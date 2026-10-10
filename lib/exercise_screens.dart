// Bibliothèque d'exercices, fiche exercice et mentions.
// G3 (D4.10) : la base v1.1 du propriétaire (1 039 exercices, 8
// disciplines, `kalis_core`) remplace le pack 2.0.0. La fiche réunit
// démonstration (si l'exercice en a une), points clés, erreurs fréquentes,
// respiration, muscles (carte 2D par rôle ; liste en texte, muscles profonds
// compris), matériel et lieux, paliers conseillés et variantes navigables.
// Les consignes sont des repères d'entraînement.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'anatomy_screen.dart';
import 'atlas.dart' show mapGroupsOfAtlasMuscles;
import 'content_pack.dart';
import 'exercise_mannequin.dart';
import 'filter_menu.dart';
import 'kit/kit.dart';
import 'mannequin_clip.dart';
import 'muscle_map_2d.dart';
import 'search.dart';
import 'store.dart';
import 'ui.dart' show kPageColor;

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

/// UI4 : l'exercice sollicite un groupe de la carte 2D (filtre de
/// l'Anatomie) par ses muscles principaux ou secondaires dessinés.
bool exerciseWorksMapGroup(ExerciseEntry e, String group) =>
    mapGroupsOfAtlasMuscles([
      for (final m in [...e.ex.primaryMuscles, ...e.ex.secondaryMuscles])
        ...atlasOfBaseMuscle(m),
    ]).contains(group);

/// Marges d'une liste de sous-page : marge d'écran, réserve basse du dock
/// ou de la zone système (comme `KPage`).
EdgeInsets _listPadding(BuildContext context) {
  final inset = KNavigationInset.of(context);
  final bottom = inset > 0 ? inset : MediaQuery.paddingOf(context).bottom;
  return EdgeInsets.fromLTRB(
    KSpacing.page,
    KSpacing.s8,
    KSpacing.page,
    KSpacing.s24 + bottom,
  );
}

/// Corps d'une sous-page : largeur de lecture maximale, centré.
Widget _framed(Widget child) => SafeArea(
  top: false,
  bottom: false,
  child: Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: KSpacing.maxWidth),
      child: child,
    ),
  ),
);

/// Bibliothèque « Exercices » (Arsenal › Exercices).
///
/// UI4 : [initialQuery] ouvre la liste sur une recherche (recherche de la
/// racine d'Arsenal, « Voir les n exercices ») ; [muscleGroup] la filtre
/// sur un groupe de la carte (Anatomie › « Exercices pour ce muscle »),
/// filtre retirable par sa puce. Même moteur : [searchExercises].
class ExerciseLibraryScreen extends StatefulWidget {
  final String initialQuery;
  final String? muscleGroup;
  const ExerciseLibraryScreen({
    super.key,
    this.initialQuery = '',
    this.muscleGroup,
  });

  /// M4c : filtres gardés pendant la session (rien n'était mémorisé).
  static FilterSelection session = const FilterSelection();

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  final _search = TextEditingController();
  String _q = '';
  FilterSelection _sel = ExerciseLibraryScreen.session;
  String? _group;

  /// Exercices du groupe [_group] (calculés une fois par écran).
  Set<String>? _groupIds;

  Set<String> _idsOf(String group) => _groupIds ??= {
    for (final e in store.content.entries)
      if (exerciseWorksMapGroup(e, group)) e.id,
  };

