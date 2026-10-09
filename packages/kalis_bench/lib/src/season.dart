/// Saisons croisées (lot CX, 0.2.0) : `kalis_plan` écrit le plan de saison
/// et chaque bloc, `kalis_adapt` conduit chaque séance d'un athlète simulé,
/// les résumés d'adaptation et les résultats de test nourrissent le bloc
/// suivant, l'affûtage mène à l'échéance et le jour de l'échéance produit
/// les tentatives. Chaque profil street est suivi sur une saison entière
/// (jusqu'à l'échéance et au moins une semaine après, 16 semaines au
/// moins), sous les trois modèles de vérité du simulateur, dans une saison
/// de référence et sept scénarios imposés ; le couple des moteurs 0.1 sert
/// de point de comparaison.
library;

import 'package:kalis_adapt/kalis_adapt.dart';
import 'package:kalis_adapt/simulation.dart';
import 'package:kalis_core/kalis_core.dart';

import 'adapter.dart';
import 'analysis.dart';
import 'profile.dart';
import 'program.dart';
import 'safety.dart';
import 'trajectory.dart';

/// Semaines minimales d'une saison.
const int seasonMinWeeks = 16;

/// Écart entre la première échéance et la deuxième (scénario « deuxième
/// échéance »), en semaines : six semaines laissent une semaine de
/// récupération et un bloc complet de quatre à cinq semaines (R3-P9,
/// R3-P19) — choix raisonné.
const int seasonSecondTargetGap = 6;

/// Semaine (0 = première) où le changement de discipline principale prend
/// effet : la moitié de la saison (choix raisonné).
int seasonDisciplineWeek(int weeks) => weeks ~/ 2;

/// Semaine de l'annonce de la course ajoutée (scénario
/// [SeasonScenario.race]).
const int seasonAddedRaceAnnounce = 4;

/// Semaine de la course ajoutée : six semaines après l'annonce, le temps
/// d'un bloc (choix raisonné, comme [seasonSecondTargetGap]).
const int seasonAddedRaceWeek = 10;

/// Distance de la course ajoutée, en mètres.
const double seasonAddedRaceMeters = 10000;

/// Scénarios imposés d'une saison.
enum SeasonScenario {
  /// Saison de référence : l'athlète simulé du profil.
  base('reference', 'saison de référence'),

  /// Séances manquées : une séance sur quatre, et dix jours d'arrêt.
  missed(
    'seances_manquees',
    'une séance sur quatre manquée et dix jours sans '
        'entraînement (semaines 6 et 7)',
  ),

  /// Semaine de maladie.
  illness('maladie', 'une semaine de maladie (semaine 7)'),

  /// Douleur au coude.
  elbow(
    'douleur_coude',
    'douleur au coude à 5 sur 10 pendant trois semaines '
        '(semaines 5 à 7)',
  ),

  /// Douleur à l'épaule.
  shoulder(
    'douleur_epaule',
    'douleur à l\'épaule à 5 sur 10 pendant trois '
        'semaines (semaines 5 à 7)',
  ),

  /// Parc seulement.
  park('parc_seulement', 'trois semaines au parc seulement (semaines 8 à 10)'),

  /// Échéance avancée de deux semaines.
  earlier(
    'echeance_avancee',
    'échéance avancée de deux semaines, annoncée six '
        'semaines avant la date prévue',
  ),

  /// Deuxième échéance dans la saison.
  second(
    'deuxieme_echeance',
    'deuxième échéance six semaines après la '
        'première',
  ),

  /// Changement de discipline principale à mi-saison (lot CY) : la
  /// première discipline secondaire devient la principale, l'ancienne
  /// principale passe secondaire (profils qui en ont une).
  discipline(
    'changement_discipline',
    'discipline principale changée à mi-saison (la première secondaire '
        'devient la principale)',
  ),

  /// Course ajoutée en cours de saison à un profil street hybride (lot
  /// CY) : un 10 km annoncé en semaine 4, couru en semaine
  /// [seasonAddedRaceWeek].
  race(
    'course_ajoutee',
    'course de 10 km ajoutée en cours de saison (annoncée en semaine 4, '
        'courue en semaine 10)',
  );

  const SeasonScenario(this.code, this.label);

  /// Code stable.
  final String code;

  /// Libellé lisible.
  final String label;
}

