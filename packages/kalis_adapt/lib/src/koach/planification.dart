part of 'koach.dart';

// Planification de Koach 1.0 (référence `koach/planification.py`, contrat
// § 3.7.1, § 9.1 à 9.4), portée ligne pour ligne.
//
// Chaque lundi, Koach replanifie de la semaine suivante jusqu'à l'échéance
// (jumeau numérique de 1 000 trajectoires, recherche par entropie croisée,
// optimisation bornée autour du plan de référence de `kalis_plan`, validateur
// de sécurité injecté). Koach ne change que le volume (séries) et l'intensité
// (charge) du plan écrit.
//
// numpy : les opérations vectorielles de la référence sont écrites en
// boucles. Les réductions et produits sont isolés dans les fonctions `_pl…`
// en fin de fichier, chacune avec ce que fait numpy (2.5, OpenBLAS) :
//   * `.sum()` / `.mean()` / `np.std` sur un axe contigu : sommation par
//     paires de numpy (`_plSommePaires`), vérifiée bit pour bit contre numpy
//     2.5.3 ;
//   * réduction sur l'axe 0 d'un tableau 2D C-contigu : accumulation
//     séquentielle ligne après ligne (`_plMoyenneAxe0`, `_plEcartTypeAxe0`),
//     vérifiée ;
//   * `np.einsum('cdq,cq->cd')` : noyau `sum_of_products_contig_contig_
//     outstride0_two` de numpy en SIMD de base x86-64 (2 voies, sans FMA)
//     (`_plEinsumQ`), vérifié bit pour bit ;
//   * produits matriciels `@` (BLAS : ddot, dgemv, dgemm d'OpenBLAS, avec FMA
//     et accumulateurs vectoriels) : somme séquentielle dans l'ordre des
//     indices (`_plDot`, `_plHPHt`) — PAS bit pour bit (écarts de l'ordre de
//     l'ulp sur une partie des éléments) ;
//   * `np.exp`, `np.log` de tableaux (noyaux AVX512F de numpy, environ 5 %
//     des résultats à 1 ulp de la libm) : `math.exp`, `math.log`
//     (`_plNpExp`, `_plNpLog`) — PAS bit pour bit.

/// Semaines où la planification n'ajoute ni volume ni intensité
/// (`planification.SEMAINES_VERROUILLEES`).
const List<String> planificationSemainesVerrouillees = [
  'intro',
  'deload',
  'taper',
  'test',
  'competition',
  'transition',
];

/// Grille d'intensité des tables (`GRILLE_INTENSITE`).
const List<double> grilleIntensite = [-0.05, -0.025, 0.0, 0.025, 0.05];

/// Validateur de sécurité injecté : fonction(blocs) → liste de constats
/// {code, week, dayIndex, exerciseId, …} (critères de 0.3.1).
typedef Validateur = List<Json> Function(List<Json> blocs);

/// `planification.rir_de_flammes` (réserve de 2,5 sans flammes).
double planificationRirDeFlammes(Object? f, [double defaut = 2.5]) {
  if (f == null) {
    return defaut;
  }
  final x = dbl(f);
  return x >= 10 ? 0.0 : (11 - x) / 2.0;
}

/// Semaine écrite du plan de référence (dictionnaire de
/// `semaines_de_reference`).
class SemaineReference {
  SemaineReference(
    this.bloc,
    this.semaineBloc,
    this.genre,
    this.intention,
    this.jours,
  );

  final int bloc;
  final int semaineBloc;
  final Object? genre;
  final Object? intention;

  /// (dayIndex, items) dans l'ordre écrit.
  final List<(int, List<Json>)> jours;
}

/// Semaines écrites du plan de référence : par semaine globale, la semaine
/// écrite ou null quand elle n'est pas écrite.
List<SemaineReference?> semainesDeReference(
  List<Json> blocs,
  List<int>? blockWeeks,
  int horizon,
) {
  final out = <SemaineReference?>[];
  final n = blocs.length;
  final debuts = (blockWeeks != null && blockWeeks.isNotEmpty)
      ? List<int>.of(blockWeeks)
      : <int>[0];
  for (var w = 0; w < horizon; w++) {
    var k = 0;
    for (var j = 0; j < debuts.length; j++) {
      if (debuts[j] <= w) {
        k = j;
      }
    }
    if (k >= n) {
      out.add(null);
      continue;
    }
    final wb = w - debuts[k];
    Json? ecrite;
    for (final s in jl(jm(blocs[k]['pass2'])['weeks'])) {
      final sm = jm(s);
      if (sm['weekIndex'] == wb) {
        ecrite = sm;
      }
    }
    if (ecrite == null) {
      out.add(null);
      continue;
    }
    final jours = <(int, List<Json>)>[
      for (final d in jl(ecrite['days']))
        (
          ent(jm(d)['dayIndex']),
          [for (final it in jl(jm(d)['items'])) jm(it)],
        ),
    ];
    out.add(
      SemaineReference(k, wb, ecrite['kind'], ecrite['intent'], jours),
    );
  }
  return out;
}

/// Semaine verrouillée (allègement, affûtage, test, compétition,
/// transition, introduction).
bool verrouillee(SemaineReference semaine) {
  final g = ou(semaine.intention, semaine.genre);
  return planificationSemainesVerrouillees.contains(g) ||
      const ['deload', 'test', 'intro'].contains(semaine.genre);
}

/// Table d'une semaine écrite (dictionnaire de `Planification._table`).
class TablePlanification {
  TablePlanification(
    this.stim,
    this.syst,
    this.masse,
    this.part,
    this.tendon,
    this.verrou,
    this.bloc,
  );

  /// `stim[g][e][k]` : (volume, effort, intensité) des exercices suivis.
  final List<List<List<double>>> stim;

  /// `syst[g][jour % 7][q]` : charge systémique par qualité.
  final List<List<List<double>>> syst;

  /// `masse[q]` : séries × vecteur.
  final List<double> masse;

  /// `part[q]` : part moyenne du 1RM pondérée par la masse.
  final List<double> part;

  /// `tendon[zone][q]` : charge tendineuse au point g = 2.
  final Map<String, List<double>> tendon;

  final bool verrou;
  final int bloc;

  /// Forme JSON (mêmes clés que la référence).
  Json versJson() => <String, Object?>{
    'stim': stim,
    'syst': syst,
    'masse': masse,
    'part': part,
    'tendon': <String, Object?>{for (final e in tendon.entries) e.key: e.value},
    'verrou': verrou,
    'bloc': bloc,
  };
}

/// Extension de planification : replanification hebdomadaire.
class Planification extends Extension {
  /// [validateur] : fonction(blocs) → liste de constats de sécurité
  /// (critères de 0.3.1 lus sur les blocs) ; [options] : surcharge de
  /// `params['planification']` (banc : moins de trajectoires).
  Planification(this.params, this.fiches, this.validateur, [Json? options])
    : p = Map<String, Object?>.of(jm(params['planification'])) {
    p.addAll(options ?? const <String, Object?>{});
    // Le validateur de sécurité est obligatoire : sans lui aucun plan
    // modulé n'est contrôlé. `options['sans_validateur']` (essais de
    // parité numérique seulement) le remplace par un refus de TOUTE
    // modulation qui s'écarte de la référence au-delà des plafonds.
    if (validateur == null &&
        !vrai((options ?? const <String, Object?>{})['sans_validateur'])) {
      throw ArgumentError('Planification : validateur de sécurité obligatoire');
    }
  }

  final Json params;
  final Json p;
  final Map<String, Json> fiches;
  final Validateur? validateur;
  List<SemaineReference?> semaines = [];
  List<Json>? blocs;
  List<int>? blockWeeks;
  int horizon = 0;

  /// Exercice → charge totale visée (kg) ou valeur visée.
  Map<String, double> cibles = {};
  int? echeanceJour;

  /// Exercices suivis par le jumeau.
  List<String> suivis = [];

  /// Semaine → {'volume': [NQ facteurs], 'intensite': i}.
  Map<int, Json> plan = {};

  /// Une ligne par replanification.
  final List<Json> historique = [];
  List<List<Object?>>? constatsReference;
  double poidsCorps = 72.0;

  /// (moyenne, écart-type) de ln capacité du jour J prévue, par exercice
  /// suivi.
  (List<double>, List<double>)? _prevuJour;
  Map<int, TablePlanification?> _tables = {};

  /// Hypothèse de dose fixée par le tirage de Thompson (posée par [tirer]).
  int? hypotheseThompson;

  /// Lecture de `_prevu_jour` (tests).
  (List<double>, List<double>)? get prevuJour => _prevuJour;

  // ------------------------------------------------------------------
  // Référence
  // ------------------------------------------------------------------
  /// Plan de référence (blocs de `kalis_plan`), cibles {exercice : valeur
  /// visée (charge TOTALE pour un exercice chargé)}, jour de l'échéance
  /// (indice de jour depuis le début) ou null.
  void chargerReference(
    List<Json> blocs,
    List<int>? blockWeeks,
    int horizon, {
    Map<String, num>? cibles,
    int? echeanceJour,
    List<String>? principaux,
    num? poidsCorps,
  }) {
    this.blocs = blocs;
    this.blockWeeks = (blockWeeks != null && blockWeeks.isNotEmpty)
        ? List<int>.of(blockWeeks)
        : <int>[0];
    this.horizon = horizon;
    semaines = semainesDeReference(blocs, this.blockWeeks, horizon);
    this.cibles = <String, double>{
      for (final e in (cibles ?? const <String, num>{}).entries)
        e.key: e.value.toDouble(),
    };
    this.echeanceJour = echeanceJour;
    if (vrai(poidsCorps)) {
      this.poidsCorps = poidsCorps!.toDouble();
    }
    final suivis0 = this.cibles.keys.toList()..sort();
    for (final e in principaux ?? const <String>[]) {
      if (!suivis0.contains(e)) {
        suivis0.add(e);
      }
    }
    suivis = [
      for (final e in suivis0)
        if (fiches.containsKey(e)) e,
    ];
    plan = {};
    constatsReference = null;
    _tables = {};
  }

