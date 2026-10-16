/// Critère du lot KS1c2 « aucun jour sans son principal » (`pipeline/cp/
/// prompts/KS1c2.txt`, `CAHIER_KS.md` § 3.6, § 9) : un jour typé porte au
/// moins un exercice principal de son schéma, sur les profils du banc **et**
/// sur une grille de profils incomplets (repères absents par schéma,
/// questionnaire de santé non rempli ou prudent, du débutant à l'élite).
/// Le module ne lit que le contrat de `kalis_core` : il mesure aussi bien
/// `kalis_plan` 0.4.1 (mesure avant) que 0.4.2.
library;

import 'package:kalis_core/kalis_core.dart';

import 'profile.dart';
import 'structure_criteria.dart';

/// Schémas chargés attendus d'un type de jour : `pull`, `push`, `legs` ;
/// `full` en demande deux des trois. Vide pour un jour de course, de
/// récupération, de conditionnement ou de figures seules (leur principal
/// se lit autrement).
Set<String> principalSchemasOf(DayType type) {
  final out = <String>{};
  for (final p in type.patterns) {
    switch (p) {
      case DayPattern.pull:
        out.add('pull');
      case DayPattern.push:
        out.add('push');
      case DayPattern.legs:
        out.add('legs');
      case DayPattern.full:
        out.addAll(const <String>['pull', 'push', 'legs']);
      case DayPattern.skill || DayPattern.run || DayPattern.recovery:
        break;
    }
  }
  return out;
}

/// Écarts d'un jour typé [day] à la règle « aucun jour sans son principal »
/// (liste vide si le jour la tient) :
///
/// - `principal` : aucun emplacement principal (`SlotRole.main`) dont
///   l'exercice est d'un schéma du type ;
/// - `schéma <s>` : un schéma écrit au type (tirage, poussée ou jambes, hors
///   `full`) sans aucun exercice porteur (principal ou secondaire) ;
/// - `corps entier` : un jour `full` dont moins de deux des trois schémas
///   ont un exercice porteur ;
/// - `figure` : un jour de figures seules sans emplacement de figure ni
///   principal.
///
/// Jours sans attente : type absent (bloc écrit avant 0.4.4), course,
/// récupération, conditionnement (le travail principal y est la pièce, pas
/// un schéma).
List<String> principalGapsOfDay(Catalog catalog, PlanDay day) {
  final type = day.type;
  if (type == null ||
      type.quality == DayQuality.run ||
      type.quality == DayQuality.recovery ||
      type.quality == DayQuality.conditioning) {
    return const <String>[];
  }
  final schemas = principalSchemasOf(type);
  final out = <String>[];
  if (schemas.isEmpty) {
    if (type.patterns.contains(DayPattern.skill) &&
        !day.slots.any(
          (s) => s.role == SlotRole.skill || s.role == SlotRole.main,
        )) {
      out.add('figure');
    }
    return out;
  }
  final carried = <String>{};
  var main = false;
  for (final s in day.slots) {
    final e = catalog.find(s.exerciseId);
    final schema = e == null ? null : structureSchemaOf(e);
    if (schema == null || !schemas.contains(schema)) {
      continue;
    }
    if (s.role == SlotRole.main) {
      main = true;
    }
    if (s.role == SlotRole.main || s.role == SlotRole.secondary) {
      carried.add(schema);
    }
  }
  if (!main) {
    out.add('principal');
  }
  if (type.patterns.contains(DayPattern.full)) {
    if (carried.length < 2) {
      out.add('corps entier');
    }
  }
  for (final p in type.patterns) {
    final s = switch (p) {
      DayPattern.pull => 'pull',
      DayPattern.push => 'push',
      DayPattern.legs => 'legs',
      _ => null,
    };
    if (s != null && !carried.contains(s)) {
      out.add('schéma $s');
    }
  }
  return out;
}

/// Écarts d'une passe 1 : `jour : écart` pour chaque jour typé en défaut.
List<String> principalGapsOf(Catalog catalog, Pass1Plan plan) => <String>[
  for (final d in plan.days)
    for (final g in principalGapsOfDay(catalog, d)) '${d.dayIndex} : $g',
];

/// Axe « repères » de la grille des profils incomplets.
enum GridMarks {
  /// Repères du profil, tous.
  all('tous'),

  /// Sans aucun repère de tirage (traction, traction lestée, muscle-up).
  noPull('sans tirage'),

  /// Sans aucun repère de poussée (dips, dips lesté, pompes).
  noPush('sans poussée'),

