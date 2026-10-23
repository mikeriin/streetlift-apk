// KB5 (dev7.7.0, pipeline CP, DECISIONS_CP.md C17.47, C17.48) — Koach 1.0.8
// (`kalis_adapt` 1.0.7) et `kalis_plan` 0.4.3 dans l'application :
//
// - paquets, paramètres `1.0.8-ref.1` et fiches 1.0.1 (empreintes) ;
//   crédits « chest » des tirages (rapport « séries par groupe » de
//   `kalis_plan`, fiches de Koach) ;
// - groupes (X2, X7) : les `GroupSpec` de la séance écrite passent à
//   `plan(seance)`, les groupes recalés de la sortie sont lus ; une ligne
//   remplacée par l'application (PR8, intervalles tels qu'écrits) fait
//   recaler son groupe par la même règle (parité avec le moteur) ;
// - technique (X3) : intervalles d'un EMOM = séries, sécurité de
//   l'application ;
// - raison `koach.volume_semaine` (X8) : dite en tête de séance et sur la
//   carte, gardée après la première série, jamais une coupe ;
// - programme PR2 synthétique : lundi de tirage et mardi de poussée servis
//   à toutes leurs lignes écrites ; EMOM, intervalles, douleur, bilan bas :
//   lignes et tours d'accord ; poulie au pas de 2,5 kg ;
// - passage depuis dev7.6.0 sans perte, export / import à l'identique.
//
// Données synthétiques seulement (C17.33.2) ; horloge injectée ; stockage
// simulé ; calculs du moteur sur place.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_adapt/kalis_adapt.dart' as ka;
import 'package:kalis_adapt/koach.dart' as ko;
import 'package:kalis_adapt/koach_textes.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_plan/kalis_plan.dart' as kp;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/koach1/koach1_widgets.dart'
    show debugResetKoachTakeoverWait;
import 'package:streetlift_tracker/koach1/koach_groupes.dart';
import 'package:streetlift_tracker/koach1/koach_moteur.dart';
import 'package:streetlift_tracker/models.dart' show Exercise;
import 'package:streetlift_tracker/store.dart';

import 'kb2c1_fixtures.dart';
import 'support/sha256.dart';

typedef Json = Map<String, Object?>;

/// Section de la sauvegarde exportée.
String _section(AppStore app, String key) =>
    jsonEncode((jsonDecode(app.exportAll()) as Map<String, dynamic>)[key]);

bool _surGrille(double kg, double pas) =>
    ((kg / pas) - (kg / pas).roundToDouble()).abs() < 1e-6;

/// Sonde imprimée (relevé de la livraison).
void _sonde(String nom, Object? v) {
  // ignore: avoid_print
  print('KB5|$nom|${jsonEncode(v)}');
}

/// Koach nu (paramètres et fiches de l'application), comme les tests du
/// paquet (`koach_km6_test.dart`).
ko.Koach _koachNu() => ko.Koach(
  jsonDecode(File(kKoachParamsAsset).readAsStringSync()) as Json,
  ko.lireFichesKoach(File(kKoachFichesAsset).readAsStringSync()),
  <String, Object?>{
    'niveau': 2,
    'sexe': 'male',
    'poids_kg': 75.0,
    'declares': <String, Object?>{},
    'zones_fragiles': <Object?>[],
  },
);

