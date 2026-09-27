// Rendu Flutter des démonstrations (L9b, KT-080) : reproduit le dessin du
// moteur de référence du pack (kt_pose.js 2.0.0) — silhouette, zones
// musculaires, accessoires et sol — avec les couleurs par rôles de la palette
// active. Réduction des animations : images clés fixes côte à côte.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'app_theme.dart';
import 'pose_engine.dart';

/// Rôles de couleur du moteur (jamais de couleur en dur hors neutres).
@immutable
class PoseRoles {
  final Color fond, accent, neutreMoyen, neutreMoyenLoin, neutreContraste;
  const PoseRoles({
    required this.fond,
    required this.accent,
    required this.neutreMoyen,
    required this.neutreMoyenLoin,
    required this.neutreContraste,
  });

  /// Rôles d'une palette (6 dominantes × 2 modes) : l'accent est celui de
  /// l'application (`KPalette.accent`), comme `roles()` du moteur de référence.
  factory PoseRoles.of(KAccentSpec spec, bool dark) => PoseRoles(
    fond: dark ? KPalette.black : KPalette.light,
    accent: KPalette(dark, spec).accent,
    neutreMoyen: KPalette.gray,
    neutreMoyenLoin: dark ? const Color(0xFF5E5E5E) : const Color(0xFFB4B4B4),
    neutreContraste: dark ? KPalette.light : KPalette.black,
  );

  /// Palette active de l'application.
  factory PoseRoles.current() => PoseRoles.of(SL.accentSpec, SL.dark);

  @override
  bool operator ==(Object other) =>
      other is PoseRoles &&
      other.fond == fond &&
      other.accent == accent &&
      other.neutreMoyenLoin == neutreMoyenLoin;

  @override
  int get hashCode => Object.hash(fond, accent, neutreMoyenLoin);
}

const _plateR = 0.125; // disque de 45 cm pour une taille de 1,80 m

/// Peint une pose (articulations [joints]) dans le cadre [viewBox] du moteur.
class PosePainter extends CustomPainter {
  final PoseAnimation pose;
  final Joints joints;
  final List<double> viewBox;
  final PoseRoles roles;
  final bool background;
  PosePainter({
    required this.pose,
    required this.joints,
    required this.viewBox,
    required this.roles,
    this.background = false,
  });

  late double _s;
  late Offset _o;

  Offset _p(Offset q) => Offset(
    (q.dx - viewBox[0]) * _s + _o.dx,
    (-q.dy - viewBox[1]) * _s + _o.dy,
  );

  Path _poly(List<Offset> pts) =>
      Path()..addPolygon([for (final q in pts) _p(q)], true);

  Paint _fill(Color c, [double opacity = 1]) =>
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..color = c.withValues(alpha: c.a * opacity);

  Paint _stroke(Color c, double w, [double opacity = 1]) =>
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(w * _s, .6)
        ..color = c.withValues(alpha: c.a * opacity);

  @override
  void paint(Canvas canvas, Size size) {
    _s = math.min(size.width / viewBox[2], size.height / viewBox[3]);
    _o = Offset(
      (size.width - viewBox[2] * _s) / 2,
      (size.height - viewBox[3] * _s) / 2,
    );
    if (background) {
      canvas.drawRect(
        Rect.fromLTWH(_o.dx, _o.dy, viewBox[2] * _s, viewBox[3] * _s),
        _fill(roles.fond),
      );
    }
    // sol
    canvas.drawLine(
      _p(Offset(viewBox[0], 0.004)),
      _p(Offset(viewBox[0] + viewBox[2], 0.004)),
      _stroke(roles.neutreContraste, 0.008),
    );
    _props(canvas, true);
    _body(canvas);
    _props(canvas, false);
  }

