// Profil de validation (lot KM2) : les seuls champs du profil que lisent
// les critères de sécurité du banc (`kalis_bench` 0.3.1,
// `lib/src/safety.dart` et `lib/src/analysis.dart`, copiés le 2026-10-10
// dans `securite.dart`). Construit depuis les champs du banc (constructeur,
// `ProfilValidation.depuisJsonBanc`) ou depuis le profil d'athlète de
// l'application (`ProfilValidation.depuisProfil`).
import 'package:kalis_core/kalis_core.dart';

/// Année du début des programmes du banc (`benchStartYear` de
/// `kalis_bench`) : l'âge du banc est `2026 − année de naissance`.
const int anneeDebutBanc = 2026;

/// Articulation du catalogue que désigne une zone du corps (`jointOfZone`
/// de `kalis_bench`).
const Map<BodyZone, Joint> articulationDeZone = <BodyZone, Joint>{
  BodyZone.shoulder: Joint.shoulder,
  BodyZone.elbow: Joint.elbow,
  BodyZone.wristHand: Joint.wrist,
  BodyZone.lowerBack: Joint.lumbar,
  BodyZone.knee: Joint.knee,
  BodyZone.hip: Joint.hip,
  BodyZone.ankleFoot: Joint.ankle,
};

/// Nom français d'une zone du corps (libellé d'une gêne de l'application,
/// qui n'en porte pas).
const Map<BodyZone, String> _nomZone = <BodyZone, String>{
  BodyZone.neck: 'cou',
  BodyZone.shoulder: 'épaule',
  BodyZone.elbow: 'coude',
  BodyZone.wristHand: 'poignet ou main',
  BodyZone.upperBack: 'haut du dos',
  BodyZone.lowerBack: 'bas du dos',
  BodyZone.chest: 'poitrine',
  BodyZone.abdomen: 'abdomen',
  BodyZone.hip: 'hanche',
  BodyZone.thigh: 'cuisse',
  BodyZone.knee: 'genou',
  BodyZone.lowerLeg: 'jambe',
  BodyZone.ankleFoot: 'cheville ou pied',
};

/// Test ou record exact d'un mouvement (`BenchRecord` : seuls les champs
/// lus par les critères).
final class RecordValidation {
  /// Record.
  const RecordValidation({
    required this.exerciseId,
    required this.mesure,
    required this.valeur,
    this.distanceMetres,
  });

  /// Exercice.
  final String exerciseId;

  /// Grandeur mesurée.
  final LevelMeasure mesure;

  /// Valeur exacte : strictement positive, le mouvement est acquis ; nulle
  /// (ou négative), il ne l'est pas.
  final double valeur;

  /// Distance, pour un temps.
  final double? distanceMetres;
}

/// Gêne ou antécédent (`BenchInjury` : seuls les champs lus par les
/// critères).
final class GeneValidation {
  /// Gêne.
  const GeneValidation({
    required this.zone,
    required this.gene,
    required this.antecedent,
    required this.libelle,
    this.articulation,
    this.moisDepuis,
  });

  /// Zone.
  final BodyZone zone;

  /// Articulation déclarée.
  final Joint? articulation;

  /// Gêne actuelle, de 0 à 10.
  final int gene;

  /// Vrai pour un antécédent (statut `history` du banc), faux pour une
  /// gêne présente (`current`).
  final bool antecedent;

  /// Ancienneté de l'épisode, en mois.
  final int? moisDepuis;

  /// Description (texte des constats seulement).
  final String libelle;

  /// Articulation du catalogue concernée (celle déclarée, sinon celle de
  /// la zone), ou `null` (`BenchInjury.catalogJoint`).
  Joint? get articulationCatalogue => articulation ?? articulationDeZone[zone];

  /// Antécédent de moins de douze mois (critère `contre_indication`).
  bool get recente => antecedent && (moisDepuis ?? 99) < 12;
}

