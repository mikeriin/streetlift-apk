import 'package:meta/meta.dart';

/// Opcode « déplacer » : `0 x y` (début d'un sous-chemin).
const int koachMoveTo = 0;

/// Opcode « ligne » : `1 x y`.
const int koachLineTo = 1;

/// Opcode « courbe cubique » : `2 x1 y1 x2 y2 x y`.
const int koachCubicTo = 2;

/// Opcode « fermer le sous-chemin » : `3`.
const int koachClose = 3;

/// Boîte englobante en unités Koach (`left`, `top` inclus ; `right`,
/// `bottom` : bord opposé). L'axe y descend : le haut a un `top` négatif.
@immutable
class KoachBox {
  /// Crée une boîte.
  const KoachBox(this.left, this.top, this.right, this.bottom);

  /// Bord gauche.
  final int left;

  /// Bord haut.
  final int top;

  /// Bord droit.
  final int right;

  /// Bord bas.
  final int bottom;

  /// Largeur.
  int get width => right - left;

  /// Hauteur.
  int get height => bottom - top;

  /// Centre horizontal.
  double get centerX => (left + right) / 2;

  /// Centre vertical.
  double get centerY => (top + bottom) / 2;

  /// Plus petite boîte contenant les deux.
  KoachBox union(KoachBox o) => KoachBox(
    left < o.left ? left : o.left,
    top < o.top ? top : o.top,
    right > o.right ? right : o.right,
    bottom > o.bottom ? bottom : o.bottom,
  );

  /// Agrandit la boîte de [m] unités de chaque côté.
  KoachBox inflate(int m) => KoachBox(left - m, top - m, right + m, bottom + m);

  /// Vrai si le point est dans la boîte (bords compris).
  bool contains(num x, num y) =>
      x >= left && x <= right && y >= top && y <= bottom;

  @override
  bool operator ==(Object other) =>
      other is KoachBox &&
      other.left == left &&
      other.top == top &&
      other.right == right &&
      other.bottom == bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);

  @override
  String toString() => 'KoachBox($left, $top, $right, $bottom)';
}

/// Dessin d'une pose de Koach : trois calques de commandes numériques,
/// remplissage pair-impair (even-odd), voir CONTRAT.md.
///
/// Repère : x = 0 au milieu des yeux, y = 0 sur la ligne des pieds (ou la
/// coupe d'un buste), y négatif vers le haut ; une pose en pied mesure 1 000
/// unités de la pointe de la flamme aux pieds.
@immutable
class KoachPoseArt {
  /// Crée un dessin (utilisé par le fichier généré).
  const KoachPoseArt({
    required this.id,
    required this.bounds,
    required this.eyeBoxes,
    required this.ink,
    required this.paper,
    required this.eyes,
  });

  /// Identifiant de la pose (celui de [KoachPose.id]).
  final String id;

  /// Boîte englobante du calque encre.
  final KoachBox bounds;

  /// Boîtes des deux yeux ouverts (gauche puis droite), vide si yeux fermés :
  /// centre du clignement.
  final List<KoachBox> eyeBoxes;

  /// Calque encre : silhouette et accessoires (yeux ouverts compris, couverts
  /// ensuite par le calque yeux).
  final List<int> ink;

  /// Calque papier : parties blanches à l'intérieur de la silhouette (K,
  /// yeux fermés, intérieur des accessoires, traits de séparation).
  final List<int> paper;

  /// Calque yeux : les deux yeux ouverts (vide si la pose a les yeux fermés).
  final List<int> eyes;

  /// Vrai si la pose a les yeux ouverts (clignement possible).
  bool get eyesOpen => eyes.isNotEmpty;
}

/// Dessin d'une flamme de difficulté (D5.3) : silhouette pleine, creux du
/// bas, et encre (= silhouette moins creux). Repère : x = 0 au centre, y = 0
/// à la base ; la flamme 10 mesure 1 000 unités de haut, les autres gardent
/// leurs tailles relatives d'origine.
@immutable
class KoachFlameArt {
  /// Crée un dessin de flamme (utilisé par le fichier généré).
  const KoachFlameArt({
    required this.level,
    required this.bounds,
    required this.ink,
    required this.outline,
    required this.hollow,
  });

  /// Niveau 1 à 10.
  final int level;

  /// Boîte englobante de la silhouette.
  final KoachBox bounds;

  /// Encre : la flamme telle que dessinée (creux évidé).
  final List<int> ink;

  /// Silhouette extérieure pleine (creux rempli).
  final List<int> outline;

  /// Creux intérieur (ouvert vers le bas sur le dessin d'origine).
  final List<int> hollow;
}

/// Visiteur des commandes d'un calque : reçoit chaque commande dans l'ordre.
/// L'application l'implémente pour construire un `Path` Flutter.
abstract interface class KoachPathSink {
  /// Début d'un sous-chemin.
  void moveTo(double x, double y);

  /// Segment de droite.
  void lineTo(double x, double y);

  /// Courbe de Bézier cubique.
  void cubicTo(double x1, double y1, double x2, double y2, double x, double y);

  /// Fermeture du sous-chemin courant.
  void close();
}

/// Erreur de format d'un calque.
class KoachArtFormatException implements Exception {
  /// Crée l'erreur.
  KoachArtFormatException(this.message);

  /// Description.
  final String message;

  @override
  String toString() => 'KoachArtFormatException: $message';
}

