// KB6 (dev7.8.0, pipeline CP, DECISIONS_CP.md C17.54-55) — Koach 1.0.9
// (`kalis_adapt` 1.0.8) dans l'application :
//
// - paquet copié à l'octet, paramètres `1.0.9-ref.1` (empreintes) ;
// - forme du jour apprise en « Garder l'écrit » : bilan complet versé avec
//   `applique: false` (jamais par `HealthCheck`), séance servie identique
//   à celle sans forme du jour ; douleur inchangée ; ligne de la carte du
//   bilan ;
// - « Remplacer pour aujourd'hui » : propositions de Koach groupées et
//   étiquetées, « Pourquoi ? › Il me manque : ceinture de lest » pour le
//   dip lesté de la J5, HSPU jamais proposé pour le dip principal, cible
//   de départ servie ; remplaçant servi par Koach avec ses cibles (avant
//   le début, ou séance recommencée sans série validée) ; sinon cible de
//   départ ; recherche toujours là, Assisté inchangé (écran) ;
// - passage depuis dev7.7.2 sans perte, export / import à l'identique.
//
// Données synthétiques seulement (C17.33.2) ; horloge injectée ; stockage
// simulé ; calculs du moteur sur place.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_adapt/kalis_adapt.dart' as ka;
import 'package:kalis_adapt/koach.dart' as ko;
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
import 'support/sha256.dart';

const _hspu = 'cd-hspu-mur-dos';

/// Sonde imprimée (relevé de la livraison).
void _sonde(String nom, Object? v) {
  // ignore: avoid_print
  print('KB6|$nom|${jsonEncode(v)}');
}

