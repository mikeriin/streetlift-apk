# Kalis Track 1.8.0 — Programme et estimations

Version **1.8.0+32**, issue de la version 1.7.7. Refonte de Programme d’après les deux croquis et remplacement des calculs affichés de volume et de durée. Aucune dépendance ajoutée.

## Interface livrée

- Niveau existant à gauche, silhouette claire du logo centrée, calendrier à droite.
- Curseur des 40 semaines, navigation précédente/suivante et retour à la semaine actuelle. Le numéro ouvre un panneau avec dates, bloc, cycle, validation et séances de la semaine.
- Sept journées sous forme de lignes compactes. La séance du jour est développée à l’ouverture ; toucher une autre journée développe sa fiche. Un bouton distinct permet de démarrer, reprendre ou consulter.
- État de validation, nombre d’exercices, volumes, durée et silhouettes musculaires face/dos sur la fiche. Le menu et la confirmation d’effacement sont conservés.
- Détail des calculs accessible par le bouton d’information, avec accès à chaque exercice. Même présentation dans les consignes d’exercice et l’aperçu WOD.
- Navigation inférieure, cartes par exercice, progression segmentée de séance et écran d’ouverture au drapeau de deux secondes conservés.

## Calculs

Le moteur commun est dans `lib/training_estimate.dart`. Il produit des volumes et une durée avec une borne basse et haute, au lieu d’un temps unique obtenu par une pondération de points.

| Élément | Traitement |
|---|---|
| Séries et répétitions | Somme des répétitions, avec conservation des fourchettes ; deux côtés comptés lorsque la prescription le demande. |
| Charge externe | Somme de répétitions × kg connus ; deux haltères comptés lorsque c’est explicite. Le poids du corps est exclu. |
| Efforts chronométrés | Secondes d’effort distinctes des répétitions ; tenues, montée en tension explicitée et intervalles pris en compte. |
| Effort estimé | Répétitions × cadence propre au mouvement ; un tempo explicite remplace la cadence par défaut. Distances et calories de machine conservent leurs unités. |
| Repos | Repos entre les séries, soit N−1 ; plages et unités mixtes comme « 2 min 30 » conservées. Micro-repos myo et clusters ajoutés séparément. |
| Exercices enchaînés | Un repos commun par tour ; horloge partagée pour les deux EMOM d’une même page. |
| Transitions | Hypothèse de 30–60 s entre blocs du programme ; 3–8 s entre mouvements/blocs d’un WOD. |
| WOD sans repos prescrit | Pour les formats concernés, marge de pauses libres de 10–35 % du temps d’effort, explicitée dans le détail. |
| AMRAP / HIIT / EMOM | Durée imposée respectée ; volume AMRAP projeté selon les cadences. Plages de minutes et rotations EMOM appliquées à chaque créneau. |
| Cash in / cash out | Une seule occurrence, hors des intervalles EMOM. |
| Time cap | Affiché séparément ; ne raccourcit pas artificiellement le temps nécessaire pour compléter le volume écrit. |
| Maximum inconnu | Volume et temps manquants signalés. Pour les répétitions maximales du programme, le Pilotage peut fournir une plage indicative de 70–100 % du maximum renseigné. Une tenue maximale inconnue n’est pas inventée. |

Exemples couverts par les tests :

- 3×5, tempo 3-0-1-0, repos 60 s : **15 répétitions, 60 s d’effort + 120 s de repos = 3 min**. Avec 10 kg externes : **150 kg·rép.**
- 3×8–12 avec 2–3 min de repos : **24–36 répétitions et 4–6 min de repos**.
- 8 intervalles de 30 s / 30 s : **7 min 30**, sans dernier repos.
- EMOM 10 min, cinq créneaux à 10 répétitions puis cinq à 20 : **150 répétitions, 10 min**.
- AMRAP 3 min + 2 min repos + AMRAP 4 min + 2 min repos + AMRAP 5 min : **16 min**.
- EMOM 30 min avec 1 000 m de rameur avant et après : **2 000 m hors des créneaux**, comptés une fois ; le temps total dépasse les 30 min du bloc EMOM.

### Ajustement à l’historique

