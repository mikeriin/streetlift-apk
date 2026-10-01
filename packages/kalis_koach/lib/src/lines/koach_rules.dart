import 'package:meta/meta.dart';

import '../koach_pose.dart';
import 'koach_event.dart';

/// Règle « événement → réplique » : variantes de message, poses possibles,
/// paramètres attendus, priorité, actions et explication.
@immutable
class KoachRule {
  /// Crée une règle.
  const KoachRule({
    required this.event,
    required this.messageKeys,
    required this.poses,
    required this.priority,
    this.params = const <String>[],
    this.actions = const <KoachAction>[],
    this.whyKey,
  });

  /// Événement.
  final KoachEvent event;

  /// Variantes du message (au moins une), choisies à tour de rôle.
  final List<String> messageKeys;

  /// Poses possibles (au moins une), choisies à tour de rôle.
  final List<KoachPose> poses;

  /// Priorité ([KoachPriority]).
  final int priority;

  /// Paramètres obligatoires.
  final List<String> params;

  /// Actions proposées.
  final List<KoachAction> actions;

  /// Explication « Pourquoi ? ».
  final String? whyKey;
}

/// Entrée de la table des codes de raison du moteur.
@immutable
class KoachReason {
  /// Crée une entrée.
  const KoachReason({
    required this.code,
    required this.proposalKeys,
    required this.appliedKeys,
    required this.whyKey,
    required this.poses,
    this.params = const <String>[],
  });

  /// Code de raison produit par le moteur (`load_increased`…).
  final String code;

  /// Variantes du message de proposition.
  final List<String> proposalKeys;

  /// Variantes du message de changement appliqué.
  final List<String> appliedKeys;

  /// Explication « Pourquoi ? ».
  final String whyKey;

  /// Poses possibles.
  final List<KoachPose> poses;

  /// Paramètres obligatoires.
  final List<String> params;
}

/// Actions usuelles.
abstract final class KoachActions {
  /// Accepter.
  static const accept = KoachAction(KoachActionKind.accept, 'action.accept');

  /// Refuser.
  static const decline = KoachAction(KoachActionKind.decline, 'action.decline');

  /// Pourquoi ?
  static const why = KoachAction(KoachActionKind.why, 'action.why');

  /// Plus tard.
  static const later = KoachAction(KoachActionKind.later, 'action.later');

  /// Modifier le profil.
  static const editProfile =
      KoachAction(KoachActionKind.editProfile, 'action.edit_profile');

  /// Réessayer.
  static const retry = KoachAction(KoachActionKind.retry, 'action.retry');

  /// Annuler.
  static const undo = KoachAction(KoachActionKind.undo, 'action.undo');

  /// Commencer.
  static const start = KoachAction(KoachActionKind.start, 'action.start');

  /// Voir le détail.
  static const details = KoachAction(KoachActionKind.details, 'action.details');

  /// Continuer.
  static const continueOn =
      KoachAction(KoachActionKind.continueOn, 'action.continue');

  /// OK.
  static const ok = KoachAction(KoachActionKind.ok, 'action.ok');
}