/// Semaines jusqu'à l'échéance du profil brut [json] : la plus proche des
/// échéances principales, sinon la plus proche des autres échéances ; sans
/// échéance, le plus lointain des objectifs datés ; ou `null`.
int? seasonTargetWeeks(Map<String, Object?> json) {
  final events = json['events'];
  int? best;
  var bestMain = false;
  if (events is List<Object?>) {
    for (final e in events) {
      if (e is! Map<String, Object?>) {
        continue;
      }
      final w = e['weeksOut'];
      if (w is! int) {
        continue;
      }
      final main = e['priority'] == 'A';
      if (best == null ||
          (main && !bestMain) ||
          (main == bestMain && w < best)) {
        best = w;
        bestMain = main;
      }
    }
  }
  if (best != null) {
    return best;
  }
  final goals = json['goals'];
  if (goals is List<Object?>) {
    for (final g in goals) {
      if (g is! Map<String, Object?>) {
        continue;
      }
      final w = g['weeksOut'];
      if (w is int && (best == null || w > best)) {
        best = w;
      }
    }
  }
  return best;
}

/// Profil brut du scénario [scenario] : le profil [json] lui-même, ou, pour
/// [SeasonScenario.earlier], l'échéance avancée de deux semaines (profil
/// tel qu'il est après l'annonce, pour les critères calculables), et, pour
/// [SeasonScenario.second], une deuxième échéance (copie de la première,
/// même nature et mêmes cibles) [seasonSecondTargetGap] semaines plus tard.
Map<String, Object?> seasonProfileJson(
  Map<String, Object?> json,
  SeasonScenario scenario,
) {
  final target = seasonTargetWeeks(json);
  if (target == null ||
      (scenario != SeasonScenario.earlier &&
          scenario != SeasonScenario.second)) {
    return json;
  }
  final out = Map<String, Object?>.of(json);
  final events = <Object?>[];
  final goals = <Object?>[];
  final rawEvents = json['events'];
  final rawGoals = json['goals'];
  var eventMoved = false;
  if (rawEvents is List<Object?>) {
    for (final e in rawEvents) {
      if (e is! Map<String, Object?>) {
        events.add(e);
        continue;
      }
      final copy = Map<String, Object?>.of(e);
      if (!eventMoved && copy['weeksOut'] == target) {
        eventMoved = true;
        if (scenario == SeasonScenario.earlier) {
          copy['weeksOut'] = target - 2;
          events.add(copy);
        } else {
          events
            ..add(copy)
            ..add(<String, Object?>{
              ...copy,
              'id': '${copy['id']}-2',
              'label': 'deuxième échéance',
              'weeksOut': target + seasonSecondTargetGap,
            });
        }
      } else {
        events.add(copy);
      }
    }
  }
  if (rawGoals is List<Object?>) {
    for (final g in rawGoals) {
      if (g is! Map<String, Object?>) {
        goals.add(g);
        continue;
      }
      final copy = Map<String, Object?>.of(g);
      // Échéance avancée : tout objectif daté du même jour avance avec
      // elle (comme `shiftTargetDate` pour le profil des moteurs) ;
      // deuxième échéance : un objectif n'est doublé que sans échéance.
      if (copy['weeksOut'] == target &&
          (scenario == SeasonScenario.earlier || !eventMoved)) {
        if (scenario == SeasonScenario.earlier) {
          copy['weeksOut'] = target - 2;
          goals.add(copy);
        } else {
          goals
            ..add(copy)
            ..add(<String, Object?>{
              ...copy,
              'id': '${copy['id']}-2',
              'weeksOut': target + seasonSecondTargetGap,
            });
        }
      } else {
        goals.add(copy);
      }
    }
  }
  out['events'] = events;
  out['goals'] = goals;
  return out;
}

/// Semaines simulées d'une saison du profil brut [json] : jusqu'à
/// l'échéance (la deuxième dans le scénario qui en ajoute une) et une
/// semaine après, au moins [seasonMinWeeks].
int seasonWeeksOf(Map<String, Object?> json, SeasonScenario scenario) {
  var target = seasonTargetWeeks(json);
  if (target != null && scenario == SeasonScenario.second) {
    target += seasonSecondTargetGap;
  }
  final weeks = target == null ? seasonMinWeeks : target + 1;
  return weeks < seasonMinWeeks ? seasonMinWeeks : weeks;
}

