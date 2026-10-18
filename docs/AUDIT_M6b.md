# Audit M6b — mannequin fixe (Kalis Track 5.5.4 → 5.5.5)

Lot M6b du pipeline « Mannequin 3D » (29/09/2026, Opus 5.5, effort élevé) :
bugs d'affichage, incohérences graphiques et d'usage de tout ce qui touche
au mannequin et aux filtres, dans l'état de référence du 29/09/2026 (écorché
acheté, muscles opaques, maillage gris et halo de la zone travaillée dans la
couleur dominante, fond = support, boutons de vue sans rotation au doigt,
zoom et toucher, plus d'animation, mannequin à la place des images 2D).

## Méthode

- Lecture du code de chaque écran et composant : Anatomie (vues, filtres,
  toucher, zoom, résumé), fiche exercice (mannequin en tête, légende,
  « Absents du mannequin »), STATS (semaine), carte de séance de l'accueil,
  feuille de séance, aperçu de WOD, Moteur 3D, Réglages › Affichage 3D,
  Sources et licences, menus « Filtres » normalisés (M4c), repli sans
  Flutter GPU.
- Captures du vrai rendu Flutter GPU (émulateur Android 15, 360 × 640 dp) :
  `integration_test/audit_m6b_test.dart`, en deux parties (`M6B_PART=a|b`) —
  Anatomie sombre (repos, menu Filtres, groupe Dos, toucher, zoom × 2,5,
  retour Face), Anatomie claire, grande taille de texte (130 %) avec
  animations réduites (vue changée sans transition), fiches Traction
  pronation, Dips, Back squat (sombre), Étirement des fléchisseurs de hanche
  (clair, muscles étirés), STATS sombre et clair, accueil sombre et clair,
  aperçu de WOD, Moteur 3D, grand écran (800 × 1280 dp : Anatomie et fiche).
  Relevé `m6b_releve_a.json` / `m6b_releve_b.json` : part de la figure, part
  du halo, **démarcation** (écart moyen des pixels juste à l'intérieur et
  juste à l'extérieur des bords de la vue : 0 partout après correction),
  vue de départ, libellés d'accessibilité, nom touché.
- « Avant » : captures de la CI de 5.5.4 (run 36571687956,
  `claude/ci-3d-fable`) ; l'essai A de M6b (audit sur 5.5.4, run
  36588531083) a perdu ses captures (30 images renvoyées d'un coup : service
  du pilote perdu), d'où les deux parties.

## Défauts

Gravité : **bloquant** (écran inutilisable ou information fausse),
**majeur** (information trompeuse ou contraire à une décision du
propriétaire), **mineur** (finition).

