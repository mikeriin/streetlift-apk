// Modèles WOD (For Time, rounds, AMRAP, EMOM, routine libre) + WODs préchargés.
import 'dart:convert';

import 'wod_formats.dart';

class WodResult {
  String at; // ISO
  String score; // texte affiché (ex. « 12:34 » ou « 7 rounds + 5 »)
  int? seconds; // pour les formats chronométrés
  int? rounds; // AMRAP / EMOM
  int? reps;
  String notes;
  bool completed;
  String? prescription;

  /// Tentative dont ce score est la finalisation (KT-003) : une même
  /// tentative ne produit jamais deux résultats.
  String? attempt;

  /// Règle de score sous laquelle ce résultat a été saisi (L3b), par ex.
  /// `tabata/1`. Absente : résultat antérieur à 2.5.6, lu selon
  /// `readRule` (voir `wod_formats.dart`), jamais réécrit.
  String? scoring;

  /// Tabata : répétitions saisies par intervalle, un tableau par mouvement.
  /// `null` = intervalle non renseigné (différent de 0 répétition).
  List<List<int?>>? intervals;

  WodResult({
    required this.at,
    required this.score,
    this.seconds,
    this.rounds,
    this.reps,
    this.notes = '',
    this.completed = true,
    this.prescription,
    this.attempt,
    this.scoring,
    this.intervals,
  });

  Map<String, dynamic> toJson() => {
    'at': at,
    'score': score,
    'seconds': seconds,
    'rounds': rounds,
    'reps': reps,
    'notes': notes,
    'completed': completed,
    if (prescription != null) 'prescription': prescription,
    if (attempt != null) 'attempt': attempt,
    if (scoring != null) 'scoring': scoring,
    if (intervals != null)
      'intervals': [for (final block in intervals!) List<int?>.of(block)],
  };
  WodResult.fromJson(Map<String, dynamic> j)
    : at = j['at'] as String,
      score = j['score'] as String? ?? '',
      seconds = j['seconds'] as int?,
      rounds = j['rounds'] as int?,
      reps = j['reps'] as int?,
      notes = j['notes'] as String? ?? '',
      completed = j['completed'] as bool? ?? true,
      prescription = j['prescription'] as String?,
      attempt = j['attempt'] as String?,
      scoring = j['scoring'] as String?,
      intervals =
          j['intervals'] == null
              ? null
              : [
                for (final block in j['intervals'] as List)
                  [for (final v in block as List) v as int?],
              ];
}

/// Définition structurée d'un format dont la consigne fixe un déroulement
/// ou une règle de score que les champs génériques ne décrivent pas (L3b).
/// Elle vient du catalogue embarqué (générateur, WOD préchargé), jamais
/// d'une analyse du texte.
class WodFormat {
  /// `tabata` · `amrap-blocks` · `emom-reps` · `death-by`.
  final String kind;

  /// Tabata : un bloc d'intervalles par mouvement, dans l'ordre.
  final List<String> movements;

  /// Tabata : intervalles par bloc, secondes d'effort, secondes de repos
  /// entre deux intervalles. `blockRest` : repos entre deux blocs (Tabata,
  /// AMRAP en blocs).
  final int sets, work, rest, blockRest;

  /// AMRAP en blocs : durée de chaque bloc, en minutes.
  final List<int> blockMinutes;

  /// EMOM compté en répétitions : ce qui est compté (ex. « tractions »).
  final String unit;

  const WodFormat.tabata({
    required this.movements,
    required this.sets,
    required this.work,
    required this.rest,
    required this.blockRest,
  }) : kind = 'tabata',
       blockMinutes = const [],
       unit = '';

  const WodFormat.amrapBlocks({
    required this.blockMinutes,
    required this.blockRest,
  }) : kind = 'amrap-blocks',
       movements = const [],
       sets = 0,
       work = 0,
       rest = 0,
       unit = '';

  const WodFormat.emomReps(this.unit)
    : kind = 'emom-reps',
      movements = const [],
      blockMinutes = const [],
      sets = 0,
      work = 0,
      rest = 0,
      blockRest = 0;

  const WodFormat.deathBy()
    : kind = 'death-by',
      movements = const [],
      blockMinutes = const [],
      sets = 0,
      work = 0,
      rest = 0,
      blockRest = 0,
      unit = '';

  const WodFormat._(
    this.kind,
    this.movements,
    this.sets,
    this.work,
    this.rest,
    this.blockRest,
    this.blockMinutes,
    this.unit,
  );

  Map<String, dynamic> toJson() => {
    'kind': kind,
    if (movements.isNotEmpty) 'movements': movements,
    if (sets > 0) 'sets': sets,
    if (work > 0) 'work': work,
    if (rest > 0) 'rest': rest,
    if (blockRest > 0) 'blockRest': blockRest,
    if (blockMinutes.isNotEmpty) 'blockMinutes': blockMinutes,
    if (unit.isNotEmpty) 'unit': unit,
  };

