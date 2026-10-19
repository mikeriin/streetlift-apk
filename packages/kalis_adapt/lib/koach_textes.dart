/// Textes français des raisons de Koach 1.0 (lot KM2, pour KM3) : une phrase
/// lisible par code de raison, jamais un code brut (cahier KM, « Comportement
/// dans l'application » : « Textes de Koach : un texte lisible par code de
/// raison »). Intégration : `docs/INTEGRATION_KM3.md`, § 4.
///
/// Codes couverts :
///
/// - les 22 codes `koach.*` émis par la séance (`reference/CONTRAT_1_0.md`,
///   § 3.5 ; `lib/src/koach/seance.dart`), avec leurs paramètres et leurs
///   causes ([koachCodesRaisons], [koachCausesRaisons]) ;
/// - la surveillance hors modèle (`Surveillance`, contrat § 3.7.2) : causes
///   de l'alerte ([koachCausesHorsModele]) et actions codées rendues par
///   `Surveillance.repondre` ([koachActionsHorsModele]) ;
/// - les raisons texte du contrôle dual (`ControleDual.raisons`, contrat
///   § 3.5) : `essai_demarre:…`, `essai_refuse:…`, `essai_interrompu:…`,
///   `synthetique_impossible:…` ;
/// - les questions et les choix du diagnostic (`Surveillance.questions`) :
///   [texteQuestionKoach], [texteChoixKoach].
///
/// Registre : celui des textes de `kalis_core`
/// (`data/reason_texts_fr_0_4.json`) : tutoiement, Koach parle à la
/// première personne, une phrase courte. Un code inconnu rend une phrase
/// générique propre ([texteRaisonKoachGenerique]).
///
/// Les identifiants d'exercices (`exercice`, `remplacant`) ne sont jamais
/// écrits : l'appelant passe `nomExercice` (nom affiché de la base) ; sans
/// lui, ou si le nom est inconnu, la phrase dit « cet exercice ».
///
/// Dart pur, sans dépendance.
library;

/// Nom affiché d'un exercice de la base (null : inconnu). L'application
/// passe la recherche de son catalogue ; elle rend null plutôt que
/// l'identifiant quand le nom manque.
typedef NomExercice = String? Function(String exerciseId);

/// Les codes `koach.*` du contrat 1.0 (§ 3.5), dans l'ordre du contrat.
const List<String> koachCodesRaisons = <String>[
  'koach.douleur_persistante',
  'koach.douleur_retrait',
  'koach.test_reporte',
  'koach.poignet_appui_neutre',
  'koach.poignet_dose',
  'koach.technique_retenue',
  'koach.reprise_coupure',
  'koach.surmenage',
  'koach.reprise_dose',
  'koach.vrai_test',
  'koach.endurance_raccourcie',
  'koach.course_facile',
  'koach.endurance_retrait',
  'koach.course_bornee',
  'koach.wod_echelle',
  'koach.fatigue_croisee',
  'koach.arret_exercice',
  'koach.zone_fragile',
  'koach.serie_repere',
  'koach.tendon',
  'koach.retour_gradue',
  'koach.seance_bornee',
];

/// Valeurs du paramètre `cause` que la séance émet, par code (relevé dans
/// `lib/src/koach/seance.dart` et `securite.dart`). `koach.test_reporte`
/// émet aussi `coupure`, absent du tableau du contrat ; les causes
/// `reprise_N` suivent `securite.endurance_reprise` (7 et 14 jours dans le
/// fichier de paramètres livré).
const Map<String, List<String>> koachCausesRaisons = <String, List<String>>{
  'koach.douleur_retrait': <String>[
    'douleur',
    'douleur_arret',
    'douleur_reprise',
    'poignet_chaud',
    'poignet_charge',
    'reprise_dose',
  ],
  'koach.test_reporte': <String>['bilan_bas', 'coupure'],
  'koach.technique_retenue': <String>[
    'niveau',
    'douleur',
    'bilan',
    'phase',
    'echeance',
    'antecedent',
  ],
  'koach.endurance_raccourcie': <String>[
    'reprise_7',
    'reprise_14',
    'bilan',
    'bilan_fort',
    'douleur_jambe',
    'course_dure',
  ],
  'koach.course_facile': <String>[
    'bilan',
    'bilan_fort',
    'douleur_jambe',
    'course_dure',
  ],
  'koach.endurance_retrait': <String>[
    'bilan',
    'bilan_fort',
    'douleur_jambe',
    'course_dure',
  ],
  'koach.wod_echelle': <String>[
    'bilan',
    'bilan_fort',
    'douleur_jambe',
    'jours_durs',
  ],
  'koach.fatigue_croisee': <String>['course_dure'],
  'koach.arret_exercice': <String>['echecs', 'volume_test'],
  'koach.zone_fragile': <String>['surcharge', 'hausse'],
  'koach.tendon': <String>['total'],
};

