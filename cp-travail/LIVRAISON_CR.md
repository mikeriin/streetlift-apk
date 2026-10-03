# Livraison CR — banc d'essai `kalis_bench` 0.1.0 et mesure des moteurs 0.1

Lot CR du pipeline « Calibrage des programmes » (voie A, Fable 5.1, effort maximal). Livré le 03/10/2026.
Validation : automatique (contrôle vert). Aucun moteur n'est modifié par ce lot.

| | |
| --- | --- |
| Paquet | `kalis_bench` **0.1.0** (nouveau ; lit `kalis_core` 0.4.0, `kalis_plan` 0.1.0, `kalis_adapt` 0.1.0) |
| Branche de travail | `moteurs`, commit `@COMMIT@` — « Kalis Track moteurs (CR) : kalis_bench 0.1.0 » |
| Étiquette (branche fixe) | `etiquettes/kalis_bench-v0.1.0` |
| Contrôle | `claude/ci-cp-a`, run @RUN@ : @PAQUETS@ |
| Moteurs 0.1 au panel | moyenne **4,9/10**, note la plus basse **3/10** (seuil du calibrage : 9/10) |
| Sécurité des moteurs 0.1 | **117 violations** sur 27 programmes (cible : 0) |
| Page de relecture | https://claude.ai/artifact/48CYFBy75Xykohm674vLNq (manche 0, dix programmes à noter) |

## Déroulement

Deux sessions. La première (02/10) a écrit le référentiel, analysé les six programmes de référence, écrit les mesures agrégées, les profils, les critères et leurs tests ; elle s'est arrêtée avant la livraison (DECISIONS_CP.md C3), son arbre conservé sur `claude/ci-cp-a`, son analyse détaillée perdue. La seconde (03/10, 11:14 UTC) a repris cet arbre **en le vérifiant** : relecture indépendante du code (13 constats, tous traités), rapprochement du référentiel avec la revue du profil v3 de CQ (15 références ajoutées, une erreur de signe corrigée, 7 divergences consignées), nouvelle analyse des références (chiffrée sur `cp-references`), puis étalonnage du panel, mesure des moteurs 0.1, page de relecture et publication. Sous-agents sur Opus, sauvegardes sur `cp-sauvegardes/CR` (PIPELINE_CP.md §9).

## 1. Ce qui est livré

| Livrable | Où | Contenu |
| --- | --- | --- |
| Référentiel | `packages/kalis_bench/docs/REFERENTIEL.md`, `docs/referentiel/R1` à `R6` | 145 principes chiffrés (volume, intensité et techniques, périodisation et affûtage, figures et endurance de force, individualisation et sécurité, autres disciplines) ; chaque principe : règle, niveau de preuve, traduction du débutant à l'élite, ce qu'un très bon coach fait au-delà ; références vérifiées deux fois, puis une troisième passe à la reprise |
| Mesures des références | `docs/MESURES_REFERENCES.md` | fourchettes agrégées et anonymes (volumes, fréquences, formats, progression, affûtage) ; aucun extrait, aucun nom |
| Profils types | `profiles/` (27 fichiers), `docs/PROFILS.md` | 17 street (débutant complet à élite, compétitions, contraintes) et 10 autres disciplines, chacun avec 4 à 10 attentes de coach vérifiables ; adaptateur isolé vers le profil des moteurs |
| Critères calculables | `lib/src/`, `docs/CRITERES.md` | sécurité (15 critères, zéro violation exigé), qualité (9 critères), attentes par profil, trajectoires simulées avec verdicts ; exports lisibles ; CLI ; 7 fichiers de tests |
| Panel | `docs/PANEL.md`, `docs/grilles/` (gelées, SHA-256), `docs/ETALONNAGE_PANEL.md`, `docs/etalonnage/` | quatre écoles, grilles de 9 critères ancrés à 4, 7, 9 et 10, protocole aveugle, contrôle de dérive |
| Mesure de départ | `docs/BASELINE_0_1.md`, `docs/baseline/CORRECTIONS_PANEL_0_1.md` | moteurs 0.1 sur tout le banc ; défauts par ordre de priorité pour CP1, CA1, CP2, CA2 ; les 415 corrections demandées par le panel |
| Page de relecture | lien ci-dessus ; source dans `tool/relecture/` | manche 0 : huit profils street (débutant complet à élite) et deux d'autres disciplines ; pour chaque programme, vue d'ensemble puis semaines et séances ; note d'ensemble, cinq critères, commentaire du programme et de chaque séance ; notes enregistrées dans la collection `notes` de la page |
| Analyse des références | branche `cp-references`, `analyse_CR.tar.gpg` (chiffrée) | analyse détaillée, transcriptions, ancres hautes de l'étalonnage, couples pour la non-ressemblance |

## 2. Étalonnage du panel

