# Livraison CA2 — `kalis_adapt` 0.3.0 (toutes disciplines) et 0.2.3 (street)

Lot CA2 du pipeline « Calibrage des programmes » (voie B, Opus 5.5 effort maximal, C5.1). Sessions du 05/10 (18:17-23:10 UTC), du 06/10 (14:50-16:15 UTC, arrêtées sur la limite du plan) et du 08/10 (reprise depuis `cp-sauvegardes/CA2`, 13:05 UTC →). Délégation totale (C8) : recommandation en fin de document, le pilotage décide.

## 1. Ce qui est livré

| Paquet | Version | Étiquette (branche fixe) | Commit `moteurs` | Contrôle complet |
| --- | --- | --- | --- | --- |
| `kalis_adapt` | 0.2.3 (partie 0, street) | `etiquettes/kalis_adapt-v0.2.3` | ff22faa9 | run 37796701628 |
| `kalis_bench` | 0.2.2 (partie 0) | `etiquettes/kalis_bench-v0.2.2` | ff22faa9 | run 37796701628 |
| `kalis_core` | 0.4.3 (commit séparé, additif : 5 codes de raison) | `etiquettes/kalis_core-v0.4.3` | @CORE@ | @RUN@ |
| `kalis_adapt` | 0.3.0 (partie 1) | `etiquettes/kalis_adapt-v0.3.0` | @MAIN@ | @RUN@ |
| `kalis_bench` | 0.2.3 (partie 1) | `etiquettes/kalis_bench-v0.2.3` | @MAIN@ | @RUN@ |

`kalis_plan` n'est pas touché (CP2, voie A). Couple jugé : `kalis_plan` 0.2.2, dernière étiquette publiée pendant tout le lot.

### Partie 0 — street (0.2.3, publiée le 08/10 à 16:20 UTC)

- **Conduite sous douleur (sécurité, C9.8)** : reprise graduée suivie séance par séance (palier qui recule quand la douleur répond, dose écrite jamais dépassée, jamais de levée sur une semaine non chargée) ; douleur pendant l'effort jamais à 5/10 (allègement dès 4/10) ; pendant un arrêt, mouvements à contrainte moyenne au premier palier, retirés après 14 jours si la douleur reste à 3/10 ; **poignet** : charge externe d'appui retirée, remplaçant d'une poussée limité aux parallettes, et tant que la gêne de la semaine atteint 3/10 seuls les appuis sur parallettes à contrainte moyenne restent, échauffement compris ; aucun test tant que la zone dépasse 2/10 dans la semaine ; renvoi vers un professionnel une fois puis chaque semaine ; +10 % par séance au plus sur une zone récente.
- **Maintien récent** (pas un record d'avant l'arrêt), **estimation moins prudente** (séries lourdes lues avec le biais appris ; série arrêtée sous la cible prise comme borne jusqu'à une deuxième mesure), **élastique** (deux séances au même cran, sept jours au moins, montée après un manque réel), **gain d'affûtage** de 2 % avant la première barre.
- **Relecture indépendante du code** (Opus, 08/10) : 12 constats, tous corrigés et testés — dont l'arrêt qui tombait au premier signalement plus bas, l'étape de figure et le test reporté qui échappaient aux règles de douleur, le plafond de 67,5-70 % du 1RM absent sur un remplaçant.

### Partie 1 — autres disciplines (0.3.0)

- **Course** : sortie du jour bornée à la plus longue course des 30 jours + 10 % (Frandsen et al. 2025, BJSM, 5 205 coureurs ; la règle des 10 % par semaine n'a pas d'effet protecteur, Buist et al. 2008) ; test de course plus long que la borne servi en course bornée ; jour sans (bilan bas, douleur du bas du corps à 3/10, course récente trop dure) : séance de qualité servie en course facile ou retirée (Kiviniemi 2007, Vesterinen 2016, Javaloyes 2019) ; bilan très bas : durée à 70 % ; reprise après 7 jours sans séance à 70 %, après 14 jours à 50 %.
- **Conditionnement** : pièce mise à l'échelle (75 %) un jour sans ou après deux jours durs de suite (Tibana 2016 : marqueurs inflammatoires en hausse à 48 h).
- **Hybrides** : fatigue croisée (course dure la veille → une répétition de réserve de plus sur le bas du corps ; Wilson 2012, Robineau 2016) ; course et conditionnement comptés dans le modèle forme-fatigue ; l'ordre écrit des séances est gardé.
- **Force, musculation** : le mode coach de 0.2 s'applique à tout bloc au contrat 0.4.0, quelle que soit la discipline (choix par le contenu du bloc, pas par la discipline) : il s'exercera dès que `kalis_plan` 0.3.0 écrira ces blocs.
- **Street** : élastique — une séance entière dite au moins 2 répétitions plus facile que visé, ou une série repère qui dépasse l'écrit de 2 répétitions, fait passer à l'élastique plus fin (sept jours au moins) ; la série repère ne remet plus la série de séances à zéro.
- **Jamais au-dessus de l'écrit** (durée, distance, répétitions, séries, effort, allure) : invariants E1 à E3 vérifiés à chaque séance des simulations et des 10 240 journaux aléatoires de chaque suite de propriétés (profils de course, de cardio et hybrides ajoutés).
- **Simulateur** : vérité d'endurance (course : capacité de durée et risque de surcharge selon Frandsen ; conditionnement : forme après des jours durs, risque d'épaule ou de dos ; deux modèles par discipline), indépendante du moteur.
- **`kalis_core` 0.4.3** (commit séparé) : `adapt.run_capped`, `adapt.easy_instead`, `adapt.endurance_shortened`, `adapt.wod_scaled`, `adapt.cross_fatigue` ; textes courts de Koach (`docs/RAISONS_0_4.md`).

