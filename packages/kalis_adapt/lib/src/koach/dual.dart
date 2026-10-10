part of 'koach.dart';

// Apprentissage actif (référence `koach/dual.py`, cahier KM § 7, contrat
// § 3.7.4) :
//
// * `Reponse` : a posteriori discret sur les hypothèses de réponse h = (s0,
//   type de stimulus) ; `tirer` fait le tirage de Thompson ;
// * `calibre` : condition de déclenchement ;
// * `EssaiN1` : essai N-of-1 A/B par bras de 3 semaines (ABBA/BAAB) ;
// * `controleSynthetique` : contrôle synthétique, poids sur le simplexe par
//   gradient projeté accéléré (FISTA, nombre d'itérations fixe) ;
// * `ControleDual` : extension du moteur qui orchestre le tout.
//
// Boucles de longueur fixe, opérations élémentaires, clés triées. Le seul
// aléa est `Mulberry32`, seedé par une graine passée en paramètre.

/// Quantile 95 % de la loi normale (intervalle à 90 %).
const double z90 = 1.6448536269514722;

/// Valeurs par défaut des paramètres `controle_dual` (`DEFAUTS_DUAL`).
const Json defautsDual = <String, Object?>{
  'semaines_min': 8,
  'intervalle_max': 0.06,
  'bras_semaines': 3,
  'synthetique_semaines_min': 6,
  'synthetique_iterations': 200,
  'amplitude_volume': 0.10,
  'amplitude_intensite': 0.03,
  'sigma_progres': 0.01,
  'plancher_poids': 1e-6,
  'a_priori_effet_sd': 0.005,
  'marge_echeance_semaines': 6,
  'seuil_decision': 0.8,
  'n_bras': 4,
  'sigma_innovation': 0.003,
  'semaines_gardees': 26,
};
const Json defautsPlafonds = <String, Object?>{
  'plafond_volume': 0.15,
  'plafond_intensite': 0.05,
};
const List<String> dualLettres = ['A', 'B'];

Object? _duParam(Json params, String cle) =>
    _ruGet(dictOuVide(params['controle_dual']), cle, defautsDual[cle]);

Object? _duPlafond(Json params, String cle) =>
    _ruGet(dictOuVide(params['planification']), cle, defautsPlafonds[cle]);

/// Facteur final par rapport à la référence quand la planification a déjà
/// déplacé le plan de [facteurPlan] : le produit reste dans
/// [1 − plafond, 1 + plafond].
double facteurBorne(double facteurPlan, double facteurEssai, double plafond) {
  final f = facteurPlan * facteurEssai;
  final bas = 1.0 - plafond;
  final haut = 1.0 + plafond;
  return f < bas ? bas : (f > haut ? haut : f);
}

// ----------------------------------------------------------------------
// 1. A posteriori sur les hypothèses de réponse
// ----------------------------------------------------------------------

/// Observation scalaire : (attendus sous chaque hypothèse, observé,
/// variance).
typedef ObservationReponse = (List<double>, double, double);

/// Poids a posteriori des hypothèses h = (s0, k).
class Reponse {
  Reponse(
    List<(double, int)> hypotheses,
    num ref, [
    num plancher = 1e-6,
    List<Object?>? poids,
  ]) : hypotheses = List<(double, int)>.of(hypotheses),
       ref = ref.toDouble(),
       plancher = plancher.toDouble() {
    final n = this.hypotheses.length;
    this.poids = poids == null
        ? List<double>.filled(n, 1.0 / n)
        : [for (final w in poids) dbl(w)];
  }

  static Reponse depuisParams(Json params) {
    final dyn = jm(params['dynamique']);
    final stims = jl(dyn['hypotheses_stimulus']);
    final s0s = jl(dyn['hypotheses_s0']);
    final hyps = <(double, int)>[
      for (var k = 0; k < stims.length; k++)
        for (final s in s0s) (dbl(s), k),
    ];
    return Reponse(
      hyps,
      dbl(dyn['dose_reference']),
      dbl(_duParam(params, 'plancher_poids')),
    );
  }

  final List<(double, int)> hypotheses;
  final double ref;
  final double plancher;
  late List<double> poids;

  /// Dernière semaine (de journal) déjà consommée.
  int? derniere;

  /// Progrès observés intégrés.
  int nObs = 0;

  double dose(List<Object?> stim, int i) {
    final (s0, k) = hypotheses[i];
    final s = dbl(stim[k]);
    if (s <= 0) {
      return 0.0;
    }
    return (1.0 - math.exp(-s / s0)) / (1.0 - math.exp(-ref / s0));
  }

  /// Vraisemblance directe des progrès (données synthétiques, tests) :
  /// [lignes] {semaine, doses, mu} dans l'ordre ; [rho] : nombre ou
  /// dictionnaire exercice -> nombre. Renvoie le nombre de progrès intégrés.
  int mettreAJour(List<Json> lignes, Object? rho, num sigma) {
    final n = hypotheses.length;
    final obs = <ObservationReponse>[];
    num? dern;
    for (var j = 0; j < lignes.length - 1; j++) {
      final a = lignes[j];
      final b = lignes[j + 1];
      if (derniere != null && (b['semaine'] as num) <= derniere!) {
        continue;
      }
      final bMu = jm(b['mu']);
      final aMu = jm(a['mu']);
      final bDoses = jm(b['doses']);
      final ids = bMu.keys.toList()..sort();
      for (final ex in ids) {
        if (!aMu.containsKey(ex) || !bDoses.containsKey(ex)) {
          continue;
        }
        final stim = jl(bDoses[ex]);
        final r = rho is Map<String, Object?> ? dbl(rho[ex]) : dbl(rho);
        final attendus = [for (var i = 0; i < n; i++) r * dose(stim, i)];
        obs.add((
          attendus,
          dbl(bMu[ex]) - dbl(aMu[ex]),
          (sigma * sigma).toDouble(),
        ));
      }
      dern = b['semaine'] as num;
    }
    if (dern == null) {
      return 0;
    }
    return integrer(obs, dern);
  }

