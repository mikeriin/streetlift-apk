# Changelog — kalis_koach

## 0.1.0 — 01/10/2026 (lot GK)

- Première version.
- 36 poses vectorisées (planches A pédagogie, B émotions, C énergie) : découpe par composantes
  connexes, traits de séparation nettoyés et régularisés, normalisation (pieds sur y = 0, 1 000
  unités de haut, bustes à taille de tête égale), calques encre / papier / yeux, boîtes des yeux pour
  le clignement, regard et côté de la bulle. IoU ≥ 0,99 avec la silhouette nettoyée.
- 10 flammes de difficulté : encre, silhouette, creux ; teinte du dégradé (D5.5) et libellé
  d'accessibilité.
- Répliques : 28 événements, 99 messages français, priorités, actions, explications « Pourquoi ? »,
  table extensible des codes de raison (6 exemples).
- Simulateur `bin/kalis_koach_cli.dart --rapport`.
