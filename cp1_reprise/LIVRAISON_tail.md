
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

@RESTES@

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
- **Clé des références.** Lue dans le document privé du projet claude.ai, utilisée seulement en mémoire pour déchiffrer et rechiffrer ; elle n'est écrite nulle part.
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

## 8. Décision demandée au propriétaire

La cible C7 (chaque note à 9 ou plus, moyenne 9,5 par jury) n'est pas atteinte et ne me paraît pas atteignable par de nouvelles boucles du même type : le panel plafonne à 9 par construction de sa grille, et la relecture documentée varie d'un point d'une passe à l'autre sur un programme inchangé.

Trois voies, de la plus prudente à la plus coûteuse :

- **A (recommandée).** Accepter `kalis_plan` 0.2.0 comme base : 0 violation, panel à 9 sur 66 couples sur 68. Fixer pour la suite une cible mesurable avec ces jurys : panel « aucune correction nécessaire » partout (9 partout), relecture documentée à 8 de moyenne et 7 au minimum, notée par deux relecteurs indépendants par profil pour lisser la dispersion. Traiter les points de la partie 7 dans CX.
- **B.** Rouvrir un lot CP1 bis ciblé sur les quatre demandes « haute » les plus fréquentes de la relecture documentée (partie 7, points 1 à 3), avec la cible de la voie A.
- **C.** Garder la cible C7 telle quelle et relancer des boucles : je ne le recommande pas, pour les raisons de la partie 3.
