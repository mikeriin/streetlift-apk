# Livraison KB2 — Bascule ouverte par dérogation, prise de main immédiate de Koach 1.0.5 (dev7.2.1)

Pipeline « Calibrage des programmes », voie App (tâche « Opus 5.5, effort élevé, application »), relancé par le pilotage le 18/10/2026 vers 19:00 UTC (DECISIONS_CP.md C17.32, C17.33, C17.34) ; 2e session (la 1re s'était arrêtée sur un refus de déchiffrement). Délégation (C8) : validation par le pilotage.

**Ce lot n'a rien déchiffré, n'a pas lu `cp-references`, n'a reçu ni utilisé aucune clé et n'a manipulé aucune donnée personnelle du propriétaire (C17.33.2).** Tous les tests tournent sur des données synthétiques.

- **Base** : `main` 293e5689 (dev7.2.0, KB1). **Livré** : dev7.2.1 (7.2.1+141) sur `main` 60e17e2b (avance rapide depuis 293e5689), build signé run 39206500464 (https://github.com/mikeriin/streetlift-apk/actions/runs/39206500464 ; APK : artefact `kalis-track-apk`, https://github.com/mikeriin/streetlift-apk/actions/runs/39206500464/artifacts/12166750252), contrôle complet `claude/ci-3d` run 39190303462 (même commit que `main` : arbre contrôlé identique ; job émulateur relancé une fois, le premier essai n'ayant pu joindre le service VM de l'application sur quatre cibles d'avant, avant tout test).
- **Paquets** : inchangés (`packages/` identique à l'octet à 293e5689 : `kalis_plan` 0.4.2, `kalis_adapt` 1.0.4 / Koach 1.0.5, `kalis_core` 0.4.4).
- **Bascule** : **ouverte** (`kKoachBasculeAutorisee = true`) par dérogation du propriétaire (C17.34) ; prise de main immédiate.

## 1. Critère 10 (mesuré par le pilotage, non re-mesuré ici)

Source : `pipeline/cp/donnees/rejeu_journal_agregats_kb2.json` (C17.33.3, agrégats seulement : rejeu direct du journal moteur converti par dev7.2.0, référence `etiquettes/kalis_adapt-v1.0.4`, paramètres SHA-256 `d8a492b7…f26d` = asset de l'application, depuis S12).

| Mesure | Valeur |
| --- | --- |
| A — une séance d'avance (e1RM), n = 61 | erreur moyenne **5,9 %**, médiane **2,9 %**, biais **+0,8 %**, couverture 90 % : **86,9 %** |
| Principaux (n = 15) / autres (n = 46) | 4,3 % (médiane 1,9 %) / 6,4 % (médiane 4,1 %) |
| C — notes « ouvertes » | prévues **41 %**, observées **20 %** (écart note − prévision −2,56 répétitions) |
| B — tests réels (n = 5) | 22,3 %, biais +17,0 %, couverture 60 % |
| Séries notées depuis S12 | 244 (≥ 100 demandées) |

**Critère 10 : non tenu** (erreur ≥ 3 %, couverture < 88 % ; biais tenu). **Ouverture par dérogation du propriétaire (C17.34).** L'inspecteur du mode dev affiche : « Critère 10 (18/10) : non tenu — ouverture par dérogation · erreur 5,9 %, couverture 86,9 % » (`kKoachCritere10`).

**Re-mesure prévue vers le 09/11/2026** (C17.34.3) : nouvel export du journal après trois semaines du nouveau programme (inspecteur › « Exporter le journal moteur »), rejeu par le pilotage ; toujours non tenu → lot moteur ciblé (notes « ouvertes », tests réels sous-estimés) ou retour au moteur d'avant par l'arrêt d'urgence.

## 2. Règle de prise de main (`lib/koach1_store.dart`)

- `koachTakeoverPlanned()` : semaine S de la **première séance non faite** (journée avec exercices, journal non fait) à partir de max(départ affiché `firstShown` (PR2), premier bloc d'un programme créé, semaine du jour, semaine de la date d'ouverture). Même règle pour un programme importé et un programme créé.
- `koachTakeoverWeek()` : cette semaine dès que son lundi est passé (à l'ouverture de l'application, au retour au premier plan, avant une séance). Jamais une semaine d'avant `firstShown`, jamais une semaine passée, jamais une séance faite.
- **Date d'ouverture** : notée au premier lancement d'un build où la bascule est ouverte (`KoachEngineData.openedOn`, clé locale `kb2_ouverture_v1`) ; la date d'installation notée par dev7.0.0 à dev7.2.0 (`installedOn`) ne décide plus de rien (gardée pour l'inspecteur).
- `kKoachInstallLimite`, `kKoachBasculeVisee`, `kKoachBasculeRepli` et `koachBasculeDate` (23/11/2026 / 04/01/2027) **retirés** (plus aucun écran ne les lisait hors de la carte et de l'inspecteur, réécrits). Session de test : la date forcée garde son chemin (`koachForceBascule`).
- **Séances faites de la semaine de prise de main** : gardées telles quelles au journal de l'application, versées au journal de Koach (sans `plan`) au rattrapage ; Koach sert les suivantes. **Séance commencée avec le moteur d'avant avant la prise de main** (cas d'une mise à jour en pleine séance, ou du bouton « Ouvrir la séance » ci-dessous) : `koachStartedBefore` — gardée telle qu'elle a été servie jusqu'à sa fin (ni réécrite par Koach, ni modulée par la semaine de Koach), versée une fois faite (constat de la relecture indépendante, corrigé et testé).
- **Propositions du moteur 0.x en place sur les semaines reprises** : traitées comme à la prise de main de KM3 — la référence de Koach est le programme écrit (blocs annotés d'origine, sans la couche d'ajustements CI1c ni les propositions de 0.x ; programme créé : blocs ajustés `adjustedBlock` comme en KM3) ; code de décision de 0.x, couche CI1c, revue et propositions de 0.x **inactifs sur toute semaine conduite par Koach**. Rien n'est effacé (les propositions restent enregistrées dans l'Évolution) ; l'arrêt d'urgence sert l'écrit, pas le moteur d'avant (KM3). Le code 0.x reste dans l'APK (repli des programmes que Koach ne conduit pas, C17.32.5).

### Semaine et séance de prise de main attendues pour le propriétaire

| Installation de dev7.2.1 | Prise de main | Première séance servie par Koach |
| --- | --- | --- |
| Dimanche 18/10 ou lundi 19/10 avant la séance | lundi 19/10 à la première ouverture (S15 interne = **S1 affichée**) | **J1 de S1** |
| Mardi 20/10, J1 faite | à l'installation, S1 | J2 (J1 reste telle quelle) |
| Mercredi 21/10, J1 et J2 faites | à l'installation, S1 | J3 |
| Dimanche après une S1 entièrement faite | lundi suivant | J1 de S2 |

Charge fixe C15 (squat d'endurance à 70 kg) respectée par Koach (testé : 70 kg servis). Arrêt d'urgence de KM3 disponible après la prise de main (Réglages › Séance › Koach 1.0, et Évolution) : séances servies telles qu'écrites, réactivation par rejeu (testé).

### Exercices sans historique (règle, sans lecture du journal réel)

Un exercice du nouveau programme sans aucune série au journal part des **a priori de Koach** : valeur déclarée du profil (`declares` de l'instantané, `_koachDeclares` : références du programme et objectifs) quand elle existe, sinon l'a priori de population de sa fiche (`vecteurs_qualites_v1.json`, accessoires convertis par la courbe de population). À sa première séance, Koach le sert avec une incertitude large : charge prudente tirée de cet a priori, cible de réserve de la ligne écrite, et il se recale dès la première série notée (la note de la flamme est ce qui l'informe le plus vite). Ce lot ne dit pas lesquels des exercices du nouveau programme ont un historique : il faudrait lire le journal réel (C17.33.2) ; le pilotage peut le compter sur l'export du 09/11.

## 3. Ce que voit le propriétaire

- **Écran d'attente** : si une séance est ouverte pendant la prise de main (une seule fois), fenêtre du kit non refermable « Koach prend la main sur ton programme — Une seule fois : il relit ton historique pour servir ta séance (quelques secondes). Rien n'est perdu si tu fermes l'application. » avec un indicateur ; elle se ferme seule à la fin et la séance s'ouvre servie par Koach. **Bornée** : passé 45 s, « Ça prend plus longtemps que prévu… » et le bouton « Ouvrir la séance » (séance servie comme avant tant que Koach n'a pas fini ; si une série y est validée, la séance reste au moteur d'avant jusqu'à sa fin).
- **Carte Koach** (Réglages, Évolution) avant la prise de main : « Je prends les commandes de ton programme à partir de S1 (semaine du lundi 19 octobre) : tes séances faites restent telles quelles. » ; pendant : « … un instant, une seule fois. » ; après : carte active de KM3, avec la semaine affichée (« Koach conduit ton programme depuis S1 (19/10/2026) : il propose, tu valides d'un tap… » ; c'était « S15 », numéro interne, corrigé dans ce lot ; l'inspecteur dit « S15 interne (S1 affichée) »).
- **Inspecteur** (mode dev) : « Bascule : ouverte par dérogation · ouverture : <date> · prise de main prévue : S15 interne (S1 affichée) » et la ligne du critère 10.

## 4. Temps de la prise de main

Mesure sur l'émulateur de la CI (Android 15, x86_64, rendu logiciel) avec une sauvegarde synthétique de même forme que celle du propriétaire, un peu plus lourde : 34 séances, **788 séries** (propriétaire : 34 séances, 672 séries converties), 783 événements rejoués. Huit mesures (quatre passages de la cible, parties a et b) :

| Passage | Prise de main a / b (inspecteur, `prise_de_main`) | Attente vue à l'écran a / b (J1 ouvert tout de suite) |
| --- | --- | --- |
| run 39163928246 | 13,5 s / 8,3 s | 13,7 s / 8,5 s |
| run 39168949687, essai 1 | 29,0 s / 12,5 s | 30,9 s / 12,7 s |
| run 39168949687, essai 2 | 10,6 s / 17,9 s | 11,2 s / 17,9 s |
| run 39190303462 (contrôle final) | 17,5 s / 8,3 s | 18,2 s / 8,2 s |

Médiane 13 s, de 8,3 à 29,0 s selon la charge du runner (le même émulateur a mis 18 à 21 s pour la prise de main forcée et le rattrapage de la cible KM3 au même passage). Début de la séance ensuite : environ 1 s. Repère du cahier : 10 s ; KB1 : 10 à 14 s sur le même émulateur (journal de 84 séances). **Au-dessus du repère, ce que voit le propriétaire** : l'écran d'attente borné du § 3 (texte clair, indicateur, une seule fois) ; la séance s'ouvre seule à la fin ; au-delà de 45 s, il peut l'ouvrir sans attendre. Un téléphone récent est en général plus rapide que cet émulateur logiciel (à lire dans l'inspecteur › Temps de calcul).

**Arrêt pendant la prise de main** : rien n'est écrit avant la fin du rejeu (`_koachActivate` n'écrit l'état de Koach qu'après le calcul ; le journal de l'application n'est jamais touché ; la sauvegarde d'origine est prise avant). Testé : état enregistré au début de la prise de main (ce qu'un arrêt brutal laisserait) = aucun état de Koach, journal identique ; relancé depuis cet état, la prise de main se refait proprement (test unitaire et relevé de la cible émulateur).

## 5. Tests

- `test/kb2_prise_de_main_test.dart` (données synthétiques de la forme de la sauvegarde du propriétaire : programme importé `programInstance` généré de 24 semaines au départ affiché S15, ancien programme S1-S14 au journal, squat 70 kg à charge fixe) : constante ouverte et critère 10 ; date d'ouverture notée, date de dev7.2.0 ignorée ; **ouverture le dimanche 18/10 → prise de main le lundi en S15 (S1 affichée), J1 servi par Koach** ; **mercredi 21/10 avec J1 et J2 faits → J1, J2 intacts (versés), Koach sert J3** ; **ouverture avant `firstShown` impossible** ; **semaine passée jamais reprise** ; semaine en cours toute faite → lundi suivant ; **bascule fermée (constante à faux) : rien ne change** ; charge fixe 70 kg servie par Koach, **arrêt d'urgence puis réactivation** ; séance commencée avec le moteur d'avant gardée ; **migration depuis dev7.2.0 sans perte** (journal, programme importé, sauvegarde d'origine identiques) et **export après la prise de main réimporté à l'identique** ; arrêt pendant la prise de main ; **programme créé (kalis_plan) : même règle** ; écran d'attente (fermeture seule, borne de 45 s).
- `test/flutter_test_config.dart` : les tests des lots d'avant tournent bascule fermée, comme à leur lot (moteur d'avant = repli) ; KB2, KB1 et KM3 l'ouvrent eux-mêmes. Tests de KB1 et KM3 mis à jour (plus de date du 23/11) ; versions 7.2.1.
- **Cible émulateur** `integration_test/koach_kb2_test.dart` (a sombre rouge, b clair violet ; horloge de l'application placée, après le lancement, au lundi de la semaine de prise de main : le 19/10/2026 cette semaine) : sauvegarde synthétique de même forme (programme PR2, 34 séances au journal, 788 séries) laissée par dev7.2.0 → lancement de dev7.2.1 : prise de main, J1 ouvert tout de suite (écran d'attente), séance servie par Koach, journal identique, squat d'endurance à 70 kg servi le samedi, arrêt d'urgence puis réactivation, inspecteur. **Verte dans les deux parties à chacun de ses cinq passages dans sa version finale** (run 39168949687 essais 1 à 3, run 39190303462 essais 1 et 2 ; au passage d'avant, run 39163928246, la sauvegarde synthétique n'avait pas les références du programme et la ligne à 70 kg n'était pas trouvée : code de test corrigé) : S1 affichée, prise de main en S15, J1 servi (6 exercices), squat d'endurance servi à 70 kg (9 répétitions écrites), arrêt d'urgence puis réactivation, critère 10 à l'inspecteur, journal identique, aucun état de Koach écrit pendant la prise de main.
- Cibles émulateur des lots d'avant : jouées bascule fermée (une ligne `debugKoachBasculeAutorisee = false` en tête, code de test seulement), comme à leur lot. **Cible KM3 corrigée (code de test seulement)** : sa garde de temps finale prenait `replanification ?? prise_de_main` sous 10 s ; un lundi réel (19/10), aucun rattrapage n'a lieu et la règle retombait sur la prise de main forcée (15 à 18 s sur l'émulateur, déjà au-dessus de 10 s en KB1) : rouge sans lien avec KB2, et dépendant du jour. Garde désormais sur la replanification seule, à 30 s (le budget de 10 s est tenu sur la VM Dart, critère 11 ; le runner varie de 2 à 3 fois d'un passage à l'autre : 21 s mesurées une fois). Toutes vertes au contrôle final (run 39190303462 : KB1, KS1A, KM3, BV11, CIF, CI1g, CI1f, CI1e, CI1c, CI1, CU, G10 à G1, M8, M7).
- Contrôles : formatage (lib, test, integration_test), analyse, **1 112 tests Dart** (51 sautés comme avant), mode dev, Python (163), quatre paquets, rendus de test, builds debug et profile : verts (run 39190303462). Les échecs rencontrés en route : cible KM3 (garde de temps dépendante du jour, corrigée ci-dessus) et pannes du pilote de l'émulateur (service VM injoignable, aucun test lancé), aucune dans le code de l'application.

## 6. Relecture indépendante

Sous-agent Opus sur le diff complet : logique de semaine vérifiée (bornes `firstShown` / premier bloc, journées vides, séance faite, date forcée, rattrapage de la semaine de prise de main). Constats corrigés : import d'un fichier `part` et imports inutiles dans le test, choix de la ligne à charge fixe (une ligne à 0 kg existe en J6), fermeture de l'écran d'attente si une page s'ouvre par-dessus (`removeRoute`), **séance commencée avec le moteur d'avant** (désormais gardée, test ajouté), comparaison fragile du journal, date du lundi sur la carte. Remarques gardées : la date d'ouverture ne borne jamais plus que la semaine du jour (gardée, documentée) ; l'attente n'est montrée qu'une fois par lancement.

## 7. Limites

- Critère 10 non tenu (§ 1) : Koach conduit par dérogation ; garde-fous de C17.34.2 en place (suggestions validées d'un tap, charge fixe, conduite sous douleur, arrêt d'urgence).
- Prise de main : opération unique de 8 à 29 s (médiane 13 s) sur l'émulateur de la CI (§ 4) ; temps réel à lire sur le téléphone (inspecteur › Temps de calcul).
- Code 0.x encore dans l'APK : son retrait est un lot après une semaine servie par Koach sans incident (C17.32.5, `kalis_adapt` 1.1.0).
- `koachTakeoverPlanned` prend la première semaine non faite à partir de la semaine du jour : une séance non faite d'une semaine passée n'est jamais reprise (voulu).

## 8. Recommandation au pilotage

Valider dev7.2.1 et la transmettre tout de suite au propriétaire (jalon : sa séance du lundi 19/10). Garder la re-mesure du critère 10 vers le 09/11 (C17.34.3) et le lot de retrait du code 0.x après une semaine servie sans incident. Au prochain lot qui touche la CI : la cible KM3 et ses sœurs mesurent des temps sur un émulateur logiciel dont la vitesse varie de 2 à 3 fois d'un passage à l'autre ; ces gardes devraient rester des relevés (la règle de 10 s est tenue sur la VM Dart).

## 9. À tester (propriétaire)

1. Installer dev7.2.1 **avant la séance de lundi** si possible (sinon : Koach prend la suite de la semaine).
2. Ouvrir l'application : la première séance ouverte peut attendre quelques secondes (« Koach prend la main sur ton programme »), une seule fois.
3. Vérifier que la séance du jour est servie par Koach (charges et cibles par série ; squat d'endurance à 70 kg tel qu'écrit).
4. Noter les flammes à chaque série, au plus juste : c'est ce qui recale Koach (re-mesure vers le 09/11).
5. Au moindre doute : Réglages › Séance › Koach 1.0 › **Arrêt d'urgence** (séances servies telles qu'écrites, rien perdu, réactivable).
