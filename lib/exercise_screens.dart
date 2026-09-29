// Bibliothèque d'exercices, fiche exercice et mentions (L9b, KT-080/082).
// La fiche réunit démonstration animée, points clés, erreurs fréquentes,
// respiration, muscles (mannequin 3D depuis M3, repli : atlas 2D ; liste en
// texte), précautions, prérequis, progressions et régressions navigables.
// Les consignes sont des repères d'entraînement.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'app_theme.dart';
import 'atlas_data.dart';
import 'content_pack.dart';
import 'exercise_mannequin.dart';
import 'filter_menu.dart';
import 'search.dart';
import 'store.dart';
import 'ui.dart';

/// Ouvre la fiche d'un exercice de la base v2.
Future<void> openExerciseSheet(BuildContext context, String id) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => ExerciseSheetScreen(id: id)));

// ------------------------------- recherche ---------------------------------

/// Filtres de la bibliothèque (ensemble vide = tous).
///
/// M4c : plusieurs choix par catégorie (union), catégories combinées
/// (intersection), dans le menu « Filtres » commun.
class ExerciseFilters {
  final Set<String> types, lieux, materiels;

  /// Tranches de difficulté : 1 (1-3), 2 (4-6), 3 (7-10).
  final Set<int> niveaux;
  const ExerciseFilters({
    this.types = const {},
    this.lieux = const {},
    this.materiels = const {},
    this.niveaux = const {},
  });

  bool accepts(ExerciseEntry e) =>
      (types.isEmpty || types.contains(e.type)) &&
      (lieux.isEmpty || lieux.any(e.lieux.contains)) &&
      (materiels.isEmpty || materiels.any(e.materiel.contains)) &&
      (niveaux.isEmpty || niveaux.contains(difficultyBand(e.difficulte)));

  /// Catégories du menu « Filtres » (clés préfixées : uniques dans le menu).
  static List<FilterCategory> categories(ContentIndex index) => [
    FilterCategory(
      id: 'type',
      label: 'Type de mouvement',
      options: [
        for (final e in index.typeLabels.entries)
          FilterOption('type:${e.key}', e.value),
      ],
    ),
    FilterCategory(
      id: 'lieu',
      label: 'Lieu',
      options: [
        for (final e in index.lieuLabels.entries)
          FilterOption('lieu:${e.key}', e.value),
      ],
    ),
    FilterCategory(
      id: 'materiel',
      label: 'Matériel',
      options: [
        for (final e in index.materielLabels.entries)
          if (e.key != 'aucun') FilterOption('mat:${e.key}', e.value),
      ],
    ),
    FilterCategory(
      id: 'niveau',
      label: 'Difficulté',
      options: [
        for (final e in difficultyBandLabels.entries)
          FilterOption('niv:${e.key}', e.value),
      ],
    ),
  ];

  static Set<String> _strip(Set<String> keys, String prefix) => {
    for (final k in keys)
      if (k.startsWith(prefix)) k.substring(prefix.length),
  };

  static ExerciseFilters fromSelection(FilterSelection s) => ExerciseFilters(
    types: _strip(s.of('type'), 'type:'),
    lieux: _strip(s.of('lieu'), 'lieu:'),
    materiels: _strip(s.of('materiel'), 'mat:'),
    niveaux: {
      for (final n in _strip(s.of('niveau'), 'niv:'))
        if (int.tryParse(n) != null) int.parse(n),
    },
  );
}

int difficultyBand(int d) => d <= 3 ? 1 : (d <= 6 ? 2 : 3);

const difficultyBandLabels = {
  1: 'Accessible (1 à 3)',
  2: 'Intermédiaire (4 à 6)',
  3: 'Avancé (7 à 10)',
};

