// G6 (D1.6, D3, D5.8, D6) : création du profil d'athlète v2 (`kalis_core`).
//
// Modèle pur (aucune dépendance Flutter) : brouillon de la création du
// profil, validation de chaque étape, construction du profil v2 du contrat
// figé par GC (`AthleteProfile`, schéma 2), section versionnée de la
// sauvegarde (`athleteProfile`, v1) et données de présentation (disciplines,
// mouvements de référence et fourchettes, matériel regroupé, zones du
// corps). L'horloge est passée en paramètre.
//
// Le profil L8 (`profile.dart`) n'est plus utilisé pour décrire
// l'utilisateur : il reste lu pour l'import et garde le bloc santé du
// questionnaire L13 (consentement, réponses, accord du médecin), qui
// continue de décider du mode prudent.
import 'package:kalis_core/kalis_core.dart';

import 'profile.dart';

/// Version de la section `athleteProfile` de la sauvegarde.
const int kAthleteSectionVersion = 1;

/// Identifiant du questionnaire santé référencé par le profil v2
/// (`HealthScreeningRef.questionnaireId`) : celui de L8/L13, inchangé.
const String kHealthQuestionnaireId = 'kalis-aptitude-l8-v1';

String _two(int n) => n.toString().padLeft(2, '0');

/// Jour civil d'une date locale.
CivilDate civilOf(DateTime d) => CivilDate(d.year, d.month, d.day);

/// Date locale (minuit) d'un jour civil.
DateTime dateOfCivil(CivilDate d) => DateTime(d.year, d.month, d.day);

final RegExp _atRe = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$');
bool _okAt(Object? v) =>
    v is String && _atRe.hasMatch(v) && DateTime.tryParse(v) != null;

/// Horodatage local « AAAA-MM-JJTHH:MM:SS ».
String athleteAt(DateTime d) => profileAt(d);

// ================================================================ disciplines

/// Libellé d'une discipline du profil (D3.1).
const kDisciplineLabels = <TrainingDiscipline, String>{
  TrainingDiscipline.musculation: 'Musculation',
  TrainingDiscipline.streetWorkout: 'Street workout',
  TrainingDiscipline.streetlifting: 'Streetlifting',
  TrainingDiscipline.calisthenics: 'Calisthénie',
  TrainingDiscipline.crossfit: 'CrossFit / WOD',
  TrainingDiscipline.cardio: 'Cardio',
  TrainingDiscipline.mobility: 'Mobilité',
  TrainingDiscipline.generalFitness: 'Forme générale',
};

/// Une phrase d'explication par discipline (écran de la discipline).
const kDisciplineHints = <TrainingDiscipline, String>{
  TrainingDiscipline.musculation:
      'Machines, barres et haltères pour gagner en force et en muscle.',
  TrainingDiscipline.streetWorkout:
      'Le poids du corps à la barre et aux barres parallèles : tractions, '
      'dips, pompes, en séries.',
  TrainingDiscipline.streetlifting:
      'Tractions, dips et muscle-ups lestés, plus le squat : la force sur '
      'quatre mouvements de compétition.',
  TrainingDiscipline.calisthenics:
      'Les figures : équilibre sur les mains, front lever, planche, '
      'muscle-up, et leurs étapes.',
  TrainingDiscipline.crossfit:
      'Des enchaînements variés et intenses, haltérophilie et gymnastique '
      'comprises (sans l’ancien onglet WOD).',
  TrainingDiscipline.cardio:
      'Course, vélo, rameur, corde à sauter : le souffle et l’endurance.',
  TrainingDiscipline.mobility:
      'Souplesse et amplitude des articulations, sans forcer.',
  TrainingDiscipline.generalFitness:
      'Un peu de tout pour être en forme au quotidien : force, souffle et '
      'mobilité.',
};

/// Libellé d'une composante du mode street (D3.3).
const kStreetStyleLabels = <StreetStyle, String>{
  StreetStyle.streetlifting: 'Streetlifting',
  StreetStyle.setsReps: 'Sets & reps',
  StreetStyle.calisthenics: 'Calisthénie',
};

const kStreetStyleHints = <StreetStyle, String>{
  StreetStyle.streetlifting:
      'Charges maximales lestées : traction, dips, muscle-up, squat.',
  StreetStyle.setsReps: 'Beaucoup de répétitions au poids du corps, en séries.',
  StreetStyle.calisthenics: 'Les figures et leur maîtrise.',
};

/// Libellé du niveau global d'expérience (D3.5).
const kExperienceLabels = <ExperienceLevel, String>{
  ExperienceLevel.beginner: 'Je débute',
  ExperienceLevel.intermediate: 'Je m’entraîne depuis quelques mois',
  ExperienceLevel.advanced: 'Je m’entraîne depuis plus de 2 ans',
  ExperienceLevel.elite: 'Je fais de la compétition',
};

/// Mode assisté ou libre (D3.7, D5.6).
const kGuidanceLabels = <GuidanceMode, String>{
  GuidanceMode.assisted: 'Assisté',
  GuidanceMode.free: 'Libre',
};

const kSexLabels = <Sex, String>{
  Sex.female: 'Femme',
  Sex.male: 'Homme',
  Sex.undisclosed: 'Je préfère ne pas le dire',
};

const kPlaceNames = <Place, String>{
  Place.gym: 'Salle',
  Place.home: 'Maison',
  Place.outdoor: 'Extérieur',
};

/// Phrase d'aperçu d'un dosage (« environ 1 séance sur 5 en mobilité »).
String dosageInWords(TrainingDiscipline d, int pct) {
  final label = kDisciplineLabels[d]!.toLowerCase();
  if (pct >= 100) return 'Toutes tes séances en $label';
  if (pct <= 0) return 'Aucune séance en $label';
  final n = (100 / pct).round();
  if (n <= 1) return 'Presque toutes tes séances en $label';
  if (pct > 50) {
    return 'Environ ${(pct / 10).round()} séances sur 10 en $label';
  }
  return 'Environ 1 séance sur $n en $label';
}

String streetDosageInWords(StreetStyle s, int pct) {
  final label = kStreetStyleLabels[s]!;
  if (pct <= 0) return 'Pas de $label';
  final n = (100 / pct).round();
  if (pct > 50) return '$label : environ ${(pct / 10).round()} séances sur 10';
  return '$label : environ 1 séance sur $n';
}

// ================================================== mouvements de référence

/// Fourchette proposée pour un mouvement (D3.5).
class LevelBand {
  final double low, high;
  final String label;
  const LevelBand(this.low, this.high, this.label);
}

/// Mouvement de référence de la déclaration de niveau : un exercice du
/// catalogue, une grandeur et des fourchettes (choix raisonné du lot, sans
/// valeur normative : les moteurs prennent la borne basse).
class LevelMovement {
  final String key, exerciseId, label, question;
  final LevelMeasure measure;
  final List<LevelBand> bands;
  final double? distanceMeters;
  const LevelMovement(
    this.key,
    this.exerciseId,
    this.measure,
    this.label,
    this.question,
    this.bands, {
    this.distanceMeters,
  });
}

const _repsHard = [
  LevelBand(0, 0, '0'),
  LevelBand(1, 3, '1 à 3'),
  LevelBand(4, 7, '4 à 7'),
  LevelBand(8, 12, '8 à 12'),
  LevelBand(13, 20, '13 à 20'),
  LevelBand(21, 30, '21 à 30'),
  LevelBand(31, 45, 'Plus de 30'),
];

