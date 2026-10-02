// Store global : Pilotage éditable + journal de séances, persistés localement.
// Les calculs de charge reproduisent exactement les formules du classeur v3.3.
import 'dart:async';
import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:math' show max;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:kalis_core/kalis_core.dart' show TrainingLog;
import 'package:kalis_adapt/kalis_adapt.dart' as ka;
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_plan/kalis_plan.dart' as kp;

import 'adapt/adapt_texts.dart';
import 'adapt/session_adapt.dart';

import 'athlete_profile.dart';
import 'content_pack.dart';
import 'kalis_clock.dart';
import 'session_prefs.dart';
import 'game.dart';
import 'journal_adapter.dart';
import 'koach_data.dart';
import 'legacy_adapt_data.dart';
import 'legacy_week_kinds.dart';
import 'mannequin_clip.dart' show ClipRegistry;
import 'models.dart';
import 'persistence.dart';
import 'plan/plan_creation.dart';
import 'plan/plan_evolution.dart';
import 'plan/plan_program.dart';
import 'plan/plan_texts.dart' as pt;
import 'profile.dart';
import 'program_instance.dart';
import 'training_estimate.dart';
import 'progression.dart';
import 'retired_data.dart';
import 'search.dart' show normalizeText;
import 'set_validation.dart';
import 'wellbeing.dart';

export 'adapt/session_adapt.dart';
export 'plan/plan_evolution.dart';
export 'koach_data.dart';
export 'legacy_adapt_data.dart';
export 'legacy_week_kinds.dart';
export 'persistence.dart';
export 'profile.dart';
export 'set_validation.dart' show SetCheck, SetField;
export 'wellbeing.dart';

part 'athlete_profile_store.dart';
part 'evolution_store.dart';
part 'plan_store.dart';
part 'profile_store.dart';
part 'program_store.dart';
part 'safety_store.dart';
part 'session_adapt_store.dart';

/// Charge à la grille du matériel : deux décimales au plus (« 2,5 » ;
/// « 35 » ; « 36,25 »). Charges du moteur dynamique (et, avant G10, de
/// Koach L7).
String koachKg(double kg) {
  if (kg == kg.roundToDouble()) return kg.toInt().toString();
  var t = kg.toStringAsFixed(2);
  while (t.endsWith('0')) {
    t = t.substring(0, t.length - 1);
  }
  return t.replaceAll('.', ',');
}

class SetEntry {
  String kg;
  String reps;
  String rir;
  String v; // vitesse (VBT), lifts principaux
  bool done;
  String? completedAt;

  /// Koach (L7, D9) : difficulté en RIR (0-5, pas de 0,5 ; 5 = « 5 ou
  /// plus »). Absente = comportement 2.x.
  double? effort;

  /// Koach (L7, D11) : série écartée (incident), gardée au journal.
  bool excluded;

  /// G9 (D5.3, D5.4) : note de la série en flammes (1 à 10), donnée à la
  /// validation. Absente avec [flamesUnknown] : « Je ne sais pas » (le
  /// moteur la traite comme une série sans note).
  int? flames;
  bool flamesUnknown;
  SetEntry({
    this.kg = '',
    this.reps = '',
    this.rir = '',
    this.v = '',
    this.done = false,
    this.completedAt,
    this.effort,
    this.excluded = false,
    this.flames,
    this.flamesUnknown = false,
  });

  Map<String, dynamic> toJson() => {
    'kg': kg,
    'reps': reps,
    'rir': rir,
    'v': v,
    'done': done,
    'completedAt': completedAt,
    if (effort != null) 'effort': effort,
    if (excluded) 'excluded': true,
    if (flames != null) 'flames': flames,
    if (flamesUnknown) 'flamesUnknown': true,
  };
  SetEntry.fromJson(Map<String, dynamic> j)
    : kg = j['kg'] as String? ?? '',
      reps = j['reps'] as String? ?? '',
      rir = j['rir'] as String? ?? '',
      v = j['v'] as String? ?? '',
      done = j['done'] as bool? ?? false,
      completedAt = j['completedAt'] as String?,
      effort = (j['effort'] as num?)?.toDouble(),
      excluded = j['excluded'] as bool? ?? false,
      flames = j['flames'] is int ? j['flames'] as int : null,
      flamesUnknown = j['flamesUnknown'] == true;
}

class ExerciseLog {
  List<SetEntry> sets;
  String note;
  bool? showKg; // null = règle automatique
  bool? showRir;
  bool? showV;

  /// Koach (L7, KT-029) : prescription affichée à la première validation
  /// (« 35 kg · 5×4 ») et dernière suggestion appliquée ou refusée.
  String? prescribed;
  String? koach;
  ExerciseLog({
    List<SetEntry>? sets,
    this.note = '',
    this.showKg,
    this.showRir,
    this.showV,
    this.prescribed,
    this.koach,
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
    if (prescribed != null) 'prescribed': prescribed,
    if (koach != null) 'koach': koach,
  };
  ExerciseLog.fromJson(Map<String, dynamic> j)
    : sets = ((j['sets'] as List?) ?? [])
          .map((s) => SetEntry.fromJson(s as Map<String, dynamic>))
          .toList(),
      note = j['note'] as String? ?? '',
      showKg = j['showKg'] as bool?,
      showRir = j['showRir'] as bool?,
      showV = j['showV'] as bool?,
      prescribed = j['prescribed'] as String?,
      koach = j['koach'] as String?;
}

class SessionLog {
  bool done;
  String? finishedAt; // ISO
  String? title; // libellé lisible (ex. « S8 · J1 »)
  Map<String, ExerciseLog> ex;
  Map<String, String> exerciseNames;

  /// G9 : séance servie par `kalis_adapt` (bilan santé, séance prescrite,
  /// conseils pendant la séance), JSON au schéma de [SessionAdapt]
  /// (lib/adapt/session_adapt.dart, version 1). Facultatif ; gardé tel quel
  /// s'il est illisible.
  Map<String, dynamic>? adapt;
  SessionLog({
    this.done = false,
    this.finishedAt,
    this.title,
    Map<String, ExerciseLog>? ex,
    Map<String, String>? exerciseNames,
    this.adapt,
  }) : ex = ex ?? {},
       exerciseNames = exerciseNames ?? {};

  Map<String, dynamic> toJson() => {
    'done': done,
    'finishedAt': finishedAt,
    'title': title,
    'exerciseNames': exerciseNames,
    'ex': ex.map((k, v) => MapEntry(k, v.toJson())),
    if (adapt != null) 'adapt': adapt,
  };
  SessionLog.fromJson(Map<String, dynamic> j)
    : done = j['done'] as bool? ?? false,
      finishedAt = j['finishedAt'] as String?,
      title = j['title'] as String?,
      exerciseNames = Map<String, String>.from(
        j['exerciseNames'] as Map? ?? {},
      ),
      ex = ((j['ex'] as Map<String, dynamic>?) ?? {}).map(
        (k, v) => MapEntry(k, ExerciseLog.fromJson(v as Map<String, dynamic>)),
      ),
      adapt = j['adapt'] is Map
          ? (j['adapt'] as Map).cast<String, dynamic>()
          : null;
}

// ===================== RÉGLAGES =====================

/// Couleurs dominantes enregistrables (L5-C), dans l'ordre du sélecteur.
/// Mêmes identifiants que `KAccentSpec.all` (vérifié par les tests).
const kAccentIds = ['rouge', 'jaune', 'vert', 'violet', 'orange', 'turquoise'];

/// Repli explicite vers le rouge : champ absent (état antérieur à L5-C),
/// valeur inconnue ou d'un autre type. Ne rend jamais une sauvegarde
/// invalide à lui seul.
String normalizeAccent(Object? value) =>
    value is String && kAccentIds.contains(value) ? value : 'rouge';

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
  bool notifSkipRest; // L12 : sans effet (jamais de rappel un jour de repos)
  bool celebrations; // écran de récompenses et cérémonie de niveau
  int weeklyGoal; // objectif de jours actifs par semaine ; 0 = adaptatif
  String title; // titre affiché sur la feuille de personnage ; '' = rang
  String accent; // couleur dominante (L5-C), voir kAccentIds

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
    this.accent = 'rouge',
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
    'accent': accent,
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
      // L12 (KT-070) : conservé pour la compatibilité du format ; les rappels
      // ne tombent plus jamais un jour de repos, quelle que soit sa valeur.
      notifSkipRest = j['notifSkipRest'] as bool? ?? true,
      celebrations = j['celebrations'] as bool? ?? true,
      weeklyGoal = j['weeklyGoal'] as int? ?? 0,
      title = j['title'] as String? ?? '',
      accent = normalizeAccent(j['accent']);
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
  /// Programme affiché : le programme embarqué (modèle Expert streetlifting,
  /// instance implicite) ou l'instance générée (L10, KT-050).
  late Program program;

  /// Programme embarqué (JSON et objet) et annotations Koach d'origine.
  Map<String, dynamic> _baseProgramJson = const {};
  late Program _baseProgram;
  Map<String, dynamic> _baseKoachJson = const {};
  bool _baseKoachAvailable = false;

  /// L10 : instance de programme (null = modèle Expert streetlifting
  /// implicite : programme embarqué inchangé). Contrat : docs/CONTRAT_L10.md.
  ProgramInstance? programInstance;

  /// Instances illisibles ignorées au dernier démarrage.
  int programLoadIssues = 0;

  /// G7 : programme créé par `kalis_plan` (section `planProgram`) ; il
  /// remplace l'instance L10 / le programme embarqué quand il existe.
  PlanProgram? planProgram;

