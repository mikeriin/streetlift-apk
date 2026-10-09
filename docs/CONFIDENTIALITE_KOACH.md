# Kalis Track 3.0.0 — Koach : données et confidentialité (KT-036)

**Document préparatoire — 26 septembre 2026.** Il décrit ce que Koach enregistre, où, pourquoi et comment l'utilisateur le contrôle. **Il ne tranche pas la qualification juridique** (données de santé ou non, base légale, obligations d'information) : les points à faire valider par une personne compétente (juriste, délégué à la protection des données) sont listés au §6.

## 1. Principe

- **Tout est local** : Koach calcule sur le téléphone, à partir du journal de l'application. Aucun compte, aucun serveur, aucune analyse d'audience, aucun modèle en ligne, aucune bibliothèque d'apprentissage automatique. Le code de Koach (`lib/koach_*.dart`) n'utilise aucune API réseau.
- **Désactivé par défaut** (D6) : rien n'est demandé ni enregistré par Koach avant son activation explicite (Réglages → Koach), précédée d'une explication.
- **Questionnaires facultatifs** (D14) : désactivés tant que l'information du §3 n'a pas été acceptée ; « Passer » toujours possible ; aucune fonction ne dépend d'une réponse.

## 2. Données enregistrées par Koach

| Donnée | Quand | Usage | Nature |
| --- | --- | --- | --- |
| Difficulté d'une série (`effort`, échelle Échec → Facile ou RIR/RPE) | À la validation d'une série (obligatoire sur la 1re et la dernière série des 4 mouvements principaux, Koach actif) | Estimation du niveau, suggestions de charge | Donnée d'entraînement |
| Série écartée (`excluded`) | Sur demande (incident) | Exclure la série des estimations | Donnée d'entraînement |
| Prescription affichée, suggestion appliquée ou refusée (`prescribed`, `koach`) | À la première validation ; au choix | Historique daté | Donnée d'entraînement |
| Pesées datées (`weighIns`) | Saisie de l'utilisateur ; modification du poids dans Références | Calcul des mouvements lestés (poids du corps + lest) | **Donnée corporelle — à qualifier (§6)** |
| Historique des valeurs de pilotage (`history`) | Activation, saisie, proposition acceptée, test | Historique daté, plafonds de progression | Donnée d'entraînement |
| Décisions (`decisions`) : acceptations et refus datés | Au choix | Ne pas reproposer une proposition refusée | Donnée d'usage |
| Verrous, matériel, objectifs, adaptations de structure, allègements | Réglages et choix de l'utilisateur | Paramètres des propositions | Préférences |
| **Sommeil** (tranche horaire), **forme** (0-10) avant la séance | Questionnaire facultatif | Proposer un volume réduit (jour de fatigue, D25) | **Donnée de santé potentielle (§6)** |
| **Douleur** (0-10) par mouvement principal, au bilan | Questionnaire facultatif | Ne proposer aucune hausse ; proposer un allègement temporaire (D26) | **Donnée de santé potentielle (§6)** |

Ne sont **jamais** enregistrés : estimations, courbes, biais, états du moteur (recalculés à chaque ouverture depuis le journal, D31) ; localisation ; identifiants de l'appareil ; contacts ; données d'autres applications.

## 3. Information affichée avant les questionnaires (texte de l'application)

> Sommeil, forme et douleur peuvent être des données de santé. Ces questions sont facultatives (« Passer » est toujours possible). Tes réponses restent sur ce téléphone : aucune n'est envoyée. Elles figurent dans l'export de sauvegarde et sont effacées avec les données de l'application ; tu peux aussi les supprimer seules. Koach s'en sert uniquement pour proposer un volume réduit (sommeil, forme) ou aucune hausse de charge (douleur).

Boutons : « Ne pas activer » / « J'ai compris, activer ». La douleur au-dessus de 3/10 affiche le rappel « Une douleur qui persiste relève d'un professionnel de santé. » Koach n'établit aucun diagnostic et ne demande jamais l'arrêt (D26).

