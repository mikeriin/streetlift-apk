// Contrats des formats WOD (L3b, KT-008) : une seule source pour la fiche,
// le chronomètre, la saisie du score, les records et l'XP de record.
//
// Règles approuvées par le propriétaire le 25/09/2026 :
// - Tabata : saisie par intervalle ; score = total des minimums de chaque
//   mouvement ; après le dernier effort d'un bloc, le repos entre blocs
//   remplace le repos court ; fin au dernier effort du dernier bloc.
// - Routine sans règle écrite : temps noté, sans record.
// - EMOM sans règle écrite : minutes tenues sur N, la plus haute gagne.
// Règles écrites dans le catalogue et appliquées telles quelles : For Time
// et rounds au temps, AMRAP en rounds + reps, AMRAP en blocs au total des
// rounds, Death by à la dernière minute réussie, E5MOM au total de reps.
import 'wod_models.dart';

/// Règle de score. L'identifiant (versionné) est enregistré sur chaque
/// nouveau résultat : deux résultats ne se comparent que sous la même règle.
enum ScoreRule {
  time('time/1'),
  amrap('amrap/1'),
  emomMinutes('emom-minutes/1'),
  emomReps('emom-reps/1'),
  deathBy('death-by/1'),
  tabata('tabata/1'),
  amrapBlocks('amrap-blocks/1'),
  none('none/1');

  const ScoreRule(this.id);
  final String id;