/// Réglages de l'athlète simulé du profil [bench] dans le scénario
/// [scenario] (champs de `AthleteSpec`).
Map<String, Object?> seasonSpecJson(
  BenchProfile bench,
  SeasonScenario scenario,
) {
  final json = athleteSpecJson(bench);
  switch (scenario) {
    case SeasonScenario.missed:
      json['missRate'] = 0.25;
      json['breakFromDay'] = 37;
      json['breakDays'] = 10;
    case SeasonScenario.illness:
      json['illnessFromDay'] = 42;
      json['illnessDays'] = 7;
    case SeasonScenario.elbow:
      json['painZone'] = BodyZone.elbow.code;
      json['painFromDay'] = 28;
      json['painDays'] = 21;
      json['painIntensity'] = 5;
    case SeasonScenario.shoulder:
      json['painZone'] = BodyZone.shoulder.code;
      json['painFromDay'] = 28;
      json['painDays'] = 21;
      json['painIntensity'] = 5;
    case SeasonScenario.park:
      json['otherPlace'] = Place.outdoor.code;
      json['otherPlaceFromDay'] = 49;
      json['otherPlaceDays'] = 21;
    case SeasonScenario.base:
    case SeasonScenario.earlier:
    case SeasonScenario.second:
    case SeasonScenario.discipline:
    case SeasonScenario.race:
      break;
  }
  return json;
}

/// Profil [p] dont l'échéance du [from] (échéances et objectifs datés de
/// ce jour) est déplacée de [days] jours.
AthleteProfile shiftTargetDate(AthleteProfile p, CivilDate from, int days) {
  final json = p.toJson();
  final to = from.addDays(days).iso;
  final events = json['events'];
  if (events is List<Object?>) {
    json['events'] = <Object?>[
      for (final e in events)
        if (e is Map<String, Object?> && e['date'] == from.iso)
          <String, Object?>{...e, 'date': to}
        else
          e,
    ];
  }
  final goals = json['goals'];
  if (goals is List<Object?>) {
    json['goals'] = <Object?>[
      for (final g in goals)
        if (g is Map<String, Object?> && g['targetDate'] == from.iso)
          <String, Object?>{...g, 'targetDate': to}
        else
          g,
    ];
  }
  return AthleteProfile.fromJson(json);
}

/// Disciplines du profil brut [json] : principale, puis secondaires.
List<String> _disciplinesOf(Map<String, Object?> json) {
  final core = json['core'];
  final mix = core is Map<String, Object?> ? core['disciplines'] : null;
  if (mix is! Map<String, Object?>) {
    return const <String>[];
  }
  final out = <String>[if (mix['primary'] is String) mix['primary']! as String];
  final secondaries = mix['secondaries'];
  if (secondaries is List<Object?>) {
    for (final x in secondaries) {
      if (x is Map<String, Object?> && x['discipline'] is String) {
        out.add(x['discipline']! as String);
      }
    }
  }
  return out;
}

/// Vrai si le scénario [scenario] a un sens pour le profil brut [json] :
/// changement de discipline seulement avec une discipline secondaire ;
/// course ajoutée seulement pour un profil street dont une secondaire est
/// la course (cardio) ; les autres scénarios pour tous les profils.
bool seasonScenarioApplies(Map<String, Object?> json, SeasonScenario scenario) {
  final disciplines = _disciplinesOf(json);
  return switch (scenario) {
    SeasonScenario.discipline => disciplines.length >= 2,
    SeasonScenario.race =>
      json['group'] == 'street' &&
          disciplines.skip(1).contains(TrainingDiscipline.cardio.code),
    _ => true,
  };
}

/// Profil [p] dont la première discipline secondaire devient la principale
/// (les parts restent à leur place : la principale garde la plus grande) ; [p] tel quel sans discipline secondaire.
AthleteProfile swapPrimaryDiscipline(AthleteProfile p) {
  final mix = p.disciplines;
  if (mix.secondaries.isEmpty) {
    return p;
  }
  final first = mix.secondaries.first;
  final street = p.streetMode;
  if (street != null) {
    // Mode street : la composante qui devient principale prend la part de
    // l'ancienne (le dosage reste l'image du mode street, contrat de
    // `kalis_core`) ; une principale hors street retire le mode street.
    StreetStyle? style;
    for (final s in StreetStyle.values) {
      if (s.discipline == first.discipline) {
        style = s;
      }
    }
    if (style != null) {
      final pct = <StreetStyle, int>{
        for (final s in StreetStyle.values) s: street.pctOf(s),
      };
      final old = street.primary;
      final top = pct[old]!;
      pct[old] = pct[style]!;
      pct[style] = top;
      final mode = StreetMode(
        primary: style,
        streetliftingPct: pct[StreetStyle.streetlifting]!,
        setsRepsPct: pct[StreetStyle.setsReps]!,
        calisthenicsPct: pct[StreetStyle.calisthenics]!,
      );
      return p.copyWith(streetMode: mode, disciplines: mode.toDisciplineMix());
    }
  }
  final swapped = mix.copyWith(
    primary: first.discipline,
    secondaries: <DisciplineShare>[
      DisciplineShare(discipline: mix.primary, pct: first.pct),
      ...mix.secondaries.skip(1),
    ],
  );
  return street == null
      ? p.copyWith(disciplines: swapped)
      : p.copyWith(streetMode: null, disciplines: swapped);
}

