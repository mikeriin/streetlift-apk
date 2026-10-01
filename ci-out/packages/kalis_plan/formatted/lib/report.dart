/// Rapports lisibles du simulateur : cas types, non-ressemblance,
/// sensibilité. Fonctions pures (aucun fichier, aucune horloge) : `bin/` les
/// écrit, les tests les comparent aux documents de `docs/`.
///
/// À n'importer que depuis `bin/` et les tests. Le texte produit ici est de
/// la documentation ; le moteur, lui, ne rend que des codes.
library;

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_core/testing.dart';

import 'src/context.dart';
import 'src/engine.dart';
import 'src/hash.dart';
import 'src/inspect.dart';
import 'src/params.dart';
import 'src/traits.dart';

const List<String> _weekdays = <String>[
  'lundi',
  'mardi',
  'mercredi',
  'jeudi',
  'vendredi',
  'samedi',
  'dimanche',
];

/// Jour de début des cas types (un lundi).
final CivilDate reportStartDate = CivilDate(2026, 10, 5);

String _f(double v, [int digits = 2]) => v.toStringAsFixed(digits);

String _num(double v) {
  final rounded = (v * 100).roundToDouble() / 100;
  return rounded == rounded.roundToDouble()
      ? rounded.toStringAsFixed(0)
      : rounded.toString();
}

String _name(Catalog catalog, String id) => catalog.find(id)?.name ?? id;

/// Prescription sur une ligne : `3×8-12 · 7 fl. · 90 s · 42,5 kg`.
String prescriptionLine(ExercisePrescription p) {
  final b = StringBuffer();
  final targets = p.setTargets;
  if (p.kind == SetKind.test) {
    b.write('TEST ');
  } else if (p.kind == SetKind.calibration) {
    b.write('CALIBRAGE ');
  }
  if (p.repsLow != null) {
    b.write('${p.sets}×');
    b.write(
      p.repsLow == p.repsHigh ? '${p.repsLow}' : '${p.repsLow}-${p.repsHigh}',
    );
  } else if (p.secondsLow != null) {
    final low = p.secondsLow!;
    final high = p.secondsHigh!;
    if (high >= 300 && p.sets == 1) {
      b.write(
        low == high ? '${high ~/ 60} min' : '${low ~/ 60}-${high ~/ 60} min',
      );
    } else {
      b.write('${p.sets}×');
      b.write(low == high ? '$high s' : '$low-$high s');
    }
  } else if (p.distanceMeters != null) {
    b.write('${p.sets}×${_num(p.distanceMeters!)} m');
  } else if (p.calories != null) {
    b.write('${p.sets}×${_num(p.calories!)} cal');
  }
  if (p.targetFlames != null) {
    b.write(' · ${p.targetFlames} fl.');
  }
  final rest = p.restSeconds;
  if (rest != null && rest > 0) {
    b.write(' · ${rest}s');
  }
  if (p.startLoadKg != null) {
    b.write(' · ${_num(p.startLoadKg!)} kg');
  } else if (p.percentOfOneRm != null) {
    b.write(' · ${(p.percentOfOneRm! * 100).round()} % 1RM');
  }
  if (targets != null) {
    b.write(' [');
    b.write(
      targets
          .map(
            (t) =>
                '${t.repsLow ?? t.secondsLow ?? ''}'
                '${t.loadKg == null ? '' : '@${_num(t.loadKg!)}'}'
                '${t.flames == null ? '' : ' ${t.flames}fl.'}',
          )
          .join(' / '),
    );
    b.write(']');
  }
  if (p.groupId != null) {
    b.write(' · ${p.format ?? 'groupe'} ${p.groupId}');
  }
  return b.toString();
}

/// Résumé d'un profil sur une ligne.
String profileLine(AthleteProfile p) {
  final mix = p.disciplines;
  final parts = <String>[
    '${mix.primary.code} ${mix.primaryPct} %',
    for (final s in mix.secondaries) '${s.discipline.code} ${s.pct} %',
  ];
  final days = <DaySlot>[...p.availability]
    ..sort((a, b) => a.weekday.compareTo(b.weekday));
  final when = days
      .map(
        (d) =>
            '${_weekdays[d.weekday - 1]} ${d.minutes} min'
            '${d.place == null ? '' : ' (${d.place!.code})'}',
      )
      .join(', ');
  final extra = <String>[
    if (p.streetMode != null) 'mode street',
    if (p.experience != null) 'expérience ${p.experience!.code}',
    if (p.bodyWeightKg != null) '${_num(p.bodyWeightKg!)} kg',
    'né en ${p.birthYear}',
    p.sex.code,
    if (p.healthScreening != null) 'santé ${p.healthScreening!.outcome.code}',
    for (final l in p.limitations) '${l.zone.code} gêne ${l.discomfort}/10',
  ];
  return '${parts.join(' + ')} — $when — lieux ${p.places.map((x) => x.code).join(', ')}'
      ' — ${extra.join(', ')}';
}

