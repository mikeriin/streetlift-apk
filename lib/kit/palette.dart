// UI0 (refonte UI) : les 8 palettes du propriétaire et la dérivation de
// leurs rôles de couleur (cahier §5.1, DECISIONS_UI.md U0.6, U0.8).
//
// Couche « globaux » des jetons (Fluent 2) : les valeurs hexadécimales du
// propriétaire, telles qu'il les a données (`inputs/palettes_kalis_track.txt`).
// Aucun écran ne les lit : ils lisent les rôles (`KRoles`, couche « alias »),
// dérivés ici.
//
// Règle de dérivation (identique à `inputs/palettes_derivation.py`, tableau de
// référence `inputs/palettes_roles.json`, retrouvé à l'identique par
// `test/ui0_palette_test.dart`) : la valeur du propriétaire est gardée telle
// quelle quand elle passe le contraste exigé par son rôle ; sinon on garde sa
// teinte et sa chroma (HCT, `material_color_utilities`) et on ne déplace que
// sa tonalité, du plus petit pas de 0,5 qui suffit.
import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:material_color_utilities/material_color_utilities.dart';

/// Palette du propriétaire : dominante, secondaire, accent, fond sombre, fond
/// clair (valeurs exactes).
class KPaletteSource {
  final String id, nom;
  final int dominante, secondaire, accent, fondSombre, fondClair;
  const KPaletteSource(
    this.id,
    this.nom,
    this.dominante,
    this.secondaire,
    this.accent,
    this.fondSombre,
    this.fondClair,
  );
}

/// Les 8 palettes, dans l'ordre du fichier du propriétaire (ordre du
/// sélecteur). Bordeaux Performance est la palette par défaut.
const kPaletteSources = <KPaletteSource>[
  KPaletteSource(
    'bordeaux',
    'Bordeaux Performance',
    0xFF551515,
    0xFF8E3030,
    0xFFD9A66C,
    0xFF181819,
    0xFFF6F2EF,
  ),
  KPaletteSource(
    'obsidian',
    'Obsidian Energy',
    0xFFE5484D,
    0xFFFF8566,
    0xFFFFC857,
    0xFF121316,
    0xFFF2F3F5,
  ),
  KPaletteSource(
    'arctic',
    'Arctic Motion',
    0xFF2563EB,
    0xFF4F9CF9,
    0xFF14B8A6,
    0xFF152238,
    0xFFF5F8FC,
  ),
  KPaletteSource(
    'neon',
    'Neon Athlete',
    0xFFB4F044,
    0xFF67D8C0,
    0xFF8C72FF,
    0xFF101510,
    0xFFF2F9EA,
  ),
  KPaletteSource(
    'titanium',
    'Titanium Pro',
    0xFF4C6474,
    0xFF8A9DA8,
    0xFFD5A24C,
    0xFF171E24,
    0xFFE8EDF0,
  ),
  KPaletteSource(
    'violet',
    'Violet Momentum',
    0xFF7546DB,
    0xFFAC8CFA,
    0xFF29BFB0,
    0xFF181427,
    0xFFF5F1FF,
  ),
  KPaletteSource(
    'forest',
    'Forest Endurance',
    0xFF236B50,
    0xFF7BAC81,
    0xFFD7B374,
    0xFF17251D,
    0xFFF4F5EE,
  ),
  KPaletteSource(
    'solar',
    'Solar Sprint',
    0xFFD95A27,
    0xFFFF9760,
    0xFFE8BC49,
    0xFF211B1A,
    0xFFFFF6ED,
  ),
];

/// Identifiant de la palette par défaut.
const kDefaultPaletteId = 'bordeaux';

/// Anciens identifiants de la préférence `accent` (L5-C, 6 couleurs), relus
/// vers la palette la plus proche (cahier §5.1).
const kLegacyPaletteIds = <String, String>{
  'rouge': 'bordeaux',
  'jaune': 'neon',
  'vert': 'forest',
  'violet': 'violet',
  'orange': 'solar',
  'turquoise': 'arctic',
};