/// Profil [p] avec une course de [seasonAddedRaceMeters] mètres au jour
/// [date] (échéance secondaire).
AthleteProfile addRace(AthleteProfile p, CivilDate date) => p.copyWith(
  events: <SeasonEvent>[
    ...?p.events,
    SeasonEvent(
      id: 'course-ajoutee',
      kind: EventKind.race,
      priority: EventPriority.secondary,
      date: date,
      name: 'course de 10 km ajoutée',
      distanceMeters: seasonAddedRaceMeters,
    ),
  ],
);

/// Changements du profil en cours de saison pour le scénario [scenario]
/// du profil brut [json] : l'échéance avancée de deux semaines, annoncée
/// six semaines avant sa date prévue (au plus tôt la deuxième semaine) ;
/// la discipline principale changée à mi-saison ; une course ajoutée.
List<ProfileChange> seasonChanges(
  Map<String, Object?> json,
  SeasonScenario scenario,
) {
  if (!seasonScenarioApplies(json, scenario)) {
    return const <ProfileChange>[];
  }
  if (scenario == SeasonScenario.discipline) {
    final week = seasonDisciplineWeek(seasonWeeksOf(json, scenario));
    final names = _disciplinesOf(json);
    return <ProfileChange>[
      ProfileChange(
        week: week,
        apply: swapPrimaryDiscipline,
        label:
            'discipline principale changée en semaine ${week + 1} '
            '(${names[0]} → ${names[1]})',
      ),
    ];
  }
  if (scenario == SeasonScenario.race) {
    final date = eventDate(benchStartDate, seasonAddedRaceWeek);
    return <ProfileChange>[
      ProfileChange(
        week: seasonAddedRaceAnnounce,
        apply: (p) => addRace(p, date),
        label:
            'course de 10 km ajoutée en semaine '
            '${seasonAddedRaceAnnounce + 1} pour la semaine '
            '$seasonAddedRaceWeek',
      ),
    ];
  }
  final target = seasonTargetWeeks(json);
  if (scenario != SeasonScenario.earlier || target == null || target < 6) {
    return const <ProfileChange>[];
  }
  final from = eventDate(benchStartDate, target);
  final week = target - 6 < 1 ? 1 : target - 6;
  return <ProfileChange>[
    ProfileChange(
      week: week,
      apply: (p) => shiftTargetDate(p, from, -14),
      label:
          'échéance avancée de deux semaines (semaine $target → '
          'semaine ${target - 2})',
    ),
  ];
}

/// Profil des moteurs 0.1 : le même profil sans l'ancienneté
/// d'entraînement du schéma 3, ce qui le fait passer par le chemin 0.1 de
/// `kalis_plan` (inchangé ligne à ligne depuis 0.1.0, CP1.1).
AthleteProfile legacyProfileOf(AthleteProfile p) {
  final json = p.toJson()..remove('trainingAge');
  return AthleteProfile.fromJson(json);
}

/// Prescription écrite par le bloc de [run] pour l'emplacement [slotId]
/// de la séance [s], ou `null`.
ExercisePrescription? writtenItemOf(SimRun run, SimSession s, String slotId) {
  ProgramBlock? block;
  for (var i = 0; i < run.blocks.length; i++) {
    if (i < run.blockWeeks.length && run.blockWeeks[i] <= s.week) {
      block = run.blocks[i];
    }
  }
  if (block == null) {
    return null;
  }
  for (final w in block.pass2.weeks) {
    if (w.weekIndex != s.weekInBlock) {
      continue;
    }
    for (final d in w.days) {
      if (d.dayIndex != s.plan.dayIndex) {
        continue;
      }
      for (final it in d.items) {
        if (it.slotId == slotId) {
          return it;
        }
      }
    }
  }
  return null;
}

