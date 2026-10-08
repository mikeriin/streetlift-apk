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

BodyZone? _zoneAt(Object? v) {
  if (v is! num) {
    return null;
  }
  final i = v.round();
  return i >= 0 && i < BodyZone.values.length ? BodyZone.values[i] : null;
}

/// Zone de rang [v] dans `BodyZone.values`, en français.
String _zoneOfIndex(Object? v) {
  final z = _zoneAt(v);
  return z == null ? 'zone signalée' : coachZoneLabel(z.code);
}

/// Mouvements retirés pour la zone de rang [v], entre parenthèses.
String _provokingOfIndex(Object? v) => switch (_zoneAt(v)) {
  BodyZone.wristHand =>
    '(tous les appuis poignet en extension, mains à plat : planche et '
        'équilibres au sol, pompes en appui tendu, shoulder taps, pompes au '
        'sol ; les appuis à prise neutre — parallettes, barres parallèles, '
        'anneaux, poignées — restent, en volume réduit, si la gêne ne monte '
        'pas)',
  BodyZone.elbow =>
    '(mouvements lestés et tirages lourds qui chargent le coude, '
        'pronation lourde ; tractions en prise neutre légères seulement si '
        'la gêne reste à 2 sur 10 au plus)',
  BodyZone.shoulder =>
    '(dips, appuis renversés, figures en appui et tout ce qui charge '
        "l'épaule en fin d'amplitude)",
  _ => '(ceux qui chargent fortement la zone)',
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
          v is num && v < 0
              ? "Ensuite, seulement si aucune traction n'est passée : la "
                    'tenue menton au-dessus de la barre la plus longue, '
                    'deux essais chronométrés (monte en sautant depuis un '
                    'appui, bras fléchis, menton au-dessus de la barre ; '
                    'repère : ${_int(-v)} s). Elle mesure la force de la '
                    "position haute, d'un test à l'autre."
              : 'Test : la tenue menton au-dessus de la barre la plus '
                    'longue, deux essais chronométrés (monte en sautant '
                    'depuis un appui, bras fléchis, menton au-dessus de la '
                    "barre). Note le temps (repère : ${_int(v)} s) : s'il "
                    "monte d'un test à l'autre, la position haute de la "
                    'traction se renforce.',
        CoachNotes.strictAttempt =>
          "Test, d'abord l'essai strict, frais : après l'échauffement et "
              "1 à 2 tractions faciles à l'élastique, essaie la traction "
              'stricte — départ bras tendus, menton au-dessus de la barre, '
              "sans élan — jusqu'à 3 essais séparés de 3 min, autant de "
              'répétitions propres que possible (objectif : ${_int(v)}). '
              "Fais cet essai à chaque test, en fin de bloc comme le "
              "jour de l'échéance, quel que soit le temps de tes "
              'descentes. Si une traction passe, '
              "déclare-la dans l'application : les séances commenceront "
              'alors par 2 à 3 tractions strictes isolées, propres, arrêt '
              'au premier essai lent ou déformé (jamais un effort '
              'maximal), le reste en descentes freinées et en tractions '
              'assistées.',
        CoachNotes.entrySet =>
          "Série d'entrée de reprise, aujourd'hui seulement : la première "
              'série de cette ligne se fait jusqu\'à ${_int(v)} répétitions '
              "de l'échec, à la place du chiffre écrit (départs au chrono : "
              'une série avant, puis 3 min de repos). Note le total : ton '
              'maximum de reprise = ce total + ${_int(v)}. S\'il est sous '
              'le repère écrit, recalcule les séries de la semaine sur lui, '
              'aux mêmes pourcentages.',
        CoachNotes.slowNegativePush =>
          'Pompe complète en descente freinée : ${_int(v)} s pour '
              'descendre, corps gainé de la tête aux talons, poitrine au '
              'sol ; remonte en posant les genoux. Arrête la série dès '
              "qu'une descente passe sous 2 s ou que le bassin s'affaisse.",
        CoachNotes.roleForearm =>
          'Avant-bras : fléchisseurs et extenseurs du poignet en charge '
              'légère, loin de la limite — tolérance du coude et du '
              'poignet au volume de tirage et aux appuis.',
        CoachNotes.roleRunner =>
          'Renforcement du coureur : mollets en charge lente, rebonds '
              'courts et élastiques (contacts brefs, sans fatigue) — pour '
              "le tendon d'Achille et l'économie de course. Douleur au "
              "tibia, au tendon d'Achille ou au pied à 3 sur 10 : retire "
              'les rebonds.',
        CoachNotes.restPause =>
          'Repos-pause, chaque semaine où cette note figure sur la ligne '
              '(et seulement celles-là) : la dernière série écrite se '
              'prolonge par ${_int(v)} relances au '
              'plus de 3 à 4 répétitions, après 20 s de pause chacune ; '
              "chaque relance s'arrête avec une répétition en réserve. "
              'Rien de plus : ces relances comptent pour une série dure. '
              'Pas de relance si le coude ou l\'épaule dépasse le seuil '
              'de ta règle de douleur.',
        CoachNotes.ambitious =>
          v is num && v < 2000
              ? 'Objectif ambitieux : plusieurs tractions en partant de zéro '
                    "sur ce programme, c'est possible, pas garanti. "
                    '${v.round() % 1000 > 1 ? 'Une ou deux tractions propres' : 'Une première traction propre'} '
                    'au test final serait déjà un très bon cycle : ne force '
                    'pas la forme pour en faire plus.'
              : 'Objectif ambitieux : le gain demandé dépasse le rythme '
                    'habituel à ton niveau (environ +15 % en 12 semaines '
                    "chez un pratiquant entraîné). Le programme vise "
                    "l'objectif, mais un résultat de "
                    '${v is num ? v.round() ~/ 1000 : ''} à '
                    '${v is num ? v.round() % 1000 : ''} au test final '
                    'serait déjà un bon cycle : ne force pas la forme pour '
                    "y arriver. Si le repère de mi-parcours n'est pas "
                    'atteint, le bloc suivant change de méthode (voir le '
                    'repère) et repart du résultat du test ; '
                    "l'objectif se joue alors au cycle suivant.",
        CoachNotes.maxSetPlan =>
          'Avant la série maximale : 2 séries faciles (un quart, puis un '
              'tiers du maximum), 2 à 3 min de repos. Pendant : rythme '
              'régulier dès le départ, souffle en haut de chaque '
              'répétition ; des pauses courtes en position de repos (bras '
              'tendus) si ton standard les autorise'
              '${v is num && v > 0 ? ' ; répétition repère à mi-série : ${_int(v)}' : ''}'
              '.',
        CoachNotes.holdRamp =>
          'Avant le maintien maximal : la préparation habituelle des '
              'poignets et des épaules, puis 2 tenues de montée (une étape '
              "plus facile 5 s, puis l'étape du test 2 à 3 s), et "
              "${_int(v)} min de repos avant l'essai. Jamais à froid.",
        CoachNotes.tracking =>
          'Suivi : coche chaque séance faite (objectif : ${_int(v)} par '
              'semaine) et note tes minutes de marche chaque semaine ; '
              'relève ton poids et ton tour de taille aux semaines 1, 6 et '
              '12, le matin à jeun. Perte de poids : un déficit modéré '
              '(500 kcal par jour au plus) garde le muscle, avec des '
              'protéines à chaque repas et 7 h de sommeil visées ; pour '
              "l'alimentation, fais-toi accompagner par un professionnel "
              'de santé.',
        CoachNotes.smallLoad =>
          'Ton 1RM lesté est proche du poids du corps : la charge ne se '
              'calcule pas en pourcentage mais à la réserve — départ '
              'conseillé : ${_plain(v)} kg de lest. À la première séance '
              'du bloc, fais une série de calibrage (monte par paliers de '
              "1,25 à 2,5 kg jusqu'à la série qui laisse la réserve "
              'écrite, poids du corps seul compris) et garde cette charge ; '
              'ensuite ajoute '
              'le plus petit pas quand toutes les séries passent ; si la '
              "réserve n'est pas tenue, retire 2,5 kg dans la séance.",
        CoachNotes.pushLadder =>
          'Échelle de poussée : pompe au mur → mains surélevées (barre '
              'basse ou barres parallèles, de plus en plus bas) → genoux '
              '→ sol. Un seul critère de passage : quand 2 séries de '
              '${_int(v)} propres passent avec la réserve écrite, deux '
              "séances de suite, descends d'un cran (note la hauteur des "
              'mains en cm à chaque séance et au test). Jamais plus de '
              '${_int(v)} répétitions sur un cran : au-delà, on baisse '
              "l'appui, on n'allonge pas la série. Poignet gêné (3 sur 10 "
              'ou plus deux séances de suite) : même cran sur poignées, '
              'parallettes ou poings fermés.',
        CoachNotes.primer =>
          "Amorçage à l'avant-veille : deux simples à ${_pct(v)} du 1RM "
              "par mouvement, dans l'ordre de l'épreuve, rapides et "
              'faciles, avec les commandes et le matériel du jour J. '
              'Rien de plus.',
        CoachNotes.recalibrate =>
          'Série de recalage (dernière semaine de charge du bloc) : note '
              'la charge, les répétitions et la réserve réelle de la série '
              'de tête. Au moins une répétition de plus en réserve que '
              'prévu : ton 1RM de travail monte de ${_plain(v)} % au bloc '
              'suivant ; une de moins : il baisse de ${_plain(v)} %. '
              "Déclare la série dans l'application, les charges se "
              'recalent dessus.',
        CoachNotes.stepGate =>
          'Étape suivante, sous condition. Repère mesurable : au dernier '
              "test, un maintien maximal d'au moins "
              "${v is num ? (v / 0.75).round() : ''} s sur l'étape "
              'actuelle (des tenues de ${_int(v)} s en valent alors 75 %). '
              'Tu remplaces ensuite, une séance lourde par semaine, les '
              'tenues écrites par 3 × ${_int(v)} s ; quand elles sont '
              'propres 2 séances de suite (douleur à 2 sur 10 au plus), '
              "cette ligne s'ouvre : entrées de 2 à 3 s, très loin de la "
              'limite. Sinon, saute-la. La semaine où elle '
              "s'ouvre, rien d'autre n'augmente (un seul changement à la "
              'fois).',
        CoachNotes.entryCheck =>
          "Série repère, aujourd'hui seulement : la première série de "
              "cette ligne va jusqu'à ${_int(v)} répétitions de l'échec "
              '(mouvement lesté : à la charge écrite, autant de répétitions '
              'propres que possible en gardant cette réserve). Note-la : '
              "ton maximum du jour = répétitions faites + ${_int(v)}. S'il "
              'est sous le repère écrit de plus de 5 %, recalcule les '
              'séries des deux premières semaines sur ce maximum du jour, '
              "aux mêmes pourcentages ; sinon, garde les chiffres écrits. "
              "Un record déclaré n'est un repère qu'une fois vérifié.",
        CoachNotes.repsRehearsal =>
          'Simulation du test : la série de tête se fait au format du '
              'test (même échauffement, même standard de répétition), '
              "jusqu'à une répétition de l'échec — environ ${_int(v)} "
              "répétitions. Note le résultat : il dit si l'objectif du test "
              'est réaliste ; pas de série allégée après.',
        CoachNotes.stepCriterion =>
          'Tenues vers le critère de passage : ${_int(v)} s par tenue, '
              'une fois par semaine, à la place des tenues courtes. Arrêt '
              'dès que la ligne casse (qualité sous 4 sur 5). Quand le '
              "critère de l'échelle est tenu proprement 2 séances de suite, "
              "l'étape suivante s'ouvre au bloc suivant.",
        CoachNotes.maxAttempt =>
          'Toutes les ${_int(v)} semaines, la première tenue de cette '
              "séance est un maintien maximal propre (arrêt dès que la "
              'ligne casse). Note-le : les secondes des semaines suivantes '
              'valent 60 à 85 % de ce nouveau repère ; si une tenue passe '
              'sous 4 sur 5 en qualité, garde la dose.',
        CoachNotes.holdCalibrate =>
          'Première séance : mesure ton maintien maximal propre (un seul '
              'essai), puis travaille à ${_pct(v)} de ce temps. '
              "Déclare-le dans l'application.",
        CoachNotes.estimatedLoad =>
          "Charge de départ estimée d'après ton maximum au poids du "
              'corps : ${_plain(v)} kg de lest. Ajuste-la à la première '
              'séance pour garder la réserve prévue, puis ajoute le plus '
              'petit pas quand toutes les séries passent.',
        CoachNotes.reconciled =>
          'Ton maximum de répétitions au poids du corps indique un 1RM '
              'plus haut que celui déclaré : les charges et les '
              'pourcentages de cette ligne sont calculés sur un seul '
              'repère, ${_plain(v)} kg de charge totale (poids du corps '
              'compris). Le prochain test le recale.',
        CoachNotes.tendonLoad =>
          'Charge progressive des fléchisseurs du poignet (face interne '
              'du coude) : à faire valider par le professionnel qui suit '
              'ton coude. Même seuil que la règle de douleur de la zone : '
              'tu ajoutes le plus petit pas seulement si la gêne reste à 2 '
              'sur 10 au plus pendant la séance et le lendemain ; à '
              '${_int(v)} ou 4, charge inchangée.',
        CoachNotes.pullReturn =>
          'Retour au tirage lesté : quand le coude reste à 2 sur 10 ou '
              'moins deux semaines de suite sur ces tractions, ajoute '
              '${_plain(v)} kg (3 × 5, 3 répétitions en réserve), puis '
              '${_plain(v)} kg toutes les deux semaines au plus. Au-delà '
              'de 2 sur 10, reviens au palier précédent.',
        CoachNotes.easyBeforeTest =>
          'À deux jours du test : séance facile, deux séries au plus à '
              "${_pct(v)} des répétitions habituelles, très loin de "
              "l'échec — 48 h sans travail dur avant le test.",
        CoachNotes.alreadyApplied =>
          'Les réductions liées à ton profil habituel (sommeil, stress, '
              'travail physique, âge) sont déjà dans les chiffres des '
              "tableaux : ne les retire pas une deuxième fois. La baisse "
              "du jour (nuit nettement plus courte que d'habitude, bilan "
              "bas) s'applique en plus, elle.",
        CoachNotes.dressRehearsal =>
          "Dernier lourd avant l'épreuve (J−${_int(v)}) : fais-le dans "
              'les conditions du jour J — commandes, matériel de '
              'compétition, amplitude jugée (filme-toi de profil).',
        CoachNotes.bodyweightFloor =>
          'La charge visée tombe sous ton poids de corps : série sans '
              'lest, à ${_pct(v)} de ton 1RM (poids du corps compris), '
              'avec moins de répétitions pour garder la réserve.',
        CoachNotes.overload =>
          'Amplitude partielle (fin du mouvement, 10 à 15 cm) à ${_pct(v)} '
              'de ton 1RM complet : toujours avec butées de sécurité '
              'réglées juste sous la position de travail (barres dans une '
              'cage, ou box sous les pieds) ou avec parade. Retire '
              "l'exercice si le coude ou l'épaule dépasse le seuil de ta "
              'règle de douleur.',
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
          "Barre de l'objectif (${_plain(v)} kg de lest ou de charge) : "
              'elle est au-dessus de ton 1RM de départ. Elle ne se tente '
              'que si tes simples lourds des dernières semaines de charge '
              'sont montés vite avec une répétition en réserve : recalcule '
              'alors ton 1RM (charge totale du simple ÷ 0,94) et reprends '
              'les trois barres sur ce nouveau 1RM. Sinon, garde le plan '
              "des trois tentatives : l'objectif attendra le cycle suivant.",
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
        CoachNotes.shortVersion when v is num && v >= 300 =>
          'Jour chargé : version courte de ${_int(v - 300)} min — 3 min de '
              "marche, l'exercice de jambes et l'équilibre, puis 3 min "
              "d'étirements. Une séance courte vaut mieux qu'une séance "
              'sautée.',
        CoachNotes.shortVersion when v is num && v >= 100 =>
          'Jour chargé : version courte de ${_int(v - 100)} min — 5 min de '
              'marche rapide puis footing facile, sans fractions. Une '
              "séance courte vaut mieux qu'une séance sautée.",
        CoachNotes.shortVersion =>
          v is num && v < 20
              ? 'Jour chargé : version courte de ${_int(v)} min — 4 min '
                    "d'échauffement, puis le premier exercice seul (le "
                    "mouvement de l'objectif), 2 séries. Une séance courte "
                    "vaut mieux qu'une séance sautée."
              : 'Jour chargé : version courte de ${_int(v)} min — '
                    "5 min d'échauffement, puis les deux premiers exercices "
                    'de la séance, 2 séries chacun. Une séance courte vaut '
                    "mieux qu'une séance sautée.",
        CoachNotes.bandChoice =>
          v is num && v >= 100
              ? "Élastique : prends celui qui permet ${_int(v - 100)} "
                    'répétitions propres avec la réserve prévue ; note-le à '
                    'chaque séance. Il ajoute du volume de tirage sans '
                    'remplacer tes tractions strictes ; pour changer '
                    "d'élastique, suis la règle d'assistance."
              : "Élastique : prends celui qui permet ${_int(v)} répétitions "
                    'propres avec la réserve prévue ; note-le à chaque '
                    'séance. Si même le plus fort ne suffit pas, fais la '
                    'traction pieds en appui (barre basse) en attendant ; '
                    "pour changer d'élastique, suis la règle d'assistance. "
                    'À partir de la sixième semaine, commence deux séances '
                    'par semaine par 1 à 3 essais isolés de traction '
                    'stricte, frais, 2 min entre eux, arrêt au premier essai '
                    "lent ; tant qu'aucun ne passe, fais à la place une "
                    "traction sautée suivie d'une descente de 5 s.",
        CoachNotes.cue => switch (v is num ? v.round() : 0) {
          1 =>
            'Exécution : départ bras tendus, épaules basses, menton '
                'au-dessus de la barre, sans élan.',
          2 =>
            'Exécution : épaules basses, descente contrôlée, épaule '
                'nettement sous le coude en bas, verrouillage complet en '
                'haut.',
          3 =>
            'Exécution : amène la barre aux hanches, transition rapide, '
                'poitrine au-dessus de la barre avant de pousser. La série '
                "s'arrête à la première répétition dont la transition "
                'ralentit, se fait en deux temps ou demande un battement de '
                "jambes de plus : jamais jusqu'à l'échec.",
          4 =>
            'Exécution : bras tendus, pousse la barre vers les hanches, '
                'bassin en rétroversion, corps aligné.',
          5 =>
            'Exécution : repousse le sol loin de toi, épaules en avant '
                'des mains, bras tendus, bassin en rétroversion. Poignet '
                'sensible (gêne habituelle au-dessus de 1 sur 10) : '
                'parallettes ou poings fermés par défaut ; retour au sol '
                'quand la gêne reste à 0 ou 1 le lendemain deux semaines '
                'de suite.',
          6 =>
            'Exécution : corps gainé de la tête aux talons, poitrine près '
                'du sol, coudes à 45°.',
          7 =>
            'Exécution : pli de la hanche sous le haut du genou à chaque '
                'répétition, tronc gainé, pieds ancrés.',
          8 =>
            'Exécution : doigts écartés, épaules ouvertes, côtes '
                'rentrées ; sors proprement dès que la ligne se perd. '
                'Poignet sensible (gêne habituelle au-dessus de 1 sur '
                '10) : poings fermés, barres basses ou parallettes par '
                'défaut.',
          9 =>
            'Exécution : départ bras tendus, tire les coudes vers le bas '
                "et l'arrière jusqu'à toucher la barre avec la poitrine, "
                'sans élan.',
          10 =>
            'Exécution : corps gainé de la tête aux genoux, poitrine près '
                "de l'appui, coudes à 45°.",
          11 =>
            'Exécution : épaules basses, descente lente et contrôlée ; '
                'amplitude progressive — les premières semaines, descends '
                "jusqu'au bras parallèle au sol, puis un peu plus bas "
                "chaque semaine si l'épaule ne se plaint pas ; verrouillage "
                'complet en haut.',
          12 =>
            'Exécution : corps gainé de la tête aux talons, poitrine près '
                "de l'appui, coudes à 45°. Poignet à ménager : poings "
                'fermés, poignées ou parallettes (poignet neutre), ou mains '
                "sur une barre basse pour la pompe inclinée ; pas d'appui "
                'paume à plat tant que la gêne ne reste pas à 0 ou 1 le '
                'lendemain deux semaines de suite.',
          _ => null,
        },
        CoachNotes.intervalPace =>
          'Allure des fractions : '
              '${v is num ? '${v.round() ~/ 60} min ${(v.round() % 60).toString().padLeft(2, '0')}' : ''} '
              'au kilomètre (ton allure estimée sur 3 km), récupération en '
              'trottinant ; '
              "si l'allure ne tient plus, arrête la série. Chaque test "
              'chronométré recale cette allure.',
        CoachNotes.goalPace =>
          "Allure de l'objectif : "
              '${v is num ? '${v.round() ~/ 60} min ${(v.round() % 60).toString().padLeft(2, '0')}' : ''} '
              'au kilomètre, régulière du début à la fin.',
        CoachNotes.timeTrial =>
          'Test chronométré sur ${v is num ? _plain(v / 1000) : ''} km, '
              "après 10 à 15 min d'échauffement, à allure régulière. Il "
              'recale les allures du bloc suivant.',
        CoachNotes.skillHorizon =>
          'Objectif de figure, à lire en premier : la figure complète '
              "n'est pas atteignable dans ce programme. Chaque étape "
              'demande au moins ${_int(v)} semaines (le tendon suit moins '
              'vite que le muscle). Ce programme vise à valider le critère '
              "de l'étape actuelle, puis à ouvrir la suivante sous "
              "condition ; le test final porte sur l'étape actuelle. La "
              'figure complète vient aux cycles suivants, étape par étape.',
        CoachNotes.walking =>
          'Pour la perte de poids : en plus des séances, deux marches de '
              '15 à 20 min en semaine 1, les jours sans séance, à allure '
              'modérée (tu peux parler en phrases, légèrement essoufflé), '
              'puis trois marches qui montent vers ${_int(v)} min ; garde '
              'un jour sans activité. Ajoute '
              "10 min par semaine au total pour viser 150 min d'endurance "
              'par semaine vers la semaine 8, puis 200 min et plus en fin '
              'de programme, marche des séances comprise (si la marche de '
              'fin de séance raccourcit, les marches des autres jours '
              'compensent). Toute durée compte : tu peux fractionner. La '
              'priorité des premières semaines reste de tenir les séances.',
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
          "Repère sur le chemin de l'objectif : ${_plain(v)}. Une seule "
              "règle : le bloc suivant est écrit sur le résultat du test ; "
              "s'il est atteint, il garde sa méthode ; s'il ne l'est pas, "
              'la séance la plus légère du mouvement (départs au chrono ou '
              'séries de volume) devient une séance de surcharge en séries '
              'courtes — variante plus dure ou lest léger, 2 répétitions en '
              "réserve. Tu n'ajoutes jamais de séries toi-même.",
        CoachNotes.wodPace =>
          'Conditionnement : allure tenable du premier au dernier passage '
              '(effort ${_int(v)} sur 10), jamais un sprint au départ ; '
              'chaque passage garde 2 à 3 répétitions en réserve. Mets à '
              "l'échelle pour garder le format : charge plus légère, "
              'amplitude réduite ou variante plus simple. Charges de repère : '
              'wall ball 9 kg (6 kg), swing 24 kg (16 kg), haltères 22,5 kg '
              '(15 kg) ; une charge qui casse ta série dès le premier tour '
              'est trop lourde.',
        CoachNotes.safetyPins =>
          'Charge lourde (${_int(v)} % du 1RM et plus) : sécurités de la '
              'cage réglées juste sous le point le plus bas, ou un pareur. '
              "Si la dernière montée d'échauffement n'est pas rapide, la "
              'série de tête se fait à cette charge-là.',
        CoachNotes.checkpointBody =>
          "Repère sur le chemin de l'objectif : ${_plain(v)}. Une seule "
              "règle : le bloc suivant est écrit sur le résultat du test ; "
              "s'il est atteint, il garde sa méthode ; s'il ne l'est pas, "
              'la séance la plus légère du mouvement (départs au chrono ou '
              'séries de volume) devient une séance de surcharge sans lest, '
              'en séries courtes à 2 répétitions en réserve : descente en 4 '
              'à 5 s et pause en haut, puis une variante plus dure (archer, '
              "chest-to-bar) quand ce tempo devient facile. Tu n'ajoutes "
              'jamais de séries toi-même.',
        CoachNotes.checkpointHold =>
          "Repère sur le chemin de l'objectif : ${_plain(v)} s. Une seule "
              "règle : le bloc suivant est écrit sur le résultat du test ; "
              "s'il est atteint, il garde sa méthode ; s'il ne l'est pas, il "
              'change de dose sur le levier : des tenues plus courtes et '
              'plus nombreuses, au même temps total, avec des repos '
              "complets (2 à 3 min). Tu n'ajoutes jamais de séries toi-même.",
        CoachNotes.checkpointLoad =>
          "Repère sur le chemin de l'objectif : ${_plain(v)} kg. Une seule "
              "règle : le bloc suivant est écrit sur le résultat du test "
              "(charges recalées) ; s'il n'est pas atteint, le bloc garde sa "
              "méthode, à partir de ce résultat, et l'objectif se joue au "
              'cycle suivant — pas de charge ajoutée au jugé.',
        CoachNotes.checkpointLadder =>
          "Repère sur le chemin de l'objectif : ${_plain(v)}. Une seule "
              "règle : le bloc suivant est écrit sur le résultat du test ; "
              "s'il n'est pas atteint, il baisse l'appui de la pompe "
              "facile d'un cran (mains plus basses) et garde les descentes "
              "freinées au sol. Tu n'ajoutes jamais de séries toi-même.",
        CoachNotes.pushHeight =>
          (v is num && v > 0)
              ? 'Hauteur des mains, à régler cette semaine : ton maximum sur '
                    "l'appui d'avant dépasse 15 — baisse les mains de "
                    "${_int(v)} cran${v > 1 ? 's' : ''} (environ 10 cm "
                    "chacun), jusqu'à l'appui où ton maximum propre est de 12 "
                    'à 14 répétitions. Note la hauteur en cm : elle sert aux '
                    'séances et au test, et ne change ensuite que par le '
                    "critère de l'échelle."
              : 'Hauteur des mains, à régler à la première séance : '
                    "l'appui où ton maximum propre est de 12 à 14 répétitions. "
                    'Note la hauteur en cm : elle sert aux séances et au test, '
                    "et ne change ensuite que par le critère de l'échelle.",
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
              'les charges, les répétitions et les secondes du bloc '
              'suivant : déclare ton résultat, le bloc suivant est écrit '
              'dessus (série de tête = résultat − 2 ; tenues = 60 à 85 % '
              'du maintien mesuré), jamais sur un progrès supposé. Un test '
              'fait un jour de bilan bas se reporte de 48 à 72 h.',
        CoachNotes.weightClass =>
          v is num && v < 0
              ? 'Catégorie de poids : plus de ${_int(-v)} kg. Pesée (règlement '
                    'FinalRep, à vérifier pour ta compétition) : 2 h avant ta '
                    'première vague. Pèse-toi une fois par semaine, au '
                    'réveil ; si ton poids change, les charges, écrites en '
                    'charge totale, se recalculent.'
              : 'Catégorie de poids : moins de ${_int(v)} kg à ton poids '
                    'actuel. Pesée (règlement FinalRep, à vérifier pour ta '
                    'compétition) : 2 h avant ta première vague, tolérance '
                    'de 0,1 kg. Pèse-toi une fois par semaine, au réveil : si '
                    'tu dépasses la limite de plus de 1 kg à deux semaines de '
                    "l'épreuve, change plutôt de catégorie que de couper du "
                    'poids à la fin ; si ton poids change, les charges, '
                    'écrites en charge totale, se recalculent.',
        CoachNotes.painTrend =>
          'Douleur relevée au bloc précédent (${_int(v)}/10 sur cette '
              'zone) : la figure reste au programme, avec environ 40 % de '
              'volume en moins et la variante la plus douce pour la zone '
              '(parallettes ou poings pour le poignet) ; pas de hausse tant '
              'que la gêne ne reste pas sous 2/10 deux semaines de suite. '
              'À 6/10, douleur la nuit ou gêne qui dure : arrête le '
              'mouvement et consulte.',
        CoachNotes.wristSpare =>
          "Poignet sensible au profil : l'appui en extension sans prise "
              'neutre est réduit de moitié dès le départ (parallettes, '
              'poignées ou poings par défaut) : ce sont les séries de ces '
              'figures qui sont divisées par deux. Règle de douleur, la '
              'même que celle du programme : hausse seulement si la gêne '
              "reste à ${_int(v)} sur 10 au plus pendant l'effort et revient "
              'à ton état habituel le lendemain matin ; à 3 ou 4, dose '
              'inchangée ; à 5, variante plus facile et volume réduit ; '
              'au-delà, arrêt et consultation. Les séries reviennent par '
              'paliers de 10 % quand la gêne reste à 0 ou 1 deux semaines '
              'de suite.',
        CoachNotes.eventZone =>
          "Zone de l'épreuve : séries à environ ${_int(v)} % de ton maximum, "
              'repos court, la réserve écrite sur la dernière (2 répétitions '
              'au moins) — '
              "c'est la fin de série que le test demande. La dernière série "
              "s'arrête dès que la forme casse ; si la réserve tombe sous 1, "
              "retire une répétition par série la séance suivante.",
        CoachNotes.plateau =>
          'Plateau au dernier test (${_int(v)} répétitions, sans progrès) : '
              'ce bloc change de méthode au lieu de recopier le précédent — '
              'une variante plus dure en séries courtes (descente en 4 à 5 s, '
              'pause en haut, archer ou typewriter quand le maximum le '
              'permet), des départs au chrono qui montent d\'une variable à '
              'la fois, et une seule série de tête par semaine. Cible '
              'réaliste au prochain test : ${v is num ? v.round() + 1 : ''} '
              'à ${v is num ? v.round() + 2 : ''} répétitions.',
        CoachNotes.painStep =>
          "Étape plus facile pour l'instant : la gêne écarte l'étape de "
              'travail de la figure. Mêmes consignes de tenue, parallettes '
              "ou poings si l'appui le permet. Retour à l'étape de travail "
              'après deux semaines à 2 sur 10 au plus ; son test attend ce '
              "retour (un maintien maximal fait sur la douleur ne mesure pas "
              'la figure).',
        CoachNotes.painStop =>
          'Douleur qui dure (${_zoneOfIndex(v)}) : 3 sur 10 ou plus depuis '
              'plus de deux semaines, ou revenue après une reprise. Tous '
              'les mouvements qui la provoquent sont retirés '
              '${_provokingOfIndex(v)} ; le travail qui ne la charge pas '
              'continue. Consulte un médecin ou un kinésithérapeute : une '
              'douleur qui dure ou qui revient doit être examinée (une '
              "douleur d'appui du poignet peut cacher une lésion que seul "
              'un examen montre). Les mouvements retirés ne reviennent '
              "qu'après deux semaines à 2 sur 10 au plus, par paliers "
              "d'environ 10 % par semaine.",
        CoachNotes.painReprise =>
          'Bloc de reprise après une douleur qui dure sur un mouvement de '
              "l'objectif : ni test, ni affûtage, ni épreuve dans ce bloc ; "
              "l'échéance est repoussée au bloc suivant. Trois étapes : "
              'participation (le reste du programme suivi, les mouvements '
              'qui provoquent la zone retirés ou en reprise graduée), retour '
              'au mouvement (il revient à la moitié de son volume habituel, '
              "+10 % par semaine, loin de l'échec), puis performance (volume "
              "et charges habituels). On passe à l'étape suivante quand la "
              'gêne reste à 2 sur 10 au plus pendant la séance et le '
              'lendemain matin deux semaines de suite ; aucun test tant que '
              'la douleur dépasse 2 sur 10. Décision à prendre avec le '
              'professionnel qui suit la zone.',
        CoachNotes.painReturn =>
          'Reprise graduée (${_zoneOfIndex(v is num ? v.round() ~/ 100 : -1)}) : '
              'les mouvements retirés reviennent à '
              '${v is num ? 50 + 10 * ((v.round() % 100) ~/ 10) : 50} % de '
              'leur volume habituel, puis +10 % par semaine de charge '
              "(jamais pendant une semaine d'allègement), 3 répétitions en "
              'réserve au moins ; les mouvements lestés repartent vers 67,5 % '
              'du 1RM, +2,5 % par semaine au plus. Chaque palier se garde '
              'seulement si la gêne reste à 2 sur 10 au plus pendant la '
              "séance et revient à ton état habituel le lendemain matin, "
              "sans hausse d'une semaine à l'autre ; sinon, reviens au "
              'palier précédent. Si la douleur revient à 3 sur 10 ou plus, '
              'arrêt et nouvel avis.',
        CoachNotes.painReturnItem =>
          'Reprise graduée après une douleur qui dure : ${_pct(v)} du volume '
              'habituel cette semaine, loin de l\'échec ; le palier suivant '
              'seulement si la gêne reste à 2 sur 10 au plus et a disparu le '
              'lendemain.',
        CoachNotes.eventFormat =>
          "Format de l'épreuve : il n'existe pas de règlement unique. "
              "Saisis-le dans ton échéance (ordre des ateliers, temps limite, "
              'repos entre les ateliers, pauses permises ou séries sans '
              "arrêt, standard de répétition) : les répétitions de l'épreuve "
              "s'y caleront. En attendant, le programme suppose l'ordre "
              'muscle-up, tractions, dips et ${_int(v)} s de repos entre les '
              'ateliers.',
        CoachNotes.eventRehearsal =>
          "Répétition de l'épreuve : une série longue par atelier, dans "
              "l'ordre de l'épreuve, ${_int(v)} s de repos entre les "
              'ateliers. Rythme régulier dès le départ, pauses courtes '
              'bras tendus prévues (5 à 20 s), une répétition repère à '
              'mi-série ; amplitude et critères du règlement, filme-toi.',
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
          'Montée en charge avant la série de tête : ${_int(v)} séries '
              'progressives — 5 répétitions à 40 %, 3 à 60 %, 2 à 75 %, '
              '1 à 85 % de la charge du jour, 1 à 3 min entre elles.',
        CoachNotes.rampMuscleUp =>
          'Avant le muscle-up : ${_int(v)} séries de tractions faciles '
              '(la moitié de ton maximum), puis 2 ou 3 transitions à la '
              'barre basse ou des muscle-ups très faciles ; rien à froid.',
        CoachNotes.topSetBackoff =>
          'Une série de tête, puis des séries allégées (la baisse, en % '
              'de la charge totale poids du corps compris, est écrite sur '
              'la ligne).',
        CoachNotes.speedWork =>
          'Séance légère à ${_pct(v)} du 1RM : chaque répétition rapide et '
              "propre, très loin de l'échec.",
        CoachNotes.attemptsPlan =>
          'Trois tentatives : ${_pct(v)} du 1RM (une barre déjà réussie à '
              "l'entraînement), puis 96 %, puis la troisième = la deuxième "
              '+ 2,5 à 5 kg selon sa vitesse (99 à 102 %). Au moins 6 min '
              'entre deux tentatives ; échauffement à 40, 60, 75 puis 85 % '
              'avant la première ; après un essai manqué, la même barre ou '
              '2,5 kg de moins. Si une zone à ménager dépasse le seuil de '
              'ta règle de douleur cette semaine-là, pas de troisième '
              'barre.',
        CoachNotes.opener =>
          "Rappel avant l'échéance : ${_pct(v)} du 1RM, une série de tête "
              'rapide et facile, sans forcer (le dernier lourd est derrière '
              'toi).',
        CoachNotes.maintenance =>
          "En entretien : volume réduit, charge gardée — le volume va à "
              "l'objectif.",
        CoachNotes.everyMinute =>
          'Départs au chrono : une série toutes les ${_int(v)} s ; si les '
              'répétitions ne passent plus, arrête là.',
        CoachNotes.qualityFirst =>
          'À faire frais, en début de séance ; arrête dès que la qualité '
              'passe sous ${_int(v)} sur 5.',
        CoachNotes.submaximalHold =>
          'Tenues sous-maximales : 55 à 65 % de ton dernier maintien '
              'maximal mesuré les jours légers ; les jours lourds, 60 % en '
              'construction, 65 % en intensification, 70 % en réalisation '
              '(75 % au plus). Le volume se compte en secondes propres '
              'cumulées par séance (30 à 60 s sur le levier visé). Sur un '
              'levier dur, tenues courtes de 2 à 5 s, arrêt dès que la '
              'ligne se perd ; tu peux les enchaîner en grappes de 2 ou 3 '
              '(15 s entre elles). Les secondes écrites partent du dernier '
              'repère connu : si tu as mesuré un autre maintien, '
              'recalcule ; chaque tenue reste propre, bassin et épaules '
              'placés.',
        CoachNotes.slowTempo =>
          'Traction complète au tempo : montée tirée sans élan, 2 s le '
              'menton au-dessus de la barre, descente freinée en ${_int(v)} s. '
              'Arrête la série dès que la montée ralentit nettement ou '
              "qu'une descente passe sous 3 s ; si la première série ne "
              'passe pas, descente en 2 à 3 s.',
        CoachNotes.slowNegative =>
          'Descente freinée en ${_int(v)} s, sans à-coup (monte en sautant '
              "depuis un appui) ; l'effort se règle au contrôle, pas à la "
              "réserve : arrête la série dès qu'une descente passe sous "
              '3 s. Si la première descente passe déjà sous 3 s, fais-la '
              "avec l'élastique, ou vise 2 à 3 s, et allonge d'une "
              'seconde par semaine.',
        CoachNotes.eventDay =>
          v is num && v > 0
              ? "Jour de l'épreuve : cette séance se déplace au jour de "
                    "l'épreuve, ${_int(v)} jour(s) plus tard dans la "
                    'semaine ; rien de dur entre-temps.'
              : "Jour du test de l'objectif : c'est la séance elle-même, "
                    'après 48 h sans travail dur du mouvement.',
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
        CoachNotes.generalWarmup when v is num && v >= 300 =>
          "Chaque séance commence par ${_int(v - 300)} min d'échauffement "
              '(comptées dans la durée estimée) : marche sur place ou '
              'marche rapide, puis mobilité debout des épaules (bâton), des '
              'hanches et des chevilles, près d\'un appui.',
        CoachNotes.generalWarmup when v is num && v >= 200 =>
          "Chaque séance commence par ${_int(v - 200)} min d'échauffement "
              '(comptées dans la durée estimée) : 3 à 5 min de cardio léger '
              '(rameur, vélo), mobilité des épaules et des hanches, puis '
              'les séries de montée en charge du premier exercice (barre '
              'vide, puis deux ou trois paliers).',
        CoachNotes.generalWarmup when v is num && v >= 100 =>
          "Chaque séance commence par ${_int(v - 100)} min d'échauffement "
              '(comptées dans la durée estimée) : 5 min de trot progressif, '
              'mobilité des chevilles et des hanches, gammes (montées de '
              'genoux, talons-fesses) ; avant les fractions, deux ou trois '
              'accélérations progressives.',
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
          "Assistance (une seule règle pour changer d'élastique) : quand "
              'toutes les séries atteignent le haut de la plage avec la '
              'réserve prévue, deux séances de suite, passe dès la séance '
              "suivante à l'élastique plus fin (ou allège l'appui des pieds) "
              'et repars du bas de la plage ; si la réserve ne tient plus, '
              'reprends le précédent.',
        CoachRules.doubleProgression =>
          'Progression : quand toutes les séries atteignent le haut de la '
              'plage avec la réserve prévue, passe à la variante ou à la '
              'charge suivante et repars du bas de la plage.',
        CoachRules.loadStep =>
          'Charges lestées : elles suivent les pourcentages écrits semaine '
              'par semaine ; si la série de tête ne laisse pas la réserve '
              'prévue, garde la charge de la semaine précédente.',
        CoachRules.repStep =>
          'Séries au poids du corps : les répétitions sont calées sur ton '
              'dernier maximum mesuré (ton record, puis chaque test) — '
              'jamais sur un progrès supposé. Si toutes les séries passent '
              'avec au moins une répétition de réserve de plus que prévu, '
              'ajoute une répétition par série la semaine suivante (sans '
              'dépasser ton maximum − 2) ; si la réserve prévue ne tient '
              'pas, garde les chiffres de la semaine précédente ; après '
              'un test, série de tête = résultat − 2.',
        CoachRules.holdStep =>
          step is num && step >= 5
              ? "Gainage et tenues d'appoint : +5 s par tenue quand toutes "
                    'les tenues sont propres.'
              : 'Tenues de figure : les secondes écrites sont la dose (une '
                    'part de ton dernier maintien mesuré). Entre deux tests, '
                    "tu peux ajouter 1 s par tenue quand toutes sont propres, "
                    'sans dépasser 75 % de ce maintien ; au-delà, garde la '
                    "dose jusqu'au test suivant. L'étape suivante seulement "
                    "quand le critère de passage de l'échelle est atteint.",
        CoachRules.densityStep =>
          'Départs au chrono : une seule variable monte à la fois — un '
              'départ de plus toutes les deux semaines au plus, ou, dans la '
              "phase spécifique d'une épreuve de répétitions, environ 5 % "
              'du maximum de plus par départ chaque semaine (le nombre de '
              'départs reste) ; hors de cette phase, les répétitions par '
              "départ ne montent qu'après un test.",
        CoachRules.durationStep =>
          'Progression : durée +${_int(step)} % par semaine au plus.',
        _ => null,
      };
    case ReasonCodes.planPainRule:
      final zone = p['zone'];
      return 'Douleur (${zone is String ? coachZoneLabel(zone) : ''}), un '
          'seul seuil pour tous les mouvements qui chargent la zone '
          '(tirage, préhension, appuis, et le mouvement lesté qui la '
          'sollicite) : tu ajoutes de la charge ou du volume seulement si '
          'la gêne reste à 2 sur 10 au plus pendant la séance et le '
          'lendemain ; à 3 ou 4, tu fais la séance écrite sans rien '
          'ajouter et tu gardes la charge la semaine suivante, quels que '
          'soient les pourcentages écrits ; à '
          '5, prends la variante plus facile et retire 30 à 50 % du volume '
          "de la zone ; à ${_int(p['stopAt'])} ou plus, douleur la nuit, "
          'perte de force ou gêne qui dure deux semaines : arrête le '
          'mouvement et consulte un professionnel de santé. Le programme '
          'ne pose aucun diagnostic.';
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
      return 'Affûtage : séries dures ramenées à environ '
          "${_pct(p['volumeFactor'])} de la semaine de pointe, intensité "
          "et fréquence gardées, à ${_int(p['daysToEvent'])} jours de "
          "l'échéance au plus.";
    case ReasonCodes.planToCalibrate:
      return 'Charges « à calibrer » : à la première séance, trouve la '
          'charge qui permet le haut de la plage avec la réserve prévue, '
          'note-la, puis suis la double progression.';
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
          ': volume réduit la première semaine (de moitié après dix '
          "semaines d'arrêt ou plus) et au moins 3 répétitions en réserve, "
          'puis retour progressif (+10 à 15 % de séries par semaine les '
          'quatre premières semaines après une longue coupure, +20 % au '
          'plus ensuite) ; les répétitions écrites partent de tes '
          'anciens records réduits, jamais des records eux-mêmes — le '
          "test d'entrée et chaque test les recalent.";
    case ReasonCodes.planRecoveryProfile:
      return switch (p['factor']) {
        'sleep' =>
          'Sommeil court : volume réduit de 15 % et une répétition en '
              'réserve de plus. Vise 7 h : horaires réguliers, sieste de '
              "20 à 30 min quand c'est possible.",
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