  // ------------------------------------------------------------------
  // Stimulus d'une prescription écrite
  // ------------------------------------------------------------------
  (double, double) _courbePopulation(bool bas) {
    final ap = jm(params['a_priori']);
    final lamb = dbl(jl(ap['courbe_forme'])[0]);
    final k =
        dbl(jl(ap['courbe_echelle'])[0]) +
        (bas ? dbl(ap['courbe_bas_du_corps']) : 0.0);
    return (lamb, k);
  }

  double _g(double lamb, double k, double r) => Modele.gK(lamb, k, r);

  /// Pente de la courbe, sans le plancher de `Modele._dg`.
  double _dg(double lamb, double k, double r0) {
    final r = r0 < 1 ? 1.0 : r0;
    final gam = 1.0 - lamb;
    return math.exp(k) *
        g8 *
        math.exp((gam - 1.0) * math.log(r)) /
        (ln8 * phiK(gam * ln8));
  }

  /// Séries d'une prescription sous un écart d'intensité : liste de
  /// (séries, réserve, part du 1RM ou null, secondes ou répétitions).
  List<(int, double, double?, double)> lignesItem(
    Json item, [
    double ecart = 0.0,
  ]) {
    if (item['kind'] == 'warmup') {
      return [];
    }
    final fiche = fiches[item['exerciseId']];
    if (fiche == null) {
      return [];
    }
    final n = _plSeries(item);
    if (n <= 0) {
      return [];
    }
    final test = dictOuVide(item['test']);
    var rir = planificationRirDeFlammes(item['targetFlames']);
    if (item['kind'] == 'test') {
      rir = test['targetRir'] != null ? dbl(test['targetRir']) : 1.0;
    }
    final lo = item['repsLow'];
    final hi = item['repsHigh'];
    double? reps;
    if (lo != null || hi != null) {
      reps = (dbl(lo ?? hi) + dbl(hi ?? lo)) / 2.0;
    }
    final sec = item['secondsHigh'] ?? item['secondsLow'];
    final quantite = reps ?? (vrai(sec) ? dbl(sec) / 10.0 : 1.0);
    double? part;
    var pente = 0.03;
    if (fiche['type'] == 'charge') {
      final (lamb, k) = _courbePopulation(vrai(fiche['bas']));
      final r = (reps ?? 8.0) + rir;
      part = dblOu(item['percentOfOneRm']);
      part ??= math.exp(-_g(lamb, k, r));
      pente = _dg(lamb, k, r);
    }
    if (ecart != 0.0 && part != null) {
      part = part * (1.0 + ecart);
      rir = rir - ecart / pente;
      if (rir < 0.5) {
        rir = 0.5;
      }
    }
    final tech = dictOuVide(item['technique']);
    if (tech['kind'] == 'top_set_backoff' && n >= 2 && part != null) {
      final drop = vrai(tech['backoffDropPct'])
          ? dbl(tech['backoffDropPct'])
          : 0.08;
      return [
        (1, rir, part, quantite),
        (n - 1, rir + drop / pente, part * (1.0 - drop), quantite),
      ];
    }
    return [(n, rir, part, quantite)];
  }

  /// (volume, effort, intensité, charge systémique, charge tendineuse)
  /// d'une prescription, par convention identique à `Modele._stimulus`.
  (double, double, double, double, double) stimulusItem(
    Json item, [
    double ecart = 0.0,
  ]) {
    final fiche = fiches[item['exerciseId']] ?? <String, Object?>{};
    final f = jm(params['fatigue']);
    var vol = 0.0;
    var eff = 0.0;
    var inten = 0.0;
    var syst = 0.0;
    var tend = 0.0;
    for (final (n, rir, part, quantite) in lignesItem(item, ecart)) {
      vol += n * (rir <= 4 ? 1.0 : 0.5);
      eff += n / (1.0 + (rir > 1 ? rir - 1 : 0.0) / 3.0);
      final pp = part ?? 1.0;
      inten += n * clampD((pp - 0.4) / 0.4, 0.2, 1.5);
      final effort =
          1.0 / (1.0 + (rir > 0 ? rir : 0.0) / dbl(f['effort_demi_rir']));
      syst += n * effort * dbl(fiche['systemique'] ?? 1.0);
      tend +=
          n *
          effort *
          dbl(fiche['tendon'] ?? 0.0) *
          (fiche['type'] == 'tenue' ? quantite : 1.0);
    }
    return (vol, eff, inten, syst, tend);
  }

  /// `_table` (accès public pour les essais de parité).
  TablePlanification? table(int w) => _table(w);

  /// Tables de la semaine écrite [w] : par point de la grille d'intensité,
  /// stimulus des exercices suivis (par unité de facteur de volume), charge
  /// systémique par qualité et par jour, masse de séries par qualité, part
  /// moyenne du 1RM par qualité, charge tendineuse par zone et par qualité.
  TablePlanification? _table(int w) {
    if (_tables.containsKey(w)) {
      return _tables[w];
    }
    final s = (0 <= w && w < semaines.length) ? semaines[w] : null;
    if (s == null) {
      _tables[w] = null;
      return null;
    }
    final ne = suivis.length;
    final nGrille = grilleIntensite.length;
    final stim = <List<List<double>>>[
      for (var gi = 0; gi < nGrille; gi++)
        [for (var e = 0; e < ne; e++) List<double>.filled(3, 0.0)],
    ];
    // Par jour de la semaine.
    final syst = <List<List<double>>>[
      for (var gi = 0; gi < nGrille; gi++)
        [for (var d = 0; d < 7; d++) List<double>.filled(nq, 0.0)],
    ];
    final masse = List<double>.filled(nq, 0.0);
    final partM = List<double>.filled(nq, 0.0);
    final tendon = <String, List<double>>{};
    for (final (jour, items) in s.jours) {
      final d = jour % 7;
      for (final item in items) {
        final fiche = fiches[item['exerciseId']];
        if (fiche == null || item['kind'] == 'warmup') {
          continue;
        }
        final v = jld(fiche['vecteur']);
        final lignes = lignesItem(item, 0.0);
        var nTot = 0;
        for (final l in lignes) {
          nTot += l.$1;
        }
        if (nTot <= 0) {
          continue;
        }
        for (var q = 0; q < nq; q++) {
          masse[q] += nTot * v[q];
        }
        // sum() de Python : séquentiel, départ 0.
        var pm = 0.0;
        for (final l in lignes) {
          pm += l.$1 * (l.$3 ?? 0.7);
        }
        for (var q = 0; q < nq; q++) {
          partM[q] += pm * v[q];
        }
        for (var gi = 0; gi < nGrille; gi++) {
          final ecart = grilleIntensite[gi];
          final (vol, eff, inten, sy, te) = stimulusItem(item, ecart);
          if (suivis.contains(item['exerciseId'])) {
            final e = suivis.indexOf(item['exerciseId'] as String);
            stim[gi][e][0] += vol;
            stim[gi][e][1] += eff;
            stim[gi][e][2] += inten;
          }
          for (var q = 0; q < nq; q++) {
            syst[gi][d][q] += sy * v[q];
          }
          if (gi == 2 && te > 0 && vrai(fiche['zone_tendon'])) {
            final z = fiche['zone_tendon'] as String;
            final tz = tendon.putIfAbsent(z, () => List<double>.filled(nq, 0.0));
            for (var q = 0; q < nq; q++) {
              tz[q] += te * v[q];
            }
          }
        }
      }
    }
    for (var q = 0; q < nq; q++) {
      if (masse[q] > 0) {
        partM[q] /= masse[q];
      }
    }
    final t = TablePlanification(
      stim,
      syst,
      masse,
      partM,
      tendon,
      verrouillee(s),
      s.bloc,
    );
    _tables[w] = t;
    return t;
  }

