// LC1 (KT-037) — Révision du contenu S12-S19 (Bloc 2 — Force).
// Contrôle le programme révisé contre la section 3 de la demande (listes
// par jour, séries, coefficients, règles R1-R6), les volumes calculés pour
// des maxima explicites, le recalcul pendant une séance après modification
// de la feuille Pilotage, la lecture d'un journal contenant un identifiant
// supprimé, et la cohérence semaine complète / XP (G2 : plus de crédits).
// LC1b (suite de KT-037, 26/09/2026) : S11·J6 au format du J6 du Bloc 2,
// squat endurance de S11 conservé (`tools/lc1b_s11_j6.py`) ; S12·J6 inchangé.
// Données synthétiques et stockage simulé uniquement.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/pilotage_screen.dart';
import 'package:streetlift_tracker/session_history.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

import 'phone_test_support.dart' show swipePage;

/// Identifiants retirés de S12 à S19 (202), relevés sur l'asset 2.5.6.
const removedIds = <String>[
  'B2-9',
  'B2-12',
  'B2-13',
  'B2-18',
  'B2-21',
  'B2-25',
  'B2-26',
  'B2-31',
  'B2-33',
  'B2-34',
  'B2-35',
  'B2-37',
  'B2-38',
  'B2-41',
  'B2-43',
  'B2-47',
  'B2-50',
  'B2-51',
  'B2-53',
  'B2-54',
  'B2-55',
  'B2-58',
  'B2-59',
  'B2-61',
  'B2-62',
  'B2-63',
  'B2-64',
  'B2-65',
  'B2-67',
  'B2-76',
  'B2-79',
  'B2-80',
  'B2-85',
  'B2-88',
  'B2-92',
  'B2-93',
  'B2-98',
  'B2-100',
  'B2-101',
  'B2-102',
  'B2-104',
  'B2-105',
  'B2-110',
  'B2-114',
  'B2-120',
  'B2-121',
  'B2-122',
  'B2-125',
  'B2-126',
  'B2-128',
  'B2-129',
  'B2-130',
  'B2-132',
  'B2-134',
  'B2-143',
  'B2-146',
  'B2-147',
  'B2-152',
  'B2-155',
  'B2-159',
  'B2-160',
  'B2-165',
  'B2-167',
  'B2-168',
  'B2-169',
  'B2-171',
  'B2-172',
  'B2-177',
  'B2-181',
  'B2-187',
  'B2-188',
  'B2-189',
  'B2-192',
  'B2-193',
  'B2-195',
  'B2-196',
  'B2-197',
  'B2-199',
  'B2-201',
  'B2-210',
  'B2-213',
  'B2-214',
  'B2-221',
  'B2-225',
  'B2-226',
  'B2-231',
  'B2-233',
  'B2-234',
  'B2-235',
  'B2-237',
  'B2-238',
  'B2-243',
  'B2-247',
  'B2-253',
  'B2-254',
  'B2-255',
  'B2-258',
  'B2-259',
  'B2-261',
  'B2-262',
  'B2-263',
  'B2-265',
  'B2-267',
  'B2-276',
  'B2-279',
  'B2-280',
  'B2-285',
  'B2-288',
  'B2-292',
  'B2-293',
  'B2-298',
  'B2-300',
  'B2-301',
  'B2-302',
  'B2-304',
  'B2-305',
  'B2-310',
  'B2-314',
  'B2-320',
  'B2-321',
  'B2-322',
  'B2-325',
  'B2-326',
  'B2-328',
  'B2-329',
  'B2-330',
  'B2-332',
  'B2-334',
  'B2-343',
  'B2-346',
  'B2-347',
  'B2-352',
  'B2-355',
  'B2-359',
  'B2-360',
  'B2-365',
  'B2-367',
  'B2-368',
  'B2-369',
  'B2-371',
  'B2-372',
  'B2-377',
  'B2-381',
  'B2-387',
  'B2-388',
  'B2-389',
  'B2-392',
  'B2-393',
  'B2-395',
  'B2-396',
  'B2-397',
  'B2-399',
  'B2-401',
  'B2-410',
  'B2-413',
  'B2-414',
  'B2-419',
  'B2-422',
  'B2-426',
  'B2-427',
  'B2-432',
  'B2-434',
  'B2-435',
  'B2-436',
  'B2-438',
  'B2-439',
  'B2-444',
  'B2-448',
  'B2-454',
  'B2-455',
  'B2-456',
  'B2-459',
  'B2-460',
  'B2-462',
  'B2-463',
  'B2-464',
  'B2-466',
  'B2-468',
  'B2-477',
  'B2-480',
  'B2-481',
  'B2-488',
  'B2-492',
  'B2-493',
  'B2-498',
  'B2-500',
  'B2-501',
  'B2-502',
  'B2-504',
  'B2-505',
  'B2-510',
  'B2-514',
  'B2-520',
  'B2-521',
  'B2-522',
  'B2-525',
  'B2-526',
  'B2-528',
  'B2-529',
  'B2-530',
  'B2-532',
  'B2-534',
];

