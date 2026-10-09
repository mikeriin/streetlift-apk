# Livraison CP2 — `kalis_plan` 0.3.0 : fin du street et autres disciplines

Lot moteur CP2 (voie A, tâche Opus moteurs, Opus 5.5, effort maximal ; C5.1). Sessions : 05/10, 06/10, 08/10 et 08-09/10 (reprises depuis `cp-sauvegardes/CP2` après la limite du plan). Prompt `pipeline/cp/prompts/CP2.txt`, `LANCEMENTS.md` section CP2, DECISIONS_CP.md C7.5, C7.6, C8, C9, C10. **Cible C7.5 non atteinte** ; à valider par la conversation de pilotage (C8.1).

## 1. Ce qui est livré

| Paquet | Version | Étiquette | Commit `moteurs` | Contrôle |
| --- | --- | --- | --- | --- |
| `kalis_plan` (partie 0, publiée le 08/10) | 0.2.3 | `etiquettes/kalis_plan-v0.2.3` | 9b2e9ea3 | run 37820965364 |
| `kalis_plan` (partie 1) | **0.3.0** | `etiquettes/kalis_plan-v0.3.0` | 1ca7475f | run 37882215421 (`claude/ci-cp-a`) |
| `kalis_bench` | **0.2.4** | `etiquettes/kalis_bench-v0.2.4` | 1ca7475f | même run |

Base : `moteurs` 9f931fbf (`kalis_core` 0.4.3, `kalis_adapt` 0.3.0, `kalis_bench` 0.2.3 de CA2). `kalis_core` et `kalis_adapt` inchangés.

### Partie 0 — street (0.2.3, déjà publiée, CP2.1)

Constats de sécurité C9.7 et C9.8 traités et vérifiés sur les exports (poignet de `street_10`, reprise des dips de `street_12`, poignet de `street_01`, 1RM déclarés de `street_07`, volume de départ de `street_08`, sauts de charge lestée) ; relecture indépendante du code (12 constats, 10 corrigés). Détail : `packages/kalis_plan/docs/CALIBRAGE_CP2.md`, partie 0.

### Partie 1 — autres disciplines (0.3.0)

Les dix profils « autres » passaient encore par le chemin 0.1 (inchangé depuis CP1, 23 violations de sécurité au banc). 0.3.0 les fait passer par le chemin coach (`coachEligible` accepte toutes les disciplines), avec un squelette par style (`lib/src/coach/general.dart`) :

- **Musculation et hypertrophie** : groupe prioritaire à 4 séries, mouvements principaux gardés, spécialisation d'un muscle faible (+30 à 50 % de séries, choix raisonné ; rendements décroissants, Pelland 2026), vrais allègements (≤ 60 % du volume) à la place des semaines de test, charges d'accessoires calculées sur répétitions + réserve.
- **Force et force athlétique** : soulevé de terre en volume si le dos est limité ; épreuve et tests seulement sur les mouvements entraînés ; affûtage −41 à 60 % de volume (Bosquet 2007).
- **Santé et senior** : équilibre chaque jour, jambes gardées, genou ≥ 3/10 → chaise contre le mur, presse horizontale, pont ; repos ≤ 75 s ; consignes « squat sur chaise », appui de sécurité, amplitude réduite du genou, progression de l'équilibre (OMS 2020 ; Sherrington 2019).
- **Conditionnement (CrossFit)** : WOD mis à l'échelle du créneau (tours via les séries, plancher de réserve), bloc de force seulement à partir de 40 min, profil prudent → santé ; jours de muscle-up : dips (barre droite ou parallèles) et échauffement scapulaire, traction retirée des WOD (Bergeron 2011, consensus CHAMP-ACSM).
- **Course** : sortie longue ≤ 110 % de la plus longue des 30 jours (Frandsen 2025) ou de la course connue ; ≈ 80 % à basse intensité (Seiler 2010) ; jour de qualité du débutant = footing complet ; allure cible sur le premier jour de qualité ; course d'épreuve sur la première séance de course de la semaine, test de mi-parcours borné par le créneau ; affûtage 3 répétitions de qualité ; 12 min réservées à la course les jours de force ; interférence : ni squat ni soulevé de terre ≥ 85 % la veille ou le jour d'une course dure.
- **Échauffements et versions courtes** par famille (course, salle, santé) : nouveaux codes de note additifs (`warmup_run`, `warmup_gym`, `warmup_health`, `short_run`, `short_health`, `wod_pace`, `chair_squat`, `knee_shallow`, `balance_progress`, `hold_support`) et leurs textes.
- **Banc** (`kalis_bench` 0.2.4) : adaptateur de spécialisation (vocabulaire des muscles), critère « séance trop longue » qui exempte le contre-la-montre du jour d'épreuve, codes d'échauffement exportés.
- **Tests** : propriétés « autres disciplines » sur 10 240 profils aléatoires (`test/coach_general_properties_*_test.dart`) ; tous les tests de `kalis_plan` (302) et des autres paquets verts.