const kLevelMovements = <LevelMovement>[
  LevelMovement(
    'pullups',
    'sw-traction-pronation',
    LevelMeasure.maxReps,
    'Tractions',
    'Combien de tractions d’affilée, menton au-dessus de la barre ?',
    _repsHard,
  ),
  LevelMovement(
    'pushups',
    'sw-pompe',
    LevelMeasure.maxReps,
    'Pompes',
    'Combien de pompes d’affilée, corps gainé ?',
    [
      LevelBand(0, 0, '0'),
      LevelBand(1, 5, '1 à 5'),
      LevelBand(6, 15, '6 à 15'),
      LevelBand(16, 30, '16 à 30'),
      LevelBand(31, 50, '31 à 50'),
      LevelBand(51, 80, 'Plus de 50'),
    ],
  ),
  LevelMovement(
    'dips',
    'sw-dips-barres-paralleles',
    LevelMeasure.maxReps,
    'Dips',
    'Combien de dips d’affilée aux barres parallèles ?',
    [
      LevelBand(0, 0, '0'),
      LevelBand(1, 3, '1 à 3'),
      LevelBand(4, 8, '4 à 8'),
      LevelBand(9, 15, '9 à 15'),
      LevelBand(16, 25, '16 à 25'),
      LevelBand(26, 40, 'Plus de 25'),
    ],
  ),
  LevelMovement(
    'muscleup',
    'cd-muscle-up-barre-strict',
    LevelMeasure.maxReps,
    'Muscle-up',
    'Combien de muscle-ups stricts d’affilée ?',
    [
      LevelBand(0, 0, '0'),
      LevelBand(1, 2, '1 ou 2'),
      LevelBand(3, 5, '3 à 5'),
      LevelBand(6, 10, '6 à 10'),
      LevelBand(11, 20, 'Plus de 10'),
    ],
  ),
  LevelMovement(
    'squat',
    'mu-back-squat-barre-haute',
    LevelMeasure.oneRmKg,
    'Squat',
    'Ta charge maximale au squat sur une répétition (barre comprise) ?',
    [
      LevelBand(20, 40, 'Moins de 40 kg'),
      LevelBand(40, 60, '40 à 60 kg'),
      LevelBand(60, 80, '60 à 80 kg'),
      LevelBand(80, 100, '80 à 100 kg'),
      LevelBand(100, 130, '100 à 130 kg'),
      LevelBand(130, 160, '130 à 160 kg'),
      LevelBand(160, 220, 'Plus de 160 kg'),
    ],
  ),
  LevelMovement(
    'deadlift',
    'mu-souleve-de-terre-conventionnel',
    LevelMeasure.oneRmKg,
    'Soulevé de terre',
    'Ta charge maximale au soulevé de terre sur une répétition ?',
    [
      LevelBand(40, 60, 'Moins de 60 kg'),
      LevelBand(60, 90, '60 à 90 kg'),
      LevelBand(90, 120, '90 à 120 kg'),
      LevelBand(120, 150, '120 à 150 kg'),
      LevelBand(150, 180, '150 à 180 kg'),
      LevelBand(180, 220, '180 à 220 kg'),
      LevelBand(220, 300, 'Plus de 220 kg'),
    ],
  ),
  LevelMovement(
    'bench',
    'mu-developpe-couche-barre',
    LevelMeasure.oneRmKg,
    'Développé couché',
    'Ta charge maximale au développé couché sur une répétition ?',
    [
      LevelBand(20, 40, 'Moins de 40 kg'),
      LevelBand(40, 60, '40 à 60 kg'),
      LevelBand(60, 80, '60 à 80 kg'),
      LevelBand(80, 100, '80 à 100 kg'),
      LevelBand(100, 120, '100 à 120 kg'),
      LevelBand(120, 150, '120 à 150 kg'),
      LevelBand(150, 200, 'Plus de 150 kg'),
    ],
  ),
  LevelMovement(
    'weighted_pullup',
    'sl-traction-lestee',
    LevelMeasure.oneRmKg,
    'Traction lestée',
    'Ton lest maximal à la traction sur une répétition (lest seul) ?',
    [
      LevelBand(0, 10, 'Moins de 10 kg'),
      LevelBand(10, 20, '10 à 20 kg'),
      LevelBand(20, 35, '20 à 35 kg'),
      LevelBand(35, 50, '35 à 50 kg'),
      LevelBand(50, 70, '50 à 70 kg'),
      LevelBand(70, 100, 'Plus de 70 kg'),
    ],
  ),
  LevelMovement(
    'weighted_dips',
    'sl-dips-leste',
    LevelMeasure.oneRmKg,
    'Dips lesté',
    'Ton lest maximal aux dips sur une répétition (lest seul) ?',
    [
      LevelBand(0, 15, 'Moins de 15 kg'),
      LevelBand(15, 30, '15 à 30 kg'),
      LevelBand(30, 50, '30 à 50 kg'),
      LevelBand(50, 70, '50 à 70 kg'),
      LevelBand(70, 90, '70 à 90 kg'),
      LevelBand(90, 130, 'Plus de 90 kg'),
    ],
  ),
  LevelMovement(
    'weighted_muscleup',
    'sl-muscle-up-leste',
    LevelMeasure.oneRmKg,
    'Muscle-up lesté',
    'Ton lest maximal au muscle-up sur une répétition (lest seul) ?',
    [
      LevelBand(0, 5, 'Moins de 5 kg'),
      LevelBand(5, 10, '5 à 10 kg'),
      LevelBand(10, 20, '10 à 20 kg'),
      LevelBand(20, 30, '20 à 30 kg'),
      LevelBand(30, 45, 'Plus de 30 kg'),
    ],
  ),
  LevelMovement(
    'competition_squat',
    'sl-squat-competition',
    LevelMeasure.oneRmKg,
    'Squat de compétition',
    'Ta charge maximale au squat de compétition (barre comprise) ?',
    [
      LevelBand(20, 40, 'Moins de 40 kg'),
      LevelBand(40, 60, '40 à 60 kg'),
      LevelBand(60, 80, '60 à 80 kg'),
      LevelBand(80, 100, '80 à 100 kg'),
      LevelBand(100, 130, '100 à 130 kg'),
      LevelBand(130, 160, '130 à 160 kg'),
      LevelBand(160, 220, 'Plus de 160 kg'),
    ],
  ),
  LevelMovement(
    'plank',
    'mu-gainage-ventral-coudes',
    LevelMeasure.maxHoldSeconds,
    'Gainage',
    'Combien de temps tiens-tu le gainage sur les coudes ?',
    [
      LevelBand(10, 30, 'Moins de 30 s'),
      LevelBand(30, 60, '30 s à 1 min'),
      LevelBand(60, 90, '1 min à 1 min 30'),
      LevelBand(90, 120, '1 min 30 à 2 min'),
      LevelBand(120, 180, '2 à 3 min'),
      LevelBand(180, 300, 'Plus de 3 min'),
    ],
  ),
  LevelMovement(
    'dead_hang',
    'sw-dead-hang',
    LevelMeasure.maxHoldSeconds,
    'Suspension à la barre',
    'Combien de temps restes-tu suspendu à la barre ?',
    [
      LevelBand(5, 15, 'Moins de 15 s'),
      LevelBand(15, 30, '15 à 30 s'),
      LevelBand(30, 60, '30 s à 1 min'),
      LevelBand(60, 90, '1 min à 1 min 30'),
      LevelBand(90, 150, 'Plus de 1 min 30'),
    ],
  ),
  LevelMovement(
    'handstand',
    'cs-handstand-ventre-au-mur',
    LevelMeasure.maxHoldSeconds,
    'Équilibre sur les mains (au mur)',
    'Combien de temps tiens-tu sur les mains, ventre face au mur ?',
    [
      LevelBand(0, 0, 'Je ne tiens pas'),
      LevelBand(1, 10, '1 à 10 s'),
      LevelBand(11, 30, '11 à 30 s'),
      LevelBand(31, 60, '31 s à 1 min'),
      LevelBand(61, 120, 'Plus de 1 min'),
    ],
  ),
  LevelMovement(
    'front_lever',
    'cs-front-lever-tuck',
    LevelMeasure.maxHoldSeconds,
    'Front lever groupé',
    'Combien de temps tiens-tu le front lever groupé (tuck) ?',
    [
      LevelBand(0, 0, 'Je ne tiens pas'),
      LevelBand(1, 5, '1 à 5 s'),
      LevelBand(6, 10, '6 à 10 s'),
      LevelBand(11, 20, '11 à 20 s'),
      LevelBand(21, 40, 'Plus de 20 s'),
    ],
  ),
  LevelMovement(
    'run_5k',
    'ca-footing-endurance-fondamentale',
    LevelMeasure.timeSeconds,
    'Course de 5 km',
    'En combien de temps cours-tu 5 km ?',
    [
      LevelBand(2400, 3600, 'Plus de 40 min'),
      LevelBand(2100, 2400, '35 à 40 min'),
      LevelBand(1800, 2100, '30 à 35 min'),
      LevelBand(1500, 1800, '25 à 30 min'),
      LevelBand(1320, 1500, '22 à 25 min'),
      LevelBand(1200, 1320, '20 à 22 min'),
      LevelBand(960, 1200, 'Moins de 20 min'),
    ],
    distanceMeters: 5000,
  ),
  LevelMovement(
    'air_squat',
    'mu-air-squat',
    LevelMeasure.maxReps,
    'Squats au poids du corps',
    'Combien de squats au poids du corps d’affilée ?',
    [
      LevelBand(1, 10, 'Moins de 10'),
      LevelBand(10, 25, '10 à 25'),
      LevelBand(26, 50, '26 à 50'),
      LevelBand(51, 80, '51 à 80'),
      LevelBand(81, 120, 'Plus de 80'),
    ],
  ),
  LevelMovement(
    'deep_squat',
    'mo-squat-profond-tenu',
    LevelMeasure.maxHoldSeconds,
    'Souplesse : squat profond',
    'Combien de temps restes-tu accroupi, talons au sol ?',
    [
      LevelBand(0, 0, 'Je n’y arrive pas'),
      LevelBand(1, 30, 'Moins de 30 s'),
      LevelBand(30, 60, '30 s à 1 min'),
      LevelBand(61, 120, '1 à 2 min'),
      LevelBand(121, 300, 'Plus de 2 min'),
    ],
  ),
  LevelMovement(
    'half_split',
    'mo-demi-grand-ecart',
    LevelMeasure.maxHoldSeconds,
    'Souplesse : demi-grand écart',
    'Combien de temps tiens-tu le demi-grand écart, sans douleur ?',
    [
      LevelBand(0, 0, 'Je n’y arrive pas'),
      LevelBand(1, 30, 'Moins de 30 s'),
      LevelBand(30, 60, '30 s à 1 min'),
      LevelBand(61, 120, '1 à 2 min'),
      LevelBand(121, 300, 'Plus de 2 min'),
    ],
  ),
];

