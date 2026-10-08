# Kalis Track 4.3.0 — Test fermé Google Play (KT-078)

**27 septembre 2026.**

## 1. Règle en vigueur

Source : aide Play Console « App testing requirements for new personal developer accounts », https://support.google.com/googleplay/android-developer/answer/14151465, consultée le 27/09/2026 : les comptes développeur **personnels créés après le 13 novembre 2023** doivent mener un test fermé avec **au moins 12 testeurs inscrits sans interruption pendant au moins 14 jours** avant de demander l'accès à la production. Un testeur qui se désinscrit avant 14 jours ne compte pas ; s'il se réinscrit, les 14 jours repartent de zéro. (Conforme à la dernière connaissance du propriétaire.)

Conseil : viser **15 à 20 testeurs** pour garder 12 inscrits sans interruption, et 15 jours pour la marge.

## 2. Message d'invitation (à copier)

> Salut ! Je prépare la sortie de **Kalis Track**, une appli d'entraînement gratuite (street workout, streetlifting, muscu, mobilité), sans compte ni pub, qui fonctionne hors ligne. Il me faut des testeurs pendant **15 jours** avant la publication.
> Ce qu'il te faut : un téléphone Android et un compte Google. Tu dois avoir 18 ans ou plus.
> Ce que je te demande : rester inscrit au test 15 jours (même si tu ne l'utilises pas tous les jours), faire au moins 2 ou 3 séances, et m'envoyer ton avis depuis l'appli (Réglages → À propos → Donner mon avis).
> L'appli ne collecte rien : tout reste sur ton téléphone.
> Si tu es partant, envoie-moi l'adresse de ton compte Google Play et je t'envoie le lien.

## 3. Mode d'emploi d'installation (testeur)

1. Donne l'adresse de ton compte Google (celle du Play Store) à l'organisateur ; il l'ajoute à la liste des testeurs.
2. Ouvre le **lien d'inscription au test** reçu, connecte-toi avec ce compte, puis touche **« Devenir testeur »**.
3. Touche le lien **« Télécharger sur Google Play »** (ou cherche Kalis Track dans le Play Store avec ce compte ; la mise à disposition peut prendre quelques heures).
4. Installe, ouvre l'application et suis le démarrage (2 minutes).
5. **Ne te désinscris pas** pendant 15 jours. Les mises à jour arrivent par le Play Store.
6. Pour donner ton avis : Réglages → À propos → **Donner mon avis** → choisis le scénario, écris, puis « Partager mon avis » (messagerie, e-mail…). Tu vois exactement le texte envoyé.

Testeur qui avait installé un APK hors Play Store : même signature, l'installation Play Store se fait par-dessus ; exporter d'abord une sauvegarde par prudence.

## 4. Retour intégré à l'application

Réglages → À propos → **Donner mon avis** (`FeedbackScreen`) : formulaire local jamais enregistré ; scénario, note 1-5 facultative, « ce qui marche », « ce qui bloque », « autre » ; version cochée par défaut, repère de niveau et mode prudent décochés ; jamais d'historique, de charge, de poids ni de réponse de santé ; aperçu exact puis partage par le menu Android ou copie. Aucun serveur.

## 5. Scénarios à tester par profil

| Profil | Scénario | Attendu |
| --- | --- | --- |
| Tous | Démarrage : âge, objectifs, jours, lieux, repère, santé (accepter puis refuser sur un second essai), mode | Avertissement visible ; moins de 18 ans refusé ; programme généré ; mode prudent si refus |
| Débutant (0-9 pompes) | Première séance guidée, parcours d'habitude (20 min), séance « 10 minutes, ça compte » | Consignes claires, démonstrations lisibles, victoires sans avalanche de chiffres |
| Intermédiaire | Une semaine complète, bilans Koach (sommeil, forme facultatifs), « J'ai seulement 30 minutes », échange d'exercice | Propositions compréhensibles, rien ne change sans tap (mode Assisté) |
| Expert / compétiteur | Séance lourde lestée, estimations, test d'un maximum, programme « Préparer une compétition » | Charges cohérentes, progression visible, pas de test maximal en mode prudent |
| Senior (65 ans et plus) | Démarrage avec une année ≥ 65 ans | Mode prudent d'office, avis médical conseillé, charges plafonnées |
| Tous | Noter une douleur 5/10 trois séances de suite sur un mouvement | Pas de hausse, allègement proposé, renvoi vers un professionnel à la 3ᵉ ; « Douleur ou malaise ? » dans les options de séance |
| Tous | Export d'une sauvegarde, suppression des données, import | Tout revient ; données de santé présentes dans l'export |
| Tous | Texte à 200 %, TalkBack, thème clair, réduction des animations | Rien de coupé ni d'illisible |
| Tous | Rappels (jours d'entraînement seulement), pause vacances | Aucun rappel un jour de repos |

## 6. Tableau de suivi des retours

| # | Date | Testeur (pseudo) | Profil | Scénario | Gravité (bloquant / gênant / mineur / idée) | Description | Reproduit ? | Ticket | Statut (ouvert / corrigé en x.y.z / refusé) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | | | | | | | | | |

Suivi des inscriptions : colonne par jour J1-J15, nombre de testeurs inscrits (≥ 12 chaque jour).

## 7. Critères de passage en production

1. Au moins **12 testeurs inscrits sans interruption pendant 14 jours** (règle Google Play, §1).
2. **Aucun retour « bloquant » ouvert** (plantage, perte de données, impossible de finir le démarrage ou une séance, texte de santé erroné).
3. Au moins un testeur par profil (débutant, intermédiaire, expert, senior) a terminé ses scénarios.
4. Export → suppression → import vérifié par au moins 2 testeurs sans perte.
5. Aucune allégation médicale dans la fiche Play Store (`GOOGLE_PLAY.md`) ; déclarations remplies ; URL de la politique en ligne.
6. Registre de validation relu par le propriétaire (lignes P1 : relues ou limite assumée par écrit).
7. Build signé sur `main` réussi pour la version candidate ; versionCode supérieur à celui du test.
