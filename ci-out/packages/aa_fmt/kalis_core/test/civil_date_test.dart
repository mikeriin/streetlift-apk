import 'dart:math';

import 'package:kalis_core/kalis_core.dart';
import 'package:test/test.dart';

void main() {
  test('lecture et écriture AAAA-MM-JJ', () {
    final d = CivilDate.parse('2026-10-01');
    expect(d.year, 2026);
    expect(d.month, 10);
    expect(d.day, 1);
    expect(d.iso, '2026-10-01');
    expect(d.toString(), '2026-10-01');
    expect(d.weekday, 4); // jeudi
    expect(CivilDate(987, 3, 4).iso, '0987-03-04');
  });

  test('dates refusées', () {
    for (final bad in <String>[
      '2026-02-30',
      '2026-13-01',
      '2026-00-10',
      '2026-1-1',
      '26-01-01',
      '2026-01-01T00:00:00',
      ' 2026-01-01',
      '',
    ]) {
      expect(() => CivilDate.parse(bad), throwsFormatException, reason: bad);
    }
    expect(() => CivilDate(2025, 2, 29), throwsArgumentError);
    expect(() => CivilDate(0, 1, 1), throwsArgumentError);
    expect(CivilDate(2024, 2, 29).iso, '2024-02-29');
  });

  test('numéro de jour : aller-retour sur 10 000 jours seedés', () {
    final r = Random(7);
    expect(CivilDate(1970, 1, 1).dayNumber, 0);
    expect(CivilDate(1969, 12, 31).dayNumber, -1);
    for (var i = 0; i < 10000; i++) {
      final n = r.nextInt(120000) - 30000;
      final d = CivilDate.fromDayNumber(n);
      expect(d.dayNumber, n);
      expect(CivilDate.parse(d.iso), d);
      expect(d.addDays(1).dayNumber, n + 1);
      expect(d.addDays(7).weekday, d.weekday);
      expect(d.weekday, inInclusiveRange(1, 7));
    }
  });

  test('arithmétique en jours civils (changements d\'heure sans effet)', () {
    final beforeDst = CivilDate(2026, 3, 28);
    expect(beforeDst.addDays(1).iso, '2026-03-29');
    expect(beforeDst.addDays(2).iso, '2026-03-30');
    expect(CivilDate(2026, 10, 24).addDays(2).iso, '2026-10-26');
    expect(CivilDate(2026, 12, 31).addDays(1).iso, '2027-01-01');
    expect(CivilDate(2026, 1, 1).daysUntil(CivilDate(2027, 1, 1)), 365);
    expect(CivilDate(2027, 1, 1).daysUntil(CivilDate(2026, 1, 1)), -365);
  });

  test('ordre et égalité', () {
    final a = CivilDate(2026, 5, 17);
    final b = CivilDate(2026, 5, 18);
    expect(a < b, isTrue);
    expect(a <= a, isTrue);
    expect(b > a, isTrue);
    expect(b >= b, isTrue);
    expect(a.compareTo(b), lessThan(0));
    expect(a == CivilDate.parse('2026-05-17'), isTrue);
    expect(a.hashCode, CivilDate.parse('2026-05-17').hashCode);
    expect(<CivilDate>[b, a]..sort(), <CivilDate>[a, b]);
  });
}
