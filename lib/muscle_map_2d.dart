// M8 (30/09/2026, changement de plan du propriétaire) : carte 2D des
// muscles travaillés.
//
// Les animations 3D ne servent qu'à la démonstration des exercices et à
// Koach. Partout ailleurs (section Muscles des fiches, STATS, accueil, aperçu
// de WOD, écran Anatomie), les muscles travaillés s'affichent sur une carte
// 2D redessinée d'après l'image du propriétaire : vues de face, de dos et de
// profil. Gris s'ils ne sont pas travaillés, couleur dominante de
// l'utilisateur sinon (principal vif, secondaire atténué, stabilisateur
// pâle ; intensité continue pour la semaine de STATS). Le fond est
// transparent : la carte prend la couleur de son support (règle des fonds
// du 30/09/2026). La liste des muscles en texte reste toujours affichée à
// côté (jamais l'information par la couleur seule).
//
// 5.9.1 (correction 1) : image détaillée du propriétaire (chaque muscle
// dessiné, traits et modelé repris).
//
// 5.10.0 (correction 2, « quelque chose de scientifiquement correct ») :
// la carte est découpée **muscle par muscle** (`kMapRegions`, générée par
// tools/muscles2d/build_map.py) : une région = une zone dessinée, reliée
// aux muscles du pack qu'elle montre. Un exercice n'allume que les régions
// de ses muscles (plus le groupe entier) ; les muscles profonds (non
// dessinés) restent en texte. Rendu : une carte des étiquettes par vue
// (niveau de gris = rang de la région) coloriée pixel par pixel dans une
// image, puis les traits et le modelé de l'image par-dessus.
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'muscle_map_regions.dart';

export 'muscle_map_regions.dart';

/// Un filtre de l'écran Anatomie (groupe de régions).
class MapGroup {
  final String id, label;
  const MapGroup(this.id, this.label);
}

/// Une région dessinée de la carte : muscles du pack montrés, filtre.
class MapRegion {
  final String id, label;
  final List<String> muscles;
  final String? group;
  const MapRegion(this.id, this.label, this.muscles, this.group);
}

/// Valeurs particulières de la carte des étiquettes.
const kMapSombre = 253, kMapPeau = 254;

/// Libellé d'un groupe (filtre).
String mapGroupLabel(String id) => kMapGroups
    .firstWhere((g) => g.id == id, orElse: () => MapGroup(id, id))
    .label;

/// Région d'un identifiant.
MapRegion? mapRegion(String id) {
  for (final r in kMapRegions) {
    if (r.id == id) return r;
  }
  return null;
}

/// Régions montrant chaque muscle du pack (un muscle profond n'en a pas).
final Map<String, List<String>> kMuscleRegions = () {
  final out = <String, List<String>>{};
  for (final r in kMapRegions) {
    for (final m in r.muscles) {
      (out[m] ??= []).add(r.id);
    }
  }
  return out;
}();

/// Muscle du pack dessiné sur la carte (sinon : profond, listé en texte).
bool mapDrawsMuscle(String muscle) => kMuscleRegions.containsKey(muscle);

/// Groupes (filtres) de chaque groupe historique de l'application (repli
/// d'un exercice sans fiche : `groupe:<g>`) ; le premier est le principal.
const kAppGroupToMap = <String, List<String>>{
  'pectoraux': ['pectoraux'],
  'épaules': ['deltoides', 'coiffe'],
  'biceps': ['biceps'],
  'triceps': ['triceps'],
  'avant-bras': ['avant_bras'],
  'gainage': ['abdominaux', 'obliques', 'lombaires'],
  'dos': ['dorsaux', 'trapezes'],
  'quadriceps': ['quadriceps'],
  'ischios': ['ischios'],
  'fessiers': ['fessiers'],
  'mollets': ['mollets'],
};

/// Intensité par rôle (mêmes valeurs que le mannequin 3D).
const kMapPrimary = 1.0, kMapSecondary = .62, kMapStabilizer = .35;

/// Seuil sous lequel une région reste grise (2 %, comme la carte historique).
const kMapMinIntensity = .02;

/// Intensité (0-1) par région d'après les rôles d'un exercice : une région
/// prend le rôle le plus fort de ses muscles.
Map<String, double> mapIntensitiesFromRoles({
  List<String> primaires = const [],
  List<String> secondaires = const [],
  List<String> stabilisateurs = const [],
}) {
  final out = <String, double>{};
  void add(List<String> ids, double v) {
    for (final id in ids) {
      for (final r in kMuscleRegions[id] ?? const <String>[]) {
        if (v > (out[r] ?? 0)) out[r] = v;
      }
    }
  }

  add(stabilisateurs, kMapStabilizer);
  add(secondaires, kMapSecondary);
  add(primaires, kMapPrimary);
  return out;
}

