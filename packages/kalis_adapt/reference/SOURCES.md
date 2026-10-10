# Sources des paramètres de Koach 1.0

Rédigé le 09/10/2026, remis en accord avec le code et le fichier le 10/10/2026. Fichier décrit : `params/koach_params_v1.json`, SHA-256 `f48984a40f3bd3a23e0d7c00890faaf72f7a99549415446d03392084b7b7c0cf`, 297 clés (6 à la racine, 291 dans les onze sections). L'empreinte sera recalculée à la livraison du lot si le fichier change d'ici là.
Compagnon de `CONTRAT_1_0.md` (§ 7 : rôle de chaque clé et module lecteur).

## Comment lire ce document

Chaque clé du fichier de paramètres reçoit une ligne et une seule catégorie :

| Catégorie | Sens |
| --- | --- |
| **référence publiée vérifiée** | La valeur vient d'une publication dont les chiffres ont été vérifiés (`km1-outils/notes/SOURCES_RECHERCHE.md`, statut « vérifié »). La référence est citée. |
| **mesure sur le banc** | La valeur est tirée d'une mesure sur le banc (modèles de vérité A, B, C portés depuis `kalis_bench`). La mesure et le script sont cités, d'après `km1-outils/SAUVEGARDE.md`. |
| **repris de 0.3.1** | Paramètre de `kalis_adapt` 0.3.1 ou de `kalis_plan` repris tel quel, ou critère du banc `kalis_bench` (couple validé avec 0.3.1). Le nom du paramètre et le numéro de règle de l'inventaire `km1-outils/notes/SECURITE_0_3_1.md` sont cités. |
| **choix raisonné** | Aucune source ne produit la valeur. La raison est dite en une ligne, avec la mesure de contrôle quand il y en a une et le moyen de caler la valeur. Les valeurs fixées par le cahier (`pipeline/cp/CAHIER_KM.md`, « Méthodes § n ») sont dans cette catégorie : le cahier les impose sans source chiffrée ; le paragraphe est cité. |

Règles suivies :

- Quand une source de la littérature est seulement **cohérente** avec une valeur sans l'avoir produite, la clé reste « choix raisonné » ou « mesure sur le banc », et la source est citée comme contexte.
- Une valeur contrôlée sur le banc sans avoir été ajustée reste un choix raisonné ; la mesure de contrôle est donnée.
- Une clé qu'aucun module de `koach/` ne lit est marquée **Non lue par le moteur** (vérifié par script sur le code du 10/10/2026 : recherche de la chaîne de la clé, hors entrées des dictionnaires de défauts).
- Aucune référence n'est ajoutée à la liste ci-dessous ; aucun résultat du rejeu d'un journal réel n'est cité.

Les scripts cités sont dans `/home/claude/km1-outils/`. `fit_reponse.py` (sur `/tmp/reponse.json`) et `diag_prior.py` ont été réexécutés le 09/10/2026 ; les chiffres donnés en sont tirés.

## Références de la littérature citées

Toutes figurent dans `SOURCES_RECHERCHE.md` avec leur statut, sauf mention contraire.

| Référence | Statut |
| --- | --- |
| Halperin I, Malleron T, Har-Nir I, Androulakis-Korakakis P, Wolf M, Fisher J, Steele J. *Accuracy in predicting repetitions to task failure in resistance exercise: a scoping review and exploratory meta-analysis.* Sports Med 2022;52:377–390. DOI 10.1007/s40279-021-01559-x | vérifié (résumé) |
| Nuzzo JL, Pinto MD, Nosaka K, Steele J. *Maximal number of repetitions at percentages of the one repetition maximum…* Sports Med 2024;54(2):303–321. DOI 10.1007/s40279-023-01937-7 | vérifié (texte) |
| Grgic J, Lazinica B, Schoenfeld BJ, et al. *Test–retest reliability of the one-repetition maximum (1RM) strength assessment: a systematic review.* Sports Med Open 2020;6:31. DOI 10.1186/s40798-020-00260-z | vérifié (résumé) |
| Busso T. *Variable dose-response relationship between exercise training and performance.* Med Sci Sports Exerc 2003;35(7):1188–1195 | vérifié (texte) |
| Morán-Navarro R, et al. *Time course of recovery following resistance training leading or not to failure.* Eur J Appl Physiol 2017;117:2387–2399 | vérifié (texte) |
| McMaster DT, Gill N, Cronin J, McGuigan M. Sports Med 2013;43(5):367–384 | vérifié (résumé) |
| Steele J, et al. Res Q Exerc Sport 2023;94(4):913–930 | vérifié (résumé) |
| Pelland JC, et al. Prépublication SportRxiv 460 v2 (2024) | vérifié (prépublication) |
| Al-Rahamneh H, Eston R. Eur J Appl Physiol 2011;111(6):1055–1062 | vérifié (résumé) |
| Travis SK, Mujika I, Gentles JA, Stone MH, Bazyler CD. Sports 2020;8(9):125 | vérifié (texte) |
| Zourdos MC, Klemp A, Dolan C, Quiles JM, Schau KA, Jo E, Helms E, Esgro B, Duncan S, Garcia Merino S, Blanco R. *Novel resistance training-specific rating of perceived exertion scale measuring repetitions in reserve.* J Strength Cond Res 2016;30(1):267–275. DOI 10.1519/JSC.0000000000001049 | référence vérifiée (dépôt AUT, consulté pour ce document) ; le contenu de l'échelle (« RPE 5–6 = 4–6 RIR ») n'a été lu qu'en **seconde main** (topendsports.com), donc pas utilisé comme source d'une valeur |
| Škarabot J, Cronin N, Strojnik V, Avela J. *Bilateral deficit in maximal force production.* Eur J Appl Physiol 2016;116(11-12):2057–2084. DOI 10.1007/s00421-016-3458-z | référence vérifiée pour ce document (portail Northumbria) ; le résumé ne donne **aucune ampleur chiffrée** du déficit bilatéral, donc pas utilisé comme source du facteur 0,55 |
| Robinson ZP, Pelland JC, Remmert JF, Refalo MC, Jukic I, Steele J, Zourdos MC. Sports Med 2024;54(9):2209–2231. DOI 10.1007/s40279-024-02069-2 | vérifié (résumé : sens) |
| Contexte seulement, statuts dans `SOURCES_RECHERCHE.md` : Busso 1991 (seconde main), Bosquet 2013, Gabbett 2016 (chiffres en seconde main), Impellizzeri 2020, Sperandei 2016 (seconde main), Perri 2002, Remmert 2023 (chiffres en seconde main) | jamais utilisés comme source d'une valeur |
| Méthodes (sans valeur de paramètre) : Adams & MacKay 2007 (BOCPD), de Boer et al. 2005 (entropie croisée), Abadie et al. 2010 (contrôle synthétique), Lillie et al. 2011, Duan et al. 2013 (N-of-1), Russo et al. 2018 (Thompson) | voir `SOURCES_RECHERCHE.md` § 13 |

Les références de Beck & Teboulle 2009 (FISTA), Held, Wolfe & Crowder 1974 et Duchi et al. 2008 (projection sur le simplexe), et Lanczos (fonction gamma) sont citées dans le code mais **n'ont pas été vérifiées** : elles n'y servent qu'à nommer une méthode.

---

## 1. Clés du fichier de paramètres

### Racine du fichier