  // ------------------------------------------------------------------
  // Jumeau numérique
  // ------------------------------------------------------------------
  /// Tire [n] trajectoires de l'a posteriori : ln capacité des exercices
  /// suivis, réponse rho, écarts par classe, hypothèse de dose, bruits
  /// communs (jour de l'échéance, processus).
  ///
  /// Sortie (mêmes clés que la référence) : `mu` (n × E), `rho` (n), `eps`
  /// (n × 5) : `List<List<double>>` / `List<double>` ; `hyp` (`List<int>`) ;
  /// `bruit_jour`, `bruit_proc`, `bruit_est`, `manque` (n × max(E, 1)) ;
  /// `bruit_seance` (n) ; `classes` (`List<int>`) ; `fatigue`, `kg`
  /// (double) ; `semaines` (int) ; `hypotheses` (liste de `[s0, k]`).
  Json tirer(Koach koach, int semaine, int n) {
    final m = koach.modele;
    final ne = suivis.length;
    final lignes = <List<double>>[];
    final moyennes = <double>[];
    for (final ex in suivis) {
      m.piste(ex); // crée les pistes avant de figer la taille de l'état
    }
    for (final ex in suivis) {
      final t = m.piste(ex);
      final h = List<double>.filled(m.n, 0.0);
      var base = 0.0;
      if (t != null) {
        final (idx, co) = m.hCapacite(t, jour: false);
        for (var r = 0; r < idx.length; r++) {
          h[idx[r]] += co[r];
        }
        base = t.base;
      }
      lignes.add(h);
      // numpy : `h @ m.m[:m.n]` (1-D @ 1-D) → ddot d'OpenBLAS (accumulateurs
      // vectoriels, FMA) ; ici somme séquentielle (h est creux : seuls les
      // termes non nuls comptent, leur ordre d'accumulation peut différer).
      moyennes.add(base + _plDot(h, m.m));
    }
    for (final i in [rho, for (var c = 0; c < classesK.length; c++) eps + c]) {
      final h = List<double>.filled(m.n, 0.0);
      h[i] = 1.0;
      lignes.add(h);
      moyennes.add(m.m[i]);
    }
    // numpy : `H @ P[:n, :n] @ H.T` → deux dgemm ; ici séquentiel.
    final s0 = _plHPHt(lignes, m);
    final k = s0.length;
    final s = <List<double>>[
      for (var a = 0; a < k; a++)
        [for (var b = 0; b < k; b++) 0.5 * (s0[a][b] + s0[b][a])],
    ];
    // Racine de Cholesky en boucles explicites (portable à l'identique,
    // robuste à une covariance semi-définie).
    final l = choleskySemi(s);
    final rng = Mulberry32(fnv1a32('koach-plan:${ent(p['graine'])}:$semaine'));
    final z = <List<double>>[
      for (var a = 0; a < n; a++) List<double>.filled(k, 0.0),
    ];
    for (var a = 0; a < n; a++) {
      for (var b = 0; b < k; b++) {
        z[a][b] = rng.gauss();
      }
    }
    // numpy : `moyennes[None, :] + z @ L.T` → dgemm ; ici x[a][b] =
    // moyennes[b] + Σ_q z[a][q]·L[b][q], q croissant.
    final x = <List<double>>[
      for (var a = 0; a < n; a++)
        [for (var b = 0; b < k; b++) moyennes[b] + _plDot(z[a], l[b])],
    ];
    final hyp = List<int>.filled(n, 0);
    final poids = List<double>.of(m.poidsHyp);
    final tot = somme(poids);
    // Contrôle dual (cahier § 7) : quand le modèle est calibré, le
    // contrôle dual tire UNE hypothèse de dose pour la semaine (tirage
    // de Thompson) et le plan est optimisé sous elle ; sinon chaque
    // trajectoire tire la sienne selon les poids a posteriori. Les
    // tirages uniformes sont consommés dans les deux cas (mêmes nombres
    // aléatoires communs en aval).
    hypotheseThompson = null;
    for (final Object xe in koach.extensions) {
      if (xe is AvecHypothese) {
        hypotheseThompson = xe.hypothesePourLaSemaine(
          koach,
          semaine,
          ent(p['graine']),
        );
      }
    }
    for (var a = 0; a < n; a++) {
      final u = rng.next() * tot;
      var c = 0.0;
      hyp[a] = poids.length - 1;
      for (var j = 0; j < poids.length; j++) {
        c += poids[j];
        if (u < c) {
          hyp[a] = j;
          break;
        }
      }
    }
    final ht = hypotheseThompson;
    if (ht != null) {
      for (var a = 0; a < n; a++) {
        hyp[a] = ht;
      }
    }
    final nb = math.max(ne, 1);
    final bruitJour = <List<double>>[
      for (var a = 0; a < n; a++) List<double>.filled(nb, 0.0),
    ];
    final bruitProc = <List<double>>[
      for (var a = 0; a < n; a++) List<double>.filled(nb, 0.0),
    ];
    for (var a = 0; a < n; a++) {
      for (var b = 0; b < nb; b++) {
        bruitJour[a][b] = rng.gauss();
        bruitProc[a][b] = rng.gauss();
      }
    }
    final classes = <int>[];
    for (final ex in suivis) {
      final t = m.piste(ex);
      classes.add(t?.classe ?? 0);
    }
    // Jour de l'échéance (tirés après tous les autres : les nombres
    // aléatoires communs des tirages précédents ne bougent pas) : effet
    // de jour de la SÉANCE, commun à toutes les cibles testées ce
    // jour-là ; erreur de l'estimation que Koach aura lui-même le jour J
    // (c'est elle qui fixe les barres tentées) ; manque de l'échelle des
    // tentatives par rapport à sa barre la plus haute possible.
    final bruitSeance = List<double>.filled(n, 0.0);
    final bruitEst = <List<double>>[
      for (var a = 0; a < n; a++) List<double>.filled(nb, 0.0),
    ];
    final manque = <List<double>>[
      for (var a = 0; a < n; a++) List<double>.filled(nb, 0.0),
    ];
    for (var a = 0; a < n; a++) {
      bruitSeance[a] = rng.gauss();
      for (var b = 0; b < nb; b++) {
        bruitEst[a][b] = rng.gauss();
        final u = rng.next();
        manque[a][b] = -math.log(u < 1.0 - 1e-12 ? 1.0 - u : 1e-12);
      }
    }
    return <String, Object?>{
      'mu': <List<double>>[
        for (var a = 0; a < n; a++) [for (var b = 0; b < ne; b++) x[a][b]],
      ],
      'rho': <double>[for (var a = 0; a < n; a++) x[a][ne]],
      'eps': <List<double>>[
        for (var a = 0; a < n; a++) [for (var b = ne + 1; b < k; b++) x[a][b]],
      ],
      'hyp': hyp,
      'bruit_jour': bruitJour,
      'bruit_proc': bruitProc,
      'classes': classes,
      'bruit_seance': bruitSeance,
      'bruit_est': bruitEst,
      'manque': manque,
      'fatigue': m.fG[1],
      'kg': m.m[kg],
      'semaines': m.semaines,
      'hypotheses': <Object?>[
        for (final (hs0, hk) in m.hypotheses) <Object?>[hs0, hk],
      ],
    };
  }

  /// `_dimensions` (accès public pour les essais de parité).
  (List<int>, List<int>) dimensions(int depuis) => _dimensions(depuis);

  /// Blocs restants et qualités actives à partir de la semaine [depuis].
  (List<int>, List<int>) _dimensions(int depuis) {
    final bl = <int>[];
    final actives = List<bool>.filled(nq, false);
    for (var w = depuis; w < horizon; w++) {
      final t = _table(w);
      if (t == null) {
        continue;
      }
      if (!bl.contains(t.bloc)) {
        bl.add(t.bloc);
      }
      for (var q = 0; q < nq; q++) {
        actives[q] = actives[q] || t.masse[q] > 0;
      }
    }
    return (
      bl,
      [
        for (var q = 0; q < nq; q++)
          if (actives[q]) q,
      ],
    );
  }

  /// Vecteur de recherche → (volume[bloc][NQ], intensité[bloc]).
  (Map<int, List<double>>, Map<int, double>) decoder(
    List<double> x,
    List<int> blocsIdx,
    List<int> qualites,
  ) {
    final nqa = qualites.length;
    final vol = <int, List<double>>{};
    final inten = <int, double>{};
    final pv = dbl(p['plafond_volume']);
    final pi = dbl(p['plafond_intensite']);
    for (var j = 0; j < blocsIdx.length; j++) {
      final b = blocsIdx[j];
      final a = List<double>.filled(nq, 1.0);
      for (var i = 0; i < nqa; i++) {
        final q = qualites[i];
        a[q] = 1.0 + clampD(x[j * (nqa + 1) + i], -pv, pv);
      }
      vol[b] = a;
      inten[b] = clampD(x[j * (nqa + 1) + nqa], -pi, pi);
    }
    return (vol, inten);
  }