const _bas = kc.HealthCheck(overall: 1, sleepQuality: 1, energy: 1);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('paquet et empreintes', () {
    test('Koach 1.0.9 (`kalis_adapt` 1.0.8, paramètres 1.0.9-ref.1, 344 '
        'clés) ; asset copié à l’octet ; version 7.8.0', () {
      expect(ka.kalisAdaptVersion, '1.0.8');
      expect(ko.koachVersion, '1.0.9-ref.1');
      expect(ko.koachParametresVersion, '1.0.9-ref.1');
      expect(ko.koachParametresCles, 344);
      expect(kKoachParamsAsset, 'assets/koach/koach_params_1_0_9.json');
      const sha =
          '1a59e6756923ce348378ff356a25b0af4adc8e8114ae9ac1ba53b85c46808dc5';
      expect(ko.koachParametresSha256, sha);
      final a = File(kKoachParamsAsset).readAsBytesSync();
      final b = File(
        'packages/kalis_adapt/assets/koach/koach_params_1_0_9.json',
      ).readAsBytesSync();
      expect(a, b);
      expect(sha256Hex(a), sha);
      expect(File('assets/koach/koach_params_1_0_8.json').existsSync(), false);
      final pub = File('pubspec.yaml').readAsStringSync();
      expect(pub, contains('- assets/koach/koach_params_1_0_9.json'));
      expect(pub, isNot(contains('koach_params_1_0_8.json')));
      expect(pub, contains('version: 7.8.0+155'));
      final lock = File('pubspec.lock').readAsStringSync();
      expect(lock, contains('version: "1.0.8"'));
    });
  });

  group('fonctions pures', () {
    test('bilan versé sans être appliqué : carte copiée, drapeau ajouté', () {
      final check = const kc.HealthCheck(
        overall: 2,
        energy: 1,
        minutesAvailable: 45,
      ).toJson();
      final v = koachBilanNonApplique(check);
      expect(v['applique'], isFalse);
      expect(v['overall'], 2);
      expect(v['energy'], 1);
      expect(v['minutesAvailable'], 45);
      // La carte d'origine n'est pas modifiée.
      expect(check.containsKey('applique'), isFalse);
      // `HealthCheck` ignore le drapeau : il ne doit jamais repasser par lui.
      expect(
        kc.HealthCheck.fromJson(v).toJson().containsKey('applique'),
        isFalse,
      );
    });

    test('ligne remplacée demandée à Koach', () {
      final it = <String, Object?>{
        'slotId': 's1',
        'exerciseId': 'sl-dips-leste',
        'sets': 6,
        'startLoadKg': 20.0,
      };
      final r = koachLigneRemplacee(it, 'cd-dips-russes', 'pas_de_materiel');
      expect(r['exerciseId'], 'cd-dips-russes');
      expect(r['slotId'], 's1');
      expect(r['sets'], 6);
      expect(r['remplace'], {
        'exerciseId': 'sl-dips-leste',
        'raison': 'pas_de_materiel',
      });
      expect(it['exerciseId'], 'sl-dips-leste');
    });

    test('cible de départ lisible et séries à la cible', () {
      String kg(double x) => '${x.toStringAsFixed(1)} kg';
      expect(dayDepartText({'repsLow': 6, 'repsHigh': 8}, kg), '6-8 reps');
      expect(
        dayDepartText({'repsLow': 5, 'repsHigh': 5, 'loadKg': 20.0}, kg),
        '5 reps à 20.0 kg',
      );
      expect(
        dayDepartText({'secondsLow': 24, 'secondsHigh': 30}, kg),
        '24-30 s',
      );
      expect(dayDepartText({'source': null}, kg), isNull);
      expect(dayHasDepart({'source': 'a_priori'}), isFalse);
      expect(dayHasDepart({'repsHigh': 8}), isTrue);
      expect(
        daySetsAtDepart('6×2 · E2MOM', {'repsLow': 6, 'repsHigh': 8}),
        '6×6-8 · E2MOM',
      );
      expect(
        daySetsAtDepart('6×2 · E2MOM', {'secondsLow': 20, 'secondsHigh': 25}),
        '6×20-25 s · E2MOM',
      );
      expect(daySetsAtDepart('3×10', {'loadKg': 20.0}), isNull);
      expect(daySetsAtDepart('EMOM 12 min', {'repsHigh': 8}), isNull);
    });

    test('cible de la série suivante plus basse (écrit gardé)', () {
      String kg(double x) => '${x.toStringAsFixed(2)} kg';
      final served = {'startLoadKg': 18.75, 'repsLow': 3, 'repsHigh': 3};
      expect(
        koachBaisseCible(
          served,
          {
            '1': {'loadKg': 17.5, 'repsLow': 3, 'repsHigh': 3},
          },
          1,
          kg,
        ),
        (avant: '18.75 kg', apres: '17.50 kg'),
      );
      expect(
        koachBaisseCible(
          served,
          {
            '1': {'loadKg': 18.75},
          },
          1,
          kg,
        ),
        isNull,
      );
      expect(
        koachBaisseCible(
          {'repsLow': 8, 'repsHigh': 10},
          {
            '2': {'repsLow': 6, 'repsHigh': 8},
          },
          2,
          kg,
        ),
        (avant: '8-10 reps', apres: '6-8 reps'),
      );
      // Première série : jamais dite.
      expect(
        koachBaisseCible(
          served,
          {
            '0': {'loadKg': 10.0},
          },
          0,
          kg,
        ),
        isNull,
      );
    });

    test('ligne « Koach note ta forme du jour » de la carte du bilan', () {
      KoachBilan b({
        bool forme = false,
        String? choix,
        bool assiste = false,
        bool modifiable = true,
      }) => (
        forme: forme,
        choix: choix,
        assiste: assiste,
        modifiable: modifiable,
        lignes: const {
          's': {'exerciseId': 'x'},
        },
      );
      expect(
        koachTexteFormeNotee(b()),
        'Koach note ta forme du jour même si tu gardes l’écrit.',
      );
      expect(koachTexteFormeNotee(b(choix: 'ecrit')), isNotNull);
      expect(koachTexteFormeNotee(b(forme: true, choix: 'applique')), isNull);
      expect(
        koachTexteFormeNotee(b(forme: true, assiste: true)),
        startsWith('Si tu annules'),
      );
      expect(
        koachTexteFormeNotee(b(forme: true, assiste: true, modifiable: false)),
        isNull,
      );
    });
  });

  group('programme PR2 synthétique (Koach 1.0.9)', () {
    late AppStore app;
    var clock = DateTime(2026, 10, 19, 7);

    Future<AppStore> nouveau() async {
      final x = AppStore()..storeClock = () => clock;
      await x.init();
      await importPr2Nouveau(x, firstWeek: 12);
      x.koachNoteInstall();
      await x.koachRefresh();
      expect(x.koachEngine.fromWeek, 15);
      return x;
    }

    setUp(() async {
      KoachCalcul.isolat = false;
      debugKoachBasculeAutorisee = true;
      debugResetKoachTakeoverWait();
      clock = DateTime(2026, 10, 19, 7);
      SharedPreferences.setMockInitialValues({});
      app = await nouveau();
    });
    tearDown(() async {
      debugKoachBasculeAutorisee = false;
      await app.flush();
      app.dispose();
    });

    /// Jour J[j] de S15 (lundi 19/10 = J1), séance ouverte en aperçu.
    Future<DayPlan> jour(int j, [AppStore? s]) async {
      final x = s ?? app;
      clock = DateTime(2026, 10, 18 + j, 7);
      await x.koachRefresh();
      final base = x.program.week(15).day(j)!;
      expect(x.adaptOpen(15, base)?.koach?['state'], 'preview');
      return base;
    }

    /// Journée affichée de S15·J[j].
    DayPlan shown(int j, [AppStore? s]) {
      final x = s ?? app;
      final base = x.program.week(15).day(j)!;
      final a = x.sessionAdapt(15, j);
      return a == null ? x.withDayChanges(15, base) : x.adaptDay(15, base, a);
    }

    Exercise ex(int j, String start) => shown(
      j,
    ).exercises.firstWhere((e) => e.name.toUpperCase().startsWith(start));

    /// Séries pré-remplies validées (5 reps, 8 flammes) de [e].
    void faire(int j, Exercise e, {int? count}) {
      final base = app.program.week(15).day(j)!;
      final log = app.exLog(15, j, e);
      final n = count ?? log.sets.length;
      for (var i = 0; i < n; i++) {
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

    void finir(int j) {
      for (final e in shown(j).exercises) {
        faire(j, e);
      }
      app.markSessionDone(15, j, true);
    }

    Set<String> exercicesVerses() => {
      for (final ev in app.koachEngine.journal)
        if (ev['type'] == 'serie') '${(ev['serie'] as Map)['exerciseId']}',
    };

    Map<String, Object?>? servi(int j, String slot) {
      final items = app.sessionAdapt(15, j)?.koach?['items'];
      for (final it in (items as List? ?? const [])) {
        if (it is Map && it['slotId'] == slot) {
          return it.cast<String, Object?>();
        }
      }
      return null;
    }

    /// Jour de S15 où le bilan bas change au moins une ligne ([s] : magasin).
    Future<int> bilanBas([AppStore? s]) async {
      final x = s ?? app;
      for (final j in const [1, 2, 3, 4, 5, 6]) {
        final b0 = x.program.week(15).day(j);
        if (b0 == null || b0.exercises.isEmpty) continue;
        final base = await jour(j, x);
        x.adaptAnswer(15, base, _bas);
        expect(await x.koachStart(15, base), isTrue);
        if (x.koachBilan(15, j) != null) return j;
      }
      fail('aucune ligne changée par le bilan bas');
    }

    test(
      '« Garder l’écrit » (Libre) : bilan complet versé avec `applique: '
      'false` ; séance servie identique à celle sans forme du jour',
      () async {
        app.setGuidanceMode('free');
        final j = await bilanBas();
        final b = app.koachBilan(15, j)!;
        expect(b.forme, isFalse);
        expect(
          koachTexteFormeNotee(b),
          'Koach note ta forme du jour même si tu gardes l’écrit.',
        );
        final ev = app.koachEngine.journal.lastWhere(
          (e) => e['type'] == 'seance_debut',
        );
        final bilan = ev['bilan'] as Map;
        _sonde('bilan_verse', bilan);
        expect(bilan['applique'], isFalse);
        expect(bilan['overall'], 1);
        expect(bilan['energy'], 1);
        expect(bilan['sleepQuality'], 1);
        // Le journal gardé (sauvegarde) porte le drapeau tel quel.
        final doc = jsonDecode(app.exportAll()) as Map<String, dynamic>;
        expect(jsonEncode(doc), contains('"applique":false'));
        final plan = jsonEncode(app.sessionAdapt(15, j)!.plan.toJson());
        final base = app.program.week(15).day(j)!;
        // Même séance, même état du moteur (journal ramené au début de la
        // séance), sans bilan : servie à l'identique.
        app.adaptAnswer(15, base, const kc.HealthCheck());
        expect(app.sessionAdapt(15, j)!.check, isNull);
        expect(await app.koachRecommencerPourChangement(15, base), isTrue);
        final refEv = app.koachEngine.journal.lastWhere(
          (e) => e['type'] == 'seance_debut',
        );
        expect(refEv['bilan'], isNull);
        expect(jsonEncode(app.sessionAdapt(15, j)!.plan.toJson()), plan);
        // De nouveau le bilan bas : la même séance.
        app.adaptAnswer(15, base, _bas);
        expect(await app.koachRecommencerPourChangement(15, base), isTrue);
        expect(jsonEncode(app.sessionAdapt(15, j)!.plan.toJson()), plan);
        expect(app.koachBilan(15, j), isNotNull);
        // « Garder l'écrit » : choix noté, séance inchangée.
        expect(await app.koachBilanChoose(15, base, false), isTrue);
        expect(jsonEncode(app.sessionAdapt(15, j)!.plan.toJson()), plan);
        // Après la première série, une cible plus basse est dite sur la
        // carte (autorégulation) ; relevé seulement (dépend du moteur).
        final e = shown(j).exercises.firstWhere((x) => x.engine);
        faire(j, e, count: 1);
        final ligne = app.koachReasonLine(15, j, e);
        _sonde('ligne_apres_serie_1', ligne);
        if (ligne != null && ligne.startsWith('Koach ajuste la suite')) {
          expect(ligne, contains('au lieu de'));
        }
      },
    );

    test('Assisté puis « Annuler » : bilan versé sans être appliqué', () async {
      expect(app.adaptMode, 'assisted');
      final j = await bilanBas();
      final base = app.program.week(15).day(j)!;
      final ev0 = app.koachEngine.journal.lastWhere(
        (e) => e['type'] == 'seance_debut',
      );
      expect((ev0['bilan'] as Map).containsKey('applique'), isFalse);
      final debuts = app.koachEngine.journal
          .where((e) => e['type'] == 'seance_debut')
          .length;
      expect(await app.koachBilanChoose(15, base, false), isTrue);
      final ev = app.koachEngine.journal.lastWhere(
        (e) => e['type'] == 'seance_debut',
      );
      expect((ev['bilan'] as Map)['applique'], isFalse);
      expect((ev['bilan'] as Map)['overall'], 1);
      // Un seul début de séance au journal (retour au début).
      expect(
        app.koachEngine.journal.where((e) => e['type'] == 'seance_debut'),
        hasLength(debuts),
      );
    });

    test('douleur en Libre « Garder l’écrit » : conduite inchangée', () async {
      app.setGuidanceMode('free');
      final base = await jour(2);
      app.adaptAnswer(
        15,
        base,
        const kc.HealthCheck(
          overall: 2,
          energy: 2,
          pains: [
            kc.PainReport(
              zone: kc.BodyZone.shoulder,
              side: kc.BodySide.right,
              intensity: 6,
              phase: kc.PainPhase.before,
            ),
          ],
        ),
      );
      expect(await app.koachStart(15, base), isTrue);
      final ev = app.koachEngine.journal.lastWhere(
        (e) => e['type'] == 'seance_debut',
      );
      final bilan = ev['bilan'] as Map;
      expect(bilan['applique'], isFalse);
      expect((bilan['pains'] as List), hasLength(1));
      final st = app.sessionAdapt(15, 2)!.koach!;
      _sonde('douleur_retraits', st['retraits']);
      final raisons = [
        for (final r in (st['raisons'] as List)) '${(r as Map)['code']}',
      ];
      expect(raisons.any((c) => c.startsWith('koach.douleur')), isTrue);
    });

    test('J5, dip lesté : « Pourquoi ? › pas de matériel › ceinture de '
        'lest » : propositions groupées, étiquetées, sans ceinture, sans '
        'HSPU ; recherche dans toute la base inchangée', () async {
      app.setGuidanceMode('free');
      await jour(5);
      final dip = ex(5, 'DIP LESTÉ');
      expect(app.dayMissingChoices(15, 5, dip), contains('ceinture de lest'));
      final o0 = app.dayReplaceOptions(15, shown(5), dip)!;
      _sonde('options_sans_raison', [
        for (final p in o0.proposals) [p.id, p.label, p.depart],
      ]);
      expect(o0.reason, 'autre');
      expect(o0.proposals, isNotEmpty);
      final o = app.dayReplaceOptions(
        15,
        shown(5),
        dip,
        reason: 'pas_de_materiel',
        missing: const ['ceinture de lest'],
      )!;
      _sonde('options_ceinture', [
        for (final p in o.proposals) [p.id, p.label, p.text, p.depart],
      ]);
      expect(o.reason, 'pas_de_materiel');
      expect(o.proposals, isNotEmpty);
      final ids = o.proposals.map((p) => p.id).toSet();
      expect(ids, isNot(contains(_hspu)));
      expect(ids, isNot(contains('sl-dips-leste')));
      // Déjà dans la séance : jamais proposés.
      expect(ids, isNot(contains('cd-dips-explosifs')));
      for (final p in o.proposals) {
        expect(kDayReplaceLabels.keys, contains(p.label));
        expect(p.text, isNotEmpty);
        expect(
          app.content.catalog!.find(p.id)!.equipment,
          isNot(contains('ceinture de lest')),
          reason: p.id,
        );
      }
      expect(o.proposals.map((p) => p.label), contains('sans_materiel'));
      expect(o.proposals.any((p) => dayHasDepart(p.depart)), isTrue);
      // Trop dur : jamais plus difficile.
      final dur = app.dayReplaceOptions(15, shown(5), dip, reason: 'trop_dur')!;
      expect(dur.reason, 'trop_dur');
      // Assisté : mêmes propositions (seule la recherche libre change).
      app.setGuidanceMode('assisted');
      final a = app.dayReplaceOptions(
        15,
        shown(5),
        dip,
        reason: 'pas_de_materiel',
        missing: const ['ceinture de lest'],
      )!;
      expect(
        a.proposals.map((p) => p.id).toList(),
        o.proposals.map((p) => p.id).toList(),
      );
    });

    test('J5, dip lesté (départ chronométré tel qu’écrit) remplacé avant le '
        'début : cible de départ servie, Koach reçoit le remplaçant, séries '
        'versées sous l’exercice réel', () async {
      app.setGuidanceMode('free');
      final base = await jour(5);
      final dip = ex(5, 'DIP LESTÉ');
      final key = dayChangeKey(dip.id);
      final slot = app.adaptSlotOf(15, 5, dip.id)!;
      final o = app.dayReplaceOptions(
        15,
        shown(5),
        dip,
        reason: 'pas_de_materiel',
        missing: const ['ceinture de lest'],
      )!;
      final p = o.proposals.firstWhere(
        (x) => dayHasDepart(x.depart),
        orElse: () => o.proposals.first,
      );
      app.dayReplace(
        15,
        shown(5),
        dip,
        to: p.id,
        name: p.name,
        reason: o.reason,
        missing: const ['ceinture de lest'],
        depart: p.depart,
        label: p.label,
      );
      final c = app.dayChangeOf(15, 5, key)!;
      expect(c['raison'], 'pas_de_materiel');
      expect(c['manque'], ['ceinture de lest']);
      expect(c['etiquette'], p.label);
      final r = shown(5).exercises.firstWhere((e) => e.catalogId == p.id);
      expect(r.id, '$key~${p.id}');
      _sonde('remplacant_pr8', {
        'id': p.id,
        'depart': p.depart,
        'series': app.setsLabel(r),
        'pourquoi': r.why,
      });
      if (daySetsAtDepart(app.setsLabel(dip), p.depart) case final t?) {
        expect(app.setsLabel(r), t);
        expect(r.why, contains('Cible de départ de Koach'));
      }
      expect(app.setCount(r), app.setCount(dip));
      expect(
        app.exerciseGroupOf(15, 5, r)?.toJson(),
        app.exerciseGroupOf(15, 5, dip)?.toJson(),
      );
      // Début réel : Koach reçoit le remplaçant à l'emplacement.
      expect(await app.koachStart(15, base), isTrue);
      final s = servi(5, slot)!;
      expect(s['exerciseId'], p.id);
      expect((s['remplace'] as Map)['exerciseId'], 'sl-dips-leste');
      expect((s['remplace'] as Map)['raison'], 'pas_de_materiel');
      final plan = app.koachEngine.journal.lastWhere(
        (e) => e['type'] == 'plan',
      );
      _sonde('plan_remplace', (plan['contraintes'] as Map)['zones'] is Map);
      final zones = (plan['contraintes'] as Map)['zones'] as Map;
      expect(zones.containsKey(p.id), isTrue);
      expect(
        ((plan['contraintes'] as Map)['grilles'] as Map).containsKey(p.id),
        isTrue,
      );
      finir(5);
      final verses = exercicesVerses();
      expect(verses, contains(p.id));
      expect(
        app.koachEngine.journal.where(
          (ev) =>
              ev['type'] == 'serie' &&
              (ev['serie'] as Map)['slotId'] == slot &&
              (ev['serie'] as Map)['exerciseId'] == 'sl-dips-leste',
        ),
        isEmpty,
      );
    });

    /// Ligne non principale de S15·J[j] (ni départ chronométré servi tel
    /// qu'écrit) qui a une proposition suivie par Koach ; [sauf] : lignes
    /// écrites à ignorer.
    ({Exercise e, DayReplaceProposal p}) accessoire(
      int j, {
      Set<String> sauf = const {},
    }) {
      for (final e in shown(j).exercises) {
        if (sauf.contains(dayChangeKey(e.id)) || !e.engine) continue;
        final slot = app.adaptSlotOf(15, j, e.id);
        if (slot == null || app.adaptAsWritten(15, slot)) continue;
        if (app.koachJourInfo(15, j)?.roles[slot] == 'main') continue;
        if (!app.dayCanChange(15, j, e)) continue;
        final o = app.dayReplaceOptions(15, shown(j), e);
        final p = o?.proposals
            .where((x) => app.koachLive!.fiches.containsKey(x.id))
            .firstOrNull;
        if (p != null) return (e: e, p: p);
      }
      fail('aucun accessoire remplaçable le J$j');
    }

    test('accessoire remplacé avant le début : Koach le sert avec ses '
        'propres cibles et la raison du remplacement', () async {
      app.setGuidanceMode('free');
      final base = await jour(1);
      final (:e, :p) = accessoire(1);
      final slot = app.adaptSlotOf(15, 1, e.id)!;
      app.dayReplace(
        15,
        shown(1),
        e,
        to: p.id,
        name: p.name,
        depart: p.depart,
        label: p.label,
      );
      expect(await app.koachStart(15, base), isTrue);
      final s = servi(1, slot)!;
      expect(s['exerciseId'], p.id);
      final r = shown(1).exercises.firstWhere((x) => x.catalogId == p.id);
      _sonde('accessoire', {
        'de': e.name,
        'id': p.id,
        'etiquette': p.label,
        'servi': s,
        'series': app.setsLabel(r),
        'engine': r.engine,
        'raison': app.koachReasonLine(15, 1, r),
      });
      expect(r.engine, isTrue);
      expect(r.id, '${dayChangeKey(e.id)}~${p.id}');
      final raisons = [
        for (final x in (app.sessionAdapt(15, 1)!.koach!['ouverture'] as List))
          '${(x as Map)['code']}',
      ];
      expect(raisons, contains('koach.remplacement'));
      // Cible de Koach demandée pour la première série.
      app.exLog(15, 1, r);
      app.koachEnsureTarget(15, base, r, 0);
      final cibles = app.sessionAdapt(15, 1)!.koach!['cibles'] as Map;
      _sonde('accessoire_cible_0', cibles[slot]);
      expect(cibles[slot], isA<Map>());
      expect((cibles[slot] as Map).containsKey('0'), isTrue);
      // Un remplaçant servi par Koach revient à l'écrit tant que la séance
      // peut repartir de son début.
      expect(app.dayCanUndo(15, 1, dayChangeKey(e.id)), isTrue);
    });

    test('séance commencée sans série validée : elle repart de son début et '
        'Koach sert le remplaçant ; avec une série validée ailleurs : cible '
        'de départ, pas de retour possible du remplaçant servi', () async {
      app.setGuidanceMode('free');
      final base = await jour(1);
      expect(await app.koachStart(15, base), isTrue);
      final n0 = app.sessionAdapt(15, 1)!.koach!['n0'] as int;
      final debuts = app.koachEngine.journal
          .where((e) => e['type'] == 'seance_debut')
          .length;
      final (:e, :p) = accessoire(1);
      final key = dayChangeKey(e.id);
      final slot = app.adaptSlotOf(15, 1, e.id)!;
      expect(app.koachRecommencable(15, 1), isTrue);
      app.dayReplace(
        15,
        shown(1),
        e,
        to: p.id,
        name: p.name,
        depart: p.depart,
        label: p.label,
      );
      expect(await app.dayServeChanges(15, base), isTrue);
      expect(servi(1, slot)!['exerciseId'], p.id);
      expect(app.sessionAdapt(15, 1)!.koach!['n0'], n0);
      expect(
        app.koachEngine.journal.where((x) => x['type'] == 'seance_debut'),
        hasLength(debuts),
      );
      // Une série validée sur la première ligne : plus de retour au début.
      final first = shown(1).exercises.first;
      faire(1, first, count: 1);
      expect(app.koachRecommencable(15, 1), isFalse);
      expect(app.dayCanUndo(15, 1, key), isFalse);
      // Un autre accessoire remplacé maintenant : cible de départ.
      final second = accessoire(1, sauf: {key, dayChangeKey(first.id)});
      final q = second.p;
      app.dayReplace(
        15,
        shown(1),
        second.e,
        to: q.id,
        name: q.name,
        depart: q.depart,
        label: q.label,
      );
      expect(await app.dayServeChanges(15, base), isFalse);
      final r = shown(1).exercises.firstWhere((x) => x.catalogId == q.id);
      _sonde('apres_serie', {
        'de': second.e.name,
        'id': q.id,
        'depart': q.depart,
        'series': app.setsLabel(r),
        'pourquoi': r.why,
      });
      expect(r.engine, isFalse);
      if (dayDepartText(q.depart, (x) => '$x kg') != null) {
        expect(r.why, contains('Cible de départ de Koach'));
      }
      expect(app.dayCanUndo(15, 1, dayChangeKey(second.e.id)), isTrue);
    });

    test('passage depuis dev7.7.2 et export / import à l’identique', () async {
      app.setGuidanceMode('free');
      await jour(1);
      final (:e, :p) = accessoire(1);
      final muscleUp = ex(1, 'MUSCLE-UP LESTÉ');
      // Changement au format de dev7.7.2 (sans raison ni cible) : lu tel
      // quel.
      app.dayReplace(15, shown(1), muscleUp, to: _hspu, name: 'HSPU');
      app.dayReplace(
        15,
        shown(1),
        e,
        to: p.id,
        name: p.name,
        reason: 'trop_dur',
        depart: p.depart,
        label: p.label,
      );
      app.forgetConsultation(15, 1);
      expect(app.dayChanges(15, 1), hasLength(2));
      await app.flush();
      final out1 = app.exportAll();
      final doc = jsonDecode(out1) as Map<String, dynamic>;
      expect(await app.importAll(out1), isTrue);
      final out2 = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      for (final k in doc.keys) {
        if (k == 'exportedAt' || k == 'savedAt') continue;
        expect(jsonEncode(out2[k]), jsonEncode(doc[k]), reason: k);
      }
      final c = app.dayChanges(15, 1);
      expect(c[dayChangeKey(muscleUp.id)]!.containsKey('raison'), isFalse);
      expect(c[dayChangeKey(e.id)]!['raison'], 'trop_dur');
    });
  });

  group('écran « Remplacer pour aujourd’hui » (KB6)', () {
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

    final calls = <(String?, List<String>)>[];
    DayReplaceOptions options(String? reason, List<String> missing) {
      calls.add((reason, missing));
      final sans = missing.contains('ceinture de lest');
      return (
        reason: reason ?? 'autre',
        proposals: [
          if (!sans)
            (
              id: 'sl-dips-banc-leste',
              name: 'Dips lestés sur banc',
              label: 'equivalent',
              text: 'Même mouvement.',
              depart: const <String, Object?>{'repsLow': 3, 'repsHigh': 3},
            ),
          (
            id: 'cd-dips-russes',
            name: 'Dips russes',
            label: 'sans_materiel',
            text: 'Au poids du corps, sans ceinture de lest.',
            depart: const <String, Object?>{'repsLow': 6, 'repsHigh': 8},
          ),
          (
            id: 'sw-dips-negatifs',
            name: 'Dips négatifs',
            label: 'plus_facile',
            text: 'Version plus accessible.',
            depart: const <String, Object?>{},
          ),
        ],
      );
    }

    Future<ReplacePick?> ouvrir(
      WidgetTester tester, {
      required bool free,
      required Future<void> Function() act,
    }) async {
      ReplacePick? out;
      calls.clear();
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
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
                      free: free,
                      options: options,
                      missingChoices: const [
                        'barres parallèles',
                        'ceinture de lest',
                      ],
                      departOf: (id) => id == _hspu
                          ? const {'repsLow': 4, 'repsHigh': 5}
                          : null,
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

    testWidgets('Libre : propositions groupées, « Pourquoi ? › Il me manque '
        ': ceinture de lest » recalcule ; choix avec sa cible de départ', (
      tester,
    ) async {
      final pick = await ouvrir(
        tester,
        free: true,
        act: () async {
          expect(find.byKey(const ValueKey('replace-why')), findsOneWidget);
          expect(
            find.byKey(const ValueKey('replace-group-equivalent')),
            findsOneWidget,
          );
          expect(find.text('Équivalent'), findsOneWidget);
          expect(find.text('Sans ce matériel'), findsOneWidget);
          expect(find.text('Plus facile'), findsOneWidget);
          expect(find.textContaining('Départ : 6-8 reps'), findsOneWidget);
          expect(find.textContaining('Cible à choisir'), findsOneWidget);
          // La recherche de toute la base reste là, sous les propositions.
          expect(find.byKey(const ValueKey('replace-search')), findsOneWidget);
          expect(
            tester.getTopLeft(find.byKey(const ValueKey('replace-search'))).dy,
            greaterThan(
              tester
                  .getTopLeft(
                    find.byKey(const ValueKey('replace-group-equivalent')),
                  )
                  .dy,
            ),
          );
          expect(find.byKey(const ValueKey('replace-missing')), findsNothing);
          await tester.tap(
            find.byKey(const ValueKey('replace-why-pas_de_materiel')),
          );
          await tester.pumpAndSettle();
          expect(find.text('Il me manque :'), findsOneWidget);
          await tester.tap(
            find.byKey(const ValueKey('replace-missing-ceinture de lest')),
          );
          await tester.pumpAndSettle();
          expect(calls.last.$1, 'pas_de_materiel');
          expect(calls.last.$2, ['ceinture de lest']);
          expect(
            find.byKey(const ValueKey('replace-group-equivalent')),
            findsNothing,
          );
          await tester.tap(
            find.byKey(const ValueKey('replace-proposal-cd-dips-russes')),
          );
        },
      );
      expect(pick?.id, 'cd-dips-russes');
      expect(pick?.reason, 'pas_de_materiel');
      expect(pick?.missing, ['ceinture de lest']);
      expect(pick?.label, 'sans_materiel');
      expect(pick?.depart, {'repsLow': 6, 'repsHigh': 8});
    });

    testWidgets('Libre : recherche dans toute la base, cible de départ de '
        'l’exercice trouvé', (tester) async {
      final pick = await ouvrir(
        tester,
        free: true,
        act: () async {
          await tester.enterText(
            find.descendant(
              of: find.byKey(const ValueKey('replace-search')),
              matching: find.byType(EditableText),
            ),
            'hspu au mur dos',
          );
          await tester.pumpAndSettle();
          // Propositions et question masquées pendant la recherche.
          expect(find.byKey(const ValueKey('replace-why')), findsNothing);
          final row = find.byKey(const ValueKey('replace-$_hspu'));
          await tester.ensureVisible(row);
          await tester.pumpAndSettle();
          await tester.tap(row);
        },
      );
      expect(pick?.id, _hspu);
      expect(pick?.depart, {'repsLow': 4, 'repsHigh': 5});
      expect(pick?.reason, isNull);
    });

    testWidgets('Assisté : propositions groupées seules, le choix libre est '
        'dit', (tester) async {
      final pick = await ouvrir(
        tester,
        free: false,
        act: () async {
          expect(find.byKey(const ValueKey('replace-search')), findsNothing);
          expect(
            find.byKey(const ValueKey('replace-free-hint')),
            findsOneWidget,
          );
          expect(find.byKey(const ValueKey('replace-why')), findsOneWidget);
          await tester.tap(
            find.byKey(const ValueKey('replace-proposal-sw-dips-negatifs')),
          );
        },
      );
      expect(pick?.id, 'sw-dips-negatifs');
      expect(pick?.label, 'plus_facile');
      expect(pick?.depart, isEmpty);
    });
  });
}
