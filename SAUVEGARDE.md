# Sauvegarde CI1c (voie App, pipeline CP)

Base : main 64e286b3 (dev6.9.1). Arbre de travail complet (sans .github).

## Fait
- Reproduction sur main (run rapide 37783043662, branche claude/ci-ci1c-rapide) : 3 échecs attendus
  (bloc importé : séance déjà ouverte non recalculée après acceptation, 5 au lieu de 6 séries ;
  street généré : idem 2 au lieu de 3 ; consultation : entrée S12-J3 créée).
- Relevé : la revue réelle sur la fixture du propriétaire (S12) ne produit aucune proposition (déblocage session_restructure).
- Code : couche d'ajustements sur le bloc importé (DayPlan.overlay/original, Exercise.koach,
  syncImportedOverlay), adaptOpen recalculé à l'ouverture (non commencée), séance commencée mise à jour
  (source), refreshUnstartedSession, forgetConsultation (fermeture), _pruneConsultations (migration),
  propositions non applicables au bloc importé filtrées (Évolution : texte clair).

## En cours / reste
- Tests ci1c complets, run rapide ALL, cible émulateur, ci-3d, relecture, publication dev6.9.2.
- Run rapide essai 2 (37784xxx) : tous les tests verts (771). Format appliqué.
- Relecture indépendante (Opus) : 10 constats ; à corriger : brouillons saisis (drapeau edited), clé record,
  couche par jour, validation du plan fusionné, règle d'échange, raison par emplacement, jours faits, carte non applicable.
- Corrections de relecture faites ; run rapide essai 3 vert (771 tests) ; version 6.9.2+110 ; README, SUIVI, CI_GP.
- Contrôle complet poussé sur claude/ci-3d : commit 8b415536 (arbre 3ba926dd).
- Reste : résultat ci-3d (captures CI1c a/b à relire), publication main, build signé, livraison.
- ci-3d essai 1 (run 37788556859) : émulateur CI1c a/b et CI1 verts ; échecs : versions attendues 6.9.1 (tests g3 dev, python), gradlew absent de l'arbre (index vide). Essai 2 poussé : 3734306e.
- Publié sur main 770589ce (arbre d361353d identique à ci-3d run 37792900255 vert). Attente build signé.
