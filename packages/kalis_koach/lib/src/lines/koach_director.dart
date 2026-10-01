import '../koach_pose.dart';
import 'koach_event.dart';
import 'koach_messages_fr.dart';
import 'koach_rules.dart';

/// Choisit la réplique de Koach pour un événement, de façon déterministe :
/// deux demandes identiques donnent la même réplique ; deux occurrences
/// successives d'un même événement ne répètent pas la même variante quand
/// il y en a plusieurs. Aucune horloge, aucun hasard.
class KoachDirector {
  /// Crée un directeur ; [reasons] relie les codes de raison des moteurs aux
  /// messages (table de base par défaut).
  KoachDirector({KoachReasonTable? reasons, List<KoachRule>? rules})
      : reasons = reasons ?? KoachReasonTable.base(),
        _rules = {for (final r in rules ?? koachRules) r.event: r};

  /// Table des raisons.
  final KoachReasonTable reasons;

  final Map<KoachEvent, KoachRule> _rules;

  /// Règle de l'événement (toutes sauf [KoachEvent.why]).
  KoachRule? ruleFor(KoachEvent event) => _rules[event];

  /// Réplique pour [cue]. Lève [ArgumentError] si un paramètre obligatoire
  /// manque ou si l'événement est [KoachEvent.why] (voir [explain]).
  KoachLine lineFor(KoachCue cue) {
    if (cue.occurrence < 0 || cue.seed < 0) {
      throw ArgumentError('occurrence et seed doivent être positifs');
    }
    final rule = _rules[cue.event];
    if (rule == null) {
      throw ArgumentError.value(cue.event, 'event',
          'pas de règle (utiliser explain pour KoachEvent.why)');
    }
    var messageKeys = rule.messageKeys;
    var poses = rule.poses;
    var required = rule.params;
    var whyKey = rule.whyKey;
    final reason = cue.reason == null ? null : reasons[cue.reason!];
    if (reason != null &&
        (cue.event == KoachEvent.proposalNew ||
            cue.event == KoachEvent.changeApplied)) {
      messageKeys = cue.event == KoachEvent.proposalNew
          ? reason.proposalKeys
          : reason.appliedKeys;
      poses = reason.poses;
      required = reason.params;
      whyKey = reason.whyKey;
    }
    for (final p in required) {
      if (!cue.params.containsKey(p)) {
        throw ArgumentError.value(cue.params, 'params',
            'paramètre « $p » manquant pour ${cue.event.name}');
      }
    }
    final k = cue.occurrence + cue.seed;
    // Pose : décalée d'un cran par rapport au message pour varier les
    // associations message-pose.
    return KoachLine(
      event: cue.event,
      pose: poses[(k + cue.seed ~/ 7) % poses.length],
      messageKey: messageKeys[k % messageKeys.length],
      params: Map<String, String>.unmodifiable(cue.params),
      priority: rule.priority,
      actions: rule.actions,
      whyKey: whyKey,
      reason: cue.reason,
    );
  }

  /// Réplique « Pourquoi ? » qui explique [line] ; `null` si [line] n'a pas
  /// d'explication.
  KoachLine? explain(KoachLine line, {int occurrence = 0}) {
    final key = line.whyKey;
    if (key == null) return null;
    return KoachLine(
      event: KoachEvent.why,
      pose: koachWhyPoses[occurrence.abs() % koachWhyPoses.length],
      messageKey: key,
      params: line.params,
      priority: KoachPriority.answer,
      actions: const [KoachActions.ok],
      whyKey: null,
      reason: line.reason,
    );
  }
}

/// Rend les messages (français) : remplace les paramètres `{nom}`.
class KoachTexts {
  /// Crée le rendu sur une bibliothèque (français par défaut).
  const KoachTexts([this.messages = koachMessagesFr]);

  /// Bibliothèque.
  final Map<String, String> messages;

  static final RegExp _placeholder = RegExp(r'\{([a-z_]+)\}');

  /// Paramètres présents dans le message [key].
  Set<String> placeholders(String key) => {
        for (final m in _placeholder.allMatches(_raw(key))) m.group(1)!,
      };

  String _raw(String key) {
    final t = messages[key];
    if (t == null) throw ArgumentError.value(key, 'key', 'message inconnu');
    return t;
  }

  /// Message [key] avec ses paramètres. Lève [ArgumentError] si la clé ou un
  /// paramètre manque.
  String render(String key, Map<String, String> params) =>
      _raw(key).replaceAllMapped(_placeholder, (m) {
        final v = params[m.group(1)!];
        if (v == null) {
          throw ArgumentError.value(
              params, 'params', 'paramètre « ${m.group(1)} » manquant ($key)');
        }
        return v;
      });

  /// Texte de la bulle.
  String bubble(KoachLine line) => render(line.messageKey, line.params);

  /// Texte de l'explication « Pourquoi ? » de [line], ou `null`.
  String? why(KoachLine line) =>
      line.whyKey == null ? null : render(line.whyKey!, line.params);

  /// Libellé d'une action.
  String action(KoachAction action) => _raw(action.labelKey);
}

/// Toutes les clés de messages référencées par les règles, la table des
/// raisons et les actions (contrôle des clés orphelines).
Set<String> koachReferencedKeys(
    {List<KoachRule> rules = koachRules,
    List<KoachReason> reasons = koachBaseReasons}) {
  final keys = <String>{};
  for (final r in rules) {
    keys.addAll(r.messageKeys);
    if (r.whyKey != null) keys.add(r.whyKey!);
    for (final a in r.actions) {
      keys.add(a.labelKey);
    }
  }
  for (final r in reasons) {
    keys
      ..addAll(r.proposalKeys)
      ..addAll(r.appliedKeys)
      ..add(r.whyKey);
  }
  keys.add(KoachActions.ok.labelKey);
  return keys;
}

/// Pose recommandée pour un usage hors réplique (par exemple un écran
/// vide), à tour de rôle selon [occurrence].
KoachPose koachPoseFor(KoachUsage usage, {int occurrence = 0}) {
  final list = KoachPose.forUsage(usage);
  if (list.isEmpty) return KoachPose.present;
  return list[occurrence.abs() % list.length];
}
