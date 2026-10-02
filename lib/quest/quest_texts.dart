// G12 — textes français de la progression. Le moteur `kalis_quest` ne
// produit aucun texte (codes, identifiants, nombres) : ils sont rendus ici.
// Règles L13 : aucune allégation médicale, aucune promesse de résultat.
import 'package:kalis_core/kalis_core.dart' as kc;

import '../athlete_profile.dart'
    show civilText, durationText, numText, weekdayName;
import '../plan/plan_sheets.dart' show planName;

/// Nom d'un exercice du catalogue.
String questExercise(Object? id) => id == null ? '' : planName('$id');

const _monthsShort = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

/// « 12 déc. » (année ajoutée si elle diffère de [today]).
String shortCivil(kc.CivilDate d, {kc.CivilDate? today}) {
  final base = '${d.day == 1 ? '1er' : d.day} ${_monthsShort[d.month - 1]}';
  return today != null && today.year != d.year ? '$base ${d.year}' : base;
}

/// « 2 450 » : milliers séparés par une espace fine insécable.
String thousands(int v) {
  final s = v.abs().toString();
  final out = StringBuffer(v < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(' ');
    out.write(s[i]);
  }
  return out.toString();
}

String plural(int n, String one, [String? many]) =>
    '$n ${n > 1 ? (many ?? '${one}s') : one}';

// ------------------------------------------------------------------- XP

String xpSourceLabel(kc.XpSource s) => switch (s) {
  kc.XpSource.effort => 'Effort',
  kc.XpSource.consistency => 'Régularité',
  kc.XpSource.record => 'Records',
  kc.XpSource.milestone => 'Jalons d’objectif',
  kc.XpSource.quest => 'Quêtes',
};

String kreditSourceLabel(kc.KreditSource s) => switch (s) {
  kc.KreditSource.quest => 'Quête réussie',
  kc.KreditSource.chest => 'Coffre surprise',
  kc.KreditSource.levelUp => 'Passage de niveau',
  kc.KreditSource.milestone => 'Jalon',
  kc.KreditSource.record => 'Record',
};

/// Ligne du registre d'XP : ce qui a rapporté.
String xpEntryText(kc.XpEntry e) {
  for (final r in e.reasons) {
    final p = r.params;
    switch (r.code) {
      case 'quest.no_reward_pain':
        return 'Séance faite malgré une douleur déclarée : pas de gain';
      case 'quest.xp_capped':
        return switch ('${p['scope']}') {
          'week' => 'Séance en plus du programme de la semaine',
          'partial' => 'Séance écourtée : comptée pour ce qui est fait',
          'week_xp' => 'Plafond de la semaine atteint',
          _ => 'Gain plafonné',
        };
      case 'quest.xp_effort':
        final sets = p['sets'];
        return sets is int
            ? 'Séance : ${plural(sets, 'série')} de travail'
            : 'Séance';
      case 'quest.xp_consistency':
        return 'Semaine régulière';
      case 'quest.xp_record':
        return 'Record : ${questExercise(p['exerciseId'])}';
      case 'quest.xp_milestone':
        return 'Jalon d’objectif';
      case 'quest.xp_quest':
        final id = '${p['questId'] ?? ''}';
        return id.startsWith('dev-')
            ? 'Outil de test : XP ajoutés'
            : 'Quête réussie';
      case 'quest.streak':
        return 'Série de ${plural((p['weeks'] as num?)?.toInt() ?? 0, 'semaine')}';
    }
  }
  return xpSourceLabel(e.source);
}

// ---------------------------------------------------------- attributs

const kAttributeOrder = [
  kc.AthleteAttribute.strength,
  kc.AthleteAttribute.endurance,
  kc.AthleteAttribute.power,
  kc.AthleteAttribute.technique,
  kc.AthleteAttribute.mobility,
  kc.AthleteAttribute.consistency,
];

String attributeLabel(kc.AthleteAttribute a) => switch (a) {
  kc.AthleteAttribute.strength => 'Force',
  kc.AthleteAttribute.endurance => 'Endurance',
  kc.AthleteAttribute.power => 'Puissance',
  kc.AthleteAttribute.technique => 'Technique',
  kc.AthleteAttribute.mobility => 'Mobilité',
  kc.AthleteAttribute.consistency => 'Régularité',
};

