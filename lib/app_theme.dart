// Adaptateur de la refonte UI (UI0, cahier §5) : l'API historique des
// couleurs (`KAccentSpec`, `KPalette`, `SL`, `ProgrammeColors`), des commandes
// (`KControl`) et du thème (`buildTheme`) lit désormais les jetons du kit
// (`lib/kit/`). Les écrans existants compilent sans changement et prennent
// déjà les 8 palettes du propriétaire, le contraste renforcé et les polices
// Barlow ; les lots d'écrans passent ensuite aux composants du kit. Ce
// fichier disparaît à UI5.
import 'package:flutter/material.dart';

import 'kit/palette.dart';
import 'kit/theme.dart';
import 'kit/tokens.dart';

export 'kit/palette.dart' show kPaletteSources, normalizePaletteId, kContrast;

/// Commandes tactiles partagées par les formulaires et les séances.
class KControl {
  static const double height = KSize.target, radius = KSize.target / 2;
  static const double iconSize = KSize.iconSmall, gap = KSpacing.s12;
  static const double buttonHeight = KSize.target;
  static const density = VisualDensity.standard;
  static const double formGap = KSpacing.s16;
  static const shape = KRadius.pill;
  static const fieldPadding = EdgeInsets.symmetric(
    horizontal: KSpacing.s14,
    vertical: KSpacing.s14,
  );
  static const selectPadding = EdgeInsets.symmetric(
    horizontal: KSpacing.s14,
    vertical: KSpacing.s12,
  );
  static final textStyle = KType.corps;
  static final numberStyle = KType.corps.copyWith(
    fontWeight: KType.corpsFort.fontWeight,
    fontFeatures: KFont.tabular,
  );
}

/// Palette choisie par l'utilisateur (préférence `accent`).
///
/// UI0 : les 8 palettes du propriétaire (cahier §5.1) remplacent les six
/// couleurs de L5-C. Chaque instance ne porte que l'identifiant et le nom ;
/// les couleurs sont dérivées des jetons (`KRoles`) et gardent les rôles
/// historiques lus par les illustrations et les peintres de données :
/// [principal] = dominante exacte (aplats), [bright] / [vividLight] = haut de
/// la rampe d'intensité (`KRoles.rampe`, sombre / clair), [vivid] = couleur
/// vive des sélections historiques (secondaire ajustée).
@immutable
class KAccentSpec {
  /// Identifiant stable enregistré dans les réglages (`accent`).
  final String id;
  final String label;
  const KAccentSpec._(this.id, this.label);

  KRoles get _dark => KRoles.of(id, dark: true);
  KRoles get _light => KRoles.of(id, dark: false);

  /// Dominante exacte du propriétaire (boutons pleins, carte du jour).
  Color get principal => _dark.pleine;

  /// Couleur vive des sélections historiques, en sombre.
  Color get vivid => _dark.second;

  /// Haut de la rampe d'intensité en sombre (anatomie, flammes, décor).
  Color get bright => _dark.rampe;

  /// Texte posé sur [principal].
  Color? get onPrincipal => _dark.surPleine;

  /// Texte posé sur [vivid].
  Color? get onVivid => Color(kOnColor(vivid.toARGB32()));

  /// Variantes du mode clair.
  Color? get vividLight => _light.rampe;
  Color? get accentLight => _light.encre;
  Color? get onVividLight => Color(kOnColor(_light.rampe.toARGB32()));
  Color? get decorLight => _light.rampe;
  List<Color>? get gaugeLight => [principal, _light.rampe];

  static const bordeaux = KAccentSpec._('bordeaux', 'Bordeaux Performance');
  static const obsidian = KAccentSpec._('obsidian', 'Obsidian Energy');
  static const arctic = KAccentSpec._('arctic', 'Arctic Motion');
  static const neon = KAccentSpec._('neon', 'Neon Athlete');
  static const titanium = KAccentSpec._('titanium', 'Titanium Pro');
  static const violet = KAccentSpec._('violet', 'Violet Momentum');
  static const forest = KAccentSpec._('forest', 'Forest Endurance');
  static const solar = KAccentSpec._('solar', 'Solar Sprint');

  /// Anciens noms (L5-C) : palettes vers lesquelles leurs identifiants sont
  /// relus (cahier §5.1).
  static const rouge = bordeaux;
  static const jaune = neon;
  static const vert = forest;
  static const orange = solar;
  static const turquoise = arctic;

