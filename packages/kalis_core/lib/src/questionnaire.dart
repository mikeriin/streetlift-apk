/// Parcours de questions du profil d'athlète (0.4.0) : arbre de questions
/// adaptatif, tests guidés et préréglages de règlement, lus depuis
/// `data/parcours_v3.json` (généré par `tool/gen_parcours.py`).
///
/// L'application ne code aucune condition d'apparition : après chaque
/// réponse, elle demande à [ProfileQuestionnaire.visibleQuestions] les
/// questions à montrer pour le profil en cours de saisie. Les conditions
/// s'évaluent sur le JSON du profil (`AthleteProfile.toJson()`, ou un
/// brouillon incomplet) ; une valeur absente rend une condition fausse :
/// sans réponse, le parcours le plus court est montré.
///
/// Dart pur : « aujourd'hui » (l'année) est passé en paramètre.
library;

import 'json_util.dart';

/// Réponse possible d'une question à choix.
final class QuestionOption {
  /// Réponse de code [code], affichée [label].
  const QuestionOption(this.code, this.label, this.hint);

  /// Code écrit dans le profil (code d'enum du contrat).
  final String code;

  /// Texte affiché.
  final String label;

  /// Précision affichée sous le texte, ou `null`.
  final String? hint;
}

/// Question du parcours.
final class ProfileQuestion {
  ProfileQuestion._(this.json)
    : id = jsonString(json, 'id'),
      screen = jsonString(json, 'screen'),
      since = jsonInt(json, 'since'),
      kind = jsonString(json, 'kind'),
      text = jsonString(json, 'text'),
      fields = jsonList(json, 'fields', (v) => jsonAsString(v, 'fields')),
      required = jsonBool(json, 'required'),
      skip = jsonBool(json, 'skip'),
      unknown = jsonBool(json, 'unknown'),
      when = jsonObject(json, 'when'),
      options =
          jsonListOrNull(json, 'options', (v) {
            final o = jsonAsObject(v, 'options');
            return QuestionOption(
              jsonString(o, 'code'),
              jsonString(o, 'label'),
              jsonStringOrNull(o, 'hint'),
            );
          }) ??
          const <QuestionOption>[];

  /// Objet JSON complet de la question (textes de Koach, champs d'un
  /// élément de liste, notes d'implémentation, validations).
  final Map<String, Object?> json;

  /// Identifiant stable.
  final String id;

  /// Écran qui porte la question.
  final String screen;

  /// Schéma du profil qui a introduit la question (2 ou 3).
  final int since;

  /// Forme : `choice`, `multi`, `number`, `text`, `date`, `group` (éditeur
  /// de liste) ou `composite` (choix multiples + éditeur).
  final String kind;

  /// Texte de la question.
  final String text;

  /// Champs du profil que la question écrit (chemins dans le JSON).
  final List<String> fields;

  /// Réponse obligatoire.
  final bool required;

  /// « Passer » est proposé : le champ reste absent.
  final bool skip;

  /// « Je ne sais pas » est proposé : le champ reste absent et un test
  /// guidé sera proposé.
  final bool unknown;

  /// Condition d'apparition.
  final Map<String, Object?> when;

  /// Réponses possibles (vide pour les autres formes).
  final List<QuestionOption> options;
}

/// Protocole de test guidé.
final class GuidedTest {
  GuidedTest._(this.json)
    : id = jsonString(json, 'id'),
      title = jsonString(json, 'title'),
      stage = jsonString(json, 'stage'),
      benchmarkKind = jsonStringOrNull(json, 'benchmarkKind'),
      testKind = jsonStringOrNull(json, 'testKind'),
      eligible = jsonObject(json, 'eligible');

  /// Objet JSON complet (pour qui, sécurité, déroulé, arrêt, conversion,
  /// incertitude, références).
  final Map<String, Object?> json;

  /// Identifiant stable (`Benchmark.protocolId`, `TestSpec.protocolId`).
  final String id;

  /// Titre.
  final String title;

  /// Moment : `creation` (déclaratif), `first_session`, `later`.
  final String stage;

