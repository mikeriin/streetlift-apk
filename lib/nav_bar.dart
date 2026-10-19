import 'package:flutter/material.dart';

import 'kit/dock.dart';

/// Onglets de la racine, dans l'ordre du dock : [index] est la position de
/// l'onglet (clé `nav-<index>` de son bouton). Ouverture sur [program].
enum AppTab { arsenal, stats, program, settings }

/// UI5 (refonte UI, R6) : changement d'onglet depuis n'importe quel écran,
/// y compris une page empilée au-dessus des onglets (Records, relecture
/// d'une séance) ou une feuille ouverte.
///
/// La racine (`RootNav`, `main.dart`) se lie au montage et se délie au
/// démontage ; [open] ferme alors tout ce qui est empilé au-dessus de la
/// racine (routes poussées, feuilles, dialogues du navigateur racine) puis
/// sélectionne l'onglet, comme un appui sur le dock. Sans racine montée
/// (écran testé seul), [open] ne fait rien et rend `false`.
///
/// ```dart
/// KEmpty(
///   …,
///   action: 'Ouvrir le programme',
///   onAction: () => openTab(context, AppTab.program),
/// )
/// ```
class AppTabs {
  AppTabs._();

  static Object? _owner;
  static ValueChanged<AppTab>? _select;

  /// Une racine est montée : [open] changera d'onglet.
  static bool get bound => _select != null;

  /// Lie la racine [owner] : [select] sélectionne un onglet.
  static void bind(Object owner, ValueChanged<AppTab> select) {
    _owner = owner;
    _select = select;
  }

  /// Délie [owner], s'il est encore la racine liée.
  static void unbind(Object owner) {
    if (!identical(owner, _owner)) return;
    _owner = null;
    _select = null;
  }

  /// Ramène à la racine (routes empilées fermées) et sélectionne [tab].
  /// Rend `false` sans racine montée (rien n'est fermé).
  static bool open(BuildContext context, AppTab tab) {
    final select = _select;
    if (select == null) return false;
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.popUntil((route) => route.isFirst);
    select(tab);
    return true;
  }
}

/// Raccourci de [AppTabs.open] : ouvre l'onglet [tab] depuis [context].
bool openTab(BuildContext context, AppTab tab) => AppTabs.open(context, tab);

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

  /// Une entrée par [AppTab], dans le même ordre.
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