  /// Valeur de chaque plan candidat (lignes de [xx]) sous le jumeau.
  /// Renvoie (valeur, P par cible, distance de transport, détail) ; le
  /// détail (null sans [detail]) a les clés `J`, `penal`, `fatigue_fin`,
  /// `fatigue_echeance` (null sans échéance dans l'horizon évalué) et
  /// `gains` (C × E × nh).
  (List<double>, List<List<double>>, List<double>, Json?) evaluer(
    List<List<double>> xx,
    Json tirage,
    int depuis,
    List<int> blocsIdx,
    List<int> qualites, {
    bool detail = false,
    double? echelle,
  }) {
    final dyn = jm(params['dynamique']);
    final pl = p;
    final cc = xx.length;
    final ne = suivis.length;
    final nqa = qualites.length;
    final pv = dbl(pl['plafond_volume']);
    final pi = dbl(pl['plafond_intensite']);
    final aa = <List<List<double>>>[
      for (var c = 0; c < cc; c++)
        [for (var j = 0; j < blocsIdx.length; j++) List<double>.filled(nq, 1.0)],
    ];
    final ii = <List<double>>[
      for (var c = 0; c < cc; c++) List<double>.filled(blocsIdx.length, 0.0),
    ];
    for (var j = 0; j < blocsIdx.length; j++) {
      for (var i = 0; i < nqa; i++) {
        final q = qualites[i];
        for (var c = 0; c < cc; c++) {
          aa[c][j][q] = 1.0 + _plClip(xx[c][j * (nqa + 1) + i], -pv, pv);
        }
      }
      for (var c = 0; c < cc; c++) {
        ii[c][j] = _plClip(xx[c][j * (nqa + 1) + nqa], -pi, pi);
      }
    }
    final vv = <List<double>>[
      for (final ex in suivis) jld(fiches[ex]!['vecteur']),
    ];
    final hyps = <(double, int)>[
      for (final h in jl(tirage['hypotheses'])) _plHyp(h),
    ];
    final nh = hyps.length;
    var fin = horizon - 1;
    final jourEch = echeanceJour;
    if (jourEch != null) {
      fin = math.min(fin, divEnt(jourEch, 7));
    } else if (cibles.isEmpty) {
      fin = math.min(
        fin,
        depuis + ent(pl['horizon_sans_echeance_sem']) - 1,
      );
    }
    var ff = List<double>.filled(cc, dbl(tirage['fatigue']));
    final gains = <List<List<double>>>[
      for (var c = 0; c < cc; c++)
        [for (var e = 0; e < ne; e++) List<double>.filled(nh, 0.0)],
    ];
    final transport = List<double>.filled(cc, 0.0);
    var masseRef = 0.0;
    final surcharge = List<double>.filled(cc, 0.0);
    final penal = List<double>.filled(cc, 0.0);
    final tendonHist = <String, List<(List<double>, double)>>{};
    List<double>? fEch;
    final refDose = dbl(dyn['dose_reference']);
    final acc0 = ent(tirage['semaines']);
    for (var w = depuis; w < fin + 1; w++) {
      final t = _table(w);
      if (t == null) {
        final e7 = math.exp(-7.0 / _tauLent());
        ff = [for (var c = 0; c < cc; c++) ff[c] * e7];
        continue;
      }
      final j = blocsIdx.indexOf(t.bloc);
      var a = <List<double>>[
        for (var c = 0; c < cc; c++) List<double>.of(aa[c][j]),
      ];
      var i = <double>[for (var c = 0; c < cc; c++) ii[c][j]];
      if (t.verrou) {
        a = [
          for (var c = 0; c < cc; c++)
            [for (var q = 0; q < nq; q++) _plMinimum(a[c][q], 1.0)],
        ];
        i = [for (var c = 0; c < cc; c++) _plMinimum(i[c], 0.0)];
      }
      // Interpolation linéaire sur la grille d'intensité.
      final g0 = List<int>.filled(cc, 0);
      final fr = List<double>.filled(cc, 0.0);
      for (var c = 0; c < cc; c++) {
        final pos =
            (i[c] - grilleIntensite[0]) /
            (grilleIntensite[1] - grilleIntensite[0]);
        var g = pos.floor();
        if (g < 0) {
          g = 0;
        }
        if (g > grilleIntensite.length - 2) {
          g = grilleIntensite.length - 2;
        }
        g0[c] = g;
        fr[c] = pos - g;
      }
      final stim = <List<List<double>>>[
        for (var c = 0; c < cc; c++)
          [
            for (var e = 0; e < ne; e++)
              [
                for (var k = 0; k < 3; k++)
                  t.stim[g0[c]][e][k] * (1 - fr[c]) +
                      t.stim[g0[c] + 1][e][k] * fr[c],
              ],
          ],
      ];
      final syst = <List<List<double>>>[
        for (var c = 0; c < cc; c++)
          [
            for (var d = 0; d < 7; d++)
              [
                for (var q = 0; q < nq; q++)
                  t.syst[g0[c]][d][q] * (1 - fr[c]) +
                      t.syst[g0[c] + 1][d][q] * fr[c],
              ],
          ],
      ];
      // Facteur de volume par exercice. numpy : `a @ V.T` → dgemm ; ici
      // séquentiel sur q.
      final fe = <List<double>>[
        for (var c = 0; c < cc; c++)
          [for (var e = 0; e < ne; e++) _plDot(a[c], vv[e])],
      ];
      for (var c = 0; c < cc; c++) {
        for (var e = 0; e < ne; e++) {
          for (var k = 0; k < 3; k++) {
            stim[c][e][k] = stim[c][e][k] * fe[c][e];
          }
        }
      }
      // (C, 7). numpy : `np.einsum('cdq,cq->cd', syst, a)` (voir
      // `_plEinsumQ`).
      final chargeJour = <List<double>>[
        for (var c = 0; c < cc; c++)
          [for (var d = 0; d < 7; d++) _plEinsumQ(syst[c][d], a[c])],
      ];
      // Fatigue lente en fin de semaine, et au matin de l'échéance.
      final decro = <double>[
        for (var d = 0; d < 7; d++) _plNpExp(-(7.0 - d) / _tauLent()),
      ];
      if (jourEch != null && w == divEnt(jourEch, 7)) {
        final jde = jourEch % 7;
        final avant = <double>[
          for (var d = 0; d < 7; d++)
            d < jde ? math.exp(-(jde - d) / _tauLent()) : 0.0,
        ];
        final eDe = math.exp(-jde / _tauLent());
        // numpy : `charge_jour @ avant` → dgemv ; ici séquentiel sur d.
        fEch = <double>[
          for (var c = 0; c < cc; c++)
            ff[c] * eDe + _plDot(chargeJour[c], avant),
        ];
      }
      final e7 = math.exp(-7.0 / _tauLent());
      // numpy : `charge_jour @ decro` → dgemv ; ici séquentiel sur d.
      ff = <double>[
        for (var c = 0; c < cc; c++) ff[c] * e7 + _plDot(chargeJour[c], decro),
      ];
      final seuil = dbl(dyn['recuperation_seuil']);
      final kRec = <double>[
        for (var c = 0; c < cc; c++)
          _plMaximum(
            1.0 -
                dbl(dyn['recuperation_pente']) *
                    _plMaximum(ff[c] - seuil, 0.0) /
                    seuil,
            dbl(dyn['recuperation_plancher']),
          ),
      ];
      final acc =
          1.0 /
          (1.0 + (acc0 + (w - depuis)) / dbl(dyn['accoutumance_semaines']));
      for (var h = 0; h < nh; h++) {
        final (s0, ks) = hyps[h];
        final den = 1.0 - math.exp(-refDose / s0);
        for (var c = 0; c < cc; c++) {
          final kra = kRec[c] * acc;
          for (var e = 0; e < ne; e++) {
            final sv = stim[c][e][ks];
            final dose = (1.0 - _plNpExp(-sv / s0)) / den;
            gains[c][e][h] += dose * kra;
          }
        }
      }
      // Transport optimal (1-D, par qualité) : la masse commune se
      // déplace de l'écart d'intensité, la masse créée ou retirée coûte
      // `transport_creation` par série.
      final mr = t.masse;
      final tc = dbl(pl['transport_creation']);
      for (var c = 0; c < cc; c++) {
        final absI = i[c].abs();
        final mp = <double>[for (var q = 0; q < nq; q++) a[c][q] * mr[q]];
        // numpy : `.sum(axis=1)` sur l'axe contigu de NQ = 10 éléments →
        // sommation par paires.
        final terme1 = <double>[
          for (var q = 0; q < nq; q++)
            _plMinimum(mp[q], mr[q]) * (t.part[q] * absI),
        ];
        final terme2 = <double>[
          for (var q = 0; q < nq; q++) (mp[q] - mr[q]).abs(),
        ];
        transport[c] +=
            _plSommePaires(terme1) + tc * _plSommePaires(terme2);
      }
      // numpy : `mr.sum()` (10 éléments contigus) → sommation par paires.
      masseRef += _plSommePaires(mr);
      // Charge de travail relative (sans échéance : P(continuer)).
      // numpy : `t['syst'][2].sum()` (7 × 10 contigus = 70) → par paires.
      final refCharge = _plSommePaires(<double>[
        for (var d = 0; d < 7; d++)
          for (var q = 0; q < nq; q++) t.syst[2][d][q],
      ]);
      if (refCharge > 0) {
        for (var c = 0; c < cc; c++) {
          // numpy : `charge_jour.sum(axis=1)` (7 < 8 éléments) →
          // séquentiel.
          surcharge[c] += _plMaximum(
            _plSommePaires(chargeJour[c]) / refCharge - 1.0,
            0.0,
          );
        }
      }
      // Tendons : charge de la semaine / moyenne des 4 semaines d'avant.
      final ratioMax = dbl(pl['risque_tendon_ratio_max']);
      final plancher = dbl(pl['risque_tendon_plancher']);
      for (final MapEntry(key: z, value: tq) in t.tendon.entries) {
        // numpy : `a @ tq` → dgemv ; ici séquentiel sur q.
        final cw = <double>[for (var c = 0; c < cc; c++) _plDot(a[c], tq)];
        // numpy : `tq.sum()` → par paires.
        final rw = _plSommePaires(tq);
        final hist = tendonHist.putIfAbsent(z, () => []);
        if (hist.isNotEmpty) {
          final dern = hist.sublist(math.max(0, hist.length - 4));
          // sum() de Python sur des tableaux : 0 + cw₁ + cw₂ + … élément
          // par élément.
          final moyC = List<double>.filled(cc, 0.0);
          for (var c = 0; c < cc; c++) {
            var sc = 0.0;
            for (final x in dern) {
              sc += x.$1[c];
            }
            moyC[c] = sc / dern.length;
          }
          var sr = 0.0;
          for (final x in dern) {
            sr += x.$2;
          }
          final moyR = sr / dern.length;
          if (moyR >= plancher) {
            final rr = rw / moyR;
            final limite = rr > ratioMax ? rr : ratioMax;
            for (var c = 0; c < cc; c++) {
              penal[c] +=
                  (cw[c] / _plMaximum(moyC[c], 1e-9) > limite + 1e-9) ? 1.0 : 0.0;
            }
          }
        }
        hist.add((cw, rw));
      }
    }
    final distance = masseRef > 0
        ? <double>[for (var c = 0; c < cc; c++) transport[c] / masseRef]
        : List<double>.of(transport);
    // Trajectoires.
    final mu = _plMat(tirage['mu']);
    final nn = mu.length;
    final hyp = _plEnts(tirage['hyp']);
    final pCible = <List<double>>[
      for (var c = 0; c < cc; c++) List<double>.filled(ne, 0.0),
    ];
    var jj = List<double>.filled(cc, 0.0);
    if (ne > 0) {
      final rhoT = _plVec(tirage['rho']);
      final epsT = _plMat(tirage['eps']);
      final classes = _plEnts(tirage['classes']);
      final bruitProc = _plMat(tirage['bruit_proc']);
      // (N, E)
      final taux = <List<double>>[
        for (var n = 0; n < nn; n++)
          [for (var e = 0; e < ne; e++) rhoT[n] + epsT[n][classes[e]]],
      ];
      final semainesS = math.max(1, fin + 1 - depuis);
      final proc = math.sqrt(
        dbl(dyn['q_delta_semaine']) * semainesS +
            pw(dbl(pl['sigma_prevision_semaine']), 2.0) * semainesS,
      );
      // (C, E, N) : μ + gains[hyp]·taux + proc·bruit_proc.
      final muFin = <List<List<double>>>[
        for (var c = 0; c < cc; c++)
          [
            for (var e = 0; e < ne; e++)
              [
                for (var n = 0; n < nn; n++)
                  mu[n][e] +
                      gains[c][e][hyp[n]] * taux[n][e] +
                      proc * bruitProc[n][e],
              ],
          ],
      ];
      final jourE = jourEch;
      if (cibles.isNotEmpty && jourE != null) {
        final pj = jm(params['jour']);
        final sec = jm(params['securite']);
        final fe2 = fEch ?? ff;
        final kgT = dbl(tirage['kg']);
        final gainAff = dbl(pl['gain_affutage']);
        // Capacité à frais le jour J (fatigue lente comprise), puis
        // capacité du jour : effet de jour de la séance (commun aux
        // cibles : elles réussissent ou échouent ensemble) et de
        // l'exercice ; gain moyen de l'affûtage mesuré sur le banc.
        final frais = <List<List<double>>>[
          for (var c = 0; c < cc; c++)
            [
              for (var e = 0; e < ne; e++)
                [
                  for (var n = 0; n < nn; n++)
                    muFin[c][e][n] - kgT * fe2[c] + gainAff,
                ],
            ],
        ];
        // numpy : `frais[0].mean(axis=1)`, `frais[0].std(axis=1)` → sommes
        // par paires sur N (vérifié pour toutes les formes rencontrées).
        final moyP = <double>[];
        final sdP = <double>[];
        for (var e = 0; e < ne; e++) {
          final row = frais[0][e];
          final mo = _plSommePaires(row) / nn;
          moyP.add(mo);
          final dev = <double>[for (final v in row) (v - mo) * (v - mo)];
          sdP.add(math.sqrt(_plSommePaires(dev) / nn));
        }
        _prevuJour = (moyP, sdP);
        final ss = dbl(pj['sigma_seance']);
        final se = dbl(pj['sigma_exercice']);
        final bSeance = _plVec(tirage['bruit_seance']);
        final bJour = _plMat(tirage['bruit_jour']);
        final jourC = <List<List<double>>>[
          for (var c = 0; c < cc; c++)
            [
              for (var e = 0; e < ne; e++)
                [
                  for (var n = 0; n < nn; n++)
                    frais[c][e][n] + ss * bSeance[n] + se * bJour[n][e],
                ],
            ],
        ];
        final tout = <List<bool>>[
          for (var c = 0; c < cc; c++) List<bool>.filled(nn, true),
        ];
        final z1 = normPpfK(dbl(sec['tentative_ouverture_proba']));
        final z2 = normPpfK(dbl(sec['tentative_deuxieme_proba']));
        final z3 = normPpfK(dbl(sec['tentative_troisieme_proba']));
        final zc = normPpfK(dbl(pl['tentative_cible_proba']));
        final sj = dbl(pl['tentative_sd_jour']);
        final bEst = _plMat(tirage['bruit_est']);
        final manque = _plMat(tirage['manque']);
        for (var e = 0; e < ne; e++) {
          final ex = suivis[e];
          if (!cibles.containsKey(ex)) {
            continue;
          }
          final lnT = math.log(cibles[ex]!);
          if (fiches[ex]!['type'] == 'charge') {
            // Cible chargée : le jour J compte la barre RÉUSSIE.
            // Elle est atteinte si l'échelle des tentatives
            // (règles A8.2 de 0.3.1, `seance._tentative`) va
            // jusqu'à la cible ET si l'athlète la soulève.
            // L'échelle part de l'estimation que Koach aura ce
            // jour-là : capacité vraie + erreur d'estimation.
            final errSd = dbl(pl['erreur_estimation_echeance_sd']);
            final o1 = math.log(dbl(sec['tentative_ouverture_part']));
            final o2 = -z1 * sj;
            final dA1 = _plMinPy(o1, o2);
            final l2 = math.log(1.0 + dbl(sec['tentative_saut_2']));
            final l3 = math.log(1.0 + dbl(sec['tentative_saut_3']));
            final skg = dbl(sec['tentative_saut_kg']);
            final coefManque = dbl(pl['tentative_manque']);
            for (var c = 0; c < cc; c++) {
              var nOk = 0;
              for (var n = 0; n < nn; n++) {
                final est = frais[c][e][n] + errSd * bEst[n][e];
                final a1 = est + dA1;
                final a2 = _plMinimum(
                  _plMinimum(est - z2 * sj, a1 + l2),
                  _plNpLog(_plNpExp(a1) + skg),
                );
                final a3 = _plMinimum(a2 + l3, _plNpLog(_plNpExp(a2) + skg));
                // Dernier essai : la barre visée est tentée si elle
                // est à portée de saut et tenue pour assez probable ;
                // sinon la barre du quantile de la 3e tentative.
                final vise = (lnT <= a3) && (lnT <= est - zc * sj);
                var haut = vise ? a3 : _plMinimum(a3, est - z3 * sj);
                haut = haut - coefManque * manque[n][e];
                final ok = (haut >= lnT - 1e-12) && (jourC[c][e][n] >= lnT);
                if (ok) {
                  nOk++;
                }
                tout[c][n] = tout[c][n] && ok;
              }
              // numpy : moyenne de booléens (somme exacte) / N.
              pCible[c][e] = nOk / nn;
            }
          } else {
            // Répétitions ou tenue maximales : rendement du test
            // (valeur faite / maximum du jour) et dispersion de
            // la prévision mesurés sur le banc.
            final rendSd = dbl(pl['rendement_test_sd']);
            final marge = dbl(pl['marge_cible']);
            for (var c = 0; c < cc; c++) {
              var nOk = 0;
              for (var n = 0; n < nn; n++) {
                final ok =
                    jourC[c][e][n] + rendSd * bEst[n][e] >= lnT + marge;
                if (ok) {
                  nOk++;
                }
                tout[c][n] = tout[c][n] && ok;
              }
              pCible[c][e] = nOk / nn;
            }
          }
        }
        jj = <double>[
          for (var c = 0; c < cc; c++) _plCompte(tout[c]) / nn,
        ];
      } else {
        // Sans échéance : progression attendue (relative à celle du
        // plan de référence nul) × P(continuer).
        final abandon = dbl(pl['abandon_hebdo']);
        final abandonSur = dbl(pl['abandon_surcharge']);
        jj = <double>[
          for (var c = 0; c < cc; c++)
            _plProgression(muFin[c], mu, ne, nn, cc) *
                _plNpExp(-abandon * (semainesS + abandonSur * surcharge[c])),
        ];
        if (echelle != null && echelle != 0.0) {
          jj = <double>[for (var c = 0; c < cc; c++) jj[c] / echelle];
        }
      }
    }
    final lt = dbl(pl['lambda_transport']);
    final valeur = <double>[
      for (var c = 0; c < cc; c++) jj[c] - lt * distance[c] - penal[c],
    ];
    if (detail) {
      return (
        valeur,
        pCible,
        distance,
        <String, Object?>{
          'J': jj,
          'penal': penal,
          'fatigue_fin': ff,
          'fatigue_echeance': fEch,
          'gains': gains,
        },
      );
    }
    return (valeur, pCible, distance, null);
  }

