part of 'koach.dart';

// Adhérence et refus (référence `koach/adherence.py`, cahier KM § 8,
// décision D7, contrat § 3.7.3) :
//
// * probit bayésien de P(acceptation) d'une proposition : P = Φ(w·x),
//   w ~ N(m, P), mis à jour à chaque décision par appariement des moments
//   de rang 1 (accepter ⇔ w·x + ε > 0, ε ~ N(0, 1)) ;
// * un refus « trop lourd » / « trop léger » devient EN PLUS une mesure
//   faible de capacité (`Modele.observerRaison`) ; « matériel » et « temps »
//   sont rangés comme contraintes de planification ;
// * garde-fou anti-complaisance : `forme` découpe un trajet départ -> cible
//   dont le dernier palier vaut toujours exactement la cible.
//
// Boucles de longueur fixe, opérations élémentaires. Aucun aléa.

/// Valeurs par défaut des paramètres `adherence` (`DEFAUTS_ADHERENCE`).
const Json defautsAdherence = <String, Object?>{
  'a_priori_poids_sd': 1.5,
  'biais_initial': 1.0,
  'pas_min': 0.5,
  'proba_cible': 0.7,
  'refus_silence_j': 0,
  'paliers_max': 4,
  'ampleur_echelle': 4.0,
  'ampleur_borne': 3.0,
  'refus_recents_j': 14,
  'refus_recents_echelle': 5.0,
};

const List<String> adherenceTypes = [
  'charge_plus',
  'charge_moins',
  'volume_plus',
  'volume_moins',
  'reps_plus',
  'reps_moins',
  'echange',
  'test',
  'allegement',
];
const List<String> adherenceMoments = ['debut_de_seance', 'entre_series', 'prochaine_seance'];
const List<String> raisonsCapacite = ['too_heavy', 'too_light'];
const List<String> raisonsContrainte = ['equipment', 'time'];

// Caractéristiques : 0 biais ; 1..9 type ; 10 ampleur ; 11 jour de bilan
// bas ; 12 semaine d'allègement ; 13 moment entre deux séries ; 14 moment à
// la prochaine séance (référence : début de séance) ; 15 refus récents.
const int adherenceIType = 1;
const int adherenceIAmpleur = 10;
const int adherenceIBilan = 11;
const int adherenceIAllegement = 12;
const int adherenceIEntre = 13;
const int adherenceIProchaine = 14;
const int adherenceIRefus = 15;
const int adherenceDim = 16;
const List<String> adherenceNoms = [
  'biais',
  ...adherenceTypes,
  'ampleur',
  'bilan_bas',
  'semaine_allegement',
  'entre_series',
  'prochaine_seance',
  'refus_recents',
];

Object? _adParam(Json? params, String cle) =>
    _ruGet(dictOuVide(dictOuVide(params)['adherence']), cle, defautsAdherence[cle]);

/// Modèle d'adhérence (extension du moteur).
class Adherence extends Extension implements AvecParametres {
  Adherence([Json? params]) {
    appliquerParametres(params);
    final sd = poidsSd;
    m = List<double>.filled(adherenceDim, 0.0);
    m[0] = biaisInitial;
    pm = [for (var i = 0; i < adherenceDim; i++) List<double>.filled(adherenceDim, 0.0)];
    for (var i = 0; i < adherenceDim; i++) {
      pm[i][i] = sd * sd;
    }
  }

  Json? params;
  late double poidsSd;
  late double biaisInitial;
  late double pasMin;
  late double probaCible;
  late int paliersMax;
  late double ampleurEchelle;
  late double ampleurBorne;
  late int refusRecentsJ;
  late double refusRecentsEchelle;

  /// Moyenne des poids (`m`).
  late List<double> m;

  /// Covariance des poids (`P`).
  late List<List<double>> pm;

  /// Jours des refus récents (valeurs du journal, telles quelles).
  List<num> refusJours = [];
  List<Json> contraintesListe = [];
  int n = 0;

  /// Calibration en ligne : par tranche de 20 %, (n, Σ p prédite,
  /// Σ acceptées).
  List<(int, double, int)> tranches = [for (var i = 0; i < 5; i++) (0, 0.0, 0)];

