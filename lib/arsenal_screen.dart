import 'package:flutter/material.dart';

import 'anatomy_screen.dart';
import 'atlas.dart' show mapGroupOfAtlasMuscle;
import 'atlas_data.dart';
import 'dev/dev_widgets.dart' show HeaderLogo;
import 'exercise_screens.dart';
import 'kit/kit.dart';
import 'muscle_map_2d.dart';
import 'search.dart';
import 'store.dart';

/// Onglet Arsenal — référence : fiches d'exercices et anatomie. G2 : les
/// séances manuelles et les WOD ont été retirés (D1.1), l'application se
/// recentre sur le programme.
///
/// UI4 (cahier §4.1, §4.4) : gabarit « menu racine » ; recherche directe
/// « Exercice ou muscle » : résultats groupés « Exercices » (moteur de la
/// bibliothèque) puis « Muscles » (groupes et muscles de l'atlas, même règle
/// de correspondance) ; groupe « Consulter » (Exercices, Anatomie).
class ArsenalScreen extends StatefulWidget {
  const ArsenalScreen({super.key});

  /// Exercices montrés avant « Voir les n exercices ».
  static const exerciseLimit = 5;

  /// Muscles montrés avant « Afficher plus ».
  static const muscleLimit = 6;

  @override
  State<ArsenalScreen> createState() => _ArsenalScreenState();
}

/// Résultat « Muscles » de la recherche d'Arsenal : un groupe de la carte
/// ou un muscle de l'atlas, et le groupe sur lequel l'Anatomie s'ouvre.
@immutable
class MuscleSearchHit {
  /// Identifiant : groupe de la carte ou muscle de l'atlas.
  final String id;
  final String label;

  /// Groupe de la carte ouvert dans l'Anatomie.
  final String group;
  final bool isGroup;

  /// Muscle profond ou hors des groupes de la carte : l'Anatomie s'ouvre
  /// sur le groupe le plus proche (groupe historique du muscle).
  final bool approximate;
  final SearchDoc doc;

  MuscleSearchHit({
    required this.id,
    required this.label,
    required this.group,
    required this.isGroup,
    this.approximate = false,
  }) : doc = SearchDoc(name: label, meta: mapGroupLabel(group));

  /// Description de la ligne.
  String get subtitle {
    if (isGroup) return 'Groupe musculaire';
    final name = mapGroupLabel(group);
    return approximate ? 'Muscle non dessiné · voir $name' : 'Muscle · $name';
  }
}

/// Index des muscles : les groupes de la carte, puis les muscles de l'atlas
/// (un muscle sans groupe sur la carte prend le premier groupe de son
/// groupe historique).
final List<MuscleSearchHit> kMuscleSearchIndex = () {
  final out = <MuscleSearchHit>[
    for (final g in kMapGroups)
      MuscleSearchHit(id: g.id, label: g.label, group: g.id, isGroup: true),
  ];
  for (final e in atlasMuscles.entries) {
    final drawn = mapGroupOfAtlasMuscle(e.key);
    final legacy = kAppGroupToMap[e.value.groupe];
    final group =
        drawn ?? (legacy == null || legacy.isEmpty ? null : legacy.first);
    if (group == null) continue;
    out.add(
      MuscleSearchHit(
        id: e.key,
        label: e.value.nom,
        group: group,
        isGroup: false,
        approximate: drawn == null,
      ),
    );
  }
  return out;
}();

/// UI4 : groupes et muscles qui correspondent à [q] (règle de `search.dart`),
/// du plus pertinent au moins pertinent ; à score égal, les groupes d'abord.
List<MuscleSearchHit> searchMuscles(String q) {
  final query = SearchQuery(q);
  if (query.isEmpty) return const [];
  final scored = <(MuscleSearchHit, double)>[
    for (final h in kMuscleSearchIndex)
      if (query.matches(h.doc.all)) (h, query.score(h.doc)),
  ];
  scored.sort((a, b) {
    final c = b.$2.compareTo(a.$2);
    if (c != 0) return c;
    if (a.$1.isGroup != b.$1.isGroup) return a.$1.isGroup ? -1 : 1;
    return a.$1.doc.name.compareTo(b.$1.doc.name);
  });
  return [for (final s in scored) s.$1];
}