  double _tauLent() => dbl(jm(params['fatigue'])['tau_musculaire_j']);

  // ------------------------------------------------------------------
  // Recherche par entropie croisée
  // ------------------------------------------------------------------
  /// Replanifie de la semaine [semaine] à l'échéance. Renvoie la ligne
  /// d'historique écrite.
  Json replanifier(Koach koach, int semaine) {
    final pl = p;
    _prevuJour = null;
    final (blocsIdx, qualites) = _dimensions(semaine);
    final ligne = <String, Object?>{
      'semaine': semaine,
      'jour': koach.modele.jour,
      'plans': 0,
    };
    if (blocsIdx.isEmpty || suivis.isEmpty) {
      historique.add(ligne);
      return ligne;
    }
    final n = ent(pl['trajectoires']);
    final tirage = tirer(koach, semaine, n);
    final nqa = qualites.length;
    final d = blocsIdx.length * (nqa + 1);
    final iters = ent(pl['iterations']);
    final pop = math.max(4, divEnt(ent(pl['plans_max']), iters));
    final rng = Mulberry32(fnv1a32('koach-cem:${ent(pl['graine'])}:$semaine'));
    var moy = List<double>.filled(d, 0.0);
    // Départ : le plan en cours (continuité d'une semaine à l'autre).
    for (var j = 0; j < blocsIdx.length; j++) {
      final b = blocsIdx[j];
      for (var w = semaine; w < horizon; w++) {
        final t = _table(w);
        final pw0 = plan[w];
        if (t != null && t.bloc == b && pw0 != null) {
          final volW = jl(pw0['volume']);
          for (var i = 0; i < nqa; i++) {
            final q = qualites[i];
            moy[j * (nqa + 1) + i] = dbl(volW[q]) - 1.0;
          }
          moy[j * (nqa + 1) + nqa] = dbl(pw0['intensite']);
          break;
        }
      }
    }
    final pv = dbl(pl['plafond_volume']);
    final pi = dbl(pl['plafond_intensite']);
    var ecart = List<double>.filled(d, 0.0);
    for (var j = 0; j < blocsIdx.length; j++) {
      for (var i = 0; i < nqa; i++) {
        ecart[j * (nqa + 1) + i] = pv * 0.5;
      }
      ecart[j * (nqa + 1) + nqa] = pi * 0.5;
    }
    final borne = List<double>.filled(d, 0.0);
    for (var j = 0; j < blocsIdx.length; j++) {
      for (var i = 0; i < nqa; i++) {
        borne[j * (nqa + 1) + i] = pv;
      }
      borne[j * (nqa + 1) + nqa] = pi;
    }
    // Sans échéance, l'objectif est exprimé en part de la valeur du plan
    // de référence (comparable à la pénalité de transport).
    double? echelle;
    if (!(cibles.isNotEmpty && echeanceJour != null)) {
      final (_, _, _, det0) = evaluer(
        [List<double>.filled(d, 0.0)],
        tirage,
        semaine,
        blocsIdx,
        qualites,
        detail: true,
      );
      final j0 = (det0!['J'] as List<double>)[0];
      echelle = j0 > 1e-9 ? j0 : null;
    }
    var meilleurX = List<double>.filled(d, 0.0);
    double? meilleureV;
    var evalues = 0;
    final eliteN = math.max(2, arrondi(pop * dbl(pl['elite'])).truncate());
    final lis = dbl(pl['lissage']);
    var candidatsFinaux = <List<double>>[];
    for (var it = 0; it < iters; it++) {
      final xx = <List<double>>[
        for (var a = 0; a < pop; a++) List<double>.filled(d, 0.0),
      ];
      // X[0] = 0 : la référence est toujours candidate.
      for (var b = 0; b < d; b++) {
        xx[1][b] = moy[b];
      }
      for (var a = 2; a < pop; a++) {
        for (var b = 0; b < d; b++) {
          xx[a][b] = moy[b] + ecart[b] * rng.gauss();
        }
      }
      for (var a = 0; a < pop; a++) {
        for (var b = 0; b < d; b++) {
          xx[a][b] = _plClip(xx[a][b], -borne[b], borne[b]);
        }
      }
      final (vIt, _, _, _) = evaluer(
        xx,
        tirage,
        semaine,
        blocsIdx,
        qualites,
        echelle: echelle,
      );
      evalues += pop;
      // Tri par clé (−valeur, indice).
      final ordre = [for (var a = 0; a < pop; a++) a]
        ..sort((a, b) => _plComparerCem(vIt, a, b));
      final elite = <List<double>>[for (final a in ordre.take(eliteN)) xx[a]];
      final vm = meilleureV;
      if (vm == null || vIt[ordre[0]] > vm) {
        meilleureV = vIt[ordre[0]];
        meilleurX = List<double>.of(xx[ordre[0]]);
      }
      candidatsFinaux = <List<double>>[
        for (final a in ordre.take(4)) List<double>.of(xx[a]),
        ...candidatsFinaux.take(4),
      ];
      final em = _plMoyenneAxe0(elite, d);
      moy = <double>[
        for (var b = 0; b < d; b++) lis * em[b] + (1 - lis) * moy[b],
      ];
      final es = _plEcartTypeAxe0(elite, d);
      ecart = <double>[
        for (var b = 0; b < d; b++) lis * es[b] + (1 - lis) * ecart[b],
      ];
      ecart = <double>[for (var b = 0; b < d; b++) _plMaximum(ecart[b], 1e-4)];
    }
    // Le plan retenu doit battre la référence de plus que le bruit de
    // recherche, et passer le validateur de sécurité.
    final ref = [List<double>.filled(d, 0.0)];
    final (vRef, pRef, _, _) = evaluer(
      ref,
      tirage,
      semaine,
      blocsIdx,
      qualites,
      echelle: echelle,
    );
    final gainMin = dbl(pl['gain_min']);
    List<double>? choisi;
    var vChoisi = vRef[0];
    final essais = <List<double>>[meilleurX, ...candidatsFinaux];
    for (final x in essais) {
      final (vx, _, _, _) = evaluer(
        [x],
        tirage,
        semaine,
        blocsIdx,
        qualites,
        echelle: echelle,
      );
      if (vx[0] <= vRef[0] + gainMin) {
        continue;
      }
      var ok = false;
      var xs = List<double>.of(x);
      for (var r = 0; r < 3; r++) {
        if (_sur(xs, semaine, blocsIdx, qualites)) {
          ok = true;
          break;
        }
        xs = <double>[for (final y in xs) 0.5 * y]; // ramené vers la référence
      }
      if (ok) {
        final (vxx, _, _, _) = evaluer(
          [xs],
          tirage,
          semaine,
          blocsIdx,
          qualites,
          echelle: echelle,
        );
        if (vxx[0] > vChoisi + gainMin) {
          choisi = xs;
          vChoisi = vxx[0];
          break;
        }
      }
    }
    var garde = false;
    if (choisi == null) {
      // Aucun plan meilleur et sûr. Revenir d'un coup à la référence
      // ferait un saut de charge ou de volume après des semaines
      // modulées (jusqu'à +10 % d'une semaine à l'autre) : le plan en
      // cours, validé lundi dernier avec le même passé, est gardé ;
      // à défaut la référence si le validateur l'accepte ; à défaut la
      // dernière modulation servie est prolongée (aucun saut).
      final aVenir = <int>[
        for (var w = semaine; w < horizon; w++)
          if (_table(w) != null) w,
      ];
      if (aVenir.every(plan.containsKey)) {
        garde = true;
      } else if (_sur(List<double>.filled(d, 0.0), semaine, blocsIdx, qualites)) {
        choisi = List<double>.filled(d, 0.0);
      } else {
        garde = true;
        final passees = <int>[
          for (final w in (plan.keys.toList()..sort()))
            if (w < semaine) w,
        ];
        final derniere = passees.isNotEmpty ? plan[passees.last] : null;
        for (final w in aVenir) {
          if (plan.containsKey(w) || derniere == null) {
            continue;
          }
          final t = _table(w)!;
          var a = <double>[for (final x in jl(derniere['volume'])) dbl(x)];
          var i = dbl(derniere['intensite']);
          if (t.verrou) {
            a = <double>[for (final x in a) _plMinPy(x, 1.0)];
            i = _plMinPy(i, 0.0);
          }
          plan[w] = <String, Object?>{'volume': a, 'intensite': i};
        }
      }
    }
    final List<double> choisiF;
    final Map<int, List<double>> vol;
    final Map<int, double> inten;
    if (choisi != null) {
      choisiF = choisi;
      final dec = decoder(choisiF, blocsIdx, qualites);
      vol = dec.$1;
      inten = dec.$2;
      for (var w = semaine; w < horizon; w++) {
        final t = _table(w);
        if (t == null) {
          continue;
        }
        var a = List<double>.of(vol[t.bloc]!);
        var i = inten[t.bloc]!;
        if (t.verrou) {
          a = <double>[for (final x in a) _plMinimum(x, 1.0)];
          i = _plMinPy(i, 0.0);
        }
        plan[w] = <String, Object?>{
          'volume': <double>[for (final x in a) x],
          'intensite': i,
        };
      }
    } else {
      choisiF = List<double>.filled(d, 0.0);
      final dec = decoder(choisiF, blocsIdx, qualites);
      vol = dec.$1;
      inten = dec.$2;
    }
    ligne['plan_garde'] = garde;
    final (v, pc, dist, det) = evaluer(
      [choisiF],
      tirage,
      semaine,
      blocsIdx,
      qualites,
      detail: true,
      echelle: echelle,
    );
    final prevu = _prevuJour;
    ligne.addAll(<String, Object?>{
      'plans': evalues + 2 + essais.length,
      'valeur': v[0],
      'valeur_reference': vRef[0],
      'objectif': (det!['J'] as List<double>)[0],
      'transport': dist[0],
      'p_cibles': <String, Object?>{
        for (var e = 0; e < suivis.length; e++)
          if (cibles.containsKey(suivis[e])) suivis[e]: pc[0][e],
      },
      'p_cibles_reference': <String, Object?>{
        for (var e = 0; e < suivis.length; e++)
          if (cibles.containsKey(suivis[e])) suivis[e]: pRef[0][e],
      },
      'prevu_jour': prevu != null
          ? <String, Object?>{
              for (var e = 0; e < suivis.length; e++)
                if (cibles.containsKey(suivis[e]))
                  suivis[e]: <double>[prevu.$1[e], prevu.$2[e]],
            }
          : <String, Object?>{},
      'volume': <String, Object?>{
        for (final b in blocsIdx)
          '$b': <double>[for (final x in vol[b]!) arrondi(x, 4)],
      },
      'intensite': <String, Object?>{
        for (final b in blocsIdx) '$b': arrondi(inten[b]!, 4),
      },
      'qualites': List<int>.of(qualites),
    });
    historique.add(ligne);
    return ligne;
  }

