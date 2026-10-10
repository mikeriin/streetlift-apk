// Couche « jeu » dérivée du journal : records personnels, attributs de
// personnage, série avec boucliers, objectifs adaptatifs, campagne (chapitres
// du programme), boss (semaines de tests), saisons, titres, rareté des badges
// et bilan de récompenses de fin de séance.
//
// Comme les XP, rien n'est persisté ici : tout se recalcule depuis les
// données, une sauvegarde réimportée donne exactement le même état. Le barème
// d'XP (progression.dart) n'est pas modifié ; les mécaniques ajoutées
// récompensent en titres et en visibilité (G2 : plus de crédits WOD).
import 'dart:math' as math;

import 'models.dart';
import 'progression.dart';
import 'search.dart' show normalizeText;
import 'store.dart' show SessionLog;

// ---------------------------------------------------------------------------
// Records personnels (par nom d'exercice)
// ---------------------------------------------------------------------------

/// Epley : 1RM estimé = charge × (1 + reps / 30). Poids de corps : la charge
/// vaut 0 et l'on compare les répétitions.
double e1rmOf(double kg, int reps) => kg <= 0 ? 0 : kg * (1 + reps / 30);

class ExerciseBests {
  double bestE1rm = 0;
  double bestKg = 0;
  int bestKgReps = 0;
  int bestReps = 0;
  int weightedSets = 0, bodyweightSets = 0;
}

double? _kg(String s) => double.tryParse(s.trim().replaceAll(',', '.'));
int? _reps(String s) => int.tryParse(s.trim());

/// Meilleures performances par exercice, toutes séances confondues (clé de
/// séance `excludeKey` ignorée : la séance en cours).
Map<String, ExerciseBests> exerciseBests(
  Map<String, SessionLog> logs, {
  String? excludeKey,
}) {
  final out = <String, ExerciseBests>{};
  for (final entry in logs.entries) {
    if (entry.key == excludeKey) continue;
    final log = entry.value;
    for (final ex in log.ex.entries) {
      final name = log.exerciseNames[ex.key];
      if (name == null || name.isEmpty) continue;
      final best = out.putIfAbsent(normalizeText(name), ExerciseBests.new);
      for (final set in ex.value.sets) {
        if (!set.done) continue;
        _fold(best, set.kg, set.reps);
      }
    }
  }
  return out;
}

void _fold(ExerciseBests best, String kgText, String repsText) {
  final reps = _reps(repsText) ?? 0;
  final kg = _kg(kgText) ?? 0;
  if (reps <= 0) return;
  if (kg > 0) {
    best.weightedSets++;
    final e = e1rmOf(kg, reps);
    if (e > best.bestE1rm) {
      best.bestE1rm = e;
      best.bestKg = kg;
      best.bestKgReps = reps;
    }
  } else {
    best.bodyweightSets++;
    if (reps > best.bestReps) best.bestReps = reps;
  }
}

/// Record battu par une série (charge / reps) face à l'historique d'un
/// exercice ; null si ce n'est pas un record ou s'il n'y a pas de référence.
class RecordHit {
  final String exercise;
  final bool weighted;
  final double kg;
  final int reps;
  final double previous; // 1RM estimé précédent, ou reps précédentes
  final double current;
  const RecordHit({
    required this.exercise,
    required this.weighted,
    required this.kg,
    required this.reps,
    required this.previous,
    required this.current,
  });

  String get label {
    String fmt(double v) => v == v.roundToDouble()
        ? v.toInt().toString()
        : v.toStringAsFixed(1).replaceAll('.', ',');
    return weighted
        ? '${fmt(kg)} kg × $reps (1RM estimé ${fmt(current)} kg, avant ${fmt(previous)})'
        : '$reps reps (avant ${previous.toInt()})';
  }
}

