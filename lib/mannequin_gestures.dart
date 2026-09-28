// M4c (mannequin 3D) : zoom au pincement et gestes du mannequin.
//
// Un doigt : rotation (horizontale seule dans une page qui défile : fiche,
// STATS). Deux doigts : zoom centré sur le point entre les doigts (le muscle
// visé reste sous les doigts) et déplacement de la vue une fois zoomé.
// Toucher bref : nom du muscle. Double toucher : retour à la vue par défaut
// (reconnu seulement quand la vue est zoomée, pour ne pas retarder le
// toucher bref le reste du temps).
//
// Le zoom réduit l'angle de champ de la caméra, qui ne bouge pas vers le
// modèle : jamais de traversée. Bornes : du corps entier (1×, vue par
// défaut) à 4× ; la fenêtre zoomée reste dans le cadre de la vue par défaut.
// Rien ici ne dépend de flutter_scene : testable sans GPU.
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Angle de champ vertical du mannequin à l'échelle 1 (corps entier).
const double kMannequinFovY = 28 * math.pi / 180;

/// Zoom maximal : un muscle de l'avant-bras remplit la vue.
const double kMannequinMaxZoom = 4;

/// Zoom et déplacement de la vue du mannequin.
///
/// [offset] : point visé moins le centre du mannequin, en coordonnées du
/// monde (la rotation tourne autour du point visé). Le plan de référence
/// est le plan perpendiculaire à l'axe de la caméra qui passe par le point
/// visé, à la distance [distance] de la caméra.
class MannequinZoom {
  double scale;
  vm.Vector3 offset;

  MannequinZoom({this.scale = 1, vm.Vector3? offset})
    : offset = offset ?? vm.Vector3.zero();

  MannequinZoom copy() => MannequinZoom(scale: scale, offset: offset.clone());

  /// Vue par défaut : corps entier, centré.
  bool get isDefault => scale <= 1.0001 && offset.length2 < 1e-12;

  void reset() {
    scale = 1;
    offset = vm.Vector3.zero();
  }

  /// Angle de champ vertical de la caméra.
  double get fovY => 2 * math.atan(math.tan(kMannequinFovY / 2) / scale);

  /// Demi-hauteur visible dans le plan de référence à l'échelle 1.
  static double baseHalfHeight(double distance) =>
      distance * math.tan(kMannequinFovY / 2);

  /// Point du plan de référence sous le point [p] d'une vue de taille
  /// [size] (relatif au centre du mannequin).
  vm.Vector3 planePoint(
    Offset p,
    Size size,
    vm.Vector3 right,
    vm.Vector3 up,
    double distance,
  ) {
    final h = baseHalfHeight(distance) / scale;
    final w = h * size.width / math.max(1, size.height);
    final nx = p.dx / math.max(1, size.width) * 2 - 1;
    final ny = 1 - p.dy / math.max(1, size.height) * 2;
    return offset + right * (nx * w) + up * (ny * h);
  }

  /// Zoom à l'échelle [target] (bornée) en gardant sous [focal] le même
  /// point du plan de référence.
  void zoomAt(
    double target,
    Offset focal,
    Size size,
    vm.Vector3 right,
    vm.Vector3 up,
    double distance,
  ) {
    final before = planePoint(focal, size, right, up, distance);
    scale = target.clamp(1.0, kMannequinMaxZoom);
    final after = planePoint(focal, size, right, up, distance);
    offset += before - after;
    clampTo(size, right, up, distance);
  }

  /// Pincement en cours, calculé depuis son début (sans cumul d'arrondis ni
  /// de bornes intermédiaires) : le point du plan de référence qui était
  /// sous [startFocal] au début, zoom [start], se retrouve sous [focal] à
  /// l'échelle [scale] (bornée), puis la fenêtre est bornée.
  static MannequinZoom pinched(
    MannequinZoom start,
    Offset startFocal,
    Offset focal,
    double scale,
    Size size,
    vm.Vector3 right,
    vm.Vector3 up,
    double distance,
  ) {
    final p = start.planePoint(startFocal, size, right, up, distance);
    final z = MannequinZoom(
      scale: scale.clamp(1.0, kMannequinMaxZoom),
      offset: start.offset.clone(),
    );
    z.offset += p - z.planePoint(focal, size, right, up, distance);
    z.clampTo(size, right, up, distance);
    return z;
  }

  /// Déplace la vue pour que le contenu suive les doigts de [delta] pixels.
  void pan(
    Offset delta,
    Size size,
    vm.Vector3 right,
    vm.Vector3 up,
    double distance,
  ) {
    final perPixel =
        2 * baseHalfHeight(distance) / scale / math.max(1, size.height);
    offset += right * (-delta.dx * perPixel) + up * (delta.dy * perPixel);
    clampTo(size, right, up, distance);
  }

