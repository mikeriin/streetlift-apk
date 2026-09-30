// M8 (30/09/2026, changement de plan du propriétaire) : carte 2D des
// groupes musculaires travaillés.
//
// Les animations 3D ne servent plus qu'à la démonstration des exercices et à
// Koach. Partout ailleurs (section Muscles des fiches, STATS, accueil, aperçu
// de WOD, écran Anatomie), les groupes travaillés s'affichent sur une carte
// 2D redessinée d'après l'image fournie par le propriétaire : vues de face,
// de dos et de profil, 15 groupes. Chaque groupe est un masque
// (`assets/muscles2d/<vue>/<groupe>.png`, fabriqué par
// tools/muscles2d/build_map.py) teinté à l'affichage : gris s'il n'est pas
// travaillé, couleur dominante de l'utilisateur par rôle sinon (principal
// vif, secondaire atténué, stabilisateur pâle ; intensité continue pour la
// semaine de STATS). Les traits entre les muscles et le fond sont
// transparents : la carte prend la couleur de son support (règle des fonds
// du 30/09/2026). La liste des muscles en texte reste toujours affichée à
// côté (jamais l'information par la couleur seule).
//
// 5.9.1 (M8 correction 1, 30/09/2026) : nouvelle image du propriétaire,
// plus détaillée (chaque muscle dessiné, sans légende). En plus des 15
// groupes : calques `neutre` (bas du dos, sans groupe : toujours gris),
// `contour` (traits de l'image) et `ombre` (modelé : fibres, volumes, noir
// translucide par-dessus les muscles).
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';

/// Un groupe de la carte.
class MapGroup {
  final String id, label;
  const MapGroup(this.id, this.label);
}

/// Les 15 groupes de la carte (ordre de la légende de l'image source).
const kMapGroups = [
  MapGroup('trapezes', 'Trapèzes'),
  MapGroup('deltoides', 'Deltoïdes'),
  MapGroup('pectoraux', 'Pectoraux'),
  MapGroup('dorsaux', 'Dorsaux'),
  MapGroup('biceps', 'Biceps'),
  MapGroup('triceps', 'Triceps'),
  MapGroup('avant_bras', 'Avant-bras'),
  MapGroup('abdominaux', 'Abdominaux'),
  MapGroup('obliques', 'Obliques'),
  MapGroup('fessiers', 'Fessiers'),
  MapGroup('quadriceps', 'Quadriceps'),
  MapGroup('ischios', 'Ischio-jambiers'),
  MapGroup('adducteurs', 'Adducteurs'),
  MapGroup('mollets', 'Mollets'),
  MapGroup('tibial', 'Tibial antérieur'),
];

/// Libellé d'un groupe de la carte.
String mapGroupLabel(String id) => kMapGroups
    .firstWhere((g) => g.id == id, orElse: () => MapGroup(id, id))
    .label;

/// Calques de la carte, dans l'ordre de `tools/muscles2d/build_map.py`
/// (valeur de la carte des étiquettes = 1 + rang).
const kMapLayers = [
  'trapezes',
  'deltoides',
  'pectoraux',
  'dorsaux',
  'biceps',
  'triceps',
  'avant_bras',
  'abdominaux',
  'obliques',
  'fessiers',
  'quadriceps',
  'ischios',
  'adducteurs',
  'mollets',
  'tibial',
  'neutre',
  'peau',
  'sombre',
  'contour',
  'ombre',
];

