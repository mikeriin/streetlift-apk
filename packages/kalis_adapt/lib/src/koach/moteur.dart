part of 'koach.dart';

// Façade du moteur (référence `koach/moteur.py`, contrat § 3) :
//   observe(evenement), posterior(), plan(contraintes), explain().
// L'état se recalcule depuis le journal (`rejouer`).

/// Module branché sur le moteur (planification, adhérence, surveillance,
/// contrôle dual). Les crochets sont appelés dans l'ordre de
/// [Koach.extensions].
abstract class Extension {
  void finSeance(Koach koach, ResumeSeance? resume, Json e) {}

  void seanceManquee(Koach koach, Json e) {}

  void finSemaine(Koach koach, Json ligne, Json e) {}

  void decision(Koach koach, Json e) {}

  Object? planSemaine(Koach koach, Json c) => null;
}

/// Extension prévenue quand la surveillance lève l'alerte hors modèle.
abstract interface class AvecAlerteHorsModele {
  void surAlerteHorsModele(Koach koach, List<String> causes);
}

/// Extension qui relit ses paramètres après un import (événement
/// `parametres`).
abstract interface class AvecParametres {
  void appliquerParametres(Json params);
}

/// Extension qui fixe l'hypothèse de dose de la semaine (tirage de
/// Thompson du contrôle dual).
abstract interface class AvecHypothese {
  int? hypothesePourLaSemaine(Koach koach, int semaine, int graine);
}

/// Ce que les crochets de séance savent du jour (contexte de la dernière
/// séance ouverte).
class ContexteSeance {
  ContexteSeance({
    this.semaine,
    this.jourIndex,
    this.jour = 0,
    this.genre,
    this.ecrit = const <Json>[],
  });

  /// Semaine globale (`contexte.semaine`).
  final int? semaine;

  /// Indice du jour d'entraînement dans la semaine (`contexte.jour_index`).
  final int? jourIndex;

  /// Jour depuis le début.
  final int jour;

  /// Nature de la semaine (`contexte.genre`).
  final Object? genre;

  /// Items écrits du jour, avant toute modulation (ceux de l'appel de
  /// `plan`).
  final List<Json> ecrit;
}

/// Extension qui module les items écrits du jour avant la prescription
/// (planification, semaine allégée, bras de volume d'un essai). Appelée par
/// la façade, dans l'ordre de [Koach.extensions] (KM2, constat M6).
abstract interface class AvecItemsDuJour {
  List<Json> itemsDuJour(Koach koach, ContexteSeance ctx, List<Json> items);
}

/// Extension qui retouche la cible d'une série (bras d'intensité d'un
/// essai), sous les bornes de la séance.
abstract interface class AvecCibleSerie {
  Json? cibleSerie(Koach koach, Json item, int index, Json? cible);
}

/// Le moteur Koach : estimation, prescription, garde-fous.
class Koach {
  Koach(this.params, this.fiches, this.profil)
    : modele = Modele(params, fiches, profil) {
    garde = Gardefous(params, modele.niveau, profil['zones_fragiles']);
    seances = Seances(params, modele, garde, fiches);
  }

  Json params;
  final Map<String, Json> fiches;
  final Json profil;
  final Modele modele;
  late final Gardefous garde;
  late final Seances seances;
  final List<Json> journal = [];
  List<Json> raisons = [];
  int jour = 0;
  final List<Extension> extensions = [];

  /// Contexte de la dernière séance ouverte (crochets de la façade).
  ContexteSeance contexteSeance = ContexteSeance();

  /// Grilles de charge de la dernière séance prescrite (bras d'intensité).
  Map<String, Grille> grillesSeance = {};

  /// Charges externes visées par exercice (événements `reference` et
  /// `cibles`) : posées en `koachCible` sur les items de test (tentatives).
  Map<String, Object?> ciblesTentatives = {};

  /// Charge externe de la première série servie, par exercice (forme des
  /// propositions de l'adhérence).
  final Map<String, double> _derniereCharge = {};

