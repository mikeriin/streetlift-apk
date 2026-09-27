// Atlas musculaire du pack de contenu (L9b, KT-080) : 51 muscles superficiels
// dessinés (face et dos), une région par muscle et par côté ; les muscles
// profonds sont donnés en texte. Couleurs par rôles, jamais en dur.
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'atlas_data.dart';
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
    final s =
        (size.width / atlasViewWidth) < (size.height / atlasViewHeight)
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
            final paint =
                Paint()
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

/// Atlas face + dos d'un exercice, avec légende textuelle (l'information
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

  @override
  Widget build(BuildContext context) {
    final fills = exerciseAtlasFills(
      accent: SL.accent,
      focus: SL.text,
      primaires: primaires,
      secondaires: secondaires,
      stabilisateurs: stabilisateurs,
      etires: etires,
    );
    String names(List<String> ids) =>
        ids.map((m) => atlasMuscles[m]?.nom ?? m).join(', ');
    final label = [
      if (primaires.isNotEmpty) 'Principaux : ${names(primaires)}',
      if (secondaires.isNotEmpty) 'Secondaires : ${names(secondaires)}',
      if (stabilisateurs.isNotEmpty)
        'Stabilisateurs : ${names(stabilisateurs)}',
      if (etires.isNotEmpty) 'Étirés : ${names(etires)}',
    ].join('. ');
    Widget view(String v, String title) => Expanded(
      child: Column(
        children: [
          SizedBox(
            height: height,
            child: CustomPaint(
              size: Size.infinite,
              painter: AtlasPainter(
                view: v,
                fills: fills,
                body: KPalette.gray,
                marks: SL.text,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: SL.dim,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
    return Semantics(
      label: 'Atlas musculaire. $label',
      image: true,
      child: ExcludeSemantics(
        child: Row(children: [view('face', 'FACE'), view('dos', 'DOS')]),
      ),
    );
  }
}

/// Légende des rôles de l'atlas (motif + texte).
class AtlasRoleLegend extends StatelessWidget {
  const AtlasRoleLegend({super.key});

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
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        item(
          'Principal (plein)',
          BoxDecoration(
            color: SL.accent,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        item(
          'Secondaire (atténué)',
          BoxDecoration(
            color: SL.accent.withValues(alpha: .42),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        item(
          'Stabilisateur (contour)',
          BoxDecoration(
            border: Border.all(color: SL.accent, width: 1.6),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }
}