/// Groupe de la carte de chaque muscle du pack (identifiants de
/// `atlasMuscles`). Muscles sans groupe (profonds du tronc, cou, plancher
/// pelvien, diaphragme, carré des lombes, érecteurs) : listés en texte.
const kMuscleToMapGroup = <String, String>{
  'sterno_cleido_mastoidien': 'trapezes',
  'extenseurs_cervicaux': 'trapezes',
  'trapeze_superieur': 'trapezes',
  'trapeze_moyen': 'trapezes',
  'trapeze_inferieur': 'trapezes',
  'elevateur_scapula': 'trapezes',
  'rhomboides': 'trapezes',
  'deltoide_anterieur': 'deltoides',
  'deltoide_moyen': 'deltoides',
  'deltoide_posterieur': 'deltoides',
  'supra_epineux': 'deltoides',
  'infra_epineux': 'deltoides',
  'petit_rond': 'deltoides',
  'sous_scapulaire': 'deltoides',
  'dentele_anterieur': 'pectoraux',
  'petit_pectoral': 'pectoraux',
  'grand_pectoral_claviculaire': 'pectoraux',
  'grand_pectoral_sterno_costal': 'pectoraux',
  'grand_pectoral_abdominal': 'pectoraux',
  'grand_dorsal': 'dorsaux',
  'grand_rond': 'dorsaux',
  'biceps_chef_long': 'biceps',
  'biceps_chef_court': 'biceps',
  'brachial': 'biceps',
  'coraco_brachial': 'biceps',
  'triceps_chef_long': 'triceps',
  'triceps_chef_lateral': 'triceps',
  'triceps_chef_medial': 'triceps',
  'ancone': 'triceps',
  'brachio_radial': 'avant_bras',
  'extenseurs_du_poignet': 'avant_bras',
  'extenseurs_des_doigts': 'avant_bras',
  'flechisseurs_du_poignet': 'avant_bras',
  'flechisseurs_superficiels_des_doigts': 'avant_bras',
  'flechisseurs_profonds_des_doigts': 'avant_bras',
  'rond_pronateur': 'avant_bras',
  'supinateur': 'avant_bras',
  'carre_pronateur': 'avant_bras',
  'muscles_intrinseques_main': 'avant_bras',
  'droit_abdomen': 'abdominaux',
  'transverse_abdomen': 'abdominaux',
  'oblique_externe': 'obliques',
  'oblique_interne': 'obliques',
  'grand_psoas': 'quadriceps',
  'iliaque': 'quadriceps',
  'sartorius': 'quadriceps',
  'droit_femoral': 'quadriceps',
  'vaste_lateral': 'quadriceps',
  'vaste_medial': 'quadriceps',
  'vaste_intermediaire': 'quadriceps',
  'tenseur_fascia_lata': 'fessiers',
  'grand_fessier': 'fessiers',
  'moyen_fessier': 'fessiers',
  'petit_fessier': 'fessiers',
  'rotateurs_lateraux_hanche': 'fessiers',
  'pectine': 'adducteurs',
  'long_adducteur': 'adducteurs',
  'court_adducteur': 'adducteurs',
  'grand_adducteur': 'adducteurs',
  'gracile': 'adducteurs',
  'biceps_femoral': 'ischios',
  'biceps_femoral_chef_court': 'ischios',
  'semi_tendineux': 'ischios',
  'semi_membraneux': 'ischios',
  'poplite': 'ischios',
  'gastrocnemien_medial': 'mollets',
  'gastrocnemien_lateral': 'mollets',
  'soleaire': 'mollets',
  'tibial_posterieur': 'mollets',
  'fibulaires': 'mollets',
  'muscles_intrinseques_pied': 'mollets',
  'flechisseurs_profonds_des_orteils': 'mollets',
  'long_extenseur_des_orteils': 'tibial',
  'tibial_anterieur': 'tibial',
};

/// Groupes de la carte de chaque groupe historique de l'application (repli
/// d'un exercice sans fiche : `groupe:<g>`) ; le premier est le principal.
const kAppGroupToMap = <String, List<String>>{
  'pectoraux': ['pectoraux'],
  'épaules': ['deltoides'],
  'biceps': ['biceps'],
  'triceps': ['triceps'],
  'avant-bras': ['avant_bras'],
  'gainage': ['abdominaux', 'obliques'],
  'dos': ['dorsaux', 'trapezes'],
  'quadriceps': ['quadriceps'],
  'ischios': ['ischios'],
  'fessiers': ['fessiers'],
  'mollets': ['mollets'],
};

/// Intensité par rôle (mêmes valeurs que le mannequin 3D).
const kMapPrimary = 1.0, kMapSecondary = .62, kMapStabilizer = .35;

/// Intensité (0-1) par groupe de la carte d'après les rôles d'un exercice :
/// un groupe prend son rôle le plus fort.
Map<String, double> mapIntensitiesFromRoles({
  List<String> primaires = const [],
  List<String> secondaires = const [],
  List<String> stabilisateurs = const [],
}) {
  final out = <String, double>{};
  void add(List<String> ids, double v) {
    for (final id in ids) {
      final g = kMuscleToMapGroup[id];
      if (g != null && v > (out[g] ?? 0)) out[g] = v;
    }
  }

  add(stabilisateurs, kMapStabilizer);
  add(secondaires, kMapSecondary);
  add(primaires, kMapPrimary);
  return out;
}

/// Seuil sous lequel un groupe reste gris (2 %, comme la carte historique).
const kMapMinIntensity = .02;