  @override
  void appliquerParametres(Json? params) {
    this.params = params;
    poidsSd = dbl(_adParam(params, 'a_priori_poids_sd'));
    biaisInitial = dbl(_adParam(params, 'biais_initial'));
    pasMin = dbl(_adParam(params, 'pas_min'));
    probaCible = dbl(_adParam(params, 'proba_cible'));
    paliersMax = ent(_adParam(params, 'paliers_max'));
    ampleurEchelle = dbl(_adParam(params, 'ampleur_echelle'));
    ampleurBorne = dbl(_adParam(params, 'ampleur_borne'));
    refusRecentsJ = ent(_adParam(params, 'refus_recents_j'));
    refusRecentsEchelle = dbl(_adParam(params, 'refus_recents_echelle'));
  }

  // ------------------------------------------------------------------
  // Caractéristiques et prédiction
  // ------------------------------------------------------------------
  int refusRecents(num jour) {
    var nb = 0;
    for (final j in refusJours) {
      if (jour - j < refusRecentsJ) {
        nb += 1;
      }
    }
    return nb;
  }

  /// Vecteur x (16 flottants). [ampleur] : |changement| en pas de grille ;
  /// [contexte] : {bilan_bas, semaine_allegement, moment, refus_recents}.
  List<double> caracteristiques(Object? typ, Object? ampleur, [Json? contexte]) {
    if (!adherenceTypes.contains(typ)) {
      throw ArgumentError('type de changement inconnu : ${_ruRepr(typ)}');
    }
    final c = dictOuVide(contexte);
    final x = List<double>.filled(adherenceDim, 0.0);
    x[0] = 1.0;
    x[adherenceIType + adherenceTypes.indexOf(typ as String)] = 1.0;
    final a = dbl(ou(ampleur, 0.0)).abs() / ampleurEchelle;
    x[adherenceIAmpleur] = a < ampleurBorne ? a : ampleurBorne;
    x[adherenceIBilan] = vrai(c['bilan_bas']) ? 1.0 : 0.0;
    x[adherenceIAllegement] = vrai(c['semaine_allegement']) ? 1.0 : 0.0;
    final moment = _ruGet(c, 'moment', 'debut_de_seance');
    x[adherenceIEntre] = moment == 'entre_series' ? 1.0 : 0.0;
    x[adherenceIProchaine] = moment == 'prochaine_seance' ? 1.0 : 0.0;
    final r = dbl(ou(c['refus_recents'], 0)) / refusRecentsEchelle;
    x[adherenceIRefus] = r < 1.0 ? r : 1.0;
    return x;
  }

  List<double> _px(List<double> x) {
    final px = List<double>.filled(adherenceDim, 0.0);
    for (var i = 0; i < adherenceDim; i++) {
      var s = 0.0;
      for (var j = 0; j < adherenceDim; j++) {
        s += pm[i][j] * x[j];
      }
      px[i] = s;
    }
    return px;
  }

  (double, double, List<double>) _moments(List<double> x) {
    var s = 0.0;
    for (var i = 0; i < adherenceDim; i++) {
      s += m[i] * x[i];
    }
    final px = _px(x);
    var v = 0.0;
    for (var i = 0; i < adherenceDim; i++) {
      v += x[i] * px[i];
    }
    if (v < 1e-12) {
      v = 1e-12;
    }
    return (s, v, px);
  }

  /// Probabilité prédictive Φ(m·x / sqrt(1 + xᵀPx)).
  double proba(List<double> x) {
    final (s, v, _) = _moments(x);
    return normCdfK(s / math.sqrt(1.0 + v));
  }

  // ------------------------------------------------------------------
  // Apprentissage
  // ------------------------------------------------------------------

  /// Mise à jour par appariement des moments de rang 1 ; renvoie la
  /// probabilité prédite AVANT la mise à jour.
  double apprendre(List<double> x, bool accepte) {
    final (s, v, px) = _moments(x);
    final p = normCdfK(s / math.sqrt(1.0 + v));
    double s2;
    double v2;
    if (accepte) {
      final (_, sa, va) = intervalMoments(s, v, 1.0, 0.0, inf);
      s2 = sa;
      v2 = va;
    } else {
      final (_, sa, va) = intervalMoments(s, v, 1.0, -inf, 0.0);
      s2 = sa;
      v2 = va;
    }
    final a = (s2 - s) / v;
    final b = (v - v2) / (v * v);
    for (var i = 0; i < adherenceDim; i++) {
      m[i] += px[i] * a;
    }
    for (var i = 0; i < adherenceDim; i++) {
      for (var j = 0; j < adherenceDim; j++) {
        pm[i][j] -= px[i] * px[j] * b;
      }
    }
    var k = (p * 5.0).truncate();
    if (k > 4) {
      k = 4;
    }
    final t = tranches[k];
    tranches[k] = (t.$1 + 1, t.$2 + p, t.$3 + (accepte ? 1 : 0));
    n += 1;
    return p;
  }