int? _amountOf(ExercisePrescription it) =>
    it.secondsHigh ?? it.secondsLow ?? it.repsHigh ?? it.repsLow;

/// Écart relatif moyen entre les répétitions (ou secondes) que le bloc
/// écrit et celles que le moteur d'évolution sert, sur les mouvements
/// prioritaires [priority] hors tests : plus il est petit, plus le
/// programme écrit est réaliste pour l'athlète réel. `null` sans séance
/// comparable.
double? writtenGapOf(SimRun run, Set<String> priority) {
  var sum = 0.0;
  var n = 0;
  for (final s in run.served) {
    for (final it in s.plan.items) {
      if (!priority.contains(it.exerciseId) || it.kind == SetKind.test) {
        continue;
      }
      final w = writtenItemOf(run, s, it.slotId);
      if (w == null ||
          w.kind == SetKind.test ||
          w.exerciseId != it.exerciseId) {
        continue;
      }
      final written = _amountOf(w);
      final served = _amountOf(it);
      if (written == null || served == null || written <= 0) {
        continue;
      }
      sum += (served - written).abs() / written;
      n++;
    }
  }
  return n == 0 ? null : sum / n;
}

/// Mouvements prioritaires [priority] présents dans un bloc et absents du
/// bloc suivant sans raison (ni exercice écarté par le résumé
/// d'adaptation, ni bloc de transition) : « rien de défait d'un bloc à
/// l'autre sans raison ». Une étape de figure compte pour sa figure.
int undoneOf(SimRun run, Set<String> priority) {
  Set<String> familiesOf(ProgramBlock b) {
    final out = <String>{};
    for (final w in b.pass2.weeks) {
      for (final d in w.days) {
        for (final it in d.items) {
          final target = it.skillTargetId;
          if (target != null && priority.contains(target)) {
            out.add(target);
          } else if (priority.contains(it.exerciseId)) {
            out.add(it.exerciseId);
          }
        }
      }
    }
    return out;
  }

  var count = 0;
  for (var k = 1; k < run.blocks.length; k++) {
    final after = run.blocks[k];
    final phase = after.pass1.intent?.phase;
    final weeks = after.pass2.weeks;
    if (phase == SeasonPhaseKind.transition ||
        (weeks.isNotEmpty && weeks.first.intent == WeekIntent.transition)) {
      continue;
    }
    final avoided = <String>{};
    final start = k < run.blockWeeks.length ? run.blockWeeks[k] : null;
    for (final (week, review) in run.reviews) {
      if (start != null && week == start - 1) {
        avoided.addAll(review.summary.avoidedExerciseIds);
      }
    }
    final before = familiesOf(run.blocks[k - 1]);
    final now = familiesOf(after);
    for (final id in before) {
      if (!now.contains(id) && !avoided.contains(id)) {
        count++;
      }
    }
  }
  return count;
}

/// Blocs tels qu'ils ont été servis : un bloc arrêté avant son terme (un
/// changement de profil re-planifie la saison) est réduit à ses semaines
/// servies, pour que la semaine `k` de la saison réalisée soit bien la
/// semaine `k` vécue.
List<ProgramBlock> servedBlocksOf(SimRun run) {
  final out = <ProgramBlock>[];
  for (var k = 0; k < run.blocks.length; k++) {
    final b = run.blocks[k];
    if (k + 1 < run.blockWeeks.length) {
      final served = run.blockWeeks[k + 1] - run.blockWeeks[k];
      if (served >= 1 && served < b.pass2.weeks.length) {
        out.add(
          ProgramBlock(
            pass1: b.pass1.copyWith(weeks: served),
            pass2: b.pass2.copyWith(weeks: b.pass2.weeks.sublist(0, served)),
          ),
        );
        continue;
      }
    }
    out.add(b);
  }
  return out;
}

/// Violations de sécurité du programme tel qu'il a évolué dans [run]
/// (blocs reconstruits et propositions appliquées), lues sur [bench]
/// (profil du scénario) jusqu'à [weeks] semaines.
List<Finding> realizedFindings(
  Catalog catalog,
  BenchProfile bench,
  AdaptedProfile adapted,
  SimRun run,
  int weeks,
) => safetyFindings(
  ProgramView(
    catalog,
    BenchProgram(
      bench: bench,
      adapted: adapted,
      request: PlanRequest(
        profile: adapted.profile,
        seed: 0,
        startDate: benchStartDate,
        locks: const <PlanLock>[],
      ),
      blocks: servedBlocksOf(run),
      horizonWeeks: weeks,
    ),
  ),
  bench,
);