/// Recherche plein texte + filtres, classée par pertinence puis par nom.
/// Les doublons signalés de l'ancienne base ne sont pas listés (leur fiche
/// reste accessible par l'exercice canonique).
List<ExerciseEntry> searchExercises(
  ContentIndex index,
  String q,
  ExerciseFilters filters,
) {
  final query = SearchQuery(q);
  final scored = <(ExerciseEntry, double)>[];
  for (final e in index.entries) {
    if (e.doublonDe != null || !filters.accepts(e)) continue;
    if (query.isEmpty) {
      scored.add((e, 0));
      continue;
    }
    final d = exerciseSearchDoc(index, e.toLegacy());
    if (!query.matches(d.all)) continue;
    scored.add((e, query.score(d)));
  }
  scored.sort((a, b) {
    final c = b.$2.compareTo(a.$2);
    if (c != 0) return c;
    return normalizeText(a.$1.nom).compareTo(normalizeText(b.$1.nom));
  });
  return [for (final s in scored) s.$1];
}

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  /// M4c : filtres gardés pendant la session (rien n'était mémorisé).
  static FilterSelection session = const FilterSelection();

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  final _search = TextEditingController();
  String _q = '';
  FilterSelection _sel = ExerciseLibraryScreen.session;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = store.content;
    final list = searchExercises(
      index,
      _q,
      ExerciseFilters.fromSelection(_sel),
    );
    final header = <Widget>[
      const KPageIntro(
        'Exercices',
        'Fiches, démonstrations et progressions. Repères d’entraînement.',
      ),
      KSearch(
        controller: _search,
        hint: 'Nom, muscle, matériel, lieu…',
        onChanged: (v) => setState(() => _q = v),
      ),
      const SizedBox(height: KSpace.gap),
      FilterMenu(
        key: const ValueKey('library-filter-menu'),
        keyPrefix: 'library',
        categories: ExerciseFilters.categories(index),
        value: _sel,
        onChanged: (v) => setState(() {
          _sel = v;
          ExerciseLibraryScreen.session = v;
        }),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Text(
          '${list.length} exercice${list.length > 1 ? 's' : ''}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    ];
    return KScreen(
      appBar: AppBar(title: const Text('EXERCICES')),
      body: ListView.builder(
        padding: KSpace.content,
        itemCount: header.length + (list.isEmpty ? 1 : list.length),
        itemBuilder: (context, i) {
          if (i < header.length) return header[i];
          if (list.isEmpty) {
            return const KEmpty(
              icon: Icons.search_off,
              title: 'Aucun exercice',
              message: 'Élargis la recherche ou retire un filtre.',
            );
          }
          final e = list[i - header.length];
          return _ExerciseTile(entry: e, index: index);
        },
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final ExerciseEntry entry;
  final ContentIndex index;
  const _ExerciseTile({required this.entry, required this.index});

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(entry.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(
      '${index.typeLabels[entry.type] ?? entry.type} · '
      'difficulté ${entry.difficulte}/10',
      style: TextStyle(fontSize: 12, color: SL.dim),
    ),
    trailing: Icon(Icons.chevron_right, color: SL.dim),
    onTap: () => openExerciseSheet(context, entry.id),
  );
}

// --------------------------------- fiche -----------------------------------

class ExerciseSheetScreen extends StatelessWidget {
  final String id;
  const ExerciseSheetScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final entry = store.content.byId[id];
    return KScreen(
      appBar: AppBar(title: const Text('FICHE EXERCICE')),
      body: FutureBuilder<ContentLibrary>(
        future: ContentLibrary.load(),
        initialData: ContentLibrary.loaded,
        builder: (context, snap) {
          if (snap.hasError) {
            return const Padding(
              padding: KSpace.content,
              child: KEmpty(
                icon: Icons.error_outline,
                title: 'Fiche illisible',
                message: 'Le contenu embarqué n’a pas pu être lu.',
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final lib = snap.data!;
          final d = lib.detail(id);
          if (d == null || entry == null) {
            return const Padding(
              padding: KSpace.content,
              child: KEmpty(
                icon: Icons.help_outline,
                title: 'Exercice inconnu',
                message: 'Cet exercice ne figure pas dans la base.',
              ),
            );
          }
          return _Sheet(entry: entry, detail: d, lib: lib);
        },
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  final ExerciseEntry entry;
  final ExerciseDetail detail;
  final ContentLibrary lib;
  const _Sheet({required this.entry, required this.detail, required this.lib});

  String _name(String id) => store.content.byId[id]?.nom ?? id;

  Widget _bullets(List<String> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final t in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•  ', style: TextStyle(color: SL.accent)),
              Expanded(child: Text(t)),
            ],
          ),
        ),
    ],
  );

  Widget _links(BuildContext context, List<(String, String)> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (id, note) in items)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_name(id)),
          subtitle: note.isEmpty ? null : Text(note),
          trailing: Icon(Icons.chevron_right, color: SL.dim),
          onTap: store.content.byId.containsKey(id)
              ? () => openExerciseSheet(context, id)
              : null,
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final muscles = <(String, List<String>)>[
      ('Principaux', detail.primaires),
      ('Secondaires', detail.secondaires),
      ('Stabilisateurs', detail.stabilisateurs),
      ('Étirés', detail.etires),
    ];
    String muscleName(String m) =>
        atlasMuscles[m]?.nom ?? store.content.muscleLabels[m] ?? m;
    final idx = store.content;
    final sources = lib.sourcesOf(entry.id);
    return KList(
      children: [
        Text(
          entry.nom.toUpperCase(),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            KBadge(idx.typeLabels[entry.type] ?? entry.type),
            KBadge('Difficulté ${entry.difficulte}/10'),
            KBadge(lib.label('mesures', detail.mesure)),
            KBadge(lib.label('modes_charge', detail.modeCharge)),
          ],
        ),
        // 5.5.3 (décision du propriétaire, 29/09/2026) : le mannequin 3D
        // remplace la démonstration 2D en tête de fiche ; il montre les
        // muscles ciblés par l'exercice (repli : carte 2D historique).
        KCard(
          child: ExerciseMannequin(
            key: ValueKey('fiche-muscles-${entry.id}'),
            primaires: detail.primaires,
            secondaires: detail.secondaires,
            stabilisateurs: detail.stabilisateurs,
            etires: detail.etires,
          ),
        ),
        const KSection('Points clés'),
        _bullets(detail.pointsCles),
        const KSection('Erreurs fréquentes'),
        _bullets(detail.erreurs),
        const KSection('Respiration'),
        Text(detail.respiration),
        const KSection('Muscles'),
        KCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (title, ids) in muscles)
                if (ids.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$title : ',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: ids.map(muscleName).join(', ')),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
        if (detail.precautions.isNotEmpty) ...[
          const KSection('Précautions'),
          _bullets([
            for (final p in detail.precautions) lib.label('precautions', p),
          ]),
        ],
        const KSection('Matériel et lieux'),
        Text(
          [
            for (final m in entry.materiel) idx.materielLabels[m] ?? m,
          ].join(', '),
        ),
        Text(
          [for (final l in entry.lieux) idx.lieuLabels[l] ?? l].join(' · '),
          style: TextStyle(color: SL.dim, fontSize: 12.5),
        ),
        if (detail.prerequis.isNotEmpty) ...[
          const KSection('Prérequis'),
          _links(context, detail.prerequis),
        ],
        if (detail.regressions.isNotEmpty) ...[
          const KSection('Régressions (plus facile)'),
          _links(context, [for (final r in detail.regressions) (r, '')]),
        ],
        if (detail.progressions.isNotEmpty) ...[
          const KSection('Progressions (plus difficile)'),
          _links(context, [for (final p in detail.progressions) (p, '')]),
        ],
        if (detail.varianteDe != null &&
            store.content.byId.containsKey(detail.varianteDe)) ...[
          const KSection('Variante de'),
          _links(context, [(detail.varianteDe!, '')]),
        ],
        if (sources.isNotEmpty)
          KCard(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              title: const Text('Sources consultées'),
              subtitle: Text(
                '${sources.length} référence${sources.length > 1 ? 's' : ''} ; aucun texte repris',
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              children: [
                for (final s in sources)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${s['entree'] ?? ''} — ${s['url'] ?? ''}',
                      style: TextStyle(fontSize: 12, color: SL.dim),
                    ),
                  ),
              ],
            ),
          ),
        Text(
          'Repères d’entraînement, sans valeur médicale. Contenu non relu par '
          'un professionnel diplômé : en cas de gêne, arrête l’exercice.',
          style: TextStyle(fontSize: 12, color: SL.dim),
        ),
      ],
    );
  }
}

