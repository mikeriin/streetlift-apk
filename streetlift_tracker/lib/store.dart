// Store global : Pilotage éditable + journal de séances, persistés localement.
// Les calculs de charge reproduisent exactement les formules du classeur v3.3.
import 'dart:async';
import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:math' show max;
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'game.dart';
import 'models.dart';
import 'persistence.dart';
import 'training_estimate.dart';
import 'progression.dart';
import 'wod_generator.dart';
import 'wod_models.dart';

export 'persistence.dart';

class SetEntry {
  String kg;
  String reps;
  String rir;
  String v; // vitesse (VBT), lifts principaux
  bool done;
  String? completedAt;
  SetEntry({
    this.kg = '',
    this.reps = '',
    this.rir = '',
    this.v = '',
    this.done = false,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'kg': kg,
    'reps': reps,
    'rir': rir,
    'v': v,
    'done': done,
    'completedAt': completedAt,
  };
  SetEntry.fromJson(Map<String, dynamic> j)
    : kg = j['kg'] as String? ?? '',
      reps = j['reps'] as String? ?? '',
      rir = j['rir'] as String? ?? '',
      v = j['v'] as String? ?? '',
      done = j['done'] as bool? ?? false,
      completedAt = j['completedAt'] as String?;
}

class ExerciseLog {
  List<SetEntry> sets;
  String note;
  bool? showKg; // null = règle automatique
  bool? showRir;
  bool? showV;
  ExerciseLog({
    List<SetEntry>? sets,
    this.note = '',
    this.showKg,
    this.showRir,
    this.showV,
  }) : sets = sets ?? [];

  void addSet() => sets.add(SetEntry());
  bool removeLastSet() {
    if (sets.length <= 1 || sets.last.done) return false;
    sets.removeLast();
    return true;
  }

  Map<String, dynamic> toJson() => {
    'sets': sets.map((s) => s.toJson()).toList(),
    'note': note,
    'showKg': showKg,
    'showRir': showRir,
    'showV': showV,
  };
  ExerciseLog.fromJson(Map<String, dynamic> j)
    : sets =
          ((j['sets'] as List?) ?? [])
              .map((s) => SetEntry.fromJson(s as Map<String, dynamic>))
              .toList(),
      note = j['note'] as String? ?? '',
      showKg = j['showKg'] as bool?,
      showRir = j['showRir'] as bool?,
      showV = j['showV'] as bool?;
}

class SessionLog {
  bool done;
  String? finishedAt; // ISO
  String? title; // libellé lisible (ex. « S8 · J1 » ou nom de séance perso)
  Map<String, ExerciseLog> ex;
  Map<String, String> exerciseNames;
  String? customId;
  SessionLog({
    this.done = false,
    this.finishedAt,
    this.title,
    Map<String, ExerciseLog>? ex,
    Map<String, String>? exerciseNames,
    this.customId,
  }) : ex = ex ?? {},
       exerciseNames = exerciseNames ?? {};

  Map<String, dynamic> toJson() => {
    'done': done,
    'finishedAt': finishedAt,
    'title': title,
    'customId': customId,
    'exerciseNames': exerciseNames,
    'ex': ex.map((k, v) => MapEntry(k, v.toJson())),
  };
  SessionLog.fromJson(Map<String, dynamic> j)
    : done = j['done'] as bool? ?? false,
      finishedAt = j['finishedAt'] as String?,
      title = j['title'] as String?,
      customId = j['customId'] as String?,
      exerciseNames = Map<String, String>.from(
        j['exerciseNames'] as Map? ?? {},
      ),
      ex = ((j['ex'] as Map<String, dynamic>?) ?? {}).map(
        (k, v) => MapEntry(k, ExerciseLog.fromJson(v as Map<String, dynamic>)),
      );
}

// ===================== RÉGLAGES =====================

class AppSettings {
  int defaultRest; // s, appliqué quand l'exercice n'a pas de repos
  bool autoTimer; // lancer le repos à la validation d'une série
  bool sound;
  bool vibration;
  int prepSec; // décompte « prêt » avant EMOM/AMRAP/HIIT
  bool rpe; // afficher RPE au lieu de RIR
  bool lb; // afficher les charges en livres
  bool prefill; // pré-remplir la charge suggérée
  bool wakelock; // écran allumé pendant la séance
  String theme; // system | dark | light
  bool trackRir; // colonne RIR/RPE affichée par défaut
  bool trackVelocity; // colonne vitesse (VBT) affichée par défaut sur les lifts
  bool notifOn; // rappel quotidien de la séance du jour
  int notifHour;
  int notifMinute;
  bool notifSkipRest; // pas de rappel les jours de repos
  bool celebrations; // écran de récompenses et cérémonie de niveau
  int weeklyGoal; // objectif de jours actifs par semaine ; 0 = adaptatif
  String title; // titre affiché sur la feuille de personnage ; '' = rang

  AppSettings({
    this.defaultRest = 90,
    this.autoTimer = true,
    this.sound = true,
    this.vibration = true,
    this.prepSec = 5,
    this.rpe = false,
    this.lb = false,
    this.prefill = true,
    this.wakelock = true,
    this.theme = 'dark',
    this.trackRir = false,
    this.trackVelocity = false,
    this.notifOn = false,
    this.notifHour = 7,
    this.notifMinute = 30,
    this.notifSkipRest = true,
    this.celebrations = true,
    this.weeklyGoal = 0,
    this.title = '',
  });

  Map<String, dynamic> toJson() => {
    'defaultRest': defaultRest,
    'autoTimer': autoTimer,
    'sound': sound,
    'vibration': vibration,
    'prepSec': prepSec,
    'rpe': rpe,
    'lb': lb,
    'prefill': prefill,
    'wakelock': wakelock,
    'theme': theme,
    'trackRir': trackRir,
    'trackVelocity': trackVelocity,
    'notifOn': notifOn,
    'notifHour': notifHour,
    'notifMinute': notifMinute,
    'notifSkipRest': notifSkipRest,
    'celebrations': celebrations,
    'weeklyGoal': weeklyGoal,
    'title': title,
  };
  AppSettings.fromJson(Map<String, dynamic> j)
    : defaultRest = j['defaultRest'] as int? ?? 90,
      autoTimer = j['autoTimer'] as bool? ?? true,
      sound = j['sound'] as bool? ?? true,
      vibration = j['vibration'] as bool? ?? true,
      prepSec = j['prepSec'] as int? ?? 5,
      rpe = j['rpe'] as bool? ?? false,
      lb = j['lb'] as bool? ?? false,
      prefill = j['prefill'] as bool? ?? true,
      wakelock = j['wakelock'] as bool? ?? true,
      theme = j['theme'] as String? ?? 'dark',
      trackRir = j['trackRir'] as bool? ?? false,
      trackVelocity = j['trackVelocity'] as bool? ?? false,
      notifOn = j['notifOn'] as bool? ?? false,
      notifHour = j['notifHour'] as int? ?? 7,
      notifMinute = j['notifMinute'] as int? ?? 30,
      notifSkipRest = j['notifSkipRest'] as bool? ?? true,
      celebrations = j['celebrations'] as bool? ?? true,
      weeklyGoal = j['weeklyGoal'] as int? ?? 0,
      title = j['title'] as String? ?? '';
}

// ===================== SÉANCES PERSONNALISÉES =====================

/// Modes d'exécution disponibles pour les séances personnalisées.
class ExecMode {
  final String id;
  final String label;
  final String desc;
  final List<String> fields; // paramètres à afficher dans l'éditeur
  const ExecMode(this.id, this.label, this.desc, this.fields);
}

const execModes = <ExecMode>[
  ExecMode(
    'classic',
    'Classique',
    'Séries × répétitions, repos entre les séries.',
    ['series', 'reps'],
  ),
  ExecMode(
    'myo',
    'Myo-reps',
    'Série d\u2019activation proche de l\u2019échec, puis mini-séries avec micro-repos.',
    ['actReps', 'miniReps', 'minis', 'intra'],
  ),
  ExecMode(
    'cluster',
    'Cluster',
    'Chaque série est découpée en mini-blocs séparés de quelques secondes.',
    ['series', 'miniReps', 'minis', 'intra'],
  ),
  ExecMode(
    'emom',
    'EMOM',
    'Un bloc de travail au top de chaque intervalle (Every Minute On the Minute).',
    ['rounds', 'interval', 'reps'],
  ),
  ExecMode(
    'amrap',
    'AMRAP',
    'Un maximum de travail dans la durée fixée (As Many Reps As Possible).',
    ['duree'],
  ),
  ExecMode(
    'iso',
    'Isométrie',
    'Tenues statiques chronométrées (holds, gainage, overcoming iso).',
    ['series', 'hold'],
  ),
  ExecMode(
    'hiit',
    'Intervalles',
    'Alternance effort/repos chronométrée (HIIT, Tabata).',
    ['rounds', 'work', 'restI'],
  ),
  ExecMode(
    'pyramide',
    'Pyramide',
    'Répétitions croissantes ou décroissantes, ex. 12-10-8-6.',
    ['pyr'],
  ),
  ExecMode(
    'tabata',
    'Tabata',
    'Huit intervalles de 20 s d\u2019effort et 10 s de repos, soit 4 minutes.',
    ['rounds', 'work', 'restI'],
  ),
  ExecMode(
    'deathby',
    'Death by',
    'Une rep de plus à chaque minute, jusqu\u2019à ne plus tenir l\u2019intervalle.',
    ['startReps', 'step', 'interval', 'rounds'],
  ),
  ExecMode(
    'maxreps',
    'Séries au max',
    'Chaque série jusqu\u2019à l\u2019échec technique, repos fixe entre les séries.',
    ['series'],
  ),
  ExecMode(
    'maxhold',
    'Tenues au max',
    'Tenues jusqu\u2019au lâcher (dead-hang, L-sit, planche), chronométrées.',
    ['series'],
  ),
  ExecMode(
    'tempo',
    'Tempo',
    'Séries × reps avec cadence imposée, ex. 3-1-1-0 (descente, bas, montée, haut).',
    ['series', 'reps', 'tempo'],
  ),
  ExecMode(
    'dropset',
    'Drop set',
    'Série proche de l\u2019échec puis paliers immédiats à charge ou difficulté réduite.',
    ['series', 'reps', 'drops'],
  ),
  ExecMode(
    'density',
    'Densité',
    'Un maximum de séries de N reps dans la durée fixée, repos libre.',
    ['duree', 'reps'],
  ),
];

/// Valeurs par défaut propres à un mode (prioritaires sur celles du champ).
const modeDefaults = <String, Map<String, int>>{
  'tabata': {'rounds': 8, 'work': 20, 'restI': 10},
  'deathby': {'startReps': 1, 'step': 1, 'interval': 60, 'rounds': 20},
  'density': {'duree': 10, 'reps': 5},
  'dropset': {'series': 3, 'reps': 8, 'drops': 2},
  'maxreps': {'series': 3},
  'maxhold': {'series': 3},
  'tempo': {'series': 4, 'reps': 6},
};

ExecMode modeById(String id) =>
    execModes.firstWhere((m) => m.id == id, orElse: () => execModes.first);

int _uidCounter = 0;
String _newUid() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${_uidCounter++}';

class CustomExercise {
  String
  uid; // stable : les logs y restent rattachés même après réordonnancement
  String name;
  String mode; // id ExecMode
  Map<String, dynamic> p; // paramètres du mode
  double? kg;
  int? rest; // s
  String note;
  CustomExercise({
    String? uid,
    required this.name,
    this.mode = 'classic',
    Map<String, dynamic>? p,
    this.kg,
    this.rest,
    this.note = '',
  }) : uid = uid ?? _newUid(),
       p = p ?? {};

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'mode': mode,
    'p': p,
    'kg': kg,
    'rest': rest,
    'note': note,
  };
  CustomExercise.fromJson(Map<String, dynamic> j)
    : uid = j['uid'] as String? ?? _newUid(),
      name = j['name'] as String,
      mode = j['mode'] as String? ?? 'classic',
      p = Map<String, dynamic>.from(j['p'] as Map? ?? {}),
      kg = j['kg'] == null ? null : (j['kg'] as num).toDouble(),
      rest = j['rest'] as int?,
      note = j['note'] as String? ?? '';

  int _pi(String k, int d) => ((p[k] as num?)?.toInt() ?? d).clamp(
    k == 'restI' || k == 'intra' ? 0 : 1,
    3600,
  );
  String _ps(String k, String d) {
    final v = p[k];
    return v is String && v.trim().isNotEmpty ? v : d;
  }

  /// Libellé « Séries × Reps » selon le mode.
  String setsText() {
    switch (mode) {
      case 'myo':
        return '1×${_pi('actReps', 12)} puis ${_pi('minis', 4)}×(${_pi('miniReps', 4)}) · ${_pi('intra', 15)} s intra';
      case 'cluster':
        return '${_pi('series', 4)}×(${_pi('minis', 3)}×${_pi('miniReps', 2)}) · ${_pi('intra', 20)} s intra';
      case 'emom':
        return 'EMOM ${_pi('rounds', 10)}×${_pi('interval', 60)} s · ${_pi('reps', 5)} reps';
      case 'amrap':
        return 'AMRAP ${_pi('duree', 8)} min';
      case 'iso':
        return '${_pi('series', 3)}×${_pi('hold', 30)} s';
      case 'hiit':
        return '${_pi('rounds', 8)}× (${_pi('work', 30)} s effort / ${_pi('restI', 30)} s repos)';
      case 'pyramide':
        return _ps('pyr', '12-10-8-6');
      case 'tabata':
        return '${_pi('rounds', 8)}× (${_pi('work', 20)} s effort / ${_pi('restI', 10)} s repos)';
      case 'deathby':
        return 'EMOM ${_pi('rounds', 20)}×${_pi('interval', 60)} s · Death by ${_pi('startReps', 1)} + ${_pi('step', 1)} / min';
      case 'maxreps':
        return '${_pi('series', 3)}×MAX';
      case 'maxhold':
        return '${_pi('series', 3)}×MAX tenue';
      case 'tempo':
        return '${_pi('series', 4)}×${_pi('reps', 6)} · tempo ${_ps('tempo', '3-1-1-0')}';
      case 'dropset':
        return '${_pi('series', 3)}×(${_pi('reps', 8)} + ${_pi('drops', 2)} palier${_pi('drops', 2) > 1 ? 's' : ''})';
      case 'density':
        return 'Densité ${_pi('duree', 10)} min · séries de ${_pi('reps', 5)}';
      default:
        return '${_pi('series', 4)}×${_pi('reps', 8)}';
    }
  }

  int forcedSets() {
    switch (mode) {
      case 'myo':
        return 1 + _pi('minis', 4);
      case 'cluster':
        return _pi('series', 4);
      case 'emom':
      case 'amrap':
      case 'hiit':
        return 1;
      case 'iso':
        return _pi('series', 3);
      case 'pyramide':
        return _ps('pyr', '12-10-8-6').split(RegExp(r'[-/ ]+')).length;
      case 'tabata':
      case 'deathby':
      case 'density':
        return 1;
      case 'maxreps':
      case 'maxhold':
        return _pi('series', 3);
      case 'tempo':
        return _pi('series', 4);
      case 'dropset':
        return _pi('series', 3) * (1 + _pi('drops', 2));
      default:
        return _pi('series', 4);
    }
  }

  Map<String, dynamic>? timerSpec() {
    switch (mode) {
      case 'emom':
        return {
          'type': 'emom',
          'rounds': _pi('rounds', 10),
          'interval': _pi('interval', 60),
        };
      case 'amrap':
        return {'type': 'amrap', 'sec': _pi('duree', 8) * 60};
      case 'hiit':
        return {
          'type': 'hiit',
          'rounds': _pi('rounds', 8),
          'work': _pi('work', 30),
          'rest': _pi('restI', 30),
        };
      case 'iso':
        return {'type': 'hold', 'sec': _pi('hold', 30)};
      case 'cluster':
        return {'type': 'hold', 'sec': _pi('intra', 20)};
      case 'tabata':
        return {
          'type': 'hiit',
          'rounds': _pi('rounds', 8),
          'work': _pi('work', 20),
          'rest': _pi('restI', 10),
        };
      case 'deathby':
        return {
          'type': 'emom',
          'rounds': _pi('rounds', 20),
          'interval': _pi('interval', 60),
        };
      case 'density':
        return {'type': 'amrap', 'sec': _pi('duree', 10) * 60};
    }
    return null;
  }

