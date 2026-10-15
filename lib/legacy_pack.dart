// Entrées d'une instance « generated » L10 (moteur retiré par G7), restée
// lisible et affichée telle quelle : lecture stricte des entrées
// (`GenInputs`). BV11 (dev6.19.0) : le pack 2.0.0 est retiré de
// l'application ; ses vocabulaires (matériel, familles, zones) ne sont plus
// utilisés. Les identifiants d'exercices aimés ou évités d'une ancienne
// instance (`disliked`, `liked`) restent tels quels (lus, jamais résolus).
import 'dart:convert';

// ------------------------------------------------------------------ outils

List<String> _strings(Object? v) => [for (final x in (v as List? ?? [])) '$x'];

String civilIsoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime? parseCivil(Object? v) {
  if (v is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) return null;
  final d = DateTime.tryParse(v);
  return d == null ? null : DateTime(d.year, d.month, d.day);
}

int civilDayIndex(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;

// ---------------------------------------------------------- vocabulaires

/// Lieux du profil (L8) acceptés par les entrées d'une instance L10 (BV11 :
/// seul vocabulaire de l'ancien pack encore lu, pour la lecture stricte).
const kPlaceToPack = {
  'home_none': 'maison_sans_materiel',
  'home_equipped': 'maison_equipee',
  'park': 'parc_street_workout',
  'gym': 'salle',
};

// ----------------------------------------------------------------- entrées

/// Entrées du générateur : instantané figé dans l'instance (KT-050).
class GenInputs {
  /// S1·J1 (date civile).
  final DateTime start;
  final String goalPrimary;
  final String? goalSecondary;
  final int goalWeight; // part du principal (50-100)
  final DateTime? eventDate;
  final List<String> eventItems;
  final List<int> weekdays; // 1 = lundi … 7 = dimanche
  final int sessionMinutes;
  final Map<int, String> dayPlace; // jour → lieu
  final Map<String, List<String>> places; // lieu → matériel
  final List<String> disliked, liked;

  /// Gênes > 0 par articulation du pack (niveau 0-10), seulement avec
  /// consentement (L8).
  final Map<String, int> pains;
  final bool caution;
  final String autonomy;

  /// Mesures (KT-051) : `pushups`, `pullups`, `squatRatio`, `pullLoadPct`,
  /// `dipLoadPct`, `hingeReps`, `plankSeconds` ; provenance dans
  /// [measureSources] (`measured`, `estimated`, `calibrated`).
  final Map<String, double> measures;
  final Map<String, String> measureSources;

  /// Références de Pilotage connues (B4, B8-B11, B16-B20…).
  final Map<String, double> references;

  /// `auto`, `fullbody`, `upper_lower`, `ppl`.
  final String split;

  /// Mouvement ciblé par l'objectif d'endurance : `pullups`, `pushups`,
  /// `dips`, `squats`.
  final String focus;

  /// Points d'entrée atteints (chaîne → étape), tirés du calibrage et du
  /// journal.
  final Map<String, String> entries;

  /// Ajustement de volume par groupe (±2 par cycle, KT-055).
  final Map<String, int> volumeAdjust;

  /// Tests légers de calibrage au premier cycle.
  final bool calibration;

  const GenInputs({
    required this.start,
    this.goalPrimary = 'health',
    this.goalSecondary,
    this.goalWeight = 70,
    this.eventDate,
    this.eventItems = const [],
    this.weekdays = const [1, 3, 5],
    this.sessionMinutes = 45,
    this.dayPlace = const {},
    this.places = const {'home_none': []},
    this.disliked = const [],
    this.liked = const [],
    this.pains = const {},
    this.caution = false,
    this.autonomy = 'guided',
    this.measures = const {},
    this.measureSources = const {},
    this.references = const {},
    this.split = 'auto',
    this.focus = '',
    this.entries = const {},
    this.volumeAdjust = const {},
    this.calibration = true,
  });

  GenInputs copyWith({
    DateTime? start,
    Map<String, String>? entries,
    Map<String, int>? volumeAdjust,
    Map<String, double>? measures,
    Map<String, String>? measureSources,
    bool? calibration,
    String? split,
    String? focus,
  }) => GenInputs(
    start: start ?? this.start,
    goalPrimary: goalPrimary,
    goalSecondary: goalSecondary,
    goalWeight: goalWeight,
    eventDate: eventDate,
    eventItems: eventItems,
    weekdays: weekdays,
    sessionMinutes: sessionMinutes,
    dayPlace: dayPlace,
    places: places,
    disliked: disliked,
    liked: liked,
    pains: pains,
    caution: caution,
    autonomy: autonomy,
    measures: measures ?? this.measures,
    measureSources: measureSources ?? this.measureSources,
    references: references,
    split: split ?? this.split,
    focus: focus ?? this.focus,
    entries: entries ?? this.entries,
    volumeAdjust: volumeAdjust ?? this.volumeAdjust,
    calibration: calibration ?? this.calibration,
  );

  Map<String, dynamic> toJson() => {
    'start': civilIsoDate(start),
    'goalPrimary': goalPrimary,
    if (goalSecondary != null) 'goalSecondary': goalSecondary,
    'goalWeight': goalWeight,
    if (eventDate != null) 'eventDate': civilIsoDate(eventDate!),
    'eventItems': eventItems,
    'weekdays': weekdays,
    'sessionMinutes': sessionMinutes,
    'dayPlace': {for (final e in dayPlace.entries) '${e.key}': e.value},
    'places': places,
    'disliked': disliked,
    'liked': liked,
    'pains': pains,
    'caution': caution,
    'autonomy': autonomy,
    'measures': measures,
    'measureSources': measureSources,
    'references': references,
    'split': split,
    'focus': focus,
    'entries': entries,
    'volumeAdjust': volumeAdjust,
    'calibration': calibration,
  };

  /// Lecture stricte : toute valeur hors contrat lève [FormatException].
  factory GenInputs.fromJson(Map<String, dynamic> j) {
    T need<T>(String k) {
      final v = j[k];
      if (v is! T) throw FormatException('Entrée du générateur invalide : $k');
      return v;
    }

    Map<String, V> map<V>(String k, V Function(Object?) f) {
      final m = j[k];
      if (m == null) return {};
      if (m is! Map) throw FormatException('Entrée du générateur : $k');
      return {for (final e in m.entries) '${e.key}': f(e.value)};
    }

    final start = parseCivil(j['start']);
    if (start == null) throw const FormatException('Départ invalide.');
    final weekdays = [for (final d in need<List>('weekdays')) d as int];
    if (weekdays.isEmpty || weekdays.any((d) => d < 1 || d > 7)) {
      throw const FormatException('Jours invalides.');
    }
    final minutes = need<int>('sessionMinutes');
    if (minutes < 10 || minutes > 240) {
      throw const FormatException('Durée invalide.');
    }
    final places = <String, List<String>>{
      for (final e in map<List<String>>('places', _strings).entries)
        e.key: e.value,
    };
    if (places.isEmpty ||
        places.keys.any((p) => !kPlaceToPack.containsKey(p))) {
      throw const FormatException('Lieux invalides.');
    }
    return GenInputs(
      start: start,
      goalPrimary: need<String>('goalPrimary'),
      goalSecondary: j['goalSecondary'] as String?,
      goalWeight: (j['goalWeight'] as int?) ?? 70,
      eventDate: parseCivil(j['eventDate']),
      eventItems: _strings(j['eventItems']),
      weekdays: weekdays,
      sessionMinutes: minutes,
      dayPlace: {
        for (final e in map<String>('dayPlace', (v) => v as String).entries)
          int.parse(e.key): e.value,
      },
      places: places,
      disliked: _strings(j['disliked']),
      liked: _strings(j['liked']),
      pains: map<int>('pains', (v) => v as int),
      caution: j['caution'] == true,
      autonomy: j['autonomy'] as String? ?? 'guided',
      measures: map<double>('measures', (v) => (v as num).toDouble()),
      measureSources: map<String>('measureSources', (v) => v as String),
      references: map<double>('references', (v) => (v as num).toDouble()),
      split: j['split'] as String? ?? 'auto',
      focus: j['focus'] as String? ?? '',
      entries: map<String>('entries', (v) => v as String),
      volumeAdjust: map<int>('volumeAdjust', (v) => v as int),
      calibration: j['calibration'] != false,
    );
  }

  /// Empreinte des entrées qui déclenchent une proposition de régénération
  /// (KT-057) : objectifs, lieux, matériel, disponibilités, gênes, prudence.
  String get profileKey => jsonEncode({
    'g': [goalPrimary, goalSecondary, goalWeight],
    'e': [if (eventDate != null) civilIsoDate(eventDate!), ...eventItems],
    'd': weekdays,
    'm': sessionMinutes,
    'dp': {for (final e in dayPlace.entries) '${e.key}': e.value},
    'p': places,
    'x': disliked,
    'l': liked,
    'pain': pains,
    'c': caution,
    's': split,
    'f': focus,
  });
}
