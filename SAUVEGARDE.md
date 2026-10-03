# Sauvegarde du lot CQ (kalis_core 0.4.0)

Session de reprise du 03/10/2026 (05:51 UTC). L'arbre de cette branche = `moteurs` + le travail du lot (sans `.github/`).

## Fait
- Reprise de l'arbre de `claude/ci-cp-b` (commit 0c5945c4, seconde passe après relectures ; run 37071267552 : tests verts, seul le formatage échouait).
- Vérification indépendante des 84 références de `docs/PROFIL_V3.md` (3 vérificateurs) : 9 corrections faites.
- Audit indépendant de `docs/RELECTURES_CQ.md` contre l'arbre : constats traités (body_weight_goal reportée pour un débutant, recent_training après skills, CONTRAT §1/§9/§12/§13, PacingSegment.setReps min 1, tableau débutant par discipline, RELECTURES remis à jour : plus aucun « À ARBITRER »).
- Générateurs relancés ; `pytest tools/catalog/tests` : 86 verts.

## En cours (mis à jour 07:35 UTC)
- Run 37103369029 : seuls 2 tests du parcours échouaient (attente « recovery » alors que body_weight_goal est aussi reportée) : corrigés ; sources formatées appliquées ; zz_dev_test retiré ; passe finale poussée.
- Contrôle CI sur `claude/ci-cp-b` (run 37103369029 lancé à 06:32 UTC, environ 45 min) : 1) passe avec `test/zz_dev_test.dart` (export des sources formatées dans `ci-out/packages/kalis_core/formatted`), 2) copie des sources formatées (lib, test, bin), retrait de `zz_dev_test.dart`, passe finale.

## Reste à faire
- Commit « Kalis Track moteurs (CQ) : kalis_core 0.4.0 » sur `moteurs` (rebase), branche `etiquettes/kalis_core-v0.4.0`.
- `pipeline/cp/livraisons/LIVRAISON_CQ.md` + projet claude.ai ; section CQ de `DECISIONS_CP.md` ; ligne CQ d'`ETAT_CP.md` et tableau des étiquettes ; page de suivi (partie « Calibrage ») ; notification.

## Décisions prises
- Débutant : aucune question de récupération à la création (4 questions reportées) ; du schéma 3, seulement skills / emphasis / events / running_base selon la discipline (16 à 18 questions).
- Pas de SDK Dart dans la session : le formatage passe par la CI.
- Brouillon de LIVRAISON_CQ.md prêt (dans la session ; contenu repris de CHANGELOG, PROFIL_V3, PARCOURS_V3, RELECTURES_CQ).
