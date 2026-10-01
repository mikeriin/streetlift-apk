# Journal des versions de kalis_quest

## 0.1.0

Première version (lot G11 du pipeline « Génération et progression »).

- `KalisQuest` réalise `QuestEngine` de kalis_core 0.3.0 : `evaluate` rend l'état (registres d'XP et de
  Krédits en ajout seul, quêtes, état opaque), le niveau, les attributs, les rangs, l'avancement des
  objectifs, les événements nouveaux, les objectifs suggérés, les records et les données de présentation.
- XP : effort rapporté au programme (réalisation × justesse des flammes, combo, plafonds par séance et
  par semaine), régularité et jours de repos, records, jalons d'objectif, quêtes. Niveaux 1 à 100 puis
  prestige ; courbe calée par la simulation de rythme.
- Garde-fous : aucun XP au-delà du programme ; aucune récompense pour une séance faite malgré une
  douleur déclarée ; un jour de repos ou de pause ne propose que de la récupération ; rien n'est jamais
  retiré.
- Attributs et rangs par mouvement sur standards par sexe et poids de corps (`docs/STANDARDS.md`).
- Quêtes quotidiennes, hebdomadaires, de campagne et Koach, déterministes (graine + date).
- Objectifs : jalons le long de la courbe prévue, prédiction (médiane, intervalle à 80 %), retard,
  suggestions à 60 % de chances d'atteinte.
- Coffres à taux variable avec garantie, série de semaines avec pauses, fantôme, note de séance, combo,
  récapitulatif hebdomadaire, comparaisons dans le temps.
- Simulation de rythme (`lib/simulation.dart`), lignes de commande `kalis_quest:simulate` et
  `bin/kalis_quest_cli.dart`, documents de `docs/`.
