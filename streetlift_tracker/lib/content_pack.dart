// Base d'exercices v2 (L9b, KT-079) : index léger chargé au démarrage
// (recherche, filtres, correspondance des anciens noms et du programme de
// 40 semaines) et fiches complètes chargées à la demande (détails, sources,
// démonstrations, arbres de progression). Aucune donnée utilisateur n'est
// réécrite : les séances, l'historique et les records gardent leurs noms, et
// le nom est résolu en identifiant v2 à la lecture (mapping_v1_to_v2).
import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter/services.dart';

import 'search.dart';

/// Entrée de l'index (une par exercice, 625).
class ExerciseEntry {
  final String id, nom;

  /// Nom historique (clé des séances, de l'historique et des records) : nom
  /// v1 pour les 505 exercices d'origine, `nom` pour les ajouts.
  final String n;

  /// Groupes et matériel au format de l'ancienne base (`g`, `eq`).
  final String g, eq;
  final bool v1;
  final List<String> alias, lieux, materiel, groupes, muscles;
  final String type, demo;
  final int difficulte;
  final bool generateur;
  final String? doublonDe;

  const ExerciseEntry({
    required this.id,
    required this.nom,
    required this.n,
    required this.g,
    required this.eq,
    this.v1 = true,
    this.alias = const [],
    this.lieux = const [],
    this.materiel = const [],
    this.groupes = const [],
    this.muscles = const [],
    this.type = '',
    this.demo = 'disponible',
    this.difficulte = 1,
    this.generateur = true,
    this.doublonDe,
  });

  factory ExerciseEntry.fromJson(Map<String, dynamic> j) {
    List<String> l(String k) => [for (final v in (j[k] as List? ?? [])) '$v'];
    return ExerciseEntry(
      id: j['id'] as String,
      nom: j['nom'] as String,
      n: j['n'] as String,
      g: j['g'] as String,
      eq: j['eq'] as String,
      v1: j['v1'] == true,
      alias: l('alias'),
      lieux: l('lieux'),
      materiel: l('materiel'),
      groupes: l('groupes'),
      muscles: l('muscles'),
      type: j['type'] as String? ?? '',
      demo: j['demo'] as String? ?? 'disponible',
      difficulte: (j['difficulte'] as num?)?.toInt() ?? 1,
      generateur: j['generateur'] != false,
      doublonDe: j['doublon_de'] as String?,
    );
  }

  /// Format historique de la base (`n`, `g`, `eq`) + identifiant v2.
  Map<String, dynamic> toLegacy() => {'n': n, 'g': g, 'eq': eq, 'id': id};
}

/// Index de la base v2 et correspondances.
class ContentIndex {
  final String version;
  final List<ExerciseEntry> entries;
  final Map<String, ExerciseEntry> byId;
  final Map<String, String> typeLabels, lieuLabels, materielLabels;
  final Map<String, String> muscleLabels;

  /// Ancien nom v1 → identifiant (canonique si l'entrée v1 est un doublon).
  final Map<String, String> baseV1;

  /// Intitulé du programme v33 → identifiant.
  final Map<String, String> programme;
  final Map<String, String> _byNormalizedName;

  ContentIndex._({
    required this.version,
    required this.entries,
    required this.typeLabels,
    required this.lieuLabels,
    required this.materielLabels,
    required this.muscleLabels,
    required this.baseV1,
    required this.programme,
  }) : byId = {for (final e in entries) e.id: e},
       _byNormalizedName = {
         for (final e in entries) ...{
           for (final a in e.alias) normalizeText(a): e.id,
           normalizeText(e.nom): e.id,
           normalizeText(e.n): e.id,
         },
       };

  factory ContentIndex.fromJson(Map<String, dynamic> j) {
    final vocab = j['vocabulaires'] as Map<String, dynamic>;
    Map<String, String> labels(String k) => {
      for (final e in (vocab[k] as Map<String, dynamic>).entries)
        e.key: '${e.value}',
    };
    return ContentIndex._(
      version: j['version'] as String? ?? '',
      entries: [
        for (final e in j['exercices'] as List)
          ExerciseEntry.fromJson(e as Map<String, dynamic>),
      ],
      typeLabels: labels('types_mouvement'),
      lieuLabels: labels('lieux'),
      materielLabels: labels('materiel'),
      muscleLabels: labels('muscles'),
      baseV1: {
        for (final e in (j['base_v1'] as Map<String, dynamic>).entries)
          e.key:
              ((e.value as Map)['canonique'] ?? (e.value as Map)['id'])
                  as String,
      },
      programme: {
        for (final e in (j['programme_v33'] as Map<String, dynamic>).entries)
          e.key: (e.value as Map)['id'] as String,
      },
    );
  }

  static const indexAsset = 'assets/content/index.json.gz';

  static Future<ContentIndex> load([AssetBundle? bundle]) async {
    final bytes = await (bundle ?? rootBundle).load(indexAsset);
    return ContentIndex.fromJson(
      jsonDecode(utf8.decode(gzip.decode(bytes.buffer.asUint8List())))
          as Map<String, dynamic>,
    );
  }

  /// Identifiant v2 d'un nom enregistré (séance, historique, record,
  /// intitulé du programme). Ordre : correspondance v1 (canonique), intitulé
  /// du programme, nom ou alias v2 ; null pour un exercice personnel.
  String? idFor(String name) {
    final exact = baseV1[name] ?? programme[name];
    if (exact != null) return exact;
    final base = name.split(' — ').first.split(' [').first.trim();
    return baseV1[base] ??
        programme[base] ??
        _byNormalizedName[normalizeText(name)] ??
        _byNormalizedName[normalizeText(base)];
  }

