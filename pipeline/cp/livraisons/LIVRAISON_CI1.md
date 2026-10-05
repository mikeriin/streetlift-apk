# Livraison CI1 — le street calibré dans l'application (dev6.9.0)

Lot CI1 du pipeline « Calibrage des programmes », voie App (tâche « Opus 5.5, effort élevé, application »), lancé le 05/10/2026 vers 11:55 UTC (DECISIONS_CP.md C8.6, C9.1). Validation : conversation de pilotage (C8.1).

- **Version** : dev6.9.0 (`pubspec.yaml` 6.9.0+108).
- **main** : 938de59 — « Kalis Track dev6.9.0 (CI1) : street calibré dans l'application ».
- **Build signé** : run 37328372801 (APK de développement + AAB).
- **Contrôle complet** : `claude/ci-3d`, run 37324228351 (formatage, analyse, suite Dart complète, mode dev, Python, paquets, émulateur CI1 a et b).
- **Paquets** : `kalis_core` 0.4.2, `kalis_plan` 0.2.1, `kalis_adapt` 0.2.1 (branches fixes `etiquettes/…`), `kalis_koach` 0.1.0 inchangé. `etiquettes/kalis_plan-v0.2.2` et `etiquettes/kalis_adapt-v0.2.2` n'existaient pas à la fin du lot : **livré en 0.2.1** ; la mise à jour (deux dossiers et `pubspec.lock`, contrat inchangé) suivra la validation de la correction 1 de CX (C9.1).

## 1. Ce qui change pour l'utilisateur

**Qui reçoit le moteur calibré.** Un profil street (streetlifting, sets & reps, calisthénie ; secondaires street, cardio ou mobilité) au profil v3 complet : expérience, ancienneté, disponibilités. Décidé par `kalis_plan` (`coachEligible`), sans condition codée dans l'application. Un débutant, à qui le parcours ne demande pas son ancienneté, est présenté aux moteurs avec « moins de 6 mois » (sans cela, aucun débutant n'aurait eu le moteur calibré ; DECISIONS_CP.md CI1.4). Les autres disciplines restent au moteur d'avant.

**Séance guidée** (priorité 1) :
- chaque ligne porte son rôle : « Tête » puis « A1, A2… » (séries allégées), « M1… » (minutes d'un EMOM), « T1… » (tentatives), « Éc1… » (montées d'échauffement), « P1… » (paliers), « V1… » (vagues) ;
- sous le titre, un panneau du coach : la technique en clair (« Série de tête puis séries allégées : 1 × 5 (série de tête), puis 3 × 5 à −8 % »), la part du maximum, le tempo (« Descente en 4 s »), la consigne d'exécution ; la **règle de douleur** du programme et les arrêts ou consultations du moteur, toujours visibles (bouclier) ; « Note du coach » ouvre les consignes complètes rédigées par `kalis_plan` dans la feuille de Koach ;
- chronos : EMOM et blocs au temps par le chrono de l'application, mini-repos des clusters / rest-pause / myo-reps, maintiens chronométrés ligne par ligne (déjà en place), repos écrit ligne par ligne (aucun repos entre deux minutes d'un EMOM) ;
- journal : chaque ligne est envoyée au moteur avec son rôle (série de tête, allégée, test, tentative, montée), pour que les séries allégées soient recalculées sur la série de tête réalisée et que les tests soient lus comme tels.

**Saison** (priorité 2) : Réglages › Mon programme › carte « Ta saison » (échéance et compte à rebours, phase en cours, prochaine semaine particulière) → écran MA SAISON : phases datées (construction, intensification, réalisation, affûtage, échéance, allègements, tests), bloc en cours semaine par semaine, règles du programme, échelles des figures.

**Tests et jour J** (priorité 3) : les résultats de test lus par le moteur rejoignent les records du profil (une fois chacun, tests du bloc en cours) ; l'étape des figures est mise à jour sans effacer ce que l'utilisateur a déclaré. Écran « Jour J » depuis la saison : échauffement et tentatives avec leur chance de réussite, objectif (assurer, plus gros total, record), recalcul après chaque tentative notée ; rythme et objectif d'une épreuve de répétitions.

**Koach** (priorité 4) : les codes de raison 0.4 du moteur de suivi s'affichent (plus de texte masqué), paramètres en clair (technique, phase, jour lourd / léger, cause) ; textes de `plan.coach_note`, `plan.pain_rule`, `plan.progression_rule`.

**Programme en cours** : un programme du moteur d'avant finit son bloc tel quel ; à « Préparer le bloc suivant », Koach propose « Passer au moteur calibré » ou « Garder le moteur actuel » (jamais imposé, à refaire à chaque fin de bloc). Le programme de 40 semaines du propriétaire n'est ni régénéré ni servi autrement (aucune saison, aucun report de test sur son bloc importé).

## 2. À tester (conversation de pilotage, puis propriétaire)

