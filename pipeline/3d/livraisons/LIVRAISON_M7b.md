# Livraison M7b — Animations de Koach en mascotte (5.8.0)

Lot M7b du pipeline « Mannequin 3D » (Opus 5.5, effort élevé), 29-30/09/2026.

## Ce qui change dans l'application
- **Arsenal › Anatomie › Koach (aperçu)** (nouvelle entrée sous le résumé des groupes) : Koach joue en boucle l'animation choisie, puces par famille dessous (Attente, Koach parle, Koach félicite). Boutons Face / Dos / Profil / 3/4 et zoom au pincement (pas de rotation au doigt, décision du 29/09). Mannequin neutre (aucun muscle allumé). Koach n'apparaît nulle part ailleurs ; fiches et animation de test inchangées.

## Les 9 animations
| Famille | Animation | Durée | Type |
| --- | --- | --- | --- |
| Attente | Respire et change d'appui | 4,0 s | boucle |
| Attente | Regarde autour et roule les épaules | 4,4 s | boucle |
| Attente | S'étire les bras puis le cou | 5,4 s | boucle |
| Koach parle | Explique d'une main | 4,2 s | boucle |
| Koach parle | Explique des deux mains | 4,3 s | boucle |
| Koach parle | Montre quelque chose sur le côté (index tendu, à droite de l'écran) | 3,2 s | boucle |
| Koach félicite | Applaudit | 3,2 s | revient à l'attente |
| Koach félicite | Lève le poing (uppercut puis deux « yes ! ») | 3,0 s | revient à l'attente |
| Koach félicite | Pouce levé | 3,0 s | revient à l'attente |

Style anime : anticipation, poses franches, dépassement puis amorti, tenues ≤ 0,4 s relancées, tête / cou / clavicules / mains en décalage de 2 à 4 images. Même pose d'attente au départ et à l'arrivée (écart entre animations ≤ 0,03°).

## Fabrication
- `tools/anatomy/koach_rig.py` : pose par canaux (miroir exact gauche / droite), jambes par cinématique inverse (pieds fixes), clés et courbes, résolution des mains, contrôles, FBX « Without Skin » sur l'armature reconstruite depuis `squelette_mixamo.json` (aucune ressource chiffrée).
- `tools/anatomy/koach_animations.py` : les 9 animations ; `--controle`, `--importer` (FBX → `import_animations.import_koach` → `assets/anatomy/clips/koach/`, registre).
- `tools/anatomy/koach_preview.py` : planches, bandes et GIF hors application.
- Sources FBX non chiffrées ni suivies (choix du propriétaire du 29/09 : « oublie le chiffré ») : le script est la source.

## Validation (au moins 3 passes par animation)
1. Contrôles automatiques et planches / bandes / GIF regardés par moi à chaque version.
2. Sous-agent neuf « directeur d'animation » (références anime, jeux de combat), 6 passes :

| Animation | v1 | v2 | v3 | v4 | v5 | v6 |
| --- | --- | --- | --- | --- | --- | --- |
| Respiration | 4 | 6 | 6,5 | 7 | 7 | **8** |
| Regard | 4 | 6 | 6,5 | 6,5 | 7,5 | **8** |
| Étirement | 5 | 5 | 6,5 | 7 | **8** | 8 |
| Une main | 4 | 5,5 | 6,5 | 7 | **8** | 8 |
| Deux mains | 5 | 6 | 7 | 7,5 | **8** | 8 |
| Montre | 5 | 5,5 | 6 | 7 | 7 | **8** |
| Applaudit | 4 | 5 | 6,5 | 6,5 | 7 | **8** |
| Poing | 6 | 4,5 | 5,5 | 7 | **8** | 8 |
| Pouce | 3 | 3,5 | 5,5 | 6 | **8** | 8 |

Principaux défauts corrigés (avant → après) : bras qui passaient par l'horizontale sur le côté (sémaphore) → arcs devant le corps ; poses mortes de 0,8 à 3 s → tenues ≤ 0,4 s relancées ; mains dans la silhouette du torse → hors silhouette ; « yes » du poing devant le visage → coude le long du flanc, poing sur le côté ; pouce collé à l'épaule → bras ouvert, pouce détaché ; index « pistolet / V » → index horizontal, pouce replié ; respiration invisible → sternum et épaules +2 cm ; fins de boucle mortes → relancées.

3. Rendu réel sur émulateur (CI 3D) : les 9 poses fortes et 8 images par animation regardées ; mains (pouce levé, poing, index, paumes qui claquent) correctes sur le vrai maillage.

## Contrôles
- Python : 128 tests (dont 11 M7b : registre, clips décodés, contrôles automatiques, aucune tenue figée > 0,45 s, clips fidèles au script, transitions, miroir des mains) ; `verify_project.py`, `package_release.py --check`, `check_release_without_secrets.py --tree`.
- Dart : suite complète (dont `test/m7b_koach_test.dart` : registre, ordre, clips, pieds fixes, pose d'attente partagée, écran, entrée de l'Anatomie, boucle).
- CI 3D : essais A (formatage, test Dart, animations réduites de l'émulateur), B (tests Dart, accolades), C.
- Clips : 4 à 11,6 Ko (66 Ko en tout), écart ≤ 0,2°, ≤ 8,2 mm en bout de doigt ; dépassement du budget de 5 Ko justifié (contacts exacts).

## Limites
- Rendu de revue en capsules (pas le maillage) ; le vrai maillage a été vérifié sur les captures de l'émulateur seulement (rendu logiciel, 2 images/s).
- « Montre » pointe vers la droite de l'écran (côté gauche de Koach) ; un miroir pour l'autre côté serait à ajouter quand la mascotte sera placée.
- Les FBX de Koach ne sont pas conservés (régénérés par le script).
