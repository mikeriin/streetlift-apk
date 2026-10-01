/// Interfaces des trois moteurs. `kalis_core` ne contient aucune
/// implémentation : `kalis_plan` (G4), `kalis_adapt` (G8) et `kalis_quest`
/// (G11) les réalisent, l'application ne dépend que de ces interfaces.
///
/// Règles communes à toute implémentation (PIPELINE_GP.md §2) : fonctions
/// pures — aucune horloge (« aujourd'hui » est dans la requête), aucun
/// hasard hors de la graine fournie, aucun stockage ; deux appels identiques
/// rendent un résultat identique à l'octet près une fois sérialisé ; aucune
/// phrase, seulement des codes de raison du registre.
library;

import 'catalog.dart';
import 'contracts.dart';

/// Moteur statique : création et restructuration du programme (D4).
abstract interface class PlanEngine {
  /// Version sémantique du moteur, recopiée dans les programmes produits.
  String get engineVersion;

  /// Passe 1 : le bloc, ses jours, ses exercices et leurs rôles (D4.4).
  ///
  /// Déterministe : même requête, même programme ; une autre proposition
  /// s'obtient par une autre graine (D4.3).
  Pass1Plan createPass1(Catalog catalog, PlanRequest request);

  /// Applique une action de revue à [current] (D4.5, D4.6) : ce qui est
  /// verrouillé ne bouge pas, le reste est ré-optimisé, le diff dit ce qui
  /// a bougé et pourquoi. [request] porte les verrous déjà posés.
  ReviewResult review(
    Catalog catalog,
    PlanRequest request,
    Pass1Plan current,
    ReviewAction action,
  );

  /// Variantes de l'exercice de l'emplacement [slotId] : jusqu'à 3 ciblées
  /// (plus facile, équivalente, autre matériel) et toutes les admissibles.
  VariantSet variants(
    Catalog catalog,
    PlanRequest request,
    Pass1Plan current,
    String slotId,
  );

  /// Passe 2 : prescriptions par semaine du programme validé (D4.7).
  Pass2Plan createPass2(Catalog catalog, PlanRequest request, Pass1Plan pass1);

  /// Bloc suivant, construit à partir du précédent et des données réelles
  /// (D4.8).
  BlockProposal nextBlock(Catalog catalog, NextBlockRequest request);

  /// Restructuration d'une séance, d'une semaine ou d'un bloc, demandée par
  /// le moteur dynamique (D5.1).
  BlockProposal restructure(Catalog catalog, RestructureRequest request);
}

/// Moteur dynamique : suivi et adaptation (D5).
abstract interface class AdaptEngine {
  /// Version sémantique du moteur.
  String get engineVersion;

  /// Prescription de la séance ([weekIndex], [dayIndex]) du bloc en cours,
  /// ajustée au journal et au bilan santé du jour (D5.8, D5.9).
  ///
  /// Une réponse absente de [healthCheck] n'est jamais remplacée par une
  /// valeur par défaut.
  SessionPlan prescribeSession(
    Catalog catalog,
    AdaptInput input, {
    required int weekIndex,
    required int dayIndex,
    HealthCheck? healthCheck,
  });

  /// Conseil pour la série suivante d'un exercice, d'après les séries déjà
  /// faites dans la séance en cours.
  IntraSessionAdvice adviseNextSet(
    Catalog catalog,
    AdaptInput input,
    SessionPlan session,
    List<SetRecord> done,
  );

  /// Revue complète : estimations, propositions, résumé d'adaptation,
  /// journal du moteur et état à repasser au prochain appel.
  AdaptReview review(Catalog catalog, AdaptInput input);
}

/// Moteur de progression : niveau, attributs, rangs, quêtes, objectifs (D7).
abstract interface class QuestEngine {
  /// Version sémantique du moteur.
  String get engineVersion;

  /// Recalcule la progression depuis tout le journal. Les registres d'XP et
  /// de Krédits de l'état rendu prolongent ceux de l'état reçu sans jamais
  /// en retirer ni en modifier une écriture (D7.3).
  QuestOutcome evaluate(Catalog catalog, QuestInput input);
}