/// Profil lu par le validateur de sécurité : les seuls champs que les
/// critères du banc lisent.
final class ProfilValidation {
  /// Profil, champ par champ (champs du banc : voir chaque champ).
  const ProfilValidation({
    required this.niveau,
    required this.anneeNaissance,
    required this.tailleCm,
    this.anneeReference = anneeDebutBanc,
    this.poidsCorpsKg,
    this.records = const <RecordValidation>[],
    this.exercicesConnus = const <String>[],
    this.exercicesNonAcquis = const <String>[],
    this.prudent = false,
    this.genes = const <GeneValidation>[],
    this.semainesEcheance,
    this.semainesPause = 0,
  });

  /// Profil du banc lu dans son JSON (`BenchProfile.fromJson`, champs lus
  /// par les critères seulement ; par exemple `benchJson` d'une saison de
  /// référence). [poidsCorpsKg] : poids de corps du profil des moteurs
  /// (charges totales) ; par défaut celui de `core`, que l'adaptateur du
  /// banc recopie. [FormatException] si un champ lu manque ou a un type
  /// inattendu.
  factory ProfilValidation.depuisJsonBanc(
    Map<String, Object?> json, {
    double? poidsCorpsKg,
  }) {
    final core = _objet(json['core'], 'core');
    final screening = core['healthScreening'];
    final pause = json['break'];
    int? echeance;
    for (final e in _liste(json, 'events')) {
      final event = _objet(e, 'events');
      final priority = _texteOuNull(event, 'priority') ?? 'A';
      if (priority != 'A') {
        continue;
      }
      final weeksOut = _entier(event, 'weeksOut');
      if (echeance == null || weeksOut < echeance) {
        echeance = weeksOut;
      }
    }
    return ProfilValidation(
      niveau: ExperienceLevel.fromCode(_texte(json, 'level')),
      anneeNaissance: _entier(core, 'birthYear'),
      tailleCm: _entier(core, 'heightCm'),
      poidsCorpsKg: poidsCorpsKg ?? _nombreOuNull(core, 'bodyWeightKg'),
      records: <RecordValidation>[
        for (final r in _liste(json, 'records'))
          _recordDeJson(_objet(r, 'records')),
      ],
      exercicesConnus: _textes(core, 'knownExerciseIds'),
      exercicesNonAcquis: _textes(core, 'cannotDoExerciseIds'),
      prudent:
          screening is Map<String, Object?> &&
          screening['outcome'] == HealthScreeningOutcome.cautious.code,
      genes: <GeneValidation>[
        for (final i in _liste(json, 'injuries'))
          _geneDeJson(_objet(i, 'injuries')),
      ],
      semainesEcheance: echeance,
      semainesPause: pause == null
          ? 0
          : _entier(_objet(pause, 'break'), 'weeksOff'),
    );
  }

