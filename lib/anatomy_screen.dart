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
//
// M8 (5.9.0, changement de plan du propriétaire du 30/09/2026) : la 3D ne
// sert plus qu'à la démonstration des exercices et à Koach. L'écran
// Anatomie montre la carte 2D des 15 groupes (face, dos, profil, d'après
// l'image du propriétaire) : filtres = les 15 groupes, groupes cochés dans
// la couleur dominante, les autres en gris ; toucher un groupe affiche son
// nom (réglage « Nom du muscle au toucher ») ; résumé texte des muscles de
// chaque groupe coché. L'entrée « Koach (aperçu) » reste.
import 'package:flutter/material.dart';

import 'atlas_data.dart';
import 'filter_menu.dart';
import 'koach_preview_screen.dart';
import 'mannequin_3d.dart' show Display3DSettings;
import 'muscle_map_2d.dart';
import 'ui.dart';

/// Filtres de l'écran Anatomie : groupes de la carte allumés (union).
@immutable
class AnatomyFilters {
  /// Groupes cochés, allumés ensemble.
  final Set<String> groups;

  const AnatomyFilters({this.groups = const {}});

  /// Nombre de cases (M8 : les 15 groupes de la carte).
  static const total = 15;

  /// Tout coché.
  static final all = AnatomyFilters(
    groups: {for (final g in kMapGroups) g.id},
  );

  /// Tout décoché.
  static const none = AnatomyFilters();

  /// Nombre de filtres actifs (cases cochées).
  int get count => groups.length;

  /// Groupes cochés dans l'ordre de la carte.
  List<String> get orderedGroups => [
    for (final g in kMapGroups)
      if (groups.contains(g.id)) g.id,
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
      options: [for (final g in kMapGroups) FilterOption(g.id, g.label)],
    ),
  ];

  FilterSelection get selection => FilterSelection({'groupes': groups});

  static AnatomyFilters fromSelection(FilterSelection s) => AnatomyFilters(
    groups: {
      for (final g in kMapGroups)
        if (s.has('groupes', g.id)) g.id,
    },
  );
}

class AnatomyScreen extends StatefulWidget {
  /// Groupe de la carte allumé à l'ouverture (remplace ceux de la session).
  final String? initialGroup;
  const AnatomyScreen({super.key, this.initialGroup});

  /// Filtres gardés pendant la session (null : pas encore ouvert).
  static AnatomyFilters? session;

  @override
  State<AnatomyScreen> createState() => AnatomyScreenState();
}

class AnatomyScreenState extends State<AnatomyScreen> {
  late AnatomyFilters _filters;

  /// Dernier groupe touché sur la carte (nom affiché).
  String? touched;

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
  }

  void _set(AnatomyFilters f) => setState(() {
    _filters = f;
    AnatomyScreen.session = f;
  });

  void toggleGroup(String group) => _set(_filters.toggleGroup(group));
  void checkAll() => _set(AnatomyFilters.all);
  void uncheckAll() => _set(AnatomyFilters.none);

  /// Filtres de départ (« Réinitialiser ») : aucun groupe.
  AnatomyFilters get defaults => AnatomyFilters.none;

  /// Toucher d'un groupe de la carte (null : à côté).
  void touch(String? group) {
    if (!Display3DSettings.instance.touchNames.value) return;
    setState(() => touched = group);
  }

  /// Intensités de la carte : groupes cochés au plus fort.
  Map<String, double> get intensities => {
    for (final g in _filters.groups) g: kMapPrimary,
  };

  @override
  Widget build(BuildContext context) {
    final f = _filters;
    final mq = MediaQuery.of(context);
    // Le plus d'écran possible : hauteur visible moins la barre, la ligne
    // des filtres et le nom touché (le reste défile dessous) ; la carte se
    // réduit d'elle-même si la largeur manque.
    final height =
        (mq.size.height -
                mq.padding.top -
                mq.padding.bottom -
                kToolbarHeight -
                KNavigationInset.of(context) -
                220)
            .clamp(260.0, 640.0);
    final tt = Theme.of(context).textTheme;
    final labels = [for (final g in f.orderedGroups) mapGroupLabel(g)];
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
            onChanged: (s) => _set(AnatomyFilters.fromSelection(s)),
          ),
          MuscleMap2D(
            key: const ValueKey('anatomy-map'),
            intensities: intensities,
            height: height,
            selected: touched,
            onGroupTap: touch,
            semanticLabel: labels.isEmpty
                ? 'Carte des groupes musculaires'
                : 'Carte des groupes musculaires, '
                      '${labels.length == 1 ? 'groupe' : 'groupes'} '
                      '${labels.join(', ')} en couleur',
          ),
          ValueListenableBuilder<bool>(
            valueListenable: Display3DSettings.instance.touchNames,
            builder: (context, names, _) {
              final t = touched;
              if (names && t != null) {
                return Text(
                  mapGroupLabel(t),
                  key: const ValueKey('anatomy-touched'),
                  textAlign: TextAlign.center,
                  style: tt.titleMedium,
                );
              }
              return Text(
                names
                    ? 'Touche un groupe pour afficher son nom. Groupes '
                          'cochés en couleur, les autres en gris ; muscles '
                          'profonds listés en texte sur les fiches.'
                    : 'Nom du muscle au toucher désactivé '
                          '(Réglages › Affichage 3D).',
                style: tt.bodySmall,
              );
            },
          ),
          _summary(context),
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
            'Carte des groupes musculaires redessinée pour l’application. '
            'Repères d’entraînement, pas un avis médical.',
            style: tt.bodySmall,
          ),
        ],
      ),
    );
  }

  /// Résumé texte : chaque groupe coché et ses muscles.
  Widget _summary(BuildContext context) {
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
                    color: mapHeat(kMapPrimary, dark),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(mapGroupLabel(g), style: tt.titleMedium)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              [
                for (final m in mapGroupMuscles(g)) atlasMuscles[m]?.nom ?? m,
              ].join(', '),
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
