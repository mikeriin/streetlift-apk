/// Courbe des niveaux : 1 à 100, puis prestige (D7.4).
library;

import 'package:kalis_core/kalis_core.dart';

import 'numeric.dart';
import 'params.dart';

/// Courbe des niveaux d'un jeu de paramètres.
///
/// Passer du niveau `n` au niveau `n + 1` coûte
/// `5 × arrondi(levelScale × n^0,875 / 5)` XP, avec `n^0,875 = √√√(n⁷)` : la
/// racine carrée est exacte en IEEE 754, donc la table est la même sur
/// toute machine. Le niveau 100 a lui aussi son coût : le franchir fait
/// passer un prestige (niveau affiché 1, XP total conservé).
final class LevelCurve {
  /// Courbe des paramètres [params].
  LevelCurve(QuestParams params)
    : costs = List<int>.unmodifiable(<int>[
        for (var n = 1; n <= maxLevel; n++) _cost(n, params.levelScale),
      ]) {
    var sum = 0;
    final totals = <int>[0];
    for (final c in costs) {
      sum += c;
      totals.add(sum);
    }
    thresholds = List<int>.unmodifiable(totals);
  }

  /// Niveau le plus haut.
  static const int maxLevel = 100;

  static int _cost(int n, double scale) {
    final n2 = n * n;
    final seventh = (n2 * n2 * n2 * n).toDouble();
    final c = 5 * (scale * sqrt(sqrt(sqrt(seventh))) / 5).round();
    return c < 5 ? 5 : c;
  }

  /// Coût du niveau `n` au suivant, à l'indice `n − 1`.
  final List<int> costs;

  /// XP cumulé à l'entrée du niveau `n`, à l'indice `n − 1` ; le dernier
  /// élément (indice 100) est l'XP d'un prestige complet.
  late final List<int> thresholds;

  /// XP d'un prestige complet (niveaux 1 à 100 franchis).
  int get prestigeSpan => thresholds[maxLevel];

  /// XP total à l'entrée du niveau [level] du premier tour.
  int xpAt(int level) => thresholds[clampInt(level, 1, maxLevel + 1) - 1];

  /// Niveau et prestige pour [totalXp] XP acquis.
  LevelState stateOf(int totalXp) {
    final xp = totalXp < 0 ? 0 : totalXp;
    final prestige = xp ~/ prestigeSpan;
    final within = xp - prestige * prestigeSpan;
    var low = 0;
    var high = maxLevel - 1;
    while (low < high) {
      final mid = (low + high + 1) ~/ 2;
      if (thresholds[mid] <= within) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return LevelState(
      level: low + 1,
      prestige: prestige,
      totalXp: xp,
      xpIntoLevel: within - thresholds[low],
      xpForNextLevel: costs[low],
    );
  }

  /// Rang global d'un état : `prestige × 100 + niveau`, qui ne baisse
  /// jamais quand l'XP total augmente.
  static int ordinal(LevelState s) => s.prestige * maxLevel + s.level;
}
