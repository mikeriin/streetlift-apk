part of 'koach.dart';

// Prescription de la séance et conseil série par série de Koach 1.0
// (référence `koach/seance.py`, contrat § 3 `plan`, § 8 garde-fous) : charge
// et volume ajustés à chaque séance depuis l'a posteriori, test adaptatif,
// tentatives choisies par probabilité de réussite, le tout sous les
// contraintes dures de sécurité.

// ----------------------------------------------------------------------
// Sémantique Python
// ----------------------------------------------------------------------

/// `d.get(k, defaut)` de Python (défaut seulement si la clé manque).
Object? _seGet(Json d, String k, Object? defaut) =>
    d.containsKey(k) ? d[k] : defaut;

/// `min(a, b)` de Python : le premier, sauf si le second est plus petit.
T _seMin<T extends num>(T a, T b) => b < a ? b : a;

/// `max(a, b)` de Python : le premier, sauf si le second est plus grand.
T _seMax<T extends num>(T a, T b) => b > a ? b : a;

/// `x or defaut` de Python sur un nombre JSON facultatif.
double _seOu(Object? v, double defaut) => vrai(v) ? dbl(v) : defaut;

/// `max(liste or [0.0])` de Python sur des flottants.
double _seMaxListe(List<double> l) {
  final x = l.isNotEmpty ? l : <double>[0.0];
  var r = x[0];
  for (var i = 1; i < x.length; i++) {
    if (x[i] > r) {
      r = x[i];
    }
  }
  return r;
}

/// `a // b` de Python sur des flottants (algorithme de CPython :
/// `float_floor_div`).
double _seDivPlancherD(double vx, double wx) {
  var mod = vx.remainder(wx);
  var div = (vx - mod) / wx;
  if (mod != 0.0) {
    if ((wx < 0) != (mod < 0)) {
      mod += wx;
      div -= 1.0;
    }
  }
  double floordiv;
  if (div != 0.0) {
    floordiv = div.floorToDouble();
    if (div - floordiv > 0.5) {
      floordiv += 1.0;
    }
  } else {
    floordiv = (vx / wx).isNegative ? -0.0 : 0.0;
  }
  return floordiv;
}

/// `a // b` de Python sur des nombres JSON (entier si les deux le sont).
num _seDivEnt(num a, num b) {
  if (a is int && b is int) {
    return divEnt(a, b);
  }
  return _seDivPlancherD(a.toDouble(), b.toDouble());
}

/// `liste.index(x)` de Python : premier élément identique ou égal.
int _seIndex(List<Json> l, Json x) {
  for (var i = 0; i < l.length; i++) {
    if (identical(l[i], x) || egalJson(l[i], x)) {
      return i;
    }
  }
  throw ArgumentError('élément absent de la liste');
}

/// `liste.remove(x)` de Python : retire le premier élément identique ou
/// égal.
void _seRetirer(List<Json> l, Json x) {
  l.removeAt(_seIndex(l, x));
}

/// `id(x) in ids` de Python.
bool _seContientId(List<Json> ids, Json x) {
  for (final y in ids) {
    if (identical(y, x)) {
      return true;
    }
  }
  return false;
}

// ----------------------------------------------------------------------
// Fonctions de module
// ----------------------------------------------------------------------

double? rirDeFlammes(Object? f) {
  if (f == null) {
    return null;
  }
  final x = f as num;
  return x >= 10 ? 0.0 : (11 - x) / 2.0;
}

int flammesDeRir(double rir) {
  if (rir >= 5) {
    return 1;
  }
  final h = (rir * 2 - 0.5).ceil();
  if (h <= 0) {
    return 10;
  }
  if (h == 1) {
    return 9;
  }
  return 11 - h;
}

/// Arrondi au plus proche, moitié vers le haut (`seance.arrondi`).
int _seArrondi(double x) => (x + 0.5).floor();

/// L'item sans sa technique, en séries classiques au même travail approché
/// (`standardEquivalent`). Modifie [item] en place.
Json equivalentStandard(Json item) {
  final t = dictOuVide(item['technique']);
  final kind = t['kind'];
  var sets = item['sets'];
  var low = item['repsLow'];
  var high = item['repsHigh'];

  num mediane(Object? reps) {
    final r = [for (final x in jl(reps)) x as num]..sort();
    return r[divEnt(r.length, 2)];
  }

  if (kind == 'wave' && vrai(t['waveReps'])) {
    low = high = mediane(t['waveReps']);
  } else if (kind == 'pyramid' && vrai(t['pyramidReps'])) {
    low = high = mediane(t['pyramidReps']);
  } else if (kind == 'ladder') {
    if (t['ladderStart'] != null && t['ladderTop'] != null) {
      low = high = _seDivEnt(
        (t['ladderStart'] as num) + (t['ladderTop'] as num),
        2,
      );
    }
  } else if ((kind == 'density' || kind == 'for_time') &&
      low != null &&
      high != null) {
    final total = ou(t['totalRepsTarget'], high) as num;
    final each = _seDivEnt(total, 4) >= 1 ? _seDivEnt(total, 4) : 1;
    sets = total < 4 ? 1 : 3;
    low = high = each;
  } else if (kind == 'cluster') {
    final mini = t['miniSets'];
    final each = t['miniSetReps'];
    if (mini != null && each != null && low != null && high != null) {
      final whole = _seDivEnt(2 * (mini as num) * (each as num) + 2, 3);
      low = high = whole >= 1 ? whole : 1;
    }
  }
  final regles = <Object?>[
    for (final r in listeOuVide(item['autoregulation']))
      if (!const [
        'backoff_from_top_set',
        'stop_on_rep_drop',
      ].contains(jm(r)['kind']))
        r,
  ];
  item['sets'] = sets;
  item['repsLow'] = low;
  item['repsHigh'] = high;
  item['technique'] = null;
  item['setTargets'] = null;
  item['autoregulation'] = regles.isNotEmpty ? regles : null;
  return item;
}

/// Durée prescrite d'une ligne d'endurance, toutes séries (secondes) ; 0
/// sans durée ni distance (`prescribedSeconds`).
double secondesPrescrites(Json item, Object? sets, double vitesse) {
  var sv = item['secondsHigh'];
  sv ??= item['secondsLow'];
  if (sv != null) {
    return ((sv as num) * (sets as num)).toDouble();
  }
  final mv = item['distanceMeters'];
  if (mv != null && vitesse > 0) {
    return (mv as num) * (sets as num) / vitesse;
  }
  return 0.0;
}

/// Ligne ramenée à la part [part] de l'écrit (`scaled`) : jamais au-dessus
/// de l'écrit, arrondi vers le bas. Modifie [item] en place ; vrai si
/// quelque chose a changé.
bool reduire(Json item, double part) {
  if (part >= 1) {
    return false;
  }
  final sets = _seGet(item, 'sets', 0) as num;
  if (sets > 1 && item['repsHigh'] == null && item['repsLow'] == null) {
    var n = (sets * part).floor();
    if (n < 1) {
      n = 1;
    }
    if (n == sets) {
      return false;
    }
    item['sets'] = n;
    return true;
  }

  num? bas(Object? v0, int unite, int plancherV) {
    if (v0 == null) {
      return null;
    }
    final v = v0 as num;
    num x = (v * part / unite).floor() * unite;
    if (x < plancherV) {
      x = plancherV < v ? plancherV : v;
    }
    return x;
  }

  num? basReel(Object? v0, int unite) {
    if (v0 == null) {
      return null;
    }
    final v = v0 as num;
    final x = (v * part / unite).floor() * unite;
    return x < unite ? (v < unite ? v : unite) : x;
  }

  final hi = item['secondsHigh'];
  final lo = item['secondsLow'];
  final rh = item['repsHigh'];
  final rl = item['repsLow'];
  final mv = item['distanceMeters'];
  final cal = item['calories'];
  final nHi = bas(hi, hi != null && (hi as num) >= 300 ? 60 : 5, 5);
  var nLo = bas(lo, lo != null && (lo as num) >= 300 ? 60 : 5, 5);
  if (nLo != null && nHi != null && nLo > nHi) {
    nLo = nHi;
  }
  final nRh = bas(rh, 1, 1);
  var nRl = bas(rl, 1, 1);
  if (nRl != null && nRh != null && nRl > nRh) {
    nRl = nRh;
  }
  final nM = basReel(mv, 100);
  final nCal = basReel(cal, 1);
  if (egalJson(nHi, hi) &&
      egalJson(nLo, lo) &&
      egalJson(nRh, rh) &&
      egalJson(nRl, rl) &&
      egalJson(nM, mv) &&
      egalJson(nCal, cal)) {
    return false;
  }
  item['secondsHigh'] = nHi;
  item['secondsLow'] = nLo;
  item['repsHigh'] = nRh;
  item['repsLow'] = nRl;
  item['distanceMeters'] = nM;
  item['calories'] = nCal;
  item['setTargets'] = null;
  return true;
}

// ----------------------------------------------------------------------
// Grille de charges
// ----------------------------------------------------------------------

/// Grille de charges d'un exercice (pas, minimum, règle des haltères).
class Grille {
  Grille(this.pas, this.minimum, [this.halteres = false]);

  static const double epsilon = 1e-9;

  final double pas;
  final double minimum;
  final bool halteres;

  double _pas(double charge) {
    if (halteres) {
      return charge < 10 - epsilon ? pas : 2.0;
    }
    return pas;
  }

  double plancher(double charge) {
    double v;
    if (halteres && charge > 10 + epsilon) {
      v = 10 + ((charge - 10) / 2.0 + epsilon).floorToDouble() * 2.0;
    } else if (charge <= minimum) {
      v = minimum;
    } else {
      v = minimum + ((charge - minimum) / pas + epsilon).floorToDouble() * pas;
    }
    return v < minimum ? minimum : v;
  }

  double suivant(double charge) {
    final b = plancher(charge);
    if (b > charge + epsilon) {
      return b;
    }
    return b + _pas(b);
  }

  double precedent(double charge) {
    final b = plancher(charge);
    if (b < charge - epsilon) {
      return b;
    }
    double d;
    if (halteres) {
      d = b <= 10 + epsilon ? pas : 2.0;
    } else {
      d = pas;
    }
    final v = b - d;
    return v < minimum ? minimum : v;
  }

  double proche(double charge) {
    final lo = plancher(charge);
    final hi = suivant(lo);
    return (charge - lo) <= (hi - charge) ? lo : hi;
  }
}

// ----------------------------------------------------------------------
// Mémoire d'un exercice
// ----------------------------------------------------------------------

/// Ce que la prescription retient d'un exercice (recalculé du journal).
class Memoire {
  int? jour;
  num? chargeMax;
  num? repsMax;
  num? secMax;
  num? secTotal;
  bool echec = false;

  /// (slotId, haut de plage) -> (charge de la première série, raté ou
  /// haut de plage manqué).
  final Map<(String?, double?), (num, bool)> schemas = {};
  final List<int> jours = [];
  int? cranJour;
  int hautDePlage = 0;
  int facile = 0;
  int basManque = 0;
  (num, int)? meilleurSec;
  num? chargeSeance;
  num? repsSeance;
  num? secSeance;
  int echecSeance = 0;
  double totalSeance = 0.0;
  int facilesSeance = 0;

  /// (jour, charge, répétitions) des séries réussies.
  final List<(int, num, num)> chargesReussies = [];
  Object? flammesSeance;

  /// Plus lourde charge du dernier passage de l'exercice.
  num? chargeDerniere;

  /// (jour, charge, répétitions, flammes dites) des barres réussies (1.0.2).
  final List<(int, num, num, Object?)> barres = [];

  /// (jour, charge) des barres ratées sans une répétition faite (1.0.2).
  final List<(int, num)> barresRatees = [];

  /// slotId -> (charge de base d'une semaine de charge, charge de base,
  /// répétitions du schéma) de la dernière séance de l'emplacement.
  final Map<String?, (num?, num?, num?)> marques = {};

  /// slotId -> secondes de tenue de la dernière séance de l'emplacement.
  final Map<String, num> secSlot = {};

  /// (jour, ln capacité + effet de séance), trois au plus (A6.2).
  List<(int, double)> forme = [];

  /// Jour de la dernière alerte de surmenage (A6.2).
  int? alerteJour;
  double? alertePart;
}

/// Budgets de retour gradué de la séance en cours (`_budgets_retour`).
class BudgetsRetour {
  BudgetsRetour({
    required this.limites,
    required this.fait,
    required this.limiteDures,
    required this.faitDures,
    required this.reste,
    required this.limitesTenue,
    required this.budgetsTenue,
    required this.jourTenue,
  });

  /// Limites de la rampe par groupe majeur.
  final List<double> limites;

  /// Réalisé de la semaine par groupe (séances fermées, manquées à l'écrit).
  final List<double> fait;

  /// Limite et réalisé des séries dures d'une semaine d'allègement.
  final double? limiteDures;
  final double? faitDures;

  /// Séances restantes de la semaine (écrit).
  final List<List<Json>> reste;

  /// slotId -> séries permises par le plan de la semaine (1.0.6).
  final Map<String?, int> plan = {};

  /// slotId -> cause d'une coupure du plan : ('groupe', indice) ou
  /// ('total', null).
  final Map<String?, (String, Object?)> cause = {};

  /// Vrai si le plan a réparti les coupes sur la semaine.
  bool? repartie;

  /// Lignes encore en excès après le plan (planchers des principaux).
  List<int> depasse = [];

  final Map<String, double?> limitesTenue;
  final Map<String, double?> budgetsTenue;
  final Map<String, double> jourTenue;
}

/// Unité du plan du retour gradué (`_plan_retour`).
class _UniteRetour {
  _UniteRetour(
    this.seance,
    this.pos,
    this.slot,
    this.n,
    this.poids,
    this.rang,
    this.plancher,
  ) : m = n;

  final int seance;
  final int pos;
  final String? slot;
  final int n;
  int m;
  final List<(int, double)> poids;
  final int rang;
  final int plancher;
}

// ----------------------------------------------------------------------
// Séances
// ----------------------------------------------------------------------

/// Prescription de séance et conseil d'entre-séries.
class Seances {
  Seances(this.p, this.m, this.g, this.fiches) : s = jm(p['securite']);

  static const List<String> famillesBrasTendus = ['push', 'pull', 'mixed'];
  static const int tenueMinS = 5;

  Json p;
  Json s;
  final Modele m;
  final Gardefous g;
  final Map<String, Json> fiches;
  final Map<String, Memoire> memoire = {};
  int jour = 0;
  int palier = 0;
  double decalage = 0.0;
  List<Json> raisons = [];

  /// (jour, secondes, flammes notées max, flammes visées) d'une séance.
  List<(int, double, num?, num?)> courses = [];

  /// Jours de conditionnement dur.
  List<int> joursDurs = [];

  /// Jours de course dure.
  List<int> joursCourseDure = [];

  /// Jours d'entraînement (au moins une série hors échauffement).
  List<int> joursActifs = [];
  double courseMetres = 0.0;
  double courseSecondes = 0.0;

  /// Jours des séances fermées (reprise après coupure, A6.1).
  List<int> joursSeances = [];

  /// Jour de la séance de retour de la dernière coupure.
  int? retour;
  int? derniereSeance;
  int coupure = 0;
  Json? contexte;

  /// slotId -> plan de l'item servi (séance en cours).
  Map<String?, Json> plans = {};

  /// zone -> {semaine: séries faites des mouvements qui la provoquent}.
  final Map<String, Map<int, int>> doseZone = {};

  /// id -> (niveaux de zone, zones provoquées), vu à la prescription.
  final Map<String, (Json, Set<String>)> zonesEx = {};

  /// zone -> {semaine: séries écrites (séances vues et manquées)}.
  final Map<String, Map<int, int>> ecritZone = {};

  /// zone sensible -> séries encore permises aujourd'hui (rampe du réalisé).
  Map<String, num> budgetZone = {};

  /// zone sensible -> séries permises cette semaine (total).
  Map<String, int> budgetSemaine = {};

  /// Zones encore sous rampe après la fenêtre sensible (sortie progressive).
  final Set<String> rampeZone = {};

  /// zone -> (semaine d'entrée, départ) de la rampe de retour après coupure
  /// (règle 3 bis).
  final Map<String, (int, int)> retourZone = {};

  /// zone -> {semaine: séries écrites des séances manquées qui la
  /// provoquent}.
  final Map<String, Map<int, int>> manqueZone = {};

  /// zone -> dernier jour d'exposition réalisée (règle 3 bis).
  final Map<String, int> expoJour = {};

  /// zone sous budget -> séries que l'échauffement peut prendre aujourd'hui.
  Map<String, num> reserveEchauffement = {};

  /// Exercices pour lesquels la porte du vrai test a laissé consulter
  /// `_vraiTest`, dans l'ordre (lecture pour les tests : la référence compte
  /// ces appels en remplaçant `Seances._vrai_test`). N'entre dans aucun
  /// résultat.
  final List<String> appelsVraiTest = [];

  /// semaine -> séries dures créditées par groupe majeur.
  final Map<int, List<double>> volSemaines = {};

  /// semaine -> {famille: secondes de tenue bras tendus}.
  final Map<int, Map<String, double>> tenueSemaines = {};

  /// semaine -> séries dures servies, tous groupes.
  final Map<int, double> duresSemaines = {};

  /// semaine -> séries dures écrites des séances vues.
  final Map<int, double> ecritSemaines = {};

  /// semaine -> semaine allégée par nature.
  final Map<int, bool> allegees = {};

  /// semaine -> intention ou genre de la semaine.
  final Map<int, Object?> genres = {};

  /// Items servis de la séance en cours.
  List<Json>? servis;

  /// Budgets de la séance en cours.
  BudgetsRetour? retourVol;

  /// Semaines où une séance a été manquée (1.0.6, répartition).
  final Set<int> semainesManquees = {};

  num _n(String k) => s[k] as num;

  Memoire mem(String exId) {
    if (!memoire.containsKey(exId)) {
      memoire[exId] = Memoire();
    }
    return memoire[exId]!;
  }

  // ------------------------------------------------------------------
  // Prévisions
  // ------------------------------------------------------------------
  double _gardeSerie(Piste t) => m.gardeDe(t);

  /// Charge externe (hors grille) pour [reps] répétitions à [rir] en
  /// réserve aujourd'hui, au quantile prudent ; null si la piste n'est pas
  /// une charge.
  double? chargePour(
    String exId,
    double reps,
    double rir, [
    double prudence = 0.0,
  ]) {
    final t = m.piste(exId);
    if (t == null || t.type != 'charge') {
      return null;
    }
    final (mu, sd) = m.capaciteDuJour(exId)!;
    final (lamb, k) = m.courbe(t);
    final r = (reps + rir) / _gardeSerie(t);
    final total = math.exp(mu - prudence * sd - Modele.gK(lamb, k, r));
    return total - t.fraction * m.poidsKg;
  }

  /// Charge totale qui correspond, pour cet athlète, à une part écrite du
  /// 1RM (niveau d'effort lu sur la courbe de population).
  double chargeDePart(String exId, double part, {bool duJour = false}) {
    final t = m.piste(exId);
    final mu = duJour ? m.capaciteDuJour(exId)!.$1 : m.capacite(exId)!.$1;
    if (part >= 1.0) {
      return math.exp(mu) * part;
    }
    final ap = jm(p['a_priori']);
    final lam0 = jld(ap['courbe_forme'])[0];
    final k0 =
        jld(ap['courbe_echelle'])[0] +
        (t!.bas ? dbl(ap['courbe_bas_du_corps']) : 0.0);
    final x = -math.log(part);
    // Inverse de g sur la courbe de population (forme fermée).
    final r = x > 0 ? Modele.repsDe(lam0, k0, x) : 1.0;
    final (lamb, k) = m.courbe(t);
    return math.exp(mu - Modele.gK(lamb, k, r));
  }

  /// Répétitions prévues à [rir] en réserve avec la charge [externe].
  double? repsPrevues(String exId, double? externe, double rir) {
    final t = m.piste(exId);
    if (t == null) {
      return null;
    }
    final (mu, _) = m.capaciteDuJour(exId)!;
    double r;
    if (t.type == 'charge') {
      final masse = m.masse(t, externe);
      if (masse <= 0) {
        return null;
      }
      r = m.repsA(t, mu - math.log(masse));
    } else if (t.type == 'reps') {
      r = math.exp(mu);
    } else {
      return null;
    }
    return r * _gardeSerie(t) - rir;
  }

  double? secondesPrevues(String exId, double rir) {
    final t = m.piste(exId);
    if (t == null || t.type != 'tenue') {
      return null;
    }
    final (mu, _) = m.capaciteDuJour(exId)!;
    final hhe =
        clampD(m.m[hh], 0.03, 0.3) *
        math.exp(clampD(m.m[t.idx + 1], -1.0, 1.0));
    var f = 1.0 - hhe * rir;
    if (f < 0.15) {
      f = 0.15;
    }
    return math.exp(mu) * _gardeSerie(t) * f;
  }

  /// P(réussir [reps] répétitions avec la charge [externe] aujourd'hui) ;
  /// [brut] : écart-type sans l'élargissement de la fiabilité (tentatives).
  double? probaReussite(
    String exId,
    double externe, [
    num reps = 1,
    bool brut = false,
  ]) {
    final t = m.piste(exId);
    if (t == null || t.type != 'charge') {
      return null;
    }
    final (mu, sd) = m.capaciteDuJour(exId, brut: brut)!;
    final (lamb, k) = m.courbe(t);
    final besoin =
        math.log(m.masse(t, externe)) +
        Modele.gK(lamb, k, reps / _gardeSerie(t));
    return normCdfK((mu - besoin) / _seMax(sd, 0.005));
  }

