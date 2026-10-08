// CI1c (dev6.9.2, pipeline CP, DECISIONS_CP.md C10) sur émulateur Android,
// lancé par tools/ci3d_drive.sh avec le build de développement :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/koach_ci1c_test.dart \
//     --dart-define=M6B_PART=a --dart-define=KALIS_DEV=true -d emulator-5554
// a = thème sombre, rouge Kalis ; b = thème clair, violet.
// Session personnelle (programme importé du propriétaire, mode libre) :
// Koach propose de réorganiser une séance (un exercice retiré, un autre
// remplacé) ; « Accepter » dans Évolution → l'accueil, le programme et la
// séance montrent tout de suite le changement, l'original reste en dessous ;
// une séance future ouverte pour voir puis fermée ne laisse aucune entrée.
// Session de test (5 appuis) : programme street créé, séance de demain
// ouverte à l'avance, proposition acceptée, séance rouverte à jour ;
// suppression de la session de test, session personnelle intacte.
// Relevé `ci1c_releve_<partie>.json`, captures `ci1c_*_<thème>.png`.
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/dev/dev_session.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/plan/evolution_widgets.dart'
    show EvolutionScreen;
import 'package:streetlift_tracker/session_prefs.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

final _root = GlobalKey();
const _part = String.fromEnvironment('M6B_PART', defaultValue: 'a');
const _limit = Timeout(Duration(minutes: 8));

/// Réorganisation de la journée de [place] à partir de sa semaine : un
/// emplacement retiré, un autre reçoit l'exercice [to].
kc.Proposal _restructure(
  AdaptPlace place, {
  required String removed,
  required String swapped,
  required String to,
}) {
  final b = place.block;
  return kc.Proposal(
    id: 'session:${place.dayIndex}:${place.blockId}@${place.weekIndex}',
    kind: kc.ProposalKind.sessionRestructure,
    scope: kc.ProposalScope.session,
    createdOn: civilOf(store.storeClock()),
    confidence: .9,
    unlockLevel: kc.UnlockLevel.sessionRestructure,
    autoApplicable: true,
    block: kc.ProgramBlock(
      pass1: b.pass1.copyWith(
        days: [
          for (final d in b.pass1.days)
            d.copyWith(
              slots: [
                for (final s in d.slots)
                  s.slotId == swapped ? s.copyWith(exerciseId: to) : s,
              ],
            ),
        ],
      ),
      pass2: b.pass2.copyWith(
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
      ),
    ),
    reasons: const [
      kc.Reason(
        code: 'adapt.time_short',
        params: {'minutesAvailable': 30, 'minutesPlanned': 60},
      ),
    ],
  );
}

