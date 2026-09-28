// M2 (mannequin 3D) : écran « Anatomie » (Arsenal › Anatomie).
//
// Le mannequin anatomique s'explore : vues Face / Dos / Profil / 3/4, rotation
// au doigt, groupes de l'application mis en évidence, nom du muscle au
// toucher (réglage « Nom du muscle au toucher »). La liste des muscles des
// groupes cochés reste toujours affichée en texte (jamais l'information par
// la couleur seule). Placé dans l'Arsenal, à côté de la bibliothèque
// d'exercices : c'est la référence qu'on consulte avec les fiches.
//
// M4b : un seul bouton « Filtres » ouvre un menu de cases à cocher qui se
// superposent : les 11 groupes (chaque groupe coché s'allume en même temps
// que les autres), « Muscles profonds » (affichés en transparence ou
// masqués) et « Os ». Mannequin aussi grand que l'écran le permet, boutons
// de vue dessous, résumé texte des groupes cochés en dessous. Les filtres
// sont gardés pendant la session.
//
// M4c : le menu devient le composant commun `FilterMenu` (filtres
// normalisés dans toute l'application) : catégories « Groupes musculaires »
// et « Affichage » (Muscles profonds, Os), Tout cocher / Tout décocher par
// catégorie, Réinitialiser, filtres actifs en puces sous le bouton.
//
// M5 : sélecteur « Posture » (debout, suspendu à la barre, squat bas, planche
// de gainage) : le mannequin riggé passe d'une posture à l'autre par une
// transition douce ; mise en évidence et toucher restent justes sur le modèle
// déformé. La posture est gardée pendant la session.
import 'package:flutter/material.dart';

import 'filter_menu.dart';
import 'mannequin_3d.dart';
import 'ui.dart';

/// Libellés des 11 groupes de l'application.
const kGroupLabels = {
  'pectoraux': 'Pectoraux',
  'épaules': 'Épaules',
  'biceps': 'Biceps',
  'triceps': 'Triceps',
  'avant-bras': 'Avant-bras',
  'gainage': 'Gainage',
  'dos': 'Dos',
  'quadriceps': 'Quadriceps',
  'ischios': 'Ischios',
  'fessiers': 'Fessiers',
  'mollets': 'Mollets',
};

/// M5 : postures de référence de l'écran Anatomie (clés de
/// `assets/anatomy/rig.json`, `app: true`) et libellés.
const kAnatomyPostures = {
  'debout': 'Debout',
  'suspendu': 'Suspendu',
  'squat_bas': 'Squat bas',
  'planche': 'Planche',
};

/// Vue qui montre le mieux une posture (null : vue inchangée).
MannequinView? viewForPosture(String posture) => switch (posture) {
  'squat_bas' => MannequinView.troisQuarts,
  'planche' => MannequinView.profil,
  _ => null,
};

/// Vue de départ qui montre le mieux un groupe.
MannequinView viewForGroup(String? group) => switch (group) {
  'dos' ||
  'triceps' ||
  'ischios' ||
  'fessiers' ||
  'mollets' => MannequinView.dos,
  _ => MannequinView.face,
};

/// Filtres de l'écran Anatomie (M4b) : groupes allumés (union), muscles
/// profonds affichés, os affichés.
@immutable
class AnatomyFilters {
  /// Groupes cochés, allumés ensemble.
  final Set<String> groups;

  /// « Muscles profonds » coché : muscles profonds affichés (en
  /// transparence) ; décoché : masqués (couche superficielle seule).
  final bool deep;

  /// « Os » coché : squelette affiché.
  final bool bones;

  const AnatomyFilters({
    this.groups = const {},
    this.deep = true,
    this.bones = true,
  });

  /// Nombre de cases (11 groupes, « Muscles profonds », « Os »).
  static const total = 13;

  /// Tout coché.
  static final all = AnatomyFilters(groups: kGroupLabels.keys.toSet());

  /// Tout décoché.
  static const none = AnatomyFilters(deep: false, bones: false);

  /// Nombre de filtres actifs (cases cochées).
  int get count => groups.length + (deep ? 1 : 0) + (bones ? 1 : 0);

  /// Groupes cochés dans l'ordre de l'application.
  List<String> get orderedGroups => [
    for (final g in kGroupLabels.keys)
      if (groups.contains(g)) g,
  ];

  AnatomyFilters toggleGroup(String group) => AnatomyFilters(
    groups: groups.contains(group)
        ? ({...groups}..remove(group))
        : {...groups, group},
    deep: deep,
    bones: bones,
  );

  AnatomyFilters withDeep(bool value) =>
      AnatomyFilters(groups: groups, deep: value, bones: bones);

  AnatomyFilters withBones(bool value) =>
      AnatomyFilters(groups: groups, deep: deep, bones: value);