Changements qui touchent aussi le street (CHANGELOG 0.3.0) : garde de `nextBlock`, durée des séances d'épreuve, textes d'échauffement par famille ; le street a été renoté en entier (partie 3).

## 2. Banc

| Mesure | 0.1 (BASELINE_0_1) | 0.2.3 | 0.3.0 |
| --- | --- | --- | --- |
| Violations de sécurité, 10 profils autres | 23 | 23 (chemin 0.1) | **0** |
| Violations de sécurité, 17 profils street (programmes et 136 saisons) | — | 0 | **0** |

## 3. Panel (4 écoles, grilles gelées de `PANEL.md`, empreintes vérifiées)

### Street (68 couples, saisons croisées)

| Passe | Couples à 9 | Minimum | Moyenne |
| --- | --- | --- | --- |
| départ (CX correction 1, 0.2.2) | 23 | 5,5 | 7,95 |
| fin de partie 0 (0.2.3) | 14 | 5 | 7,62 |
| **finale 0.3.0** (`kalis_adapt` 0.3.0) | **19** | **5** | **7,71** |

Street non dégradé par la partie 1 (exigence de `LANCEMENTS.md`). Couples les plus bas (force / calisthénie / hypertrophie / santé) : `street_10` 5,5/5,5/5/6, `street_03` 6,5/6,5/5/7, `street_05` 6,5/7/7/7, `street_11` 6,5/6,5/6,5/7,5, `street_13` 6,5/7/7/7,5. À 9 partout : `street_16`.

### Autres disciplines (40 couples, programmes écrits)

| Passe | Couples à 9 | Minimum | Moyenne |
| --- | --- | --- | --- |
| a1 (départ du chemin coach) | 4 | 3,5 | 6,15 |
| a2 (boucle 1) | 6 | 5 | 7,15 |
| a3 (boucle 2) | 8 | 5 | 7,61 |
| a4 (boucle 3) | 13 | 5,5 | 7,88 |
| **fa (boucle 4, passe finale complète)** | **15** | **5** | **7,92** |

| Profil | Force | Calisthénie | Hypertrophie | Santé |
| --- | --- | --- | --- | --- |
| `autres_01_debutant_musculation` | 9 | 8 | 9 | 9 |
| `autres_02_hypertrophie_intermediaire` | 7 | 7 | 7 | 7 |
| `autres_03_powerlifter_competition` | 9 | 8 | 9 | 9 |
| `autres_04_force_generale_46_ans` | 7 | 6 | 6,5 | 8 |
| `autres_05_course_10_km_debutante` | 9 | 7,5 | 8 | 8 |
| `autres_06_semi_marathon_intermediaire` | 8 | 8 | 9 | 8 |
| `autres_07_mobilite_sante_senior` | 9 | 9 | 9 | 9 |
| `autres_08_crossfit_intermediaire` | 5 | 5,5 | 7 | 6,5 |
| `autres_09_perte_de_poids_debutante` | 9 | 8 | 9 | 9 |
| `autres_10_contraintes_multiples` | 8 | 8 | 8 | 7 |

Quatre boucles de code, gain à chaque boucle ; arrêt après la boucle 4 sur le budget d'utilisation (C9.2 : 5 au plus). La passe fa mesure la boucle 4.

## 4. Relecture documentée (C7.3, C7.6 ; sans seuil)

Trois relecteurs Opus distincts (street débutants, intermédiaires et contraintes ; street avancés et élite ; autres disciplines), qui n'ont reçu que les exports (profil, programme, saison simulée pour le street) et des sources web ouvertes par eux-mêmes (ACSM, NSCA, OMS, Bosquet, Pritchard, Helms, BJSM, CrossFit, Hal Higdon…). Notes écrites dans la page de relecture : manche 7 (autres disciplines) et manche 8 (street 0.3.0), auteur `relecture-documentee`. PubMed et PMC étaient inaccessibles aux relecteurs (captcha) : moins de méta-analyses citées qu'aux manches précédentes.