  @override
  void initState() {
    super.initState();
    _q = widget.initialQuery;
    _search.text = widget.initialQuery;
    _group = widget.muscleGroup;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearSearch() => setState(() {
    _search.clear();
    _q = '';
  });

  void _resetFilters() => setState(() {
    _sel = const FilterSelection();
    ExerciseLibraryScreen.session = _sel;
    _group = null;
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final index = store.content;
    final group = _group;
    final found = searchExercises(
      index,
      _q,
      ExerciseFilters.fromSelection(_sel),
    );
    final ids = group == null ? null : _idsOf(group);
    final list = ids == null
        ? found
        : [
            for (final e in found)
              if (ids.contains(e.id)) e,
          ];
    final header = <Widget>[
      const KLead(
        'Base d’exercices : 8 disciplines, fiches et progressions. '
        'Repères d’entraînement.',
      ),
      KSearchField(
        controller: _search,
        hint: 'Rechercher un exercice',
        onChanged: (v) => setState(() => _q = v),
      ),
      const SizedBox(height: KSpacing.s12),
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
      if (group != null)
        Padding(
          padding: const EdgeInsets.only(top: KSpacing.s8),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: KChip(
              'Groupe musculaire : ${mapGroupLabel(group)}',
              key: const ValueKey('library-muscle-chip'),
              selected: true,
              deleteLabel: 'Retirer le filtre',
              onDeleted: () => setState(() => _group = null),
            ),
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(top: KSpacing.s12, bottom: KSpacing.s4),
        child: Text(
          '${list.length} exercice${list.length > 1 ? 's' : ''}',
          key: const ValueKey('library-count'),
          style: KType.detail.copyWith(color: k.texte2),
        ),
      ),
    ];
    return Scaffold(
      appBar: KTopBar.sub(
        title: 'Exercices',
        subtitle: group == null ? null : mapGroupLabel(group),
      ),
      body: _framed(
        ListView.builder(
          padding: _listPadding(context),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: header.length + (list.isEmpty ? 1 : list.length),
          itemBuilder: (context, i) {
            if (i < header.length) return header[i];
            if (list.isEmpty) {
              // R6 : l'état vide propose l'action qui le résout.
              final searching = _q.trim().isNotEmpty;
              return KEmpty(
                key: const ValueKey('library-empty'),
                icon: Icons.search_off,
                title: 'Aucun exercice',
                message: 'Élargis la recherche ou retire un filtre.',
                action: searching
                    ? 'Effacer la recherche'
                    : 'Réinitialiser les filtres',
                onAction: searching ? _clearSearch : _resetFilters,
              );
            }
            final e = list[i - header.length];
            return KMenuRow(
              key: ValueKey('library-ex-${e.id}'),
              title: e.nom,
              subtitle:
                  '${e.discipline} · ${e.niveau} · '
                  'difficulté ${e.difficulte}/10',
              onTap: () => openExerciseSheet(context, e.id),
            );
          },
        ),
      ),
    );
  }
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
    if (d == null || entry == null) {
      return KPage.sub(
        title: 'Exercice',
        children: [
          KEmpty(
            icon: Icons.help_outline,
            title: 'Exercice inconnu',
            message: 'Cet exercice ne figure pas dans la base.',
            action: 'Retour',
            onAction: () => Navigator.maybePop(context),
          ),
        ],
      );
    }
    // M8 : la fiche s'affiche tout de suite ; la tête (démonstration, si
    // l'exercice a une animation) apparaît dès le registre lu (déjà lu au
    // lancement par le préchargement).
    return FutureBuilder<ClipRegistry?>(
      future: _load(),
      initialData: ClipRegistry.loaded,
      builder: (context, _) => _Sheet(entry: entry, detail: d),
    );
  }
}

class _Sheet extends StatelessWidget {
  final ExerciseEntry entry;
  final ExerciseDetail detail;
  const _Sheet({required this.entry, required this.detail});

  String _name(String id) => store.content.byId[id]?.nom ?? id;

