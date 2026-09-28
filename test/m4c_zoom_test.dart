// M4c : zoom au pincement du mannequin 3D. Calcul du zoom (bornes, point
// focal stable, retour à la vue par défaut) et gestes sans GPU : pincement,
// rotation, défilement de la page, toucher et double toucher.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streetlift_tracker/mannequin_gestures.dart';
import 'package:vector_math/vector_math.dart' as vm;

void main() {
  final right = vm.Vector3(1, 0, 0), up = vm.Vector3(0, 1, 0);
  const size = Size(360, 480);
  const distance = 4.2;

  group('calcul du zoom', () {
    test('bornes : corps entier (1×) à 4×', () {
      final z = MannequinZoom();
      expect(z.isDefault, isTrue);
      z.zoomAt(10, const Offset(180, 240), size, right, up, distance);
      expect(z.scale, kMannequinMaxZoom);
      z.zoomAt(.2, const Offset(180, 240), size, right, up, distance);
      expect(z.scale, 1);
      // À 1×, la vue est exactement la vue par défaut, même après un
      // zoom décentré.
      z.zoomAt(3, const Offset(20, 30), size, right, up, distance);
      expect(z.offset.length, greaterThan(0));
      z.zoomAt(1, const Offset(300, 400), size, right, up, distance);
      expect(z.isDefault, isTrue);
      expect(z.fovY, closeTo(kMannequinFovY, 1e-5));
    });

    test('angle de champ divisé par le zoom (tangente)', () {
      final z = MannequinZoom(scale: 4);
      expect(vm.degrees(z.fovY), closeTo(vm.degrees(kMannequinFovY) / 4, .2));
    });

    test('point focal stable : le point sous les doigts reste en place', () {
      for (final focal in const [
        Offset(180, 240),
        Offset(90, 120),
        Offset(250, 330),
        Offset(200, 100),
      ]) {
        final z = MannequinZoom();
        var before = z.planePoint(focal, size, right, up, distance);
        for (final s in [1.5, 2.2, 3.1]) {
          z.zoomAt(s, focal, size, right, up, distance);
          final after = z.planePoint(focal, size, right, up, distance);
          expect(
            (after - before).length,
            lessThan(1e-5),
            reason: '$focal à $s×',
          );
          before = after;
        }
      }
    });

    test('bord de la vue : la fenêtre zoomée reste dans la vue d’ensemble', () {
      final z = MannequinZoom();
      // Pincement au bord supérieur gauche : le point exact ne peut rester
      // sous les doigts sans sortir du cadre, la vue s'arrête au bord.
      z.zoomAt(4, Offset.zero, size, right, up, distance);
      final h0 = MannequinZoom.baseHalfHeight(distance);
      final w0 = h0 * size.width / size.height;
      expect(z.offset.x, closeTo(-(w0 - w0 / 4), 1e-5));
      expect(z.offset.y, closeTo(h0 - h0 / 4, 1e-5));
      // Coin de la fenêtre zoomée = coin de la vue d'ensemble.
      final corner = z.planePoint(Offset.zero, size, right, up, distance);
      expect(corner.x, closeTo(-w0, 1e-5));
      expect(corner.y, closeTo(h0, 1e-5));
    });

    test('pincement calculé depuis son début : doigts qui bougent '
        'inégalement, le point touché reste sous les doigts', () {
      const start = Offset(90, 300);
      final z0 = MannequinZoom();
      final p = z0.planePoint(start, size, right, up, distance);
      var z = z0;
      // Doigts qui avancent l'un après l'autre : le point entre eux oscille.
      for (var i = 1; i <= 12; i++) {
        final focal = start + Offset(i.isOdd ? -4 : 3, i.isOdd ? 2 : -1);
        final s = 1 + i * .25;
        z = MannequinZoom.pinched(
          z0,
          start,
          focal,
          s,
          size,
          right,
          up,
          distance,
        );
        final q = z.planePoint(focal, size, right, up, distance);
        expect((q - p).length, lessThan(1e-5), reason: 'pas $i');
      }
      expect(z.scale, kMannequinMaxZoom);
    });

    test('déplacement à deux doigts : le contenu suit les doigts', () {
      final z = MannequinZoom(scale: 3);
      const focal = Offset(180, 240);
      final p = z.planePoint(focal, size, right, up, distance);
      z.pan(const Offset(30, -20), size, right, up, distance);
      final moved = z.planePoint(
        focal + const Offset(30, -20),
        size,
        right,
        up,
        distance,
      );
      expect((moved - p).length, lessThan(1e-5));
      // Sans zoom, aucun déplacement possible.
      final flat = MannequinZoom()
        ..pan(const Offset(80, 80), size, right, up, distance);
      expect(flat.isDefault, isTrue);
    });

    test('vue tournée après un déplacement : profondeur bornée', () {
      final z = MannequinZoom(scale: 2, offset: vm.Vector3(0, 0, 5));
      z.clampTo(size, right, up, distance);
      final h0 = MannequinZoom.baseHalfHeight(distance);
      final w0 = h0 * size.width / size.height;
      expect(z.offset.z, closeTo(w0 - w0 / 2, 1e-5));
      z.zoomAt(1, const Offset(10, 10), size, right, up, distance);
      expect(z.isDefault, isTrue);
    });

    test('interpolation vers la vue par défaut', () {
      final a = MannequinZoom(scale: 3, offset: vm.Vector3(.2, .1, 0));
      final mid = MannequinZoom.lerp(a, MannequinZoom(), .5);
      expect(mid.scale, 2);
      expect(mid.offset.x, closeTo(.1, 1e-6));
      expect(MannequinZoom.lerp(a, MannequinZoom(), 1).isDefault, isTrue);
    });
  });

  group('gestes', () {
    late List<String> events;
    late double lastScale;

    Widget page({required bool horizontalOnly, bool doubleTap = false}) =>
        MaterialApp(
          home: Scaffold(
            body: ListView(
              key: const ValueKey('page'),
              children: [
                const SizedBox(height: 200),
                MannequinGestures(
                  key: const ValueKey('mannequin-view'),
                  horizontalOnly: horizontalOnly,
                  onTapUp: (_) => events.add('tap'),
                  onDoubleTap: doubleTap ? () => events.add('double') : null,
                  onRotateStart: () => events.add('rotate-start'),
                  onRotate: (d) => events.add('rotate'),
                  onRotateEnd: () => events.add('rotate-end'),
                  onPinchStart: (_) => events.add('pinch-start'),
                  onPinchUpdate: (d) {
                    events.add('pinch');
                    lastScale = d.scale;
                  },
                  onPinchEnd: (_) => events.add('pinch-end'),
                  child: const SizedBox(height: 400, width: 360),
                ),
                const SizedBox(height: 1600),
              ],
            ),
          ),
        );

    double scrolled(WidgetTester tester) => tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byKey(const ValueKey('page')),
            matching: find.byType(Scrollable),
          ),
        )
        .position
        .pixels;

    setUp(() {
      events = [];
      lastScale = 1;
    });

    Future<void> pinch(WidgetTester tester, {double spread = 60}) async {
      final c = tester.getCenter(find.byKey(const ValueKey('mannequin-view')));
      final a = await tester.startGesture(c - const Offset(30, 10), pointer: 1);
      await tester.pump(const Duration(milliseconds: 20));
      final b = await tester.startGesture(c + const Offset(30, 10), pointer: 2);
      await tester.pump(const Duration(milliseconds: 20));
      for (var i = 0; i < 6; i++) {
        await a.moveBy(Offset(-spread / 6, 0));
        await b.moveBy(Offset(spread / 6, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await a.up();
      await b.up();
      await tester.pump(const Duration(milliseconds: 400));
    }

    for (final horizontalOnly in [true, false]) {
      testWidgets('pincement : zoom, la page ne défile pas '
          '(${horizontalOnly ? 'fiche, rotation horizontale' : 'Anatomie'})', (
        tester,
      ) async {
        await tester.pumpWidget(page(horizontalOnly: horizontalOnly));
        await pinch(tester);
        expect(events, contains('pinch-start'));
        expect(events, contains('pinch'));
        expect(lastScale, greaterThan(1.5));
        expect(events, isNot(contains('rotate')));
        expect(events, isNot(contains('tap')));
        expect(scrolled(tester), 0);
      });

      testWidgets('deux doigts rapprochés : dézoom '
          '(${horizontalOnly ? 'fiche' : 'Anatomie'})', (tester) async {
        await tester.pumpWidget(page(horizontalOnly: horizontalOnly));
        final c = tester.getCenter(
          find.byKey(const ValueKey('mannequin-view')),
        );
        final a = await tester.startGesture(
          c - const Offset(80, 0),
          pointer: 1,
        );
        final b = await tester.startGesture(
          c + const Offset(80, 0),
          pointer: 2,
        );
        for (var i = 0; i < 5; i++) {
          await a.moveBy(const Offset(12, 0));
          await b.moveBy(const Offset(-12, 0));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await a.up();
        await b.up();
        await tester.pump();
        expect(lastScale, lessThan(.8));
        expect(scrolled(tester), 0);
      });
    }

    testWidgets('fiche : un doigt vertical fait défiler la page, '
        'horizontal tourne le mannequin', (tester) async {
      await tester.pumpWidget(page(horizontalOnly: true));
      await tester.drag(
        find.byKey(const ValueKey('mannequin-view')),
        const Offset(0, -150),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(scrolled(tester), greaterThan(100));
      expect(events, isNot(contains('rotate')));
      expect(events, isNot(contains('pinch')));
      events.clear();
      final before = scrolled(tester);
      await tester.drag(
        find.byKey(const ValueKey('mannequin-view')),
        const Offset(-150, 0),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(events, contains('rotate'));
      expect(events, isNot(contains('pinch')));
      expect(scrolled(tester), before);
    });

    testWidgets('Anatomie : un doigt tourne le mannequin, jamais de zoom', (
      tester,
    ) async {
      await tester.pumpWidget(page(horizontalOnly: false));
      await tester.timedDrag(
        find.byKey(const ValueKey('mannequin-view')),
        const Offset(-120, 20),
        const Duration(milliseconds: 300),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(events, contains('rotate'));
      expect(events, isNot(contains('pinch-start')));
    });

    testWidgets('toucher bref immédiat sans zoom ; double toucher une fois '
        'zoomé', (tester) async {
      await tester.pumpWidget(page(horizontalOnly: true));
      await tester.tap(find.byKey(const ValueKey('mannequin-view')));
      await tester.pump();
      expect(events, ['tap']);
      events.clear();
      await tester.pumpWidget(page(horizontalOnly: true, doubleTap: true));
      final view = find.byKey(const ValueKey('mannequin-view'));
      await tester.tap(view);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tap(view);
      await tester.pump(const Duration(milliseconds: 400));
      expect(events, ['double']);
      events.clear();
      // Toucher simple, vue zoomée : nom du muscle après le délai du double.
      await tester.tap(view);
      await tester.pump(const Duration(milliseconds: 400));
      expect(events, ['tap']);
    });
  });
}