LevelMovement? levelMovement(String key) {
  for (final m in kLevelMovements) {
    if (m.key == key) return m;
  }
  return null;
}

LevelMovement? levelMovementForExercise(String exerciseId) {
  for (final m in kLevelMovements) {
    if (m.exerciseId == exerciseId) return m;
  }
  return null;
}

/// Mouvements proposés par discipline, du plus parlant au moins parlant.
const kDisciplineMovements = <TrainingDiscipline, List<String>>{
  TrainingDiscipline.musculation: [
    'squat',
    'deadlift',
    'bench',
    'pullups',
    'pushups',
    'plank',
  ],
  TrainingDiscipline.streetWorkout: [
    'pullups',
    'pushups',
    'dips',
    'muscleup',
    'dead_hang',
  ],
  TrainingDiscipline.streetlifting: [
    'weighted_pullup',
    'weighted_dips',
    'weighted_muscleup',
    'competition_squat',
    'pullups',
    'dips',
  ],
  TrainingDiscipline.calisthenics: [
    'pullups',
    'dips',
    'muscleup',
    'handstand',
    'front_lever',
    'pushups',
  ],
  TrainingDiscipline.crossfit: [
    'pullups',
    'squat',
    'deadlift',
    'run_5k',
    'pushups',
  ],
  TrainingDiscipline.cardio: ['run_5k', 'plank'],
  TrainingDiscipline.mobility: ['deep_squat', 'half_split'],
  TrainingDiscipline.generalFitness: [
    'pushups',
    'air_squat',
    'plank',
    'run_5k',
  ],
};

/// Au plus autant de mouvements proposés (≈ 5 minutes au total, D3.4).
const int kMaxLevelMovements = 9;

/// Mouvements proposés pour des disciplines (principale d'abord).
List<LevelMovement> movementsFor(List<TrainingDiscipline> disciplines) {
  final keys = <String>[];
  // Tour à tour : les premiers mouvements de chaque discipline passent
  // avant les derniers de la principale.
  final lists = [
    for (final d in disciplines) kDisciplineMovements[d] ?? const <String>[],
  ];
  final longest = lists.fold<int>(0, (a, l) => l.length > a ? l.length : a);
  for (var rank = 0; rank < longest; rank++) {
    for (var i = 0; i < lists.length; i++) {
      // La principale compte double : ses deux premiers mouvements d'abord.
      final take = i == 0 ? 2 : 1;
      for (var k = rank * take; k < (rank + 1) * take; k++) {
        if (k < lists[i].length && !keys.contains(lists[i][k])) {
          keys.add(lists[i][k]);
        }
      }
    }
  }
  return [for (final k in keys.take(kMaxLevelMovements)) levelMovement(k)!];
}

// ================================================================ matériel

/// Groupes du vocabulaire `materiel` de la base (les 68 termes, chacun
/// dans un seul groupe ; test : tout le vocabulaire est couvert).
const kEquipmentGroups = <(String, List<String>)>[
  ('Au sol, sans matériel', ['aucun (sol)', 'tapis', 'mur', 'serviette']),
  (
    'Barres et agrès',
    [
      'barre fixe',
      'barres parallèles',
      'barre basse',
      'anneaux',
      'sangles de suspension',
      'parallettes',
      'espalier',
      'poteau vertical',
      'station dips / relevés de jambes',
    ],
  ),
  (
    'Barres et disques',
    [
      'barre olympique',
      'disques',
      'barre EZ',
      'barre hexagonale',
      'barre de sécurité (safety bar)',
      'landmine',
      'chaînes',
    ],
  ),
  (
    'Haltères, kettlebells et ballons',
    [
      'haltères',
      'kettlebell',
      'médecine-ball',
      'sac lesté',
      'cible murale (wall ball)',
    ],
  ),
  ('Élastiques', ['élastique', 'bande de résistance mini (mini-band)']),
  (
    'Bancs, racks et supports',
    [
      'banc plat',
      'banc inclinable',
      'cage / rack',
      'box / plinth',
      'step',
      'banc à lombaires',
      'GHD',
      'pupitre (banc Larry Scott)',
    ],
  ),
  (
    'Machines et poulies',
    [
      'poulie',
      'machine guidée',
      'Smith machine',
      'presse à cuisses',
      'hack squat',
      'machine à mollets',
      'traîneau',
    ],
  ),
  (
    'Lest',
    ['ceinture de lest', 'gilet lesté', 'sac à dos lesté', 'harnais de nuque'],
  ),
  (
    'Accessoires',
    [
      'magnésie',
      'roue abdominale',
      'ballon de gym',
      'sliders',
      'corde',
      'sangles de tirage',
      'rouleau de poignet',
      'pince de préhension',
      'barre à grosse prise / grip épais',
    ],
  ),
  (
    'Cardio',
    [
      'corde à sauter',
      'rameur',
      'vélo / home-trainer',
      'air bike (assault / echo)',
      'SkiErg',
      'tapis de course',
      'piste ou terrain extérieur',
      'côte ou escaliers',
      'piscine',
      'cônes',
    ],
  ),
  (
    'Mobilité et récupération',
    ['rouleau de massage (foam roller)', 'balle de massage', 'bâton'],
  ),
];

/// Tout le matériel regroupé, dans l'ordre des groupes.
final List<String> kAllGroupedEquipment = [
  for (final g in kEquipmentGroups) ...g.$2,
];

/// Préréglage de matériel (remplace la sélection du lieu choisi).
class EquipmentPreset {
  final String id, label;
  final List<String> equipment;
  const EquipmentPreset(this.id, this.label, this.equipment);
}

const _homeBare = ['aucun (sol)', 'mur', 'tapis', 'serviette'];

final List<EquipmentPreset> kEquipmentPresets = [
  EquipmentPreset('gym_full', 'Salle complète', [
    for (final e in kAllGroupedEquipment)
      if (!const {
        'piste ou terrain extérieur',
        'côte ou escaliers',
        'piscine',
        'poteau vertical',
        'sac à dos lesté',
        'harnais de nuque',
      }.contains(e))
        e,
  ]),
  const EquipmentPreset('home_bare', 'Maison sans matériel', _homeBare),
  const EquipmentPreset('bar_bands', 'Barre de traction + élastiques', [
    ..._homeBare,
    'barre fixe',
    'élastique',
    'bande de résistance mini (mini-band)',
  ]),
  const EquipmentPreset('home_equipped', 'Maison équipée', [
    ..._homeBare,
    'barre fixe',
    'élastique',
    'bande de résistance mini (mini-band)',
    'haltères',
    'kettlebell',
    'banc plat',
    'corde à sauter',
  ]),
  const EquipmentPreset('park', 'Parc de street workout', [
    'aucun (sol)',
    'barre fixe',
    'barres parallèles',
    'barre basse',
    'espalier',
    'piste ou terrain extérieur',
  ]),
  const EquipmentPreset('outdoor_run', 'Dehors, pour courir', [
    'aucun (sol)',
    'piste ou terrain extérieur',
    'côte ou escaliers',
  ]),
];

EquipmentPreset? equipmentPreset(String id) {
  for (final p in kEquipmentPresets) {
    if (p.id == id) return p;
  }
  return null;
}

/// Matériel proposé quand un lieu est choisi (modifiable).
List<String> defaultEquipmentFor(Place p) => switch (p) {
  Place.gym => equipmentPreset('gym_full')!.equipment,
  Place.home => equipmentPreset('home_bare')!.equipment,
  Place.outdoor => equipmentPreset('outdoor_run')!.equipment,
};

/// Matériel trié dans l'ordre du vocabulaire de la base.
List<String> sortEquipment(Iterable<String> items, List<String> vocabulary) {
  final set = items.toSet();
  final order = vocabulary.isEmpty ? kAllGroupedEquipment : vocabulary;
  return [
    for (final e in order)
      if (set.contains(e)) e,
    for (final e in set)
      if (!order.contains(e)) e,
  ];
}

// =================================================== zones et articulations

/// Libellé d'une zone du corps (blessures, gênes).
const kZoneLabels = <BodyZone, String>{
  BodyZone.neck: 'Cou',
  BodyZone.shoulder: 'Épaule',
  BodyZone.elbow: 'Coude et bras',
  BodyZone.wristHand: 'Poignet, main et avant-bras',
  BodyZone.upperBack: 'Haut du dos',
  BodyZone.lowerBack: 'Bas du dos',
  BodyZone.chest: 'Poitrine',
  BodyZone.abdomen: 'Ventre',
  BodyZone.hip: 'Hanche et fessier',
  BodyZone.thigh: 'Cuisse',
  BodyZone.knee: 'Genou',
  BodyZone.lowerLeg: 'Jambe (mollet, tibia)',
  BodyZone.ankleFoot: 'Cheville et pied',
};

const kSideLabels = <BodySide, String>{
  BodySide.left: 'Gauche',
  BodySide.right: 'Droite',
  BodySide.both: 'Des deux côtés',
};