/// Intensité (0-1) par groupe de la carte pour des poids par muscle du pack
/// ou par groupe historique (`groupe:<g>`, exercice sans fiche) : un groupe
/// cumule ses muscles, puis tout est ramené au plus fort ; seuil de 2 %.
Map<String, double> mapIntensitiesFromWeights(Map<String, double> weights) {
  final sum = <String, double>{};
  weights.forEach((key, w) {
    if (w <= 0) return;
    if (key.startsWith('groupe:')) {
      final gs = kAppGroupToMap[key.substring(7)] ?? const <String>[];
      for (var i = 0; i < gs.length; i++) {
        sum[gs[i]] = (sum[gs[i]] ?? 0) + w * (i == 0 ? 1.0 : .6);
      }
    } else {
      final g = kMuscleToMapGroup[key];
      if (g != null) sum[g] = (sum[g] ?? 0) + w;
    }
  });
  if (sum.isEmpty) return const {};
  final max = sum.values.reduce((a, b) => a > b ? a : b);
  return {
    for (final e in sum.entries)
      if (e.value / max > kMapMinIntensity) e.key: e.value / max,
  };
}

/// Muscles du pack d'un groupe de la carte (listes en texte, Anatomie).
List<String> mapGroupMuscles(String group) => [
  for (final e in kMuscleToMapGroup.entries)
    if (e.value == group) e.key,
];

// ------------------------------------------------------------- couleurs --

/// Gris d'un muscle non travaillé, de la peau (articulations) et des
/// extrémités (tête, mains, pieds), selon le thème.
Color mapMuscleGray(bool dark) =>
    dark ? const Color(0xFF55565B) : const Color(0xFFC4C5C9);
Color mapSkinGray(bool dark) =>
    dark ? const Color(0xFF7A7B80) : const Color(0xFFE2E2E4);
Color mapDarkGray(bool dark) =>
    dark ? const Color(0xFF34353A) : const Color(0xFF5A5B60);

/// 5.9.1 : traits de l'image (cernes, séparations) et modelé (fibres,
/// volumes, noir translucide posé sur les muscles).
Color mapContour(bool dark) =>
    dark ? const Color(0xFF0E0E10) : const Color(0xFF2A2B30);
const kMapShade = Color(0x73000000);

/// Couleur d'un groupe travaillé : du gris à la couleur dominante vive
/// selon l'intensité (principal vif, secondaire atténué, stabilisateur
/// pâle ; semaine de STATS : continue).
Color mapHeat(double v, bool dark, [KAccentSpec? accent]) {
  final a = accent ?? SL.accentSpec;
  final vivid = dark ? a.bright : (a.vividLight ?? a.vivid);
  final f = .22 + .78 * v.clamp(0.0, 1.0);
  return Color.lerp(mapMuscleGray(dark), vivid, f)!;
}

/// Sur un support de la couleur dominante (carte du jour de l'accueil) :
/// toute la carte dans la couleur du texte posé sur ce support, groupes
/// travaillés opaques, le reste en transparence.
Color mapTinted(String layer, double v, Color tint) => switch (layer) {
  'peau' => tint.withValues(alpha: .34),
  'sombre' => tint.withValues(alpha: .14),
  'contour' => const Color(0x59000000),
  'ombre' => const Color(0x40000000),
  'neutre' => tint.withValues(alpha: .22),
  _ =>
    v > kMapMinIntensity
        ? tint.withValues(alpha: .55 + .45 * v.clamp(0.0, 1.0))
        : tint.withValues(alpha: .22),
};

// ----------------------------------------------------------------- vues --

/// Vues de la carte.
enum MapView {
  face('Face', 511, 980),
  dos('Dos', 489, 976),
  profil('Profil', 187, 980);

  final String label;

  /// Taille des masques (px) : proportions de la vue.
  final double width, height;
  const MapView(this.label, this.width, this.height);

  String asset(String layer) => 'assets/muscles2d/$name/$layer.png';
  String get labels => 'assets/muscles2d/$name/etiquettes.png';
}