/// Causes de l'alerte hors modèle (`ruptureCauses`, contrat § 3.7.2).
const List<String> koachCausesHorsModele = <String>[
  'rupture',
  'residu',
  'assiduite',
  'douleur',
];

/// Actions codées de `Surveillance.repondre` (contrat § 3.7.2).
const List<String> koachActionsHorsModele = <String>[
  'conduite_douleur',
  'replanifier',
  'semaine_allegee',
  'elargir',
];

/// Message d'entrée du diagnostic (code `surveillance.hors_modele`).
const String texteHorsModeleKoach =
    'Cette situation sort de mon modèle : réponds à trois questions au '
    'plus pour que je m’adapte.';

/// Repli d'un code inconnu : jamais le code lui-même.
const String texteRaisonKoachGenerique =
    'J’ai ajusté cette partie de ta séance pour qu’elle reste adaptée à toi.';

// ----------------------------------------------------------------------
// Entrée principale
// ----------------------------------------------------------------------

/// Phrase française d'une raison de Koach.
///
/// [raison] : `{code, params}` comme `Koach.explain()` ou la sortie de
/// `plan` les rendent (`params` peut manquer). Sont aussi acceptés :
///
/// - une cause de l'alerte hors modèle : code `rupture`, `residu`,
///   `assiduite` ou `douleur` (préfixe `surveillance.` ou
///   `surveillance.cause.` permis) ; code `surveillance.hors_modele` pour le
///   message d'entrée du diagnostic ;
/// - une action du diagnostic : l'objet rendu par `Surveillance.repondre`
///   (clé `action` et ses champs), ou code `conduite_douleur`,
///   `replanifier`, `semaine_allegee`, `elargir` (préfixe `surveillance.`
///   ou `surveillance.action.` permis) avec ces champs dans `params` ;
/// - une raison texte du contrôle dual comme code (`essai_refuse:12:…`).
///
/// Un code inconnu rend [texteRaisonKoachGenerique].
String texteRaisonKoach(
  Map<String, Object?> raison, {
  NomExercice? nomExercice,
}) {
  final brut = raison['code'];
  final params = _objet(raison['params']);
  if (brut is! String) {
    final action = raison['action'];
    if (action is String) {
      return _texteAction(action, raison);
    }
    return texteRaisonKoachGenerique;
  }
  final code = brut.trim();
  if (code.startsWith('koach.')) {
    return _texteKoach(code, params, nomExercice);
  }
  if (code == 'surveillance.hors_modele' || code == 'hors_modele') {
    return texteHorsModeleKoach;
  }
  final court = _sansPrefixe(code);
  if (koachCausesHorsModele.contains(court)) {
    return _texteCause(court);
  }
  if (koachActionsHorsModele.contains(court)) {
    return _texteAction(court, params);
  }
  final dual = _texteDual(code, nomExercice);
  if (dual != null) {
    return dual;
  }
  return texteRaisonKoachGenerique;
}

/// Phrase d'une raison texte du contrôle dual (`ControleDual.raisons`).
String texteRaisonDual(String raison, {NomExercice? nomExercice}) {
  return _texteDual(raison.trim(), nomExercice) ?? texteRaisonKoachGenerique;
}

// ----------------------------------------------------------------------
// Diagnostic : questions et choix
// ----------------------------------------------------------------------

