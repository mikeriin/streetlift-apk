# Décisions du propriétaire — pipeline « Génération et progression » (GP)

Source : conversation de pilotage du 30/09/2026 (22:00-23:10, heure de Paris), questionnaire à choix multiples. **Ces décisions font référence. Un lot ne les remet pas en cause** ; s'il rencontre une contradiction qui change le résultat, il s'arrête et notifie (PIPELINE_GP.md §5). Les choix réversibles qu'elles laissent ouverts sont tranchés par le lot et consignés dans la section du lot, en bas de ce fichier.

## D0. Cadre

- D0.1 Le pipeline « Mannequin 3D » est clos (30/09/2026). Base de départ validée : **5.10.1+93**, `main` 601a04d (M8 correction 3).
- D0.2 Priorité : les fonctionnalités principales de création du programme de l'utilisateur. L'application ne vise plus les « streeteux » mais **tout le monde** ; le streetlifting reste accessible par le **mode street**.
- D0.3 Les moteurs sont codés **comme des systèmes indépendants de l'application** (paquets Dart purs, sans Flutter, sans stockage, sans horloge implicite), puis utilisés par l'application. But : les faire évoluer sans toucher aux écrans. Ils sont testés par leurs propres tests et, dans l'application, par le **mode dev** (D2).
- D0.4 Validation : **lots de moteur enchaînés automatiquement** quand leurs contrôles sont verts ; **chaque lot qui change ce qui se voit dans l'application attend le test du propriétaire** sur son téléphone.
- D0.5 Modèles : **Claude Fable 5.1, effort maximal** pour la conception des moteurs (G4, G8, G11) ; **Claude Opus 5.5, effort élevé** pour les écrans, l'intégration et les données.
- D0.6 Ordre : mode dev d'abord, puis nettoyage, base d'exercices, moteur statique, Koach, profil, création du programme, moteur dynamique, séance, évolution, leveling, envie de progresser, partage des données, nettoyage final (tableau §8 de PIPELINE_GP.md). Koach passe avant le profil parce qu'il parle pendant la création du profil.
- D0.7 Suivi : une page claude.ai republiée à chaque lot + une notification courte avec son lien.
- D0.9 **(30/09/2026, 23:30) Nom des versions : « devX.Y.Z »** (ex. dev6.0.0) pour tout ce que produit ce pipeline : libellé affiché dans l'application (Réglages › À propos, en-tête s'il y figure), `versionName` de l'APK, titre du dernier commit poussé sur `main` (donc du run `build-apk.yml`), notifications, page de suivi, livraisons, `ETAT_GP.md`. `pubspec.yaml` garde le format imposé `X.Y.Z+N` (N = versionCode, toujours croissant, pour que l'APK s'installe par-dessus) ; l'AAB destiné au Play Store garde « X.Y.Z ». Les versions des paquets de moteur (`kalis_plan 0.1.0`…) ne changent pas de forme.
- D0.8 Les 11 anciennes tâches planifiées Kalis Track (L8 à L13, L9, L9R, L9b, refonte, pipeline 3D) sont désactivées.

## D1. Ce qui disparaît

