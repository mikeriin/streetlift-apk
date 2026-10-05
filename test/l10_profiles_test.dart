// L10 — 13 profils types générés, contrôlés (propriétés du contrat) et
// exportés en document lisible pour relecture par le propriétaire :
// test/goldens/l10_profils_types.md (copié dans docs/PROFILS_TYPES_L10.md).
// Le document est la référence : une nouvelle génération doit le
// reproduire au caractère près (KALIS_UPDATE_GOLDEN=1 pour le réécrire).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:streetlift_tracker/program_generator.dart';
import 'package:streetlift_tracker/program_instance.dart';

import 'support/l10_support.dart';

class _Profile {
  final String title, who;
  final GenInputs inputs;
  const _Profile(this.title, this.who, this.inputs);
}

const _gym = [
  'pullup_bar',
  'dip_bars',
  'dumbbells',
  'barbell',
  'rack',
  'bench',
  'machines',
];

List<_Profile> _profiles() {
  GenInputs p({
    String goal = 'health',
    String? secondary,
    List<int> days = const [1, 3, 5],
    int minutes = 45,
    Map<String, List<String>> places = const {'home_none': []},
    Map<String, double> measures = const {},
    bool caution = false,
    Map<String, int> pains = const {},
    DateTime? event,
    List<String> items = const [],
    String focus = '',
    String autonomy = 'guided',
  }) => GenInputs(
    start: kL10Start,
    goalPrimary: goal,
    goalSecondary: secondary,
    eventDate: event,
    eventItems: items,
    weekdays: days,
    sessionMinutes: minutes,
    places: places,
    measures: measures,
    measureSources: {for (final k in measures.keys) k: 'estimated'},
    caution: caution,
    pains: pains,
    focus: focus,
    autonomy: autonomy,
  );
  return [
    _Profile(
      'Sédentaire, 45 ans, à la maison sans matériel',
      'Objectif Forme et santé, 3 × 30 min, repère : 5 pompes.',
      p(minutes: 30, measures: const {'pushups': 5}),
    ),
    _Profile(
      'Sédentaire, 58 ans, au parc',
      'Objectif Forme et santé, 2 × 30 min (mardi, samedi), 3 pompes, 0 traction.',
      p(
        days: const [2, 6],
        minutes: 30,
        places: const {
          'park': ['pullup_bar', 'dip_bars'],
        },
        measures: const {'pushups': 3, 'pullups': 0},
      ),
    ),
    _Profile(
      'Femme de 30 ans, débutante en salle',
      'Objectif Force (secondaire Forme et santé), 3 × 60 min, 2 pompes, 0 traction.',
      p(
        goal: 'strength',
        secondary: 'health',
        minutes: 60,
        places: const {'gym': _gym},
        measures: const {'pushups': 2, 'pullups': 0},
      ),
    ),
    _Profile(
      'Senior de 67 ans, mode prudent',
      'Objectif Forme et santé, 3 × 45 min, maison équipée, 8 pompes ; mode prudent (65 ans et plus).',
      p(
        places: const {
          'home_equipped': ['pullup_bar', 'bands', 'dumbbells', 'mat'],
        },
        measures: const {'pushups': 8},
        caution: true,
      ),
    ),
    _Profile(
      'Homme de 35 ans, intermédiaire au parc',
      'Objectif Force, 4 × 60 min, parc avec lest, 35 pompes, 9 tractions.',
      p(
        goal: 'strength',
        days: const [1, 2, 4, 5],
        minutes: 60,
        places: const {
          'park': ['pullup_bar', 'dip_bars', 'weight_belt'],
        },
        measures: const {'pushups': 35, 'pullups': 9},
      ),
    ),
    _Profile(
      'Reprise après 6 mois d\'arrêt',
      'Ancien intermédiaire, objectif Force (secondaire Forme et santé), 3 × 45 min en salle ; repère actuel : 20 pompes, 5 tractions.',
      p(
        goal: 'strength',
        secondary: 'health',
        places: const {'gym': _gym},
        measures: const {'pushups': 20, 'pullups': 5},
      ),
    ),
    _Profile(
      'Préparation d\'un test physique dans 10 semaines',
      'Épreuves : pompes et tractions au maximum, le 14/12/2026 ; 4 × 60 min au parc ; 30 pompes, 8 tractions.',
      p(
        goal: 'event',
        event: l10Day(70),
        items: const ['pushups_max', 'pullups_max'],
        days: const [1, 3, 5, 6],
        minutes: 60,
        places: const {
          'park': ['pullup_bar', 'dip_bars'],
        },
        measures: const {'pushups': 30, 'pullups': 8},
      ),
    ),
    _Profile(
      'Endurance en tractions, 3 jours par semaine',
      'Objectif Endurance (tractions), 3 × 45 min, maison équipée, 25 pompes, 8 tractions.',
      p(
        goal: 'endurance',
        focus: 'pullups',
        places: const {
          'home_equipped': ['pullup_bar', 'bands', 'dumbbells', 'mat'],
        },
        measures: const {'pushups': 25, 'pullups': 8},
      ),
    ),
    _Profile(
      'Expert streetlifting (propriétaire)',
      'Épreuve des 4 mouvements lestés, secondaire Force 70/30, 6 × 120 min, parc + salle, références du classeur.',
      ownerInputs(),
    ),
    _Profile(
      'Objectif double 70/30',
      'Force (70 %) et Endurance (30 %), 4 × 75 min en salle, 40 pompes, 12 tractions.',
      p(
        goal: 'strength',
        secondary: 'endurance',
        days: const [1, 2, 4, 5],
        minutes: 75,
        places: const {'gym': _gym},
        measures: const {'pushups': 40, 'pullups': 12},
      ),
    ),
    _Profile(
      'Séances de 30 minutes',
      'Objectif Force, 4 × 30 min en salle, 30 pompes, 8 tractions.',
      p(
        goal: 'strength',
        days: const [1, 2, 4, 5],
        minutes: 30,
        places: const {'gym': _gym},
        measures: const {'pushups': 30, 'pullups': 8},
      ),
    ),
    _Profile(
      'Épaule douloureuse (5/10)',
      'Objectif Force, 3 × 60 min en salle, 30 pompes, 8 tractions ; gêne à l\'épaule 5/10 (mode prudent).',
      p(
        goal: 'strength',
        minutes: 60,
        places: const {'gym': _gym},
        measures: const {'pushups': 30, 'pullups': 8},
        pains: const {'epaule': 5},
        caution: true,
      ),
    ),
    _Profile(
      'Changement de lieu en cours de cycle',
      'Objectif Force, 3 × 45 min : parc jusqu\'au mercredi de la 3e semaine, puis salle ; suite régénérée à partir de ce jour.',
      p(
        goal: 'strength',
        places: const {
          'park': ['pullup_bar', 'dip_bars'],
        },
        measures: const {'pushups': 30, 'pullups': 8},
      ),
    ),
  ];
}

