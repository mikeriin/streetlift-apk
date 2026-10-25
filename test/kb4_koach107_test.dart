// KB4 (dev7.4.0, pipeline CP, DECISIONS_CP.md C17.40, C17.42) — Koach 1.0.7
// (`kalis_adapt` 1.0.6) dans l'application :
//
// - paquet et paramètres 1.0.7 ; texte `koach.ajout_borne` ;
// - garde de la séance (`koachGardeSeance`) pour tous les rôles : une
//   ligne écrite absente du servi sans retrait motivé est servie telle
//   qu'écrite (le retrait d'un accessoire par le retour gradué de KB3 est
//   retiré) ;
// - scénario C17.40 sur le programme importé PR2 synthétique (six séances
//   par semaine en PPL, départ affiché S15, trois semaines d'historique
//   moins volumineuses que le programme) : lundi de tirage et mardi de
//   poussée servis avec toutes leurs lignes à leurs séries écrites ;
//   douleur à l'épaule : conduite sous douleur ;
// - réactivation après l'arrêt d'urgence : séances faites pendant l'arrêt
//   versées dans l'ordre, jamais réécrites, Koach reprend à la suivante ;
//   carte de reprise de l'accueil ;
// - passage depuis dev7.3.0 (Koach actif ; Koach arrêté avec une séance
//   commencée) sans perte ; sauvegarde exportée puis réimportée à
//   l'identique ;
// - lignes EMOM « volume » (« EMOM 8 min × 3 reps par minute ») : une
//   ligne par minute, départ chronométré, Koach actif comme arrêté.
//
// Données synthétiques seulement (C17.33.2) ; horloge injectée ; stockage
// simulé ; calculs du moteur sur place.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_adapt/kalis_adapt.dart' as ka;
import 'package:kalis_adapt/koach.dart' as ko;
import 'package:kalis_adapt/koach_textes.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/koach1/koach1_widgets.dart';
import 'package:streetlift_tracker/koach1/koach_moteur.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

import 'kb2c1_fixtures.dart';

Map<String, Object?> _it(String slot, String ex, {String? kind}) => {
  'slotId': slot,
  'exerciseId': ex,
  'sets': 3,
  'kind': ?kind,
};

Map<String, Object?> _r(String code, String ex, [Map<String, Object?>? p]) => {
  'code': code,
  'params': {'exercice': ex, ...?p},
};

/// Section de la sauvegarde exportée.
String _section(AppStore app, String key) =>
    jsonEncode((jsonDecode(app.exportAll()) as Map<String, dynamic>)[key]);

/// Séries notées de toutes les séances (journal sans l'état du moteur :
/// séances faites jamais réécrites).
String _series(AppStore app) {
  final logs = (jsonDecode(app.exportAll()) as Map<String, dynamic>)['logs'];
  if (logs is! Map) return '-';
  return jsonEncode({
    for (final e in logs.entries)
      '${e.key}': {
        for (final x in (e.value as Map).entries)
          if (x.key != 'adapt') '${x.key}': x.value,
      },
  });
}

/// Ligne de programme au format de la sauvegarde.
Exercise _ligne(Map<String, Object?> sets, {String name = 'Dips PdC'}) =>
    Exercise.fromJson({
      'id': 'x',
      'name': name,
      'sets': sets,
      'load': {'type': 'fixed', 'kg': 0.0},
      'rest': '—',
      'restSec': null,
    });

