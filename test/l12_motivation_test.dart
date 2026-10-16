// L12 — règles pures de la motivation et de la progression visible :
// niveau de détail et nombre de chiffres, chaînes de progression, étapes
// réelles vues une seule fois (barème non appliqué), régularité avec jours
// de repos respectés, bornes des bilans, bibliothèque de messages (sécurité
// toujours neutre, aucun mot interdit), partage sans donnée de santé par
// défaut, parcours d'habitude, section `motiv` de la sauvegarde.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:streetlift_tracker/koach_adapt.dart' show dayIndex;
import 'package:streetlift_tracker/motivation.dart';

int d(int y, int m, int day) => dayIndex(DateTime(y, m, day));

void main() {
  group('niveau de détail (KT-065)', () {
    test('débutant et novice : victoires ; intermédiaire : simple ; avancé '
        'et expert : complet ; « Afficher toutes les statistiques »', () {
      expect(detailLevelFor(0), DetailLevel.victories);
      expect(detailLevelFor(1), DetailLevel.victories);
      expect(detailLevelFor(2), DetailLevel.simple);
      expect(detailLevelFor(3), DetailLevel.full);
      expect(detailLevelFor(4), DetailLevel.full);
      for (var l = 0; l <= 4; l++) {
        expect(detailLevelFor(l, showAll: true), DetailLevel.full);
      }
    });

    test('au plus 3 chiffres par écran de victoires', () {
      expect(figureCount('+6 pompes depuis ton départ'), 1);
      expect(figureCount('3 × 12 propres'), 2);
      expect(figureCount('Première traction !'), 0);
      expect(figureCount('1RM estimé : 36,25 kg'), 2);
      const all = [
        Victory('a', '+6 répétitions en pompes depuis ton départ', 1),
        Victory('b', 'Première traction !', 0),
        Victory('c', '5 semaines régulières', 2),
        Victory('d', '12 jours d’entraînement sur 14 prévus', 3),
        Victory('e', '+2,5 kg en squat depuis ton départ', 2),
      ];
      final picked = pickVictories(all);
      expect(picked.length, lessThanOrEqualTo(3));
      expect(
        picked.fold<int>(0, (n, v) => n + v.figures),
        lessThanOrEqualTo(kMaxVictoryFigures),
      );
      expect(picked.first.id, 'b');
      expect(
        pickVictories(all, maxFigures: 2).fold<int>(0, (n, v) => n + v.figures),
        lessThanOrEqualTo(2),
      );
    });
  });

  group('chaînes de progression (KT-066)', () {
    const chain = Chain('pompes', 'Pompes', [
      ChainStep(
        'mur',
        ChainThreshold(series: 3, reps: 15, text: '3 × 15 propres'),
      ),
      ChainStep(
        'genoux',
        ChainThreshold(series: 3, reps: 12, text: '3 × 12 propres'),
      ),
      ChainStep(
        'pompes',
        ChainThreshold(series: 3, reps: 12, text: '3 × 12 propres'),
      ),
      ChainStep(
        'lestees',
        ChainThreshold(lestPct: 20, reps: 8, text: '8 avec 20 %'),
      ),
      ChainStep('fin', null),
    ]);
    List<PerfSet> sets(List<int> reps, [double kg = 0]) => [
      for (final r in reps) (value: r, kg: kg),
    ];

    test('critère atteint dans une séance : étape franchie datée ; étape '
        'en cours et suivante', () {
      final p = chainProgress(chain, {
        'mur': [
          (day: 10, sets: sets([15, 14, 15])),
          (day: 12, sets: sets([15, 15, 16])),
        ],
      });
      expect(p.reached, {0: 12});
      expect(p.met, {0: 12});
      expect(p.current, 1);
      expect(p.stateOf(0), ChainStepState.reached);
      expect(p.stateOf(1), ChainStepState.current);
      expect(p.stateOf(2), ChainStepState.next);
      expect(p.stateOf(3), ChainStepState.locked);
      expect(p.currentStep!.threshold!.text, '3 × 12 propres');
    });

    test('étape plus avancée pratiquée : étapes précédentes franchies par '
        'déduction, sans étape réelle célébrée', () {
      final p = chainProgress(chain, {
        'pompes': [
          (day: 20, sets: sets([5, 5])),
        ],
      });
      expect(p.reached.keys, containsAll([0, 1]));
      expect(p.met, isEmpty);
      expect(p.current, 2);
      expect(p.practiced, {2: 20});
      expect(p.started, isTrue);
    });

    test('lest en pourcentage du poids de corps', () {
      final perf = {
        'lestees': [
          (day: 30, sets: sets([8], 14)),
        ],
      };
      expect(
        chainProgress(chain, perf, bodyweight: 80).met.containsKey(3),
        isFalse,
      );
      expect(chainProgress(chain, perf, bodyweight: 70).met, {3: 30});
      expect(chainProgress(chain, perf).met, isEmpty);
    });

    test('chaînes mises en avant selon l\'objectif', () {
      expect(chainsForGoals(['health']), contains('pompes'));
      expect(chainsForGoals(['health']), isNot(contains('front_lever')));
      expect(chainsForGoals(['event'], eventItems: ['mu_1rm']), ['muscle_up']);
      expect(chainsForGoals(const []), contains('tractions'));
    });

    test('pack réel : 24 chaînes, seuils lus', () {
      final raw =
          jsonDecode(
                utf8.decode(
                  gzip.decode(
                    File(
                      'assets/content/progressions.json.gz',
                    ).readAsBytesSync(),
                  ),
                ),
              )
              as Map<String, dynamic>;
      final book = ChainBook.fromJson(raw);
      expect(book.chains, hasLength(24));
      final t = book.byId['tractions']!;
      expect(t.steps.first.threshold!.seconds, 30);
      expect(t.steps.last.threshold, isNull);
      expect(
        book.chains.expand((c) => c.steps).where((s) => s.threshold != null),
        isNotEmpty,
      );
    });
  });

  group('étapes réelles et récompenses (KT-067)', () {
    const ms = [
      Milestone('record:pompes:2026-09-21', 'record', 'Record : Pompes', 100),
      Milestone('chain:pompes', 'chain', 'Étape franchie : Pompes', 105),
      Milestone('regular:4', 'regular', '4 semaines régulières', 90),
    ];

    test('célébrées une seule fois, récentes seulement', () {
      final pending = pendingMilestones(ms, const {}, 106);
      expect(pending.map((m) => m.id), [
        'record:pompes:2026-09-21',
        'chain:pompes',
      ]);
      final seen = {'record:pompes:2026-09-21': '2026-09-25'};
      expect(pendingMilestones(ms, seen, 106).map((m) => m.id), [
        'chain:pompes',
      ]);
      expect(
        pendingMilestones(ms, {...seen, 'chain:pompes': 'x'}, 106),
        isEmpty,
      );
      // Une étape future n'est jamais célébrée d'avance.
      expect(pendingMilestones(ms, const {}, 99), isEmpty);
    });

    test('barème proposé mais non appliqué (invariant économie)', () {
      expect(kMilestoneRewardsApproved, isFalse);
      for (final m in ms) {
        expect(milestoneCredits(m), 0);
      }
      expect(kMilestoneCreditsProposal['chain'], greaterThan(0));
      expect(kMilestoneCreditsProposal['regular:52'], greaterThan(0));
    });
  });

  group('régularité : les jours de repos respectés comptent (KT-067)', () {
    // Semaine du lundi 21/09/2026 ; séances prévues lundi, mercredi,
    // vendredi.
    final monday = d(2026, 9, 21);
    final planned = {monday, monday + 2, monday + 4};

    test('jour de repos respecté compté ; séance un jour de repos jamais '
        'pénalisée ni comptée comme repos', () {
      final base = weekRegularity(
        monday: monday,
        planned: planned,
        training: {monday, monday + 2, monday + 4},
        today: monday + 7,
      );
      expect(base.planned, 3);
      expect(base.plannedDone, 3);
      expect(base.restDays, 4);
      expect(base.restRespected, 4);
      expect(base.onPlan, 7);
      expect(base.regular, isTrue);
      final extra = weekRegularity(
        monday: monday,
        planned: planned,
        training: {monday, monday + 1, monday + 2, monday + 4},
        today: monday + 7,
      );
      expect(extra.restRespected, 3);
      expect(extra.done, 4);
      expect(extra.regular, isTrue);
    });

    test('semaine en cours : jours futurs non comptés ; aujourd\'hui sans '
        'séance un jour de repos = repos respecté', () {
      final w = weekRegularity(
        monday: monday,
        planned: planned,
        training: {monday},
        today: monday + 1,
      );
      expect(w.plannedDone, 1);
      expect(w.restDays, 1);
      expect(w.restRespected, 1);
    });

    test('pause exclue ; 3/4 des séances ; parcours d\'habitude : 2', () {
      final paused = weekRegularity(
        monday: monday,
        planned: planned,
        training: const {},
        today: monday + 7,
        paused: {for (var i = 0; i < 7; i++) monday + i},
      );
      expect(paused.counted, isFalse);
      expect(paused.paused, isTrue);
      expect(regularTarget(3), 3);
      expect(regularTarget(4), 3);
      expect(regularTarget(2), 2);
      expect(regularTarget(1), 1);
      expect(regularTarget(4, habit: true), 2);
      expect(regularTarget(1, habit: true), 1);
      final two = weekRegularity(
        monday: monday,
        planned: planned,
        training: {monday, monday + 4},
        today: monday + 7,
        habit: true,
      );
      expect(two.regular, isTrue);
    });

    test('série et paliers de régularité', () {
      final weeks = [
        for (var i = 0; i < 9; i++)
          weekRegularity(
            monday: monday + 7 * i,
            planned: {for (final p in planned) p + 7 * i},
            training: {for (final p in planned) p + 7 * i},
            today: monday + 7 * 9,
          ),
      ];
      expect(regularStreak(weeks, monday + 7 * 9), 9);
      final tiers = regularMilestones(weeks, monday + 7 * 9);
      expect(tiers.map((m) => m.id), ['regular:4', 'regular:8']);
      expect(tiers.first.day, monday + 7 * 3 + 6);
      // Une semaine manquée remet la série à zéro.
      final broken = [
        ...weeks.take(3),
        weekRegularity(
          monday: monday + 21,
          planned: {monday + 21},
          training: const {},
          today: monday + 7 * 9,
        ),
      ];
      expect(regularStreak(broken, monday + 28), 0);
    });
  });

  group('bilans aux bornes (KT-069)', () {
    test('bilan hebdomadaire : semaine précédente, du lundi au dimanche '
        'suivant', () {
      // Dimanche 27/09 : la semaine en cours n'est pas terminée, le bilan
      // disponible est celui de la semaine du 14/09.
      expect(reviewWeekMonday(d(2026, 9, 27)), d(2026, 9, 14));
      // Lundi 28/09 : bilan de la semaine du 21/09 qui vient de finir.
      expect(reviewWeekMonday(d(2026, 9, 28)), d(2026, 9, 21));
      expect(reviewWeekMonday(d(2026, 10, 4)), d(2026, 9, 21));
      const r = WeekReview(0, 'Record : Pompes', 'a', 'b');
      expect(r.items, hasLength(3));
      expect(const WeekReview(0, null, 'a', 'b').items, hasLength(2));
    });

    test('bilan de fin de cycle : du lendemain du dernier jour, 14 jours', () {
      expect(cycleReviewOpen(100, 100), isFalse);
      expect(cycleReviewOpen(100, 101), isTrue);
      expect(cycleReviewOpen(100, 114), isTrue);
      expect(cycleReviewOpen(100, 115), isFalse);
      final cycles = programCycles([
        (1, 'b1', 'Bloc 1'),
        (2, 'b1', 'Bloc 1'),
        (3, 'b2', 'Bloc 2'),
        (4, 'b1', 'Bloc 1 bis'),
      ]);
      expect(cycles.map((c) => (c.firstWeek, c.lastWeek)), [
        (1, 2),
        (3, 3),
        (4, 4),
      ]);
      expect(cycles.last.index, 3);
      expect(cycleChange({1: 100, 2: 104, 3: 110}, 1, 3), closeTo(10, 1e-9));
      expect(cycleChange({1: 100}, 1, 3), isNull);
    });

    test('assiduité jamais culpabilisante', () {
      final w = weekRegularity(
        monday: 0,
        planned: {0, 2, 4},
        training: {0},
        today: 7,
      );
      final line = adherenceLine(w);
      expect(line, contains('1 séance sur 3 prévues'));
      expect(line, contains('jours de repos respectés'));
    });
  });

  group('ton de Koach (KT-068)', () {
    test('ton par défaut selon le niveau ; exigence croissante', () {
      expect(defaultToneFor(0), 'kind');
      expect(defaultToneFor(1), 'kind');
      expect(defaultToneFor(2), 'neutral');
      expect(defaultToneFor(3), 'demanding');
      expect(defaultToneFor(4), 'demanding');
      expect(
        koachLine('session_done', 'demanding', 4),
        contains('Entraînement difficile, guerre facile'),
      );
      expect(
        koachLine('session_done', 'demanding', 0),
        isNot(koachLine('session_done', 'demanding', 4)),
      );
    });

    test('messages de sécurité : même texte neutre quel que soit le ton', () {
      for (final c in kSafetyContexts) {
        final ref = koachLine(c, 'neutral', 2);
        expect(ref, isNotEmpty);
        for (final t in kToneIds) {
          for (var l = 0; l <= 4; l++) {
            expect(koachLine(c, t, l), ref, reason: '$c $t $l');
          }
        }
      }
    });

    test(
      'bibliothèque complète, sans vocabulaire médical, humiliation, '
      'culpabilisation ni incitation à ignorer douleur, repos ou fatigue',
      () {
        final forbidden = RegExp(
          r'\b(nul|nulle|faible|honte|paresse|paresseux|flemme|excuses?|'
          r'fainéant|pathétique|mou|lâche|malgré|ignore|ignorer|diagnostic|'
          r'blessure|traitement|guérir|maladie|fatigue|souffr\w*|pitié|'
          r'jamais assez|pas le choix|déçu|décevant)\b',
          caseSensitive: false,
        );
        var count = 0;
        for (final (c, t, l, text) in allKoachLines()) {
          expect(text, isNotEmpty, reason: '$c $t $l');
          if (kSafetyContexts.contains(c)) continue;
          expect(forbidden.hasMatch(text), isFalse, reason: '$c $t $l : $text');
          expect(text.toLowerCase(), isNot(contains('douleur')));
          count++;
        }
        expect(count, kMessageContexts.length * 3 * 5);
      },
    );
  });

  test('rappels : uniquement un jour d\'entraînement prévu, hors pause '
      '(KT-070)', () {
    expect(reminderAllowed(trainingDay: true), isTrue);
    expect(reminderAllowed(trainingDay: false), isFalse);
    expect(reminderAllowed(trainingDay: true, paused: true), isFalse);
  });

  group('partage et habitude (KT-071)', () {
    const data = ShareData(
      victories: ['+6 répétitions en pompes depuis ton départ'],
      records: ['Traction lestée : 20 kg × 3'],
      regularity: '5 semaines régulières',
      chain: 'Étape franchie : Pompes',
      bodyweight: 'Poids de corps : 71,5 kg',
    );

    test('image de partage sans poids ni donnée de santé par défaut', () {
      final lines = shareLines(data, ShareOptions());
      expect(lines, hasLength(4));
      expect(lines.any((l) => l.contains('Poids')), isFalse);
      final health = RegExp(
        r'santé|douleur|gêne|maladie|médecin|questionnaire',
        caseSensitive: false,
      );
      expect(lines.any(health.hasMatch), isFalse);
      final withWeight = shareLines(data, ShareOptions(bodyweight: true));
      expect(withWeight.last, 'Poids de corps : 71,5 kg');
      expect(
        shareLines(
          data,
          ShareOptions(
            victories: false,
            records: false,
            regularity: false,
            chain: false,
          ),
        ),
        isEmpty,
      );
    });

    test('parcours d\'habitude : débutant et novice, 4 premières semaines, '
        '20 minutes ou moins', () {
      expect(habitActive(level: 0, startDay: 100, today: 100), isTrue);
      expect(habitActive(level: 1, startDay: 100, today: 127), isTrue);
      expect(habitActive(level: 1, startDay: 100, today: 128), isFalse);
      expect(habitActive(level: 1, startDay: 100, today: 99), isFalse);
      expect(habitActive(level: 2, startDay: 100, today: 100), isFalse);
      expect(habitActive(level: 0, startDay: null, today: 100), isFalse);
      expect(
        habitActive(level: 0, startDay: 100, today: 100, disabled: true),
        isFalse,
      );
      expect(habitMinutes(45), 20);
      expect(habitMinutes(15), 15);
      expect(habitMinutes(null), 20);
      expect(habitWeek(100, 100), 1);
      expect(habitWeek(100, 121), 4);
    });
  });

  group('section motiv de la sauvegarde', () {
    test('neuve = absente ; relue à l\'identique', () {
      final m = MotivData();
      expect(m.pristine, isTrue);
      m
        ..tone = 'demanding'
        ..showAll = true
        ..hideBody = true
        ..seen['chain:pompes'] = '2026-09-27'
        ..reviews['week:2026-09-21'] = '2026-09-28';
      final back = MotivData.fromJson(
        jsonDecode(jsonEncode(m.toJson())),
        strict: true,
      );
      expect(jsonEncode(back.toJson()), jsonEncode(m.toJson()));
      expect(back.pristine, isFalse);
    });

    test(
      'import strict : valeur hors contrat refusée ; démarrage tolérant',
      () {
        for (final bad in [
          {'v': 9},
          {'tone': 'cruel'},
          {'showAll': 'oui'},
          {
            'seen': {'chain:pompes': 'hier'},
          },
          'texte',
        ]) {
          expect(
            () => MotivData.fromJson(bad, strict: true),
            throwsFormatException,
            reason: '$bad',
          );
          final issues = <String>[];
          MotivData.fromJson(bad, issues: issues);
          expect(issues, isNotEmpty, reason: '$bad');
        }
        expect(MotivData.fromJson(null).pristine, isTrue);
      },
    );
  });
}
