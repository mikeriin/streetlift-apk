// L5-C — Couleur dominante : palettes, rôles, thème et préférence.
// UI0 (refonte UI) : les 8 palettes du propriétaire remplacent les six
// couleurs ; mêmes comportements de la préférence (choix gardé, import,
// échec d'écriture, suppression), anciens identifiants relus (rouge →
// bordeaux…). Valeurs des rôles : test/ui0_palette_test.dart.
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
import 'package:streetlift_tracker/kit/kit.dart' show KRoles;
import 'package:streetlift_tracker/store.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05);
}

const _modes = [true, false];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('palettes', () {
    test('huit palettes, Bordeaux par défaut, identifiants stables', () {
      expect(KAccentSpec.all.map((a) => a.id).toList(), kAccentIds);
      expect(KAccentSpec.all.map((a) => a.label).toList(), [
        'Bordeaux Performance',
        'Obsidian Energy',
        'Arctic Motion',
        'Neon Athlete',
        'Titanium Pro',
        'Violet Momentum',
        'Forest Endurance',
        'Solar Sprint',
      ]);
      expect(KAccentSpec.defaultId, 'bordeaux');
      for (final value in <Object?>[null, '', 'bleu', 'ROUGE', 42, true, []]) {
        expect(KAccentSpec.byId(value), same(KAccentSpec.bordeaux));
        expect(normalizeAccent(value), 'bordeaux');
      }
      for (final a in KAccentSpec.all) {
        expect(KAccentSpec.byId(a.id), same(a));
        expect(normalizeAccent(a.id), a.id);
      }
      // Anciens identifiants (L5-C) relus vers la palette la plus proche.
      for (final (old, now) in const [
        ('rouge', 'bordeaux'),
        ('jaune', 'neon'),
        ('vert', 'forest'),
        ('violet', 'violet'),
        ('orange', 'solar'),
        ('turquoise', 'arctic'),
      ]) {
        expect(normalizeAccent(old), now);
        expect(KAccentSpec.byId(old).id, now);
      }
    });

    test('Bordeaux : dominante exacte du propriétaire (#551515)', () {
      for (final dark in _modes) {
        final p = KPalette(dark, KAccentSpec.bordeaux);
        expect(p.bordeaux, const Color(0xFF551515));
        expect(
          p.accent,
          dark ? const Color(0xFFCA6F6A) : const Color(0xFF551515),
        );
        expect(p.onBrand, Colors.white);
        expect(p.onBrandSoft, Colors.white);
        expect(p.accentTint, KPalette(dark).accentTint);
      }
    });

    test('16 combinaisons : textes, fonds pleins et éléments lisibles', () {
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
          // Composant d'interface (critère 1.4.11, 3:1).
          expect(
            contrast(p.action, p.bg),
            greaterThanOrEqualTo(3.0),
            reason: '$id : vive sur le fond',
          );
        }
      }
    });

    test('rôles fixes identiques dans toutes les palettes', () {
      for (final dark in _modes) {
        for (final a in KAccentSpec.all) {
          final p = KPalette(dark, a);
          expect(p.alert, KPalette.actionRed);
          expect(p.redAccent, dark ? KPalette.lightRed : KPalette.burgundy);
          // UI0 : fonds, textes et états suivent la palette (fonds du
          // propriétaire) ; ils viennent tous de ses rôles.
          final r = KRoles.of(a.id, dark: dark);
          expect(p.bg, r.fond);
          expect(p.surface, r.surface);
          expect(p.text, r.texte);
          expect(p.success, r.validation);
          expect(p.danger, r.danger);
        }
      }
    });

    test('thème Material : palette et luminosité indépendantes', () {
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
          // Choix d'un segment : aplat de la dominante (même forme).
          expect(
            t.segmentedButtonTheme.style!.backgroundColor!.resolve({
              WidgetState.selected,
            }),
            p.bordeaux,
          );
          expect(
            t.segmentedButtonTheme.style!.foregroundColor!.resolve({
              WidgetState.selected,
            }),
            p.onBrand,
          );
          expect(t.chipTheme.secondaryLabelStyle!.color, p.onBrand);
          expect(
            t.checkboxTheme.fillColor!.resolve({WidgetState.selected}),
            p.success,
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
      expect(SL.accentSpec, same(KAccentSpec.bordeaux));
    });
  });

  group('préférence', () {
    test('AppSettings : absent, inconnu ou mauvais type → bordeaux', () {
      expect(AppSettings().accent, 'bordeaux');
      expect(AppSettings.fromJson({}).accent, 'bordeaux');
      expect(AppSettings.fromJson({'accent': 'bleu'}).accent, 'bordeaux');
      expect(AppSettings.fromJson({'accent': 7}).accent, 'bordeaux');
      expect(AppSettings.fromJson({'accent': 'rouge'}).accent, 'bordeaux');
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

    test('installation neuve : bordeaux', () async {
      expect(app.settings.accent, 'bordeaux');
      expect(app.accentMode.value, 'bordeaux');
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
      for (final id in [...kAccentIds.reversed, 'solar', 'forest', 'neon']) {
        app.settings.accent = id;
        app.saveSettings();
      }
      expect(app.accentMode.value, 'neon');
      await app.flush();
      expect((await relaunch()).settings.accent, 'neon');
    });

    test(
      'échec d’écriture : choix affiché, erreur visible, disque intact',
      () async {
        app.settings.accent = 'forest';
        app.saveSettings();
        await app.flush();
        app.debugWriteHook = (_) async => false;
        app.settings.accent = 'arctic';
        app.saveSettings();
        await app.flush();
        expect(app.accentMode.value, 'arctic');
        expect(app.persistenceError.value, isNotNull);
        expect(app.hasUnsavedChanges, isTrue);
        expect((await relaunch()).settings.accent, 'forest');
        app.debugWriteHook = null;
        app.saveSettings();
        expect(await app.retrySave(), isTrue);
        expect(app.persistenceError.value, isNull);
        expect((await relaunch()).settings.accent, 'arctic');
      },
    );

    test('export : la préférence est incluse', () async {
      app.settings.accent = 'solar';
      app.saveSettings();
      final data = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      expect((data['settings'] as Map)['accent'], 'solar');
    });

    test(
      'import d’une sauvegarde sans préférence : bordeaux, reste conservé',
      () async {
        app.settings
          ..theme = 'light'
          ..defaultRest = 150
          ..accent = 'violet';
        app.saveSettings();
        final data = jsonDecode(app.exportAll()) as Map<String, dynamic>;
        (data['settings'] as Map).remove('accent');
        final other = await relaunch();
        other.settings.accent = 'neon';
        other.saveSettings();
        expect(
          await other.importBackup(jsonEncode(data)),
          ImportStatus.success,
        );
        expect(other.settings.accent, 'bordeaux');
        expect(other.accentMode.value, 'bordeaux');
        expect(other.settings.theme, 'light');
        expect(other.settings.defaultRest, 150);
      },
    );

    test(
      'import d’une valeur inconnue : bordeaux, sans refuser la sauvegarde',
      () async {
        final data = jsonDecode(app.exportAll()) as Map<String, dynamic>;
        (data['settings'] as Map)['accent'] = 'magenta';
        (data['settings'] as Map)['defaultRest'] = 120;
        expect(await app.importBackup(jsonEncode(data)), ImportStatus.success);
        expect(app.settings.accent, 'bordeaux');
        expect(app.settings.defaultRest, 120);
        // Aller-retour d'une valeur connue.
        (data['settings'] as Map)['accent'] = 'arctic';
        expect(await app.importBackup(jsonEncode(data)), ImportStatus.success);
        expect(app.settings.accent, 'arctic');
        expect(app.accentMode.value, 'arctic');
        await app.flush();
        expect((await relaunch()).settings.accent, 'arctic');
      },
    );

    test(
      'import d’une ancienne sauvegarde (L5-C) : identifiant relu, jamais refusé',
      () async {
        final data = jsonDecode(app.exportAll()) as Map<String, dynamic>;
        (data['settings'] as Map)['accent'] = 'turquoise';
        expect(await app.importBackup(jsonEncode(data)), ImportStatus.success);
        expect(app.settings.accent, 'arctic');
        expect(app.accentMode.value, 'arctic');
        await app.flush();
        expect((await relaunch()).settings.accent, 'arctic');
      },
    );

    test(
      'contraste renforcé : retrouvé à la réouverture, indépendant',
      () async {
        app.settings.contrast = true;
        app.saveSettings();
        expect(app.contrastMode.value, isTrue);
        expect(app.accentMode.value, 'bordeaux');
        await app.flush();
        final next = await relaunch();
        expect(next.settings.contrast, isTrue);
        expect(next.contrastMode.value, isTrue);
        final data = jsonDecode(next.exportAll()) as Map<String, dynamic>;
        expect((data['settings'] as Map)['contrast'], true);
        next.settings.contrast = false;
        next.saveSettings();
        final off = jsonDecode(next.exportAll()) as Map<String, dynamic>;
        expect((off['settings'] as Map).containsKey('contrast'), isFalse);
      },
    );

    test('suppression locale : retour à Bordeaux', () async {
      app.settings.accent = 'forest';
      app.saveSettings();
      await app.flush();
      final result = await app.eraseAllData();
      expect(result.status, EraseStatus.success);
      expect(app.settings.accent, 'bordeaux');
      expect(app.accentMode.value, 'bordeaux');
      expect((await relaunch()).settings.accent, 'bordeaux');
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
      final xp = app.levelProgress.inLevel, level = app.level;
      final start = app.program.start;
      final logs = jsonEncode((jsonDecode(app.exportAll()) as Map)['logs']);
      for (final id in kAccentIds) {
        app.settings.accent = id;
        app.saveSettings();
      }
      await app.flush();
      final next = await relaunch();
      for (final a in [app, next]) {
        expect(a.level, level);
        expect(a.levelProgress.inLevel, xp);
        expect(a.program.start, start);
        expect(jsonEncode((jsonDecode(a.exportAll()) as Map)['logs']), logs);
      }
    });
  });
}
