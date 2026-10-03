/// Squelette d'un bloc du chemin street : pour chaque jour, des
/// emplacements qui portent leur méthode (comment l'exercice sera dosé
/// semaine après semaine par la passe 2).
library;

import 'package:kalis_core/kalis_core.dart';

import 'season.dart';

/// Méthodes de dosage d'un emplacement.
abstract final class Method {
  /// Force lestée, séance lourde : série de tête puis séries allégées.
  static const String liftHeavy = 'lift.heavy';

  /// Force lestée, séance de volume.
  static const String liftVolume = 'lift.volume';

  /// Force lestée, séance légère (technique, vitesse).
  static const String liftLight = 'lift.light';

  /// Force lestée, variante ciblée sur un point faible.
  static const String liftVariant = 'lift.variant';

  /// Force lestée en entretien (spécialisation d'un autre mouvement).
  static const String liftMaintain = 'lift.maintain';

  /// Répétitions : série longue puis séries allégées.
  static const String repsTop = 'reps.top';

  /// Répétitions : séries sous-maximales de volume.
  static const String repsVolume = 'reps.volume';

  /// Répétitions : densité (une série par minute, échelles).
  static const String repsDensity = 'reps.density';

  /// Répétitions : force (variante dure ou lest, séries courtes).
  static const String repsStrength = 'reps.strength';

  /// Répétitions : pratique technique, loin de l'échec (muscle-up).
  static const String repsTechnique = 'reps.technique';

  /// Répétitions : séries au format de l'épreuve.
  static const String repsEvent = 'reps.event';

  /// Débutant : double progression sur une variante adaptée.
  static const String beginnerMain = 'beginner.main';

  /// Débutant : descentes freinées.
  static const String beginnerNegative = 'beginner.negative';

  /// Débutant : maintien (suspension, appui).
  static const String beginnerHold = 'beginner.hold';

  /// Figure : maintiens sous-maximaux sur l'étape actuelle.
  static const String skillHold = 'skill.hold';

  /// Figure : maintiens longs sur une étape plus facile (jour léger).
  static const String skillEasyHold = 'skill.easy_hold';

  /// Figure : essais courts sur l'étape suivante.
  static const String skillAttempt = 'skill.attempt';

  /// Figure : travail dynamique dans le même schéma.
  static const String skillDynamic = 'skill.dynamic';

  /// Figure : pratique d'équilibre.
  static const String skillBalance = 'skill.balance';

  /// Assistance polyarticulaire.
  static const String accessoryCompound = 'accessory.compound';

  /// Jambes au poids du corps, en unilatéral.
  static const String accessoryLegs = 'accessory.legs';

  /// Isolation.
  static const String accessoryIsolation = 'accessory.isolation';

  /// Prévention (coiffe, scapulas), séries faciles.
  static const String accessoryPrehab = 'accessory.prehab';

  /// Tronc.
  static const String accessoryCore = 'accessory.core';

  /// Préparation articulaire (échauffement).
  static const String warmupPrep = 'warmup.prep';

  /// Course facile.
  static const String runEasy = 'run.easy';

  /// Sortie longue.
  static const String runLong = 'run.long';

  /// Séance de qualité (fractionné).
  static const String runQuality = 'run.quality';

  /// Mobilité en fin de séance.
  static const String mobility = 'mobility';

  /// Ordre de retrait quand le temps ou le volume manque (du premier
  /// retiré au dernier).
  static const List<String> cutOrder = <String>[
    mobility,
    accessoryIsolation,
    accessoryCore,
    accessoryPrehab,
    accessoryCompound,
    accessoryLegs,
    liftVariant,
    skillDynamic,
    skillEasyHold,
    repsVolume,
    repsDensity,
    liftLight,
    beginnerHold,
    beginnerNegative,
    skillBalance,
    repsStrength,
    repsTechnique,
    liftMaintain,
    liftVolume,
    skillAttempt,
    repsEvent,
    repsTop,
    beginnerMain,
    skillHold,
    liftHeavy,
    runEasy,
    runQuality,
    runLong,
    warmupPrep,
  ];

  /// Rang de [method] dans l'ordre de retrait (les méthodes inconnues sont
  /// retirées en premier).
  static int cutRank(String method) {
    final at = cutOrder.indexOf(method);
    return at < 0 ? 0 : at + 1;
  }
}

/// Emplacement du squelette.
final class SlotSpec {
  /// Emplacement.
  SlotSpec({
    required this.exerciseId,
    required this.role,
    required this.method,
    this.sets = 3,
    this.stress,
    this.referenceId,
    this.skillTargetId,
    this.group,
    this.weak,
    this.fromWeek = 0,
    this.untilWeek = 99,
    this.note,
  });

  /// Exercice.
  final String exerciseId;

  /// Rôle dans la séance.
  final SlotRole role;

  /// Méthode de dosage ([Method]).
  final String method;

  /// Séries de la semaine la plus chargée.
  final int sets;

  /// Jour lourd, moyen ou léger pour ce mouvement.
  final DayStress? stress;

  /// Exercice dont le record règle la charge (mouvement de compétition
  /// pour une variante, mouvement au poids du corps pour une régression).
  final String? referenceId;

  /// Figure visée dont l'exercice est une étape.
  final String? skillTargetId;

  /// Clé du groupe d'exercices enchaînés du jour (superset, circuit).
  final String? group;

  /// Point faible servi.
  final WeakPointKind? weak;

  /// Première semaine du bloc où l'emplacement est prescrit.
  final int fromWeek;

  /// Dernière semaine du bloc où l'emplacement est prescrit.
  final int untilWeek;

  /// Code de note de coach propre à l'emplacement.
  final String? note;

  /// Identifiant de l'emplacement (donné à l'assemblage).
  String slotId = '';
}

/// Séance du squelette.
final class DaySpec {
  /// Séance.
  DaySpec(this.dayIndex);

  /// Rang du jour.
  final int dayIndex;

  /// Thème (code de `FocusCodes`).
  String focus = '';

  /// Emplacements, dans l'ordre de la séance.
  final List<SlotSpec> slots = <SlotSpec>[];

  /// Vrai si la séance contient déjà l'exercice [id].
  bool hasExercise(String id) => slots.any((s) => s.exerciseId == id);
}

/// Style de programme du chemin street.
enum CoachStyle {
  /// Débutant : corps entier, progressions vers la traction, la pompe, le
  /// dips.
  beginner,

  /// Sets & reps : endurance de force au poids du corps.
  reps,

  /// Streetlifting : force lestée.
  lifting,

  /// Calisthénie : figures.
  figures,
}

/// Squelette d'un bloc.
final class Skeleton {
  /// Squelette.
  Skeleton({
    required this.style,
    required this.shape,
    required this.days,
    required this.ladders,
    required this.reasons,
    required this.intent,
  });

  /// Style.
  final CoachStyle style;

  /// Forme du bloc.
  final BlockShape shape;

  /// Séances.
  final List<DaySpec> days;

  /// Échelles des figures travaillées.
  final List<SkillLadder> ladders;

  /// Raisons du bloc (notes de coach).
  final List<Reason> reasons;

  /// Intention du bloc.
  final BlockIntent intent;

  /// Emplacement d'identifiant [slotId], ou `null`.
  SlotSpec? slot(String slotId) {
    for (final d in days) {
      for (final s in d.slots) {
        if (s.slotId == slotId) {
          return s;
        }
      }
    }
    return null;
  }
}
