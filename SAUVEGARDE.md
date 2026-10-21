# Sauvegarde KB4 (dev7.4.0)

Base : main 88fb1965 (dev7.3.0). Session lancée 21/10/2026 04:22 UTC (« Lot : KB4 »).

## Fait
- Paquet kalis_adapt 1.0.6 copié à l'octet (lib/, assets/koach/, pubspec.yaml), asset koach_params_1_0_7.json (app + paquet), kKoachParamsAsset, version 7.4.0+148.

## Décisions
- Lignes « EMOM N min × R reps par minute » (reps fixes) : une ligne par minute, départ chronométré 60 s (comme « 12×6 · EMOM », PR1), servies telles qu'écrites (asWritten, règle PR8) Koach actif comme arrêté.
- Garde : tous les rôles ; motifs : douleur, endurance, test reporté, séance bornée au temps donné, rampe tendineuse (retour_gradue bras_tendus à 0).
- Réactivation : séances « open » finies pendant l'arrêt fermées (seance_fin) avant le rattrapage ; aperçus périmés retirés ; carte d'accueil « Réactiver Koach » (jamais automatique).

## Fait aussi
- Code complet (garde, réactivation, EMOM, carte, inspecteur), tests kb4 (rapide run 39545379840 : 14/15 verts, 1 test corrigé), kb3/kb1/versions, cible koach_kb4_test + ci3d_drive.sh, relecture Opus traitée (commit 6f35433c sur claude/ci-ui-kb4-rapide).

- Rapide vert (run 39547004881) sur 53016cac ; contrôle complet poussé sur claude/ci-3d (5e7545ca) à 05:05 UTC.

- ci-3d 39547568156 : tests sauf G10 (instantané EMOM, corrigé), émulateur : KB4 sur l'en-tête (corrigé), ci1c/ci1f pannes VM. Relance ci-3d 01f7a4a0 (07:24 UTC) sur d522c365. Brouillon de livraison dans le scratchpad (LIVRAISON_KB4.md) copié ici.

## Reste
- Code (garde, réactivation, EMOM, carte), tests kb4, mise à jour kb3/kb1/versions, cible émulateur, CI rapide puis ci-3d, main, build, livraison.