  /// Profil d'athlète de l'application [profil] (`kalis_core`, schéma 3)
  /// pour un programme qui commence le [debut].
  ///
  /// Correspondances (l'adaptateur du banc, `adapter.dart` de
  /// `kalis_bench`, écrit ces champs depuis le profil du banc ; sur un
  /// profil ainsi adapté, elles redonnent les valeurs du banc sauf où il
  /// est dit « prudent ») :
  /// - niveau : [niveau] s'il est donné, sinon `experience`, sinon
  ///   débutant (prudent : plus bas plafonds) ;
  /// - records : `movementLevels` connus (`known`), valeur `high ?? low`
  ///   (l'adaptateur écrit `low = high = valeur`), distance
  ///   `distanceMeters` ; les niveaux sans valeur sont ignorés ;
  /// - exercices connus, non acquis : `knownExerciseIds`,
  ///   `cannotDoExerciseIds` ;
  /// - prudent : `healthScreening.outcome == cautious` ;
  /// - gênes : `limitations` (zone, articulation, gêne `discomfort`) ;
  ///   ancienneté depuis `since` (moins de 6 semaines : 1 mois ; 6 à 12
  ///   semaines : 2 ; 3 à 12 mois : 3 ; plus de 12 mois ou résolue : 12 ;
  ///   absente : inconnue) ; le profil ne distingue pas gêne présente et
  ///   antécédent : toute gêne de moins de douze mois compte comme
  ///   antécédent récent (prudent) ; libellé : nom de la zone ;
  /// - échéance : la plus proche des `events` de priorité `main` datés au
  ///   plus tôt le [debut], en semaines `(jours depuis debut) ~/ 7 + 1`
  ///   (le banc date l'échéance de `weeksOut` semaines au samedi de la
  ///   semaine `weeksOut − 1`) ;
  /// - semaines de pause : [semainesPause] si elle est donnée, sinon la
  ///   borne basse de `trainingGap` (aucune ou réduite : 0 ; moins de 3
  ///   semaines : 2, prudent ; 3 à 10 : 3 ; 10 à 26 : 11 ; 6 à 24 mois :
  ///   27 ; plus de 2 ans : 105) ;
  /// - âge : `debut.year − birthYear` ; taille, poids : `heightCm`,
  ///   `bodyWeightKg`.
  factory ProfilValidation.depuisProfil(
    AthleteProfile profil, {
    required CivilDate debut,
    ExperienceLevel? niveau,
    int? semainesPause,
  }) {
    int? echeance;
    for (final e in profil.events ?? const <SeasonEvent>[]) {
      if (e.priority != EventPriority.main) {
        continue;
      }
      final jours = e.date.dayNumber - debut.dayNumber;
      if (jours < 0) {
        continue;
      }
      final semaines = jours ~/ 7 + 1;
      if (echeance == null || semaines < echeance) {
        echeance = semaines;
      }
    }
    return ProfilValidation(
      niveau: niveau ?? profil.experience ?? ExperienceLevel.beginner,
      anneeNaissance: profil.birthYear,
      anneeReference: debut.year,
      tailleCm: profil.heightCm,
      poidsCorpsKg: profil.bodyWeightKg,
      records: <RecordValidation>[
        for (final m in profil.movementLevels)
          if (m.known && (m.high ?? m.low) != null)
            RecordValidation(
              exerciseId: m.exerciseId,
              mesure: m.measure,
              valeur: (m.high ?? m.low)!,
              distanceMetres: m.distanceMeters,
            ),
      ],
      exercicesConnus: <String>[...?profil.knownExerciseIds],
      exercicesNonAcquis: <String>[...?profil.cannotDoExerciseIds],
      prudent:
          profil.healthScreening?.outcome == HealthScreeningOutcome.cautious,
      genes: <GeneValidation>[
        for (final l in profil.limitations)
          GeneValidation(
            zone: l.zone,
            articulation: l.joint,
            gene: l.discomfort,
            antecedent: true,
            moisDepuis: _moisDepuis(l.since),
            libelle: _nomZone[l.zone] ?? l.zone.code,
          ),
      ],
      semainesEcheance: echeance,
      semainesPause: semainesPause ?? _semainesDePause(profil.trainingGap),
    );
  }

  /// Niveau global (indice : 0 débutant à 3 élite, ordre de `BenchLevel`).
  final ExperienceLevel niveau;

  /// Année de naissance (`core.birthYear`).
  final int anneeNaissance;

  /// Année de référence de l'âge ([anneeDebutBanc] au banc).
  final int anneeReference;

  /// Taille, en cm (`core.heightCm`).
  final int tailleCm;

  /// Poids de corps, en kg, ou `null` (charges totales : poids du profil
  /// des moteurs ; indice de masse corporelle : `core.bodyWeightKg`, le
  /// même au banc).
  final double? poidsCorpsKg;

  /// Tests et records exacts (`records`), dans l'ordre.
  final List<RecordValidation> records;

  /// Exercices déclarés connus (`core.knownExerciseIds`).
  final List<String> exercicesConnus;