  factory WodFormat.fromJson(Map<String, dynamic> j) => WodFormat._(
    j['kind'] as String,
    [for (final m in (j['movements'] as List?) ?? const []) m as String],
    j['sets'] as int? ?? 0,
    j['work'] as int? ?? 0,
    j['rest'] as int? ?? 0,
    j['blockRest'] as int? ?? 0,
    [for (final m in (j['blockMinutes'] as List?) ?? const []) m as int],
    j['unit'] as String? ?? '',
  );

  /// Définition utilisable pour un WOD de ce type ; sinon le WOD garde la
  /// règle générique de son type.
  bool validFor(String type) => switch (kind) {
    'tabata' =>
      type == 'routine' &&
          movements.isNotEmpty &&
          movements.length <= 20 &&
          movements.every((m) => m.trim().isNotEmpty && m.length <= 200) &&
          sets >= 1 &&
          sets <= 50 &&
          work >= 1 &&
          work <= 3600 &&
          rest >= 0 &&
          rest <= 3600 &&
          blockRest >= 0 &&
          blockRest <= 3600,
    'amrap-blocks' =>
      type == 'routine' &&
          blockMinutes.isNotEmpty &&
          blockMinutes.length <= 20 &&
          blockMinutes.every((m) => m >= 1 && m <= 240) &&
          blockRest >= 0 &&
          blockRest <= 3600,
    'emom-reps' =>
      type == 'emom' && unit.trim().isNotEmpty && unit.length <= 60,
    'death-by' => type == 'emom',
    _ => false,
  };
}

/// Types : fortime · rounds · amrap · emom · routine
const wodTypes = <String, String>{
  'fortime': 'For Time',
  'rounds': 'Rounds for time',
  'amrap': 'AMRAP',
  'emom': 'EMOM',
  'routine': 'Routine / libre',
};

class Wod {
  String id;
  String name;
  String type;
  int rounds; // rounds / emom : nombre de tours
  int restSec; // repos entre rounds (0 = aucun)
  int minutes; // amrap : durée ; fortime : time cap (0 = aucun)
  int interval; // emom : intervalle en s
  String scheme; // ex. « 27-21-15-12-9 »
  List<String> lines; // mouvements, une ligne = un mouvement / un bloc
  String notes; // pénalités, objectifs, team…
  String source;
  int level; // niveau requis pour le déverrouiller (1 = libre)
  List<WodResult> results;

  /// Format structuré (Tabata, AMRAP en blocs, EMOM compté en reps, Death
  /// by) : fixé par le catalogue, hors définition modifiable.
  WodFormat? format;

  Wod({
    required this.id,
    required this.name,
    this.type = 'fortime',
    this.rounds = 0,
    this.restSec = 0,
    this.minutes = 0,
    this.interval = 60,
    this.scheme = '',
    List<String>? lines,
    this.notes = '',
    this.source = '',
    this.level = 1,
    List<WodResult>? results,
    this.format,
  }) : lines = lines ?? [],
       results = results ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'rounds': rounds,
    'restSec': restSec,
    'minutes': minutes,
    'interval': interval,
    'scheme': scheme,
    'lines': lines,
    'notes': notes,
    'source': source,
    'level': level,
    'results': results.map((r) => r.toJson()).toList(),
    if (format != null) 'format': format!.toJson(),
  };
  Wod.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      name = j['name'] as String,
      type = j['type'] as String? ?? 'fortime',
      rounds = j['rounds'] as int? ?? 0,
      restSec = j['restSec'] as int? ?? 0,
      minutes = j['minutes'] as int? ?? 0,
      interval = j['interval'] as int? ?? 60,
      scheme = j['scheme'] as String? ?? '',
      lines = ((j['lines'] as List?) ?? []).map((e) => e.toString()).toList(),
      notes = j['notes'] as String? ?? '',
      source = j['source'] as String? ?? '',
      level = j['level'] as int? ?? 1,
      results =
          ((j['results'] as List?) ?? [])
              .map((r) => WodResult.fromJson(r as Map<String, dynamic>))
              .toList(),
      format =
          j['format'] == null
              ? null
              : WodFormat.fromJson(j['format'] as Map<String, dynamic>);

  /// Les résultats ne calibrent que la prescription réellement effectuée.
  String get prescriptionKey => jsonEncode({
    'type': type,
    'rounds': rounds,
    'restSec': restSec,
    'minutes': minutes,
    'interval': interval,
    'scheme': scheme,
    'lines': lines,
    'notes': notes,
  });

  String get typeLabel => formatLabel(this) ?? wodTypes[type] ?? type;

  /// Résumé de l'entête (ex. « 5 rounds · repos 1 min · cap 20 min »).
  String header() {
    final structured = formatHeader(this);
    if (structured != null) return structured;
    final p = <String>[];
    if (type == 'amrap') p.add('$minutes min');
    if (type == 'emom') p.add('$rounds × $interval s');
    if (type == 'rounds') p.add('$rounds rounds');
    if (restSec > 0) {
      p.add(
        'repos ${restSec >= 60 ? '${restSec ~/ 60} min${restSec % 60 == 0 ? '' : ' ${restSec % 60} s'}' : '$restSec s'}',
      );
    }
    if (type != 'amrap' && minutes > 0) p.add('cap $minutes min');
    if (scheme.isNotEmpty) p.add(scheme);
    return p.join(' · ');
  }

  /// Types au chronomètre montant dans l'ancien modèle (avant L3b) : sert
  /// encore à l'estimation de durée et à la lecture des anciens résultats.
  /// Le runner et la saisie suivent `ruleFor` / `phasesOf`.
  bool get timed => type == 'fortime' || type == 'rounds' || type == 'routine';

  /// Record selon la règle de score actuelle du WOD (`wod_formats.dart`) :
  /// seuls les résultats complets saisis ou lus sous cette règle comptent ;
  /// à égalité, le premier résultat reste le record. Null : aucun résultat
  /// comparable, ou format sans classement.
  WodResult? best() => bestResult(this);
}

