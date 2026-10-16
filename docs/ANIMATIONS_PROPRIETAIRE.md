# Tes animations dans Kalis Track — mode d'emploi (M7)

Ce qu'il faut : **un fichier par exercice**, exporté depuis Mixamo, sur le
personnage **Ch36** (celui de l'application). Tout se fait depuis le
téléphone, sans rien installer.

## 1. Exporter depuis Mixamo

Sur mixamo.com (dans le navigateur du téléphone, en « version pour
ordinateur » si besoin) :

1. Personnage : **Ch36** (onglet *Characters*), le même que dans l'appli.
2. Choisis ou règle ton animation (onglet *Animations*). Si l'option
   **In Place** existe (marche, fentes marchées…), coche-la.
3. **Download**, avec exactement ces réglages :

| Réglage Mixamo | Valeur |
| --- | --- |
| Format | **FBX Binary (.fbx)** |
| Skin | **Without Skin** |
| Frames per Second | **30** |
| Keyframe Reduction | **none** (aucune réduction) |

Une seule répétition suffit : l'appli la joue en boucle. Commence et
termine dans la même position (bras compris), sinon la boucle saute.

## 2. Nommer le fichier

Le nom du fichier est **l'identifiant de l'exercice** (tableau ci-dessous),
suivi de `.fbx`. Exemple : `back-squat.fbx`, `traction-pronation.fbx`.
Un nom inconnu est refusé à l'import avec un message clair (et les noms
proches).

## 3. Envoyer les fichiers

Joins les fichiers `.fbx` à un message dans **la conversation de pilotage
de Kalis Track** (Claude), avec une phrase du genre : « Importe ces
animations ». Plusieurs fichiers d'un coup, c'est bien.

**Ne les dépose pas sur GitHub** (dépôt public : n'importe qui pourrait les
télécharger). La session d'import les chiffre (`assets_secure/animations/`,
comme le personnage) : ils ne sont jamais en clair dans le dépôt.

## 4. Ce que fait l'import

`tools/anatomy/import_animations.py` (lancé par la session, pas par toi) :

- `deposer` : vérifie chaque fichier (nom, squelette Mixamo du personnage
  Ch36 : noms des 65 os, hiérarchie, proportions), puis le chiffre ;
- `importer` : retire le déplacement parasite du bassin si l'exercice est
  sur place, rééchantillonne à 30 i/s, compresse (≤ 5 Ko par exercice visé,
  mesuré sinon), découpe les **phases** (montée, descente, pause) et les
  associe à l'exercice ;
- s'il y a un souci (mauvais personnage, fichier sans animation, export
  « With Skin »…), l'import s'arrête sur un message qui dit quoi refaire.

Après l'import et le build, la fiche de l'exercice montre le mannequin
animé avec son lecteur (lecture / pause, curseur, phase et tempo, halo plus
vif en montée, plus doux en descente, pulsation lente en pause). Les fiches
sans animation restent comme aujourd'hui.

Pour les réglages fins (phases à la main, exercice qui n'est pas « sur
place », une même animation pour plusieurs exercices) : dis-le dans la
conversation ; ils vont dans `tools/anatomy/animations.json`.

## 5. Identifiants de ton programme

Ordre du programme ; les variantes (tests, lestés, pause…) peuvent reprendre
la même animation que le mouvement de base : envoie seulement la base et
dis « même animation pour … ».

| Identifiant (nom du fichier) | Exercice | Même animation possible pour |
| --- | --- | --- |
| `ab-wheel` | Ab wheel | |
| `back-squat` | Back squat | `squat-pause`, `squat-endurance-70-kg`, `test-1rm-back-squat`, `test-max-squat-70-kg` |
| `muscle-up` | Muscle-up | `muscle-up-leste`, `test-1rm-muscle-up-leste`, `test-max-muscle-ups-pdc` |
| `curl-barre-ez` | Curl barre EZ | |
| `curl-marteau-par-haltere` | Curl marteau (par haltère) | |
| `dips` | Dips | `dips-lestes`, `test-1rm-dip-leste`, `test-max-dips-pdc`, `dips-a-resistance-accommodante-elastique-depuis-le-sol` |
| `dead-hang-leste-ou-pdc` | Dead-hang lesté ou PdC | `false-grip-hold-anneaux-ou-barre` |
| `developpe-couche` | Développé couché | |
| `developpe-militaire-debout` | Développé militaire debout | |
| `excentriques-de-transition-lestes` | Excentriques de transition lestés | |
| `extension-triceps-poulie-corde` | Extension triceps poulie corde | |
| `face-pulls` | Face pulls | |
| `fentes-marchees-par-haltere` | Fentes marchées (par haltère) | |
| `hip-thrust` | Hip thrust | |
| `hollow-body-hold` | Hollow body hold | |
| `isometrie-bas-de-dip` | Isométrie bas de dip | |
| `isometrie-de-transition-muscle-up` | Isométrie de transition muscle-up | |
| `leg-curl` | Leg curl | |
| `leg-raises-lestes-suspendu` | Leg raises lestés (suspendu) | |
| `mobilite-complete` | Mobilité complète | |
| `mobilite-epaules-poignets` | Mobilité épaules + poignets | |
| `mollets-debout` | Mollets debout | |
| `negatifs-de-muscle-up` | Négatifs de muscle-up | `negatifs-de-muscle-up-complets` |
| `pallof-press` | Pallof press | |
| `pompes` | Pompes | `pompes-lestees-lest-ajoute`, `test-max-pompes-pdc` |
| `rotations-externes-par-haltere` | Rotations externes (par haltère) | |
| `rowing-barre-penche` | Rowing barre penché | |
| `rowing-haltere-unilateral-par-haltere` | Rowing haltère unilatéral (par haltère) | |
| `scapular-pull-ups` | Scapular pull-ups | |
| `souleve-de-terre-roumain` | Soulevé de terre roumain | |
| `traction-pronation` | Traction pronation | `traction-lestee`, `test-1rm-traction-lestee`, `test-max-tractions-pdc` |
| `tirage-horizontal-poulie` | Tirage horizontal poulie | |
| `tirage-vertical-prise-neutre` | Tirage vertical prise neutre | |
| `tractions-explosives-poitrine-barre` | Tractions explosives poitrine-barre | |
| `transitions-de-muscle-up-a-l-elastique` | Transitions de muscle-up à l'élastique | |
| `travail-poignet-excentrique-haltere` | Travail poignet excentrique (haltère) | |
| `ytw-a-plat-ventre-banc-incline` | YTW à plat ventre (banc incliné) | |
| `elevations-laterales-par-haltere` | Élévations latérales (par haltère) | |

Pas d'animation pour `bilan`, `repos-actif`, `hiit-court`,
`marche-ou-velo-tres-leger` (pas un mouvement d'exercice). Tout autre
exercice du pack (625 identifiants, dans l'appli : Arsenal › Référence)
peut aussi recevoir une animation, avec le même nommage.

## 6. Pour vérifier le lecteur sans tes animations

Réglages › À propos › Moteur 3D › **Animation de test** : un squat lent au
poids du corps, fait comme tes fichiers (FBX « Without Skin » passé par le
même import), **réservé aux tests** (jamais montré sur une fiche).
