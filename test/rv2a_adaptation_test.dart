// RV2, zone a (dev7.6.0) — adaptation du moteur 0.x, bilan du jour,
// douleur, colle des groupes. Constats signalés par RV1 (dev7.5.0) et
// RV1c1 (§ 4) :
// - A2 : une douleur signalée pendant la séance (ou un autre fait du jour)
//   ne rétablit plus un ajustement du bilan refusé ; les conseils d'un
//   exercice dont la prescription ne change pas sont gardés ;
// - groupe de l'emplacement écrit repris quand l'item servi n'a pas de
//   `groupId` (intervalles : chrono des tours, « Lancer ») ;
// - A3 : textes du moteur en livres au réglage « lb » ;
// - A4 : renvoi vers un professionnel des zones du Bilan du jour dans
//   « Santé et sécurité » ;
// - A5 : texte de la douleur à jour (plus d'« allègement de 20 % ») ;
// - A7 : « Aucune douleur » gardé après une zone ajoutée puis retirée ;
// - A8 : saisies préparées gardées le lendemain ;
// - A9 : pas de « 20,5 kg au lieu de 20,5 kg ».
// Données synthétiques ; horloge injectée ; stockage simulé.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/adapt/adapt_texts.dart';
import 'package:streetlift_tracker/adapt/health_check.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/wellbeing_screens.dart';

import 'l2_fixtures.dart';

/// Programme d'exemple commencé le 13/07/2026, journal des 11 premières
/// semaines ; « aujourd'hui » : lundi 28/09 (S12·J1), comme G9.
Future<void> _ownerState(AppStore app) async {
  final filled = filledBackup(app);
  final logs = (filled['logs'] as Map).cast<String, dynamic>();
  logs.removeWhere((k, _) {
    final w = int.parse(k.substring(1, k.indexOf('-')));
    return w >= 12;
  });
  filled['programStart'] = {
    'status': 'set',
    'date': '2026-07-13',
    'origin': 'migration',
  };
  expect(await app.importAll(jsonEncode(filled)), isTrue);
}

void _saveProfile(AppStore app, kc.GuidanceMode mode) {
  app.saveAthleteProfile(
    ProfileDraft.of(
      sampleAthleteProfile(on: civilOf(app.storeClock()), guidance: mode),
    )..consent = 'refused',
  );
}

/// Premier exercice servi par le moteur avec une charge.
Exercise _loadedEngine(DayPlan day) => day.exercises.firstWhere(
  (e) => e.engine && e.load.kg != null && e.load.kg! > 0,
);

/// Bilan très bas (forme du jour) : la séance est ajustée.
const _low = kc.HealthCheck(overall: 1, sleepQuality: 1, energy: 1);

/// Douleur de la cheville à 4/10 (synthétique).
const _ankle = kc.PainReport(
  zone: kc.BodyZone.ankleFoot,
  side: kc.BodySide.both,
  intensity: 4,
  phase: kc.PainPhase.before,
);

/// [c] avec la douleur [p] (« Douleur ou malaise ? » pendant la séance).
kc.HealthCheck _withPain(kc.HealthCheck c, kc.PainReport p) =>
    kc.HealthCheck.fromJson({
      ...c.toJson(),
      'pains': [p.toJson()],
    });

kc.ExercisePrescription? _itemOf(SessionAdapt a, String? slot) {
  for (final it in a.active.items) {
    if (it.slotId == slot) return it;
  }
  return null;
}

/// Prescription synthétique (une ligne chargée) pour les textes.
kc.ExercisePrescription _prescription(double kg, int sets) =>
    kc.ExercisePrescription(
      slotId: 's1',
      exerciseId: 'rv2-extension',
      sets: sets,
      repsLow: 10,
      repsHigh: 10,
      startLoadKg: kg,
      toCalibrate: false,
      loadBasis: kc.LoadBasis.external,
      reasons: const [],
    );

