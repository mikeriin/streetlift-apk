// L12 (KT-065 à KT-071) — motivation et progression visible : règles
// pures, sans Flutter, sans horloge (les jours sont passés en paramètre),
// testables. Niveau de détail selon le niveau, victoires concrètes, chaînes
// de progression du pack, étapes réelles (records, étapes de chaîne, cycles,
// régularité), ton de Koach et bibliothèque de messages, bilans, rappels,
// partage local et parcours d'habitude des débutants.
// Branchement sur le store : lib/motiv_store.dart. Écrans :
// lib/motivation_screens.dart. Contrat : docs/CONTRAT_L12.md.
import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:math' as math;

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

// ================================================= niveau de détail (KT-065)

/// Niveau de détail de l'affichage des progrès.
/// - `victories` : débutant et novice, victoires concrètes, au plus
///   [kMaxVictoryFigures] chiffres par écran ;
/// - `simple` : intermédiaire, records et courbes simples ;
/// - `full` : avancé et expert (ou « Afficher toutes les statistiques »),
///   statistiques complètes de Koach.
enum DetailLevel { victories, simple, full }

const kMaxVictoryFigures = 3;

/// Niveau global 0 (débutant) … 4 (expert).
DetailLevel detailLevelFor(int level, {bool showAll = false}) {
  if (showAll) return DetailLevel.full;
  if (level <= 1) return DetailLevel.victories;
  if (level == 2) return DetailLevel.simple;
  return DetailLevel.full;
}

final RegExp _figure = RegExp(r'\d+(?:[.,]\d+)?');

/// Nombre de chiffres (valeurs numériques) d'un texte : « +6 pompes depuis
/// ton départ » → 1 ; « 3 × 12 » → 2.
int figureCount(String text) => _figure.allMatches(text).length;

/// Victoire concrète (débutant et novice) : texte court, priorité (plus
/// petit = plus important).
class Victory {
  final String id, text;
  final int priority;
  const Victory(this.id, this.text, this.priority);
  int get figures => figureCount(text);
}

/// Victoires retenues pour un écran : par priorité, sans dépasser
/// [maxFigures] chiffres au total, au plus [maxItems].
List<Victory> pickVictories(
  List<Victory> all, {
  int maxFigures = kMaxVictoryFigures,
  int maxItems = 3,
}) {
  final sorted = [...all]..sort((a, b) {
    final c = a.priority.compareTo(b.priority);
    return c != 0 ? c : a.id.compareTo(b.id);
  });
  final out = <Victory>[];
  var figures = 0;
  for (final v in sorted) {
    if (out.length >= maxItems) break;
    if (figures + v.figures > maxFigures) continue;
    out.add(v);
    figures += v.figures;
  }
  return out;
}

// ============================================ chaînes de progression (KT-066)

/// Seuil de passage d'une étape (pack L9, `seuil_passage`).
class ChainThreshold {
  final int series;
  final int? reps, seconds;
  final bool perSide;
  final double? lestPct;
  final String text;
  const ChainThreshold({
    this.series = 1,
    this.reps,
    this.seconds,
    this.perSide = false,
    this.lestPct,
    this.text = '',
  });

  factory ChainThreshold.fromJson(Map<String, dynamic> j) => ChainThreshold(
    series: (j['series'] as num?)?.toInt() ?? 1,
    reps: (j['repetitions'] as num?)?.toInt(),
    seconds: (j['secondes'] as num?)?.toInt(),
    perSide: j['par_cote'] == true,
    lestPct: (j['lest_pct_poids_de_corps'] as num?)?.toDouble(),
    text: j['texte'] as String? ?? '',
  );

  /// Valeur à atteindre par série (répétitions ou secondes).
  int get target => seconds ?? reps ?? 1;
}

class ChainStep {
  final String id;
  final ChainThreshold? threshold;
  const ChainStep(this.id, this.threshold);
}

class Chain {
  final String id, title;
  final List<ChainStep> steps;
  const Chain(this.id, this.title, this.steps);
}

/// Chaînes du pack (`assets/content/progressions.json.gz`), chargées une
/// fois (fichier léger).
class ChainBook {
  final List<Chain> chains;
  final Map<String, Chain> byId;
  ChainBook(this.chains) : byId = {for (final c in chains) c.id: c};

  factory ChainBook.fromJson(Map<String, dynamic> j) => ChainBook([
    for (final c in (j['chaines'] as List? ?? const []))
      Chain(
        (c as Map)['id'] as String,
        c['titre'] as String? ?? c['id'] as String,
        [
          for (final s in (c['etapes'] as List? ?? const []))
            ChainStep(
              (s as Map)['id'] as String,
              s['seuil_passage'] is Map
                  ? ChainThreshold.fromJson(
                    (s['seuil_passage'] as Map).cast<String, dynamic>(),
                  )
                  : null,
            ),
        ],
      ),
  ]);

