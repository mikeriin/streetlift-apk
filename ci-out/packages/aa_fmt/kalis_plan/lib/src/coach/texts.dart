/// Textes français des raisons du chemin street : ce que l'athlète lit
/// sous un exercice ou en tête de bloc. Une raison sans texte propre rend
/// `null` (le texte générique de `kalis_core` s'applique).
library;

import 'package:kalis_core/kalis_core.dart';

import 'prescribe.dart';

String _pct(Object? v) => v is num ? '${(v * 100).round()} %' : '';

String _int(Object? v) => v is num ? '${v.round()}' : '';

String _plain(Object? v) {
  if (v is! num) {
    return '';
  }
  return v == v.roundToDouble()
      ? '${v.round()}'
      : v.toString().replaceAll('.', ',');
}

/// Nom français d'une zone du corps.
String coachZoneLabel(String code) => switch (code) {
  'neck' => 'cou',
  'shoulder' => 'épaule',
  'elbow' => 'coude',
  'wrist_hand' => 'poignet et main',
  'upper_back' => 'haut du dos',
  'lower_back' => 'bas du dos',
  'chest' => 'poitrine',
  'hip' => 'hanche',
  'knee' => 'genou',
  'ankle_foot' => 'cheville et pied',
  _ => code.replaceAll('_', ' '),
};

/// Nom français d'une phase de saison.
String coachPhaseLabel(String code) => switch (code) {
  'accumulation' => 'accumulation (volume)',
  'intensification' => 'intensification (charges lourdes)',
  'realization' => 'réalisation (pic de forme)',
  'taper' => 'affûtage',
  'competition' => 'échéance',
  'transition' => 'transition (récupération)',
  'test' => 'test',
  'deload' => 'allègement',
  'maintenance' => 'entretien',
  'reintroduction' => 'reprise progressive',
  'intro' => 'introduction',
  _ => code,
};

/// Nom français d'un point faible.
String coachWeakPointLabel(String code) => switch (code) {
  'bottom' => 'bas du mouvement',
  'mid_range' => 'milieu du mouvement',
  'lockout' => 'verrouillage',
  'dead_start' => 'départ bras tendus',
  'transition' => 'transition',
  'grip' => 'prise',
  'late_set_fatigue' => 'fin de série',
  'balance' => 'équilibre',
  'mobility' => 'mobilité',
  'speed' => 'vitesse',
  _ => code.replaceAll('_', ' '),
};

String _since(String code) => switch (code) {
  'under_6_weeks' => 'moins de 6 semaines',
  'weeks_6_to_12' => '6 à 12 semaines',
  'months_3_to_12' => '3 à 12 mois',
  'over_12_months' => 'plus de 12 mois',
  'past_resolved' => 'ancien, sans gêne',
  _ => code.replaceAll('_', ' '),
};

String _gap(String code) => switch (code) {
  'reduced' => 'entraînement allégé',
  'under_3_weeks' => 'moins de 3 semaines',
  'weeks_3_to_10' => '3 à 10 semaines',
  'weeks_10_to_26' => '10 à 26 semaines',
  'months_6_to_24' => '6 mois à 2 ans',
  'over_2_years' => 'plus de 2 ans',
  _ => code.replaceAll('_', ' '),
};

String _band(String code) => switch (code) {
  'under_6_months' => 'moins de 6 mois',
  'months_6_to_24' => '6 mois à 2 ans',
  'years_2_to_5' => '2 à 5 ans',
  'over_5_years' => 'plus de 5 ans',
  _ => code.replaceAll('_', ' '),
};

String _sport(String code) => switch (code) {
  'running' => 'course à pied',
  'cycling' => 'vélo',
  'swimming' => 'natation',
  'other_endurance' => 'endurance',
  'team_sport' => 'sport collectif',
  'combat_sport' => 'sport de combat',
  'climbing' => 'escalade',
  'racket_sport' => 'sport de raquette',
  'other_strength' => 'autre sport de force',
  _ => 'autre sport',
};

