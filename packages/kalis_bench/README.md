# kalis_bench

Banc d'essai du calibrage des programmes de Kalis Track (pipeline CP). Il dit ce qu'est un excellent programme pour chaque profil, du débutant à l'élite, comment on le mesure et qui le juge.

- **Lire d'abord** : `CONTRAT.md`, puis `docs/REFERENTIEL.md` (référentiel), `docs/CRITERES.md` (critères calculables), `docs/PANEL.md` (panel de coachs virtuels), `docs/BASELINE_0_1.md` (où en sont les moteurs 0.1).
- **Lancer** : `dart run bin/kalis_bench_cli.dart --rapport <dossier>` (rapport complet, comme en CI) ou `dart run kalis_bench:run --moteur croisement --profils street --graine 0 --sortie <dossier>`.
- **Export pour le panel** : `python3 tool/panel_export.py <dossier>/programmes/<profil>.json` (programme concis, sans redite des semaines identiques).
- **Saisons croisées** (0.2.0, lot CX) : le rapport complet écrit aussi `saisons.json`, `SAISONS.md` et `saisons/` (chaque profil street sur sa saison entière, huit scénarios imposés) ; journal du calibrage : `docs/CALIBRAGE_CX.md` ; manche « saisons » de la page de relecture : `tool/relecture/build_manche_saisons.py`.
- **Profils** : `profiles/`, format dans `docs/PROFILS.md` ; `python3 tool/gen_profiles.py --check`.

Les programmes de référence privés ne sont pas dans ce paquet : seules des mesures agrégées et anonymes y figurent (`docs/MESURES_REFERENCES.md`).