/// WODs préchargés (les 19 « en stock » de Gaël).
List<Wod> seedWods() {
  var n = 0;
  String nid() => 'seed${++n}';
  return [
    Wod(
      id: nid(),
      name: '5 rounds bodyweight',
      type: 'rounds',
      rounds: 5,
      restSec: 60,
      lines: [
        '10 push-ups',
        '20 air squats',
        '30 sit-ups',
        '20 reverse lunges',
        '10 burpees',
      ],
      source: 'onlinewod',
    ),
    Wod(
      id: nid(),
      name: 'Routine intermédiaire barre',
      type: 'routine',
      lines: [
        '18 tractions · 30" rest · 28 dips · 15" rest · 5 dips + 10 pompes',
        '15 tractions · 30" rest · 24 dips · 15" rest · 10 dips + 10 pompes',
        '12 tractions · 30" rest · 20 dips · 15" rest · 12 dips + 10 pompes',
        '8 tractions · 30" rest · 15 dips · 15" rest · 17 dips + 10 pompes',
      ],
      source: 'caliwodfr',
    ),
    Wod(
      id: nid(),
      name: 'Dips + knees to chest circuit',
      type: 'rounds',
      rounds: 5,
      restSec: 120,
      lines: ['10 dips', '20 knees to chest', '10 dips'],
      source: 'calisthenicsworkouts',
    ),
    Wod(
      id: nid(),
      name: 'IPC 100-80-60-40-20',
      type: 'fortime',
      lines: [
        '100 pompes surélevées (pieds sur banc)',
        '80 tractions',
        '60 burpees',
        '40 toes-to-bar',
        '20 burpees-tractions',
      ],
      notes:
          'Objectif — intermédiaire < 40 min · confirmé < 35 min · athlète < 30 min',
      source: 'david_invictusphysicalcoaching',
    ),
    Wod(
      id: nid(),
      name: '400 m run 21-15-9',
      type: 'fortime',
      scheme: '21-15-9',
      lines: ['400 m run', 'burpees', 'sit-ups', 'air squats'],
      notes: 'Chaque round commence par 400 m de course.',
      source: 'onlinewod',
    ),
    Wod(
      id: nid(),
      name: '10 rounds 10-10-10-10',
      type: 'rounds',
      rounds: 10,
      lines: ['10 pull-ups', '10 push-ups', '10 air squats', '10 burpees'],
      source: 'fitnessinbox',
    ),
    Wod(
      id: nid(),
      name: 'Set sur barre (muscle-ups)',
      type: 'routine',
      lines: [
        '1 MU + 8 pull-ups + 1 MU + 10 bar dips',
        '2 MU + 7 pull-ups + 1 MU + 9 bar dips',
        '3 MU + 6 pull-ups + 1 MU + 8 bar dips',
        '4 MU + 5 pull-ups + 1 MU + 7 bar dips',
        '4 MU + 4 pull-ups + 1 MU + 7 bar dips',
        '3 MU + 3 pull-ups + 1 MU + 8 bar dips',
        '2 MU + 2 pull-ups + 1 MU + 9 bar dips',
        '1 MU + 1 pull-up + 1 MU + 10 bar dips',
      ],
      source: 'caliwodfr',
    ),
    Wod(
      id: nid(),
      name: 'WOD Team of 2',
      type: 'routine',
      lines: [
        '1000 m run — ensemble',
        '2 rounds à partager : 100 m sandbag lunges 20 kg · 100 m farmer carry 2×24 kg · 80 m burpees broad jump',
        '1000 m run — ensemble',
        '2 rounds à partager : 500 m skierg · 500 m run · 500 m row',
        '1000 m run — ensemble',
        '100 wall balls',
      ],
      notes: 'En binôme.',
      source: 'caliwodfr',
    ),
    Wod(
      id: nid(),
      name: 'Pyramide accumulée burpees',
      type: 'fortime',
      lines: [
        '10 burpees',
        '10 burpees · 25 push-ups',
        '10 burpees · 25 push-ups · 50 lunges',
        '10 burpees · 25 push-ups · 50 lunges · 100 sit-ups',
        '10 burpees · 25 push-ups · 50 lunges · 100 sit-ups · 150 air squats',
      ],
      source: 'onlinewod',
    ),
    Wod(
      id: nid(),
      name: 'IPC 1 → 15 reps',
      type: 'fortime',
      scheme: '1-2-3-…-15',
      lines: ['pompes', 'burpees', 'tractions', 'toes-to-bar'],
      notes:
          'Objectif — intermédiaire < 50 min · confirmé < 45 min · athlète < 40 min',
      source: 'david_invictusphysicalcoaching',
    ),
    Wod(
      id: nid(),
      name: 'IPC 5000 m avec pénalités',
      type: 'fortime',
      lines: ['5000 m de course'],
      notes:
          'Toutes les 5\'00", pénalité : 5-10 burpees · 10-20 pompes · 20-30 air squats. Choisis ton niveau. Commence par la course, ne coupe pas le chrono.',
      source: 'david_invictusphysicalcoaching',
    ),
    Wod(
      id: nid(),
      name: 'AMRAP 3-4-5',
      type: 'routine',
      restSec: 120,
      lines: [
        'AMRAP 3 min : 3 burpees · 3 air squats · 3 push-ups',
        'Repos 2 min',
        'AMRAP 4 min : 6 burpees · 6 air squats · 6 push-ups',
        'Repos 2 min',
        'AMRAP 5 min : 9 burpees · 9 air squats · 9 push-ups',
      ],
      source: 'onlinewod',
    ),
    Wod(
      id: nid(),
      name: 'Routine avancée muscle-ups',
      type: 'routine',
      lines: [
        '5 MU · 35 dips · 20 pull-ups · 40 pompes',
        '5 MU · 30 dips · 18 pull-ups · 35 pompes',
        '5 MU · 25 dips · 16 pull-ups · 30 pompes',
        '5 MU · 20 dips · 12 pull-ups · 25 pompes',
        '5 MU · 15 dips · 10 pull-ups · 20 pompes',
      ],
      source: 'caliwodfr',
    ),
    Wod(
      id: nid(),
      name: '27-21-15-12-9 burpees / sit-ups',
      type: 'fortime',
      scheme: '27-21-15-12-9',
      lines: ['burpees', 'sit-ups'],
      notes: '400 m run entre chaque round.',
      source: 'onlinewod',
    ),
    Wod(
      id: nid(),
      name: 'Run & burpees descendant',
      type: 'fortime',
      lines: [
        '1000 m run · 50 burpees',
        '800 m run · 40 burpees',
        '600 m run · 30 burpees',
        '400 m run · 20 burpees',
        '200 m run · 10 burpees',
      ],
      source: 'onlinewod',
    ),
    Wod(
      id: nid(),
      name: 'IPC 10 → 1 multi-ladder',
      type: 'fortime',
      lines: [
        '10-9-8-7-6-5-4-3-2-1 burpees',
        '20-18-16-14-12-10-8-6-4-2 tractions',
        '30-27-24-21-18-15-12-9-6-3 air squats',
        '40-36-32-28-24-20-16-12-8-4 pompes',
      ],
      notes:
          '1re série : 10 burpees · 20 tractions · 30 air squats · 40 pompes, etc. Objectif — inter. < 50 min · confirmé < 45 min · athlète < 40 min',
      source: 'david_invictusphysicalcoaching',
    ),
    Wod(
      id: nid(),
      name: 'IPC 100 bench press',
      type: 'fortime',
      lines: ['100 bench press'],
      notes:
          'À chaque break, pénalité : 15 pompes · 10 dips · 5 burpees. Barre — débutant 50 kg · inter. 70 kg · confirmé 90 kg · athlète 110 kg',
      source: 'david_invictusphysicalcoaching',
    ),
    Wod(
      id: nid(),
      name: '44-22 squats / burpees / lunges',
      type: 'fortime',
      lines: [
        '44 air squats',
        '22 burpees',
        '44 reverse lunges',
        '22 burpees',
        '44 forward lunges',
      ],
      source: 'onlinewod',
    ),
    Wod(
      id: nid(),
      name: '20/1 → 1/20 push-ups / sit-ups',
      type: 'fortime',
      scheme: '20/1 → 1/20',
      lines: [
        '20 push-ups · 1 sit-up',
        '19 push-ups · 2 sit-ups',
        '… jusqu\'à 1 push-up · 20 sit-ups',
      ],
      source: 'onlinewod',
    ),
  ];
}