  // ------------------------------------------------------------------
  // Application au plan écrit et sécurité
  // ------------------------------------------------------------------
  Json? modulation(int semaine) => plan[semaine];

  double facteurExercice(String exId, Json? mod) {
    final fiche = fiches[exId];
    if (fiche == null || mod == null) {
      return 1.0;
    }
    final vec = jl(fiche['vecteur']);
    final volM = jl(mod['volume']);
    var f = 0.0;
    for (var q = 0; q < nq; q++) {
      f += dbl(vec[q]) * dbl(volM[q]);
    }
    return f;
  }

  /// Items de la semaine [semaine] après modulation : dictionnaire
  /// (jour, slotId) → (séries, écart d'intensité). L'arrondi des séries
  /// est une diffusion d'erreur par exercice dans l'ordre des jours
  /// (fonction pure de la modulation), puis le plafond de volume par
  /// qualité est vérifié sur les séries entières.
  Map<(int, String), (int, double)> itemsModules(int semaine) {
    final s = (0 <= semaine && semaine < semaines.length)
        ? semaines[semaine]
        : null;
    final mod = plan[semaine];
    final out = <(int, String), (int, double)>{};
    if (s == null) {
      return out;
    }
    final reste = <String, double>{};
    for (final (jour, items) in s.jours) {
      for (final item in items) {
        final n = _plSeries(item);
        if (mod == null ||
            item['kind'] == 'warmup' ||
            item['kind'] == 'test' ||
            n <= 0) {
          out[(jour, item['slotId'] as String)] = (n, 0.0);
          continue;
        }
        final ex = item['exerciseId'] as String;
        final voulu = n * facteurExercice(ex, mod) + (reste[ex] ?? 0.0);
        var servi = (voulu + 0.5).floor();
        if (servi < 1) {
          servi = 1;
        }
        reste[ex] = voulu - servi;
        out[(jour, item['slotId'] as String)] = (
          servi,
          dbl(mod['intensite']),
        );
      }
    }
    if (mod == null) {
      return out;
    }
    // Plafond dur par qualité sur les séries entières : on retire, dans
    // l'ordre inverse, les séries ajoutées qui font dépasser +15 %.
    final pv = dbl(p['plafond_volume']);
    final ref = List<double>.filled(nq, 0.0);
    final modM = List<double>.filled(nq, 0.0);
    final ajouts = <(int, String, List<double>)>[];
    final retraits = <(int, String, List<double>)>[];
    for (final (jour, items) in s.jours) {
      for (final item in items) {
        final fiche = fiches[item['exerciseId']];
        final n = _plSeries(item);
        if (fiche == null ||
            item['kind'] == 'warmup' ||
            item['kind'] == 'test' ||
            n <= 0) {
          continue;
        }
        final v = jld(fiche['vecteur']);
        final slot = item['slotId'] as String;
        final servi = out[(jour, slot)]!.$1;
        for (var q = 0; q < nq; q++) {
          ref[q] += n * v[q];
          modM[q] += servi * v[q];
        }
        if (servi > n) {
          ajouts.add((jour, slot, v));
        }
        if (servi < n) {
          retraits.add((jour, slot, v));
        }
      }
    }
    for (final (jour, slot, v) in ajouts.reversed) {
      var depasse = false;
      for (var q = 0; q < nq; q++) {
        if (modM[q] > ref[q] * (1 + pv) + 1e-9) {
          depasse = true;
        }
      }
      if (!depasse) {
        break;
      }
      final (nS, ec) = out[(jour, slot)]!;
      out[(jour, slot)] = (nS - 1, ec);
      for (var q = 0; q < nq; q++) {
        modM[q] -= v[q];
      }
    }
    for (final (jour, slot, v) in retraits.reversed) {
      var manque = false;
      for (var q = 0; q < nq; q++) {
        if ((modM[q] < ref[q] * (1 - pv) - 1e-9) && (ref[q] > 0)) {
          manque = true;
        }
      }
      if (!manque) {
        break;
      }
      final (nS, ec) = out[(jour, slot)]!;
      out[(jour, slot)] = (nS + 1, ec);
      for (var q = 0; q < nq; q++) {
        modM[q] += v[q];
      }
    }
    return out;
  }