  /// Exercices déclarés non acquis (`core.cannotDoExerciseIds`).
  final List<String> exercicesNonAcquis;

  /// Questionnaire santé en mode prudent (`core.healthScreening.outcome`).
  final bool prudent;

  /// Gênes et antécédents (`injuries`), dans l'ordre.
  final List<GeneValidation> genes;

  /// Semaines jusqu'à l'échéance prioritaire la plus proche
  /// (`mainEvent.weeksOut`), ou `null`.
  final int? semainesEcheance;

  /// Semaines sans entraînement juste avant le programme
  /// (`break.weeksOff`).
  final int semainesPause;

  /// Âge retenu par les critères.
  int get age => anneeReference - anneeNaissance;

  /// Indice de masse corporelle, ou `null` sans poids
  /// (`BenchProfile.bodyMassIndex`).
  double? get indiceMasseCorporelle {
    final weight = poidsCorpsKg;
    if (weight == null) {
      return null;
    }
    final meters = tailleCm / 100;
    return weight / (meters * meters);
  }
}

int? _moisDepuis(ConstraintSince? since) => switch (since) {
  null => null,
  ConstraintSince.under6Weeks => 1,
  ConstraintSince.weeks6To12 => 2,
  ConstraintSince.months3To12 => 3,
  ConstraintSince.over12Months => 12,
  ConstraintSince.pastResolved => 12,
};

int _semainesDePause(TrainingGap? gap) => switch (gap) {
  null => 0,
  TrainingGap.none => 0,
  TrainingGap.reduced => 0,
  TrainingGap.under3Weeks => 2,
  TrainingGap.weeks3To10 => 3,
  TrainingGap.weeks10To26 => 11,
  TrainingGap.months6To24 => 27,
  TrainingGap.over2Years => 105,
};

RecordValidation _recordDeJson(Map<String, Object?> json) => RecordValidation(
  exerciseId: _texte(json, 'exerciseId'),
  mesure: LevelMeasure.fromCode(_texte(json, 'measure')),
  valeur: _nombre(json, 'value'),
  distanceMetres: _nombreOuNull(json, 'distanceMeters'),
);

GeneValidation _geneDeJson(Map<String, Object?> json) {
  final joint = _texteOuNull(json, 'joint');
  return GeneValidation(
    zone: BodyZone.fromCode(_texte(json, 'zone')),
    articulation: joint == null ? null : Joint.fromCode(joint),
    gene: _entier(json, 'discomfort'),
    antecedent: _texte(json, 'status') == 'history',
    moisDepuis: _entierOuNull(json, 'monthsAgo'),
    libelle: _texte(json, 'label'),
  );
}

// Lecture du JSON du banc (mêmes règles que `benchObject`, `benchList`…).

Map<String, Object?> _objet(Object? value, String what) {
  if (value is Map<String, Object?>) {
    return value;
  }
  throw FormatException('$what : objet JSON attendu');
}

List<Object?> _liste(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) {
    return const <Object?>[];
  }
  if (value is List<Object?>) {
    return value;
  }
  throw FormatException('$key : liste JSON attendue');
}

String _texte(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String) {
    return value;
  }
  throw FormatException('$key : texte attendu');
}

String? _texteOuNull(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  throw FormatException('$key : texte attendu');
}

int _entier(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  throw FormatException('$key : entier attendu');
}

int? _entierOuNull(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  throw FormatException('$key : entier attendu');
}

double? _nombreOuNull(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  throw FormatException('$key : nombre attendu');
}

double _nombre(Map<String, Object?> json, String key) {
  final value = _nombreOuNull(json, key);
  if (value == null) {
    throw FormatException('$key : nombre attendu');
  }
  return value;
}

List<String> _textes(Map<String, Object?> json, String key) => <String>[
  for (final v in _liste(json, key))
    if (v is String) v else throw FormatException('$key : textes attendus'),
];