  Exercise toExercise(int index) {
    final m = modeById(mode);
    // « Tenues au max » force la saisie chronométrée ; « Tempo » affiche la
    // cadence comme le programme.
    final tempo =
        mode == 'maxhold'
            ? 'Isométrie'
            : mode == 'tempo'
            ? _ps('tempo', '3-1-1-0')
            : '';
    return Exercise.manual(
      id: 'CU-$uid',
      name: name,
      setsText: setsText(),
      intensity: mode == 'classic' ? '' : m.label,
      kg: kg,
      rest: rest == null ? '' : '$rest s',
      restSec: rest,
      tempo: tempo,
      cue: note.isEmpty ? m.desc : note,
      forcedSets: forcedSets(),
      timer: timerSpec(),
    );
  }
}

class CustomSession {
  String id; // numérique unique (clé de journal S0-J<id>)
  String name;
  List<CustomExercise> items;
  CustomSession({
    required this.id,
    required this.name,
    List<CustomExercise>? items,
  }) : items = items ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'items': items.map((e) => e.toJson()).toList(),
  };
  CustomSession.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      name = j['name'] as String,
      items =
          ((j['items'] as List?) ?? [])
              .map((e) => CustomExercise.fromJson(e as Map<String, dynamic>))
              .toList();

  /// Adaptateur vers le runner de séance existant (semaine 0 = perso).
  WeekPlan toWeekPlan() {
    final exs = <Exercise>[];
    for (var i = 0; i < items.length; i++) {
      exs.add(items[i].toExercise(i));
    }
    return WeekPlan.manual(
      n: 0,
      block: name,
      color: const Color(0xFF4FA3C7),
      days: [DayPlan.manual(j: int.parse(id), title: name, exercises: exs)],
    );
  }
}

/// Nature de la saisie d'un exercice, déduite des données.
class LogSpec {
  final String
  kind; // reps | repsMax | hold | holdMax | duration | interval | emom | amrap
  final int? seconds; // tenue (hold) ou durée totale (duration / emom)
  final int? intra; // micro-repos myo-reps / clusters
  final bool myo;
  final bool cluster;
  final String
  rowPrefix; // M (myo) · C (cluster) · É (échelle) · R (round) · T (test)
  const LogSpec(
    this.kind, {
    this.seconds,
    this.intra,
    this.myo = false,
    this.cluster = false,
    this.rowPrefix = '',
  });
  bool get timed => kind == 'hold' || kind == 'holdMax' || kind == 'duration';
}

class AppStore extends ChangeNotifier {
  late final Program program;
  late final SharedPreferences _prefs;

  /// Valeurs Pilotage éditables : PdC (B4), 1RM (B8-B11), max reps (B16-B20),
  /// charges de référence accessoires (B25-B45).
  final Map<String, double> values = {};

  /// Reps de référence des accessoires (colonne D, non éditable).
  final Map<String, int> refReps = {};

  final Map<String, SessionLog> logs = {};

  /// Incrémenté à chaque reset pour forcer le rafraîchissement des champs.
  int pilotageEpoch = 0;

  AppSettings settings = AppSettings();

  /// Ne change qu'au changement de thème : évite de reconstruire MaterialApp
  /// à chaque notification du store.
  final ValueNotifier<String> themeMode = ValueNotifier<String>('system');
  final List<Map<String, dynamic>> dbExercises = []; // base embarquée
  final List<Map<String, dynamic>> userExercises =
      []; // ajoutés par l'utilisateur
  final List<CustomSession> customSessions = [];
  final List<Wod> wods = [];

  static const _kState = 'kalis_state_v3';
  static const _kRecovery = 'kalis_recovery_v1';
  static const _recoveryLimit = 3;
  final ValueNotifier<String?> persistenceError = ValueNotifier<String?>(null);

  /// File unique des écritures (KT-013) : sauvegardes ordinaires, achats et
  /// imports s'exécutent un par un, dans l'ordre de leur demande. La file est
  /// relancée dans la zone de l'appelant : elle ne dépend d'aucun Future créé
  /// ailleurs (un Future terminé dans une autre zone y reporterait la suite).
  final List<Future<void> Function()> _writeQueue = [];
  bool _draining = false;
  Future<void>? _queuedSnapshot;
  bool _initialized = false;

  /// Modifications demandées en mémoire / dernière modification comprise dans
  /// une écriture acceptée par l'API. L'égalité ne prouve pas la présence sur
  /// disque après un arrêt brutal : seule une relance le vérifie.
  int _changeSeq = 0;
  int _acceptedSeq = 0;

  /// Des modifications en mémoire n'ont pas encore été acceptées par l'API.
  bool get hasUnsavedChanges => _acceptedSeq < _changeSeq;

  /// Injection d'erreurs d'écriture pour les tests uniquement. Reçoit le
  /// document encodé ; doit renvoyer le résultat de l'écriture simulée.
  @visibleForTesting
  Future<bool> Function(String encoded)? debugWriteHook;

  static const _kPilotage = 'pilotage_v1';
  static const _kLogs = 'logs_v1';
  static const _kSettings = 'settings_v1';
  static const _kCustom = 'custom_sessions_v1';
  static const _kUserEx = 'user_exercises_v1';
  static const _kWodsLegacy =
      'wods_v1'; // ancien format (catalogue entier dupliqué)
  static const _kWodsUser = 'wods_user_v2'; // WODs créés par l'utilisateur
  static const _kWodsDel = 'wods_del_v2'; // ids de WODs préchargés supprimés
  static const _kWodsEdit =
      'wods_edit_v2'; // id préchargé → définition modifiée
  static const _kWodResults = 'wod_results_v2'; // id → résultats (compressé)
  static const _kSeedV = 'wods_seed_v';
  static const _kLastLevel = 'level_seen';
  static const _kUnlocked = 'unlocked_wods_v1';
  static const _kCreditsV = 'credits_v';

  /// WODs déverrouillés : id → crédits payés (0 = offert par la migration).
  final Map<String, int> unlockedWods = {};

  /// Droits « coût 0 » antérieurs aux crédits v2, conservés sans donner
  /// accès, en attente d'arbitrage (KT-014) : id → origine.
  final Map<String, String> legacyGrants = {};

  /// Achats en cours : id → prix de l'offre acceptée, réservé sur le solde.
  final Map<String, int> _purchases = {};

  Future<void> init() async {
    program = Program.fromJson(
      jsonDecode(await _loadGz('assets/programme_v33.json.gz'))
          as Map<String, dynamic>,
    );
    _prefs = await SharedPreferences.getInstance();

    // Défauts depuis le JSON du classeur.
    final p = program.pilotage;
    values['B4'] = p.bodyweight;
    for (final l in p.mainLifts) {
      values[l.ref] = l.oneRm;
    }
    for (final m in p.repMax) {
      values[m.ref] = m.max;
    }
    for (final a in p.accessories) {
      values[a.ref] = a.refLoad;
      refReps[a.ref] = a.refReps;
    }

    for (final e
        in jsonDecode(await _loadGz('assets/exercises_db.json.gz')) as List) {
      dbExercises.add(Map<String, dynamic>.from(e as Map));
    }
    final saved = _prefs.getString(_kState);
    if (saved != null) {
      _applyBackup(_parseBackup(_unpack(saved)!));
      _rankDifficulty();
      _initialized = true;
      return;
    }

    // Écrase avec les valeurs sauvegardées.
    final sp = _prefs.getString(_kPilotage);
    if (sp != null) {
      final m = jsonDecode(sp) as Map<String, dynamic>;
      m.forEach((k, v) => values[k] = (v as num).toDouble());
    }
    final sl = _unpack(_prefs.getString(_kLogs));
    if (sl != null) {
      final m = jsonDecode(sl) as Map<String, dynamic>;
      m.forEach(
        (k, v) => logs[k] = SessionLog.fromJson(v as Map<String, dynamic>),
      );
    }

    // Base d'exercices embarquée (gzip) + exercices utilisateur.
    final su = _prefs.getString(_kUserEx);
    if (su != null) {
      for (final e in jsonDecode(su) as List) {
        userExercises.add(Map<String, dynamic>.from(e as Map));
      }
    }
    final ss = _prefs.getString(_kSettings);
    if (ss != null) {
      settings = AppSettings.fromJson(jsonDecode(ss) as Map<String, dynamic>);
    }
    themeMode.value = settings.theme;
    final sc = _prefs.getString(_kCustom);
    if (sc != null) {
      for (final e in jsonDecode(sc) as List) {
        customSessions.add(CustomSession.fromJson(e as Map<String, dynamic>));
      }
    }
    await _loadWods();
    _lastLevel = _prefs.getInt(_kLastLevel) ?? level;
    final su2 = _prefs.getString(_kUnlocked);
    if (su2 != null) {
      (jsonDecode(su2) as Map<String, dynamic>).forEach(
        (k, v) => unlockedWods[k] = (v as num).toInt(),
      );
    }
    if ((_prefs.getInt(_kCreditsV) ?? 0) < 2) {
      // v2 : tous les WODs préchargés se gagnent. Règle KT-014 : un accès
      // « coût 0 » de l'ancienne migration reste acquis, gratuitement, si le
      // WOD a au moins un résultat enregistré (droit établi par l'usage) ;
      // sinon il est archivé dans `legacyGrants`, sans accès. Les
      // déverrouillages payés en crédits restent acquis.
      final used = {
        for (final w in wods)
          if (w.results.isNotEmpty) w.id,
      };
      for (final id in [
        for (final e in unlockedWods.entries)
          if (e.value == 0 && !used.contains(e.key)) e.key,
      ]) {
        unlockedWods.remove(id);
        legacyGrants[id] = 'credits_v1';
      }
      await _prefs.setInt(_kCreditsV, 2);
    }
    _rankDifficulty();
    _initialized = true;
    // Migration vers une seule écriture atomique. Les anciennes clés restent
    // disponibles pour récupérer les données si la migration est interrompue.
    await flush();
  }

  // ---------- Crédits de déverrouillage ----------

  /// Prix de base par palier : niveaux 1-3 → 1 crédit (Standard), 4-6 → 2
  /// (Avancé), 7-8 → 3 (Élite), 9-10 → 4 (Légende).
  /// Les WOD personnels des anciennes sauvegardes restent possédés.
  int basePrice(Wod w) {
    if (!isCatalog(w)) return 0;
    if (w.level <= 3) return 1;
    if (w.level <= 6) return 2;
    if (w.level <= 8) return 3;
    return 4;
  }

  /// Prix affiché : prix de base moins la vitrine de la semaine (−1) et
  /// moins un essai terminé (−1), jamais sous 1 crédit. Le prix payé est
  /// figé à l'achat : une remise passée ne change pas un solde.
  int wodCost(Wod w) {
    if (!isCatalog(w)) return 0;
    var price = basePrice(w);
    if (unlocked(w)) return price;
    if (weeklyIds.contains(w.id)) price -= 1;
    if (triedAndDone(w)) price -= 1;
    return max(1, price);
  }

  /// Remise en cours sur un WOD verrouillé (0 = plein tarif).
  int discountOf(Wod w) => unlocked(w) ? 0 : basePrice(w) - wodCost(w);

  /// Un WOD essayé et terminé (essai du jour) reste verrouillé mais garde
  /// ses résultats et coûte 1 crédit de moins.
  bool triedAndDone(Wod w) => w.results.any((r) => r.completed);

  /// Crédits manquants pour un WOD verrouillé (0 = abordable).
  int missingFor(Wod w) => max(0, wodCost(w) - credits);

  /// Barème par niveau (voir [Progression.creditsForLevel]).
  int creditsForLevel(int l) => Progression.creditsForLevel(l);

  /// Crédits gagnés selon le journal actuel : barème du niveau + crédits
  /// dérivés (chapitres bouclés, boss vaincus, semaines complètes).
  int get creditsFromJournal => creditsForLevel(level) + game.bonusCredits;

  /// Registre des gains de crédits déjà attribués (KT-005, option C,
  /// registre par gain approuvé le 25/09/2026) : identifiant du gain →
  /// crédits. Un gain n'est payé qu'une fois et n'est jamais repris ;
  /// `carry:*` conserve un surplus historique non attribuable (migration).
  final Map<String, int> creditGrants = {};

  static final _grantKey = RegExp(
    r'^(?:level:[1-9]\d{0,3}|chapter:[\w-]{1,32}|boss:[\w-]{1,32}|week:\d{4}-\d{2}-\d{2}|carry:[\w-]{1,32})$',
  );

  /// Gains que le journal actuel justifie : chaque palier de niveau atteint,
  /// chapitre bouclé, boss vaincu et semaine complète (par son lundi).
  Map<String, int> get journalGrants {
    final out = <String, int>{};
    for (var n = 1; n <= level; n++) {
      out['level:$n'] =
          creditsForLevel(n) - (n == 1 ? 0 : creditsForLevel(n - 1));
    }
    final g = game;
    for (final c in g.chapters) {
      if (c.complete) out['chapter:${c.key}'] = GameState.creditsPerChapter;
    }
    for (final b in g.bosses) {
      if (b.defeated) out['boss:${b.id}'] = GameState.creditsPerBoss;
    }
    for (final w in progression.weeks.values) {
      if (w.sessions + w.wods >= 3) {
        out['week:${_dayString(w.monday)}'] = GameState.creditsPerFullWeek;
      }
    }
    return out;
  }

  /// Crédits gagnés : gains enregistrés + gains nouveaux du journal pas
  /// encore enregistrés. Corriger ou supprimer une performance fait varier
  /// l'XP et le niveau, jamais ce total ; refaire une performance supprimée
  /// ne repaie pas un gain déjà enregistré, une activité nouvelle oui.
  int get creditsEarned {
    var total = creditGrants.values.fold(0, (a, b) => a + b);
    journalGrants.forEach((id, amount) {
      if (!creditGrants.containsKey(id)) total += amount;
    });
    return total;
  }

  /// Enregistre les gains nouveaux (appelé à chaque écriture acceptée).
  void _recordGrants() {
    journalGrants.forEach(
      (id, amount) => creditGrants.putIfAbsent(id, () => amount),
    );
  }

  /// Migration d'un état sans registre (avant L3) : les gains justifiés par
  /// le journal, plus l'éventuel surplus du plus haut L2 (`creditsEarnedMax`),
  /// conservé tel quel. Aucun crédit créé ni retiré.
  void _migrateGrants(int? earnedMax) {
    creditGrants
      ..clear()
      ..addAll(journalGrants);
    final known = creditGrants.values.fold(0, (a, b) => a + b);
    if (earnedMax != null && earnedMax > known) {
      creditGrants['carry:l2'] = earnedMax - known;
    }
  }

  /// Isolement des tests qui vident le journal entre deux cas : sans cela,
  /// le registre garde les gains du cas précédent.
  @visibleForTesting
  void debugResetEarnedCredits() => creditGrants.clear();

  /// Achats enregistrés + achats en cours (réservés jusqu'à leur résultat).
  int get creditsSpent {
    var total = unlockedWods.values.fold(0, (a, b) => a + b);
    _purchases.forEach((id, cost) {
      if (!unlockedWods.containsKey(id)) total += cost;
    });
    return total;
  }

  /// Solde réel : peut être négatif si les dépenses dépassent les gains
  /// enregistrés (ancienne sauvegarde, ancien calcul). Le déficit est
  /// affiché, jamais masqué ; aucun achat possible tant qu'il n'est pas
  /// comblé par de nouveaux gains (arbitrage du 25/09/2026).
  int get credits => creditsEarned - creditsSpent;

  /// Un achat de ce WOD attend le résultat de son écriture.
  bool purchasePending(Wod w) => _purchases.containsKey(w.id);

  /// Achat au prix de l'offre affichée [acceptedCost] (KT-002). Le droit
  /// n'est annoncé qu'après l'écriture acceptée ; en cas d'échec, seul ce
  /// droit est retiré de la mémoire, les autres modifications sont gardées.
  Future<PurchaseResult> purchaseWod(Wod w, {int? acceptedCost}) async {
    if (unlocked(w)) return const PurchaseResult(PurchaseStatus.alreadyOwned);
    if (_purchases.containsKey(w.id)) {
      return const PurchaseResult(PurchaseStatus.pending);
    }
    final cost = wodCost(w);
    if (acceptedCost != null && acceptedCost != cost) {
      return PurchaseResult(PurchaseStatus.priceChanged, cost: cost);
    }
    if (credits < cost) {
      return PurchaseResult(PurchaseStatus.insufficientCredits, cost: cost);
    }
    _purchases[w.id] = cost;
    notifyListeners();
    return _serialize(() async {
      // Un import a pu changer les droits ou le solde pendant l'attente.
      _purchases.remove(w.id);
      if (unlockedWods.containsKey(w.id)) {
        notifyListeners();
        return const PurchaseResult(PurchaseStatus.alreadyOwned);
      }
      if (credits < cost) {
        notifyListeners();
        return PurchaseResult(PurchaseStatus.insufficientCredits, cost: cost);
      }
      _purchases[w.id] = cost;
      unlockedWods[w.id] = cost;
      _changeSeq++;
      final ok = _initialized && await _commitState();
      _purchases.remove(w.id);
      if (!ok) {
        if (unlockedWods[w.id] == cost) unlockedWods.remove(w.id);
        notifyListeners();
        return PurchaseResult(PurchaseStatus.failed, cost: cost);
      }
      _dataRevision++;
      if (wishlist.remove(w.id)) _persist();
      notifyListeners();
      return PurchaseResult(PurchaseStatus.success, cost: cost);
    });
  }

