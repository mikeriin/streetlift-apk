# Kalis Track — Refonte UI 2.2.3

Mise à jour : 21 septembre 2026. Version **2.2.3+46**.

Cette livraison corrige le chrono de fin d'exercice et applique la palette
bordeaux / anthracite sur l'ensemble des écrans. Les transitions, l'acquisition
des WOD par crédits et le suivi unifié STATS sont conservés. Navigation :
**ARSENAL · STATS · PROGRAMME · RÉGLAGES**.

## Corrections — intégré

- [x] Repos lancé après la dernière série d'un exercice (transition vers le suivant).
- [x] Myo-reps : micro-repos entre séries, repos complet en fin, puce « Repos final » exacte.
- [x] Boutons de mode lisibles (texte blanc cassé sur bordeaux).
- [x] Boutons de suppression lisibles (rouge d'action, texte blanc cassé).
- [x] Sous-titre du réglage Thème conforme au choix.
- [x] Sous-pages Réglages sans titre doublé.
- [x] Style `headlineMedium` remplacé par un style défini par le thème.

## Palette — intégré

- [x] #6B0C0C : boutons pleins, cartes de marque, base des jauges.
- [x] #A61717 : navigation, segments, indicateur STATS, curseur de semaine, points d'étape, branche de l'arbre, Acheter, intra-cluster, médailles, alertes et effort du chrono, suppression.
- [x] Accent texte / icônes : #E85959 en sombre (4,77:1 sur #1E1E1E), #6B0C0C en clair.
- [x] Vert réservé à la validation : séries, séances, badges, cibles, WOD acquis, chrono terminé.
- [x] Chiffres du chrono en #F4F4F4 ; libellé coloré selon l'état.
- [x] Jauges en dégradé #6B0C0C → #A61717 sur piste #333333 (`KProgressBar`).
- [x] Carte musculaire : rampe bordeaux → rouge.
- [x] Formats de WOD en accent (routine neutre) ; lift principal en accent, prévention en gris.
- [x] Icônes de menu sur pastille teintée ; sélection de liste et de puces teintée.
- [x] Thèmes clair et sombre ; contraste ≥ 4,5:1 pour tous les rôles textuels.

## Conservé

- [x] Programme : J1 à J7, slider, résumés, indicateur de niveau.
- [x] STATS : Aperçu, Parcours, Performances, Historique.
- [x] Arsenal : séances personnelles, catalogue et achats WOD.
- [x] Calculs, journal, XP, crédits, notifications, import / export, signature.

## Validation et livraison

Voir `AUDIT_2.2.3.md`. Aucune analyse, compilation, test ni capture n'a pu
être exécuté dans l'environnement de livraison ; le workflow GitHub reste le
point de contrôle avant l'APK.

## Historique

Les checklists 1.8.7 à 2.2.2 restent dans `docs/REFONTE_UI_*.md`.
