import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../koach_pose.dart';

/// Événements auxquels Koach réagit (D6.4 : Koach parle partout).
enum KoachEvent {
  /// Premier lancement, accueil.
  welcome,

  /// Début de la création du profil.
  profileStart,

  /// Étape de la création du profil (paramètre `remaining`).
  profileStep,

  /// Profil terminé.
  profileDone,

  /// Le profil doit être mis à jour (paramètre `field`) — D6.5.
  profileUpdateNeeded,

  /// Création du programme en cours.
  programGenerating,

  /// Première passe prête, à relire (paramètre `weeks`).
  programDraftReady,

  /// Programme final prêt (paramètre `weeks`).
  programReady,

  /// Ouverture de la revue du programme.
  reviewIntro,

  /// Modification appliquée pendant la revue.
  reviewChangeApplied,

  /// Proposition de changement du moteur (code de raison).
  proposalNew,

  /// Proposition acceptée.
  proposalAccepted,

  /// Proposition refusée.
  proposalDeclined,

  /// Changement appliqué automatiquement par le moteur (code de raison).
  changeApplied,

  /// Ouverture du bilan santé avant la séance.
  healthCheckIntro,

  /// Bilan santé : tout va bien.
  healthCheckGood,

  /// Bilan santé : gêne signalée.
  healthCheckDiscomfort,

  /// Bilan santé : douleur signalée.
  healthCheckPain,

  /// Fin de séance réussie.
  sessionEndGood,

  /// Fin de séance difficile.
  sessionEndHard,

  /// Séance écourtée (paramètres `done`, `planned`).
  sessionEndPartial,

  /// Nouveau record (paramètres `exercise`, `value`).
  personalRecord,

  /// Erreur.
  error,

  /// Action annulée.
  actionCancelled,

  /// Entrée dans la session de test (mode dev).
  devSessionEnter,

  /// Retour à la session personnelle.
  devSessionExit,

  /// Nouveauté présentée la première fois (paramètre `feature`).
  featureIntro,

  /// Explication « Pourquoi ? » d'une réplique précédente.
  why,
}

/// Actions qu'une bulle peut proposer.
enum KoachActionKind {
  /// Accepter une proposition.
  accept,

  /// Refuser une proposition.
  decline,

  /// Demander « Pourquoi ? ».
  why,

  /// Reporter.
  later,

  /// Modifier le profil.
  editProfile,

  /// Réessayer.
  retry,

  /// Annuler la dernière modification.
  undo,

  /// Commencer.
  start,

  /// Voir le détail.
  details,

  /// Continuer.
  continueOn,

  /// Fermer la bulle.
  ok,
}

/// Action proposée : sa nature et la clé de son libellé.
@immutable
class KoachAction {
  /// Crée une action.
  const KoachAction(this.kind, this.labelKey);

  /// Nature.
  final KoachActionKind kind;

  /// Clé du libellé dans la bibliothèque de messages.
  final String labelKey;

  @override
  bool operator ==(Object other) =>
      other is KoachAction && other.kind == kind && other.labelKey == labelKey;

  @override
  int get hashCode => Object.hash(kind, labelKey);

  @override
  String toString() => 'KoachAction(${kind.name})';
}

/// Demande de réplique envoyée par l'application.
///
/// [occurrence] = nombre de fois où cet événement a déjà été montré (tenu
/// par l'application) : deux occurrences successives n'ont jamais la même
/// variante quand il y en a plusieurs. [seed] = graine stable (par exemple
/// un nombre tiré une fois pour l'installation) qui décale l'ordre des
/// variantes sans hasard.
@immutable
class KoachCue {
  /// Crée une demande.
  const KoachCue(
    this.event, {
    this.params = const <String, String>{},
    this.reason,
    this.occurrence = 0,
    this.seed = 0,
  });

  /// Événement.
  final KoachEvent event;

  /// Paramètres déjà mis en forme par l'application (noms, nombres).
  final Map<String, String> params;

  /// Code de raison du moteur ([KoachEvent.proposalNew],
  /// [KoachEvent.changeApplied]).
  final String? reason;

  /// Nombre d'affichages précédents de l'événement (≥ 0).
  final int occurrence;

  /// Graine stable (≥ 0).
  final int seed;
}

/// Réplique choisie : tout ce qu'il faut pour afficher la bulle.
@immutable
class KoachLine {
  /// Crée une réplique.
  const KoachLine({
    required this.event,
    required this.pose,
    required this.messageKey,
    required this.params,
    required this.priority,
    required this.actions,
    required this.whyKey,
    this.reason,
  });

  /// Événement d'origine.
  final KoachEvent event;

  /// Pose de Koach.
  final KoachPose pose;

  /// Clé du message (variante choisie).
  final String messageKey;

  /// Paramètres du message.
  final Map<String, String> params;

  /// Priorité (plus grand = plus important) quand plusieurs répliques se
  /// disputent la place : voir [KoachPriority].
  final int priority;

  /// Actions proposées, dans l'ordre d'affichage.
  final List<KoachAction> actions;

  /// Clé de l'explication « Pourquoi ? », ou `null`.
  final String? whyKey;

  /// Code de raison du moteur, s'il y en a un.
  final String? reason;

  @override
  bool operator ==(Object other) =>
      other is KoachLine &&
      other.event == event &&
      other.pose == pose &&
      other.messageKey == messageKey &&
      const MapEquality<String, String>().equals(other.params, params) &&
      other.priority == priority &&
      const ListEquality<KoachAction>().equals(other.actions, actions) &&
      other.whyKey == whyKey &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(
    event,
    pose,
    messageKey,
    const MapEquality<String, String>().hash(params),
    priority,
    const ListEquality<KoachAction>().hash(actions),
    whyKey,
    reason,
  );

  @override
  String toString() => 'KoachLine(${event.name}, ${pose.id}, $messageKey)';
}

/// Échelle des priorités.
abstract final class KoachPriority {
  /// Sécurité de l'utilisateur (douleur signalée).
  static const int safety = 100;

  /// Réponse à une question de l'utilisateur (« Pourquoi ? »).
  static const int answer = 95;

  /// Erreur.
  static const int error = 90;

  /// Changement de session (test / personnelle).
  static const int session = 85;

  /// Bilan santé.
  static const int health = 80;

  /// Changement appliqué par le moteur.
  static const int applied = 75;

  /// Proposition ou demande qui attend une réponse.
  static const int decision = 70;

  /// Record.
  static const int record = 65;

  /// Fin de séance, annulation.
  static const int feedback = 60;

  /// Étapes du programme et de la revue.
  static const int program = 50;

  /// Confirmations courtes.
  static const int confirm = 40;

  /// Nouveautés.
  static const int discovery = 30;

  /// Accueil et parcours du profil.
  static const int onboarding = 20;
}
