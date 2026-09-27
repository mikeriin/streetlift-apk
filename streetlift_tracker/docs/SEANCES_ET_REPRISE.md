# Séances et reprise (L4b — KT-009, KT-018)

Version 2.5.9. Décisions du propriétaire du 26/09/2026 (Europe/Paris) :

| Sujet | Décision |
| --- | --- |
| Valeur d'une série | **Obligatoire pour valider** : reps, secondes ou minutes requises et valides ; un pré-remplissage compte seulement si tu coches ; kg, RIR/RPE, vitesse facultatifs mais vérifiés ; 0 accepté seulement pour un test max ; lest négatif (assistance) accepté |
| Repos entre séries après destruction du processus | **Non relancé** : la séance rouvre sur l'exercice en cours, aucun bip tardif ; écran verrouillé / arrière-plan : le repos continue à l'heure réelle |
| Chrono WOD après destruction, arrêt forcé, redémarrage | **Pause au dernier temps sûr** : tentative et droit de finir retrouvés (essai commencé avant minuit compris) ; chrono en pause au dernier point enregistré ; « Reprendre » (absence non comptée) ou « Terminer » pour saisir le score ; rien d'inventé |
| Séances en cours, fin partielle, abandon | **Fonctionnement actuel + reprise visible** : plusieurs journées peuvent avoir un brouillon ; quitter ≠ abandonner ; « Terminer » possible avec des séries non validées (bilan x/y, XP inchangée) ; badge « En cours » ; abandon = « Effacer l'historique » (confirmé) ; un seul WOD chronométré actif |

## 1. Saisie des séries (KT-009)

| Champ | Sens | À la coche | Format et domaine | Refus |
| --- | --- | --- | --- | --- |
| Valeur | reps (reps, max, EMOM, AMRAP, intervalles) | obligatoire | entier, 5 chiffres au plus ; **0 seulement pour un test max** | vide, décimale, unité collée (« 8 reps »), signe, exposant |
| Valeur | secondes (tenue, tenue max) | obligatoire | entier ; 0 seulement pour une tenue max | idem |
| Valeur | minutes (durée) | obligatoire | entier ≥ 1 | idem |
| kg | lest (charge ajoutée) ou barre | facultatif | virgule **ou** point, 2 décimales, \|v\| ≤ 10 000 ; **négatif = assistance** (élastique, machine) | « 1.250 » (séparateur ambigu), « 72 5 », « 1e3 », « NaN », « 72,5 kg » |
| RIR | répétitions en réserve | facultatif | 0 à 99, pas de 0,5 | « 2,3 », négatif |
| RPE (réglage) | effort perçu | facultatif | 1 à 10, pas de 0,5 | 0, 11 |
| Vitesse | m/s | facultatif | > 0, 3 décimales | 0, 4 décimales |

