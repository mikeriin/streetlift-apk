# Livraison KB3 — Koach 1.0.6 dans l'application (dev7.3.0)

Pipeline « Calibrage des programmes », voie App (tâche « Opus 5.5, effort élevé, application »), lancé par le pilotage le 20/10/2026 vers 09:50 UTC (DECISIONS_CP.md C17.39). Délégation (C8) : validation par le pilotage.

**Ce lot n'a rien déchiffré, n'a pas lu `cp-references`, n'a reçu aucune clé et n'a manipulé aucune donnée du propriétaire (C17.33.2).** Tous les tests tournent sur des données synthétiques (semaine type `test/fixtures/pr9_semaine.json`, programme embarqué pour S1 à S14).

- **Base** : `main` c173e77c (dev7.2.6). Le propriétaire a publié dev7.2.5 (214c3549) puis dev7.2.6 (c173e77c) pendant le lot : rebasé deux fois, conflits de version et de `SUIVI_PROJET.md` seulement, rien défait de ses correctifs dev7.2.3 à dev7.2.6.
- **Livré** : dev7.3.0 (7.3.0+147) sur `main` 88fb1965 (828f5154 KB3, puis 88fb1965 : `pubspec.lock` régénéré par l'outil, le premier build signé 39448301212 ayant refusé l'ancien verrou en `--enforce-lockfile`) ; **build signé run 39450035889 vert** (https://github.com/mikeriin/streetlift-apk/actions/runs/39450035889 ; APK : artefact `kalis-track-apk` 12279626158, https://github.com/mikeriin/streetlift-apk/actions/runs/39450035889/artifacts/12279626158 ; AAB 12279097660).
- **Contrôle complet `claude/ci-3d`** : run 39410993295 **vert** sur 674b0b34 (KB3 sur dev7.2.5 ; émulateur : 1er essai annulé à 140 min par des pannes de la VM, « device offline » avant tout test, 2e essai vert, `drive-code.txt` tous à 0) ; run 39445690594 sur 828f5154 (KB3 sur dev7.2.6) : contrôles, tous les tests Dart, mode dev, build debug et profile **verts** ; émulateur en cours à la livraison. Le verrou (`pubspec.lock`) est régénéré à l'identique par la CI dans les deux runs.
- Sous-agent : une relecture indépendante (Opus) du diff de `lib/` et du test (§ 6).

## 1. Paquet et empreinte

- `packages/kalis_adapt/lib/`, `assets/koach/` et `pubspec.yaml` copiés à l'octet depuis `etiquettes/kalis_adapt-v1.0.5` (`moteurs` 91d8ea70, C17.19.3) : 55 fichiers, empreinte `447ffbeb9911d5fd3e8879501dc5a3725efaa3da36ff6ce81851f78fa5ccbe7b` (test `kb1_koach105_test.dart`, mis à jour ; KB1 : `06c8f971…`).
- Asset `assets/koach/koach_params_1_0_6.json` à la place de `koach_params_1_0_5.json` : version `1.0.6-ref.1`, 347 clés, SHA-256 `4156e61b674be1e983d22dba21067cb47cc16d25429b60588957549b9464045a` ; déclaration du `pubspec.yaml` de l'application, `kKoachParamsAsset`, tests d'empreinte (`km3_koach_test`, `kb1_koach105_test`, `kb3_koach106_test`).
- `kalis_plan` 0.4.2 et `kalis_core` 0.4.4 inchangés ; aucun autre changement de `packages/`.

## 2. Rôles (`reste_semaine`, séances manquées)

- `koachItemVolume(item, roles)` ajoute le champ additif `role` (rôle de l'emplacement, `roles` du plan de séance : `main`, `secondary`, `accessory`, `skill`…) ; omis si l'emplacement n'a pas de rôle connu.
- Appelé pour chaque item de `contexte['reste_semaine']` et des séances manquées (`manquees`, rattrapage du lundi), programme importé comme programme créé (`koachJourInfo(...).roles`).
- Tests : PR2 synthétique (J2 à J6 dans `reste_semaine`, chaque item avec `role`, dip lesté `main`, pompes lestées non principal) ; séances manquées (S15 sans séance faite, lundi suivant) ; programme créé par `kalis_plan` (rôles présents, au moins un `main`).
- Les séances manquées déjà enregistrées par dev7.2.4 (sans `role`) restent telles quelles : Koach 1.0.6 ne lit pas le rôle des séances manquées pour couper (il les compte à leur écrit).

## 3. Garde des principaux

`koachGardeSeance(ecrit, servi, raisons, {budgetDonne, roles})` :

- **Principal** (rôle `main`, ou rôle inconnu par prudence) absent du servi sans retrait motivé : servi **tel qu'écrit** (filet de KB2 correction 1), « Servi tel qu’écrit… » sur la carte. Avec 1.0.6, cela ne devrait plus arriver sans douleur (0 sur 90 600 saisons, KM4) ; reste possible pour une figure par la rampe tendineuse (M1 de KM4).
- **Accessoire, secondaire, technique** que le retour gradué met à 0 (raison `koach.retour_gradue`, `series` 0, `ecrites` égal aux séries écrites de la ligne quand Koach les dit) : **retiré**, entrée `retraits` (code `koach.retour_gradue`), raison en tête de séance (« Je retire « Pull-over… » aujourd’hui : pour tes pectoraux, le volume que la semaine permet est déjà pris (au plus 55,8 séries cette semaine). »).
- Un principal mis à 0 **sous douleur** (`douleur` de la raison 1.0.6) est retiré (C17.37.2).
- Une autre raison (surmenage, tendon, séance bornée sans temps donné…) ne retire jamais une ligne : absente du servi sans retour gradué à 0, elle est servie telle qu'écrite (jamais de retrait en silence). Le choix ne dépend pas de l'ordre des raisons.
- Retraits motivés de KB2 correction 1 inchangés (douleur, endurance, test reporté, séance bornée au temps donné).

**Constat et correction en cours de lot (séance servie qui retombait sur l'aperçu).** Muscle-up lesté et traction lestée sont des lignes au départ chronométré (E2MOM) servies **telles qu'écrites** depuis PR8 (`adaptAsWritten`, nombre de séries fixé par le programme). Avec 1.0.6, Koach les sert réduites (3 sur 6, 4 sur 8) : la séance servie devenait invalide (« 3 séries, 6 attendues (intervalles) » : un groupe E2MOM de 6 tours ne peut pas porter 3 séries) et l'application retombait **en silence sur toute la séance écrite** — accessoires coupés et réductions de Koach compris. Correction :
- une ligne PR8 entre dans la séance servie par sa ligne de l'aperçu (séries et charge du programme, comme à l'écran) ; la réduction de Koach est **dite sur sa carte** : « Servi tel qu’écrit (départ chronométré du programme). Koach aurait fait 3 séries sur 6 pour rester dans le volume de la semaine : écoute tes sensations. » ; elle n'est pas répétée en tête de séance ;
- un groupe dont tous les membres sont retirés n'est plus déclaré ;
- diagnostic `invalide` (mode dev, état de la séance) si une séance servie reste illisible.

**Décision à confirmer par le pilotage** : C17.39 demandait « muscle-up lesté et traction lestée (séries réduites au plus) ». J'ai gardé la règle PR8 du propriétaire (séries du programme sur les lignes au départ chronométré : « rien défaire des lots du propriétaire ») ; la réduction est dite, pas appliquée. Si le pilotage veut que Koach réduise aussi ces lignes, c'est un changement de PR8 (nombre de tours du groupe recalculé), à décider à part.

## 4. Raisons

- Textes de `koach_textes.dart` 1.0.6 : `ecrites` (« 3 séries au lieu de 6 sur … »), retrait du jour (« Je retire … aujourd’hui »), `douleur`.
- `koachTrierRaisons` : ordre des codes du contrat (`koachCodesRaisons`, douleur d'abord), tri stable ; carte et en-tête n'utilisent plus l'ordre du moteur.
- `ouverture` : raisons de l'ouverture gardées dans l'état de la séance ; `plan(serie)` remplace `raisons`, mais retraits, séries réduites et séance bornée restent dits (en-tête = raisons ∪ ouverture, carte : raison de structure de l'ouverture à défaut). Un état d'avant sans `ouverture` retombe sur `raisons`.

## 5. Tests

- `test/kb3_koach106_test.dart`, 13 tests : paquet et textes ; rôle des items ; garde pure (principal sans / sous douleur, accessoire, secondaire, technique, rôle inconnu, deux raisons dans les deux ordres, séance bornée sans temps donné, sans rôles) ; ordre des raisons ; scénario PR2 ; raisons gardées après `plan(serie)` ; séances manquées ; passage depuis dev7.2.4 ; programme créé.
- **Scénario C17.37 (PR2 synthétique, six séances par semaine en PPL, départ affiché S15, pull-over « chest » ajouté au lundi de tirage)**, relevé du test :
  - Koach sert muscle-up lesté **3 sur 6**, traction lestée **4 sur 8** (plancher), pompes 8, poignets 3, face pull 1 sur 3, curl marteau 2 sur 3 ;
  - **pull-over retiré d'abord** (pectoraux, limite 55,8) et **rowing retiré** (dorsaux, limite 47,4), raisons en tête ; aucun principal retiré ;
  - cartes : MUSCLE-UP LESTÉ 6×2 · E2MOM et TRACTION LESTÉE 8×3 · E2MOM (PR8, réduction dite sur la carte), pompes 8×11 · E2MOM, poignets 3 × 13-19, face pull 1 × 13-19, curl marteau 2 × 8-14 ;
  - temps : `plan(seance)` 22 ms, début de séance 110-136 ms, prise de main 2,9-3,0 s (VM de la CI, test Dart).
- Données : passage depuis dev7.2.4 (instantané de prise de main 1.0.5, J1 faite) : prise de main gardée (S15, version 1.0.5 de l'instantané, pas de nouvelle prise de main), moteur 1.0.6 en service, journal de 1.0.5 gardé événement par événement, `logs`, `programInstance`, `programOrigin` (C11.2) identiques, séance faite intacte ; J2 servie par 1.0.6. Rejeu d'un journal d'une version d'avant par 1.0.6 : `kb1_koach105_test` (versions à jour).
- KB2 correction 1 mis à jour : S1·J1 du programme PR2 (sans pull-over) — ordre écrit, muscle-up en tête, seuls manquent les accessoires que Koach retire en le disant ; série notée de l'arrêt d'urgence sur les poignets (le rowing peut être retiré).
- Cible émulateur `integration_test/koach_kb3_test.dart` (inscrite dans `tools/ci3d_drive.sh`, parties a sombre/rouge et b clair/violet) : même scénario, relevé `kb3_releve_<partie>.json`, captures `kb3_1_seance_j1`, `kb3_2_carte_reduite` ; **verte** dans les deux thèmes (run 39410993295) : relevé identique au test Dart (servis, retraits, cartes, raisons ; `reste_semaine` : 5 séances, rôles partout ; `plan(seance)` 29 ms, début de séance 55 ms, prise de main 3,8 s sur l'émulateur).
- Toutes les cibles d'avant (KB2c1, KB2, KB1, KS1A, KM3, BV11, CIF, CI1g…G1, M8, M7) : vertes (run 39410993295, `drive-code.txt` tous à 0).
- Tests Dart (tous), mode dev, Python, paquets, rendus : verts (run 39410993295).

## 6. Relecture indépendante

Sous-agent Opus (diff de `lib/` et du test) : 0 bloquant. Traités : retrait d'un non-principal dépendant de l'ordre des raisons (désormais seulement par le retour gradué à 0 de la ligne) ; raison d'une ligne PR8 liée à la ligne (séries écrites) et non à l'exercice ; en-tête gardé après `plan(serie)` pour les raisons qui ne sont pas des retraits ; séance bornée sans temps donné (accessoire servi tel qu'écrit, comme avant, testé) ; principal sous douleur ; tests sans condition, rôle `skill`, deux ordres. Gardé : raisons rattachées à l'exercice quand Koach ne donne pas `ecrites` (même exercice sur deux lignes, rare).

## 7. Limites

1. **Séries d'une ligne servie telle qu'écrite (garde, C17.39.5)** : versées au moteur comme aujourd'hui (observations) ; `fermer` ne compte au volume réalisé que les items servis par Koach. Devient marginal : un principal n'est plus à 0 sans douleur.
2. **Lignes PR8** : Koach les planifie réduites (3 sur 6) ; l'athlète fait les 6 tours écrits ; les séries faites sont versées au moteur et comptées au réalisé (item servi) : la rampe de la semaine suivante part de ce réalisé. Voir la décision du § 3.
3. Accessoires coupés par la rampe : avec un programme plus volumineux que les semaines d'avant, plusieurs accessoires peuvent être retirés ou réduits les premières semaines (scénario : pull-over et rowing retirés, face pull à 1 série) ; c'est le comportement voulu de 1.0.6 (accessoires d'abord), dit en tête de séance.
4. Crédits de groupes (tractions créditées « chest » 0,5, muscle-up 1,0) inchangés (C17.39.4) : ils pèsent sur la limite « pectoraux » d'un lundi de tirage.

## 8. Recommandation au pilotage

Valider dev7.3.0. Trancher le § 3 (réduction de Koach sur les lignes au départ chronométré : dite seulement, ou appliquée en changeant PR8). Lot `kalis_plan` des crédits de groupes (C17.39.4) toujours recommandé.

## 9. À tester (propriétaire)

- Installer dev7.3.0. Prochaine séance de tirage : muscle-up lesté et traction lestée présents, en tête, aux tours du programme.
- Lire les raisons : en tête de séance (« Je retire … aujourd’hui » pour un accessoire coupé), sur la carte (« Koach aurait fait 3 séries sur 6 … »).
- Noter les flammes au plus juste : c'est ce qui règle la rampe des semaines suivantes.
