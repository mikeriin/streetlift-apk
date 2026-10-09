# Livraison CY — croisement final `kalis_plan` 0.3 ↔ `kalis_adapt` 0.3, toutes disciplines

Lot moteur CY (voie A, tâche Opus moteurs, Opus 5.5 ; C5.1). Session du 09/10/2026, 06:00 à 13:30 UTC (lancement sans
ligne « Lot : » : CY était le seul lot moteur « à faire »). Prompt `pipeline/cp/prompts/CY.txt`, `LANCEMENTS.md` section
CY, DECISIONS_CP.md C7.5, C8, C9.2, C10, C11. **Cible C7.5 non atteinte** ; à valider par la conversation de pilotage
(C8.1). Journal détaillé : `packages/kalis_bench/docs/CALIBRAGE_CY.md`.

## 1. Ce qui est livré

| Paquet | Version | Étiquette | Commit `moteurs` | Contrôle complet |
| --- | --- | --- | --- | --- |
| `kalis_plan` | **0.3.1** | `etiquettes/kalis_plan-v0.3.1` | aacbe054 | run 37922562342 (`claude/ci-cp-a`) |
| `kalis_adapt` | **0.3.1** | `etiquettes/kalis_adapt-v0.3.1` | aacbe054 | même run |
| `kalis_bench` | **0.3.0** | `etiquettes/kalis_bench-v0.3.0` | aacbe054 | même run |

Base : `moteurs` 1ca7475f (CP2 : `kalis_plan` 0.3.0, `kalis_bench` 0.2.4 ; CA2 : `kalis_adapt` 0.3.0, `kalis_core`
0.4.3). `kalis_core` inchangé. Contrats additifs (notes de coach, paramètres, un argument du constructeur) ; JSON
0.3.0 relu sans changement.

