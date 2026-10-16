import 'package:meta/meta.dart';

import 'art/koach_pose_art.g.dart';
import 'art/koach_pose_info.g.dart';
import 'koach_art.dart';

/// Émotion portée par une pose.
enum KoachEmotion {
  /// Explique, montre.
  explaining,

  /// Réfléchit.
  thinking,

  /// Curieux, enquête.
  curious,

  /// Fier.
  proud,

  /// Déterminé.
  determined,

  /// Salue.
  greeting,

  /// Approuve.
  approving,

  /// Content.
  happy,

  /// Hésite, ne sait pas.
  unsure,

  /// Désolé.
  sorry,

  /// Bienveillant, attentionné.
  caring,

  /// Plein d'énergie.
  energetic,

  /// Fête une réussite.
  celebrating,

  /// Encourage.
  encouraging,

  /// Accueille, présente.
  welcoming,
}

/// Usage recommandé d'une pose (pour choisir une pose hors des répliques).
enum KoachUsage {
  /// Réglage, ajustement.
  adjustment,

  /// Analyse.
  analysis,

  /// Calibrage.
  calibration,

  /// Annulation.
  cancel,

  /// Attention portée à l'utilisateur.
  care,

  /// Confirmation.
  confirmation,

  /// Choix à faire.
  decision,

  /// Session de test (mode dev).
  devSession,

  /// Encouragement.
  encouragement,

  /// Erreur.
  error,

  /// Fiche d'exercice.
  exercise,

  /// Explication.
  explanation,

  /// Nouveauté présentée la première fois.
  featureIntro,

  /// Objectif.
  goal,

  /// Bilan santé.
  healthCheck,

  /// Étape suivante.
  nextStep,

  /// Profil.
  profile,

  /// Programme.
  program,

  /// Progression.
  progress,

  /// Proposition de changement.
  proposal,

  /// Question posée.
  question,

  /// Record.
  record,

  /// Demande à l'utilisateur.
  request,

  /// Repos, récupération.
  rest,

  /// Revue du programme.
  review,

  /// Fin de séance.
  sessionEnd,

  /// Début de séance.
  sessionStart,

  /// Réglages.
  settings,

  /// Réussite.
  success,

  /// Remerciement.
  thanks,

  /// Astuce.
  tip,

  /// Information inconnue.
  unknown,

  /// Accueil.
  welcome,

  /// Explication « Pourquoi ? ».
  why,
}

/// Cadrage de la pose.
enum KoachFraming {
  /// En pied (pieds sur la ligne y = 0).
  full,

  /// Buste (coupe à la taille sur la ligne y = 0).
  bust,
}

/// Direction du regard (vue de trois quarts mesurée sur les yeux).
enum KoachGaze {
  /// Regarde vers la gauche de l'écran.
  left,

  /// De face.
  front,

  /// Regarde vers la droite de l'écran.
  right,
}

/// Côté de l'écran.
enum KoachSide {
  /// Gauche.
  left,

  /// Droite.
  right,
}

/// Fiche d'une pose : métadonnées, regard, côté conseillé de la bulle.
@immutable
class KoachPoseInfo {
  /// Crée une fiche (utilisé par le fichier généré).
  const KoachPoseInfo({
    required this.id,
    required this.sheet,
    required this.row,
    required this.col,
    required this.emotion,
    required this.usages,
    required this.eyesOpen,
    required this.framing,
    required this.gaze,
    required this.bubbleSide,
  });

  /// Identifiant stable (`explain_board`…).
  final String id;

  /// Planche source (A, B ou C).
  final String sheet;

  /// Ligne dans la planche (0 = haut).
  final int row;

  /// Colonne dans la planche (0 = gauche).
  final int col;

  /// Émotion.
  final KoachEmotion emotion;

  /// Usages recommandés.
  final List<KoachUsage> usages;

  /// Yeux ouverts (clignement possible) ou fermés.
  final bool eyesOpen;