  static ChainBook? loaded;
  static Future<ChainBook>? _pending;

  static const asset = 'assets/content/progressions.json.gz';

  static Future<ChainBook> load([AssetBundle? bundle]) =>
      _pending ??= _load(bundle ?? rootBundle).catchError((Object e) {
        _pending = null;
        throw e;
      });

  static Future<ChainBook> _load(AssetBundle b) async {
    final bytes = await b.load(asset);
    final raw =
        jsonDecode(utf8.decode(gzip.decode(bytes.buffer.asUint8List())))
            as Map<String, dynamic>;
    return loaded = ChainBook.fromJson(raw);
  }
}

/// Série réalisée : valeur (répétitions, ou secondes pour une tenue) et
/// charge ajoutée (kg, 0 sans lest).
typedef PerfSet = ({int value, double kg});

/// Séance réalisée sur un exercice du pack : jour civil et séries validées.
typedef PerfSession = ({int day, List<PerfSet> sets});

/// Critère de passage atteint dans une séance.
bool thresholdMet(ChainThreshold t, List<PerfSet> sets, {double? bodyweight}) {
  final pct = t.lestPct;
  if (pct != null) {
    if (bodyweight == null || bodyweight <= 0) return false;
    final kg = bodyweight * pct / 100;
    final ok =
        sets.where((s) => s.value >= t.target && s.kg + 1e-9 >= kg).length;
    return ok >= math.max(1, t.series);
  }
  final ok = sets.where((s) => s.value >= t.target).length;
  return ok >= math.max(1, t.series);
}

enum ChainStepState { reached, current, next, locked }

/// Avancement d'une chaîne : jour de passage de chaque étape franchie
/// (null pour une étape franchie sans date propre ou non franchie),
/// étape en cours.
class ChainProgress {
  final Chain chain;

  /// Étapes franchies (index → jour du passage, ou null si déduite d'une
  /// étape plus avancée pratiquée).
  final Map<int, int?> reached;

  /// Index de l'étape en cours (== longueur : chaîne terminée).
  final int current;

  /// Une étape de la chaîne au moins a été pratiquée.
  final bool started;

  /// Étapes dont le critère a été atteint (index → jour) : seules ces
  /// étapes deviennent des étapes réelles célébrées.
  final Map<int, int> met;

  /// Première pratique de chaque étape (index → jour).
  final Map<int, int> practiced;
  const ChainProgress(
    this.chain,
    this.reached,
    this.current,
    this.started, {
    this.met = const {},
    this.practiced = const {},
  });

  bool get complete => current >= chain.steps.length;

  ChainStepState stateOf(int i) {
    if (reached.containsKey(i)) return ChainStepState.reached;
    if (i == current) return ChainStepState.current;
    if (i == current + 1) return ChainStepState.next;
    return ChainStepState.locked;
  }

  ChainStep? get currentStep => complete ? null : chain.steps[current];
  ChainStep? get nextStep =>
      current + 1 < chain.steps.length ? chain.steps[current + 1] : null;
}

/// Avancement d'une chaîne selon les séances réalisées (par identifiant du
/// pack). Une étape est franchie quand son critère est atteint dans une
/// séance (jour = première séance qui l'atteint) ou quand une étape plus
/// avancée de la chaîne a été pratiquée (jour = première séance de
/// l'étape suivante pratiquée).
ChainProgress chainProgress(
  Chain chain,
  Map<String, List<PerfSession>> perf, {
  double? bodyweight,
}) {
  final n = chain.steps.length;
  final firstPractice = List<int?>.filled(n, null);
  final metDay = List<int?>.filled(n, null);
  for (var i = 0; i < n; i++) {
    final s = chain.steps[i];
    final sessions = [...?perf[s.id]]..sort((a, b) => a.day.compareTo(b.day));
    for (final p in sessions) {
      if (p.sets.isEmpty) continue;
      firstPractice[i] ??= p.day;
      final t = s.threshold;
      if (t != null &&
          metDay[i] == null &&
          thresholdMet(t, p.sets, bodyweight: bodyweight)) {
        metDay[i] = p.day;
      }
    }
  }
  final reached = <int, int?>{};
  // Étape franchie par déduction : une étape plus avancée pratiquée.
  int? laterPractice;
  for (var i = n - 1; i >= 0; i--) {
    final own = metDay[i];
    if (own != null || laterPractice != null) {
      final later = laterPractice;
      reached[i] =
          own == null ? later : (later == null ? own : math.min(own, later));
    }
    final f = firstPractice[i];
    if (f != null) {
      laterPractice = laterPractice == null ? f : math.min(laterPractice, f);
    }
  }
  var current = 0;
  while (current < n && reached.containsKey(current)) {
    current++;
  }
  return ChainProgress(
    chain,
    reached,
    current,
    firstPractice.any((d) => d != null),
    met: {
      for (var i = 0; i < n; i++)
        if (metDay[i] != null) i: metDay[i]!,
    },
    practiced: {
      for (var i = 0; i < n; i++)
        if (firstPractice[i] != null) i: firstPractice[i]!,
    },
  );
}

