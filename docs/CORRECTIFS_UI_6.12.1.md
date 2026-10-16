# Correctifs UI et UX — dev6.12.1 (11/10/2026)

Passe unique demandée par le propriétaire après essai de dev6.12.0 sur téléphone.

| Remarque | Correctif |
| --- | --- |
| Couleurs trop fades | Sombre : encre et secondaire ravivées (chroma HCT portée vers 72, teinte gardée, contraste ≥ 4,5:1 / 3:1 inchangé) ; surfaces teintées de la dominante quand le fond du propriétaire est neutre (chroma 7 au plus). Fond et dominante exacts inchangés. `lib/kit/palette.dart`, `test/fixtures/ui0_palettes_roles.json` régénéré. |
| Couleur de marque trop peu présente | Titres de section, pastilles d'icône des menus, numéros des jours, onglet actif du dock, repère de séance en `encre`. |
| Cartes trop arrondies | Rayons 24 → 16 (cartes), 20 → 12 (groupes, lignes de jour, tuiles, champs de série). |
| Dock sans identité | Plus de liseré gris en sombre ; onglet actif en pilule tonale `encre` (icône `encre`, libellé `texte`). |
| Explications de Koach de trop | « Pourquoi ? » du Bilan du jour et de l'ajustement, détail des notes de Koach, consignes des mini-séries : en mode guidé seulement. Réglages › Séance › Koach : « Mode guidé » (désactivé par défaut) et « Comprendre Koach » (toutes les explications). |
| Glissement des pages qui prend le pas sur le défilement | Vue paginée de séance (`KSessionPager`) : seuil de glissement horizontal doublé, ressort plus ferme (la page se pose plus vite), champs actifs au même seuil. |
| Boutons de forme qui font tache | Tuiles de ressenti au rayon 12 avec repère d'échelle coloré (de `danger` à `validation`), plus compactes. |
| Carte d'exercice confuse | Charge, volume et cible de réserve (« RIR 2 », difficulté sur 10) sur une ligne, cible en badge ; repos, tempo, technique en repères discrets ; une ligne de consigne de Koach (le reste dans sa feuille) ; séance précédente à la demande (icône d'historique de la barre d'outils). |
| Clusters et techniques rares | Bandeau compact : titre court (« Cluster · 3 × 1 · 15 s »), cases des mini-séries, pas à pas et bouton de validation sur une ligne ; un seul bouton de mini-repos. |
| « Exercices » partout | Bouton supprimé : l'appui (ou appui long) sur le titre de la séance ou sur « Exercice n sur N » ouvre la liste ; aussi dans le menu ⋮ (« Liste des exercices »). Même chose dans l'historique. |
| Boutons et espaces trop larges | Repère et points sur une ligne, marges de la carte d'exercice et des lignes de Koach resserrées. |

Réglage ajouté : `AppSettings.koachGuided` (écrit seulement s'il est activé ; export identique sinon).

## 6.13.0 — taille d'affichage

Réglages › Apparence › « Taille d’affichage » : 85, 90, 100, 110 ou 120 %. Toute l'interface (textes, cartes, boutons, feuilles, boîtes de dialogue) est dessinée sur un écran virtuel mis à l'échelle (`KDisplayScale`, `lib/kit/display_scale.dart`), comme la taille d'affichage d'Android ; s'ajoute au réglage du téléphone. `AppSettings.displaySize`, écrit seulement s'il diffère de 100.

## 6.14.0 — couleurs et espacements

Réglages › Apparence : « Couleurs » (Sobres = dérivation de 6.12.0, Normales par défaut, Vives = 6.12.1 ; `kColorIntensity`, `kColorIntensities` dans `lib/kit/palette.dart`) et « Espacements » (Compacts 70 %, Normaux 85 % par défaut, Aérés 100 % ; `KDensity` dans `lib/kit/tokens.dart`, appliqué aux marges intérieures des cartes, des lignes de menu et de jour et aux titres de section, lignes jamais sous 48 dp). Titres de section revenus en `texte2`, pastilles d'icône des menus sur `haute` (icône `encre`). Bordeaux sombre : encre #D56964 en « Normales ».

## 6.15.0 — lift principal et clusters

- Carte du lift principal (`Exercise.main`) : contour et surtitre « Lift principal » en `encre`, charge et cible RIR en `encre` ; les autres exercices : carte neutre, charge en `texte`, cible sur `haute`.
- Cluster : la cible de la ligne est répartie en blocs (`clusterSplit` : 3 reps en 2 blocs → 2 + 1) au lieu de « 2 × 1 » qui contredisait la ligne ; titre « Cluster · 3 reps en 2 blocs, 30 s entre » ; deux lignes au plus : titre, puis cases des blocs (valeur prévue, faite, suivante) et saisie du bloc suivant (− valeur + ✓) côte à côte.
- Zones de saisie (champs de série, validation, chrono de série, bandeau des blocs, note, champs des formulaires) à la hauteur des espacements choisis (`KDensity.field` : 48 dp × facteur, 36 dp au moins ; 48 dp en « Aérés »).

## 6.16.0 — barre des flammes

La partie parcourue de la ligne des flammes est un dégradé des couleurs des points (chaque position a la couleur de son point, fixe pendant le déplacement, révélée jusqu'à la flamme), sans transparence ; un halo de la couleur de la flamme (fondu radial) relie la barre à la flamme. Dessin de la flamme inchangé.

## 6.17.0 — flou progressif et hauteurs stables

- Flou progressif (`KProgressiveBlur`, `KFloatingBottom`, `lib/kit/blur.dart`) sous le dock et la barre de repos : bande de 32 dp au-dessus du bloc, flou par 6 paliers jusqu'à σ 10 avec un voile du fond (0 → 60 %, 70 % en bas), sans prise d'appui ; voile seul quand les animations sont réduites.
- Bandeau des blocs : place du bouton d'annulation gardée et hauteur de la ligne des blocs gardée quand tous sont notés (plus de saut de hauteur) ; marge basse de la page d'exercice portée à 56 dp pour sortir de la bande floutée.

## 6.17.1 — ligne des flammes en union lisse (SDF)

Halo retiré. Ligne, points et base de la flamme dessinés comme une seule forme (`FlameTrackPainter`, `lib/adapt/flame_track.dart`) : union lisse (smooth min polynomial, rayon 5) des distances signées d'une capsule (ligne parcourue 1,5 dp, restante 1 dp), des points (3,5 dp, qui s'effacent sous la flamme) et d'un cercle de 5 dp sous la flamme ; contour obtenu par dichotomie sur la demi-hauteur à chaque demi-pixel. Couleur de chaque point jusqu'à la flamme, `texte3` après ; la position animée de la flamme pilote la forme et la flamme.

## 6.17.2 — flou continu

Flou progressif sans palier visible : bande portée à 40 dp, 32 paliers (un tous les 1,25 dp) au lieu de 6, flou croissant en courbe quadratique (écart entre paliers voisins ≤ 0,6 de σ), paliers groupés sur une seule capture de l'arrière-plan (`BackdropGroup`, `BackdropFilter.grouped`).

## 6.17.3 — fondu au lieu du flou

Le flou progressif (filtres d'arrière-plan empilés) est retiré : trop coûteux et trop haut. À la place, un fondu vers la couleur du fond sur 24 dp au-dessus du dock et de la barre de repos (0 → 25 → 60 → 85 %, 95 % sous le bloc), un seul dégradé, aucun filtre. Le dock garde son flou derrière sa pilule.