  ExerciseEntry? entryFor(String name) {
    final id = idFor(name);
    return id == null ? null : byId[id];
  }
}

/// Fiche complète (chargée à la demande).
class ExerciseDetail {
  final Map<String, dynamic> raw;
  const ExerciseDetail(this.raw);

  List<String> _l(String k) => [for (final v in (raw[k] as List? ?? [])) '$v'];
  List<String> get primaires => _l('muscles_primaires');
  List<String> get secondaires => _l('muscles_secondaires');
  List<String> get stabilisateurs => _l('muscles_stabilisateurs');
  List<String> get etires => _l('muscles_etires');
  List<String> get pointsCles => _l('points_cles');
  List<String> get erreurs => _l('erreurs_frequentes');
  List<String> get precautions => _l('precautions');
  List<String> get progressions => _l('progressions');
  List<String> get regressions => _l('regressions');
  List<String> get methodes => _l('methodes');
  String get respiration => raw['respiration'] as String? ?? '';
  String get modeCharge => raw['mode_charge'] as String? ?? '';
  String get mesure => raw['mesure'] as String? ?? '';
  String? get varianteDe => raw['variante_de'] as String?;
  List<(String, String)> get prerequis => [
    for (final p in (raw['prerequis'] as List? ?? []))
      ('${(p as Map)['id']}', '${p['seuil'] ?? ''}'),
  ];
  Map<String, dynamic> get pose =>
      (raw['pose'] as Map?)?.cast<String, dynamic>() ?? const {};
  String get demoStatut => pose['statut'] as String? ?? 'indisponible';
  String? get demoMotif => pose['motif'] as String?;
  Map<String, int> get contraintes => {
    for (final e in ((raw['contrainte_articulaire'] as Map?) ?? {}).entries)
      '${e.key}': (e.value as num).toInt(),
  };
}

/// Contenu chargé à la demande (fiches, sources, poses, progressions).
class ContentLibrary {
  final Map<String, dynamic> details, sources, poses, progressions;
  final Map<String, dynamic> vocab;
  ContentLibrary._(
    this.details,
    this.sources,
    this.poses,
    this.progressions,
    this.vocab,
  );

  static Future<ContentLibrary>? _pending;

  /// Contenu déjà chargé (fiche suivante affichée sans attente).
  static ContentLibrary? loaded;

  /// Chargement unique et partagé (assets gzip).
  static Future<ContentLibrary> load([AssetBundle? bundle]) =>
      _pending ??= _load(bundle ?? rootBundle).catchError((Object e) {
        _pending = null;
        throw e;
      });

  static Future<Map<String, dynamic>> _gz(AssetBundle b, String name) async {
    final bytes = await b.load('assets/content/$name.json.gz');
    return jsonDecode(utf8.decode(gzip.decode(bytes.buffer.asUint8List())))
        as Map<String, dynamic>;
  }

  static Future<ContentLibrary> _load(AssetBundle b) async {
    final d = await _gz(b, 'details');
    return loaded = ContentLibrary._(
      d['exercices'] as Map<String, dynamic>,
      await _gz(b, 'sources'),
      await _gz(b, 'poses'),
      await _gz(b, 'progressions'),
      d['vocabulaires'] as Map<String, dynamic>,
    );
  }

  ExerciseDetail? detail(String id) {
    final r = details[id];
    return r == null ? null : ExerciseDetail(r as Map<String, dynamic>);
  }

  String label(String vocabulary, String id) {
    final v = (vocab[vocabulary] as Map?)?[id];
    return v == null ? id : '$v';
  }

  List<Map<String, dynamic>> sourcesOf(String id) => [
    for (final s in (sources[id] as List? ?? []))
      (s as Map).cast<String, dynamic>(),
  ];

  /// Gabarit et entrée de démonstration d'un exercice (null si absent).
  (Map<String, dynamic>, Map<String, dynamic>)? poseOf(String id) {
    final e = (poses['exercices'] as Map)[id] as Map?;
    if (e == null) return null;
    final g = (poses['gabarits'] as Map)[e['gabarit']] as Map?;
    if (g == null) return null;
    return (g.cast<String, dynamic>(), e.cast<String, dynamic>());
  }
}

/// Document de recherche d'un exercice : nom historique, nom v2 et alias,
/// groupes, matériel, lieux, type de mouvement et muscles (L9b, KT-082).
SearchDoc exerciseSearchDoc(ContentIndex index, Map<String, dynamic> e) {
  final n = e['n'] as String, g = e['g'] as String, eq = e['eq'] as String;
  final entry = index.byId[e['id']];
  if (entry == null) return SearchDoc(name: n, meta: g, body: eq);
  return SearchDoc(
    name: n,
    meta: [g, ...entry.groupes].join(' '),
    body: [
      eq,
      for (final m in entry.materiel) index.materielLabels[m] ?? m,
      index.typeLabels[entry.type] ?? entry.type,
      for (final l in entry.lieux) index.lieuLabels[l] ?? l,
    ].join(' '),
    notes: [
      if (entry.nom != n) entry.nom,
      ...entry.alias,
      for (final m in entry.muscles) index.muscleLabels[m] ?? m,
    ].join(' '),
  );
}
