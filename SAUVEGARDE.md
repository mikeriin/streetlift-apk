# Sauvegarde KM1c2 (KM1 correction 2, référence Koach 1.0.2)

Base : `moteurs` df28b47c. Session Fable 5.1, lancée le 11/10/2026 ~05:10 UTC. `add_repo` absent de la session ; push vérifié (pipeline : ligne « en cours »).

## Fait
- Lecture : prompt, C13.10-12, cahier, LIVRAISON_KM2, CRITERES_KM2, code de `koach/seance.py` (bornes de hausse, tentatives, rampe).
- Diagnostic `adv-31c45cfb` (graine 0) : estimation correcte au jour J (147 kg pour 157) ; ouverture bornée par le « dernier passage » en semaine de retour (47,5 kg, simple d'affûtage à 65 % converti par la courbe apprise), puis sauts de tentatives de 5 %/3 % arrondis à la grille = 0 : trois barres à 47,5 kg.
- Outils : `km1c2_outils/trace.py`, `dbg1.py` (dans cette sauvegarde).

## En cours
- Point 1 (reprise par paliers mesurés).

## Reste
- Points 2 (critère 5), 3 (critère 4), 4 (fixtures, docs), campagne six graines, relecture, contrôle, livraison.

## 11/10 ~06:40 UTC — point 1, itération 1 (code dans cette sauvegarde)
- `seance.py` : (a) semaine du retour de coupure, lignes chargées : plus de `sans_hausse` ni d'ancre « dernier passage » ; reprise par paliers (`plan['reprise']`) : 1re série sans hausse par rapport au même schéma, palier suivant (+5 % ou un cran) seulement après une série faite, notée, dite au plus aussi dure que visé ; (b) ancre « dernier passage » gardée pour la douleur seulement (bilan bas : règle 0.3.1, même schéma) ; (c) tentatives : ancre de coupure retirée ; plafond « barres des 42 jours » remplacé par des paliers selon la note (`securite.tentative_palier_par_rir` = [[4,0.10],[3,0.075],[2,0.05],[1,0.025]], 0 si non notée) ; un cran permis si la barre précédente est dite facile (saut en % < cran).
- Adversaires KM2 rejoués (Koach sans extension, témoin lu) : b3000 15/18 appariés ≥ témoin − 0,03 (2 sous − 0,10 : échecs d'ouverture un mauvais jour) ; complet_b600 17/19 (1) ; b300 18/19 (0). Avant : 10/24.
- CI : campagne six graines lancée (parties 1/2 sur ci-cp-a, 2/2 sur ci-cp-b ; ~85 min ; résultats `ci-out/packages/aa_km1c2/campagne_*.tar.xz`, à extraire dans /tmp/km1-campagne puis `python3 -m banc.campagne --graines 6 --temps-existants`). Outils : `km1c2_outils/ci_push.sh`, `ci/`.
- Local : recherche adversariale 3000 contre l'itération 1 (/tmp/k/adv_it1_b3000.json).
- Ajouts banc : `--partie i/n`, `couverture_paires` (recalage hors ligne de defaut_modele_sd), `prevu_jour` et `observe` dans les unités de calibration (critère 5).
- Tests : 181 passent ; à mettre à jour : `test_retour_de_coupure_ni_test_ni_hausse`, `test_documents` (empreinte, SOURCES, CONTRAT), fixtures.

## 11/10 07:50 UTC — points 1 (itération 2), 2 et 3 codés ; campagne finale lancée
- Point 1, itération 2 (retenue) : palier d'ouverture = plus lourde barre des 42 jours ramenée à 1 rép. × (1 + palier de la note la plus dure des barres à 5 % près) ; `tentative_palier_bande` 0,05. Recherche 3000 contre cette version + témoin Dart (CI) : 7 bis 18/24 (75 %), 5 cas sous − 0,10 (échecs d'ouverture street_07, estimation trop haute sous notes bruitées), pire écart − 0,30 (KM2 : 9/24, − 0,60). Tous les cas powerlifter tenus.
- Point 2 : `planification.dispersion_echeance` 0,62 (mesuré graines 0,2,4 : 0,623 ; graines 1,3,5 : 0,625). Réplique hors ligne du modèle (/tmp/k/p2model.py) : six graines, pire décile 16,2 → 12,5 points, erreur pondérée 3,3 → 1,6 points. Le seuil de 5 points par décile n'est pas tenu (n ≈ 45 par décile : erreur d'échantillonnage ≈ 7 points ; biais par graine ± 1 % = ± 15 points près du seuil).
- Point 3 : `defaut_modele_sd` 0,010 + `intervalle_echelle` 0,9 (dans `capacite`) ; six graines sans planificateur : couverture 89,26 %, e1RM 3,69 %, jour J 0,9439 / 0,9324.
- Sans planificateur, graine 2 : 3 poussées de douleur (street_03, seances_manquees, vérité b) — identiques avec 1.0.1 (préexistant ; la configuration officielle, Koach complet, en a 0).
- CI : campagne finale (code 1.0.2-ref.1) parties 1/2 (ci-cp-a) et 2/2 (ci-cp-b), ~80 min. Local : recherche adversariale finale (/tmp/k/adv_fin_b3000.json), puis témoin Dart en CI (ci/run_temoin.sh, AVEC_DART=1).
- Reste : fixtures, SOURCES, CONTRAT (note datée, règles, clés : 321), README, relecture indépendante (Opus), contrôle complet, publication, livraison.
