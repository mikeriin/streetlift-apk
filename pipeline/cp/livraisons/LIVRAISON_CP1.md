# Livraison CP1 — `kalis_plan` 0.2.0 : le street au niveau d'un coach

Lot moteur du pipeline « Calibrage des programmes » (voie A, Fable 5.1), exécuté du 03/10/2026 20:27 UTC au 04/10/2026.

**État : livré — cible non atteinte.** Le moteur est publié et sûr (0 violation de sécurité sur les 17 profils street), le panel est à 9 sur 66 notes sur 68, mais ni le panel (moyenne 8,97 pour 9,5 visés, deux notes à 8) ni la relecture documentée (moyenne 7,41, minimum 7, pour 9 visés) n'atteignent la cible C7. Le propriétaire m'a délégué le choix de la suite (04/10/2026) : voie A, base acceptée et cible à confirmer (dernière partie).

## 1. Ce qui est livré

| Élément | Valeur |
| --- | --- |
| Paquets | `kalis_plan` 0.2.0, `kalis_bench` 0.1.1, `kalis_core` 0.4.1 |
| Branche | `moteurs`, commit d0d60018 |
| Étiquettes | `etiquettes/kalis_plan-v0.2.0`, `etiquettes/kalis_bench-v0.1.1`, `etiquettes/kalis_core-v0.4.1` |
| Contrôle | `claude/ci-cp-a`, run 37185013127 (mode complet), commit dcb1fdd7 (`packages/` identique à `moteurs` d0d60018) : vert |
| Sauvegardes | `cp-sauvegardes/CP1` |

`kalis_plan` 0.2.0 ajoute un **chemin street** (`lib/src/coach/`) pour les profils au schéma 3 dont la discipline principale est le streetlifting, le sets & reps ou la calisthénie. Les autres profils gardent le chemin 0.1, inchangé.

Ce que le moteur sait faire maintenant, pour ces profils :

- un **plan de saison** calé à rebours sur l'échéance : introduction, construction, intensification, réalisation, allègements, tests, affûtage, semaine de l'épreuve ;
- quatre **styles de programme** : débutant (chemin vers la première traction, échelle de pompes, descentes freinées), sets & reps (série de tête, volume sous-maximal, départs au chrono, répétition de l'épreuve), streetlifting (pourcentages du 1RM en charge totale, série de tête et séries allégées, variantes de point faible, dernier lourd, plan de tentatives), figures (étape actuelle, étape suivante sous condition, dynamique au niveau de l'étape, budget du poignet) ; plus l'hybride avec la course ;
- la **variation dans la semaine** (jours lourd, moyen, léger) et d'une semaine à l'autre ;
- les **repères** : le repère d'un exercice ne monte qu'après un test de cet exercice, jamais sur un progrès supposé ;
- les **garde-fous** : plafonds de volume par groupe et par niveau, hausse de volume et de charge bornée, tenues bras tendus, durée de séance, reprise après coupure (demi-volume puis +10 à 15 % par semaine), zones à ménager, 48 h avant un test de tirage ;
- des **notes de coach** courtes (74 codes, `docs/NOTES_COACH.md`) : pourquoi ce bloc, comment progresser, quoi faire un jour sans, règle de douleur, stratégie de test.

`kalis_bench` 0.1.1 : adaptateur des profils types vers le profil v3 et export lisible enrichi (saison, échelles de figures, règles du programme). Profils types, attentes de coach et grilles du panel **inchangés** (empreintes des cinq grilles revérifiées en fin de lot, identiques à `docs/PANEL.md`).

`kalis_core` 0.4.1 : évolution additive, trois codes de raison pour les notes de coach (`plan.coach_note`, `plan.progression_rule`, `plan.pain_rule`) ; un JSON de 0.4.0 se relit et se réécrit à l'identique.