  /// Ordre d'affichage du sélecteur (ordre du propriétaire).
  static const all = [
    bordeaux,
    obsidian,
    arctic,
    neon,
    titanium,
    violet,
    forest,
    solar,
  ];
  static const defaultId = kDefaultPaletteId;

  /// Palette d'un identifiant ; ancien identifiant relu, absent, inconnu ou
  /// d'un autre type : Bordeaux.
  static KAccentSpec byId(Object? id) {
    final n = normalizePaletteId(id);
    return all.firstWhere((a) => a.id == n);
  }

  /// Identifiant enregistrable.
  static String normalize(Object? id) => byId(id).id;
}

/// Rôles historiques de la charte, lus sur les jetons du kit.
///
/// Rôles fixes indépendants de la palette (rareté, dégradé historique des
/// données, alertes de chrono) : constantes statiques, inchangées.
class KPalette {
  /// Rouge Kalis historique : rôles fixes des peintres de données et des
  /// rangs (indépendants de la palette choisie).
  static const burgundy = KFixedColors.burgundy;
  static const actionRed = KFixedColors.actionRed;
  static const black = KFixedColors.black;
  static const charcoal = KFixedColors.charcoal;
  static const gray = KFixedColors.gray;
  static const light = KFixedColors.light;
  static const green = KFixedColors.green;
  static const lightRed = KFixedColors.lightRed;

  /// Dégradé historique des données (graphiques d'intensité, chronos).
  static const redGradient = [burgundy, actionRed];
  final bool dark;
  final KAccentSpec a;
  final bool contrast;
  const KPalette(this.dark, [this.a = KAccentSpec.bordeaux, bool? contrast])
    : contrast = contrast ?? false;

  KRoles get r => KRoles.of(a.id, dark: dark, contrast: contrast);

  Color get bg => r.fond;
  Color get surface => r.surface;
  Color get card => r.surface;
  Color get text => r.texte;
  Color get dim => r.texte2;

  /// Dominante : actions principales, jauges, cartes de marque.
  Color get bordeaux => r.pleine;

  /// États actifs, sélection, records (fond ou contour).
  Color get action => dark ? a.vivid : a.vividLight!;

  /// Accent lisible en texte et icônes : `encre`.
  Color get accent => r.encre;

  /// Texte sur [bordeaux].
  Color get onBrand => r.surPleine;
  Color get onBrandSoft => r.surPleine;

  /// Texte sur [action].
  Color get onAction => (dark ? a.onVivid : a.onVividLight)!;
  Color get onActionSoft => onAction;

  /// Icônes décoratives vives (flamme de série, boss, confettis).
  Color get decor => dark ? a.bright : a.decorLight!;

  /// Jauges de la charte (dont les barres de progression du niveau).
  List<Color> get gauge => dark ? [a.principal, a.vivid] : a.gaugeLight!;

  /// Confettis de célébration.
  List<Color> get confetti => [r.pleine, r.encre, r.accent, r.second];

  /// Alertes de chrono, confirmations de suppression (fond ou contour,
  /// texte clair posé dessus) : rouge d'action historique, rôle fixe.
  Color get alert => actionRed;

  /// Accent rouge historique : phases de chrono, rareté, données.
  Color get redAccent => dark ? lightRed : burgundy;

  /// Teinte de fond derrière un élément accentué (puces, icônes de menu).
  Color get accentTint => r.haute;

  /// Validation et succès uniquement.
  Color get success => r.validation;

  /// Logo : texte en sombre ; en clair, la dominante (cahier §5.1), ou son
  /// encre quand la dominante est trop claire pour le fond (Neon).
  Color get logo => dark ? r.texte : r.encre;
  Color get prevViolet => r.texte2;
  Color get danger => r.danger;
  Color get line => r.filet;
  Color get faint => r.haute;
  Color get dot => r.texte3;
  Color get onAccent => r.surEncre;
  Color get progressTrack => r.filet;
  Color get fieldFill => r.surface;
  Color get fieldBorder => r.texte3;
  Color get formFill => r.surface;
  Color get formBorder => r.texte3;
}

class SL {
  static bool dark = true;

  /// Contraste renforcé (U6) ; synchronisé par l'application.
  static bool contrast = false;
  static KPalette get _palette => KPalette(dark, accentSpec, contrast);