/// Chaînes utiles à l'objectif (mises en avant) : objectif principal et
/// secondaire du profil ; épreuves de l'objectif daté. Sans profil : chaînes
/// du streetlifting (programme de 40 semaines).
List<String> chainsForGoals(
  List<String> goals, {
  List<String> eventItems = const [],
}) {
  const byGoal = <String, List<String>>{
    'health': [
      'pompes',
      'tractions',
      'squat',
      'charniere',
      'gainage_ventral',
      'mobilite_epaules',
      'mobilite_hanches',
    ],
    'strength': [
      'tractions',
      'dips',
      'pompes_lestees',
      'back_squat',
      'charniere',
      'squat',
    ],
    'endurance': [
      'pompes',
      'tractions',
      'dips',
      'squat',
      'gainage_ventral',
      'gainage_creux',
    ],
    'event': ['tractions', 'dips', 'muscle_up', 'back_squat'],
    'muscle': ['pompes', 'tractions', 'dips', 'back_squat', 'charniere'],
    'skills': [
      'front_lever',
      'back_lever',
      'planche',
      'equilibre_mains',
      'l_sit',
      'muscle_up',
    ],
    'energy': ['pompes', 'squat', 'gainage_ventral', 'mobilite_hanches'],
  };
  const byEvent = <String, String>{
    'pull_1rm': 'tractions',
    'dip_1rm': 'dips',
    'mu_1rm': 'muscle_up',
    'squat_1rm': 'back_squat',
  };
  final out = <String>[];
  void add(String c) {
    if (!out.contains(c)) out.add(c);
  }

  for (final g in goals) {
    if (g == 'event' && eventItems.isNotEmpty) {
      for (final e in eventItems) {
        final c = byEvent[e];
        if (c != null) add(c);
      }
      continue;
    }
    for (final c in byGoal[g] ?? const <String>[]) {
      add(c);
    }
  }
  if (out.isEmpty) byGoal['event']!.forEach(add);
  return out;
}

// ============================================== étapes réelles (KT-067)

/// Étape réelle : record, étape de chaîne franchie, cycle terminé,
/// régularité. Identifiant stable : une étape n'est célébrée (et, après
/// validation du barème, payée) qu'une fois.
class Milestone {
  final String id, kind, title;
  final int day;
  const Milestone(this.id, this.kind, this.title, this.day);
}

const kMilestoneKinds = ['record', 'chain', 'cycle', 'regular'];

/// Paliers de régularité (semaines régulières d'affilée).
const kRegularTiers = [4, 8, 12, 26, 52];

/// Une étape est célébrée si elle date de moins de [kCelebrateDays] jours
/// et n'a pas encore été vue (une installation mise à jour ne reçoit pas
/// une avalanche de célébrations pour son historique).
const kCelebrateDays = 7;

/// Barème PROPOSÉ (crédits par étape), non appliqué : invariant économie,
/// en attente de validation du propriétaire (docs/CONTRAT_L12.md §5).
const kMilestoneCreditsProposal = <String, int>{
  'record': 0,
  'chain': 2,
  'cycle': 3,
  'regular:4': 1,
  'regular:8': 1,
  'regular:12': 2,
  'regular:26': 3,
  'regular:52': 5,
};

/// Le barème ne s'applique qu'après validation : tant que ce drapeau est
/// faux, aucune étape ne crée de crédit ni d'XP (registre KT-005 inchangé).
const kMilestoneRewardsApproved = false;

/// Crédits d'une étape selon le barème appliqué (0 tant qu'il n'est pas
/// validé).
int milestoneCredits(Milestone m) {
  if (!kMilestoneRewardsApproved) return 0;
  final key = m.kind == 'regular' ? m.id : m.kind;
  return kMilestoneCreditsProposal[key] ?? 0;
}

/// Étapes à célébrer : récentes, non vues, triées par date puis identifiant.
List<Milestone> pendingMilestones(
  List<Milestone> all,
  Map<String, String> seen,
  int today,
) {
  final out = [
    for (final m in all)
      if (!seen.containsKey(m.id) &&
          m.day <= today &&
          today - m.day < kCelebrateDays)
        m,
  ]..sort((a, b) {
    final c = a.day.compareTo(b.day);
    return c != 0 ? c : a.id.compareTo(b.id);
  });
  return out;
}

// ================================================ régularité (KT-067)

/// Semaine civile (lundi = [monday], numéro de jour) vue sous l'angle de la
/// régularité : séances prévues et faites, jours de repos respectés.
class WeekRegularity {
  final int monday;
  final int planned, done, restDays, restRespected, plannedDone;
  final bool paused;