/// Lignes nouvelles (66) : identifiant → (semaine, jour, nom).
const addedLines = <String, (int, int, String)>{
  'B2-L1-001': (12, 3, 'Squat pause 2 s'),
  'B2-L1-002': (12, 3, 'GtG muscle-up — dans la journée'),
  'B2-L1-003': (12, 4, 'TEST MAX TRACTIONS PdC'),
  'B2-L1-004': (12, 4, 'Tractions PdC — séries continues'),
  'B2-L1-005': (12, 4, 'Travail poignet excentrique (haltère)'),
  'B2-L1-006': (12, 5, 'TEST MAX DIPS PdC'),
  'B2-L1-007': (12, 5, 'TEST MAX POMPES PdC'),
  'B2-L1-008': (12, 5, 'GtG muscle-up — dans la journée'),
  'B2-L1-009': (12, 6, 'Muscle-ups PdC explosifs'),
  'B2-L1-010': (12, 6, 'TEST MAX SQUAT @ 70 kg'),
  'B2-L1-011': (13, 3, 'Squat pause 2 s'),
  'B2-L1-012': (13, 3, 'GtG muscle-up — dans la journée'),
  'B2-L1-013': (13, 4, 'Tractions PdC — série de référence'),
  'B2-L1-014': (13, 4, 'Travail poignet excentrique (haltère)'),
  'B2-L1-015': (13, 5, 'Dips PdC — série de référence'),
  'B2-L1-016': (13, 5, 'Pompes PdC — série de référence'),
  'B2-L1-017': (13, 5, 'GtG muscle-up — dans la journée'),
  'B2-L1-018': (13, 6, 'Muscle-ups PdC explosifs'),
  'B2-L1-019': (14, 3, 'Squat pause 2 s'),
  'B2-L1-020': (14, 3, 'GtG muscle-up — dans la journée'),
  'B2-L1-021': (14, 4, 'Tractions PdC — série de référence'),
  'B2-L1-022': (14, 4, 'Travail poignet excentrique (haltère)'),
  'B2-L1-023': (14, 5, 'Dips PdC — série de référence'),
  'B2-L1-024': (14, 5, 'Pompes PdC — série de référence'),
  'B2-L1-025': (14, 5, 'GtG muscle-up — dans la journée'),
  'B2-L1-026': (14, 6, 'Muscle-ups PdC explosifs'),
  'B2-L1-027': (15, 3, 'Squat pause 2 s'),
  'B2-L1-028': (15, 3, 'GtG muscle-up — dans la journée'),
  'B2-L1-029': (15, 4, 'Tractions PdC — série de référence'),
  'B2-L1-030': (15, 4, 'Travail poignet excentrique (haltère)'),
  'B2-L1-031': (15, 5, 'Dips PdC — série de référence'),
  'B2-L1-032': (15, 5, 'Pompes PdC — série de référence'),
  'B2-L1-033': (15, 5, 'GtG muscle-up — dans la journée'),
  'B2-L1-034': (15, 6, 'Muscle-ups PdC explosifs'),
  'B2-L1-035': (16, 3, 'Squat pause 2 s'),
  'B2-L1-036': (16, 3, 'GtG muscle-up — dans la journée'),
  'B2-L1-037': (16, 4, 'Tractions PdC — série de référence'),
  'B2-L1-038': (16, 4, 'Travail poignet excentrique (haltère)'),
  'B2-L1-039': (16, 5, 'Dips PdC — série de référence'),
  'B2-L1-040': (16, 5, 'Pompes PdC — série de référence'),
  'B2-L1-041': (16, 5, 'GtG muscle-up — dans la journée'),
  'B2-L1-042': (16, 6, 'Muscle-ups PdC explosifs'),
  'B2-L1-043': (17, 3, 'Squat pause 2 s'),
  'B2-L1-044': (17, 3, 'GtG muscle-up — dans la journée'),
  'B2-L1-045': (17, 4, 'Tractions PdC — série de référence'),
  'B2-L1-046': (17, 4, 'Travail poignet excentrique (haltère)'),
  'B2-L1-047': (17, 5, 'Dips PdC — série de référence'),
  'B2-L1-048': (17, 5, 'Pompes PdC — série de référence'),
  'B2-L1-049': (17, 5, 'GtG muscle-up — dans la journée'),
  'B2-L1-050': (17, 6, 'Muscle-ups PdC explosifs'),
  'B2-L1-051': (18, 3, 'Squat pause 2 s'),
  'B2-L1-052': (18, 3, 'GtG muscle-up — dans la journée'),
  'B2-L1-053': (18, 4, 'Tractions PdC — série de référence'),
  'B2-L1-054': (18, 4, 'Travail poignet excentrique (haltère)'),
  'B2-L1-055': (18, 5, 'Dips PdC — série de référence'),
  'B2-L1-056': (18, 5, 'Pompes PdC — série de référence'),
  'B2-L1-057': (18, 5, 'GtG muscle-up — dans la journée'),
  'B2-L1-058': (18, 6, 'Muscle-ups PdC explosifs'),
  'B2-L1-059': (19, 3, 'Squat pause 2 s'),
  'B2-L1-060': (19, 3, 'GtG muscle-up — dans la journée'),
  'B2-L1-061': (19, 4, 'Tractions PdC — série de référence'),
  'B2-L1-062': (19, 4, 'Travail poignet excentrique (haltère)'),
  'B2-L1-063': (19, 5, 'Dips PdC — série de référence'),
  'B2-L1-064': (19, 5, 'Pompes PdC — série de référence'),
  'B2-L1-065': (19, 5, 'GtG muscle-up — dans la journée'),
  'B2-L1-066': (19, 6, 'Muscle-ups PdC explosifs'),
};

