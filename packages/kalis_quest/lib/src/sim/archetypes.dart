/// Archétypes de la simulation de rythme : huit façons de s'entraîner
/// pendant trois ans, de 2 à 6 séances par semaine, du débutant à
/// l'expert, avec arrêts, vacances déclarées, maladie et douleur.
library;

/// Période qui revient chaque année : semaine de départ dans l'année
/// (0 à 51) et durée en jours.
final class YearlySpan {
  /// Période.
  const YearlySpan(this.week, this.days);

  /// Semaine de départ dans l'année (0 à 51).
  final int week;

  /// Durée, en jours.
  final int days;
}

/// Comportement d'un athlète simulé.
final class Archetype {
  /// Archétype.
  const Archetype({
    required this.key,
    required this.profileKey,
    required this.level,
    required this.adherence,
    required this.note,
    this.fullRate = 0.9,
    this.ratingSkip = 0.05,
    this.ratingNoise = 0.7,
    this.healthRate = 0.7,
    this.claimRate = 0.5,
    this.mobilityRate = 0.1,
    this.stops = const <YearlySpan>[],
    this.vacations = const <YearlySpan>[],
    this.illnesses = const <YearlySpan>[],
    this.painRate = 0,
    this.throughRate = 0.3,
    this.cheat = false,
  });

  /// Clé.
  final String key;

  /// Profil type de `kalis_core` (programme créé par `kalis_plan`).
  final String profileKey;

  /// Niveau de la vérité : 0 débutant, 1 intermédiaire, 2 avancé,
  /// 3 expert.
  final int level;

  /// Probabilité de faire une séance prévue.
  final double adherence;

  /// Ce que l'archétype représente.
  final String note;

  /// Probabilité de faire la séance en entier (sinon 60 % des exercices).
  final double fullRate;

  /// Probabilité de ne pas noter une série.
  final double ratingSkip;

  /// Écart-type de l'erreur de note, en répétitions en réserve.
  final double ratingNoise;

  /// Probabilité de répondre au bilan santé.
  final double healthRate;

  /// Probabilité de déclarer faite une quête de récupération.
  final double claimRate;

  /// Probabilité d'une courte séance de mobilité un jour de repos.
  final double mobilityRate;

  /// Arrêts non déclarés.
  final List<YearlySpan> stops;

  /// Vacances déclarées.
  final List<YearlySpan> vacations;

  /// Maladies déclarées.
  final List<YearlySpan> illnesses;

  /// Probabilité qu'une séance commence par une douleur déclarée (5/10 à
  /// l'épaule).
  final double painRate;

  /// Probabilité, ce jour-là, de faire quand même les exercices écartés.
  final double throughRate;

  /// Triche par surentraînement : séries en plus à chaque séance et
  /// séances en plus les jours de repos.
  final bool cheat;
}

/// Les huit archétypes de la simulation de rythme.
const List<Archetype> archetypes = <Archetype>[
  Archetype(
    key: 'debutant_2x',
    profileKey: 'debutant_forme_generale_maison_2x30',
    level: 0,
    adherence: 0.85,
    note: 'Débutant, 2 séances de 30 min par semaine à la maison.',
  ),
  Archetype(
    key: 'debutant_3x',
    profileKey: 'homme_25_musculation_debutant_3x60',
    level: 0,
    adherence: 0.90,
    note: 'Débutant régulier, 3 séances par semaine en salle (repère).',
  ),
  Archetype(
    key: 'intermediaire_4x',
    profileKey: 'femme_45_musculation_salle_4x60',
    level: 1,
    adherence: 0.90,
    note: 'Intermédiaire régulière, 4 séances par semaine (repère).',
  ),
  Archetype(
    key: 'avance_street_4x',
    profileKey: 'street_streetlifting_4x90',
    level: 2,
    adherence: 0.92,
    ratingSkip: 0.02,
    note: 'Avancé en streetlifting, 4 séances de 90 min par semaine.',
  ),
  Archetype(
    key: 'expert_6x',
    profileKey: 'six_jours_musculation_avance_6x75',
    level: 3,
    adherence: 0.95,
    ratingSkip: 0.02,
    ratingNoise: 0.5,
    note: 'Expert, 6 séances par semaine.',
  ),
  Archetype(
    key: 'irregulier_3x',
    profileKey: 'femme_30_street_workout_parc_3x45',
    level: 1,
    adherence: 0.60,
    fullRate: 0.8,
    ratingSkip: 0.15,
    stops: <YearlySpan>[YearlySpan(20, 21), YearlySpan(44, 28)],
    note:
        'Irrégulière : 3 séances prévues, 60 % faites, deux arrêts non '
        'déclarés de 3 et 4 semaines par an.',
  ),
  Archetype(
    key: 'vacances_5x',
    profileKey: 'crossfit_5x60',
    level: 1,
    adherence: 0.88,
    vacations: <YearlySpan>[YearlySpan(30, 21), YearlySpan(51, 7)],
    note:
        '5 séances par semaine, vacances déclarées : 3 semaines l\'été, '
        '1 semaine l\'hiver.',
  ),
  Archetype(
    key: 'maladie_3x',
    profileKey: 'senior_65_forme_generale_3x40',
    level: 0,
    adherence: 0.85,
    illnesses: <YearlySpan>[YearlySpan(8, 10), YearlySpan(36, 10)],
    painRate: 0.08,
    note:
        'Senior, 3 séances par semaine, deux maladies déclarées de 10 jours '
        'par an, douleur déclarée avant 8 % des séances (dont 30 % faites '
        'quand même sans épargner la zone).',
  ),
];

/// Archétype de clé [key] ; [ArgumentError] s'il est inconnu.
Archetype archetypeOf(String key) {
  for (final a in archetypes) {
    if (a.key == key) {
      return a;
    }
  }
  throw ArgumentError.value(key, 'key', 'archétype inconnu');
}

/// Jumeau parfait de [a] : toutes les séances prévues, faites en entier.
Archetype perfectOf(Archetype a) => Archetype(
  key: '${a.key}_parfait',
  profileKey: a.profileKey,
  level: a.level,
  adherence: 1,
  note: 'Jumeau de ${a.key} qui fait tout le programme.',
  fullRate: 1,
  ratingSkip: a.ratingSkip,
  ratingNoise: a.ratingNoise,
  healthRate: a.healthRate,
  claimRate: a.claimRate,
  mobilityRate: a.mobilityRate,
);

/// Jumeau tricheur de [a] : mêmes aléas, mais des séries en plus à chaque
/// séance et des séances en plus les jours de repos.
Archetype cheaterOf(Archetype a) => Archetype(
  key: '${a.key}_tricheur',
  profileKey: a.profileKey,
  level: a.level,
  adherence: a.adherence,
  note: 'Jumeau tricheur de ${a.key} : surentraînement.',
  fullRate: a.fullRate,
  ratingSkip: a.ratingSkip,
  ratingNoise: a.ratingNoise,
  healthRate: a.healthRate,
  claimRate: a.claimRate,
  mobilityRate: a.mobilityRate,
  stops: a.stops,
  vacations: a.vacations,
  illnesses: a.illnesses,
  painRate: a.painRate,
  throughRate: a.throughRate,
  cheat: true,
);
