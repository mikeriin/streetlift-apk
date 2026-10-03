# Livraison CU — parcours de création du profil v3 dans l'application

Lot CU du pipeline « Calibrage des programmes » (voie App, Opus 5.5, effort élevé). Livré le 03/10/2026.
Validation : **propriétaire** (statut « à valider »).

| | |
| --- | --- |
| Version | **dev6.8.0** (`pubspec.yaml` 6.8.0+107) |
| Commit `main` | `6467bc2` — « Kalis Track dev6.8.0 (CU) : parcours de création du profil v3 » |
| Build signé | run `37126824436` (`build-apk.yml`, APK de développement et AAB) |
| Contrôle complet | `claude/ci-3d`, run `37125421224` |
| Paquet | `kalis_core` **0.4.0** (`etiquettes/kalis_core-v0.4.0`) ; `kalis_plan` 0.1.0, `kalis_adapt` 0.1.0, `kalis_koach` 0.1.0 inchangés |

## Ce qui change pour toi

- **La création du profil pose les questions qui comptent pour toi.** Un débutant répond à 16 à 18 questions selon sa discipline et ne voit aucune question sur sa récupération ; un pratiquant régulier dit en plus depuis quand il s'entraîne, s'il a arrêté récemment, ses records, ses échéances ; un compétiteur voit les questions de la compétition (records au standard, tentatives, catégorie, règlement pré-rempli Final Rep ou ISF), ses points faibles et sa charge actuelle.
- **Deux nouveaux écrans** : « Ton expérience » (niveau, ancienneté, arrêt récent) et « Ta récupération » (sommeil et stress habituels, journées assises / debout / physiques, autres sports, poids voulu). Les records passent avant les fourchettes, qui ne portent plus que sur les mouvements sans record (4 au plus pour un débutant).
- **Les gênes se précisent** : depuis quand, la gêne à l'effort, ce qui la réveille, « C'est ancien, je ne sens plus rien » — des contraintes d'entraînement, jamais un diagnostic (L13 inchangée).
- **Poids demandé en street** (et en streetlifting, street workout, calisthénie) : sans lui, ni charge totale ni lest.
- **« Passer » et « Je ne sais pas »** laissent la réponse vide : l'application n'invente rien.
- **Compléter mon profil** : ton profil existant passe au nouveau format sans rien perdre ; Koach t'invite une fois, sur l'accueil, à répondre aux nouvelles questions (toutes facultatives) ; l'entrée reste dans Réglages › Profil. Ton programme ne change pas.
- **Tests guidés** (Réglages › Profil › Tests guidés, et Koach sur l'accueil à la première séance) : quand une capacité utile est inconnue, un test court, avec ses consignes de sécurité ; le résultat (en fourchette) rejoint tes records. Aucun test pour un débutant ou sans questionnaire santé.

## Nombre de questions par profil type

Contrôlé dans l'application (`test/cu_profil_v3_test.dart`, profils de `packages/kalis_core/test/fixtures/profiles_v3.json`) : mêmes nombres que `PARCOURS_V3.md` § 2, et le flux montre exactement ces questions, écran par écran.

| Profil type | Questions à la création | Écrans sans question (non montrés) |
| --- | ---: | --- |
| Débutant, forme générale | **16** | Ta récupération, Tes préférences |
| Intermédiaire, musculation | 27 | — |
| Compétiteur élite, streetlifting | **29** | — |
| Coureuse, 10 km | 28 | — |
| Sets & reps, avancé | 29 | — |

Débutant selon sa discipline : 16 (forme générale, mobilité, street workout), 17 (musculation, CrossFit, streetlifting, calisthénie), 18 (cardio).

## À tester

1. **Parcours débutant** — session de test (5 appuis sur le logo) : forme générale, niveau « Débutant ». Écrans : Toi, discipline, dosage, Ton expérience, Ce que tu sais faire (4 fourchettes), objectifs, jours, lieux, santé, mode, récapitulatif. Pas d'écran Récupération ni Préférences.
2. **Parcours compétiteur** — depuis le récapitulatif (ou une nouvelle session de test) : mode street, streetlifting (le poids est demandé), niveau « Élite » (ancienneté, arrêt), un record (traction lestée, 3 répétitions, en compétition, au standard), une compétition principale avec le règlement « Final Rep », ta catégorie, puis « Ta récupération ».
3. **Compléter mon profil** — session perso : la carte de Koach sur l'accueil (une seule fois), puis les nouvelles questions ; Réglages › Profil › Compléter mon profil. Vérifie que ton programme et ton historique n'ont pas bougé.

## Contrôles

- CI rapide (`claude/ci-cu-rapide`, 4 essais) : formatage, analyse, tests choisis.
- Contrôle complet `claude/ci-3d` : formatage, `flutter analyze`, suite Dart complète, tests du mode dev, tâche `packages`, Python (`verify_project.py`, allégations L13), `package_release.py --check`, `check_release_without_secrets.py --tree`, émulateur (`integration_test/profil_cu_test.dart`, parties a sombre et b clair) — tout vert au 4e essai (essais 1 à 3 : test d'intégration corrigé — liste paresseuse, clavier ouvert, émulateur lent ; cadres des feuilles en thème sombre et noms courts des échéances corrigés après lecture des captures).
- Tests du lot (`test/cu_profil_v3_test.dart`) : parcours (asset identique au paquet, 31 questions), profils types (questions vues, reportées, tests permis), débutant par discipline, chaque condition d'apparition depuis le brouillon, poids obligatoire, profil v3 construit et relu (contrat, catalogue, aller-retour, `lifestyleUpdatedOn`), réponses devenues sans objet, fourchettes du débutant, migration v2 → v3, profil stocké de dev6.7.0 relu sans perte, invitation (existant, puis après la première semaine), sauvegarde exportée et réimportée à l'identique, programme créé par les moteurs actuels pour chaque profil type, tests guidés (aucun pour un débutant, proposition, conversion, enregistrement), écrans (flux de chaque profil type en sombre et en clair, débutant et poids en street, record, échéance avec règlement, Compléter mon profil, 200 % de texte).
- Tests adaptés (comportement changé par le lot) : `test/g6_profil_test.dart` (écrans d'un débutant, profil au schéma 3, poids en street), `test/g2_*`, `test/g3_mode_dev_test.dart` et `tools/tests/test_g2_retrait.py` (version 6.8.0), `integration_test/profil_g6_test.dart` et `programme_g7_test.dart` (écran Expérience, écran Récupération). Aucun test retiré ni désactivé.

## Limites

- Les **moteurs actuels** (`kalis_plan` 0.1, `kalis_adapt` 0.1) ignorent les nouvelles réponses : elles serviront aux moteurs calibrés (lot CI). Les 38 textes de Koach des nouveaux codes de raison sont en place avec un rendu générique (ces codes ne sont pas encore émis).
- **Tests guidés** : le tri par mouvement (prérequis, matériel, gêne) est un choix du lot ; les tests sous-maximaux sont proposés à partir du jour de départ du programme, pas encore prescrits dans la séance par le moteur (CI).
- **Une sauvegarde de dev6.8.0 ne se relit pas en dev6.7.0** (profil au schéma 3, annoncé par CQ).
- Raccourcis de date des records : « il y a 1 à 3 mois » enregistre 61 jours avant la saisie.
- Décisions gardées malgré les recommandations de CQ (à toi de trancher) : 1 à 2 disciplines secondaires (D3.2), taille obligatoire, mode assisté / libre et fourchettes demandés au débutant dès la création.
- Contenu sportif non relu par un professionnel diplômé.

## Décisions du lot

`pipeline/cp/DECISIONS_CP.md`, section CU (CU.1 à CU.17).