- Blancs autour d'une valeur collée (espace, insécable) : ignorés. Aucun séparateur ambigu n'est réinterprété.
- **Vide ≠ 0** : un champ vide est une valeur absente. 0 kg = sans lest (valide). 0 rep = refusé sauf test max.
- **Suggestion / brouillon / performance** : le pré-remplissage (reps prévues, charge suggérée) et un chrono de tenue terminé restent des brouillons. Seule la **coche** acceptée fait d'une série une performance (statistiques, records, XP de séries comptent les séries validées).
- **Où** : `AppStore.toggleSet` (niveau métier, tout point d'entrée) et l'écran de séance. Refus : rien ne change, le texte saisi reste, le champ est nommé sous la série (icône + texte, région annoncée une fois) ; le message disparaît à la frappe.
- **Série validée puis modifiée** : valeur toujours valide → reste validée (même heure de validation) ; valeur devenue invalide → **repasse non validée** avec le message. Décocher / recocher ne donne aucun gain supplémentaire (XP de séance = séance terminée ; crédits au registre L3).
- **Unités** : les séries sont toujours saisies et stockées en kg ; le réglage « livres » ne convertit que l'affichage des charges suggérées : aucune conversion aller-retour sur une saisie.
- **Anciennes données** : journaux et sauvegardes existants lus tels quels (aucune valeur réécrite, aucune série supprimée, aucune sauvegarde refusée pour une ancienne valeur) ; seules les **nouvelles** coches sont vérifiées.

## 2. Occurrences et états

| Type | Identité | États |
| --- | --- | --- |
| Journée du programme | clé `S<n>-J<j>` (L4 : calendrier, S·J inchangés) | brouillon (ouverte, suggestions) → **en cours** (≥ 1 série validée ou une note) → terminée (`done`, `finishedAt`) |
| Séance perso | `S0-J<id>` ; occurrences terminées archivées `S0-J<id>@<uid>` à « Nouvelle séance » | idem ; l'archive n'est jamais réécrite, même si le modèle change ou est supprimé |
| Tentative WOD | identifiant de tentative (L3) + point sûr local | lancée → en pause / en cours → score enregistré (le point sûr disparaît dans la même écriture) ou abandonnée (sortie confirmée) |

- Reprendre = rouvrir la **même clé** : aucune nouvelle occurrence, ni par une notification, ni par une reconstruction, ni par l'historique.
- La page de reprise se déduit du journal (groupe de la dernière série validée, ou le suivant s'il est complet) : aucune donnée en double.
- Reprise après minuit : les séries gardent leur heure de validation ; la date de fin (`finishedAt`) est l'heure où tu termines (sémantique existante) ; S·J et calendrier L4 ne bougent pas.
- **Abandon** : programme / perso = « Effacer l'historique » (confirmé, la journée seulement) ; WOD = « Quitter » confirmé (la tentative ; les résultats enregistrés restent). Une interruption ou une navigation n'abandonne rien.
- **Un seul WOD chronométré** : démarrer un autre WOD propose d'abandonner la tentative en cours (dialogue), sinon rien ne démarre (aussi vérifié par le store).

## 3. Matrice de reprise

| Situation | Séances (programme, perso) | Repos / tenue / EMOM de ligne | Chrono WOD |
| --- | --- | --- | --- |
| Navigation (autre écran, puis retour) | brouillon et séries en mémoire, écriture différée (600 ms) | continue à l'heure réelle | continue ; tentative ouverte |
| Pause demandée | — (pas de pause de séance) | « Arrêter » | temps figé ; point sûr |
| Verrouillage, arrière-plan | écriture à `paused`/`inactive` | continue ; bip joué seulement si le processus tourne ; au retour : phase juste, aucune rafale | continue à l'heure réelle ; au retour : phase juste, alerte seulement si la transition date de < 1,5 s ; point sûr au plus toutes les 15 s de temps actif |
| Appel, dialogue système | idem arrière-plan | idem | idem (non converti en pause) |
| Destruction du processus, relance | journal relu : **même séance**, badge « En cours », bandeau « À reprendre », ouverture sur l'exercice en cours | **non relancé** (décision) | **tentative retrouvée, chrono en pause au dernier point sûr** ; absence non comptée ; « Reprendre » ou « Terminer » |
| Arrêt forcé puis ouverture manuelle | idem destruction | idem | idem |
| Redémarrage du téléphone | idem | idem | idem ; aucun repère d'horloge réutilisé |
| Import (même appareil ou autre) | données du fichier ; brouillons du fichier = brouillons | non concerné | **jamais exporté ni importé** ; l'import et l'effacement annulent le chrono en cours ; un écran encore ouvert ne peut plus écrire (garde `dataEpoch`) |

Perte possible : au plus les frappes des **600 ms** précédant une destruction (écriture différée), et pour un WOD le temps actif depuis le **dernier point sûr** (≤ 15 s, ou depuis la dernière pause / phase / round). Une écriture acceptée par l'API de stockage n'est pas une preuve de durabilité disque absolue.

## 4. Horloges

- **Heure murale** (`DateTime.now`) : compte la veille de l'appareil ; peut sauter (réglage manuel, fuseau n'intervient pas : les durées sont des différences d'instants).
- **Horloge monotone du processus** (`Stopwatch`, CLOCK_MONOTONIC sur Android) : ne recule jamais, mais s'arrête en veille profonde et repart à chaque processus.
- **Durée d'un chrono** = max(heure murale écoulée, monotone écoulée) dans un même processus : un recul de l'heure ne fait ni reculer ni geler un chrono ; un saut en avant n'est pas distinguable d'une veille et est compté (limite).
- Sources consultées le 26/09/2026 : Android `SystemClock` (`currentTimeMillis` réglable par l'utilisateur ou le réseau ; `uptimeMillis` s'arrête en veille profonde ; `elapsedRealtime` la compte) ; VM Dart `runtime/vm/os_android.cc` (horloge monotone = `clock_gettime(CLOCK_MONOTONIC)`) ; Flutter `AppLifecycleState` (aucune notification garantie avant une terminaison brutale : les écritures ne dépendent donc pas de la fermeture). Une horloge incluant la veille (`elapsedRealtime`) demanderait un canal natif : non ajouté, inutile aux règles approuvées puisqu'aucune origine n'est réutilisée entre processus.
- **Rien n'est persisté comme origine de durée** : un point sûr ne contient que du temps déjà compté (ms actives, rounds, fin du repos inter-round). Après un nouveau processus, un redémarrage ou un import, la reprise part de ce temps, en pause.
- Les phases (Tabata, intervalles, EMOM, repos) se déduisent du temps écoulé, jamais du nombre de rafraîchissements : des ticks manqués ne prolongent aucune phase ; une seule alerte récente, aucune rafale.
- Un chrono terminé ne valide ni une série ni une séance ; la feuille de score WOD reste à remplir (L3b).

## 5. Fin de séance, bilan, récompenses

1. « Terminer la séance » → `finishSession` : séance marquée terminée, bilan calculé et **mis de côté**, écriture attendue.
2. Écriture acceptée → retour à la navigation, bilan (ou bandeau si les célébrations sont coupées), niveau.
3. Écriture refusée → séries gardées, message, bouton **« Réessayer l'enregistrement »** ; aucun bilan annoncé.
4. Double appui / nouvel appel : aucune seconde fin, aucun second bilan, aucun gain de plus (XP dérivée du journal, crédits au registre L3 par identifiant).

Présentation « au plus une fois » (en mémoire) ; attribution persistée avec la séance. Destruction : avant l'écriture → séance « en cours », à terminer à nouveau (un seul gain) ; après l'écriture, avant ou pendant le bilan → séance terminée, gains conservés, bilan non rejoué (la célébration de niveau reste due à la prochaine vérification).

## 6. Historique

Lecture sur une copie détachée : consulter, faire défiler, changer de thème, quitter ne modifie ni séries, ni notes, ni dates, ni crédits, ni séance en cours, ni stockage. Seules les corrections L1b-R2 confirmées (rouvrir, supprimer) écrivent.

## 7. Notifications et alertes

| Élément | Nature | Après L4b |
| --- | --- | --- |
| Rappels du programme | alarmes natives planifiées (L4 : calendrier confirmé) | inchangés ; repli approximatif si l’alarme exacte est refusée (déjà présent, relevé par A0 ; testé par `notifications_test.dart`) |
| Repos, transitions d'intervalle, fin de WOD | sons / vibrations dans l'application | pas d'alerte native : **non reçus si le processus est suspendu ou détruit** |
| Ouverture par rappel | charge utile `S<n>-J<j>` validée (1 ≤ n ≤ 40, 1 ≤ j ≤ 7) | journée déjà ouverte → retour à son écran ; autre journée ouverte → refermée (brouillon gardé) puis ouverture ; journée faite → historique ; double appui → une seule route ; aucune série, occurrence ni récompense créée |

Aucune permission, service permanent ou exemption de batterie ajoutés. « Planifiée » (accepté par le plugin) ≠ « reçue » : non garanti après arrêt forcé ou restriction constructeur.

## 8. Données et migrations

- Nouveau champ local `activeWod` (v1) dans le document d'état : tentative, WOD, empreinte de la définition, dates de lancement et de point sûr (information), ms actives, rounds, repos inter-round, time cap, fin. Validation stricte ; illisible → ignoré avec un message, **le reste des données est chargé**.
- Exports : inchangés (format 3, sans `activeWod`) ; un fichier qui en contiendrait un est importé sans lui. Anciennes sauvegardes : importées, aucune séance en cours synthétisée.
- Aucun autre stockage : pas de fichier, pas de clé parallèle ; l'effacement L2b remet l'état neuf.

## 9. Protocole de test

Automatique : `test/l4b_seances_test.dart` (horloges injectées, stockage simulé) et suites existantes. Téléphone : `LIVRAISON_L4b.md` (A non destructif sur ton installation, B sur appareil ou profil de test : arrêts forcés, redémarrage, erreurs).