  /// Séances à faire pour que la semaine soit régulière.
  final int target;
  const WeekRegularity({
    required this.monday,
    required this.planned,
    required this.done,
    required this.restDays,
    required this.restRespected,
    required this.plannedDone,
    required this.target,
    this.paused = false,
  });

  /// Semaine comptée (au moins une séance prévue hors pause).
  bool get counted => planned > 0;
  bool get regular => counted && done >= target;

  /// Jours « sur le plan » : séances prévues faites + jours de repos
  /// respectés (repos compté comme une réussite, jamais l'inverse).
  int get onPlan => plannedDone + restRespected;
}

/// Séances visées pour une semaine régulière : 3/4 des séances prévues
/// (arrondi supérieur), au moins une ; parcours d'habitude : 2 au plus.
int regularTarget(int planned, {bool habit = false}) {
  if (planned <= 0) return 0;
  final t = math.max(1, (planned * 3 / 4).ceil());
  return habit ? math.min(t, math.min(2, planned)) : t;
}

/// Régularité d'une semaine. [planned] : jours prévus d'entraînement ;
/// [training] : jours où l'utilisateur s'est entraîné (séances du
/// programme, séances perso, séance de 10 minutes) ; [paused] : jours de
/// pause (vacances, maladie), exclus ; [today] : les jours futurs ne
/// comptent pas encore.
WeekRegularity weekRegularity({
  required int monday,
  required Set<int> planned,
  required Set<int> training,
  required int today,
  Set<int> paused = const {},
  bool habit = false,
}) {
  var p = 0, pd = 0, done = 0, rest = 0, restOk = 0, pausedDays = 0;
  for (var d = monday; d < monday + 7; d++) {
    if (paused.contains(d)) {
      pausedDays++;
      continue;
    }
    final isPlanned = planned.contains(d);
    final trained = training.contains(d);
    if (trained && d <= today) done++;
    if (isPlanned) {
      p++;
      if (trained && d <= today) pd++;
    } else if (d < today || (d == today && !trained)) {
      // Jour de repos écoulé (ou aujourd'hui sans séance) : respecté s'il
      // n'y a pas eu d'entraînement. S'entraîner un jour de repos n'est
      // jamais pénalisé, simplement pas compté comme repos.
      rest++;
      if (!trained) restOk++;
    }
  }
  return WeekRegularity(
    monday: monday,
    planned: p,
    done: done,
    restDays: rest,
    restRespected: restOk,
    plannedDone: pd,
    target: regularTarget(p, habit: habit),
    paused: pausedDays == 7,
  );
}

/// Semaines régulières d'affilée (les semaines sans séance prévue, en pause
/// par exemple, ne cassent ni n'allongent la série). La semaine en cours
/// compte seulement si elle est déjà régulière.
int regularStreak(List<WeekRegularity> weeks, int currentMonday) {
  final sorted = [...weeks]..sort((a, b) => b.monday.compareTo(a.monday));
  var n = 0;
  for (final w in sorted) {
    if (w.monday > currentMonday) continue;
    if (!w.counted) continue;
    if (w.regular) {
      n++;
    } else if (w.monday == currentMonday) {
      continue;
    } else {
      break;
    }
  }
  return n;
}

/// Étapes de régularité : premier passage à chaque palier (jour = dimanche
/// de la semaine qui l'atteint).
List<Milestone> regularMilestones(List<WeekRegularity> weeks, int today) {
  final sorted = [...weeks]..sort((a, b) => a.monday.compareTo(b.monday));
  final out = <Milestone>[];
  final done = <int>{};
  var streak = 0;
  for (final w in sorted) {
    if (!w.counted) continue;
    final ended = w.monday + 6 <= today;
    if (w.regular) {
      streak++;
      for (final t in kRegularTiers) {
        if (streak >= t && !done.contains(t)) {
          done.add(t);
          out.add(
            Milestone(
              'regular:$t',
              'regular',
              '$t semaines régulières',
              math.min(w.monday + 6, today),
            ),
          );
        }
      }
    } else if (ended) {
      streak = 0;
    }
  }
  return out;
}

// ============================================ cycles et bilans (KT-069)

/// Cycle du programme : suite de semaines consécutives du même bloc.
class ProgramCycle {
  final int index, firstWeek, lastWeek;
  final String key, label;
  const ProgramCycle(
    this.index,
    this.firstWeek,
    this.lastWeek,
    this.key,
    this.label,
  );
}