| Profil | Ensemble | Adapté | Progression | Volume / intensité | Exercices | Faisable et sûr |
| --- | --- | --- | --- | --- | --- | --- |
| `street_01_debutant_complet` | 5,5 | 6 | 5 | 5 | 7 | 7,5 |
| `street_03_debutante` | 3,5 | 4 | 3 | 3 | 6 | 6 |
| `street_06_inter_sets_reps` | 5,5 | 6,5 | 4,5 | 5,5 | 7 | 8 |
| `street_12_antecedent_coude` | 6,5 | 7,5 | 6 | 6,5 | 8 | 8 |
| `street_14_parc_sans_lest` | 5,5 | 6,5 | 4,5 | 5,5 | 7 | 8 |
| `street_07_avance_streetlifting_competition` | 7,5 | 8 | 7 | 7,5 | 7,5 | 8 |
| `street_08_avance_sets_reps_competition` | 6,5 | 7 | 6 | 6 | 7 | 8 |
| `street_09_elite_streetlifting` | 7 | 7,5 | 6,5 | 7 | 8 | 7 |
| `street_10_elite_figures` | 5,5 | 6,5 | 4,5 | 5 | 6 | 6 |
| `autres_01_debutant_musculation` | 7,5 | 7,5 | 7 | 7 | 7,5 | 9 |
| `autres_02_hypertrophie_intermediaire` | 6,5 | 6,5 | 5,5 | 6 | 7 | 8,5 |
| `autres_03_powerlifter_competition` | 7,5 | 7,5 | 8 | 6,5 | 7,5 | 8,5 |
| `autres_04_force_generale_46_ans` | 5 | 6 | 4 | 5 | 7 | 8 |
| `autres_05_course_10_km_debutante` | 5 | 5 | 5,5 | 5 | 6 | 5,5 |
| `autres_06_semi_marathon_intermediaire` | 6,5 | 7 | 7 | 6,5 | 6 | 7,5 |
| `autres_07_mobilite_sante_senior` | 7 | 7,5 | 6 | 6,5 | 7 | 9 |
| `autres_08_crossfit_intermediaire` | 5,5 | 5,5 | 5 | 5,5 | 6 | 7 |
| `autres_09_perte_de_poids_debutante` | 7 | 7,5 | 6 | 7 | 7,5 | 7,5 |
| `autres_10_contraintes_multiples` | 5,5 | 6 | 4,5 | 5,5 | 6 | 7,5 |

Moyenne d'ensemble : street 5,9 (minimum 3,5, `street_03` ; manche 4 relue par le pilotage : 5,9), autres 6,3 (minimum 5). Le panel est nettement plus indulgent que la relecture documentée, comme aux manches précédentes.

Constats principaux (traitement : partie 6) :

1. **Street, temps disponible et dose du mouvement de l'objectif** (`street_01`, `03`, `06`, `14`) : séances à environ la moitié du créneau, mouvement de l'objectif sous-dosé, aucun objectif atteint ; `street_03` : pompe inclinée à 1 × 2-3 répétitions pendant 15 semaines pour un maximum d'environ 22 (le critère de passage 2 × 12 ne peut pas être rempli).
2. **Pas de changement de méthode après un plateau** (`street_06`, `14`, `10`) : variante plus dure (archer, typewriter) jamais introduite ; `street_10` : dose de figure figée de S5 à S15, poignet chargé jusqu'à une gêne à 4/10 en S14, test maximal de planche gardé en S16.
3. **1RM déclarés** : `street_09` (dips, squat surestimés ; échec à 170 kg en S6), `street_07` (muscle-up sous-estimé), `street_12` (bloc 3 sur 116 kg pour un test à 119,5 kg).
4. **Autres** : `autres_04` objectif de squat hors de portée et bloc d'intensification plus léger qu'en S4 ; `autres_05` « fractionné » qui reste un footing 12 semaines, sortie longue plafonnée à 52 min pour une course d'environ 70 min, course un jeudi sur un créneau de 45 min ; `autres_08` progressions de muscle-up absentes (traction poitrine-barre lestée, transition à la barre basse, muscle-up à l'élastique), WOD sans tours ni plafond ; `autres_10` progression incohérente de la chaise contre le mur, bas du corps limité à l'isométrie ; `autres_02` épaules sous-entraînées (6 séries par semaine), note de coureur sur les mollets.
5. **Sécurité signalée** : `street_01` et `street_03` (poignet : variante neutre tardive ou absente) ; `street_12` (+17,9 % d'une séance à l'autre sur le dips lesté) ; `autres_10` (avis médical à exiger avant la semaine 1 pour un genou à 5/10, développé au-dessus de la tête sur l'épaule opérée) ; `autres_05` (sortie longue +27 % en S7) ; `autres_06` (footing du lendemain du semi à rendre facultatif). Aucun de ces points n'est une violation calculable du banc (0 violation).

## 5. Relectures traitées

- Relecture documentée indépendante de la manche 4 (`RELECTURE_DOCUMENTEE_CX_c1.md` ; la lecture des notes de la page par ArtifactData était refusée par la session au début de la partie 0, même contenu que les notes `m4_*_pilotage`) : constats de sécurité C9.8 traités en partie 0 (CP2.1, C10.6). Remarques « autres disciplines » de la manche 0 (créneau disponible, volume de poussée, jambes, profils non street ; LANCEMENTS, CX correction 1) : traitées par le chemin coach (partie 1).
- Relecture indépendante du code de 0.2.3 (12 constats, 10 corrigés) et de 0.3.0 (12 constats : 1 à 4 et 6 à 9 corrigés ; non corrigés : 10, espacement de 72 h en force à trois séances, mineur ; 11, adaptateur de spécialisation, latent ; 12, mineurs).
- Contrat de `kalis_core` : un paramètre de raison inconnu est refusé (`unknown_param`) ; les échauffements par famille passent donc par des codes de note distincts, ajoutés à la liste des valeurs de CoachNotes (additif).

## 6. Limites et constats ouverts

1. **Cible C7.5 non atteinte** : street 19/68 à 9 (min 5), autres 15/40 (min 5). Incertitude du panel ≈ 1 point.
2. Ouverts côté programme écrit (`kalis_plan`) pour CY : temps disponible inutilisé et dose du mouvement de l'objectif chez les débutants street ; changement de méthode après plateau (variantes plus dures, figures de l'élite sur levier plus facile) ; plafond de la pompe inclinée de `street_03` ; 1RM déclarés surestimés hors street_07 (`street_09`) ; hypertrophie (`autres_02`) : séries qui ne montent pas, épaules ; intensité du squat aux blocs 2-3 de `autres_04` ; fractionné et sortie longue de `autres_05` ; progressions et tests du muscle-up de `autres_08` ; genou et cardio de `autres_10` ; avis médical bloquant au-delà de 4/10 déclaré.
3. Relecture documentée : notes de 3,5 à 7,5 (sans seuil, C7.6) ; ses constats de sécurité sont des points de conduite et de programme sans violation calculable — à faire vérifier par le pilotage.
4. PubMed et PMC inaccessibles aux relecteurs de cette session (captcha).