  /// Section `planProgram` illisible au démarrage : gardée telle quelle et
  /// réécrite à l'identique (aucune perte).
  Map<String, dynamic>? _planRaw;
  int planLoadIssues = 0;

  /// G7 (D4.9) : « Où j'en suis » (section `programResume`).
  ProgramResume? programResume;

  /// G10 : propositions du moteur dynamique et suites données (section
  /// `planEvolution`) ; illisible au démarrage : gardée telle quelle
  /// ([_evoRaw]) et réécrite à l'identique.
  PlanEvolution planEvolution = PlanEvolution.empty;
  Map<String, dynamic>? _evoRaw;
  int evolutionLoadIssues = 0;

  /// Révision de l'évolution (clés des calculs gardés).
  int _evoRevision = 0;
  String _evoRefreshKey = '';

  /// Dernière revue du moteur dynamique (jamais sauvegardée).
  EvolutionReview? lastEvolutionReview;

  /// G9 : calculs du moteur dynamique gardés (bloc importé, journal
  /// présenté au moteur), clés de signature ; jamais sauvegardés.
  final Map<String, Object?> _g9Cache = {};

  /// Programme à afficher selon l'instance ; le départ est conservé.
  void _materializeProgram(DateTime? start) {
    final plan = planProgram;
    if (plan != null) {
      try {
        final weekday =
            start?.weekday ?? plan.blocks.first.block.pass1.startDate.weekday;
        final weeks = planWeeks(
          plan,
          startWeekday: weekday,
          labels: PlanStore(this).planLabels,
          view: EvolutionStore(this)._evoWeekEntry,
        );
        program = Program.fromJson({
          'meta': {
            ...(_baseProgramJson['meta'] as Map<String, dynamic>),
            'weeks': weeks.length,
            'generator': 'kalis_plan ${kp.kalisPlanVersion}',
          },
          'pilotage': _baseProgramJson['pilotage'],
          'weeks': weeks,
        });
        weekKinds = _baseKoachAvailable || plan.prefixKoach.isNotEmpty
            ? LegacyWeekKinds.fromJson(
                planKoachJson(plan, weeks, _baseKoachJson),
              )
            : const LegacyWeekKinds.empty();
        program.start = start;
        return;
      } catch (_) {
        planLoadIssues++;
        _planRaw = plan.toJson().cast<String, dynamic>();
        planProgram = null;
      }
    }
    final inst = programInstance;
    if (inst != null && inst.generated) {
      try {
        program = Program.fromJson(inst.programJson(_baseProgramJson));
        weekKinds = _baseKoachAvailable
            ? LegacyWeekKinds.fromJson(inst.koachJson(_baseKoachJson))
            : const LegacyWeekKinds.empty();
      } catch (_) {
        programLoadIssues++;
        programInstance = null;
        program = _baseProgram;
        weekKinds = _baseWeekKinds;
      }
    } else {
      program = _baseProgram;
      weekKinds = _baseWeekKinds;
    }
    program.start = start;
  }

  /// G1 : vue du stockage limitée à la session active (session_prefs.dart).
  late final KalisPrefs _prefs;

  /// Valeurs Pilotage éditables : PdC (B4), 1RM (B8-B11), max reps (B16-B20),
  /// charges de référence accessoires (B25-B45).
  final Map<String, double> values = {};

  /// Reps de référence des accessoires (colonne D, non éditable).
  final Map<String, int> refReps = {};

  /// Provenance de chaque référence renseignée (KT-007) :
  /// `set` = saisie ou confirmée par l'utilisateur, `historic` = valeur
  /// d'une installation ou sauvegarde antérieure à 2.5.8, provenance non
  /// documentée (conservée et utilisée telle quelle). Une référence absente
  /// de [values] est « non renseignée » : aucun calcul ne la remplace.
  final Map<String, String> refStatus = {};

  /// Origine du départ du programme : `user` (choisi) ou `migration`
  /// (ancrage historique 13/07/2026 d'une installation existante).
  String startOrigin = '';

  /// Références éditables : poids du corps, 1RM, maxima, accessoires.
  List<String> get referenceRefs => [
    'B4',
    for (final l in program.pilotage.mainLifts) l.ref,
    for (final r in program.pilotage.repMax) r.ref,
    for (final a in program.pilotage.accessories) a.ref,
  ];

  /// Référence connue (renseignée ou historique).
  bool refKnown(String ref) => values.containsKey(ref);

  /// `unknown`, `set` ou `historic`.
  String refProvenance(String ref) =>
      values.containsKey(ref) ? (refStatus[ref] ?? 'historic') : 'unknown';

  final Map<String, SessionLog> logs = {};

  /// Incrémenté à chaque reset pour forcer le rafraîchissement des champs.
  int pilotageEpoch = 0;

  AppSettings settings = AppSettings();

  /// Ne change qu'au changement de thème : évite de reconstruire MaterialApp
  /// à chaque notification du store.
  final ValueNotifier<String> themeMode = ValueNotifier<String>('system');

  /// Couleur dominante (L5-C) : même principe que [themeMode], indépendante.
  final ValueNotifier<String> accentMode = ValueNotifier<String>('rouge');
  final List<Map<String, dynamic>> dbExercises = []; // base embarquée
  final List<Map<String, dynamic>> userExercises =
      []; // ajoutés par l'utilisateur

  /// Koach L7 (retiré en G10, D1.4) : options, pesées, décisions et
  /// saisies de l'époque, gardées en lecture seule (section `koach` relue
  /// et réécrite à l'identique). Contrat d'origine : docs/CONTRAT_L7.md.
  KoachData koach = KoachData();

  /// Profil (L8, KT-038) : null tant qu'il n'a été ni créé au démarrage
  /// ni confirmé (installation existante). Contrat : docs/CONTRAT_L8.md.
  UserProfile? profile;

  /// Entrées du profil illisibles ignorées au dernier démarrage.
  int profileLoadIssues = 0;

  /// G6 : profil d'athlète v2 (section `athleteProfile`), null tant qu'il
  /// n'a pas été créé. Il remplace le profil L8 pour décrire l'utilisateur.
  AthleteRecord? athlete;

  /// Section `athleteProfile` illisible au démarrage : gardée telle quelle
  /// et réécrite à l'identique (aucune perte) jusqu'à un nouveau profil.
  Map<String, dynamic>? _athleteRaw;
  int athleteLoadIssues = 0;

  /// L11 (retiré en G10, D1.4) : adaptations au jour le jour de l'époque,
  /// gardées en lecture seule (section `adapt` relue et réécrite à
  /// l'identique). Contrat d'origine : docs/CONTRAT_L11.md.
  AdaptData adapt = AdaptData();

  /// Entrées d'adaptation illisibles ignorées au dernier démarrage.
  int adaptLoadIssues = 0;

  /// G2 (D1.1, D1.2) : données retirées (WOD, séances manuelles, crédits,
  /// L12) lues au démarrage et pas encore copiées. Tant qu'elles sont là,
  /// chaque écriture du document les garde telles quelles : rien n'est
  /// supprimé sans copie complète relue (voir [_secureRetiredData]).
  RetiredData _retiredPending = RetiredData.empty;

  /// La copie de sécurité G2 a échoué à ce lancement : les écrans retirés
  /// restent masqués, les données restent dans le document, nouvel essai au
  /// lancement suivant.
  bool retiredCopyFailed = false;

  /// Nature des semaines d'un programme existant (annotations du
  /// programme, section `weeks`) : décharges et tests du bloc importé
  /// (G9). Vide si l'asset est illisible.
  LegacyWeekKinds weekKinds = const LegacyWeekKinds.empty();
  LegacyWeekKinds _baseWeekKinds = const LegacyWeekKinds.empty();

  /// Entrées Koach illisibles ignorées au dernier démarrage (§3.4).
  int koachLoadIssues = 0;

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
  static const _kUserEx = 'user_exercises_v1';
  static const _kLastLevel = 'level_seen';

  /// G2 : copie complète des données d'avant la suppression des WOD et des
  /// séances manuelles (document au format d'export de 6.0.x, compressé) et
  /// sa fiche (date, empreinte, contenu supprimé, annonce vue). Clés de la
  /// session active : la session de test a les siennes. Hors sauvegarde.
  static const kRetiredCopyKey = 'g2_copie_avant_suppression_v1';
  static const kRetiredNoticeKey = 'g2_annonce_suppression_v1';

  /// Clés qu'écrivait une installation antérieure au document unique (ou
  /// une copie de secours) : preuve d'une installation existante. Les clés
  /// du catalogue et de version écrites au tout premier lancement n'en
  /// font pas partie (installation neuve interrompue avant sa première
  /// sauvegarde).
  static const _existingKeys = {
    _kRecovery,
    _kPilotage,
    _kLogs,
    _kSettings,
    // Clés des séances manuelles et des WOD d'avant le document unique :
    // jamais lues ni effacées depuis G2, elles prouvent encore une
    // installation existante.
    'custom_sessions_v1',
    _kUserEx,
    'wods_v1',
    'wods_user_v2',
    'wods_del_v2',
    'wods_edit_v2',
    'wod_results_v2',
    'unlocked_wods_v1',
    _kLastLevel,
  };

  /// Références embarquées (classeur du créateur) : seulement pour migrer
  /// une installation ou une sauvegarde antérieure à 2.5.8, qui les
  /// utilisait déjà. Jamais pour un nouvel utilisateur.
  void _defaultReferences(Map<String, double> out) {
    final p = program.pilotage;
    out['B4'] = p.bodyweight;
    for (final l in p.mainLifts) {
      out[l.ref] = l.oneRm;
    }
    for (final m in p.repMax) {
      out[m.ref] = m.max;
    }
    for (final a in p.accessories) {
      out[a.ref] = a.refLoad;
    }
  }

