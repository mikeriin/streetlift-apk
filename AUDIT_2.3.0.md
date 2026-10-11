# Audit 2.3.0 — Catalogue élargi, recherche tolérante

Date : 22 septembre 2026. Version 2.3.0+48 (2.2.4+47 précédente).

## Périmètre

- Nouveau : `lib/search.dart` (moteur de recherche partagé), `test/search_test.dart`.
- Modifiés : `lib/wod_generator.dart` (deuxième série, code de la première intact), `lib/store.dart` (`catalogWods`, 7 modes d’exécution, `modeDefaults`, `setsText` / `forcedSets` / `timerSpec` / `toExercise`), `lib/builder_screen.dart` (paramètres de mode, sélecteur d’exercices), `lib/wod_catalog.dart` (réécrit), `lib/ui.dart` (`KSearch` sans autocorrection), `assets/exercises_db.json.gz` (505 exercices).
- Version : `pubspec.yaml`, `lib/settings_screen.dart` (`kAppVersion`), `test/visual_capture_test.dart` (`validation/2.3.0`). README et checklist 2.2.4 archivés dans `docs/`.
- Tests ajustés : `screens_test` (`WODs · 1000`), `store_test` (1 000 WODs, ids uniques, niveaux 1-10, points et minutes > 0), `wod_acquisition_test` (`hasLength(1000)`, corrigé après un premier passage du workflow : l’ancien `hasLength(500)` avait échappé à la relecture), `training_estimate_test` (nom), `tools/tests/test_tools.py` (505 exercices).

## Vérifications effectuées ici

- Port Python du générateur V2 et du parseur du store (`_parseLine`, `_movePoints`, `_computeStats`) : 500 WODs distincts obtenus en 533 tirages, points de 34 à 1 314 (médiane 170), durée ≥ 1 min pour chacun, aucune ligne muette (Tabata, Death by, EMOM par blocs, force + metcon, échelles montantes avec `…` comprises). Les tirages aléatoires diffèrent entre Python et Dart ; les formes des lignes, elles, sont identiques.
- Compatibilité des lignes avec `equipmentOf` (matériel), `_rangeRe` / `_rotRe` (EMOM), `_maxRe` (Tabata) et `_scheme` (échelles `1-2-3-…-10`).
- Compatibilité avec `logSpec` : `3×MAX` → `repsMax` ; `3×MAX tenue` + tempo « Isométrie » → `holdMax` ; `4×6 · tempo 3-1-1-0` → `reps` ; `3×(8 + 2 paliers)` → `reps` (la regex de tenue exige un nombre après ×) ; chronos `hiit` / `emom` / `amrap` lus avant le texte.
- Tests existants relus : `screens_test` (un seul `TextField`, une seule `Icons.close`, `WODs · 0` puis `WODs · 1000`), `wod_acquisition_test` (recherche « Mon ancien défi » → `WODs · 0` : les trois termes doivent tous apparaître), `ui_refactor_test` (catalogue rendu à 320 px et texte 130 % : rangées de puces à 56 / 52 px, listes horizontales sans débordement).
- Équilibre des délimiteurs vérifié sur chaque fichier Dart modifié (analyse lexicale hors chaînes et commentaires).
- `python3 -m unittest discover -s tools/tests` et `python3 tools/verify_project.py --signing` : résultats dans `validation/2.3.0/`.

## Correctif du dock 2.2.4 (deuxième passage du workflow)

`flutter test` a révélé un défaut du dock livré en 2.2.4, jamais passé par le
workflow : `AnimatedSize` anime dans la phase de layout, et avec « Réduire les
animations » (durée nulle) son contrôleur se termine de façon synchrone pendant
`performLayout`, d’où « A RenderAnimatedSize was mutated in its own
performLayout implementation » à chaque changement d’onglet
(`motion_test` : « réduire les animations rend les onglets et le sélecteur
STATS immédiats », puis exceptions en cascade à chaque frame).

`lib/nav_bar.dart` est réécrit sans `AnimatedSize` ni `AnimatedContainer` :
un seul `TweenAnimationBuilder` par onglet (progression 0 → 1) pilote la
largeur (`Expanded`, poids 1 → 1,9), la révélation du libellé
(`Align(widthFactor: t)` sous `ClipRect`), son opacité et la teinte de la
pastille (`Color.lerp`). Une animation implicite accepte `Duration.zero`
(la mise à jour se fait dans `didUpdateWidget`, hors layout). Rendu identique
à 240 ms, `easeOutCubic` ; les quatre `Text` restent dans l’arbre, clés
`nav-$i`, `Semantics`, `Tooltip`, `BackdropFilter` et `extent` inchangés.

## Correctif du catalogue (troisième passage du workflow)

`wod_acquisition_test` attend, sous le compteur de crédits, la phrase « Gagne des
crédits en progressant. Achète un WOD, rejoue-le à volonté. » que la réécriture
de `wod_catalog.dart` avait retirée. Elle est rétablie à la même place. Un
contrôle mécanique a ensuite confronté chaque libellé cherché par les tests
(`find.text`, `find.textContaining`, `find.byTooltip`, clés) aux sources : plus
aucun libellé manquant hors chaînes calculées ou données de test.

## Points d’attention

- Les niveaux 1-10 sont recalculés par déciles sur 1 000 WODs : un WOD de la première série peut changer de niveau (et de prix futur) ; les crédits déjà dépensés restent ceux enregistrés à l’achat.
- Le filtre et le tri par durée estiment 1 000 WODs à la première utilisation (`wodEstimate`, cache de 1 024 entrées) : un court délai est possible la première fois.
- Le tri « Pertinence » n’a de sens qu’avec une recherche ; sans recherche il retombe sur « Débloqués puis niveau ».

## Non vérifié dans l’environnement de livraison

- `flutter test` et la compilation Android : pas de SDK Flutter disponible ici. Premier passage du workflow : `flutter analyze` réussi (22 s), tests en échec sur `wod_acquisition_test` (500 → 1 000), corrigé dans ce ZIP. Le workflow reste le point de contrôle avant l’APK.
- Rendu visuel des nouvelles puces et du menu de tri : pas de capture.
