// Invariants du moteur sur les profils types : déterminisme à l'octet près,
// « Autre proposition », verrous, erreurs d'entrée, ligne de commande.
import 'dart:convert';
import 'dart:io';

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';
import 'package:test/test.dart';

import 'support.dart';

Set<String> _freeExercises(Pass1Plan plan) => <String>{
  for (final d in plan.days)
    for (final s in d.slots)
      if (!s.locked) s.exerciseId,
};

/// Part des exercices de [b] absents de [a] (distance de « Autre
/// proposition », CONTRAT.md).
double _distance(Pass1Plan a, Pass1Plan b) {
  final before = _freeExercises(a);
  final after = _freeExercises(b);
  if (after.isEmpty) {
    return 0;
  }
  return after.where((e) => !before.contains(e)).length / after.length;
}

void main() {
  final catalog = loadCatalog();
  final inspector = PlanInspector(catalog);
  final profiles = loadProfiles();

  group('déterminisme', () {
    test('même requête, même JSON, quelle que soit l\'instance', () {
      for (final fixture in profiles) {
        final request = requestFor(fixture.profile, seed: 2);
        final a = KalisPlan().createPass1(catalog, request);
        final b = KalisPlan().createPass1(catalog, request);
        expect(jsonText(a.toJson()), jsonText(b.toJson()), reason: fixture.key);
        // Le cache de la dernière suite de propositions ne change rien :
        // demander d'abord une autre graine rend le même programme.
        final shared = KalisPlan();
        shared.createPass1(catalog, requestFor(fixture.profile));
        shared.createPass1(catalog, requestFor(fixture.profile, seed: 5));
        final c = shared.createPass1(catalog, request);
        expect(jsonText(c.toJson()), jsonText(a.toJson()), reason: fixture.key);
      }
    });

    test('le résultat ne dépend pas de l\'ordre des listes du profil', () {
      for (final fixture in profiles.take(12)) {
        final p = fixture.profile;
        final shuffled = p.copyWith(
          availability: p.availability.reversed.toList(),
          equipment: p.equipment.reversed.toList(),
          movementLevels: p.movementLevels.reversed.toList(),
          likedExerciseIds: p.likedExerciseIds.reversed.toList(),
          dislikedExerciseIds: p.dislikedExerciseIds.reversed.toList(),
        );
        final a = KalisPlan().createPass1(catalog, requestFor(p));
        final b = KalisPlan().createPass1(catalog, requestFor(shuffled));
        expect(
          jsonText(b.toJson()..remove('reasons')),
          jsonText(a.toJson()..remove('reasons')),
          reason: fixture.key,
        );
      }
    });

    test('la graine est lue modulo ${KalisPlan.alternativeCycle}', () {
      final p = profileOf('femme_30_street_workout_parc_3x45').profile;
      final a = KalisPlan().createPass1(catalog, requestFor(p, seed: 1));
      final b = KalisPlan().createPass1(
        catalog,
        requestFor(p, seed: 1 + KalisPlan.alternativeCycle),
      );
      expect(
        jsonText(b.toJson()..remove('seed')),
        jsonText(a.toJson()..remove('seed')),
      );
      expect(b.seed, 1 + KalisPlan.alternativeCycle);
    });
  });

  group('autre proposition', () {
    test('note à moins de 3 %, sécurité tenue, contraintes dures', () {
      const params = PlanParams.standard;
      for (final fixture in profiles) {
        final engine = KalisPlan();
        final best = engine.createPass1(catalog, requestFor(fixture.profile));
        for (var seed = 1; seed <= 3; seed++) {
          final request = requestFor(fixture.profile, seed: seed);
          final other = engine.createPass1(catalog, request);
          final label = '${fixture.key}, graine $seed';
          expect(inspector.hardViolations(request, other), isEmpty,
              reason: label);
          expect(other.validate(), isEmpty, reason: label);
          expect(
            other.score.total,
            greaterThanOrEqualTo(
              (1 - params.alternativeTolerance) * best.score.total - 1e-9,
            ),
            reason: label,
          );
        }
      }
    });

    test('au moins un tiers d\'exercices différents quand le vivier le '
        'permet', () {
      // Profils au vivier large : la règle des 3 % laisse la place à un
      // tiers d'exercices différents (mesure complète : VALIDATION.md).
      for (final key in <String>[
        'femme_45_musculation_salle_4x60',
        'six_jours_musculation_avance_6x75',
        'homme_25_musculation_debutant_3x60',
        'materiel_complet_gouts_marques',
        'crossfit_5x60',
      ]) {
        final engine = KalisPlan();
        final p = profileOf(key).profile;
        final best = engine.createPass1(catalog, requestFor(p));
        final other = engine.createPass1(catalog, requestFor(p, seed: 1));
        expect(
          _distance(best, other),
          greaterThanOrEqualTo(1 / 3 - 1e-9),
          reason: key,
        );
      }
    });
  });

  group('verrous', () {
    final profile = profileOf('femme_45_musculation_salle_4x60').profile;

    test('exercice exigé présent, exercice exclu absent', () {
      final base = KalisPlan().createPass1(catalog, requestFor(profile));
      final present = base.days.first.slots.first.exerciseId;
      const wanted = 'mu-hip-thrust-barre';
      final request = requestFor(
        profile,
        locks: <PlanLock>[
          PlanLock(kind: LockKind.excludeExercise, exerciseId: present),
          const PlanLock(kind: LockKind.requireExercise, exerciseId: wanted),
        ],
      );
      final plan = KalisPlan().createPass1(catalog, request);
      final ids = <String>{
        for (final d in plan.days)
          for (final s in d.slots) s.exerciseId,
      };
      expect(ids, isNot(contains(present)));
      expect(ids, contains(wanted));
      expect(inspector.hardViolations(request, plan), isEmpty);
    });

    test('emplacement gardé : même exercice, même emplacement, verrouillé', () {
      final base = KalisPlan().createPass1(catalog, requestFor(profile));
      final slot = base.days[1].slots[1];
      final request = requestFor(
        profile,
        locks: <PlanLock>[
          PlanLock(
            kind: LockKind.keepSlot,
            slotId: slot.slotId,
            exerciseId: slot.exerciseId,
          ),
        ],
      );
      for (var seed = 0; seed < 3; seed++) {
        final plan = KalisPlan().createPass1(
          catalog,
          request.copyWith(seed: seed),
        );
        final kept = plan.days[1].slots.firstWhere(
          (s) => s.slotId == slot.slotId,
        );
        expect(kept.exerciseId, slot.exerciseId);
        expect(kept.locked, isTrue);
      }
    });

    test('jour gardé : la revue d\'un autre jour n\'y touche pas', () {
      final engine = KalisPlan();
      final request = requestFor(
        profile,
        locks: const <PlanLock>[PlanLock(kind: LockKind.keepDay, dayIndex: 0)],
      );
      final plan = engine.createPass1(catalog, request);
      final result = engine.review(
        catalog,
        ReviewRequest(
          request: request,
          current: plan,
          action: ReviewAction(
            kind: ReviewKind.dislike,
            slotId: plan.days[2].slots.first.slotId,
          ),
        ),
      );
      expect(
        jsonText(result.plan.days[0].toJson()),
        jsonText(plan.days[0].toJson()),
      );
    });
  });

  group('erreurs d\'entrée', () {
    final profile = profileOf('minimal_1x20').profile;

    test('profil invalide : ArgumentError', () {
      final broken = profile.copyWith(availability: const <DaySlot>[]);
      expect(
        () => KalisPlan().createPass1(catalog, requestFor(broken)),
        throwsArgumentError,
      );
    });

    test('exercice inconnu du catalogue : ArgumentError', () {
      final broken = profile.copyWith(
        likedExerciseIds: const <String>['zz-inconnu'],
      );
      expect(
        () => KalisPlan().createPass1(catalog, requestFor(broken)),
        throwsArgumentError,
      );
    });

    test('emplacement inconnu en revue : ArgumentError', () {
      final engine = KalisPlan();
      final request = requestFor(profile);
      final plan = engine.createPass1(catalog, request);
      expect(
        () => engine.review(
          catalog,
          ReviewRequest(
            request: request,
            current: plan,
            action: const ReviewAction(kind: ReviewKind.remove, slotId: 'd9.9'),
          ),
        ),
        throwsArgumentError,
      );
    });
  });

  group('ligne de commande', () {
    test('dart run kalis_plan:plan rend le programme du moteur', () {
      final fixture = profileOf('homme_25_musculation_debutant_3x60');
      final dir = Directory.systemTemp.createTempSync('kalis_plan_cli');
      try {
        final file = File('${dir.path}/profil.json')
          ..writeAsStringSync(jsonEncode(fixture.profile.toJson()));
        final locks = File('${dir.path}/verrous.json')
          ..writeAsStringSync(
            jsonEncode(<Object?>[
              const PlanLock(
                kind: LockKind.requireExercise,
                exerciseId: 'mu-hip-thrust-barre',
              ).toJson(),
            ]),
          );
        final request = requestFor(
          fixture.profile,
          seed: 3,
          locks: const <PlanLock>[
            PlanLock(
              kind: LockKind.requireExercise,
              exerciseId: 'mu-hip-thrust-barre',
            ),
          ],
        );
        final engine = KalisPlan();
        final expected = engine.createPass1(catalog, request);
        final one = Process.runSync('dart', <String>[
          'run',
          'kalis_plan:plan',
          '--profile',
          file.path,
          '--seed',
          '3',
          '--pass',
          '1',
          '--locks',
          locks.path,
        ]);
        expect(one.exitCode, 0, reason: '${one.stderr}');
        expect(
          jsonEncode(jsonDecode(one.stdout as String)),
          jsonText(expected.toJson()),
        );
        final two = Process.runSync('dart', <String>[
          'run',
          'kalis_plan:plan',
          '--profile',
          file.path,
          '--seed',
          '3',
          '--pass',
          '2',
          '--locks',
          locks.path,
        ]);
        expect(two.exitCode, 0, reason: '${two.stderr}');
        final block = ProgramBlock.fromJson(
          jsonDecode(two.stdout as String) as Map<String, Object?>,
        );
        expect(block.validate(), isEmpty);
        expect(jsonText(block.pass1.toJson()), jsonText(expected.toJson()));
        final usage = Process.runSync('dart', <String>[
          'run',
          'kalis_plan:plan',
          '--seed',
          '1',
        ]);
        expect(usage.exitCode, 64);
      } finally {
        dir.deleteSync(recursive: true);
      }
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