/// D'où vient la valeur (CONTRAT de kalis_quest, § 5.2, en mots simples).
String attributeSource(kc.AthleteAttribute a) => switch (a) {
  kc.AthleteAttribute.strength =>
    'Tes meilleures charges sur les mouvements de force (squat, soulevé de '
        'terre, développé, tractions et dips lestés…), et à défaut tes '
        'répétitions au poids du corps ou les exercices les plus durs que tu '
        'réussis.',
  kc.AthleteAttribute.endurance =>
    'Tes répétitions sur pompes, tractions et dips, ton temps de course, et '
        'ton cardio des 4 dernières semaines (repère : 150 minutes par '
        'semaine).',
  kc.AthleteAttribute.power =>
    'Ton muscle-up et tes mouvements explosifs, un peu ta force, et tes '
        'séries explosives des 8 dernières semaines (repère : 10 par '
        'semaine).',
  kc.AthleteAttribute.technique =>
    'Tes figures (front lever, planche, équilibre, muscle-up) et la justesse '
        'de tes notes : la part de tes séries notées à une flamme près de la '
        'cible, sur 8 semaines.',
  kc.AthleteAttribute.mobility =>
    'Tes jours de mobilité par semaine (repère : 3) et ton temps de mobilité '
        '(repère : 30 minutes par semaine), sur 4 semaines.',
  kc.AthleteAttribute.consistency =>
    'Tes séances faites sur tes séances prévues, sur les 12 dernières '
        'semaines, et ta série de semaines réussies.',
};

/// Comment la faire monter.
String attributeHow(kc.AthleteAttribute a) => switch (a) {
  kc.AthleteAttribute.strength =>
    'Suis tes charges prescrites et note honnêtement tes flammes : tes '
        'records font monter la Force. Une performance compte entière '
        'pendant 3 semaines, puis un peu moins chaque semaine.',
  kc.AthleteAttribute.endurance =>
    'Ajoute des répétitions sur tes mouvements au poids du corps, et du '
        'cardio régulier.',
  kc.AthleteAttribute.power =>
    'Travaille tes mouvements explosifs et ton muscle-up quand ils sont '
        'dans ton programme.',
  kc.AthleteAttribute.technique =>
    'Note chaque série au plus juste, et progresse sur tes figures.',
  kc.AthleteAttribute.mobility =>
    'Quelques minutes de mobilité, trois jours par semaine, suffisent à '
        'la faire monter.',
  kc.AthleteAttribute.consistency =>
    'Fais les séances prévues de ta semaine. Les jours de repos ne te '
        'coûtent rien.',
};

// --------------------------------------------------------------- rangs

String tierLabel(kc.MovementRankTier t) => switch (t) {
  kc.MovementRankTier.unranked => 'Sans rang',
  kc.MovementRankTier.bronze => 'Bronze',
  kc.MovementRankTier.silver => 'Argent',
  kc.MovementRankTier.gold => 'Or',
  kc.MovementRankTier.platinum => 'Platine',
  kc.MovementRankTier.diamond => 'Diamant',
  kc.MovementRankTier.elite => 'Élite',
};

/// Rang suivant (null : Élite).
kc.MovementRankTier? nextTier(kc.MovementRankTier t) {
  final i = kc.MovementRankTier.values.indexOf(t);
  return i + 1 < kc.MovementRankTier.values.length
      ? kc.MovementRankTier.values[i + 1]
      : null;
}

/// Valeur lisible d'une mesure de rang (`load`, `reps`, `hold`, `run`).
String rankValueText(String measure, num v) => switch (measure) {
  'load' =>
    v < 0 ? '${numText((-v * 10).round() / 10)} kg d’aide' : '${numText((v * 10).round() / 10)} kg',
  'reps' => plural(v.round(), 'répétition'),
  'hold' => durationText(v),
  'run' => '${durationText(v)} sur 5 km',
  _ => numText(v),
};

// -------------------------------------------------------------- quêtes

String questKindLabel(kc.QuestKind k) => switch (k) {
  kc.QuestKind.daily => 'Du jour',
  kc.QuestKind.weekly => 'De la semaine',
  kc.QuestKind.campaign => 'Campagne',
  kc.QuestKind.koach => 'Quête de Koach',
};

String _metricTarget(String? metric, num target) => switch (metric) {
  'sessions' => plural(target.round(), 'séance'),
  'full_sessions' => '${plural(target.round(), 'séance')} en entier',
  'sets_in_target' => '${plural(target.round(), 'série')} dans la cible',
  'rated_sessions' => '${plural(target.round(), 'séance')} toute notée',
  'health_checks' => plural(target.round(), 'bilan'),
  'combo' => '${plural(target.round(), 'série')} d’affilée dans la cible',
  'mobility_seconds' => '${durationText(target)} de mobilité',
  'mobility_days' => '${plural(target.round(), 'jour')} de mobilité',
  'exercise_sets' => plural(target.round(), 'série'),
  _ => numText(target),
};