// -------------------------------- mentions ---------------------------------

/// Sources et licences du pack de contenu (assets/content/licences.md).
class MentionsScreen extends StatelessWidget {
  const MentionsScreen({super.key});

  static const asset = 'assets/content/licences.md';

  /// M2 : crédits du modèle anatomique 3D (CC BY-SA 4.0), texte exact.
  static const anatomyAsset = 'assets/anatomy/ATTRIBUTION.md';

  static Future<String> _load() async {
    final content = await rootBundle.loadString(asset);
    String anatomy = '';
    try {
      anatomy = await rootBundle.loadString(anatomyAsset);
    } catch (_) {}
    return anatomy.isEmpty ? content : '$anatomy\n\n$content';
  }

  @override
  Widget build(BuildContext context) => KScreen(
    appBar: AppBar(title: const Text('SOURCES ET LICENCES')),
    body: FutureBuilder<String>(
      future: _load(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return KList(children: markdownBlocks(context, snap.data!));
      },
    ),
  );
}

String _plain(String s) =>
    s.replaceAll('**', '').replaceAll('`', '').replaceAll(RegExp(r'\*'), '');

/// Rendu simple du Markdown des mentions : titres, paragraphes, listes et
/// tableaux (une carte par ligne, « colonne : valeur »), lisible à 320 px.
List<Widget> markdownBlocks(BuildContext context, String md) {
  final out = <Widget>[];
  final lines = md.split('\n');
  var i = 0;
  while (i < lines.length) {
    final line = lines[i].trimRight();
    if (line.trim().isEmpty) {
      i++;
      continue;
    }
    if (line.startsWith('#')) {
      final level = line.indexOf(' ');
      final text = _plain(line.substring(level + 1));
      out.add(
        level <= 1
            ? Text(
                text.toUpperCase(),
                style: Theme.of(context).textTheme.titleLarge,
              )
            : KSection(text),
      );
      i++;
      continue;
    }
    if (line.startsWith('|')) {
      List<String> cells(String l) => [
        for (final c in l.trim().replaceAll(RegExp(r'^\||\|$'), '').split('|'))
          _plain(c.trim()),
      ];
      final head = cells(line);
      i++;
      if (i < lines.length && lines[i].contains('---')) i++;
      while (i < lines.length && lines[i].trimLeft().startsWith('|')) {
        final row = cells(lines[i]);
        out.add(
          KCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var c = 0; c < row.length; c++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          if (c < head.length)
                            TextSpan(
                              text: '${head[c]} : ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          TextSpan(text: row[c]),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
        i++;
      }
      continue;
    }
    if (line.startsWith('- ')) {
      out.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('•  ', style: TextStyle(color: SL.accent)),
            Expanded(child: Text(_plain(line.substring(2)))),
          ],
        ),
      );
      i++;
      continue;
    }
    out.add(Text(_plain(line)));
    i++;
  }
  return out;
}