  Widget _bullets(KTokens k, List<String> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final t in items)
        Padding(
          padding: const EdgeInsets.only(bottom: KSpacing.s8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•  ', style: KType.corps.copyWith(color: k.texte2)),
              Expanded(
                child: Text(t, style: KType.corps.copyWith(color: k.texte)),
              ),
            ],
          ),
        ),
    ],
  );

  Widget _links(BuildContext context, String key, List<String> ids) =>
      KMenuGroup(
        key: ValueKey('fiche-$key'),
        dividerIndent: KSpacing.s16,
        children: [
          for (final id in ids)
            KMenuRow(
              title: _name(id),
              subtitle: store.content.byId[id] == null
                  ? null
                  : '${store.content.byId[id]!.niveau} · difficulté '
                        '${store.content.byId[id]!.difficulte}/10',
              onTap: store.content.byId.containsKey(id)
                  ? () => openExerciseSheet(context, id)
                  : null,
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final body = KType.corps.copyWith(color: k.texte);
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
    // UI4 : groupes de la carte sollicités, chacun ouvre l'Anatomie.
    final groups = mapGroupsOfAtlasMuscles([
      ...detail.primaires,
      ...detail.secondaires,
      ...detail.stabilisateurs,
    ]);
    final variantOf = detail.varianteDe;
    final variants = detail.variantes;
    final children = <Widget>[
      if (entry.alias.isNotEmpty)
        Text(
          'Aussi : ${entry.alias.join(' · ')}',
          style: KType.detail.copyWith(color: k.texte2),
        ),
      Wrap(
        spacing: KSpacing.s8,
        runSpacing: KSpacing.s8,
        children: [
          KChip(entry.discipline),
          KChip(entry.niveau),
          KChip('Difficulté ${entry.difficulte}/10'),
          KChip(kLoadTypeLabels[detail.typeCharge] ?? detail.typeCharge),
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
      const KSectionTitle('Points clés'),
      KeyedSubtree(
        key: const ValueKey('fiche-points-cles'),
        child: _bullets(k, detail.pointsCles),
      ),
      const KSectionTitle('Erreurs fréquentes'),
      KeyedSubtree(
        key: const ValueKey('fiche-erreurs'),
        child: _bullets(k, detail.erreurs),
      ),
      const KSectionTitle('Respiration'),
      Text(
        detail.respiration,
        key: const ValueKey('fiche-respiration'),
        style: body,
      ),
      const KSectionTitle('Muscles'),
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
            const SizedBox(height: KSpacing.s12),
            MapRoleLegend(stabilizers: detail.stabilisateurs.isNotEmpty),
            if (deep.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: KSpacing.s8),
                child: Text(
                  'Non dessinés sur la carte : '
                  '${deep.map(baseMuscleLabel).join(', ')}.',
                  key: const ValueKey('fiche-muscles-profonds'),
                  textAlign: TextAlign.center,
                  style: KType.detail.copyWith(color: k.texte2),
                ),
              ),
            const SizedBox(height: KSpacing.s14),
            for (final (title, names) in muscles)
              if (names.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: KSpacing.s8),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$title : ',
                          style: KType.corpsFort.copyWith(color: k.texte),
                        ),
                        TextSpan(text: names.map(baseMuscleLabel).join(', ')),
                      ],
                    ),
                    style: body,
                  ),
                ),
            if (groups.isNotEmpty) ...[
              const SizedBox(height: KSpacing.s4),
              Text(
                'Voir un groupe dans l’Anatomie :',
                style: KType.detail.copyWith(color: k.texte2),
              ),
              Wrap(
                key: const ValueKey('fiche-groupes'),
                spacing: KSpacing.s8,
                children: [
                  for (final g in groups)
                    KChip(
                      mapGroupLabel(g),
                      key: ValueKey('fiche-groupe-$g'),
                      icon: Icons.accessibility_new_rounded,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AnatomyScreen(initialGroup: g),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      const KSectionTitle('Matériel et lieux'),
      Text(
        entry.materiel.isEmpty
            ? 'Aucun matériel'
            : entry.materiel.map(capitalized).join(', '),
        key: const ValueKey('fiche-materiel'),
        style: body,
      ),
      Text(
        [for (final l in entry.lieux) kPlaceLabels[l] ?? l].join(' · '),
        style: KType.detail.copyWith(color: k.texte2),
      ),
      if (detail.prerequis.isNotEmpty) ...[
        const KSectionTitle('Paliers conseillés avant'),
        _links(context, 'prerequis', detail.prerequis),
      ],
      if (variantOf != null && store.content.byId.containsKey(variantOf)) ...[
        const KSectionTitle('Variante de'),
        _links(context, 'variante-de', [variantOf]),
      ],
      if (variants.isNotEmpty) ...[
        const KSectionTitle('Variantes'),
        _links(context, 'variantes', variants),
      ],
      Text(
        'Repères d’entraînement, sans valeur médicale. Contenu non relu par '
        'un professionnel diplômé : en cas de gêne, arrête l’exercice.',
        style: KType.detail.copyWith(color: k.texte2),
      ),
    ];
    return Scaffold(
      // R3, C1 : le titre de la fiche est le nom de l'exercice (capitales
      // par le style, U3).
      appBar: KTopBar.sub(key: const ValueKey('fiche-titre'), title: entry.nom),
      body: _framed(
        ListView.separated(
          padding: _listPadding(context),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: children.length,
          separatorBuilder: (_, __) => const SizedBox(height: KSpacing.s8),
          itemBuilder: (_, i) => children[i],
        ),
      ),
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
  Widget build(BuildContext context) => Scaffold(
    appBar: const KTopBar.sub(title: 'Sources et licences'),
    body: FutureBuilder<String>(
      future: _load(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final blocks = markdownBlocks(context, snap.data!);
        return _framed(
          ListView.separated(
            padding: _listPadding(context),
            itemCount: blocks.length,
            separatorBuilder: (_, __) => const SizedBox(height: KSpacing.s12),
            itemBuilder: (_, i) => blocks[i],
          ),
        );
      },
    ),
  );
}

String _plain(String s) =>
    s.replaceAll('**', '').replaceAll('`', '').replaceAll(RegExp(r'\*'), '');

/// Rendu simple du Markdown des mentions : titres, paragraphes, listes et
/// tableaux (une carte par ligne, « colonne : valeur »), lisible à 320 px.
List<Widget> markdownBlocks(BuildContext context, String md) {
  final k = KTokens.of(context);
  final body = KType.corps.copyWith(color: k.texte);
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
            // Titre du document : capitales par le style (U3).
            ? Semantics(
                header: true,
                child: Text(
                  k.title(text),
                  style: k.titleStyle(
                    KType.titreCarte.copyWith(color: k.texte),
                  ),
                ),
              )
            : KSectionTitle(text),
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
                    padding: const EdgeInsets.only(bottom: KSpacing.s4),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          if (c < head.length)
                            TextSpan(
                              text: '${head[c]} : ',
                              style: KType.corpsFort.copyWith(color: k.texte),
                            ),
                          TextSpan(text: row[c]),
                        ],
                      ),
                      style: body,
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
            Text('•  ', style: KType.corps.copyWith(color: k.texte2)),
            Expanded(child: Text(_plain(line.substring(2)), style: body)),
          ],
        ),
      );
      i++;
      continue;
    }
    out.add(Text(_plain(line), style: body));
    i++;
  }
  return out;
}
