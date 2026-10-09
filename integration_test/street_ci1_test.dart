// CI1 (dev6.9.0, pipeline CP) sur émulateur Android, lancé par
// tools/ci3d_drive.sh avec le build de développement (KALIS_DEV=true) :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/street_ci1_test.dart \
//     --dart-define=M6B_PART=a --dart-define=KALIS_DEV=true -d emulator-5554
// a = thème sombre, rouge Kalis, compétiteur de streetlifting ; b = thème
// clair, violet, débutant de calisthénie. Session personnelle (programme
// de 40 semaines du propriétaire) : Réglages › Mon programme avec la
// saison de son annotation (CI1e, C11 ; sans saison avant).
// Session de test (5 appuis) : profil street v3 complet et programme créé
// par le chemin calibré ; carte « Ta saison », écran MA SAISON (phases,
// compte à rebours, semaines du bloc, règles), jour J (partie a) ; séance
// servie par le mode coach de kalis_adapt : série de tête et séries
// allégées (partie a) ou maintien chronométré (partie b), panneau du coach,
// lignes nommées par leur rôle ; suppression de la session de test,
// session personnelle intacte.
// Relevé `ci1_releve_<partie>.json`, captures `ci1_*_<thème>.png`.
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/adapt/adapt_texts.dart' show painStopsOf;
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/dev/dev_session.dart';
import 'package:streetlift_tracker/kalis_clock.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/plan/season_view.dart';
import 'package:streetlift_tracker/program_screens.dart';
import 'package:streetlift_tracker/session_host.dart';
import 'package:streetlift_tracker/session_prefs.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

final _root = GlobalKey();
const _part = String.fromEnvironment('M6B_PART', defaultValue: 'a');
const _limit = Timeout(Duration(minutes: 8));

/// Calendrier fixe de la session de test : le programme commence le jeudi
/// 1er octobre 2026.
final _day0 = DateTime(2026, 10, 1);