/// Passe 1 en Markdown : une liste par jour.
List<String> pass1Lines(Catalog catalog, Pass1Plan plan, PlanMetrics metrics) {
  final out = <String>[];
  for (final day in plan.days) {
    out.add(
      '- **${_weekdays[day.weekday - 1]}** (${day.minutesBudget} min, estimé '
      '${_f(metrics.dayMinutes[day.dayIndex], 0)} min) — `${day.focus}`',
    );
    for (final slot in day.slots) {
      out.add(
        '  - ${_name(catalog, slot.exerciseId)} — ${slot.role.code}'
        '${slot.locked ? ' (verrouillé)' : ''} `${slot.exerciseId}`',
      );
    }
  }
  return out;
}

/// Diff en Markdown.
List<String> diffLines(Catalog catalog, PlanDiff diff) {
  if (diff.changes.isEmpty) {
    return <String>['  - (rien d\'autre ne bouge)'];
  }
  return <String>[
    for (final c in diff.changes)
      '  - `${c.kind.code}`'
          '${c.dayIndex == null ? '' : ' jour ${c.dayIndex}'}'
          '${c.fromExerciseId == null ? '' : ' : ${_name(catalog, c.fromExerciseId!)}'}'
          '${c.toExerciseId == null ? '' : ' → ${_name(catalog, c.toExerciseId!)}'}'
          ' (${c.reasons.map((r) => r.code).join(', ')})',
  ];
}

/// Passe 2 en Markdown : un tableau par jour, une colonne par semaine.
List<String> pass2Lines(Catalog catalog, Pass1Plan pass1, Pass2Plan pass2) {
  final out = <String>[];
  final header = StringBuffer('| Exercice |');
  final rule = StringBuffer('| --- |');
  for (final w in pass2.weeks) {
    header.write(' S${w.weekIndex + 1} (${w.kind.code}) |');
    rule.write(' --- |');
  }
  for (final day in pass1.days) {
    out
      ..add('')
      ..add('${_weekdays[day.weekday - 1]} :')
      ..add('')
      ..add(header.toString())
      ..add(rule.toString());
    for (final slot in day.slots) {
      final row = StringBuffer('| ${_name(catalog, slot.exerciseId)} |');
      for (final w in pass2.weeks) {
        ExercisePrescription? found;
        for (final dp in w.days) {
          if (dp.dayIndex != day.dayIndex) {
            continue;
          }
          for (final item in dp.items) {
            if (item.slotId == slot.slotId) {
              found = item;
            }
          }
        }
        row.write(' ${found == null ? '—' : prescriptionLine(found)} |');
      }
      out.add(row.toString());
    }
  }
  return out;
}

/// Cas type complet d'un profil : passe 1, revue simulée (deux
/// remplacements), diff, passe 2.
final class ProfileCase {
  /// Cas calculé par [runProfileCase].
  const ProfileCase({
    required this.key,
    required this.description,
    required this.request,
    required this.pass1,
    required this.metrics,
    required this.reviews,
    required this.reviewed,
    required this.pass2,
    required this.violations,
  });

  /// Clé du profil.
  final String key;

  /// Description du profil.
  final String description;

  /// Requête de création.
  final PlanRequest request;

  /// Passe 1 d'origine.
  final Pass1Plan pass1;

  /// Mesures de la passe 1 (séries réglées).
  final PlanMetrics metrics;

  /// Actions de la revue simulée et leur résultat.
  final List<(ReviewAction, ReviewResult)> reviews;

  /// Passe 1 après la revue.
  final Pass1Plan reviewed;

  /// Passe 2 du programme revu.
  final Pass2Plan pass2;

  /// Violations (contrat, contraintes dures) relevées en chemin.
  final List<String> violations;
}

