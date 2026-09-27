// Générateur de programme personnalisé (L10, KT-050 à KT-057).
//
// Fonction pure : (entrées + graine + données) → programme. Aucune horloge,
// aucun accès disque, aucun hasard non seedé : deux appels identiques
// produisent un JSON identique au caractère près. Méthode hybride (décision
// du propriétaire) : modèles de périodisation écrits en données
// (`assets/program_models.json`), choix des exercices et des volumes par
// règles. Le programme produit suit le schéma de `programme_v33.json`
// (semaines, journées, exercices) pour que tous les écrans existants le
// lisent sans changement ; les champs ajoutés (`why`, `role`, `exId`…) sont
// ignorés par les versions antérieures. Contrat : docs/CONTRAT_L10.md.
import 'dart:convert';
import 'dart:math' as math;

import 'atlas_data.dart' show atlasMuscles;
import 'models.dart';
import 'training_estimate.dart';

/// Version du générateur (écrite dans chaque instance).
const kGeneratorVersion = '1.0.0';

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

int _clampInt(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);

T? _firstOrNull<T>(Iterable<T> items) {
  for (final x in items) {
    return x;
  }
  return null;
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

/// Paramètres lus dans `assets/program_models.json`.
class GenModels {
  final Map<String, dynamic> raw;
  const GenModels(this.raw);

  factory GenModels.fromJsonString(String s) =>
      GenModels(jsonDecode(s) as Map<String, dynamic>);

  String get version => raw['version'] as String;
  Map<String, dynamic> get levels => raw['levels'] as Map<String, dynamic>;
  List<int> ints(Map<String, dynamic> m, String k) => [
    for (final v in m[k] as List) (v as num).toInt(),
  ];
  List<double> doubles(Map<String, dynamic> m, String k) => [
    for (final v in m[k] as List) (v as num).toDouble(),
  ];
  Map<String, dynamic> section(String k) => raw[k] as Map<String, dynamic>;
  Map<String, dynamic> model(String id) =>
      (raw['models'] as Map<String, dynamic>)[id] as Map<String, dynamic>;
  List<int> get startSets => ints(section('volume'), 'start');
  int get healthReduction =>
      (section('volume')['healthReduction'] as num).toInt();
  int get ceilingAbove => (section('volume')['ceilingAbove'] as num).toInt();
  int get cycleStep => (section('volume')['cycleStep'] as num).toInt();
  List<int> get setsMain => ints(section('volume'), 'setsMain');
  List<int> get setsAccessory => ints(section('volume'), 'setsAccessory');
  List<int> get mainDifficulty => ints(section('difficulty'), 'main');
  List<int> get accessoryDifficulty => ints(section('difficulty'), 'accessory');
  int restOf(String k) => (section('rest')[k] as num).toInt();
  String splitLabel(String id) =>
      ((section('splits')[id] as Map?)?['label'] as String?) ?? id;
  String modelLabel(String id) => model(id)['label'] as String;
}

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

  static String _norm(String s) =>
      s
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

// ------------------------------------------------------------ niveaux

class MovementLevels {
  final Map<String, int> levels; // mouvement → 0-4
  final Map<String, String>
  sources; // measured | estimated | calibrated | default
  final int global;
  const MovementLevels(this.levels, this.sources, this.global);

  Map<String, dynamic> toJson() => {
    'global': global,
    'movements': {
      for (final m in kRefMovements)
        m: {'level': levels[m], 'source': sources[m]},
    },
  };
}

/// Tranche d'une mesure : chaque seuil atteint fait monter d'un niveau ;
/// [strictLast] : le dernier seuil doit être dépassé (squat « > 2,0 »).
int _band(double v, List<double> cuts, {bool strictLast = false}) {
  var b = 0;
  for (var k = 0; k < cuts.length; k++) {
    final last = k == cuts.length - 1;
    if (strictLast && last ? v > cuts[k] : v >= cuts[k]) b++;
  }
  return b;
}

/// Niveau par mouvement de référence et niveau global (médiane basse des
/// mouvements mesurés). Le niveau global ne sert qu'au choix de la
/// périodisation et des valeurs par défaut (KT-051).
MovementLevels movementLevels(GenModels models, GenInputs inputs) {
  final l = models.levels;
  List<double> cuts(String k) => [
    for (final v in l[k] as List) (v as num).toDouble(),
  ];
  final m = inputs.measures;
  final levels = <String, int>{};
  final sources = <String, String>{};
  void put(String movement, String key, int level) {
    final prev = levels[movement];
    if (prev == null || level > prev) {
      levels[movement] = level;
      sources[movement] = inputs.measureSources[key] ?? 'measured';
    }
  }

  if (m['pushups'] != null) {
    put('push', 'pushups', _band(m['pushups']!, cuts('pushups')));
  }
  final dip = m['dipLoadPct'];
  if (dip != null) {
    final t = l['dipLoadPct'] as Map;
    if (dip >= (t['expert'] as num)) {
      put('push', 'dipLoadPct', 4);
    } else if (dip >= (t['advanced'] as num)) {
      put('push', 'dipLoadPct', 3);
    }
  }
  if (m['pullups'] != null) {
    put('pull', 'pullups', _band(m['pullups']!, cuts('pullups')));
  }
  final pull = m['pullLoadPct'];
  if (pull != null) {
    final t = l['pullLoadPct'] as Map;
    if (pull >= (t['expert'] as num)) {
      put('pull', 'pullLoadPct', 4);
    } else if (pull >= (t['advanced'] as num)) {
      put('pull', 'pullLoadPct', 3);
    }
  }
  if (m['squatRatio'] != null) {
    put(
      'squat',
      'squatRatio',
      _band(m['squatRatio']!, cuts('squatRatio'), strictLast: true),
    );
  }
  if (m['hingeReps'] != null) {
    put('hinge', 'hingeReps', _band(m['hingeReps']!, cuts('hingeReps')));
  }
  if (m['plankSeconds'] != null) {
    put(
      'core',
      'plankSeconds',
      _band(m['plankSeconds']!, cuts('plankSeconds')),
    );
  }
  final known = levels.values.toList();
  final global = lowerMedian(known);
  for (final mv in kRefMovements) {
    if (!levels.containsKey(mv)) {
      levels[mv] = global;
      sources[mv] = 'default';
    }
  }
  return MovementLevels(
    {for (final mv in kRefMovements) mv: levels[mv]!},
    {for (final mv in kRefMovements) mv: sources[mv]!},
    global,
  );
}

// ------------------------------------------------------- modèle et répartition

/// Choix automatique de la périodisation (KT-052).
String chooseModel(GenModels models, GenInputs i, int global) {
  final c =
      models.model('expert_streetlifting')['criteria'] as Map<String, dynamic>;
  final equipment = {for (final l in i.places.values) ...l};
  final expert =
      !i.caution &&
      global >= (c['level'] as num).toInt() &&
      (c['goals'] as List).contains(i.goalPrimary) &&
      i.weekdays.length >= (c['days'] as num).toInt() &&
      i.sessionMinutes >= (c['minutes'] as num).toInt() &&
      (c['equipment'] as List).every(equipment.contains) &&
      (i.goalPrimary != 'event' ||
          i.eventItems.every(
            (e) => const {
              'pull_1rm',
              'dip_1rm',
              'mu_1rm',
              'squat_1rm',
              'pullups_max',
              'dips_max',
              'mu_max',
              'pushups_max',
            }.contains(e),
          ));
  if (expert) return 'expert_streetlifting';
  if (i.goalPrimary == 'health') return 'health';
  if (global <= 1) return 'linear';
  if (global == 2) return 'undulating';
  return 'block';
}

/// Types de séance de la semaine, dans l'ordre des jours (KT-053).
List<String> sessionKinds(int days, String split, {required bool health}) {
  if (days <= 0) return const [];
  if (health || split == 'fullbody') return List.filled(days, 'FB');
  if (split == 'upper_lower') {
    return [for (var i = 0; i < days; i++) i.isEven ? 'U' : 'L'];
  }
  if (split == 'ppl') {
    const c = ['PUSH', 'PULL', 'LEGS'];
    return [for (var i = 0; i < days; i++) c[i % 3]];
  }
  return switch (days) {
    1 => ['FB'],
    2 => ['FB', 'FB'],
    3 => ['FB', 'FB', 'FB'],
    4 => ['U', 'L', 'U', 'L'],
    5 => ['U', 'L', 'PUSH', 'PULL', 'LEGS'],
    6 => ['PUSH', 'PULL', 'LEGS', 'PUSH', 'PULL', 'LEGS'],
    _ => ['PUSH', 'PULL', 'LEGS', 'PUSH', 'PULL', 'LEGS', 'REC'],
  };
}

String splitIdOf(List<String> kinds) {
  if (kinds.every((k) => k == 'FB')) return 'fullbody';
  if (kinds.every((k) => k == 'U' || k == 'L')) return 'upper_lower';
  if (kinds.contains('U')) return 'upper_lower_ppl';
  return 'ppl';
}

const kKindTitles = {
  'FB': 'CORPS ENTIER',
  'U': 'HAUT DU CORPS',
  'L': 'BAS DU CORPS',
  'PUSH': 'POUSSÉE',
  'PULL': 'TIRAGE',
  'LEGS': 'JAMBES',
  'REC': 'RÉCUPÉRATION ACTIVE',
};

// --------------------------------------------------------------- créneaux

/// Créneau d'une séance : ce qu'on cherche, par ordre de priorité.
class _Slot {
  final String key;
  final List<String> types;
  final bool main;
  final String? group; // groupe visé (isolation)
  final List<String> chains; // chaînes préférées (principal)
  final List<String> prefer; // identifiants préférés
  final bool figure;
  final String? eventItem;
  const _Slot(
    this.key,
    this.types, {
    this.main = false,
    this.group,
    this.chains = const [],
    this.prefer = const [],
    this.figure = false,
    this.eventItem,
  });
}

const _pushH = _Slot(
  'push_h',
  ['poussee_horizontale'],
  main: true,
  chains: ['pompes', 'pompes_lestees'],
);
const _pushV = _Slot(
  'push_v',
  ['poussee_verticale'],
  main: true,
  chains: ['dips', 'hspu', 'equilibre_mains'],
);
const _pullV = _Slot(
  'pull_v',
  ['tirage_vertical'],
  main: true,
  chains: ['tractions'],
);
const _pullH = _Slot('pull_h', ['tirage_horizontal'], main: true);
const _squat = _Slot(
  'squat',
  ['squat'],
  main: true,
  chains: ['back_squat', 'squat'],
);
const _hinge = _Slot(
  'hinge',
  ['charniere_hanche'],
  main: true,
  chains: ['charniere'],
);
const _lunge = _Slot('lunge', ['fente']);
const _hingeAcc = _Slot('hinge_acc', ['charniere_hanche']);
const _pushHAcc = _Slot('push_h_acc', ['poussee_horizontale']);
const _pushVAcc = _Slot('push_v_acc', ['poussee_verticale']);
const _pullHAcc = _Slot('pull_h_acc', ['tirage_horizontal']);
const _pullVAcc = _Slot('pull_v_acc', ['tirage_vertical']);
const _coreExt = _Slot(
  'core_ext',
  ['gainage_anti_extension'],
  chains: ['gainage_ventral', 'gainage_creux'],
);
const _coreRot = _Slot('core_rot', ['gainage_anti_rotation']);
const _coreLat = _Slot('core_lat', ['gainage_anti_flexion_laterale']);
const _coreFlex = _Slot('core_flex', ['flexion_tronc']);
const _biceps = _Slot('biceps', ['isolation'], group: 'biceps');
const _triceps = _Slot('triceps', ['isolation'], group: 'triceps');
const _shoulders = _Slot('shoulders', ['isolation'], group: 'épaules');
const _hams = _Slot('hams', ['isolation'], group: 'ischios');
const _calves = _Slot('calves', ['isolation'], group: 'mollets');
const _prevention = _Slot(
  'prevention',
  ['tirage_horizontal', 'isolation'],
  prefer: [
    'face-pulls',
    'face-pulls-elastique',
    'face-pulls-aux-anneaux',
    'oiseau-elevations-buste-penche',
    'oiseau-a-la-poulie',
    'prone-y-raises',
  ],
);

/// Créneaux d'une séance, par priorité décroissante. [index] : rang de la
/// séance de ce type dans la semaine (alternance A/B/C).
List<_Slot> _slotsFor(String kind, int index, {required bool health}) {
  if (health) {
    // Tous les types chaque semaine : rotation fente / squat et
    // charnière / tirage horizontal selon la séance.
    return switch (index % 3) {
      0 => [_squat, _pushH, _pullV, _hinge, _coreExt, _lunge, _pullHAcc],
      1 => [_lunge, _pushV, _pullH, _hinge, _coreRot, _squat, _pushHAcc],
      _ => [_squat, _pushH, _pullH, _hingeAcc, _coreLat, _lunge, _pullVAcc],
    };
  }
  return switch (kind) {
    'FB' => switch (index % 3) {
      0 => [_squat, _pushH, _pullV, _hingeAcc, _coreExt, _pullHAcc, _triceps],
      1 => [_hinge, _pushV, _pullH, _lunge, _coreRot, _pullVAcc, _biceps],
      _ => [
        _squat,
        _pushV,
        _pullV,
        _hingeAcc,
        _coreLat,
        _pushHAcc,
        _prevention,
      ],
    },
    'U' => [
      _pushH,
      _pullV,
      _pushVAcc,
      _pullHAcc,
      _prevention,
      _biceps,
      _triceps,
      _coreFlex,
    ],
    'L' => [_squat, _hinge, _lunge, _hams, _calves, _coreExt, _coreLat],
    'PUSH' => [_pushH, _pushV, _pushHAcc, _triceps, _shoulders, _coreExt],
    'PULL' => [_pullV, _pullH, _pullVAcc, _prevention, _biceps, _coreFlex],
    'LEGS' => [_squat, _hinge, _lunge, _hams, _calves, _coreRot],
    _ => const [],
  };
}

/// Exercice de l'épreuve (objectif « test ou compétition ») et type visé.
const _eventExercise = <String, (List<String>, String)>{
  'pull_1rm': (['traction-lestee', 'traction-pronation'], 'tirage_vertical'),
  'dip_1rm': (['dips-lestes', 'dips'], 'poussee_verticale'),
  'mu_1rm': (['muscle-up-leste', 'muscle-up'], 'figure_dynamique'),
  'squat_1rm': (['back-squat', 'squat-gobelet'], 'squat'),
  'pullups_max': (['traction-pronation'], 'tirage_vertical'),
  'dips_max': (['dips'], 'poussee_verticale'),
  'pushups_max': (['pompes'], 'poussee_horizontale'),
  'mu_max': (['muscle-up'], 'figure_dynamique'),
};

/// Épreuves en répétitions maximales (style endurance).
const _eventMax = {'pullups_max', 'dips_max', 'pushups_max', 'mu_max'};

/// Mouvement ciblé par l'endurance → type et exercices préférés.
const _focusExercise = <String, (String, List<String>)>{
  'pullups': ('tirage_vertical', ['traction-pronation']),
  'pushups': ('poussee_horizontale', ['pompes']),
  'dips': ('poussee_verticale', ['dips']),
  'squats': ('squat', ['squat-au-poids-de-corps']),
};

/// Références de Pilotage des mouvements lestés (charge en % du 1RM).
const _refLoads = <String, (String, String, String)>{
  // id → (type de charge, référence, mouvement Koach)
  'traction-lestee': ('system', 'B8', 'pull'),
  'dips-lestes': ('system', 'B9', 'dip'),
  'muscle-up-leste': ('system', 'B10', 'mu'),
  'back-squat': ('barbell', 'B11', 'squat'),
};

// ----------------------------------------------------------------- résultat

class GeneratedProgram {
  /// Programme au schéma de `programme_v33.json` (meta, pilotage, weeks).
  final Map<String, dynamic> program;

  /// Annotations Koach au schéma de `koach_program.json`.
  final Map<String, dynamic> koach;

  /// Résumé : modèle, explication, niveaux, répartition, volumes…
  final Map<String, dynamic> summary;
  const GeneratedProgram(this.program, this.koach, this.summary);
}

/// Données de base : programme embarqué du propriétaire et annotations.
class GenBase {
  final Map<String, dynamic> program;
  final Map<String, dynamic> koach;
  const GenBase(this.program, this.koach);
}

// ---------------------------------------------------------------- séances

class _Item {
  final GenExercise ex;
  final String
  role; // warmup | mobility | ramp | calibration | main | accessory | specific | circuit | cooldown | test
  final _Slot? slot;
  final int priority;
  int sets;
  String text; // prescription (colonne « Séries × Reps »)
  String intensity;
  int restSec;
  String nameSuffix;
  String why;
  bool hard;
  bool heavy = false;
  int? rir;
  Map<String, dynamic>? load;
  Map<String, dynamic>? koach;
  int minutes; // blocs chronométrés
  _Item(
    this.ex,
    this.role, {
    this.slot,
    this.priority = 0,
    this.sets = 0,
    this.text = '',
    this.intensity = '',
    this.restSec = 0,
    this.nameSuffix = '',
    this.why = '',
    this.hard = false,
    this.rir,
    this.minutes = 0,
  });
}

class _Session {
  final int weekday;
  final int j;
  final String kind;
  final int kindIndex;
  final String place;
  final List<_Item> items = [];
  final Set<String> heavyFamilies = {};
  String title = '';
  String why = '';
  bool capped = false;
  String style = '';
  _Session(this.weekday, this.j, this.kind, this.kindIndex, this.place);
}

/// Contexte d'une génération (catalogue filtré, niveaux, cache de durée).
class _Ctx {
  final GenModels models;
  final GenCatalog catalog;
  final GenInputs inputs;
  final int seed;
  final MovementLevels levels;
  final String model;
  final Set<String> disliked;
  final Set<String> liked;
  final Map<String, double> _time = {};
  _Ctx(
    this.models,
    this.catalog,
    this.inputs,
    this.seed,
    this.levels,
    this.model,
    this.disliked,
    this.liked,
  );

  bool get health => model == 'health';
  bool get simple => levels.global <= 1;
  bool get technical => levels.global >= 3;

  int level(String movement) => levels.levels[movement] ?? levels.global;

  late final List<int> _mainD = models.mainDifficulty;
  late final List<int> _accD = models.accessoryDifficulty;
  late final int _penalty =
      (models.section('difficulty')['cautionPenalty'] as num).toInt();
  final Map<String, Set<String>> _equipment = {};

  int maxDifficulty(GenExercise e, {required bool main}) {
    final lv = level(e.refMovement);
    var d = main ? _mainD[lv] : _accD[lv];
    if (inputs.caution) d -= _penalty;
    return math.max(1, d);
  }

  /// Étape atteinte dans une chaîne (points d'entrée).
  bool achieved(String id) {
    for (final e in inputs.entries.entries) {
      final steps = catalog.chains[e.key];
      if (steps == null) continue;
      final at = steps.indexOf(e.value), i = steps.indexOf(id);
      if (i >= 0 && at >= i) return true;
    }
    return false;
  }

  /// Prérequis atteints : étape validée dans le journal, ou prérequis
  /// nettement sous le niveau du mouvement (KT-054).
  bool prerequisitesMet(GenExercise e) {
    for (final p in e.prereq) {
      final pe = catalog.byId[p];
      if (pe == null) continue;
      if (achieved(p)) continue;
      if (pe.difficulty <= maxDifficulty(e, main: true)) continue;
      return false;
    }
    return true;
  }

  /// Contraintes strictes (matériel, gênes, prudence, goûts).
  bool allowed(GenExercise e, Set<String> equipment, {bool figure = false}) {
    if (!e.usable) return false;
    if (disliked.contains(e.id)) return false;
    if (!e.materiel.every(equipment.contains)) return false;
    for (final p in inputs.pains.entries) {
      if (p.value > 3 && (e.joints[p.key] ?? 0) > 1) return false;
    }
    if (inputs.caution && e.impact) return false;
    final fig = e.type == 'figure_dynamique' || e.type == 'figure_statique';
    if (fig && !figure) return false;
    if (e.measure == 'distance') return false;
    return true;
  }

  Set<String> equipmentAt(String place) =>
      _equipment[place] ??= packEquipment(
        place,
        inputs.places[place] ?? const [],
      );
}

// ------------------------------------------------------------- génération

/// Génère un programme. [firstWeek] : numéro de la première semaine
/// produite (régénération de la suite, cycle suivant) ; [cycle] : rang du
/// cycle (rotation des accessoires, calibrage au premier).
GeneratedProgram generateProgram({
  required GenModels models,
  required GenCatalog catalog,
  required GenBase base,
  required GenInputs inputs,
  required int seed,
  int firstWeek = 1,
  int cycle = 0,
  String? forceModel,
}) {
  final levels = movementLevels(models, inputs);
  final model = forceModel ?? chooseModel(models, inputs, levels.global);
  final explain = models.model(model)['explain'] as Map<String, dynamic>;
  final explanation =
      levels.global >= 3
          ? explain['technical'] as String
          : explain['simple'] as String;
  if (model == 'expert_streetlifting') {
    return GeneratedProgram(base.program, base.koach, {
      'generator': kGeneratorVersion,
      'models': models.version,
      'model': model,
      'modelLabel': models.modelLabel(model),
      'explanation': explanation,
      'levels': levels.toJson(),
      'split': 'streetlifting',
      'splitLabel': 'Modèle streetlifting (6 séances)',
      'weeks': (base.program['weeks'] as List).length,
      'firstWeek': 1,
      'seed': seed,
    });
  }
  final disliked = <String>{};
  for (final n in inputs.disliked) {
    final id = catalog.idForName(n);
    if (id != null) disliked.add(id);
  }
  final liked = <String>{};
  for (final n in inputs.liked) {
    final id = catalog.idForName(n);
    if (id != null) liked.add(id);
  }
  final ctx = _Ctx(
    models,
    catalog,
    inputs,
    seed,
    levels,
    model,
    disliked,
    liked,
  );
  return _Generator(ctx, base, firstWeek, cycle, explanation).run();
}

class _WeekPlan {
  final int n;
  final String kind; // load | deload | taper | event
  final int cycle; // rang du cycle
  final int loadIndex; // rang de la semaine de charge dans le cycle
  final String phase;
  final bool calibration;
  final bool miniTest;
  final bool simulation; // simulation partielle
  final bool fullSimulation;
  final bool eventWeek;
  const _WeekPlan(
    this.n,
    this.kind,
    this.cycle,
    this.loadIndex,
    this.phase, {
    this.calibration = false,
    this.miniTest = false,
    this.simulation = false,
    this.fullSimulation = false,
    this.eventWeek = false,
  });
}

class _Generator {
  final _Ctx c;
  final GenBase base;
  final int firstWeek;
  final int cycle;
  final String explanation;
  _Generator(this.c, this.base, this.firstWeek, this.cycle, this.explanation);

  GenInputs get i => c.inputs;
  GenModels get m => c.models;
  Map<String, dynamic> get model => m.model(c.model);

  late final List<int> weekdays = (i.weekdays.toSet().toList()..sort());
  late final List<String> kinds = sessionKinds(
    weekdays.length,
    i.split,
    health: c.health,
  );

  /// Date civile de la première journée produite.
  DateTime get origin =>
      DateTime(i.start.year, i.start.month, i.start.day + (firstWeek - 1) * 7);

  int jOf(int weekday) => (weekday - i.start.weekday) % 7 + 1;

  // ---------------------------------------------------------- horizon

  /// Macrocycle jusqu'à la date de l'épreuve.
  bool _macro = false;

  List<_WeekPlan> _horizon() {
    final loadWeeks = (model['loadWeeks'] as num).toInt();
    final cycleLen = loadWeeks + 1;
    final event = i.goalPrimary == 'event' ? i.eventDate : null;
    final out = <_WeekPlan>[];
    if (event != null) {
      final days = civilDayIndex(event) - civilDayIndex(origin);
      // Au-delà de 40 semaines : cycles ordinaires ; le macrocycle sera
      // construit quand l'épreuve entrera dans l'horizon (cycle suivant).
      if (days >= 0 && days ~/ 7 + 1 <= 40) {
        _macro = true;
        // Macrocycle jusqu'à la date (40 semaines au plus) : cycles, puis
        // affûtage de 7 ou 14 jours ; la semaine de l'épreuve est la
        // dernière produite.
        final total = math.min(40, days ~/ 7 + 1);
        final t = m.section('taper');
        final taper = total >= (t['longFromWeeks'] as num).toInt() ? 2 : 1;
        final build = total - taper;
        var n = firstWeek, cyc = cycle;
        while (n < firstWeek + build) {
          final remaining = firstWeek + build - n;
          // Une décharge au moins toutes les 6 semaines ; un reliquat court
          // (≤ 3 semaines, suivi de l'affûtage) reste sans décharge.
          final len = math.min(remaining, cycleLen);
          final loads =
              (len == remaining && remaining <= 3) || len == 1 ? len : len - 1;
          for (var w = 0; w < loads; w++) {
            out.add(
              _WeekPlan(
                n++,
                'load',
                cyc,
                w,
                _phaseName(w),
                calibration:
                    i.calibration && cyc == cycle && cycle == 0 && w < 2,
                simulation: w == loads - 1 && loads >= 3,
              ),
            );
          }
          if (loads < len) {
            out.add(
              _WeekPlan(n++, 'deload', cyc, -1, 'Décharge', miniTest: true),
            );
          }
          cyc++;
        }
        // Simulation complète 2 à 3 semaines avant l'épreuve (hors
        // affûtage), sur une semaine de charge.
        for (var x = out.length - 1; x >= 0; x--) {
          final w = out[x];
          if (w.kind == 'load' && w.n <= firstWeek + build - 2) {
            out[x] = _WeekPlan(
              w.n,
              w.kind,
              w.cycle,
              w.loadIndex,
              w.phase,
              calibration: w.calibration,
              fullSimulation: true,
            );
            break;
          }
        }
        for (var t2 = 0; t2 < taper; t2++) {
          out.add(
            _WeekPlan(
              n++,
              'taper',
              cyc,
              -1,
              'Affûtage',
              eventWeek: t2 == taper - 1,
            ),
          );
        }
        return out;
      }
    }
    for (var w = 0; w < loadWeeks; w++) {
      out.add(
        _WeekPlan(
          firstWeek + w,
          'load',
          cycle,
          w,
          _phaseName(w),
          calibration: i.calibration && cycle == 0 && w < 2,
        ),
      );
    }
    out.add(
      _WeekPlan(
        firstWeek + loadWeeks,
        'deload',
        cycle,
        -1,
        'Décharge',
        miniTest: true,
      ),
    );
    return out;
  }

  String _phaseName(int w) {
    final weeks = model['weeks'] as List;
    final spec = weeks[w % weeks.length] as Map;
    return spec['phase'] as String? ?? (model['label'] as String);
  }

  Map<String, dynamic> _weekSpec(int loadIndex) {
    final weeks = model['weeks'] as List;
    return (weeks[loadIndex % weeks.length] as Map).cast<String, dynamic>();
  }

  // --------------------------------------------------------- sélection

  final Map<String, GenExercise?> _pickCache = {};

  GenExercise? _pick(
    _Slot s,
    _Session session, {
    required int cyc,
    Set<String> exclude = const {},
    int? maxOverride,
  }) {
    final key =
        '${s.key}|${s.types.join(',')}|${s.group}|${s.main}|${s.figure}|'
        '${session.place}|$cyc|$maxOverride|${(exclude.toList()..sort()).join(',')}';
    if (_pickCache.containsKey(key)) return _pickCache[key];
    return _pickCache[key] = _pickUncached(
      s,
      session,
      cyc: cyc,
      exclude: exclude,
      maxOverride: maxOverride,
    );
  }

  GenExercise? _pickUncached(
    _Slot s,
    _Session session, {
    required int cyc,
    Set<String> exclude = const {},
    int? maxOverride,
  }) {
    final equipment = c.equipmentAt(session.place);
    final place = kPlaceToPack[session.place];
    final candidates = <GenExercise>[];
    for (final e in c.catalog.all) {
      if (!s.types.contains(e.type)) continue;
      if (s.group != null && !e.groups.contains(s.group)) continue;
      if (exclude.contains(e.id)) continue;
      if (!c.allowed(e, equipment, figure: s.figure)) continue;
      if (e.measure == 'temps' &&
          s.main &&
          !s.types.first.startsWith('gainage')) {
        continue;
      }
      final maxD = maxOverride ?? c.maxDifficulty(e, main: s.main);
      if (e.difficulty > maxD && !c.achieved(e.id)) continue;
      if (!c.prerequisitesMet(e)) continue;
      candidates.add(e);
    }
    if (candidates.isEmpty) return null;
    // Point d'entrée atteint dans une chaîne préférée : étape suivante si
    // elle est permise, sinon l'étape atteinte.
    if (s.main) {
      for (final ch in s.chains) {
        final at = c.inputs.entries[ch];
        final steps = c.catalog.chains[ch];
        if (at == null || steps == null) continue;
        final idx = steps.indexOf(at);
        for (var k = steps.length - 1; k >= 0; k--) {
          if (k > idx + 1) continue;
          final hit = candidates.where((e) => e.id == steps[k]);
          if (hit.isNotEmpty) return hit.first;
        }
      }
    }
    GenExercise? best;
    var bestScore = -1e9;
    for (final e in candidates) {
      final maxD = maxOverride ?? c.maxDifficulty(e, main: s.main);
      final target = s.main ? maxD : math.max(1, maxD - 1);
      var score = -10.0 * (target - e.difficulty).abs();
      if (s.prefer.contains(e.id)) {
        score += 30 - s.prefer.indexOf(e.id).toDouble();
      }
      if (s.main && s.chains.isNotEmpty) {
        for (final ch in s.chains) {
          if (c.catalog.chains[ch]?.contains(e.id) ?? false) {
            score += 8;
            break;
          }
        }
      }
      if (place != null && e.lieux.contains(place)) score += 3;
      if (c.liked.contains(e.id)) score += 6;
      if (s.main && e.unilateral) score -= 2;
      if (s.main &&
          !c.health &&
          (i.goalPrimary == 'strength' || i.goalPrimary == 'event') &&
          e.loaded) {
        score += 4;
      }
      if (c.health && e.loaded && e.loadMode == 'barre') score -= 3;
      // Départage : principaux stables d'un cycle à l'autre, accessoires
      // renouvelés à chaque cycle (KT-054).
      final key =
          s.main
              ? '${c.seed}:${s.key}:${e.id}'
              : '${c.seed}:$cyc:${s.key}:${e.id}';
      score += (genHash(key) % 1000) / 1000.0;
      if (score > bestScore) {
        bestScore = score;
        best = e;
      }
    }
    return best;
  }

  GenExercise? _byIds(List<String> ids, _Session s, {bool figure = false}) {
    final equipment = c.equipmentAt(s.place);
    for (final id in ids) {
      final e = c.catalog.byId[id];
      if (e != null &&
          c.allowed(e, equipment, figure: figure) &&
          c.prerequisitesMet(e)) {
        return e;
      }
    }
    return null;
  }

  // ------------------------------------------------------ prescriptions

  (List<int> reps, int rir, String style) _style(
    _WeekPlan w,
    _Session s,
    _Slot? slot,
    int occurrence,
  ) {
    List<int> reps;
    int rir;
    String style;
    if (c.model == 'block') {
      final spec = _weekSpec(w.loadIndex < 0 ? 0 : w.loadIndex);
      reps = [for (final v in spec['reps'] as List) (v as num).toInt()];
      rir = (spec['rir'] as num).toInt();
      style = spec['phase'] as String;
    } else {
      final styles =
          (c.health && w.cycle > 0 && model['stylesLater'] != null)
              ? model['stylesLater'] as List
              : model['styles'] as List;
      final st = styles[occurrence % styles.length] as Map;
      reps = [for (final v in st['reps'] as List) (v as num).toInt()];
      rir = (st['rir'] as num).toInt();
      style = st['name'] as String;
      final add =
          w.loadIndex >= 0
              ? ((_weekSpec(w.loadIndex)['repsAdd'] as num?)?.toInt() ?? 0)
              : 0;
      if (add > 0) reps = [reps[0] + add, reps[1] + add];
    }
    // Objectif secondaire / endurance : séries plus longues ; force :
    // séries courtes (pondération appliquée par [_goalStyle]).
    if (c.health) {
      final h = m.section('health')['rir'] as List;
      rir = _clampInt(rir, (h[0] as num).toInt(), (h[1] as num).toInt());
    }
    if (w.kind == 'deload') {
      rir += (m.section('deload')['rirAdd'] as num).toInt();
    }
    if (i.caution) rir = math.max(rir, 3);
    return (reps, rir, style);
  }

  /// Objectif servi par un créneau principal (pondération 70/30, KT-052).
  String _goalStyle(String family, int occurrence) {
    final sec = i.goalSecondary;
    if (sec == null || sec == i.goalPrimary) return i.goalPrimary;
    final w = i.goalWeight.clamp(50, 100) / 100.0;
    // Répartition déterministe : l'occurrence k sert le principal tant
    // que sa part cumulée reste ≤ w (arrondi au plus proche).
    final before = (occurrence * w).round();
    final after = ((occurrence + 1) * w).round();
    return after > before ? i.goalPrimary : sec;
  }

  String _setsText(GenExercise e, int sets, List<int> reps) {
    final side = e.unilateral ? ' par côté' : '';
    if (e.measure == 'temps') {
      int r5(int v) => math.max(10, (v / 5).round() * 5);
      final a = r5(reps[0] * 3), b = r5(reps[1] * 3);
      return a == b ? '$sets×$a s$side' : '$sets×$a-$b s$side';
    }
    return reps[0] == reps[1]
        ? '$sets×${reps[0]}$side'
        : '$sets×${reps[0]}-${reps[1]}$side';
  }

  // -------------------------------------------------------- durées

  Exercise _exercise(_Item it, String id) => Exercise.fromJson(_json(it, id));

  double _seconds(_Item it) {
    final key = '${it.ex.id}|${it.nameSuffix}|${it.text}|${it.restSec}';
    final hit = c._time[key];
    if (hit != null) return hit;
    final e = _exercise(it, 'x');
    final est = TrainingEstimator.exercise(e, prescription: it.text);
    return c._time[key] = est.elapsed.midpoint;
  }

  /// Durée estimée d'une séance (même calcul que l'écran : somme des
  /// exercices, 30-60 s de transition entre exercices).
  double sessionSeconds(_Session s) {
    var total = 0.0;
    var first = true;
    for (final it in s.items) {
      final t = _seconds(it);
      total += t;
      if (!first && t > 0) total += 45;
      first = false;
    }
    return total;
  }

  // --------------------------------------------------------- JSON

  String _name(_Item it) =>
      it.nameSuffix.isEmpty ? it.ex.name : '${it.ex.name} — ${it.nameSuffix}';

  Map<String, dynamic> _json(_Item it, String id) {
    final rest = it.restSec;
    return {
      'id': id,
      'name': _name(it),
      'sets': {'type': 'text', 'value': it.text},
      'intensity': it.intensity,
      'load': it.load ?? {'type': 'none'},
      'rest':
          rest <= 0
              ? '—'
              : rest % 60 == 0
              ? '${rest ~/ 60} min'
              : '$rest s',
      'restSec': rest,
      'tempo': '',
      'cue': it.ex.points.take(2).join(' · '),
      'main': it.role == 'main',
      'prevention': it.slot?.key == 'prevention',
      'why': it.why,
      'role': it.role,
      'exId': it.ex.id,
      'groups': it.ex.groups,
      if (it.hard) 'hard': it.sets,
      if (it.heavy) 'heavy': true,
      if (it.ex.family != null) 'family': it.ex.family,
    };
  }

  // ------------------------------------------------------ construction

  GeneratedProgram run() {
    final plan = _horizon();
    final weeks = <Map<String, dynamic>>[];
    final koachEx = <String, dynamic>{};
    final weekTypes = <String, String>{};
    final weekVolumes = <Map<String, dynamic>>[];
    final capped = <String>[];
    final targets = _targets();
    final ceiling = _ceiling();
    // Jour absolu de la dernière séance lourde, par famille.
    final heavyLast = <String, int>{};
    for (final w in plan) {
      final sessions = _week(w, targets, ceiling);
      if (w.eventWeek) _eventDay(w, sessions);
      // Règle des 48 h entre séances lourdes d'une même famille : la
      // seconde devient technique (RIR + 2, charge recalculée).
      for (final s in sessions) {
        final abs = (w.n - 1) * 7 + s.j - 1;
        for (final f in [...s.heavyFamilies]) {
          final prev = heavyLast[f];
          if (prev != null && abs - prev < 2) {
            s.heavyFamilies.remove(f);
            for (final it in s.items) {
              if (it.heavy && it.ex.family == f) {
                it.heavy = false;
                it.rir = (it.rir ?? 2) + 2;
                it.load = _load(it, _repsOf[it] ?? const [8, 12]);
                if (it.koach != null) {
                  it.koach = {...it.koach!, 'rirTarget': it.rir};
                }
                it.intensity =
                    'RIR ${it.rir} · séance technique, moins de 48 h après une séance lourde';
                it.why =
                    '${it.why} Moins de 48 h après la dernière séance lourde de ${kFamilyLabels[f]} : séries techniques.';
              }
            }
          } else {
            heavyLast[f] = abs;
          }
        }
      }
      final days = <Map<String, dynamic>>[];
      final volume = <String, int>{};
      for (var j = 1; j <= 7; j++) {
        final s = _firstOrNull(sessions.where((x) => x.j == j));
        if (s == null) {
          days.add({
            'j': j,
            'title': 'REPOS',
            'cycle': w.kind == 'deload' ? 'DELOAD — décharge' : w.phase,
            'conduite':
                'Repos : récupération. Marche ou mobilité légère si tu en as envie.',
            'exercises': <Map<String, dynamic>>[],
            'why': 'La progression se construit aussi pendant la récupération.',
          });
          continue;
        }
        final exs = <Map<String, dynamic>>[];
        for (var k = 0; k < s.items.length; k++) {
          final it = s.items[k];
          final id = 'g${w.n}.$j.${k + 1}';
          exs.add(_json(it, id));
          if (it.hard) {
            for (final g in it.ex.groups) {
              volume[g] = (volume[g] ?? 0) + it.sets;
            }
          }
          if (it.koach != null) {
            koachEx[id] = it.koach;
          } else if (it.rir != null && it.hard) {
            koachEx[id] = {'rirTarget': it.rir};
          }
        }
        final seconds = sessionSeconds(s);
        if (s.capped) capped.add('S${w.n}-J$j');
        days.add({
          'j': j,
          'title': s.title,
          'cycle':
              w.kind == 'deload'
                  ? 'DELOAD — décharge'
                  : w.kind == 'taper'
                  ? 'Affûtage'
                  : w.phase,
          'conduite': s.why,
          'exercises': exs,
          'why': s.why,
          'kind': s.kind,
          'place': s.place,
          'minutes': i.sessionMinutes,
          'estimate': seconds.round(),
          if (s.capped) 'capped': true,
        });
      }
      weekTypes['${w.n}'] =
          w.eventWeek || w.fullSimulation
              ? 'test'
              : w.kind == 'deload'
              ? 'deload'
              : 'normal';
      weekVolumes.add({'n': w.n, 'kind': w.kind, 'groups': volume});
      weeks.add({
        'n': w.n,
        'dates': '',
        'block':
            'Cycle ${w.cycle + 1} — ${w.kind == 'deload'
                ? 'Décharge'
                : w.kind == 'taper'
                ? 'Affûtage'
                : w.phase}',
        'blockKey': 'C${w.cycle + 1}',
        'color': switch (w.kind) {
          'deload' => '808080',
          'taper' => '4F6D7A',
          _ =>
            w.phase == 'Intensification'
                ? 'A61717'
                : w.phase == 'Réalisation'
                ? '8E1B1B'
                : '6B0C0C',
        },
        'kind': w.kind,
        'phase': w.phase,
        'days': days,
      });
    }
    final meta =
        Map<String, dynamic>.of(base.program['meta'] as Map<String, dynamic>)
          ..['generator'] = kGeneratorVersion
          ..['models'] = m.version
          ..['model'] = c.model
          ..['weeks'] = weeks.length;
    final program = {
      'meta': meta,
      'pilotage': base.program['pilotage'],
      'weeks': weeks,
    };
    final koach = {
      'version': 1,
      'source': {'generator': kGeneratorVersion, 'seed': c.seed},
      'exercises': koachEx,
      'accessories': base.koach['accessories'] ?? const {},
      'weeks': weekTypes,
      'curve': base.koach['curve'] ?? const {},
    };
    final summary = {
      'generator': kGeneratorVersion,
      'models': m.version,
      'model': c.model,
      'modelLabel': m.modelLabel(c.model),
      'explanation': explanation,
      'levels': c.levels.toJson(),
      'split': splitIdOf(kinds),
      'splitLabel': m.splitLabel(splitIdOf(kinds)),
      'kinds': kinds,
      'weekdays': weekdays,
      'firstWeek': firstWeek,
      'weeks': weeks.length,
      'cycle': cycle,
      'seed': c.seed,
      'targets': targets,
      'ceiling': ceiling,
      'weekVolumes': weekVolumes,
      'capped': capped,
      if (_macro) 'eventDate': civilIsoDate(i.eventDate!),
      'goalShare': _goalShare,
    };
    return GeneratedProgram(program, koach, summary);
  }

  /// Part effective de l'objectif principal dans les créneaux principaux.
  Map<String, int> get _goalShare => {
    'primary': _sharePrimary,
    'secondary': _shareSecondary,
  };
  int _sharePrimary = 0, _shareSecondary = 0;

  /// Séries difficiles visées par groupe et par semaine (KT-055).
  Map<String, int> _targets() {
    var start = m.startSets[c.levels.global];
    if (c.health) start -= m.healthReduction;
    final ceiling = m.startSets[c.levels.global] + m.ceilingAbove;
    return {
      for (final g in const [
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
      ])
        g: _clampInt(start + (i.volumeAdjust[g] ?? 0), 2, ceiling),
    };
  }

  int _ceiling() => m.startSets[c.levels.global] + m.ceilingAbove;

  /// Groupes prioritaires : ceux des mouvements de l'objectif principal.
  Set<String> _priorityFamilies() {
    switch (i.goalPrimary) {
      case 'endurance':
        final f = _focusExercise[_focus()]!;
        return {familyOfType(f.$1) ?? 'push'};
      case 'event':
        return {
          for (final it in i.eventItems)
            familyOfType(_eventExercise[it]?.$2 ?? '') ??
                (it.startsWith('mu') ? 'pull' : 'push'),
        };
      case 'strength':
        return {'squat', 'push', 'pull', 'hinge'};
      default:
        return {'squat', 'push', 'pull', 'hinge', 'lunge', 'core'};
    }
  }

  String _focus() {
    if (_focusExercise.containsKey(i.focus)) return i.focus;
    final eq = {for (final l in i.places.values) ...l};
    return eq.contains('pullup_bar') ? 'pullups' : 'pushups';
  }

  List<_Session> _week(_WeekPlan w, Map<String, int> targets, int ceiling) {
    final sessions = <_Session>[];
    final counts = <String, int>{};
    final famOccurrence = <String, int>{};
    final places = i.places.keys.toList()..sort();
    for (var k = 0; k < weekdays.length; k++) {
      final wd = weekdays[k];
      final kind = kinds[k];
      final idx = counts[kind] ?? 0;
      counts[kind] = idx + 1;
      final place = i.dayPlace[wd] ?? places.first;
      final s = _Session(
        wd,
        jOf(wd),
        kind,
        idx,
        i.places.containsKey(place) ? place : places.first,
      );
      _build(s, w, famOccurrence);
      sessions.add(s);
    }
    sessions.sort((a, b) => a.j.compareTo(b.j));
    _ensureCoverage(sessions, w, famOccurrence);
    _allocate(sessions, w, targets, ceiling);
    for (final s in sessions) {
      _fit(s, w, targets, ceiling, sessions);
      _finish(s, w);
    }
    return sessions;
  }

  // ------------------------------------------------------ une séance

  void _build(_Session s, _WeekPlan w, Map<String, int> famOccurrence) {
    final cyc = w.cycle;
    if (s.kind == 'REC') {
      s.title = kKindTitles['REC']!;
      final mob = _pick(const _Slot('rec', ['mobilite']), s, cyc: cyc);
      if (mob != null) {
        final min = _clampInt(i.sessionMinutes ~/ 2, 5, 20);
        s.items.add(
          _Item(
            mob,
            'cooldown',
            minutes: min,
            text: '$min min',
            nameSuffix: 'récupération active',
            why:
                'Récupération active : bouger sans fatigue entre deux blocs de séances.',
          ),
        );
      }
      return;
    }
    final slots = _slotsFor(s.kind, s.kindIndex, health: c.health);
    final used = <String>{};
    var priority = 100;
    // Épreuves : mouvement de l'épreuve en tête de séance (préparation
    // datée).
    final items = <_Item>[];
    if (i.goalPrimary == 'event') {
      for (final item in i.eventItems) {
        final spec = _eventExercise[item];
        if (spec == null) continue;
        final fam = familyOfType(spec.$2) ?? 'pull';
        if (!_kindServes(s.kind, fam)) continue;
        final slot = _Slot(
          'event_$item',
          [spec.$2],
          main: true,
          figure: spec.$2 == 'figure_dynamique',
          eventItem: item,
        );
        final e =
            _byIds(spec.$1, s, figure: slot.figure) ??
            _pick(slot, s, cyc: cyc, exclude: used);
        if (e == null || used.contains(e.id)) continue;
        used.add(e.id);
        items.add(_Item(e, 'main', slot: slot, priority: priority--));
      }
    }
    for (final slot in slots) {
      final e = _pick(slot, s, cyc: cyc, exclude: used);
      if (e == null) continue;
      used.add(e.id);
      items.add(
        _Item(
          e,
          slot.main && items.where((x) => x.role == 'main').length < 3
              ? 'main'
              : 'accessory',
          slot: slot,
          priority: priority--,
        ),
      );
    }
    s.title =
        s.kind == 'FB'
            ? 'CORPS ENTIER ${String.fromCharCode(65 + s.kindIndex % 3)}'
            : kKindTitles[s.kind]!;
    for (final it in items) {
      _prescribe(it, s, w, famOccurrence);
    }
    s.items.addAll(items);
  }

  /// Prescription de base d'un exercice (séries fixées par l'allocation).
  void _prescribe(
    _Item it,
    _Session s,
    _WeekPlan w,
    Map<String, int> famOccurrence,
  ) {
    final fam = it.ex.family ?? '';
    final occ = famOccurrence[fam] ?? 0;
    if (it.role == 'main') famOccurrence[fam] = occ + 1;
    final (reps0, rir, style) = _style(w, s, it.slot, occ);
    var reps = reps0;
    if (it.role == 'main' && !c.health) {
      // Pondération sur tout le programme (et non semaine par semaine).
      final gocc = _goalOcc[fam] ?? 0;
      _goalOcc[fam] = gocc + 1;
      final goal = _goalStyle(fam, gocc);
      if (goal == i.goalPrimary) {
        _sharePrimary++;
      } else {
        _shareSecondary++;
      }
      final item = it.slot?.eventItem;
      if (goal == 'endurance' || (item != null && _eventMax.contains(item))) {
        reps = [math.max(reps[0], 10), math.max(reps[1], 15)];
      } else if (goal == 'strength' ||
          (item != null && item.endsWith('_1rm'))) {
        if (c.model != 'block') {
          reps = [math.min(reps[0], 4), math.min(reps[1], 6)];
        }
      }
    }
    if (it.role != 'main') {
      // Accessoires : plages un peu plus longues, jamais sous 8.
      reps = [math.max(8, reps[0]), math.max(12, reps[1])];
    }
    it.rir = it.role == 'main' ? rir : math.max(rir, 2);
    it.hard = it.rir! <= 3;
    it.heavy = it.role == 'main' && reps[1] <= 6 && it.rir! <= 2;
    if (it.heavy && it.ex.family != null) s.heavyFamilies.add(it.ex.family!);
    it.sets = 0;
    it.restSec =
        c.health
            ? m.restOf('health')
            : it.role == 'main'
            ? (it.heavy ? m.restOf('mainHeavy') : m.restOf('main'))
            : it.ex.type == 'isolation'
            ? m.restOf('isolation')
            : m.restOf('accessory');
    s.style = style;
    it.text = _setsText(it.ex, 2, reps);
    it.intensity = _intensity(it, reps, style, w);
    it.load = _load(it, reps);
    if (it.load != null && it.load!['ref'] != null) {
      final r = _refLoads[it.ex.id]!;
      it.koach = {
        'cat': 'strength',
        'ref': r.$2,
        'movement': r.$3,
        'rirTarget': it.rir,
      };
    }
    _repsOf[it] = reps;
  }

  /// Séances minimales par famille et par semaine : 2 pour les mouvements
  /// de l'objectif (au moins 2 séances), 1 pour chaque type de mouvement
  /// de « Forme et santé » (KT-052, KT-053).
  late final Map<String, int> _required = () {
    final sessions = kinds.where((k) => k != 'REC').length;
    final out = <String, int>{};
    if (c.health) {
      for (final f in const [
        'squat',
        'push',
        'pull',
        'hinge',
        'lunge',
        'core',
      ]) {
        out[f] = 1;
      }
      return out;
    }
    if (sessions < 2) return out;
    for (final f in _priorityFamilies()) {
      out[f] = 2;
    }
    return out;
  }();

  static const _familyTypes = <String, List<String>>{
    'push': ['poussee_horizontale', 'poussee_verticale'],
    'pull': ['tirage_vertical', 'tirage_horizontal'],
    'squat': ['squat'],
    'hinge': ['charniere_hanche'],
    'lunge': ['fente'],
    'core': [
      'gainage_anti_extension',
      'gainage_anti_rotation',
      'gainage_anti_flexion_laterale',
    ],
  };

  /// Ajoute en complément le mouvement de l'objectif (ou le type de
  /// mouvement manquant) aux séances qui ne le travaillent pas, jusqu'au
  /// minimum hebdomadaire.
  void _ensureCoverage(
    List<_Session> sessions,
    _WeekPlan w,
    Map<String, int> famOccurrence,
  ) {
    final training = sessions.where((s) => s.kind != 'REC').toList();
    for (final e in _required.entries) {
      int have() =>
          training
              .where((s) => s.items.any((it) => it.ex.family == e.key))
              .length;
      for (final s in training) {
        if (have() >= e.value) break;
        if (s.items.any((it) => it.ex.family == e.key)) continue;
        final types = _familyTypes[e.key];
        if (types == null) continue;
        final used = {for (final it in s.items) it.ex.id};
        final slot = _Slot('goal_${e.key}', types);
        // Aucun exercice au niveau (mode prudent débutant) : difficulté
        // relâchée jusqu'à 3, prérequis toujours exigés.
        final ex =
            _pick(slot, s, cyc: w.cycle, exclude: used) ??
            _pick(slot, s, cyc: w.cycle, exclude: used, maxOverride: 2) ??
            _pick(slot, s, cyc: w.cycle, exclude: used, maxOverride: 3);
        if (ex == null) continue;
        final it = _Item(ex, 'accessory', slot: slot, priority: 150);
        _prescribe(it, s, w, famOccurrence);
        s.items.insert(0, it);
      }
    }
  }

  /// L'exercice est indispensable au minimum hebdomadaire de sa famille.
  bool _critical(_Item it, _Session s, List<_Session> week) {
    final f = it.ex.family;
    final need = f == null ? null : _required[f];
    if (need == null) return false;
    var count = 0;
    for (final o in week) {
      final has = o.items.any(
        (x) =>
            !identical(x, it) &&
            x.ex.family == f &&
            (x.role == 'main' || x.role == 'accessory') &&
            x.sets > 0,
      );
      if (has) count++;
    }
    return count < need;
  }

  final Map<_Item, List<int>> _repsOf = {};
  final Map<String, int> _goalOcc = {};

  bool _kindServes(String kind, String family) => switch (kind) {
    'FB' => true,
    'U' => family == 'push' || family == 'pull',
    'L' ||
    'LEGS' => family == 'squat' || family == 'hinge' || family == 'lunge',
    'PUSH' => family == 'push',
    'PULL' => family == 'pull',
    _ => false,
  };

  String _intensity(_Item it, List<int> reps, String style, _WeekPlan w) {
    final r = it.rir ?? 2;
    final parts = <String>['RIR $r'];
    if (it.load != null && it.load!['pct'] != null) {
      parts.add('~${((it.load!['pct'] as num) * 100).round()} %');
    }
    if (it.role == 'main' &&
        (c.model == 'linear' || (c.health && w.cycle == 0))) {
      parts.add('+1 rép. par séance réussie');
    }
    if (c.model == 'undulating' && it.role == 'main') {
      parts.add('séance $style');
    }
    if (w.kind == 'deload') parts.add('décharge');
    return parts.join(' · ');
  }

  Map<String, dynamic>? _load(_Item it, List<int> reps) {
    if (it.role != 'main') return null;
    final r = _refLoads[it.ex.id];
    if (r == null || !i.references.containsKey(r.$2)) return null;
    if (r.$1 == 'system' && !i.references.containsKey('B4')) return null;
    final rir = it.rir ?? 2;
    // Epley : %1RM ≈ 1 / (1 + (répétitions + RIR) / 30), arrondi au
    // centième (le mode prudent plafonne à 80 % à l'affichage).
    final pct = 1 / (1 + (reps[1] + rir) / 30);
    return {'type': r.$1, 'ref': r.$2, 'pct': (pct * 100).round() / 100};
  }

  // ------------------------------------------------------ volume

  /// Répartit les séries de la semaine : minimum 2 séries par exercice
  /// retenu, puis tours successifs jusqu'aux séries visées par groupe,
  /// sans dépasser le plafond (KT-055). Les groupes des mouvements de
  /// l'objectif sont servis en premier.
  void _allocate(
    List<_Session> sessions,
    _WeekPlan w,
    Map<String, int> targets,
    int ceiling,
  ) {
    final vol = <String, int>{};
    final prio = _priorityFamilies();
    bool fits(_Item it, int add) {
      for (final g in it.ex.groups) {
        if ((vol[g] ?? 0) + add > ceiling) return false;
      }
      return true;
    }

    void count(_Item it, int add) {
      for (final g in it.ex.groups) {
        vol[g] = (vol[g] ?? 0) + add;
      }
    }

    final budget = i.sessionMinutes * 60.0;
    int rank(_Item it) =>
        (prio.contains(it.ex.family) ? 0 : 1) * 1000 +
        (it.role == 'main' ? 0 : 500) -
        it.priority;
    final sorted = <(_Session, _Item)>[
      for (final s in sessions)
        for (final it in s.items)
          if (it.role == 'main' || it.role == 'accessory') (s, it),
    ]..sort((a, b) {
      final r = rank(a.$2).compareTo(rank(b.$2));
      if (r != 0) return r;
      return a.$1.j.compareTo(b.$1.j);
    });
    // Couverture d'abord : les séances minimales de chaque famille exigée
    // (objectif, « Forme et santé ») reçoivent leurs séries en premier.
    for (final e in _required.entries) {
      final served = <_Session>{};
      for (final (s, it) in sorted) {
        if (served.length >= e.value) break;
        if (it.ex.family != e.key || served.contains(s) || it.sets > 0) {
          continue;
        }
        final sets = fits(it, 2) ? 2 : (fits(it, 1) ? 1 : 0);
        if (sets == 0) continue;
        it.sets = sets;
        _retext(it);
        count(it, sets);
        served.add(s);
      }
    }
    // Tour 0 : 2 séries par exercice retenu, prioritaires d'abord ; le
    // premier principal d'une séance est toujours gardé.
    for (final (s, it) in sorted) {
      if (it.sets > 0) continue;
      final first =
          it.role == 'main' &&
          s.items.where((x) => x.sets > 0 && x.role == 'main').isEmpty;
      var sets = 2;
      if (!fits(it, sets)) {
        if (!first || !fits(it, 1)) continue;
        sets = 1;
      }
      it.sets = sets;
      _retext(it);
      if (!first && _workSeconds(s) > budget * 1.05) {
        it.sets = 0;
        _retext(it);
        continue;
      }
      count(it, sets);
    }
    // Tours suivants : +1 série vers la cible, dans le temps disponible.
    var changed = true;
    while (changed) {
      changed = false;
      for (final (s, it) in sorted) {
        if (it.sets == 0) continue;
        final r = it.role == 'main' ? m.setsMain : m.setsAccessory;
        if (it.sets >= r[1]) continue;
        final under = it.ex.groups.any(
          (g) => (vol[g] ?? 0) < (targets[g] ?? 0),
        );
        if (!under || !fits(it, 1)) continue;
        it.sets++;
        _retext(it);
        if (_workSeconds(s) > budget) {
          it.sets--;
          _retext(it);
          continue;
        }
        count(it, 1);
        changed = true;
      }
    }
    for (final s in sessions) {
      s.items.removeWhere(
        (it) => it.sets == 0 && (it.role == 'main' || it.role == 'accessory'),
      );
    }
    _weekVolume = vol;
  }

  Map<String, int> _weekVolume = {};

  void _retext(_Item it) {
    final reps = _repsOf[it] ?? const [8, 12];
    it.text = _setsText(it.ex, math.max(1, it.sets), reps);
  }

  /// Durée des exercices de travail seuls (échauffement estimé à 7 min).
  double _workSeconds(_Session s) {
    var t =
        7 * 60.0 +
        (c.health ? (i.sessionMinutes < 25 ? 3 * 60.0 : 11 * 60.0) : 0);
    for (final it in s.items) {
      if (it.sets <= 0) continue;
      t += _seconds(it) + 45;
    }
    return t;
  }

  // ------------------------------------------ échauffement, blocs, ajustement

  void _fit(
    _Session s,
    _WeekPlan w,
    Map<String, int> targets,
    int ceiling,
    List<_Session> week,
  ) {
    if (s.kind == 'REC') return;
    final work = [...s.items];
    s.items.clear();
    // Semaine de décharge, d'affûtage, réalisation : séries réduites.
    double factor = 1;
    if (w.kind == 'deload') {
      factor = (m.section('deload')['volumeFactor'] as num).toDouble();
    } else if (w.kind == 'taper') {
      factor = (m.section('taper')['volumeFactor'] as num).toDouble();
    } else if (c.model == 'block' && w.loadIndex >= 0) {
      final spec = _weekSpec(w.loadIndex);
      factor = (spec['volumeFactor'] as num?)?.toDouble() ?? 1;
      final add = (spec['setsAdd'] as num?)?.toInt() ?? 0;
      if (add > 0) {
        for (final it in work) {
          if (it.role == 'main' && it.sets < m.setsMain[1]) {
            if (it.ex.groups.every(
              (g) => (_weekVolume[g] ?? 0) + add <= ceiling,
            )) {
              it.sets += add;
              for (final g in it.ex.groups) {
                _weekVolume[g] = (_weekVolume[g] ?? 0) + add;
              }
            }
          }
        }
      }
    }
    if (factor < 1) {
      for (final it in work) {
        it.sets = math.max(1, (it.sets * factor).round());
      }
    }
    for (final it in work) {
      _retext(it);
    }
    // Échauffement (KT-056).
    final warm = _warmup(s, w, work);
    s.items.addAll(warm);
    // Calibrage (premier cycle) ou mini-test (décharge) : tests légers en
    // tête de séance, jamais d'échec ni de maximum (KT-051).
    if ((w.calibration || (w.miniTest && _lastSessionOf(s, week))) &&
        work.isNotEmpty) {
      final seen = _calibrated[w.n] ??= <String>{};
      for (final it in work.where((x) => x.role == 'main')) {
        final mv = it.ex.refMovement;
        if (seen.contains(mv) ||
            (w.calibration &&
                w.loadIndex == 1 &&
                _calibratedAny.contains(mv))) {
          continue;
        }
        seen.add(mv);
        _calibratedAny.add(mv);
        s.items.add(
          _Item(
            it.ex,
            'calibration',
            sets: 1,
            text:
                it.ex.measure == 'temps'
                    ? '1×20-90 s'
                    : it.ex.loaded
                    ? '1×5-8'
                    : '1×5-20',
            intensity:
                'Calibrage : une série propre, arrête à 2-3 répétitions en réserve (RIR 2-3). Jamais d\'échec, pas de maximum.',
            restSec: 120,
            nameSuffix: w.miniTest ? 'mini-test' : 'calibrage',
            why:
                w.miniTest
                    ? 'Mini-test de fin de cycle : il règle le cycle suivant (jamais à l\'échec).'
                    : 'Mesure ton niveau actuel pour régler la suite (jamais à l\'échec).',
            rir: 3,
          ),
        );
      }
    }
    // Simulations d'épreuve (préparation datée).
    if (i.goalPrimary == 'event' && (w.simulation || w.fullSimulation)) {
      for (final it in work.where((x) => x.slot?.eventItem != null)) {
        s.items.add(
          _Item(
            it.ex,
            'specific',
            sets: 1,
            text: _eventMax.contains(it.slot!.eventItem) ? '1×8-20' : '1×1-3',
            intensity: 'RIR ${i.caution ? 3 : 1} · sans échec',
            restSec: 180,
            nameSuffix:
                w.fullSimulation
                    ? 'simulation complète de l\'épreuve'
                    : 'simulation partielle',
            why:
                w.fullSimulation
                    ? 'Simulation complète : répéter l\'ordre et le rythme de l\'épreuve, sans aller à l\'échec.'
                    : 'Simulation partielle : se familiariser avec l\'épreuve, espacée et sans échec.',
            rir: i.caution ? 3 : 1,
          ),
        );
      }
    }
    s.items.addAll(work);
    // Épreuve : dernier jour de la semaine de l'épreuve.
    // Travail spécifique selon l'objectif.
    final end = <_Item>[];
    if (c.health) {
      end.addAll(_healthBlocks(s, w));
    } else if (_servesFocus(s) && w.kind != 'taper') {
      final d = _density(s, w);
      if (d != null) end.add(d);
    }
    s.items.addAll(end);
    // Ajustement à la durée disponible : ±10 % (KT-053).
    final budget = i.sessionMinutes * 60.0;
    var guard = 0;
    while (sessionSeconds(s) > budget * 1.1 && guard++ < 80) {
      if (!_shrink(s, week)) break;
    }
    guard = 0;
    if (w.kind == 'load') {
      while (sessionSeconds(s) < budget * 0.9 && guard++ < 60) {
        if (!_grow(s, targets, ceiling)) {
          s.capped = true;
          break;
        }
      }
    }
    // Garde-fou : jamais au-delà de +10 %.
    guard = 0;
    while (sessionSeconds(s) > budget * 1.1 && guard++ < 120) {
      if (!_shrink(s, week, force: true)) break;
    }
    // Retrait forcé trop large : on complète de nouveau sans dépasser +10 %.
    guard = 0;
    if (w.kind == 'load') {
      while (sessionSeconds(s) < budget * 0.9 && guard++ < 60) {
        if (!_grow(s, targets, ceiling)) {
          s.capped = true;
          break;
        }
      }
    }
  }

  final Map<int, Set<String>> _calibrated = {};
  final Set<String> _calibratedAny = {};

  bool _lastSessionOf(_Session s, List<_Session> week) =>
      week.where((x) => x.kind != 'REC').last == s;

  bool _servesFocus(_Session s) {
    if (i.goalPrimary != 'endurance' && i.goalSecondary != 'endurance') {
      return false;
    }
    final f = _focusExercise[_focus()]!;
    return _kindServes(s.kind, familyOfType(f.$1) ?? 'push');
  }

  /// Réduit la séance : blocs chronométrés, séries d'accessoires puis de
  /// principaux, exercices non indispensables ; jamais le premier principal
  /// ni l'échauffement. [force] : dernier recours pour tenir +10 %.
  bool _shrink(_Session s, List<_Session> week, {bool force = false}) {
    for (final it in s.items.reversed) {
      if ((it.role == 'circuit' || it.role == 'specific') && it.minutes > 6) {
        it.minutes--;
        _retime(it);
        return true;
      }
    }
    final work =
        s.items.where((x) => x.role == 'accessory' || x.role == 'main').toList()
          ..sort((a, b) => a.priority.compareTo(b.priority));
    for (final it in work) {
      if (it.role == 'accessory' && it.sets > 2) {
        it.sets--;
        _retext(it);
        _dropVolume(it, 1);
        return true;
      }
    }
    for (final it in work) {
      if (it.role == 'main' && it.sets > 2) {
        it.sets--;
        _retext(it);
        _dropVolume(it, 1);
        return true;
      }
    }
    for (final it in work) {
      if (it.role == 'accessory' && !_critical(it, s, week)) {
        s.items.remove(it);
        _dropVolume(it, it.sets);
        return true;
      }
    }
    final mains = work.where((x) => x.role == 'main').toList();
    for (var k = 0; k + 1 < mains.length; k++) {
      final it = mains[k];
      if (!_critical(it, s, week)) {
        s.items.remove(it);
        _dropVolume(it, it.sets);
        return true;
      }
    }
    for (final it in s.items.reversed) {
      if (it.role == 'cooldown' && it.minutes > 3) {
        it.minutes--;
        _retime(it);
        return true;
      }
    }
    for (final it in [...s.items]) {
      if (it.role == 'calibration' ||
          (it.role == 'specific' && it.minutes == 0)) {
        s.items.remove(it);
        return true;
      }
    }
    if (!force) return false;
    for (final it in work) {
      if (it.sets > 1) {
        it.sets--;
        _retext(it);
        _dropVolume(it, 1);
        return true;
      }
    }
    for (final it in [...s.items]) {
      if (it.role == 'ramp' || it.role == 'specific' || it.role == 'circuit') {
        s.items.remove(it);
        return true;
      }
    }
    for (final it in s.items.reversed) {
      if (it.role == 'cooldown' && it.minutes > 2) {
        it.minutes--;
        _retime(it);
        return true;
      }
    }
    for (final it in work) {
      if (it.role == 'accessory') {
        s.items.remove(it);
        _dropVolume(it, it.sets);
        return true;
      }
    }
    if (mains.length > 1) {
      s.items.remove(mains.first);
      _dropVolume(mains.first, mains.first.sets);
      return true;
    }
    for (final it in [...s.items]) {
      if (it.role == 'cooldown') {
        s.items.remove(it);
        return true;
      }
    }
    return false;
  }

  void _dropVolume(_Item it, int sets) {
    for (final g in it.ex.groups) {
      _weekVolume[g] = (_weekVolume[g] ?? 0) - sets;
    }
  }

  /// Ajoute du travail utile sans dépasser le plafond de volume : une série
  /// sur un exercice existant, sinon allonge un bloc chronométré.
  bool _grow(_Session s, Map<String, int> targets, int ceiling) {
    final budget = i.sessionMinutes * 60.0;
    final work =
        s.items.where((x) => x.role == 'accessory' || x.role == 'main').toList()
          ..sort((a, b) => b.priority.compareTo(a.priority));
    for (final it in work) {
      final r = it.role == 'main' ? m.setsMain : m.setsAccessory;
      if (it.sets >= r[1]) continue;
      if (!it.ex.groups.every((g) => (_weekVolume[g] ?? 0) + 1 <= ceiling)) {
        continue;
      }
      it.sets++;
      _retext(it);
      if (sessionSeconds(s) > budget * 1.1) {
        it.sets--;
        _retext(it);
        continue;
      }
      for (final g in it.ex.groups) {
        _weekVolume[g] = (_weekVolume[g] ?? 0) + 1;
      }
      return true;
    }
    for (final it in s.items) {
      final max =
          it.role == 'circuit'
              ? (m.section('health')['circuitMinutes'] as List)[1] as int
              : it.role == 'specific' && it.minutes > 0
              ? 12
              : 0;
      if (max > 0 && it.minutes < max) {
        it.minutes++;
        _retime(it);
        if (sessionSeconds(s) > budget * 1.1) {
          it.minutes--;
          _retime(it);
          continue;
        }
        return true;
      }
    }
    // Accessoire supplémentaire (autre créneau du même type de séance).
    final used = {for (final it in s.items) it.ex.id};
    final extra = _slotsFor(s.kind, s.kindIndex + 1, health: c.health);
    for (final slot in extra) {
      final e = _pick(
        _Slot('${slot.key}_x', slot.types, group: slot.group),
        s,
        cyc: 0,
        exclude: used,
      );
      if (e == null) continue;
      if (!e.groups.every((g) => (_weekVolume[g] ?? 0) + 2 <= ceiling)) {
        continue;
      }
      final it = _Item(
        e,
        'accessory',
        slot: _Slot('${slot.key}_x', slot.types, group: slot.group),
        priority: -1 - s.items.length,
        sets: 2,
        restSec: c.health ? m.restOf('health') : m.restOf('accessory'),
        rir: math.max(2, i.caution ? 3 : 2),
        hard: true,
      );
      _repsOf[it] = const [8, 12];
      _retext(it);
      it.intensity = 'RIR ${it.rir}';
      it.why = _whyExercise(it);
      // Inséré avant les blocs de fin.
      final at = s.items.indexWhere(
        (x) =>
            x.role == 'circuit' ||
            x.role == 'cooldown' ||
            (x.role == 'specific' && x.minutes > 0),
      );
      if (at < 0) {
        s.items.add(it);
      } else {
        s.items.insert(at, it);
      }
      if (sessionSeconds(s) > budget * 1.1) {
        s.items.remove(it);
        continue;
      }
      for (final g in e.groups) {
        _weekVolume[g] = (_weekVolume[g] ?? 0) + 2;
      }
      return true;
    }
    return false;
  }

  void _retime(_Item it) {
    if (it.role == 'specific' && it.text.startsWith('EMOM')) {
      final reps = RegExp(r'(\d+) reps').firstMatch(it.text)?[1] ?? '5';
      it.text = 'EMOM ${it.minutes} min · $reps reps';
    } else if (it.role == 'specific' && it.text.startsWith('AMRAP')) {
      it.text = 'AMRAP ${it.minutes} min';
    } else {
      it.text = '${it.minutes} min';
    }
  }

  List<_Item> _warmup(_Session s, _WeekPlan w, List<_Item> work) {
    final wu = m.section('warmup');
    final out = <_Item>[];
    final equipment = c.equipmentAt(s.place);
    // 3 minutes d'activation générale, sans impact en mode prudent.
    const activation = [
      'rameur',
      'skierg',
      'marche-rapide',
      'jumping-jacks',
      'high-knees-montees-de-genoux',
      'inchworms',
      'cercles-de-bras',
    ];
    GenExercise? act;
    for (final id in activation) {
      final e = c.catalog.byId[id];
      if (e != null && c.allowed(e, equipment) && c.prerequisitesMet(e)) {
        act = e;
        break;
      }
    }
    act ??= _pick(
      const _Slot('warm', ['mobilite', 'locomotion', 'conditionnement']),
      s,
      cyc: 0,
      maxOverride: 2,
    );
    if (act != null) {
      out.add(
        _Item(
          act,
          'warmup',
          minutes: (wu['activationMinutes'] as num).toInt(),
          text: '${(wu['activationMinutes'] as num).toInt()} min',
          intensity: 'Facile, respiration aisée',
          nameSuffix: 'activation générale',
          why:
              'Échauffement : élever la température et le rythme cardiaque en douceur.',
        ),
      );
    }
    // Mobilité des articulations sollicitées.
    final lower = s.kind == 'L' || s.kind == 'LEGS';
    final mobIds =
        lower
            ? const [
              'mobilisation-cheville-genou-au-mur',
              'fente-basse-etirement-hanche',
              'squat-profond-tenu',
              'etirements-flechisseurs-de-hanche',
            ]
            : const [
              'cercles-de-bras',
              'mobilite-epaules-poignets',
              'wall-slides-glisses-au-mur',
              'mobilite-thoracique-cat-cow-rotations',
              'dislocations-epaules-baton',
            ];
    GenExercise? mob;
    for (final id in mobIds) {
      final e = c.catalog.byId[id];
      if (e != null &&
          c.allowed(e, equipment) &&
          c.prerequisitesMet(e) &&
          e.id != act?.id) {
        mob = e;
        break;
      }
    }
    final mobRange = wu['mobilityMinutes'] as List;
    final mobItem =
        mob == null
            ? null
            : _Item(
              mob,
              'mobility',
              minutes: (mobRange[0] as num).toInt(),
              text: '${(mobRange[0] as num).toInt()} min',
              intensity: 'Amplitude progressive, sans douleur',
              nameSuffix: 'mobilité articulaire',
              why:
                  lower
                      ? 'Prépare chevilles, genoux et hanches aux mouvements du jour.'
                      : 'Prépare épaules, coudes et poignets aux mouvements du jour.',
            );
    if (mobItem != null) out.add(mobItem);
    // Montée en charge sur le premier mouvement principal.
    final first = _firstOrNull(work.where((x) => x.role == 'main'));
    if (first != null) {
      final reps = _repsOf[first] ?? const [8, 12];
      final level =
          reps[1] <= 6
              ? 'heavy'
              : reps[1] <= 12
              ? 'moderate'
              : 'light';
      final steps = (wu['ramp'] as Map)[level] as List;
      final String text;
      final String intensity;
      if (first.ex.loaded || first.load != null) {
        text =
            '${steps.length}×${(steps.last as List)[1]}-${(steps.first as List)[1]}';
        intensity =
            'Montée : ${steps.map((st) => '${(st as List)[0]} % × ${st[1]}').join(', ')} de ta charge de travail';
      } else {
        text = '2×3-5';
        intensity = 'Séries d\'approche faciles, loin de l\'échec';
      }
      out.add(
        _Item(
          first.ex,
          'ramp',
          text: text,
          intensity: intensity,
          restSec: 45,
          nameSuffix: 'montée en charge',
          why:
              'Monte progressivement vers ta charge de travail : le geste se cale, les articulations suivent.',
        ),
      );
    }
    // Durée totale : 5 à 10 minutes (mobilité ajustée, puis rampe réduite).
    double total() {
      var t = 0.0;
      for (var k = 0; k < out.length; k++) {
        t += _seconds(out[k]) + (k > 0 ? 45 : 0);
      }
      return t;
    }

    final tot = wu['totalMinutes'] as List;
    final lo = (tot[0] as num) * 60.0, hi = (tot[1] as num) * 60.0;
    if (mobItem != null) {
      while (total() < lo && mobItem.minutes < (mobRange[1] as num).toInt()) {
        mobItem.minutes++;
        mobItem.text = '${mobItem.minutes} min';
      }
    }
    final ramp = _firstOrNull(out.where((x) => x.role == 'ramp'));
    if (ramp != null && total() > hi) {
      ramp.text = '2×3-5';
      ramp.intensity = 'Deux séries d\'approche : 40 % × 5 puis 60 % × 3';
    }
    if (ramp != null && total() > hi) out.remove(ramp);
    if (act != null && total() < lo) {
      final a = out.first;
      while (total() < lo && a.minutes < 6) {
        a.minutes++;
        a.text = '${a.minutes} min';
      }
    }
    return out;
  }

  List<_Item> _healthBlocks(_Session s, _WeekPlan w) {
    final out = <_Item>[];
    final equipment = c.equipmentAt(s.place);
    final h = m.section('health');
    final range = h['circuitMinutes'] as List;
    // Circuit à faible impact : 3 exercices simples à la suite.
    const circuitIds = [
      'jumping-jacks',
      'mountain-climbers',
      'squat-au-poids-de-corps',
      'bird-dog',
      'marche-rapide',
      'planche-sur-les-genoux',
      'pont-fessier-au-sol',
      'dead-bug',
      'fentes-arriere',
      'pompes-inclinees-mains-surelevees',
    ];
    final picks = <GenExercise>[];
    final offset = (s.kindIndex + w.n) % circuitIds.length;
    for (var k = 0; k < circuitIds.length && picks.length < 3; k++) {
      final e = c.catalog.byId[circuitIds[(offset + k) % circuitIds.length]];
      if (e == null || !c.allowed(e, equipment)) continue;
      if (e.impact || !c.prerequisitesMet(e)) continue;
      picks.add(e);
    }
    // Moins de 25 minutes : pas de circuit, la durée va au travail.
    if (picks.isNotEmpty && i.sessionMinutes >= 25) {
      final min = (range[0] as num).toInt();
      final it = _Item(
        picks.first,
        'circuit',
        minutes: min,
        text: '$min min',
        intensity:
            'Rythme modéré : tu peux parler. 40 s d\'effort, 20 s de pause',
        nameSuffix:
            'circuit faible impact avec ${picks.skip(1).map((e) => e.nom.toLowerCase()).join(' et ')}',
        why:
            'Circuit à faible impact : entretenir le souffle sans choc pour les articulations.',
        restSec: 0,
      );
      out.add(it);
    }
    // 5 minutes de mobilité de retour au calme.
    const cool = [
      'etirements-chaine-posterieure',
      'mobilite-thoracique-cat-cow-rotations',
      'etirements-flechisseurs-de-hanche',
      'fente-basse-etirement-hanche',
    ];
    for (final id in cool) {
      final e = c.catalog.byId[id];
      if (e != null && c.allowed(e, equipment) && c.prerequisitesMet(e)) {
        final min =
            i.sessionMinutes < 20
                ? 3
                : (h['mobilityEndMinutes'] as num).toInt();
        out.add(
          _Item(
            e,
            'cooldown',
            minutes: min,
            text: '$min min',
            intensity: 'Respiration lente, sans forcer',
            nameSuffix: 'mobilité de retour au calme',
            why:
                'Mobilité de fin de séance : garder de l\'amplitude et revenir au calme.',
          ),
        );
        break;
      }
    }
    return out;
  }

  /// Bloc de densité sur le mouvement ciblé (EMOM, AMRAP court, échelles).
  _Item? _density(_Session s, _WeekPlan w) {
    final f = _focusExercise[_focus()]!;
    final equipment = c.equipmentAt(s.place);
    GenExercise? e;
    for (final it in s.items) {
      if (it.role == 'main' && it.ex.type == f.$1) {
        e = it.ex;
        break;
      }
    }
    e ??= _byIds(f.$2, s);
    if (e == null || !c.allowed(e, equipment) || !c.prerequisitesMet(e)) {
      return null;
    }
    final max = switch (_focus()) {
      'pullups' => i.measures['pullups'],
      'pushups' => i.measures['pushups'],
      _ => null,
    };
    final reps = _clampInt(((max ?? 10) * 0.4).round(), 2, 15);
    final variant = (w.n + s.kindIndex) % 3;
    final minutes = _clampInt(6 + 2 * math.max(0, w.loadIndex), 6, 12);
    final String text;
    switch (variant) {
      case 0:
        text = 'EMOM $minutes min · $reps reps';
      case 1:
        text = 'AMRAP ${math.min(minutes, 8)} min';
      default:
        text = '2 échelles de 1 à ${_clampInt(reps, 2, 8)}';
    }
    return _Item(
      e,
      'specific',
      minutes:
          variant == 2 ? 0 : (variant == 1 ? math.min(minutes, 8) : minutes),
      text: text,
      intensity:
          'RIR ${i.caution ? 3 : 2} en fin de bloc · densité, jamais d\'échec',
      restSec: variant == 2 ? 90 : 0,
      nameSuffix:
          variant == 0
              ? 'bloc de densité (EMOM)'
              : variant == 1
              ? 'bloc de densité (AMRAP court)'
              : 'bloc de densité (échelles)',
      why:
          'Travail spécifique d\'endurance : plus de répétitions de qualité dans le même temps.',
      rir: i.caution ? 3 : 2,
    );
  }

  /// Jour de l'épreuve : les séances de ce jour et des jours suivants de la
  /// semaine sont remplacées par l'épreuve elle-même (échauffement puis
  /// épreuves dans l'ordre choisi).
  void _eventDay(_WeekPlan w, List<_Session> sessions) {
    final date = i.eventDate;
    if (date == null) return;
    final j = civilDayIndex(date) - civilDayIndex(i.start) - (w.n - 1) * 7 + 1;
    if (j < 1 || j > 7) return;
    sessions.removeWhere((s) => s.j >= j);
    final wd = date.weekday;
    final places = i.places.keys.toList()..sort();
    final place = i.dayPlace[wd] ?? places.first;
    final s = _Session(
      wd,
      j,
      'EVENT',
      0,
      i.places.containsKey(place) ? place : places.first,
    );
    final tests = <_Item>[];
    for (final item in i.eventItems) {
      final spec = _eventExercise[item];
      if (spec == null) continue;
      final e =
          _byIds(spec.$1, s, figure: spec.$2 == 'figure_dynamique') ??
          _pick(
            _Slot(
              'event_$item',
              [spec.$2],
              main: true,
              figure: spec.$2 == 'figure_dynamique',
            ),
            s,
            cyc: w.cycle,
          );
      if (e == null) continue;
      final max = _eventMax.contains(item);
      final it = _Item(
        e,
        'test',
        text: max ? '1×max' : 'Montée : 3 paliers puis 3 tentatives',
        intensity:
            max
                ? 'Épreuve : maximum de répétitions propres'
                : 'Épreuve : une répétition, montée par paliers',
        restSec: 300,
        nameSuffix: 'épreuve',
        why: 'Jour J : l\'épreuve que tu as préparée.',
      );
      _repsOf[it] = max ? const [8, 20] : const [1, 1];
      tests.add(it);
    }
    s.items.addAll(_warmup(s, w, const []));
    s.items.addAll(tests);
    s.title = 'TEST — JOUR J';
    s.why =
        'Jour de l\'épreuve : échauffement complet, puis tes épreuves dans l\'ordre. Récupère bien entre chaque essai.';
    sessions.add(s);
  }

  void _finish(_Session s, _WeekPlan w) {
    for (final it in s.items) {
      if (it.why.isEmpty) it.why = _whyExercise(it);
    }
    s.why = _whySession(s, w);
  }

  // --------------------------------------------------------- pourquoi

  String _groupsText(GenExercise e) {
    final g = e.groups.isEmpty ? ['tout le corps'] : e.groups;
    return g.length == 1
        ? g.first
        : '${g.take(g.length - 1).join(', ')} et ${g.last}';
  }

  String _whyExercise(_Item it) {
    final e = it.ex;
    final chain = c.catalog.chainOf(e.id, it.slot?.chains);
    if (it.role == 'main') {
      if (c.simple) {
        return 'Exercice principal : il fait progresser ${_groupsText(e)}, à ton niveau actuel.';
      }
      final r = _repsOf[it];
      final step =
          chain == null
              ? ''
              : ' ; étape ${chain.$2 + 1}/${c.catalog.chains[chain.$1]!.length} de « ${c.catalog.chainTitles[chain.$1]} »';
      return 'Principal ${kFamilyLabels[e.family] ?? e.type} : ${r == null ? '' : '${r[0]}-${r[1]} répétitions '}à RIR ${it.rir}$step.';
    }
    if (it.slot?.key == 'prevention') {
      return c.simple
          ? 'Protège tes épaules : un petit travail pour l\'arrière des épaules.'
          : 'Prévention : équilibre poussée / tirage, rotateurs externes et deltoïdes postérieurs.';
    }
    return c.simple
        ? 'Complète le travail de ${_groupsText(e)}.'
        : 'Accessoire pour équilibrer le volume hebdomadaire de ${_groupsText(e)}.';
  }

  String _whySession(_Session s, _WeekPlan w) {
    final base = switch (s.kind) {
      'FB' =>
        c.simple
            ? 'Séance corps entier : jambes, poussée, tirage et gainage, pour progresser partout.'
            : 'Corps entier : un mouvement principal par grand schéma moteur, volume réparti sur la semaine.',
      'U' =>
        c.simple
            ? 'Haut du corps : pousser et tirer, en équilibre.'
            : 'Haut du corps : poussées et tirages appariés, prévention des épaules.',
      'L' =>
        c.simple
            ? 'Bas du corps : jambes, fessiers et gainage.'
            : 'Bas du corps : squat, charnière de hanche et travail unilatéral.',
      'PUSH' => 'Poussée : pectoraux, épaules et triceps.',
      'PULL' => 'Tirage : dos et biceps, prévention des épaules.',
      'LEGS' => 'Jambes : squat, charnière de hanche et fentes.',
      _ => 'Récupération active.',
    };
    final phase = switch (w.kind) {
      'deload' =>
        ' Semaine de décharge : moins de séries pour récupérer, puis un mini-test léger.',
      'taper' =>
        w.eventWeek
            ? ' Semaine de l\'épreuve : volume réduit, intensité maintenue. Bonne épreuve !'
            : ' Affûtage : volume réduit, intensité maintenue avant ton épreuve.',
      _ =>
        w.calibration
            ? ' Premières semaines : tests légers de calibrage en début de séance.'
            : '',
    };
    final cap =
        s.capped
            ? ' Séance plus courte que ton temps disponible : rien de plus ne tient sans dépasser ton temps ou le volume prévu pour ta récupération.'
            : '';
    return '$base$phase$cap';
  }
}
