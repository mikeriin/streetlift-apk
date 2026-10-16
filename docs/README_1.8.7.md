# Kalis Track — 1.8.7

Application Android Flutter hors ligne : programme streetlifting v3.3, séances personnalisées, catalogue de 500 WODs, chronos et suivi local.

Le nom `streetlift_tracker_v33.zip` désigne la version **3.3 du programme**, pas la version de l'application. Il reste identique pour simplifier les mises à jour du dépôt.

## Mise à jour sur GitHub

1. Dans l'application installée, fais **Réglages → Exporter une sauvegarde** et conserve le texte.
2. Remplace `streetlift_tracker_v33.zip` **à la racine du dépôt** par le zip fourni. Ne le décompresse pas dans le dépôt si tu utilises ce workflow.
3. Le workflow de la version 1.6 reste compatible, sans changement. Si tu utilises encore l’ancien workflow, remplace son contenu par le fichier fourni, à l'emplacement **`.github/workflows/build-apk.yml`**. Son extension doit être `.yml`, sans `.txt`. Garde un seul workflow de compilation.
4. Enregistre le changement du zip et, si nécessaire, celui du workflow. Dans **Actions → Build APK**, consulte le run déclenché par le commit, ou lance **Run workflow**.
5. Quand il est terminé, télécharge l'artefact **kalis-track-apk**. Décompresse l'archive téléchargée, puis ouvre **kalis-track.apk** sur le téléphone.
6. Installe la mise à jour par-dessus l'application existante. L'identifiant Android et la clé de signature sont conservés. Si Android refuse la mise à jour, conserve la sauvegarde et relève le message exact avant toute désinstallation.

La compilation exécute d'abord les vérifications de données, l'analyse Flutter et les tests. Un échec bloque la livraison de l'APK. Le fichier `.sha256` joint à l'artefact permet de vérifier son intégrité.

## Correctif de compilation 1.8.7

Le contrôle GitHub `flutter analyze --no-pub` signalait un `if` sans accolades dans `test/level_fill_test.dart`. Les blocs conditionnels de ce test sont corrigés. Le correctif conserve la refonte Programme / accueil validée. Remplace le ZIP à la racine du dépôt, puis lance **Actions → Build APK**.

Voir **AUDIT_1.8.7.md** pour les résultats du contrôle sur une extraction propre du ZIP et **REFONTE_UI.md** pour la checklist actualisée.

## Programme / accueil 1.8.6 — écran 3 validé

- Le niveau est affiché à gauche : les chiffres pleins se colorent de gauche à droite selon les XP, sans contour, sans dégradé et sans barre séparée. Un appui ouvre Ma progression. Le logo monochrome est à droite.
- La progression des semaines associe une portion pleine, un repère Sx et les points restants. Un appui court ouvre les détails ; le glissement du repère change la semaine. Un balayage horizontal du contenu affiche la semaine précédente ou suivante. La liste complète des semaines reste accessible depuis la fiche.
- Les jours ordinaires sont des cartes compactes arrondies. La séance du jour montre ses statistiques et les muscles ciblés de face et de dos, sans légendes sous les silhouettes.
- La navigation partagée utilise cinq cercles flottants, sans libellés visibles, avec Programme plus grand au centre. Le contenu défile sous un flou progressif ; une marge de fin permet d'atteindre les derniers éléments. La navigation se masque à l'ouverture du clavier.
- Les séances, l'historique en lecture seule, les résumés, les calculs et les sauvegardes restent reliés aux données existantes. Les thèmes clair, sombre et système restent disponibles.

Voir **REFONTE_UI.md** pour la checklist et **AUDIT_1.8.6.md** pour les contrôles. Seul l'écran 3 est validé dans cette nouvelle refonte. La navigation partagée et la position d'arrivée du logo d'ouverture sont adaptées à cet accueil.

Les sections de versions antérieures ci-dessous constituent l'historique des changements ; la description 1.8.6 ci-dessus fait référence pour le Programme et la navigation actuels.

## Transition de navigation 1.8.5

