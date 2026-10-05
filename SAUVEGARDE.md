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

## Avancement 05/10 ~19:45 UTC
- Code partie 0 écrit (non compilé localement) : `lib/src/pain_return.dart` (reprise graduée : palier qui recule si la douleur répond, arrêt gardé sur semaine non chargée, reprise propre au moteur après une levée en milieu de bloc, part 1RM 67,5 % + 2,5 %/palier), session.dart (tests jamais sur zone douloureuse ni en reprise, appui du poignet sensible = dose écrite au plus), coach.dart (doseCapped/inReturn, maintien récent `recentBestOf`, élastique : 2 séances au même cran, montée seulement après échec / 2 séances sous la plage / >2 rép.), advise/coach_advice (verrous en séance), truth.dart (zone réactive après un épisode, modèles B et C : poussées `painFlares`), kalis_bench season (colonne Douleur « hausses / poussées »).
- kalis_adapt 0.2.3 (version.dart, pubspec). Tests ajoutés : coach_rules_test (levée, maintien récent, street_12 coude, street_01 élastique).
- Contrôle dev poussé sur claude/ci-cp-b (commit 55d74554) : outil aa_fmt, graines 4, sans kalis_quest. Script : ci.sh (scratchpad, voir commit).

## Avancement 05/10 ~19:50 UTC
- Contrôle dev 2 (6afd314b, run 37361856152) : kalis_adapt vert, kalis_bench vert, format OK. Hausses sur zone douloureuse : 0 partout (avant : 0,49 pour street_12 scénarios douleur — tests faits sur zone douloureuse).
- Ajouts boucle 1 ter : gain d'affûtage 2 % des tentatives (Travis 2020), CONTRAT § 11.16, CHANGELOG 0.2.3 ; contrôle dev 3 poussé (b02991c6).
- Dérive du panel (ancres p08_a, p14_c) : (a) 1/1/1/1, (c) 9/8/8/8 → pas de dérive. Empreintes des grilles identiques.
- Recherches : sources vérifiées (Silbernagel 2007 via source secondaire, Soligard 2016, ACSM 2009, Travis 2020/2021, Darragh 2025, Halperin 2022, Bosquet 2013 résumé, NSW ACI 2022, Nielsen 2014, Buist 2008, Wang 2023).
- Suite : passe panel complète (17 saisons street, contrôle dev 3), relecture documentée, relecture du code, contrôle full, publication 0.2.3.

## Avancement 05/10 ~20:40 UTC
- Panel passe 1 (13 profils sur dev 2 : 01-06, 08, 10, 11, 13-15, 17) : 11 couples sur 52 à 9 ; corrections nécessaires presque toutes sur le programme écrit (kalis_plan) ; côté adapt : cadence de l'élastique (01), poussée à prise neutre sur poignet douloureux (01, 03). Notes : ca2-outils/notes/p1, p1_corr.md.
- Boucle 2 : cran d'élastique 14 jours au moins (coachAssistMinDays), substitution prise neutre (poignet), relecture indépendante du code (16 constats, corrigés : levée datée sans compteur courant, substitution poignet seule et qui n'en provoque aucune autre, appui neutre sous 6/10, part la plus basse, arrondi vers le bas, conseil du poignet, zone réactive (tolérance qui ne baisse pas, séries des mouvements provocants), taperedAt avant le bloc, gain d'affûtage avant la 1re tentative, semaine de levée comptée à moitié, contrat).
- Contrôle dev 5 poussé (remplace dev 4).
- Reste partie 0 : panel 07, 09, 12, 16 + renote des profils changés (01, 03, 10…) sur dev 5, relecture documentée (7 saisons), contrôle full, publication 0.2.3 (moteurs, étiquette, DECISIONS, ETAT, page de relecture manche 5, notification).