  /// Cadrage.
  final KoachFraming framing;

  /// Regard.
  final KoachGaze gaze;

  /// Côté conseillé pour la bulle : côté du regard, sauf si un accessoire
  /// l'occupe (alors l'autre côté) ; de face : le côté le plus dégagé.
  final KoachSide bubbleSide;
}

/// Les 36 poses de Koach (planches A pédagogie, B émotions, C énergie).
enum KoachPose {
  /// A1 — tableau à chevalet montré avec une baguette.
  explainBoard('explain_board'),

  /// A2 — livre ouvert, index levé.
  readTip('read_tip'),

  /// A3 — planche anatomique montrée du doigt.
  anatomy('anatomy'),

  /// A4 — histogramme en hausse.
  progressChart('progress_chart'),

  /// A5 — doigt sur la tempe.
  think('think'),

  /// A6 — presse-papiers coché.
  checklist('checklist'),

  /// A7 — croix et coche (buste).
  choice('choice'),

  /// A8 — ampoule allumée (buste).
  idea('idea'),

  /// A9 — engrenage (buste).
  settings('settings'),

  /// A10 — poing serré, « ! ».
  determined('determined'),

  /// A11 — panneau directionnel.
  direction('direction'),

  /// A12 — loupe.
  analyze('analyze'),

  /// B1 — salut de la main.
  wave('wave'),

  /// B2 — pouce levé.
  thumbsUp('thumbs_up'),

  /// B3 — bras ouverts, yeux fermés de joie.
  happy('happy'),

  /// B4 — pointe à droite.
  point('point'),

  /// B5 — main au menton.
  ponder('ponder'),

  /// B6 — haussement d'épaules.
  shrug('shrug'),

  /// B7 — main sur le front.
  oops('oops'),

  /// B8 — mains jointes.
  please('please'),

  /// B9 — cœur avec les mains.
  love('love'),

  /// B10 — biceps et étincelle.
  flex('flex'),

  /// B11 — course.
  run('run'),

  /// B12 — bras levés, victoire.
  victory('victory'),

  /// C1 — pouce levé.
  thumbsUp2('thumbs_up_2'),

  /// C2 — bras levés, joie.
  cheer('cheer'),

  /// C3 — poing serré.
  pump('pump'),

  /// C4 — drapeau.
  flag('flag'),

  /// C5 — poing tendu vers toi.
  fistBump('fist_bump'),

  /// C6 — cœur, yeux fermés.
  heart('heart'),

  /// C7 — pointe vers toi.
  you('you'),

  /// C8 — double biceps.
  doubleBiceps('double_biceps'),

  /// C9 — applaudit.
  clap('clap'),

  /// C10 — sprint.
  sprint('sprint'),

  /// C11 — poing levé.
  fistUp('fist_up'),

  /// C12 — main tendue qui présente.
  present('present');

  const KoachPose(this.id);

  /// Identifiant stable (celui des planches et du stockage).
  final String id;

  /// Dessin vectoriel.
  KoachPoseArt get art => koachPoseArts[index];

  /// Fiche.
  KoachPoseInfo get info => koachPoseInfos[index];

  /// Pose d'identifiant [id], ou `null`.
  static KoachPose? byId(String id) {
    for (final p in values) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Poses recommandées pour un usage.
  static List<KoachPose> forUsage(KoachUsage usage) => [
    for (final p in values)
      if (p.info.usages.contains(usage)) p,
  ];
}

/// Cadre commun à toutes les poses (union des boîtes, marge de 40 unités) :
/// dessiner chaque pose dans ce cadre garde Koach à la même place et à la
/// même taille quand il change de pose.
final KoachBox koachCommonFrame = KoachPose.values
    .map((p) => p.art.bounds)
    .reduce((a, b) => a.union(b))
    .inflate(40);

/// Hauteur d'une pose en pied, en unités (pointe de la flamme → pieds).
const int koachBodyHeight = 1000;
