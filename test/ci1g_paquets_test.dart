// CI1g (dev6.11.1, pipeline CP, DECISIONS_CP.md C11.7) — paquets
// `kalis_plan` 0.3.1 et `kalis_adapt` 0.3.1 (lot CY) dans l'application.
// Points imposés par CY : note `clearance_first` montrée avant la première
// séance comme une étape à confirmer ; consigne de la pompe sur barre basse
// quand elle remplace une poussée pour une gêne du poignet ;
// `shoulder_history` sous le développé au-dessus de la tête ; textes de
// tous les nouveaux codes (aucun code brut). C11 : le programme de 40
// semaines reste découpé en blocs de six semaines au plus (option
// `restructureImported` sans objet). Données synthétiques ; stockage simulé.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_adapt/kalis_adapt.dart' as ka;
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_plan/kalis_plan.dart' as kp;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/adapt/adapt_texts.dart';
import 'package:streetlift_tracker/adapt/clearance.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/plan/coach_texts.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';

/// Premier profil des fixtures du parcours v3 (`kalis_core`) dont la
/// discipline principale est dans [primaries], en JSON.
Map<String, Object?> _fixtureJson([
  Set<String> primaries = const {
    'street_workout',
    'streetlifting',
    'calisthenics',
  },
]) {
  final raw =
      jsonDecode(
            File(
              'packages/kalis_core/test/fixtures/profiles_v3.json',
            ).readAsStringSync(),
          )
          as Map<String, Object?>;
  return [
    for (final p in raw['profiles']! as List)
      ((p as Map)['profile'] as Map).cast<String, Object?>(),
  ].firstWhere((p) {
    final primary = kc.AthleteProfile.fromJson(p).disciplines.primary.code;
    return primaries.contains(primary);
  });
}

/// Profil street (ou [primaries]) avec une gêne de l'épaule déclarée à
/// [discomfort]/10 (consentement santé donné), programme du chemin calibré
/// créé.
void _streetWithShoulder(
  AppStore app,
  int discomfort, {
  Set<String>? primaries,
  String since = 'months_3_to_12',
}) {
  final json = Map<String, Object?>.of(
    primaries == null ? _fixtureJson() : _fixtureJson(primaries),
  );
  json['limitations'] = [
    {
      'zone': 'shoulder',
      'side': 'right',
      'joint': 'epaule',
      'discomfort': discomfort,
      'since': since,
    },
  ];
  final r = app.saveAthleteProfile(
    ProfileDraft.of(kc.AthleteProfile.fromJson(json))..consent = 'given',
  );
  expect(r, isNotNull, reason: 'profil enregistré');
  final c = PlanStore(app).newPlanCreation(journal: false)!;
  c.start();
  c.createPass2();
  PlanStore(app).applyPlanCreation(c);
}

/// Première journée du programme créé servie par le moteur (S, J).
(int, int)? _firstDay(AppStore app) {
  final plan = app.planProgram;
  if (plan == null) return null;
  for (var w = plan.firstWeek; w <= app.program.weeks.length; w++) {
    for (var j = 1; j <= 7; j++) {
      final day = app.program.week(w).day(j);
      if (day == null || day.exercises.isEmpty) continue;
      if (app.adaptPlaceOf(w, j) != null) return (w, j);
    }
  }
  return null;
}