RecordHit? recordFor(
  Map<String, ExerciseBests> bests,
  String exercise,
  String kgText,
  String repsText,
) {
  final best = bests[normalizeText(exercise)];
  final reps = _reps(repsText) ?? 0;
  final kg = _kg(kgText) ?? 0;
  if (reps <= 0 || best == null) return null;
  if (kg > 0) {
    if (best.weightedSets == 0) return null;
    final e = e1rmOf(kg, reps);
    if (e <= best.bestE1rm) return null;
    return RecordHit(
      exercise: exercise,
      weighted: true,
      kg: kg,
      reps: reps,
      previous: best.bestE1rm,
      current: e,
    );
  }
  if (best.bodyweightSets == 0 || reps <= best.bestReps) return null;
  return RecordHit(
    exercise: exercise,
    weighted: false,
    kg: 0,
    reps: reps,
    previous: best.bestReps.toDouble(),
    current: reps.toDouble(),
  );
}

// ---------------------------------------------------------------------------
// Attributs de personnage
// ---------------------------------------------------------------------------

class GameAttribute {
  final String id, label, hint;
  final int score; // 0-100

  /// Entrées manquantes (KT-007) : `available` faux = aucune entrée, score
  /// sans valeur ; [note] explique ce qui manque (aussi pour un calcul
  /// partiel). Formules inchangées.
  final bool available;
  final String? note;
  const GameAttribute(
    this.id,
    this.label,
    this.score,
    this.hint, {
    this.available = true,
    this.note,
  });

  /// Niveau d'attribut 1-10 (un niveau tous les 10 points).
  int get level => (1 + score ~/ 10).clamp(1, 10);
  double get fraction => score / 100;
}

/// Interpolation linéaire par morceaux sur des points (x, score) croissants.
int curveScore(double value, List<(num, int)> points) {
  if (value <= points.first.$1) return points.first.$2;
  for (var i = 1; i < points.length; i++) {
    final x0 = points[i - 1].$1.toDouble(), y0 = points[i - 1].$2;
    final x1 = points[i].$1.toDouble(), y1 = points[i].$2;
    if (value <= x1) {
      final t = (value - x0) / (x1 - x0);
      return (y0 + (y1 - y0) * t).round();
    }
  }
  return points.last.$2;
}

const skillFamilies = <(String, String)>[
  ('muscle-up', r'muscle.?up'),
  ('handstand', r'hspu|handstand|atr\b|pike'),
  ('front lever', r'front lever'),
  ('back lever', r'back lever'),
  ('planche', r'planche(?! lest| lat| rkc| bras| avec| sur)|pseudo-planche'),
  ('l-sit', r'l-sit|v-sit|manna'),
  ('pistol', r'pistol|shrimp|skater'),
  ('flag', r'flag|drapeau'),
  ('archer', r'archer|typewriter|une main|one arm'),
  ('dragon', r'dragon'),
];

class CharacterSheet {
  final List<GameAttribute> attributes;
  const CharacterSheet(this.attributes);

  GameAttribute get force => attributes[0];
  GameAttribute get endurance => attributes[1];
  GameAttribute get technique => attributes[2];
  GameAttribute get regularite => attributes[3];

  /// Niveau global = moyenne arrondie des quatre niveaux d'attribut.
  int get powerLevel =>
      (attributes.fold(0, (s, a) => s + a.level) / attributes.length).round();

