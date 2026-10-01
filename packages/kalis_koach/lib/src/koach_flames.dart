import 'art/koach_flame_art.g.dart';
import 'koach_art.dart';

/// Nombre de flammes de l'échelle de difficulté (D5.3).
const int koachFlameLevels = 10;

/// Dessin de la flamme de niveau [level] (1 à 10).
KoachFlameArt koachFlame(int level) {
  if (level < 1 || level > koachFlameLevels) {
    throw RangeError.range(level, 1, koachFlameLevels, 'level');
  }
  return koachFlameArts[level - 1];
}

/// Position de la flamme [level] dans le dégradé de la couleur dominante
/// (D5.5) : 0 = teinte la plus claire (flamme 1), 1 = teinte la plus vive
/// (flamme 10), linéaire. L'application interpole elle-même ses couleurs.
double koachFlameTint(int level) {
  koachFlame(level);
  return (level - 1) / (koachFlameLevels - 1);
}

/// Libellé d'accessibilité d'une flamme (l'information ne passe jamais par
/// la seule couleur ni la seule taille).
String koachFlameLabel(int level) {
  koachFlame(level);
  return 'Difficulté $level sur $koachFlameLevels';
}

/// Cadre commun aux 10 flammes (union des boîtes) : dessinées dans ce cadre,
/// elles gardent leurs tailles relatives et la même ligne de base.
final KoachBox koachFlameFrame = koachFlameArts
    .map((f) => f.bounds)
    .reduce((a, b) => a.union(b));
