# Audit 2.2.4 — Dock à libellé actif

Date : 22 septembre 2026. Version 2.2.4+47 (2.2.3+46 précédente).

## Périmètre

Un seul fichier de code modifié : `lib/nav_bar.dart` (réécrit). Version
incrémentée dans `pubspec.yaml`, `lib/settings_screen.dart` (`kAppVersion`)
et `test/visual_capture_test.dart` (dossier de captures). README et checklist
2.2.3 archivés dans `docs/`.

## Vérifications effectuées ici

- Lecture croisée de `main.dart` (`RootNav`) : l’inset de défilement lit
  `HeroNavBar.extent` ; la nouvelle valeur (84) est cohérente avec la hauteur
  réelle du dock (8 + 64 + 12) et la `SafeArea` inférieure reste ajoutée par le
  widget comme avant.
- Lecture des tests qui touchent le dock :
  - `programme_test.dart` attend exactement 4 `Text` et un `BackdropFilter`
    dans `HeroNavBar` : les quatre libellés sont toujours des `Text` (repliés
    pour les onglets inactifs), le flou est conservé.
  - `redesign_test.dart` cherche `find.text(label.toUpperCase())` sous chaque
    `ValueKey('nav-$i')` avant de taper : les libellés restent en capitales et
    présents dans l’arbre même repliés (un `ClipRect` n’est pas « offstage »).
  - `motion_test.dart`, `ui_refactor_test.dart` : navigation par clé, inchangée.
- `Expanded` rendu depuis le `builder` d’un `TweenAnimationBuilder` : autorisé,
  le parent `RenderObject` le plus proche reste le `Row`.
- Contraintes : `Flexible` dans un `Row` à `mainAxisSize.min` sous largeur
  bornée ; `Align(widthFactor: 0)` accepté ; texte réduit par `FittedBox`
  plutôt que coupé (écrans de 320 px, police agrandie jusqu’à 1,15).
- `python3 -m unittest discover -s tools/tests` et
  `python3 tools/verify_project.py` : résultats dans `validation/2.2.4/`.

## Non vérifié dans l’environnement de livraison

- `flutter analyze`, `flutter test` et la compilation Android : pas de SDK
  Flutter disponible ici. Le workflow `build-apk.yml` les exécute avant de
  produire l’APK ; en cas d’échec sur `nav_bar.dart`, le fichier 2.2.3 se
  trouve dans le ZIP précédent et se remet à l’identique.
- Rendu visuel : pas de capture ; le dessin de référence est la rangée
  « Juste milieu » du canvas One UI 8.
