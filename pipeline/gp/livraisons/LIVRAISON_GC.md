# Livraison GC — contrats et paquet `kalis_core` 0.1.0 (piste M)

01/10/2026 — Fable 5.1, effort maximal (tâche A). Branche `moteurs`, commit `5327294`
(« Kalis Track moteurs (GC) : kalis_core 0.1.0 »). Contrôle : run `ci-paquets` n° 36833295632 vert sur
`claude/ci-gp-moteurs` (formatage, `dart analyze --fatal-infos` sans problème, 182 tests Dart, simulateur,
80 tests Python).

**Étiquette** : le push de l'étiquette annotée `kalis_core-v0.1.0` est **refusé par le proxy de la session
(HTTP 403, aucune étiquette n'existe sur le dépôt)**. À sa place : la branche fixe
`etiquettes/kalis_core-v0.1.0`, posée sur `5327294` et jamais déplacée. Récupération par un lot de la
piste A : `git fetch origin etiquettes/kalis_core-v0.1.0` puis
`git checkout FETCH_HEAD -- packages/kalis_core`. Le propriétaire peut créer la vraie étiquette sur ce
commit quand il veut (`git tag -a kalis_core-v0.1.0 5327294 && git push origin kalis_core-v0.1.0`).

## Ce qui est livré

| Élément | Où |
| --- | --- |
| Copie de la base v1.1.0 (SHA-256 vérifié par deux tests) | `packages/kalis_core/data/source/` |
| Outil de compilation relançable (Python 3.11), règles, tests | `tools/catalog/` |
| Catalogue compilé : la base + 18 champs calculés par règles | `packages/kalis_core/data/catalog_v1.json.gz` (375 Ko) |
| `Catalog` Dart : chargement depuis des octets, index, graphe `variante_de`, proximité | `lib/src/catalog.dart` |
| Relecture pour le propriétaire : distributions, 60 exemples seedés, cas ambigus, CSV | `docs/RELECTURE_CATALOGUE.md`, `docs/relecture_catalogue.csv` |
| Contrats : 73 types, 54 enums, JSON versionné, validation | `tool/contracts_spec.py` → `lib/src/generated/`, `docs/TYPES.md` |
| Échelle des flammes (D5.3) | `lib/src/flames.dart` |
| Interfaces `PlanEngine`, `AdaptEngine`, `QuestEngine` (une requête versionnée par méthode) | `lib/src/engines.dart` |
| Registre de 67 codes de raison, sans texte | `lib/src/generated/reason_codes.g.dart` |
| Jeux de données : 40 profils, 12 journaux (4 à 24 semaines, 468 séances, 5 480 séries) avec la vérité du modèle simulé, programme du propriétaire normalisé (lecture seule), ancien journal et sa conversion | `test/fixtures/` |
| Documentation | `CONTRAT.md`, `INTEGRATION.md`, `README.md`, `CHANGELOG.md`, `docs/CONVERSION_JOURNAL.md` |
| Simulateur | `bin/kalis_core_cli.dart --rapport <dossier>` |

## Mesures (run 36833295632)

- Chargement du catalogue, décompression comprise : meilleur 40,6 ms, médiane 46,0 ms (budget 150 ms).
- Aller-retour JSON : 10 000 valeurs seedées pour chacun des 73 types, égalité et sérialisation identique
  à l'octet près ; proximité : 10 000 paires ; flammes : table exacte, inverse exact, 10 000 tirages.
- Jeux de données : 0 violation sur 40 profils et 12 journaux ; 319 séries sans note conservées comme
  absences ; 12 séances « reprise ».
- Paquet entier (pub get, formatage, analyse, tests, simulateur) : 95 s.

## Catalogue : distribution des champs calculés (règles 1.1.0)

- Type de charge : poids du corps 446, aucune 155, barre 116, haltères 88, poulie 61, lest 58, machine 53,
  autre 25, kettlebell 19, élastique 18 (détail exact dans la relecture).
- Unité : répétitions 73 %, secondes 24 %, distance 3 %, calories 1 exercice.
- Articularité : poly 53 %, mono 19 %, sans objet 28 % (tenues, cardio, mobilité).
- Difficulté : Débutant 1-3, Intermédiaire 3-6, Avancé 6-8, Élite 8-10 (jamais décroissante avec le niveau).
- 204 exercices ont une fraction du poids du corps (publiée, dérivée ou estimée, dite pour chacune).

## Relecture indépendante

Un sous-agent a relu contrats, règles et catalogue avant l'étiquette : 35 constats, dont 2 bloquants
(le programme de 40 semaines du propriétaire n'entrait pas dans un bloc ; un bloc ne pouvait pas changer
d'exercice en cours de route). Corrigés avant de figer : durée de bloc 1 à 52 semaines dans le contrat
(4 à 6 reste la règle de `kalis_plan`), **la passe 2 fait foi semaine par semaine**, requêtes versionnées
pour chaque méthode de moteur, cibles série par série, `percentOfOneRm`, douleurs du bilan optionnelles
(non posée ≠ aucune), décisions sur les propositions, lieu par jour et matériel par lieu, « sais faire /
ne sais pas faire » dans le profil, pauses déclarées, records, objectifs suggérés, écriture canonique
des objets JSON libres, conventions de charge écrites, 12 règles du catalogue corrigées.

## Limites

- Champs calculés par règles sur les noms : des cas particuliers restent mal classés ; la relecture liste
  les cas ambigus. **Contenu sportif non relu par un professionnel diplômé.**
- Les valeurs publiées (Suprak 2011, Ebben 2011, Winter 2009) sont reprises des résumés et tables publiés,
  non revérifiées sur le texte intégral dans ce lot.
- Pas de SDK Dart dans la session : le formatage officiel a été récupéré par la branche de contrôle
  (deux passages avec un test d'export présent sur cette branche seulement, puis le passage final sans lui).
- La correspondance noms du programme v33 → catalogue des jeux de données est indicative ; celle de
  référence est à faire par G3.

## Pour la suite

- G4 (`kalis_plan`) part de `moteurs` (5327294) et réalise `PlanEngine`. **Le lancement automatique de G4 a été refusé à la session (permission sur `fire_trigger`)** : à lancer à la main sur la tâche Fable B avec « Lot : G4 ».
- G3 récupère `packages/kalis_core` par la branche fixe ci-dessus ; `INTEGRATION.md` dit comment charger le
  catalogue, stocker le profil, convertir le journal.
- À relire par le propriétaire : `packages/kalis_core/docs/RELECTURE_CATALOGUE.md` (sur `moteurs`).
