// CU (dev6.8.0) : textes de Koach des codes de raison ajoutés par
// `kalis_core` 0.4.0 (`packages/kalis_core/data/reason_texts_fr_0_4.json`,
// `docs/RAISONS_0_4.md`), recopiés tels quels. Les moteurs actuels
// (`kalis_plan` 0.1, `kalis_adapt` 0.1) ne les émettent pas : rendu
// générique ({paramètre} → valeur) en attendant le lot CI, qui les rendra
// avec les libellés de l'application. Test : test/cu_profil_v3_test.dart.

/// Code de raison → modèle de phrase ({paramètre}).
const kReasonTexts04 = <String, String>{
  'plan.season_phase':
      'On est en phase « {phase} », à {weeksToEvent} semaines de ton échéance.',
  'plan.taper':
      'Affûtage : moins de volume, mêmes charges. Tu arrives frais dans {daysToEvent} jours.',
  'plan.peak_event':
      'Toute ta saison est construite pour être en forme ce jour-là.',
  'plan.undulation':
      "Aujourd'hui, c'est un jour {stress} : on alterne lourd, moyen et léger dans la semaine.",
  'plan.technique':
      'Technique du jour : {technique}.',
  'plan.technique_withheld':
      'Je garde la technique « {technique} » pour plus tard : pas encore le bon moment ({cause}).',
  'plan.specialization':
      'Priorité à ta cible pendant {weeks} semaines ; le reste est entretenu.',
  'plan.maintenance_volume':
      "Volume d'entretien pour ce groupe : juste ce qu'il faut pour ne rien perdre.",
  'plan.skill_step':
      "C'est ton étape actuelle sur cette figure.",
  'plan.skill_plateau':
      "Tu es à cette étape depuis longtemps : je change d'approche sur cette figure.",
  'plan.recent_load':
      'Premier bloc calé sur ce que tu fais en ce moment : ni trop facile, ni marche trop haute.',
  'plan.test_scheduled':
      'Un test est prévu : il me dira où tu en es vraiment.',
  'plan.benchmark_used':
      "Charge calculée d'après ton test ou ton record.",
  'plan.percent_based':
      'Charge réglée sur une part de ton maximum.',
  'plan.recovery_profile':
      'Je tiens compte de ta récupération ({factor}).',
  'plan.constraint_history':
      "Zone à ménager : j'avance plus doucement sur les mouvements qui la chargent.",
  'plan.concurrent_sport':
      'Tu fais aussi un autre sport : je place tes séances lourdes à distance.',
  'plan.training_age':
      "Volume et rythme réglés sur ton ancienneté d'entraînement.",
  'plan.return_from_gap':
      'Tu reprends après une coupure : on repart progressivement.',
  'plan.weak_point':
      'Exercice choisi pour travailler là où tu bloques.',
  'plan.event_specific':
      'Travail spécifique de ton épreuve.',
  'adapt.backoff_from_top_set':
      "Séries allégées calculées sur ta série de tête d'aujourd'hui.",
  'adapt.rir_cap':
      'Je baisse un peu la charge pour que tu gardes de la réserve.',
  'adapt.test_result':
      'Test enregistré : ton estimation est à jour.',
  'adapt.skill_step_up':
      "Critère tenu : tu passes à l'étape suivante.",
  'adapt.skill_step_down':
      "Aujourd'hui, on revient une étape en dessous pour rester propre.",
  'adapt.skill_hold':
      'On reste à cette étape : tes tendons ont besoin de temps.',
  'adapt.phase_respected':
      "Je respecte l'intention de la phase en cours.",
  'adapt.taper_no_volume':
      "Affûtage : je n'ajoute rien, on garde les charges.",
  'adapt.event_near':
      'Ton échéance est dans {days} jours : je reste prudent.',
  'adapt.attempt_opener':
      'Ouverture : une barre sûre, pour entrer dans la compétition.',
  'adapt.attempt_next':
      "Tentative suivante choisie d'après la précédente.",
  'adapt.attempt_conservative':
      'Je propose une barre prudente ({cause}).',
  'adapt.pacing':
      'Rythme conseillé pour viser {targetReps} répétitions.',
  'adapt.recovery_profile':
      'Je tiens compte de ta récupération ({factor}).',
  'adapt.tendon_load':
      'Je surveille la charge de tes tendons : progression ralentie sur ces appuis.',
  'adapt.technique_executed':
      'Technique « {technique} » faite comme prévu.',
  'adapt.mini_set_stop':
      'On arrête les mini-séries ici ({cause}).',
};

/// Phrase d'un code de 0.4.0 ([params] : paramètres de la raison ;
/// [exerciseName] : nom d'un exercice) ; null si le code n'est pas de 0.4.0.
String? reasonText04(
  String code,
  Map<String, Object?> params,
  String Function(String id) exerciseName,
) {
  final t = kReasonTexts04[code];
  if (t == null) return null;
  return t.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) {
    final k = m.group(1)!;
    final v = params[k];
    if (v == null) return '…';
    if (v is String && k.toLowerCase().endsWith('exerciseid')) {
      return exerciseName(v);
    }
    if (v is num) {
      final r = (v * 10).round() / 10;
      return r == r.roundToDouble()
          ? r.toInt().toString()
          : r.toString().replaceAll('.', ',');
    }
    return '$v';
  });
}
