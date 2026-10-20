// KB2 correction 1 (dev7.2.2, pipeline CP, DECISIONS_CP.md C17.36) — la
// séance servie par Koach après le questionnaire hors modèle :
//
// - garde de la séance (`koachGardeSeance`) : Koach ne retire ni n'ajoute
//   jamais en silence un exercice de la séance écrite ; ordre écrit ;
// - cause du constat 4 : sur le nouveau programme (PR2), la règle de
//   retour gradué de Koach 1.0.5 (`koach.retour_gradue`, volume de la
//   semaine par grand groupe) retirait le muscle-up lesté et la traction
//   lestée de S1·J1 ; l'application effaçait les lignes absentes du servi.
//   Avec ou sans alerte : « Plus tard » sert la même séance ;
// - réponses au questionnaire (codes des choix), chaque cause menée de
//   bout en bout ; réponse refusée : séance écrite, question reposée ;
// - arrêt d'urgence pendant une séance commencée : retour à l'écrit,
//   séries notées gardées.
//
// Données synthétiques (kb2c1_fixtures.dart) ; horloge injectée ;
// stockage simulé ; calculs du moteur sur place.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/koach1/koach1_widgets.dart';
import 'package:streetlift_tracker/koach1/koach_moteur.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/store.dart';

import 'kb2c1_fixtures.dart';

Map<String, Object?> _it(String slot, String ex, {String? kind}) => {
  'slotId': slot,
  'exerciseId': ex,
  'sets': 3,
  'kind': ?kind,
};