  static CharacterSheet compute({
    required Map<String, double> refs,
    required Map<String, SessionLog> logs,
    required Progression progression,
    required StreakInfo streak,
  }) {
    // Poids du corps non renseigné : aucun rapport de force calculé (pas de
    // poids arbitraire, KT-007). Formules inchangées quand il est connu.
    final bwRef = refs['B4'];
    final bw = bwRef != null && bwRef > 0 ? bwRef : 0.0;
    final hasBw = bw > 0;
    // --- Force : ratios (poids de corps + lest) / poids de corps.
    final force = <int>[];
    final pull = hasBw ? refs['B8'] : null;
    if (pull != null) {
      force.add(
        curveScore((bw + pull) / bw, [
          (1.0, 10),
          (1.3, 30),
          (1.6, 55),
          (1.9, 75),
          (2.2, 90),
          (2.5, 100),
        ]),
      );
    }
    final dip = hasBw ? refs['B9'] : null;
    if (dip != null) {
      force.add(
        curveScore((bw + dip) / bw, [
          (1.0, 10),
          (1.4, 30),
          (1.8, 55),
          (2.2, 75),
          (2.6, 90),
          (3.0, 100),
        ]),
      );
    }
    final mu = hasBw ? refs['B10'] : null;
    if (mu != null) {
      force.add(
        curveScore((bw + mu) / bw, [
          (1.0, 30),
          (1.15, 50),
          (1.3, 70),
          (1.5, 90),
          (1.7, 100),
        ]),
      );
    }
    final squat = hasBw ? refs['B11'] : null;
    if (squat != null) {
      force.add(
        curveScore(squat / bw, [
          (0.5, 0),
          (1.0, 20),
          (1.5, 50),
          (2.0, 75),
          (2.5, 95),
          (3.0, 100),
        ]),
      );
    }
    final forceScore = force.isEmpty ? 0 : _mean(force);
    final forceNote = !hasBw
        ? 'Indisponible : renseigne ton poids du corps et au moins une charge de référence (Références).'
        : force.isEmpty
        ? 'Indisponible : aucune charge de référence renseignée (Références).'
        : force.length < 4
        ? 'Calcul partiel : ${force.length} référence${force.length > 1 ? 's' : ''} de force sur 4.'
        : null;

    // --- Endurance : maxima de répétitions au poids de corps.
    final endurance = <int>[];
    void reps(String ref, List<(num, int)> points) {
      final v = refs[ref];
      if (v != null) endurance.add(curveScore(v, points));
    }

    reps('B16', [(0, 0), (1, 20), (5, 50), (10, 75), (15, 90), (20, 100)]);
    reps('B17', [
      (0, 0),
      (5, 10),
      (10, 30),
      (20, 55),
      (30, 75),
      (40, 90),
      (50, 100),
    ]);
    reps('B18', [
      (0, 0),
      (10, 10),
      (25, 30),
      (50, 60),
      (70, 75),
      (100, 95),
      (120, 100),
    ]);
    reps('B19', [
      (0, 0),
      (20, 10),
      (40, 35),
      (60, 55),
      (80, 75),
      (100, 90),
      (120, 100),
    ]);
    reps('B20', [(0, 0), (5, 10), (15, 40), (25, 65), (40, 90), (50, 100)]);
    final enduranceNote = endurance.isEmpty
        ? 'Maxima en répétitions non renseignés (Références) : endurance indisponible.'
        : endurance.length < 5
        ? 'Calcul partiel : ${endurance.length} maximum${endurance.length > 1 ? 's' : ''} sur 5.'
        : null;
    final enduranceScore = endurance.isEmpty ? 0 : _mean(endurance);

    // --- Technique : familles de skills travaillées + niveau au muscle-up.
    final families = <String>{};
    for (final log in logs.values) {
      for (final ex in log.ex.entries) {
        if (!ex.value.sets.any((s) => s.done)) continue;
        final name = normalizeText(log.exerciseNames[ex.key] ?? '');
        if (name.isEmpty) continue;
        for (final (family, pattern) in skillFamilies) {
          if (RegExp(pattern).hasMatch(name)) families.add(family);
        }
      }
    }
    var technique = 11 * families.length;
    // Lest au muscle-up : ne dépend pas du poids du corps.
    final muLoad = refs['B10'];
    if (muLoad != null) {
      technique += muLoad >= 20
          ? 40
          : muLoad >= 10
          ? 30
          : muLoad > 0
          ? 20
          : 12;
    }
    final techniqueScore = math.min(100, technique);

    // --- Régularité : série (boucliers compris), semaines récentes validées,
    // volume de séances.
    final int recent = progression.recentWeeks
        .where((w) => w.activeDays.length >= 2)
        .length;
    final int streakPart = 8 * math.min(streak.weeks, 6);
    final int sessionPart = math.min(4, progression.sessions ~/ 25);
    final int regularite = math
        .min(100, streakPart + 6 * recent + sessionPart)
        .toInt();

    return CharacterSheet([
      GameAttribute(
        'force',
        'Force',
        forceScore,
        'Lest relatif au poids de corps sur tractions, dips, muscle-up et squat (références Pilotage).',
        available: force.isNotEmpty,
        note: forceNote,
      ),
      GameAttribute(
        'endurance',
        'Endurance',
        enduranceScore,
        'Maxima de répétitions au poids de corps (références Pilotage).',
        note: enduranceNote,
      ),
      GameAttribute(
        'technique',
        'Technique',
        techniqueScore,
        'Familles de skills travaillées en séance et niveau au muscle-up.',
      ),
      GameAttribute(
        'regularite',
        'Régularité',
        regularite,
        'Semaines validées d\u2019affilée (boucliers compris), semaines actives sur les huit dernières.',
      ),
    ]);
  }
}