La forme de sélection descend jusqu'à une barre entièrement plate, puis remonte sous le nouvel onglet. La transition dure 360 ms et ne déplace plus la bosse latéralement. Des appuis successifs repartent de la hauteur réellement affichée et aboutissent au dernier onglet choisi.

La barre et la bosse forment un seul aplat de couleur uniforme. Seul le fond derrière les icônes conserve un dégradé de transparence. L'éclair au toucher a été retiré pour ne pas se superposer à la forme. L'icône Programme reste légèrement plus grande que les quatre autres. Le réglage « Réduire les animations » affiche directement la nouvelle sélection.

Voir **AUDIT_1.8.5.md** pour les vérifications de cette livraison.

## En-tête et navigation 1.8.4

Le Programme utilise maintenant un fond continu : aucun trait horizontal ni bandeau de couleur différente en haut ou en bas. Niveau, logo et calendrier sont centrés sur le même axe avec une hauteur visuelle harmonisée. La barre de progression du niveau reste sous son libellé, sans rectangle de fond. Ces indicateurs gardent une échelle commune lorsque le texte du contenu est agrandi.

La navigation inférieure garde ses cinq onglets. Un léger fondu apparaît vers le bas ; une forme arrondie en surbrillance glisse sous l'onglet ouvert. L'icône Programme reste légèrement plus grande que les quatre autres. Les animations suivent le réglage système « Réduire les animations » et les zones tactiles sont conservées.

Le logo de l'ouverture animée termine son trajet à la nouvelle taille de l'en-tête. Voir **AUDIT_1.8.4.md** pour les vérifications de cette livraison.

## Interface 1.8.3

- L'historique reprend les cartes, les tableaux jaunes et la navigation par exercice de l'exécution. Les valeurs, validations et notes sont en lecture seule. Le bilan final ne propose aucune action de modification. L'ouverture ne préremplit pas de valeurs et ne crée aucune entrée dans le journal.
- Les anciens exercices personnalisés restent lisibles même si leur modèle a été supprimé : noms et valeurs enregistrés sont conservés. Si leur unité n'a pas été sauvegardée, la colonne affiche « Valeur ». L'effort est présenté sans réinterpréter les anciennes saisies selon le réglage RIR/RPE actuel.
- L'accueil reprend les titres en capitales et les accents vert, bleu et jaune de l'exécution. Le temps estimé de la séance du jour est mis en avant, à côté des muscles ciblés. Les sept journées, les gestes des cartes, le niveau sans fond rectangulaire, les séparateurs et la navigation du bas sont conservés. Aucun liseré latéral n'est ajouté à la carte du jour.
- Les semaines reprennent les points et la capsule active de l'exécution. La capsule « S1…S40 » reste compacte (30 × 18 px au réglage normal) avec une zone tactile de 48 px. Le glissement, les commandes accessibles, l'appui long et le calendrier sont conservés.
- L'ouverture animée réutilise exactement le logo de l'en-tête. Voir la section suivante et **AUDIT_1.8.3.md** pour les vérifications.

## Programme 1.8.1

- Niveau et petite barre de progression sans fond rectangulaire ; logo clair centré et calendrier à droite.
- Un seul curseur, avec le numéro **S1…S40** directement sur sa poignée. Fais-le glisser pour changer de semaine ; maintiens le numéro pour ouvrir le détail. Le calendrier permet aussi de choisir une semaine.
- Les sept cartes restent compactes et la séance du jour est développée et mise en surbrillance par son fond. Les menus ⋮, la mention « Aujourd’hui » et les boutons de démarrage/détails ont été retirés.
- **Appui court sur une carte** : ouvrir/reprendre la séance, ou consulter son historique lorsqu’elle est terminée.
- **Appui long sur une carte** : ouvrir directement son résumé (état, exercices, muscles, volumes, durée et détail des calculs).

La navigation inférieure et les calculs de la version 1.8.0 sont conservés. Voir **AUDIT_1.8.1.md** pour les vérifications de cette mise à jour.

## Estimations 1.8.0