double _r(double v) => (v * 100000).roundToDouble() / 100000;

Map<String, Object?> _stat(List<double> values) {
  final s = Stat.of(values);
  var sd = 0.0;
  if (values.length > 1) {
    var ss = 0.0;
    for (final v in values) {
      ss += (v - s.mean) * (v - s.mean);
    }
    sd = ss / (values.length - 1);
    // Racine carrée par la méthode de Newton.
    var x = sd <= 0 ? 0.0 : sd;
    for (var i = 0; i < 30 && x > 0; i++) {
      x = 0.5 * (x + sd / x);
    }
    sd = x;
  }
  return <String, Object?>{...s.toJson(), 'sd': _r(sd)};
}

/// Couples de moteurs d'une saison : `kalis_plan` 0.2 avec `kalis_adapt`
/// 0.2 (« cx »), et les moteurs 0.1 (« v01 », saison de référence
/// seulement).
const List<String> seasonCouples = <String>['cx', 'v01'];

/// Saisons du profil brut [json] (profil du banc [bench]) : pour chaque
/// modèle de vérité, [seeds] graines de la saison de référence et de
/// chaque scénario sous le couple « cx », et [seeds] graines de la saison
/// de référence sous le couple « v01 ».
Map<String, Object?> seasonCampaignOf(
  Catalog catalog,
  PlanEngine plan,
  Map<String, Object?> json, {
  required int seeds,
  List<SeasonScenario> scenarios = SeasonScenario.values,
}) {
  final base = BenchProfile.fromJson(json);
  final priority = <String>{...base.priorityIds};
  final out = <String, Object?>{};
  for (final scenario in scenarios) {
    if (!seasonScenarioApplies(json, scenario)) {
      continue;
    }
    final scenarioJson = seasonProfileJson(json, scenario);
    final bench = BenchProfile.fromJson(scenarioJson);
    // Le profil des moteurs : celui du scénario quand l'échéance est connue
    // dès le départ (deuxième échéance) ; sinon celui du profil, l'avance
    // de l'échéance arrivant en cours de saison.
    final startJson = scenario == SeasonScenario.second ? scenarioJson : json;
    final adapted = adaptProfile(
      BenchProfile.fromJson(startJson),
      catalog: catalog,
    );
    final weeks = seasonWeeksOf(json, scenario);
    final spec = athleteFromJson(seasonSpecJson(base, scenario));
    final changes = seasonChanges(json, scenario);
    final couples = scenario == SeasonScenario.base
        ? seasonCouples
        : const <String>['cx'];
    final byCouple = <String, Object?>{};
    for (final couple in couples) {
      final legacy = couple == 'v01';
      final profile = legacy
          ? legacyProfileOf(adapted.profile)
          : adapted.profile;
      final byTruth = <String, Object?>{};
      for (final truth in TruthKind.values) {
        final runs = <SimRun>[];
        final gaps = <double>[];
        final undone = <double>[];
        final violations = <double>[];
        final events = <double>[];
        final gainsBySeed = <double>[];
        final codes = <String, int>{};
        var pain = 0;
        var flares = 0;
        var done = 0;
        var planned = 0;
        for (var seed = 0; seed < seeds; seed++) {
          final engine = KalisAdapt(legacy: legacy);
          final run = simulate(
            catalog: catalog,
            spec: spec,
            profile: profile,
            seed: seed,
            policy: KalisAdaptPolicy(engine),
            program: SimProgram(catalog, plan, profile, seed: 0),
            weeks: weeks,
            loop: engine,
            truthKind: truth,
            changes: legacy ? const <ProfileChange>[] : changes,
          );
          final gap = writtenGapOf(run, priority);
          if (gap != null) {
            gaps.add(gap);
          }
          undone.add(undoneOf(run, priority).toDouble());
          final found = realizedFindings(catalog, bench, adapted, run, weeks);
          violations.add(found.length.toDouble());
          for (final f in found) {
            codes[f.code] = (codes[f.code] ?? 0) + 1;
          }
          final one = CoachMetrics(<SimRun>[run]);
          if (one.eventPerformance.n > 0) {
            events.add(one.eventPerformance.mean);
          }
          if (run.gain.isNotEmpty) {
            var sum = 0.0;
            for (final g in run.gain.values) {
              sum += g;
            }
            gainsBySeed.add(sum / run.gain.length);
          }
          pain += run.painAggravations;
          flares += run.painFlares;
          done += run.sessionsDone;
          planned += run.sessionsPlanned;
          run.sessions.clear();
          run.blocks.clear();
          run.served.clear();
          run.reviews.clear();
          runs.add(run);
        }
        byTruth[truth.name] = <String, Object?>{
          ...CoachMetrics(runs).toJson(),
          'writtenGap': _stat(gaps),
          'undone': _stat(undone),
          'realizedViolations': _stat(violations),
          'violationCodes': codes,
          'eventStability': _stat(events),
          'gainStability': _stat(gainsBySeed),
          'painAggravations': _r(pain / (seeds == 0 ? 1 : seeds)),
          'painFlares': _r(flares / (seeds == 0 ? 1 : seeds)),
          'adherence': _r(planned == 0 ? 0 : done / planned),
        };
      }
      byCouple[couple] = byTruth;
    }
    out[scenario.code] = <String, Object?>{
      'label': scenario.label,
      'weeks': weeks,
      'couples': byCouple,
    };
  }
  return <String, Object?>{
    'key': base.key,
    'title': base.title,
    'level': base.level.code,
    'seeds': seeds,
    'scenarios': out,
  };
}