## 7. Contrôles, non-ressemblance, clé

- Contrôle complet `claude/ci-cp-a` run 37882215421 (commit dd6165df) : `kalis_core`, `kalis_plan` (302 tests, propriétés street et autres, docs générés, formatage), `kalis_adapt`, `kalis_bench` (27 profils, 136 saisons street : 0 violation) **verts** ; le travail a ensuite atteint sa limite de 90 min pendant `kalis_quest`, qui n'est pas touché par CP2 (il ne dépend que de `kalis_core` et `kalis_adapt`, identiques à `moteurs` 9f931fbf) et qui était vert au contrôle précédent (run 37871717821, mêmes dépendances). Dossier `packages/` publié identique à l'arbre contrôlé.
- Références privées : utilisées seulement dans la session (clé lue d'un fichier `/tmp` en mode 600) ; aucune recopie, aucune mention. Non-ressemblance (`tool/reference_jaccard.py`, calculée dans la session avec la clé, sur les 27 programmes et les 17 saisons street du candidat) : maximum exact **0,250**, tolérant **0,250** (seuil 0,30) ; autres disciplines : 0,022 au plus. Détail chiffré sur `cp-references` (`analyse_CP2.tar.gpg`, commit 0aa951dd). Clé passée à gpg par un fichier `/tmp` en mode 600 (`--passphrase-file`), supprimé après usage.
- Programme de 40 semaines du propriétaire : non touché.

## 8. Recommandation (C8 : le pilotage décide)

1. **Valider CP2 comme base de CY** (`kalis_plan` 0.3.0, `kalis_bench` 0.2.4) : 0 violation sur les 27 profils et les 136 saisons street (23 sur les autres en 0.1), street non dégradé (19/68 contre 14/68 à la fin de la partie 0), autres disciplines de 6,15 à 7,92 de moyenne et de 4 à 15 couples à 9 en quatre boucles.
2. **Faire entrer 0.3.0 dans l'application** avec `kalis_adapt` 0.3.0 (C10.8 : lot d'application suivant) : c'est la première version où les autres disciplines passent par les moteurs calibrés.
3. **Cible C7.5 reportée à CY**, avec en tête les points de la partie 6 (2), d'abord les deux constats de relecture qui touchent la sécurité perçue (avis médical bloquant pour une douleur déclarée ≥ 5/10 ; variante poignet neutre dès la première gêne chez les débutants street) puis l'usage du créneau et la dose du mouvement de l'objectif, qui pèsent sur le plus de couples.