/// Calques présents dans chaque vue (les autres groupes sont cachés).
const kMapViewLayers = <MapView, Set<String>>{
  MapView.face: {
    'trapezes', 'deltoides', 'pectoraux', 'dorsaux', 'biceps', 'triceps', //
    'avant_bras', 'abdominaux', 'obliques', 'fessiers', 'quadriceps',
    'adducteurs', 'mollets', 'tibial', 'peau', 'sombre', 'contour', 'ombre',
  },
  MapView.dos: {
    'trapezes', 'deltoides', 'dorsaux', 'triceps', 'avant_bras', //
    'obliques', 'fessiers', 'quadriceps', 'ischios', 'mollets', 'neutre',
    'peau', 'sombre', 'contour', 'ombre',
  },
  MapView.profil: {
    'trapezes', 'deltoides', 'pectoraux', 'dorsaux', 'biceps', 'triceps', //
    'avant_bras', 'abdominaux', 'obliques', 'fessiers', 'quadriceps',
    'ischios', 'mollets', 'tibial', 'peau', 'sombre', 'contour', 'ombre',
  },
};

/// Étiquettes décodées d'une vue (toucher : quel groupe sous le doigt).
class _Labels {
  final int width, height;
  final Uint8List rgba;
  const _Labels(this.width, this.height, this.rgba);

  String? at(double fx, double fy) {
    final x = (fx * width).floor(), y = (fy * height).floor();
    if (x < 0 || y < 0 || x >= width || y >= height) return null;
    final v = rgba[(y * width + x) * 4];
    if (v == 0 || v > kMapLayers.length) return null;
    return kMapLayers[v - 1];
  }
}

final _labels = <MapView, Future<_Labels>>{};

Future<_Labels> _loadLabels(MapView v) => _labels[v] ??= () async {
  final data = await rootBundle.load(v.labels);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  final bytes = await frame.image.toByteData();
  final out = _Labels(
    frame.image.width,
    frame.image.height,
    bytes!.buffer.asUint8List(),
  );
  frame.image.dispose();
  return out;
}();

/// Précharge les masques (lancement de l'application : pas de saut à la
/// première carte affichée).
Future<void> precacheMuscleMap(BuildContext context) async {
  for (final v in MapView.values) {
    for (final l in kMapViewLayers[v]!) {
      await precacheImage(AssetImage(v.asset(l)), context);
    }
  }
}

/// Carte 2D des groupes musculaires : une ou plusieurs vues côte à côte,
/// chaque groupe teinté selon [intensities] (0 ou absent : gris). Fond
/// transparent (couleur du support). [onGroupTap] : groupe touché (null :
/// hors d'un groupe).
class MuscleMap2D extends StatelessWidget {
  final Map<String, double> intensities;
  final List<MapView> views;
  final double height;

  /// Nom de chaque vue sous la figure.
  final bool viewLabels;

  /// Groupe mis en évidence (toucher, Anatomie) : contour dans la couleur
  /// du texte.
  final String? selected;
  final ValueChanged<String?>? onGroupTap;
  final String semanticLabel;

  /// Support de la couleur dominante : carte teintée de cette couleur
  /// ([mapTinted]) au lieu du gris et de la couleur dominante.
  final Color? tint;

  const MuscleMap2D({
    super.key,
    this.intensities = const {},
    this.views = MapView.values,
    this.height = 280,
    this.viewLabels = true,
    this.selected,
    this.onGroupTap,
    this.tint,
    this.semanticLabel = 'Carte des groupes musculaires',
  });

  /// Écart entre deux vues, en part de la hauteur.
  static const gap = .06;

  /// Largeur des vues [views] côte à côte pour une hauteur [h].
  static double widthFor(List<MapView> views, double h) {
    var w = 0.0;
    for (final v in views) {
      w += h * v.width / v.height;
    }
    return w + h * gap * (views.length - 1);
  }