/// Intensité (0-1) par région pour des poids par muscle du pack ou par
/// groupe historique (`groupe:<g>`, exercice sans fiche : toutes les régions
/// de ses groupes). Une région prend le poids de son muscle le plus
/// sollicité, puis tout est ramené au plus fort ; seuil de 2 %.
Map<String, double> mapIntensitiesFromWeights(Map<String, double> weights) {
  final muscle = <String, double>{};
  final group = <String, double>{};
  weights.forEach((key, w) {
    if (w <= 0) return;
    if (key.startsWith('groupe:')) {
      final gs = kAppGroupToMap[key.substring(7)] ?? const <String>[];
      for (var i = 0; i < gs.length; i++) {
        group[gs[i]] = (group[gs[i]] ?? 0) + w * (i == 0 ? 1.0 : .6);
      }
    } else {
      muscle[key] = (muscle[key] ?? 0) + w;
    }
  });
  final region = <String, double>{};
  for (final r in kMapRegions) {
    var v = r.group == null ? 0.0 : (group[r.group] ?? 0);
    for (final m in r.muscles) {
      final w = muscle[m] ?? 0;
      if (w > v) v = w;
    }
    if (v > 0) region[r.id] = v;
  }
  if (region.isEmpty) return const {};
  final max = region.values.reduce((a, b) => a > b ? a : b);
  return {
    for (final e in region.entries)
      if (e.value / max > kMapMinIntensity) e.key: e.value / max,
  };
}

/// Toutes les régions des groupes [groups] au plus fort (Anatomie).
Map<String, double> mapIntensitiesFromGroups(Iterable<String> groups) {
  final set = groups.toSet();
  return {
    for (final r in kMapRegions)
      if (r.group != null && set.contains(r.group)) r.id: kMapPrimary,
  };
}

/// Muscles du pack dessinés dans un groupe (listes en texte, Anatomie).
List<String> mapGroupMuscles(String group) => [
  for (final r in kMapRegions)
    if (r.group == group) ...r.muscles,
];

/// Groupes dont au moins une région est allumée, dans l'ordre des filtres ;
/// régions sans groupe (cou, psoas, couturier) nommées à part.
List<String> mapWorkedLabels(Map<String, double> intensities) {
  final lit = {
    for (final e in intensities.entries)
      if (e.value > kMapMinIntensity) e.key,
  };
  final groups = {
    for (final r in kMapRegions)
      if (lit.contains(r.id) && r.group != null) r.group!,
  };
  return [
    for (final g in kMapGroups)
      if (groups.contains(g.id)) g.label,
    for (final r in kMapRegions)
      if (lit.contains(r.id) && r.group == null) r.label,
  ];
}

/// Résumé texte des groupes travaillés (jamais l'information par la
/// couleur seule).
String mapWorkedSummary(Map<String, double> intensities) {
  final labels = mapWorkedLabels(intensities);
  return labels.isEmpty ? 'Aucun groupe travaillé' : labels.join(' · ');
}

// ------------------------------------------------------------- couleurs --

/// Gris d'un muscle non travaillé, de la peau (tendons, rotules) et des
/// extrémités (tête, mains, pieds), selon le thème.
Color mapMuscleGray(bool dark) =>
    dark ? const Color(0xFF55565B) : const Color(0xFFC4C5C9);
Color mapSkinGray(bool dark) =>
    dark ? const Color(0xFF7A7B80) : const Color(0xFFE2E2E4);
Color mapDarkGray(bool dark) =>
    dark ? const Color(0xFF34353A) : const Color(0xFF5A5B60);

/// Traits de l'image (cernes, séparations) et modelé (fibres, volumes :
/// noir translucide posé sur les muscles).
Color mapContour(bool dark) =>
    dark ? const Color(0xFF0E0E10) : const Color(0xFF2A2B30);
const kMapShade = Color(0x73000000);

/// Couleur d'une région travaillée : du gris à la couleur dominante vive
/// selon l'intensité (principal vif, secondaire atténué, stabilisateur
/// pâle ; semaine de STATS : continue).
Color mapHeat(double v, bool dark, [KAccentSpec? accent]) {
  final a = accent ?? SL.accentSpec;
  final vivid = dark ? a.bright : (a.vividLight ?? a.vivid);
  final f = .22 + .78 * v.clamp(0.0, 1.0);
  return Color.lerp(mapMuscleGray(dark), vivid, f)!;
}