## 2. Banc avant / après

**Street, saisons croisées** (`kalis_bench` 0.2.2, 17 profils × 8 scénarios × 3 modèles de vérité × 100 graines ; contrôles complets c4df7413 → d9029a47) : violations de sécurité du programme réalisé 0,0126 → 0,0124 par saison ; **0 violation sur les 136 saisons racontées** ; poussées d'une zone réactive (somme des moyennes) 26,7 → 24,9 ; hausses sur zone douloureuse 0,02 à 0,05 par saison, seulement `street_10` modèle B (douleur de surcharge signalée pendant la séance), inchangé ; meilleure barre du jour de l'échéance 94,7 % du maximum réel, tentatives réussies 93,1 % (inchangés) ; écart d'effort 1,064 → 1,110 répétition (plus de séances retirées ou bornées par la conduite sous douleur). Avant la partie 0 (CX correction 1 → boucle 3) : échéance 94,4 → 95,0 %, échecs non voulus 0,21 → 0,23 %, hausses sur zone douloureuse dans les scénarios de douleur de `street_12` 0,49 → 0.

**Endurance** (`test/endurance_campaign_test.dart`, 4 athlètes × 16 semaines × 3 modèles × 20 graines, programmes de `kalis_plan` 0.2.2) :

| Athlète | Politique | Surcharges / 100 saisons | Pic moyen (× plus longue des 30 j) | Course faite (min / sem.) |
| --- | --- | --- | --- | --- |
| course débutante | 0.3.0 / 0.2 / règle des 10 % | 5,0 / 5,0 / 8,3 | 1,04 / 1,03 / 1,34 | 57 / 59 / 35 |
| semi-marathon | 0.3.0 / 0.2 / règle des 10 % | 10,0 / 13,3 / 13,3 | 1,10 / 1,55 / 1,59 | 138 / 149 / 80 |
| CrossFit | 0.3.0 / 0.2 / règle des 10 % | 30,0 / 35,0 / 35,0 | — | — |
| hybride 50/50 | 0.3.0 / 0.2 / règle des 10 % | 18,3 / 20,0 / 18,3 | 1,10 / 1,39 / 1,27 | 51 / 55 / 27 |

0.3.0 borne la plus grande sortie en gardant 93 % du temps de course ; blessures de surcharge simulées −14 % par rapport à 0.2 (taux de base : choix raisonnés, seuls les écarts se lisent). La règle des 10 % par semaine coupe 41 à 51 % du temps de course sans borner les pics.

**Mode 0.1** : les profils non street suivent toujours le chemin 0.1 de `kalis_plan` ; leurs lignes de musculation sont conduites comme en 0.2 (campagne de `docs/MESURES.md` : mêmes écarts au RIR visé). Temps de calcul (`docs/MESURES.md`) : décision de séance 0,16 ms (médiane), 10,6 ms au 99ᵉ centile (≤ 50 ms) ; conseil après une série 0,07 ms (médiane), 0,16 ms au 99ᵉ centile, maximum 3,4 à 5,1 ms selon les passes (pause du ramasse-miettes ; cible 5 ms).

## 3. Panel

