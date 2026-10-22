// RV2 (dev7.6.0, lot RV2, zone k) — Koach 1.0 dans l'application :
// corrections des constats de la revue RV1.
//
// - K1 : ligne d'endurance (fiche `cardio` ou `wod`) d'une séance servie
//   versée en une seule `serie` (`demand`, `doneShare`, `dose`,
//   `fatigueSets`) une fois finie ou à la fin de la séance, jamais tour par
//   tour ; corrigée à la fin de la séance si un tour change ;
// - K3 : série validée pendant le rattrapage calculé dans un isolat :
//   rejouée sur l'instance adoptée, rangs `versed` justes, aucune perte,
//   aucun doublon ;
// - K4 : panne du moteur après des versements : journal remis tel qu'avant,
//   puis séries versées une seule fois au passage suivant ;
// - K5 : jour 0 de Koach = jour du départ (départ un mercredi : semaine de
//   Koach = semaine du programme, séances manquées au bon jour) ; départ
//   un lundi : rien ne change ; instantané d'avant RV2 : cadre gardé.
//
// Données synthétiques seulement (C17.33.2) ; horloge injectée ; stockage
// simulé.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/koach1/koach1_widgets.dart';
import 'package:streetlift_tracker/koach1/koach_journal.dart'
    show koachJour, koachLundiDe;
import 'package:streetlift_tracker/koach1/koach_moteur.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/store.dart';

import 'kb2c1_fixtures.dart';

/// Sonde imprimée (relevé de la livraison).
void _sonde(String nom, Object? v) {
  // ignore: avoid_print
  print('RV2K|$nom|${jsonEncode(v)}');
}

/// Événements de la séance en cours au journal de Koach (depuis le dernier
/// `seance_debut`).
List<Map<String, Object?>> _seance(AppStore app) {
  final j = app.koachEngine.journal;
  final i = j.lastIndexWhere((x) => x['type'] == 'seance_debut');
  return i < 0 ? const [] : j.sublist(i);
}

/// Séries de la séance en cours de l'emplacement [slot] (et du rang
/// [index] s'il est donné).
List<Map<String, Object?>> _series(AppStore app, String slot, [int? index]) => [
  for (final x in _seance(app))
    if (x['type'] == 'serie' &&
        (x['serie'] as Map)['slotId'] == slot &&
        (index == null || (x['serie'] as Map)['setIndex'] == index))
      (x['serie'] as Map).cast<String, Object?>(),
];

/// Exercices servis de la journée.
List<Exercise> _served(AppStore app, int week, int j) {
  final base = app.program.week(week).day(j)!;
  final a = app.sessionAdapt(week, j)!;
  return app.adaptDay(week, base, a).exercises;
}

/// Série [i] de [e] notée puis validée, Koach prévenu.
void _validate(
  AppStore app,
  int week,
  int j,
  Exercise e,
  int i,
  String reps, [
  int flames = 7,
]) {
  final base = app.program.week(week).day(j)!;
  final log = app.exLog(week, j, e);
  app.adaptPrefill(week, j, e, log);
  log.sets[i].reps = reps;
  log.sets[i].flames = flames;
  expect(app.toggleSet(log, i, app.logSpec(e)).ok, isTrue);
  app.koachAfterSet(week, base, e, i);
}

/// Séance S[week]·J[j] commencée par Koach.
Future<DayPlan> _start(AppStore app, int week, int j) async {
  final base = app.program.week(week).day(j)!;
  expect(app.adaptOpen(week, base)?.koach?['state'], 'preview');
  expect(await app.koachStart(week, base), isTrue);
  return base;
}

/// Profil d'athlète enregistré (comme `importPr2Nouveau`).
void _profil(AppStore app) {
  app.saveAthleteProfile(
    ProfileDraft.of(
      sampleAthleteProfile(
        on: civilOf(app.storeClock()),
        guidance: kc.GuidanceMode.assisted,
      ),
    )..consent = 'refused',
  );
}

