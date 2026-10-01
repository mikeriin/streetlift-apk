import 'package:kalis_koach/kalis_koach.dart';
import 'package:test/test.dart';

/// Boîte des extrémités de segments (sans points de contrôle) : doit tenir
/// dans la boîte déclarée.
KoachBox endpointsBounds(List<int> cmds) {
  final xs = <int>[], ys = <int>[];
  var i = 0;
  while (i < cmds.length) {
    switch (cmds[i]) {
      case koachMoveTo || koachLineTo:
        xs.add(cmds[i + 1]);
        ys.add(cmds[i + 2]);
        i += 3;
      case koachCubicTo:
        xs.add(cmds[i + 5]);
        ys.add(cmds[i + 6]);
        i += 7;
      default:
        i++;
    }
  }
  xs.sort();
  ys.sort();
  return KoachBox(xs.first, ys.first, xs.last, ys.last);
}

class _Recorder implements KoachPathSink {
  final ops = <String>[];
  @override
  void moveTo(double x, double y) => ops.add('M$x,$y');
  @override
  void lineTo(double x, double y) => ops.add('L$x,$y');
  @override
  void cubicTo(
          double x1, double y1, double x2, double y2, double x, double y) =>
      ops.add('C$x1,$y1,$x2,$y2,$x,$y');
  @override
  void close() => ops.add('Z');
}