/// Niveaux requis des WODs préchargés d'origine (migration des installations existantes).
const seedLevels = <String, int>{
  'seed1': 1,
  'seed2': 5,
  'seed3': 2,
  'seed4': 8,
  'seed5': 2,
  'seed6': 4,
  'seed7': 7,
  'seed8': 3,
  'seed9': 5,
  'seed10': 8,
  'seed11': 4,
  'seed12': 1,
  'seed13': 9,
  'seed14': 3,
  'seed15': 4,
  'seed16': 9,
  'seed17': 6,
  'seed18': 2,
  'seed19': 3,
};

/// Deuxième fournée : 12 WODs (captures de septembre 2026).
List<Wod> seedWodsV2() => [
  Wod(
    id: 'seed20',
    name: '4 rounds burpees & 100 m',
    type: 'rounds',
    rounds: 4,
    level: 2,
    lines: [
      '10 burpees',
      '100 m run',
      '10 air squats',
      '100 m run',
      '10 push-ups',
      '100 m run',
      '10 sit-ups',
      '100 m run',
    ],
    source: 'onlinewod',
  ),
  Wod(
    id: 'seed21',
    name: 'Routine avancée dips lestés',
    type: 'routine',
    level: 8,
    lines: [
      '10 dips 25 kg + (1 pull-up + 1 muscle-up) ×4 + 14 tractions + 30 pompes',
      '10 dips 25 kg + (1 pull-up + 1 muscle-up) ×3 + 13 tractions + 28 pompes',
      '10 dips 25 kg + (1 pull-up + 1 muscle-up) ×2 + 12 tractions + 25 pompes',
      '10 dips 25 kg + (1 pull-up + 1 muscle-up) ×1 + 11 tractions + 22 pompes',
    ],
    source: 'caliwodfr',
  ),
  Wod(
    id: 'seed22',
    name: 'Set sur barre +5 kg dégressif',
    type: 'routine',
    scheme: '10-8-6-4-2',
    level: 9,
    lines: ['muscle-ups', 'dips barre', 'pull-ups'],
    notes: 'Lesté +5 kg. 10-8-6-4-2 de chaque, enchaîné.',
    source: 'caliwodfr',
  ),
  Wod(
    id: 'seed23',
    name: 'WOD 21-15-9 barre + burpees / lunges',
    type: 'fortime',
    level: 5,
    lines: [
      '21 pull-ups',
      '21 dips',
      '21 push-ups',
      '50 burpees',
      '15 pull-ups',
      '15 dips',
      '15 push-ups',
      '50 walking lunges',
      '9 pull-ups',
      '9 dips',
      '9 push-ups',
    ],
    notes:
        'Débutant : poids du corps · Intermédiaire : lesté 10 kg · Confirmé : lesté 20 kg',
    source: 'caliwodfr',
  ),
  Wod(
    id: 'seed24',
    name: 'Cindy — niveau athlète (IPC)',
    type: 'amrap',
    minutes: 20,
    level: 9,
    lines: ['3 muscle-ups stricts', '6 HSPU stricts', '9 box jumps'],
    notes: 'AMRAP 20 min. Choisis ton niveau et dépasse tes limites.',
    source: 'david_invictusphysicalcoaching',
  ),
  Wod(
    id: 'seed25',
    name: 'HYROX — jour 407',
    type: 'rounds',
    rounds: 2,
    minutes: 60,
    level: 6,
    lines: [
      '400 m run',
      '100 walking lunges',
      '400 m run',
      '80 air squats',
      '400 m run',
      '60 sit-ups',
      '400 m run',
      '40 push-ups',
      '400 m run',
      '20 burpees',
      '400 m run',
    ],
    notes: 'Time cap 55/60 min.',
    source: 'entrainement_high_rox',
  ),
  Wod(
    id: 'seed26',
    name: '10 rounds 30-20-10-5',
    type: 'rounds',
    rounds: 10,
    level: 3,
    lines: ['30 air squats', '20 sit-ups', '10 push-ups', '5 burpees'],
    source: 'onlinewod',
  ),
  Wod(
    id: 'seed27',
    name: 'Iron Body',
    type: 'rounds',
    rounds: 10,
    level: 6,
    lines: ['10 pull-ups', '20 push-ups', '30 air squats', '40 sit-ups'],
    notes: 'Score = temps.',
    source: 'ironboundtribe',
  ),
  Wod(
    id: 'seed28',
    name: '6 rounds 24-24-24 + 400 m',
    type: 'rounds',
    rounds: 6,
    level: 3,
    lines: [
      '24 air squats',
      '24 push-ups',
      '24 walking lunge steps',
      '400 m run',
    ],
    source: 'onlinewod',
  ),
  Wod(
    id: 'seed29',
    name: 'E5MOM 25 min — max tractions (IPC)',
    type: 'emom',
    rounds: 5,
    interval: 300,
    level: 7,
    // Consigne : « Objectif total tractions » → score = total de tractions.
    format: const WodFormat.emomReps('tractions'),
    lines: [
      '20 burpees',
      '30 pompes',
      '40 air squats',
      '+ le reste du temps : MAX de tractions',
    ],
    notes:
        'Départ toutes les 5 min pendant 25 min. Objectif total tractions — intermédiaire 50 · confirmé 75 · athlète 100.',
    source: 'david_invictusphysicalcoaching',
  ),
  Wod(
    id: 'seed30',
    name: 'AMRAP 40 — partner (I go, you go)',
    type: 'amrap',
    minutes: 40,
    level: 4,
    lines: ['3 burpees', '4 air squats', '5 push-ups', '6 sit-ups'],
    notes: 'En binôme, en alternance.',
    source: 'onlinewod',
  ),
];

