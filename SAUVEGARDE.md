# Sauvegarde UI5 (session session_014wA1B8bKecW5barqcLhDf9)

Branche de travail locale `ui/UI5` (partie de `refonte-ui` 48bda98, fusion de main dev6.11.2 faite en avance rapide et poussée).

## Fait
- Kit (U0.16) : KTopBar.sub sans AppBar (titre jamais coupé, 2/3 lignes, barre qui suit), KLead aligné sur la racine, KSwitchRow (interrupteur sous le libellé), KStepperRow seuil 420, KSegmented 48 dp et keyPrefix, KStepper keyPrefix, KIconButton désactivé sans fond, KNotice/KEmpty clés, champs : KFieldBorder (étiquette dans la pilule, neutre).
- Feuille de contenu unique KContentSheet/showKContentSheet ; KConfirm = confirmation unique (contenu qui défile, clés), showKChoice ; showKListSheet(initial:).
- Promus : KDayRow (ex ProgramDayRow), KWhyTile, KSessionHeader, KProgressDots, KBottomInset, KMeter, KStatTile, KTileGrid, KActionRow, KScaffold, KPageList. Fichiers de zone supprimés (program_widgets, session_kit, k_info_sheet), ui.dart supprimé, app_theme réduit aux rôles des illustrations, métriques historiques retirées.
- Agents : textes R3/R5/R9 + toUpperCase (jetons UI5 = 0), formats C9 (lib/kit/format.dart, virgule, au moins n min, espace fine), API openTab + états vides Stats, test d'installation.
- tools/check_ui_illustrations.py + relevé + test Python ; test/ui5_kit_test.dart ; tour parties e (320 dp × 200 %) et f (palettes, contraste).

## Reste
- Contrôle rapide puis complet (claude/ci-ui-ui5), correction format/analyse/tests ; captures regardées ; relecture indépendante ; cahier §5.2 (U0.17) ; REFONTE_UI.md ; version 6.12.0+116 ; main ; livraison.