  static ScoreRule? byId(String? id) {
    for (final r in values) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Plus haut = mieux (sinon plus bas = mieux). Sans objet pour `none`.
  bool get higherIsBetter => this != time;

  /// Règle qui produit un classement.
  bool get ranked => this != none;
}

/// Format structuré du WOD, s'il est valide pour son type.
WodFormat? structuredFormat(Wod w) {
  final f = w.format;
  return f != null && f.validFor(w.type) ? f : null;
}

/// Règle de score actuelle d'un WOD.
ScoreRule ruleFor(Wod w) {
  switch (structuredFormat(w)?.kind) {
    case 'tabata':
      return ScoreRule.tabata;
    case 'amrap-blocks':
      return ScoreRule.amrapBlocks;
    case 'emom-reps':
      return ScoreRule.emomReps;
    case 'death-by':
      return ScoreRule.deathBy;
  }
  return switch (w.type) {
    'fortime' || 'rounds' => ScoreRule.time,
    'amrap' => ScoreRule.amrap,
    'emom' => ScoreRule.emomMinutes,
    _ => ScoreRule.none,
  };
}

/// Règle sous laquelle un résultat se lit.
/// - Résultat versionné (2.5.6 et après) : sa propre règle.
/// - Résultat antérieur (sans version) d'un For Time, rounds ou AMRAP : la
///   règle n'a pas changé (même champs, même sens) ; il se compare aux
///   nouveaux sans conversion ni réécriture.
/// - Autre résultat antérieur (routine, Tabata, AMRAP en blocs, EMOM) :
///   `null` = lecture historique, jamais comparée aux nouveaux résultats.
ScoreRule? readRule(Wod w, WodResult r) {
  if (r.scoring != null) return ScoreRule.byId(r.scoring);
  final rule = ruleFor(w);
  return rule == ScoreRule.time || rule == ScoreRule.amrap ? rule : null;
}

/// Minimum de chaque mouvement d'un Tabata ; `null` pour un mouvement dont
/// un intervalle n'est pas renseigné. Zéro est une valeur réelle.
List<int?> tabataMinima(WodResult r) => [
  for (final block in r.intervals ?? const <List<int?>>[])
    block.isEmpty || block.any((v) => v == null)
        ? null
        : block.cast<int>().reduce((a, b) => a < b ? a : b),
];

/// Saisie Tabata complète pour ce format : bon nombre de mouvements et
/// d'intervalles, chacun renseigné.
bool tabataComplete(WodFormat f, WodResult r) {
  final blocks = r.intervals;
  if (blocks == null || blocks.length != f.movements.length) return false;
  return blocks.every(
    (b) => b.length == f.sets && b.every((v) => v != null && v >= 0),
  );
}

/// Valeur comparable d'un résultat sous une règle, ou `null` si le résultat
/// ne porte pas les données nécessaires (jamais de valeur par défaut).
num? performance(ScoreRule rule, WodResult r, [WodFormat? format]) {
  switch (rule) {
    case ScoreRule.time:
      final s = r.seconds;
      return s != null && s > 0 ? s : null;
    case ScoreRule.amrap:
    case ScoreRule.emomMinutes:
    case ScoreRule.deathBy:
    case ScoreRule.amrapBlocks:
      final rounds = r.rounds;
      return rounds != null && rounds >= 0 ? rounds : null;
    case ScoreRule.emomReps:
      final reps = r.reps;
      return reps != null && reps >= 0 ? reps : null;
    case ScoreRule.tabata:
      if (format != null && !tabataComplete(format, r)) return null;
      final minima = tabataMinima(r);
      if (minima.isEmpty || minima.any((m) => m == null)) return null;
      return minima.fold<int>(0, (a, b) => a + b!);
    case ScoreRule.none:
      return null;
  }
}

/// Le résultat entre dans le classement de la règle actuelle du WOD.
bool isRanked(Wod w, WodResult r) {
  final rule = ruleFor(w);
  return rule.ranked &&
      r.completed &&
      readRule(w, r) == rule &&
      performance(rule, r, structuredFormat(w)) != null;
}

/// `a` bat strictement `b` sous `rule` (égalité : pas de nouveau record).
bool beats(ScoreRule rule, WodResult a, WodResult b, [WodFormat? format]) {
  if (rule == ScoreRule.amrap) {
    // Rounds d'abord, puis reps (même lecture qu'avant L3b).
    return a.rounds! > b.rounds! ||
        (a.rounds == b.rounds && (a.reps ?? 0) > (b.reps ?? 0));
  }
  final va = performance(rule, a, format)!, vb = performance(rule, b, format)!;
  return rule.higherIsBetter ? va > vb : va < vb;
}

/// Record actuel : premier des meilleurs résultats classés.
WodResult? bestResult(Wod w) {
  final rule = ruleFor(w);
  final format = structuredFormat(w);
  WodResult? best;
  for (final r in w.results) {
    if (!isRanked(w, r)) continue;
    if (best == null || beats(rule, r, best, format)) best = r;
  }
  return best;
}

// ---------------------------------------------------------------------------
// Lecture historique : l'ancienne règle, conservée à l'identique pour l'XP
// de record des résultats antérieurs à L3b (aucun gain, aucune perte).

bool legacyValid(Wod w, WodResult r) {
  if (!r.completed) return false;
  if (w.timed) return r.seconds != null && r.seconds! > 0;
  return (w.type == 'amrap' || w.type == 'emom') &&
      r.rounds != null &&
      r.rounds! >= 0;
}

bool legacyBeats(Wod w, WodResult value, WodResult best) => w.timed
    ? value.seconds! < best.seconds!
    : value.rounds! > best.rounds! ||
          (value.rounds == best.rounds && (value.reps ?? 0) > (best.reps ?? 0));

/// Groupe de comparaison pour l'XP de record : résultats lus sous la même
/// règle ; `legacy` = anciens résultats d'une règle qui a changé (ancienne
/// règle) ; `null` = aucun record possible.
String? recordGroup(Wod w, WodResult r) {
  final rule = readRule(w, r);
  if (rule == null) return r.scoring == null ? 'legacy' : null;
  return rule.ranked ? rule.id : null;
}

// ---------------------------------------------------------------------------
// Déroulement chronométré par phases.

enum PhaseKind { prep, work, rest, blockRest }

class WodPhase {
  final PhaseKind kind;
  final int seconds;

