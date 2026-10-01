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

// ------------------------------------------------- comparaison au générateur L10

/// Mesures d'un programme d'un profil, communes aux deux générateurs
/// (`docs/COMPARAISON_L10.md`).
final class ComparisonRow {
  /// Mesures.
  const ComparisonRow({
    required this.sessions,
    required this.overTimeSessions,
    required this.timeUse,
    required this.familyError,
    required this.groupSets,
    required this.pullSets,
    required this.pushSets,
    required this.hipSets,
    required this.kneeSets,
    required this.highStressOnLimitedJoint,
  });

  /// Nombre de séances de la semaine de référence.
  final int sessions;

  /// Séances plus longues que les minutes données ce jour-là.
  final int overTimeSessions;

  /// Part moyenne du temps donné qui est utilisée (plafonnée à 1).
  final double timeUse;

  /// Erreur de dosage en trois familles (renforcement, cardio, mobilité),
  /// de 0 à 1.
  final double familyError;

  /// Séries hebdomadaires fractionnaires par groupe majeur (directes 1,
  /// indirectes 0,5).
  final Map<String, double> groupSets;

  /// Séries de tirage.
  final double pullSets;

  /// Séries de poussée.
  final double pushSets;

  /// Séries de chaîne postérieure.
  final double hipSets;

  /// Séries à dominante genou.
  final double kneeSets;

  /// Exercices de travail à contrainte maximale sur une articulation dont
  /// la gêne déclarée est d'au moins 4 sur 10.
  final int highStressOnLimitedJoint;

  /// Groupes majeurs sous [floor] séries.
  int groupsUnder(double floor) =>
      groupSets.values.where((v) => v < floor).length;

  /// Groupes majeurs au-dessus de [ceiling] séries.
  int groupsOver(double ceiling) =>
      groupSets.values.where((v) => v > ceiling).length;

  /// Équilibre d'un rapport : vrai entre 2/3 et 3/2, faux au-delà (ou si un
  /// seul côté est travaillé), `null` si aucun des deux ne l'est.
  static bool? balanced(double a, double b) {
    if (a <= 0 && b <= 0) {
      return null;
    }
    if (a <= 0 || b <= 0) {
      return false;
    }
    final r = a / b;
    return r >= 2 / 3 - 1e-9 && r <= 3 / 2 + 1e-9;
  }
}

const Map<String, String> _oldJointOfCode = <String, String>{
  'epaule': 'epaule',
  'coude': 'coude',
  'poignet': 'poignet',
  'lombaires': 'rachis_lombaire',
  'genou': 'genou',
  'hanche': 'hanche',
  'cheville': 'cheville',
};

/// Parts visées en trois familles (renforcement, cardio, mobilité) d'un
/// profil sans « forme générale », ou `null` s'il en comporte.
(double, double, double)? familyTargets(AthleteProfile profile) {
  var r = 0.0;
  var c = 0.0;
  var m = 0.0;
  void add(TrainingDiscipline d, int pct) {
    if (d == TrainingDiscipline.cardio) {
      c += pct;
    } else if (d == TrainingDiscipline.mobility) {
      m += pct;
    } else {
      r += pct;
    }
  }

  if (profile.disciplines.primary == TrainingDiscipline.generalFitness) {
    return null;
  }
  add(profile.disciplines.primary, profile.disciplines.primaryPct);
  for (final s in profile.disciplines.secondaries) {
    if (s.discipline == TrainingDiscipline.generalFitness && s.pct > 0) {
      return null;
    }
    add(s.discipline, s.pct);
  }
  final sum = r + c + m;
  return sum <= 0 ? null : (r / sum, c / sum, m / sum);
}

double _familyError((double, double, double)? target, double r, double c, double m) {
  if (target == null) {
    return 0;
  }
  final sum = r + c + m;
  if (sum <= 0) {
    return 1;
  }
  final (tr, tc, tm) = target;
  return ((r / sum - tr).abs() + (c / sum - tc).abs() + (m / sum - tm).abs()) /
      2;
}