  void _body(Canvas canvas) {
    final zoneRoles = poseZoneRoles(pose.primaires, pose.secondaires);
    for (final sh in poseBodyShapes(pose.view, joints)) {
      final base = sh.far ? roles.neutreMoyenLoin : roles.neutreMoyen;
      if (sh.circle != null) {
        canvas.drawCircle(_p(sh.circle!.$1), sh.circle!.$2 * _s, _fill(base));
      } else {
        canvas.drawPath(_poly(sh.all!), _fill(base));
      }
      for (final z in sh.zones.entries) {
        final role = zoneRoles[z.key];
        if (role == null) continue;
        final visible = !pose.isFace || poseFaceFront.contains(z.key);
        final op = (role == 'prim' ? 1.0 : 0.45) * (sh.far ? 0.6 : 1.0);
        final pts = z.value;
        if (!visible) {
          final paint = _stroke(roles.accent, 0.006, op);
          if (pts != null) {
            canvas.drawPath(_poly(pts), paint);
          } else if (sh.circle != null) {
            canvas.drawCircle(_p(sh.circle!.$1), sh.circle!.$2 * _s, paint);
          }
          continue;
        }
        final paint = _fill(roles.accent, op);
        if (pts != null) {
          canvas.drawPath(_poly(pts), paint);
        } else if (sh.circle != null) {
          canvas.drawCircle(_p(sh.circle!.$1), sh.circle!.$2 * _s, paint);
        } else {
          canvas.drawPath(_poly(sh.all!), paint);
        }
      }
    }
  }

  void _line(
    Canvas canvas,
    Offset a,
    Offset b,
    double w, {
    double opacity = 1,
    bool dashed = false,
  }) {
    final paint = _stroke(roles.neutreContraste, w, opacity);
    if (!dashed) {
      canvas.drawLine(_p(a), _p(b), paint);
      return;
    }
    final path =
        Path()
          ..moveTo(_p(a).dx, _p(a).dy)
          ..lineTo(_p(b).dx, _p(b).dy);
    canvas.drawPath(dashPath(path, 0.03 * _s, 0.02 * _s), paint);
  }

  void _circle(
    Canvas canvas,
    Offset c,
    double r, {
    bool fill = false,
    double opacity = 1,
  }) {
    canvas.drawCircle(
      _p(c),
      r * _s,
      fill
          ? _fill(roles.neutreContraste, opacity)
          : _stroke(roles.neutreContraste, 0.012, opacity),
    );
  }

  /// Rectangle (x, y bas, largeur, hauteur) en repère du moteur.
  void _rect(
    Canvas canvas,
    double x,
    double y,
    double w,
    double h, {
    bool fill = false,
    double opacity = 1,
  }) {
    final r = Rect.fromPoints(_p(Offset(x, y + h)), _p(Offset(x + w, y)));
    canvas.drawRect(
      r,
      fill
          ? _fill(roles.neutreContraste, opacity)
          : (_stroke(roles.neutreContraste, 0.012, opacity)
            ..strokeCap = StrokeCap.butt),
    );
  }

  void _quad(Canvas canvas, Offset a, Offset ctrl, Offset b, double w) {
    final pa = _p(a), pc = _p(ctrl), pb = _p(b);
    canvas.drawPath(
      Path()
        ..moveTo(pa.dx, pa.dy)
        ..quadraticBezierTo(pc.dx, pc.dy, pb.dx, pb.dy),
      _stroke(roles.neutreContraste, w),
    );
  }

  Offset _mid(String a, String b) => Offset(
    (joints[a]!.dx + joints[b]!.dx) / 2,
    (joints[a]!.dy + joints[b]!.dy) / 2,
  );

  Offset _attach(String? att) {
    if (att == 'prises') return _mid('prise_g', 'prise_d');
    return joints[att] ?? joints['prise_d']!;
  }