Le résumé d’une séance détaille effort, repos, transitions, volumes et hypothèses. Chaque exercice du panneau ouvre son propre calcul. Dans une séance, le même détail se trouve dans les consignes de l’exercice. Les aperçus WOD, les cartes du catalogue et ses filtres utilisent le même moteur commun.

Les durées tiennent compte des tempos, fourchettes de répétitions et repos, exercices unilatéraux, isométries, myo-reps, clusters, échelles, supersets, HIIT, AMRAP et EMOM. Une limite de chrono n’est plus utilisée comme durée de complétion. Les cash in / cash out sont comptés une fois, en dehors des intervalles. Les chronos de repos ne se relancent plus après la dernière série.

La charge est présentée dans des unités vérifiables : répétitions, secondes d’effort, mètres, calories de machine et **kg·rép. externes connus**. Les anciennes pondérations de points restent réservées au classement des niveaux WOD ; elles ne sont plus présentées comme une mesure de charge réelle. À partir de trois résultats complets de la même prescription, le temps d’un WOD à terminer peut s’ajuster à l’historique. Un changement de consigne invalide cet ajustement.

Les estimations ne sont pas des mesures : les cadences et pauses libres sont des hypothèses affichées. Une prescription non chiffrée reste signalée, notamment une tenue « max ». Le détail et les limites sont documentés dans **AUDIT_1.8.0.md**.

## Écran de lancement 1.7.7

À l'ouverture, le nom **KALIS TRACK** et le logo apparaissent au centre. Un petit drapeau français de **36 × 24 px** est placé en bas, au-dessus de la zone système. Le même logo se déplace et se réduit jusqu'à sa position dans l'en-tête du Programme, tandis que l'accueil apparaît en fondu.

L'animation dure **2 secondes**, avec chargement des données en parallèle. Si le chargement dépasse la première partie, la marque reste au centre puis termine son déplacement une fois les données prêtes. L'option système « Réduire les animations » remplace le déplacement par un fondu. Un retour à une application déjà ouverte reprend l'écran en cours. Le premier écran natif Android reprend le K existant ; l'icône installée reste identique.

## Interface 1.7.6 — commandes plus fines

La direction artistique de la version 1.6 est rétablie : bandeaux en dégradé, bouton Programme central, cartes compactes, titres de section en capitales et couleurs propres aux exercices. La version 1.7.2 resserre les cartes, les formulaires et les listes dans ce même style, en clair comme en sombre.

La version 1.7.6 allège les commandes harmonisées en 1.7.4 : graisse des textes réduite, arrondis plus courts, fonds plus discrets et actions secondaires moins remplies. À taille de texte normale, les boutons ont une surface visible de référence de **36 px** et une zone tactile de **44 px** ; les champs de formulaire et sélecteurs mesurent **40 px**. La saisie des performances affiche des cellules de **36 px**, avec une zone de saisie étendue verticalement à **44 px**. Les champs multilignes et les textes agrandis prennent la hauteur nécessaire.