Documentation : `packages/kalis_plan/CONTRAT.md` § 12 (comportement, tableau de tous les paramètres chiffrés avec leur source, invariants testés) et § 9 (limites connues) ; `docs/NOTES_COACH.md` ; `docs/CALIBRAGE_CP1.md` (journal des 8 passes de notation, recherches ciblées et leurs sources).

## 2. Banc d'essai, avant et après

Profils street (17) :

| Mesure | Moteurs 0.1 (lot CR) | `kalis_plan` 0.2.0 |
| --- | --- | --- |
| Violations de sécurité (programmes créés) | 94 | **0** |
| Attentes de coach tenues | 66 sur 111 | **110 sur 111** |
| Panel, moyenne (minimum) | 4,9 (3,0) | **8,97 (8)** |
| Panel, notes à 9 ou plus | 0 sur 68 | **66 sur 68** |
| Relecture documentée, moyenne (minimum) | 3,9 (3) sur les 8 profils relus en manche 0 | **7,41 (7)** sur les 17 profils |
| Non-ressemblance au programme du propriétaire (seuil 0,30) | 0,000 exact | **0,095** au plus en exercices × schémas (0,250 en exercices seuls) |
| Non-ressemblance aux six références (seuil 0,30) | 0,014 exact, 0,222 tolérant (cinq références et demie) | **0,130 exact, 0,231 tolérant** (les six, en entier) |

La seule attente non tenue : `street_12_antecedent_coude`, « aucun exercice à contrainte forte sur le coude ». Elle contredit l'objectif déclaré du même profil (un 1RM de dips lestés) : le moteur garde le dips lesté, retire la traction lestée, charge le coude par paliers et renvoie au professionnel qui suit la zone. Le profil et l'attente n'ont pas été modifiés.

Profils des autres disciplines (10) : chemin 0.1 inchangé, mêmes chiffres qu'à la mesure de départ (23 violations, qualité et attentes identiques ligne à ligne).

Détail par profil :

| Profil | Panel 0.1 (F / C / H / S) | Panel 0.2.0 (F / C / H / S) | Relecture documentée 0.2.0 | Violations de sécurité 0.1 → 0.2.0 | Attentes de coach 0.1 → 0.2.0 |
| --- | --- | --- | --- | --- | --- |
| `street_01_debutant_complet` | 5,5 / 6,0 / 6,0 / 6,5 | 9 / 9 / 9 / 9 | 8 | 2 → 0 | 5/7 → 7/7 |
| `street_02_debutant_surpoids` | 7,0 / 7,0 / 7,0 / 5,0 | 9 / 9 / 9 / 9 | 8 | 1 → 0 | 6/6 → 6/6 |
| `street_03_debutante` | 4,5 / 5,0 / 4,5 / 5,0 | 9 / 9 / 9 / 9 | 7 | 3 → 0 | 3/5 → 5/5 |
| `street_04_reprise_longue_pause` | 6,5 / 5,0 / 7,0 / 5,0 | 9 / 9 / 9 / 9 | 7 | 5 → 0 | 3/4 → 4/4 |
| `street_05_inter_calisthenie_front_lever` | 4,0 / 5,0 / 5,0 / 4,5 | 9 / 9 / 9 / 9 | 7 | 6 → 0 | 4/6 → 6/6 |
| `street_06_inter_sets_reps` | 4,5 / 5,0 / 7,0 / 4,0 | 9 / 9 / 9 / 9 | 7 | 1 → 0 | 4/6 → 6/6 |
| `street_07_avance_streetlifting_competition` | 3,5 / 4,0 / 4,5 / 4,0 | 9 / 9 / 9 / 9 | 8 | 4 → 0 | 5/10 → 10/10 |
| `street_08_avance_sets_reps_competition` | 4,5 / 3,5 / 5,5 / 4,0 | 9 / 8 / 9 / 9 | 7 | 7 → 0 | 2/8 → 8/8 |
| `street_09_elite_streetlifting` | 4,0 / 5,0 / 6,0 / 4,0 | 9 / 9 / 9 / 9 | 8 | 8 → 0 | 5/10 → 10/10 |
| `street_10_elite_figures` | 5,0 / 4,0 / 6,0 / 4,0 | 9 / 9 / 9 / 9 | 7 | 25 → 0 | 6/7 → 7/7 |
| `street_11_master_51_ans` | 4,0 / 4,5 / 4,5 / 4,0 | 9 / 9 / 9 / 9 | 7 | 7 → 0 | 4/5 → 5/5 |
| `street_12_antecedent_coude` | 4,0 / 3,5 / 4,0 / 4,0 | 9 / 9 / 9 / 9 | 7 | 7 → 0 | 2/6 → 5/6 |
| `street_13_peu_de_temps` | 6,5 / 6,0 / 5,5 / 6,0 | 9 / 9 / 9 / 9 | 8 | 0 → 0 | 5/6 → 6/6 |
| `street_14_parc_sans_lest` | 4,5 / 4,5 / 5,0 / 4,0 | 9 / 8 / 9 / 9 | 7 | 8 → 0 | 3/5 → 5/5 |
| `street_15_travail_physique_sommeil_court` | 4,0 / 3,5 / 6,0 / 4,5 | 9 / 9 / 9 / 9 | 8 | 1 → 0 | 4/6 → 6/6 |
| `street_16_specialisation_traction_lestee` | 3,0 / 3,0 / 5,0 / 3,0 | 9 / 9 / 9 / 9 | 8 | 6 → 0 | 1/8 → 8/8 |
| `street_17_hybride_street_course` | 5,0 / 5,0 / 6,0 / 5,0 | 9 / 9 / 9 / 9 | 7 | 3 → 0 | 4/6 → 6/6 |