void _debut(ko.Koach k, Json? bilan) => k.observe(<String, Object?>{
  'type': 'seance_debut',
  'jour': 0,
  'bilan': bilan,
  'contexte': <String, Object?>{},
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('paquets et empreintes', () {
    test('Koach 1.0.8 (`kalis_adapt` 1.0.7, paramètres 1.0.8-ref.1, 344 '
        'clés), `kalis_plan` 0.4.3 ; assets copiés à l’octet', () {
      expect(ka.kalisAdaptVersion, '1.0.7');
      expect(kp.kalisPlanVersion, '0.4.3');
      expect(ko.koachVersion, '1.0.8-ref.1');
      expect(ko.koachParametresVersion, '1.0.8-ref.1');
      expect(ko.koachParametresCles, 344);
      expect(kKoachParamsAsset, 'assets/koach/koach_params_1_0_8.json');
      const params =
          '9d74365e58b84fe0e9db7801dd450c053e4ca870184fca5b480b534b116841d1';
      const fiches =
          '99b0cae2d0b29d18d5daa30ee92b91990225124e38e44d522e80e8ae01a196e0';
      expect(ko.koachParametresSha256, params);
      expect(ko.koachFichesSha256, fiches);
      for (final (name, sha) in const [
        ('koach_params_1_0_8.json', params),
        ('vecteurs_qualites_v1.json', fiches),
      ]) {
        final a = File('assets/koach/$name').readAsBytesSync();
        final b = File(
          'packages/kalis_adapt/assets/koach/$name',
        ).readAsBytesSync();
        expect(a, b, reason: name);
        expect(sha256Hex(a), sha, reason: name);
      }
      expect(File('assets/koach/koach_params_1_0_7.json').existsSync(), false);
      final pub = File('pubspec.yaml').readAsStringSync();
      expect(pub, contains('- assets/koach/koach_params_1_0_8.json'));
      expect(pub, isNot(contains('koach_params_1_0_7.json')));
      expect(pub, contains('version: 7.7.2+154'));
      final lock = File('pubspec.lock').readAsStringSync();
      expect(lock, contains('version: "1.0.7"'));
      expect(lock, contains('version: "0.4.3"'));
      final f =
          jsonDecode(
                File(
                  'assets/koach/vecteurs_qualites_v1.json',
                ).readAsStringSync(),
              )
              as Map;
      expect(f['version'], '1.0.1');
    });

    test('crédits « chest » des tirages : `kalis_plan` 0.4.3 (rapport « séries '
        'par groupe », structure de la semaine) et fiches de Koach', () async {
      SharedPreferences.setMockInitialValues({});
      final app = AppStore();
      await app.init();
      final t = kp.CatalogTraits.of(app.content.catalog!);
      int chest(String id) => t.of(id).creditOf(kp.MuscleGroup.chest);
      expect(chest('sl-traction-lestee'), 0);
      expect(chest('mu-tirage-vertical-triangle'), 0);
      expect(chest('sl-muscle-up-leste'), 1); // demi-série
      expect(chest('mu-pull-over-haltere'), 1); // demi-série
      expect(chest('sl-dips-leste'), 2);
      expect(t.of('sl-traction-lestee').creditOf(kp.MuscleGroup.lats), 2);
      // Fiches de Koach : même table (groupe 0 = chest).
      final f =
          jsonDecode(
                File(
                  'assets/koach/vecteurs_qualites_v1.json',
                ).readAsStringSync(),
              )
              as Map;
      expect((f['groupes'] as List).first, 'chest');
      double chestFiche(String id) {
        for (final g
            in ((f['exercices'] as Map)[id] as Map)['groupes'] as List) {
          if ((g as List)[0] == 0) return (g[1] as num).toDouble();
        }
        return 0;
      }

      expect(chestFiche('sl-traction-lestee'), 0);
      expect(chestFiche('sl-muscle-up-leste'), 0.5);
      expect(chestFiche('mu-pull-over-haltere'), 0.5);
      expect(chestFiche('sl-dips-leste'), 1.0);
      await app.flush();
      app.dispose();
    });

    test('poulie sans profil de pas : 2,5 kg dans le moteur (X1) ; la colle '
        'de RV1 donne la même valeur', () {
      final g = ka.LoadGrid.of(kc.LoadType.cable, null);
      expect(g.step, 2.5);
      expect(g.minimum, 2.5);
      final def = withCableIncrement(const []);
      expect(def.single.stepKg, g.step);
      expect(def.single.minKg, g.minimum);
    });
  });

  group('groupes et technique (pures, parité avec le moteur)', () {
    test('règles de `groupesServis` : mêmes valeurs que le test du paquet', () {
      final ecrits = <Json>[
        {'slotId': 'a', 'groupId': 'c', 'sets': 4},
        {'slotId': 'b', 'groupId': 'c', 'sets': 4},
        {'slotId': 'e', 'groupId': 'e', 'sets': 1},
        {'slotId': 'm1', 'groupId': 'm', 'sets': 5},
        {'slotId': 'm2', 'groupId': 'm', 'sets': 5},
        {'slotId': 'x', 'groupId': 'x', 'sets': 3},
        {'slotId': 'k', 'groupId': 'k', 'sets': 6, 'koachVolume': 2},
      ];
      final servis = <Json>[
        {'slotId': 'a', 'groupId': 'c', 'sets': 3},
        {'slotId': 'b', 'groupId': 'c', 'sets': 2},
        {'slotId': 'e', 'groupId': 'e', 'sets': 1},
        {'slotId': 'm1', 'groupId': 'm', 'sets': 4},
        {'slotId': 'm2', 'groupId': 'm', 'sets': 5},
        {'slotId': 'k', 'groupId': 'k', 'sets': 5},
      ];
      final groupes = <Json>[
        {'groupId': 'c', 'format': 'circuit', 'rounds': 4},
        {'groupId': 'e', 'format': 'amrap', 'durationSeconds': 600},
        {
          'groupId': 'm',
          'format': 'emom',
          'intervalSeconds': 60,
          'durationSeconds': 600,
        },
        {'groupId': 'x', 'format': 'superset', 'rounds': 3},
        {
          'groupId': 'k',
          'format': 'intervals',
          'rounds': 4,
          'intervalSeconds': 60,
        },
        {'groupId': 'r', 'format': 'rounds_for_time', 'rounds': 5},
      ];
      expect(koachGroupesServis(groupes, ecrits, servis), [
        {'groupId': 'c', 'format': 'circuit', 'rounds': 3},
        {'groupId': 'e', 'format': 'amrap', 'durationSeconds': 600},
        {
          'groupId': 'm',
          'format': 'emom',
          'intervalSeconds': 60,
          'durationSeconds': 540,
        },
        {
          'groupId': 'k',
          'format': 'intervals',
          'rounds': 5,
          'intervalSeconds': 60,
        },
      ]);
      final deux = koachGroupesServis(
        [
          {'groupId': 'c', 'format': 'circuit', 'rounds': 2},
        ],
        ecrits,
        servis,
      );
      expect(deux[0]['rounds'], 2);
      // E2MOM A/B (durée qui compte les tours) ; contre la montre : le plus
      // petit nombre de séries.
      final ab = koachGroupesServis(
        [
          {
            'groupId': 'g',
            'format': 'emom',
            'rounds': 8,
            'intervalSeconds': 120,
            'durationSeconds': 960,
          },
          {'groupId': 'f', 'format': 'rounds_for_time', 'rounds': 5},
        ],
        [
          {'slotId': 'A', 'groupId': 'g', 'sets': 8},
          {'slotId': 'B', 'groupId': 'g', 'sets': 8},
          {'slotId': 'F1', 'groupId': 'f', 'sets': 5},
          {'slotId': 'F2', 'groupId': 'f', 'sets': 5},
        ],
        [
          {'slotId': 'A', 'groupId': 'g', 'sets': 6},
          {'slotId': 'B', 'groupId': 'g', 'sets': 6},
          {'slotId': 'F1', 'groupId': 'f', 'sets': 4},
          {'slotId': 'F2', 'groupId': 'f', 'sets': 3},
        ],
      );
      expect(ab[0]['rounds'], 6);
      expect(ab[0]['durationSeconds'], 720);
      expect(ab[1]['rounds'], 3);
    });

    Json intervalles(Json? bilan) {
      final k = _koachNu();
      _debut(k, bilan);
      final c = <String, Object?>{
        'horizon': 'seance',
        'items': <Object?>[
          <String, Object?>{
            'slotId': 's1',
            'exerciseId': 'cf-burpee',
            'kind': 'work',
            'sets': 8,
            'secondsLow': 30,
            'secondsHigh': 30,
            'restSeconds': 30,
            'groupId': 'g1',
            'format': 'intervals',
          },
        ],
        'grilles': <String, Object?>{},
        'zones': <String, Object?>{},
        'roles': <String, Object?>{'s1': 'accessory'},
        'groups': <Object?>[
          <String, Object?>{
            'groupId': 'g1',
            'format': 'intervals',
            'rounds': 8,
            'intervalSeconds': 30,
            'restBetweenRoundsSeconds': 30,
          },
        ],
      };
      return {'in': c, 'out': ko.jm(k.plan(c))};
    }

    test('Koach 1.0.8 rend les groupes recalés (X2) ; la règle de '
        'l’application donne les mêmes', () {
      for (final bilan in <Json?>[
        null,
        {'overall': 1},
      ]) {
        final r = intervalles(bilan);
        final c = r['in']! as Json;
        final out = r['out']! as Json;
        final items = [for (final x in out['items']! as List) ko.jm(x)];
        final groups = [for (final x in out['groups']! as List) ko.jm(x)];
        expect(
          koachGroupesServis(
            [for (final x in c['groups']! as List) ko.jm(x)],
            [for (final x in c['items']! as List) ko.jm(x)],
            items,
          ),
          groups,
          reason: '$bilan',
        );
        // Tours = lignes servies (bilan bas : 6 sur 8).
        expect(groups.single['rounds'], items.single['sets']);
        expect(koachGroupesDeSortie(out['groups']), hasLength(1));
      }
      expect(
        ko.jm(ko.jl(ko.jm(intervalles({'overall': 1})['out'])['items'])[0]),
        containsPair('sets', 6),
      );
    });

    test('ligne remplacée par l’application (intervalles tels qu’écrits, '
        'PR8) : groupe recalé sur les lignes servies ; sinon celui du '
        'moteur', () {
      const ecrit = kc.GroupSpec(
        groupId: 'g1',
        format: kc.GroupFormat.intervals,
        rounds: 8,
        intervalSeconds: 30,
        restBetweenRoundsSeconds: 30,
      );
      const moteur = kc.GroupSpec(
        groupId: 'g1',
        format: kc.GroupFormat.intervals,
        rounds: 6,
        intervalSeconds: 30,
        restBetweenRoundsSeconds: 30,
      );
      final w = <String, Object?>{
        'slotId': 's1',
        'exerciseId': 'cf-burpee',
        'kind': 'work',
        'sets': 8,
        'secondsLow': 30,
        'secondsHigh': 30,
        'restSeconds': 30,
        'groupId': 'g1',
      };
      final ligneEcrite = kc.ExercisePrescription.fromJson({
        ...w,
        'toCalibrate': false,
        'loadBasis': 'unloaded',
        'reasons': <Object?>[],
      });
      // Servie telle qu'écrite (8) : groupe recalé à 8 tours.
      final a = koachGroupesDeLaSeance([ecrit], [moteur], [w], [ligneEcrite]);
      expect(a.groupes!.single.rounds, 8);
      expect(a.recales, ['g1']);
      // Servie par Koach (6) : le groupe du moteur.
      final b = koachGroupesDeLaSeance(
        [ecrit],
        [moteur],
        [w],
        [ligneEcrite.copyWith(sets: 6)],
      );
      expect(identical(b.groupes!.single, moteur), isTrue);
      expect(b.recales, isEmpty);
      // Groupe sans membre servi : plus déclaré ; sans groupes écrits : rien.
      expect(
        koachGroupesDeLaSeance([ecrit], [moteur], [w], const []).groupes,
        isEmpty,
      );
      expect(
        koachGroupesDeLaSeance(null, null, [w], [ligneEcrite]).groupes,
        isNull,
      );
    });

    test('technique cohérente avec les séries (X3, sécurité)', () {
      final base = kc.ExercisePrescription.fromJson({
        'slotId': 's1',
        'exerciseId': 'sl-dips-leste',
        'kind': 'work',
        'sets': 9,
        'repsLow': 3,
        'repsHigh': 3,
        'restSeconds': 0,
        'toCalibrate': false,
        'loadBasis': 'external',
        'reasons': <Object?>[],
        'technique': {'kind': 'emom', 'intervalSeconds': 60, 'intervals': 10},
      });
      expect(base.validate(), isNotEmpty);
      final ok = koachTechniqueCoherente(base);
      expect(ok.technique!.intervals, 9);
      expect(ok.validate(), isEmpty);
      expect(identical(koachTechniqueCoherente(ok), ok), isTrue);
      // Série de tête et séries allégées : allégées < séries.
      final top = base.copyWith(
        sets: 3,
        technique: const kc.SetTechnique(
          kind: kc.SetTechniqueKind.topSetBackoff,
          backoffSets: 4,
        ),
      );
      expect(koachTechniqueCoherente(top).technique!.backoffSets, 2);
      // Pyramide qui ne tient plus : séries classiques.
      final pyr = base.copyWith(
        sets: 3,
        technique: const kc.SetTechnique(
          kind: kc.SetTechniqueKind.pyramid,
          pyramidReps: [5, 3, 1, 3, 5],
        ),
      );
      expect(koachTechniqueCoherente(pyr).technique, isNull);
      // Moteur 1.0.8 : EMOM dont il baisse les séries (bilan très bas).
      final k = _koachNu();
      _debut(k, {'overall': 1});
      final ecrit = <String, Object?>{
        'slotId': 's1',
        'exerciseId': 'sl-dips-leste',
        'kind': 'work',
        'sets': 10,
        'repsLow': 3,
        'repsHigh': 3,
        'targetFlames': 6,
        'restSeconds': 0,
        'technique': <String, Object?>{
          'kind': 'emom',
          'intervalSeconds': 60,
          'intervals': 10,
        },
      };
      final r = ko.jm(
        k.plan({
          'horizon': 'seance',
          'items': [ecrit],
          'grilles': <String, Object?>{},
          'zones': <String, Object?>{},
          'roles': <String, Object?>{'s1': 'main'},
        }),
      );
      final it = ko.jm(ko.jl(r['items'])[0]);
      expect(ko.jm(it['technique'])['intervals'], it['sets']);
    });

    test('`koach.volume_semaine` : texte de 1.0.8, raison de structure, '
        'jamais une coupe pour la garde', () {
      final r = <String, Object?>{
        'code': 'koach.volume_semaine',
        'params': {
          'exercice': 'mu-rowing-barre',
          'series': 2,
          'ecrites': 3,
          'cause': 'planification',
        },
      };
      expect(koachCodesRaisons, contains('koach.volume_semaine'));
      final t = texteRaisonKoach(r, nomExercice: (_) => 'Rowing barre');
      expect(
        t,
        'Cette semaine, je te propose 2 séries sur « Rowing barre » au lieu '
        'des 3 écrites : je répartis l’effort de la semaine d’après ta '
        'récupération prévue.',
      );
      expect(kKoachRaisonsDeSeance, contains('koach.volume_semaine'));
      // Ligne absente du servi avec cette seule raison : servie telle
      // qu'écrite (jamais un retrait motivé).
      final g = koachGardeSeance(
        [
          {'slotId': 'a', 'exerciseId': 'mu-rowing-barre', 'sets': 3},
        ],
        const [],
        [r],
      );
      expect(g.retraits, isEmpty);
      expect(g.ecrites.single['cause'], 'koach.volume_semaine');
    });
  });

  group('programme PR2 synthétique (Koach 1.0.8)', () {
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

    /// Prise de main au lundi S15, trois semaines d'historique (S12 à S14).
    Future<void> activate() async {
      await importPr2Nouveau(app, firstWeek: 12);
      app.koachNoteInstall();
      await app.koachRefresh();
      expect(
        app.koachEngine.fromWeek,
        15,
        reason: '${app.koachEngine.blocked}',
      );
    }

    /// Ouvre la séance S15·J[j] au jour J[j] (bilan [check]) et la fait
    /// servir par Koach.
    Future<void> ouvrir(int j, {kc.HealthCheck? check}) async {
      clock = DateTime(2026, 10, 18 + j, 7);
      await app.koachRefresh();
      final base = app.program.week(15).day(j)!;
      expect(app.adaptOpen(15, base)?.koach?['state'], 'preview');
      if (check != null) app.adaptAnswer(15, base, check);
      expect(await app.koachStart(15, base), isTrue, reason: 'J$j');
    }

    /// Valide toutes les séries de la séance servie S15·J[j] (reps
    /// pré-remplies, 8 flammes), puis la marque faite.
    void doAll(int j) {
      final base = app.program.week(15).day(j)!;
      final a = app.sessionAdapt(15, j);
      final day = a == null ? base : app.adaptDay(15, base, a);
      for (final e in day.exercises) {
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

    /// Séance servie S15·J[j] : plan lisible ; intervalles d'un EMOM =
    /// séries ; chaque groupe déclaré a un membre servi, chaque membre son
    /// groupe ; tours (et durée d'un EMOM au temps) recalés sur les lignes
    /// servies quand l'écrit les comptait. Rend un relevé.
    Map<String, Object?> coherente(int j) {
      final a = app.sessionAdapt(15, j)!;
      final st = a.koach!;
      expect(st['state'], 'open', reason: 'J$j');
      expect(st['invalide'], isNull, reason: 'J$j ${st['invalide']}');
      final plan = a.plan;
      expect(plan.validate(), isEmpty, reason: 'J$j');
      for (final it in plan.items) {
        final t = it.technique;
        if (t?.kind == kc.SetTechniqueKind.emom && t?.intervals != null) {
          expect(t!.intervals, it.sets, reason: 'J$j ${it.slotId}');
        }
      }
      final ecrit = app.adaptPlaceOf(15, j)!.day!;
      final declares = {for (final g in plan.groups ?? const []) g.groupId};
      for (final it in plan.items) {
        if (it.groupId == null) continue;
        expect(declares, contains(it.groupId), reason: 'J$j ${it.slotId}');
      }
      final relev = <String, Object?>{};
      for (final g in plan.groups ?? const <kc.GroupSpec>[]) {
        final membres = [
          for (final it in plan.items)
            if (it.groupId == g.groupId) it,
        ];
        expect(membres, isNotEmpty, reason: 'J$j ${g.groupId}');
        final gw = ecrit.groups!.firstWhere((x) => x.groupId == g.groupId);
        final membresE = [
          for (final it in ecrit.items)
            if (it.groupId == g.groupId) it,
        ];
        final auMoins = g.format == kc.GroupFormat.roundsForTime;
        int choix(Iterable<int> v) =>
            v.reduce((x, y) => auMoins ? (x < y ? x : y) : (x > y ? x : y));
        final nE = choix(membresE.map((x) => x.sets));
        final nS = choix(membres.map((x) => x.sets));
        if (gw.rounds != null && gw.rounds == nE) {
          expect(g.rounds, nS, reason: 'J$j ${g.groupId}');
        } else {
          expect(g.rounds, gw.rounds, reason: 'J$j ${g.groupId}');
        }
        final iv = gw.intervalSeconds;
        if (g.format == kc.GroupFormat.emom &&
            iv != null &&
            iv > 0 &&
            gw.durationSeconds != null) {
          final totE = membresE.fold<int>(0, (s, x) => s + x.sets);
          final totS = membres.fold<int>(0, (s, x) => s + x.sets);
          if (gw.durationSeconds == iv * totE) {
            expect(g.durationSeconds, iv * totS, reason: 'J$j ${g.groupId}');
          } else if (gw.rounds != null &&
              gw.durationSeconds == iv * gw.rounds!) {
            expect(
              g.durationSeconds,
              iv * g.rounds!,
              reason: 'J$j ${g.groupId}',
            );
          }
        }
        relev[g.groupId] = {
          'format': g.format.code,
          'tours': g.rounds,
          'duree': g.durationSeconds,
          'lignes': [for (final x in membres) x.sets],
        };
      }
      relev['recales'] = st['groupesRecales'];
      return relev;
    }

    /// Séries servies et écrites par emplacement de la séance ouverte.
    ({Map<String, int> servis, Map<String, int> ecrites, Map st}) etat(int j) {
      final st = app.sessionAdapt(15, j)!.koach!;
      final servis = <String, int>{
        for (final x in st['items'] as List)
          '${(x as Map)['slotId']}': (x['sets'] as num).round(),
      };
      final ecrites = <String, int>{
        for (final x in app.koachJourInfo(15, j)!.items)
          '${x['slotId']}': (x['sets'] as num).round(),
      };
      return (servis: servis, ecrites: ecrites, st: st);
    }

    test('lundi de tirage et mardi de poussée servis à toutes leurs lignes '
        'écrites (une baisse de la semaine serait dite) ; groupes '
        'cohérents', () async {
      await activate();
      final relev = <String, Object?>{};
      for (final j in const [1, 2]) {
        final sw = Stopwatch()..start();
        await ouvrir(j);
        final ms = sw.elapsedMicroseconds / 1000;
        final e = etat(j);
        final base = app.program.week(15).day(j)!;
        final a = app.sessionAdapt(15, j)!;
        final shown = app.adaptDay(15, base, a).exercises;
        final raisons = [
          for (final r in e.st['raisons'] as List)
            (r as Map).cast<String, Object?>(),
        ];
        relev['J$j'] = {
          'servis': e.servis,
          'ecrites': e.ecrites,
          'garde': e.st['garde'],
          'retraits': e.st['retraits'],
          'raisons': [for (final r in raisons) texteRaisonKoach(r)],
          'cartes': [
            for (final x in shown) '${x.catalogId}:${app.setsLabel(x)}',
          ],
          'entete': app.koachSessionReasons(15, j, max: 9),
          'groupes': coherente(j),
          'temps_ms': ms,
        };
        expect((e.st['retraits'] as List?) ?? const [], isEmpty);
        expect(e.st['garde'], isNull, reason: 'J$j ${e.st['garde']}');
        // Chaque ligne écrite servie ; sous l'écrit seulement avec la
        // raison de la modulation de la semaine sur son exercice.
        for (final x in e.ecrites.entries) {
          final n = e.servis[x.key];
          expect(n, isNotNull, reason: 'J$j ${x.key}');
          if (n! >= x.value) continue;
          final ex = app
              .koachJourInfo(15, j)!
              .items
              .firstWhere((it) => it['slotId'] == x.key)['exerciseId'];
          expect(
            raisons.any(
              (r) =>
                  r['code'] == 'koach.volume_semaine' &&
                  (r['params'] as Map?)?['exercice'] == ex,
            ),
            isTrue,
            reason: 'J$j ${x.key} $n < ${x.value}',
          );
        }
        expect(
          [for (final x in shown) x.catalogId],
          [for (final x in base.exercises) x.catalogId],
        );
        expect(
          app
              .koachSessionReasons(15, j, max: 9)
              .where((t) => t.startsWith('Je retire')),
          isEmpty,
        );
        doAll(j);
        expect(app.koachEngine.versed, contains(app.sessionKey(15, j)));
      }
      _sonde('scenario', relev);
      final j2 = (relev['J2'] as Map)['cartes'] as List;
      for (final c in const [
        'sl-dips-leste:8×3 · E2MOM',
        'sw-traction-pronation:',
        'sl-pompe-lestee-gilet:',
        'mu-developpe-militaire-barre-debout:',
        'mu-rotation-externe-haltere-couche:',
        'mu-pushdown-corde:',
        'mu-elevation-laterale-halteres:',
      ]) {
        expect(j2.any((x) => '$x'.startsWith(c)), isTrue, reason: c);
      }
    });

    test('mardi, douleur à l’épaule : conduite sous douleur, groupes '
        'cohérents (groupe sans membre retiré)', () async {
      await activate();
      await ouvrir(
        2,
        check: const kc.HealthCheck(
          pains: [
            kc.PainReport(
              zone: kc.BodyZone.shoulder,
              side: kc.BodySide.both,
              intensity: 5,
              phase: kc.PainPhase.before,
            ),
          ],
        ),
      );
      final e = etat(2);
      for (final x in (e.st['retraits'] as List?) ?? const []) {
        expect((x as Map)['code'], 'koach.douleur_retrait', reason: '$x');
      }
      _sonde('douleur_j2', {
        'servis': e.servis,
        'retraits': e.st['retraits'],
        'groupes': coherente(2),
      });
    });

    test('mercredi, bilan bas : E3MOM et intervalles d’accord avec leurs '
        'lignes ; intervalles servis tels qu’écrits (C17.44.4)', () async {
      await activate();
      await ouvrir(
        3,
        check: const kc.HealthCheck(overall: 1, sleepQuality: 1, energy: 1),
      );
      final relev = coherente(3);
      final a = app.sessionAdapt(15, 3)!;
      final ecrit = app.adaptPlaceOf(15, 3)!.day!;
      final iv = ecrit.groups!.firstWhere(
        (g) => g.format == kc.GroupFormat.intervals,
      );
      final g = a.plan.groups!.firstWhere((x) => x.groupId == iv.groupId);
      final ligne = a.plan.items.firstWhere((x) => x.groupId == iv.groupId);
      expect(ligne.sets, 8);
      expect(g.rounds, 8);
      expect(g.intervalSeconds, 30);
      _sonde('bilan_bas_j3', relev);
    });

    test('jeudi : EMOM minute par minute et contraste E2MOM d’accord avec '
        'leurs lignes', () async {
      await activate();
      await ouvrir(4);
      final relev = coherente(4);
      final cartes = [
        for (final x
            in app
                .adaptDay(
                  15,
                  app.program.week(15).day(4)!,
                  app.sessionAdapt(15, 4)!,
                )
                .exercises)
          app.setsLabel(x),
      ];
      _sonde('emom_j4', {'groupes': relev, 'cartes': cartes});
    });

    test('samedi, bilan bas : intervalles « 6× (40 s / 20 s) » tels '
        'qu’écrits, tours = lignes', () async {
      await activate();
      await ouvrir(
        6,
        check: const kc.HealthCheck(overall: 1, sleepQuality: 1, energy: 1),
      );
      final relev = coherente(6);
      final a = app.sessionAdapt(15, 6)!;
      final iv = app
          .adaptPlaceOf(15, 6)!
          .day!
          .groups!
          .firstWhere((g) => g.format == kc.GroupFormat.intervals);
      final g = a.plan.groups!.firstWhere((x) => x.groupId == iv.groupId);
      final ligne = a.plan.items.firstWhere((x) => x.groupId == iv.groupId);
      expect(ligne.sets, 6);
      expect(g.rounds, 6);
      _sonde('bilan_bas_j6', relev);
    });

    test('raison `koach.volume_semaine` sur une semaine modulée : en tête de '
        'séance et sur la carte, gardée après la première série ; pas en '
        'tête pour une ligne au départ chronométré servie telle '
        'qu’écrite', () async {
      await activate();
      await ouvrir(1);
      final base = app.program.week(15).day(1)!;
      final a = app.sessionAdapt(15, 1)!;
      final shown = app.adaptDay(15, base, a).exercises;
      final libre = shown.firstWhere(
        (x) => x.engine && !app.adaptAsWritten(15, x.slotId),
      );
      String? slotDe(Exercise x) => x.slotId ?? app.adaptSlotOf(15, 1, x.id);
      final pr8 = shown.firstWhere((x) => app.adaptAsWritten(15, slotDe(x)));
      final ecrites = {
        for (final x in app.koachJourInfo(15, 1)!.items)
          '${x['slotId']}': (x['sets'] as num).round(),
      };
      Json raison(String ex, int series, int ecr) => {
        'code': 'koach.volume_semaine',
        'params': {
          'exercice': ex,
          'series': series,
          'ecrites': ecr,
          'cause': 'planification',
        },
      };
      final nLibre = ecrites[libre.slotId]!;
      final nPr8 = ecrites[slotDe(pr8)]!;
      final rLibre = raison(libre.catalogId!, nLibre - 1, nLibre);
      final rPr8 = raison(pr8.catalogId!, nPr8 - 1, nPr8);
      void poser(List<Json> raisons, List<Json> ouverture) {
        final now = app.sessionAdapt(15, 1)!;
        app.sessionLog(15, 1).adapt = now
            .copyWith(
              koach: {
                ...now.koach!,
                'raisons': raisons,
                'ouverture': ouverture,
              },
            )
            .toJson()
            .cast<String, dynamic>();
      }

      poser([rLibre, rPr8], [rLibre, rPr8]);
      String texte(Json r) =>
          texteRaisonKoach(r, nomExercice: (x) => app.content.byId[x]?.nom);
      final entete = app.koachSessionReasons(15, 1, max: 9);
      expect(entete, contains(texte(rLibre)));
      expect(entete, isNot(contains(texte(rPr8))));
      expect(app.koachReasonLine(15, 1, libre), texte(rLibre));
      // Après la première série (`plan(serie)` remplace les raisons) : la
      // carte la garde (raison de structure de l'ouverture).
      poser(const [], [rLibre, rPr8]);
      expect(app.koachReasonLine(15, 1, libre), texte(rLibre));
      expect(app.koachSessionReasons(15, 1, max: 9), contains(texte(rLibre)));
      // Ligne au départ chronométré servie telle qu'écrite : sa carte dit
      // ce que Koach aurait fait, la ligne garde ses séries écrites.
      expect(
        app.koachReasonLine(15, 1, pr8),
        koachTexteEcartEcrit(nPr8 - 1, nPr8),
      );
      _sonde('volume_semaine', {
        'libre': libre.catalogId,
        'pr8': pr8.catalogId,
        'entete': entete,
        'carte_pr8': app.koachReasonLine(15, 1, pr8),
      });
    });

    test('extension triceps poulie servie au pas de 2,5 kg, comme '
        'l’aperçu', () async {
      await activate();
      clock = DateTime(2026, 10, 20, 7);
      await app.koachRefresh();
      final base = app.program.week(15).day(2)!;
      final ap = app.adaptOpen(15, base)!;
      expect(ap.koach?['state'], 'preview');
      // Aperçu (avant le début réel) : charge de départ de la ligne.
      final avant = ap.plan.items
          .where((x) => x.exerciseId == 'mu-pushdown-corde')
          .firstOrNull
          ?.startLoadKg;
      expect(await app.koachStart(15, base), isTrue);
      final a = app.sessionAdapt(15, 2)!;
      final e = app
          .adaptDay(15, base, a)
          .exercises
          .firstWhere((x) => x.catalogId == 'mu-pushdown-corde');
      app.exLog(15, 2, e);
      app.koachEnsureTarget(15, base, e, 0);
      final servi = app.adaptGoal(15, 2, e, 0)?.kg;
      _sonde('poulie', {'apercu': avant, 'servi': servi});
      expect(servi, isNotNull);
      expect(_surGrille(servi!, 2.5), isTrue, reason: '$servi');
      if (avant != null && avant > 0) {
        expect(_surGrille(avant, 2.5), isTrue, reason: '$avant');
      }
    });

    test('passage depuis dev7.6.0 (prise de main 1.0.7) sans perte ; '
        'sauvegarde réimportée à l’identique', () async {
      await activate();
      await ouvrir(1);
      doAll(1);
      for (var i = 0; i < 200; i++) {
        if (app.sessionAdapt(15, 1)?.koach?['prevision'] != null) break;
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      await app.flush();
      final doc = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      final engine = (doc['koachEngine'] as Map).cast<String, dynamic>();
      final snap = (engine['snap'] as Map).cast<String, dynamic>();
      snap['version_moteur'] = '1.0.7-ref.1';
      snap['version_parametres'] = '1.0.7-ref.1';
      snap['sha256_parametres'] =
          '2f055c5181743089afd0c3602bc270f77b01063ebc1bab32b293c81c6816f42c';
      engine['snap'] = snap;
      doc['koachEngine'] = engine;
      final text = jsonEncode(doc);
      app.dispose();
      await fresh();
      expect(await app.importAll(text), isTrue);
      final logs = _section(app, 'logs');
      final instance = _section(app, 'programInstance');
      final origin = _section(app, 'programOrigin');
      final journal = [for (final x in app.koachEngine.journal) jsonEncode(x)];
      expect(app.programOrigin, isNotNull);
      // Mardi : premier lancement de dev7.7.0.
      clock = DateTime(2026, 10, 20, 7);
      app.koachNoteInstall();
      await app.koachRefresh();
      final e = app.koachEngine;
      expect(e.fromWeek, 15);
      expect(e.snap!.versionMoteur, '1.0.7-ref.1');
      expect(app.koachLive!.params['version'], '1.0.8-ref.1');
      expect(_section(app, 'logs'), logs);
      expect(_section(app, 'programInstance'), instance);
      expect(_section(app, 'programOrigin'), origin);
      for (var i = 0; i < journal.length; i++) {
        expect(jsonEncode(e.journal[i]), journal[i], reason: 'événement $i');
      }
      // J2 servie par 1.0.8 avec ses groupes.
      final j2 = app.program.week(15).day(2)!;
      expect(app.adaptOpen(15, j2)?.koach?['state'], 'preview');
      expect(await app.koachStart(15, j2), isTrue);
      coherente(2);
      // Sauvegarde exportée puis réimportée à l'identique.
      final out1 = app.exportAll();
      final keys = (jsonDecode(out1) as Map<String, dynamic>).keys.toList();
      expect(await app.importAll(out1), isTrue);
      for (final k in keys) {
        if (k == 'exportedAt' || k == 'savedAt') continue;
        expect(
          _section(app, k),
          jsonEncode((jsonDecode(out1) as Map)[k]),
          reason: k,
        );
      }
    });
  });
}