/// Cycles à partir des semaines (numéro, clé de bloc, libellé).
List<ProgramCycle> programCycles(List<(int, String, String)> weeks) {
  final out = <ProgramCycle>[];
  for (final w in weeks) {
    if (out.isNotEmpty &&
        out.last.key == w.$2 &&
        out.last.lastWeek == w.$1 - 1) {
      final l = out.removeLast();
      out.add(ProgramCycle(l.index, l.firstWeek, w.$1, l.key, l.label));
    } else {
      out.add(ProgramCycle(out.length + 1, w.$1, w.$1, w.$2, w.$3));
    }
  }
  return out;
}

/// Bilan hebdomadaire disponible : semaine civile précédente, du lundi
/// (inclus) au dimanche (inclus) de la semaine qui suit. Renvoie le lundi
/// de la semaine résumée.
int reviewWeekMonday(int today) {
  final monday = today - ((today + 3) % 7);
  return monday - 7;
}

/// Bilan de fin de cycle visible du lendemain du dernier jour du cycle
/// jusqu'à [kCycleReviewDays] jours après.
const kCycleReviewDays = 14;

bool cycleReviewOpen(int lastDay, int today) =>
    today > lastDay && today - lastDay <= kCycleReviewDays;

/// Bilan hebdomadaire : trois éléments au plus (une victoire, l'assiduité,
/// le cap de la semaine suivante).
class WeekReview {
  final int monday;
  final String? victory;
  final String adherence;
  final String next;
  const WeekReview(this.monday, this.victory, this.adherence, this.next);

  List<String> get items => [if (victory != null) victory!, adherence, next];
}

/// Texte d'assiduité d'un bilan : jamais culpabilisant, les jours de repos
/// respectés comptent.
String adherenceLine(WeekRegularity w) {
  if (!w.counted) {
    return w.paused
        ? 'Semaine en pause : rien à rattraper.'
        : 'Pas de séance prévue cette semaine-là.';
  }
  final rest =
      w.restRespected == 0
          ? ''
          : ' et ${w.restRespected} jour${w.restRespected > 1 ? 's' : ''} de repos respecté${w.restRespected > 1 ? 's' : ''}';
  return '${w.plannedDone} séance${w.plannedDone > 1 ? 's' : ''} sur ${w.planned} prévue${w.planned > 1 ? 's' : ''}$rest.';
}

/// Bilan de fin de cycle : progrès sur l'objectif, points forts, point à
/// travailler, prochain objectif, projection (Koach, L7).
class CycleReview {
  final ProgramCycle cycle;
  final String progress, strength, work, next;
  final String? projection;
  const CycleReview({
    required this.cycle,
    required this.progress,
    required this.strength,
    required this.work,
    required this.next,
    this.projection,
  });

  List<(String, String)> get lines => [
    ('Progrès', progress),
    ('Point fort', strength),
    ('À travailler', work),
    ('Prochain objectif', next),
    if (projection != null) ('Projection', projection!),
  ];
}

/// Évolution relative (en %) d'une estimation entre le début et la fin
/// d'un cycle (null si moins de deux points).
double? cycleChange(Map<int, double> weekly, int firstWeek, int lastWeek) {
  final pts = [
    for (var w = firstWeek; w <= lastWeek; w++)
      if (weekly[w] != null && weekly[w]! > 0) weekly[w]!,
  ];
  if (pts.length < 2) return null;
  return (pts.last - pts.first) / pts.first * 100;
}

// ================================================= ton de Koach (KT-068)

const kToneIds = ['kind', 'demanding', 'neutral'];

/// Ton par défaut selon le niveau (identique au profil L8) : bienveillant
/// pour débutant et novice, neutre pour intermédiaire, exigeant au-delà.
String defaultToneFor(int level) => switch (level) {
  2 => 'neutral',
  >= 3 => 'demanding',
  _ => 'kind',
};

/// Contextes de messages.
const kMessageContexts = [
  'session_done',
  'record',
  'chain_step',
  'cycle_done',
  'regular_week',
  'comeback',
  'week_good',
  'week_low',
  'minimal_session',
  'rest_day',
  'habit',
  'progress',
];

/// Messages de sécurité : même texte neutre et clair quel que soit le ton
/// (douleur, mode prudent, maladie).
const kSafetyContexts = ['pain', 'caution', 'illness'];

const _safety = <String, String>{
  'pain':
      'Gêne ou douleur signalée : arrête l’exercice concerné et allège. '
      'Si elle persiste, parles-en à un professionnel de santé.',
  'caution':
      'Mode prudent actif : charges et volume restent modérés tant qu’il '
      'est actif.',
  'illness':
      'Retour de maladie : semaine plus légère. Si les symptômes persistent, '
      'parles-en à un professionnel de santé.',
};

