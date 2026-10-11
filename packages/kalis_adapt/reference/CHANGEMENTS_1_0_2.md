# KM1 correction 2 — liste exacte des changements de la référence (1.0.1 → 1.0.2)

Base : `moteurs` df28b47c (référence 1.0.1, `kalis_adapt` 1.0.0). Décision : DECISIONS_CP.md C13.12 (trois points de méthode). Diff complet : l'historique git de `moteurs` (commit « KM1c2 »). Paramètres : `params/koach_params_v1.json` version `1.0.2-ref.1` (322 clés : 5 nouvelles, 1 valeur changée). L'API et le schéma du journal du contrat 1.0 ne changent pas ; seules des règles internes et des paramètres changent. Le code Dart (`kalis_adapt` 1.0.0) n'est pas touché : le portage de ce delta est le lot KM2c1.

Mesures : `donnees/criteres_km1c2.json` (campagne, graines 0 à 5, 4 320 saisons, Koach complet), `donnees/adversaires_km1c2.json` et `donnees/comparaison_adversaires_km1c2*.json` (banc adversarial, critère 7 bis), `pipeline/cp/livraisons/LIVRAISON_KM1c2.md`.

## A. Reprise par paliers mesurés (koach/seance.py) — point 1 de C13.12

Cause mesurée (adversaire `adv-31c45cfb`, recherche de KM2) : l'estimation était juste le jour J (147 kg pour un maximum de 157 kg), mais (1) la semaine du retour d'une coupure, toute charge était bornée par le « dernier passage » de l'exercice, quel que soit l'emplacement (ici un simple d'affûtage à 47,5 kg) ; (2) l'ouverture des tentatives prenait la même borne ; (3) les sauts de 5 % puis 3 % d'une barre aussi légère, ramenés à la grille, valaient zéro : trois tentatives à 47,5 kg. Même ancrage un jour de bilan bas (« dernier passage » d'une séance légère d'un autre emplacement).

### A.1 Lignes chargées, semaine du retour d'une coupure (`_item`, `_cible_charge`, `_bornes_hausse`, `serie_faite`)
- `_item` : `coupure > 0` ne pose plus `sans_hausse` sur une ligne `charge` ; il pose `plan['reprise'] = True`. Les lignes `reps` et `tenue` gardent `sans_hausse` (inchangé). Les séries × `coupure_series`, l'absence de mesure (`_mesure_utile`) et le report des tests `one_rm` / `attempt_simulation` hors jour d'épreuve sont inchangés.
- Première série (`_bornes_hausse`) : `gel = sans_hausse ou reprise`. Avec `gel`, comme avant avec `sans_hausse` : au plus la charge de la dernière séance du même schéma (emplacement, répétitions), ou, schéma nouveau, au plus la plus lourde barre réussie des `barre_recente_j` derniers jours (sans la hausse `premiere_hausse`).
- Test adaptatif de la première série (charge voisine plus informative) : pas en reprise (comme avec `sans_hausse`).
- `plan['reprise_cible']` = la charge que l'estimation demande pour la série, avant les bornes de hausse (après la part écrite, le plafond de part, le plafond du simple).
- Séries suivantes : la règle ordinaire d'une série à l'autre (+5 % de la charge totale ou un cran, étape 14 du contrat) ne s'applique en reprise que si le palier précédent est **franchi** (`plan['palier_franchi']`, posé par `serie_faite`) : série sans échec, notée, dite au plus aussi dure que visé (`flames ≤ target.flames`), répétitions faites ≥ `target.repsLow`. Sinon la charge reste celle de la série précédente (ou, sans série versée au journal, celle de la première série) ; trace `palier de reprise non franchi`.
- `serie_faite` : quand un palier est franchi à une charge ≥ `reprise_cible`, sur une série de travail (`target.role` absent), `Memoire.reprise_jour` = jour de la séance (champ nouveau, lu par les diagnostics ; la reprise de l'exercice est terminée).
- `borne_externe` : renvoie `None` en reprise (aucun bras d'intensité pendant la semaine du retour, comme avec `sans_hausse`).
- Test xRM chargé (`_cible_test`) : la borne « au plus le dernier passage » vaut avec `sans_hausse`, après un échec non prévu, et en reprise **hors jour d'épreuve** ; le jour d'épreuve, en reprise, le test suit l'estimation.

### A.2 Ancre « dernier passage de l'exercice » (`_cible_charge`, étape 15 du contrat)
- Avant : `sans_hausse` (conduite sous douleur, palier de bilan ≥ 1, coupure) ou raison de conduite → au plus `charge_derniere`.
- Maintenant : conduite sous douleur seulement (`cond['sans_hausse']` ou `cond['raison']` : zone douloureuse, bloquante ou en reprise, poignet). C'est l'invariant de 0.3.1 (aucune hausse par rapport à la dernière séance de l'exercice sur zone douloureuse, `A/coach.dart` : `lastAny`) et c'est ce que le modèle de vérité du banc sanctionne (aggravation si la première série dépasse la dernière séance de l'exercice sous douleur > 3).
- Jour de bilan bas sans douleur : comme 0.3.1 (`lockCause = 'health'`), borne de la dernière séance du même schéma (`_bornes_hausse` avec `sans_hausse`) et charge gelée d'une série à l'autre ; plus d'ancre sur un autre emplacement.

### A.3 Tentatives (`_tentative`, `fermer`)
- Retiré : « jour d'épreuve en semaine de retour : ouverture ≤ dernier passage » (étape 2 ter du contrat).
- Remplacé : le plafond « barres réussies des 42 jours + `premiere_hausse` (10 %) » (étape 3) devient un **palier selon la note** :
  - chaque barre réussie des `barre_recente_j` derniers jours est ramenée à une répétition : `total = (c + pdc)·(1 + schema_change_part·min(r − 1, schema_change_reps_max))` (inchangé) ;
  - son palier vient de la réserve dite (`rir_de_flammes`) et de `securite.tentative_palier_par_rir` = [[4, 0,10], [3, 0,075], [2, 0,05], [1, 0,025]] : première ligne dont le seuil est ≤ réserve dite ; 0 si la barre n'est pas notée ou est dite à moins d'une répétition de l'échec ;
  - plafond = `plus_haute·(1 + pas) − pdc`, où `plus_haute` est le plus grand `total` et `pas` le **plus petit** palier des barres dont le `total` est ≥ `plus_haute·(1 − tentative_palier_bande)` (0,05) ;
  - l'ouverture calculée (étapes 1, 2, 2 bis) est ramenée sous ce plafond, sur la grille.
- Nouvelle mémoire : `Memoire.barres` = liste de (jour, charge, répétitions, flammes dites) des séries chargées réussies, remplie par `fermer` en même temps que `charges_reussies`.
- Tentatives suivantes : quand le saut en pourcentage est plus petit qu'un cran de la grille (la charge resterait celle de la barre précédente), un cran est permis si la barre précédente a été dite au plus aussi dure que visé (`flammes_seance ≤ 7` après la première, `≤ 9` après la deuxième) et si le cran ne dépasse pas `tentative_saut_kg` ; la condition `P(réussite) ≥ 0,2` reste. `Memoire.flammes_seance` est désormais lu.
- Les sauts (`tentative_saut_2`, `tentative_saut_3`, `tentative_saut_kg`), les probabilités, la barre gardée après un échec et la baisse de bilan bas ou de douleur sont inchangés (règles A8.2 de 0.3.1).

### A.4 Mesures qui ont décidé (itérations 1 et 2 du point)
- Itération 1 : palier par barre (maximum, sur toutes les barres, de `total·(1 + pas)`). Itération 2 (retenue) : palier de la plus lourde barre avec la note la plus dure des barres proches. Sur 409 ouvertures de jour J des adversaires connus (KM1, KM2, recherche contre l'itération 1), simulation de l'échelle : échecs d'ouverture 12 (estimation seule), 11 (itération 1), 6 (itération 2) ; sur 570 ouvertures du banc (graines 0 et 1) : meilleure barre / maximum 0,9412, 0,9412, 0,9401, aucun échec d'ouverture.
- Essayé puis écarté : ouverture ≤ la plus lourde barre récente sans aucun palier (banc 0,9375) ; ouverture à 91 % du maximum que la barre prouve (banc 0,888 à 0,928) ; probabilité d'ouverture 0,975 ou 0,99 (banc 0,9387, 0,9313 ; moins d'échecs mais performance moyenne des adversaires en baisse).
- Sauts plus grands après une barre dite très facile : non retenus (moins prudents que A8.2 de 0.3.1).

## B. P(réussite) du jour J (koach/planification.py) — point 2 de C13.12
- `evaluer`, avec cibles et échéance : après `frais = mu_fin − KG·fatigue + gain_affutage`, la dispersion des trajectoires autour de leur moyenne (par plan candidat et par exercice) est multipliée par `planification.dispersion_echeance` : `frais ← moyenne + dispersion_echeance·(frais − moyenne)`, moyenne prise sur les trajectoires (`mean(axis=2)`). `prevu_jour` (ligne d'historique) rapporte la moyenne et l'écart-type après cette opération.
- `dispersion_echeance` = 0,62, **mesuré** sur les graines 0, 2 et 4 (717 cibles chargées, une prévision par cible 4 semaines avant l'échéance) : écart-type de ln(maximum du jour J) − prévision = 4,06 % ; effet de jour du modèle (`sigma_seance`, `sigma_exercice`) = 2,84 % ; reste 2,9 % pour un écart-type des trajectoires de 4,57 % en moyenne → κ² = (Σe² − n·σ_jour²)/Σs² = 0,388, κ = 0,62. Vérifié sur les graines 1, 3 et 5 (jamais vues) : voir la livraison.
- Aucun autre paramètre du modèle de réussite ne change (`erreur_estimation_echeance_sd` remesuré sur 570 ouvertures du banc : 3,8 % hors effet de jour, pour 0,03 ; gardé).

## C. Intervalle à 90 % (koach/modele.py) — point 3 de C13.12
- `capacite(id)` : écart-type = `√(intervalle_echelle²·max(h P hᵀ, 0) + defaut_modele_sd²)` (avant : `√(max(h P hᵀ, 0) + defaut_modele_sd²)`). `capacite_du_jour` est inchangé.
- `mesure.defaut_modele_sd` 0,015 → 0,010 ; `mesure.intervalle_echelle` = 0,9 (nouveau, lu par `.get` avec le défaut 1).
- Pourquoi deux paramètres : sur les graines 0, 2 et 4, le recalage hors ligne (34 775 estimations des principaux chargés, rangs ≥ 3) donne 93,6 % avec 0,015 et encore 92,3 % avec un défaut de modèle nul : le défaut de modèle seul ne ramène pas la couverture dans 88-92 %. L'intervalle du filtre est trop large aux premiers rangs de séance (rang 3 : 98,5 %, rang 6 : 95,8 %) et juste ensuite (rangs 10 à 15 : 92 à 93 %). Avec (0,010 ; 0,9) : 90,2 % hors ligne.
- Effets de bord : `capacite` est lu par le calibrage de la première charge (`σ > 0,12`), `_mesure_utile` (demi-largeur > 6 %), le contrôle dual et les innovations de la surveillance ; mesurés par la campagne (critères 1, 3, 6, 8 sans recul).

## D. Banc (banc/*.py)
- `banc/adversaire.py` : `critere_apparie(lignes)` et clé `critere_7_bis` de `comparer` (C13.12) : adversaires où les deux moteurs ont un jour J ; part des cas où Koach ≥ témoin − 0,03 (seuil 90 %) ; cas sous témoin − 0,10, excusés seulement si le témoin y commet une violation de sécurité ; variante `temoin_avec_barre`.
- `banc/campagne.py` : option `--partie i/n` (campagne répartie) ; `estimations.couverture_paires` par saison (recalage hors ligne du critère 4) ; `prevu_jour` et `observe` dans les unités de calibration (critère 5).
- `banc/mesures.py` : `paires_couverture`. `banc/planification_banc.py` : `prevu_jour` dans `previsions`.

## E. Tests (tests/)
- `test_securite_regles.py` : `test_retour_de_coupure_ni_test_ni_mesure_paliers` (remplace `…_ni_hausse`), `test_reprise_par_paliers_mesures`, `test_reprise_palier_non_franchi`, `test_reprise_terminee_a_la_cible`, `test_bilan_bas_sans_douleur_borne_par_le_meme_schema`, `test_ouverture_paliers_selon_la_note`, `test_tentative_un_cran_apres_une_barre_dite_facile` ; `test_pas_de_tentative_maximale_au_retour_de_coupure` mis à jour.
- Fixtures de parité régénérées (13).