  /// Verse un événement du journal (§ 2.1).
  void observe(Json e) {
    journal.add(e);
    final typ = e['type'];
    final m = modele;
    if (typ == 'seance_debut') {
      jour = ent(e['jour']);
      garde.avancer(jour);
      final bilan = jmOu(e['bilan']);
      if (bilan != null && bilan['pains'] != null) {
        garde.noterSeance(jour, jl(bilan['pains']), posee: true);
      }
      m.debutSeance(jour, bilan, e['poids_kg']);
      final ctx = dictOuVide(e['contexte']);
      seances.ouvrir(jour, bilan, ctx);
      contexteSeance = ContexteSeance(
        semaine: ctx['semaine'] == null ? null : ent(ctx['semaine']),
        jourIndex: ctx['jour_index'] == null ? null : ent(ctx['jour_index']),
        jour: jour,
        genre: ctx['genre'],
      );
    } else if (typ == 'serie') {
      m.observerSerie(jm(e['serie']));
      seances.serieFaite(jm(e['serie']));
    } else if (typ == 'seance_fin') {
      final douleurs = e['douleurs'];
      if (vrai(douleurs)) {
        garde.noterSeance(jour, jl(douleurs), posee: false);
      }
      seances.fermer(dictOuVide(e['seance']));
      final resume = m.finSeance();
      for (final x in extensions) {
        x.finSeance(this, resume, e);
      }
    } else if (typ == 'seance_manquee') {
      for (final x in extensions) {
        x.seanceManquee(this, e);
      }
    } else if (typ == 'semaine_fin') {
      m.avancer(ent(e['jour']));
      final ligne = m.finSemaine();
      for (final x in extensions) {
        x.finSemaine(this, ligne, e);
      }
    } else if (typ == 'cran') {
      m.changerCran(e['exerciseId'] as String, dbl(e['facteur']));
    } else if (typ == 'poids') {
      if (e['poids_kg'] != null && dbl(e['poids_kg']) > 0) {
        m.poidsKg = dbl(e['poids_kg']);
      }
    } else if (typ == 'decision') {
      for (final x in extensions) {
        x.decision(this, e);
      }
    } else if (typ == 'charge_manuelle') {
      m.observerChargeManuelle(
        e['exerciseId'] as String,
        e['loadKg'],
        e['reps'],
        e['rir'],
      );
    } else if (typ == 'parametres') {
      appliquerParametres(this, jm(e['fichier']));
    } else if (typ == 'plan') {
      _plan(jm(e['contraintes']));
    } else if (typ == 'reference') {
      // Plan de référence de la planification (KM2, constat M7) : versé au
      // journal, le rejeu reconstruit la planification.
      ciblesTentatives = Map<String, Object?>.of(
        dictOuVide(e['cibles_tentatives']),
      );
      for (final x in extensions) {
        if (x is Planification) {
          x.surReference(this, e);
        }
      }
    } else if (typ == 'cibles') {
      ciblesTentatives = Map<String, Object?>.of(
        dictOuVide(e['cibles_tentatives']),
      );
      for (final x in extensions) {
        if (x is Planification) {
          x.surCibles(e);
        }
      }
    }
  }

