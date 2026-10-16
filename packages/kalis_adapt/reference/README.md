# Koach 1.0.3 — référence Python (lot KM1, correction 3)

Référence exécutable de la méthode Koach (`pipeline/cp/CAHIER_KM.md`), version 1.0.3 : contrat 1.0 avec les passes « KM1 correction 1 » (DECISIONS_CP.md C13.10), « KM1 correction 2 » (C13.12) et « KM1 correction 3 » (C17.9 : estimation sous notes non fiables ; paramètres `1.0.3-ref.1`). Ce qui change est dans les notes datées du 10/10, du 11/10 et du 15/10/2026 en tête de `CONTRAT_1_0.md` et dans `CHANGEMENTS_1_0_1.md`, `CHANGEMENTS_1_0_2.md` et `CHANGEMENTS_1_0_3.md`. `kalis_adapt` 1.0.1 (lot KM2c1) porte la version 1.0.2 ; le portage du delta 1.0.3 est le lot KM2c2 : mêmes entrées, mêmes sorties à 1e-9 sur les fixtures. Elle n'est pas embarquée dans l'application.

Python 3 et numpy seulement. Aucune donnée personnelle : le rejeu du journal réel ne publie que des agrégats.

## Contenu

| Dossier ou fichier | Rôle |
| --- | --- |
| `CONTRAT_1_0.md` | Contrat gelé 1.0, modifié pour 1.0.1 et 1.0.2 par des notes datées (10/10 et 11/10/2026) : API `observe` / `posterior` / `plan` / `explain`, schéma du journal, modèles, règles de sécurité, paramètres, portage, écarts connus (annexe A). |
| `SOURCES.md` | Origine de chaque paramètre de `params/koach_params_v1.json` (une ligne par clé). |
| `params/koach_params_v1.json` | Fichier de paramètres versionné (`1.0.3-ref.1`, 338 clés), lu tel quel par les tests Dart de `kalis_adapt` 1.0.2 (asset `assets/koach/koach_params_1_0_3.json`, copie à l'octet près). |
| `qualites/` | Vecteurs de qualités des 1 039 exercices (`regles.py` → `vecteurs_qualites_v1.json`). |
| `koach/` | Le moteur : `modele.py` (estimation), `seance.py` et `securite.py` (séance, garde-fous), `planification.py`, `rupture.py`, `adherence.py`, `dual.py`, `moteur.py` (façade), `numerique.py`. |
| `banc/` | Port Python des modèles de vérité et des critères de sécurité de `kalis_bench`, meneur de saison, banc adversarial, campagne de mesure des critères. |
| `rejeu/` | Rejeu walk-forward d'un export de l'application (agrégats seulement). |
| `fixtures/` | Fixtures de parité Python/Dart (`generer.py`, format décrit dans `fixtures/README.md`). |
| `donnees/` | Saisons de référence, témoin `kalis_adapt` 0.3.1 exporté par `kalis_bench` (Dart), résultats publiés. |
| `tests/` | Tests (pytest). |

## Commandes

Depuis ce dossier :

```
python3 -m pytest tests -q                      # tous les tests (≈ 2 min)
python3 fixtures/generer.py                     # régénère les fixtures ; --verifier pour contrôler
python3 -m banc.campagne --profils tous --scenarios tous --graines 2 --sortie donnees/criteres_km1.json
python3 -m banc.adversaire --chercher --budget 300 --sortie donnees/adversaires_v1.json
python3 -m banc.campagne --graines 6 --partie 1/2      # campagne répartie : une part des saisons, écrites dans /tmp/km1-campagne
python3 -m banc.adversaire --comparer <adversaires_temoin.json.gz> --adversaires <fichier lisible> --sans-rejeu --rapport <comparaison.json>   # critère 7 bis
python3 -I rejeu/walk_forward.py <export.json> --programme <prog.json.gz> --koach-programme <koach_program.json.gz> \
    --correspondance <corr.json> --depuis 12 --sortie donnees/rejeu_journal_agregats.json
```

Le témoin (`donnees/temoin/`, `donnees/adversaires_temoin.json.gz`) vient de `packages/kalis_bench/bin/km1.dart`
(export des modèles de vérité, des saisons de référence et des mesures de `kalis_adapt` 0.3.1).

## Résultats publiés (1.0.3, lot KM1c3)

- `donnees/criteres_km1c3.json` : critères du cahier sur six graines (4 320 saisons, Koach 1.0.3 complet contre 0.3.1).
- `donnees/adversaires_km1c3.json` : recherche adversariale de 3 000 saisons contre Koach 1.0.3 ; `donnees/adversaires_km1c3_temoin.json.gz` : témoin 0.3.1 (Dart) ; `donnees/comparaison_adversaires_km1c3.json` : comparaison et critère 7 bis ; `donnees/comparaison_adversaires_km1c3_*.json` : Koach 1.0.3 rejoué sur les cinq jeux connus.
- `donnees/rejeu_journal_agregats_km1c3.json` : rejeu du journal réel (agrégats seulement), avec la section `D_fiabilite_des_notes`.

## Résultats publiés (1.0.2, lot KM1c2)

- `donnees/criteres_km1c2.json` : critères du cahier sur six graines (graines 0 à 5, 4 320 saisons, Koach 1.0.2 complet contre 0.3.1), campagne répartie (`--partie`) puis assemblée. Critère 5 mesuré selon C13.11.2 : `detail.par_cible.une_prevision_par_cible`.
- `donnees/adversaires_km1c2.json` : recherche adversariale de 3 000 saisons contre Koach 1.0.2 ; `donnees/adversaires_km1c2_temoin.json.gz` : témoin 0.3.1 (Dart, `kalis_bench` `bin/km1.dart`) sur ces adversaires ; `donnees/comparaison_adversaires_km1c2.json` : comparaison et critère 7 bis (`critere_7_bis`).
- `donnees/comparaison_adversaires_km1c2_km2_*.json` et `…_km1_v1.json` : Koach 1.0.2 rejoué sur les adversaires de KM2 (`kalis_bench/docs/data/km2/`) et de KM1, témoin relu (`donnees/temoin_adversaires/`).
- `donnees/calibration_grappes_km1c2.json` (`python3 -m banc.calibration_grappes <dossier de travail de la campagne>`) : ce que la mesure du critère 5 peut conclure — cas regroupés par grappe (graine, profil, exercice), biais global et distribution de l'écart maximal par décile d'un modèle parfaitement calibré aux issues liées dans la grappe.
- Les fichiers de 1.0.1 ci-dessous sont gardés pour la comparaison avant / après (dont `donnees/criteres_moteur.json`, non refait) ; le mauvais jour et les temps de 1.0.2 sont dans `donnees/criteres_km1c2.json` (critères 2 et 8 de la campagne).

## Résultats publiés avec 1.0 et 1.0.1

- `donnees/criteres_km1.json` : critères chiffrés du cahier sur la matrice du banc (Koach 1.0.1 complet contre 0.3.1), campagne finale de la correction 1 (code et paramètres livrés). Mesures fixées par C13.10.2 : erreur d'e1RM en moyenne des trois vérités, mauvais jour en contrefactuel apparié, calibration de P(réussite) par cible, rejeu réel seulement rapporté.
- `donnees/criteres_km1_avant_correction1.json` : la même campagne pour KM1 (Koach 1.0), gardée pour la comparaison avant / après.
- `donnees/comparaison_adversaires.json` : pire cas adversarial, Koach 1.0.1 rejoué sur les adversaires trouvés contre Koach 1.0 (pas de nouvelle recherche).
- `donnees/rejeu_journal_agregats.json` : rejeu du journal réel, agrégats (mesuré avec Koach 1.0, KM1 ; non refait pour 1.0.1).
- `donnees/criteres_moteur.json` : temps, mauvais jour isolé (saisons divergentes et contrefactuel apparié), déterminisme (Koach 1.0.1).
- `donnees/validation_briques_6_7.json` : rupture, adhérence, contrôle dual (refait le 10/10/2026 avec Koach 1.0.1).

Le détail par critère, les limites et ce qui reste sont dans `pipeline/cp/livraisons/LIVRAISON_KM1.md` (Koach 1.0), `LIVRAISON_KM1_correction1.md` (1.0.1) et `LIVRAISON_KM1c2.md` (1.0.2), branche `pipeline`. Les listes exactes des changements sont dans `CHANGEMENTS_1_0_1.md` et `CHANGEMENTS_1_0_2.md`.