- **Commandes et formulaires** : actions voisines de même largeur et centrées sur le même axe, grilles de saisie régulières, libellés de formulaire toujours visibles et marges communes. Les groupes passent en colonne lorsque l’écran ou le texte l’exige. Le sélecteur de thème possède trois segments égaux. Dans le chrono WOD, Démarrer est l’action principale ; Valider round et Terminer sont délimités par un contour fin, Réinitialiser reste discret. Les réglages +/− et les validations de série n’ont plus de gros pavés.
- **Navigation** : cinq destinations permanentes autour du bouton Programme central. La semaine sélectionnée et la position dans les listes sont conservées en changeant d'onglet. Le changement de thème conserve l'état des écrans.
- **Programme** : vue compacte 1.8.1 et gestes décrits ci-dessus ; palette et repères J1 à J7 conservés.
- **Séance** : une carte par exercice, avec prescription et lignes de saisie rapprochées. Les consignes détaillées s’ouvrent avec le bouton d’information. Une note vide est repliée ; le bouton de note sous les séries permet de l’ouvrir. Une note déjà enregistrée est affichée à l’ouverture de l’exercice. Les exercices enchaînés conservent une page commune et chacun leur carte. Les petits repères séparés de la version 1.6 indiquent à nouveau chaque étape, bilan inclus ; le repère actif est plus long et reprend la couleur de la semaine. Le glissement horizontal reste disponible ; les boutons Précédent/Suivant et la liste Exercices donnent un accès direct au bilan et aux autres cartes. Les colonnes d'effort et de vitesse passent sous les autres champs lorsque la largeur disponible l'exige.
- **Arsenal et catalogue** : création de séance et de WOD directement accessibles, menus d'actions visibles, recherche effaçable, filtres homogènes et indications quand la recherche ne renvoie aucun résultat.
- **WOD** : mouvements prioritaires dans l'aperçu, chronomètre prioritaire dans l'exécution, commandes et résultats regroupés en cartes.
- **Éditeurs** : bouton Enregistrer explicite, réorganisation visible des exercices et champs adaptés à la largeur de l'écran et au clavier.
- **Suivi, progression et Pilotage** : même carte de niveau, références et cibles plus lisibles, explications simplifiées. Les valeurs de Pilotage sont enregistrées automatiquement.
- **Réglages** : préférences regroupées et choix du thème qui s'adaptent à la largeur. Les boutons de test de notification ont été retirés.

## Notifications

Dans **Réglages → Notifications**, active **Rappels de séance**, puis choisis l'heure et l'option d'ignorer les jours de repos. Le panneau indique le prochain rappel. Les autorisations nécessaires restent demandées au moment de l'activation.

Les réglages avancés sont regroupés sous **Options Android** : heure précise, paramètres du canal et batterie. Un blocage Android ou une erreur de programmation reste visible avec l'action correspondante.

Les rappels couvrent les journées restantes et non validées du programme, jusqu'à 280 alarmes. Les préférences du canal Android existant sont respectées. Les tests de notification fonctionnels sur le téléphone ne sont plus proposés dans l'interface ; la suite de tests du code conserve sa couverture du service.

Les commandes **Exporter une sauvegarde** et **Importer une sauvegarde** sont à nouveau reliées à leur action. Dans le Pilotage, les valeurs se placent à côté de leur référence lorsque la place le permet, avec des unités courtes ; les champs passent sous leur libellé lorsque le texte est agrandi ou l'écran étroit.

### Densité d’affichage

La carte de référence « Muscle-up lesté » en S8/J1 passe de **689 à 450 pixels logiques de haut** sur un écran de 390 × 844, à taille de texte normale, soit **environ 35 % de moins**. Un test à 360 × 760, avec les espaces système et la colonne RIR, vérifie que les cinq séries sont entièrement visibles et validables sans défilement. Les valeurs restent en taille 15 ; les boutons de validation gardent une cible de 44 × 44.

Les bandeaux de niveau, les listes, les réglages et les cartes de suivi sont également resserrés. Les consignes complètes, notes, grands textes et exercices comportant davantage de séries restent consultables par défilement lorsque nécessaire.

## Progression 1.6

Ouvre **Ma progression** en touchant le niveau en haut de l'accueil, ou depuis les cartes de l'Arsenal et du Suivi.

- **7 rangs** : Recrue (1), Régulier (5), Challenger (10), Vétéran (20), Expert (30), Élite (45), Légende (60).
- **16 badges** : séances terminées, séries validées, WODs terminés et variés, améliorations de records, régularité. Les objectifs affichent leur progression et leur récompense.
- **4 objectifs par semaine** : 2 jours actifs (+75 XP), 3 jours actifs (+50 XP), 20 séries validées (+50 XP), 1 WOD terminé (+40 XP). Les bonus se cumulent, jusqu'à 215 XP par semaine.
- **Régularité par semaine** : 2 jours d'entraînement distincts suffisent. Les jours de repos n'interrompent pas une série ; la semaine en cours peut encore être complétée.
- **Crédits durables dans la progression** : 1 par niveau, +1 tous les 5 niveaux et encore +1 tous les 10. Les crédits déjà dépensés et les WODs débloqués restent comptabilisés.
- **XP transparentes** : détail par origine, barre de niveau, prochain rang et récompense à venir. L'historique existant compte rétroactivement pour les bonus, quand les dates le permettent.