Les notes du panel sont celles de la passe complète finale (17 profils × 4 écoles), après renotation des six couples qui avaient reçu une correction nécessaire corrigée ensuite (« la dernière notation fait foi », `docs/PANEL.md`). Les notes de la relecture documentée sont celles de la passe finale sur les 17 profils. Après ces passes, la relecture indépendante du code a entraîné des corrections qui changent de 0 à 4,1 % des lignes des exports selon le profil (sous le seuil de 10 % de `docs/PANEL.md`) : ces exports n'ont pas été renotés.

## 3. Calibrage : huit passes, et pourquoi il s'arrête là

| Passe | Panel, moyenne (min) | Relecture documentée, moyenne (min) |
| --- | --- | --- |
| 0 (premier jet) | 6,89 (4) | 5,76 (4) |
| 1 | 7,76 (5) | 6,47 (5) |
| 2 | 8,38 (7) | 6,94 (6) |
| 3 | 8,68 (7) | 7,29 (6) |
| 4 | 8,84 (8) | 7,29 (7) |
| 5 | 8,79 (7,5) | 7,41 (6) |
| 6 | 8,90 (8) | 7,00 (6) |
| 7 (passe complète) | 8,90 puis 8,97 après renotation (8) | 7,41 (7) |

La règle C7.2 autorise dix boucles et demande d'arrêter après deux boucles sans gain. J'ai arrêté après la septième, sur un plateau net :

- **Relecture documentée** : 7,29 – 7,29 – 7,41 – 7,00 – 7,41 sur les cinq dernières passes. À la passe 6, trois profils dont l'export n'avait pas changé sont passés de 7 à 6 : la dispersion de ce jury (environ un point) est du même ordre que les gains restants.
- **Panel** : 8,84 – 8,79 – 8,90 – 8,97. Dans cette grille, 9 veut dire « aucune correction nécessaire » ; une moyenne de 9,5 demanderait des 10 sur la moitié des couples, et aucun 10 n'a été donné en huit passes (deux 9,5).
- **Demandes contradictoires.** Les deux jurys, et les écoles entre elles, demandent des choses opposées sur les mêmes lignes : volume de tirage du débutant (le réduire à 8–10 séries, ou ajouter des descentes et des tenues), affûtage du débutant (3 à 5 jours, ou −40 à −60 % sur deux semaines), repos-pause (demandé à la passe 4, jugé trop dur à la passe 5), seuil de douleur (3 sur 10 trop permissif pour l'un, trop strict pour l'autre), lest proche du poids du corps (chiffre demandé, puis jugé trop lourd, puis « à calibrer » demandé). Chaque correction pour l'un coûte un point chez l'autre.

