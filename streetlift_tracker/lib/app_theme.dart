import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'motion.dart';

/// Commandes tactiles partagées par les formulaires et les séances.
class KControl {
  static const double height = 48, radius = 24, iconSize = 20, gap = 10;
  static const double buttonHeight = 48;
  static const density = VisualDensity.standard;
  static const double formGap = 16;
  static const shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(radius)),
  );
  static const fieldPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 14,
  );
  static const selectPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 11,
  );
  static const textStyle = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 15,
    height: 1.3,
  );
  static const numberStyle = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 15,
    height: 1.3,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

/// Couleur dominante choisie par l'utilisateur (L5-C, 26/09/2026).
///
/// Six familles au choix, le Rouge Kalis restant la valeur par défaut. Chaque
/// famille remplit les trois rôles historiques du rouge : [principal] (rôle
/// du bordeaux : boutons pleins, carte du jour, bandeaux, jauges),
/// [vivid] (rôle du rouge d'action : sélection, curseur, interrupteurs) et
/// [bright] (accent textuel sur fond sombre). Les couleurs porteuses d'un sens
/// indépendant (erreurs, validation, chronos, rangs, données, couvertures)
/// ne dépendent pas de ce choix : voir les rôles fixes de [KPalette].
///
/// Le Jaune est trop clair pour du texte blanc : il porte du #121212, et en
/// mode clair sa sélection et son accent passent à l'or foncé #7A5800.
@immutable
class KAccentSpec {
  /// Identifiant stable enregistré dans les réglages (`accent`).
  final String id;
  final String label;
  final Color principal, vivid, bright;

  /// Texte posé sur [principal] / [vivid] ; null = tons clairs historiques
  /// (blanc ou #F4F4F4 selon l'élément).
  final Color? onPrincipal, onVivid;

  /// Variantes du mode clair quand la teinte n'y est pas lisible.
  final Color? vividLight, accentLight, onVividLight, decorLight;
  final List<Color>? gaugeLight;

  const KAccentSpec({
    required this.id,
    required this.label,
    required this.principal,
    required this.vivid,
    required this.bright,
    this.onPrincipal,
    this.onVivid,
    this.vividLight,
    this.accentLight,
    this.onVividLight,
    this.decorLight,
    this.gaugeLight,
  });

  static const rouge = KAccentSpec(
    id: 'rouge',
    label: 'Rouge Kalis',
    principal: KPalette.burgundy,
    vivid: KPalette.actionRed,
    bright: KPalette.lightRed,
  );
  static const jaune = KAccentSpec(
    id: 'jaune',
    label: 'Jaune',
    principal: Color(0xFFE6B000),
    vivid: Color(0xFFF5C400),
    bright: Color(0xFFF5C400),
    onPrincipal: KPalette.black,
    onVivid: KPalette.black,
    vividLight: Color(0xFF7A5800),
    accentLight: Color(0xFF7A5800),
    decorLight: Color(0xFFE6B000),
    gaugeLight: [Color(0xFF7A5800), Color(0xFF8A6500)],
  );
  static const vert = KAccentSpec(
    id: 'vert',
    label: 'Vert',
    principal: Color(0xFF0B4D33),
    vivid: Color(0xFF157A4E),
    bright: Color(0xFF4EC08A),
  );
  static const violet = KAccentSpec(
    id: 'violet',
    label: 'Violet',
    principal: Color(0xFF44146B),
    vivid: Color(0xFF8240C4),
    bright: Color(0xFFB38CF2),
  );
  static const orange = KAccentSpec(
    id: 'orange',
    label: 'Orange',
    principal: Color(0xFF6E2E05),
    vivid: Color(0xFFA84707),
    bright: Color(0xFFF2924A),
  );
  static const turquoise = KAccentSpec(
    id: 'turquoise',
    label: 'Turquoise',
    principal: Color(0xFF08494F),
    vivid: Color(0xFF0E7479),
    bright: Color(0xFF3EC4C4),
  );

  /// Ordre d'affichage du sélecteur.
  static const all = [rouge, jaune, vert, violet, orange, turquoise];
  static const defaultId = 'rouge';

  /// Palette d'un identifiant ; absent, inconnu ou d'un autre type : rouge.
  static KAccentSpec byId(Object? id) =>
      all.firstWhere((a) => a.id == id, orElse: () => rouge);

