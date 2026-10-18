// KS1A (dev7.1.0, pipeline CP, types de jour de `kalis_core` 0.4.4 et
// `kalis_plan` 0.4.1, DECISIONS_CP.md C17.20) sur émulateur Android, lancé
// par tools/ci3d_drive.sh avec le build de développement :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/types_ks1a_test.dart \
//     --dart-define=M6B_PART=a --dart-define=KALIS_DEV=true -d emulator-5554
// a = thème sombre, rouge Kalis ; b = thème clair, violet.
// 1. Session personnelle (migration depuis dev7.0.0) : programme de 40
//    semaines du propriétaire commencé le 13/07/2026, journal saisi
//    jusqu'à la veille (S1 à S14). Au lancement : même journal, sauvegarde
//    d'origine, Koach pas actif (bascule fermée) ; types de jour affichés
//    à l'accueil (carte du jour, lignes des jours) et en tête de séance.
// 2. Session de test : profil street 50 / 50 à six séances de 120 min ;
//    programme créé par `kalis_plan` 0.4.1 : création (structure de la
//    semaine, types des jours), accueil (type, « sur 120 min
//    disponibles »), tête de séance ; échéance avancée en semaine 2 : Mon
//    programme propose le bloc suivant dès la semaine 3, bloc en cours
//    tronqué à ses deux semaines servies ; session personnelle intacte.
// Relevé `ks1a_releve_<partie>.json`, captures `ks1a_*_<thème>.png`.
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/dev/dev_session.dart';
import 'package:streetlift_tracker/home_screen.dart';
import 'package:streetlift_tracker/kalis_clock.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/nav_bar.dart';
import 'package:streetlift_tracker/plan/day_type.dart';
import 'package:streetlift_tracker/plan/plan_screens.dart';
import 'package:streetlift_tracker/program_screens.dart';
import 'package:streetlift_tracker/session_prefs.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

import '../test/l2_fixtures.dart';