/// Texte d'une question du diagnostic (champ `code` d'une question de
/// `Surveillance.questions`).
String texteQuestionKoach(String code) {
  switch (code) {
    case 'cause':
      return 'Qu’est-ce qui a changé ces derniers temps ?';
    case 'zone':
      return 'Où as-tu mal ?';
    case 'intensite':
      return 'Quelle intensité, de 0 à 10 ?';
    case 'seances_par_semaine':
      return 'Combien de séances par semaine peux-tu faire ?';
    case 'duree_max_min':
      return 'Combien de temps par séance ?';
  }
  return 'Dis-m’en un peu plus sur ce qui se passe.';
}

/// Texte d'un choix [choix] (champ `code` d'un choix) de la question
/// [question].
String texteChoixKoach(String question, Object? choix) {
  final nombre = _entier(choix);
  switch (question) {
    case 'cause':
      return switch (choix) {
        'douleur' => 'Une douleur',
        'moins_de_temps' => 'Moins de temps',
        'fatigue' => 'Fatigue ou vie chargée',
        'rien' => 'Rien de spécial',
        _ => 'Autre chose',
      };
    case 'zone':
      final zone = choix is String ? _zones[choix] : null;
      return zone == null ? 'Autre endroit' : zone.libelle;
    case 'intensite':
      if (nombre == null) {
        return 'Je ne sais pas';
      }
      if (nombre == 0) {
        return '0/10 (aucune gêne)';
      }
      if (nombre == 10) {
        return '10/10 (la pire possible)';
      }
      return '$nombre/10';
    case 'seances_par_semaine':
      if (nombre == null) {
        return 'Je ne sais pas';
      }
      return nombre <= 1 ? '1 séance' : '$nombre séances';
    case 'duree_max_min':
      return nombre == null ? 'Je ne sais pas' : '$nombre min';
  }
  return nombre == null ? 'Autre réponse' : '$nombre';
}

// ----------------------------------------------------------------------
// Codes koach.*
// ----------------------------------------------------------------------

