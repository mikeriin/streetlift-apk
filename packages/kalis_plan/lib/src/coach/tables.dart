/// Tables du chemin street : mouvements piliers, échelles de figures,
/// variantes par point faible, candidats d'assistance. Les identifiants
/// sont ceux du catalogue 1.1 ; un identifiant absent ou inadmissible est
/// simplement sauté (`Athlete.pick`).
library;

import 'package:kalis_core/kalis_core.dart';

/// Identifiants des mouvements piliers.
abstract final class Ids {
  /// Traction lestée de compétition.
  static const String weightedPull = 'sl-traction-lestee';

  /// Dips lesté de compétition.
  static const String weightedDip = 'sl-dips-leste';

  /// Muscle-up lesté de compétition.
  static const String weightedMuscleUp = 'sl-muscle-up-leste';

  /// Squat de compétition.
  static const String squat = 'sl-squat-competition';

  /// Traction pronation.
  static const String pull = 'sw-traction-pronation';

  /// Dips aux barres parallèles.
  static const String dip = 'sw-dips-barres-paralleles';

  /// Pompe classique.
  static const String pushUp = 'sw-pompe';

  /// Muscle-up strict à la barre.
  static const String muscleUp = 'cd-muscle-up-barre-strict';

  /// Row australien.
  static const String row = 'sw-row-australien';

  /// Footing en endurance fondamentale.
  static const String easyRun = 'ca-footing-endurance-fondamentale';

  /// Sortie longue.
  static const String longRun = 'ca-sortie-longue';
}

/// Échelles de figures, de l'étape la plus facile à la figure.
const Map<String, List<String>> skillLadders = <String, List<String>>{
  'cs-front-lever': <String>[
    'cs-front-lever-tuck',
    'cs-front-lever-tuck-avance',
    'cs-front-lever-une-jambe',
    'cs-front-lever-straddle',
    'cs-front-lever-half-lay',
    'cs-front-lever',
  ],
  'cs-planche': <String>[
    'cs-planche-lean',
    'cs-planche-tuck',
    'cs-planche-tuck-avancee',
    'cs-planche-straddle',
    'cs-planche-half-lay',
    'cs-planche',
  ],
  'cs-back-lever': <String>[
    'cs-back-lever-tuck',
    'cs-back-lever-tuck-avance',
    'cs-back-lever-une-jambe',
    'cs-back-lever-straddle',
    'cs-back-lever-half-lay',
    'cs-back-lever',
  ],
  'cs-handstand': <String>[
    'cs-handstand-ventre-au-mur',
    'cs-handstand-dos-au-mur',
    'cs-handstand',
  ],
  'cs-l-sit': <String>['cs-l-sit-tuck', 'cs-l-sit-une-jambe', 'cs-l-sit'],
  'cs-drapeau-humain': <String>[
    'cs-drapeau-vertical',
    'cs-drapeau-tuck',
    'cs-drapeau-tuck-avance',
    'cs-drapeau-une-jambe',
    'cs-drapeau-straddle',
    'cs-drapeau-humain',
  ],
  'cd-muscle-up-barre-strict': <String>[
    'cd-muscle-up-barre-basse-pieds-au-sol',
    'cd-muscle-up-barre-negatif',
    'cd-muscle-up-barre-assiste-elastique',
    'cd-muscle-up-barre-strict',
  ],
};

/// Travail dynamique dans le schéma d'une figure, par rang d'étape (du
/// plus facile au plus dur).
const Map<String, List<String>> skillDynamics = <String, List<String>>{
  'cs-front-lever': <String>[
    'cd-front-lever-raise-tuck',
    'cd-front-lever-raise-tuck-avance',
    'cd-front-lever-row-tuck',
    'cd-ice-cream-maker-tuck',
    'cd-front-lever-raise-straddle',
    'cd-ice-cream-maker',
  ],
  'cs-planche': <String>[
    'cd-pompe-pseudo-planche',
    'cd-pompe-pseudo-planche-parallettes',
    'cd-planche-pushup-tuck',
    'cd-planche-pushup-tuck-avance',
    'cd-planche-pushup-straddle-elastique',
    'cd-planche-pushup-straddle',
  ],
  'cs-back-lever': <String>[
    'cd-skin-the-cat-groupe',
    'cd-back-lever-pull-tuck',
    'cd-skin-the-cat',
    'cd-back-lever-pull-complet',
  ],
  'cs-handstand': <String>[
    'cd-wall-walk',
    'cd-shoulder-taps-mur',
    'cd-hspu-negatif-mur',
    'cd-hspu-mur-dos',
  ],
  'cd-muscle-up-barre-strict': <String>[
    'cd-traction-explosive-poitrine-barre',
    'sw-dips-barre-droite',
  ],
};

