# Koach 1.0.1 — référence Python (lot KM1, correction 1)

Référence exécutable de la méthode Koach (`pipeline/cp/CAHIER_KM.md`), version 1.0.1 : contrat 1.0 avec la passe « KM1 correction 1 » (DECISIONS_CP.md C13.10 ; paramètres `1.0.1-ref.1`). Ce qui change par rapport à 1.0 est dans la note datée du 10/10/2026 en tête de `CONTRAT_1_0.md`. Elle sert de modèle au portage Dart du lot KM2
(`kalis_adapt` 1.0.0) : mêmes entrées, mêmes sorties à 1e-9 sur les fixtures. Elle n'est pas embarquée dans l'application.

Python 3 et numpy seulement. Aucune donnée personnelle : le rejeu du journal réel ne publie que des agrégats.

## Contenu

| Dossier ou fichier | Rôle |
| --- | --- |
| `CONTRAT_1_0.md` | Contrat gelé 1.0, modifié pour 1.0.1 par une note datée (10/10/2026) : API `observe` / `posterior` / `plan` / `explain`, schéma du journal, modèles, règles de sécurité, paramètres, portage, écarts connus (annexe A). |
| `SOURCES.md` | Origine de chaque paramètre de `params/koach_params_v1.json` (une ligne par clé). |
| `params/koach_params_v1.json` | Fichier de paramètres versionné (`1.0.1-ref.1`, 317 clés). |
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
python3 -I rejeu/walk_forward.py <export.json> --programme <prog.json.gz> --koach-programme <koach_program.json.gz> \
    --correspondance <corr.json> --depuis 12 --sortie donnees/rejeu_journal_agregats.json
```

Le témoin (`donnees/temoin/`, `donnees/adversaires_temoin.json.gz`) vient de `packages/kalis_bench/bin/km1.dart`
(export des modèles de vérité, des saisons de référence et des mesures de `kalis_adapt` 0.3.1).

## Résultats publiés

- `donnees/criteres_km1.json` : critères chiffrés du cahier sur la matrice du banc (Koach 1.0.1 complet contre 0.3.1), campagne finale de la correction 1 (code et paramètres livrés). Mesures fixées par C13.10.2 : erreur d'e1RM en moyenne des trois vérités, mauvais jour en contrefactuel apparié, calibration de P(réussite) par cible, rejeu réel seulement rapporté.
- `donnees/criteres_km1_avant_correction1.json` : la même campagne pour KM1 (Koach 1.0), gardée pour la comparaison avant / après.
- `donnees/comparaison_adversaires.json` : pire cas adversarial, Koach 1.0.1 rejoué sur les adversaires trouvés contre Koach 1.0 (pas de nouvelle recherche).
- `donnees/rejeu_journal_agregats.json` : rejeu du journal réel, agrégats (mesuré avec Koach 1.0, KM1 ; non refait pour 1.0.1).
- `donnees/criteres_moteur.json` : temps, mauvais jour isolé (saisons divergentes et contrefactuel apparié), déterminisme (Koach 1.0.1).
- `donnees/validation_briques_6_7.json` : rupture, adhérence, contrôle dual (refait le 10/10/2026 avec Koach 1.0.1).

Le détail par critère, les limites et ce qui reste sont dans `pipeline/cp/livraisons/LIVRAISON_KM1.md` (Koach 1.0) et `pipeline/cp/livraisons/LIVRAISON_KM1_correction1.md` (Koach 1.0.1), branche `pipeline`. La liste exacte des changements de la correction 1 est dans `CHANGEMENTS_1_0_1.md`.