String _texteKoach(String code, Map<String, Object?> p, NomExercice? noms) {
  final nom = _nomExercice(p['exercice'], noms);
  final ex = nom == null ? 'cet exercice' : '« $nom »';
  final cause = p['cause'];
  final zone = _zone(p['zone']);
  final part = _nombre(p['part']);
  switch (code) {
    case 'koach.douleur_persistante':
      return 'Ta douleur ${zone.a} dure : fais-la examiner par un médecin ou '
          'un kiné. En attendant, je ménage ${zone.nom}.';
    case 'koach.douleur_retrait':
      return _texteRetrait(cause, ex, zone);
    case 'koach.test_reporte':
      if (cause == 'bilan_bas') {
        return 'Test reporté sur $ex : ton bilan du jour est bas, ce n’est '
            'pas le jour pour te mesurer.';
      }
      if (cause == 'coupure') {
        return 'Test reporté sur $ex : tu reprends après une coupure, on se '
            'remet d’abord en route.';
      }
      return 'Test reporté sur $ex : ce n’est pas le bon jour pour te '
          'mesurer.';
    case 'koach.poignet_appui_neutre':
      final gene = _entier(p['intensite']);
      final sur10 = gene == null ? '' : ' ($gene/10)';
      return 'Ton poignet te gêne$sur10 : fais $ex sur un appui neutre '
          '(parallettes ou poignées), sans dépasser ce qui est prévu.';
    case 'koach.poignet_dose':
      return 'Poignet sensible : pas plus que la dose prévue sur $ex.';
    case 'koach.technique_retenue':
      final technique = _technique(p['technique']);
      final pourquoi = _causeTechnique(cause);
      return 'Je garde $technique pour plus tard sur $ex : $pourquoi.';
    case 'koach.reprise_coupure':
      final jours = _entier(p['jours']);
      final depuis = jours == null
          ? 'une coupure'
          : '$jours jours sans entraînement';
      return 'Tu reviens après $depuis : moins de séries sur $ex cette '
          'semaine.';
    case 'koach.surmenage':
      return _texteSurmenage(p, ex);
    case 'koach.reprise_dose':
      // 1.0.5 : rampe du réalisé après une douleur ou après une coupure
      // (règle 3 bis, sans douleur connue) : texte neutre.
      return 'Retour progressif : séries limitées sur $ex pour ménager '
          '${zone.nom}.';
    case 'koach.vrai_test':
      final sur = nom == null ? '' : ' sur $ex';
      return 'Test du jour$sur : une montée par paliers jusqu’à une série '
          'dure, pour mettre ton niveau à jour.';
    case 'koach.endurance_raccourcie':
      final combien = part == null
          ? 'moins que prévu'
          : '$part % de ce qui était prévu';
      return 'On raccourcit $ex : $combien (${_causeEndurance(cause)}).';
    case 'koach.course_facile':
      final remplacant = _nomExercice(p['remplacant'], noms);
      final facile = remplacant == null
          ? 'une course facile'
          : '« $remplacant »';
      return 'Aujourd’hui, $facile à la place de $ex '
          '(${_causeEndurance(cause)}).';
    case 'koach.endurance_retrait':
      return 'Pas de séance de qualité aujourd’hui sur $ex '
          '(${_causeEndurance(cause)}) : aucune course facile n’est '
          'faisable ici pour la remplacer.';
    case 'koach.course_bornee':
      if (part == null) {
        return 'Je raccourcis $ex : pas beaucoup plus long que ta plus '
            'longue sortie récente.';
      }
      return 'Je raccourcis $ex : pas plus de $part % au-dessus de ta '
          'plus longue sortie récente.';
    case 'koach.wod_echelle':
      final echelle = part == null
          ? 'allégé'
          : 'à $part % de ce qui était prévu';
      return 'Je mets $ex à l’échelle, $echelle '
          '(${_causeEndurance(cause)}).';
    case 'koach.fatigue_croisee':
      return 'Un peu plus de marge sur $ex : ta course d’hier était dure.';
    case 'koach.arret_exercice':
      if (cause == 'volume_test') {
        return 'On arrête $ex ici : la montée du test a déjà fait le volume '
            'prévu.';
      }
      return 'On arrête $ex ici : plusieurs séries ratées, inutile '
          'd’insister aujourd’hui.';
    case 'koach.zone_fragile':
      if (cause == 'surcharge') {
        return 'Charge limitée sur $ex : il sollicite ${zone.nom}, une zone '
            'fragile de ton profil.';
      }
      return 'Hausse plafonnée sur $ex : ${zone.nom} est une zone fragile '
          'de ton profil.';
    case 'koach.serie_repere':
      return 'Série repère sur $ex : fais-la au ressenti, jusqu’aux flammes '
          'visées ; elle me sert à régler la suite.';
    case 'koach.tendon':
      if (cause == 'total') {
        return 'Temps de tenue total limité sur $ex : tes tendons ont besoin '
            'de temps pour s’adapter.';
      }
      return 'Tenue limitée sur $ex : tes tendons ont besoin de temps pour '
          's’adapter.';
    case 'koach.retour_gradue':
      return _texteRetourGradue(p, ex);
    case 'koach.seance_bornee':
      final minutes = _entier(p['minutes']);
      final duree = minutes == null
          ? 'le temps dont tu disposes'
          : '$minutes min';
      return 'Je raccourcis ou retire $ex pour que ta séance tienne en '
          '$duree.';
  }
  return texteRaisonKoachGenerique;
}

String _texteRetrait(Object? cause, String ex, _Zone zone) {
  switch (cause) {
    case 'douleur':
      return 'Je retire $ex aujourd’hui : il sollicite ${zone.nom}, qui te '
          'fait mal.';
    case 'douleur_arret':
      return 'Je mets $ex de côté tant que ta douleur ${zone.a} n’est pas '
          'calmée.';
    case 'douleur_reprise':
      return 'Pas encore $ex : on reprend progressivement après ta douleur '
          '${zone.a}.';
    case 'poignet_chaud':
      return 'Je retire $ex : ton poignet est encore sensible et cet appui '
          'le charge trop.';
    case 'poignet_charge':
      return 'Je retire $ex : il charge trop le poignet tant qu’il te fait '
          'mal.';
    case 'reprise_dose':
      return 'Je retire $ex : la dose du jour pour ${zone.nom} est atteinte '
          '(retour progressif).';
  }
  return 'Je retire $ex aujourd’hui pour ménager une zone douloureuse.';
}

