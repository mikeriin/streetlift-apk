# Livraison KB4 — Koach 1.0.7 dans l'application (dev7.4.0)

Pipeline « Calibrage des programmes », voie App (tâche « Opus 5.5, effort élevé, application »). Lancé par le pilotage le 21/10/2026 vers 02:40 UTC (DECISIONS_CP.md C17.42) ; la session de 04:20 UTC sans ligne « Lot : » s'est arrêtée (RV1 marqué « en attente de KB4 ») ; relancé avec « Lot : KB4 » à 04:22 UTC. Statut trouvé : « en cours (lancé …) » sans session ni sauvegarde ; traité comme le lancement (pas de `cp-sauvegardes/KB4` existante). Délégation (C8) : validation par le pilotage.

**Ce lot n'a rien déchiffré, n'a pas lu `cp-references`, n'a reçu aucune clé et n'a manipulé aucune donnée du propriétaire (C17.33.2).** Tous les tests tournent sur des données synthétiques (semaine type `test/fixtures/pr9_semaine.json`, programme embarqué pour l'historique).

- **Base** : `main` 88fb1965 (dev7.3.0) ; aucune publication du propriétaire pendant le lot.
- **Livré** : dev7.4.0 (7.4.0+148) sur `main` 0e063fde ; **build signé run 39593261404 vert** (https://github.com/mikeriin/streetlift-apk/actions/runs/39593261404 ; APK : artefact `kalis-track-apk` 12343941984, https://github.com/mikeriin/streetlift-apk/actions/runs/39593261404/artifacts/12343941984 ; AAB 12343237771).
- **Contrôle complet `claude/ci-3d`** : trois runs, `lib/` identique dans les trois ; **contrôles, analyse, formatage, 1 168 tests Dart, mode dev, builds debug et profile verts** sur l'arbre publié (run 39575555962, commit de contrôle e4a497d7 = arbre de `main` 0e063fde). Émulateur : toutes les cibles vertes sur l'arbre publié (KB4, KB3, KB2c1, KB2, KB1, KS1A, KM3, BV11, CIF, CI1g, CI1f, CI1, CU, G10 … M7) sauf CI1c b et CI1e b, **jamais lancées** (« Connection refused » au service de la VM, deux essais chacun : panne de l'émulateur, aucune ligne de test exécutée) ; ces deux cibles sont vertes, sur le même `lib/`, aux runs 39561707144 (CI1c a et b) et 39547568156 (CI1e a et b). Run 1 (39547568156) : instantané 2.x de G10 à mettre à jour (EMOM minute par minute, seul changement voulu) ; run 2 (39561707144) : assertion de l'en-tête EMOM de la cible KB4 (espaces insécables) ; corrigés.
- Contrôle rapide `claude/ci-ui-kb4-rapide` : run 39547004881 vert (formatage, analyse, 16 tests KB4), verrou régénéré par l'outil puis respecté.
- Sous-agent : une relecture indépendante (Opus) du diff de `lib/` (§ 6).

## 1. Ce qui change pour le propriétaire

- **Koach ne coupe plus ton programme pour le volume.** Chaque exercice et chaque série écrits sont servis ; Koach ne borne que ce qu'il **ajoute** au-dessus de l'écrit (« Je garde les 8 séries écrites de ton programme sur …, sans en ajouter : … »). Plus de « Je retire … aujourd’hui » pour le volume.
- Les retraits restent possibles, dits, pour : douleur signalée (conduite sous douleur), cardio au bilan bas, test reporté, séance bornée au temps que tu donnes, tenues bras tendus (rampe des tendons).
- **Réactivation** : au premier lancement de dev7.4.0 avec Koach arrêté, une carte de l'accueil « Koach ne coupe plus ton programme » propose **Réactiver Koach** (ou « Plus tard » ; la réactivation reste dans Réglages). Jamais de réactivation automatique.
- **EMOM « N min × R reps par minute »** (muscle-ups et tractions PdC du J4, dips PdC du J5) : **une ligne par minute** (8 × 3, 10 × 8, 12 × 18), en-tête « EMOM · 8 tours · 8 min » avec le bouton Lancer, comme les E2MOM du lundi ; Koach actif comme arrêté. Une minute ratée : laisse sa ligne non validée (ou note les reps faites). Une séance ouverte avant la mise à jour sans rien de noté passe d'elle-même à une ligne par minute.

## 2. Paquet et empreinte

- `packages/kalis_adapt/lib/`, `assets/koach/` et `pubspec.yaml` copiés à l'octet depuis `etiquettes/kalis_adapt-v1.0.6` (`moteurs` 737d528d) : 55 fichiers, empreinte `cebaa39f3c2358ed4b043c7afe45e4f4885ddaa1e72f52ed5c230a32eb314d42` (KB3 : `447ffbeb…`). Rien d'autre dans `packages/`.
- Asset `assets/koach/koach_params_1_0_7.json` à la place de `koach_params_1_0_6.json` : `1.0.7-ref.1`, 344 clés, SHA-256 `2f055c5181743089afd0c3602bc270f77b01063ebc1bab32b293c81c6816f42c` (application et paquet) ; déclaration, `kKoachParamsAsset`, tests d'empreinte (`kb1_koach105_test`, `km3_koach_test`, `kb4_koach107_test`).
- `pubspec.lock` régénéré par l'outil (CI, `flutter pub get`), puis `--enforce-lockfile` respecté.
- Contrat (§ 7 de LIVRAISON_KM5) : l'application passe à `plan('seance')` les items **écrits** du jour ; la modulation de la semaine est appliquée par le moteur lui-même (`itemsDuJour` → `Planification.appliquer`, qui pose `koachVolume`) : aucune transformation de `sets` avant Koach. `manquees` et `reste_semaine` : items écrits du programme. Un seul `prescrire` par séance (état `open`, jamais recommencé ; KB4 : une séance faite ou déjà versée n'est jamais commencée par Koach) ; prévisions sur une copie du moteur (inchangé).

## 3. Garde de la séance, tous les rôles

`koachGardeSeance(ecrit, servi, raisons, {budgetDonne})` (paramètre `roles` retiré) :
- une ligne écrite absente du servi est servie **telle qu'écrite** (ligne de l'aperçu, ou, si l'aperçu ne l'a pas, la ligne écrite du jour avec la charge fixe C15), raison affichée, diagnostic `garde` (inspecteur du mode dev) ; avec 1.0.7, cela n'arrive plus pour le volume (0 sur le scénario) ;
- retraits motivés : `koach.douleur_retrait`, `koach.endurance_retrait`, `koach.test_reporte` (ligne de test), `koach.seance_bornee` (temps donné par l'athlète), `koach.retour_gradue` d'un groupe `bras_tendus_*` à 0 série (rampe tendineuse) ;
- le retrait d'un accessoire par `koach.retour_gradue` (KB3) est retiré ; la ligne retirée « `koach.planification` » (modulation à 0) aussi : l'aperçu et la semaine affichée ne retirent plus jamais une ligne écrite.
- Lignes au départ chronométré (PR8) : séries écrites dans l'aperçu et la semaine affichée (plus de modulation qui casserait les tours du groupe) ; « Koach aurait fait N séries sur M … » seulement si les séries servies diffèrent encore de l'écrit (`koachTexteEcartEcrit`) — jamais vu sur le scénario.
- Textes : `koach_textes.dart` 1.0.7 (`koach.ajout_borne`), ordre des raisons de KB3 gardé.

## 4. Réactivation après l'arrêt d'urgence

- `koachResume` : rejeu du journal gardé, puis :
  - une séance que Koach servait à l'arrêt (début au journal) et finie pendant l'arrêt est **fermée une fois** (séries restantes, `seance_fin`) avant le rattrapage (`_koachCloseOrphans`, seulement si son `seance_debut` est le dernier début ouvert du journal, au même jour) ; le rattrapage ne la verse jamais une seconde fois ;
  - séances faites pendant l'arrêt (telles qu'écrites) **versées dans l'ordre** (observations, sans `plan`), semaines fermées ensuite ; séances jamais réécrites (séries notées identiques, testé) ;
  - aperçu d'avant l'arrêt d'une séance commencée ou faite pendant l'arrêt : état `ecrite` (`refus: arret`), bilan et lieu gardés, jamais commencée par Koach ;
  - séance servie pas finie : reprend ses séries servies, séries notées gardées ;
  - Koach reprend à la première séance non faite, planification du moteur rejouée (modulation figée à l'arrêt abandonnée).
- Carte de l'accueil `KoachRepriseCard` (champ `annonce107` de la section `koachEngine`, additif) : montrée seulement si l'arrêt date d'avant dev7.4.0 ; « Plus tard » la cache ; un arrêt décidé avec dev7.4.0 ne la montre pas.
- Défaut corrigé au passage : avant KB4, une séance servie par Koach finie alors que le moteur n'était pas prêt pouvait être versée une seconde fois au rattrapage (deux `seance_debut`).

## 5. Lignes EMOM « volume » (constat du 20/10, S1·J4)

- Cause : « EMOM 8 min × 3 reps par minute » était noté en une ligne du total (`setCount` 1, `plannedReps` 8 × 3 = 24) sur la séance écrite (Koach arrêté).
- Correction (`emomPerMinute`) : une ligne par minute (`setCount` = minutes), `LogSpec('reps', every: 60)` — même saisie que « 12×6 · EMOM » (PR1) : en-tête du départ chronométré, chrono, tours comptés sur les séries validées ; reps par minute = arrondi de coefficient × référence ÷ minutes, comme l'écrit (B16 10 → 3, B17 30 → 8, B18 70 → 18 testés). Import : ligne servie telle qu'écrite (règle PR8, départ chronométré à reps fixes) : Koach actif comme arrêté, même carte ; journal du moteur : même lecture qu'avant (agrégat). EMOM montant (« +1 rep/min jusqu'à l'échec ») inchangé.
- Autres formes vérifiées (test) : « 6×30 s » (6 tenues), « 3×10/jambe » (3 × 10), « 2×15/bras » (2 × 15), « 2 tours × 4 paliers » (8 paliers), « 8×3 · E2MOM » : déjà une ligne par série. « 8× (30 s effort / 30 s repos) » : une ligne d'intervalles avec le chrono des tours (pas de reps par tour à noter) : gardé ; recommandation au § 8.
- `CLAUDE.md` (protocoles) mis à jour.

## 6. Tests et relevé

- `test/kb4_koach107_test.dart`, 16 tests : paquet et textes ; garde pure (tous rôles, retraits motivés, ordre) ; texte de la ligne PR8 ; EMOM (formes, références) ; scénario ; douleur ; réactivation ; carte ; passage depuis dev7.3.0 ; EMOM du programme Koach actif et arrêté ; écran de séance (widget) ; séance ouverte avant dev7.4.0.
- **Scénario C17.40** (PR2 synthétique, six séances par semaine en PPL, départ affiché S15, **trois semaines d'historique** S12 à S14) — relevé du test :
  - rampe à l'ouverture de J1 : écrit de la semaine / limite = chest 66,5 / 55,8, delt_anterior 47,5 / 39,6, triceps 60,5 / 51,6 (limite = historique × 1,2 : le programme écrit ≈ +43 %, +44 %, +41 % au-dessus de l'historique) ;
  - **J1** servi à toutes ses séries écrites : muscle-up lesté 6, traction lestée 8, pompes 8, rowing 3, poignets 3, face pull 3, curl marteau 3 ; aucune raison, aucun retrait, aucune garde ;
  - **J2** (poussée) servi à toutes ses séries écrites : dip lesté E2MOM 8 × 3, tractions PdC dans la pause 8, pompes lestées 4, développé militaire 3, rotations externes 2 (/bras), extension triceps 3, élévations latérales 3 ; aucune raison, aucun retrait ; temps `plan(seance)` 36-58 ms (test Dart, VM de la CI) ;
  - douleur à l'épaule le mardi : six lignes retirées par `koach.douleur_retrait` (dip, tractions PdC, pompes lestées, développé, rotations, élévations), extension triceps servie à 3 ;
  - réactivation (J1 servie et commencée, arrêt, J1 finie puis J2 et J3 faites pendant l'arrêt, réactivation le jeudi) : J1 fermée une fois, J2 et J3 versées dans l'ordre (jours 98, 99, 99, 100, 100), autant de `seance_debut` que de `seance_fin`, séries notées identiques, J4 servie par Koach.
- Passage depuis dev7.3.0 : Koach actif (prise de main 1.0.6 gardée, moteur 1.0.7) puis Koach arrêté avec une séance commencée : `logs`, `programInstance`, `programOrigin` identiques ; sauvegarde exportée puis réimportée à l'identique (toutes les sections) ; série notée gardée après réactivation.
- Tests d'avant mis à jour : KB3 (tests propres à 1.0.6 remplacés), KB1 (empreinte, asset), versions (G2, G3, KS1A, KM3, CI1d/f/g, Python).
- Cible émulateur `integration_test/koach_kb4_test.dart` (inscrite dans `tools/ci3d_drive.sh`, parties a sombre/rouge et b clair/violet) : J1 servie et faite, J2 servie (captures de chaque page de la séance de poussée), arrêt, J4 écrite avec l'EMOM minute par minute (capture), carte de reprise (capture), réactivation. Cible KB3 mise à jour (pull-over gardé). Relevé émulateur (deux thèmes, run 39575555962) : J1 servie et faite sans retrait ; J2 servie, 5 pages, structure identique à l'écrit, aucune raison en tête ; J4 arrêtée : 8 lignes de 3, en-tête « EMOM · 8 min » + Lancer ; carte de reprise affichée, réactivation, carte disparue, J3 en aperçu de Koach ; débuts = fins + la séance J2 ouverte. Captures `kb4_1_poussee_page1..5`, `kb4_2_emom_minute_par_minute`, `kb4_3_carte_reprise`, `kb4_4_accueil_reactive` (`ci-out/emulateur/` de `claude/ci-3d`, commit 5844d7c6).

## 7. Relecture indépendante

Sous-agent Opus (diff de `lib/`) : aucune erreur de compilation ; traités : formatage ; séance faite jamais commencée par Koach (`koachStartNow`) ; bilan gardé à la reprise (état `ecrite` au lieu d'effacer l'aperçu) ; séance `open` fermée seulement si son début est le dernier début ouvert du journal (sinon versée hors de Koach) ; ligne PR8 absente de l'aperçu reprise de l'écrit ; semaine affichée sans « 0 série » ; EMOM « + » limité à « +N rep » ; journal d'une ancienne ligne EMOM d'un total lue en agrégat. Gardés (mineurs, dits) : course entre un arrêt et un rafraîchissement en cours (préexistante) ; une séance servie finie pendant l'arrêt verse ses séries d'après le plan servi.

## 8. Limites et recommandations au pilotage

1. Valider dev7.4.0 ; RV1 peut suivre (C17.41).
2. Intervalles « 8× (30 s effort / 30 s repos) » : une ligne sur la séance écrite, une ligne par tour quand Koach sert (groupe d'intervalles) : à aligner dans RV1 si le propriétaire le souhaite (pas le même piège : pas de total de reps).
3. Une minute d'EMOM ratée se note en laissant sa ligne non validée (0 rep refusé, comme les E2MOM) ; un bouton « minute ratée » serait un ajout d'écran (non fait : pas de refonte).
4. Modulation hebdomadaire de la planification (±15 %, au moins une série par ligne, inchangée en 1.0.7) : elle peut encore baisser une ligne sous l'écrit pour la fatigue ; aucune baisse vue sur le scénario.
5. Lot KS des crédits de groupes : toujours recommandé (C17.39.4).
6. Constat pour RV1 (capture de la page 5 de J2, données synthétiques) : charge de l'extension triceps poulie servie à « 20,41 kg » (pas de la grille de la poulie non appliqué ?), comportement d'avant KB4, non touché ici.

## 9. À tester (propriétaire)

- Installer dev7.4.0 ; sur l'accueil, « Réactiver Koach ».
- Séance du jour : toutes les lignes du programme, à leurs séries écrites.
- J4 / J5 : EMOM minute par minute, bouton Lancer.
- Noter les flammes au plus juste.