  @override
  bool operator ==(Object other) =>
      other is AnatomyFilters &&
      other.deep == deep &&
      other.bones == bones &&
      other.groups.length == groups.length &&
      other.groups.containsAll(groups);

  @override
  int get hashCode => Object.hash(deep, bones, Object.hashAllUnordered(groups));

  /// M4c : catégories du menu « Filtres ».
  static final categories = [
    FilterCategory(
      id: 'groupes',
      label: 'Groupes musculaires',
      options: [
        for (final e in kGroupLabels.entries) FilterOption(e.key, e.value),
      ],
    ),
    const FilterCategory(
      id: 'affichage',
      label: 'Affichage',
      options: [
        FilterOption('deep', 'Muscles profonds'),
        FilterOption('bones', 'Os'),
      ],
    ),
  ];

  FilterSelection get selection => FilterSelection({
    'groupes': groups,
    'affichage': {if (deep) 'deep', if (bones) 'bones'},
  });

  static AnatomyFilters fromSelection(FilterSelection s) => AnatomyFilters(
    groups: {
      for (final g in kGroupLabels.keys)
        if (s.has('groupes', g)) g,
    },
    deep: s.has('affichage', 'deep'),
    bones: s.has('affichage', 'bones'),
  );
}

class AnatomyScreen extends StatefulWidget {
  /// Groupe allumé à l'ouverture (remplace les groupes de la session).
  final String? initialGroup;
  const AnatomyScreen({super.key, this.initialGroup});

  /// Filtres gardés pendant la session (null : pas encore ouvert).
  static AnatomyFilters? session;

  /// M5 : posture gardée pendant la session.
  static String sessionPosture = 'debout';

  @override
  State<AnatomyScreen> createState() => AnatomyScreenState();
}

class AnatomyScreenState extends State<AnatomyScreen> {
  MannequinMap? _map;
  late AnatomyFilters _filters;
  late MannequinView _view;

  AnatomyFilters get filters => _filters;

  String _posture = AnatomyScreen.sessionPosture;

  /// Posture affichée (M5).
  String get posture => _posture;

  void setPosture(String key) => setState(() {
    _posture = key;
    AnatomyScreen.sessionPosture = key;
    final v = viewForPosture(key);
    if (v != null) _view = v;
  });

  /// Groupes cochés.
  Set<String> get groups => _filters.groups;

  @override
  void initState() {
    super.initState();
    final session =
        AnatomyScreen.session ??
        AnatomyFilters(bones: Display3DSettings.instance.bones.value);
    final initial = widget.initialGroup;
    _filters = initial == null
        ? session
        : AnatomyFilters(
            groups: {initial},
            deep: session.deep,
            bones: session.bones,
          );
    AnatomyScreen.session = _filters;
    final ordered = _filters.orderedGroups;
    _view = viewForGroup(ordered.isEmpty ? null : ordered.first);
    // Carte déjà chargée : utilisée tout de suite, sans attente.
    _map = MannequinMap.loaded;
    if (_map == null) {
      MannequinMap.load().then((m) {
        if (mounted) setState(() => _map = m);
      });
    }
  }

  void _set(AnatomyFilters f, {String? checkedGroup}) => setState(() {
    _filters = f;
    AnatomyScreen.session = f;
    // Un groupe qu'on vient de cocher choisit la vue qui le montre le mieux.
    if (checkedGroup != null) _view = viewForGroup(checkedGroup);
  });

  void toggleGroup(String group) {
    final checking = !_filters.groups.contains(group);
    _set(_filters.toggleGroup(group), checkedGroup: checking ? group : null);
  }

  void setDeep(bool value) => _set(_filters.withDeep(value));
  void setBones(bool value) => _set(_filters.withBones(value));
  void checkAll() => _set(AnatomyFilters.all);
  void uncheckAll() => _set(AnatomyFilters.none);

  /// Filtres de départ (« Réinitialiser ») : aucun groupe, muscles profonds
  /// affichés, os selon le réglage « Os visibles ».
  AnatomyFilters get defaults =>
      AnatomyFilters(bones: Display3DSettings.instance.bones.value);

  void _onMenu(FilterSelection s) {
    final next = AnatomyFilters.fromSelection(s);
    String? checked;
    for (final g in kGroupLabels.keys) {
      if (next.groups.contains(g) && !_filters.groups.contains(g)) {
        checked = g;
        break;
      }
    }
    _set(next, checkedGroup: checked);
  }

  AnatomyFilters? _intensityKey;
  MannequinMap? _intensityMap;
  Map<String, double> _intensities = const {};

  Set<String>? _deepCache;
  Set<String> _deepIds(MannequinMap map) => _deepCache ??= map.deepIds;