kc.SessionPlan _plan(List<kc.ExercisePrescription> items) => kc.SessionPlan(
  date: kc.CivilDate(2026, 10, 22),
  blockId: 'rv2-bloc',
  weekIndex: 0,
  dayIndex: 0,
  items: items,
  adjustments: const [],
  confidence: 1,
  reasons: const [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('magasin', () {
    late AppStore app;
    var clock = DateTime(2026, 9, 28, 9);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      clock = DateTime(2026, 9, 28, 9);
      app = AppStore()..storeClock = () => clock;
      await app.init();
    });
    tearDown(() async {
      await app.flush();
      app.dispose();
    });

    test('A2 : douleur signalée après « Annuler » (mode assisté) : '
        'l’ajustement refusé n’est pas rétabli ; un nouveau bilan le '
        'repropose', () async {
      await _ownerState(app);
      _saveProfile(app, kc.GuidanceMode.assisted);
      final day = app.program.week(12).day(1)!;
      app.adaptOpen(12, day);
      final a = app.adaptAnswer(12, day, _low)!;
      expect(a.base, isNotNull, reason: 'un bilan très bas change la séance');
      expect(a.choice, 'applied');
      expect(app.adaptChoose(12, day, 'undone')!.choice, 'undone');
      // « Douleur ou malaise ? » : le bilan du jour avec la douleur.
      final b = app.adaptAnswer(12, day, _withPain(_low, _ankle))!;
      expect(b.check!.pains!.single.zone, kc.BodyZone.ankleFoot);
      expect(b.base, isNotNull);
      expect(b.choice, 'undone');
      expect(b.adjusted, isFalse);
      // La séance faite est celle sans l'effet de la forme du jour, avec
      // la douleur (fait du jour).
      expect(jsonEncode(b.active.toJson()), jsonEncode(b.base!.toJson()));
      // Temps disponible, lieu : faits du jour aussi, le refus tient.
      final c = app.adaptSetMinutes(12, day, 45)!;
      if (c.base != null) expect(c.choice, 'undone');
      // Nouveau bilan (forme changée) : l’ajustement est reproposé.
      final d = app.adaptAnswer(
        12,
        day,
        const kc.HealthCheck(overall: 2, sleepQuality: 1),
      )!;
      if (d.base != null) expect(d.choice, 'applied');
    });

    test('A2 : séance commencée, mode libre : « Garder ma séance » tient '
        'après une douleur ; conseils d’un exercice inchangé gardés', () async {
      await _ownerState(app);
      _saveProfile(app, kc.GuidanceMode.free);
      final base = app.program.week(12).day(1)!;
      app.adaptOpen(12, base);
      final a = app.adaptAnswer(12, base, _low)!;
      expect(a.choice, 'pending');
      final kept = app.adaptChoose(12, base, 'kept')!;
      final served = app.adaptDay(12, base, kept);
      final e = _loadedEngine(served);
      final log = app.exLog(12, 1, e);
      app.adaptPrefill(12, 1, e, log);
      log.sets[0]
        ..reps = '1'
        ..flames = 10;
      expect(app.toggleSet(log, 0, app.logSpec(e)).ok, isTrue);
      app.adaptAfterSet(12, served, e, 0);
      final before = app.sessionAdapt(12, 1)!;
      final b = app.adaptAnswer(12, base, _withPain(_low, _ankle))!;
      expect(b.base, isNotNull);
      expect(b.choice, 'kept');
      expect(b.pending, isFalse);
      final slot = app.adaptSlotOf(12, 1, e.id);
      final itA = _itemOf(before, slot), itB = _itemOf(b, slot);
      final steps = before.advice[e.id];
      if (steps != null &&
          itA != null &&
          itB != null &&
          jsonEncode(itA.toJson()) == jsonEncode(itB.toJson())) {
        expect(b.advice[e.id]?.length, steps.length);
      }
      // Forme du jour : seuls les faits (douleurs, temps) changent.
      expect(SessionAdaptStore.sameHealthForm(_low, b.check), isTrue);
      expect(
        SessionAdaptStore.sameHealthForm(
          _low,
          const kc.HealthCheck(overall: 2, sleepQuality: 1, energy: 1),
        ),
        isFalse,
      );
      expect(SessionAdaptStore.sameHealthForm(null, null), isTrue);
    });

    test('A8 : séance pas commencée rouverte le lendemain : les saisies '
        'préparées de l’athlète restent, le pré-rempli est refait', () async {
      await _ownerState(app);
      _saveProfile(app, kc.GuidanceMode.assisted);
      final base = app.program.week(12).day(1)!;
      final a = app.adaptOpen(12, base)!;
      final served = app.adaptDay(12, base, a);
      final e = _loadedEngine(served);
      final log = app.exLog(12, 1, e);
      app.adaptPrefill(12, 1, e, log);
      expect(log.sets.length, greaterThan(1));
      final prefilled = log.sets[1].kg;
      // Saisie préparée (non validée) sur la 1re série.
      log.sets[0]
        ..kg = '77'
        ..reps = '4'
        ..edited = true;
      app.saveLogs(affectsProgression: false);
      // Le lendemain, rien de validé : nouvelle prescription.
      clock = DateTime(2026, 9, 29, 9);
      final b = app.adaptOpen(12, base)!;
      expect(b.date, '2026-09-29');
      final x = app.logs[app.sessionKey(12, 1)]!.ex[e.id]!;
      expect(x.sets[0].kg, '77');
      expect(x.sets[0].reps, '4');
      expect(x.sets[0].edited, isTrue);
      // Série pré-remplie : refaite d'après la séance du jour.
      final g = app.adaptGoal(12, 1, e, 1);
      if (g?.kg != null) expect(x.sets[1].kg, adaptKgField(g!.kg!));
      expect(prefilled, isNotEmpty);
    });

    test('A4 : zones du Bilan du jour au-dessus de 3/10 plus de 2 séances '
        'de suite : renvoi listé pour « Santé et sécurité »', () async {
      const pain = kc.PainReport(
        zone: kc.BodyZone.shoulder,
        side: kc.BodySide.both,
        intensity: 5,
        phase: kc.PainPhase.before,
      );
      for (final (j, date) in [
        (1, '2026-09-21'),
        (3, '2026-09-23'),
        (5, '2026-09-25'),
      ]) {
        app.sessionLog(11, j).adapt = SessionAdapt(
          blockId: 'rv2-bloc',
          weekIndex: 0,
          dayIndex: j - 1,
          date: date,
          mode: 'assisted',
          asked: true,
          check: const kc.HealthCheck(overall: 3, pains: [pain]),
          plan: _plan(const []),
        ).toJson().cast<String, dynamic>();
      }
      expect(app.adaptPainReferralZones, ['Épaule']);
      expect(app.painReferralLabels, ['Épaule']);
    });

    group('RV1c1 § 4 : groupe de l’emplacement écrit', () {
      late Exercise e;
      late String slot;
      late kc.GroupSpec written;
      late AdaptPlace place;

      setUp(() async {
        await _ownerState(app);
        _saveProfile(app, kc.GuidanceMode.assisted);
        e = app.program
            .week(3)
            .day(6)!
            .original
            .exercises
            .firstWhere((x) => x.id == 'P0-144');
        slot = app.adaptSlotOf(3, 6, e.id)!;
        place = app.adaptPlaceOf(3, 6)!;
        app.sessionLog(3, 6).adapt = null;
        written = app.exerciseGroupOf(3, 6, e)!;
        expect(written.format, kc.GroupFormat.intervals);
      });

      /// Séance servie synthétique : la journée écrite du bloc, l'item de
      /// l'emplacement modifié par [edit] ; groupes servis : ceux qui ont
      /// encore un membre ([extra] en plus).
      void serve(
        kc.ExercisePrescription Function(kc.ExercisePrescription) edit, {
        List<kc.GroupSpec> extra = const [],
      }) {
        final items = [
          for (final it in place.day!.items) it.slotId == slot ? edit(it) : it,
        ];
        final used = {
          for (final it in items)
            if (it.groupId case final id?) id,
        };
        final plan = kc.SessionPlan(
          date: kc.CivilDate(2026, 9, 28),
          blockId: place.blockId,
          weekIndex: place.weekIndex,
          dayIndex: place.dayIndex,
          items: items,
          adjustments: const [],
          confidence: 1,
          reasons: const [],
          groups: [
            for (final g in [...?place.day!.groups, ...extra])
              if (used.contains(g.groupId)) g,
          ],
        );
        expect(plan.validate(), isEmpty);
        app.sessionLog(3, 6).adapt = SessionAdapt(
          blockId: place.blockId,
          weekIndex: place.weekIndex,
          dayIndex: place.dayIndex,
          date: '2026-09-28',
          mode: 'assisted',
          plan: plan,
        ).toJson().cast<String, dynamic>();
        expect(app.sessionAdapt(3, 6), isNotNull);
      }

      test('remplacement servi sans groupId : groupe écrit (intervalles, '
          'chrono des tours)', () {
        serve(
          (it) => it.copyWith(
            exerciseId: '${it.exerciseId}-remplacant',
            groupId: null,
          ),
        );
        expect(_itemOf(app.sessionAdapt(3, 6)!, slot)!.groupId, isNull);
        final g = app.exerciseGroupOf(3, 6, e);
        expect(g, isNotNull);
        expect(g!.groupId, written.groupId);
        expect(g.format, kc.GroupFormat.intervals);
        expect(g.rounds, written.rounds);
        expect(g.intervalSeconds, written.intervalSeconds);
      });

      test('groupId servi : inchangé ; groupId servi différent : le '
          'servi', () {
        serve((it) => it);
        expect(app.exerciseGroupOf(3, 6, e)!.groupId, written.groupId);
        serve(
          (it) => it.copyWith(groupId: 'rv2-servi'),
          extra: const [
            kc.GroupSpec(
              groupId: 'rv2-servi',
              format: kc.GroupFormat.circuit,
              rounds: 3,
            ),
          ],
        );
        final g = app.exerciseGroupOf(3, 6, e)!;
        expect(g.groupId, 'rv2-servi');
        expect(g.format, kc.GroupFormat.circuit);
      });

      test('course facile servie à la place du fractionné : seule', () {
        serve(
          (it) => it.copyWith(
            exerciseId: 'rv2-course-facile',
            sets: 1,
            repsLow: null,
            repsHigh: null,
            secondsLow: 600,
            secondsHigh: 600,
            setTargets: null,
            technique: null,
            groupId: null,
          ),
        );
        expect(app.exerciseGroupOf(3, 6, e), isNull);
      });
    });
  });

  group('textes', () {
    test('A9 : écart de charge invisible à l’affichage : non dit ; séries '
        'qui changent dites', () {
      String name(String id) => 'Extension';
      expect(
        sessionDiffLines(
          _plan([_prescription(20.4, 4)]),
          _plan([_prescription(20.5, 4)]),
          name,
        ),
        isEmpty,
      );
      expect(
        sessionDiffLines(
          _plan([_prescription(20.4, 4)]),
          _plan([_prescription(20.5, 3)]),
          name,
        ),
        ['Extension : 3 séries au lieu de 4.'],
      );
      expect(
        sessionDiffLines(
          _plan([_prescription(20, 4)]),
          _plan([_prescription(17.5, 4)]),
          name,
        ),
        ['Extension : 17,5 kg au lieu de 20 kg.'],
      );
    });

    test('A3 : réglage « lb » : charges des textes du moteur en livres', () {
      expect(adaptKgLabel(100), '100 kg');
      expect(adaptKgLabel(100, lb: true), '220,5 lb');
      expect(
        sessionDiffLines(
          _plan([_prescription(20, 4)]),
          _plan([_prescription(17.5, 4)]),
          (_) => 'Extension',
          lb: true,
        ),
        ['Extension : 38,6 lb au lieu de 44,1 lb.'],
      );
      const up = kc.Reason(code: 'adapt.load_up', params: {'deltaKg': 2.5});
      expect(
        adaptReasonText(up),
        '+2,5 kg par rapport à la dernière fois.',
      );
      expect(
        adaptReasonText(up, lb: true),
        '+5,5 lb par rapport à la dernière fois.',
      );
    });

    test('A5 : conseils de douleur à jour (moteur : zone épargnée, arrêt '
        'puis reprise par paliers)', () {
      expect(kPainAdvice, isNot(contains('20 %')));
      expect(kPainAdvice, contains('épargne la zone'));
      expect(kPainAdvice, contains('Douleur ou malaise ?'));
      expect(kPainAdvice, contains('par paliers'));
    });
  });

  group('écrans', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      store.storeClock = () => DateTime(2026, 9, 28, 9);
      await store.init();
    });

    Widget page(Widget child) => MaterialApp(
      theme: buildTheme(true),
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: child,
    );

    void phone(WidgetTester tester) {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    Future<void> tapVisible(WidgetTester tester, Finder f) async {
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    testWidgets('A7 : « Aucune douleur », zone ajoutée puis retirée : '
        '« aucune » gardé', (tester) async {
      phone(tester);
      kc.HealthCheck? result;
      await tester.pumpWidget(
        page(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  key: const ValueKey('rv2-ouvrir'),
                  onPressed: () async {
                    result = await Navigator.of(context).push<kc.HealthCheck>(
                      MaterialPageRoute(
                        builder: (_) => const HealthDetailScreen(
                          initial: kc.HealthCheck(overall: 2),
                        ),
                      ),
                    );
                  },
                  child: const Text('Bilan'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('rv2-ouvrir')));
      await tester.pumpAndSettle();
      expect(find.byType(HealthDetailScreen), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('detail-no-pain')));
      const zone = kc.BodyZone.ankleFoot;
      await tapVisible(tester, find.byKey(ValueKey('pain-zone-${zone.code}')));
      expect(find.byKey(const ValueKey('pain-sheet')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pain-save')));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('pain-${zone.code}')), findsOneWidget);
      await tapVisible(tester, find.byTooltip('Retirer'));
      expect(find.byKey(ValueKey('pain-${zone.code}')), findsNothing);
      await tapVisible(tester, find.byKey(const ValueKey('detail-save')));
      expect(result, isNotNull);
      expect(result!.pains, isNotNull);
      expect(result!.pains, isEmpty);
      expect(result!.overall, 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('A4 : « Santé et sécurité » : renvoi des zones du Bilan du '
        'jour', (tester) async {
      phone(tester);
      const pain = kc.PainReport(
        zone: kc.BodyZone.shoulder,
        side: kc.BodySide.both,
        intensity: 6,
        phase: kc.PainPhase.before,
      );
      for (final (j, date) in [
        (1, '2026-09-21'),
        (3, '2026-09-23'),
        (5, '2026-09-25'),
      ]) {
        store.sessionLog(11, j).adapt = SessionAdapt(
          blockId: 'rv2-bloc',
          weekIndex: 0,
          dayIndex: j - 1,
          date: date,
          mode: 'assisted',
          asked: true,
          check: const kc.HealthCheck(overall: 3, pains: [pain]),
          plan: _plan(const []),
        ).toJson().cast<String, dynamic>();
      }
      await tester.pumpWidget(page(const SafetyScreen()));
      await tester.pumpAndSettle();
      final referral = find.byKey(const ValueKey('safety-referral'));
      await tester.scrollUntilVisible(
        referral,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(referral, findsOneWidget);
      expect(
        tester.widget<Text>(referral).data,
        startsWith('Épaule : Cette douleur dure'),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