/// Couleur d'une valeur de la carte des étiquettes : région (1…), peau,
/// extrémités. Sur un support de la couleur dominante ([tint], carte du
/// jour de l'accueil) : toute la carte dans la couleur du texte posé sur ce
/// support, régions travaillées opaques, le reste en transparence.
Color mapLabelColor(
  int label,
  Map<String, double> intensities,
  bool dark, {
  Color? tint,
  String? selected,
}) {
  if (label == 0) return const Color(0x00000000);
  if (label == kMapPeau) {
    return tint?.withValues(alpha: .34) ?? mapSkinGray(dark);
  }
  if (label == kMapSombre) {
    return tint?.withValues(alpha: .14) ?? mapDarkGray(dark);
  }
  if (label > kMapRegions.length) return const Color(0x00000000);
  final r = kMapRegions[label - 1];
  final v = intensities[r.id] ?? 0;
  final lit = v > kMapMinIntensity && r.muscles.isNotEmpty;
  Color c;
  if (tint != null) {
    c = tint.withValues(alpha: lit ? .55 + .45 * v.clamp(0.0, 1.0) : .22);
  } else {
    c = lit ? mapHeat(v, dark) : mapMuscleGray(dark);
  }
  if (r.id == selected) {
    c = Color.lerp(c, dark ? Colors.white : Colors.black, .35)!;
  }
  return c;
}

// ----------------------------------------------------------------- vues --

/// Vues de la carte.
enum MapView {
  face('Face', 511, 980),
  dos('Dos', 489, 976),
  profil('Profil', 187, 980);

  final String label;

  /// Taille des cartes (px) : proportions de la vue.
  final double width, height;
  const MapView(this.label, this.width, this.height);

  String get labels => 'assets/muscles2d/$name/etiquettes.png';
  String get contour => 'assets/muscles2d/$name/contour.png';
  String get shade => 'assets/muscles2d/$name/ombre.png';
}

/// Carte des étiquettes décodée d'une vue.
class MapLabels {
  final int width, height;

  /// Une valeur par pixel.
  final Uint8List values;
  const MapLabels(this.width, this.height, this.values);

  int at(double fx, double fy) {
    final x = (fx * width).floor(), y = (fy * height).floor();
    if (x < 0 || y < 0 || x >= width || y >= height) return 0;
    return values[y * width + x];
  }

  /// Région sous un point (fractions de la vue), sinon null.
  String? regionAt(double fx, double fy) {
    final v = at(fx, fy);
    return v >= 1 && v <= kMapRegions.length ? kMapRegions[v - 1].id : null;
  }
}

final _labels = <MapView, Future<MapLabels>>{};
final _labelsReady = <MapView, MapLabels>{};

/// Tests : étiquettes d'une vue fournies directement (sans image).
@visibleForTesting
void debugSetMapLabels(MapView v, MapLabels? labels) {
  if (labels == null) {
    _labels.remove(v);
    _labelsReady.remove(v);
  } else {
    _labels[v] = Future.value(labels);
    _labelsReady[v] = labels;
  }
}

/// Étiquettes d'une vue déjà lues (toucher sans attente), sinon null.
MapLabels? mapLabelsIfLoaded(MapView v) => _labelsReady[v];

/// Étiquettes d'une vue (lues une fois).
Future<MapLabels> loadMapLabels(MapView v) => _labels[v] ??= () async {
  final data = await rootBundle.load(v.labels);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  final bytes = (await frame.image.toByteData())!.buffer.asUint8List();
  final w = frame.image.width, h = frame.image.height;
  frame.image.dispose();
  final values = Uint8List(w * h);
  for (var i = 0; i < values.length; i++) {
    values[i] = bytes[i * 4];
  }
  return _labelsReady[v] = MapLabels(w, h, values);
}();

/// Précharge les étiquettes et les calques (lancement de l'application).
Future<void> precacheMuscleMap(BuildContext context) async {
  for (final v in MapView.values) {
    if (!context.mounted) return;
    await precacheImage(AssetImage(v.contour), context);
    if (!context.mounted) return;
    await precacheImage(AssetImage(v.shade), context);
    await loadMapLabels(v);
  }
}

/// Précharge sans attendre (lancement de l'application).
void mapPrecacheInBackground(BuildContext context) =>
    unawaited(precacheMuscleMap(context));

/// Image d'une vue coloriée : pixels RGBA d'après [mapLabelColor].
Future<ui.Image> paintMapLabels(MapLabels labels, List<Color> lut) {
  final table = Uint32List(256);
  for (var i = 0; i < lut.length && i < 256; i++) {
    final c = lut[i];
    final a = (c.a * 255).round(), r = (c.r * 255).round();
    final g = (c.g * 255).round(), b = (c.b * 255).round();
    // RGBA en mémoire (petit-boutiste) : prémultiplié non requis ici
    table[i] = (a << 24) | (b << 16) | (g << 8) | r;
  }
  final pixels = Uint32List(labels.values.length);
  for (var i = 0; i < pixels.length; i++) {
    pixels[i] = table[labels.values[i]];
  }
  final done = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    pixels.buffer.asUint8List(),
    labels.width,
    labels.height,
    ui.PixelFormat.rgba8888,
    done.complete,
  );
  return done.future;
}

