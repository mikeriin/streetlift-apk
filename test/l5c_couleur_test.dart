// L5-C — Couleur dominante : palettes, rôles, thème et préférence.
// Stockage simulé (SharedPreferences en mémoire) ; les erreurs d'écriture
// sont injectées par `debugWriteHook`. « Relance » = nouvelle instance qui
// relit ce stockage simulé : ni un arrêt brutal ni un appareil réel.
// Contrastes : formule de luminance relative WCAG 2.x (calcul, pas mesure
// sur écran). Aucune donnée réelle.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/store.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05);
}

const _modes = [true, false];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('palettes', () {
    test('six familles, rouge par défaut, identifiants stables', () {
      expect(KAccentSpec.all.map((a) => a.id).toList(), kAccentIds);
      expect(KAccentSpec.all.map((a) => a.label).toList(), [
        'Rouge Kalis',
        'Jaune',
        'Vert',
        'Violet',
        'Orange',
        'Turquoise',
      ]);
      expect(KAccentSpec.defaultId, 'rouge');
      for (final value in <Object?>[null, '', 'bleu', 'ROUGE', 42, true, []]) {
        expect(KAccentSpec.byId(value), same(KAccentSpec.rouge));
        expect(normalizeAccent(value), 'rouge');
      }
      for (final a in KAccentSpec.all) {
        expect(KAccentSpec.byId(a.id), same(a));
        expect(normalizeAccent(a.id), a.id);
      }
    });

    test('le Rouge Kalis a la couleur du logo (5.10.0)', () {
      for (final dark in _modes) {
        final p = KPalette(dark, KAccentSpec.rouge);
        expect(p.bordeaux, const Color(0xFF5E1615));
        expect(p.action, const Color(0xFF9E2A28));
        expect(
          p.accent,
          dark ? const Color(0xFFD96968) : const Color(0xFF5E1615),
        );
        expect(p.onBrand, Colors.white);
        expect(p.onBrandSoft, KPalette.light);
        expect(p.onAction, Colors.white);
        expect(p.onActionSoft, KPalette.light);
        expect(p.gauge, KPalette.redGradient);
        expect(p.decor, KPalette.lightRed);
        expect(p.accentTint, KPalette(dark).accentTint);
      }
    });

    test('12 combinaisons : textes, fonds pleins et éléments lisibles', () {
      for (final a in KAccentSpec.all) {
        for (final dark in _modes) {
          final p = KPalette(dark, a);
          final id = '${a.id} ${dark ? 'sombre' : 'clair'}';
          for (final bg in [p.bg, p.surface, p.card, p.formFill, p.fieldFill]) {
            expect(
              contrast(p.accent, bg),
              greaterThanOrEqualTo(4.5),
              reason: '$id : accent sur $bg',
            );
          }
          for (final fg in [p.onBrand, p.onBrandSoft]) {
            expect(
              contrast(fg, p.bordeaux),
              greaterThanOrEqualTo(4.5),
              reason: '$id : texte sur principale',
            );
          }
          for (final fg in [p.onAction, p.onActionSoft]) {
            expect(
              contrast(fg, p.action),
              greaterThanOrEqualTo(4.5),
              reason: '$id : texte sur vive',
            );
          }
          // Puce sélectionnée : libellé sur la teinte d'accent.
          final tint = Color.alphaBlend(p.accentTint, p.surface);
          expect(
            contrast(dark ? p.text : p.accent, tint),
            greaterThanOrEqualTo(4.5),
            reason: '$id : puce sélectionnée',
          );
          // colorScheme.onPrimary sur colorScheme.primary.
          expect(
            contrast(p.onAccent, p.accent),
            greaterThanOrEqualTo(4.5),
            reason: '$id : onPrimary',
          );
          // Jauges et sélection : visibles sur leur piste et sur le fond.
          expect(contrast(p.action, p.progressTrack), greaterThan(1.5));
          expect(contrast(p.gauge.last, p.progressTrack), greaterThan(1.5));
          // Composant d'interface (critère 1.4.11, 3:1) ; le rouge historique
          // en sombre reste l'exception documentée (2,51:1, identité gardée).
          expect(
            contrast(p.action, p.bg),
            a.id == 'rouge' && dark
                ? greaterThan(2.4)
                : greaterThanOrEqualTo(3.0),
            reason: '$id : vive sur le fond',
          );
        }
      }
    });

    test('rôles fixes et neutres identiques dans toutes les palettes', () {
      for (final dark in _modes) {
        final ref = KPalette(dark);
        for (final a in KAccentSpec.all) {
          final p = KPalette(dark, a);
          expect(p.alert, KPalette.actionRed);
          expect(p.redAccent, ref.accent);
          for (final pair in [
            (p.success, ref.success),
            (p.danger, ref.danger),
            (p.logo, ref.logo),
            (p.bg, ref.bg),
            (p.surface, ref.surface),
            (p.card, ref.card),
            (p.text, ref.text),
            (p.dim, ref.dim),
            (p.line, ref.line),
            (p.progressTrack, ref.progressTrack),
          ]) {
            expect(pair.$1, pair.$2, reason: '${a.id} $dark');
          }
        }
      }
    });

    test('thème Material : dominante et luminosité indépendantes', () {
      for (final a in KAccentSpec.all) {
        for (final dark in _modes) {
          final t = buildTheme(dark, a);
          final p = KPalette(dark, a);
          expect(t.brightness, dark ? Brightness.dark : Brightness.light);
          expect(t.colorScheme.primary, p.accent);
          expect(t.colorScheme.error, p.danger);
          expect(
            t.filledButtonTheme.style!.backgroundColor!.resolve({}),
            p.bordeaux,
          );
          expect(
            t.filledButtonTheme.style!.foregroundColor!.resolve({}),
            p.onBrandSoft,
          );
          expect(
            t.segmentedButtonTheme.style!.backgroundColor!.resolve({
              WidgetState.selected,
            }),
            p.action,
          );
          expect(
            t.segmentedButtonTheme.style!.foregroundColor!.resolve({
              WidgetState.selected,
            }),
            p.onAction,
          );
          expect(
            t.chipTheme.secondaryLabelStyle!.color,
            dark ? p.text : p.accent,
          );
          expect(
            t.checkboxTheme.fillColor!.resolve({WidgetState.selected}),
            KPalette.green,
          );
          expect(
            contrast(
              t.colorScheme.inversePrimary,
              t.colorScheme.inverseSurface,
            ),
            greaterThanOrEqualTo(4.5),
          );
          expect(SL.accentSpec, same(a));
          expect(SL.dark, dark);
        }
      }
      buildTheme(true);
      expect(SL.accentSpec, same(KAccentSpec.rouge));
    });
  });

  group('préférence', () {
    test('AppSettings : absent, inconnu ou mauvais type → rouge', () {
      expect(AppSettings().accent, 'rouge');
      expect(AppSettings.fromJson({}).accent, 'rouge');
      expect(AppSettings.fromJson({'accent': 'bleu'}).accent, 'rouge');
      expect(AppSettings.fromJson({'accent': 7}).accent, 'rouge');
      for (final id in kAccentIds) {
        final settings = AppSettings()..accent = id;
        final back = AppSettings.fromJson(
          jsonDecode(jsonEncode(settings.toJson())) as Map<String, dynamic>,
        );
        expect(back.accent, id);
      }
    });

    late AppStore app;
    final others = <AppStore>[];
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      app = AppStore();
      await app.init();
      app.settings.sound = app.settings.vibration = false;
    });
    tearDown(() async {
      app.debugWriteHook = null;
      await app.flush();
      app.dispose();
      for (final other in others) {
        other.dispose();
      }
      others.clear();
    });
    Future<AppStore> relaunch() async {
      final next = AppStore();
      await next.init();
      others.add(next);
      return next;
    }

    test('installation neuve : rouge', () async {
      expect(app.settings.accent, 'rouge');
      expect(app.accentMode.value, 'rouge');
    });

    test('choix retrouvé à la réouverture, thème indépendant', () async {
      app.settings.theme = 'light';
      app.saveSettings();
      app.settings.accent = 'violet';
      app.saveSettings();
      expect(app.accentMode.value, 'violet');
      expect(app.themeMode.value, 'light');
      await app.flush();
      var next = await relaunch();
      expect(next.settings.accent, 'violet');
      expect(next.accentMode.value, 'violet');
      expect(next.settings.theme, 'light');
      // Changer le mode ne touche pas la couleur, et inversement.
      next.settings.theme = 'system';
      next.saveSettings();
      await next.flush();
      expect(next.accentMode.value, 'violet');
      next = await relaunch();
      expect(next.settings.theme, 'system');
      expect(next.settings.accent, 'violet');
    });

    test('choix rapides : le dernier est retrouvé', () async {
      for (final id in [...kAccentIds.reversed, 'orange', 'vert', 'jaune']) {
        app.settings.accent = id;
        app.saveSettings();
      }
      expect(app.accentMode.value, 'jaune');
      await app.flush();
      expect((await relaunch()).settings.accent, 'jaune');
    });

    test(
      'échec d’écriture : choix affiché, erreur visible, disque intact',
      () async {
        app.settings.accent = 'vert';
        app.saveSettings();
        await app.flush();
        app.debugWriteHook = (_) async => false;
        app.settings.accent = 'turquoise';
        app.saveSettings();
        await app.flush();
        expect(app.accentMode.value, 'turquoise');
        expect(app.persistenceError.value, isNotNull);
        expect(app.hasUnsavedChanges, isTrue);
        expect((await relaunch()).settings.accent, 'vert');
        app.debugWriteHook = null;
        app.saveSettings();
        expect(await app.retrySave(), isTrue);
        expect(app.persistenceError.value, isNull);
        expect((await relaunch()).settings.accent, 'turquoise');
      },
    );

    test('export : la préférence est incluse', () async {
      app.settings.accent = 'orange';
      app.saveSettings();
      final data = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      expect((data['settings'] as Map)['accent'], 'orange');
    });

    test(
      'import d’une sauvegarde sans préférence : rouge, reste conservé',
      () async {
        app.settings
          ..theme = 'light'
          ..defaultRest = 150
          ..accent = 'violet';
        app.saveSettings();
        final data = jsonDecode(app.exportAll()) as Map<String, dynamic>;
        (data['settings'] as Map).remove('accent');
        final other = await relaunch();
        other.settings.accent = 'jaune';
        other.saveSettings();
        expect(
          await other.importBackup(jsonEncode(data)),
          ImportStatus.success,
        );
        expect(other.settings.accent, 'rouge');
        expect(other.accentMode.value, 'rouge');
        expect(other.settings.theme, 'light');
        expect(other.settings.defaultRest, 150);
      },
    );

    test(
      'import d’une valeur inconnue : rouge, sans refuser la sauvegarde',
      () async {
        final data = jsonDecode(app.exportAll()) as Map<String, dynamic>;
        (data['settings'] as Map)['accent'] = 'magenta';
        (data['settings'] as Map)['defaultRest'] = 120;
        expect(await app.importBackup(jsonEncode(data)), ImportStatus.success);
        expect(app.settings.accent, 'rouge');
        expect(app.settings.defaultRest, 120);
        // Aller-retour d'une valeur connue.
        (data['settings'] as Map)['accent'] = 'turquoise';
        expect(await app.importBackup(jsonEncode(data)), ImportStatus.success);
        expect(app.settings.accent, 'turquoise');
        expect(app.accentMode.value, 'turquoise');
        await app.flush();
        expect((await relaunch()).settings.accent, 'turquoise');
      },
    );

    test('suppression locale : retour au rouge', () async {
      app.settings.accent = 'vert';
      app.saveSettings();
      await app.flush();
      final result = await app.eraseAllData();
      expect(result.status, EraseStatus.success);
      expect(app.settings.accent, 'rouge');
      expect(app.accentMode.value, 'rouge');
      expect((await relaunch()).settings.accent, 'rouge');
    });

    test('changer de couleur ne touche ni XP, ni niveau, ni dates', () async {
      for (final week in app.program.weeks.take(2)) {
        for (final day in week.days) {
          if (day.exercises.isNotEmpty) {
            app.markSessionDone(week.n, day.j, true);
          }
        }
      }
      await app.flush();
      final xp = app.questLevel.totalXp, level = app.questLevel.level;
      final start = app.program.start;
      final logs = jsonEncode((jsonDecode(app.exportAll()) as Map)['logs']);
      for (final id in kAccentIds) {
        app.settings.accent = id;
        app.saveSettings();
      }
      await app.flush();
      final next = await relaunch();
      for (final a in [app, next]) {
        expect(a.questLevel.level, level);
        expect(a.questLevel.totalXp, xp);
        expect(a.program.start, start);
        expect(jsonEncode((jsonDecode(a.exportAll()) as Map)['logs']), logs);
      }
    });
  });
}
