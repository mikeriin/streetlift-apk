// G12 (dev6.8.0, D1.3, D3.8, D7) — leveling et objectifs branchés sur
// kalis_quest : registre (remise à zéro, niveau jamais en baisse après la
// suppression d'une séance), gains de fin de séance, sauvegarde (section
// `questState` versionnée, import strict, démarrage tolérant, anciennes
// sections ignorées), objectifs de G6 repris, déclarations, retrait de
// l'ancien système sans référence morte, écrans dans les deux thèmes.
// Données synthétiques ; horloge injectée ; stockage simulé.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/quest/progression_view.dart';
import 'package:streetlift_tracker/quest/quest_texts.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';

/// Programme du propriétaire commencé le 13/07/2026, journal des 11
/// premières semaines ; « aujourd'hui » : lundi 28/09 (S12·J1).
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

void _profile(AppStore app) => app.saveAthleteProfile(
  ProfileDraft.of(sampleAthleteProfile(on: civilOf(app.storeClock())))
    ..consent = 'refused',
);

/// Valide toutes les séries valides de la journée S[w]·J[j].
int _doDay(AppStore app, int w, int j) {
  final day = app.program.week(w).day(j)!;
  var n = 0;
  for (final ex in day.exercises) {
    final log = app.exLog(w, j, ex);
    final spec = app.logSpec(ex);
    for (var i = 0; i < log.sets.length; i++) {
      log.sets[i].reps = '8';
      if (app.toggleSet(log, i, spec).ok) n++;
    }
  }
  return n;
}

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

    test('sans profil v2 : pas de moteur, niveau 1, aucune section', () async {
      await _ownerState(app);
      expect(app.questAvailable, isFalse);
      expect(app.quest, isNull);
      expect(app.questLevel.level, 1);
      expect(app.questData, isNull);
      expect(jsonDecode(app.exportAll()), isNot(contains('questState')));
    });

    test('remise à zéro (D1.3) : registre vide au branchement, historique '
        'sans XP rétroactif, niveau 1, propriétaire compris', () async {
      await _ownerState(app);
      _profile(app);
      final o = app.quest!;
      expect(app.questData, isNotNull);
      expect(o.level.level, 1);
      expect(o.level.prestige, 0);
      expect(o.level.totalXp, 0);
      expect(o.state.xp.where((e) => e.amount > 0), isEmpty);
      expect(o.attributes, hasLength(6));
      // Quêtes du jour créées (jour d'entraînement du programme).
      expect(
        o.state.quests.where(
          (q) => q.kind == kc.QuestKind.daily && q.startsOn == civilOf(clock),
        ),
        isNotEmpty,
      );
      // « Nouveau départ » annoncé une fois.
      expect(app.questResetToAnnounce, isTrue);
      app.markQuestResetAnnounced();
      expect(app.questResetToAnnounce, isFalse);
      // Sections de l'ancien système absentes de l'export.
      final doc = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      expect(doc.containsKey('lastLevel'), isFalse);
      expect((doc['settings'] as Map).containsKey('weeklyGoal'), isFalse);
      expect((doc['settings'] as Map).containsKey('title'), isFalse);
      expect((doc['questState'] as Map)['version'], 1);
    });

    test('fin de séance : gains du moteur, une seule fois ; séance '
        'supprimée : niveau et XP jamais en baisse', () async {
      await _ownerState(app);
      _profile(app);
      app.quest;
      expect(_doDay(app, 12, 1), greaterThan(0));
      expect(
        await app.finishSession(12, 1, title: 'S12 · J1'),
        ResultSave.saved,
      );
      final g = app.consumeGains();
      expect(g, isNotNull);
      expect(g!.xp, greaterThan(0));
      expect(g.xpBySource[kc.XpSource.effort], greaterThan(0));
      expect(app.consumeGains(), isNull);
      final effort = app.questData!.state.xp.where(
        (e) => e.source == kc.XpSource.effort && e.sessionId == 'S12-J1',
      );
      expect(effort, hasLength(1));
      final total = app.questLevel.totalXp;
      final level = app.questLevel;
      expect(total, greaterThan(0));
      // Suppression de la séance : le registre ne perd rien.
      expect(app.deleteLog('S12-J1'), isNotNull);
      clock = clock.add(const Duration(days: 1));
      final after = app.quest!;
      expect(after.level.totalXp, greaterThanOrEqualTo(total));
      expect(after.level.level, greaterThanOrEqualTo(level.level));
      expect(
        app.questData!.state.xp.where(
          (e) => e.source == kc.XpSource.effort && e.sessionId == 'S12-J1',
        ),
        hasLength(1),
      );
    });

    test('export et import : progression identique, relance identique', () async {
      await _ownerState(app);
      _profile(app);
      _doDay(app, 12, 1);
      await app.finishSession(12, 1, title: 'S12 · J1');
      app.consumeGains();
      await app.flush();
      final file = app.exportForFile(
        appVersion: 'test',
        at: DateTime(2026, 9, 28, 10),
      );
      final state = jsonEncode(app.questData!.toJson());
      SharedPreferences.setMockInitialValues({});
      final other = AppStore()..storeClock = () => clock;
      await other.init();
      final preview = other.previewImport(file).preview!;
      expect(preview.xp, app.questLevel.totalXp);
      expect(preview.level, app.questLevel.level);
      expect(await other.applyImport(preview), ImportStatus.success);
      expect(jsonEncode(other.questData!.toJson()), state);
      expect(
        jsonEncode(other.quest!.level.toJson()),
        jsonEncode(app.quest!.level.toJson()),
      );
      expect(other.consumeGains(), isNull);
      expect(other.exportAll(), app.exportAll());
      other.dispose();
    });

    test('section questState : import strict, démarrage tolérant', () async {
      await _ownerState(app);
      _profile(app);
      app.quest;
      final doc = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      final broken = Map<String, dynamic>.from(doc)
        ..['questState'] = {'version': 1, 'seed': 3, 'state': 'illisible'};
      expect(
        app.previewImport(jsonEncode(broken)).status,
        ImportStatus.invalid,
      );
      final negative = jsonDecode(jsonEncode(doc)) as Map<String, dynamic>;
      ((negative['questState'] as Map)['state'] as Map)['xp'] = [
        {
          'sequence': 0,
          'date': '2026-09-28',
          'source': 'effort',
          'amount': -5,
          'reasons': [],
        },
      ];
      expect(
        app.previewImport(jsonEncode(negative)).status,
        ImportStatus.invalid,
      );
      // Démarrage avec une section illisible : gardée telle quelle, le
      // moteur ne tourne pas et rien n'est écrit par-dessus.
      SharedPreferences.setMockInitialValues({
        'kalis_state_v3': jsonEncode(broken),
      });
      final started = AppStore()..storeClock = () => clock;
      await started.init();
      expect(started.questUnreadable, isTrue);
      expect(started.questLoadIssues, 1);
      expect(started.quest, isNull);
      final again = jsonDecode(started.exportAll()) as Map<String, dynamic>;
      expect(again['questState'], broken['questState']);
      started.dispose();
    });

    test('ancienne sauvegarde (lastLevel, objectif hebdo, titre) : importée, '
        'champs de l’ancien système ignorés', () async {
      final filled = filledBackup(app)
        ..['lastLevel'] = 42
        ..['settings'] = {
          ...AppSettings().toJson(),
          'weeklyGoal': 4,
          'title': 'Diesel',
        };
      expect(await app.importAll(jsonEncode(filled)), isTrue);
      final doc = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      expect(doc.containsKey('lastLevel'), isFalse);
      expect((doc['settings'] as Map).containsKey('weeklyGoal'), isFalse);
      expect((doc['settings'] as Map).containsKey('title'), isFalse);
      expect(app.questLevel.level, 1);
    });

    test('objectifs de G6 repris par le moteur ; échéance ajustée et '
        'suggestion ajoutée au profil', () async {
      await _ownerState(app);
      _profile(app);
      final goals = app.athleteProfile!.goals;
      expect(goals, isNotEmpty);
      final o = app.quest!;
      expect(
        o.goals.map((g) => g.goalId).toSet(),
        goals.map((g) => g.id).toSet(),
      );
      final id = goals.first.id;
      final date = goals.first.targetDate!.addDays(30);
      expect(app.adjustGoal(id, date: date), isTrue);
      expect(app.athleteProfile!.goals.first.targetDate, date);
      expect(app.athleteProfile!.goals.first.id, id);
      final suggested = kc.Goal(
        id: 'x',
        kind: kc.GoalKind.performance,
        origin: kc.GoalOrigin.suggested,
        createdOn: civilOf(clock),
        exerciseId: 'sw-traction-pronation',
        metric: kc.GoalMetric.maxReps,
        targetValue: 22,
        targetDate: civilOf(clock).addDays(56),
      );
      expect(app.addSuggestedGoal(suggested), isTrue);
      final added = app.athleteProfile!.goals.last;
      expect(added.origin, kc.GoalOrigin.suggested);
      expect(added.id, isNot('x'));
      expect(added.validate(), isEmpty);
      // Le moteur suit le nouvel objectif.
      clock = clock.add(const Duration(minutes: 1));
      expect(app.goalProgressOf(added.id), isNotNull);
    });

    test('quête de récupération déclarée faite : payée par le moteur', () async {
      await _ownerState(app);
      _profile(app);
      kc.Quest? claimable;
      for (var d = 0; d < 8 && claimable == null; d++) {
        clock = DateTime(2026, 9, 28 + d, 9);
        for (final q in app.quest!.state.quests) {
          if (app.questClaimable(q)) claimable = q;
        }
      }
      expect(claimable, isNotNull, reason: 'aucun jour de repos en 8 jours');
      final before = app.questLevel.totalXp;
      app.questClaim(claimable!.id);
      final done = app.quest!.state.quests.firstWhere(
        (q) => q.id == claimable!.id,
      );
      expect(done.status, kc.QuestStatus.completed);
      expect(app.questLevel.totalXp, before + claimable.rewardXp);
      expect(app.questClaimable(done), isFalse);
    });

    test('outils de test absents hors session de test', () async {
      await _ownerState(app);
      _profile(app);
      expect(app.devAddXp(1000), isNull);
      expect(app.devCompleteDailyQuests(), isNull);
      expect(app.questLevel.totalXp, 0);
    });
  });

  test('retrait de l’ancien système sans référence morte', () {
    for (final f in [
      'lib/progression.dart',
      'lib/game.dart',
      'lib/rewards.dart',
      'lib/levelup.dart',
      'lib/game_widgets.dart',
      'lib/stats_progression.dart',
      'lib/progression_screen.dart',
      'lib/goal_suggestions_g6.dart',
    ]) {
      expect(File(f).existsSync(), isFalse, reason: f);
    }
    final dead = RegExp(
      r"import '(?:\.\./)*(?:progression|game|rewards|levelup|game_widgets|"
      r"stats_progression|progression_screen|goal_suggestions_g6)\.dart'|"
      r'\b(?:GameState|RewardSummary|progressRanks|CharacterSheet|'
      r'StreakInfo|WeeklyGoal|provisionalGoalSuggestions)\b',
    );
    for (final dir in ['lib', 'test', 'integration_test']) {
      for (final f in Directory(dir).listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        if (f.path.endsWith('g12_progression_test.dart')) continue;
        expect(dead.hasMatch(f.readAsStringSync()), isFalse, reason: f.path);
      }
    }
  });

  group('écrans', () {
    final clock = DateTime(2026, 9, 28, 9);
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      store.storeClock = () => clock;
      await store.init();
      await _ownerState(store);
      _profile(store);
      _doDay(store, 12, 1);
      await store.finishSession(12, 1, title: 'S12 · J1');
      store.consumeGains();
    });
    tearDownAll(() => store.storeClock = DateTime.now);

    Future<void> open(
      WidgetTester tester,
      Widget screen, {
      required bool dark,
      double scale = 1,
      double width = 390,
    }) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
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
          home: screen,
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> scrollAll(WidgetTester tester) async {
      final lists = find.byType(Scrollable);
      if (lists.evaluate().isEmpty) return;
      for (var i = 0; i < 8; i++) {
        await tester.drag(lists.first, const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }

    for (final dark in [true, false]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('progression, quêtes, attributs, rangs, objectifs, '
            'Krédits, gains — thème ${dark ? 'sombre' : 'clair'}, texte '
            '$scale', (tester) async {
          final width = scale > 1 ? 320.0 : 390.0;
          await open(
            tester,
            const ProgressionScreen(),
            dark: dark,
            scale: scale,
            width: width,
          );
          expect(find.byKey(const ValueKey('progression-level')), findsOneWidget);
          await scrollAll(tester);
          for (final s in const <Widget>[
            QuestsScreen(),
            AttributesScreen(),
            RanksScreen(),
            StandardsScreen(),
            GoalsScreen(),
            KreditsScreen(),
            LedgerScreen(),
          ]) {
            await open(tester, s, dark: dark, scale: scale, width: width);
            expect(tester.takeException(), isNull, reason: '$s');
            await scrollAll(tester);
          }
        });
      }
    }

    testWidgets('Krédits : Koach dit de les garder ; historique des gains : '
        'la séance figure', (tester) async {
      await open(tester, const KreditsScreen(), dark: true);
      expect(find.text('Garde-les, ils serviront bientôt.'), findsOneWidget);
      await open(tester, const LedgerScreen(), dark: true);
      final effort = store.questData!.state.xp.firstWhere(
        (e) => e.source == kc.XpSource.effort,
      );
      expect(find.text(xpEntryText(effort)), findsWidgets);
    });

    testWidgets('attribut : détail (d’où vient la valeur, comment la faire '
        'monter)', (tester) async {
      await open(tester, const AttributesScreen(), dark: false);
      await tester.tap(find.byKey(const ValueKey('attribute-strength')));
      await tester.pumpAndSettle();
      expect(find.text('D’où vient la valeur'), findsOneWidget);
      expect(find.text('Comment la faire monter'), findsOneWidget);
      expect(
        find.text(attributeSource(kc.AthleteAttribute.strength)),
        findsOneWidget,
      );
    });

    testWidgets('Koach présente une nouveauté une seule fois', (tester) async {
      await open(tester, const QuestsScreen(), dark: true);
      final ok = find.byKey(const ValueKey('koach-intro-ok-quests'));
      if (ok.evaluate().isNotEmpty) {
        await tester.tap(ok);
        await tester.pumpAndSettle();
      }
      expect(store.questIntroSeen('quests'), isTrue);
      await open(tester, const QuestsScreen(), dark: true);
      expect(find.byKey(const ValueKey('koach-intro-quests')), findsNothing);
    });
  });
}