/// Bibliothèque : contexte → ton → [débutant/novice, intermédiaire,
/// avancé/expert]. L'exigence augmente avec le niveau ; aucun vocabulaire
/// médical, aucune humiliation ni culpabilisation, jamais d'incitation à
/// ignorer la douleur, le repos ou la fatigue.
const _library = <String, Map<String, List<String>>>{
  'session_done': {
    'kind': [
      'Séance faite, bravo ! Chaque séance compte.',
      'Beau travail aujourd’hui. Tu construis ta progression.',
      'Séance propre. Récupère bien, la suite se prépare.',
    ],
    'demanding': [
      'Séance faite. C’est comme ça qu’on avance.',
      'Séance validée. Prochaine séance, même qualité.',
      'Travail fait. Entraînement difficile, guerre facile.',
    ],
    'neutral': [
      'Séance terminée.',
      'Séance terminée et enregistrée.',
      'Séance terminée. Données prises en compte par Koach.',
    ],
  },
  'record': {
    'kind': [
      'Nouveau record ! Tu peux être fier de toi.',
      'Nouveau record, bravo : le travail paie.',
      'Record battu. Belle constance.',
    ],
    'demanding': [
      'Nouveau record. Continue sur cette lancée.',
      'Record battu. Consolide-le avant de viser plus haut.',
      'Record battu. Entraînement difficile, guerre facile : prochain palier.',
    ],
    'neutral': [
      'Nouveau record enregistré.',
      'Nouveau record enregistré.',
      'Nouveau record enregistré ; estimation mise à jour.',
    ],
  },
  'chain_step': {
    'kind': [
      'Nouvelle étape franchie ! Une vraie victoire.',
      'Étape franchie, bravo. La suivante t’attend quand tu seras prêt.',
      'Étape franchie. Prends le temps de la consolider.',
    ],
    'demanding': [
      'Étape franchie. Au tour de la suivante.',
      'Étape franchie. Garde une technique propre sur la suivante.',
      'Étape franchie. Entraînement difficile, guerre facile : exécution parfaite exigée sur la suivante.',
    ],
    'neutral': [
      'Étape franchie.',
      'Étape franchie ; critère atteint.',
      'Étape franchie ; critère de passage atteint.',
    ],
  },
  'cycle_done': {
    'kind': [
      'Cycle terminé ! Regarde le chemin parcouru.',
      'Cycle terminé, bravo pour ta constance.',
      'Cycle terminé. Le bilan t’aide à préparer la suite.',
    ],
    'demanding': [
      'Cycle bouclé. On repart pour le suivant.',
      'Cycle bouclé. Analyse le bilan et fixe ton cap.',
      'Cycle bouclé. Entraînement difficile, guerre facile : le prochain bloc se prépare maintenant.',
    ],
    'neutral': [
      'Cycle terminé.',
      'Cycle terminé ; bilan disponible.',
      'Cycle terminé ; bilan et projection disponibles.',
    ],
  },
  'regular_week': {
    'kind': [
      'Semaine régulière, bravo : repos compris.',
      'Semaine régulière. C’est la clé.',
      'Semaine régulière. Belle gestion de l’effort et du repos.',
    ],
    'demanding': [
      'Semaine régulière. On garde le rythme.',
      'Semaine régulière. Garde ce cap.',
      'Semaine régulière. La constance, c’est ce qui sépare les bons des très bons.',
    ],
    'neutral': [
      'Semaine régulière.',
      'Semaine régulière.',
      'Semaine régulière.',
    ],
  },
  'comeback': {
    'kind': [
      'Content de te revoir ! On reprend en douceur.',
      'De retour : on reprend là où tu t’es arrêté.',
      'De retour. Koach ajuste la reprise pour toi.',
    ],
    'demanding': [
      'De retour. On reprend, pas à pas.',
      'De retour. On reprend proprement.',
      'De retour. Reprise progressive : la patience fait partie du travail.',
    ],
    'neutral': [
      'Reprise de l’entraînement.',
      'Reprise de l’entraînement.',
      'Reprise de l’entraînement ; ajustements de reprise appliqués selon ton mode.',
    ],
  },
  'week_good': {
    'kind': [
      'Belle semaine !',
      'Belle semaine, continue comme ça.',
      'Belle semaine de travail.',
    ],
    'demanding': [
      'Bonne semaine. On recommence.',
      'Bonne semaine. Même exigence la prochaine fois.',
      'Bonne semaine. Entraînement difficile, guerre facile.',
    ],
    'neutral': ['Semaine terminée.', 'Semaine terminée.', 'Semaine terminée.'],
  },
  'week_low': {
    'kind': [
      'Semaine plus calme : ça arrive. Une petite séance suffit pour relancer.',
      'Semaine plus calme. On repart tranquillement.',
      'Semaine plus calme. Le plan s’adapte, on repart.',
    ],
    'demanding': [
      'Semaine plus calme. Une séance de 10 minutes suffit pour relancer.',
      'Semaine plus calme. Fixe-toi une première séance et tiens-la.',
      'Semaine plus calme. Priorité à la prochaine séance clé.',
    ],
    'neutral': [
      'Semaine avec moins de séances que prévu.',
      'Semaine avec moins de séances que prévu.',
      'Semaine avec moins de séances que prévu.',
    ],
  },
  'minimal_session': {
    'kind': [
      '10 minutes, ça compte ! Bravo d’avoir bougé.',
      '10 minutes, ça compte. Le rythme est gardé.',
      '10 minutes, ça compte : le rythme est gardé.',
    ],
    'demanding': [
      '10 minutes faites. C’est mieux que zéro.',
      '10 minutes faites. Le rythme tient.',
      '10 minutes faites. Le rythme tient.',
    ],
    'neutral': [
      'Séance courte enregistrée.',
      'Séance courte enregistrée.',
      'Séance courte enregistrée.',
    ],
  },
  'rest_day': {
    'kind': [
      'Jour de repos : il fait partie du programme. Profite !',
      'Jour de repos : la récupération fait partie de la progression.',
      'Jour de repos : la récupération fait partie du plan.',
    ],
    'demanding': [
      'Jour de repos. Il fait partie du travail.',
      'Jour de repos. Récupérer, c’est aussi s’entraîner.',
      'Jour de repos. Récupérer fait partie du plan : on respecte.',
    ],
    'neutral': [
      'Jour de repos prévu.',
      'Jour de repos prévu.',
      'Jour de repos prévu.',
    ],
  },
  'habit': {
    'kind': [
      'Deux séances courtes par semaine suffisent pour installer l’habitude.',
      'Deux séances courtes par semaine suffisent pour installer l’habitude.',
      'Deux séances courtes par semaine pour installer l’habitude.',
    ],
    'demanding': [
      'Deux séances courtes par semaine : on les tient.',
      'Deux séances courtes par semaine : on les tient.',
      'Deux séances courtes par semaine : on les tient.',
    ],
    'neutral': [
      'Parcours d’habitude : deux séances courtes par semaine.',
      'Parcours d’habitude : deux séances courtes par semaine.',
      'Parcours d’habitude : deux séances courtes par semaine.',
    ],
  },
  'progress': {
    'kind': [
      'Regarde tout ce que tu as déjà accompli.',
      'Tes progrès, semaine après semaine.',
      'Tes progrès et tes repères.',
    ],
    'demanding': [
      'Voilà le travail. On continue.',
      'Tes progrès. Chaque séance compte.',
      'Tes chiffres. Entraînement difficile, guerre facile.',
    ],
    'neutral': ['Tes progrès.', 'Tes progrès.', 'Tes progrès et statistiques.'],
  },
};

