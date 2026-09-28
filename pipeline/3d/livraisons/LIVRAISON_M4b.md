# Livraison M4b — Anatomie complète en transparence, filtres à cocher (Kalis Track 5.3.1)

**Date** : 28/09/2026 · **Version** : 5.3.1+76 · **Commit main** : 4531346 · **Build signé** : run 36409875811 (n° 101) · **CI 3D** : run 36408180487 (essais 36403295133, 36406347888)

## Ce que tu vois dans l'appli
- **Tous les muscles sont de retour** : les 21 paires de muscles profonds retirées en M2 (rhomboïdes, subscapulaire, supra-épineux, petit pectoral, carré des lombes, multifides, rotateurs de hanche, tibial postérieur…) et le platysma.
- **Muscles transparents à 50 %** partout où le mannequin s'affiche (Anatomie, fiche exercice, STATS, Moteur 3D) : un muscle sollicité caché se voit à travers les autres, avec sa couleur et son halo. Os, tête, mains et pieds restent opaques.
- **Toucher** : le muscle allumé le plus proche sur le trajet du doigt, sinon le plus proche ; « (profond) » dans la bulle pour un muscle profond.
- **Arsenal › Référence › Anatomie** : bouton **Filtres · n** ; menu de cases à cocher (11 groupes allumés ensemble, « Muscles profonds », « Os », Tout cocher / Tout décocher), fermé en touchant en dehors, gardé pendant la session. Mannequin plus grand, boutons de vue dessous, résumé des groupes cochés et de leurs muscles.

## Technique
- `tools/anatomy/build_model.py` : plus aucun muscle retiré, couche « profond » (source Z-Anatomy ou caché au repos), platysma, décimation des muscles cachés × 0,85 ; 62 506 triangles (≤ 75 000), GLB 1,29 Mo, 227 maillages (183 avant).
- `lib/mannequin_3d.dart` : `kMuscleOpacity = 0.5`, `AlphaMode.blend` (tri arrière → avant par image, sans écriture de profondeur, faces arrière éliminées : rendu natif de flutter_scene 0.23), émission compensée, `hidden`, `bones`, règle du toucher `MannequinScene.pickAlong`.
- `lib/anatomy_screen.dart` : `AnatomyFilters`, `MenuAnchor` + `CheckboxMenuButton`.
- CI 3D : `integration_test/anatomie_m4b_test.dart`, émulateur 540 × 960.

## Contrôles
- Formatage, analyse sans remarque, 910 tests Dart réussis (13 ignorés, 0 échec), tests Python (`test_m2_anatomy.py` étendu), `verify_project.py`, `package_release.py --check`, builds debug, profile et signé.
- Émulateur : muscles profonds seuls allumés, 4 vues sombre + 2 clair ; rotation par petits pas sans disparition ni clignotement ; toucher « Petit rhomboïde (droit) (profond) · Dos » ; filtres multiples, menu, profonds masqués, résumé, sombre et clair ; fiche et STATS en transparence. Captures regardées.
- Moteur 3D (émulateur, avant opaque / après transparent) : 2 200 / 2 472 ms, 1 142 / 1 122 ms, 2 421 / 2 770 ms selon les passages : écart dans le bruit du rendu logiciel. À vérifier sur ton téléphone (120 images/s en 5.0.0).

## Page de suivi
https://claude.ai/artifact/KknJkZqegaxWrFsmMaomsA

## Limites
- Tri des translucides par maille : ordre approximatif possible où deux grands muscles se chevauchent (invisible sur les captures).
- Muscles profonds allumés seuls plus discrets en thème clair.
- Écran Anatomie : glisser sur le mannequin le fait tourner ; la page défile en glissant sur les filtres, les boutons ou le texte.
- Fléchisseurs cervicaux profonds, diaphragme, plancher pelvien : absents du modèle source.
