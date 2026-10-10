// UI0 (refonte UI) — palettes du propriétaire, dérivation des rôles,
// contraste, préférence `accent` (cahier §5.1, U5, U6 ; DECISIONS_UI.md U0.6).
// Le tableau de référence `test/fixtures/ui0_palettes_roles.json` est la
// copie exacte de `pipeline/ui/inputs/palettes_roles.json` (script
// `palettes_derivation.py`, HCT de `materialyoucolor`) : la dérivation Dart
// (`material_color_utilities`) doit le retrouver à l'identique.
// Contrastes : formule de luminance relative WCAG 2.x (calcul).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/kit/kit.dart';
import 'package:streetlift_tracker/store.dart';

Color _c(String hex) =>
    Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));

void main() {
  final reference =
      jsonDecode(
            File('test/fixtures/ui0_palettes_roles.json').readAsStringSync(),
          )
          as Map<String, dynamic>;

  group('palettes du propriétaire', () {
    test('8 palettes, ordre et valeurs du fichier du propriétaire', () {
      expect(kPaletteSources.map((p) => p.id).toList(), [
        'bordeaux',
        'obsidian',
        'arctic',
        'neon',
        'titanium',
        'violet',
        'forest',
        'solar',
      ]);
      expect(
        kPaletteSources.map((p) => p.id).toList(),
        reference.keys.toList(),
      );
      for (final p in kPaletteSources) {
        final s = reference[p.id]['source'] as Map<String, dynamic>;
        expect(p.nom, reference[p.id]['nom']);
        expect(Color(p.dominante), _c(s['dominante'] as String), reason: p.id);
        expect(
          Color(p.secondaire),
          _c(s['secondaire'] as String),
          reason: p.id,
        );
        expect(Color(p.accent), _c(s['accent'] as String), reason: p.id);
        expect(
          Color(p.fondSombre),
          _c(s['fondSombre'] as String),
          reason: p.id,
        );
        expect(Color(p.fondClair), _c(s['fondClair'] as String), reason: p.id);
      }
      expect(kDefaultPaletteId, 'bordeaux');
    });

    test('dérivation : palettes_roles.json retrouvé à l’identique', () {
      var compared = 0;
      for (final p in kPaletteSources) {
        for (final (mode, dark) in const [('sombre', true), ('clair', false)]) {
          final expected = reference[p.id][mode] as Map<String, dynamic>;
          final roles = KRoles.of(p.id, dark: dark).named;
          for (final e in roles.entries) {
            expect(
              kHex(e.value),
              expected[e.key],
              reason: '${p.id} $mode ${e.key}',
            );
            compared++;
          }
        }
      }
      expect(compared, 8 * 2 * 12);
    });

    test('dominante exacte pour les aplats, en clair comme en sombre (U5)', () {
      for (final p in kPaletteSources) {
        for (final dark in [true, false]) {
          final r = KRoles.of(p.id, dark: dark);
          final rc = KRoles.of(p.id, dark: dark, contrast: true);
          expect(r.pleine, Color(p.dominante), reason: p.id);
          expect(rc.pleine, Color(p.dominante), reason: '${p.id} renforcé');
          expect(kContrast(r.surPleine, r.pleine), greaterThanOrEqualTo(4.5));
        }
      }
      // Texte noir sur Obsidian, Solar et Neon (U5).
      for (final id in ['obsidian', 'solar', 'neon']) {
        expect(KRoles.of(id, dark: true).surPleine, const Color(0xFF121212));
      }
      expect(KRoles.of('bordeaux', dark: true).surPleine, Colors.white);
      // La dominante illisible sur le fond sombre n'est jamais l'encre.
      final b = KRoles.of('bordeaux', dark: true);
      expect(kContrast(b.pleine, b.surface), lessThan(2));
      expect(b.encre, isNot(b.pleine));
      expect(kContrast(b.encre, b.surface), greaterThanOrEqualTo(4.5));
    });

    test(
      '32 combinaisons (8 palettes × 2 thèmes × 2 contrastes) : seuils de §5.1',
      () {
        for (final p in kPaletteSources) {
          for (final dark in [true, false]) {
            for (final strong in [false, true]) {
              final r = KRoles.of(p.id, dark: dark, contrast: strong);
              final need = strong ? 7.0 : 4.5, weak = strong ? 4.5 : 3.0;
              final id =
                  '${p.id} ${dark ? 'sombre' : 'clair'}${strong ? ' renforcé' : ''}';
              for (final bg in [r.fond, r.surface]) {
                expect(
                  kContrast(r.texte, bg),
                  greaterThanOrEqualTo(need),
                  reason: '$id texte',
                );
                expect(
                  kContrast(r.texte2, r.surface),
                  greaterThanOrEqualTo(need),
                  reason: '$id texte2',
                );
                expect(
                  kContrast(r.encre, r.surface),
                  greaterThanOrEqualTo(need),
                  reason: '$id encre',
                );
                expect(
                  kContrast(r.accent, r.surface),
                  greaterThanOrEqualTo(need),
                  reason: '$id accent',
                );
                expect(
                  kContrast(r.second, r.surface),
                  greaterThanOrEqualTo(weak),
                  reason: '$id second',
                );
              }
              if (!dark) {
                expect(
                  kContrast(r.encre, r.fond),
                  greaterThanOrEqualTo(need),
                  reason: '$id encre/fond',
                );
                expect(
                  kContrast(r.accent, r.fond),
                  greaterThanOrEqualTo(need),
                  reason: '$id accent/fond',
                );
              }
              for (final bg in [r.fond, r.surface, r.haute]) {
                for (final s in [r.validation, r.danger, r.avertissement]) {
                  expect(
                    kContrast(s, bg),
                    greaterThanOrEqualTo(need),
                    reason: '$id état $s sur $bg',
                  );
                }
                expect(
                  kContrast(r.texte, bg),
                  greaterThanOrEqualTo(need),
                  reason: '$id texte/$bg',
                );
                expect(
                  kContrast(r.texte2, bg),
                  greaterThanOrEqualTo(4.5),
                  reason: '$id texte2/$bg',
                );
              }
              for (final (fg, bg) in [
                (r.surPleine, r.pleine),
                (r.surEncre, r.encre),
                (r.surAccent, r.accent),
                (r.surValidation, r.validation),
                (r.surDanger, r.danger),
              ]) {
                expect(
                  kContrast(fg, bg),
                  greaterThanOrEqualTo(4.5),
                  reason: '$id $fg sur $bg',
                );
              }
              // Repères et barres visibles sur leur piste.
              expect(
                kContrast(r.encre, r.filet),
                greaterThan(1.5),
                reason: '$id encre/filet',
              );
              // Rampe d'intensité : du bas (pleine) au haut, visiblement.
              expect(
                kContrast(r.rampe, r.pleine),
                greaterThan(1.2),
                reason: '$id rampe',
              );
            }
          }
        }
      },
    );

    test('contraste renforcé : 7:1 et 4,5:1, sans toucher aux aplats', () {
      for (final p in kPaletteSources) {
        for (final dark in [true, false]) {
          final n = KRoles.of(p.id, dark: dark);
          final c = KRoles.of(p.id, dark: dark, contrast: true);
          expect(kContrast(c.encre, c.surface), greaterThanOrEqualTo(7));
          expect(kContrast(c.texte2, c.surface), greaterThanOrEqualTo(7));
          expect(kContrast(c.second, c.surface), greaterThanOrEqualTo(4.5));
          expect(
            kContrast(c.encre, c.surface),
            greaterThanOrEqualTo(kContrast(n.encre, n.surface)),
          );
          expect(c.fond, n.fond);
          expect(c.surface, n.surface);
          expect(c.pleine, n.pleine);
          expect(c.surPleine, n.surPleine);
        }
      }
    });

    test(
      'rampe : encre quand elle se distingue de la dominante, sinon tonalité',
      () {
        // Bordeaux sombre : la rampe va de la dominante à l'encre (§5.1).
        final b = KRoles.of('bordeaux', dark: true);
        expect(b.rampe, b.encre);
        // Neon sombre : dominante déjà très claire, rampe vers sa secondaire.
        final n = KRoles.of('neon', dark: true);
        expect(n.rampe, n.second);
        for (final p in kPaletteSources) {
          for (final dark in [true, false]) {
            final r = KRoles.of(p.id, dark: dark);
            if (kContrast(r.encre, r.pleine) >= 2.5) expect(r.rampe, r.encre);
          }
        }
      },
    );
  });

  group('préférence et adaptateur', () {
    test('anciens identifiants relus, inconnus vers Bordeaux', () {
      const legacy = {
        'rouge': 'bordeaux',
        'jaune': 'neon',
        'vert': 'forest',
        'violet': 'violet',
        'orange': 'solar',
        'turquoise': 'arctic',
      };
      for (final e in legacy.entries) {
        expect(normalizePaletteId(e.key), e.value);
        expect(normalizeAccent(e.key), e.value);
        expect(KAccentSpec.byId(e.key).id, e.value);
        expect(AppSettings.fromJson({'accent': e.key}).accent, e.value);
      }
      for (final v in <Object?>[
        null,
        '',
        'bleu',
        'BORDEAUX',
        7,
        true,
        const [],
      ]) {
        expect(normalizePaletteId(v), 'bordeaux');
        expect(normalizeAccent(v), 'bordeaux');
      }
      expect(kAccentIds, KAccentSpec.all.map((a) => a.id).toList());
      expect(kAccentIds, kPaletteSources.map((p) => p.id).toList());
      expect(AppSettings().accent, 'bordeaux');
    });

    test('contraste renforcé : absent de l’export tant qu’il est éteint', () {
      final off = AppSettings();
      expect(off.contrast, isFalse);
      expect(off.toJson().containsKey('contrast'), isFalse);
      final on = AppSettings()..contrast = true;
      expect(on.toJson()['contrast'], true);
      expect(AppSettings.fromJson(on.toJson()).contrast, isTrue);
      expect(AppSettings.fromJson({'contrast': 'oui'}).contrast, isFalse);
    });

    test('adaptateur KAccentSpec / KPalette : rôles lus sur les jetons', () {
      for (final a in KAccentSpec.all) {
        for (final dark in [true, false]) {
          final r = KRoles.of(a.id, dark: dark);
          final p = KPalette(dark, a);
          expect(p.bordeaux, r.pleine);
          expect(p.accent, r.encre);
          expect(p.bg, r.fond);
          expect(p.text, r.texte);
          expect(p.dim, r.texte2);
          expect(p.success, r.validation);
          expect(p.danger, r.danger);
          expect(p.logo, dark ? r.texte : r.encre);
          expect(a.principal, Color(paletteSource(a.id).dominante));
          expect(dark ? a.bright : a.vividLight, r.rampe);
        }
      }
      expect(KAccentSpec.rouge, same(KAccentSpec.bordeaux));
      expect(KAccentSpec.jaune, same(KAccentSpec.neon));
    });

    test('thème : jetons en extension, polices Barlow', () {
      for (final p in kPaletteSources) {
        for (final dark in [true, false]) {
          final t = kitTheme(dark: dark, paletteId: p.id);
          final k = t.extension<KTokens>()!;
          expect(k.paletteId, p.id);
          expect(k.dark, dark);
          expect(t.scaffoldBackgroundColor, k.fond);
          expect(t.colorScheme.primary, k.encre);
          expect(t.textTheme.bodyMedium!.fontFamily, KFont.text);
          expect(t.textTheme.headlineLarge!.fontFamily, KFont.title);
          expect(
            t.filledButtonTheme.style!.backgroundColor!.resolve({}),
            k.pleine,
          );
          expect(
            kContrast(
              t.colorScheme.inversePrimary,
              t.colorScheme.inverseSurface,
            ),
            greaterThanOrEqualTo(4.5),
          );
        }
      }
    });
  });
}