  /// L'a posteriori lisible (§ 3.4).
  Json posterior() {
    final m = modele;
    final exercices = <String, Object?>{};
    for (final exId in m.ordre) {
      final t = m.pistes[exId]!;
      final (mu, sd) = m.capacite(exId)!;
      final iv = m.intervalle(exId)!;
      exercices[exId] = <String, Object?>{
        'type': t.type,
        'ln_capacite': mu,
        'ecart_type': sd,
        'valeur': m.valeur(exId),
        'intervalle_90': [iv.$1, iv.$2, iv.$3],
        'seances': t.seances,
        'mesures': t.mesures,
      };
    }
    double sdDe(int i) {
      final v = m.pget(i, i);
      return math.sqrt(v > 0.0 ? v : 0.0);
    }

    return <String, Object?>{
      'jour': m.jour,
      'qualites': [for (var q = 0; q < nq; q++) m.m[th + q]],
      'qualites_sd': [for (var q = 0; q < nq; q++) sdDe(th + q)],
      'reponse': m.m[rho],
      'reponse_sd': sdDe(rho),
      'reponse_classes': [for (var c = 0; c < 5; c++) m.m[eps + c]],
      'fatigue_sensibilite': <String, Object?>{
        'nerveux_systemique': m.m[kn],
        'nerveux_local': m.m[kl],
        'musculaire_systemique': m.m[kg],
        'musculaire_local': m.m[km],
      },
      'fatigue': <String, Object?>{
        'nerveux': <String, Object?>{
          'systemique': m.fG[0],
          'local': List<double>.of(m.fL[0]),
        },
        'musculaire': <String, Object?>{
          'systemique': m.fG[1],
          'local': List<double>.of(m.fL[1]),
        },
        'tendineux': Map<String, Object?>.of(m.fTendon),
        'tau': List<double>.of(m.tau),
      },
      'biais_rir': [m.m[ba], m.m[bp]],
      'bruit_rir': m.bruitRir,
      'courbe': [m.m[lam], m.m[ku]],
      'fatigue_intra': m.m[fi],
      'part_tenue': m.m[hh],
      'note_paresseuse': m.paresse[0] / (m.paresse[0] + m.paresse[1]),
      'hypotheses_reponse': List<double>.of(m.poidsHyp),
      'exercices': exercices,
    };
  }

  /// La séance, la série suivante ou la semaine (§ 3.3). L'appel est versé
  /// au journal (événement `plan`).
  Object? plan(Json c) {
    final cc = canonique(c);
    journal.add(<String, Object?>{'type': 'plan', 'contraintes': cc});
    return _plan(cc);
  }

  /// Forme journalisable (JSON) des contraintes.
  static Json canonique(Json c0) {
    final c = Map<String, Object?>.of(c0);
    if (c['horizon'] == 'seance') {
      final ids = <String>[];
      for (final it in listeOuVide(c['items'])) {
        final ex = jm(it)['exerciseId'] as String;
        if (!ids.contains(ex)) {
          ids.add(ex);
        }
      }
      final grilles = <String, Object?>{};
      final zones = <String, Object?>{};
      final gIn = dictOuVide(c['grilles']);
      final zIn = dictOuVide(c['zones']);
      for (final ex in ids) {
        final g = gIn[ex];
        if (g != null) {
          if (g is Grille) {
            grilles[ex] = <String, Object?>{
              'pas': g.pas,
              'minimum': g.minimum,
              'halteres': vrai(g.halteres),
            };
          } else {
            grilles[ex] = Map<String, Object?>.of(jm(g));
          }
        }
        final z = zIn[ex];
        if (z != null) {
          final Json niveaux;
          final Iterable<Object?> provoquees;
          if (z is (Json, Set<String>)) {
            niveaux = z.$1;
            provoquees = z.$2;
          } else {
            final zl = jl(z);
            niveaux = jm(zl[0]);
            provoquees = zl[1] as Iterable<Object?>;
          }
          final tri = [for (final x in provoquees) x as String]..sort();
          zones[ex] = <Object?>[Map<String, Object?>.of(niveaux), tri];
        }
      }
      final slots = [
        for (final it in listeOuVide(c['items'])) jm(it)['slotId'],
      ];
      final roles = <String, Object?>{
        for (final e in dictOuVide(c['roles']).entries)
          if (slots.contains(e.key)) e.key: e.value,
      };
      c['grilles'] = grilles;
      c['zones'] = zones;
      c['roles'] = roles;
    }
    return copieJson(c);
  }

