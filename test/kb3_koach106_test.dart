// KB3 (dev7.3.0, pipeline CP, DECISIONS_CP.md C17.39) — Koach 1.0.6
// (`kalis_adapt` 1.0.5) dans l'application :
//
// - rôle de l'emplacement donné à chaque item de `reste_semaine` et des
//   séances manquées (le retour gradué coupe les accessoires d'abord et
//   garde le plancher des principaux) ;
// - garde de la séance (`koachGardeSeance`) pour les principaux seulement :
//   un accessoire ou un secondaire retiré par Koach reste retiré, raison
//   affichée ; un principal absent du servi est servi tel qu'écrit ;
// - raisons : séries réduites (« 3 séries au lieu de 6 ») et retrait
//   (« Je retire … aujourd’hui ») dits ; affichage indépendant de l'ordre
//   des raisons du moteur ;
// - scénario C17.37 sur le programme importé PR2 synthétique (six séances
//   par semaine en PPL, départ affiché S15, pull-over « chest » ajouté au
//   lundi de tirage) : muscle-up lesté et traction lestée servis par
//   Koach, l'accessoire « chest » retiré d'abord ;
// - données : passage depuis dev7.2.4 (prise de main de Koach 1.0.5)
//   sans perte, séances faites jamais réécrites, programme d'origine
//   intact (C11.2), pas de nouvelle prise de main.
//
// Données synthétiques seulement (C17.33.2) ; horloge injectée ; stockage
// simulé ; calculs du moteur sur place.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_adapt/kalis_adapt.dart' as ka;
import 'package:kalis_adapt/koach.dart' as ko;
import 'package:kalis_adapt/koach_textes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/koach1/koach_journal.dart';
import 'package:streetlift_tracker/koach1/koach_moteur.dart';
import 'package:streetlift_tracker/store.dart';

import 'kb2c1_fixtures.dart';
import 'l2_fixtures.dart';

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

/// Semaine type PR2 avec un pull-over (accessoire qui crédite « chest »)
/// au lundi de tirage, après la traction lestée et ses pompes.
Map<String, dynamic> _semaineAvecPullOver() {
  final s = pr2Semaine();
  final j1 = (s['days'] as List).first as Map<String, dynamic>;
  final ex = (j1['exercises'] as List).cast<Map<String, dynamic>>();
  ex.insert(3, {
    'id': 'NA-S15J1-08',
    'name': 'Pull-over haltère',
    'sets': {'type': 'text', 'value': '3×12'},
    'intensity': 'RIR 2',
    'load': {'type': 'acc', 'ref': 'B43', 'dayReps': 12, 'step': 2.0},
    'rest': '90 s',
    'restSec': 90,
    'tempo': 'Contrôlé',
    'cue': 'Accessoire du test KB3 (données synthétiques).',
    'main': false,
    'prevention': false,
    'catalogId': 'mu-pull-over-haltere',
  });
  j1['exercises'] = ex;
  return s;
}

/// Dernier début de séance versé au journal de Koach.
Map<String, Object?> _debut(AppStore app) =>
    app.koachEngine.journal.lastWhere((x) => x['type'] == 'seance_debut');

/// Contexte du dernier début de séance.
Map<String, Object?> _contexte(AppStore app) =>
    ((_debut(app)['contexte'] as Map?) ?? const {}).cast<String, Object?>();