/// Joue le cas type du profil [fixture] : création, deux actions de revue
/// (« je ne sais pas faire » sur un exercice, puis remplacement d'un autre
/// par sa variante équivalente), passe 2.
ProfileCase runProfileCase(
  Catalog catalog,
  KalisPlan engine,
  ProfileFixture fixture, {
  int seed = 0,
}) {
  final inspector = PlanInspector(catalog, params: engine.params);
  final violations = <String>[];
  var request = PlanRequest(
    profile: fixture.profile,
    seed: seed,
    startDate: reportStartDate,
    locks: const <PlanLock>[],
  );
  final pass1 = engine.createPass1(catalog, request);
  void check(String label, Pass1Plan plan, PlanRequest req) {
    for (final v in plan.validate()) {
      violations.add('$label : ${v.path} ${v.code}');
    }
    for (final v in catalog.checkExerciseIds(<String>{
      for (final d in plan.days)
        for (final s in d.slots) s.exerciseId,
    })) {
      violations.add('$label : ${v.code} ${v.message}');
    }
    for (final v in inspector.hardViolations(req, plan)) {
      violations.add('$label : $v');
    }
  }

  check('passe 1', pass1, request);
  final metrics = inspector.metrics(request, pass1);

  // Revue simulée : le choix des emplacements est fixé par un hachage de
  // la clé du profil, pas par la position.
  final reviews = <(ReviewAction, ReviewResult)>[];
  var current = pass1;
  final slots = <PlanSlot>[for (final d in pass1.days) ...d.slots];
  if (slots.isNotEmpty) {
    final first = slots[fnv1a32('${fixture.key}:a') % slots.length];
    final action = ReviewAction(
      kind: ReviewKind.cannotDo,
      slotId: first.slotId,
    );
    final result = engine.review(
      catalog,
      ReviewRequest(request: request, current: current, action: action),
    );
    reviews.add((action, result));
    request = request.copyWith(
      profile: applyProfileDelta(request.profile, result.profileDelta),
      locks: result.locks,
    );
    current = result.plan;
    check('revue 1', current, request);

    final rest = <PlanSlot>[
      for (final d in current.days)
        for (final s in d.slots)
          if (s.slotId != first.slotId && !s.locked) s,
    ];
    if (rest.isNotEmpty) {
      final second = rest[fnv1a32('${fixture.key}:b') % rest.length];
      final variants = engine.variants(
        catalog,
        VariantsRequest(
          request: request,
          current: current,
          slotId: second.slotId,
        ),
      );
      Variant? pick;
      for (final v in variants.targeted) {
        if (v.kind == VariantKind.equivalent) {
          pick = v;
        }
      }
      pick ??= variants.targeted.isEmpty ? null : variants.targeted.first;
      pick ??= variants.all.isEmpty ? null : variants.all.first;
      if (pick != null) {
        final replace = ReviewAction(
          kind: ReviewKind.replace,
          slotId: second.slotId,
          replacementExerciseId: pick.exerciseId,
        );
        final result2 = engine.review(
          catalog,
          ReviewRequest(request: request, current: current, action: replace),
        );
        reviews.add((replace, result2));
        request = request.copyWith(
          profile: applyProfileDelta(request.profile, result2.profileDelta),
          locks: result2.locks,
        );
        current = result2.plan;
        check('revue 2', current, request);
      }
    }
  }
  final pass2 = engine.createPass2(
    catalog,
    Pass2Request(request: request, pass1: current),
  );
  for (final v in pass2.validate()) {
    violations.add('passe 2 : ${v.path} ${v.code}');
  }
  for (final v in ProgramBlock(pass1: current, pass2: pass2).validate()) {
    violations.add('bloc : ${v.path} ${v.code}');
  }
  return ProfileCase(
    key: fixture.key,
    description: fixture.description,
    request: request,
    pass1: pass1,
    metrics: metrics,
    reviews: reviews,
    reviewed: current,
    pass2: pass2,
    violations: violations,
  );
}