Le détail de chaque passe, les notes par école et par profil, les corrections faites et leur effet sont dans `packages/kalis_plan/docs/CALIBRAGE_CP1.md`.

Corrections nécessaires encore ouvertes au panel (les deux couples à 8) :

- `street_08_avance_sets_reps_competition`, calisthenie (8) : Le lundi, soit faire la série de tête de tractions avant le muscle-up (et réduire celui-ci à 2 × 6–8), soit recaler la série de tête sur le maximum en état de fatigue (par exemple 22 puis 24 répétitions au lieu de 24 puis 26 et 28)
- `street_14_parc_sans_lest`, calisthenie (8) : Remplacer le « Handstand dos au mur » (et le repli sur parallettes) par une variante faisable avec le matériel du parc : pike push-up hold ou tenue en appui pieds surélevés sur la barre basse, ou handstand contre un poteau si l'athlète confirme qu'il en a un. Donner aussi un repli poignet sur les barres parallèles.

La première n'est pas suivie : l'ordre muscle-up puis traction est celui de l'épreuve (R4-F1, le geste le plus technique à l'état frais). La seconde est fondée : le catalogue ne déclare pas de matériel « mur » pour l'appui renversé dos au mur, le moteur le croit donc faisable partout (limite notée au contrat § 9).

Ce que la relecture documentée reproche encore le plus souvent (priorité « haute », passe finale) : le temps de séance n'est pas rempli (séances de 20 à 45 min sur 60 à 90 disponibles) alors que le volume spécifique pourrait monter ; les figures manquent de travail dynamique au levier visé et de tenues à plus de 70 % du maximum ; la progression écrite est plate dans un bloc (les séries dures ne montent pas d'une semaine à l'autre) ; les blocs écrits partent du repère attendu au test au lieu d'attendre le résultat réel ; le format exact d'une épreuve de sets & reps n'est pas connu du profil.

## 4. Notes de la page de relecture (manche 0) traitées