List<(Joint, int)> _limitedJoints(AthleteProfile profile) => <(Joint, int)>[
  for (final l in profile.limitations)
    if (l.discomfort >= 4 && (l.joint ?? l.zone.joint) != null)
      ((l.joint ?? l.zone.joint)!, l.discomfort),
];

/// Mesures du programme de l'ancien générateur L10 pour le profil
/// [fixture], lues dans l'extrait [l10] (`docs/data/l10_sorties.json.gz`).
ComparisonRow l10ComparisonRow(ProfileFixture fixture, Map<String, Object?> l10) {
  final profiles = l10['profiles']! as Map<String, Object?>;
  final exercises = l10['exercises']! as Map<String, Object?>;
  final p = profiles[fixture.key]! as Map<String, Object?>;
  final minutesOf = <int, int>{
    for (final d in fixture.profile.availability) d.weekday: d.minutes,
  };
  final limited = _limitedJoints(fixture.profile);
  final groups = <String, double>{
    for (final g in MuscleGroup.values)
      if (g.major) g.code: 0,
  };
  var sessions = 0;
  var over = 0;
  var use = 0.0;
  var resistance = 0.0;
  var mobility = 0.0;
  var pull = 0.0;
  var push = 0.0;
  var hip = 0.0;
  var knee = 0.0;
  var stressed = 0;
  for (final d in p['days']! as List<Object?>) {
    final day = d! as Map<String, Object?>;
    final given = minutesOf[day['weekday']! as int] ?? 0;
    final estimate = (day['estimateSeconds']! as num) / 60;
    sessions++;
    if (estimate > given + 1e-9) {
      over++;
    }
    use += given <= 0 ? 1 : (estimate > given ? 1 : estimate / given);
    var warm = 0.0;
    var mob = 0.0;
    for (final i in day['items']! as List<Object?>) {
      final item = i! as Map<String, Object?>;
      final role = item['role']! as String;
      final minutes = (item['minutes']! as num).toDouble();
      if (role == 'warmup') {
        warm += minutes;
        continue;
      }
      if (role == 'mobility' || role == 'cooldown') {
        mob += minutes;
        continue;
      }
      if (role == 'ramp') {
        continue;
      }
      final e = exercises[item['exerciseId']] as Map<String, Object?>?;
      if (e == null) {
        continue;
      }
      final sets = (item['sets']! as num).toDouble();
      final credits = e['groups']! as Map<String, Object?>;
      for (final c in credits.entries) {
        groups[c.key] = (groups[c.key] ?? 0) + sets * (c.value! as num) / 2;
      }
      switch (e['family']) {
        case 'push':
          push += sets;
        case 'pull':
          pull += sets;
        case 'squat':
        case 'lunge':
          knee += sets;
        case 'hinge':
          hip += sets;
      }
      final joints = e['joints']! as Map<String, Object?>;
      for (final (joint, _) in limited) {
        if ((joints[_oldJointOfCode[joint.code]] as num? ?? 0) >= 3) {
          stressed++;
        }
      }
    }
    mobility += mob;
    final work = estimate - warm - mob;
    resistance += work < 0 ? 0 : work;
  }
  return ComparisonRow(
    sessions: sessions,
    overTimeSessions: over,
    timeUse: sessions == 0 ? 0 : use / sessions,
    familyError: _familyError(
      familyTargets(fixture.profile),
      resistance,
      0,
      mobility,
    ),
    groupSets: groups,
    pullSets: pull,
    pushSets: push,
    hipSets: hip,
    kneeSets: knee,
    highStressOnLimitedJoint: stressed,
  );
}

