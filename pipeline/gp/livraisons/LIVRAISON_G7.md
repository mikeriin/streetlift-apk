# Livraison G7 — Création du programme en deux passes, revue, « Où j'en suis »

- **Version** : dev6.5.0 (pubspec 6.5.0+101 ; AAB « 6.5.0 »)
- **Commit main** : c349883 · **Build signé** : run 36931083902
- **Contrôles** : CI `claude/ci-3d` run 36929149412 (formatage, analyse, suite Dart complète, tests du mode dev, paquets dont `kalis_plan` 10 240 profils, tests Python, `verify_project.py`, `package_release.py --check`, `check_release_without_secrets.py --tree`, émulateur G7 a + b)
- **Moteur intégré** : `kalis_plan` 0.1.0 (branche fixe `etiquettes/kalis_plan-v0.1.0`, inchangé) + `kalis_core` 0.1.0

## Ce qui change

1. **Passe 1** (après le profil, ou Réglages › Mon programme › « Créer un nouveau programme ») : Koach présente le bloc ; une carte par jour (« Lundi · 60 min », thème, exercices et rôle, sans séries) ; carte des muscles de la semaine (couleurs de l'Anatomie) et répartition par discipline (part réelle / visée) ; « Autre proposition » et « Proposition précédente ».
2. **Revue exercice par exercice** (cartes à glisser) : raison du choix, carte des muscles, points clés, fiche et démonstration ; « Je sais faire » (verrou), « Je ne sais pas faire » / « Je n'aime pas » → 3 variantes ciblées + « Voir tout » + « Laisse Koach choisir » ; « Ajouter » (recherche dans les 1 039 exercices, jour au choix) ; « Retirer ». Après chaque changement, `kalis_plan` régénère avec tous les verrous ; **Koach montre le diff** (ce qui a bougé et pourquoi, détail par changement) ; « Annuler ce changement ». Récapitulatif, « Valider les exercices ».
3. **Passe 2** : semaine par semaine (introduction, montée, décharge / test), séries × répétitions (ou temps), **flammes visées** (icône + RIR), repos, charges prudentes ou « à calibrer » ; Koach (tableau) explique la logique ; ajustements séries ±1, répétitions, repos — refus expliqué hors bornes ; « Valider mon programme ».
4. **Instance active** : section `planProgram` (v1) lue par l'accueil, le calendrier, les séances, STATS, rappels. Fin de bloc : carte de l'accueil et écran minimal « Bloc suivant » (`nextBlock`).
5. **Session perso** : le programme de 40 semaines reste actif ; « Créer un nouveau programme » ne s'applique qu'après confirmation, à partir de la semaine suivante (semaines passées et historique intacts), retour possible 7 jours tant qu'aucune séance du nouveau n'est saisie.
6. **Où j'en suis** (Réglages › Mon programme ; proposé sur l'accueil après 14 jours sans séance saisie) : semaine + séance ; les séances d'avant sans saisie deviennent « reprise » (neutres ; XP et niveau inchangés, testé).
7. **Session de test** : inspecteur du moteur (propositions et notes détaillées, profil vu par le moteur, contraintes dures, contribution et raisons de chaque exercice, « pourquoi pas un exercice de plus ? ») ; journal du moteur exporté en JSON.
8. **Retraits** : générateur L10 (`program_generator.dart`, `assets/program_models.json`, écrans de génération / régénération, cycle suivant). Instances L10 existantes lisibles et affichées telles quelles.

## Tests retirés avec la fonctionnalité (L10)

`test/l10_generator_test.dart`, `test/l10_profiles_test.dart` (+ `test/goldens/l10_profils_types.md`), `test/l10_properties_test.dart`, `test/l10_screens_test.dart`, `tools/tests/test_program_models.py` ; dans `test/l10_store_test.dart` : génération au départ, régénération, annulation, mode Guidé, cycle suivant, fichier de modèles (remplacés par un test de compatibilité d'une instance L10 existante). Modifiés : `g6_profil_test` (fin du profil : « Ton profil est prêt » ; feuille « touche ton programme » : « Plus tard »).

## Tests ajoutés

`test/g7_plan_test.dart` (contrat INTEGRATION.md § 4, propositions, revue complète avec verrous et annulation, passe 2 et bornes, instance active / sauvegarde / import strict, programme du propriétaire + retour 7 jours, « reprise » neutre + XP inchangés + journal des moteurs, textes de tous les codes `plan.*`, écrans), `test/g7_mode_dev_test.dart`, `integration_test/programme_g7_test.dart` (11 captures × 2 thèmes).

## À tester par le propriétaire

1. **Session de test** (5 appuis sur le logo) : profil « débutant maison », puis « Créer mon programme » : passe 1, autre proposition, revue (remplace 2 exercices et lis le diff de Koach, essaie « Annuler ce changement »), passe 2 (touche un exercice, essaie +2 séries), « Valider mon programme ».
2. Recommence avec un profil **street** (mode street).
3. **Session perso** : Réglages › Mon programme › « Où j'en suis » (regarde sans valider si tu veux) ; « Créer un nouveau programme » demande une confirmation avant de remplacer quoi que ce soit.

## Limites

- Les bornes des ajustements de la passe 2 sont tenues par l'application (un fichier, `checkAdjust`) : `kalis_plan` 0.1.0 n'expose pas de vérification ; à remplacer par une API du moteur.
- Résumé d'adaptation du bloc suivant : séances prévues / faites seulement (confiance 0) jusqu'à `kalis_adapt` (G9).
- Temps du moteur sur émulateur (debug, rendu logiciel) : ≈ 4 s de l'appui à la passe 1 affichée ; à mesurer sur le téléphone (build release).
- La séance elle-même (flammes, bilan santé, charges) arrive en G9 : en G7, la séance garde l'écran actuel avec les prescriptions du programme créé.
- Contenu sportif non relu par un professionnel diplômé (registre de `kalis_plan`).