/// Une série de plus sur [item] (semaine et journée de [place]).
kc.Proposal _volume(AdaptPlace place, kc.ExercisePrescription item) =>
    kc.Proposal(
      id: 'volume:${item.slotId}@${place.weekIndex}',
      kind: kc.ProposalKind.volume,
      scope: kc.ProposalScope.exercise,
      createdOn: civilOf(store.storeClock()),
      confidence: .74,
      unlockLevel: kc.UnlockLevel.volume,
      autoApplicable: true,
      exerciseId: item.exerciseId,
      diff: kc.PlanDiff(
        changes: [
          kc.PlanChange(
            kind: kc.ChangeKind.prescriptionChanged,
            dayIndex: place.dayIndex,
            weekIndex: place.weekIndex,
            slotId: item.slotId,
            fromPrescription: item,
            toPrescription: item.copyWith(sets: item.sets + 1),
            reasons: const [
              kc.Reason(code: 'adapt.volume_up', params: {'sets': 1}),
            ],
          ),
        ],
      ),
      reasons: const [
        kc.Reason(code: 'adapt.volume_up', params: {'sets': 1}),
      ],
    );

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final data = <String, Object?>{};
  final dark = _part == 'a';
  final theme = dark ? 'sombre' : 'clair';
  final accent = dark ? 'rouge' : 'violet';
  final releve = <String, Object?>{
    'partie': _part,
    'theme': theme,
    'couleur_dominante': accent,
  };
  binding.reportData = data;

  void record() => data['ci1c_releve_$_part.json'] =
      const JsonEncoder.withIndent('  ').convert(releve);

  Future<void> shot(String name) async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['ci1c_${name}_$theme.png'] = base64Encode(png.buffer.asUint8List());
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

  /// Prochaine journée d'entraînement à partir d'aujourd'hui (décalage
  /// [after] jours au moins) servie par le moteur (semaine, J, place).
  (int, int, AdaptPlace)? nextDay({int after = 0}) {
    final now = store.storeClock();
    for (var k = after; k < 21; k++) {
      final d = DateTime(now.year, now.month, now.day + k);
      if (!store.program.containsDate(d)) continue;
      final w = store.program.weekFor(d);
      final o = store.program.offsetOf(d)!;
      final j = o % 7 + 1;
      final day = store.program.week(w).day(j);
      if (day == null || day.exercises.isEmpty) continue;
      final place = store.adaptPlaceOf(w, j);
      if (place == null || (place.day?.items.length ?? 0) < 3) continue;
      return (w, j, place);
    }
    return null;
  }

  /// Exercice affiché de l'emplacement [slot] (programme importé).
  Exercise? shownFor(int w, int j, String slot) {
    for (final e in store.program.week(w).day(j)!.exercises) {
      if (store.adaptSlotOf(w, j, e.id) == slot) return e;
    }
    return null;
  }

  Future<void> openSession(WidgetTester tester, int w, int j) async {
    final week = store.program.week(w);
    final day = week.day(j)!;
    unawaited(
      appNavigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => SessionScreen(week: week, day: day),
        ),
      ),
    );
    await until(tester, find.byKey(const ValueKey('health-question')));
    await wait(tester, 1000);
  }

  /// Proposition reçue puis acceptée (« Accepter » de Koach, mode libre)
  /// sans image entre les deux : la revue suivante du moteur (aucune
  /// proposition réelle dans ce journal) retirerait une proposition en
  /// attente. Écran Évolution ensuite : historique « Accepté ».
  Future<void> accept(
    WidgetTester tester,
    String name,
    AdaptPlace place,
    kc.Proposal p,
  ) async {
    store.evolutionReceive(place, [p]);
    final pending = store.evolutionPending;
    releve['${name}_en_attente'] = pending.length == 1;
    if (pending.isNotEmpty) store.evolutionAccept(pending.single);
    releve['${name}_acceptee'] = store.planEvolution.entries.any(
      (e) => e.id == p.id && e.status == 'accepted',
    );
    await wait(tester, 800);
    await push(tester, const EvolutionScreen(), 2000);
    await shot('${name}_evolution');
    await home(tester);
  }

  testWidgets('CI1c $_part ($theme, $accent) : ajustement de Koach accepté '
      'appliqué tout de suite ; séance consultée jamais figée', (tester) async {
    final raw = await SharedPreferences.getInstance();
    await raw.clear();
    final seed = AppStore();
    await seed.init();
    seed.settings.theme = dark ? 'dark' : 'light';
    seed.settings.accent = accent;
    seed.saveSettings();
    // Session personnelle : programme importé du propriétaire commencé il
    // y a 10 jours, profil d'exemple en mode libre.
    final real = DateTime.now();
    await seed.configureStart(DateTime(real.year, real.month, real.day - 10));
    seed.saveAthleteProfile(
      ProfileDraft.of(
        sampleAthleteProfile(
          on: civilOf(real.subtract(const Duration(days: 20))),
          guidance: kc.GuidanceMode.free,
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

    // 1. Programme importé : réorganisation proposée puis acceptée.
    final hit = nextDay();
    releve['perso_jour'] = hit == null ? null : 'S${hit.$1}-J${hit.$2}';
    if (hit != null) {
      final (w, j, place) = hit;
      releve['perso_importe'] = place.imported;
      final items = place.day!.items;
      final removed = items[1], swapped = items[2];
      final to = items
          .firstWhere(
            (i) =>
                i.exerciseId != swapped.exerciseId &&
                (i.secondsLow == null) == (swapped.secondsLow == null),
            orElse: () => items.first,
          )
          .exerciseId;
      final before = store.program.week(w).day(j)!.exercises.length;
      await accept(
        tester,
        '01_perso',
        place,
        _restructure(
          place,
          removed: removed.slotId,
          swapped: swapped.slotId,
          to: to,
        ),
      );
      final shown = store.program.week(w).day(j)!;
      releve['perso_couche'] = !identical(shown.original, shown);
      releve['perso_retire_affiche'] = shownFor(w, j, removed.slotId) == null;
      releve['perso_exercices'] = '$before → ${shown.exercises.length}';
      final sw = shownFor(w, j, swapped.slotId);
      releve['perso_remplace_affiche'] = sw?.catalogId == to;
      releve['perso_nom'] = sw?.name;
      releve['perso_original_intact'] =
          shown.original.exercises.length == before;
      await scrollTo(tester, find.byKey(ValueKey('programme-day-$j')));
      await shot('02_perso_accueil');
      // Séance : le changement est servi.
      await openSession(tester, w, j);
      await shot('03_perso_bilan');
      final a = store.sessionAdapt(w, j);
      final served = a == null ? null : store.adaptDay(w, shown, a);
      releve['perso_retire_servi'] =
          served != null &&
          served.exercises.every(
            (e) => store.adaptSlotOf(w, j, e.id) != removed.slotId,
          );
      final se = served?.exercises
          .where((e) => store.adaptSlotOf(w, j, e.id) == swapped.slotId)
          .firstOrNull;
      releve['perso_remplace_servi'] = se?.catalogId == to;
      final menu = find.text('Exercices');
      if (menu.evaluate().isNotEmpty) {
        await tapF(tester, menu, ms: 900);
        releve['perso_liste_nom'] = find
            .descendant(
              of: find.byType(ListTile),
              matching: find.textContaining(
                store.splitName(store.adaptExerciseName(to)).$1,
              ),
            )
            .evaluate()
            .isNotEmpty;
        await shot('04_perso_liste');
        Navigator.of(tester.element(find.byType(ListTile).first)).pop();
        await wait(tester, 600);
      }
      await home(tester);
      // 2. Séance du lendemain ouverte pour voir, puis fermée : aucune
      // entrée d'historique.
      final next = nextDay(after: 1);
      if (next != null) {
        final key = store.sessionKey(next.$1, next.$2);
        final had = store.logs.containsKey(key);
        await openSession(tester, next.$1, next.$2);
        await shot('05_perso_seance_future');
        await home(tester);
        await wait(tester, 1200);
        releve['perso_consultation_sans_entree'] =
            had || !store.logs.containsKey(key);
      }
    }
    await store.flush();
    final persoBefore = jsonEncode(KalisPrefs(raw, dev: false).snapshot());

    // 3. Session de test : programme street créé (mode libre), séance de
    // demain ouverte à l'avance, proposition acceptée, séance rouverte.
    final logo = find.byKey(const ValueKey('header-logo')).hitTestable();
    for (var i = 0; i < 5; i++) {
      await tester.tap(logo.first);
      await tester.pump(Duration(milliseconds: i < 4 ? 300 : 16));
    }
    await opened(tester);
    releve['dev_actif'] = DevSession.active.value;
    store.settings
      ..theme = dark ? 'dark' : 'light'
      ..accent = accent;
    store.saveSettings();
    store.saveAthleteProfile(
      ProfileDraft.of(
        sampleStreetProfile(
          on: civilOf(store.storeClock()),
          guidance: kc.GuidanceMode.free,
        ),
      )..consent = 'refused',
    );
    final c = PlanStore(store).newPlanCreation(journal: false);
    if (c != null) {
      c.start();
      c.createPass2();
      PlanStore(store).applyPlanCreation(c);
    }
    await store.flush();
    await wait(tester, 1200);
    final dev = nextDay(after: 1) ?? nextDay();
    releve['dev_jour'] = dev == null ? null : 'S${dev.$1}-J${dev.$2}';
    if (dev != null) {
      final (w, j, place) = dev;
      final item = place.day!.items.firstWhere(
        (i) => i.setTargets == null && i.sets < 10,
        orElse: () => place.day!.items.first,
      );
      await openSession(tester, w, j);
      final before = store.sessionAdapt(w, j);
      releve['dev_series_avant'] = before?.active.items
          .where((i) => i.slotId == item.slotId)
          .firstOrNull
          ?.sets;
      await shot('06_dev_seance_avant');
      await home(tester);
      await wait(tester, 1200);
      releve['dev_consultation_sans_entree'] = !store.logs.containsKey(
        store.sessionKey(w, j),
      );
      await accept(tester, '07_dev', place, _volume(place, item));
      await openSession(tester, w, j);
      final after = store.sessionAdapt(w, j);
      releve['dev_series_apres'] = after?.active.items
          .where((i) => i.slotId == item.slotId)
          .firstOrNull
          ?.sets;
      releve['dev_seance_a_jour'] = releve['dev_series_apres'] == item.sets + 1;
      await shot('08_dev_seance_apres');
      await home(tester);
    }

    // Suppression de la session de test : session personnelle intacte.
    final badge = find.byKey(const ValueKey('dev-badge'));
    if (badge.evaluate().isNotEmpty) {
      await tester.longPress(badge.first);
      await wait(tester, 1200);
      await tapF(tester, find.byKey(const ValueKey('dev-delete')));
      await tester.tap(find.byKey(const ValueKey('dev-delete-confirm')));
      await wait(tester, 600);
      await opened(tester);
    }
    releve['retour_perso'] = !DevSession.active.value;
    await store.flush();
    releve['perso_intacte'] =
        jsonEncode(KalisPrefs(raw, dev: false).snapshot()) == persoBefore;
    record();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();

    expect(releve['perso_accueil'], isTrue);
    expect(releve['perso_importe'], isTrue);
    expect(releve['01_perso_acceptee'], isTrue);
    expect(releve['perso_couche'], isTrue);
    expect(releve['perso_retire_affiche'], isTrue);
    expect(releve['perso_remplace_affiche'], isTrue);
    expect(releve['perso_original_intact'], isTrue);
    expect(releve['perso_retire_servi'], isTrue);
    expect(releve['perso_remplace_servi'], isTrue);
    expect(releve['perso_consultation_sans_entree'], isTrue);
    expect(releve['dev_actif'], isTrue);
    expect(releve['dev_consultation_sans_entree'], isTrue);
    expect(releve['07_dev_acceptee'], isTrue);
    expect(releve['dev_seance_a_jour'], isTrue);
    expect(releve['retour_perso'], isTrue);
    expect(releve['perso_intacte'], isTrue);
  }, timeout: _limit);
}
