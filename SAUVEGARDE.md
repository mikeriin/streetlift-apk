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