Map<String, Object?> _r(String code, String ex) => {
  'code': code,
  'params': {'exercice': ex},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('garde de la séance (pure)', () {
    final ecrit = [
      _it('j1-a', 'a'),
      _it('j1-b', 'b'),
      _it('j1-c', 'c'),
      _it('j1-d', 'd', kind: 'test'),
      _it('j1-e', 'e'),
    ];

    test('retrait par le retour gradué : ligne servie telle qu’écrite, '
        'cause gardée ; ordre écrit', () {
      final g = koachGardeSeance(
        ecrit,
        [_it('j1-c', 'c'), _it('j1-d', 'd', kind: 'test'), _it('j1-e', 'e')],
        [_r('koach.retour_gradue', 'a'), _r('koach.retour_gradue', 'b')],
      );
      expect([for (final x in g.servis) x['slotId']], ['j1-c', 'j1-d', 'j1-e']);
      expect(g.ecrites, [
        {'slotId': 'j1-a', 'exercice': 'a', 'cause': 'koach.retour_gradue'},
        {'slotId': 'j1-b', 'exercice': 'b', 'cause': 'koach.retour_gradue'},
      ]);
      expect(g.retraits, isEmpty);
    });

    test('retraits motivés : douleur, test reporté, temps donné', () {
      final g = koachGardeSeance(
        ecrit,
        [_it('j1-b', 'b')],
        [
          _r('koach.douleur_retrait', 'a'),
          _r('koach.seance_bornee', 'c'),
          _r('koach.test_reporte', 'd'),
          _r('koach.test_reporte', 'e'),
        ],
        budgetDonne: true,
      );
      expect(
        [for (final x in g.retraits) x['slotId']],
        ['j1-a', 'j1-c', 'j1-d'],
      );
      // Un « test reporté » sur une ligne de travail n'est pas un motif.
      expect([for (final x in g.ecrites) x['slotId']], ['j1-e']);
      // Durée bornée sans temps donné par l'athlète : pas un motif.
      final h = koachGardeSeance(
        ecrit,
        [for (final x in ecrit) x]..removeAt(2),
        [_r('koach.seance_bornee', 'c')],
      );
      expect(h.ecrites, [
        {'slotId': 'j1-c', 'exercice': 'c', 'cause': 'koach.seance_bornee'},
      ]);
    });

    test('vrai test gardé devant sa ligne ; ajout sans ligne écrite '
        'écarté ; sans raison : servi tel qu’écrit', () {
      final g = koachGardeSeance(ecrit, [
        _it('j1-e', 'e'),
        _it('j1-z', 'z'),
        _it('j1-b.t', 'b', kind: 'test'),
        _it('j1-b', 'b'),
        _it('j1-a', 'a'),
        _it('j1-d', 'd', kind: 'test'),
      ], const []);
      expect(
        [for (final x in g.servis) x['slotId']],
        ['j1-a', 'j1-b.t', 'j1-b', 'j1-d', 'j1-e'],
      );
      expect(g.ecrites, [
        {'slotId': 'j1-c', 'exercice': 'c'},
      ]);
    });
  });

  group('programme PR2 synthétique', () {
    late AppStore app;
    var clock = DateTime(2026, 10, 19, 7);

    Future<void> fresh() async {
      SharedPreferences.setMockInitialValues({});
      app = AppStore()..storeClock = () => clock;
      await app.init();
    }

    setUp(() async {
      KoachCalcul.isolat = false;
      debugKoachBasculeAutorisee = true;
      debugResetKoachTakeoverWait();
      clock = DateTime(2026, 10, 19, 7); // lundi 19/10, S15 = S1 affichée
      await fresh();
    });
    tearDown(() async {
      debugKoachBasculeAutorisee = false;
      await app.flush();
      app.dispose();
    });

    /// Prise de main, S1·J1 ouverte (aperçu) ; [alerte] : alerte hors
    /// modèle levée (cause « rupture »).
    Future<DayPlan> open({bool alerte = false}) async {
      await importPr2Nouveau(app);
      app.koachNoteInstall();
      await app.koachRefresh();
      expect(
        app.koachEngine.fromWeek,
        15,
        reason: '${app.koachEngine.blocked}',
      );
      final base = app.program.week(15).day(1)!;
      expect(app.adaptOpen(15, base)?.koach?['state'], 'preview');
      if (alerte) {
        app.koachLive!.surveillance!.alertes = [true, false, false, false];
        expect(app.koachNeedsDiagnostic, isTrue);
      }
      return base;
    }

    // KB3 (Koach 1.0.6) : le retour gradué ne retire plus un principal
    // sans douleur ; muscle-up et traction lestés sont servis par Koach
    // (séries réduites au plus, raison sur la carte), plus par la garde.
    test('S1·J1 servie par Koach : mêmes exercices, même ordre que '
        'l’écrit ; muscle-up et traction lestés servis par Koach 1.0.6, '
        'réduits au plus', () async {
      final base = await open();
      final ecrit = structureSeance(app, 15, 1);
      expect(ecrit.first, startsWith('MUSCLE-UP LESTÉ'));
      expect(await app.koachStart(15, base), isTrue);
      expect(app.koachOpen(15, 1), isTrue);
      final a = app.sessionAdapt(15, 1)!;
      final st = a.koach!;
      final ecrites = [
        for (final x in (st['ecrites'] as List?) ?? const [])
          (x as Map)['exercice'],
      ];
      expect(ecrites, isNot(contains('sl-muscle-up-leste')));
      expect(ecrites, isNot(contains('sl-traction-lestee')));
      final servis = {
        for (final x in st['items'] as List)
          (x as Map)['exerciseId']: x['sets'],
      };
      expect(servis['sl-muscle-up-leste'] as num, inInclusiveRange(1, 6));
      expect(servis['sl-traction-lestee'] as num, inInclusiveRange(1, 8));
      final shown = app.adaptDay(15, base, a).exercises;
      expect(shown.length, base.exercises.length);
      for (var i = 0; i < shown.length; i++) {
        expect(shown[i].name, base.exercises[i].name);
      }
      final ex = base.exercises.first;
      final e = shown.firstWhere((x) => x.id == ex.id);
      expect(app.adaptSlotOf(15, 1, e.id), 'j1-sl-muscle-up-leste');
      // Ligne au départ chronométré (PR8) : séries écrites, réduction de
      // Koach dite sur la carte.
      expect(app.setsLabel(shown.first), app.setsLabel(base.exercises.first));
      final n = servis['sl-muscle-up-leste'] as num;
      if (n < 6) {
        expect(
          app.koachReasonLine(15, 1, shown.first),
          contains('$n séries sur 6'),
        );
      }
    });

    test(
      '« Plus tard » (alerte levée, sans réponse) sert la même séance '
      'que sans alerte ; la question est reposée à la séance suivante',
      () async {
        final base0 = await open();
        expect(await app.koachStart(15, base0), isTrue);
        final sans = structureSeance(app, 15, 1);
        final items0 = jsonEncode(app.sessionAdapt(15, 1)!.plan.items);
        await app.flush();
        app.dispose();
        await fresh();
        final base = await open(alerte: true);
        expect(await app.koachStart(15, base), isTrue);
        expect(structureSeance(app, 15, 1), sans);
        expect(jsonEncode(app.sessionAdapt(15, 1)!.plan.items), items0);
        // Alerte toujours levée : question reposée à J2.
        expect(app.koachNeedsDiagnostic, isTrue);
        final j2 = app.program.week(15).day(2)!;
        expect(app.adaptOpen(15, j2)?.koach?['state'], 'preview');
        expect(app.koachQuestions(const {}).first['code'], 'cause');
      },
    );

    /// Réponses données par l'écran pour [cause] : le code du choix voulu
    /// de chaque question (premier choix sinon).
    Map<String, Object?> answers(String cause) {
      final r = <String, Object?>{};
      for (var step = 0; step < 3; step++) {
        final qs = app.koachQuestions(r);
        if (step >= qs.length) break;
        final q = qs[step];
        final choix = q['choix'] as List;
        final code = '${q['code']}';
        final pick = switch (code) {
          'cause' => choix.firstWhere((c) => (c as Map)['code'] == cause),
          'intensite' => choix.firstWhere((c) => (c as Map)['code'] == 4),
          'seances_par_semaine' => choix.firstWhere(
            (c) => (c as Map)['code'] == 4,
          ),
          'duree_max_min' => choix.firstWhere((c) => (c as Map)['code'] == 60),
          _ => choix.first,
        };
        expect(koachChoiceLabel(code, pick), isNot(startsWith('Autre')));
        r[code] = koachChoiceCode(pick);
      }
      return r;
    }

    for (final (cause, action, n) in const [
      ('douleur', 'conduite_douleur', 3),
      ('moins_de_temps', 'replanifier', 3),
      ('fatigue', 'semaine_allegee', 1),
      ('rien', 'elargir', 1),
    ]) {
      test('cause « $cause » menée de bout en bout : réponse acceptée, '
          'action « $action », séance servie par Koach', () async {
        final base = await open(alerte: true);
        final r = answers(cause);
        expect(r.length, n);
        expect(r['cause'], cause);
        for (final v in r.values) {
          expect(v is String || v is int, isTrue, reason: '$v');
        }
        expect(app.koachDiagnosticValid(r), isTrue);
        final journal = app.koachEngine.journal.length;
        expect(app.koachStartNow(15, base, diagnostic: r), isTrue);
        expect(app.koachOpen(15, 1), isTrue);
        expect(app.koachAnswerRefused(15, 1), isFalse);
        final d = app.koachEngine.journal.lastWhere(
          (x) => x['type'] == 'decision',
        );
        expect(d[kKoachCleDiag], r);
        expect(app.koachEngine.journal.length, greaterThan(journal));
        final rep = app.koachLive!.surveillance!.reponses;
        expect(jsonEncode(rep.last), contains('"$action"'));
        // Cause répondue acquittée (une douleur signalée peut lever la
        // sienne : conduite sous douleur du moteur).
        expect(app.koachAlertCauses, isNot(contains('rupture')));
        if (cause != 'douleur') expect(app.koachNeedsDiagnostic, isFalse);
        expect(app.sessionAdapt(15, 1)!.koach?['diag'], r);
      });
    }

    test('réponse refusée (objet du choix au lieu de son code) : jamais '
        'en silence — séance écrite servie, question reposée', () async {
      final base = await open(alerte: true);
      final apercu = jsonEncode(app.sessionAdapt(15, 1)!.plan.items);
      final journal = jsonEncode(app.koachEngine.journal);
      final bad = <String, Object?>{
        'cause': {'code': 'rien', 'texte': 'Rien de spécial'},
      };
      expect(app.koachDiagnosticValid(bad), isFalse);
      expect(app.koachDiagnosticValid({'cause': 'autre'}), isFalse);
      expect(
        app.koachDiagnosticValid({'cause': 'douleur', 'zone': 'nulle_part'}),
        isFalse,
      );
      expect(app.koachStartNow(15, base, diagnostic: bad), isFalse);
      expect(app.koachAnswerRefused(15, 1), isTrue);
      expect(app.koachOpen(15, 1), isFalse);
      expect(app.koachPending(15, 1), isFalse);
      // Séance écrite (l'aperçu), rien versé au journal de Koach.
      expect(jsonEncode(app.sessionAdapt(15, 1)!.plan.items), apercu);
      expect(jsonEncode(app.koachEngine.journal), journal);
      expect(structureSeance(app, 15, 1).first, startsWith('MUSCLE-UP LESTÉ'));
      // Rouverte : reste la séance écrite (pas de nouveau questionnaire).
      expect(app.adaptOpen(15, base)?.koach?['state'], 'ecrite');
      // Question reposée à la séance suivante.
      expect(app.koachNeedsDiagnostic, isTrue);
      final j2 = app.program.week(15).day(2)!;
      expect(app.adaptOpen(15, j2)?.koach?['state'], 'preview');
    });

    test('arrêt d’urgence pendant une séance commencée : retour à la séance '
        'écrite, séries notées gardées ; réactivation', () async {
      final base = await open();
      expect(await app.koachStart(15, base), isTrue);
      final a = app.sessionAdapt(15, 1)!;
      final shown = app.adaptDay(15, base, a).exercises;
      // Première série du rowing (servie par Koach) notée.
      final row = shown.firstWhere(
        (x) => x.catalogId == 'mu-rowing-barre-pronation',
      );
      final log = app.exLog(15, 1, row);
      app.adaptPrefill(15, 1, row, log);
      log.sets[0]
        ..kg = '62.5'
        ..reps = '8'
        ..done = true;
      app.saveLogs();
      final done = jsonEncode(log.sets[0].toJson());
      app.koachStop();
      expect(app.koachStoppedWeek(15), isTrue);
      expect(app.adaptOpen(15, base), isNull);
      final key = app.sessionKey(15, 1);
      final kept = app.logs[key]!.ex[row.id]!;
      expect(jsonEncode(kept.sets[0].toJson()), done);
      final wr = base.exercises.firstWhere((x) => x.id == row.id);
      expect(kept.sets.length, app.setCount(wr));
      for (final s in kept.sets.skip(1)) {
        expect(s.done, isFalse);
        expect(s.kg, isEmpty);
        expect(s.reps, isEmpty);
      }
      // Séance écrite : les exercices du programme, dans l'ordre.
      final written = app.program.week(15).day(1)!;
      expect(written.exercises.length, base.exercises.length);
      await app.koachResume();
      expect(app.koachOpen(15, 1), isTrue);
      expect(jsonEncode(app.logs[key]!.ex[row.id]!.sets[0].toJson()), done);
    });
  });
}
