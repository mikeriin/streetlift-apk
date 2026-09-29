# Livraison M6b — correctifs du mannequin fixe (Kalis Track 5.5.5)

**Date** : 29/09/2026 · **Version** : 5.5.5+84 · **Commit main** : 019fa08 (« Kalis Track 5.5.5 (M6b) : correctifs du mannequin fixe (11 défauts corrigés après audit) ») · **Build signé** : run 36601660192 (n° 159) · **CI 3D** : run 36599218965 (essais A à E sur `claude/ci-3d`) · **Modèle** : Opus 5.5, effort élevé · **Base** : main 9826982 (5.5.4+83)

## Ce qui a été fait
Audit de tous les écrans du mannequin fixe (`docs/AUDIT_M6b.md`) : code relu écran par écran, captures du vrai rendu en sombre et en clair, 360 × 640 dp et grand écran (800 × 1280 dp), texte à 130 %, animations réduites ; relevé de démarcation vue / support (0 partout). 11 défauts corrigés :

| # | Défaut | Gravité | Correction |
| --- | --- | --- | --- |
| D1 | Anatomie : « Muscles profonds » sans effet, compté dans « Filtres · n » | majeur | Case retirée ; Affichage = « Os » |
| D2 | Fiche traction (et 110 exercices) : 3/4 avant, halo du dorsal lu comme un pectoral | majeur | Vue de départ départagée par l'aire des régions des principaux (traction → Dos) |
| D3 | Moteur 3D : cadre sombre autour du mannequin | majeur | Fond de la page |
| D4 | Moteur 3D : aucun halo en rotation | majeur | Halo suivant la caméra de chaque image |
| D5 | Accueil : halo invisible sur la carte du jour (couleur sur couleur) | majeur | Halo de la couleur du texte de la carte |
| D6 | Légende des rôles en pastilles pleines | mineur | Pastilles « halo » |
| D7 | « en rouge » au lecteur d'écran | mineur | « mis en évidence par un halo » |
| D8 | « 1 actifs » au lecteur d'écran (Filtres) | mineur | Accord en nombre |
| D9 | Fiche sur tablette : mannequin petit | mineur | 45 % de la hauteur, 380-600 dp |
| D10 | Crédits : « gris à 50 % » | mineur | Texte à jour |
| D11 | Rotation possible derrière l'indicateur de chargement | mineur | Vue changée sans transition avant la scène |

## À tester
- **Arsenal › Référence › Anatomie** : « Filtres · 1 » au départ ; le menu n'a plus « Muscles profonds », seulement « Os » ; touche un muscle : son nom.
- **Arsenal › Exercices › Traction pronation** (et chin-up, rowing) : s'ouvre de dos, halo sur les dorsaux ; légende en pastilles halo. Dips, squat : 3/4 comme avant.
- **Accueil › carte du jour** : halo clair autour des muscles de la séance, visible sur le fond bordeaux.
- **Réglages › À propos › Moteur 3D** : plus de cadre ; halo sur les muscles de la traction pendant la rotation.

## Contrôles
- Dart : formatage et analyse sans remarque, 963 tests, 0 échec (`test/m6b_correctifs_test.dart` ajouté ; m3, m4b, m4c adaptés au filtre retiré et à la vue par l'aire).
- Python : 106 tests (aires des régions recalculées depuis le GLB), `verify_project`, `package_release --check`, `check_release_without_secrets --tree`.
- Émulateur : `audit_m6b_test` parties a et b vertes, captures regardées (Anatomie, fiches, STATS, accueil, WOD, Moteur 3D, grand écran).

## Non corrigés
Halo sans test d'occlusion (petite tache possible à travers le corps) ; toucher d'une aponévrose sans bulle (voulu) ; régions morcelées du modèle (lot de modèle) ; rendus de test `visual_capture_test` déjà en échec sur main (sans lien 3D).

## Page de suivi
https://claude.ai/artifact/KknJkZqegaxWrFsmMaomsA (section « M6b »)