La page portait 70 notes de la relecture documentée (C6) sur dix programmes des moteurs 0.1, dont huit profils street (notes d'ensemble 3 à 6). Chaque commentaire a été découpé en points et vérifié sur le programme 0.2.0 du même profil : **106 points, 81 corrigés, 21 corrigés en partie, 4 non corrigés** (`pipeline/cp/livraisons/CP1_M0_TRAITEMENT.md`, point par point avec la preuve).

Non corrigés : back lever en tuck non repris pour `street_05` (le back lever a disparu du programme) ; séances de `street_06` encore à 38–50 min sur 60 ; muscle-up de `street_06` sans négatives ni élastique ; planche complète jamais travaillée pour `street_10` (seule la half-lay, sous condition). Les deux profils des autres disciplines relus en manche 0 ne relèvent pas de ce lot (chemin 0.1 inchangé) : leurs commentaires restent à traiter par le lot qui touchera ces disciplines.

La manche « kalis_plan 0.2 — street (CP1, 04/10/2026) » est ajoutée à la page de relecture avec les 17 profils street ; les notes de la relecture documentée finale y sont écrites (`auteur : relecture-documentee`).

## 5. Contrôles

| Contrôle | Résultat |
| --- | --- |
| `kalis_plan` : formatage, analyse, tests (dont 17 tests du chemin street, 6 tests d'invariants de calibrage, propriétés sur 10 240 profils aléatoires du chemin 0.1 et 10 240 du chemin street) | vert |
| `kalis_bench`, `kalis_core`, `kalis_adapt`, `kalis_quest` | vert |
| Banc : 0 violation de sécurité sur les 17 profils street | tenu |
| Budgets (création ≤ 1 s, régénération ≤ 300 ms), déterminisme | tenus (tests) |
| Relecture indépendante du code (Opus) | 6 constats bloquants, 12 à corriger, 6 mineurs : voir ci-dessous |
| Recontrôle des références non lues par CR (C5.2) | fait : non-ressemblance sous 0,30 ; mesures agrégées conformes sauf deux écarts mineurs |

**Relecture indépendante.** Corrigés dans ce lot : lest proche du poids du corps plus lourd que son étiquette de réserve ; réserve plancher écrite alors que la charge ne la laissait pas (la charge descend maintenant) ; mode prudent sans effet sur l'intensité (plafond 85 %, réserve 2, pas de 1RM en trois tentatives) ; tests placés dans la semaine qui suit une épreuve (semaine de récupération maintenant) ; excentriques dosés en séries de 6 à 8 quand ils servaient de repli au débutant, y compris en surpoids ; charge estimée d'après le maximum au poids du corps plus lourde que sa réserve ; jour léger du streetlifting placé sur un jour de course ; textes qui ne disaient pas ce que fait le code (étape suivante, reprise, série d'entrée). Non corrigés, écrits comme limites au contrat § 9 : échéance placée avant la première séance de sa semaine ; affûtage de deux semaines avec échéance en première semaine du bloc ; 48 h avant un test garanties pour le tirage seulement ; pas de filtre des excentriques sur une zone à antécédent ; plus petit pas de charge ; tenues très courtes ; reprise du volume après trois semaines légères ; restructuration sans historique ; record déclaré à 0 répétition ; variantes hors règles d'admission.

**Recontrôle C5.2.** Les deux parties de références que CR n'avait pas lues en détail (transcrites par la conversation de pilotage) ont été analysées ; l'analyse est ajoutée, chiffrée avec la même clé, sur `cp-references` (`analyse_CP1.tar.gpg`). Indice de Jaccard le plus haut entre un programme street 0.2.0 et une semaine de référence : 0,130 (exact) et 0,231 (tolérant), sous le seuil de 0,30. Mesures agrégées de `docs/MESURES_REFERENCES.md` : conformes, sauf deux fourchettes (un repos publié « 2 à 6 min », recalculé 1 à 6 min ; un lest publié « 0 à +5 kg », recalculé 0 à +10 kg selon le classement d'une station) ; le document n'a pas été modifié, l'écart est consigné ici pour le lot qui le reprendra.

## 6. Écarts et limites de ce lot

- **Recherche web.** Le quota de recherche (WebSearch) de la session s'est épuisé pendant le lot. Les cinq recherches ciblées étaient faites ; les relecteurs documentés ont ensuite lu leurs sources par WebFetch à partir d'une liste d'adresses publiques déjà repérées (`CALIBRAGE_CP1.md`, parties 2 et 5).
- **Clé des références : une faute de ma part.** La clé a été lue dans le document privé du projet claude.ai. Pour chiffrer `analyse_CP1.tar.gpg`, je l'ai passée en clair dans une commande du terminal de la session, au lieu de la lire depuis une variable. Le contrôle d'autorisations de la session a refusé la commande suivante ; je n'ai pas contourné ce refus, j'ai arrêté le lot et prévenu le propriétaire. Vérification faite ensuite sans réécrire la clé : elle n'apparaît dans aucun fichier d'aucune des 37 branches du dépôt, dans aucun diff de l'historique, dans aucun message de commit, dans aucun fichier de travail du lot, et les commandes en cause n'ont jamais tourné dans la CI. Elle n'est donc sortie d'aucun espace privé du propriétaire (document du projet, messages de lancement, transcription de la session). Je n'ai pas fait de rotation : elle toucherait le document de la clé, les quatre archives et les messages de lancement des autres lots, hors du périmètre d'un lot ; la conversation de pilotage peut la faire si le propriétaire la préfère (`DECISIONS_CP.md`, section CP1).
- **Fin de lot en deux temps.** Après cet arrêt, la tâche a été relancée automatiquement ; je n'ai pas pris ce message pour un accord et j'ai attendu la réponse du propriétaire (« Fais ce qui est le plus optimal selon toi », 04/10/2026). La publication a été faite ensuite.
- **Dernières corrections non renotées.** Les corrections issues de la relecture indépendante du code et des tests de propriétés sont postérieures à la dernière notation (partie 2) ; les programmes de la page de relecture sont ceux du moteur livré.
- **Horloge.** L'horloge du conteneur n'a pas avancé de façon fiable : les sauvegardes ont été faites à chaque étape (plus de 30 sur `cp-sauvegardes/CP1`) plutôt qu'à l'heure.
- **Nombre de boucles.** Le prompt du lot dit six boucles au plus, la décision C7.2 dix ; j'ai suivi C7.2 (huit passes de notation).
- **Catalogue.** L'appui renversé dos au mur ne demande aucun matériel dans le catalogue ; la pompe mains surélevées demande un « banc plat » : le moteur passe par la pompe sur les genoux et une note d'échelle. À corriger dans `kalis_core` (hors de ce lot).
- **Profils incohérents.** `street_11` déclare 10 tractions au poids du corps et un 1RM lesté de +15 kg ; les deux ne se recoupent pas (R2-P2). Le moteur prescrit alors la traction lestée « à calibrer » à la première séance.
- Toutes les limites du chemin street sont au contrat § 9.

## 7. Ce qui reste pour CX et les lots suivants

1. Faire monter les séries dures d'une semaine à l'autre dans un bloc quand le temps et les plafonds le permettent, et affecter le temps libre au travail spécifique de l'objectif (première demande de la relecture documentée).
2. Figures : dynamique et excentriques au levier visé, tenues à 75–85 % une séance sur deux, demi-paliers, test de l'objectif en premier.
3. Écrire le bloc suivant à partir du résultat réel du test (aujourd'hui : repère attendu, puis consigne de recalcul).
4. Ajouter au profil le format de l'épreuve de sets & reps (ordre, repos, pauses autorisées), la catégorie de poids et la pesée en streetlifting.
5. Limites du contrat § 9 relevées par la relecture indépendante.
6. `kalis_core` : matériel de l'appui renversé au mur et de la pompe mains surélevées.

## 8. Décision : voie A, par délégation du propriétaire

La cible C7 (chaque note à 9 ou plus, moyenne 9,5 par jury) n'est pas atteinte et ne me paraît pas atteignable par de nouvelles boucles du même type : le panel donne 9 pour « aucune correction nécessaire » et n'a donné aucun 10 en huit passes, et la relecture documentée varie d'un point d'une passe à l'autre sur un programme inchangé.

J'avais présenté trois voies au propriétaire : **A**, accepter 0.2.0 comme base avec une cible mesurable ; **B**, rouvrir un lot CP1 bis ciblé sur les demandes les plus fréquentes de la relecture documentée ; **C**, garder C7 telle quelle et relancer des boucles. Sa réponse (04/10/2026) : « Fais ce qui est le plus optimal selon toi ».

Je retiens la **voie A** (`DECISIONS_CP.md`, section CP1) :

- `kalis_plan` 0.2.0 sert de base du street à CA1 et à CX. Le statut du lot reste « livré — cible non atteinte » : je ne déclare pas C7 atteinte.
- Pas de nouvelles boucles CP1 sur C7 telle quelle.
- Cible proposée pour la suite, **à confirmer par le propriétaire** (C7 reste écrite telle quelle tant qu'il ne l'a pas changée) : panel à 9 partout ; relecture documentée à 8 de moyenne et 7 au minimum, deux relecteurs indépendants par profil ; 0 violation de sécurité.
- Les points de la partie 7 vont à CX, dans cet ordre.

Ce choix se renverse sans rien défaire : la voie B ou C repart de `moteurs` d0d60018 et des sauvegardes `cp-sauvegardes/CP1`.