  Object? _plan(Json c) {
    final h = c['horizon'];
    if (h == 'seance') {
      final grilles = <String, Grille>{
        for (final e in dictOuVide(c['grilles']).entries)
          e.key: Grille(
            dbl(jm(e.value)['pas']),
            dbl(jm(e.value)['minimum']),
            vrai(jm(e.value)['halteres']),
          ),
      };
      final zones = <String, (Json, Set<String>)>{
        for (final e in dictOuVide(c['zones']).entries)
          e.key: (
            Map<String, Object?>.of(jm(jl(e.value)[0])),
            {for (final z in jl(jl(e.value)[1])) z as String},
          ),
      };
      final ecrit = [for (final it in jl(c['items'])) jm(it)];
      final ctx = ContexteSeance(
        semaine: contexteSeance.semaine,
        jourIndex: contexteSeance.jourIndex,
        jour: contexteSeance.jour,
        genre: contexteSeance.genre,
        ecrit: ecrit,
      );
      var modules = ecrit;
      for (final Object x in extensions) {
        if (x is AvecItemsDuJour) {
          modules = x.itemsDuJour(this, ctx, modules);
        }
      }
      if (ciblesTentatives.isNotEmpty) {
        modules = [
          for (final it in modules)
            if (ciblesTentatives.containsKey(it['exerciseId']) &&
                it['kind'] == 'test')
              (Map<String, Object?>.of(it)
                ..['koachCible'] = ciblesTentatives[it['exerciseId']])
            else
              it,
        ];
      }
      grillesSeance = grilles;
      final items = seances.prescrire(
        modules,
        grilles,
        zones,
        dictOuVide(c['roles']),
      );
      raisons = List<Json>.of(seances.raisons);
      return <String, Object?>{'items': items, 'raisons': raisons};
    }
    if (h == 'serie') {
      final item = jm(c['item']);
      final index = ent(c['index']);
      var cible = seances.cible(item, index, listeOuVide(c['faites']));
      raisons = List<Json>.of(seances.raisons);
      for (final Object x in extensions) {
        if (x is AvecCibleSerie) {
          cible = x.cibleSerie(this, item, index, cible);
        }
      }
      return _proposition(item, index, cible);
    }
    if (h == 'semaine') {
      Object? out;
      for (final x in extensions) {
        final r = x.planSemaine(this, c);
        if (r != null) {
          out = r;
        }
      }
      return out;
    }
    throw ArgumentError('horizon inconnu : $h');
  }

  /// Forme d'adhérence (KM2, constat M6) : quand la charge de la première
  /// série d'un exercice chargé change, la cible porte `proposition`
  /// (paliers et moment choisis par [Adherence.forme]) ; la charge servie
  /// ne change pas (garde-fou anti-complaisance : la forme agit sur la
  /// présentation, jamais sur la cible).
  Json? _proposition(Json item, int index, Json? cible) {
    if (cible == null || index != 0 || cible['loadKg'] == null) {
      return cible;
    }
    final exId = item['exerciseId'] as String;
    final charge = dbl(cible['loadKg']);
    final avant = _derniereCharge[exId];
    _derniereCharge[exId] = charge;
    if (avant == null || (charge - avant).abs() < 1e-9) {
      return cible;
    }
    Adherence? ad;
    for (final Object x in extensions) {
      if (x is Adherence) {
        ad = x;
      }
    }
    if (ad == null || item['kind'] == 'test') {
      return cible;
    }
    final g = grillesSeance[exId];
    final pas = (g != null && g.pas > 0) ? g.pas : 2.5;
    final typ = charge > avant ? 'charge_plus' : 'charge_moins';
    final forme = ad.forme(charge, avant, pas, typ, <String, Object?>{
      'bilan_bas': false,
      'semaine_allegement': contexteSeance.genre == 'deload',
      'refus_recents': ad.refusRecents(jour),
    });
    final out = Map<String, Object?>.of(cible);
    out['proposition'] = <String, Object?>{
      'type': typ,
      'depart': avant,
      'cible': charge,
      ...forme,
    };
    return out;
  }

  /// Les raisons des dernières décisions (§ 3.5).
  List<Json> explain() => List<Json>.of(raisons);
}

/// Recalcule l'état depuis le journal.
Koach rejouer(
  Json params,
  Map<String, Json> fiches,
  Json profil,
  List<Json> journal, [
  List<Extension Function()> extensions = const [],
]) {
  final k = Koach(params, fiches, profil);
  for (final f in extensions) {
    k.extensions.add(f());
  }
  for (final e in journal) {
    k.observe(e);
  }
  return k;
}
