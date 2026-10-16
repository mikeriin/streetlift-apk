// KS1A (dev7.1.0, pipeline CP, DECISIONS_CP.md C17.20) — types de jour de
// `kalis_core` 0.4.4 (`PlanDay.type` : schémas de mouvement, qualité visée,
// charge) dans l'application.
//
// - Libellés (LIVRAISON_KS1.md § 6.1) : « Tirage — force », « Jambes —
//   endurance de force ». Lecture seule : aucune règle d'entraînement ici.
// - Programme importé (programme de 40 semaines du propriétaire, ancien
//   programme L10, semaines d'avant un programme créé) : type déduit du
//   titre écrit de la journée, à la lecture (le programme d'origine n'est
//   jamais réécrit). J1 à J3 force, J4 et J5 endurance de force, J6
//   puissance ; journées de test, de récupération et de mobilité d'après
//   leur titre. Le même `DayType` annote les journées des blocs importés
//   (imported_program.dart).
import 'package:kalis_core/kalis_core.dart' as kc;

import '../search.dart' show normalizeText;

/// Schéma de mouvement d'un jour, avec majuscule (début de libellé).
const kDayPatternLabels = <kc.DayPattern, String>{
  kc.DayPattern.pull: 'Tirage',
  kc.DayPattern.push: 'Poussée',
  kc.DayPattern.legs: 'Jambes',
  kc.DayPattern.full: 'Corps entier',
  kc.DayPattern.skill: 'Figures',
  kc.DayPattern.run: 'Course',
  kc.DayPattern.recovery: 'Récupération',
};

/// Qualité visée par un jour (après le tiret).
const kDayQualityLabels = <kc.DayQuality, String>{
  kc.DayQuality.force: 'force',
  kc.DayQuality.volume: 'volume',
  kc.DayQuality.endurance: 'endurance de force',
  kc.DayQuality.power: 'puissance',
  kc.DayQuality.skill: 'technique',
  kc.DayQuality.conditioning: 'conditionnement',
  kc.DayQuality.run: 'course',
  kc.DayQuality.recovery: 'récupération',
};

/// Libellé d'un type de jour : schémas (« Tirage », « Figures + tirage »)
/// et qualité (« — force ») ; la qualité est omise quand elle redit le
/// schéma (« Récupération », « Course »). Null sans type.
String? dayTypeLabel(kc.DayType? type) {
  if (type == null || type.patterns.isEmpty) return null;
  final names = <String>[];
  for (final p in type.patterns) {
    final l = kDayPatternLabels[p];
    if (l != null && !names.contains(l)) names.add(l);
  }
  if (names.isEmpty) return null;
  final patterns = [
    names.first,
    for (final n in names.skip(1)) n.toLowerCase(),
  ].join(' + ');
  final quality = kDayQualityLabels[type.quality];
  if (quality == null || quality == names.first.toLowerCase()) {
    return patterns;
  }
  return '$patterns — $quality';
}

/// Libellé d'un code de schéma ou d'une liste de codes (« pull+legs »,
/// « pull, legs ») en minuscules, pour les raisons ; le code tel quel s'il
/// est inconnu.
String dayPatternsText(String codes) {
  final out = <String>[];
  for (final c in codes.split(RegExp(r'[^a-z_]+'))) {
    if (c.isEmpty) continue;
    final p = kc.DayPattern.values.where((v) => v.code == c).firstOrNull;
    final l = p == null ? c.replaceAll('_', ' ') : kDayPatternLabels[p]!;
    if (!out.contains(l.toLowerCase())) out.add(l.toLowerCase());
  }
  return out.isEmpty ? codes : out.join(' + ');
}

/// Libellé d'un code de qualité ; le code tel quel s'il est inconnu.
String dayQualityText(String code) {
  final q = kc.DayQuality.values.where((v) => v.code == code).firstOrNull;
  return q == null ? code.replaceAll('_', ' ') : kDayQualityLabels[q]!;
}