  /// Intègre des observations scalaires indépendantes. Une semaine ≤ la
  /// dernière consommée est ignorée. Renvoie le nombre d'observations
  /// intégrées.
  int integrer(List<ObservationReponse> observations, num semaine) {
    if (derniere != null && semaine <= derniere!) {
      return 0;
    }
    derniere = ent(semaine);
    final n = hypotheses.length;
    final ll = List<double>.filled(n, 0.0);
    var compte = 0;
    for (final (attendus, obs, variance) in observations) {
      final v = variance;
      if (!(v > 0.0)) {
        continue;
      }
      for (var i = 0; i < n; i++) {
        final d = obs - attendus[i];
        ll[i] += -0.5 * d * d / v;
      }
      compte += 1;
    }
    if (compte == 0) {
      return 0;
    }
    // Log-espace, normalisation stable (soustraction du maximum).
    final lw = List<double>.filled(n, 0.0);
    var mx = -inf;
    for (var i = 0; i < n; i++) {
      final w = poids[i];
      lw[i] = (w > 0 ? math.log(w) : -745.0) + ll[i];
      if (lw[i] > mx) {
        mx = lw[i];
      }
    }
    var tot = 0.0;
    for (var i = 0; i < n; i++) {
      lw[i] = math.exp(lw[i] - mx);
      tot += lw[i];
    }
    // Plancher puis renormalisation.
    var tot2 = 0.0;
    for (var i = 0; i < n; i++) {
      var w = lw[i] / tot;
      if (w < plancher) {
        w = plancher;
      }
      lw[i] = w;
      tot2 += w;
    }
    for (var i = 0; i < n; i++) {
      poids[i] = lw[i] / tot2;
    }
    nObs += compte;
    return compte;
  }

  /// Tirage de Thompson : un seul uniforme, inversion de la fonction de
  /// répartition dans l'ordre des hypothèses.
  int tirer(Mulberry32 rng) {
    final u = rng.next();
    var c = 0.0;
    final n = poids.length;
    for (var i = 0; i < n; i++) {
      c += poids[i];
      if (u < c) {
        return i;
      }
    }
    return n - 1;
  }

  /// Indice de plus grand poids (égalité : le plus petit indice).
  int meilleure() {
    var b = 0;
    for (var i = 1; i < poids.length; i++) {
      if (poids[i] > poids[b]) {
        b = i;
      }
    }
    return b;
  }

  double entropie() {
    var h = 0.0;
    for (final w in poids) {
      if (w > 0) {
        h -= w * math.log(w);
      }
    }
    return h;
  }

  Json etat() => <String, Object?>{
    'hypotheses': <Object?>[
      for (final h in hypotheses) <Object?>[h.$1, h.$2],
    ],
    'ref': ref,
    'plancher': plancher,
    'poids': List<double>.of(poids),
    'derniere': derniere,
    'n_obs': nObs,
  };

  static Reponse depuisEtat(Json etat) {
    final hyps = <(double, int)>[
      for (final h in jl(etat['hypotheses'])) (dbl(jl(h)[0]), ent(jl(h)[1])),
    ];
    final r = Reponse(
      hyps,
      dbl(etat['ref']),
      dbl(etat['plancher']),
      jl(etat['poids']),
    );
    r.derniere = etat['derniere'] == null ? null : ent(etat['derniere']);
    r.nObs = ent(etat['n_obs']);
    return r;
  }
}

// ----------------------------------------------------------------------
// 2. Condition de déclenchement
// ----------------------------------------------------------------------

/// (bool, raisons) : au moins `semaines_min` semaines de journal ET, pour
/// chaque lift principal, demi-largeur relative de l'intervalle à 90 % de
/// l'e1RM sous `intervalle_max`.
(bool, List<String>) calibre(
  Koach koach,
  List<String> liftsPrincipaux, [
  int? semaines,
]) {
  final p = koach.params;
  final raisons = <String>[];
  final n = semaines ?? koach.modele.journalSemaines.length;
  final nmin = _duParam(p, 'semaines_min') as num;
  if (n < nmin) {
    raisons.add('semaines_insuffisantes:$n<${ent(nmin)}');
  }
  final imax = _duParam(p, 'intervalle_max') as num;
  if (liftsPrincipaux.isEmpty) {
    raisons.add('aucun_lift_principal');
  }
  for (final ex in liftsPrincipaux) {
    final c = koach.modele.capacite(ex);
    if (c == null) {
      raisons.add('lift_inconnu:$ex');
      continue;
    }
    final demi = z90 * c.$2;
    if (!(demi < imax)) {
      raisons.add('intervalle_large:$ex:${demi.toStringAsFixed(4)}');
    }
  }
  return (raisons.isEmpty, raisons);
}

// ----------------------------------------------------------------------
// 3. Essai N-of-1
// ----------------------------------------------------------------------

/// Mesure d'un essai : (semaine, bras, lettre, progrès traité − témoin).
typedef MesureEssai = (int, int, String, double);

/// Compare A (+amplitude_volume de volume) et B (+amplitude_intensite
/// d'intensité) sur une qualité ou un exercice, par bras de
/// `bras_semaines` semaines.
class EssaiN1 {
  /// [cible] : {'qualite': q} ou {'exerciseId': id}.
  EssaiN1(
    Json params,
    Json cible, [
    List<Object?>? exercicesTraites,
    List<Object?>? exercicesTemoins,
  ]) {
    if (cible.containsKey('qualite')) {
      cle = 'qualite';
    } else if (cible.containsKey('exerciseId')) {
      cle = 'exerciseId';
    } else {
      throw ArgumentError('cible sans qualite ni exerciseId');
    }
    valeur = cible[cle];
    final tr = vrai(exercicesTraites)
        ? exercicesTraites!
        : (cle == 'qualite' ? <Object?>[] : <Object?>[valeur]);
    traites = [for (final x in tr) x as String]..sort();
    temoins = [for (final x in listeOuVide(exercicesTemoins)) x as String]
      ..sort();
    brasSemaines = ent(_duParam(params, 'bras_semaines'));
    ampV = dbl(_duParam(params, 'amplitude_volume'));
    ampI = dbl(_duParam(params, 'amplitude_intensite'));
    plafondV = dbl(_duPlafond(params, 'plafond_volume'));
    plafondI = dbl(_duPlafond(params, 'plafond_intensite'));
    // Toujours à l'intérieur des plafonds de l'optimisation bornée
    // (AssertionError dans la référence : pas une ArgumentError).
    if (!(0.0 <= ampV && ampV <= plafondV)) {
      throw StateError('amplitude de volume hors plafond : ${_ruRepr(ampV)}');
    }
    if (!(0.0 <= ampI && ampI <= plafondI)) {
      throw StateError("amplitude d'intensité hors plafond : ${_ruRepr(ampI)}");
    }
    tau = dbl(_duParam(params, 'a_priori_effet_sd'));
    sigmaSecours = dbl(_duParam(params, 'sigma_progres'));
    seuil = dbl(_duParam(params, 'seuil_decision'));
    marge = ent(_duParam(params, 'marge_echeance_semaines'));
  }

