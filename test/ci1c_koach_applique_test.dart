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

/// Restructuration de séance sur le bloc importé à partir de la semaine
/// [weekIndex] : l'emplacement [removed] est retiré de la journée
/// [dayIndex], l'emplacement [swapped] reçoit l'exercice [to].
kc.Proposal _restructure(
  AdaptPlace place, {
  required String removed,
  required String swapped,
  required String to,
}) {
  final b = place.block;
  final pass1 = b.pass1.copyWith(
    days: [
      for (final d in b.pass1.days)
        d.copyWith(
          slots: [
            for (final sl in d.slots)
              sl.slotId == swapped ? sl.copyWith(exerciseId: to) : sl,
          ],
        ),
    ],
  );
  final pass2 = b.pass2.copyWith(
    weeks: [
      for (final w in b.pass2.weeks)
        w.weekIndex < place.weekIndex
            ? w
            : w.copyWith(
                days: [
                  for (final d in w.days)
                    d.dayIndex != place.dayIndex
                        ? d
                        : d.copyWith(
                            items: [
                              for (final it in d.items)
                                if (it.slotId == removed)
                                  ...<kc.ExercisePrescription>[]
                                else if (it.slotId == swapped)
                                  it.copyWith(exerciseId: to)
                                else
                                  it,
                            ],
                          ),
                ],
              ),
    ],
  );
  return kc.Proposal(
    id: 'session:${place.dayIndex}:${place.blockId}@${place.weekIndex}',
    kind: kc.ProposalKind.sessionRestructure,
    scope: kc.ProposalScope.session,
    createdOn: kc.CivilDate(2026, 9, 28),
    confidence: .9,
    unlockLevel: kc.UnlockLevel.sessionRestructure,
    autoApplicable: true,
    block: kc.ProgramBlock(pass1: pass1, pass2: pass2),
    reasons: [
      const kc.Reason(
        code: 'adapt.time_short',
        params: {'minutesAvailable': 30, 'minutesPlanned': 60},
      ),
    ],
  );
}