  /// Identifiant enregistrable : repli explicite vers le rouge.
  static String normalize(Object? id) => byId(id).id;
}

/// Bordeaux, anthracite et vert.
///
/// Rôles de la charte : #6B0C0C fait avancer la séance (boutons pleins, cartes
/// de marque, remplissage des jauges) ; #A61717 marque les états actifs, les
/// records et les alertes de chrono ; #388E3C ne sert qu'à la validation.
/// Sur fond sombre, ces deux rouges restent sous 3:1 en texte ; l'accent
/// textuel sombre est donc une teinte claire du rouge d'action (#E85959,
/// 4,8:1 sur #1E1E1E), le clair conserve le bordeaux (12:1 sur blanc).
class KPalette {
  /// Rouge Kalis : valeurs historiques, aussi utilisées par les rôles fixes
  /// (alertes, chronos, rangs, données, couvertures WOD) quelle que soit la
  /// couleur dominante choisie.
  static const burgundy = Color(0xFF6B0C0C);
  static const actionRed = Color(0xFFA61717);
  static const black = Color(0xFF121212);
  static const charcoal = Color(0xFF1E1E1E);
  static const gray = Color(0xFF8A8A8A);
  static const light = Color(0xFFF4F4F4);
  static const green = Color(0xFF388E3C);
  static const lightRed = Color(0xFFE85959);

  /// Dégradé historique des données (graphiques d'intensité, chronos).
  static const redGradient = [burgundy, actionRed];
  final bool dark;
  final KAccentSpec a;
  const KPalette(this.dark, [this.a = KAccentSpec.rouge]);
  Color get bg => dark ? black : light;
  Color get surface => dark ? charcoal : Colors.white;
  Color get card => dark ? charcoal : Colors.white;
  Color get text => dark ? light : black;
  Color get dim => dark ? gray : const Color(0xFF616161);

  /// Dominante : actions principales, jauges, cartes de marque.
  Color get bordeaux => a.principal;

  /// États actifs, sélection, records (fond ou contour, pas texte sur fond
  /// sombre). Les alertes de chrono et les suppressions utilisent [alert].
  Color get action => dark ? a.vivid : (a.vividLight ?? a.vivid);

  /// Accent lisible en texte et icônes sur toutes les surfaces.
  Color get accent => dark ? a.bright : (a.accentLight ?? a.principal);

  /// Texte sur [bordeaux] : blanc (`onBrand`) ou blanc cassé
  /// (`onBrandSoft`) selon l'élément historique ; #121212 pour le Jaune.
  Color get onBrand => a.onPrincipal ?? Colors.white;
  Color get onBrandSoft => a.onPrincipal ?? light;

  Color? get _onVivid =>
      dark || a.vividLight == null ? a.onVivid : a.onVividLight;

  /// Texte sur [action].
  Color get onAction => _onVivid ?? Colors.white;
  Color get onActionSoft => _onVivid ?? light;

  /// Icônes décoratives vives (flamme de série, boss, confettis).
  Color get decor => dark ? a.bright : (a.decorLight ?? a.bright);

  /// Jauges de la charte (dont les barres de progression du niveau).
  List<Color> get gauge =>
      dark ? [a.principal, a.vivid] : (a.gaugeLight ?? [a.principal, a.vivid]);

  /// Confettis de célébration.
  List<Color> get confetti => [a.principal, a.vivid, a.bright, light];

  // ----- Rôles fixes : indépendants de la couleur dominante -----

  /// Alertes de chrono, confirmations de suppression (fond ou contour).
  Color get alert => actionRed;

  /// Accent rouge historique : phases de chrono, rareté, données.
  Color get redAccent => dark ? lightRed : burgundy;

  /// Teinte de fond derrière un élément accentué (puces, icônes de menu).
  Color get accentTint => accent.withValues(alpha: dark ? .14 : .10);

