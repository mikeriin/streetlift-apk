# Sauvegarde KM3 (Koach 1.0 dans l'application, dev7.0.0)

Session Opus 5.5 application, lancée le 16/10/2026 06:44 UTC (C17.14). Base `main` 72596f38 (dev6.19.0).

## Décisions prises (INTEGRATION_KM3.md § 10, délégation C8)

1. Avant la bascule : le moteur de dev6.19.0 (0.3.1) continue de servir le bloc en cours (prompt : « le bloc en cours n'est pas coupé »). Bascule fermée dans ce build (`kKoachBasculeAutorisee = false`) : la version validée (1.0.3, KM2c2) et le rejeu du journal réel (C17.13.3) sont exigés ; la session de test du mode dev force la bascule (`koachForceBascule`). Prise de main au début d'un bloc ; programme créé : premier bloc après l'installation.
2. Profil de Koach figé (instantané) : limite acceptée.
3. Refus du récapitulatif de fin de bloc : noté, le plan modulé reste (anti-complaisance).
4. « Moins de temps » : `duree_max_min` en `contexte.budget` ; séances par semaine gardées (information).
5. Arrêt d'urgence : séances servies telles qu'écrites (+ semaine modulée gardée), avis de consulter gardé.
6. Crans d'élastique : pas de champ (limite).
7. `jours_avant_echeance` non passé (comme au banc).
8. Corrections a posteriori : remplacement + rejeu (à faire : rejeu en arrière-plan).
9. Séances libres ignorées.
10. Échéance : jour de test de S40 ; cibles : objectifs (`koach.objectives`) d'abord, sinon `mainLifts.target`.
11. Données 0.x : gardées, lues telles quelles.

## Fait

- Paquet `kalis_adapt` = `etiquettes/kalis_adapt-v1.0.2` (Koach 1.0.3) à l'octet ; assets `assets/koach/` (params 1_0_3).
- `lib/koach1/koach_moteur.dart` (fabrique, instantané, isolat, rattrapage, essai N-of-1), `koach_journal.dart` (événements), `koach_rejeu.dart` (walk-forward A).
- `lib/koach1_store.dart` (section `koachEngine`, bascule, prise de main, rattrapage, séance, cibles, charge fixe, suggestions, fin de séance, arrêt, récap, exports).
- Branchements dans `session_adapt_store.dart`, `store.dart`, `main.dart`, `program_origin.dart`.

## Fait (suite)

- Interface (suggestion, refus, diagnostic, récap, arrêt d'urgence, Réglages › Koach 1.0, Évolution), inspecteur du mode dev, prévision sur copie, tests km3 (16 verts en rapide), captures ui_km3, cible émulateur koach_km3_test + ci3d_drive.sh, limite d'arbre 50 Mo.

## Reste (ancien)

- Interface : carte de suggestion, refus avec raisons, diagnostic, récap de bloc, arrêt d'urgence, inspecteur et outils du mode dev, textes clusters, retraits (mode assisté/libre, moteur d'avant, option de structure).
- pubspec (version 7.0.0, assets), tests km3, cible émulateur, CI.

## En cours

- Contrôle complet claude/ci-3d (run lancé sur ca8544c6, puis à relancer sur la pointe) ; publication main, build signé, livraison.
