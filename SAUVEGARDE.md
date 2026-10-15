# Sauvegarde KM1c3 — estimation sous notes non fiables (référence Koach 1.0.3)

Session Fable 5.1, effort maximal, démarrée le 15/10/2026 à 19:09 UTC. Base `moteurs` e502e963 (Koach 1.0.2, `kalis_adapt` 1.0.1). Contrôle `claude/ci-cp-a`. Pas de SDK Dart dans la session (campagnes Python en local sur 2 cœurs ou sur la CI par des commits « KM1c3 contrôle (dev) » à arbre réduit, comme KM1c2).

## Fait

- Démarrage : accès push vérifié (`git push --dry-run`), `add_repo` absent de la session ; ligne KM1c3 « en cours » poussée sur `pipeline` (42a6e8c7).
- Lecture : prompt, LANCEMENTS, DECISIONS (C13, C17), CAHIER_KM, LIVRAISON_KM1c2, LIVRAISON_KM2c1, CHANGEMENTS_1_0_2, `koach/modele.py` (mesure), `koach/seance.py` (`_tentative`, `_palier_barres`), `banc/adversaire.py`, `banc/campagne.py`.
- Diagnostic des 6 cas sous le plancher (`adversaires_km1c2.json`) : avant le jour J l'estimation est 4 à 8 % trop haute (p. ex. adv-1c0774cf g1 : 162,5 pour 150,8), poussée par des notes « 4 en réserve ou plus » sur des simples à 95 % du maximum ; l'ouverture = 0,91 × estimation (+ gain d'affûtage) tombe au-dessus du maximum du jour, puis A8.2 garde la barre. Les notes ouvertes contredites n'alimentent pas `_apprendre_bruit` (seules les notes à intervalle fermé le font).

- Point 1 écrit : `koach/modele.py` classe `Fiabilite` (grille a posteriori sur ln φ, Beta de la part non notée, oubli, par schéma rapporté), alimentée dans `_serie_force` ; `Modele.elargissement()` (κ) appliqué dans `capacite`, `capacite_du_jour`, `planification.tirer` (D S D) ; `posterior()['fiabilite']` ; tests `tests/test_fiabilite.py` (10 verts). Paramètres ajoutés (`mesure.fiabilite_*`, `securite.tentative_prudence_elargie`, `tentative_echec_baisse`, `echec_sans_hausse_tout_schema` : commutateurs des variantes du point 3, 0 = 1.0.2).
- Point 4 (m3) : `rupture.BORNES` `defaut_modele_sd` (0,001 ; 0,1) + bornes des clés nouvelles ; tests dans `test_rupture.py` ; `appliquer_parametres` repointe `fiabilite.p`.
- Point 5 : journal déchiffré sous `/tmp/cp-references/journal` (clé par `/tmp/cle_cp.txt` 600) ; correspondance noms → ids reconstruite (`index.json.gz` programme_v33/base_v1 → `correspondance.json` G3 → fiches : 78/79) ; `rejeu/walk_forward.py` tourne (1.0.2 : 38 séries, erreur 4,6 %, couverture 97,4 %, 167 notes : ouvertes prévues 43,7 % / observées 20,4 %).
- Mesures : harnais `variante.py` (5 jeux d'adversaires + banc graine 0 sans extension) ; base = KM1c2 reproduit (24/24, 23/24, 22/24, 20/24, 17/24). **V1 (κ² = 1 + 1,0·(E[φ]−E₀)⁺ + 12·(ρ−0,2)⁺², σ élargi seul)** : b3000 18/24 (4 sous), km1c2 18/24, b300 22/24 : l'élargissement seul abaisse l'ouverture de 5 à 9 % chez tout athlète bruité (coût −0,033 en moyenne sur b3000) sans sauver les cas à +7 % d'erreur. Banc : κ > 1,05 pour 4 % des saisons seulement, jour J 0,9577 → 0,9603 (bruit).

## En cours

- Capture des ouvertures (`ouvertures.py`) sur les cinq jeux et le banc pour évaluer hors ligne des règles d'ouverture (palier des barres conditionné à κ, barre dite à la limite non reprise comme ouverture, quantile) avant de remesurer.

## Reste à faire

Points 1 à 5 du prompt, critères, relecture, fin de lot (voir `pipeline/cp/prompts/KM1c3.txt`).

## Décisions prises

- Point 4 (m3) : borne basse 0,001 pour `mesure.defaut_modele_sd` (cohérente avec la règle des clés `_sd`).
- Indicateur : zone morte aux moyennes a priori (E₀[φ] = 1,133, ρ₀ = 0,2) : κ = 1 exactement pour un athlète au moins aussi fiable que l'a priori.
- Constat : les zéros du jour J viennent d'une estimation > +4 % avant l'échéance ; sur les adversaires, la part des estimations à +4 % passe de 7 % (notes fiables) à 17 % (notes bruitées ou non notées ≥ 30 %).
