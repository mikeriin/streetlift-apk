# Sauvegarde CA2 (kalis_adapt, voie B, Opus 5.5)

Session lancée le 05/10/2026 18:17 UTC (ligne ETAT_CP « en cours depuis 2026-10-05 18:17 UTC », poussée).
Base : `moteurs` 9526ac47 (kalis_plan 0.2.2, kalis_adapt 0.2.2, kalis_bench 0.2.1). CP2 tourne en parallèle (voie A).

## Fait
- Lecture : PIPELINE_CP, DECISIONS_CP (C7-C9, CA1, CX, CX c1), LANCEMENTS (CA2), LIVRAISON_CA1, CX, CX c1, RELECTURE_DOCUMENTEE_CX, notes de la page (m4 lues ; aucune note `m4_*_pilotage` au 05/10 18:40).
- Pas de SDK Dart dans la session (hôte bloqué) : contrôles par `claude/ci-cp-b`.

## En cours — partie 0 (street, kalis_adapt 0.2.3)
1. Conduite sous douleur : reprise graduée suivie jour par jour (gêne > 2/10, pas revenue à la base, ou en hausse → palier précédent) ; levée jamais en semaine verrouillée ; reprise graduée propre à adapt si l'arrêt se lève au milieu d'un bloc qui écrit les mouvements provocants ; dose d'appui du poignet sans hausse ; tests reportés pendant la reprise.
2. Meilleur maintien récent (pas d'avant l'arrêt) pour le plancher de 55 %.
3. Estimation moins prudente (jamais de baisse sur séries faciles), cran d'assistance sans aller-retour, constats CA1/relecture.

## Reste
- Partie 0 : tests, CI, panel, publication 0.2.3.
- Partie 1 : disciplines non street → 0.3.0.