/// Troisième fournée — séances publiées par OnlineWOD (onlinewod.com/blog).
List<Wod> seedWodsV3() {
  Wod w(
    String id,
    String name,
    String type,
    int level,
    List<String> lines, {
    int rounds = 0,
    int rest = 0,
    int minutes = 0,
    int interval = 60,
    String scheme = '',
    String notes = '',
  }) => Wod(
    id: id,
    name: name,
    type: type,
    level: level,
    lines: lines,
    rounds: rounds,
    restSec: rest,
    minutes: minutes,
    interval: interval,
    scheme: scheme,
    notes: notes,
    source: 'onlinewod',
  );
  return [
    w(
      'seed32',
      'Échelle burpees / squats 12-9-6',
      'rounds',
      3,
      [
        '12 burpees',
        '12 air squats',
        '9 burpees',
        '9 air squats',
        '6 burpees',
        '6 air squats',
      ],
      rounds: 4,
      rest: 60,
      minutes: 20,
      notes:
          'Time cap 20 min repos compris. Ne sprinte pas le round 1 : des rounds réguliers.',
    ),
    w(
      'seed33',
      'AMRAP 16 fentes & wall walks',
      'amrap',
      4,
      [
        '20 fentes avant (10/10)',
        '2 wall walks',
        '20 fentes arrière (10/10)',
        '2 wall walks',
      ],
      minutes: 16,
      notes: 'Objectif 4-6 rounds. Wall walks : contrôle la descente.',
    ),
    w(
      'seed34',
      'Chipper tractions / pompes 15-12-9',
      'fortime',
      6,
      [
        '15 pull-ups',
        '15 push-ups',
        '30 double-unders',
        '12 pull-ups',
        '12 push-ups',
        '30 double-unders',
        '9 pull-ups',
        '9 push-ups',
        '30 double-unders',
        'Repos 2 min',
        '9 push-ups',
        '9 pull-ups',
        '30 double-unders',
        '12 push-ups',
        '12 pull-ups',
        '30 double-unders',
        '15 push-ups',
        '15 pull-ups',
        '30 double-unders',
      ],
      minutes: 20,
      notes:
          'Time cap 20 min. Sans double-unders : 90 single-unders ou 30 high knees.',
    ),
    w(
      'seed35',
      'Grinder course / fentes / sit-ups',
      'rounds',
      4,
      [
        '20 butterfly sit-ups',
        '200 m run',
        '40 walking lunges (20/20)',
        '200 m run',
        '20 butterfly sit-ups',
        '200 m run',
      ],
      rounds: 3,
      rest: 60,
      minutes: 30,
      notes: 'Time cap 30 min repos compris. Allure modérée sur les runs.',
    ),
    w(
      'seed36',
      'Double AMRAP 5 ascendant',
      'routine',
      5,
      [
        'AMRAP 5 min : 2-4-6-8-10… squat jumps · push-ups (ou HSPU)',
        'Repos 2 min',
        'AMRAP 5 min : 2-4-6-8-10… jumping lunges (par côté) · plank up-downs',
      ],
      rest: 120,
      notes:
          'Objectif : atteindre le round de 10 sur le premier AMRAP, 8-10 sur le second.',
    ),
    w(
      'seed37',
      'EMOM 15 haute densité',
      'emom',
      3,
      ['5 air squats', '5 push-ups', '5 squat jumps', '5 butterfly sit-ups'],
      rounds: 15,
      notes: 'Si le round 1 dépasse 40 s, passe à 4 reps par mouvement.',
    ),
    w(
      'seed38',
      'Classique course / burpees',
      'rounds',
      4,
      ['400 m run', '20 burpees'],
      rounds: 5,
      minutes: 25,
      notes:
          'Time cap 25 min. Runs à 80-85 %, burpees en 2-3 blocs max. Objectif 18-22 min.',
    ),
    w(
      'seed39',
      'Pyramide de squats descendante',
      'fortime',
      3,
      [
        '50 air squats',
        '15 push-ups',
        '40 air squats',
        '15 push-ups',
        '30 air squats',
        '15 push-ups',
        '20 air squats',
        '15 push-ups',
        '10 air squats',
        '15 push-ups',
      ],
      minutes: 12,
      notes: 'Time cap 12 min. Objectif 8-10 min ; sous 8 min = élite.',
    ),
    w(
      'seed40',
      'Murph',
      'fortime',
      10,
      [
        '1600 m run',
        '100 pull-ups',
        '200 push-ups',
        '300 air squats',
        '1600 m run',
      ],
      notes:
          'RX avec gilet lesté 9 kg. Partition possible : 20 rounds de 5 tractions · 10 pompes · 15 squats.',
    ),
    w(
      'seed41',
      'Murph — version rounds',
      'rounds',
      5,
      ['400 m run', '10 push-ups', '5 pull-ups', '10 air squats', '5 pull-ups'],
      rounds: 6,
      rest: 90,
      notes:
          '5 à 8 rounds. Option A : chaque round à fond (RPE 8-9). Option B : negative split, intensité croissante.',
    ),
    w(
      'seed42',
      'Piste 1 — allures variées',
      'rounds',
      3,
      [
        '800 m allure lente',
        '400 m récupération',
        '400 m allure modérée',
        '400 m récupération',
        '200 m rapide',
        '400 m récupération',
      ],
      rounds: 3,
      rest: 300,
    ),
    w(
      'seed43',
      'Piste 2 — 1600 à 200 dégressif',
      'fortime',
      5,
      [
        '1600 m run',
        'Repos 4 min',
        '1200 m run',
        'Repos 3 min',
        '800 m run',
        'Repos 2 min',
        '400 m run',
        'Repos 1 min',
        '200 m run',
      ],
      notes: 'Dans chaque intervalle, alterner 200 m rapide / 200 m lent.',
    ),
    w('seed44', 'Piste 3 — 800 / 600 / 400', 'routine', 5, [
      '2 × 800 m allure lente-modérée · repos 4 min',
      '3 × 600 m allure modérée · repos 3 min',
      '4 × 400 m allure modérée-rapide · repos 2 min',
    ]),
    w('seed45', 'Piste 4 — changements de rythme', 'routine', 4, [
      '3 × (500 m lent + 300 m rapide) · repos 3 min',
      '3 × (400 m lent + 200 m rapide) · repos 3 min',
      '3 × (300 m lent + 100 m rapide)',
    ]),
    w(
      'seed46',
      'Piste 5 — 800-600-400-200',
      'rounds',
      5,
      [
        '800 m run',
        'Repos 1 min',
        '600 m run',
        'Repos 1 min',
        '400 m run',
        'Repos 1 min',
        '200 m run',
      ],
      rounds: 3,
      rest: 180,
    ),
    w(
      'seed47',
      'Piste 6 — 10 × 400 m',
      'rounds',
      4,
      ['400 m allure modérée-rapide'],
      rounds: 10,
      rest: 120,
      notes: 'Choisis l\u2019allure la plus rapide tenable sur les 10 rounds.',
    ),
    w(
      'seed48',
      'Piste 7 — progression jusqu\u2019au sprint',
      'rounds',
      3,
      [
        '4 min course lente',
        '1 min marche',
        '2 min allure modérée',
        '1 min marche',
        '1 min rapide',
        '1 min marche',
        '30 s sprint max',
      ],
      rounds: 3,
      rest: 180,
    ),
    w(
      'seed49',
      'Piste 8 — sprints 100 m',
      'rounds',
      3,
      [
        '100 m sprint',
        '100 m footing',
        '100 m sprint',
        '100 m footing',
        '100 m sprint',
      ],
      rounds: 3,
      rest: 300,
    ),
    w(
      'seed50',
      'Piste 9 — 4 × 400 m repos 15 s',
      'rounds',
      6,
      [
        '400 m run',
        'Repos 15 s',
        '400 m run',
        'Repos 15 s',
        '400 m run',
        'Repos 15 s',
        '400 m run',
      ],
      rounds: 3,
      rest: 180,
      notes: 'Le repos de 15 s est brutal : tolérance au lactate.',
    ),
    w(
      'seed51',
      'Piste 10 — 500 + 300 m',
      'rounds',
      5,
      ['500 m rapide', 'Repos 1 min', '300 m très rapide'],
      rounds: 3,
      rest: 240,
    ),
    w(
      'seed52',
      'Piste 11 — 3 × 300 m crescendo',
      'rounds',
      5,
      [
        '300 m modéré',
        'Repos 90 s',
        '300 m rapide',
        'Repos 90 s',
        '300 m très rapide',
      ],
      rounds: 3,
      rest: 240,
    ),
    w(
      'seed53',
      'Piste 12 — 8 × 100 m sprint',
      'rounds',
      2,
      ['100 m sprint', '300 m marche'],
      rounds: 8,
      notes: 'Pas de repos entre les rounds : récupération active en marchant.',
    ),
  ];
}

