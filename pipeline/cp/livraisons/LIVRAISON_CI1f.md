# Livraison CI1f — paquets 0.3.0, mini-séries, groupes, formats du programme de 40 semaines (dev6.11.0)

Lot CI1f du pipeline « Calibrage des programmes », voie App (tâche « Opus 5.5, effort élevé, application »), lancé le 09/10/2026 vers 09:08 UTC (DECISIONS_CP.md C11, C11.6 ; LANCEMENTS.md, section CI1f), en parallèle de CY. Validation : conversation de pilotage (C8.1).

- **Version** : dev6.11.0 (`pubspec.yaml` 6.11.0+113) : changement structurant (paquets 0.3.0, nouvelle saisie des séries, groupes).
- **Publication sur `main` : non faite.** Le push sur `main` a été refusé par le contrôle d'autorisations de cette session (motif affiché : « Modify Shared Resources »). Le commit prêt est 9dd09214 — « Kalis Track dev6.11.0 (CI1f) : paquets 0.3.0, mini-séries, groupes, formats du programme de 40 semaines » (parent : main 238078ee ; arbre 7e71bbbb, identique à celui du contrôle complet), sauvegardé sur `cp-sauvegardes/CI1f-candidat`. Décision requise : la publication sur `main` (et le build signé de `main`) par une session qui en a l'autorisation.
- **Build** : le push de `cp-sauvegardes/CI1f-candidat` a lancé le workflow de build (run 37937757916, même commit) ; ce n'est pas le build signé de `main`.
- **Contrôle complet** : `claude/ci-3d`, run 37934054639 (essai 5 ; commit 84a2edeb, arbre 7e71bbbb) (formatage, analyse, suite Dart complète, mode dev, Python, paquets, émulateur CI1f a et b, puis CI1e, CI1c et CI1 a et b).
- **Paquets** : `kalis_core` 0.4.3, `kalis_plan` 0.3.0, `kalis_adapt` 0.3.0 (branches fixes `etiquettes/…`, copie octet pour octet, vérifiée arbre par arbre) ; `kalis_koach` 0.1.0 inchangé ; `kalis_bench` jamais dans l'application. `pubspec.lock` (versions des paquets locaux) et `assets/catalog/parcours_v3.json` (0.4.3) à jour. Aucune étiquette de CY prise.
- Mise au point : `claude/ci-ci1f-rapide` (suite complète avec 0.3.0 : analyse verte) et `claude/ci-ci1f-rapide2` (essais 2 à 5).

## 1. Paquets 0.3.0 dans l'application

- **Autres disciplines** (musculation, force, course et cardio, CrossFit, mobilité, forme) : `kalis_plan` 0.3.0 les écrit par le chemin calibré (mode coach, saison) ; l'application les crée et les sert comme le street (test `ci1_street_test` mis à jour : la musculation passe au chemin calibré).
- **Conduite de l'endurance** (`kalis_adapt` 0.3.0) : sorties bornées, endurance facile un jour sans, reprise après une coupure, WOD mis à l'échelle, fatigue croisée. Pour qu'elle lise le journal, l'application note maintenant :
  - les **durées en minutes** (« 1 × 10 min ») et les convertit en secondes pour le moteur (la saisie est marquée à la validation : une durée notée en secondes avant 6.11.0 n'est jamais multipliée) ;
  - les **distances en mètres** (« 4 × 400 m » : colonne « M », journal `distanceMeters`) ;
  - les **intervalles au temps** d'un exercice en répétitions (burpees du HIIT) en secondes.
- **Textes de Koach** des cinq nouveaux codes de raison (`adapt.run_capped`, `adapt.easy_instead`, `adapt.endurance_shortened`, `adapt.wod_scaled`, `adapt.cross_fatigue`) et de leurs causes (bilan bas ou très bas, gêne aux jambes, course récente trop dure, deux jours durs de suite, reprise après une ou deux semaines) : aucun code brut (testé). Les nouvelles notes de coach de `kalis_plan` 0.3.0 sont rédigées par le paquet.

## 2. Mini-séries saisies une à une (CI1.11, CQ.5)

- Cluster, rest-pause et myo-reps : sous la série, Koach montre « Myo-reps : activation, puis mini-séries » (ou le cluster prévu) ; chaque mini-série s'ajoute avec sa valeur proposée (−/+), le mini-repos se lance tout seul, le total remplit la série (champ en lecture), « Retirer la dernière mini-série » corrige. Conseil affiché : mini-séries restantes (plafond du moteur, `miniSetsLeft`) et règle d'arrêt (« arrête dès qu'une mini-série n'atteint plus 4 »).
- Journal : **une** série (`reps` = total) avec ses `parts` (répétitions, repos pris avant) et sa technique ; `kalis_adapt` lit un myo-rep sur l'activation (première partie), un cluster sur chaque partie. Un myo-rep validé sans ses mini-séries garde sa technique (le moteur ne lit pas son total comme une série d'une traite). Résumé de la série : « 62,5 kg × 26 reps (15+4+4+3) ».
- **Myo-reps notés avant 6.11.0 en 5 lignes** (Act, M1…M4) : regroupés à la lecture en une série avec ses parties quand c'est sûr (lignes validées d'affilée depuis l'activation, même charge, aucune écartée) ; sinon gardés, marqués myo-reps pour que le moteur ne les lise pas comme des séries d'une traite. Journal jamais réécrit (testé).
- `kalis_adapt` 0.3.0 sert une ligne chargée sans part du 1RM (les lignes en RIR du programme importé) par sa règle générale, qui perd la technique sans la retirer pour une raison dite : la séance garde alors la technique écrite par le bloc (même nombre de lignes, niveau du profil suffisant : myo-reps et clusters à partir du niveau avancé, matrice R2-P22). Une technique retirée par le moteur (niveau, douleur, bilan, phase) ne revient pas. **Pour CY** : garder la technique en règle générale aussi.

