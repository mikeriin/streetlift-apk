# Sauvegarde UI1 (session session_018ETAYadGCNKByTAfVnsshL)

Lot pris le 2026-10-10 13:42 UTC. Branche de travail `ui/UI1` (depuis refonte-ui 0e5342df).

## Fait
- lib/plan/widgets/program_widgets.dart (showProgramSheet, ProgramDayRow, WhyTile) — à promouvoir par UI5.
- home_screen.dart (en-tête, KSeasonBar + gestes, lignes de jour, carte du jour, ligne « Mon programme », feuilles semaine, ordre des récompenses §4.6 dans openProgramDay).
- program_screens.dart (Mon programme au gabarit de menu, revenir à un programme précédent : feuille d'actions + confirmations), season_view, event_day_screen, evolution_widgets, plan_sheets, program_position, program_explainer, resume_banner, levelup, koach_bubble.
- check_ui_tokens --zone UI1 --menus : 0.

## Fait aussi
- Tests ui1_programme_test / ui1_programme_capture_test ; tests existants adaptés (programme_test, level_fill, l5c_selecteur, ui_refactor, g7_plan, intégration koach_ci1e, programme_g7, tour).
- Analyse verte sauf infos ; contrôle rapide en cours (d2cc4fb).

## En cours / reste
- Contrôle rapide claude/ci-ui-ui1-rapide (compilation, formatage).
- Tests existants à adapter (programme_test, level_fill_test, l5c_selecteur, ui_refactor, g7_plan_test adjust, intégration koach_ci1e, programme_g7, street_ci1).
- Nouveaux tests ui1_* (récompenses, accueil, Mon programme) et captures ui1_*_capture_test.dart.
- Tour : profil avec compétition, Mon programme mesuré sans carte du moment.
- Livraison, ETAT_UI, notification.