/// Rejoue les commandes [cmds] dans [sink], avec une mise à l'échelle et une
/// translation facultatives : (x, y) → (x × scale + dx, y × scale + dy).
void replayKoachPath(
  List<int> cmds,
  KoachPathSink sink, {
  double scale = 1,
  double dx = 0,
  double dy = 0,
}) {
  double px(int v) => v * scale + dx;
  double py(int v) => v * scale + dy;
  var i = 0;
  while (i < cmds.length) {
    final op = cmds[i];
    switch (op) {
      case koachMoveTo:
        _need(cmds, i, 3);
        sink.moveTo(px(cmds[i + 1]), py(cmds[i + 2]));
        i += 3;
      case koachLineTo:
        _need(cmds, i, 3);
        sink.lineTo(px(cmds[i + 1]), py(cmds[i + 2]));
        i += 3;
      case koachCubicTo:
        _need(cmds, i, 7);
        sink.cubicTo(
          px(cmds[i + 1]),
          py(cmds[i + 2]),
          px(cmds[i + 3]),
          py(cmds[i + 4]),
          px(cmds[i + 5]),
          py(cmds[i + 6]),
        );
        i += 7;
      case koachClose:
        sink.close();
        i += 1;
      default:
        throw KoachArtFormatException('opcode $op inconnu à la position $i');
    }
  }
}

void _need(List<int> cmds, int i, int n) {
  if (i + n > cmds.length) {
    throw KoachArtFormatException('commande tronquée à la position $i');
  }
}

/// Statistiques d'un calque (contrôle et rapport).
@immutable
class KoachPathStats {
  /// Crée les statistiques.
  const KoachPathStats({
    required this.subpaths,
    required this.lines,
    required this.cubics,
    required this.allClosed,
  });

  /// Nombre de sous-chemins.
  final int subpaths;

  /// Nombre de segments de droite.
  final int lines;

  /// Nombre de courbes cubiques.
  final int cubics;

  /// Vrai si chaque sous-chemin se termine par une fermeture.
  final bool allClosed;
}

/// Analyse un calque et vérifie sa forme (lève [KoachArtFormatException]).
KoachPathStats koachPathStats(List<int> cmds) {
  var subpaths = 0, lines = 0, cubics = 0;
  var open = false;
  var allClosed = true;
  final sink = _CountingSink(
    onMove: () {
      if (open) allClosed = false;
      subpaths++;
      open = true;
    },
    onLine: () {
      if (!open) throw KoachArtFormatException('segment hors sous-chemin');
      lines++;
    },
    onCubic: () {
      if (!open) throw KoachArtFormatException('courbe hors sous-chemin');
      cubics++;
    },
    onClose: () {
      if (!open) throw KoachArtFormatException('fermeture sans sous-chemin');
      open = false;
    },
  );
  replayKoachPath(cmds, sink);
  if (open) allClosed = false;
  return KoachPathStats(
    subpaths: subpaths,
    lines: lines,
    cubics: cubics,
    allClosed: allClosed,
  );
}

/// Boîte englobante des points (extrémités et points de contrôle) d'un
/// calque ; `null` si le calque est vide.
KoachBox? koachControlBounds(List<int> cmds) {
  int? l, t, r, b;
  var i = 0;
  void add(int x, int y) {
    l = (l == null || x < l!) ? x : l;
    r = (r == null || x > r!) ? x : r;
    t = (t == null || y < t!) ? y : t;
    b = (b == null || y > b!) ? y : b;
  }

  while (i < cmds.length) {
    switch (cmds[i]) {
      case koachMoveTo || koachLineTo:
        add(cmds[i + 1], cmds[i + 2]);
        i += 3;
      case koachCubicTo:
        add(cmds[i + 1], cmds[i + 2]);
        add(cmds[i + 3], cmds[i + 4]);
        add(cmds[i + 5], cmds[i + 6]);
        i += 7;
      default:
        i += 1;
    }
  }
  if (l == null) return null;
  return KoachBox(l!, t!, r!, b!);
}

class _CountingSink implements KoachPathSink {
  _CountingSink({
    required this.onMove,
    required this.onLine,
    required this.onCubic,
    required this.onClose,
  });
  final void Function() onMove;
  final void Function() onLine;
  final void Function() onCubic;
  final void Function() onClose;

  @override
  void moveTo(double x, double y) => onMove();
  @override
  void lineTo(double x, double y) => onLine();
  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x,
    double y,
  ) => onCubic();
  @override
  void close() => onClose();
}

/// Écrit un calque en données de chemin SVG (`d`), pour les rapports.
String koachPathToSvg(List<int> cmds) {
  final b = StringBuffer();
  var i = 0;
  while (i < cmds.length) {
    switch (cmds[i]) {
      case koachMoveTo:
        b.write('M${cmds[i + 1]} ${cmds[i + 2]}');
        i += 3;
      case koachLineTo:
        b.write('L${cmds[i + 1]} ${cmds[i + 2]}');
        i += 3;
      case koachCubicTo:
        b.write(
          'C${cmds[i + 1]} ${cmds[i + 2]} ${cmds[i + 3]} '
          '${cmds[i + 4]} ${cmds[i + 5]} ${cmds[i + 6]}',
        );
        i += 7;
      case koachClose:
        b.write('Z');
        i += 1;
      default:
        throw KoachArtFormatException('opcode ${cmds[i]} inconnu');
    }
  }
  return b.toString();
}