int _mean(List<int> values) =>
    (values.fold(0, (a, b) => a + b) / values.length).round();

// ---------------------------------------------------------------------------
// Série avec boucliers
// ---------------------------------------------------------------------------

/// Une semaine est validée à partir de deux jours actifs (règle inchangée).
/// Un bouclier couvre une semaine manquée : gagné toutes les trois semaines
/// validées d'affilée, deux en réserve au plus, consommé automatiquement. La
/// semaine en cours ne casse jamais la série avant le lundi suivant.
class StreakInfo {
  final int weeks;
  final int shields;
  final List<DateTime> shieldedWeeks;
  final bool currentValidated;
  const StreakInfo({
    required this.weeks,
    required this.shields,
    required this.shieldedWeeks,
    required this.currentValidated,
  });

  static StreakInfo compute(Map<DateTime, TrainingWeek> weeks, DateTime now) {
    final thisMonday = mondayOf(now);
    final active =
        weeks.entries
            .where((e) => e.value.activeDays.isNotEmpty)
            .map((e) => e.key)
            .toList()
          ..sort();
    if (active.isEmpty) {
      return const StreakInfo(
        weeks: 0,
        shields: 0,
        shieldedWeeks: [],
        currentValidated: false,
      );
    }
    var shields = 0, streak = 0;
    final used = <DateTime>[];
    var cursor = active.first;
    bool validated(DateTime monday) =>
        (weeks[monday]?.activeDays.length ?? 0) >= 2;
    while (cursor.isBefore(thisMonday)) {
      if (validated(cursor)) {
        streak++;
        if (streak % 3 == 0 && shields < 2) shields++;
      } else if (shields > 0 && streak > 0) {
        shields--;
        used.add(cursor);
      } else {
        streak = 0;
      }
      cursor = cursor.add(const Duration(days: 7));
    }
    final current = validated(thisMonday);
    if (current) {
      streak++;
      if (streak % 3 == 0 && shields < 2) shields++;
    }
    return StreakInfo(
      weeks: streak,
      shields: shields,
      shieldedWeeks: used,
      currentValidated: current,
    );
  }
}

// ---------------------------------------------------------------------------
// Objectifs adaptatifs
// ---------------------------------------------------------------------------

class WeeklyGoal {
  final int target, done;
  final bool manual;
  final double history; // moyenne des jours actifs, 4 semaines passées
  const WeeklyGoal({
    required this.target,
    required this.done,
    required this.manual,
    required this.history,
  });
  bool get reached => done >= target;
  double get fraction => target == 0 ? 0 : (done / target).clamp(0.0, 1.0);

  /// Cible = moyenne récente + 1 jour, entre 2 et le nombre de journées
  /// d'entraînement de la semaine de programme ; `manual` > 0 remplace le
  /// calcul (autonomie).
  static WeeklyGoal compute(Progression p, int programDays, int manual) {
    final past = p.recentWeeks.length > 1
        ? p.recentWeeks.sublist(
            math.max(0, p.recentWeeks.length - 5),
            p.recentWeeks.length - 1,
          )
        : const <TrainingWeek>[];
    final history = past.isEmpty
        ? 0.0
        : past.fold(0, (s, w) => s + w.activeDays.length) / past.length;
    final ceiling = math.max(2, programDays);
    var auto = history < 0.5
        ? 2
        : math.min(ceiling, math.max(2, history.round() + 1));
    if (history.round() >= ceiling) auto = ceiling;
    return WeeklyGoal(
      target: manual > 0 ? manual : auto,
      done: p.week.activeDays.length,
      manual: manual > 0,
      history: history,
    );
  }
}