/// Section de la sauvegarde exportée.
String _section(AppStore app, String key) =>
    jsonEncode((jsonDecode(app.exportAll()) as Map<String, dynamic>)[key]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('paquet', () {
    test('Koach 1.0.6 servi (`kalis_adapt` 1.0.5, paramètres 1.0.6-ref.1, '
        '347 clés)', () {
      expect(ka.kalisAdaptVersion, '1.0.5');
      expect(ko.koachVersion, '1.0.6-ref.1');
      expect(ko.koachParametresVersion, '1.0.6-ref.1');
      expect(ko.koachParametresCles, 347);
      expect(
        ko.koachParametresSha256,
        '4156e61b674be1e983d22dba21067cb47cc16d25429b60588957549b9464045a',
      );
      expect(kKoachParamsAsset, 'assets/koach/koach_params_1_0_6.json');
    });

    test('textes 1.0.6 : séries réduites (« au lieu de »), retrait du '
        'jour', () {
      final reduit = texteRaisonKoach(
        {
          'code': 'koach.retour_gradue',
          'params': {
            'exercice': 'sl-muscle-up-leste',
            'groupe': 'chest',
            'series': 3,
            'ecrites': 6,
          },
        },
        nomExercice: (_) => 'Muscle-up lesté',
      );
      expect(reduit, startsWith('3 séries au lieu de 6 sur Muscle-up lesté'));
      final retrait = texteRaisonKoach(
        {
          'code': 'koach.retour_gradue',
          'params': {
            'exercice': 'mu-pull-over-haltere',
            'groupe': 'chest',
            'series': 0,
            'ecrites': 3,
          },
        },
        nomExercice: (_) => 'Pull-over',
      );
      expect(retrait, startsWith('Je retire Pull-over aujourd’hui'));
    });
  });

  group('rôles des items (contrat 1.0.6)', () {
    test('rôle de l’emplacement ajouté ; omis s’il est inconnu', () {
      final it = {
        'slotId': 'j2-dips',
        'exerciseId': 'sl-dips-leste',
        'kind': 'work',
        'sets': 8,
        'loadKg': 20,
      };
      expect(koachItemVolume(it, {'j2-dips': 'main'}), {
        'slotId': 'j2-dips',
        'exerciseId': 'sl-dips-leste',
        'kind': 'work',
        'sets': 8,
        'targetFlames': null,
        'secondsLow': null,
        'secondsHigh': null,
        'role': 'main',
      });
      expect(koachItemVolume(it).containsKey('role'), isFalse);
      expect(koachItemVolume(it, {'autre': 'main'}).containsKey('role'), false);
    });
  });

  group('garde de la séance : principaux seulement (pure)', () {
    final ecrit = [
      _it('j1-a', 'a'),
      _it('j1-b', 'b'),
      _it('j1-c', 'c'),
      _it('j1-d', 'd'),
      _it('j1-e', 'e'),
    ];
    const roles = {
      'j1-a': 'main',
      'j1-b': 'secondary',
      'j1-c': 'accessory',
      'j1-d': 'accessory',
      // j1-e : rôle inconnu.
    };

    test('principal retiré : servi tel qu’écrit ; accessoire et secondaire '
        'retirés par le retour gradué : retirés, raison gardée', () {
      final g = koachGardeSeance(
        ecrit,
        const [],
        [
          _r('koach.retour_gradue', 'a'),
          _r('koach.retour_gradue', 'b'),
          _r('koach.retour_gradue', 'c'),
          _r('koach.tendon', 'e'),
        ],
        roles: roles,
      );
      expect(g.ecrites, [
        {'slotId': 'j1-a', 'exercice': 'a', 'cause': 'koach.retour_gradue'},
        // Sans raison de Koach : jamais retiré en silence.
        {'slotId': 'j1-d', 'exercice': 'd'},
        // Rôle inconnu : gardé comme un principal.
        {'slotId': 'j1-e', 'exercice': 'e', 'cause': 'koach.tendon'},
      ]);
      expect(g.retraits, [
        {'slotId': 'j1-b', 'exercice': 'b', 'code': 'koach.retour_gradue'},
        {'slotId': 'j1-c', 'exercice': 'c', 'code': 'koach.retour_gradue'},
      ]);
    });

    test('retraits motivés inchangés (douleur) ; sans rôles : garde de '
        'KB2 correction 1', () {
      final g = koachGardeSeance(
        ecrit,
        [for (final x in ecrit.skip(1)) x],
        [_r('koach.douleur_retrait', 'a')],
        roles: roles,
      );
      expect(g.retraits, [
        {'slotId': 'j1-a', 'exercice': 'a', 'code': 'koach.douleur_retrait'},
      ]);
      final h = koachGardeSeance(ecrit, const [], [
        _r('koach.retour_gradue', 'c'),
      ]);
      expect(h.retraits, isEmpty);
      expect(h.ecrites, hasLength(5));
    });
  });

  group('ordre des raisons', () {
    test('affichage dans l’ordre du contrat, quel que soit l’ordre du '
        'moteur', () {
      final a = [
        _r('koach.retour_gradue', 'x'),
        _r('koach.douleur_retrait', 'y'),
        {'code': 'inconnu'},
        _r('koach.surmenage', 'x'),
      ];
      final t1 = [for (final r in koachTrierRaisons(a)) r['code']];
      final t2 = [
        for (final r in koachTrierRaisons(a.reversed.toList())) r['code'],
      ];
      expect(t1, [
        'koach.douleur_retrait',
        'koach.surmenage',
        'koach.retour_gradue',
        'inconnu',
      ]);
      expect(t2, t1);
    });
  });

  group('programme PR2 synthétique (C17.37)', () {
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

    Future<DayPlan> open() async {
      await importPr2Nouveau(app, semaine: _semaineAvecPullOver());
      app.koachNoteInstall();
      await app.koachRefresh();
      expect(
        app.koachEngine.fromWeek,
        15,
        reason: '${app.koachEngine.blocked}',
      );
      final base = app.program.week(15).day(1)!;
      expect(app.adaptOpen(15, base)?.koach?['state'], 'preview');
      return base;
    }

    test('lundi de tirage servi par Koach : muscle-up lesté et traction '
        'lestée présents (séries réduites au plus), pull-over « chest » '
        'retiré d’abord, raisons affichées ; rôles dans reste_semaine', () async {
      final base = await open();
      expect(
        [for (final e in base.exercises) e.catalogId],
        contains('mu-pull-over-haltere'),
      );
      final sw = Stopwatch()..start();
      expect(await app.koachStart(15, base), isTrue);
      final ms = sw.elapsedMicroseconds / 1000;
      expect(app.koachOpen(15, 1), isTrue);
      final st = app.sessionAdapt(15, 1)!.koach!;
      final items = [
        for (final x in st['items'] as List) (x as Map).cast<String, Object?>(),
      ];
      Map<String, Object?>? servi(String id) =>
          items.where((x) => x['exerciseId'] == id).firstOrNull;
      final a = app.sessionAdapt(15, 1)!;
      final shown = app.adaptDay(15, base, a).exercises;
      // Sonde (relevé de la livraison).
      // ignore: avoid_print
      print(
        'KB3|sonde|${jsonEncode({
          'servis': [for (final x in items) '${x['exerciseId']}:${x['sets']}'],
          'ecrites': st['ecrites'],
          'retraits': st['retraits'],
          'raisons': [for (final r in st['raisons'] as List) texteRaisonKoach((r as Map).cast<String, Object?>())],
          'cartes': [for (final e in shown) '${e.catalogId}:${app.setsLabel(e)}'],
          'entete': app.koachSessionReasons(15, 1, max: 9),
          'temps_ms': ms,
          'temps': app.koachTemps.toJson(),
        })}',
      );
      // Principaux servis par Koach (pas par la garde), au plus leur écrit.
      final mu = servi('sl-muscle-up-leste');
      final tr = servi('sl-traction-lestee');
      expect(mu, isNotNull);
      expect(tr, isNotNull);
      expect(mu!['sets'] as num, inInclusiveRange(1, 6));
      expect(tr!['sets'] as num, inInclusiveRange(1, 8));
      final ecrites = [
        for (final x in (st['ecrites'] as List?) ?? const [])
          (x as Map)['exercice'],
      ];
      expect(ecrites, isNot(contains('sl-muscle-up-leste')));
      expect(ecrites, isNot(contains('sl-traction-lestee')));
      // Accessoire « chest » coupé d'abord : retiré, raison dite.
      expect(servi('mu-pull-over-haltere'), isNull);
      expect(st['retraits'], [
        {
          'slotId': 'j1-mu-pull-over-haltere',
          'exercice': 'mu-pull-over-haltere',
          'code': 'koach.retour_gradue',
        },
      ]);
      expect(
        app.koachSessionReasons(15, 1).first,
        startsWith('Je retire'),
      );
      expect(app.koachSessionReasons(15, 1).first, contains('aujourd’hui'));
      // Cartes : ordre écrit, muscle-up en tête, pull-over absent.
      expect(shown.first.catalogId, 'sl-muscle-up-leste');
      expect(
        [for (final e in shown) e.catalogId],
        isNot(contains('mu-pull-over-haltere')),
      );
      expect(shown.length, base.exercises.length - 1);
      // Séries réduites : raison sur la carte (« au lieu de »).
      for (final (x, n) in [(mu, 6), (tr, 8)]) {
        final e = shown.firstWhere((s) => s.catalogId == x['exerciseId']);
        final line = app.koachReasonLine(15, 1, e);
        if ((x['sets'] as num) < n) {
          expect(line, contains('au lieu de $n'), reason: '$x');
        }
      }
      // Rôles transmis dans reste_semaine (J2 à J6).
      final reste = _contexte(app)['reste_semaine'] as List;
      expect(reste, hasLength(5));
      for (final seance in reste) {
        for (final it in seance as List) {
          expect((it as Map).containsKey('role'), isTrue, reason: '$it');
        }
      }
      final j2 = (reste.first as List).cast<Map>();
      expect(
        j2.firstWhere((x) => x['exerciseId'] == 'sl-dips-leste')['role'],
        'main',
      );
      expect(
        j2.firstWhere((x) => x['exerciseId'] == 'sl-pompe-lestee-gilet')['role'],
        isNot('main'),
      );
      // Budget de décision (C3 : ≤ 50 ms par décision, VM ; ici toute la
      // séance servie, mesurée).
      expect(ms, lessThan(5000));
    });

    test('raisons gardées après la première série (`plan(serie)`)', () async {
      final base = await open();
      expect(await app.koachStart(15, base), isTrue);
      final a = app.sessionAdapt(15, 1)!;
      final shown = app.adaptDay(15, base, a).exercises;
      final avant = app.koachSessionReasons(15, 1, max: 9);
      final mu = shown.first;
      final ligne = app.koachReasonLine(15, 1, mu);
      final log = app.exLog(15, 1, mu);
      app.adaptPrefill(15, 1, mu, log);
      // Cible de la première série (`plan(serie)` : remplace les raisons).
      app.koachEnsureTarget(15, base, mu, 0);
      final apres = app.koachSessionReasons(15, 1, max: 9);
      expect(apres.first, avant.first);
      if (ligne != null && ligne.contains('au lieu de')) {
        expect(app.koachReasonLine(15, 1, mu), isNotNull);
      }
    });

    test('séances manquées : rôle de l’emplacement sur chaque item', () async {
      await open();
      // Aucune séance de S15 faite ; lundi suivant.
      clock = DateTime(2026, 10, 26, 7);
      await app.koachRefresh();
      final mq = app.koachEngine.manquees;
      expect(mq, isNotEmpty);
      for (final m in mq) {
        for (final it in m['items'] as List) {
          expect((it as Map).containsKey('role'), isTrue, reason: '$it');
        }
      }
    });

    test('passage depuis dev7.2.4 : prise de main de 1.0.5 gardée, séances '
        'faites, journal et programme d’origine intacts', () async {
      final base = await open();
      // Séance du lundi servie par Koach 1.0.5 en dev7.2.4 : on la marque
      // faite, puis on écrit l'instantané d'une prise de main 1.0.5.
      expect(await app.koachStart(15, base), isTrue);
      app.markSessionDone(15, 1, true);
      await app.flush();
      final doc = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      final engine = (doc['koachEngine'] as Map).cast<String, dynamic>();
      final snap = (engine['snap'] as Map).cast<String, dynamic>();
      snap['version_moteur'] = '1.0.5-ref.1';
      snap['version_parametres'] = '1.0.5-ref.1';
      snap['sha256_parametres'] =
          'd8a492b7debca0e4a504ed399efee0a8a6e4e003ab99f7cbb7f49c114bfbf26d';
      engine['snap'] = snap;
      doc['koachEngine'] = engine;
      final text = jsonEncode(doc);
      await app.flush();
      app.dispose();
      await fresh();
      expect(await app.importAll(text), isTrue);
      final logs = _section(app, 'logs');
      final instance = _section(app, 'programInstance');
      final origin = _section(app, 'programOrigin');
      final journal = [
        for (final x in app.koachEngine.journal) jsonEncode(x),
      ];
      expect(app.programOrigin, isNotNull);
      // Lendemain : premier lancement de dev7.3.0.
      clock = DateTime(2026, 10, 20, 7);
      app.koachNoteInstall();
      await app.koachRefresh();
      final e = app.koachEngine;
      expect(e.fromWeek, 15);
      expect(e.snap!.versionMoteur, '1.0.5-ref.1');
      expect(app.koachLive, isNotNull);
      expect(app.koachLive!.params['version'], '1.0.6-ref.1');
      expect(_section(app, 'logs'), logs);
      expect(_section(app, 'programInstance'), instance);
      expect(_section(app, 'programOrigin'), origin);
      // Journal de 1.0.5 gardé tel quel (rattrapage ajouté après).
      expect(e.journal.length, greaterThanOrEqualTo(journal.length));
      for (var i = 0; i < journal.length; i++) {
        expect(jsonEncode(e.journal[i]), journal[i], reason: 'événement $i');
      }
      expect(app.logs[app.sessionKey(15, 1)]!.done, isTrue);
      // Mardi : séance servie par 1.0.6 (prise de main de 1.0.5 gardée).
      final j2 = app.program.week(15).day(2)!;
      expect(app.adaptOpen(15, j2)?.koach?['state'], 'preview');
      expect(await app.koachStart(15, j2), isTrue);
      expect(app.koachOpen(15, 2), isTrue);
      expect(_section(app, 'programOrigin'), origin);
      expect(app.logs[app.sessionKey(15, 1)]!.done, isTrue);
    });
  });

  group('programme créé (kalis_plan)', () {
    late AppStore app;
    var clock = DateTime(2026, 10, 5, 9);
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      KoachCalcul.isolat = false;
      debugResetKoachTakeoverWait();
      clock = DateTime(2026, 10, 5, 9); // lundi
      app = AppStore()..storeClock = () => clock;
      await app.init();
    });
    tearDown(() async {
      debugKoachBasculeAutorisee = false;
      await app.flush();
      app.dispose();
    });

    test('rôles de l’emplacement dans reste_semaine', () async {
      debugKoachBasculeAutorisee = false;
      final r = app.saveAthleteProfile(
        ProfileDraft.of(sampleStreet5050Profile(on: civilOf(clock)))
          ..consent = 'refused',
      );
      expect(r, isNotNull);
      final c = PlanStore(app).newPlanCreation(journal: false)!;
      c.start();
      c.createPass2();
      PlanStore(app).applyPlanCreation(c);
      final plan = app.planProgram!;
      final lundi = app.koachLundi!;
      final w0 = plan.firstWeek;
      final monday = lundi.addDays(7 * (w0 - 1));
      clock = DateTime(monday.year, monday.month, monday.day, 7);
      debugKoachBasculeAutorisee = true;
      await app.koachRefresh();
      expect(app.koachEngine.snap, isNotNull);
      final d = app.program
          .week(w0)
          .days
          .firstWhere((x) => x.exercises.isNotEmpty);
      expect(app.adaptOpen(w0, d)?.koach?['state'], 'preview');
      expect(await app.koachStart(w0, d), isTrue);
      final reste = _contexte(app)['reste_semaine'] as List;
      expect(reste, isNotEmpty);
      final roles = <Object?>{};
      for (final s in reste) {
        for (final it in s as List) {
          expect((it as Map).containsKey('role'), isTrue, reason: '$it');
          roles.add(it['role']);
        }
      }
      expect(roles, contains('main'));
    });
  });
}