### Street (68 couples) — partie 0 et fin de lot

| Mesure | CX correction 1 (manche 4) | Partie 0 (0.2.3) | Fin de lot (0.3.0) |
| --- | --- | --- | --- |
| Couples à 9 sur 68 | 23 | 19 | 19 |
| Minimum | 5,5 | 5 | 5 |
| Moyenne | 7,95 | 7,76 | 7,76 |

Par profil (force / calisthénie / hypertrophie / santé), dernière notation : `street_01` 7,5/8/7/6,5 ; `02` 8/8/8/9 ; `03` 7/7/6/5,5 ; `04` 9/9/8/9 ; `05` 7/8/6,5/8 ; `06` 9/8/7/8 ; `07` 8/8/8/8 ; `08` 6/7/7/8 ; `09` 7/8/8/8 ; `10` 7/5/7/6,5 ; `11` 7/7/8/7 ; `12` 9/9/9/9 ; `13` 7,5/7/6,5/7 ; `14` 8/8/9/9 ; `15` 9/9/9/9 ; `16` 9/9/9/9 ; `17` 7/6,5/7/8. Détail, passes 1 à 6 et q2 : `packages/kalis_adapt/docs/CALIBRAGE_CA2.md`. Écart avec la manche 4 dans l'incertitude d'un point du panel, avec des notes plus sévères sur la conduite du poignet (choix de sécurité assumé, ci-dessous). Les corrections nécessaires restantes visent presque toutes le programme écrit (CP2). Grilles inchangées (empreintes SHA-256 vérifiées), dérive du panel vérifiée au départ (ancres `p08_a` 1/1/1/1, `p14_c` 9/8/8/8).

### Autres disciplines (40 couples) — passe q1 (moteur de la boucle 1)

| Profil | Force | Calisthénie | Hypertrophie | Santé | Couple 0.1 (CR, moyenne) |
| --- | --- | --- | --- | --- | --- |
| `autres_01` débutant musculation | 7 | 7 | 7 | 7 | 6,8 |
| `autres_02` hypertrophie | 6,5 | 6 | 6,5 | 6 | 6,5 |
| `autres_03` powerlifter | 3,5 | 4 | 5 | 4 | 3,8 |
| `autres_04` force 46 ans | 5,5 | 6 | 6 | 6 | 4,6 |
| `autres_05` 10 km débutante | 4,5 | 3 | 3 | 4 | 4,1 |
| `autres_06` semi-marathon | 4,5 | 3,5 | 4 | 4,5 | 3,4 |
| `autres_07` mobilité senior | 5,5 | 6 | 5 | 5 | 5,2 |
| `autres_08` CrossFit | 5 | 6,5 | 7 | 6 | 5,2 |
| `autres_09` perte de poids | 5 | 7 | 6,5 | 5 | 5,8 |
| `autres_10` contraintes multiples | 5 | 8 | 5 | 5 | 5,5 |

40 couples, aucun à 9, minimum 3, moyenne 5,41 (couple 0.1 : ≈ 5,1). **Cible C7.5 non atteinte.** Les corrections nécessaires portent presque toutes sur le programme écrit par le chemin 0.1 de `kalis_plan` 0.2.2 : course d'échéance non placée et sans affûtage, tests sur la distance de la course (semi couru à fond en semaines 5 et 10), aucune allure, pas de séance spécifique, double progression absente en musculation, tirage non budgété en CrossFit, objectifs non commentés. Côté conduite, une demande (trois écoles) : les tests de course trop longs → traités (test borné).

## 4. Relecture documentée (C7.3, sans seuil)

Trois sous-agents Opus, sources web seulement, exports du moteur livré ; notes sur la page (manche 5, `relecture-documentee`) :

| Profil | Ensemble | Côté conduite (résumé) |
| --- | --- | --- |
| `street_01` | 5 | élastique jamais changé → corrigé ; poussée à l'arrêt longtemps sans variante neutre (choix de sécurité) |
| `street_03` | 4 | élastique et échelle de poussée bloqués → élastique corrigé ; échelle : programme écrit |
| `street_06` | 6 | dips servis 12-12-12 au lieu de 22 trois semaines après un mauvais jour (non traité) |
| `street_07` | 7 | estimation du muscle-up trop basse, jour J à 88,5 % (non traité) |
| `street_08` | 6 | dips à environ 18 RIR en S10-11 (sous-dosage, non traité) |
| `street_10` | 5 | arrêt de la planche bien appliqué ; reprise affichée à 10 % au lieu de 50 % (programme écrit) |
| `street_12` | 7 | 3ᵉ barre prudente ; état du coude non suivi (programme) |
| `autres_05` course 10 km | 4 | borne appliquée sans réajuster le plan ; pas de passage en course-marche (non traité) |
| `autres_06` semi | 3 | qualité servie facile en cas de douleur, épreuve bornée ; stimulus trop faible (efforts notés 1/10) |
| `autres_08` CrossFit | 4 | épaulé-jeté figé, RIR réels au-dessus des cibles sans hausse (mode 0.1) |
| `autres_02` hypertrophie | 4 | aucune surcharge progressive en 12 semaines (mode 0.1, non traité) |

