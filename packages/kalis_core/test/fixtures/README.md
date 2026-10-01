# Jeux de données communs (kalis_core)

Fichiers générés par `tool/gen_fixtures.py` (déterministe, graines fixes) — ne pas modifier à la main.
Les autres paquets les lisent par chemin relatif (`../kalis_core/test/fixtures/…`) depuis leurs tests et
leurs simulateurs, avec les lecteurs de `package:kalis_core/testing.dart`.

| Fichier | Contenu | Lecture |
| --- | --- | --- |
| `profiles.json` | 40 profils types (`AthleteProfile` v2) : `key`, `description`, `profile` | `readProfileFixtures` |
| `journals.json.gz` | 12 journaux synthétiques de 4 à 24 semaines (`TrainingLog`) : `key`, `profileKey`, `weeks`, `description`, `truth`, `log` | `readJournalFixtures` (après `gzip.decode`) |
| `owner_program_v33.json.gz` | Programme personnel du propriétaire, normalisé, **lecture seule** | JSON brut |
| `legacy_journal.json` | Journal au format actuel de l'application (`before`), sa conversion (`after`, `TrainingLog`) et le rapport de conversion (`report`) | JSON brut ; règles dans `docs/CONVERSION_JOURNAL.md` |

## Journaux synthétiques

Les séances ne viennent d'aucun moteur : des gabarits simples (dans `gen_fixtures.py`) joués par un athlète
simulé. `truth` donne, par exercice, les paramètres vrais du modèle : `mode` (`load` : 1RM de charge totale en
kg — charge externe + fraction du poids du corps × poids ; `reps` : répétitions max ; `hold` : tenue max en
secondes ; `run` : vitesse en m/s), `capacityStart` et `weeklyGain` (gain relatif linéaire par semaine).
Répétitions possibles à une charge : formule d'Epley inversée, `30 × (1RM / charge − 1)` ; chaque série
suivante coûte 1,2 % de capacité ; la note en flammes est celle du RIR vrai, bruité (écart-type 0,4).
`kalis_adapt` peut donc comparer ses estimations à la vérité. Dans un bilan santé, `pains` n'est présent
que si la question a été posée (réponse basse) ; `j08_irregulier` déclare sa coupure dans `breaks`.

| Clé | Ce que le journal illustre |
| --- | --- |
| `j04_debutant_maison` | débutant, progression rapide, notes parfois absentes |
| `j08_femme_musculation_salle` | assidue, bilans santé fréquents |
| `j12_coureur` | séries en durée et en distance |
| `j16_proprietaire_streetlifting` | lest (charge externe + poids du corps), progression lente |
| `j24_musculation_avance` | long journal (133 séances) pour les mesures de temps de calcul |
| `j06_blessure_epaule` | douleurs signalées avant et pendant la séance |
| `j08_irregulier` | séances manquées, bilans bas, coupure de 12 jours |
| `j12_calisthenie` | tenues en secondes |
| `j05_reprise` | 3 semaines marquées « reprise » (D4.9) |
| `j10_sans_notes` | 60 % des séries sans note |
| `j20_plateau` | gain nul : stagnation |
| `j04_minimal` | une séance par semaine |

## Programme du propriétaire

`owner_program_v33.json.gz` reprend `assets/programme_v33.json.gz` (40 semaines) sans les consignes :
semaines, jours, exercices (nom, nom normalisé, séries en texte, intensité, type de charge, repos). Il sert au
test de non-ressemblance de `kalis_plan` (D4.1) ; aucun moteur ne s'en sert comme gabarit ni ne le régénère
(D5.10). `catalogId` est une correspondance **indicative** vers le catalogue, par règles sur le nom (absente
quand rien ne correspond clairement) ; la correspondance de référence pour l'historique est celle du lot G3.