| Clé | Valeur | Catégorie | Source, mesure ou raison |
| --- | --- | --- | --- |
| `schema` | 1 | choix raisonné | Métadonnée de format ; aucune source requise. |
| `version` | "1.0.0-ref.1" | choix raisonné | Métadonnée ; « 1.0.0-ref.1 » = référence Python du lot KM1. |
| `date` | "2026-10-09" | choix raisonné | Métadonnée. |
| `note` | (texte) | choix raisonné | Métadonnée. |
| `qualites` | ["pousser", "tirer", "jambes", "tronc", "figures", "endurance_force", "explosivite", "aerobie", "anaerobie", "mobilite"] | choix raisonné | **Non lue par le moteur.** Cahier, Méthodes § 2 : « 10 qualités latentes, liste figée dans le contrat de KM1 ». Le choix des dix noms est une décision du lot (SAUVEGARDE, « Architecture décidée »). Lue par le banc ; contrôlée en type seulement à l'import. |
| `classes_reponse` | ["charge", "reps", "tenue", "cardio", "wod"] | choix raisonné | **Non lue par le moteur.** Cahier, Méthodes § 2 (table des types d'exercice). Écart : « Mobilité (2PL) » n'a pas de classe ; « répétitions au poids du corps » en a une (choix du lot). `modele.CLASSES` fait foi ; contrôlée en type seulement à l'import. |

### Section `a_priori`

| Clé | Valeur | Catégorie | Source, mesure ou raison |
| --- | --- | --- | --- |
| `theta_sd` | 0.2 | choix raisonné | ±20 % d'écart commun de l'utilisateur sur une qualité. Calage possible : dispersion inter-profils des écarts a priori ↔ vérité (`km1-outils/diag_prior.py`). |
| `delta_sd` | 0.3 | choix raisonné | A priori volontairement large. Contrôle banc (`diag_prior.py`, vérité A, tirages de départ, exercices chargés non déclarés) : écart a priori − vérité de moyenne +0,03 à +0,09 et de dispersion 0,11 à 0,17 selon le niveau ; 0,30 couvre ces écarts. Pas de calage formel. |
| `delta_sd_declare` | 0.07 | choix raisonné | Contrôle banc (`diag_prior.py`) : dispersion de l'écart déclaré ↔ vérité 0,05 à 0,065 (charges), 0,05 à 0,10 (répétitions). Valeur retenue sans ajustement formel. Sert quand la déclaration ne donne pas son propre écart-type. Relecture m12 : jugée étroite pour un 1RM auto-déclaré sans date ni test (non corrigé). |
| `rho_moyenne_par_niveau` | [0.0095, 0.003, 0.0012, 0.0006] | mesure sur le banc | Ajustement de la réponse vraie sur le banc (`km1-outils/fit_reponse.py` sur `/tmp/reponse.json` produit par `diag_reponse.py`, classe « loaded », modèles A+B+C, n = 4 939 semaines) : ρ par niveau [0,00951 ; 0,00284 ; 0,00107 ; 0,00052] (réexécuté pour ce document), arrondi à [0,0095 ; 0,003 ; 0,0012 ; 0,0006] (SAUVEGARDE, 21:10). Ordre de grandeur cohérent avec la littérature lue (Steele 2023 : +30–50 % la 1re année chez des débutants ; McMaster 2013 : élites ≈ 0,3–0,6 %/mois), qui n'a pas servi au calcul. |
| `rho_sd_rel` | 0.6 | choix raisonné | Incertitude relative de 60 % sur ρ. Calage possible : dispersion de ρ entre profils d'un même niveau dans `fit_reponse.py`. |
| `eps_classe_moyenne` | [0.0, 0.0029, 0.0029, 0.002, 0.001] | choix raisonné | Charge = 0 par construction (classe de référence). Répétitions et tenues 0,0029 : même sens que `fit_reponse.py` (niveau 1 : ρ charge 0,0028, répétitions 0,0077, tenues 0,0065), mais la valeur exacte n'est reproduite par aucun script ni notée dans SAUVEGARDE ; cardio 0,002 et wod 0,001 : aucun ajustement (le script ne traite que charge, répétitions, tenues). À confirmer. |
| `eps_classe_sd` | 0.003 | choix raisonné | Incertitude ≈ valeur des écarts. Calage possible : dispersion inter-profils des ρ par classe. |
| `k_nerveux` | [0.0, 0.0] | mesure sur le banc | Régression de l'effet de jour vrai sur les quatre régresseurs de fatigue (`diag_fatigue.py`, SAUVEGARDE 09/10 « estimation v4 », point 3) : coefficient ≈ 0, d'où [0 ; 0] (figé). |
| `k_musculaire` | [0.0, 0.0] | mesure sur le banc | Même régression : coefficient ≈ 0, d'où [0 ; 0] (figé). |
| `biais_rir_additif` | [0.0, 0.0] | choix raisonné | Cahier, Méthodes § 3 : « Biais initial 0 ». Écart-type 0 (biais figé) : sur le banc, BA n'est pas identifiable séparément de BP (relecture B3). Écart au cahier (« biais appris par utilisateur ») déclaré dans CONTRAT_1_0.md, annexe A.1. |
| `courbe_echelle_exercice_sd` | 0.22 | choix raisonné | SAUVEGARDE (« échelle par exercice, sd 0,23 », puis 0,22). Sens appuyé par Nuzzo et al. 2024 (répétitions à %1RM très différentes selon l'exercice), sans calcul de la valeur. |
| `courbe_bas_du_corps` | -0.2 | choix raisonné | Courbe plus plate pour les polyarticulaires du bas du corps : sens donné par Nuzzo et al. 2024 (80 % du 1RM : 8,8 rép. au développé couché contre 13,1 à la presse, vérifié texte). Avec la branche linéaire, ce rapport donnerait ln((13,1−1)/(8,8−1)) ≈ −0,44 (calcul) ; −0,2 est un choix prudent (la presse n'est pas le squat). |
| `fatigue_intra` | [0.85, 0.0] | mesure sur le banc | Calé sur la fatigue intra-séance du modèle de vérité A (0,85·e^(−repos/160)·e^(−rir/1,4), SAUVEGARDE « Constats sur les modèles de vérité ») ; figé (sd 0). |
| `part_tenue` | [0.1, 0.0] | choix raisonné | 1 répétition de réserve = 10 % du maintien maximal (SAUVEGARDE, point 7). Hypothèse de linéarité de l'effort perçu en fonction de la part du temps limite : étayée en exercice dynamique (Al-Rahamneh & Eston 2011, R² ≥ 0,88, vérifié résumé), non trouvée en isométrique (SOURCES_RECHERCHE § 11) ; figé (sd 0). |
| `niveau_echelle_charge` | [0.65, 1.0, 1.25, 1.45] | choix raisonné | Multiplicateurs de la table de ratios (niveau intermédiaire = 1). Calage possible : `diag_prior.py` (écart moyen par niveau : +0,08, +0,09, +0,03, −0,02 pour les charges non déclarées). |
| `facteur_femme` | 0.7 | choix raisonné | Rapport de force femmes/hommes rapporté au poids du corps ; aucune source lue. Calage : profils féminins du banc. |
| `reps_base` | 12.0 | choix raisonné | 12 répétitions maximales à marge nulle. Contrôle `diag_prior.py` (reps non déclarés : écart moyen −0,07 à +0,01, dispersion 0,13 à 0,26). |
| `tenue_base_s` | 30.0 | choix raisonné | 30 s à marge nulle. `diag_prior.py` : tenues biaisées vers le haut aux niveaux 2 et 3 (−0,10 et −0,15), à recaler. |
| `pente_difficulte` | 0.3 | choix raisonné | ×e^0,3 ≈ 1,35 par point de marge ; aucune source. |
| `reps_sd` | 0.4 | choix raisonné | Large (`diag_prior.py` : dispersion observée 0,13 à 0,28). |
| `cardio_minutes_par_niveau` | [30.0, 60.0, 90.0, 120.0] | choix raisonné | Ordres de grandeur ; aucune source. |
| `cardio_sd` | 0.4 | choix raisonné | Large ; aucune source. |
| `wod_sd` | 0.25 | choix raisonné | Aucune source. |
| `courbe_forme` | [0.3, 0.3] | mesure sur le banc | Banc synthétique `synth2.py` (SAUVEGARDE, point 4) : λ appris retrouve A ≈ 0,4, B ≈ 0, C ≈ 1 ; a priori 0,3 ± 0,3 couvre les trois vérités. |
| `courbe_echelle` | [0.1, 0.0] | mesure sur le banc | Courbe a priori trop plate d'environ 12 % par rapport aux vérités → +0,10 (SAUVEGARDE 09/10 ~19:00, point 3) ; figé. Avec C_LIN, pente effective 0,0265·e^0,1 = 0,0293 ln/rép. (calcul). |
| `biais_rir_proportionnel` | [0.25, 0.15] | mesure sur le banc | Moyenne : biais multiplicatif β du modèle de vérité A, 0,25 ± 0,18 (SAUVEGARDE). Sens (sous-estimation de la réserve, croissante avec la longueur de série) cohérent avec Halperin et al. 2022 (biais moyen 0,95 rép., vérifié résumé). Écart-type 0,15 : choix ; BP est appris par utilisateur depuis le 10/10/2026 (relecture B3 : figé, il ne suivait pas un biais personnel). |
| `k_nerveux_local` | [0.0047, 0.0019] | mesure sur le banc | Régression `diag_fatigue.py` : rapide local (par groupe musculaire) 0,0047 (SAUVEGARDE, point 3). Écart-type 0,0019 : choix (≈ 40 %). |
| `k_musculaire_systemique` | [0.00075, 0.0003] | mesure sur le banc | Même régression : lent systémique 0,00075. Écart-type 0,0003 : choix. |
| `part_tenue_exercice_sd` | 0.2 | choix raisonné | Aucune source. |
| `marge_niveau` | [3.0, 2.0] | choix raisonné | Marge = 3 + 2·niveau − difficulté ; aucune source. |
| `reps_bornes` | [2.0, 60.0] | choix raisonné | Bornes de vraisemblance ; aucune source. |
| `tenue_bornes_s` | [5.0, 180.0] | choix raisonné | Bornes de vraisemblance ; aucune source. |
| `fatigue_intra_exercice_sd` | 0.35 | choix raisonné | ±35 % de sensibilité propre à l'exercice ; aucune source. |

### Section `mesure`

| Clé | Valeur | Catégorie | Source, mesure ou raison |
| --- | --- | --- | --- |
| `bruit_rir_par_niveau` | [2.0, 1.5, 1.0, 1.0] | choix raisonné | Cahier, Méthodes § 3 : « débutant 2,0 reps, intermédiaire 1,5, avancé 1,0 ». Élite = avancé (choix). Lu comme le bruit à la réserve `bruit_rir_reference` (interprétation du lot, voir cette clé). |
| `bruit_rir_pente` | 0.25 | choix raisonné | Bruit décroissant vers l'échec : sens étayé (Halperin 2022, β = −0,025 pour la proximité de l'échec, vérifié résumé ; Remmert 2023, seconde main). Pente choisie ; calage : `diag_calib.py`. |
| `bruit_rir_plancher` | 0.5 | choix raisonné | Bruit à réserve nulle = 0,5/1,75 ≈ 29 % du bruit de référence ; choix. |
| `bruit_rir_longue_serie_de` | 12 | référence publiée vérifiée | Halperin I, Malleron T, Har-Nir I, et al. Sports Med 2022;52:377–390 : effet du nombre de répétitions β = 0,06 jusqu'à 12 rép., 0,47 au-delà (vérifié résumé). |
| `bruit_rir_longue_serie_pente` | 0.08 | choix raisonné | +8 % de bruit par répétition au-delà de 12 ; le β de Halperin n'est pas converti (unités différentes). |
| `bruit_serie` | 0.012 | choix raisonné | **Non lue par le moteur.** Aucune source. |
| `bruit_echec` | 0.01 | choix raisonné | **Non lue par le moteur.** Aucune source. |
| `bruit_test` | 0.008 | choix raisonné | 0,8 % sur ln capacité pour une barre manquée ; aucune source. |
| `bruit_charge_manuelle` | 0.03 | choix raisonné | 3 % ; du même ordre que le CV test-retest du 1RM (Grgic et al. 2020, médiane 4,2 %, vérifié résumé), sans dérivation. |
| `bruit_raison_refus` | 0.12 | choix raisonné | Cahier, Méthodes § 8 : « mesure de capacité faible, à bruit élevé » (qualitatif) ; 12 % choisi. |
| `bruit_tenue` | 0.08 | choix raisonné | Aucune source. |
| `bruit_cardio` | 0.15 | choix raisonné | Aucune source. |
| `bruit_wod` | 0.1 | choix raisonné | Aucune source. |
| `bruit_continu` | 0.08 | choix raisonné | **Non lue par le moteur.** Aucune source. |
| `note_paresseuse_a_priori` | [1.0, 9.0] | mesure sur le banc | Beta(1, 9) de moyenne 10 % = part de notes paresseuses des modèles de vérité (SAUVEGARDE, « notes paresseuses 10 % »). |
| `apprentissage_bruit_oubli` | 0.97 | choix raisonné | Mémoire ≈ 33 séries ; aucune source. |
| `apprentissage_bruit_bornes` | [0.4, 2.5] | choix raisonné | Aucune source. |
| `rir_ouvert` | 4.0 | choix raisonné | Note « 4 ou plus » (SAUVEGARDE). Motifs : vérité B plafonne les notes à 4 ; l'échelle RIR de Zourdos et al. 2016 regroupe « 4–6 RIR » (contenu de l'échelle lu en seconde main seulement, topendsports.com ; la référence elle-même est vérifiée : J Strength Cond Res 2016;30(1):267–275). |
| `cardio_pente_rir` | 4.0 | choix raisonné | Aucune source. |
| `cardio_charge_neutre` | 0.8 | choix raisonné | Aucune source. |
| `cardio_poids_qualite` | 1.25 | choix raisonné | **Non lue par le moteur.** Lue par le banc seulement (`banc/politique_koach.py`). Aucune source. |
| `wod_pente_rir` | 4.0 | choix raisonné | Aucune source. |
| `bruit_rir_endurance` | 0.8 | choix raisonné | Aucune source. |
| `bruit_rir_reference` | 5.0 | choix raisonné | Interprétation du cahier : le bruit 2,0/1,5/1,0 vaut loin de l'échec, à 5 RIR (SAUVEGARDE). Le cahier ne le dit pas. |
| `dispersion_fatigue_intra` | 0.3 | choix raisonné | Aucune source. |
| `note_aberrante` | 0.05 | choix raisonné | 5 % (SAUVEGARDE, point 8) ; aucune source. |
| `porte_note_ouverte` | 1.0 | choix raisonné | Une note ouverte (« 4 en réserve ou plus ») n'est versée que si la prévision est à moins d'un écart-type au-dessus de la borne (relecture B1 : avec la valeur 99, la porte était inactive et l'e1RM dérivait vers le haut chez un athlète qui stagne). Mesure : banc SET9 inchangé ou meilleur ; essai synthétique de plateau (`km1-outils/plateau.py`), surestimation à 24 semaines +5 à +14 % avant, +4 à +7 % après. Valeur 1,0 non ajustée. |
| `note_erreur_grossiere` | [0.08, 2.0] | mesure sur le banc | Modèle de vérité B : 8 % d'erreurs de ±2 (SAUVEGARDE). |
| `noteur_entier_notes_min` | 20 | choix raisonné | SAUVEGARDE 19:50 ; aucune source. |
| `noteur_entier_part_max` | 0.05 | choix raisonné | SAUVEGARDE 19:50 ; aucune source. |
| `defaut_modele_sd` | 0.015 | choix raisonné | Erreur que le filtre gaussien ne voit pas (forme de courbe, densité supposée). Mesure : sans ce terme, couverture de l'intervalle à 90 % de 87 % au rang 6 (SET9, 4 graines, SAUVEGARDE 09/10 ~22:50), sous les 88 à 92 % du cahier. 0,015 est provisoire : à caler sur la campagne de mesure. Elle relève aussi le plancher de la demi-largeur à 2,5 % (CONTRAT, annexe A.1). |

### Section `jour`

| Clé | Valeur | Catégorie | Source, mesure ou raison |
| --- | --- | --- | --- |
| `sigma_seance` | 0.022 | mesure sur le banc | Effet de jour vrai moyen −2,6 %, écart-type 2,8 % (SAUVEGARDE 09/10 ~19:00, point 2) ; √(0,022² + 0,018²) = 0,0284 (calcul). Ordre de grandeur cohérent avec Grgic et al. 2020 (CV test-retest du 1RM, médiane 4,2 %, vérifié résumé). |
| `sigma_exercice` | 0.018 | mesure sur le banc | Partage du même écart-type de 2,8 % entre séance et exercice (voir ci-dessus) ; le partage 0,022/0,018 est un choix. |
| `bilan_par_point` | 0.012 | mesure sur le banc | Régression de l'effet de jour sur le bilan (`diag_fatigue.py`, SAUVEGARDE point 3 : « bilan 0,012/point »). |
| `bilan_neutre` | 4 | repris de 0.3.1 | `healthNeutral` = 4 (inventaire A5.1). |
| `sigma_seance_avec_bilan` | 0.018 | choix raisonné | Un peu plus étroit qu'en l'absence de bilan ; non mesuré. |
| `mauvais_jour_proba` | 0.1 | choix raisonné | Modèle de vérité C du banc : un jour sur dix à −4 % (SAUVEGARDE) ; la probabilité a priori de la branche « mauvais jour » reprend cette fréquence (SAUVEGARDE 09/10 ~22:50). |
| `mauvais_jour_proba_bilan_bas` | 0.45 | choix raisonné | Aucune source. |
| `mauvais_jour_moyenne` | -0.06 | choix raisonné | −6 % ; vérité C : −4 % (SAUVEGARDE). Non calé. |
| `mauvais_jour_sigma` | 0.045 | choix raisonné | Aucune source. |

### Section `fatigue`

| Clé | Valeur | Catégorie | Source, mesure ou raison |
| --- | --- | --- | --- |
| `tau_nerveux_j` | 2.5 | choix raisonné | Cahier, Méthodes § 4 : « nerveux 2,5 j ». Cohérent avec Morán-Navarro et al. 2017 (récupération ≈ 72 h, vérifié texte) et Busso 2003 (τ3 = 2,3 j, vérifié texte). |
| `tau_musculaire_j` | 7.0 | choix raisonné | Cahier, Méthodes § 4 : « musculaire 7 j ». Aucune source directe (SOURCES_RECHERCHE § 6 : encadré par Busso 1991 et 2003, 1,9 à 16,8 j). |
| `tau_tendineux_j` | 28.0 | choix raisonné | Cahier, Méthodes § 4 : « tendineux 28 j ». Aucune constante publiée trouvée (SOURCES_RECHERCHE § 6). |
| `grille_tau_nerveux` | [1.5, 2.5, 4.0] | choix raisonné | **Non lue par le moteur.** Aucune source. |
| `grille_tau_musculaire` | [4.0, 7.0, 10.0] | choix raisonné | **Non lue par le moteur.** Aucune source. |
| `grille_tau_tendineux` | [21.0, 28.0, 42.0] | choix raisonné | **Non lue par le moteur.** Aucune source. |
| `effort_demi_rir` | 2.0 | choix raisonné | Effort ½ à 2 RIR ; aucune source. |
| `echec_supplement` | 0.5 | choix raisonné | Aucune source. |
| `intra_report` | 0.7 | choix raisonné | 0,7^rang (SAUVEGARDE) ; aucune source. |
| `intra_repos_s` | 180.0 | mesure sur le banc | Vérité A : e^(−repos/160) ; arrondi à 180 (SAUVEGARDE). |
| `intra_rir` | 1.5 | mesure sur le banc | Vérité A : e^(−rir/1,4) ; arrondi à 1,5 (SAUVEGARDE). |

### Section `dynamique`

| Clé | Valeur | Catégorie | Source, mesure ou raison |
| --- | --- | --- | --- |
| `q_theta_semaine` | 2e-05 | choix raisonné | Aucune source. |
| `q_delta_semaine` | 0.0001 | choix raisonné | Aucune source. |
| `q_delta_jour_inactif` | 2e-05 | choix raisonné | Aucune source. |
| `desentrainement_grace_j` | 14 | choix raisonné | 14 j ; McMaster et al. 2013 : force maintenue ≈ 3 semaines chez des élites (vérifié résumé) : Koach commence plus tôt (plus prudent). |
| `desentrainement_par_semaine` | 0.01 | choix raisonné | 1 %/sem. ; McMaster 2013 : −14,5 % sur ≈ 7,2 semaines (≈ 2 %/sem., calcul) ; Bosquet 2013 : relation dose-réponse avec la durée. Choix plus lent. |
| `dose_reference` | 6.0 | choix raisonné | 6 unités de stimulus = dose 1 ; fixé aussi dans `fit_reponse.py`. |
| `hypotheses_s0` | [1.5, 2.5, 5.0] | mesure sur le banc | `fit_reponse.py` : meilleurs s0 par classe et par vérité dans {1,5 ; 2,5 ; 5,0} (grille testée {1,5 ; 2,5 ; 5 ; 10}) ; SAUVEGARDE 21:10. Forme saturante cohérente avec Pelland et al. 2024 (rendements décroissants, prépublication, vérifié). |
| `hypotheses_stimulus` | ["volume", "effort", "intensite"] | mesure sur le banc | `fit_reponse.py` : le meilleur stimulus varie selon la classe et la vérité (intensité pour la charge, effort ou volume pour répétitions et tenues) ; les trois sont gardés comme hypothèses. |
| `q_reponse_semaine` | 1e-08 | choix raisonné | Aucune source. |
| `changement_cran_elastique_sd` | 0.25 | repris de 0.3.1 | `coachAssistStepSd` = 0,25 (inventaire A9.3). Le facteur 0,75 (`coachAssistStepShare`) est passé par l'appelant dans l'événement `cran`. |
| `recuperation_seuil` | 8.0 | mesure sur le banc | `fit_reponse.py` (seuil F0, grille {4, 6, 8, 10, 12}) : 6 à 8 selon la classe ; 8 retenu (SAUVEGARDE 21:10). |
| `recuperation_pente` | 0.5 | mesure sur le banc | `fit_reponse.py` (κ, grille {0 ; 0,25 ; 0,5 ; 0,75 ; 1}) : 0,25 à 0,5 ; 0,5 retenu. |
| `recuperation_plancher` | 0.2 | mesure sur le banc | Plancher 0,2 du facteur de récupération du modèle de vérité (`diag_dose.py`, max(0,2 ; …)). |
| `accoutumance_semaines` | 40.0 | mesure sur le banc | `fit_reponse.py` : 40 semaines préféré à « pas d'accoutumance » dans toutes les classes (grille à deux valeurs seulement). |

### Section `test_adaptatif`

| Clé | Valeur | Catégorie | Source, mesure ou raison |
| --- | --- | --- | --- |
| `intervalle_declenchement` | 0.06 | choix raisonné | Cahier, Méthodes § 5 : « intervalle à 90 % de l'e1RM dépasse 6 % » ; lu comme une demi-largeur ±6 % (SAUVEGARDE 18:30). |
| `poids_information` | 0.5 | choix raisonné | **Non lue par le moteur.** Aucune source. |
| `ecart_rir_tolere` | 0.5 | choix raisonné | Zone prescrite = réserve à ±0,5 rép. de la cible (cahier § 5 « dans la zone prescrite », valeur choisie). |
| `jours_min_entre_tests` | 14 | repris de 0.3.1 | `coachProbeDays` = 14 (inventaire A8.3). |
| `reps_ouvertes` | 6 | repris de 0.3.1 | `benchmarkExtraReps` = 6 (inventaire A8.3). |
| `repere_hausse` | 0.1 | repris de 0.3.1 | Même borne que la règle du premier passage à un schéma, `maxUpMain` = 0,10 (inventaire A7.2 règle 5). |
| `test_reps` | 3 | choix raisonné | SAUVEGARDE 18:30 (« 3 intermédiaire »). |
| `test_reps_debutant` | 5 | choix raisonné | SAUVEGARDE 18:30 (« 5 débutant »). |
| `test_rir` | 1.0 | choix raisonné | Aucune source. |
| `test_rir_debutant` | 2.0 | choix raisonné | Aucune source (0.3.1 sert les séries repères des débutants à 2 RIR, A8.3, règle voisine). |
| `test_reps_ouvertes` | 0 | choix raisonné | **Non lue par le moteur.** Aucune source. |
| `rampe_pas` | 0.1 | choix raisonné | Cran > 10 % : pas de montée (SAUVEGARDE, point 5). |
| `rampe_series_max` | 7 | choix raisonné | Aucune source. |
| `repos_test_s` | 180 | choix raisonné | Aucune source. |
| `rampe_pas_par_rir` | [[4.0, 0.075], [3.0, 0.05], [2.5, 0.035], [2.0, 0.025]] | choix raisonné | 7,5/5/3,5/2,5 % (SAUVEGARDE, point 5) ; résultat contrôlé sur le banc (`diag_rampes.py` : réserve vraie finale 1,2–1,9, débutants 2–3), pas ajusté par une mesure. |
| `test_reps_avance` | 1 | choix raisonné | SAUVEGARDE 18:30 (« 1 rép. avancé/élite »). |
| `test_rir_avance` | 1.0 | choix raisonné | Aucune source. |
| `rampe_sd_min` | 0.05 | choix raisonné | Aucune source. |
| `rampe_confirmations` | 2 | choix raisonné | SAUVEGARDE, point 5 (« 2 notes basses »). |
| `rampe_proba_min` | 0.75 | choix raisonné | SAUVEGARDE 19:50 (« garde de probabilité sur la montée (0,75) »). |

### Section `planification`

| Clé | Valeur | Catégorie | Source, mesure ou raison |
| --- | --- | --- | --- |
| `trajectoires` | 1000 | choix raisonné | Cahier, Méthodes § 5 : « 1 000 trajectoires ». |
| `plans_max` | 256 | choix raisonné | Cahier, Méthodes § 5 : « 256 plans évalués au plus » (écart de comptage : CONTRAT, annexe). |
| `iterations` | 4 | choix raisonné | Méthode de l'entropie croisée (de Boer et al. 2005, référence vérifiée) ; nombre choisi. |
| `elite` | 0.25 | choix raisonné | Aucune source. |
| `lissage` | 0.7 | choix raisonné | Aucune source. |
| `plafond_volume` | 0.15 | choix raisonné | Cahier, Méthodes § 6 : « volume par qualité ±15 % ». |
| `plafond_intensite` | 0.05 | choix raisonné | Cahier, Méthodes § 6 : « intensité moyenne ±5 % ». |
| `lambda_transport` | 0.5 | choix raisonné | Le cahier (§ 6) demande « λ calibré sur le banc » : aucun calage n'est documenté (SAUVEGARDE). À caler (balayage de λ sur la matrice de saisons, critère « performance le jour J »). |
| `risque_tendon_ratio_max` | 1.3 | choix raisonné | Rapport 1,3 : rappelle la zone ACWR 0,8–1,3 de Gabbett 2016, chiffres non lus dans la source primaire (seconde main) et critiqués (Impellizzeri 2020) : non cité comme source. |
| `risque_tendon_plancher` | 4.0 | choix raisonné | Aucune source. |
| `horizon_sans_echeance_sem` | 12 | choix raisonné | Cahier, Méthodes § 1 : « P(continuer sur 12 semaines) ». |
| `sigma_prevision_semaine` | 0.004 | choix raisonné | Aucune source. |
| `gain_affutage` | 0.015 | choix raisonné | **Non lue par le moteur.** Travis et al. 2020 donne +1,8 à +6,4 % selon le mouvement, vérifié texte, non utilisé.  |
| `graine` | 20261009 | choix raisonné | Date du lot ; arbitraire. |
| `prudence_charge` | [0.6, 0.25] | choix raisonné | Quantile prudent 0,6 sd puis 0,25 sd après 3 séances ; aucune source. |
| `transport_creation` | 0.25 | choix raisonné | Aucune source. |
| `marge_cible` | 0.0 | choix raisonné | Aucune source. |
| `abandon_hebdo` | 0.01 | choix raisonné | 1 %/sem. Littérature lue (Sperandei 2016 : < 5 % actifs à 12 mois en salle) seulement en seconde main et sur une autre population : non cité. |
| `abandon_surcharge` | 3.0 | choix raisonné | Aucune source (Perri 2002 : adhérence meilleure à intensité modérée, sens seulement). |
| `gain_min` | 0.002 | choix raisonné | Aucune source. |

### Section `securite`

| Clé | Valeur | Catégorie | Source, mesure ou raison |
| --- | --- | --- | --- |
| `hausse_par_niveau` | [0.1, 0.05, 0.05, 0.05] | repris de 0.3.1 | `coachRise` (inventaire A7.2). |
| `hausse_fragile_facteur` | 0.5 | repris de 0.3.1 | `coachHistoryRiseFactor` (inventaire A7.2). |
| `douleur_seuil` | 3 | repris de 0.3.1 | `painThreshold` (inventaire A1.1). |
| `douleur_jours_actifs` | 14 | repris de 0.3.1 | `painClearDays` (inventaire A1.1). |
| `douleur_forte_contrainte` | 4 | repris de 0.3.1 | `painHard` (inventaire A1.3). |
| `douleur_moyenne_contrainte` | 5 | repris de 0.3.1 | `coachPainStop` (inventaire A1.3). |
| `douleur_allegement` | 4 | repris de 0.3.1 | `coachPainRegress` (inventaire A1.4). |
| `douleur_allegement_series` | 0.6 | repris de 0.3.1 | `coachPainRegressSets` (inventaire A1.4). |
| `douleur_rir_bonus` | 1.0 | repris de 0.3.1 | `painRirBonus` (inventaire A1.2). |
| `douleur_remplacant_part` | 0.7 | repris de 0.3.1 | **Non lue par le moteur.** `coachPainSubPct` (inventaire A1.5). Koach retire au lieu de remplacer (CONTRAT § 8.1). |
| `arret_persistance_min` | 3 | repris de 0.3.1 | `painPersistMin` (inventaire A2.1). |
| `arret_persistance_j` | 14 | repris de 0.3.1 | `painPersistDays` (inventaire A2.1). |
| `arret_forte_min` | 5 | repris de 0.3.1 | `painStrongMin` (inventaire A2.1). |
| `arret_forte_j` | 7 | repris de 0.3.1 | `painStrongDays` (inventaire A2.1). |
| `arret_retour_j` | 84 | repris de 0.3.1 | `painRecurDays` (inventaire A2.1). |
| `arret_seances_de_suite` | 3 | repris de 0.3.1 | Constante « ≥ 3 séances de suite » de 0.3.1 (A/model.dart:170-193) (inventaire A2.1 (d)). |
| `arret_levee_j` | 14 | repris de 0.3.1 | `painResumeDays` (et `painEpisodeGapDays`, même valeur) (inventaire A2.1). |
| `arret_escalade_j` | 14 | repris de 0.3.1 | `coachStopEscalateDays` (inventaire A2.2). |
| `reprise_depart` | 0.5 | repris de 0.3.1 | `coachReturnStart` (inventaire A2.2, A3.3). |
| `reprise_pas` | 0.1 | repris de 0.3.1 | `coachReturnStep` (inventaire A3.3). |
| `reprise_plancher` | 0.4 | repris de 0.3.1 | `coachReturnFloor` (inventaire A3.3). |
| `reprise_rir` | 3.0 | repris de 0.3.1 | `coachReturnRir` (inventaire A2.2, A3.3). |
| `reprise_douleur_max` | 2 | repris de 0.3.1 | `coachReturnPain` (inventaire A1.6, A3.3). |
| `reprise_surveillance_j` | 84 | repris de 0.3.1 | `coachReturnWatchDays` (inventaire A3.1). |
| `reprise_charge_base` | 0.675 | repris de 0.3.1 | Constante 0,675 de `_returnLoadAt` (inventaire A2.2, A3.3). |
| `reprise_charge_pente` | 0.25 | repris de 0.3.1 | Constante 0,25 de `_returnLoadAt` (inventaire A3.3). |
| `reprise_hausse_quantite` | 0.1 | repris de 0.3.1 | `coachRecentRise` (inventaire A3.3). |
| `bilan_palier1` | -0.02 | repris de 0.3.1 | `healthLevel1` (inventaire A5.1). |
| `bilan_palier2` | -0.04 | repris de 0.3.1 | `healthLevel2` (inventaire A5.1). |
| `bilan_rir_bonus` | 0.5 | repris de 0.3.1 | `healthRirBonus` (inventaire A5.1, A5.2). |
| `bilan_bas_rir_min` | 3.0 | repris de 0.3.1 | `coachLowDayRir` (inventaire A5.2). |
| `coupure_j` | 14 | repris de 0.3.1 | `coachBreakDays` (inventaire A6.1). |
| `coupure_series` | 0.8 | repris de 0.3.1 | `coachBreakSets` (inventaire A6.1). |
| `tenue_hausse_par_niveau` | [0.2, 0.15, 0.1, 0.1] | repris de 0.3.1 | `coachHoldRise` (inventaire A9.1). |
| `tenue_part_max` | 0.75 | repris de 0.3.1 | `coachHoldMaxShare` (inventaire A9.1). |
| `simple_part_max` | 0.92 | repris de 0.3.1 | Constante 0,92 (A/coach.dart:1276) (inventaire A7.2 règle 7). |
| `simple_part_max_bilan_bas` | 0.85 | repris de 0.3.1 | Constante 0,85 (A/coach.dart:1276) (inventaire A5.2, A7.2 règle 7). |
| `tentative_ouverture_part` | 0.91 | repris de 0.3.1 | `attemptOpenerShare` (inventaire A8.2). |
| `tentative_ouverture_proba` | 0.95 | repris de 0.3.1 | `attemptOpenerProbability` (inventaire A8.2). |
| `tentative_deuxieme_proba` | 0.8 | repris de 0.3.1 | `attemptSecondProbability` (inventaire A8.2). |
| `tentative_troisieme_proba` | 0.5 | repris de 0.3.1 | `attemptThirdProbability` (inventaire A8.2). |
| `tentative_saut_2` | 0.05 | repris de 0.3.1 | Constante +5 % (A/coach.dart:2350-2362) (inventaire A8.2). |
| `tentative_saut_3` | 0.03 | repris de 0.3.1 | Constante +3 % (inventaire A8.2). |
| `tentative_saut_kg` | 5.0 | repris de 0.3.1 | Constante +5 kg (inventaire A8.2). |
| `tentative_bilan_bas_part` | 0.02 | repris de 0.3.1 | `attemptLowHealthShare` (inventaire A8.2). |
| `echec_baisse` | 0.075 | repris de 0.3.1 | × 0,925 du conseil (A/coach_advice.dart:244-305) (inventaire A7.4). |
| `echecs_arret` | 2 | repris de 0.3.1 | « 2 échecs non prévus → stop_exercise » (mode 0.1) (inventaire A7.4). |
| `endurance_pic` | 0.1 | repris de 0.3.1 | `enduranceSpike` (inventaire A10.3). |
| `endurance_pic_jours` | 30 | repris de 0.3.1 | `enduranceSpikeDays` (inventaire A10.3). |
| `endurance_pic_courses_min` | 3 | repris de 0.3.1 | `enduranceSpikeMinRuns` (inventaire A10.3). |
| `endurance_reprise` | [[7, 0.7], [14, 0.5]] | repris de 0.3.1 | `enduranceResumeShortDays/Short, enduranceResumeLongDays/Long` (inventaire A10.1). |
| `endurance_mauvais_jour` | 0.7 | repris de 0.3.1 | `enduranceBadDayShare` (inventaire A10.2). |
| `wod_jours_durs` | 2 | repris de 0.3.1 | `wodHardStreak` (inventaire A10.4). |
| `wod_echelle` | 0.75 | repris de 0.3.1 | `wodScaleShare` (inventaire A10.4). |
| `plafond_hebdo_par_niveau` | [12, 20, 25, 30] | repris de 0.3.1 | **Non lue par le moteur.** coachWeeklyCeilingSets (inventaire A11 ; critère du banc B3). Critère de sécurité de `kalis_bench` (partie B de l'inventaire), couple validé avec 0.3.1 ; le validateur injecté l'applique, en constantes du banc. |
| `volume_hausse` | 0.2 | repris de 0.3.1 | **Non lue par le moteur.** volumeRise du banc (inventaire B2). Critère de sécurité de `kalis_bench` (partie B de l'inventaire), couple validé avec 0.3.1 ; le validateur injecté l'applique, en constantes du banc. |
| `volume_hausse_series` | 2 | repris de 0.3.1 | **Non lue par le moteur.** volumeRiseSets du banc (inventaire B2). Critère de sécurité de `kalis_bench` (partie B de l'inventaire), couple validé avec 0.3.1 ; le validateur injecté l'applique, en constantes du banc. |
| `volume_hausse_2sem` | 0.3 | repris de 0.3.1 | **Non lue par le moteur.** volumeRiseTwoWeeks du banc (inventaire B2). Critère de sécurité de `kalis_bench` (partie B de l'inventaire), couple validé avec 0.3.1 ; le validateur injecté l'applique, en constantes du banc. |
| `volume_hausse_2sem_series` | 4 | repris de 0.3.1 | **Non lue par le moteur.** volumeRiseTwoWeeksSets du banc (inventaire B2). Critère de sécurité de `kalis_bench` (partie B de l'inventaire), couple validé avec 0.3.1 ; le validateur injecté l'applique, en constantes du banc. |
| `decharge_part` | 0.7 | repris de 0.3.1 | **Non lue par le moteur.** seuil 0,70 du banc (inventaire B11). Critère de sécurité de `kalis_bench` (partie B de l'inventaire), couple validé avec 0.3.1 ; le validateur injecté l'applique, en constantes du banc. |
| `decharge_max_semaines` | [12, 7, 6, 6] | repris de 0.3.1 | **Non lue par le moteur.** seuils [12 ; 7 ; 6 ; 6] du banc (inventaire B11). Critère de sécurité de `kalis_bench` (partie B de l'inventaire), couple validé avec 0.3.1 ; le validateur injecté l'applique, en constantes du banc. |
| `affutage_baisse` | [0.3, 0.3, 0.4, 0.4] | repris de 0.3.1 | **Non lue par le moteur.** seuils [0,30 ; 0,30 ; 0,40 ; 0,40] du banc (inventaire B12). Critère de sécurité de `kalis_bench` (partie B de l'inventaire), couple validé avec 0.3.1 ; le validateur injecté l'applique, en constantes du banc. |
| `seance_tolerance` | 1.15 | repris de 0.3.1 | **Non lue par le moteur.** × 1,15 du banc (inventaire B10). Critère de sécurité de `kalis_bench` (partie B de l'inventaire), couple validé avec 0.3.1 ; le validateur injecté l'applique, en constantes du banc. |
| `seance_tolerance_min` | 3.0 | repris de 0.3.1 | **Non lue par le moteur.** +3 min du banc (inventaire B10). Critère de sécurité de `kalis_bench` (partie B de l'inventaire), couple validé avec 0.3.1 ; le validateur injecté l'applique, en constantes du banc. |
| `couloir_haut_max` | 0.15 | repris de 0.3.1 | `coachCorridorUpMax` (inventaire A7.2). |
| `couloir_part_lourde` | 0.85 | repris de 0.3.1 | `coachCorridorHeavyShare` (inventaire A7.2). |
| `schema_change_part` | 0.025 | repris de 0.3.1 | `coachRepLoadShare` (inventaire A7.2 règle 4). |
| `schema_change_reps_max` | 4 | repris de 0.3.1 | `coachRepGapMax` (inventaire A7.2 règle 4). |
| `barre_recente_j` | 42 | repris de 0.3.1 | `attemptRecentDays` (inventaire A7.2 règle 5, A8.2). |
| `premiere_hausse` | 0.1 | repris de 0.3.1 | `maxUpMain` (inventaire A7.1, A7.2 règle 5). |
| `reprise_dose_depart` | 0.6 | mesure sur le banc | Règle propre à Koach, plus prudente que 0.3.1 : budget hebdomadaire de séries par zone en reprise (départ 0,6 × habitude). Banc, scénarios douleur_coude/epaule (162 saisons) : poussées 69 → 0 (SAUVEGARDE 19:50). |
| `reprise_dose_hausse` | 0.25 | mesure sur le banc | Même règle : +25 % ou +1 série par semaine de charge. Même mesure (poussées 69 → 0). |
| `tentative_recente_part` | 0.85 | repris de 0.3.1 | Constante 0,85 (A/coach.dart:2329) (inventaire A8.2). |
| `fragile_anciennetes` | ["under_6_weeks", "weeks_6_to_12", "months_3_to_12"] | repris de 0.3.1 | `ConstraintSince.under6Weeks`, `weeks6To12`, `months3To12` (A/replay.dart:42-51) (inventaire A7.2). |
| `fragile_gene_min` | 2 | repris de 0.3.1 | `l.discomfort >= 2` (A/replay.dart:48) (inventaire A7.2). |
| `fragile_niveau_min` | 0.5 | repris de 0.3.1 | `info.zoneLevel(zone) >= 0.5` (A/replay.dart:120-125) (inventaire A7.2). |
| `surcharge_fragile_max` | 1.0 | repris de 0.3.1 | `coachOverloadFragileMax` (A/params.dart:139 ; A/coach.dart:1039-1042) (inventaire A7.2 règle 8). |
| `poignet_gene_j` | 14 | repris de 0.3.1 | `reportsBetween(day - 13, day)` de `wristGeneRecent` (A/session.dart:2456-2460) (inventaire A4.1). |
| `poignet_chaud_j` | 7 | repris de 0.3.1 | `reportsBetween(day - 6, day)` de `wristStopHot` (A/session.dart:2876-2891) (inventaire A4.2). |
| `poignet_sensible_min` | 1 | repris de 0.3.1 | `r >= 1` de `wristSensitive` (A/session.dart:1709-1713) (inventaire A4.3). |
| `poignet_sensible_j` | 14 | repris de 0.3.1 | `reportsBetween(day - 13, day)` de `wristSensitive` (A/session.dart:1709) (inventaire A4.3). |
| `poignet_appui_neutre_materiel` | ["parallettes", "poignées"] | repris de 0.3.1 | `_wristNeutralEquipment` (A/session.dart:2450) (inventaire A4.1, A4.2). |
| `technique_niveau_acces` | {"top_set_backoff": 1, "drop_set": 1, "amrap": 1, "pyramid": 1, "ladder": 1, "density": 1, "for_time": 1, "cluster": 2, "rest_pause": 2, "myo_reps": 2, "accentuated_eccentric": 2, "contrast": 2, "wave": 2} | repris de 0.3.1 | `techniqueAccessLevel` (A/coach.dart:123-142) (inventaire A9.2). |
| `techniques_intensives` | ["rest_pause", "myo_reps", "drop_set", "accentuated_eccentric", "amrap", "cluster", "wave", "contrast"] | repris de 0.3.1 | `techniqueIntensifies` (A/coach.dart:147-155) (inventaire A9.2). |
| `excentrique_echeance_j` | 10 | repris de 0.3.1 | `coachEccentricEventDays` (A/params.dart:184) (inventaire A9.2). |
| `tenue_hausse_marge_s` | 1 | repris de 0.3.1 | `coachHoldRiseSlackSeconds` (A/params.dart:168 ; A/coach.dart:1853, 1901) (inventaire A9.1). |
| `coupure_fenetre_j` | 7 | repris de 0.3.1 | `digests[i].day < day - 7` (A/session.dart:1103) (inventaire A6.1). |
| `renvoi_periode_j` | 7 | repris de 0.3.1 | `(day - start) ~/ 7` de `_stopNoticeDue` (A/session.dart:2419) (inventaire A2.2). |
| `surmenage_baisse` | 0.05 | repris de 0.3.1 | `coachOverreachDrop` (A/params.dart:143) (inventaire A6.2). |
| `surmenage_jours` | 7 | repris de 0.3.1 | `coachOverreachDays` (A/params.dart:144) (inventaire A6.2). |
| `surmenage_fenetre_j` | 21 | repris de 0.3.1 | `coachOverreachSpanDays` (A/params.dart:145) (inventaire A6.2). |
| `surmenage_coupe` | 0.4 | repris de 0.3.1 | `coachOverreachCut` (A/params.dart:146) (inventaire A6.2). |
| `endurance_materiel_course` | ["piste ou terrain extérieur", "tapis de course", "côte ou escaliers"] | repris de 0.3.1 | `runningEquipment` (A/endurance.dart:34-38) (inventaire A10). |
| `endurance_qualite_ids` | ["fractionne", "seuil", "tempo", "30-30", "sprint", "cotes", "fartlek", "intervalles", "navettes", "accelerations"] | repris de 0.3.1 | `qualityRunIds` (A/endurance.dart:42-53) (inventaire A10.2). |
| `endurance_qualite_rir` | 3.0 | repris de 0.3.1 | `enduranceQualityRir` (A/params.dart:220) (inventaire A10.2). |
| `endurance_facile_rir` | 5.0 | repris de 0.3.1 | `enduranceEasyRir` (A/params.dart:221) (inventaire A10.2, A10.3). |
| `endurance_vitesse` | 2.6 | repris de 0.3.1 | `enduranceRunSpeed` (A/params.dart:222) (inventaire A10.3). |
| `endurance_douleur_jambe` | 3 | repris de 0.3.1 | `enduranceLegPain` (A/params.dart:223) (inventaire A10.2). |
| `endurance_dure_flammes` | 8 | repris de 0.3.1 | `enduranceHardFlames` (A/params.dart:219) (inventaire A10.2, A10.4, A10.5). |
| `endurance_dure_marge` | 2 | repris de 0.3.1 | `enduranceHardMargin` (A/params.dart:217) (inventaire A10.2). |
| `endurance_dure_jours` | 3 | repris de 0.3.1 | `enduranceHardDays` (A/params.dart:218) (inventaire A10.2). |
| `endurance_course_facile` | {"tapis": "ca-course-tapis-endurance", "defaut": "ca-footing-endurance-fondamentale"} | repris de 0.3.1 | `easyRunFor` (A/endurance.dart:383-390) (inventaire A10.2). |
| `endurance_facile_min_s` | 60 | repris de 0.3.1 | `work >= 60` (A/session.dart:2662) (inventaire A10.2). |
| `endurance_bornee_reduction` | 0.9 | repris de 0.3.1 | `scaled(longestDraft.item, 1, 0.9)` (A/session.dart:2800) (inventaire A10.3). |
| `wod_fenetre_j` | 7 | repris de 0.3.1 | `while (d >= day - 7)` de `conditioningStreak` (A/endurance.dart:262) (inventaire A10.4). |
| `retour_seances_avant_mesure` | 2 | choix raisonné | Règle propre à Koach, plus prudente que 0.3.1 (relecture B2) : après une coupure ≥ `coupure_j`, ni vrai test ni série repère pendant la semaine du retour ni avant 2 séances de l'exercice depuis le retour ; aucune source chiffrée. |

### Section `adherence`

| Clé | Valeur | Catégorie | Source, mesure ou raison |
| --- | --- | --- | --- |
| `a_priori_poids_sd` | 1.5 | choix raisonné | Aucune source. |
| `biais_initial` | 1.0 | choix raisonné | P(acceptation) a priori élevée ; aucune source. |
| `pas_min` | 0.5 | choix raisonné | Aucune source. |
| `proba_cible` | 0.7 | choix raisonné | Aucune source. |
| `refus_silence_j` | 0 | choix raisonné | **Non lue par le moteur.** Présente dans `DEFAUTS_ADHERENCE`, jamais lue. |
| `paliers_max` | 4 | choix raisonné | Aucune source. |
| `ampleur_echelle` | 4.0 | choix raisonné | Aucune source. |
| `ampleur_borne` | 3.0 | choix raisonné | Aucune source. |
| `refus_recents_j` | 14 | choix raisonné | Aucune source. |
| `refus_recents_echelle` | 5.0 | choix raisonné | Aucune source. |

### Section `rupture`

| Clé | Valeur | Catégorie | Source, mesure ou raison |
| --- | --- | --- | --- |
| `hasard` | 0.02 | choix raisonné | Durée moyenne d'un régime 50 séances (Adams & MacKay 2007, méthode) ; valeur choisie. |
| `alerte` | 0.6 | choix raisonné | Cahier, Méthodes § 9 : « Alerte si P(rupture) dépasse 0,6, seuil calibré sur le banc ». Banc (`banc/validation_koach.py`, `donnees/validation_briques_6_7.json`) : 0,77 fausse alerte par 100 séances (SAUVEGARDE 21:10). |
| `fenetre` | 3 | choix raisonné | **Non lue par le moteur.** Valeur initiale du fichier, remplacée par `fenetre_seances` ; présente dans `DEFAUTS_RUPTURE`. |
| `a_priori_moyenne_sd` | 2.0 | choix raisonné | Aucune source. |
| `residu_secours` | 0.05 | choix raisonné | Cahier, Méthodes § 9 : « résidu d'e1RM supérieur à 5 % ». La grandeur moyennée par le code n'est pas un résidu (relecture M8, CONTRAT annexe A.2). Banc : actif 39 % des semaines dans une version antérieure (SAUVEGARDE 21:10). |
| `residu_secours_semaines` | 2 | choix raisonné | Cahier, Méthodes § 9 : « deux semaines de suite ». |
| `assiduite_secours` | 0.7 | choix raisonné | Cahier, Méthodes § 9 : « assiduité sous 70 % ». |
| `assiduite_secours_semaines` | 2 | choix raisonné | Cahier, Méthodes § 9 : « sur 2 semaines ». |
| `douleur_secours` | 2 | choix raisonné | Cahier, Méthodes § 9 : « douleur supérieure à 2/10 ». |
| `elargissement_rien_de_special` | 4.0 | choix raisonné | Cahier § 9 « incertitude élargie » (qualitatif) ; ×4 choisi. |
| `semaine_allegee_series` | 0.6 | repris de 0.3.1 | `deloadVolumeFactor` = 0,6 de kalis_plan (inventaire A6.3). |
| `semaine_allegee_rir` | 2.0 | repris de 0.3.1 | `deloadRirBonus` = 2 de kalis_plan (inventaire A6.3). |
| `a_priori_alpha` | 2.0 | choix raisonné | Aucune source. |
| `a_priori_beta` | 1.0 | choix raisonné | Variance attendue 1 (résidus normalisés). |
| `a_priori_alpha_nouvelle` | 5.0 | choix raisonné | Aucune source. |
| `course_max` | 200 | choix raisonné | Troncature numérique. |
| `min_observations` | 6 | choix raisonné | Aucune source. |
| `fenetre_seances` | 10 | mesure sur le banc | Banc (commentaire de `Bocpd.depuis_params`, SAUVEGARDE 18:27) : détection en moins de 6 séances ≈ 88 % avec 10 contre ≈ 54 % avec 3. |
| `silence_semaines` | 2 | choix raisonné | Aucune source. |
| `journal_dossier` | 60 | choix raisonné | Taille du dossier. |
| `douleur_recente_j` | 7 | choix raisonné | Même fenêtre de 7 jours que la règle A1.6 de 0.3.1. |
| `residu_reps_reference` | 8.0 | choix raisonné | 8 répétitions = point où les deux branches de la courbe sont égales (C_LOG). Sert à `_residu_e1rm`, chemin jamais pris avec le modèle (CONTRAT, annexe A.2, M8). |

### Section `controle_dual`

| Clé | Valeur | Catégorie | Source, mesure ou raison |
| --- | --- | --- | --- |
| `semaines_min` | 8 | choix raisonné | Cahier, Méthodes § 7 : « 8 semaines de journal au moins ». |
| `intervalle_max` | 0.06 | choix raisonné | Cahier, Méthodes § 7 : « intervalle à 90 % de l'e1RM sous 6 % ». |
| `bras_semaines` | 3 | choix raisonné | Cahier, Méthodes § 7 : « bras de 3 semaines ». |
| `synthetique_semaines_min` | 6 | choix raisonné | Cahier, Méthodes § 7 : « au moins 6 semaines avant l'intervention ». |
| `synthetique_iterations` | 200 | choix raisonné | Nombre fixe d'itérations FISTA (Beck & Teboulle 2009, méthode). |
| `amplitude_volume` | 0.1 | choix raisonné | Dans le plafond de 15 % du cahier § 6 ; valeur choisie. |
| `amplitude_intensite` | 0.03 | choix raisonné | Dans le plafond de 5 % du cahier § 6 ; valeur choisie. |
| `sigma_progres` | 0.01 | choix raisonné | Aucune source. |
| `plancher_poids` | 1e-06 | choix raisonné | Numérique. |
| `a_priori_effet_sd` | 0.005 | choix raisonné | Aucune source. |
| `marge_echeance_semaines` | 6 | choix raisonné | Aucune source. |
| `seuil_decision` | 0.8 | choix raisonné | Aucune source. |
| `n_bras` | 4 | choix raisonné | ABBA/BAAB (Lillie 2011, Duan 2013 : méthode) ; nombre choisi. |
| `sigma_innovation` | 0.003 | choix raisonné | Aucune source. |
| `semaines_gardees` | 26 | choix raisonné | Mémoire. |

---

## 2. Constantes chiffrées écrites dans le code

Ces constantes ne sont pas dans le fichier de paramètres. Elles sont citées par fichier et fonction (sans numéro de ligne).

### 2.1 `koach/modele.py`

| Constante | Valeur | Catégorie | Source ou raison |
| --- | --- | --- | --- |
| `C_LIN` | 0,0265 ln/rép. | choix raisonné | Pente de la branche linéaire. Cohérente avec Nuzzo et al. 2024 (90 % ≈ 5 rép. : −ln 0,9/4 = 0,0263 ; 70 % ≈ 15 rép. : −ln 0,7/14 = 0,0255, calculs) ; l'origine exacte de 0,0265 n'est pas documentée. Plus plate que Brzycki (≈ 0,028 à 0,032) et Epley (≈ 0,028), calculs ; ramenée à 0,0293 par `courbe_echelle`. |
| `C_LOG` | 0,0892 | choix raisonné | Définie par l'égalité des branches à 8 rép. : 0,0265·7/ln 8 = 0,08921 (calcul). Avec e^0,1 : 0,0986 ≈ exposant 0,10 de Lombardi (formule lue en seconde main, `SOURCES_RECHERCHE` § 2). |
| `NGR` | 17 groupes | repris de 0.3.1 | Les 17 groupes musculaires de `kalis_plan`, repris par `regles.GROUPES`. Hors inventaire A. |
| `ZONES_TENDON` | 7 zones | choix raisonné | Articulations des contraintes du catalogue `kalis_core`. |
| Taille initiale de l'état (`Modele.__init__`) | 28 + 3·48 = 172 | choix raisonné | Allocation ; sans effet sur les valeurs. |
| Poids par défaut (`Modele.__init__`) | 72 kg | choix raisonné | Même défaut que le banc ; pris sans signalement (relecture m14). |
| Plancher de capacité d'une charge (`base_de`) | `fraction·poids·1,1` | choix raisonné | Le 1RM total dépasse au moins le poids porté. |
| Plancher de variance de δ_e (`piste`) | (0,5·sd)² | choix raisonné | Garde une part propre à l'exercice. |
| Bornes de la courbe : λ ∈ [−0,3 ; 1,2], k ∈ [−1 ; 1] (`courbe`, `_projeter`) | — | choix raisonné | Bornes de sûreté numérique. |
| `reps_a` : `1 + 20x` si −0,05 < x ≤ 0, 12 pas de Newton, R ∈ [1 ; 200] | — | choix raisonné | Prolongement sous la charge maximale ; nombre de pas fixe pour la portabilité. |
| Plancher de `_dg` | 0,004 | choix raisonné | Évite une pente nulle. |
| FI ∈ [0 ; 1,5], φ_e ∈ [−1,5 ; 1,5], garde ≥ 0,3 (`fatigue_intra_de`, `garde_de`) | — | choix raisonné | Bornes de sûreté. |
| BA ∈ [−2,5 ; 2,5], BP ∈ [−0,2 ; 1] (`_lin_force`, `_lin_tenue`, `rir_vrai`) | — | choix raisonné | Bornes de sûreté. |
| HH ∈ [0,03 ; 0,30], part ≤ 3 (`_lin_tenue`) | — | choix raisonné | Bornes de sûreté. |
| Repos par défaut, si absent (`_serie_force`, `_serie_tenue`) | 90 s | choix raisonné | Défaut usuel ; un repos de 0 s est gardé. |
| `rir_c` d'une tenue sans note (`_serie_tenue`) | 2 | choix raisonné | — |
| Bruit d'une série sans note ou ratée (`_bruit_force`) | 0,35 rép. | choix raisonné | Mesure en réserve vraie, sans biais de perception. |
| Réserve bornée à 8 pour le bruit | 8 | choix raisonné | — |
| Répétitions de référence du bruit d'une tenue (`_serie_tenue`) | 6 | choix raisonné | — |
| Apprentissage du bruit : z² ≤ 9, z2_n > 12, gain 0,02 (`_apprendre_bruit`) | — | choix raisonné | — |
| Paresse bornée à [0,01 ; 0,9] ; note aberrante répartie sur 10 flammes (`_serie_force`, `_serie_tenue`) | — | choix raisonné | 10 flammes possibles. |
| Seuil de grande surprise, dichotomies (`_observer`) | 1,0 ; 12 | choix raisonné | SAUVEGARDE, « estimation v4 », point 1 (cause de dérive trouvée sur `synth2.py`). Covariance du pas raccourci par la forme de Joseph (facteur 2α − α²), relecture m1. |
| Composantes considérées d'une série sans note (`_serie_force`) | λ et κ_e (charge), λ (reps) | choix raisonné | SAUVEGARDE 09/10 ~22:50 : une série sans note dit que la capacité est plus haute, pas quelle est la forme de la courbe. |
| Résidu d'e1RM : pistes chargées vues ≥ 3 séances (`debut_exercice`) | 3 | choix raisonné | — |
| Séance d'endurance écourtée : capacité < demande/1,3 (`_serie_endurance`) | 1,3 | choix raisonné | — |
| Réserve visée d'endurance sans flammes (`_serie_endurance`) | 5 (cardio), 2 (wod) | choix raisonné | — |
| Effort d'une série d'endurance sans note (`_serie_endurance`) | 0,6 | choix raisonné | — |
| Stimulus : volume 1 si réserve ≤ 4, sinon 0,5 (`_stimulus`) | — | repris de 0.3.1 | Série « dure » = RIR ≤ 4 (critère du banc, inventaire B0) ; le demi-crédit au-delà est un choix. |
| Stimulus : effort 1/(1 + max(rir − 1, 0)/3) (`_stimulus`) | — | choix raisonné | Forme cohérente avec Robinson et al. 2024 (hypertrophie meilleure près de l'échec ; force : relation négligeable), sans dérivation. |
| Stimulus : intensité clamp((part − 0,4)/0,4 ; 0,2 ; 1,5) (`_stimulus`) | — | choix raisonné | — |
| Variance du désentraînement (`fin_semaine`) | (0,5·baisse)² | choix raisonné | — |
| z de l'intervalle à 90 % (`intervalle`) | 1,6448536269514722 ; sinon `norm_ppf(0,5 + niveau/2)` | — | Quantiles exacts de la loi normale (pas un paramètre). |

**Fatigue intra-séance.** La fonction `exp(−rir/intra_rir)·exp(−repos/intra_repos_s)·intra_report^rang` reprend la forme du modèle de vérité A du banc (porté de `kalis_bench`, `banc/verite.py`) : 0,85·e^(−repos/160)·e^(−rir/1,4). Voir les clés `fatigue.intra_*` et `a_priori.fatigue_intra` (mesure sur le banc).

### 2.2 `koach/numerique.py`

| Constante | Valeur | Catégorie | Raison |
| --- | --- | --- | --- |
| Série de l'erfc : 80 termes si \|x\| < 2 ; fraction continue de 200 étages | — | choix raisonné | Algorithme numérique ; précision relative ≈ 1e-15 annoncée par le code. |
| Coefficients d'Acklam, seuil 0,02425, un pas de Halley | — | choix raisonné | Algorithme numérique usuel du quantile normal ; source primaire non vérifiée. |
| `interval_moments` : masse < 1e-280 → mise à jour ponctuelle, logZ = −640 ; v' ≥ 1e-12·v | — | choix raisonné | Garde-fous numériques. |
| `category_moments` : 52 pas de base (104 intervalles), 6,5 écarts-types, fenêtre [a − 8T ; b + 8T], pas ≤ la moitié de la largeur de la vraisemblance, 1 200 intervalles au plus, vz ≥ 1e-12 | — | choix raisonné | Quadrature des trapèzes à pas choisi sur la vraisemblance (relecture M4), contrôlée contre une quadrature dense. |
| `cholesky_semi` : pivot annulé sous 1e-12 × la plus grande diagonale | 1e-12 | choix raisonné | Garde-fou numérique d'une covariance semi-définie. |
| `arrondi` : `floor(x·10ⁿ + 0,5)/10ⁿ` | — | choix raisonné | Arrondi portable (demi vers le haut) à la place de `round` de Python. |
| `gauss` : u ≥ 1e-12 | — | choix raisonné | Évite Φ⁻¹(0). |
| mulberry32 (`0x6D2B79F5`, décalages 15/7/14, `\|1`, `\|61`) ; fnv1a32 (`0x811C9DC5`, `0x01000193`) | — | repris de 0.3.1 | Même générateur que L7 et le banc (cahier, Contraintes : « graines fixes (mulberry32, comme L7) ») ; constantes standard de FNV-1a. |

### 2.3 `koach/securite.py`

| Constante | Valeur | Catégorie | Source |
| --- | --- | --- | --- |
| `palier_bilan` : −0,015 par point sous 4 ; −0,01 par heure de sommeil sous 6 h (≤ 3 h) ; −0,01 par réponse ≤ 2 ; part du détail 0,5 ; plancher −0,08 ; overall ≤ 1 → palier 2, ≤ 2 → palier 1 | — | repris de 0.3.1 | `healthPerPoint`, `healthNeutral`, `sleepHoursNeutral`, `sleepPerHour`, `detailPerItem`, `detailShare`, `healthFloor` (inventaire A5.1). |
| Épisode « réel » : ≥ 2 signalements ou un ≥ 4 (`_arrets`) | 4 | repris de 0.3.1 | Inventaire A2.1 (c). |
| Une semaine compte si la levée lui laisse ≥ 4 jours (`_semaines_de_charge`) | 4 j | repris de 0.3.1 | Inventaire A3.1. |
| Fenêtre des 7 derniers jours (`jour − 6` : `reprise`, `signalee_semaine`, `conduite`) | 7 j | repris de 0.3.1 | Inventaire A1.6, A2.2, A3.3. |
| `SEMAINES_VERROUILLEES` | intro, deload, taper, test, competition, transition | repris de 0.3.1 | `WeekPolicy` (inventaire A6.5). |
| `ZONES_BAS`, `POIGNET` | hip, thigh, knee, lower_leg, ankle_foot ; wrist_hand | repris de 0.3.1 | Zones du bas du corps et du poignet des règles A2.3, A4, A10.2. |

### 2.4 `koach/seance.py`

| Constante | Valeur | Catégorie | Source ou raison |
| --- | --- | --- | --- |
| Réserve des séries repères (`_repere`) | 1,5 ; 2 (débutant) | repris de 0.3.1 | `benchmarkRir` = 1,5 ; 2 pour un débutant (inventaire A8.3). |
| Échéance proche (`_mesure_utile`) | ≤ 14 j | repris de 0.3.1 | `coachEventNearDays` (inventaire A6.5). |
| D'une série à l'autre : +5 % / −15 % (`_cible_charge`, `borne_externe`) | — | repris de 0.3.1 | `maxUpSet`, `maxDownSet` (inventaire A7.4). |
| Réserve par défaut sans flammes (`rir_cible`) | 2,5 | choix raisonné | — |
| Plafond de réserve (`rir_cible`) | 5 | repris de 0.3.1 | Plafond RIR 5 (inventaire A1.2). |
| Plancher de séries au palier 2 (`_item`) | 3 (principal), 2 | repris de 0.3.1 | Inventaire A5.2. |
| Calibrage : aucune mesure et σ > 0,12 (`_cible_charge`) | 0,12 | choix raisonné | Analogue au calibrage de 0.3.1 (`calibrationSd` 0,06, A7.1), valeur différente. |
| Gain d'information minimal (`_cible_charge`) | +2 % | choix raisonné | — |
| Chute de charge par défaut d'une série de tête (`_cible_charge`) | 0,08 | choix raisonné | — |
| Prudence de la série repère ; de la montée ; du test xRM | 0,5 ; 0,5 ; 0,25 sd | choix raisonné | — |
| Fenêtre de la barre récente de la série repère (`_cible_charge`) | 42 j | repris de 0.3.1 | `attemptRecentDays` (inventaire A7.2) ; codée en dur ici. |
| Plage étendue (`_cible_reps`) | ≤ 2·haut, ≤ 30 | repris de 0.3.1 | Inventaire A7.3. |
| Prévision sûre : e^(−σ/2), +0,3 (`_cible_reps`, `_cible_tenue`) | — | repris de 0.3.1 | `⌊capacité − RIR + 0,3⌋` (inventaire A7.3, A9.4) ; le facteur e^(−σ/2) est un choix. |
| Série repère en répétitions (`_cible_reps`) | ≤ 60 | choix raisonné | — |
| Tenue : fraction ≥ 0,15 (`secondes_prevues`) | — | choix raisonné | — |
| Tenue repère (`_cible_tenue`) | ≤ 180 s | choix raisonné | — |
| Séries de l'item de test (`prescrire`) | `rampe_series_max` + 2 si 1 rép. | choix raisonné | — |
| Montée : réserve affichée (`_rampe`) | 2 | choix raisonné | SAUVEGARDE, point 5 (« sinon l'athlète simulé s'arrête avant les répétitions »). |
| Montée : réserve atteinte si dite ≤ rir + 0,75 (`_rampe`) | 0,75 | choix raisonné | — |
| Montée : borne haute μ + 2,5σ (`_rampe`) | 2,5 | choix raisonné | — |
| Montée : départ à réserve + 2 (`_rampe`) | 2 | choix raisonné | — |
| Tentatives : flammes 7, 9, 10 (`_tentative`) | — | repris de 0.3.1 | Inventaire A8.2. |
| Tentatives : σ ≥ 0,01 (`_tentative`) | — | repris de 0.3.1 | `max(relSd, 0,01)` (inventaire A8.2). |
| Tentatives : cible tentée si P ≥ 0,35 (`_tentative`) | 0,35 | repris de 0.3.1 | `attemptRecordProbability` (inventaire A8.2). |
| Tentatives : même barre si P < 0,2 (`_tentative`) | 0,2 | choix raisonné | — |
| Haltères : pas de 2 kg au-delà de 10 kg (`Grille`) | — | repris de 0.3.1 | Règle de grille de `kalis_core`, que le banc reprend. |
| Tolérance de grille (`Grille.EPS`) | 1e-9 | choix raisonné | Numérique. |
| Jours de séance gardés (`fermer`) | 20 | choix raisonné | Mémoire suffisante pour la règle de coupure. |
| Historique d'endurance (`_fermer_endurance`) | 60 j | choix raisonné | Couvre la plus longue fenêtre des règles A10 (30 j). |
| Réduction d'une ligne d'endurance (`reduire`) : minute au-delà de 300 s, sinon 5 s ; 100 m ; une répétition ; une calorie | — | repris de 0.3.1 | `scaled` (A/endurance.dart:310-381), selon la note de couverture. |
| Itérations de la borne de course (`_endurance`) | 50 au plus | choix raisonné | Garde de boucle. |

### 2.5 `koach/planification.py`

| Constante | Valeur | Catégorie | Raison |
| --- | --- | --- | --- |
| `GRILLE_INTENSITE` | −5 ; −2,5 ; 0 ; +2,5 ; +5 % | choix raisonné | Couvre le plafond ±5 % du cahier (Méthodes § 6) ; pas choisi. |
| Pente par défaut hors charge (`lignes_item`) | 0,03 | choix raisonné | ≈ C_LIN·e^0,1. |
| Part par défaut (`_table`) | 0,7 | choix raisonné | — |
| Répétitions par défaut (`lignes_item`) | 8 | choix raisonné | — |
| Chute par défaut d'une série de tête (`lignes_item`) | 0,08 | choix raisonné | — |
| Semaine non écrite : F × e^(−7/τ) (`evaluer`) | — | choix raisonné | Décroissance d'une semaine avec la constante lente (relecture m9). |
| Fenêtre tendineuse (`evaluer`) | 4 semaines | choix raisonné | — |
| Population minimale 4, élite minimale 2, écart de départ 0,5·plafond, plancher 1e-4 (`replanifier`) | — | choix raisonné | — |
| Candidats finaux : 4 + 4 ; 3 essais ramenés × 0,5 (`replanifier`) | — | choix raisonné | — |
| `risque` : marge 1e-9 (`evaluer`) | — | choix raisonné | Numérique. |

### 2.6 `koach/rupture.py`, `koach/adherence.py`, `koach/dual.py`

| Constante | Valeur | Catégorie | Raison |
| --- | --- | --- | --- |
| `LANCZOS_G`, `LANCZOS_C` (`rupture.lgamma`) | g = 7, 9 coefficients | choix raisonné | Approximation numérique de ln Γ ; source primaire non vérifiée ; erreur < 1e-13 annoncée par le code. |
| `SEMAINES_GARDEES` 12, `REPONSES_GARDEES` 10 (`Surveillance`) | — | choix raisonné | Mémoire. |
| Durées proposées au diagnostic (`QUESTION_DUREE`) | 20, 30, 45, 60, 75, 90 min | choix raisonné | — |
| `BORNES` et `FIGEES` de l'import (`rupture`) | — | choix raisonné | Bornes de validation ; clés figées pour que l'import n'assouplisse aucun garde-fou (relecture M3). |
| `DIM` 16, 5 tranches de calibration (`adherence`) | — | choix raisonné | — |
| `Z90` (`dual`) | 1,6448536269514722 | — | Quantile exact. |
| `borne_lambda_max` : 4 carrés (`dual`) | majorant ≤ 1,11·λmax pour J = 5 | choix raisonné | Calcul du code. |
| `RAISONS_GARDEES` 50 ; plancher de log-poids −745 (`dual`) | — | choix raisonné | Numérique. |

### 2.7 `qualites/regles.py` (vecteurs de qualités)

Toutes ces constantes ont été écrites lors de la génération par règles, puis corrigées après la relecture indépendante de 222 exercices (`km1-outils/notes/RELECTURE_VECTEURS.md`, partie C). La relecture justifie leur **sens** par l'anatomie fonctionnelle ou l'usage d'entraîneur, mais ne mesure aucune valeur. Elles sont donc classées « choix raisonné », sauf mention.

| Constante | Valeur | Catégorie | Raison (relecture) |
| --- | --- | --- | --- |
| `QUALITES` | 10 qualités | choix raisonné | Cahier, Méthodes § 2 (10 qualités) ; noms choisis par le lot. |
| `MUSCLE` (R1) | muscle → pousser, tirer, jambes ou tronc | choix raisonné | Anatomie fonctionnelle. |
| `EXTENSEURS_EN_TIRAGE`, `SCHEMAS_TIRAGE` (R1-a) | 4 muscles comptés « tirer » dans 4 schémas | choix raisonné | Relecture C.1, R1-a. |
| `POIDS_STABILISATEUR` (R1-b) | 0,25 | choix raisonné | Relecture C.1, R1-b (prise limitante en soulevé de terre). |
| `SCHEMA` (R2, parts fixes) | table de `regles.SCHEMA` | choix raisonné | Relecture C.2. |
| `FIGURES_COMPRESSION` | 0,2 ; 0,3 ; 0,4 ; 0,5 ; tronc 0,65 − figures ; mobilité 0,15 | choix raisonné | Relecture R2-a. |
| Figures dynamiques non explosives | figures 0,45 | choix raisonné | Relecture R2-b. |
| `EXPLOSIVITE_TRANSITION` | 0,25 (explosif), 0,05 (dynamique), 0 sinon | choix raisonné | Relecture R2-c. |
| `FIGURES_HSPU_LIBRE`, `FIGURES_HSPU_MUR` | 0,25 ; 0,10 | choix raisonné | Relecture R2-d. |
| Haltérophilie non explosive | explosivité 0,1, mobilité 0,1 | choix raisonné | Relecture R2-g. |
| `ENDURANCE_PDC` (R3) | 0,30 ; 0,20 ; 0,10 ; 0,10 | choix raisonné | Relecture C.3 ; R3-b note que la part dépend du niveau de l'exercice. |
| `ENDURANCE_ISO_TRONC` | 0,30 | choix raisonné | — |
| `SANS_CHARGE` | poids du corps, aucune (élastique exclu) | choix raisonné | Relecture R3-a. |
| `PART_RACINE` (R4) | 0,30 | choix raisonné | Relecture C.4 : aucun défaut systématique. |
| `FAMILLES_ENDURANCE`, `CHARGES_EXTERNES` (R5) | — | choix raisonné | Type = mode d'exécution de `kalis_core` ; corrections R5 non appliquées (SAUVEGARDE). |
| `NIVEAU_CONTRAINTE` (R6) | faible 0,1 ; moyenne 0,4 ; forte 0,8 | choix raisonné | — |
| `ORDRE_ZONES`, `ORDRE_SCHEMA` | — | choix raisonné | Relecture R6-b. |
| `BONUS_BRAS_TENDUS` | 0 ; 0,1 ; 0,2 ; 0,2 | choix raisonné | Relecture R6-c (bras de levier croissant). |
| Excentrique +0,1 ; lesté au poids du corps +0,1 ; plancher des sauts 0,7 avec impact (`tendon_de`) | — | choix raisonné | Relecture R6-e. |
| `ASSISTANCE_TENDON`, `ASSISTANCE_PLANCHER` | −0,2 ; 0,4 | choix raisonné | Relecture R6-d. |
| `PASSIF_PLAFOND` | 0,4 | choix raisonné | Relecture R6-f. |
| Zone nulle si charge ≤ 0,1 (`tendon_de`) | — | choix raisonné | Relecture R6-a. |
| `RATIO` (R7, 1RM total/poids du corps, intermédiaire ; colonnes barre, haltères ou kettlebell par main, machine, poulie, lest) | table de `regles.RATIO` | choix raisonné | « Ordres de grandeur de normes de force », sans source lue. Contrôle banc : `diag_prior.py` (écart moyen de +0,03 à +0,09 en ln selon le niveau, dispersion 0,11 à 0,17 ; pires cas : swing kettlebell +0,46, dips lestés −0,38, mollets machine +0,38). |
| `RATIO_DEFAUT` | 0,50 ; 0,20 ; 0,50 ; 0,40 ; 1,20 | choix raisonné | — |
| `LEST_RELATIF` | traction 0,40 ; dips 0,50 ; pompe 0,40 ; muscle-up 0,15 ; fente 0,30 ; rowing 0,35 | choix raisonné | Relecture R7-c. |
| `HALTERO_RACINE`, `HALTERO_VARIANTE` | arraché 0,78, épaulé 1,00, épaulé-jeté 0,95, … ; muscle ×0,70, power ×0,85, tirage ×1,10 | choix raisonné | Relecture R7-d : « rapports d'usage chez les entraîneurs, pas une norme publiée ». |
| `UNILATERAL` | 0,55 | choix raisonné | Relecture R7-b, qui cite Škarabot et al. 2016 : référence vérifiée, mais son résumé ne chiffre pas le déficit. Valeur non sourcée. |
| `EXCENTRIQUE` | 1,25 | choix raisonné | Relecture R7-f (« valeur prudente »). |
| `EXTENSEURS_POIGNET` | 0,6 | choix raisonné | Relecture R7-e. |
| Fente, colonne machine | 1,10 | choix raisonné | Relecture R7-g (« presse unilatérale ≈ moitié de la bilatérale 2,2 »). |
| `GROUPES`, `GROUPE_DE` (R8) | 17 groupes | repris de 0.3.1 | Groupes musculaires de `kalis_plan` ; hors inventaire A. |
| Poids des groupes (principal 1, secondaire 0,5) | — | repris de 0.3.1 | Crédit des séries par groupe du banc (inventaire B0 : crédit 2 → 1, 1 → 0,5). |
| `systemique`, `locale` = fatigue du catalogue / 3 (`generer`) | — | choix raisonné | Normalisation de l'échelle 0 à 3 de `kalis_core`. |
| `HALTERO_RACINE` défaut | 0,85 | choix raisonné | — |

### 2.8 `rejeu/journal_app.py` (convertisseur, hors moteur)

| Constante | Valeur | Catégorie | Raison |
| --- | --- | --- | --- |
| `SD_DECLARE_ACCESSOIRE` | 0,12 (ln) | choix raisonné | Écart-type d'une valeur déclarée indirecte (charge de travail initiale d'un accessoire convertie en 1RM), plus large que `delta_sd_declare`. |
| `COURBE_LAMBDA` | 0,3 | choix raisonné | Forme de population de la courbe (`a_priori.courbe_forme[0]`), recopiée ; sans l'échelle `courbe_echelle` (CONTRAT, annexe A.3). |

---

## 3. Synthèse

**Clés du fichier de paramètres** (section 1, 297 clés, une ligne chacune) :

| Catégorie | Clés |
| --- | --- |
| référence publiée vérifiée | 1 |
| mesure sur le banc | 25 |
| repris de 0.3.1 | 110 |
| choix raisonné | 161 (dont 23 valeurs fixées par le cahier) |
| **Total** | **297** |

Clés non lues par le moteur : 25 (liste dans `CONTRAT_1_0.md` § 7.5), dont 10 règles de volume de 0.3.1 portées par le validateur injecté et 2 clés lues par le banc seulement (`qualites`, `mesure.cardio_poids_qualite`).

La catégorie « repris de 0.3.1 » regroupe les paramètres de `kalis_adapt` 0.3.1 et de `kalis_plan` (inventaire A), et les critères du banc `kalis_bench` (inventaire B).

**Constantes du code** (section 2) : la plupart sont des choix raisonnés ou des garde-fous numériques. Celles qui viennent de 0.3.1 sont signalées une par une.

### 3.1 Clés classées sous réserve

Ces clés sont classées, mais leur classement doit être confirmé par l'auteur du calage :

| Clé | Réserve |
| --- | --- |
| `a_priori.eps_classe_moyenne` | Classée « choix raisonné ». Le sens est celui de `fit_reponse.py`, mais aucun script ne reproduit 0,0029, 0,002 ou 0,001. |
| `a_priori.courbe_echelle_exercice_sd` | SAUVEGARDE dit 0,23, le fichier 0,22 ; aucune mesure notée. |
| `dynamique.recuperation_seuil` et `dynamique.recuperation_pente` | Le meilleur ajustement de la classe « charge » donne 6 et 0,25 ; les valeurs retenues (8 et 0,5) correspondent aux classes répétitions et tenues. Le choix entre les classes n'est pas documenté. |
| `test_adaptatif.*` (rampe) | Réglés par essais successifs sur le banc ; SAUVEGARDE donne le résultat, pas la mesure qui fixe chaque valeur. |
| `jour.mauvais_jour_proba` | Classée « mesure sur le banc » : la valeur reprend la fréquence d'un modèle de vérité (C), pas un ajustement sur l'ensemble des vérités. |

### 3.2 Clés non classées

**Aucune.** Chaque clé a reçu une catégorie. Les plus fragiles sont celles de la section 3.1.

### 3.3 À caler en priorité

Ce sont les choix raisonnés qui ont le plus d'effet sur les critères de bascule :

1. `mesure.defaut_modele_sd` : critère « couverture 88 à 92 % » ; valeur provisoire, à caler sur la campagne.
2. `planification.lambda_transport` : le cahier demande un calage sur le banc.
3. `a_priori.biais_rir_proportionnel` (écart-type) et `mesure.porte_note_ouverte` : dérive de l'e1RM sur un plateau (reste +4 à +7 % sur l'essai synthétique).
4. `a_priori.tenue_base_s` et `a_priori.niveau_echelle_charge` : biais mesurés par `diag_prior.py`.
5. `jour.mauvais_jour_*` : critère « effet d'un mauvais jour isolé sous 1 % ».
6. `mesure.bruit_rir_pente` et `mesure.bruit_rir_plancher` : critère « couverture 88 à 92 % ».
7. `a_priori.delta_sd_declare` : relecture m12 (déclaration sans date ni test).
