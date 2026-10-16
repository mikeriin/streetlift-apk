/// Athlètes simulés de la campagne de validation.
library;

import 'package:kalis_core/kalis_core.dart';

import 'truth.dart';

/// Les huit athlètes de la campagne : chacun s'appuie sur un profil type
/// de `kalis_core` (programme créé par `kalis_plan`).
const List<AthleteSpec> simAthletes = <AthleteSpec>[
  AthleteSpec(
    key: 'debutant_salle',
    profileKey: 'homme_25_musculation_debutant_3x60',
    level: 0,
    weeklyGain: 0.012,
    ratingNoise: 1.3,
    lazy: 0.15,
    daySd: 0.03,
  ),
  AthleteSpec(
    key: 'intermediaire_salle',
    profileKey: 'femme_45_musculation_salle_4x60',
    level: 1,
    weeklyGain: 0.004,
  ),
  AthleteSpec(
    key: 'avance_street',
    profileKey: 'proprietaire_streetlifting_avance',
    level: 2,
    weeklyGain: 0.0015,
    rirBias: 0.15,
    rirBiasSd: 0.12,
    ratingNoise: 0.8,
    lazy: 0.05,
    missRate: 0.05,
    daySd: 0.02,
  ),
  AthleteSpec(
    key: 'notes_paresseuses',
    profileKey: 'trois_disciplines_70_20_10',
    level: 1,
    weeklyGain: 0.004,
    lazy: 0.92,
  ),
  AthleteSpec(
    key: 'irregulier',
    profileKey: 'tres_grand_lourd',
    level: 1,
    weeklyGain: 0.004,
    missRate: 0.30,
    breakFromDay: 70,
    breakDays: 12,
    illnessFromDay: 110,
    illnessDays: 8,
    daySd: 0.03,
  ),
  AthleteSpec(
    key: 'maison_halteres',
    profileKey: 'musculation_maison_halteres_4x45',
    level: 0,
    weeklyGain: 0.010,
    ratingNoise: 1.3,
    lazy: 0.2,
    missRate: 0.12,
    daySd: 0.03,
  ),
  AthleteSpec(
    key: 'calisthenie_parc',
    profileKey: 'femme_30_street_workout_parc_3x45',
    level: 1,
    weeklyGain: 0.004,
    skipRating: 0.1,
  ),
  AthleteSpec(
    key: 'douleur_et_lieu',
    profileKey: 'materiel_complet_gouts_marques',
    level: 1,
    weeklyGain: 0.004,
    painZone: BodyZone.shoulder,
    painFromDay: 56,
    painDays: 21,
    painIntensity: 5,
    otherPlace: Place.home,
    otherPlaceFromDay: 98,
    otherPlaceDays: 14,
  ),
];

/// Athlète de clé [key] ; [ArgumentError] s'il est inconnu.
AthleteSpec athleteOf(String key) {
  for (final a in simAthletes) {
    if (a.key == key) {
      return a;
    }
  }
  throw ArgumentError.value(key, 'key', 'athlète simulé inconnu');
}

/// Athlète décrit par l'objet JSON [json] : `key`, `profileKey`, `level`,
/// `weeklyGain` obligatoires ; les autres champs de [AthleteSpec] sont
/// facultatifs (mêmes noms). [FormatException] si un champ a un type
/// inattendu.
AthleteSpec athleteFromJson(Map<String, Object?> json) {
  T need<T>(String name) {
    final v = json[name];
    if (v is T) {
      return v;
    }
    throw FormatException('champ `$name` absent ou de type inattendu');
  }

  double number(String name, double fallback) {
    final v = json[name];
    if (v == null) {
      return fallback;
    }
    if (v is num) {
      return v.toDouble();
    }
    throw FormatException('champ `$name` : nombre attendu');
  }

  int? whole(String name) {
    final v = json[name];
    if (v == null) {
      return null;
    }
    if (v is int) {
      return v;
    }
    throw FormatException('champ `$name` : entier attendu');
  }

  final zone = json['painZone'];
  final place = json['otherPlace'];
  return AthleteSpec(
    key: need<String>('key'),
    profileKey: need<String>('profileKey'),
    level: need<int>('level'),
    weeklyGain: need<num>('weeklyGain').toDouble(),
    ratingNoise: number('ratingNoise', 1),
    rirBias: number('rirBias', 0.25),
    rirBiasSd: number('rirBiasSd', 0.18),
    lazy: number('lazy', 0.1),
    skipRating: number('skipRating', 0),
    missRate: number('missRate', 0.08),
    breakFromDay: whole('breakFromDay'),
    breakDays: whole('breakDays') ?? 0,
    illnessFromDay: whole('illnessFromDay'),
    illnessDays: whole('illnessDays') ?? 0,
    painZone: zone is String ? BodyZone.fromCode(zone) : null,
    painFromDay: whole('painFromDay'),
    painDays: whole('painDays') ?? 0,
    painIntensity: whole('painIntensity') ?? 5,
    otherPlace: place is String ? Place.fromCode(place) : null,
    otherPlaceFromDay: whole('otherPlaceFromDay'),
    otherPlaceDays: whole('otherPlaceDays') ?? 0,
    daySd: number('daySd', 0.025),
    healthAnswerRate: number('healthAnswerRate', 0.7),
    shortTimeRate: number('shortTimeRate', 0.05),
  );
}

/// Objet JSON de l'athlète [a] (relu par [athleteFromJson]).
Map<String, Object?> athleteToJson(AthleteSpec a) => <String, Object?>{
  'key': a.key,
  'profileKey': a.profileKey,
  'level': a.level,
  'weeklyGain': a.weeklyGain,
  'ratingNoise': a.ratingNoise,
  'rirBias': a.rirBias,
  'rirBiasSd': a.rirBiasSd,
  'lazy': a.lazy,
  'skipRating': a.skipRating,
  'missRate': a.missRate,
  if (a.breakFromDay != null) 'breakFromDay': a.breakFromDay,
  'breakDays': a.breakDays,
  if (a.illnessFromDay != null) 'illnessFromDay': a.illnessFromDay,
  'illnessDays': a.illnessDays,
  if (a.painZone != null) 'painZone': a.painZone!.code,
  if (a.painFromDay != null) 'painFromDay': a.painFromDay,
  'painDays': a.painDays,
  'painIntensity': a.painIntensity,
  if (a.otherPlace != null) 'otherPlace': a.otherPlace!.code,
  if (a.otherPlaceFromDay != null) 'otherPlaceFromDay': a.otherPlaceFromDay,
  'otherPlaceDays': a.otherPlaceDays,
  'daySd': a.daySd,
  'healthAnswerRate': a.healthAnswerRate,
  'shortTimeRate': a.shortTimeRate,
};