  /// Couleur d'un calque.
  static Color layerColor(
    String layer,
    Map<String, double> intensities,
    bool dark, [
    Color? tint,
  ]) {
    if (tint != null) return mapTinted(layer, intensities[layer] ?? 0, tint);
    if (layer == 'peau') return mapSkinGray(dark);
    if (layer == 'sombre') return mapDarkGray(dark);
    if (layer == 'contour') return mapContour(dark);
    if (layer == 'ombre') return kMapShade;
    // bas du dos (fascia, érecteurs) : muscle sans groupe, toujours gris
    if (layer == 'neutre') return mapMuscleGray(dark);
    final v = intensities[layer] ?? 0;
    return v > kMapMinIntensity ? mapHeat(v, dark) : mapMuscleGray(dark);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final worked = [
      for (final g in kMapGroups)
        if ((intensities[g.id] ?? 0) > kMapMinIntensity) g.label,
    ];
    final labels = viewLabels && views.length > 1;
    return Semantics(
      label: worked.isEmpty
          ? '$semanticLabel : aucun groupe travaillé'
          : '$semanticLabel : ${worked.join(', ')}',
      child: LayoutBuilder(
        builder: (context, box) {
          // Vues aussi hautes que demandé, réduites si la largeur manque.
          var h = height;
          if (box.hasBoundedWidth && widthFor(views, h) > box.maxWidth) {
            // marge d'un pixel : arrondis de mise en page
            h = (box.maxWidth - 1) / widthFor(views, 1);
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final v in views) ...[
                if (v != views.first) SizedBox(width: h * gap),
                _column(context, v, h, dark, labels),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _column(
    BuildContext context,
    MapView v,
    double h,
    bool dark,
    bool labels,
  ) {
    final tt = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MapFigure(
          key: ValueKey('map-${v.name}'),
          view: v,
          height: h,
          intensities: intensities,
          dark: dark,
          tint: tint,
          selected: selected,
          onGroupTap: onGroupTap,
        ),
        // Nom de la vue, jamais plus large que la figure (profil étroit,
        // grand texte) : réduit au besoin.
        if (labels)
          SizedBox(
            width: h * v.width / v.height,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  v.label,
                  maxLines: 1,
                  style: tt.labelSmall?.copyWith(color: SL.dim),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MapFigure extends StatelessWidget {
  final MapView view;
  final double height;
  final Map<String, double> intensities;
  final bool dark;
  final Color? tint;
  final String? selected;
  final ValueChanged<String?>? onGroupTap;

  const _MapFigure({
    super.key,
    required this.view,
    required this.height,
    required this.intensities,
    required this.dark,
    this.tint,
    this.selected,
    this.onGroupTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = height * view.width / view.height;
    final layers = [
      for (final l in kMapLayers)
        if (kMapViewLayers[view]!.contains(l)) l,
    ];
    final stack = SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final l in layers)
            Image.asset(
              view.asset(l),
              key: ValueKey('map-${view.name}-$l'),
              fit: BoxFit.fill,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              color: l == selected
                  ? Color.lerp(
                      MuscleMap2D.layerColor(l, intensities, dark, tint),
                      dark ? Colors.white : Colors.black,
                      .35,
                    )
                  : MuscleMap2D.layerColor(l, intensities, dark, tint),
              colorBlendMode: BlendMode.srcIn,
            ),
        ],
      ),
    );
    final tap = onGroupTap;
    if (tap == null) return stack;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (d) async {
        final labels = await _loadLabels(view);
        final g = labels.at(
          d.localPosition.dx / width,
          d.localPosition.dy / height,
        );
        tap(kMapGroups.any((m) => m.id == g) ? g : null);
      },
      child: stack,
    );
  }
}

/// Légende des rôles (pastilles dans les couleurs de la carte).
class MapRoleLegend extends StatelessWidget {
  final bool stabilizers;
  const MapRoleLegend({super.key, this.stabilizers = true});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tt = Theme.of(context).textTheme;
    Widget item(String label, Color c) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        // grand texte, carte étroite : retour à la ligne plutôt qu'un
        // débordement
        Flexible(child: Text(label, style: tt.bodySmall)),
      ],
    );
    return Wrap(
      key: const ValueKey('map-legend'),
      spacing: 14,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        item('Principal', mapHeat(kMapPrimary, dark)),
        item('Secondaire', mapHeat(kMapSecondary, dark)),
        if (stabilizers) item('Stabilisateur', mapHeat(kMapStabilizer, dark)),
        item('Non travaillé', mapMuscleGray(dark)),
      ],
    );
  }
}

/// Muscles de chaque groupe travaillé, en texte (jamais l'information par la
/// couleur seule).
String mapWorkedSummary(Map<String, double> intensities) {
  final parts = <String>[];
  for (final g in kMapGroups) {
    final v = intensities[g.id] ?? 0;
    if (v <= kMapMinIntensity) continue;
    parts.add(g.label);
  }
  return parts.isEmpty ? 'Aucun groupe travaillé' : parts.join(' · ');
}

/// Utilisé par les tests : charge les étiquettes d'une vue.
@visibleForTesting
Future<String?> mapGroupAt(MapView view, double fx, double fy) async =>
    (await _loadLabels(view)).at(fx, fy);

/// Précharge les masques sans attendre (lancement de l'application).
void mapPrecacheInBackground(BuildContext context) =>
    unawaited(precacheMuscleMap(context));
