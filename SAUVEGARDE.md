# Sauvegarde UI0 (session session_01DfhZd3fMyMGSUKefFeRLGk)

Base : main b7996b3f. Branche de travail locale : refonte-ui.

## Fait
- Prise du lot (ETAT_UI.md, 09:48 UTC).
- Polices Barlow (assets/fonts, OFL, EMPREINTES.sha256).
- lib/kit/palette.dart (dérivation HCT, vérifiée en JS contre palettes_roles.json : 0 écart), tokens.dart, theme.dart, transitions.dart (ressorts).
- app_theme.dart en adaptateur (KAccentSpec 8 palettes, alias rouge→bordeaux…).
- tools/check_ui_tokens.py.

## En cours / reste
- composants du kit, ui.dart, nav_bar.dart (dock), store.dart (préférence accent + contraste), sélecteur, tests, ci-ui.yml, tour, livraison.