void main() {
  group('catalogue des poses', () {
    test('36 poses, identifiants uniques et alignés sur les dessins', () {
      expect(KoachPose.values, hasLength(36));
      expect(KoachPose.values.map((p) => p.id).toSet(), hasLength(36));
      for (final p in KoachPose.values) {
        expect(p.art.id, p.id, reason: 'dessin de ${p.name}');
        expect(p.info.id, p.id, reason: 'fiche de ${p.name}');
        expect(KoachPose.byId(p.id), p);
      }
      expect(KoachPose.byId('inconnue'), isNull);
    });

    test('12 poses par planche, cases distinctes', () {
      for (final sheet in ['A', 'B', 'C']) {
        final inSheet =
            KoachPose.values.where((p) => p.info.sheet == sheet).toList();
        expect(inSheet, hasLength(12), reason: 'planche $sheet');
        expect(
            inSheet.map((p) => '${p.info.row}.${p.info.col}').toSet(),
            hasLength(12));
      }
    });

    test('yeux : calque présent si et seulement si yeux ouverts', () {
      for (final p in KoachPose.values) {
        expect(p.art.eyesOpen, p.info.eyesOpen, reason: p.id);
        expect(p.art.eyeBoxes, hasLength(p.info.eyesOpen ? 2 : 0),
            reason: p.id);
        if (p.info.eyesOpen) {
          final s = koachPathStats(p.art.eyes);
          expect(s.subpaths, greaterThanOrEqualTo(2), reason: p.id);
          // Œil gauche puis droit, à la hauteur de la tête.
          expect(p.art.eyeBoxes[0].centerX,
              lessThan(p.art.eyeBoxes[1].centerX));
          for (final e in p.art.eyeBoxes) {
            expect(e.centerY, inInclusiveRange(-700, -250), reason: p.id);
            expect(e.width, inInclusiveRange(40, 200), reason: p.id);
          }
        }
      }
    });

    test('poses connues aux yeux fermés', () {
      final closed = {
        for (final p in KoachPose.values)
          if (!p.info.eyesOpen) p
      };
      expect(closed, {
        KoachPose.happy,
        KoachPose.victory,
        KoachPose.cheer,
        KoachPose.heart,
        KoachPose.clap,
        KoachPose.fistUp,
        KoachPose.present,
      });
    });

    test('bustes : choix, idée, réglages', () {
      expect(
          {
            for (final p in KoachPose.values)
              if (p.info.framing == KoachFraming.bust) p
          },
          {KoachPose.choice, KoachPose.idea, KoachPose.settings});
    });

    test('chaque usage a au moins une pose', () {
      for (final u in KoachUsage.values) {
        expect(KoachPose.forUsage(u), isNotEmpty, reason: u.name);
        expect(koachPoseFor(u, occurrence: 3).info.usages, contains(u));
      }
    });
  });

  group('dessins', () {
    test('calques bien formés, fermés, sans opcode inconnu', () {
      for (final p in KoachPose.values) {
        for (final layer in [p.art.ink, p.art.paper, p.art.eyes]) {
          if (layer.isEmpty) continue;
          final s = koachPathStats(layer);
          expect(s.allClosed, isTrue, reason: p.id);
          expect(s.subpaths, greaterThan(0));
        }
        expect(koachPathStats(p.art.ink).cubics, greaterThan(20),
            reason: '${p.id} : tracé lissé');
      }
    });

    test('normalisation : pieds sur y = 0, hauteur 1 000 pour les poses en pied',
        () {
      for (final p in KoachPose.values) {
        final b = p.art.bounds;
        // La ligne des pieds (ou la coupe du buste) est à y = 0, à la
        // précision de l'arrondi et du lissage près.
        expect(b.bottom, inInclusiveRange(-2, 4), reason: p.id);
        // La tête est autour de x = 0 (repère au milieu des yeux).
        expect(b.left, lessThan(-100), reason: p.id);
        expect(b.right, greaterThan(100), reason: p.id);
        if (p.info.framing == KoachFraming.full) {
          // Pointe de la flamme à -1 000 ; un bras levé ou un drapeau peut
          // dépasser au-dessus.
          expect(b.top, lessThanOrEqualTo(-990), reason: p.id);
          expect(b.top, greaterThan(-1200), reason: p.id);
        } else {
          expect(b.top, inInclusiveRange(-1000, -600), reason: p.id);
        }
      }
    });

    test('boîte déclarée = boîte des extrémités, à 2 unités près', () {
      for (final p in KoachPose.values) {
        final e = endpointsBounds(p.art.ink);
        final b = p.art.bounds;
        expect(e.left - b.left, inInclusiveRange(-2, 30), reason: p.id);
        expect(b.right - e.right, inInclusiveRange(-2, 30), reason: p.id);
        expect(e.top - b.top, inInclusiveRange(-2, 30), reason: p.id);
        expect(b.bottom - e.bottom, inInclusiveRange(-2, 30), reason: p.id);
      }
    });

    test('papier et yeux à l’intérieur de la silhouette', () {
      for (final p in KoachPose.values) {
        final b = p.art.bounds.inflate(2);
        for (final layer in [p.art.paper, p.art.eyes]) {
          final c = koachControlBounds(layer);
          if (c == null) continue;
          expect(b.contains(c.left, c.top) && b.contains(c.right, c.bottom),
              isTrue,
              reason: p.id);
        }
      }
    });

    test('cadre commun : contient toutes les poses', () {
      for (final p in KoachPose.values) {
        final b = p.art.bounds;
        expect(
            koachCommonFrame.contains(b.left, b.top) &&
                koachCommonFrame.contains(b.right, b.bottom),
            isTrue);
      }
    });

    test('poids total des commandes raisonnable', () {
      var ints = 0;
      for (final p in KoachPose.values) {
        ints += p.art.ink.length + p.art.paper.length + p.art.eyes.length;
      }
      for (var l = 1; l <= koachFlameLevels; l++) {
        final f = koachFlame(l);
        ints += f.ink.length + f.outline.length + f.hollow.length;
      }
      // ~90 000 entiers ≈ 370 Ko de source Dart (plafond du lot : 400 Ko).
      expect(ints, lessThan(100000));
    });
  });

  group('rejeu des commandes', () {
    test('mise à l’échelle et translation', () {
      final r = _Recorder();
      replayKoachPath([0, 1, 2, 1, 3, 4, 2, 0, 0, 1, 1, 2, 2, 3], r,
          scale: 2, dx: 10, dy: -1);
      expect(r.ops, [
        'M12.0,3.0',
        'L16.0,7.0',
        'C10.0,-1.0,12.0,1.0,14.0,3.0',
        'Z',
      ]);
    });

    test('opcode inconnu et commande tronquée refusés', () {
      expect(() => koachPathStats([9]), throwsA(isA<KoachArtFormatException>()));
      expect(() => koachPathStats([0, 1]),
          throwsA(isA<KoachArtFormatException>()));
      expect(() => koachPathStats([1, 1, 1]),
          throwsA(isA<KoachArtFormatException>()));
    });

    test('SVG', () {
      expect(koachPathToSvg([0, 1, 2, 1, 3, 4, 2, 5, 6, 7, 8, 9, 10, 3]),
          'M1 2L3 4C5 6 7 8 9 10Z');
    });
  });
}
