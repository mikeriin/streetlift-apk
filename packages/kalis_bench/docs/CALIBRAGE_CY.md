# Calibrage CY — croisement final `kalis_plan` 0.3 ↔ `kalis_adapt` 0.3, toutes disciplines

Lot CY du pipeline « Calibrage des programmes » (voie A, Opus 5.5 effort maximal, C5.1), 09/10/2026. Couple livré :
`kalis_plan` 0.3.1, `kalis_adapt` 0.3.1, `kalis_bench` 0.3.0 (`kalis_core` 0.4.3 inchangé). Grilles du panel inchangées
(empreintes SHA-256 de `PANEL.md` vérifiées au départ) ; dérive du panel vérifiée avant la première boucle (ancres
`p08_a` : 1/1/1/1 ; `p14_c` : 8/8/8/8 ; seuils (a) ≤ 2, (c) ≥ 8).

## 1. Ce que le banc mesure désormais (0.3.0)

- **Saisons croisées des 27 profils** (17 street, 10 autres disciplines) : `kalis_plan` écrit chaque bloc, `kalis_adapt`
  conduit chaque séance, le résumé d'adaptation et les tests nourrissent le bloc suivant. Saisons de 16 semaines au
  moins, jusqu'à une semaine après l'échéance.
- **Dix scénarios imposés** : les huit de CX (référence, séances manquées, maladie, douleur au coude, douleur à
  l'épaule, parc seulement, échéance avancée, deuxième échéance) et deux nouveaux :
  - `changement_discipline` : à mi-saison, la première discipline secondaire devient la principale (22 profils ; pour
    un profil au mode street, le mode street suit : la composante qui devient principale prend la part de l'ancienne,
    contrat de `kalis_core`) ;
  - `course_ajoutee` : un 10 km annoncé en semaine 5 et couru en semaine 10 (profil street hybride, `street_17`).
  Un scénario sans objet pour un profil n'est pas simulé (239 saisons racontées au lieu de 136).
- **100 graines par modèle de vérité** (trois modèles) au contrôle complet ; 4 aux contrôles de mise au point.
- Comparaison au couple 0.1 (couple `v01` de la campagne) et au couple 0.2 (street : campagne de CX correction 1,
  `kalis_bench` 0.2.1, run 37330259003, mêmes scénarios et mêmes graines).

## 2. Partie 0 — sécurité (constats de la relecture documentée de CP2, C10.10, et de CA2)

| Constat (profil) | Correction | Paquet |
| --- | --- | --- |
| Variante poignet neutre tardive (`street_01`, `street_03`) | Première gêne du poignet (3/10 ou plus dans les 14 jours, avant tout arrêt) : la poussée paume à plat passe sur un appui neutre faisable — parallettes, poignées, ou pompe mains serrées sur une barre basse. Pendant un arrêt, C10.8 (a) inchangée (parallettes et poignées seulement). | adapt |
| +17,9 % d'une séance à l'autre au dips lesté (`street_12`) ; +18,1 % (`street_08`) | Schéma changé au même emplacement : charge totale bornée par la hausse à schéma égal, +2,5 % par répétition de moins (4 au plus), aucune part en plus sur une zone à antécédent. | adapt |
| Avis médical à exiger avant la semaine 1 (`autres_10`, genou à 5/10, questionnaire prudent) | Note de bloc `clearance_first` (questionnaire « prudent » ou gêne déclarée ≥ 5/10 ; ACSM 2015, dépistage avant l'activité) ; l'application la montre avant la première séance comme une étape à confirmer. | plan |
| Développé au-dessus de la tête sur l'épaule opérée (`autres_10`) | Note `shoulder_history` : sans douleur, amplitude tolérée, feu vert du chirurgien ou du kiné. | plan |
| Sortie longue +27 % en semaine 7 (`autres_05`) | La règle appliquée est celle de Frandsen et al. 2025 (+10 % au plus sur la plus longue course des quatre dernières semaines ; le saut de 27 % se mesurait contre la semaine de test) ; le texte de la règle dit maintenant ce que le moteur fait. | plan |
| Footing le lendemain du semi (`autres_06`) | Lendemain d'une course d'épreuve : pas de course écrite (repos ou marche libre). | plan |
| Squat servi 142,5 kg pour 137,5 kg écrits, maximum du jour 143 (`street_07`) | À 85 % du 1RM écrit ou plus, le couloir de charge ne monte plus au-dessus de l'écrit. | adapt |
| Test maximal de planche gardé au programme pendant la douleur (`street_10`) | Pas de test maximal sur une articulation douloureuse : gêne relevée au bloc précédent ≥ 3/10, déclarée ≥ 4/10, ou zone à l'arrêt (une vraie épreuve reste écrite). | plan |
| Tirage ajouté après les tests de tirage (`street_08`) | Jour de test de traction ou de muscle-up : le travail ordinaire de tirage vertical et de muscle-up saute. | plan |
| Test « 8 à 15 » muscle-ups pour une première réussite (`autres_08`) | Mouvement à risque élevé jamais réussi : le repère est une répétition propre. | plan |
| Sous-dosage reconduit après un mauvais jour (CA2, `street_06`) | Un jour de bilan bas ne devient plus le repère d'un jour bas suivant. | adapt |

Non traités en partie 0 (conduite, sans risque) : estimation du muscle-up le jour J (`street_07`), course-marche du
débutant qui n'achève pas ses sorties (`autres_05`) — voir § 6.

## 3. Boucles de calibrage (C9.2 : 5 au plus, arrêt après une boucle sans gain)

| Passe | Version | Street (68 couples) | Autres (40 couples, saisons) |
| --- | --- | --- | --- |
| Départ street (passe finale de CP2, même couple 0.3.0 × 0.3.0) | 0.3.0 | 19 à 9, min 5, moy 7,71 | — (CP2 notait les programmes écrits : 15/40, min 5, moy 7,92) |
| p1 (complète, saisons) | partie 0 + boucle 1 | 19 à 9, min 5, moy 7,85 | 2 à 9, min 5,5, moy 7,41 |
| p2 (couples sous 9 dont l'export a changé, et couples à 9 changés de plus de 10 %) | boucle 2 | **22** à 9, min 5, moy 7,71 | **4** à 9, min 5,5, moy 7,30 |
| p3 (13 couples : exports changés de plus de 2 % par les corrections de sécurité et la relecture du code) | sécurité + relecture du code | 22 à 9, min 5, moy 7,73 | 3 à 9, min **2** (`autres_06`), moy 6,71 |
| p4 (`autres_06`, 4 écoles) | boucle 3 | **22** à 9, min 5, moy 7,73 | **3** à 9, min 5,5, moy 7,21 |

Boucle 1 : variantes plus faciles hors du plafond de répétitions (la pompe inclinée de `street_03` était écrite 1 × 2 à
1 × 3 pendant quinze semaines pour un maximum d'environ 22) ; deux séries assistées par jour pour le débutant qui vise
la première traction (douze séries de tirage vertical par semaine au plus, R5-P1) ; archer et typewriter d'abord au
plateau sans lest à partir de douze tractions ; propositions « volume ajusté » sous le plafond du niveau (une
proposition portait les fessiers d'une débutante à 13 séries : seule violation calculable vue au banc étendu, corrigée).

Boucle 2 : double progression « 2 pour 2 » (NSCA) dans la conduite (charges figées seize semaines quand l'athlète ne
va jamais près de l'échec) ; sortie longue après une course (70 %, puis +10 % par semaine) ; note « zone de
l'épreuve » alignée sur les répétitions écrites ; remplissage du créneau à 80 % en semaine de construction, sous les
garde-fous de volume.

Boucle 3 (régression vue en p3) : la course retirée sous une douleur de cheville (`autres_06`, correction de sécurité de
`kalis_adapt`) était comptée comme « sautée » dans le résumé d'adaptation ; `kalis_plan` l'écartait alors pour tout le
bloc suivant, échéance comprise (six semaines de séances d'une minute de mobilité, notes 2 à 2,5). Un retrait sous arrêt
n'est plus compté comme sauté : le bloc suivant garde la course avec la note d'arrêt, la conduite la retire tant que
l'arrêt tient puis la rend par paliers (50 %). `autres_06` revient à 7, 8, 7, 7 (p2 : 9, 8, 8, 8 ; corrections
nécessaires restantes : allure du semi construite, renforcement mollet et cheville, vraie transition après la course —
méthode, pas sécurité).

Arrêt après la boucle 3 (C9.2 : 5 au plus ; la boucle 3 n'a fait que rattraper sa régression, sans gain), après une passe
de corrections de sécurité issue de la relecture documentée (§ 4) et la relecture indépendante du code (§ 5) : gain à la
boucle 2 (street 19 → 22 couples, autres 2 → 4), minimum inchangé (autres : 3 à 9 en fin de lot, `autres_06` renoté à 7 par l’école force) ; les corrections nécessaires restantes portent sur
la méthode (estimation des capacités par le moteur d'évolution, spécialisation, progression des figures et du
muscle-up) et sur des choix que les deux jurys jugent en sens contraires (volume du débutant). Budget : C9.5, deux
sessions en parallèle (CI1e).

Lecture : incertitude du panel d'environ un point (CR.4) ; les saisons des autres disciplines sont jugées plus
sévèrement que leurs programmes écrits (CP2 : 15/40) parce que la conduite y apparaît (charges sous-estimées).

## 4. Relecture documentée (C7.3, C7.6 ; sans seuil)

Trois sous-agents Opus, sources web seulement (ACSM, NSCA, OMS, NICE, HPRC, Stronger by Science, Riegel…), exports de
la boucle 2. Notes d'ensemble : street 6, 5, 6, 7, 6 (débutants, intermédiaires, contraintes : `street_01`, 03, 06,
12, 14) et 7, 6, 7, 5 (avancés et élite : 07, 08, 09, 10) — moyenne 6,1 (CP2, manche 8 : 5,9) ; autres disciplines 5,
3, 5, 4, 4, 6, 6, 4, 5, 6 — moyenne 4,8 (saisons ; CP2, manche 7, programmes écrits : 6,3).

Constats de sécurité et leur traitement :

| Constat | Traitement |
| --- | --- |
| Pompes reservies pendant la gêne du poignet avant deux semaines à 2/10 (`street_01`, `street_03`, `street_10`) | La pompe mains sur la barre basse ne vaut appui neutre qu'à la première gêne ; pendant l'arrêt, règle C10.8 (a) entière (corrigé, candidat 2). |
| +17,4 % d'une séance à l'autre au dips lesté (`street_12`) | Aucune part en plus pour les répétitions de moins sur une zone à antécédent (corrigé). |
| Course continuée sous une douleur de cheville à 4/10 neuf séances (`autres_06`) | Douleur qui dure au bas du corps : la course est retirée tant que l'arrêt tient, cardio sans impact gardé (corrigé, `kalis_adapt`). |
| Presse pectorale 20 → 25 kg (+25 %) puis séries de 1 à 3 (`autres_09`) | La règle « 2 pour 2 » ne prend pas un cran de plus de 10 % (corrigé). |
| 1RM déclarés non vérifiés écrits au programme (`street_07`, `street_09`) | Conduite : à 85 % ou plus, jamais au-dessus de l'écrit, et le couloir redescend ; l'écrit garde le déclaré au premier bloc (limite, § 6). |
| Dips partiels au-delà du 1RM complet avec antécédent (`street_09`) | Le moteur d'évolution borne le surchargé au 1RM de référence sur une zone fragile (0.2) ; limite écrite au § 6. |
| Avis médical demandé mais non confirmé (`autres_10`) | Note `clearance_first` : l'application la fait confirmer avant la première séance (`kalis_plan/docs/INTEGRATION_CI.md`). |
| Hausses de 40 % au développé haltères (`autres_10`, épaule opérée) | Cran d'haltères de 2 kg sur 10 kg ; la règle « 2 pour 2 » ne prend plus un cran de plus de 10 % (corrigé) ; note `shoulder_history`. |
| Échec au squat à 81 % d'un 1RM déclaré (`autres_08`) | Limite : 1RM déclaré surestimé ; sécurités de cage écrites à partir de 85 % seulement. |

Les autres remarques (objectifs qui n'avancent pas, estimation sous-évaluée par le moteur d'évolution, séances de
qualité absentes en course débutante, spécialisation non appliquée) sont reprises au § 6.

## 5. Contrôles

- Mise au point : runs 37894110383, 37897459037, 37900445699, 37906425835 (boucle 2 : quatre paquets verts, 0
  violation sur les 27 programmes créés et les 239 saisons racontées).
- Non-ressemblance aux références privées (`tool/reference_jaccard.py`, clé lue d'un fichier `/tmp` en mode 600) : 27
  programmes et 27 saisons de la boucle 2, maximum exact 0,231, tolérant 0,250 (seuil 0,30).
- Contrôle complet du candidat livré : voir la livraison.

## 6. Limites et suite

1. **Cible C7.5 non atteinte** (street 22/68, autres 3/40 ; minimum 5 en street, 5,5 dans les autres disciplines).
2. **Estimation par le moteur d'évolution** : une série loin de l'échec n'est qu'une borne basse (CA1.3) ; sur les
   athlètes simulés qui notent mal, les capacités restent sous-estimées (presse estimée à la moitié du réel,
   tentatives du jour J à 88-93 % du maximum du jour). La règle « 2 pour 2 » ne s'applique qu'aux séries notées ;
   l'estimation elle-même reste à revoir (série repère plus fréquente, lecture des notes de 3 en réserve et plus).
3. **1RM déclarés** : le premier bloc est écrit sur le déclaré ; une série repère est écrite (`entry_check`) mais le
   pourcentage reste celui du déclaré.
4. **Musculation** : spécialisation d'un muscle annoncée mais peu appliquée (`autres_02`), échelles de variantes du
   senior, progression du muscle-up en CrossFit (`autres_08`) ; course débutante sans séance de qualité.
5. **Volume du débutant** : le panel (CX, CP2) demandait de le réduire, la relecture documentée demande de l'augmenter ;
   choix retenu : deux séries assistées par jour, douze séries de tirage vertical par semaine au plus (R5-P1).
