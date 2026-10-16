### KM2c2

Lot livré le 16/10/2026 (session Opus 5.5, effort maximal, C17.13.4), validation automatique par le pilotage sur
les critères du cahier (C13.3) : `kalis_adapt` 1.0.2 (Koach 1.0.3 en Dart) et `kalis_bench` 0.5.1, `moteurs` 4910ec13,
étiquettes publiées, contrôle complet `claude/ci-cp-a` run 38858101198 vert. Détail :
`pipeline/cp/livraisons/LIVRAISON_KM2c2.md`, `kalis_bench` `docs/CRITERES_KM2C2.md`.

- **KM2c2.1 Lancement** : message sans ligne « Lot : » ; seul lot moteur « à faire » (KS1c1 « en cours » sur la voie
  B, contrôle `claude/ci-cp-b`). `add_repo` absent de la session ; accès en écriture vérifié par `git push --dry-run`
  puis par le push de la ligne « en cours ». Pas de SDK Dart (proxy) : mise au point sur la CI (`claude/ci-cp-a`,
  commits « KM2c2 contrôle (dev) » à arbre réduit, workflow de mise au point qui rend le formatage en patch et lance
  la campagne en quatre parts parallèles). Clé des références non lue (aucune référence privée nécessaire).
- **KM2c2.2 Portage** : delta de `CHANGEMENTS_1_0_3.md` (A à D, H) porté ligne à ligne ; asset
  `koach_params_1_0_3.json` (338 clés) ; tests repointés, copies figées de 1.0.2 supprimées ; API inchangée,
  `posterior()['fiabilite']`.
- **KM2c2.3 Fixtures complémentaires** (relecture, M1) : trois fixtures produites par la référence sans la modifier
  (`kalis_adapt/test/fixtures/km2c2/`) pour les branches que les 15 fixtures n'exécutent pas (tentative ratée hors
  compétition et en compétition, jumeau avec κ > 1). `reference/fixtures/generer.py`, `tirage_intermediaire` n'applique
  pas κ (aide au portage, sans effet sur les fixtures livrées) : signalé, non modifié.
- **KM2c2.4 Saisons figées** : depuis `kalis_plan` 0.4.0 (KS1), la saison vivante du banc n'est plus celle que lit la
  référence (`donnees/reference/`, 0.3.1) : une campagne Dart sur les saisons vivantes diverge (12 adversaires de
  `autres_03_powerlifter_competition`, prévisions de la planification), sans rapport avec le delta. `kalis_bench` 0.5.1
  ajoute `--saisons-figees` ; mesurée ainsi (témoin relu), la campagne Dart six graines est identique à la référence
  (critères 1 à 4, 6, 7, secondaires, bilan ; `calibration_grappes` champ pour champ) et les six jeux d'adversaires
  aussi (7 bis : 24, 22, 22, 21, 22 ; recherche de KM1c3 19/24). Temps 0,335 s et 9,7 ms. 0 violation.
- **KM2c2.5 Relecture indépendante** (sous-agent Opus, deux passes) : 0 bloquant, 0 majeur ; M1 (couverture) traité
  par KM2c2.3 ; mineurs traités (docs, types de `resume`, journal muté cohérent, scénarios de la matrice tirés du
  fichier figé).
- **KM2c2.6 Recommandations (C8)** : (a) valider KM2c2 comme portage de Koach 1.0.3 : KM3 intègre `kalis_adapt` 1.0.2
  (simple montée de paquet depuis 1.0.0 ou 1.0.1, asset de paramètres à remplacer) ; (b) le lot suivant de Koach
  régénère les données de référence (`reference/donnees/reference/`, témoin, fixtures du banc) sur `kalis_plan` 0.4.x
  après KS1c1, comme le prévoit le prompt ; d'ici là, toute comparaison Dart ↔ Python passe par `--saisons-figees`.