  /// Code de `BenchmarkKind` de la valeur produite, ou `null` (aucun test).
  final String? benchmarkKind;

  /// Code de `TestKind` de la série de test, ou `null` (aucun test).
  final String? testKind;

  /// Condition pour proposer le test.
  final Map<String, Object?> eligible;
}

/// Parcours de questions du profil d'athlète.
final class ProfileQuestionnaire {
  ProfileQuestionnaire._(
    this.version,
    this.scales,
    this.screens,
    this.questions,
    this.tests,
    this.rulesetPresets,
  );

  /// Lit `data/parcours_v3.json` (objet JSON déjà décodé). [FormatException]
  /// si un champ manque, a un type inattendu, si le schéma n'est pas pris en
  /// charge ou si une condition est mal formée.
  factory ProfileQuestionnaire.fromJson(Map<String, Object?> json) {
    final schema = jsonInt(json, 'schema');
    if (schema != supportedSchemaVersion) {
      throw FormatException('Parcours : schéma $schema non pris en charge');
    }
    final scalesJson = jsonObject(json, 'scales');
    final scales = <String, List<String>>{
      for (final key in scalesJson.keys)
        key: jsonList(scalesJson, key, (v) => jsonAsString(v, key)),
    };
    final questions = jsonList(
      json,
      'questions',
      (v) => ProfileQuestion._(jsonAsObject(v, 'questions')),
    );
    final tests = jsonList(
      json,
      'tests',
      (v) => GuidedTest._(jsonAsObject(v, 'tests')),
    );
    for (final q in questions) {
      _checkCondition(q.when, scales);
    }
    for (final t in tests) {
      _checkCondition(t.eligible, scales);
    }
    final ids = <String>{};
    for (final q in questions) {
      if (!ids.add(q.id)) {
        throw FormatException('Parcours : question en double', q.id);
      }
    }
    return ProfileQuestionnaire._(
      jsonString(json, 'version'),
      scales,
      jsonList(json, 'screens', (v) => jsonAsObject(v, 'screens')),
      questions,
      tests,
      jsonList(json, 'rulesetPresets', (v) => jsonAsObject(v, 'rulesetPresets')),
    );
  }

  /// Schéma du fichier pris en charge.
  static const int supportedSchemaVersion = 1;

  /// Version de `kalis_core` qui a produit le fichier.
  final String version;

  /// Échelles ordonnées utilisées par les conditions (`experience`,
  /// `trainingAge`).
  final Map<String, List<String>> scales;

  /// Écrans, dans l'ordre (`id`, `title`, `koach`, `since`, `note`).
  final List<Map<String, Object?>> screens;

  /// Toutes les questions, dans l'ordre du parcours.
  final List<ProfileQuestion> questions;

  /// Protocoles de tests guidés.
  final List<GuidedTest> tests;

  /// Préréglages de règlement de l'éditeur d'échéance.
  final List<Map<String, Object?>> rulesetPresets;

  /// Question d'identifiant [id], ou `null`.
  ProfileQuestion? question(String id) {
    for (final q in questions) {
      if (q.id == id) {
        return q;
      }
    }
    return null;
  }

  /// Questions à montrer pour le profil [profile] (JSON du profil ou d'un
  /// brouillon), dans l'ordre du parcours.
  ///
  /// [todayYear] : année du jour, fournie par l'application. [since] : 2
  /// pour tout le parcours, 3 pour les seules questions du schéma 3
  /// (« Compléter mon profil » d'un utilisateur existant).
  List<ProfileQuestion> visibleQuestions(
    Map<String, Object?> profile, {
    required int todayYear,
    int since = 2,
  }) {
    return <ProfileQuestion>[
      for (final q in questions)
        if (q.since >= since && evaluate(q.when, profile, todayYear: todayYear))
          q,
    ];
  }

  /// Tests guidés permis pour le profil [profile].
  List<GuidedTest> eligibleTests(
    Map<String, Object?> profile, {
    required int todayYear,
  }) {
    return <GuidedTest>[
      for (final t in tests)
        if (evaluate(t.eligible, profile, todayYear: todayYear)) t,
    ];
  }