## 3. Groupes d'exercices enchaînés (`GroupSpec`)

- Les exercices d'un même groupe (EMOM, circuit, superset, AMRAP, tours pour le temps, chipper, intervalles) sont sur **une page** de la séance (et de l'historique), sous une carte « Enchaînement » : format et paramètres (« EMOM 12 min », « Circuit · 3 tours · 3 min entre deux tours », « Intervalles · 8 × 30 s, récupération 30 s »), ordre des exercices, consigne, **chrono du groupe** (EMOM, AMRAP, intervalles, chrono montant, récupération entre deux tours).
- **Résultat du groupe** : tours faits (sur N), répétitions du tour entamé (AMRAP), temps (tours pour le temps, chipper) ; enregistré avec la séance (`SessionLog.groups`) et donné au moteur (`SessionRecord.groupResults`).

## 4. Programme de 40 semaines : formats annotés (C11.6)

| Format | Lignes | Annotation | Servi |
| --- | --- | --- | --- |
| Myo-reps « 1×15 puis 4×(4) » | 154 | technique `myo_reps` (activation = plage de la ligne, 4 mini-séries de 4, 10 s) | mini-séries une à une |
| Durées « 10 min », « 30-45 min » (mobilité, marche ou vélo léger) | 76 | secondes, conduite de l'endurance | en minutes, chrono |
| HIIT « 8× (30 s effort / 30 s repos) » | 28 | groupe `intervals` (8 × 30 s, récupération 30 s), burpees au temps | chrono d'intervalles du groupe |
| EMOM « EMOM 12 min × V reps par minute » | 6 | technique `emom` (une ligne par minute) dans un groupe `emom` ; dips et pompes « enchaînés » dans le même groupe | un chrono pour le groupe |
| Contrastes « 3 rounds : … » | 20 | groupe `circuit` (3 tours, 3 min) ; contraste du squat : partie explosive (squat sauté) | tel qu'écrit, dans son groupe |
| Échelles « 4 échelles dégressives de 7 à 1 » | 3 | groupe `circuit` (4 tours de 28, 2 min) ; dips et pompes enchaînés | tel qu'écrit, dans son groupe |
| « N × ? reps » (référence non renseignée) | selon tes Références | maximum estimé d'après ton profil (test reporté) ou ton meilleur test au maximum noté ; Koach le dit sous l'exercice | sinon tel qu'écrit, « ? » ouvre Références |