String _causeTechnique(Object? cause) {
  switch (cause) {
    case 'niveau':
      return 'elle demande plus d’expérience, tu fais la version classique';
    case 'douleur':
      return 'une douleur est en cours';
    case 'bilan':
      return 'ton bilan du jour est bas';
    case 'phase':
      return 'la semaine en cours ne s’y prête pas';
    case 'echeance':
      return 'ton échéance est trop proche';
    case 'antecedent':
      return 'elle chargerait une zone fragile de ton profil';
  }
  return 'ce n’est pas encore le bon moment';
}

String _texteSurmenage(Map<String, Object?> p, String ex) {
  final pourcent = _pourcent(p['part']);
  final series = _entier(p['series']);
  final niveau = pourcent == null
      ? ''
      : ' (environ $pourcent % de ton niveau habituel)';
  var moins = 'moins de séries';
  if (series != null) {
    moins = series <= 1 ? 'une série de moins' : '$series séries de moins';
  }
  return 'Ta performance sur $ex a baissé$niveau : $moins pour récupérer.';
}

String _texteRetourGradue(Map<String, Object?> p, String ex) {
  final groupe = p['groupe'];
  final series = _entier(p['series']);
  final secondes = _entier(p['secondes']);
  final limite = _nombre(p['limite']);
  if (groupe == 'allegement') {
    if (series == 0) {
      return 'Je retire $ex : c’est une semaine d’allègement et son volume '
          'est déjà atteint.';
    }
    final dures = limite == null ? '' : ' (au plus $limite séries dures)';
    return 'Semaine d’allègement : moins de séries sur $ex$dures.';
  }
  final String qui;
  final String borne;
  if (groupe is String && groupe.startsWith('bras_tendus')) {
    qui = _brasTendus(groupe);
    borne = limite == null ? '' : ' (au plus $limite s cette semaine)';
  } else {
    qui = _groupes[groupe] ?? 'ce groupe musculaire';
    borne = limite == null ? '' : ' (au plus $limite séries cette semaine)';
  }
  if (series == 0) {
    return 'Je retire $ex cette semaine : pour $qui, le volume que la '
        'reprise permet est déjà atteint$borne.';
  }
  if (secondes != null) {
    return 'Tenue raccourcie à $secondes s sur $ex : pour $qui, le volume '
        'remonte progressivement$borne.';
  }
  var combien = 'Moins de séries';
  if (series != null) {
    combien = series == 1 ? 'Une série' : '$series séries';
    // 1.0.6 : séries écrites de la ligne (`ecrites`), quand elles sont dites.
    final ecrites = _entier(p['ecrites']);
    if (ecrites != null && ecrites > series) {
      combien = '$combien au lieu de $ecrites';
    }
  }
  return '$combien sur $ex : pour $qui, le volume remonte '
      'progressivement$borne.';
}

String _brasTendus(String groupe) {
  switch (groupe) {
    case 'bras_tendus_push':
      return 'tes appuis bras tendus en poussée';
    case 'bras_tendus_pull':
      return 'tes appuis bras tendus en tirage';
  }
  return 'tes appuis bras tendus';
}

String _causeEndurance(Object? cause) {
  switch (cause) {
    case 'bilan':
      return 'ton bilan du jour est bas';
    case 'bilan_fort':
      return 'ton bilan du jour est très bas';
    case 'douleur_jambe':
      return 'tes jambes te font mal';
    case 'course_dure':
      return 'ta dernière course était dure';
    case 'jours_durs':
      return 'tu enchaînes les jours durs';
  }
  if (cause is String && cause.startsWith('reprise_')) {
    final jours = int.tryParse(cause.substring('reprise_'.length));
    if (jours != null && jours > 0) {
      return 'tu reprends après $jours jours sans entraînement';
    }
    return 'tu reprends après une coupure';
  }
  return 'pour te ménager aujourd’hui';
}