  // ---------- Liste d'envies ----------
  /// Ids de WODs mis de côté ; le moins cher tient lieu de prochain objectif.
  final Set<String> wishlist = {};

  bool wished(Wod w) => wishlist.contains(w.id);

  void toggleWish(Wod w) {
    if (!wishlist.remove(w.id)) wishlist.add(w.id);
    _persist();
    notifyListeners();
  }

  /// WODs de la liste encore verrouillés, du moins cher au plus cher.
  List<Wod> get wishedWods {
    final out = [
      for (final w in wods)
        if (wishlist.contains(w.id) && !unlocked(w)) w,
    ]..sort((a, b) {
      final c = wodCost(a).compareTo(wodCost(b));
      if (c != 0) return c;
      final l = a.level.compareTo(b.level);
      return l != 0 ? l : a.name.compareTo(b.name);
    });
    return out;
  }

  /// Prochain objectif : le WOD souhaité le moins cher, ou null.
  Wod? get wishTarget => wishedWods.isEmpty ? null : wishedWods.first;

  // ---------- Vitrine : sélections déterministes ----------
  /// Horloge de la vitrine (remplaçable dans les tests) : les sélections du
  /// jour et de la semaine ne dépendent que de la date et du journal.
  DateTime Function() storeClock = DateTime.now;

  static int _fnv(String s) {
    var h = 0x811C9DC5;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h;
  }

  String get _dayKey => civilDay(storeClock()).toIso8601String();
  String get _weekKey => mondayOf(storeClock()).toIso8601String();

  /// Niveau de WOD « à ta mesure » : niveau global de la feuille de
  /// personnage (1-10, même échelle que la difficulté du catalogue).
  int get targetWodLevel => game.sheet.powerLevel.clamp(1, 10);

  /// Sélection déterministe parmi les WODs verrouillés du catalogue : les
  /// candidats préférés d'abord, puis les autres ; à l'intérieur, par [rank]
  /// croissant (0 par défaut) puis par empreinte de « sel|id ».
  List<Wod> _pick(
    String salt,
    int count, {
    required bool Function(Wod) prefer,
    int Function(Wod)? rank,
    Set<String> exclude = const {},
    bool distinctTypes = false,
  }) {
    final pool = [
      for (final w in wods)
        if (isCatalog(w) && !unlocked(w) && !exclude.contains(w.id)) w,
    ];
    final keys = {for (final w in pool) w.id: _fnv('$salt|${w.id}')};
    final rankOf = rank;
    int byKey(Wod a, Wod b) {
      if (rankOf != null) {
        final r = rankOf(a).compareTo(rankOf(b));
        if (r != 0) return r;
      }
      return keys[a.id]!.compareTo(keys[b.id]!);
    }

    final preferred = pool.where(prefer).toList()..sort(byKey);
    final rest = pool.where((w) => !prefer(w)).toList()..sort(byKey);
    final out = <Wod>[];
    final types = <String>{};
    for (final w in preferred.followedBy(rest)) {
      if (distinctTypes && !types.add(w.type)) continue;
      out.add(w);
      if (out.length == count) break;
    }
    return out;
  }

  // Essai du jour et vitrine : état explicite, sauvegardé (KT-004). Une
  // sélection n'est remplacée qu'à une date strictement postérieure : une
  // navigation, un achat, un niveau ou un recul d'horloge ne la relancent pas.
  String? _trialDay;
  String? _trialId;
  String? _weekOf;
  List<String> _weeklyIdsStored = const [];

  static String _dayString(DateTime civil) =>
      civil.toIso8601String().substring(0, 10);

  String get _today => _dayString(civilDay(storeClock()));

  /// Sélection de l'essai d'un jour (règles approuvées) : WOD du catalogue
  /// verrouillé, hors vitrine, jamais tenté ; à ton niveau ±1, sinon ±2,
  /// sinon tout le catalogue ; aucun candidat → pas d'essai ce jour-là.
  String? _selectTrial(String day) {
    final t = targetWodLevel;
    final exclude = {..._weeklyIdsStored};
    for (final spread in const [1, 2, 99]) {
      final pick = _pick(
        'trial|$day',
        1,
        prefer: (w) => w.results.isEmpty && (w.level - t).abs() <= spread,
        exclude: exclude,
      ).where((w) => w.results.isEmpty && (w.level - t).abs() <= spread);
      if (pick.isNotEmpty) return pick.first.id;
    }
    return null;
  }

  /// Essai du jour : fixé pour toute la journée civile locale, même si le
  /// WOD est acheté, tenté ou si le niveau change. Jouable sans limite de
  /// tentatives jusqu'à minuit (règle approuvée). Null : aucun candidat.
  Wod? get trialWod {
    _ensureSelection();
    final id = _trialId;
    if (id == null) return null;
    final cached = _trialWodCache;
    if (cached != null && cached.id == id) return cached;
    for (final w in wods) {
      if (w.id == id) return _trialWodCache = w;
    }
    return null;
  }

  Wod? _trialWodCache;

  /// Établit, si la date locale est strictement postérieure, la vitrine de
  /// la semaine puis l'essai du jour ; remplace dans la vitrine un WOD
  /// acheté par le suivant. Toute nouvelle sélection est sauvegardée.
  void _ensureSelection() {
    _ensureWeekly();
    final today = _today;
    if (_trialDay == null || today.compareTo(_trialDay!) > 0) {
      final migrating = _trialDay == null;
      _trialDay = today;
      _trialId =
          (migrating ? _migratedTrial(today) : null) ?? _selectTrial(today);
      _trialWodCache = null;
      _saveSelection();
    }
  }

  /// Migration sans sélection sauvegardée (état antérieur à L3) : un WOD
  /// verrouillé déjà joué aujourd'hui était l'essai du jour ; il le reste.
  /// Aucun autre historique d'essai n'est inventé.
  String? _migratedTrial(String today) {
    for (final w in wods) {
      if (!isCatalog(w) || unlockedWods.containsKey(w.id)) continue;
      final playedToday = w.results.any((r) {
        final at = DateTime.tryParse(r.at);
        return at != null && _dayString(civilDay(at)) == today;
      });
      if (playedToday) return w.id;
    }
    return null;
  }

  /// Aucun essai possible aujourd'hui (aucun WOD admissible).
  bool get noTrialToday => trialWod == null;

  bool isTrial(Wod w) {
    _ensureSelection();
    return _trialId == w.id;
  }

  /// Jouable maintenant : débloqué, ou essai du jour.
  bool canRun(Wod w) => unlocked(w) || isTrial(w);

  /// Vitrine de la semaine : trois WODs verrouillés de formats différents,
  /// fixés du lundi au dimanche. Règle existante (README 2.5.0) : un WOD
  /// acheté laisse sa place au suivant ; le remplaçant est lui aussi fixé.
  List<Wod> get weeklyPicks {
    _ensureWeekly();
    return [
      for (final id in _weeklyIdsStored)
        for (final w in wods)
          if (w.id == id) w,
    ];
  }

  void _ensureWeekly() {
    final week = _dayString(mondayOf(storeClock()));
    if (_weekOf == null || week.compareTo(_weekOf!) > 0) {
      _weekOf = week;
      _weeklyIdsStored = [for (final w in _pickWeekly(week, const {})) w.id];
      _saveSelection();
    }
    if (!_weeklyIdsStored.any(unlockedWods.containsKey)) return;
    final kept = [
      for (final id in _weeklyIdsStored)
        if (!unlockedWods.containsKey(id)) id,
    ];
    final replacements = _pickWeekly(
      _weekOf!,
      {..._weeklyIdsStored, if (_trialId != null) _trialId!},
      count: _weeklyIdsStored.length - kept.length,
      avoidTypes: {
        for (final w in wods)
          if (kept.contains(w.id)) w.type,
      },
    );
    _weeklyIdsStored = [...kept, for (final w in replacements) w.id];
    _saveSelection();
  }

  List<Wod> _pickWeekly(
    String week,
    Set<String> exclude, {
    int count = 3,
    Set<String> avoidTypes = const {},
  }) {
    final t = targetWodLevel;
    final picks = _pick(
      'weekly|$week',
      count + avoidTypes.length,
      prefer: (w) => w.level >= t - 1 && w.level <= t + 2,
      exclude: exclude,
      distinctTypes: true,
    );
    final preferred = [
      for (final w in picks)
        if (!avoidTypes.contains(w.type)) w,
    ];
    return [
      ...preferred,
      for (final w in picks)
        if (avoidTypes.contains(w.type)) w,
    ].take(count).toList();
  }

  Set<String> get weeklyIds {
    _ensureWeekly();
    return _weeklyIdsStored.toSet();
  }

  /// Une sélection établie (à la première lecture du jour ou de la
  /// semaine) est sauvegardée aussitôt.
  void _saveSelection() {
    if (_initialized) unawaited(_writeSnapshot());
  }

  // ---------- Tentatives de WOD (KT-003) ----------
  /// Tentatives en cours, en mémoire : le droit de terminer est attaché à
  /// une tentative autorisée à son lancement, pas à l'heure de validation.
  /// Il ne survit pas à la fermeture de l'écran ni au processus (reprise
  /// générale : L4b).
  final Map<String, ({String wodId, DateTime startedAt})> _attempts = {};

  /// Démarre une tentative si le WOD est jouable maintenant.
  String? startAttempt(Wod w) {
    if (!canRun(w)) return null;
    final id = _newUid();
    _attempts[id] = (wodId: w.id, startedAt: storeClock());
    return id;
  }

  /// Terminer : WOD jouable, ou tentative autorisée encore ouverte.
  bool canFinish(Wod w, String? attempt) =>
      canRun(w) || (attempt != null && _attempts[attempt]?.wodId == w.id);

  /// Abandon (sortie de l'écran) : la tentative ne peut plus être validée.
  void abandonAttempt(String? attempt) {
    if (attempt != null) _attempts.remove(attempt);
  }

  /// Validation d'un score : un seul résultat par tentative ; succès annoncé
  /// seulement si l'écriture est acceptée. En cas d'échec, le résultat reste
  /// en mémoire (rien n'est perdu) et [retrySave] le réessaie.
  Future<ResultSave> recordWodResult(
    Wod w,
    WodResult r, {
    String? attempt,
  }) async {
    if (attempt != null && w.results.any((x) => x.attempt == attempt)) {
      return await retrySave() ? ResultSave.saved : ResultSave.unsaved;
    }
    if (!canFinish(w, attempt)) return ResultSave.denied;
    r.attempt = attempt;
    addWodResult(w, r);
    _attempts.remove(attempt);
    await flush();
    return hasUnsavedChanges ? ResultSave.unsaved : ResultSave.saved;
  }

  String? _recoKey;
  List<Wod> _reco = const [];

  /// « À ta mesure » : WODs verrouillés à ton niveau (±1), hors essai et
  /// vitrine, renouvelés chaque jour.
  List<Wod> recommended({int count = 8}) {
    final key = '$_dayKey|$count|${unlockedWods.length}';
    if (_recoKey != key) {
      final t = targetWodLevel;
      final trial = trialWod?.id;
      _reco = _pick(
        'reco|$_dayKey',
        count,
        prefer: (w) => (w.level - t).abs() <= 1,
        exclude: {...weeklyIds, if (trial != null) trial},
      );
      _recoKey = key;
    }
    return _reco;
  }

  /// Secondes avant minuit (fin de l'essai du jour).
  Duration get untilMidnight {
    final now = storeClock();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    return midnight.difference(now);
  }

  /// Jours entiers avant le prochain lundi (changement de vitrine).
  int get daysUntilNewWeek {
    final now = storeClock();
    return 8 - now.weekday;
  }

  // ---------- Aperçu d'un WOD : volume, charge de travail, muscles ----------
  static final _splitRe = RegExp(r'\s*(?:\+|·|(?<!\d),(?!\d)|\s/\s| et )\s*');
  static final _partRe = RegExp(
    r'''^(\d+(?:[.,]\d+)?)\s*(km|min|m|s|"|'|″|′)?(?![A-Za-zÀ-ÿ])\s*(.*)$''',
  );
  static final _ladderRe = RegExp(r'^(\d+(?:-\d+){2,})\s+(.*)$');

  List<int> _scheme(String text) {
    final nums = _numRe.allMatches(text).map((m) => int.parse(m[0]!)).toList();
    if (text.contains('/') || nums.isEmpty) return const [];
    if (text.contains('…') || text.contains('→') || text.contains('...')) {
      if (nums.length < 2) return const [];
      final step =
          nums.length > 2
              ? nums[1] - nums[0]
              : (nums.last >= nums.first ? 1 : -1);
      if (step == 0 || (nums.last - nums.first) * step < 0) return const [];
      final count = (nums.last - nums.first).abs() ~/ step.abs() + 1;
      return List.generate(
        count > 1000 ? 1000 : count,
        (i) => nums.first + i * step,
      );
    }
    return nums;
  }

  /// Analyse le mouvement, sans compter les numéros de minute, charges,
  /// annotations par côté ou temps de repos comme des répétitions.
  List<({int reps, int meters, String text})> _parseLine(Wod w, String line) {
    var text = line.trim().replaceAll('–', '-').replaceAll('−', '-');
    final shared = RegExp(
      r'^(\d+)\s+rounds?[^:]*:\s*(.*)$',
      caseSensitive: false,
    ).firstMatch(text);
    if (shared != null) {
      final factor = int.parse(shared[1]!);
      return [
        for (final p in _parseLine(w, shared[2]!))
          (reps: p.reps * factor, meters: p.meters * factor, text: p.text),
      ];
    }
    text = text.replaceFirst(
      RegExp(
        r'^(?:min\b[^:]*|cash in|cash out|finisher|amrap\s+\d+\s*min)\s*:\s*',
        caseSensitive: false,
      ),
      '',
    );
    final block = RegExp(r'^(\d+)\s*[×x]\s*\((.*?)\)(.*)$').firstMatch(text);
    if (block != null) {
      final factor = int.parse(block[1]!);
      return [
        for (final p in _parseLine(w, block[2]!))
          (reps: p.reps * factor, meters: p.meters * factor, text: p.text),
        ..._parseLine(w, block[3]!),
      ];
    }
    final ladder = _ladderRe.firstMatch(text);
    if (ladder != null) {
      return [
        (
          reps: _scheme(ladder[1]!).fold(0, (a, b) => a + b),
          meters: 0,
          text: ladder[2]!,
        ),
      ];
    }
    final out = <({int reps, int meters, String text})>[];
    for (final raw in text.split(_splitRe)) {
      final part = raw.trim();
      if (part.isEmpty || _restRe.hasMatch(part.toLowerCase())) continue;
      final m = _partRe.firstMatch(part);
      if (m != null) {
        final n = double.parse(m[1]!.replaceAll(',', '.'));
        final unit = m[2];
        final move = (m[3] ?? '').trim();
        if (unit == 'm' || unit == 'km') {
          final repetitions = _scheme(w.scheme).length;
          out.add((
            reps: 0,
            meters:
                (n * (unit == 'km' ? 1000 : 1)).round() * max(1, repetitions),
            text: move.isEmpty ? 'run' : move,
          ));
        } else if (unit == null &&
            move.isNotEmpty &&
            !_restRe.hasMatch(move.toLowerCase())) {
          out.add((reps: n.round(), meters: 0, text: move));
        }
        continue;
      }
      if (_maxRe.hasMatch(part.toLowerCase())) {
        out.add((
          reps: 15,
          meters: 0,
          text: part.replaceAll(_maxStripRe, '').trim(),
        ));
      } else if (w.scheme.isNotEmpty) {
        final sum = _scheme(w.scheme).fold(0, (a, b) => a + b);
        if (sum > 0) out.add((reps: sum, meters: 0, text: part));
      }
    }
    return out;
  }

