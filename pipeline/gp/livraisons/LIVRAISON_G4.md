# Livraison G4 — moteur statique `kalis_plan` 0.1.0 (piste M)

01/10/2026 — Fable 5.1, effort maximal (tâche B). Branche `moteurs`, commit `bbdb497`
(« Kalis Track moteurs (G4) : kalis_plan 0.1.0 »). Contrôle : run `ci-paquets` n° 36877967988 vert sur
`claude/ci-gp-moteurs` (formatage, `dart analyze --fatal-infos` sans remarque, 121 tests Dart dont
10 240 profils aléatoires, simulateur). Rien ne change dans `lib/` de l'application.

**Étiquette** : branche fixe `etiquettes/kalis_plan-v0.1.0` sur `bbdb497` (le push d'étiquettes est refusé
aux sessions). Récupération par un lot de la piste A : `git fetch origin etiquettes/kalis_plan-v0.1.0` puis
`git checkout FETCH_HEAD -- packages/kalis_plan`.

## Ce qui est livré

| Élément | Où (`packages/kalis_plan/`) |
| --- | --- |
| `KalisPlan implements PlanEngine` : `createPass1`, `review`, `variants`, `createPass2`, `nextBlock`, `restructure` — Dart pur, sans horloge ni entrée-sortie | `lib/` |
| Passe 1 : vivier sous 10 contraintes dures, note explicite à 14 composantes (sécurité puis qualité), glouton avec anticipation, recuit simulé seedé (12 000 coups), descente, départage par hachage FNV-1a | `lib/src/context.dart`, `score.dart`, `search.dart` |
| « Autre proposition » par la graine (note à moins de 3 % de la meilleure, un tiers d'exercices différents visé) | `lib/src/engine.dart` |
| Revue (su, pas su, je n'aime pas, retirer, remplacer, ajouter), variantes, régénération à diff minimal avec verrous | `lib/src/engine.dart`, `variants.dart`, `diff.dart` |
| Passe 2 : séries, plages, flammes visées, repos, charges de départ prudentes, semaines d'introduction, de montée, de décharge, de test | `lib/src/pass2.dart` |
| Bloc suivant et restructuration (séance, semaine, fin du bloc) | `lib/src/engine.dart` |
| `PlanInspector` : relecture des contraintes, note relue, « et si j'ajoutais… » | `lib/src/inspect.dart` |
| Ligne de commande `dart run kalis_plan:plan --profile <json> --seed <n> --pass 1\|2 [--locks <json>]` ; simulateur `bin/kalis_plan_cli.dart --rapport <dossier>` | `bin/` |
| Contrat : problème, contraintes, note, paramètres (chacun avec sa référence, sa mesure ou « hypothèse »), invariants testés, limites, registre de validation, 46 références | `CONTRAT.md` |
| Validation | `docs/VALIDATION.md`, `docs/PROFILS_TYPES.md` (les 40 programmes), `docs/COMPARAISON_L10.md`, `docs/MESURES.md` |

## Résultats (run 36877967988)

- **40 profils types** : 0 contrainte dure violée, note de 0,918 à 0,976 (moyenne 0,958), aucune séance
  au-delà du temps donné. Programmes lus en entier ; dix défauts de la note corrigés à la lecture
  (`docs/VALIDATION.md`, § 2).
- **10 240 profils aléatoires** : 0 échec. Sur 1 000 autres : 0 programme invalide, 3 avec une séance de repli.
- **Temps** (machine du contrôle) : génération complète 50 ms en médiane, 96 ms au pire sur les profils
  types, 212 ms au pire sur 1 000 profils (budget 1 s) ; régénération 7 ms en médiane, 46 ms au pire
  (budget 300 ms). À remesurer sur téléphone.
- **Non-ressemblance à ton programme** : indice de Jaccard maximal 0,154 pour ton propre profil, 0,227 sur
  1 000 profils, pour un seuil de 0,30 (le premier décile de la ressemblance de ton programme avec
  lui-même d'un bloc à l'autre). Aucun de tes accessoires de street sur-représenté chez les autres profils.
- **Face au générateur L10**, mêmes 40 profils :

| Critère | L10 | kalis_plan |
| --- | --- | --- |
| Profils dont chaque discipline a un programme | 9 sur 40 | 40 sur 40 |
| Erreur de dosage, moyenne | 23,8 points | 0,4 point |
| Séances plus longues que le temps donné | 33 sur 143 | 0 sur 143 |
| Temps donné utilisé | 91 % | 95 % |
| Tirage et poussée équilibrés | 21 sur 27 | 24 sur 27 |
| Chaîne postérieure et genou équilibrés | 13 sur 27 | 26 sur 27 |
| Groupes majeurs sous 4 séries par semaine, par profil | 0,7 | 0,8 |
| Groupes majeurs au-dessus de 20 séries par semaine, par profil | 1,5 | 2,3 |

  Les deux dernières lignes ne sont pas meilleures ; elles sont expliquées dans `docs/VALIDATION.md`, § 5
  (matériel absent ; séries de pratique comptées à plein par ce comptage simple).

## Relecture indépendante

Un second lecteur automatique a relu code, contrat et validation avant la livraison : 17 constats, dont 5
affirmations que le code ou les tests ne soutenaient pas. Tout est corrigé ou écrit comme limite
(`docs/VALIDATION.md`, § 8) : portée réelle des tests, restructuration relue, cache lié au catalogue,
exponentielle portable, mode prudent (un niveau de 1 montait à 2 ; profil sans questionnaire désormais
traité comme prudent), ligne de commande.

## Limites

- **Contenu sportif non relu par un professionnel diplômé** (bandes de volume, seuils de gêne, comptage
  des séries de pratique pour moitié, choix des exercices). Premier point à faire relire : le comptage des
  séries de pratique.
- Le moteur rend le meilleur programme trouvé, pas un optimum prouvé ; beaucoup de programmes se valent au
  sens de la note.
- Niveau, prérequis et « trop facile » ne sont pas revérifiés par un second code.
- Déterminisme entre machines construit, mais vérifié sur une seule ; le Web n'est pas pris en charge.
- Pas de découpage imposé, pas de formats CrossFit codifiés, pas de plan d'allure en cardio ; petits groupes
  (mollets, lombaires, ischio-jambiers) souvent sous leur bande sans matériel. Liste complète : `CONTRAT.md`, § 9.

## Pour la suite

- G8 (`kalis_adapt`) part de `moteurs` (bbdb497). Son lancement sur la tâche Fable A est tenté en fin de lot ; en cas de refus, `ETAT_GP.md` le dit et le pilotage le lance.
- G7 (piste A) récupère `packages/kalis_plan` par la branche fixe ; `README.md` donne l'exemple d'appel.
- À lire par le propriétaire : `packages/kalis_plan/docs/PROFILS_TYPES.md` (le programme de ton profil est
  `proprietaire_streetlifting_avance`) et `docs/VALIDATION.md`.
