// Ancien pack d'exercices 2.0.0 vu par les moteurs L10 et L11 (données
// gardées jusqu'au retrait de L11 en G10, D1.4) : catalogue du pack
// (`GenCatalog`), matériel par lieu, et lecture stricte des entrées d'une
// instance « generated » L10 (`GenInputs`), restée lisible et affichée
// telle quelle après le retrait du générateur L10 par G7.
//
// Le générateur L10 (`program_generator.dart`, `assets/program_models.json`)
// est retiré par G7 : `kalis_plan` le remplace.
import 'dart:convert';

import 'atlas_data.dart' show atlasMuscles;

// ------------------------------------------------------------------ outils

/// Hachage FNV-1a 32 bits : départage déterministe, indépendant de l'ordre
/// des appels (une sélection ne décale pas les suivantes).
int genHash(String s) {
  var h = 0x811C9DC5;
  for (final c in utf8.encode(s)) {
    h ^= c;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}

List<String> _strings(Object? v) => [for (final x in (v as List? ?? [])) '$x'];

/// Médiane basse (prudence : entre deux niveaux, le plus bas).
int lowerMedian(List<int> values) {
  if (values.isEmpty) return 0;
  final s = [...values]..sort();
  return s[(s.length - 1) ~/ 2];
}

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

/// Mouvements de référence du niveau (KT-051).
const kRefMovements = ['push', 'pull', 'squat', 'hinge', 'core'];
const kRefMovementLabels = {
  'push': 'Poussée',
  'pull': 'Tirage',
  'squat': 'Squat',
  'hinge': 'Charnière de hanche',
  'core': 'Gainage',
};

/// Familles de mouvement (règle des 48 h, couverture hebdomadaire).
const kFamilies = [
  'push',
  'pull',
  'squat',
  'hinge',
  'lunge',
  'core',
  'mobility',
];
const kFamilyLabels = {
  'push': 'poussée',
  'pull': 'tirage',
  'squat': 'squat',
  'hinge': 'charnière de hanche',
  'lunge': 'fente',
  'core': 'gainage',
  'mobility': 'mobilité',
};

/// Famille d'un type de mouvement du pack (null : sans famille).
String? familyOfType(String type) => switch (type) {
  'poussee_horizontale' || 'poussee_verticale' => 'push',
  'tirage_horizontal' || 'tirage_vertical' => 'pull',
  'squat' => 'squat',
  'fente' => 'lunge',
  'charniere_hanche' => 'hinge',
  'gainage_anti_extension' ||
  'gainage_anti_rotation' ||
  'gainage_anti_flexion_laterale' ||
  'flexion_tronc' => 'core',
  'mobilite' => 'mobility',
  _ => null,
};

/// Mouvement de référence (niveau) d'un exercice.
String refMovementOf(String type, List<String> groups) {
  switch (familyOfType(type)) {
    case 'push':
      return 'push';
    case 'pull':
      return 'pull';
    case 'squat' || 'lunge':
      return 'squat';
    case 'hinge':
      return 'hinge';
    case 'core':
      return 'core';
  }
  final g = groups.isEmpty ? '' : groups.first;
  return switch (g) {
    'pectoraux' || 'épaules' || 'triceps' => 'push',
    'dos' || 'biceps' || 'avant-bras' => 'pull',
    'quadriceps' || 'mollets' => 'squat',
    'ischios' || 'fessiers' => 'hinge',
    'gainage' => 'core',
    _ => 'core',
  };
}

/// Lieux du profil (L8) → lieux du pack (L9).
const kPlaceToPack = {
  'home_none': 'maison_sans_materiel',
  'home_equipped': 'maison_equipee',
  'park': 'parc_street_workout',
  'gym': 'salle',
};

/// Matériel normalisé du profil (L8) → vocabulaire `materiel` du pack.
const kEquipmentToPack = <String, List<String>>{
  'pullup_bar': ['barre_fixe', 'poteau'],
  'dip_bars': ['barres_paralleles'],
  'rings': ['anneaux', 'sangles'],
  'bands': ['elastique'],
  'dumbbells': ['halteres'],
  'kettlebell': ['kettlebell'],
  'barbell': ['barre', 'disques'],
  'rack': ['rack'],
  'bench': ['banc'],
  'weight_belt': ['lest'],
  'machines': ['machine', 'poulie'],
  'box': ['box'],
  'jump_rope': ['corde_a_sauter'],
  'erg': ['ergometre'],
  'mat': ['sol_degage'],
};

/// Toujours disponibles : le corps, le sol, un mur, un support stable
/// (chaise, marche, banc public).
const kAlwaysPack = ['aucun', 'mur', 'support_stable', 'sol_degage'];

/// Matériel déduit du lieu (à valider, registre §8).
const kPlaceImpliedPack = <String, List<String>>{
  'home_none': ['serviette', 'baton'],
  'home_equipped': ['serviette', 'baton'],
  'park': ['barre_basse', 'espace_exterieur'],
  'gym': ['serviette'],
};

/// Zones de gêne du profil → articulations du pack.
const kZoneToJoint = {
  'shoulder': 'epaule',
  'elbow': 'coude',
  'wrist': 'poignet',
  'lower_back': 'rachis_lombaire',
  'neck': 'rachis_cervical',
  'hip': 'hanche',
  'knee': 'genou',
  'ankle': 'cheville',
};

/// Matériel pack disponible dans un lieu.
Set<String> packEquipment(String place, List<String> equipment) {
  final out = <String>{...kAlwaysPack, ...?kPlaceImpliedPack[place]};
  for (final e in equipment) {
    out.addAll(kEquipmentToPack[e] ?? const []);
  }
  if (place == 'gym' && equipment.contains('rack')) out.add('barre_basse');
  return out;
}

final RegExp _impactRe = RegExp(
  r'saut|sauté|jump|pliom|explosi|clap|burpee|sprint|bondiss|pogo|skater|navette|shuttle|kipping|double-under',
);

// ---------------------------------------------------------------- données

/// Exercice du pack vu par le générateur.
class GenExercise {
  final String id, name, nom, type, loadMode, measure, demo, role;
  final int difficulty;
  final List<String> materiel, lieux, groups, allGroups, prereq, points;
  final List<String> alias;
  final Map<String, int> joints;
  final bool unilateral, generator;
  final String? duplicateOf;
  GenExercise({
    required this.id,
    required this.name,
    required this.nom,
    required this.type,
    required this.loadMode,
    required this.measure,
    required this.demo,
    required this.role,
    required this.difficulty,
    required this.materiel,
    required this.lieux,
    required this.groups,
    required this.allGroups,
    required this.prereq,
    required this.points,
    required this.alias,
    required this.joints,
    required this.unilateral,
    required this.generator,
    required this.duplicateOf,
  });

  /// Démonstration animée disponible (KT-054 : exigée pour tout exercice
  /// retenu).
  bool get animated => demo == 'disponible';

  /// Exercice utilisable par le générateur.
  bool get usable =>
      generator && duplicateOf == null && animated && role == 'exercice';

  bool get loaded =>
      loadMode != 'poids_de_corps' &&
      loadMode != 'assistance' &&
      loadMode != 'elastique';

  /// Saut, impact ou élan (exclus en mode prudent), calculé une fois.
  late final bool impact = _impactRe.hasMatch('$id ${name.toLowerCase()}');
  late final String? family = familyOfType(type);
  late final String refMovement = refMovementOf(type, groups);
}

/// Catalogue du pack pour le générateur (index + fiches + arbres).
class GenCatalog {
  final List<GenExercise> all; // trié par identifiant
  final Map<String, GenExercise> byId;
  final Map<String, List<String>> chains; // chaîne → étapes
  final Map<String, String> chainTitles;

  /// Seuil de passage d'une étape (première chaîne qui la décrit).
  final Map<String, Map<String, dynamic>> thresholds;
  final Map<String, String> _names; // nom normalisé → id

  GenCatalog._(this.all, this.chains, this.chainTitles, this.thresholds)
    : byId = {for (final e in all) e.id: e},
      _names = {
        for (final e in all) ...{
          for (final a in e.alias) _norm(a): e.id,
          _norm(e.nom): e.id,
          _norm(e.name): e.id,
        },
      };

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[àâä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[îï]'), 'i')
      .replaceAll(RegExp('[ôö]'), 'o')
      .replaceAll(RegExp('[ùûü]'), 'u')
      .replaceAll('ç', 'c')
      .replaceAll('œ', 'oe')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();

  /// [index] : `assets/content/index.json.gz` décodé ; [details] :
  /// `details.json.gz` ; [progressions] : `progressions.json.gz`.
  factory GenCatalog.fromContent({
    required Map<String, dynamic> index,
    required Map<String, dynamic> details,
    required Map<String, dynamic> progressions,
  }) {
    final names = <String, Map<String, dynamic>>{
      for (final e in index['exercices'] as List)
        (e as Map)['id'] as String: e.cast<String, dynamic>(),
    };
    final fiches = details['exercices'] as Map<String, dynamic>;
    final ids = fiches.keys.toList()..sort();
    final list = <GenExercise>[];
    for (final id in ids) {
      final d = fiches[id] as Map<String, dynamic>;
      final n = names[id];
      final groups = <String>[];
      for (final m in _strings(d['muscles_primaires'])) {
        final g = atlasMuscles[m]?.groupe;
        if (g != null && !groups.contains(g)) groups.add(g);
      }
      final all = _strings(n?['groupes']);
      if (groups.isEmpty && all.isNotEmpty) groups.add(all.first);
      list.add(
        GenExercise(
          id: id,
          name: (n?['n'] as String?) ?? (n?['nom'] as String?) ?? id,
          nom: (n?['nom'] as String?) ?? id,
          type: d['type_mouvement'] as String? ?? '',
          loadMode: d['mode_charge'] as String? ?? 'poids_de_corps',
          measure: d['mesure'] as String? ?? 'repetitions',
          demo: ((d['pose'] as Map?)?['statut'] as String?) ?? 'indisponible',
          role: d['role'] as String? ?? 'exercice',
          difficulty: (d['difficulte'] as num?)?.toInt() ?? 1,
          materiel: _strings(d['materiel']),
          lieux: _strings(d['lieux']),
          groups: groups,
          allGroups: all,
          prereq: [
            for (final p in (d['prerequis'] as List? ?? []))
              '${(p as Map)['id']}',
          ],
          points: _strings(d['points_cles']),
          alias: _strings(n?['alias']),
          joints: {
            for (final e
                in ((d['contrainte_articulaire'] as Map?) ?? {}).entries)
              '${e.key}': (e.value as num).toInt(),
          },
          unilateral: d['unilateral'] == true,
          generator: d['generateur'] != false,
          duplicateOf: d['doublon_de'] as String?,
        ),
      );
    }
    final chains = <String, List<String>>{};
    final titles = <String, String>{};
    final thresholds = <String, Map<String, dynamic>>{};
    for (final c in progressions['chaines'] as List) {
      final m = c as Map;
      final steps = <String>[];
      for (final s in m['etapes'] as List) {
        final sm = s as Map;
        steps.add(sm['id'] as String);
        final seuil = sm['seuil_passage'];
        if (seuil is Map && !thresholds.containsKey(sm['id'])) {
          thresholds[sm['id'] as String] = seuil.cast<String, dynamic>();
        }
      }
      chains[m['id'] as String] = steps;
      titles[m['id'] as String] = m['titre'] as String? ?? m['id'] as String;
    }
    return GenCatalog._(list, chains, titles, thresholds);
  }

  /// Identifiant d'un nom saisi librement (exercices aimés ou détestés).
  String? idForName(String name) => _names[_norm(name)];

  /// Chaîne (et rang) d'un exercice ; première chaîne qui le contient.
  (String, int)? chainOf(String id, [List<String>? prefer]) {
    for (final c in prefer ?? const <String>[]) {
      final i = chains[c]?.indexOf(id) ?? -1;
      if (i >= 0) return (c, i);
    }
    for (final e in chains.entries) {
      final i = e.value.indexOf(id);
      if (i >= 0) return (e.key, i);
    }
    return null;
  }
}

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
