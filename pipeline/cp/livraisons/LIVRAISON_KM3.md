# Livraison KM3 — Koach 1.0 dans l'application (dev7.0.0)

Pipeline « Calibrage des programmes », voie App (tâche « Opus 5.5, effort élevé, application »), lancé par le pilotage le 16/10/2026 vers 06:45 UTC (DECISIONS_CP.md C17.14). Délégation (C8) : validation par le pilotage sur les critères du cahier (`CAHIER_KM.md`).

- **Base** : `main` 72596f38 (dev6.19.0). **Livré** : dev7.0.0 (7.0.0+129) sur `main` dc9cbc55, build signé run 38904862533, contrôle complet `claude/ci-3d` run 38894487551 (vert, arbre identique à `main`).
- **Paquet** : `kalis_adapt` 1.0.2 = `etiquettes/kalis_adapt-v1.0.2` à l'octet (Koach 1.0.3, KM2c2, publiée pendant le lot : LANCEMENTS.md, « prends la dernière étiquette ») ; `kalis_bench` absent de l'application ; `kalis_core` 0.4.3 et `kalis_plan` 0.3.1 inchangés. Assets `assets/koach/koach_params_1_0_3.json` et `vecteurs_qualites_v1.json` copiés à l'octet, SHA-256 vérifiés par un test.
- **Programme de 40 semaines (C11.2)** : aucune séance faite ni série validée réécrite ; sauvegarde d'origine prise avant la prise de main ; « Revenir à mon programme d'origine » gardé (nouvelle référence versée à Koach, journal gardé).

## 1. Décision structurante : la bascule (INTEGRATION_KM3.md § 10, question 1)

**Koach 1.0 est entièrement intégré, mais la bascule est fermée dans ce build** (`kKoachBasculeAutorisee = false`, `lib/koach1_store.dart`) :

- le prompt dit « avant [la bascule], le moteur 1.0.0 est intégré mais le bloc en cours n'est pas coupé » et LANCEMENTS.md « la bascule exige la version de Koach validée la plus récente (1.0.3 après KM2c2) et le rejeu du journal réel sur un export neuf du propriétaire (C17.13.3) ; KM3 livre le mécanisme et ses tests ». KM2c2 a été validé pendant le lot (C17.16, 08:25 UTC : `kalis_adapt` 1.0.2 est la version visée, c'est celle de ce build), mais **le critère 10 n'est pas mesuré** sur un export neuf : une bascule automatique au 23/11 avec ce build serait une bascule sans cette preuve ;
- d'ici là, **le moteur de dev6.19.0 (code de 0.3.1, présent à l'identique dans `kalis_adapt` 1.0.x) continue de servir le bloc en cours** (réponse (a) de la question 1) : aucune perte des garde-fous de séance (conduite sous douleur, poignet, bilan bas), ce que (b) aurait retiré pendant cinq semaines ;
- **le mécanisme est complet** : date de bascule notée à la première ouverture (23/11/2026 si dev7.0.0 est installé au plus tard le 16/11/2026, sinon 04/01/2027), prise de main au début du bloc de cette date (S20 pour le programme du propriétaire), programme créé au premier début de bloc après l'installation ;
- **la session de test du mode dev force la bascule** (inspecteur de Koach › « Koach prend la main cette semaine ») : tout Koach s'y essaie sur une copie du programme de 40 semaines, sans toucher la session personnelle ;
- **pour basculer** : un lot court passe `kKoachBasculeAutorisee` à `true` (une ligne, plus la version) et republie ; la date notée à l'installation de dev7.0.0 est gardée (préférence `km3_installation_v1`), la date du cahier s'applique alors toute seule.