  // ---------- Score historique de classement du catalogue ----------
  // Points par répétition selon le type de mouvement (poids de corps, barre,
  // skills, implements), majorés par le lest, l'enchaînement de mouvements qui
  // sollicitent la même chaîne, les contraintes (unbroken), le format (rounds,
  // repos, AMRAP, EMOM) et les distances. Conservé pour les niveaux et crédits ;
  // les volumes et durées présentés à l'utilisateur viennent de TrainingEstimator.
  static final _moves = <(RegExp, double, String, bool)>[
    // (motif, points par rep ou par 100 m, catégorie, poids de corps)
    (RegExp(r'muscle.?up|\bmu\b'), 4.5, 'pull', true),
    (RegExp(r'hspu|handstand'), 3.2, 'push', true),
    (RegExp(r'wall walk'), 3.5, 'push', true),
    (RegExp(r'dragon'), 3.0, 'core', true),
    (RegExp(r'pistol'), 2.2, 'legs', true),
    (RegExp(r'front lever|planche'), 5.0, 'pull', true),
    (RegExp(r'burpee.{0,12}(box|over|broad|plate)'), 2.2, 'meta', true),
    (RegExp(r'devil press'), 2.5, 'meta', false),
    (RegExp(r'burpee'), 1.7, 'meta', true),
    (RegExp(r'snatch|clean|thruster'), 2.0, 'meta', false),
    (RegExp(r'toes.?to.?bar|t2b'), 1.5, 'core', true),
    (RegExp(r'rows? barre|ring row|row(s)? aux anneaux'), 0.9, 'pull', true),
    (RegExp(r'pull.?up|chin.?up|traction'), 1.7, 'pull', true),
    (RegExp(r'\bdip'), 1.4, 'push', true),
    (RegExp(r'archer|diamond|pike|d[ée]clin'), 1.3, 'push', true),
    (RegExp(r'push.?up|pompe'), 1.0, 'push', true),
    (RegExp(r'wall.?ball'), 1.1, 'meta', false),
    (RegExp(r'kettlebell|kb swing|swing'), 0.9, 'meta', false),
    (RegExp(r'goblet'), 1.0, 'legs', false),
    (RegExp(r'sandbag lunge'), 1.2, 'legs', false),
    (RegExp(r'box jump|squat jump|jumping lunge|saut'), 0.9, 'legs', true),
    (RegExp(r'lunge|fente|step.?up|step.?over'), 0.5, 'legs', true),
    (RegExp(r'squat'), 0.5, 'legs', true),
    (RegExp(r'double.?under'), 0.25, 'meta', true),
    (
      RegExp(r'mountain climber|jumping jack|plank|shoulder tap'),
      0.4,
      'core',
      true,
    ),
    (RegExp(r'sit.?up|v.?up|hollow|leg raise|crunch|abdo'), 0.5, 'core', true),
    (RegExp(r'farmer|carry'), 12.0, 'carry', false),
    (RegExp(r'\bcal\b'), 1.0, 'erg', false),
    (RegExp(r'\brun\b|course|sprint|footing'), 7.5, 'erg', true),
    (RegExp(r'\brow\b|rameur'), 6.0, 'erg', false),
    (RegExp(r'ski'), 6.0, 'erg', false),
    (RegExp(r'bike|erg\b|v[ée]lo'), 2.0, 'erg', false),
  ];

  /// Secondes par répétition (ou par 100 m) — durée estimée et rounds d'AMRAP.
  static final _secs = <(RegExp, double)>[
    (RegExp(r'muscle.?up|\bmu\b|front lever|planche'), 5.0),
    (RegExp(r'hspu|handstand|wall walk|dragon'), 4.0),
    (RegExp(r'burpee|devil'), 4.0),
    (RegExp(r'pull.?up|chin.?up|traction|toes|t2b|pistol'), 3.0),
    (RegExp(r'wall.?ball|snatch|clean|thruster'), 3.0),
    (RegExp(r'\bdip|archer|diamond|pike|goblet|sandbag'), 2.5),
    (
      RegExp(r'push.?up|pompe|box jump|squat jump|jumping|swing|kettlebell'),
      2.0,
    ),
    (RegExp(r'double.?under'), 0.5),
    (RegExp(r'\bcal\b'), 4.0),
    (RegExp(r'farmer|carry'), 40.0),
    (RegExp(r'\brun\b|course|sprint|footing|\brow\b|rameur|ski'), 25.0),
    (RegExp(r'bike|erg\b|v[ée]lo'), 12.0),
  ];

  /// (points par unité, catégorie, poids de corps) pour un texte de mouvement.
  (double, String, bool) _movePoints(String text) {
    final l = text.toLowerCase();
    if (RegExp(r'^cal(?:ories)?\b').hasMatch(l)) return (1.0, 'erg', false);
    for (final (re, pts, cat, bw) in _moves) {
      if (re.hasMatch(l)) return (pts, cat, bw);
    }
    return (0.8, 'meta', true);
  }

  double _moveSeconds(String text) {
    final l = text.toLowerCase();
    for (final (re, sec) in _secs) {
      if (re.hasMatch(l)) return sec;
    }
    return 1.5; // squats, fentes, sit-ups, gainage…
  }

  static final _kgRe = RegExp(r'(\d+(?:[.,]\d+)?)\s*kg');
  static final _unbrokenRe = RegExp(r'unbroken|sans pause|enchaîn');
  static final _rangeRe = RegExp(r'min\s*(\d+)\s*-\s*(\d+)');
  static final _rotRe = RegExp(r'^min\s*\d+\s*,');
  static final _restRe = RegExp(r'^(rest|repos)');
  static final _maxRe = RegExp(r'\bmax\b');
  static final _maxStripRe = RegExp(r'max( de)?', caseSensitive: false);
  static final _numRe = RegExp(r'\d+');

  double _lineSeconds(
    Wod w,
    String line, [
    List<({int reps, int meters, String text})>? parsed,
  ]) {
    var t = 0.0;
    for (final p in parsed ?? _parseLine(w, line)) {
      final sec = _moveSeconds(p.text);
      t +=
          p.meters > 0 ? p.meters / 100 * (sec >= 12 ? sec : 25) : p.reps * sec;
    }

    return t + 5; // transition
  }

  /// Points d'une ligne (un round) : lest, enchaînement, contraintes, multiplicateur « 3 × (…) ».
  double _linePoints(
    Wod w,
    String line,
    String? prevCat,
    void Function(String) setPrevCat, [
    List<({int reps, int meters, String text})>? parsed,
  ]) {
    var total = 0.0;
    final parts = parsed ?? _parseLine(w, line);
    var cat = prevCat;
    for (final p in parts) {
      final (pts, category, bw) = _movePoints(p.text);
      var v = p.meters > 0 ? p.meters / 100 * pts : p.reps * pts;
      if (p.meters > 0 && category != 'erg' && category != 'carry') {
        v = p.meters / 20 * pts; // burpees broad jump, fentes en mètres
      }
      final kg = _kgRe.firstMatch(p.text.toLowerCase());
      if (kg != null && bw) {
        v *=
            1 +
            double.parse(kg.group(1)!.replaceAll(',', '.')) /
                40; // lest sur un mouvement au poids de corps
      }
      if (cat != null && cat == category && category != 'erg') {
        v *= 1.15; // même chaîne enchaînée
      }
      cat = category;
      total += v;
    }
    if (parts.length >= 3) total *= 1.10; // complexe enchaîné sans pause
    if (_unbrokenRe.hasMatch(line.toLowerCase())) total *= 1.2;

    setPrevCat(cat ?? '');
    return total;
  }

  ({int points, int minutes, String level}) wodStats(Wod w) {
    final cached = _statsCache[w.id];
    final legacy =
        cached != null && _statsDefinitions[w.id] == _defJson(w)
            ? cached
            : _computeStats(w);
    final estimate = wodEstimate(w);
    final st = (
      points: legacy.points,
      minutes: max(1, (estimate.elapsed.midpoint / 60).ceil()),
      level: legacy.level,
    );
    _statsCache[w.id] = st;
    _statsDefinitions[w.id] = _defJson(w);
    return st;
  }

  ({int points, int minutes, String level}) _computeStats(Wod w) {
    String? prev;
    final perLine = <double>[];
    var roundSec = 0.0;
    for (final line in w.lines) {
      final parsed = _parseLine(w, line);
      perLine.add(
        _linePoints(w, line, prev, (c) => prev = c.isEmpty ? null : c, parsed),
      );
      roundSec += _lineSeconds(w, line, parsed);
    }
    final roundPts = perLine.fold(0.0, (a, b) => a + b);
    double total;
    int minutes;
    if (w.type == 'amrap') {
      final rounds = max(1.0, w.minutes * 60 / max(20.0, roundSec + 10));
      total = roundPts * rounds * 1.1;
      minutes = w.minutes;
    } else if (w.type == 'emom') {
      final ranged = <double>[];
      var anyRange = false, rotation = false;
      for (var i = 0; i < w.lines.length; i++) {
        final l = w.lines[i].toLowerCase();
        final m = _rangeRe.firstMatch(l);
        if (m != null) {
          anyRange = true;
          ranged.add(
            perLine[i] * (int.parse(m.group(2)!) - int.parse(m.group(1)!) + 1),
          );
        } else {
          if (_rotRe.hasMatch(l) || l.contains('altern')) rotation = true;
          ranged.add(perLine[i]);
        }
      }
      if (anyRange) {
        total = ranged.fold(0.0, (a, b) => a + b);
      } else if (rotation) {
        total = 0;
        for (var i = 0; i < perLine.length; i++) {
          final visits =
              w.rounds ~/ perLine.length +
              (i < w.rounds % perLine.length ? 1 : 0);
          total += perLine[i] * visits;
        }
      } else {
        total = roundPts * w.rounds; // tout à chaque intervalle
      }
      total *= 1.15; // horloge fixe, aucun repos choisi
      minutes = ((w.rounds * w.interval) / 60).round();
    } else {
      final r = (w.type == 'rounds' && w.rounds > 0) ? w.rounds : 1;
      total = roundPts * r * (w.scheme.isNotEmpty ? 1.1 : 1.0);
      if (r > 1) {
        total *= w.restSec == 0 ? 1.08 : (w.restSec >= 90 ? 0.95 : 1.0);
      }
      minutes = ((roundSec * r + (r - 1) * w.restSec) / 60).round().clamp(
        1,
        240,
      );
      if (w.minutes > 0 && minutes > w.minutes) minutes = w.minutes;
    }
    final pts = total.round();
    final lvl =
        pts < 200
            ? 'Légère'
            : pts < 400
            ? 'Modérée'
            : pts < 700
            ? 'Élevée'
            : 'Très élevée';
    return (points: pts, minutes: minutes, level: lvl);
  }

  /// Sollicitation musculaire d'un WOD (mêmes clés que la carte hebdomadaire).
  Map<String, double> wodMuscles(Wod w) => plannedMuscles(wodEstimate(w));

  // ---------- Progression (XP, niveaux, déverrouillage) ----------
  int _lastLevel = 1;

  Progression? _progression;
  DateTime? _progressionDay;
  Progression get progression {
    final now = DateTime.now();
    final day = civilDay(now);
    if (_progression == null || _progressionDay != day) {
      _progression = Progression.calculate(
        logs: logs,
        catalog: wods,
        program: program,
        now: now,
      );
      _progressionDay = day;
    }
    return _progression!;
  }

  @override
  void notifyListeners() {
    _progression = null;
    _game = null;
    _recoKey = null;
    super.notifyListeners();
  }

  // ---------- Couche jeu (dérivée, jamais persistée) ----------
  GameState? _game;
  Progression? _gameSource;

  /// Recalculée dès que la progression l'est. Le jour civil ne suffit pas :
  /// après minuit, si `progression` était lue en premier, elle mettait à jour
  /// `_progressionDay` et le jeu de la veille restait servi.
  GameState get game {
    final p = progression;
    if (_game == null || !identical(_gameSource, p)) {
      _game = GameState.compute(
        progression: p,
        program: program,
        logs: logs,
        refs: values,
        wods: wods,
        isDone: isDone,
        now: DateTime.now(),
        manualWeeklyGoal: settings.weeklyGoal,
      );
      _gameSource = p;
    }
    return _game!;
  }

  /// Titre affiché sur la feuille de personnage : celui choisi s'il est
  /// obtenu, sinon le rang.
  String get displayTitle {
    final chosen = settings.title;
    if (chosen.isNotEmpty &&
        game.titles.any((t) => t.earned && t.name == chosen)) {
      return chosen;
    }
    return progression.rank.title;
  }

  RewardSummary? _pendingReward;

  /// Bilan de la dernière séance ou du dernier score enregistré, consommé par
  /// l'écran de récompenses (une seule fois).
  RewardSummary? consumeReward() {
    final r = _pendingReward;
    _pendingReward = null;
    return r;
  }

  /// Records battus par les séries validées d'une séance face à l'historique
  /// des autres séances.
  List<RecordHit> sessionRecords(String key) {
    final log = logs[key];
    if (log == null) return const [];
    final bests = exerciseBests(logs, excludeKey: key);
    final out = <RecordHit>[];
    final seen = <String>{};
    for (final ex in log.ex.entries) {
      final name = log.exerciseNames[ex.key];
      if (name == null) continue;
      RecordHit? best;
      for (final set in ex.value.sets.where((s) => s.done)) {
        final hit = recordFor(bests, name, set.kg, set.reps);
        if (hit != null && (best == null || hit.current > best.current)) {
          best = hit;
        }
      }
      if (best != null && seen.add(name)) out.add(best);
    }
    return out;
  }

  /// Record battu par une série en cours de séance (séance `key` exclue de
  /// l'historique), pour la bannière en direct.
  RecordHit? liveRecord(String key, String exercise, String kg, String reps) =>
      recordFor(exerciseBests(logs, excludeKey: key), exercise, kg, reps);

  int get xp => progression.totalXp;
  static int needFor(int l) => Progression.needFor(l);
  int get level => progression.level;
  ({int inLevel, int need}) get levelProgress => (
    inLevel: progression.inLevel,
    need: progression.need,
  );

  /// Possédé : hors catalogue (WOD personnel) ou acheté avec des crédits
  /// dont l'écriture a été acceptée.
  bool unlocked(Wod w) =>
      !isCatalog(w) ||
      (unlockedWods.containsKey(w.id) && !_purchases.containsKey(w.id));

  /// Si le niveau a monté depuis la dernière vérification : (ancien, nouveau,
  /// crédits gagnés), sinon null. À appeler après une séance ou un score.
  ({int from, int to, int credits})? consumeLevelUp() {
    final now = level;
    if (now <= _lastLevel) return null;
    final from = _lastLevel;
    _lastLevel = now;
    _persist();
    return (
      from: from,
      to: now,
      credits: creditsForLevel(now) - creditsForLevel(from),
    );
  }

  // ---------- WODs ----------
  // Le catalogue préchargé vit dans le code ; on ne persiste que les WODs créés,
  // les suppressions, les modifications d'un préchargé et les résultats.
  /// Catalogue complet : sélection (préchargés) + première série générée
  /// (jusqu'à 500) + deuxième série générée (500 de plus, ids « genx… »).
  List<Wod> catalogWods() {
    final seeds = allSeedWods();
    return [
      ...seeds,
      ...generateWods(generatedCount(seeds.length)),
      ...generateWodsV2(generatedCountV2),
    ];
  }

  late final Map<String, Wod> _seedDefaults = {
    for (final w in catalogWods()) w.id: w,
  };

  /// Définition JSON de chaque WOD préchargé, calculée une fois : la
  /// sauvegarde compare le millier de WODs du catalogue à leur version
  /// d'origine à chaque écriture, sans réencoder l'original.
  late final Map<String, String> _seedJson = {
    for (final e in _seedDefaults.entries) e.key: _defJson(e.value),
  };

  /// Définition comparable (sans résultats ni niveau, qui est recalculé).
  static Map<String, dynamic> _definition(Wod w) => {
    'id': w.id,
    'name': w.name,
    'type': w.type,
    'rounds': w.rounds,
    'restSec': w.restSec,
    'minutes': w.minutes,
    'interval': w.interval,
    'scheme': w.scheme,
    'lines': w.lines,
    'notes': w.notes,
    'source': w.source,
  };
  static String _defJson(Wod w) => jsonEncode(_definition(w));

  bool isCatalog(Wod w) => _seedDefaults.containsKey(w.id);
  bool isGenerated(Wod w) => w.id.startsWith('gen');

  Future<void> _loadWods() async {
    wods.clear();
    final legacy = _prefs.getString(_kWodsLegacy);
    if (legacy != null) {
      await _migrateLegacyWods(legacy);
    }
    final deleted =
        ((jsonDecode(_prefs.getString(_kWodsDel) ?? '[]') as List).map(
          (e) => e.toString(),
        )).toSet();
    final edits =
        jsonDecode(_prefs.getString(_kWodsEdit) ?? '{}')
            as Map<String, dynamic>;
    final results =
        jsonDecode(_unpack(_prefs.getString(_kWodResults)) ?? '{}')
            as Map<String, dynamic>;
    for (final seed in _seedDefaults.values) {
      if (deleted.contains(seed.id)) continue;
      final w =
          edits.containsKey(seed.id)
              ? Wod.fromJson(edits[seed.id] as Map<String, dynamic>)
              : Wod.fromJson(seed.toJson());
      w.results = _resultsOf(results, w.id);
      wods.add(w);
    }
    for (final e in jsonDecode(_prefs.getString(_kWodsUser) ?? '[]') as List) {
      final w = Wod.fromJson(e as Map<String, dynamic>);
      w.results = _resultsOf(results, w.id);
      wods.insert(0, w);
    }
    await _prefs.setInt(_kSeedV, 4);
  }