// ----------------------------------------------------------------------
// Surveillance hors modèle
// ----------------------------------------------------------------------

String _texteCause(String cause) {
  switch (cause) {
    case 'rupture':
      return 'Tes dernières séances ne ressemblent pas à ce que j’attendais : '
          'cette situation sort de mon modèle.';
    case 'residu':
      return 'Depuis deux semaines, tes performances s’écartent de mes '
          'prévisions : cette situation sort de mon modèle.';
    case 'assiduite':
      return 'Tu as fait nettement moins de séances que prévu ces dernières '
          'semaines : j’ai besoin de comprendre ce qui a changé.';
    case 'douleur':
      return 'Tu as signalé une douleur marquée récemment : j’ai besoin d’en '
          'savoir plus avant d’aller plus loin.';
  }
  return texteHorsModeleKoach;
}

String _texteAction(String action, Map<String, Object?> d) {
  switch (action) {
    case 'conduite_douleur':
      final zone = _zone(d['zone']);
      final gene = _entier(d['intensite']);
      final sur10 = gene == null ? '' : ' ($gene/10)';
      return 'Je ménage ${zone.nom}$sur10 et je te conseille de consulter un '
          'médecin ou un kiné si la douleur dure.';
    case 'replanifier':
      final disp = _objet(d['disponibilites']);
      final brutS = disp['seances_par_semaine'] ?? d['seances_par_semaine'];
      final brutM = disp['duree_max_min'] ?? d['duree_max_min'];
      final seances = _entier(brutS);
      final minutes = _entier(brutM);
      final morceaux = <String>[];
      if (seances == 1) {
        morceaux.add('1 séance par semaine');
      } else if (seances != null) {
        morceaux.add('$seances séances par semaine');
      }
      if (minutes != null) {
        morceaux.add('$minutes min au plus par séance');
      }
      if (morceaux.isEmpty) {
        return 'Noté : tu as moins de temps. Je tiens compte de la durée '
            'disponible de chaque séance.';
      }
      return 'Noté : ${morceaux.join(', ')}. Je tiens compte de la durée '
          'disponible de chaque séance ; le nombre de séances de ton '
          'programme ne change pas pour l’instant.';
    case 'semaine_allegee':
      final pourcent = _pourcent(d['series']);
      final rir = _nombre(d['rir']);
      final series = pourcent == null
          ? 'moins de séries'
          : 'environ $pourcent % des séries';
      final marge = rir == null
          ? 'plus de réserve'
          : '$rir répétition${_pluriel(d['rir'])} de réserve en plus';
      return 'Semaine allégée pendant 7 jours : $series et $marge.';
    case 'elargir':
      return 'D’accord : je reste plus ouvert sur ton niveau et je '
          'réapprends vite avec tes prochaines séances.';
  }
  return texteRaisonKoachGenerique;
}

// ----------------------------------------------------------------------
// Contrôle dual
// ----------------------------------------------------------------------

String? _texteDual(String code, NomExercice? noms) {
  if (code.startsWith('essai_demarre:')) {
    final semaine = _semaineAffichee(code.split(':')[1]);
    final quand = semaine == null ? 'cette semaine' : 'en semaine $semaine';
    return 'Petit essai lancé $quand : j’alterne deux façons de doser ton '
        'entraînement, dans les limites habituelles, pour voir celle qui '
        'te fait le plus progresser.';
  }
  if (code.startsWith('essai_refuse:')) {
    final champs = code.split(':');
    final reste = champs.length > 2 ? champs.sublist(2).join(':') : '';
    final raisons = <String>[];
    for (final r in reste.split(',')) {
      final t = _raisonRefusEssai(r.trim(), noms);
      if (t != null && !raisons.contains(t)) {
        raisons.add(t);
      }
    }
    if (raisons.isEmpty) {
      return 'Pas d’essai pour l’instant : ce n’est pas encore le bon '
          'moment.';
    }
    return 'Pas d’essai pour l’instant : ${raisons.join(' ; ')}.';
  }
  if (code.startsWith('essai_interrompu:')) {
    final raison = code.substring('essai_interrompu:'.length);
    var pourquoi = 'les conditions ont changé';
    if (raison == 'douleur') {
      pourquoi = 'tu as signalé une douleur';
    } else if (raison == 'alerte_hors_modele') {
      pourquoi = 'ta situation sort de mon modèle';
    }
    return 'J’arrête l’essai en cours : $pourquoi. Ton plan reprend son '
        'cours normal.';
  }
  if (code.startsWith('synthetique_impossible')) {
    return 'Je n’ai pas pu mesurer l’effet de l’essai cette semaine : pas '
        'assez de données de comparaison.';
  }
  return null;
}

