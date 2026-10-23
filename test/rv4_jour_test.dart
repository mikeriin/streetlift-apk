// RV4 (dev7.7.2, pipeline CP, DECISIONS_CP.md C17.51.5, C17.52.3-4) —
// changements du jour et bilan du jour selon le mode du profil :
//
// - « Remplacer pour aujourd'hui » : HSPU au mur à la place du dip lesté
//   dans l'E2MOM de la J5 (groupe, format, chrono et séries gardés ; tenue
//   ou répétitions selon l'exercice ; Koach reçoit l'exercice réel) ;
//   exercice personnel ; Koach actif et arrêté ; programme écrit jamais
//   modifié ;
// - « Retirer pour aujourd'hui » : avec et sans groupe ; Koach sert la
//   séance sans la ligne ; remise ;
// - export / import à l'identique ;
// - bilan du jour sous Koach : mode libre (écrit servi, « Accepter » /
//   « Garder l'écrit »), mode assisté (appliqué, « Annuler ») ; choix versé
//   au moteur ; bilan bas et haut.
//
// Données synthétiques seulement (C17.33.2) ; horloge injectée ; stockage
// simulé ; calculs du moteur sur place.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/koach1/koach1_widgets.dart'
    show debugResetKoachTakeoverWait;
import 'package:streetlift_tracker/koach1/koach_moteur.dart';
import 'package:streetlift_tracker/models.dart' show DayPlan, Exercise;
import 'package:streetlift_tracker/session_replace_screen.dart';
import 'package:streetlift_tracker/store.dart';

import 'kb2c1_fixtures.dart';

const _hspu = 'cd-hspu-mur-dos';
const _handstand = 'cs-handstand-dos-au-mur';