| # | Écran | Défaut | Gravité | Capture (avant → après) | Cause | Statut |
| --- | --- | --- | --- | --- | --- | --- |
| D1 | Anatomie › Filtres | Case « Muscles profonds » sans aucun effet, comptée dans « Filtres · n » (« Filtres · 2 » sans rien de coché), résumé « Muscles profonds affichés » | majeur | `m56_anatomie_profil` (« Filtres · 2 ») → `m6b_anatomie_sombre_menu`, `m6b_anatomie_sombre_repos` (« Filtres · 1 ») | L'écorché acheté (5.5.2) n'a pas de couche profonde : `deepIds` vide | Corrigé : case retirée (Affichage = « Os »), résumé « Os affichés / masqués », compteur 12 cases |
| D2 | Fiche exercice (traction et 110 exercices à principaux avant / arrière) | Vue de départ 3/4 avant : le grand dorsal, principal, est à peine visible, et son halo au flanc, fondu avec celui du biceps, se lit comme un pectoral | majeur | `m56_traction-pronation_fiche` → `m6b_fiche_traction-pronation_sombre` | Règle M3 « principaux mixtes → 3/4 » sans tenir compte de la taille des muscles | Corrigé : aire de chaque région dans `muscles_map.json` ; principaux mixtes → la face dont la surface est au moins 2 × celle de l'autre, sinon 3/4 (traction, chin-up, tirages → Dos ; dips, squat, muscle-up → 3/4) |
| D3 | Réglages › À propos › Moteur 3D | Cadre sombre visible autour du mannequin (fond de la scène ≠ page) | majeur | `m56_moteur3d_prechargement` → `m6b_moteur3d` | Écran laissé à `sceneBackground` en 5.5.4, contrairement à la décision « fond = support » | Corrigé : fond de la page |
| D4 | Moteur 3D | Texte « muscles d'une traction allumés » mais rien d'allumé : pas de halo pendant la rotation continue | majeur | `m56_moteur3d_prechargement` → `m6b_moteur3d` | Halo désactivé en rotation (caméra calculée à chaque image) | Corrigé : le halo lit la caméra de chaque image (`cameraOf`, `repaint`) |
| D5 | Accueil › carte de la séance du jour | Halo invisible : la rampe de la couleur dominante sur le fond de la couleur dominante (bordeaux sur bordeaux) | majeur | `m6b_accueil_sombre` (essai B) → `m6b_accueil_sombre` (essai C) | Fond de la carte = teinte principale (`SL.bordeaux`) | Corrigé : sur cette carte, halo de la couleur du texte (`SL.onBrandSoft`, déjà la teinte du repli 2D) ; ailleurs, couleur dominante |
| D6 | Fiche › légende des rôles | Pastilles pleines alors que le mannequin montre un halo flou sur des muscles gris | mineur | `m56_back-squat_fiche` → `m6b_fiche_traction-pronation_sombre_legende` | Légende de la carte 2D gardée telle quelle | Corrigé : pastilles « halo » (même couleur et même opacité que le halo, sur le gris des muscles) quand la 3D est affichée |
| D7 | Anatomie | Lecteur d'écran : « groupe Dos en rouge » | mineur | — | Libellé écrit pour la rampe rouge (avant 5.5.2) | Corrigé : « mis en évidence par un halo » |
| D8 | Tous les menus « Filtres » | Lecteur d'écran : « 1 actifs », « 0 actifs » | mineur | — | Pluriel fixe | Corrigé : « 0 actif », « 1 actif », « 3 actifs » |
| D9 | Fiche exercice sur grand écran | Mannequin de 380 dp dans une carte de 730 dp de large (petit, perdu) | mineur | `m6b_grand_ecran_fiche` (essai B → C) | Hauteur fixe | Corrigé : 45 % de la hauteur de l'écran, entre 380 et 600 dp (inchangé sur téléphone) |
| D10 | Sources et licences (crédits du modèle) | « gris à 50 % d'opacité, couleur dominante pour les muscles sollicités » | mineur | — | Texte de 5.5.2 | Corrigé : muscles opaques, halo |
| D11 | Mannequin (toutes vues) | Vue de départ connue après le chargement de la carte : une rotation pouvait se jouer derrière l'indicateur de chargement | mineur | — | `setView` animé même sans scène | Corrigé : sans scène affichée, la vue change sans transition |

## Non corrigés (raison)

| # | Écran | Défaut | Gravité | Raison |
| --- | --- | --- | --- | --- |
| N1 | Anatomie, fiches | Halo sans test d'occlusion : une petite tache peut apparaître là où un muscle sollicité est caché (Épaules cochées, vue de face : tache sur le pectoral, `m6b_grand_ecran_anatomie`) | mineur | Limite connue de 5.5.4 ; un test de visibilité par rayon coûterait des dizaines de ms à chaque image des transitions et du pincement. À reprendre avec un rendu par identifiant quand flutter_scene le permettra. |
| N2 | Anatomie (toucher) | Toucher le fascia de la colonne, une aponévrose, ou juste à côté de la silhouette sous le flou du halo : aucune bulle | mineur | Aponévroses et tendons non sélectionnables (décision de 5.5.2) ; le halo flou déborde la silhouette de quelques pixels. Toucher vérifié sur l'émulateur (grand dorsal, grand fessier, gastrocnémien : `toucher_direct` du relevé). |
| N3 | STATS (clair) | Semaine chargée : halo sur presque tout le corps | mineur | Reflète les données (toutes les zones travaillées, pondérées) ; la liste chiffrée des groupes reste dessous. |
| N4 | Modèle | 20 régions en plusieurs morceaux (ex. un fragment de l'ilio-psoas droit au bras, 67 triangles) | mineur | Correction dans la segmentation (`build_model.py`, archive achetée) : lot de modèle, hors M6b. |
| N5 | CI | Rendus de test `visual_capture_test.dart` (flutter test, `KALIS_CAPTURE`) en échec, déjà sur main (STATS › activité) | mineur | Sans lien avec le mannequin ; la suite Dart complète est verte. |

## Tests

- `test/m6b_correctifs_test.dart` : D1 (catégories, menu, résumé), D7
  (libellé), D6 (pastilles en halo), aires lues dans la carte.
- `test/m3_fiche_mannequin_test.dart` : D2 (traction / chin-up → Dos ;
  dips, squat, muscle-up → 3/4 ; carte sans aire → 3/4 ; 50 fiches).
- `test/m4b_anatomie_test.dart`, `test/m4c_filter_menu_test.dart` : D1, D8.
- `tools/tests/test_m2_anatomy.py` : aires recalculées depuis le GLB.
- `integration_test/audit_m6b_test.dart` : D2-D5, D9, démarcation nulle
  partout, animations réduites, grand texte, grand écran.
