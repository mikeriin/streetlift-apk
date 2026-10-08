// CI1c (dev6.9.2, pipeline CP, DECISIONS_CP.md C10) — un ajustement de
// Koach accepté change tout de suite le programme : la séance servie, la
// séance déjà ouverte, le programme affiché (MON PROGRAMME, accueil) et les
// séances suivantes ; pour le programme de 40 semaines du propriétaire
// (bloc importé), l'ajustement est une couche posée par-dessus l'original,
// annulable, sans régénération (C10.2). Une séance non commencée est
// recalculée à chaque ouverture ; une simple consultation ne crée aucune
// entrée d'historique.
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
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/session_screen.dart';
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

void _saveProfile(AppStore app, kc.GuidanceMode mode) {
  app.saveAthleteProfile(
    ProfileDraft.of(
      sampleAthleteProfile(on: civilOf(app.storeClock()), guidance: mode),
    )..consent = 'refused',
  );
}

/// Profils types du parcours v3 (`kalis_core`, CQ).
kc.AthleteProfile _street(String primary) {
  final raw =
      jsonDecode(
            File(
              'packages/kalis_core/test/fixtures/profiles_v3.json',
            ).readAsStringSync(),
          )
          as Map<String, Object?>;
  for (final p in raw['profiles']! as List) {
    final prof = kc.AthleteProfile.fromJson(
      ((p as Map)['profile'] as Map).cast<String, Object?>(),
    );
    if (prof.disciplines.primary.code == primary) return prof;
  }
  throw StateError('profil $primary absent');
}

/// Proposition de volume : une série de plus sur [item] (semaine
/// [weekIndex], journée [dayIndex] du bloc).
kc.Proposal _volume(
  AdaptPlace place,
  int weekIndex,
  int dayIndex,
  kc.ExercisePrescription item,
) => kc.Proposal(
  id: 'volume:${item.slotId}@$weekIndex',
  kind: kc.ProposalKind.volume,
  scope: kc.ProposalScope.exercise,
  createdOn: kc.CivilDate(2026, 9, 28),
  confidence: .74,
  unlockLevel: kc.UnlockLevel.volume,
  autoApplicable: true,
  exerciseId: item.exerciseId,
  diff: kc.PlanDiff(
    changes: [
      kc.PlanChange(
        kind: kc.ChangeKind.prescriptionChanged,
        dayIndex: dayIndex,
        weekIndex: weekIndex,
        slotId: item.slotId,
        fromPrescription: item,
        toPrescription: item.copyWith(sets: item.sets + 1),
        reasons: [
          const kc.Reason(code: 'adapt.volume_up', params: {'sets': 1}),
        ],
      ),
    ],
  ),
  reasons: [const kc.Reason(code: 'adapt.volume_up', params: {'sets': 1})],
);

/// Première prescription « simple » (sans cibles par série) de la journée.
kc.ExercisePrescription _simpleItem(AdaptPlace place) =>
    place.day!.items.firstWhere((i) => i.setTargets == null && i.sets < 10);

/// Exercice du programme affiché pour l'emplacement [slot].
Exercise? _shownFor(AppStore app, int week, int j, String slot) {
  for (final e in app.program.week(week).day(j)!.exercises) {
    if (app.adaptSlotOf(week, j, e.id) == slot) return e;
  }
  return null;
}