/// Règles de base : une par événement (sauf [KoachEvent.why], construit à
/// partir de la réplique expliquée). Pour [KoachEvent.proposalNew] et
/// [KoachEvent.changeApplied], les messages viennent de la table des
/// raisons quand le code est connu, sinon de ces règles génériques.
// dart format off
const List<KoachRule> koachRules = <KoachRule>[
  KoachRule(event: KoachEvent.welcome, messageKeys: ['welcome.1', 'welcome.2'], poses: [KoachPose.wave, KoachPose.present], priority: KoachPriority.onboarding, actions: [KoachActions.start]),
  KoachRule(event: KoachEvent.profileStart, messageKeys: ['profile.start.1', 'profile.start.2'], poses: [KoachPose.checklist, KoachPose.wave], priority: KoachPriority.onboarding, actions: [KoachActions.continueOn]),
  KoachRule(event: KoachEvent.profileStep, messageKeys: ['profile.step.1', 'profile.step.2', 'profile.step.3'], poses: [KoachPose.checklist, KoachPose.thumbsUp, KoachPose.think], priority: KoachPriority.onboarding, params: ['remaining']),
  KoachRule(event: KoachEvent.profileDone, messageKeys: ['profile.done.1', 'profile.done.2'], poses: [KoachPose.thumbsUp, KoachPose.happy], priority: KoachPriority.confirm, actions: [KoachActions.continueOn]),
  KoachRule(event: KoachEvent.profileUpdateNeeded, messageKeys: ['profile.update.1', 'profile.update.2'], poses: [KoachPose.please, KoachPose.checklist], priority: KoachPriority.decision, params: ['field'], actions: [KoachActions.editProfile, KoachActions.later, KoachActions.why], whyKey: 'why.profile_update'),
  KoachRule(event: KoachEvent.programGenerating, messageKeys: ['program.generating.1', 'program.generating.2'], poses: [KoachPose.analyze, KoachPose.think], priority: KoachPriority.program),
  KoachRule(event: KoachEvent.programDraftReady, messageKeys: ['program.draft.1', 'program.draft.2'], poses: [KoachPose.explainBoard, KoachPose.direction], priority: KoachPriority.program, params: ['weeks'], actions: [KoachActions.details, KoachActions.why], whyKey: 'why.program_draft'),
  KoachRule(event: KoachEvent.programReady, messageKeys: ['program.ready.1', 'program.ready.2'], poses: [KoachPose.happy, KoachPose.flag, KoachPose.present], priority: KoachPriority.program, params: ['weeks'], actions: [KoachActions.start]),
  KoachRule(event: KoachEvent.reviewIntro, messageKeys: ['review.intro.1', 'review.intro.2'], poses: [KoachPose.explainBoard, KoachPose.checklist], priority: KoachPriority.program, actions: [KoachActions.continueOn, KoachActions.why], whyKey: 'why.review'),
  KoachRule(event: KoachEvent.reviewChangeApplied, messageKeys: ['review.applied.1', 'review.applied.2'], poses: [KoachPose.thumbsUp, KoachPose.settings], priority: KoachPriority.confirm, actions: [KoachActions.ok, KoachActions.undo]),
  KoachRule(event: KoachEvent.proposalNew, messageKeys: ['proposal.generic.1', 'proposal.generic.2'], poses: [KoachPose.choice, KoachPose.ponder], priority: KoachPriority.decision, actions: [KoachActions.accept, KoachActions.decline, KoachActions.why], whyKey: 'why.generic_change'),
  KoachRule(event: KoachEvent.proposalAccepted, messageKeys: ['proposal.accepted.1', 'proposal.accepted.2'], poses: [KoachPose.thumbsUp2, KoachPose.thumbsUp], priority: KoachPriority.confirm),
  KoachRule(event: KoachEvent.proposalDeclined, messageKeys: ['proposal.declined.1', 'proposal.declined.2'], poses: [KoachPose.shrug, KoachPose.thumbsUp], priority: KoachPriority.confirm),
  KoachRule(event: KoachEvent.changeApplied, messageKeys: ['applied.generic.1', 'applied.generic.2'], poses: [KoachPose.settings, KoachPose.analyze], priority: KoachPriority.applied, actions: [KoachActions.ok, KoachActions.why], whyKey: 'why.generic_change'),
  KoachRule(event: KoachEvent.healthCheckIntro, messageKeys: ['health.intro.1', 'health.intro.2'], poses: [KoachPose.please, KoachPose.checklist], priority: KoachPriority.health, actions: [KoachActions.continueOn, KoachActions.why], whyKey: 'why.health_check'),
  KoachRule(event: KoachEvent.healthCheckGood, messageKeys: ['health.good.1', 'health.good.2'], poses: [KoachPose.thumbsUp, KoachPose.pump, KoachPose.run], priority: KoachPriority.confirm, actions: [KoachActions.start]),
  KoachRule(event: KoachEvent.healthCheckDiscomfort, messageKeys: ['health.discomfort.1', 'health.discomfort.2'], poses: [KoachPose.please, KoachPose.love], priority: KoachPriority.health, actions: [KoachActions.continueOn]),
  KoachRule(event: KoachEvent.healthCheckPain, messageKeys: ['health.pain.1', 'health.pain.2'], poses: [KoachPose.please, KoachPose.heart], priority: KoachPriority.safety, actions: [KoachActions.ok, KoachActions.why], whyKey: 'why.health_pain'),
  KoachRule(event: KoachEvent.sessionEndGood, messageKeys: ['session.good.1', 'session.good.2', 'session.good.3'], poses: [KoachPose.clap, KoachPose.victory, KoachPose.thumbsUp2], priority: KoachPriority.feedback),
  KoachRule(event: KoachEvent.sessionEndHard, messageKeys: ['session.hard.1', 'session.hard.2'], poses: [KoachPose.fistBump, KoachPose.love], priority: KoachPriority.feedback),
  KoachRule(event: KoachEvent.sessionEndPartial, messageKeys: ['session.partial.1', 'session.partial.2'], poses: [KoachPose.thumbsUp, KoachPose.fistBump], priority: KoachPriority.feedback, params: ['done', 'planned']),
  KoachRule(event: KoachEvent.personalRecord, messageKeys: ['record.1', 'record.2', 'record.3'], poses: [KoachPose.victory, KoachPose.cheer, KoachPose.doubleBiceps, KoachPose.flex], priority: KoachPriority.record, params: ['exercise', 'value']),
  KoachRule(event: KoachEvent.error, messageKeys: ['error.1', 'error.2'], poses: [KoachPose.oops, KoachPose.shrug], priority: KoachPriority.error, actions: [KoachActions.retry]),
  KoachRule(event: KoachEvent.actionCancelled, messageKeys: ['cancelled.1', 'cancelled.2'], poses: [KoachPose.shrug, KoachPose.oops], priority: KoachPriority.feedback),
  KoachRule(event: KoachEvent.devSessionEnter, messageKeys: ['dev.enter.1', 'dev.enter.2'], poses: [KoachPose.settings, KoachPose.wave], priority: KoachPriority.session, actions: [KoachActions.ok, KoachActions.why], whyKey: 'why.dev_session'),
  KoachRule(event: KoachEvent.devSessionExit, messageKeys: ['dev.exit.1', 'dev.exit.2'], poses: [KoachPose.wave, KoachPose.thumbsUp], priority: KoachPriority.session),
  KoachRule(event: KoachEvent.featureIntro, messageKeys: ['feature.1', 'feature.2'], poses: [KoachPose.present, KoachPose.idea, KoachPose.readTip], priority: KoachPriority.discovery, params: ['feature'], actions: [KoachActions.details, KoachActions.later, KoachActions.why], whyKey: 'why.feature'),
];

