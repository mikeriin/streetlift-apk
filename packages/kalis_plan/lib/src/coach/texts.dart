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
  'accumulation' => 'construction (volume)',
  'intensification' => 'intensification (séries plus dures)',
  'realization' => "réalisation (spécifique à l'objectif)",
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
        CoachNotes.negativeGate =>
          'Test : la descente la plus lente possible, deux essais. Si elle '
              'dure ${_int(v)} s ou plus sans à-coup, tente une traction '
              'stricte au début de la séance suivante ; si elle passe, '
              "déclare-la dans l'application : le programme passera aux "
              'tractions.',
        CoachNotes.strictAttempt =>
          'Puis ton test : après 3 min de repos, essaie la traction '
              'stricte — départ bras tendus, menton au-dessus de la barre, '
              'sans élan — une seule série, autant de répétitions propres '
              "que possible (objectif : ${_int(v)}). Si elle passe, "
              "déclare-la dans l'application.",
        CoachNotes.bodyweightFloor =>
          'La charge visée tombe sous ton poids de corps : série sans '
              'lest, à ${_pct(v)} de ton 1RM (poids du corps compris), '
              'avec moins de répétitions pour garder la réserve.',
        CoachNotes.overload =>
          'Amplitude partielle surchargée : ${_pct(v)} de ton 1RM complet, '
              'sur la seule fin du mouvement, en butée ou avec parade.',
        CoachNotes.activation =>
          "Activation à l'avant-veille : deux séries faciles à ${_pct(v)} "
              'du maximum par atelier, pour garder le geste sans fatigue.',
        CoachNotes.reentryTest =>
          "Test d'entrée de reprise : en semaine 1, sur chaque mouvement "
              'principal, fais une première série arrêtée à ${_int(v)} '
              "répétitions de l'échec et note le total. Déclare ces "
              "nouveaux repères dans l'application : tout le programme se "
              'recale dessus. Tes anciens records ne sont pas des charges '
              'de travail.',
        CoachNotes.restBeforeEvent =>
          "Repos avant l'échéance : mobilité et préparation articulaire "
              'seulement, rien de fatigant dans les 2 à 4 derniers jours.',
        CoachNotes.badDay =>
          v is num && v >= 2
              ? 'Baisse du jour : ton sommeil court habituel est déjà compté '
                    'dans le programme. Elle ne se déclenche que sur une '
                    "nuit nettement pire que d'habitude (moins de 5 h), des "
                    'courbatures marquées sur la zone ou une journée très '
                    'éprouvante : 1 série de moins par exercice, aucune '
                    'série à moins de 3 répétitions en réserve, test '
                    'reporté.'
              : 'Baisse du jour (nuit de moins de 6 h, courbatures marquées '
                    'sur la zone, journée très stressante) : 1 série de moins '
                    'par exercice, aucune série à moins de 3 répétitions en '
                    'réserve, pas de test.',
        CoachNotes.attemptsGoal =>
          "Troisième tentative : la barre de l'objectif "
              '(${_plain(v)} kg de lest ou de charge) si la deuxième est '
              'montée vite et proprement ; sinon 2,5 à 5 kg de plus que la '
              'deuxième. Recale les trois barres sur tes séries lourdes des '
              'deux dernières semaines de charge.',
        CoachNotes.painGeneral =>
          'Douleur articulaire ou tendineuse (coude, épaule, poignet, '
              'genou) : de 0 à 2 sur 10, continue ; à 3 ou 4, finis la '
              "séance sans progresser et n'ajoute rien la semaine "
              'suivante ; à 5, prends la variante plus facile et retire 30 '
              'à 50 % du volume de la zone ; à ${_int(v)} ou plus, douleur '
              'la nuit ou gêne qui dure deux semaines : arrête le mouvement '
              'et consulte un professionnel de santé. Regarde la tendance '
              'sur deux à trois semaines, pas une seule séance.',
        CoachNotes.redFlags =>
          'Arrêt immédiat et avis médical : douleur dans la poitrine, '
              'essoufflement anormal, malaise ou vertige. Souffle pendant '
              "l'effort, sans bloquer la respiration sur les séries longues.",
        CoachNotes.shortVersion =>
          'Jour chargé : version courte de ${_int(v)} min — échauffement, '
              'puis les deux ou trois premiers exercices de la séance. Une '
              "séance courte vaut mieux qu'une séance sautée.",
        CoachNotes.bandChoice =>
          "Élastique : prends celui qui permet ${_int(v)} répétitions "
              'propres avec la réserve prévue ; note-le à chaque séance. '
              'Si même le plus fort ne suffit pas, fais la traction pieds '
              'en appui (barre basse) en attendant.',
        CoachNotes.cue => switch (v is num ? v.round() : 0) {
          1 =>
            'Exécution : départ bras tendus, épaules basses, menton '
                'au-dessus de la barre, sans élan.',
          2 =>
            "Exécution : épaules basses, descente contrôlée jusqu'à "
                "l'épaule au niveau du coude, verrouillage complet en haut.",
          3 =>
            'Exécution : tirage explosif vers les hanches, transition '
                'rapide, poitrine au-dessus de la barre avant de pousser.',
          4 =>
            'Exécution : bras tendus, tire la barre vers les hanches, '
                'bassin en rétroversion, corps aligné.',
          5 =>
            'Exécution : repousse le sol loin de toi, épaules en avant '
                'des mains, bras tendus, bassin en rétroversion.',
          6 =>
            'Exécution : corps gainé de la tête aux talons, poitrine près '
                'du sol, coudes à 45°.',
          7 =>
            'Exécution : même profondeur à chaque répétition, tronc '
                'gainé, pieds ancrés.',
          8 =>
            'Exécution : doigts écartés, épaules ouvertes, côtes '
                'rentrées ; sors proprement dès que la ligne se perd.',
          _ => null,
        },
        CoachNotes.intervalPace =>
          'Allure des fractions : 400 m en '
              '${v is num ? '${v.round() ~/ 60} min ${(v.round() % 60).toString().padLeft(2, '0')}' : ''} '
              '(ton allure estimée sur 5 km), récupération en trottinant ; '
              "si l'allure ne tient plus, arrête la série.",
        CoachNotes.goalPace =>
          "Allure de l'objectif : "
              '${v is num ? '${v.round() ~/ 60} min ${(v.round() % 60).toString().padLeft(2, '0')}' : ''} '
              'au kilomètre, régulière du début à la fin.',
        CoachNotes.timeTrial =>
          'Test chronométré sur ${v is num ? _plain(v / 1000) : ''} km, '
              "après 10 à 15 min d'échauffement, à allure régulière. Il "
              'recale les allures du bloc suivant.',
        CoachNotes.skillHorizon =>
          'Objectif de figure : chaque étape demande au moins '
              '${_int(v)} semaines (le tendon suit moins vite que le '
              'muscle). Ce programme vise les étapes écrites dans '
              "l'échelle ; la figure complète vient après, étape par "
              "étape, et le test final porte sur l'étape réellement "
              'travaillée.',
        CoachNotes.walking =>
          'Pour la perte de poids : en plus des séances, marche rapide '
              '${_int(v)} min, deux à trois fois par semaine (tu peux '
              'parler en marchant), et 5 min de plus toutes les deux '
              'semaines.',
        CoachNotes.pushMaintenance =>
          "Poussée en entretien : ton objectif porte sur le tirage, la "
              'poussée garde ${_int(v)} séries par séance pour '
              "l'équilibre des épaules.",
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
          'Une série de tête, puis des séries allégées (la baisse, en % '
              'de la charge totale poids du corps compris, est écrite sur '
              'la ligne).',
        CoachNotes.speedWork =>
          'Séance légère à ${_pct(v)} du 1RM : chaque répétition rapide et '
              "propre, très loin de l'échec.",
        CoachNotes.attemptsPlan =>
          'Trois tentatives : ${_pct(v)} du 1RM (une barre déjà réussie à '
              "l'entraînement), puis 96 %, puis la troisième selon la "
              'vitesse de la deuxième (99 à 102 %). Au moins 6 min entre '
              'deux tentatives.',
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
              ? "Séance de l'échéance : elle se fait le jour même de "
                    "l'épreuve, ${_int(v)} jour(s) après ce créneau "
                    'habituel.'
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
          "Chaque séance commence par ${_int(v)} min d'échauffement au "
              'plus (comptées dans la durée estimée) : épaules, poignets '
              'et hanches en mobilité, 2 × 8 tirages scapulaires, 2 × 8 '
              'pompes scapulaires, puis quelques répétitions faciles du '
              'premier mouvement.',
        CoachNotes.toleranceVolume =>
          'Volume réglé à ${_pct(v)} du volume type de ton niveau, au vu de '
              'ta récupération.',
        _ => null,
      };
    case ReasonCodes.planProgressionRule:
      final step = p['step'];
      return switch (p['rule']) {
        CoachRules.assistanceStep =>
          "Assistance : dès que le haut de la plage est tenu avec la "
              "réserve prévue, passe à un élastique plus fin (ou allège "
              "l'appui des pieds) et repars du bas de la plage.",
        CoachRules.doubleProgression =>
          'Progression : quand toutes les séries atteignent le haut de la '
              'plage avec la réserve prévue, passe à la variante ou à la '
              'charge suivante et repars du bas de la plage.',
        CoachRules.loadStep =>
          'Charges lestées : elles suivent les pourcentages écrits semaine '
              'par semaine ; si la série de tête ne laisse pas la réserve '
              'prévue, garde la charge de la semaine précédente.',
        CoachRules.repStep =>
          'Séries au poids du corps : les répétitions écrites suivent ta '
              "trajectoire vers l'objectif (environ une répétition de "
              'plus toutes les une à deux semaines sur la série de tête) ; '
              'si la réserve prévue ne tient pas, garde les chiffres de la '
              'semaine précédente.',
        CoachRules.holdStep =>
          step is num && step >= 5
              ? "Gainage et tenues d'appoint : +5 s par tenue quand toutes "
                    'les tenues sont propres.'
              : 'Tenues de figure : +1 s par tenue quand toutes les tenues '
                    "sont propres ; l'étape suivante quand le critère de "
                    "passage de l'échelle est atteint.",
        CoachRules.densityStep =>
          'Départs au chrono : un départ de plus toutes les deux semaines '
              "au plus ; les répétitions par départ ne montent qu'après "
              'un test.',
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
        'time_trial' => 'Test chronométré.',
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