  /// Validation et succès uniquement.
  Color get success => dark ? const Color(0xFF64AA67) : const Color(0xFF2C7230);
  Color get logo => dark ? light : burgundy;
  Color get prevViolet =>
      dark ? const Color(0xFFCCCCCC) : const Color(0xFF575757);
  Color get danger => dark ? const Color(0xFFF09B9B) : actionRed;
  Color get line => dark ? const Color(0xFF383838) : const Color(0xFFDDDDDD);
  Color get faint => dark ? const Color(0xFF232323) : const Color(0xFFE5E5E5);
  Color get dot => dark ? const Color(0xFF4A4A4A) : const Color(0xFFBDBDBD);
  Color get onAccent => dark ? black : light;
  Color get progressTrack =>
      dark ? const Color(0xFF333333) : const Color(0xFFDCDCDC);
  Color get fieldFill => dark ? charcoal : const Color(0xFFEEEEEE);
  Color get fieldBorder => gray;
  Color get formFill => dark ? charcoal : const Color(0xFFEEEEEE);
  Color get formBorder => gray;
}

class SL {
  static bool dark = true;
  static KPalette get _palette => KPalette(dark, accentSpec);
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

  /// Couleur dominante courante (L5-C) ; synchronisée par l'application.
  static KAccentSpec accentSpec = KAccentSpec.rouge;

  /// Texte à poser sur [bg] quand c'est une couleur dominante pleine.
  static Color onFill(Color bg) =>
      bg == action
          ? onActionSoft
          : (bg == bordeaux ? onBrandSoft : KPalette.light);

  /// Dégradé des jauges (dominante) ; les graphiques de données gardent
  /// [KPalette.redGradient].
  static List<Color> get gradient => _palette.gauge;
}

class ProgrammeColors {
  final bool dark;
  final KAccentSpec accent;
  const ProgrammeColors(this.dark, [this.accent = KAccentSpec.rouge]);
  factory ProgrammeColors.of(BuildContext context) => ProgrammeColors(
    Theme.of(context).brightness == Brightness.dark,
    SL.accentSpec,
  );
  KPalette get p => KPalette(dark, accent);
  Color get card => p.card;
  Color get accent => p.accent;
  Color get muted => p.dim;
  Color get levelRest => p.dot;
  Color get green => p.success;
  Color get volume => p.accent;
  Color get circle => p.faint;
  Color get onAccent => p.onAccent;

  /// Curseur de semaine : vive de la dominante, libellé blanc cassé
  /// (#121212 sur le Jaune).
  Color get slider => p.action;
  Color get onSlider => p.onActionSoft;
}

InputDecoration logDeco({String? hint, String? suffix}) => InputDecoration(
  hintText: hint,
  suffixText: suffix,
  isDense: true,
  filled: true,
  fillColor: SL.fieldFill,
  hintStyle: TextStyle(
    fontFamily: 'Roboto',
    color: SL.dim.withValues(alpha: .8),
  ),
  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: SL.fieldBorder),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: SL.fieldBorder),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: SL.accent, width: 1.5),
  ),
);