  Future<void> init() async {
    _baseProgramJson =
        jsonDecode(await _loadGz('assets/programme_v33.json.gz'))
            as Map<String, dynamic>;
    program = _baseProgram = Program.fromJson(_baseProgramJson);
    programInstance = null;
    try {
      _baseKoachJson =
          jsonDecode(await _loadGz('assets/koach_program.json.gz'))
              as Map<String, dynamic>;
      _baseKoachAvailable =
          (_baseKoachJson['exercises'] as Map?)?.isNotEmpty ?? false;
      weekKinds = _baseWeekKinds = LegacyWeekKinds.fromJson(_baseKoachJson);
    } catch (_) {
      // Annotations absentes ou illisibles : natures de semaine inconnues.
      _baseKoachJson = const {};
      _baseKoachAvailable = false;
      weekKinds = _baseWeekKinds = const LegacyWeekKinds.empty();
    }
    _prefs = await KalisPrefs.active();

    final p = program.pilotage;
    for (final a in p.accessories) {
      refReps[a.ref] = a.refReps;
    }

    // G3 (D4.10) : base d'exercices v1.1 (kalis_core) pour Arsenal, les
    // fiches et la résolution des noms enregistrés (correspondance relue).
    content = await ContentIndex.load();
    ClipRegistry.legacyIds = content.legacyIds;
    // Groupes musculaires des noms enregistrés : ceux de l'ancienne base
    // (pack 2.0.0, noms v1 compris), inchangés, pour que l'historique et
    // STATS restent identiques ; un nom de la base v1.1 qui n'y figure pas
    // prend les groupes de ses muscles principaux (`groupsFor`).
    final legacy =
        jsonDecode(await _loadGz(_legacyIndexAsset)) as Map<String, dynamic>;
    legacyPack = LegacyPackIndex.fromJson(legacy);
    for (final e in legacy['exercices'] as List) {
      final m = e as Map<String, dynamic>;
      dbExercises.add({'n': m['n'], 'g': m['g'], 'eq': m['eq'], 'id': m['id']});
    }
    final saved = _prefs.getString(_kState);
    if (saved != null) {
      Map<String, dynamic>? raw;
      _applyBackup(_parseBackup(_unpack(saved)!, rawMap: (m) => raw = m));
      _initialized = true;
      // G2 : données retirées encore présentes → copie complète relue, puis
      // seulement suppression (sinon elles restent, nouvel essai au
      // prochain lancement).
      final document = raw;
      if (document != null) await _secureRetiredData(document);
      return;
    }

    // Installation antérieure au document unique (clés d'origine) : elle
    // utilisait le calendrier d'ancrage et les références embarquées, qui
    // restent en place (KT-006/007). Sans aucune de ces clés, l'installation
    // est réellement neuve : programme non démarré, références inconnues.
    final existing = _prefs.getKeys().any(_existingKeys.contains);
    if (existing) {
      _defaultReferences(values);
      program.start = program.anchorMonday;
      startOrigin = 'migration';
    } else {
      program.start = null;
      startOrigin = '';
    }
    // Écrase avec les valeurs sauvegardées.
    final sp = _prefs.getString(_kPilotage);
    if (sp != null) {
      final m = jsonDecode(sp) as Map<String, dynamic>;
      m.forEach((k, v) => values[k] = (v as num).toDouble());
    }
    for (final ref in values.keys) {
      refStatus[ref] = 'historic';
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
    accentMode.value = settings.accent;
    // G2 : séances manuelles et WOD de ces anciennes clés ignorés ; les clés
    // restent en place, intactes (aucune donnée effacée).
    logs.removeWhere((k, _) => isManualSessionKey(k));
    _lastLevel = _prefs.getInt(_kLastLevel) ?? level;
    _initialized = true;
    // Migration vers une seule écriture atomique. Les anciennes clés restent
    // disponibles pour récupérer les données si la migration est interrompue.
    await flush();
  }

  // ---------- Horloge ----------
  /// Horloge du magasin (remplaçable dans les tests).
  DateTime Function() storeClock = KalisClock.now;

  /// Horloge réelle (non remplacée par un test) : les chronos peuvent alors
  /// s'appuyer aussi sur l'horloge monotone du processus.
  bool get realClock =>
      identical(storeClock, KalisClock.now) ||
      identical(storeClock, DateTime.now);

  // ---------- Progression (XP, niveaux, déverrouillage) ----------
  int _lastLevel = 1;

  Progression? _progression;
  DateTime? _progressionDay;
  Progression get progression {
    final now = KalisClock.now();
    final day = civilDay(now);
    if (_progression == null || _progressionDay != day) {
      _progression = Progression.calculate(
        logs: logs,
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
        isDone: isDone,
        now: KalisClock.now(),
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
  ({int inLevel, int need}) get levelProgress =>
      (inLevel: progression.inLevel, need: progression.need);

  /// Si le niveau a monté depuis la dernière vérification : (ancien,
  /// nouveau), sinon null. À appeler après une séance.
  ({int from, int to})? consumeLevelUp() {
    final now = level;
    if (now <= _lastLevel) return null;
    final from = _lastLevel;
    _lastLevel = now;
    _persist();
    return (from: from, to: now);
  }

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

  // ---------- Réglages ----------
  void saveSettings() {
    _persist();
    if (themeMode.value != settings.theme) themeMode.value = settings.theme;
    if (accentMode.value != settings.accent) {
      accentMode.value = settings.accent;
    }
    notifyListeners();
  }

  String get effortLabel => settings.rpe ? 'RPE' : 'RIR';

  // ---------- Base d'exercices ----------
  /// Base d'exercices v1.1 (G3) ; vide avant [init].
  ContentIndex content = ContentIndex.empty();

  /// Noms enregistrés → anciens identifiants (moteurs L10 et L11).
  LegacyPackIndex legacyPack = LegacyPackIndex.empty();

  /// Ancienne base (pack 2.0.0) : groupes musculaires des noms enregistrés
  /// (STATS) ; données internes de L10 et L11 jusqu'à leur retrait (G10).
  static const _legacyIndexAsset = 'assets/content/index.json.gz';

  /// Identifiant v1.1 d'un nom d'exercice enregistré ou d'un intitulé du
  /// programme ; null pour un exercice personnel ou sans équivalent.
  String? exerciseIdFor(String name) => content.idFor(name);

  /// G3 : journal au format de `kalis_core` (règles C1 à C12,
  /// lib/journal_adapter.dart), calculé depuis l'état exporté ; l'ancien
  /// journal reste la source et n'est jamais réécrit.
  ({TrainingLog log, JournalConversionReport report}) coreTrainingLog() =>
      convertLegacyJournal(
        jsonDecode(exportAll()) as Map<String, dynamic>,
        exerciseId: content.idFor,
        usesSeconds: (id) => content.byId[id]?.ex.unit.code == 'secondes',
        dayOrder: (w, j) => w >= 1 && w <= program.weeks.length
            ? [for (final e in program.week(w).day(j)?.exercises ?? []) e.id]
            : const [],
        legacyDate: program.legacyDateFor,
      );

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

  // ---------- Sauvegarde : un document, une écriture atomique ----------
  _BackupData _currentBackup() => _BackupData(
    values: values,
    refStatus: refStatus,
    start: program.start,
    startOrigin: startOrigin,
    logs: logs,
    settings: settings,
    userExercises: userExercises,
    lastLevel: _lastLevel,
    koach: koach,
    profile: profile,
    athlete: athlete,
    athleteRaw: _athleteRaw,
    programInstance: programInstance,
    planProgram: planProgram,
    planRaw: _planRaw,
    programResume: programResume,
    planEvolution: planEvolution,
    evolutionRaw: _evoRaw,
    adapt: adapt,
  );

  /// Format 3 sans les sections retirées par G2 (`custom`, `catalog`,
  /// `unlocked`, crédits, vitrine, envies, `motiv` : voir
  /// retired_data.dart). Les versions 6.0.x ne relisent pas ce document
  /// (catalogue de WOD absent) ; la copie d'avant G2 sert à revenir en
  /// arrière.
  Map<String, dynamic> _backupJson(_BackupData data) {
    return {
      'kalisTrack': 1,
      'format': 3,
      'pilotage': data.values,
      // KT-007 : provenance de chaque référence renseignée (absente = non
      // renseignée). KT-006 : départ personnel (S1·J1, date civile).
      'referenceStatus': data.refStatus,
      'programStart': data.start == null
          ? {'status': 'pending'}
          : {
              'status': 'set',
              'date': civilDateString(data.start!),
              'origin': data.startOrigin,
            },
      'logs': data.logs.map((k, v) => MapEntry(k, v.toJson())),
      'settings': data.settings.toJson(),
      'userExercises': data.userExercises,
      'lastLevel': data.lastLevel,
      // L7 : section écrite seulement si Koach a servi (export identique à
      // 2.5.9 sinon) ; ignorée par les versions antérieures.
      if (!data.koach.pristine) 'koach': data.koach.toJson(),
      // L8 : profil écrit seulement s'il existe (export identique à 3.0.x
      // sinon) ; ignoré par les versions antérieures.
      if (data.profile != null) 'profile': data.profile!.toJson(),
      // G6 : profil d'athlète v2, écrit seulement s'il existe ; ignoré par
      // les versions antérieures (section versionnée, facultative).
      if (data.athlete != null)
        'athleteProfile': data.athlete!.toJson()
      else if (data.athleteRaw != null)
        'athleteProfile': data.athleteRaw,
      // L10 : instance de programme écrite seulement si elle existe (export
      // identique à 3.2.0 sinon) ; ignorée par les versions antérieures.
      if (data.programInstance != null)
        'programInstance': data.programInstance!.toJson(),
      // G7 : programme créé par kalis_plan et « Où j'en suis », écrits
      // seulement s'ils existent ; ignorés par les versions antérieures
      // (sections versionnées, facultatives).
      if (data.planProgram != null)
        'planProgram': data.planProgram!.toJson()
      else if (data.planRaw != null)
        'planProgram': data.planRaw,
      if (data.programResume != null)
        'programResume': data.programResume!.toJson(),
      // G10 : propositions du moteur dynamique et suites données, écrites
      // seulement s'il y en a ; ignorées par les versions antérieures
      // (section versionnée, facultative).
      if (!data.planEvolution.isEmpty)
        'planEvolution': data.planEvolution.toJson()
      else if (data.evolutionRaw != null)
        'planEvolution': data.evolutionRaw,
      // L11 : adaptations écrites seulement si elles servent (export
      // identique à 4.0.0 sinon) ; ignorées par les versions antérieures.
      if (!data.adapt.pristine) 'adapt': data.adapt.toJson(),
    };
  }

  String exportAll() => jsonEncode(_backupJson(_currentBackup()));

  /// Document local : la sauvegarde exportée, plus (G2) les données
  /// retirées tant que leur copie n'est pas faite : elles restent écrites
  /// telles quelles, jamais perdues par une écriture ordinaire.
  String _stateDocument() {
    final m = _backupJson(_currentBackup());
    _retiredPending.restoreInto(m);
    return jsonEncode(m);
  }

  // ---------- G2 : copie avant suppression (D1.1) ----------

  /// Copie complète au format d'export de 6.0.x : le document lu au
  /// démarrage, tel quel (chrono WOD local retiré, date de la copie
  /// ajoutée ; champs de session de test comme un export). 6.0.x l'importe.
  static String retiredCopyText(
    Map<String, dynamic> document, {
    required DateTime at,
    bool devSession = false,
    int offsetDays = 0,
  }) {
    final copy = Map<String, dynamic>.of(document)..remove('activeWod');
    copy['exportedAt'] = at.toIso8601String();
    if (devSession) {
      copy['sessionDeTest'] = true;
      copy['decalageJours'] = offsetDays;
    }
    return jsonEncode(copy);
  }

  /// Données retirées présentes dans [document] (document lu au démarrage) :
  /// - sans donnée de l'utilisateur (catalogue vierge, vitrine…) : retirées
  ///   à la prochaine écriture, sans copie ni annonce ;
  /// - sinon : copie écrite dans le stockage de l'application, relue et
  ///   vérifiée (texte identique, empreinte, contenu identique au document,
  ///   lecture comme un import), fiche écrite, puis seulement le document
  ///   est réécrit sans elles. Au moindre échec : rien n'est supprimé, les
  ///   écrans restent masqués, nouvel essai au lancement suivant.
  Future<void> _secureRetiredData(Map<String, dynamic> document) async {
    final retired = RetiredData.of(document);
    if (retired.isEmpty) return;
    if (!retired.summary.hasUserData) {
      await flush();
      return;
    }
    _retiredPending = retired;
    retiredCopyFailed = true;
    final at = KalisClock.now();
    try {
      final text = retiredCopyText(
        document,
        at: at,
        devSession: SessionSpace.isDev,
        offsetDays: KalisClock.offsetDays,
      );
      final packed = _pack(text);
      final hook = debugRetiredCopyHook;
      final written = hook != null
          ? await hook(packed)
          : await _prefs.setString(kRetiredCopyKey, packed);
      if (!written) return;
      final back = _unpack(_prefs.getString(kRetiredCopyKey));
      if (back == null || back != text || fnv1a32(back) != fnv1a32(text)) {
        return;
      }
      final reread = jsonDecode(back) as Map<String, dynamic>;
      final expected = Map<String, dynamic>.of(document)..remove('activeWod');
      for (final k in ['exportedAt', 'sessionDeTest', 'decalageJours']) {
        reread.remove(k);
        expected.remove(k);
      }
      if (!jsonDeepEquals(reread, expected) ||
          RetiredData.of(reread).summary.toJson().toString() !=
              retired.summary.toJson().toString()) {
        return;
      }
      // Import à blanc : la copie se relit comme une sauvegarde.
      _parseBackup(back);
      final notice = RetiredNotice(
        at: at,
        bytes: utf8.encode(text).length,
        checksum: fnv1a32(text),
        summary: retired.summary,
      );
      if (!await _prefs.setString(
        kRetiredNoticeKey,
        jsonEncode(notice.toJson()),
      )) {
        return;
      }
    } catch (_) {
      return;
    }
    // Copie confirmée : le document est réécrit sans les données retirées.
    _retiredPending = RetiredData.empty;
    retiredCopyFailed = false;
    await flush();
  }

  /// Injection d'un échec d'écriture de la copie G2 (tests uniquement).
  @visibleForTesting
  static Future<bool> Function(String packed)? debugRetiredCopyHook;

  /// Fiche de la copie G2 (null : aucune copie dans cette session).
  RetiredNotice? get retiredNotice {
    try {
      final raw = _prefs.getString(kRetiredNoticeKey);
      return raw == null ? null : RetiredNotice.fromJson(jsonDecode(raw));
    } catch (_) {
      // Fiche illisible, ou magasin pas encore chargé.
      return null;
    }
  }

  /// Texte de la copie G2 (null : absente ou illisible).
  String? get retiredCopy {
    try {
      final text = _unpack(_prefs.getString(kRetiredCopyKey));
      final notice = retiredNotice;
      if (text == null || notice == null) return null;
      return fnv1a32(text) == notice.checksum ? text : null;
    } catch (_) {
      return null;
    }
  }

  /// L'annonce de la suppression a été lue (bouton « Compris »).
  Future<void> markRetiredNoticeSeen() async {
    final notice = retiredNotice;
    if (notice == null || notice.seen) return;
    notice.seen = true;
    try {
      await _prefs.setString(kRetiredNoticeKey, jsonEncode(notice.toJson()));
    } catch (_) {}
    notifyListeners();
  }

  String exportCompact() => _pack(exportAll());

  /// [limits] : import d'un texte externe (KT-015). Sans limites : état
  /// produit par l'application elle-même, relu au démarrage.
  _BackupData _parseBackup(
    String raw, {
    ImportLimits? limits,
    void Function(Map<String, dynamic>)? rawMap,
  }) {
    final m =
        (limits == null ? jsonDecode(raw) : boundedJsonDecode(raw, limits))
            as Map<String, dynamic>;
    rawMap?.call(m);
    if (m['kalisTrack'] != 1 || ![1, 2, 3].contains(m['format'] ?? 1)) {
      throw const FormatException('Format de sauvegarde non pris en charge.');
    }
    if (limits != null) _checkCollections(m, limits);
    // Tout construire et valider AVANT de modifier le store ou le disque.
    // Sauvegarde 2.5.8+ : seules les références renseignées, avec leur
    // provenance. Sauvegarde antérieure : elle utilisait les références
    // embarquées, complétées par ses valeurs ; toutes deviennent
    // « historiques » (conservées, utilisées, jamais requalifiées).
    final withStatus = m.containsKey('referenceStatus');
    final known = referenceRefs.toSet();
    final nextValues = <String, double>{};
    if (!withStatus) _defaultReferences(nextValues);
    (m['pilotage'] as Map<String, dynamic>).forEach((k, v) {
      final n = (v as num).toDouble();
      if (!n.isFinite || n < 0 || n > 10000 || (k == 'B4' && n == 0)) {
        throw const FormatException('Valeur de pilotage invalide.');
      }
      nextValues[k] = n;
    });
    final nextStatus = <String, String>{};
    if (withStatus) {
      final raw = m['referenceStatus'] as Map<String, dynamic>;
      for (final e in raw.entries) {
        if (!nextValues.containsKey(e.key) ||
            (e.value != 'set' && e.value != 'historic')) {
          throw const FormatException('Provenance de référence invalide.');
        }
        nextStatus[e.key] = e.value as String;
      }
      // Valeur présente sans provenance (fichier retouché à la main) :
      // conservée et utilisée, mais « à vérifier », jamais « renseignée ».
      for (final k in nextValues.keys) {
        nextStatus.putIfAbsent(k, () => 'historic');
      }
      // Une clé hors du tableau actuel ne peut venir que d'une ancienne
      // sauvegarde : conservée telle quelle, jamais « renseignée ».
      for (final k in nextValues.keys) {
        if (!known.contains(k) && nextStatus[k] != 'historic') {
          throw const FormatException('Référence inconnue.');
        }
      }
    } else {
      for (final k in nextValues.keys) {
        nextStatus[k] = 'historic';
      }
    }
    // Départ du programme : absent = sauvegarde antérieure à 2.5.8, qui
    // suivait l'ancrage du 13/07/2026 ; jamais remplacé par aujourd'hui.
    DateTime? nextStart = program.anchorMonday;
    var nextOrigin = 'migration';
    final startJson = m['programStart'];
    if (startJson != null) {
      final sj = startJson as Map<String, dynamic>;
      if (sj['status'] == 'pending' && sj.length == 1) {
        nextStart = null;
        nextOrigin = '';
      } else if (sj['status'] == 'set') {
        nextStart = parseCivilDate(sj['date']);
        nextOrigin = sj['origin'] as String? ?? '';
        if (nextStart == null ||
            nextStart.year < 2000 ||
            nextStart.year > 2100 ||
            (nextOrigin != 'user' && nextOrigin != 'migration')) {
          throw const FormatException('Départ du programme invalide.');
        }
      } else {
        throw const FormatException('Départ du programme invalide.');
      }
    }
    final nextLogs = (m['logs'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, SessionLog.fromJson(v as Map<String, dynamic>)),
    );
    // G2 : séances manuelles (semaine 0) retirées, ignorées à la lecture.
    nextLogs.removeWhere((k, _) => isManualSessionKey(k));
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
    final nextUser = ((m['userExercises'] as List?) ?? [])
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
        // L7 : textes Koach du journal bornés ; au démarrage, un texte
        // hors bornes est ignoré (le reste du journal est gardé).
        if ((ex.prescribed?.length ?? 0) > 200 ||
            (ex.koach?.length ?? 0) > 300) {
          if (limits != null) {
            throw const FormatException('Journal Koach invalide.');
          }
          if ((ex.prescribed?.length ?? 0) > 200) ex.prescribed = null;
          if ((ex.koach?.length ?? 0) > 300) ex.koach = null;
        }
        for (final set in ex.sets) {
          if (set.completedAt != null &&
              DateTime.tryParse(set.completedAt!) == null) {
            throw const FormatException('Date de série invalide.');
          }
          final effort = set.effort;
          if (effort != null &&
              (!effort.isFinite ||
                  effort < 0 ||
                  effort > 5 ||
                  effort * 2 != (effort * 2).roundToDouble())) {
            if (limits != null) {
              throw const FormatException('Difficulté de série invalide.');
            }
            set.effort = null;
          }
          // G9 : note en flammes de 1 à 10.
          final flames = set.flames;
          if (flames != null && (flames < 1 || flames > 10)) {
            if (limits != null) {
              throw const FormatException('Note de série invalide.');
            }
            set.flames = null;
          }
        }
      }
      // G9 : séance servie par le moteur dynamique (contrôle strict à
      // l'import ; au démarrage, une section illisible est gardée telle
      // quelle et ignorée).
      if (log.adapt != null && limits != null) {
        SessionAdapt.fromJson(log.adapt!);
      }
    }
    // L7 : décisions Koach. Import (fichier externe) : toute valeur hors
    // contrat refuse l'import ; démarrage : entrée illisible ignorée.
    final koachIssues = <String>[];
    final nextKoach = KoachData.fromJson(
      m['koach'],
      knownRefs: known,
      movements: {for (final l in program.pilotage.mainLifts) l.key},
      strict: limits != null,
      issues: koachIssues,
    );
    // L8 : profil. Import strict ; démarrage tolérant (entrée ignorée).
    final profileIssues = <String>[];
    final nextProfile = UserProfile.fromJson(
      m['profile'],
      strict: limits != null,
      issues: profileIssues,
    );
    // G6 : profil d'athlète v2. Import strict ; démarrage tolérant (section
    // illisible gardée telle quelle, jamais perdue).
    AthleteRecord? nextAthlete;
    Map<String, dynamic>? athleteRaw;
    var athleteIssues = 0;
    final rawAthlete = m['athleteProfile'];
    if (rawAthlete != null) {
      try {
        nextAthlete = AthleteRecord.fromJson(rawAthlete);
      } catch (e) {
        if (limits != null) {
          throw const FormatException('Profil d’athlète illisible.');
        }
        athleteIssues = 1;
        if (rawAthlete is Map) {
          athleteRaw = Map<String, dynamic>.from(rawAthlete);
        }
      }
    }
    // L10 : instance de programme. Import strict ; démarrage tolérant.
    final programIssues = <String>[];
    final nextProgram = ProgramInstance.fromJson(
      m['programInstance'],
      strict: limits != null,
      issues: programIssues,
    );
    // G7 : programme kalis_plan. Import strict ; démarrage tolérant
    // (section illisible gardée telle quelle, jamais perdue).
    PlanProgram? nextPlan;
    Map<String, dynamic>? planRaw;
    var planIssues = 0;
    final rawPlan = m['planProgram'];
    if (rawPlan != null) {
      try {
        nextPlan = PlanProgram.fromJson(rawPlan);
      } catch (_) {
        if (limits != null) {
          throw const FormatException('Programme créé illisible.');
        }
        planIssues = 1;
        if (rawPlan is Map) planRaw = Map<String, dynamic>.from(rawPlan);
      }
    }
    ProgramResume? nextResume;
    final rawResume = m['programResume'];
    if (rawResume != null) {
      try {
        nextResume = ProgramResume.fromJson(rawResume);
      } catch (_) {
        if (limits != null) {
          throw const FormatException('« Où j’en suis » illisible.');
        }
      }
    }
    // G10 : évolution du programme. Import strict ; démarrage tolérant
    // (section illisible gardée telle quelle, jamais perdue).
    var nextEvolution = PlanEvolution.empty;
    Map<String, dynamic>? evolutionRaw;
    var evolutionIssues = 0;
    final rawEvolution = m['planEvolution'];
    if (rawEvolution != null) {
      try {
        nextEvolution = PlanEvolution.fromJson(rawEvolution);
      } catch (_) {
        if (limits != null) {
          throw const FormatException('Évolution du programme illisible.');
        }
        evolutionIssues = 1;
        if (rawEvolution is Map) {
          evolutionRaw = Map<String, dynamic>.from(rawEvolution);
        }
      }
    }
    // L11 : adaptations. Import strict ; démarrage tolérant.
    final adaptIssues = <String>[];
    final nextAdapt = AdaptData.fromJson(
      m['adapt'],
      strict: limits != null,
      issues: adaptIssues,
    );
    return _BackupData(
      values: nextValues,
      refStatus: nextStatus,
      start: nextStart,
      startOrigin: nextOrigin,
      logs: nextLogs,
      settings: nextSettings,
      userExercises: nextUser,
      lastLevel: m['lastLevel'] as int?,
      koach: nextKoach,
      koachIssues: koachIssues.length,
      profile: nextProfile,
      profileIssues: profileIssues.length,
      athlete: nextAthlete,
      athleteRaw: athleteRaw,
      athleteIssues: athleteIssues,
      programInstance: nextProgram,
      programIssues: programIssues.length,
      planProgram: nextPlan,
      planRaw: planRaw,
      planIssues: planIssues,
      programResume: nextResume,
      planEvolution: nextEvolution,
      evolutionRaw: evolutionRaw,
      evolutionIssues: evolutionIssues,
      adapt: nextAdapt,
      adaptIssues: adaptIssues.length,
      retired: RetiredData.of(m).summary,
    );
  }

  /// Tailles des collections d'un import, avant toute conversion (KT-015).
  static void _checkCollections(Map<String, dynamic> m, ImportLimits limits) {
    void cap(Object? value, int limit, String what) {
      final n = value is Map
          ? value.length
          : (value is List ? value.length : 0);
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
    // G2 : sections retirées, ignorées à la lecture mais encore bornées
    // (un fichier de 6.0.x est lu en entier avant d'être validé).
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
    refStatus
      ..clear()
      ..addAll(data.refStatus);
    programInstance = data.programInstance;
    programLoadIssues = data.programIssues;
    planProgram = data.planProgram;
    _planRaw = data.planRaw;
    planLoadIssues = data.planIssues;
    programResume = data.programResume;
    planEvolution = data.planEvolution;
    _evoRaw = data.evolutionRaw;
    evolutionLoadIssues = data.evolutionIssues;
    _evoRevision++;
    _evoRefreshKey = '';
    lastEvolutionReview = null;
    // Libellés des objectifs du programme : profil de la sauvegarde.
    athlete = data.athlete;
    _materializeProgram(data.start);
    startOrigin = data.startOrigin;
    logs
      ..clear()
      ..addAll(data.logs);
    settings = data.settings;
    userExercises
      ..clear()
      ..addAll(data.userExercises);
    koach = data.koach;
    koachLoadIssues = data.koachIssues;
    profile = data.profile;
    profileLoadIssues = data.profileIssues;
    athlete = data.athlete;
    _athleteRaw = data.athleteRaw;
    athleteLoadIssues = data.athleteIssues;
    adapt = data.adapt;
    adaptLoadIssues = data.adaptIssues;
    _allEx = null;
    _muscleIndex = null;
    pilotageEpoch++;
    themeMode.value = settings.theme;
    accentMode.value = settings.accent;
    _lastLevel = data.lastLevel ?? level;
    // G2 : un état remplacé (import, effacement) n'a plus de données
    // retirées en attente ; l'ancien reste dans la copie de récupération.
    _retiredPending = RetiredData.empty;
    retiredCopyFailed = false;
    _progression = null;
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
            program: program,
            now: KalisClock.now(),
          ),
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
    data['exportedAt'] = (at ?? KalisClock.now()).toIso8601String();
    data['appVersion'] = appVersion;
    // G1 : export d'une session de test, reconnu à l'import (champs
    // optionnels, ignorés par les versions précédentes).
    if (SessionSpace.isDev) {
      data['sessionDeTest'] = true;
      data['decalageJours'] = KalisClock.offsetDays;
    }
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
      _lastLevel = 1;
      _pendingReward = null;
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

  /// État d'une installation neuve : aucune référence, aucun journal,
  /// réglages par défaut.
  _BackupData _freshData() {
    // État d'installation neuve (L2b) : programme non démarré, références
    // non renseignées (KT-006/007).
    return _BackupData(
      values: {},
      refStatus: {},
      start: null,
      startOrigin: '',
      logs: {},
      settings: AppSettings(),
      userExercises: [],
      lastLevel: 1,
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
        'at': KalisClock.now().toIso8601String(),
        'reason': reason,
        // G2 : document local complet (données retirées encore en attente
        // de copie comprises).
        'state': _pack(_stateDocument()),
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
    final ok = await _writeRaw(_pack(_stateDocument()));
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
      ok = hook != null
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
  /// Référence saisie par l'utilisateur : elle devient « renseignée ».
  /// Refus silencieux d'une valeur hors domaine (vide, non finie, négative,
  /// poids du corps nul, > 10 000) : la valeur précédente est gardée.
  void setValue(String ref, double v) {
    if (!referenceRefs.contains(ref) ||
        !v.isFinite ||
        v < 0 ||
        v > 10000 ||
        (ref == 'B4' && v == 0)) {
      return;
    }
    if (values[ref] == v && refStatus[ref] == 'set') return;
    values[ref] = v;
    refStatus[ref] = 'set';
    // Poids du corps saisi : pesée du jour (le profil et les charges lisent
    // la pesée la plus récente ; L7 le faisait, G10 le garde).
    if (ref == 'B4' && koach.weighIns.isNotEmpty && v >= 20 && v <= 400) {
      final day = civilDateString(storeClock());
      koach.weighIns
        ..removeWhere((w) => w.date == day)
        ..add(WeighIn(day, v))
        ..sort((a, b) => a.date.compareTo(b.date));
    }
    _persist();
    notifyListeners();
  }

  /// « C'est bien ma valeur » : une référence historique devient renseignée,
  /// sans changer sa valeur.
  void confirmReference(String ref) {
    if (!values.containsKey(ref) || refStatus[ref] == 'set') return;
    refStatus[ref] = 'set';
    _persist();
    notifyListeners();
  }

  /// « Je ne sais pas » : la référence redevient non renseignée ; les
  /// calculs qui en dépendent l'indiquent au lieu de la remplacer.
  void clearReference(String ref) {
    if (!values.containsKey(ref)) return;
    values.remove(ref);
    refStatus.remove(ref);
    pilotageEpoch++;
    _persist();
    notifyListeners();
  }

  /// Toutes les références redeviennent « non renseignées » (les valeurs
  /// embarquées sont celles du créateur, pas celles de l'utilisateur).
  /// Séances, historique et récompenses ne changent pas.
  void resetPilotage() {
    pilotageEpoch++;
    values.clear();
    refStatus.clear();
    _persist();
    notifyListeners();
  }

  /// La charge suggérée dépend d'une référence non renseignée.
  bool loadNeedsReference(Exercise e) {
    final s = e.load;
    return switch (s.type) {
      'system' => !values.containsKey('B4') || !values.containsKey(s.ref),
      'barbell' => !values.containsKey(s.ref ?? 'B11'),
      'acc' => !values.containsKey(s.ref),
      _ => false,
    };
  }

  /// Première référence manquante pour calculer la charge ou le volume d'un
  /// exercice, null si le calcul est possible.
  String? missingReference(Exercise e) {
    final s = e.load;
    final needs = <String>[
      if (s.type == 'system') ...['B4', s.ref!],
      if (s.type == 'barbell') s.ref ?? 'B11',
      if (s.type == 'acc') s.ref!,
      if (e.sets.type == 'volume') e.sets.ref!,
    ];
    for (final ref in needs) {
      if (!values.containsKey(ref)) return ref;
    }
    return null;
  }

  /// Libellé d'une référence (« Traction lestée (1RM) », « Tractions (max) »).
  String referenceLabel(String ref) {
    final p = program.pilotage;
    if (ref == 'B4') return 'Poids du corps';
    for (final l in p.mainLifts) {
      if (l.ref == ref) return '${l.name} (1RM)';
    }
    for (final r in p.repMax) {
      if (r.ref == ref) return '${r.name} (max)';
    }
    for (final a in p.accessories) {
      if (a.ref == ref) return a.name;
    }
    return ref;
  }

  // ---------- Départ du programme (KT-006) ----------
  /// Bornes du départ choisi (décision du 26/09/2026) : jusqu'à 280 jours
  /// dans le passé (reprise en cours de programme), un an dans le futur.
  static const startPastDays = 280, startFutureDays = 365;

  /// Le départ proposé est-il dans les bornes, par rapport à aujourd'hui ?
  bool startAllowed(DateTime date) {
    final today = Program.civilIndex(storeClock());
    final d = Program.civilIndex(date);
    return d >= today - startPastDays && d <= today + startFutureDays;
  }

  /// Enregistre le départ (S1·J1 = [date], quel que soit le jour) et, le
  /// cas échéant, les références saisies (null = « Je ne sais pas »).
  /// Rien n'est considéré comme configuré tant que l'écriture n'est pas
  /// acceptée : en cas d'échec, l'état précédent est rétabli en mémoire.
  /// Aucune séance, aucun résultat, aucune récompense n'est créé.
  Future<StartSave> configureStart(
    DateTime date, {
    Map<String, double?> references = const {},
  }) async {
    final day = DateTime(date.year, date.month, date.day);
    if (!startAllowed(day)) return StartSave.outOfRange;
    for (final e in references.entries) {
      final v = e.value;
      if (!referenceRefs.contains(e.key) ||
          (v != null &&
              (!v.isFinite ||
                  v < 0 ||
                  v > 10000 ||
                  (e.key == 'B4' && v == 0)))) {
        return StartSave.invalid;
      }
    }
    final previous = (
      start: program.start,
      origin: startOrigin,
      values: Map<String, double>.of(values),
      status: Map<String, String>.of(refStatus),
    );
    program.start = day;
    startOrigin = 'user';
    references.forEach((ref, v) {
      if (v == null) {
        values.remove(ref);
        refStatus.remove(ref);
      } else {
        values[ref] = v;
        refStatus[ref] = 'set';
      }
    });
    pilotageEpoch++;
    _dataRevision++;
    _changeSeq++;
    notifyListeners();
    final ok = _initialized && await _serialize(_commitState);
    if (ok) return StartSave.saved;
    // Écriture refusée : pas de départ annoncé, l'état précédent revient.
    program.start = previous.start;
    startOrigin = previous.origin;
    values
      ..clear()
      ..addAll(previous.values);
    refStatus
      ..clear()
      ..addAll(previous.status);
    pilotageEpoch++;
    notifyListeners();
    return StartSave.unsaved;
  }

  // ---------- Calculs (répliques des formules Excel) ----------
  double _round(double x, double step) => (x / step).round() * step;

  /// Charge suggérée en kg, ou null si non applicable : la consigne du
  /// programme (G10 : Koach L7 retiré ; une séance servie par kalis_adapt
  /// porte la charge du moteur).
  double? loadFor(Exercise e) {
    final s = e.load;
    // G9 : exercice servi par kalis_adapt, charge du moteur.
    if (e.engine) return s.kg;
    // Référence non renseignée : aucune charge inventée (KT-007).
    if (loadNeedsReference(e)) return null;
    switch (s.type) {
      case 'fixed':
        return s.kg;
      case 'system':
        final pdc = values['B4']!; // présence vérifiée (loadNeedsReference)
        final rm = values[s.ref!] ?? 0;
        final raw = (pdc + rm) * ProfileStore(this).profilePct(s) - pdc;
        final r = _round(raw, 2.5);
        return r < 0 ? 0.0 : r;
      case 'barbell':
        return _round(
          (values[s.ref ?? 'B11'] ?? 0) * ProfileStore(this).profilePct(s),
          2.5,
        );
      case 'acc':
        final ref = values[s.ref!] ?? 0;
        final rr = refReps[s.ref!] ?? 10;
        final raw = ref * (1 + (rr + 2) / 30) / (1 + (s.dayReps! + 2) / 30);
        return _round(raw, s.step!);
      default:
        return null;
    }
  }

  /// Charge prescrite pour la semaine [week] du programme. G10 : celle de
  /// [loadFor] (Koach L7 et les adaptations L11 sont retirés ; le moteur
  /// dynamique sert ses propres charges).
  double? sessionLoad(int week, Exercise e, {int? day}) => loadFor(e);

  /// [week] : charge de la séance de cette semaine ([sessionLoad]).
  String loadLabel(Exercise e, {int? week, int? day}) {
    final kg = week == null ? loadFor(e) : sessionLoad(week, e, day: day);
    if (kg == null && loadNeedsReference(e)) return 'à renseigner';
    if (kg == null) return '—';
    if (kg <= 0) return 'PdC';
    if (settings.lb) {
      final lb = kg * 2.20462;
      return '${lb.toStringAsFixed(lb == lb.roundToDouble() ? 0 : 1)}\u00A0lb';
    }
    // Charge du moteur (grille du matériel, 1,25 kg…) : deux décimales au
    // plus ; sinon une.
    final t = e.engine
        ? koachKg(kg)
        : kg == kg.roundToDouble()
        ? kg.toInt().toString()
        : kg.toStringAsFixed(1).replaceAll('.', ',');
    return '$t\u00A0kg';
  }

  /// Texte pré-rempli de la colonne kg (une décimale au plus).
  String kgFieldText(double kg) {
    return kg == kg.roundToDouble()
        ? kg.toInt().toString()
        : kg.toStringAsFixed(1);
  }

  TrainingEstimate exerciseEstimate(Exercise e) {
    double? maximum;
    final name = e.name.toLowerCase();
    final ref = name.contains('muscle')
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

  Map<String, double> plannedMuscles(TrainingEstimate estimate) {
    final out = <String, double>{};
    for (final name in plannedNames(estimate).keys) {
      for (final group in groupsFor(name)) {
        out[group] = 1;
      }
    }
    return out;
  }

  /// 5.5.3 : exercices prévus (nom → poids 1) : la zone ciblée sur le
  /// mannequin vient des muscles du pack de chaque exercice
  /// (`targetedRegionIntensities`), plus du groupe entier.
  Map<String, double> plannedNames(TrainingEstimate estimate) => {
    for (final m in estimate.movements) m.name: 1,
    for (final e in estimate.details) e.title: 1,
  };

  /// Rendu de la colonne « Séries × Reps » (les volumes suivent tes maxima).
  String setsLabel(Exercise e) {
    final s = e.sets;
    if (s.type == 'volume') {
      final ref = values[s.ref!];
      // Maximum non renseigné : volume à renseigner, jamais calculé sur 0.
      if (ref == null) return '${s.prefix}?${s.suffix}';
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
        (e['n'] as String).toLowerCase(): (e['g'] as String)
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
    // G3 : nom de la base v1.1 (exercice échangé, futures séances).
    final id = content.idFor(splitName(name).$1);
    final entry = id == null ? null : content.byId[id];
    if (entry != null &&
        normalizeText(entry.nom) == normalizeText(splitName(name).$1)) {
      return entry.groupes;
    }
    return const [];
  }

  /// Les séries sont attribuées à leur date de validation. Les anciens logs
  /// utilisent la fin de séance, ou la date planifiée si la séance est en cours.
  Map<String, double> weeklyMuscles([DateTime? at]) {
    final out = <String, double>{for (final g in muscleGroups) g: 0};
    weeklyNames(at).forEach((name, sets) {
      final gs = groupsFor(name);
      for (var i = 0; i < gs.length; i++) {
        out[gs[i]] = (out[gs[i]] ?? 0) + sets * (i == 0 ? 1.0 : 0.6);
      }
    });
    return out;
  }

  /// 5.5.3 : exercices de la semaine (nom → séries validées), base des groupes (`weeklyMuscles`) et de la zone ciblée sur le
  /// mannequin (`targetedRegionIntensities`).
  Map<String, double> weeklyNames([DateTime? at]) {
    final now = at ?? KalisClock.now();
    final monday = DateTime(now.year, now.month, now.day - now.weekday + 1);
    final out = <String, double>{};
    bool inWeek(DateTime? date) =>
        date != null && !date.isBefore(monday) && !date.isAfter(now);
    void add(String name, double sets) {
      out[name] = (out[name] ?? 0) + sets;
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
          fallback ??= program.legacyDateFor(week, day);
        }
      }
      for (final ex in sl.ex.entries) {
        final name = names[ex.key];
        if (name == null) continue;
        final n = ex.value.sets
            .where(
              (set) =>
                  set.done &&
                  inWeek(DateTime.tryParse(set.completedAt ?? '') ?? fallback),
            )
            .length;
        if (n > 0) add(name, n.toDouble());
      }
    }
    return out;
  }

  // ---------- Nature de la saisie ----------
  LogSpec logSpec(Exercise e) {
    // G9 : séance servie par kalis_adapt (libellés de adaptSetsText).
    if (e.engine) {
      final t = setsLabel(e).toLowerCase().trim();
      if (t.endsWith('max s')) return const LogSpec('holdMax');
      if (t.endsWith('max')) return const LogSpec('repsMax');
      final h = RegExp(r'^\d+\s*×\s*(\d+)(?:-(\d+))?\s*s$').firstMatch(t);
      if (h != null) {
        return LogSpec('hold', seconds: int.parse(h.group(2) ?? h.group(1)!));
      }
      return const LogSpec('reps');
    }
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
    return s.ex.putIfAbsent(e.id, () {
      // G9 : un exercice servi par kalis_adapt garde les séries du moteur.
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

  /// Réponses et décisions de l'ancien Koach (L7, lecture seule) d'une
  /// séance supprimée, gardées pour l'annulation.
  final Map<String, ({SessionAnswers? answers, List<KoachDecision> decisions})>
  _legacyStash = {};

  /// Une séance supprimée emporte ses réponses et décisions de l'ancien
  /// Koach (L7) ; [stash] : gardées pour l'annulation.
  void _forgetLegacySession(String key, {bool stash = false}) {
    final answers = koach.answers.remove(key);
    final decisions = [
      for (final d in koach.decisions)
        if (d.id.startsWith('$key|')) d,
    ];
    koach.decisions.removeWhere((d) => d.id.startsWith('$key|'));
    if (stash) _legacyStash[key] = (answers: answers, decisions: decisions);
    if (answers != null || decisions.isNotEmpty) _persist();
  }

  void _restoreLegacySession(String key) {
    final kept = _legacyStash.remove(key);
    if (kept == null) return;
    if (kept.answers != null) koach.answers[key] = kept.answers!;
    koach.decisions.addAll(kept.decisions);
    _persist();
  }

  /// KT-036 : suppression des seules réponses aux anciens questionnaires
  /// de Koach L7 (sommeil, forme, douleur).
  void clearKoachAnswers() {
    if (koach.answers.isEmpty) return;
    koach.answers.clear();
    _persist();
    notifyListeners();
  }

  /// Efface tout l'historique d'une séance : séries, notes, statut « fait »
  /// (et ses réponses et décisions de l'ancien Koach L7).
  void clearSession(int week, int j) {
    logs.remove(sessionKey(week, j));
    _forgetLegacySession(sessionKey(week, j));
    saveLogs(immediate: true);
  }

  // ---------- Séries (KT-009) ----------
  /// Coche ou décoche une série. La coche n'est acceptée qu'avec une saisie
  /// valide pour le mode (voir `set_validation.dart`) : un pré-remplissage
  /// devient une performance seulement ici. Refus : rien ne change, le
  /// texte saisi est gardé.
  SetCheck toggleSet(ExerciseLog log, int index, LogSpec spec) {
    final s = log.sets[index];
    if (s.done) {
      s.done = false;
      s.completedAt = null;
      saveLogs();
      return const SetCheck.ok();
    }
    final check = checkSet(spec, s, rpe: settings.rpe);
    if (!check.ok) return check;
    s.done = true;
    s.completedAt = storeClock().toIso8601String();
    saveLogs();
    return check;
  }

  /// Difficulté (RIR) d'une série, écrite avec ses flammes (G9 ; champ
  /// `effort` de L7, lu par les anciennes versions et le journal des
  /// moteurs).
  void setEffort(ExerciseLog log, int index, double? rir) {
    log.sets[index].effort = rir;
    saveLogs(affectsProgression: false);
  }

  /// Série écartée (incident, D11 de L7 gardée en G9) : gardée au journal,
  /// hors des estimations des moteurs.
  void toggleExcluded(ExerciseLog log, int index) {
    final s = log.sets[index];
    s.excluded = !s.excluded;
    saveLogs(affectsProgression: false);
  }

  /// Après la modification d'une série déjà validée : si sa saisie n'est
  /// plus valide, elle repasse « non validée » (jamais de série terminée
  /// avec une valeur invalide). Renvoie le problème, ou null.
  SetCheck? revalidateSet(ExerciseLog log, int index, LogSpec spec) {
    final s = log.sets[index];
    if (!s.done) return null;
    final check = checkSet(spec, s, rpe: settings.rpe);
    if (check.ok) return null;
    s.done = false;
    s.completedAt = null;
    saveLogs();
    return check;
  }

  void markSessionDone(int week, int j, bool done, {String? title}) {
    final s = sessionLog(week, j);
    final wasDone = s.done;
    final before = progression;
    final goal = game.sessionGoal;
    s.done = done;
    // Une séance rouverte pour correction garde sa date de fin d'origine :
    // semaine, série et historique ne se déplacent pas au jour de la retouche.
    final finishedAt = s.finishedAt ?? storeClock().toIso8601String();
    s.finishedAt = done ? finishedAt : null;
    if (title != null) s.title = title;
    saveLogs(immediate: true);
    if (!done || wasDone) return;
    final training =
        program.weeks.any((w) => w.n == week) &&
        (program.week(week).day(j)?.exercises.isNotEmpty ?? false);
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
      baseXp: 100,
      baseLabel: 'Journée du programme',
      records: sessionRecords(sessionKey(week, j)),
      goalReached: total == 0 ? null : ok / total >= goal - 1e-9,
    );
  }

  bool isDone(int week, int j) => logs[sessionKey(week, j)]?.done ?? false;

  // ---------- Fin de séance (KT-018) ----------
  /// Bilans calculés dont l'écriture a été refusée : présentés seulement
  /// après une écriture acceptée (jamais de fin annoncée trop tôt).
  final Map<String, RewardSummary> _unsavedRewards = {};

  /// Termine une séance et attend l'écriture. `saved` : séance terminée et
  /// enregistrée, bilan prêt ([consumeReward]). `unsaved` : terminée en
  /// mémoire, écriture refusée ; saisies gardées, nouvel appel = nouvelle
  /// tentative d'écriture, sans second bilan ni second gain (XP dérivée du
  /// journal, crédits au registre L3 par identifiant).
  Future<ResultSave> finishSession(int week, int j, {String? title}) async {
    final key = sessionKey(week, j);
    if (!isDone(week, j)) {
      markSessionDone(week, j, true, title: title);
      final reward = _pendingReward;
      _pendingReward = null;
      if (reward != null) _unsavedRewards[key] = reward;
    }
    await flush();
    if (hasUnsavedChanges) return ResultSave.unsaved;
    final reward = _unsavedRewards.remove(key);
    if (reward != null) _pendingReward = reward;
    return ResultSave.saved;
  }

  // ---------- Séances en cours (KT-018) ----------
  /// Séance en cours : journal non terminé avec une activité réelle (une
  /// série validée ou une note). Ouvrir une séance ou afficher des
  /// suggestions n'en fait pas une séance en cours.
  bool inProgress(String key) {
    final log = logs[key];
    if (log == null || log.done) return false;
    return log.ex.values.any(
      (e) => e.note.trim().isNotEmpty || e.sets.any((s) => s.done),
    );
  }

  /// Séances du programme à reprendre, la plus récente d'abord.
  List<SessionResume> get sessionsInProgress {
    final out = <SessionResume>[];
    for (final entry in logs.entries) {
      final match = RegExp(r'^S(\d+)-J(\d+)$').firstMatch(entry.key);
      if (match == null || !inProgress(entry.key)) continue;
      final n = int.parse(match[1]!), j = int.parse(match[2]!);
      if (n == 0 || n > program.weeks.length) continue;
      final week = program.week(n);
      final day = week.day(j);
      if (day == null || day.exercises.isEmpty) continue;
      final title = 'S$n · J$j — ${day.title}';
      var done = 0, total = 0;
      DateTime? last;
      for (final e in entry.value.ex.values) {
        total += e.sets.length;
        for (final set in e.sets.where((x) => x.done)) {
          done++;
          final at = DateTime.tryParse(set.completedAt ?? '');
          if (at != null && (last == null || at.isAfter(last))) last = at;
        }
      }
      out.add(
        SessionResume(
          key: entry.key,
          week: week,
          day: day,
          title: title,
          done: done,
          total: total,
          last: last,
        ),
      );
    }
    out.sort((a, b) {
      final x = a.last, y = b.last;
      if (x == null || y == null) return x == null ? 1 : -1;
      return y.compareTo(x);
    });
    return out;
  }

  /// Page de reprise : groupe de la dernière série validée, ou le suivant
  /// s'il est complet (le bilan après le dernier). 0 sans série validée.
  int resumePage(int week, int j, List<List<Exercise>> groups) {
    final log = logs[sessionKey(week, j)];
    if (log == null || log.done) return 0;
    var page = -1;
    DateTime? last;
    for (var g = 0; g < groups.length; g++) {
      for (final e in groups[g]) {
        for (final set in log.ex[e.id]?.sets ?? const <SetEntry>[]) {
          if (!set.done) continue;
          final at = DateTime.tryParse(set.completedAt ?? '');
          if (page < 0 ||
              (at != null && (last == null || !at.isBefore(last)))) {
            page = g;
            last = at ?? last;
          }
        }
      }
    }
    if (page < 0) return 0;
    final complete = groups[page].every(
      (e) => (log.ex[e.id]?.sets ?? const <SetEntry>[]).every((x) => x.done),
    );
    return complete ? page + 1 : page;
  }

  // ---------- Correction depuis l'historique ----------

  /// Séance à rouvrir pour corriger une entrée terminée du journal : journée
  /// d'entraînement du programme. Null pour une archive (clé « …@uid ») ou
  /// un jour de repos : seule la suppression reste alors proposée.
  ({WeekPlan week, DayPlan day})? correctionPlan(String key) {
    if (logs[key]?.done != true) return null;
    final match = RegExp(r'^S(\d+)-J(\d+)$').firstMatch(key);
    if (match == null) return null;
    final n = int.parse(match[1]!), j = int.parse(match[2]!);
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
    if (removed != null) {
      _forgetLegacySession(key, stash: true);
      saveLogs(immediate: true);
    }
    return removed;
  }

  /// Annulation d'une suppression : n'écrase jamais une séance recommencée
  /// entre-temps sous la même clé.
  bool restoreLog(String key, SessionLog log) {
    if (logs.containsKey(key)) return false;
    logs[key] = log;
    _restoreLegacySession(key);
    saveLogs(immediate: true);
    return true;
  }

  int get completedCount => program.weeks.fold(
    0,
    (n, w) => n + w.days.where((d) => isDone(w.n, d.j)).length,
  );

  @override
  void dispose() {
    _saveT?.cancel();
    themeMode.dispose();
    accentMode.dispose();
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
  final int programSessions, archivedSessions, userExercises;
  final int level, xp;

  /// G2 : données du fichier qui ne sont plus importées (WOD, séances
  /// manuelles, crédits, motivation L12) ; vide pour un fichier récent.
  final RetiredSummary ignored;

  ImportPreview._({
    required _BackupData data,
    required String encoded,
    required Map<String, dynamic> meta,
    required Progression progression,
    required this.localRevision,
  }) : _data = data,
       _encoded = encoded,
       format = (meta['format'] ?? 1) as int,
       exportedAt = meta['exportedAt'] is String
           ? DateTime.tryParse(meta['exportedAt'] as String)
           : null,
       appVersion = meta['appVersion'] is String
           ? meta['appVersion'] as String
           : null,
       programSessions = data.logs.values.where((l) => l.done).length,
       archivedSessions = data.logs.keys.where((k) => k.contains('@')).length,
       userExercises = data.userExercises.length,
       ignored = data.retired,
       level = progression.level,
       xp = progression.totalXp;

  /// Séances terminées au total.
  int get sessionsDone => programSessions;

  /// Départ du programme contenu dans le fichier (null : non démarré).
  DateTime? get programStart => _data.start;

  /// 'user', 'migration' (calendrier d'origine) ou '' (non démarré).
  String get startOrigin => _data.startOrigin;

  /// Références renseignées / héritées à vérifier dans le fichier.
  int get referencesSet =>
      _data.refStatus.values.where((s) => s == 'set').length;
  int get referencesHistoric =>
      _data.refStatus.values.where((s) => s == 'historic').length;

  /// L7 : section Koach du fichier (absente = Koach jamais utilisé).
  bool get koachPresent => !_data.koach.pristine;
  bool get koachEnabled => _data.koach.enabled;
  int get koachWeighIns => _data.koach.weighIns.length;

  /// Séances avec réponses aux questionnaires (sommeil, forme, douleur).
  int get koachAnswers => _data.koach.answers.length;

  /// L8 : profil présent dans le fichier, et réponses de santé.
  bool get profilePresent => _data.profile != null;
  bool get profileHealth => _data.profile?.health.hasHealthContent ?? false;

  /// G6 : profil d'athlète v2 présent dans le fichier.
  bool get athleteProfilePresent => _data.athlete != null;
}

class _BackupData {
  final Map<String, double> values;
  final Map<String, String> refStatus;
  final DateTime? start;
  final String startOrigin;
  final Map<String, SessionLog> logs;
  final AppSettings settings;
  final List<Map<String, dynamic>> userExercises;
  final int? lastLevel;

  /// L7 : décisions Koach (neuves si la section est absente).
  final KoachData koach;
  final int koachIssues;

  /// L8 : profil (null si la section est absente).
  final UserProfile? profile;
  final int profileIssues;

  /// G6 : profil d'athlète v2 (null si la section est absente) ; section
  /// illisible gardée telle quelle ([athleteRaw]).
  final AthleteRecord? athlete;
  final Map<String, dynamic>? athleteRaw;
  final int athleteIssues;

  /// L10 : instance de programme (null si la section est absente).
  final ProgramInstance? programInstance;
  final int programIssues;

  /// G7 : programme kalis_plan (null si absent ; illisible : [planRaw]) et
  /// « Où j'en suis ».
  final PlanProgram? planProgram;
  final Map<String, dynamic>? planRaw;
  final int planIssues;
  final ProgramResume? programResume;

  /// G10 : évolution du programme (vide si absente ; illisible :
  /// [evolutionRaw]).
  final PlanEvolution planEvolution;
  final Map<String, dynamic>? evolutionRaw;
  final int evolutionIssues;

  /// L11 : adaptations (neuves si la section est absente).
  final AdaptData adapt;
  final int adaptIssues;

  /// G2 : données retirées présentes dans le document lu (ignorées).
  final RetiredSummary retired;
  _BackupData({
    required this.values,
    required this.refStatus,
    required this.start,
    required this.startOrigin,
    required this.logs,
    required this.settings,
    required this.userExercises,
    this.lastLevel,
    KoachData? koach,
    this.koachIssues = 0,
    this.profile,
    this.profileIssues = 0,
    this.athlete,
    this.athleteRaw,
    this.athleteIssues = 0,
    this.programInstance,
    this.programIssues = 0,
    this.planProgram,
    this.planRaw,
    this.planIssues = 0,
    this.programResume,
    this.planEvolution = PlanEvolution.empty,
    this.evolutionRaw,
    this.evolutionIssues = 0,
    AdaptData? adapt,
    this.adaptIssues = 0,
    this.retired = const RetiredSummary(),
  }) : koach = koach ?? KoachData(),
       adapt = adapt ?? AdaptData();
}

/// Séance à reprendre (bandeau de l'accueil).
class SessionResume {
  final String key, title;
  final WeekPlan week;
  final DayPlan day;
  final int done, total;
  final DateTime? last;
  const SessionResume({
    required this.key,
    required this.week,
    required this.day,
    required this.title,
    required this.done,
    required this.total,
    required this.last,
  });
}

/// « 2026-09-28 » : date civile, sans heure ni fuseau.
String civilDateString(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// « 28/09/2026 ».
String civilDateLabel(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Date civile « AAAA-MM-JJ » stricte (29/02 seulement les années
/// bissextiles) ; null sinon.
DateTime? parseCivilDate(Object? raw) {
  if (raw is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
    return null;
  }
  final y = int.parse(raw.substring(0, 4));
  final mo = int.parse(raw.substring(5, 7));
  final d = int.parse(raw.substring(8, 10));
  final date = DateTime(y, mo, d);
  return date.year == y && date.month == mo && date.day == d ? date : null;
}

/// Singleton global — simple et suffisant pour cette app.
/// Magasin de la session active. G1 : remplacé par un magasin neuf au
/// redémarrage logique (session de test, session_host.dart).
AppStore store = AppStore();
