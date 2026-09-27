// Bibliothèque d'exercices, fiche exercice et mentions (L9b, KT-080/082).
// La fiche réunit démonstration animée, points clés, erreurs fréquentes,
// respiration, muscles (atlas + texte), précautions, prérequis, progressions
// et régressions navigables. Les consignes sont des repères d'entraînement.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'app_theme.dart';
import 'atlas.dart';
import 'atlas_data.dart';
import 'content_pack.dart';
import 'pose_engine.dart';
import 'pose_painter.dart';
import 'search.dart';
import 'store.dart';
import 'ui.dart';

/// Ouvre la fiche d'un exercice de la base v2.
Future<void> openExerciseSheet(BuildContext context, String id) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => ExerciseSheetScreen(id: id)));

// ------------------------------- recherche ---------------------------------

/// Filtres de la bibliothèque (null = tous).
class ExerciseFilters {
  final String? type, lieu, materiel;

  /// Tranche de difficulté : 1 (1-3), 2 (4-6), 3 (7-10).
  final int? niveau;
  const ExerciseFilters({this.type, this.lieu, this.materiel, this.niveau});

  bool accepts(ExerciseEntry e) =>
      (type == null || e.type == type) &&
      (lieu == null || e.lieux.contains(lieu)) &&
      (materiel == null || e.materiel.contains(materiel)) &&
      (niveau == null || difficultyBand(e.difficulte) == niveau);
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

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  final _search = TextEditingController();
  String _q = '';
  ExerciseFilters _f = const ExerciseFilters();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required Map<T, String> options,
    required ValueChanged<T?> onChanged,
  }) => DropdownButtonFormField<T?>(
    value: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [
      DropdownMenuItem<T?>(value: null, child: const Text('Tous')),
      for (final e in options.entries)
        DropdownMenuItem<T?>(
          value: e.key,
          child: Text(e.value, overflow: TextOverflow.ellipsis),
        ),
    ],
    onChanged: onChanged,
  );

  @override
  Widget build(BuildContext context) {
    final index = store.content;
    final list = searchExercises(index, _q, _f);
    final materiel = <String, String>{
      for (final e in index.materielLabels.entries)
        if (e.key != 'aucun') e.key: e.value,
    };
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
      _dropdown<String>(
        label: 'Type de mouvement',
        value: _f.type,
        options: index.typeLabels,
        onChanged:
            (v) => setState(
              () =>
                  _f = ExerciseFilters(
                    type: v,
                    lieu: _f.lieu,
                    materiel: _f.materiel,
                    niveau: _f.niveau,
                  ),
            ),
      ),
      const SizedBox(height: KSpace.gap),
      _dropdown<String>(
        label: 'Lieu',
        value: _f.lieu,
        options: index.lieuLabels,
        onChanged:
            (v) => setState(
              () =>
                  _f = ExerciseFilters(
                    type: _f.type,
                    lieu: v,
                    materiel: _f.materiel,
                    niveau: _f.niveau,
                  ),
            ),
      ),
      const SizedBox(height: KSpace.gap),
      _dropdown<String>(
        label: 'Matériel',
        value: _f.materiel,
        options: materiel,
        onChanged:
            (v) => setState(
              () =>
                  _f = ExerciseFilters(
                    type: _f.type,
                    lieu: _f.lieu,
                    materiel: v,
                    niveau: _f.niveau,
                  ),
            ),
      ),
      const SizedBox(height: KSpace.gap),
      _dropdown<int>(
        label: 'Difficulté',
        value: _f.niveau,
        options: difficultyBandLabels,
        onChanged:
            (v) => setState(
              () =>
                  _f = ExerciseFilters(
                    type: _f.type,
                    lieu: _f.lieu,
                    materiel: _f.materiel,
                    niveau: v,
                  ),
            ),
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
      'difficulté ${entry.difficulte}/10'
      '${entry.demo == 'indisponible' ? ' · sans démonstration' : ''}',
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
          onTap:
              store.content.byId.containsKey(id)
                  ? () => openExerciseSheet(context, id)
                  : null,
        ),
    ],
  );

  Widget _demo() {
    final motif = detail.demoMotif;
    final pose = lib.poseOf(entry.id);
    if (detail.demoStatut == 'indisponible' || pose == null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: SL.dim),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Démonstration indisponible'
              '${motif == null ? '' : ' : $motif'}. '
              'Suis les points clés et l’atlas ci-dessous.',
            ),
          ),
        ],
      );
    }
    var anim = PoseAnimation.fromPack(pose.$1, pose.$2);
    if (detail.demoStatut == 'statique') {
      // Geste hors du plan de la vue : position de départ seulement.
      anim = PoseAnimation(
        view: anim.view,
        loop: anim.loop,
        keyframes: [anim.keyframes.first],
        props: anim.props,
        primaires: anim.primaires,
        secondaires: anim.secondaires,
        statut: anim.statut,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PoseDemo(pose: anim, label: entry.nom),
        if (detail.demoStatut == 'statique')
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Position de départ seulement${motif == null ? '' : ' : $motif'}.',
              style: TextStyle(fontSize: 12, color: SL.dim),
            ),
          ),
      ],
    );
  }

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
        KCard(child: _demo()),
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
              ExerciseAtlas(
                primaires: detail.primaires,
                secondaires: detail.secondaires,
                stabilisateurs: detail.stabilisateurs,
                etires: detail.etires,
              ),
              const SizedBox(height: 12),
              const AtlasRoleLegend(),
              const SizedBox(height: 12),
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

  @override
  Widget build(BuildContext context) => KScreen(
    appBar: AppBar(title: const Text('SOURCES ET LICENCES')),
    body: FutureBuilder<String>(
      future: rootBundle.loadString(asset),
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