String _f(Object? stat, {int digits = 2, bool percent = false}) {
  if (stat is! Map<String, Object?>) {
    return '—';
  }
  final n = stat['n'];
  final mean = stat['mean'];
  if (n is! int || n == 0 || mean is! num) {
    return '—';
  }
  final v = percent ? mean * 100 : mean.toDouble();
  return '${v.toStringAsFixed(digits).replaceAll('.', ',')}'
      '${percent ? ' %' : ''}';
}

/// Les saisons [profiles] (une entrée par profil, voir [seasonCampaignOf])
/// en Markdown.
String seasonCampaignMarkdown(List<Map<String, Object?>> profiles) {
  final seeds = profiles.isEmpty ? 0 : profiles.first['seeds'];
  final b = StringBuffer()
    ..writeln('# Saisons croisées — `kalis_plan` × `kalis_adapt` (lot CX)')
    ..writeln()
    ..writeln(
      'Document généré par `dart run bin/kalis_bench_cli.dart --rapport '
      '<dossier>` (fichier `saisons.json`). Chaque profil street du banc '
      'est suivi sur une saison entière : `kalis_plan` écrit le plan de '
      'saison et chaque bloc, `kalis_adapt` conduit chaque séance, les '
      'résumés d\'adaptation et les résultats de test nourrissent le bloc '
      'suivant (`nextBlock`), jusqu\'à l\'échéance et au moins une semaine '
      'après ($seasonMinWeeks semaines au moins). $seeds graines par modèle '
      'de vérité, pour la saison de référence et pour chaque scénario '
      'imposé ; le couple des moteurs 0.1 (`kalis_plan` chemin 0.1, '
      '`kalis_adapt` en comportement 0.1) sur la saison de référence.',
    )
    ..writeln()
    ..writeln(
      'Colonnes : écart absolu moyen entre l\'effort affiché et l\'effort '
      'réel (répétitions en réserve) ; échecs non voulus ; progression '
      'réelle par semaine ; tentatives réussies ; meilleure performance du '
      'jour de l\'échéance rapportée au maximum réel du jour (et son écart '
      'type entre graines) ; écart relatif entre les répétitions écrites '
      'par le programme et celles que le moteur sert (mouvements '
      'prioritaires) ; mouvements prioritaires retirés d\'un bloc au '
      'suivant sans raison ; violations de sécurité du programme tel qu\'il '
      'a évolué ; hausses sur une zone douloureuse (et poussées d\'une zone '
      'restée réactive après un épisode de douleur, modèles B et C, après la '
      'barre oblique) ; assiduité.',
    );
  final scenarios = <String>[for (final s in SeasonScenario.values) s.code];
  for (final truth in const <String>['a', 'b', 'c']) {
    b
      ..writeln()
      ..writeln('## Modèle de vérité ${truth.toUpperCase()}')
      ..writeln()
      ..writeln(
        '| Profil | Saison | Couple | Écart d\'effort | Échecs | '
        'Progression / sem. | Tentatives | Échéance (écart type) | '
        'Écrit ↔ servi | Retirés sans raison | Violations | Douleur | '
        'Assiduité |',
      )
      ..writeln(
        '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- '
        '| --- | --- |',
      );
    for (final p in profiles) {
      final byScenario = p['scenarios'];
      if (byScenario is! Map<String, Object?>) {
        continue;
      }
      var first = true;
      for (final code in scenarios) {
        final sc = byScenario[code];
        if (sc is! Map<String, Object?>) {
          continue;
        }
        final couples = sc['couples'];
        if (couples is! Map<String, Object?>) {
          continue;
        }
        for (final couple in seasonCouples) {
          final c = couples[couple];
          final m = c is Map<String, Object?> ? c[truth] : null;
          if (m is! Map<String, Object?>) {
            continue;
          }
          final event = m['eventStability'];
          final sd = event is Map<String, Object?> ? event['sd'] : null;
          b.writeln(
            '| ${first ? p['key'] : ''} | $code (${sc['weeks']} sem.) | '
            '$couple | ${_f(m['effortGap'])} | '
            '${_f(m['failRate'], percent: true)} | '
            '${_f(m['weeklyGain'], digits: 3, percent: true)} | '
            '${_f(m['attemptRate'], digits: 0, percent: true)} | '
            '${_f(m['eventPerformance'], digits: 1, percent: true)}'
            '${sd is num && (event as Map<String, Object?>)['n'] != 0 ? ' (${(sd * 100).toStringAsFixed(1).replaceAll('.', ',')})' : ''} | '
            '${_f(m['writtenGap'], digits: 1, percent: true)} | '
            '${_f(m['undone'])} | ${_f(m['realizedViolations'])} | '
            '${m['painAggravations']}'
            '${m['painFlares'] is num ? ' / ${m['painFlares']}' : ''} | '
            '${m['adherence'] is num ? '${((m['adherence']! as num) * 100).toStringAsFixed(0)} %' : '—'} |',
          );
          first = false;
        }
      }
    }
  }
  // Synthèse : moyennes sur les profils, par scénario et couple.
  b
    ..writeln()
    ..writeln('## Moyennes sur les profils (trois modèles de vérité)')
    ..writeln()
    ..writeln(
      '| Saison | Couple | Écart d\'effort | Échecs | Progression / sem. | '
      'Tentatives | Échéance | Écrit ↔ servi | Retirés sans raison | '
      'Violations |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |');
  for (final code in scenarios) {
    for (final couple in seasonCouples) {
      final sums = <String, double>{};
      final counts = <String, int>{};
      for (final p in profiles) {
        final byScenario = p['scenarios'];
        final sc = byScenario is Map<String, Object?> ? byScenario[code] : null;
        final couples = sc is Map<String, Object?> ? sc['couples'] : null;
        final c = couples is Map<String, Object?> ? couples[couple] : null;
        if (c is! Map<String, Object?>) {
          continue;
        }
        for (final truth in const <String>['a', 'b', 'c']) {
          final m = c[truth];
          if (m is! Map<String, Object?>) {
            continue;
          }
          for (final key in const <String>[
            'effortGap',
            'failRate',
            'weeklyGain',
            'attemptRate',
            'eventPerformance',
            'writtenGap',
            'undone',
            'realizedViolations',
          ]) {
            final stat = m[key];
            if (stat is Map<String, Object?> &&
                stat['n'] is int &&
                (stat['n']! as int) > 0 &&
                stat['mean'] is num) {
              sums[key] = (sums[key] ?? 0) + (stat['mean']! as num).toDouble();
              counts[key] = (counts[key] ?? 0) + 1;
            }
          }
        }
      }
      if (counts.isEmpty) {
        continue;
      }
      String mean(String key, {int digits = 2, bool percent = false}) {
        final n = counts[key] ?? 0;
        if (n == 0) {
          return '—';
        }
        final v = sums[key]! / n * (percent ? 100 : 1);
        return '${v.toStringAsFixed(digits).replaceAll('.', ',')}'
            '${percent ? ' %' : ''}';
      }

      b.writeln(
        '| $code | $couple | ${mean('effortGap')} | '
        '${mean('failRate', percent: true)} | '
        '${mean('weeklyGain', digits: 3, percent: true)} | '
        '${mean('attemptRate', digits: 0, percent: true)} | '
        '${mean('eventPerformance', digits: 1, percent: true)} | '
        '${mean('writtenGap', digits: 1, percent: true)} | '
        '${mean('undone')} | ${mean('realizedViolations')} |',
      );
    }
  }
  return b.toString();
}