kc.Reason _note(String note, double value) => kc.Reason(
  code: kc.ReasonCodes.planCoachNote,
  params: {'note': note, 'value': value},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('paquets 0.3.1 dans l’application', () {
    expect(kp.kalisPlanVersion, '0.3.1');
    expect(ka.kalisAdaptVersion, '0.3.1');
    // C11 : défaut inchangé pour tous (option du lot CY).
    expect(ka.KalisAdapt().restructureImported, isFalse);
  });

  group('textes (aucun code brut)', () {
    late AppStore app;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      app = AppStore()..storeClock = () => DateTime(2026, 10, 9, 9);
      await app.init();
    });
    tearDown(() async {
      await app.flush();
      app.dispose();
    });

    test('toutes les notes de coach de kalis_plan 0.3.1 sont rédigées', () {
      final catalog = app.content.catalog;
      expect(catalog, isNotNull);
      expect(kp.CoachNotes.all, contains(kp.CoachNotes.clearanceFirst));
      expect(kp.CoachNotes.all, contains(kp.CoachNotes.shoulderHistory));
      for (final note in kp.CoachNotes.all) {
        // (`cue` : consigne n° 1 à 12 seulement.)
        final values = note == kp.CoachNotes.cue
            ? [for (var i = 1; i <= 12; i++) i.toDouble()]
            : <double>[0, 2, 6, 12, 85];
        for (final v in values) {
          final t = coachText(_note(note, v), catalog);
          expect(t, isNotNull, reason: '$note ($v)');
          expect(t!.trim(), isNotEmpty, reason: note);
          expect(t.contains(note), isFalse, reason: '$note : code brut');
          expect(t.contains('plan.'), isFalse, reason: note);
          expect(t.contains('{'), isFalse, reason: '$note : gabarit');
        }
      }
    });

    test('avis médical, épaule, genou : en tête avec le bouclier', () {
      final catalog = app.content.catalog;
      for (final note in [
        kp.CoachNotes.clearanceFirst,
        kp.CoachNotes.shoulderHistory,
        kp.CoachNotes.kneeShallow,
      ]) {
        expect(isPainReason(_note(note, 0)), isTrue, reason: note);
      }
      expect(isPainReason(_note(kp.CoachNotes.wodPace, 8)), isFalse);
      final gene = coachText(_note(kp.CoachNotes.clearanceFirst, 6), catalog)!;
      expect(gene, startsWith('Gêne déclarée à 6/10'));
      final quest = coachText(_note(kp.CoachNotes.clearanceFirst, 0), catalog)!;
      expect(quest, startsWith('Ton questionnaire de santé'));
      expect(
        coachText(_note(kp.CoachNotes.shoulderHistory, 0), catalog),
        startsWith('Épaule opérée ou déjà blessée'),
      );
    });

    test('pompe sur barre basse pour une gêne du poignet : consigne de CY', () {
      String name(String id) => switch (id) {
        'sw-pompe' => 'Pompes',
        'sw-pompe-inclinee' => 'Pompe inclinée (mains surélevées)',
        _ => 'Pompes sur parallettes',
      };
      const wrist = kc.Reason(
        code: 'adapt.pain_reported',
        params: {'zone': 'wrist_hand', 'intensity': 3},
      );
      final bar = adjustmentText(
        const kc.SessionAdjustment(
          kind: kc.AdjustmentKind.exerciseSwapped,
          exerciseId: 'sw-pompe',
          replacementExerciseId: 'sw-pompe-inclinee',
          reasons: [wrist],
        ),
        name,
      );
      expect(
        bar,
        'Remplacement : Pompes → Pompe inclinée (mains surélevées) (gêne du '
        'poignet) : mains serrées sur la barre basse, poignets droits.',
      );
      expect(wristBarPushUp('sw-pompe-inclinee', const [wrist]), isTrue);
      expect(wristBarPushUp('sw-pompe-parallettes', const [wrist]), isFalse);
      expect(
        wristBarPushUp('sw-pompe-inclinee', const [
          kc.Reason(
            code: 'adapt.pain_reported',
            params: {'zone': 'shoulder', 'intensity': 3},
          ),
        ]),
        isFalse,
      );
      expect(
        adjustmentText(
          const kc.SessionAdjustment(
            kind: kc.AdjustmentKind.exerciseSwapped,
            exerciseId: 'sw-pompe',
            replacementExerciseId: 'sw-pompe-parallettes',
            reasons: [wrist],
          ),
          name,
        ),
        'Remplacement : Pompes → Pompes sur parallettes (gêne du poignet : '
        'appui neutre, poignets droits).',
      );
      expect(
        kWristBarPushUpCue,
        'Mains serrées sur la barre basse, poignets '
        'droits.',
      );
    });

    test('charge plafonnée (`cap`) : rédigée', () {
      final t = adaptReasonText(
        const kc.Reason(code: 'adapt.load_held', params: {'cause': 'cap'}),
        exerciseName: (id) => id,
      )!;
      expect(t, startsWith('Charge plafonnée'));
      expect(t.contains('cap'), isFalse);
    });
  });

  group('avis médical avant la première séance (clearance_first)', () {
    late AppStore app;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      app = AppStore()..storeClock = () => DateTime(2026, 10, 9, 9);
      await app.init();
    });
    tearDown(() async {
      await app.flush();
      app.dispose();
    });

    test('gêne déclarée à 6/10 : note du bloc, étape à confirmer une fois '
        'par bloc, gardée dans la sauvegarde', () async {
      _streetWithShoulder(app, 6);
      final block = app.planProgram!.blocks.last.block;
      expect(isCoachBlock(block), isTrue);
      final r = coachClearanceReason(block);
      expect(r, isNotNull);
      final day = _firstDay(app)!;
      final pending = app.clearancePending(day.$1, day.$2);
      expect(pending, isNotNull);
      expect(pending!.reason.params['value'], 6);
      expect(pending.key, endsWith('#6'));
      // Réglages par défaut : export identique à 6.11.0 (aucune clé).
      expect(app.settings.toJson().containsKey('medicalClearance'), isFalse);
      app.confirmClearance(pending.key);
      expect(app.clearancePending(day.$1, day.$2), isNull);
      expect(app.settings.medicalClearance[pending.key], '2026-10-09');
      // Sauvegarde exportée puis relue : confirmation gardée.
      final exported = app.exportAll();
      SharedPreferences.setMockInitialValues({});
      final other = AppStore()..storeClock = () => DateTime(2026, 10, 9, 9);
      await other.init();
      expect(await other.importAll(exported), isTrue);
      expect(other.settings.medicalClearance[pending.key], '2026-10-09');
      await other.flush();
      other.dispose();
    });

    test('sans gêne : aucune étape', () {
      _streetWithShoulder(app, 1);
      final block = app.planProgram!.blocks.last.block;
      expect(coachClearanceReason(block), isNull);
      final day = _firstDay(app)!;
      expect(app.clearancePending(day.$1, day.$2), isNull);
    });

    test('épaule à antécédent (musculation) : `shoulder_history` sous '
        'chaque développé au-dessus de la tête écrit, avec le bouclier', () {
      final catalog = app.content.catalog!;
      var overhead = 0;
      // (Antécédent ancien et peu gênant : le développé reste écrit ; une
      // gêne forte peut le retirer.)
      var written = 0;
      for (final (level, since) in const [
        (2, 'past_resolved'),
        (3, 'over_12_months'),
        (6, 'months_3_to_12'),
      ]) {
        _streetWithShoulder(
          app,
          level,
          primaries: {'musculation'},
          since: since,
        );
        for (final b in app.planProgram!.blocks) {
          for (final w in b.block.pass2.weeks) {
            for (final d in w.days) {
              for (final it in d.items) {
                final e = catalog.find(it.exerciseId);
                if (e?.pattern == kc.MovementPattern.pousseeVerticaleHaute) {
                  written++;
                }
                final noted = it.reasons.any(
                  (r) =>
                      r.code == kc.ReasonCodes.planCoachNote &&
                      r.params['note'] == kp.CoachNotes.shoulderHistory,
                );
                if (noted) {
                  overhead++;
                  expect(
                    e?.pattern,
                    kc.MovementPattern.pousseeVerticaleHaute,
                    reason: it.exerciseId,
                  );
                  final pain = [
                    for (final r in it.reasons)
                      if (isPainReason(r)) coachText(r, catalog),
                  ];
                  expect(
                    pain.any((t) => t!.startsWith('Épaule opérée')),
                    isTrue,
                  );
                }
              }
            }
          }
        }
        // ignore: avoid_print
        print(
          'CI1G $level/10 $since : développés écrits $written, notés '
          '$overhead',
        );
      }
      expect(overhead, greaterThan(0));
    });
  });

  group('séance : étape bloquante', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      store.storeClock = () => DateTime(2026, 10, 9, 9);
      await store.init();
      _streetWithShoulder(store, 6);
    });

    Widget app(int w, int j, bool dark) => MaterialApp(
      theme: buildTheme(dark),
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: SessionScreen(
        week: store.program.week(w),
        day: store.program.week(w).day(j)!,
      ),
    );

    testWidgets('« Pas encore » puis rappel en tête ; « J’ai eu l’avis » : '
        'plus rien', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final (w, j) = _firstDay(store)!;
      clearanceDeferred.clear();
      await tester.pumpWidget(app(w, j, true));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('clearance-dialog')), findsOneWidget);
      expect(find.textContaining('Gêne déclarée à 6/10'), findsWidgets);
      // Bloquante : le retour ne la ferme pas.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('clearance-dialog')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('clearance-not-yet')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('clearance-dialog')), findsNothing);
      expect(find.byKey(const ValueKey('clearance-card')), findsOneWidget);
      expect(find.text(kClearanceWaiting), findsWidgets);
      // Même séance rouverte : pas redemandé ; rappel gardé.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(app(w, j, false));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('clearance-dialog')), findsNothing);
      expect(find.byKey(const ValueKey('clearance-card')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('clearance-card-confirm')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('clearance-card')), findsNothing);
      expect(store.clearancePending(w, j), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      // Rouverte (nouveau lancement simulé) : plus rien.
      clearanceDeferred.clear();
      await tester.pumpWidget(app(w, j, true));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('clearance-dialog')), findsNothing);
      expect(find.byKey(const ValueKey('clearance-card')), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('« J’ai eu l’avis » dans l’étape : gardé pour le bloc', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final (w, j) = _firstDay(store)!;
      final key = '${store.adaptPlaceOf(w, j)!.blockId}#6';
      store.settings.medicalClearance.remove(key);
      store.saveSettings();
      clearanceDeferred.clear();
      await tester.pumpWidget(app(w, j, false));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('clearance-dialog')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('clearance-confirm')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('clearance-dialog')), findsNothing);
      expect(find.byKey(const ValueKey('clearance-card')), findsNothing);
      expect(store.settings.medicalClearance.containsKey(key), isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('C11 : programme de 40 semaines', () {
    test('blocs du programme importé de six semaines au plus '
        '(`restructureImported` sans objet)', () async {
      SharedPreferences.setMockInitialValues({});
      final app = AppStore()..storeClock = () => DateTime(2026, 10, 9, 9);
      await app.init();
      final filled = filledBackup(app);
      filled['programStart'] = {
        'status': 'set',
        'date': '2026-07-13',
        'origin': 'migration',
      };
      expect(await app.importAll(jsonEncode(filled)), isTrue);
      app.saveAthleteProfile(
        ProfileDraft.of(sampleAthleteProfile(on: civilOf(app.storeClock())))
          ..consent = 'refused',
      );
      final segments = app.importedProgram!.segments;
      expect(segments, isNotEmpty);
      for (final s in segments) {
        expect(s.last - s.first + 1, lessThanOrEqualTo(6), reason: s.label);
        expect(s.block.pass2.weeks.length, lessThanOrEqualTo(6));
      }
      // Aucune étape d'avis médical sur le programme du propriétaire.
      expect(app.clearancePending(13, 1), isNull);
      await app.flush();
      app.dispose();
    });
  });
}