/// Zone désignée par une région de la carte des muscles (carte 2D).
const kRegionZones = <String, BodyZone>{
  'trapeze_superieur': BodyZone.neck,
  'extenseurs_cervicaux': BodyZone.neck,
  'sterno_cleido_mastoidien': BodyZone.neck,
  'cou': BodyZone.neck,
  'deltoide_anterieur': BodyZone.shoulder,
  'deltoide_moyen': BodyZone.shoulder,
  'deltoide_posterieur': BodyZone.shoulder,
  'sous_epineux': BodyZone.shoulder,
  'trapeze_moyen': BodyZone.upperBack,
  'trapeze_inferieur': BodyZone.upperBack,
  'rhomboides': BodyZone.upperBack,
  'grand_rond': BodyZone.upperBack,
  'grand_dorsal': BodyZone.upperBack,
  'grand_pectoral': BodyZone.chest,
  'dentele_anterieur': BodyZone.chest,
  'biceps': BodyZone.elbow,
  'brachial': BodyZone.elbow,
  'triceps_long': BodyZone.elbow,
  'triceps_lateral': BodyZone.elbow,
  'triceps_medial': BodyZone.elbow,
  'brachio_radial': BodyZone.elbow,
  'flechisseurs': BodyZone.wristHand,
  'extenseurs': BodyZone.wristHand,
  'droit_abdomen': BodyZone.abdomen,
  'oblique_externe': BodyZone.abdomen,
  'lombaires': BodyZone.lowerBack,
  'grand_fessier': BodyZone.hip,
  'moyen_fessier': BodyZone.hip,
  'tenseur_fascia_lata': BodyZone.hip,
  'iliopsoas': BodyZone.hip,
  'pectine': BodyZone.hip,
  'couturier': BodyZone.thigh,
  'adducteurs': BodyZone.thigh,
  'droit_femoral': BodyZone.thigh,
  'vaste_lateral': BodyZone.thigh,
  'vaste_medial': BodyZone.thigh,
  'biceps_femoral': BodyZone.thigh,
  'semi_tendineux': BodyZone.thigh,
  'gastrocnemien_medial': BodyZone.lowerLeg,
  'gastrocnemien_lateral': BodyZone.lowerLeg,
  'soleaire': BodyZone.lowerLeg,
  'fibulaires': BodyZone.lowerLeg,
  'tibial_anterieur': BodyZone.lowerLeg,
  'extenseurs_orteils': BodyZone.ankleFoot,
};

/// Régions de la carte qui montrent une zone (zone sans région : les
/// articulations seules, choisies dans la liste).
List<String> regionsOfZone(BodyZone z) => [
  for (final e in kRegionZones.entries)
    if (e.value == z) e.key,
];

/// Zones des gênes L8 → zones du profil v2 (« Autre » n'a pas
/// d'équivalent).
const kLegacyZones = <String, BodyZone>{
  'shoulder': BodyZone.shoulder,
  'elbow': BodyZone.elbow,
  'wrist': BodyZone.wristHand,
  'lower_back': BodyZone.lowerBack,
  'neck': BodyZone.neck,
  'hip': BodyZone.hip,
  'knee': BodyZone.knee,
  'ankle': BodyZone.ankleFoot,
};

/// Clé stable d'une limitation (une seule par zone et côté).
String limitationKey(Limitation l) => '${l.zone.code}|${l.side.code}';

/// Limitation d'une zone : l'articulation est celle que la zone désigne
/// (contraintes articulaires du catalogue), sinon aucune.
Limitation limitationOf(BodyZone zone, BodySide side, int discomfort) =>
    Limitation(
      zone: zone,
      side: side,
      joint: zone.joint,
      discomfort: discomfort.clamp(0, 10).toInt(),
    );

// ================================================================== objectifs

/// Unité affichée d'une grandeur d'objectif.
String goalMetricLabel(GoalMetric m) => switch (m) {
  GoalMetric.oneRmKg => 'Charge maximale (1 répétition)',
  GoalMetric.maxReps => 'Répétitions d’affilée',
  GoalMetric.maxHoldSeconds => 'Temps de tenue',
  GoalMetric.skillUnlocked => 'Réussir la figure',
  GoalMetric.timeSeconds => 'Temps sur une distance',
  GoalMetric.distanceMeters => 'Distance en un temps donné',
};

/// Durée lisible : « 25 min 30 s », « 45 s », « 1 h 05 ».
String durationText(num seconds) {
  final s = seconds.round();
  if (s < 60) return '$s s';
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, r = s % 60;
  if (h > 0) return '$h h ${_two(m)}';
  return r == 0 ? '$m min' : '$m min ${_two(r)} s';
}

String _num(num v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v
      .toStringAsFixed(2)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll('.', ',');
}

String numText(num v) => _num(v);

const _months = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

/// « 12 janvier 2027 ».
String civilText(CivilDate d) =>
    '${d.day == 1 ? '1er' : d.day} ${_months[d.month - 1]} ${d.year}';

/// Phrase d'un objectif ([name] : nom de l'exercice).
String goalText(Goal g, String Function(String id) name) {
  if (g.kind == GoalKind.habit) {
    final n = g.sessionsPerWeek ?? 0;
    final w = g.weeks ?? 0;
    return '$n séance${n > 1 ? 's' : ''} par semaine pendant $w semaine'
        '${w > 1 ? 's' : ''}';
  }
  final ex = g.exerciseId == null ? '' : name(g.exerciseId!);
  final v = g.targetValue;
  final what = switch (g.metric) {
    GoalMetric.oneRmKg => '${_num(v ?? 0)} kg sur 1 répétition',
    GoalMetric.maxReps =>
      '${_num(v ?? 0)} répétition${(v ?? 0) > 1 ? 's' : ''} d’affilée'
          '${g.loadKg != null && g.loadKg! > 0 ? ' à ${_num(g.loadKg!)} kg' : ''}',
    GoalMetric.maxHoldSeconds => 'tenir ${durationText(v ?? 0)}',
    GoalMetric.skillUnlocked => 'réussir la figure',
    GoalMetric.timeSeconds =>
      '${_distance(g.distanceMeters ?? 0)} en ${durationText(v ?? 0)}',
    GoalMetric.distanceMeters =>
      '${_distance(v ?? 0)} en ${durationText(g.durationSeconds ?? 0)}',
    null => '',
  };
  final date = g.targetDate == null
      ? ''
      : ' d’ici le ${civilText(g.targetDate!)}';
  return '$ex : $what$date';
}

String _distance(num meters) =>
    meters >= 1000 ? '${_num(meters / 1000)} km' : '${_num(meters)} m';

/// Grandeurs possibles d'un objectif de performance pour un exercice.
List<GoalMetric> metricsFor(CatalogExercise e) {
  final out = <GoalMetric>[];
  final loadable = const {
    LoadType.barbell,
    LoadType.dumbbells,
    LoadType.kettlebell,
    LoadType.addedWeight,
    LoadType.machine,
    LoadType.cable,
  }.contains(e.loadType);
  final figure = const {
    CatalogDiscipline.calisthenicsStatic,
    CatalogDiscipline.calisthenicsDynamic,
    CatalogDiscipline.streetWorkout,
  }.contains(e.discipline);
  switch (e.unit) {
    case MeasureUnit.repetitions:
      if (loadable) out.add(GoalMetric.oneRmKg);
      out.add(GoalMetric.maxReps);
      if (figure) out.add(GoalMetric.skillUnlocked);
    case MeasureUnit.seconds:
      if (e.discipline == CatalogDiscipline.cardio) {
        out.addAll([GoalMetric.timeSeconds, GoalMetric.distanceMeters]);
      } else {
        out.add(GoalMetric.maxHoldSeconds);
        if (figure) out.add(GoalMetric.skillUnlocked);
      }
    case MeasureUnit.distance:
      out.addAll([GoalMetric.timeSeconds, GoalMetric.distanceMeters]);
    case MeasureUnit.calories:
      out.add(GoalMetric.timeSeconds);
  }
  return out;
}

/// Identifiant d'objectif libre (« goal-3 »), unique dans [goals].
String nextGoalId(Iterable<Goal> goals) {
  var n = 0;
  for (final g in goals) {
    final m = RegExp(r'^goal-(\d+)$').firstMatch(g.id);
    if (m != null) {
      final v = int.parse(m.group(1)!);
      if (v > n) n = v;
    }
  }
  return 'goal-${n + 1}';
}

// ============================================================ étapes du flux

/// Étapes de la création du profil (un écran = une question, D3.4).
const kAthleteSteps = [
  'welcome',
  'identity',
  'discipline',
  'secondary',
  'levels',
  'goals',
  'availability',
  'places',
  'health',
  'preferences',
  'mode',
  'recap',
];

/// Rubrique de l'écran Profil (Réglages › Profil) → étape du flux.
const kRubricTitles = <String, String>{
  'identity': 'Toi',
  'discipline': 'Discipline principale',
  'secondary': 'Disciplines secondaires',
  'levels': 'Niveau par mouvement',
  'goals': 'Objectifs',
  'availability': 'Disponibilités',
  'places': 'Lieux et matériel',
  'health': 'Santé, blessures et gênes',
  'preferences': 'Exercices aimés et détestés',
  'mode': 'Mode assisté ou libre',
};