/// Section Markdown d'un cas type.
List<String> profileCaseLines(Catalog catalog, ProfileCase c, int rank) {
  final m = c.metrics;
  final components = <String>[
    for (final s in c.pass1.score.components) '${s.code} ${_f(s.value)}',
  ];
  final groups = <String>[
    for (final g in MuscleGroup.values)
      if (g.major)
        '${g.code} ${_num(m.groupSets[g.code] ?? 0)}'
            ' [${_num(m.bandLow[g.code] ?? 0)}-${_num(m.bandHigh[g.code] ?? 0)}]',
  ];
  final out = <String>[
    '## $rank. `${c.key}`',
    '',
    c.description,
    '',
    'Profil : ${profileLine(c.request.profile)}.',
    '',
    '### Passe 1',
    '',
    'Note ${_f(c.pass1.score.total, 3)} — ${components.join(' · ')}.',
    '',
    ...pass1Lines(catalog, c.pass1, m),
    '',
    'Dosage : ${m.classShare.entries.map((e) => '${e.key} ${(e.value * 100).round()} %'
            ' (visé ${((m.classTarget[e.key] ?? 0) * 100).round()} %)').join(', ')}'
        ' — erreur ${_f(m.dosageError * 100, 1)} points.',
    '',
    'Volume hebdomadaire (séries fractionnaires [bande]) : ${groups.join(', ')}.'
        ' Groupes majeurs dans leur bande : ${(m.inBandShare * 100).round()} %.',
    '',
    'Équilibre : tirage ${_num(m.pullSets)} / poussée ${_num(m.pushSets)} séries ;'
        ' chaîne postérieure ${_num(m.hipSets)} / genou ${_num(m.kneeSets)} ;'
        ' schémas de base ${m.coveredPatterns}/${m.coverablePatterns}.',
    '',
    '### Revue simulée',
    '',
  ];
  if (c.reviews.isEmpty) {
    out.add('(aucune action possible)');
  }
  for (final (action, result) in c.reviews) {
    final slot = action.slotId;
    String? before;
    for (final d in c.pass1.days) {
      for (final s in d.slots) {
        if (s.slotId == slot) {
          before = s.exerciseId;
        }
      }
    }
    final label = action.kind == ReviewKind.cannotDo
        ? '« Je ne sais pas faire » sur ${_name(catalog, before ?? '?')}'
        : 'Remplacement par ${_name(catalog, action.replacementExerciseId ?? '?')}';
    out
      ..add('- $label (`$slot`) :')
      ..addAll(diffLines(catalog, result.diff));
  }
  out
    ..add('')
    ..add('### Passe 2')
    ..addAll(pass2Lines(catalog, c.reviewed, c.pass2))
    ..add('');
  if (c.violations.isNotEmpty) {
    out
      ..add('**VIOLATIONS** : ${c.violations.join(' ; ')}')
      ..add('');
  }
  return out;
}

/// Document `PROFILS_TYPES.md` : les cas types des profils [fixtures].
String profilsTypesMarkdown(
  Catalog catalog,
  KalisPlan engine,
  List<ProfileFixture> fixtures,
) {
  final lines = <String>[
    '# Profils types de kalis_plan',
    '',
    'Fichier généré par `dart run bin/kalis_plan_cli.dart --rapport <dossier>` (kalis_plan '
        '${engine.engineVersion}, catalogue ${catalog.sourceVersion}, règles '
        '${catalog.rulesVersion}) — ne pas modifier à la main ; `test/docs_test.dart` le '
        'compare au moteur.',
    '',
    'Pour chacun des ${fixtures.length} profils des jeux de données de `kalis_core` : la '
        'passe 1 (exercices par séance), une revue simulée (« je ne sais pas faire » sur un '
        'exercice, puis remplacement d\'un autre par sa variante équivalente), le diff, puis '
        'la passe 2 du programme revu. Notation d\'une prescription : séries × plage · '
        'flammes visées · repos · charge de départ (ou part du 1RM visée).',
    '',
  ];
  var rank = 0;
  for (final fixture in fixtures) {
    rank++;
    lines.addAll(
      profileCaseLines(catalog, runProfileCase(catalog, engine, fixture), rank),
    );
  }
  return '${lines.join('\n')}\n';
}

/// Poids par défaut, pour mémoire dans les rapports.
Map<String, double> defaultWeights() {
  const w = ScoreWeights();
  final values = w.values;
  return <String, double>{
    for (var i = 0; i < ScoreWeights.codes.length; i++)
      ScoreWeights.codes[i]: values[i],
  };
}

// ------------------------------------------------------- non-ressemblance

/// Indice de Jaccard de deux ensembles (0 si les deux sont vides).
double jaccard(Set<String> a, Set<String> b) {
  if (a.isEmpty && b.isEmpty) {
    return 0;
  }
  var common = 0;
  for (final x in a) {
    if (b.contains(x)) {
      common++;
    }
  }
  return common / (a.length + b.length - common);
}

/// Exercices d'un programme de passe 1.
Set<String> planExerciseIds(Pass1Plan plan) => <String>{
  for (final d in plan.days)
    for (final s in d.slots) s.exerciseId,
};