  /// Garde la fenêtre zoomée dans le cadre de la vue par défaut (corps
  /// entier) : à l'échelle 1, la vue est exactement la vue par défaut.
  void clampTo(Size size, vm.Vector3 right, vm.Vector3 up, double distance) {
    final h0 = baseHalfHeight(distance);
    final w0 = h0 * size.width / math.max(1, size.height);
    final limH = h0 - h0 / scale, limW = w0 - w0 / scale;
    final ox = offset.dot(right), oy = offset.dot(up);
    final depth = offset - right * ox - up * oy;
    final d = depth.length;
    // Composante de profondeur (vue tournée après un déplacement) : bornée
    // comme la largeur, nulle à l'échelle 1.
    final keptDepth = d <= limW || d == 0 ? depth : depth * (limW / d);
    offset =
        keptDepth +
        right * ox.clamp(-limW, limW).toDouble() +
        up * oy.clamp(-limH, limH).toDouble();
  }

  /// Interpolation (transition vers une vue).
  static MannequinZoom lerp(MannequinZoom a, MannequinZoom b, double t) =>
      MannequinZoom(
        scale: a.scale + (b.scale - a.scale) * t,
        offset: a.offset + (b.offset - a.offset) * t,
      );
}

/// Pincement à deux doigts : ne gagne jamais un geste à un doigt (rotation
/// du mannequin, défilement de la page), gagne dès que deux doigts sont
/// posés sur le mannequin (la page ne défile pas pendant le zoom).
class PinchGestureRecognizer extends ScaleGestureRecognizer {
  PinchGestureRecognizer({super.debugOwner});

  final Set<int> _down = {};

  /// Doigts suivis (tests).
  int get pointers => _down.length;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _down.add(event.pointer);
    if (_down.length >= 2) resolve(GestureDisposition.accepted);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _down.remove(event.pointer);
    }
    super.handleEvent(event);
  }

  @override
  void rejectGesture(int pointer) {
    _down.remove(pointer);
    super.rejectGesture(pointer);
  }

  @override
  void resolve(GestureDisposition disposition) {
    // Un seul doigt : jamais gagnant.
    if (disposition == GestureDisposition.accepted && _down.length < 2) return;
    super.resolve(disposition);
  }

  @override
  String get debugDescription => 'pinch';
}

/// Couche de gestes du mannequin (sans rendu).
class MannequinGestures extends StatelessWidget {
  final Widget child;

  /// Rotation horizontale seule (page qui défile verticalement).
  final bool horizontalOnly;
  final GestureTapUpCallback? onTapUp;

  /// Null : double toucher non reconnu (vue par défaut).
  final VoidCallback? onDoubleTap;
  final VoidCallback? onRotateStart;
  final ValueChanged<Offset>? onRotate;
  final VoidCallback? onRotateEnd;
  final GestureScaleStartCallback? onPinchStart;
  final GestureScaleUpdateCallback? onPinchUpdate;
  final GestureScaleEndCallback? onPinchEnd;

  const MannequinGestures({
    super.key,
    required this.child,
    this.horizontalOnly = false,
    this.onTapUp,
    this.onDoubleTap,
    this.onRotateStart,
    this.onRotate,
    this.onRotateEnd,
    this.onPinchStart,
    this.onPinchUpdate,
    this.onPinchEnd,
  });

  @override
  Widget build(BuildContext context) {
    final recognizers = <Type, GestureRecognizerFactory>{
      TapGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            () => TapGestureRecognizer(debugOwner: this),
            (r) => r.onTapUp = onTapUp,
          ),
      PinchGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<PinchGestureRecognizer>(
            () => PinchGestureRecognizer(debugOwner: this),
            (r) => r
              ..onStart = onPinchStart
              ..onUpdate = onPinchUpdate
              ..onEnd = onPinchEnd,
          ),
      if (onDoubleTap != null)
        DoubleTapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<DoubleTapGestureRecognizer>(
              () => DoubleTapGestureRecognizer(debugOwner: this),
              (r) => r.onDoubleTap = onDoubleTap,
            ),
      if (horizontalOnly)
        HorizontalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<
              HorizontalDragGestureRecognizer
            >(() => HorizontalDragGestureRecognizer(debugOwner: this), (r) {
              r.onStart = (_) => onRotateStart?.call();
              r.onUpdate = (d) => onRotate?.call(Offset(d.delta.dx, 0));
              r.onEnd = (_) => onRotateEnd?.call();
            })
      else
        PanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
              () => PanGestureRecognizer(debugOwner: this),
              (r) {
                r.onStart = (_) => onRotateStart?.call();
                r.onUpdate = (d) => onRotate?.call(d.delta);
                r.onEnd = (_) => onRotateEnd?.call();
              },
            ),
    };
    return RawGestureDetector(
      gestures: recognizers,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}
