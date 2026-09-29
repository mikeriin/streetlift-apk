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
// de gainage) sur le mannequin riggé.
//
// 5.5.2 (M56 correction 2, décision du propriétaire du 29/09/2026) : modèle
// remplacé par l'écorché acheté (un muscle = une région de sa texture), sans
// squelette ni posture : le sélecteur « Posture » est retiré, le mannequin
// reste au repos ; les positions des exercices seront faites à la main plus
// tard. Muscles en gris à 50 % d'opacité, groupes allumés dans la couleur
// dominante choisie par l'utilisateur.
//
// 5.5.3-5.5.4 (M56 corrections 3 et 4) : muscles opaques, plus de rotation
// au doigt (boutons de vue, pincement, toucher), maillage gris et halo des
// groupes cochés dans la couleur dominante, fond de la page.
//
// M6b : le filtre « Muscles profonds » est retiré (l'écorché n'a plus de
// couche profonde : il n'avait plus d'effet) ; reste « Os » dans la
// catégorie « Affichage ».
//
// M6c (5.6.0) : le mannequin devient le personnage Mixamo « Ch36 », zones
// musculaires sur la peau : plus d'os à afficher, le filtre « Os » et la
// catégorie « Affichage » sont retirés ; restent les 11 groupes.
//
// M7b (5.8.0) : entrée « Koach (aperçu) » (animations de la mascotte,
// koach_preview_screen.dart) sous le résumé des groupes.
import 'package:flutter/material.dart';

import 'filter_menu.dart';
import 'koach_preview_screen.dart';
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

/// Vue de départ qui montre le mieux un groupe.
MannequinView viewForGroup(String? group) => switch (group) {
  'dos' ||
  'triceps' ||
  'ischios' ||
  'fessiers' ||
  'mollets' => MannequinView.dos,
  _ => MannequinView.face,
};

/// Filtres de l'écran Anatomie (M4b) : groupes allumés (union). M6b : plus
/// de filtre « Muscles profonds » ; M6c : plus de filtre « Os » (personnage
/// à la peau lisse).
@immutable
class AnatomyFilters {
  /// Groupes cochés, allumés ensemble.
  final Set<String> groups;

  const AnatomyFilters({this.groups = const {}});

  /// Nombre de cases (11 groupes).
  static const total = 11;

  /// Tout coché.
  static final all = AnatomyFilters(groups: kGroupLabels.keys.toSet());

  /// Tout décoché.
  static const none = AnatomyFilters();

  /// Nombre de filtres actifs (cases cochées).
  int get count => groups.length;

  /// Groupes cochés dans l'ordre de l'application.
  List<String> get orderedGroups => [
    for (final g in kGroupLabels.keys)
      if (groups.contains(g)) g,
  ];

  AnatomyFilters toggleGroup(String group) => AnatomyFilters(
    groups: groups.contains(group)
        ? ({...groups}..remove(group))
        : {...groups, group},
  );

  @override
  bool operator ==(Object other) =>
      other is AnatomyFilters &&
      other.groups.length == groups.length &&
      other.groups.containsAll(groups);

  @override
  int get hashCode => Object.hashAllUnordered(groups);

  /// M4c : catégories du menu « Filtres ».
  static final categories = [
    FilterCategory(
      id: 'groupes',
      label: 'Groupes musculaires',
      options: [
        for (final e in kGroupLabels.entries) FilterOption(e.key, e.value),
      ],
    ),
  ];

  FilterSelection get selection => FilterSelection({'groupes': groups});

  static AnatomyFilters fromSelection(FilterSelection s) => AnatomyFilters(
    groups: {
      for (final g in kGroupLabels.keys)
        if (s.has('groupes', g)) g,
    },
  );
}

class AnatomyScreen extends StatefulWidget {
  /// Groupe allumé à l'ouverture (remplace les groupes de la session).
  final String? initialGroup;
  const AnatomyScreen({super.key, this.initialGroup});

  /// Filtres gardés pendant la session (null : pas encore ouvert).
  static AnatomyFilters? session;

  @override
  State<AnatomyScreen> createState() => AnatomyScreenState();
}

class AnatomyScreenState extends State<AnatomyScreen> {
  MannequinMap? _map;
  late AnatomyFilters _filters;
  late MannequinView _view;

  AnatomyFilters get filters => _filters;

  /// Groupes cochés.
  Set<String> get groups => _filters.groups;

  @override
  void initState() {
    super.initState();
    final session = AnatomyScreen.session ?? AnatomyFilters.none;
    final initial = widget.initialGroup;
    _filters = initial == null ? session : AnatomyFilters(groups: {initial});
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

  void checkAll() => _set(AnatomyFilters.all);
  void uncheckAll() => _set(AnatomyFilters.none);

  /// Filtres de départ (« Réinitialiser ») : aucun groupe.
  AnatomyFilters get defaults => AnatomyFilters.none;

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
    final mq = MediaQuery.of(context);
    // Le plus d'écran possible : hauteur visible moins la barre, la ligne
    // des filtres et les boutons de vue (le reste défile dessous).
    final height =
        (mq.size.height -
                mq.padding.top -
                mq.padding.bottom -
                kToolbarHeight -
                KNavigationInset.of(context) -
                240)
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
            intensities: intensities,
            background: Theme.of(context).scaffoldBackgroundColor,
            view: _view,
            height: height,
            semanticLabel: labels.isEmpty
                ? 'Mannequin anatomique en 3D'
                : 'Mannequin anatomique en 3D, '
                      '${labels.length == 1 ? 'groupe' : 'groupes'} '
                      '${labels.join(', ')} mis en évidence par un halo',
          ),
          ValueListenableBuilder<bool>(
            valueListenable: Display3DSettings.instance.touchNames,
            builder: (context, names, _) => Text(
              names
                  ? 'Touche un muscle pour afficher son nom ; les boutons '
                        'Face, Dos, Profil, 3/4 tournent le mannequin, pince '
                        'pour zoomer. Zones musculaires dessinées sur la '
                        'peau ; les muscles profonds sont listés en texte '
                        'sur les fiches.'
                  : 'Nom du muscle au toucher désactivé '
                        '(Réglages › Affichage 3D).',
              style: tt.bodySmall,
            ),
          ),
          if (map != null) _summary(context, map),
          // M7b : aperçu des animations de Koach (mascotte).
          KCard(
            key: const ValueKey('anatomy-koach-preview'),
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.accessibility_new),
              title: const Text('Koach (aperçu)'),
              subtitle: const Text(
                'Ses animations de mascotte : attente, parle, félicite',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const KoachPreviewScreen()),
              ),
            ),
          ),
          Text(
            'Modèle : personnage Mixamo (Adobe), zones musculaires issues de '
            'l’écorché « Ecorche Musclenames Male Anatomy » (licence '
            'd’achat). Crédits dans Réglages › À propos › Sources et '
            'licences. Repères d’entraînement, pas un avis médical.',
            style: tt.bodySmall,
          ),
        ],
      ),
    );
  }

  /// Résumé texte : chaque groupe coché et ses muscles.
  Widget _summary(BuildContext context, MannequinMap map) {
    final tt = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final f = _filters;
    if (f.groups.isEmpty) {
      return Text(
        'Aucun groupe coché : ouvre « Filtres » pour allumer un ou plusieurs '
        'groupes.',
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
              map.names(map.fromGroups({g: 1})).join(', '),
              key: ValueKey('anatomy-group-muscles-$g'),
              style: tt.bodyMedium,
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