/// Carte 2D des muscles : une ou plusieurs vues côte à côte, chaque région
/// teintée selon [intensities] (par région ; 0 ou absent : gris). Fond
/// transparent (couleur du support). [onRegionTap] : région touchée (null :
/// hors d'une région).
class MuscleMap2D extends StatelessWidget {
  final Map<String, double> intensities;
  final List<MapView> views;
  final double height;

  /// Nom de chaque vue sous la figure.
  final bool viewLabels;

  /// Région mise en évidence (toucher, Anatomie).
  final String? selected;
  final ValueChanged<String?>? onRegionTap;
  final String semanticLabel;

  /// Support de la couleur dominante : carte teintée de cette couleur.
  final Color? tint;

  const MuscleMap2D({
    super.key,
    this.intensities = const {},
    this.views = MapView.values,
    this.height = 280,
    this.viewLabels = true,
    this.selected,
    this.onRegionTap,
    this.tint,
    this.semanticLabel = 'Carte des muscles',
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

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final worked = mapWorkedLabels(intensities);
    final labels = viewLabels && views.length > 1;
    return Semantics(
      label: worked.isEmpty
          ? '$semanticLabel : aucun muscle travaillé'
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
        MapFigure(
          key: ValueKey('map-${v.name}'),
          view: v,
          height: h,
          intensities: intensities,
          dark: dark,
          tint: tint,
          selected: selected,
          onRegionTap: onRegionTap,
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

/// Une vue de la carte : étiquettes coloriées, traits et modelé.
class MapFigure extends StatefulWidget {
  final MapView view;
  final double height;
  final Map<String, double> intensities;
  final bool dark;
  final Color? tint;
  final String? selected;
  final ValueChanged<String?>? onRegionTap;

  const MapFigure({
    super.key,
    required this.view,
    required this.height,
    required this.intensities,
    required this.dark,
    this.tint,
    this.selected,
    this.onRegionTap,
  });

  @override
  State<MapFigure> createState() => MapFigureState();
}

class MapFigureState extends State<MapFigure> {
  ui.Image? _image;
  String? _key, _pending;

  /// Image coloriée affichée (contrôles).
  ui.Image? get image => _image;

  /// Couleurs de chaque valeur d'étiquette pour l'état actuel.
  List<Color> get lut => [
    for (var i = 0; i < 256; i++)
      mapLabelColor(
        i,
        widget.intensities,
        widget.dark,
        tint: widget.tint,
        selected: widget.selected,
      ),
  ];

  String _signature() {
    final e = widget.intensities.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return '${widget.dark}|${widget.tint?.toARGB32()}|${widget.selected}|'
        '${SL.accentSpec.id}|${e.map((x) => '${x.key}=${x.value}').join(',')}';
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didUpdateWidget(MapFigure oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refresh();
  }

  Future<void> _refresh() async {
    final key = _signature();
    if (key == _key || key == _pending) return;
    _pending = key;
    final colors = lut;
    try {
      final labels = await loadMapLabels(widget.view);
      final image = await paintMapLabels(labels, colors);
      if (!mounted || _pending != key) {
        image.dispose();
        return;
      }
      setState(() {
        _image?.dispose();
        _image = image;
        _key = key;
      });
    } catch (_) {
      // Étiquettes illisibles : la vue reste vide (liste en texte à côté).
    } finally {
      if (_pending == key) _pending = null;
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.view;
    final width = widget.height * v.width / v.height;
    final tint = widget.tint;
    final stack = SizedBox(
      width: width,
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_image != null)
            RawImage(
              key: ValueKey('map-${v.name}-regions'),
              image: _image,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
            ),
          Image.asset(
            v.shade,
            key: ValueKey('map-${v.name}-ombre'),
            fit: BoxFit.fill,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            color: tint == null ? kMapShade : const Color(0x40000000),
            colorBlendMode: BlendMode.srcIn,
          ),
          Image.asset(
            v.contour,
            key: ValueKey('map-${v.name}-contour'),
            fit: BoxFit.fill,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            color: tint == null
                ? mapContour(widget.dark)
                : const Color(0x59000000),
            colorBlendMode: BlendMode.srcIn,
          ),
        ],
      ),
    );
    final tap = widget.onRegionTap;
    if (tap == null) return stack;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (d) async {
        final labels = mapLabelsIfLoaded(v) ?? await loadMapLabels(v);
        final r = labels.regionAt(
          d.localPosition.dx / width,
          d.localPosition.dy / widget.height,
        );
        tap(r != null && mapRegion(r)!.muscles.isNotEmpty ? r : null);
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

/// Utilisé par les tests : région sous un point d'une vue.
@visibleForTesting
Future<String?> mapRegionAt(MapView view, double fx, double fy) async =>
    (await loadMapLabels(view)).regionAt(fx, fy);