  /// Information attendue d'une série sur la capacité de l'exercice :
  /// variance retirée à ln capacité par l'observation de la réserve perçue
  /// à cette charge (test adaptatif).
  double information(String exId, double externe, double reps) {
    final t = m.piste(exId);
    if (t == null || t.type != 'charge') {
      return 0.0;
    }
    final masse = m.masse(t, externe);
    if (masse <= 0) {
      return 0.0;
    }
    final (idx, co, _, rr, v) = m._linForce(
      t,
      m.m,
      math.log(masse),
      reps,
      m.intra(t),
      false,
      true,
    );
    final (_, variance, ph) = Modele.stats(m.m, m.pm, m.cap, idx, co);
    final (hi, hc) = m.hCapacite(t, jour: false);
    var cov = 0.0;
    for (var q = 0; q < hi.length && q < hc.length; q++) {
      cov += hc[q] * ph[hi[q]];
    }
    final r = v > 0 ? v : 0.0;
    final s2 = pw(m.bruitRirDe(r < 8 ? r : 8.0, rr), 2);
    return cov * cov / (variance + s2);
  }

  // ------------------------------------------------------------------
  // Séance
  // ------------------------------------------------------------------

  /// Début de séance : palier du bilan, coupure, verrous de semaine.
  void ouvrir(int jour, Json? bilan, Json contexte) {
    this.jour = jour;
    this.contexte = contexte;
    if (vrai(contexte) && contexte['semaine'] != null) {
      g.noterSemaine(
        ent(contexte['semaine']),
        contexte['genre'],
        contexte['intention'],
      );
      genres[ent(contexte['semaine'])] = ou(
        contexte['intention'],
        contexte['genre'],
      );
    }
    final (pal, dec) = g.palierBilan(bilan);
    palier = pal;
    decalage = dec;
    coupure = _coupure(jour);
    retour = _retour(jour);
    raisons = [];
    // A2.2 : renvoi vers un professionnel à la première séance d'un arrêt,
    // puis à la première séance de chaque semaine d'arrêt.
    for (final z in g.renvois()) {
      _raison('koach.douleur_persistante', {'zone': z, 'consulter': true});
    }
    plans = {};
    budgetZone = {};
    servis = null;
    retourVol = null;
    final c = dictOuVide(this.contexte);
    final legeres = jl(s['semaines_allegees']);
    for (final mq0 in listeOuVide(c['manquees'])) {
      // Séance manquée : comptée à son volume écrit.
      final mq = jm(mq0);
      if (mq['semaine'] == null) {
        continue;
      }
      final sem = ent(mq['semaine']);
      semainesManquees.add(sem);
      if (mq.containsKey('genre') && !allegees.containsKey(sem)) {
        allegees[sem] = dans(mq['genre'], legeres);
      }
      _compter(sem, [for (final x in listeOuVide(mq['items'])) jm(x)]);
      ecritSemaines[sem] =
          (ecritSemaines[sem] ?? 0.0) +
          somme([
            for (final x in listeOuVide(mq['items'])) _seriesDures(jm(x)),
          ]);
      _compterEcritZone(sem, [for (final x in listeOuVide(mq['items'])) jm(x)]);
      _compterManqueZone(sem, [
        for (final x in listeOuVide(mq['items'])) jm(x),
      ]);
    }
    if (c['semaine'] != null) {
      allegees[ent(c['semaine'])] = dans(c['genre'], legeres);
    }
    budgetSemaine = {};
    for (final z in g.zones.keys.toList()..sort()) {
      final (b, sortie) = _budgetZoneSemaine(z);
      if (sortie) {
        rampeZone.remove(z);
      }
      if (b != null) {
        budgetSemaine[z] = b;
        rampeZone.add(z);
      }
    }
    // Règle 3 bis : zones en rampe de retour (séances manquées) ; la rampe
    // de la zone sensible l'emporte dès qu'elle s'applique ; une semaine
    // verrouillée (intro, allègement, affûtage, test, compétition,
    // transition : volume déjà réduit ou échéance) la suspend.
    for (final z in retourZone.keys.toList()..sort()) {
      if (budgetSemaine.containsKey(z) || g.sensible(z)) {
        retourZone.remove(z);
        continue;
      }
      if (verrouillee()) {
        continue;
      }
      final (b, sortie) = _budgetRetour(z);
      if (sortie || b == null) {
        retourZone.remove(z);
      } else {
        budgetSemaine[z] = b;
      }
    }
    for (final mm in memoire.values) {
      mm.chargeSeance = null;
      mm.repsSeance = null;
      mm.secSeance = null;
      mm.echecSeance = 0;
      mm.totalSeance = 0.0;
      mm.facilesSeance = 0;
    }
  }

  /// Durée de la coupure qui vaut encore aujourd'hui (règle A6.1), 0 sinon.
  int _coupure(int jour) {
    final js = joursSeances;
    if (js.isEmpty) {
      return 0;
    }
    if (jour - js.last >= _n('coupure_j')) {
      return jour - js.last;
    }
    for (var i = js.length - 1; i > 0; i--) {
      if (js[i] < jour - _n('coupure_fenetre_j')) {
        break;
      }
      if (js[i] - js[i - 1] >= _n('coupure_j')) {
        return js[i] - js[i - 1];
      }
    }
    return 0;
  }

  /// Jour de la séance de retour de la dernière coupure d'au moins
  /// `coupure_j` jours, ou null.
  int? _retour(int jour) {
    final js = joursSeances;
    if (js.isEmpty) {
      return null;
    }
    if (jour - js.last >= _n('coupure_j')) {
      return jour;
    }
    for (var i = js.length - 1; i > 0; i--) {
      if (js[i] - js[i - 1] >= _n('coupure_j')) {
        return js[i];
      }
    }
    return null;
  }

  /// Séances de l'exercice faites depuis le retour de coupure (null hors
  /// retour).
  int? _apresRetour(Memoire mm) {
    final r = retour;
    if (r == null) {
      return null;
    }
    var n = 0;
    for (final j in mm.jours) {
      if (j >= r) {
        n += 1;
      }
    }
    return n;
  }

  int _doseSemaine(String z, int semaine) => doseZone[z]?[semaine] ?? 0;

  // `Seances._semaine_connue` de la référence n'est appelée nulle part
  // (1.0.5) : non portée (élément privé inutilisé).

  /// Semaine connue ET de charge (genre ou intention hors allègement, test,
  /// affûtage, compétition, transition) ; une semaine entièrement manquée
  /// est une semaine de charge connue à exposition 0.
  bool _semaineDeCharge(int w) {
    final gs = g.semaines[w];
    if (gs != null) {
      return gs;
    }
    final al = allegees[w];
    if (al != null) {
      return !al;
    }
    return false;
  }

  /// Séries écrites de la semaine [semaine] par zone provoquée (exercices
  /// déjà vus à la prescription ; échauffement compris, comme le réalisé de
  /// [fermer]).
  void _compterEcritZone(int semaine, List<Json> items) {
    for (final x in items) {
      final zz = zonesEx[x['exerciseId']];
      if (zz == null) {
        continue;
      }
      final n = ent(ou(x['sets'], 0));
      if (n <= 0) {
        continue;
      }
      for (final z in zz.$2) {
        final e = ecritZone.putIfAbsent(z, () => <int, int>{});
        e[semaine] = (e[semaine] ?? 0) + n;
      }
    }
  }

  int _ecritZone(String z, int semaine) => ecritZone[z]?[semaine] ?? 0;

  /// Séries écrites des séances manquées de la semaine [semaine] par zone
  /// provoquée (exercices déjà vus) : ce que la zone n'a pas reçu (règle 3
  /// bis).
  void _compterManqueZone(int semaine, List<Json> items) {
    for (final x in items) {
      final zz = zonesEx[x['exerciseId']];
      if (zz == null) {
        continue;
      }
      final n = ent(ou(x['sets'], 0));
      if (n <= 0) {
        continue;
      }
      for (final z in zz.$2) {
        final e = manqueZone.putIfAbsent(z, () => <int, int>{});
        e[semaine] = (e[semaine] ?? 0) + n;
      }
    }
  }

  /// Vrai si une séance manquée a privé la zone [z] d'exposition dans la
  /// fenêtre de la charge chronique.
  bool _manqueRecent(String z) {
    final semaine = g.semaine;
    final mq = manqueZone[z] ?? const <int, int>{};
    for (
      var k = semaine - ent(s['charge_chronique_semaines']);
      k < semaine;
      k++
    ) {
      if ((mq[k] ?? 0) > 0) {
        return true;
      }
    }
    return false;
  }

  /// 1.0.5 (lot KM1c4, règles 1 à 3) : (permis, sortie) — séries permises
  /// cette semaine, tous mouvements qui provoquent la zone [z] confondus
  /// (échauffement compris), quand la zone est sensible
  /// ([Gardefous.sensible]) ou encore sous rampe après la fenêtre (sortie
  /// progressive) ; (null, false) sinon ; `sortie` vrai quand la zone sort
  /// de la rampe. Fonction pure (l'appelant tient [rampeZone]). « Rampe du
  /// réalisé » : référence = exposition réalisée de la dernière semaine de
  /// charge connue depuis l'épisode (et après la levée d'un arrêt), permis
  /// = max(référence + 1 ; référence × (1 + `reprise_dose_hausse`)), tenue
  /// sous une gêne récente ; sans référence, `reprise_dose_depart` ×
  /// habitude (charge chronique des quatre semaines d'avant l'épisode), ou
  /// `reprise_dose_sans_habitude` ; jamais sous `reprise_dose_min`. Port
  /// ligne pour ligne de `Seances._budget_zone_semaine`.
  (int?, bool) _budgetZoneSemaine(String z) {
    final d = g.zones[z];
    if (d == null) {
      return (null, false);
    }
    final semaine = g.semaine;
    final ep = g.episode(z);
    final sensible = g.sensible(z);
    if (!sensible && !rampeZone.contains(z)) {
      return (null, false);
    }
    final rzsm = ent(s['rampe_zone_semaines_max']);
    final debut = ep != null ? divEnt(ep.$1, 7) : semaine;
    // Après un arrêt levé dans l'épisode, rien d'avant la semaine de la
    // levée ne sert de référence (la zone repart de l'arrêt).
    var apres = debut + 1;
    final leve = d.arretLeve;
    if (ep != null && leve != null && leve >= ep.$1) {
      // Première semaine qui compte après la levée : celle de la levée si
      // elle lui laisse au moins 4 jours, sinon la suivante.
      final premiere = 7 - (leve % 7) >= 4
          ? divEnt(leve, 7)
          : divEnt(leve, 7) + 1;
      apres = _seMax(apres, premiere);
    }
    int? ref;
    var tenir = false;
    if (semaine == debut) {
      // Semaine du signalement : tenue au réalisé de la semaine de charge
      // précédente ; sans semaine de charge précédente, départ.
      var w = semaine - 1;
      while (w >= 0 && w >= semaine - rzsm) {
        if (_semaineDeCharge(w)) {
          ref = _doseSemaine(z, w);
          tenir = true;
          break;
        }
        w -= 1;
      }
    } else {
      var w = semaine - 1;
      while (w >= debut && w >= 0) {
        if (_semaineDeCharge(w)) {
          if (w < apres) {
            break;
          }
          ref = _doseSemaine(z, w);
          if (ref <= 0) {
            final fin = _seMax(apres, w - rzsm) - 1;
            for (var k = w - 1; k > fin; k--) {
              if (_semaineDeCharge(k) && _doseSemaine(z, k) > 0) {
                ref = _doseSemaine(z, k);
                break;
              }
            }
          }
          break;
        }
        w -= 1;
      }
      if (ref == null && debut < semaine && apres == debut + 1) {
        // Aucune semaine de charge connue entre le signalement et
        // aujourd'hui : la semaine du signalement sert, tenue.
        if (_semaineDeCharge(debut)) {
          ref = _doseSemaine(z, debut);
          tenir = true;
        }
      }
    }
    if (ref != null && ref > 0 && g.arret(z)) {
      ref = null;
    }
    int total;
    if (ref != null && ref > 0) {
      if (tenir ||
          d.pireEntre(jour - _n('douleur_hausse_j') + 1, jour) >
              _n('reprise_douleur_max')) {
        total = ref;
      } else {
        total = _seMax(
          ref + 1,
          (ref * (1 + dbl(s['reprise_dose_hausse'])) + 1e-9).floor(),
        );
      }
    } else {
      final avant = <int>[
        for (var k = debut - 4; k < debut; k++)
          if (k >= 0 && _semaineDeCharge(k)) _doseSemaine(z, k),
      ];
      if (avant.isNotEmpty) {
        var tot = 0;
        for (final x in avant) {
          tot += x;
        }
        final habitude = tot / 4.0;
        total = (dbl(s['reprise_dose_depart']) * habitude + 1e-9).floor();
      } else {
        total = ent(s['reprise_dose_sans_habitude']);
      }
    }
    if (total < _n('reprise_dose_min')) {
      total = ent(s['reprise_dose_min']);
    }
    if (!sensible) {
      // Sortie progressive (règle 2) : après la fenêtre, la rampe continue
      // tant que le permis n'atteint pas l'écrit (dernière semaine de charge
      // connue, et semaine en cours vue jusqu'ici) ; dès qu'il l'atteint, la
      // zone sort.
      var ecritRef = _ecritZone(z, semaine);
      var w = semaine - 1;
      while (w >= 0) {
        if (_semaineDeCharge(w)) {
          ecritRef = _seMax(ecritRef, _ecritZone(z, w));
          break;
        }
        w -= 1;
      }
      if (total >= ecritRef) {
        return (null, true);
      }
    }
    return (total, false);
  }

  /// Habitude de la zone [z] avant une coupure (règle 3 bis) : moyenne de
  /// l'exposition réalisée sur les `charge_chronique_semaines` semaines
  /// calendaires qui finissent à la semaine [fin], limitées à celles qui
  /// suivent la première semaine connue du journal. null sans semaine
  /// connue.
  double? _habitudeAvant(String z, int fin) {
    final connues = <int>[...g.semaines.keys, ...allegees.keys];
    if (connues.isEmpty) {
      return null;
    }
    var premiere = connues[0];
    for (final k in connues) {
      if (k < premiere) {
        premiere = k;
      }
    }
    final ks = <int>[
      for (
        var k = fin - ent(s['charge_chronique_semaines']) + 1;
        k < fin + 1;
        k++
      )
        if (k >= premiere) k,
    ];
    if (ks.isEmpty) {
      return null;
    }
    var tot = 0;
    for (final k in ks) {
      tot += _doseSemaine(z, k);
    }
    return tot / ks.length.toDouble();
  }

  /// Permis de la première semaine de retour d'une zone après une coupure :
  /// `reprise_dose_depart` × habitude d'avant la coupure,
  /// `reprise_dose_sans_habitude` sans exposition connue, jamais sous
  /// `reprise_dose_min`.
  int _departRetour(String z) {
    final fin = divEnt(expoJour[z]!, 7);
    final habitude = _habitudeAvant(z, fin);
    int total;
    if (habitude == null || habitude <= 0) {
      total = ent(s['reprise_dose_sans_habitude']);
    } else {
      total = (dbl(s['reprise_dose_depart']) * habitude + 1e-9).floor();
    }
    if (total < _n('reprise_dose_min')) {
      total = ent(s['reprise_dose_min']);
    }
    return total;
  }

  /// 1.0.5 (lot KM1c4, règle 3 bis, « rampe du réalisé après une
  /// coupure ») : (permis, sortie) pour une zone sans douleur connue qui
  /// revient d'une coupure ([_entrerRetour]). Même rampe que la zone
  /// sensible depuis l'entrée ([debut]) ; sans référence, le départ
  /// [depart] figé à l'entrée ; jamais sous `reprise_dose_min` ; `sortie`
  /// dès que le permis atteint l'écrit. Fonction pure (l'appelant tient
  /// [retourZone]).
  (int?, bool) _budgetRetour(String z, {int? depart, int? debut}) {
    final semaine = g.semaine;
    int debutR;
    int departR;
    if (debut == null || depart == null) {
      final r = retourZone[z];
      if (r == null) {
        return (null, false);
      }
      debutR = r.$1;
      departR = r.$2;
    } else {
      debutR = debut;
      departR = depart;
    }
    final rzsm = ent(s['rampe_zone_semaines_max']);
    int? ref;
    var w = semaine - 1;
    while (w >= debutR && w >= 0) {
      if (_semaineDeCharge(w)) {
        ref = _doseSemaine(z, w);
        if (ref <= 0) {
          final fin = _seMax(debutR, w - rzsm) - 1;
          for (var k = w - 1; k > fin; k--) {
            if (_semaineDeCharge(k) && _doseSemaine(z, k) > 0) {
              ref = _doseSemaine(z, k);
              break;
            }
          }
        }
        break;
      }
      w -= 1;
    }
    int total;
    if (ref != null && ref > 0) {
      total = _seMax(
        ref + 1,
        (ref * (1 + dbl(s['reprise_dose_hausse'])) + 1e-9).floor(),
      );
    } else {
      total = departR;
    }
    if (total < _n('reprise_dose_min')) {
      total = ent(s['reprise_dose_min']);
    }
    var ecritRef = _ecritZone(z, semaine);
    w = semaine - 1;
    while (w >= 0) {
      if (_semaineDeCharge(w)) {
        ecritRef = _seMax(ecritRef, _ecritZone(z, w));
        break;
      }
      w -= 1;
    }
    if (total >= ecritRef) {
      return (null, true);
    }
    return (total, false);
  }

  /// Règle 3 bis : une zone sans douleur connue, ni sous rampe, qui n'a reçu
  /// aucune exposition depuis `coupure_j` jours au moins alors qu'une séance
  /// manquée l'écrivait dans les `charge_chronique_semaines` dernières
  /// semaines, entre dans la rampe de retour quand l'écrit de la semaine
  /// (séances vues et manquées, séance du jour, séances restantes) dépasse
  /// son départ ; son permis est posé pour la semaine. Une semaine
  /// verrouillée n'ouvre ni n'applique la rampe de retour.
  void _entrerRetour(List<Json> items) {
    final c = dictOuVide(contexte);
    final semaine = g.semaine;
    if (verrouillee()) {
      return;
    }
    final zones = <String>{...doseZone.keys};
    final reste = <String, int>{};
    final seances = <(List<Json>, bool)>[
      for (final x in listeOuVide(c['reste_semaine']))
        ([for (final y in listeOuVide(x)) jm(y)], false),
      (items, true),
    ];
    for (final (seance, duJour) in seances) {
      for (final x in seance) {
        final zz = zonesEx[x['exerciseId']];
        if (zz == null) {
          continue;
        }
        for (final z in zz.$2) {
          zones.add(z);
          if (!duJour) {
            reste[z] = (reste[z] ?? 0) + ent(ou(x['sets'], 0));
          }
        }
      }
    }
    for (final z in zones.toList()..sort()) {
      if (budgetSemaine.containsKey(z) ||
          retourZone.containsKey(z) ||
          rampeZone.contains(z) ||
          g.sensible(z)) {
        continue;
      }
      final ej = expoJour[z];
      if (ej == null || jour - ej < _n('coupure_j')) {
        continue;
      }
      if (!_manqueRecent(z)) {
        continue;
      }
      final ecrit = _ecritZone(z, semaine) + (reste[z] ?? 0);
      if (ecrit <= 0) {
        continue;
      }
      final depart = _departRetour(z);
      final (permis, _) = _budgetRetour(z, depart: depart, debut: semaine);
      if (permis != null && permis < ecrit) {
        retourZone[z] = (semaine, depart);
        budgetSemaine[z] = permis;
      }
    }
  }

  /// Part du budget hebdomadaire de chaque zone sous rampe pour la séance du
  /// jour : reste de la semaine réparti au prorata de l'écrit du jour et des
  /// séances restantes de la semaine (`contexte['reste_semaine']`), arrondi
  /// au plus proche (demi vers le haut) ; tout le reste quand rien n'est
  /// écrit.
  Map<String, num> _budgetsZoneJour(List<Json> items) {
    final out = <String, num>{};
    final c = dictOuVide(contexte);
    final semaine = g.semaine;
    for (final e in budgetSemaine.entries) {
      final z = e.key;
      var reste = e.value - _doseSemaine(z, semaine);
      if (reste < 0) {
        reste = 0;
      }
      var eJour = 0;
      for (final x in items) {
        final zz = zonesEx[x['exerciseId']];
        if (zz != null && zz.$2.contains(z)) {
          eJour += ent(ou(x['sets'], 0));
        }
      }
      var eReste = 0;
      for (final sc in listeOuVide(c['reste_semaine'])) {
        for (final y in listeOuVide(sc)) {
          final x = jm(y);
          final zz = zonesEx[x['exerciseId']];
          if (zz != null && zz.$2.contains(z)) {
            eReste += ent(ou(x['sets'], 0));
          }
        }
      }
      int part;
      if (eJour + eReste > 0) {
        part = (reste * eJour / (eJour + eReste).toDouble() + 0.5).floor();
      } else {
        part = reste;
      }
      out[z] = part;
    }
    return out;
  }

  bool verrouillee() {
    final c = dictOuVide(contexte);
    return semainesVerrouillees.contains(ou(c['intention'], c['genre'])) ||
        const ['deload', 'test', 'intro'].contains(c['genre']);
  }

