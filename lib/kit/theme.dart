// UI0 (refonte UI) : thème Material de l'application, construit sur les
// jetons (cahier §5). Les composants historiques (boutons, champs, listes,
// feuilles, dialogues) prennent ainsi déjà palettes, polices et rayons avant
// que les lots d'écrans ne passent aux composants du kit.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'palette.dart';
import 'tokens.dart';
import 'transitions.dart';

/// Thème d'une palette, d'une luminosité et du mode de contraste.
ThemeData kitTheme({
  required bool dark,
  String paletteId = kDefaultPaletteId,
  bool contrast = false,
  bool capsTitles = kCapsTitles,
}) {
  final r = KRoles.of(paletteId, dark: dark, contrast: contrast);
  final tokens = KTokens(roles: r, capsTitles: capsTitles);
  final scheme = (dark ? const ColorScheme.dark() : const ColorScheme.light())
      .copyWith(
        primary: r.encre,
        onPrimary: r.surEncre,
        primaryContainer: r.haute,
        onPrimaryContainer: r.texte,
        secondary: r.validation,
        onSecondary: r.surValidation,
        secondaryContainer: r.haute,
        onSecondaryContainer: r.texte,
        tertiary: r.accent,
        onTertiary: r.surAccent,
        tertiaryContainer: r.haute,
        onTertiaryContainer: r.texte,
        surface: r.surface,
        onSurface: r.texte,
        onSurfaceVariant: r.texte2,
        surfaceContainerLowest: r.fond,
        surfaceContainerLow: r.surface,
        surfaceContainer: r.surface,
        surfaceContainerHigh: r.haute,
        surfaceContainerHighest: r.haute,
        surfaceDim: r.fond,
        surfaceBright: r.haute,
        outline: r.texte3,
        outlineVariant: r.filet,
        error: r.danger,
        onError: r.surDanger,
        inverseSurface: r.texte,
        onInverseSurface: r.fond,
        // Lien posé sur la surface inversée (texte) : encre de l'autre
        // thème, ajustée au besoin (≥ 4,5:1).
        inversePrimary: Color(
          kAdjustTone(
            KRoles.of(
              paletteId,
              dark: !dark,
              contrast: contrast,
            ).encre.toARGB32(),
            r.texte.toARGB32(),
            contrast ? 7 : 4.5,
            dark ? -1 : 1,
          ),
        ),
        surfaceTint: Colors.transparent,
        shadow: Colors.transparent,
      );
  TextStyle t(TextStyle s, Color c) => s.copyWith(color: c);
  final field = OutlineInputBorder(
    borderRadius: const BorderRadius.all(Radius.circular(KSize.target / 2)),
    borderSide: BorderSide(color: r.filet),
  );
  const pill = WidgetStatePropertyAll<OutlinedBorder>(KRadius.pill);
  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    fontFamily: KFont.text,
    extensions: [tokens],
    scaffoldBackgroundColor: r.fond,
    canvasColor: r.fond,
    splashFactory: InkSparkle.splashFactory,
    materialTapTargetSize: MaterialTapTargetSize.padded,
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
    textTheme: TextTheme(
      displaySmall: t(KType.titreRacine, r.texte),
      headlineLarge: t(KType.titreRacine, r.texte),
      headlineMedium: t(KType.titreRacine, r.texte),
      headlineSmall: t(KType.titreEcran, r.texte),
      titleLarge: t(KType.titreEcran, r.texte),
      titleMedium: t(KType.corpsFort, r.texte),
      titleSmall: t(KType.libelle, r.texte),
      bodyLarge: t(KType.corps, r.texte),
      bodyMedium: t(KType.corps, r.texte),
      bodySmall: t(KType.detail, r.texte2),
      labelLarge: t(KType.libelle, r.texte),
      labelMedium: t(KType.micro, r.texte2),
      labelSmall: t(KType.micro, r.texte2),
    ),
    iconTheme: IconThemeData(color: r.texte, size: KSize.icon),
    dividerColor: r.filet,
    dividerTheme: DividerThemeData(color: r.filet, thickness: 1, space: 1),
    cardTheme: CardThemeData(
      color: r.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: KRadius.cardShape,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: r.fond,
      foregroundColor: r.texte,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: KSpacing.s16,
      toolbarHeight: KSize.dock,
      systemOverlayStyle: dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      titleTextStyle: tokens.titleStyle(t(KType.titreEcran, r.texte)),
      iconTheme: IconThemeData(color: r.texte, size: KSize.icon),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: r.haute,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: KSpacing.s16,
        vertical: KSpacing.s14,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      alignLabelWithHint: true,
      helperMaxLines: 2,
      errorMaxLines: 3,
      prefixIconConstraints: const BoxConstraints(
        minWidth: KSize.target,
        minHeight: KSize.target,
      ),
      suffixIconConstraints: const BoxConstraints(
        minWidth: KSize.target,
        minHeight: KSize.target,
      ),
      border: field,
      enabledBorder: field.copyWith(
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: field.copyWith(
        borderSide: BorderSide(color: r.encre, width: KSize.current),
      ),
      errorBorder: field.copyWith(borderSide: BorderSide(color: r.danger)),
      focusedErrorBorder: field.copyWith(
        borderSide: BorderSide(color: r.danger, width: KSize.current),
      ),
      labelStyle: t(KType.libelle, r.texte2),
      floatingLabelStyle: t(KType.libelle, r.encre),
      hintStyle: t(KType.corps, r.texte2),
      helperStyle: t(KType.detail, r.texte2),
      errorStyle: t(KType.detail, r.danger),
      prefixIconColor: r.texte2,
      suffixIconColor: r.texte2,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: r.pleine,
        foregroundColor: r.surPleine,
        disabledBackgroundColor: r.haute,
        disabledForegroundColor: r.texte3,
        minimumSize: const Size(KSize.target, KSize.target),
        iconSize: KSize.iconSmall,
        padding: const EdgeInsets.symmetric(
          horizontal: KSpacing.s20,
          vertical: KSpacing.s12,
        ),
        shape: KRadius.pill,
        textStyle: KType.corpsFort,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: r.haute,
        foregroundColor: r.texte,
        minimumSize: const Size(KSize.target, KSize.target),
        shape: KRadius.pill,
        textStyle: KType.corpsFort,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: r.texte,
        minimumSize: const Size(KSize.target, KSize.target),
        iconSize: KSize.iconSmall,
        padding: const EdgeInsets.symmetric(
          horizontal: KSpacing.s16,
          vertical: KSpacing.s12,
        ),
        side: BorderSide(color: r.filet, width: KSize.current),
        shape: KRadius.pill,
        textStyle: KType.corpsFort,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: r.encre,
        minimumSize: const Size(KSize.target, KSize.target),
        iconSize: KSize.iconSmall,
        shape: KRadius.pill,
        padding: const EdgeInsets.symmetric(
          horizontal: KSpacing.s12,
          vertical: KSpacing.s12,
        ),
        textStyle: KType.libelle,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: r.texte,
        minimumSize: const Size(KSize.target, KSize.target),
        iconSize: KSize.icon,
        shape: KRadius.pill,
        padding: const EdgeInsets.all(KSpacing.s12),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: r.pleine,
      foregroundColor: r.surPleine,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: KRadius.pill,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: KSpacing.s16,
        vertical: KSpacing.s4,
      ),
      minTileHeight: KSize.target,
      iconColor: r.texte,
      textColor: r.texte,
      selectedColor: r.encre,
      selectedTileColor: r.haute,
      titleTextStyle: t(KType.corpsFort, r.texte),
      subtitleTextStyle: t(KType.detail, r.texte2),
      leadingAndTrailingTextStyle: t(KType.detail, r.texte2),
      shape: KRadius.menuShape,
    ),
    expansionTileTheme: ExpansionTileThemeData(
      iconColor: r.texte2,
      collapsedIconColor: r.texte2,
      textColor: r.texte,
      collapsedTextColor: r.texte,
      shape: KRadius.menuShape,
      collapsedShape: KRadius.menuShape,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: r.haute,
      selectedColor: r.pleine,
      secondarySelectedColor: r.pleine,
      disabledColor: r.haute,
      checkmarkColor: r.surPleine,
      deleteIconColor: r.texte2,
      labelStyle: t(KType.libelle, r.texte),
      secondaryLabelStyle: t(KType.libelle, r.surPleine),
      side: BorderSide.none,
      shape: KRadius.pill,
      padding: const EdgeInsets.symmetric(
        horizontal: KSpacing.s8,
        vertical: KSpacing.s4,
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: KSpacing.s4),
      showCheckmark: false,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: r.encre,
      linearTrackColor: r.filet,
      circularTrackColor: r.filet,
      linearMinHeight: KSpacing.s4,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: r.encre,
      inactiveTrackColor: r.filet,
      thumbColor: r.encre,
      overlayColor: r.encre.withValues(alpha: .12),
      valueIndicatorColor: r.pleine,
      valueIndicatorTextStyle: t(KType.libelle, r.surPleine),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: r.texte,
      unselectedLabelColor: r.texte2,
      indicatorColor: r.encre,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
      labelStyle: KType.libelle,
      unselectedLabelStyle: KType.libelle,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled)
            ? r.texte3
            : s.contains(WidgetState.selected)
            ? r.surPleine
            : r.texte2,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? r.pleine : r.haute,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.transparent : r.texte2,
      ),
      trackOutlineWidth: const WidgetStatePropertyAll(2),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(KSpacing.s4)),
      ),
      side: BorderSide(color: r.texte2, width: 2),
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? r.validation : null,
      ),
      checkColor: WidgetStatePropertyAll(r.surValidation),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? r.encre : r.texte2,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size(KSize.target, KSize.target),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: KSpacing.s12, vertical: KSpacing.s8),
        ),
        shape: pill,
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? r.pleine : r.haute,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? r.surPleine : r.texte2,
        ),
        side: const WidgetStatePropertyAll(BorderSide.none),
        textStyle: WidgetStatePropertyAll(KType.libelle),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: r.surface,
      modalBackgroundColor: r.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: r.texte3,
      dragHandleSize: const Size(KSize.handleWidth, KSize.handleHeight),
      shape: const RoundedRectangleBorder(borderRadius: KRadius.sheetRadius),
      elevation: 0,
      modalElevation: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: r.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: KRadius.cardShape,
      titleTextStyle: t(KType.titreSeance, r.texte),
      contentTextStyle: t(KType.corps, r.texte),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: r.texte,
      contentTextStyle: t(KType.libelle, r.fond),
      actionTextColor: r.fond,
      elevation: 0,
      shape: KRadius.menuShape,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: r.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: KRadius.menuRadius,
        side: BorderSide(color: r.filet),
      ),
      textStyle: t(KType.corps, r.texte),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(r.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: KRadius.menuRadius,
            side: BorderSide(color: r.filet),
          ),
        ),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: ShapeDecoration(color: r.texte, shape: KRadius.pill),
      textStyle: t(KType.detail, r.fond),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: r.encre,
      selectionColor: r.encre.withValues(alpha: .3),
      selectionHandleColor: r.encre,
    ),
  );
}