String? _raisonRefusEssai(String r, NomExercice? noms) {
  switch (r) {
    case '':
      return null;
    case 'non_calibre':
      return 'je ne connais pas encore ton niveau assez précisément';
    case 'affutage':
      return 'tu es en affûtage';
    case 'alerte_hors_modele':
      return 'ta situation sort de mon modèle';
    case 'douleur':
      return 'une douleur est en cours';
    case 'echeance_proche':
      return 'ton échéance est trop proche';
    case 'essai_en_cours':
    case 'deja_en_cours':
      return 'un essai est déjà en cours';
    case 'deja_termine':
      return 'cet essai est déjà terminé';
    case 'deja_interrompu':
      return 'cet essai a été interrompu';
    case 'aucun_lift_principal':
      return 'ton programme n’a pas de mouvement principal chargé';
  }
  if (r.startsWith('deja_')) {
    return 'cet essai a déjà eu lieu';
  }
  if (r.startsWith('temoin_trop_court')) {
    return 'il me faut plus de semaines de comparaison avant de commencer';
  }
  if (r.startsWith('semaines_insuffisantes')) {
    return 'il me faut encore quelques semaines de journal';
  }
  if (r.startsWith('lift_inconnu')) {
    return 'je n’ai pas encore de mesure sur un de tes mouvements principaux';
  }
  if (r.startsWith('intervalle_large')) {
    final champs = r.split(':');
    final nom = champs.length > 1 ? _nomExercice(champs[1], noms) : null;
    final sur = nom == null ? 'un de tes mouvements principaux' : '« $nom »';
    return 'mon estimation sur $sur est encore trop large';
  }
  return 'les conditions ne sont pas réunies';
}

/// Semaine du moteur (indice global à partir de 0) → numéro affiché (à
/// partir de 1).
int? _semaineAffichee(String texte) {
  final s = int.tryParse(texte);
  return (s == null || s < 0) ? null : s + 1;
}

// ----------------------------------------------------------------------
// Libellés
// ----------------------------------------------------------------------

final class _Zone {
  const _Zone(this.libelle, this.nom, this.a);

  /// Choix du diagnostic (« Épaule »).
  final String libelle;

  /// Avec l'article (« l’épaule »).
  final String nom;

  /// Avec « à » (« à l’épaule »).
  final String a;
}

/// Zones du corps (`kalis_core` `BodyZone`, `libellesZones` de la
/// surveillance).
const Map<String, _Zone> _zones = <String, _Zone>{
  'neck': _Zone('Cou', 'le cou', 'au cou'),
  'shoulder': _Zone('Épaule', 'l’épaule', 'à l’épaule'),
  'elbow': _Zone('Coude', 'le coude', 'au coude'),
  'wrist_hand': _Zone(
    'Poignet, main',
    'le poignet ou la main',
    'au poignet ou à la main',
  ),
  'upper_back': _Zone('Haut du dos', 'le haut du dos', 'au haut du dos'),
  'lower_back': _Zone('Bas du dos', 'le bas du dos', 'au bas du dos'),
  'chest': _Zone('Poitrine', 'la poitrine', 'à la poitrine'),
  'abdomen': _Zone('Abdomen', 'l’abdomen', 'à l’abdomen'),
  'hip': _Zone('Hanche', 'la hanche', 'à la hanche'),
  'thigh': _Zone('Cuisse', 'la cuisse', 'à la cuisse'),
  'knee': _Zone('Genou', 'le genou', 'au genou'),
  'lower_leg': _Zone('Jambe', 'la jambe', 'à la jambe'),
  'ankle_foot': _Zone(
    'Cheville, pied',
    'la cheville ou le pied',
    'à la cheville ou au pied',
  ),
};

