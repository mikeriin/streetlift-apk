// L11 — règles pures de l'adaptation au jour le jour (KT-058 à KT-064) :
// compression à 20, 30 et 45 minutes, échange pour douleur, reprises à 7,
// 14 et 28 jours, plan qui glisse, seuils d'assiduité, plateau (vrai
// positif, aucun faux positif pendant une décharge), modes d'autonomie,
// charge de séance et seuil de 1,5, lecture stricte des données.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:streetlift_tracker/koach_adapt.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/program_generator.dart';

import 'support/l10_support.dart';

/// Séance type d'environ 57 min : montée en charge, 2 principaux, 4
/// accessoires, prévention, retour au calme.
List<CItem> _session({int doneMain = 0}) => [
  const CItem(id: 'ramp', role: 'warmup', sets: 3, work: 20, rest: 40),
  CItem(
    id: 'm1',
    role: 'main',
    sets: 4,
    done: doneMain,
    work: 30,
    rest: 90,
    groups: const {'dos', 'biceps'},
  ),
  const CItem(
    id: 'm2',
    role: 'main',
    sets: 4,
    work: 30,
    rest: 90,
    groups: {'pectoraux', 'triceps'},
  ),
  const CItem(
    id: 'a1',
    role: 'accessory',
    sets: 3,
    work: 40,
    rest: 75,
    groups: {'dos'},
  ),
  const CItem(
    id: 'a2',
    role: 'accessory',
    sets: 3,
    work: 40,
    rest: 75,
    groups: {'dos', 'biceps'},
  ),
  const CItem(
    id: 'a3',
    role: 'accessory',
    sets: 3,
    work: 40,
    rest: 75,
    groups: {'quadriceps'},
  ),
  const CItem(
    id: 'a4',
    role: 'accessory',
    sets: 3,
    work: 40,
    rest: 75,
    groups: {'épaules'},
  ),
  const CItem(
    id: 'prev',
    role: 'prevention',
    sets: 3,
    work: 30,
    rest: 45,
    groups: {'épaules'},
  ),
  const CItem(id: 'cool', role: 'cooldown', sets: 1, work: 300, rest: 0),
];

