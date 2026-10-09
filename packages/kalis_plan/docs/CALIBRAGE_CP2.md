# Calibrage CP2 — journal

Lot CP2 du pipeline « Calibrage des programmes » (`pipeline/cp/prompts/CP2.txt`, `LANCEMENTS.md`, section CP2). Partie 0 : finir le street (`kalis_plan` 0.2.3). Partie 1 : les autres disciplines (`kalis_plan` 0.3.0). Panel : protocole et grilles gelées de `packages/kalis_bench/docs/PANEL.md` (empreintes SHA-256 revérifiées au début de chaque session : identiques). Sous-agents sur Opus 5.5. Cible C7.5 : note d'ensemble ≥ 9 pour chaque école et chaque profil, 0 violation de sécurité ; au plus 5 boucles, arrêt après une boucle sans gain (C9.2).

## Partie 0 — street (0.2.3)

### Sessions

Trois sessions (05/10 18:14 – 22:20 UTC, 06/10 14:49 – 16:10 UTC, 08/10 16:05 UTC –), arrêtées deux fois sur la limite du plan ; reprises depuis `cp-sauvegardes/CP2` et la branche de contrôle `claude/ci-cp-a`.

### Boucles

Saisons croisées du banc (`kalis_bench` 0.2.1, mode croisement, `kalis_adapt` 0.2.2 : dernière étiquette publiée de `kalis_adapt` pendant toute la partie 0), 17 profils street × 4 écoles = 68 couples. Fichier noté : programme réalisé par les blocs (export concis) puis la saison racontée.

| Passe | Code (contrôle) | Couples renotés | Couples à 9 | Minimum | Moyenne |
| --- | --- | --- | --- | --- | --- |
| départ (panel final de CX correction 1, 0.2.2) | 9526ac47 | 68 | 23 | 5,5 | 7,95 |
| p1 (boucle 1) | 6fd64980 | 68 | 14 | 5 | 7,58 |
| p2 (boucle 2) | 36939513 | 54 | 27 | 6 | 8,01 |
| p3 (boucle 3) | f44ada83 | 56 | 15 | 4 | 7,64 |

Les boucles de code 3 à 5 (constats de sécurité C9.8 compris) n'ont été notées qu'une fois, à la passe p3 : la session du 06/10 s'est arrêtée avant sa passe. **La passe p3 n'apporte aucun gain** (couples à 9 et minimum en baisse) : arrêt du calibrage de la partie 0 (C9.2). Couples non renotés en p3 : `street_04` et `street_11` (export identique à p2, 0 % de lignes changées), `street_12` (6 %, sous le seuil de 10 % de `PANEL.md`) : leurs notes de p2 sont reprises.

Lecture : l'incertitude du panel est d'environ un point (CR.4, C9) ; la baisse de p2 à p3 tient en partie au bruit (un relecteur a donné 7,5 aux quatre programmes de son appel) et en partie à des choix de sécurité que le panel pénalise : `street_10` (calisthénie 4) — appui du poignet en extension réduit de moitié dès la semaine 1 pour une gêne déclarée (constat C9.8 (v)), d'où un volume de planche que l'école juge trop faible ; le panel demande de reporter ce volume sur un levier plus facile, ce qui reste à faire.

### Constats de sécurité C9.7 et C9.8 (vérifiés sur les exports de f44ada83)

| Constat | Attendu | Vérification |
| --- | --- | --- |
| C9.7 (a), C9.8 (v) `street_10` | gêne du poignet déclarée : appui en extension réduit d'emblée, parallettes, règle de douleur dès S1, renforcement | figures en appui sans prise neutre ×0,5 dès S1 (note `wrist_spare`) : 7 tenues de planche par semaine au lieu de 20, handstand et HSPU sur parallettes, une seule grosse séance d'appui ; règle de douleur écrite dès S1 ; pressions des doigts, rotations, étirement des fléchisseurs. Traité. |
| C9.7 (e) `street_08` | sauts de charge lestée bornés en charge et en tonnage | référence = dernière semaine de charge ; ±2 répétitions d'écart au plus hors pic ; tonnage par exercice lesté +15 % au plus. Banc : 0 hausse de plus de 10 % faite de plusieurs crans. Traité. |
| C9.7, C9.8 (i) `street_12` | reprise des dips après douleur du coude : paliers, jamais d'affûtage ni de test, +10 %/semaine | bloc « reprise progressive » (note `pain_reprise`) sans affûtage, test ni épreuve, échéance repoussée, +10 % par semaine au plus dans le bloc ; coude gêné : +2,5 kg par semaine. Scénario `douleur_coude` : dips 2 × 2 → 2 × 3 → 4 × 4 → 2 × 8, aucun test sur les dips. Traité. Limite : la hausse est bornée à l'intérieur d'un bloc ; la première semaine d'un bloc suivant n'est bornée que par la reprise graduée exercice par exercice. |
| C9.8 (ii) `street_01` | après une douleur au poignet, retirer les mouvements provocants, variante poignet neutre | zone signalée sur trois séances au bloc précédent → « sensible » (2/10) au bloc suivant : wrist push-ups de l'échauffement retirés, pompe écrite poings fermés, poignées ou parallettes (bloc 3). Traité. |
| C9.8 (iii) `street_07` | blocs écrits sur le 1RM estimé, pas sur un 1RM déclaré plus haut | un 1RM seulement déclaré nettement au-dessus de l'estimation de fin de bloc est remplacé par elle (baisse de 15 % au plus) ; dips lestés : charges écrites des blocs 2 et 3 sous le maximum réel. Traité. Reste (non sécurité, `kalis_adapt`) : tentatives du jour J prudentes. |
| C9.8 (iv) `street_08` | plafond de volume dès le premier bloc ; muscle-up arrêté avant la casse | première semaine du premier bloc : répétitions par mouvement ≤ 4 × maximum (dips ≈ 187 au lieu de 352) ; consigne d'arrêt du muscle-up à la première transition qui ralentit. Traité. |

