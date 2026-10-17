// Atlas musculaire du pack de contenu (L9b, KT-080) : 51 muscles superficiels
// dessinés (face et dos), une région par muscle et par côté ; les muscles
// profonds sont donnés en texte. Couleurs par rôles, jamais en dur.
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'atlas_data.dart';
import 'muscle_body.dart';
import 'pose_painter.dart' show dashPath;

/// Remplissage d'une région : couleur, opacité, contour pointillé éventuel.
@immutable
class AtlasFill {
  final Color color;
  final double opacity;
  final bool outline, dashed, blur;
  const AtlasFill(
    this.color, {
    this.opacity = 1,
    this.outline = false,
    this.dashed = false,
    this.blur = false,
  });

  @override
  bool operator ==(Object other) =>
      other is AtlasFill &&
      other.color == color &&
      other.opacity == opacity &&
      other.outline == outline &&
      other.dashed == dashed &&
      other.blur == blur;

  @override
  int get hashCode => Object.hash(color, opacity, outline, dashed, blur);
}

final Map<AtlasRegion, List<Offset>> _pointsCache = {};

List<Offset> atlasPoints(AtlasRegion r) => _pointsCache.putIfAbsent(r, () {
  final v = r.points.split(' ').map(double.parse).toList();
  return [for (var i = 0; i + 1 < v.length; i += 2) Offset(v[i], v[i + 1])];
});

/// Groupes de l'application (11) visibles dans une vue de l'atlas.
Set<String> atlasGroupsIn(String view) => {
  for (final r in atlasRegions)
    if (r.view == view && r.kind == 'muscle')
      if (atlasMuscles[r.muscle]?.groupe case final String g) g,
};

/// Peint une vue de l'atlas (`face` ou `dos`) ; [fills] : muscle → rôle.
/// Les muscles sans rôle restent dans le ton du corps.
class AtlasPainter extends CustomPainter {
  final String view;
  final Map<String, List<AtlasFill>> fills;
  final Color body;
  final Color marks;
  AtlasPainter({
    required this.view,
    required this.fills,
    required this.body,
    required this.marks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = (size.width / atlasViewWidth) < (size.height / atlasViewHeight)
        ? size.width / atlasViewWidth
        : size.height / atlasViewHeight;
    final o = Offset(
      (size.width - atlasViewWidth * s) / 2,
      (size.height - atlasViewHeight * s) / 2,
    );
    Path path(AtlasRegion r) {
      final pts = [for (final p in atlasPoints(r)) o + p * s];
      return r.closed
          ? (Path()..addPolygon(pts, true))
          : (Path()..addPolygon(pts, false));
    }

    for (final r in atlasRegions) {
      if (r.view != view) continue;
      switch (r.kind) {
        case 'corps':
          canvas.drawPath(
            path(r),
            Paint()..color = body.withValues(alpha: .18),
          );
        case 'repere':
          canvas.drawPath(
            path(r),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1 * s
              ..color = marks.withValues(alpha: .35),
          );
        case 'muscle':
          final p = path(r);
          final roles = fills[r.muscle];
          if (roles == null || roles.every((f) => f.outline)) {
            canvas.drawPath(p, Paint()..color = body.withValues(alpha: .32));
          }
          for (final f in roles ?? const <AtlasFill>[]) {
            final paint = Paint()
              ..isAntiAlias = true
              ..color = f.color.withValues(alpha: f.color.a * f.opacity);
            if (f.blur) {
              paint.maskFilter = MaskFilter.blur(BlurStyle.normal, 7 * s);
            }
            if (f.outline) {
              paint
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.6 * s;
              canvas.drawPath(f.dashed ? dashPath(p, 4 * s, 3 * s) : p, paint);
            } else {
              canvas.drawPath(p, paint);
            }
          }
      }
    }
  }

  @override
  bool shouldRepaint(AtlasPainter old) =>
      old.view != view ||
      old.body != body ||
      old.marks != marks ||
      !_sameFills(old.fills, fills);

  static bool _sameFills(
    Map<String, List<AtlasFill>> a,
    Map<String, List<AtlasFill>> b,
  ) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      final o = b[e.key];
      if (o == null || o.length != e.value.length) return false;
      for (var i = 0; i < o.length; i++) {
        if (o[i] != e.value[i]) return false;
      }
    }
    return true;
  }
}

/// Rôles d'un exercice sur l'atlas : primaires (accent), secondaires (accent
/// atténué à 0,42), stabilisateurs (contour pointillé), étirés (contour).
Map<String, List<AtlasFill>> exerciseAtlasFills({
  required Color accent,
  required Color focus,
  List<String> primaires = const [],
  List<String> secondaires = const [],
  List<String> stabilisateurs = const [],
  List<String> etires = const [],
}) {
  final out = <String, List<AtlasFill>>{};
  void add(String m, AtlasFill f) => (out[m] ??= []).add(f);
  for (final m in primaires) {
    add(m, AtlasFill(accent));
  }
  for (final m in secondaires) {
    if (!primaires.contains(m)) add(m, AtlasFill(accent, opacity: .42));
  }
  for (final m in stabilisateurs) {
    add(m, AtlasFill(accent, outline: true, dashed: true));
  }
  for (final m in etires) {
    add(m, AtlasFill(focus, outline: true));
  }
  return out;
}