/// Durées proposées par jour (D3.6) ; saisie libre de 10 à 300 min.
const kMinutePresets = [20, 30, 45, 60, 75, 90];

const kWeekdayNames = [
  'lundi',
  'mardi',
  'mercredi',
  'jeudi',
  'vendredi',
  'samedi',
  'dimanche',
];

String weekdayName(int d) => kWeekdayNames[d - 1];
String weekdayTitle(int d) =>
    kWeekdayNames[d - 1][0].toUpperCase() + kWeekdayNames[d - 1].substring(1);

// ================================================================== brouillon

/// Réponses en cours de la création du profil (brouillon gardé si
/// l'application est fermée, jamais pour un âge de moins de 18 ans).
class ProfileDraft {
  String displayName = '';
  Sex? sex;
  String birthYear = '';
  bool? adult18;
  String height = '';
  String weight = '';

  bool street = false;
  TrainingDiscipline? primary;
  StreetStyle? streetPrimary;

  /// Secondaires (hors mode street) et leur part, dans l'ordre du choix.
  final Map<TrainingDiscipline, int> secondaries = {};

  /// Parts des trois composantes du mode street.
  final Map<StreetStyle, int> streetPcts = {};

  ExperienceLevel? experience;

  /// Mouvement → fourchette choisie (rang), -1 = « je ne sais pas ».
  final Map<String, int> levels = {};

  /// Objectifs ; le premier est l'objectif principal.
  final List<Goal> goals = [];

  /// Jour ISO → minutes.
  final Map<int, int> days = {};

  /// Jour ISO → lieu (plusieurs lieux seulement).
  final Map<int, Place> dayPlace = {};

  /// Lieux choisis et matériel de chacun.
  final Map<Place, Set<String>> places = {};

  /// Consentement aux données de santé : 'given', 'refused' (null : pas
  /// encore répondu).
  String? consent;
  final Map<String, bool> answers = {};
  final List<Limitation> limitations = [];

  final List<String> liked = [];
  final List<String> disliked = [];

  GuidanceMode? guidance;

  /// Champs du profil existant que le flux ne demande pas (gardés tels
  /// quels à la modification) : création, incréments, revue du programme.
  CivilDate? createdOn;
  List<LoadIncrement> loadIncrements = const [];
  List<String>? knownExerciseIds;
  List<String>? cannotDoExerciseIds;

  /// Fourchettes de mouvements hors de la liste proposée (profil existant).
  List<MovementLevel> extraLevels = const [];

  ProfileDraft();

  int? get birthYearValue => int.tryParse(birthYear.trim());
  int? get heightValue => int.tryParse(height.trim());

  /// Poids : null si vide, NaN si invalide.
  double? get weightValue {
    final t = weight.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    final v = double.tryParse(t);
    return v == null || v < 25 || v > 300 ? double.nan : v;
  }

  int? ageIn(int year) {
    final by = birthYearValue;
    return by == null ? null : year - by;
  }

  /// Moins de 18 ans (18 ans dans l'année : « déjà fêté tes 18 ans ? »).
  bool isMinorIn(int year) {
    final a = ageIn(year);
    return a != null && (a < 18 || (a == 18 && adult18 == false));
  }

  /// Disciplines choisies, principale d'abord.
  List<TrainingDiscipline> get disciplines {
    if (street) {
      final p = streetPrimary;
      if (p == null) return const [];
      final mode = streetMode;
      return [
        p.discipline,
        for (final s in StreetStyle.values)
          if (s != p && (mode == null || mode.pctOf(s) > 0)) s.discipline,
      ];
    }
    final p = primary;
    if (p == null) return const [];
    return [p, ...secondaries.keys];
  }

  int get primaryPct => 100 - secondaries.values.fold<int>(0, (a, b) => a + b);

  /// Mode street du brouillon (null si désactivé ou incomplet).
  StreetMode? get streetMode {
    final p = streetPrimary;
    if (!street || p == null) return null;
    int pct(StreetStyle s) => streetPcts[s] ?? 0;
    final others = StreetStyle.values.where((s) => s != p);
    final sum = others.fold<int>(0, (a, s) => a + pct(s));
    int share(StreetStyle s) => s == p ? 100 - sum : pct(s);
    return StreetMode(
      primary: p,
      streetliftingPct: share(StreetStyle.streetlifting),
      setsRepsPct: share(StreetStyle.setsReps),
      calisthenicsPct: share(StreetStyle.calisthenics),
    );
  }

  /// Dosage des disciplines (image du mode street s'il est activé).
  DisciplineMix? get mix {
    if (street) return streetMode?.toDisciplineMix();
    final p = primary;
    if (p == null) return null;
    return DisciplineMix(
      primary: p,
      primaryPct: primaryPct,
      secondaries: [
        for (final e in secondaries.entries)
          DisciplineShare(discipline: e.key, pct: e.value),
      ],
    );
  }

  /// Parts par défaut quand une secondaire est ajoutée (80/20, 70/20/10).
  void addSecondary(TrainingDiscipline d) {
    if (secondaries.containsKey(d) || secondaries.length >= 2 || d == primary) {
      return;
    }
    if (secondaries.isEmpty) {
      secondaries[d] = 20;
    } else {
      secondaries[d] = 10;
    }
  }

  void removeSecondary(TrainingDiscipline d) => secondaries.remove(d);

  /// Change une part de secondaire en gardant la principale la plus grande
  /// (D3.2, contrat : somme 100, principale ≥ chaque secondaire).
  void setSecondaryPct(TrainingDiscipline d, int pct) {
    if (!secondaries.containsKey(d)) return;
    final others = secondaries.entries
        .where((e) => e.key != d)
        .fold<int>(0, (a, e) => a + e.value);
    var v = pct.clamp(5, 95).toInt();
    // principale = 100 − others − v ≥ max(v, autres)
    int maxOther() => secondaries.entries
        .where((e) => e.key != d)
        .fold<int>(0, (a, e) => e.value > a ? e.value : a);
    while (v > 5 && (100 - others - v < v || 100 - others - v < maxOther())) {
      v -= 5;
    }
    secondaries[d] = v;
  }

  /// Plus grande part possible pour une secondaire.
  int maxSecondaryPct(TrainingDiscipline d) {
    final others = secondaries.entries
        .where((e) => e.key != d)
        .fold<int>(0, (a, e) => a + e.value);
    final maxOther = secondaries.entries
        .where((e) => e.key != d)
        .fold<int>(0, (a, e) => e.value > a ? e.value : a);
    var v = 95;
    while (v > 5 && (100 - others - v < v || 100 - others - v < maxOther)) {
      v -= 5;
    }
    return v;
  }

  /// Active ou désactive le mode street (parts par défaut 60/20/20).
  void setStreet(bool on) {
    street = on;
    if (on && streetPcts.isEmpty) {
      for (final s in StreetStyle.values) {
        streetPcts[s] = 20;
      }
    }
  }

  void setStreetPrimary(StreetStyle p) {
    streetPrimary = p;
    for (final s in StreetStyle.values) {
      streetPcts.putIfAbsent(s, () => 20);
    }
    // La principale n'a pas de part réglable : elle prend le reste.
    streetPcts.remove(p);
    for (final s in StreetStyle.values) {
      if (s != p) setStreetPct(s, streetPcts[s] ?? 20);
    }
  }

  /// Part d'une composante secondaire du mode street (0 à 45 %, la
  /// principale reste la plus grande).
  void setStreetPct(StreetStyle s, int pct) {
    final p = streetPrimary;
    if (p == null || s == p) return;
    final other = StreetStyle.values.firstWhere((x) => x != p && x != s);
    final o = streetPcts[other] ?? 0;
    var v = pct.clamp(0, 95).toInt();
    while (v > 0 && (100 - o - v < v || 100 - o - v < o)) {
      v -= 5;
    }
    streetPcts[s] = v;
  }

  int maxStreetPct(StreetStyle s) {
    final p = streetPrimary;
    if (p == null || s == p) return 0;
    final other = StreetStyle.values.firstWhere((x) => x != p && x != s);
    final o = streetPcts[other] ?? 0;
    var v = 95;
    while (v > 0 && (100 - o - v < v || 100 - o - v < o)) {
      v -= 5;
    }
    return v;
  }

  /// Mouvements proposés pour les disciplines choisies.
  List<LevelMovement> get movements => movementsFor(disciplines);

  /// Ajoute un lieu avec son matériel par défaut.
  void addPlace(Place p) {
    places.putIfAbsent(p, () => {...defaultEquipmentFor(p)});
  }

  void removePlace(Place p) {
    places.remove(p);
    dayPlace.removeWhere((_, v) => v == p);
  }

  /// Ajoute ou remplace une limitation (une par zone et côté).
  void putLimitation(Limitation l) {
    limitations.removeWhere((x) => limitationKey(x) == limitationKey(l));
    limitations.add(l);
  }

