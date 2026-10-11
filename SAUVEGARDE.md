# Sauvegarde UI5 (session session_014wA1B8bKecW5barqcLhDf9)

Branche de travail locale `ui/UI5` (partie de `refonte-ui` 48bda98, fusion de main dev6.11.2 faite en avance rapide et poussée).

## Fait
- Kit (U0.16) : KTopBar.sub sans AppBar (titre jamais coupé, 2/3 lignes, barre qui suit), KLead aligné sur la racine, KSwitchRow (interrupteur sous le libellé), KStepperRow seuil 420, KSegmented 48 dp et keyPrefix, KStepper keyPrefix, KIconButton désactivé sans fond, KNotice/KEmpty clés, champs : KFieldBorder (étiquette dans la pilule, neutre).
- Feuille de contenu unique KContentSheet/showKContentSheet ; KConfirm = confirmation unique (contenu qui défile, clés), showKChoice ; showKListSheet(initial:).
- Promus : KDayRow (ex ProgramDayRow), KWhyTile, KSessionHeader, KProgressDots, KBottomInset, KMeter, KStatTile, KTileGrid, KActionRow, KScaffold, KPageList. Fichiers de zone supprimés (program_widgets, session_kit, k_info_sheet), ui.dart supprimé, app_theme réduit aux rôles des illustrations, métriques historiques retirées.
- Agents : textes R3/R5/R9 + toUpperCase (jetons UI5 = 0), formats C9 (lib/kit/format.dart, virgule, au moins n min, espace fine), API openTab + états vides Stats, test d'installation.
- tools/check_ui_illustrations.py + relevé + test Python ; test/ui5_kit_test.dart ; tour parties e (320 dp × 200 %) et f (palettes, contraste).

## En cours
- Contrôle complet 1 sur claude/ci-ui-ui5 (arbre e129b1b, avant format et seuil du dock) ; cahier §5.2 corrigé dans un worktree pipeline local (non poussé).

## Reste
- Contrôle rapide puis complet (claude/ci-ui-ui5), correction format/analyse/tests ; captures regardées ; relecture indépendante ; cahier §5.2 (U0.17) ; REFONTE_UI.md ; version 6.12.0+116 ; main ; livraison.

## Point 07:30 UTC
- Relecture indépendante faite (verdict : publiable après corrections mineures) ; constats 2, 3, 4, 5, 6, 13 corrigés ; 1, 7, 8 expliqués (livraison §6, §8).
- main a avancé (dev6.11.3, e351f274) : fusionné (cb03625), version 6.12.0+117.
- Contrôle complet 3 : run 38121521174 (arbre cb03625).
- Brouillon de livraison : /tmp (non sauvegardé ailleurs) — à réécrire depuis ce plan si besoin : sections 1 à 9 du gabarit PIPELINE_UI §4.
- Worktree pipeline local : cahier §5.2 et DECISIONS UI5 écrits, non poussés.
- Reste : vérifier le run, captures, publier main (avance rapide depuis e351f274), build signé, livraison, ETAT, notification.

## 2026-10-11 11:13 UTC
Publié : refonte-ui et main = caf5589 (ff depuis e351f27). Reste : vérifier build signé sur main, livraison, ETAT_UI, notification.

## 2026-10-11 11:29 UTC
LIVRÉ : main caf5589 (build signé 38134737676 vert), pipeline 241ce9a (livraison, ETAT livré), projet claude.ai claude/LIVRAISON_UI5.md.