/// Intensités de la carte d'un exercice, par rôle (le plus fort l'emporte).
const exerciseRoleHeat = (
  primaire: 1.0,
  secondaire: .62,
  stabilisateur: .35,
  etire: .25,
);

/// Agrège les muscles d'un exercice (81 muscles de l'atlas) en intensités par
/// groupe de l'application (11 groupes), selon [exerciseRoleHeat].
Map<String, double> exerciseGroupIntensities({
  List<String> primaires = const [],
  List<String> secondaires = const [],
  List<String> stabilisateurs = const [],
  List<String> etires = const [],
}) {
  final out = <String, double>{};
  void add(Iterable<String> ids, double value) {
    for (final id in ids) {
      final group = atlasMuscles[id]?.groupe;
      if (group != null && (out[group] ?? 0) < value) out[group] = value;
    }
  }

  add(etires, exerciseRoleHeat.etire);
  add(stabilisateurs, exerciseRoleHeat.stabilisateur);
  add(secondaires, exerciseRoleHeat.secondaire);
  add(primaires, exerciseRoleHeat.primaire);
  return out;
}

/// Carte anatomique face / dos / profil d'un exercice (illustrations
/// historiques, calques par groupe), avec description textuelle (l'information
/// n'est jamais portée par la couleur seule).
class ExerciseAtlas extends StatelessWidget {
  final List<String> primaires, secondaires, stabilisateurs, etires;
  final double height;
  const ExerciseAtlas({
    super.key,
    this.primaires = const [],
    this.secondaires = const [],
    this.stabilisateurs = const [],
    this.etires = const [],
    this.height = 240,
  });

  /// Intensité par groupe (0-1) affichée par la carte.
  Map<String, double> get groupIntensities => exerciseGroupIntensities(
    primaires: primaires,
    secondaires: secondaires,
    stabilisateurs: stabilisateurs,
    etires: etires,
  );

  @override
  Widget build(BuildContext context) {
    String names(List<String> ids) =>
        ids.map((m) => atlasMuscles[m]?.nom ?? m).join(', ');
    final label = [
      if (primaires.isNotEmpty) 'Principaux : ${names(primaires)}',
      if (secondaires.isNotEmpty) 'Secondaires : ${names(secondaires)}',
      if (stabilisateurs.isNotEmpty)
        'Stabilisateurs : ${names(stabilisateurs)}',
      if (etires.isNotEmpty) 'Étirés : ${names(etires)}',
    ].join('. ');
    return Semantics(
      label: 'Carte musculaire anatomique. $label',
      image: true,
      child: ExcludeSemantics(
        // Intensités par rôle, sans normalisation sur le maximum.
        child: MuscleHeatmap(
          data: groupIntensities,
          normalize: false,
          height: height,
          glow: true,
          views: const ['front', 'back', 'profile'],
        ),
      ),
    );
  }
}

/// Légende des rôles de la carte (rampe d'intensité + texte).
class AtlasRoleLegend extends StatelessWidget {
  /// M3 : teinte des muscles étirés sur le mannequin 3D (null : carte 2D,
  /// rampe à 0,25).
  final Color? stretchColor;

  /// M6b : mannequin 3D (maillage gris et halo, 5.5.4) : opacité du halo
  /// selon l'intensité (`MannequinHaloPainter.alphaFor`) ; chaque pastille
  /// montre alors le halo posé sur le gris des muscles [haloBase], comme sur
  /// le mannequin. Null : pastilles pleines (carte 2D).
  final double Function(double intensity)? haloAlpha;
  final Color haloBase;

  const AtlasRoleLegend({
    super.key,
    this.stretchColor,
    this.haloAlpha,
    this.haloBase = const Color(0xFF8F8B8A),
  });

  @override
  Widget build(BuildContext context) {
    Widget item(String text, BoxDecoration deco) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 14, decoration: deco),
        const SizedBox(width: 6),
        Flexible(
          child: Text(text, style: TextStyle(fontSize: 12, color: SL.text)),
        ),
      ],
    );
    BoxDecoration deco(Color color, double v) {
      final alpha = haloAlpha?.call(v);
      if (alpha == null) {
        return BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        );
      }
      final glow = color.withValues(alpha: alpha);
      return BoxDecoration(
        color: Color.alphaBlend(glow, haloBase),
        borderRadius: BorderRadius.circular(3),
        boxShadow: [BoxShadow(color: glow, blurRadius: 6, spreadRadius: 1)],
      );
    }

    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final (text, v) in [
          ('Principal', exerciseRoleHeat.primaire),
          ('Secondaire', exerciseRoleHeat.secondaire),
          ('Stabilisateur', exerciseRoleHeat.stabilisateur),
          ('Étiré', exerciseRoleHeat.etire),
        ])
          item(
            text,
            deco(
              text == 'Étiré' && stretchColor != null ? stretchColor! : heat(v),
              v,
            ),
          ),
      ],
    );
  }
}
