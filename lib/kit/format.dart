// UI5 (refonte UI, cahier C9) : formateurs de présentation en français.
//
// Un format par grandeur : nombres à virgule (« 62,5 »), espace fine
// insécable (U+202F) entre un nombre et son unité (« 75 kg », « 22 min »),
// secondes au-delà de 90 s écrites en minutes, « au moins » plutôt que
// « ≥ ». Fonctions pures (aucun `BuildContext`) : elles ne changent que le
// texte affiché, jamais un calcul ni une donnée enregistrée (décisions
// U0.19 et U0.23).
import 'dart:math' as math;

/// Espace fine insécable (U+202F) entre un nombre et son unité (C9) : le
/// nombre et l'unité ne sont jamais séparés en fin de ligne.
const String kUnitSpace = '\u202F';

/// Nombre français : virgule décimale, [maxDecimals] décimales au plus,
/// sans zéro final ; un entier s'écrit sans décimale.
///
/// `62.5` → « 62,5 » ; `60` et `60.0` → « 60 » ; `7.25` → « 7,25 » ;
/// `59.999` → « 60 » ; `-2.5` → « -2,5 ». Une valeur non finie garde son
/// écriture Dart (« NaN », « Infinity »).
String formatDecimal(num value, {int maxDecimals = 2}) {
  if (value is int) return '$value';
  final v = value.toDouble();
  if (!v.isFinite) return '$v';
  var t = v.toStringAsFixed(math.max(0, maxDecimals));
  if (t.contains('.')) {
    t = t.replaceFirst(RegExp(r'0+$'), '');
    if (t.endsWith('.')) t = t.substring(0, t.length - 1);
  }
  if (t == '-0') t = '0';
  return t.replaceAll('.', ',');
}

/// Texte d'un nombre déjà écrit ([number]) suivi de son [unit], séparés
/// par l'espace fine insécable : `unitText('3–4', 'min')` → « 3–4 min ».
String unitText(String number, String unit) => '$number$kUnitSpace$unit';

/// Nombre et unité : `formatUnit(75, 'kg')` → « 75 kg » ;
/// `formatUnit(62.5, 'kg')` → « 62,5 kg » (espace fine insécable).
String formatUnit(num value, String unit, {int maxDecimals = 2}) =>
    unitText(formatDecimal(value, maxDecimals: maxDecimals), unit);

/// Charge en kg arrondie à l'affichage au pas [step] (aucun arrondi si
/// [step] est nul ou négatif), au format français : `formatKg(62.5)` →
/// « 62,5 kg » ; `formatKg(87.34, step: 0.5)` → « 87,5 kg ». La valeur
/// d'origine (calcul, journal) ne change pas.
String formatKg(num kg, {double step = 0}) {
  var v = kg.toDouble();
  if (step > 0 && v.isFinite) v = (v / step).round() * step;
  return formatUnit(v, 'kg');
}

/// Durée en secondes (arrondie à la seconde) : en secondes jusqu'à 90 s,
/// en minutes au-delà (C9), avec les secondes restantes quand il y en a.
///
/// `45` → « 45 s » ; `90` → « 90 s » ; `120` → « 2 min » ;
/// `150` → « 2 min 30 s » ; `600` → « 10 min ». Les heures restent en
/// minutes (« 75 min ») : les durées d'une séance se lisent en minutes.
String formatSeconds(num seconds) {
  final s = seconds.round();
  if (s <= 90) return unitText('$s', 's');
  final m = s ~/ 60, r = s % 60;
  return r == 0
      ? unitText('$m', 'min')
      : '${unitText('$m', 'min')} ${unitText('$r', 's')}';
}

/// Plage de durées en secondes : en secondes si la borne haute ne dépasse
/// pas 90 s (« 30–45 s »), sinon en minutes entières, borne basse arrondie
/// en dessous et borne haute au-dessus (« 9–11 min »). Bornes égales : une
/// seule durée ([formatSeconds]).
String formatSecondsRange(num low, num high) {
  final lo = math.min(low, high).round(), hi = math.max(low, high).round();
  if (lo == hi) return formatSeconds(lo);
  if (hi <= 90) return unitText('$lo–$hi', 's');
  final a = math.max(1, (lo / 60).floor()), b = math.max(1, (hi / 60).ceil());
  return a == b ? unitText('$a', 'min') : unitText('$a–$b', 'min');
}