  late final String cle;
  late final Object? valeur;
  late final List<String> traites;
  late final List<String> temoins;
  late final int brasSemaines;
  late final double ampV;
  late final double ampI;
  late final double plafondV;
  late final double plafondI;
  late final double tau;
  late final double sigmaSecours;
  late final double seuil;
  late final int marge;
  List<String> sequence = [];
  int? debut;

  /// prevu, en_cours, termine, interrompu.
  String statut = 'prevu';
  Object? raisonFin;
  List<MesureEssai> mesures = [];

  // --- conditions -------------------------------------------------------
  Json facteurs(String lettre) {
    if (lettre == 'A') {
      return <String, Object?>{'volume': 1.0 + ampV, 'intensite': 1.0};
    }
    return <String, Object?>{'volume': 1.0, 'intensite': 1.0 + ampI};
  }

  int duree() => sequence.length * brasSemaines;

  /// Séquence équilibrée et contre-balancée (ABBA ou BAAB). nBras pair ≥ 2.
  List<String> plan(Mulberry32 rng, int nBras) {
    if (nBras < 2 || nBras % 2 != 0) {
      throw ArgumentError('n_bras doit être pair et ≥ 2');
    }
    final seq = <String>[];
    var prem = 'A';
    for (var j = 0; j < divEnt(nBras, 2); j++) {
      if (j % 2 == 0) {
        prem = rng.next() < 0.5 ? 'A' : 'B';
      } else {
        prem = prem == 'A' ? 'B' : 'A';
      }
      seq.add(prem);
      seq.add(prem == 'A' ? 'B' : 'A');
    }
    sequence = seq;
    return List<String>.of(seq);
  }

  /// (bool, raisons). [contexte] : {'calibre', 'affutage',
  /// 'semaines_avant_echeance', 'alerte', 'douleur', 'semaines_temoin',
  /// 'semaines_temoin_min'}.
  (bool, List<String>) peutDemarrer(Json contexte) {
    final raisons = <String>[];
    if (!vrai(_ruGet(contexte, 'calibre', false))) {
      raisons.add('non_calibre');
    }
    if (vrai(_ruGet(contexte, 'affutage', false))) {
      raisons.add('affutage');
    }
    if (vrai(_ruGet(contexte, 'alerte', false))) {
      raisons.add('alerte_hors_modele');
    }
    if (vrai(_ruGet(contexte, 'douleur', false))) {
      raisons.add('douleur');
    }
    final ech = contexte['semaines_avant_echeance'];
    if (ech != null) {
      final e = ech as num;
      final d = sequence.isNotEmpty
          ? duree()
          : brasSemaines * ent(defautsDual['n_bras']);
      if (e < marge || e - d < marge) {
        raisons.add('echeance_proche');
      }
    }
    if (statut != 'prevu') {
      raisons.add('deja_$statut');
    }
    // Contrôle synthétique : il faut assez de semaines AVANT l'intervention.
    final pre = contexte['semaines_temoin'];
    if (pre != null &&
        (pre as num) <
            ent(
              _ruGet(
                contexte,
                'semaines_temoin_min',
                defautsDual['synthetique_semaines_min'],
              ),
            )) {
      raisons.add('temoin_trop_court:${ent(pre)}');
    }
    return (raisons.isEmpty, raisons);
  }

  void demarrer(int semaine) {
    if (sequence.isEmpty) {
      throw ArgumentError('plan() avant demarrer()');
    }
    debut = semaine;
    statut = 'en_cours';
  }

  /// Retour au plan de référence (alerte hors modèle, douleur…).
  void interrompre(Object? raison) {
    if (statut == 'prevu' || statut == 'en_cours') {
      statut = 'interrompu';
      raisonFin = raison;
    }
  }

  int? brasDe(int semaine) {
    final d = debut;
    if (d == null || statut == 'interrompu') {
      return null;
    }
    final i = divEnt(semaine - d, brasSemaines);
    if (semaine < d || i >= sequence.length) {
      return null;
    }
    return i;
  }

  /// 'A', 'B' ou null (essai fini, interrompu ou pas commencé).
  String? condition(int semaine) {
    final i = brasDe(semaine);
    return i == null ? null : sequence[i];
  }

  bool fini(int semaine) => debut != null && semaine >= debut! + duree() - 1;

  bool enregistrer(
    int semaine,
    double progresTraite,
    double progresTemoinSynthetique,
  ) {
    final i = brasDe(semaine);
    if (i == null) {
      return false;
    }
    for (final m in mesures) {
      if (m.$1 == semaine) {
        return false;
      }
    }
    mesures.add((
      semaine,
      i,
      sequence[i],
      progresTraite - progresTemoinSynthetique,
    ));
    if (fini(semaine) && statut == 'en_cours') {
      statut = 'termine';
    }
    return true;
  }

  // --- analyse ------------------------------------------------------------

  /// Effet moyen B − A sur le progrès hebdomadaire, a posteriori normal
  /// sous a priori N(0, τ²), décision 'B', 'A' ou 'indetermine'.
  Json analyse() {
    final nb = sequence.length;
    final sommeB = List<double>.filled(nb, 0.0);
    final compte = List<int>.filled(nb, 0);
    for (final m in mesures) {
      sommeB[m.$2] += m.$4;
      compte[m.$2] += 1;
    }
    final moy = List<double>.filled(nb, 0.0);
    for (var i = 0; i < nb; i++) {
      if (compte[i] > 0) {
        moy[i] = sommeB[i] / compte[i];
      }
    }
    final diffs = <double>[];
    var varSommeInv = 0.0; // Σ (1/nA + 1/nB) sur les paires complètes
    var ddl = 0;
    for (var j = 0; j < divEnt(nb, 2); j++) {
      final i0 = 2 * j;
      final i1 = 2 * j + 1;
      if (compte[i0] == 0 || compte[i1] == 0) {
        continue;
      }
      final ia = sequence[i0] == 'A' ? i0 : i1;
      final ib = sequence[i0] == 'A' ? i1 : i0;
      diffs.add(moy[ib] - moy[ia]);
      varSommeInv += 1.0 / compte[ia] + 1.0 / compte[ib];
      ddl += compte[ia] - 1 + compte[ib] - 1;
    }
    final n = diffs.length;
    if (n == 0) {
      return <String, Object?>{
        'paires': 0,
        'effet': null,
        'erreur_type': null,
        'ddl': 0,
        'probabilite_b': 0.5,
        'moyenne_post': 0.0,
        'ecart_type_post': tau,
        'decision': 'indetermine',
        'moyennes_bras': moy,
      };
    }
    var effet = 0.0;
    for (final d in diffs) {
      effet += d;
    }
    effet /= n;
    // Somme des carrés intra-bras, sur les seules paires complètes.
    var sswP = 0.0;
    for (final m in mesures) {
      final j = divEnt(m.$2, 2);
      if (compte[2 * j] > 0 && compte[2 * j + 1] > 0) {
        final d = m.$4 - moy[m.$2];
        sswP += d * d;
      }
    }
    final s2 = ddl > 0 ? sswP / ddl : sigmaSecours * sigmaSecours;
    var se2 = s2 * varSommeInv / (n * n);
    final t2 = tau * tau;
    if (se2 <= 0) {
      se2 = 1e-18;
    }
    final vPost = 1.0 / (1.0 / t2 + 1.0 / se2);
    final mPost = vPost * effet / se2;
    final sdPost = math.sqrt(vPost);
    final p = normCdfK(mPost / sdPost);
    String dec;
    if (p >= seuil) {
      dec = 'B';
    } else if (p <= 1.0 - seuil) {
      dec = 'A';
    } else {
      dec = 'indetermine';
    }
    return <String, Object?>{
      'paires': n,
      'effet': effet,
      'erreur_type': math.sqrt(se2),
      'ddl': ddl,
      'probabilite_b': p,
      'moyenne_post': mPost,
      'ecart_type_post': sdPost,
      'decision': dec,
      'moyennes_bras': moy,
    };
  }