  /// Événement {type: 'decision', jour, proposition: {id, type,
  /// exerciseId, ampleur, charge_kg, reps, rir, contexte}, accepte,
  /// raison}. Les événements `decision` sans proposition sont ignorés.
  @override
  void decision(Koach koach, Json e) {
    if (e['proposition'] == null) {
      return;
    }
    final prop = dictOuVide(e['proposition']);
    final jour = _ruGet(e, 'jour', 0) as num;
    final accepte = vrai(e['accepte']);
    final typ = prop['type'];
    if (adherenceTypes.contains(typ)) {
      final ctx = dictOuVide(prop['contexte']);
      final c = <String, Object?>{
        'bilan_bas': ctx['bilan_bas'],
        'semaine_allegement': ctx['semaine_allegement'],
        'moment': _ruGet(ctx, 'moment', 'debut_de_seance'),
        'refus_recents': _ruGet(ctx, 'refus_recents', refusRecents(jour)),
      };
      apprendre(caracteristiques(typ, prop['ampleur'], c), accepte);
    }
    if (accepte) {
      return;
    }
    refusJours.add(jour);
    // Seuls les refus récents servent : on oublie les plus anciens.
    final garde = <num>[];
    for (final j in refusJours) {
      if (jour - j < refusRecentsJ) {
        garde.add(j);
      }
    }
    refusJours = garde;
    final raison = e['raison'];
    if (raisonsCapacite.contains(raison)) {
      final ex = prop['exerciseId'];
      final charge = prop['charge_kg'];
      final reps = prop['reps'];
      final rir = prop['rir'];
      if (ex != null && charge != null && reps != null && rir != null) {
        // Second canal (D7) : mesure faible de capacité, raison explicite.
        koach.modele.observerRaison(ex as String, raison, dbl(charge), dbl(reps), dbl(rir));
      }
    } else if (raisonsContrainte.contains(raison)) {
      contraintesListe.add(<String, Object?>{
        'jour': jour,
        'raison': raison,
        'exerciseId': prop['exerciseId'],
        'proposition': prop['id'],
      });
    }
  }

  /// Contraintes de planification datées (matériel, temps).
  List<Json> contraintes() => [for (final c in contraintesListe) Map<String, Object?>.of(c)];

  // ------------------------------------------------------------------
  // Forme des propositions (garde-fou anti-complaisance)
  // ------------------------------------------------------------------

  /// n paliers de départ vers cible, intermédiaires calés sur la grille de
  /// pas depuis le départ, dernier = cible exactement.
  static List<num> _paliers(num depart, num cible, int n, double pas) {
    final d = cible - depart;
    final sg = d > 0 ? 1.0 : -1.0;
    final q = d.abs() / (n * pas);
    final out = <num>[];
    for (var k = 1; k < n; k++) {
      out.add(depart + sg * pas * (k * q + 0.5).floor());
    }
    out.add(cible);
    return out;
  }

