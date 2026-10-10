import 'package:flutter/material.dart';

import 'kit/dock.dart';

/// Dock flottant de l'application : quatre destinations stables (Arsenal,
/// Stats, Programme, Réglages), ouverture sur Programme, libellé sur
/// l'onglet actif seulement. UI0 (refonte UI, C8) : rendu par le dock du kit
/// ([KDock] : hauteur 64, pilule de l'onglet actif en `pleine`) ; même
/// ordre, mêmes noms, mêmes clés (`nav-0`…), même accessibilité.
class HeroNavBar extends StatelessWidget {
  /// Réserve de défilement des quatre onglets, hors zone système : le
  /// contenu s'arrête 16 dp au-dessus du dock (C8). `main.dart` l'ajoute au
  /// défilement.
  static const double extent = KDock.reserve;

  static const List<KDockItem> items = [
    KDockItem(Icons.grid_view_rounded, 'Arsenal'),
    KDockItem(Icons.insights_rounded, 'Stats'),
    KDockItem(Icons.fitness_center_rounded, 'Programme'),
    KDockItem(Icons.settings_outlined, 'Réglages'),
  ];

  final int index;
  final ValueChanged<int> onTap;
  const HeroNavBar({super.key, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) =>
      KDock(items: items, index: index, onTap: onTap);
}
