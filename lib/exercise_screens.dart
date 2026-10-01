// Bibliothèque d'exercices, fiche exercice et mentions.
// G3 (D4.10) : la base v1.1 du propriétaire (1 039 exercices, 8
// disciplines, `kalis_core`) remplace le pack 2.0.0. La fiche réunit
// démonstration (si l'exercice en a une), points clés, erreurs fréquentes,
// respiration, muscles (carte 2D par rôle ; liste en texte, muscles profonds
// compris), matériel et lieux, paliers conseillés et variantes navigables.
// Les consignes sont des repères d'entraînement.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'app_theme.dart';
import 'content_pack.dart';
import 'exercise_mannequin.dart';
import 'mannequin_clip.dart';
import 'muscle_map_2d.dart';
import 'filter_menu.dart';
import 'search.dart';
import 'store.dart';
import 'ui.dart';

/// Ouvre la fiche d'un exercice de la base v1.1.
Future<void> openExerciseSheet(BuildContext context, String id) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => ExerciseSheetScreen(id: id)));

// ------------------------------- recherche ---------------------------------

/// Filtres de la bibliothèque (ensemble vide = tous).
///
/// M4c : plusieurs choix par catégorie (union), catégories combinées
/// (intersection), dans le menu « Filtres » commun. G3 : discipline, type de
/// mouvement (famille), niveau, lieu, matériel et difficulté de la base v1.1.
class ExerciseFilters {
  final Set<String> disciplines, familles, niveaux, lieux, materiels;

  /// Tranches de difficulté : 1 (1-3), 2 (4-6), 3 (7-10).
  final Set<int> difficultes;
  const ExerciseFilters({
    this.disciplines = const {},
    this.familles = const {},
    this.niveaux = const {},
    this.lieux = const {},
    this.materiels = const {},
    this.difficultes = const {},
  });

  bool accepts(ExerciseEntry e) =>
      (disciplines.isEmpty || disciplines.contains(e.discipline)) &&
      (familles.isEmpty || familles.contains(e.famille)) &&
      (niveaux.isEmpty || niveaux.contains(e.niveau)) &&
      (lieux.isEmpty || lieux.any(e.lieux.contains)) &&
      (materiels.isEmpty || materiels.any(e.materiel.contains)) &&
      (difficultes.isEmpty ||
          difficultes.contains(difficultyBand(e.difficulte)));

  /// Catégories du menu « Filtres » (clés préfixées : uniques dans le menu).
  static List<FilterCategory> categories(ContentIndex index) {
    List<String> present(String Function(ExerciseEntry) f) {
      final seen = <String>{};
      return [
        for (final e in index.entries)
          if (seen.add(f(e))) f(e),
      ];
    }

    final disciplines = present((e) => e.discipline);
    final niveaux = present((e) => e.niveau);
    final familles = [
      for (final k in kCatalogFamilyLabels.keys)
        if (index.entries.any((e) => e.famille == k)) k,
    ];
    return [
      FilterCategory(
        id: 'discipline',
        label: 'Discipline',
        options: [for (final d in disciplines) FilterOption('disc:$d', d)],
      ),
      FilterCategory(
        id: 'famille',
        label: 'Type de mouvement',
        options: [
          for (final f in familles)
            FilterOption('fam:$f', kCatalogFamilyLabels[f]!),
        ],
      ),
      FilterCategory(
        id: 'niveau',
        label: 'Niveau',
        options: [for (final n in niveaux) FilterOption('lvl:$n', n)],
      ),
      FilterCategory(
        id: 'lieu',
        label: 'Lieu',
        options: [
          for (final e in kPlaceLabels.entries)
            FilterOption('lieu:${e.key}', e.value),
        ],
      ),
      FilterCategory(
        id: 'materiel',
        label: 'Matériel',
        options: [
          for (final m in index.equipmentVocabulary)
            FilterOption('mat:$m', capitalized(m)),
        ],
      ),
      FilterCategory(
        id: 'difficulte',
        label: 'Difficulté',
        options: [
          for (final e in difficultyBandLabels.entries)
            FilterOption('dif:${e.key}', e.value),
        ],
      ),
    ];
  }