/// Mesures du programme de kalis_plan pour le profil [fixture] (passe 1 de
/// graine 0, séries de la dernière semaine de montée de la passe 2).
ComparisonRow planComparisonRow(
  Catalog catalog,
  KalisPlan engine,
  ProfileFixture fixture,
) {
  final inspector = PlanInspector(catalog, params: engine.params);
  final traits = CatalogTraits.of(catalog);
  final request = PlanRequest(
    profile: fixture.profile,
    seed: 0,
    startDate: reportStartDate,
    locks: const <PlanLock>[],
  );
  final pass1 = engine.createPass1(catalog, request);
  final pass2 = engine.createPass2(
    catalog,
    Pass2Request(request: request, pass1: pass1),
  );
  final metrics = inspector.metrics(request, pass1);
  var reference = pass2.weeks.first;
  for (final w in pass2.weeks) {
    if (w.kind == WeekKind.build) {
      reference = w;
    }
  }
  final limited = _limitedJoints(fixture.profile);
  final groups = <String, double>{
    for (final g in MuscleGroup.values)
      if (g.major) g.code: 0,
  };
  var pull = 0.0;
  var push = 0.0;
  var hip = 0.0;
  var knee = 0.0;
  var stressed = 0;
  for (final day in reference.days) {
    for (final item in day.items) {
      final t = traits.of(item.exerciseId);
      if (!t.kind.isResistance) {
        continue;
      }
      final sets = item.sets.toDouble();
      for (final g in MuscleGroup.values) {
        if (g.major) {
          groups[g.code] = groups[g.code]! + sets * t.groupCredits[g.index] / 2;
        }
      }
      switch (t.balance) {
        case BalanceClass.pushHorizontal:
        case BalanceClass.pushVertical:
          push += sets;
        case BalanceClass.pullHorizontal:
        case BalanceClass.pullVertical:
          pull += sets;
        case BalanceClass.pullThenPush:
          pull += sets / 2;
          push += sets / 2;
        case BalanceClass.knee:
          knee += sets;
        case BalanceClass.hip:
          hip += sets;
        case BalanceClass.core:
        case BalanceClass.none:
          break;
      }
      for (final (joint, _) in limited) {
        if (t.exercise.stressOn(joint) == JointStress.high) {
          stressed++;
        }
      }
    }
  }
  var over = 0;
  var use = 0.0;
  for (var d = 0; d < metrics.dayMinutes.length; d++) {
    final given = metrics.dayBudget[d];
    final estimate = metrics.dayMinutes[d];
    if (estimate > given + 1e-9) {
      over++;
    }
    use += estimate > given ? 1 : estimate / given;
  }
  var cardio = 0.0;
  var mobility = 0.0;
  var resistance = 0.0;
  for (final e in metrics.classShare.entries) {
    if (e.key == DisciplineClass.cardio.name) {
      cardio += e.value;
    } else if (e.key == DisciplineClass.mobility.name) {
      mobility += e.value;
    } else {
      resistance += e.value;
    }
  }
  return ComparisonRow(
    sessions: metrics.dayMinutes.length,
    overTimeSessions: over,
    timeUse: metrics.dayMinutes.isEmpty ? 0 : use / metrics.dayMinutes.length,
    familyError: _familyError(
      familyTargets(fixture.profile),
      resistance,
      cardio,
      mobility,
    ),
    groupSets: groups,
    pullSets: pull,
    pushSets: push,
    hipSets: hip,
    kneeSets: knee,
    highStressOnLimitedJoint: stressed,
  );
}

/// Vrai si le profil consacre au moins la moitié de son temps au
/// renforcement et s'entraîne au moins deux heures par semaine : les
/// critères de volume et d'équilibre ne se jugent que sur ces profils.
bool isResistanceProfile(AthleteProfile profile) {
  final t = familyTargets(profile);
  var minutes = 0;
  for (final d in profile.availability) {
    minutes += d.minutes;
  }
  return t != null && t.$1 >= 0.5 && minutes >= 120;
}

