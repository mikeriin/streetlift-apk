// G7 (D4, D6) : textes français de la création du programme.
//
// Les moteurs ne produisent aucun texte (PIPELINE_GP.md §3) : codes de
// raison, codes de thème, rôles, natures de semaine et composantes de la
// note de `kalis_plan` sont rendus ici, en phrases courtes, au tutoiement,
// sans promesse de résultat ni allégation médicale (règles L13). Un code
// inconnu de l'application donne un texte générique (jamais d'erreur).
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_plan/kalis_plan.dart' show DisciplineClass;

import '../athlete_profile.dart'
    show kDisciplineLabels, kZoneLabels, weekdayName;
import 'reason_texts_0_4.dart';

/// Jour de la semaine avec majuscule (ISO : 1 = lundi).
String weekdayLabel(int isoWeekday) {
  final n = weekdayName(isoWeekday.clamp(1, 7));
  return '${n[0].toUpperCase()}${n.substring(1)}';
}

/// Thème d'une séance (`FocusCodes` de kalis_plan).
const kFocusLabels = <String, String>{
  'mobility': 'Mobilité',
  'cardio.endurance': 'Cardio endurance',
  'cardio.intervals': 'Cardio fractionné',
  'conditioning': 'Conditionnement',
  'skills': 'Figures',
  'strength.lower': 'Bas du corps',
  'strength.push': 'Poussée',
  'strength.pull': 'Tirage',
  'strength.upper': 'Haut du corps',
  'strength.full_body': 'Corps entier',
};

String focusLabel(String code) => kFocusLabels[code] ?? 'Séance';

/// Rôle d'un exercice dans la séance.
const kRoleLabels = <kc.SlotRole, String>{
  kc.SlotRole.main: 'Principal',
  kc.SlotRole.secondary: 'Secondaire',
  kc.SlotRole.accessory: 'Complément',
  kc.SlotRole.skill: 'Figure',
  kc.SlotRole.core: 'Gainage',
  kc.SlotRole.conditioning: 'Conditionnement',
  kc.SlotRole.mobility: 'Mobilité',
  kc.SlotRole.warmup: 'Échauffement',
  kc.SlotRole.cooldown: 'Retour au calme',
};

/// Nature d'une semaine du bloc.
const kWeekKindLabels = <kc.WeekKind, String>{
  kc.WeekKind.intro: 'Introduction',
  kc.WeekKind.build: 'Montée',
  kc.WeekKind.deload: 'Décharge',
  kc.WeekKind.test: 'Test',
};

/// Explication courte d'une nature de semaine (Koach).
const kWeekKindHints = <kc.WeekKind, String>{
  kc.WeekKind.intro:
      'Semaine d’introduction : un peu moins de séries et plus de marge, '
      'pour apprendre les gestes et caler tes charges.',
  kc.WeekKind.build:
      'Semaine de montée : les séries augmentent un peu, la marge diminue '
      'doucement.',
  kc.WeekKind.deload:
      'Semaine de décharge : moins de séries et plus de marge, pour '
      'récupérer avant le bloc suivant.',
  kc.WeekKind.test:
      'Semaine de test : volume réduit et une épreuve pour mesurer où tu en '
      'es sur ton objectif.',
};

/// Groupes musculaires de kalis_plan (`MuscleGroup.code`).
const kMuscleGroupLabels = <String, String>{
  'chest': 'pectoraux',
  'delt_anterior': 'avant des épaules',
  'delt_middle': 'milieu des épaules',
  'delt_posterior': 'arrière des épaules',
  'lats': 'grand dorsal',
  'upper_back': 'haut du dos',
  'biceps': 'biceps',
  'triceps': 'triceps',
  'abs': 'abdominaux',
  'lower_back': 'lombaires',
  'glutes': 'fessiers',
  'quads': 'quadriceps',
  'hamstrings': 'ischio-jambiers',
  'calves': 'mollets',
  'forearms': 'avant-bras',
  'adductors': 'adducteurs',
  'upper_traps': 'trapèzes',
};

/// Classe de discipline de kalis_plan (`DisciplineClass.name`) → libellé.
String disciplineClassLabel(String name) {
  for (final c in DisciplineClass.values) {
    if (c.name == name) return kDisciplineLabels[c.discipline] ?? name;
  }
  return name;
}

/// Discipline du profil par son code (`TrainingDiscipline.code`).
String disciplineCodeLabel(String code) {
  for (final d in kc.TrainingDiscipline.values) {
    if (d.code == code) return kDisciplineLabels[d] ?? code;
  }
  return code;
}

/// Articulation ou zone (`Joint.code`, `BodyZone.code`).
String jointLabel(String code) {
  const joints = <String, String>{
    'epaule': 'épaule',
    'coude': 'coude',
    'poignet': 'poignet',
    'lombaires': 'bas du dos',
    'genou': 'genou',
    'hanche': 'hanche',
    'cheville': 'cheville',
  };
  final j = joints[code];
  if (j != null) return j;
  for (final z in kc.BodyZone.values) {
    if (z.code == code) return (kZoneLabels[z] ?? code).toLowerCase();
  }
  return code;
}

