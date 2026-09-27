// L10 — générateur de programme (KT-050 à KT-057) : niveaux, modèles,
// répartition, exercices, volume, échauffements, explications, fusion d'une
// régénération, déterminisme et références figées. Fonction pure : aucune
// horloge, assets lus sur le disque.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:streetlift_tracker/program_generator.dart';
import 'package:streetlift_tracker/program_instance.dart';

import 'support/l10_support.dart';

GenInputs _p({
  String goal = 'strength',
  String? secondary,
  int weight = 70,
  List<int> days = const [1, 3, 5],
  int minutes = 60,
  Map<String, List<String>> places = const {
    'gym': [
      'pullup_bar',
      'dip_bars',
      'dumbbells',
      'barbell',
      'rack',
      'bench',
      'machines',
    ],
  },
  Map<String, double> measures = const {'pushups': 30, 'pullups': 8},
  bool caution = false,
  Map<String, int> pains = const {},
  List<String> disliked = const [],
  DateTime? event,
  List<String> items = const [],
  String split = 'auto',
  String focus = '',
  Map<String, int> adjust = const {},
}) => GenInputs(
  start: kL10Start,
  goalPrimary: goal,
  goalSecondary: secondary,
  goalWeight: weight,
  eventDate: event,
  eventItems: items,
  weekdays: days,
  sessionMinutes: minutes,
  places: places,
  measures: measures,
  caution: caution,
  pains: pains,
  disliked: disliked,
  split: split,
  focus: focus,
  volumeAdjust: adjust,
);

Iterable<Map<String, dynamic>> _days(GeneratedProgram g) sync* {
  for (final w in g.program['weeks'] as List) {
    for (final d in (w as Map)['days'] as List) {
      yield (d as Map).cast<String, dynamic>();
    }
  }
}

Iterable<Map<String, dynamic>> _exercises(GeneratedProgram g) sync* {
  for (final d in _days(g)) {
    for (final e in d['exercises'] as List) {
      yield (e as Map).cast<String, dynamic>();
    }
  }
}

int _rir(Map<String, dynamic> e) =>
    int.parse(RegExp(r'RIR (\d)').firstMatch(e['intensity'] as String)![1]!);

