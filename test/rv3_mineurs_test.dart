// RV3 (dev7.7.1) — mineurs restants de RV1 (P10, R6-R8, R10, R13, F5-F7,
// F9, F11-F16) : tests de non-régression.
//
// - P10 : programme importé annoté recalculé quand le mode prudent change
//   (charges de départ plafonnées à 80 % du 1RM) ;
// - R6 : « Prochain rappel » = prochain rappel de séance, jamais un GtG ;
// - R7 : rappels replanifiés quand leur contenu change (numérotation
//   affichée PR2), sans attendre un autre signal ;
// - R8 : réglages d'affichage 3D lus au démarrage ;
// - R10 : contraste renforcé, texte secondaire à 7:1 sur `haute` ;
// - R13 : « Licences des logiciels » depuis Sources et licences ;
// - F5 : poids visé effacé avec l'objectif de poids ;
// - F6 : messages du contrat sans chemin technique (« $.x ») ;
// - F7 : priorité (schéma de mouvement) en mots ;
// - F9 : catégorie de poids d'un autre règlement retirée ;
// - F11 : fourchettes gardées au changement de discipline ;
// - F12 : calendrier d'une échéance proche ;
// - F13 : carte 2D repeinte quand l'intensité des couleurs change ;
// - F15 : valeur facultative illisible signalée ;
// - F16 : champs du test perso.
//
// Données synthétiques seulement ; horloge injectée ; stockage simulé.
import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart' show buildTheme;
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/athlete_profile_flow.dart';
import 'package:streetlift_tracker/exercise_screens.dart' show MentionsScreen;
import 'package:streetlift_tracker/kit/kit.dart'
    show KRoles, kColorIntensity, kContrast, kPaletteSources;
import 'package:streetlift_tracker/main.dart' show bootSession;
import 'package:streetlift_tracker/mannequin_3d.dart' show Display3DSettings;
import 'package:streetlift_tracker/muscle_map_2d.dart'
    show
        MapFigure,
        MapFigureState,
        MapLabels,
        MapView,
        debugSetMapLabels,
        mapLabelsIfLoaded;
import 'package:streetlift_tracker/notifications.dart';
import 'package:streetlift_tracker/profile_v3.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import 'phone_test_support.dart';
import 'support/fake_notifications.dart';

/// Brouillon complet et valide, santé autorisée et sans réponse « oui »
/// (repris de test/g6_profil_test.dart).
ProfileDraft _fullDraft() {
  final d = ProfileDraft()
    ..displayName = 'Alex'
    ..sex = kc.Sex.female
    ..birthYear = '1992'
    ..height = '168'
    ..weight = '61,5'
    ..primary = kc.TrainingDiscipline.musculation
    ..experience = kc.ExperienceLevel.intermediate
    ..consent = 'given'
    ..guidance = kc.GuidanceMode.free;
  d.addSecondary(kc.TrainingDiscipline.mobility);
  d.levels['squat'] = 2; // 60 à 80 kg
  d.goals.add(
    kc.Goal(
      id: 'goal-1',
      kind: kc.GoalKind.habit,
      origin: kc.GoalOrigin.user,
      createdOn: kc.CivilDate(2026, 10, 1),
      sessionsPerWeek: 3,
      weeks: 8,
    ),
  );
  d.days
    ..[1] = 60
    ..[4] = 45;
  d.addPlace(kc.Place.gym);
  d.answers.addAll({for (final q in kHealthQuestions) q.id: false});
  return d;
}

/// Brouillon d'un débutant complet et valide (repris de
/// test/cu_profil_v3_test.dart).
ProfileDraft _beginnerDraft() {
  final d = ProfileDraft()
    ..sex = kc.Sex.male
    ..birthYear = '1994'
    ..height = '178'
    ..primary = kc.TrainingDiscipline.generalFitness
    ..experience = kc.ExperienceLevel.beginner
    ..consent = 'refused'
    ..guidance = kc.GuidanceMode.assisted;
  d.addSecondary(kc.TrainingDiscipline.mobility);
  d.goals.add(
    kc.Goal(
      id: 'goal-1',
      kind: kc.GoalKind.habit,
      origin: kc.GoalOrigin.user,
      createdOn: kc.CivilDate(2026, 10, 1),
      sessionsPerWeek: 2,
      weeks: 8,
    ),
  );
  d.days
    ..[2] = 30
    ..[5] = 30;
  d.addPlace(kc.Place.home);
  return d;
}