/// Ressemblance maximale tolérée entre la semaine type d'un programme
/// généré et une semaine du programme du propriétaire (indice de Jaccard
/// des exercices). C'est le premier décile de la ressemblance du programme
/// du propriétaire avec lui-même, d'un bloc à l'autre : un programme
/// généré doit lui ressembler moins que neuf fois sur dix ses propres blocs
/// ne se ressemblent (`docs/NON_RESSEMBLANCE.md`).
const double ownerWeekResemblanceLimit = 0.30;

/// Programme personnel du propriétaire (`owner_program_v33.json.gz` de
/// kalis_core), lu pour le seul test de non-ressemblance : aucun moteur ne
/// s'en sert (D4.1).
final class OwnerProgram {
  OwnerProgram._(
    this.weeks,
    this.weekBlocks,
    this.sessions,
    this.mains,
    this.accessories,
  );

  /// Lit le fichier normalisé de kalis_core.
  factory OwnerProgram.fromJson(Map<String, Object?> json) {
    final weeks = <Set<String>>[];
    final blocks = <String>[];
    final sessions = <Set<String>>[];
    final mains = <String>{};
    final others = <String>{};
    for (final w in json['weeks']! as List<Object?>) {
      final week = w! as Map<String, Object?>;
      final ids = <String>{};
      for (final d in week['days']! as List<Object?>) {
        final day = d! as Map<String, Object?>;
        final session = <String>{};
        for (final x in (day['exercises'] as List<Object?>?) ?? const []) {
          final exercise = x! as Map<String, Object?>;
          final id = exercise['catalogId'];
          if (id is! String) {
            continue;
          }
          session.add(id);
          if (exercise['main'] == true) {
            mains.add(id);
          } else {
            others.add(id);
          }
        }
        if (session.isNotEmpty) {
          sessions.add(session);
          ids.addAll(session);
        }
      }
      if (ids.isNotEmpty) {
        weeks.add(ids);
        blocks.add('${week['blockKey']}');
      }
    }
    return OwnerProgram._(
      weeks,
      blocks,
      sessions,
      mains,
      others.difference(mains),
    );
  }

  /// Exercices de chaque semaine (semaines sans correspondance omises).
  final List<Set<String>> weeks;

  /// Bloc de chaque semaine de [weeks].
  final List<String> weekBlocks;

  /// Exercices de chaque séance.
  final List<Set<String>> sessions;

  /// Mouvements principaux.
  final Set<String> mains;

  /// Accessoires : exercices jamais marqués « principal ».
  final Set<String> accessories;

  /// Tous les exercices.
  Set<String> get exerciseIds => <String>{...mains, ...accessories};

  /// Plus forte ressemblance de [ids] avec une semaine du programme.
  double weekResemblance(Set<String> ids) {
    var best = 0.0;
    for (final w in weeks) {
      final j = jaccard(ids, w);
      if (j > best) {
        best = j;
      }
    }
    return best;
  }

  /// Plus forte ressemblance de [ids] avec une séance du programme.
  double sessionResemblance(Set<String> ids) {
    var best = 0.0;
    for (final s in sessions) {
      final j = jaccard(ids, s);
      if (j > best) {
        best = j;
      }
    }
    return best;
  }

  /// Ressemblances entre deux semaines de blocs différents, triées.
  List<double> crossBlockResemblances() {
    final out = <double>[];
    for (var i = 0; i < weeks.length; i++) {
      for (var j = i + 1; j < weeks.length; j++) {
        if (weekBlocks[i] != weekBlocks[j]) {
          out.add(jaccard(weeks[i], weeks[j]));
        }
      }
    }
    out.sort();
    return out;
  }
}

/// Vrai si le profil ne pratique aucune discipline « street »
/// (streetlifting, street workout, calisthénie).
bool isStreetFree(AthleteProfile profile) {
  bool street(TrainingDiscipline d) =>
      d == TrainingDiscipline.streetlifting ||
      d == TrainingDiscipline.streetWorkout ||
      d == TrainingDiscipline.calisthenics;
  if (street(profile.disciplines.primary)) {
    return false;
  }
  for (final s in profile.disciplines.secondaries) {
    if (s.pct > 0 && street(s.discipline)) {
      return false;
    }
  }
  return true;
}

/// Accessoire du propriétaire comparé à ses pairs de la même catégorie.
final class AccessoryFinding {
  /// Constat.
  const AccessoryFinding({
    required this.exerciseId,
    required this.category,
    required this.admissible,
    required this.rate,
    required this.bestPeerId,
    required this.bestPeerRate,
    required this.overRepresented,
    required this.ownerSpecific,
  });

