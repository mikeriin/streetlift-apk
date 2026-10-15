# Sauvegarde KM1c3 — estimation sous notes non fiables (référence Koach 1.0.3)

Session Fable 5.1, effort maximal, démarrée le 15/10/2026 à 19:09 UTC. Base `moteurs` e502e963 (Koach 1.0.2, `kalis_adapt` 1.0.1). Contrôle `claude/ci-cp-a`. Pas de SDK Dart dans la session (campagnes Python en local sur 2 cœurs ou sur la CI par des commits « KM1c3 contrôle (dev) » à arbre réduit, comme KM1c2).

## Fait

- Démarrage : accès push vérifié (`git push --dry-run`), `add_repo` absent de la session ; ligne KM1c3 « en cours » poussée sur `pipeline` (42a6e8c7).
- Lecture : prompt, LANCEMENTS, DECISIONS (C13, C17), CAHIER_KM, LIVRAISON_KM1c2, LIVRAISON_KM2c1, CHANGEMENTS_1_0_2, `koach/modele.py` (mesure), `koach/seance.py` (`_tentative`, `_palier_barres`), `banc/adversaire.py`, `banc/campagne.py`.
- Diagnostic des 6 cas sous le plancher (`adversaires_km1c2.json`) : avant le jour J l'estimation est 4 à 8 % trop haute (p. ex. adv-1c0774cf g1 : 162,5 pour 150,8), poussée par des notes « 4 en réserve ou plus » sur des simples à 95 % du maximum ; l'ouverture = 0,91 × estimation (+ gain d'affûtage) tombe au-dessus du maximum du jour, puis A8.2 garde la barre. Les notes ouvertes contredites n'alimentent pas `_apprendre_bruit` (seules les notes à intervalle fermé le font).

## En cours

- Collecte (`collecte.py`, scratchpad) sur les 448 saisons des cinq jeux d'adversaires : fiabilité observée des notes (z², bruit_rir appris, part non notée) contre erreur et couverture, pour concevoir l'indicateur du point 1.

## Reste à faire

Points 1 à 5 du prompt, critères, relecture, fin de lot (voir `pipeline/cp/prompts/KM1c3.txt`).

## Décisions prises

- Point 4 (m3) : borne basse strictement positive pour `mesure.defaut_modele_sd` (à confirmer à l'écriture).
