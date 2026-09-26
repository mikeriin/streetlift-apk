# Livraison L9 — pack de contenu Kalis Track v1 (première passe)

Date : 26/09/2026 · Statut : **livré, relecture du propriétaire requise** · Application : inchangée (aucun build).

## Livrables
- Branche orpheline `content-pack` (commit 14d3952) : `kalis_content_pack_v1.zip` (≈ 0,5 Mo, 31 fichiers) et le dossier `kalis_content_pack/` décompressé.
- Outil de relecture publié : https://claude.ai/artifact/MfMKxQMztc1rd85LLhUn6S (relectures enregistrées dans la base partagée de l'artefact, collection `relectures` ; export JSON possible). Version autonome : `review_tool.html` dans le pack.

## Contenu
- `exercises_v2.json` : 555 exercices (505 de la base v1 rattachés + 50 ajouts), schéma v2 complet ; 505 utilisables par le générateur ; 22 doublons et 50 non-conformités signalés sans suppression ; 19 tests.
- `progressions.json` : 24 arbres (pompes mur → un bras, tractions suspension → lestées, dips banc → lestés, squat → pistol, back squat, charnière, gainage, muscle-up, front et back lever, planche, ATR, HSPU, L-sit, drapeau, mobilité épaules/hanches/chevilles), 142 étapes, 12 entrées « débutant complet ».
- `poses.json` : squelette 2D, 200 gabarits de 1 à 4 images clés, pose pour 100 % des exercices ; couleurs par rôles (6 palettes × 2 modes).
- `renderer_reference/` : moteur HTML/SVG/JS autonome (spécification pour L9b) avec version statique.
- `mapping_v1_to_v2.json` : 505 noms v1 et 79 intitulés du programme v33 rattachés (avec méthodes).
- `coverage_report.md`, `validation_register.md`, `licences.md`, `CONTRAT_L9.md`, `README.md`, `tools/`.

## Résultats exacts des tests
- `python3 -m unittest discover -s tools/tests -v` (avec les entrées v1 et programme) : **25 tests, 25 OK**.
- `tools/validate.py` : schéma, graphe, poses, interpolation, correspondances, prérequis, substitutions : **OK** ; 79 manques de couverture signalés (non bloquants) ; 39 avertissements « difficulté ≥ 7 sans prérequis explicite ».

## Décisions prises par défaut
D-L9-01 à D-L9-10 (voir `CONTRAT_L9.md` §6) ; les points à confirmer sont dans `pipeline/DECISIONS_EN_ATTENTE.md`.

## Suite
Aucun lot lancé. Après la relecture, lancer la seconde passe (trig_01KyxRKcUDA45rdHQAw4xVGM) : elle lit les relectures, corrige et pousse `kalis_content_pack_v1_final.zip` sur `content-pack`.