int _offsetTo(DateTime d) {
  final real = KalisClock.realNow();
  return DateTime.utc(
    d.year,
    d.month,
    d.day,
  ).difference(DateTime.utc(real.year, real.month, real.day)).inDays;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final data = <String, Object?>{};
  final dark = _part == 'a';
  final theme = dark ? 'sombre' : 'clair';
  final accent = dark ? 'rouge' : 'violet';
  final beginner = !dark;
  final releve = <String, Object?>{
    'partie': _part,
    'theme': theme,
    'couleur_dominante': accent,
    'profil': beginner ? 'debutant_calisthenie' : 'competiteur_streetlifting',
  };
  binding.reportData = data;

  void record() => data['ci1_releve_$_part.json'] =
      const JsonEncoder.withIndent('  ').convert(releve);

  Future<void> shot(String name) async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['ci1_${name}_$theme.png'] = base64Encode(png.buffer.asUint8List());
    image.dispose();
    record();
  }

  Future<void> wait(WidgetTester tester, [int ms = 1500]) async {
    for (var i = 0; i < ms ~/ 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> opened(WidgetTester tester) async {
    for (var i = 0; i < 200; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byKey(const ValueKey('opening-logo')).evaluate().isEmpty &&
          i > 25) {
        break;
      }
    }
    await wait(tester, 1000);
  }

  Future<bool> until(WidgetTester tester, Finder f, {int max = 120}) async {
    for (var i = 0; i < max && f.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return f.evaluate().isNotEmpty;
  }

  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    for (final dy in const [-250.0, 250.0]) {
      for (var i = 0; i < 40 && target.hitTestable().evaluate().isEmpty; i++) {
        final lists = find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .hitTestable();
        if (lists.evaluate().isEmpty) break;
        final s = tester.state<ScrollableState>(lists.last).position;
        if ((dy < 0 && s.pixels >= s.maxScrollExtent) ||
            (dy > 0 && s.pixels <= s.minScrollExtent)) {
          break;
        }
        await tester.drag(lists.last, Offset(0, dy));
        await wait(tester, 300);
      }
    }
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target.last);
      await wait(tester, 400);
    }
  }

  Future<void> tapF(WidgetTester tester, Finder f, {int ms = 800}) async {
    await scrollTo(tester, f);
    await tester.tap(f.hitTestable().first);
    await wait(tester, ms);
  }

  Future<void> tap(WidgetTester tester, String key, {int ms = 800}) =>
      tapF(tester, find.byKey(ValueKey(key)), ms: ms);

  Future<void> top(WidgetTester tester) async {
    final lists = find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .hitTestable();
    for (var i = 0; i < 12 && lists.evaluate().isNotEmpty; i++) {
      final s = tester.state<ScrollableState>(lists.last);
      if (s.position.pixels <= 0) break;
      await tester.drag(lists.last, const Offset(0, 400));
      await wait(tester, 200);
    }
    await wait(tester, 500);
  }

  Future<void> push(WidgetTester tester, Widget screen, [int ms = 1800]) async {
    unawaited(
      appNavigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => screen),
      ),
    );
    await wait(tester, ms);
  }

  Future<void> home(WidgetTester tester) async {
    appNavigator.currentState!.popUntil((r) => r.isFirst);
    await wait(tester, 1200);
  }

  /// Première journée dont le bloc écrit une prescription qui vérifie
  /// [test] (semaine, jour J).
  (int, int, kc.ExercisePrescription)? findDay(
    bool Function(kc.ExercisePrescription) test,
  ) {
    for (var w = 1; w <= 8; w++) {
      for (var j = 1; j <= 7; j++) {
        final place = store.adaptPlaceOf(w, j);
        for (final it in place?.day?.items ?? const []) {
          if (test(it)) return (w, j, it);
        }
      }
    }
    return null;
  }

  testWidgets('CI1 $_part ($theme, $accent) : street calibré — saison, '
      'séance guidée, session personnelle intacte', (tester) async {
    final raw = await SharedPreferences.getInstance();
    await raw.clear();
    final seed = AppStore();
    await seed.init();
    seed.settings.theme = dark ? 'dark' : 'light';
    seed.settings.accent = accent;
    seed.saveSettings();
    // Session personnelle : programme du propriétaire commencé il y a
    // 10 jours, profil d'exemple (chemin 0.1 : sans ancienneté).
    final real = DateTime.now();
    await seed.configureStart(DateTime(real.year, real.month, real.day - 10));
    seed.saveAthleteProfile(
      ProfileDraft.of(
        sampleAthleteProfile(
          on: civilOf(real.subtract(const Duration(days: 20))),
        ),
      )..consent = 'refused',
    );
    await seed.flush();
    seed.dispose();

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    await tester.pumpWidget(RepaintBoundary(key: _root, child: kalisApp()));
    await opened(tester);
    releve['perso_accueil'] = await until(
      tester,
      find.byKey(const ValueKey('header-logo')),
    );

    // Session personnelle : programme du propriétaire, sans saison.
    await push(tester, const ProgramScreen());
    releve['perso_modele'] = await until(
      tester,
      find.byKey(const ValueKey('program-model')),
    );
    // CI1e (C11) : le programme de 40 semaines a maintenant sa saison.
    releve['perso_saison'] = find
        .byKey(const ValueKey('program-season'))
        .evaluate()
        .isNotEmpty;
    await shot('01_perso_programme');
    await home(tester);
    await store.flush();
    final persoBefore = jsonEncode(KalisPrefs(raw, dev: false).snapshot());

    // Session de test : profil street v3 et programme calibré.
    final logo = find.byKey(const ValueKey('header-logo')).hitTestable();
    for (var i = 0; i < 5; i++) {
      await tester.tap(logo.first);
      await tester.pump(Duration(milliseconds: i < 4 ? 300 : 16));
    }
    await opened(tester);
    releve['dev_actif'] = DevSession.active.value;
    await SessionHost.restart(
      () => DevSession.setOffsetDays(_offsetTo(_day0)),
      message: 'Voyage dans le temps',
    );
    await opened(tester);
    store.settings
      ..theme = dark ? 'dark' : 'light'
      ..accent = accent;
    store.saveSettings();
    store.saveAthleteProfile(
      ProfileDraft.of(
        sampleStreetProfile(
          on: civilOf(store.storeClock()),
          beginner: beginner,
        ),
      )..consent = 'refused',
    );
    releve['calibre'] = PlanStore(store).planCoachEligible;
    final c = PlanStore(store).newPlanCreation(journal: false);
    if (c != null) {
      c.start();
      c.createPass2();
      PlanStore(store).applyPlanCreation(c);
    }
    releve['dev_programme'] = PlanStore(store).programPlanned;
    releve['saison_phases'] = store.planProgram?.season?.phases.length ?? 0;
    await store.flush();
    await wait(tester, 1200);

    // Réglages › Mon programme : carte « Ta saison ».
    await push(tester, const ProgramScreen());
    releve['carte_saison'] = await until(
      tester,
      find.byKey(const ValueKey('program-season')),
    );
    await scrollTo(tester, find.byKey(const ValueKey('program-season')));
    await shot('02_carte_saison');
    await tap(tester, 'season-open', ms: 1800);
    releve['ecran_saison'] = await until(
      tester,
      find.byKey(const ValueKey('season-screen')),
    );
    await top(tester);
    await shot('03_saison');
    await scrollTo(tester, find.textContaining('semaine par semaine'));
    await shot('04_saison_semaines');
    if (find.textContaining('Règles de ton programme').evaluate().isNotEmpty) {
      await scrollTo(tester, find.textContaining('Règles de ton programme'));
      await shot('05_saison_regles');
    }
    if (!beginner) {
      await top(tester);
      final jj = find.byKey(const ValueKey('season-event-day'));
      releve['jour_j_bouton'] = jj.evaluate().isNotEmpty;
      if (jj.evaluate().isNotEmpty) {
        await tapF(tester, jj, ms: 2500);
        releve['jour_j'] = await until(
          tester,
          find.byKey(const ValueKey('event-day')),
        );
        releve['jour_j_tentatives'] = find
            .byWidgetPredicate(
              (w) =>
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.startsWith('event-lift-'),
            )
            .evaluate()
            .length;
        await shot('06_jour_j');
      }
    }
    await home(tester);

    // Séance : série de tête (compétiteur) ou maintien (débutant).
    final hit =
        findDay(
          (it) => beginner
              ? it.technique?.kind == kc.SetTechniqueKind.isometricHold
              : it.technique?.kind == kc.SetTechniqueKind.topSetBackoff,
        ) ??
        findDay((it) => it.technique != null);
    releve['seance_trouvee'] = hit != null;
    if (hit != null) {
      final (w, j, item) = hit;
      releve['seance'] =
          'S$w-J$j ${item.exerciseId} ${item.technique?.kind.code}';
      final s = store.program.start!;
      final date = DateTime(s.year, s.month, s.day + (w - 1) * 7 + j - 1);
      await SessionHost.restart(
        () => DevSession.setOffsetDays(_offsetTo(date)),
        message: 'Jour de la séance',
      );
      await opened(tester);
      final week = store.program.week(w);
      final day = week.day(j)!;
      unawaited(
        appNavigator.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => SessionScreen(week: week, day: day),
          ),
        ),
      );
      releve['bilan'] = await until(
        tester,
        find.byKey(const ValueKey('health-question')),
      );
      await wait(tester, 1000);
      await tap(tester, 'feel-4', ms: 2000);
      if (find.byKey(const ValueKey('adjust-go')).evaluate().isNotEmpty) {
        await tap(tester, 'adjust-go', ms: 1500);
      } else if (find
          .byKey(const ValueKey('bilan-start'))
          .evaluate()
          .isNotEmpty) {
        await tap(tester, 'bilan-start', ms: 1500);
      }
      await wait(tester, 800);
      // Page de l'exercice : liste « Exercices », titre de l'exercice.
      final a = store.sessionAdapt(w, j);
      final served = a == null ? null : store.adaptDay(w, day, a);
      final e = served?.exercises
          .where((x) => x.slotId == item.slotId)
          .firstOrNull;
      releve['exercice_servi'] = e != null;
      if (e != null) {
        // Page de l'exercice : liste « Exercices » (le titre peut être
        // celui d'un groupe « A + B »), sinon pages glissées une à une.
        final card = find.byKey(ValueKey('exercise-card-${e.id}'));
        final title = store.splitName(e.name).$1;
        final menu = find.text('Exercices');
        if (card.evaluate().isEmpty && menu.evaluate().isNotEmpty) {
          await tapF(tester, menu, ms: 900);
          final tile = find.descendant(
            of: find.byType(ListTile),
            matching: find.textContaining(title),
          );
          if (tile.evaluate().isNotEmpty) {
            await tapF(tester, tile, ms: 1500);
          } else if (find.byType(ListTile).evaluate().isNotEmpty) {
            Navigator.of(tester.element(find.byType(ListTile).first)).pop();
            await wait(tester, 600);
          }
        }
        for (var i = 0; i < 14 && card.evaluate().isEmpty; i++) {
          final pages = find.byType(PageView).hitTestable();
          if (pages.evaluate().isEmpty) break;
          await tester.fling(pages.last, const Offset(-320, 0), 1200);
          await wait(tester, 1200);
        }
        releve['page_exercice'] = card.evaluate().isNotEmpty;
        final panel = find.byKey(ValueKey('coach-panel-${e.id}'));
        releve['panneau_coach'] = await until(tester, panel, max: 40);
        releve['technique_affichee'] = find
            .byKey(ValueKey('coach-technique-${e.id}'))
            .evaluate()
            .isNotEmpty;
        releve['ligne_1'] = store.adaptRowLabel(w, j, e, 0);
        releve['ligne_2'] = e.forcedSets != null && e.forcedSets! > 1
            ? store.adaptRowLabel(w, j, e, 1)
            : null;
        releve['chrono'] = e.timer?['type'];
        releve['mesure'] = store.logSpec(e).kind;
        await top(tester);
        await shot('07_seance_exercice');
        if (panel.evaluate().isNotEmpty) {
          await scrollTo(tester, panel);
          await shot('08_seance_panneau');
          await tapF(tester, panel, ms: 1500);
          releve['feuille_coach'] = find
              .byKey(const ValueKey('koach-sheet'))
              .evaluate()
              .isNotEmpty;
          if (releve['feuille_coach'] == true) {
            await shot('09_notes_coach');
            Navigator.of(
              tester.element(find.byKey(const ValueKey('koach-sheet'))),
            ).pop();
            await wait(tester, 800);
          }
        }
        final valider = find.byTooltip('Valider la série 1');
        if (valider.evaluate().isNotEmpty) {
          await tapF(tester, valider, ms: 1500);
          releve['serie_1_validee'] =
              store.logs[store.sessionKey(w, j)]?.ex[e.id]?.sets.first.done;
          await shot('10_serie_validee');
        }
      }
      await home(tester);
    }

    // CI1b (paquets 0.2.2) : douleur au poignet à 4/10 notée à chaque
    // séance pendant plus de deux semaines (journal semé par le magasin, à
    // l'heure de chaque séance) → la séance suivante s'ouvre sur l'arrêt :
    // mouvements qui chargent le poignet retirés, consigne de consulter.
    {
      final start = store.program.start!;
      final weeks = store.planProgram?.blocks.first.weeks ?? 0;
      DateTime dateOf(int w, int j) =>
          DateTime(start.year, start.month, start.day + (w - 1) * 7 + j - 1);
      final days = <(int, int)>[
        for (var w = 1; w <= weeks; w++)
          for (var j = 1; j <= 7; j++)
            if (store.program.week(w).day(j)?.exercises.isNotEmpty ?? false)
              (w, j),
      ];
      // Séances semées jusqu'à deux semaines pleines entre le premier et
      // le dernier signalement (seuil du moteur), puis séance suivante.
      final clock = store.storeClock;
      const wrist = kc.PainReport(
        zone: kc.BodyZone.wristHand,
        side: kc.BodySide.both,
        intensity: 4,
        phase: kc.PainPhase.before,
      );
      var seeded = 0;
      DateTime? firstSeed, lastSeed;
      (int, int)? stop;
      for (final (w, j) in days) {
        final date = dateOf(w, j);
        // (La séance guidée plus haut est déjà commencée : jamais semée ni
        // choisie.)
        if (hit != null && hit.$1 == w && hit.$2 == j) continue;
        if (firstSeed != null &&
            lastSeed != null &&
            lastSeed.difference(firstSeed).inDays >= 15) {
          stop = (w, j);
          break;
        }
        store.storeClock = () => date.add(const Duration(hours: 9));
        final base = store.program.week(w).day(j)!;
        if (store.adaptOpen(w, base) == null) continue;
        final a = store.adaptAnswer(
          w,
          base,
          const kc.HealthCheck(pains: [wrist]),
        );
        if (a == null) continue;
        final served = store.adaptDay(w, base, a);
        for (final e in served.exercises) {
          final log = store.exLog(w, j, e);
          if (log.sets.isEmpty) continue;
          store.adaptPrefill(w, j, e, log);
          if (log.sets.first.reps.isEmpty) log.sets.first.reps = '5';
          log.sets.first.flames = 7;
          if (store.toggleSet(log, 0, store.logSpec(e)).ok) {
            seeded++;
            firstSeed ??= date;
            lastSeed = date;
            break;
          }
        }
      }
      store.storeClock = clock;
      releve['douleur_jour'] = stop == null ? null : 'S${stop.$1}-J${stop.$2}';
      final st = stop;
      if (st != null) {
        store.saveLogs();
        await store.flush();
        releve['douleur_seances'] = seeded;
        await SessionHost.restart(
          () => DevSession.setOffsetDays(_offsetTo(dateOf(st.$1, st.$2))),
          message: 'Jour de la séance',
        );
        await opened(tester);
        final week = store.program.week(st.$1);
        final day = week.day(st.$2)!;
        unawaited(
          appNavigator.currentState!.push(
            MaterialPageRoute<void>(
              builder: (_) => SessionScreen(week: week, day: day),
            ),
          ),
        );
        releve['douleur_carte'] = await until(
          tester,
          find.byKey(const ValueKey('health-pain-stop')),
        );
        final a = store.sessionAdapt(st.$1, st.$2);
        releve['douleur_arret'] =
            a?.active.reasons.any((r) => r.code == 'adapt.pain_persistent') ??
            false;
        releve['douleur_retires'] = [
          for (final x
              in a?.active.adjustments ?? const <kc.SessionAdjustment>[])
            if (x.kind == kc.AdjustmentKind.exerciseRemoved) x.exerciseId,
        ];
        await top(tester);
        await shot('11_douleur_arret');
        await tap(tester, 'feel-4', ms: 2000);
        // Après le bilan : la séance servie n'a aucun exercice retiré.
        final after = store.sessionAdapt(st.$1, st.$2);
        final servedIds = after == null
            ? const <String?>{}
            : {
                for (final e in store.adaptDay(st.$1, day, after).exercises)
                  e.catalogId,
              };
        releve['douleur_retires_absents'] = [
          for (final x
              in after?.active.adjustments ?? const <kc.SessionAdjustment>[])
            if (x.kind == kc.AdjustmentKind.exerciseRemoved &&
                x.reasons.any((r) => r.code == 'adapt.pain_persistent'))
              x.exerciseId,
        ].every((id) => !servedIds.contains(id));
        await home(tester);
        // CI1d (`kalis_adapt` 0.2.3) : le renvoi vers un professionnel n'est
        // répété qu'une fois par semaine ; la séance suivante de l'arrêt
        // garde la carte (exercices retirés ou remplacés), avec ou sans la
        // consigne de consulter selon le jour.
        // (Séance suivante, jamais la séance guidée déjà commencée ; la
        // carte n'est attendue que si l'arrêt y retire ou remplace un
        // mouvement : une séance sans appui du poignet n'en a pas.)
        final i = days.indexOf(st);
        final rest = [
          if (i >= 0)
            for (final d in days.skip(i + 1))
              if (hit == null || d != hit) d,
        ];
        final next = rest.isEmpty ? null : rest.first;
        if (next != null) {
          await SessionHost.restart(
            () => DevSession.setOffsetDays(_offsetTo(dateOf(next.$1, next.$2))),
            message: 'Séance suivante',
          );
          await opened(tester);
          final nweek = store.program.week(next.$1);
          final nday = nweek.day(next.$2)!;
          unawaited(
            appNavigator.currentState!.push(
              MaterialPageRoute<void>(
                builder: (_) => SessionScreen(week: nweek, day: nday),
              ),
            ),
          );
          releve['douleur_suite_jour'] = 'S${next.$1}-J${next.$2}';
          releve['douleur_suite_carte'] = await until(
            tester,
            find.byKey(const ValueKey('health-pain-stop')),
          );
          final na = store.sessionAdapt(next.$1, next.$2);
          releve['douleur_suite_attendue'] =
              na != null &&
              painStopsOf(na.active, store.adaptExerciseName).isNotEmpty;
          releve['douleur_suite_renvoi'] =
              na?.active.reasons.any(
                (r) => r.code == 'adapt.pain_persistent',
              ) ??
              false;
          releve['douleur_suite_texte'] = [
            for (final t in tester.widgetList<Text>(
              find.descendant(
                of: find.byKey(const ValueKey('health-pain-stop')),
                matching: find.byType(Text),
              ),
            ))
              t.data ?? '',
          ];
          await top(tester);
          await shot('12_douleur_suite');
          await home(tester);
        }
      }
    }

    // Suppression de la session de test : session personnelle intacte.
    final badge = find.byKey(const ValueKey('dev-badge'));
    if (badge.evaluate().isNotEmpty) {
      await tester.longPress(badge.first);
      await wait(tester, 1200);
      await tap(tester, 'dev-delete');
      await tester.tap(find.byKey(const ValueKey('dev-delete-confirm')));
      await wait(tester, 600);
      await opened(tester);
    }
    releve['retour_perso'] = !DevSession.active.value;
    await store.flush();
    releve['perso_intacte'] =
        jsonEncode(KalisPrefs(raw, dev: false).snapshot()) == persoBefore;
    releve['perso_saison_apres'] = storeSeasonOverview() != null;
    record();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();

    expect(releve['perso_modele'], isTrue);
    expect(releve['perso_saison'], isTrue);
    expect(releve['dev_actif'], isTrue);
    expect(releve['calibre'], isTrue);
    expect(releve['dev_programme'], isTrue);
    expect(releve['saison_phases'], greaterThan(0));
    expect(releve['carte_saison'], isTrue);
    expect(releve['ecran_saison'], isTrue);
    if (!beginner) expect(releve['jour_j'], isTrue);
    expect(releve['seance_trouvee'], isTrue);
    expect(releve['exercice_servi'], isTrue);
    expect(releve['panneau_coach'], isTrue);
    expect(releve['douleur_carte'], isTrue);
    expect(releve['douleur_arret'], isTrue);
    expect(releve['douleur_retires_absents'], isTrue);
    if (releve['douleur_suite_attendue'] == true) {
      expect(releve['douleur_suite_carte'], isTrue);
    }
    expect(releve['retour_perso'], isTrue);
    expect(releve['perso_intacte'], isTrue);
    expect(releve['perso_saison_apres'], isTrue);
  }, timeout: _limit);
}
