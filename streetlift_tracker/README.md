# Kalis Track 3.0.0 — Koach, ajustement des charges sur le téléphone

## 3.0.0 — Koach (lot L7)

**Koach** (Kalis Coach) suit tes séries du programme de 40 semaines et te propose des ajustements de charge. Il est **désactivé par défaut** : active-le dans Réglages → Koach (une explication s'affiche d'abord). Désactivé, l'application fonctionne exactement comme en 2.5.9.

- **Difficulté de la série** : six niveaux, d'« Échec » à « Facile », chacun avec « encore N » (répétitions encore possibles). Koach actif, elle est demandée sur la première et la dernière série des quatre mouvements principaux (muscle-up, traction, dip lestés, back squat) : un tap choisit et valide. Mode avancé : RIR ou RPE dans la colonne habituelle. Sous chaque série validée, la difficulté notée reste modifiable, et une série peut être **écartée** (incident) : elle reste au journal, XP comprise, sans compter dans les estimations.
- **Pendant la séance** : après la série 1, si elle était plus facile ou plus dure que le RIR visé, Koach propose la charge des séries restantes, avec la raison en une ligne (« +2,5 kg — série 1 à Soutenu, visé Dur ») : « Appliquer » ou « Garder ma charge ». Jamais de hausse en semaine de décharge, avec une douleur notée au-dessus de 3/10 ou un jour de fatigue accepté.
- **Jour de fatigue** : si la série 1 est nettement sous ton niveau habituel (ou sommeil court, forme basse), Koach propose de réduire le volume restant de 15 à 30 %, charges maintenues.
- **Fin de séance** : bilan Koach avant le bilan de récompenses. Les valeurs de la feuille Pilotage (1RM, maxima, charges des accessoires) ne changent **jamais sans ton accord** : chaque proposition s'accepte ou se refuse d'un tap, avec sa raison ; une valeur peut être verrouillée (« Garder ma valeur »).
- **STATS › Performances → Koach** : 1RM estimés avec leur incertitude, courbe, projection vers ton étape (cible 12 mois du programme) et ton objectif final (à saisir), statut écrit (« dans les temps », « en retard »…), maxima d'endurance, historique daté des valeurs, pesées.
- **Pesées datées** : ton poids du jour sert au calcul des mouvements lestés ; rappel sur l'accueil après 7 jours sans pesée.
- **Matériel** : incréments de tes haltères, disques, barre, poulies (en livres) et machines, modifiables ; les charges suivent ta grille.
- **Options** : questionnaires facultatifs (sommeil, forme, douleur), après une information claire, supprimables à tout moment ; « Koach adapte la structure » (désactivé par défaut) : ±1 série par mouvement ou décharge anticipée pour la semaine suivante, annulable.
- **Tes données** : tout est calculé et conservé sur ton téléphone, sans compte ni connexion. Les données Koach sont dans l'export de sauvegarde et effacées avec les données de l'application. Mise à jour depuis 2.5.x : rien n'est réécrit, Koach reste désactivé jusqu'à ce que tu l'actives.

Koach produit des **estimations d'entraînement**, sans garantie de résultat ; ses paramètres restent à éprouver sur le terrain (voir `docs/CONTRAT_L7.md` §11). Détail : `docs/CONTRAT_L7.md`, `docs/CONFIDENTIALITE_KOACH.md`, `SUIVI_PROJET.md` (L7), `LIVRAISON_L7.md`. Tests : `test/l7_*_test.dart`, `tools/tests/test_koach_reference.py`.

## 2.5.9 — Séances fiables et reprise (lot L4b)

- **Séries validées pour de vrai** : une série ne se coche qu'avec une valeur valide (reps, secondes ou minutes ; 0 seulement pour un test max). Charge avec virgule ou point, négative pour une assistance ; RIR et RPE vérifiés chacun sur son échelle. Si quelque chose ne va pas, le champ est nommé sous la série et ta saisie reste. Une série modifiée avec une valeur invalide repasse « non validée ».
- **Suggestion ≠ performance** : les reps et charges pré-remplies, comme un chrono de tenue terminé, ne comptent qu'une fois la série cochée.
- **Reprise** : une séance commencée est marquée « En cours » et proposée dans « À reprendre » sur l'accueil ; elle rouvre sur l'exercice où tu en étais, avec tes séries. Le repos n'est pas relancé.
- **WOD interrompu** (application tuée, arrêt forcé, redémarrage) : la tentative est retrouvée, chrono en pause au dernier temps enregistré ; « Reprendre » ou « Terminer » pour saisir le score. Un essai commencé avant minuit peut toujours être terminé. Un seul WOD chronométré à la fois.
- **Fin de séance** : le bilan ne s'affiche qu'une fois la séance enregistrée ; en cas d'échec, « Réessayer l'enregistrement », sans double gain.
- **Rappels** : toucher un rappel ramène à la séance déjà ouverte au lieu d'en empiler une seconde ; une journée faite ouvre son historique.
- Chronos : un changement d'heure en arrière ne fait plus remonter un repos ; au retour dans l'application, aucune rafale de bips anciens.

