# Journal des versions de kalis_adapt

## 0.1.0

Première version (lot G8 du pipeline « Génération et progression »).

- `KalisAdapt` réalise `AdaptEngine` de kalis_core 0.2.0 : `prescribeSession`, `adviseNextSet`,
  `review` ; `estimates`, `applyProposal`.
- Modèle individuel : filtre de Kalman par exercice sur la capacité opérationnelle (tendance locale
  amortie, forme de la courbe répétitions ↔ charge, effet de jour), observation des séries avec bornes
  (notes absentes, « 5 et plus », séries terminées, séries ratées), écrêtage des écarts aberrants,
  fatigue dans la séance, forme et fatigue entre les séances, forme du jour, notes peu informatives,
  partage entre exercices proches, coupures.
- Décisions : charge à hystérésis sur la grille réelle du matériel, plafonds de hausse, calibrage,
  séries notées « 5 et plus », conseil pendant la séance (écart de 2 flammes), série repère, bilan santé
  gradué, douleur, lieu et temps du jour, charge minimale trop lourde, programme importé, tests.
- Revue : résumé d'adaptation, propositions (volume, décharge anticipée, échange, épargne d'une zone,
  restructurations par `kalis_plan`) filtrées par déblocage, confiance et utilité ; records ; journal du
  moteur.
- Simulateur d'athlètes à vérité connue (`lib/simulation.dart`), comparaison à la double progression, à
  l'ancien moteur L7/L11 et à l'oracle ; lignes de commande `kalis_adapt:simulate`, `kalis_adapt:replay`,
  `bin/kalis_adapt_cli.dart`.
- Validation : `docs/` (mesures de la campagne, lecture, rejeu du programme importé du propriétaire),
  référence croisée Python, tests de propriétés sur 10 240 journaux aléatoires.