/// Groupe de niveau pour les messages (0 : débutant et novice ; 1 :
/// intermédiaire ; 2 : avancé et expert).
int messageGroup(int level) => level <= 1 ? 0 : (level == 2 ? 1 : 2);

/// Message de Koach : contexte × ton × niveau. Les contextes de sécurité
/// gardent toujours le même ton neutre.
String koachLine(String context, String tone, int level) {
  final safe = _safety[context];
  if (safe != null) return safe;
  final byTone = _library[context];
  if (byTone == null) return '';
  final list = byTone[kToneIds.contains(tone) ? tone : 'neutral']!;
  return list[messageGroup(level)];
}

/// Tous les messages (pour les tests de la bibliothèque).
Iterable<(String, String, int, String)> allKoachLines() sync* {
  for (final c in [...kMessageContexts, ...kSafetyContexts]) {
    for (final t in kToneIds) {
      for (var l = 0; l <= 4; l++) {
        yield (c, t, l, koachLine(c, t, l));
      }
    }
  }
}

// ======================================================= rappels (KT-070)

/// Rappel autorisé ce jour-là : uniquement un jour d'entraînement prévu,
/// jamais un jour de repos ni pendant une pause.
bool reminderAllowed({required bool trainingDay, bool paused = false}) =>
    trainingDay && !paused;

// ================================================ partage (KT-071)

/// Contenu d'une image de partage, choisi par l'utilisateur. Poids et
/// données de santé exclus par défaut.
class ShareOptions {
  bool victories, records, regularity, chain, bodyweight;
  ShareOptions({
    this.victories = true,
    this.records = true,
    this.regularity = true,
    this.chain = true,
    this.bodyweight = false,
  });
}

/// Données disponibles pour l'image (déjà formatées).
class ShareData {
  final List<String> victories, records;
  final String? regularity, chain, bodyweight;
  const ShareData({
    this.victories = const [],
    this.records = const [],
    this.regularity,
    this.chain,
    this.bodyweight,
  });
}