void _sonde(String nom, Object? v) {
  // ignore: avoid_print
  print('RV4|$nom|${jsonEncode(v)}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('fonctions pures', () {
    test('clé de la ligne écrite', () {
      expect(dayChangeKey('NA-S15J5-01'), 'NA-S15J5-01');
      expect(dayChangeKey('NA-S15J5-01~$_hspu'), 'NA-S15J5-01');
      expect(dayChangeKey('k15.5.j5-a#t'), 'k15.5.j5-a');
      expect(dayChangeKey('k15.5.j5-a#t~x'), 'k15.5.j5-a');
      expect(
        dayCustomId('Pompes pike surélevées'),
        'perso-pompes-pike-surelevees',
      );
    });

    test('séries dans l’unité du remplaçant', () {
      expect(daySetsInUnit('6×2 · E2MOM', seconds: true), '6×30 s · E2MOM');
      expect(
        daySetsInUnit('6×2 · E2MOM', seconds: true, value: 20),
        '6×20 s · E2MOM',
      );
      expect(daySetsInUnit('3×30 s', seconds: false), '3×8');
      expect(daySetsInUnit('3 × 20-30 s', seconds: false, value: 5), '3 × 5');
      expect(daySetsInUnit('2 tours × 5 paliers', seconds: true), isNull);
    });

    test('lignes que le bilan change, textes', () {
      final l = koachBilanLignes(
        [
          {'slotId': 'a', 'exerciseId': 'x'},
          {'slotId': 'b', 'exerciseId': 'y'},
          {'slotId': 'c', 'exerciseId': 'z'},
        ],
        [
          {'slotId': 'a', 'sets': 4, 'startLoadKg': 60.0},
          {'slotId': 'b', 'sets': 3},
          {'slotId': 'c', 'sets': 2},
        ],
        [
          {'slotId': 'a', 'sets': 3, 'startLoadKg': 55.0},
          {'slotId': 'b', 'sets': 3},
        ],
      );
      expect(l.keys, ['a', 'c']);
      expect((l['c']! as Map)['autre'], {'retire': true});
      KoachBilan b({bool forme = false, String? choix, bool assiste = false}) =>
          (
            forme: forme,
            choix: choix,
            assiste: assiste,
            modifiable: true,
            lignes: {'a': l['a']! as Map},
          );
      expect(
        koachTexteBilan(b()),
        startsWith(
          'Avec ton bilan du jour, Koach '
          'te propose d’ajuster un exercice',
        ),
      );
      expect(
        koachTexteBilan(b(forme: true, assiste: true)),
        startsWith('Ton bilan du jour : Koach ajuste un exercice'),
      );
      expect(koachTexteBilan(b(choix: 'ecrit')), startsWith('Écrit gardé'));
      expect(
        koachTexteBilan(b(choix: 'ecrit', assiste: true)),
        startsWith('Annulé'),
      );
      expect(koachTexteBilan(b(choix: 'applique')), startsWith('Accepté'));
    });
  });

  group('programme PR2 synthétique (Koach)', () {
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
      await app.flush();
      app.dispose();
    });

    /// Jour J[j] de S15 (lundi 19/10 = J1), séance ouverte en aperçu.
    Future<DayPlan> jour(int j) async {
      clock = DateTime(2026, 10, 18 + j, 7);
      await app.koachRefresh();
      final base = app.program.week(15).day(j)!;
      expect(app.adaptOpen(15, base)?.koach?['state'], 'preview');
      return base;
    }

    /// Journée affichée de S15·J[j] (séance de Koach, changements du jour).
    DayPlan shown(int j) {
      final base = app.program.week(15).day(j)!;
      final a = app.sessionAdapt(15, j);
      return a == null
          ? app.withDayChanges(15, base)
          : app.adaptDay(15, base, a);
    }

    Exercise ex(int j, String start) => shown(
      j,
    ).exercises.firstWhere((e) => e.name.toUpperCase().startsWith(start));

    /// Séries pré-remplies validées (5 reps, 8 flammes), séance finie.
    void finir(int j) {
      final base = app.program.week(15).day(j)!;
      for (final e in shown(j).exercises) {
        final log = app.exLog(15, j, e);
        for (var i = 0; i < log.sets.length; i++) {
          if (e.engine) {
            app.koachEnsureTarget(15, base, e, i);
            app.adaptPrefill(15, j, e, log);
          }
          final s = log.sets[i];
          if (s.reps.isEmpty) s.reps = '5';
          s.flames = 8;
          if (!app.toggleSet(log, i, app.logSpec(e)).ok) {
            s.reps = '5';
            app.toggleSet(log, i, app.logSpec(e));
          }
          if (e.engine) app.koachAfterSet(15, base, e, i);
        }
      }
      app.markSessionDone(15, j, true);
    }

    Set<String> exercicesVerses() => {
      for (final ev in app.koachEngine.journal)
        if (ev['type'] == 'serie') '${(ev['serie'] as Map)['exerciseId']}',
    };

    test(
      'HSPU au mur à la place du dip lesté dans l’E2MOM de la J5 : '
      'groupe, chrono et séries gardés ; Koach reçoit l’exercice réel',
      () async {
        app.setGuidanceMode('free');
        final base = await jour(5);
        final dip = ex(5, 'DIP LESTÉ');
        final key = dayChangeKey(dip.id);
        final groupe = app.exerciseGroupOf(15, 5, dip);
        final pages = app.groups(shown(5), week: 15);
        final page = pages.firstWhere((g) => g.any((e) => e.id == dip.id));
        _sonde('avant', {
          'dip': dip.id,
          'series': app.setsLabel(dip),
          'groupe': groupe?.toJson(),
          'page': [for (final e in page) e.name],
          'propositions': app.dayReplaceProposals(dip),
        });
        expect(app.dayCanChange(15, 5, dip), isTrue);
        app.dayReplace(15, shown(5), dip, to: _hspu, name: 'HSPU');
        final h = ex(5, 'HSPU AU MUR');
        expect(h.id, '$key~$_hspu');
        expect(h.catalogId, _hspu);
        expect(h.engine, isFalse);
        expect(h.why, contains('Remplace « DIP LESTÉ » aujourd’hui'));
        // Même emplacement : séries, format au départ chronométré, groupe.
        expect(app.setsLabel(h), app.setsLabel(dip));
        expect(app.setCount(h), app.setCount(dip));
        expect(app.logSpec(h).every, app.logSpec(dip).every);
        expect(app.exerciseGroupOf(15, 5, h)?.toJson(), groupe?.toJson());
        final page2 = app
            .groups(shown(5), week: 15)
            .firstWhere((g) => g.any((e) => e.id == h.id));
        expect(page2.length, page.length);
        // Répétitions au poids du corps : pas de colonne de charge.
        expect(app.showKgFor(h, app.exLog(15, 5, h)), isFalse);
        // Programme écrit inchangé.
        expect(
          app.program.week(15).day(5)!.exercises.map((e) => e.name),
          isNot(contains(startsWith('HSPU'))),
        );
        // Journal du moteur : l'exercice réel.
        expect(app.journalLineOf(15, 5, h.id, false).exerciseId, _hspu);
        expect(await app.koachStart(15, base), isTrue);
        expect(ex(5, 'HSPU AU MUR').id, h.id);
        expect(
          app
              .groups(shown(5), week: 15)
              .firstWhere((g) => g.any((e) => e.id == h.id))
              .length,
          page.length,
        );
        finir(5);
        final verses = exercicesVerses();
        _sonde('verses', verses.toList());
        expect(verses, contains(_hspu));
        final dipId = app.content.idFor(dip.name);
        expect(dipId, isNotNull);
        expect(
          app.koachEngine.journal.where(
            (ev) =>
                ev['type'] == 'serie' &&
                (ev['serie'] as Map)['slotId'] ==
                    app.adaptSlotOf(15, 5, dip.id) &&
                (ev['serie'] as Map)['exerciseId'] == dipId,
          ),
          isEmpty,
        );
        // Séance faite : plus de changement possible.
        expect(app.dayCanChange(15, 5, h), isFalse);
      },
    );

    test('tenue à la place de répétitions, exercice personnel, retour à '
        'l’écrit', () async {
      final base = await jour(5);
      final dip = ex(5, 'DIP LESTÉ');
      app.dayReplace(15, shown(5), dip, to: _handstand, name: 'Handstand');
      final t = ex(5, 'HANDSTAND DOS');
      expect(app.setsLabel(t), '6×30 s · E2MOM');
      expect(app.logSpec(t).kind, 'hold');
      expect(app.logSpec(t).seconds, 30);
      expect(app.logSpec(t).every, app.logSpec(dip).every);
      app.dayReplace(15, shown(5), t, name: 'Pike perso');
      final p = ex(5, 'PIKE PERSO');
      expect(p.id, '${dayChangeKey(dip.id)}~perso-pike-perso');
      expect(p.catalogId, isNull);
      expect(app.dayChangeOf(15, 5, p.id)!['from'], dip.name);
      expect(app.journalLineOf(15, 5, p.id, false).exerciseId, isNull);
      expect(app.dayLastPerformance(null, 'Pike perso'), isNull);
      app.dayUndo(15, base, dayChangeKey(p.id));
      expect(ex(5, 'DIP LESTÉ').id, dip.id);
      expect(app.dayChanges(15, 5), isEmpty);
    });

    test('retrait avec groupe avant le début : groupe recalé, Koach sert '
        'la séance sans la ligne, remise possible', () async {
      final base = await jour(5);
      final dip = ex(5, 'DIP LESTÉ');
      final expl = ex(5, 'DIPS EXPLOSIFS');
      final g0 = app.exerciseGroupOf(15, 5, dip);
      app.dayRemove(15, shown(5), expl, 'materiel');
      expect(shown(5).exercises.map((e) => e.id), isNot(contains(expl.id)));
      final g1 = app.exerciseGroupOf(15, 5, dip);
      _sonde('groupe', {'avant': g0?.toJson(), 'apres': g1?.toJson()});
      expect(app.dayRemovedLines(15, 5).single.reason, 'Pas de matériel');
      expect(await app.koachStart(15, base), isTrue);
      final a = app.sessionAdapt(15, 5)!;
      final slot = app.adaptSlotOf(15, 5, expl.id);
      expect(a.plan.items.map((x) => x.slotId), isNot(contains(slot)));
      expect(a.plan.validate(), isEmpty);
      expect(shown(5).exercises.map((e) => e.id), isNot(contains(expl.id)));
      // Remise : servie telle qu'écrite, groupe d'accord.
      app.dayUndo(15, base, dayChangeKey(expl.id));
      final b = app.sessionAdapt(15, 5)!;
      expect(b.plan.items.map((x) => x.slotId), contains(slot));
      expect(b.plan.validate(), isEmpty);
      expect(shown(5).exercises.map((e) => e.id), contains(expl.id));
    });

    test(
      'retrait sans groupe pendant la séance : Koach ne reçoit rien de la '
      'ligne ; Koach arrêté : changements gardés sur la séance écrite',
      () async {
        final base = await jour(5);
        expect(await app.koachStart(15, base), isTrue);
        final front = ex(5, 'BARRE AU FRONT');
        app.dayRemove(15, shown(5), front, 'temps');
        expect(shown(5).exercises.map((e) => e.id), isNot(contains(front.id)));
        finir(5);
        expect(exercicesVerses(), isNot(contains(front.catalogId)));
        // J6 : arrêt d'urgence, séance écrite : le remplacement tient.
        final b6 = await jour(6);
        app.koachStop();
        expect(app.koachStoppedWeek(15), isTrue);
        final squat = app
            .withDayChanges(15, b6)
            .exercises
            .firstWhere((e) => e.name.startsWith('Hip thrust'));
        app.dayReplace(15, b6, squat, to: _hspu, name: 'HSPU');
        expect(
          app.withDayChanges(15, b6).exercises.map((e) => e.catalogId),
          contains(_hspu),
        );
      },
    );

    test('passage depuis dev7.7.1 et export / import à l’identique', () async {
      // Une sauvegarde de dev7.7.1 n'a pas de changements du jour.
      final before = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      for (final l in (before['logs'] as Map).values) {
        expect((l as Map).containsKey('changes'), isFalse);
      }
      await jour(5);
      final dip = ex(5, 'DIP LESTÉ');
      app.dayReplace(15, shown(5), dip, to: _hspu, name: 'HSPU');
      app.dayRemove(15, shown(5), ex(5, 'FACE PULLS'), 'douleur');
      await app.flush();
      final out1 = app.exportAll();
      final doc = jsonDecode(out1) as Map<String, dynamic>;
      final logs = doc['logs'] as Map;
      expect((logs['S15-J5'] as Map)['changes'], hasLength(2));
      expect(await app.importAll(out1), isTrue);
      final out2 = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      for (final k in doc.keys) {
        if (k == 'exportedAt' || k == 'savedAt') continue;
        expect(jsonEncode(out2[k]), jsonEncode(doc[k]), reason: k);
      }
      expect(app.dayChanges(15, 5), hasLength(2));
    });

    /// Bilan [check] de S15·J[j], début réel de la séance.
    Future<DayPlan> servir(int j, kc.HealthCheck check) async {
      final base = await jour(j);
      app.adaptAnswer(15, base, check);
      expect(await app.koachStart(15, base), isTrue);
      return base;
    }

    /// Jour de S15 où le bilan bas change au moins une ligne (mode
    /// courant) ; rend son jour.
    Future<int> bilanBas() async {
      for (final j in const [1, 2, 3, 4, 5, 6]) {
        final base = app.program.week(15).day(j);
        if (base == null || base.exercises.isEmpty) continue;
        await servir(
          j,
          const kc.HealthCheck(overall: 1, sleepQuality: 1, energy: 1),
        );
        final b = app.koachBilan(15, j);
        _sonde('bilan_bas_J$j', app.sessionAdapt(15, j)!.koach!['bilan']);
        if (b != null) return j;
      }
      fail('aucune ligne changée par le bilan bas');
    }

    List<Map> decisionsBilan() => [
      for (final ev in app.koachEngine.journal)
        if (ev['type'] == 'decision' &&
            '${(ev['proposition'] as Map?)?['id']}'.endsWith('-bilan'))
          ev,
    ];

    test('mode libre : séance servie à l’écrit, bilan proposé ; « Accepter » '
        'repart du début avec la forme du jour, acceptation versée', () async {
      app.setGuidanceMode('free');
      final j = await bilanBas();
      final base = app.program.week(15).day(j)!;
      final b = app.koachBilan(15, j)!;
      expect(b.forme, isFalse);
      expect(b.assiste, isFalse);
      expect(b.choix, isNull);
      expect(b.modifiable, isTrue);
      final slot = b.lignes.keys.first;
      final ligne = app.koachBilanLigne(b, slot);
      _sonde('ligne_libre', ligne);
      // Écrit servi : les séries servies sont celles sans la forme du jour.
      final avant = app
          .sessionAdapt(15, j)!
          .plan
          .items
          .map((x) => x.toJson())
          .toList();
      expect(b.lignes[slot]!['servi'], isA<Map>());
      final n0 = app.sessionAdapt(15, j)!.koach!['n0'] as int;
      expect(await app.koachBilanChoose(15, base, true), isTrue);
      final c = app.koachBilan(15, j)!;
      expect(c.forme, isTrue);
      expect(c.choix, 'applique');
      expect(app.sessionAdapt(15, j)!.koach!['n0'], n0);
      expect(
        app.sessionAdapt(15, j)!.plan.items.map((x) => x.toJson()).toList(),
        isNot(avant),
      );
      expect(app.sessionAdapt(15, j)!.plan.validate(), isEmpty);
      // Un seul début de séance au journal.
      expect(
        app.koachEngine.journal.where((e) => e['type'] == 'seance_debut'),
        hasLength(
          app.koachEngine.journal
                  .take(n0)
                  .where((e) => e['type'] == 'seance_debut')
                  .length +
              1,
        ),
      );
      finir(j);
      final d = decisionsBilan();
      expect(d, hasLength(1));
      expect(d.single['accepte'], isTrue);
    });

    test(
      'mode libre : « Garder l’écrit » note le choix, refus versé',
      () async {
        app.setGuidanceMode('free');
        final j = await bilanBas();
        final base = app.program.week(15).day(j)!;
        final avant = jsonEncode(app.sessionAdapt(15, j)!.plan.toJson());
        expect(await app.koachBilanChoose(15, base, false), isTrue);
        final c = app.koachBilan(15, j)!;
        expect(c.forme, isFalse);
        expect(c.choix, 'ecrit');
        expect(jsonEncode(app.sessionAdapt(15, j)!.plan.toJson()), avant);
        finir(j);
        final d = decisionsBilan();
        expect(d, hasLength(1));
        expect(d.single['accepte'], isFalse);
      },
    );

    test(
      'mode assisté : bilan appliqué et dit ; « Annuler » repart du début '
      'sans la forme du jour ; plus de choix après la première série',
      () async {
        expect(app.adaptMode, 'assisted');
        final j = await bilanBas();
        final base = app.program.week(15).day(j)!;
        final b = app.koachBilan(15, j)!;
        expect(b.forme, isTrue);
        expect(b.assiste, isTrue);
        expect(app.koachBilanLigne(b, b.lignes.keys.first), isNotNull);
        expect(await app.koachBilanChoose(15, base, false), isTrue);
        final c = app.koachBilan(15, j)!;
        expect(c.forme, isFalse);
        expect(c.choix, 'ecrit');
        expect(koachTexteBilan(c), startsWith('Annulé'));
        // Première série validée : le choix est figé.
        final e = shown(j).exercises.first;
        final log = app.exLog(15, j, e);
        log.sets.first.reps = '5';
        log.sets.first.flames = 8;
        app.toggleSet(log, 0, app.logSpec(e));
        expect(app.koachBilan(15, j)!.modifiable, isFalse);
        expect(await app.koachBilanChoose(15, base, true), isFalse);
      },
    );

    test('bilan haut : sans changement ou dit de même ; douleur : conduite '
        'gardée dans les deux modes', () async {
      app.setGuidanceMode('free');
      final base = await servir(
        2,
        const kc.HealthCheck(overall: 5, sleepQuality: 5, energy: 5),
      );
      final b = app.koachBilan(15, 2);
      _sonde('bilan_haut', app.sessionAdapt(15, 2)!.koach!['bilan']);
      if (b != null) {
        for (final s in b.lignes.keys) {
          final t = app.koachBilanLigne(b, s);
          if (t != null) expect(t, contains('au lieu de'));
        }
      }
      expect(base.j, 2);
      // Les faits du bilan (douleurs, temps) sont toujours versés.
      final ev = app.koachEngine.journal.lastWhere(
        (e) => e['type'] == 'seance_debut',
      );
      expect(ev['bilan'], isNull);
    });
  });

  group('écran « Remplacer pour aujourd’hui »', () {
    late AppStore app;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      app = AppStore();
      await app.init();
      store = app;
    });
    tearDown(() async {
      await app.flush();
      app.dispose();
    });

    Future<ReplacePick?> ouvrir(
      WidgetTester tester, {
      required bool free,
      required Future<void> Function() act,
    }) async {
      ReplacePick? out;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(false),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                out = await Navigator.push<ReplacePick>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReplaceExercisePage(
                      fromName: 'DIP LESTÉ',
                      proposals: const ['sl-dips-leste', 'sl-dips-banc-leste'],
                      free: free,
                    ),
                  ),
                );
              },
              child: const Text('ouvrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      await act();
      await tester.pumpAndSettle();
      return out;
    }

    testWidgets('mode libre : recherche sans accents dans toute la base, '
        'choix hors propositions', (tester) async {
      final pick = await ouvrir(
        tester,
        free: true,
        act: () async {
          expect(find.byKey(const ValueKey('replace-search')), findsOneWidget);
          expect(
            find.byKey(const ValueKey('replace-proposal-sl-dips-leste')),
            findsOneWidget,
          );
          await tester.enterText(
            find.descendant(
              of: find.byKey(const ValueKey('replace-search')),
              matching: find.byType(EditableText),
            ),
            'hspu au mur dos',
          );
          await tester.pumpAndSettle();
          // Propositions masquées pendant la recherche.
          expect(
            find.byKey(const ValueKey('replace-proposal-sl-dips-leste')),
            findsNothing,
          );
          final row = find.byKey(const ValueKey('replace-$_hspu'));
          await tester.scrollUntilVisible(row, 200);
          await tester.tap(row);
        },
      );
      expect(pick?.id, _hspu);
      expect(pick?.name, 'HSPU au mur dos au mur');
    });

    testWidgets('mode libre : exercice personnel', (tester) async {
      app.addUserExercise('Pompes pike surélevées', 'Épaules', 'Banc');
      final pick = await ouvrir(
        tester,
        free: true,
        act: () async {
          await tester.enterText(
            find.descendant(
              of: find.byKey(const ValueKey('replace-search')),
              matching: find.byType(EditableText),
            ),
            'pike sureleve',
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const ValueKey('replace-own-Pompes pike surélevées')),
          );
        },
      );
      expect(pick?.id, isNull);
      expect(pick?.name, 'Pompes pike surélevées');
    });

    testWidgets('mode assisté : propositions seules, le choix libre est dit', (
      tester,
    ) async {
      final pick = await ouvrir(
        tester,
        free: false,
        act: () async {
          expect(find.byKey(const ValueKey('replace-search')), findsNothing);
          expect(
            find.byKey(const ValueKey('replace-free-hint')),
            findsOneWidget,
          );
          await tester.tap(
            find.byKey(const ValueKey('replace-proposal-sl-dips-banc-leste')),
          );
        },
      );
      expect(pick?.id, 'sl-dips-banc-leste');
    });
  });
}
