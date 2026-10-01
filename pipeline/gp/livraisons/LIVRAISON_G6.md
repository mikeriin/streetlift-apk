# Livraison G6 — Création du profil (dev6.4.0)

Date : 01/10/2026 · Piste A · Statut : **à valider par le propriétaire**
Version : **dev6.4.0** (pubspec 6.4.0+99) · Commit `main` : 9fdf48b · Build signé : run 36904901143
Contrôles : CI `claude/ci-3d` run 36901898040 (essai 5) — formatage, analyse, 883 tests Dart (+15 du build de dev), 160 tests Python, `verify_project`, `package_release --check`, sans secrets, paquets `kalis_core` et `kalis_koach`, émulateur G6 a (sombre, rouge) et b (clair, violet) : **verts**. Rendus `visual_capture_test` : échec déjà présent sur `main` (inchangé).

## Ce qui change
- **Création du profil guidée par Koach** (≈ 5 min, 12 écrans, une question par écran, barre de progression, retour arrière, reprise du brouillon) qui remplit exactement le profil d'athlète v2 de `kalis_core` (contrat GC inchangé, `packages/` non modifié) : accueil + avertissement L13 ; toi (prénom/pseudo, sexe, année — 18 ans et plus —, taille, poids facultatif expliqué) ; discipline principale (8, phrase + pose) ou mode street ; 1 à 2 secondaires dosées (« environ 1 séance sur 5 en mobilité ») ; niveau par mouvement en fourchettes + « Je ne sais pas » + expérience ; objectifs (performance datée, habitude, « Laisse Koach proposer », principal = premier) ; jours + durée par jour (20…90 min ou libre) ; lieux, matériel de la base regroupé (68 termes), préréglages, matériel par lieu, lieu du jour ; santé (questionnaire L13, carte du corps + articulations, gêne 0-10) ; aimés/détestés ; mode assisté/libre avec exemples ; récapitulatif modifiable.
- **« Créer mon programme »** : enregistre le profil ; sans programme (session de test, installation neuve), Koach annonce « Ton programme arrive bientôt » (G7).
- **Session perso** : à l'ouverture, Koach propose de refaire ton profil (pré-rempli depuis l'ancien), « Plus tard » une fois par jour au plus ; programme, historique et réglages inchangés (test chiffré + émulateur : session perso identique clé par clé).
- **Réglages › Profil** : chaque rubrique se modifie seule ; Koach signale un changement qui touche le programme. Mode prudent, accord santé, accord du médecin inchangés.
- Sauvegarde : nouvelle section `athleteProfile` v1, facultative ; anciennes sauvegardes importées sans erreur (profil L8 lu, gardé).

## Retraits (et tests retirés avec eux)
- Démarrage court L8, confirmation d'une installation existante (KT-043), questions progressives (KT-040), écran Profil L8 (`lib/profile_screens.dart`).
- Tests : `test/l8_profile_screens_test.dart`, `test/g1c1_brouillon_profil_test.dart` (repris par `g6_profil_test`), et dans `test/l8_profile_test.dart` : `defaultsForLevel`, groupe « questions progressives » (2), « questions progressives : au plus une par séance », « migration du propriétaire (KT-043) », « étape par défaut sans objectif final ».

## Fichiers principaux
`lib/athlete_profile.dart`, `lib/athlete_profile_store.dart`, `lib/athlete_profile_flow.dart`, `lib/athlete_profile_screen.dart`, `lib/goal_suggestions_g6.dart` (provisoire, à retirer en G12) ; tests `test/g6_profil_test.dart`, `test/g6_mode_dev_test.dart`, `integration_test/profil_g6_test.dart` (cible émulateur par défaut, G5 sous `CI3D_TOUT=1`).

## À tester
1. Session de test (5 appuis sur le logo) : création complète du profil, chronomètre (≈ 2 min 35 sur émulateur avec des réponses rapides) ; Koach à chaque étape ; « Ton programme arrive bientôt ».
2. Session perso : Koach propose « Refaire mon profil » → refais-le ; vérifie que ton programme, ton historique et tes réglages sont intacts ; Réglages › Profil : modifie une rubrique (ex. disponibilités) → Koach signale l'effet sur le programme.

## Limites
- Fourchettes des mouvements et règles « Laisse Koach proposer » : choix raisonnés non relus par un professionnel.
- `loadIncrements` laissé vide (pas par défaut du moteur). L10/L11 gardent leurs anciens champs jusqu'à G10 ; avec un profil v2, l'ancien générateur L10 n'est plus proposé.
- Carte du corps : les articulations sans région (genou, poignet…) se choisissent dans la liste.