Banc : 0 violation de sécurité sur les 17 saisons street et leurs 7 scénarios (`saisons/SECURITE.md`).

### Paramètres nouveaux de 0.2.3

| Paramètre | Valeur | Source |
| --- | --- | --- |
| Hausse du volume d'une semaine à l'autre dans un bloc de reprise | +10 % au plus, de 75 à 100 % | Soligard et al. 2016 (consensus du CIO sur la charge) ; retour au sport par étapes (Ardern et al. 2016) ; choix raisonné pour la valeur exacte |
| Répétitions par mouvement au poids du corps, première semaine du premier bloc | ≤ 4 × maximum | choix raisonné : bas des séances de densité (250 à 400 % du maximum par séance, deux séances) ; ensuite `coachVolumeRise` |
| Charge lestée, coude gêné | +2,5 kg par semaine (5 en pic) | plus petit pas de charge ; R5-P20 (paliers de reprise) ; choix raisonné |
| Tonnage d'un exercice lesté d'une semaine à l'autre | +15 % au plus | même borne que la hausse de volume de CP1 (`coachVolumeRise`, R3) |
| Appui du poignet en extension, gêne déclarée | ×0,5 | constat C9.8 (v) ; choix raisonné (aucune publication ne fixe la part) |
| 1RM déclaré remplacé par l'estimation | baisse de 15 % au plus (`coachEstimateDropShare` 0,85) | CX correction 1 ; choix raisonné |

## Partie 1 — autres disciplines (0.3.0)

### Mesure de départ

Les dix profils « autres » du banc passaient par le chemin 0.1 (inchangé depuis CP1) : mesure de départ = `packages/kalis_bench/docs/BASELINE_0_1.md` (23 violations de sécurité sur ces profils). Le panel a été étalonné sur deux ancres hors street avant la première boucle (CR.6 : force athlétique experte 9,5/9/9/9, course mauvaise 0/0,5/0/0 ; `cp2-outils/notes/ancres_autres`).

### Contrôles et invariants

Propriétés « autres disciplines » : 10 240 profils aléatoires (`test/coach_general_properties_*_test.dart`, `randomGeneralProfile`) : relecture `coachAudit` (durée des séances, plafonds et hausses de volume par groupe, réserve, charges, tests), sortie longue ≤ 110 % de la plus longue des quatre semaines d'avant (ou de la course connue + 25 %), pas de squat ni de soulevé de terre ≥ 85 % la veille ou le jour d'une course dure (interférence). Premier contrôle de la partie 1 : 64 fichiers de propriétés en échec ; après les corrections : 0.

### Boucles du panel (10 profils × 4 écoles = 40 couples)

| Passe | Code (contrôle) | Couples renotés | Couples à 9 | Minimum | Moyenne |
| --- | --- | --- | --- | --- | --- |
| a1 (départ du chemin coach) | run 37852402019 | 40 | 4 | 3,5 | 6,15 |
| a2 (boucle 1) | run 37856208345 | 36 | 6 | 5 | 7,15 |
| a3 (boucle 2) | run 37862085855 | 34 | 8 | 5 | 7,61 |
| a4 (boucle 3) | run 37865081103 | 16 | 13 | 5,5 | 7,88 |

(Couples dont l'export n'a pas changé : note de la passe d'avant reprise ; le panel varie d'environ un point sur un programme inchangé.)

### Sources vérifiées des règles chiffrées (sous-agent de recherche, 09/10/2026)

| Règle | Verdict | Source |
| --- | --- | --- |
| Affûtage : volume −41 à 60 % sur 2 semaines, intensité gardée | confirmé | Bosquet, Montpetit, Arvisais, Mujika, *Med Sci Sports Exerc* 2007;39:1358-65 |
| Séance de course ≤ 110 % de la plus longue des 30 jours | confirmé | Frandsen et al., *Br J Sports Med* 2025;59:1203-1210 |
| +10 % par semaine | nuancé : plafond de confort, non validé (Buist et al. 2008 ; Nielsen et al. 2014) ; le garde-fou bloquant est celui par séance | — |
| ≈ 80 % du volume à basse intensité | confirmé (descriptif) | Seiler 2010 ; Stöggl & Sperlich 2014, 2015 |
| Senior : équilibre et force fonctionnelle ≥ 3 j/sem ; −24 % de chutes | confirmé | OMS 2020 (Bull et al., *BJSM* 2020) ; Sherrington et al., Cochrane 2019 |
| 150 à 300 min/sem d'activité modérée | confirmé | OMS 2020 |
| ≥ 10 séries par muscle et par semaine | nuancé (tendance, p = 0,074) | Schoenfeld, Ogborn, Krieger, *J Sports Sci* 2017 |
| Spécialisation +30 à 50 % de séries | pratique de terrain, choix raisonné | rendements décroissants : Pelland et al., *Sports Med* 2026 |
| Reprise ≤ 10 %/sem | nuancé (sportifs sains) | Soligard et al., *BJSM* 2016 ; Ardern et al., *BJSM* 2016 (continuum, sans pourcentage) |
| Conditionnement : rhabdomyolyse, progression, mise à l'échelle | confirmé | Bergeron et al., *Curr Sports Med Rep* 2011 (consensus CHAMP-ACSM) |