/// Titre d'une quête.
String questTitle(kc.Quest q) {
  final p = q.params;
  final t = q.target;
  switch (q.template) {
    case 'daily.session':
      return 'Faire ta séance du jour';
    case 'daily.rated':
      return 'Noter toutes tes séries';
    case 'daily.health_check':
      return 'Répondre au bilan du début de séance';
    case 'daily.in_target':
      return 'Mettre ${plural(t.round(), 'série')} dans la cible de flammes';
    case 'daily.combo':
      return 'Enchaîner ${plural(t.round(), 'série')} dans la cible';
    case 'rest.sleep':
      return 'Bien dormir cette nuit';
    case 'rest.hydration':
      return 'Boire régulièrement dans la journée';
    case 'rest.walk':
      return 'Faire une marche tranquille';
    case 'rest.mobility':
      return 'Faire ${durationText(t)} de mobilité douce';
    case 'rest.breathing':
      return 'Prendre quelques minutes de respiration calme';
    case 'weekly.sessions':
      return 'Faire ${plural(t.round(), 'séance')} cette semaine';
    case 'weekly.rated':
      return 'Noter toutes les séries de ${plural(t.round(), 'séance')}';
    case 'weekly.health_checks':
      return 'Faire le bilan avant ${plural(t.round(), 'séance')}';
    case 'weekly.mobility':
      return 'De la mobilité ${plural(t.round(), 'jour')} cette semaine';
    case 'koach.mobility':
      return 'Mobilité : ${_metricTarget('${p['metric']}', t)} cette semaine';
    case 'koach.accuracy':
      return 'Justesse : ${_metricTarget('${p['metric']}', t)}';
    case 'koach.full_sessions':
      return 'Faire ${plural(t.round(), 'séance')} en entier';
    case 'koach.lagging_exercise':
      return '${questExercise(p['exerciseId'])} : toutes tes séries '
          'prévues (${t.round()})';
    case 'koach.weekday':
      final d = p['weekday'];
      return d is int
          ? 'Ne pas manquer ta séance du ${weekdayName(d)}'
          : 'Ne pas manquer ta séance';
    case 'campaign.chapter':
      return 'Chapitre : ${plural(t.round(), 'séance')} de ton bloc';
    case 'campaign.boss':
      return 'Boss du chapitre : ta séance de test, faite au moins à 80 %';
  }
  return _metricTarget('${p['metric']}', t);
}

/// Pourquoi Koach propose cette quête (quêtes de Koach, campagne).
String? questWhy(kc.Quest q) {
  for (final r in q.reasons) {
    final p = r.params;
    switch (r.code) {
      case 'quest.weak_point':
        final a = kc.AthleteAttribute.values
            .where((x) => x.code == p['attribute'])
            .firstOrNull;
        return a == null
            ? 'Un point à renforcer.'
            : 'Ton attribut ${attributeLabel(a)} est l’un de tes plus bas : '
                  'cette quête aide à le faire monter.';
      case 'quest.lagging_exercise':
        return 'C’est l’exercice que tu écourtes ou sautes le plus souvent.';
      case 'quest.weekday_focus':
        return 'C’est le jour où ta séance saute le plus souvent.';
      case 'quest.campaign_chapter':
        return 'Un chapitre par bloc de ton programme.';
      case 'quest.campaign_boss':
        return 'Le boss : la séance de test de ton bloc, ou sa dernière '
            'séance.';
      case 'quest.daily':
        return switch ('${p['dayKind']}') {
          'rest' => 'Jour de repos : seulement de la récupération.',
          'break' => 'Pause déclarée : seulement de la récupération.',
          _ => null,
        };
      case 'quest.weekly':
        return 'Jamais plus que ce que ton programme prévoit.';
    }
  }
  return null;
}

/// Avancement lisible : « 2 / 3 », « 3 min / 5 min ».
String questProgressText(kc.Quest q) {
  final metric = '${q.params['metric']}';
  if (metric == 'mobility_seconds') {
    return '${durationText(q.progress)} / ${durationText(q.target)}';
  }
  if (metric == 'claim') {
    return q.progress >= q.target ? 'fait' : 'à faire';
  }
  return '${numText(q.progress.floorToDouble())} / ${numText(q.target)}';
}

String rewardText(int xp, int kredits) => [
  if (xp > 0) '+${thousands(xp)} XP',
  if (kredits > 0) '+$kredits Krédit${kredits > 1 ? 's' : ''}',
].join(' · ');

// ---------------------------------------------------------- événements

String gradeLabel(kc.SessionGrade g) => switch (g) {
  kc.SessionGrade.s => 'S',
  kc.SessionGrade.a => 'A',
  kc.SessionGrade.b => 'B',
  kc.SessionGrade.c => 'C',
};