  /// Accessoire du propriétaire.
  final String exerciseId;

  /// Catégorie de la base.
  final String category;

  /// Nombre de profils pour lesquels il était admissible.
  final int admissible;

  /// Part de ces profils dont le programme le contient.
  final double rate;

  /// Exercice hors programme du propriétaire le plus souvent choisi de la
  /// même catégorie, ou `null`.
  final String? bestPeerId;

  /// Sa part.
  final double bestPeerRate;

  /// Sur-représenté (voir [InclusionStudy.findings]).
  final bool overRepresented;

  /// Accessoire propre au propriétaire : exercice d'une discipline street
  /// de la base (streetlifting, street workout, calisthénie). Les autres
  /// (élévations latérales, face pull, mollets…) sont le fonds commun de
  /// tout programme de musculation.
  final bool ownerSpecific;

  /// Objet JSON (rapports).
  Map<String, Object?> toJson() => <String, Object?>{
    'exerciseId': exerciseId,
    'category': category,
    'admissible': admissible,
    'rate': (rate * 10000).round() / 10000,
    'bestPeerId': bestPeerId,
    'bestPeerRate': (bestPeerRate * 10000).round() / 10000,
    'overRepresented': overRepresented,
    'ownerSpecific': ownerSpecific,
  };
}

/// Fréquence de chaque exercice dans les programmes d'une population, par
/// rapport au nombre de profils pour lesquels il était admissible.
final class InclusionStudy {
  /// Profils pour lesquels l'exercice était choisissable.
  final Map<String, int> admissible = <String, int>{};

  /// Programmes qui contiennent l'exercice.
  final Map<String, int> included = <String, int>{};

  /// Nombre de programmes comptés.
  int plans = 0;

  /// Compte le programme [plan] du profil de [request].
  void add(PlanInspector inspector, PlanRequest request, Pass1Plan plan) {
    final PlanContext ctx = inspector.contextFor(request, plan);
    plans++;
    for (final e in ctx.pool) {
      if (e.selectable && !e.fallback) {
        admissible.update(e.id, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    for (final id in planExerciseIds(plan)) {
      included.update(id, (n) => n + 1, ifAbsent: () => 1);
    }
  }

  /// Part des profils (pour lesquels [id] était admissible) dont le
  /// programme contient [id], ou `null` sous [minAdmissible] profils.
  double? rate(String id, {int minAdmissible = 30}) {
    final n = admissible[id] ?? 0;
    return n < minAdmissible ? null : (included[id] ?? 0) / n;
  }

  /// Chaque accessoire du propriétaire face au pair le plus choisi de sa
  /// catégorie. Sur-représenté : choisi pour plus de 5 % des profils où il
  /// est admissible ET plus de deux fois plus souvent que ce meilleur pair.
  List<AccessoryFinding> findings(
    Catalog catalog,
    OwnerProgram owner, {
    int minAdmissible = 30,
  }) {
    final ownerIds = owner.exerciseIds;
    final out = <AccessoryFinding>[];
    final accessories = owner.accessories.toList()..sort();
    for (final id in accessories) {
      final e = catalog.find(id);
      final r = rate(id, minAdmissible: minAdmissible);
      if (e == null || r == null) {
        continue;
      }
      String? bestPeer;
      var bestRate = 0.0;
      for (final peer in catalog.byCategory(e.category)) {
        if (ownerIds.contains(peer.id)) {
          continue;
        }
        final pr = rate(peer.id, minAdmissible: minAdmissible);
        if (pr != null &&
            (pr > bestRate || (pr == bestRate && bestPeer == null))) {
          bestRate = pr;
          bestPeer = peer.id;
        }
      }
      out.add(
        AccessoryFinding(
          exerciseId: id,
          category: e.category,
          admissible: admissible[id] ?? 0,
          rate: r,
          bestPeerId: bestPeer,
          bestPeerRate: bestRate,
          overRepresented: r > 0.05 && r > 2 * bestRate,
          ownerSpecific:
              e.discipline == CatalogDiscipline.streetlifting ||
              e.discipline == CatalogDiscipline.streetWorkout ||
              e.discipline == CatalogDiscipline.calisthenicsStatic ||
              e.discipline == CatalogDiscipline.calisthenicsDynamic,
        ),
      );
    }
    return out;
  }
}