  /// Évalue la condition [condition] sur le profil [profile].
  bool evaluate(
    Map<String, Object?> condition,
    Map<String, Object?> profile, {
    required int todayYear,
  }) {
    final op = jsonString(condition, 'op');
    switch (op) {
      case 'always':
        return true;
      case 'all':
        for (final c in _children(condition)) {
          if (!evaluate(c, profile, todayYear: todayYear)) {
            return false;
          }
        }
        return true;
      case 'any':
        for (final c in _children(condition)) {
          if (evaluate(c, profile, todayYear: todayYear)) {
            return true;
          }
        }
        return false;
      case 'not':
        return !evaluate(
          jsonObject(condition, 'of'),
          profile,
          todayYear: todayYear,
        );
      case 'present':
        return _valuesAt(profile, jsonString(condition, 'path')).isNotEmpty;
      case 'in':
        final values = jsonList(condition, 'values', (v) => v);
        for (final v in _valuesAt(profile, jsonString(condition, 'path'))) {
          if (values.contains(v)) {
            return true;
          }
        }
        return false;
      case 'at_least':
        final scale = scales[jsonString(condition, 'scale')]!;
        final rank = scale.indexOf(jsonString(condition, 'value'));
        for (final v in _valuesAt(profile, jsonString(condition, 'path'))) {
          if (v is String && scale.contains(v) && scale.indexOf(v) >= rank) {
            return true;
          }
        }
        return false;
      case 'min_number':
        final minimum = jsonDouble(condition, 'value');
        for (final v in _valuesAt(profile, jsonString(condition, 'path'))) {
          if (v is num && v >= minimum) {
            return true;
          }
        }
        return false;
      case 'age_at_least':
        final birthYear = profile['birthYear'];
        return birthYear is int &&
            todayYear - birthYear >= jsonInt(condition, 'value');
      default:
        throw FormatException('Parcours : opération inconnue', op);
    }
  }

  static List<Map<String, Object?>> _children(Map<String, Object?> condition) {
    return jsonList(condition, 'of', (v) => jsonAsObject(v, 'of'));
  }

  /// Valeurs non nulles au bout de [path] : clés séparées par des points ;
  /// `cle[*]` parcourt une liste.
  static List<Object> _valuesAt(Map<String, Object?> profile, String path) {
    var current = <Object>[profile];
    for (final part in path.split('.')) {
      final star = part.endsWith('[*]');
      final key = star ? part.substring(0, part.length - 3) : part;
      final next = <Object>[];
      for (final c in current) {
        if (c is! Map<String, Object?>) {
          continue;
        }
        final v = c[key];
        if (v == null) {
          continue;
        }
        if (star) {
          if (v is List<Object?>) {
            for (final item in v) {
              if (item != null) {
                next.add(item);
              }
            }
          }
        } else {
          next.add(v);
        }
      }
      current = next;
    }
    return current;
  }

  static void _checkCondition(
    Map<String, Object?> condition,
    Map<String, List<String>> scales,
  ) {
    final op = jsonString(condition, 'op');
    switch (op) {
      case 'always':
        return;
      case 'all':
      case 'any':
        for (final c in _children(condition)) {
          _checkCondition(c, scales);
        }
      case 'not':
        _checkCondition(jsonObject(condition, 'of'), scales);
      case 'present':
        jsonString(condition, 'path');
      case 'in':
        jsonString(condition, 'path');
        jsonList(condition, 'values', (v) => v);
      case 'at_least':
        jsonString(condition, 'path');
        final scale = scales[jsonString(condition, 'scale')];
        if (scale == null || !scale.contains(jsonString(condition, 'value'))) {
          throw FormatException('Parcours : échelle ou valeur inconnue', op);
        }
      case 'min_number':
        jsonString(condition, 'path');
        jsonDouble(condition, 'value');
      case 'age_at_least':
        jsonInt(condition, 'value');
      default:
        throw FormatException('Parcours : opération inconnue', op);
    }
  }
}