/// Variante d'un mouvement lesté par point faible.
const Map<String, Map<WeakPointKind, List<String>>> weakPointVariants =
    <String, Map<WeakPointKind, List<String>>>{
      Ids.weightedPull: <WeakPointKind, List<String>>{
        WeakPointKind.bottom: <String>['sl-traction-lestee-pause-bas'],
        WeakPointKind.deadStart: <String>['sl-traction-lestee-pause-bas'],
        WeakPointKind.midRange: <String>['sl-traction-lestee-pause-mi-course'],
        WeakPointKind.lockout: <String>['sl-traction-lestee-pause-haut'],
        WeakPointKind.speed: <String>['sl-traction-haute-lestee'],
        WeakPointKind.grip: <String>['sl-dead-hang-leste'],
      },
      Ids.weightedDip: <WeakPointKind, List<String>>{
        WeakPointKind.bottom: <String>['sl-dips-leste-pause-bas'],
        WeakPointKind.deadStart: <String>[
          'sl-dips-leste-depart-bas',
          'sl-dips-leste-pause-bas',
        ],
        WeakPointKind.midRange: <String>['sl-dips-leste-pause-mi-course'],
        WeakPointKind.lockout: <String>[
          'sl-dips-leste-partiel-haut',
          'sl-dips-leste-prise-serree',
          'sl-dips-leste-pause-mi-course',
        ],
      },
      Ids.weightedMuscleUp: <WeakPointKind, List<String>>{
        WeakPointKind.transition: <String>[
          'sl-traction-haute-lestee',
          'sl-dips-barre-fixe-leste',
        ],
        WeakPointKind.bottom: <String>['sl-traction-haute-lestee'],
        WeakPointKind.lockout: <String>['sl-dips-barre-fixe-leste'],
        WeakPointKind.speed: <String>['sl-traction-haute-lestee'],
      },
      Ids.squat: <WeakPointKind, List<String>>{
        WeakPointKind.bottom: <String>['sl-squat-pause-bas'],
        WeakPointKind.deadStart: <String>['sl-pin-squat', 'sl-squat-pause-bas'],
        WeakPointKind.midRange: <String>[
          'sl-squat-pause-mi-descente',
          'sl-pin-squat',
        ],
        WeakPointKind.lockout: <String>['sl-squat-pause-mi-descente'],
      },
      Ids.muscleUp: <WeakPointKind, List<String>>{
        WeakPointKind.transition: <String>[
          'cd-muscle-up-barre-negatif',
          'cd-muscle-up-barre-assiste-elastique',
          'cd-traction-explosive-poitrine-barre',
        ],
      },
    };

/// Candidats d'assistance, par besoin, du plus souhaité au repli.
abstract final class Picks {
  /// Tirage horizontal.
  static const List<String> row = <String>[
    'mu-rowing-barre-pronation',
    'mu-rowing-haltere-unilateral-banc',
    'mu-rowing-halteres-buste-penche',
    'sw-row-australien-pieds-sureleves',
    'sw-row-australien-anneaux',
    'sw-row-australien',
    'sw-row-australien-barres-paralleles',
    'sw-row-australien-genoux-flechis',
  ];

  /// Tirage horizontal au poids du corps (parc).
  static const List<String> bodyweightRow = <String>[
    'sw-row-australien-anneaux',
    'sw-row-australien',
    'sw-row-australien-barres-paralleles',
    'sw-row-australien-genoux-flechis',
  ];

  /// Tirage horizontal du débutant.
  static const List<String> easyRow = <String>[
    'sw-row-australien-genoux-flechis',
    'sw-row-australien',
    'sw-row-australien-barres-paralleles',
  ];

  /// Arrière d'épaule et scapulas, sans grand dorsal.
  static const List<String> rearDelt = <String>[
    'mu-face-pull-corde',
    'mu-face-pull-elastique',
    'mu-band-pull-apart',
    'mu-oiseau-halteres',
    'sw-row-scapulaire',
  ];

  /// Coiffe des rotateurs.
  static const List<String> cuff = <String>[
    'mu-rotation-externe-poulie',
    'mu-rotation-externe-elastique',
    'mu-rotation-externe-haltere-couche',
    'mu-band-pull-apart',
  ];

  /// Fléchisseurs du coude, charge légère.
  static const List<String> curl = <String>[
    'mu-curl-marteau-halteres',
    'mu-curl-marteau-corde-poulie',
  ];

  /// Chaîne postérieure.
  static const List<String> hinge = <String>[
    'mu-souleve-de-terre-roumain-barre',
    'mu-souleve-de-terre-roumain-halteres',
    'mu-hip-thrust-unilateral',
    'mu-pont-fessier-unilateral',
    'mu-pont-fessier-sol',
  ];

  /// Ischio-jambiers au poids du corps (progression prudente).
  static const List<String> hamstring = <String>[
    'mu-nordic-hamstring-curl-assiste',
    'mu-pont-fessier-unilateral',
    'mu-pont-fessier-sol',
  ];

  /// Jambes en unilatéral, salle.
  static const List<String> gymSingleLeg = <String>[
    'mu-fente-arriere-halteres',
    'mu-split-squat',
    'mu-split-squat-bulgare-poids-du-corps',
    'mu-fente-arriere-poids-du-corps',
  ];

