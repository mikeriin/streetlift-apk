# LIVRAISON G3 — Base d'exercices v1.1 dans l'application (dev6.2.0)

- **Version** : dev6.2.0 (pubspec 6.2.0+97 ; AAB « 6.2.0 »).
- **Commit main** : 92fea5a (parent e5cf07f, dev6.1.0).
- **Build signé** : run `build-apk.yml` 36860680819 (main).
- **CI de contrôle** : `claude/ci-3d`, run 36858835004 (essai 3) : formatage (correctif CI appliqué), analyse, 858 tests Dart, 14 tests du mode dev, tests Python, `packages` (kalis_core), build debug et profile, émulateur G3 a sombre + b clair : verts. Rendus `visual_capture` : échec déjà présent sur `main`.
- **Paquet intégré** : `kalis_core` 0.1.0, branche fixe `etiquettes/kalis_core-v0.1.0` (5327294), `packages/kalis_core` et `tools/catalog` non modifiés.
- **Lot déduit** : message de lancement sans « Lot : … » ; G3 était le lot attendu de la piste A (G2 validé, GC livré, « G3 lancé » par le pilotage).

## Ce qui change

- Arsenal › Exercices : base v1.1 du propriétaire (1 039 exercices, 8 disciplines) à la place du pack 2.0.0 (625). Filtres Discipline, Type de mouvement, Niveau, Lieu, Matériel, Difficulté ; recherche par nom, alias, muscle, matériel, discipline.
- Fiches : discipline, niveau, difficulté, type de charge, points clés, erreurs fréquentes, respiration, muscles (carte 2D par rôle + liste, profonds en texte), matériel et lieux, paliers conseillés, variante de / variantes.
- Correspondance anciens noms et identifiants → base v1.1 (`assets/catalog/correspondance.json`, rapport `docs/G3_CORRESPONDANCE.md`) : 169 automatiques, 291 relus « même exercice », 155 « même mouvement, petite différence », 10 sans équivalent. Programme embarqué : 78 intitulés sur 79 (le bilan de phase n'est pas un exercice).
- Historique, records et STATS : identiques (relevé chiffré produit sur `main` avant G3, run 36847477371, comparé dans `test/g3_historique_test.dart` : 240 séances × 2 historiques, 79 exercices, 65 séances à records, 40 semaines de groupes).
- Journal au format `kalis_core` : `lib/journal_adapter.dart` (C1 à C12) ; l'exemple du paquet est reproduit à l'identique.
- Démonstrations : retrouvées par l'ancien identifiant (aucune animation d'exercice n'existe encore).
- Échange d'exercice (L11) : propositions et noms enregistrés de la base v1.1.
- L13 : 15 phrases de la base reformulées à l'affichage (« soulager », « rééducation »).
- Mentions : section « Base d'exercices v1.1 ».
- CI : publication de `ci-out/` corrigée (aucun rendu différent ⇒ plus d'échec).

## Tests

- Nouveaux : `test/g3_catalogue_test.dart`, `test/g3_historique_test.dart` (+ `test/fixtures/g3_historique_avant.json`), `test/g3_mode_dev_test.dart`, `tools/tests/test_g3_catalogue.py`, `integration_test/catalogue_g3_test.dart`.
- Mis à jour (fonction remplacée, aucune assertion retirée sans équivalent) : `l9b_content_test` (base v1.1, filtres, fiches), `m3_fiche_mannequin_test` et `m8_carte_2d_test` (identifiants v1.1, muscles sans région de la base), `m4_stats_mannequin_test`, `m4c_filter_menu_test` (filtre Discipline), `l11_store_test` (nom du substitut), `g2_retrait_test` et `g2_mode_dev_test` (version 6.2.0 ; magasin initialisé hors du temps simulé), `test_g2_retrait.py` (version), `integration_test/carte_2d_m8_test` (identifiants). Ajout `scrollSlowlyTo` (test/phone_test_support.dart).
- Mesures : chargement du catalogue 81 ms (CI, JIT) ; liste de 1 039 exercices 16,8 ms/image (L9B_PERF).

## À tester par le propriétaire

1. Arsenal › Exercices : « 1039 exercices » ; Filtres › Discipline (ex. Streetlifting = 61) ; recherche « traction lestée ».
2. Une fiche par discipline : points clés, erreurs fréquentes, respiration, carte des muscles, variantes navigables.
3. Historique (STATS), records et répartition musculaire : identiques à dev6.1.0.
4. Réglages › À propos : « dev6.2.0 », « base d'exercices v1.1.0 (1039 exercices) ».
5. Session de test (5 appuis sur le logo) : même bibliothèque.
6. Relire `docs/G3_CORRESPONDANCE.md` (surtout les 155 « proche ») et `packages/kalis_core/docs/RELECTURE_CATALOGUE.md`.

## Limites

- Pas de sauvegarde réelle du propriétaire dans le dépôt : comparaison faite sur l'historique synthétique complet des 40 semaines et le banc `charge`.
- Ancien pack 2.0.0 gardé pour L10/L11 (retrait en G10) et pour les groupes de STATS des noms enregistrés.
- 15 phrases de la base à corriger à la source (L13), aujourd'hui reformulées à l'affichage.
- Rattachements « proche » relus par le lot, pas par un professionnel diplômé.