  // --- état -----------------------------------------------------------------
  Json etat() => <String, Object?>{
    'cle': cle,
    'valeur': valeur,
    'traites': List<String>.of(traites),
    'temoins': List<String>.of(temoins),
    'sequence': List<String>.of(sequence),
    'debut': debut,
    'statut': statut,
    'raison_fin': raisonFin,
    'mesures': <Object?>[
      for (final m in mesures) <Object?>[m.$1, m.$2, m.$3, m.$4],
    ],
  };

  static EssaiN1 depuisEtat(Json params, Json etat) {
    final e = EssaiN1(
      params,
      <String, Object?>{etat['cle'] as String: etat['valeur']},
      jl(etat['traites']),
      jl(etat['temoins']),
    );
    e.sequence = [for (final x in jl(etat['sequence'])) x as String];
    e.debut = etat['debut'] == null ? null : ent(etat['debut']);
    e.statut = etat['statut'] as String;
    e.raisonFin = etat['raison_fin'];
    e.mesures = [
      for (final m0 in jl(etat['mesures']))
        (ent(jl(m0)[0]), ent(jl(m0)[1]), jl(m0)[2] as String, dbl(jl(m0)[3])),
    ];
    return e;
  }
}

// ----------------------------------------------------------------------
// 4. Contrôle synthétique
// ----------------------------------------------------------------------

/// Projection euclidienne exacte de v sur {w ≥ 0, Σ w = 1} : tri
/// décroissant par insertion (égalités départagées par l'indice croissant),
/// seuil θ, w = max(v − θ, 0).
List<double> projectionSimplexe(List<double> v) {
  final n = v.length;
  final ordre = [for (var i = 0; i < n; i++) i];
  for (var i = 1; i < n; i++) {
    var j = i;
    while (j > 0) {
      final a = ordre[j - 1];
      final b = ordre[j];
      if (v[b] > v[a] || (v[b] == v[a] && b < a)) {
        ordre[j - 1] = b;
        ordre[j] = a;
        j -= 1;
      } else {
        break;
      }
    }
  }
  var cumul = 0.0;
  var theta = 0.0;
  for (var r = 0; r < n; r++) {
    cumul += v[ordre[r]];
    final t = (cumul - 1.0) / (r + 1);
    if (v[ordre[r]] - t > 0) {
      theta = t;
    }
  }
  final w = List<double>.filled(n, 0.0);
  for (var i = 0; i < n; i++) {
    final d = v[i] - theta;
    w[i] = d > 0 ? d : 0.0;
  }
  return w;
}

/// Majorant garanti de la plus grande valeur propre d'une matrice
/// symétrique semi-définie positive : λmax ≤ trace(A^(2^p))^(1/2^p).
double borneLambdaMax(List<List<double>> a, double tr, [int carres = 4]) {
  final nj = a.length;
  var b = [
    for (var j = 0; j < nj; j++) [for (var l = 0; l < nj; l++) a[j][l] / tr],
  ];
  for (var it = 0; it < carres; it++) {
    final c = [for (var j = 0; j < nj; j++) List<double>.filled(nj, 0.0)];
    for (var j = 0; j < nj; j++) {
      for (var l = 0; l < nj; l++) {
        var acc = 0.0;
        for (var m = 0; m < nj; m++) {
          acc += b[j][m] * b[m][l];
        }
        c[j][l] = acc;
      }
    }
    b = c;
  }
  var t = 0.0;
  for (var j = 0; j < nj; j++) {
    t += b[j][j];
  }
  if (t <= 0.0) {
    return tr;
  }
  return tr * pw(t, 1.0 / (1 << carres));
}

/// min_w wᵀAw − 2bᵀw sur le simplexe (FISTA à pas 1/L, L = 2 × majorant de
/// λmax(A), nombre d'itérations fixe). Renvoie (w, écart de dualité de
/// Frank-Wolfe).
(List<double>, double) _duSimplexeMoindresCarres(
  List<List<double>> a,
  List<double> b,
  int iterations,
) {
  final nj = b.length;
  var w = List<double>.filled(nj, 1.0 / nj);
  var tr = 0.0;
  for (var j = 0; j < nj; j++) {
    tr += a[j][j];
  }
  if (tr <= 0.0) {
    return (w, 0.0);
  }
  final lip = 2.0 * borneLambdaMax(a, tr);
  final y = List<double>.of(w);
  var t = 1.0;
  for (var it = 0; it < iterations; it++) {
    final z = List<double>.filled(nj, 0.0);
    for (var j = 0; j < nj; j++) {
      var g = 0.0;
      for (var l = 0; l < nj; l++) {
        g += a[j][l] * y[l];
      }
      g = 2.0 * (g - b[j]);
      z[j] = y[j] - g / lip;
    }
    final wn = projectionSimplexe(z);
    final tn = (1.0 + math.sqrt(1.0 + 4.0 * t * t)) / 2.0;
    final c = (t - 1.0) / tn;
    for (var j = 0; j < nj; j++) {
      y[j] = wn[j] + c * (wn[j] - w[j]);
    }
    w = wn;
    t = tn;
  }
  // Écart de dualité de Frank-Wolfe : gᵀw − min_j g_j ≥ f(w) − f*.
  final g = List<double>.filled(nj, 0.0);
  var gmin = inf;
  var gw = 0.0;
  for (var j = 0; j < nj; j++) {
    var s = 0.0;
    for (var l = 0; l < nj; l++) {
      s += a[j][l] * w[l];
    }
    g[j] = 2.0 * (s - b[j]);
    gw += g[j] * w[j];
    if (g[j] < gmin) {
      gmin = g[j];
    }
  }
  return (w, gw - gmin);
}