/// Part de séries à valider pour « réussir » une séance : moyenne des trois
/// dernières séances + 5 points, entre 75 % et 100 % (90 % sans historique).
double sessionGoalFraction(Map<String, SessionLog> logs) {
  final done =
      logs.entries
          .where((e) => e.value.done && e.value.finishedAt != null)
          .toList()
        ..sort(
          (a, b) =>
              (b.value.finishedAt ?? '').compareTo(a.value.finishedAt ?? ''),
        );
  final ratios = <double>[];
  for (final entry in done.take(3)) {
    var total = 0, ok = 0;
    for (final ex in entry.value.ex.values) {
      total += ex.sets.length;
      ok += ex.sets.where((s) => s.done).length;
    }
    if (total > 0) ratios.add(ok / total);
  }
  if (ratios.isEmpty) return 0.9;
  final mean = ratios.fold(0.0, (a, b) => a + b) / ratios.length;
  return (mean + 0.05).clamp(0.75, 1.0);
}

// ---------------------------------------------------------------------------
// Campagne, boss, saisons
// ---------------------------------------------------------------------------

class Chapter {
  final String key, name, title;
  final int firstWeek, lastWeek, trainingDays, doneDays;
  final bool current;
  const Chapter({
    required this.key,
    required this.name,
    required this.title,
    required this.firstWeek,
    required this.lastWeek,
    required this.trainingDays,
    required this.doneDays,
    required this.current,
  });
  double get fraction =>
      trainingDays == 0 ? 0 : (doneDays / trainingDays).clamp(0.0, 1.0);

  /// Chapitre bouclé à 75 % des journées d'entraînement : les imprévus ne
  /// bloquent pas la campagne.
  bool get complete => trainingDays > 0 && doneDays / trainingDays >= 0.75;
}

const chapterTitles = <String, String>{
  'P0': 'Éclaireur',
  'B1': 'Forgeron',
  'B2': 'Maître d\u2019armes',
  'B3': 'Briseur de barre',
  'B4': 'Increvable',
  'B5': 'Athlète de pointe',
};

String chapterName(int index, String block) {
  final parts = block.split('—');
  final theme = (parts.length > 1 ? parts.last : block).trim();
  return index == 0 ? 'Prologue · $theme' : 'Chapitre $index · $theme';
}

List<Chapter> computeChapters(
  Program program,
  bool Function(int week, int day) isDone,
  int currentWeek,
) {
  final groups = <String, List<WeekPlan>>{};
  final order = <String>[];
  for (final w in program.weeks) {
    if (!groups.containsKey(w.blockKey)) order.add(w.blockKey);
    groups.putIfAbsent(w.blockKey, () => []).add(w);
  }
  final out = <Chapter>[];
  for (var i = 0; i < order.length; i++) {
    final weeks = groups[order[i]]!;
    var training = 0, done = 0;
    for (final w in weeks) {
      for (final d in w.days) {
        if (d.exercises.isEmpty) continue;
        training++;
        if (isDone(w.n, d.j)) done++;
      }
    }
    out.add(
      Chapter(
        key: order[i],
        name: chapterName(i, weeks.first.block),
        title: chapterTitles[order[i]] ?? 'Chapitre $i bouclé',
        firstWeek: weeks.first.n,
        lastWeek: weeks.last.n,
        trainingDays: training,
        doneDays: done,
        current: currentWeek >= weeks.first.n && currentWeek <= weeks.last.n,
      ),
    );
  }
  return out;
}

/// Un boss regroupe les journées de test d'une ou deux semaines consécutives.
class Boss {
  final String id, name, title;
  final int firstWeek, lastWeek;
  final List<(int, int)> tests; // (semaine, jour)
  final int done;
  const Boss({
    required this.id,
    required this.name,
    required this.title,
    required this.firstWeek,
    required this.lastWeek,
    required this.tests,
    required this.done,
  });
  bool get defeated => tests.isNotEmpty && done >= tests.length;
  double get fraction => tests.isEmpty ? 0 : done / tests.length;
}