  // ------------------------------------------------------------ validation

  /// Erreur de l'étape [step] (null : l'étape est complète).
  String? stepError(String step, DateTime now) {
    switch (step) {
      case 'identity':
        if (displayName.trim().length > 40) {
          return 'Prénom ou pseudo : 40 caractères au plus.';
        }
        if (sex == null) {
          return 'Indique ton sexe (ou « Je préfère ne pas le dire »).';
        }
        final by = birthYearValue;
        if (by == null || by < 1900 || by > now.year) {
          return 'Indique ton année de naissance (4 chiffres).';
        }
        if (ageIn(now.year) == 18 && adult18 == null) {
          return 'Indique si tu as déjà fêté tes 18 ans.';
        }
        final h = heightValue;
        if (h == null || h < 100 || h > 250) {
          return 'Indique ta taille en centimètres (100 à 250).';
        }
        final w = weightValue;
        if (w != null && w.isNaN) return 'Poids entre 25 et 300 kg.';
        return null;
      case 'discipline':
        if (street) {
          return streetPrimary == null
              ? 'Choisis ta principale parmi les trois styles street.'
              : null;
        }
        return primary == null ? 'Choisis ta discipline principale.' : null;
      case 'secondary':
        if (street) {
          final m = streetMode;
          if (m == null) return 'Choisis ta principale parmi les trois styles.';
          final others = StreetStyle.values
              .where((s) => s != m.primary)
              .fold<int>(0, (a, s) => a + m.pctOf(s));
          if (others <= 0) {
            return 'Donne une part à au moins un des deux autres styles.';
          }
          return null;
        }
        if (secondaries.isEmpty) {
          return 'Choisis au moins une discipline secondaire (1 ou 2).';
        }
        final m = mix;
        if (m == null || m.validate().isNotEmpty) {
          return 'Revois les parts : la principale doit rester la plus grande.';
        }
        return null;
      case 'goals':
        return goals.isEmpty
            ? 'Ajoute au moins un objectif, ou laisse Koach en proposer.'
            : null;
      case 'availability':
        if (days.isEmpty) return 'Choisis au moins un jour.';
        for (final m in days.values) {
          if (m < 10 || m > 300) return 'Durée par jour : de 10 à 300 minutes.';
        }
        return null;
      case 'places':
        return places.isEmpty ? 'Choisis au moins un lieu.' : null;
      case 'health':
        return consent == null
            ? 'Choisis « J’accepte » ou « Je refuse ».'
            : null;
      case 'mode':
        return guidance == null
            ? 'Choisis le mode assisté ou le mode libre.'
            : null;
    }
    return null;
  }

  /// Première étape incomplète (null : tout est rempli).
  String? firstIncomplete(DateTime now) {
    for (final s in kAthleteSteps) {
      if (stepError(s, now) != null) return s;
    }
    return null;
  }

  // ---------------------------------------------------------- construction

  List<MovementLevel> get movementLevels {
    final out = <MovementLevel>[];
    final seen = <String>{};
    for (final m in movements) {
      final i = levels[m.key];
      if (i == null) continue;
      seen.add('${m.exerciseId}|${m.measure.code}');
      if (i < 0 || i >= m.bands.length) {
        out.add(
          MovementLevel(
            exerciseId: m.exerciseId,
            measure: m.measure,
            known: false,
            distanceMeters: m.distanceMeters,
          ),
        );
      } else {
        final b = m.bands[i];
        out.add(
          MovementLevel(
            exerciseId: m.exerciseId,
            measure: m.measure,
            known: true,
            low: b.low,
            high: b.high,
            distanceMeters: m.distanceMeters,
          ),
        );
      }
    }
    // Fourchettes déjà déclarées sur des mouvements que les disciplines
    // actuelles ne proposent plus : gardées (rien n'est perdu).
    for (final l in extraLevels) {
      if (seen.add('${l.exerciseId}|${l.measure.code}')) out.add(l);
    }
    return out;
  }

  /// Profil v2 construit (null si une étape est incomplète).
  /// [vocabulary] : ordre du matériel de la base ; [health] : référence au
  /// questionnaire santé, calculée par le magasin.
  AthleteProfile? build(
    DateTime now, {
    List<String> vocabulary = const [],
    HealthScreeningRef? health,
  }) {
    if (firstIncomplete(now) != null) return null;
    final m = mix;
    if (m == null) return null;
    final today = civilOf(now);
    final placeList = [
      for (final p in Place.values)
        if (places.containsKey(p)) p,
    ];
    final all = sortEquipment({
      for (final s in places.values) ...s,
    }, vocabulary);
    List<PlaceEquipment>? byPlace;
    if (placeList.length > 1) {
      final sets = [for (final p in placeList) places[p]!];
      final same = sets.every(
        (s) => s.length == sets.first.length && s.containsAll(sets.first),
      );
      if (!same) {
        byPlace = [
          for (final p in placeList)
            PlaceEquipment(
              place: p,
              equipment: sortEquipment(places[p]!, vocabulary),
            ),
        ];
      }
    }
    final w = weightValue;
    final dislikedSet = disliked.toSet();
    return AthleteProfile(
      displayName: displayName.trim().isEmpty ? null : displayName.trim(),
      sex: sex!,
      birthYear: birthYearValue!,
      heightCm: heightValue!,
      bodyWeightKg: w == null || w.isNaN ? null : w,
      disciplines: m,
      streetMode: street ? streetMode : null,
      movementLevels: movementLevels,
      goals: List.of(goals),
      availability: [
        for (final d in days.keys.toList()..sort())
          DaySlot(
            weekday: d,
            minutes: days[d]!,
            place: placeList.length > 1 ? dayPlace[d] : null,
          ),
      ],
      places: placeList,
      equipment: all,
      equipmentByPlace: byPlace,
      loadIncrements: loadIncrements,
      limitations: consent == 'given' ? List.of(limitations) : const [],
      likedExerciseIds: [
        for (final id in liked)
          if (!dislikedSet.contains(id)) id,
      ],
      dislikedExerciseIds: List.of(disliked),
      knownExerciseIds: knownExerciseIds,
      cannotDoExerciseIds: cannotDoExerciseIds,
      experience: experience,
      guidanceMode: guidance!,
      healthScreening: health,
      createdOn: createdOn ?? today,
      updatedOn: (createdOn != null && createdOn! > today) ? createdOn! : today,
    );
  }

  /// Brouillon d'un profil existant (modification, rubrique par rubrique).
  factory ProfileDraft.of(AthleteProfile p, {HealthData? health}) {
    final d = ProfileDraft()
      ..displayName = p.displayName ?? ''
      ..sex = p.sex
      ..birthYear = '${p.birthYear}'
      ..adult18 = true
      ..height = '${p.heightCm}'
      ..weight = p.bodyWeightKg == null ? '' : _num(p.bodyWeightKg!)
      ..experience = p.experience
      ..guidance = p.guidanceMode
      ..createdOn = p.createdOn
      ..loadIncrements = p.loadIncrements
      ..knownExerciseIds = p.knownExerciseIds
      ..cannotDoExerciseIds = p.cannotDoExerciseIds;
    final s = p.streetMode;
    if (s != null) {
      d
        ..street = true
        ..streetPrimary = s.primary;
      for (final st in StreetStyle.values) {
        if (st != s.primary) d.streetPcts[st] = s.pctOf(st);
      }
    } else {
      d.primary = p.disciplines.primary;
      for (final sh in p.disciplines.secondaries) {
        d.secondaries[sh.discipline] = sh.pct;
      }
    }
    final extra = <MovementLevel>[];
    for (final l in p.movementLevels) {
      final ref = levelMovementForExercise(l.exerciseId);
      if (ref == null || ref.measure != l.measure) {
        extra.add(l);
        continue;
      }
      if (!l.known) {
        d.levels[ref.key] = -1;
        continue;
      }
      final i = ref.bands.indexWhere((b) => b.low == l.low && b.high == l.high);
      if (i < 0) {
        extra.add(l);
      } else {
        d.levels[ref.key] = i;
      }
    }
    d.extraLevels = extra;
    d.goals.addAll(p.goals);
    for (final slot in p.availability) {
      d.days[slot.weekday] = slot.minutes;
      if (slot.place != null) d.dayPlace[slot.weekday] = slot.place!;
    }
    final byPlace = {
      for (final pe in p.equipmentByPlace ?? const <PlaceEquipment>[])
        pe.place: pe.equipment,
    };
    for (final pl in p.places) {
      d.places[pl] = {...(byPlace[pl] ?? p.equipment)};
    }
    d.limitations.addAll(p.limitations);
    d.liked.addAll(p.likedExerciseIds);
    d.disliked.addAll(p.dislikedExerciseIds);
    if (health != null) {
      d.consent = health.consentGiven
          ? 'given'
          : health.consent == null
          ? null
          : 'refused';
      if (health.consentGiven) d.answers.addAll(health.answers);
    }
    return d;
  }

