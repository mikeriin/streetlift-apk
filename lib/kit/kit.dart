// Kit de la refonte UI (UI0, cahier §5) : jetons, thème et composants.
//
// Mode d'emploi pour les lots d'écrans (UI1 à UI4) : `pipeline/ui/livraisons/
// LIVRAISON_UI0.md`, section « Mode d'emploi du kit », et LIVRAISON_UI5.md
// (composants promus, formateurs). Un écran importe ce fichier et n'écrit
// aucune valeur de présentation en dur : il passe par un composant, un
// formateur (`format.dart`) ou par `KTokens.of(context)` (contrôle :
// `tools/check_ui_tokens.py --zone UI5`, tout `lib/`).
export 'buttons.dart';
export 'controls.dart';
export 'dock.dart';
export 'format.dart';
export 'menus.dart';
export 'page.dart';
export 'palette.dart'
    show
        KPaletteSource,
        KRoles,
        kPaletteSources,
        kDefaultPaletteId,
        normalizePaletteId,
        paletteSource,
        kContrast,
        kHex;
export 'palette_picker.dart';
export 'program.dart';
export 'search_field.dart';
export 'session.dart';
export 'sheets.dart';
export 'surfaces.dart';
export 'theme.dart';
export 'tokens.dart';
export 'transitions.dart';