const _levels = ['débutant', 'novice', 'intermédiaire', 'avancé', 'expert'];

String _describe(GeneratedProgram g, {int detailWeeks = 2}) {
  final b = StringBuffer();
  final s = g.summary;
  b.writeln('- Modèle : **${s['modelLabel']}** — ${s['explanation']}');
  final lv = s['levels'] as Map?;
  if (lv != null) {
    final mv = lv['movements'] as Map;
    b.writeln(
      '- Niveaux : ${[for (final m in kRefMovements) '${kRefMovementLabels[m]} ${_levels[(mv[m] as Map)['level'] as int]} (${(mv[m] as Map)['source']})'].join(', ')} ; global ${_levels[lv['global'] as int]}',
    );
  }
  if (s['splitLabel'] != null) b.writeln('- Répartition : ${s['splitLabel']}');
  if (s['targets'] != null) {
    b.writeln(
      '- Séries difficiles visées par groupe et par semaine : ${(s['targets'] as Map)['dos']} (plafond ${s['ceiling']})',
    );
  }
  final weeks = (g.program['weeks'] as List).cast<Map>();
  b.writeln('- Semaines produites : ${weeks.length}');
  if (s['model'] == 'expert_streetlifting') {
    b.writeln(
      '- Programme identique au programme actuel de 40 semaines (LC1 comprise) : voir l\'application.',
    );
    return b.toString();
  }
  b.writeln();
  b.writeln(
    '| Semaine | Type | Séances | Durée moyenne estimée | Séries difficiles (dos / pectoraux / quadriceps) |',
  );
  b.writeln('| --- | --- | --- | --- | --- |');
  for (final w in weeks) {
    final days = [
      for (final d in w['days'] as List)
        if (((d as Map)['exercises'] as List).isNotEmpty) d,
    ];
    final minutes = days.isEmpty
        ? 0
        : days
                  .map((d) => dayMinutes(d.cast<String, dynamic>()))
                  .reduce((a, c) => a + c) /
              days.length;
    final vol = <String, int>{};
    for (final d in days) {
      for (final e in d['exercises'] as List) {
        final em = e as Map;
        if (em['hard'] is! int) continue;
        for (final gr in em['groups'] as List) {
          vol['$gr'] = (vol['$gr'] ?? 0) + (em['hard'] as int);
        }
      }
    }
    b.writeln(
      '| S${w['n']} | ${w['kind']} · ${w['phase']} | ${days.length} | ${minutes.toStringAsFixed(0)} min | ${vol['dos'] ?? 0} / ${vol['pectoraux'] ?? 0} / ${vol['quadriceps'] ?? 0} |',
    );
  }
  for (final w in weeks.take(detailWeeks)) {
    b.writeln();
    b.writeln('#### Semaine ${w['n']}');
    for (final d in w['days'] as List) {
      final dm = (d as Map).cast<String, dynamic>();
      final exs = dm['exercises'] as List;
      if (exs.isEmpty) continue;
      b.writeln();
      b.writeln(
        '**J${dm['j']} — ${dm['title']}** (${dm['place']}, ≈ ${dayMinutes(dm).toStringAsFixed(0)} min${dm['capped'] == true ? ', volume plafonné' : ''}) — ${dm['why']}',
      );
      b.writeln();
      for (final e in exs) {
        final em = e as Map;
        b.writeln(
          '- ${em['name']} : ${(em['sets'] as Map)['value']} · ${em['intensity']} · repos ${em['rest']} — _${em['why']}_',
        );
      }
    }
  }
  return b.toString();
}