À partir de **trois résultats complets**, les WOD à terminer sans horloge fixe peuvent utiliser jusqu’aux cinq résultats récents correspondant exactement à la prescription enregistrée. La plage englobe les temps observés et au moins ±15 % autour de leur médiane. Les détails effort/repos restent théoriques et sont identifiés comme tels.

Une signature de prescription optionnelle est enregistrée avec les nouveaux résultats : format, tours, durée, intervalle, repos, schéma, mouvements et notes du WOD. Une modification empêche de réutiliser les temps de l’ancienne variante. Les résultats incomplets et les anciens résultats sans cette signature ne calibrent pas l’estimation. La comparaison suppose que la prescription écrite a bien été réalisée.

### Sens des indicateurs et limites

Les répétitions de mouvements différents ne constituent pas une équivalence de difficulté. Le tonnage ne mesure ni la fatigue ni la dépense énergétique. Les calories affichées sont celles prescrites sur l’ergomètre. L’indice historique de points est conservé uniquement pour le classement et les déverrouillages WOD, afin de préserver la progression existante.

Les cadences, transitions et marges de récupération sont des hypothèses de l’application, non une formule physiologique validée. L’échauffement non prescrit, les changements de matériel longs et les pauses libres supplémentaires ne peuvent pas être connus à l’avance. Les pénalités variables, options, variantes et partages en équipe restent à interpréter d’après les consignes ; le volume affiché peut concerner l’équipe et non une personne. Le moteur signale les éléments qu’il ne peut pas chiffrer.

La distinction entre charge externe et réponse interne est notamment discutée par [Bourdon et al., *Monitoring Athlete Training Loads: Consensus Statement* (2017)](https://pubmed.ncbi.nlm.nih.gov/28463642/). Cette référence ne valide pas les coefficients choisis ici. Une validation des écarts entre durées prévues et durées réelles nécessite tes séances sur téléphone.

## Fiabilité et compatibilité

- Cache des estimations WOD invalidé par les changements de prescription ou de résultats, avec taille limitée.
- Analyse des blocs imbriqués bornée ; génération d’échelles limitée pour éviter une boucle excessive sur une saisie extrême.
- Valeur « 2 min 30 » prise en compte aussi par le chrono automatique ; pas de repos automatique après la dernière série.
- Programme, base d’exercices, calcul des charges suggérées du Pilotage, signature Android et workflow conservés.
- Les nouveaux champs de résultats sont optionnels : les anciennes sauvegardes restent lisibles.

## Vérifications effectuées

- Flutter **3.29.3**, Dart **3.7.2** ; analyse statique sans anomalie.
- **115 tests Flutter réussis**, dont 27 sur les estimations et 4 sur la nouvelle vue Programme. Les 51 tests concernant calculs, store et Programme ont aussi été exécutés après le dernier ajustement du code.
- **4 tests Python réussis** ; intégrité des **40 semaines, 280 jours, 1 954 prescriptions et 172 exercices** vérifiée, ainsi que les ressources Android et le certificat de signature.
- Tous les exercices du programme et les 500 WODs traversent le moteur avec des résultats finis, ordonnés et non négatifs. Cela vérifie la robustesse, pas la précision physiologique des hypothèses.
- Rendus Flutter avec Roboto en clair et sombre : Programme à 320, 360 et 390 px, panneau de semaine, détail des estimations et aperçu WOD. Sur la référence S8/J4, les sept journées tiennent sans défilement en **360×760** et **390×844** ; un léger défilement reste possible sur écran plus étroit ou texte agrandi.
- Tests avec texte à 130 %, navigation, démarrage de la journée sélectionnée, bornes du curseur, persistence des saisies, sauvegardes et chronos existants.

**L’APK n’a pas été compilé ni installé ici.** Le fonctionnement natif Android et l’exactitude pratique des temps restent à confirmer sur ton téléphone après compilation.

## Livraison et installation

Remplace **streetlift_tracker_v33.zip** à la racine de ton dépôt, puis lance **Actions → Build APK**. Le workflow actuel reste compatible. Télécharge l’artefact **kalis-track-apk**, extrais **kalis-track.apk** et installe la mise à jour sur l’application existante.