void main() {
  group('KT-058 séance compressée', () {
    for (final minutes in const [20, 30, 45]) {
      test('$minutes min : durée respectée, principaux conservés (≥ 2/3), '
          'prévention à 1 série', () {
        final items = _session();
        final plan = compressSession(items, minutes);
        expect(plan.unchanged, isFalse);
        expect(plan.before, greaterThan(minutes * 60));
        expect(plan.feasible, isTrue);
        expect(plan.after, lessThanOrEqualTo(minutes * 60));
        for (final m in const ['m1', 'm2']) {
          expect(plan.removed, isNot(contains(m)));
          expect(plan.sets[m] ?? 4, greaterThanOrEqualTo(3));
        }
        expect(plan.removed, isNot(contains('prev')));
        expect(plan.sets['prev'], 1);
        expect(plan.removed, containsAll(['ramp', 'cool']));
        expect(plan.warmup, isTrue);
        final byId = {for (final it in items) it.id: it};
        for (final p in plan.pairs) {
          expect(byId[p.$1]!.role, 'accessory');
          expect(byId[p.$2]!.role, 'accessory');
          expect(
            byId[p.$1]!.groups.intersection(byId[p.$2]!.groups),
            isEmpty,
            reason: 'accessoires enchaînés sans conflit musculaire',
          );
          expect(plan.removed, isNot(contains(p.$1)));
          expect(plan.removed, isNot(contains(p.$2)));
        }
      });
    }

    test('plus le temps est court, plus on retire (monotone)', () {
      final a = compressSession(_session(), 45);
      final b = compressSession(_session(), 30);
      final c = compressSession(_session(), 20);
      expect(a.after, greaterThanOrEqualTo(b.after));
      expect(b.after, greaterThanOrEqualTo(c.after));
      expect(c.removed.length, greaterThanOrEqualTo(a.removed.length));
    });

    test('séance déjà assez courte : rien ne change', () {
      final plan = compressSession(_session(), 120);
      expect(plan.unchanged, isTrue);
      expect(plan.removed, isEmpty);
      expect(plan.sets, isEmpty);
    });

    test('pendant la séance : séries faites gardées, pas d\'échauffement', () {
      final plan = compressSession(_session(doneMain: 4), 20, started: true);
      expect(plan.warmup, isFalse);
      expect(plan.sets['m1'] ?? 4, 4);
      expect(plan.after, lessThanOrEqualTo(20 * 60));
    });

    test('durée impossible : principaux aux 2/3, signalé', () {
      final plan = compressSession(_session(), 10);
      expect(plan.feasible, isFalse);
      expect(plan.sets['m1'], 3);
      expect(plan.sets['m2'], 3);
      expect(plan.removed, isNot(contains('m1')));
    });

    test('déterministe', () {
      final a = jsonEncode(compressSession(_session(), 30).toJson());
      final b = jsonEncode(compressSession(_session(), 30).toJson());
      expect(a, b);
    });

    test('prescription réduite : « 4×8 » → « 3×8 », myo et EMOM intacts', () {
      expect(SetsSpec.text('4×8').withCount(3)!.value, '3×8');
      expect(
        SetsSpec.text('4×(3×2) · 20 s intra').withCount(2)!.value,
        '2×(3×2) · 20 s intra',
      );
      expect(reducibleText('4×8'), isTrue);
      expect(reducibleText('1×12-15 puis 4×(4)'), isFalse);
      expect(reducibleText('EMOM 10 min'), isFalse);
      expect(SetsSpec.text('Montée 5-3-1').withCount(2), isNull);
      expect(leadingSets('5×5'), 5);
      expect(mainMinimum(4, 0), 3);
      expect(mainMinimum(5, 0), 4);
      expect(mainMinimum(3, 3), 3);
      expect(mainMinimum(1, 0), 1);
    });
  });

  group('KT-059 échange d\'exercice', () {
    final catalog = L10Data.load().catalog;
    final equipment = {
      ...kAlwaysPack,
      'barre_fixe',
      'barres_paralleles',
      'halteres',
      'elastique',
      'banc',
    };

    GenExercise withJoints(String type) => catalog.all.firstWhere(
      (e) =>
          e.type == type &&
          e.usable &&
          e.joints.values.any((v) => v >= 2) &&
          swapCandidates(catalog, e, equipment: equipment).isNotEmpty,
    );

    for (final type in const [
      'poussee_horizontale',
      'tirage_vertical',
      'squat',
    ]) {
      test('douleur ($type) : même type, difficulté ±1, matériel disponible, '
          'contrainte articulaire ≤ l\'original', () {
        final original = withJoints(type);
        final list = swapCandidates(
          catalog,
          original,
          equipment: equipment,
          motive: 'pain',
        );
        expect(list.length, lessThanOrEqualTo(3));
        for (final c in list) {
          expect(c.id, isNot(original.id));
          expect(c.type, original.type);
          expect(
            (c.difficulty - original.difficulty).abs(),
            lessThanOrEqualTo(1),
          );
          expect(c.materiel.every(equipment.contains), isTrue);
          for (final j in c.joints.entries) {
            expect(
              j.value,
              lessThanOrEqualTo(original.joints[j.key] ?? 0),
              reason: '${c.id} ${j.key}',
            );
          }
        }
      });
    }

    test('jamais un exercice détesté ; classement déterministe', () {
      final original = withJoints('poussee_horizontale');
      final first = swapCandidates(catalog, original, equipment: equipment);
      expect(first, isNotEmpty);
      final again = swapCandidates(catalog, original, equipment: equipment);
      expect([for (final e in again) e.id], [for (final e in first) e.id]);
      final without = swapCandidates(
        catalog,
        original,
        equipment: equipment,
        disliked: {first.first.id},
      );
      expect([for (final e in without) e.id], isNot(contains(first.first.id)));
    });

    test('charge initiale prudente', () {
      expect(prudentLoad(40, 'charge_externe', 'charge_externe'), 30);
      expect(prudentLoad(8, 'charge_externe', 'charge_externe'), 6);
      expect(prudentLoad(40, 'charge_externe', 'poids_de_corps'), isNull);
      expect(prudentLoad(null, 'lest', 'lest'), isNull);
    });
  });

  group('KT-060 reprise, vacances, maladie', () {
    test('règles de reprise à 7, 14 et 28 jours (et bornes)', () {
      expect(resumeRule(6).active, isFalse);
      final r7 = resumeRule(7);
      expect(
        [r7.band, r7.loadCut, r7.setCut, r7.calibrationSet],
        [1, .10, 1, false],
      );
      expect(resumeRule(13).band, 1);
      final r14 = resumeRule(14);
      expect(
        [r14.band, r14.loadCut, r14.setCut, r14.calibrationSet],
        [2, .20, 0, true],
      );
      expect(resumeRule(27).band, 2);
      final r28 = resumeRule(28);
      expect([r28.band, r28.loadCut, r28.calibrationWeek], [3, .30, true]);
    });

    test('épisode de reprise : dernier arrêt ≥ 7 jours avant la séance', () {
      expect(resumeEpisode(const [], 100), isNull);
      expect(resumeEpisode(const [90, 95], 100), isNull);
      expect(resumeEpisode(const [80, 81], 100), (100, 19));
      // Reprise commencée le jour 100 : la séance du 102 appartient au
      // même épisode.
      expect(resumeEpisode(const [80, 100], 102), (100, 20));
    });

    test('une séance par mouvement (7-13 et 14-27 jours) ; semaine entière '
        '(28 jours et plus)', () {
      final r = resumeRule(10);
      expect(resumeAppliesTo(r, 100, 100, const []), isTrue);
      expect(resumeAppliesTo(r, 100, 102, const [100]), isFalse);
      expect(resumeAppliesTo(r, 100, 102, const [90]), isTrue);
      final w = resumeRule(30);
      expect(resumeAppliesTo(w, 100, 106, const [100, 102]), isTrue);
      expect(resumeAppliesTo(w, 100, 107, const [100]), isFalse);
      expect(
        resumeAppliesTo(r, 100, 100 + kResumeHorizonDays + 1, const []),
        isFalse,
      );
    });

    test('maladie : première semaine de retour seulement', () {
      expect(illnessRecovery(const [200], 199), isFalse);
      expect(illnessRecovery(const [200], 200), isTrue);
      expect(illnessRecovery(const [200], 206), isTrue);
      expect(illnessRecovery(const [200], 207), isFalse);
    });

    test('le plan glisse, aucune séance doublée', () {
      final planned = [for (var o = 0; o < 10; o++) (o, 100 + o)];
      // Faites : 0, 1, 2 ; aujourd'hui = jour 106 → prochaine = 3 (jour 103).
      expect(slideProposal(planned, {0, 1, 2}, 106), (3, 3));
      // À jour.
      expect(slideProposal(planned, {0, 1, 2}, 103), isNull);
      // Une séance sautée puis faite ensuite : la suite part de la dernière.
      expect(slideProposal(planned, {0, 2}, 104), (3, 1));
    });
  });

  group('KT-061 assiduité', () {
    List<(int, bool)> planned(double rateNow, double ratePrev) {
      final out = <(int, bool)>[];
      // 16 séances par fenêtre de 28 jours, finissant la veille du jour 200.
      for (var k = 0; k < 16; k++) {
        out.add((200 - 28 + k, k < (16 * rateNow).round()));
        out.add((200 - 56 + k, k < (16 * ratePrev).round()));
      }
      return out;
    }

    test('< 60 % : une séance de moins ou plus courtes', () {
      final p = planned(.5, .5);
      final r = adherenceRate(p, 200)!;
      expect(r, closeTo(.5, 1e-9));
      expect(
        adherenceAdvice(r, adherenceRate(p, 200, offset: 28), true),
        'fewer',
      );
    });

    test('60 à 89 % : rien', () {
      final p = planned(.75, .95);
      expect(adherenceAdvice(adherenceRate(p, 200), .95, true), 'none');
      expect(adherenceAdvice(.60, .95, true), 'none');
      expect(adherenceAdvice(.89, .95, true), 'none');
    });

    test('≥ 90 % sur 2 cycles avec progression : une séance de plus', () {
      final p = planned(.95, .95);
      final now = adherenceRate(p, 200);
      final prev = adherenceRate(p, 200, offset: 28);
      expect(adherenceAdvice(now, prev, true), 'more');
      expect(adherenceAdvice(now, prev, false), 'none');
      expect(adherenceAdvice(now, .80, true), 'none');
    });

    test('données insuffisantes et jours en pause', () {
      expect(adherenceRate(const [(199, false), (198, false)], 200), isNull);
      final p = [for (var d = 172; d < 200; d += 2) (d, d >= 186)];
      final paused = {for (var d = 172; d < 186; d++) d};
      expect(adherenceRate(p, 200, paused: paused), 1.0);
    });

    test('jour ajouté ou retiré', () {
      expect(dayToAdd(const [1, 3, 5]), 2);
      expect(dayToAdd(const [1, 4]), 6);
      expect(dayToAdd(const [1, 2, 3, 4, 5, 6, 7]), isNull);
      expect(dayToDrop(const [1, 2, 5]), 2);
      expect(dayToDrop(const [1]), isNull);
    });
  });

  group('KT-062 plateau', () {
    test('vrai positif : estimation plate 3 semaines, assiduité ≥ 80 %', () {
      final w = {10: 100.0, 11: 100.2, 12: 100.1, 13: 100.3};
      expect(
        plateauDetected(w, 13, adherence: .9, fatigue: false, deload: false),
        isTrue,
      );
    });

    test('pas de faux positif : décharge, fatigue, assiduité faible, '
        'progression', () {
      final flat = {10: 100.0, 11: 100.0, 12: 100.0, 13: 100.0};
      expect(
        plateauDetected(flat, 13, adherence: .9, fatigue: false, deload: true),
        isFalse,
      );
      expect(
        plateauDetected(flat, 13, adherence: .9, fatigue: true, deload: false),
        isFalse,
      );
      expect(
        plateauDetected(flat, 13, adherence: .7, fatigue: false, deload: false),
        isFalse,
      );
      final up = {10: 100.0, 11: 101.0, 12: 102.0, 13: 103.0};
      expect(
        plateauDetected(up, 13, adherence: .9, fatigue: false, deload: false),
        isFalse,
      );
      expect(
        plateauDetected(
          const {10: 100.0, 13: 100.0},
          13,
          adherence: .9,
          fatigue: false,
          deload: false,
        ),
        isFalse,
        reason: 'au moins 3 points',
      );
    });

    test('intervention selon le niveau', () {
      expect(plateauKind(0), 'technique');
      expect(plateauKind(1), 'technique');
      expect(plateauKind(2), 'range');
      expect(plateauKind(3), 'deload');
      expect(plateauKind(4), 'deload');
    });

    test('estimation d\'une série', () {
      expect(setEstimate(100, 5, 2), closeTo(100 * (1 + 7 / 30), 1e-9));
      expect(setEstimate(null, 12, 1), 13);
    });
  });

  group('KT-063 modes d\'autonomie', () {
    test('Guidé : baisses appliquées, hausse seulement à RIR visé + 2', () {
      expect(autonomyAction('guided', 'down', 'missed'), 'auto');
      expect(autonomyAction('guided', 'down', 'twoHard'), 'auto');
      expect(autonomyAction('guided', 'up', 'easy2'), 'auto');
      expect(autonomyAction('guided', 'up', 'easy1'), 'none');
    });

    test('Assisté : tout est proposé ; Expert : suggestion visible', () {
      for (final r in const ['easy1', 'easy2', 'missed']) {
        expect(autonomyAction('assisted', 'up', r), 'propose');
        expect(autonomyAction('expert', 'down', r), 'info');
      }
    });

    test('adaptations de sécurité : appliquées d\'office en Guidé, '
        'annulables ; validées d\'un tap sinon', () {
      expect(safetyApplied('guided', null), isTrue);
      expect(safetyApplied('guided', 'refused'), isFalse);
      expect(safetyApplied('assisted', null), isFalse);
      expect(safetyApplied('assisted', 'applied'), isTrue);
      expect(safetyApplied('expert', null), isFalse);
      expect(safetyApplied('expert', 'applied'), isTrue);
    });
  });

  group('KT-064 charge de séance', () {
    test('charge = difficulté × durée', () {
      expect(sessionLoadOf(6, 50), 300);
    });

    test('seuil de 1,5 fois la moyenne des 4 semaines précédentes', () {
      final base = {10: 1000.0, 11: 1000.0, 12: 1000.0, 13: 1000.0};
      expect(loadCaution({...base, 14: 1500}, 14), isNull);
      final c = loadCaution({...base, 14: 1600}, 14);
      expect(c, isNotNull);
      expect(c!.$1, closeTo(1.6, 1e-9));
      // Une seule semaine renseignée : pas de repère.
      expect(loadCaution({13: 1000, 14: 3000}, 14), isNull);
      // Semaine sans séance notée comptée à 0.
      expect(loadCaution({11: 1000, 13: 1000, 14: 800}, 14), isNotNull);
    });

    test('semaine civile du lundi au dimanche', () {
      final monday = dayIndex(DateTime(2026, 10, 5));
      final sunday = dayIndex(DateTime(2026, 10, 11));
      expect(weekIndexOfDay(monday), weekIndexOfDay(sunday));
      expect(weekIndexOfDay(sunday + 1), weekIndexOfDay(monday) + 1);
      expect(dayString(dayOfIndex(monday)), '2026-10-05');
    });
  });

  group('données', () {
    test('aller-retour et lecture stricte', () {
      final a = AdaptData()
        ..autonomy = 'guided'
        ..pause = const AdaptPause('vacation', '2026-10-01')
        ..shorter = '2026-10-01T10:00:00'
        ..lightenFrom = '2026-10-01'
        ..lightenTo = '2026-10-04';
      a.pauses.add(const AdaptPause('illness', '2026-09-01', '2026-09-05'));
      a.sessions['S3-J1'] = {
        'minutes': 30,
        'removed': ['B1-12'],
        'sets': {'B1-7': 3},
        'pairs': [
          ['B1-8', 'B1-11'],
        ],
        'swaps': {
          'B1-9': {'to': 'x', 'name': 'X', 'motive': 'busy', 'kg': 20.0},
        },
        'resume': 'applied',
      };
      a.difficulty['S3-J1'] = {'rpe': 6, 'minutes': 50};
      a.events.add(AdaptEvent('2026-10-01T10:00:00', 'slide', {'days': 2}));
      a.dismissed['slide|S3-J1'] = '2026-10-01T10:00:00';
      final json = jsonDecode(jsonEncode(a.toJson()));
      final b = AdaptData.fromJson(json, strict: true);
      expect(jsonEncode(b.toJson()), jsonEncode(a.toJson()));
      expect(AdaptData().pristine, isTrue);
      expect(b.pristine, isFalse);
    });

    test('valeurs hors contrat : import refusé, démarrage tolérant', () {
      final bad = {
        'v': 1,
        'autonomy': 'robot',
        'sessions': {
          'S3-J1': {'minutes': 2},
        },
        'difficulty': {
          'S3-J1': {'rpe': 11, 'minutes': 50},
        },
      };
      expect(
        () => AdaptData.fromJson(bad, strict: true),
        throwsFormatException,
      );
      final issues = <String>[];
      final d = AdaptData.fromJson(bad, issues: issues);
      expect(issues.length, 3);
      expect(d.pristine, isTrue);
      expect(
        () => AdaptData.fromJson({'v': 9}, strict: true),
        throwsFormatException,
      );
    });
  });
}