void main() {
  final data = L10Data.load();

  test('13 profils types : propriétés respectées et document de relecture', () {
    final doc = StringBuffer()
      ..writeln('# Kalis Track 4.0.0 — 13 profils types (générateur L10)')
      ..writeln()
      ..writeln(
        'Document généré par `test/l10_profiles_test.dart` (générateur $kGeneratorVersion, graine 2026, départ lundi 5 octobre 2026). '
        'Contenu sportif non relu par un professionnel diplômé : voir le registre de validation (`docs/CONTRAT_L10.md` §8). '
        'Les durées sont des estimations (training_estimate.dart), pas des mesures.',
      );
    final failures = <String>[];
    var k = 0;
    for (final prof in _profiles()) {
      k++;
      doc
        ..writeln()
        ..writeln('## $k. ${prof.title}')
        ..writeln()
        ..writeln(prof.who)
        ..writeln();
      final g = data.generate(prof.inputs, seed: 2026);
      failures.addAll(checkProgram(data, prof.inputs, g, tag: prof.title));
      if (prof.title.startsWith('Changement de lieu')) {
        // Régénération le mercredi de la 3e semaine : la salle remplace le
        // parc ; semaines 1-2 et lundi de S3 conservés.
        final moved = GenInputs.fromJson({
          ...prof.inputs.toJson(),
          'places': {'gym': _gym},
        });
        final next = data.generate(moved, seed: 2026, firstWeek: 3);
        final old = (g.program['weeks'] as List).cast<Map<String, dynamic>>();
        final merged = mergeWeeks(
          oldWeeks: old,
          newWeeks: (next.program['weeks'] as List)
              .cast<Map<String, dynamic>>(),
          from: (week: 3, day: 3),
          hasLog: (w, d) => w < 3 || (w == 3 && d < 3),
        );
        expect(
          merged.take(2).toList().toString(),
          old.take(2).toList().toString(),
        );
        final diff = diffWeeks(
          before: old,
          after: merged,
          from: (week: 3, day: 3),
          modelBefore: g.summary['model'] as String,
          modelAfter: next.summary['model'] as String,
        );
        doc.writeln('Avant le changement :');
        doc.writeln();
        doc.writeln(_describe(g, detailWeeks: 1));
        doc.writeln('**Ce qui change à partir du mercredi de la semaine 3 :**');
        doc.writeln();
        for (final w in diff.weeks) {
          for (final l in w.lines) {
            doc.writeln('- S${w.week} $l');
          }
        }
        doc.writeln();
        doc.writeln('Après régénération (salle) :');
        doc.writeln();
        doc.writeln(_describe(next, detailWeeks: 1));
        failures.addAll(
          checkProgram(
            data,
            moved,
            data.generate(moved, seed: 2026),
            tag: 'salle',
          ),
        );
        continue;
      }
      doc.writeln(_describe(g));
    }
    expect(failures, isEmpty, reason: failures.take(40).join('\n'));
    final file = File('test/goldens/l10_profils_types.md');
    final text = doc.toString();
    if (!file.existsSync() ||
        Platform.environment['KALIS_UPDATE_GOLDEN'] == '1') {
      file
        ..createSync(recursive: true)
        ..writeAsStringSync(text);
      return;
    }
    expect(file.readAsStringSync(), text);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