Recommandation au pilotage : valider ce choix ; demander au propriétaire un export neuf (sauvegarde, ou « journal moteur » de l'inspecteur, § 5), mesurer le critère 10, puis lancer ce lot court **avant le 16/11/2026** pour garder la bascule au 23/11/2026 (aucune montée de paquet nécessaire : 1.0.2 est déjà la version validée).

## 2. Ce qui est livré

### 2.1 Moteur et journal (`lib/koach1/`, `lib/koach1_store.dart`)

- **Un objet `Koach` vivant**, construit avec ses quatre extensions dans l'ordre du banc (planification avec le validateur de sécurité à lecture tardive, surveillance, contrôle dual, adhérence) ; **journal de Koach persisté tel quel** (section `koachEngine` du document, exportée avec la sauvegarde) avec ses instantanés hors journal (profil de Koach, profil de validation et lundi de S1, mouvements principaux, extensions, versions et SHA-256) ; **rejeu exact** vérifié (aller-retour JSON : `posterior`, planification, surveillance, contrôle dual, adhérence identiques).
- **Prise de main** (§ 7.1) : sauvegarde d'origine, profil de Koach par les règles de `journal_app.profil_de` (niveau, sexe, poids, zones fragiles, valeurs déclarées initiales, accessoires convertis par la courbe de population), historique déjà fait versé sans `plan` (`semaine_fin` à chaque lundi), puis une seule `reference` (blocs annotés d'origine, sans la couche CI1c ni les propositions de 0.x ; échéance = jour de test de S40 ; cibles = objectifs du propriétaire d'abord, sinon `mainLifts.target`). Sans poids connu, pas de prise de main (Koach prendrait 72 kg).
- **Rattrapage du lundi**, hors du fil d'interface (isolat) : séances faites hors de Koach versées, séances manquées (`seance_manquee` + `contexte.manquees`), `semaine_fin` (replanification), proposition d'essai N-of-1 du contrôle dual (contexte obligatoire), puis séances faites de la semaine en cours.
- **Séance du jour** : aperçu sans appel au moteur (journée écrite, séries de la semaine modulée, charge fixe) ; **début réel** au premier exercice (bilan réglé) : `poids`, `seance_debut` (bilan, pesée, contexte complet : semaine, jour écrit, nature et intention de la semaine, jour d'épreuve, budget, lieu, séances manquées, reste de la semaine), réponse au diagnostic, `plan(seance)` sur les items écrits ; **une cible par série** (`plan(serie)`, une fois, juste avant de la proposer, après avoir versé les séries faites dans l'ordre de réalisation) ; vrai test inséré avant le travail (exercice « Test court », refusable) ; « arrêter l'exercice » respecté ; **fin de séance** : séries restantes, `seance_fin` (douleurs signalées après le début), décisions de la séance ; corrections d'une série déjà versée (note, répétitions, charge, décochée) : événement remplacé ou retiré, puis rejeu (question 8).
- **Charge fixe (C15)** au-dessus de Koach : ligne `load.type == 'fixed'` servie à sa charge écrite, plage plafonnée au haut de la ligne, sauf charge plus basse de Koach sous douleur (zone sollicitée active, raison de douleur, de reprise ou de poignet) ; Koach apprend de la charge réellement faite.
- **Prévision de la prochaine fois (C15.4)** : même calcul que la séance, sur une **copie** du moteur (isolat), jour réel, charge fixe comprise ; l'écran de fin de séance l'affiche quand elle arrive.
- **Programme créé** : résumé d'adaptation de `nextBlock` construit depuis `posterior()` ; nouvelle `reference` versée dès que les blocs changent (bloc suivant écrit, retour au programme d'origine).

### 2.2 Comportement unique (écrans)