1. **Créer un programme street compétiteur** — session de test (5 appuis sur le logo) : Réglages › Profil, mode street, streetlifting, niveau « Avancé », ancienneté « 2 à 5 ans », une compétition principale dans 10 à 14 semaines (règlement au choix) ; Réglages › Mon programme › Créer mon programme → la carte « Ta saison » apparaît.
2. **Vue saison** : « Voir la saison » → phases datées, compte à rebours, semaines d'allègement / test / affûtage du bloc, règles du programme. Bouton « Jour J : tentatives » → tentatives proposées ; marquer « Réussie » ou « Manquée » et voir la suite recalculée.
3. **Séance avec série de tête et séries allégées** : ouvrir une séance du programme qui contient un mouvement lesté de compétition (« Dips lesté », « Muscle-up lesté »…) ; lignes « Tête, A1, A2, A3 », panneau du coach ; valider la série de tête plus lourde ou plus légère que prévu → les séries allégées suivent.
4. **Maintien chronométré** : un exercice tenu (« Hollow body hold », « Support hold ») → chrono sur chaque ligne, consigne « arrête avant de perdre la position ».
5. **Un test** : au bout du bloc (semaine de test), la séance de test (« Série de test », ligne « Test ») ; après la séance, Réglages › Profil › records : le résultat y est.
6. **Créer un programme débutant** : nouvelle session de test, calisthénie, niveau « Débutant » → programme calibré (échelle de poussée, maintiens courts), sans technique avancée.
7. **Session perso** : Mon programme inchangé (« Expert streetlifting (40 semaines) »), pas de carte « Ta saison ».

## 3. Contrôles

| Contrôle | Résultat |
| --- | --- |
| Formatage, `flutter analyze`, analyse des tests d'intégration | vert |
| Suite Dart complète (757 tests) et tests du mode dev | vert |
| `test/ci1_street_test.dart` : compétiteur, débutant, musculation (chemin 0.1), séance série de tête / allégées et journal des rôles, maintien, EMOM, migration, programme du propriétaire, records reportés une fois, textes | vert |
| Tests Python (`tools/tests`, `verify_project.py`, limite de l'arbre 30 Mo), paquets | vert |
| Émulateur CI1 a (sombre, compétiteur) et b (clair, débutant) : saison, jour J, séance guidée, session perso intacte | vert (parties a et b) |
| Build signé APK + AAB | vert (run 37328372801) |
| Rendus de test « captures » (`visual_capture_test.dart`) | en échec avant CI1 aussi (même échec sur les runs de CU) : pas de ce lot |

Relecture indépendante du code (sous-agent Opus) : 6 constats ; 4 corrigés avant livraison (figures du profil écrasées, records en double ou ressuscités, « garder le moteur » qui retirait l'expérience au lieu de l'ancienneté, saison périmée gardée), 1 corrigé en partie (jour J recalculé seulement quand l'objectif ou une tentative change ; repos d'échauffement en secondes), 1 laissé en limite (outil de développement : inspecteur du moteur).

Relevé des programmes générés dans les tests (premiers blocs) : compétiteur 9 séries de tête / 6 maintiens sur 80 prescriptions, saison de 13 semaines (construction, allègement, intensification, réalisation, affûtage, échéance) ; débutant 20 maintiens et 2 tests de répétitions sur 148, aucune technique avancée ; sets & reps 24 EMOM et 9 séries de tête.

## 4. Limites et reste à faire

- Mini-séries d'un cluster ou d'un rest-pause : la ligne porte le total (pas de saisie des parties) ; note de propreté des maintiens et figures non saisie.
- Groupes enchaînés décrits par le moteur (`GroupSpec` : superset, circuit, AMRAP de groupe) affichés comme avant (texte), pas comme groupe.
- Tentatives du jour J : affichées et recalculées, pas écrites au journal (rôle `attempt`, `eventId`).
- Conseils `miniSetsLeft` et `stepExerciseId` du moteur entre les séries non affichés.
- Simulateur du mode dev : ne joue pas les techniques (une ligne = une série).
- Intermédiaire ou plus qui a passé la question d'ancienneté : moteur d'avant tant qu'il ne l'a pas renseignée (recommandation à CP2 : accepter l'absence pour un débutant ou la demander à tous).
- Inspecteur du moteur (session de test) : une revue au premier affichage peut maintenant aussi mettre à jour le profil (risque de reconstruction pendant le dessin, outil de développement seulement).
- Texte « Dernière série ouverte : autant de répétitions que possible » aussi affiché sur un maintien (série repère du moteur) : à dire en secondes (lot suivant).
- Rendus de test « captures » (`visual_capture_test.dart`) en échec sur `claude/ci-3d` depuis avant CU : hors de ce lot, signalé.
- Paquets 0.2.2 de la correction de CX à intégrer quand ils seront validés.

Détail des décisions : `pipeline/cp/DECISIONS_CP.md`, section CI1.
