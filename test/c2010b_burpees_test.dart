// Correctif 20/10/2026 (dev7.2.6) : finishers rameur / air bike du
// programme suivi passés en burpees (option burpee muscle-up). Données
// synthétiques uniquement.
import 'package:flutter_test/flutter_test.dart';
import 'package:streetlift_tracker/program_instance.dart';

Map<String, dynamic> _ex(String id, String name, String sets, String cat) => {
  'id': id,
  'name': name,
  'sets': {'type': 'text', 'value': sets},
  'intensity': 'Intense',
  'rest': '—',
  'cue': 'Garde la même distance sur chaque effort.',
  'catalogId': cat,
};

ProgramInstance _inst() => ProgramInstance(
  kind: 'generated',
  origin: 'user',
  createdAt: '2026-10-17T10:00:00',
  updatedAt: '2026-10-17T10:00:00',
  weeks: [
    {
      'n': 1,
      'days': [
        {
          'j': 3,
          'title': 'Jambes',
          'exercises': [
            _ex('A-1', 'Back squat', '5×5', 'sl-back-squat'),
            _ex(
              'A-2',
              'Intervalles air bike ou rameur — finisher',
              '8× (30 s effort / 30 s repos)',
              'ca-air-bike-sprints',
            ),
          ],
        },
        {
          'j': 6,
          'title': 'Jambes endurance',
          'exercises': [
            _ex(
              'B-1',
              'Intervalles rameur — finisher',
              '6× (40 s effort / 20 s repos)',
              'ca-rameur-sprint',
            ),
          ],
        },
      ],
    },
  ],
);

void main() {
  test('rameur et air bike → burpees, volume et identifiants gardés', () {
    final out = burpeeFinishers(_inst())!;
    final days = out.weeks.single['days'] as List;
    final squat = (days[0]['exercises'] as List)[0] as Map;
    final short = (days[0]['exercises'] as List)[1] as Map;
    final long = (days[1]['exercises'] as List)[0] as Map;
    expect(squat['name'], 'Back squat');
    for (final e in [short, long]) {
      expect(e['name'], kBurpeeFinisherName);
      expect(e['catalogId'], 'cf-burpee');
      expect(e['cue'], contains('burpee muscle-up'));
    }
    expect(short['id'], 'A-2');
    expect((short['sets'] as Map)['value'], '8× (30 s effort / 30 s repos)');
    expect(short['cue'], startsWith('Finisher court'));
    expect(long['cue'], startsWith('Deuxième finisher'));
    expect(long['intensity'], 'Intense');
    // Une seule fois : rien à changer au passage suivant.
    expect(burpeeFinishers(out), isNull);
  });

  test('instance sans finisher machine ou modèle : rien', () {
    final template = ProgramInstance.template(at: '2026-10-17T10:00:00');
    expect(burpeeFinishers(template), isNull);
    expect(burpeeFinishers(burpeeFinishers(_inst())!), isNull);
  });
}