/// Tous les WODs préchargés, dans l'ordre des fournées.
/// Quatrième fournée — captures de septembre (Caliwod, High Rox, OnlineWOD).
List<Wod> seedWodsV4() => [
  Wod(
    id: 'seed54',
    name: 'Erg & box — dégressif',
    type: 'fortime',
    source: 'caliwodfr',
    lines: [
      '2000 m erg',
      '10 burpees over the box',
      '1500 m erg',
      '20 box step-overs haltère 20 kg',
      '1000 m erg',
      '30 box jumps',
      '500 m erg',
    ],
    notes: 'Erg au choix : bike, rameur ou skierg.',
  ),
  Wod(
    id: 'seed55',
    name: 'RURE — AMRAP 20',
    type: 'amrap',
    minutes: 20,
    source: 'entrainement_high_rox',
    lines: ['5 burpees', '10 wall balls 6 kg', '15 lunges'],
  ),
  Wod(
    id: 'seed56',
    name: 'AMRAP 8 barre lestée',
    type: 'amrap',
    minutes: 8,
    source: 'caliwodfr',
    lines: [
      '3 tractions + 1 muscle-up + 3 bar dips (unbroken)',
      '10 tractions 5 kg',
      '10 dips 5 kg',
    ],
  ),
  Wod(
    id: 'seed57',
    name: 'Hommage F. Montorio — 19 rounds',
    type: 'rounds',
    rounds: 19,
    source: 'caliwodfr',
    lines: ['4 pull-ups', '18 push-ups', '17 air squats', '21 m sandbag carry'],
    notes:
        '19 rounds pour 19 années de service. Hommage au sergent-chef Florian Montorio (17e RGP), mort au Liban le 18 avril 2026 (opération Daman, FINUL).',
  ),
  Wod(
    id: 'seed58',
    name: 'E2MOM 12 — muscle-up lesté',
    type: 'emom',
    rounds: 6,
    interval: 120,
    source: 'caliwodfr',
    lines: ['1 muscle-up 2,5 kg', '8 tractions', '8 pompes', '3 muscle-ups'],
    notes: 'Toutes les 2 minutes pendant 12 minutes.',
  ),
  Wod(
    id: 'seed59',
    name: 'HYROX — jour 414',
    type: 'rounds',
    rounds: 2,
    minutes: 60,
    source: 'entrainement_high_rox',
    lines: [
      '100 m farmer carry 16/24/32 kg',
      '2000 m echo bike',
      '50 wall balls 4/6/9 kg',
      '1000 m row',
      '50 m burpees broad jump',
      '1000 m skierg',
      '50 m sandbag lunges 10/20/30 kg',
      '100 m farmer carry',
    ],
    notes: 'Time cap 50/60 min.',
  ),
  Wod(
    id: 'seed60',
    name: 'HYROX — jour 415 endurance',
    type: 'rounds',
    rounds: 3,
    minutes: 60,
    source: 'entrainement_high_rox',
    lines: [
      '500 m run',
      '50 cal row',
      '500 m run',
      '40 wall balls 4/6/9 kg',
      '500 m run',
      '30 burpees to plate',
      '500 m run',
      '20 goblet squats 16/24/32 kg',
    ],
    notes: 'Time cap 60 min. Cardio, force, mental.',
  ),
  Wod(
    id: 'seed61',
    name: '3 rounds burpees intercalés',
    type: 'rounds',
    rounds: 3,
    source: 'onlinewod',
    lines: [
      '15 burpees',
      '30 air squats',
      '15 burpees',
      '30 push-ups',
      '15 burpees',
      '30 reverse lunges',
      '15 burpees',
      '30 sit-ups',
    ],
  ),
  Wod(
    id: 'seed62',
    name: 'HYROX — jour 411 EMOM 30',
    type: 'emom',
    rounds: 30,
    interval: 60,
    source: 'entrainement_high_rox',
    lines: [
      'Cash in : 1000 m row',
      'min 1-5 : 10 burpees',
      'min 6-10 : 20 wall balls 4/6/9 kg',
      'min 11-15 : 20 m sandbag lunges 10/20/30 kg',
      'min 16-20 : 12 snatch 15/22,5 kg',
      'min 21-25 : 40 mountain climbers',
      'min 26-30 : 15 push-ups',
      'Cash out : 1000 m row',
    ],
  ),
  Wod(
    id: 'seed63',
    name: 'HYROX — jour 416',
    type: 'rounds',
    rounds: 2,
    minutes: 60,
    source: 'entrainement_high_rox',
    lines: [
      '1000 m skierg',
      '80 m burpees broad jump',
      '1000 m row',
      '200 m farmer carry 16/24/32 kg',
      '100 m fentes 10/20/30 kg',
      '100 wall balls 4/6/9 kg',
    ],
    notes: 'Time cap 60 min.',
  ),
  Wod(
    id: 'seed64',
    name: 'Cannonball — For Time',
    type: 'fortime',
    source: 'caliwodfr',
    lines: [
      '1000 m row',
      '1000 m skierg',
      '50 wall balls',
      '50 m burpees',
      '800 m row',
      '800 m skierg',
      '50 wall balls',
      '50 m sandbag lunges 20 kg',
      '600 m row',
      '600 m skierg',
      '100 wall balls',
    ],
  ),
];

/// WODs retirés du catalogue (course à pied uniquement).
const removedSeedIds = {
  'seed11',
  'seed42',
  'seed43',
  'seed44',
  'seed45',
  'seed46',
  'seed47',
  'seed48',
  'seed49',
  'seed50',
  'seed51',
  'seed52',
  'seed53',
};

List<Wod> allSeedWods() => [
  for (final w in [
    ...seedWods(),
    ...seedWodsV2(),
    ...seedWodsV3(),
    ...seedWodsV4(),
  ])
    if (!removedSeedIds.contains(w.id)) w,
];