  /// Classement du catalogue (déciles), disponible avant tout déverrouillage.
  void rankCatalog() {
    _rankDifficulty();
    notifyListeners();
  }

  // ---------- Difficulté automatique (déciles du catalogue) ----------
  List<double> _levelCuts = const [];
  final Map<String, String> _statsDefinitions = {};
  final Map<String, ({String key, TrainingEstimate value})> _wodEstimates = {};
  final Map<String, ({int points, int minutes, String level})> _statsCache = {};

  double difficultyScore(Wod w) => _computeStats(w).points.toDouble();

  /// Classe tout le catalogue par déciles de score → niveau 1-10, et applique le
  /// même barème aux WODs de l'utilisateur.
  void _rankDifficulty() {
    final scores = [
      for (final w in _seedDefaults.values) _computeStats(w).points.toDouble(),
    ]..sort();
    if (scores.length >= 10) {
      _levelCuts = [
        for (var k = 1; k < 10; k++) scores[(scores.length * k / 10).floor()],
      ];
    }
    for (final w in wods) {
      w.level = levelFor(w);
    }
  }

  int levelFor(Wod w) {
    if (_levelCuts.isEmpty) return w.level;
    final sc = difficultyScore(w);
    var lvl = 1;
    for (final c in _levelCuts) {
      if (sc >= c) lvl++;
    }
    return lvl.clamp(1, 10);
  }

  List<WodResult> _resultsOf(Map<String, dynamic> all, String id) =>
      ((all[id] as List?) ?? [])
          .map((r) => WodResult.fromJson(r as Map<String, dynamic>))
          .toList();

  /// Ancien format : liste complète (catalogue + perso + résultats) → nouveau format.
  Future<void> _migrateLegacyWods(String raw) async {
    final old =
        (jsonDecode(raw) as List)
            .map((e) => Wod.fromJson(e as Map<String, dynamic>))
            .toList();
    final present = old.map((w) => w.id).toSet();
    final known = [
      for (var k = 1; k <= 30; k++) 'seed$k',
    ]; // fournées 1 et 2 uniquement
    final deleted = [
      for (final id in known)
        if (!present.contains(id)) id,
    ];
    final user = <Map<String, dynamic>>[];
    final edits = <String, dynamic>{};
    final results = <String, dynamic>{};
    for (final w in old) {
      if (w.results.isNotEmpty) {
        results[w.id] = w.results.map((r) => r.toJson()).toList();
      }
      final seed = _seedDefaults[w.id];
      if (seed == null) {
        user.add(_definition(w));
      } else {
        if (w.level == 1 && seed.level != 1) {
          w.level = seed.level; // niveaux de la fournée 2
        }
        if (_defJson(w) != _defJson(seed)) {
          edits[w.id] = _definition(w);
        }
      }
    }
    await _prefs.setString(_kWodsDel, jsonEncode(deleted));
    await _prefs.setString(_kWodsEdit, jsonEncode(edits));
    await _prefs.setString(_kWodsUser, jsonEncode(user));
    await _prefs.setString(_kWodResults, _pack(jsonEncode(results)));
  }

  void _saveWods() {
    _persist();
    notifyListeners();
  }

  void _saveWodResults() => _persist();

  // ---------- Compression des gros blobs (gzip + base64) ----------
  static String _pack(String s) =>
      s.length < 1500 ? s : 'gz:${base64Encode(gzip.encode(utf8.encode(s)))}';
  static String? _unpack(String? s) {
    if (s == null) return null;
    if (!s.startsWith('gz:')) return s;
    return utf8.decode(gzip.decode(base64Decode(s.substring(3))));
  }

  static Future<String> _loadGz(String asset) async {
    final data = await rootBundle.load(asset);
    return utf8.decode(
      gzip.decode(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      ),
    );
  }

  /// Données de test et compatibilité des anciennes prescriptions sauvegardées.
  /// Aucun écran de création ou de modification n’expose cette opération.
  @visibleForTesting
  void upsertWod(Wod w) {
    _trialWodCache = null;
    _statsCache.remove(w.id);
    _wodEstimates.remove(w.id);
    final i = wods.indexWhere((x) => x.id == w.id);
    if (i >= 0) {
      wods[i] = w;
    } else {
      wods.insert(0, w);
    }
    w.level = levelFor(w);
    _saveWods();
  }

  void addWodResult(Wod w, WodResult r) {
    final before = progression;
    final creditsBefore = credits;
    r.prescription ??= w.prescriptionKey;
    w.results.add(r);
    _saveWodResults();
    notifyListeners();
    final after = progression;
    if (after.totalXp <= before.totalXp) return;
    _pendingReward = RewardSummary.build(
      before: before,
      after: after,
      heading: r.completed ? 'WOD terminé' : 'Tentative enregistrée',
      title: w.name,
      creditsBefore: creditsBefore,
      creditsAfter: credits,
      baseXp: 80,
      baseLabel: 'Tentative WOD',
    );
  }

  void deleteWodResult(Wod w, WodResult r) {
    w.results.remove(r);
    _saveWodResults();
    notifyListeners();
  }

  // ---------- Réglages ----------
  void saveSettings() {
    _persist();
    if (themeMode.value != settings.theme) themeMode.value = settings.theme;
    notifyListeners();
  }

  String get effortLabel => settings.rpe ? 'RPE' : 'RIR';

  // ---------- Base d'exercices ----------
  List<Map<String, dynamic>>? _allEx;
  List<Map<String, dynamic>> get allExercises =>
      _allEx ??= [...dbExercises, ...userExercises];

  void addUserExercise(String name, String group, String equip) {
    userExercises.add({'n': name, 'g': group, 'eq': equip});
    _allEx = null;
    _muscleIndex = null;
    _persist();
    notifyListeners();
  }

  // ---------- Séances personnalisées ----------
  void _saveCustom() {
    _persist();
    notifyListeners();
  }

  String newSessionId() {
    var id = DateTime.now().microsecondsSinceEpoch;
    while (customSessions.any((s) => s.id == '$id')) {
      id++;
    }
    return '$id';
  }

  void upsertSession(CustomSession s) {
    final i = customSessions.indexWhere((x) => x.id == s.id);
    if (i >= 0) {
      customSessions[i] = s;
    } else {
      customSessions.add(s);
    }
    _saveCustom();
  }

  void deleteSession(CustomSession s) {
    customSessions.removeWhere((x) => x.id == s.id);
    logs.removeWhere(
      (k, v) => k == 'S0-J${s.id}' || k.startsWith('S0-J${s.id}@'),
    );
    _saveCustom();
    saveLogs(immediate: true);
  }

  void duplicateSession(CustomSession s) {
    final copy = CustomSession.fromJson(s.toJson());
    copy.id = newSessionId();
    copy.name = '${s.name} (copie)';
    customSessions.add(copy);
    _saveCustom();
  }

  // ---------- Sauvegarde : un document, une écriture atomique ----------
  _BackupData _currentBackup() => _BackupData(
    values: values,
    logs: logs,
    settings: settings,
    custom: customSessions,
    userExercises: userExercises,
    wods: wods,
    unlocked: unlockedWods,
    legacyGrants: legacyGrants,
    lastLevel: _lastLevel,
    earnedMax: creditsEarned,
    creditGrants: creditGrants,
    trialDay: _trialDay,
    trialId: _trialId,
    weekOf: _weekOf,
    weeklyIds: _weeklyIdsStored,
    wishlist: wishlist.toList(),
  );

  Map<String, dynamic> _backupJson(_BackupData data) {
    final edits = <String, dynamic>{};
    final user = <Map<String, dynamic>>[];
    final present = data.wods.map((w) => w.id).toSet();
    for (final w in data.wods) {
      if (!_seedDefaults.containsKey(w.id)) {
        user.add(_definition(w));
      } else if (_defJson(w) != _seedJson[w.id]) {
        edits[w.id] = _definition(w);
      }
    }
    return {
      'kalisTrack': 1,
      'format': 3,
      'pilotage': data.values,
      'logs': data.logs.map((k, v) => MapEntry(k, v.toJson())),
      'settings': data.settings.toJson(),
      'custom': data.custom.map((s) => s.toJson()).toList(),
      'userExercises': data.userExercises,
      'catalog': {
        'deleted': [
          for (final id in _seedDefaults.keys)
            if (!present.contains(id)) id,
        ],
        'edits': edits,
        'user': user,
        'results': {
          for (final w in data.wods)
            if (w.results.isNotEmpty)
              w.id: w.results.map((r) => r.toJson()).toList(),
        },
      },
      'unlocked': data.unlocked,
      if (data.legacyGrants.isNotEmpty) 'legacyGrants': data.legacyGrants,
      'lastLevel': data.lastLevel,
      if (data.earnedMax != null) 'creditsEarnedMax': data.earnedMax,
      if (data.creditGrants != null) 'creditGrants': data.creditGrants,
      if (data.trialDay != null)
        'trialOfDay': {'day': data.trialDay, 'wod': data.trialId},
      if (data.weekOf != null)
        'weeklyShowcase': {'week': data.weekOf, 'ids': data.weeklyIds},
      'wishlist': data.wishlist,
    };
  }

  String exportAll() => jsonEncode(_backupJson(_currentBackup()));
  String exportCompact() => _pack(exportAll());

