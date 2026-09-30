# Livraison M8 correction 1 — Carte d'après l'image détaillée (5.9.1)

Retour du propriétaire (30/09/2026) : nouvelle image, plus détaillée (face, dos, profil ; chaque muscle dessiné et cerné de noir ; sans légende).

## Correction
- `tools/muscles2d/build_map.py` réécrit pour cette image (`tools/muscles2d/source_carte.png`) : fond clair relié au bord → transparent ; zones colorées isolées par couleur (k-moyennes) puis connexité (un muscle = une zone) ; groupe de chaque zone par des règles de position et de couleur propres à chaque vue (une même couleur sert à plusieurs muscles ; les deux jambes ne sont pas colorées pareil : tibial antérieur repéré par sa place contre le tibia).
- Rattachements : dentelé antérieur → pectoraux ; grand dorsal vu de face → dorsaux ; tenseur du fascia lata → fessiers ; couturier → quadriceps ; vaste latéral vu de dos → quadriceps ; sous-épineux → deltoïdes ; muscles du cou → trapèzes. Bas du dos (fascia, érecteurs) : gris, sans groupe (calque `neutre`) — question posée au propriétaire : 16ᵉ groupe « lombaires » ?
- Nouveaux calques : `contour` (traits de l'image), `ombre` (modelé en noir translucide sur les muscles). Couleurs inchangées : 15 groupes, gris non travaillé, couleur dominante par rôle.
- Dart : `kMapLayers` (neutre, contour, ombre), tailles des vues (face 511 × 980, dos 489 × 976, profil 187 × 980), couleurs des nouveaux calques (et sur la carte du jour teintée), toucher limité aux 15 groupes. Assets : 936 Ko.

## Contrôles
- CI 3D run 36723637430 (essai A vert) : 1011 tests Dart, tests Python (fabrication reproductible, masques, tailles côté Dart), formatage et analyse sans remarque.
- Émulateur sombre et clair : couleur au cœur du grand dorsal = couleur dominante sous le modelé ((229, 88, 88) pour (232, 89, 89) attendu), pectoraux gris ; toucher → « Dorsaux » ; démarcation 0,0 ; aucune vue 3D.
- main a6e0bd7 ; build signé n° 182 (36725473167).
