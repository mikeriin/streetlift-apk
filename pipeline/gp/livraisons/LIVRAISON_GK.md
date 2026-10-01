# Livraison GK — Koach vectorisé, flammes et paquet `kalis_koach` (piste K)

- Date : 01/10/2026 (Opus 5.5, effort élevé). Validation : automatique (contrôles verts).
- Paquet : `kalis_koach` **0.1.0**, branche `koach`, commit **4fa2777** (« Kalis Track koach (GK) : kalis_koach 0.1.0 »).
- Contrôle : `claude/ci-gp-koach`, run **36831108263** vert (paquet : formatage, `dart analyze --fatal-infos`, 36 tests, simulateur ; outils Python : 9 tests dont la régénération du Dart à l'identique).
- **Étiquette `kalis_koach-v0.1.0` : créée localement, push refusé par le serveur (HTTP 403, deux essais)**. Statut : en attente du propriétaire. À faire : `git tag -a kalis_koach-v0.1.0 4fa2777 -m "kalis_koach 0.1.0 (lot GK)"` puis `git push origin kalis_koach-v0.1.0` (ou une release GitHub sur 4fa2777). Le même blocage concernera probablement les étiquettes de la piste M.
- Page de suivi : https://claude.ai/artifact/7tr7vJvnnn85KzVx5qYRw5 (partie Koach).

## Contenu

- `tools/koach/` : `build_koach.py` (chaîne complète, `--check`, `--controle`), `segment.py` (découpe par composantes connexes avec contrôles, nettoyage, yeux, mesures), `vectorize.py` (potrace, commandes, rendu pair-impair, IoU), `poses.json` (catalogue), `sources/` (copie des planches, SHA-256 contrôlées), `requirements.txt` (versions figées), `tests/`.
- `packages/kalis_koach/` : `lib/` (format des commandes, 36 poses en 3 calques encre / papier / yeux, boîtes des yeux, fiches émotion / usages / regard / bulle, 10 flammes encre / silhouette / creux, teinte D5.5, libellé d'accessibilité ; répliques : 28 événements, 99 messages, priorités, actions, « Pourquoi ? », table extensible de 6 codes de raison), `bin/kalis_koach_cli.dart --rapport` (inventaire, cas types, SVG), `test/`, `README.md`, `CONTRAT.md`, `CHANGELOG.md`, `docs/controle/` (planches clair / sombre, gros plans, calques des flammes, tableau IoU), `docs/cas_types.md` (relus).

## Résultats

- IoU par pose (rendu des commandes relues dans le Dart généré) : min **0,990** avec la silhouette nettoyée, **0,971** avec la planche brute ; flammes min **0,991**. Exigence 0,97 tenue partout.
- Poids du Dart généré : 371 Ko (plafond 400 Ko). SVG exportés par le paquet en CI identiques aux données (0 écart).
- 36 identifiants du prompt vérifiés sur les images : tous corrects. Yeux fermés : happy, victory, cheer, heart, clap, fist_up, present. Bustes : choice, idea, settings.
- Choix d'une réplique : 4 µs (CI).

## Décisions (DECISIONS_GP.md, section GK)

Traits de séparation conservés et régularisés ; normalisation en pied / buste ; repère yeux / pieds ; regard mesuré ; table de raisons d'exemple ; sources copiées sur `koach`.

## Limites

- Traits de séparation plus épais que sur les planches (choix réversible) ; petites encoches tête-épaules devenues des tirets arrondis visibles seulement en gros plan.
- Codes de raison : exemples, à relier aux codes de `kalis_core` / `kalis_adapt` (G9, G10).
- Textes non relus par un professionnel diplômé.

## Pour G5

`git fetch origin --tags && git checkout kalis_koach-v0.1.0 -- packages/kalis_koach` (une fois l'étiquette poussée) ; implémenter un `KoachPathSink` vers `Path` (`PathFillType.evenOdd`), couleurs D6.2 (CONTRAT § 2), clignement par écrasement vertical du calque yeux autour de `eyeBoxes`, `koachCommonFrame` pour garder Koach en place entre deux poses.