  /// {'paliers', 'moment', 'proba_min'} : le plus petit nombre de paliers
  /// dont chacun a P(acceptation) >= proba_cible, chaque pas >= pas_min, au
  /// plus paliers_max ; sinon le découpage de plus forte probabilité
  /// minimale. Le dernier palier vaut toujours exactement [cible].
  Json forme(num cible, num depart, [num? pasMinArg, Object? typ = 'charge_plus', Json? contexte]) {
    final pas = pasMinArg != null ? pasMinArg.toDouble() : pasMin;
    final c = dictOuVide(contexte);
    final moments = vrai(c['moments_possibles']) ? jl(c['moments_possibles']) : adherenceMoments;
    final d = (cible - depart).abs();
    var nMax = pas > 0 ? (d / pas + 1e-9).floor() : 1;
    if (nMax > paliersMax) {
      nMax = paliersMax;
    }
    if (nMax < 1) {
      nMax = 1;
    }
    // (proba_min, n, paliers, moment)
    (double, int, List<num>, Object?)? meilleur;
    for (var n = 1; n < nMax + 1; n++) {
      List<num> paliers;
      if (d == 0.0) {
        paliers = <num>[cible];
      } else {
        paliers = _paliers(depart, cible, n, pas);
      }
      // Chaque pas doit valoir au moins pas_min (sauf trajet en un pas).
      var prec = depart;
      var valide = true;
      final pasL = <num>[];
      for (final v in paliers) {
        final ecart = (v - prec).abs();
        if (n > 1 && ecart < pas * (1.0 - 1e-9)) {
          valide = false;
        }
        pasL.add(ecart);
        prec = v;
      }
      if (!valide) {
        continue;
      }
      (double, Object?)? choix;
      for (final mo in moments) {
        final cm = <String, Object?>{
          'bilan_bas': c['bilan_bas'],
          'semaine_allegement': c['semaine_allegement'],
          'moment': mo,
          'refus_recents': _ruGet(c, 'refus_recents', 0),
        };
        var pmin = 1.0;
        for (final e in pasL) {
          final p = proba(caracteristiques(typ, pas > 0 ? e / pas : 0.0, cm));
          if (p < pmin) {
            pmin = p;
          }
        }
        if (choix == null || pmin > choix.$1) {
          choix = (pmin, mo);
        }
      }
      final ch = choix!;
      if (meilleur == null || ch.$1 > meilleur.$1) {
        meilleur = (ch.$1, n, paliers, ch.$2);
      }
      if (ch.$1 >= probaCible) {
        meilleur = (ch.$1, n, paliers, ch.$2);
        break;
      }
      if (d == 0.0) {
        break;
      }
    }
    final best = meilleur!;
    final paliers = List<num>.of(best.$3);
    paliers[paliers.length - 1] = cible;
    return <String, Object?>{'paliers': paliers, 'moment': best.$4, 'proba_min': best.$1};
  }

  // ------------------------------------------------------------------
  // Calibration (banc)
  // ------------------------------------------------------------------

  /// Table prédit / observé par tranche de 20 %. [decisions] : liste de
  /// [p prédite, acceptée] ou de {'p', 'accepte'} ; sans argument, les
  /// décisions vues par ce modèle.
  List<Json> calibration([List<Object?>? decisions]) {
    List<(int, double, int)> t;
    if (decisions == null) {
      t = List<(int, double, int)>.of(tranches);
    } else {
      t = [for (var i = 0; i < 5; i++) (0, 0.0, 0)];
      for (final dcs in decisions) {
        double p;
        bool a;
        if (dcs is Map<String, Object?>) {
          p = dbl(dcs['p']);
          a = vrai(dcs['accepte']);
        } else {
          final l = jl(dcs);
          p = dbl(l[0]);
          a = vrai(l[1]);
        }
        var k = (p * 5.0).truncate();
        if (k > 4) {
          k = 4;
        }
        if (k < 0) {
          k = 0;
        }
        t[k] = (t[k].$1 + 1, t[k].$2 + p, t[k].$3 + (a ? 1 : 0));
      }
    }
    final out = <Json>[];
    for (var k = 0; k < 5; k++) {
      final nk = t[k].$1;
      out.add(<String, Object?>{
        'tranche': <Object?>[0.2 * k, 0.2 * (k + 1)],
        'n': nk,
        'predit': nk > 0 ? t[k].$2 / nk : null,
        'observe': nk > 0 ? t[k].$3 / nk : null,
      });
    }
    return out;
  }

  // ------------------------------------------------------------------
  // Sérialisation
  // ------------------------------------------------------------------
  Json etat() => <String, Object?>{
    'version': 1,
    'noms': List<String>.of(adherenceNoms),
    'm': List<double>.of(m),
    'P': <Object?>[for (final r in pm) List<double>.of(r)],
    'refus_jours': List<num>.of(refusJours),
    'contraintes': contraintes(),
    'n': n,
    'tranches': <Object?>[
      for (final x in tranches) <Object?>[x.$1, x.$2, x.$3],
    ],
  };

  static Adherence depuisEtat(Json? params, Json etat) {
    final a = Adherence(params);
    if (ent(_ruGet(etat, 'version', 0)) != 1 || jl(etat['m']).length != adherenceDim) {
      throw ArgumentError("état d'adhérence incompatible");
    }
    a.m = jld(etat['m']);
    a.pm = [for (final r in jl(etat['P'])) jld(r)];
    a.refusJours = [for (final j in jl(etat['refus_jours'])) j as num];
    a.contraintesListe = [for (final c in jl(etat['contraintes'])) Map<String, Object?>.of(jm(c))];
    a.n = ent(etat['n']);
    a.tranches = [
      for (final x0 in jl(etat['tranches'])) (ent(jl(x0)[0]), dbl(jl(x0)[1]), ent(jl(x0)[2])),
    ];
    return a;
  }
}