/// Texte français de la raison [r] du chemin street, ou `null`.
String? coachReasonText(Reason r, Catalog catalog) {
  final p = r.params;
  String name(Object? id) => id is String ? (catalog.find(id)?.name ?? id) : '';
  switch (r.code) {
    case ReasonCodes.planCoachNote:
      final v = p['value'];
      return switch (p['note']) {
        CoachNotes.restBeforeEvent =>
          "Repos avant l'échéance : mobilité et préparation articulaire "
              'seulement, rien de fatigant dans les 2 à 4 derniers jours.',
        CoachNotes.badDay =>
          'Baisse du jour (nuit de moins de 6 h, courbatures marquées sur '
              'la zone, journée très stressante) : ${_int(v)} série de moins '
              'par exercice, aucune série à moins de 3 répétitions en '
              'réserve, pas de test.',
        CoachNotes.missed =>
          'Séance manquée : elle ne se rattrape pas. Semaine manquée : '
              'refais la dernière semaine terminée. Deux semaines ou plus : '
              'reprends deux semaines en arrière avec ${_int(v)} % de volume '
              'en moins.',
        CoachNotes.checkpoint =>
          "Repère sur le chemin de l'objectif : ${_plain(v)}. "
              "S'il n'est pas atteint, garde les volumes du bloc au lieu de "
              'les durcir.',
        CoachNotes.testRest =>
          '${_int(v)} h sans travail dur du mouvement avant un test.',
        CoachNotes.rampBodyweight =>
          'Avant la série de tête : ${_int(v)} séries faciles (un tiers, '
              'puis la moitié des répétitions prévues).',
        CoachNotes.loadAdjust =>
          'Ajustement des charges : si la série de tête laisse moins de '
              'réserve que prévu, baisse les séries suivantes de 2,5 à 5 % ; '
              'si elle en laisse au moins deux de plus, ajoute le plus petit '
              'pas la semaine suivante.',
        CoachNotes.repsAdjust =>
          'Ajustement des répétitions : si les répétitions prévues ne '
              'passent pas avec la réserve demandée, garde les mêmes chiffres '
              'la semaine suivante ; ${_int(v)} séances de suite en dessous, '
              'retire une série.',
        CoachNotes.testUse =>
          'Les tests de fin de bloc (ou de la semaine de test) recalent '
              'les charges et les répétitions du bloc suivant.',
        CoachNotes.eventRehearsal =>
          "Répétition de l'épreuve : une série longue par atelier, dans "
              "l'ordre de l'épreuve, ${_int(v)} s de repos entre les "
              'ateliers.',
        CoachNotes.rolePrehab =>
          'Prévention : coiffe et fixateurs des omoplates, pour encaisser '
              'le volume de tirage et de poussée.',
        CoachNotes.roleRow =>
          'Tirage horizontal : équilibre des épaules face à la poussée et '
              'au tirage vertical.',
        CoachNotes.rolePosterior =>
          'Chaîne postérieure : ischio-jambiers et fessiers, entretien du '
              'bas du corps.',
        CoachNotes.roleLegs => 'Jambes : force utile, sans fatigue excessive.',
        CoachNotes.roleCore =>
          'Tronc : le gainage qui tient la position à la barre.',
        CoachNotes.roleElbow =>
          'Fléchisseurs du coude en charge légère : tolérance du coude au '
              'tirage lourd.',
        CoachNotes.rampWarmup =>
          'Montée en charge : ${_int(v)} séries progressives (environ 40 %, '
              '60 % puis 75 à 80 % de la charge du jour) avant la série de '
              'tête.',
        CoachNotes.topSetBackoff =>
          'Une série de tête, puis des séries allégées de ${_int(v)} % '
              '(charge totale, poids du corps compris).',
        CoachNotes.speedWork =>
          'Séance légère à ${_pct(v)} du 1RM : chaque répétition rapide et '
              "propre, très loin de l'échec.",
        CoachNotes.attemptsPlan =>
          'Trois tentatives : ${_pct(v)} du 1RM, puis 96 %, puis la '
              'troisième selon la vitesse de la deuxième (99 à 102 %).',
        CoachNotes.opener =>
          "Dernier rappel lourd avant l'échéance : ${_pct(v)} du 1RM, une "
              'seule série de tête, sans forcer.',
        CoachNotes.maintenance =>
          'En entretien pendant la spécialisation : volume réduit, charge '
              'gardée.',
        CoachNotes.everyMinute =>
          'Départs au chrono : une série toutes les ${_int(v)} s ; si les '
              'répétitions ne passent plus, arrête là.',
        CoachNotes.qualityFirst =>
          'À faire frais, en début de séance ; arrête dès que la qualité '
              'passe sous ${_int(v)} sur 5.',
        CoachNotes.submaximalHold =>
          'Tenues à ${_pct(v)} de ton maintien maximal : chaque tenue reste '
              'propre, bassin et épaules placés.',
        CoachNotes.slowNegative =>
          'Descente freinée en ${_int(v)} s, sans à-coup ; arrête dès que tu '
              'ne contrôles plus la descente.',
        CoachNotes.eventDay =>
          v is num && v > 0
              ? "Séance de l'échéance (elle a lieu ${_int(v)} jour(s) plus "
                    'tard : cale cette séance sur le jour réel).'
              : "Jour de l'échéance.",
        CoachNotes.recovery =>
          'Récupération : facile, sans chercher la performance.',
        CoachNotes.calibrate =>
          'Charge à régler à la première séance : monte par paliers '
              "jusqu'à une série qui laisse ${_int(v)} répétitions en "
              'réserve.',
        CoachNotes.superset =>
          "Enchaîné avec l'exercice suivant ; ${_int(v)} s de repos entre "
              'les tours.',
        CoachNotes.easyPace =>
          'Allure de conversation (tu peux parler en phrases), '
              '${_int(v)} min.',
        CoachNotes.generalWarmup =>
          "Chaque séance commence par ${_int(v)} min d'échauffement : "
              'épaules, poignets et hanches en mobilité, 2 × 8 tirages '
              'scapulaires, 2 × 8 pompes scapulaires, puis quelques '
              'répétitions faciles du premier mouvement.',
        CoachNotes.toleranceVolume =>
          'Volume réglé à ${_pct(v)} du volume type de ton niveau, au vu de '
              'ta récupération.',
        _ => null,
      };
    case ReasonCodes.planProgressionRule:
      final step = p['step'];
      return switch (p['rule']) {
        CoachRules.doubleProgression =>
          'Progression : quand toutes les séries atteignent le haut de la '
              'plage avec la réserve prévue, passe à la variante ou à la '
              'charge suivante et repars du bas de la plage.',
        CoachRules.loadStep =>
          'Progression : la charge monte d\'environ '
              '${step is num ? step.toString().replaceAll('.', ',') : ''} % '
              'du 1RM par semaine si la réserve prévue est tenue ; sinon '
              'garde la charge.',
        CoachRules.repStep =>
          'Progression : ${_int(step)} répétition de plus par semaine tant '
              'que la réserve prévue est tenue.',
        CoachRules.holdStep =>
          'Progression : +${_int(step)} s par tenue quand toutes les tenues '
              "sont propres ; l'étape suivante quand le critère de passage "
              'est atteint.',
        CoachRules.densityStep =>
          'Progression : une minute de plus par semaine, puis une '
              'répétition de plus par minute.',
        CoachRules.durationStep =>
          'Progression : durée +${_int(step)} % par semaine au plus.',
        _ => null,
      };
    case ReasonCodes.planPainRule:
      final zone = p['zone'];
      return 'Douleur (${zone is String ? coachZoneLabel(zone) : ''}) : '
          "de 0 à 2 sur 10, continue ; à ${_int(p['continueBelow'])} ou "
          "${_int(p['regressAt'])}, finis la séance sans progresser et "
          "n'ajoute rien la semaine suivante ; à 5, prends la variante plus "
          'facile et retire 30 à 50 % du volume de la zone ; à '
          "${_int(p['stopAt'])} ou plus, douleur la nuit, perte de force ou "
          'gêne qui dure deux semaines : arrête le mouvement et consulte un '
          'professionnel de santé. Le programme ne pose aucun diagnostic.';
    case ReasonCodes.planWeakPoint:
      final kind = p['kind'];
      return 'Cible ton point faible '
          '(${kind is String ? coachWeakPointLabel(kind) : ''}) sur : '
          '${name(p['exerciseId'])}.';
    case ReasonCodes.planTestScheduled:
      return switch (p['testKind']) {
        'one_rm' => 'Test : 1RM en trois tentatives.',
        'rep_max' =>
          "Test : monte par paliers jusqu'à une série lourde qui garde "
              '1 répétition en réserve ; elle estime ton 1RM sans le risque '
              "d'un maximum.",
        'max_reps' =>
          'Test : une seule série maximale, arrêt dès que la forme casse.',
        'max_hold' =>
          'Test : un maintien maximal, arrêt dès que la position se '
              'dégrade.',
        _ => 'Test.',
      };
    case ReasonCodes.planEventSpecific:
      return "Au format de l'échéance.";
    case ReasonCodes.planTaper:
      return 'Affûtage : volume réduit à ${_pct(p['volumeFactor'])} du '
          "volume de pointe, intensité gardée, à ${_int(p['daysToEvent'])} "
          "jours de l'échéance au plus.";
    case ReasonCodes.planToCalibrate:
      return 'Charge à calibrer à la première séance.';
    case ReasonCodes.planSeasonPhase:
      final phase = p['phase'];
      final weeks = p['weeksToEvent'];
      return 'Phase du bloc : '
          '${phase is String ? coachPhaseLabel(phase) : ''}'
          '${weeks is int && weeks > 0 ? " ; l'échéance est dans $weeks semaine(s)" : ''}.';
    case ReasonCodes.planPeakEvent:
      return "Les blocs sont calés à rebours sur l'échéance : le dernier "
          'finit sur elle.';
    case ReasonCodes.planTrainingAge:
      final band = p['band'];
      return "Ancienneté d'entraînement prise en compte : "
          '${band is String ? _band(band) : ''}.';
    case ReasonCodes.planReturnFromGap:
      final gap = p['gap'];
      return 'Reprise après une coupure (${gap is String ? _gap(gap) : ''}) '
          ': volume réduit de moitié et au moins 3 répétitions en réserve '
          'la première semaine, puis retour progressif ; tes anciens '
          'records ne sont pas des charges de travail.';
    case ReasonCodes.planRecoveryProfile:
      return switch (p['factor']) {
        'sleep' =>
          'Sommeil court : volume réduit de 15 %, une répétition en '
              'réserve de plus, pas de hausse de volume tant que le '
              'sommeil ne remonte pas.',
        'stress' =>
          'Stress élevé : volume réduit de 10 %, une répétition en réserve '
              'de plus.',
        'occupational_load' =>
          'Travail physique : volume de tirage, de préhension et de jambes '
              'réduit de 15 %.',
        'age' =>
          p['level'] == '60_plus'
              ? 'À 60 ans et plus : volume réduit de 20 %, progression du '
                    'volume deux fois plus lente.'
              : 'À 40 ans et plus : progression du volume deux fois plus '
                    'lente (+10 % par semaine au plus).',
        _ => null,
      };
    case ReasonCodes.planConcurrentSport:
      final sport = p['sport'];
      return '${sport is String ? _sport(sport) : ''} '
          '(${_int(p['sessions'])} séance(s) par semaine) : pris en compte '
          'dans le volume des jambes et le placement des séances.';
    case ReasonCodes.planSpecialization:
      return 'Spécialisation : ${name(p['target'])} monte en fréquence et '
          'en volume, le reste passe en entretien (charge gardée, volume '
          'réduit) pendant ${_int(p['weeks'])} semaines.';
    case ReasonCodes.planConstraintHistory:
      final zone = p['zone'];
      final since = p['since'];
      return 'Antécédent (${zone is String ? coachZoneLabel(zone) : ''}, '
          '${since is String ? _since(since) : ''}) : charge graduée sur la '
          "zone, pas d'échec, pas d'excentrique accentué.";
    case ReasonCodes.planSkillStep:
      return "Figure : travail à l'étape « ${name(p['exerciseId'])} ».";
    case ReasonCodes.planCautiousHealth:
      return 'Mode prudent (questionnaire santé) : intensité modérée, pas '
          "d'impact.";
    default:
      return null;
  }
}