  /// Items du jour modulés (copie) : `sets` changé, `koachIntensite`
  /// posé (lu par la prescription de séance).
  List<Json> appliquer(int semaine, int jour, List<Json> items) {
    final mods = itemsModules(semaine);
    final out = <Json>[];
    for (final item in items) {
      final cle = (jour, item['slotId'] as String);
      final mod = mods[cle];
      if (mod == null) {
        out.add(item);
        continue;
      }
      final (n, ecart) = mod;
      if (n == _plSeries(item) && ecart == 0.0) {
        out.add(item);
        continue;
      }
      final it = Map<String, Object?>.of(item);
      it['sets'] = n;
      if (ecart != 0.0) {
        it['koachIntensite'] = ecart;
      }
      it['koachVolume'] = n - _plSeries(item);
      out.add(it);
    }
    return out;
  }

  /// Copie des blocs de référence avec le plan appliqué (séries, part du
  /// 1RM et charge de départ) : ce que lit le validateur de sécurité.
  List<Json> blocsModules([Map<int, Json>? planX]) {
    final garde = plan;
    if (planX != null) {
      plan = planX;
    }
    try {
      final out = <Json>[for (final b in blocs!) copieJson(b)];
      for (var w = 0; w < semaines.length; w++) {
        final s = semaines[w];
        if (s == null || !plan.containsKey(w)) {
          continue;
        }
        final mods = itemsModules(w);
        for (final ecrite0 in jl(jm(out[s.bloc]['pass2'])['weeks'])) {
          final ecrite = jm(ecrite0);
          if (ecrite['weekIndex'] != s.semaineBloc) {
            continue;
          }
          for (final d0 in jl(ecrite['days'])) {
            final d = jm(d0);
            for (final it0 in jl(d['items'])) {
              final item = jm(it0);
              // Clé (dayIndex, slotId) absente de `mods` (Python : `cle not
              // in mods`) si l'un des deux manque ou n'a pas le type d'une
              // clé de `items_modules`.
              final di = d['dayIndex'];
              final slot = item['slotId'];
              if (di is! num || slot is! String || di != di.truncate()) {
                continue;
              }
              final cle = (di.truncate(), slot);
              final mod = mods[cle];
              if (mod == null) {
                continue;
              }
              final (n, ecart) = mod;
              item['sets'] = n;
              if (vrai(item['setTargets'])) {
                item['setTargets'] = null;
              }
              if (ecart != 0.0) {
                final fiche = fiches[item['exerciseId']] ?? <String, Object?>{};
                final bw = dbl(fiche['fraction'] ?? 0.0) * poidsCorps;
                if (item['percentOfOneRm'] != null) {
                  item['percentOfOneRm'] = arrondi(
                    dbl(item['percentOfOneRm']) * (1 + ecart),
                    4,
                  );
                }
                final inten = item['intensity'];
                if (vrai(inten) &&
                    jm(inten)['basis'] == 'percent_one_rm' &&
                    jm(inten)['value'] != null) {
                  jm(inten)['value'] = arrondi(
                    dbl(jm(inten)['value']) * (1 + ecart),
                    4,
                  );
                }
                if (item['startLoadKg'] != null) {
                  item['startLoadKg'] = arrondi(
                    (dbl(item['startLoadKg']) + bw) * (1 + ecart) - bw,
                    3,
                  );
                }
              }
            }
          }
        }
      }
      return out;
    } finally {
      plan = garde;
    }
  }

  List<List<Object?>> _clesConstats(List<Json> constats) {
    return <List<Object?>>[
      for (final c in constats)
        <Object?>[c['code'], c['week'], c['dayIndex'], c['exerciseId']],
    ]..sort(_plComparerCles);
  }

  /// Vrai si le plan [x] n'ajoute aucun constat de sécurité à ceux du
  /// plan de référence (validateur injecté ; sans validateur : vrai).
  bool _sur(
    List<double> x,
    int semaine,
    List<int> blocsIdx,
    List<int> qualites,
  ) {
    final val = validateur;
    if (val == null) {
      return true;
    }
    constatsReference ??= _clesConstats(val(blocs!));
    final (vol, inten) = decoder(x, blocsIdx, qualites);
    final planX = <int, Json>{
      for (final e in plan.entries)
        if (e.key < semaine) e.key: e.value,
    };
    for (var w = semaine; w < horizon; w++) {
      final t = _table(w);
      if (t == null) {
        continue;
      }
      var a = List<double>.of(vol[t.bloc]!);
      var i = inten[t.bloc]!;
      if (t.verrou) {
        a = <double>[for (final y in a) _plMinimum(y, 1.0)];
        i = _plMinPy(i, 0.0);
      }
      planX[w] = <String, Object?>{
        'volume': <double>[for (final y in a) y],
        'intensite': i,
      };
    }
    final trouves = _clesConstats(val(blocsModules(planX)));
    final ref = List<List<Object?>>.of(constatsReference!);
    for (final c in trouves) {
      final k = ref.indexWhere((r) => _plEgalCle(r, c));
      if (k >= 0) {
        ref.removeAt(k);
      } else {
        return false;
      }
    }
    return true;
  }

  // ------------------------------------------------------------------
  // Crochets du moteur
  // ------------------------------------------------------------------
  /// Lundi : replanification de la semaine suivante à l'échéance.
  @override
  void finSemaine(Koach koach, Json ligne, Json e) {
    replanifier(koach, ent(e['semaine'] ?? 0) + 1);
  }

  @override
  Object? planSemaine(Koach koach, Json c) {
    final w = c['semaine'];
    if (vrai(c['replanifier'])) {
      replanifier(koach, ent(w));
    }
    return <String, Object?>{
      'semaine': w,
      'modulation': plan[w],
      'items': itemsModules(ent(w)),
    };
  }

  Json etat() {
    final ws = plan.keys.toList()..sort();
    return <String, Object?>{
      'plan': <String, Object?>{for (final w in ws) '$w': plan[w]},
      'historique': historique,
    };
  }
}

// ----------------------------------------------------------------------
// Outils du module
// ----------------------------------------------------------------------

/// `item.get('sets') or 0`.
int _plSeries(Json item) => vrai(item['sets']) ? ent(item['sets']) : 0;

/// `min(a, b)` de Python : b si b < a, sinon a.
double _plMinPy(double a, double b) => b < a ? b : a;

/// `np.minimum` (NaN propagé).
double _plMinimum(double a, double b) => (a <= b || a.isNaN) ? a : b;

/// `np.maximum` (NaN propagé).
double _plMaximum(double a, double b) => (a >= b || a.isNaN) ? a : b;

/// `np.clip(x, lo, hi)` = `minimum(maximum(x, lo), hi)`.
double _plClip(double x, double lo, double hi) =>
    _plMinimum(_plMaximum(x, lo), hi);

/// `np.exp` sur un tableau. numpy 2.5 (x86-64 avec AVX512F) passe par son
/// noyau vectoriel `AVX512F_exp_DOUBLE` (Tang, table de 32, FMA), qui
/// diffère de la libm d'un ulp sur environ 5 % des arguments ; sans
/// AVX512F, numpy appelle `exp` de la libm. Ici : libm (`math.exp`).
double _plNpExp(double x) => math.exp(x);

/// `np.log` sur un tableau (noyau AVX512F de numpy : rares écarts d'un ulp
/// à la libm). Ici : libm (`math.log`).
double _plNpLog(double x) => math.log(x);

/// Produit scalaire des produits matriciels BLAS de la référence
/// (`h @ m`, `z @ L.T`, `a @ V.T`, `charge_jour @ decro`,
/// `charge_jour @ avant`, `a @ tq`). numpy : ddot / dgemv / dgemm
/// d'OpenBLAS (accumulateurs vectoriels, FMA, ordre propre au noyau
/// choisi à l'exécution) : non reproductible exactement en Dart sans FMA.
/// Ici : somme séquentielle Σ x[i]·y[i] dans l'ordre des indices, départ 0
/// (sur [x].length termes).
double _plDot(List<double> x, List<double> y) {
  var s = 0.0;
  for (var i = 0; i < x.length; i++) {
    s += x[i] * y[i];
  }
  return s;
}

