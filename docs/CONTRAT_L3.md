# Kalis Track — Contrat L3 : économie et essai WOD (KT-003, KT-004, KT-005)

**Version : 2.5.5+56 — 25 septembre 2026, Europe/Paris.**
Ce document sépare trois choses : les **règles approuvées** (par le propriétaire, ou déjà écrites et publiées dans le README), les **choix d'implémentation** faits par l'IA dans le cadre de ces règles, et les **propositions en attente** (non appliquées).

Nature des preuves : « déclaration du propriétaire » = réponse écrite du propriétaire ; « test automatique » = test Dart exécuté en CI ; « GitHub » = résultat d'un run ; « appareil » = essai sur téléphone (aucun à ce jour pour L3).

## 1. Tableau de contrat

| Sujet | Comportement avant L3 (2.5.4) | Règle approuvée | Décision manquante |
| --- | --- | --- | --- |
| Tentative d'essai lancée avant minuit (KT-003) | `canRun` revérifié au score et à chaque reconstruction : après minuit, score refusé, fiche d'achat affichée | Une tentative engagée peut être terminée et enregistrée après minuit, sans rendre le WOD acquis ni ouvrir un accès temporaire illimité (demande L3) | Aucune |
| Nombre de tentatives de l'essai | Non défini ; illimité de fait | **Illimitées jusqu'à minuit** (déclaration du propriétaire, 25/09/2026) | Aucune |
| Choix de l'essai du jour (KT-004) | Recalculé depuis le jour **et** l'état (niveau, achats, résultats) ; clé invalidée à chaque notification | Un essai par jour civil local, stable pour la journée (README) ; jamais tenté | Aucune |
| Achat de l'essai | L'achat retirait le WOD du tirage : un autre essai pouvait apparaître le jour même | Acquis tout de suite ; **aucun second essai gratuit** le même jour (demande L3) | Aucune |
| Aucun WOD jamais tenté au niveau ±1 | Un WOD déjà tenté pouvait être proposé | **Élargir à ±2, puis à tout le catalogue ; sinon pas d'essai, avec un message** (déclaration du propriétaire) | Aucune |
| Vitrine hebdomadaire | Recalculée selon le niveau courant, pouvait changer dans la semaine | Lundi → dimanche ; « **un WOD acheté laisse sa place au suivant** » (README, règle existante) | Aucune |
| Crédits après correction/suppression (KT-005) | Recalculés à la baisse ; `max(0, …)` masquait un écart | **Option C** : crédits gagnés jamais repris ; XP et niveau recalculés (propriétaire, L2) | Aucune |
| Comptabilité des gains | L2 : « plus haut total atteint » ; une vraie nouvelle semaine ne payait rien sous ce plus haut | **Registre par gain** : une vraie nouvelle activité paie, un palier ou une semaine déjà payés ne repaient pas (déclaration du propriétaire) | Aucune |
| Solde incohérent (dépensé > gagné) | Borné à 0, écart invisible | **Afficher le déficit** ; achats bloqués ; droits conservés ; aucun crédit compensatoire (déclaration du propriétaire) | Aucune |
| Import | Remplacement complet (L2) | Remplacement, jamais fusion (L2, rappelé par L3) | Aucune |
| Manipulation de l'horloge | Non traitée | — | **Oui, facultatif** : voir §5 (limites documentées, pas de contre-mesure demandée) |
| Survie d'une tentative à l'arrêt du processus | Non | Hors L3 : chrono et reprise après redémarrage = L4b | Traitée en L4b |

## 2. Règles approuvées et comportement implémenté

### 2.1 Tentative d'essai (KT-003)