  /// Sert la séance écrite [items]. [grilles] : id -> Grille ; [zones] :
  /// id -> (niveaux de zone, zones provoquées) ; [roles] : slotId -> rôle.
  /// Renvoie les items servis (mêmes champs, plus `koach`).
  List<Json> prescrire(
    List<Json> items,
    Map<String, Grille> grilles,
    Map<String, (Json, Set<String>)> zones,
    Json roles,
  ) {
    var out = <Json>[];
    final testes = <String>{};
    for (final e in zones.entries) {
      zonesEx[e.key] = e.value;
    }
    retourVol = _budgetsRetour(items);
    final semO = dictOuVide(contexte)['semaine'];
    if (semO != null) {
      final sem = ent(semO);
      ecritSemaines[sem] =
          (ecritSemaines[sem] ?? 0.0) +
          somme([for (final x in items) _seriesDures(x)]);
      _compterEcritZone(sem, items);
      _entrerRetour(items);
    }
    budgetZone = _budgetsZoneJour(items);
    // Réserve de l'échauffement : ce que le permis du jour laisse après les
    // séries de travail écrites sur la zone (le travail d'abord).
    reserveEchauffement = {};
    for (final e in budgetZone.entries) {
      final z = e.key;
      var travail = 0;
      for (final x in items) {
        final zz = zonesEx[x['exerciseId']];
        if (zz != null && zz.$2.contains(z) && x['kind'] != 'warmup') {
          travail += ent(ou(x['sets'], 0));
        }
      }
      reserveEchauffement[z] = _seMax<num>(0, e.value - travail);
    }
    // 1.0.6 (KM4) : deux passes — la séance servie par les règles de
    // chaque exercice, puis le plan du retour gradué de la semaine
    // (`_planRetour`) appliqué ligne par ligne avec le vrai test.
    final premiers = <(Json, Json?)>[];
    for (final item in items) {
      final servi = _item(
        item,
        grilles[item['exerciseId']],
        zones[item['exerciseId']],
        roles[item['slotId']],
      );
      premiers.add((item, servi));
    }
    _planRetour([
      for (final (item, servi) in premiers)
        if (servi != null) (item, servi),
    ]);
    for (final (item, servi0) in premiers) {
      if (servi0 == null) {
        continue;
      }
      final servi = _retourGradue(servi0);
      if (servi == null) {
        plans.remove(item['slotId']);
        continue;
      }
      final plan = plans[item['slotId']];
      final exId = item['exerciseId'] as String;
      final zonesTest = zones[exId]?.$2 ?? const <String>{};
      if (plan != null &&
          !testes.contains(exId) &&
          item['kind'] == 'work' &&
          !zonesTest.any(
            (z) => budgetZone.containsKey(z) && !retourZone.containsKey(z),
          )) {
        // 1.0.5 : pas de vrai test (montée de charge) sur un mouvement qui
        // provoque une zone SENSIBLE sous rampe du réalisé ; la rampe de
        // retour après une coupure (règle 3 bis) ne l'interdit pas.
        appelsVraiTest.add(exId);
        var vt = _vraiTest(servi, plan, m.pistes[exId]);
        if (vt != null &&
            !_dureePermetTest(
              items,
              item,
              vt,
              out.where((x) => x['koach'] == 'vrai_test').length,
            )) {
          vt = null;
        }
        if (vt != null) {
          // Vrai test programmé : montée de charge servie comme un test, à
          // la place d'une série de travail.
          testes.add(exId);
          final ta = jm(p['test_adaptatif']);
          final slot = '${item['slotId'] as String}.t';
          final test = <String, Object?>{
            'slotId': slot,
            'exerciseId': exId,
            'sets': (ta['rampe_series_max'] as num) + (vt.$1 == 1 ? 2 : 0),
            'repsLow': vt.$1,
            'repsHigh': vt.$1,
            'targetFlames': flammesDeRir(vt.$2.toDouble()),
            'restSeconds': _seMax<num>(
              ou(item['restSeconds'], 0) as num,
              ta['repos_test_s'] as num,
            ),
            'kind': 'test',
            'test': <String, Object?>{
              'kind': 'rep_max',
              'targetRir': vt.$2,
              'attempts': ta['rampe_series_max'],
            },
            'loadBasis': item['loadBasis'],
            'toCalibrate': false,
            'reasons': <Object?>[
              <String, Object?>{
                'code': 'koach.vrai_test',
                'params': <String, Object?>{},
              },
            ],
            'koach': 'vrai_test',
          };
          // Séries de la ligne avant la montée : celles servies, jamais plus
          // que l'écrit.
          final lignes = _seMin(
            ent(ou(item['sets'], 0)),
            ent(ou(servi['sets'], 0)),
          );
          final p2 = Map<String, Object?>.of(plan);
          p2.addAll(<String, Object?>{
            'test': true,
            'rampe': vt,
            'echecs': 0,
            'ecrit': test,
            'charge_item': null,
            'durs': 0,
            'durs_max': _seMax(1, lignes - 1),
          });
          plans[slot] = p2;
          _raison('koach.vrai_test', {'exercice': exId});
          out.add(test);
          // Les deux séries proches de la limite de la montée remplacent
          // autant de séries de travail.
          final retire = _seMin<num>(
            ent(ta['rampe_series_travail']),
            (servi['sets'] as num) - 1,
          );
          if (retire > 0) {
            servi['sets'] = (servi['sets'] as num) - retire;
          }
          plan['apres_test'] = true;
          plan['slot_test'] = slot;
          plan['series_ecrites'] = lignes;
        }
      }
      out.add(servi);
    }
    out = _dureeBornee(_endurance(out), items);
    servis = [for (final it in out) Map<String, Object?>.of(it)];
    return out;
  }

  void _raison(String code, Json params) {
    raisons.add(<String, Object?>{'code': code, 'params': params});
  }

  Json? _item(
    Json item,
    Grille? grille,
    (Json, Set<String>)? zone,
    Object? role,
  ) {
    final exId = item['exerciseId'] as String;
    final fiche = dictOuVide(fiches[exId]);
    final typ = fiche['type'];
    final estTest = item['kind'] == 'test';
    final echauffement = item['kind'] == 'warmup';
    final c = dictOuVide(contexte);
    final evenement = vrai(c['jour_evenement']);
    final (niveaux, hits) = zone ?? (<String, Object?>{}, <String>{});
    final mem = this.mem(exId);
    final cond = g.conduite(
      niveaux,
      hits,
      estTest: estTest,
      depuisJour: mem.jour,
      fiche: fiche,
      echauffement: echauffement,
    );
    if (vrai(cond['retire'])) {
      _raison('koach.douleur_retrait', {
        'exercice': exId,
        'zone': cond['zone'],
        'cause': cond['raison'],
      });
      return null;
    }
    if (estTest && palier >= 1 && !evenement) {
      _raison('koach.test_reporte', {'exercice': exId, 'cause': 'bilan_bas'});
      return null;
    }
    if (estTest &&
        coupure > 0 &&
        !evenement &&
        typ == 'charge' &&
        const [
          'one_rm',
          'attempt_simulation',
        ].contains(dictOuVide(item['test'])['kind'])) {
      // Semaine du retour après une coupure : pas de tentative maximale.
      _raison('koach.test_reporte', {'exercice': exId, 'cause': 'coupure'});
      return null;
    }
    final servi = Map<String, Object?>.of(item);
    final plan = <String, Object?>{
      'cond': cond,
      'role': role,
      'test': estTest,
      'type': typ,
      'grille': grille,
      'sans_hausse': vrai(cond['sans_hausse']) || palier >= 1,
      'rir_bonus': cond['rir'],
      'rir_min': cond['rir_min'],
      'part_max': cond['part_max'],
      'echecs': 0,
      'baisse': 1.0,
      'verrou': verrouillee(),
      'ecrit': item,
      'tete': null,
      'repere': false,
      'dose_plafonnee': cond['dose_plafonnee'],
      'fragile': cond['fragile'],
      'servi': servi,
    };
    if (coupure > 0 && const ['reps', 'tenue'].contains(typ)) {
      // Semaine du retour après une coupure : répétitions et tenues
      // jamais au-dessus de la dernière séance ; pas de mesure ni de test.
      plan['sans_hausse'] = true;
    }
    if (coupure > 0 && typ == 'charge') {
      // 1.0.2 — reprise par paliers mesurés (C13.12) : la première série ne
      // dépasse pas la dernière séance du même schéma (ou les barres
      // récentes) ; chaque série faite, dite au plus aussi dure que visé,
      // autorise le palier suivant (+5 % ou un cran), jusqu'à la charge que
      // l'estimation demande.
      plan['reprise'] = true;
    }
    if (cond['appui_neutre'] != null) {
      _raison('koach.poignet_appui_neutre', {
        'exercice': exId,
        'intensite': cond['appui_neutre'],
      });
    }
    if (vrai(cond['poignet_sensible']) && !echauffement) {
      _raison('koach.poignet_dose', {'exercice': exId});
    }
    _technique(servi, plan, cond);
    if (palier == 1) {
      plan['rir_bonus'] = dbl(plan['rir_bonus']) + dbl(s['bilan_rir_bonus']);
    } else if (palier == 2) {
      plan['rir_bonus'] =
          dbl(plan['rir_bonus']) + 2 * dbl(s['bilan_rir_bonus']);
      plan['rir_min'] = _seMax(
        _seOu(plan['rir_min'], 0.0),
        dbl(s['bilan_bas_rir_min']),
      );
    }
    var series = _seGet(servi, 'sets', 0) as num;
    if (!estTest && const ['charge', 'reps', 'tenue'].contains(typ)) {
      if (!echauffement) {
        final f = dbl(cond['series']);
        if (f < 1.0) {
          series = _seMax(1, (series * f + 1e-9).floor());
        }
      }
      // A6.1 : reprise après coupure, échauffement compris.
      if (coupure >= _n('coupure_j')) {
        final n = (series * dbl(s['coupure_series']) + 0.5).floor();
        if (1 <= n && n < series) {
          series = n;
          _raison('koach.reprise_coupure', {
            'exercice': exId,
            'jours': coupure,
          });
        }
      }
      if (!echauffement) {
        if (palier == 2 && item['targetFlames'] != null) {
          final plancherS = role == 'main' ? 3 : 2;
          if (series > plancherS) {
            series -= 1;
          }
        }
        series = _surmenage(exId, mem, role, series);
      }
    }
    // Rampe du réalisé (1.0.5, KM1c4) : séries de tout mouvement qui
    // provoque une zone sous budget ramenées à ce que la séance permet
    // encore, échauffement compris (chaque série expose la structure).
    String? epuisee;
    final tri = hits.toList()..sort();
    for (final z in tri) {
      if (budgetZone.containsKey(z)) {
        var reste = budgetZone[z]!;
        if (echauffement) {
          // L'échauffement ne prend que ce que le travail de la séance
          // laisse (réservé à la prescription).
          reste = _seMin<num>(reste, reserveEchauffement[z] ?? reste);
        }
        if (series > reste) {
          series = reste > 0 ? reste : 0;
          if (series <= 0) {
            epuisee = z;
          }
          _raison('koach.reprise_dose', {'exercice': exId, 'zone': z});
        }
      }
    }
    if (series <= 0 && epuisee != null) {
      _raison('koach.douleur_retrait', {
        'exercice': exId,
        'zone': epuisee,
        'cause': 'reprise_dose',
      });
      return null;
    }
    for (final z in tri) {
      if (budgetZone.containsKey(z)) {
        budgetZone[z] = budgetZone[z]! - series;
        if (echauffement && reserveEchauffement.containsKey(z)) {
          reserveEchauffement[z] = reserveEchauffement[z]! - series;
        }
      }
    }
    servi['sets'] = series;
    plans[item['slotId'] as String?] = plan;
    if (const ['charge', 'reps', 'tenue'].contains(typ) && !echauffement) {
      servi['setTargets'] = null;
    }
    return servi;
  }

  /// A6.2 : pendant `surmenage_jours` jours après une alerte de surmenage
  /// d'un mouvement principal, lignes − arrondi(lignes × `surmenage_coupe`)
  /// (au moins une, jamais la dernière), en semaine de charge seulement.
  num _surmenage(String exId, Memoire mm, Object? role, num series) {
    final c = dictOuVide(contexte);
    final a = mm.alerteJour;
    if (role != 'main' || a == null || series < 2) {
      return series;
    }
    if (!(0 < jour - a && jour - a <= _n('surmenage_jours'))) {
      return series;
    }
    if (verrouillee() || ou(c['intention'], c['genre']) == 'maintenance') {
      return series;
    }
    var retire = (series * dbl(s['surmenage_coupe']) + 0.5).floor();
    if (retire < 1) {
      retire = 1;
    }
    _raison('koach.surmenage', {
      'exercice': exId,
      'series': retire,
      'part': arrondi(mm.alertePart!, 3),
    });
    return series - retire;
  }

  // ------------------------------------------------------------------
  // Techniques (règle A9.2 de 0.3.1)
  // ------------------------------------------------------------------

  /// Technique au-dessus du niveau du profil : séries classiques
  /// équivalentes. Technique qui intensifie : non servie sur zone
  /// douloureuse ou en reprise, un jour de bilan au palier 2, en semaine
  /// verrouillée ; excentrique accentué non servi près d'une échéance ni
  /// sur zone fragile du profil.
  void _technique(Json servi, Json plan, Json cond) {
    final tech = dictOuVide(servi['technique']);
    final kind = tech['kind'];
    if (!vrai(kind) || kind == 'standard') {
      return;
    }
    final c = dictOuVide(contexte);
    String? cause;
    if (g.niveau <
        (_seGet(jm(s['technique_niveau_acces']), kind as String, 0) as num)) {
      cause = 'niveau';
    } else if (dans(kind, jl(s['techniques_intensives']))) {
      final jours = c['jours_avant_echeance'];
      if (cond['raison'] != null) {
        cause = 'douleur';
      } else if (palier >= 2) {
        cause = 'bilan';
      } else if (vrai(plan['verrou'])) {
        cause = 'phase';
      } else if (kind == 'accentuated_eccentric' &&
          jours != null &&
          (jours as num) <= _n('excentrique_echeance_j')) {
        cause = 'echeance';
      } else if (kind == 'accentuated_eccentric' && vrai(cond['fragile'])) {
        cause = 'antecedent';
      }
    }
    if (cause == null) {
      return;
    }
    if (cause == 'niveau') {
      equivalentStandard(servi);
    } else {
      servi['technique'] = null;
    }
    _raison('koach.technique_retenue', {
      'exercice': servi['exerciseId'],
      'technique': kind,
      'cause': cause,
    });
  }

  // ------------------------------------------------------------------
  // Retour gradué au volume
  // ------------------------------------------------------------------

  /// Crédits de la fiche sur les groupes majeurs : [(indice, séries
  /// créditées par série dure)], en demi-séries.
  List<(int, double)> _credits(String exId) {
    final n = jl(s['volume_groupes_majeurs']).length;
    final out = <(int, double)>[];
    for (final gw in listeOuVide(dictOuVide(fiches[exId])['groupes'])) {
      final i = jl(gw)[0] as num;
      final w = jl(gw)[1] as num;
      if (i < n) {
        final c = (w * 2 + 0.5).floor() / 2.0;
        if (c > 0) {
          out.add((i.toInt(), c));
        }
      }
    }
    return out;
  }

  /// Séries dures d'un item (`ItemView.hardSets` du banc).
  double _seriesDures(Json it) {
    final fiche = dictOuVide(fiches[it['exerciseId']]);
    if (!vrai(fiche['renforcement']) || it['kind'] == 'warmup') {
      return 0.0;
    }
    final f = it['targetFlames'];
    if (f != null && rirDeFlammes(f)! > _n('serie_dure_rir_max')) {
      return 0.0;
    }
    return dbl(ou(it['sets'], 0));
  }

  /// (famille, secondes par série) d'une tenue bras tendus de
  /// renforcement, sinon (null, 0).
  (String?, double) _tenueBrasTendus(Json it) {
    final fiche = dictOuVide(fiches[it['exerciseId']]);
    final fam = fiche['bras_tendus'];
    if (fam == null || !vrai(fiche['renforcement'])) {
      return (null, 0.0);
    }
    if (it['secondsLow'] == null && it['secondsHigh'] == null) {
      return (null, 0.0);
    }
    var sh = it['secondsHigh'];
    sh ??= it['secondsLow'];
    return (fam as String, dbl(ou(sh, 0)));
  }

  /// Ajoute au volume de la semaine [semaine] les séries dures créditées
  /// et les secondes bras tendus de [items].
  void _compter(int semaine, List<Json> items) {
    var v = volSemaines[semaine];
    if (v == null) {
      v = List<double>.filled(jl(s['volume_groupes_majeurs']).length, 0.0);
      volSemaines[semaine] = v;
    }
    final t = tenueSemaines.putIfAbsent(semaine, () => <String, double>{});
    for (final it in items) {
      final dures = _seriesDures(it);
      if (dures > 0) {
        duresSemaines[semaine] = (duresSemaines[semaine] ?? 0.0) + dures;
        for (final (gi, c) in _credits(it['exerciseId'] as String)) {
          v[gi] += dures * c;
        }
      }
      final (fam, sec) = _tenueBrasTendus(it);
      if (fam != null) {
        t[fam] = (t[fam] ?? 0.0) + dbl(ou(it['sets'], 0)) * sec;
      }
    }
  }

  /// `rampLimit` du banc : plus haute valeur admise en semaine [index] au
  /// vu des trois semaines précédentes.
  double _limiteRampe(
    List<bool> allegeesH,
    List<double> serie,
    int index,
    double hausse,
    double tolerance,
  ) {
    double pas(double ref) {
      final rel = ref * (1 + hausse);
      final ab = ref + tolerance;
      return rel > ab ? rel : ab;
    }

    var charge = 0.0;
    var legere = 0.0;
    var uneChargee = false;
    for (var k = index - 3; k < index; k++) {
      if (k < 0) {
        continue;
      }
      if (allegeesH[k]) {
        if (serie[k] > legere) {
          legere = serie[k];
        }
      } else {
        uneChargee = true;
        if (serie[k] > charge) {
          charge = serie[k];
        }
      }
    }
    if (uneChargee) {
      return pas(charge > legere ? charge : legere);
    }
    final reprise = legere / dbl(s['volume_reprise_part']);
    final pp = pas(legere);
    return pp > reprise ? pp : reprise;
  }

  /// (allégées, série) des semaines 0..[semaine].
  (List<bool>, List<double>) _historique(
    int semaine,
    double Function(int) valeur,
  ) {
    final allegeesH = [
      for (var k = 0; k < semaine + 1; k++) allegees[k] ?? false,
    ];
    final serie = [for (var k = 0; k < semaine + 1; k++) valeur(k)];
    return (allegeesH, serie);
  }

  /// Séries dures créditées admises au groupe [gi] en semaine [semaine].
  double _limiteVolume(int gi, int semaine) {
    final n = jl(s['volume_groupes_majeurs']).length;
    final (allegeesH, serie) = _historique(semaine, (k) {
      final v = volSemaines[k];
      final l = (v != null && v.isNotEmpty) ? v : List<double>.filled(n, 0.0);
      return l[gi];
    });
    final l1 = _limiteRampe(
      allegeesH,
      serie,
      semaine,
      dbl(s['volume_hausse']),
      dbl(s['volume_hausse_series']),
    );
    if (semaine > 1 &&
        !allegeesH[semaine] &&
        !allegeesH[semaine - 1] &&
        !allegeesH[semaine - 2] &&
        serie[semaine - 2] > 0) {
      final ref = serie[semaine - 2];
      final l2 = _seMax(
        ref * (1 + dbl(s['volume_hausse_2sem'])),
        ref + dbl(s['volume_hausse_2sem_series']),
      );
      if (l2 < l1) {
        return l2;
      }
    }
    return l1;
  }

  /// Secondes bras tendus admises à la famille [fam] en semaine [semaine] ;
  /// null sans tenue de la famille dans les trois semaines précédentes.
  double? _limiteTenue(String fam, int semaine) {
    final (allegeesH, serie) = _historique(
      semaine,
      (k) => tenueSemaines[k]?[fam] ?? 0.0,
    );
    var ref = 0.0;
    for (var k = semaine - 3; k < semaine; k++) {
      if (k >= 0 && serie[k] > ref) {
        ref = serie[k];
      }
    }
    if (ref <= 0) {
      return null;
    }
    return _limiteRampe(
      allegeesH,
      serie,
      semaine,
      jld(s['tenue_hausse_par_niveau'])[g.niveau],
      dbl(s['tenue_hausse_hebdo_s']),
    );
  }

  /// Rang de priorité du retour gradué par rôle d'emplacement (1.0.6, KM4) :
  /// 0 coupé d'abord, 1 ensuite (secondaire, technique), 2 en dernier
  /// (principal).
  static const Map<String, int> rangRole = {
    'main': 2,
    'secondary': 1,
    'skill': 1,
  };