- **À la séance** : cible de Koach par série (charge, plage, flammes) ; **une ligne de raison** (texte de `koach_textes.dart`, jamais un code) ; **suggestion** sur la première série (charge proposée par rapport au dernier passage, paliers) **validée d'un tap**, ou **refusée** avec une raison facultative en un tap (trop lourd, trop léger, matériel, temps, autre, sans raison) ; la charge d'avant est alors pré-remplie, la décision versée après la fin de séance ; aucune baisse de sécurité n'est présentée comme une suggestion ; message de Koach après chaque série quand la cible suivante change.
- **Chaque lundi** : semaine à venir modulée affichée dans Mon programme et l'accueil (« Koach, cette semaine : 4 séries au lieu de 5 · charge −3 % », l'écrit en dessous) ; semaines suivantes telles qu'écrites.
- **Fin de bloc** : carte à l'accueil et dans Évolution, écran « Bloc suivant : ce qui change et pourquoi » (volume par qualité, charges, chances par objectif contre le plan écrit), validé d'un tap ; un refus est noté, le plan modulé reste (question 3, garde-fou anti-complaisance).
- **Hors modèle** : au début de la séance, « Cette situation sort de mon modèle » + la cause, puis 3 questions au plus (texte et choix de `koach_textes.dart`), réponse versée avant `plan` ; « Plus tard » possible.
- **Arrêt d'urgence** : Réglages › Séance › Koach 1.0 (et Évolution), une confirmation ; séances servies telles qu'écrites, semaine en cours avec ses séries modulées ; rien perdu ; **réactivation** par rejeu du journal puis rattrapage de tout ce qui s'est passé (séances versées sans `plan`) ; l'écran rappelle l'avis de consulter en cas de douleur (question 5).
- **Aide des clusters** : « RIR visé sur chaque bloc · note la série au bloc le plus dur » dans « Comprendre Koach » et le titre de la bande des blocs.
- **Mode dev** (`kDevBuild`, absent de l'AAB) : inspecteur de Koach (état, versions et empreintes, **temps de calcul réels**, raisons et traces de la séance, capacités et intervalles, qualités, biais et bruit de la note, fatigue, planification, surveillance, contrôle dual, adhérence) ; **export du journal moteur** (journal + séances au format de `walk_forward.rejouer`, disponible avant la bascule) ; **export du dossier hors modèle** ; **import d'un fichier de paramètres** (sélecteur système, erreurs affichées) ; **rejeu walk-forward** (mesure A, agrégats et critère 10) ; bascule forcée de la session de test.

### 2.3 Retraits

| Élément | Sort dans dev7.0.0 |
| --- | --- |
| Code de décision de 0.x, couche d'ajustement CI1c, statut spécial du programme importé, revue et propositions de 0.x | **inactifs sur toute semaine conduite par Koach** (la séance, l'affichage et Évolution ne les appellent plus) ; ils servent encore le bloc en cours jusqu'à la bascule (§ 1) ; le code 0.x quitte l'APK au lot de bascule |
| Modes assisté / libre, choix « garder le moteur d'avant », option de structure, déblocage | masqués dès que Koach conduit le programme (un seul comportement) ; le champ du profil reste lu et réécrit à l'identique |
| Série AMRAP toutes les 4 semaines, filtre RIR | partent avec 0.x (Koach sert ses séries repères et son vrai test) |
| Données de 0.x (`SessionLog.adapt`, décisions, `planEvolution`) | gardées, lues telles quelles, jamais versées à Koach (question 11) |

## 3. Tests

