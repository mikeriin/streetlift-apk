# Livraison KB2 correction 1 — Popup de Koach et séance servie (dev7.2.2)

Pipeline « Calibrage des programmes », voie App (tâche « Opus 5.5, effort élevé, application »), lancée par le pilotage le 19/10/2026 vers 08:50 UTC (DECISIONS_CP.md C17.36). Délégation (C8) : validation par le pilotage.

**Ce lot n'a rien déchiffré, n'a pas lu `cp-references`, n'a reçu aucune clé et n'a manipulé aucune donnée du propriétaire (C17.33.2).** Tous les tests tournent sur des données synthétiques : la semaine type du nouveau programme est `test/fixtures/pr9_semaine.json`, déjà dans le dépôt.

- **Base** : `main` 60e17e2b (dev7.2.1, KB2).
- **Livré** : dev7.2.2 (7.2.2+142) sur `main` 2699c208 (avance rapide depuis 60e17e2b, aucun commit du propriétaire entre-temps) ; build signé run 39247838502 (essai 2 : le premier est resté en file d’attente chez GitHub ; https://github.com/mikeriin/streetlift-apk/actions/runs/39247838502 ; APK : artefact `kalis-track-apk`, https://github.com/mikeriin/streetlift-apk/actions/runs/39247838502/artifacts/12186467387) ; contrôle complet `claude/ci-3d` run 39238562117 vert (https://github.com/mikeriin/streetlift-apk/actions/runs/39238562117), commit 3a7ea653 dont l’arbre est identique à `main` 2699c208.
- **Paquets** : inchangés (`packages/` identique à l'octet à 60e17e2b). Aucun changement du moteur.

## 1. Cause du constat 4 (séance changée après « Plus tard »)

J'ai reproduit le problème avec une sonde CI (run CI UI 39226750025). Le programme importé est synthétique, de même forme que PR2 :
- ancien programme S1 à S14 au journal ;
- S15 à S24 sur la semaine type `pr9_semaine.json` ;
- départ affiché en S15 ;
- prise de main le lundi 19/10.

**Ce qui se passe sur S1·J1** (« TIRAGE LOURD + MUSCLE-UP ») :
- **Écrit** : 7 lignes. Muscle-up lesté E2MOM 6×2 ; traction lestée E2MOM 8×3 avec les pompes PdC enchaînées dans la pause (8×11, RIR 5+) ; rowing ; poignets ; finisher face pulls + curl marteau.
- **Servi par `plan(seance)`** : 5 items. Le muscle-up lesté et la traction lestée manquent.
- **Raisons du moteur** : `koach.retour_gradue` sur les deux lignes (groupe « chest », limite 55,8 séries, `series: 0`).

**Cause dans le moteur** (`packages/kalis_adapt/lib/src/koach/seance.dart`, `_budgetsRetour` puis `_retourGradue`, règle de Koach 1.0.5) :
- La règle borne les séries dures de la semaine par grand groupe. La limite vient du volume réalisé les semaines d'avant (`_limiteVolume`, rampe de hausse).
- Le moteur réserve d'abord le volume des séances écrites restantes de la semaine (`reste_semaine`), puis sert les items du jour dans l'ordre.
- Le nouveau programme charge beaucoup le groupe « chest » sur la semaine : dips lestés, pompes lestées, dips au départ chronométré, développé…
- Le budget de ce groupe est donc épuisé avant J1. Les deux premières lignes qui le créditent (muscle-up lesté, traction lestée, séries dures) passent à 0 série et sont retirées.
- Les pompes PdC (RIR 5+) ne comptent pas comme séries dures : elles restent.

**Cause dans l'application** :
- `adaptDay` (`lib/session_adapt_store.dart`) retirait en silence toute ligne écrite absente du servi.
- Cela touchait aussi les lignes au départ chronométré servies telles qu'écrites (PR8).
- Résultat à l'écran : la carte « pompes PdC · E2MOM 8 tours · 16 min » ouvrait la séance, suivie de rowing, poignets et du finisher (4 cartes). C'est exactement la capture du propriétaire.

**« Plus tard » n'y est pour rien** : la sonde sert la même séance avec et sans alerte. L'alerte ne change rien au plan. Elle a seulement coïncidé avec la première séance du nouveau programme.

**Correction côté application (garde, point 5)** : `koachGardeSeance`, fonction pure testée, appelée par `koachStartNow`. Koach ne retire ni n'ajoute plus jamais un exercice en silence :
- La séance servie suit l'ordre écrit. Un vrai test de Koach reste devant sa ligne. Un item sans ligne écrite est écarté.
- Une ligne écrite absente du servi est servie **telle qu'écrite** : c'est la ligne de l'aperçu, avec les séries de la semaine et la charge fixe C15. Elle est notée `ecrites` dans l'état de la séance.
- La raison est affichée sur la carte, par exemple « Servi tel qu'écrit. Koach l'aurait retiré pour rester dans le volume de la semaine : écoute tes sensations. ». La raison du retrait annulé n'est plus dite dans l'en-tête.
- **Retraits motivés gardés**, avec leur raison affichée en tête : conduite sous douleur (`koach.douleur_retrait`), course ou cardio retirés au bilan bas ou sous douleur (`koach.endurance_retrait`), test reporté sur une ligne de test (`koach.test_reporte`), séance bornée au temps que l'athlète a donné (`koach.seance_bornee` avec un budget).
- Une ligne que la planification de la semaine a mise à 0 série n'est déjà pas dans l'aperçu : elle reste retirée, comme l'aperçu le montrait.
- Une ligne servie telle qu'écrite n'appelle pas `plan(serie)`. Ses séries sont versées au moteur comme observations ; `serieFaite` accepte une série sans plan.

**Limite (moteur, non changé)** : `fermer` ne compte au volume réalisé de la semaine que les items que Koach a servis. Les séries d'une ligne servie telle qu'écrite sont observées par le modèle de capacité, mais n'entrent pas dans le volume qui nourrit la règle de retour gradué. Cette règle sous-estime donc le réalisé et continuera de vouloir retirer ces lignes, que la garde remet.

**Recommandation** : un lot moteur court (KM1c5 / KM2c4) pour deux points.
- Compter au volume réalisé les séries observées hors du servi.
- Revoir l'ordre « réserve du reste de la semaine d'abord » : il sacrifie les lignes principales du jour au profit des séances à venir. Une solution serait de répartir l'excès sur la semaine, ou de réduire les accessoires d'abord.

## 2. Popup du questionnaire hors modèle (`lib/koach1/koach1_widgets.dart`)

1. **Libellés** : `koachChoiceLabel(question, choix)` donne le texte de l'application pour le **code** du choix, ou à défaut le texte du choix rendu par le moteur. Les cinq questions sont couvertes : cause, zone, intensité, séances par semaine, durée. Plus jamais « Autre chose » pour un choix connu.
2. **Réponses** :
   - `reponses[code]` reçoit le code du choix (`koachChoiceCode` : chaîne ou entier).
   - `koachDiagnosticValid` vérifie chaque réponse contre les choix de sa question, avant tout envoi au moteur.
   - Si une réponse est refusée (invalide, ou `repondre` qui lève une erreur), la séance n'est jamais perdue en silence :
     - un message à l'écran : « Koach n'a pas pu prendre ta réponse en compte : tu fais la séance écrite aujourd'hui. Il te reposera la question à la prochaine séance. » ;
     - la séance passe à l'état `ecrite`, c'est-à-dire l'aperçu ;
     - le journal du moteur est coupé avant le début de séance, pour qu'il reste rejouable ;
     - la question revient à la séance suivante. La même journée redevient l'aperçu le lendemain si elle n'est pas commencée.
3. **Message d'entrée** : `koachDiagnosticIntro` donne une phrase par cause, sans la fin « cette situation sort de mon modèle », puis le message d'entrée une seule fois. Exemple : « Tes dernières séances ne ressemblent pas à ce que j'attendais. Cette situation sort de mon modèle : réponds à trois questions au plus pour que je m'adapte. »
4. **« Plus tard »** sert la même séance que sans alerte (tests unitaire et écran) ; la question revient à la séance suivante. Une feuille de question fermée (glisser, retour) vaut « Plus tard ».

## 3. Arrêt d'urgence pendant une séance commencée (point 6)

`koachStop` ramène une séance commencée et non finie, servie par Koach, à la séance écrite (`_koachBackToWritten`, semaines servies par Koach seulement) :
- les séries validées ou saisies sont gardées ;
- les autres séries sont vidées, au nombre écrit ;
- l'écran de séance ouvert passe à l'écrit.

À la réactivation, la séance de Koach reprend avec ses séries gardées.

## 4. Tests

- `test/kb2c1_seance_servie_test.dart`, 11 tests :
  - garde pure : retour gradué, retraits motivés, ordre, vrai test, ajout ;
  - S1·J1 PR2 servie identique à l'écrit (mêmes cartes, même ordre, mêmes blocs E2MOM, raisons) ;
  - « Plus tard » identique à « sans alerte », question reposée en J2 ;
  - les quatre causes menées de bout en bout : réponse acceptée, action codée (`conduite_douleur`, `replanifier`, `semaine_allegee`, `elargir`), séance servie par Koach ;
  - réponse refusée : séance écrite, journal inchangé, question reposée ;
  - arrêt d'urgence en cours de séance, puis réactivation.
- `test/kb2c1_popup_test.dart`, 8 tests :
  - textes : message d'entrée pour chaque cause et combinaison, libellés et codes ;
  - popup à l'écran : « Plus tard », quatre choix, douleur → zone → intensité, moins de temps → séances → durée, retour = « Plus tard » ;
  - écran de séance S1·J1 par « Plus tard ».
- Cible émulateur `integration_test/koach_kb2c1_test.dart`, parties a (sombre, rouge) et b (clair, violet), inscrite dans `tools/ci3d_drive.sh` :
  - popup : message, choix ; feuille fermée = « Plus tard » ;
  - J1 servi identique à l'écrit ;
  - arrêt d'urgence avec une série notée gardée, puis réactivation ;
  - J2 avec « Rien de spécial » accepté.
  - Relevés `kb2c1_releve_a.json` / `_b.json` et captures `kb2c1_*`.
- Toutes les cibles d'avant (KB2, KB1, KS1A, KM3, BV11, CIF, CI1g…G1, M8, M7) : vertes, run 39238562117 (`drive-code.txt` : tous les codes à 0). Tous les tests Dart, mode dev, Python, paquets : verts.
- Version : `pubspec.yaml` 7.2.2+142, `kVersion`, tests de version, `SUIVI_PROJET.md`.

## 5. Relecture indépendante

Un sous-agent Opus a relu le diff de `lib/`. Points traités :
- journal coupé sur échec (sinon `seance_debut` orphelin ou rejeu bloqué) ;
- `koach.endurance_retrait` traité comme motivé ;
- état `ecrite` périmé le lendemain ;
- ligne à 0 série par la planification laissée retirée ;
- arrêt d'urgence limité aux semaines servies.

Points notés sans correction :
- volume réalisé des lignes servies telles qu'écrites (moteur, § 1) ;
- raisons rattachées à l'exercice et non à la ligne, quand un même exercice occupe deux lignes (rare) ;
- `plan(serie)` remplace la liste des raisons : la mise en avant d'un retrait s'efface après la première série.

## 6. Recommandation au pilotage

Valider dev7.2.2 (urgent : le propriétaire s'entraîne avec Koach).

Lancer ensuite un lot moteur court sur le retour gradué (§ 1), avant la re-mesure du critère 10 vers le 09/11. Tant que ce lot n'est pas fait, les lignes lourdes du nouveau programme seront souvent « servies telles qu'écrites » : la charge vient du programme et non de Koach. Ce sont les lignes au départ chronométré, déjà servies telles qu'écrites depuis PR8.

## 7. À tester (propriétaire)

- Installer dev7.2.2. Ouvrir la séance du jour et vérifier qu'elle a les mêmes exercices, dans le même ordre, que le programme.
- Si Koach pose ses questions : les quatre réponses ont leur texte. « Plus tard » ne change pas la séance.
- Une carte marquée « Servi tel qu'écrit » suit le programme : régler la charge au ressenti.
- Arrêt d'urgence en cas de doute : la séance revient au programme, les séries notées restent.
