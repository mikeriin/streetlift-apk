// L9b (KT-080) — moteur des démonstrations : concordance avec le moteur de
// référence du pack (kt_pose.js 2.0.0), recoloration par palettes, réduction
// des animations. Fixtures exportées par tools/content_pack_import.py :
// positions de chaque image clé (poses.json du pack) et 20 exercices × 5
// instants calculés par le moteur JavaScript de référence.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/pose_engine.dart';
import 'package:streetlift_tracker/pose_painter.dart';

Map<String, dynamic> _gz(String path) =>
    jsonDecode(utf8.decode(gzip.decode(File(path).readAsBytesSync())))
        as Map<String, dynamic>;

double _contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05);
}

/// Accents du moteur de référence (kt_pose.js, ACCENTS) : sombre, clair.
const _referenceAccents = {
  'rouge': (0xFFE85959, 0xFF6B0C0C),
  'jaune': (0xFFF5C400, 0xFF7A5800),
  'vert': (0xFF4EC08A, 0xFF0B4D33),
  'violet': (0xFFB38CF2, 0xFF44146B),
  'orange': (0xFFF2924A, 0xFF6E2E05),
  'turquoise': (0xFF3EC4C4, 0xFF08494F),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final poses = _gz('assets/content/poses.json.gz');
  final gabarits = poses['gabarits'] as Map<String, dynamic>;
  final exercices = poses['exercices'] as Map<String, dynamic>;

  PoseAnimation animationOf(String id) {
    final e = exercices[id] as Map<String, dynamic>;
    return PoseAnimation.fromPack(
      gabarits[e['gabarit']] as Map<String, dynamic>,
      e,
    );
  }

  group('concordance avec le moteur de référence', () {
    test('toutes les images clés des 246 gabarits (écart < 0,002)', () {
      final expected = _gz('test/fixtures/l9b/keyframe_joints.json.gz');
      expect(expected.length, gabarits.length);
      var worst = 0.0, count = 0;
      for (final entry in gabarits.entries) {
        final anim = PoseAnimation.fromPack(
          entry.value as Map<String, dynamic>,
        );
        final frames = expected[entry.key] as List;
        expect(frames.length, anim.keyframes.length, reason: entry.key);
        for (var i = 0; i < frames.length; i++) {
          final j = poseOf(anim.keyframes[i], anim.view);
          for (final p in (frames[i] as Map<String, dynamic>).entries) {
            final v = p.value as List;
            final d = math.max(
              (j[p.key]!.dx - (v[0] as num)).abs(),
              (j[p.key]!.dy - (v[1] as num)).abs(),
            );
            worst = math.max(worst, d);
            count++;
            expect(d, lessThan(0.002), reason: '${entry.key} #$i ${p.key}');
          }
        }
      }
      expect(count, greaterThan(10000));
      // Positions du pack arrondies à 4 décimales (écart max. mesuré avec le
      // moteur de référence JavaScript : 9,8e-5).
      expect(worst, lessThan(2e-4));
    });

    test('20 exercices × 5 instants : positions identiques à 0,5 % près', () {
      final fixture =
          jsonDecode(
                File('test/fixtures/l9b/pose_parity.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final list = fixture['exercices'] as List;
      expect(list.length, 20);
      var worst = 0.0;
      for (final raw in list) {
        final x = raw as Map<String, dynamic>;
        final anim = animationOf(x['id'] as String);
        expect(anim.view, x['view']);
        expect(poseDuration(anim), closeTo((x['duration'] as num), 1e-9));
        final bbox = poseBBox(anim);
        final eb = x['bbox'] as List;
        for (var i = 0; i < 4; i++) {
          expect(bbox[i], closeTo((eb[i] as num).toDouble(), 1e-9));
        }
        final samples = x['samples'] as List;
        expect(samples.length, 5);
        for (final s in samples) {
          final t = ((s as Map)['t'] as num).toDouble();
          final j = poseJointsAt(anim, t);
          final joints = s['joints'] as Map<String, dynamic>;
          expect(j.keys.toSet(), joints.keys.toSet());
          for (final p in joints.entries) {
            final v = p.value as List;
            final d = math.max(
              (j[p.key]!.dx - (v[0] as num)).abs(),
              (j[p.key]!.dy - (v[1] as num)).abs(),
            );
            worst = math.max(worst, d);
            // 0,5 % de la taille du personnage (unité = taille).
            expect(d, lessThan(0.005), reason: '${x['id']} t=$t ${p.key}');
          }
        }
      }
      // Même calcul en double précision : écart numérique seulement.
      expect(worst, lessThan(1e-9));
    });

    test('courbe d\'accélération et chronologie du moteur', () {
      expect(poseEase(0), 0);
      expect(poseEase(.5), closeTo(.5, 1e-12));
      expect(poseEase(1), closeTo(1, 1e-12));
      final cycles = [
        for (final e in exercices.entries)
          if ((e.value as Map)['statut'] == 'disponible' &&
              (gabarits[(e.value as Map)['gabarit']] as Map)['boucle'] ==
                  'cycle')
            e.key,
      ];
      expect(cycles, isNotEmpty);
      final a = animationOf(cycles.first);
      final steps = poseTimeline(a);
      expect(steps.length, a.keyframes.length);
      expect(steps.last.b, 0);
      // Bouclage : t et t + durée donnent la même pose.
      final d = poseDuration(a);
      final p1 = poseJointsAt(a, .3), p2 = poseJointsAt(a, .3 + d);
      for (final k in p1.keys) {
        expect((p1[k]! - p2[k]!).distance, lessThan(1e-9));
      }
    });

    test('toutes les démonstrations disponibles se calculent sans erreur', () {
      var n = 0;
      for (final e in exercices.entries) {
        final m = e.value as Map;
        if (m['statut'] == 'indisponible') continue;
        final anim = animationOf(e.key);
        final d = poseDuration(anim);
        for (final f in const [0.0, .25, .5, .75]) {
          final j = poseJointsAt(anim, f * d);
          for (final p in j.values) {
            expect(p.dx.isFinite && p.dy.isFinite, isTrue, reason: e.key);
          }
          expect(poseBodyShapes(anim.view, j), isNotEmpty);
        }
        n++;
      }
      expect(n, greaterThan(600));
    });
  });

  group('recoloration par rôles', () {
    test('6 palettes × 2 modes : accent du moteur de référence', () {
      for (final spec in KAccentSpec.all) {
        final ref = _referenceAccents[spec.id]!;
        for (final dark in const [true, false]) {
          final r = PoseRoles.of(spec, dark);
          expect(
            r.accent,
            Color(dark ? ref.$1 : ref.$2),
            reason: '${spec.id} $dark',
          );
          expect(r.neutreMoyen, const Color(0xFF8A8A8A));
          expect(r.fond, dark ? KPalette.black : KPalette.light);
          // Objets graphiques (WCAG 1.4.11) : ≥ 3:1 sur le fond.
          expect(
            _contrast(r.accent, r.fond),
            greaterThanOrEqualTo(3),
            reason: '${spec.id} $dark',
          );
          expect(_contrast(r.neutreMoyen, r.fond), greaterThanOrEqualTo(3));
          expect(_contrast(r.neutreContraste, r.fond), greaterThan(7));
        }
      }
    });

    test('rendu de référence : seule la teinte active est peinte', () async {
      final anim = animationOf('pompes');
      expect(anim.primaires, isNotEmpty);
      final j = poseJointsAt(anim, 0);
      final vb = poseBBox(anim);
      final all = <int>{
        for (final r in _referenceAccents.values) ...[r.$1, r.$2],
      };
      for (final spec in KAccentSpec.all) {
        for (final dark in const [true, false]) {
          final roles = PoseRoles.of(spec, dark);
          final recorder = ui.PictureRecorder();
          PosePainter(
            pose: anim,
            joints: j,
            viewBox: vb,
            roles: roles,
            background: true,
          ).paint(Canvas(recorder), const Size(240, 240));
          final image = await recorder.endRecording().toImage(240, 240);
          final bytes =
              (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
          image.dispose();
          final seen = <int>{};
          for (var i = 0; i < bytes.lengthInBytes; i += 4) {
            final c =
                (bytes.getUint8(i + 3) << 24) |
                (bytes.getUint8(i) << 16) |
                (bytes.getUint8(i + 1) << 8) |
                bytes.getUint8(i + 2);
            seen.add(c);
          }
          final own = roles.accent.toARGB32();
          expect(seen, contains(own), reason: '${spec.id} $dark');
          expect(
            seen,
            contains(roles.neutreMoyen.toARGB32()),
            reason: '${spec.id} $dark corps',
          );
          for (final other in all.difference({own})) {
            expect(seen.contains(other), isFalse, reason: '${spec.id} $dark');
          }
        }
      }
    });
  });

  group('lecture et réduction des animations', () {
    Widget host(Widget child, {bool reduce = false}) => MaterialApp(
      theme: buildTheme(true),
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          disableAnimations: reduce,
        ),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

    testWidgets('animation : la pose change au fil du temps', (tester) async {
      final anim = animationOf('pompes');
      await tester.pumpWidget(host(PoseDemo(pose: anim, label: 'Pompes')));
      final first = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(PoseDemo),
          matching: find.byType(CustomPaint),
        ).first,
      );
      final j0 = (first.painter! as PosePainter).joints;
      await tester.pump(const Duration(milliseconds: 900));
      final later = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(PoseDemo),
          matching: find.byType(CustomPaint),
        ).first,
      );
      final j1 = (later.painter! as PosePainter).joints;
      expect(
        j0.keys.any((k) => (j0[k]! - j1[k]!).distance > 1e-3),
        isTrue,
      );
      // Pause : la pose ne bouge plus.
      await tester.tap(find.byTooltip('Mettre en pause'));
      await tester.pump();
      final paused =
          (tester
                      .widget<CustomPaint>(
                        find.descendant(
                          of: find.byType(PoseDemo),
                          matching: find.byType(CustomPaint),
                        ).first,
                      )
                      .painter!
                  as PosePainter)
              .joints;
      await tester.pump(const Duration(milliseconds: 700));
      final still =
          (tester
                      .widget<CustomPaint>(
                        find.descendant(
                          of: find.byType(PoseDemo),
                          matching: find.byType(CustomPaint),
                        ).first,
                      )
                      .painter!
                  as PosePainter)
              .joints;
      for (final k in paused.keys) {
        expect((paused[k]! - still[k]!).distance, lessThan(1e-12));
      }
      expect(find.byTooltip('Reprendre'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('réduction des animations : images clés fixes', (
      tester,
    ) async {
      final anim = animationOf('pompes');
      await tester.pumpWidget(
        host(PoseDemo(pose: anim, label: 'Pompes'), reduce: true),
      );
      await tester.pumpAndSettle(); // aucune animation en cours
      final paints = find.descendant(
        of: find.byType(PoseDemo),
        matching: find.byType(CustomPaint),
      );
      expect(paints, findsNWidgets(anim.keyframes.length));
      for (var i = 0; i < anim.keyframes.length; i++) {
        final p = tester.widget<CustomPaint>(paints.at(i)).painter!;
        final expected = poseOf(anim.keyframes[i], anim.view);
        final got = (p as PosePainter).joints;
        for (final k in expected.keys) {
          expect((got[k]! - expected[k]!).distance, lessThan(1e-12));
        }
        expect(
          find.text('${i + 1}. ${anim.keyframes[i].label}'),
          findsOneWidget,
        );
      }
      expect(find.byTooltip('Mettre en pause'), findsNothing);
      expect(tester.takeException(), null);
    });
  });
}