  /// Jambes au poids du corps, du plus dur au plus facile.
  static const List<String> bodyweightLegs = <String>[
    'sw-pistol-squat',
    'sw-shrimp-squat',
    'sw-pistol-squat-assis-box',
    'sw-skater-squat',
    'sw-shrimp-squat-bras-libres',
    'mu-split-squat-bulgare-poids-du-corps',
    'mu-fente-arriere-poids-du-corps',
    'mu-air-squat',
  ];

  /// Second mouvement de jambes au poids du corps.
  static const List<String> bodyweightLegsSecond = <String>[
    'mu-fente-arriere-poids-du-corps',
    'mu-cossack-squat',
    'mu-fente-laterale',
    'mu-air-squat',
  ];

  /// Jambes du débutant.
  static const List<String> beginnerSquat = <String>[
    'mu-air-squat',
    'mu-wall-sit',
  ];

  /// Fentes du débutant.
  static const List<String> beginnerLunge = <String>[
    'mu-fente-arriere-poids-du-corps',
    'mu-step-up-lateral',
    'mu-air-squat',
  ];

  /// Hanche du débutant.
  static const List<String> beginnerHip = <String>[
    'mu-pont-fessier-sol',
    'mu-pont-fessier-unilateral',
  ];

  /// Tronc, anti-extension et flexion de hanche, du plus dur au plus
  /// facile.
  static const List<String> core = <String>[
    'sw-releve-jambes-tendues-suspendu',
    'mu-hollow-body-hold',
    'sw-releve-genoux-suspendu',
    'mu-gainage-ventral-coudes',
    'mu-dead-bug',
  ];

  /// Tronc du débutant.
  static const List<String> beginnerCore = <String>[
    'mu-dead-bug',
    'mu-gainage-ventral-coudes',
    'mu-hollow-body-groupe',
  ];

  /// Tronc latéral.
  static const List<String> sideCore = <String>[
    'mu-gainage-lateral-coude',
    'mu-gainage-lateral-genoux',
  ];

  /// Gainage spécifique des figures (creux, compression).
  static const List<String> skillCore = <String>[
    'cs-l-sit',
    'cs-l-sit-barres-paralleles',
    'mu-hollow-body-hold',
    'cs-l-sit-tuck',
    'mu-hollow-body-groupe',
  ];

  /// Préparation des poignets.
  static const List<String> wristPrep = <String>[
    'mo-wrist-push-ups',
    'mo-rotations-poignets',
    'mo-pressions-doigts-appui',
  ];

  /// Préparation des épaules et des scapulas.
  static const List<String> shoulderPrep = <String>[
    'sw-traction-scapulaire',
    'sw-pompe-scapulaire',
    'mo-cars-epaule',
    'sw-row-scapulaire',
  ];

  /// Préparation de la suspension.
  static const List<String> hangPrep = <String>[
    'sw-active-hang',
    'sw-traction-scapulaire',
    'sw-dead-hang',
  ];

  /// Préparation des coudes.
  static const List<String> elbowPrep = <String>['mo-rotations-coudes-appui'];

  /// Traction, variantes dures sans lest.
  static const List<String> hardPull = <String>[
    'sw-traction-chest-to-bar',
    'sw-traction-l-sit',
    'sw-traction-typewriter',
    'sw-traction-archer',
    'sw-traction-large',
  ];

  /// Dips, variantes dures sans lest.
  static const List<String> hardDip = <String>[
    'sw-dips-anneaux',
    'sw-dips-buste-penche',
    'cd-dips-russes',
  ];

  /// Pompes, variantes dures sans lest.
  static const List<String> hardPushUp = <String>[
    'cd-pompe-pseudo-planche',
    'sw-pompe-declinee',
    'sw-pompe-archer',
    'sw-pompe-diamant',
  ];

  /// Traction assistée du débutant.
  static const List<String> assistedPull = <String>[
    'sw-traction-assistee-elastique',
    'sw-traction-assistee-pieds-au-sol',
  ];

  /// Pompe adaptée du débutant, de la plus dure à la plus facile.
  static const List<String> easyPushUp = <String>[
    'sw-pompe-inclinee',
    'sw-pompe-genoux',
    'sw-pompe-murale',
  ];

  /// Dips adaptés du débutant.
  static const List<String> assistedDip = <String>[
    'sw-dips-assistes-elastique',
    'sw-dips-assistes-pieds',
    'sw-dips-negatifs',
  ];

  /// Séance de qualité en course.
  static const List<String> runQuality = <String>[
    'ca-fractionne-400m',
    'ca-course-30-30',
    'ca-fartlek',
    'ca-cotes-longues',
  ];

  /// Mobilité de fin de séance.
  static const List<String> mobility = <String>[
    'mo-routine-mobilite-epaules-poignets',
    'mo-cat-cow',
    'mo-squat-profond-tenu',
  ];
}