const _Zone _zoneInconnue = _Zone('Autre', 'cette zone', 'à cette zone');

_Zone _zone(Object? code) {
  final z = code is String ? _zones[code] : null;
  return z ?? _zoneInconnue;
}

/// Groupes majeurs du retour gradué (`securite.volume_groupes_majeurs`).
const Map<String, String> _groupes = <String, String>{
  'chest': 'tes pectoraux',
  'delt_anterior': 'l’avant de tes épaules',
  'delt_middle': 'le milieu de tes épaules',
  'delt_posterior': 'l’arrière de tes épaules',
  'lats': 'tes dorsaux',
  'upper_back': 'le haut de ton dos',
  'biceps': 'tes biceps',
  'triceps': 'tes triceps',
  'abs': 'tes abdominaux',
  'lower_back': 'tes lombaires',
  'glutes': 'tes fessiers',
  'quads': 'tes quadriceps',
  'hamstrings': 'tes ischio-jambiers',
  'calves': 'tes mollets',
};

/// Libellés des techniques (ceux de l'application, `techniqueLabel`).
const Map<String, String> _techniques = <String, String>{
  'top_set_backoff': 'série de tête puis séries allégées',
  'cluster': 'clusters',
  'rest_pause': 'rest-pause',
  'myo_reps': 'myo-reps',
  'drop_set': 'série dégressive',
  'isometric_hold': 'maintien chronométré',
  'accentuated_eccentric': 'descentes freinées',
  'contrast': 'contraste',
  'wave': 'vagues',
  'amrap': 'série au maximum',
  'emom': 'EMOM',
  'density': 'bloc de densité',
  'ladder': 'échelle',
  'pyramid': 'pyramide',
  'skill_practice': 'pratique de la figure',
  'for_time': 'contre la montre',
};

String _technique(Object? code) {
  final t = code is String ? _techniques[code] : null;
  return t == null ? 'cette technique' : 'la technique « $t »';
}

// ----------------------------------------------------------------------
// Outils
// ----------------------------------------------------------------------

Map<String, Object?> _objet(Object? v) {
  if (v is Map<String, Object?>) {
    return v;
  }
  if (v is Map<Object?, Object?>) {
    return <String, Object?>{for (final e in v.entries) '${e.key}': e.value};
  }
  return const <String, Object?>{};
}

const List<String> _prefixes = <String>[
  'surveillance.cause.',
  'surveillance.action.',
  'surveillance.',
];

String _sansPrefixe(String code) {
  for (final p in _prefixes) {
    if (code.startsWith(p)) {
      return code.substring(p.length);
    }
  }
  return code;
}

String? _nomExercice(Object? id, NomExercice? noms) {
  if (id is! String || id.isEmpty || noms == null) {
    return null;
  }
  final n = noms(id)?.trim();
  if (n == null || n.isEmpty || n == id) {
    return null;
  }
  return n;
}

num? _num(Object? v) {
  if (v is num) {
    return v.isFinite ? v : null;
  }
  if (v is String) {
    final x = num.tryParse(v.trim().replaceAll(',', '.'));
    return (x != null && x.isFinite) ? x : null;
  }
  return null;
}

int? _entier(Object? v) => _num(v)?.round();

/// Nombre à la française : entier tel quel, sinon une décimale au plus
/// (virgule).
String? _nombre(Object? v) {
  final x = _num(v);
  if (x == null) {
    return null;
  }
  final r = (x * 10).round() / 10;
  if (r == r.roundToDouble()) {
    return '${r.round()}';
  }
  return r.toStringAsFixed(1).replaceAll('.', ',');
}

/// Part (0 à 1) en pourcent entier.
int? _pourcent(Object? v) {
  final x = _num(v);
  return x == null ? null : (x * 100).round();
}

String _pluriel(Object? v) {
  final x = _num(v);
  return (x != null && x.abs() >= 2) ? 's' : '';
}
