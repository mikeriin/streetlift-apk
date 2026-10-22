# Animation du mannequin 3D (M7, 5.7.0)

## Chaîne

1. Le propriétaire exporte un FBX Mixamo « Without Skin » (30 i/s, sans
   réduction d'images clés) par exercice, sur le personnage Ch36
   (`docs/ANIMATIONS_PROPRIETAIRE.md`).
2. `tools/anatomy/import_animations.py deposer` vérifie (nom = identifiant
   du pack, squelette Mixamo : 65 os, hiérarchie, longueurs à ±3 %) et
   chiffre la source dans `assets_secure/animations/<id>.fbx.enc`.
3. `import_animations.py importer` : rotations de chaque os dans le repère
   du corps (depuis les matrices du monde du FBX et les repères de repos du
   personnage, `squelette_mixamo.json`), translation du bassin, dérive
   horizontale retirée pour un exercice sur place, 30 i/s, réduction des
   images clés (écart ≤ 0,2°, relâché jusqu'à 1° si le clip dépasse 5 Ko,
   dépassement mesuré et justifié dans le registre), compression
   (`.ktclip`), phases (réglages de `tools/anatomy/animations.json`, sinon
   détection par la hauteur du centre de masse : montée = concentrique,
   descente = excentrique, presque immobile = isométrique), registre
   `assets/anatomy/clips/index.json`.
4. L'application charge le **mannequin animable**
   (`assets/anatomy/mannequin_anime.glb`, `tools/anatomy/build_animated.py` :
   mêmes zones que le mannequin fixe, au repos en T, 65 os `j_<os>`, peau
   Mixamo à 4 influences ; chiffré comme le mannequin fixe) et le clip ;
   chaque image pose les os (`MannequinScene.applyPose`), le GPU déforme le
   corps ; halo et toucher suivent le corps déformé (même peau sur le
   processeur, `assets/anatomy/peau_mixamo.bin`).

Convention commune (outil Python, `MannequinRig`, clips) : repère glTF
(y en haut, avant = +z, gauche anatomique = +x, mètres) ; une posture est
une rotation locale par os, exprimée dans le repère du corps, autour de la
tête de l'os, composée le long de la chaîne, plus la translation du bassin.

## Lecteur (`lib/mannequin_player.dart`)

- Sous le mannequin : lecture / pause (48 dp), curseur de temps (glisser =
  parcourir le mouvement ; la lecture reprend au lâcher si elle était en
  cours), phase et tempo (« Descente · 3 s »), temps, boutons de vue du
  mannequin (Face / Dos / Profil / 3/4), zoom au pincement, nom au toucher.
- Caméra fixe pendant la lecture : cadrage commun à tout le clip (union des
  boîtes du corps aux images clés et toutes les 0,5 s).
- Libellés accessibles : bouton (« Lecture » / « Pause »), curseur
  (« 1,2 s sur 6 s, Descente »), phase annoncée en pause.

## Intensité par phase (`phaseHaloGain`, `lib/mannequin_clip.dart`)

Le maillage reste gris ; le **halo** de la zone travaillée (couleur
dominante, §2 du pipeline) voit son opacité multipliée par un gain :

| Phase | Gain | Rendu |
| --- | --- | --- |
| concentrique (montée, le muscle raccourcit) | 1,0 | halo vif |
| excentrique (descente, le muscle freine) | 0,62 | halo plus doux |
| isométrique (pause, maintien) | 0,8 ± 0,07, période 2 s | pulsation lente |

- Transitions : fondu en S de 0,4 s centré sur chaque frontière (jamais
  plus de la moitié d'une des deux phases), y compris entre la fin et le
  début du clip (boucle).
- Jamais de clignotement : variation du gain ≤ 2 par seconde, pulsation à
  0,5 Hz (le seuil d'accessibilité est 3 éclats par seconde, WCAG 2.3.1).
  Contrôlé par `test/m7_player_test.dart`.
- Animations réduites : aucune pulsation (gain constant de la phase).

Raison : l'effort musculaire est plus fort en concentrique qu'en
excentrique à charge égale (activation EMG plus élevée en concentrique) ;
l'isométrie est un effort tenu, rendu par une respiration lente plutôt que
par une intensité fixe qui se confondrait avec les autres phases.

## Animations réduites (réglage Android « Supprimer les animations »)

Pas de lecture (ni automatique, ni par bouton : le bouton n'est pas
affiché) ; le curseur s'arrête seulement sur les **images clés de début et
de fin de chaque phase** (squat de test : 0, 3, 4, 5, 6 s) ; changement de
vue instantané ; pas de pulsation.

## Économie

- Lecture seulement quand le lecteur est à l'écran : hors de l'écran
  (défilement), pause, reprise quand il revient ; page cachée par une autre :
  ticker muet (Flutter) ; application en arrière-plan : pause, reprise au
  retour ; **60 s sans interaction** : pause (reprise au bouton).
- Pas de lecture sans clip : un exercice sans animation garde son mannequin
  fixe (rendu à la demande, comme avant).
- Peau sur le processeur seulement pour les zones entourées d'un halo (une
  fois par image) et au toucher.

## Clips (`.ktclip`)

gzip d'un bloc petit-boutiste : `KTC1`, version, images/s, nombre d'images,
pistes d'os (os, clés en écarts d'images sur un octet, quaternions « trois
plus petites composantes » sur 16 bits), piste du bassin (mm). Un os sans
piste reste au repos. Animation de test : 181 images, 16 pistes, 1 982
octets.