  /// Données du retour gradué de la séance du jour (1.0.6) : limites et
  /// réalisé de la semaine par groupe majeur ; une semaine d'allègement,
  /// limite et réalisé des séries dures ; séances restantes (réparties par
  /// [_planRetour]) ; tenues bras tendus : budget = limite − fait − écrit
  /// restant. null la première semaine du programme ou du journal, ou sans
  /// semaine connue.
  BudgetsRetour? _budgetsRetour([List<Json> items = const []]) {
    final c = dictOuVide(contexte);
    final semO = c['semaine'];
    if (semO == null || (semO as num) < 1) {
      return null;
    }
    final sem = ent(semO);
    if (!allegees.keys.any((k) => k < sem) &&
        !volSemaines.keys.any((k) => k < sem)) {
      // Première semaine du journal : pas de limite.
      return null;
    }
    final n = jl(s['volume_groupes_majeurs']).length;
    final reste = <List<Json>>[];
    final reserveT = <String, double>{};
    var ecritReste = 0.0;
    for (final seance in listeOuVide(c['reste_semaine'])) {
      final rT = <String, double>{};
      final items0 = <Json>[];
      for (final x in jl(seance)) {
        final it = jm(x);
        items0.add(it);
        ecritReste += _seriesDures(it);
        final (fam, sec) = _tenueBrasTendus(it);
        if (fam != null) {
          rT[fam] = (rT[fam] ?? 0.0) + dbl(ou(it['sets'], 0)) * sec;
        }
      }
      for (final fam in rT.keys.toList()..sort()) {
        reserveT[fam] = (reserveT[fam] ?? 0.0) + rT[fam]!;
      }
      reste.add(items0);
    }
    final faitV = volSemaines[sem];
    final fait = (faitV != null && faitV.isNotEmpty)
        ? List<double>.of(faitV)
        : List<double>.filled(n, 0.0);
    final faitT = tenueSemaines[sem] ?? <String, double>{};
    final limites = [for (var gi = 0; gi < n; gi++) _limiteVolume(gi, sem)];
    final limitesT = <String, double?>{};
    final budgetsT = <String, double?>{};
    for (final fam in famillesBrasTendus) {
      final lim = _limiteTenue(fam, sem);
      limitesT[fam] = lim;
      budgetsT[fam] = lim == null
          ? null
          : lim - (faitT[fam] ?? 0.0) - (reserveT[fam] ?? 0.0);
    }
    // Allègement : une semaine allégée par nature, ou dont l'écrit est un
    // allègement au vu de l'écrit des trois semaines précédentes, reste un
    // allègement au vu du servi.
    final part = dbl(s['decharge_part']);
    final legere = allegees[sem] ?? false;
    final ecrit =
        (ecritSemaines[sem] ?? 0.0) +
        somme([for (final it in items) _seriesDures(it)]) +
        ecritReste;
    final refE = _seMaxListe([
      for (var k = sem - 3; k < sem; k++)
        if (k >= 0) ecritSemaines[k] ?? 0.0,
    ]);
    final allegement = refE > 0 ? (ecrit <= part * refE + 1e-9) : legere;
    double? limiteD;
    double? faitD;
    if (allegement || legere) {
      final refS = _seMaxListe([
        for (var k = sem - 3; k < sem; k++)
          if (k >= 0) duresSemaines[k] ?? 0.0,
      ]);
      if (refS > 0) {
        limiteD = part * refS;
        faitD = duresSemaines[sem] ?? 0.0;
      }
    }
    return BudgetsRetour(
      limites: limites,
      fait: fait,
      limiteDures: limiteD,
      faitDures: faitD,
      reste: reste,
      limitesTenue: limitesT,
      budgetsTenue: budgetsT,
      jourTenue: <String, double>{},
    );
  }