La courbe de niveaux et les XP de base sont conservées (programme 100, perso 60, tentative WOD 80, première référence WOD valide 40). Chaque amélioration stricte ultérieure d'un record WOD valide apporte désormais 40 XP supplémentaires. Une égalité ou une tentative inachevée ne donne pas de bonus de record.

Les bonus sont calculés depuis le journal, sans bouton de réclamation : ils ne doublent pas au redémarrage ou à la réimportation. Supprimer des données peut retirer leurs XP et bonus. Les journées de récupération gardent le barème historique de validation, mais ne comptent pas comme entraînements pour les nouveaux objectifs et badges.

## Autres corrections conservées de la version 1.5

- Sauvegardes plus compactes, regroupées dans une écriture unique ; saisies et notes sauvegardées après 600 ms d'inactivité, avec enregistrement lors du passage en arrière-plan et à la sortie de séance.
- Import entièrement validé avant remplacement ; reprise des anciennes préférences et des exports v1/v2, sans supprimer les anciennes clés lors de la migration.
- Séance perso déjà terminée : choix entre consulter et recommencer. Recommencer archive la précédente occurrence ; chaque séance terminée peut ainsi contribuer à l'historique et à l'XP.
- Historique consultable dans Suivi ; compteur d'avancement limité au programme. Carte hebdomadaire fondée sur les dates de validation des nouvelles séries, même si tu exécutes une autre semaine du programme.
- Chronos corrigés : précision pendant les pauses, temps exact au clic Round, rattrapage après arrière-plan, prévention des doublons de score, contrôle des durées et des paramètres.
- Résultat WOD incomplet identifiable ; il est exclu des records chronométrés. Tri AMRAP par rounds, puis répétitions.
- Calcul des niveaux WOD rétabli ; points mieux lus pour les EMOM, blocs multipliés, charges décimales et abréviations MU. Les déciles reposent sur le catalogue complet, indépendamment des suppressions personnelles.
- Carte musculaire corrigée, recherche effaçable, formulaires mieux validés, contrôleurs libérés et adaptations aux petits écrans.
- Rappels quotidiens sérialisés, actualisés au retour dans l'application ; un appui ouvre la séance concernée. Les séances déjà terminées sont ignorées.
- Projet Android complet inclus : plus de génération de squelette ni de réécriture fragile de fichiers Gradle dans le workflow.

Voir **AUDIT_1.8.6.md** pour les changements actuels et **AUDIT_1.8.0.md** pour les estimations ; **AUDIT.md** et **AUDIT_1.5.0.md** conservent les notes antérieures.

## Données et compatibilité

- Programme inchangé : **40 semaines, 280 jours, 1 954 prescriptions**. Base d'exercices inchangée : **172 entrées**.
- Ancrage : lundi **13 juillet 2026**, donc S8 le **31 août 2026**. Les semaines sont calculées par dates civiles, y compris au changement d'heure.
- Identifiant : `fr.tchoupi.streetlift_tracker`.
- Signature : `signing/kalis_track.p12`, alias `kalis`, identique au fichier d'origine.
- Version visible : `1.8.7`. GitHub Actions génère un versionCode fondé sur la date, qui reste croissant même si le workflow est renommé.
- Les nouveaux exports peuvent commencer par `gz:` : c'est une sauvegarde compressée complète à copier **en entier**. Ils s'importent dans cette version ; les versions antérieures à 1.5 ne savent pas lire ce format. La version 1.8.7 conserve le format de sauvegarde des versions 1.5 et 1.6.
- Les nouvelles dates de validation n'existent pas dans les anciennes séries : pour ces dernières, la carte utilise la date de fin de séance, ou la date planifiée pour une séance du programme encore ouverte.
- L'option livres (lb) concerne les **charges suggérées** ; le journal et le Pilotage restent explicitement en **kg**.