/// LC1b : identifiants retirés de S11·J6 (7).
const lc1bRemovedIds = <String>[
  'B1-519',
  'B1-520',
  'B1-522',
  'B1-523',
  'B1-524',
  'B1-526',
  'B1-528',
];

const mu = 'MUSCLE-UP LESTÉ — lift n°1, avant tout tirage';
const pull = 'TRACTION LESTÉE — lift principal';
const dip = 'DIP LESTÉ — lift principal';
const squat = 'BACK SQUAT — lift principal';
const gtg = 'GtG muscle-up — dans la journée';
const wrist = 'Travail poignet excentrique (haltère)';
const noSensor =
    "Sans capteur : arrête la série dès qu'une rep ralentit nettement ou que ta marge passe sous le RIR visé.";
const calibrationStart = 'Série 1 = calibrage, note ton RIR.';
const calibrationEnd =
    "Série ratée → −2,5 kg (−5 kg s'il manque 2 reps ou plus).";
const deloadNote = 'Décharge : aucune hausse de charge.';

bool deload(int n) => n == 15 || n == 19;

/// Liste finale attendue (section 3), par jour.
List<String> expectedNames(int n, int j) => switch (j) {
  1 => [mu, pull, 'Rowing barre penché', 'Curl barre EZ', 'Face pulls', wrist],
  2 => [
    dip,
    'Pompes lestées (lest ajouté)',
    'Développé militaire debout',
    'Élévations latérales (par haltère)',
    'Extension triceps poulie corde',
    'Rotations externes (par haltère)',
  ],
  3 => [
    squat,
    'Squat pause 2 s',
    'Soulevé de terre roumain',
    'Leg curl',
    'Ab wheel',
    gtg,
  ],
  4 => [
    if (n == 12) ...[
      'TEST MAX TRACTIONS PdC',
      'Tractions PdC — séries continues',
    ] else ...[
      'Tractions PdC — série de référence',
      'Tractions PdC — clusters',
    ],
    'Rowing haltère unilatéral (par haltère)',
    'Curl marteau (par haltère)',
    'Dead-hang lesté ou PdC',
    'Face pulls',
    wrist,
  ],
  5 => [
    if (n == 12) ...[
      'TEST MAX DIPS PdC',
      'TEST MAX POMPES PdC',
    ] else ...[
      'Dips PdC — série de référence',
      'Dips PdC — clusters',
      'Pompes PdC — série de référence',
      'Pompes PdC — clusters',
    ],
    'Élévations latérales (par haltère)',
    gtg,
  ],
  _ => [
    'Muscle-ups PdC explosifs',
    'Tractions explosives poitrine-barre',
    n == 12 ? 'TEST MAX SQUAT @ 70 kg' : 'Squat endurance @ 70 kg',
    'Leg raises lestés (suspendu)',
    'Mobilité épaules + poignets',
  ],
};