## 4. Où sont les données, combien de temps

| Lieu | Contenu | Contrôle de l'utilisateur |
| --- | --- | --- |
| Stockage privé de l'application (document `kalis_state_v3`) | Toutes les données du §2 | Réglages → Sauvegardes → « Supprimer les données de l'application » (tout, y compris Koach) ; Réglages → Koach → « Supprimer mes réponses aux questionnaires » (sommeil, forme, douleur seuls ; visible dès qu'une réponse existe, même Koach désactivé) ; suppression d'une pesée (écran Pesées, accessible tant qu'une pesée existe) ; « Effacer l'historique » d'une séance efface aussi ses réponses et décisions Koach |
| Fichier d'export (emplacement choisi par l'utilisateur), texte copié | Section `koach` et champs de série | Fichier **non chiffré** (déjà indiqué dans l'application) : l'utilisateur choisit où il le range et avec qui il le partage |
| Sauvegarde Android (Google), si activée sur le téléphone | Données de l'application, dont Koach (décision KT-016 : sauvegarde système conservée) | Paramètres Android ; l'application ne peut ni la déclencher, ni la vérifier, ni l'effacer (texte déjà présent dans Réglages → Sauvegardes) |

Durée : jusqu'à suppression par l'utilisateur (aucune purge automatique). Désactiver Koach ne supprime rien : l'application reprend son fonctionnement 2.x et les données restent disponibles si Koach est réactivé.

## 5. Garanties techniques vérifiables

- Code : aucun appel réseau dans `lib/koach_*.dart` ; aucune dépendance ajoutée par L7 (`pubspec.yaml`).
- Manifeste Android principal : aucune permission réseau (`android.permission.INTERNET` seulement dans les manifestes `debug` et `profile`, pour les outils de développement Flutter). Le manifeste final de l'APK signé est archivé par le build (`android-artifacts.json`, liste des permissions) : voir `LIVRAISON_L7.md` pour le relevé du build 3.0.0.
- Import : une section `koach` hors contrat refuse l'import entier ; au démarrage, une entrée illisible est ignorée et signalée (écran Koach), le reste est chargé.
- Tests : `test/l7_koach_store_test.dart` (export, import, effacement, suppression des réponses), `test/l7_koach_screens_test.dart` (information préalable avant activation des questionnaires).

## 6. Points à faire valider (non tranchés)

1. **Qualification** : sommeil, forme, douleur (et poids du corps) sont-ils des données concernant la santé au sens du RGPD (art. 4-15 et 9) dans ce contexte d'usage personnel et local ?
2. **Responsable de traitement** : une application sans serveur ni collecte par l'éditeur traite-t-elle des données « pour le compte » de quelqu'un ? Quelles obligations restent à l'éditeur (information, fiche de la boutique d'applications, section « Sécurité des données » de Google Play) ?
3. **Base légale et consentement** : l'information du §3 et l'activation explicite suffisent-elles, ou faut-il un consentement explicite distinct (art. 9-2-a) et sa trace ?
4. **Sauvegarde Android** (KT-016) : faut-il exclure les réponses aux questionnaires de la sauvegarde système (règles `dataExtractionRules`), au prix d'une perte à la réinstallation ?
5. **Export non chiffré** : un avertissement spécifique aux réponses de santé est-il nécessaire lors de l'export ?
6. **Mineurs** : l'application ne vérifie pas l'âge ; faut-il réserver les questionnaires aux adultes ?
7. **Textes** : relecture des libellés (information, rappel « professionnel de santé ») par une personne qualifiée ; aucun vocabulaire médical ni promesse de résultat (D3).
8. **Validation sportive** : les règles et paramètres de Koach (docs/CONTRAT_L7.md §11) sont à éprouver sur le terrain et à faire valider par un préparateur physique compétent.