Détail : `docs/SEANCES_ET_REPRISE.md`, `SUIVI_PROJET.md` (L4b). Tests : `test/l4b_seances_test.dart`.

## 2.5.8 — Ton départ, tes références (lot L4)

- **Nouvelle installation** : le programme n'est plus calé sur la date du créateur. L'accueil propose « Choisir mon départ » : la date choisie devient ta séance S1 · J1, quel que soit le jour (jusqu'à 280 jours en arrière pour une reprise, jusqu'à un an à l'avance). « Plus tard » est possible ; tant que le départ n'est pas choisi, les semaines restent consultables et aucun rappel n'est envoyé.
- **Références** : aucune valeur n'est inventée. Poids du corps, 1RM et maxima sont « non renseignés » tant que tu ne les saisis pas (« Je ne sais pas » accepté, aucun test maximal exigé) ; les charges et volumes concernés affichent « à renseigner », les attributs « indisponible » ou « calcul partiel ».
- **Installation existante** : rien ne bouge. Ton calendrier (départ du 13/07/2026), ta semaine en cours, tes séances et leurs dates, tes crédits, tes WODs et tes résultats sont conservés ; tes références restent utilisées, marquées « à vérifier » (« C'est bien ma valeur » quand tu veux).
- **Changer de départ** : Réglages → Programme → Départ du programme, avec l'effet affiché avant de confirmer (« S11 · J6 → S1 · J6 ») ; les séances faites gardent leur semaine, leur jour et leur date réelle ; les rappels sont replanifiés.
- **Fin du programme** : après S40 · J7, « Programme terminé » ; aucun nouveau cycle.
- Sauvegardes : le départ et la provenance des références sont exportés et restaurés ; une ancienne sauvegarde garde le calendrier du 13/07/2026.

Détail : `docs/DEPART_PROGRAMME.md`, `SUIVI_PROJET.md` (L4). Tests : `test/l4_depart_test.dart`.

## 2.5.7 — Bloc 2 (S12-S19) révisé (lot LC1)

Contenu d'entraînement des semaines 12 à 19 révisé selon tes décisions du 26/09/2026 ; le reste du programme et la feuille Pilotage ne changent pas.

- **Sans capteur de vitesse** : tempo « Intention maximale » sur muscle-up, traction, dip et squat lestés ; la série s'arrête quand une rep ralentit nettement ou que la marge passe sous le RIR visé.
- **Séries classiques** en S12, S13, S15 et S19 ; clusters en S14, S16, S17 et S18.
- **Série de calibrage** (série 1) sur les 4 mouvements principaux, avec la règle d'ajustement de charge et du 1RM ; décharges S15 et S19 : aucune hausse.
- **Séances resserrées** : 6 lignes par jour au lieu de 9 à 11 (202 lignes retirées, 66 ajoutées). Nouveautés : squat pause 2 s, GtG muscle-up enregistrable en J3 et J5, muscle-ups PdC explosifs en J6, séries de référence d'endurance (0,6 × ton max) suivies des clusters du reste du volume.
- **S12 = semaine de recalage** : tests max tractions (J4), dips puis pompes (J5), squat 70 kg (J6), en tête de séance. Reporte chaque résultat dans la feuille Pilotage **sans quitter la séance** : menu ⋮ → « Références (feuille Pilotage) ». En revenant, les volumes des lignes suivantes sont déjà recalculés (les reps pré-remplies non validées suivent ; ce que tu as saisi n'est pas écrasé).

Détail : `SUIVI_PROJET.md` (LC1). Tests : `test/lc1_programme_test.dart`, `tools/tests/test_lc1_revision.py`.

## 2.5.6 — Formats WOD fiables (lot L3b)

- **Tabata de bout en bout.** Les 40 Tabata du catalogue ont un vrai déroulement : 8 efforts de 20 s séparés par 10 s de repos, 1 min entre deux mouvements, fin au dernier effort (3 mouvements : 13 min 30 s ; 4 : 18 min 20 s). L'écran nomme la phase en toutes lettres (« EFFORT », « REPOS », « REPOS ENTRE MOUVEMENTS »), le mouvement et l'intervalle ; pause et reprise figent la phase ; pas de rafale de bips au retour dans l'application.
- **Score Tabata conforme à la consigne.** Tu saisis tes reps de chaque intervalle ; l'application prend le plus faible de chaque mouvement (0 compte) et additionne ces minimums. Case vide = non renseignée, jamais zéro ; un Tabata incomplet reste dans l'historique sans devenir un record.
- **Une règle de score par format, affichée.** For Time et rounds : temps le plus court, et tu indiques toi-même si le WOD est terminé (un arrêt rapide ne devient plus un record) ; au-delà du time cap, résultat incomplet. AMRAP : rounds + reps. EMOM : minutes tenues sur N (plus de valeur pré-remplie). Death by : dernière minute réussie. E5MOM tractions : total de tractions. AMRAP en blocs : total des rounds, avec un chrono par blocs. Routines sans règle écrite : temps noté, sans record.
- **Anciens résultats intacts.** Rien n'est converti ni supprimé ; un ancien temps de Tabata ou un ancien score d'EMOM reste dans l'historique avec son explication, sans être comparé aux nouveaux. L'XP déjà gagnée ne bouge pas.

Contrats détaillés : `docs/WOD_FORMATS.md`. Tests : `test/l3b_formats_test.dart`.

## 2.5.5 — Essai du jour, vitrine et crédits fiabilisés (lot L3)

- **Essai commencé avant minuit : il se termine.** Un essai lancé à 23 h 59 peut être fini et son score enregistré après minuit. Le droit vaut pour cette tentative seulement : quitter l’écran l’abandonne, et le WOD ne devient pas acquis. Un score n’est enregistré qu’une fois, même en appuyant deux fois ou en réessayant après une erreur d’écriture ; la récompense n’apparaît qu’une fois le score sauvegardé.
- **Un seul essai par jour, qui ne change plus.** L’essai du jour est fixé à la première ouverture de la journée et enregistré (il fait partie de la sauvegarde). Tentatives illimitées jusqu’à minuit. L’acheter le rend acquis tout de suite, sans faire apparaître un autre essai gratuit. Toujours un WOD jamais tenté : au niveau ±1, sinon ±2, sinon dans tout le catalogue ; s’il n’en reste aucun, pas d’essai ce jour-là (message dans la boutique).
- **Vitrine fixée pour la semaine.** Choisie le premier affichage de la semaine et enregistrée ; seul un WOD acheté laisse sa place au suivant. Reculer l’horloge ne refait ni l’essai ni la vitrine.
- **Crédits : chaque gain payé une fois.** Chaque gain (palier de niveau, chapitre, boss, semaine complète) est inscrit dans un registre sauvegardé. Corriger ou supprimer une activité ne retire rien ; la refaire ne repaie rien ; une vraie nouvelle semaine complète rapporte bien son crédit. Les prix payés et les WODs acquis ne changent jamais.
- **Déficit affiché.** Si une ancienne sauvegarde dépense plus qu’elle n’a gagné, le solde indique « déficit de N crédits » au lieu de 0 ; les achats attendent de nouveaux gains, les WODs acquis restent acquis.
- **Anciennes sauvegardes.** Registre reconstruit depuis le journal, surplus L2 conservé ; aucun crédit créé ni retiré. L’import reste un remplacement complet.

Contrat détaillé : `docs/CONTRAT_L3.md`. Tests : `test/l3_economy_test.dart`.

## 2.5.4 — Sauvegarde Android : choix explicite

Choix retenu : la **sauvegarde Android par défaut** est conservée et désormais déclarée (`android:allowBackup="true"`, sans règle de filtrage). Si la sauvegarde Google est activée sur le téléphone, Android peut copier les données de l’application et les restaurer à la réinstallation ; le transfert vers un nouveau téléphone les inclut. Le comportement ne change pas ; il est maintenant contrôlé à chaque build sur le manifeste final (aucune dépendance ne peut le modifier en silence). L’export par fichier reste la copie que tu contrôles.


## Nouveautés 2.5.3 — tes données sous ton contrôle (lot L2b)

Dans **Réglages → Sauvegardes** :

- **Exporter une sauvegarde** : le sélecteur de fichiers d’Android s’ouvre, tu choisis l’emplacement (téléphone, carte, Drive…). Nom proposé : `kalis-track-sauvegarde-AAAA-MM-JJ-HHMM.json`, sans nom ni donnée sportive. Aucun fichier existant n’est écrasé (Android ajoute un numéro). Le succès n’est annoncé qu’après écriture **et relecture identique** du fichier ; annulation, accès refusé, emplacement indisponible ou écriture incomplète sont signalés (un fichier incomplet est supprimé). Le fichier est du JSON **non chiffré** : garde-le en lieu sûr.
- **Importer une sauvegarde** : choisis un fichier ; il est lu dans les limites de L2 (8 Mio), validé, puis un **aperçu** montre ce qu’il contient réellement (format, date d’export si le fichier l’indique, séances, résultats, WODs débloqués, niveau calculé) face à tes données actuelles. Rien ne change avant ta confirmation. Par défaut, tes données actuelles sont d’abord exportées dans un fichier ; si cet export est annulé ou échoue, l’import n’a pas lieu. « Remplacer sans sauvegarde » est un choix explicite. Si tes données changent pendant l’aperçu, une nouvelle confirmation est demandée.
- **Copier / Coller une sauvegarde** : le presse-papiers reste disponible et passe par le même aperçu.
- **Sauvegarde Android** : explication du comportement réel (l’application ne désactive pas la sauvegarde du système, qu’elle ne peut ni déclencher ni vérifier).
- **Zone sensible → Supprimer les données de l’application** : liste précise de ce qui est supprimé et de ce qui ne l’est pas, export préalable proposé, confirmation en tapant `SUPPRIMER`. L’application revient à son état d’installation (journal, séances perso, références, résultats, crédits, WODs débloqués, envies, réglages, copies internes, anciennes clés de migration, rappels) ; le programme et le catalogue restent. Une suppression incomplète est signalée comme telle.

Aucune permission de stockage n’est ajoutée : le sélecteur système donne accès au seul fichier choisi. Tests : `test/l2b_data_control_test.dart`.


## Correctifs 2.5.2 — sauvegarde et achats (lot L2)

- **Achat confirmé seulement une fois enregistré.** Le bouton passe en « Achat en cours… », le prix est réservé sur le solde, puis le déblocage (révélation, message) n’est annoncé qu’après l’écriture acceptée. Écriture refusée : message explicite, aucun crédit débité, WOD toujours verrouillé, nouvelle tentative possible. Double appui : un seul débit. Deux achats rapprochés : jamais au-delà du solde. Prix changé entre l’affichage et l’appui : rien n’est débité.
- **Une seule file d’écritures.** Sauvegardes ordinaires, achats et imports passent dans le même ordre ; chaque écriture encode l’état au moment où elle s’exécute : un état ancien ne peut plus être écrit après un plus récent. Après une erreur, les modifications restent en mémoire, l’alerte propose **Réessayer**.
- **Import plus sûr.** Validation complète avant tout changement ; l’état courant est d’abord gardé en copie de secours (les trois dernières sont conservées) ; import appliqué seulement après son écriture. Messages distincts : sauvegarde invalide, trop volumineuse, écriture refusée.
- **Imports bornés.** Texte ≤ 8 Mio de caractères, JSON décompressé ≤ 32 Mio (contrôlé pendant la décompression), ≤ 2 millions de valeurs, textes ≤ 100 000 caractères, ≤ 20 000 séances, ≤ 500 000 séries, ≤ 100 000 résultats de WOD, ≤ 20 000 entrées par autre collection. Une sauvegarde représentative (40 semaines entièrement saisies, 60 séances perso, 300 résultats) pèse 1 037 555 octets de JSON et 49 183 caractères compactée.
- **Crédits gagnés jamais repris.** Corriger ou supprimer une séance, un score ou une semaine fait varier l’XP et le niveau, mais plus le total de crédits gagnés : l’application retient le plus haut total atteint (`creditsEarnedMax`, exporté avec la sauvegarde). Refaire une performance supprimée ne redonne rien tant que ce plus haut n’est pas dépassé. Au premier lancement, ce plus haut part du calcul actuel : aucun crédit créé ni retiré. *Remplacé en 2.5.5 par le registre des gains.*
- **Droits WOD anciens.** Les accès « coût 0 » de l’ancienne migration ne sont plus effacés. Un WOD déjà joué (au moins un résultat) reste acquis, gratuitement ; les autres sont archivés à part (`legacyGrants`), sans accès, pour ne pas rendre tout le catalogue gratuit. Même règle pour un import au format 1 ou 2 ; un droit à coût 0 d’une sauvegarde format 3 reste acquis.

Tests : `test/l2_persistence_test.dart`, `test/l2_purchase_ui_test.dart`, jeux de données `test/l2_fixtures.dart`.


## Nouveauté 2.5.1 — corriger ou supprimer une séance terminée

Une séance validée par erreur ou avec une valeur fausse n’est plus figée. Depuis son historique (accueil sur une journée faite, ou STATS → Historique), le menu **⋮** propose :

- **Corriger les saisies** (aussi sur la page **Bilan** de l’historique) : la séance repasse en cours avec toutes ses séries, charges, notes et coches, dans l’écran d’exécution habituel. Son XP de séance est retiré le temps de la correction puis rendu quand tu la termines de nouveau. **Sa date d’origine est conservée** : semaine, série de jours et historique ne se déplacent pas au jour de la retouche.
- **Supprimer de l’historique** : efface séries, notes et statut « fait » après confirmation. L’XP et les bonus de la séance sont retirés ; les WODs déjà débloqués restent acquis. Le message qui suit propose **Annuler** et restaure la séance à l’identique, sans jamais écraser une séance recommencée entre-temps.

Les archives de séances perso répétées et les séances perso supprimées ne peuvent pas être rouvertes (leur modèle a pu changer) : seule la suppression est proposée. Tests : `test/history_correction_test.dart`.


Le suivi, le pilotage et la progression sont réunis dans **STATS**. La navigation principale compte quatre onglets : **ARSENAL · STATS · PROGRAMME · RÉGLAGES**.

## Nouveautés 2.5.0 — le WOD Store, façon boutique de jeu

Le catalogue devient une vitrine, sans rien de ce qui agace dans les boutiques de jeux : pas de tirage payant, pas de faux compte à rebours, rien qui se retire. Tout repose sur des sélections déterministes (la date et ton journal) et sur des crédits gagnés à l'entraînement.

- **Crédits plus généreux, jamais repris.** 3 crédits offerts au niveau 1, +2 par niveau, +3 de plus tous les 5 niveaux ; +3 par chapitre bouclé, +5 par boss vaincu, +1 par semaine complète (trois entraînements). Tout solde existant est recalculé à la hausse au premier lancement. Les prix ne bougent pas : 1 à 4 crédits selon le palier (Standard 1-3, Avancé 4-6, Élite 7-8, Légende 9-10).
- **À l'affiche : l'essai du jour.** Un WOD verrouillé, hors vitrine, à ton niveau (±1) et jamais tenté, jouable gratuitement jusqu'à minuit. Le score et l'XP restent ; terminé, il coûte 1 crédit de moins. Un seul essai par jour : le terminer n'en fait pas apparaître un autre.
- **Vitrine de la semaine.** Trois WODs de formats différents à −1 crédit, du lundi au dimanche, autour de ton niveau (jusqu'à deux crans au-dessus). Un WOD acheté laisse sa place au suivant ; le prix payé est figé à l'achat.
- **À ta mesure.** Huit WODs verrouillés autour de ton niveau, renouvelés chaque jour.
- **Liste d'envies et prochain objectif.** Un cœur sur chaque fiche (et dans le menu des tuiles). Le WOD souhaité le moins cher s'affiche en tête de boutique avec sa jauge de crédits : « Plus que 1 crédit · niveau 8 dans 120 XP (+2 crédits) ». La liste est sauvegardée et exportée avec le reste.
- **Couvertures procédurales.** Chaque WOD a une couverture dessinée à la volée : un motif par famille (lignes de vitesse For Time, anneaux AMRAP, cadran EMOM, tours empilés, barreaux d'échelle, escalier de chipper, blocs Tabata, rampe Death by), une intensité par palier, des chevrons de palier toujours doublés d'un libellé.
- **Fiche façon page produit.** Couverture, accroche, mouvements, « pourquoi ça compte » (cible musculaire, qualité travaillée), volume et durée, muscles, ton record. Le déblocage joue un reflet sur la couverture, avec un retour haptique, sans écran modal ; « Réduire les animations » affiche directement l'état final.
- **Arsenal.** Les tuiles de WOD portent leur couverture, leur palier et leur état (possédé et record, essai offert, prix remisé barré, « plus que 1 crédit », cadenas) ; la bannière de crédits annonce le prochain objectif ou l'essai du jour.
- **Règles à portée de main.** « Gagner » dans la carte de crédits ouvre le détail des gains ; les textes de campagne (chapitres, boss) suivent le nouveau barème.

Tests ajoutés : `test/wod_store_test.dart` (paliers et plancher de prix, essai du jour stable et remise après essai, vitrine hebdomadaire déterministe, sélection « à ta mesure », achat au prix figé, liste d'envies persistée et exportée, vitrine du catalogue puis recherche, essai lancé sans achat, achat avec révélation, rendu 320 px / 130 %). Barème mis à jour dans `progression_test` et `game_test`.

## Correctifs 2.4.1 — récompenses et niveau

Deux anomalies signalées après une séance terminée.

- **L’écran de récompenses ne s’affichait pas toujours.** Il n’était déclenché que par l’écran qui avait ouvert la séance, au retour ; une séance ouverte depuis la **notification de rappel** ne le montrait jamais, et le bilan restait en attente jusqu’à un moment sans rapport (fermeture d’un historique, séance suivante). Désormais la page **Bilan de séance** affiche elle-même le bilan dès qu’elle referme la séance, quel que soit le point d’entrée (accueil, Arsenal, rappel). Le rappel ouvre en outre l’historique si la journée est déjà faite, comme l’accueil.
- **Le décompte partait pendant la fermeture de la séance.** Destruction de l’écran, sauvegarde complète et reconstruction des onglets tombaient au milieu des 1,1 s de comptage : sur un téléphone chargé, le compteur sautait à sa valeur finale ou semblait ne pas démarrer. L’écran repose maintenant sur une chronologie unique (`AnimationController`) qui ne démarre qu’une fois l’écran entièrement affiché **et** la séance refermée, une image plus tard. Le compteur part toujours de +0 XP ; « Réduire les animations » affiche directement l’état final. La sauvegarde compare le catalogue à ses définitions d’origine sans les réencoder à chaque écriture.
- **Le niveau, la jauge et les crédits ne se mettaient pas à jour** après un passage de niveau tant que l’application n’était pas relancée. La pastille de niveau de l’accueil, le solde de crédits de l’Arsenal et les cartes de l’Aperçu (objectif, série, quête, campagne, boss, saison, comparaison) étaient instanciés en `const` sans écouter le store : Flutter retrouve la même instance et ne les reconstruit jamais. Ces widgets étendent désormais `StoreWidget` (`lib/store_widget.dart`), dont l’élément s’abonne au store et se reconstruit à chaque notification, où qu’il soit placé. La couche jeu (`store.game`) est en outre recalculée dès que la progression l’est, y compris après minuit.

Tests ajoutés : `test/reward_flow_test.dart` (pastille, crédits, carte hebdo et sonde `StoreWidget` qui suivent un passage de niveau puis se désabonnent ; bilan affiché après une séance ouverte sans vérification au retour, décompte lancé après la fermeture de la séance ; ouverture par rappel ; décompte de zéro au gain complet ; état final immédiat avec « Réduire les animations »).

## Nouveautés 2.4.0 — la couche « jeu »

Douze mécaniques issues d’une revue des preuves sur la gamification de l’activité physique (méta-analyses 2022-2025 : effet réel mais modeste, porté par le feedback, les objectifs adaptatifs et les séries avec pardon ; classements globaux et séries punitives écartés). Le barème d’XP est **inchangé** ; tout ce qui suit se recalcule depuis le journal, comme les XP, et une sauvegarde réimportée redonne le même état.

- **Écran de récompenses** après une séance validée ou un score de WOD (`lib/rewards.dart`) : compteur d’XP qui défile, jauge qui se remplit et passe le niveau, bonus affichés un à un (badge avec sa rareté, défi, semaine validée, record, objectif de séance, crédits), cérémonie de niveau avec insigne, confettis et retour haptique ; « Promotion » quand le rang change. Une seule passe d’animations ; « Réduire les animations » rend tout immédiat ; le réglage **Célébrations** le remplace par une confirmation discrète.
- **Records en direct** pendant la séance : une série validée qui bat le meilleur 1RM estimé (Epley) ou le maximum de reps au poids de corps de cet exercice déclenche une bannière « RECORD » et une vibration.
- **Feuille de personnage** (STATS → Aperçu) : insigne de rang dessiné (chevrons puis étoiles, anneau de prestige au-delà de Légende), titre affiché, niveau, jauge, quatre attributs 0-100 avec niveau 1-10 et radar : **Force** (lest relatif au poids de corps sur tractions, dips, muscle-up, squat, depuis les références Pilotage), **Endurance** (maxima de reps + WODs terminés), **Technique** (familles de skills travaillées, niveau au muscle-up, formats de WOD), **Régularité** (série, semaines actives).
- **Objectif hebdomadaire adaptatif** : moyenne des quatre dernières semaines + 1 jour, entre 2 et les journées prévues au programme, remplaçable dans Réglages ou d’un appui (2 à 6 jours, 0 = adaptatif). Sans XP : un cap personnel. **Objectif de séance** : part de séries à valider (moyenne des trois dernières + 5 points, entre 75 et 100 %), affiché sur le bilan et dans la quête principale.
- **Série avec boucliers** : deux jours actifs valident toujours la semaine ; un bouclier couvre une semaine manquée, gagné toutes les trois semaines validées d’affilée (deux en réserve), consommé automatiquement. La semaine en cours ne casse jamais la série ; les deloads du programme sont présentés comme faisant partie du plan.
- **Quêtes** : quête principale = prochaine journée du programme avec son objectif ; défis hebdomadaires existants présentés comme quêtes (bonus XP inchangés) ; quêtes de saison à titres : « Touche-à-tout » (trois formats de WOD dans la saison) et « Gardien du repos » (chaque deload de la saison honoré).
- **Badges à rareté** : Commun, Rare, Épique, Légendaire selon le bonus, affichés dans l’arbre et la fiche ; les légendaires donnent un titre.
- **Campagne** : un chapitre par bloc du programme (Prologue · Tests, Chapitre 1 · Hypertrophie… Chapitre 5 · Peaking) avec progression, bouclé à 75 % des journées d’entraînement → titre + 1 crédit WOD.
- **Boss** : les semaines de tests (S1-2, S25, S31, S39-40) sont des boss ; vaincus quand tous leurs tests sont validés → titre + 1 crédit WOD ; rappel du deload qui précède.
- **Saisons** : quatre saisons de dix semaines calées sur le programme, titre à 70 % ; rien n’est remis à zéro. **Prestige** : au-delà du niveau 60, une étoile par tranche de dix niveaux.
- **Toi contre toi-même** : semaine en cours contre la précédente (entraînements, séries, jours actifs) et meilleure semaine. Aucun classement ni comparaison à d’autres : l’application est hors ligne, et les preuves défavorisent les classements globaux.
- **Titres** : gagnés par chapitres, boss, saisons, quêtes et badges légendaires ; le titre choisi s’affiche sur la feuille de personnage à la place du rang.
- **Économie** : crédits gagnés = barème par niveau (inchangé) + crédits dérivés de la campagne et des boss ; les WODs déjà débloqués restent acquis.

Nouveaux fichiers : `lib/game.dart` (modèle dérivé, testé dans `test/game_test.dart`), `lib/game_widgets.dart` (insigne, radar, cartes), `lib/rewards.dart` (écran de récompenses). Réglages : **Célébrations** et **Objectif de jours actifs par semaine**.

## Nouveautés 2.3.0

- **1 000 WODs au catalogue** (500 auparavant) : la sélection et la première série générée (`gen0`…`gen448`) sont conservées à l’identique, achats et résultats compris. La deuxième série (`genx0`…) ajoute 500 WODs en douze familles : couplet + distance, triplet, chipper décroissant, échelles 21-15-9 / 15-12-9 / 10-8-6-4-2, échelles montantes 1 → 10, AMRAP, 3 × AMRAP avec repos, EMOM en rotation, EMOM par blocs de 5 min, force lestée puis metcon, Tabata par mouvement et Death by. Noms descriptifs (format + mouvements), notes de mise à l’échelle, vocabulaire élargi (chest-to-bar, muscle-ups lestés, HSPU en déficit, pistols lestés, thrusters, 800 m, front lever raises…). Les niveaux 1-10 restent calculés par déciles sur tout le catalogue ; le coût déjà payé d’un WOD débloqué ne change pas.
- **Quinze modes d’exécution** pour les séances personnelles (huit auparavant) : Classique, Myo-reps, Cluster, EMOM, AMRAP, Isométrie, Intervalles, Pyramide, plus **Tabata** (8 × 20 / 10 s, chrono d’intervalles), **Death by** (reps croissantes à chaque minute, chrono EMOM), **Séries au max**, **Tenues au max** (saisie chronométrée), **Tempo** (cadence 3-1-1-0 affichée dans la séance), **Drop set** (paliers loggés séparément) et **Densité** (chrono AMRAP, séries de N reps). Chaque mode applique ses propres valeurs par défaut au changement de mode.
- **Base d’exercices : 505 entrées** (172 auparavant). Tractions et dips en variantes de prise, tempo, pause, cluster, singles lourds, excentriques lestés ; muscle-ups stricts / kipping / anneaux ; leviers avant et arrière, drapeau, essuie-glaces, L-sit, V-sit, manna ; pompes et HSPU ; haltères, barre, poulies, kettlebell, sac lesté, médecine-ball, box, corde, ergomètres, sangles, battle rope ; jambes, gainage, bras, prévention, mobilité et tests.
- **Recherche tolérante** (`lib/search.dart`), commune au catalogue de WODs et au sélecteur d’exercices : sans distinction d’accents ni de casse, plusieurs termes (tous requis), préfixes (« trac » trouve « tractions »), synonymes français / anglais (traction ↔ pull-up / chin-up, pompe ↔ push-up, fente ↔ lunge, course ↔ run, corde ↔ double-unders, abdos ↔ sit-ups / hollow / toes-to-bar…), formats (amrap, emom, chipper, tabata, death by). Résultats classés par pertinence (titre > format > mouvements > notes).
- **Filtres du catalogue** : puces rapides sous la recherche (Abordables, Poids de corps, For Time, AMRAP, EMOM, Rounds, Routine, < 15 min), nouvelle section **Mouvements** (tractions, dips, muscle-ups, pompes, squats / fentes, burpees, gainage, course, erg, corde, HSPU, kettlebell, box, skills), menu de **tri** (débloqués puis niveau, pertinence, niveau, durée, nom, nouveautés). Le compteur du bouton « Voir N WODs » tient compte de la recherche en cours.
- **Sélecteur d’exercices** : puces par groupe musculaire et par matériel, compteur de résultats, section « Récents » (huit derniers choix de la session), entrée « Créer « … » » conservée, message quand rien ne correspond.
- Champs de recherche sans autocorrection ni suggestions clavier.

## Nouveautés 2.2.4

- Dock de navigation redessiné dans l’esprit One UI : quatre icônes dans une capsule floutée de 64 px, le libellé n’apparaît que sur l’onglet actif, dans une pastille teintée (accent #E85959 en sombre, bordeaux #6B0C0C en clair). L’onglet actif s’élargit en 240 ms, les autres se resserrent ; « Réduire les animations » supprime la transition.
- Les quatre libellés restent présents pour les lecteurs d’écran et les tests ; ceux des onglets inactifs sont repliés, pas retirés. Clés `nav-0` à `nav-3`, sémantique, retour haptique et largeur maximale de 560 px conservés.
- Hauteur réservée sous les onglets ramenée de 100 à 84 px.

## Palette

Bordeaux **#6B0C0C** pour les actions principales et les jauges, rouge **#A61717** pour les états actifs, les records et les alertes de chrono, fonds #121212 / #1E1E1E, textes #F4F4F4 / #8A8A8A, vert #388E3C réservé à la validation. En sombre, les textes et icônes accentués utilisent #E85959. Jauges en dégradé bordeaux → rouge (`KProgressBar`), carte musculaire en rampe bordeaux → rouge. Le mode sombre est choisi par défaut pour une nouvelle installation ; Clair et Système restent disponibles.

## Présentation et fonctions

- Le K historique apparaît seul, sur fond transparent, dans l’en-tête et à l’ouverture : blanc cassé en sombre, bordeaux en clair.
- Transitions courtes en fondu et glissement entre onglets, rubriques STATS, semaines et pages. Les filtres, saisies et positions de lecture sont conservés. Les mouvements respectent « Réduire les animations ».
- Les nouveaux WOD s’acquièrent uniquement dans le catalogue avec les crédits gagnés en progressant. Le prix est affiché avant l’achat ; un achat donne un accès durable, sans nouveau débit à chaque tentative.
- Création, modification et duplication de WOD retirées. Les WOD acquis, anciens WOD personnels et tous leurs résultats restent disponibles. Les séances personnelles restent composables.

## Un suivi clair, avec des paliers motivants

| Rubrique STATS | Contenu |
|---|---|
| Aperçu | Niveau et XP, activité de la semaine, prochain objectif, huit semaines d’activité et totaux |
| Parcours | Arbre de badges : Pratique, Rythme et Défis ; paliers obtenus, prochain objectif, bonus et règles |
| Performances | Force, endurance, références modifiables, avancement du programme, muscles et records WOD |
| Historique | Séances et tentatives WOD, recherche dans les titres et notes, filtres, détails en lecture seule |

Les badges et missions utilisent les séances, séries et résultats déjà enregistrés. Les récompenses restent automatiques. Les règles de régularité autorisent les repos : deux jours actifs suffisent pour valider une semaine.

## Continuité des séances

Programme garde les sept jours dans leur ordre, les gestes du slider et les résumés sur appui long. Les 40 semaines, 280 journées et 1 818 exercices du programme (1 954 avant la révision LC1 du Bloc 2), les quinze modes de séance, charges, séries, notes, RIR/RPE, vitesse, chronos, WOD, XP et sauvegardes gardent leur fonctionnement. Les anciennes séances sans date restent consultables.

Les données des captures sont simulées uniquement dans les tests. L’application livrée n’ajoute aucune activité de démonstration à ton historique.

## Compilation habituelle depuis le ZIP

La procédure courante est [Validation Android L1b](docs/VALIDATION_ANDROID_L1b.md).
Elle décrit les actions GitHub et les essais sur téléphone, dans l’ordre.
Le workflow produit un APK et un AAB avec le même numéro de build, puis contrôle
signatures, identité, manifestes finaux et alignements 16 Ko avant de proposer
les deux artefacts au téléchargement.

Les deux secrets GitHub déjà fonctionnels sont conservés. Le ZIP ne contient
aucune clé privée ni mot de passe. Analyse et tests restent accessibles sans
secrets ; la preuve du refus Gradle sans secrets est prévue dans la nouvelle CI.
Ne pas refaire la préparation de clé décrite dans les consignes historiques L1.

Le propriétaire confirme la mise à jour L1 sans désinstallation et la
conservation de ses données. Cette déclaration est enregistrée dans
`SUIVI_PROJET.md` ; les essais de la nouvelle livraison L1b restent à réaliser.

## Développement et vérification

```sh
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
python3 tools/verify_project.py
python3 -m unittest discover -s tools/tests -v
TZ=Europe/Paris flutter test --no-pub --timeout 90s --reporter expanded
```

Captures reproductibles de l’application :

```sh
flutter test --no-pub --dart-define=KALIS_CAPTURE=true test/visual_capture_test.dart
```

Elles sont écrites dans `validation/2.5.0`. Le test de captures reste désactivé lors de la commande habituelle. Pour charger les polices dans les rendus, définir `FLUTTER_ROOT` sur le SDK utilisé.

`assets/exercises_db.json.gz` (505 exercices) et `assets/programme_v33.json.gz` sont compressés de façon reproductible (`tools/pack_assets.py`, gzip niveau 9, mtime 0). Le masque original du logo est `assets/icon/logo_mask.png` ; `tools/generate_brand.py` régénère ses déclinaisons.

Voir `REFONTE_UI.md` pour la checklist et `AUDIT_2.5.0.md` pour les vérifications et les limites de validation. Les documents antérieurs sont conservés dans `docs` et les audits précédents ; leurs consignes historiques de signature sont remplacées par `docs/SIGNATURE_ET_ZIP.md`. L’état courant et les validations restantes figurent dans `SUIVI_PROJET.md`.

## Archive de livraison sous 25 Mo

```sh
python3 tools/package_release.py ../streetlift_tracker_v33.zip
```

Le paquet conserve le code, les ressources, les tests, le wrapper Gradle, le certificat public de référence (empreinte) et le workflow. Il exclut les clés privées, secrets locaux, caches et APK/AAB ; les copies détectées de secrets dans les contenus font échouer le packaging. Il inclut les captures de la version actuelle, quand elles ont été générées, et les rapports textuels historiques. Les images de validation des anciennes versions sont exclues. Le script refuse de remplacer l’archive si le ZIP ou son contenu extrait dépasse 25 000 000 octets. Relire un ZIP avec `python3 tools/package_release.py --check ../streetlift_tracker_v33.zip`.