/// Gabarit de semaine (`SplitChoice.templateId` de `kalis_plan` 0.4),
/// en clair, pour « Semaine construite en … ».
String splitTemplateText(String id) => switch (id) {
  'ppl6_q' => 'tirage, poussée, jambes, deux fois',
  'pp_l5' => 'tirage, poussée, deux fois, puis jambes',
  'ul4' => 'haut, bas, deux fois',
  'fb3' || 'fb2' || 'fb_beginner' => 'corps entier',
  'mix_q' => 'jours de force et jours d’endurance de force',
  'lift_dup' || 'power_dup' => 'jours lourds, moyens et légers',
  'reps_pillars' => 'séances de répétitions',
  'figures' => 'séances de figures',
  'gym_split' => 'groupes musculaires',
  'run_week' => 'semaine de course',
  'wod_week' => 'semaine de WOD',
  'health_week' => 'semaine santé',
  _ => 'semaine type',
};

// --------------------------------------------- programme importé (C11)

/// Type de jour d'une journée importée d'après son titre écrit et son
/// numéro [j] (1 = J1) ; null : journée sans exercice, ou titre sans
/// schéma reconnu (rien n'est affiché).
///
/// Schémas : tirage (traction, muscle-up, « MU »), poussée (dip, pompe),
/// jambes (squat), figures (« skill ») ; deux schémas chargés ou plus :
/// corps entier, comme `kalis_plan` (`coachDerivedType`). Récupération,
/// repos actif et mobilité : récupération. Qualité : test de 1RM → force,
/// test de maximum → endurance de force, « puissance » → puissance,
/// « endurance » → endurance de force, « lourd » → force ; sinon d'après
/// le jour (J1 à J3 force, J4 et J5 endurance de force, J6 puissance).
kc.DayType? importedDayType(String title, int j, {bool training = true}) {
  if (!training) return null;
  final t = ' ${normalizeText(title)} ';
  bool has(String w) => t.contains(' $w ');
  bool part(String w) => t.contains(w);
  if (has('repos') ||
      part('recuperation') ||
      (part('mobilite') &&
          !part('squat') &&
          !part('traction') &&
          !part('dip'))) {
    return const kc.DayType(
      patterns: [kc.DayPattern.recovery],
      quality: kc.DayQuality.recovery,
      stress: kc.DayStress.light,
    );
  }
  // Schémas dans l'ordre où le titre les nomme.
  final found = <(int, kc.DayPattern)>[];
  void find(kc.DayPattern p, List<String> words) {
    var at = -1;
    for (final w in words) {
      final i = t.indexOf(w);
      if (i >= 0 && (at < 0 || i < at)) at = i;
    }
    if (at >= 0) found.add((at, p));
  }

  find(kc.DayPattern.skill, [' skill ', ' figure']);
  find(kc.DayPattern.pull, [
    'tirage',
    'traction',
    'muscle-up',
    'muscle up',
    ' mu ',
    'rowing',
  ]);
  find(kc.DayPattern.push, [' dip', 'pompe', 'poussee', 'developpe']);
  find(kc.DayPattern.legs, ['squat', 'jambe', 'souleve']);
  if (found.isEmpty) return null;
  found.sort((a, b) => a.$1.compareTo(b.$1));
  var patterns = [for (final f in found) f.$2];
  const loaded = {kc.DayPattern.pull, kc.DayPattern.push, kc.DayPattern.legs};
  if (patterns.where(loaded.contains).length >= 2) {
    patterns = [
      for (final p in patterns)
        if (!loaded.contains(p)) p,
    ];
    patterns.add(kc.DayPattern.full);
  }
  final kc.DayQuality quality;
  final kc.DayStress stress;
  if (part('test') && part('1rm')) {
    quality = kc.DayQuality.force;
    stress = kc.DayStress.heavy;
  } else if (part('test') && part('max')) {
    quality = kc.DayQuality.endurance;
    stress = kc.DayStress.heavy;
  } else if (part('puissance') || part('explosi')) {
    quality = kc.DayQuality.power;
    stress = kc.DayStress.medium;
  } else if (part('endurance')) {
    quality = kc.DayQuality.endurance;
    stress = kc.DayStress.medium;
  } else if (part('lourd') || part('force')) {
    quality = kc.DayQuality.force;
    stress = kc.DayStress.heavy;
  } else if (j >= 1 && j <= 3) {
    quality = kc.DayQuality.force;
    stress = kc.DayStress.heavy;
  } else if (j == 4 || j == 5) {
    quality = kc.DayQuality.endurance;
    stress = kc.DayStress.medium;
  } else if (j == 6) {
    quality = kc.DayQuality.power;
    stress = kc.DayStress.medium;
  } else {
    return null;
  }
  return kc.DayType(patterns: patterns, quality: quality, stress: stress);
}