/// Identifiant de palette enregistrable : identifiant actuel gardé, ancien
/// identifiant relu, absent, inconnu ou d'un autre type → Bordeaux.
String normalizePaletteId(Object? id) {
  if (id is! String) return kDefaultPaletteId;
  if (kPaletteSources.any((p) => p.id == id)) return id;
  return kLegacyPaletteIds[id] ?? kDefaultPaletteId;
}

/// Palette d'un identifiant (normalisé).
KPaletteSource paletteSource(Object? id) {
  final n = normalizePaletteId(id);
  return kPaletteSources.firstWhere((p) => p.id == n);
}

// ------------------------------------------------------------ contraste --

/// Luminance relative WCAG 2.x d'une couleur opaque.
double kLuminance(int argb) {
  double ch(int v) {
    final c = v / 255;
    return c <= 0.04045
        ? c / 12.92
        : math.pow((c + 0.055) / 1.055, 2.4) as double;
  }

  return 0.2126 * ch((argb >> 16) & 0xFF) +
      0.7152 * ch((argb >> 8) & 0xFF) +
      0.0722 * ch(argb & 0xFF);
}

/// Rapport de contraste WCAG entre deux couleurs opaques (1 à 21).
double kContrastArgb(int a, int b) {
  final la = kLuminance(a), lb = kLuminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// [kContrastArgb] pour des [Color].
double kContrast(Color a, Color b) => kContrastArgb(a.toARGB32(), b.toARGB32());

const int _white = 0xFFFFFFFF;

/// Texte sombre posé sur les dominantes claires (U5).
const int kInkOnLight = 0xFF121212;

int _tone(int argb, double tone, [double? chroma]) {
  final h = Hct.fromInt(argb);
  return Hct.from(h.hue, chroma ?? h.chroma, tone).toInt();
}

/// Garde [argb] s'il atteint [need] contre [against] ; sinon déplace sa seule
/// tonalité HCT par pas de 0,5 ([direction] +1 éclaircit, −1 assombrit). Si
/// la direction demandée n'y suffit pas, l'autre direction est essayée
/// (jamais le cas pour les palettes du propriétaire ; vérifié par test).
int kAdjustTone(int argb, int against, double need, int direction) {
  if (kContrastArgb(argb, against) >= need) return argb;
  final t0 = Hct.fromInt(argb).tone;
  for (final dir in [direction, -direction]) {
    for (var step = 1; step <= 200; step++) {
      final t = t0 + dir * step * 0.5;
      if (t < 0 || t > 100) break;
      final c = _tone(argb, t);
      if (kContrastArgb(c, against) >= need) return c;
    }
  }
  return kContrastArgb(_white, against) >= kContrastArgb(0xFF000000, against)
      ? _white
      : 0xFF000000;
}

/// Tonalité de [argb] déplacée dans la seule [direction] jusqu'à [need]
/// contre la couleur de départ ; null si la borne (0 ou 100) arrive avant.
int? _toneUntil(int argb, double need, int direction) {
  final t0 = Hct.fromInt(argb).tone;
  for (var step = 1; step <= 200; step++) {
    final t = t0 + direction * step * 0.5;
    if (t < 0 || t > 100) return null;
    final c = _tone(argb, t);
    if (kContrastArgb(c, argb) >= need) return c;
  }
  return null;
}

/// Texte posé sur un aplat : blanc ou #121212, le plus contrasté.
int kOnColor(int fill) =>
    kContrastArgb(fill, _white) >= kContrastArgb(fill, kInkOnLight)
    ? _white
    : kInkOnLight;

/// Couleurs fixes historiques (charte de 5.10.0), indépendantes de la
/// palette : rareté des badges, dégradé des données, alertes de chrono,
/// fonds des illustrations. Lues par les peintres de données et les
/// illustrations (liste blanche) à travers `KPalette` ; jamais par un
/// nouvel écran.
abstract final class KFixedColors {
  static const burgundy = Color(0xFF5E1615);
  static const actionRed = Color(0xFF9E2A28);
  static const black = Color(0xFF121212);
  static const charcoal = Color(0xFF1E1E1E);
  static const gray = Color(0xFF8A8A8A);
  static const light = Color(0xFFF4F4F4);
  static const green = Color(0xFF388E3C);
  static const lightRed = Color(0xFFD96968);
}

// ----------------------------------------------------------------- rôles --

/// États communs (cahier §5.1) : valeurs de départ, sombre puis clair.
const int kValidationSombre = 0xFF5CB860, kValidationClair = 0xFF2E7D32;
const int kDangerSombre = 0xFFEF6B6B, kDangerClair = 0xFFB3261E;
const int kAvertissementSombre = 0xFFE6A23C, kAvertissementClair = 0xFF8A5300;

/// Rôles de couleur d'une palette dans un thème (couche « alias »).
///
/// - `fond` < `surface` < `haute` : profondeur par la surface (aucune ombre) ;
///   `filet` : séparateurs et contours neutres.
/// - `texte`, `texte2` (descriptions, valeurs secondaires), `texte3` (inactif
///   seulement).
/// - `pleine` : aplat de l'action principale, du jour courant, de l'onglet
///   actif, de la carte du jour = dominante **exacte** du propriétaire ;
///   `surPleine` : texte et icônes posés dessus.
/// - `encre` : élément courant, repère, chiffre mis en avant, lien (texte ou
///   icône sur `fond` ou `surface`, ≥ 4,5:1 ; jamais la dominante quand elle y
///   est illisible).
/// - `second` (données, barres secondaires, ≥ 3:1), `accent` (records,
///   réussites, Jour J, ≥ 4,5:1).
/// - `validation`, `danger`, `avertissement` : états, ≥ 4,5:1 sur `fond`,
///   `surface` et `haute`.
///
/// Contraste renforcé (U6) : mêmes règles à 7:1 (4,5:1 au lieu de 3:1), et
/// `texte2` porté à 7:1 sur `surface`.
class KRoles {
  final String paletteId;
  final bool dark, contrast;
  final Color fond, surface, haute, filet;
  final Color texte, texte2, texte3;
  final Color pleine, surPleine, encre, second, accent;
  final Color validation, danger, avertissement;

  /// Texte posé sur `encre`, `accent`, `validation`, `danger` utilisés en
  /// aplat (puces de record, pastilles d'état).
  final Color surEncre, surAccent, surValidation, surDanger;

  /// Haut de la rampe d'intensité (anatomie, flammes) : `encre` quand elle se
  /// distingue de `pleine` (≥ 2,5:1), sinon la dominante éclaircie (sombre)
  /// ou assombrie (clair) juste assez. Bas de la rampe : `pleine`.
  final Color rampe;

  const KRoles._({
    required this.paletteId,
    required this.dark,
    required this.contrast,
    required this.fond,
    required this.surface,
    required this.haute,
    required this.filet,
    required this.texte,
    required this.texte2,
    required this.texte3,
    required this.pleine,
    required this.surPleine,
    required this.encre,
    required this.second,
    required this.accent,
    required this.validation,
    required this.danger,
    required this.avertissement,
    required this.surEncre,
    required this.surAccent,
    required this.surValidation,
    required this.surDanger,
    required this.rampe,
  });

  static final Map<String, KRoles> _cache = {};

  /// Rôles d'une palette (identifiant normalisé par [normalizePaletteId]).
  static KRoles of(
    Object? paletteId, {
    required bool dark,
    bool contrast = false,
  }) {
    final p = paletteSource(paletteId);
    return _cache.putIfAbsent(
      '${p.id}|$dark|$contrast',
      () => _derive(p, dark: dark, contrast: contrast),
    );
  }

  static KRoles _derive(
    KPaletteSource p, {
    required bool dark,
    required bool contrast,
  }) {
    final strong = contrast ? 7.0 : 4.5;
    final weak = contrast ? 4.5 : 3.0;
    final int fond, surface, haute, filet, texte, texte3, encre, second, accent;
    int texte2;
    if (dark) {
      final f = Hct.fromInt(p.fondSombre);
      int sd(double dt) =>
          Hct.from(f.hue, math.min(f.chroma, 16), f.tone + dt).toInt();
      fond = p.fondSombre;
      surface = sd(5);
      haute = sd(10);
      filet = sd(15);
      texte = Hct.from(f.hue, 2, 95).toInt();
      texte2 = Hct.from(f.hue, 4, 70).toInt();
      texte3 = Hct.from(f.hue, 4, 50).toInt();
      encre = kAdjustTone(p.dominante, surface, strong, 1);
      second = kAdjustTone(p.secondaire, surface, weak, 1);
      accent = kAdjustTone(p.accent, surface, strong, 1);
      if (contrast) texte2 = kAdjustTone(texte2, surface, 7, 1);
    } else {
      final f = Hct.fromInt(p.fondClair);
      fond = p.fondClair;
      surface = _white;
      haute = p.fondClair;
      filet = Hct.from(f.hue, math.min(f.chroma, 8), f.tone - 10).toInt();
      texte = Hct.from(f.hue, 4, 10).toInt();
      texte2 = Hct.from(f.hue, 6, 40).toInt();
      texte3 = Hct.from(f.hue, 6, 60).toInt();
      encre = kAdjustTone(
        kAdjustTone(p.dominante, _white, strong, -1),
        fond,
        strong,
        -1,
      );
      second = kAdjustTone(p.secondaire, _white, weak, -1);
      accent = kAdjustTone(
        kAdjustTone(p.accent, _white, strong, -1),
        fond,
        strong,
        -1,
      );
      if (contrast) {
        texte2 = kAdjustTone(kAdjustTone(texte2, _white, 7, -1), fond, 7, -1);
      }
    }
    // Décision du propriétaire (10/10/2026, 10:11) : dominante exacte pour
    // les aplats, en clair comme en sombre ; seul le texte posé dessus
    // s'adapte (≥ 4,5:1 vérifié pour les 8 palettes).
    final pleine = p.dominante;
    final surPleine = kOnColor(pleine);
    // États : valeur commune, ajustée en tonalité seulement si elle passe
    // sous le seuil sur la surface la moins favorable de la palette.
    int state(int value) {
      final dir = dark ? 1 : -1;
      var v = value;
      for (var i = 0; i < 3; i++) {
        for (final bg in [fond, surface, haute]) {
          v = kAdjustTone(v, bg, strong, dir);
        }
      }
      return v;
    }

    final validation = state(dark ? kValidationSombre : kValidationClair);
    final danger = state(dark ? kDangerSombre : kDangerClair);
    final avertissement = state(
      dark ? kAvertissementSombre : kAvertissementClair,
    );
    var rampe = encre;
    if (kContrastArgb(rampe, pleine) < 2.5) {
      if (dark) {
        // En sombre, l'intensité monte vers le clair ; une dominante déjà
        // très claire (Neon) prend sa secondaire, visible sur le fond.
        rampe = _toneUntil(pleine, 2.5, 1) ?? second;
      } else {
        rampe = kAdjustTone(pleine, pleine, 2.5, -1);
      }
    }
    Color c(int v) => Color(v);
    return KRoles._(
      paletteId: p.id,
      dark: dark,
      contrast: contrast,
      fond: c(fond),
      surface: c(surface),
      haute: c(haute),
      filet: c(filet),
      texte: c(texte),
      texte2: c(texte2),
      texte3: c(texte3),
      pleine: c(pleine),
      surPleine: c(surPleine),
      encre: c(encre),
      second: c(second),
      accent: c(accent),
      validation: c(validation),
      danger: c(danger),
      avertissement: c(avertissement),
      surEncre: c(kOnColor(encre)),
      surAccent: c(kOnColor(accent)),
      surValidation: c(kOnColor(validation)),
      surDanger: c(kOnColor(danger)),
      rampe: c(rampe),
    );
  }

  /// Rôles nommés comme dans `inputs/palettes_roles.json` (test).
  Map<String, Color> get named => {
    'fond': fond,
    'surface': surface,
    'haute': haute,
    'filet': filet,
    'texte': texte,
    'texte2': texte2,
    'texte3': texte3,
    'pleine': pleine,
    'surPleine': surPleine,
    'encre': encre,
    'second': second,
    'accent': accent,
  };
}

/// Écriture `#RRGGBB` d'une couleur (tests, catalogue).
String kHex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).toUpperCase().padLeft(6, '0')}';
