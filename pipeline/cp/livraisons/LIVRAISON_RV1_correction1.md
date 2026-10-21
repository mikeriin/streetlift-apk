# Livraison RV1 — correction 1 (RV1c1) : chronos des groupes au chrono, dev7.5.1

Lot de la voie App du pipeline CP (DECISIONS_CP.md C17.45, prompt `prompts/RV1c1.txt`), lancé le 21/10/2026 vers 20:10 UTC en parallèle de la fin de RV1. Opus 5.5, effort élevé. Aucune donnée réelle, aucun déchiffrement, aucune clé (C17.33.2).

## 1. Ce qui est livré

- **Version** : dev7.5.1 (7.5.1+150) sur `main` c6d6e41c (base dev7.5.0 c963a215) ; build signé run 39688534010 (https://github.com/mikeriin/streetlift-apk/actions/runs/39688534010) (APK artefact `kalis-track-apk` 12388925016 : https://github.com/mikeriin/streetlift-apk/actions/runs/39688534010/artifacts/12388925016).
- **Contrôle** : contrôle rapide `claude/ci-ui-rv1c1-rapide` run 39671097026 vert ; contrôle complet `claude/ci-3d` run 39675372342 **vert** sur l'arbre publié (a51bac95 = arbre de `main` c6d6e41c) : formatage, analyse, Python, tests Dart, mode dev, rendus, builds debug et profile, paquets ; émulateur : toutes les cibles des lots précédents code 0 et `rv1c1` a et b vertes. Run précédent 39672136872 rouge sur un jeton UI (`EdgeInsets.only(bottom: … : 0)` dans la barre) : corrigé avant publication. dev7.5.0 (`main` c963a215, commit de 21:19 UTC, publié par RV1) a un arbre identique à `claude/ci-3d` e0337102, base du lot : rebase sans changement de `lib/` au-delà de la correction, pas de nouveau contrôle nécessaire.
- **Paquets** : inchangés (aucun fichier de `packages/` touché).

## 2. Constats du propriétaire et correctifs

### (a) S1·J3, squat E3MOM 6 × 3 à 95 kg avec dead hang 30 s dans la pause

Cause : un seul minuteur (`TimerCtl`) pour toute la séance. Le sablier d'une ligne de tenue appelait `timer.single('TENUE', …)`, qui remplaçait le chrono des tours. RV1 avait retiré le repos automatique au milieu d'un groupe *du moteur* ; or la page « squat E3MOM + dead hang enchaîné » du programme importé n'est pas un groupe du moteur (`_group` null) : la validation de la ligne B (dernier membre) lançait **aussi** le repos par défaut (90 s), qui remplaçait le chrono des tours. Deux chemins, même effet que la capture (« Repos 1:43 »).

Solution retenue (la plus simple, sans refonte, jetons UI) : **chrono de tenue secondaire**.

- `TimerCtl.groupClock` : le chrono en cours est celui d'un groupe au chrono — `emom()` (EMOM, E2MOM, E3MOM, E90s, EMOM par minute, groupe EMOM du moteur), `startInterval()` (intervalles), AMRAP (`single(…, group: true)`), « pour le temps » / chipper (`stopwatch('CHRONO', group: true)`).
- Tant qu'il tourne (`groupRunning`) : `startRest` est sans effet (repos automatique après une série, bouton « Repos » d'un superset / circuit, quelle que soit la page) ; `add` (−15 s / +15 s) est sans effet et la barre du groupe s'affiche sans ces boutons (`_ClockBar` : libellé, temps, Arrêter) ; tenue (sablier), tenue au maximum (chrono montant), durée, mini-repos (cluster, mini-séries, bouton du coach) passent par `solo` / `soloStopwatch` et vont au **chrono secondaire** `side` (même horloge, sans décompte « Prêt »), affiché en une ligne compacte au-dessus de la barre du groupe (icône, « Tenue », temps, Arrêter puis Fermer ; bip à la fin). Un second appui sur le sablier arrête la tenue secondaire.
- Le chrono du groupe s'arrête seulement quand il est fini, arrêté par l'athlète (Arrêter), ou relancé (« Lancer » d'un groupe).
- Hors groupe au chrono : `solo` = l'ancien `single` (chrono principal, −15 s / +15 s), comportement inchangé.

Autres chemins vérifiés : changement de page de la séance (le minuteur vit avec l'écran, aucun appel) ; retour après mise en arrière-plan (phases déduites du temps écoulé, `ElapsedClock`, rien n'est relancé) ; notification du minuteur (il n'y en a pas : seuls les bips) ; page de fin (barre masquée, chrono continue, inchangé).

### (b) Finisher « Intervalles · 8 × 30 s, récupération 30 s », burpees remplacés

RV1 retire le sablier des tours d'intervalles écrits (`rowPrefix 'I'`). Vérifié par un sous-agent (lecture du code, chemins énumérés) : ce titre vient d'un groupe du moteur au format intervalles ; quand l'exercice est échangé (échange accepté sur le bloc importé, échange du jour du moteur, programme créé), la ligne devient « 8 × 30 s » en tenue **sans** `rowPrefix 'I'` : le sablier par tour revenait. Correctif : pas de sablier sur une ligne dont l'exercice est dans un groupe d'intervalles (`exerciseGroupOf(...).format == intervals`), en plus de `rowPrefix 'I'`. Le « Lancer » du groupe rythme effort et récupération ; valider un tour ne lance aucun repos.

## 3. Tests

- `test/rv1c1_chronos_test.dart` (8 tests) : contrôleur — E3MOM 6 × 180 s, tenue au tour 3 (secondaire, comptée, bip), repos / ±15 s / mini-repos sans effet, tour 4 à 9:00 ; tenue au maximum secondaire ; second appui ; intervalles, AMRAP, pour le temps protégés puis libérés à l'arrêt ; hors groupe inchangé. Écran (chrono injecté, horloge simulée) — page squat E3MOM + dead hang enchaîné : « Lancer l'E3MOM », barre sans ±15 s, tour 3, sablier de B·3 → « Tour 3/6 » intact + ligne « Tenue 0:30 », validation de B·1 avec repos auto à 90 s → chrono intact, tenue finie, « Tour 4/6 » à l'heure, Fermer la tenue garde la barre ; intervalles « Burpees » puis « Mountain climbers » : aucun sablier, Lancer → effort / récupération, validation sans repos ; planche hors groupe : sablier = chrono principal avec ±15 s.
- Versions : `test/g2_*`, `test/g3_mode_dev_test.dart`, `test/ks1a_types_test.dart`, `test/km3_koach_test.dart`, `test/kb1_koach105_test.dart`, `tools/tests/test_g2_retrait.py` à 7.5.1.
- `SessionScreen(timer:)` : chrono injectable pour les tests (l'écran ne libère pas un chrono donné).
- Cible émulateur `integration_test/rv1c1_chronos_test.dart`, inscrite dans `tools/ci3d_drive.sh` (parties a sombre / bordeaux / 90 %, b clair / neon / 110 %) : relevé `rv1c1_releve_<partie>.json`, captures :
  - `avant_e3mom_tenue` : ancien chemin (`single('TENUE')`) : la barre devient « Tenue 0:30 », le chrono des tours a disparu (reproduction du constat) ;
  - `apres_e3mom_tenue` : « Tour 3/6 » + ligne « Tenue » au-dessus ; `apres_e3mom_tenue_finie` ; `apres_e3mom_tour4` ;
  - `apres_intervalles` (« Repos 1/8 », aucun sablier) ; `apres_tenue_hors_groupe` (barre de repos ±15 s).
- Lues dans les deux thèmes : la ligne secondaire tient en une ligne à 90 % et 110 %, contrastes conformes aux jetons (`haute`, `filet`, `texte2`, `validation` pour « Terminé »). Captures dans `claude/ci-3d` dc04806, `ci-out/emulateur/rv1c1_*`. Relevés a et b identiques aux attendus (`avant` : barre « TENUE », groupe perdu ; `e3mom` : tour 3 intact après sablier et validation, tenue « TERMINÉ », tour 4 ; `intervalles` : 0 sablier, effort / récupération ; `horsGroupe` : chrono principal, ±15 s).

## 4. Limites et recommandations

- **Échange du moteur qui perd son groupe** (chemin relevé par la vérification) : si `kalis_adapt` sert un exercice de remplacement sans `groupId` dans un bloc d'intervalles hors programme importé (semaines d'un programme créé, ou après la dernière semaine importée), `exerciseGroupOf` ne trouve pas de groupe : lignes de tenue avec sablier, pas de « Lancer » des tours. Le sablier ne casse plus rien (pas de chrono de groupe), mais le format est perdu. Recommandation : lot moteur ou de colle — reprendre le groupe de l'emplacement du bloc quand l'item servi n'en a pas (`session_adapt_store.dart`, `exerciseGroupOf`). Non corrigé ici (hors périmètre de la correction, risque de régression des groupes).
- **Lignes d'un échange accepté (chemin B)** : nombre de lignes pris des séries de l'échange, tours du « Lancer » pris du groupe ; égaux sur le programme du propriétaire, à surveiller si une évolution change l'un sans l'autre.
- Un échange du jour par le moteur sur une ligne importée « telle qu'écrite » (intervalles) est ignoré (l'exercice d'origine reste) : règle PR8 / RV1, signalé seulement.
- Un chrono de groupe lancé puis oublié bloque le repos automatique des exercices suivants tant qu'il tourne : voulu (il ne se remplace jamais) ; l'athlète l'arrête d'un appui.

## 5. À tester (propriétaire)

1. S1·J3 : Lancer l'E3MOM du squat, au tour 3 appuyer le sablier du dead hang : la barre garde « Tour 3/6 », une ligne « Tenue » décompte au-dessus ; valider la ligne : pas de repos ; le tour 4 part à 9:00.
2. Finisher intervalles (exercice remplacé) : aucun sablier par tour ; Lancer rythme 30 s / 30 s.
3. Une planche hors groupe : sablier comme avant.

## 6. Recommandation au pilotage

Valider dev7.5.1 : correctif ciblé (chrono du groupe protégé dans le contrôleur, plus un affichage), aucun changement de moteur, du programme importé ni des données.