const _bossNames = [
  'Évaluation initiale',
  'Tests 1RM',
  'Tests d\u2019endurance',
  'Tests finaux',
];
const _bossTitles = ['Testé au feu', 'Maître des 1RM', 'Diesel', 'Finisseur'];

bool isTestDay(DayPlan d) => d.title.trim().toUpperCase().startsWith('TEST');
bool isDeloadWeek(WeekPlan w) =>
    w.days.any((d) => d.cycle.toUpperCase().contains('DELOAD'));

List<Boss> computeBosses(
  Program program,
  bool Function(int week, int day) isDone,
) {
  final out = <Boss>[];
  List<(int, int)> tests = [];
  int? first, last;
  var done = 0;
  void flush() {
    if (tests.isEmpty) return;
    final i = out.length;
    out.add(
      Boss(
        id: 'boss$i',
        name: i < _bossNames.length ? _bossNames[i] : 'Tests · semaine $first',
        title: i < _bossTitles.length ? _bossTitles[i] : 'Vainqueur $i',
        firstWeek: first!,
        lastWeek: last!,
        tests: tests,
        done: done,
      ),
    );
    tests = [];
    first = null;
    last = null;
    done = 0;
  }

  for (final w in program.weeks) {
    final days = w.days.where(isTestDay).toList();
    if (days.isEmpty) {
      flush();
      continue;
    }
    first ??= w.n;
    last = w.n;
    for (final d in days) {
      tests.add((w.n, d.j));
      if (isDone(w.n, d.j)) done++;
    }
  }
  flush();
  return out;
}

class Season {
  final int index;
  final String name, title;
  final int firstWeek, lastWeek, trainingDays, doneDays;
  final bool current;
  const Season({
    required this.index,
    required this.name,
    required this.title,
    required this.firstWeek,
    required this.lastWeek,
    required this.trainingDays,
    required this.doneDays,
    required this.current,
  });
  double get fraction =>
      trainingDays == 0 ? 0 : (doneDays / trainingDays).clamp(0.0, 1.0);
  bool get complete => trainingDays > 0 && doneDays / trainingDays >= 0.7;
}

const _seasonNames = [
  'Fondations',
  'Force',
  'Force max & endurance',
  'Peaking',
];
const _seasonTitles = ['Socle', 'Acier', 'Marathonien', 'Sommet'];

List<Season> computeSeasons(
  Program program,
  bool Function(int week, int day) isDone,
  int currentWeek, {
  int length = 10,
}) {
  final out = <Season>[];
  final total = program.weeks.length;
  for (var start = 1, i = 0; start <= total; start += length, i++) {
    final end = math.min(total, start + length - 1);
    var training = 0, done = 0;
    for (var n = start; n <= end; n++) {
      for (final d in program.week(n).days) {
        if (d.exercises.isEmpty) continue;
        training++;
        if (isDone(n, d.j)) done++;
      }
    }
    out.add(
      Season(
        index: i + 1,
        name: i < _seasonNames.length ? _seasonNames[i] : 'Saison ${i + 1}',
        title: i < _seasonTitles.length
            ? _seasonTitles[i]
            : 'Saison ${i + 1} bouclée',
        firstWeek: start,
        lastWeek: end,
        trainingDays: training,
        doneDays: done,
        current: currentWeek >= start && currentWeek <= end,
      ),
    );
  }
  return out;
}

// ---------------------------------------------------------------------------
// Titres
// ---------------------------------------------------------------------------

class GameTitle {
  final String id, name, source;
  final bool earned;
  const GameTitle(this.id, this.name, this.source, this.earned);
}

// ---------------------------------------------------------------------------
// Toi contre toi-même
// ---------------------------------------------------------------------------

class SelfCompare {
  final TrainingWeek current, previous;
  final TrainingWeek? best;
  const SelfCompare({required this.current, required this.previous, this.best});
  int get sessionsDelta => current.sessions - previous.sessions;
  int get setsDelta => current.sets - previous.sets;
  int get daysDelta => current.activeDays.length - previous.activeDays.length;
}