/// Sauvegarde exportée, modifiée par [edit], réimportée.
Future<void> _reimport(
  AppStore app,
  void Function(Map<String, dynamic> b) edit,
) async {
  final b = jsonDecode(app.exportAll()) as Map<String, dynamic>;
  edit(b);
  expect(await app.importAll(jsonEncode(b)), isTrue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Koach (programme PR2 synthétique, départ un lundi)', () {
    late AppStore app;
    var clock = DateTime(2026, 10, 19, 7);

    setUp(() async {
      KoachCalcul.isolat = false;
      debugKoachBasculeAutorisee = true;
      debugResetKoachTakeoverWait();
      clock = DateTime(2026, 10, 19, 7);
      SharedPreferences.setMockInitialValues({});
      app = AppStore()..storeClock = () => clock;
      await app.init();
      await importPr2Nouveau(app, firstWeek: 12);
      app.koachNoteInstall();
      await app.koachRefresh();
      expect(app.koachEngine.fromWeek, 15);
    });
    tearDown(() async {
      debugKoachBasculeAutorisee = false;
      debugKoachPanne = null;
      KoachCalcul.isolat = false;
      KoachCalcul.debugAvantAdoption = null;
      await app.flush();
      app.dispose();
    });

    test('K1 : ligne d’intervalles servie : une seule série d’endurance '
        '(demande, part faite, dose), versée la ligne finie, jamais tour '
        'par tour ; un tour corrigé remplace la série à la fin', () async {
      clock = DateTime(2026, 10, 21, 7); // S15·J3
      await app.koachRefresh();
      final base = await _start(app, 15, 3);
      final e = _served(
        app,
        15,
        3,
      ).firstWhere((x) => x.name.toLowerCase().contains('air bike'));
      final slot = e.slotId ?? app.adaptSlotOf(15, 3, e.id)!;
      final tours = app.exLog(15, 3, e).sets.length;
      expect(tours, greaterThan(1));
      // Autre exercice servi : sa cible demandée verse ce qui est fait.
      final e2 = _served(app, 15, 3).firstWhere(
        (x) => x.engine && x.slotId != null && x.slotId != slot,
      );
      for (var i = 0; i < tours - 1; i++) {
        _validate(app, 15, 3, e, i, '30');
      }
      app.koachEnsureTarget(15, base, e2, 0);
      // Ligne pas finie : rien versé (avant : un tour = une série).
      expect(_series(app, slot), isEmpty);
      _validate(app, 15, 3, e, tours - 1, '30');
      _validate(app, 15, 3, e2, 0, '3', 8);
      final une = _series(app, slot);
      expect(une, hasLength(1));
      final s = une.single;
      for (final k in ['demand', 'doneShare', 'dose', 'fatigueSets']) {
        expect(s[k], isA<num>(), reason: '$k ${jsonEncode(s)}');
      }
      expect(s['setIndex'], 0);
      final dose = (s['dose'] as num).toDouble();
      expect(dose, greaterThan(0));
      // Dernier tour corrigé (20 s au lieu de 30 s) puis fin de séance : la
      // série de la ligne est remplacée, jamais doublée.
      app.exLog(15, 3, e).sets[tours - 1].reps = '20';
      app.markSessionDone(15, 3, true);
      await app.koachRefresh();
      expect(app.koachRuntimeError, isNull);
      final apres = _series(app, slot);
      expect(apres, hasLength(1));
      final fait = 30.0 * (tours - 1) + 20;
      expect(
        (apres.single['dose'] as num).toDouble(),
        closeTo(dose * fait / (30.0 * tours), 1e-9),
      );
      final fin = _seance(app).lastWhere((x) => x['type'] == 'seance_fin');
      final sets = ((fin['seance'] as Map)['sets'] as List)
          .where((x) => (x as Map)['slotId'] == slot)
          .toList();
      expect(sets, hasLength(1));
      expect(app.koachEngine.versed, contains(app.sessionKey(15, 3)));
      _sonde('k1', {'tours': tours, 'serie': apres.single});
    });

    test('K1 : ligne d’endurance pas finie à la fin de la séance : versée '
        'une fois, à la fin', () async {
      clock = DateTime(2026, 10, 21, 7);
      await app.koachRefresh();
      await _start(app, 15, 3);
      final e = _served(
        app,
        15,
        3,
      ).firstWhere((x) => x.name.toLowerCase().contains('air bike'));
      final slot = e.slotId ?? app.adaptSlotOf(15, 3, e.id)!;
      for (var i = 0; i < 3; i++) {
        _validate(app, 15, 3, e, i, '30');
      }
      expect(_series(app, slot), isEmpty);
      app.markSessionDone(15, 3, true);
      await app.koachRefresh();
      final s = _series(app, slot);
      expect(s, hasLength(1));
      expect(s.single['doneShare'], isA<num>());
      expect(s.single['demand'], isA<num>());
    });

    test('K3 : série validée pendant le rattrapage (isolat) : rejouée sur '
        'l’instance adoptée, rangs justes, ni perte ni doublon', () async {
      clock = DateTime(2026, 10, 20, 7); // S15·J2
      await app.koachRefresh();
      await _start(app, 15, 2);
      final e = _served(app, 15, 2).firstWhere((x) => x.engine);
      final slot = e.slotId ?? app.adaptSlotOf(15, 2, e.id)!;
      _validate(app, 15, 2, e, 0, '5', 8);
      expect(_series(app, slot, 0), hasLength(1));
      // Lundi suivant : rattrapage (séances manquées, fin de semaine) dans
      // un isolat ; la série 2 est validée pendant le calcul.
      clock = DateTime(2026, 10, 26, 8);
      KoachCalcul.isolat = true;
      var pendant = false;
      KoachCalcul.debugAvantAdoption = () async {
        KoachCalcul.debugAvantAdoption = null;
        _validate(app, 15, 2, e, 1, '5', 8);
        pendant = true;
      };
      await app.koachRefresh();
      expect(pendant, isTrue);
      expect(app.koachRuntimeError, isNull);
      expect(app.koachLive, isNotNull);
      expect(app.koachEngine.closed, 15);
      final journal = app.koachEngine.journal;
      expect(
        journal.where((x) => x['type'] == 'semaine_fin' && x['semaine'] == 14),
        hasLength(1),
      );
      expect(jsonEncode(app.koachLive!.journal), jsonEncode(journal));
      // Séries 1 et 2 : une fois chacune après le début de la séance.
      final d = journal.lastIndexWhere((x) => x['type'] == 'seance_debut');
      int n(int index) => journal
          .skip(d)
          .where(
            (x) =>
                x['type'] == 'serie' &&
                (x['serie'] as Map)['slotId'] == slot &&
                (x['serie'] as Map)['setIndex'] == index,
          )
          .length;
      expect(n(0), 1);
      expect(n(1), 1);
      // Rangs gardés par la séance : chacun pointe sa série.
      final versed = (app.sessionAdapt(15, 2)!.koach!['versed'] as List)
          .whereType<List>()
          .where((v) => v.length >= 4)
          .toList();
      expect(versed.length, greaterThanOrEqualTo(2));
      for (final v in versed) {
        final ev = journal[v[3] as int];
        expect(ev['type'], 'serie', reason: '$v');
        expect((ev['serie'] as Map)['slotId'], v[0], reason: '$v');
        expect((ev['serie'] as Map)['setIndex'], v[1], reason: '$v');
      }
      // Fin de séance : corrections lues aux bons rangs, rien retiré.
      KoachCalcul.isolat = false;
      app.markSessionDone(15, 2, true);
      await app.koachRefresh();
      expect(app.koachEngine.versed, contains(app.sessionKey(15, 2)));
      final j2 = app.koachEngine.journal;
      expect(j2.skip(d).where((x) => x['type'] == 'seance_fin'), hasLength(1));
      expect(
        j2
            .skip(d)
            .where(
              (x) =>
                  x['type'] == 'serie' && (x['serie'] as Map)['slotId'] == slot,
            )
            .length,
        2,
      );
      _sonde('k3', {'journal': j2.length, 'versed': versed});
    });

    test('K4 : panne à la demande de la série suivante : journal remis tel '
        'qu’avant, série versée une seule fois au passage suivant', () async {
      final base = await _start(app, 15, 1);
      final e = _served(app, 15, 1).firstWhere((x) => x.engine);
      final slot = e.slotId ?? app.adaptSlotOf(15, 1, e.id)!;
      final avant = jsonEncode(app.koachEngine.journal);
      debugKoachPanne = (etape) {
        if (etape == 'plan_serie') throw StateError('panne simulée');
      };
      _validate(app, 15, 1, e, 0, '5', 8);
      expect(jsonEncode(app.koachEngine.journal), avant);
      expect(app.koachLive, isNull);
      debugKoachPanne = null;
      await app.koachRefresh();
      expect(app.koachLive, isNotNull);
      app.koachEnsureTarget(15, base, e, 1);
      expect(_series(app, slot, 0), hasLength(1));
      _validate(app, 15, 1, e, 1, '5', 8);
      expect(_series(app, slot, 0), hasLength(1));
      expect(_series(app, slot, 1), hasLength(1));
    });

    test('K4 : panne à la fin de la séance : journal remis tel qu’avant, '
        'séance fermée une seule fois au passage suivant', () async {
      await _start(app, 15, 1);
      final e = _served(app, 15, 1).firstWhere((x) => x.engine);
      final slot = e.slotId ?? app.adaptSlotOf(15, 1, e.id)!;
      _validate(app, 15, 1, e, 0, '5', 8);
      // Série notée corrigée après versement (correction en place).
      app.exLog(15, 1, e).sets[0].flames = 9;
      final avant = jsonEncode(app.koachEngine.journal);
      debugKoachPanne = (etape) {
        if (etape == 'seance_fin') throw StateError('panne simulée');
      };
      app.markSessionDone(15, 1, true);
      expect(jsonEncode(app.koachEngine.journal), avant);
      expect(app.koachLive, isNull);
      expect(app.koachEngine.versed, isNot(contains(app.sessionKey(15, 1))));
      expect(app.sessionAdapt(15, 1)!.koach!['state'], 'open');
      debugKoachPanne = null;
      await app.koachRefresh();
      expect(app.koachRuntimeError, isNull);
      expect(app.koachEngine.versed, contains(app.sessionKey(15, 1)));
      final j = app.koachEngine.journal;
      final d = j.lastIndexWhere((x) => x['type'] == 'seance_debut');
      expect(j.skip(d).where((x) => x['type'] == 'seance_fin'), hasLength(1));
      final s0 = [
        for (final x in j.skip(d))
          if (x['type'] == 'serie' &&
              (x['serie'] as Map)['slotId'] == slot &&
              (x['serie'] as Map)['setIndex'] == 0)
            x['serie'] as Map,
      ];
      expect(s0, hasLength(1));
      expect(s0.single['flames'], 9);
    });

    test('K5 : départ un lundi : jour 0 inchangé (lundi = jour du départ), '
        'instantané et journal relus à l’identique', () async {
      final depart = civilOf(app.program.start!);
      expect(depart.weekday, 1);
      expect(app.koachLundi!.iso, depart.iso);
      expect(app.koachLundi!.iso, koachLundiDe(depart).iso);
      expect(app.koachEngine.snap!.lundi, '2026-07-13');
      for (var j = 1; j <= 7; j++) {
        expect(
          app.koachWeekOf(civilOf(app.program.dateFor(15, j))),
          15,
          reason: 'J$j',
        );
      }
      final snap = jsonEncode(app.koachEngine.snap!.toJson());
      final journal = jsonEncode(app.koachEngine.journal);
      await _reimport(app, (_) {});
      await app.koachRefresh();
      expect(jsonEncode(app.koachEngine.snap!.toJson()), snap);
      expect(jsonEncode(app.koachEngine.journal), journal);
    });
  });

  group('Koach (programme PR2 synthétique, départ un mercredi)', () {
    late AppStore app;
    var clock = DateTime(2026, 10, 19, 7);

    setUp(() async {
      KoachCalcul.isolat = false;
      debugKoachBasculeAutorisee = true;
      debugResetKoachTakeoverWait();
      clock = DateTime(2026, 10, 19, 7);
      SharedPreferences.setMockInitialValues({});
      app = AppStore()..storeClock = () => clock;
      await app.init();
      await importPr2Nouveau(app, firstWeek: 12);
      // Même programme, départ le mercredi 15/07/2026 (S1·J1).
      await _reimport(app, (b) {
        b['programStart'] = {
          'status': 'set',
          'date': '2026-07-15',
          'origin': 'migration',
        };
      });
      _profil(app);
      expect(civilOf(app.program.start!).iso, '2026-07-15');
    });
    tearDown(() async {
      debugKoachBasculeAutorisee = false;
      await app.flush();
      app.dispose();
    });

    Future<void> priseDeMain() async {
      clock = DateTime(2026, 10, 21, 7); // mercredi, S15·J1
      app.koachNoteInstall();
      await app.koachRefresh();
      expect(app.koachEngine.fromWeek, 15, reason: app.koachEngine.blocked);
    }

    test('K5 : jour 0 = jour du départ : semaine de Koach = semaine du '
        'programme chaque jour de S1, S2 et S15 ; séances manquées au bon '
        'jour', () async {
      expect(app.koachLundi!.iso, '2026-07-15');
      for (final w in [1, 2, 15]) {
        for (var j = 1; j <= 7; j++) {
          final d = civilOf(app.program.dateFor(w, j));
          expect(app.koachWeekOf(d), w, reason: 'S$w·J$j ${d.iso}');
        }
      }
      await priseDeMain();
      expect(app.koachEngine.snap!.lundi, '2026-07-15');
      // Mercredi suivant (S16·J1) : la semaine S15 se ferme.
      clock = DateTime(2026, 10, 28, 8);
      await app.koachRefresh();
      expect(app.koachRuntimeError, isNull);
      expect(app.koachWeekOf(civilOf(clock)), 16);
      final depart = civilOf(app.program.start!);
      final attendus = <int>{
        for (final d in app.program.week(15).days)
          if (d.exercises.isNotEmpty)
            koachJour(depart, civilOf(app.program.dateFor(15, d.j))),
      };
      final manquees = [
        for (final x in app.koachEngine.journal)
          if (x['type'] == 'seance_manquee' && x['semaine'] == 14) x,
      ];
      expect({for (final x in manquees) x['jour']}, attendus);
      for (final x in manquees) {
        expect((x['jour'] as int) ~/ 7, 14, reason: '$x');
      }
      final fin = app.koachEngine.journal.lastWhere(
        (x) => x['type'] == 'semaine_fin' && x['semaine'] == 14,
      );
      expect(fin['jour'], 105);
      _sonde('k5', {
        'manquees': [for (final x in manquees) x['jour']],
      });
    });

    test('K5 : instantané pris avant RV2 au lundi de la semaine du départ : '
        'cadre gardé, journal jamais réécrit', () async {
      await priseDeMain();
      await _reimport(app, (b) {
        ((b['koachEngine'] as Map)['snap'] as Map)['lundi'] = '2026-07-13';
      });
      expect(app.koachEngine.snap!.lundi, '2026-07-13');
      expect(app.koachLundi!.iso, '2026-07-13');
      final journal = jsonEncode(app.koachEngine.journal);
      await app.koachRefresh();
      expect(app.koachRuntimeError, isNull);
      expect(app.koachEngine.snap!.lundi, '2026-07-13');
      expect(jsonEncode(app.koachEngine.journal), journal);
    });
  });
}