final _root = GlobalKey();
const _part = String.fromEnvironment('M6B_PART', defaultValue: 'a');
const _limit = Timeout(Duration(minutes: 9));

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

  void record() => data['ks1a_releve_$_part.json'] =
      const JsonEncoder.withIndent('  ').convert(releve);

  Future<void> shot(String name) async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['ks1a_${name}_$theme.png'] = base64Encode(png.buffer.asUint8List());
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

  Future<void> home(WidgetTester tester) async {
    appNavigator.currentState!.popUntil((r) => r.isFirst);
    await wait(tester, 1200);
    AppTabs.open(appNavigator.currentContext!, AppTab.program);
    await wait(tester, 1200);
  }

  /// Texte d'un widget Text trouvé par sa clé (null : absent).
  String? textOf(String key) {
    final f = find.byKey(ValueKey(key));
    if (f.evaluate().isEmpty) return null;
    final w = f.evaluate().first.widget;
    return w is Text ? (w.data ?? w.textSpan?.toPlainText()) : null;
  }

  /// Sous-titre de la tête de séance (texte qui contient « S<n>, J<j> »).
  String? headerSubtitle() {
    final texts = find.descendant(
      of: find.byKey(const ValueKey('session-header')),
      matching: find.byType(Text),
    );
    for (final e in texts.evaluate()) {
      final w = e.widget as Text;
      final t = w.data ?? w.textSpan?.toPlainText() ?? '';
      // PR2 (dev7.1.2) : « S14 · J5 » (avant : « S14, J5 »).
      if (RegExp(r'S\d+(, | · )J\d').hasMatch(t)) return t;
    }
    return null;
  }

  /// Séance [w]·[j] ouverte (première page : bilan), tête relevée,
  /// capture, retour à l'accueil sans rien saisir.
  Future<String?> openHeader(
    WidgetTester tester,
    int w,
    int j,
    String name,
  ) async {
    final week = store.program.week(w);
    final day = week.day(j)!;
    unawaited(
      appNavigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => SessionScreen(week: week, day: day),
        ),
      ),
    );
    await until(tester, find.byKey(const ValueKey('session-header')));
    await wait(tester, 1500);
    final sub = headerSubtitle();
    await shot(name);
    await home(tester);
    return sub;
  }

  testWidgets('KS1A $_part ($theme, $accent) : types de jour, durée, '
      'échéance ; sessions perso et de test', (tester) async {
    final raw = await SharedPreferences.getInstance();
    await raw.clear();
    final seed = AppStore();
    await seed.init();
    seed.settings.theme = dark ? 'dark' : 'light';
    seed.settings.accent = accent;
    seed.saveSettings();
    // Sauvegarde du propriétaire au format de dev7.0.0 : programme
    // commencé le 13/07/2026, journal saisi jusqu'à la veille (S14 au
    // plus).
    final real = DateTime.now();
    final today = DateTime(real.year, real.month, real.day);
    final b = filledBackup(seed);
    final logs = (b['logs'] as Map).cast<String, dynamic>();
    logs.removeWhere((k, _) {
      final m = RegExp(r'^S(\d+)-J(\d+)$').firstMatch(k);
      if (m == null) return true;
      final w = int.parse(m[1]!), j = int.parse(m[2]!);
      final day = DateTime(2026, 7, 13 + (w - 1) * 7 + j - 1);
      return w > 14 || !day.isBefore(today);
    });
    b['programStart'] = {
      'status': 'set',
      'date': '2026-07-13',
      'origin': 'migration',
    };
    releve['import'] = await seed.importAll(jsonEncode(b));
    seed.seedSampleAthleteProfile();
    await seed.flush();
    final logsBefore = jsonEncode(
      (jsonDecode(seed.exportAll()) as Map<String, dynamic>)['logs'],
    );
    seed.dispose();

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    await tester.pumpWidget(RepaintBoundary(key: _root, child: kalisApp()));
    await opened(tester);
    await until(tester, find.byKey(const ValueKey('header-logo')));

    // 1. Session personnelle : migration, rien d'autre ne change.
    releve['journal_identique'] =
        jsonEncode(
          (jsonDecode(store.exportAll()) as Map<String, dynamic>)['logs'],
        ) ==
        logsBefore;
    releve['origine_presente'] = store.programOrigin != null;
    releve['koach_actif'] = store.koachEngine.active;
    releve['programme_cree'] = store.planProgram != null;
    final now = store.storeClock();
    final w = store.program.weekFor(now);
    final j = store.program.offsetOf(now)! % 7 + 1;
    releve['jour'] = 'S$w-J$j';
    final week = store.program.week(w);
    releve['types_semaine'] = {
      for (final d in week.days) 'J${d.j}': store.dayTypeLabelOf(d),
    };
    final todayDay = week.day(j)!;
    releve['type_du_jour'] = store.dayTypeLabelOf(todayDay);
    releve['carte_type'] = textOf('today-day-type-$j');
    await shot('1_accueil');
    // Feuille de la semaine : chaque journée montre son type.
    await tester.tap(find.byKey(const ValueKey('selected-week')));
    await wait(tester, 1500);
    String? rowType;
    for (final d in week.days) {
      final l = store.dayTypeLabelOf(d);
      if (l == null) continue;
      final row = find.byKey(ValueKey('week-sheet-day-${d.j}'));
      final hit = find.descendant(of: row, matching: find.textContaining(l));
      if (hit.evaluate().isNotEmpty) {
        rowType = 'J${d.j} $l';
        break;
      }
    }
    releve['feuille_semaine_type'] = rowType;
    await shot('1c_feuille_semaine');
    await home(tester);
    await scrollTo(tester, find.byKey(const ValueKey('home-my-program')));
    await shot('1b_accueil_jours');
    // Tête de séance d'une journée d'entraînement de la semaine.
    final train = todayDay.exercises.isNotEmpty
        ? todayDay
        : week.days.firstWhere((d) => d.exercises.isNotEmpty);
    releve['entete_perso'] = await openHeader(
      tester,
      w,
      train.j,
      '2_seance_perso',
    );
    await store.flush();
    final persoBefore = jsonEncode(KalisPrefs(raw, dev: false).snapshot());

    // 2. Session de test : programme créé pour un profil street 50 / 50.
    // (Accueil remonté en haut : le logo est dans l'en-tête de la liste.)
    final logo = find.byKey(const ValueKey('header-logo')).hitTestable();
    for (var i = 0; i < 30 && logo.evaluate().isEmpty; i++) {
      final lists = find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .hitTestable();
      if (lists.evaluate().isEmpty) break;
      await tester.drag(lists.first, const Offset(0, 300));
      await wait(tester, 300);
    }
    releve['logo_visible'] = logo.evaluate().isNotEmpty;
    for (var i = 0; i < 5; i++) {
      await tester.tap(logo.first);
      await tester.pump(Duration(milliseconds: i < 4 ? 300 : 16));
    }
    await opened(tester);
    releve['dev_actif'] = DevSession.active.value;
    releve['dev_espace'] = SessionSpace.isDev;
    store.settings
      ..theme = dark ? 'dark' : 'light'
      ..accent = accent;
    store.saveSettings();
    // Lundi prochain (ou aujourd'hui) : premier jour du programme.
    final monday = (DateTime.monday - real.weekday + 7) % 7;
    KalisClock.setOffsetDays(monday);
    final p0 = sampleStreet5050Profile(on: civilOf(KalisClock.now()));
    releve['profil'] =
        store.saveAthleteProfile(ProfileDraft.of(p0)..consent = 'refused') !=
        null;
    // Création à l'écran : structure de la semaine, types des jours.
    unawaited(
      appNavigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const PlanCreationScreen()),
      ),
    );
    releve['creation_structure'] = await until(
      tester,
      find.byKey(const ValueKey('plan-structure')),
      max: 300,
    );
    await wait(tester, 1200);
    releve['creation_type_j0'] = textOf('plan-day-type-0');
    await shot('3_creation');
    await home(tester);
    final c = PlanStore(store).newPlanCreation(journal: false);
    if (c != null) {
      c.start();
      c.createPass2();
      PlanStore(store).applyPlanCreation(c);
    }
    final plan = store.planProgram;
    releve['programme_dev'] = plan != null;
    final block = plan?.blocks.last.block;
    releve['gabarit'] = block?.pass1.split?.templateId;
    releve['types_dev'] = [
      for (final d in block?.pass1.days ?? const []) dayTypeLabel(d.type),
    ];
    await home(tester);
    // (Session de test neuve : le parcours de création du profil couvre
    // l'onglet Programme ; l'accueil du programme est ouvert à part.)
    unawaited(
      appNavigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      ),
    );
    await wait(tester, 2000);
    final now2 = store.storeClock();
    final w2 = store.program.weekFor(now2);
    final j2 = store.program.offsetOf(now2)! % 7 + 1;
    releve['jour_dev'] = 'S$w2-J$j2';
    releve['carte_type_dev'] = textOf('today-day-type-$j2');
    releve['carte_duree_dev'] = textOf('today-duration-$j2');
    releve['durees_dev'] = [
      for (final d in store.program.week(w2).days)
        if (d.exercises.isNotEmpty) store.dayDurationText(d),
    ];
    await shot('4_accueil_dev');
    releve['entete_dev'] = await openHeader(tester, w2, j2, '5_seance_dev');

    // Échéance avancée de six semaines, en semaine 2 du programme.
    KalisClock.setOffsetDays(monday + 10);
    final ev = p0.events!.single;
    store.saveAthleteProfile(
      ProfileDraft.of(
        p0.copyWith(events: [ev.copyWith(date: ev.date.addDays(-42))]),
      )..consent = 'refused',
    );
    releve['echeance_changee'] = PlanStore(store).planDeadlineChanged;
    releve['bloc_suivant_semaine'] = PlanStore(store).planNextFirstWeek;
    unawaited(
      appNavigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const ProgramScreen()),
      ),
    );
    final next = find.byKey(const ValueKey('program-next-block'));
    await until(tester, find.byKey(const ValueKey('program-list')));
    await wait(tester, 800);
    await scrollTo(tester, next);
    releve['mon_programme_bloc_suivant'] = next.evaluate().isNotEmpty;
    releve['mon_programme_sous_titre'] = find
        .descendant(of: next, matching: find.textContaining('semaine 3'))
        .evaluate()
        .isNotEmpty;
    await shot('6_mon_programme_echeance');
    await home(tester);
    final prev = store.planProgram?.blocks.last.block;
    final c2 = PlanStore(store).newNextBlockCreation(journal: false);
    if (c2 != null && prev != null) {
      releve['bloc_suivant_debut'] = c2.startDate.iso;
      releve['bloc_suivant_attendu'] = prev.pass1.startDate.addDays(14).iso;
      c2.createPass2();
      PlanStore(store).applyNextBlockCreation(c2);
      final p2 = store.planProgram!;
      releve['bloc_en_cours_semaines'] = p2.blocks[p2.blocks.length - 2].weeks;
      releve['bloc_suivant_premiere_semaine'] = p2.blockFirstWeek(
        p2.blocks.length - 1,
      );
    }
    KalisClock.setOffsetDays(0);

    // Suppression de la session de test : session personnelle intacte.
    final badge = find.byKey(const ValueKey('dev-badge'));
    if (badge.evaluate().isNotEmpty) {
      await tester.longPress(badge.first);
      await wait(tester, 1200);
      final del = find.byKey(const ValueKey('dev-delete'));
      await tester.ensureVisible(del.first);
      await wait(tester, 400);
      await tester.tap(del.hitTestable().first);
      await wait(tester, 800);
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

    expect(releve['import'], isTrue);
    expect(releve['journal_identique'], isTrue);
    expect(releve['origine_presente'], isTrue);
    expect(releve['koach_actif'], isFalse);
    expect(releve['programme_cree'], isFalse);
    if (todayDay.exercises.isNotEmpty) {
      expect(releve['type_du_jour'], isNotNull);
      expect(releve['carte_type'], releve['type_du_jour']);
    }
    expect(releve['feuille_semaine_type'], isNotNull);
    expect(releve['entete_perso'], contains(' · S'));
    expect(releve['dev_actif'], isTrue);
    expect(releve['profil'], isTrue);
    expect(releve['creation_structure'], isTrue);
    expect(releve['creation_type_j0'], contains(' — '));
    expect(releve['programme_dev'], isTrue);
    expect(releve['gabarit'], isNotNull);
    expect(releve['types_dev'] as List, hasLength(6));
    expect((releve['types_dev'] as List).every((t) => t != null), isTrue);
    expect(releve['carte_type_dev'], isNotNull);
    expect(releve['carte_duree_dev'], contains('min disponibles'));
    expect(
      (releve['durees_dev'] as List).any(
        (t) => '$t'.endsWith('sur 120 disponibles'),
      ),
      isTrue,
    );
    expect(releve['entete_dev'], contains(' · S'));
    expect(releve['echeance_changee'], isTrue);
    expect(releve['bloc_suivant_semaine'], 3);
    expect(releve['mon_programme_bloc_suivant'], isTrue);
    expect(releve['bloc_suivant_debut'], releve['bloc_suivant_attendu']);
    expect(releve['bloc_en_cours_semaines'], 2);
    expect(releve['bloc_suivant_premiere_semaine'], 3);
    expect(releve['retour_perso'], isTrue);
    expect(releve['perso_intacte'], isTrue);
  }, timeout: _limit);
}
