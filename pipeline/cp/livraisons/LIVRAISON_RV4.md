# Livraison RV4 — remplacement libre, retrait du jour, F13, bilan du jour selon le mode (dev7.7.2)

Lot de la voie App du pipeline CP (DECISIONS_CP.md C17.51.5, C17.52.3-4). Base : `main` e5d161a9 (dev7.7.1, RV3). Données synthétiques seulement (C17.33.2) ; aucune clé, aucune donnée réelle. `packages/` intacts à l'octet (aucune limite du moteur rencontrée : Koach reçoit le remplaçant comme une série de cet exercice ; il n'a pas de cible sur la ligne remplacée).

- Publication : `main` bb320350 (avance rapide depuis e5d161a9, un commit, arbre identique au commit contrôlé bea0f77e) ; build signé « Build APK et AAB » run 40060607994 **vert** (APK : artefact kalis-track-apk 12547712095, https://github.com/mikeriin/streetlift-apk/actions/runs/40060607994).
- Contrôle complet `claude/ci-3d` : run 40028120976 (ec9aaa72) : contrôles, analyse, Python, 1 315 tests Dart, mode dev, rendus, paquets, builds **verts** ; émulateur : toutes les cibles vertes sauf RV4 b (appui manqué sur le remplaçant : avertissement de hit test, cible seule corrigée) ; run 40040662996 (bea0f77e, arbre publié ; diffère de ec9aaa72 par `integration_test/rv4_remplacement_test.dart` seul) : mêmes contrôles verts, RV4 a et b **vertes** ; KB5, BV11, CI1g, CI1e à 124 (« Connection refused » à la connexion au VM Service : pertes de la VM, vérifié dans les journaux), vertes au run 40028120976 sur le même `lib/` et les mêmes fichiers de cible. Chaque cible verte dans un essai (règle C17.49.3 / C17.50).
- Contrôle rapide `claude/ci-ui-rv4-rapide` run 40028118001 : formatage, analyse, `test/rv4_jour_test.dart` (15 tests), rendus `test/ui_rv4_capture_test.dart` verts.

## 1. Ce qui change pour le propriétaire

- **Remplacer un exercice pour aujourd'hui** : sur la carte d'un exercice, menu ⋯ › « Remplacer pour aujourd'hui ». En mode **Libre** (Évolution) : les propositions (exercices les plus proches) puis une recherche dans **toute la base** (1 039 exercices, sans accents : « hspu mur » trouve « HSPU au mur dos au mur ») et dans tes exercices personnels. En mode **Assisté** : les propositions seules, et une ligne dit que le choix libre existe en Libre. Le remplaçant garde la place de la ligne : séries, groupe (E2MOM…), format, chrono, repos. « Revenir à « DIP LESTÉ » » annule. Ton programme écrit ne change jamais.
- **Retirer pour aujourd'hui** (même menu) avec une raison : pas de matériel, douleur, manque de temps, autre. La ligne disparaît de la séance du jour ; « Annuler » sur le message ou menu de la séance › « Remettre un exercice retiré » tant que la séance n'est pas finie. Douleur : la page du bilan du jour s'ouvre sur la douleur (conduite habituelle).
- **Bilan du jour selon ton mode** (sous Koach) : en **Libre**, la séance reste celle de l'écrit ; la carte du bilan du jour et les cartes concernées disent « Avec ton bilan du jour, Koach te propose d'ajuster N exercices » avec « Accepter » / « Garder l'écrit ». En **Assisté**, l'ajustement est appliqué et dit, avec « Annuler ». Le choix se fait avant la première série validée ; ensuite il est figé (une ligne le dit). La douleur signalée garde sa conduite dans les deux modes.
- **F13** : la carte 2D des muscles se repeint quand tu changes « Couleurs » (Réglages › Apparence).

## 2. Point 1 — remplacement libre (C17.51.5)

- **Constat** : dans dev7.7.1, il n'existait aucun « Remplacer » **en séance** (seulement à la création du programme, « Je ne sais pas faire » / « Je n'aime pas », et les échanges de l'évolution du programme). RV4 ajoute l'action dans le menu ⋯ de la carte (PR7), pour toute séance (Koach actif, Koach arrêté, moteur d'avant, séance écrite), tant que la ligne n'a aucune série validée et que la séance n'est pas finie.
- **Propositions** : les 6 exercices de la base les plus proches (`Catalog.similarity` de `kalis_core` : muscles, schéma, famille, difficulté ; exercices assistés écartés). Pour le dip lesté : dips lestés (pause, anneaux, chaînes…). C'est ce qui manquait au propriétaire : les HSPU n'en font pas partie, d'où la recherche libre.
- **Libre** : recherche de l'Arsenal (`searchExercises`, sans accents, synonymes) dans toute la base, et « Mes exercices » (exercices personnels). L'écran du sélecteur d'exercice n'avait pas de filtres : pas de filtre ajouté (sans refonte).
- **Emplacement gardé** : la ligne affichée est recréée par-dessus la ligne servie (`withDayChanges`) : même identifiant de ligne écrite (`<ligne>~<exercice>` au journal), mêmes séries (nombre et format « 6×2 · E2MOM »), même groupe et même chrono (`exerciseGroupOf` lit l'emplacement), même repos ; nom « enchaîné » gardé pour une ligne enchaînée. Unité : un remplaçant en secondes sur une ligne en répétitions passe à « 6×30 s · E2MOM » (30 s ou la dernière valeur de l'exercice ; 8 répétitions dans l'autre sens : choix raisonné, la saisie reste libre) ; `logSpec` lit désormais une tenue au départ chronométré (« N×30 s · E2MOM » : tenue, départ toutes les 2 min). Charge : celle de la dernière fois dans le journal ; sinon rien (à saisir), colonne kg ouverte d'emblée pour un exercice chargé (barre, haltères, lest, machine, poulie, kettlebell). Les a priori de Koach ne sont pas utilisés (le prompt laissait « champ vide à remplir »).
- **Koach** : la ligne remplacée n'a plus de cible du moteur (aucune cible du dip appliquée aux HSPU) ; ses séries sont versées sous l'exercice réel (`_adaptDone`, `journalLineOf` : `cd-hspu-mur-dos`, testé). Un exercice personnel n'a pas d'identifiant de la base : il n'est pas versé (comme tout exercice inconnu du journal, `JournalConversionReport.unmappedExerciseNames`). Un exercice de la base sans fiche de Koach est ignoré par le modèle (`piste` absente) sans erreur.
- **Données** : `SessionLog.changes` (nouvelle section facultative de chaque séance, par ligne écrite : `type`, `to`, `name`, `from`, unité, valeur, charge). Une séance qui n'a que des changements du jour n'est plus prise pour une simple consultation (sinon effacée à la fermeture : trouvé et corrigé pendant le lot, testé).

## 3. Point 2 — retrait du jour

- `type: retrait`, raison au choix ; la ligne et son test court éventuel disparaissent de la journée affichée.
- Groupe au chrono : `exerciseGroupOf` recale le groupe sur les lignes restantes par la règle du moteur (`koachGroupesServis`, KB5). Pour l'E2MOM de la J5 (dip lesté + dips explosifs, 6 tours, 720 s), retirer les dips explosifs garde 6 tours et 720 s (durée comptée en tours) : le dip garde son chrono.
- Koach : avant le début, la ligne est exclue des items écrits demandés à `plan(seance)` (Koach sert la séance sans elle, garde comprise) ; après le début, elle n'est simplement plus faite (aucune série versée). Remise après le début d'une ligne retirée avant : servie telle qu'écrite, groupes recalés (`koachRemettreLigne`).
- Douleur : `reportSessionPain` (bilan du jour, section Douleur) ; sans moteur, la page de santé et sécurité.

## 4. Point 3 — F13 (C17.52.3)

Correctif de 2ad2f473 repris à l'identique (`lib/muscle_map_2d.dart` : intensité « Couleurs » dans la clé du cache, dessin abandonné en cas de course A → B → A) et son test F13 (`test/rv3_mineurs_test.dart`). Empreinte de ce seul fichier mise à jour dans `tools/ui_illustrations_empreintes.json` (relevé lu par `tools/check_ui_illustrations.py`, docstring annotée) ; le dessin rendu ne change pas.

## 5. Point 4 — bilan du jour selon le mode sous Koach (C17.52.4)

- **Lecture servie** : en Assisté, `seance_debut` porte le bilan complet ; en Libre (sans « Accepter »), seulement ses faits (temps disponible, douleurs : la conduite sous douleur ne dépend jamais du mode, comme `factsOf` du moteur 0.x).
- **Autre lecture** : au début réel (`koachStart`), l'autre bilan est joué sur une **copie** du moteur (isolat ; `koachSeanceAutreCopie`), même garde ; les lignes que les deux lectures servent différemment (séries, charge de départ, plages) sont gardées dans la séance (`koach.bilan.lignes`). Les lignes au départ chronométré servies telles qu'écrites (PR8) en sont exclues (elles ne changent jamais).
- **Choix** : même mécanique que la modulation de RV3. Même service (« Garder l'écrit » en Libre) : choix noté. Changement de service (« Accepter » en Libre, « Annuler » en Assisté) : possible avant toute série validée ; le journal de Koach est ramené au `seance_debut` de cette séance (seuls ce début, la réponse au diagnostic et les demandes `plan` sont retirés ; sinon refus), le moteur vivant est rejoué, puis la séance redémarre avec l'autre lecture. Un seul `seance_debut` de la séance reste au journal (testé). Séances manquées versées au début restituées.
- **Moteur** : le choix est versé à la fin comme une `decision` (`allegement`, ou `volume_plus` quand le bilan ajoute ; ampleur = nombre de lignes ; `accepte` vrai pour « Accepter ») ; aucun choix : rien.
- **Affichage** : `KoachBilanCard` sur la page du bilan du jour (toutes les lignes) et sur chaque carte concernée (sa ligne), boutons pour toute la séance.
- **Limite** : en Libre sans « Accepter », Koach ne reçoit pas la forme du jour (elle reste dans la séance de l'application) ; si le pilotage veut qu'il l'apprenne même quand l'écrit est servi, il faut un `plan(seance)` qui ignore la forme tout en la versant (lot moteur).

## 6. Tests

- `test/rv4_jour_test.dart` : fonctions pures ; HSPU au mur à la place du dip lesté dans l'E2MOM de la J5 (groupe, format, chrono, séries, colonne kg, programme intact, Koach reçoit `cd-hspu-mur-dos`) ; tenue à la place de répétitions, exercice personnel, retour ; retrait avec groupe avant le début (Koach sans la ligne, remise) ; retrait sans groupe pendant la séance ; Koach arrêté ; passage depuis dev7.7.1, fermeture sans série, export / import à l'identique ; bilan Libre (« Accepter », « Garder l'écrit »), Assisté (« Annuler », figé après la première série), bilan haut ; écran de remplacement (recherche, exercice perso, assisté).
- `test/ui_rv4_capture_test.dart` : écran de remplacement (libre, assisté) et carte du bilan (libre, assisté), sombre bordeaux et clair violet (relus).
- Cible émulateur `integration_test/rv4_remplacement_test.dart` (a = sombre rouge, b = clair violet, mode Libre) : vendredi J5, menu ⋯ du dip lesté, « Remplacer pour aujourd'hui », recherche « hspu mur dos », HSPU au mur ; b : retrait de la barre au front. Inscrite dans `tools/ci3d_drive.sh`.

- Sur la carte remplacée, la note de rôle de la ligne écrite reste affichée (« Mode prudent : … charge limitée à 80 % du 1RM estimé ») : elle vient de l'emplacement, pas de l'exercice ; sans effet sur une ligne au poids du corps.

## 7. Recommandations au pilotage

1. Valider dev7.7.2.
2. Décider si Koach doit apprendre la forme du jour même quand l'écrit est servi (Libre) : lot moteur (§ 5, limite).
3. Propositions de remplacement : proximité de base seulement (pas le matériel du jour) ; un lot moteur pourrait servir les variantes de `kalis_plan` (plus facile, équivalente, autre matériel) en séance.

## 8. À tester (propriétaire)

- Profil en Libre ; vendredi (poussée densité) : menu ⋯ du dip lesté › « Remplacer pour aujourd'hui » › « hspu » › HSPU au mur : même E2MOM, même chrono.
- Menu ⋯ d'un accessoire › « Retirer pour aujourd'hui » › « Pas de matériel » ; menu de la séance › « Remettre un exercice retiré ».
- Bilan du jour bas : en Libre, la séance reste l'écrit, « Accepter » / « Garder l'écrit » ; en Assisté, appliqué, « Annuler ».
