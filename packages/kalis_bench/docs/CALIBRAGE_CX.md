# Calibrage du croisement street (lot CX)

Lot CX du pipeline « Calibrage des programmes » : `kalis_plan` 0.2 écrit le plan de saison et chaque bloc,
`kalis_adapt` 0.2 conduit chaque séance d'un athlète simulé, les résumés d'adaptation et les résultats de test
nourrissent le bloc suivant (saisons croisées, `lib/src/season.dart`). Le panel note les **saisons** : le
programme tel que les blocs successifs l'ont écrit (export concis), puis la saison simulée (décisions du
moteur, tests, jour de l'échéance ; modèle de vérité B, graine 0, saison de référence). Cible (C7.5) : 9 au
moins pour chaque école et chaque profil street, 0 violation de sécurité.

## Avant la première boucle

- Empreintes des cinq grilles : identiques à `docs/PANEL.md` (concaténation `7d337a2e…`).
- Dérive du panel (ancres `p06_a` et `p17_c`, un appel Opus par école) : variante (a) 1 / 1 / 1 / 1, variante
  (c) 9 / 9 / 9 / 8 → pas de dérive.

## Passe 0 (complète, 68 couples) — moteurs livrés (`kalis_plan` 0.2.0, `kalis_adapt` 0.2.0)

Contrôle `claude/ci-cp-a` run 37222464508 (banc des saisons, moteurs inchangés).

| Profil | Force | Calisthénie | Hypertrophie | Santé |
| --- | --- | --- | --- | --- |
| `street_01_debutant_complet` | 6 | 6 | 5,5 | 6,5 |
| `street_02_debutant_surpoids` | 8 | 7 | 7 | 8 |
| `street_03_debutante` | 4,5 | 5 | 4,5 | 5 |
| `street_04_reprise_longue_pause` | 8 | 7 | 7 | 8 |
| `street_05_inter_calisthenie_front_lever` | 7 | 6 | 7 | 7 |
| `street_06_inter_sets_reps` | 7 | 6,5 | 7,5 | 6,5 |
| `street_07_avance_streetlifting_competition` | 8 | 7 | 8 | 8 |
| `street_08_avance_sets_reps_competition` | 6,5 | 6,5 | 6,5 | 6 |
| `street_09_elite_streetlifting` | 7 | 6,5 | 7 | 6,5 |
| `street_10_elite_figures` | 6,5 | 6 | 6 | 6 |
| `street_11_master_51_ans` | 7,5 | 7 | 7,5 | 7,5 |
| `street_12_antecedent_coude` | 8 | 8 | 7,5 | 8 |
| `street_13_peu_de_temps` | 7,5 | 7 | 7 | 7 |
| `street_14_parc_sans_lest` | 7,5 | 7 | 7,5 | 7 |
| `street_15_travail_physique_sommeil_court` | 7 | 8 | 8 | 8 |
| `street_16_specialisation_traction_lestee` | 8 | 8 | 9 | 8 |
| `street_17_hybride_street_course` | 7 | 7 | 8 | 7 |

Couples à 9 ou plus : 1 sur 68 ; minimum 4,5 ; moyenne 7,01. Les saisons sont notées plus sévèrement que les
programmes seuls (CP1 : 66 sur 68) et que les trajectoires d'un seul cycle (CA1 : 34 sur 68) : elles
montrent ce que le moteur de création fait des résultats réels.

Corrections nécessaires de la passe 0, lues en entier (`cx-outils/notes/p0.json` sur la sauvegarde), par
famille et par nombre de couples concernés :

1. **Blocs écrits sur le repère attendu, pas sur le test** (presque tous les profils, toutes écoles) : séries de
   tête au-dessus du maximum mesuré (27 dips pour 22, 18 tractions pour 14, tenues de 9 s pour un maximum de
   7 s), 1RM déclarés jamais recalés vers le bas (dips +90 kg déclarés, environ +78 kg réels).
2. **Charge du coude** : tirage cinq jours sur cinq ou deux jours de suite (street_06, 07, 08, 09, 14, 17).
3. **Après l'échéance** : pas de transition, reprise à pleine charge la semaine suivante (street_07, 08, 09, 16).
4. **Figures** : critère de passage hors de portée (3 × 12 s pour un maximum de 12 à 13 s), étape actuelle
   retirée au profit de l'étape suivante (street_10), pas de dynamique ni de tirage de force (street_05).
5. **Débutants** : élastique jamais affiné, négatives à dose fixe, pompe sur les genoux trop facile ou simples
   de pompe classique, test de descente rendu en répétitions (street_01, 02, 03).
6. **Douleur** : poignet à 4 sur 10 plusieurs semaines, bloc suivant qui passe à une variante plus dure
   (street_04), partielles surchargées au-dessus du 1RM sur un coude à antécédent (street_09).
7. **Divers** : séries de volume de traction lestée trop faciles (street_16), règle « réductions déjà
   appliquées » contradictoire avec la baisse du jour (street_10).