/// Séries attendues pour les lignes nommées dans la section 3.
Map<String, String> expectedSets(int n, int j) {
  final d = deload(n);
  return switch (j) {
    1 => {
      'Rowing barre penché': d ? '2×8' : '3×8',
      'Curl barre EZ': d ? '1×10' : '2×10',
      'Face pulls': d ? '2×18' : '3×18',
      wrist: d ? '2×15 (flex. + ext.)' : '3×15 (flex. + ext.)',
    },
    2 => {
      'Pompes lestées (lest ajouté)': d ? '2×8' : '3×8',
      'Développé militaire debout': d ? '2×8' : '3×8',
      'Extension triceps poulie corde': d
          ? '1×12-15 puis 2×(4)'
          : '1×12-15 puis 4×(4)',
      'Rotations externes (par haltère)': '2×15/bras',
    },
    3 => {
      'Squat pause 2 s': d ? '1×4' : '2×4',
      'Soulevé de terre roumain': d ? '2×10' : '3×10',
      'Leg curl': d ? '2×12' : '3×12',
      gtg: d ? '2×3' : '3×4',
    },
    4 => {
      'Rowing haltère unilatéral (par haltère)': d ? '2×10' : '3×10',
      'Curl marteau (par haltère)': d ? '1×12' : '2×12',
      'Dead-hang lesté ou PdC': d ? '1× max effort' : '2× max effort',
      'Face pulls': d ? '2×18' : '3×18',
      wrist: d ? '2×15 (flex. + ext.)' : '3×15 (flex. + ext.)',
      if (n == 12) 'TEST MAX TRACTIONS PdC': '1 × maximum',
    },
    5 => {
      gtg: d ? '2×3' : '3×4',
      if (n == 12) 'TEST MAX DIPS PdC': '1 × maximum',
      if (n == 12) 'TEST MAX POMPES PdC': '1 × maximum',
    },
    _ => {
      'Muscle-ups PdC explosifs': d ? '3×2' : '4×3',
      'Tractions explosives poitrine-barre': d ? '3×3' : '4×3',
      if (n == 12) 'TEST MAX SQUAT @ 70 kg': '1 × maximum',
    },
  };
}