/// Lieu (`Place.code`).
String placeLabel(String code) =>
    const {
      'salle': 'la salle',
      'maison': 'la maison',
      'exterieur': 'dehors',
    }[code] ??
    'ton lieu';

/// Composantes de la note (`PlanScore.components`).
const kScoreLabels = <String, String>{
  'recovery': 'Récupération entre les séances',
  'fatigue_balance': 'Fatigue répartie',
  'joint_load': 'Articulations ménagées',
  'goal_specificity': 'Objectifs travaillés',
  'discipline_dosage': 'Dosage des disciplines',
  'muscle_volume': 'Volume par muscle',
  'pattern_balance': 'Équilibre des mouvements',
  'discipline_structure': 'Structure de chaque discipline',
  'time_use': 'Temps disponible utilisé',
  'variety': 'Variété',
  'exercise_fit': 'Exercices adaptés à ton niveau',
  'stimulus_fatigue': 'Effet par rapport à la fatigue',
  'preferences': 'Tes goûts',
  'novelty': 'Nouveautés dosées',
};

/// Pourquoi une composante qui progresse fait bouger un exercice (diff).
const kScoreWhy = <String, String>{
  'recovery':
      'pour laisser au moins 48 h entre deux séances lourdes des mêmes muscles',
  'fatigue_balance': 'pour mieux répartir la fatigue sur la semaine',
  'joint_load': 'pour ménager tes articulations',
  'goal_specificity': 'pour mieux servir tes objectifs',
  'discipline_dosage': 'pour garder le dosage de tes disciplines',
  'muscle_volume': 'pour garder le bon volume sur chaque muscle',
  'pattern_balance': 'pour garder l’équilibre poussée / tirage et jambes',
  'discipline_structure': 'pour garder la structure de ta discipline',
  'time_use': 'pour tenir dans ton temps disponible',
  'variety': 'pour éviter deux exercices trop proches',
  'exercise_fit': 'pour des exercices adaptés à ton niveau',
  'stimulus_fatigue': 'pour plus d’effet avec moins de fatigue',
  'preferences': 'pour garder ce que tu aimes',
  'novelty': 'pour ne pas apprendre trop de nouveaux gestes à la fois',
};

/// Rendu d'une raison de kalis_plan. [exerciseName] et [goalLabel] donnent
/// les noms ; un code inconnu donne un texte générique.
String reasonText(
  kc.Reason r, {
  required String Function(String id) exerciseName,
  String Function(String goalId)? goalLabel,
}) {
  final p = r.params;
  String s(String k) => '${p[k] ?? ''}';
  num n(String k) => (p[k] is num) ? p[k] as num : 0;
  String one(num v) {
    final t = (v * 10).round() / 10;
    return t == t.roundToDouble()
        ? t.toInt().toString()
        : t.toString().replaceAll('.', ',');
  }

  switch (r.code) {
    case 'plan.discipline_share':
      return '${disciplineCodeLabel(s('discipline'))} : ${n('pct')} % de ton '
          'temps, comme dans ton profil.';
    case 'plan.movement_coverage':
      return 'Couvre un mouvement de base qui manquait.';
    case 'plan.muscle_volume':
      return 'Travaille les ${kMuscleGroupLabels[s('muscle')] ?? s('muscle')} : '
          '${one(n('weeklySets'))} séries par semaine, repère '
          '${one(n('targetLow'))} à ${one(n('targetHigh'))}.';
    case 'plan.fatigue_balance':
      return 'Répartit la fatigue entre tes séances.';
    case 'plan.time_budget':
      return 'Tient dans tes ${n('minutes')} min de ce jour-là.';
    case 'plan.equipment_available':
      return 'Faisable avec ton matériel, à ${placeLabel(s('place'))}.';
    case 'plan.equipment_missing':
      return 'Écarté : il manque du matériel.';
    case 'plan.level_match':
      return 'Difficulté ${n('difficulty')} sur 10, adaptée à ton niveau.';
    case 'plan.prerequisite_missing':
      return 'Écarté : il faut d’abord maîtriser '
          '${exerciseName(s('exerciseId'))}.';
    case 'plan.joint_limitation':
      return 'Ménage ton ${jointLabel(s('joint'))} (gêne ${n('discomfort')}/10).';
    case 'plan.user_likes':
      return 'Tu aimes cet exercice.';
    case 'plan.user_dislikes':
      return 'Tu n’aimes pas cet exercice : je l’ai retiré.';
    case 'plan.user_cannot_do':
      return 'Tu ne sais pas encore le faire : je l’ai remplacé.';
    case 'plan.user_added':
      return 'Ajouté à ta demande.';
    case 'plan.user_removed':
      return 'Retiré à ta demande.';
    case 'plan.user_replaced':
      return 'Variante que tu as choisie.';
    case 'plan.lock_kept':
      return 'Validé par toi : il ne bouge plus.';
    case 'plan.goal_support':
      final g = goalLabel?.call(s('goalId'));
      return g == null || g.isEmpty
          ? 'Sert un de tes objectifs.'
          : 'Sert ton objectif : $g.';
    case 'plan.variety':
      return 'Change un peu pour varier.';
    case 'plan.reoptimized':
      return 'Le reste du programme a été réajusté autour de ton changement.';
    case 'plan.variant_easier':
      return 'Plus facile (${n('difficultyDelta').abs()} palier'
          '${n('difficultyDelta').abs() > 1 ? 's' : ''} de moins).';
    case 'plan.variant_equivalent':
      return 'Équivalent : mêmes muscles, même difficulté.';
    case 'plan.variant_other_equipment':
      return 'Avec un autre matériel.';
    case 'plan.start_load_conservative':
      return 'Charge de départ prudente : je la cale avec tes flammes.';
    case 'plan.to_calibrate':
      return 'Charge à calibrer sur tes 2-3 premières séances.';
    case 'plan.week_kind':
      for (final k in kc.WeekKind.values) {
        if (k.code == s('kind')) return kWeekKindHints[k]!;
      }
      return 'Logique de la semaine.';
    case 'plan.progression_from_previous_block':
      return 'Reprend ou fait progresser ${exerciseName(s('exerciseId'))} '
          'du bloc précédent.';
    case 'plan.adaptation_applied':
      return 'Tient compte de ce que tes séances ont montré.';
    case 'plan.cautious_health':
      return 'Programme prudent, d’après ton questionnaire santé.';
    case 'plan.restructure_scope':
      return 'Changement limité à une partie du programme.';
  }
  // CU : codes ajoutés par kalis_core 0.4.0.
  return reasonText04(r.code, p, exerciseName) ?? 'Choix du moteur.';
}