Publication intermédiaire de la partie 0 : non faite séparément. La partie 0 a été codée en premier (contrôles
37894110383 et 37897459037), mais le premier contrôle vert complet est arrivé avec la boucle 1 ; la partie 0 est livrée
avec le reste, dans la même version. **Écart au prompt (publication intermédiaire « dès qu'elle est faite »)**, consigné
ici.

## 2. Partie 0 — sécurité

Constats C10.10 (relecture documentée de CP2) et de CA2, tous traités et vérifiés sur les exports (tableau détaillé :
CALIBRAGE_CY § 2) :

- **Poignet** (`street_01`, `street_03`) : première gêne (3/10 dans les 14 jours, avant l'arrêt) → poussée paume à plat
  remplacée tout de suite par un appui neutre faisable (parallettes, poignées, pompe mains serrées sur une barre
  basse) ; pendant l'arrêt, C10.8 (a) entière.
- **Dips lestés de `street_12`** (+17,9 % d'une séance à l'autre) : charge totale bornée quand le schéma change au même
  emplacement (+2,5 % par répétition de moins, 4 au plus, aucune part en plus sur une zone à antécédent).
- **Avis médical avant la semaine 1** (`autres_10`) : note de bloc `clearance_first` (questionnaire prudent ou gêne
  déclarée ≥ 5/10), à montrer comme une étape à confirmer avant la première séance ; **épaule opérée** : note
  `shoulder_history` sur le développé au-dessus de la tête (pas de développé sans douleur ni feu vert).
- **Sortie longue bornée** (`autres_05`) : règle appliquée (+10 % sur la plus longue des quatre dernières semaines,
  Frandsen 2025) ; le texte dit maintenant ce que le moteur fait. **Récupération après une course** (`autres_06`) :
  aucun footing le lendemain, sortie longue repartie à 70 % puis +10 % par semaine.
- Et : couloir plafonné à l'écrit à 85 % du 1RM ou plus (`street_07`), pas de test maximal sur une articulation
  douloureuse (`street_10`), pas de tirage après un test de tirage (`street_08`), premier muscle-up testé sur une
  répétition propre (`autres_08`).
- **Conduite (CA2)** : sous-dosage après un mauvais jour (le jour bas ne devient plus le repère d'un jour bas suivant).
  Non traités (conduite, sans risque) : estimation du muscle-up du jour J, course-marche après des sorties inachevées
  (§ 7).

## 3. Croisement final

- **Banc 0.3.0** : saisons croisées des 27 profils (17 street, 10 autres), 10 scénarios imposés dont deux nouveaux —
  changement de discipline principale à mi-saison (22 profils) et course de 10 km ajoutée à un street hybride
  (`street_17`) — 240 saisons racontées ; 100 graines par modèle de vérité (trois modèles) au contrôle complet.
- **Sécurité calculable : 0 violation** sur les 27 programmes créés et les 240 saisons racontées (graine 0, programme tel
  qu'il a évolué) ; sur 100 graines × 3 modèles, voir la colonne « violations » ci-dessous.
- **Comparaison des couples** (saison de référence, moyenne des profils street, 100 graines, modèle B) :

| Modèle de vérité | Couple | Écart d'effort (RIR) | Échecs non voulus | Progression / sem. | Échéance (part du max du jour) | Violations du programme réalisé / saison |
| --- | --- | --- | --- | --- | --- | --- |
| A | 0.1 | 1,09 | 0,53 % | 0,32 % | — | 8,38 |
| A | 0.2 (CX c1) | 0,77 | 0,21 % | 0,34 % | 95,6 % | 0,002 |
| A | **0.3.1** | 0,76 | 0,22 % | 0,34 % | 96,1 % | 0,002 |
| B | 0.1 | 2,10 | 0,10 % | 0,26 % | — | 8,75 |
| B | 0.2 (CX c1) | 0,90 | 0,16 % | 0,31 % | 93,6 % | 0,002 |
| B | **0.3.1** | 0,87 | 0,15 % | 0,32 % | 94,3 % | 0,007 |
| C | 0.1 | 1,44 | 1,06 % | 0,07 % | — | 9,35 |
| C | 0.2 (CX c1) | 1,43 | 0,61 % | 0,11 % | 92,8 % | 0,015 |
| C | **0.3.1** | 1,51 | 0,62 % | 0,11 % | 93,7 % | 0,011 |

Saison de référence, 17 profils street (les seuls que les couples 0.1 et 0.2 savent conduire sur une saison), 100 graines
par modèle ; couple 0.2 : campagne de CX correction 1 (`kalis_bench` 0.2.1), mêmes graines. 0.3.1 sur les 27 profils :
violations 0,0015 (A), 0,0041 (B), 0,0067 (C) par saison. Hausses sur une zone douloureuse (modèle B, somme des profils
street) : 0.1 0,18, 0.2 0,04, 0.3.1 0,01. Lecture : 0.3.1 tient le niveau de 0.2 sur l'effort, les échecs et la
progression, gagne 0,5 à 0,9 point à l'échéance et réduit les hausses sur zone douloureuse ; les violations résiduelles
du programme réalisé (moins d'une saison sur cent) sont du même ordre qu'en 0.2 (CA2.5 : 0,012 par saison) ; leur cause
graine par graine n'a pas été analysée dans CY.

- **Boucles** (C9.2) : trois. Boucle 1 : variantes faciles hors du plafond de répétitions, tirage assisté du débutant,
  archer et typewriter au plateau. Boucle 2 : double progression « 2 pour 2 », plafond des propositions de volume, sortie
  longue après une course, remplissage du créneau à 80 %. Boucle 3 : un retrait sous arrêt n'est plus compté comme
  « sauté » (régression de `autres_06` vue au panel). Arrêt après la boucle 3 (pas de gain, les corrections restantes
  sont de méthode).

## 4. Panel (4 écoles, grilles gelées, empreintes vérifiées ; dérive vérifiée)

| Passe | Street (68 couples) | Autres disciplines (40 couples, saisons) |
| --- | --- | --- |
| Départ (fin de CP2) | 19 à 9, min 5, moy 7,71 | — (CP2 notait les programmes écrits : 15/40) |
| p1 (complète) | 19, min 5, moy 7,85 | 2, min 5,5, moy 7,41 |
| p2 (boucle 2) | 22, min 5, moy 7,71 | 4, min 5,5, moy 7,30 |
| p3 (sécurité, relecture du code ; 13 couples) | 22, min 5, moy 7,73 | 3, min 2 (`autres_06`), moy 6,71 |
| **Final** (p4 : `autres_06`, 4 écoles) | **22, min 5, moy 7,73** | **3, min 5,5, moy 7,21** |

Règle d'économie (PIPELINE §9) : renotés les couples sous 9 dont l'export a changé de plus de 2 % et tous les couples
d'un export changé de plus de 10 %. Changements de 0,2 à 1,6 % (`autres_02`, `autres_05`, `street_07`, `street_08`,
`street_09`, `street_17`) et changements de couples à 9 sous 10 % (`street_12` 7,3 %, `street_16` 5,5 %) : non renotés,
notes de p2 gardées. Les autres disciplines sont notées sur leurs saisons (la conduite y apparaît), plus sévèrement que
leurs programmes écrits en CP2. Corrections nécessaires restantes : méthode (estimation des capacités par le moteur
d'évolution, spécialisation, allure de course construite, progression des figures), aucune de sécurité.

## 5. Relecture documentée (C7.3, C7.6 ; sans seuil) et relecture indépendante du code

- Trois relecteurs Opus, sources web : street 6, 5, 6, 7, 6, 7, 6, 7, 5 (moyenne 6,1 ; manche 8 : 5,9) ; autres
  disciplines 5, 3, 5, 4, 4, 6, 6, 4, 5, 6 (moyenne 4,8 ; manche 7, programmes écrits : 6,3). Notes écrites sur la page
  de relecture (manche 9, auteur « relecture-documentee », 125 notes).
- Constats de sécurité traités (CALIBRAGE_CY § 4) : poignet servi en pompe pendant l'arrêt (retour à C10.8 (a)), dips
  lestés de `street_12`, course sous une douleur de cheville à 4/10 (course retirée tant que l'arrêt tient, puis
  reprise à 50 %), cran de +25 % en « 2 pour 2 » (cran de 10 % au plus), hausses de 40 % sur l'épaule opérée.
  Restent en limites : 1RM déclarés non vérifiés au premier bloc (`street_07`, `street_09`), dips partiels au-delà du
  1RM complet (`street_09`), échec au squat à 81 % d'un 1RM déclaré surestimé (`autres_08`).
- Relecture indépendante du code (sous-agent Opus) : 14 constats, tous traités — conditions de la règle « 2 pour 2 »,
  charge repère lestée, plafond de volume sur toutes les semaines modifiées, remplissage du créneau (lignes réduites
  pour douleur, groupes, reprise longue), plafond de répétitions d'un mouvement nouveau, retrait du tirage un jour de
  test après les tests de l'échéance, test à une répétition réservé au muscle-up, `shoulder_history` hors tendance,
  course sous douleur réservée au mode coach et reprise graduée, textes et journaux.

## 6. Contrôle final

- **Contrôle complet** run 37922562342 (`claude/ci-cp-a`, 100 graines, saisons des 27 profils) : vert — cinq paquets (`kalis_quest` compris) et outils Python ; arbre identique au commit publié hors Markdown (`CALIBRAGE_CY.md`, `INTEGRATION_CI.md` de `kalis_adapt`).
- **Invariants et budgets** : tests de propriétés de `kalis_plan` (chemins street et autres) et de `kalis_adapt`
  (invariants d'endurance E1-E3, campagne) verts ; budgets de temps des tests tenus.
- **Déterminisme** : mêmes exports au contrôle de mise au point et au contrôle complet (graine 0, même arbre).
- **JSON** : contrats additifs ; un programme et un résumé 0.3.0 relus sans changement (tests de compatibilité verts).
- **Programme du propriétaire** : `kalis_adapt/docs/PROPRIETAIRE.md` régénéré identique à 0.3.0 (seule la ligne de
  version change) — même conduite sur le programme importé (`restructureImported` faux par défaut).
- **Non-ressemblance** : 27 programmes et 27 saisons, maximum exact 0,231, tolérant 0,250 (seuil 0,30) ; détail chiffré
  dans `analyse_CY.tar.gpg` (`cp-references`). Clé lue d'un fichier `/tmp` en mode 600 (`--passphrase-file`), supprimé
  après usage avec les références déchiffrées.

## 7. C11 — branches « bloc importé » de `kalis_adapt`

- Recensement : une seule exclusion par la nature « importé », `BlockView.imported` (bloc de plus de six semaines) —
  restructurations proposées par `review` et niveau de déblocage compté par tranches de six semaines. Le reste
  (couloir, marques d'emplacement, conduite sous douleur, tests reportés, épreuve) dépend des champs du contrat 0.4.0
  (`blockCoached`), pas d'une branche « importé ».
- Rendu réglable sans changer le défaut : `KalisAdapt(restructureImported: true)` (défaut `false`), testé
  (`coach_rules_test`). Depuis CI1e (dev6.10.0), le programme du propriétaire est converti en blocs de six semaines au
  plus, annotés au contrat 0.4.0 : le mode coach s'y applique sans l'option.

## 8. Notes d'intégration

`packages/kalis_plan/docs/INTEGRATION_CI.md` et `packages/kalis_adapt/docs/INTEGRATION_CI.md` : ce qui change de 0.2.3
à 0.3.1, quoi afficher, journaliser et minuter pour chaque prescription nouvelle, codes de raison et de note, migration
des programmes en cours, deux points imposés (`clearance_first` montrée avant la première séance comme une étape à
confirmer ; pompe remplacée pour le poignet affichée « mains serrées sur la barre basse, poignets droits »), points non
déterminés.

## 9. Page de relecture

Manche 9 « toutes disciplines (CY, 09/10/2026) » : les 27 saisons, chacune avec un scénario imposé (changement de
discipline pour 22 profils, course ajoutée pour `street_17`) ; en tête, le tableau de l'évolution des notes du panel et
de la relecture documentée depuis la manche 0. Aucune note du propriétaire dans les manches 0 à 8.

## 10. Limites

1. Cible C7.5 non atteinte : street 22/68 à 9, autres 3/40, minimum 5.
2. Le moteur d'évolution sous-estime les capacités des athlètes qui notent mal (presse à la moitié du réel, tentatives
   du jour J à 88-93 % du maximum) ; la règle « 2 pour 2 » ne corrige que les séries notées.
3. 1RM déclarés écrits tels quels au premier bloc (série repère écrite, pourcentage inchangé).
4. Méthode des autres disciplines : allure de course construite vers l'échéance, renforcement du coureur, spécialisation
   d'un muscle, progression du muscle-up en CrossFit, course-marche du débutant.
5. Volume du débutant : panel et relecture documentée demandent des sens contraires ; choix gardé (R5-P1).
6. Écart de publication : `CALIBRAGE_CY.md`, les notes d'intégration et cette livraison ont été complétés après le
   contrôle complet (Markdown non lus par les tests) ; le reste du commit est l'arbre du contrôle.

## 11. Recommandation (C8 : le pilotage décide)

1. Valider `kalis_plan` 0.3.1 et `kalis_adapt` 0.3.1 comme couple de l'application (lot CI suivant) : 0 violation de
   sécurité sur 240 saisons, constats de sécurité de C10.10, de CA2 et de la relecture documentée de CY traités,
   programme du propriétaire inchangé, panel street au moins au niveau de CP2 (22 contre 19 couples à 9).
2. Ne pas relancer de calibrage sur la cible C7.5 telle quelle avec ces jurys : trois boucles, gains d'un à trois
   couples, incertitude d'un point ; les corrections restantes demandent un lot de méthode (estimation des capacités,
   allure de course, figures), à créer par le propriétaire s'il le souhaite.
3. Dans l'application : afficher `clearance_first` avant la première séance et la consigne de la pompe sur barre basse
   (notes d'intégration § 5).
