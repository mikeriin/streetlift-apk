# Livraison G6 correction 1 — dev6.4.1

Date : 01/10/2026 · Piste A · Statut : **à valider par le propriétaire**
Version : **dev6.4.1** (pubspec 6.4.1+100) · Commit `main` : 9b82b86 · Build signé : run 36917354059
Contrôles : CI `claude/ci-3d` run 36914114452 (essai 2) — formatage, analyse, 886 tests Dart (+15 du build de dev), tests Python, paquets, émulateur G6 a (sombre) et b (clair) : **verts** (rendus `visual_capture` : échec déjà présent sur `main`).

## Corrections demandées
1. **Modifier un objectif sans le supprimer** : crayon (ou appui sur l'objectif) → feuille pré-remplie ; même identifiant, même place (principal gardé).
2. **Exercices manquants dans la recherche aimés / détestés** : la liste s'arrêtait à 8 résultats. Maintenant tous les résultats par pages (20, puis « Afficher plus » +40) avec leur nombre ; sans recherche, les exercices de tes disciplines ; avec une recherche, toute la base (1 039). Idem pour « Autre exercice… » des objectifs.
3. **Explications de la création et de la gestion du programme** : « Comment marche ton programme ? » (Koach, 8 étapes) sur l'accueil du flux, le mode, le récapitulatif, l'écran de fin, Réglages › Profil et l'onglet Programme.
4. **Programme affiché après une première création du profil** : avec un profil v2 sans programme, l'onglet Programme n'affiche plus le programme de 40 semaines ni son choix de date de départ ; Koach annonce le programme à venir (G7). Ton propre programme (départ fixé) n'est pas concerné.
5. **Koach actif par défaut** et **« Koach adapte la structure » par défaut** : activés à l'enregistrement du profil quand Koach n'a jamais été activé ; un Koach que tu as désactivé reste désactivé.

## Tests
`test/g6_profil_test.dart` : objectif modifié en place, recherche complète et paginée, onglet Programme en attente + explication, Koach actif et structure par défaut ; émulateur : onglet Programme en attente (programme embarqué absent) et feuille d'explication en clair et sombre.

## À tester
Session de test : crée un profil, modifie un objectif (crayon), cherche « traction » dans les exercices aimés (« Afficher plus »), ouvre « Comment marche ton programme ? », puis l'onglet Programme : plus de programme de 40 semaines. Réglages › Koach : actif, structure adaptée.