class _ArsenalScreenState extends State<ArsenalScreen> {
  final _search = TextEditingController();
  String _q = '';
  bool _allMuscles = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _query(String v) => setState(() {
    _q = v;
    _allMuscles = false;
  });

  void _clear() {
    _search.clear();
    _query('');
  }

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  List<Widget> _results(BuildContext context) {
    final q = _q.trim();
    if (q.isEmpty) return const [];
    final exercises = searchExercises(
      store.content,
      q,
      const ExerciseFilters(),
    );
    final muscles = searchMuscles(q);
    if (exercises.isEmpty && muscles.isEmpty) {
      // R6 : pas de cul-de-sac.
      return [
        KEmpty(
          key: const ValueKey('arsenal-no-result'),
          icon: Icons.search_off,
          title: 'Aucun résultat',
          message:
              'Aucun exercice ni muscle ne correspond à « $q ». Vérifie '
              'l’orthographe ou essaie un autre mot.',
          action: 'Effacer la recherche',
          onAction: _clear,
        ),
      ];
    }
    final shownMuscles = _allMuscles
        ? muscles
        : muscles.take(ArsenalScreen.muscleLimit).toList();
    return [
      if (exercises.isNotEmpty)
        KMenuGroup(
          key: const ValueKey('arsenal-results-exercises'),
          title: 'Exercices',
          children: [
            for (final e in exercises.take(ArsenalScreen.exerciseLimit))
              KMenuRow(
                key: ValueKey('arsenal-ex-${e.id}'),
                title: e.nom,
                subtitle:
                    '${e.discipline} · ${e.niveau} · '
                    'difficulté ${e.difficulte}/10',
                onTap: () => openExerciseSheet(context, e.id),
              ),
            if (exercises.length > ArsenalScreen.exerciseLimit)
              KMenuRow(
                key: const ValueKey('arsenal-ex-all'),
                icon: Icons.menu_book_outlined,
                title: 'Voir les ${exercises.length} exercices',
                subtitle: 'Dans la bibliothèque, avec les filtres',
                onTap: () => _push(ExerciseLibraryScreen(initialQuery: q)),
              ),
          ],
        ),
      if (muscles.isNotEmpty)
        KMenuGroup(
          key: const ValueKey('arsenal-results-muscles'),
          title: 'Muscles',
          children: [
            for (final m in shownMuscles)
              KMenuRow(
                key: ValueKey(
                  '${m.isGroup ? 'arsenal-group' : 'arsenal-muscle'}-${m.id}',
                ),
                title: m.label,
                subtitle: m.subtitle,
                onTap: () => _push(AnatomyScreen(initialGroup: m.group)),
              ),
            if (shownMuscles.length < muscles.length)
              KMenuRow(
                key: const ValueKey('arsenal-muscles-more'),
                icon: Icons.expand_more_rounded,
                title: 'Afficher plus',
                subtitle:
                    '${muscles.length - shownMuscles.length} autre'
                    '${muscles.length - shownMuscles.length > 1 ? 's' : ''}',
                chevron: false,
                onTap: () => setState(() => _allMuscles = true),
              ),
          ],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return KMenuPage(
      title: 'Arsenal',
      lead: 'Tes exercices. Tes muscles. Ta technique.',
      // G1 : gestes du mode dev (build de développement seulement).
      trailing: const HeaderLogo(),
      search: Semantics(
        container: true,
        label: 'Rechercher un exercice ou un muscle',
        child: KSearchField(
          key: const ValueKey('arsenal-search'),
          controller: _search,
          hint: 'Exercice ou muscle',
          onChanged: _query,
        ),
      ),
      groups: [
        ..._results(context),
        KMenuGroup(
          title: 'Consulter',
          children: [
            KMenuRow(
              key: const ValueKey('arsenal-exercises'),
              icon: Icons.menu_book_outlined,
              title: 'Exercices',
              subtitle: 'Fiches, démonstrations, muscles et progressions',
              onTap: () => _push(const ExerciseLibraryScreen()),
            ),
            // M2 (mannequin 3D) : référence consultée avec les fiches
            // d'exercices.
            KMenuRow(
              key: const ValueKey('arsenal-anatomy'),
              icon: Icons.accessibility_new_rounded,
              title: 'Anatomie',
              subtitle: 'Muscles, groupes, vues et leurs exercices',
              onTap: () => _push(const AnatomyScreen()),
            ),
          ],
        ),
      ],
    );
  }
}