/// Compétiteur élite de streetlifting (les échéances et l'objectif de
/// poids sont montrés).
ProfileDraft _eliteDraft() {
  final d = _beginnerDraft()
    ..experience = kc.ExperienceLevel.elite
    ..weight = '73'
    ..primary = kc.TrainingDiscipline.streetlifting
    ..secondaries.clear();
  d.addSecondary(kc.TrainingDiscipline.calisthenics);
  return d;
}

/// Fourchette du squat « 60 à 80 kg » (rang 2).
bool _squat60to80(kc.MovementLevel l) =>
    l.exerciseId == 'mu-back-squat-barre-haute' &&
    l.known &&
    l.low == 60 &&
    l.high == 80;

/// Laisse la file des rappels finir (fausse frontière native : tout se
/// termine en microtâches).
Future<void> _settleQueue() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('programme et rappels', () {
    late AppStore app;
    var clock = DateTime(2026, 9, 13, 12);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tzdata.initializeTimeZones();
      clock = DateTime(2026, 9, 13, 12);
      app = AppStore()..storeClock = () => clock;
      await app.init();
    });
    tearDown(() async {
      await app.flush();
      app.dispose();
    });

    test('P10 : programme importé recalculé quand le mode prudent change '
        '(65 ans atteints au 1er janvier)', () async {
      clock = DateTime(2026, 12, 30, 9);
      app.program.start = DateTime(2026, 7, 13);
      app.setValue('B4', 72);
      app.setValue('B11', 140);
      // 64 ans en 2026, 65 en 2027 ; santé autorisée, aucune réponse oui.
      final saved = app.saveAthleteProfile(_fullDraft()..birthYear = '1962');
      expect(saved, isNotNull);
      expect(app.cautionActive, isFalse);
      final before = app.importedProgram;
      expect(before, isNotNull);
      expect(identical(app.importedProgram, before), isTrue);
      clock = DateTime(2027, 1, 4, 9);
      expect(app.cautionActive, isTrue);
      expect(app.caution.reasons, contains('age65'));
      final after = app.importedProgram;
      expect(after, isNotNull);
      // Avant RV3 : même objet (charges de départ d'avant le mode prudent).
      expect(identical(after, before), isFalse);
      expect(identical(app.importedProgram, after), isTrue);
    });

    test('R6 : prochain rappel à l’heure choisie, un jour de GtG', () async {
      app.settings.notifOn = true;
      app.program.start = DateTime(2026, 7, 13);
      // GtG hors séance (comme pour le programme suivi).
      app.program.detachGtg(fromWeek: 1);
      DateTime? gtgDay;
      for (final w in app.program.weeks) {
        for (final d in w.days) {
          if (gtgDay == null && d.gtg.isNotEmpty) {
            gtgDay = app.program.dateFor(w.n, d.j);
          }
        }
      }
      expect(gtgDay, isNotNull);
      final day = gtgDay!;
      // 10 h le jour d'un GtG : la séance du jour (7 h 30) est passée, le
      // GtG de 11 h passe avant la prochaine séance.
      final now = DateTime(day.year, day.month, day.day, 10);
      final backend = FakeNotifications();
      final service = NotificationService(app, backend, now: () => now);
      addTearDown(service.dispose);
      await service.reschedule();
      expect(
        backend.scheduled.any((r) => r.reminder.id >= gtgReminderFirstId),
        isTrue,
      );
      final next = service.status.value.next!;
      expect(next.hour, app.settings.notifHour);
      expect(next.minute, app.settings.notifMinute);
      expect(next.isAfter(now), isTrue);
    });

    test('R7 : numérotation affichée changée (PR2) : rappels replanifiés '
        'sans autre signal', () async {
      app.settings.notifOn = true;
      app.program.start = DateTime(2026, 7, 13);
      final now = DateTime.utc(2026, 9, 13, 12);
      final backend = FakeNotifications();
      final service = NotificationService(app, backend, now: () => now);
      addTearDown(service.dispose);
      service.bind();
      await service.reschedule();
      expect(backend.scheduled, isNotEmpty);
      // Programme repris en S5 : la S40 devient la S36 affichée.
      app.program.firstShown = 5;
      app.setValue('B4', 72);
      await _settleQueue();
      final last = backend.scheduled.last.reminder;
      final m = RegExp(r'^S(\d+)-J(\d)$').firstMatch(last.payload)!;
      final label = app.program.sessionLabel(
        int.parse(m[1]!),
        int.parse(m[2]!),
      );
      expect(last.title, startsWith('$label — '));
    });
  });

  group('palette', () {
    test('R10 : contraste renforcé, texte secondaire à 7:1 sur `haute` et '
        '`surface`, chaque palette et intensité', () {
      final saved = kColorIntensity;
      addTearDown(() => kColorIntensity = saved);
      for (final level in [0, 1, 2]) {
        kColorIntensity = level;
        for (final p in kPaletteSources) {
          for (final dark in [true, false]) {
            final c = KRoles.of(p.id, dark: dark, contrast: true);
            final why = '${p.id} ${dark ? 'sombre' : 'clair'} $level';
            expect(
              kContrast(c.texte2, c.haute),
              greaterThanOrEqualTo(7),
              reason: why,
            );
            expect(
              kContrast(c.texte2, c.surface),
              greaterThanOrEqualTo(7),
              reason: why,
            );
          }
        }
      }
    });
  });

  group('profil', () {
    test('F6 : message d’une violation du contrat, sans chemin technique', () {
      final reps = violationText(
        const kc.Violation(r'$.reps', 'below_min', ''),
      );
      expect(reps, 'Réponse incomplète ou hors limites : répétitions.');
      expect(
        violationText(
          const kc.Violation(r'$.lifts[0].targetKg', 'above_max', ''),
        ),
        'Réponse incomplète ou hors limites : barre visée.',
      );
      for (final path in [r'$', r'$.foo', r'$.stations[2]']) {
        final text = violationText(kc.Violation(path, 'x', ''));
        expect(text, isNot(contains(r'$')), reason: path);
        expect(text, isNot(contains('foo')), reason: path);
      }
      expect(
        violationText(const kc.Violation(r'$', 'no_measure', '')),
        'Indique au moins une valeur.',
      );
    });

    test('F7 : priorité sur un schéma de mouvement, en mots', () {
      const s = kc.Specialization(
        kind: kc.SpecializationKind.pattern,
        pattern: kc.MovementPattern.pousseeHorizontale,
      );
      expect(
        specializationText(s, null),
        'Poussée horizontale (pompes, développé)',
      );
    });

    test('F11 : fourchette gardée quand la discipline change', () {
      final d = ProfileDraft()..primary = kc.TrainingDiscipline.musculation;
      d.levels['squat'] = 2; // 60 à 80 kg
      bool squat(ProfileDraft x) => x.movementLevels.any(_squat60to80);
      expect(squat(d), isTrue);
      // Le cardio ne propose pas le squat : la fourchette reste.
      d.primary = kc.TrainingDiscipline.cardio;
      expect(d.movements.any((m) => m.key == 'squat'), isFalse);
      expect(squat(d), isTrue);
      final ids = [
        for (final l in d.movementLevels) '${l.exerciseId}|${l.measure.code}',
      ];
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('F12 : jour ouvert par le calendrier dans ses bornes', () {
      final first = DateTime(2026, 10, 8), last = DateTime(2031);
      // Échéance dans 3 jours, bornes à partir de J+7 : premier jour permis.
      expect(pickerInitialDate(DateTime(2026, 10, 4), first, last), first);
      expect(pickerInitialDate(DateTime(2032, 5, 1), first, last), last);
      final inside = DateTime(2027, 2, 1);
      expect(pickerInitialDate(inside, first, last), inside);
    });
  });

  group('écrans', () {
    final now = DateTime(2026, 10, 1, 12);

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await store.init();
    });
    setUp(() async {
      store.debugWriteHook = null;
      await store.eraseAllData();
      store.storeClock = () => now;
    });
    tearDown(() => store.storeClock = DateTime.now);

    Widget page(Widget child) => MaterialApp(
      theme: buildTheme(true),
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: child,
    );

    // Hors écran quand la feuille d'une échéance est ouverte par-dessus.
    AthleteProfileFlowState flow(WidgetTester tester) =>
        tester.state(find.byType(AthleteProfileFlow, skipOffstage: false));

    Future<void> tap(WidgetTester tester, String key, {bool up = false}) async {
      final f = find.byKey(ValueKey(key));
      await scrollToAction(tester, f, up: up);
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    Future<void> type(WidgetTester tester, String key, String text) async {
      final f = find.byKey(ValueKey(key));
      await scrollToAction(tester, f);
      await tester.enterText(f, text);
      await tester.pumpAndSettle();
    }

    /// Échéances : feuille d'ajout ouverte, nature [kind], date (mois),
    /// priorité principale.
    Future<void> openEvent(WidgetTester tester, String kind) async {
      phone(tester);
      await store.saveAthleteDraft(_eliteDraft(), step: 'goals');
      await tester.pumpWidget(page(const AthleteProfileFlow()));
      await tester.pumpAndSettle();
      await tap(tester, 'event-add');
      await tap(tester, 'event-kind-$kind');
      await tap(tester, 'event-date-month');
      await tap(tester, 'event-month-6');
      await tap(tester, 'event-priority-main');
    }

    testWidgets('F5 : objectif de poids sans perte ni prise : poids visé '
        'effacé, jamais réaffiché', (tester) async {
      phone(tester);
      await store.saveAthleteDraft(_eliteDraft(), step: 'goals');
      await tester.pumpWidget(page(const AthleteProfileFlow()));
      await tester.pumpAndSettle();
      flow(tester).debugGo('recovery');
      await tester.pumpAndSettle();
      await tap(tester, 'q-body_weight_goal-lose');
      await type(tester, 'q-target-weight', '70');
      expect(flow(tester).draft.targetBodyWeightKg, 70);
      await tap(tester, 'q-body_weight_goal-maintain', up: true);
      expect(flow(tester).draft.targetBodyWeightKg, isNull);
      await tap(tester, 'q-body_weight_goal-lose', up: true);
      final field = find.byKey(const ValueKey('q-target-weight'));
      await scrollToAction(tester, field);
      // Avant RV3 : « 70 » réaffiché, rien d'enregistré.
      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
      expect(flow(tester).draft.targetBodyWeightKg, isNull);
      await store.saveAthleteDraft(null);
    });

    testWidgets('F9 : catégorie de poids d’un autre règlement retirée', (
      tester,
    ) async {
      await openEvent(tester, 'strength_competition');
      await tap(tester, 'event-preset-final_rep_2lift');
      await tap(tester, 'event-class-73');
      // « Autre » : aucune catégorie proposée.
      await tap(tester, 'event-preset-other', up: true);
      expect(find.byKey(const ValueKey('event-class-73')), findsNothing);
      await tap(tester, 'event-save');
      final e = flow(tester).draft.events!.single;
      expect(e.kind, kc.EventKind.strengthCompetition);
      expect(e.ruleset, isNull);
      expect(e.weightClassKg, isNull);
      expect(e.openWeightClass, isNull);
      expect(e.validate(), isEmpty);
      await store.saveAthleteDraft(null);
    });

    testWidgets('F15 : valeur facultative illisible signalée, rien '
        'd’enregistré en silence', (tester) async {
      await openEvent(tester, 'strength_competition');
      await tap(tester, 'event-preset-final_rep_2lift');
      await type(tester, 'event-planned-weight', 'soixante-treize');
      await tap(tester, 'event-save');
      expect(find.byKey(const ValueKey('event-error')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('event-error'))).data,
        'Une valeur saisie n’est pas lisible : corrige-la ou efface-la.',
      );
      expect(flow(tester).draft.events, isNull);
      await type(tester, 'event-planned-weight', '73,5');
      await tap(tester, 'event-save');
      expect(flow(tester).draft.events!.single.plannedBodyWeightKg, 73.5);
      await store.saveAthleteDraft(null);
    });

    testWidgets('F16 : test perso : meilleur résultat et temps visé', (
      tester,
    ) async {
      await openEvent(tester, 'personal_test');
      await type(tester, 'event-best-reps', '40');
      await type(tester, 'event-target-time', '12:30');
      await tap(tester, 'event-save');
      final e = flow(tester).draft.events!.single;
      expect(e.kind, kc.EventKind.personalTest);
      expect(e.bestTotalReps, 40);
      expect(e.targetSeconds, 750);
      expect(e.validate(), isEmpty);
      await store.saveAthleteDraft(null);
    });

    testWidgets('R13 : Sources et licences mène aux licences des logiciels', (
      tester,
    ) async {
      phone(tester);
      // Licences de synthèse seulement (pas de lecture des avis du SDK).
      LicenseRegistry.reset();
      LicenseRegistry.addLicense(
        () => Stream.value(
          const LicenseEntryWithLineBreaks(['Barlow'], 'SIL OFL 1.1'),
        ),
      );
      await tester.pumpWidget(page(const MentionsScreen()));
      final row = find.byKey(const ValueKey('mentions-software-licences'));
      final title = find.textContaining('MANNEQUIN ANATOMIQUE 3D');
      for (var i = 0; i < 100 && title.evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      expect(title, findsWidgets);
      final vertical = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      );
      for (var i = 0; i < 100 && row.hitTestable().evaluate().isEmpty; i++) {
        await tester.drag(vertical.last, const Offset(0, -300));
        await tester.pumpAndSettle();
      }
      expect(row.hitTestable(), findsOneWidget);
      await tester.tap(row);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(LicensePage), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('F13 : carte 2D repeinte quand l’intensité des couleurs '
        'change', (tester) async {
      final saved = mapLabelsIfLoaded(MapView.face);
      debugSetMapLabels(MapView.face, MapLabels(4, 4, Uint8List(16)));
      addTearDown(() => debugSetMapLabels(MapView.face, saved));
      final intensity = kColorIntensity;
      addTearDown(() => kColorIntensity = intensity);
      // (Nouvelle instance à chaque construction, comme l'application qui se
      // reconstruit : un widget constant identique n'est pas remis à jour.)
      Widget figure() => page(
        // ignore: prefer_const_constructors
        MapFigure(
          key: const ValueKey('rv3-map'),
          view: MapView.face,
          height: 200,
          intensities: const {},
          dark: true,
        ),
      );
      MapFigureState state() =>
          tester.state<MapFigureState>(find.byKey(const ValueKey('rv3-map')));
      Future<void> waitFor(bool Function() done) async {
        for (var i = 0; i < 100 && !done(); i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump();
        }
      }

      kColorIntensity = 1;
      await tester.pumpWidget(figure());
      await waitFor(() => state().image != null);
      final first = state().image;
      expect(first, isNotNull);
      // « Couleurs » changé dans les réglages : l'application se reconstruit.
      kColorIntensity = 2;
      await tester.pumpWidget(figure());
      await waitFor(() => !identical(state().image, first));
      // Avant RV3 : même image (couleurs d'avant le changement).
      expect(identical(state().image, first), isFalse);
      expect(state().image, isNotNull);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('réglages 3D', () {
    test('R8 : nom au toucher coupé, lu au démarrage (avant tout écran des '
        'réglages)', () async {
      final previous = store;
      await previous.flush();
      SharedPreferences.setMockInitialValues({'kt3d_nom_toucher': false});
      Display3DSettings.instance.reset();
      addTearDown(Display3DSettings.instance.reset);
      store = AppStore();
      await bootSession();
      expect(Display3DSettings.instance.touchNames.value, isFalse);
      expect(Display3DSettings.instance.halo.value, isTrue);
    });
  });
}
