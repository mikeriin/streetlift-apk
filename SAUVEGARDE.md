# Sauvegarde KM2c1 (portage Dart de Koach 1.0.2, kalis_adapt 1.0.1)

Base : `moteurs` 9ac79e40. Session Opus 5.5 lancée le 15/10/2026 ~15:29 UTC.

## Fait
- Delta 1.0.2 porté dans `packages/kalis_adapt/lib/src/koach/` : seance.dart (reprise par paliers, `_palierBarres`, tentatives, test xRM jour d'épreuve, Memoire.barres/barresRatees, serieFaite palier_franchi, ancre douleur seulement), modele.dart (`capacite(brut:)`, intervalle_echelle), dual.dart (brut: true x2), planification.dart (dispersion_echeance ; previsions.prevu_jour), rupture.dart (4 bornes).
- Asset renommé `assets/koach/koach_params_1_0_2.json` (= reference/params/koach_params_v1.json, 1.0.2-ref.1, 322 clés, SHA 211c9361…), parametres.dart à jour.
- Tests repointés vers `reference/fixtures/` et `koach_params_v1.json` ; moteur_11 ajouté aux boucles ; copies `fix_dart/` et `koach_params_d1.json` supprimées.
- kalis_bench : `kmCritereApparie` (critère 7 bis) dans `kmComparerAdversaires` + test ; fixtures km2 régénérées (generer_banc_km2.py) ; _evaluationPython (1.0.2) mis à jour.
- Versions : kalis_adapt 1.0.1, kalis_bench 0.4.2.

- Premier contrôle dev (run 38762512163) : compilation OK, analyse OK, parité 14 fixtures OK, banc km2 OK ; 2 échecs corrigés (invariant « bilan bas » du test de propriétés réécrit pour A.2 de 1.0.2 ; `_min` typé).
- Relecture indépendante (Opus) traitée : B1 (moyenne séquentielle quand E=1, C>1 — vérifié bit à bit sur numpy), M1 (campagne : prevu_jour, observe, couverture_paires), m1 (test), m2 (commentaire). m3 (borne defaut_modele_sd 0 refusée par la règle _sd) : signalé au pilotage, non modifié (référence).

## Résultats
- Adversaires (run 38764346154, Koach sans extension, témoin relu) : Dart = Python à l'identique sur les 5 jeux (koach, groupes, critere_7_bis) — 7 bis : KM1 24/24, b300 23/24, complet b600 22/24, b3000 20/24 (2 sous plancher), recherche km1c2 17/24 (6).
- Run 38766161412 : kalis_bench 109 tests verts ; kalis_adapt 1 échec (docs/PROPRIETAIRE.md, version) corrigé ; campagne g0-5 : 4 parts (~10 min chacune) dans /home/claude/aa/parts (copie dans ci-out du commit ca79b38c).

- Assemblage fait : critères Dart = Python (1-4, 6, 7) ; critère 5 C13.13.1 identique ; données dans kalis_bench/docs/data/km2c1, doc CRITERES_KM2C1.md.
- Commit final local e502e963 (worktree /home/claude/mot), brouillon /home/claude/LIVRAISON_KM2c1.md.

## En cours
- Contrôle complet 01d46b69 sur claude/ci-cp-a (arbre de e502e963).
- Incident : cp-sauvegardes/KM2c1-candidat poussée avec .github → build APK run 38777553043 annulé ; suppression de branche refusée (403).
- Contrôle dev fb0e0ec6 sur claude/ci-cp-a : tests + 5 jeux d'adversaires (7 bis, sans extension, témoin relu) + campagne g0-5 en 4 parties + assemblage (outil `aa_km2c1`, `extra.sh` dans /home/claude/aa).

## Reste
- Corriger la compilation / parité ; formatage.
- Campagne Dart six graines (4 parties) + assemblage ; adversaires (7 bis) ; temps.
- Relecture indépendante (sous-agent Opus).
- Docs (CHANGELOG, CONTRAT.md, INTEGRATION_KM3.md, PORTAGE_DART.md, README référence), contrôle complet, push moteurs, étiquettes, livraison, état, page de suivi, notification.