  static Set<String> _strip(Set<String> keys, String prefix) => {
    for (final k in keys)
      if (k.startsWith(prefix)) k.substring(prefix.length),
  };

  static ExerciseFilters fromSelection(FilterSelection s) => ExerciseFilters(
    disciplines: _strip(s.of('discipline'), 'disc:'),
    familles: _strip(s.of('famille'), 'fam:'),
    niveaux: _strip(s.of('niveau'), 'lvl:'),
    lieux: _strip(s.of('lieu'), 'lieu:'),
    materiels: _strip(s.of('materiel'), 'mat:'),
    difficultes: {
      for (final n in _strip(s.of('difficulte'), 'dif:'))
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
List<ExerciseEntry> searchExercises(
  ContentIndex index,
  String q,
  ExerciseFilters filters,
) {
  final query = SearchQuery(q);
  final scored = <(ExerciseEntry, double)>[];
  for (final e in index.entries) {
    if (!filters.accepts(e)) continue;
    if (query.isEmpty) {
      scored.add((e, 0));
      continue;
    }
    final d = e.searchDoc;
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
        'Base d’exercices : 8 disciplines, fiches et progressions. '
            'Repères d’entraînement.',
      ),
      KSearch(
        controller: _search,
        hint: 'Nom, muscle, matériel, discipline…',
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
          key: const ValueKey('library-count'),
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
          return _ExerciseTile(key: ValueKey('library-ex-${e.id}'), entry: e);
        },
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final ExerciseEntry entry;
  const _ExerciseTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(entry.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(
      '${entry.discipline} · ${entry.niveau} · '
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

  static Future<ClipRegistry?> _load() async {
    try {
      return await ClipRegistry.load();
    } catch (_) {
      // Registre illisible : aucune démonstration, la fiche s'affiche.
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = store.content.detail(id);
    final entry = store.content.byId[id];
    return KScreen(
      appBar: AppBar(title: const Text('FICHE EXERCICE')),
      body: d == null || entry == null
          ? const Padding(
              padding: KSpace.content,
              child: KEmpty(
                icon: Icons.help_outline,
                title: 'Exercice inconnu',
                message: 'Cet exercice ne figure pas dans la base.',
              ),
            )
          // M8 : la fiche s'affiche tout de suite ; la tête (démonstration,
          // si l'exercice a une animation) apparaît dès le registre lu
          // (déjà lu au lancement par le préchargement).
          : FutureBuilder<ClipRegistry?>(
              future: _load(),
              initialData: ClipRegistry.loaded,
              builder: (context, _) => _Sheet(entry: entry, detail: d),
            ),
    );
  }
}

class _Sheet extends StatelessWidget {
  final ExerciseEntry entry;
  final ExerciseDetail detail;
  const _Sheet({required this.entry, required this.detail});

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

  Widget _links(BuildContext context, String key, List<String> ids) => Column(
    key: ValueKey('fiche-$key'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final id in ids)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_name(id)),
          subtitle: store.content.byId[id] == null
              ? null
              : Text(
                  '${store.content.byId[id]!.niveau} · difficulté '
                  '${store.content.byId[id]!.difficulte}/10',
                  style: TextStyle(fontSize: 12, color: SL.dim),
                ),
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
      ('Principaux', detail.musclesPrincipaux),
      ('Secondaires', detail.musclesSecondaires),
      ('Stabilisateurs', detail.musclesStabilisateurs),
      ('Étirés', detail.musclesEtires),
    ];
    // Muscles sollicités que la carte ne dessine pas (profonds).
    final deep = [
      for (final m in {
        ...detail.musclesPrincipaux,
        ...detail.musclesSecondaires,
        ...detail.musclesStabilisateurs,
      })
        if (!atlasOfBaseMuscle(m).any(mapDrawsMuscle)) m,
    ];
    final variantOf = detail.varianteDe;
    final variants = detail.variantes;
    return KList(
      children: [
        Text(
          entry.nom.toUpperCase(),
          key: const ValueKey('fiche-titre'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (entry.alias.isNotEmpty)
          Text(
            'Aussi : ${entry.alias.join(' · ')}',
            style: TextStyle(fontSize: 12.5, color: SL.dim),
          ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            KBadge(entry.discipline),
            KBadge(entry.niveau),
            KBadge('Difficulté ${entry.difficulte}/10'),
            KBadge(kLoadTypeLabels[detail.typeCharge] ?? detail.typeCharge),
          ],
        ),
        // M8 (propriétaire, 30/09/2026) : la 3D ne sert qu'à la
        // démonstration ; en tête de fiche seulement si l'exercice a une
        // animation (G3 : anciennes démonstrations reliées par la
        // correspondance), rien sinon.
        if (ClipRegistry.loaded?.forExercise(entry.id) != null)
          KeyedSubtree(
            key: const ValueKey('fiche-mannequin-support'),
            child: ExerciseMannequin(
              key: ValueKey('fiche-muscles-${entry.id}'),
              background: kPageColor(context),
              exerciseId: entry.id,
              height: (MediaQuery.sizeOf(context).height * .45).clamp(
                380.0,
                600.0,
              ),
              primaires: detail.primaires,
              secondaires: detail.secondaires,
              stabilisateurs: detail.stabilisateurs,
              etires: detail.etires,
            ),
          ),
        const KSection('Points clés'),
        KeyedSubtree(
          key: const ValueKey('fiche-points-cles'),
          child: _bullets(detail.pointsCles),
        ),
        const KSection('Erreurs fréquentes'),
        KeyedSubtree(
          key: const ValueKey('fiche-erreurs'),
          child: _bullets(detail.erreurs),
        ),
        const KSection('Respiration'),
        Text(detail.respiration, key: const ValueKey('fiche-respiration')),
        const KSection('Muscles'),
        KCard(
          key: const ValueKey('fiche-muscles'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // M8 : carte 2D par rôle (principal vif, secondaire atténué,
              // stabilisateur pâle, autres en gris), muscle par muscle.
              MuscleMap2D(
                key: ValueKey('fiche-muscle-map-${entry.id}'),
                intensities: mapIntensitiesFromRoles(
                  primaires: detail.primaires,
                  secondaires: detail.secondaires,
                  stabilisateurs: detail.stabilisateurs,
                ),
                height: 250,
                semanticLabel: 'Carte des muscles de l’exercice',
              ),
              const SizedBox(height: 10),
              MapRoleLegend(stabilizers: detail.stabilisateurs.isNotEmpty),
              if (deep.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Non dessinés sur la carte : '
                    '${deep.map(baseMuscleLabel).join(', ')}.',
                    key: const ValueKey('fiche-muscles-profonds'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: SL.dim),
                  ),
                ),
              const SizedBox(height: 14),
              for (final (title, names) in muscles)
                if (names.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$title : ',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: names.map(baseMuscleLabel).join(', ')),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
        const KSection('Matériel et lieux'),
        Text(
          entry.materiel.isEmpty
              ? 'Aucun matériel'
              : entry.materiel.map(capitalized).join(', '),
          key: const ValueKey('fiche-materiel'),
        ),
        Text(
          [for (final l in entry.lieux) kPlaceLabels[l] ?? l].join(' · '),
          style: TextStyle(color: SL.dim, fontSize: 12.5),
        ),
        if (detail.prerequis.isNotEmpty) ...[
          const KSection('Paliers conseillés avant'),
          _links(context, 'prerequis', detail.prerequis),
        ],
        if (variantOf != null && store.content.byId.containsKey(variantOf)) ...[
          const KSection('Variante de'),
          _links(context, 'variante-de', [variantOf]),
        ],
        if (variants.isNotEmpty) ...[
          const KSection('Variantes'),
          _links(context, 'variantes', variants),
        ],
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
