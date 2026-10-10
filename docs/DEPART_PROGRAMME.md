# Départ du programme et références personnelles (L4 — KT-006, KT-007)

Version 2.5.8. Décisions du propriétaire du 26/09/2026 (Europe/Paris) :

| Sujet | Décision retenue |
| --- | --- |
| Date de départ | La date choisie est **S1 · J1**, quel que soit le jour de la semaine. J1 à J7 suivent ensuite jour après jour ; les semaines s'enchaînent sans décalage automatique. |
| Bornes | Départ entre **280 jours avant** et **365 jours après** aujourd'hui (bornes incluses). Report possible (« Plus tard »). |
| Références inconnues | **Inconnues par défaut**, « Je ne sais pas » accepté partout ; les accessoires se complètent plus tard. Aucune valeur d'exemple n'est enregistrée. |
| Installations existantes | **Calendrier gardé** (départ = 13/07/2026) et **références gardées** (« à vérifier », toujours utilisées). Vérification proposée, jamais imposée. Départ modifiable dans Réglages, avec aperçu de l'effet, sans remise à zéro. |

## 1. Calendrier

Trois notions distinctes :

| Notion | Où | Change avec le départ ? |
| --- | --- | --- |
| Identifiants du programme : `S<n>-J<j>`, identifiants d'exercices | asset `programme_v33.json.gz`, clés du journal | **Jamais** |
| Calendrier prévu : date de chaque S·J | calculé : `départ + (n − 1) × 7 + (j − 1)` jours civils | Oui (c'est son rôle) |
| Dates réelles : fin de séance, séries, résultats WOD | journal (`finishedAt`, `completedAt`, `at`) | **Jamais** |

- `Program.start` (date civile) est la seule donnée ajoutée ; `null` = programme non démarré. L'ancrage de l'asset (`meta.anchorMonday` = 13/07/2026) n'est plus utilisé pour le calendrier affiché ; il sert seulement à la migration et aux anciennes séances sans date enregistrée (`legacyDateFor`, voir §4).
- Calculs en **jours civils** (`Program.civilIndex`, date UTC à minuit) : les passages heure d'été / heure d'hiver ne décalent jamais un jour ; fin de mois, fin d'année, 29 février testés.
- **Avant le départ** : l'accueil affiche « Départ le … (S1 · J1) dans N jours » ; semaine 1 consultable ; aucun rappel avant S1 · J1.
- **Pendant** : semaine et jour courants = position dans le calendrier personnel.
- **Après S40 · J7** : « Programme terminé le … » ; pas de semaine 41, pas de nouveau cycle ; l'accueil reste borné à la semaine 40 ; historique consultable ; aucun rappel.
- **Non démarré** (installation neuve, ou « Plus tard ») : bandeau « Programme non démarré » + « Choisir mon départ » ; les semaines restent consultables avec « dates à définir » ; aucun rappel ; aucune date prévue n'est inventée (`dateFor` refuse sans départ).
- Pas de décalage automatique, pas de programmation adaptative : une séance manquée ne déplace rien.

## 2. Parcours approuvé

**Accueil** (bandeau dans la liste des journées, lisible à 200 %) → **Départ du programme** (aussi dans Réglages → Programme) :

1. Date de S1 · J1 : aujourd'hui proposé, sélecteur borné −280 / +365 jours ; aperçu de la fin (S40 · J7) et de la position du jour.
2. Premier départ uniquement : références facultatives (poids du corps, 1RM de travail des 4 mouvements, 5 maxima en répétitions), **vide = « Je ne sais pas »**. Aucun test maximal exigé.
3. « Confirmer le départ » : rien n'est annoncé avant l'écriture acceptée (file d'écriture L2). Écriture refusée → message, état précédent rétabli en mémoire, écran conservé, nouvel essai possible. Double appui : une seule confirmation. « Plus tard » / retour système : rien n'est enregistré.
4. Installation déjà démarrée : « Départ actuel » (+ « calendrier d'origine conservé » pour une migration), **effet du changement** (« Aujourd'hui : S11 · J6 → S1 · J6 »), rappel que les séances faites gardent leur S·J et leur date réelle ; références non touchées. Même date : bouton inactif.
5. Après enregistrement : rappels replanifiés (mêmes identifiants S·J, sans doublon). Une erreur de programmation native reste affichée dans Réglages → Notifications et se corrige sans effacer le départ.

Aucune séance, série, résultat, XP, crédit ou droit n'est créé par ce parcours.

## 3. Références : provenance

| Provenance | Stockage | Affichage | Utilisée dans les calculs |
| --- | --- | --- | --- |
| **Non renseignée** | absente de `pilotage` | « Non renseigné », champ vide | Non : charge « à renseigner », volume « N × ? reps », attribut sans valeur, aucune pré-saisie |
| **Renseignée** (`set`) | valeur + `referenceStatus[ref] = "set"` | valeur | Oui |
| **Historique** (`historic`) | valeur + `"historic"` | « À vérifier · valeur d'une version précédente » + « C'est bien ma valeur » / « Je ne sais pas » | Oui, telle quelle |

- Une installation neuve n'a **aucune** référence : les valeurs du classeur (ex. poids 71,5 kg) ne sont plus copiées.
- Saisir une valeur (même égale à l'ancienne valeur embarquée) la rend « renseignée ». Confirmer une valeur historique ne change pas le nombre. « Je ne sais pas » supprime la valeur ; « Effacer toutes mes références » les rend toutes non renseignées (séances, historique et récompenses conservés, calendrier inchangé).
- Saisie : virgule ou point, 2 décimales au plus, 0 à 10 000 ; poids du corps > 0 ; vide, texte, `NaN`, infini, notation exponentielle refusés (valeur précédente gardée). Zéro reste une valeur légitime (lest nul), distincte d'une valeur absente.
- **Unités** : références toujours saisies et stockées en **kg** (ou répétitions). Le réglage « charges en livres » ne convertit que l'affichage des charges suggérées : aucune conversion aller-retour sur les valeurs stockées, donc aucune dérive.
- **Conventions** (inchangées) : traction, dips et muscle-up lestés = **charge ajoutée** au poids du corps (charge suggérée = `(PdC + 1RM) × % − PdC`) ; back squat = **charge totale** de la barre.
- Une référence renseignée n'est jamais une séance : aucune série validée, aucun résultat, aucune récompense.
- Attributs de la fiche : force calculée seulement si le poids du corps est connu ; technique (muscle-up) à partir de la référence connue ; sinon l'attribut reste indisponible au lieu d'utiliser 70 kg.

## 4. Migration (idempotente, sans étape provisoire)

| Situation au lancement de 2.5.8 | Résultat |
| --- | --- |
| Document unique `kalis_state_v3` sans `programStart` (≤ 2.5.7) | Départ **13/07/2026**, origine `migration` ; références du fichier conservées, toutes « historiques » ; journal, WODs, crédits, droits, sélections L3 inchangés |
| Anciennes clés séparées (≤ 2.2 : `pilotage_v1`, `logs_v1`, `settings_v1`, WODs, droits…) sans document unique | Idem : valeurs embarquées complétées par les valeurs sauvegardées, toutes « historiques » ; départ 13/07/2026 |
| Aucune de ces clés (seulement le catalogue/version écrits au tout premier lancement) | Installation **neuve** : non démarrée, références inconnues |
| Document 2.5.8+ | Lu tel quel (départ, origine, provenances) |

- Le départ n'est **jamais** déduit de la première séance, de la date d'installation ni de la date d'import.
- La migration relue une seconde fois donne le même état (tests). Elle ne crée aucun crédit ni droit : les crédits restent ceux du registre L3 (`creditGrants`), l'XP est recalculée sur le même journal.
- **Anciennes séances sans date enregistrée** (`finishedAt` absent) : leur date de repli reste celle du calendrier d'origine (`legacyDateFor`, 13/07/2026), **indépendante du départ** : changer de départ ne redate jamais l'historique.
- Changer de départ ensuite : les séances faites gardent leur clé S·J (donc leur statut « faite ») et leur date réelle ; seule la position « aujourd'hui » et les dates prévues changent.

## 5. Sauvegardes (format 3, champs optionnels)

```json
"programStart": {"status": "set", "date": "2026-07-13", "origin": "migration"},
"programStart": {"status": "pending"},
"referenceStatus": {"B4": "set", "B8": "historic"}
```

| Fichier importé | Résultat |
| --- | --- |
| 2.5.8+ (départ défini ou en attente) | Restauré tel quel : départ, origine, provenances. Restaurer sur un autre téléphone n'est pas un nouveau départ. |
| Antérieur à 2.5.8 (sans ces champs) | Migré comme ci-dessus : 13/07/2026, références « historiques » ; jamais « aujourd'hui », jamais traité comme un nouvel utilisateur |
| Valeur sans provenance (fichier retouché) | Conservée « historique » |
| Invalide : date impossible (29/02/2027, format autre que `AAAA-MM-JJ`), année hors 2000-2100, origine inconnue, `pending` avec autre champ, statut autre que `set`/`historic`, provenance sans valeur, clé inconnue marquée `set`, poids du corps nul | **Refusé en entier**, rien n'est modifié (départ et références gardés) |

L'aperçu d'import affiche le départ du fichier et celui du téléphone, et le nombre de références renseignées / à vérifier. L'effacement local (L2b) remet l'état d'installation : non démarré, aucune référence. Aucun stockage parallèle : tout est dans le document unique, sa copie de secours et l'export.

## 6. Rappels

- Uniquement avec un départ défini ; de S1 · J1 à S40 · J7 ; identifiants `1000 + (n − 1) × 7 + j`, contenu `S<n>-J<j>`.
- Le départ fait partie de la signature de planification : un changement (Réglages, import, effacement) replanifie les mêmes identifiants, supprime les obsolètes, sans doublon.
- Une ancienne notification ouverte après un changement ouvre toujours la **journée S·J** qu'elle nomme (déjà faite → son historique), à froid comme à chaud.

## 7. Limites connues

- Les titres « Touche-à-tout » et « Gardien du repos » portent sur la **saison en cours** : ils suivent la position dans le calendrier (comportement antérieur). Aucun crédit n'en dépend.
- L'objectif hebdomadaire automatique utilise le nombre de journées de la semaine de programme courante : il suit le calendrier. Les crédits de semaine complète (3 activités par semaine civile) n'en dépendent pas.
- Changer le départ vers une date antérieure à des séances faites garde ces séances faites (clé S·J) : les rappels de ces journées restent supprimés.
- Aucun contrôle sur appareil n'a été exécuté pour ce lot.