- **Démarrer** un essai crée une *tentative* : identifiant aléatoire, WOD, heure de début (`startAttempt`). Elle n'existe qu'en mémoire, pour cet écran.
- **Terminer** : le score est accepté si le WOD est jouable maintenant (acheté ou essai du jour) **ou** si la tentative ouverte porte sur ce WOD (`canFinish`). Après minuit, l'écran reste donc sur le chrono et la saisie du score s'ouvre.
- Le droit est attaché à **cette tentative**, pas au WOD : quitter l'écran l'abandonne (`abandonAttempt`). Rouvrir le WOD après minuit montre la fiche d'achat. Aucun accès n'est accordé à une nouvelle tentative.
- **Un seul résultat par tentative** : le résultat porte l'identifiant de la tentative (`attempt`, exporté). Un second envoi (double appui, retour d'erreur, nouvel essai d'écriture) ne crée ni second résultat, ni seconde XP, ni seconde récompense. La feuille de score ignore aussi un second appui.
- **Écriture refusée** : le résultat reste affiché et en mémoire, marqué non sauvegardé ; message « non enregistré » avec **Réessayer** (`retrySave`). La récompense (écran de progression) n'est montrée qu'après écriture acceptée. Aucun succès n'est annoncé avant.
- La date du résultat est l'**heure de validation** (00 h 01 dans l'exemple) : c'est l'heure réelle d'enregistrement. La tentative ne consomme rien : l'essai reste un essai (pas de crédit, pas de déblocage).
- Achat du WOD pendant la tentative : la validation se fait normalement, le WOD est acquis.

### 2.2 Essai du jour (KT-004)