  /// [limits] : import d'un texte externe (KT-015). Sans limites : état
  /// produit par l'application elle-même, relu au démarrage.
  _BackupData _parseBackup(String raw, {ImportLimits? limits}) {
    final m =
        (limits == null ? jsonDecode(raw) : boundedJsonDecode(raw, limits))
            as Map<String, dynamic>;
    if (m['kalisTrack'] != 1 || ![1, 2, 3].contains(m['format'] ?? 1)) {
      throw const FormatException('Format de sauvegarde non pris en charge.');
    }
    if (limits != null) _checkCollections(m, limits);
    // Tout construire et valider AVANT de modifier le store ou le disque.
    final defaults = program.pilotage;
    final nextValues = <String, double>{
      'B4': defaults.bodyweight,
      for (final l in defaults.mainLifts) l.ref: l.oneRm,
      for (final r in defaults.repMax) r.ref: r.max,
      for (final a in defaults.accessories) a.ref: a.refLoad,
    };
    (m['pilotage'] as Map<String, dynamic>).forEach((k, v) {
      final n = (v as num).toDouble();
      if (!n.isFinite || n < 0 || n > 10000 || (k == 'B4' && n == 0)) {
        throw const FormatException('Valeur de pilotage invalide.');
      }
      nextValues[k] = n;
    });
    final nextLogs = (m['logs'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, SessionLog.fromJson(v as Map<String, dynamic>)),
    );
    final nextSettings = AppSettings.fromJson(
      m['settings'] as Map<String, dynamic>,
    );
    if (!['system', 'dark', 'light'].contains(nextSettings.theme) ||
        nextSettings.notifHour < 0 ||
        nextSettings.notifHour > 23 ||
        nextSettings.notifMinute < 0 ||
        nextSettings.notifMinute > 59 ||
        nextSettings.prepSec < 0 ||
        nextSettings.prepSec > 60 ||
        nextSettings.defaultRest < 0 ||
        nextSettings.defaultRest > 3600) {
      throw const FormatException('Réglages invalides.');
    }
    final nextCustom =
        ((m['custom'] as List?) ?? [])
            .map((e) => CustomSession.fromJson(e as Map<String, dynamic>))
            .toList();
    final ids = <String>{};
    for (final session in nextCustom) {
      if (int.tryParse(session.id) == null ||
          !ids.add(session.id) ||
          session.name.trim().isEmpty ||
          session.items.length > 1000) {
        throw const FormatException('Séance personnalisée invalide.');
      }
      final exerciseIds = <String>{};
      for (final ex in session.items) {
        if (ex.name.trim().isEmpty ||
            !exerciseIds.add(ex.uid) ||
            !execModes.any((m) => m.id == ex.mode) ||
            (ex.kg != null && (!ex.kg!.isFinite || ex.kg!.abs() > 10000)) ||
            (ex.rest != null && (ex.rest! < 0 || ex.rest! > 86400))) {
          throw const FormatException('Exercice personnalisé invalide.');
        }
        for (final entry in ex.p.entries) {
          if (entry.key == 'pyr') {
            if (entry.value is! String ||
                !RegExp(
                  r'^\d+(?:[-/ ]+\d+)*$',
                ).hasMatch((entry.value as String).trim())) {
              throw const FormatException('Pyramide invalide.');
            }
          } else if (entry.value is! num ||
              !(entry.value as num).isFinite ||
              (entry.value as num) <
                  (['intra', 'restI'].contains(entry.key) ? 0 : 1) ||
              (entry.value as num) > 3600 ||
              (entry.value as num) % 1 != 0) {
            throw const FormatException('Paramètre de séance invalide.');
          }
        }
      }
    }
    final nextUser =
        ((m['userExercises'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
    for (final ex in nextUser) {
      if (ex['n'] is! String ||
          (ex['n'] as String).trim().isEmpty ||
          ex['g'] is! String ||
          ex['eq'] is! String) {
        throw const FormatException('Base d’exercices invalide.');
      }
    }
    final nextWods = <Wod>[];
    if (m['format'] == 3) {
      final catalog = m['catalog'] as Map<String, dynamic>;
      final deleted = (catalog['deleted'] as List).cast<String>().toSet();
      final edits = catalog['edits'] as Map<String, dynamic>;
      final results = catalog['results'] as Map<String, dynamic>;
      for (final seed in _seedDefaults.values) {
        if (deleted.contains(seed.id)) continue;
        final w = Wod.fromJson(
          (edits[seed.id] as Map<String, dynamic>?) ?? seed.toJson(),
        );
        if (w.id != seed.id) {
          throw const FormatException('Identifiant de WOD incohérent.');
        }
        w.results = _resultsOf(results, w.id);
        nextWods.add(w);
      }
      for (final e in catalog['user'] as List) {
        final w = Wod.fromJson(e as Map<String, dynamic>);
        w.results = _resultsOf(results, w.id);
        nextWods.add(w);
      }
    } else {
      nextWods.addAll(
        ((m['wods'] as List?) ??
                _seedDefaults.values.map((w) => w.toJson()).toList())
            .map((e) => Wod.fromJson(e as Map<String, dynamic>)),
      );
    }
    final wodIds = <String>{};
    for (final w in nextWods) {
      if (!wodIds.add(w.id) ||
          w.id.isEmpty ||
          w.name.trim().isEmpty ||
          !wodTypes.containsKey(w.type) ||
          w.rounds < 0 ||
          w.rounds > 3600 ||
          w.interval <= 0 ||
          w.interval > 86400 ||
          w.minutes < 0 ||
          w.minutes > 1440 ||
          w.restSec < 0 ||
          w.restSec > 86400 ||
          (w.type == 'emom' && w.rounds == 0) ||
          (w.type == 'amrap' && w.minutes == 0)) {
        throw const FormatException('WOD invalide.');
      }
      for (final r in w.results) {
        if ((r.attempt?.length ?? 0) > 64 ||
            DateTime.tryParse(r.at) == null ||
            (r.seconds ?? 0) < 0 ||
            (r.rounds ?? 0) < 0 ||
            (r.reps ?? 0) < 0) {
          throw const FormatException('Résultat invalide.');
        }
      }
    }
    for (final entry in nextLogs.entries) {
      if (!RegExp(r'^S\d+-J\d+(?:@.+)?$').hasMatch(entry.key)) {
        throw const FormatException('Identifiant de séance invalide.');
      }
      final log = entry.value;
      if (log.finishedAt != null &&
          DateTime.tryParse(log.finishedAt!) == null) {
        throw const FormatException('Date de séance invalide.');
      }
      for (final ex in log.ex.values) {
        if (ex.sets.length > 1000) {
          throw const FormatException('Trop de séries.');
        }
        for (final set in ex.sets) {
          if (set.completedAt != null &&
              DateTime.tryParse(set.completedAt!) == null) {
            throw const FormatException('Date de série invalide.');
          }
        }
      }
    }
    final nextUnlocked = <String, int>{};
    final nextLegacy = <String, String>{};
    (m['legacyGrants'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      if (v is! String || k.isEmpty) {
        throw const FormatException('Droits anciens invalides.');
      }
      nextLegacy[k] = v;
    });
    final format = (m['format'] ?? 1) as int;
    final used = {
      for (final w in nextWods)
        if (w.results.isNotEmpty) w.id,
    };
    (m['unlocked'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      if (v is! int || v < 0) throw const FormatException('Crédits invalides.');
      // Formats 1-2 (avant les crédits v2) : un coût 0 d'un WOD du catalogue
      // vient de l'ancienne migration. Même règle qu'au démarrage (KT-014) :
      // acquis s'il a été joué, sinon archivé sans accès.
      if (limits != null &&
          format < 3 &&
          v == 0 &&
          _seedDefaults.containsKey(k) &&
          !used.contains(k)) {
        nextLegacy[k] = 'import_format_$format';
        return;
      }
      nextUnlocked[k] = v;
    });
    final nextWishlist = <String>[];
    for (final id in (m['wishlist'] as List?) ?? const []) {
      if (id is! String) {
        throw const FormatException('Liste d’envies invalide.');
      }
      if (!nextWishlist.contains(id)) nextWishlist.add(id);
    }
    final earnedMax = m['creditsEarnedMax'];
    if (earnedMax != null &&
        (earnedMax is! int || earnedMax < 0 || earnedMax > 1000000)) {
      throw const FormatException('Crédits gagnés invalides.');
    }
    Map<String, int>? grants;
    final rawGrants = m['creditGrants'];
    if (rawGrants != null) {
      if (rawGrants is! Map) throw const FormatException('Registre invalide.');
      grants = {};
      rawGrants.forEach((k, v) {
        if (k is! String ||
            !_grantKey.hasMatch(k) ||
            v is! int ||
            v < 0 ||
            v > 1000000) {
          throw const FormatException('Registre de crédits invalide.');
        }
        grants![k] = v;
      });
    }
    final dayRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    String? trialDay, trialId, weekOf;
    var weekly = <String>[];
    final trial = m['trialOfDay'];
    if (trial != null) {
      if (trial is! Map ||
          trial['day'] is! String ||
          !dayRe.hasMatch(trial['day'] as String) ||
          (trial['wod'] != null && trial['wod'] is! String)) {
        throw const FormatException('Essai du jour invalide.');
      }
      trialDay = trial['day'] as String;
      trialId = trial['wod'] as String?;
    }
    final showcase = m['weeklyShowcase'];
    if (showcase != null) {
      if (showcase is! Map ||
          showcase['week'] is! String ||
          !dayRe.hasMatch(showcase['week'] as String) ||
          showcase['ids'] is! List ||
          (showcase['ids'] as List).length > 3 ||
          (showcase['ids'] as List).any((e) => e is! String)) {
        throw const FormatException('Vitrine invalide.');
      }
      weekOf = showcase['week'] as String;
      weekly = (showcase['ids'] as List).cast<String>();
    }
    return _BackupData(
      values: nextValues,
      logs: nextLogs,
      settings: nextSettings,
      custom: nextCustom,
      userExercises: nextUser,
      wods: nextWods,
      unlocked: nextUnlocked,
      legacyGrants: nextLegacy,
      lastLevel: m['lastLevel'] as int?,
      earnedMax: earnedMax,
      creditGrants: grants,
      trialDay: trialDay,
      trialId: trialId,
      weekOf: weekOf,
      weeklyIds: weekly,
      wishlist: nextWishlist,
    );
  }

  /// Tailles des collections d'un import, avant toute conversion (KT-015).
  static void _checkCollections(Map<String, dynamic> m, ImportLimits limits) {
    void cap(Object? value, int limit, String what) {
      final n =
          value is Map ? value.length : (value is List ? value.length : 0);
      if (n > limit) throw ImportLimitException('Trop de $what.');
    }

    final logs = m['logs'];
    cap(logs, limits.maxLogs, 'séances');
    var sets = 0;
    if (logs is Map) {
      for (final log in logs.values) {
        final ex = log is Map ? log['ex'] : null;
        if (ex is! Map) continue;
        for (final e in ex.values) {
          final list = e is Map ? e['sets'] : null;
          if (list is List) sets += list.length;
        }
      }
    }
    if (sets > limits.maxSets) {
      throw const ImportLimitException('Trop de séries.');
    }
    cap(m['custom'], limits.maxEntries, 'séances perso');
    cap(m['userExercises'], limits.maxEntries, 'exercices perso');
    cap(m['unlocked'], limits.maxEntries, 'droits WOD');
    cap(m['legacyGrants'], limits.maxEntries, 'droits anciens');
    cap(m['creditGrants'], limits.maxEntries, 'gains de crédits');
    cap(m['wishlist'], limits.maxEntries, 'envies');
    cap(m['wods'], limits.maxEntries, 'WODs');
    final catalog = m['catalog'];
    if (catalog is Map) {
      cap(catalog['user'], limits.maxEntries, 'WODs perso');
      cap(catalog['edits'], limits.maxEntries, 'WODs modifiés');
      cap(catalog['deleted'], limits.maxEntries, 'WODs supprimés');
      var results = 0;
      final all = catalog['results'];
      if (all is Map) {
        for (final list in all.values) {
          if (list is List) results += list.length;
        }
      }
      if (results > limits.maxResults) {
        throw const ImportLimitException('Trop de résultats de WOD.');
      }
    }
  }

  void _applyBackup(_BackupData data) {
    _progression = null;
    values
      ..clear()
      ..addAll(data.values);
    logs
      ..clear()
      ..addAll(data.logs);
    settings = data.settings;
    customSessions
      ..clear()
      ..addAll(data.custom);
    userExercises
      ..clear()
      ..addAll(data.userExercises);
    wods
      ..clear()
      ..addAll(data.wods);
    unlockedWods
      ..clear()
      ..addAll(data.unlocked);
    legacyGrants
      ..clear()
      ..addAll(data.legacyGrants);
    wishlist
      ..clear()
      ..addAll(data.wishlist);
    _allEx = null;
    _muscleIndex = null;
    _statsCache.clear();
    _wodEstimates.clear();
    _statsDefinitions.clear();
    pilotageEpoch++;
    themeMode.value = settings.theme;
    _lastLevel = data.lastLevel ?? level;
    _trialDay = data.trialDay;
    _trialId = data.trialId;
    _trialWodCache = null;
    _weekOf = data.weekOf;
    _weeklyIdsStored = List.of(data.weeklyIds);
    _attempts.clear();
    // Registre absent (état antérieur à L3) : migration explicite, sur un
    // catalogue classé (les XP de WOD dépendent du niveau des WODs).
    final grants = data.creditGrants;
    if (grants == null) {
      _rankDifficulty();
      _migrateGrants(data.earnedMax);
    } else {
      creditGrants
        ..clear()
        ..addAll(grants);
    }
  }

  /// Import compatible avec l'API historique : `true` si tout est appliqué.
  Future<bool> importAll(String raw) async =>
      await importBackup(raw) == ImportStatus.success;

  /// Remplace toutes les données par une sauvegarde (KT-013 / KT-015).
  /// Validation complète et bornée avant toute modification ; l'état courant
  /// (modifications non écrites comprises) est d'abord conservé comme copie
  /// de récupération ; l'import passe dans la file des écritures et n'est
  /// appliqué en mémoire qu'après l'écriture acceptée.
  Future<ImportStatus> importBackup(
    String raw, {
    ImportLimits limits = ImportLimits.standard,
  }) async {
    final result = previewImport(raw, limits: limits);
    final preview = result.preview;
    if (preview == null) return result.status;
    return _commitImport(preview._data, preview._encoded);
  }

  /// Révision des données métier : augmente à chaque modification réelle
  /// (pas lors d'un simple enregistrement ou d'un passage en arrière-plan).
  int get dataRevision => _dataRevision;
  int _dataRevision = 0;

  /// Lecture, validation et résumé d'une sauvegarde, sans aucune
  /// modification (L2b). Le texte validé est conservé : l'import confirmé
  /// applique exactement ce contenu.
  ({ImportStatus status, ImportPreview? preview}) previewImport(
    String raw, {
    ImportLimits limits = ImportLimits.standard,
  }) {
    try {
      final text = boundedUnpack(raw, limits);
      final data = _parseBackup(text, limits: limits);
      final meta = jsonDecode(text) as Map<String, dynamic>;
      return (
        status: ImportStatus.success,
        preview: ImportPreview._(
          data: data,
          encoded: _pack(jsonEncode(_backupJson(data))),
          meta: meta,
          progression: Progression.calculate(
            logs: data.logs,
            catalog: data.wods,
            program: program,
            now: DateTime.now(),
          ),
          customWods:
              data.wods.where((w) => !_seedDefaults.containsKey(w.id)).length,
          localRevision: _dataRevision,
        ),
      );
    } on ImportLimitException {
      return (status: ImportStatus.tooLarge, preview: null);
    } catch (_) {
      return (status: ImportStatus.invalid, preview: null);
    }
  }

  /// Applique un aperçu confirmé. Si les données locales ont changé depuis
  /// l'aperçu, rien n'est modifié ([ImportStatus.conflict]).
  Future<ImportStatus> applyImport(ImportPreview preview) => _commitImport(
    preview._data,
    preview._encoded,
    expectedRevision: preview.localRevision,
  );

  Future<ImportStatus> _commitImport(
    _BackupData data,
    String encoded, {
    int? expectedRevision,
  }) {
    return _serialize(() async {
      if (!_initialized) return ImportStatus.writeFailed;
      if (expectedRevision != null && expectedRevision != _dataRevision) {
        return ImportStatus.conflict;
      }
      if (!await _keepRecoveryCopy('import')) {
        persistenceError.value =
            'Import interrompu : copie de sécurité impossible. Tes données actuelles sont conservées.';
        return ImportStatus.writeFailed;
      }
      if (!await _writeRaw(encoded)) {
        persistenceError.value =
            'La sauvegarde a échoué. Tes données actuelles sont conservées.';
        return ImportStatus.writeFailed;
      }
      _applyBackup(data);
      _rankDifficulty();
      // Aucune cérémonie de niveau ni bilan pour des acquis déjà présents
      // dans la sauvegarde restaurée.
      _lastLevel = max(_lastLevel, level);
      _pendingReward = null;
      _dataRevision++;
      // Mémoire et document écrit sont identiques : plus rien d'antérieur à
      // écrire. Une sauvegarde déjà demandée réécrira simplement cet état.
      _acceptedSeq = _changeSeq;
      persistenceError.value = null;
      notifyListeners();
      return ImportStatus.success;
    });
  }

  /// Contenu d'un fichier de sauvegarde : format 3 actuel, avec la date
  /// d'export et la version de l'application (champs optionnels, ignorés
  /// par les versions précédentes). Instantané synchrone de la mémoire.
  String exportForFile({required String appVersion, DateTime? at}) {
    final data = _backupJson(_currentBackup());
    data['exportedAt'] = (at ?? DateTime.now()).toIso8601String();
    data['appVersion'] = appVersion;
    return jsonEncode(data);
  }

  /// Injection d'échecs de retrait de clé pour les tests uniquement.
  @visibleForTesting
  Future<bool> Function(String key)? debugRemoveHook;

  /// Clés de stockage de l'application (noms seulement), pour l'inventaire
  /// de suppression.
  @visibleForTesting
  Set<String> get storedKeys => _prefs.getKeys();

  /// Supprime toutes les données locales de l'application (L2b) : un état
  /// neuf remplace d'abord le document principal, puis toutes les autres
  /// clés (copies de récupération, anciennes clés de migration) sont
  /// retirées. Passe dans la file des écritures : une sauvegarde demandée
  /// plus tôt s'exécute avant, une demandée plus tard écrit l'état neuf.
  Future<EraseResult> eraseAllData() {
    _saveT?.cancel();
    _saveT = null;
    return _serialize(() async {
      if (!_initialized) return const EraseResult(EraseStatus.failed);
      final fresh = _freshData();
      if (!await _writeRaw(_pack(jsonEncode(_backupJson(fresh))))) {
        persistenceError.value =
            'Suppression impossible : écriture refusée. Tes données sont intactes.';
        return const EraseResult(EraseStatus.failed);
      }
      _applyBackup(fresh);
      _rankDifficulty();
      _lastLevel = 1;
      _pendingReward = null;
      _purchases.clear();
      _dataRevision++;
      _acceptedSeq = _changeSeq;
      final remaining = <String>[];
      for (final key in _prefs.getKeys().toList()) {
        if (key == _kState) continue;
        var removed = false;
        try {
          final hook = debugRemoveHook;
          removed = hook != null ? await hook(key) : await _prefs.remove(key);
        } catch (_) {
          removed = false;
        }
        if (!removed || _prefs.containsKey(key)) remaining.add(key);
      }
      persistenceError.value = null;
      notifyListeners();
      return EraseResult(
        remaining.isEmpty ? EraseStatus.success : EraseStatus.partial,
        remaining: remaining,
      );
    });
  }

  /// État d'une installation neuve : références du programme, catalogue
  /// embarqué d'origine, aucun journal, aucun droit, réglages par défaut.
  _BackupData _freshData() {
    final defaults = program.pilotage;
    return _BackupData(
      values: {
        'B4': defaults.bodyweight,
        for (final l in defaults.mainLifts) l.ref: l.oneRm,
        for (final r in defaults.repMax) r.ref: r.max,
        for (final a in defaults.accessories) a.ref: a.refLoad,
      },
      logs: {},
      settings: AppSettings(),
      custom: [],
      userExercises: [],
      wods: [for (final w in _seedDefaults.values) Wod.fromJson(w.toJson())],
      unlocked: {},
      lastLevel: 1,
      creditGrants: {},
    );
  }

  /// Copies de récupération (plus récente d'abord), jamais écrasées par un
  /// seul import : les [_recoveryLimit] dernières sont gardées.
  @visibleForTesting
  List<Map<String, dynamic>> get recoveryCopies {
    final raw = _prefs.getString(_kRecovery);
    if (raw == null) return const [];
    try {
      return [
        for (final e in jsonDecode(raw) as List)
          Map<String, dynamic>.from(e as Map),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Document complet d'une copie de récupération, décompressé.
  @visibleForTesting
  String? recoveryState(int index) {
    final copies = recoveryCopies;
    if (index < 0 || index >= copies.length) return null;
    return _unpack(copies[index]['state'] as String?);
  }

  Future<bool> _keepRecoveryCopy(String reason) async {
    final raw = _prefs.getString(_kRecovery);
    List<Object?> copies;
    try {
      copies = raw == null ? [] : jsonDecode(raw) as List<Object?>;
    } catch (_) {
      // Une liste illisible n'est pas écrasée : l'import attend un arbitrage.
      return false;
    }
    final next = [
      {
        'at': DateTime.now().toIso8601String(),
        'reason': reason,
        'state': _pack(exportAll()),
      },
      ...copies.take(_recoveryLimit - 1),
    ];
    try {
      return await _prefs.setString(_kRecovery, jsonEncode(next));
    } catch (_) {
      return false;
    }
  }

  /// Nouvelle tentative après une erreur : `true` si l'état en mémoire est
  /// désormais accepté par l'API de stockage.
  Future<bool> retrySave() async {
    await flush();
    return !hasUnsavedChanges;
  }

  void _persist() {
    _dataRevision++;
    if (_initialized) unawaited(_writeSnapshot());
  }

  /// Ajoute une opération à la file unique des écritures. Elle démarre au
  /// plus tôt dans une microtâche : jamais pendant l'appel qui l'ajoute.
  Future<T> _serialize<T>(Future<T> Function() op) {
    final done = Completer<T>();
    _writeQueue.add(() async {
      try {
        done.complete(await op());
      } catch (error, stack) {
        done.completeError(error, stack);
      }
    });
    if (!_draining) {
      _draining = true;
      scheduleMicrotask(_drainWrites);
    }
    return done.future;
  }

  Future<void> _drainWrites() async {
    try {
      while (_writeQueue.isNotEmpty) {
        await _writeQueue.removeAt(0)();
      }
    } finally {
      _draining = false;
    }
  }

  /// Sauvegarde de l'état courant. Les demandes rapprochées se regroupent en
  /// une écriture, qui encode l'état au moment où elle s'exécute : un état
  /// ancien ne peut plus être écrit après un état plus récent.
  Future<void> _writeSnapshot() {
    if (!_initialized) return Future<void>.value();
    _changeSeq++;
    final queued = _queuedSnapshot;
    if (queued != null) return queued;
    final next = _serialize(() async {
      _queuedSnapshot = null;
      await _commitState();
    });
    _queuedSnapshot = next;
    return next;
  }

  Future<bool> _commitState() async {
    final seq = _changeSeq;
    // Les gains nouveaux du journal sont acquis (KT-005, registre par gain).
    _recordGrants();
    final ok = await _writeRaw(_pack(exportAll()));
    if (ok) {
      if (seq > _acceptedSeq) _acceptedSeq = seq;
      persistenceError.value = null;
    } else {
      persistenceError.value =
          'Sauvegarde impossible. Tes modifications restent sur cet écran : réessaie avant de fermer l’application.';
    }
    return ok;
  }

  /// Écrit le document principal. En cas de refus, le cache de
  /// SharedPreferences (mis à jour avant la réponse native) retrouve le
  /// dernier document accepté.
  Future<bool> _writeRaw(String encoded) async {
    final previous = _prefs.getString(_kState);
    var ok = false;
    try {
      final hook = debugWriteHook;
      ok =
          hook != null
              ? await hook(encoded)
              : await _prefs.setString(_kState, encoded);
    } catch (_) {
      ok = false;
    }
    if (!ok) {
      try {
        if (previous == null) {
          await _prefs.remove(_kState);
        } else if (_prefs.getString(_kState) != previous) {
          await _prefs.setString(_kState, previous);
        }
      } catch (_) {}
    }
    return ok;
  }

  // ---------- Pilotage ----------
  void setValue(String ref, double v) {
    if (!values.containsKey(ref) ||
        !v.isFinite ||
        v < 0 ||
        v > 10000 ||
        (ref == 'B4' && v == 0)) {
      return;
    }
    if (values[ref] == v) return;
    values[ref] = v;
    _persist();
    notifyListeners();
  }

  void resetPilotage() {
    pilotageEpoch++;
    final p = program.pilotage;
    values['B4'] = p.bodyweight;
    for (final l in p.mainLifts) {
      values[l.ref] = l.oneRm;
    }
    for (final m in p.repMax) {
      values[m.ref] = m.max;
    }
    for (final a in p.accessories) {
      values[a.ref] = a.refLoad;
    }
    _persist();
    notifyListeners();
  }

  // ---------- Calculs (répliques des formules Excel) ----------
  double _round(double x, double step) => (x / step).round() * step;

  /// Charge suggérée en kg, ou null si non applicable.
  double? loadFor(Exercise e) {
    final s = e.load;
    switch (s.type) {
      case 'fixed':
        return s.kg;
      case 'system':
        final pdc = values['B4']!;
        final rm = values[s.ref!] ?? 0;
        final raw = (pdc + rm) * s.pct! - pdc;
        final r = _round(raw, 2.5);
        return r < 0 ? 0.0 : r;
      case 'barbell':
        return _round((values[s.ref ?? 'B11'] ?? 0) * s.pct!, 2.5);
      case 'acc':
        final ref = values[s.ref!] ?? 0;
        final rr = refReps[s.ref!] ?? 10;
        final raw = ref * (1 + (rr + 2) / 30) / (1 + (s.dayReps! + 2) / 30);
        return _round(raw, s.step!);
      default:
        return null;
    }
  }

  String loadLabel(Exercise e) {
    final kg = loadFor(e);
    if (kg == null) return '—';
    if (kg <= 0) return 'PdC';
    if (settings.lb) {
      final lb = kg * 2.20462;
      return '${lb.toStringAsFixed(lb == lb.roundToDouble() ? 0 : 1)}\u00A0lb';
    }
    final t =
        kg == kg.roundToDouble()
            ? kg.toInt().toString()
            : kg.toStringAsFixed(1).replaceAll('.', ',');
    return '$t\u00A0kg';
  }

  TrainingEstimate exerciseEstimate(Exercise e) {
    double? maximum;
    final name = e.name.toLowerCase();
    final ref =
        name.contains('muscle')
            ? 'B16'
            : name.contains('traction')
            ? 'B17'
            : name.contains('dip')
            ? 'B18'
            : name.contains('pompe')
            ? 'B19'
            : name.contains('squat')
            ? 'B20'
            : null;
    if (ref != null) maximum = values[ref];
    return TrainingEstimator.exercise(
      e,
      prescription: setsLabel(e),
      kg: loadFor(e),
      defaultRest: settings.defaultRest,
      repMax: maximum,
    );
  }

  TrainingEstimate dayEstimate(DayPlan day) {
    final out = TrainingEstimate();
    final blocks = groups(day);
    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      final estimates = block.map(exerciseEstimate).toList();
      for (var j = 0; j < block.length; j++) {
        out.details.add((
          title: splitName(block[j].name).$1,
          estimate: estimates[j],
        ));
      }
      final combined = TrainingEstimate();
      for (final e in estimates) {
        combined.add(e);
      }
      if (block.length > 1) {
        final first = estimates.first, second = estimates.last;
        if (logSpec(block.first).kind == 'emom' &&
            logSpec(block.last).kind == 'emom' &&
            first.clock?.high == second.clock?.high) {
          // Both movements share the same clock, as in the session runner.
          final seconds = first.elapsed.high;
          final work = (first.work.midpoint + second.work.midpoint).clamp(
            0.0,
            seconds,
          );
          combined.work = Span.exact(work);
          combined.transitions = Span.zero;
          combined.rest = Span.exact(seconds - work);
          out.notes.add('Les EMOM enchaînés partagent la même horloge.');
        } else {
          // One recovery between supersets, never one recovery per movement.
          combined.rest = Span(
            max(first.rest.low, second.rest.low),
            max(first.rest.high, second.rest.high),
          );
          combined.transitions =
              combined.transitions +
              const Span(3, 8).times(max(first.sets, second.sets));
          out.notes.add('Exercices enchaînés : un seul repos entre les tours.');
        }
      }
      out.add(combined);
      if (i > 0 && combined.elapsed.high > 0) {
        out.transitions = out.transitions + const Span(30, 60);
      }
    }
    if (out.elapsed.high > 0) {
      out.notes.add(
        'Transitions : 30–60 s entre exercices. Échauffement non prescrit et pauses libres non inclus.',
      );
    }
    return out;
  }

  TrainingEstimate wodEstimate(Wod w) {
    // Le calcul ne dépend que de la prescription et de ses résultats.
    final key = jsonEncode([
      w.prescriptionKey,
      w.results.map((r) => r.toJson()).toList(),
    ]);
    final cached = _wodEstimates[w.id];
    if (cached?.key == key) return cached!.value;
    final estimate = TrainingEstimator.wod(w);
    if (_wodEstimates.length >= 1024) {
      _wodEstimates.remove(_wodEstimates.keys.first);
    }
    _wodEstimates[w.id] = (key: key, value: estimate);
    return estimate;
  }

  Map<String, double> plannedMuscles(TrainingEstimate estimate) {
    final out = <String, double>{};
    final names = [
      ...estimate.movements.map((m) => m.name),
      ...estimate.details.map((e) => e.title),
    ];
    for (final name in names) {
      for (final group in groupsFor(name)) {
        out[group] = 1;
      }
    }
    return out;
  }

  /// Rendu de la colonne « Séries × Reps » (les volumes suivent tes maxima).
  String setsLabel(Exercise e) {
    final s = e.sets;
    if (s.type == 'volume') {
      final ref = values[s.ref!] ?? 0;
      final n = (s.coef! * ref / s.div!).round();
      return '${s.prefix}$n${s.suffix}';
    }
    return s.value ?? '';
  }

  /// Nombre de lignes de séries à afficher dans le logger.
  int setCount(Exercise e) {
    if (e.forcedSets != null) return e.forcedSets!.clamp(1, 1000);
    final txt = setsLabel(e);
    final low = txt.toLowerCase().trim();
    if (e.interval != null) return 1;
    if (low.startsWith('emom')) return 1;
    if (RegExp(r'^(\d+)(?:-(\d+))?\s*min$').hasMatch(low)) return 1;
    final myo = RegExp(r'puis\s*(\d+)\s*[×x]').firstMatch(txt);
    if (myo != null) return 1 + int.parse(myo.group(1)!);
    if (low.contains('montée')) return 6; // 3 paliers de montée + 3 tentatives
    final lead = RegExp(r'^(\d+)\s*(?:[×x]|rounds?|échelles?)').firstMatch(low);
    if (lead != null) return int.parse(lead.group(1)!);
    return 1;
  }

  // ---------- Affichage ----------
  /// Titre court + sous-titre : « POMPES PDC — SÉRIES LONGUES — ENCHAÎNÉ… »
  /// → (« Pompes PdC », « séries longues · enchaîné après les dips »).
  (String, String) splitName(String name) {
    final parts = name.split(RegExp(r'\s+—\s+'));
    final title = parts.first.trim();
    final rest = parts
        .skip(1)
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .join(' · ');
    return (title, rest);
  }

  /// Colonne kg : lestable (charge suggérée > 0 ou « lesté » dans le nom)
  /// ou déjà renseignée, sauf préférence explicite de l'exercice.
  bool showKgFor(Exercise e, ExerciseLog log) {
    if (log.showKg != null) return log.showKg!;
    if (log.sets.any((s) => s.kg.trim().isNotEmpty)) return true;
    final kg = loadFor(e);
    if (kg != null && kg > 0) return true;
    return e.name.toLowerCase().contains('lest');
  }

  bool showRirFor(ExerciseLog log) =>
      log.showRir ??
      (settings.trackRir || log.sets.any((s) => s.rir.trim().isNotEmpty));

  bool showVFor(Exercise e, ExerciseLog log) =>
      log.showV ??
      ((settings.trackVelocity && e.main) ||
          log.sets.any((s) => s.v.trim().isNotEmpty));

  /// Dernière performance loggée pour le même exercice (même jour, semaine
  /// précédente ayant un journal) — programme uniquement.
  ({int week, ExerciseLog log})? previousLog(int week, int j, Exercise e) {
    if (week <= 1 || week > program.weeks.length) return null;
    final title = splitName(e.name).$1.toLowerCase();
    for (var w = week - 1; w >= 1; w--) {
      final sl = logs[sessionKey(w, j)];
      if (sl == null) continue;
      final day = program.week(w).day(j);
      if (day == null) continue;
      for (final px in day.exercises) {
        if (splitName(px.name).$1.toLowerCase() != title) continue;
        final l = sl.ex[px.id];
        if (l != null && l.sets.any((s) => s.done)) return (week: w, log: l);
      }
    }
    return null;
  }

  /// Résumé compact d'un journal : « 10 kg × 3 · 3 · 3 » ou « 39 · 37 · 35 ».
  String summarize(ExerciseLog l, {bool kg = true}) {
    final done = l.sets.where((s) => s.done).toList();
    if (done.isEmpty) return '';
    final kgs = done.map((s) => s.kg.trim()).where((k) => k.isNotEmpty).toSet();
    final reps = done
        .map((s) => s.reps.trim().isEmpty ? '–' : s.reps.trim())
        .join(' · ');
    if (kg && kgs.length == 1) return '${kgs.first}\u00A0kg × $reps';
    if (kg && kgs.length > 1) {
      return done
          .map(
            (s) =>
                '${s.kg.trim().isEmpty ? 'PdC' : '${s.kg.trim()}\u00A0kg'}×${s.reps.trim()}',
          )
          .join(' · ');
    }
    return reps;
  }

  // ---------- Groupes musculaires ----------
  static final List<(RegExp, List<String>)> _kw = [
    (RegExp(r'muscle.?up|\bmu\b'), ['dos', 'pectoraux', 'triceps']),
    (
      RegExp(
        r'traction|pull.?up|chin.?up|row|tirage|face pull|dead.?hang|scapul|\blat\b',
      ),
      ['dos', 'biceps'],
    ),
    (RegExp(r'\bdip'), ['pectoraux', 'triceps']),
    (
      RegExp(r'pompe|push.?up|hspu|handstand|pike|développé|bench|press'),
      ['pectoraux', 'triceps', 'épaules'],
    ),
    (
      RegExp(
        r'squat|fente|lunge|pistol|box jump|step.?up|leg extension|presse',
      ),
      ['quadriceps', 'fessiers'],
    ),
    (
      RegExp(r'soulevé|deadlift|rdl|hip thrust|nordic|leg curl|good morning'),
      ['ischios', 'fessiers'],
    ),
    (RegExp(r'burpee'), ['pectoraux', 'quadriceps', 'gainage']),
    (
      RegExp(
        r'sit.?up|abdo|hollow|gainage|plank|planche \(|leg raise|toes|crunch|ab wheel|pallof|dragon|l-sit|v-sit|superman',
      ),
      ['gainage'],
    ),
    (
      RegExp(
        r'\brun\b|course|sprint|row(er|ing machine)|rameur|bike|ski|corde|jump|mountain',
      ),
      ['mollets', 'quadriceps'],
    ),
    (RegExp(r'curl'), ['biceps', 'avant-bras']),
    (RegExp(r'triceps|extension|kickback'), ['triceps']),
    (
      RegExp(
        r'élévation|rotation|oiseau|ytw|pull-apart|dislocation|shoulder|épaule|militaire',
      ),
      ['épaules'],
    ),
    (RegExp(r'poignet|wrist|farmer|false grip|hang'), ['avant-bras']),
    (RegExp(r'mollet|calf'), ['mollets']),
    (
      RegExp(r'front lever|planche|skin the cat|atr|wall walk'),
      ['dos', 'épaules', 'gainage'],
    ),
  ];

  static const muscleGroups = [
    'pectoraux',
    'épaules',
    'biceps',
    'triceps',
    'avant-bras',
    'gainage',
    'dos',
    'quadriceps',
    'ischios',
    'fessiers',
    'mollets',
  ];

  Map<String, List<String>>? _muscleIndex;

  /// Index paresseux : pas de parcours de toute la base pour chaque série.
  List<String> groupsFor(String name) {
    final t = splitName(name).$1.toLowerCase();
    _muscleIndex ??= {
      for (final e in allExercises)
        (e['n'] as String).toLowerCase():
            (e['g'] as String)
                .split(',')
                .map((g) => g.trim())
                .where(muscleGroups.contains)
                .toList(),
    };
    final exact = _muscleIndex![t];
    if (exact != null && exact.isNotEmpty) return exact;
    for (final (re, gs) in _kw) {
      if (re.hasMatch(t)) return gs;
    }
    return const [];
  }

  /// Les séries sont attribuées à leur date de validation. Les anciens logs
  /// utilisent la fin de séance, ou la date planifiée si la séance est en cours.
  Map<String, double> weeklyMuscles([DateTime? at]) {
    final now = at ?? DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - now.weekday + 1);
    final out = <String, double>{for (final g in muscleGroups) g: 0};
    bool inWeek(DateTime? date) =>
        date != null && !date.isBefore(monday) && !date.isAfter(now);
    void add(List<String> gs, double sets) {
      for (var i = 0; i < gs.length; i++) {
        out[gs[i]] = (out[gs[i]] ?? 0) + sets * (i == 0 ? 1.0 : 0.6);
      }
    }

    for (final entry in logs.entries) {
      final sl = entry.value;
      final key = RegExp(r'^S(\d+)-J(\d+)').firstMatch(entry.key);
      if (key == null) continue;
      final week = int.parse(key[1]!), day = int.parse(key[2]!);
      final names = Map<String, String>.of(sl.exerciseNames);
      DateTime? fallback = DateTime.tryParse(sl.finishedAt ?? '');
      if (week > 0 && week <= program.weeks.length) {
        final plan = program.week(week).day(day);
        if (plan != null) {
          for (final ex in plan.exercises) {
            names.putIfAbsent(ex.id, () => ex.name);
          }
          fallback ??= program.dateFor(week, day);
        }
      } else if (week == 0) {
        for (final cs in customSessions.where(
          (c) => c.id == (sl.customId ?? '$day'),
        )) {
          for (final ex in cs.items) {
            names.putIfAbsent('CU-${ex.uid}', () => ex.name);
          }
        }
      }
      for (final ex in sl.ex.entries) {
        final name = names[ex.key];
        if (name == null) continue;
        final n =
            ex.value.sets
                .where(
                  (set) =>
                      set.done &&
                      inWeek(
                        DateTime.tryParse(set.completedAt ?? '') ?? fallback,
                      ),
                )
                .length;
        if (n > 0) add(groupsFor(name), n.toDouble());
      }
    }
    for (final w in wods) {
      for (final r in w.results) {
        if (!inWeek(DateTime.tryParse(r.at)) ||
            (!r.completed && (r.rounds ?? 0) == 0)) {
          continue;
        }
        final rounds =
            w.type == 'rounds' && w.rounds > 0
                ? (r.rounds ?? w.rounds).clamp(1, w.rounds)
                : (r.rounds ?? 1).clamp(1, 3600);
        for (final line in w.lines) {
          for (final part
              in TrainingEstimator.parseLine(
                line,
                repScheme: w.scheme,
              ).movements) {
            add(groupsFor(part.name), 0.5 * rounds);
          }
        }
      }
    }
    return out;
  }

  // ---------- Nature de la saisie ----------
  LogSpec logSpec(Exercise e) {
    final low = setsLabel(e).toLowerCase().trim();
    final nm = e.name.toLowerCase();
    final tp = e.tempo.toLowerCase();
    final tm = e.timer;
    if (tm != null) {
      switch (tm['type'] as String) {
        case 'hiit':
          return const LogSpec('interval');
        case 'emom':
          return LogSpec(
            'emom',
            seconds: (tm['rounds'] as int) * (tm['interval'] as int),
          );
        case 'amrap':
          return LogSpec('amrap', seconds: tm['sec'] as int);
        case 'hold':
          if (low.contains('intra')) {
            return LogSpec(
              'reps',
              intra: tm['sec'] as int,
              cluster: true,
              rowPrefix: 'C',
            );
          }
          return LogSpec('hold', seconds: tm['sec'] as int);
      }
    }
    if (e.interval != null) return const LogSpec('interval');
    final emom = RegExp(r'^emom\s*(\d+)\s*min').firstMatch(low);
    if (emom != null) {
      return LogSpec('emom', seconds: int.parse(emom.group(1)!) * 60);
    }
    if (low.contains('cluster')) {
      final mi = RegExp(r'\((\d+)\s*s intra\)').firstMatch(low);
      return LogSpec(
        'reps',
        intra: mi == null ? 30 : int.parse(mi.group(1)!),
        cluster: true,
        rowPrefix: 'C',
      );
    }
    if (RegExp(r'^1\s*[×x].*puis\s*\d+\s*[×x]').hasMatch(low)) {
      final intra = RegExp(r'(\d+)\s*s intra').firstMatch(low);
      return LogSpec(
        'reps',
        intra: intra == null ? (e.restSec ?? 10) : int.parse(intra.group(1)!),
        myo: true,
        rowPrefix: 'M',
      );
    }
    final hold = RegExp(
      r'^\d+\s*[×x]\s*(\d+)(?:-(\d+))?\s*s\b',
    ).firstMatch(low);
    if (hold != null) {
      return LogSpec(
        'hold',
        seconds: int.parse(hold.group(2) ?? hold.group(1)!),
      );
    }
    if (low.contains('max')) {
      final iso =
          tp.contains('isom') ||
          nm.contains('hang') ||
          nm.contains('hold') ||
          nm.contains('tenue');
      return LogSpec(iso ? 'holdMax' : 'repsMax');
    }
    final dur = RegExp(r'^(\d+)(?:-(\d+))?\s*min$').firstMatch(low);
    if (dur != null) {
      return LogSpec(
        'duration',
        seconds: int.parse(dur.group(2) ?? dur.group(1)!) * 60,
      );
    }
    if (low.contains('échelle')) return const LogSpec('reps', rowPrefix: 'É');
    if (low.contains('round')) return const LogSpec('reps', rowPrefix: 'R');
    if (low.contains('montée')) return const LogSpec('reps', rowPrefix: 'T');
    return const LogSpec('reps');
  }

  /// Reps prévues par ligne de série, déduites du libellé (null = pas de cible).
  /// « 5×4 » → 4 · « 3×12-15 » → 12 · « 4 × 17 reps » → 17 · myo : activation puis
  /// minis · clusters : reps par cluster · pyramide « 12-10-8-6 » · échelles « de 7 à 1 »
  /// → 28 · montée en singles → 1 · EMOM 12 min × 5 reps → 60.
  List<int?> plannedReps(Exercise e, LogSpec sp, int n) {
    final low = setsLabel(e).toLowerCase().trim();
    final out = List<int?>.filled(n, null);
    int? num(RegExp r, {int g = 1}) {
      final m = r.firstMatch(low);
      return m == null ? null : int.tryParse(m.group(g)!);
    }

    if (sp.kind == 'emom') {
      final c = RegExp(
        r'emom\s*(\d+)\s*[×x]\s*\d+\s*s.*?(\d+)\s*reps',
      ).firstMatch(low);
      final m = RegExp(r'(\d+)\s*min.*?(\d+)\s*reps').firstMatch(low);
      final mm = c ?? m;
      if (mm != null && n > 0) {
        out[0] = int.parse(mm.group(1)!) * int.parse(mm.group(2)!);
      }
      return out;
    }
    if (sp.kind != 'reps') return out;
    if (sp.myo) {
      final act = num(RegExp(r'^1\s*[×x]\s*(\d+)'));
      final mini = num(RegExp(r'puis\s*\d+\s*[×x]\s*\(?(\d+)'));
      for (var i = 0; i < n; i++) {
        out[i] = i == 0 ? act : mini;
      }
      return out;
    }
    if (sp.cluster) {
      final cm = RegExp(r'\((\d+)\s*[×x]\s*(\d+)\)').firstMatch(low);
      if (cm != null) {
        return List.filled(
          n,
          int.parse(cm.group(1)!) * int.parse(cm.group(2)!),
        );
      }
      return List.filled(n, num(RegExp(r'^\d+\s*[×x]\s*(\d+)')));
    }
    if (RegExp(r'^\d+(?:\s*-\s*\d+){2,}$').hasMatch(low)) {
      final parts = low.split(RegExp(r'\s*-\s*')).map(int.tryParse).toList();
      for (var i = 0; i < n; i++) {
        out[i] = i < parts.length ? parts[i] : parts.last;
      }
      return out;
    }
    final lad = num(RegExp(r'de\s*(\d+)\s*à\s*1'));
    if (lad != null) return List.filled(n, lad * (lad + 1) ~/ 2);
    if (low.contains('montée')) return List.filled(n, 1);
    final std = num(RegExp(r'^\d+\s*[×x]\s*(\d+)'));
    if (std != null) return List.filled(n, std);
    return out;
  }

  /// Libellé de la ligne de série (Act / M1… · C1… · É1… · R1… · Mont./Tent.).
  String setLabel(LogSpec sp, int i) {
    if (sp.myo) return i == 0 ? 'Act' : 'M$i';
    switch (sp.rowPrefix) {
      case 'C':
        return 'C${i + 1}';
      case 'É':
        return 'É${i + 1}';
      case 'R':
        return 'R${i + 1}';
      case 'T':
        return i < 3 ? 'Mo${i + 1}' : 'T${i - 2}';
    }
    return '${i + 1}';
  }

  /// Repos à lancer après la série `i` (0-based) sur `total` ; null = aucun
  /// chrono automatique. La dernière série lance aussi son repos : c'est la
  /// transition vers l'exercice suivant. Les myo-reps enchaînent le
  /// micro-repos, puis le repos complet à la fin.
  int? restAfterSet(Exercise e, LogSpec sp, int i, int total) {
    final r = e.rest.toLowerCase();
    if (r.trim() == '—') return null;
    if (r.contains('après') || r.contains('au total')) return null;
    final def = settings.defaultRest > 0 ? settings.defaultRest : null;
    final last = i >= total - 1;
    if (sp.myo) {
      if (!last) return sp.intra;
      // « 10 s intra » décrit le micro-repos : le repos final est le défaut.
      if (r.contains('intra')) return def;
    }
    return TrainingEstimator.duration(e.rest)?.high.round() ?? e.restSec ?? def;
  }

  /// Regroupe les exercices enchaînés (ex. dips → pompes) sur une même page.
  List<List<Exercise>> groups(DayPlan d) {
    final out = <List<Exercise>>[];
    var i = 0;
    while (i < d.exercises.length) {
      final e = d.exercises[i];
      if (i + 1 < d.exercises.length &&
          d.exercises[i + 1].name.toLowerCase().contains('enchaîn')) {
        out.add([e, d.exercises[i + 1]]);
        i += 2;
      } else {
        out.add([e]);
        i += 1;
      }
    }
    return out;
  }

  // ---------- Journal ----------
  String sessionKey(int week, int j) => 'S$week-J$j';

  SessionLog sessionLog(int week, int j) =>
      logs.putIfAbsent(sessionKey(week, j), () => SessionLog());

  ExerciseLog exLog(int week, int j, Exercise e) {
    final s = sessionLog(week, j);
    s.exerciseNames[e.id] = e.name;
    if (week == 0) s.customId = '$j';
    return s.ex.putIfAbsent(e.id, () {
      final n = setCount(e);
      return ExerciseLog(sets: List.generate(n, (_) => SetEntry()));
    });
  }

  Timer? _saveT;

  /// Persistance différée (600 ms) : l'encodage JSON du journal complet ne
  /// tourne plus sur le thread d'interface à chaque coche ou frappe.
  void saveLogs({bool immediate = false, bool affectsProgression = true}) {
    _dataRevision++;
    _saveT?.cancel();
    if (immediate) {
      _flushLogs();
    } else {
      _saveT = Timer(const Duration(milliseconds: 600), _flushLogs);
    }
    if (affectsProgression) {
      notifyListeners();
    } else {
      // Modifier une note ou une charge ne recalcule pas tous les badges.
      super.notifyListeners();
    }
  }

  void _flushLogs() {
    _saveT?.cancel();
    _saveT = null;
    // La révision a déjà été comptée par [saveLogs] au moment du changement.
    if (_initialized) unawaited(_writeSnapshot());
  }

  /// À appeler quand l'app passe en arrière-plan.
  Future<void> flush() {
    _saveT?.cancel();
    _saveT = null;
    return _writeSnapshot();
  }

  /// Efface tout l'historique d'une séance : séries, notes, statut « fait ».
  void clearSession(int week, int j) {
    logs.remove(sessionKey(week, j));
    saveLogs(immediate: true);
  }

  void markSessionDone(int week, int j, bool done, {String? title}) {
    final s = sessionLog(week, j);
    final wasDone = s.done;
    final before = progression;
    final creditsBefore = credits;
    final goal = game.sessionGoal;
    s.done = done;
    // Une séance rouverte pour correction garde sa date de fin d'origine :
    // semaine, série et historique ne se déplacent pas au jour de la retouche.
    final finishedAt = s.finishedAt ?? DateTime.now().toIso8601String();
    s.finishedAt = done ? finishedAt : null;
    if (title != null) s.title = title;
    saveLogs(immediate: true);
    if (!done || wasDone) return;
    final training =
        week == 0
            ? s.ex.isNotEmpty
            : (program.weeks.any((w) => w.n == week) &&
                (program.week(week).day(j)?.exercises.isNotEmpty ?? false));
    if (!training) return;
    var total = 0, ok = 0;
    for (final ex in s.ex.values) {
      total += ex.sets.length;
      ok += ex.sets.where((x) => x.done).length;
    }
    final after = progression;
    if (after.totalXp <= before.totalXp) return;
    _pendingReward = RewardSummary.build(
      before: before,
      after: after,
      heading: 'Séance validée',
      title: title ?? s.title ?? sessionKey(week, j),
      creditsBefore: creditsBefore,
      creditsAfter: credits,
      baseXp: week == 0 ? 60 : 100,
      baseLabel: week == 0 ? 'Séance personnelle' : 'Journée du programme',
      records: sessionRecords(sessionKey(week, j)),
      goalReached: total == 0 ? null : ok / total >= goal - 1e-9,
    );
  }

  bool isDone(int week, int j) => logs[sessionKey(week, j)]?.done ?? false;

  // ---------- Correction depuis l'historique ----------

  /// Séance à rouvrir pour corriger une entrée terminée du journal : journée
  /// d'entraînement du programme, ou séance perso qui existe encore. Null pour
  /// une archive (clé « …@uid »), un jour de repos ou une séance supprimée :
  /// seule la suppression reste alors proposée.
  ({WeekPlan week, DayPlan day})? correctionPlan(String key) {
    if (logs[key]?.done != true) return null;
    final match = RegExp(r'^S(\d+)-J(\d+)$').firstMatch(key);
    if (match == null) return null;
    final n = int.parse(match[1]!), j = int.parse(match[2]!);
    if (n == 0) {
      for (final session in customSessions) {
        if (int.tryParse(session.id) != j || session.items.isEmpty) continue;
        final plan = session.toWeekPlan();
        return (week: plan, day: plan.days.first);
      }
      return null;
    }
    for (final week in program.weeks) {
      if (week.n != n) continue;
      final day = week.day(j);
      if (day == null || day.exercises.isEmpty) return null;
      return (week: week, day: day);
    }
    return null;
  }

  /// Repasse une séance terminée en cours, saisies et date de fin conservées.
  /// Son XP de séance est retiré jusqu'à la nouvelle validation.
  bool reopenSession(String key) {
    final log = logs[key];
    if (log == null || !log.done) return false;
    log.done = false;
    saveLogs(immediate: true);
    return true;
  }

  /// Retire une entrée du journal et la renvoie pour permettre l'annulation.
  SessionLog? deleteLog(String key) {
    final removed = logs.remove(key);
    if (removed != null) saveLogs(immediate: true);
    return removed;
  }

  /// Annulation d'une suppression : n'écrase jamais une séance recommencée
  /// entre-temps sous la même clé.
  bool restoreLog(String key, SessionLog log) {
    if (logs.containsKey(key)) return false;
    logs[key] = log;
    saveLogs(immediate: true);
    return true;
  }

  int get completedCount => program.weeks.fold(
    0,
    (n, w) => n + w.days.where((d) => isDone(w.n, d.j)).length,
  );

  void restartCustomSession(CustomSession session) {
    final key = 'S0-J${session.id}';
    final previous = logs[key];
    if (previous != null && previous.done) {
      previous.customId = session.id;
      for (final ex in session.items) {
        previous.exerciseNames.putIfAbsent('CU-${ex.uid}', () => ex.name);
      }
      logs['$key@${_newUid()}'] = previous;
    }
    logs.remove(key);
    saveLogs(immediate: true);
  }

  @override
  void dispose() {
    _saveT?.cancel();
    themeMode.dispose();
    persistenceError.dispose();
    super.dispose();
  }
}

/// Aperçu d'une sauvegarde validée (L2b) : uniquement des informations
/// réellement présentes dans le fichier, jamais déduites de son nom.
class ImportPreview {
  final _BackupData _data;
  final String _encoded;

  /// Révision des données locales au moment de l'aperçu.
  final int localRevision;

  final int format;

  /// Date d'export enregistrée dans le fichier (null : non enregistrée).
  final DateTime? exportedAt;
  final String? appVersion;
  final int programSessions, customSessionsDone, archivedSessions;
  final int customTemplates, userExercises, wodResults, customWods;
  final int wodsUnlocked, creditsPaid, legacyGrants, wishlist;
  final int level, xp;
  final int? creditsEarnedMax;

  /// Crédits gagnés enregistrés dans le registre (null : sauvegarde
  /// antérieure à L3, registre reconstruit à l'import).
  final int? creditsGranted;

  ImportPreview._({
    required _BackupData data,
    required String encoded,
    required Map<String, dynamic> meta,
    required Progression progression,
    required this.customWods,
    required this.localRevision,
  }) : _data = data,
       _encoded = encoded,
       format = (meta['format'] ?? 1) as int,
       exportedAt =
           meta['exportedAt'] is String
               ? DateTime.tryParse(meta['exportedAt'] as String)
               : null,
       appVersion =
           meta['appVersion'] is String ? meta['appVersion'] as String : null,
       programSessions =
           data.logs.entries
               .where((e) => e.value.done && !e.key.startsWith('S0-'))
               .length,
       customSessionsDone =
           data.logs.entries
               .where((e) => e.value.done && e.key.startsWith('S0-'))
               .length,
       archivedSessions = data.logs.keys.where((k) => k.contains('@')).length,
       customTemplates = data.custom.length,
       userExercises = data.userExercises.length,
       wodResults = data.wods.fold(0, (n, w) => n + w.results.length),
       wodsUnlocked = data.unlocked.length,
       creditsPaid = data.unlocked.values.fold(0, (a, b) => a + b),
       legacyGrants = data.legacyGrants.length,
       wishlist = data.wishlist.length,
       creditsEarnedMax = data.earnedMax,
       creditsGranted = data.creditGrants?.values.fold<int>(0, (a, b) => a + b),
       level = progression.level,
       xp = progression.totalXp;

  /// Séances terminées au total.
  int get sessionsDone => programSessions + customSessionsDone;
}

class _BackupData {
  final Map<String, double> values;
  final Map<String, SessionLog> logs;
  final AppSettings settings;
  final List<CustomSession> custom;
  final List<Map<String, dynamic>> userExercises;
  final List<Wod> wods;
  final Map<String, int> unlocked;
  final Map<String, String> legacyGrants;
  final int? lastLevel;
  final int? earnedMax;
  final Map<String, int>? creditGrants;
  final String? trialDay, trialId, weekOf;
  final List<String> weeklyIds;
  final List<String> wishlist;
  _BackupData({
    required this.values,
    required this.logs,
    required this.settings,
    required this.custom,
    required this.userExercises,
    required this.wods,
    required this.unlocked,
    this.legacyGrants = const {},
    this.lastLevel,
    this.earnedMax,
    this.creditGrants,
    this.trialDay,
    this.trialId,
    this.weekOf,
    this.weeklyIds = const [],
    this.wishlist = const [],
  });
}

/// Solde négatif affiché tel quel (KT-005) : jamais masqué par un zéro.
String creditDeficitLabel(int balance) =>
    'déficit de ${-balance} crédit${-balance > 1 ? 's' : ''}';

/// Singleton global — simple et suffisant pour cette app.
final AppStore store = AppStore();