  /// Bloc (0…) et intervalle dans le bloc (0…), pour l'affichage.
  final int block, interval;
  const WodPhase(this.kind, this.seconds, {this.block = 0, this.interval = 0});
}

/// Phases du WOD (hors préparation), ou `null` s'il ne se déroule pas par
/// phases. Tabata : effort / repos court entre deux intervalles ; après le
/// dernier effort d'un bloc, le repos entre blocs (s'il en reste un) ; fin
/// au dernier effort du dernier bloc (règle approuvée).
List<WodPhase>? phasesOf(Wod w) {
  final f = structuredFormat(w);
  if (f == null) return null;
  if (f.kind == 'tabata') {
    return [
      for (var b = 0; b < f.movements.length; b++) ...[
        for (var i = 0; i < f.sets; i++) ...[
          WodPhase(PhaseKind.work, f.work, block: b, interval: i),
          if (i < f.sets - 1 && f.rest > 0)
            WodPhase(PhaseKind.rest, f.rest, block: b, interval: i),
        ],
        if (b < f.movements.length - 1 && f.blockRest > 0)
          WodPhase(PhaseKind.blockRest, f.blockRest, block: b, interval: 0),
      ],
    ];
  }
  if (f.kind == 'amrap-blocks') {
    return [
      for (var b = 0; b < f.blockMinutes.length; b++) ...[
        WodPhase(PhaseKind.work, f.blockMinutes[b] * 60, block: b),
        if (b < f.blockMinutes.length - 1 && f.blockRest > 0)
          WodPhase(PhaseKind.blockRest, f.blockRest, block: b),
      ],
    ];
  }
  return null;
}

/// Durée totale annoncée des phases, en secondes (préparation exclue).
int phasesDuration(List<WodPhase> phases) =>
    phases.fold(0, (sum, p) => sum + p.seconds);

String durationLabel(int seconds) {
  final m = seconds ~/ 60, s = seconds % 60;
  if (m == 0) return '$s s';
  return s == 0 ? '$m min' : '$m min $s s';
}

/// Libellé de la phase en cours, lisible sans couleur ni son.
String phaseTitle(Wod w, WodPhase p) {
  final f = structuredFormat(w)!;
  switch (p.kind) {
    case PhaseKind.prep:
      return 'PRÉPARATION';
    case PhaseKind.work:
      return f.kind == 'tabata'
          ? 'EFFORT'
          : 'AMRAP ${p.block + 1}/${f.blockMinutes.length}';
    case PhaseKind.rest:
      return 'REPOS';
    case PhaseKind.blockRest:
      return f.kind == 'tabata' ? 'REPOS ENTRE MOUVEMENTS' : 'REPOS';
  }
}

/// Position dans le déroulement : « Mouvement 2/3 · push-ups · intervalle
/// 5/8 », ou pour un repos entre blocs, ce qui suit.
String phaseDetail(Wod w, WodPhase p) {
  final f = structuredFormat(w)!;
  if (f.kind == 'tabata') {
    final n = f.movements.length;
    if (p.kind == PhaseKind.prep) {
      return 'Ensuite : ${f.movements.first}, intervalle 1/${f.sets}';
    }
    if (p.kind == PhaseKind.blockRest) {
      return 'Ensuite : mouvement ${p.block + 2}/$n · ${f.movements[p.block + 1]}';
    }
    final next = p.kind == PhaseKind.rest
        ? ' · ensuite ${p.interval + 2}/${f.sets}'
        : '';
    return 'Mouvement ${p.block + 1}/$n · ${f.movements[p.block]} · intervalle ${p.interval + 1}/${f.sets}$next';
  }
  final n = f.blockMinutes.length;
  if (p.kind == PhaseKind.prep) return 'Ensuite : bloc 1/$n';
  if (p.kind == PhaseKind.blockRest) {
    return 'Ensuite : bloc ${p.block + 2}/$n (${f.blockMinutes[p.block + 1]} min)';
  }
  return 'Bloc ${p.block + 1}/$n · ${f.blockMinutes[p.block]} min';
}

// ---------------------------------------------------------------------------
// Libellés.

/// Nom du format quand il précise le type (null : libellé du type).
String? formatLabel(Wod w) => switch (structuredFormat(w)?.kind) {
  'tabata' => 'Tabata',
  'amrap-blocks' => 'AMRAP en blocs',
  'death-by' => 'Death by (EMOM)',
  _ => null,
};

/// Entête d'un format structuré (null : entête générique).
String? formatHeader(Wod w) {
  final f = structuredFormat(w);
  if (f == null) return null;
  switch (f.kind) {
    case 'tabata':
      final total = phasesDuration(phasesOf(w)!);
      return '${f.movements.length} mouvement${f.movements.length > 1 ? 's' : ''} · '
          '${f.sets} × ${f.work} s / ${f.rest} s · '
          '${durationLabel(f.blockRest)} entre deux · ${durationLabel(total)}';
    case 'amrap-blocks':
      final total = phasesDuration(phasesOf(w)!);
      return '${f.blockMinutes.join('-')} min · repos ${durationLabel(f.blockRest)} · ${durationLabel(total)}';
    case 'emom-reps':
    case 'death-by':
      return '${w.rounds} × ${w.interval} s';
  }
  return null;
}

/// Règle de score en clair, avec son unité et son sens.
String ruleText(Wod w) {
  final f = structuredFormat(w);
  switch (ruleFor(w)) {
    case ScoreRule.time:
      final cap = w.minutes > 0
          ? ' Time cap ${w.minutes} min : au-delà, le résultat est incomplet.'
          : '';
      return 'Score : temps (min:s), le plus court gagne. Seul un WOD terminé en entier compte comme record.$cap';
    case ScoreRule.amrap:
      return 'Score : rounds complets + reps du round en cours, le plus haut gagne. Record : AMRAP mené jusqu’au bout (${w.minutes} min).';
    case ScoreRule.emomMinutes:
      return 'Score : minutes tenues sur ${w.rounds} (travail fini dans l’intervalle), le plus haut gagne.';
    case ScoreRule.emomReps:
      return 'Score : total de ${f!.unit}, le plus haut gagne.';
    case ScoreRule.deathBy:
      return 'Score : dernière minute réussie (sur ${w.rounds} au chrono), la plus haute gagne.';
    case ScoreRule.tabata:
      return 'Score : pour chaque mouvement, les reps de l’intervalle le plus faible ; total de ces minimums, le plus haut gagne. Record : tous les intervalles renseignés.';
    case ScoreRule.amrapBlocks:
      return 'Score : total des rounds sur les ${f!.blockMinutes.length} blocs, le plus haut gagne.';
    case ScoreRule.none:
      return 'Pas de score comparé : la consigne ne donne pas de règle. Le temps est noté pour ton suivi, sans record.';
  }
}

/// Texte affiché d'un résultat saisi sous la règle actuelle.
String scoreText(Wod w, WodResult r) {
  final rule = ScoreRule.byId(r.scoring) ?? ruleFor(w);
  final prefix = r.completed ? '' : 'Incomplet · ';
  switch (rule) {
    case ScoreRule.time:
      return '$prefix${clockText(r.seconds ?? 0)}';
    case ScoreRule.none:
      return '$prefix${r.seconds == null ? 'temps non noté' : clockText(r.seconds!)}';
    case ScoreRule.amrap:
      final rd = r.rounds ?? 0, rp = r.reps ?? 0;
      return '$prefix$rd round${rd > 1 ? 's' : ''}${rp > 0 ? ' + $rp' : ''}';
    case ScoreRule.emomMinutes:
      return '$prefix${r.rounds}/${w.rounds} minutes tenues';
    case ScoreRule.emomReps:
      return '$prefix${r.reps} ${structuredFormat(w)?.unit ?? 'reps'}';
    case ScoreRule.deathBy:
      final m = r.rounds ?? 0;
      return '$prefix${m == 0 ? 'Aucune minute réussie' : 'Minute $m réussie'}';
    case ScoreRule.amrapBlocks:
      return '$prefix${r.rounds} round${(r.rounds ?? 0) > 1 ? 's' : ''} au total';
    case ScoreRule.tabata:
      final minima = tabataMinima(r);
      final list = minima.map((m) => m == null ? '—' : '$m').join(' · ');
      final total = performance(ScoreRule.tabata, r);
      return r.completed && total != null
          ? 'Total $total reps · minimums $list'
          : 'Partiel · minimums $list';
  }
}

/// Explication d'un résultat qui n'entre pas dans le classement actuel
/// (null : il y entre, ou il est simplement incomplet).
String? historicalNote(Wod w, WodResult r) {
  final read = readRule(w, r);
  if (read == ruleFor(w)) return null;
  if (r.scoring != null) {
    return 'Saisi sous une autre règle (${r.scoring}) : non comparé.';
  }
  if (w.type == 'emom') {
    return 'Ancien score (rounds + reps) : conservé, non comparé aux minutes tenues.';
  }
  return switch (ruleFor(w)) {
    ScoreRule.tabata =>
      'Ancien score au temps : conservé, sans répétitions, non comparé.',
    ScoreRule.amrapBlocks =>
      'Ancien score au temps : conservé, non comparé au total des rounds.',
    _ => 'Ancien score au temps : conservé, sans record.',
  };
}

/// Détail lisible d'un résultat (historique, fiche de résultat).
List<String> resultDetails(Wod w, WodResult r) {
  final out = <String>[];
  final blocks = r.intervals;
  if (blocks != null) {
    final f = structuredFormat(w);
    final minima = tabataMinima(r);
    for (var b = 0; b < blocks.length; b++) {
      final name = f != null && b < f.movements.length
          ? f.movements[b]
          : 'Mouvement ${b + 1}';
      final values = blocks[b].map((v) => v == null ? '—' : '$v').join(' · ');
      final min = minima[b];
      out.add(
        '$name : $values${min == null ? ' · intervalle non renseigné' : ' · plus faible $min'}',
      );
    }
  }
  final rule = readRule(w, r);
  if (r.seconds != null && r.seconds! > 0) {
    out.add('Temps enregistré : ${clockText(r.seconds!)}');
  }
  switch (rule) {
    case ScoreRule.amrap:
      if (r.rounds != null) {
        out.add('${r.rounds} rounds · ${r.reps ?? 0} reps du round en cours');
      }
    case ScoreRule.emomMinutes:
      if (r.rounds != null) {
        out.add('${r.rounds} minutes tenues sur ${w.rounds}');
      }
    case ScoreRule.emomReps:
      if (r.reps != null) {
        out.add('${r.reps} ${structuredFormat(w)?.unit ?? 'reps'}');
      }
    case ScoreRule.deathBy:
      if (r.rounds != null) out.add('Dernière minute réussie : ${r.rounds}');
    case ScoreRule.amrapBlocks:
      if (r.rounds != null) out.add('${r.rounds} rounds au total');
    case null:
      if (r.rounds != null) {
        out.add(
          '${r.rounds} tours${r.reps == null ? '' : ' · ${r.reps} répétitions supplémentaires'}',
        );
      }
    case ScoreRule.time || ScoreRule.none || ScoreRule.tabata:
      break;
  }
  out.add(ruleForResultText(w, r));
  final note = historicalNote(w, r);
  if (note != null) out.add(note);
  return out;
}

/// Règle qui s'applique à ce résultat, en clair.
String ruleForResultText(Wod w, WodResult r) {
  final rule = readRule(w, r);
  if (rule == null) return 'Règle : ancien score, lecture historique.';
  if (rule == ruleFor(w)) return ruleText(w);
  return 'Règle : ${rule.id}.';
}

String clockText(int s) {
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, r = s % 60;
  final mm = m.toString().padLeft(h > 0 ? 2 : 1, '0');
  final ss = r.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
}