  /// Jetons courants (même source que `KTokens.of(context)`).
  static KRoles get roles => _palette.r;
  static Color get bg => _palette.bg;
  static Color get surface => _palette.surface;
  static Color get card => _palette.card;
  static Color get text => _palette.text;
  static Color get dim => _palette.dim;
  static Color get bordeaux => _palette.bordeaux;
  static Color get action => _palette.action;
  static Color get accent => _palette.accent;
  static Color get accentTint => _palette.accentTint;
  static Color get success => _palette.success;
  static Color get progressTrack => _palette.progressTrack;
  static Color get logo => _palette.logo;
  static Color get prevViolet => _palette.prevViolet;
  static Color get danger => _palette.danger;
  static Color get line => _palette.line;
  static Color get faint => _palette.faint;
  static Color get dot => _palette.dot;
  static Color get onAccent => _palette.onAccent;
  static Color get fieldFill => _palette.fieldFill;
  static Color get fieldBorder => _palette.fieldBorder;
  static Color get formFill => _palette.formFill;
  static Color get formBorder => _palette.formBorder;

  static Color get onBrand => _palette.onBrand;
  static Color get onBrandSoft => _palette.onBrandSoft;
  static Color get onAction => _palette.onAction;
  static Color get onActionSoft => _palette.onActionSoft;
  static Color get decor => _palette.decor;
  static Color get alert => _palette.alert;
  static Color get redAccent => _palette.redAccent;
  static List<Color> get confetti => _palette.confetti;

  /// Palette courante ; synchronisée par l'application.
  static KAccentSpec accentSpec = KAccentSpec.bordeaux;

  /// Texte à poser sur [bg] quand c'est un aplat de la palette.
  static Color onFill(Color bg) => bg == action
      ? onActionSoft
      : (bg == bordeaux ? onBrandSoft : Color(kOnColor(bg.toARGB32())));

  /// Dégradé des jauges (dominante) ; les graphiques de données gardent
  /// [KPalette.redGradient].
  static List<Color> get gradient => _palette.gauge;
}

class ProgrammeColors {
  final bool dark;
  final KAccentSpec spec;
  const ProgrammeColors(this.dark, [this.spec = KAccentSpec.bordeaux]);
  factory ProgrammeColors.of(BuildContext context) => ProgrammeColors(
    Theme.of(context).brightness == Brightness.dark,
    SL.accentSpec,
  );
  KPalette get p => KPalette(dark, spec, SL.contrast);
  Color get card => p.card;
  Color get accent => p.accent;
  Color get muted => p.dim;
  Color get levelRest => p.dot;
  Color get green => p.success;
  Color get volume => p.accent;
  Color get circle => p.faint;
  Color get onAccent => p.onAccent;

  /// Curseur de semaine (frise, pastille « S13 ») : `encre`, lisible sur le
  /// fond dans les 8 palettes (la dominante Neon ne l'est pas en clair).
  Color get slider => p.accent;
  Color get onSlider => p.onAccent;
}

InputDecoration logDeco({String? hint, String? suffix}) => InputDecoration(
  hintText: hint,
  suffixText: suffix,
  isDense: true,
  filled: true,
  fillColor: SL.roles.haute,
  hintStyle: KType.corps.copyWith(color: SL.roles.texte3),
  contentPadding: const EdgeInsets.symmetric(
    horizontal: KSpacing.s8,
    vertical: KSpacing.s8,
  ),
  border: OutlineInputBorder(
    borderRadius: KRadius.menuRadius,
    borderSide: BorderSide(color: SL.roles.filet),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: KRadius.menuRadius,
    borderSide: BorderSide(color: SL.roles.filet),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: KRadius.menuRadius,
    borderSide: BorderSide(color: SL.roles.encre, width: KSize.current),
  ),
);

/// Thème de l'application (adaptateur de `kitTheme`) ; positionne aussi la
/// palette courante de [SL] pour les usages directs et les tests.
ThemeData buildTheme(
  bool dark, [
  KAccentSpec accent = KAccentSpec.bordeaux,
  bool? contrast,
]) {
  SL.dark = dark;
  SL.accentSpec = accent;
  if (contrast != null) SL.contrast = contrast;
  return kitTheme(dark: dark, paletteId: accent.id, contrast: SL.contrast);
}