- Contrastes et échelles sont servis **tels qu'écrits** : une échelle ou un contraste n'est pas une série d'une traite, le moteur ne règle pas leurs répétitions et ne lit pas de capacité dans leurs tours (journal : technique `density`, sans partie) ; le volume compte.
- Lignes notées avant 6.11.0 dans ces formats (EMOM en un total, échelles, tours, intervalles) : relues sans lecture de capacité (elles comptaient jusqu'ici comme des séries d'une traite : un EMOM de 60 tractions lu comme une série de 60).
- **Restent absents** (servis tels qu'écrits) : seules les séries « N × ? reps » (et « EMOM 12 min × ? reps ») dont la référence n'est ni renseignée ni estimable — 33 lignes sur la sauvegarde synthétique des tests, 151 sur une installation neuve sans Références ; « BILAN — report des résultats » (« — ») n'est pas une série. Sur ton téléphone, si tes Références sont renseignées, il ne reste rien d'absent.

## 5. À tester (téléphone du propriétaire, programme de 40 semaines)

1. **Myo-reps** (élévations latérales, curls, extensions à la poulie) : sous la série, « Noter l'activation » puis « Noter la mini-série » à chaque mini-série ; le mini-repos se lance ; valide la série : une seule ligne « … (15+4+4+3) ». *Le format apparaît si ton profil dit avancé ou élite (Réglages › Profil).*
2. **Durées** (mobilité, marche ou vélo) : « 1 × 10 min », note les minutes.
3. **HIIT** (samedi) : la page « Enchaînement · Intervalles 8 × 30 s » avec son chrono ; note les tours faits.
4. **EMOM et échelles** (S26, S27 : dips puis pompes) et **contrastes** (S20 et après) : une page par enchaînement, un chrono, le résultat du groupe.
5. Si une référence manque (« ? ») : Koach dit la valeur estimée sous l'exercice ; renseigne-la dans Références pour la fixer.

## 6. Contrôles

| Contrôle | Résultat |
| --- | --- |
| Formatage, analyse (dont tests d'intégration), Python | vert (run 37934054639) |
| Suite Dart complète et mode dev | vert (run 37934054639) |
| `test/ci1f_formats_test.dart` : textes des codes d'endurance (aucun code brut) ; journal (série avec ses parties ; anciens myo-reps regroupés ou laissés) ; annotation (9 blocs valides, mode coach ; myo-reps, durées, HIIT, EMOM et groupe partagé dips + pompes, contraste servi tel qu'écrit, échelles) ; pages de séance par groupe ; références estimées ; séance S13 : myo-reps saisis mini-série par mini-série → une série au journal du moteur ; installation neuve en S20 : myo-reps servis ; résultat de groupe journalisé | vert |
| Tests adaptés : CI1 (musculation au chemin calibré), CI1d (versions des paquets), CI1e (myo-reps plus absents), versions 6.11.0 (G2, G3) | vert |
| Émulateur CI1f a (sombre, rouge) et b (clair, violet), session perso, profil avancé, S20·J1 : curl en myo-reps, activation 12 puis 3 mini-séries de 4, mini-repos lancé, conseil « Encore 1 mini-série au plus (10 s entre deux) ; arrête dès qu'une mini-série n'atteint plus 4 », série validée 24 (12+4+4+4) ; S20·J3 : contraste en carte « Enchaînement · Circuit · 3 tours · 3 min entre deux tours », résultat du groupe enregistré. Captures `ci1f_01` à `ci1f_06`, sombre et clair, relues | vert |
| Émulateur CI1e, CI1c, CI1 (a et b), CU, G1 à G10, M7, M8 (non-régression) | vert |
| Paquets | vert, identiques aux étiquettes |
| Build de `main` signé | non fait (publication sur `main` refusée à la session) |

Essais : contrôle complet 1 à 4 (cible CI1f seulement : bande de mini-séries sous chaque série → série en cours seulement ; navigation de la cible) ; la suite Dart et les autres cibles étaient vertes dès l'essai 1. Le build de contrôle déclenché par `claude/ci-3d` échoue une fois sur deux sur des délais de `m8_carte_2d_test` (rendu, sans rapport avec le lot).

Relecture indépendante du code (sous-agent Opus) : 13 constats, traités (DECISIONS_CP.md, CI1f.11).

## 7. Limites et reste à faire

- La plage d'un myo-rep annoté est celle de l'**activation** (et non le total, comme le contrat l'écrit sans le contrôler) : `kalis_adapt` 0.3.0 règle la charge d'une ligne sur sa plage. À reprendre si CY lit autrement les myo-reps.
- Les techniques à mini-séries ne sont servies qu'à partir du niveau avancé (matrice de `kalis_adapt`) : avec un profil sans niveau, la ligne est servie en série classique (comme le moteur le décide).
- L'historique d'une séance de 6.9.x/6.10.0 dont une durée a été servie en secondes (≥ 2 min, multiple de 60) s'affiche maintenant en minutes (« 1150 min ») : affichage seulement, le journal donné au moteur est juste.
- Un test de course en distance se note en répétitions (le temps n'est pas encore saisi) ; distances : saisie simple, sans allure.
- Un « enchaîné » dont la ligne précédente n'est pas portée reste seul.

## 8. Recommandation (C8, le pilotage décide)

Publier 9dd09214 sur `main` (session autorisée), lancer le build signé, puis valider dev6.11.0 et la donner au propriétaire à la place de dev6.10.0. Pour CY : (1) servir la technique (myo-reps, clusters) aussi en règle générale ; (2) préciser la plage d'un myo-rep (activation ou total) dans le contrat ; (3) la part 0 de CY entrera par un lot court.

Détail des décisions : `pipeline/cp/DECISIONS_CP.md`, section CI1f.