// ---------------------------------------------------------------------------
// Rareté des badges
// ---------------------------------------------------------------------------

enum BadgeRarity { commun, rare, epique, legendaire }

BadgeRarity rarityOf(BadgeDefinition b) => b.xp >= 400
    ? BadgeRarity.legendaire
    : b.xp >= 200
    ? BadgeRarity.epique
    : b.xp >= 100
    ? BadgeRarity.rare
    : BadgeRarity.commun;

String rarityLabel(BadgeRarity r) => switch (r) {
  BadgeRarity.commun => 'Commun',
  BadgeRarity.rare => 'Rare',
  BadgeRarity.epique => 'Épique',
  BadgeRarity.legendaire => 'Légendaire',
};

// ---------------------------------------------------------------------------
// État de jeu agrégé
// ---------------------------------------------------------------------------

class GameState {
  final CharacterSheet sheet;
  final StreakInfo streak;
  final WeeklyGoal weekly;
  final double sessionGoal;
  final List<Chapter> chapters;
  final List<Boss> bosses;
  final List<Season> seasons;
  final List<GameTitle> titles;
  final SelfCompare compare;
  final bool deloadWeek;
  final int programWeek;
  const GameState({
    required this.sheet,
    required this.streak,
    required this.weekly,
    required this.sessionGoal,
    required this.chapters,
    required this.bosses,
    required this.seasons,
    required this.titles,
    required this.compare,
    required this.deloadWeek,
    required this.programWeek,
  });

  Chapter? get currentChapter => chapters.where((c) => c.current).firstOrNull;
  Season? get currentSeason => seasons.where((s) => s.current).firstOrNull;
  Boss? get nextBoss => bosses.where((b) => !b.defeated).firstOrNull;
  List<GameTitle> get earnedTitles => titles.where((t) => t.earned).toList();

  /// Étoiles de prestige au-delà du rang Légende (niveau 60) : une par
  /// tranche de dix niveaux.
  static int prestigeOf(int level) => level < 60 ? 0 : 1 + (level - 60) ~/ 10;

  static GameState compute({
    required Progression progression,
    required Program program,
    required Map<String, SessionLog> logs,
    required Map<String, double> refs,
    required bool Function(int week, int day) isDone,
    required DateTime now,
    int manualWeeklyGoal = 0,
  }) {
    final week = program.containsDate(now) ? program.weekFor(now) : 0;
    final programDays = week == 0
        ? 4
        : program.week(week).days.where((d) => d.exercises.isNotEmpty).length;
    final streak = StreakInfo.compute(progression.weeks, now);
    final sheet = CharacterSheet.compute(
      refs: refs,
      logs: logs,
      progression: progression,
      streak: streak,
    );
    final chapters = computeChapters(program, isDone, week);
    final bosses = computeBosses(program, isDone);
    final seasons = computeSeasons(program, isDone, week);
    final season = seasons.where((s) => s.current).firstOrNull;
    final deloadDone = <bool>[];
    if (season != null) {
      for (var n = season.firstWeek; n <= season.lastWeek && n < week; n++) {
        final w = program.week(n);
        if (isDeloadWeek(w)) {
          final done = w.days
              .where((d) => d.exercises.isNotEmpty && isDone(n, d.j))
              .length;
          deloadDone.add(done >= 1);
        }
      }
    }
    final titles = <GameTitle>[
      for (final c in chapters)
        GameTitle('chapter-${c.key}', c.title, c.name, c.complete),
      for (final b in bosses)
        GameTitle(b.id, b.title, 'Boss · ${b.name}', b.defeated),
      for (final s in seasons)
        GameTitle(
          'season-${s.index}',
          s.title,
          'Saison ${s.index} · ${s.name}',
          s.complete,
        ),
      GameTitle(
        'guardian',
        'Gardien du repos',
        'Chaque semaine de deload de la saison honorée',
        deloadDone.isNotEmpty && deloadDone.every((d) => d),
      ),
      for (final b in progression.badges)
        if (rarityOf(b.badge) == BadgeRarity.legendaire)
          GameTitle(
            'badge-${b.badge.id}',
            b.badge.title,
            'Badge légendaire',
            b.earned,
          ),
    ];
    final recent = progression.recentWeeks;
    TrainingWeek? best;
    for (final w in progression.weeks.values) {
      if (w.monday == progression.week.monday) continue;
      if (best == null || w.sets > best.sets) best = w;
    }
    return GameState(
      sheet: sheet,
      streak: streak,
      weekly: WeeklyGoal.compute(progression, programDays, manualWeeklyGoal),
      sessionGoal: sessionGoalFraction(logs),
      chapters: chapters,
      bosses: bosses,
      seasons: seasons,
      titles: titles,
      compare: SelfCompare(
        current: progression.week,
        previous: recent.length >= 2
            ? recent[recent.length - 2]
            : TrainingWeek(progression.week.monday),
        best: best,
      ),
      deloadWeek: week > 0 && isDeloadWeek(program.week(week)),
      programWeek: week,
    );
  }
}