/// Raison la plus parlante d'un emplacement (hors raisons générales).
kc.Reason? mainReason(List<kc.Reason> reasons) {
  const order = [
    'plan.user_added',
    'plan.user_replaced',
    'plan.user_likes',
    'plan.lock_kept',
    'plan.goal_support',
    'plan.joint_limitation',
    'plan.muscle_volume',
    'plan.movement_coverage',
    'plan.discipline_share',
    'plan.level_match',
  ];
  for (final code in order) {
    for (final r in reasons) {
      if (r.code == code) return r;
    }
  }
  return reasons.isEmpty ? null : reasons.first;
}

/// Composante de la note qui a le plus progressé entre deux programmes
/// (poids × écart), pour dire pourquoi le reste a bougé ; null si rien ne
/// progresse.
String? improvedComponent(kc.PlanScore before, kc.PlanScore after) {
  final b = {for (final c in before.components) c.code: c.value};
  String? best;
  var gain = 1e-4;
  for (final c in after.components) {
    final d = (c.value - (b[c.code] ?? c.value)) * c.weight;
    if (d > gain) {
      gain = d;
      best = c.code;
    }
  }
  return best;
}

/// « 3 × 8-12 », « 3 × 20-30 s », « 20-30 min », « 4 × 400 m ».
String prescriptionLabel(kc.ExercisePrescription p) {
  final sets = p.sets;
  String range(int a, int b) => a == b ? '$a' : '$a-$b';
  if (p.repsLow != null && p.repsHigh != null) {
    return '$sets × ${range(p.repsLow!, p.repsHigh!)}';
  }
  if (p.secondsLow != null && p.secondsHigh != null) {
    final lo = p.secondsLow!, hi = p.secondsHigh!;
    if (sets == 1 && lo >= 300 && lo % 60 == 0 && hi % 60 == 0) {
      return '${range(lo ~/ 60, hi ~/ 60)} min';
    }
    return '$sets × ${range(lo, hi)} s';
  }
  if (p.distanceMeters != null) {
    final m = p.distanceMeters!.round();
    return '$sets × $m m';
  }
  if (p.calories != null) return '$sets × ${p.calories!.round()} cal';
  return '$sets série${sets > 1 ? 's' : ''}';
}

/// « 2 min », « 90 s », « libre ».
String restLabel(int? seconds) {
  if (seconds == null) return 'libre';
  if (seconds == 0) return 'enchaîné';
  if (seconds % 60 == 0) return '${seconds ~/ 60} min';
  if (seconds > 60) return '${seconds ~/ 60} min ${seconds % 60} s';
  return '$seconds s';
}

/// Charge de départ lisible (convention externe du contrat).
String? loadLabel(kc.ExercisePrescription p) {
  final kg = p.startLoadKg;
  if (kg == null) {
    if (p.percentOfOneRm != null && p.percentOfOneRm! > 0) {
      return 'repère ${(p.percentOfOneRm! * 100).round()} % de ton max';
    }
    return null;
  }
  final t = kg == kg.roundToDouble()
      ? kg.toInt().toString()
      : kg
            .toStringAsFixed(2)
            .replaceAll(RegExp(r'0+$'), '')
            .replaceAll('.', ',');
  return switch (p.loadBasis) {
    kc.LoadBasis.bodyweightPlusExternal =>
      kg == 0 ? 'poids du corps' : '+ $t kg de lest',
    kc.LoadBasis.bodyweight => 'poids du corps',
    _ => '$t kg',
  };
}