Six profils, quatre variantes ((a) volontairement mauvais, (b) générique correct, (c) expert, (d) ancre haute privée), quatre écoles, en aveugle ; 84 appels en deux manches.

| Variante | Manche 1 | Manche 2 (règles précisées, gel) | Exigé |
| --- | --- | --- | --- |
| (a) mauvais | 0 à 1 | 0 à 1 | < 6 |
| (b) générique correct | 4 à 6 | 4 à 7 | entre (a) et (c) |
| (c) expert | 7,5 à 9 | 8 à 9 | au-dessus de (b) |
| (d) ancre haute | 6,5 à 8 | **9** (quatre écoles, quatre profils) | ≥ 9 |
| Répétabilité (deux appels indépendants) | ≤ 1 point | ≤ 1 point (moyenne 0,25) | ≤ 1 point |

Entre les deux manches, les règles communes ont été précisées (correction nécessaire contre amélioration ; 9 = aucune correction nécessaire) et les ancres hautes réécrites d'un seul tenant ; les critères et leurs ancrages n'ont pas changé (DECISIONS_CP.md CR.3). Grilles gelées ensuite.

## 3. Rapport du banc : moteurs 0.1 (avant tout calibrage)

Il n'y a pas d'« après » dans ce lot : cette mesure est le point de départ des lots suivants.

- **Sécurité** : 117 violations sur les programmes créés (volume au-dessus du plafond 77, volume trop vite 16, bras tendus trop vite 6, charge trop vite 5, pas d'allègement avant l'échéance 5, séance trop longue 5, technique sans prérequis 3) ; 167 après adaptation simulée. Quatre profils sur 27 sans violation.
- **Attentes de coach** : 113 tenues sur 166 (68 %).
- **Trajectoires** (`kalis_adapt` 0.1.0) : écart moyen au RIR visé 2,05 répétitions ; 26 trajectoires sur 27 hors repère ; performance simulée à l'échéance de 86 à 97 % du meilleur niveau antérieur pour quatre profils sur cinq ; gain nul chez les avancés.
- **Non-ressemblance** : programme du propriétaire, sous 0,30 partout ; références privées, 0,014 (lecture exacte) et 0,222 (lecture tolérante) au plus.

### Notes du panel, par école et par profil (une passe, 108 notes)

| Profil | Niveau | Force | Calisthénie | Hypertrophie | Santé | Moyenne | Plus basse |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `street_01_debutant_complet` | débutant | 5,5 | 6,0 | 6,0 | 6,5 | 6,0 | **5,5** |
| `street_02_debutant_surpoids` | débutant | 7,0 | 7,0 | 7,0 | 5,0 | 6,5 | **5,0** |
| `street_03_debutante` | débutant | 4,5 | 5,0 | 4,5 | 5,0 | 4,8 | **4,5** |
| `street_04_reprise_longue_pause` | intermédiaire | 6,5 | 5,0 | 7,0 | 5,0 | 5,9 | **5,0** |
| `street_05_inter_calisthenie_front_lever` | intermédiaire | 4,0 | 5,0 | 5,0 | 4,5 | 4,6 | **4,0** |
| `street_06_inter_sets_reps` | intermédiaire | 4,5 | 5,0 | 7,0 | 4,0 | 5,1 | **4,0** |
| `street_07_avance_streetlifting_competition` | avancé | 3,5 | 4,0 | 4,5 | 4,0 | 4,0 | **3,5** |
| `street_08_avance_sets_reps_competition` | avancé | 4,5 | 3,5 | 5,5 | 4,0 | 4,4 | **3,5** |
| `street_09_elite_streetlifting` | élite | 4,0 | 5,0 | 6,0 | 4,0 | 4,8 | **4,0** |
| `street_10_elite_figures` | élite | 5,0 | 4,0 | 6,0 | 4,0 | 4,8 | **4,0** |
| `street_11_master_51_ans` | intermédiaire | 4,0 | 4,5 | 4,5 | 4,0 | 4,2 | **4,0** |
| `street_12_antecedent_coude` | intermédiaire | 4,0 | 3,5 | 4,0 | 4,0 | 3,9 | **3,5** |
| `street_13_peu_de_temps` | intermédiaire | 6,5 | 6,0 | 5,5 | 6,0 | 6,0 | **5,5** |
| `street_14_parc_sans_lest` | intermédiaire | 4,5 | 4,5 | 5,0 | 4,0 | 4,5 | **4,0** |
| `street_15_travail_physique_sommeil_court` | intermédiaire | 4,0 | 3,5 | 6,0 | 4,5 | 4,5 | **3,5** |
| `street_16_specialisation_traction_lestee` | avancé | 3,0 | 3,0 | 5,0 | 3,0 | 3,5 | **3,0** |
| `street_17_hybride_street_course` | intermédiaire | 5,0 | 5,0 | 6,0 | 5,0 | 5,2 | **5,0** |
| `autres_01_debutant_musculation` | débutant | 6,5 | 6,5 | 7,0 | 7,0 | 6,8 | **6,5** |
| `autres_02_hypertrophie_intermediaire` | intermédiaire | 6,0 | 7,0 | 7,0 | 6,0 | 6,5 | **6,0** |
| `autres_03_powerlifter_competition` | avancé | 3,0 | 4,0 | 4,5 | 3,5 | 3,8 | **3,0** |
| `autres_04_force_generale_46_ans` | intermédiaire | 3,5 | 4,0 | 6,0 | 5,0 | 4,6 | **3,5** |
| `autres_05_course_10_km_debutante` | débutant | 4,0 | 4,0 | 4,5 | 4,0 | 4,1 | **4,0** |
| `autres_06_semi_marathon_intermediaire` | intermédiaire | 3,0 | 3,0 | 4,5 | 3,0 | 3,4 | **3,0** |
| `autres_07_mobilite_sante_senior` | débutant | 5,5 | 5,5 | 5,0 | 5,0 | 5,2 | **5,0** |
| `autres_08_crossfit_intermediaire` | intermédiaire | 5,0 | 4,5 | 6,5 | 5,0 | 5,2 | **4,5** |
| `autres_09_perte_de_poids_debutante` | débutant | 5,0 | 7,0 | 6,0 | 5,0 | 5,8 | **5,0** |
| `autres_10_contraintes_multiples` | débutant | 5,0 | 5,0 | 5,0 | 7,0 | 5,5 | **5,0** |
| **Moyenne** | | 4,7 | 4,8 | 5,6 | 4,7 | 4,9 | **3,0** |