/// Valide la première série de [e] (séance servie S[week]·J[j]).
void _validateFirstSet(AppStore app, int week, int j, Exercise e) {
  final log = app.exLog(week, j, e);
  app.adaptPrefill(week, j, e, log);
  if (log.sets[0].reps.isEmpty) log.sets[0].reps = '5';
  log.sets[0].flames = 7;
  expect(app.toggleSet(log, 0, app.logSpec(e)).ok, isTrue);
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
      // Programme affiché (MON PROGRAMME) : déjà la couche du bloc.
      final shown = app.program
          .week(week)
          .day(j)!
          .exercises
          .firstWhere((e) => e.slotId == item.slotId);
      expect(app.setCount(shown), item.sets + 1);
    });

    test('programme importé : échange et retrait acceptés montrés dans le '
        'programme affiché et servis, semaines suivantes comprises ; '
        'l’original reste en dessous ; annuler le rend', () async {
      await _ownerState(app);
      _saveProfile(app, kc.GuidanceMode.free);
      final place = app.adaptPlaceOf(12, 1)!;
      final items = place.day!.items;
      expect(items.length, greaterThanOrEqualTo(3));
      final removed = items[1];
      final swapped = items[2];
      final to = items
          .firstWhere(
            (i) =>
                i.exerciseId != swapped.exerciseId &&
                (i.secondsLow == null) == (swapped.secondsLow == null) &&
                i.loadBasis == swapped.loadBasis,
            orElse: () => items.firstWhere(
              (i) =>
                  i.exerciseId != swapped.exerciseId &&
                  (i.secondsLow == null) == (swapped.secondsLow == null),
            ),
          )
          .exerciseId;
      final original13 = [
        for (final e in app.program.week(13).day(1)!.exercises) e.id,
      ];
      app.evolutionReceive(place, [
        _restructure(
          place,
          removed: removed.slotId,
          swapped: swapped.slotId,
          to: to,
        ),
      ]);
      app.evolutionAccept(app.evolutionPending.single);
      for (final w in [12, 13]) {
        final d = app.program.week(w).day(1)!;
        expect(identical(d.original, d), isFalse, reason: 'S$w : couche');
        expect(
          _shownFor(app, w, 1, removed.slotId),
          isNull,
          reason: 'S$w : exercice retiré',
        );
        final sw = _shownFor(app, w, 1, swapped.slotId)!;
        expect(sw.catalogId, to);
        expect(sw.name, app.adaptExerciseName(to));
        expect(sw.why, contains('Koach'));
        // L'original reste intact en dessous.
        expect(
          d.original.exercises.any(
            (e) => app.adaptSlotOf(w, 1, e.id) == removed.slotId,
          ),
          isTrue,
        );
        // Séance servie : même chose.
        final a = app.adaptOpen(w, d)!;
        final served = app.adaptDay(w, d, a);
        expect(
          served.exercises.where(
            (e) => app.adaptSlotOf(w, 1, e.id) == removed.slotId,
          ),
          isEmpty,
        );
        final se = served.exercises.firstWhere(
          (e) => app.adaptSlotOf(w, 1, e.id) == swapped.slotId,
        );
        expect(se.catalogId, to);
        expect(se.name, app.adaptExerciseName(to));
        expect(se.id.contains('~'), isFalse);
      }
      // Semaine d'avant : intacte.
      expect(identical(app.program.week(11).day(1)!.original,
          app.program.week(11).day(1)), isTrue);
      // Annuler : programme d'origine.
      expect(app.evolutionUndo(app.planEvolution.entries.last), isTrue);
      expect(
        [for (final e in app.program.week(13).day(1)!.exercises) e.id],
        original13,
      );
      expect(app.program.week(13).day(1)!.source, isNull);
    });

    test('séance future ouverte à l’avance, puis ajustement accepté et '
        'bilan : rouverte à jour sans rien effacer ; le jour venu, '
        'nouvelle prescription', () async {
      await _ownerState(app);
      _saveProfile(app, kc.GuidanceMode.free);
      final place = app.adaptPlaceOf(12, 3);
      if (place == null) return; // pas de séance ce jour-là
      final item = _simpleItem(place);
      app.adaptOpen(12, app.program.week(12).day(3)!);
      expect(app.logs.containsKey('S12-J3'), isTrue);
      app.evolutionReceive(place, [
        _volume(place, place.weekIndex, place.dayIndex, item),
      ]);
      app.evolutionAccept(app.evolutionPending.single);
      final reopened = app.adaptOpen(12, app.program.week(12).day(3)!)!;
      expect(_servedItem(reopened, item.slotId)!.sets, item.sets + 1);
      // Bilan du jour donné, puis réouverture le même jour : bilan et
      // suite gardés, prescription à jour.
      final day3 = app.program.week(12).day(3)!;
      final answered = app.adaptAnswer(
        12,
        day3,
        const kc.HealthCheck(overall: 1, sleepQuality: 1, energy: 1),
      )!;
      final again = app.adaptOpen(12, day3)!;
      expect(again.check!.toJson(), answered.check!.toJson());
      expect(again.choice, answered.choice);
      // Le jour de la séance : nouvelle prescription (sans le bilan de
      // l'avant-veille), ajustement accepté compris.
      clock = DateTime(2026, 9, 30, 9);
      final later = app.adaptOpen(12, app.program.week(12).day(3)!)!;
      expect(later.date, '2026-09-30');
      expect(later.check, isNull);
      expect(_servedItem(later, item.slotId)!.sets, item.sets + 1);
    });

    test('séance commencée : séries validées gardées, ce qui reste à faire '
        'suit l’ajustement accepté', () async {
      await _ownerState(app);
      _saveProfile(app, kc.GuidanceMode.free);
      final day = app.program.week(12).day(1)!;
      final a = app.adaptOpen(12, day)!;
      final served = app.adaptDay(12, day, a);
      final first = served.exercises.firstWhere((e) => e.engine);
      _validateFirstSet(app, 12, 1, first);
      final firstSlot = app.adaptSlotOf(12, 1, first.id)!;
      final done = app.logs['S12-J1']!.ex[first.id]!.sets[0].toJson();
      final place = app.adaptPlaceOf(12, 1)!;
      final other = place.day!.items.firstWhere(
        (i) => i.slotId != firstSlot && i.setTargets == null && i.sets < 10,
      );
      app.evolutionReceive(place, [
        _volume(place, place.weekIndex, place.dayIndex, other),
      ]);
      app.evolutionAccept(app.evolutionPending.single);
      final b = app.adaptOpen(12, app.program.week(12).day(1)!)!;
      expect(_servedItem(b, other.slotId)!.sets, other.sets + 1);
      expect(
        jsonEncode(_servedItem(b, firstSlot)!.toJson()),
        jsonEncode(_servedItem(a, firstSlot)!.toJson()),
        reason: 'exercice commencé : prescription gardée',
      );
      expect(app.logs['S12-J1']!.ex[first.id]!.sets[0].toJson(), done);
    });

    test('consultation seule : aucune entrée à la fermeture ; bilan donné '
        'ou note : entrée gardée', () async {
      await _ownerState(app);
      _saveProfile(app, kc.GuidanceMode.free);
      final d2 = app.program.week(12).day(2);
      final d3 = app.program.week(12).day(3);
      final d1 = app.program.week(12).day(1)!;
      app.adaptOpen(12, d1);
      expect(app.isConsultation('S12-J1'), isTrue);
      app.forgetConsultation(12, 1);
      expect(app.logs.containsKey('S12-J1'), isFalse);
      app.adaptOpen(12, d1);
      app.adaptAnswer(12, d1, const kc.HealthCheck(overall: 4));
      app.forgetConsultation(12, 1);
      expect(app.logs.containsKey('S12-J1'), isTrue);
      for (final d in [d2, d3]) {
        if (d == null || d.exercises.isEmpty) continue;
        app.adaptOpen(12, d);
        app.exLog(12, d.j, d.exercises.first).note = 'Poignet raide';
        app.forgetConsultation(12, d.j);
        expect(app.logs.containsKey('S12-J${d.j}'), isTrue);
      }
    });

    test('sauvegarde de dev6.9.1 : séances consultées figées réparées, '
        'rien d’autre ne change', () async {
      await _ownerState(app);
      _saveProfile(app, kc.GuidanceMode.free);
      // État 6.9.1 : S12-J1 seulement consultée (figée), S12-J2 avec une
      // note, S12-J3 avec un bilan.
      final w = app.program.week(12);
      final days = [for (final d in w.days) if (d.exercises.isNotEmpty) d];
      app.adaptOpen(12, days[0]);
      for (final e in days[0].exercises) {
        app.exLog(12, days[0].j, e);
      }
      app.adaptOpen(12, days[1]);
      app.exLog(12, days[1].j, days[1].exercises.first).note = 'Note gardée';
      app.adaptOpen(12, days[2]);
      app.adaptAnswer(12, days[2], const kc.HealthCheck(overall: 2));
      final raw = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      for (final l in (raw['logs'] as Map).values) {
        ((l as Map)['adapt'] as Map?)?.remove('src');
      }
      final k0 = 'S12-J${days[0].j}';
      final k1 = 'S12-J${days[1].j}';
      final k2 = 'S12-J${days[2].j}';
      expect((raw['logs'] as Map).containsKey(k0), isTrue);
      final other = AppStore()..storeClock = () => clock;
      await other.init();
      expect(await other.importAll(jsonEncode(raw)), isTrue);
      expect(other.logs.containsKey(k0), isFalse, reason: 'consultation');
      expect(
        other.logs[k1]!.ex[days[1].exercises.first.id]!.note,
        'Note gardée',
      );
      expect(other.sessionAdaptOf(k2)!.check!.overall, 2);
      final doneBefore = [
        for (final e in app.logs.entries)
          if (e.value.done) '${e.key}:${jsonEncode(e.value.toJson())}',
      ];
      final doneAfter = [
        for (final e in other.logs.entries)
          if (e.value.done) '${e.key}:${jsonEncode(e.value.toJson())}',
      ];
      expect(doneAfter, doneBefore);
      expect(
        jsonEncode(other.planEvolution.toJson()),
        jsonEncode(app.planEvolution.toJson()),
      );
      await other.flush();
      other.dispose();
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

    testWidgets('réponse au bilan puis fermeture : entrée gardée, bilan '
        'relu à la réouverture', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      store.clearSession(12, 1);
      final week = store.program.week(12);
      Widget app() => MaterialApp(
        theme: buildTheme(false),
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: SessionScreen(week: week, day: week.day(1)!),
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('feel-4')));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      expect(store.logs.containsKey('S12-J1'), isTrue);
      expect(store.sessionAdapt(12, 1)!.check!.overall, 4);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(store.sessionAdapt(12, 1)!.check!.overall, 4);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