  // -------------------------------------------------------------- brouillon

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    if (sex != null) 'sex': sex!.code,
    'birthYear': birthYear,
    if (adult18 != null) 'adult18': adult18,
    'height': height,
    'weight': weight,
    'street': street,
    if (primary != null) 'primary': primary!.code,
    if (streetPrimary != null) 'streetPrimary': streetPrimary!.code,
    'secondaries': {for (final e in secondaries.entries) e.key.code: e.value},
    'streetPcts': {for (final e in streetPcts.entries) e.key.code: e.value},
    if (experience != null) 'experience': experience!.code,
    'levels': levels,
    'goals': [for (final g in goals) g.toJson()],
    'days': {for (final e in days.entries) '${e.key}': e.value},
    'dayPlace': {for (final e in dayPlace.entries) '${e.key}': e.value.code},
    'places': {for (final e in places.entries) e.key.code: e.value.toList()},
    if (consent != null) 'consent': consent,
    'answers': answers,
    'limitations': [for (final l in limitations) l.toJson()],
    'liked': liked,
    'disliked': disliked,
    if (guidance != null) 'guidance': guidance!.code,
    if (createdOn != null) 'createdOn': createdOn!.iso,
    'loadIncrements': [for (final i in loadIncrements) i.toJson()],
    if (knownExerciseIds != null) 'known': knownExerciseIds,
    if (cannotDoExerciseIds != null) 'cannotDo': cannotDoExerciseIds,
    'extraLevels': [for (final l in extraLevels) l.toJson()],
  };

  /// Lecture d'un brouillon ; null s'il est illisible.
  static ProfileDraft? fromJson(Object? raw) {
    if (raw is! Map) return null;
    try {
      T? en<T>(Object? v, T Function(String) f) => v is String ? f(v) : null;
      final d = ProfileDraft()
        ..displayName = raw['displayName'] as String? ?? ''
        ..sex = en(raw['sex'], Sex.fromCode)
        ..birthYear = raw['birthYear'] as String? ?? ''
        ..adult18 = raw['adult18'] as bool?
        ..height = raw['height'] as String? ?? ''
        ..weight = raw['weight'] as String? ?? ''
        ..street = raw['street'] as bool? ?? false
        ..primary = en(raw['primary'], TrainingDiscipline.fromCode)
        ..streetPrimary = en(raw['streetPrimary'], StreetStyle.fromCode)
        ..experience = en(raw['experience'], ExperienceLevel.fromCode)
        ..consent = raw['consent'] as String?
        ..guidance = en(raw['guidance'], GuidanceMode.fromCode)
        ..createdOn = en(raw['createdOn'], CivilDate.parse)
        ..knownExerciseIds = (raw['known'] as List?)?.cast<String>()
        ..cannotDoExerciseIds = (raw['cannotDo'] as List?)?.cast<String>();
      (raw['secondaries'] as Map? ?? const {}).forEach(
        (k, v) => d.secondaries[TrainingDiscipline.fromCode('$k')] = v as int,
      );
      (raw['streetPcts'] as Map? ?? const {}).forEach(
        (k, v) => d.streetPcts[StreetStyle.fromCode('$k')] = v as int,
      );
      (raw['levels'] as Map? ?? const {}).forEach(
        (k, v) => d.levels['$k'] = v as int,
      );
      for (final g in raw['goals'] as List? ?? const []) {
        d.goals.add(Goal.fromJson((g as Map).cast<String, Object?>()));
      }
      (raw['days'] as Map? ?? const {}).forEach(
        (k, v) => d.days[int.parse('$k')] = v as int,
      );
      (raw['dayPlace'] as Map? ?? const {}).forEach(
        (k, v) => d.dayPlace[int.parse('$k')] = Place.fromCode(v as String),
      );
      (raw['places'] as Map? ?? const {}).forEach(
        (k, v) =>
            d.places[Place.fromCode('$k')] = {...(v as List).cast<String>()},
      );
      (raw['answers'] as Map? ?? const {}).forEach(
        (k, v) => d.answers['$k'] = v as bool,
      );
      for (final l in raw['limitations'] as List? ?? const []) {
        d.limitations.add(
          Limitation.fromJson((l as Map).cast<String, Object?>()),
        );
      }
      d.liked.addAll((raw['liked'] as List? ?? const []).cast<String>());
      d.disliked.addAll((raw['disliked'] as List? ?? const []).cast<String>());
      d.loadIncrements = [
        for (final i in raw['loadIncrements'] as List? ?? const [])
          LoadIncrement.fromJson((i as Map).cast<String, Object?>()),
      ];
      d.extraLevels = [
        for (final l in raw['extraLevels'] as List? ?? const [])
          MovementLevel.fromJson((l as Map).cast<String, Object?>()),
      ];
      return d;
    } catch (_) {
      return null;
    }
  }
}

// ======================================== pré-remplissage (profil L8, 6.x)

/// Lieux L8 → lieux v2.
const kLegacyPlaces = <String, Place>{
  'home_none': Place.home,
  'home_equipped': Place.home,
  'park': Place.outdoor,
  'gym': Place.gym,
};

/// Matériel L8 → vocabulaire de la base.
const kLegacyEquipment = <String, List<String>>{
  'pullup_bar': ['barre fixe'],
  'dip_bars': ['barres parallèles'],
  'rings': ['anneaux'],
  'bands': ['élastique'],
  'dumbbells': ['haltères'],
  'kettlebell': ['kettlebell'],
  'barbell': ['barre olympique', 'disques'],
  'rack': ['cage / rack'],
  'bench': ['banc plat'],
  'weight_belt': ['ceinture de lest'],
  'machines': ['machine guidée', 'poulie'],
  'box': ['box / plinth'],
  'jump_rope': ['corde à sauter'],
  'erg': ['rameur', 'vélo / home-trainer'],
  'mat': ['tapis'],
};

/// Brouillon pré-rempli depuis le profil L8 et les données de
/// l'application (refaire son profil, D1.6) : seulement ce qui se
/// correspond sans ambiguïté ; le reste est demandé. Rien n'est écrit.
ProfileDraft draftFromLegacy(
  UserProfile? legacy, {
  double? bodyWeight,
  DateTime? now,
}) {
  final d = ProfileDraft();
  if (bodyWeight != null && bodyWeight >= 25 && bodyWeight <= 300) {
    d.weight = _num(double.parse(bodyWeight.toStringAsFixed(1)));
  }
  if (legacy == null) return d;
  final by = legacy.intValue('birthYear');
  if (by != null) {
    d.birthYear = '$by';
    if (now != null && now.year - by > 18) d.adult18 = true;
  }
  final days = legacy.value('days');
  final minutes = legacy.intValue('sessionMinutes');
  if (days is List && minutes != null && minutes >= 10 && minutes <= 300) {
    for (final x in days) {
      if (x is int && x >= 1 && x <= 7) d.days[x] = minutes;
    }
  }
  final places = legacy.value('places');
  if (places is Map) {
    places.forEach((k, v) {
      final p = kLegacyPlaces['$k'];
      if (p == null) return;
      final set = d.places.putIfAbsent(p, () => {'aucun (sol)'});
      for (final e in (v as List? ?? const [])) {
        set.addAll(kLegacyEquipment['$e'] ?? const []);
      }
    });
  }
  final dayPlace = legacy.value('dayPlace');
  if (dayPlace is Map && d.places.length > 1) {
    dayPlace.forEach((k, v) {
      final day = int.tryParse('$k');
      final p = kLegacyPlaces['$v'];
      if (day != null && p != null && d.days.containsKey(day)) {
        d.dayPlace[day] = p;
      }
    });
  }
  final h = legacy.health;
  if (h.consentGiven) {
    d.consent = 'given';
    d.answers.addAll(h.answers);
    for (final i in h.injuries) {
      final z = kLegacyZones[i.zone];
      if (z != null) d.putLimitation(limitationOf(z, BodySide.both, i.level));
    }
  } else if (h.consent != null) {
    d.consent = 'refused';
  }
  return d;
}

// ============================================== section de la sauvegarde

/// Changement daté du profil (rubriques) ; [program] : il touche le
/// programme (la régénération arrive en G7).
class ProfileChange {
  final String at;
  final List<String> rubrics;
  final bool program;
  const ProfileChange(this.at, this.rubrics, this.program);

  Map<String, dynamic> toJson() => {
    'at': at,
    'rubrics': rubrics,
    if (program) 'program': true,
  };
}

/// Section `athleteProfile` (v1) : le profil v2 et ses dates de saisie.
class AthleteRecord {
  final AthleteProfile profile;

  /// Enregistrement du profil (horodatage local).
  final String savedAt;

  /// Dernière saisie de l'année de naissance (mode prudent : l'accord du
  /// médecin couvre ce qui a été déclaré avant lui).
  final String birthYearAt;

  /// Saisie de chaque limitation (clé zone|côté).
  final Map<String, String> limitationsAt;

  /// Changements datés (les plus récents à la fin, 100 au plus).
  final List<ProfileChange> changes;

  const AthleteRecord({
    required this.profile,
    required this.savedAt,
    required this.birthYearAt,
    this.limitationsAt = const {},
    this.changes = const [],
  });

  static const maxChanges = 100;