  /// Sans repère de jambes (squat).
  noLegs('sans jambes'),

  /// Sans repère de muscle-up (strict ou lesté).
  noMuscleUp('sans muscle-up'),

  /// Aucun repère.
  none('aucun');

  const GridMarks(this.label);

  /// Libellé du rapport.
  final String label;
}

/// Axe « santé » de la grille : questionnaire `standard`, non rempli
/// (`not_answered` : programme prudent, constat de KS1A) ou `cautious`.
enum GridHealth {
  /// Questionnaire rempli, réponse standard.
  standard('standard', 'standard'),

  /// Questionnaire non rempli (mode prudent).
  notAnswered('non rempli', 'not_answered'),

  /// Questionnaire rempli, réponse prudente.
  cautious('prudent', 'cautious');

  const GridHealth(this.label, this.code);

  /// Libellé du rapport.
  final String label;

  /// Code de `HealthScreeningOutcome`.
  final String code;
}

/// Axe « niveau » de la grille (niveau, ancienneté en mois).
enum GridLevel {
  /// Débutant, 4 mois.
  beginner('débutant', 'beginner', 4),

  /// Intermédiaire, 18 mois.
  intermediate('intermédiaire', 'intermediate', 18),

  /// Avancé, 48 mois.
  advanced('avancé', 'advanced', 48),

  /// Élite, 96 mois.
  elite('élite', 'elite', 96);

  const GridLevel(this.label, this.code, this.months);

  /// Libellé du rapport.
  final String label;

  /// Code de `BenchLevel`.
  final String code;

  /// Ancienneté d'entraînement, en mois.
  final int months;
}

const Set<String> _pullMarks = <String>{
  'sw-traction-pronation',
  'sl-traction-lestee',
  'sl-muscle-up-leste',
  'cd-muscle-up-barre-strict',
};

const Set<String> _pushMarks = <String>{
  'sw-dips-barres-paralleles',
  'sl-dips-leste',
  'sw-pompe',
};

const Set<String> _legsMarks = <String>{'sl-squat-competition'};

const Set<String> _muscleUpMarks = <String>{
  'sl-muscle-up-leste',
  'cd-muscle-up-barre-strict',
};

bool _dropped(GridMarks marks, String id) => switch (marks) {
  GridMarks.all => false,
  GridMarks.noPull => _pullMarks.contains(id),
  GridMarks.noPush => _pushMarks.contains(id),
  GridMarks.noLegs => _legsMarks.contains(id),
  GridMarks.noMuscleUp => _muscleUpMarks.contains(id),
  GridMarks.none => true,
};

/// Variante du profil [base] (objet JSON d'un profil du banc) : repères
/// [marks], questionnaire [health], niveau [level]. Les objectifs, les
/// échéances, les points faibles et le matériel restent ceux de la base :
/// seuls les repères (`records`, et les étapes de figures qui en tiennent
/// lieu), le questionnaire et le niveau changent. Clé :
/// `<base>~<repères>~<santé>~<niveau>`.
Map<String, Object?> gridVariantJson(
  Map<String, Object?> base,
  GridMarks marks,
  GridHealth health,
  GridLevel level,
) {
  final json = Map<String, Object?>.of(base);
  final core = Map<String, Object?>.of(
    (base['core'] ?? const <String, Object?>{}) as Map<String, Object?>,
  );
  json['key'] = '${base['key']}~${marks.name}~${health.name}~${level.name}';
  json['level'] = level.code;
  json['trainingAgeMonths'] = level.months;
  core['healthScreening'] = <String, Object?>{
    'questionnaireId': 'kalis-sante-l13-v1',
    if (health != GridHealth.notAnswered) 'answeredOn': '2026-10-01',
    'outcome': health.code,
  };
  json['core'] = core;
  json['records'] = <Object?>[
    for (final r in (base['records'] ?? const <Object?>[]) as List<Object?>)
      if (!_dropped(marks, (r! as Map<String, Object?>)['exerciseId']! as String))
        r,
  ];
  if (marks == GridMarks.none) {
    json.remove('unknownLevels');
  }
  return json;
}

/// Grille des profils incomplets : chaque base × repères × santé × niveau
/// (6 × 3 × 4 = 72 variantes par base).
List<BenchProfile> principalGrid(List<Map<String, Object?>> bases) =>
    <BenchProfile>[
      for (final base in bases)
        for (final m in GridMarks.values)
          for (final h in GridHealth.values)
            for (final l in GridLevel.values)
              BenchProfile.fromJson(gridVariantJson(base, m, h, l)),
    ];