- `test/km3_koach_test.dart` (17 tests) : assets à l'octet et SHA-256 ; bascule fermée (le moteur d'avant sert le bloc) ; dates 23/11/2026 et 04/01/2027, prise de main en S20 ; prise de main forcée : historique sans `plan`, une `reference`, rejeu exact ; séance servie (aperçu, début réel, cible par série, fin versée, prévision sur copie) ; **suggestion refusée « trop lourd »** (charge d'avant pré-remplie, décision versée après `seance_fin`) ; **arrêt d'urgence et réactivation** ; lundi suivant : séances manquées, replanification, **hors modèle (assiduité) et diagnostic** ; export du journal moteur et walk-forward ; sauvegarde (section relue, ancienne sauvegarde sans la section) ; **charge fixe** ; textes sans code brut ; **migration** sans réécriture + retour au programme d'origine ; séance servie chaque semaine de S15 à S20 ; reprise après quatre semaines sans séance.
- **`calculs dans un isolat`** (dans `km3_koach_test.dart`) : prise de main, rattrapage du lundi, début de séance, série, fin, nouvelle référence, arrêt et réactivation avec les calculs réellement envoyés à un isolat, comme sur le téléphone (les autres tests calculent sur place). Ce test a été ajouté après la première cible émulateur : le rattrapage et la nouvelle référence passaient à l'isolat une fermeture créée dans le magasin, dont le contexte emportait le magasin lui-même (inenvoyable) ; sur le téléphone, le rattrapage échouait, le moteur était rejoué en boucle et la séance ne commençait jamais. Corrigé (`KoachCalcul.rattraper` / `observer`, fermetures créées hors du magasin).
- `test/km3_seance_ecran_test.dart` : parcours à l'écran comme sur l'émulateur (bascule forcée un vendredi, S14·J5) : bilan, « Premier exercice », la séance de Koach commence (6 items servis).
- `test/ui_km3_capture_test.dart` : rendus sombre / clair (bordeaux, violet) de la carte de Koach (attente, active, arrêtée), de la suggestion, de la feuille des raisons, du récapitulatif de bloc, de l'inspecteur.
- Cible émulateur `integration_test/koach_km3_test.dart` (a sombre rouge, b clair violet ; session perso puis session de test) : vertes (run 38894487551, émulateur Android 15, 540×960). Session perso : Koach installé mais pas actif, bascule visée 23/11/2026, installation notée 16/10/2026, sauvegarde d'origine prise, journal de 0.x identique, export du journal moteur (82 séances) disponible, carte « en attente », session perso intacte après la session de test. Session de test : sauvegarde importée, bascule forcée, prise de main en S14 (1 986 événements), aperçu puis séance commencée (6 items servis), cible par série, série validée, suggestion affichée, refusée « Trop lourd » (décision `too_heavy` versée à la fin de séance), séance versée, carte active dans Évolution, inspecteur, arrêt d'urgence puis réactivation. Rendus dans les deux thèmes (`ci-out/emulateur/km3_*`).
- **Défaut trouvé par la cible émulateur et corrigé** : voir le test « calculs dans un isolat » ci-dessus (rattrapage et nouvelle référence envoyaient le magasin à l'isolat). Sans la cible émulateur, il serait passé : les tests Dart calculaient sur place.
- Tests existants adaptés : versions (7.0.0, `kalis_adapt` 1.0.2) ; limite de l'arbre du dépôt (hors ressources chiffrées) portée de 30 à **59 Mo** (`tools/release_security.py`) : le paquet copié à l'octet pèse 29,6 Mo (référence Python 21,4 Mo, tests et fixtures 5,6 Mo) au lieu de 1,7 Mo, l'arbre passe de 26,5 à 55,5 Mo ; 59 Mo reste sous le budget chiffré de 60 Mo (test M6c inchangé). L'APK n'embarque que le Dart et les deux assets. **Recommandation** : marge de 3,5 Mo seulement ; avant la prochaine montée de `kalis_adapt`, le pilotage peut décider de ne copier dans l'application que `lib/`, `assets/`, `docs/` et `pubspec.yaml` (la référence et les fixtures restent sur `moteurs`), ce qui ramène l'arbre vers 28 Mo.

## 4. Temps de calcul

| Mesure | VM de la CI (tests) | Émulateur (cible KM3) | Cahier |
| --- | --- | --- | --- |
| Prise de main (historique S1-S14 + référence, rejeu) | 2,0 à 3,4 s | 16,0 à 17,7 s | — |
| Replanification du lundi | 0,7 à 1,2 s | 0,28 à 0,32 s (rattrapage de S14) ; une semaine complète ≈ 1,2 s (prise de main de 14 semaines en 17 s) | ≤ 10 s |
| `plan(serie)` | ≤ 5,2 ms (0,06 ms en général) | ≤ 4,4 ms | ≤ 50 ms |
| `observe(serie)` | ≤ 1,3 ms | 2,1 ms | — |
| `plan(seance)` | ≤ 17 ms | 16,4 ms | — |
| Début de séance (rattrapage + `seance_debut` + `plan(seance)`) | ≈ 100 ms | 42 ms | — |
| Prévision de la prochaine fois (copie dans l'isolat) | 0,18 s | 0,12 s | — |
| Rejeu du journal au démarrage de l'application (isolat, l'écran reste utilisable) | 3,3 s | 6,7 à 10 s | — |

L'inspecteur du mode dev affiche ces temps sur le téléphone.

## 5. Critère 10 (pour le pilotage)

L'export « journal moteur » (inspecteur › Exporter le journal moteur) fonctionne avant la bascule : `{type: journal_moteur, version, version_moteur, version_parametres, sha256_parametres, profil, extensions, principaux, lifts, journal, seances, rapport}`, chaque séance au format de `walk_forward.rejouer` (`cle, semaine, jour, avant, debut, series, meta, fin`). Lecture par la référence Python : `conversion = {profil, principaux, seances, rapport}` puis `walk_forward.rejouer(conversion, params, fiches, 12)` et `agreger` (sans fichier de correspondance). Il contient des données de santé : partage par le système seulement, jamais versé en clair au dépôt (C13.6).

## 6. Décisions prises sous délégation (INTEGRATION_KM3.md § 10)

1. Avant la bascule : (a), moteur d'avant jusqu'à la bascule, bascule fermée dans ce build (§ 1).
2. Profil de Koach figé (instantané, rejeu exact) : limite acceptée ; une gêne nouvelle passe par le journal (douleurs).
3. Refus du récapitulatif : noté, le plan modulé reste.
4. « Moins de temps » : durée en `contexte.budget` ; nombre de séances gardé à titre d'information, aucune journée sautée d'office.
5. Arrêt d'urgence : écrit servi, avis de consulter rappelé.
6. Crans d'élastique : pas de champ ajouté (limite).
7. `jours_avant_echeance` : non passé, comme au banc.
8. Corrections a posteriori : remplacement de l'événement et rejeu.
9. Séances libres : ignorées (comme le critère 10).
10. Échéance : jour de test de S40 ; cibles : objectifs du propriétaire d'abord.
11. Données 0.x : gardées, lues telles quelles.

## 7. Limites

- Une douleur signalée pendant la séance n'atteint Koach qu'à `seance_fin` (le contrat n'a pas d'événement de douleur en cours de séance) ; la séance déjà servie ne change pas.
- Programme créé : la modulation de la semaine n'est montrée que dans la séance (aperçu), pas dans la liste de Mon programme (affichée pour le programme de 40 semaines).
- Le journal de Koach grossit avec les séances (≈ 2 000 événements pour S1-S14) et s'écrit avec le document : à surveiller.
- Lignes à charge fixe : la planification ne connaît pas la contrainte (P(réussite) un peu optimiste, § 8 point 7).
- Code 0.x encore dans l'APK jusqu'à la bascule (§ 1).
- Démarrage à froid : le journal de Koach est rejoué dans un isolat à l'ouverture de l'application (6,7 à 10 s sur l'émulateur de la CI, sans doute moins sur le téléphone) ; une séance commencée juste après l'ouverture attend ce rejeu (l'aperçu reste affiché, puis les cibles de Koach arrivent). Piste si c'est gênant : garder un instantané de l'état du moteur à côté du journal.
- Limite de l'arbre du dépôt portée à 59 Mo (§ 3) : marge de 3,5 Mo.

## 8. À tester (propriétaire)

1. Installer dev7.0.0 par-dessus dev6.19.0 : séances, records, STATS et séance du jour comme avant ; Réglages › Séance › Koach 1.0 : « Koach 1.0 est installé… date visée 23/11/2026 ».
2. Mode dev : session de test (5 appuis sur le logo), importer ta sauvegarde, inspecteur de Koach › « Koach prend la main cette semaine » ; ouvrir la séance du jour : bilan, premier exercice, charge et raison de Koach, valider des séries (la cible suivante suit), valider ou refuser une suggestion, finir : « La prochaine fois » apparaît.
3. Dans cette session de test : Réglages › Koach 1.0 › Arrêt d'urgence puis Réactiver ; inspecteur : temps de calcul réels sur ton téléphone ; Exporter le journal moteur.
4. Session perso : rien ne doit avoir changé dans ta séance du jour.
