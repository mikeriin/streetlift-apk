// KT-009 — Validation des saisies de séries (L4b).
//
// Contrat des champs d'une série (texte saisi, jamais réécrit) :
//
// | Champ   | Sens                                   | Obligatoire à la coche | Format / domaine                                   |
// | ------- | -------------------------------------- | ---------------------- | -------------------------------------------------- |
// | valeur  | reps (reps, max, EMOM, AMRAP, interv.) | oui (décision 26/09)   | entier 0-99 999 ; 0 seulement pour un test max      |
// |         | secondes (tenue, tenue max)            | oui                    | entier ; 0 seulement pour une tenue max            |
// |         | minutes (durée)                        | oui                    | entier ≥ 1                                         |
// | kg      | lest (charge ajoutée) ou barre, en kg  | non                    | décimal, virgule ou point, 2 décimales, |v| ≤ 10 000 ; négatif = assistance |
// | effort  | RIR (répétitions en réserve)           | non                    | 0-99, pas de 0,5                                   |
// |         | RPE (réglage « RPE »)                  | non                    | 1-10, pas de 0,5                                   |
// | vitesse | m/s                                    | non                    | décimal > 0, 3 décimales au plus, < 100            |
//
// Un champ vide = valeur absente (différent de 0). Un pré-remplissage ou un
// chrono écoulé n'est qu'une suggestion : seule la coche, après validation,
// fait d'une série une performance.

import 'store.dart';

/// Champ d'une série.
enum SetField { value, kg, effort, velocity }

/// Résultat de la vérification d'une série au moment de la coche.
class SetCheck {
  final SetField? field;
  final String? message;
  const SetCheck.ok() : field = null, message = null;
  const SetCheck.error(SetField this.field, String this.message);
  bool get ok => field == null;
}

/// Blancs tolérés autour d'une valeur collée (espaces, insécables, tabulations).
String _clean(String? text) =>
    (text ?? '').replaceAll(RegExp(r'^[\s  ]+|[\s  ]+$'), '');

/// Entier positif ou nul (chiffres seulement) ; null si le texte n'en est pas un.
int? parseWholeNumber(String? text, {int maxDigits = 5}) {
  final t = _clean(text);
  if (!RegExp('^\\d{1,$maxDigits}\$').hasMatch(t)) return null;
  return int.parse(t);
}

/// Charge en kg : signe « - » facultatif (assistance), virgule ou point,
/// 2 décimales au plus. « 1.250 » (séparateur ambigu), « 72 5 », « 1e3 »,
/// « NaN » : refusés, jamais réinterprétés.
double? parseLoadKg(String? text) {
  final t = _clean(text);
  if (!RegExp(r'^[-−]?\d{1,5}(?:[.,]\d{1,2})?$').hasMatch(t)) return null;
  final v = double.parse(t.replaceAll('−', '-').replaceAll(',', '.'));
  if (!v.isFinite || v.abs() > 10000) return null;
  return v == 0 ? 0 : v; // « -0 » = 0
}

/// Effort : RIR 0-99 ou RPE 1-10, par pas de 0,5.
double? parseEffort(String? text, {required bool rpe}) {
  final t = _clean(text);
  if (!RegExp(r'^\d{1,2}(?:[.,][05])?$').hasMatch(t)) return null;
  final v = double.parse(t.replaceAll(',', '.'));
  if (rpe && (v < 1 || v > 10)) return null;
  return v;
}

/// Vitesse moyenne en m/s, strictement positive.
double? parseVelocity(String? text) {
  final t = _clean(text);
  if (!RegExp(r'^\d{1,2}(?:[.,]\d{1,3})?$').hasMatch(t)) return null;
  final v = double.parse(t.replaceAll(',', '.'));
  return v > 0 ? v : null;
}

/// Unité de la colonne « valeur » selon le mode.
String valueUnit(LogSpec spec) => switch (spec.kind) {
  'hold' || 'holdMax' => 'secondes',
  'duration' => 'minutes',
  _ => 'reps',
};

/// Un 0 n'a de sens que pour un test maximal (aucune rep, aucune seconde).
bool zeroAllowed(LogSpec spec) =>
    spec.kind == 'repsMax' || spec.kind == 'holdMax';

/// Vérifie une série avant de la valider. Les colonnes masquées ne sont pas
/// vérifiées si elles sont vides ; un texte présent l'est toujours (une
/// colonne masquée garde son contenu).
SetCheck checkSet(LogSpec spec, SetEntry e, {required bool rpe}) {
  final unit = valueUnit(spec);
  final value = _clean(e.reps);
  if (value.isEmpty) {
    return SetCheck.error(
      SetField.value,
      'Indique le nombre de $unit pour valider la série.',
    );
  }
  final n = parseWholeNumber(value);
  if (n == null) {
    return SetCheck.error(
      SetField.value,
      '${_label(unit)} : nombre entier sans unité (ex. ${_example(spec)}).',
    );
  }
  if (n == 0 && !zeroAllowed(spec)) {
    return SetCheck.error(
      SetField.value,
      '0 $unit : laisse la série non validée, ou saisis ce que tu as fait.',
    );
  }
  if (_clean(e.kg).isNotEmpty && parseLoadKg(e.kg) == null) {
    return const SetCheck.error(
      SetField.kg,
      'kg : nombre avec virgule ou point, 2 décimales au plus (ex. 72,5 ; -10 pour une assistance).',
    );
  }
  if (_clean(e.rir).isNotEmpty && parseEffort(e.rir, rpe: rpe) == null) {
    return SetCheck.error(
      SetField.effort,
      rpe
          ? 'RPE : de 1 à 10, par pas de 0,5 (ex. 8,5).'
          : 'RIR : nombre de reps en réserve, par pas de 0,5 (ex. 2).',
    );
  }
  if (_clean(e.v).isNotEmpty && parseVelocity(e.v) == null) {
    return const SetCheck.error(
      SetField.velocity,
      'Vitesse : m/s positif, 3 décimales au plus (ex. 0,45).',
    );
  }
  return const SetCheck.ok();
}

String _label(String unit) => switch (unit) {
  'secondes' => 'Secondes',
  'minutes' => 'Minutes',
  _ => 'Reps',
};

String _example(LogSpec spec) => switch (spec.kind) {
  'hold' || 'holdMax' => '30',
  'duration' => '12',
  _ => '8',
};