/// Sonde imprimée (relevé de la livraison).
void _sonde(String nom, Object? v) {
  // ignore: avoid_print
  print('KB4|$nom|${jsonEncode(v)}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('paquet', () {
    test('Koach servi : 1.0.9 depuis KB6 (`kalis_adapt` 1.0.8, paramètres '
        '1.0.9-ref.1, 344 clés)', () {
      expect(ka.kalisAdaptVersion, '1.0.8');
      expect(ko.koachVersion, '1.0.9-ref.1');
      expect(ko.koachParametresVersion, '1.0.9-ref.1');
      expect(ko.koachParametresCles, 344);
      expect(
        ko.koachParametresSha256,
        '1a59e6756923ce348378ff356a25b0af4adc8e8114ae9ac1ba53b85c46808dc5',
      );
      expect(kKoachParamsAsset, 'assets/koach/koach_params_1_0_9.json');
    });

    test('texte de `koach.ajout_borne` : l’écrit gardé, l’ajout borné', () {
      expect(koachCodesRaisons, contains('koach.ajout_borne'));
      final garde = texteRaisonKoach({
        'code': 'koach.ajout_borne',
        'params': {
          'exercice': 'sl-dips-leste',
          'groupe': 'triceps',
          'series': 8,
          'ecrites': 8,
          'prevues': 9,
        },
      }, nomExercice: (_) => 'Dip lesté');
      expect(garde, startsWith('Je garde les 8 séries écrites'));
      expect(garde, contains('sans en ajouter'));
      expect(garde, isNot(contains('Je retire')));
      final ajout = texteRaisonKoach({
        'code': 'koach.ajout_borne',
        'params': {
          'exercice': 'sl-dips-leste',
          'groupe': 'chest',
          'series': 9,
          'ecrites': 8,
          'prevues': 11,
        },
      }, nomExercice: (_) => 'Dip lesté');
      expect(ajout, startsWith('J’ajoute une série'));
    });
  });

  group('garde de la séance : tous les rôles (pure)', () {
    final ecrit = [
      _it('j1-a', 'a'),
      _it('j1-b', 'b'),
      _it('j1-c', 'c'),
      _it('j1-d', 'd'),
      _it('j1-e', 'e', kind: 'test'),
      _it('j1-f', 'f'),
    ];

    test('ligne absente sans retrait motivé : servie telle qu’écrite, quel '
        'que soit le rôle (le retour gradué de 1.0.6 ne retire plus)', () {
      final g = koachGardeSeance(ecrit, const [], [
        _r('koach.retour_gradue', 'a', {'groupe': 'chest', 'series': 0}),
        _r('koach.ajout_borne', 'b', {'series': 0}),
        _r('koach.surmenage', 'c'),
        _r('koach.tendon', 'f'),
      ]);
      expect(g.retraits, isEmpty);
      expect(g.ecrites, [
        {'slotId': 'j1-a', 'exercice': 'a', 'cause': 'koach.retour_gradue'},
        {'slotId': 'j1-b', 'exercice': 'b', 'cause': 'koach.ajout_borne'},
        {'slotId': 'j1-c', 'exercice': 'c', 'cause': 'koach.surmenage'},
        {'slotId': 'j1-d', 'exercice': 'd'},
        {'slotId': 'j1-e', 'exercice': 'e'},
        {'slotId': 'j1-f', 'exercice': 'f', 'cause': 'koach.tendon'},
      ]);
    });

    test('retraits motivés : douleur, endurance, test reporté, séance '
        'bornée au temps donné, rampe tendineuse (bras tendus à 0)', () {
      final raisons = [
        _r('koach.douleur_retrait', 'a'),
        _r('koach.endurance_retrait', 'b'),
        _r('koach.seance_bornee', 'c'),
        _r('koach.retour_gradue', 'd', {
          'groupe': 'bras_tendus_tirage',
          'series': 0,
        }),
        _r('koach.test_reporte', 'e'),
        _r('koach.test_reporte', 'f'),
      ];
      for (final r in [raisons, raisons.reversed.toList()]) {
        final g = koachGardeSeance(ecrit, const [], r, budgetDonne: true);
        expect(
          {for (final x in g.retraits) x['slotId']: x['code']},
          {
            'j1-a': 'koach.douleur_retrait',
            'j1-b': 'koach.endurance_retrait',
            'j1-c': 'koach.seance_bornee',
            'j1-d': 'koach.retour_gradue',
            'j1-e': 'koach.test_reporte',
          },
        );
        // Un test reporté ne retire qu'une ligne de test.
        expect(g.ecrites, [
          {'slotId': 'j1-f', 'exercice': 'f', 'cause': 'koach.test_reporte'},
        ]);
      }
      // Séance bornée sans temps donné par l'athlète : servie telle
      // qu'écrite ; rampe tendineuse à 2 séries : servie telle qu'écrite.
      final h = koachGardeSeance(ecrit, const [], [
        _r('koach.seance_bornee', 'c'),
        _r('koach.retour_gradue', 'd', {
          'groupe': 'bras_tendus_tirage',
          'series': 2,
        }),
      ]);
      expect(h.retraits, isEmpty);
      expect(h.ecrites, hasLength(6));
    });

    test('ordre écrit gardé ; vrai test devant sa ligne ; ajout écarté', () {
      final g = koachGardeSeance(ecrit, [
        {'slotId': 'j1-c', 'exerciseId': 'c', 'sets': 3},
        {'slotId': 'j1-a', 'exerciseId': 'a', 'sets': 4},
        {'slotId': 'j1-a.t', 'exerciseId': 'a', 'sets': 1},
        {'slotId': 'j9-z', 'exerciseId': 'z', 'sets': 2},
      ], const []);
      expect(
        [for (final x in g.servis) x['slotId']],
        ['j1-a', 'j1-a.t', 'j1-c'],
      );
      expect(
        [for (final x in g.ecrites) x['slotId']],
        ['j1-b', 'j1-d', 'j1-e', 'j1-f'],
      );
    });

    test('ligne au départ chronométré (PR8) : message seulement si les '
        'séries servies diffèrent encore de l’écrit', () {
      expect(koachTexteEcartEcrit(8, 8), isNull);
      expect(koachTexteEcartEcrit(6, 8), contains('6 séries sur 8'));
      expect(koachTexteEcartEcrit(1, 6), contains('1 série sur 6'));
      expect(koachTexteEcartEcrit(9, 8), contains('9 séries au lieu de 8'));
      expect(koachTexteEcrite('koach.retour_gradue'), startsWith('Servi tel'));
      expect(
        koachTexteEcrite('koach.retour_gradue'),
        isNot(contains('volume')),
      );
    });
  });

  group('lignes EMOM « volume » : une ligne par minute', () {
    late AppStore app;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      app = AppStore();
      await app.init();
    });
    tearDown(() async {
      await app.flush();
      app.dispose();
    });

    test('« EMOM 8 min × 3 reps par minute » : 8 lignes de 3, départ toutes '
        'les 60 s, reps arrondies comme l’écrit', () {
      expect(emomPerMinute('EMOM 8 min × 3 reps par minute'), (
        minutes: 8,
        reps: 3,
      ));
      expect(
        emomPerMinute('EMOM 20 min · 10 reps, +1 rep/min jusqu’à l’échec'),
        isNull,
      );
      expect(emomPerMinute('12×6 · EMOM'), isNull);
      // Références du constat (S1·J4, J5) : coefficient × référence ÷
      // minutes, arrondi comme l'écrit.
      for (final (ref, v, coef, div, minutes) in [
        ('B16', 10.0, 2.4, 8, 8),
        ('B17', 30.0, 2.667, 10, 10),
        ('B18', 70.0, 3.086, 12, 12),
      ]) {
        app.setValue(ref, v);
        final e = _ligne({
          'type': 'volume',
          'prefix': 'EMOM $div min × ',
          'coef': coef,
          'ref': ref,
          'div': div,
          'suffix': ' reps par minute',
        });
        final reps = (coef * v / div).round();
        expect(app.setsLabel(e), 'EMOM $minutes min × $reps reps par minute');
        final sp = app.logSpec(e);
        expect(sp.kind, 'reps', reason: ref);
        expect(sp.every, 60, reason: ref);
        expect(app.setCount(e), minutes, reason: ref);
        expect(
          app.plannedReps(e, sp, minutes),
          List.filled(minutes, reps),
          reason: ref,
        );
        expect(app.restAfterSet(e, sp, 0, minutes), isNull);
        _sonde('emom_$ref', {'label': app.setsLabel(e), 'lignes': minutes});
      }
    });

    test('autres formes du programme : une ligne par série, jamais un '
        'total ; EMOM montant inchangé', () {
      Exercise t(String v) => _ligne({'type': 'text', 'value': v});
      expect(app.setCount(t('6×30 s')), 6);
      expect(app.logSpec(t('6×30 s')).kind, 'hold');
      expect(app.setCount(t('3×10/jambe')), 3);
      final j = t('3×10/jambe');
      expect(app.plannedReps(j, app.logSpec(j), 3), [10, 10, 10]);
      final b = t('2×15/bras');
      expect(app.setCount(b), 2);
      expect(app.plannedReps(b, app.logSpec(b), 2), [15, 15]);
      expect(app.setCount(t('2 tours × 4 paliers')), 8);
      expect(app.setCount(t('8×3 · E2MOM')), 8);
      // Intervalles : RV1 (C17.43.3) : une ligne par tour (avant KB4 et
      // dans KB4 : une ligne pour la séance d'intervalles écrite).
      final iv = t('8× (30 s effort / 30 s repos)');
      expect(app.logSpec(iv).kind, 'hold');
      expect(app.logSpec(iv).rowPrefix, 'I');
      expect(app.setCount(iv), 8);
      // EMOM montant (« +1 rep/min jusqu'à l'échec ») : une ligne, sans
      // cible (PR1).
      final m = t('EMOM 20 min · 10 reps, +1 rep/min jusqu’à l’échec');
      expect(app.logSpec(m).kind, 'emom');
      expect(app.setCount(m), 1);
    });
  });

  group('programme PR2 synthétique (C17.40)', () {
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

    test('lundi de tirage et mardi de poussée servis avec toutes leurs '
        'lignes à leurs séries écrites ; le programme dépasse la limite de '
        'la rampe (chest, delt_anterior, triceps)', () async {
      await activate();
      final relev = <String, Object?>{};
      for (final j in const [1, 2]) {
        clock = DateTime(2026, 10, 18 + j, 7);
        await app.koachRefresh();
        final base = app.program.week(15).day(j)!;
        expect(app.adaptOpen(15, base)?.koach?['state'], 'preview');
        final sw = Stopwatch()..start();
        expect(await app.koachStart(15, base), isTrue, reason: 'J$j');
        final ms = sw.elapsedMicroseconds / 1000;
        final e = etat(j);
        final a = app.sessionAdapt(15, j)!;
        final shown = app.adaptDay(15, base, a).exercises;
        final rv = app.koachLive!.seances.retourVol;
        final groupes = [
          for (final g
              in ((app.koachLive!.params['securite']
                      as Map)['volume_groupes_majeurs']
                  as List))
            '$g',
        ];
        final rampe = <String, Object?>{};
        if (rv != null) {
          for (final g in const ['chest', 'delt_anterior', 'triceps']) {
            final i = groupes.indexOf(g);
            if (i < 0) continue;
            rampe[g] = {
              'limite': rv.limites[i],
              'ecrit': rv.ecrit[i],
              'fait': rv.fait[i],
            };
          }
        }
        relev['J$j'] = {
          'servis': e.servis,
          'ecrites': e.ecrites,
          'garde': e.st['garde'],
          'retraits': e.st['retraits'],
          'raisons': [
            for (final r in e.st['raisons'] as List)
              texteRaisonKoach((r as Map).cast<String, Object?>()),
          ],
          'cartes': [
            for (final x in shown) '${x.catalogId}:${app.setsLabel(x)}',
          ],
          'entete': app.koachSessionReasons(15, j, max: 9),
          'rampe': rampe,
          'temps_ms': ms,
        };
        // Séance servie lisible, aucune ligne retirée, aucune ligne servie
        // par la garde (Koach 1.0.7 ne coupe plus pour le volume).
        expect(e.st['invalide'], isNull, reason: 'J$j');
        expect((e.st['retraits'] as List?) ?? const [], isEmpty);
        expect(e.st['garde'], isNull, reason: 'J$j ${e.st['garde']}');
        // Chaque ligne écrite servie, au moins à ses séries écrites.
        for (final x in e.ecrites.entries) {
          expect(e.servis[x.key], isNotNull, reason: 'J$j ${x.key}');
          expect(
            e.servis[x.key]!,
            greaterThanOrEqualTo(x.value),
            reason: 'J$j ${x.key}',
          );
        }
        // Cartes : toutes les lignes du programme, dans l'ordre écrit.
        expect(
          [for (final x in shown) x.catalogId],
          [for (final x in base.exercises) x.catalogId],
        );
        // Plus de « Je retire … » au nom du volume.
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
      // Mardi : lignes du constat C17.40.2 à leurs séries écrites.
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
      // Le programme dépasse la limite de la rampe sur un groupe au moins
      // (sinon le scénario ne mesurerait rien).
      final rampe = (relev['J2'] as Map)['rampe'] as Map;
      expect(
        rampe.values.any(
          (v) => ((v as Map)['ecrit'] as num) > (v['limite'] as num),
        ),
        isTrue,
        reason: jsonEncode(rampe),
      );
    });

    test('douleur à l’épaule signalée le mardi : conduite sous douleur '
        '(retraits motivés), les autres lignes à leur écrit', () async {
      await activate();
      clock = DateTime(2026, 10, 20, 7);
      await app.koachRefresh();
      final base = app.program.week(15).day(2)!;
      expect(app.adaptOpen(15, base)?.koach?['state'], 'preview');
      app.adaptAnswer(
        15,
        base,
        const kc.HealthCheck(
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
      expect(await app.koachStart(15, base), isTrue);
      final e = etat(2);
      final retraits = [
        for (final x in (e.st['retraits'] as List?) ?? const [])
          (x as Map).cast<String, Object?>(),
      ];
      _sonde('douleur', {
        'servis': e.servis,
        'retraits': retraits,
        'garde': e.st['garde'],
      });
      expect(e.st['invalide'], isNull);
      // Tout retrait est motivé par la douleur (jamais par le volume).
      for (final x in retraits) {
        expect(x['code'], 'koach.douleur_retrait', reason: '$x');
      }
      // Une ligne non retirée est servie à au moins son écrit, ou réduite
      // par la conduite sous douleur (jamais retirée en silence).
      final retires = {for (final x in retraits) '${x['slotId']}'};
      for (final x in e.ecrites.keys) {
        if (retires.contains(x)) continue;
        expect(e.servis[x], isNotNull, reason: x);
      }
    });

    test(
      'réactivation après un arrêt : deux séances faites pendant l’arrêt '
      'versées dans l’ordre, jamais réécrites, Koach reprend à la '
      'suivante ; séance servie finie pendant l’arrêt fermée une fois',
      () async {
        await activate();
        // Lundi : J1 servie par Koach, une série notée, puis arrêt.
        final j1 = app.program.week(15).day(1)!;
        expect(app.adaptOpen(15, j1)?.koach?['state'], 'preview');
        expect(await app.koachStart(15, j1), isTrue);
        final first = app
            .adaptDay(15, j1, app.sessionAdapt(15, 1)!)
            .exercises
            .firstWhere((x) => x.engine);
        app.koachEnsureTarget(15, j1, first, 0);
        final log1 = app.exLog(15, 1, first);
        app.adaptPrefill(15, 1, first, log1);
        if (log1.sets[0].reps.isEmpty) log1.sets[0].reps = '5';
        log1.sets[0].flames = 8;
        expect(app.toggleSet(log1, 0, app.logSpec(first)).ok, isTrue);
        app.koachAfterSet(15, j1, first, 0);
        // Aperçu de J2 calculé avant l'arrêt (aperçu périmé ensuite).
        final j2 = app.program.week(15).day(2)!;
        expect(app.adaptOpen(15, j2)?.koach?['state'], 'preview');
        final journal0 = [
          for (final x in app.koachEngine.journal) jsonEncode(x),
        ];
        app.koachStop();
        expect(app.koachEngine.stop, isNotNull);
        // Arrêt décidé avec dev7.4.0 : pas de carte de reprise.
        expect(app.koachAnnonceReprise, isFalse);
        // J1 finie pendant l'arrêt (séance écrite), puis J2 et J3 faites
        // telles qu'écrites.
        for (final j in const [1, 2, 3]) {
          clock = DateTime(2026, 10, 18 + j, 19);
          final d = app.program.week(15).day(j)!;
          expect(app.adaptOpen(15, d), isNull, reason: 'J$j');
          for (final e in d.exercises) {
            final log = app.exLog(15, j, e);
            for (var i = 0; i < log.sets.length; i++) {
              final s = log.sets[i];
              if (s.done) continue;
              if (s.reps.isEmpty) s.reps = '6';
              s.flames = 7;
              app.toggleSet(log, i, app.logSpec(e));
            }
          }
          app.markSessionDone(15, j, true);
        }
        final logs = _series(app);
        expect(app.koachEngine.journal.length, journal0.length);
        // Jeudi : réactivation.
        clock = DateTime(2026, 10, 22, 7);
        await app.koachResume();
        final e = app.koachEngine;
        expect(e.stop, isNull);
        expect(app.koachLive, isNotNull);
        expect(app.koachRuntimeError, isNull);
        // Journal d'avant l'arrêt gardé tel quel.
        for (var i = 0; i < journal0.length; i++) {
          expect(jsonEncode(e.journal[i]), journal0[i], reason: 'événement $i');
        }
        // J1 fermée une fois, J2 et J3 versées dans l'ordre (un début et une
        // fin par séance).
        for (final j in const [1, 2, 3]) {
          expect(e.versed, contains(app.sessionKey(15, j)));
        }
        final types = [for (final x in e.journal) '${x['type']}'];
        expect(
          types.where((t) => t == 'seance_debut').length,
          types.where((t) => t == 'seance_fin').length,
        );
        final jours = [
          for (final x in e.journal.skip(journal0.length))
            if (x['type'] == 'seance_debut' || x['type'] == 'seance_fin')
              (x['jour'] as num).toInt(),
        ];
        final tri = [...jours]..sort();
        expect(jours, tri);
        _sonde('reactivation', {
          'ajoutes': types.skip(journal0.length).toList(),
          'jours': jours,
        });
        // Séances faites jamais réécrites (séries notées identiques).
        expect(_series(app), logs);
        // Koach reprend à la première séance non faite (J4), modulation de
        // l'arrêt abandonnée.
        final j4 = app.program.week(15).day(4)!;
        expect(app.koachServesDay(15, 4), isTrue);
        expect(app.adaptOpen(15, j4)?.koach?['state'], 'preview');
        expect(await app.koachStart(15, j4), isTrue);
        expect(app.koachOpen(15, 4), isTrue);
        // J2 faite pendant l'arrêt : hors de Koach, bilan gardé.
        expect(app.sessionAdapt(15, 2)?.koach?['state'], 'ecrite');
        expect(app.koachStartNow(15, app.program.week(15).day(2)!), isFalse);
      },
    );

    test('carte de reprise : arrêt d’avant dev7.4.0, « Plus tard » puis '
        '« Réactiver » (jamais automatique)', () async {
      await activate();
      app.koachStop();
      // Arrêt écrit par dev7.3.0 : pas d'annonce notée.
      app.koachEngine.annonce107 = null;
      final text = app.exportAll();
      await app.flush();
      app.dispose();
      await fresh();
      expect(await app.importAll(text), isTrue);
      app.koachNoteInstall();
      await app.koachRefresh();
      expect(app.koachEngine.stop, isNotNull);
      expect(app.koachAnnonceReprise, isTrue);
      app.koachAnnonceRepriseVue();
      expect(app.koachAnnonceReprise, isFalse);
      expect(app.koachEngine.stop, isNotNull);
      // L'annonce vue survit à l'export.
      final again = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      expect((again['koachEngine'] as Map)['annonce107'], isNotNull);
      await app.koachResume();
      expect(app.koachEngine.stop, isNull);
      expect(app.koachAnnonceReprise, isFalse);
    });

    test('passage depuis dev7.3.0 : Koach actif, puis Koach arrêté avec une '
        'séance commencée : logs, programInstance, programOrigin '
        'identiques ; sauvegarde réimportée à l’identique', () async {
      await activate();
      final j1 = app.program.week(15).day(1)!;
      expect(app.adaptOpen(15, j1)?.koach?['state'], 'preview');
      expect(await app.koachStart(15, j1), isTrue);
      doAll(1);
      // Prévisions de la séance (calcul en arrière-plan) finies avant de
      // fermer cette instance.
      for (var i = 0; i < 200; i++) {
        if (app.sessionAdapt(15, 1)?.koach?['prevision'] != null) break;
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      await app.flush();
      // Instantané d'une prise de main de 1.0.6 (dev7.3.0).
      final doc = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      final engine = (doc['koachEngine'] as Map).cast<String, dynamic>();
      final snap = (engine['snap'] as Map).cast<String, dynamic>();
      snap['version_moteur'] = '1.0.6-ref.1';
      snap['version_parametres'] = '1.0.6-ref.1';
      snap['sha256_parametres'] =
          '4156e61b674be1e983d22dba21067cb47cc16d25429b60588957549b9464045a';
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
      // Mardi : premier lancement de dev7.4.0 (Koach actif).
      clock = DateTime(2026, 10, 20, 7);
      app.koachNoteInstall();
      await app.koachRefresh();
      final e = app.koachEngine;
      expect(e.fromWeek, 15);
      expect(e.snap!.versionMoteur, '1.0.6-ref.1');
      expect(app.koachLive!.params['version'], '1.0.9-ref.1');
      expect(app.koachAnnonceReprise, isFalse);
      expect(_section(app, 'logs'), logs);
      expect(_section(app, 'programInstance'), instance);
      expect(_section(app, 'programOrigin'), origin);
      for (var i = 0; i < journal.length; i++) {
        expect(jsonEncode(e.journal[i]), journal[i], reason: 'événement $i');
      }
      // Mardi : J2 servie par 1.0.7, une série notée, puis arrêt (comme
      // dev7.3.0 le laissait).
      final j2 = app.program.week(15).day(2)!;
      expect(app.adaptOpen(15, j2)?.koach?['state'], 'preview');
      expect(await app.koachStart(15, j2), isTrue);
      final first = app
          .adaptDay(15, j2, app.sessionAdapt(15, 2)!)
          .exercises
          .first;
      final log = app.exLog(15, 2, first);
      if (log.sets[0].reps.isEmpty) log.sets[0].reps = '3';
      log.sets[0].flames = 8;
      expect(app.toggleSet(log, 0, app.logSpec(first)).ok, isTrue);
      final done = jsonEncode(log.sets[0].toJson());
      app.koachStop();
      app.koachEngine.annonce107 = null;
      await app.flush();
      final stopped = app.exportAll();
      final logs2 = _section(app, 'logs');
      // Lancement suivant (dev7.4.0) : rien perdu, carte de reprise.
      app.dispose();
      await fresh();
      expect(await app.importAll(stopped), isTrue);
      app.koachNoteInstall();
      await app.koachRefresh();
      expect(_section(app, 'logs'), logs2);
      expect(_section(app, 'programInstance'), instance);
      expect(_section(app, 'programOrigin'), origin);
      expect(app.koachAnnonceReprise, isTrue);
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
      // Réactivation : la série notée est gardée, la séance reste servie.
      await app.koachResume();
      expect(app.koachEngine.stop, isNull);
      expect(app.koachOpen(15, 2), isTrue);
      final kept = app.logs[app.sessionKey(15, 2)]!.ex[first.id]!;
      expect(jsonEncode(kept.sets[0].toJson()), done);
    });

    test('lignes EMOM « volume » de J4 et J5 : une ligne par minute, Koach '
        'actif comme arrêté', () async {
      await activate();
      final relev = <String, Object?>{};
      for (final actif in const [true, false]) {
        for (final j in const [4, 5]) {
          final base = app.program.week(15).day(j)!;
          final a = actif ? app.adaptOpen(15, base) : null;
          if (actif) expect(a?.koach?['state'], 'preview');
          final day = a == null ? base : app.adaptDay(15, base, a);
          for (final e in day.exercises) {
            final label = app.setsLabel(e);
            final m = emomPerMinute(label);
            if (m == null) continue;
            final sp = app.logSpec(e);
            relev['${actif ? 'actif' : 'arrete'}_J${j}_${e.id}'] = {
              'label': label,
              'lignes': app.setCount(e),
              'every': sp.every,
              'ecrit': app.adaptAsWritten(
                15,
                e.slotId ?? app.adaptSlotOf(15, j, e.id),
              ),
            };
            expect(e.engine, isFalse, reason: label);
            expect(sp.every, 60, reason: label);
            expect(app.setCount(e), m.minutes, reason: label);
            expect(
              app.plannedReps(e, sp, m.minutes),
              List.filled(m.minutes, m.reps),
            );
          }
        }
        if (actif) {
          app.koachStop();
          expect(app.koachStoppedWeek(15), isTrue);
        }
      }
      _sonde('emom_programme', relev);
      // Muscle-ups PdC (J4), tractions PdC (J4), dips PdC (J5) : six
      // relevés (deux états × trois lignes).
      expect(relev.length, 6, reason: jsonEncode(relev));
    });
  });

  group('écran de séance : EMOM minute par minute', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await store.init();
      store.settings
        ..sound = false
        ..vibration = false
        ..wakelock = false
        ..autoTimer = false
        ..prefill = true;
    });

    testWidgets('« EMOM 8 min × 3 reps par minute » : en-tête du départ '
        'chronométré, 8 lignes de 3, une minute validée à la fois', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final e = Exercise.manual(
        id: 'EM-1',
        name: 'Muscle-ups PdC — EMOM technique',
        setsText: 'EMOM 8 min × 3 reps par minute',
      );
      final week = WeekPlan.manual(
        n: 0,
        block: 'EMOM',
        color: const Color(0xFF4FA3C7),
        days: [
          DayPlan.manual(j: 9804, title: 'EMOM', exercises: [e]),
        ],
      );
      final day = week.days.single;
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
      final header = find.byKey(const ValueKey('timing-header'));
      expect(header, findsOneWidget);
      expect(
        find.descendant(
          of: header,
          matching: find.textContaining('EMOM · 8 tours'),
        ),
        findsOneWidget,
      );
      final log = store.exLog(week.n, day.j, e);
      expect(log.sets.length, 8);
      expect([for (final s in log.sets) s.reps], List.filled(8, '3'));
      expect(find.byTooltip('Valider la série 8'), findsWidgets);
      await tester.tap(find.byTooltip('Valider la série 1').first);
      await tester.pumpAndSettle();
      expect(log.sets[0].done, isTrue);
      expect(log.sets.where((s) => s.done).length, 1);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    test('séance ouverte avant dev7.4.0 (une ligne du total, rien noté) : '
        'une ligne par minute ; jamais une ligne notée retirée', () {
      final e = Exercise.manual(
        id: 'EM-2',
        name: 'Tractions PdC — EMOM',
        setsText: 'EMOM 10 min × 8 reps par minute',
      );
      final s = store.sessionLog(0, 9805);
      s.ex[e.id] = ExerciseLog(sets: [SetEntry(reps: '80')]);
      expect(store.exLog(0, 9805, e).sets.length, 10);
      final f = Exercise.manual(
        id: 'EM-3',
        name: 'Dips PdC — EMOM',
        setsText: 'EMOM 12 min × 18 reps par minute',
      );
      s.ex[f.id] = ExerciseLog(sets: [SetEntry(reps: '200', done: true)]);
      expect(store.exLog(0, 9805, f).sets.length, 1);
      expect(store.exLog(0, 9805, f).sets.single.reps, '200');
    });
  });
}