- D1.1 **Plus de WOD ni de séances manuelles** : onglet WOD, catalogue, générateur et aperçu de WOD, créateur de séances manuelles (builder), crédits WOD et leurs écrans. **Les données déjà saisies sont supprimées** (choix du propriétaire), après une **sauvegarde complète automatique** exportée dans le stockage de l'application et proposée au partage (filet de sécurité, aucune donnée détruite sans copie).
- D1.2 **Mes progrès et tout L12** (victoires, chaînes de figures, bilans, ton de Koach L12, partage d'image L12) : supprimés.
- D1.3 **Ancien système de progression** (XP, rangs Recrue → Légende, badges, boss, saisons, titres, série avec boucliers, campagne L-lots, objectifs adaptatifs, crédits) : **refonte totale, remise à zéro pour tout le monde, propriétaire compris**. Retiré au lot G12, quand le nouveau le remplace (pas de trou entre les deux).
- D1.4 **Anciens moteurs** : Koach L7 (autorégulation RIR), L11 (adaptation au jour le jour) et générateur L10 (avec `assets/program_models.json`) sont **remplacés entièrement** par les nouveaux moteurs, puis retirés.
- D1.5 **Koach 3D** (M7b, 9 animations) : remplacé partout par les **poses 2D** fournies. Le moteur 3D reste pour la démonstration des exercices.
- D1.6 **Profil L8** : remplacé. Le propriétaire **refait la création de profil** (sans toucher à son programme ni à son historique).

## D2. Mode dev

- D2.1 **5 appuis d'affilée sur le logo** (fenêtre retenue : 2 s entre deux appuis) → une **session de test** démarre comme une installation neuve (premier écran, création du profil, création du programme…). Le logo passe en **rose vif** (#FF1493) tant que la session dev est active.
- D2.2 **Appui long de 3 s** sur le logo rose → la session dev est **supprimée directement** (vibration + Koach « Session de test supprimée »), retour à la session personnelle, intacte.
- D2.3 La session dev est **conservée jusqu'à sa suppression** (fermeture et redémarrage de l'application compris). Ses données sont **totalement séparées** des données personnelles : aucune lecture ni écriture croisée, sauvegardes et exports personnels inchangés.
- D2.4 **Builds de dev seulement** : l'APK construit par GitHub Actions (celui du propriétaire, même signature, installé par-dessus) contient le mode dev ; l'AAB destiné au Play Store ne le contient pas (drapeau de compilation, code du mode dev absent ou inaccessible).
- D2.5 Outils de la session dev : **voyage dans le temps** (avancer les jours), **simulateur de séances** (remplir N semaines avec des flammes simulées selon un profil d'athlète), **inspecteur du moteur** (pourquoi chaque décision : scores, confiance), **export du journal moteur** (JSON). Chaque outil arrive avec le lot qui le rend utile (voir §8).

## D3. Profil et disciplines

- D3.1 Disciplines principales proposées : **les 8 de la base** — Musculation, Street workout, Streetlifting, Calisthénie, CrossFit / WOD (comme discipline d'entraînement du programme, sans l'onglet WOD supprimé), Cardio, Mobilité, **Forme générale**.
- D3.2 **Une principale + 1 à 2 secondaires dosées** (ex. musculation 70 %, mobilité 20 %, cardio 10 %).
- D3.3 **Mode street** (activable à la création du profil) : l'utilisateur choisit **une principale parmi streetlifting, sets & reps, calisthénie**, et **dose les deux autres** en secondaire.
- D3.4 Création du profil **complète, environ 5 minutes**.
- D3.5 Niveau de départ : **déclaration par mouvement (fourchettes)** à la création, puis **calibrage automatique** par le moteur dynamique sur les 2-3 premières séances.
- D3.6 Disponibilités : **jours précis + durée par jour** (ex. lundi 60 min, mercredi 45 min, samedi 90 min).
- D3.7 **Mode assisté ou libre choisi à la création du profil** (expliqué par Koach), modifiable dans les réglages.
- D3.8 Objectifs (refonte complète) : **performance chiffrée avec date** (1RM, répétitions max, figure débloquée, temps de course…), **objectifs d'habitude** (ex. 3 séances par semaine pendant 8 semaines), **objectifs suggérés par Koach** selon le profil et les données, **jalons automatiques + prédiction de la date d'atteinte**.

## D4. Moteur statique (création du programme)

- D4.1 **Refonte à partir de zéro.** Le programme créé ne doit plus ressembler au programme personnel du propriétaire : aucune donnée, aucun modèle ni aucune séance de `programme_v33.json` ne sert de gabarit (test de non-ressemblance obligatoire).
- D4.2 Approche : **optimisation sous contraintes**. Chaque programme candidat est noté (couverture des schémas de mouvement, volume hebdomadaire par muscle selon le niveau, coût en fatigue et récupération, préférences, matériel, lieu, temps par jour, disciplines et dosage) puis optimisé par une **recherche déterministe**.
- D4.3 **Déterministe + « Autre proposition »** : même profil = même programme ; un bouton donne une autre proposition équivalente (nouvelle graine).
- D4.4 **Passe 1** : seulement les exercices par séance, sans séries ni répétitions (ex. « Lundi › muscle-up, tractions, curl, dead hang… »).
- D4.5 **Revue exercice par exercice** : carte « Je sais faire » / « Je ne sais pas faire » / « Je n'aime pas » ; les variantes sont proposées aussitôt : **3 ciblées (plus facile, équivalente, autre matériel) + « Voir tout »**. L'utilisateur peut aussi **ajouter** un exercice qu'il aime ou **en retirer** un.
- D4.6 **Un changement relance la création** : tout ce que l'utilisateur a déjà validé reste **verrouillé**, le reste est ré-optimisé, **Koach montre ce qui a bougé et pourquoi** (diff).
- D4.7 **Passe 2** après validation de la passe 1 : séries, répétitions, RIR visé, repos, charges. Charges de départ **prudentes**, calées en 2-3 séances par le moteur dynamique. La passe 2 est **montrée puis validée** (Koach explique la logique ; l'utilisateur peut ajuster).
- D4.8 Horizon : **blocs glissants de 4 à 6 semaines**, programme sans fin ; chaque bloc est construit à partir du précédent et des données réelles.
- D4.9 **Où j'en suis** : l'utilisateur peut choisir où il en est dans son programme (changement de téléphone, récupération ratée). Les séances antérieures sont marquées **« reprise »** : **neutres** (ni XP, ni statistiques, ni série, ni records, ni données pour les moteurs). **XP et niveau ne bougent pas.**
- D4.10 Base d'exercices : **la base v1.1 du propriétaire** (1 039 exercices, 8 disciplines) remplace le pack 2.0.0, intégrée par le lot G3 (fichier attaché par le propriétaire). Correspondance anciens noms → nouveaux id pour garder l'historique.

## D5. Moteur dynamique (suivi et adaptation)

- D5.1 **Deux moteurs**, chacun son rôle : statique (création) et dynamique (suivi, modification). Le dynamique appelle le statique pour toute restructuration.
- D5.2 Approche : **modèle individuel bayésien** — estimation continue de la force par exercice (filtre de Kalman sur charge × répétitions × flammes), modèle forme/fatigue, forme du jour ; chaque décision porte un niveau de confiance.
- D5.3 **Échelle des 10 flammes (demi-RIR)** : 10 = échec (RIR 0 ou répétition manquée), 9 = RIR 1, 8 = RIR 1,5, 7 = RIR 2, 6 = RIR 2,5, 5 = RIR 3, 4 = RIR 3,5, 3 = RIR 4, 2 = RIR 4,5, 1 = RIR 5 et plus. Icônes : les 10 flammes fournies (`inputs/flammes_difficulte_1_a_10.png`), taille croissante.
- D5.4 Note **obligatoire à chaque série, pré-remplie** avec la cible (un appui pour confirmer, glisser pour corriger).
- D5.5 Couleur des flammes : **dégradé de la couleur dominante** (clair → vif).
- D5.6 **Mode assisté** : **tout** ce que Koach propose est appliqué automatiquement (charges et répétitions, volume, échange d'exercice, restructuration de séance ou de bloc, et toute autre proposition), avec explication et possibilité d'annuler. **Mode libre** : tout est proposé, rien n'est appliqué sans accord.
- D5.7 Rythme de déblocage **standard** : charges et répétitions dès la 1re séance ; volume après 2 semaines ; échange d'exercice après 4 semaines ; restructuration de séance après 1 bloc ; restructuration de bloc après 2 blocs — et seulement quand la confiance du modèle est suffisante.
- D5.8 **Bilan santé en début de séance** : **une question** (« Comment tu te sens ? », 5 niveaux), **détail seulement si la réponse est basse** : sommeil, énergie et humeur, courbatures, douleurs localisées (zone + 0-10), stress, motivation, temps disponible aujourd'hui, alimentation / hydratation. **Tout est facultatif ; une réponse absente n'est pas prise en compte** (aucune valeur par défaut injectée).
- D5.9 Bilan mauvais → **ajustement gradué** (charges, séries ou exercices ; appliqué en assisté, proposé en libre) ; douleur → exercices qui **épargnent la zone**. La règle de santé L13 (douleur > 3/10 plus de 2 séances de suite → renvoi vers un professionnel) est conservée.
- D5.10 Le **programme personnel du propriétaire** (40 semaines, S12 en cours) **reste tel quel** et **passe sous le nouveau moteur dynamique** (flammes, bilan santé, propositions).
- D5.11 Évolution dans le temps : peu de changements au début ; avec les données, propositions jusqu'à la restructuration d'une séance, voire d'un bloc. Le programme **grandit avec l'utilisateur** (humeur, douleurs, performances).

## D6. Koach (mascotte)

- D6.1 Assets : **les 36 poses fournies** (`inputs/koach/`, 3 planches de 12) + les 10 flammes. Vectorisées, nettoyées, découpées une par une.
- D6.2 Couleur : **inversée selon le thème** — corps blanc (yeux et K de la couleur du fond) en thème sombre, corps noir (yeux et K blancs) en thème clair.
- D6.3 **Micro-animations** : respiration, rebond d'entrée, clignement des yeux, transition entre poses ; réduites si « Réduire les animations ».
- D6.4 Koach parle **partout pour le test** (profil et création du programme, propositions, bilan santé et fin de séance, explications contextuelles « pourquoi ») ; **le propriétaire demandera d'enlever là où c'est de trop**.
- D6.5 C'est Koach qui s'adresse à l'utilisateur quand il faut modifier le profil ou expliquer quelque chose.

## D7. Leveling (moteur de progression)

- D7.1 Refonte totale, remise à zéro (D1.3). Moteur indépendant, avancé : niveaux, quêtes, avancements.
- D7.2 XP : **effort réel** (volume × intensité des flammes, plafonné pour ne jamais pousser au surentraînement), **régularité**, **records et jalons d'objectif**, **quêtes**.
- D7.3 **Le niveau ne redescend jamais** (XP acquis à vie).
- D7.4 Courbe : **niveaux 1 à 100 puis prestige**.
- D7.5 Avancement en plus du niveau : **attributs façon RPG** (Force, Endurance, Puissance, Technique, Mobilité, Régularité) qui montent selon les vraies performances ; **rangs par mouvement** (Bronze → Élite) sur **standards par sexe et poids de corps**, publiés et justifiés dans les docs.
- D7.6 Quêtes : **quotidiennes** (1-3 courtes), **hebdomadaires**, **campagne liée au programme** (chapitres = blocs, boss = séances de test), **quêtes Koach personnalisées** (points faibles).
- D7.7 Récompense : pour l'instant des **« Krédits »** (monnaie Kalis Track), gagnés ; leur usage sera défini dans un autre pipeline (aucune boutique ici).
- D7.8 Social (classement, amis, défis) : **plus tard** (pas de serveur).

## D8. Envie de progresser

- D8.1 **Tout implémenter** ; le propriétaire teste et dira quoi garder ou supprimer : célébration de record (Koach, vibration, son, flamme géante), récompenses surprises (coffres de Krédits à taux variable), série de semaines (flamme qui grandit), course contre son fantôme (perf passée en direct), note de séance S/A/B/C + combo, récap hebdo façon story, comparaisons dans le temps (1 mois / 3 mois / 1 an), prédictions de date.
- D8.2 **Sons + vibrations**, désactivables séparément.
- D8.3 Chaque fonction a son interrupteur (réglages), pour que le propriétaire puisse en couper une sans lot de code.

## D9. Partage des données

- D9.1 Réglages › **« Partager mes données d'évolution »** : **export manuel, opt-in** (désactivé par défaut), fichier envoyé par le menu de partage Android.
- D9.2 **Pseudonymisé** : identifiant aléatoire, âge par tranche, dates relatives (J+n), aucun nom ni note libre. Contenu : performances, flammes, blessures et douleurs, progression, discipline, profil utile aux moteurs, décisions des moteurs et réponses de l'utilisateur.
- D9.3 Livrer aussi un **script de recalibrage** (`tools/recalibrate/`) qui agrège les fichiers reçus et recalcule les paramètres des moteurs (rejouable, testé).

---

## Décisions prises par les lots (choix réversibles)

(Chaque lot ajoute ici sa section « Gx » : décision, raison, alternative écartée.)

### G1 — Mode dev (30/09-01/10/2026, Opus 5.5)

- **Isolation par préfixe de clés** (`lib/session_prefs.dart`, `KalisPrefs`) : les clés de la session personnelle restent exactement celles d'avant (aucune migration, aucun déplacement de données) ; la session de test écrit sous `kt_session_test::` ; la clé de contrôle `kt_session_test_control_v1` (marqueur, date de création, décalage) est hors des deux espaces. Chaque magasin est lié à l'espace de sa création : une écriture tardive ne peut pas changer d'espace. L'application n'écrit aucun autre fichier interne (sauvegardes par le sélecteur système, copies de récupération dans les préférences) ; seul fichier du mode dev : l'export partagé (`cache/partage/kalis_session_de_test.json`), supprimé avec la session. Écartée : un second fichier SharedPreferences (plugin non prévu pour plusieurs fichiers sur Android, migration plus risquée).
- **Redémarrage logique dans le processus** (`lib/session_host.dart`) : écritures terminées, arbre de l'application démonté, magasin neuf chargé, ouverture rejouée. Écarté : redémarrage du processus Android (code natif, perte de l'état de l'outil).
- **5 appuis pendant une session de test : rien** (la réinitialiser = la supprimer puis 5 appuis). Raison : aucun effacement possible par erreur.
- **Étiquette DEV au bord droit de tous les écrans**, noire et blanche (le rose reste réservé au logo) : le démarrage d'une installation neuve n'a pas d'en-tête, il faut pouvoir atteindre les outils et la suppression partout. Appui long : outils de test.
- **Anneau de l'appui long dans la couleur du texte** (pas en rose). Durée préservée avec « Réduire les animations » (sinon Flutter la ramène à 0,15 s : défaut trouvé sur émulateur, corrigé et testé).
- **TalkBack** : 5 activations du logo comptent comme 5 appuis ; l'action « appui long » du logo rose supprime directement (même règle que D2.2).
- **Suppression aussi depuis les outils de test**, avec confirmation (alternative accessible à l'appui long, qui reste direct).
- **Voyage dans le temps en jours civils entiers** (même heure murale, changements d'heure compris) ; « Choisir une date » de aujourd'hui à + 5 ans ; « Revenir à aujourd'hui ». Restent à l'heure réelle : durées des chronos, identifiants techniques, heure des rappels Android.
- **Rappels** : le service suit le magasin actif ; en session de test, les rappels personnels sont annulés (non programmés), puis recalculés au retour ; ceux de la session de test disparaissent à sa suppression.
- **Export de la session de test** : champs `sessionDeTest: true` et `decalageJours` (optionnels, ignorés par les versions précédentes), fichier `kalis-track-session-de-test-AAAA-MM-JJ-HHMM.json`. Import d'une telle sauvegarde dans la session personnelle : avertissement explicite (aussi dans l'AAB).
- **Preuve D2.4** : marqueur `KALIS-DEV-SESSION-7F3A` (code du mode dev) exigé dans les `libapp.so` de l'APK et absent de celles de l'AAB (`verify_android_artifacts.py --dev-apk`).
- **Tâche `packages`** : convention du simulateur `dart run bin/<paquet>_cli.dart --rapport <dossier>` (docs/CI_GP.md), à suivre par G4, G8, G11.
- **Test daté** : `wod_acquisition_test.dart` fixe l'horloge de la vitrine (il échouait le 01/10/2026 selon l'« essai du jour ») ; aucune assertion retirée.