## Signature et secrets GitHub

La clé d'origine est gardée dans le zip pour assurer la continuité des installations. Le mot de passe historique est utilisé par défaut. Si tu as déjà un secret `KALIS_KEYSTORE_PASSWORD`, il doit correspondre au mot de passe de cette même clé.

Si le dépôt est public, la présence de cette clé et de son mot de passe dans les fichiers permet à des tiers de signer des APK avec cette identité. Le workflow accepte un secret `KALIS_KEYSTORE_BASE64` contenant **la même clé**, encodée en base64 : tu peux alors retirer le fichier `.p12` de tes prochaines archives publiques. Déplacer la clé ne retire toutefois pas les copies déjà publiées dans l'historique. Ne génère pas une autre clé pour cette mise à jour : elle ne serait pas acceptée par l'application installée.

`tools/verify_project.py --signing` compare le certificat à l'empreinte d'origine. Le mot de passe est lu depuis l'environnement, sans être injecté dans du code Gradle.

## Développement local

Environnement fixé pour cette livraison : Flutter **3.29.3**, Dart **3.7.2**, Java **17**. Android : compileSdk **36**, targetSdk **35**, minSdk **21**, AGP **8.12.1**, Gradle **8.13**, Kotlin **2.2.10**.

Après extraction du zip, dans le dossier `streetlift_tracker` :

```bash
flutter pub get --enforce-lockfile
flutter analyze --no-pub
TZ=Europe/Paris flutter test --no-pub
python3 -m unittest discover -s tools/tests -v
python3 tools/verify_project.py --signing
dart run flutter_launcher_icons
flutter build apk --release --no-pub --build-number=NUMERO_SUPERIEUR_A_L_INSTALLE
```

La compilation Android exige un SDK Android configuré et ses licences acceptées. Le workflow s'exécute sur le runner GitHub Ubuntu et laisse Gradle installer les composants Android requis.

Ne remplace pas le projet par un nouveau squelette Flutter : les fichiers `android/` livrés portent les réglages de signature, les notifications et le petit pont natif de fréquence d'affichage.

## Régénérer les données

Le classeur et l'illustration source ne sont pas inclus dans le zip d'origine. Les assets existants suffisent pour compiler ; aucune régénération n'est nécessaire.

```bash
# Nécessite openpyxl et le classeur original.
python3 tools/xlsx_to_json.py Programme_Streetlifting_v3-3.xlsx
python3 tools/pack_assets.py

# Outil optionnel de segmentation : nécessite Pillow, NumPy et SciPy.
python3 tools/muscles_from_reference.py illustration.png --output segmentation
```

Le convertisseur refuse les formules inconnues au lieu de remplacer silencieusement une charge par zéro. Les arrondis Python suivent l'arrondi Excel à mi-distance. La compression est reproductible et conserve les sources JSON. L'outil de segmentation produit des fichiers de travail, pas un remplacement automatique des masques de l'application.

## Limites actuelles

- Les chronos utilisent le temps réel et se recalent au retour. Ils ne sont pas un service Android permanent : si Android suspend ou tue le processus, une alerte sonore à l'instant exact n'est pas garantie. Le maintien de l'écran allumé reste disponible.
- Les rappels couvrent tout le programme restant. Android peut retarder une alarme approximative ou bloquer les notifications en raison des autorisations, du canal, du mode Ne pas déranger ou des restrictions du constructeur. Les réglages Android restent accessibles dans le panneau des rappels.
- Les points, durées estimées et cartes WOD sont des estimations à partir des textes. Les variantes, pénalités et schémas libres complexes ne constituent pas des données structurées exhaustives.
- Les résultats des tests Flutter et Python de cette livraison sont détaillés dans AUDIT_1.8.7.md. Le service de notifications est testé avec une simulation de la couche native. La compilation release Android et le comportement sur téléphone doivent être confirmés par le run GitHub et l'installation.
