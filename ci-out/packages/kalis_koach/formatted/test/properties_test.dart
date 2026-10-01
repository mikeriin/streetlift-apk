import 'dart:math';

import 'package:kalis_koach/kalis_koach.dart';
import 'package:test/test.dart';

const List<String> _paramNames = [
  'remaining',
  'field',
  'weeks',
  'exercise',
  'replacement',
  'minutes',
  'done',
  'planned',
  'value',
  'feature',
];

const List<String> _values = [
  '1',
  '40',
  'Pompes',
  'Tractions australiennes pronation',
  'Rowing inversé aux anneaux',
  'ton matériel disponible',
  '22 répétitions',
  'les objectifs personnels',
];

/// Tests de propriétés : 10 000 demandes aléatoires (graine fixe) — chaque
/// réplique est valide, déterministe, rendue sans paramètre résiduel et
/// dans les longueurs maximales.
void main() {
  test('10 000 demandes aléatoires seedées', () {
    final rnd = Random(20261001);
    final director = KoachDirector();
    const texts = KoachTexts();
    final codes = [...director.reasons.codes, 'code_inconnu', null];
    final events = KoachEvent.values.where((e) => e != KoachEvent.why).toList();
    var explained = 0;
    for (var n = 0; n < 10000; n++) {
      final event = events[rnd.nextInt(events.length)];
      final params = <String, String>{
        for (final p in _paramNames) p: _values[rnd.nextInt(_values.length)],
      };
      final cue = KoachCue(
        event,
        params: params,
        reason: codes[rnd.nextInt(codes.length)],
        occurrence: rnd.nextInt(1000),
        seed: rnd.nextInt(1 << 30),
      );
      final line = director.lineFor(cue);
      // Déterminisme.
      expect(director.lineFor(cue), line);
      // Cohérence avec la règle.
      final rule = director.ruleFor(event)!;
      expect(line.event, event);
      expect(line.priority, rule.priority);
      expect(line.actions, rule.actions);
      expect(koachMessagesFr.containsKey(line.messageKey), isTrue);
      final reason = cue.reason == null ? null : director.reasons[cue.reason!];
      final usesReason =
          reason != null &&
          (event == KoachEvent.proposalNew ||
              event == KoachEvent.changeApplied);
      expect(line.pose, isIn(usesReason ? reason.poses : rule.poses));
      // Rendu.
      final bubble = texts.bubble(line);
      expect(bubble, isNot(contains('{')));
      expect(bubble.length, lessThanOrEqualTo(koachBubbleMaxChars));
      final why = director.explain(line, occurrence: n);
      if (why != null) {
        explained++;
        final t = texts.bubble(why);
        expect(t.length, lessThanOrEqualTo(koachWhyMaxChars));
        expect(why.pose, isIn(koachWhyPoses));
      }
      // Occurrence suivante : autre variante quand il y en a plusieurs.
      final next = director.lineFor(
        KoachCue(
          event,
          params: params,
          reason: cue.reason,
          occurrence: cue.occurrence + 1,
          seed: cue.seed,
        ),
      );
      final variants = usesReason
          ? (event == KoachEvent.proposalNew
                ? reason.proposalKeys
                : reason.appliedKeys)
          : rule.messageKeys;
      if (variants.length > 1) {
        expect(next.messageKey, isNot(line.messageKey));
      }
    }
    expect(explained, greaterThan(1000));
  });

  test('toutes les variantes sont atteintes', () {
    final director = KoachDirector();
    final seen = <String>{};
    for (final e in KoachEvent.values) {
      if (e == KoachEvent.why) continue;
      for (final reason in [null, ...director.reasons.codes]) {
        for (var o = 0; o < 6; o++) {
          final line = director.lineFor(
            KoachCue(
              e,
              params: {for (final p in _paramNames) p: 'x'},
              reason: reason,
              occurrence: o,
            ),
          );
          seen.add(line.messageKey);
        }
      }
    }
    final expected = <String>{
      for (final r in koachRules) ...r.messageKeys,
      for (final r in koachBaseReasons) ...[
        ...r.proposalKeys,
        ...r.appliedKeys,
      ],
    };
    expect(seen, expected);
  });
}