/// Coefficients des clusters (origine − 0,6), par semaine.
const clusterCoef = {
  'B17': {13: 1.4, 14: 1.6, 15: 0.8, 16: 1.4, 17: 1.6, 18: 1.8, 19: 0.8},
  'B18': {13: 1.4, 14: 1.6, 15: 0.8, 16: 1.4, 17: 1.6, 18: 1.8, 19: 0.8},
  'B19': {13: 0.8, 14: 0.94, 15: 0.38, 16: 0.8, 17: 0.94, 18: 1.08, 19: 0.38},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Programme révisé (asset)', () {
    late AppStore app;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      app = AppStore();
      await app.init();
    });
    tearDown(() async {
      await app.flush();
      app.dispose();
    });
    Exercise line(int n, int j, String name) =>
        app.program.week(n).day(j)!.exercises.firstWhere((e) => e.name == name);

    test(
      '1 812 exercices ; LC1 : 202 suppressions et 66 ajouts ; LC1b : 7 et 1',
      () {
        final where = <String, (int, int, String)>{};
        for (final w in app.program.weeks) {
          for (final d in w.days) {
            for (final e in d.exercises) {
              expect(where.containsKey(e.id), isFalse, reason: e.id);
              where[e.id] = (w.n, d.j, e.name);
            }
          }
        }
        // LC1 : 1 954 − 202 + 66 = 1 818 ; LC1b (S11·J6) : 1 818 − 7 + 1.
        expect(where, hasLength(1812));
        expect(1954 - removedIds.length + addedLines.length, 1818);
        expect(1818 - lc1bRemovedIds.length + 1, 1812);
        for (final id in [...removedIds, ...lc1bRemovedIds]) {
          expect(where.containsKey(id), isFalse, reason: id);
        }
        expect(where['B1-L1b-001'], (11, 6, 'Muscle-ups PdC explosifs'));
        expect(
          [
            for (final id in where.keys)
              if (id.contains('L1b')) id,
          ],
          ['B1-L1b-001'],
        );
        final added = {
          for (final e in where.entries)
            if (e.key.startsWith('B2-L1-')) e.key: e.value,
        };
        expect(added, addedLines);
        expect(addedLines.keys, [
          for (var i = 1; i <= 66; i++) 'B2-L1-${i.toString().padLeft(3, '0')}',
        ]);
      },
    );

    test('S12 à S19 : lignes, ordre, séries et règles R1 à R4 (section 3)', () {
      for (var n = 12; n <= 19; n++) {
        final week = app.program.week(n);
        for (var j = 1; j <= 6; j++) {
          final day = week.day(j)!;
          final names = [for (final e in day.exercises) e.name];
          expect(names, expectedNames(n, j), reason: 'S$n J$j');
          expectedSets(n, j).forEach((name, sets) {
            expect(line(n, j, name).sets.value, sets, reason: 'S$n J$j $name');
          });
          for (final e in day.exercises) {
            expect(e.cue.contains('VBT'), isFalse, reason: 'S$n J$j ${e.name}');
            if (e.name.startsWith('GtG')) {
              expect(j == 3 || j == 5, isTrue);
              expect(e, day.exercises.last);
              expect(e.load.kg, 0);
              expect(e.rest, '≥ 2 h');
            }
          }
          expect(day.conduite.contains('GtG dans la journée'), isFalse);
          if (j == 1 || j == 6) expect(day.conduite.contains('GtG'), isFalse);
          if (j == 3 || j == 5) {
            expect(
              day.conduite,
              contains('GtG : 3 × 4 muscle-ups PdC répartis dans la journée.'),
            );
          }
          if (j == 6) {
            expect(day.title, 'PUISSANCE MU + SQUAT ENDURANCE');
            expect(
              day.conduite,
              contains(
                'CONDUITE J6 — Muscle-up au poids de corps et tirage explosif, squat endurance. AUCUNE charge maximale.',
              ),
            );
          }
          if (n == 12) {
            expect(
              day.conduite,
              startsWith('SEMAINE DE RECALAGE — sortie de décharge.'),
            );
            expect(
              day.conduite.contains('Test en tête de séance'),
              j >= 4,
              reason: 'S12 J$j',
            );
          }
        }
        // R1 à R3 sur les 4 mouvements principaux.
        for (final (j, name) in [(1, mu), (1, pull), (2, dip), (3, squat)]) {
          final e = line(n, j, name);
          expect(e.main, isTrue);
          expect(e.tempo, 'Intention maximale');
          expect(e.cue, contains(noSensor));
          final classic = {12, 13, 15, 19}.contains(n);
          expect(
            e.sets.value!.contains('en clusters'),
            !classic,
            reason: 'S$n $name',
          );
          if (classic) expect(e.cue.contains('Clusters :'), isFalse);
          if (deload(n)) {
            expect(e.cue, endsWith(deloadNote));
            expect(e.cue.contains(calibrationStart), isFalse);
          } else {
            expect(e.cue, contains(calibrationStart));
            expect(e.cue, endsWith(calibrationEnd));
          }
        }
        // Coefficients (R6) et séries de référence.
        if (n > 12) {
          for (final (j, ref, name) in [
            (4, 'B17', 'Tractions PdC — clusters'),
            (5, 'B18', 'Dips PdC — clusters'),
            (5, 'B19', 'Pompes PdC — clusters'),
          ]) {
            final s = line(n, j, name).sets;
            expect((s.type, s.ref, s.div), ('volume', ref, 5));
            expect(s.coef, clusterCoef[ref]![n], reason: 'S$n $name');
          }
          for (final (j, ref, name) in [
            (4, 'B17', 'Tractions PdC — série de référence'),
            (5, 'B18', 'Dips PdC — série de référence'),
            (5, 'B19', 'Pompes PdC — série de référence'),
          ]) {
            final s = line(n, j, name).sets;
            expect(
              (s.type, s.prefix, s.coef, s.ref, s.div, s.suffix),
              ('volume', '1 × ', 0.6, ref, 1, ' reps'),
            );
          }
        } else {
          final s = line(12, 4, 'Tractions PdC — séries continues').sets;
          expect((s.prefix, s.coef, s.ref, s.div), ('2 × ', 1.2, 'B17', 2));
        }
      }
    });

    test('volumes calculés : maxima actuels puis modifiés', () {
      String label(int n, int j, String name) =>
          app.setsLabel(line(n, j, name));
      const pullRef = 'Tractions PdC — série de référence';
      const pullCl = 'Tractions PdC — clusters';
      const dipRef = 'Dips PdC — série de référence';
      const dipCl = 'Dips PdC — clusters';
      const pushRef = 'Pompes PdC — série de référence';
      const pushCl = 'Pompes PdC — clusters';
      const squat70 = 'Squat endurance @ 70 kg';
      final cases = {
        (30.0, 70.0, 65.0, 25.0): {
          (12, 4, 'Tractions PdC — séries continues'): '2 × 18 reps',
          (13, 4, pullRef): '1 × 18 reps',
          (13, 4, pullCl): '5 × 8 reps',
          (14, 4, pullCl): '5 × 10 reps',
          (15, 4, pullCl): '5 × 5 reps',
          (18, 4, pullCl): '5 × 11 reps',
          (13, 5, dipRef): '1 × 42 reps',
          (13, 5, dipCl): '5 × 20 reps',
          (14, 5, dipCl): '5 × 22 reps',
          (15, 5, dipCl): '5 × 11 reps',
          (18, 5, dipCl): '5 × 25 reps',
          (13, 5, pushRef): '1 × 39 reps',
          (13, 5, pushCl): '5 × 10 reps',
          (14, 5, pushCl): '5 × 12 reps',
          (15, 5, pushCl): '5 × 5 reps',
          (18, 5, pushCl): '5 × 14 reps',
          (13, 6, squat70): '3 × 10 reps',
        },
        (33.0, 80.0, 70.0, 30.0): {
          (12, 4, 'Tractions PdC — séries continues'): '2 × 20 reps',
          (13, 4, pullRef): '1 × 20 reps',
          (13, 4, pullCl): '5 × 9 reps',
          (14, 4, pullCl): '5 × 11 reps',
          (15, 4, pullCl): '5 × 5 reps',
          (18, 4, pullCl): '5 × 12 reps',
          (13, 5, dipRef): '1 × 48 reps',
          (13, 5, dipCl): '5 × 22 reps',
          (14, 5, dipCl): '5 × 26 reps',
          (15, 5, dipCl): '5 × 13 reps',
          (18, 5, dipCl): '5 × 29 reps',
          (13, 5, pushRef): '1 × 42 reps',
          (13, 5, pushCl): '5 × 11 reps',
          (14, 5, pushCl): '5 × 13 reps',
          (15, 5, pushCl): '5 × 5 reps',
          (18, 5, pushCl): '5 × 15 reps',
          (13, 6, squat70): '3 × 12 reps',
        },
      };
      cases.forEach((maxima, expected) {
        app.setValue('B17', maxima.$1);
        app.setValue('B18', maxima.$2);
        app.setValue('B19', maxima.$3);
        app.setValue('B20', maxima.$4);
        expected.forEach((key, value) {
          expect(label(key.$1, key.$2, key.$3), value, reason: '$maxima $key');
        });
      });
    });

    test('squat pause : 0,67 × 120 kg → 80 kg (arrondi 2,5 kg)', () {
      // L4 : 120 kg est la valeur du classeur, saisie ici explicitement
      // (une installation neuve n'a aucune référence).
      expect(
        app.program.pilotage.mainLifts.firstWhere((l) => l.ref == 'B11').oneRm,
        120,
      );
      app.setValue('B11', 120);
      final e = line(12, 3, 'Squat pause 2 s');
      expect(app.loadFor(e), 80);
      expect(app.loadLabel(e), '80 kg');
    });

    test('LC1b : S11·J6 au format du J6 de S12, squat endurance S11 gardé', () {
      final day = app.program.week(11).day(6)!;
      final s12 = app.program.week(12).day(6)!;
      expect(day.title, 'PUISSANCE MU + SQUAT ENDURANCE');
      expect(day.cycle, 'DELOAD');
      expect(
        day.conduite,
        startsWith(
          'CONDUITE J6 — Muscle-up au poids de corps et tirage explosif, squat endurance. AUCUNE charge maximale. | ',
        ),
      );
      expect(day.conduite.contains('Test'), isFalse);
      expect(
        [for (final e in day.exercises) e.id],
        ['B1-L1b-001', 'B1-521', 'B1-525', 'B1-527', 'B1-529'],
      );
      expect(
        [for (final e in day.exercises) e.name],
        [
          'Muscle-ups PdC explosifs',
          'Tractions explosives poitrine-barre',
          'Squat endurance @ 70 kg',
          'Leg raises lestés (suspendu)',
          'Mobilité épaules + poignets',
        ],
      );
      // Même format que S12·J6, sauf le squat (test max en S12 seulement).
      for (final i in [0, 1, 3, 4]) {
        final a = day.exercises[i], b = s12.exercises[i];
        expect(
          (a.name, a.sets.value, a.intensity, a.rest, a.tempo, a.cue),
          (b.name, b.sets.value, b.intensity, b.rest, b.tempo, b.cue),
          reason: a.id,
        );
        expect(app.setCount(a), app.setCount(b), reason: a.id);
        expect(app.loadLabel(a), app.loadLabel(b), reason: a.id);
      }
      expect(s12.exercises[2].name, 'TEST MAX SQUAT @ 70 kg');
      final squat70 = day.exercises[2];
      expect(squat70.main, isTrue);
      expect(squat70.intensity, 'Sous-maximal, RIR 3');
      expect(
        (squat70.sets.coef, squat70.sets.ref, squat70.sets.div),
        (0.9, 'B20', 3),
      );
      // 3 × (0,9 × max) / 3 : max 25 → 3 × 8, max 30 → 3 × 9.
      app.setValue('B20', 25);
      expect(app.setsLabel(squat70), '3 × 8 reps');
      app.setValue('B20', 30);
      expect(app.setsLabel(squat70), '3 × 9 reps');
      expect(app.loadLabel(squat70), '70 kg');
    });

    test('séries planifiées S12/S13 (effet sur le compteur de séries)', () {
      int sets(int n) => [
        for (var j = 1; j <= 6; j++)
          for (final e in app.program.week(n).day(j)!.exercises)
            app.setCount(e),
      ].fold(0, (a, b) => a + b);
      // Avant LC1 : 198 séries planifiées par semaine de montée.
      expect(sets(12), 102);
      expect(sets(13), 117);
    });

    test('semaine S12 entièrement faite : XP et semaine complète', () async {
      final xp = app.progression.programXp;
      // Dates passées (la semaine réelle S12 est à venir) : la règle dépend
      // du nombre de journées faites, pas du nombre d'exercices.
      for (var j = 1; j <= 6; j++) {
        final log = app.sessionLog(12, j)
          ..done = true
          ..finishedAt = '2026-09-${13 + j}T18:00:00';
        for (final e in app.program.week(12).day(j)!.exercises) {
          final l = app.exLog(12, j, e);
          for (final s in l.sets) {
            s
              ..reps = '5'
              ..done = true;
          }
        }
        expect(log.done, isTrue);
      }
      app.saveLogs(immediate: true);
      await app.flush();
      expect(app.progression.programXp - xp, 600);
      // Semaine complète : au moins trois entraînements dans la semaine
      // civile du lundi 14/09.
      final week = app.progression.weeks[DateTime.utc(2026, 9, 14)];
      expect(week, isNotNull);
      expect(week!.sessions, greaterThanOrEqualTo(3));
    });
  });

  group('Séance et journal', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await store.init();
      store.settings
        ..sound = false
        ..vibration = false
        ..autoTimer = false
        ..wakelock = false
        ..prefill = true;
    });
    setUp(() {
      store.logs.clear();
      store.resetPilotage();
      // L4 : références inconnues après remise à zéro ; ces scénarios
      // utilisent les valeurs du classeur, saisies explicitement.
      final p = store.program.pilotage;
      store.setValue('B4', p.bodyweight);
      for (final l in p.mainLifts) {
        store.setValue(l.ref, l.oneRm);
      }
      for (final m in p.repMax) {
        store.setValue(m.ref, m.max);
      }
      for (final a in p.accessories) {
        store.setValue(a.ref, a.refLoad);
      }
    });

    Widget page(Widget child, {double scale = 1, bool dark = true}) =>
        MaterialApp(
          theme: buildTheme(dark),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: child,
        );

    void phone(WidgetTester tester, Size size) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets(
      'feuille Pilotage modifiée pendant la séance : volumes recalculés tout de suite',
      (tester) async {
        phone(tester, const Size(390, 844));
        final week = store.program.week(12);
        final day = week.day(4)!;
        await tester.pumpWidget(page(SessionScreen(week: week, day: day)));
        await tester.pumpAndSettle();
        expect(find.text('TEST MAX TRACTIONS PDC'), findsWidgets);
        await swipePage(tester);
        expect(find.text(nbsp('2 × 18 reps')), findsOneWidget);
        final continuous = day.exercises[1];
        List<String> reps() => [
          for (final s in store.exLog(12, 4, continuous).sets) s.reps,
        ];
        expect(reps(), ['18', '18']);
        // Première série saisie à la main : jamais écrasée.
        store.exLog(12, 4, continuous).sets.first.reps = '17';
        // Report du test (tractions : 33) dans la feuille Pilotage, depuis la
        // séance : menu → Références.
        await tester.tap(find.byTooltip('Options de séance'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Références (feuille Pilotage)'));
        await tester.pumpAndSettle();
        expect(find.byType(PilotageScreen), findsOneWidget);
        store.setValue('B17', 33);
        Navigator.of(tester.element(find.byType(PilotageScreen))).pop();
        await tester.pumpAndSettle();
        expect(find.text(nbsp('2 × 20 reps')), findsOneWidget);
        expect(reps(), ['17', '20']);
        // Nouvelle modification pendant que la page est affichée.
        store.setValue('B17', 30);
        await tester.pump();
        expect(find.text(nbsp('2 × 18 reps')), findsOneWidget);
        expect(reps(), ['17', '18']);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );

    testWidgets('journal S12 avec un identifiant supprimé : lecture intacte', (
      tester,
    ) async {
      phone(tester, const Size(320, 720));
      final log = SessionLog(
        done: true,
        finishedAt: '2026-09-21T18:00:00',
        exerciseNames: {'B2-9': 'Tirage vertical prise neutre'},
        ex: {
          'B2-9': ExerciseLog(
            sets: [
              SetEntry(kg: '65', reps: '10', done: true),
              SetEntry(kg: '65', reps: '9', done: true),
            ],
          ),
        },
      );
      store.logs['S12-J1'] = log;
      final before = log.toJson().toString();
      final exported = store.exportAll();
      expect(
        await tester.runAsync(() => store.importBackup(exported)),
        ImportStatus.success,
      );
      expect(store.logs['S12-J1']!.toJson().toString(), before);
      await tester.pumpWidget(
        page(
          SessionHistoryScreen(
            log: store.logs['S12-J1']!,
            sessionKey: 'S12-J1',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('TIRAGE VERTICAL PRISE NEUTRE'), findsOneWidget);
      expect(find.text('65'), findsNWidgets(2));
      expect(find.text('9'), findsOneWidget);
      expect(store.logs['S12-J1']!.toJson().toString(), before);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets(
      'LC1b : journal S11·J6 avec un identifiant supprimé, séance du jour',
      (tester) async {
        phone(tester, const Size(320, 720));
        final old = SessionLog(
          done: true,
          finishedAt: '2026-09-20T18:00:00',
          exerciseNames: {'B1-520': 'Excentriques de transition LESTÉS'},
          ex: {
            'B1-520': ExerciseLog(
              sets: [SetEntry(kg: '12,5', reps: '3', done: true)],
            ),
          },
        );
        store.logs['S11-J6'] = old;
        final before = old.toJson().toString();
        await tester.pumpWidget(
          page(SessionHistoryScreen(log: old, sessionKey: 'S11-J6')),
        );
        await tester.pumpAndSettle();
        expect(find.text('EXCENTRIQUES DE TRANSITION LESTÉS'), findsOneWidget);
        expect(store.logs['S11-J6']!.toJson().toString(), before);
        store.logs.remove('S11-J6');
        // Séance S11·J6 au nouveau format : 5 pages, texte 200 %.
        final week = store.program.week(11);
        final day = week.day(6)!;
        await tester.pumpWidget(
          page(SessionScreen(week: week, day: day), scale: 2),
        );
        await tester.pumpAndSettle();
        expect(find.text('MUSCLE-UPS PDC EXPLOSIFS'), findsWidgets);
        // 5.5.2 : plus de boutons, glissement de page en page jusqu'au
        // bilan (une page Koach possible avant l'exercice 1).
        for (var p = 0; p <= day.exercises.length; p++) {
          expect(tester.takeException(), isNull, reason: 'S11 J6 page $p');
          await swipePage(tester);
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );

    for (final (size, scale, dark) in [
      (const Size(390, 844), 1.3, true),
      (const Size(320, 720), 2.0, false),
      (const Size(320, 720), 1.3, true),
      (const Size(390, 844), 2.0, true),
    ]) {
      testWidgets(
        'rendu S12 J3/J4/J5 à ${size.width.toInt()}×${size.height.toInt()}, texte ${(scale * 100).round()} %, ${dark ? 'sombre' : 'clair'}',
        (tester) async {
          phone(tester, size);
          final week = store.program.week(12);
          for (final j in [3, 4, 5]) {
            final day = week.day(j)!;
            await tester.pumpWidget(
              page(
                SessionScreen(week: week, day: day),
                scale: scale,
                dark: dark,
              ),
            );
            await tester.pumpAndSettle();
            for (var p = 0; p <= day.exercises.length; p++) {
              expect(tester.takeException(), isNull, reason: 'S12 J$j page $p');
              // 5.5.2 : glissement jusqu'au bilan (plus de bouton Suivant).
              await swipePage(tester);
            }
            await tester.pumpWidget(const SizedBox());
            await tester.pumpAndSettle();
          }
        },
      );
    }
  });
}