/// Prescription servie pour l'emplacement [slot].
kc.ExercisePrescription? _servedItem(SessionAdapt a, String slot) {
  for (final it in a.active.items) {
    if (it.slotId == slot) return it;
  }
  return null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ajustement de Koach accepté', () {
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

    test('propositions de la revue sur le bloc importé (relevé)', () async {
      await _ownerState(app);
      for (final mode in [kc.GuidanceMode.free, kc.GuidanceMode.assisted]) {
        _saveProfile(app, mode);
        app.evolutionRefresh(force: true);
        final r = app.lastEvolutionReview;
        // ignore: avoid_print
        print(
          'RELEVE ${mode.code} : bloc ${r?.place.blockId} '
          'importé=${r?.place.imported} semaine=${r?.week} '
          'déblocage=${r?.review.summary.unlockLevel.code} '
          'propositions=${[for (final p in r?.review.proposals ?? const <kc.Proposal>[]) '${p.id}(${p.kind.code}, diff=${p.diff?.changes.length}, bloc=${p.block != null})']}',
        );
        for (final l in r?.review.log ?? const <kc.EngineLogEntry>[]) {
          if (l.event == 'proposal_withheld') {
            // ignore: avoid_print
            print('RELEVE retenue : ${l.data}');
          }
        }
        for (final e in app.planEvolution.entries) {
          // ignore: avoid_print
          print('RELEVE entrée : ${e.id} ${e.status} ${e.blockId}');
        }
      }
    });

    test('programme importé : accepter une proposition change la séance '
        'déjà ouverte, le programme affiché ; refuser ne change rien ; '
        'annuler revient à l’original', () async {
      await _ownerState(app);
      _saveProfile(app, kc.GuidanceMode.free);
      final day = app.program.week(12).day(1)!;
      final place = app.adaptPlaceOf(12, 1)!;
      expect(place.imported, isTrue);
      final item = _simpleItem(place);
      final shownBefore = _shownFor(app, 12, 1, item.slotId)!;
      final setsBefore = app.setCount(shownBefore);
      // Séance ouverte pour voir ce qui est prévu.
      final opened = app.adaptOpen(12, day)!;
      expect(_servedItem(opened, item.slotId)!.sets, item.sets);
      // Proposition refusée : rien ne change.
      final p = _volume(place, place.weekIndex, place.dayIndex, item);
      app.evolutionReceive(place, [p]);
      app.evolutionRefuse(app.evolutionPending.single);
      expect(
        _servedItem(app.adaptOpen(12, day)!, item.slotId)!.sets,
        item.sets,
      );
      expect(app.setCount(_shownFor(app, 12, 1, item.slotId)!), setsBefore);
      // Proposition acceptée (autre identifiant : la refusée ne revient
      // pas avant son délai).
      final q = kc.Proposal.fromJson({
        ...p.toJson(),
        'id': 'volume:bis:${item.slotId}@${place.weekIndex}',
      });
      app.evolutionReceive(place, [q]);
      app.evolutionAccept(app.evolutionPending.single);
      final reopened = app.adaptOpen(12, day)!;
      expect(
        _servedItem(reopened, item.slotId)!.sets,
        item.sets + 1,
        reason: 'séance déjà ouverte recalculée après l’acceptation',
      );
      final served = app.adaptDay(12, day, reopened);
      final e = served.exercises.firstWhere(
        (x) => app.adaptSlotOf(12, 1, x.id) == item.slotId,
      );
      expect(app.setCount(e), item.sets + 1);
      expect(
        app.setCount(_shownFor(app, 12, 1, item.slotId)!),
        item.sets + 1,
        reason: 'programme affiché (MON PROGRAMME, accueil)',
      );
      // Annuler : retour à l'original.
      final entry = app.planEvolution.entries.last;
      expect(app.evolutionUndo(entry), isTrue);
      expect(
        _servedItem(app.adaptOpen(12, day)!, item.slotId)!.sets,
        item.sets,
      );
      expect(app.setCount(_shownFor(app, 12, 1, item.slotId)!), setsBefore);
    });

    test('programme street généré : la séance déjà ouverte suit la '
        'proposition acceptée', () async {
      clock = DateTime(2026, 10, 1, 9);
      final r = app.saveAthleteProfile(
        ProfileDraft.of(
          _street('streetlifting').copyWith(
            guidanceMode: kc.GuidanceMode.free,
          ),
        )..consent = 'refused',
      );
      expect(r, isNotNull);
      final c = PlanStore(app).newPlanCreation(journal: false)!;
      c.start();
      c.createPass2();
      PlanStore(app).applyPlanCreation(c);
      int? week, j;
      for (var w = 1; w <= 2 && week == null; w++) {
        for (var d = 1; d <= 7; d++) {
          final pl = app.adaptPlaceOf(w, d);
          if (pl?.day?.items.any((i) => i.setTargets == null && i.sets < 10) ??
              false) {
            week = w;
            j = d;
            break;
          }
        }
      }
      expect(week, isNotNull);
      final day = app.program.week(week!).day(j!)!;
      final place = app.adaptPlaceOf(week, j)!;
      final item = _simpleItem(place);
      app.adaptOpen(week, day);
      app.evolutionReceive(place, [
        _volume(place, place.weekIndex, place.dayIndex, item),
      ]);
      app.evolutionAccept(app.evolutionPending.single);
      expect(
        _servedItem(app.adaptOpen(week, app.program.week(week).day(j)!)!,
                item.slotId)
            ?.sets,
        item.sets + 1,
      );
    });
  });

  group('séance consultée', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      store.storeClock = () => DateTime(2026, 9, 28, 9);
      await store.init();
      await _ownerState(store);
      _saveProfile(store, kc.GuidanceMode.free);
    });

    testWidgets('ouvrir puis fermer une séance future ne crée aucune '
        'entrée d’historique', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final week = store.program.week(12);
      final day = week.day(3)!;
      expect(store.logs.containsKey('S12-J3'), isFalse);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(true),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: SessionScreen(week: week, day: day),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      expect(store.logs.containsKey('S12-J3'), isFalse);
    });
  });
}