/// Contrôle synthétique démoyenné (Abadie, Diamond et Hainmueller 2010).
/// Renvoie {poids, erreur_pre, contrefactuel, ecart, effet_moyen,
/// ecart_dualite}. Lève une [ArgumentError] (ValueError de la référence)
/// si les données ne le permettent pas.
Json controleSynthetique(
  List<double> serieTraitee,
  List<List<double>> seriesTemoins,
  int debutIntervention, [
  int iterations = 200,
  int semainesMin = 6,
]) {
  final nt = serieTraitee.length;
  final t0 = debutIntervention;
  if (t0 < semainesMin) {
    throw ArgumentError(
      "contrôle synthétique : $t0 semaines avant l'intervention (minimum $semainesMin)",
    );
  }
  if (t0 > nt) {
    throw ArgumentError("début d'intervention après la fin de la série");
  }
  final nj = seriesTemoins.length;
  if (nj == 0) {
    throw ArgumentError('contrôle synthétique sans série témoin');
  }
  for (final s in seriesTemoins) {
    if (s.length != nt) {
      throw ArgumentError('séries témoins de longueurs différentes');
    }
  }
  var my = 0.0;
  for (var t = 0; t < t0; t++) {
    my += serieTraitee[t];
  }
  my /= t0;
  final mx = List<double>.filled(nj, 0.0);
  for (var j = 0; j < nj; j++) {
    var acc = 0.0;
    for (var t = 0; t < t0; t++) {
      acc += seriesTemoins[j][t];
    }
    mx[j] = acc / t0;
  }
  final am = [for (var j = 0; j < nj; j++) List<double>.filled(nj, 0.0)];
  final bv = List<double>.filled(nj, 0.0);
  for (var j = 0; j < nj; j++) {
    for (var l = 0; l < nj; l++) {
      var acc = 0.0;
      for (var t = 0; t < t0; t++) {
        acc += (seriesTemoins[j][t] - mx[j]) * (seriesTemoins[l][t] - mx[l]);
      }
      am[j][l] = acc;
    }
    var acc = 0.0;
    for (var t = 0; t < t0; t++) {
      acc += (seriesTemoins[j][t] - mx[j]) * (serieTraitee[t] - my);
    }
    bv[j] = acc;
  }
  final (w, gap) = _duSimplexeMoindresCarres(am, bv, iterations);
  final contre = List<double>.filled(nt, 0.0);
  for (var t = 0; t < nt; t++) {
    var v = my;
    for (var j = 0; j < nj; j++) {
      v += w[j] * (seriesTemoins[j][t] - mx[j]);
    }
    contre[t] = v;
  }
  var sse = 0.0;
  for (var t = 0; t < t0; t++) {
    final d = serieTraitee[t] - contre[t];
    sse += d * d;
  }
  final ecart = <double>[];
  for (var t = t0; t < nt; t++) {
    ecart.add(serieTraitee[t] - contre[t]);
  }
  var effet = 0.0;
  for (final d in ecart) {
    effet += d;
  }
  effet = ecart.isNotEmpty ? effet / ecart.length : 0.0;
  return <String, Object?>{
    'poids': w,
    'erreur_pre': math.sqrt(sse / t0),
    'contrefactuel': contre,
    'ecart': ecart,
    'effet_moyen': effet,
    'ecart_dualite': gap,
  };
}

/// Progrès hebdomadaires de la cible et de son témoin synthétique à partir
/// de l'intervention : progrès(t) = valeur(t) − valeur(t − 1), t ≥ début.
Json effetEssai(
  List<double> serieTraitee,
  List<List<double>> seriesTemoins,
  int debutIntervention, [
  int iterations = 200,
  int semainesMin = 6,
]) {
  final sc = controleSynthetique(
    serieTraitee,
    seriesTemoins,
    debutIntervention,
    iterations,
    semainesMin,
  );
  final c = sc['contrefactuel'] as List<double>;
  final pt = <double>[];
  final pc = <double>[];
  for (var t = debutIntervention; t < serieTraitee.length; t++) {
    pt.add(serieTraitee[t] - serieTraitee[t - 1]);
    pc.add(c[t] - c[t - 1]);
  }
  return <String, Object?>{
    'progres_traite': pt,
    'progres_temoin_synthetique': pc,
    'synthetique': sc,
  };
}

// ----------------------------------------------------------------------
// 5. Orchestration
// ----------------------------------------------------------------------