  /// Date de saisie d'une limitation.
  String limitationAt(Limitation l) =>
      limitationsAt[limitationKey(l)] ?? savedAt;

  /// Changements qui touchent le programme, depuis la dernière création
  /// du programme (G7 les lira).
  bool get programChangePending => changes.any((c) => c.program);

  Map<String, dynamic> toJson() => {
    'v': kAthleteSectionVersion,
    'profile': profile.toJson(),
    'savedAt': savedAt,
    'birthYearAt': birthYearAt,
    if (limitationsAt.isNotEmpty) 'limitationsAt': limitationsAt,
    if (changes.isNotEmpty) 'changes': [for (final c in changes) c.toJson()],
  };

  /// Lecture de la section ; [FormatException] si elle est hors contrat.
  static AthleteRecord fromJson(Object? raw) {
    if (raw is! Map ||
        raw['v'] is! int ||
        (raw['v'] as int) < 1 ||
        (raw['v'] as int) > kAthleteSectionVersion) {
      throw const FormatException('Profil v2 : section illisible.');
    }
    final p = raw['profile'];
    if (p is! Map) throw const FormatException('Profil v2 absent.');
    final profile = AthleteProfile.fromJson(p.cast<String, Object?>());
    final violations = profile.validate();
    if (violations.isNotEmpty) {
      throw FormatException('Profil v2 hors contrat : ${violations.first}');
    }
    if (!_okAt(raw['savedAt']) || !_okAt(raw['birthYearAt'])) {
      throw const FormatException('Profil v2 : dates illisibles.');
    }
    final la = <String, String>{};
    final rawLa = raw['limitationsAt'];
    if (rawLa != null) {
      if (rawLa is! Map) throw const FormatException('Profil v2 : gênes.');
      rawLa.forEach((k, v) {
        if (!_okAt(v)) throw const FormatException('Profil v2 : gênes.');
        la['$k'] = v as String;
      });
    }
    final changes = <ProfileChange>[];
    final rawC = raw['changes'];
    if (rawC != null) {
      if (rawC is! List || rawC.length > maxChanges) {
        throw const FormatException('Profil v2 : changements.');
      }
      for (final c in rawC) {
        if (c is! Map ||
            !_okAt(c['at']) ||
            c['rubrics'] is! List ||
            !(c['rubrics'] as List).every(kRubricTitles.containsKey)) {
          throw const FormatException('Profil v2 : changement.');
        }
        changes.add(
          ProfileChange(
            c['at'] as String,
            (c['rubrics'] as List).cast<String>(),
            c['program'] == true,
          ),
        );
      }
    }
    return AthleteRecord(
      profile: profile,
      savedAt: raw['savedAt'] as String,
      birthYearAt: raw['birthYearAt'] as String,
      limitationsAt: la,
      changes: changes,
    );
  }
}

/// Rubriques qui diffèrent entre deux profils.
Set<String> changedRubrics(AthleteProfile? a, AthleteProfile b) {
  if (a == null) return kRubricTitles.keys.toSet();
  bool diff(Object? x, Object? y) => !jsonDeepEquals(x, y);
  final out = <String>{};
  if (a.displayName != b.displayName ||
      a.sex != b.sex ||
      a.birthYear != b.birthYear ||
      a.heightCm != b.heightCm ||
      a.bodyWeightKg != b.bodyWeightKg) {
    out.add('identity');
  }
  if (a.disciplines.primary != b.disciplines.primary ||
      (a.streetMode?.primary) != (b.streetMode?.primary) ||
      (a.streetMode == null) != (b.streetMode == null)) {
    out.add('discipline');
  }
  if (diff(a.disciplines.toJson(), b.disciplines.toJson()) ||
      diff(a.streetMode?.toJson(), b.streetMode?.toJson())) {
    out.add('secondary');
  }
  if (a.experience != b.experience ||
      diff(
        [for (final l in a.movementLevels) l.toJson()],
        [for (final l in b.movementLevels) l.toJson()],
      )) {
    out.add('levels');
  }
  if (diff(
    [for (final g in a.goals) g.toJson()],
    [for (final g in b.goals) g.toJson()],
  )) {
    out.add('goals');
  }
  if (diff(
    [for (final s in a.availability) s.toJson()],
    [for (final s in b.availability) s.toJson()],
  )) {
    out.add('availability');
  }
  if (diff(
        a.places.map((p) => p.code).toList(),
        b.places.map((p) => p.code).toList(),
      ) ||
      diff(a.equipment, b.equipment) ||
      diff(
        a.equipmentByPlace?.map((e) => e.toJson()).toList(),
        b.equipmentByPlace?.map((e) => e.toJson()).toList(),
      )) {
    out.add('places');
  }
  if (diff(
        [for (final l in a.limitations) l.toJson()],
        [for (final l in b.limitations) l.toJson()],
      ) ||
      diff(a.healthScreening?.toJson(), b.healthScreening?.toJson())) {
    out.add('health');
  }
  if (diff(a.likedExerciseIds, b.likedExerciseIds) ||
      diff(a.dislikedExerciseIds, b.dislikedExerciseIds)) {
    out.add('preferences');
  }
  if (a.guidanceMode != b.guidanceMode) out.add('mode');
  return out;
}

/// Un changement de ces rubriques touche le programme (régénération en
/// G7) ; le nom, la taille et le mode n'en changent pas la construction.
bool rubricsAffectProgram(
  Set<String> rubrics,
  AthleteProfile? a,
  AthleteProfile b,
) {
  for (final r in rubrics) {
    switch (r) {
      case 'identity':
        if (a == null ||
            a.sex != b.sex ||
            a.birthYear != b.birthYear ||
            a.bodyWeightKg != b.bodyWeightKg) {
          return true;
        }
      case 'mode':
        break;
      default:
        return true;
    }
  }
  return false;
}

/// Référence au questionnaire santé (aucune réponse copiée) : sans accord
/// ou questionnaire incomplet → sans réponse ; sinon prudent si le mode
/// prudent s'applique, standard sinon.
HealthScreeningRef healthRefOf(HealthData h, CautionStatus caution) {
  final answered = h.answeredAt == null
      ? null
      : DateTime.tryParse(h.answeredAt!);
  if (!h.consentGiven || !h.complete) {
    return HealthScreeningRef(
      questionnaireId: kHealthQuestionnaireId,
      answeredOn: h.consentGiven && answered != null ? civilOf(answered) : null,
      outcome: HealthScreeningOutcome.notAnswered,
    );
  }
  return HealthScreeningRef(
    questionnaireId: kHealthQuestionnaireId,
    answeredOn: answered == null ? null : civilOf(answered),
    outcome: caution.active
        ? HealthScreeningOutcome.cautious
        : HealthScreeningOutcome.standard,
  );
}

/// Profil d'exemple complet et valide (tests, sessions d'essai semées).
AthleteProfile sampleAthleteProfile({
  CivilDate? on,
  GuidanceMode guidance = GuidanceMode.assisted,
}) {
  final day = on ?? CivilDate(2026, 10, 1);
  return AthleteProfile(
    displayName: 'Gaël',
    sex: Sex.male,
    birthYear: 1990,
    heightCm: 178,
    bodyWeightKg: 75,
    disciplines: const StreetMode(
      primary: StreetStyle.streetlifting,
      streetliftingPct: 60,
      setsRepsPct: 20,
      calisthenicsPct: 20,
    ).toDisciplineMix(),
    streetMode: const StreetMode(
      primary: StreetStyle.streetlifting,
      streetliftingPct: 60,
      setsRepsPct: 20,
      calisthenicsPct: 20,
    ),
    movementLevels: const [
      MovementLevel(
        exerciseId: 'sl-traction-lestee',
        measure: LevelMeasure.oneRmKg,
        known: true,
        low: 35,
        high: 50,
      ),
      MovementLevel(
        exerciseId: 'sw-traction-pronation',
        measure: LevelMeasure.maxReps,
        known: true,
        low: 13,
        high: 20,
      ),
    ],
    goals: [
      Goal(
        id: 'goal-1',
        kind: GoalKind.performance,
        origin: GoalOrigin.user,
        createdOn: day,
        exerciseId: 'sl-traction-lestee',
        metric: GoalMetric.oneRmKg,
        targetValue: 60,
        targetDate: day.addDays(180),
      ),
    ],
    availability: const [
      DaySlot(weekday: 1, minutes: 75),
      DaySlot(weekday: 3, minutes: 75),
      DaySlot(weekday: 5, minutes: 90),
    ],
    places: const [Place.gym],
    equipment: const [
      'aucun (sol)',
      'barre fixe',
      'barres parallèles',
      'barre olympique',
      'disques',
      'cage / rack',
      'ceinture de lest',
    ],
    loadIncrements: const [],
    limitations: const [],
    likedExerciseIds: const [],
    dislikedExerciseIds: const [],
    experience: ExperienceLevel.advanced,
    guidanceMode: guidance,
    healthScreening: const HealthScreeningRef(
      questionnaireId: kHealthQuestionnaireId,
      outcome: HealthScreeningOutcome.notAnswered,
    ),
    createdOn: day,
    updatedOn: day,
  );
}
