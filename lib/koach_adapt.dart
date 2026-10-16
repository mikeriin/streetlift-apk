// L11 (KT-058 à KT-064) — Koach étendu : adaptation au jour le jour.
//
// Règles pures et déterministes (aucune dépendance Flutter, aucune
// horloge : les dates sont passées en paramètre sous forme de numéros de
// jour civil). Données persistées : section optionnelle `adapt` de la
// sauvegarde. Contrat : docs/CONTRAT_L11.md.
import 'dart:math' as math;

import 'program_generator.dart';

/// Version du format de la section `adapt`.
const int kAdaptVersion = 1;

final RegExp _dayRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');
final RegExp _atRe = RegExp(
  r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(?::\d{2}(?:\.\d{1,6})?)?$',
);
final RegExp _keyRe = RegExp(r'^S([1-9]\d*)-J([1-7])$');

bool _okDay(Object? v) =>
    v is String && _dayRe.hasMatch(v) && DateTime.tryParse(v) != null;
bool _okAt(Object? v) =>
    v is String && _atRe.hasMatch(v) && DateTime.tryParse(v) != null;

/// Numéro de jour civil (indépendant de l'heure d'été).
int dayIndex(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;

/// Date civile d'un numéro de jour.
DateTime dayOfIndex(int i) {
  final u = DateTime.fromMillisecondsSinceEpoch(i * 86400000, isUtc: true);
  return DateTime(u.year, u.month, u.day);
}

String dayString(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Semaine civile (lundi → dimanche) d'un numéro de jour (le 1/1/1970
/// était un jeudi).
int weekIndexOfDay(int day) => (day + 3) ~/ 7;

// ================================================== autonomie (KT-063)

/// Modes d'autonomie (identiques au profil L8).
const kAutonomyModes = ['guided', 'assisted', 'expert'];

const kAutonomyExplanations = {
  'guided':
      'Koach applique lui-même les baisses et les adaptations de sécurité, '
      'avec un message et un bouton « Annuler ». Une hausse n’est appliquée '
      'que si la série était nettement plus facile que prévu. Aucune '
      'validation pendant la séance.',
  'assisted':
      'Koach propose, tu valides d’un tap (fonctionnement de Koach depuis '
      'la version 3.0).',
  'expert':
      'Tout est manuel : les suggestions de Koach restent visibles, tu '
      'règles toi-même tes charges et tes séries.',
};

/// Conduite de Koach face à une suggestion de charge pendant la séance :
/// `auto` (appliquée, annulable), `propose` (validée d'un tap), `info`
/// (visible, sans bouton d'application), `none` (rien à montrer).
///
/// [direction] : `up` ou `down` ; [reason] : règle D24 (`easy2` = RIR ≥
/// RIR visé + 2, seule hausse appliquée d'office en mode Guidé).
String autonomyAction(String mode, String direction, String reason) {
  switch (mode) {
    case 'guided':
      if (direction == 'down') return 'auto';
      return reason == 'easy2' ? 'auto' : 'none';
    case 'expert':
      return 'info';
    default:
      return 'propose';
  }
}

/// Adaptation de sécurité (reprise, maladie) : appliquée à la séance ?
/// [choice] : choix enregistré pour la séance (`applied`, `refused` ou
/// null).
bool safetyApplied(String mode, String? choice) => switch (mode) {
  'guided' => choice != 'refused',
  _ => choice == 'applied',
};

// ============================================ séance compressée (KT-058)

/// Élément d'une séance vu par la compression. Durées en secondes,
/// estimées par `training_estimate.dart` (effort et repos par série).
class CItem {
  final String id;

  /// `warmup`, `main`, `test`, `accessory`, `low` (circuit, travail
  /// spécifique), `prevention`, `cooldown`.
  final String role;
  final int sets;

  /// Séries déjà validées (compression pendant la séance).
  final int done;
  final double work, rest;

  /// Le nombre de séries peut changer (« 4×8 ») ; sinon l'exercice reste tel
  /// quel ou est retiré en entier.
  final bool reducible;
  final Set<String> groups;
  const CItem({
    required this.id,
    required this.role,
    required this.sets,
    this.done = 0,
    required this.work,
    required this.rest,
    this.reducible = true,
    this.groups = const {},
  });

  double get perSet => work + rest;
}

/// Résultat d'une compression.
class CPlan {
  final int minutes;

  /// Nouveau nombre de séries (exercices modifiés seulement).
  final Map<String, int> sets;
  final List<String> removed;
  final List<(String, String)> pairs;

  /// Échauffement ramené à 3 minutes (séance pas encore commencée).
  final bool warmup;

  /// Durées restantes estimées avant et après, en secondes.
  final double before, after;

  /// La durée demandée est tenue.
  final bool feasible;

  /// La séance tenait déjà dans le temps demandé : rien ne change.
  final bool unchanged;
  const CPlan({
    required this.minutes,
    required this.sets,
    required this.removed,
    required this.pairs,
    required this.warmup,
    required this.before,
    required this.after,
    required this.feasible,
    required this.unchanged,
  });

  Map<String, dynamic> toJson() => {
    'minutes': minutes,
    if (sets.isNotEmpty) 'sets': sets,
    if (removed.isNotEmpty) 'removed': removed,
    if (pairs.isNotEmpty)
      'pairs': [
        for (final p in pairs) [p.$1, p.$2],
      ],
    if (warmup) 'warmup': true,
  };
}

/// Paramètres de la compression (registre de validation, contrat L11 §9).
const kWarmupSeconds = 180.0;
const kTransitionSeconds = 45.0;
const kMainKeep = 2 / 3;

/// Série minimale d'un mouvement principal : au moins 2/3 des séries
/// prévues, jamais moins que les séries déjà faites.
int mainMinimum(int sets, int done) =>
    math.max(done, math.max(1, (sets * kMainKeep).ceil()));

/// Recompose une séance pour [minutes] (KT-058) : échauffement de 3 min,
/// prévention à 1 série (jamais supprimée), accessoires enchaînés deux par
/// deux sans groupe musculaire commun, retrait des exercices de plus
/// faible priorité (fin de séance d'abord), puis mouvements principaux
/// ramenés vers 2/3 de leurs séries. Déterministe.
CPlan compressSession(List<CItem> items, int minutes, {bool started = false}) {
  final budget = minutes * 60.0;
  double remaining(CItem it, int n) => math.max(0, n - it.done) * it.perSet;

  // Durée d'origine (échauffement prévu inclus quand il est chiffré).
  double total(
    Map<String, int> sets,
    Set<String> removed,
    List<(String, String)> pairs, {
    required bool shortWarmup,
  }) {
    var t = 0.0;
    var blocks = 0;
    final paired = <String>{};
    for (final p in pairs) {
      paired
        ..add(p.$1)
        ..add(p.$2);
    }
    final byId = {for (final it in items) it.id: it};
    for (final p in pairs) {
      final a = byId[p.$1]!, b = byId[p.$2]!;
      final rounds = math.max(
        math.max(0, sets[a.id]! - a.done),
        math.max(0, sets[b.id]! - b.done),
      );
      if (rounds == 0) continue;
      t += rounds * (a.work + b.work + math.max(a.rest, b.rest));
      blocks++;
    }
    for (final it in items) {
      if (removed.contains(it.id) || paired.contains(it.id)) continue;
      if (shortWarmup && it.role == 'warmup') continue;
      final r = remaining(it, sets[it.id]!);
      if (r <= 0) continue;
      t += r;
      blocks++;
    }
    if (shortWarmup && !started) {
      t += kWarmupSeconds;
      blocks++;
    }
    return t + math.max(0, blocks - 1) * kTransitionSeconds;
  }

  final full = {for (final it in items) it.id: it.sets};
  final before = total(full, const {}, const [], shortWarmup: false);
  if (before <= budget) {
    return CPlan(
      minutes: minutes,
      sets: const {},
      removed: const [],
      pairs: const [],
      warmup: false,
      before: before,
      after: before,
      feasible: true,
      unchanged: true,
    );
  }

  final sets = Map<String, int>.of(full);
  final removed = <String>{};
  // 1. Échauffement réduit, retour au calme retiré, prévention à 1 série.
  for (final it in items) {
    if (it.role == 'warmup' && it.done == 0) removed.add(it.id);
    if (it.role == 'cooldown' && it.done == 0) removed.add(it.id);
    if (it.role == 'prevention' && it.reducible) {
      sets[it.id] = math.max(it.done, math.min(1, it.sets));
    }
  }
  // 2. Accessoires enchaînés deux par deux, sans conflit musculaire.
  List<(String, String)> pairUp() {
    final out = <(String, String)>[];
    final used = <String>{};
    final acc = [
      for (final it in items)
        if ((it.role == 'accessory' || it.role == 'low') &&
            it.done == 0 &&
            !removed.contains(it.id))
          it,
    ];
    for (var i = 0; i < acc.length; i++) {
      final a = acc[i];
      if (used.contains(a.id)) continue;
      for (var k = i + 1; k < acc.length; k++) {
        final b = acc[k];
        if (used.contains(b.id)) continue;
        if (a.groups.isEmpty ||
            b.groups.isEmpty ||
            a.groups.intersection(b.groups).isNotEmpty) {
          continue;
        }
        out.add((a.id, b.id));
        used
          ..add(a.id)
          ..add(b.id);
        break;
      }
    }
    return out;
  }

  var pairs = pairUp();
  double now() => total(sets, removed, pairs, shortWarmup: true);

  // 3. Retrait des exercices de plus faible priorité : circuits et travail
  // spécifique, puis accessoires, de la fin de la séance vers le début.
  final removable = [
    for (final it in items.reversed)
      if (it.role == 'low' && it.done == 0) it,
    for (final it in items.reversed)
      if (it.role == 'accessory' && it.done == 0) it,
  ];
  for (final it in removable) {
    if (now() <= budget) break;
    removed.add(it.id);
    pairs = pairUp();
  }
  // 4. Mouvements principaux ramenés vers 2/3 de leurs séries, une série
  // à la fois (le plus fourni d'abord, en partant de la fin).
  while (now() > budget) {
    CItem? pick;
    var room = 0;
    for (final it in items.reversed) {
      if (it.role != 'main' || !it.reducible) continue;
      final r = sets[it.id]! - mainMinimum(it.sets, it.done);
      if (r > room) {
        room = r;
        pick = it;
      }
    }
    if (pick == null) break;
    sets[pick.id] = sets[pick.id]! - 1;
  }
  final after = now();
  return CPlan(
    minutes: minutes,
    sets: {
      for (final e in sets.entries)
        if (e.value != full[e.key] && !removed.contains(e.key)) e.key: e.value,
    },
    removed: [
      for (final it in items)
        if (removed.contains(it.id)) it.id,
    ],
    pairs: pairs,
    warmup: !started,
    before: before,
    after: after,
    feasible: after <= budget,
    unchanged: false,
  );
}

/// Prescription dont le nombre de séries peut être réduit (« 4×8 ») : pas
/// les myo-reps (« 1×12 puis 4×(4) »), montées ni EMOM.
bool reducibleText(String text) {
  final t = text.toLowerCase();
  return RegExp(r'^\s*\d+\s*[×x]').hasMatch(t) &&
      !t.contains('puis') &&
      !t.contains('montée') &&
      !t.contains('emom');
}

/// Nombre de séries lu dans la prescription (« 4×8 » → 4), sinon null.
int? leadingSets(String text) {
  final m = RegExp(r'^\s*(\d+)\s*[×x]').firstMatch(text);
  return m == null ? null : int.parse(m.group(1)!);
}

// =============================== variante et échange d'exercice (KT-059)

/// Motifs d'un échange.
const kSwapMotives = <(String, String)>[
  ('busy', 'Matériel pris ou absent'),
  ('pain', 'Gêne ou douleur'),
  ('wish', 'Envie de changer'),
];

/// Jusqu'à [count] substituts classés (KT-059) : même type de mouvement,
/// difficulté ±1, matériel disponible, au moins un groupe musculaire
/// principal commun, contrainte articulaire ≤ l'original pour chaque
/// articulation si le motif est une douleur, jamais un exercice détesté.
/// Classement : groupes communs, écart de difficulté, même mode de charge,
/// démonstration animée, puis identifiant (déterministe).
List<GenExercise> swapCandidates(
  GenCatalog catalog,
  GenExercise original, {
  required Set<String> equipment,
  String motive = 'wish',
  Set<String> disliked = const {},
  Set<String> exclude = const {},
  int count = 3,
}) {
  final scored = <(GenExercise, int)>[];
  for (final e in catalog.all) {
    if (e.id == original.id || exclude.contains(e.id)) continue;
    if (!e.generator || e.duplicateOf != null || e.role != 'exercice') {
      continue;
    }
    if (disliked.contains(e.id)) continue;
    if (e.type != original.type) continue;
    if ((e.difficulty - original.difficulty).abs() > 1) continue;
    if (!e.materiel.every(equipment.contains)) continue;
    final shared = e.groups.toSet().intersection(original.groups.toSet());
    if (original.groups.isNotEmpty && shared.isEmpty) continue;
    if (motive == 'pain') {
      var ok = true;
      for (final j in e.joints.entries) {
        if (j.value > (original.joints[j.key] ?? 0)) {
          ok = false;
          break;
        }
      }
      if (!ok) continue;
    }
    var score = 10 * shared.length;
    score -= 3 * (e.difficulty - original.difficulty).abs();
    if (e.loadMode == original.loadMode) score += 2;
    if (e.animated) score += 1;
    if (motive == 'pain') {
      // Moins de contrainte articulaire : mieux classé.
      final a = e.joints.values.fold<int>(0, (s, v) => s + v);
      final b = original.joints.values.fold<int>(0, (s, v) => s + v);
      score += math.max(0, b - a);
    }
    scored.add((e, score));
  }
  scored.sort((a, b) {
    final c = b.$2.compareTo(a.$2);
    return c != 0 ? c : a.$1.id.compareTo(b.$1.id);
  });
  return [for (final s in scored.take(count)) s.$1];
}

/// Charge initiale prudente d'un substitut (KT-059) : 80 % de la charge de
/// l'original si les deux se chargent de la même façon, arrondie au pas
/// inférieur (1 kg sous 10 kg, sinon 2,5 kg) ; null sinon (première série
/// de calibrage au poids choisi).
double? prudentLoad(double? originalKg, String originalMode, String mode) {
  if (originalKg == null || originalKg <= 0) return null;
  if (originalMode != mode) return null;
  if (mode == 'poids_de_corps' || mode == 'assistance') return null;
  final raw = originalKg * 0.8;
  final step = raw < 10 ? 1.0 : 2.5;
  final v = (raw / step).floor() * step;
  return v > 0 ? v : null;
}

// ======================== séances manquées, vacances, maladie (KT-060)

/// Règle de reprise selon la durée de l'arrêt.
class ResumeRule {
  final int gap;

  /// 0 : aucune ; 1 : 7-13 j ; 2 : 14-27 j ; 3 : 28 j et plus.
  final int band;
  final double loadCut;
  final int setCut;
  final bool calibrationSet;
  final bool calibrationWeek;
  const ResumeRule(
    this.gap,
    this.band,
    this.loadCut,
    this.setCut,
    this.calibrationSet,
    this.calibrationWeek,
  );
  bool get active => band > 0;
}

/// Paramètres de reprise (registre de validation).
ResumeRule resumeRule(int gap) {
  if (gap >= 28) return ResumeRule(gap, 3, .30, 0, true, true);
  if (gap >= 14) return ResumeRule(gap, 2, .20, 0, true, false);
  if (gap >= 7) return ResumeRule(gap, 1, .10, 1, false, false);
  return ResumeRule(gap, 0, 0, 0, false, false);
}

/// Épisode de reprise d'une séance datée [session] : dernier arrêt d'au
/// moins 7 jours entre deux jours d'entraînement de [days] (hors cette
/// séance), avant [session]. Renvoie (premier jour de la reprise, durée de
/// l'arrêt) ou null (aucun arrêt, ou aucun entraînement avant).
(int, int)? resumeEpisode(List<int> days, int session) {
  final before = <int>{
    for (final d in days)
      if (d < session) d,
  }.toList()..sort();
  if (before.isEmpty) return null;
  final points = [...before, session];
  for (var i = points.length - 1; i > 0; i--) {
    final gap = points[i] - points[i - 1];
    if (gap >= 7) return (points[i], gap);
  }
  return null;
}

/// Horizon au-delà duquel une reprise n'est plus appliquée (un mouvement
/// jamais retravaillé ne reste pas allégé indéfiniment).
const kResumeHorizonDays = 42;

/// Séance de reprise : réductions à appliquer pour un mouvement principal.
/// [movementDays] : jours (depuis le début de la reprise, hors cette
/// séance) où ce mouvement a été travaillé.
bool resumeAppliesTo(
  ResumeRule rule,
  int episodeStart,
  int session,
  List<int> movementDays,
) {
  if (!rule.active) return false;
  if (session - episodeStart > kResumeHorizonDays) return false;
  if (rule.calibrationWeek) return session - episodeStart < 7;
  return !movementDays.any((d) => d >= episodeStart && d < session);
}

/// Retour de maladie : première semaine à volume −30 % et RIR +1.
const kIllnessVolume = .70;
const kIllnessDays = 7;

/// Le jour [day] tombe dans la semaine de retour d'une maladie terminée le
/// jour [returns] (premier jour hors pause).
bool illnessRecovery(List<int> returns, int day) =>
    returns.any((r) => day >= r && day < r + kIllnessDays);

/// Séance « suivante » quand le plan glisse (KT-060) : première journée
/// d'entraînement prévue après la dernière journée faite, si sa date est
/// passée. [planned] : (index d'ordre S·J, jour prévu), triés ; [done] :
/// index d'ordre des journées faites. Renvoie (index, jours de retard).
(int, int)? slideProposal(
  List<(int order, int day)> planned,
  Set<int> done,
  int today,
) {
  final last = done.isEmpty ? -1 : done.reduce(math.max);
  for (final p in planned) {
    if (p.$1 <= last || done.contains(p.$1)) continue;
    final late = today - p.$2;
    return late >= 1 ? (p.$1, late) : null;
  }
  return null;
}

// ============================================== assiduité (KT-061)

/// Taux de séances faites sur une fenêtre de [window] jours finissant la
/// veille de [today] ; jours en pause exclus. Null si moins de 4 séances
/// prévues (données insuffisantes).
double? adherenceRate(
  List<(int day, bool done)> planned,
  int today, {
  int window = 28,
  Set<int> paused = const {},
  int offset = 0,
}) {
  final end = today - offset, start = end - window;
  var n = 0, ok = 0;
  for (final p in planned) {
    if (p.$1 < start || p.$1 >= end || paused.contains(p.$1)) continue;
    n++;
    if (p.$2) ok++;
  }
  if (n < 4) return null;
  return ok / n;
}

/// Conseil d'assiduité : `fewer` (< 60 %), `more` (≥ 90 % sur deux
/// fenêtres de 4 semaines avec progression), `none` sinon, `unknown` sans
/// données suffisantes.
String adherenceAdvice(double? now, double? previous, bool progressed) {
  if (now == null) return 'unknown';
  if (now < .60) return 'fewer';
  if (now >= .90 && previous != null && previous >= .90 && progressed) {
    return 'more';
  }
  return 'none';
}

// ================================================== plateau (KT-062)

/// Pente relative par semaine (moindres carrés, rapportée à la moyenne).
/// [points] : (semaine, estimation). Null si moins de 2 points.
double? relativeSlope(List<(double, double)> points) {
  if (points.length < 2) return null;
  final n = points.length.toDouble();
  final mx = points.fold<double>(0, (s, p) => s + p.$1) / n;
  final my = points.fold<double>(0, (s, p) => s + p.$2) / n;
  if (my <= 0) return null;
  var sxy = 0.0, sxx = 0.0;
  for (final p in points) {
    sxy += (p.$1 - mx) * (p.$2 - my);
    sxx += (p.$1 - mx) * (p.$1 - mx);
  }
  if (sxx == 0) return null;
  return (sxy / sxx) / my;
}

/// Seuil de plateau : moins de +0,5 % par semaine.
const kPlateauSlope = .005;

/// Plateau (KT-062) : sur les semaines [current − 3 … current], au moins 3
/// estimations dont celle de [current] ou de la semaine précédente, pente
/// < +0,5 %/semaine, assiduité ≥ 80 %, aucun signal de fatigue, aucune
/// semaine de décharge dans la fenêtre.
bool plateauDetected(
  Map<int, double> weekly,
  int current, {
  required double? adherence,
  required bool fatigue,
  required bool deload,
}) {
  if (fatigue || deload) return false;
  if (adherence == null || adherence < .80) return false;
  final pts = <(double, double)>[
    for (var w = current - 3; w <= current; w++)
      if (weekly[w] != null) (w.toDouble(), weekly[w]!),
  ];
  if (pts.length < 3) return false;
  if (weekly[current] == null && weekly[current - 1] == null) return false;
  final s = relativeSlope(pts);
  return s != null && s < kPlateauSlope;
}

/// Intervention proposée selon le niveau (0 débutant … 4 expert).
String plateauKind(int level) => level <= 1
    ? 'technique'
    : level == 2
    ? 'range'
    : 'deload';

const kPlateauTexts = {
  'technique':
      'Point technique : relis les points clés de l’exercice et filme une '
      'série si tu peux. Varie les répétitions : une séance avec 2 '
      'répétitions de plus et une série de moins, puis la séance habituelle.',
  'range':
      'Change de plage de répétitions (par exemple 6-8 au lieu de 8-12) ou '
      'passe à une variante proche pendant un cycle.',
  'deload':
      'Semaine de décharge (séries × 0,6, charges −10 %), puis un nouveau '
      'bloc orienté sur ton point faible.',
};

/// Estimation d'une série (repère d'entraînement, formule d'Epley) :
/// masse × (1 + (répétitions + RIR) / 30) ; sans masse : répétitions + RIR.
double setEstimate(double? mass, int reps, double rir) {
  final n = reps + rir;
  if (mass == null || mass <= 0) return n;
  return mass * (1 + n / 30);
}

// ============================== charge de séance simplifiée (KT-064)

/// Libellés de l'échelle de difficulté globale (0-10).
const kDifficultyLabels = {
  0: 'Repos',
  1: 'Très facile',
  2: 'Facile',
  3: 'Modéré',
  4: 'Un peu dur',
  5: 'Dur',
  6: 'Dur +',
  7: 'Très dur',
  8: 'Très dur +',
  9: 'Presque maximal',
  10: 'Maximal',
};

/// Charge de séance = difficulté × durée (minutes).
double sessionLoadOf(int difficulty, int minutes) =>
    (difficulty * minutes).toDouble();

/// Seuil de prudence : charge de la semaine > 1,5 × moyenne des 4
/// semaines précédentes.
const kLoadRatio = 1.5;

/// Prudence (KT-064) : (ratio, moyenne) si la semaine [current] dépasse
/// 1,5 fois la moyenne des 4 semaines précédentes (semaines sans séance
/// notée comptées à 0), avec au moins 2 de ces semaines renseignées.
(double, double)? loadCaution(Map<int, double> weekly, int current) {
  final now = weekly[current];
  if (now == null || now <= 0) return null;
  var sum = 0.0, filled = 0;
  for (var w = current - 4; w < current; w++) {
    final v = weekly[w];
    if (v != null && v > 0) {
      sum += v;
      filled++;
    }
  }
  if (filled < 2) return null;
  final mean = sum / 4;
  if (mean <= 0) return null;
  final ratio = now / mean;
  return ratio > kLoadRatio ? (ratio, mean) : null;
}

/// Allègement proposé après un message de prudence : volume × 0,8 jusqu'à
/// la fin de la semaine civile.
const kLightenVolume = .80;

/// Séances 20 % plus courtes (assiduité < 60 %).
const kShorterFactor = .80;

// ============================== séances d'entretien (vacances, KT-060)

/// Matériel toujours disponible en vacances (sans matériel).
const kNoEquipment = {'aucun', 'sol_degage', 'mur', 'support_stable'};

/// Séance d'entretien de 20 minutes sans matériel : un exercice par type
/// (poussée, squat, fente, charnière, gainage), difficulté la plus proche
/// de la cible du niveau, sans saut. Déterministe.
List<GenExercise> maintenanceExercises(GenCatalog catalog, int level) {
  final target = const [2, 3, 4, 5, 5][level.clamp(0, 4)];
  const types = [
    'poussee_horizontale',
    'squat',
    'fente',
    'charniere_hanche',
    'gainage_anti_extension',
  ];
  final out = <GenExercise>[];
  for (final t in types) {
    GenExercise? best;
    for (final e in catalog.all) {
      if (e.type != t || !e.usable || e.impact) continue;
      if (!e.materiel.every(kNoEquipment.contains)) continue;
      if (best == null) {
        best = e;
        continue;
      }
      final a = (e.difficulty - target).abs(),
          b = (best.difficulty - target).abs();
      if (a < b || (a == b && e.id.compareTo(best.id) < 0)) best = e;
    }
    if (best != null) out.add(best);
  }
  return out;
}

// ======================================================== données

/// Pause en cours (vacances ou maladie).
class AdaptPause {
  final String kind; // vacation | illness
  final String from; // AAAA-MM-JJ
  final String? to; // premier jour de retour (pauses terminées)
  const AdaptPause(this.kind, this.from, [this.to]);
  Map<String, dynamic> toJson() => {
    'kind': kind,
    'from': from,
    if (to != null) 'to': to,
  };
}

/// Événement daté (historique des adaptations, annulables).
class AdaptEvent {
  final String at, kind;
  final Map<String, dynamic> detail;
  String status; // applied | undone
  AdaptEvent(this.at, this.kind, this.detail, [this.status = 'applied']);
  Map<String, dynamic> toJson() => {
    'at': at,
    'kind': kind,
    'status': status,
    if (detail.isNotEmpty) 'detail': detail,
  };
}

/// Section `adapt` de la sauvegarde (écrite seulement si utilisée).
class AdaptData {
  int version = kAdaptVersion;

  /// Mode choisi sans profil (installation sans profil L8).
  String? autonomy;

  /// Adaptations par séance (`S·J`) : compression, échanges, lieu, choix
  /// de reprise.
  final Map<String, Map<String, dynamic>> sessions = {};
  AdaptPause? pause;
  final List<AdaptPause> pauses = [];

  /// Séances 20 % plus courtes (assiduité), depuis cet horodatage.
  String? shorter;

  /// Allègement × 0,8 : jours civils inclus [from, to].
  String? lightenFrom, lightenTo;

  /// Difficulté globale par séance : {rpe 0-10, minutes}.
  final Map<String, Map<String, int>> difficulty = {};
  final List<AdaptEvent> events = [];

  /// Propositions écartées (« Plus tard ») : identifiant → horodatage.
  final Map<String, String> dismissed = {};

  static const maxSessions = 400,
      maxDifficulty = 2000,
      maxEvents = 500,
      maxDismissed = 500;

  bool get pristine =>
      autonomy == null &&
      sessions.isEmpty &&
      pause == null &&
      pauses.isEmpty &&
      shorter == null &&
      lightenFrom == null &&
      difficulty.isEmpty &&
      events.isEmpty &&
      dismissed.isEmpty;

  Map<String, dynamic> toJson() => {
    'v': version,
    if (autonomy != null) 'autonomy': autonomy,
    if (sessions.isNotEmpty) 'sessions': sessions,
    if (pause != null) 'pause': pause!.toJson(),
    if (pauses.isNotEmpty) 'pauses': [for (final p in pauses) p.toJson()],
    if (shorter != null) 'shorter': shorter,
    if (lightenFrom != null) 'lighten': {'from': lightenFrom, 'to': lightenTo},
    if (difficulty.isNotEmpty) 'difficulty': difficulty,
    if (events.isNotEmpty) 'events': [for (final e in events) e.toJson()],
    if (dismissed.isNotEmpty) 'dismissed': dismissed,
  };

  static bool _simple(Object? v) =>
      v == null ||
      v is bool ||
      (v is num && v.isFinite) ||
      (v is String && v.length <= 200);

  static bool _okSession(Object? v) {
    if (v is! Map) return false;
    for (final e in v.entries) {
      final k = e.key, x = e.value;
      final ok = switch (k) {
        'minutes' => x is int && x >= 5 && x <= 600,
        'at' => _okAt(x),
        'warmup' => x is bool,
        'place' => x is String && x.length <= 40,
        'resume' => x == 'applied' || x == 'refused',
        'sets' =>
          x is Map &&
              x.length <= 60 &&
              x.entries.every(
                (s) =>
                    s.key is String &&
                    (s.key as String).length <= 80 &&
                    s.value is int &&
                    (s.value as int) >= 1 &&
                    (s.value as int) <= 100,
              ),
        'removed' =>
          x is List &&
              x.length <= 60 &&
              x.every((i) => i is String && i.length <= 80),
        'pairs' =>
          x is List &&
              x.length <= 30 &&
              x.every(
                (p) =>
                    p is List &&
                    p.length == 2 &&
                    p.every((i) => i is String && i.length <= 80),
              ),
        'swaps' =>
          x is Map &&
              x.length <= 60 &&
              x.entries.every(
                (s) =>
                    s.key is String &&
                    (s.key as String).length <= 80 &&
                    s.value is Map &&
                    (s.value as Map)['to'] is String &&
                    (s.value as Map)['name'] is String &&
                    ((s.value as Map)['name'] as String).length <= 200 &&
                    (s.value as Map).length <= 6 &&
                    (s.value as Map).values.every(_simple) &&
                    ((s.value as Map)['kg'] == null ||
                        ((s.value as Map)['kg'] is num &&
                            ((s.value as Map)['kg'] as num) >= 0 &&
                            ((s.value as Map)['kg'] as num) <= 1000)),
              ),
        _ => false,
      };
      if (!ok) return false;
    }
    return true;
  }

  static AdaptPause? _pause(Object? v, {bool closed = false}) {
    if (v is! Map) return null;
    final kind = v['kind'], from = v['from'], to = v['to'];
    if (kind != 'vacation' && kind != 'illness') return null;
    if (!_okDay(from)) return null;
    if (closed ? !_okDay(to) : to != null) return null;
    if (closed && (to as String).compareTo(from as String) < 0) return null;
    return AdaptPause(kind as String, from as String, to as String?);
  }

  /// Lecture de la section. [strict] (import d'un fichier) : toute valeur
  /// hors contrat lève [FormatException] ; sinon (démarrage) l'entrée est
  /// ignorée et comptée dans [issues].
  static AdaptData fromJson(
    Object? raw, {
    bool strict = false,
    List<String>? issues,
  }) {
    final out = AdaptData();
    if (raw == null) return out;
    void bad(String what) {
      if (strict) throw FormatException('Adaptations invalides : $what.');
      issues?.add(what);
    }

    if (raw is! Map) {
      bad('section');
      return out;
    }
    final v = raw['v'];
    if (v != null && (v is! int || v < 1 || v > kAdaptVersion)) {
      bad('version');
      return out;
    }
    final a = raw['autonomy'];
    if (a != null) {
      if (a is String && kAutonomyModes.contains(a)) {
        out.autonomy = a;
      } else {
        bad('mode');
      }
    }
    final sessions = raw['sessions'];
    if (sessions != null) {
      if (sessions is! Map || (strict && sessions.length > maxSessions)) {
        bad('séances');
      } else {
        for (final e in sessions.entries) {
          if (e.key is String &&
              _keyRe.hasMatch(e.key as String) &&
              _okSession(e.value)) {
            out.sessions[e.key as String] = Map<String, dynamic>.from(
              e.value as Map,
            );
          } else {
            bad('séance ${e.key}');
          }
        }
      }
    }
    final p = raw['pause'];
    if (p != null) {
      final x = _pause(p);
      if (x == null) {
        bad('pause');
      } else {
        out.pause = x;
      }
    }
    final ps = raw['pauses'];
    if (ps != null) {
      if (ps is! List || (strict && ps.length > maxEvents)) {
        bad('pauses');
      } else {
        for (final i in ps) {
          final x = _pause(i, closed: true);
          if (x == null) {
            bad('pause terminée');
          } else {
            out.pauses.add(x);
          }
        }
      }
    }
    final s = raw['shorter'];
    if (s != null) {
      if (_okAt(s)) {
        out.shorter = s as String;
      } else {
        bad('séances plus courtes');
      }
    }
    final l = raw['lighten'];
    if (l != null) {
      if (l is Map &&
          _okDay(l['from']) &&
          _okDay(l['to']) &&
          (l['to'] as String).compareTo(l['from'] as String) >= 0) {
        out
          ..lightenFrom = l['from'] as String
          ..lightenTo = l['to'] as String;
      } else {
        bad('allègement');
      }
    }
    final d = raw['difficulty'];
    if (d != null) {
      if (d is! Map || (strict && d.length > maxDifficulty)) {
        bad('difficultés');
      } else {
        for (final e in d.entries) {
          final x = e.value;
          if (e.key is String &&
              (e.key as String).length <= 60 &&
              x is Map &&
              x['rpe'] is int &&
              (x['rpe'] as int) >= 0 &&
              (x['rpe'] as int) <= 10 &&
              x['minutes'] is int &&
              (x['minutes'] as int) >= 1 &&
              (x['minutes'] as int) <= 600 &&
              x.length == 2) {
            out.difficulty[e.key as String] = {
              'rpe': x['rpe'] as int,
              'minutes': x['minutes'] as int,
            };
          } else {
            bad('difficulté ${e.key}');
          }
        }
      }
    }
    final ev = raw['events'];
    if (ev != null) {
      if (ev is! List || (strict && ev.length > maxEvents)) {
        bad('historique');
      } else {
        for (final x in ev) {
          if (x is Map &&
              _okAt(x['at']) &&
              x['kind'] is String &&
              (x['kind'] as String).length <= 40 &&
              (x['status'] == 'applied' || x['status'] == 'undone') &&
              (x['detail'] == null ||
                  (x['detail'] is Map &&
                      (x['detail'] as Map).length <= 20 &&
                      (x['detail'] as Map).keys.every((k) => k is String) &&
                      (x['detail'] as Map).values.every(_simple)))) {
            out.events.add(
              AdaptEvent(
                x['at'] as String,
                x['kind'] as String,
                Map<String, dynamic>.from((x['detail'] as Map?) ?? const {}),
                x['status'] as String,
              ),
            );
          } else {
            bad('événement');
          }
        }
      }
    }
    final dm = raw['dismissed'];
    if (dm != null) {
      if (dm is! Map || (strict && dm.length > maxDismissed)) {
        bad('propositions écartées');
      } else {
        for (final e in dm.entries) {
          if (e.key is String &&
              (e.key as String).length <= 200 &&
              _okAt(e.value)) {
            out.dismissed[e.key as String] = e.value as String;
          } else {
            bad('proposition écartée');
          }
        }
      }
    }
    // Démarrage : listes trop longues bornées aux entrées les plus récentes.
    if (out.events.length > maxEvents) {
      out.events.removeRange(0, out.events.length - maxEvents);
    }
    return out;
  }
}

// ======================= une séance de plus ou de moins (KT-061)

/// Jour retiré pour « une séance de moins » : celui qui laisse les séances
/// restantes les mieux espacées (le plus serré d'abord, puis le dernier).
int? dayToDrop(List<int> days) {
  if (days.length <= 1) return null;
  final sorted = [...days]..sort();
  int? best;
  var bestGap = 99;
  for (final d in sorted) {
    var gap = 99;
    for (final o in sorted) {
      if (o == d) continue;
      final g = ((o - d) % 7 + 7) % 7;
      final h = ((d - o) % 7 + 7) % 7;
      gap = math.min(gap, math.min(g, h));
    }
    if (gap < bestGap || (gap == bestGap && (best == null || d > best))) {
      bestGap = gap;
      best = d;
    }
  }
  return best;
}

/// Jour ajouté pour « une séance de plus » : le premier jour libre sans
/// séance la veille ni le lendemain, sinon le premier jour libre.
int? dayToAdd(List<int> days) {
  if (days.length >= 7) return null;
  bool free(int d) => !days.contains(d);
  int wrap(int d) => (d - 1 + 7) % 7 + 1;
  for (var d = 1; d <= 7; d++) {
    if (free(d) && free(wrap(d - 1)) && free(wrap(d + 1))) return d;
  }
  for (var d = 1; d <= 7; d++) {
    if (free(d)) return d;
  }
  return null;
}