  @override
  Widget build(BuildContext context) {
    final map = _map;
    final f = _filters;
    // Mêmes groupes : même table (la scène ne recalcule pas ses matériaux).
    if (!identical(_intensityKey, f) || !identical(_intensityMap, map)) {
      _intensityKey = f;
      _intensityMap = map;
      _intensities = map == null || f.groups.isEmpty
          ? const <String, double>{}
          : map.fromGroups({for (final g in f.groups) g: kIntensityPrimary});
    }
    final intensities = _intensities;
    final hidden = map == null || f.deep ? const <String>{} : _deepIds(map);
    final mq = MediaQuery.of(context);
    // Le plus d'écran possible : hauteur visible moins la barre, la ligne
    // des filtres et les boutons de vue (le reste défile dessous).
    final height =
        (mq.size.height -
                mq.padding.top -
                mq.padding.bottom -
                kToolbarHeight -
                KNavigationInset.of(context) -
                285)
            .clamp(300.0, 900.0);
    final tt = Theme.of(context).textTheme;
    final labels = [for (final g in f.orderedGroups) kGroupLabels[g]!];
    return KScreen(
      appBar: AppBar(title: const Text('ANATOMIE')),
      body: KList(
        key: const ValueKey('anatomy-list'),
        gap: 10,
        children: [
          // Bouton « Filtres » et filtres actifs en puces (M4c).
          FilterMenu(
            key: const ValueKey('anatomy-filter-menu'),
            keyPrefix: 'anatomy',
            categories: AnatomyFilters.categories,
            value: f.selection,
            initial: defaults.selection,
            chipCategories: const {'groupes'},
            onChanged: _onMenu,
          ),
          Mannequin3D(
            key: const ValueKey('anatomy-mannequin'),
            posture: _posture,
            intensities: intensities,
            hidden: hidden,
            bones: f.bones,
            view: _view,
            height: height,
            semanticLabel: labels.isEmpty
                ? 'Mannequin anatomique en 3D'
                : 'Mannequin anatomique en 3D, '
                      '${labels.length == 1 ? 'groupe' : 'groupes'} '
                      '${labels.join(', ')} en rouge',
          ),
          // M5 : sous les boutons de vue (au-dessus, à 200 % de texte, les
          // puces repoussaient le mannequin hors de la liste construite).
          _postureSelector(context),
          ValueListenableBuilder<bool>(
            valueListenable: Display3DSettings.instance.touchNames,
            builder: (context, names, _) => Text(
              names
                  ? 'Touche un muscle pour afficher son nom. Tous les muscles '
                        'sont transparents : un muscle profond allumé se voit '
                        'à travers les autres.'
                  : 'Nom du muscle au toucher désactivé '
                        '(Réglages › Affichage 3D).',
              style: tt.bodySmall,
            ),
          ),
          if (map != null) _summary(context, map),
          Text(
            'Modèle : Z-Anatomy, dérivé de BodyParts3D (CC BY-SA 4.0). '
            'Crédits dans Réglages › À propos › Sources et licences. '
            'Repères d’entraînement, pas un avis médical.',
            style: tt.bodySmall,
          ),
        ],
      ),
    );
  }

  /// M5 : puces « Posture » (une seule choisie).
  Widget _postureSelector(BuildContext context) => Row(
    key: const ValueKey('anatomy-postures'),
    children: [
      Text('Posture', style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(width: 10),
      Expanded(
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final e in kAnatomyPostures.entries)
              ChoiceChip(
                key: ValueKey('anatomy-posture-${e.key}'),
                label: Text(e.value),
                selected: _posture == e.key,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => setPosture(e.key),
              ),
          ],
        ),
      ),
    ],
  );

  /// Résumé texte : chaque groupe coché et ses muscles (profonds signalés),
  /// état des muscles profonds et des os.
  Widget _summary(BuildContext context, MannequinMap map) {
    final tt = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final f = _filters;
    final deepNames = {
      for (final r in map.regions)
        if (r.profond) r.nom,
    };
    final state =
        'Muscles profonds ${f.deep ? 'affichés' : 'masqués'} · '
        'Os ${f.bones ? 'affichés' : 'masqués'}';
    if (f.groups.isEmpty) {
      return Text(
        'Aucun groupe coché : ouvre « Filtres » pour allumer un ou plusieurs '
        'groupes. $state.',
        key: const ValueKey('anatomy-summary-empty'),
        style: tt.bodyMedium,
      );
    }
    return KCard(
      key: const ValueKey('anatomy-group-list'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final g in f.orderedGroups) ...[
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: mannequinHeat(1, dark),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(kGroupLabels[g]!, style: tt.titleMedium)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              [
                for (final n in map.names(map.fromGroups({g: 1})))
                  deepNames.contains(n) ? '$n (profond)' : n,
              ].join(', '),
              key: ValueKey('anatomy-group-muscles-$g'),
              style: tt.bodyMedium,
            ),
            const SizedBox(height: 12),
          ],
          Text(state, style: tt.bodySmall),
        ],
      ),
    );
  }
}
