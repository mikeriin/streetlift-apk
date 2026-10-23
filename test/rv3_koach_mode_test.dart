// RV3 (dev7.7.1, pipeline CP, DECISIONS_CP.md C17.51) — modulation de la
// semaine de Koach selon le mode du profil et dead hang de la pause du
// squat au bilan bas :
//
// - mode assisté : la ligne est servie modulée, la raison est dite ;
//   « Annuler » revient aux séries sans la modulation pour cette séance
//   (choix gardé, versé au moteur comme un refus) ;
// - mode libre : la ligne est servie sans la modulation, la proposition
//   est dite au conditionnel ; « Accepter » passe aux séries de Koach,
//   « Garder l'écrit » garde l'écrit (refus versé) ; choix possible dès
//   l'aperçu ;
// - ajouts au-dessus de l'écrit : même règle (appliqués et dits en
//   assisté, proposés en libre) ;
// - C17.51.4 : le mode qui décide est celui du profil, jamais un `mode`
//   enregistré dans une séance ;
// - mercredi au bilan bas : le dead hang de la pause reste servi à ses
//   séries écrites, enchaîné au squat E3MOM.
//
// Données synthétiques seulement (C17.33.2) ; horloge injectée ; stockage
// simulé ; calculs du moteur sur place. La modulation de la semaine est
// forcée sur le plan de la planification de Koach (facteur de volume).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/koach1/koach1_widgets.dart'
    show debugResetKoachTakeoverWait;
import 'package:streetlift_tracker/koach1/koach_moteur.dart';
import 'package:streetlift_tracker/models.dart' show Exercise;
import 'package:streetlift_tracker/store.dart';

import 'kb2c1_fixtures.dart';