/// Poses des explications « Pourquoi ? », à tour de rôle.
const List<KoachPose> koachWhyPoses = <KoachPose>[KoachPose.think, KoachPose.explainBoard, KoachPose.readTip, KoachPose.idea];

/// Table des codes de raison (exemples pour les codes les plus probables du
/// moteur dynamique ; extensible par [KoachReasonTable.extend]).
const List<KoachReason> koachBaseReasons = <KoachReason>[
  KoachReason(code: 'load_increased', proposalKeys: ['reason.load_increased.proposal.1', 'reason.load_increased.proposal.2'], appliedKeys: ['reason.load_increased.applied.1'], whyKey: 'why.load_increased', poses: [KoachPose.flex, KoachPose.progressChart], params: ['exercise']),
  KoachReason(code: 'volume_reduced', proposalKeys: ['reason.volume_reduced.proposal.1', 'reason.volume_reduced.proposal.2'], appliedKeys: ['reason.volume_reduced.applied.1'], whyKey: 'why.volume_reduced', poses: [KoachPose.please, KoachPose.analyze], params: ['exercise']),
  KoachReason(code: 'exercise_replaced', proposalKeys: ['reason.exercise_replaced.proposal.1', 'reason.exercise_replaced.proposal.2'], appliedKeys: ['reason.exercise_replaced.applied.1'], whyKey: 'why.exercise_replaced', poses: [KoachPose.choice, KoachPose.direction], params: ['exercise', 'replacement']),
  KoachReason(code: 'session_shortened', proposalKeys: ['reason.session_shortened.proposal.1', 'reason.session_shortened.proposal.2'], appliedKeys: ['reason.session_shortened.applied.1'], whyKey: 'why.session_shortened', poses: [KoachPose.sprint, KoachPose.run], params: ['minutes']),
  KoachReason(code: 'deload', proposalKeys: ['reason.deload.proposal.1', 'reason.deload.proposal.2'], appliedKeys: ['reason.deload.applied.1'], whyKey: 'why.deload', poses: [KoachPose.love, KoachPose.please]),
  KoachReason(code: 'calibration', proposalKeys: ['reason.calibration.proposal.1'], appliedKeys: ['reason.calibration.applied.1'], whyKey: 'why.calibration', poses: [KoachPose.analyze, KoachPose.anatomy], params: ['exercise']),
];
// dart format on

/// Table « code de raison du moteur → messages », extensible.
@immutable
class KoachReasonTable {
  const KoachReasonTable._(this._byCode);

  /// Table de base ([koachBaseReasons]).
  factory KoachReasonTable.base() =>
      KoachReasonTable._({for (final r in koachBaseReasons) r.code: r});

  final Map<String, KoachReason> _byCode;

  /// Entrée du code, ou `null` si le code est inconnu (message générique).
  KoachReason? operator [](String code) => _byCode[code];

  /// Codes connus, triés.
  List<String> get codes => _byCode.keys.toList()..sort();

  /// Toutes les entrées, triées par code.
  List<KoachReason> get entries => [for (final c in codes) _byCode[c]!];

  /// Nouvelle table avec des entrées ajoutées ou remplacées.
  KoachReasonTable extend(Iterable<KoachReason> more) =>
      KoachReasonTable._({..._byCode, for (final r in more) r.code: r});
}