Le reste vise le programme écrit.

## 5. Page de relecture

Page de relecture : 504 notes lues au départ (manches 0 à 4) ; aucune note du propriétaire ; rien de nouveau depuis la manche 4. **Manche 5 publiée** (08/10, « kalis_adapt 0.3.0 — conduite street et autres disciplines ») : 7 saisons street et 4 trajectoires d'autres disciplines, 77 notes de la relecture documentée. Le fichier de la page dans le dépôt (`kalis_bench/tool/relecture/relecture-kalis-track.html`) est recopié de la version en ligne (il datait de CR) ; `build_manche_saisons.py` lit aussi les trajectoires des autres disciplines.

## 6. Limites

1. **Cible C7.5 non atteinte** : street 19/68 à 9 (minimum 5), autres disciplines 0/40 (minimum 3). Les corrections nécessaires restantes visent surtout le programme écrit (CP2).
2. **Conduite non traitée** (relecture documentée de la partie 1) : surcharge progressive en mode 0.1 (musculation des profils non street : charges figées malgré 4-6 répétitions de réserve réelles) ; sous-dosage persistant après un mauvais jour (`street_06`, `street_08`) ; estimation du muscle-up trop basse le jour J (`street_07`) ; passage en course-marche après des sorties répétées inachevées. Les deux premiers se régleront en grande partie quand `kalis_plan` 0.3.0 écrira des blocs au contrat 0.4.0 (mode coach) pour ces disciplines.
3. **Choix de sécurité contesté par une école** : tant que la gêne du poignet atteint 3/10, la contrainte forte (planche, HSPU) est retirée même sur parallettes ; l'école calisthénie demande 50 % sur parallettes (`street_10`).
4. **Remplaçant de poussée pendant un arrêt du poignet** : seulement des appuis sur parallettes ; plusieurs relecteurs demandent aussi les barres parallèles ou les poings (le catalogue classe les pompes sur poings en contrainte forte et les dips en contrainte moyenne avec extension du poignet) : à trancher par le pilotage.
5. **Moteur sans modèle de capacité d'endurance** : pas d'allure critique ni de prédiction de temps ; les allures viennent du programme écrit.
6. **Simulateur** : taux de base des blessures de surcharge et capacités d'endurance par niveau = choix raisonnés ; seuls les écarts entre politiques se lisent.
7. **Panel des autres disciplines** mesuré sur le moteur de la boucle 1 (les deux changements de la boucle 2 ne changent les exports de course que de 1 à 2 %).
8. **Budget** : une seule passe complète du panel par périmètre (C10.3) ; street renoté seulement là où l'export a changé.

## 7. Recommandation (C8.1 : le pilotage décide)

1. **Valider 0.3.0** (`kalis_adapt` 0.3.0, `kalis_core` 0.4.3, `kalis_bench` 0.2.3) comme base de CY et de la mise à jour de l'application (CI1d peut prendre 0.3.0 au lieu de 0.2.3 : contrats additifs, mode 0.1 et street inchangés ou meilleurs, sécurité à 0 partout, conduite de l'endurance bornée et testée).
2. **Ne pas ouvrir de correction de CA2 avant CP2** : le plafond des notes des autres disciplines tient au programme écrit ; mesurer de nouveau au croisement final (CY) avec `kalis_plan` 0.3.0.
3. **Pour CY** (ou une correction courte de CA2 après CP2) : surcharge progressive des blocs de musculation, sous-dosage après un mauvais jour, estimation du muscle-up le jour J, course-marche pour le débutant qui n'achève pas ses sorties.
4. **Décision du pilotage** sur le remplaçant de poussée pendant un arrêt du poignet (parallettes seulement, ou aussi barres parallèles et poings) et sur la planche sur parallettes à 3/10.