/// Lignes de l'image de partage selon les choix de l'utilisateur. Aucune
/// donnée de santé n'est jamais partagée (questionnaire, gênes, douleurs,
/// maladie) ; le poids seulement si l'utilisateur le coche.
List<String> shareLines(ShareData d, ShareOptions o) => [
  if (o.victories) ...d.victories.take(3),
  if (o.records) ...d.records.take(3),
  if (o.regularity && d.regularity != null) d.regularity!,
  if (o.chain && d.chain != null) d.chain!,
  if (o.bodyweight && d.bodyweight != null) d.bodyweight!,
];

// ======================================= parcours d'habitude (KT-071)

/// Durée du parcours d'habitude (jours depuis le départ du programme).
const kHabitDays = 28;

/// Durée visée d'une séance du parcours (minutes).
const kHabitMinutes = 20;

/// Parcours actif : débutant ou novice, 4 premières semaines du programme,
/// non désactivé.
bool habitActive({
  required int level,
  required int? startDay,
  required int today,
  bool disabled = false,
}) =>
    !disabled &&
    level <= 1 &&
    startDay != null &&
    today >= startDay &&
    today < startDay + kHabitDays;

/// Durée d'une séance du parcours : 20 minutes, ou moins selon les
/// disponibilités déclarées.
int habitMinutes(int? sessionMinutes) =>
    math.min(kHabitMinutes, math.max(10, sessionMinutes ?? kHabitMinutes));

/// Semaine du parcours (1 à 4).
int habitWeek(int startDay, int today) =>
    ((today - startDay) ~/ 7 + 1).clamp(1, 4);

// ========================================================= données

const kMotivVersion = 1;

/// Section optionnelle `motiv` de la sauvegarde (écrite seulement si elle
/// sert).
class MotivData {
  /// Ton choisi sans profil (installation sans profil L8).
  String? tone;

  /// « Afficher toutes les statistiques ».
  bool showAll = false;

  /// Poids et mensurations masqués.
  bool hideBody = false;

  /// Parcours d'habitude désactivé.
  bool habitOff = false;

  /// Étapes vues (célébrées) : identifiant → jour civil (AAAA-MM-JJ).
  final Map<String, String> seen = {};

  /// Bilans lus : `week:AAAA-MM-JJ` ou `cycle:N` → jour civil.
  final Map<String, String> reviews = {};

  static const maxSeen = 2000, maxReviews = 500;

  bool get pristine =>
      tone == null &&
      !showAll &&
      !hideBody &&
      !habitOff &&
      seen.isEmpty &&
      reviews.isEmpty;

  Map<String, dynamic> toJson() => {
    'v': kMotivVersion,
    if (tone != null) 'tone': tone,
    if (showAll) 'showAll': true,
    if (hideBody) 'hideBody': true,
    if (habitOff) 'habitOff': true,
    if (seen.isNotEmpty) 'seen': Map<String, String>.of(seen),
    if (reviews.isNotEmpty) 'reviews': Map<String, String>.of(reviews),
  };

  static final RegExp _dayRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final RegExp _idRe = RegExp(r'^[\w:.\-~]{1,120}$');

  static bool _okDay(Object? v) =>
      v is String && _dayRe.hasMatch(v) && DateTime.tryParse(v) != null;

  /// Lecture de la section. [strict] (import d'un fichier) : toute valeur
  /// hors contrat lève [FormatException] ; sinon (démarrage) l'entrée est
  /// ignorée et comptée dans [issues].
  static MotivData fromJson(
    Object? raw, {
    bool strict = false,
    List<String>? issues,
  }) {
    final out = MotivData();
    if (raw == null) return out;
    void bad(String what) {
      if (strict) throw FormatException('Motivation invalide : $what.');
      issues?.add(what);
    }

    if (raw is! Map) {
      bad('section');
      return out;
    }
    final v = raw['v'];
    if (v != null && (v is! int || v < 1 || v > kMotivVersion)) {
      bad('version');
      return out;
    }
    final t = raw['tone'];
    if (t != null) {
      if (t is String && kToneIds.contains(t)) {
        out.tone = t;
      } else {
        bad('ton');
      }
    }
    for (final (key, set) in <(String, void Function(bool))>[
      ('showAll', (b) => out.showAll = b),
      ('hideBody', (b) => out.hideBody = b),
      ('habitOff', (b) => out.habitOff = b),
    ]) {
      final b = raw[key];
      if (b == null) continue;
      if (b is bool) {
        set(b);
      } else {
        bad(key);
      }
    }
    for (final (key, target, max) in [
      ('seen', out.seen, maxSeen),
      ('reviews', out.reviews, maxReviews),
    ]) {
      final m = raw[key];
      if (m == null) continue;
      if (m is! Map || (strict && m.length > max)) {
        bad(key);
        continue;
      }
      for (final e in m.entries) {
        if (e.key is String &&
            _idRe.hasMatch(e.key as String) &&
            _okDay(e.value)) {
          target[e.key as String] = e.value as String;
        } else {
          bad('$key ${e.key}');
        }
      }
    }
    return out;
  }
}