  void _props(Canvas canvas, bool behindLayer) {
    final j = joints;
    for (final p in pose.props) {
      if (behindLayer != p.behind) continue;
      final t = p.type;
      if (p.isStatic) {
        final x = p.val('x'), y = p.val('y');
        switch (t) {
          case 'corde':
            final r = RRect.fromRectAndRadius(
              Rect.fromPoints(
                _p(Offset(x - 0.022, y + 0.03)),
                _p(Offset(x + 0.022, y - 0.07)),
              ),
              Radius.circular(0.01 * _s),
            );
            canvas.drawRRect(r, _fill(roles.neutreContraste, 0.35));
          case 'barre_fixe':
            _line(
              canvas,
              Offset(x - 0.5, 0),
              Offset(x - 0.5, y),
              0.02,
              opacity: 0.5,
            );
            _line(
              canvas,
              Offset(x - 0.5, y),
              Offset(x, y),
              0.012,
              opacity: 0.5,
            );
            _circle(canvas, Offset(x, y), 0.022, fill: true);
          case 'anneaux':
            _line(canvas, Offset(x, y + 0.03), Offset(x, y + 0.55), 0.01);
            _circle(canvas, Offset(x, y), 0.035);
          case 'barres_paralleles':
            if (pose.isFace) {
              _circle(canvas, Offset(x - 0.25, y), 0.02, fill: true);
              _circle(canvas, Offset(x + 0.25, y), 0.02, fill: true);
              _line(canvas, Offset(x - 0.25, 0), Offset(x - 0.25, y), 0.016);
              _line(canvas, Offset(x + 0.25, 0), Offset(x + 0.25, y), 0.016);
            } else {
              _line(canvas, Offset(x - 0.28, y), Offset(x + 0.28, y), 0.024);
              _line(canvas, Offset(x - 0.22, 0), Offset(x - 0.22, y), 0.018);
              _line(canvas, Offset(x + 0.22, 0), Offset(x + 0.22, y), 0.018);
            }
          case 'barre_basse':
            _line(canvas, Offset(x - 0.4, y), Offset(x + 0.4, y), 0.02);
            _line(canvas, Offset(x - 0.36, 0), Offset(x - 0.36, y), 0.016);
            _line(canvas, Offset(x + 0.36, 0), Offset(x + 0.36, y), 0.016);
          case 'banc':
            final w = p.opt('w') ?? 0.55;
            _rect(canvas, x, y - 0.035, w, 0.035, fill: true);
            _line(
              canvas,
              Offset(x + 0.05, 0),
              Offset(x + 0.05, y - 0.035),
              0.02,
            );
            _line(
              canvas,
              Offset(x + w - 0.05, 0),
              Offset(x + w - 0.05, y - 0.035),
              0.02,
            );
          case 'box':
            _rect(canvas, x, 0, p.opt('w') ?? 0.3, p.opt('h') ?? 0.3);
          case 'mur':
            _line(canvas, Offset(x, 0), Offset(x, 1.25), 0.02);
          case 'poteau':
            _line(canvas, Offset(x, 0), Offset(x, 1.3), 0.03);
          case 'poulie':
            _circle(canvas, Offset(x, y), 0.03);
            _line(
              canvas,
              Offset(x, 0),
              Offset(x, math.max(y, 1.1)),
              0.02,
              opacity: 0.45,
            );
            for (final k in p.to) {
              if (j[k] != null) _line(canvas, Offset(x, y), j[k]!, 0.008);
            }
          case 'elastique':
            for (final k in p.to) {
              if (j[k] != null) {
                _line(canvas, Offset(x, y), j[k]!, 0.012, dashed: true);
              }
            }
          case 'machine':
            _rect(canvas, x - 0.05, 0, 0.1, y + 0.5);
          case 'banc_incline':
            _line(canvas, Offset(x - 0.1, 0.1), Offset(x + 0.45, 0.55), 0.03);
            _line(canvas, Offset(x + 0.2, 0), Offset(x + 0.2, 0.35), 0.02);
          case 'cale':
            _rect(canvas, x - 0.03, 0, 0.06, 0.08, fill: true);
          case 'rameur':
            _line(
              canvas,
              const Offset(-0.8, 0.12),
              const Offset(0.35, 0.12),
              0.02,
            );
            _rect(canvas, 0.25, 0, 0.12, 0.3);
          case 'velo':
            _circle(canvas, const Offset(0.35, 0.18), 0.16);
            _line(
              canvas,
              const Offset(0, 0.55),
              const Offset(0.35, 0.18),
              0.02,
            );
            _line(canvas, Offset.zero, const Offset(0, 0.55), 0.02);
          case 'traineau':
            _rect(canvas, x - 0.12, 0, 0.24, 0.16);
            _line(canvas, Offset(x, 0.16), Offset(x, 0.75), 0.02);
            for (final k in p.to) {
              if (j[k] != null) _line(canvas, Offset(x, 0.3), j[k]!, 0.008);
            }
          case 'battle_rope':
            for (final k in p.to) {
              final a = j[k];
              if (a == null) continue;
              _quad(
                canvas,
                a,
                Offset((a.dx + x) / 2, a.dy + 0.25),
                Offset(x, y),
                0.015,
              );
            }
          case 'sol_surelevé' || 'marche':
            _rect(
              canvas,
              x,
              0,
              p.opt('w') ?? 0.4,
              p.opt('h') ?? 0.2,
              fill: true,
            );
        }
      } else if (p.between != null) {
        final a = j[p.between![0]], b = j[p.between![1]];
        if (a == null || b == null) continue;
        if (t == 'baton') {
          final d = b - a;
          final l = d.distance == 0 ? 1.0 : d.distance;
          final dd = d / l;
          _line(canvas, a - dd * 0.18, b + dd * 0.18, 0.014);
        } else if (t == 'corde_a_sauter') {
          final hx = (a.dx + b.dx) / 2, hy = (a.dy + b.dy) / 2;
          final footY = math.min(j['pied_g']!.dy, j['pied_d']!.dy);
          final other =
              footY > 0.03
                  ? footY - 0.04
                  : j['tete']!.dy + poseHeadRadius + 0.06;
          final cy = (hy + other) / 2, ry = (hy - other).abs() / 2;
          final c = _p(Offset(hx, cy));
          canvas.drawOval(
            Rect.fromCenter(center: c, width: 0.6 * _s, height: 2 * ry * _s),
            _stroke(roles.neutreContraste, 0.008),
          );
        } else if (t == 'elastique') {
          _line(canvas, a, b, 0.012, dashed: true);
        } else {
          _line(canvas, a, b, 0.018);
        }
      } else if (p.attach != null) {
        final q = _attach(p.attach) + p.offset;
        switch (t) {
          case 'barre_chargee':
            _circle(canvas, q, _plateR, fill: true, opacity: 0.22);
            _circle(canvas, q, _plateR);
            _circle(canvas, q, 0.016, fill: true);
          case 'barre_vue_face':
            _line(
              canvas,
              Offset(q.dx - 0.55, q.dy),
              Offset(q.dx + 0.55, q.dy),
              0.016,
            );
            _rect(
              canvas,
              q.dx - 0.62,
              q.dy - _plateR,
              0.05,
              2 * _plateR,
              fill: true,
            );
            _rect(
              canvas,
              q.dx + 0.57,
              q.dy - _plateR,
              0.05,
              2 * _plateR,
              fill: true,
            );
          case 'halteres':
            _line(
              canvas,
              Offset(q.dx - 0.05, q.dy),
              Offset(q.dx + 0.05, q.dy),
              0.012,
            );
            _rect(canvas, q.dx - 0.06, q.dy - 0.03, 0.025, 0.06, fill: true);
            _rect(canvas, q.dx + 0.035, q.dy - 0.03, 0.025, 0.06, fill: true);
          case 'kettlebell':
            _circle(canvas, Offset(q.dx, q.dy - 0.075), 0.05, fill: true);
            _quad(
              canvas,
              Offset(q.dx - 0.03, q.dy - 0.04),
              Offset(q.dx, q.dy + 0.02),
              Offset(q.dx + 0.03, q.dy - 0.04),
              0.012,
            );
          case 'lest':
            final b = j['bassin']!;
            _line(canvas, b, Offset(b.dx, b.dy - 0.14), 0.006);
            _circle(canvas, Offset(b.dx, b.dy - 0.19), 0.05, fill: true);
          case 'medecine_ball':
            _circle(canvas, q, 0.07, fill: true);
          case 'sac_leste':
            _circle(canvas, q, 0.07);
          case 'roue':
            _circle(canvas, Offset(q.dx, q.dy - 0.02), 0.06);
          case 'rouleau':
            _circle(canvas, Offset(q.dx, 0.05), 0.05);
          case 'disque':
            _circle(canvas, q, 0.08);
          case 'gilet':
            _line(canvas, _mid('bassin', 'cou'), j['cou']!, 0.1, opacity: 0.35);
          case 'elastique_assistance':
            _line(canvas, j['prise_d']!, j['pied_d']!, 0.012, dashed: true);
        }
      }
    }
  }