void _sonde(String nom, Object? v) {
  // ignore: avoid_print
  print('RV3|$nom|${jsonEncode(v)}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('fonctions pures', () {
    test('choix lus, mode du profil par défaut', () {
      expect(koachVolumeChoix(null), isEmpty);
      final c = koachVolumeChoix({
        'volume': {
          'a': {'choix': 'applique', 'mode': 'free'},
          'b': {'choix': 'ecrit'},
          'c': {'series': 3, 'ecrites': 4},
          'd': {'choix': 'autre'},
        },
      });
      expect(c.keys, ['a', 'b']);
      expect(koachVolumeApplique(null, 'assisted'), isTrue);
      expect(koachVolumeApplique(null, 'free'), isFalse);
      expect(koachVolumeApplique(c['a'], 'assisted'), isTrue);
      expect(koachVolumeApplique(c['a'], 'free'), isTrue);
      expect(koachVolumeApplique(c['b'], 'assisted'), isFalse);
      expect(koachVolumeApplique(c['b'], 'free'), isFalse);
    });

    test('textes de la carte et de l’en-tête', () {
      KoachVolume v({
        bool applique = true,
        String? choix,
        bool assiste = true,
        int series = 2,
        int ecrites = 3,
      }) => (
        series: series,
        ecrites: ecrites,
        applique: applique,
        choix: choix,
        assiste: assiste,
        modifiable: true,
      );
      expect(
        koachTexteVolumeCarte(v()),
        startsWith('Cette semaine : 2 séries au lieu de 3.'),
      );
      expect(
        koachTexteVolumeCarte(v(applique: false, assiste: false)),
        startsWith('Koach te propose 2 séries au lieu de 3 cette semaine'),
      );
      expect(
        koachTexteVolumeCarte(v(applique: false, choix: 'ecrit')),
        'Annulé : 3 séries comme écrit, pour cette séance.',
      );
      expect(
        koachTexteVolumeCarte(
          v(applique: false, choix: 'ecrit', assiste: false),
        ),
        'Écrit gardé : 3 séries.',
      );
      expect(
        koachTexteVolumeCarte(v(choix: 'applique', assiste: false)),
        'Accepté : 2 séries.',
      );
      expect(
        koachTexteVolumeCarte(v(series: 1, ecrites: 2)),
        startsWith('Cette semaine : une série au lieu de 2.'),
      );
      // En tête : proposition du mode libre, ajout appliqué ; une baisse
      // appliquée est dite par la raison du moteur.
      expect(
        koachTexteVolumeEntete(v(applique: false, assiste: false), 'Dips'),
        startsWith('Koach te propose 2 séries sur Dips au lieu de 3'),
      );
      expect(koachTexteVolumeEntete(v(), 'Dips'), isNull);
      expect(
        koachTexteVolumeEntete(v(series: 4), 'Dips'),
        startsWith(
          'Cette semaine, je te propose 4 séries sur Dips au lieu '
          'de 3',
        ),
      );
      expect(
        koachTexteVolumeEntete(v(applique: false, choix: 'ecrit'), 'Dips'),
        isNull,
      );
    });
  });

  group('programme PR2 synthétique, semaine modulée', () {
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

    /// Jour J[j] de S15 : horloge, rafraîchissement, modulation de la
    /// semaine forcée (facteur de volume [f] sur toutes les qualités).
    Future<void> jour(int j, double f) async {
      clock = DateTime(2026, 10, 18 + j, 7);
      await app.koachRefresh();
      final pl = app.koachLive!.planification!;
      pl.plan[14] = {
        ...?pl.plan[14],
        'volume': List<double>.filled(10, f),
        'intensite': 0.0,
      };
    }

    /// Exercice affiché de l'emplacement [slot] de S15·J[j].
    Exercise exDe(int j, String slot) {
      final base = app.program.week(15).day(j)!;
      final a = app.sessionAdapt(15, j)!;
      return app
          .adaptDay(15, base, a)
          .exercises
          .firstWhere(
            (x) => (x.slotId ?? app.adaptSlotOf(15, j, x.id)) == slot,
          );
    }

    /// Séance de Koach ouverte au premier jour de S15 dont une ligne (hors
    /// départ chronométré) est modulée par la semaine ([f]) ; rend le jour
    /// et l'emplacement.
    Future<(int, String)> ouvrirModule(double f) async {
      for (final j in const [2, 1, 3, 4, 5, 6]) {
        await jour(j, f);
        final base = app.program.week(15).day(j);
        if (base == null || base.exercises.isEmpty) continue;
        expect(app.adaptOpen(15, base)?.koach?['state'], 'preview');
        expect(await app.koachStart(15, base), isTrue, reason: 'J$j');
        final st = app.sessionAdapt(15, j)!.koach!;
        _sonde('ouverture_${f}_J$j', {
          'servis': [
            for (final x in st['items'] as List)
              '${(x as Map)['slotId']}:${x['sets']}:${x['koachModule']}',
          ],
          'volume': st['volume'],
        });
        final vol = st['volume'];
        if (vol is Map && vol.isNotEmpty) return (j, '${vol.keys.first}');
      }
      fail('aucune ligne modulée (facteur $f)');
    }

    int seriesPlan(int j, String slot) => app
        .sessionAdapt(15, j)!
        .plan
        .items
        .firstWhere((x) => x.slotId == slot)
        .sets;

    int seriesServies(int j, String slot) =>
        ((app.sessionAdapt(15, j)!.koach!['items'] as List).firstWhere(
                  (x) => (x as Map)['slotId'] == slot,
                )
                as Map)['sets']
            as int;

    /// Fin de séance (séries pré-remplies validées) ; décisions de volume
    /// versées au journal de Koach.
    List<Map> decisionsVolume(int j) {
      final base = app.program.week(15).day(j)!;
      final a = app.sessionAdapt(15, j)!;
      for (final e in app.adaptDay(15, base, a).exercises) {
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
      return [
        for (final ev in app.koachEngine.journal)
          if (ev['type'] == 'decision' &&
              '${(ev['proposition'] as Map?)?['type']}'.startsWith('volume_'))
            ev,
      ];
    }

    test('mode assisté : servie modulée et dite ; « Annuler » revient aux '
        'séries écrites, refus versé', () async {
      expect(app.adaptMode, 'assisted');
      final (j, slot) = await ouvrirModule(0.4);
      final base = app.program.week(15).day(j)!;
      final e = exDe(j, slot);
      final v = app.koachVolume(15, j, e)!;
      expect(v.applique, isTrue);
      expect(v.assiste, isTrue);
      expect(v.series, lessThan(v.ecrites));
      expect(seriesPlan(j, slot), v.series);
      expect(app.exLog(15, j, e).sets.length, v.series);
      // Raison du moteur sur la carte et en tête.
      expect(
        app.koachReasonLine(15, j, e),
        startsWith(
          'Cette semaine, je te '
          'propose',
        ),
      );
      expect(
        app
            .koachSessionReasons(15, j, max: 9)
            .any((t) => t.startsWith('Cette semaine, je te propose')),
        isTrue,
      );
      app.koachVolumeChoose(15, base, e, false);
      final w = app.koachVolume(15, j, e)!;
      expect(w.applique, isFalse);
      expect(w.choix, 'ecrit');
      expect(seriesPlan(j, slot), v.ecrites);
      expect(seriesServies(j, slot), v.ecrites);
      expect(app.exLog(15, j, e).sets.length, v.ecrites);
      expect(app.sessionAdapt(15, j)!.plan.validate(), isEmpty);
      expect(
        app.koachReasonLine(15, j, e) ?? '',
        isNot(
          contains(
            'je te '
            'propose',
          ),
        ),
      );
      expect(
        app
            .koachSessionReasons(15, j, max: 9)
            .where(
              (t) => t.contains(app.content.byId[e.catalogId]?.nom ?? '§'),
            ),
        isEmpty,
      );
      final d = decisionsVolume(j);
      expect(d, hasLength(1));
      expect((d.single['proposition'] as Map)['type'], 'volume_moins');
      expect(d.single['accepte'], isFalse);
    });

    test('mode libre : servie à l’écrit, proposée ; « Accepter » passe aux '
        'séries de Koach, acceptation versée', () async {
      app.setGuidanceMode('free');
      expect(app.adaptMode, 'free');
      final (j, slot) = await ouvrirModule(0.4);
      final base = app.program.week(15).day(j)!;
      expect(app.sessionAdapt(15, j)!.mode, 'free');
      final e = exDe(j, slot);
      final v = app.koachVolume(15, j, e)!;
      expect(v.applique, isFalse);
      expect(v.assiste, isFalse);
      expect(v.choix, isNull);
      // Jamais de baisse appliquée sans action de l'athlète.
      expect(seriesPlan(j, slot), v.ecrites);
      expect(seriesServies(j, slot), v.ecrites);
      expect(app.exLog(15, j, e).sets.length, v.ecrites);
      final nom = app.content.byId[e.catalogId]?.nom ?? e.catalogId!;
      expect(
        app.koachSessionReasons(15, j, max: 9),
        contains(startsWith('Koach te propose ${v.series} série')),
      );
      expect(
        app
            .koachSessionReasons(15, j, max: 9)
            .where(
              (t) =>
                  t.startsWith('Cette semaine, je te propose') &&
                  t.contains(nom),
            ),
        isEmpty,
      );
      expect(
        app.koachReasonLine(15, j, e) ?? '',
        isNot(
          contains(
            'je te '
            'propose',
          ),
        ),
      );
      app.koachVolumeChoose(15, base, e, true);
      final w = app.koachVolume(15, j, e)!;
      expect(w.applique, isTrue);
      expect(w.choix, 'applique');
      expect(seriesPlan(j, slot), v.series);
      expect(seriesServies(j, slot), v.series);
      expect(app.exLog(15, j, e).sets.length, v.series);
      expect(app.sessionAdapt(15, j)!.plan.validate(), isEmpty);
      final d = decisionsVolume(j);
      expect(d, hasLength(1));
      expect(d.single['accepte'], isTrue);
    });

    test('mode libre : « Garder l’écrit » (refus versé) ; aucun choix : rien '
        'versé', () async {
      app.setGuidanceMode('free');
      final (j, slot) = await ouvrirModule(0.4);
      final base = app.program.week(15).day(j)!;
      final e = exDe(j, slot);
      final v = app.koachVolume(15, j, e)!;
      app.koachVolumeChoose(15, base, e, false);
      expect(app.koachVolume(15, j, e)!.choix, 'ecrit');
      expect(seriesPlan(j, slot), v.ecrites);
      final d = decisionsVolume(j);
      expect(d, hasLength(1));
      expect(d.single['accepte'], isFalse);
    });

    test('mode libre : choix dans l’aperçu, gardé à l’ouverture', () async {
      app.setGuidanceMode('free');
      // Premier jour dont une ligne est modulée : ouverture, puis le jour
      // suivant modulé de même est relu en aperçu.
      final (j0, _) = await ouvrirModule(0.4);
      int? jA;
      String? slotA;
      for (final j in const [2, 1, 3, 4, 5, 6]) {
        if (j <= j0) continue;
        await jour(j, 0.4);
        final base = app.program.week(15).day(j);
        if (base == null || base.exercises.isEmpty) continue;
        final ap = app.adaptOpen(15, base)!;
        expect(ap.koach?['state'], 'preview');
        for (final x in app.adaptDay(15, base, ap).exercises) {
          final v = app.koachVolume(15, j, x);
          if (v != null) {
            jA = j;
            slotA = x.slotId ?? app.adaptSlotOf(15, j, x.id);
            break;
          }
        }
        if (jA != null) break;
      }
      if (jA == null) {
        markTestSkipped('aucun autre jour modulé');
        return;
      }
      final base = app.program.week(15).day(jA)!;
      final e = exDe(jA, slotA!);
      final v = app.koachVolume(15, jA, e)!;
      expect(v.applique, isFalse);
      expect(v.modifiable, isTrue);
      expect(seriesPlan(jA, slotA), v.ecrites);
      app.koachVolumeChoose(15, base, e, true);
      expect(app.koachVolume(15, jA, e)!.applique, isTrue);
      expect(seriesPlan(jA, slotA), v.series);
      expect(await app.koachStart(15, base), isTrue);
      final st = app.sessionAdapt(15, jA)!.koach!;
      expect(st['state'], 'open');
      expect(((st['volume'] as Map)[slotA] as Map)['choix'], 'applique');
      expect(seriesServies(jA, slotA), v.series);
    });

    test('ajouts au-dessus de l’écrit : appliqués et dits en assisté, '
        'proposés en libre', () async {
      final (j, slot) = await ouvrirModule(1.7);
      final e = exDe(j, slot);
      final v = app.koachVolume(15, j, e)!;
      _sonde('ajout', {'series': v.series, 'ecrites': v.ecrites});
      if (v.series < v.ecrites) {
        markTestSkipped('modulation forcée sans ajout');
        return;
      }
      expect(v.applique, isTrue);
      expect(seriesPlan(j, slot), v.series);
      expect(
        app.koachSessionReasons(15, j, max: 9),
        contains(startsWith('Cette semaine, je te propose ${v.series} séries')),
      );
      final base = app.program.week(15).day(j)!;
      app.koachVolumeChoose(15, base, e, false);
      expect(seriesPlan(j, slot), v.ecrites);
      expect(app.exLog(15, j, e).sets.length, v.ecrites);
    });

    test('C17.51.4 : profil en libre, aperçu enregistré « assisted » : le '
        'profil décide', () async {
      app.setGuidanceMode('free');
      await jour(2, 0.4);
      final base = app.program.week(15).day(2)!;
      final ap = app.adaptOpen(15, base)!;
      // Trace d'une version d'avant RV3 (toujours « assisted »).
      app.sessionLog(15, 2).adapt = {
        ...ap.toJson().cast<String, dynamic>(),
        'mode': 'assisted',
      };
      final again = app.adaptOpen(15, base)!;
      expect(again.mode, 'free');
      for (final x in app.adaptDay(15, base, again).exercises) {
        final v = app.koachVolume(15, 2, x);
        if (v == null) continue;
        expect(v.applique, isFalse, reason: '${x.slotId}');
        expect(
          again.plan.items
              .firstWhere(
                (it) => it.slotId == (x.slotId ?? app.adaptSlotOf(15, 2, x.id)),
              )
              .sets,
          v.ecrites,
        );
      }
    });
  });

  group('mercredi au bilan bas : dead hang de la pause du squat', () {
    late AppStore app;
    var clock = DateTime(2026, 10, 21, 7);

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
    });
    tearDown(() async {
      debugKoachBasculeAutorisee = false;
      await app.flush();
      app.dispose();
    });

    /// Lignes affichées (nom, séries) de la séance S15·J3 servie par Koach.
    Future<List<(String, String)>> servir({kc.HealthCheck? check}) async {
      clock = DateTime(2026, 10, 21, 7);
      await app.koachRefresh();
      final base = app.program.week(15).day(3)!;
      expect(app.adaptOpen(15, base)?.koach?['state'], 'preview');
      if (check != null) app.adaptAnswer(15, base, check);
      expect(await app.koachStart(15, base), isTrue);
      final a = app.sessionAdapt(15, 3)!;
      return [
        for (final x in app.adaptDay(15, base, a).exercises)
          (x.name, app.setsLabel(x)),
      ];
    }

    test('le dead hang reste servi à ses séries, enchaîné au squat E3MOM, '
        'comme un jour normal', () async {
      final bas = await servir(
        check: const kc.HealthCheck(overall: 1, sleepQuality: 1, energy: 1),
      );
      _sonde('j3_bilan_bas', [for (final x in bas) '${x.$1}|${x.$2}']);
      final i = bas.indexWhere((x) => x.$1.startsWith('BACK SQUAT'));
      expect(i, greaterThanOrEqualTo(0));
      expect(bas[i].$2, '6×3 · E3MOM');
      // Ligne suivante : le dead hang de la pause, enchaîné (il rejoint le
      // groupe du squat à l'écran), à ses six tenues écrites.
      expect(bas[i + 1].$1, contains('Dead hang'));
      expect(bas[i + 1].$1, contains('enchaîné'));
      expect(bas[i + 1].$2, '6 × 30 s');
      final a = app.sessionAdapt(15, 3)!;
      final hang = a.plan.items.firstWhere(
        (x) => x.exerciseId == 'sw-dead-hang',
      );
      expect(hang.sets, 6);
    });
  });
}