// ---------------------------------------------------------------------------
// Bilan de récompenses (fin de séance)
// ---------------------------------------------------------------------------

class RewardLine {
  final String label;
  final int xp;
  final String kind; // base | badge | mission | streak | record | goal
  const RewardLine(this.label, this.xp, this.kind);
}

class RewardSummary {
  final String heading, title;
  final int xpBefore, xpAfter, levelBefore, levelAfter;
  final String rankBefore, rankAfter;
  final List<RewardLine> lines;
  final List<RecordHit> records;
  final bool? goalReached;
  const RewardSummary({
    required this.heading,
    required this.title,
    required this.xpBefore,
    required this.xpAfter,
    required this.levelBefore,
    required this.levelAfter,
    required this.rankBefore,
    required this.rankAfter,
    required this.lines,
    required this.records,
    this.goalReached,
  });
  int get xpGained => xpAfter - xpBefore;
  bool get levelUp => levelAfter > levelBefore;
  bool get promotion => rankAfter != rankBefore;

  static RewardSummary build({
    required Progression before,
    required Progression after,
    required String heading,
    required String title,
    int baseXp = 0,
    String baseLabel = 'Séance',
    List<RecordHit> records = const [],
    bool? goalReached,
  }) {
    final lines = <RewardLine>[];
    if (baseXp > 0) lines.add(RewardLine(baseLabel, baseXp, 'base'));
    final earnedBefore = before.badges
        .where((b) => b.earned)
        .map((b) => b.badge.id)
        .toSet();
    for (final b in after.badges) {
      if (b.earned && !earnedBefore.contains(b.badge.id)) {
        lines.add(
          RewardLine(
            'Badge « ${b.badge.title} » · ${rarityLabel(rarityOf(b.badge))}',
            b.badge.xp,
            'badge',
          ),
        );
      }
    }
    final missionsBefore = before.week.missions
        .where((m) => m.complete)
        .map((m) => m.id)
        .toSet();
    for (final m in after.week.missions) {
      if (m.complete && !missionsBefore.contains(m.id)) {
        lines.add(RewardLine('Défi « ${m.title} »', m.xp, 'mission'));
      }
    }
    if (after.currentStreak > before.currentStreak) {
      lines.add(
        RewardLine(
          'Semaine validée · série de ${after.currentStreak}',
          0,
          'streak',
        ),
      );
    }
    for (final r in records) {
      lines.add(RewardLine('Record · ${r.exercise} · ${r.label}', 0, 'record'));
    }
    if (goalReached == true) {
      lines.add(const RewardLine('Objectif de séance atteint', 0, 'goal'));
    }
    return RewardSummary(
      heading: heading,
      title: title,
      xpBefore: before.totalXp,
      xpAfter: after.totalXp,
      levelBefore: before.level,
      levelAfter: after.level,
      rankBefore: before.rank.title,
      rankAfter: after.rank.title,
      lines: lines,
      records: records,
      goalReached: goalReached,
    );
  }
}