/// `H @ P[:n, :n] @ H.T` (deux dgemm, évalués de gauche à droite). Ici :
/// HP[a][j] = Σ_i H[a][i]·P[i][j] (i croissant), puis
/// S[a][b] = Σ_j HP[a][j]·H[b][j] (j croissant).
List<List<double>> _plHPHt(List<List<double>> h, Modele m) {
  final n = m.n;
  final k = h.length;
  final hp = <List<double>>[
    for (var a = 0; a < k; a++) List<double>.filled(n, 0.0),
  ];
  for (var a = 0; a < k; a++) {
    for (var j = 0; j < n; j++) {
      var s = 0.0;
      for (var i = 0; i < n; i++) {
        s += h[a][i] * m.pget(i, j);
      }
      hp[a][j] = s;
    }
  }
  return <List<double>>[
    for (var a = 0; a < k; a++)
      [for (var b = 0; b < k; b++) _plDot(hp[a], h[b])],
  ];
}

/// `np.einsum('cdq,cq->cd', syst, a)` pour un couple (c, d) : réduction
/// sur q. numpy (sans `optimize`) appelle le noyau
/// `double_sum_of_products_contig_contig_outstride0_two` compilé pour le
/// SIMD de base x86-64 (2 voies de doubles, `muladd` = produit arrondi puis
/// somme, sans FMA) : par blocs de 8, voie L : acc_L = a0·b0 + (a2·b2 +
/// (a4·b4 + (a6·b6 + acc_L))) (indices L, L+2, L+4, L+6 du bloc) ; reste
/// par paires (voie manquante à 0) ; puis acc_0 + acc_1, ajouté à la
/// sortie initialisée à 0. Vérifié bit pour bit contre numpy 2.5.3
/// (q = 10, a vue non contiguë ou copie).
double _plEinsumQ(List<double> x, List<double> y) {
  final n = x.length;
  var v0 = 0.0;
  var v1 = 0.0;
  var i = 0;
  while (n - i >= 8) {
    v0 =
        x[i] * y[i] +
        (x[i + 2] * y[i + 2] +
            (x[i + 4] * y[i + 4] + (x[i + 6] * y[i + 6] + v0)));
    v1 =
        x[i + 1] * y[i + 1] +
        (x[i + 3] * y[i + 3] +
            (x[i + 5] * y[i + 5] + (x[i + 7] * y[i + 7] + v1)));
    i += 8;
  }
  while (i < n) {
    v0 = x[i] * y[i] + v0;
    v1 = (i + 1 < n ? x[i + 1] * y[i + 1] : 0.0) + v1;
    i += 2;
  }
  final accum = v0 + v1;
  return 0.0 + accum;
}

/// `np.add.reduce` (`.sum()`, et la somme de `.mean()` / `np.std`) sur un
/// axe contigu de n éléments : sortie initialisée à l'identité 0 (numpy
/// 2.x), plus `pairwise_sum` (vérifié bit pour bit contre numpy 2.5.3).
double _plSommePaires(List<double> a) => 0.0 + _plPaires(a, 0, a.length);

/// `pairwise_sum` de numpy (`loops_utils.h`) : n < 8 → séquentiel depuis
/// −0,0 ; n ≤ 128 (PW_BLOCKSIZE) → 8 accumulateurs déroulés, combinés en
/// ((r0+r1)+(r2+r3))+((r4+r5)+(r6+r7)), puis le reste séquentiel ; au-delà,
/// deux moitiés n2 = n/2 − (n/2 mod 8), récursivement.
double _plPaires(List<double> a, int i0, int n) {
  if (n < 8) {
    var res = -0.0;
    for (var i = 0; i < n; i++) {
      res += a[i0 + i];
    }
    return res;
  }
  if (n <= 128) {
    var r0 = a[i0];
    var r1 = a[i0 + 1];
    var r2 = a[i0 + 2];
    var r3 = a[i0 + 3];
    var r4 = a[i0 + 4];
    var r5 = a[i0 + 5];
    var r6 = a[i0 + 6];
    var r7 = a[i0 + 7];
    var i = 8;
    for (; i < n - (n % 8); i += 8) {
      r0 += a[i0 + i];
      r1 += a[i0 + i + 1];
      r2 += a[i0 + i + 2];
      r3 += a[i0 + i + 3];
      r4 += a[i0 + i + 4];
      r5 += a[i0 + i + 5];
      r6 += a[i0 + i + 6];
      r7 += a[i0 + i + 7];
    }
    var res = ((r0 + r1) + (r2 + r3)) + ((r4 + r5) + (r6 + r7));
    for (; i < n; i++) {
      res += a[i0 + i];
    }
    return res;
  }
  var n2 = n ~/ 2;
  n2 -= n2 % 8;
  return _plPaires(a, i0, n2) + _plPaires(a, i0 + n2, n - n2);
}

/// Somme d'une colonne pour une réduction sur l'axe 0 d'un tableau 2D
/// C-contigu (R × d). numpy : la boucle interne parcourt l'axe 1 (non
/// réduit) et accumule séquentiellement ligne après ligne depuis 0 ; avec
/// d = 1, l'axe réduit devient la boucle interne → sommation par paires
/// (vérifié contre numpy 2.5.3).
double _plSommeAxe0(List<double> colonne, int d) {
  if (d == 1) {
    return _plSommePaires(colonne);
  }
  var s = 0.0;
  for (final x in colonne) {
    s += x;
  }
  return s;
}

/// `elite.mean(axis=0)` : somme sur l'axe 0 (voir `_plSommeAxe0`) / R.
List<double> _plMoyenneAxe0(List<List<double>> lignes, int d) {
  final r = lignes.length;
  return <double>[
    for (var b = 0; b < d; b++)
      _plSommeAxe0([for (final l in lignes) l[b]], d) / r,
  ];
}

/// `elite.std(axis=0)` (ddof 0) : numpy `_var` → moyenne (somme / R),
/// écarts x − moyenne, carrés x·x, somme sur l'axe 0, / R, racine.
List<double> _plEcartTypeAxe0(List<List<double>> lignes, int d) {
  final r = lignes.length;
  final moy = _plMoyenneAxe0(lignes, d);
  return <double>[
    for (var b = 0; b < d; b++)
      math.sqrt(
        _plSommeAxe0([
          for (final l in lignes) (l[b] - moy[b]) * (l[b] - moy[b]),
        ], d) /
            r,
      ),
  ];
}

/// Progression moyenne d'un candidat c : `(mu_fin - mu.T).mean(axis=(1,
/// 2))[c]`. numpy : la disposition mémoire de `mu_fin` (C, E, N) suit les
/// opérandes (ordre K) : C-contiguë sauf quand E = 1 et C > 1, où l'axe C
/// devient le plus rapide. Contigu → sommation par paires sur les E·N
/// éléments (ordre e puis n) ; E = 1 et C > 1 → accumulation séquentielle
/// sur n depuis 0 (vérifié contre numpy 2.5.3 pour N ≤ 1300, E ≤ 10,
/// C ≤ 80). Divisé par E·N.
double _plProgression(
  List<List<double>> muFinC,
  List<List<double>> mu,
  int ne,
  int nn,
  int cc,
) {
  final s = <double>[
    for (var e = 0; e < ne; e++)
      for (var n = 0; n < nn; n++) muFinC[e][n] - mu[n][e],
  ];
  double tot;
  if (ne == 1 && cc > 1) {
    tot = 0.0;
    for (final x in s) {
      tot += x;
    }
  } else {
    tot = _plSommePaires(s);
  }
  return tot / (ne * nn);
}

/// Nombre de vrais (moyenne de booléens de numpy : somme exacte).
int _plCompte(List<bool> xs) {
  var k = 0;
  for (final x in xs) {
    if (x) {
      k++;
    }
  }
  return k;
}

/// Tri CEM par clé (−valeur, indice) (comparaison de tuples Python).
int _plComparerCem(List<double> v, int a, int b) {
  final x = -v[a];
  final y = -v[b];
  if (x == y) {
    return a.compareTo(b);
  }
  return x < y ? -1 : 1;
}

/// Comparaison Python de deux éléments de tuple différents (`<`).
int _plComparerPy(Object? x, Object? y) {
  if (x is num && y is num) {
    return x < y ? -1 : (y < x ? 1 : 0);
  }
  if (x is String && y is String) {
    return x.compareTo(y);
  }
  if (x is bool && y is bool) {
    return (x ? 1 : 0) - (y ? 1 : 0);
  }
  // Python : TypeError ('<' entre types incomparables, dont None).
  throw ArgumentError('constats : comparaison impossible entre $x et $y');
}

/// Tri des clés de constats (tuples `(code, week, dayIndex, exerciseId)`).
int _plComparerCles(List<Object?> a, List<Object?> b) {
  for (var k = 0; k < a.length && k < b.length; k++) {
    if (egalJson(a[k], b[k])) {
      continue;
    }
    return _plComparerPy(a[k], b[k]);
  }
  return a.length.compareTo(b.length);
}

/// Égalité de deux clés de constats (`==` de tuples Python).
bool _plEgalCle(List<Object?> a, List<Object?> b) => egalJson(a, b);

/// Lecture d'une matrice du tirage (typée ou JSON).
List<List<double>> _plMat(Object? v) {
  if (v is List<List<double>>) {
    return v;
  }
  return <List<double>>[for (final r in jl(v)) jld(r)];
}

/// Lecture d'un vecteur du tirage (typé ou JSON).
List<double> _plVec(Object? v) => v is List<double> ? v : jld(v);

/// Lecture d'un vecteur d'entiers du tirage (typé ou JSON).
List<int> _plEnts(Object? v) =>
    v is List<int> ? v : <int>[for (final x in jl(v)) ent(x)];

/// Hypothèse de dose `(s0, k)` (liste `[s0, k]` ou record).
(double, int) _plHyp(Object? h) {
  if (h is (double, int)) {
    return h;
  }
  final l = jl(h);
  return (dbl(l[0]), ent(l[1]));
}