  @override
  bool shouldRepaint(PosePainter old) =>
      old.joints != joints || old.roles != roles || old.pose != pose;
}

/// Pointillés le long d'un tracé.
Path dashPath(Path source, double dash, double gap) {
  final out = Path();
  for (final m in source.computeMetrics()) {
    var d = 0.0;
    while (d < m.length) {
      out.addPath(m.extractPath(d, math.min(d + dash, m.length)), Offset.zero);
      d += dash + gap;
    }
  }
  return out;
}

/// Démonstration animée d'un exercice. Réduction des animations (réglage du
/// système) → images clés fixes côte à côte, numérotées.
class PoseDemo extends StatefulWidget {
  final PoseAnimation pose;
  final String label;
  final double height;
  const PoseDemo({
    super.key,
    required this.pose,
    required this.label,
    this.height = 220,
  });

  @override
  State<PoseDemo> createState() => _PoseDemoState();
}

class _PoseDemoState extends State<PoseDemo>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  late List<double> _vb = poseBBox(widget.pose);
  double _t = 0, _base = 0;
  bool _playing = true;
  bool _reduce = false;

  void _tick(Duration elapsed) {
    setState(() => _t = _base + elapsed.inMicroseconds / 1e6);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.disableAnimationsOf(context);
    _sync();
  }

  @override
  void didUpdateWidget(PoseDemo old) {
    super.didUpdateWidget(old);
    if (old.pose != widget.pose) {
      _vb = poseBBox(widget.pose);
      _t = _base = 0;
      if (_ticker.isActive) _ticker.stop();
    }
    _sync();
  }

  bool get _animated =>
      !_reduce &&
      widget.pose.keyframes.length > 1 &&
      poseDuration(widget.pose) > 0;

  void _sync() {
    final run = _animated && _playing;
    if (run && !_ticker.isActive) _ticker.start();
    if (!run && _ticker.isActive) {
      _ticker.stop();
      _base = _t;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Widget _frame(Joints joints, PoseRoles roles) => CustomPaint(
    painter: PosePainter(
      pose: widget.pose,
      joints: joints,
      viewBox: _vb,
      roles: roles,
    ),
    size: Size.infinite,
  );

  @override
  Widget build(BuildContext context) {
    final roles = PoseRoles.current();
    final kfs = widget.pose.keyframes;
    final steps = [
      for (var i = 0; i < kfs.length; i++) '${i + 1}. ${kfs[i].label}',
    ];
    final semantics =
        'Démonstration : ${widget.label}. '
        '${_animated ? (_playing ? 'Animation en cours' : 'Animation en pause') : 'Images fixes'} ; '
        'étapes : ${steps.join(', ')}.';
    if (!_animated) {
      return Semantics(
        label: semantics,
        image: true,
        child: ExcludeSemantics(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < kfs.length; i++)
                SizedBox(
                  width: kfs.length == 1 ? widget.height : widget.height * .62,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height:
                            kfs.length == 1
                                ? widget.height
                                : widget.height * .62,
                        child: _frame(poseOf(kfs[i], widget.pose.view), roles),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: SL.dim),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return Semantics(
      label: semantics,
      image: true,
      child: Stack(
        children: [
          ExcludeSemantics(
            child: SizedBox(
              height: widget.height,
              width: double.infinity,
              child: RepaintBoundary(
                child: _frame(poseJointsAt(widget.pose, _t), roles),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: IconButton(
              tooltip: _playing ? 'Mettre en pause' : 'Reprendre',
              icon: Icon(
                _playing
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
              ),
              onPressed: () {
                setState(() => _playing = !_playing);
                _sync();
              },
            ),
          ),
        ],
      ),
    );
  }
}