Critères les plus bas : affûtage, pic et tests (3,0 et 3,5), progression des figures (4,1), endurance de force et cardio (4,2), périodisation (4,5), intensité (4,7).

### Défauts à corriger, par ordre de priorité (détail et mesures : `docs/BASELINE_0_1.md` §5)

- **CP1 (création, street)** : 1. échéance ignorée (ni affûtage, ni pic, ni épreuve) ; 2. intensité sous-dosée et charges mal calculées chez les avancés ; 3. mouvements visés trop peu travaillés ; 4. blocs identiques, pas de progression écrite ; 5. débutants : pas de chemin vers la première traction ; 6. figures : pas de progression par paliers ; 7. volume par muscle au-dessus des plafonds ; 8. sets & reps : aucune méthode d'endurance de force ; 9. données du profil ignorées (antécédent, reprise, sommeil, matériel, temps) ; 10. exercices inadaptés, consignes absentes.
- **CA1 (adaptation, street)** : 1. écart au RIR visé non rattrapé ; 2. pas de pilotage vers l'échéance ; 3. progression nulle des avancés ; 4. cibles hors de portée non corrigées ; 5. violations ajoutées par l'adaptation ; 6. presque aucune proposition.
- **CP2** : course non modélisée ; powerlifting sans pic ; force générale et CrossFit ; priorité musculaire ; contraintes de santé.
- **CA2** : cardio, conditionnement et mobilité non modélisés ; hausses de charge trop rapides ; écart au RIR.

## 4. Notes du propriétaire

Aucune à traiter : la page de relecture est créée par ce lot. La manche 0 attend ses notes ; chaque lot moteur suivant les lit au démarrage (`docs/PANEL.md`).

## 5. Limites

- **Références relues en partie à la reprise.** Quatre programmes relus en entier, un à moitié, un pas du tout dans cette session : la transcription des pages en images a été refusée par le contrôle d'autorisations de la session quand le lot a voulu la déléguer, et le lot n'a pas contourné ce refus. Les mesures agrégées de ces parties datent de la première session. Décision laissée au propriétaire (DECISIONS_CP.md, CR, « Écart »).
- **Une seule passe du panel** sur les moteurs 0.1 ; incertitude d'environ un point ; le programme et le résumé de trajectoire sont notés ensemble.
- **Étalonnage sur des profils street** : les grilles n'ont pas été éprouvées sur la musculation, le powerlifting ou la course pure (CR.6).
- **Le plafond de l'échelle est 9** : aucune ancre n'a obtenu 10.
- **Athlète simulé** déterministe : il mesure la cohérence de l'adaptation, pas une personne réelle.
- **Pas de SDK Dart en session** : chaque contrôle passe par la CI (45 à 50 minutes).

## 6. Ce qui reste

- CP1 : `kalis_plan` 0.2.0, street, d'après `docs/BASELINE_0_1.md` §5.1 ; CA1 ensuite (§5.2).
- Relecture du propriétaire : manche 0 de la page.
- Décision du propriétaire sur la relecture des parties de références non relues (non bloquant).