final _atLeast = RegExp('≥\\s*');

/// « ≥ 38 min » → « au moins 38 min » (C9) ; le reste du texte est gardé.
String atLeastText(String text) => text.replaceAll(_atLeast, 'au moins ');

// Unités séparées de leur nombre par l'espace fine insécable. L'unité est
// suivie d'une fin de texte, d'un blanc ou d'une ponctuation (« 3 séries »
// n'est pas « 3 s »).
final _unitAfterNumber = RegExp(
  '(\\d)[ \u00A0](min|km|kg|cm|cal|reps|rep|rép\\.|lb|h|m|s|%)'
  '(?=\$|[\\s,.;:·)×…])',
);

/// Texte dont les unités suivent leur nombre après une espace (normale ou
/// insécable) : l'espace devient l'espace fine insécable (« 40 à 60 kg »,
/// « 30 s à 1 min »). Le reste du texte est gardé.
String unitSpacesText(String text) =>
    text.replaceAllMapped(_unitAfterNumber, (m) => '${m[1]}$kUnitSpace${m[2]}');

final _decimalPoint = RegExp(r'(\d)\.(\d)');

/// Texte qui contient des nombres (produit par un calcul ou le journal) au
/// format français : virgule décimale (« 12.5 » → « 12,5 ») et espace fine
/// insécable entre un nombre et son unité ([unitSpacesText]).
String frenchNumbersText(String text) => unitSpacesText(
  text.replaceAllMapped(_decimalPoint, (m) => '${m[1]},${m[2]}'),
);

final _seconds = RegExp(
  '(\\d+)(?:\\s*–\\s*(\\d+))?[ \u00A0\u202F]s(?=\$|[\\s,.;:·)])',
);

/// Libellé d'estimation (durée ou volume de `training_estimate.dart`) au
/// format C9, à l'affichage seulement : « ≥ 38 min » → « au moins 38 min » ;
/// « 600 s d’effort » → « 10 min d’effort » (secondes au-delà de 90 s en
/// minutes, [formatSeconds] et [formatSecondsRange]) ; espace fine
/// insécable avant chaque unité (« 34–49 min », « 136 rép. »).
String estimateLabelText(String label) {
  final t = atLeastText(label).replaceAllMapped(_seconds, (m) {
    final lo = int.parse(m[1]!);
    final hi = m[2] == null ? null : int.parse(m[2]!);
    return hi == null ? formatSeconds(lo) : formatSecondsRange(lo, hi);
  });
  return frenchNumbersText(t);
}

final _decimalInput = RegExp(r'^[-−]?\d+(?:[.,]\d+)?$');

/// Saisie d'un nombre décimal (charge…) : virgule ou point (« 62,5 » et
/// « 62.5 » → 62.5), signe « - » ou « − » facultatif, blancs autour
/// ignorés. Vide ou illisible (« 62, », « 1e3 », « 72 5 ») : null.
double? parseDecimalInput(String? text) {
  final t = (text ?? '').trim();
  if (!_decimalInput.hasMatch(t)) return null;
  final v = double.tryParse(t.replaceAll('−', '-').replaceAll(',', '.'));
  return v == null || !v.isFinite ? null : v;
}

/// Texte d'un champ décimal tel qu'il est montré : le texte enregistré
/// (point décimal, « 62.5 ») avec la virgule (« 62,5 »). Même longueur :
/// appliqué à chaque frappe, il garde le curseur et la sélection.
String decimalFieldText(String stored) => stored.replaceAll('.', ',');

/// Texte d'un champ décimal tel qu'il est enregistré : la saisie (« 62,5 »)
/// avec le point décimal (« 62.5 »), comme le pré-remplissage et le
/// journal l'ont toujours écrit. Même valeur lue par le journal.
String decimalStoredText(String typed) => typed.replaceAll(',', '.');

/// Texte de contenu (consignes du programme, données) affiché avec les noms
/// de pages de l'application (cahier R9, UI5) : « la feuille Pilotage »,
/// libellé interne des anciennes consignes, devient « Mes références ». Les
/// données ne changent pas.
String contentText(String text) => text
    .replaceAll('de la feuille Pilotage', 'de Mes références')
    .replaceAll('la feuille Pilotage', 'Mes références')
    .replaceAll('feuille Pilotage', 'Mes références');