/// Document `COMPARAISON_L10.md` : kalis_plan face à l'ancien générateur
/// L10 sur les mêmes profils, critère par critère.
String l10ComparisonMarkdown(
  Catalog catalog,
  KalisPlan engine,
  List<ProfileFixture> fixtures,
  Map<String, Object?> l10,
) {
  final l10Profiles = l10['profiles']! as Map<String, Object?>;
  final old = <String, ComparisonRow>{};
  final neu = <String, ComparisonRow>{};
  for (final f in fixtures) {
    old[f.key] = l10ComparisonRow(f, l10);
    neu[f.key] = planComparisonRow(catalog, engine, f);
  }
  final n = fixtures.length;
  final resistance = <ProfileFixture>[
    for (final f in fixtures)
      if (isResistanceProfile(f.profile)) f,
  ];
  final dosed = <ProfileFixture>[
    for (final f in fixtures)
      if (familyTargets(f.profile) != null) f,
  ];
  final limited = <ProfileFixture>[
    for (final f in fixtures)
      if (_limitedJoints(f.profile).isNotEmpty) f,
  ];

  var expressible = 0;
  var approximated = 0;
  for (final f in fixtures) {
    final p = l10Profiles[f.key]! as Map<String, Object?>;
    if ((p['disciplinesWithoutProgramme']! as List<Object?>).isEmpty) {
      expressible++;
      if ((p['disciplinesApproximated']! as List<Object?>).isNotEmpty) {
        approximated++;
      }
    }
  }

  String mean(Iterable<double> values, [int digits = 1]) {
    var sum = 0.0;
    var count = 0;
    for (final v in values) {
      sum += v;
      count++;
    }
    return count == 0 ? '—' : _f(sum / count, digits);
  }

  int total(Map<String, ComparisonRow> rows, int Function(ComparisonRow) f) {
    var sum = 0;
    for (final r in rows.values) {
      sum += f(r);
    }
    return sum;
  }

  String balancedCount(
    Map<String, ComparisonRow> rows,
    bool? Function(ComparisonRow) f,
  ) {
    var ok = 0;
    var applicable = 0;
    for (final fixture in resistance) {
      final b = f(rows[fixture.key]!);
      if (b == null) {
        continue;
      }
      applicable++;
      if (b) {
        ok++;
      }
    }
    return '$ok sur $applicable';
  }

  final rows = <List<String>>[
    <String>[
      'Profils dont chaque discipline a un programme',
      '$expressible sur $n (dont $approximated où la musculation est '
          'traitée comme un objectif de force)',
      '$n sur $n',
    ],
    <String>[
      'Erreur de dosage en trois familles — renforcement, cardio, '
          'mobilité — en points, moyenne (${dosed.length} profils sans '
          '« forme générale »)',
      mean(dosed.map((f) => old[f.key]!.familyError * 100)),
      mean(dosed.map((f) => neu[f.key]!.familyError * 100)),
    ],
    <String>[
      'Profils à 10 points ou moins de leur dosage',
      '${dosed.where((f) => old[f.key]!.familyError <= 0.10).length} sur '
          '${dosed.length}',
      '${dosed.where((f) => neu[f.key]!.familyError <= 0.10).length} sur '
          '${dosed.length}',
    ],
    <String>[
      'Séances plus longues que le temps donné ce jour-là',
      '${total(old, (r) => r.overTimeSessions)} sur '
          '${total(old, (r) => r.sessions)} '
          '(${old.values.where((r) => r.overTimeSessions > 0).length} profils)',
      '${total(neu, (r) => r.overTimeSessions)} sur '
          '${total(neu, (r) => r.sessions)} '
          '(${neu.values.where((r) => r.overTimeSessions > 0).length} profils)',
    ],
    <String>[
      'Temps donné utilisé, moyenne',
      '${mean(old.values.map((r) => r.timeUse * 100), 0)} %',
      '${mean(neu.values.map((r) => r.timeUse * 100), 0)} %',
    ],
    <String>[
      'Groupes musculaires majeurs sous 4 séries par semaine, moyenne par '
          'profil (${resistance.length} profils de renforcement)',
      mean(resistance.map((f) => old[f.key]!.groupsUnder(4).toDouble())),
      mean(resistance.map((f) => neu[f.key]!.groupsUnder(4).toDouble())),
    ],
    <String>[
      'Groupes musculaires majeurs au-dessus de 20 séries par semaine, '
          'moyenne par profil',
      mean(resistance.map((f) => old[f.key]!.groupsOver(20).toDouble())),
      mean(resistance.map((f) => neu[f.key]!.groupsOver(20).toDouble())),
    ],
    <String>[
      'Tirage et poussée équilibrés (rapport entre 2/3 et 3/2)',
      balancedCount(
        old,
        (r) => ComparisonRow.balanced(r.pullSets, r.pushSets),
      ),
      balancedCount(
        neu,
        (r) => ComparisonRow.balanced(r.pullSets, r.pushSets),
      ),
    ],
    <String>[
      'Chaîne postérieure et genou équilibrés (rapport entre 2/3 et 3/2)',
      balancedCount(old, (r) => ComparisonRow.balanced(r.hipSets, r.kneeSets)),
      balancedCount(neu, (r) => ComparisonRow.balanced(r.hipSets, r.kneeSets)),
    ],
    <String>[
      'Exercices à contrainte maximale sur une articulation dont la gêne '
          'est d\'au moins 4/10 (${limited.length} profils)',
      '${limited.fold<int>(0, (s, f) => s + old[f.key]!.highStressOnLimitedJoint)}',
      '${limited.fold<int>(0, (s, f) => s + neu[f.key]!.highStressOnLimitedJoint)}',
    ],
  ];

  final lines = <String>[
    '# kalis_plan face au générateur L10',
    '',
    'Fichier généré par `dart run bin/kalis_plan_cli.dart --rapport <dossier>` (kalis_plan '
        '${engine.engineVersion}) à partir de `docs/data/l10_sorties.json.gz` — ne pas modifier à la '
        'main ; `test/docs_test.dart` le compare au moteur. Lecture et limites de la comparaison : '
        '`docs/VALIDATION.md`, § 5.',
    '',
    'Les deux générateurs reçoivent les mêmes $n profils types (kalis_core). L\'ancien générateur '
        '(L10, version ${l10['generatorVersion']}, graine ${l10['seed']}) ne lit qu\'une partie '
        'du profil : la traduction est décrite dans `tool/l10_export_test.dart.txt`. Semaine comparée : '
        'la semaine ${l10['referenceWeek']} de L10 (première semaine de charge sans calibrage) et la '
        'dernière semaine de montée de kalis_plan. Chaque durée est celle que le générateur estime '
        'lui-même ; les séries par groupe sont recomptées de la même façon des deux côtés (muscle '
        'principal 1, muscle secondaire 0,5, exercices de travail seulement).',
    '',
    '| Critère | L10 | kalis_plan |',
    '| --- | --- | --- |',
    for (final r in rows) '| ${r[0]} | ${r[1]} | ${r[2]} |',
    '',
    '## Détail par profil',
    '',
    'Temps : séances au-delà du temps donné / séances, puis part du temps utilisée. Dosage : erreur '
        'en trois familles, en points (— : profil avec « forme générale »). Volume : groupes majeurs '
        'sous 4 séries / au-dessus de 20. T/P et CP/G : séries de tirage / de poussée, de chaîne '
        'postérieure / à dominante genou.',
    '',
    '| Profil | Disciplines sans programme (L10) | Temps L10 | Temps KP | Dosage L10 | Dosage KP | '
        'Volume L10 | Volume KP | T/P L10 | T/P KP | CP/G L10 | CP/G KP |',
    '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |',
  ];
  for (final f in fixtures) {
    final a = old[f.key]!;
    final b = neu[f.key]!;
    final p = l10Profiles[f.key]! as Map<String, Object?>;
    final without = (p['disciplinesWithoutProgramme']! as List<Object?>).join(
      ', ',
    );
    final hasTarget = familyTargets(f.profile) != null;
    String time(ComparisonRow r) =>
        '${r.overTimeSessions}/${r.sessions} · ${(r.timeUse * 100).round()} %';
    String dose(ComparisonRow r) =>
        hasTarget ? _f(r.familyError * 100, 1) : '—';
    String volume(ComparisonRow r) => '${r.groupsUnder(4)} / ${r.groupsOver(20)}';
    lines.add(
      '| `${f.key}` | ${without.isEmpty ? '—' : without} | ${time(a)} | ${time(b)} | '
      '${dose(a)} | ${dose(b)} | ${volume(a)} | ${volume(b)} | '
      '${_num(a.pullSets)} / ${_num(a.pushSets)} | ${_num(b.pullSets)} / ${_num(b.pushSets)} | '
      '${_num(a.hipSets)} / ${_num(a.kneeSets)} | ${_num(b.hipSets)} / ${_num(b.kneeSets)} |',
    );
  }
  return '${lines.join('\n')}\n';
}