- État **persisté et exporté** : `trialOfDay = {day: "AAAA-MM-JJ", wod: id | null}` (jour civil local).
- Choisi une fois par jour, à la première lecture : WOD **verrouillé** du catalogue, **jamais tenté**, hors vitrine, niveau cible ±1 ; sinon ±2 ; sinon tout le catalogue ; sinon `wod: null` et le message « Pas d'essai du jour : aucun WOD jamais tenté ne reste à découvrir. Le prochain choix a lieu demain. »
- Ensuite il **ne change plus de la journée** : ni achat, ni résultat, ni changement de niveau ou de références, ni relance ne le modifient. Un import remplace tout, sélection comprise : l'essai devient celui du fichier (voir §5).
- **Achat de l'essai** : le WOD est acquis immédiatement (affiché possédé) ; l'essai du jour reste ce WOD (déjà acquis), donc **aucun autre essai gratuit** ce jour-là. Prix : remise d'essai (−1, plancher 1) si le WOD a été terminé, prix figé à l'achat (L2).
- **Changement de jour** : nouveau choix seulement si la date locale est **strictement postérieure** à celle enregistrée. Heure d'hiver/été : jour civil (pas de durée de 24 h). Changement d'année : comparaison de dates ISO.
- **Migration** (sauvegarde ou état sans `trialOfDay`) : si un WOD verrouillé du catalogue a un résultat daté d'aujourd'hui, il est repris comme essai du jour (l'essai était en cours) ; sinon un choix normal. Aucun historique d'essai n'est inventé pour les jours passés, aucun crédit n'est créé.

### 2.3 Vitrine de la semaine (KT-004)

- État **persisté et exporté** : `weeklyShowcase = {week: lundi "AAAA-MM-JJ", ids: [≤ 3]}`.
- Choisie le premier affichage de la semaine (lundi → dimanche, heure locale) : trois WODs verrouillés de formats différents, niveau cible −1 à +2 ; ne change plus de la semaine (niveau, relance, notifications sans effet).
- Règle existante appliquée : **un WOD acheté laisse sa place au suivant**, choisi de façon déterministe pour la même semaine, hors WODs déjà présentés et hors essai du jour, en évitant les formats déjà affichés. Les autres WODs gardent leur place.
- Nouvelle semaine : seulement si le lundi est strictement postérieur (recul d'horloge sans effet). Semaine à cheval sur deux années : identifiée par son lundi (ex. 28/12/2026 puis 04/01/2027).
- Migration : absence de `weeklyShowcase` → choix normal pour la semaine en cours.

### 2.4 Crédits (KT-005)

Quatre notions séparées :

| Notion | Source | Varie après correction/suppression ? |
| --- | --- | --- |
| XP et niveau | Recalculés depuis le journal | Oui (peut baisser) |
| **Gains attribués** (`creditGrants`) | Registre persistant, un identifiant par gain : `level:N`, `chapter:<clé>`, `boss:<id>`, `week:<lundi>`, `carry:l2` | Non : jamais repris |
| Dépenses | Prix payés (`unlockedWods`, montant figé à l'achat) | Non |
| Droits | WODs débloqués et droits historiques (`legacyGrants`, règle d'usage KT-014) | Non |

- **Crédits gagnés** = somme du registre + gains justifiés par le journal pas encore inscrits (ils sont inscrits à l'écriture suivante acceptée, au chargement et à l'export). **Solde** = gagnés − dépensés, **sans plancher**.
- **Anti-double attribution** : un identifiant n'est payé qu'une fois. Supprimer puis refaire une séance → la semaine et le palier existent déjà : rien de plus. Une **vraie nouvelle semaine** complète (autre lundi) → +1. Un palier perdu puis atteint de nouveau → rien. Un nouveau palier jamais atteint → payé. Montants : barème actuel inchangé (niveau `1 + 2 × niveau + 3 × floor(niveau/5)`, chapitre +3, boss +5, semaine complète +1).
- **Déficit** : si les dépenses dépassent les gains (ancienne sauvegarde, ancien calcul), le solde s'affiche « déficit de N crédits » avec une explication ; les achats sont bloqués ; les WODs acquis restent acquis ; aucun crédit compensatoire, aucune dette ajoutée.
- **Migration** (état ou fichier sans `creditGrants`) : registre = gains justifiés par le journal ; si le plus haut L2 (`creditsEarnedMax`) est supérieur, l'écart est conservé tel quel sous `carry:l2`. Aucun crédit créé ni retiré ; répétée sur le même fichier, elle donne le même registre.
- **Import = remplacement** : le registre du fichier remplace le registre courant. Importer un état plus ancien rend son registre (et ses achats) ; pas de fusion. Réimporter le même état ne crée aucun gain.
- **Suppression des données** : registre, essai et vitrine repartent de zéro (3 crédits du niveau 1).

## 3. Format de sauvegarde (toujours format 3)

Champs optionnels ajoutés : `creditGrants` (objet identifiant → entier 0 à 1 000 000, clés contrôlées), `trialOfDay` (`day` au format `AAAA-MM-JJ`, `wod` chaîne ou null), `weeklyShowcase` (`week` au format `AAAA-MM-JJ`, `ids` : au plus 3 chaînes), `attempt` sur un résultat de WOD (≤ 64 caractères). `creditsEarnedMax` reste écrit pour les versions 2.5.2 à 2.5.4. Toute valeur invalide fait refuser l'import sans rien modifier. Les versions antérieures ignorent ces champs.

L'aperçu d'import affiche « Crédits gagnés » : total du registre du fichier, ou « recalculés depuis son journal » s'il n'en contient pas.

## 4. Choix d'implémentation (dans le cadre des règles)

- Les sélections sont faites à la première lecture du jour/de la semaine, puis écrites (pas au démarrage) : un démarrage n'écrit rien de plus qu'avant.
- La tentative n'est pas persistée : un arrêt du processus pendant l'essai la perd (le chrono non plus n'est pas restauré — L4b). Après minuit, relancer l'application ne permet donc pas de terminer.
- Heure du résultat = heure de validation (et non de début).

## 5. Limites connues

- **Horloge du téléphone** : avancer la date donne l'essai et la vitrine du lendemain/de la semaine suivante plus tôt ; la reculer ensuite ne les change pas (pas de nouveau tirage). Aucune contre-mesure (horloge réseau) : l'application est hors ligne. Changer la date ne crée aucun crédit : les gains dépendent des séances et semaines enregistrées.
- **Restauration d'un ancien état** (import d'un fichier, sauvegarde Android) : remplacement complet, registre compris ; le registre contenu dans un fichier ne peut pas empêcher ce retour en arrière (règle L2).
- **Import d'un fichier sans sélection** (antérieur à 2.5.5) ou d'un jour passé : le choix du jour est refait selon les règles de migration, à partir de l'état importé ; il peut désigner un autre WOD que l'essai affiché avant l'import. Ce n'est possible qu'en remplaçant toutes les données.
- **Fuseau** : jour et semaine civils du fuseau courant ; un changement de fuseau vers l'ouest ne recule pas la sélection (même règle que le recul d'horloge).
- Crédits inscrits « à l'écriture » : si l'application est tuée avant toute écriture, un gain non inscrit reste justifié par le journal et est inscrit au lancement suivant.

## 6. Propositions en attente (non appliquées)

- Persister la tentative d'essai et le chrono pour survivre à un redémarrage (**L4b**).
- Horloge : éventuelle détection d'un recul important de la date (message), sans blocage — **à arbitrer**, non demandé.