String recordKindValue(kc.RecordKind? k, num v) => switch (k) {
  kc.RecordKind.oneRmKg => '${numText((v * 10).round() / 10)} kg (1RM estimé)',
  kc.RecordKind.maxReps => plural(v.round(), 'répétition'),
  kc.RecordKind.maxHoldSeconds => '${durationText(v)} de tenue',
  kc.RecordKind.volumeKg => '${numText(v.round())} kg de volume',
  kc.RecordKind.timeSeconds => '${durationText(v)} (5 km)',
  kc.RecordKind.distanceMeters =>
    v >= 1000 ? '${numText((v / 100).round() / 10)} km' : '${v.round()} m',
  null => numText(v),
};

/// Ligne d'un événement de plaisir (null : non affiché).
String? eventText(kc.DelightEvent e) {
  Object? param(String code, String key) {
    for (final r in e.reasons) {
      if (r.code == code) return r.params[key];
    }
    return null;
  }

  switch (e.kind) {
    case kc.DelightKind.record:
      return 'Record — ${questExercise(e.exerciseId)} : '
          '${recordKindValue(e.recordKind, e.value ?? 0)}';
    case kc.DelightKind.firstTime:
      return 'Première fois : ${questExercise(e.exerciseId)}';
    case kc.DelightKind.chest:
      return 'Coffre surprise : +${e.kredits ?? 0} Krédits';
    case kc.DelightKind.sessionGrade:
      return e.grade == null
          ? null
          : 'Note de séance : ${gradeLabel(e.grade!)}';
    case kc.DelightKind.combo:
      return 'Combo : ${plural(e.combo ?? 0, 'série')} d’affilée dans la '
          'cible';
    case kc.DelightKind.ghost:
      return 'Mieux que la dernière fois : ${questExercise(e.exerciseId)}';
    case kc.DelightKind.weekStreak:
      final n = e.streakWeeks ?? 0;
      return n > 0 ? 'Série : ${plural(n, 'semaine')} réussie' '${n > 1 ? 's' : ''}' : null;
    case kc.DelightKind.levelUp:
      final prestige = param('quest.prestige', 'prestige');
      if (prestige is int) return 'Prestige $prestige !';
      final level = param('quest.level_up', 'level');
      return level is int ? 'Niveau $level !' : 'Niveau supérieur !';
    case kc.DelightKind.rankUp:
      final tier = kc.MovementRankTier.values
          .where((t) => t.code == param('quest.rank_up', 'tier'))
          .firstOrNull;
      return 'Nouveau rang${tier == null ? '' : ' ${tierLabel(tier)}'} : '
          '${questExercise(param('quest.rank_up', 'exerciseId') ?? e.exerciseId)}';
    case kc.DelightKind.goalMilestone:
      return 'Jalon d’objectif atteint';
    case kc.DelightKind.questCompleted:
      return null;
  }
}

// ------------------------------------------------------------ objectifs

/// Valeur d'un objectif dans son unité.
String goalValueText(kc.Goal g, num v) => switch (g.metric) {
  kc.GoalMetric.oneRmKg => '${numText((v * 10).round() / 10)} kg',
  kc.GoalMetric.maxReps => plural(v.round(), 'répétition'),
  kc.GoalMetric.maxHoldSeconds => durationText(v),
  kc.GoalMetric.skillUnlocked => v >= 1 ? 'réussie' : 'pas encore',
  kc.GoalMetric.timeSeconds => durationText(v),
  kc.GoalMetric.distanceMeters =>
    v >= 1000 ? '${numText((v / 100).round() / 10)} km' : '${v.round()} m',
  null => plural(v.round(), 'séance'),
};

/// Prédiction en mots simples (médiane et fourchette à 80 %).
String predictionText(kc.Goal g, kc.GoalProgress p, kc.CivilDate today) {
  if (p.achievedOn != null) {
    return 'Atteint le ${civilText(p.achievedOn!)}. Bravo !';
  }
  final pr = p.prediction;
  if (pr == null) {
    return g.metric == kc.GoalMetric.skillUnlocked
        ? 'Pas de prédiction pour une figure : continue tes progressions.'
        : 'Pas encore de prédiction : il me faut quelques séances de plus '
              'sur cet exercice.';
  }
  if (g.kind == kc.GoalKind.habit) {
    return 'À ton rythme actuel, tu l’atteins vers le '
        '${shortCivil(pr.expectedOn, today: today)}.';
  }
  final low = shortCivil(pr.earliestOn, today: today);
  final high = shortCivil(pr.latestOn, today: today);
  final chances = (pr.confidence * 10).round().clamp(0, 10);
  return 'Le plus probable : vers le '
      '${shortCivil(pr.expectedOn, today: today)}, sans doute entre le '
      '$low et le $high. '
      '${g.targetDate == null ? '' : 'À ta date prévue : environ $chances chance${chances > 1 ? 's' : ''} sur 10.'}';
}