ThemeData buildTheme(bool dark, [KAccentSpec accent = KAccentSpec.rouge]) {
  SL.dark = dark;
  SL.accentSpec = accent;
  final p = KPalette(dark, accent);
  final scheme = (dark ? const ColorScheme.dark() : const ColorScheme.light())
      .copyWith(
        primary: p.accent,
        onPrimary: p.onAccent,
        primaryContainer: p.accentTint,
        onPrimaryContainer: p.text,
        secondary: p.success,
        onSecondary: dark ? KPalette.black : KPalette.light,
        secondaryContainer: p.success.withValues(alpha: .14),
        onSecondaryContainer: p.text,
        tertiary: p.prevViolet,
        onTertiary: p.onAccent,
        tertiaryContainer: p.prevViolet.withValues(alpha: .14),
        onTertiaryContainer: p.text,
        surface: p.surface,
        onSurface: p.text,
        onSurfaceVariant: p.dim,
        surfaceContainer: p.card,
        surfaceContainerLow: p.card,
        surfaceContainerHigh: p.formFill,
        surfaceContainerHighest: p.faint,
        outline: p.formBorder,
        outlineVariant: p.line,
        error: p.danger,
        inverseSurface: dark ? KPalette.light : KPalette.black,
        onInverseSurface: dark ? KPalette.black : KPalette.light,
        inversePrimary:
            dark ? (accent.accentLight ?? accent.principal) : accent.bright,
      );
  OutlineInputBorder border(Color c, [double width = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(KControl.radius),
    borderSide: BorderSide(color: c, width: width),
  );
  const buttonText = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  return ThemeData(
    useMaterial3: true,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: KPageTransitionsBuilder(),
        TargetPlatform.iOS: KPageTransitionsBuilder(cupertino: true),
        TargetPlatform.macOS: KPageTransitionsBuilder(cupertino: true),
        TargetPlatform.windows: KPageTransitionsBuilder(),
        TargetPlatform.linux: KPageTransitionsBuilder(),
        TargetPlatform.fuchsia: KPageTransitionsBuilder(),
      },
    ),
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    splashFactory: InkSparkle.splashFactory,
    cardTheme: CardThemeData(
      color: p.card,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      foregroundColor: p.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 16,
      toolbarHeight: 64,
      systemOverlayStyle:
          dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        color: p.text,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: -.5,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: p.formFill,
      contentPadding: KControl.fieldPadding,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      alignLabelWithHint: true,
      helperMaxLines: 2,
      errorMaxLines: 3,
      prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      border: border(p.formBorder),
      enabledBorder: border(Colors.transparent),
      focusedBorder: border(p.accent, 1.5),
      labelStyle: TextStyle(fontFamily: 'Roboto', color: p.dim, fontSize: 14),
      floatingLabelStyle: TextStyle(
        fontFamily: 'Roboto',
        color: p.accent,
        fontSize: 14,
      ),
      hintStyle: TextStyle(fontFamily: 'Roboto', color: p.dim),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.bordeaux,
        foregroundColor: p.onBrandSoft,
        minimumSize: const Size(48, 48),
        iconSize: 20,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: KControl.shape,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        iconSize: 20,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: BorderSide(color: p.formBorder),
        shape: KControl.shape,
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        iconSize: 20,
        shape: KControl.shape,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        textStyle: buttonText,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        iconSize: 22,
        shape: KControl.shape,
        padding: const EdgeInsets.all(12),
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      iconColor: p.accent,
      selectedColor: p.accent,
      selectedTileColor: p.accentTint,
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        color: p.text,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        color: p.dim,
        fontSize: 13,
        height: 1.4,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.faint,
      selectedColor: p.accentTint,
      secondarySelectedColor: p.accentTint,
      checkmarkColor: p.accent,
      labelStyle: TextStyle(
        fontFamily: 'Roboto',
        color: p.text,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      // L5-C : en sombre, libellé blanc cassé (l'accent sur sa teinte restait
      // à 4,04:1 en rouge) ; la coche et le fond gardent l'accent.
      secondaryLabelStyle: TextStyle(
        fontFamily: 'Roboto',
        color: dark ? p.text : p.accent,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide.none,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: p.bordeaux,
      linearTrackColor: p.progressTrack,
      linearMinHeight: 6,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: p.text,
      unselectedLabelColor: p.dim,
      indicatorColor: p.action,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
      labelStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.onAction : p.dim,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.action : p.faint,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? KPalette.green : null,
      ),
      checkColor: const WidgetStatePropertyAll(Colors.white),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        ),
        shape: const WidgetStatePropertyAll(KControl.shape),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.action : p.faint,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.onAction : p.dim,
        ),
        side: const WidgetStatePropertyAll(BorderSide.none),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: KPalette.gray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        color: p.text,
        fontSize: 21,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: TextStyle(
        fontFamily: 'Roboto',
        color: p.text,
        fontSize: 15,
        height: 1.45,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(
        fontFamily: 'Roboto',
        color: scheme.onInverseSurface,
        fontWeight: FontWeight.w500,
      ),
      actionTextColor: scheme.inversePrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      textStyle: TextStyle(fontFamily: 'Roboto', color: p.text, fontSize: 14),
    ),
    dividerColor: p.line,
    iconTheme: IconThemeData(color: p.text),
    textTheme: TextTheme(
      bodyLarge: KControl.textStyle.copyWith(color: p.text),
      bodyMedium: TextStyle(
        fontFamily: 'Roboto',
        color: p.text,
        fontSize: 14,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Roboto',
        color: p.dim,
        fontSize: 12.5,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Roboto',
        color: p.text,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -.2,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Roboto',
        color: p.text,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -.5,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Roboto',
        color: p.text,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -.8,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Roboto',
        color: p.text,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -1.1,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Roboto',
        color: p.text,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