void main() {
  final data = L10Data.load();

  group('KT-051 niveaux par mouvement', () {
    int level(String key, double v) =>
        movementLevels(
          data.models,
          GenInputs(start: kL10Start, measures: {key: v}),
        ).levels[switch (key) {
          'pushups' => 'push',
          'pullups' => 'pull',
          _ => 'squat',
        }]!;

    test('pompes, tractions et squat : seuils proposés au registre', () {
      for (final (v, l) in [
        (0, 0),
        (9, 0),
        (10, 1),
        (24, 1),
        (25, 2),
        (44, 2),
        (45, 3),
        (69, 3),
        (70, 4),
        (120, 4),
      ]) {
        expect(level('pushups', v.toDouble()), l, reason: 'pompes $v');
      }
      for (final (v, l) in [
        (0, 0),
        (1, 1),
        (5, 1),
        (6, 2),
        (12, 2),
        (13, 3),
        (20, 3),
        (21, 4),
      ]) {
        expect(level('pullups', v.toDouble()), l, reason: 'tractions $v');
      }
      for (final (v, l) in [
        (0.5, 0),
        (0.74, 0),
        (0.75, 1),
        (1.24, 1),
        (1.25, 2),
        (1.59, 2),
        (1.6, 3),
        (2.0, 3),
        (2.01, 4),
      ]) {
        expect(level('squatRatio', v), l, reason: 'squat $v');
      }
    });

    test('lests en % du poids du corps : avancé et expert', () {
      final a = movementLevels(
        data.models,
        GenInputs(
          start: kL10Start,
          measures: const {'pushups': 20, 'dipLoadPct': 45, 'pullLoadPct': 55},
        ),
      );
      expect(a.levels['push'], 3);
      expect(a.levels['pull'], 4);
    });

    test('niveau global = médiane basse des mouvements mesurés ; les autres '
        'mouvements prennent ce niveau « par défaut »', () {
      final l = movementLevels(
        data.models,
        GenInputs(
          start: kL10Start,
          measures: const {'pushups': 50, 'pullups': 3},
        ),
      );
      expect(l.levels['push'], 3);
      expect(l.levels['pull'], 1);
      expect(l.global, 1);
      expect(l.sources['squat'], 'default');
      expect(l.levels['squat'], 1);
      final none = movementLevels(data.models, GenInputs(start: kL10Start));
      expect(none.global, 0);
    });
  });

  group('KT-052 périodisation', () {
    test('choix automatique selon l\'objectif et le niveau', () {
      String model(GenInputs i) =>
          chooseModel(data.models, i, movementLevels(data.models, i).global);
      expect(model(_p(goal: 'health')), 'health');
      expect(model(_p(measures: const {'pushups': 5})), 'linear');
      expect(
        model(_p(measures: const {'pushups': 12, 'pullups': 2})),
        'linear',
      );
      expect(model(_p()), 'undulating');
      expect(
        model(_p(measures: const {'pushups': 50, 'pullups': 15})),
        'block',
      );
      expect(model(ownerInputs()), 'expert_streetlifting');
    });

    test('propriétaire : modèle Expert streetlifting = programme actuel, '
        '40 semaines identiques (LC1 comprise) et annotations Koach '
        'identiques', () {
      final g = data.generate(ownerInputs());
      expect(g.summary['model'], 'expert_streetlifting');
      expect((g.program['weeks'] as List), hasLength(40));
      expect(jsonEncode(g.program), jsonEncode(data.base.program));
      expect(jsonEncode(g.koach), jsonEncode(data.base.koach));
    });

    test('mode prudent : jamais le modèle Expert (tests maximaux)', () {
      final i = GenInputs.fromJson({
        ...ownerInputs().toJson(),
        'caution': true,
      });
      final g = data.generate(i);
      expect(g.summary['model'], 'block');
      expect(checkProgram(data, i, g), isEmpty);
    });

    test('sans date : cycle de 4 à 6 semaines, décharge et mini-tests', () {
      for (final i in [
        _p(measures: const {'pushups': 5}),
        _p(),
        _p(measures: const {'pushups': 50, 'pullups': 15}),
        _p(goal: 'health'),
      ]) {
        final g = data.generate(i);
        final weeks = g.program['weeks'] as List;
        expect(weeks.length, inInclusiveRange(4, 6));
        expect((weeks.last as Map)['kind'], 'deload');
        final names = [for (final e in _exercises(g)) e['name'] as String];
        expect(names.any((n) => n.endsWith('— mini-test')), isTrue);
        expect(names.any((n) => n.endsWith('— calibrage')), isTrue);
        expect(checkProgram(data, i, g), isEmpty);
      }
    });

    test('objectif daté dans 10 semaines : macrocycle, affûtage de 14 jours, '
        'simulation complète puis jour J', () {
      final i = _p(
        goal: 'event',
        event: kL10Start.add(const Duration(days: 70)),
        items: const ['pushups_max', 'pullups_max'],
        days: const [1, 3, 5, 6],
        places: const {
          'park': ['pullup_bar', 'dip_bars'],
        },
      );
      final g = data.generate(i);
      final weeks = (g.program['weeks'] as List).cast<Map>();
      expect(weeks, hasLength(11));
      expect(weeks.where((w) => w['kind'] == 'taper'), hasLength(2));
      expect(weeks.any((w) => w['kind'] == 'deload'), isTrue);
      final last = (weeks.last['days'] as List).cast<Map>();
      expect(last.first['title'], 'TEST — JOUR J');
      expect(g.summary['eventDate'], '2026-12-14');
      final names = [for (final e in _exercises(g)) e['name'] as String];
      expect(
        names.any((n) => n.endsWith('simulation complète de l\'épreuve')),
        isTrue,
      );
      expect(checkProgram(data, i, g), isEmpty);
    });

    test('« Forme et santé » : corps entier, RIR 2 à 4, circuit et mobilité, '
        'volume de départ −2 séries', () {
      final i = _p(
        goal: 'health',
        minutes: 45,
        places: const {'home_none': []},
        measures: const {'pushups': 5},
      );
      final g = data.generate(i);
      for (final d in _days(g)) {
        if ((d['exercises'] as List).isEmpty) continue;
        expect(d['title'] as String, startsWith('CORPS ENTIER'));
        final roles = [
          for (final e in d['exercises'] as List) (e as Map)['role'],
        ];
        expect(roles, contains('cooldown'));
        expect(roles, contains('circuit'));
      }
      for (final e in _exercises(g)) {
        if (e['role'] == 'main' || e['role'] == 'accessory') {
          expect(_rir(e), inInclusiveRange(2, 4));
          expect(e['family'], isNotNull);
        }
      }
      expect((g.summary['targets'] as Map)['dos'], 6 - 2);
      expect(checkProgram(data, i, g), isEmpty);
    });

    test('objectif double 70/30 : part du principal entre 60 et 80 %', () {
      final i = _p(
        secondary: 'endurance',
        days: const [1, 2, 4, 5],
        minutes: 75,
        measures: const {'pushups': 40, 'pullups': 12},
      );
      final g = data.generate(i);
      final share = (g.summary['goalShare'] as Map).cast<String, int>();
      final p = share['primary']! / (share['primary']! + share['secondary']!);
      expect(p, inInclusiveRange(0.6, 0.8));
      expect(checkProgram(data, i, g), isEmpty);
    });
  });

  group('KT-053 répartition et durée', () {
    test('règles par défaut, « Forme et santé » toujours en corps entier', () {
      expect(sessionKinds(2, 'auto', health: false), ['FB', 'FB']);
      expect(sessionKinds(3, 'auto', health: false), ['FB', 'FB', 'FB']);
      expect(sessionKinds(4, 'auto', health: false), ['U', 'L', 'U', 'L']);
      expect(sessionKinds(5, 'auto', health: false), [
        'U',
        'L',
        'PUSH',
        'PULL',
        'LEGS',
      ]);
      expect(sessionKinds(6, 'auto', health: false), [
        'PUSH',
        'PULL',
        'LEGS',
        'PUSH',
        'PULL',
        'LEGS',
      ]);
      expect(sessionKinds(4, 'auto', health: true), List.filled(4, 'FB'));
      expect(sessionKinds(3, 'ppl', health: false), ['PUSH', 'PULL', 'LEGS']);
    });

    test('durée dans ±10 % (sauf volume plafonné signalé), 48 h entre '
        'séances lourdes, jours consécutifs compris', () {
      for (final minutes in [10, 20, 30, 45, 60, 90, 120]) {
        for (final days in [
          const [1, 2],
          const [1, 2, 3],
          const [1, 2, 3, 4, 5, 6, 7],
        ]) {
          final i = _p(
            minutes: minutes,
            days: days,
            measures: const {'pushups': 60, 'pullups': 16},
          );
          final g = data.generate(i);
          expect(checkProgram(data, i, g, tag: '$minutes min $days'), isEmpty);
        }
      }
    });

    test('séances placées sur les jours choisis (J selon le départ)', () {
      final i = GenInputs.fromJson({
        ..._p(days: const [2, 4, 6]).toJson(),
        'start': '2026-10-07', // mercredi
      });
      final g = data.generate(i);
      final week = ((g.program['weeks'] as List).first as Map)['days'] as List;
      final training = [
        for (final d in week)
          if (((d as Map)['exercises'] as List).isNotEmpty) d['j'],
      ];
      // Départ un mercredi (J1) : jeudi = J2, samedi = J4, mardi = J7.
      expect(training, [2, 4, 7]);
    });
  });

  group('KT-054 choix des exercices', () {
    test('exercice détesté exclu et remplacé, gêne > 3/10 respectée, '
        'figures seulement si l\'objectif les demande', () {
      final i = _p(
        disliked: const ['Pompes'],
        pains: const {'epaule': 5},
        places: const {
          'park': ['pullup_bar', 'dip_bars'],
        },
      );
      final g = data.generate(i);
      final ids = {for (final e in _exercises(g)) e['exId']};
      expect(ids, isNot(contains('pompes')));
      expect(_exercises(g).where((e) => e['family'] == 'push'), isNotEmpty);
      for (final e in _exercises(g)) {
        final ex = data.catalog.byId[e['exId']]!;
        expect(ex.joints['epaule'] ?? 0, lessThanOrEqualTo(1), reason: ex.id);
        expect(ex.type, isNot(startsWith('figure_')), reason: ex.id);
      }
      expect(checkProgram(data, i, g), isEmpty);
    });

    test('muscle-up retenu pour une épreuve de muscle-up', () {
      final i = _p(
        goal: 'event',
        event: kL10Start.add(const Duration(days: 120)),
        items: const ['mu_max'],
        days: const [1, 3, 5],
        measures: const {'pushups': 60, 'pullups': 18},
        places: const {
          'park': ['pullup_bar', 'dip_bars'],
        },
      );
      final g = data.generate(i);
      expect(
        _exercises(
          g,
        ).any((e) => data.catalog.byId[e['exId']]!.type == 'figure_dynamique'),
        isTrue,
      );
    });

    test('mouvements principaux stables d\'un cycle à l\'autre, accessoires '
        'renouvelés', () {
      final i = _p(measures: const {'pushups': 50, 'pullups': 15});
      final a = data.generate(i, cycle: 0);
      final b = data.generate(i, firstWeek: 7, cycle: 1);
      Set<String> byRole(GeneratedProgram g, String role) => {
        for (final e in _exercises(g))
          if (e['role'] == role) e['exId'] as String,
      };
      expect(byRole(b, 'main'), byRole(a, 'main'));
      expect(byRole(b, 'accessory'), isNot(byRole(a, 'accessory')));
    });
  });

  group('KT-055 volume', () {
    test('départ par niveau, plafond départ + 6, ajustement ±2 appliqué', () {
      for (final (m, start) in [
        (const {'pushups': 5.0}, 6),
        (const {'pushups': 12.0, 'pullups': 2.0}, 8),
        (const {'pushups': 30.0, 'pullups': 8.0}, 10),
        (const {'pushups': 50.0, 'pullups': 15.0}, 12),
        (const {'pushups': 80.0, 'pullups': 25.0}, 14),
      ]) {
        final g = data.generate(_p(measures: m));
        expect((g.summary['targets'] as Map)['dos'], start);
        expect(g.summary['ceiling'], start + 6);
      }
      final g = data.generate(_p(adjust: const {'dos': 2, 'mollets': -2}));
      expect((g.summary['targets'] as Map)['dos'], 12);
      expect((g.summary['targets'] as Map)['mollets'], 8);
    });
  });

  group('KT-056 échauffement et travail spécifique', () {
    test('montée en charge 40/60/75/85 % sur un jour lourd, échauffement de '
        '5 à 10 minutes (contrôle des propriétés)', () {
      final i = _p(
        measures: const {'pushups': 50, 'pullups': 15, 'squatRatio': 1.4},
        minutes: 90,
      );
      final g = data.generate(i);
      final ramps = [
        for (final e in _exercises(g))
          if (e['role'] == 'ramp') e['intensity'] as String,
      ];
      expect(ramps, isNotEmpty);
      expect(ramps.any((r) => r.contains('40 % × 5, 60 % × 3')), isTrue);
      expect(checkProgram(data, i, g), isEmpty);
    });

    test('endurance : blocs de densité (EMOM, AMRAP court, échelles)', () {
      final i = _p(
        goal: 'endurance',
        focus: 'pullups',
        minutes: 45,
        places: const {
          'home_equipped': ['pullup_bar', 'bands', 'dumbbells', 'mat'],
        },
      );
      final g = data.generate(i);
      final blocks = [
        for (final e in _exercises(g))
          if (e['role'] == 'specific') (e['sets'] as Map)['value'] as String,
      ];
      expect(blocks.any((b) => b.startsWith('EMOM')), isTrue);
      expect(blocks.any((b) => b.startsWith('AMRAP')), isTrue);
      expect(blocks.any((b) => b.contains('échelles')), isTrue);
      expect(checkProgram(data, i, g), isEmpty);
    });
  });

  group('KT-057 explications et régénération', () {
    test('une ligne « pourquoi » par séance et par exercice, adaptée au '
        'niveau', () {
      final beginner = data.generate(_p(measures: const {'pushups': 3}));
      final expert = data.generate(
        _p(measures: const {'pushups': 80, 'pullups': 25}),
      );
      for (final g in [beginner, expert]) {
        for (final d in _days(g)) {
          expect(d['why'] as String, isNotEmpty);
        }
        for (final e in _exercises(g)) {
          expect(e['why'] as String, isNotEmpty, reason: '${e['name']}');
        }
      }
      String mainWhy(GeneratedProgram g) =>
          _exercises(g).firstWhere((e) => e['role'] == 'main')['why'];
      expect(mainWhy(beginner), startsWith('Exercice principal'));
      expect(mainWhy(expert), startsWith('Principal'));
    });

    test('fusion : journées passées et journées déjà saisies conservées, '
        'suite remplacée', () {
      final a = data.generate(_p());
      final b = data.generate(
        _p(places: const {'home_none': []}),
        firstWeek: 2,
      );
      final old = (a.program['weeks'] as List).cast<Map<String, dynamic>>();
      final merged = mergeWeeks(
        oldWeeks: old,
        newWeeks: (b.program['weeks'] as List).cast<Map<String, dynamic>>(),
        from: (week: 2, day: 3),
        hasLog: (w, d) => (w == 2 && d == 5),
      );
      expect(jsonEncode(merged.first), jsonEncode(old.first));
      final w2 = merged[1]['days'] as List;
      final o2 = old[1]['days'] as List;
      final n2 = ((b.program['weeks'] as List).first as Map)['days'] as List;
      expect(jsonEncode(w2[0]), jsonEncode(o2[0]));
      expect(jsonEncode(w2[1]), jsonEncode(o2[1]));
      expect(jsonEncode(w2[2]), jsonEncode(n2[2]));
      expect(jsonEncode(w2[4]), jsonEncode(o2[4])); // journée saisie
      final diff = diffWeeks(
        before: old,
        after: merged,
        from: (week: 2, day: 3),
        modelBefore: 'undulating',
        modelAfter: 'undulating',
      );
      expect(diff.weeks.first.lines, isNotEmpty);
      final same = diffWeeks(
        before: old,
        after: old,
        from: (week: 2, day: 1),
        modelBefore: 'undulating',
        modelAfter: 'undulating',
      );
      expect(same.empty, isTrue);
    });

    test('progression lue dans le journal : calibrage, étapes validées sur '
        '2 séances, volume ±2', () {
      final g = data.generate(
        _p(measures: const {'pushups': 12}, places: const {'home_none': []}),
      );
      final weeks = (g.program['weeks'] as List).cast<Map<String, dynamic>>();
      final logs = <String, List<LoggedSet>>{};
      String? calib;
      for (final w in weeks) {
        for (final d in w['days'] as List) {
          for (final e in (d as Map)['exercises'] as List) {
            final em = e as Map;
            final key = 'S${w['n']}-J${d['j']}';
            if (em['role'] == 'calibration' && em['exId'] == 'pompes') {
              calib ??= '$key|${em['id']}';
              logs['$key|${em['id']}'] = const [LoggedSet(24, rir: 2)];
            }
            if (em['role'] == 'main') {
              // Performance stable : volume + 2 au cycle suivant.
              logs['$key|${em['id']}'] = const [
                LoggedSet(10, rir: 2),
                LoggedSet(10, rir: 2),
              ];
            }
          }
        }
      }
      final p = progressFromLogs(
        weeks: weeks,
        catalog: data.catalog,
        sets: (k, id) => logs['$k|$id'] ?? const [],
        entries: const {},
        volumeAdjust: const {},
        cycle: 0,
      );
      if (calib != null) {
        expect(p.measures['pushups'], 26);
        expect(p.entries['pompes'], isNotNull);
      }
      expect(p.volumeAdjust.values.every((v) => v == 2), isTrue);
      expect(p.volumeAdjust, isNotEmpty);
    });
  });

  group('KT-050 déterminisme et références', () {
    test('même entrée, même graine : JSON identique au caractère près ; '
        'entrées sérialisées rejouées à l\'identique', () {
      for (final i in [
        _p(),
        _p(goal: 'health', places: const {'home_none': []}),
        _p(
          goal: 'event',
          event: kL10Start.add(const Duration(days: 90)),
          items: const ['squat_1rm', 'dip_1rm'],
        ),
      ]) {
        final a = jsonEncode(data.generate(i, seed: 7).program);
        final b = jsonEncode(data.generate(i, seed: 7).program);
        final replay = GenInputs.fromJson(
          jsonDecode(jsonEncode(i.toJson())) as Map<String, dynamic>,
        );
        final c = jsonEncode(data.generate(replay, seed: 7).program);
        expect(b, a);
        expect(c, a);
        expect(replay.profileKey, i.profileKey);
      }
    });

    test('références figées (empreinte FNV et longueur du JSON)', () {
      final profiles = <String, GenInputs>{
        'force_intermediaire_salle': _p(),
        'sante_maison': _p(goal: 'health', places: const {'home_none': []}),
        'epreuve_parc': _p(
          goal: 'event',
          event: kL10Start.add(const Duration(days: 90)),
          items: const ['pullups_max', 'dips_max'],
          places: const {
            'park': ['pullup_bar', 'dip_bars'],
          },
        ),
      };
      final now = {
        for (final e in profiles.entries)
          e.key: () {
            final s = jsonEncode(data.generate(e.value, seed: 2026).program);
            return '${genHash(s).toRadixString(16)}:${s.length}';
          }(),
      };
      final file = File('test/goldens/l10_reference.json');
      if (!file.existsSync() ||
          Platform.environment['KALIS_UPDATE_GOLDEN'] == '1') {
        file
          ..createSync(recursive: true)
          ..writeAsStringSync(
            '${const JsonEncoder.withIndent('  ').convert({'generator': kGeneratorVersion, 'profiles': now})}\n',
          );
        return;
      }
      final ref = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(ref['generator'], kGeneratorVersion);
      expect(ref['profiles'], now);
    });
  });
}