/// Extension du moteur : met à jour [Reponse] chaque lundi (innovation
/// hebdomadaire de capacité, non circulaire), conduit l'essai N-of-1 en
/// cours et expose le tirage de Thompson de la semaine et la modulation du
/// plan pendant un bras. Source unique des poids des hypothèses :
/// `reponse.poids`, recopiés dans `koach.modele.poidsHyp`.
class ControleDual extends Extension
    implements
        AvecAlerteHorsModele,
        AvecHypothese,
        AvecItemsDuJour,
        AvecCibleSerie {
  ControleDual(this.params, List<String> liftsPrincipaux)
    : lifts = List<String>.of(liftsPrincipaux)..sort(),
      reponse = Reponse.depuisParams(params);

  static const int raisonsGardees = 50;

  final Json params;
  final List<String> lifts;
  Reponse reponse;
  EssaiN1? essai;

  /// [{'essai': etat, 'analyse': dict}].
  List<Json> essaisPasses = [];
  List<String> raisons = [];

  /// ex -> (μ, V) à la fin de la dernière séance.
  Map<String, (double, double)> capSeance = {};

  /// ex -> (μ_post, V_post, [δ_h]).
  Map<String, (double, double, List<double>)> suivi = {};

  /// [{'semaine': int, 'mu': {ex: μ_pré}}] (synthétique).
  List<Json> pre = [];

  void _raison(String r) {
    raisons.add(r);
    if (raisons.length > raisonsGardees) {
      raisons = raisons.sublist(raisons.length - raisonsGardees);
    }
  }

  // --- lecture du modèle ----------------------------------------------------

  /// rho + eps de la classe de chaque exercice.
  static Map<String, double> _rho(Koach koach, List<String> ids) {
    final m = koach.modele;
    final rhoV = m.m[rho];
    final out = <String, double>{};
    for (final ex in ids) {
      final t = m.pistes[ex];
      final c = t?.classe;
      out[ex] = rhoV + (c != null ? m.m[eps + c] : 0.0);
    }
    return out;
  }

  /// Exercices suivis par le modèle avec une classe de réponse (triés).
  static List<String> _suivables(Koach koach) {
    final m = koach.modele;
    final out = <String>[];
    final cles = m.pistes.keys.toList()..sort();
    for (final ex in cles) {
      final t = m.pistes[ex];
      if (t != null && t.classe != null) {
        out.add(ex);
      }
    }
    return out;
  }

  /// (semaines, série traitée = moyenne des mu des exercices traités,
  /// séries témoins) sur les lignes où tous les exercices sont présents.
  static (List<int>, List<double>, List<List<double>>) series(
    List<Json> lignes,
    List<String> traites,
    List<String> temoins,
  ) {
    final sem = <int>[];
    final tr = <double>[];
    final te = [for (var j = 0; j < temoins.length; j++) <double>[]];
    for (final ligne in lignes) {
      final mu = jm(ligne['mu']);
      var ok = traites.isNotEmpty;
      for (final ex in traites) {
        if (!mu.containsKey(ex)) {
          ok = false;
        }
      }
      for (final ex in temoins) {
        if (!mu.containsKey(ex)) {
          ok = false;
        }
      }
      if (!ok) {
        continue;
      }
      var v = 0.0;
      for (final ex in traites) {
        v += dbl(mu[ex]);
      }
      sem.add(ent(ligne['semaine']));
      tr.add(v / traites.length);
      for (var j = 0; j < temoins.length; j++) {
        te[j].add(dbl(mu[temoins[j]]));
      }
    }
    return (sem, tr, te);
  }

  // --- innovations et poids ---------------------------------------------------
  List<ObservationReponse> _innovations(Koach koach, Json ligne) {
    final m = koach.modele;
    final hyps = m.hypotheses;
    var memes = hyps.length == reponse.hypotheses.length;
    for (var i = 0; memes && i < hyps.length; i++) {
      if (hyps[i] != reponse.hypotheses[i]) {
        memes = false;
      }
    }
    if (!memes) {
      throw ArgumentError(
        'hypothèses de réponse différentes entre le modèle et le contrôle dual',
      );
    }
    final n = reponse.hypotheses.length;
    final ids = <String>[];
    final muLigne = jm(ligne['mu']);
    final cles = muLigne.keys.toList()..sort();
    for (final ex in cles) {
      final t = m.pistes[ex];
      if (t != null && t.classe != null) {
        ids.add(ex);
      }
    }
    final rhoD = _rho(koach, ids);
    final fac = dbl(_ruGet(ligne, 'facteur', 1.0));
    final dyn = dictOuVide(params['dynamique']);
    final q7 = 7.0 * dbl(_ruGet(dyn, 'q_delta_jour_inactif', 0.0));
    final smin = dbl(_duParam(params, 'sigma_innovation'));
    final w = List<double>.of(reponse.poids);
    final obs = <ObservationReponse>[];
    final nSuivi = <String, (double, double, List<double>)>{};
    final preEx = <String, Object?>{};
    for (final ex in ids) {
      final c = m.capacite(ex);
      if (c == null) {
        continue;
      }
      final muPost = dbl(muLigne[ex]);
      final vPost = c.$2 * c.$2;
      final stim = dictOuVide(ligne['doses'])[ex];
      final g = List<double>.filled(n, 0.0);
      var gu = 0.0;
      if (stim != null) {
        final stimL = jl(stim);
        for (var i = 0; i < n; i++) {
          g[i] = rhoD[ex]! * fac * reponse.dose(stimL, i);
          gu += w[i] * g[i];
        }
      }
      final cs = capSeance[ex];
      final muPre = cs != null ? cs.$1 : muPost - gu;
      final s = suivi[ex];
      List<double> deltas;
      if (s != null) {
        final vPrior = s.$2 + q7;
        final vPre = cs != null ? cs.$2 : vPrior;
        var k = vPrior > 0.0 ? 1.0 - vPre / vPrior : 0.0;
        k = k < 0.0 ? 0.0 : (k > 1.0 ? 1.0 : k);
        var variance = vPrior - vPre;
        variance = (variance > 0.0 ? variance : 0.0) + smin * smin;
        obs.add(([for (final d in s.$3) k * d], muPre - s.$1, variance));
        deltas = [for (final d in s.$3) (1.0 - k) * d];
      } else {
        deltas = List<double>.filled(n, 0.0);
      }
      nSuivi[ex] = (
        muPost,
        vPost,
        [for (var i = 0; i < n; i++) deltas[i] + g[i] - gu],
      );
      preEx[ex] = muPre;
    }
    suivi = nSuivi;
    capSeance = {};
    pre.add(<String, Object?>{'semaine': ent(ligne['semaine']), 'mu': preEx});
    final garde = ent(_duParam(params, 'semaines_gardees'));
    if (pre.length > garde) {
      pre = pre.sublist(pre.length - garde);
    }
    return obs;
  }

  // --- crochets du moteur -----------------------------------------------------
  @override
  void finSeance(Koach koach, ResumeSeance? resume, Json e) {
    final m = koach.modele;
    for (final ex in _suivables(koach)) {
      final c = m.capacite(ex);
      if (c != null) {
        capSeance[ex] = (c.$1, c.$2 * c.$2);
      }
    }
    if (essai != null && vrai(e['douleurs'])) {
      interrompre('douleur');
    }
  }

  @override
  void finSemaine(Koach koach, Json ligne, Json e) {
    final obs = _innovations(koach, ligne);
    reponse.integrer(obs, ligne['semaine'] as num);
    koach.modele.poidsHyp = List<double>.of(reponse.poids);
    final es = essai;
    if (es == null) {
      return;
    }
    if (vrai(e['alerte_hors_modele']) || vrai(e['alerte'])) {
      interrompre('alerte_hors_modele');
      return;
    }
    if (vrai(e['douleur']) || vrai(e['douleurs'])) {
      interrompre('douleur');
      return;
    }
    final s = ent(ligne['semaine']);
    if (es.condition(s) != null) {
      // Séries de capacité a posteriori AVANT la croissance du lundi.
      final (sem, tr, te) = series(pre, es.traites, es.temoins);
      var debut = 0;
      while (debut < sem.length && sem[debut] < es.debut!) {
        debut += 1;
      }
      final pos = sem.length - 1;
      if (pos >= 0 && sem[pos] == s && debut <= pos && te.isNotEmpty) {
        try {
          final r = effetEssai(
            tr,
            te,
            debut,
            ent(_duParam(params, 'synthetique_iterations')),
            ent(_duParam(params, 'synthetique_semaines_min')),
          );
          final k = pos - debut;
          es.enregistrer(
            s,
            (r['progres_traite'] as List<double>)[k],
            (r['progres_temoin_synthetique'] as List<double>)[k],
          );
        } on ArgumentError catch (err) {
          // ValueError de la référence ; RangeError (IndexError) n'en est
          // pas une.
          if (err is RangeError) {
            rethrow;
          }
          _raison('synthetique_impossible:${err.message}');
        }
      }
    }
    if (es.statut == 'en_cours' && es.fini(s)) {
      es.statut = 'termine';
    }
    if (es.statut == 'termine' || es.statut == 'interrompu') {
      _clore();
    }
  }

  /// Propositions d'essai journalisées (événement `decision` portant
  /// `essai` : {semaine, cible, traites, temoins, contexte, graine,
  /// n_bras}).
  @override
  void decision(Koach koach, Json e) {
    final d0 = e['essai'];
    if (d0 != null) {
      final d = jm(d0);
      final (ok, rs) = proposerEssai(
        koach,
        ent(d['semaine']),
        jm(d['cible']),
        d['traites'] == null ? null : jl(d['traites']),
        d['temoins'] == null ? null : jl(d['temoins']),
        dictOuVide(d['contexte']),
        ent(d['graine']),
        d['n_bras'],
      );
      _raison(
        'essai_${ok ? 'demarre' : 'refuse'}:${ent(d['semaine'])}:${rs.join(',')}',
      );
    }
    if (essai != null && vrai(e['alerte_hors_modele'])) {
      interrompre('alerte_hors_modele');
    }
  }

  /// Une alerte hors modèle interrompt l'essai en cours.
  @override
  void surAlerteHorsModele(Koach koach, List<String> causes) {
    if (essai != null) {
      interrompre('alerte_hors_modele');
    }
  }

  // --- essais -----------------------------------------------------------------

  /// Crée, planifie et démarre un essai à la semaine [semaine] si
  /// `peutDemarrer` l'accepte. Renvoie (bool, raisons).
  (bool, List<String>) proposerEssai(
    Koach koach,
    int semaine,
    Json cible,
    List<Object?>? traites,
    List<Object?>? temoins,
    Json contexte,
    int graine, [
    Object? nBras,
  ]) {
    if (essai != null) {
      return (false, <String>['essai_en_cours']);
    }
    final es = EssaiN1(params, cible, traites, temoins);
    final nb = ent(nBras ?? _duParam(params, 'n_bras'));
    final rng = Mulberry32(fnv1a32('koach-dual-essai:$graine:$semaine'));
    es.plan(rng, nb);
    final (okCal, rCal) = calibre(koach, lifts);
    final ctx = Map<String, Object?>.of(contexte);
    ctx['calibre'] = okCal;
    // Semaines de capacités disponibles avant l'intervention pour les
    // témoins (contrôle synthétique : 6 au moins).
    var nTemoin = 0;
    if (es.temoins.isNotEmpty) {
      for (final x in pre) {
        final mu = jm(x['mu']);
        if (es.temoins.every(mu.containsKey)) {
          nTemoin += 1;
        }
      }
    }
    ctx['semaines_temoin'] = nTemoin;
    ctx['semaines_temoin_min'] = ent(
      _duParam(params, 'synthetique_semaines_min'),
    );
    final (ok, rs) = es.peutDemarrer(ctx);
    if (!ok) {
      return (false, [...rs, ...rCal]);
    }
    es.demarrer(semaine);
    essai = es;
    return (true, <String>[]);
  }

  void interrompre(String raison) {
    final es = essai;
    if (es != null) {
      es.interrompre(raison);
      _raison('essai_interrompu:$raison');
      _clore();
    }
  }

  void _clore() {
    final es = essai!;
    essaisPasses.add(<String, Object?>{
      'essai': es.etat(),
      'analyse': es.analyse(),
    });
    essai = null;
  }

  // --- sorties pour la planification ------------------------------------------

  /// Indice d'hypothèse tiré (Thompson) pour la replanification de
  /// [semaine], ou null si le modèle n'est pas calibré.
  @override
  int? hypothesePourLaSemaine(Koach koach, int semaine, int graine) {
    final (ok, _) = calibre(koach, lifts);
    if (!ok) {
      return null;
    }
    final rng = Mulberry32(fnv1a32('koach-dual:$graine:$semaine'));
    return reponse.tirer(rng);
  }

  /// Facteurs à appliquer par la planification à la cible pendant un
  /// bras ; 1,0 hors essai.
  Json modulation(int semaine) {
    final es = essai;
    final lettre = es?.condition(semaine);
    if (es == null || lettre == null) {
      return <String, Object?>{'volume': 1.0, 'intensite': 1.0};
    }
    final f = es.facteurs(lettre);
    return <String, Object?>{
      es.cle: es.valeur,
      'volume': f['volume'],
      'intensite': f['intensite'],
      'bras': lettre,
    };
  }

  // --- façade 1.0.0 (KM2) : bras de l'essai appliqués aux séances --------
  /// Nature de la dernière semaine servie (affûtage : pas d'essai).
  Object? genre;

  /// [semaine, séries de référence, séries planifiées, séries servies] de
  /// l'exercice traité par le bras A dans la semaine en cours.
  List<num>? semaineVol;

  /// Journal des modulations servies (banc et mode dev).
  final List<Json> journal = [];

  /// Bras A (volume) : séries ajoutées à l'exercice traité, le produit
  /// (facteur de la planification × facteur du bras) borné par le plafond
  /// de volume par rapport à la RÉFÉRENCE ([ContexteSeance.ecrit]), cumulé
  /// sur la semaine (`ControleDualBanc.items_du_jour` de la référence).
  @override
  List<Json> itemsDuJour(Koach koach, ContexteSeance ctx, List<Json> items) {
    genre = ctx.genre;
    final semaine = ctx.semaine;
    if (semaine == null) {
      return items;
    }
    final mod = modulation(semaine);
    if (!mod.containsKey('bras') || dbl(mod['volume']) <= 1.0) {
      return items;
    }
    final ex = mod['exerciseId'];
    if (semaineVol == null || semaineVol![0] != semaine) {
      semaineVol = <num>[semaine, 0, 0, 0];
    }
    final sv = semaineVol!;
    final plafondV = dbl(
      dictOuVide(params['planification'])['plafond_volume'] ?? 0.15,
    );
    final reference = <String, int>{};
    for (final it in ctx.ecrit) {
      if (it['exerciseId'] == ex && (it['kind'] ?? 'work') == 'work') {
        reference[it['slotId'] as String] =
            vrai(it['sets']) ? ent(it['sets']) : 0;
      }
    }
    final out = <Json>[];
    for (final it0 in items) {
      if (it0['exerciseId'] != ex ||
          (it0['kind'] ?? 'work') != 'work' ||
          (vrai(it0['sets']) ? dbl(it0['sets']) : 0) < 1) {
        out.add(it0);
        continue;
      }
      final n = ent(it0['sets']);
      final ref = sv[1] + (reference[it0['slotId']] ?? n);
      final planifiees = sv[2] + n;
      final servies = sv[3] + n;
      double borne;
      if (ref > 0) {
        borne =
            facteurBorne(planifiees / ref.toDouble(), dbl(mod['volume']), plafondV) *
            ref;
      } else {
        borne = servies.toDouble();
      }
      var plus = (borne - servies + 0.5).floor();
      while (plus > 0 && servies + plus > (1.0 + plafondV) * ref + 1e-9) {
        plus -= 1;
      }
      plus = plus > 0 ? plus : 0;
      final it = Map<String, Object?>.of(it0);
      it['sets'] = n + plus;
      sv[1] = ref;
      sv[2] = planifiees;
      sv[3] = servies + plus;
      journal.add(<String, Object?>{
        'type': 'volume',
        'jour': ctx.jour,
        'semaine': semaine,
        'exerciseId': ex,
        'ecrites': n,
        'servies': n + plus,
        'ratio_semaine': ref != 0 ? arrondi(sv[3] / ref.toDouble(), 6) : 1.0,
      });
      out.add(it);
    }
    return out;
  }

  /// Bras B (intensité) : charge de travail montée de l'amplitude du bras,
  /// jamais un jour où Koach interdit la hausse et jamais au-dessus des
  /// bornes de hausse de la séance (`Seances.borneExterne`) ;
  /// `ControleDualBanc.cible_serie` de la référence.
  @override
  Json? cibleSerie(Koach koach, Json item, int index, Json? cible) {
    if (cible == null || cible['loadKg'] == null) {
      return cible;
    }
    final semaine = koach.contexteSeance.semaine;
    if (semaine == null) {
      return cible;
    }
    final mod = modulation(semaine);
    if (mod['bras'] != 'B' || item['exerciseId'] != mod['exerciseId']) {
      return cible;
    }
    if (cible['role'] == 'test' ||
        cible['role'] == 'attempt' ||
        item['kind'] == 'test' ||
        vrai(cible['repere'])) {
      return cible;
    }
    final m = koach.modele;
    final exId = item['exerciseId'] as String;
    final t = m.pistes[exId];
    final grille = koach.grillesSeance[exId];
    if (t == null || grille == null) {
      return cible;
    }
    final kg = dbl(cible['loadKg']);
    final total = m.masse(t, kg);
    if (total <= 0) {
      return cible;
    }
    final voulu = total * dbl(mod['intensite']) - (total - kg);
    var nouveau = grille.plancher(voulu);
    if (nouveau <= kg + 1e-9) {
      return cible;
    }
    final borne = koach.seances.borneExterne(item, index, nouveau);
    if (borne == null || borne <= kg + 1e-9) {
      return cible;
    }
    if (nouveau > borne) {
      nouveau = borne.toDouble();
    }
    final c = Map<String, Object?>.of(cible);
    c['loadKg'] = nouveau;
    journal.add(<String, Object?>{
      'type': 'intensite',
      'jour': koach.jour,
      'semaine': semaine,
      'exerciseId': exId,
      'index': index,
      'ratio': arrondi(m.masse(t, nouveau) / total, 6),
    });
    return c;
  }

  // --- état -------------------------------------------------------------------
  Json etat() {
    final ex1 = capSeance.keys.toList()..sort();
    final ex2 = suivi.keys.toList()..sort();
    return <String, Object?>{
      'lifts': List<String>.of(lifts),
      'reponse': reponse.etat(),
      'essai': essai?.etat(),
      'essais_passes': <Object?>[
        for (final x in essaisPasses)
          <String, Object?>{'essai': x['essai'], 'analyse': x['analyse']},
      ],
      'raisons': List<String>.of(raisons),
      'cap_seance': <Object?>[
        for (final ex in ex1)
          <Object?>[ex, capSeance[ex]!.$1, capSeance[ex]!.$2],
      ],
      'suivi': <Object?>[
        for (final ex in ex2)
          <Object?>[
            ex,
            suivi[ex]!.$1,
            suivi[ex]!.$2,
            List<double>.of(suivi[ex]!.$3),
          ],
      ],
      'pre': <Object?>[
        for (final x in pre)
          <String, Object?>{
            'semaine': x['semaine'],
            'mu': <Object?>[
              for (final ex in jm(x['mu']).keys.toList()..sort())
                <Object?>[ex, jm(x['mu'])[ex]],
            ],
          },
      ],
    };
  }

  static ControleDual depuisEtat(Json params, Json etat) {
    final c = ControleDual(params, [
      for (final x in jl(etat['lifts'])) x as String,
    ]);
    c.reponse = Reponse.depuisEtat(jm(etat['reponse']));
    c.essai = etat['essai'] == null
        ? null
        : EssaiN1.depuisEtat(params, jm(etat['essai']));
    c.essaisPasses = [
      for (final x0 in jl(etat['essais_passes']))
        <String, Object?>{
          'essai': jm(x0)['essai'],
          'analyse': jm(x0)['analyse'],
        },
    ];
    c.raisons = [for (final r in jl(etat['raisons'])) r as String];
    c.capSeance = {
      for (final x0 in jl(_ruGet(etat, 'cap_seance', <Object?>[])))
        jl(x0)[0] as String: (dbl(jl(x0)[1]), dbl(jl(x0)[2])),
    };
    c.suivi = {
      for (final x0 in jl(_ruGet(etat, 'suivi', <Object?>[])))
        jl(x0)[0] as String: (dbl(jl(x0)[1]), dbl(jl(x0)[2]), jld(jl(x0)[3])),
    };
    c.pre = [
      for (final x0 in jl(_ruGet(etat, 'pre', <Object?>[])))
        <String, Object?>{
          'semaine': ent(jm(x0)['semaine']),
          'mu': <String, Object?>{
            for (final p0 in jl(jm(x0)['mu']))
              jl(p0)[0] as String: dbl(jl(p0)[1]),
          },
        },
    ];
    return c;
  }
}
