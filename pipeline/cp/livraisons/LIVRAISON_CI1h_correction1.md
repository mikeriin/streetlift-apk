# Livraison CI1h correction 1 — séance future au jour réel, volume écrit des lignes à charge fixe (dev6.11.3)

Lot CI1h, passe de correction 1 (DECISIONS_CP.md C15.9, lancée par le propriétaire, C15.11), voie App, tâche « Opus 5.5, effort élevé, application ». Message sans ligne « Lot : » : seul lot de la voie App « à faire ». Consigne gardée : au plus pragmatique (C15.7). Validation : conversation de pilotage.

- **Version** : dev6.11.3 (`pubspec.yaml` 6.11.3+116) — UI5 n'avait pas publié sur `main` (pointe 9ef40dad, dev6.11.2).
- **main** : e351f274 — « Kalis Track dev6.11.3 (CI1h correction 1) : séance future au jour réel, volume écrit des lignes à charge fixe » (parent 9ef40dad, arbre f3b6f3c1), publiée en avance rapide.
- **Build signé** : **en échec, hors lot** — run 38118843803 (main e351f274), deux essais (le second = la seule relance) : formatage et analyse verts, puis trois tests de `test/m8_carte_2d_test.dart` (carte musculaire 2D, non touchée) bloqués 10 min chacun (décodage d'image dans `runAsync`) ; même échec ce matin sur le même arbre (run 38116693260, commit de contrôle) et sur la branche de UI5 (run 38116802970, sans ce lot). Le contrôle complet, lui, passe ces mêmes tests (run 38116693282). Pas d'APK publié pour dev6.11.3.
- **Contrôle complet** : `claude/ci-3d`, run 38116693282, vert (commit de contrôle de6edbc2, arbre f3b6f3c1 identique à main) : formatage, analyse, Python, 830 tests Dart, mode dev, paquets, builds debug et profile, émulateur (cibles existantes, codes à 0) ; rendus « captures » en échec comme depuis avant CU.
- **Paquets inchangés** (`kalis_core` 0.4.3, `kalis_plan` / `kalis_adapt` 0.3.1) ; rien dans `packages/` ; ni `refonte-ui` ni écran touchés.
- Accès : `add_repo` absent de la session ; push vérifié (`git push --dry-run`, puis push de la ligne « en cours » sur `pipeline`).
- Mise au point : `claude/ci-ci1h-c1-rapide` (essai 2 vert, run 38116015121 : analyse, tests Dart du lot, de CI1h, CI1b à CI1g, G9, G2, mode dev G2/G3 ; Python en échec attendu sur cette branche sans `build-apk.yml`).

## 1. Causes

**Défaut A — dead-hang en tête de S14·J6 ouverte en avance (cause du pilotage confirmée par test).** dev6.11.2 prescrivait une séance future à sa date prévue (`adaptPlanDay`) avec le journal d'aujourd'hui. Test `ci1h_correction1_test.dart` « même séance ouverte le samedi… » : à la date du samedi 17/10, avec S14·J4 et J5 non faites, le moteur ajoute en tête `j4-sl-dead-hang-leste` (test, rôle « test ») avant les muscle-ups — c'est exactement ce que voyait le propriétaire le dimanche 11/10, puisque dev6.11.2 calculait la séance « au samedi ». Au jour réel (dimanche), la séance est servie telle qu'écrite : muscle-up strict, tractions explosives, squat, relevés de jambes, mobilité (relevé `CI1H1|A|dimanche`).

**Défaut B — squat endurance sous les 14 répétitions écrites (cause établie par test).** La contrainte de CI1h remettait la charge à 70 kg mais **gardait les répétitions que le moteur avait calculées pour sa propre charge, plus lourde** (plafonnées seulement par le haut). Journal synthétique proche du propriétaire (S13·J6 faite à 77,5 kg ; B20 = 32 → ligne écrite 3 × 14) — relevés `CI1H1|B|cause` :

| S13·J6 | Jour de calcul | Moteur seul | dev6.11.2 servait | dev6.11.3 sert |
| --- | --- | --- | --- | --- |
| 77,5 × 14, 1 en réserve | dimanche 11/10 | 3 × 14-20 à 75 kg (série repère) | 3 × 14 à 70 kg | 3 × 14 à 70 kg |
| 77,5 × 14, 1 en réserve | samedi 17/10 (date prévue) | 3 × 13-19 à 77,5 kg | **3 × 13** à 70 kg | 3 × 14 à 70 kg |
| 77,5 × 11, 0 en réserve | samedi 17/10 | 3 × 13-14 à 77,5 kg | **3 × 13** à 70 kg | 3 × 14 à 70 kg |
| 77,5 × 14, 3 en réserve | dimanche et samedi | 3 × 13-19 à 77,5 kg | **3 × 13** à 70 kg | 3 × 14 à 70 kg |

Le moteur règle charge et répétitions ensemble pour tenir l'effort cible (« série repère » à 77,5 kg : borne basse à 13) ; à la date prévue, la semaine paraît en plus manquée (`adapt.resume_after_break`). Avec le vrai journal du propriétaire (séries plus dures), la borne basse descend jusqu'à 11 ; le mécanisme est le même (non rejoué : journal réel sur le téléphone).

## 2. Ce qui change

- **Jour réel (C15.9)** : `adaptPlanDay` retiré ; `adaptPlannedSession` (ouverture d'une séance non commencée et chaque ligne de « La prochaine fois ») et la represcription avec bilan calculent au jour réel. Un seul calcul gardé (C15.4). La séance reste recalculée à chaque ouverture (CI1c) : le jour venu, elle suit l'état réel (un test réellement manqué est reporté normalement). Ligne « Prévision : je recalcule chaque séance le jour venu, avec ton bilan. » et séance visée avec sa date : gardées.
- **Volume écrit (C15.9)** : sur une ligne à charge fixe, `fixedLoadItem` sert la charge **et** les séries, répétitions ou secondes écrites (ligne du bloc avec les ajustements de Koach acceptés). Exceptions (le moteur peut baisser, jamais au-delà de l'écrit) : douleur (prescription ou ajustement de l'exercice, reprise graduée), bilan du jour bas donné (forme, sommeil : toute la séance), temps disponible court, reprise après coupure et conduite d'endurance (reprise, bilan, douleur de jambe) quand le moteur a réellement réduit cet exercice. Conseils entre séries : inchangés (CI1h). Séries rétablies : technique et cibles par série écrites (sinon celles du moteur prolongées) ; le « une série de moins » correspondant est retiré des ajustements ; repli « charge seule » de CI1h si la prescription sortait du contrat.
- **Choix (C8)** : « temps court » compté comme bilan du jour (fait donné par l'utilisateur) ; `adapt.resume_after_break` posé par le moteur au niveau de la séance dès 7 jours sans séance ne suffit pas (il ne retire des séries qu'à partir de 14 jours) — sinon le défaut B revenait après une semaine sans séance (relecture indépendante).

## 3. Lignes d'écran (pour UI5, U0.21)

Aucune. Fichiers touchés : `lib/session_adapt_store.dart`, `lib/adapt/session_adapt.dart` (logique), `lib/settings_screen.dart` (`kVersion` seulement), tests, docs.

## 4. Contrôles

| Contrôle | Résultat |
| --- | --- |
| `test/ci1h_correction1_test.dart` : S14·J6 ouverte le dimanche d'avant (S14·J1-J5 pas faites) → ordre et exercices écrits, pas de dead-hang, squat 70 kg × 14 sur 3 séries ; même séance le samedi avec J4/J5 réellement manquées → test reporté par le moteur (comportement inchangé le jour même) ; prévision = séance ouverte juste après (même jour, 6 exercices) ; cause des répétitions (tableau ci-dessus) ; lignes PdC à charge fixe aux répétitions et séries écrites après des séances dures (S14·J4) ; règle pure (douleur, bilan bas, sommeil, reprise, douleur d'ajustement, endurance « douleur de jambe » baissent ; sinon volume écrit) ; 8 jours sans séance → volume écrit tenu ; bilan bas → charge 70 | vert |
| `test/ci1h_charge_fixe_test.dart` (adapté : volume écrit ; séance future au jour réel) — contrôle global S1-S40 : 673 prescriptions de lignes verrouillées, 0 série hors charge écrite ; prévision = séance ouverte sur 3 séances | vert |
| Suites CI1b à CI1g, G9, G2, mode dev G2/G3 | vertes (run rapide 38116015121) |
| Contrôle complet `claude/ci-3d` | vert (run 38116693282, 830 tests) |
| Build signé APK + AAB | **échec hors lot** (run 38118843803, 2 essais : `m8_carte_2d_test.dart` bloqué ; même échec sur UI5) |
| Installation par-dessus dev6.11.2 | aucune donnée nouvelle dans la sauvegarde ; une séance pas commencée ouverte sous 6.11.2 est represcrite au jour réel à la réouverture |

Relecture indépendante (sous-agent Opus) : 5 constats, traités — exception « reprise » au niveau séance trop large (retirée : par exercice seulement), conduite d'endurance et douleur posée sur un ajustement reconnues, cibles par série et technique des séries rétablies, un seul « une série de moins » retiré par ligne. Défaut A jugé correct (aucun chemin restant sur la date prévue).

## 5. À tester sur le téléphone du propriétaire

1. Ouvrir **S14·J6 en avance** (avant samedi) : exercices dans l'ordre écrit (pas de dead-hang en tête), squat endurance **70 kg × 14** sur chaque série.
2. Fin d'une séance : « La prochaine fois » = ce que montre la séance visée ouverte juste après.
3. Le samedi : séance recalculée ; si une séance de la semaine a vraiment été manquée, son test peut revenir en tête (voulu).

## 6. Limites

- Cause des 11 répétitions établie sur un journal synthétique (mécanisme reproduit : 13) ; le journal réel n'est pas dans la session.
- Séance future **commencée** en avance : gardée telle quelle (séries validées), le reste suit la represcription de CI1c.
- KM3 conserve ce comportement (prompt KM3, C15.11).

## 7. Recommandation (C8, le pilotage décide)

- Le code est sur `main` (e351f274) et le contrôle complet est vert ; **seul le build signé manque**, bloqué par `test/m8_carte_2d_test.dart` (« étiquettes » : `loadMapLabels` → `ui.instantiateImageCodec` dans `tester.runAsync` ne rend plus la main ; les deux tests suivants du fichier héritent du blocage). Le même arbre passe ces tests dans le contrôle complet, et la branche de UI5 échoue de la même façon : problème du job de build (exécuteurs, moteur de test), pas de ce lot.
- Recommandation : relancer le build de main (run 38118843803, « Re-run failed jobs ») quand les exécuteurs se rétablissent ; s'il échoue encore, une passe courte qui rend ce test robuste (par exemple étiquettes chargées une fois en `setUpAll` hors widget, ou délai borné) — hors de ce lot, aucun test n'a été sauté ni désactivé. Puis valider dev6.11.3 à la place de dev6.11.2.
- Gel C16 : rien n'a été lancé.