  /// Vrai si la conduite sous douleur tient l'exercice aujourd'hui (raison
  /// de douleur notée par `conduite`, ou zone sensible sous la rampe du
  /// réalisé qu'il provoque, hors rampe de retour après une coupure).
  bool _douleurUnite(String exId, Json? plan) {
    final cond = dictOuVide(dictOuVide(plan)['cond']);
    if (cond['zone'] != null) {
      return true;
    }
    final zz = zonesEx[exId];
    if (zz != null) {
      for (final z in zz.$2.toList()..sort()) {
        if (budgetZone.containsKey(z) && !retourZone.containsKey(z)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Plan du retour gradué au volume de la semaine (1.0.6, KM4 ;
  /// `_plan_retour`) : lignes = groupes majeurs (et total d'une semaine
  /// d'allègement), unités = lignes dures du jour ([paires] : écrit, servi
  /// par `_item`) et des séances restantes ; coupes une série à la fois par
  /// étapes (rang 0 à 0, rang 1 à 1, principaux au plancher, rang 1 à 0,
  /// principaux à 1), l'unité qui garde la plus grande part de son écrit
  /// d'abord, à égalité la plus tardive ; répartie sur la semaine sans
  /// séance manquée dans les `retour_repartition_semaines` dernières
  /// semaines, sinon la séance du jour d'abord.
  void _planRetour(List<(Json, Json)> paires) {
    final rv = retourVol;
    if (rv == null) {
      return;
    }
    final n = jl(s['volume_groupes_majeurs']).length;
    final total = rv.limiteDures != null;
    final exces = <double>[
      for (var gi = 0; gi < n; gi++) rv.fait[gi] - rv.limites[gi],
    ];
    if (total) {
      exces.add(rv.faitDures! - rv.limiteDures!);
    }
    final part = dbl(s['retour_plancher_principal']);
    final unites = <_UniteRetour>[];

    bool ajouter(
      int seance,
      int pos,
      String? slot,
      String exId,
      int series,
      int ecrites,
      Object? role,
      bool douleur,
      bool premier,
    ) {
      final poids = <(int, double)>[..._credits(exId)];
      if (total) {
        poids.add((n, 1.0));
      }
      if (poids.isEmpty) {
        return false;
      }
      int rang;
      if (role == null) {
        // Sans rôle : la première ligne dure de la séance du jour est le
        // principal, les autres de rang 0 ; une ligne d'une séance restante
        // sans rôle n'est pas coupée d'avance (rang 3, écrit réservé).
        if (seance > 0) {
          rang = 3;
        } else {
          rang = premier ? 2 : 0;
        }
      } else {
        rang = rangRole[role] ?? 0;
      }
      if (rang == 2 && douleur) {
        rang = 1;
      }
      var plancher = 0;
      if (rang == 2) {
        plancher = (ecrites * part - 1e-9).ceil();
        if (plancher < 1) {
          plancher = 1;
        }
        if (plancher > series) {
          plancher = series;
        }
      }
      for (final (r, w) in poids) {
        exces[r] += w * series;
      }
      unites.add(_UniteRetour(seance, pos, slot, series, poids, rang, plancher));
      return true;
    }

    var pos = 0;
    var premier = true;
    for (final (item, servi) in paires) {
      final series = ent(ou(servi['sets'], 0));
      if (series <= 0 || _seriesDures(servi) <= 0) {
        continue;
      }
      final plan = plans[item['slotId']];
      final exId = item['exerciseId'] as String;
      if (ajouter(
        0,
        pos,
        item['slotId'] as String?,
        exId,
        series,
        ent(ou(item['sets'], 0)),
        plan?['role'],
        _douleurUnite(exId, plan),
        premier,
      )) {
        premier = false;
      }
      pos += 1;
    }
    for (var k = 0; k < rv.reste.length; k++) {
      pos = 0;
      premier = true;
      for (final p0 in rv.reste[k]) {
        final series = ent(ou(p0['sets'], 0));
        if (series <= 0 || _seriesDures(p0) <= 0) {
          continue;
        }
        if (ajouter(
          k + 1,
          pos,
          p0['slotId'] as String?,
          p0['exerciseId'] as String,
          series,
          series,
          p0['role'],
          false,
          premier,
        )) {
          premier = false;
        }
        pos += 1;
      }
    }
    final initial = List<double>.of(exces);
    final sem = ent(dictOuVide(contexte)['semaine']);
    final fenetre = ent(s['retour_repartition_semaines']);
    var repartie = true;
    for (var w = sem - fenetre + 1; w < sem + 1; w++) {
      if (semainesManquees.contains(w)) {
        repartie = false;
      }
    }
    rv.repartie = repartie;

    void couper(String portee, int rang, int Function(_UniteRetour) plancherDe) {
      while (true) {
        if (!exces.any((x) => x > 1e-9)) {
          return;
        }
        _UniteRetour? best;
        var bf = 0.0;
        for (final u in unites) {
          if ((portee == 'jour' && u.seance != 0) ||
              (portee == 'reste' && u.seance == 0)) {
            continue;
          }
          if (u.rang != rang || u.m <= plancherDe(u)) {
            continue;
          }
          var utile = false;
          for (final (r, _) in u.poids) {
            if (exces[r] > 1e-9) {
              utile = true;
              break;
            }
          }
          if (!utile) {
            continue;
          }
          final f = u.m / u.n;
          if (best == null ||
              f > bf ||
              (f == bf &&
                  (u.seance > best.seance ||
                      (u.seance == best.seance && u.pos > best.pos)))) {
            best = u;
            bf = f;
          }
        }
        if (best == null) {
          return;
        }
        best.m -= 1;
        for (final (r, w) in best.poids) {
          exces[r] -= w;
        }
      }
    }

    int zero(_UniteRetour u) => 0;
    int un(_UniteRetour u) => 1;
    int plancher(_UniteRetour u) => u.plancher;
    final etapes = <(int, int Function(_UniteRetour))>[
      (0, zero),
      (1, un),
      (2, plancher),
      (1, zero),
      (2, un),
    ];
    if (repartie) {
      for (final (rang, f) in etapes) {
        couper('tous', rang, f);
      }
    } else {
      for (final (rang, f) in etapes.sublist(0, 3)) {
        couper('jour', rang, f);
      }
      for (final (rang, f) in etapes.sublist(0, 3)) {
        couper('reste', rang, f);
      }
      for (final (rang, f) in etapes.sublist(3)) {
        couper('jour', rang, f);
        couper('reste', rang, f);
      }
    }
    rv.depasse = [
      for (var r = 0; r < exces.length; r++)
        if (exces[r] > 1e-9) r,
    ];
    for (final u in unites) {
      if (u.seance != 0) {
        continue;
      }
      rv.plan[u.slot] = u.m;
      if (u.m < u.n) {
        int? cause;
        for (final (r, _) in u.poids) {
          if (initial[r] > 1e-9 &&
              (cause == null || initial[r] > initial[cause])) {
            cause = r;
          }
        }
        rv.cause[u.slot] = cause == n ? ('total', null) : ('groupe', cause);
      }
    }
  }

  /// Retour gradué au volume : séries de l'item ramenées à celles que le
  /// plan de la semaine lui laisse ([_planRetour]), puis à ce que sa famille
  /// de tenue bras tendus permet encore. Zéro série : item retiré (jamais un
  /// principal sans douleur par le plan). Raison `koach.retour_gradue`.
  /// Renvoie l'item ou null.
  Json? _retourGradue(Json servi) {
    final rv = retourVol;
    if (rv == null) {
      return servi;
    }
    final series = ent(ou(servi['sets'], 0));
    if (series <= 0) {
      return servi;
    }
    var maxi = series;
    (String, Object?)? cause;
    final pl = rv.plan[servi['slotId']];
    if (pl != null && pl < maxi) {
      maxi = pl;
      cause = rv.cause[servi['slotId']];
    }
    var (fam, sec) = _tenueBrasTendus(servi);
    if (fam != null && (rv.budgetsTenue[fam] == null || sec <= 0)) {
      fam = null;
    }
    int? secondes;
    if (fam != null && maxi > 0) {
      final resteT = rv.budgetsTenue[fam]! - (rv.jourTenue[fam] ?? 0.0);
      if (maxi * sec > resteT + 1e-9) {
        // Tenues trop longues pour la semaine : mêmes séries, tenues
        // raccourcies (5 s au moins) ; sinon une série de moins, et ainsi
        // de suite.
        cause = ('famille', fam);
        var trouve = 0;
        for (var k = maxi; k > 0; k--) {
          var h = (resteT / k + 1e-9).floor();
          if (h > sec) {
            h = sec.truncate();
          }
          if (h >= tenueMinS) {
            trouve = k;
            if (h < sec) {
              secondes = h;
            }
            break;
          }
        }
        maxi = trouve;
      }
    }
    if (maxi >= series && secondes == null) {
      if (fam != null) {
        rv.jourTenue[fam] = (rv.jourTenue[fam] ?? 0.0) + series * sec;
      }
      return servi;
    }
    final cz = cause!;
    String groupe;
    double? limite;
    if (cz.$1 == 'groupe') {
      final gi = cz.$2 as int;
      groupe = jl(s['volume_groupes_majeurs'])[gi] as String;
      limite = rv.limites[gi];
    } else if (cz.$1 == 'total') {
      groupe = 'allegement';
      limite = rv.limiteDures;
    } else {
      final f = cz.$2 as String;
      groupe = 'bras_tendus_$f';
      limite = rv.limitesTenue[f];
    }
    final planItem = plans[servi['slotId']];
    final ecritItem = planItem == null
        ? servi
        : (planItem['ecrit'] as Json?) ?? servi;
    _raison('koach.retour_gradue', {
      'exercice': servi['exerciseId'],
      'groupe': groupe,
      'limite': arrondi(limite!, 1),
      'series': maxi,
      'secondes': secondes,
      'ecrites': ent(ou(ecritItem['sets'], 0)),
      'douleur': _douleurUnite(servi['exerciseId'] as String, planItem),
    });
    if (maxi <= 0) {
      return null;
    }
    servi['sets'] = maxi;
    if (vrai(servi['setTargets'])) {
      final st = jl(servi['setTargets']);
      servi['setTargets'] = st.sublist(0, math.min(maxi, st.length));
    }
    if (secondes != null) {
      servi['secondsHigh'] = secondes;
      if (servi['secondsLow'] != null &&
          (servi['secondsLow'] as num) > secondes) {
        servi['secondsLow'] = secondes;
      }
      sec = secondes.toDouble();
    }
    if (fam != null) {
      rv.jourTenue[fam] = (rv.jourTenue[fam] ?? 0.0) + maxi * sec;
    }
    return servi;
  }

  /// Fin de séance : volume réellement servi ajouté à la semaine.
  void _fermerVolume(List<Object?> sets) {
    final semO = dictOuVide(contexte)['semaine'];
    if (semO == null) {
      return;
    }
    final sem = ent(semO);
    final faites = <Object?, int>{};
    final dures = <Object?, int>{};
    for (final x0 in sets) {
      final x = jm(x0);
      if (vrai(x['nonModelise']) || x['enduranceKind'] != null) {
        continue;
      }
      final k = x['slotId'];
      faites[k] = (faites[k] ?? 0) + 1;
      final f = x['flames'];
      if (f != null && (f as num) < 3 && !vrai(x['failed'])) {
        continue;
      }
      dures[k] = (dures[k] ?? 0) + 1;
    }
    final sv = servis;
    if (sv == null) {
      // Séance sans prescription de Koach : les séries faites, telles
      // quelles.
      final parSlot = <(Object?, Object?), Json>{};
      final ordre = <(Object?, Object?)>[];
      for (final x0 in sets) {
        final x = jm(x0);
        final k = (x['slotId'], x['exerciseId']);
        if (!parSlot.containsKey(k)) {
          ordre.add(k);
          final cible = dictOuVide(x['target']);
          parSlot[k] = <String, Object?>{
            'slotId': k.$1,
            'exerciseId': k.$2,
            'sets': 0,
            'kind': x['kind'],
            'targetFlames': cible['flames'],
            'secondsHigh': x['seconds'] != null ? cible['secondsHigh'] : null,
          };
        }
        final ps = parSlot[k]!;
        ps['sets'] = (ps['sets'] as int) + 1;
      }
      _compter(sem, [for (final k in ordre) parSlot[k]!]);
      return;
    }
    final items = <Json>[];
    for (final pp in sv) {
      final q = Map<String, Object?>.of(pp);
      final slot = pp['slotId'];
      if (pp['koach'] == 'vrai_test') {
        q['sets'] = dures[slot] ?? 0;
      } else if (vrai(q['sets']) && q['kind'] != 'warmup') {
        final n = faites[slot];
        if (n != null && n < (q['sets'] as num)) {
          q['sets'] = n;
        }
      }
      items.add(q);
    }
    _compter(sem, items);
  }

  /// Durée estimée d'un item en secondes (`ItemView.estimatedSeconds`).
  double _dureeItem(Json it, double vitesse) {
    final fiche = dictOuVide(fiches[it['exerciseId']]);
    final renfo = vrai(fiche['renforcement']);
    final cotes = _seGet(fiche, 'lateralite', 'bilateral') == 'bilateral'
        ? 1
        : 2;
    final n = ent(ou(it['sets'], 0));
    double effort;
    if (it['repsLow'] != null || it['repsHigh'] != null) {
      final rh = it['repsHigh'] ?? it['repsLow'];
      effort = (ou(rh, 0) as num) * 3.0 * cotes;
    } else if (it['secondsLow'] != null || it['secondsHigh'] != null) {
      final sh = it['secondsHigh'] ?? it['secondsLow'];
      effort = dbl(ou(sh, 0)) * (renfo ? cotes : 1);
    } else if (it['distanceMeters'] != null) {
      effort = dbl(it['distanceMeters']) / vitesse;
    } else if (it['calories'] != null) {
      effort = dbl(it['calories']) * 6;
    } else {
      effort = 30.0;
    }
    final restO = it['restSeconds'];
    final rest = dbl(restO ?? 60);
    return 45.0 + n.toDouble() * effort + (n - 1).toDouble() * rest;
  }

  /// Durée estimée d'une séance en minutes (5 min d'échauffement général
  /// dès qu'un exercice de renforcement).
  double _dureeSeance(List<Json> items, double vitesse) {
    var t = 0.0;
    var renfo = false;
    for (final it in items) {
      t += _dureeItem(it, vitesse);
      renfo =
          renfo || vrai(dictOuVide(fiches[it['exerciseId']])['renforcement']);
    }
    return (t + (renfo ? 300 : 0)) / 60.0;
  }

  /// Séance d'épreuve : un contre-la-montre servi comme test et noté
  /// `event_day`.
  static bool _jourEpreuve(List<Json> items) {
    for (final it in items) {
      if (it['kind'] == 'test' &&
          dictOuVide(it['test'])['kind'] == 'time_trial' &&
          listeOuVide(
            it['reasons'],
          ).any((r) => dictOuVide(jm(r)['params'])['note'] == 'event_day')) {
        return true;
      }
    }
    return false;
  }

  /// Durée de la séance servie bornée (critère `seance_trop_longue`).
  /// Raison `koach.seance_bornee`.
  List<Json> _dureeBornee(List<Json> out0, List<Json> items) {
    final budget = dictOuVide(contexte)['budget'];
    if (budget == null || out0.isEmpty || _jourEpreuve(out0)) {
      return out0;
    }
    // Durée d'une course : la plus lente des deux vitesses, celle du
    // journal et celle du profil.
    var vitesse = _vitesse();
    final lente = dbl(ou(m.profil['allure_course'], s['duree_vitesse_defaut']));
    if (lente < vitesse) {
      vitesse = lente;
    }
    final admis =
        dbl(budget) * dbl(s['seance_tolerance']) +
        dbl(s['seance_tolerance_min']);
    final ecrit = _dureeSeance(items, vitesse);
    double limite;
    if (ecrit <= admis || _jourEpreuve(items)) {
      // Marge d'arrondi : le banc compare sans tolérance.
      limite = admis - 1e-6;
    } else {
      limite = ecrit;
    }
    final out = List<Json>.of(out0);
    final notes = <Json>[];
    var garde = 0;
    while (_dureeSeance(out, vitesse) > limite && garde < 200) {
      garde += 1;
      final exces = (_dureeSeance(out, vitesse) - limite) * 60.0;
      final endurance = [
        for (final it in out)
          if (it['kind'] != 'warmup' &&
              it['koach'] != 'vrai_test' &&
              const [
                'course',
                'cardio',
                'conditionnement',
              ].contains(_nature(it['exerciseId'] as String)))
            it,
      ];
      Json it;
      if (endurance.isNotEmpty) {
        // max(endurance, key=(durée, -indice)) : le premier des maximaux.
        Json? meilleur;
        var dMax = 0.0;
        var iMax = 0;
        for (final x in endurance) {
          final d = _dureeItem(x, vitesse);
          final i = -_seIndex(out, x);
          if (meilleur == null || d > dMax || (d == dMax && i > iMax)) {
            meilleur = x;
            dMax = d;
            iMax = i;
          }
        }
        it = meilleur!;
      } else {
        final renfo = [
          for (final x in out)
            if (!const ['warmup', 'test'].contains(x['kind']) &&
                x['koach'] != 'vrai_test')
              x,
        ];
        if (renfo.isEmpty) {
          break;
        }
        it = renfo.last;
      }
      final n = ent(ou(it['sets'], 0));
      if (n > 1) {
        it['sets'] = n - 1;
        if (vrai(it['setTargets'])) {
          final st = jl(it['setTargets']);
          it['setTargets'] = st.sublist(0, math.min(n - 1, st.length));
        }
      } else if (endurance.isNotEmpty &&
          (it['distanceMeters'] != null ||
              it['secondsHigh'] != null ||
              it['secondsLow'] != null)) {
        final effort = _dureeItem(it, vitesse) - 45.0 - exces;
        final unite = effort >= 300 ? 60 : 5;
        final sec = (effort / unite + 1e-9).floor() * unite;
        if (sec < 5) {
          _seRetirer(out, it);
        } else {
          final secLo =
              (it['secondsLow'] == null || (it['secondsLow'] as num) > sec)
              ? sec
              : it['secondsLow'];
          it.addAll(<String, Object?>{
            'distanceMeters': null,
            'secondsHigh': sec,
            'secondsLow': secLo,
            'setTargets': null,
          });
        }
      } else {
        _seRetirer(out, it);
      }
      if (!_seContientId(notes, it)) {
        notes.add(it);
        _raison('koach.seance_bornee', {
          'exercice': it['exerciseId'],
          'minutes': arrondi(limite, 2),
        });
      }
    }
    return out;
  }

  // ------------------------------------------------------------------
  // Endurance et conditionnement (règles A2.3 et A10 de 0.3.1)
  // ------------------------------------------------------------------

  /// Nature d'un exercice non modélisé : 'course', 'cardio',
  /// 'conditionnement', 'mobilite' ; null pour un exercice modélisé.
  String? _nature(String exId) {
    final fiche = dictOuVide(fiches[exId]);
    final typ = fiche['type'];
    if (typ == 'cardio') {
      if (!exId.startsWith('ca-marche') &&
          !exId.startsWith('ca-educatif') &&
          listeOuVide(
            fiche['materiel'],
          ).any((mt) => dans(mt, jl(s['endurance_materiel_course'])))) {
        return 'course';
      }
      return 'cardio';
    }
    if (typ == 'wod') {
      return 'conditionnement';
    }
    if (typ == 'mobilite') {
      return 'mobilite';
    }
    return null;
  }

  /// Vitesse de course (m/s) : celle des courses du journal qui disent
  /// distance et durée, sinon `endurance_vitesse`.
  double _vitesse() {
    if (courseSecondes > 0) {
      return courseMetres / courseSecondes;
    }
    return dbl(s['endurance_vitesse']);
  }

  /// Séance de course de qualité (`isQualityRun`).
  bool _qualite(Json item) {
    final f = item['targetFlames'];
    if (f != null &&
        rirDeFlammes(f)! <= dbl(s['endurance_qualite_rir']) + 1e-9) {
      return true;
    }
    if (item['intensity'] != null || item['kind'] == 'test') {
      return true;
    }
    final id = item['exerciseId'] as String;
    return jl(s['endurance_qualite_ids']).any((q) => id.contains(q as String));
  }

  /// Une course des `endurance_dure_jours` jours d'avant notée trop dure
  /// (`recentRunTooHard`).
  bool _courseTropDure() {
    for (final (j, _, f, t) in courses) {
      if (j >= jour || j < jour - _n('endurance_dure_jours') || f == null) {
        continue;
      }
      if (t != null
          ? (f - t >= _n('endurance_dure_marge'))
          : (f >= _n('endurance_dure_flammes') + 1)) {
        return true;
      }
    }
    return false;
  }

  /// Jours durs de conditionnement de suite juste avant aujourd'hui
  /// (`conditioningStreak`).
  int _serieWod() {
    final durs = Set<int>.of(joursDurs);
    final actifs = Set<int>.of(joursActifs);
    var n = 0;
    var d = jour - 1;
    var trou = 0;
    while (d >= jour - _n('wod_fenetre_j')) {
      if (durs.contains(d)) {
        n += 1;
        trou = 0;
      } else if (!actifs.contains(d)) {
        trou += 1;
      } else {
        break;
      }
      if (trou > 1) {
        break;
      }
      d -= 1;
    }
    return n;
  }

  /// Conduite des lignes d'endurance de la séance servie
  /// (`_enduranceDay`) : jamais plus long, plus loin, plus de répétitions
  /// ni plus dur que l'écrit. Renvoie les items servis (lignes retirées
  /// enlevées).
  List<Json> _endurance(List<Json> out) {
    final c = dictOuVide(contexte);
    final natures = <(Json, String)>[];
    for (final it in out) {
      final n = _nature(it['exerciseId'] as String);
      if (n != null) {
        natures.add((it, n));
      }
    }
    if (natures.isEmpty && !joursCourseDure.contains(jour - 1)) {
      return out;
    }
    final retires = <Json>[];
    final vitesse = _vitesse();
    final facileF = flammesDeRir(dbl(s['endurance_facile_rir']));

    void retirer(Json it, String code, Json raison) {
      retires.add(it);
      _raison(code, <String, Object?>{'exercice': it['exerciseId'], ...raison});
    }

    // 0. A2.3 : douleur qui dure au bas du corps, la course est retirée
    // tant que l'arrêt tient.
    final arretsJ = g.arretsJambe();
    if (arretsJ.isNotEmpty) {
      for (final (it, n) in natures) {
        if (n == 'course') {
          retirer(it, 'koach.douleur_retrait', {
            'zone': arretsJ[0],
            'cause': 'douleur_arret',
          });
        }
      }
    }
    final retourJambe = g.repriseJambe();
    // 1. A10.1 : reprise après une coupure.
    final er = jl(s['endurance_reprise']);
    final courtJ = jl(er[0])[0] as num;
    final courtP = dbl(jl(er[0])[1]);
    final longJ = jl(er[1])[0] as num;
    final longP = dbl(jl(er[1])[1]);
    final actif = joursActifs.isNotEmpty ? joursActifs.last : null;
    final ecart = actif == null ? 0 : jour - actif;
    final reprise = ecart >= longJ ? longP : (ecart >= courtJ ? courtP : 1.0);
    final causeReprise =
        'reprise_${(ecart >= longJ ? longJ : courtJ).truncate()}';
    // 2. A10.2 : jour sans.
    String? sans;
    if (palier >= 2) {
      sans = 'bilan_fort';
    } else if (palier >= 1) {
      sans = 'bilan';
    } else if (g.douleurJambe() >= _n('endurance_douleur_jambe')) {
      sans = 'douleur_jambe';
    } else if (_courseTropDure()) {
      sans = 'course_dure';
    } else {
      sans = null;
    }
    final pris = <Object?>[for (final it in out) it['exerciseId']];
    for (final (it, n) in natures) {
      if (_seContientId(retires, it) ||
          n == 'mobilite' ||
          it['kind'] == 'warmup') {
        continue;
      }
      final part = (retourJambe && n == 'course')
          ? _seMin(reprise, longP)
          : reprise;
      if (part < 1 && reduire(it, part)) {
        _raison('koach.endurance_raccourcie', {
          'exercice': it['exerciseId'],
          'cause': part < reprise
              ? 'reprise_${longJ.truncate()}'
              : causeReprise,
          'part': _seArrondi(part * 100),
        });
      }
      if (sans == null) {
        continue;
      }
      if (n == 'course' && _qualite(it)) {
        // Qualité → course facile de la durée de travail écrite ; sans
        // course facile faisable, la séance est retirée.
        final travail = secondesPrescrites(it, _seGet(it, 'sets', 0), vitesse);
        final fiche = dictOuVide(fiches[it['exerciseId']]);
        final cf = jm(s['endurance_course_facile']);
        final facile =
            (dans('tapis de course', listeOuVide(fiche['materiel']))
                    ? cf['tapis']
                    : cf['defaut'])
                as String;
        final ff = fiches[facile];
        // Faisable : son matériel est celui de la séance écrite, lieu du
        // jour compris.
        final faisable =
            ff != null &&
            listeOuVide(
              ff['materiel'],
            ).every((mt) => dans(mt, listeOuVide(fiche['materiel']))) &&
            (c['lieu'] == null || dans(c['lieu'], listeOuVide(ff['lieux']))) &&
            travail >= _n('endurance_facile_min_s') &&
            !pris.contains(facile);
        if (faisable) {
          var minutes = _seDivPlancherD(travail, 60).truncate();
          if (minutes < 1) {
            minutes = 1;
          }
          final f = it['targetFlames'];
          pris.add(facile);
          final ancien = it['exerciseId'];
          it.addAll(<String, Object?>{
            'exerciseId': facile,
            'sets': 1,
            'repsLow': null,
            'repsHigh': null,
            'distanceMeters': null,
            'calories': null,
            'secondsLow': minutes * 60,
            'secondsHigh': minutes * 60,
            'targetFlames': (f == null || (f as num) > facileF) ? facileF : f,
            'intensity': null,
            'setTargets': null,
            'restSeconds': null,
            'autoregulation': null,
            'groupId': null,
            'kind': it['kind'] == 'test' ? 'work' : it['kind'],
            'test': null,
          });
          _raison('koach.course_facile', {
            'exercice': ancien,
            'remplacant': facile,
            'cause': sans,
          });
        } else {
          retirer(it, 'koach.endurance_retrait', {'cause': sans});
          continue;
        }
      }
      if (palier >= 2 &&
          (n == 'course' || n == 'cardio') &&
          reduire(it, dbl(s['endurance_mauvais_jour']))) {
        _raison('koach.endurance_raccourcie', {
          'exercice': it['exerciseId'],
          'cause': sans,
          'part': _seArrondi(dbl(s['endurance_mauvais_jour']) * 100),
        });
      }
    }
    // 3. A10.3 : course du jour bornée à la plus longue course des
    // `endurance_pic_jours` derniers jours + `endurance_pic`.
    var plusLongue = 0.0;
    var compte = 0;
    for (final (j, sec, _, _) in courses) {
      if (j < jour && j >= jour - _n('endurance_pic_jours')) {
        compte += 1;
        if (sec > plusLongue) {
          plusLongue = sec;
        }
      }
    }
    final lignesCourse = [
      for (final (it, n) in natures)
        if (n == 'course' &&
            !_seContientId(retires, it) &&
            it['kind'] != 'warmup')
          it,
    ];

    double total() => somme([
      for (final it in lignesCourse)
        secondesPrescrites(it, _seGet(it, 'sets', 0), vitesse),
    ]);

    if (compte >= _n('endurance_pic_courses_min') && plusLongue > 0) {
      final plafondC = plusLongue * (1 + dbl(s['endurance_pic']));
      final avant = total();
      if (avant > plafondC + 1e-6) {
        final facteur = plafondC / avant;
        for (final it in lignesCourse) {
          var change = false;
          if (it['kind'] == 'test') {
            // Test plus long que la borne : course bornée à effort modéré,
            // test reporté.
            final f = it['targetFlames'];
            it.addAll(<String, Object?>{
              'kind': 'work',
              'test': null,
              'intensity': null,
              'setTargets': null,
              'targetFlames': f == null
                  ? null
                  : _seMin<num>(f as num, facileF + 1),
            });
            change = true;
          }
          if (reduire(it, facteur) || change) {
            _raison('koach.course_bornee', {
              'exercice': it['exerciseId'],
              'part': _seArrondi(dbl(s['endurance_pic']) * 100),
            });
          }
        }
        var garde = 0;
        while (total() > plafondC + 1e-6 && garde < 50) {
          garde += 1;
          Json? longIt;
          for (final it in lignesCourse) {
            if (longIt == null ||
                secondesPrescrites(it, _seGet(it, 'sets', 0), vitesse) >
                    secondesPrescrites(
                      longIt,
                      _seGet(longIt, 'sets', 0),
                      vitesse,
                    )) {
              longIt = it;
            }
          }
          if (longIt == null) {
            break;
          }
          if ((_seGet(longIt, 'sets', 0) as num) > 1) {
            longIt['sets'] = (longIt['sets'] as num) - 1;
          } else {
            final essai = Map<String, Object?>.of(longIt);
            if (!reduire(essai, dbl(s['endurance_bornee_reduction'])) ||
                secondesPrescrites(essai, 1, vitesse) >=
                    secondesPrescrites(longIt, 1, vitesse)) {
              break;
            }
            longIt.clear();
            longIt.addAll(essai);
          }
        }
      }
    }
    // 4. A10.4 : conditionnement mis à l'échelle.
    final String? causeWod = (sans != null && sans != 'course_dure')
        ? sans
        : (_serieWod() >= _n('wod_jours_durs') ? 'jours_durs' : null);
    if (causeWod != null) {
      for (final (it, n) in natures) {
        if (n != 'conditionnement' ||
            _seContientId(retires, it) ||
            it['kind'] == 'warmup') {
          continue;
        }
        if (!reduire(it, dbl(s['wod_echelle']))) {
          continue;
        }
        final f = it['targetFlames'];
        if (f != null && (f as num) > facileF + 1) {
          it['targetFlames'] = f - 1;
        }
        _raison('koach.wod_echelle', {
          'exercice': it['exerciseId'],
          'cause': causeWod,
          'part': _seArrondi(dbl(s['wod_echelle']) * 100),
        });
      }
    }
    // 5. A10.5 : course dure la veille, une flamme de moins sur le bas du
    // corps modélisé.
    if (joursCourseDure.contains(jour - 1)) {
      for (final it in out) {
        final fiche = dictOuVide(fiches[it['exerciseId']]);
        final f = it['targetFlames'];
        if (_seContientId(retires, it) ||
            !const ['charge', 'reps', 'tenue'].contains(fiche['type']) ||
            !vrai(fiche['bas']) ||
            const ['test', 'warmup'].contains(it['kind']) ||
            f == null ||
            (f as num) <= 1) {
          continue;
        }
        it['targetFlames'] = f - 1;
        _raison('koach.fatigue_croisee', {
          'exercice': it['exerciseId'],
          'cause': 'course_dure',
        });
      }
    }
    if (retires.isEmpty) {
      return out;
    }
    return [
      for (final it in out)
        if (!_seContientId(retires, it)) it,
    ];
  }

  // ------------------------------------------------------------------
  // Série suivante
  // ------------------------------------------------------------------
  double rirCible(Json item, Json plan) {
    final f = item['targetFlames'];
    var rir = f == null ? 2.5 : rirDeFlammes(f)!;
    rir += dbl(plan['rir_bonus']);
    if (plan['rir_min'] != null && rir < dbl(plan['rir_min'])) {
      rir = dbl(plan['rir_min']);
    }
    if (rir > 5) {
      rir = 5.0;
    }
    return rir;
  }

  /// Cible de la série [index] de l'item servi : dictionnaire {repsLow,
  /// repsHigh, secondsLow, secondsHigh, loadKg, flames, role} ou null pour
  /// arrêter l'exercice.
  Json? cible(Json item, int index, List<Object?> faites) {
    final plan = plans[item['slotId']];
    if (plan == null) {
      return _ecrit(item, index);
    }
    final typ = plan['type'];
    if (item['kind'] == 'warmup' ||
        !const ['charge', 'reps', 'tenue'].contains(typ)) {
      return _ecrit(item, index);
    }
    if ((plan['echecs'] as int) >= _n('echecs_arret') && !vrai(plan['test'])) {
      _raison('koach.arret_exercice', {
        'exercice': item['exerciseId'],
        'cause': 'echecs',
      });
      return null;
    }
    if (vrai(plan['test'])) {
      return _cibleTest(item, index, plan);
    }
    if (plan['slot_test'] != null) {
      // Après une montée de test : séries dures de la montée + séries de
      // travail ne dépassent jamais les séries écrites de la ligne.
      final durs =
          _seGet(dictOuVide(plans[plan['slot_test']]), 'durs', 0) as num;
      if (index >= 1 && durs + index >= (plan['series_ecrites'] as num)) {
        _raison('koach.arret_exercice', {
          'exercice': item['exerciseId'],
          'cause': 'volume_test',
        });
        return null;
      }
    }
    if (typ == 'charge') {
      return _cibleCharge(item, index, plan);
    }
    if (typ == 'reps') {
      return _cibleReps(item, index, plan);
    }
    return _cibleTenue(item, index, plan);
  }

  Json _ecrit(Json item, int index) => <String, Object?>{
    'repsLow': item['repsLow'],
    'repsHigh': item['repsHigh'],
    'secondsLow': item['secondsLow'],
    'secondsHigh': item['secondsHigh'],
    'loadKg': item['startLoadKg'],
    'flames': item['targetFlames'],
    'role': null,
  };

  /// Plage de répétitions de la série [index] (technique série de tête :
  /// les séries suivantes prennent la plage des séries allégées).
  (num?, num?) _plages(Json item, int index) {
    var lo = item['repsLow'];
    var hi = item['repsHigh'];
    final tech = dictOuVide(item['technique']);
    if (tech['kind'] == 'top_set_backoff' && index >= 1) {
      lo = ou(tech['backoffRepsLow'], lo);
      hi = ou(tech['backoffRepsHigh'], hi);
    }
    lo ??= hi;
    hi ??= lo;
    return (lo as num?, hi as num?);
  }

  /// Vrai si une mesure près de l'échec est utile et permise (intervalle à
  /// 90 % au-delà de ± 6 %, rien de mesuré depuis 14 jours, aucune
  /// contre-indication de 0.3.1).
  bool _mesureUtile(Json item, Json plan, Piste t, {bool estVrai = false}) {
    final ta = jm(p['test_adaptatif']);
    final c = dictOuVide(contexte);
    if ((_seGet(item, 'sets', 0) as num) < 1 ||
        vrai(plan['test']) ||
        item['kind'] == 'warmup') {
      return false;
    }
    if (vrai(plan['verrou']) ||
        vrai(plan['sans_hausse']) ||
        (plan['echecs'] as int) > 0 ||
        vrai(jm(plan['cond'])['raison'])) {
      return false;
    }
    if (vrai(plan['dose_plafonnee'])) {
      // Dose plafonnée : jamais de série repère.
      return false;
    }
    if (coupure > 0) {
      // Coupure en cours : ni vrai test ni série repère.
      return false;
    }
    final n = _apresRetour(mem(item['exerciseId'] as String));
    if (n != null && n < _n('retour_seances_avant_mesure')) {
      return false;
    }
    if (c['jours_avant_echeance'] != null &&
        (c['jours_avant_echeance'] as num) <= 14) {
      return false;
    }
    if (item['dayStress'] == 'light') {
      return false;
    }
    if (!const <String?>[
      null,
      'standard',
      'top_set_backoff',
      'isometric_hold',
    ].contains(dictOuVide(item['technique'])['kind'])) {
      return false;
    }
    final cap = m.capacite(item['exerciseId'] as String)!;
    if (1.6448536269514722 * cap.$2 <= dbl(ta['intervalle_declenchement'])) {
      return false;
    }
    if (estVrai) {
      // Jamais de vrai test après un échec non prévu à la dernière séance
      // de l'exercice, ni dans les 14 jours qui suivent une série ratée.
      if (mem(item['exerciseId'] as String).echec) {
        return false;
      }
      if (t.dernierEchecJour != null &&
          jour - t.dernierEchecJour! < (ta['jours_min_entre_tests'] as num)) {
        return false;
      }
      // Vrai test : espacé du dernier test arrivé près de l'échec, et de
      // `jours_min_entre_rampes` de toute montée.
      if (t.dernierVraiTestJour != null &&
          jour - t.dernierVraiTestJour! <
              (ta['jours_min_entre_tests'] as num)) {
        return false;
      }
      if (t.derniereRampeJour != null &&
          jour - t.derniereRampeJour! < (ta['jours_min_entre_rampes'] as num)) {
        return false;
      }
    } else if (t.dernierTestJour != null &&
        jour - t.dernierTestJour! < (ta['jours_min_entre_tests'] as num)) {
      return false;
    }
    if (g.niveau == 0 && t.seances < 3) {
      return false;
    }
    return true;
  }

  /// Série repère (test adaptatif) : dernière série de l'exercice ouverte
  /// jusqu'à la réserve de repère (1,5 ; 2 pour un débutant).
  double? _repere(Json item, int index, Json plan, Piste t) {
    if (index != (_seGet(item, 'sets', 0) as num) - 1 ||
        vrai(plan['vrai_test'])) {
      return null;
    }
    if (!_mesureUtile(item, plan, t)) {
      return null;
    }
    return g.niveau == 0 ? 2.0 : 1.5;
  }

  /// Durée estimée d'un item (critère `seance_trop_longue` du banc), côtés
  /// non comptés.
  static double _dureeItemS(Json it) {
    final n = ent(ou(it['sets'], 0));
    if (n <= 0) {
      return 0.0;
    }
    double effort;
    if (it['repsHigh'] != null || it['repsLow'] != null) {
      final rh = it['repsHigh'] ?? it['repsLow'];
      effort = (ou(rh, 0) as num) * 3.0;
    } else if (it['secondsHigh'] != null || it['secondsLow'] != null) {
      final sh = it['secondsHigh'] ?? it['secondsLow'];
      effort = dbl(ou(sh, 0));
    } else {
      effort = 30.0;
    }
    final restO = it['restSeconds'];
    final rest = dbl(restO ?? 60);
    return 45.0 + n.toDouble() * effort + (n - 1).toDouble() * rest;
  }

  /// Vrai si la montée de test tient dans le budget de la séance ; sans
  /// budget connu : un seul vrai test par séance.
  bool _dureePermetTest(List<Json> items, Json item, (num, num) vt, int deja) {
    final ta = jm(p['test_adaptatif']);
    final budget = dictOuVide(contexte)['budget'];
    if (budget == null) {
      return deja == 0;
    }
    // Séries de la montée : au plus les séries dures permises, plus une
    // série encore facile.
    final n = _seMin<num>(
      (ta['rampe_series_max'] as num) + (vt.$1 == 1 ? 2 : 0),
      _seMax(1, ent(ou(item['sets'], 0)) - 1) + 1,
    );
    final repos = _seMax<num>(
      ou(item['restSeconds'], 0) as num,
      ta['repos_test_s'] as num,
    );
    var ajout = 45.0 + n * vt.$1 * 3.0 + (n - 1) * repos;
    final retire = _seMin(
      ent(ta['rampe_series_travail']),
      ent(ou(item['sets'], 0)) - 1,
    );
    if (retire > 0) {
      final rh = item['repsHigh'] ?? ou(item['repsLow'], 0);
      ajout -= retire * ((rh as num) * 3.0 + dbl(item['restSeconds'] ?? 60));
    }
    var total = 300.0 + ajout * (deja + 1);
    for (final it in items) {
      total += _dureeItemS(it);
    }
    return total / 60.0 <=
        dbl(budget) * dbl(s['seance_tolerance']) +
            dbl(s['seance_tolerance_min']);
  }

  /// Vrai test d'un mouvement principal chargé dont l'intervalle dépasse
  /// ± 6 % : une montée de charge avant le travail du jour. Renvoie
  /// (répétitions, réserve) ou null.
  (num, num)? _vraiTest(Json item, Json plan, Piste? t) {
    final ta = jm(p['test_adaptatif']);
    if (!const ['main', 'secondary'].contains(plan['role']) ||
        plan['type'] != 'charge') {
      return null;
    }
    if ((_seGet(item, 'sets', 0) as num) < 2) {
      return null;
    }
    if (t == null ||
        t.seances < 1 ||
        !_mesureUtile(item, plan, t, estVrai: true)) {
      return null;
    }
    // Grille trop grossière pour une montée : la mesure se fait en
    // répétitions (série repère).
    final grille = plan['grille'] as Grille?;
    final mm = mem(item['exerciseId'] as String);
    final ref = mm.chargeMax;
    if (grille == null || ref == null) {
      return null;
    }
    if (!mm.chargesReussies.any((e) => jour - e.$1 <= _n('barre_recente_j'))) {
      // Aucune barre réussie depuis `barre_recente_j` jours : pas de rampe.
      return null;
    }
    final bw = t.fraction * m.poidsKg;
    if (grille.suivant(ref.toDouble()) + bw >
        (ref + bw) * (1 + dbl(ta['rampe_pas_cran'])) + 1e-9) {
      // Cran de la grille au-delà de `rampe_pas_cran` de la charge totale :
      // pas de montée.
      return null;
    }
    if (g.niveau == 0) {
      return (ta['test_reps_debutant'] as num, ta['test_rir_debutant'] as num);
    }
    if (g.niveau >= 2) {
      return (ta['test_reps_avance'] as num, ta['test_rir_avance'] as num);
    }
    return (ta['test_reps'] as num, ta['test_rir'] as num);
  }

  Json _cibleCharge(Json item, int index, Json plan) {
    final exId = item['exerciseId'] as String;
    final t = m.piste(exId);
    final mem = this.mem(exId);
    final grille = plan['grille'] as Grille?;
    final (lo, hi) = _plages(item, index);
    if (lo == null || t == null || grille == null) {
      return _ecrit(item, index);
    }
    final rir = rirCible(item, plan);
    final flammes = flammesDeRir(rir);
    final cap = m.capacite(exId)!;
    final tech = dictOuVide(item['technique']);
    // Exercice jamais mesuré et a priori vague : l'utilisateur choisit sa
    // première charge (calibrage), Koach l'apprend.
    if (t.mesures == 0 && cap.$2 > 0.12) {
      return <String, Object?>{
        'repsLow': lo,
        'repsHigh': hi,
        'loadKg': null,
        'flames': flammes,
        'role': null,
      };
    }
    // `lo` non nul implique `hi` non nul (`_plages`).
    final hiN = hi!;
    final double reps = egalJson(hiN, lo) ? hiN.toDouble() : (lo + hiN) / 2.0;
    final pr = jld(jm(p['planification'])['prudence_charge']);
    var prudence = t.seances > 3 ? pr[1] : pr[0];
    // 1.0.3 : séries lourdes (répétitions ≤ `fiabilite_schema_reps`) d'un
    // athlète aux notes peu fiables (κ > 1) : quantile plus prudent de
    // `prudence_charge_fiabilite`·(κ − 1) écarts-types (l'écart-type lui-même
    // est déjà élargi par κ) ; 0 pour κ = 1.
    final kappa = m.elargissement();
    if (kappa > 1.0 &&
        hiN <= dbl(jm(p['mesure'])['fiabilite_schema_reps'] ?? 5)) {
      prudence +=
          dbl(jm(p['planification'])['prudence_charge_fiabilite'] ?? 0.0) *
          (kappa - 1.0);
    }
    var voulu = chargePour(exId, reps, rir, prudence)!;
    final trace = <Object?>['modele ${fixe(voulu, 1)} (rir ${fixe(rir, 1)})'];
    if (tech['kind'] == 'top_set_backoff' &&
        index >= 1 &&
        plan['tete'] != null) {
      // Séries allégées : part de la série de tête.
      final drop = dbl(ou(tech['backoffDropPct'], 0.08));
      final tete = (plan['tete'] as num) + t.fraction * m.poidsKg;
      voulu = _seMin(voulu, tete * (1 - drop) - t.fraction * m.poidsKg);
      trace.add('allegee ${fixe(voulu, 1)}');
    }
    // Intensité : la charge vise l'effort écrit, déplacé par la
    // planification dans son plafond ; la part écrite du 1RM borne par le
    // haut comme en 0.3.1. (`un_rm = exp(cap[0])` de la référence n'est pas
    // lu.)
    var part = item['percentOfOneRm'] as num?;
    final bw = t.fraction * m.poidsKg;
    final ecart = _seGet(item, 'koachIntensite', 0.0);
    if (vrai(ecart) && !vrai(plan['verrou'])) {
      final plaf = dbl(jm(p['planification'])['plafond_intensite']);
      voulu = (voulu + bw) * (1 + clampD(dbl(ecart), -plaf, plaf)) - bw;
    }
    if (part != null &&
        vrai(plan['fragile']) &&
        part > _n('surcharge_fragile_max')) {
      // A7.2 : exercice surchargé sur une zone fragile du profil, jamais
      // plus que le 1RM.
      part = _n('surcharge_fragile_max');
      _raison('koach.zone_fragile', {
        'exercice': exId,
        'zone': plan['fragile'],
        'cause': 'surcharge',
      });
    }
    if (part != null && !(tech['kind'] == 'top_set_backoff' && index >= 1)) {
      double haut;
      if (vrai(plan['verrou']) ||
          g.niveau == 0 ||
          part >= _n('couloir_part_lourde')) {
        haut = chargeDePart(exId, part.toDouble()) - bw;
      } else {
        haut = chargeDePart(exId, part * (1 + dbl(s['couloir_haut_max']))) - bw;
      }
      if (voulu > haut) {
        voulu = haut;
        trace.add(
          'part ecrite ${fixe(part, 3)}'
          '${vrai(plan['verrou']) ? ' verrou' : ''} -> '
          '${fixe(voulu, 1)}',
        );
      }
    }
    if (plan['part_max'] != null &&
        voulu > chargeDePart(exId, dbl(plan['part_max'])) - bw) {
      voulu = chargeDePart(exId, dbl(plan['part_max'])) - bw;
    }
    if (egalJson(lo, hi) && egalJson(hi, 1) && !vrai(plan['test'])) {
      final plafondS = palier >= 1
          ? dbl(s['simple_part_max_bilan_bas'])
          : dbl(s['simple_part_max']);
      final hautSimple = chargeDePart(exId, plafondS, duJour: true) - bw;
      if (voulu > hautSimple) {
        voulu = hautSimple;
      }
    }
    num charge = grille.proche(_seMax(voulu, grille.minimum));
    // Test adaptatif : parmi les charges de la zone prescrite, la plus
    // informative.
    final ta = jm(p['test_adaptatif']);
    if (index == 0 &&
        !vrai(plan['sans_hausse']) &&
        !vrai(plan['reprise']) &&
        !vrai(plan['verrou']) &&
        t.seances >= 1) {
      var meilleur = charge;
      var info0 = information(exId, charge.toDouble(), reps);
      for (final cand in [
        grille.precedent(charge.toDouble()),
        grille.suivant(charge.toDouble()),
      ]) {
        final rPrev = repsPrevues(exId, cand, 0.0);
        if (rPrev == null) {
          continue;
        }
        final ecartRir = ((rPrev - reps) - rir).abs();
        if (ecartRir <= dbl(ta['ecart_rir_tolere']) &&
            cand <= voulu * 1.0 + grille._pas(charge.toDouble())) {
          final info = information(exId, cand, reps);
          if (info > info0 * (1 + 0.02)) {
            meilleur = cand;
            info0 = info;
          }
        }
      }
      charge = meilleur;
    }
    final avantBornes = charge;
    if (vrai(plan['reprise']) && plan['reprise_plafond'] == null) {
      // Reprise par paliers : les paliers ne dépassent jamais ce que la
      // première série d'une séance ordinaire aurait pu atteindre (bornes de
      // hausse A7.2 sans le gel de la reprise). Calculé une fois par ligne,
      // quelle que soit la première série demandée.
      final nR = raisons.length;
      plan['reprise_plafond'] = _bornesHausse(
        exId,
        item,
        charge,
        plan,
        t,
        grille,
        _plages(item, 0).$2,
        0,
        gel: false,
      );
      raisons.removeRange(nR, raisons.length);
    }
    if (vrai(plan['reprise']) &&
        index >= 1 &&
        plan['charge_item'] == null &&
        plan['tete'] == null) {
      // Série demandée avant la première (aperçu des séries à venir) :
      // bornée comme une première série de reprise.
      charge = _bornesHausse(exId, item, charge, plan, t, grille, hi, 0);
    }
    charge = _bornesHausse(exId, item, charge, plan, t, grille, hi, index);
    if (charge != avantBornes) {
      trace.add(
        'hausse bornee ${fixe(avantBornes, 2)} -> '
        '${fixe(charge, 2)}',
      );
    }
    // Dans la séance : après un échec, -7,5 % gardé ; jamais plus lourd un
    // jour verrouillé.
    if (dbl(plan['baisse']) < 1.0 && plan['charge_item'] != null) {
      final tete =
          ((plan['charge_item'] as num) + bw) * dbl(plan['baisse']) - bw;
      if (charge > tete) {
        charge = grille.plancher(_seMax(tete, grille.minimum));
      }
    }
    if (index >= 1 &&
        plan['charge_item'] != null &&
        (vrai(plan['sans_hausse']) ||
            (plan['echecs'] as int) > 0 ||
            vrai(plan['dose_plafonnee']))) {
      if (charge > (plan['charge_item'] as num)) {
        charge = plan['charge_item'] as num;
      }
    }
    if (index >= 1 && vrai(plan['reprise']) && !vrai(plan['palier_franchi'])) {
      // Reprise par paliers mesurés : le palier suivant n'est permis
      // qu'après une série faite en entier, sans échec, notée, et dite au
      // plus aussi dure que visé (`serieFaite`). Sans série versée au
      // journal, la charge de la première série fait foi.
      final palierR = plan['charge_item'] != null
          ? plan['charge_item'] as num
          : plan['tete'] as num?;
      if (palierR != null && charge > palierR) {
        charge = palierR;
        trace.add('palier de reprise non franchi -> ${fixe(charge, 2)}');
      }
    }
    if (index >= 1 &&
        vrai(plan['reprise']) &&
        plan['reprise_plafond'] != null &&
        charge > (plan['reprise_plafond'] as num)) {
      // Paliers franchis : jamais au-dessus de la borne de hausse d'une
      // séance ordinaire (A7.2 : même schéma + hausse du niveau, ou barre
      // récente + `premiere_hausse`).
      charge = plan['reprise_plafond'] as num;
      trace.add('plafond de reprise -> ${fixe(charge, 2)}');
    }
    if (index >= 1 &&
        plan['charge_item'] != null &&
        tech['kind'] != 'top_set_backoff') {
      // D'une série à l'autre : -15 % / +5 % au plus, un cran permis.
      final ci = plan['charge_item'] as num;
      final haut = (ci + bw) * 1.05 - bw;
      final bas = (ci + bw) * 0.85 - bw;
      if (charge > haut) {
        charge = _seMax<num>(
          grille.plancher(haut),
          _seMin<num>(charge, grille.suivant(ci.toDouble())),
        );
      }
      if (charge < bas) {
        charge = grille.proche(bas);
      }
    }
    // Zone douloureuse ou en reprise : jamais plus lourd que le dernier
    // passage de l'exercice (invariant I3 de 0.3.1). Depuis 1.0.2, un jour
    // de bilan bas sans douleur n'est borné, comme en 0.3.1, que par la
    // dernière séance du même schéma (`_bornesHausse`), et la semaine du
    // retour d'une coupure par les paliers de reprise.
    if ((vrai(jm(plan['cond'])['sans_hausse']) ||
            vrai(jm(plan['cond'])['raison'])) &&
        mem.chargeDerniere != null &&
        charge > mem.chargeDerniere!) {
      charge = mem.chargeDerniere!;
      trace.add('pas de hausse (douleur) -> ${fixe(charge, 2)}');
    }
    if (charge < grille.minimum) {
      charge = grille.minimum;
    }
    if (index == 0) {
      plan['tete'] = charge;
    }
    final rep = _repere(item, index, plan, t);
    if (rep != null) {
      plan['repere'] = true;
      _raison('koach.serie_repere', {'exercice': exId});
      // Charge du repère : celle qui laisse la réserve de repère au haut de
      // la plage, sans dépasser de plus de 10 % la plus lourde barre
      // récente.
      final vouluR = chargePour(exId, hiN.toDouble(), rep, 0.5)!;
      num recente = plan['tete'] != null ? plan['tete'] as num : charge;
      for (final (j, c, _) in mem.chargesReussies) {
        if (jour - j <= 42 && c > recente) {
          recente = c;
        }
      }
      final plafondR = (recente + bw) * (1 + dbl(ta['repere_hausse'])) - bw;
      num chargeR = grille.plancher(
        _seMax(_seMin(vouluR, plafondR), grille.minimum),
      );
      if (chargeR < charge) {
        chargeR = charge;
      }
      if (index == 0) {
        // Repère sur la première série : bornes de hausse d'une séance à
        // l'autre sur le schéma ouvert.
        chargeR = _bornesHausse(
          exId,
          item,
          chargeR,
          plan,
          t,
          grille,
          hiN + (ta['reps_ouvertes'] as num),
          0,
        );
      }
      return <String, Object?>{
        'repsLow': lo,
        'repsHigh': hiN + (ta['reps_ouvertes'] as num),
        'loadKg': chargeR,
        'flames': flammesDeRir(rep),
        'role': null,
        'repere': true,
        'trace': <Object?>[
          'repere ${fixe(chargeR, 1)} (modele '
              '${fixe(vouluR, 1)}, plafond '
              '${fixe(plafondR, 1)})',
        ],
      };
    }
    return <String, Object?>{
      'repsLow': lo,
      'repsHigh': hi,
      'loadKg': charge,
      'flames': flammes,
      'role': null,
      'trace': trace,
    };
  }

  /// Bornes de hausse d'une séance à l'autre (règles A7.2 de 0.3.1).
  num _bornesHausse(
    String exId,
    Json item,
    num charge0,
    Json plan,
    Piste t,
    Grille grille,
    num? hi,
    int index, {
    bool? gel,
  }) {
    var charge = charge0;
    if (index > 0) {
      return charge;
    }
    final mem = this.mem(exId);
    final bw = t.fraction * m.poidsKg;
    final cle = (item['slotId'] as String?, hi?.toDouble());
    final avant = mem.schemas[cle];
    final cond = jm(plan['cond']);
    final douleur =
        vrai(cond['zone']) || vrai(_seGet(item, 'koachFragile', false));
    final profil = plan['fragile'];
    final fragile = douleur || vrai(profil);
    // `coachRise[niveau]` (× 0,5 sur zone fragile) pour toute ligne
    // chargée.
    final h = g.hausseMax(fragile);
    final avantBornes = charge;
    final gele = gel ?? (vrai(plan['sans_hausse']) || vrai(plan['reprise']));
    // 1.0.3 (contrat § 6.3, mesuré en KM1c3) : après un échec non prévu à
    // la dernière séance de l'exercice, 0.3.1 interdit toute hausse par
    // rapport à cette séance, quel que soit le schéma (`track.noUp` →
    // `lastAny`) ; Koach 1.0.2 ne l'interdisait que sur le même schéma
    // (`avant.$2`). `echec_sans_hausse_tout_schema` : 1 = règle de 0.3.1 ;
    // 2 = seulement quand les notes ne sont pas fiables (κ > 1) ; 0 = 1.0.2.
    final modeEchec = (s['echec_sans_hausse_tout_schema'] ?? 0) as num;
    final derniere = mem.chargeDerniere;
    if (mem.echec &&
        derniere != null &&
        modeEchec != 0 &&
        (modeEchec == 1 || m.elargissement() > 1.0)) {
      if (charge > derniere) {
        charge = derniere;
      }
    }
    if (avant != null) {
      if (gele || avant.$2) {
        if (charge > avant.$1) {
          charge = avant.$1;
        }
      } else {
        final haut = (avant.$1 + bw) * (1 + h) - bw;
        if (charge > haut) {
          final cran = grille.suivant(avant.$1.toDouble());
          charge = _seMax<num>(
            grille.plancher(haut),
            _seMin<num>(charge, cran),
          );
        }
      }
    } else {
      // Schéma nouveau à cet emplacement : pas plus de 10 % (ou un cran)
      // au-dessus de la plus lourde barre réussie des 42 derniers jours,
      // +2,5 % par répétition de moins (4 au plus).
      num? haut;
      for (final (j, c, r) in mem.chargesReussies) {
        if (jour - j > _n('barre_recente_j')) {
          continue;
        }
        var moins = r - (hi as num);
        if (moins < 0 || vrai(profil)) {
          moins = 0;
        }
        if (moins > _n('schema_change_reps_max')) {
          moins = _n('schema_change_reps_max');
        }
        num borne;
        if (gele || douleur) {
          borne = c;
        } else {
          final hp =
              dbl(s['premiere_hausse']) *
              (vrai(profil) ? dbl(s['hausse_fragile_facteur']) : 1.0);
          final b0 =
              (c + bw) * (1 + hp) * (1 + dbl(s['schema_change_part']) * moins) -
              bw;
          borne = _seMax(grille.plancher(b0), grille.suivant(c.toDouble()));
        }
        if (haut == null || borne > haut) {
          haut = borne;
        }
      }
      if (haut == null && mem.chargeDerniere != null && (gele || douleur)) {
        // 1.0.2 — schéma nouveau et aucune barre réussie depuis
        // `barre_recente_j` jours (retour d'une longue coupure, bloc
        // nouveau) : repli de 0.3.1 sur la dernière charge de l'exercice,
        // sans hausse un jour gelé (reprise, bilan bas, douleur).
        haut = mem.chargeDerniere;
      }
      if (haut != null && charge > haut) {
        charge = haut;
      }
    }
    // A7.2 règle 4 : schéma différent de la dernière séance du même
    // emplacement.
    final marque = mem.marques[item['slotId']];
    if (marque != null && marque.$3 != null && !egalJson(marque.$3, hi)) {
      final base = marque.$1 ?? marque.$2;
      if (base != null) {
        final ecart = marque.$3! - (hi as num);
        final num reps = (ecart <= 0 || fragile)
            ? 0
            : _seMin<num>(ecart, _n('schema_change_reps_max'));
        final capG = grille.plancher(
          (base + bw) * (1 + h) * (1 + dbl(s['schema_change_part']) * reps) -
              bw,
        );
        final pas = grille.suivant(grille.plancher(base.toDouble()));
        final plafondM = capG > pas ? capG : pas;
        if (charge > plafondM + 1e-9) {
          charge = plafondM;
        }
      }
    }
    if (vrai(profil) && charge < avantBornes) {
      _raison('koach.zone_fragile', {
        'exercice': exId,
        'zone': profil,
        'cause': 'hausse',
      });
    }
    return charge;
  }

  /// Charge proposée hors de la prescription ramenée sous les garde-fous
  /// de la séance ; null si aucune hausse n'est permise sur cette ligne
  /// aujourd'hui. Lecture seule : aucun état n'est modifié.
  num? borneExterne(Json item, int index, double charge) {
    final plan = plans[item['slotId']];
    if (plan == null || plan['type'] != 'charge' || vrai(plan['test'])) {
      return null;
    }
    final cond = jm(plan['cond']);
    if (vrai(plan['sans_hausse']) ||
        vrai(plan['reprise']) ||
        vrai(plan['verrou']) ||
        plan['part_max'] != null ||
        vrai(plan['dose_plafonnee']) ||
        vrai(cond['zone']) ||
        vrai(cond['raison']) ||
        vrai(plan['fragile']) ||
        (plan['echecs'] as int) > 0 ||
        dbl(plan['baisse']) < 1.0 ||
        vrai(item['koachFragile'])) {
      return null;
    }
    final exId = item['exerciseId'] as String;
    final t = m.pistes[exId];
    final grille = plan['grille'] as Grille?;
    if (t == null || grille == null) {
      return null;
    }
    final (_, hi) = _plages(item, index);
    final n = raisons.length;
    var c = _bornesHausse(exId, item, charge, plan, t, grille, hi, index);
    raisons.removeRange(n, raisons.length);
    final bw = t.fraction * m.poidsKg;
    if (index >= 1 && plan['charge_item'] != null) {
      final ci = plan['charge_item'] as num;
      final haut = (ci + bw) * 1.05 - bw;
      if (c > haut) {
        c = _seMax<num>(
          grille.plancher(haut),
          _seMin<num>(c, grille.suivant(ci.toDouble())),
        );
      }
    }
    return c;
  }

  Json _cibleReps(Json item, int index, Json plan) {
    final exId = item['exerciseId'] as String;
    final t = m.piste(exId);
    final mem = this.mem(exId);
    final (lo, hi) = _plages(item, index);
    if (lo == null || t == null) {
      return _ecrit(item, index);
    }
    final rir = rirCible(item, plan);
    final flammes = flammesDeRir(rir);
    if (t.mesures == 0) {
      return <String, Object?>{
        'repsLow': lo,
        'repsHigh': hi,
        'loadKg': null,
        'flames': flammes,
        'role': null,
      };
    }
    final prevu = repsPrevues(exId, null, rir)!;
    final (_, sd) = m.capaciteDuJour(exId)!;
    final sur = (prevu * math.exp(-0.5 * sd) + 0.3).floor();
    final hiN = hi!;
    num haut = hiN;
    num bas = lo;
    // Trop facile au haut de la plage : plage étendue (au plus le double,
    // 30 répétitions), en semaine de charge seulement.
    final cond = jm(plan['cond']);
    final libre =
        !(vrai(plan['verrou']) ||
            vrai(plan['sans_hausse']) ||
            vrai(cond['raison']) ||
            (plan['echecs'] as int) > 0 ||
            vrai(plan['dose_plafonnee']));
    final fiche = dictOuVide(fiches[exId]);
    if (libre &&
        sur > hiN &&
        !vrai(item['technique']) &&
        fiche['type_charge'] != 'elastique') {
      haut = _seMin<num>(_seMin<num>(sur, 2 * hiN), 30);
    }
    if (sur < bas) {
      // Le bas de la plage ne laisse pas la réserve : la série s'arrête à
      // la réserve visée.
      bas = _seMax<num>(1, sur);
    }
    // Verrous : jamais au-dessus de la plus grande série de la dernière
    // séance après échec, douleur, bilan bas ; zone récente : +10 %.
    if ((vrai(plan['sans_hausse']) || mem.echec) &&
        mem.repsMax != null &&
        haut > _seMax<num>(mem.repsMax!, bas)) {
      haut = _seMax<num>(mem.repsMax!, 1);
    }
    final hq = cond['hausse_quantite'];
    if (hq != null && mem.repsMax != null) {
      final plaf = _seMax<num>(
        (mem.repsMax! * (1 + dbl(hq))).floor(),
        mem.repsMax! + 1,
      );
      if (haut > plaf) {
        haut = plaf;
      }
    }
    if ((plan['echecs'] as int) > 0 &&
        mem.repsSeance != null &&
        haut > mem.repsSeance!) {
      haut = _seMax<num>(1, mem.repsSeance!);
    }
    if (vrai(plan['dose_plafonnee']) &&
        index >= 1 &&
        mem.repsSeance != null &&
        haut > mem.repsSeance!) {
      // Dose plafonnée : jamais plus de répétitions que la série
      // précédente.
      haut = _seMax<num>(1, mem.repsSeance!);
    }
    if (bas > haut) {
      bas = haut;
    }
    final rep = _repere(item, index, plan, t);
    if (rep != null) {
      plan['repere'] = true;
      _raison('koach.serie_repere', {'exercice': exId});
      return <String, Object?>{
        'repsLow': bas,
        'repsHigh': _seMin<num>(_seMax<num>(2 * hiN, haut), 60),
        'loadKg': null,
        'flames': flammesDeRir(rep),
        'role': null,
        'repere': true,
      };
    }
    return <String, Object?>{
      'repsLow': bas,
      'repsHigh': haut,
      'loadKg': null,
      'flames': flammes,
      'role': null,
    };
  }

  Json _cibleTenue(Json item, int index, Json plan) {
    final exId = item['exerciseId'] as String;
    final t = m.piste(exId);
    final mem = this.mem(exId);
    var lo = item['secondsLow'];
    var hi = item['secondsHigh'];
    lo ??= hi;
    hi ??= lo;
    if (lo == null || t == null) {
      return _ecrit(item, index);
    }
    final loN = lo as num;
    final hiN = hi as num;
    final rir = rirCible(item, plan);
    final flammes = flammesDeRir(rir);
    if (t.mesures == 0) {
      return <String, Object?>{
        'secondsLow': loN,
        'secondsHigh': hiN,
        'loadKg': null,
        'flames': flammes,
        'role': null,
      };
    }
    final prevu = secondesPrevues(exId, rir)!;
    final (mu, sd) = m.capaciteDuJour(exId)!;
    final sur = (prevu * math.exp(-0.5 * sd)).floor();
    num haut = hiN;
    // Plafond des tenues sur la valeur centrale du maximum du jour.
    final plaf = (dbl(s['tenue_part_max']) * math.exp(mu)).floor();
    if (haut > plaf && plaf >= 1) {
      haut = plaf;
    }
    final fiche = dictOuVide(fiches[exId]);
    final brasTendus = (_seGet(fiche, 'schema', '') as String).startsWith(
      'figure_statique',
    );
    double? h;
    if (brasTendus) {
      h = jld(s['tenue_hausse_par_niveau'])[g.niveau];
    }
    final cond = jm(plan['cond']);
    if (cond['hausse_quantite'] != null) {
      h = h == null
          ? dbl(cond['hausse_quantite'])
          : _seMin(h, dbl(cond['hausse_quantite']));
    }
    if (h != null && mem.secMax != null) {
      // Tendons : hausse par tenue bornée d'une séance à l'autre.
      final borne = _seMax<num>(
        (mem.secMax! * (1 + h)).floor(),
        mem.secMax! + _n('tenue_hausse_marge_s'),
      );
      if (haut > borne) {
        haut = borne;
        _raison('koach.tendon', {'exercice': exId});
      }
    }
    if ((vrai(plan['sans_hausse']) || mem.echec) &&
        mem.secMax != null &&
        haut > mem.secMax!) {
      haut = mem.secMax!;
    }
    if ((plan['echecs'] as int) > 0 &&
        mem.secSeance != null &&
        haut > mem.secSeance!) {
      haut = mem.secSeance!;
    }
    if (vrai(plan['dose_plafonnee']) &&
        index >= 1 &&
        mem.secSeance != null &&
        haut > mem.secSeance!) {
      // Dose plafonnée : jamais plus long que la tenue précédente.
      haut = mem.secSeance!;
    }
    final tot = mem.secSlot[item['slotId']];
    final n = ou(item['sets'], 0) as num;
    if (brasTendus && h != null && vrai(tot) && n > 1) {
      // A9.1 : temps total sous tension de l'emplacement borné comme une
      // tenue.
      final most = _seMax<num>(
        (tot! * (1 + h)).floor(),
        tot + _n('tenue_hausse_marge_s'),
      );
      if (haut * n > most) {
        final chacune = _seDivEnt(most, n) >= 1 ? _seDivEnt(most, n) : 1;
        if (haut > chacune) {
          haut = chacune;
          _raison('koach.tendon', {'exercice': exId, 'cause': 'total'});
        }
      }
    }
    if (haut < 1) {
      haut = 1;
    }
    // Cible au ressenti : la tenue s'arrête à la réserve visée, entre le
    // bas sûr et la durée écrite.
    num bas = loN <= haut ? loN : haut;
    if (sur < bas) {
      bas = _seMax<num>(1, sur);
    }
    final rep = _repere(item, index, plan, t);
    if (rep != null && !(brasTendus && mem.secMax == null)) {
      plan['repere'] = true;
      _raison('koach.serie_repere', {'exercice': exId});
      // Tenue repère : jusqu'à la durée écrite du bloc (et la borne des
      // tendons), à la réserve de repère.
      final ouvert = h != null
          ? haut
          : _seMax<num>(haut, _seMin<num>(2 * hiN, 180));
      return <String, Object?>{
        'secondsLow': bas,
        'secondsHigh': ouvert,
        'loadKg': null,
        'flames': flammesDeRir(rep),
        'role': null,
        'repere': true,
      };
    }
    return <String, Object?>{
      'secondsLow': bas,
      'secondsHigh': haut,
      'loadKg': null,
      'flames': flammes,
      'role': null,
    };
  }

  // ------------------------------------------------------------------
  // Tests et tentatives
  // ------------------------------------------------------------------
  Json? _cibleTest(Json item, int index, Json plan) {
    final exId = item['exerciseId'] as String;
    final test = dictOuVide(item['test']);
    final genre = test['kind'];
    final t = m.piste(exId);
    final typ = plan['type'];
    if (t == null) {
      return _ecrit(item, index);
    }
    final rirTest = test['targetRir'] as num?;
    if ((genre == 'one_rm' || genre == 'attempt_simulation') &&
        typ == 'charge') {
      return _tentative(item, index, plan, t);
    }
    if (plan['rampe'] != null && typ == 'charge') {
      if (plan['durs_max'] != null &&
          (_seGet(plan, 'durs', 0) as num) >= (plan['durs_max'] as num)) {
        // Budget de séries dures de la montée atteint.
        return null;
      }
      return _rampe(item, index, plan, t);
    }
    if (typ == 'charge') {
      // Test xRM : charge prévue pour (répétitions + réserve du test).
      final (loC, hiC) = _plages(item, index);
      final num rirC = rirTest ?? 1.0;
      final grille = plan['grille'] as Grille?;
      if (t.mesures == 0 || grille == null) {
        return <String, Object?>{
          'repsLow': loC,
          'repsHigh': hiC,
          'loadKg': item['startLoadKg'],
          'flames': flammesDeRir(rirC.toDouble()),
          'role': 'test',
        };
      }
      final voulu = chargePour(exId, hiC!.toDouble(), rirC.toDouble(), 0.25)!;
      num charge = grille.proche(_seMax(voulu, grille.minimum));
      final mem = this.mem(exId);
      final ecrite = item['startLoadKg'] as num?;
      if (vrai(plan['verrou']) && ecrite != null && charge > ecrite + 1e-9) {
        // A6.5 : semaine allégée ou de test, jamais plus lourd que la
        // charge écrite.
        charge = grille.plancher(ecrite.toDouble()) > ecrite
            ? ecrite
            : grille.plancher(ecrite.toDouble());
      }
      final evenement = vrai(dictOuVide(contexte)['jour_evenement']);
      if ((vrai(plan['sans_hausse']) ||
              mem.echec ||
              (vrai(plan['reprise']) && !evenement)) &&
          mem.chargeDerniere != null &&
          charge > mem.chargeDerniere!) {
        // Après un échec non prévu à la dernière séance aussi ; la semaine
        // du retour d'une coupure, hors jour d'épreuve (1.0.2 : le jour
        // d'épreuve, le test suit l'estimation, comme les tentatives).
        charge = mem.chargeDerniere!;
      }
      if (vrai(plan['reprise']) && evenement) {
        // Jour d'épreuve en semaine de retour : le test suit l'estimation,
        // sous le palier des barres récentes ramené aux répétitions du test
        // (`_palierBarres`, comme l'ouverture des tentatives).
        final bw = t.fraction * m.poidsKg;
        final autorise = _palierBarres(mem, bw);
        if (autorise != null) {
          num moins = hiC - 1;
          if (moins > _n('schema_change_reps_max')) {
            moins = _n('schema_change_reps_max');
          }
          final borne =
              (autorise + bw) /
                  (1 + dbl(s['schema_change_part']) * (moins > 0 ? moins : 0)) -
              bw;
          if (charge > borne) {
            charge = grille.plancher(_seMax(borne, grille.minimum));
          }
        }
      }
      if (index >= 1 && mem.chargeSeance != null) {
        // Deuxième essai : un cran de plus si le premier a laissé plus que
        // la réserve du test, sinon la même barre.
        charge = (plan['echecs'] as int) == 0
            ? _seMax<num>(charge, mem.chargeSeance!)
            : mem.chargeSeance!;
      }
      return <String, Object?>{
        'repsLow': loC,
        'repsHigh': hiC,
        'loadKg': charge,
        'flames': flammesDeRir(rirC.toDouble()),
        'role': 'test',
      };
    }
    final num rir = rirTest ?? 0.0;
    var f = flammesDeRir(rir.toDouble());
    if (f < 8) {
      f = 8;
    }
    if (typ == 'tenue') {
      final loS = item['secondsLow'];
      final hiS = item['secondsHigh'];
      return <String, Object?>{
        'secondsLow': loS ?? hiS,
        'secondsHigh': hiS ?? loS,
        'loadKg': null,
        'flames': f,
        'role': 'test',
      };
    }
    final (lo, hi) = _plages(item, index);
    return <String, Object?>{
      'repsLow': lo,
      'repsHigh': hi,
      'loadKg': null,
      'flames': f,
      'role': 'test',
    };
  }

  /// Vrai test en montée de charge, conduit par le ressenti : tant que la
  /// série est dite facile, la charge monte ; le test s'arrête à la
  /// réserve du test, à un échec, ou quand la barre suivante dépasse
  /// nettement ce que le modèle croit possible.
  Json? _rampe(Json item, int index, Json plan, Piste t) {
    final ta = jm(p['test_adaptatif']);
    final exId = item['exerciseId'] as String;
    final mem = this.mem(exId);
    final grille = plan['grille'] as Grille?;
    final (nT, rirT) = plan['rampe'] as (num, num);
    final bw = t.fraction * m.poidsKg;
    // 1.0.3 : écart-type brut (la borne large `mu + 2,5·σ` ne doit pas
    // monter avec l'élargissement de la fiabilité : il irait dans le sens
    // moins prudent).
    final (mu, sd) = m.capaciteDuJour(exId, brut: true)!;
    final (lamb, k) = m.courbe(t);
    double voulu;
    var dit = 0.0;
    if (index == 0) {
      voulu = chargePour(exId, nT.toDouble(), rirT + 2.0, 0.5)!;
      num? recente;
      for (final (j, c, _) in mem.chargesReussies) {
        if (jour - j <= _n('barre_recente_j') &&
            (recente == null || c > recente)) {
          recente = c;
        }
      }
      if (recente == null) {
        // Pas de barre récente : pas de rampe.
        return null;
      }
      // Première barre de la montée : jamais plus que ce que les barres
      // réussies des 42 derniers jours justifient (règle du premier
      // passage à un schéma, A7.2).
      var plafondR = (recente + bw) * (1 + dbl(ta['repere_hausse'])) - bw;
      final hausse = jld(s['hausse_par_niveau'])[g.niveau];
      for (final (j, c, r) in mem.chargesReussies) {
        if (jour - j > _n('barre_recente_j')) {
          continue;
        }
        var plus = r - nT;
        if (plus < 0) {
          plus = 0;
        }
        if (plus > _n('schema_change_reps_max')) {
          plus = _n('schema_change_reps_max');
        }
        final b =
            (c + bw) *
                (1 + hausse) *
                (1 + dbl(s['schema_change_part']) * plus) -
            bw;
        if (b > plafondR) {
          plafondR = b;
        }
      }
      if (voulu > plafondR) {
        voulu = plafondR;
      }
    } else {
      final derniere = plan['charge_item'] as num?;
      if (derniere == null) {
        return null;
      }
      final f = plan['flammes_item'];
      if (vrai(plan['echec_item']) ||
          f == null ||
          (ou(plan['reps_item'], 0) as num) < nT) {
        return null;
      }
      final fN = f as num;
      dit = fN >= 10 ? 0.0 : (11 - fN) / 2.0;
      if (fN >= 10) {
        return null;
      }
      var pas = 0.0;
      if (dit <= rirT + 0.75) {
        // La note dit que la réserve du test est atteinte : la même barre
        // est refaite une fois pour confirmation.
        plan['bas'] = (_seGet(plan, 'bas', 0) as int) + 1;
        if ((plan['bas'] as int) >= (ta['rampe_confirmations'] as num)) {
          return null;
        }
        return <String, Object?>{
          'repsLow': nT,
          'repsHigh': nT,
          'loadKg': derniere,
          'flames': flammesDeRir(2.0),
          'role': 'test',
          'repere': true,
          'trace': <Object?>['vrai test, confirmation ${fixe(derniere, 1)}'],
        };
      } else {
        final paliers = jl(ta['rampe_pas_par_rir']);
        for (final e in paliers) {
          final seuil = dbl(jl(e)[0]);
          final pp = dbl(jl(e)[1]);
          if (dit >= seuil - rirT + 1.0 - 1e-9) {
            pas = pp;
            break;
          }
        }
        if (pas <= 0) {
          pas = dbl(jl(paliers.last)[1]);
        }
      }
      voulu = (derniere + bw) * (1 + pas) - bw;
      // Garde-fou large : la barre ne dépasse jamais ce que le modèle tient
      // pour presque impossible.
      final borne =
          math.exp(
            mu +
                2.5 * _seMax(sd, dbl(ta['rampe_sd_min'])) -
                Modele.gK(lamb, k, nT.toDouble()),
          ) -
          bw;
      if (voulu > borne) {
        voulu = borne;
      }
    }
    var charge = grille!.plancher(_seMax(voulu, grille.minimum));
    if (index >= 1 && charge > (plan['charge_item'] as num) + 1e-9) {
      // Barre suivante tenue pour faisable par le modèle ; sinon le plus
      // petit pas ; sinon le test s'arrête là.
      final pr = probaReussite(exId, charge, nT);
      if (pr != null && pr < dbl(ta['rampe_proba_min'])) {
        final ci = plan['charge_item'] as num;
        var petit = grille.plancher(
          _seMax(
            (ci + bw) * (1 + dbl(jl(jl(ta['rampe_pas_par_rir']).last)[1])) - bw,
            grille.minimum,
          ),
        );
        if (petit <= ci + 1e-9) {
          petit = grille.suivant(ci.toDouble());
        }
        final pr2 = probaReussite(exId, petit, nT);
        if (petit >= charge ||
            pr2 == null ||
            pr2 < dbl(ta['rampe_proba_min'])) {
          return null;
        }
        charge = petit;
      }
    }
    if (index >= 1 && charge <= (plan['charge_item'] as num) + 1e-9) {
      final ci = plan['charge_item'] as num;
      final suivant = grille.suivant(ci.toDouble());
      if ((suivant + bw) <= (ci + bw) * (1 + dbl(ta['rampe_pas'])) + 1e-9) {
        charge = suivant;
      } else if ((suivant + bw) <=
              (ci + bw) * (1 + dbl(ta['rampe_pas_cran'])) + 1e-9 &&
          dit >= rirT + dbl(ta['rampe_cran_rir_marge']) - 1e-9) {
        // Grille grossière : un cran entier, seulement après une série dite
        // très facile et si le modèle tient la barre pour faisable.
        final pr = probaReussite(exId, suivant, nT);
        if (pr == null || pr < dbl(ta['rampe_proba_min'])) {
          return null;
        }
        charge = suivant;
      } else {
        return null;
      }
    }
    // L'effort affiché d'une série de montée est « deux en réserve ».
    return <String, Object?>{
      'repsLow': nT,
      'repsHigh': nT,
      'loadKg': charge,
      'flames': flammesDeRir(2.0),
      'role': 'test',
      'repere': true,
      'trace': <Object?>['vrai test ${fixe(charge, 1)}'],
    };
  }

  /// Palier (charge externe pour UNE répétition) que les barres des
  /// `barre_recente_j` derniers jours autorisent, ou null sans barre
  /// récente (1.0.2, C13.12). Chaque barre réussie est ramenée à une
  /// répétition (+`schema_change_part` par répétition faite au-delà de la
  /// première, `schema_change_reps_max` au plus). Le palier part de la plus
  /// lourde ; il ne monte au-dessus d'elle que si toutes les barres proches
  /// (à `tentative_palier_bande` près) ont été dites faciles : la hausse est
  /// celle de la note la plus dure parmi elles (`tentative_palier_par_rir`),
  /// nulle dès qu'une de ces barres n'est pas notée ou est dite à moins
  /// d'une répétition de l'échec. Il reste sous la plus légère barre ratée
  /// sans une répétition faite pendant la même période, quand elle est plus
  /// lourde que la plus lourde barre réussie.
  double? _palierBarres(Memoire mem, double bw) {
    // 1.0.3 (contrat § 5.13, § 6.5 ; mesuré en KM1c3) : notes peu fiables
    // (κ > 1) : le palier accordé par la note d'une barre est réduit
    // (× max(0 ; 1 − tentative_palier_fiabilite·(κ − 1))), et chaque barre
    // réussie ne vaut que (1 − marge) de sa charge, marge =
    // min(tentative_marge_fiabilite_max ; tentative_marge_fiabilite·(κ − 1)).
    // κ = 1 : règle de 1.0.2.
    final kappa = m.elargissement();
    var gPas = 1.0;
    var marge = 0.0;
    if (kappa > 1.0) {
      gPas = 1.0 - dbl(s['tentative_palier_fiabilite'] ?? 0.0) * (kappa - 1.0);
      if (gPas < 0.0) {
        gPas = 0.0;
      }
      marge = dbl(s['tentative_marge_fiabilite'] ?? 0.0) * (kappa - 1.0);
      final mx = dbl(s['tentative_marge_fiabilite_max'] ?? 0.0);
      if (marge > mx) {
        marge = mx;
      }
    }
    double? plusHaute;
    final ramenees = <(double, double)>[];
    for (final (j, c, r, f) in mem.barres) {
      if (jour - j > _n('barre_recente_j')) {
        continue;
      }
      var plus = r - 1;
      if (plus > _n('schema_change_reps_max')) {
        plus = _n('schema_change_reps_max');
      }
      var total = (c + bw) * (1 + dbl(s['schema_change_part']) * plus);
      final dit = rirDeFlammes(f);
      var pas = 0.0;
      if (dit != null) {
        for (final ligne in jl(s['tentative_palier_par_rir'])) {
          final sp = jl(ligne);
          if (dit >= dbl(sp[0]) - 1e-9) {
            pas = dbl(sp[1]);
            break;
          }
        }
      }
      pas *= gPas;
      if (marge > 0.0) {
        total *= 1.0 - marge;
      }
      ramenees.add((total, pas));
      if (plusHaute == null || total > plusHaute) {
        plusHaute = total;
      }
    }
    if (plusHaute == null) {
      return null;
    }
    double? pas;
    for (final (total, p_) in ramenees) {
      if (total >= plusHaute * (1 - dbl(s['tentative_palier_bande'])) - 1e-9 &&
          (pas == null || p_ < pas)) {
        pas = p_;
      }
    }
    var autorise = plusHaute * (1 + pas!);
    for (final (j, c) in mem.barresRatees) {
      if (jour - j > _n('barre_recente_j')) {
        continue;
      }
      final ratee = c + bw;
      if (ratee > plusHaute + 1e-9 &&
          autorise > ratee * (1 - dbl(s['schema_change_part']))) {
        // Barre ratée récemment, plus lourde que tout ce qui a été
        // réussi : on reste un palier dessous.
        autorise = _seMax(
          plusHaute,
          (ratee * (1 - dbl(s['schema_change_part']))).toDouble(),
        );
      }
    }
    return autorise - bw;
  }

  /// Échelle des tentatives (règles A8.2 de 0.3.1, probabilités de
  /// Koach) : ouverture sûre, puis la barre la plus lourde qui garde la
  /// probabilité voulue.
  Json _tentative(Json item, int index, Json plan, Piste t) {
    final exId = item['exerciseId'] as String;
    final grille = plan['grille'] as Grille?;
    final mem = this.mem(exId);
    // 1.0.3 : écart-type brut (sans l'élargissement κ de la fiabilité des
    // notes) : l'ouverture au quantile élargi a été mesurée en KM1c3 (coût
    // sans gain, CHANGEMENTS_1_0_3.md § B) ; la prudence envers des notes
    // peu fiables passe par le palier des barres prouvées (`_palierBarres`)
    // et la barre suivante après un échec.
    var (mu, sd) = m.capaciteDuJour(exId, brut: true)!;
    final bw = t.fraction * m.poidsKg;
    var baisse = 1.0 - dbl(s['tentative_bilan_bas_part']) * palier;
    if (vrai(jm(plan['cond'])['zone'])) {
      baisse -= dbl(s['tentative_bilan_bas_part']);
    }
    mu += math.log(baisse);
    sd = _seMax(sd, 0.01);
    final n = _seGet(item, 'sets', 3) as num;
    final flammes = const [7, 9, 10][index < 3 ? index : 2];

    double plusLourde(double proba, [double? plafondTotal]) {
      var total = math.exp(mu - normPpfK(proba) * sd);
      if (plafondTotal != null && total > plafondTotal) {
        total = plafondTotal;
      }
      return grille!.plancher(_seMax(total - bw, grille.minimum));
    }

    if (index == 0 || mem.chargeSeance == null) {
      // A8.2 de 0.3.1 : avant la première barre seulement, le maximum
      // estimé du jour est relevé du gain de l'affûtage.
      final semO = dictOuVide(contexte)['semaine'];
      if (semO != null) {
        final sem = ent(semO);
        if (const ['taper', 'competition'].contains(genres[sem]) ||
            const ['taper', 'competition'].contains(genres[sem - 1])) {
          mu += dbl(jm(p['planification'])['gain_affutage']);
        }
      }
      num ouverture = plusLourde(
        dbl(s['tentative_ouverture_proba']),
        dbl(s['tentative_ouverture_part']) * math.exp(mu),
      );
      // Règle A8.2 de 0.3.1 : une barre réussie dans les 42 derniers jours,
      // plus légère que l'ouverture calculée et à 85 % au moins de
      // l'estimation, sert d'ouverture.
      num? recente;
      for (final (j, c, _) in mem.chargesReussies) {
        if (jour - j <= _n('barre_recente_j') &&
            (recente == null || c > recente)) {
          recente = c;
        }
      }
      if (recente != null &&
          recente < ouverture &&
          recente + bw >= dbl(s['tentative_recente_part']) * math.exp(mu)) {
        ouverture = recente;
      }
      // Incertitude élargie : une barre déjà réussie dans les 42 jours
      // reste une ouverture sûre (plancher), sans dépasser le plafond
      // d'ouverture.
      if (recente != null &&
          recente > ouverture &&
          baisse >= 1.0 &&
          !vrai(plan['sans_hausse']) &&
          coupure == 0 &&
          !mem.echec) {
        final plafondT = dbl(s['tentative_ouverture_part']) * math.exp(mu) - bw;
        ouverture = grille!.plancher(
          _seMax<num>(_seMin<num>(recente, plafondT), ouverture).toDouble(),
        );
      }
      // 1.0.2 — paliers mesurés (C13.12). L'ouverture suit la capacité
      // estimée, sans dépasser le palier que les barres réussies des 42
      // derniers jours autorisent selon ce que l'athlète en a dit
      // (`_palierBarres`).
      final autorise = _palierBarres(mem, bw);
      if (autorise != null && ouverture > autorise) {
        ouverture = grille!.plancher(_seMax(autorise, grille.minimum));
      }
      return <String, Object?>{
        'repsLow': 1,
        'repsHigh': 1,
        'loadKg': ouverture,
        'flames': flammes,
        'role': 'attempt',
      };
    }
    final derniere = mem.chargeSeance!;
    final dernierEssai = index >= n - 1;
    final proba = dernierEssai
        ? dbl(s['tentative_troisieme_proba'])
        : dbl(s['tentative_deuxieme_proba']);
    if ((plan['echecs'] as int) > 0 && vrai(mem.echecSeance)) {
      // Règle A8.2 de 0.3.1 : la même barre après un échec (en
      // compétition, le règlement interdit de redescendre). 1.0.3 (contrat
      // § 6.5, mesuré en KM1c3) : hors semaine de compétition (test 1RM à
      // l'entraînement), la barre suivante suit l'estimation mise à jour
      // par l'échec, au plus `tentative_echec_baisse_part` sous la barre
      // ratée (0 : règle A8.2 partout), jamais au-dessus.
      final partBaisse = dbl(s['tentative_echec_baisse_part'] ?? 0.0);
      final semC = dictOuVide(contexte)['semaine'];
      final competition = semC != null && genres[ent(semC)] == 'competition';
      if (partBaisse > 0.0 && !competition) {
        final g0 = grille!;
        final bas = _seMax<double>(
          ((derniere + bw) * (1 - partBaisse) - bw).toDouble(),
          g0.minimum,
        );
        var plancherB = g0.plancher(bas);
        if (plancherB < bas - 1e-9) {
          // au plus `part` sous la barre ratée : cran au-dessus
          plancherB = g0.suivant(plancherB);
        }
        num c = plusLourde(proba);
        if (c < plancherB) {
          c = plancherB;
        }
        if (c > derniere) {
          c = derniere;
        }
        return <String, Object?>{
          'repsLow': 1,
          'repsHigh': 1,
          'loadKg': c,
          'flames': flammes,
          'role': 'attempt',
        };
      }
      return <String, Object?>{
        'repsLow': 1,
        'repsHigh': 1,
        'loadKg': derniere,
        'flames': flammes,
        'role': 'attempt',
      };
    }
    final saut = dernierEssai
        ? dbl(s['tentative_saut_3'])
        : dbl(s['tentative_saut_2']);
    num charge = plusLourde(proba);
    final haut = _seMin(
      (derniere + bw) * (1 + saut) - bw,
      derniere + dbl(s['tentative_saut_kg']),
    );
    final cibleK = item['koachCible'];
    if (dernierEssai &&
        cibleK != null &&
        derniere < (cibleK as num) &&
        cibleK <= haut + 1e-9) {
      final pr = probaReussite(exId, cibleK.toDouble(), 1, true);
      if (pr != null && pr >= 0.35) {
        charge = _seMax<num>(charge, cibleK);
      }
    }
    if (charge > haut) {
      charge = grille!.plancher(haut);
    }
    if (charge < derniere) {
      charge = derniere;
    }
    if (charge <= derniere + 1e-9) {
      charge = _seMin<num>(
        grille!.suivant(derniere.toDouble()),
        _seMax<num>(grille.plancher(haut), derniere),
      );
      final f = mem.flammesSeance;
      if (charge <= derniere + 1e-9 &&
          f != null &&
          (f as num) <= (index == 1 ? 7 : 9) &&
          grille.suivant(derniere.toDouble()) - derniere <=
              dbl(s['tentative_saut_kg']) + 1e-9) {
        // 1.0.2 : saut en pourcentage plus petit qu'un cran de la grille
        // (barre légère) — un cran reste permis quand la barre précédente a
        // été dite au plus aussi dure que visé, dans la limite du saut en
        // kilos.
        charge = grille.suivant(derniere.toDouble());
      }
      final pr = probaReussite(exId, charge.toDouble(), 1, true);
      if (pr != null && pr < 0.2) {
        charge = derniere;
      }
    }
    return <String, Object?>{
      'repsLow': 1,
      'repsHigh': 1,
      'loadKg': charge,
      'flames': flammes,
      'role': 'attempt',
    };
  }

  // ------------------------------------------------------------------
  // Retour d'une série faite et fin de séance
  // ------------------------------------------------------------------
  void serieFaite(Json serie) {
    final exId = serie['exerciseId'] as String;
    final mem = this.mem(exId);
    final plan = plans[serie['slotId']];
    final charge = serie['externalLoadKg'] as num?;
    if (charge != null && charge >= 0) {
      mem.chargeSeance = charge;
    }
    if (serie['reps'] != null) {
      mem.repsSeance = serie['reps'] as num;
    }
    if (serie['seconds'] != null) {
      mem.secSeance = serie['seconds'] as num;
    }
    final echec = vrai(serie['failed']);
    mem.echecSeance = echec ? 1 : 0;
    mem.flammesSeance = serie['flames'];
    if (plan != null) {
      if (charge != null && charge >= 0) {
        plan['charge_item'] = charge;
      }
      plan['flammes_item'] = serie['flames'];
      plan['reps_item'] = serie['reps'];
      plan['echec_item'] = echec;
      if (vrai(plan['reprise'])) {
        // Palier de reprise franchi : série faite en entier, sans échec,
        // notée, dite au plus aussi dure que visé.
        final cible = dictOuVide(serie['target']);
        final f = serie['flames'];
        final fc = cible['flames'];
        final bas = cible['repsLow'];
        final franchi =
            !echec &&
            f != null &&
            fc != null &&
            (f as num) <= (fc as num) &&
            bas != null &&
            (ou(serie['reps'], 0) as num) >= (bas as num);
        plan['palier_franchi'] = franchi;
      }
      if (echec && !vrai(plan['test'])) {
        plan['echecs'] = (plan['echecs'] as int) + 1;
        plan['baisse'] = 1.0 - dbl(s['echec_baisse']);
      } else if (echec) {
        plan['echecs'] = (plan['echecs'] as int) + 1;
      }
      if (vrai(plan['test']) && plan.containsKey('durs')) {
        final f = serie['flames'];
        if (echec || f == null || (f as num) >= 3) {
          plan['durs'] = (plan['durs'] as int) + 1;
        }
      }
    }
  }

  /// Fin de séance : mémoire par exercice (verrous de la prochaine
  /// séance), courses et jours durs.
  void fermer(Json record) {
    final jour = this.jour;
    final parEx = <(String, String?), List<Json>>{};
    final semaine = g.semaine;
    final sets = listeOuVide(record['sets']);
    for (final x0 in sets) {
      final x = jm(x0);
      parEx
          .putIfAbsent((
            x['exerciseId'] as String,
            x['slotId'] as String?,
          ), () => <Json>[])
          .add(x);
      if ((ou(x['reps'], 0) as num) > 0 || (ou(x['seconds'], 0) as num) > 0) {
        final zz = zonesEx[x['exerciseId']];
        if (zz != null) {
          for (final z in zz.$2) {
            final dz = doseZone.putIfAbsent(z, () => <int, int>{});
            dz[semaine] = (dz[semaine] ?? 0) + 1;
            expoJour[z] = jour;
          }
        }
      }
    }
    final vus = <String>{};
    for (final e in parEx.entries) {
      final (exId, slot) = e.key;
      final series = e.value;
      final mem = this.mem(exId);
      if (!vus.contains(exId)) {
        mem.jours.add(jour);
        mem.echec = false;
        mem.chargeMax = null;
        mem.repsMax = null;
        mem.secMax = null;
        mem.secTotal = 0;
        vus.add(exId);
      }
      mem.jour = jour;
      num? derniere;
      for (final x in series) {
        final c = x['externalLoadKg'] as num?;
        if (c != null && c >= 0 && (derniere == null || c > derniere)) {
          derniere = c;
        }
      }
      if (derniere != null) {
        // Dernier passage de l'exercice dans la séance : référence « pas de
        // hausse ».
        mem.chargeDerniere = derniere;
      }
      for (final x in series) {
        if (x['kind'] == 'warmup') {
          continue;
        }
        final c = x['externalLoadKg'] as num?;
        if (c != null &&
            c >= 0 &&
            (mem.chargeMax == null || c > mem.chargeMax!)) {
          mem.chargeMax = c;
        }
        final r = x['reps'] as num?;
        if (r != null && (mem.repsMax == null || r > mem.repsMax!)) {
          mem.repsMax = r;
        }
        final sec = x['seconds'] as num?;
        if (sec != null) {
          if (mem.secMax == null || sec > mem.secMax!) {
            mem.secMax = sec;
          }
          mem.secTotal = mem.secTotal! + sec;
          if (mem.meilleurSec == null || sec > mem.meilleurSec!.$1) {
            mem.meilleurSec = (sec, jour);
          }
        }
        final cible = dictOuVide(x['target']);
        if (vrai(x['failed']) &&
            (ou(cible['flames'], 0) as num) < 10 &&
            !const ['attempt', 'test'].contains(cible['role'])) {
          mem.echec = true;
        }
        if (c != null && r != null && vrai(r) && !vrai(x['failed'])) {
          mem.chargesReussies.add((jour, c, r));
          mem.barres.add((jour, c, r, x['flames']));
        }
        if (c != null && c >= 0 && vrai(x['failed']) && !vrai(r)) {
          mem.barresRatees.add((jour, c));
        }
      }
      Json? premier;
      for (final x in series) {
        if (x['kind'] != 'warmup' &&
            x['externalLoadKg'] != null &&
            dictOuVide(x['target'])['role'] == null) {
          premier = x;
          break;
        }
      }
      if (premier != null) {
        final cible = dictOuVide(premier['target']);
        final hi = cible['repsHigh'] as num?;
        final rate = series.any((x) => vrai(x['failed']));
        num faitMax = ou(series[0]['reps'], 0) as num;
        for (final x in series) {
          final r = ou(x['reps'], 0) as num;
          if (r > faitMax) {
            faitMax = r;
          }
        }
        final atteint = faitMax >= (ou(hi, 0) as num);
        mem.schemas[(slot, hi?.toDouble())] = (
          premier['externalLoadKg'] as num,
          rate || !atteint,
        );
        _marquer(mem, slot, series, hi);
      }
      if (slot != null) {
        num tot = 0;
        for (final x in series) {
          if (x['kind'] != 'warmup' &&
              !const [
                'test',
                'attempt',
              ].contains(dictOuVide(x['target'])['role'])) {
            tot += ou(x['seconds'], 0) as num;
          }
        }
        if (tot > 0) {
          mem.secSlot[slot] = tot;
        }
      }
    }
    _formes(parEx);
    _fermerVolume(sets);
    _fermerEndurance(sets);
    joursSeances.add(jour);
    if (joursSeances.length > 20) {
      joursSeances = joursSeances.sublist(joursSeances.length - 20);
    }
    derniereSeance = jour;
  }

  /// Dernière séance de l'emplacement (règle du schéma changé, A7.2) :
  /// charge de base = la plus légère charge échouée, sinon la plus forte
  /// réussie ; une semaine verrouillée ou un jour de bilan bas ne remplace
  /// pas la base de semaine de charge.
  void _marquer(Memoire mm, String? slot, List<Json> series, num? hi) {
    num? held;
    num? echouee;
    for (final x in series) {
      final c = x['externalLoadKg'] as num?;
      if (x['kind'] == 'warmup' || c == null || c < 0) {
        continue;
      }
      if (vrai(x['failed'])) {
        if (echouee == null || c < echouee) {
          echouee = c;
        }
      } else if ((ou(x['reps'], 0) as num) > 0 && (held == null || c > held)) {
        held = c;
      }
    }
    final base = echouee ?? held;
    final avant = mm.marques[slot];
    num? baseCharge;
    if (verrouillee() || palier >= 1) {
      baseCharge = avant == null ? null : (avant.$1 ?? avant.$2);
    } else {
      baseCharge = base;
    }
    mm.marques[slot] = (baseCharge, base, hi);
  }

  /// ln capacité à frais + effet de jour de la séance (mélange des deux
  /// branches).
  double _forme(String exId) {
    final t = m.pistes[exId]!;
    final (idx0, co0) = m.hCapacite(t, jour: false);
    final idx = [...idx0, ds];
    final co = [...co0, 1.0];
    var mu = Modele.stats(m.m, m.pm, m.cap, idx, co).$1;
    final alt = m._alt;
    if (alt != null) {
      final w = m.poidsMauvaisJour();
      final mu1 = Modele.stats(alt.m, alt.p, alt.cap, idx, co).$1;
      mu = (1 - w) * mu + w * mu1;
    }
    return t.base + mu;
  }

  /// A6.2 : alerte de surmenage d'un mouvement principal — deux séances
  /// mesurées de suite au moins `surmenage_baisse` sous la séance de
  /// référence, les trois en `surmenage_fenetre_j` jours au plus.
  void _formes(Map<(String, String?), List<Json>> parEx) {
    final vus = <String>[];
    for (final e in parEx.entries) {
      final (exId, slot) = e.key;
      final series = e.value;
      final plan = plans[slot];
      if (plan == null ||
          plan['role'] != 'main' ||
          !const ['charge', 'reps', 'tenue'].contains(plan['type']) ||
          vus.contains(exId) ||
          m.pistes[exId] == null) {
        continue;
      }
      if (!series.any(
        (x) =>
            x['kind'] != 'warmup' &&
            ((ou(x['reps'], 0) as num) > 0 ||
                (ou(x['seconds'], 0) as num) > 0 ||
                vrai(x['failed'])),
      )) {
        continue;
      }
      vus.add(exId);
      final mm = mem(exId);
      if (m.pistes[exId]!.seances < _n('surmenage_seances_min')) {
        // Estimation pas encore posée : pas de surmenage.
        continue;
      }
      var suite = <(int, double)>[
        for (final x in mm.forme)
          if (x.$1 != jour) x,
        (jour, _forme(exId)),
      ];
      while (suite.length > 3) {
        suite.removeAt(0);
      }
      if (suite.length == 3 &&
          jour - suite[0].$1 <= _n('surmenage_fenetre_j')) {
        final limite = suite[0].$2 + math.log(1 - dbl(s['surmenage_baisse']));
        if (suite[1].$2 <= limite && suite[2].$2 <= limite) {
          final meilleure = suite[1].$2 > suite[2].$2
              ? suite[1].$2
              : suite[2].$2;
          mm.alerteJour = jour;
          mm.alertePart = math.exp(meilleure - suite[0].$2);
          suite = [suite[2]];
        }
      }
      mm.forme = suite;
    }
  }

  /// Ce que la séance dit de l'endurance (`EnduranceHistory.of`) : jour
  /// d'entraînement, course, course dure, conditionnement dur, vitesse de
  /// course.
  void _fermerEndurance(List<Object?> sets) {
    final jour = this.jour;
    final utiles = <Json>[
      for (final x0 in sets)
        if (jm(x0)['kind'] != 'warmup' && !vrai(jm(x0)['excluded'])) jm(x0),
    ];
    for (final x0 in sets) {
      final x = jm(x0);
      if (vrai(x['excluded']) ||
          _nature(x['exerciseId'] as String) != 'course') {
        continue;
      }
      final mv = x['distanceMeters'] as num?;
      final tv = x['seconds'] as num?;
      if (mv != null && tv != null && mv > 0 && tv > 0) {
        courseMetres += mv;
        courseSecondes += tv;
      }
    }
    final vitesse = _vitesse();
    var secondes = 0.0;
    num? pire;
    num? cible;
    var durWod = false;
    var dure = false;
    for (final x in utiles) {
      final n = _nature(x['exerciseId'] as String);
      final f = x['flames'] as num?;
      if (n == 'conditionnement' &&
          f != null &&
          f >= _n('endurance_dure_flammes')) {
        durWod = true;
      }
      if (n != 'course') {
        continue;
      }
      final tv = x['seconds'];
      final mv = x['distanceMeters'];
      secondes += tv != null
          ? dbl(tv)
          : (mv == null ? 0.0 : (mv as num) / vitesse);
      if (f != null && (pire == null || f > pire)) {
        pire = f;
        cible = dictOuVide(x['target'])['flames'] as num?;
        if (cible == null) {
          final plan = plans[x['slotId']];
          if (plan != null && plan['servi'] != null) {
            cible = jm(plan['servi'])['targetFlames'] as num?;
          }
        }
      }
      if (f != null && f >= _n('endurance_dure_flammes')) {
        dure = true;
      }
    }
    final bas = jour - 60;
    if (utiles.isNotEmpty) {
      joursActifs = [
        for (final j in joursActifs)
          if (j >= bas) j,
        jour,
      ];
    }
    if (secondes > 0) {
      courses = [
        for (final e in courses)
          if (e.$1 >= bas) e,
        (jour, secondes, pire, cible),
      ];
    }
    if (durWod) {
      joursDurs = [
        for (final j in joursDurs)
          if (j >= bas) j,
        jour,
      ];
    }
    if (dure) {
      joursCourseDure = [
        for (final j in joursCourseDure)
          if (j >= bas) j,
        jour,
      ];
    }
  }
}
