# Contrat de Koach 1.0 (`kalis_adapt` 1.0.0)

Rédigé le 09/10/2026, remis en accord avec le code le 10/10/2026 (référence Python `packages/kalis_adapt/reference/`, branche `moteurs`, arbre de travail du lot KM1).
Fichier de paramètres lu : `params/koach_params_v1.json`, SHA-256 `e9e315289def5ea0c5c0f5207005002e6b3d317d4786dc3d595e25359d72c47e`, 305 clés (6 à la racine, 299 dans les onze sections). L'empreinte sera recalculée à la livraison du lot si le fichier change d'ici là.

Ce contrat décrit le code tel qu'il est. Quand le code, un commentaire ou le cahier divergent, le contrat suit le code et signale l'écart dans l'annexe A. Le lot KM2 porte ce contrat en Dart ; la parité visée est de 1e-9 (cahier, « Contraintes »).

Conventions : `ln` = logarithme népérien ; « capacité » = capacité à frais d'un exercice, dans son unité (1RM de charge totale en kg, répétitions maximales, secondes de maintien maximal, ou capacité d'endurance) ; `clamp(x, a, b)` borne x. Les renvois au code citent le fichier et la fonction (`modele._observer`), sans numéro de ligne : les numéros changent d'une version à l'autre.

---

## 1. Objet, périmètre, vocabulaire

### 1.1 Objet

Koach 1.0 est un moteur hors ligne en quatre parties :

1. **Estimation** : un filtre gaussien sur un état latent. L'état regroupe 10 qualités, la réponse à l'entraînement, des sensibilités à la fatigue, la mesure de la note et la courbe répétitions-charge, plus 3 composantes par exercice suivi.
2. **Prescription** : la séance et la série suivante (charges, plages, séries, tests, tentatives).
3. **Garde-fous** : les règles de sécurité de `kalis_adapt` 0.3.1, en contraintes dures.
4. **Extensions** : planification hebdomadaire, surveillance hors modèle, adhérence, contrôle dual.

L'état se recalcule en rejouant le journal (`moteur.rejouer`). Les appels de `plan` et les imports de paramètres sont des événements du journal (§ 2.1). Le § 9.5 précise ce qui reste hors journal.

### 1.2 Modules

| Module | Rôle |
| --- | --- |
| `koach/numerique.py` | fonctions numériques portables (erfc, loi normale, appariement de moments, mulberry32, fnv1a32, `cholesky_semi`, `arrondi`) |
| `koach/modele.py` | état, a priori, dynamique, modèles de mesure, mises à jour |
| `koach/securite.py` | état de la douleur par zone, paliers du bilan, conduite sous douleur, poignet, zones fragiles du profil, bas du corps, renvoi vers un professionnel |
| `koach/seance.py` | prescription de séance, cible de série, vrai test, tentatives, techniques, surmenage, lignes d'endurance, mémoire par exercice |
| `koach/moteur.py` | façade `Koach` (`observe`, `posterior`, `plan`, `explain`), classe `Extension`, `rejouer` |
| `koach/planification.py` | extension `Planification` (replanification hebdomadaire) |
| `koach/rupture.py` | extension `Surveillance` (BOCPD, secours, diagnostic, dossier), `importer_parametres`, `appliquer_parametres`, `FIGEES`, `BORNES` |
| `koach/adherence.py` | extension `Adherence` (probit bayésien, forme des propositions) |
| `koach/dual.py` | extension `ControleDual` (hypothèses de réponse, essais N-of-1, contrôle synthétique) |
| `qualites/regles.py` | génération de `vecteurs_qualites_v1.json` (fiches d'exercices) |

### 1.3 Qualités latentes (liste figée, indices 0 à 9)

| Indice | Code | Indice | Code |
| --- | --- | --- | --- |
| 0 | `pousser` | 5 | `endurance_force` |
| 1 | `tirer` | 6 | `explosivite` |
| 2 | `jambes` | 7 | `aerobie` |
| 3 | `tronc` | 8 | `anaerobie` |
| 4 | `figures` | 9 | `mobilite` |

L'ordre est celui de `qualites/regles.QUALITES` et de `params.qualites`. Chaque fiche porte un `vecteur` de 10 charges ≥ 0 de somme 1, arrondies à 4 décimales ; l'arrondi est reporté sur la plus forte charge (`regles.generer`).

### 1.4 Classes de réponse (`modele.CLASSES`)

| Indice | Classe | Exercices (type de la fiche) | Observation |
| --- | --- | --- | --- |
| 0 | `charge` | charge externe mesurable | répétitions et note → réserve (gradué) |
| 1 | `reps` | poids du corps, assisté, élastique | répétitions et note → réserve (gradué) |
| 2 | `tenue` | unité secondes | durée, note ou échec (survie) |
| 3 | `cardio` | famille cardio | demande relative et note (gradué) |
| 4 | `wod` | famille conditionnement | demande relative et note (gradué) |

Les fiches de type `mobilite` ou `autre` ne sont pas suivies : `Modele.piste` renvoie `None` et leurs séries sont ignorées.

### 1.5 Flammes et répétitions en réserve

La note de l'utilisateur est en flammes `f` ∈ {1, …, 10} (`kalis_core` `Flames`).

- Réserve d'une note (`seance.rir_de_flammes`) : `0` si `f ≥ 10`, sinon `(11 − f)/2`.
- Inverse (`seance.flammes_de_rir`) : `1` si `rir ≥ 5` ; sinon `h = ceil(2·rir − 0,5)` ; `h ≤ 0` donne 10, `h = 1` donne 9, sinon `11 − h`.
- Intervalle de réserve **perçue** d'une note (`Modele.bornes_flammes`, ouvert = `mesure.rir_ouvert`) :
  - `f ≥ 10` : `(−∞ ; 0,25]` (posé directement par `modele._serie_force`, `_serie_tenue` et `_serie_endurance`) ;
  - `f = 9` : `[0,25 ; 1,25]`, ou `[0,25 ; 1,5]` pour un noteur entier ;
  - sinon `r = (11 − f)/2` et demi-largeur `d = 0,25` (`0,5` pour un noteur entier) ; si `r ≥ ouvert`, l'intervalle est `[r − d ; +∞)` (catégorie ouverte « 4 ou plus »), sinon `[r − d ; r + d]`.
- **Noteur entier** (`noteur_entier`) : au moins `noteur_entier_notes_min` notes non ratées et inférieures à 10, dont au plus `noteur_entier_part_max` × n à la demi-répétition. Une note à la demi-répétition est une flamme paire (2, 4, 6 ou 8).

---

## 2. Schéma du journal

Le journal est une liste ordonnée d'événements (dictionnaires JSON). `Koach.observe(e)` les ajoute à `koach.journal` dans l'ordre reçu ; `Koach.plan(c)` y ajoute lui-même un événement `plan` (§ 3.3). Le champ `type` est obligatoire. Un type inconnu est journalisé puis ignoré. Le journal est du JSON pur : il survit à un aller-retour `json.dumps` / `json.loads` (vérifié par `tests/test_rejeu_exact.py`).

### 2.1 Événements lus par le moteur

| `type` | Champs (type, unité) | Effet |
| --- | --- | --- |
| `seance_debut` | `jour` (entier, jours depuis le début) ; `bilan` (objet ou absent) ; `poids_kg` (nombre ou absent) ; `contexte` (objet ou absent) | `garde.avancer(jour)` ; si `bilan.pains` n'est pas `None`, `garde.noter_seance(jour, pains, posee=True)` ; `modele.debut_seance` ; `seances.ouvrir` |
| `serie` | `serie` (objet, § 2.2) | `modele.observer_serie`, puis `seances.serie_faite` |
| `seance_fin` | `douleurs` (liste `{zone, intensity}` ou absent) ; `seance` (objet `{sets: [serie…]}`) | `garde.noter_seance(jour, douleurs, posee=False)` si la liste n'est pas vide ; `seances.fermer(seance)` ; `modele.fin_seance()` ; crochets `fin_seance(koach, resume, e)` |
| `seance_manquee` | `jour`, `semaine` (lus par les extensions) | crochets `seance_manquee` seulement |
| `semaine_fin` | `jour` (entier) ; `semaine` (entier, indice de la semaine qui finit) ; facultatifs lus par le contrôle dual : `alerte_hors_modele`, `alerte`, `douleur`, `douleurs` | `modele.avancer(jour)`, `modele.fin_semaine()`, crochets `fin_semaine(koach, ligne, e)` |
| `cran` | `exerciseId` ; `facteur` (> 0) | `modele.changer_cran` |
| `poids` | `poids_kg` | `modele.poids_kg = poids_kg` si la valeur est présente et > 0 ; sinon l'événement est sans effet |
| `charge_manuelle` | `exerciseId` ; `loadKg` (charge externe, kg, obligatoire) ; `reps` ; `rir` | `modele.observer_charge_manuelle` ; sans effet si `reps` est absent ou si la masse totale est ≤ 0 ; `rir` absent vaut 0 |
| `decision` | voir § 2.4 | crochets `decision(koach, e)` seulement |
| `plan` | `contraintes` (objet : forme canonique de `Koach._canonique`, § 3.3) | `Koach._plan(contraintes)` : l'appel de `plan` est refait tel quel (création de pistes, mémoire de séance, budgets, raisons, replanification) ; la sortie n'est pas gardée |
| `parametres` | `fichier` (objet : fichier de paramètres déjà validé) | `rupture.appliquer_parametres(koach, fichier)` (§ 7.3) ; aucune nouvelle validation au rejeu |

Le `jour` de `seance_fin` n'est pas lu : la séance garde le jour de `seance_debut` (`koach.jour`).

**`bilan`** (bilan de santé du jour). Les clés suivantes sont lues ; une clé absente ou `None` vaut « non répondu ».

| Clé | Valeurs |
| --- | --- |
| `overall` | 0 à 5 (neutre 4) |
| `sleepHours` | heures de sommeil |
| `sleepQuality`, `energy`, `mood`, `soreness`, `stress`, `motivation`, `nutrition`, `hydration` | 1 à 5 ; une réponse ≤ 2 compte |
| `pains` | liste `{zone, intensity}` ; liste vide = question posée, aucune douleur ; absente = question non posée |

Codes de zone : `neck`, `shoulder`, `elbow`, `wrist_hand`, `upper_back`, `lower_back`, `chest`, `abdomen`, `hip`, `thigh`, `knee`, `lower_leg`, `ankle_foot`. Le bas du corps (`securite.ZONES_BAS`) regroupe `hip`, `thigh`, `knee`, `lower_leg`, `ankle_foot` ; le poignet est `wrist_hand` (`securite.POIGNET`).

**`contexte`**. Les clés lues :

| Clé | Lue par | Usage |
| --- | --- | --- |
| `semaine` | `seances.ouvrir` | indice global ; sans elle, la semaine n'est pas notée |
| `genre` | `seances.ouvrir`, `verrouillee`, `_surmenage` | `kind` de la semaine du plan |
| `intention` | `seances.ouvrir`, `verrouillee`, `_surmenage` | `intent` de la semaine du plan |
| `jour_evenement` | `seances._item` | booléen ; jour d'épreuve (un test écrit n'est pas reporté un jour de bilan bas) |
| `jours_avant_echeance` | `seances._mesure_utile`, `seances._technique` | entier ; ni mesure à 14 jours ou moins, ni excentrique accentué à `excentrique_echeance_j` jours ou moins |
| `lieu` | `seances._endurance` | lieu du jour ; une course facile de remplacement n'est faisable que si sa fiche admet ce lieu |
| `budget` | `seances._duree_permet_test`, `seances._duree_bornee` | minutes disponibles de la séance ; durée admise = `budget·seance_tolerance + seance_tolerance_min` |
| `manquees` | `seances.ouvrir` | liste `{semaine, genre, items}` des séances manquées depuis la séance précédente, avec leurs items écrits (au moins `exerciseId`, `kind`, `sets`, `targetFlames`, `secondsLow`, `secondsHigh`) ; leur volume écrit compte dans la semaine (retour gradué, § 8.3) |
| `reste_semaine` | `seances._budgets_retour` | liste des items écrits (mêmes champs) de chaque séance restante de la semaine, après celle du jour ; leur volume est réservé (retour gradué, § 8.3). Absente : aucune réserve |

### 2.2 Objet `serie`

Lu par `Modele.observer_serie`, `Seances.serie_faite` et `Seances.fermer`.

| Champ | Type, unité | Lu par | Sens |
| --- | --- | --- | --- |
| `exerciseId` | texte | tous | identifiant de la base (clé des fiches) |
| `slotId` | texte | seance | emplacement ; relie la série au plan servi (`slotId + '.t'` pour un vrai test) |
| `kind` | `work`, `warmup`, `test` | seance.fermer | les échauffements ne comptent pas dans la mémoire (maximums, échec, barres réussies, temps total de l'emplacement) |
| `reps` | entier ≥ 0 | modele, seance | répétitions faites |
| `seconds` | nombre ≥ 0 | modele, seance | durée tenue (tenues) ou durée d'une course |
| `distanceMeters` | nombre ≥ 0 ou absent | seance.fermer | distance d'une course : durée estimée par la vitesse de course, vitesse apprise si la série donne distance et durée |
| `excluded` | booléen | seance.fermer | série écartée de l'historique d'endurance |
| `externalLoadKg` | nombre ≥ 0 ou `None` | modele, seance | charge externe (sans le poids du corps) |
| `flames` | 1 à 10 ou `None` | modele, seance | note ; `None` = série sans note |
| `failed` | booléen | modele, seance | série ratée |
| `target` | objet `{repsLow, repsHigh, secondsLow, secondsHigh, flames, role}` | modele (`flames`), seance (`repsHigh`, `flames`, `role`) | cible servie ; `target.flames` = note préremplie ; `target.role` ∈ `None`, `test`, `attempt` |
| `restSeconds` | s | modele | repos avant la série ; 90 s seulement si le champ est absent ou `None` (un repos de 0 s est gardé) |
| `role` | texte | modele | `test` ou `attempt` marque une mesure (`dernier_test_jour`) |
| `repere` | booléen | modele | série repère (marque une mesure) |
| `demand` | nombre > 0 | modele (cardio, wod) | demande relative écrite (cardio : durée écrite × poids de qualité, en minutes) ; sans elle, la série d'endurance est ignorée par le modèle |
| `doneShare` | 0 à 1 (défaut 1) | modele (cardio, wod) | part faite ; < 0,999 = séance écourtée |
| `dose` | nombre (défaut 1) | modele (cardio, wod) | stimulus ajouté aux trois compteurs de la semaine |
| `fatigueSets` | nombre (défaut 1) | modele (cardio, wod) | équivalent en séries pour les compartiments |

Le banc transmet aussi `setIndex` et `technique`, que le moteur ne lit pas. La docstring de `observer_serie` cite `manual`, `parts` et `assistKg` : ces champs ne sont pas lus (annexe A).

### 2.3 Masse et unité de capacité

Pour un exercice `charge`, la masse vaut `masse = externalLoadKg + fraction × poids_kg`. `fraction` est la part du poids du corps donnée par la fiche ; `poids_kg` vient du profil, d'un `seance_debut.poids_kg` ou d'un événement `poids`. Sans aucune de ces valeurs, 72 kg sont pris sans signalement (annexe A, constat de relecture m14). La capacité est l'e1RM de cette masse totale, comme le demande le cahier (Méthodes § 2). Pour les autres types, la masse vaut 1.

### 2.4 Événements `decision`

Le moteur ne les lit pas ; chaque extension filtre ce qui la concerne.

| Charge utile | Extension | Champs |
| --- | --- | --- |
| `proposition` | Adhérence | `jour` ; `proposition` `{id, type ∈ TYPES, exerciseId, ampleur, charge_kg, reps, rir, contexte {bilan_bas, semaine_allegement, moment, refus_recents}}` ; `accepte` (booléen) ; `raison` ∈ `too_heavy`, `too_light`, `equipment`, `time`, autre ou `None`. Un événement `decision` sans `proposition` est ignoré par l'adhérence. |
| `diagnostic` | Surveillance | `{cause ∈ douleur, moins_de_temps, fatigue, rien ; zone ; intensite ; seances_par_semaine ; duree_max_min}` ; ignoré si aucune alerte n'est levée |
| `essai` | Contrôle dual | `{semaine, cible {qualite | exerciseId}, traites, temoins, contexte {affutage, semaines_avant_echeance, alerte, douleur}, graine, n_bras}` |
| `alerte_hors_modele` | Contrôle dual | booléen ; interrompt l'essai en cours |

Types de proposition (`adherence.TYPES`) : `charge_plus`, `charge_moins`, `volume_plus`, `volume_moins`, `reps_plus`, `reps_moins`, `echange`, `test`, `allegement`. Moments : `debut_de_seance`, `entre_series`, `prochaine_seance`.

### 2.5 Entrées hors journal

Ces entrées sont nécessaires au calcul mais ne sont pas des événements :

- `params` : le fichier de paramètres **initial** (§ 7). Les imports suivants sont journalisés (événement `parametres`).
- `fiches` : `vecteurs_qualites_v1.json`, champ `exercices`. Champs lus par le moteur : `type`, `vecteur`, `ratio`, `fraction`, `difficulte`, `bas`, `tendon`, `zone_tendon`, `systemique`, `locale`, `groupes`, `schema`, `type_charge`, `materiel`, `lieux`, `contraintes` (`contraintes.poignet`), `renforcement`, `lateralite`, `bras_tendus` (retour gradué et durée de séance, § 8.3 ; règle R9 de `qualites/regles.py`).
- `profil` : `niveau` 0–3 (borné ; défaut 1), `sexe` (`female` réduit l'a priori de charge), `poids_kg`, `declares`, `zones_fragiles`.
  - `declares` : `{exerciseId: (mesure, valeur[, écart-type])}`. Les mesures sont `one_rm_kg`, `max_reps` ou `max_hold_seconds`. Le troisième élément, s'il est présent et non nul, remplace `delta_sd_declare` comme écart-type (ln) de l'observation. Le convertisseur du journal de l'application (`rejeu/journal_app.declares_initiaux`) déclare ainsi les accessoires depuis leur charge de travail initiale, convertie en 1RM par la courbe de population à la réserve cible de la ligne, avec l'écart-type 0,12.
  - `zones_fragiles` : liste d'objets `{zone, since, discomfort}` ou de codes de zone. Un objet compte si `since` ∈ `fragile_anciennetes` ou si `discomfort ≥ fragile_gene_min` ; un code seul compte toujours (`Gardefous._zones_fragiles`, § 8.1).
- La **référence** de la planification (`Planification.charger_reference`) et la replanification initiale demandée par l'appelant (annexe A, constat de relecture M7).
- La liste des extensions et leur ordre (`rejouer(…, extensions)`).

### 2.6 Ce qui est recalculé depuis le journal

Toutes ces données sont recalculées : l'état gaussien (deux branches pendant une séance), les compartiments de fatigue, le multiplicateur de bruit, les compteurs de notes et de paresse, l'état de douleur et les renvois, la mémoire de prescription par exercice (marques d'emplacement, formes de surmenage, historique d'endurance), les doses par zone, le volume servi par semaine (séries dures créditées par groupe, secondes bras tendus par famille, semaines allégées : retour gradué, § 8.3), les paramètres importés et les états des extensions. Le § 9.5 liste les conditions d'un rejeu exact.

---

## 3. API

### 3.1 `Koach(params, fiches, profil)`

Le constructeur crée `modele`, `garde` (`Gardefous(params, niveau, zones_fragiles)`), `seances`, `journal = []`, `raisons = []`, `jour = 0` et `extensions = []`. Les extensions sont ajoutées par l'appelant, et leur ordre compte : c'est l'ordre des crochets.

### 3.2 `observe(evenement)` → `None`

Voir § 2.1. `observe` ajoute toujours l'événement au journal avant de le traiter, y compris un événement `plan` ou `parametres` rejoué.

### 3.3 `plan(contraintes)`

`plan(c)` met d'abord les contraintes sous forme canonique (`Koach._canonique`), ajoute `{'type': 'plan', 'contraintes': forme canonique}` au journal, puis appelle `Koach._plan` sur cette forme. Le rejeu passe par le même `_plan` (§ 2.1) : un appel de `plan` qui change l'état (création de pistes, observation déclarée, plans d'emplacement, budgets de reprise, renvois, replanification) est donc refait à l'identique.

**Forme canonique** (`_canonique`), sur une copie profonde des contraintes :

- `horizon = 'seance'` : `grilles` est réduit aux exercices des items, dans l'ordre de première apparition, chaque grille devenant `{pas, minimum, halteres}` ; `zones` est réduit de même, chaque entrée devenant `[niveaux (objet), zones provoquées (liste triée)]` ; `roles` est réduit aux `slotId` des items.
- autres horizons : copie profonde telle quelle. Les contraintes doivent alors être sérialisables en JSON (l'appelant ne passe que des types JSON).

Le champ `horizon` choisit le traitement. Une autre valeur lève `ValueError`.

**`horizon = 'seance'`.** Entrées :

| Clé | Contenu |
| --- | --- |
| `items` | items écrits du jour (format `kalis_core`). Les modulations de la semaine allégée, de la planification, du bras d'essai et de la forme d'adhérence sont appliquées **par l'appelant** avant l'appel (annexe A, constat de relecture M6) ; elles entrent ainsi dans la forme journalisée. |
| `grilles` | `{exerciseId: Grille(pas, minimum, halteres)}` ou `{exerciseId: {pas, minimum, halteres}}` |
| `zones` | `{exerciseId: (niveaux {zone: 0, 0,5 ou 1}, zones provoquées)}` |
| `roles` | `{slotId: main, secondary, …}` |

Sortie : `{'items': [...], 'raisons': [...]}`.

Chaque item servi est une copie de l'écrit. Pour un item de force, seuls `sets`, `setTargets`, `technique` si elle est retenue (avec les champs de `equivalent_standard`) et `targetFlames` après une course dure la veille (§ 6.7, étape 5) changent ; `setTargets` vaut `None` pour un item de travail `charge`, `reps` ou `tenue`. Les lignes d'endurance peuvent être raccourcies, bornées, remplacées par une course facile ou retirées (§ 6.7). Les items retirés disparaissent.

Les champs `koach*` peuvent être posés sur un item écrit, par l'appelant ou par la planification. Ils sont lus ainsi :

| Champ | Posé par | Lu par | Effet |
| --- | --- | --- | --- |
| `koachIntensite` | `Planification.appliquer` (appelé par l'appelant) | `_cible_charge` | écart relatif de charge totale, borné à ±`plafond_intensite`, ignoré en semaine verrouillée |
| `koachVolume` | `Planification.appliquer` | — | information : séries servies − séries écrites |
| `koachCible` | l'appelant | `_tentative` | charge externe visée, tentée à la dernière barre si P ≥ 0,35 |
| `koachFragile` | l'appelant | `_bornes_hausse`, `borne_externe` | hausse permise × `hausse_fragile_facteur` ; aucune hausse externe |

**Item de test inséré.** Quand le vrai test se déclenche (§ 6.4), un item est inséré **avant** l'item de travail :

```
{slotId: <slotId>.t, exerciseId, sets: rampe_series_max (+2 si 1 répétition),
 repsLow = repsHigh = n, targetFlames: flammes_de_rir(rir),
 restSeconds: max(restSeconds écrit, repos_test_s), kind: 'test',
 test: {kind: 'rep_max', targetRir: rir, attempts: rampe_series_max},
 loadBasis (copié), toCalibrate: False,
 reasons: [{code: 'koach.vrai_test', params: {}}], koach: 'vrai_test'}
```

Ensuite, l'item de travail perd une série s'il en avait au moins 3.

**`horizon = 'serie'`.** Entrées : `item` (l'item servi), `index` (rang de la série, à partir de 0) et `faites` (non lu). Sortie : `None`, qui veut dire « arrêter l'exercice », ou un objet :

| Champ | Contenu |
| --- | --- |
| `repsLow`, `repsHigh` | plage de répétitions |
| `secondsLow`, `secondsHigh` | plage de secondes (tenues) |
| `loadKg` | charge externe sur la grille, ou `None` |
| `flames` | effort affiché |
| `role` | `None`, `test` ou `attempt` |
| `repere` | facultatif : série repère ou série de montée |
| `trace` | facultatif ; texte de diagnostic **hors contrat** : la parité ne le vérifie pas |

**`horizon = 'semaine'`.** Le moteur appelle `plan_semaine(koach, c)` sur chaque extension et renvoie le dernier résultat non `None`. Pour `Planification`, `c = {semaine, replanifier?}` et la sortie vaut `{semaine, modulation: {volume: [10 facteurs], intensite} ou None, items: {(jour, slotId): (séries, écart d'intensité)}}`. Les clés de `items` sont des tuples, à sérialiser en `"jour|slotId"` en JSON.

**`Seances.borne_externe(item, index, charge)`** (lecture seule) ramène sous les garde-fous de la séance une charge proposée hors de la prescription (bras d'intensité d'un essai N-of-1). Elle renvoie `None` (aucune hausse permise) si le plan de l'emplacement est absent, n'est pas une charge, est un test, ou porte `sans_hausse`, `verrou`, `part_max`, `dose_plafonnee`, une zone ou une raison de conduite, une zone fragile du profil, un échec, une baisse après échec, ou si l'item porte `koachFragile`. Sinon elle applique `_bornes_hausse` (raisons émises effacées), puis, à l'index ≥ 1, la borne +5 % (un cran permis) sur la série précédente.

### 3.4 `posterior()` → objet

| Clé | Contenu |
| --- | --- |
| `jour` | jour du modèle |
| `qualites`, `qualites_sd` | moyennes et écarts-types des θ_q (écarts à l'a priori, en ln) |
| `reponse`, `reponse_sd` | ρ |
| `reponse_classes` | les 5 écarts EPS |
| `fatigue_sensibilite` | `{nerveux_systemique: KN, nerveux_local: KL, musculaire_systemique: KG, musculaire_local: KM}` |
| `fatigue` | `{nerveux: {systemique, local[17]}, musculaire: {systemique, local[17]}, tendineux: {zone: valeur}, tau: [3]}` |
| `biais_rir` | `[BA, BP]` |
| `bruit_rir` | multiplicateur appris |
| `courbe` | `[λ, KU]` |
| `fatigue_intra` | FI |
| `part_tenue` | HH |
| `note_paresseuse` | a/(a + b) |
| `hypotheses_reponse` | poids des 9 hypothèses |
| `exercices` | `{id: {type, ln_capacite, ecart_type, valeur = e^ln_capacite, intervalle_90: [bas, moyenne, haut], seances, mesures}}`, dans l'ordre de création des pistes |

`ecart_type` vient de `Modele.capacite` : `√(h P hᵀ + defaut_modele_sd²)` (§ 4.3). L'intervalle à 90 % vaut `exp(μ ± 1,6448536269514722·σ)` avec ce σ. Toutes ces valeurs sont « à frais » : sans effet de jour ni fatigue.

### 3.5 `explain()` → liste

`explain()` renvoie une copie de `koach.raisons`, recopiée de `seances.raisons` à chaque appel de `plan` aux horizons `seance` et `serie`. `seances.raisons` est vidée à l'ouverture de la séance : elle contient les raisons émises depuis (renvois de l'ouverture, prescription, séries). Chaque raison a la forme `{code, params}`. Une raison émise par `cible` est ré-émise à chaque appel ; les doublons sont donc possibles.

**Liste complète des codes `koach.*`** (tous émis par `koach/seance.py`). L'application écrit un texte par code.

| Code | Paramètres | Émis quand (fonction) |
| --- | --- | --- |
| `koach.douleur_persistante` | `zone`, `consulter` = `True` | renvoi vers un professionnel : première séance d'un arrêt, puis première séance de chaque période de `renvoi_periode_j` jours d'arrêt (`ouvrir`, `Gardefous.renvois`) |
| `koach.douleur_retrait` | `exercice`, `zone` (ou `None`), `cause` ∈ `douleur`, `douleur_arret`, `douleur_reprise`, `poignet_chaud`, `poignet_charge`, `reprise_dose` | exercice retiré par la conduite sous douleur ou le poignet (`_item`), budget de reprise épuisé (`_item`), course retirée pendant un arrêt du bas du corps (`_endurance`) |
| `koach.test_reporte` | `exercice`, `cause` = `bilan_bas` | test écrit retiré un jour de bilan ≥ 1, hors jour d'épreuve (`_item`) |
| `koach.poignet_appui_neutre` | `exercice`, `intensite` | première gêne du poignet sur une poussée au poids du corps : appui neutre conseillé, dose écrite au plus (`_item`) |
| `koach.poignet_dose` | `exercice` | poignet sensible : dose écrite au plus (`_item`) |
| `koach.technique_retenue` | `exercice`, `technique`, `cause` ∈ `niveau`, `douleur`, `bilan`, `phase`, `echeance`, `antecedent` | technique non servie (`_technique`) |
| `koach.reprise_coupure` | `exercice`, `jours` (entier) | séries × `coupure_series` dans la semaine du retour d'une coupure ≥ `coupure_j` jours (`_item`) |
| `koach.surmenage` | `exercice`, `series`, `part` | lignes retirées après une alerte de surmenage (`_surmenage`) |
| `koach.reprise_dose` | `exercice`, `zone` | séries ramenées au budget hebdomadaire de la zone en reprise (`_item`) |
| `koach.vrai_test` | `exercice` | vrai test inséré (`prescrire`) ; le même code figure dans `reasons` de l'item de test, avec `params` vide |
| `koach.endurance_raccourcie` | `exercice`, `cause`, `part` (entier, %) | reprise après coupure (A10.1) ou jour sans au palier 2 (A10.2) (`_endurance`) |
| `koach.course_facile` | `exercice`, `remplacant`, `cause` | course de qualité remplacée par une course facile un jour sans (`_endurance`) |
| `koach.endurance_retrait` | `exercice`, `cause` | course de qualité retirée un jour sans, faute de course facile faisable (`_endurance`) |
| `koach.course_bornee` | `exercice`, `part` | course bornée à la plus longue des derniers jours + `endurance_pic` (`_endurance`) |
| `koach.wod_echelle` | `exercice`, `cause`, `part` | conditionnement × `wod_echelle` (`_endurance`) |
| `koach.fatigue_croisee` | `exercice`, `cause` = `course_dure` | une flamme de moins sur le bas du corps après une course dure la veille (`_endurance`) |
| `koach.arret_exercice` | `exercice`, `cause` = `echecs` | `echecs_arret` échecs dans l'exercice (`cible`) |
| `koach.zone_fragile` | `exercice`, `zone`, `cause` ∈ `surcharge`, `hausse` | part écrite ramenée à `surcharge_fragile_max`, ou hausse bornée sur une zone fragile du profil (`_cible_charge`, `_bornes_hausse`) |
| `koach.serie_repere` | `exercice` | série repère (charge, répétitions, tenue) (`_cible_charge`, `_cible_reps`, `_cible_tenue`) |
| `koach.tendon` | `exercice`, `cause` = `total` (facultatif) | tenue en bras tendus bornée par la hausse des tendons, par tenue ou sur le temps total de l'emplacement (`_cible_tenue`) |
| `koach.retour_gradue` | `exercice`, `groupe` (code du groupe majeur, `allegement` pour le total d'une semaine d'allègement, ou `bras_tendus_push`, `bras_tendus_pull`, `bras_tendus_mixed`), `limite` (limite de la semaine, au dixième), `series` (séries servies ; 0 = item retiré), `secondes` (tenue raccourcie, ou `None`) | séries ou tenue ramenées à ce que la rampe hebdomadaire permet encore (`_retour_gradue`, § 8.3) |
| `koach.seance_bornee` | `exercice`, `minutes` (durée admise) | ligne raccourcie ou retirée pour que la séance tienne dans la durée admise (`_duree_bornee`, § 8.3) |

Les raisons « pas de hausse sur douleur », « bilan bas », « borne de hausse », « part écrite » et « séries ×0,6 sur douleur » n'ont pas de code : elles n'apparaissent que dans `trace`. Les extensions ont leurs propres codes, hors `koach.*` :

- Surveillance : causes `rupture`, `residu`, `assiduite`, `douleur` ; actions `conduite_douleur` (avec `renvoi_professionnel: True`), `replanifier`, `semaine_allegee`, `elargir` ; codes des questions et des choix (§ 3.7.2).
- Contrôle dual : raisons texte `essai_demarre:<semaine>:`, `essai_refuse:<semaine>:<raisons>`, `essai_interrompu:<raison>`, `synthetique_impossible:<message>`. Raisons de refus : `non_calibre`, `affutage`, `alerte_hors_modele`, `douleur`, `echeance_proche`, `deja_<statut>`, `temoin_trop_court:<n>`, `essai_en_cours`, `semaines_insuffisantes:n<m`, `aucun_lift_principal`, `lift_inconnu:<id>`, `intervalle_large:<id>:<demi>`.

### 3.6 Extensions : crochets

`Extension` (`koach/moteur.py`) définit cinq crochets, tous facultatifs :

| Crochet | Appelé |
| --- | --- |
| `fin_seance(koach, resume, e)` | après `modele.fin_seance` |
| `seance_manquee(koach, e)` | sur `seance_manquee` |
| `fin_semaine(koach, ligne, e)` | après `modele.fin_semaine` |
| `decision(koach, e)` | sur `decision` |
| `plan_semaine(koach, c)` | sur `plan` à l'horizon `semaine` |

Les crochets sont appelés dans l'ordre de `koach.extensions`. Trois crochets sont appelés par d'autres modules :

- `sur_alerte_hors_modele(koach, causes)` : appelé par `Surveillance.verifier`.
- `appliquer_parametres(params)` : appelé par `rupture.appliquer_parametres` (événement `parametres`). Seules `Surveillance` et `Adherence` l'exposent.
- `hypothese_pour_la_semaine(koach, semaine, graine)` : appelé par `Planification.tirer` sur chaque extension qui l'expose (`ControleDual`) ; la dernière valeur l'emporte.

`rejouer(params, fiches, profil, journal, extensions)` instancie les extensions (fabriques sans argument), dans l'ordre donné, et rejoue le journal.

### 3.7 Extensions : algorithmes

#### 3.7.1 `Planification(params, fiches, validateur, options=None)`

`options` surcharge `params.planification` (copie gardée à la construction). Le validateur de sécurité est **obligatoire** : `validateur=None` lève `ValueError`, sauf si `options['sans_validateur']` est vrai (essais de parité numérique seulement ; `_sur` accepte alors tout plan, déjà borné par les plafonds).

`charger_reference(blocs, block_weeks, horizon, cibles, echeance_jour, principaux, poids_corps)` prend les paramètres suivants :

- `cibles` : `{exerciseId: valeur visée}`, en charge **totale** pour un exercice chargé.
- `principaux` : exercices suivis en plus des cibles.

Les exercices suivis, `suivis`, sont les cibles triées puis les principaux, gardés s'ils ont une fiche. Cet appel n'est pas journalisé (annexe A, M7).

**Semaines de référence.** Pour la semaine globale w :

- bloc `k` = dernier indice `j` tel que `block_weeks[j] ≤ w` ;
- semaine de bloc `w − block_weeks[k]` ;
- semaine écrite = **dernière** entrée de `pass2.weeks` portant ce `weekIndex`.

Une semaine est **verrouillée** si `intention or genre` ∈ {intro, deload, taper, test, competition, transition} ou si `genre` ∈ {deload, test, intro}.

**Lignes d'un item** (`lignes_item(item, e)`). Elles sont vides pour un échauffement, une fiche absente ou `sets ≤ 0`.

- `rir` = réserve des `targetFlames` (2,5 sans flammes) ; pour un test, `test.targetRir` (1 par défaut).
- `reps` = moyenne de `repsLow` et `repsHigh` ; `quantité` = `reps`, sinon secondes/10, sinon 1.
- Pour une fiche `charge` : `part` = `percentOfOneRm`, sinon `exp(−g₀(reps ou 8 + rir))` ; `pente` = `g₀'(reps + rir)` (sans plancher) ; g₀ est la courbe de population (§ 5.1). Sinon `part = None` et `pente = 0,03`.
- Écart `e ≠ 0` et `part` non nulle : `part ×= 1 + e` et `rir = max(0,5 ; rir − e/pente)`.
- Série de tête (`top_set_backoff`, au moins 2 séries) : deux lignes, `(1, rir, part, q)` et `(n − 1, rir + drop/pente, part·(1 − drop), q)`, avec `drop = backoffDropPct` (0,08 par défaut).

**Stimulus d'un item.** Pour chaque ligne `(n, rir, part, q)` :

- volume += `n·(1 si rir ≤ 4, sinon 0,5)` ;
- effort += `n/(1 + max(rir − 1, 0)/3)` ;
- intensité += `n·clamp((part ou 1 − 0,4)/0,4 ; 0,2 ; 1,5)` ;
- systémique += `n·eff·systemique`, avec `eff = 1/(1 + max(rir, 0)/effort_demi_rir)` ;
- tendon += `n·eff·tendon·(q pour une tenue, sinon 1)`.

**Table de la semaine w.** Sur la grille d'intensité `G = (−0,05 ; −0,025 ; 0 ; 0,025 ; 0,05)` :

- `stim[g, e, 3]` : stimulus des exercices suivis, par point de grille ;
- `syst[g, jour % 7, q]` : stimulus systémique × vecteur ;
- `masse[q]` : Σ séries × vecteur ;
- `part[q]` : moyenne de la part du 1RM, 0,7 sans part, pondérée par la masse ;
- `tendon[zone][q]` : au point `g = 2` seulement.

**Tirage du jumeau** (`tirer(koach, semaine, n)`) :

1. Crée les pistes suivies.
2. Construit `H` : une ligne par exercice suivi (fonctionnelle de capacité à frais `h_frais`, moyenne `base + h·m`, sans `defaut_modele_sd`), puis une ligne pour ρ et une par EPS_c.
3. `S = H P Hᵀ`, puis `S = ½(S + Sᵀ)`.
4. `L = numerique.cholesky_semi(S)` (§ 9.3) : Cholesky en boucles explicites ; un pivot ≤ 1e-12 × la plus grande diagonale annule sa colonne.
5. Générateur mulberry32 de graine `fnv1a32('koach-plan:<graine>:<semaine>')`. Ordre des tirages : `z[a, b]` gaussien pour a < n, b < k (ligne par ligne) ; puis n uniformes pour l'hypothèse de chaque trajectoire (inversion de la fonction de répartition des `poids_hyp`, dernier indice par défaut) ; puis, pour chaque a et chaque b < max(E, 1), `bruit_jour[a, b]` et `bruit_proc[a, b]` en alternance.
6. **Tirage de Thompson.** Avant les n uniformes, chaque extension qui expose `hypothese_pour_la_semaine` est appelée avec `(koach, semaine, graine)`. Si la dernière réponse n'est pas `None` (contrôle dual calibré, § 3.7.4), **toutes** les trajectoires prennent l'hypothèse tirée. Les n uniformes sont consommés dans les deux cas : les tirages suivants restent alignés.
7. `x = moyennes + z·Lᵀ`.

**Évaluation** (`evaluer(X, tirage, depuis, blocs, qualites)`) :

- **Décodage.** Pour le bloc j, la variable de volume i (qualité q active) donne `A[:, j, q] = 1 + clip(X, ±plafond_volume)` ; l'intensité donne `I[:, j] = clip(X, ±plafond_intensite)`.
- **Dernière semaine.** `fin = horizon − 1`. Avec une échéance, `fin = min(fin, jour_ech // 7)`. Sans échéance ni cible, `fin = min(fin, depuis + horizon_sans_echeance_sem − 1)`.
- **Boucle sur w.** Une semaine non écrite ne contribue qu'à la fatigue : `F ×= e^(−7/τ)`, τ = `tau_musculaire_j`. Une semaine écrite :
  1. En semaine verrouillée : `a = min(a, 1)` et `i = min(i, 0)`.
  2. Interpolation linéaire de `stim` et `syst` sur la grille ; le stimulus est multiplié par `fe = a·Vᵀ`.
  3. `charge_jour[c, d] = Σ_q syst[c, d, q]·a[c, q]`.
  4. Fatigue lente : `F = F·e^(−7/τ) + Σ_d charge_jour[d]·e^(−(7 − d)/τ)` ; au matin de l'échéance, `f_ech = F·e^(−de/τ) + Σ_{d<de} charge_jour[d]·e^(−(de − d)/τ)`.
  5. `k_rec` = facteur de récupération de F ; `acc = 1/(1 + (semaines_modele + w − depuis)/accoutumance_semaines)`.
  6. Gain par hypothèse h : `gains[c, e, h] += dose_h(stim)·k_rec·acc`.
  7. Transport : `Σ_q min(a·masse, masse)·part·|i| + transport_creation·Σ_q |a·masse − masse|`.
  8. Surcharge : `max(Σ charge_jour/Σ syst_ref − 1, 0)`.
  9. Tendons : pour chaque zone, rapport de la semaine à la moyenne des 4 semaines précédentes (même calcul sur la référence). La pénalité vaut 1 si ce rapport dépasse `max(risque_tendon_ratio_max ; rapport de la référence)`, à condition que la moyenne de référence soit ≥ `risque_tendon_plancher`.
- **Distance.** `distance = transport/Σ masses de référence`.
- **Trajectoires.**
  - `taux = ρ + EPS_classe`.
  - `proc = √(q_delta_semaine·s + sigma_prevision_semaine²·s)`, avec `s = max(1, fin + 1 − depuis)`.
  - `μ_fin = μ + gains[hyp]·taux + proc·bruit_proc`.
  - Avec cibles **et** échéance : `jour = μ_fin − KG·f_ech + √(sigma_seance² + sigma_exercice²)·bruit_jour`. Une cible est atteinte si `jour ≥ ln(cible) + marge_cible`. `J` = part des trajectoires qui atteignent toutes les cibles (P par cible renvoyée à part).
  - Sinon : `J = moyenne(μ_fin − μ) × exp(−abandon_hebdo·(s + abandon_surcharge·surcharge))`, divisé par `echelle` (la valeur J du plan de référence) si elle existe.
- **Valeur.** `J − lambda_transport·distance − pénalité`.

**Recherche** (`replanifier(koach, semaine)`) :

1. Si aucun bloc ni aucun exercice suivi : ligne d'historique vide.
2. Dimensions : `d = blocs × (qualités actives + 1)`, avec les blocs dans l'ordre de première apparition à partir de `semaine`. `pop = max(4, plans_max // iterations)`. `elite_n = max(2, numerique.arrondi(pop·elite))`. Graine CEM : `fnv1a32('koach-cem:<graine>:<semaine>')`.
3. Moyenne de départ : le plan en cours, à la première semaine du bloc qui en a un. Écart de départ : ½ plafond.
4. Pour chaque itération : `X[0] = 0` (référence), `X[1] = moy`, `X[2…]` = `moy + écart·gauss`, tirés ligne par ligne puis bornés. Les candidats sont triés par `(−valeur, indice)`. Mise à jour : `moy = lissage·moy_élite + (1 − lissage)·moy` et `écart = max(lissage·sd_élite + (1 − lissage)·écart ; 1e-4)`, où `sd_élite` est l'écart-type de population (numpy `std`, ddof 0). Les 4 meilleurs candidats de l'itération sont ajoutés en tête de `candidats_finaux`, qui garde aussi les 4 premiers de la liste précédente.
5. Choix. Les essais sont le meilleur candidat, puis `candidats_finaux`. Un essai est écarté si sa valeur ≤ valeur de référence + `gain_min`. Sinon il est soumis au validateur (`_sur`) jusqu'à 3 fois ; s'il échoue, il est divisé par 2 et resoumis. Le premier essai validé dont la valeur dépasse celle du plan choisi (au départ, la référence) + `gain_min` est retenu.
6. Le plan retenu est écrit pour toutes les semaines écrites ≥ `semaine`, avec le verrou appliqué : `plan[w] = {volume: [10], intensite}`. La ligne d'historique arrondit volumes et intensités par `numerique.arrondi(x, 4)`.

**Application.** `items_modules(w)` calcule, pour chaque item écrit de la semaine (jours puis items, dans l'ordre écrit), le nombre de séries servies :

- Échauffements, tests et items sans séries : séries inchangées, écart 0.
- Autres items : `voulu = n·Σ_q v_q·volume_q + reste[ex]`, `servi = max(1, floor(voulu + 0,5))`, `reste[ex] = voulu − servi`.
- Plafond dur sur les séries entières : tant qu'une qualité dépasse `ref·(1 + plafond_volume)`, les ajouts sont retirés un par un, dans l'ordre inverse. Puis, tant qu'une qualité de référence non nulle passe sous `ref·(1 − plafond_volume)`, les retraits sont rendus un par un, dans l'ordre inverse.

`appliquer(semaine, jour, items)` copie les items modifiés et pose `sets`, `koachIntensite` (si l'écart ≠ 0) et `koachVolume`. Il n'est appelé que par l'appelant (M6).

`blocs_modules(plan)` produit la copie des blocs que lit le validateur. Il y écrit les séries et `setTargets = None`. Si l'écart d'intensité est non nul, il multiplie aussi `percentOfOneRm` et `intensity.value` (base `percent_one_rm`) par `1 + e` (`numerique.arrondi(·, 4)`), et `startLoadKg` devient `numerique.arrondi((startLoadKg + bw)·(1 + e) − bw, 3)`.

`_sur(x)` est vrai si le validateur ne trouve, sur les blocs modulés, aucun constat `(code, week, dayIndex, exerciseId)` absent des constats de la référence (multiensemble).

Crochets :

- `fin_semaine` replanifie à `e.semaine + 1`.
- `plan_semaine` replanifie si `c.replanifier`.

#### 3.7.2 `Surveillance(params)` (hors modèle)

**BOCPD** (Adams & MacKay 2007) sur `resume[1]`, le résidu normalisé moyen de chaque séance qui en a un.

- Modèle normal-gamma : μ0 = 0, κ0 = 1/`a_priori_moyenne_sd`², α0 = `a_priori_alpha`, β0 = `a_priori_beta`.
- Prédictive de Student : 2α degrés de liberté, échelle² β(κ+1)/(ακ).
- Hasard H constant. Courses tronquées à `course_max` ; la dernière case est absorbante et garde les statistiques de la plus ancienne course.
- Après `min_observations` observations, une course nouvelle prend l'a priori de variance α = `a_priori_alpha_nouvelle` et β = (α − 1)·E[σ²] de la course la plus probable (premier indice en cas d'égalité).
- `P(rupture)` = masse des courses de longueur ≤ `fenetre_seances`, hors course initiale (r = n). Elle vaut 0 avant `min_observations`.
- `lgamma` : Lanczos, g = 7, 9 coefficients ; formule des compléments sous 0,5.

**Causes**, recalculées par `verifier` après chaque crochet :

| Cause | Condition |
| --- | --- |
| `rupture` | P > `alerte` |
| `residu` | sur les `residu_secours_semaines` dernières semaines, chaque \|moyenne des résidus d'e1RM de la semaine\| > `residu_secours`. Le résidu d'e1RM d'une séance est `resume[5]` du modèle : écart ln entre la capacité du jour vue après la dernière série et celle prévue avant la première, sur les mouvements chargés suivis depuis au moins 3 séances. Une séance sans cette valeur (`None`) ne compte pas. La conversion de l'innovation de la note (`_residu_e1rm`) n'est utilisée que si le résumé a moins de 6 éléments, ce que le modèle ne produit jamais (annexe A, M8). |
| `assiduite` | séances faites < `assiduite_secours` × prévues, cumulées sur `assiduite_secours_semaines` semaines (prévues = faites + manquées) |
| `douleur` | une zone dont le **dernier** signalement > `douleur_secours` et date de ≤ `douleur_recente_j` jours |

Une cause hors silence lève l'alerte. Quand l'alerte passe de rien à au moins une cause, les extensions qui exposent `sur_alerte_hors_modele` sont prévenues. L'historique garde 12 semaines.

**Diagnostic.** `questions(reponses)` pose au plus 3 questions :

1. `cause` : choix `douleur`, `moins_de_temps`, `fatigue`, `rien`.
2. Si `douleur` : `zone` (13 zones), puis `intensite` (0 à 10).
3. Si `moins_de_temps` : `seances_par_semaine` (1 à 7), puis `duree_max_min` (20, 30, 45, 60, 75 ou 90).

`repondre` applique l'action :

| Cause | Action |
| --- | --- |
| `douleur` | signalement versé à `garde.noter_seance(posee=False)` ; action `conduite_douleur` avec `renvoi_professionnel` |
| `moins_de_temps` | action `replanifier` avec les disponibilités (aucune replanification n'est faite par le moteur) |
| `fatigue` | `allegement = [jour, jour + 7, semaine_allegee_series, semaine_allegee_rir]` |
| `rien` | `modele.elargir(elargissement_rien_de_special)` (variances des δ_e et des θ_q multipliées), BOCPD remise à zéro |

Chaque cause levée se tait ensuite `silence_semaines` semaines ; on garde les 10 dernières réponses.

`appliquer_allegement(items, jour)` est appelé par l'appelant, pas par le moteur (M6). Sur les items de travail ayant au moins une série : `sets = max(1, floor(sets·f + 0,5))`, et les flammes (y compris celles de `setTargets`) baissent de `floor(2·rir + 0,5)`, au moins 1, sauf à 10.

`dossier(koach)` exporte un dossier hors modèle anonymisé :

- les `journal_dossier` derniers événements, hors événements `profil` ;
- les clés de `CLES_INTERDITES` sont retirées ;
- un texte est gardé seulement s'il est un code (au plus 64 caractères `[A-Za-z0-9_.-]`, pas une date ISO).

Import de paramètres : voir § 7.3.

#### 3.7.3 `Adherence(params)`

Le modèle est un probit bayésien : `P(accepte) = Φ(w·x)`, avec `w ~ N(m, P)` de dimension 16.

- A priori : `m₀ = (biais_initial, 0, …)`, `P₀ = a_priori_poids_sd²·I`.
- Caractéristiques `x` : biais 1 ; indicatrice du type (9) ; `min(|ampleur|/ampleur_echelle, ampleur_borne)` ; bilan bas ; semaine d'allègement ; moment `entre_series` ; moment `prochaine_seance` ; `min(refus récents/refus_recents_echelle, 1)`.
- Prédiction : `Φ(m·x/√(1 + xᵀPx))`.
- Mise à jour : `interval_moments(s, v, 1, 0, +∞)` si la proposition est acceptée, `(−∞, 0]` sinon, reportée en rang 1. La variance `v = xᵀPx` est bornée à 1e-12.

Un refus avec `too_heavy` ou `too_light` (et charge, reps, rir fournis) devient aussi une mesure faible de capacité (§ 5.11). `equipment` et `time` sont rangés comme contraintes de planification.

`forme(cible, depart, pas_min, type, contexte)` découpe le trajet en paliers :

- n va de 1 à `min(paliers_max, floor(d/pas))` ;
- paliers intermédiaires `depart ± pas·floor(k·d/(n·pas) + 0,5)`, dernier palier = cible exactement ;
- chaque pas doit valoir au moins `pas_min` quand n > 1 ;
- pour chaque n, on retient le moment de plus forte probabilité minimale (ordre `MOMENTS`) ;
- on s'arrête au premier n dont la probabilité minimale atteint `proba_cible`.

La forme ne change jamais la cible. Elle n'est appliquée que par l'appelant (M6).

#### 3.7.4 `ControleDual(params, lifts_principaux)`

**Poids des hypothèses.** `Reponse` tient un a posteriori discret sur les 9 hypothèses (§ 4.4). Ses poids sont recopiés dans `modele.poids_hyp` à chaque fin de semaine.

**Innovation hebdomadaire.** Pour chaque exercice suivi d'une classe :

- `ν = μ_pré(b) − μ_post(b − 1)` ;
- `g_h = (ρ + EPS)·facteur·dose_h(stim)` et `g_u = Σ w_h g_h` ;
- `V_prior = V_post(b − 1) + 7·q_delta_jour_inactif` ;
- gain `K = clamp(1 − V_pré/V_prior ; 0 ; 1)` ;
- observation `(K·δ_h, ν, max(V_prior − V_pré, 0) + sigma_innovation²)`, puis `δ_h ← (1 − K)·δ_h + g_h − g_u`.

Les variances V viennent de `Modele.capacite`, donc comprennent `defaut_modele_sd²` (§ 4.3). La vraisemblance est gaussienne. Les poids sont normalisés en espace logarithmique, mis au plancher `plancher_poids`, puis renormalisés.

**Calibrage** (`calibre`) : au moins `semaines_min` semaines de journal, et `1,6448536269514722·σ < intervalle_max` pour chaque lift principal, avec σ de `Modele.capacite` (défaut de modèle compris).

**Essai N-of-1** (`EssaiN1`) :

- Bras A : volume × (1 + `amplitude_volume`). Bras B : intensité × (1 + `amplitude_intensite`).
- Séquence ABBA ou BAAB : tirage `rng.next() < 0,5` avec la graine `fnv1a32('koach-dual-essai:<graine>:<semaine>')`.
- Démarrage (`peut_demarrer`) refusé si le modèle n'est pas calibré, en affûtage, sous alerte ou douleur, si l'essai finirait à moins de `marge_echeance_semaines` de l'échéance, si l'essai n'est plus « prévu », ou s'il y a moins de `synthetique_semaines_min` semaines de capacités des témoins avant l'intervention (`proposer_essai` compte ces semaines dans `pre` et passe le minimum du fichier).
- Mesure hebdomadaire : progrès de la cible − progrès de son témoin synthétique. Le témoin est un contrôle synthétique démoyenné, poids sur le simplexe, FISTA à pas 1/L avec L = 2 × majorant de λmax(A) (trace de A^16, puissance 1/16) ; projection exacte sur le simplexe par tri par insertion stable.
- Analyse : différences appariées par paire de bras ; variance intra-bras groupée ; a priori `N(0, a_priori_effet_sd²)`. Décision `B` si `P(B > A) ≥ seuil_decision`, `A` si P ≤ 1 − seuil, indéterminée sinon.
- Interruption : douleur signalée en fin de séance (toute liste `douleurs` non vide), `semaine_fin` portant une alerte ou une douleur, événement `decision` `alerte_hors_modele`, alerte de la surveillance.

**Tirage de Thompson.** `hypothese_pour_la_semaine(koach, semaine, graine)` renvoie `None` si `calibre` échoue ; sinon un indice tiré avec la graine `fnv1a32('koach-dual:<graine>:<semaine>')`. `Planification.tirer` l'appelle avec `planification.graine` (§ 3.7.1).

**Modulation des bras.** `modulation(semaine)` donne les facteurs du bras en cours. Elle est appliquée par l'appelant, sous les garde-fous : sur le banc, le bras A est borné par `dual.facteur_borne` par rapport aux séries de la référence, et le bras B passe par `Seances.borne_externe` (§ 3.3). Le moteur ne l'applique pas lui-même (M6).

---

## 4. Estimation : modèle d'état

### 4.1 Vecteur d'état

L'état est gaussien, `x ~ N(m, P)`. Le stockage alloué fait `28 + 3·48` composantes au départ et double quand il manque de place ; seules les `n` premières sont actives.

| Indice | Nom | Sens |
| --- | --- | --- |
| 0–9 | `TH + q` | θ_q : écart de l'utilisateur à l'a priori sur la qualité q (ln) |
| 10 | `RHO` | ρ : réponse (ln capacité par semaine à dose 1) |
| 11–15 | `EPS + c` | écart de réponse de la classe c |
| 16 | `KN` | sensibilité, compartiment rapide, part systémique |
| 17 | `KM` | sensibilité, compartiment lent, part locale |
| 18 | `BA` | biais additif de la note (répétitions) |
| 19 | `BP` | biais proportionnel de la note |
| 20 | `LAM` | λ, forme de la courbe |
| 21 | `KU` | échelle ln de la courbe de l'utilisateur |
| 22 | `FI` | fatigue intra-séance |
| 23 | `HH` | part du maintien maximal par répétition en réserve |
| 24 | `DS` | effet de jour de séance |
| 25 | `DE` | effet de jour de l'exercice en cours |
| 26 | `KL` | sensibilité, compartiment rapide, part locale |
| 27 | `KG` | sensibilité, compartiment lent, part systémique |
| 28 + 3j | `δ_e` | écart propre de l'exercice e (j = rang de création de la piste) |
| 29 + 3j | `κ_e` | échelle de courbe propre ; pour une tenue, écart ln de HH |
| 30 + 3j | `φ_e` | écart ln de sensibilité à la fatigue de séance |

Les pistes sont créées par `Modele.piste(id)` au premier appel qui les demande (série, prescription, posterior, planification) ; `ordre` garde l'ordre de création.

### 4.2 A priori hiérarchique

Le niveau population est fixé par le fichier de paramètres ; le niveau utilisateur est porté par θ, ρ, EPS, BA, BP, λ, KU, FI, HH et les sensibilités ; le niveau exercice par δ_e, κ_e et φ_e. Toutes les covariances initiales sont nulles.

**Niveau population et utilisateur :**

- θ_q : moyenne 0, variance `theta_sd²`.
- ρ : moyenne `r = rho_moyenne_par_niveau[niveau]`, variance `(r·rho_sd_rel)²`.
- EPS_c : moyenne `eps_classe_moyenne[c]·r/rho₁`, variance `(eps_classe_sd·r/rho₁)²`, avec `rho₁ = rho_moyenne_par_niveau[1]`.
- KN, KM, KL, KG, BA, BP, λ, KU, FI, HH : moyenne et variance tirées de la paire `[moyenne, sd]` du fichier (`k_nerveux`, `k_musculaire`, `k_nerveux_local`, `k_musculaire_systemique`, `biais_rir_additif`, `biais_rir_proportionnel`, `courbe_forme`, `courbe_echelle`, `fatigue_intra`, `part_tenue`). Une `sd` nulle fige la composante. Avec le fichier v1, sont figés : KN, KM, BA, KU, FI et HH ; sont appris : KL, KG, BP (0,25 ± 0,15) et λ (0,3 ± 0,3). Le biais additif BA reste figé à 0 : il n'est pas identifiable séparément de BP sur le banc (annexe A).

**Constante de population d'un exercice** (`base_de`, ln de capacité) :

- `charge` : `ln max(ratio·poids·niveau_echelle_charge[niveau]·(facteur_femme si female) ; fraction·poids·1,1 ; 1)`.
- `reps`, `tenue` : `ln clamp(base·e^(pente_difficulte·marge) ; bornes)`, où `marge = marge_niveau[0] + marge_niveau[1]·niveau − difficulte` (difficulté 3 par défaut), `base` vaut `reps_base` ou `tenue_base_s`, et les bornes `reps_bornes` ou `tenue_bornes_s`.
- `cardio` : `ln cardio_minutes_par_niveau[niveau]`.
- `wod` : 0.

**Création d'une piste**, sur les deux branches si une séance est ouverte :

- `δ_e` : moyenne 0, variance `max(sd² − Σ_q v_q²·P[θ_q, θ_q] ; (0,5·sd)²)`. `sd` vaut `delta_sd` (charge), `reps_sd` (reps et tenue), `cardio_sd` ou `wod_sd`. `P[θ_q, θ_q]` est la variance **courante** (a posteriori) au moment de la création.
- `κ_e` : moyenne `courbe_bas_du_corps` si `bas`, sinon 0 ; variance `courbe_echelle_exercice_sd²`. Pour une tenue : moyenne 0, variance `part_tenue_exercice_sd²`.
- `φ_e` : moyenne 0, variance `fatigue_intra_exercice_sd²`.
- **Capacité déclarée.** Si `declares[id] = (mesure, valeur[, sd])`, que la mesure correspond au type et que la valeur est > 0, on verse par `_observer_hors` une observation ponctuelle : `base + Σ v_q θ_q + δ_e = cible`, de variance `sd²` si le troisième élément est présent et non nul, sinon `delta_sd_declare²`. La cible vaut `ln(valeur + fraction·poids)` pour une charge, `ln valeur` sinon.

### 4.3 Fonctionnelles de capacité

`h_frais(e)·x` : coefficient `v_q` sur θ_q (seulement pour `v_q ≠ 0`, dans l'ordre q), puis 1 sur δ_e. La capacité à frais vaut `base + h_frais·x`.

`h_jour(e)` = `h_frais` + `[DS : 1, DE : 1, KN : −gn, KL : −ln, KG : −gm, KM : −lm]`, avec les régresseurs de fatigue `(gn, ln, gm, lm) = (f_g[0], loc[0], f_g[1], loc[1])` et `loc[c] = Σ_g w_g·f_l[c][g]/Σ_g w_g` sur les groupes de la fiche (0 sans groupe).

`capacite(id)` renvoie `(base + h_frais·m, √(max(h_frais P h_fraisᵀ, 0) + defaut_modele_sd²))`. Le terme `mesure.defaut_modele_sd` (0,015, lu par `.get` avec le défaut 0) représente l'erreur que le filtre ne voit pas (forme de courbe, densité supposée) ; il élargit l'intervalle de `posterior` et entre dans toutes les décisions qui lisent `capacite` : calibrage de la première charge (`σ > 0,12`), `_mesure_utile`, `calibre` et innovations du contrôle dual. `capacite_du_jour(id)` fait le même calcul avec `h_jour` ; pendant une séance, c'est le mélange des deux branches, de poids `w` = poids du mauvais jour : moyenne `(1 − w)μ₀ + wμ₁`, variance par appariement des moments.

### 4.4 Dynamique

**Avance du temps** (`avancer(jour)`, dt = jour − jour du modèle > 0) :

- `f_g[c] ×= e^(−dt/τ_c)` et `f_l[c][·] ×= e^(−dt/τ_c)`, avec c = 0 (τ = `tau_nerveux_j`) et c = 1 (τ = `tau_musculaire_j`) ;
- `f_tendon[z] ×= e^(−dt/tau_tendineux_j)` ;
- pour **chaque** piste, `P[δ_e, δ_e] += q_delta_jour_inactif·dt` (branche principale seulement).

**Effort d'une série** (compartiments) : `effort(rir, échec) = 1/(1 + max(rir, 0)/effort_demi_rir) + (echec_supplement si échec)`. Le `rir` utilisé est `rir_c`, la réserve vraie a posteriori de la série (§ 5.3), mise à 0 sur un échec.

**Chargement** (`_charger_compartiments(t, e, quantité)`), pour c ∈ {0, 1} :

- `f_g[c] += e·systemique` ;
- `f_l[c][g] += e·locale·w_g` ;
- si la zone tendineuse existe et `tendon > 0` : `f_tendon[z]` et `f_tendon_aigu[z] += e·tendon·quantité`, avec `quantité = max(secondes, 1)/10` pour une tenue, 1 sinon.

Le compartiment tendineux n'entre dans aucune décision : il est seulement exposé par `posterior` (annexe A).

**Stimulus de la semaine** (`_stimulus`, séries faites seulement) :

- `volume += 1 si rir ≤ 4, sinon 0,5` ;
- `effort += 1/(1 + max(rir − 1, 0)/3)` ;
- `intensité += clamp((part − 0,4)/0,4 ; 0,2 ; 1,5)`, avec `part = exp(lnL − (base + δ_e + Σ v θ))` pour une charge et 1 sinon.

Une série d'endurance ajoute `dose` aux trois compteurs.

**Hypothèses de dose.** Elles sont listées dans l'ordre `for k in stimuli : for s0 in hypotheses_s0`, soit 9 couples `(s0, k)` :

```
dose_h(stim) = 0 si stim_k ≤ 0, sinon (1 − e^(−stim_k/s0)) / (1 − e^(−dose_reference/s0))
dose_moyenne = Σ_h poids_hyp[h]·dose_h
```

Les poids valent 1/9, sauf s'ils sont écrits par le contrôle dual.

**Fin de semaine** (`fin_semaine`, appelée sur `semaine_fin` après `avancer(jour)`) :

- `facteur = recuperation(f_g[1])·accoutumance(semaines)`, avec `recuperation(F) = max(recuperation_plancher ; 1 − recuperation_pente·max(F − seuil, 0)/seuil)` et `accoutumance(s) = 1/(1 + s/accoutumance_semaines)`.
- Pour chaque piste, dans l'ordre :
  - `g = dose_moyenne(stim)·facteur` ; la dispersion de la dose entre hypothèses n'est pas ajoutée à P (constat de relecture m10, non corrigé) ;
  - si `g > 0` : croissance `δ_e ← δ_e + g·(ρ + EPS_classe)`. La covariance est mise à jour **en place, ligne puis colonne** : `P[e, :n] += g·(P[ρ, :n] + P[c, :n])`, puis `P[:n, e] += g·(P[:n, ρ] + P[:n, c])` ; la seconde opération lit les valeurs modifiées par la première, ce qui donne exactement `A P Aᵀ`. Puis `m[e] += g·(m[ρ] + m[c])` ;
  - sinon, si `jour − dernier_jour > desentrainement_grace_j` : `m[δ_e] −= desentrainement_par_semaine` et `P[δ_e, δ_e] += (0,5·desentrainement_par_semaine)²` ;
  - `P[δ_e, δ_e] += q_delta_semaine` ; remise à zéro du stimulus.
- `P[θ_q, θ_q] += q_theta_semaine` ; `P[ρ, ρ] += q_reponse_semaine` ; `f_tendon_aigu = 0` ; `semaines += 1`.
- La ligne `{semaine, doses, mu (base + μ_e après croissance), fatigue_lente, fatigue_rapide, facteur}` est ajoutée à `journal_semaines`.

**Élargissement** (`elargir(f)`) : `P[δ_e, δ_e] ×= f` pour toute piste et `P[θ_q, θ_q] ×= f` (branche principale).

### 4.5 Effets de jour et branche « mauvais jour »

**`debut_seance(jour, bilan, poids)`** :

1. `avancer(jour)` ; mise à jour du poids si donné.
2. Si `bilan.overall` est donné : moyenne de DS = `bilan_par_point·(overall − bilan_neutre)`, sd = `sigma_seance_avec_bilan`, et `p = mauvais_jour_proba_bilan_bas` si overall ≤ 2. Sinon : moyenne 0, sd = `sigma_seance`, `p = mauvais_jour_proba`.
3. Remise à zéro de DS, puis de DE (`sigma_exercice`). « Remise à zéro » = ligne et colonne de P mises à 0, puis variance et moyenne posées.
4. La branche « mauvais jour » est une copie de l'état, avec DS de moyenne `+ mauvais_jour_moyenne` et de variance `mauvais_jour_sigma²`. Log-poids : `ln p` pour cette branche, `ln(1 − p)` pour la principale.

**Changement d'exercice.** Quand une série porte un exercice différent de la série précédente, DE est remis à zéro sur les deux branches, même si l'exercice a déjà été vu dans la séance (superset A, B, A, B : constat de relecture m6, non corrigé). Si c'est le premier passage de la piste ce jour-là :

- `jour_prevu` = capacité du jour (si charge et au moins 3 séances avant celle-ci) ;
- `series_seance = []` ;
- `seances += 1`.

**Toute observation** en séance met à jour les deux branches ; chaque log-poids reçoit le `logZ` de sa branche. Le poids du mauvais jour est `w = softmax(logw_principale, logw_alt)`, calculé avec soustraction du maximum.

**`fin_seance()`** :

1. Résidu d'e1RM de la séance : moyenne des `jour_vu − jour_prevu` des pistes concernées, sinon `None`.
2. Si `w > 1e-9`, fusion par appariement des moments sur les n composantes actives : `m = (1 − w)m₀ + wm₁` et `P = (1 − w)(P₀ + d₀d₀ᵀ) + w(P₁ + d₁d₁ᵀ)`.
3. Remise à zéro de DS (`sigma_seance`) et de DE.
4. Résumé `(jour, moyenne des résidus normalisés, moyenne des résidus relatifs, nombre, w, résidu e1RM)`, s'il y a des résidus ; il est ajouté à `histoire_residus`.

### 4.6 Bruits de processus et garde-fou numérique

Les bruits de processus sont ceux du § 4.4.

Après chaque série, `_projeter` agit sur les deux branches : KN, KM, KL et KG sont ramenés à 0 s'ils sont négatifs, et λ est borné dans [−0,3 ; 1,2]. Seules les moyennes changent.

---

## 5. Modèles de mesure

### 5.1 Courbe répétitions-charge

```
C_LIN = 0,0265   C_LOG = 0,0892   (égales à 8 répétitions : C_LOG·ln 8 = C_LIN·7)
g(λ, k, R)  = e^k·[(1 − λ)·C_LIN·(R − 1) + λ·C_LOG·ln R]      (R < 1 → 1)
g'(λ, k, R) = max(0,004 ; e^k·[(1 − λ)·C_LIN + λ·C_LOG/R])
```

`g` vaut −ln de la part de la capacité soulevable R fois.

- Courbe d'un exercice suivi : `λ = clamp(m[LAM], −0,3 ; 1,2)` et `k = clamp(m[KU] + m[κ_e], −1 ; 1)`.
- Courbe de population g₀ : `λ₀ = courbe_forme[0]` et `k₀ = courbe_echelle[0] + (courbe_bas_du_corps si bas)`.

**Inverse** (`reps_a(x)`, avec `x = ln(capacité/charge)`) :

- si `x ≤ 0` : `1 + 20x` pour `x > −0,05`, sinon 0 ;
- sinon `R₀ = 1 + x/g'(1)`, puis **12** pas de Newton `R ← R − (g(R) − x)/g'(R)`, en bornant R à [1 ; 200] après chaque pas.

`charge_de_part` utilise la même inversion, sur la courbe de population.

### 5.2 Bruit de la note

```
bruit_rir_de(r, R) = b·(plancher + pente·r)/(plancher + pente·reference) × (1 + pente_longue·(R − 12) si R > 12)
b = bruit_rir_par_niveau[niveau] × bruit_rir (multiplicateur appris)
```

- `r` est la réserve **vraie**, bornée à [0 ; 8].
- `R` est le nombre de répétitions possibles à frais prévu, pas les répétitions faites ; pour une tenue, `R = 6`.
- Les constantes sont `bruit_rir_plancher`, `bruit_rir_pente`, `bruit_rir_reference`, `bruit_rir_longue_serie_de` (12) et `bruit_rir_longue_serie_pente`.

**Bruit ajouté par la fatigue de séance** : `extra = (dispersion_fatigue_intra·sj·R)²`, avec `sj` le régresseur intra-séance (§ 5.3).

**Apprentissage du multiplicateur** (`_apprendre_bruit`). Il est appelé après chaque série charge ou reps dont la note donne un intervalle fermé (`resid[2]` vrai), avec z = résidu normalisé :

```
z2   = oubli·z2 + (1 − oubli)·min(z², 9)
z2_n = oubli·z2_n + 1
si z2_n > 12 : bruit_rir = clamp(bruit_rir·(1 + 0,02·(√z2 − 1)), bornes)
```

`z2` et `bruit_rir` valent 1 au départ, `z2_n` vaut 0.

### 5.3 Réserve vraie, réserve perçue, fatigue de séance

**Régresseur intra-séance** de la prochaine série de la piste :

```
sj = Σ_i eff_i·e^(−repos_i/intra_repos_s)·intra_report^(n − 1 − i)
```

Les couples `(eff_i, repos_i)` sont ceux des séries précédentes de la piste dans la séance, avec `eff_i = e^(−max(rir_c, 0)/intra_rir)` et `repos_i = restSeconds` (90 par défaut). Ils sont ajoutés **après** l'observation de chaque série.

**Fatigue et garde :**

```
FI_e  = clamp(m[FI], 0 ; 1,5)·exp(clamp(m[φ_e], −1,5 ; 1,5))
garde = max(0,3 ; 1 − FI_e·sj)
```

**Réserve vraie** d'une série de `reps` répétitions à la charge L : `v = R·garde − reps`.

- Charge : `R = reps_a(η − ln L)`.
- Poids du corps : `R = e^η`.
- `η = base + h_jour·m`.

**Réserve perçue** : `p = (v − ba)/(1 + bp)`, avec `ba = clamp(m[BA], −2,5 ; 2,5)` et `bp = clamp(m[BP], −0,2 ; 1)`.

`Modele.rir_vrai(p) = max(0 ; p·(1 + bp) + ba)` est exposé pour l'application (il vaut 0 si p ≤ 0).

### 5.4 Linéarisation et mise à jour (une passe)

La linéarisation se fait à la moyenne **a priori** de la branche principale (`lin = self.m`), en une seule passe ; il n'y a pas de filtre itéré. La même linéarisation sert aux deux branches.

**Jacobien de `v`** (`_lin_force`) :

- Composantes de `h_jour` : `c·dR·garde`.
- Charge : `[LAM : dλ·garde, KU : dk·garde, κ_e : dk·garde]`. Si `x ≤ 0`, `dR = 20` et `dλ = dk = 0` ; sinon `d = g'(R)`, `dR = 1/d`, `dλ = −e^k·(C_LOG·ln r₁ − C_LIN·(r₁ − 1))/d` avec `r₁ = max(R, 1)`, et `dk = −g(R)/d`.
- Poids du corps : `dR = R` (dérivée de `e^η`), sans terme de courbe.
- Si `sj > 0` et `garde > 0,3` : `[φ_e : −R·sj·FI_e]`.

**Perçue** : tous les coefficients sont divisés par `1 + bp`, et on ajoute `[BA : −1/(1 + bp), BP : −p/(1 + bp)]`. Les bornes (clamp) ne sont pas dérivées.

**Constante** : `const = prédiction − Σ c_i·lin_i`. L'observation porte sur `u = Σ c_i x_i + const`.

**Mise à jour** (`_observer(idx, co, const, a, b, s², point, melange, bruit, fonction, fige)`), pour chaque branche, dans l'ordre principale puis alternative :

1. `μ = Σ c_i m_i + const`, `ph = P·c` (somme des colonnes `c_i·P[:, i]` dans l'ordre des indices) et `v = Σ c_i ph_i`.
2. Moments a posteriori `(logZ, μ₂, v₂)` :
   - observation ponctuelle : Kalman scalaire (`point_moments`) ;
   - note avec bruit dépendant de u : `category_moments` avec queue lourde (§ 5.6) ;
   - sinon : `interval_moments(μ, v, s², a, b)`.
3. **Mélange** (note aberrante ou paresseuse), poids `(w_main, w_nul)` :
   - `la = ln w_main + logZ` ; `lb = ln w_nul` ;
   - poids normalisés `wa`, `wb` ;
   - moyenne `wa·μ₂ + wb·μ` ;
   - variance `wa·(v₂ + (μ₂ − moy)²) + wb·(v + (μ − moy)²)` ;
   - `logZ = max + ln(somme)`.
4. **Résidu**, sur la branche principale :
   - `informatif` = point, ou intervalle à deux bornes finies ;
   - `dehors` = intervalle ouvert et prévision hors de la borne ;
   - si informatif ou dehors : `resid = ((centre − μ)/√(v + s²), centre − μ, informatif et non ponctuel)`. Le centre est le point, la borne finie, ou le milieu de l'intervalle.
5. Si `v ≤ 0`, la branche n'est pas mise à jour.
6. **Composantes considérées** (filtre de Schmidt). Si `fige` est donné, le gain `pg` est `ph` dont les composantes de `fige` sont mises à 0 : elles pèsent dans la variance prévue `v`, mais l'observation ne les déplace pas. Sinon `pg = ph`.
7. **Grande surprise** (`|μ₂ − μ| > 1` et carte exacte `fonction` fournie) :
   - `pas = pg·(μ₂ − μ)/v` ;
   - si `|f(m + pas) − μ| > |μ₂ − μ|`, **12** dichotomies sur α ∈ [0 ; 1] : on garde la borne basse, avec le même test à `m + α·pas` ;
   - `m += α·pas` ;
   - covariance par la forme de Joseph du gain réduit α·K : `v₂α = v − (2α − α²)·(v − v₂)` ; puis `P −= ph·phᵀ·(v − v₂α)/v²`, ou la mise à jour partielle ci-dessous avec `v₂α` si `fige` est donné (la formule vaut la mise à jour ordinaire pour α = 1) ;
   - `f` recalcule la prévision exacte (`_lin_force` ou `_lin_tenue`) en un état donné. Dans la branche alternative, `μ` est la prévision linéaire de cette branche, alors que `f` est évaluée exactement sur son état (deuxième partie du constat de relecture m1, non corrigée).
8. Sinon, si `fige` est donné : `m += pg·(μ₂ − μ)/v` et `P −= w·(pg·phᵀ + ph·pgᵀ − pg·pgᵀ)` avec `w = (v − v₂)/v²` (`_covariance_partielle`). Le bloc des composantes considérées reste intact ; P reste semi-définie positive si v₂ ≥ 0.
9. Sinon, report de rang 1 : `m += ph·(μ₂ − μ)/v` ; `P −= ph·phᵀ·(v − v₂)/v²`.
10. Log-poids de la branche : `+= logZ`.

**Observations hors séance** (`_observer_hors` : déclaration, refus motivé, charge manuelle). L'observation passe par `_observer` et met donc à jour **les deux branches** si une séance est ouverte ; les log-poids des deux branches sont ensuite remis à leur valeur d'avant (l'observation ne dit rien du mauvais jour).

### 5.5 Catégories de flammes, catégorie ouverte, noteur entier

Les intervalles sont ceux du § 1.5. La catégorie ouverte vaut `[r − d ; +∞)` pour r ≥ `rir_ouvert`.

**Porte de la note ouverte** (séries de force seulement). Si `b = +∞`, que la note est perçue et que `prévision ≥ a + porte_note_ouverte·√s²`, la série ne met pas l'état à jour (résidu `None`). Avec `porte_note_ouverte` = 1,0, une note « 4 ou plus » n'est versée que si la prévision est à moins d'un écart-type au-dessus de la borne, ou en dessous. Sans cette porte, chaque note facile rognait la queue basse de la prévision et faisait dériver l'e1RM vers le haut chez un athlète qui stagne (constat de relecture B1). Les tenues n'ont pas cette porte (annexe A).

### 5.6 Quadrature `category_moments` et queue lourde

Entrées : `(m, v, a, b, noise_var, steps = 52, span = 6,5, gross, gross_sd)`. Le pas est choisi sur la vraisemblance et non sur l'a priori.

```
sd = √v ; si sd ≤ 0 → (0, m, v)
nv_min = min(noise_var(m), noise_var(a) si a fini, noise_var(b) si b fini)
large  = √nv_min si nv_min > 0, sinon 0
fini   = a et b finis ; si fini et ½(b − a) > large : large = ½(b − a)
zlo = −span ; zhi = span
si fini :
    nv_max = max(noise_var(m), noise_var(a), noise_var(b))
    T  = √(nv_max + (gross_sd² si gross > 0, sinon 0))
    zlo = max(zlo, (a − 8T − m)/sd) ; zhi = min(zhi, (b + 8T − m)/sd)
    si zhi ≤ zlo → interval_moments(m, v, noise_var(m), a, b)
n = 2·steps (104)
si large > 0 : besoin = ceil((zhi − zlo)·sd/(0,5·large)) ; si besoin > n : n = min(besoin, 1200)
h = (zhi − zlo)/n ; z_i = zlo + i·h pour i = 0 … n (n + 1 points)
u_i = m + sd·z_i ; w_i = e^(−z_i²/2) ; σ_i² = noise_var(u_i)
L_i = mass(a, b, u_i, σ_i) ; avec queue lourde : L_i = (1 − g)·L_i + g·mass(a, b, u_i, √(σ_i² + gs²))
s0 = Σ w_i L_i ; s1 = Σ w_i L_i z_i ; s2 = Σ w_i L_i z_i²     (sommes dans l'ordre de i)
sw = √(2π)/h                                               (masse a priori analytique)
si s0 < 1e-280·sw → interval_moments(m, v, noise_var(m), a, b)
mz = s1/s0 ; vz = max(1e-12 ; s2/s0 − mz²)
retour (ln(s0/sw), m + sd·mz, v·vz)
```

`(g, gs) = note_erreur_grossiere`. La masse a priori est analytique parce que la grille peut ne couvrir qu'une fenêtre. Le résultat a été contrôlé contre une quadrature dense (relecture, constat M4).

**`mass(a, b, u, t)`** (`_category_mass`) = P(a ≤ u + e ≤ b), avec e ~ N(0, t²) :

- `a = −∞` : 1 si `b = +∞`, sinon `½·erfc(−(b − u)/t/√2)` ;
- `b = +∞` : `½·erfc((a − u)/t/√2)` ;
- sinon `lo = (a − u)/t` et `hi = (b − u)/t` ; si `lo > 0`, `½·(erfc(lo/√2) − erfc(hi/√2))`, sinon `½·(erfc(−hi/√2) − erfc(−lo/√2))` ; résultat borné à ≥ 0.

La référence Python appelle ici `math.erfc` (bibliothèque C) pour la vitesse ; l'écart avec `numerique.erfc` est au plus 2e-13 (testé). Le portage Dart appelle `erfc` du module (§ 9.3).

**Fonction de bruit d'une note de force** :

```
noise_var(u) = bruit_rir_de(clamp(u·(1 + bp) + ba ; 0 ; 8), R)² + extra
```

Elle convertit la réserve perçue u en réserve vraie.

### 5.7 Note aberrante, note paresseuse

Pour une note perçue :

- `ε = note_aberrante` ;
- `par = clamp(a/(a + b) ; 0,01 ; 0,9)` si la note est égale à `target.flames`, sinon 0 ;
- poids du mélange : `w_main = (1 − ε)(1 − par)` et `w_nul = 0,1·ε + (1 − ε)·par` (une note aberrante tombe au hasard sur l'une des 10 flammes).

`(a, b)` part de `note_paresseuse_a_priori`. Après la mise à jour, si la cible a des flammes et que `|resid[1]| > 1`, on ajoute 1 à `a` quand la note vaut la cible, à `b` sinon. Le noteur entier est compté avant la mise à jour, sur toute série non ratée.

### 5.8 Séries de force : cas

L'ordre des tests est le suivant :

1. **Barre manquée** (`failed` et `reps ≤ 0`). Pour une charge seulement, intervalle `(−∞ ; 0]` sur `u = h_jour·x + base − ln L`, avec `s² = bruit_test²`. La série ne donne aucune observation pour un exercice `reps`. `rir_c = 0`.
2. **Série ratée avec des répétitions** : réserve **vraie** dans `[0 ; 1]`, sans perception ni mélange, avec `s² = 0,35² + extra`.
3. **Série sans note** : réserve vraie dans `[0 ; +∞)`, avec `s² = 0,35² + extra`. Elle n'est versée **que si la prévision la contredit** (prévision < 0, c'est-à-dire moins de répétitions possibles que de répétitions faites) ; sinon elle ne met pas l'état à jour (résidu `None`). Quand elle est versée, la forme de courbe λ et l'échelle propre κ_e (λ seul pour un exercice `reps`) sont « considérées » (`fige`, § 5.4) : la série dit que la capacité est plus haute, pas quelle est la forme de la courbe. Versée à chaque série, la borne « au moins n répétitions » ne pouvait déplacer l'état que vers le haut (cliquet observé au rejeu d'un journal réel où la plupart des séries ne sont pas notées). Écart au cahier § 3 (annexe A).
4. **Note 10** : réserve perçue dans `(−∞ ; 0,25]`.
5. **Autre note** : intervalle du § 1.5 sur la réserve perçue, sous la porte de la note ouverte (§ 5.5).

Pour une note perçue, `s² = bruit_rir_de(clamp(v ; 0 ; 8), R)² + extra` ; ce `s²` sert au résidu et à la porte. Les séries d'une charge ≤ 0 sont ignorées. Les cas 2 à 5 passent la carte exacte (`fonction`) à `_observer`.

**Après la mise à jour** :

- `_projeter` ;
- `rir_c = max(0, v)`, recalculé sur l'état a posteriori en réserve vraie (0 si échec) ;
- compartiments, puis `series_seance.append((e^(−rir_c/intra_rir), repos))`, puis stimulus ;
- `mesures += 1` ;
- `dernier_test_jour = jour` si échec, `repere`, ou `role` ∈ {test, attempt} ;
- `meilleur` mis à jour si la série est réussie et chargée.

### 5.9 Tenues (survie)

`ln_s = ln(max(secondes, 0,5 si 0)/garde)` ; `extra_t = (dispersion_fatigue_intra·sj)²` ; `bt = bruit_tenue`.

| Cas | Observation |
| --- | --- |
| Tenue ratée | temps limite observé : point `u = h_jour·x + base − ln_s = 0`, `s² = (bt/2)² + extra_t` |
| Réussie sans note | censure à droite : `u ∈ [0 ; +∞)`, `s² = bt² + extra_t`, versée **seulement si la prévision la contredit** (`μ + base − ln_s < 0`) ; sinon rien |
| Réussie avec note | réserve linéarisée (ci-dessous), puis comme une note de force |

**Réserve d'une tenue notée :**

```
hh   = clamp(m[HH], 0,03 ; 0,30)·exp(clamp(m[κ_e], −1 ; 1))
part = min(3 ; e^(ln_s − η))
r    = (1 − part)/hh
```

Coefficients : `c·part/hh` sur `h_jour`, `κ_e : −r` ; réserve perçue comme au § 5.3.

**Bruit** :

```
noise_var(u) = bruit_rir_de(clamp(u(1 + bp) + ba ; 0 ; 8), 6)² + (bt/hh₀)²/(1 + bp)² + (dispersion·sj/hh₀)²
hh₀ = clamp(m[HH], 0,03 ; 0,30)
```

Le `s²` du résidu vaut `noise_var(prévision)`. Les règles de mélange sont celles du § 5.7. La porte de la note ouverte ne s'applique pas aux tenues.

`rir_c` : 0 sur un échec ; 2 pour une tenue réussie sans note ; sinon `max(0, r)` a posteriori.

### 5.10 Endurance (cardio, conditionnement)

La série doit porter `demand > 0`, sinon elle est ignorée. `ln_d = ln demand`.

**Paramètres selon le type :**

| | cardio | wod |
| --- | --- | --- |
| pente | `cardio_pente_rir` | `wod_pente_rir` |
| neutre | `cardio_charge_neutre` | 1 |
| bruit | `bruit_cardio` | `bruit_wod` |
| `rir_cible` sans flammes cibles | 5 | 2 |

Avec des flammes cibles, `rir_cible` = leur réserve.

**Observations :**

- **Séance écourtée** (`doneShare < 0,999`) : `u = h_jour·x + base − ln_d ∈ (−∞ ; −ln 1,3]`, avec `s² = bruit²`.
- **Sinon, avec une note** :
  - `rel = e^(ln_d − η)` ;
  - prévision = `rir_cible − pente·(rel − neutre)` ;
  - coefficients `c·pente·rel` ;
  - intervalle de la note, avec `s² = bruit_rir_endurance²` ;
  - sans perception, sans biais, sans mélange.

**Effets sur l'état :**

- compartiments : effort `0,6` sans note, sinon `effort(réserve de la note)`, × `fatigueSets` ;
- stimulus : + `dose` sur les trois compteurs ;
- `mesures += 1`.

### 5.11 Raison de refus, charge manuelle, changement de cran

Ces observations portent sur la capacité à frais (`h_frais`), passent par `_observer_hors` et ne visent que les exercices `charge`. Le refus et la charge manuelle sont sans effet si `reps` est absent ou si la masse totale est ≤ 0 ; un `rir` absent vaut 0.

- **Refus motivé** (`too_heavy`, `too_light`) : `u = h_frais·x + base − ln(masse) − g(λ, k, reps + rir)`. L'intervalle vaut `(−∞ ; 0]` pour `too_heavy`, `[0 ; +∞)` pour `too_light`, avec `s² = bruit_raison_refus²`.
- **Charge manuelle** : même `u`, observation ponctuelle 0, `s² = bruit_charge_manuelle²`.
- **Cran d'élastique** : `m[δ_e] += ln facteur` et `P[δ_e, δ_e] += changement_cran_elastique_sd²`, sur les deux branches.

### 5.12 Fonctions numériques

- **`interval_moments(m, v, s², a, b)`** :
  - `t = √(v + s²)`, `lo = (a − m)/t`, `hi = (b − m)/t` ;
  - masse `z` calculée du côté précis : si `lo > 0`, `sf(lo) − sf(hi)`, sinon `cdf(hi) − cdf(lo)` ;
  - si `z < 1e-280` : mise à jour ponctuelle vers la borne la plus proche, `logZ = −640` ;
  - `r1 = (φ(lo) − φ(hi))/z`, `r2 = (lo·φ(lo) − hi·φ(hi))/z`, un terme infini comptant 0 ;
  - `m' = m + v/t·r1` ;
  - `v' = max(1e-12·v ; v − v²/t²·(r1² − r2))`.
- **`point_moments`** : Kalman scalaire, `logZ = −½(ln(2π t²) + d²/t²)`.
- Le § 9 donne le détail à porter ligne pour ligne.

---

## 6. Séance : prescription

### 6.1 Ouverture (`Seances.ouvrir`)

1. Note la semaine (`garde.noter_semaine(semaine, genre, intention)`). Une semaine est **de charge** si `intention or genre` ∉ {deload, taper, test, competition, transition}.
2. Calcule le palier et le décalage du bilan (§ 8.2, A5.1). Le décalage (`Seances.decalage`) n'est pas utilisé ensuite.
3. **Coupure** (`_coupure`) : si la dernière séance fermée date d'au moins `coupure_j` jours, `coupure` = cet écart ; sinon, si une coupure d'au moins `coupure_j` jours précède une séance de retour qui date de `coupure_fenetre_j` jours au plus (toute la semaine du retour), `coupure` = cette coupure ; sinon 0. Les 20 derniers jours de séance sont gardés.
4. **Retour** (`_retour`) : jour de la séance de retour de la dernière coupure d'au moins `coupure_j` jours (aujourd'hui si la coupure finit aujourd'hui), ou `None`.
5. Vide les raisons, puis émet `koach.douleur_persistante` pour chaque zone de `garde.renvois()` (renvoi vers un professionnel, § 8.2).
6. Vide les plans ; calcule les budgets de reprise par zone (§ 8.3).
7. Remet à zéro la mémoire de séance de chaque exercice.

### 6.2 `prescrire(items, grilles, zones, roles)`

Pour chaque item, dans l'ordre :

1. `zones_ex[id]` est mémorisé (sert aux doses par zone en fin de séance).
2. **`_item`**, dans cet ordre :
   1. **Conduite sous douleur** (`garde.conduite(niveaux, zones provoquées, est_test, depuis_jour, fiche, echauffement)`, § 8.1 et § 8.2), avec `depuis_jour` = jour de la dernière séance de l'exercice. Exercice retiré : `koach.douleur_retrait` (cause = raison de la conduite, dont `poignet_chaud` et `poignet_charge`) et item supprimé.
   2. **Test un jour de bilan ≥ 1**, hors jour d'épreuve : `koach.test_reporte` et item supprimé.
   3. **Plan de l'emplacement** :
      - `sans_hausse` = conduite sans hausse, ou palier ≥ 1, ou coupure en cours (`coupure > 0`) pour un exercice `charge`, `reps` ou `tenue` ;
      - `rir_bonus` = conduite, + `bilan_rir_bonus` au palier 1, + 2 × `bilan_rir_bonus` au palier 2 ;
      - `rir_min` = conduite ; au palier 2, au moins `bilan_bas_rir_min` ;
      - `part_max`, `dose_plafonnee`, `fragile` (zone fragile du profil sollicitée) = conduite ;
      - `verrou` = semaine verrouillée (`intention or genre` ∈ SEMAINES_VERROUILLEES, ou `genre` ∈ {deload, test, intro}).
   4. **Raisons du poignet** : `koach.poignet_appui_neutre` si la conduite conseille un appui neutre ; `koach.poignet_dose` si le poignet est sensible (hors échauffement).
   5. **Technique** (`_technique`, § 6.8).
   6. **Séries**, pour un item `charge`, `reps` ou `tenue` hors test :
      - hors échauffement, facteur de la conduite : `max(1, floor(séries·f + 1e-9))` ;
      - échauffement compris, si `coupure ≥ coupure_j` : `n = floor(séries·coupure_series + 0,5)`, appliqué si `1 ≤ n < séries`, avec `koach.reprise_coupure` ;
      - hors échauffement, au palier 2, si l'item a des flammes : une série de moins, sans descendre sous 3 (rôle `main`) ou 2 ;
      - hors échauffement, alerte de surmenage (`_surmenage`, § 6.8).
   7. **Budget de reprise** (hors échauffement) : pour chaque zone provoquée qui a un budget, dans l'ordre trié des zones, les séries sont bornées par le reste (`koach.reprise_dose`). Zéro série : `koach.douleur_retrait` (cause `reprise_dose`) et item supprimé. Sinon le budget est débité.
   8. `sets` est posé ; `setTargets = None` pour un item de travail `charge`, `reps` ou `tenue`.
3. **Retour gradué au volume** (`_retour_gradue`, § 8.3), avec les budgets de la semaine calculés une fois avant la boucle (`_budgets_retour`). Zéro série : item supprimé (et son plan).
4. **Vrai test** (§ 6.4), si l'item est de travail et que l'exercice n'a pas encore été testé dans cette prescription.
5. Après la boucle : **lignes d'endurance** (`_endurance`, § 6.7) sur la liste servie, puis **durée bornée** (`_duree_bornee`, § 8.3). La liste servie finale est gardée pour la fin de séance (`servis`).

### 6.3 `cible(item, index)` : série suivante

L'ordre des cas :

1. Sans plan, échauffement ou autre type que `charge`, `reps` ou `tenue` : la cible écrite (`_ecrit`).
2. `échecs ≥ echecs_arret` hors test : `koach.arret_exercice`, renvoie `None`.
3. Test : § 6.5.
4. Sinon, selon le type : `_cible_charge`, `_cible_reps` ou `_cible_tenue`.

**Réserve visée** (`rir_cible`) :

```
rir = réserve(targetFlames) (2,5 sans flammes) + rir_bonus ; au moins rir_min ; au plus 5
flammes affichées = flammes_de_rir(rir)
```

**Plage** (`_plages`) : `repsLow`, `repsHigh` ; pour une série de tête (`top_set_backoff`) à partir de l'index 1, `backoffRepsLow` et `backoffRepsHigh`.

#### `_cible_charge` (ordre exact)

1. **Calibrage.** Si `mesures = 0` et `σ(capacité) > 0,12` (σ de `capacite`, défaut de modèle compris) : plage, `loadKg = None`, flammes.
2. **Charge du modèle.**
   - `reps` = `repsHigh` si la plage est un point, sinon le milieu de la plage ;
   - prudence = `prudence_charge[1]` après plus de 3 séances, `prudence_charge[0]` sinon ;
   - `voulu = charge_pour(reps, rir, prudence) = exp(μ_jour − prudence·σ_jour − g(λ, k, (reps + rir)/garde)) − bw`, avec `bw = fraction·poids` et `garde` la garde courante.
3. **Séries allégées** (série de tête, index ≥ 1, tête connue) : `voulu = min(voulu, (tête + bw)·(1 − drop) − bw)`.
4. **Écart de planification.** Si `koachIntensite` est non nul hors verrou : `voulu = (voulu + bw)·(1 + clamp(écart, ±plafond_intensite)) − bw`.
5. **Surcharge sur zone fragile du profil.** Si une part écrite dépasse `surcharge_fragile_max` sur une zone fragile : la part est ramenée à `surcharge_fragile_max` (`koach.zone_fragile`, cause `surcharge`).
6. **Part écrite** (`percentOfOneRm`, sauf séries allégées) :
   - `charge_de_part(part)` lit la part comme un **niveau d'effort**. Si part ≥ 1, la charge vaut `e^μ·part`. Sinon : `R` = inverse de g₀ en `−ln part` (Newton, 12 pas, R ∈ [1 ; 200]), puis la charge vaut `exp(μ − g(λ, k, R))`. μ est la capacité à frais (du jour si demandé) ;
   - le plafond vaut `charge_de_part(part) − bw` en semaine verrouillée, pour un débutant, ou si part ≥ `couloir_part_lourde` ; sinon `charge_de_part(part·(1 + couloir_haut_max)) − bw`.
7. **Plafond de la conduite** : `charge_de_part(part_max) − bw`.
8. **Simple d'entraînement** (`repsLow = repsHigh = 1`, hors test) : au plus `charge_de_part(simple_part_max ou simple_part_max_bilan_bas si palier ≥ 1, du jour) − bw`.
9. **Grille** : `charge = grille.proche(max(voulu, minimum))`.
10. **Test adaptatif** (index 0, ni `sans_hausse` ni verrou, au moins 1 séance). Parmi le cran du dessous et celui du dessus :
    - un candidat est admissible si `|reps_prevues(cand, 0) − reps − rir| ≤ ecart_rir_tolere` et `cand ≤ voulu + pas` ;
    - il remplace la charge si son information dépasse de plus de 2 % celle de la meilleure charge, dans l'ordre précédent puis suivant ;
    - l'information vaut `cov²/(var + s²)`, avec `cov = h_frais·P·c`, `var = cᵀPc` (c = jacobien perçu de la série) et `s² = bruit_rir_de(clamp(v ; 0 ; 8), R)²`.
11. **Bornes de hausse** (`_bornes_hausse`, index 0 seulement). `douleur` = zone de conduite ou `koachFragile` ; `profil` = zone fragile du profil ; `fragile` = l'un ou l'autre ; `h = hausse_par_niveau[niveau]`, × `hausse_fragile_facteur` si fragile. Toute ligne chargée suit cette borne, accessoires compris (aucun doublement hors rôles principal et secondaire).
    - **Schéma connu** à cet emplacement, clé `(slotId, repsHigh)`, valeur `(charge, verrou)` :
      - si `sans_hausse` ou verrou (dernière séance ratée ou répétitions non atteintes) : au plus la charge de la dernière séance ;
      - sinon, si `charge > (avant + bw)(1 + h) − bw` : `charge = max(plancher(haut), min(charge, suivant(avant)))`, ce qui laisse toujours un cran.
    - **Schéma nouveau** : borne = maximum, sur les barres réussies des `barre_recente_j` derniers jours, de :
      - `c` si `sans_hausse` ou `douleur` ;
      - sinon `max(plancher((c + bw)(1 + hp)(1 + schema_change_part·r') − bw) ; suivant(c))`, avec `hp = premiere_hausse` (× `hausse_fragile_facteur` sur zone fragile du profil) et `r' = clamp(r − repsHigh ; 0 ; schema_change_reps_max)`, 0 sur zone fragile du profil.
    - **Schéma changé au même emplacement** (règle 4 de A7.2) : si la marque de l'emplacement (§ 6.6) porte un `repsHigh` différent, `base` = base de semaine de charge, sinon base de la dernière séance ; plafond = `max(plancher((base + bw)(1 + h)(1 + schema_change_part·r'') − bw) ; suivant(plancher(base)))`, avec `r'' = min(écart de répétitions, schema_change_reps_max)` si l'écart est positif et la ligne non fragile, 0 sinon.
    - Sur zone fragile du profil, une baisse émet `koach.zone_fragile` (cause `hausse`).
12. **Après un échec dans la séance** (`baisse < 1`) : la charge ne dépasse pas `plancher((charge_item + bw)·baisse − bw)`.
13. **Index ≥ 1 avec `sans_hausse`, un échec ou `dose_plafonnee`** : pas plus que la charge de la série précédente.
14. **D'une série à l'autre** (index ≥ 1, hors série de tête) :
    - au plus `(charge_item + bw)·1,05 − bw`, avec un cran permis : `max(plancher(haut), min(charge, suivant(charge_item)))` ;
    - au moins `proche((charge_item + bw)·0,85 − bw)`.
15. **Zone douloureuse ou en reprise, bilan bas, coupure en cours** (`sans_hausse` ou raison de conduite) : au plus `charge_derniere`, la plus lourde charge du dernier passage de l'exercice. En semaine verrouillée, la charge n'est bornée que par la part écrite (étape 6) et les bornes de hausse : la borne « dernier passage » a été essayée puis retirée, car elle sous-chargeait les semaines de décharge et doublait les fausses alertes de rupture sur le banc (0.3.1 borne par la charge écrite).
16. Au moins le minimum de la grille. À l'index 0, la charge devient la tête.
17. **Série repère** (§ 6.4) :
    - `charge_r = plancher(max(min(charge_pour(repsHigh, rep, 0,5) ; (récente + bw)(1 + repere_hausse) − bw) ; minimum))`, au moins la charge de travail ;
    - « récente » = la plus lourde barre réussie de moins de 42 j (constante du code), sinon la tête ;
    - à l'index 0 (ligne d'une seule série), `charge_r` passe ensuite par `_bornes_hausse` avec `repsHigh + reps_ouvertes` ;
    - retour `{repsLow, repsHigh + reps_ouvertes, loadKg: charge_r, flames: flammes_de_rir(rep), repere: True}`.

#### `_cible_reps`

1. Si `mesures = 0` : la plage écrite.
2. **Prévision.** `sûr = floor(prévu·e^(−σ/2) + 0,3)`, avec `prévu = e^μ_jour·garde − rir`.
3. **Plage étendue.** Si l'item est libre (ni verrou, ni `sans_hausse`, ni raison de conduite, ni échec, ni `dose_plafonnee`), sans technique et sans élastique (`type_charge`), et que `sûr > haut` : `haut = min(sûr, 2·haut, 30)`.
4. **Bas de plage.** Si `sûr < bas` : `bas = max(1, sûr)`.
5. **Verrous.**
   - Après `sans_hausse` ou un échec à la dernière séance : `haut ≤ max(reps_max, 1)`.
   - Zone récente (`hausse_quantite` de la conduite) : `haut ≤ max(floor(reps_max·(1 + h)), reps_max + 1)`.
   - Après un échec dans la séance : `haut ≤ reps de la série précédente`.
   - `dose_plafonnee`, index ≥ 1 : `haut ≤ reps de la série précédente`.
6. Si le bas dépasse le haut, `bas = haut`.
7. **Série repère** : `{bas, min(max(2·haut écrit, haut), 60), flammes du repère, repere}`.

#### `_cible_tenue`

1. Si `mesures = 0` : la plage écrite.
2. **Prévision.** `prévu = e^μ_jour·garde·max(0,15 ; 1 − hh·rir)` ; `sûr = floor(prévu·e^(−σ/2))`.
3. **Plafond.** `haut ≤ floor(tenue_part_max·e^μ_jour)` si cette valeur est ≥ 1 (valeur centrale, jamais un quantile haut).
4. **Tendons.** Pour un schéma `figure_statique*` : `h = tenue_hausse_par_niveau[niveau]` ; la `hausse_quantite` de la conduite s'applique aussi (minimum des deux). Si un maximum est connu, `haut ≤ max(floor(sec_max·(1 + h)), sec_max + tenue_hausse_marge_s)` (`koach.tendon`).
5. **Verrous.** Après `sans_hausse` ou un échec : `haut ≤ sec_max`. Après un échec dans la séance, ou avec `dose_plafonnee` à l'index ≥ 1 : `haut ≤ sec` de la série précédente.
6. **Temps total de l'emplacement** (bras tendus, `h` défini, plus d'une série, total de la dernière séance de l'emplacement connu) : si `haut·séries > max(floor(total·(1 + h)), total + tenue_hausse_marge_s)`, `haut ≤ max(1, ce maximum // séries)` (`koach.tendon`, cause `total`).
7. `haut` vaut au moins 1 ; `bas = min(lo, haut)`, puis `max(1, sûr)` si `sûr < bas`.
8. **Tenue repère**, sauf en bras tendus sans maximum connu : `secondsHigh` = haut si une borne de tendon s'applique, sinon `max(haut, min(2·hi, 180))`.

### 6.4 Séries repères et vrai test

**`_mesure_utile`** est vrai si toutes ces conditions tiennent :

- l'item a au moins une série ; ce n'est ni un test ni un échauffement ;
- ni verrou, ni `sans_hausse`, ni échec dans la séance, ni raison de conduite, ni `dose_plafonnee` ;
- pas de coupure en cours (`coupure > 0`) ; après un retour de coupure, au moins `retour_seances_avant_mesure` séances de l'exercice depuis le retour ;
- pas de `jours_avant_echeance ≤ 14` ; pas de `dayStress = light` ;
- la technique est absente, `standard`, `top_set_backoff` ou `isometric_hold` ;
- `1,6448536269514722·σ > intervalle_declenchement`, avec σ de `capacite` (défaut de modèle compris) ;
- dernière mesure il y a au moins `jours_min_entre_tests` jours ;
- pas un débutant avec moins de 3 séances.

**Série repère** : la dernière série de l'item (`index = sets − 1`) quand `_mesure_utile` est vrai. Réserve 2 pour un débutant, 1,5 sinon (constantes du code). Une série repère chargée qui est aussi la première série (ligne d'une seule série) passe par les bornes de hausse d'une séance à l'autre (`_bornes_hausse`) sur le schéma ouvert (`repsHigh + reps_ouvertes`), comme une première série ordinaire (critère « hausse de charge > 10 % sur plusieurs crans » du banc).

**Vrai test** (`_vrai_test`), si toutes ces conditions tiennent :

- rôle `main` ou `secondary`, type `charge`, au moins 2 séries ;
- piste vue au moins une fois ; `_mesure_utile` ;
- grille et `charge_max` connus ;
- au moins une barre réussie depuis `barre_recente_j` jours ;
- `suivant(ref) + bw ≤ (ref + bw)·(1 + rampe_pas)` : la grille n'est pas trop grossière.

Il renvoie `(n, rir)` : `(test_reps_debutant, test_rir_debutant)` au niveau 0, `(test_reps_avance, test_rir_avance)` au niveau ≥ 2, `(test_reps, test_rir)` sinon.

Séries de la ligne pour la montée : `lignes = min(séries écrites, séries servies)` (servies après douleur, bilan, surmenage et retour gradué). Séries dures de la montée au plus `max(1, lignes − 1)` ; montée + séries de travail ≤ `lignes` (arrêt `volume_test` de `cible`).

### 6.5 Tests servis (`_cible_test`)

**`one_rm` ou `attempt_simulation` (charge)** : échelle des tentatives (`_tentative`).

- `μ` = μ_jour + ln(1 − `tentative_bilan_bas_part`·palier − `tentative_bilan_bas_part` si une zone de conduite existe) ; `σ = max(σ_jour, 0,01)`.
- `plus_lourde(p, plafond) = plancher(max(min(e^(μ − Φ⁻¹(p)·σ), plafond) − bw ; minimum))`.
- Flammes affichées : 7, 9, 10 selon l'index.
- **Ouverture** (index 0 ou aucune charge dans la séance) :
  1. `plus_lourde(tentative_ouverture_proba, tentative_ouverture_part·e^μ)` ;
  2. remplacée par la plus lourde barre réussie de moins de `barre_recente_j` jours si elle est plus légère et que `récente + bw ≥ tentative_recente_part·e^μ` ;
  3. plafonnée par le maximum, sur ces barres, de `(c + bw)(1 + premiere_hausse)(1 + schema_change_part·min(r − 1, schema_change_reps_max)) − bw`, ramené sur la grille. C'est une règle propre à Koach.
- **Après un échec dans la séance** : la même barre.
- **Tentatives suivantes** :
  1. `p` = `tentative_troisieme_proba` à la dernière tentative (index ≥ sets − 1), `tentative_deuxieme_proba` sinon ;
  2. `haut = min((dernière + bw)(1 + saut) − bw ; dernière + tentative_saut_kg)` ;
  3. à la dernière, `koachCible` est tentée si `dernière < cible ≤ haut` et que `P(réussir cible) ≥ 0,35` ;
  4. la charge est bornée par `plancher(haut)` et ne descend pas sous la dernière ;
  5. si elle ne monte pas : `min(suivant(dernière), max(plancher(haut), dernière))`, et la même barre si `P < 0,2`.

**Vrai test** (rampe), dans l'ordre :

1. **Index 0** : sans barre réussie depuis `barre_recente_j` jours, le test s'arrête (`None`). Sinon `charge_pour(n, rir + 2, 0,5)`, plafonné à `(récente + bw)(1 + repere_hausse) − bw`.
2. **Index ≥ 1, fin du test** : le test s'arrête (`None`) sans charge précédente, après un échec, sans note, avec moins de n répétitions, ou sur une note 10.
3. **Confirmation** : si la réserve dite ≤ rir + 0,75, la même barre est refaite pour confirmation ; arrêt après `rampe_confirmations` notes basses.
4. **Pas de montée** : premier pas de `rampe_pas_par_rir` dont `réserve ≥ seuil − rir + 1 − 1e-9`, sinon le dernier pas. `voulu = (dernière + bw)(1 + pas) − bw`, au plus `exp(μ + 2,5·max(σ, rampe_sd_min) − g(λ, k, n)) − bw`.
5. **Grille** : `charge = plancher(voulu)`.
6. **Probabilité** : si `P(réussir) < rampe_proba_min`, essai du plus petit pas ; arrêt s'il n'est pas faisable.
7. **Hausse minimale** : si la charge ne monte pas, `suivant(dernière)` à condition que ce cran soit ≤ `rampe_pas`, sinon arrêt.
8. Effort affiché : 2 en réserve. `repere: True`.

**Test xRM chargé** :

- charge = `proche(charge_pour(repsHigh, targetRir ou 1, 0,25))`, ou `startLoadKg` si `mesures = 0` ou s'il n'y a pas de grille ;
- en semaine verrouillée, au plus la charge écrite `startLoadKg` (ramenée sur la grille par le bas) ;
- avec `sans_hausse`, ou après un échec non prévu à la dernière séance : au plus `charge_derniere` ;
- à l'index ≥ 1 : au moins la charge précédente, ou la même après un échec.

**Test sans charge** (répétitions ou tenue maximale) : la plage écrite, flammes = max(8, flammes de `targetRir` ou de 0).

### 6.6 Retour de série et fin de séance

**`serie_faite`** met à jour :

- la mémoire de séance : charge, répétitions, secondes, échec, flammes ;
- le plan de l'emplacement : charge, flammes, répétitions et échec de la série ; sur un échec, `échecs += 1`, et hors test `baisse = 1 − echec_baisse`.

**`fermer(record)`** :

1. **Doses par zone.** Les séries faites (reps > 0 ou secondes > 0) sont regroupées par `(exerciseId, slotId)`. Chacune ajoute 1 à la dose de la semaine pour chaque zone provoquée (`zones_ex`).
2. **Mémoire par exercice.** Au premier groupe d'un exercice, le jour est ajouté à `jours` et les maximums sont remis à zéro. Puis :
   - `charge_derniere` = la plus lourde charge du groupe (échauffements compris) ;
   - maximums de charge, de répétitions et de secondes (hors échauffement) ;
   - `echec` = un échec hors cible 10 et hors rôles `attempt` et `test` ;
   - barres réussies `(jour, charge, reps)` ;
   - `schemas[(slot, repsHigh de la première série de travail sans rôle)] = (charge, raté ou repsHigh non atteint)` ;
   - **marque de l'emplacement** (`_marquer`) : base de la séance = la plus légère charge ratée, sinon la plus lourde réussie ; la base de semaine de charge n'est pas remplacée en semaine verrouillée ni un jour de bilan bas ; `marques[slot] = (base de semaine de charge, base, repsHigh)` ;
   - temps de tenue total de l'emplacement (hors échauffement, test et tentative), s'il est positif.
3. **Formes de surmenage** (`_formes`, § 6.8).
4. **Volume de la semaine** (`_fermer_volume`, § 8.3) : chaque item servi compte ses séries prescrites, ou ses séries faites si moins ont été faites (au moins une) ; une montée de test ajoutée par Koach compte ses séries dures faites (flammes ≥ 3 ou échec) ; séries hors `nonModelise` et hors endurance. Sans prescription dans la séance, les séries faites du record.
5. **Historique d'endurance** (`_fermer_endurance`, § 6.7).
6. Jour ajouté aux jours de séance (20 gardés) ; `derniere_seance = jour`.

### 6.7 Lignes d'endurance (`_endurance`, `_fermer_endurance`)

Règles A2.3 et A10 de 0.3.1 : jamais plus long, plus loin, plus de répétitions ni plus dur que l'écrit. **Nature** d'un exercice non modélisé (`_nature`) : `course` (fiche `cardio` dont le matériel figure dans `endurance_materiel_course`, hors identifiants `ca-marche*` et `ca-educatif*`), `cardio`, `conditionnement` (fiche `wod`), `mobilite`. La réduction d'une ligne (`reduire(item, part)`) agit sur les séries d'un fractionné, sinon sur la durée, la distance, les répétitions ou les calories de chaque série, arrondies vers le bas (minute au-delà de 300 s, sinon 5 s ; 100 m ; une répétition ; une calorie), jamais au-dessus de l'écrit.

Sans ligne d'endurance et sans course dure la veille, la liste servie est rendue telle quelle. Sinon, dans l'ordre :

0. **Arrêt du bas du corps** (A2.3) : toute course est retirée tant qu'une zone du bas du corps est à l'arrêt (arrêt en cours, pas gardé) (`koach.douleur_retrait`, cause `douleur_arret`).
1. **Reprise après coupure** (A10.1) : selon l'écart au dernier jour actif, part `endurance_reprise` (0,7 après 7 jours, 0,5 après 14). Une course en reprise graduée du bas du corps prend au plus la part longue. Ligne réduite : `koach.endurance_raccourcie`.
2. **Jour sans** (A10.2), cause `bilan_fort` (palier 2), `bilan` (palier 1), `douleur_jambe` (dernière intensité du bas du corps ≥ `endurance_douleur_jambe` depuis `douleur_jours_actifs` jours au plus) ou `course_dure` (course des `endurance_dure_jours` jours d'avant notée `endurance_dure_marge` flammes au-dessus de sa cible, ou au moins `endurance_dure_flammes` + 1 sans cible). Une course de qualité (`_qualite` : réserve des flammes ≤ `endurance_qualite_rir`, intensité écrite, test, ou identifiant parmi `endurance_qualite_ids`) devient une course facile (`endurance_course_facile`) de la durée de travail écrite, à l'effort `flammes_de_rir(endurance_facile_rir)` au plus (`koach.course_facile`), si son matériel figure dans celui de la ligne écrite, si le lieu du jour le permet, si le travail dure au moins `endurance_facile_min_s` et si la course facile n'est pas déjà servie ; sinon elle est retirée (`koach.endurance_retrait`). Au palier 2, course et cardio sont réduits à `endurance_mauvais_jour`.
3. **Course bornée** (A10.3) : avec au moins `endurance_pic_courses_min` courses dans les `endurance_pic_jours` derniers jours, le total des courses du jour est borné à la plus longue × (1 + `endurance_pic`) ; un test plus long devient une course à effort modéré (`flammes_de_rir(endurance_facile_rir) + 1` flammes au plus) ; puis la plus longue ligne perd une série, ou est réduite par `endurance_bornee_reduction`, jusqu'à 50 fois (`koach.course_bornee`).
4. **Conditionnement** (A10.4) : × `wod_echelle` un jour sans (hors cause `course_dure`) ou après `wod_jours_durs` jours durs de suite dans les `wod_fenetre_j` jours (un jour sans séance ne rompt pas la suite, deux oui) ; une flamme de moins au-dessus de l'effort facile + 1 (`koach.wod_echelle`).
5. **Fatigue croisée** (A10.5) : après une course dure la veille, une flamme de moins sur les items modélisés du bas du corps (`koach.fatigue_croisee`).

`_fermer_endurance` tient, sur 60 jours : les jours actifs, les courses `(jour, secondes, flammes notées max, flammes visées)`, les jours de conditionnement dur et de course dure (notés ≥ `endurance_dure_flammes`), et la vitesse de course (distance et durée cumulées des séries qui disent les deux ; sinon `endurance_vitesse`).

### 6.8 Techniques et surmenage

**Techniques** (`_technique`, A9.2). Une technique au-dessus du niveau du profil (`technique_niveau_acces`) devient des séries classiques équivalentes (`equivalent_standard` : paliers au nombre médian de répétitions, échelle au milieu, densité et contre-la-montre en trois séries d'un quart du total, cluster d'une traite aux deux tiers ; règles d'autorégulation de la série de tête retirées). Une technique intensive (`techniques_intensives`) est retirée sur zone douloureuse ou en reprise, au palier 2, en semaine verrouillée ; l'excentrique accentué l'est aussi à `excentrique_echeance_j` jours ou moins d'une échéance et sur zone fragile du profil. Raison `koach.technique_retenue`.

**Surmenage** (A6.2). `_formes`, en fin de séance, suit pour chaque mouvement principal mesuré la grandeur `base + h_frais·m + DS` (mélange des deux branches, avant la fusion). Sur les trois dernières séances, à `surmenage_fenetre_j` jours au plus de la première : si les deux dernières sont toutes deux sous `première + ln(1 − surmenage_baisse)`, une alerte est posée et la séance d'alerte devient la référence. Pendant `surmenage_jours` jours après l'alerte, hors semaine verrouillée et hors semaine `maintenance`, un item principal d'au moins 2 séries perd `max(1, floor(séries·surmenage_coupe + 0,5))` séries (`koach.surmenage` ; le paramètre `part` est arrondi par `round` de Python, voir § 9.4).

---

## 7. Fichier de paramètres

### 7.1 Schéma

Le fichier est un objet JSON. La racine contient :

| Clé | Contenu |
| --- | --- |
| `schema` | entier, 1 |
| `version` | texte |
| `date` | texte |
| `note` | texte |
| `qualites` | 10 textes |
| `classes_reponse` | 5 textes |

Il y a ensuite onze sections d'objets : `a_priori`, `mesure`, `jour`, `fatigue`, `dynamique`, `test_adaptatif`, `planification`, `securite`, `adherence`, `rupture`, `controle_dual`.

- Les valeurs sont des nombres, des listes de nombres, des listes de couples, des textes, des listes de textes ou, pour `securite.technique_niveau_acces` et `securite.endurance_course_facile`, des objets.
- Une paire `[moyenne, sd]` décrit une composante d'état ; `sd = 0` la fige.
- `rupture`, `adherence` et `controle_dual` sont lues par `.get(clé, défaut)`. Les défauts (`DEFAUTS_RUPTURE`, `DEFAUTS_ADHERENCE`, `DEFAUTS_DUAL`, `DEFAUTS_PLAFONDS`) sont tous égaux aux valeurs du fichier. `mesure.defaut_modele_sd` est lue par `.get` avec le défaut 0. Toutes les autres clés sont lues par indexation directe : une clé absente lève une erreur.

### 7.2 Version

Version actuelle : `1.0.0-ref.1`. Un import doit porter la même majeure (`1`) et le même `schema`.

### 7.3 Import (`rupture.importer_parametres(koach, fichier)`)

Le fichier est un texte JSON ou un dictionnaire. L'import passe deux étapes.

**Validation** (`valider_parametres`). Rien n'est appliqué si une erreur est trouvée.

| Contrôle | Règle |
| --- | --- |
| `schema` | identique |
| `version` | texte, même majeure |
| `date`, `note` | textes |
| sections | une section inconnue est refusée |
| `securite` | doit être **identique** à l'actuelle : la sécurité ne peut pas être modifiée par un import |
| types | même type que la valeur actuelle (nombre fini, booléen, texte, liste de même longueur, objet), contrôle récursif |
| clés inconnues | refusées, sauf dans `rupture` et `adherence`, où une clé connue des défauts est admise |
| clés figées (`rupture.FIGEES`) | toute valeur différente de l'actuelle est refusée : `planification.plafond_volume`, `planification.plafond_intensite`, `controle_dual.amplitude_volume`, `controle_dual.amplitude_intensite`, `controle_dual.plafond_volume`, `controle_dual.plafond_intensite` (clés absentes du fichier : sans effet), `controle_dual.semaines_min`, `controle_dual.intervalle_max`, `controle_dual.synthetique_semaines_min`, `controle_dual.bras_semaines`, `test_adaptatif.intervalle_declenchement`, `test_adaptatif.jours_min_entre_tests`, `rupture.douleur_secours` |
| bornes (`rupture.BORNES`), vérifiées seulement sans autre erreur | `jour.mauvais_jour_proba` et `mauvais_jour_proba_bilan_bas` ∈ [1e-6 ; 0,999] ; `mesure.note_aberrante` ∈ [1e-6 ; 0,5] ; `mesure.porte_note_ouverte` ∈ [0 ; 100] ; `dynamique.recuperation_seuil` ∈ [1e-6 ; 1e6] ; `rupture.hasard` ∈ [1e-6 ; 0,5] ; `rupture.alerte` ∈ [0,05 ; 0,999] ; `rupture.residu_secours` et `assiduite_secours` ∈ [0 ; 1] ; `rupture.douleur_secours` ∈ [0 ; 10] ; `rupture.elargissement_rien_de_special` ∈ [1 ; 100] ; `rupture.semaine_allegee_series` ∈ [0,1 ; 1] ; `rupture.semaine_allegee_rir` ∈ [0 ; 5] ; `rupture.course_max` ∈ [10 ; 1000] ; `rupture.fenetre_seances` et `min_observations` ∈ [1 ; 100] ; `rupture.a_priori_alpha` et `a_priori_alpha_nouvelle` ∈ [0,5 ; 1000] ; `rupture.a_priori_beta` ∈ [1e-6 ; 1000] ; `rupture.douleur_recente_j` ∈ [0 ; 60] ; `rupture.residu_reps_reference` ∈ [1 ; 30] ; `adherence.proba_cible` ∈ [0,05 ; 0,99] ; `adherence.a_priori_poids_sd` ∈ [1e-3 ; 100] ; `adherence.biais_initial` ∈ [−5 ; 5] ; `adherence.pas_min` ∈ [1e-6 ; 1e6] ; `adherence.paliers_max` ∈ [1 ; 20] |
| positivité | toute clé numérique qui finit par `_sd` ou commence par `sigma`, `tau` ou `bruit` doit être > 0 |

**Journalisation.** Un fichier valide est versé au journal : `koach.observe({'type': 'parametres', 'fichier': nouveau})`. `rejouer` le réapplique au même endroit, sans le revalider.

**Application** (`rupture.appliquer_parametres(koach, nouveau)`). Fusion superficielle par section, dans l'ordre trié des clés (une valeur hors section remplace la valeur racine). Le dictionnaire fusionné est ensuite assigné à :

- `koach.params`, `modele.p`, `seances.p` ;
- `garde.s` et `seances.s` (section `securite`) ;
- `modele.tau` (recalculé depuis `fatigue`) ;
- `appliquer_parametres(fusion)` de chaque extension qui l'expose (Surveillance : seuils ; Adhérence) ; à défaut, une extension qui porte un attribut texte `cle_params` reçoit la section correspondante dans `x.p` (aucune extension de `koach/` ne le porte).

**Ce qui n'est pas relu après un import :**

| Élément | Où il est figé |
| --- | --- |
| hypothèses de dose et leurs poids | `modele.hypotheses`, `poids_hyp` |
| a priori déjà appliqués à l'état | état courant |
| configuration de la BOCPD | `Surveillance.bocpd` (seuls les seuils sont relus) |
| copie des paramètres de planification | `Planification.p` (pas de `appliquer_parametres`) |
| paramètres du contrôle dual | `ControleDual.params` (pas de `appliquer_parametres`) et `EssaiN1` en cours |
| `qualites` et `classes_reponse` | contrôle de type seul : elles peuvent être renommées |

Ces écarts sont repris dans l'annexe A.

### 7.4 Tableau de toutes les clés

Le tableau est généré depuis le JSON (305 clés, dans l'ordre du fichier) et contrôlé par script : toute clé du JSON absente du tableau, ou l'inverse, est une erreur. « Lu par » donne le module lecteur ; une clé « Non lue » n'est lue par aucun module de `koach/` (recherche de la chaîne de la clé dans le code, hors entrées des dictionnaires de défauts).

| Section | Clé | Valeur | Unité | Rôle | Lu par |
| --- | --- | --- | --- | --- | --- |
| — | `schema` | 1 | — | Version du schéma ; un import doit porter la même valeur | rupture.valider_parametres |
| — | `version` | "1.0.0-ref.1" | — | Version des paramètres ; un import doit garder la même majeure | rupture.valider_parametres, dossier |
| — | `date` | "2026-10-09" | — | Date du fichier (texte) | rupture.valider_parametres (type seul) |
| — | `note` | (texte) | — | Commentaire libre (texte) | rupture.valider_parametres (type seul) |
| — | `qualites` | ["pousser", "tirer", "jambes", "tronc", "figures", "endurance_force", "explosivite", "aerobie", "anaerobie", "mobilite"] | — | Noms des 10 qualités latentes, dans l'ordre des indices 0 à 9 | Non lue par le moteur (contrôle de type à l'import ; lue par le banc) |
| — | `classes_reponse` | ["charge", "reps", "tenue", "cardio", "wod"] | — | Noms des 5 classes de réponse (ordre des écarts EPS ; `modele.CLASSES` fait foi) | Non lue par le moteur (contrôle de type à l'import) |
| a_priori | `theta_sd` | 0.2 | ln | Écart-type a priori de chaque qualité θ_q | modele |
| a_priori | `delta_sd` | 0.3 | ln | Écart-type a priori total de ln capacité d'un exercice chargé | modele.piste |
| a_priori | `delta_sd_declare` | 0.07 | ln | Écart-type (ln) d'une capacité déclarée au profil, si la déclaration n'en donne pas | modele.piste |
| a_priori | `rho_moyenne_par_niveau` | [0.0095, 0.003, 0.0012, 0.0006] | ln/sem. | Réponse à l'entraînement ρ à dose de référence, par niveau 0 à 3 | modele |
| a_priori | `rho_sd_rel` | 0.6 | part | Écart-type de ρ rapporté à sa moyenne | modele |
| a_priori | `eps_classe_moyenne` | [0.0, 0.0029, 0.0029, 0.002, 0.001] | ln/sem. | Écart de réponse par classe (charge, reps, tenue, cardio, wod) au niveau intermédiaire, mis à l'échelle ρ_niveau/ρ_1 | modele |
| a_priori | `eps_classe_sd` | 0.003 | ln/sem. | Écart-type des écarts de classe (même mise à l'échelle) | modele |
| a_priori | `k_nerveux` | [0.0, 0.0] | [moy., sd] | Sensibilité KN au compartiment rapide, part systémique ; figée | modele |
| a_priori | `k_musculaire` | [0.0, 0.0] | [moy., sd] | Sensibilité KM au compartiment lent, part locale ; figée | modele |
| a_priori | `biais_rir_additif` | [0.0, 0.0] | [rép., rép.] | BA : biais additif de la note (perçu = (vrai − BA)/(1 + BP)) ; figé (sd 0) | modele |
| a_priori | `courbe_echelle_exercice_sd` | 0.22 | ln | Écart-type de l'échelle de courbe propre à l'exercice (κ_e) | modele.piste |
| a_priori | `courbe_bas_du_corps` | -0.2 | ln | Moyenne a priori de κ_e pour un exercice du bas du corps (`bas`) | modele, seance, planification |
| a_priori | `fatigue_intra` | [0.85, 0.0] | [moy., sd] | Fatigue intra-séance FI (part des répétitions perdue par unité de régresseur) ; figée | modele |
| a_priori | `part_tenue` | [0.1, 0.0] | [moy., sd] | HH : part du maintien maximal par répétition en réserve ; figée | modele, seance |
| a_priori | `niveau_echelle_charge` | [0.65, 1.0, 1.25, 1.45] | × | Multiplicateur du ratio de charge (1RM/poids du corps) par niveau | modele.base_de |
| a_priori | `facteur_femme` | 0.7 | × | Multiplicateur du 1RM a priori si `sexe` = female | modele.base_de |
| a_priori | `reps_base` | 12.0 | rép. | Répétitions maximales a priori à marge nulle | modele.base_de |
| a_priori | `tenue_base_s` | 30.0 | s | Maintien maximal a priori à marge nulle | modele.base_de |
| a_priori | `pente_difficulte` | 0.3 | ln/point | Pente de ln capacité par point de marge (niveau − difficulté) | modele.base_de |
| a_priori | `reps_sd` | 0.4 | ln | Écart-type a priori total d'un exercice reps ou tenue | modele.piste |
| a_priori | `cardio_minutes_par_niveau` | [30.0, 60.0, 90.0, 120.0] | min | Capacité a priori d'un exercice cardio, par niveau | modele.base_de |
| a_priori | `cardio_sd` | 0.4 | ln | Écart-type a priori total d'un exercice cardio | modele.piste |
| a_priori | `wod_sd` | 0.25 | ln | Écart-type a priori total d'un exercice wod | modele.piste |
| a_priori | `courbe_forme` | [0.3, 0.3] | [moy., sd] | λ : forme de la courbe (0 linéaire, 1 logarithmique) | modele, seance, planification |
| a_priori | `courbe_echelle` | [0.1, 0.0] | [moy., sd] | KU : échelle ln de la courbe de l'utilisateur ; figée | modele, seance, planification |
| a_priori | `biais_rir_proportionnel` | [0.25, 0.15] | [moy., sd] | BP : biais proportionnel de la note, appris | modele |
| a_priori | `k_nerveux_local` | [0.0047, 0.0019] | [moy., sd] | KL : sensibilité au compartiment rapide, part locale | modele |
| a_priori | `k_musculaire_systemique` | [0.00075, 0.0003] | [moy., sd] | KG : sensibilité au compartiment lent, part systémique | modele |
| a_priori | `part_tenue_exercice_sd` | 0.2 | ln | Écart-type de l'écart de HH propre à une tenue | modele.piste |
| a_priori | `marge_niveau` | [3.0, 2.0] | [pts, pts/niveau] | Marge = a + b·niveau − difficulté de l'exercice | modele.base_de |
| a_priori | `reps_bornes` | [2.0, 60.0] | rép. | Bornes de la capacité a priori d'un exercice reps | modele.base_de |
| a_priori | `tenue_bornes_s` | [5.0, 180.0] | s | Bornes de la capacité a priori d'une tenue | modele.base_de |
| a_priori | `fatigue_intra_exercice_sd` | 0.35 | ln | Écart-type de φ_e, écart de sensibilité à la fatigue de séance | modele.piste |
| mesure | `bruit_rir_par_niveau` | [2.0, 1.5, 1.0, 1.0] | rép. | Bruit de la note à la réserve de référence, par niveau 0 à 3 | modele.bruit_rir_de, seance.information |
| mesure | `bruit_rir_pente` | 0.25 | 1/rép. | Pente du bruit avec la réserve | modele.bruit_rir_de |
| mesure | `bruit_rir_plancher` | 0.5 | — | Terme constant du bruit (réserve nulle) | modele.bruit_rir_de |
| mesure | `bruit_rir_longue_serie_de` | 12 | rép. | Au-delà, le bruit croît avec la longueur de série | modele.bruit_rir_de |
| mesure | `bruit_rir_longue_serie_pente` | 0.08 | 1/rép. | Hausse relative du bruit par répétition au-delà du seuil | modele.bruit_rir_de |
| mesure | `bruit_serie` | 0.012 | ln | Non lue | — |
| mesure | `bruit_echec` | 0.01 | ln | Non lue | — |
| mesure | `bruit_test` | 0.008 | ln | Bruit d'une barre manquée (capacité < charge) | modele._serie_force |
| mesure | `bruit_charge_manuelle` | 0.03 | ln | Bruit d'une charge modifiée à la main | modele.observer_charge_manuelle |
| mesure | `bruit_raison_refus` | 0.12 | ln | Bruit d'un refus « trop lourd / trop léger » | modele.observer_raison |
| mesure | `bruit_tenue` | 0.08 | ln | Dispersion de ln T d'une tenue | modele._serie_tenue |
| mesure | `bruit_cardio` | 0.15 | ln | Bruit d'une séance cardio écourtée | modele._serie_endurance |
| mesure | `bruit_wod` | 0.1 | ln | Bruit d'un wod écourté | modele._serie_endurance |
| mesure | `bruit_continu` | 0.08 | ln | Non lue | — |
| mesure | `note_paresseuse_a_priori` | [1.0, 9.0] | Beta(a, b) | A priori de la part de notes égales à la note préremplie | modele |
| mesure | `apprentissage_bruit_oubli` | 0.97 | — | Facteur d'oubli de la moyenne de z² (multiplicateur de bruit) | modele._apprendre_bruit |
| mesure | `apprentissage_bruit_bornes` | [0.4, 2.5] | × | Bornes du multiplicateur de bruit appris | modele._apprendre_bruit |
| mesure | `rir_ouvert` | 4.0 | rép. | Réserve à partir de laquelle la note est une catégorie ouverte | modele |
| mesure | `cardio_pente_rir` | 4.0 | rép./unité | Pente réserve perçue ↔ demande relative (cardio) | modele._serie_endurance |
| mesure | `cardio_charge_neutre` | 0.8 | — | Demande relative qui laisse la réserve visée (cardio) | modele._serie_endurance |
| mesure | `cardio_poids_qualite` | 1.25 | × | Poids de la demande d'une course de qualité | Non lue par le moteur (banc/politique_koach) |
| mesure | `wod_pente_rir` | 4.0 | rép./unité | Pente réserve perçue ↔ demande relative (wod) | modele._serie_endurance |
| mesure | `bruit_rir_endurance` | 0.8 | rép. | Bruit de la note d'endurance | modele._serie_endurance |
| mesure | `bruit_rir_reference` | 5.0 | rép. | Réserve à laquelle vaut le bruit du cahier | modele.bruit_rir_de |
| mesure | `dispersion_fatigue_intra` | 0.3 | — | Bruit ajouté ∝ régresseur de fatigue de séance | modele |
| mesure | `note_aberrante` | 0.05 | proba | Probabilité qu'une note ne dise rien (répartie sur 10 flammes) | modele |
| mesure | `porte_note_ouverte` | 1.0 | écarts-types | Note ouverte (force) versée seulement si la prévision est à moins de ce nombre d'écarts-types au-dessus de la borne | modele._serie_force |
| mesure | `note_erreur_grossiere` | [0.08, 2.0] | [proba, rép.] | Queue lourde : probabilité et écart-type ajouté | modele._observer |
| mesure | `noteur_entier_notes_min` | 20 | notes | Notes vues avant de conclure « noteur entier » | modele.noteur_entier |
| mesure | `noteur_entier_part_max` | 0.05 | part | Part maximale de demi-notes d'un noteur entier | modele.noteur_entier |
| mesure | `defaut_modele_sd` | 0.015 | ln | Écart-type de défaut de modèle ajouté à celui de `capacite` (intervalle, calibrage, mesure utile, contrôle dual) | modele.capacite (`.get`, défaut 0) |
| jour | `sigma_seance` | 0.022 | ln | Écart-type de l'effet de jour de séance DS (sans bilan) | modele, planification |
| jour | `sigma_exercice` | 0.018 | ln | Écart-type de l'effet de jour d'exercice DE | modele, planification |
| jour | `bilan_par_point` | 0.012 | ln/point | Moyenne de DS par point de bilan général | modele.debut_seance |
| jour | `bilan_neutre` | 4 | point | Bilan général neutre | modele.debut_seance |
| jour | `sigma_seance_avec_bilan` | 0.018 | ln | Écart-type de DS quand le bilan général est donné | modele.debut_seance |
| jour | `mauvais_jour_proba` | 0.1 | proba | Poids a priori de la branche « mauvais jour » | modele.debut_seance |
| jour | `mauvais_jour_proba_bilan_bas` | 0.45 | proba | Idem si le bilan général ≤ 2 | modele.debut_seance |
| jour | `mauvais_jour_moyenne` | -0.06 | ln | Décalage de DS dans la branche « mauvais jour » | modele.debut_seance |
| jour | `mauvais_jour_sigma` | 0.045 | ln | Écart-type de DS dans la branche « mauvais jour » | modele.debut_seance |
| fatigue | `tau_nerveux_j` | 2.5 | j | Constante du compartiment rapide | modele |
| fatigue | `tau_musculaire_j` | 7.0 | j | Constante du compartiment lent | modele, planification |
| fatigue | `tau_tendineux_j` | 28.0 | j | Constante du compartiment tendineux | modele |
| fatigue | `grille_tau_nerveux` | [1.5, 2.5, 4.0] | j | Non lue | — |
| fatigue | `grille_tau_musculaire` | [4.0, 7.0, 10.0] | j | Non lue | — |
| fatigue | `grille_tau_tendineux` | [21.0, 28.0, 42.0] | j | Non lue | — |
| fatigue | `effort_demi_rir` | 2.0 | rép. | Effort d'une série = 1/(1 + réserve/ce nombre) | modele, planification |
| fatigue | `echec_supplement` | 0.5 | effort | Effort ajouté par un échec | modele.effort |
| fatigue | `intra_report` | 0.7 | — | Report géométrique de la fatigue d'une série à la suivante | modele._intra |
| fatigue | `intra_repos_s` | 180.0 | s | Constante de récupération entre séries | modele._intra |
| fatigue | `intra_rir` | 1.5 | rép. | Constante de l'effort intra-séance exp(−réserve/ce nombre) | modele.effort_intra |
| dynamique | `q_theta_semaine` | 2e-05 | ln² | Bruit de processus hebdomadaire de chaque θ_q | modele.fin_semaine |
| dynamique | `q_delta_semaine` | 0.0001 | ln² | Bruit de processus hebdomadaire de δ_e | modele, planification |
| dynamique | `q_delta_jour_inactif` | 2e-05 | ln²/j | Bruit de processus quotidien de δ_e (toutes les pistes, branche principale) | modele.avancer, dual |
| dynamique | `desentrainement_grace_j` | 14 | j | Inactivité au-delà de laquelle δ_e baisse | modele.fin_semaine |
| dynamique | `desentrainement_par_semaine` | 0.01 | ln/sem. | Baisse hebdomadaire de δ_e au-delà de la grâce | modele.fin_semaine |
| dynamique | `dose_reference` | 6.0 | unités de stimulus | Stimulus hebdomadaire de dose 1 | modele, dual, planification |
| dynamique | `hypotheses_s0` | [1.5, 2.5, 5.0] | unités | Constantes de saturation des hypothèses de dose | modele, dual |
| dynamique | `hypotheses_stimulus` | ["volume", "effort", "intensite"] | — | Stimulus de chaque hypothèse (volume, effort, intensité) | modele, dual |
| dynamique | `q_reponse_semaine` | 1e-08 | (ln/sem.)² | Bruit de processus de ρ | modele.fin_semaine |
| dynamique | `changement_cran_elastique_sd` | 0.25 | ln | Incertitude ajoutée par un changement de cran | modele.changer_cran |
| dynamique | `recuperation_seuil` | 8.0 | effort | Fatigue lente systémique au-delà de laquelle la réponse baisse | modele, planification |
| dynamique | `recuperation_pente` | 0.5 | — | Pente de la baisse | modele, planification |
| dynamique | `recuperation_plancher` | 0.2 | part | Plancher du facteur de récupération | modele, planification |
| dynamique | `accoutumance_semaines` | 40.0 | sem. | Accoutumance 1/(1 + semaines/ce nombre) | modele, planification |
| test_adaptatif | `intervalle_declenchement` | 0.06 | part | Demi-largeur relative (1,645 sd) au-delà de laquelle une mesure est utile | seance._mesure_utile |
| test_adaptatif | `poids_information` | 0.5 | — | Non lue | — |
| test_adaptatif | `ecart_rir_tolere` | 0.5 | rép. | Écart de réserve toléré pour une charge voisine plus informative | seance._cible_charge |
| test_adaptatif | `jours_min_entre_tests` | 14 | j | Délai minimal depuis la dernière mesure (test, repère, échec) | seance._mesure_utile |
| test_adaptatif | `reps_ouvertes` | 6 | rép. | Répétitions ouvertes d'une série repère chargée | seance._cible_charge |
| test_adaptatif | `repere_hausse` | 0.1 | part | Plafond de hausse d'une barre repère ou de la 1re barre de montée sur la barre récente | seance |
| test_adaptatif | `test_reps` | 3 | rép. | Répétitions du vrai test (intermédiaire) | seance._vrai_test |
| test_adaptatif | `test_reps_debutant` | 5 | rép. | Idem débutant | seance._vrai_test |
| test_adaptatif | `test_rir` | 1.0 | rép. | Réserve visée du vrai test (intermédiaire) | seance._vrai_test |
| test_adaptatif | `test_rir_debutant` | 2.0 | rép. | Idem débutant | seance._vrai_test |
| test_adaptatif | `test_reps_ouvertes` | 0 | rép. | Non lue | — |
| test_adaptatif | `rampe_pas` | 0.1 | part | Cran maximal pour qu'une montée soit possible ; hausse minimale d'une barre à l'autre | seance |
| test_adaptatif | `rampe_series_max` | 7 | séries | Séries de montée (+2 si 1 rép.) ; tentatives annoncées | seance.prescrire |
| test_adaptatif | `repos_test_s` | 180 | s | Repos minimal de l'item de test inséré | seance.prescrire |
| test_adaptatif | `rampe_pas_par_rir` | [[4.0, 0.075], [3.0, 0.05], [2.5, 0.035], [2.0, 0.025]] | [[rép., part]] | Pas de montée selon la réserve dite | seance._rampe |
| test_adaptatif | `test_reps_avance` | 1 | rép. | Répétitions du vrai test (avancé, élite) | seance._vrai_test |
| test_adaptatif | `test_rir_avance` | 1.0 | rép. | Réserve du vrai test (avancé, élite) | seance._vrai_test |
| test_adaptatif | `rampe_sd_min` | 0.05 | ln | Écart-type plancher de la borne haute de montée | seance._rampe |
| test_adaptatif | `rampe_confirmations` | 2 | séries | Notes basses successives qui arrêtent la montée | seance._rampe |
| test_adaptatif | `rampe_proba_min` | 0.75 | proba | P(réussite) minimale de la barre suivante | seance._rampe |
| test_adaptatif | `rampe_series_travail` | 1 | séries | Séries de travail retirées de la ligne quand une montée de vrai test est servie | seance.prescrire, seance._duree_permet_test |
| planification | `trajectoires` | 1000 | — | Trajectoires du jumeau numérique | planification |
| planification | `plans_max` | 256 | — | Budget de plans de la recherche (population = plans_max // iterations) | planification |
| planification | `iterations` | 4 | — | Itérations de l'entropie croisée | planification |
| planification | `elite` | 0.25 | part | Part élite | planification |
| planification | `lissage` | 0.7 | — | Lissage de la moyenne et de l'écart-type | planification |
| planification | `plafond_volume` | 0.15 | part | Plafond dur ±volume par qualité et par bloc | planification, seance, dual |
| planification | `plafond_intensite` | 0.05 | part | Plafond dur ±intensité par bloc | planification, seance, dual |
| planification | `lambda_transport` | 0.5 | — | λ de la pénalité de transport optimal | planification |
| planification | `risque_tendon_ratio_max` | 1.3 | × | Rapport charge tendineuse semaine / moyenne 4 semaines toléré | planification |
| planification | `risque_tendon_plancher` | 4.0 | effort | Charge de référence minimale pour appliquer le rapport | planification |
| planification | `horizon_sans_echeance_sem` | 12 | sem. | Horizon sans échéance ni cible | planification |
| planification | `sigma_prevision_semaine` | 0.004 | ln/sem. | Bruit de prévision ajouté par semaine | planification |
| planification | `gain_affutage` | 0.015 | part | Non lue | — |
| planification | `graine` | 20261009 | — | Graine des tirages de planification | planification |
| planification | `prudence_charge` | [0.6, 0.25] | écarts-types | Quantile prudent de la charge (≤ 3 séances, après) | seance._cible_charge |
| planification | `transport_creation` | 0.25 | /série | Coût de transport d'une série créée ou retirée | planification |
| planification | `marge_cible` | 0.0 | ln | Marge ajoutée au seuil de cible | planification |
| planification | `abandon_hebdo` | 0.01 | /sem. | Hasard d'abandon hebdomadaire (sans échéance) | planification |
| planification | `abandon_surcharge` | 3.0 | — | Poids de la surcharge dans le hasard d'abandon | planification |
| planification | `gain_min` | 0.002 | valeur | Gain minimal sur la référence pour retenir un plan | planification |
| planification | `rendement_test_sd` | 0.07 | ln | Dispersion du rendement d'un test le jour J dans la prévision de P(réussite) | planification |
| securite | `hausse_par_niveau` | [0.1, 0.05, 0.05, 0.05] | part | Hausse de charge maximale à schéma égal, par niveau | securite.hausse_max |
| securite | `hausse_fragile_facteur` | 0.5 | × | Facteur de la hausse sur zone fragile (conduite, `koachFragile` ou profil) | securite.hausse_max, seance._bornes_hausse |
| securite | `douleur_seuil` | 3 | /10 | Seuil de douleur (zone active au-dessus) | securite |
| securite | `douleur_jours_actifs` | 14 | j | Durée d'activité d'un signalement ; fenêtre de la douleur du bas du corps | securite |
| securite | `douleur_forte_contrainte` | 4 | /10 | Retrait si sollicitation 1 et douleur ≥ | securite.conduite |
| securite | `douleur_moyenne_contrainte` | 5 | /10 | Retrait si sollicitation ≥ 0,5 et douleur ≥ | securite.conduite |
| securite | `douleur_allegement` | 4 | /10 | Séries réduites si douleur ≥ | securite.conduite |
| securite | `douleur_allegement_series` | 0.6 | × | Facteur des séries | securite.conduite |
| securite | `douleur_rir_bonus` | 1.0 | rép. | Réserve ajoutée sur zone douloureuse | securite.conduite |
| securite | `douleur_remplacant_part` | 0.7 | part 1RM | Non lue (Koach retire au lieu de remplacer) | — |
| securite | `arret_persistance_min` | 3 | /10 | Signalement compté dans un épisode ; gêne du poignet qui compte | securite |
| securite | `arret_persistance_j` | 14 | j | Arrêt si l'épisode dure | securite |
| securite | `arret_forte_min` | 5 | /10 | Signalement fort | securite |
| securite | `arret_forte_j` | 7 | j | Arrêt si signalements forts étalés sur | securite |
| securite | `arret_retour_j` | 84 | j | Arrêt si retour d'un épisode réel dans ce délai | securite |
| securite | `arret_seances_de_suite` | 3 | séances | Arrêt après ce nombre de séances de suite > seuil | securite |
| securite | `arret_levee_j` | 14 | j | Levée après ce délai sans signalement ≥ 3 ; écart maximal dans un épisode | securite |
| securite | `arret_escalade_j` | 14 | j | Escalade si l'arrêt dure et la gêne persiste | securite.conduite |
| securite | `reprise_depart` | 0.5 | part | Part de départ de la reprise graduée (et séries pendant l'arrêt) | securite |
| securite | `reprise_pas` | 0.1 | part | Pas par semaine de charge | securite |
| securite | `reprise_plancher` | 0.4 | part | Plancher de la part | securite |
| securite | `reprise_rir` | 3.0 | rép. | Réserve minimale pendant l'arrêt et la reprise | securite |
| securite | `reprise_douleur_max` | 2 | /10 | Gêne qui fait reculer d'un palier ; zone récente | securite |
| securite | `reprise_surveillance_j` | 84 | j | Durée de surveillance après levée | securite, seance |
| securite | `reprise_charge_base` | 0.675 | part 1RM | Plafond de charge au premier palier | securite.conduite |
| securite | `reprise_charge_pente` | 0.25 | part 1RM | Hausse du plafond par part de reprise | securite.conduite |
| securite | `reprise_hausse_quantite` | 0.1 | part | Hausse maximale des répétitions/secondes sur zone récente | securite.conduite |
| securite | `bilan_palier1` | -0.02 | ln | Décalage du palier 1 | securite.palier_bilan |
| securite | `bilan_palier2` | -0.04 | ln | Décalage du palier 2 | securite.palier_bilan |
| securite | `bilan_rir_bonus` | 0.5 | rép. | Réserve ajoutée au palier 1 (×2 au palier 2) | seance |
| securite | `bilan_bas_rir_min` | 3.0 | rép. | Réserve minimale au palier 2 | seance |
| securite | `coupure_j` | 14 | j | Coupure qui réduit les séries et ouvre la semaine du retour | seance._coupure, _retour, _item |
| securite | `coupure_series` | 0.8 | × | Facteur des séries dans la semaine du retour (échauffement compris) | seance._item |
| securite | `tenue_hausse_par_niveau` | [0.2, 0.15, 0.1, 0.1] | part | Hausse maximale par tenue en bras tendus ; hausse hebdomadaire des secondes bras tendus par famille (retour gradué) | seance._cible_tenue, seance._limite_tenue |
| securite | `tenue_part_max` | 0.75 | part | Plafond d'une tenue en part du maximum du jour (valeur centrale) | seance._cible_tenue |
| securite | `simple_part_max` | 0.92 | part | Plafond d'un simple d'entraînement (part du max du jour) | seance._cible_charge |
| securite | `simple_part_max_bilan_bas` | 0.85 | part | Idem jour de bilan ≥ 1 | seance._cible_charge |
| securite | `tentative_ouverture_part` | 0.91 | part | Plafond de l'ouverture | seance._tentative |
| securite | `tentative_ouverture_proba` | 0.95 | proba | P(réussite) de l'ouverture | seance._tentative |
| securite | `tentative_deuxieme_proba` | 0.8 | proba | P(réussite) des tentatives intermédiaires | seance._tentative |
| securite | `tentative_troisieme_proba` | 0.5 | proba | P(réussite) de la dernière tentative | seance._tentative |
| securite | `tentative_saut_2` | 0.05 | part | Saut maximal (tentatives intermédiaires) | seance._tentative |
| securite | `tentative_saut_3` | 0.03 | part | Saut maximal (dernière) | seance._tentative |
| securite | `tentative_saut_kg` | 5.0 | kg | Saut maximal en charge externe | seance._tentative |
| securite | `tentative_bilan_bas_part` | 0.02 | part | Baisse du max par palier de bilan et sur douleur | seance._tentative |
| securite | `echec_baisse` | 0.075 | part | Baisse de charge gardée après un échec dans la séance | seance |
| securite | `echecs_arret` | 2 | échecs | Arrêt de l'exercice après ce nombre d'échecs | seance.cible |
| securite | `endurance_pic` | 0.1 | part | Hausse maximale du total de course sur la plus longue course récente | seance._endurance |
| securite | `endurance_pic_jours` | 30 | j | Fenêtre de la plus longue course récente | seance._endurance |
| securite | `endurance_pic_courses_min` | 3 | courses | Courses récentes nécessaires pour borner | seance._endurance |
| securite | `endurance_reprise` | [[7, 0.7], [14, 0.5]] | [[j, part]] | Part de l'écrit après une coupure de 7 et 14 jours (endurance) | seance._endurance |
| securite | `endurance_mauvais_jour` | 0.7 | × | Part de course et de cardio au palier 2 | seance._endurance |
| securite | `wod_jours_durs` | 2 | j | Jours durs de conditionnement de suite qui réduisent le conditionnement | seance._endurance |
| securite | `wod_echelle` | 0.75 | × | Part du conditionnement réduit | seance._endurance |
| securite | `plafond_hebdo_par_niveau` | [12, 20, 25, 30] | séries | Non lue (règle portée par le validateur injecté) | — |
| securite | `volume_hausse` | 0.2 | part | Hausse hebdomadaire des séries dures créditées par groupe (trois semaines précédentes) | seance._limite_volume |
| securite | `volume_hausse_series` | 2 | séries | Hausse toujours permise sur trois semaines | seance._limite_volume |
| securite | `volume_hausse_2sem` | 0.3 | part | Hausse sur deux semaines (semaine w−2) | seance._limite_volume |
| securite | `volume_hausse_2sem_series` | 4 | séries | Hausse toujours permise sur deux semaines | seance._limite_volume |
| securite | `volume_reprise_part` | 0.5 | part | Après trois semaines allégées, retour permis jusqu'à semaine allégée / cette part | seance._limite_rampe |
| securite | `volume_groupes_majeurs` | ["chest", "delt_anterior", "delt_middle", "delt_posterior", "lats", "upper_back", "biceps", "triceps", "abs", "lower_back", "glutes", "quads", "hamstrings", "calves"] | — | Groupes majeurs contrôlés, indices 0 à 13 de `groupes` des fiches | seance._credits, seance._retour_gradue |
| securite | `serie_dure_rir_max` | 4.0 | RIR | Une série compte comme dure à cette réserve ou moins (ou sans cible) | seance._series_dures |
| securite | `semaines_allegees` | ["intro", "deload", "test"] | — | Genres de semaine allégée par nature | seance.ouvrir |
| securite | `tenue_hausse_hebdo_s` | 5.0 | s | Hausse hebdomadaire toujours permise des secondes bras tendus | seance._limite_tenue |
| securite | `decharge_part` | 0.7 | part | Semaine d'allègement : séries dures ≤ cette part de la plus haute des trois semaines précédentes (écrit et servi) | seance._budgets_retour |
| securite | `decharge_max_semaines` | [12, 7, 6, 6] | sem. | Non lue (règle portée par le validateur injecté) | — |
| securite | `affutage_baisse` | [0.3, 0.3, 0.4, 0.4] | part | Non lue (règle portée par le validateur injecté) | — |
| securite | `seance_tolerance` | 1.15 | × | Durée admise d'une séance : budget × cette valeur + `seance_tolerance_min` | seance._duree_permet_test, seance._duree_bornee |
| securite | `seance_tolerance_min` | 3.0 | min | Minutes ajoutées à la durée admise | seance._duree_permet_test, seance._duree_bornee |
| securite | `couloir_haut_max` | 0.15 | part | Couloir au-dessus de la part écrite (< 85 %, hors débutant et verrou) | seance._cible_charge |
| securite | `couloir_part_lourde` | 0.85 | part | Part écrite au-dessus de laquelle la charge écrite plafonne | seance._cible_charge |
| securite | `schema_change_part` | 0.025 | part/rép. | Hausse permise par répétition de moins (schéma nouveau) | seance |
| securite | `schema_change_reps_max` | 4 | rép. | Répétitions comptées au plus | seance |
| securite | `barre_recente_j` | 42 | j | Fenêtre des barres réussies récentes | seance |
| securite | `premiere_hausse` | 0.1 | part | Hausse maximale sur la barre récente (schéma nouveau, ouverture) | seance |
| securite | `reprise_dose_depart` | 0.6 | × | Budget hebdo de séries par zone en reprise : part de l'habitude | seance._budget_reprise |
| securite | `reprise_dose_hausse` | 0.2 | part | Hausse du budget d'une semaine de charge à l'autre | seance._budget_reprise |
| securite | `tentative_recente_part` | 0.85 | part | Barre récente prise pour ouverture si ≥ cette part du max | seance._tentative |
| securite | `fragile_anciennetes` | ["under_6_weeks", "weeks_6_to_12", "months_3_to_12"] | — | Anciennetés d'un antécédent qui rendent une zone du profil fragile | securite._zones_fragiles |
| securite | `fragile_gene_min` | 2 | /10 | Gêne déclarée qui rend une zone du profil fragile | securite._zones_fragiles |
| securite | `fragile_niveau_min` | 0.5 | niveau | Sollicitation minimale d'une zone fragile par l'exercice | securite.fragile |
| securite | `surcharge_fragile_max` | 1.0 | part 1RM | Part écrite maximale sur zone fragile du profil | seance._cible_charge |
| securite | `poignet_gene_j` | 14 | j | Fenêtre de la gêne du poignet (appui neutre conseillé) | securite.poignet_gene |
| securite | `poignet_chaud_j` | 7 | j | Fenêtre du poignet « chaud » (arrêt et gêne récente) | securite.poignet_chaud |
| securite | `poignet_sensible_min` | 1 | /10 | Gêne qui rend le poignet sensible | securite.poignet_sensible |
| securite | `poignet_sensible_j` | 14 | j | Fenêtre du poignet sensible | securite.poignet_sensible |
| securite | `poignet_appui_neutre_materiel` | ["parallettes", "poignées"] | — | Matériel tenu pour un appui neutre du poignet | securite.appui_neutre |
| securite | `technique_niveau_acces` | {"top_set_backoff": 1, "drop_set": 1, "amrap": 1, "pyramid": 1, "ladder": 1, "density": 1, "for_time": 1, "cluster": 2, "rest_pause": 2, "myo_reps": 2, "accentuated_eccentric": 2, "contrast": 2, "wave": 2} | niveau | Niveau minimal du profil par technique | seance._technique |
| securite | `techniques_intensives` | ["rest_pause", "myo_reps", "drop_set", "accentuated_eccentric", "amrap", "cluster", "wave", "contrast"] | — | Techniques qui intensifient | seance._technique |
| securite | `excentrique_echeance_j` | 10 | j | Pas d'excentrique accentué à ce nombre de jours ou moins d'une échéance | seance._technique |
| securite | `tenue_hausse_marge_s` | 1 | s | Hausse toujours permise d'une tenue et du temps total de l'emplacement | seance._cible_tenue |
| securite | `coupure_fenetre_j` | 7 | j | Durée de la semaine du retour après une coupure | seance._coupure |
| securite | `renvoi_periode_j` | 7 | j | Période du renvoi vers un professionnel pendant un arrêt | securite.renvois |
| securite | `surmenage_baisse` | 0.05 | part | Baisse de forme qui compte pour l'alerte de surmenage | seance._formes |
| securite | `surmenage_jours` | 7 | j | Durée de la coupe après une alerte | seance._surmenage |
| securite | `surmenage_fenetre_j` | 21 | j | Fenêtre des trois séances comparées | seance._formes |
| securite | `surmenage_coupe` | 0.4 | part | Part des lignes retirées après une alerte | seance._surmenage |
| securite | `endurance_materiel_course` | ["piste ou terrain extérieur", "tapis de course", "côte ou escaliers"] | — | Matériel qui fait d'un cardio une course | seance._nature |
| securite | `endurance_qualite_ids` | ["fractionne", "seuil", "tempo", "30-30", "sprint", "cotes", "fartlek", "intervalles", "navettes", "accelerations"] | — | Fragments d'identifiant d'une course de qualité | seance._qualite |
| securite | `endurance_qualite_rir` | 3.0 | rép. | Réserve au plus d'une course de qualité | seance._qualite |
| securite | `endurance_facile_rir` | 5.0 | rép. | Réserve d'une course facile (effort maximal affiché) | seance._endurance |
| securite | `endurance_vitesse` | 2.6 | m/s | Vitesse de course par défaut | seance._vitesse |
| securite | `endurance_douleur_jambe` | 3 | /10 | Douleur du bas du corps qui fait un jour sans | seance._endurance |
| securite | `endurance_dure_flammes` | 8 | flammes | Note à partir de laquelle une course ou un conditionnement est dur | seance._course_trop_dure, _fermer_endurance |
| securite | `endurance_dure_marge` | 2 | flammes | Écart à la cible d'une course trop dure | seance._course_trop_dure |
| securite | `endurance_dure_jours` | 3 | j | Fenêtre de la course trop dure | seance._course_trop_dure |
| securite | `endurance_course_facile` | {"tapis": "ca-course-tapis-endurance", "defaut": "ca-footing-endurance-fondamentale"} | — | Course facile de remplacement (tapis, défaut) | seance._endurance |
| securite | `endurance_facile_min_s` | 60 | s | Travail minimal pour proposer une course facile | seance._endurance |
| securite | `endurance_bornee_reduction` | 0.9 | × | Réduction d'une ligne longue pour borner la course | seance._endurance |
| securite | `wod_fenetre_j` | 7 | j | Fenêtre des jours durs de conditionnement | seance._serie_wod |
| securite | `retour_seances_avant_mesure` | 2 | séances | Séances de l'exercice depuis le retour de coupure avant toute mesure | seance._mesure_utile |
| securite | `surmenage_seances_min` | 6 | séances | Séances mesurées du mouvement avant que l'alerte de surmenage soit suivie | seance._formes |
| adherence | `a_priori_poids_sd` | 1.5 | — | Écart-type a priori des 16 poids probit | adherence |
| adherence | `biais_initial` | 1.0 | — | Moyenne a priori du poids de biais | adherence |
| adherence | `pas_min` | 0.5 | unité de la cible | Pas minimal entre paliers (défaut si non donné) | adherence.forme |
| adherence | `proba_cible` | 0.7 | proba | P(acceptation) visée par palier | adherence.forme |
| adherence | `refus_silence_j` | 0 | j | Non lue (présente dans `DEFAUTS_ADHERENCE`) | — |
| adherence | `paliers_max` | 4 | — | Paliers maximaux vers une cible | adherence.forme |
| adherence | `ampleur_echelle` | 4.0 | pas | Ampleur divisée par ce nombre | adherence |
| adherence | `ampleur_borne` | 3.0 | — | Borne de la caractéristique d'ampleur | adherence |
| adherence | `refus_recents_j` | 14 | j | Fenêtre des refus récents | adherence |
| adherence | `refus_recents_echelle` | 5.0 | refus | Refus récents pour une caractéristique 1 | adherence |
| rupture | `hasard` | 0.02 | /séance | Hasard H de la BOCPD | rupture |
| rupture | `alerte` | 0.6 | proba | Seuil d'alerte de P(rupture) | rupture |
| rupture | `fenetre` | 3 | séances | Non lue (présente dans `DEFAUTS_RUPTURE` ; remplacée par `fenetre_seances`) | — |
| rupture | `a_priori_moyenne_sd` | 2.0 | σ | κ0 = 1/sd² de l'a priori normal-gamma | rupture |
| rupture | `residu_secours` | 0.05 | ln | Seuil de secours du résidu d'e1RM moyen absolu | rupture |
| rupture | `residu_secours_semaines` | 2 | sem. | Semaines consécutives au-dessus du seuil | rupture |
| rupture | `assiduite_secours` | 0.7 | part | Seuil d'assiduité | rupture |
| rupture | `assiduite_secours_semaines` | 2 | sem. | Semaines cumulées | rupture |
| rupture | `douleur_secours` | 2 | /10 | Douleur au-dessus de laquelle l'alerte se lève | rupture |
| rupture | `elargissement_rien_de_special` | 4.0 | × | Facteur sur les variances des capacités et qualités | rupture |
| rupture | `semaine_allegee_series` | 0.6 | × | Séries de la semaine allégée | rupture |
| rupture | `semaine_allegee_rir` | 2.0 | rép. | Réserve ajoutée en semaine allégée | rupture |
| rupture | `a_priori_alpha` | 2.0 | — | α0 de la course initiale | rupture |
| rupture | `a_priori_beta` | 1.0 | — | β0 de la course initiale | rupture |
| rupture | `a_priori_alpha_nouvelle` | 5.0 | — | α des courses nouvelles (a priori empirique) | rupture |
| rupture | `course_max` | 200 | séances | Troncature de la longueur de course | rupture |
| rupture | `min_observations` | 6 | séances | Pas d'alerte BOCPD avant | rupture |
| rupture | `fenetre_seances` | 10 | séances | Fenêtre de P(rupture) | rupture |
| rupture | `silence_semaines` | 2 | sem. | Silence d'une cause après réponse | rupture |
| rupture | `journal_dossier` | 60 | événements | Événements du journal dans le dossier | rupture.dossier |
| rupture | `douleur_recente_j` | 7 | j | Âge maximal d'un signalement pour l'alerte douleur | rupture |
| rupture | `residu_reps_reference` | 8.0 | rép. | R de conversion réserve → e1RM (g'(R)) | rupture._residu_e1rm (chemin pris seulement si le résumé de séance a moins de 6 éléments : jamais avec le modèle) |
| controle_dual | `semaines_min` | 8 | sem. | Semaines de journal pour être calibré | dual.calibre |
| controle_dual | `intervalle_max` | 0.06 | part | Demi-largeur maximale des lifts principaux | dual.calibre |
| controle_dual | `bras_semaines` | 3 | sem. | Durée d'un bras N-of-1 | dual |
| controle_dual | `synthetique_semaines_min` | 6 | sem. | Semaines avant intervention | dual |
| controle_dual | `synthetique_iterations` | 200 | — | Itérations FISTA | dual |
| controle_dual | `amplitude_volume` | 0.1 | part | Bras A : +volume | dual |
| controle_dual | `amplitude_intensite` | 0.03 | part | Bras B : +intensité | dual |
| controle_dual | `sigma_progres` | 0.01 | ln/sem. | Bruit de secours du progrès hebdomadaire | dual |
| controle_dual | `plancher_poids` | 1e-06 | — | Plancher des poids d'hypothèses | dual |
| controle_dual | `a_priori_effet_sd` | 0.005 | ln/sem. | A priori de l'effet B − A | dual |
| controle_dual | `marge_echeance_semaines` | 6 | sem. | Marge minimale avant échéance | dual |
| controle_dual | `seuil_decision` | 0.8 | proba | Seuil de décision P(B > A) | dual |
| controle_dual | `n_bras` | 4 | — | Nombre de bras (pair) | dual |
| controle_dual | `sigma_innovation` | 0.003 | ln | Plancher de l'écart-type de l'innovation | dual |
| controle_dual | `semaines_gardees` | 26 | sem. | Semaines a posteriori gardées | dual |

### 7.5 Clés non lues

**Clés du JSON lues par aucun module de `koach/`** (18, vérifiées par script sur le code du 10/10/2026) :

- racine : `qualites` (lue par le banc), `classes_reponse` ; toutes deux seulement contrôlées en type à l'import ;
- `mesure.bruit_serie`, `mesure.bruit_echec`, `mesure.bruit_continu` ;
- `mesure.cardio_poids_qualite` (lue par le banc seulement, `banc/politique_koach.py`) ;
- `fatigue.grille_tau_nerveux`, `fatigue.grille_tau_musculaire`, `fatigue.grille_tau_tendineux` ;
- `test_adaptatif.poids_information`, `test_adaptatif.test_reps_ouvertes` ;
- `planification.gain_affutage` ;
- `securite.douleur_remplacant_part` ;
- `securite.plafond_hebdo_par_niveau`, `securite.decharge_max_semaines`, `securite.affutage_baisse` : règles de volume de 0.3.1 portées par le validateur injecté (`banc/securite_banc.py`, en constantes du banc) ;
- `adherence.refus_silence_j` (présente dans `DEFAUTS_ADHERENCE`, jamais lue) ;
- `rupture.fenetre` (présente dans `DEFAUTS_RUPTURE`, jamais lue).

Les clés `securite.volume_hausse`, `volume_hausse_series`, `volume_hausse_2sem`, `volume_hausse_2sem_series`, `decharge_part`, `seance_tolerance` et `seance_tolerance_min` sont lues depuis le 10/10/2026 (retour gradué au volume et durée bornée, § 8.3).

Les clés d'endurance de la section `securite` (`endurance_pic`, `endurance_pic_jours`, `endurance_pic_courses_min`, `endurance_reprise`, `endurance_mauvais_jour`, `wod_jours_durs`, `wod_echelle`) sont lues depuis le 10/10/2026 (`seance._endurance`).

**Clés lues par `.get` avec un défaut, absentes du JSON** : aucune. `dual._innovations` lit `dynamique.q_delta_jour_inactif` avec le défaut 0 ; la clé existe.

---

## 8. Garde-fous (contraintes dures)

`securite.py` ne propose rien : il borne. Les numéros A… renvoient à l'inventaire `km1-outils/notes/SECURITE_0_3_1.md` (règles de `kalis_adapt` 0.3.1) ; les numéros B… aux critères du banc. Les références `A/fichier.dart` du relevé de couverture (`km1-outils/notes/SECURITE_KOACH_COUVERTURE.md`) renvoient au code Dart de 0.3.1 (`moteurs/packages/kalis_adapt/lib/src/`).

### 8.1 Couverture règle par règle

Statuts : **déjà** (reprise avant le 10/10/2026) ; **ajoutée** (reprise le 10/10/2026, clés de la section `securite`) ; **partielle** ; **non reprise** (applicable mais absente, raison donnée) ; **sans objet** (mode 0.1 remplacé, revue hebdomadaire absente, règle de hausse et non de borne, ou donnée que l'interface de Koach ne reçoit pas).

| Règle 0.3.1 | Statut | Dans Koach (fichier, fonction) | Raison, écart |
| --- | --- | --- | --- |
| A1.1 seuil 3/10, zone active 14 j, zone bloquante | déjà | `securite.active`, `conduite` | — |
| A1.2 pas de hausse, +1 RIR, lignes gelées | déjà | `conduite`, `seance._cible_*` | Plus prudent : plafond = dernier passage de l'exercice. |
| A1.3 retrait (forte ≥ 4, moyenne ≥ 5) | déjà | `conduite` | — |
| A1.4 allègement ≥ 4/10 (× 0,6, +1 RIR) | déjà | `conduite` | — |
| A1.5 remplaçant sous douleur | non reprise | — | Koach retire au lieu de remplacer (aucune charge sur la zone : plus prudent). Un remplaçant demande le matériel et le lieu du jour et la similarité de plan, que `plan()` ne reçoit pas. `douleur_remplacant_part` reste non lue. |
| A1.6 test retiré (zone du jour, > 2/10 dans la semaine) | déjà | `conduite`, `signalee_semaine` | — |
| A1.7 proposition « épargner la zone » | sans objet | — | Proposition de la revue hebdomadaire de 0.3.1 ; Koach n'a pas de revue de ce type. La conduite retire ou allège à chaque séance. |
| A2.1 déclenchement de l'arrêt (a)–(d) | déjà | `securite._arrets` | — |
| A2.2 pendant l'arrêt : retrait, premier palier, escalade | déjà | `conduite` | — |
| A2.2 renvoi vers un professionnel (1re séance, puis chaque semaine d'arrêt) | **ajoutée** | `securite.renvois`, `seance.ouvrir` → `koach.douleur_persistante` | Plus prudent : un arrêt déclenché en fin de séance reçoit son renvoi à la séance suivante. |
| A2.2 remplacement d'une poussée du poignet par parallettes ou poignées | non reprise | — | Même raison que A1.5 (matériel du jour inconnu) : la poussée est retirée (plus prudent). |
| A2.3 course retirée pendant un arrêt du bas du corps ; retour à ≤ 50 % | **ajoutée** | `seance._endurance` (étapes 0 et 1), `securite.arrets_jambe`, `reprise_jambe` | — |
| A3.1–A3.3 reprise graduée, arrêt gardé, paliers, recul, 67,5 % + 2,5 %/palier, tests retirés | déjà | `securite.reprise`, `arret`, `conduite` | — |
| A3.3 dose plafonnée dans la séance (reps, secondes, charge jamais au-dessus de la série précédente) | **ajoutée** | `conduite` (`dose_plafonnee`), `seance._cible_charge`, `_cible_reps`, `_cible_tenue`, `_mesure_utile` | Avant : seule la charge était bloquée dans la séance. |
| A4.1 première gêne du poignet → appui neutre | **partielle** | `securite._poignet` → `koach.poignet_appui_neutre` | Pas de remplacement (matériel du jour inconnu) : la ligne est gardée à la dose écrite (repli de 0.3.1 sans appui neutre) **et sans hausse** (plus prudent) ; l'appui neutre est conseillé par la raison. La pompe sur barre basse n'est jamais tenue pour neutre. |
| A4.2 arrêt du poignet : charge externe d'appui retirée (arrêt gardé compris), poignet « chaud » | **ajoutée** | `securite._poignet`, `poignet_chaud` ; causes `poignet_charge`, `poignet_chaud` de `koach.douleur_retrait` | Remplaçant parallettes ou poignées : non (voir A2.2). |
| A4.3 poignet sensible : dose plafonnée | **ajoutée** | `securite.poignet_sensible`, `_poignet` → `koach.poignet_dose` | Plus prudent : reprise comptée sur toute la fenêtre de surveillance (84 j). |
| A5.1 lecture du bilan, paliers | déjà | `securite.palier_bilan` | — |
| A5.2 effets des paliers | déjà | `seance._item`, `_cible_charge`, `_tentative` | Capacité prévue non baissée du décalage du bilan (le bilan agit par l'a priori de l'effet de jour) : voir § 8.5. Palier 2 sans technique d'intensification : ajouté (A9.2). Jour sans d'endurance : ajouté (A10.2). |
| A6.1 reprise après coupure ≥ 14 j : séries × 0,8 | déjà, **complétée** | `seance._coupure`, `_item` | La règle vaut toute la semaine du retour (`coupure_fenetre_j`) et s'applique à l'échauffement. Avant, Koach ne l'appliquait qu'à la première séance (moins prudent). |
| A6.2 alerte de surmenage (−40 % des lignes, 7 j) | **ajoutée** | `seance._formes`, `_forme`, `_surmenage` → `koach.surmenage` | Grandeur suivie : ln capacité à frais + effet de jour de la séance (mélange des deux branches). Toute séance avec une série faite compte comme mesurée (plus fréquent qu'en 0.3.1). |
| A6.3 décharge anticipée (revue) | sans objet | — | Proposition de la revue hebdomadaire ; la planification de Koach est bornée (§ 8.4) et validée par le validateur injecté (critères B11, B12). |
| A6.4 récupération déclarée réduite | non reprise | — | Donnée non reçue : le profil de Koach ne porte ni sommeil habituel, ni stress, ni métier. La règle porte sur les hausses de volume de la revue ; voir § 8.5. |
| A6.5 semaine verrouillée | déjà | `verrou` | — |
| A6.5 test chargé en semaine verrouillée ≤ charge écrite | **ajoutée** | `seance._cible_test` (test xRM) | Ajouté aussi : après un échec non prévu à la dernière séance, pas plus lourd que le dernier passage. |
| A6.5 échéance ≤ 14 j | partielle | `_mesure_utile` (`jours_avant_echeance`) | Le banc ne fournit que `jour_evenement`, pas `jours_avant_echeance` : la règle est inactive sur le banc. Couloir, double progression, série au ressenti : Koach n'a pas ces hausses (sans objet). |
| A7.1 bornes du mode 0.1 | sans objet | — | Mode 0.1 remplacé par le mode coach. |
| A7.2 bornes 10/5/5/5 %, un cran, couloir, simple 92 % ; schéma changé (règle 4) | déjà, **complétée** | `_bornes_hausse`, `_marquer`, `_cible_charge` | Accessoires sans doublement et règle 4 (schéma changé au même emplacement) ajoutés : bornés comme en 0.3.1. |
| A7.2 zone fragile du profil (antécédent < 12 mois ou gêne ≥ 2) : hausse × 0,5, 0 répétition comptée, paliers 5 % | **ajoutée** | `securite._zones_fragiles`, `fragile`, `conduite` (`fragile`) ; `seance._bornes_hausse` → `koach.zone_fragile` | Schéma nouveau sur zone fragile : +5 % (moitié de 10 %), aucune part pour les répétitions de moins, un cran au moins. |
| A7.2 surcharge sur zone fragile ≤ `coachOverloadFragileMax` | **ajoutée** | `seance._cible_charge` | Appliqué aussi à une part écrite sur le 1RM de l'exercice lui-même (plus prudent). |
| A7.2 double progression « 2 pour 2 », bonification | sans objet | — | Règles de hausse, pas de borne. |
| A7.2 exercice nouveau écrit en % d'un autre mouvement (60 %, paliers 10/5 %) | non reprise | — | Koach ne lit pas la part comme une part du 1RM d'un autre mouvement : il calibre (charge choisie par l'utilisateur si σ > 0,12) puis suit son propre modèle au quantile prudent. |
| A7.3 sans charge (couloir, garde de réserve directe) | non reprise | `_cible_reps` (règles propres) | Modèle propre (prévision au quantile e^(−σ/2), verrous échec, douleur, bilan, zone récente +10 %). Voir § 8.5. |
| A7.4 conseil : −15 %/+5 %, −7,5 % gardé, arrêt après 2 échecs | déjà | `cible`, `_cible_charge` | Arrêt à une réserve donnée, propreté, chute de répétitions : non lus (voir § 8.5). |
| A8.1 conditions d'un test | déjà | `_item`, `conduite` | Report à 48 h : sans objet (re-service, pas une borne). Test de course plus long que la borne : ajouté (A10.3). |
| A8.2 échelle des tentatives | déjà | `_tentative` | Bonification d'affûtage : sans objet (hausse). |
| A8.3 séries repères | déjà | `_mesure_utile`, `_repere` | Ajouté : jamais sur une ligne à dose plafonnée. |
| A9.1 tendons, hausse par tenue | déjà | `_cible_tenue` | — |
| A9.1 temps total de l'emplacement | **ajoutée** | `seance._cible_tenue`, `Memoire.sec_slot` → `koach.tendon` cause `total` | Sans le plancher de 55 % du meilleur maintien (plus prudent). |
| A9.2 techniques réservées au niveau ; techniques qui intensifient | **ajoutée** | `seance._technique`, `equivalent_standard` → `koach.technique_retenue` | Excentrique accentué à ≤ 10 j d'une échéance : seulement si `jours_avant_echeance` est fourni. |
| A9.3 élastique | sans objet | — | Koach ne décide pas des crans (événement `cran` fourni par l'appelant). |
| A9.4 séries fractionnées | sans objet | — | Koach n'ajoute jamais de séries (plus prudent). |
| A9.5 étapes de figures | non reprise | — | Pas de module de progression d'étapes : Koach sert l'étape écrite ; une douleur active sur l'étape relève de la conduite générale (retrait ou sans hausse). |
| A10.1 reprise après coupure (70 % / 50 %) | **ajoutée** | `seance._endurance` (étape 1), `_fermer_endurance` | — |
| A10.2 jour sans : qualité → course facile, palier 2 × 0,7 | **ajoutée** | `seance._endurance` (étape 2), `_qualite`, `_course_trop_dure` → `koach.course_facile`, `koach.endurance_retrait`, `koach.endurance_raccourcie` | Course facile seulement si son matériel figure dans celui de la séance écrite et si le lieu du jour le permet (Koach ne connaît pas le matériel du jour) ; sinon la séance de qualité est retirée (repli de 0.3.1). |
| A10.3 sortie bornée (+10 % sur la plus longue des 30 j), test plus long → course bornée | **ajoutée** | `seance._endurance` (étape 3) → `koach.course_bornee` | Effort borné à `flammes_de_rir(5) + 1` = 2 flammes (code 0.3.1 ; l'inventaire dit 6 : erreur de l'inventaire). |
| A10.4 conditionnement × 0,75 après jours durs ou jour sans | **ajoutée** | `seance._endurance` (étape 4), `_serie_wod` → `koach.wod_echelle` | — |
| A10.5 fatigue croisée (course dure la veille → −1 flamme bas du corps) | **ajoutée** | `seance._endurance` (étape 5) → `koach.fatigue_croisee` | — |
| A11 propositions de volume de la revue | sans objet | — | Revue hebdomadaire absente ; plafonds de la planification et validateur injecté (B2, B3). |
| A12 débutant | déjà, **complétée** | `_cible_charge` (charge écrite), `_repere` (2 RIR), `_technique` | Techniques de niveau ≥ 1 retirées : ajouté (A9.2). |
| A13 génération `kalis_plan` (mode prudent, impact, IMC, première semaine, feu vert médical) | sans objet | — | Règles d'écriture du bloc ; elles restent dans le plan de référence, que Koach ne restructure pas. |

**Règles moins prudentes dans Koach que dans 0.3.1** : aucune connue au 10/10/2026. Les deux écarts relevés à la première passe sont corrigés : hausse des accessoires (bornée par `hausse_par_niveau`, sans doublement) et schéma changé au même emplacement (règle 4, `_marquer` et `_bornes_hausse`).

### 8.2 Détail des règles reprises

| Règle 0.3.1 | Dans Koach | Où |
| --- | --- | --- |
| A1.1 zone active, zone bloquante | `active(z)` = dernière intensité si > `douleur_seuil` et ≤ `douleur_jours_actifs` jours ; bloquante si une intensité > seuil a été signalée entre `depuis_jour` (dernière séance de l'exercice) et aujourd'hui (niveau ≥ 0,5) : sans hausse, +`douleur_rir_bonus` | `securite.active`, `conduite` |
| A1.2 pas de hausse, +1 RIR | `sans_hausse`, `rir` ; plafond « dernier passage » (`charge_derniere`) ; reps et tenues plafonnées par le maximum de la dernière séance | `conduite`, `seance` |
| A1.3 retrait | niveau 1 et ≥ `douleur_forte_contrainte`, ou niveau ≥ 0,5 et ≥ `douleur_moyenne_contrainte` : `retire`, cause `douleur` | `conduite` |
| A1.4 allègement | ≥ `douleur_allegement` : séries × `douleur_allegement_series` | `conduite` |
| A1.6 test retiré | zone active du jour, ou > `reprise_douleur_max` dans les 7 jours | `conduite`, `signalee_semaine` |
| A2.1 arrêt | (a) épisode de ≥ `arret_persistance_j` jours, (b) ≥ 2 signalements ≥ `arret_forte_min` étalés sur ≥ `arret_forte_j` jours, (c) retour ≤ `arret_retour_j` jours après un épisode réel (≥ 2 signalements ou un ≥ 4, constante du code), (d) ≥ `arret_seances_de_suite` séances de suite > seuil ; épisodes = signalements ≥ `arret_persistance_min` séparés de ≤ `arret_levee_j` ; levée quand le dernier signalement ≥ 3 date de ≥ `arret_levee_j` jours (`arret_leve = dernier + arret_levee_j`) | `securite._arrets` |
| A2.2 pendant l'arrêt | mouvements qui provoquent retirés ; ceux qui chargent la zone au premier palier (séries × `reprise_depart`, ≥ `reprise_rir`, sans hausse, ≤ `reprise_charge_base` lu comme niveau d'effort, pas de test, dose plafonnée) ; escalade après `arret_escalade_j` jours si gêne ≥ 3 dans les 7 j | `conduite` |
| A2.2 renvoi | première séance de l'arrêt, puis première séance de chaque période de `renvoi_periode_j` jours ; jour du dernier renvoi retenu par zone | `securite.renvois` |
| A3.1, A3.2 reprise, arrêt gardé | `arret(z)` vrai tant qu'aucune semaine de charge n'a commencé depuis la levée (une semaine compte si la levée lui laisse ≥ 4 jours, constante du code) | `arret`, `_semaines_de_charge` |
| A3.3 paliers | part = `reprise_depart` + `reprise_pas` par semaine de charge, plancher `reprise_plancher`, recul d'un pas si > `reprise_douleur_max` dans les 7 j ; charge ≤ `reprise_charge_base` + `reprise_charge_pente`·(part − 0,5) ; ≥ `reprise_rir` ; hausse de quantité ≤ `reprise_hausse_quantite` ou +1 sur zone récente ; tests retirés ; dose plafonnée | `reprise`, `conduite`, `recente` |
| A4.1 | gêne du poignet ≥ `arret_persistance_min` dans les `poignet_gene_j` jours, avant tout arrêt, sur une poussée `reps` à contrainte de poignet `moyenne` sans appui neutre (`poignet_appui_neutre_materiel`), hors test et échauffement : `appui_neutre`, sans hausse, dose plafonnée | `securite._poignet` |
| A4.2 | arrêt du poignet (en cours ou gardé) et niveau ≥ 0,5 : poignet chaud (arrêt en cours et gêne ≥ `arret_persistance_min` dans les `poignet_chaud_j` jours) → retrait sauf appui neutre à contrainte < 1 ; sinon retrait de toute ligne `charge` hors échauffement | `securite._poignet` |
| A4.3 | poignet sensible (zone fragile du profil, arrêt, reprise sur toute la surveillance, ou gêne ≥ `poignet_sensible_min` dans les `poignet_sensible_j` jours) : dose plafonnée sur toute ligne qui provoque le poignet | `securite.poignet_sensible`, `_poignet` |
| A5.1 lecture du bilan | constantes 0,015 par point sous 4, 6 h, 0,01 par heure (≤ 3 h), 0,01 par réponse ≤ 2, part 0,5, plancher −0,08 **écrites dans le code** ; seuils `bilan_palier1/2` ; overall ≤ 1 → palier 2, ≤ 2 → palier 1 | `securite.palier_bilan` |
| A5.2 paliers | palier 1 : +`bilan_rir_bonus`, pas de hausse, tests retirés ; palier 2 : +2 × bonus, une série de moins (plancher 3 ou 2), ≥ `bilan_bas_rir_min`, simple ≤ `simple_part_max_bilan_bas`, pas de technique intensive, jour sans d'endurance ; tentatives −`tentative_bilan_bas_part` par palier | `_item`, `_cible_charge`, `_tentative`, `_technique`, `_endurance` |
| A6.1 coupure | séries × `coupure_series` pendant la semaine du retour, échauffement compris ; sans hausse ; ni mesure ni test | `_coupure`, `_item`, `_mesure_utile` |
| A6.5 semaines verrouillées | `verrou` : part écrite = plafond, pas de test adaptatif, pas de repère, pas d'écart de planification, test xRM ≤ charge écrite | `seance`, `planification` |
| A7.2 bornes | `hausse_par_niveau` (× `hausse_fragile_facteur` si fragile), un cran toujours permis, couloir +`couloir_haut_max` sous `couloir_part_lourde`, schéma nouveau +`premiere_hausse` sur la barre de `barre_recente_j` jours (+`schema_change_part`/rép., `schema_change_reps_max` au plus), schéma changé au même emplacement, simple ≤ `simple_part_max` | `_bornes_hausse`, `_cible_charge` |
| A7.4 conseil | −15 %/+5 % d'une série à l'autre (constantes du code), −`echec_baisse` gardé après un échec, arrêt après `echecs_arret` échecs | `_cible_charge`, `cible` |
| A8.2 tentatives | ouverture ≤ `tentative_ouverture_part`·max et P ≥ `tentative_ouverture_proba`, barre récente ≥ `tentative_recente_part` ; 2e P ≥ `tentative_deuxieme_proba`, 3e ≥ `tentative_troisieme_proba` ; sauts `tentative_saut_2`, `tentative_saut_3`, `tentative_saut_kg` ; jamais décroissantes ; −2 % par palier et sur douleur | `_tentative` |
| A8.3 séries repères | `jours_min_entre_tests`, 1,5 RIR (2 débutant), +`reps_ouvertes`, jamais en verrou, bilan bas, douleur, échec, dose plafonnée, coupure | `_mesure_utile`, `_repere` |
| A9.1 tendons | hausse par tenue `tenue_hausse_par_niveau` ou +`tenue_hausse_marge_s` ; tenues ≤ `tenue_part_max`·e^μ ; temps total de l'emplacement borné de même | `_cible_tenue` |
| A9.3 changement de cran | capacité × facteur fourni par l'appelant, +`changement_cran_elastique_sd` | `modele.changer_cran` |

### 8.3 Règles propres à Koach, plus prudentes

- **Budget hebdomadaire de reprise par zone** (`_budget_reprise`), pour une zone levée depuis ≤ `reprise_surveillance_j` jours et qui n'est plus à l'arrêt :
  - habitude = moyenne des doses des semaines de charge parmi les 4 semaines qui précèdent le premier signalement ≥ 3 ;
  - première semaine de charge depuis la levée : `max(1, floor(reprise_dose_depart·habitude + 1e-9))` ;
  - ensuite : `max(précédente + 1 ; floor(précédente·(1 + reprise_dose_hausse) + 1e-9))` ;
  - moins les séries déjà faites cette semaine.
  Le budget s'applique à tous les mouvements qui provoquent la zone, quel que soit le volume écrit.
- **Retour gradué au volume** (`_budgets_retour`, `_retour_gradue`, `_fermer_volume` ; critères `volume_trop_vite` et `tendon_figures` du banc, B2 et B6, portés comme contraintes dures). Koach tient, pour chaque semaine, les séries dures créditées par groupe majeur (`volume_groupes_majeurs` ; série dure = renforcement hors échauffement, à `serie_dure_rir_max` en réserve au plus ou sans cible ; crédit = part du groupe dans `groupes` de la fiche, 1 ou 0,5), les secondes de tenue bras tendus par famille (`bras_tendus` de la fiche : séries × secondes hautes) et le genre de la semaine (allégée si `genre` ∈ `semaines_allegees`). Le volume compté est celui des séances fermées (`_fermer_volume`, § 6.6) et des séances manquées à leur volume écrit (`contexte['manquees']`), comme la vue « servi, tests faits » du banc. À chaque séance de la semaine w ≥ 1 (sauf la première semaine du journal), pour chaque groupe g :
  - `rampe(r, h, t)` = `max(r·(1 + h), r + t)` ; sur les semaines w−3..w−1, `charge` = plus haut volume d'une semaine de charge, `allégée` = plus haut d'une semaine allégée ; s'il y a une semaine de charge, `L₁ = rampe(max(charge, allégée), volume_hausse, volume_hausse_series)`, sinon `L₁ = max(rampe(allégée, …), allégée / volume_reprise_part)` (une semaine inconnue compte comme semaine de charge à 0) ;
  - si w ≥ 2, que w, w−1 et w−2 sont de charge et que le volume de w−2 est positif : `L₂ = rampe(volume(w−2), volume_hausse_2sem, volume_hausse_2sem_series)` ; `L = min(L₁, L₂)`, sinon `L = L₁` ;
  - budget du jour = `L` − volume déjà compté dans la semaine − volume écrit des séances restantes de la semaine (`contexte['reste_semaine']`, réservé en entier : une séance restante manquée compterait à son écrit).
  Pour une famille bras tendus : même calcul avec `tenue_hausse_par_niveau[niveau]` et `tenue_hausse_hebdo_s`, seulement si une tenue de la famille figure dans les trois semaines précédentes. Item par item, dans l'ordre de la séance, après toutes les autres règles de séries et avant le vrai test : séries = `min(séries, floor((budget_g − déjà servi aujourd'hui_g)/crédit_g + 1e-9))` sur ses groupes ; pour une tenue bras tendus, mêmes séries avec des tenues raccourcies à `floor(reste / séries)` secondes (5 s au moins), sinon une série de moins, et ainsi de suite. Raison `koach.retour_gradue` ; zéro série : item retiré. Une montée de test compte dans les séries de sa ligne (§ 6.4).
  **Allègement** (critère `decharge_absente`, B11) : une semaine allégée par nature, ou dont l'écrit (séries dures des items écrits des séances vues, manquées comprises, plus `reste_semaine`) est ≤ `decharge_part` × le plus haut écrit des trois semaines précédentes, doit rester un allègement au vu du servi : séries dures de la semaine, tous groupes confondus, ≤ `decharge_part` × la plus haute des trois semaines servies précédentes (même budget, même réserve ; raison `koach.retour_gradue`, groupe `allegement`). Sans cette borne, un allègement écrit qui suit des semaines servies réduites (douleur) n'en est plus un pour le banc.
  Mesure (banc complet, 720 saisons, avec planificateur) : constats « retour à l'écrit » de la vue « servi, tests faits » `volume_trop_vite` 934 → 49, `tendon_figures` 73 → 13 ; tous les restants (62 ; 30 sans planificateur) sont dus au seul volume écrit de séances manquées (diagnostic `dont_dus_aux_manquees` de la campagne : ils disparaissent quand les séances manquées sont vidées) : séance manquée dont l'écrit dépasse à lui seul ce que la limite laisse (historique servi réduit par un arrêt de douleur), semaine entièrement manquée, ou séance manquée après la dernière séance de la saison. Réserve : sans réserve des séances restantes (séances servies dans l'ordre jusqu'à la limite), 34 constats (24 + 10, plus 3 `decharge_absente`) au lieu de 8 sur 72 saisons (sans planificateur, avant la borne d'allègement) ; avec une réserve limitée à la plus grosse séance restante, 21 + 12 sur 720 (sans planificateur) contre 18 + 12 avec la réserve entière, pour un gain hebdomadaire égal à 2 % près.
- **Durée bornée** (`_duree_bornee` ; critère `seance_trop_longue`, B10). Durée estimée comme le banc (`_duree_item` : 45 s de transition, 3 s par répétition et deux côtés hors bilatéral, secondes écrites (deux côtés en renforcement), distance à la vitesse de course du journal, 6 s par calorie, repos écrit ou 60 s ; 5 min de plus dès qu'un exercice de renforcement). Si l'écrit tient dans `budget·seance_tolerance + seance_tolerance_min` ou est un jour d'épreuve (contre-la-montre servi comme test noté `event_day`), la séance servie ne dépasse pas cette durée (moins 1e-6 d'arrondi), sauf si le test d'épreuve est servi tel quel ; sinon elle ne dépasse pas l'écrit. Réduction, tant que la séance est trop longue : la plus longue ligne d'endurance (course, cardio, conditionnement) perd une série, ou une course ou un cardio d'une série est ramené à une durée (secondes) qui tient, ou la ligne est retirée ; sans ligne d'endurance, la dernière ligne de renforcement hors test perd une série, puis est retirée. Jamais une montée de test. Raison `koach.seance_bornee`. Cas mesuré : jour du semi-marathon (`autres_06_semi_marathon_intermediaire`, semaine 12, budget 45 min) ; la course bornée (A10.3) convertit le contre-la-montre de 21,1 km en course de travail de 14,4 km, qui n'est plus exemptée : 77 min estimées pour 54,75 admises ; elle devient une course de 54 min.
- **Jamais plus lourd que le dernier passage** de l'exercice (et non que la dernière séance de l'emplacement) sur zone douloureuse ou en reprise, un jour de bilan bas, ou pendant la semaine du retour d'une coupure.
- **Pas de vrai test ni de série repère après une coupure** : ni pendant la semaine du retour, ni avant `retour_seances_avant_mesure` séances de l'exercice depuis le retour ; aucune rampe sans barre réussie depuis `barre_recente_j` jours (constat de relecture B2).
- **Ouverture des tentatives** bornée par les barres réussies des `barre_recente_j` derniers jours (+`premiere_hausse`, +`schema_change_part` par répétition au-delà de la première, `schema_change_reps_max` au plus).
- **Montée du vrai test** : 1re barre ≤ +`repere_hausse` sur la barre récente ; barre suivante seulement si P(réussite) ≥ `rampe_proba_min` ; borne haute à μ + 2,5σ.
- **Série repère chargée** ≤ +`repere_hausse` sur la barre récente.
- **Plafond des tenues** sur la valeur centrale `tenue_part_max·e^μ`, jamais sur un quantile haut.
- **Bras d'essai N-of-1 sous les garde-fous** (appliqués par l'appelant, § 3.7.4) : bras B par `Seances.borne_externe` (aucune hausse un jour sans hausse, verrouillé, à `part_max`, dose plafonnée, zone douloureuse ou fragile, après un échec ; sinon bornes de hausse et +5 % entre séries) ; bras A borné par `dual.facteur_borne` par rapport aux séries de la référence.
- **Semaine verrouillée** : la borne « jamais plus lourd que le dernier passage » a été essayée puis **retirée** (coût mesuré sur le banc : écart d'effort et fausses alertes de rupture en hausse). Koach borne comme 0.3.1, par la charge écrite.

### 8.4 Plafonds de la planification

- **Volume par qualité.** Facteur ∈ [1 − 0,15 ; 1 + 0,15] par bloc. Il est vérifié sur les séries entières de chaque semaine par rapport à la référence (`items_modules`) ; l'arrondi par diffusion d'erreur est corrigé jusqu'à respecter le plafond.
- **Intensité.** Écart ∈ [−0,05 ; 0,05] par bloc, appliqué à la charge totale du modèle (`koachIntensite`), et de nouveau borné dans la séance.
- **Semaines verrouillées.** Volume ≤ 1 et intensité ≤ 0.
- **Tendons.** Pénalité 1 par semaine où le rapport charge tendineuse / moyenne des 4 semaines dépasse `max(1,3 ; rapport de la référence)`, si la référence est ≥ 4.
- **Validateur injecté, obligatoire.** `validateur(blocs) → [constats {code, week, dayIndex, exerciseId}]`. `Planification(validateur=None)` lève une erreur, sauf `options['sans_validateur']` (parité numérique). Un plan qui ajoute un constat est divisé par 2, au plus 3 fois, puis abandonné. Sur le banc, le validateur est `securite_banc.constats_saison`, portage des critères B1 à B14 de `kalis_bench` vérifié contre le Dart. Les règles de volume de 0.3.1 (plafond de la 1re semaine et plafond hebdomadaire par niveau, hausses de volume sur une et deux semaines, décharge, affûtage, durée de séance) ne vivent que dans ce validateur, en constantes du banc : les clés correspondantes de la section `securite` ne sont pas lues (§ 7.5). **Dans l'application, KM2 devra fournir un validateur équivalent.**
- **Import.** Les plafonds `planification.plafond_volume`, `plafond_intensite` et les amplitudes du contrôle dual sont figés (`rupture.FIGEES`, § 7.3) ; la section `securite` ne peut pas changer.
- **Contrôle dual.** `facteur_borne` garde le produit plan × essai dans les plafonds ; il est appelé par l'appelant (banc), pas par le moteur.

### 8.5 Doutes ouverts sur l'équivalence

- A5.2 : 0.3.1 baisse la capacité prévue du décalage du bilan ; Koach ne l'applique pas (`Seances.decalage` non lu) et compte sur l'a priori de l'effet de jour (`modele.debut_seance`). Non prouvé équivalent.
- A6.4 : la planification de Koach peut monter le volume d'une qualité de 15 % sans connaître la récupération déclarée.
- A7.3, A7.4 : règles sans charge et conseil d'entre-séries de 0.3.1 (garde de réserve directe, arrêt à une réserve, propreté, chute de répétitions) remplacés par le modèle de Koach ; pas d'équivalence prouvée.
- A6.2 : la grandeur suivie (capacité à frais + effet de séance) n'est pas exactement celle de 0.3.1.
- `rejeu/journal_app.py` transmet les zones fragiles comme de simples codes : elles sont toutes tenues pour fragiles (plus prudent que 0.3.1). Le banc (`banc/politique_koach.py`) transmet ancienneté et gêne.

---

## 9. Déterminisme et parité

### 9.1 Générateur et graines

**mulberry32** (`numerique.Mulberry32`), sur des entiers de 32 bits non signés :

```
state = (state + 0x6D2B79F5) mod 2³²
t = state
t = ((t ^ (t >> 15)) · (t | 1)) mod 2³²
t ^= (t + (((t ^ (t >> 7)) · (t | 61)) mod 2³²)) mod 2³²
retour ((t ^ (t >> 14)) mod 2³²) / 4294967296
```

En Dart, toutes les multiplications doivent être faites modulo 2³² (par exemple en 64 bits suivis de `& 0xFFFFFFFF`).

`gauss()` = `norm_ppf(max(u, 1e-12))` : un seul uniforme par tirage.

**fnv1a32** sur les octets UTF-8 : base `0x811C9DC5`, puis pour chaque octet `h ^= octet` et `h = (h·0x01000193) mod 2³²`.

**Chaînes de graines** (exactes) :

| Chaîne | Où |
| --- | --- |
| `'koach-plan:%d:%d' % (planification.graine, semaine)` | jumeau numérique (`Planification.tirer`) |
| `'koach-cem:%d:%d' % (planification.graine, semaine)` | entropie croisée (`replanifier`) |
| `'koach-dual-essai:%d:%d' % (graine, semaine)` | séquence ABBA/BAAB (`ControleDual.proposer_essai`, graine de l'événement `essai`) |
| `'koach-dual:%d:%d' % (graine, semaine)` | tirage de Thompson (`hypothese_pour_la_semaine`, appelé par `tirer` avec `planification.graine`) |
| `'koach-adherence-poids:' + clé` et `'koach-adherence-decisions:' + clé` | banc seulement, utilisateur simulé (clé = `saison:scenario:graine`) |

Ordre des tirages de `tirer` : les `n·k` gaussiennes de `z`, puis `n` uniformes d'hypothèse (consommés même quand le tirage de Thompson fixe l'hypothèse), puis les paires `bruit_jour`, `bruit_proc` (§ 3.7.1).

### 9.2 Ordres qui comptent

- **Pistes** : ordre de création (`ordre`). Il fixe les indices d'état, l'ordre des mises à jour en fin de semaine et l'ordre de `posterior`. Une piste est créée au premier appel qui la demande (série, `plan`, `posterior`, planification, `calibre`) ; comme les appels de `plan` sont journalisés, l'ordre se rejoue.
- **Fonctionnelles** : qualités dans l'ordre 0 à 9 (seulement `v_q ≠ 0`), puis δ_e, puis DS, DE, KN, KL, KG, KM ; ensuite λ, KU, κ_e, φ_e, BA, BP.
- **Sommes**, toutes dans l'ordre des indices : `_stats` (colonnes de P dans l'ordre de `idx`), `_intra`, quadrature de `category_moments` (i croissant), moyennes de résidus, `cholesky_semi` (q croissant), boucles de l'adhérence et du contrôle dual.
- **Dictionnaires** : l'ordre d'insertion compte (`niveaux` de la conduite, tels que reçus dans la forme canonique ; `zones` de `garde` ; `memoire` ; groupes `(exerciseId, slotId)` de `fermer`, dans l'ordre des séries). Dart `LinkedHashMap` garde le même ordre si les insertions sont identiques.
- **Ensembles** : les zones provoquées sont parcourues triées (budget de reprise, forme canonique) ; les zones fragiles du profil sont un tuple trié ; `renvois` parcourt les zones triées. Les autres ensembles Python (`testes`, `vus`, jours durs et actifs de `_serie_wod`) ne servent qu'à des tests d'appartenance : leur ordre d'itération n'entre dans aucun résultat.
- **Tris** :
  - CEM : clé `(−valeur, indice)` ;
  - constats : tri de tuples `(code, week, dayIndex, exerciseId)` ;
  - extensions : clés triées (`sorted`) ;
  - projection sur le simplexe : tri par insertion stable ;
  - médiane de `equivalent_standard` : `sorted` sur des entiers.
- **Extensions** : ordre de la liste ; sur le banc, `surveillance`, `dual`, `adherence`. La dernière réponse non `None` de `hypothese_pour_la_semaine` l'emporte.

### 9.3 Fonctions à porter ligne pour ligne

- **`erfc`.** Si `|x| < 2` : série de 80 termes, `term ← term·2z²/(2n + 1)`, puis `erf = 2/√π·e^(−z²)·Σ` et `erfc = 1 − erf`. Sinon : fraction continue de Laplace sur 200 étages, évaluée à rebours, `f = (k/2)/(z + f)`, puis `e^(−z²)/√π/(z + f)`. Symétrie : `2 − erfc(|x|)` pour `x < 0`.
- **`norm_cdf(a)`** = `½·erfc(−a/√2)` ; **`norm_sf(a)`** = `½·erfc(a/√2)`.
- **`norm_ppf`** : Acklam (coefficients du code, seuil 0,02425), puis un pas de Halley avec `norm_cdf`.
- **`interval_moments`**, **`point_moments`** : § 5.12.
- **`category_moments`** : § 5.6 (fenêtre `[a − 8T ; b + 8T]`, pas choisi sur la vraisemblance, 104 à 1 200 intervalles). **`_category_mass`** : la référence Python appelle `math.erfc` ; le portage Dart appelle `erfc` du module. L'écart est au plus 2e-13 sur la masse : les fixtures de parité en tiennent compte (tolérance 1e-9 sur les sorties).
- **`cholesky_semi(S, tol = 1e-12)`** : `seuil = tol·max_j S[j][j]` ; pour j croissant : `d = S[j][j] − Σ_{q<j} L[j][q]²` ; si `d ≤ seuil`, colonne j laissée à 0 ; sinon `L[j][j] = √d` et, pour i > j, `L[i][j] = (S[i][j] − Σ_{q<j} L[i][q]·L[j][q])/L[j][j]`. Remplace la décomposition propre de numpy (non portable).
- **`arrondi(x, n = 0)`** = `floor(x·10ⁿ + 0,5)/10ⁿ` en flottants. Remplace `round` de Python (arrondi au pair, décimal exact) dans `elite_n`, `blocs_modules` et l'historique de planification. `seance.arrondi(x)` = `int(floor(x + 0,5))` sert aux parts en pourcent des raisons d'endurance.
- **Arrondis de séries** : `math.floor(x + 0,5)` et `math.floor(x + 1e-9)` ; `math.ceil` dans `category_moments` et `flammes_de_rir`.
- **`lgamma`** (Lanczos), **`projection_simplexe`**, **`borne_lambda_max`**, **FISTA** : boucles fixes.
- **`dart_round`** existe dans `numerique` mais n'est pas utilisé.

### 9.4 numpy et bibliothèque : ce que le Dart doit reproduire, et les risques pour 1e-9

| Point | Code | Risque | Proposition |
| --- | --- | --- | --- |
| Racine de la covariance du jumeau | `Planification.tirer` → `numerique.cholesky_semi` | Faible : boucles explicites, ordre fixé. | Porter tel quel. |
| Produits matriciels BLAS | `H @ P @ H.T`, `z @ L.T`, `a @ V.T`, `charge_jour @ decro`, `a @ tq`, `h @ m` (`tirer`, `evaluer`) | Moyen : ordre d'accumulation et FMA propres à BLAS. Écarts de l'ordre de 1e-16 relatif, amplifiés par les seuils (`jour ≥ seuil`, tri CEM). J est un multiple de 1/N : un renversement de décision demande une égalité à 1e-16 près, improbable mais possible. | Boucles explicites dans un ordre fixé, des deux côtés, pour les fixtures. |
| `np.einsum('cdq,cq->cd')` | `evaluer` | Moyen : ordre interne. | Idem. |
| Réductions `.sum()`, `.mean()` sur le dernier axe (≥ 8 éléments) | `evaluer` (transport par qualité, `syst[2].sum()`, `mr.sum()`, `prog.mean(axis=(1,2))`, `ok.mean`) | Faible à moyen : numpy fait une sommation par paires. Les moyennes de booléens sont exactes. | Reproduire la sommation par paires ou passer à des boucles des deux côtés. |
| `elite.mean(axis=0)`, `elite.std(axis=0)` | `replanifier` | Faible : réduction sur l'axe 0, séquentielle. `std` = racine de la moyenne des carrés des écarts (ddof 0). | Porter tel quel. |
| Seuils et comparaisons | `jour ≥ seuil`, `cw/moy_c > limite + 1e-9`, tri `(−v, a)`, `vx ≤ v_ref + gain_min` | Tout écart en amont peut faire basculer une comparaison : le plan retenu change et l'écart dépasse alors 1e-9. | Fixtures de parité sur `evaluer` (valeurs) **avant** la parité sur le choix. |
| Mises à jour de rang 1 | `np.outer`, `P -= …`, `_covariance_partielle`, fusion des branches, croissance ligne puis colonne | Faible : opérations élément par élément. | Porter tel quel (ligne puis colonne pour la croissance). |
| `math.erfc` de la bibliothèque C | `numerique._category_mass` | Faible : écart ≤ 2e-13 avec `numerique.erfc`, que le Dart utilise. | Tolérance des fixtures ; ou faire appeler `erfc` par la référence au moment de régénérer les fixtures. |
| `round` de Python | `seance._surmenage` (paramètre `part` de la raison `koach.surmenage`, `round(·, 3)`) | Sans effet sur l'état ; le paramètre de la raison peut différer d'un ulp décimal. | Remplacer par `numerique.arrondi` ou exclure ce paramètre de la parité. |
| `exp`, `log`, `sqrt`, `sin`, `pow` | partout | Faible : `sqrt` est correctement arrondi ; `exp`, `log`, `pow` dépendent de la libm. `intra_report ** k` est un `pow` à exposant entier : en Dart, utiliser `math.pow`. | Fixtures exécutées sur la même plateforme (CI Linux). |
| Format des traces | `'%.1f' % x` dans `trace` | Sans effet : hors contrat. | — |

### 9.5 Rejeu depuis le journal : conditions

`rejouer(params, fiches, profil, journal, extensions)` redonne le même état si :

1. `params` (fichier initial), `fiches` et `profil` sont les mêmes qu'à la construction ;
2. les extensions sont les mêmes, dans le même ordre ;
3. pour la planification, `charger_reference` et la replanification initiale sont refaites par l'appelant avant le rejeu, avec les mêmes arguments (hors journal : constat de relecture M7, non corrigé).

Les appels de `plan` (événement `plan`, contraintes canoniques), les imports de paramètres (événement `parametres`), les décisions, les douleurs et les séries sont dans le journal. Les modulations appliquées par l'appelant (allègement, planification, bras d'essai, forme d'adhérence) sont contenues dans les items de l'événement `plan`.

**Vérification.** `tests/test_rejeu_exact.py` simule deux saisons du banc (référence et douleur au coude), fait un aller-retour JSON du journal, le rejoue et compare bit à bit : ordre des pistes, `m` et `P` actifs, `posterior()` (JSON trié), `explain()` et longueur du journal. Ce test rejoue le moteur sans extensions ; le banc vérifie le rejeu des extensions à part (`banc/extensions_koach.rejouer_etats`).

**Journal de l'application** (méthode). `rejeu/journal_app.py` convertit la sauvegarde de l'application en événements de ce schéma (profil de départ, déclarations initiales, séances, séries, douleurs). `rejeu/walk_forward.py` rejoue tout le journal dans l'ordre ; pour chaque séance évaluée (à partir d'une semaine donnée du programme), la prévision est notée sur une copie du modèle avant de verser les séries. Mesures : (A) e1RM du jour prévu contre e1RM réalisé de la série notée la plus informative (première série de travail ou de test à 3 en réserve ou moins), avec son intervalle à 90 % ; (B) tests réels (1RM, maximum d'endurance) contre la capacité du jour prévue ; (C) calibration des notes ouvertes. La sortie ne contient que des agrégats (aucune valeur individuelle, aucune date, aucun identifiant de séance). Ce contrat ne donne aucun résultat de ce rejeu.

### 9.6 Fixtures

Le répertoire `reference/fixtures/` contient 8 fichiers produits par `fixtures/generer.py` (`numerique.json`, `moteur_1.json` à `moteur_5.json`, `planification_1.json`, `planification_2.json`). Ils sont **périmés** au 10/10/2026 : ils datent d'avant les changements de ce contrat (événements `plan`, validateur obligatoire, quadrature, Joseph, Cholesky), et `tests/test_fixtures.py` est désélectionné. `generer.py` doit être adapté (journal avec événements `plan`, `options['sans_validateur']` ou validateur du banc), puis les fixtures régénérées avant KM2.

| Domaine | Contenu attendu |
| --- | --- |
| Fonctions numériques | grilles d'entrées et sorties de `erfc`, `norm_ppf`, `interval_moments`, `category_moments` (dont fenêtre et pas adaptés), `point_moments`, `cholesky_semi`, `arrondi`, `lgamma`, mulberry32 (10⁴ tirages), fnv1a32 (chaînes du § 9.1) |
| Journal complet | un journal par profil type, avec `posterior()` après chaque événement et la sortie de chaque `plan` |
| Planification | `evaluer` sur une matrice X fixée ; tirage du jumeau |
| Extensions | états de la BOCPD, de l'adhérence et du contrôle dual après rejeu |

---

## 10. Limites connues et hors périmètre de 1.0

1. **Structure.** La structure du plan n'est jamais modifiée : exercices, jours, schémas, ordre. Le cahier (Méthodes § 5) prévoit des changements de structure aux frontières de bloc ; rien n'est écrit pour cela.
2. **Planification.** Elle ne module que le volume, par qualité et par bloc, et l'intensité, par bloc, à l'intérieur des plafonds. Il n'y a ni récapitulatif de fin de bloc, ni replanification sur « moins de temps » (seule l'action codée existe), ni arrêt d'urgence dans le moteur.
3. **Objectif sous contrainte de risque.** Le risque n'est représenté que par la pénalité tendineuse et le validateur ; aucune probabilité de blessure n'est estimée.
4. **Contrôle dual.** Le tirage de Thompson est branché dans la planification, mais il ne s'active que si le modèle est calibré, ce qui arrive rarement (annexe A, M5). Les bras N-of-1 et la modulation sont appliqués par l'appelant (M6).
5. **Mobilité.** Pas de modèle 2PL ; les exercices `mobilite` et `autre` (distance, calories, portés) ne sont pas suivis par le modèle. Les lignes d'endurance non modélisées suivent les seules règles de sécurité du § 6.7.
6. **Wod.** Pas de modèle continu log-normal : effort perçu et demande relative seulement (cahier, Méthodes § 2).
7. **Compartiment tendineux.** Calculé mais sans effet sur les décisions de séance.
8. **Fatigue nerveuse systémique et musculaire locale.** Figées à 0 (régression du banc) : seules les parts locale rapide et systémique lente agissent.
9. **Garde-fous non repris** (§ 8.1) : remplaçants (A1.5, A2.2), récupération déclarée (A6.4), exercice nouveau en part d'un autre mouvement (A7.2), règles sans charge de 0.3.1 (A7.3), étapes de figures (A9.5). Les règles de volume de 0.3.1 ne vivent que dans le validateur injecté.
10. **Paramètres.** Ils ne sont pas réestimés par utilisateur dans un fichier : seul l'état du filtre l'est.
11. **Rejeu.** Voir § 9.5 (référence de planification hors journal).
12. **Hors périmètre, reporté par le cahier** : VBT, a priori collectif.

---

## Annexe A. Écarts au cahier, limites connues, points ouverts

Refaite le 10/10/2026. Les constats de la relecture indépendante du code (`km1-outils/notes/RELECTURE_OPUS_CODE.md`, numéros B, M, m) sont cités par leur numéro. Les constats corrigés depuis (B1 à B4, M1 à M4, m1 en partie, m2 par choix, m3, m4, m5 en partie, m7, m9, m11, m13) n'apparaissent plus, sauf leur reste.

### A.1 Écarts au cahier

Chaque écart est à acter par le propriétaire (décision C13) ou à corriger.

| # | Cahier | Code |
| --- | --- | --- |
| 1 | Méthodes § 3 : « Toutes les séries servent, pondérées par leur fiabilité » | Une série **sans note** n'est versée que si la prévision la contredit (moins de répétitions possibles que faites) ; la forme de courbe et l'échelle propre de l'exercice sont alors « considérées », non déplacées (filtre de Schmidt, `modele._observer(fige=…)`, `_covariance_partielle`). Une tenue sans note suit la même règle. Une note ouverte de force (« 4 en réserve ou plus ») n'est versée que si la prévision est à moins de `porte_note_ouverte` = 1,0 écart-type au-dessus de la borne. Raison : cliquet vers le haut constaté au rejeu d'un journal réel et dérive de l'e1RM chez un athlète qui stagne (constats B1 et m15). |
| 2 | Méthodes § 3 : « Biais et bruit appris par utilisateur » ; « Biais initial 0 » | Le biais proportionnel BP est appris, avec un a priori de population **non nul** (0,25 ± 0,15). Le biais additif BA est **figé à 0** (sd 0) : sur le banc, il n'est pas identifiable séparément de BP. Le bruit est appris par un multiplicateur (`_apprendre_bruit`). |
| 3 | Méthodes § 3 : bruit 2,0 / 1,5 / 1,0 | Interprété comme le bruit **à 5 RIR** (`bruit_rir_reference`) ; il vaut environ 29 % de cette valeur à l'échec et croît au-delà de 12 répétitions possibles. |
| 4 | Méthodes § 2 : WOD continu log-normal, mobilité 2PL | Absents (§ 10). |
| 5 | Méthodes § 4 : trois compartiments, le tendineux alimenté par la charge tendineuse | Le compartiment tendineux est calculé mais n'agit sur rien ; la part systémique du rapide et la part locale du lent sont figées à 0. |
| 6 | Méthodes, en-tête : « Chaque valeur … réestimé pour chaque utilisateur et stocké dans le fichier de paramètres » | Non fait : seul l'état du filtre est réestimé (§ 10). |
| 7 | Méthodes § 5 : structure modifiable aux frontières de bloc | Jamais modifiée. |
| 8 | Méthodes § 5 : « 256 plans évalués au plus » | `replanifier` évalue `pop × iterations` = 256 plans, plus 1 (échelle, sans échéance), 1 (référence), 1 par essai (jusqu'à 9), 1 par essai validé et 1 (détail final), sans compter les appels au validateur. Le compte écrit dans l'historique (`evalues + 2 + len(essais)`) ne suit pas ce total. |
| 9 | Méthodes § 5 : test adaptatif, « charge choisie pour maximiser l'information » | Choix entre la charge et ses deux crans voisins seulement (`_cible_charge`, étape 10). |
| 10 | Méthodes § 5 et § 7 : « intervalle à 90 % de l'e1RM » dépasse ou passe sous 6 % | Lu comme une **demi-largeur** relative (1,645·σ) ; σ comprend `defaut_modele_sd` (0,015), soit un plancher de demi-largeur de 2,5 %. |
| 11 | Méthodes § 6 : « λ calibré sur le banc » | `lambda_transport` = 0,5, aucun calage documenté. |
| 12 | Méthodes § 7 : « Toujours à l'intérieur des plafonds de l'optimisation bornée » | Garanti par l'appelant (banc : `dual.facteur_borne`, `Seances.borne_externe`), pas par `plan()` (M6). |
| 13 | Méthodes § 8 : l'adhérence agit sur la forme des propositions | `Adherence.forme` existe mais n'est appliquée que par l'appelant (M6). |
| 14 | Méthodes § 9 : secours « résidu d'e1RM supérieur à 5 % deux semaines de suite » | La grandeur moyennée est le déplacement de la capacité du jour pendant la séance, pas un résidu (M8). |
| 15 | Méthodes § 9 : « Moins de temps → replanification » ; « Fatigue → semaine allégée » | Action codée seulement pour « moins de temps ». La semaine allégée (`appliquer_allegement`) est appliquée par l'appelant (M6). |
| 16 | Contraintes : « L'état se recalcule depuis le journal et les décisions de l'utilisateur » | Vrai pour le moteur et les extensions (appels de `plan` et imports journalisés, rejeu exact testé), sauf la référence de planification (M7). |
| 17 | Contraintes : règles de 0.3.1 en contraintes dures | Reprises sauf A1.5, A2.2 (remplaçant du poignet), A6.4, A7.2 (exercice nouveau en part d'un autre mouvement), A7.3, A9.5 (§ 8.1). Les règles de volume (dont le plafond de la 1re semaine) ne vivent que dans le validateur injecté, obligatoire, en constantes du banc. Le feu vert médical reste dans le plan de référence. |
| 18 | Contraintes : parité Python / Dart à 1e-9 | Écarts connus : `math.erfc` dans `_category_mass` (≤ 2e-13), produits BLAS et réductions numpy de la planification, `round` de Python dans la raison `koach.surmenage` (§ 9.4). Fixtures périmées (§ 9.6). |
| 19 | Contraintes : calcul (replanification ≤ 10 s, série ≤ 50 ms) | Mesuré sur la référence Python seulement ; à mesurer sur la VM Dart (KM2). |

### A.2 Limites connues : constats de relecture non corrigés

Ces constats sont reportés tels quels ; ils ne sont pas corrigés dans le code au 10/10/2026.

| N° | Constat | Conséquence |
| --- | --- | --- |
| M5 | **La demi-largeur de l'intervalle à 90 % ne passe presque jamais sous 6 %, et elle grandit** (`modele.capacite`, `dual.calibre`, `seance._mesure_utile`). Relecture : avec un 1RM déclaré et 2 séances par semaine de 4 séries notées, demi-largeur 6,3 % à la semaine 1 puis 8,5 % à la semaine 20 (niveau 1) ; chaque séance ne retire qu'environ 0,001 d'écart-type de ln capacité ; `q_delta_jour_inactif` est ajouté à toutes les pistes chaque jour. Depuis, `defaut_modele_sd` (0,015) ajoute un plancher de 2,5 %. | Le contrôle dual (cahier § 7) ne se déclenche pratiquement jamais : le tirage de Thompson et les essais N-of-1 restent inactifs. Le vrai test (§ 5) reste éligible presque en permanence : il revient tous les `jours_min_entre_tests` = 14 jours sur chaque mouvement principal et secondaire chargé (simple à RIR 1 pour un avancé), sauf contre-indication (coupure, douleur, verrou, bilan bas…). |
| M6 | **Des actions du cahier ne passent pas par la façade** : `plan({'horizon': 'seance'})` sert les items reçus. La semaine allégée (`Surveillance.appliquer_allegement`, cahier § 9), la modulation hebdomadaire (`Planification.appliquer`), le bras N-of-1 (`ControleDual.modulation`, `facteur_borne`, `Seances.borne_externe`) et la forme d'adhérence (`Adherence.forme`, § 8) doivent être appliqués par l'appelant. Seul le banc le fait (`banc/extensions_koach.py`, `banc/politique_koach.py`). | Un intégrateur KM3 qui appelle `plan()` comme le décrit ce contrat, sans ces crochets, ne servira jamais la semaine allégée, la modulation de la planification, les bras d'essai ni la forme d'adhérence. Les garde-fous de ces modulations reposent aussi sur l'appelant. |
| M7 | **L'état de la planification ne se recalcule pas depuis le journal** : `charger_reference` (blocs, cibles, échéance, poids) et la replanification initiale ne sont pas des événements du journal. | `rejouer` ne reconstruit pas `Planification.plan` si l'appelant ne répète pas ces appels dans le même ordre. |
| M8 | **Le « résidu d'e1RM » du secours n'est pas un résidu** : c'est le déplacement a posteriori de la capacité du jour pendant la séance (`jour_vu − jour_prevu`, `modele.fin_seance`), rétréci par le gain du filtre et absorbé en partie par DS et DE, puis moyenné en valeur signée sur la semaine (`Surveillance.fin_seance`, `fin_semaine`). La conversion de l'innovation de la note (`_residu_e1rm`) n'est jamais prise avec le modèle. | Le seuil du cahier (« résidu d'e1RM > 5 % deux semaines de suite ») est beaucoup moins sensible que prévu : le déplacement vaut 0,002 à 0,003 par séance quand l'écart observé contre prévu vaut plusieurs pourcents. |
| m6 | Alterner deux exercices dans une séance (superset A, B, A, B) rappelle `debut_exercice` à chaque changement et remet DE à son a priori (`modele.observer_serie`, `debut_exercice`). | Les séries d'après sont traitées comme un nouvel effet de jour indépendant, ce qui gonfle l'information sur la capacité. |
| m10 | La croissance du lundi (`modele.fin_semaine`) utilise la dose **moyenne** sur les hypothèses ; la dispersion entre hypothèses, (ρ + ε)²·Var_h(dose), n'entre pas dans P. | L'incertitude de prévision est sous-estimée. |
| m12 | `a_priori.delta_sd_declare` = 0,07 : un 1RM déclaré passe sous le seuil de calibrage (σ > 0,12) ; dès la première séance, Koach prescrit à partir de la déclaration au lieu de laisser choisir la charge (`seance._cible_charge`, étape 1). | Un 1RM auto-déclaré surévalué de 15 % donne une première série d'environ +11 % (prudence 0,6 × 0,07 ≈ 4 %). |
| m14 | Sans poids du corps (profil, séance ou événement `poids`), 72 kg sont pris en silence pour la masse totale (`Modele.__init__`, `Planification.__init__`). | L'e1RM sur masse totale des mouvements au poids du corps est faux sans que rien ne le signale. |

Autres limites connues :

- **Dérive résiduelle sur un plateau.** Après la porte de la note ouverte (B1), un essai synthétique de plateau (capacité vraie constante, notes majoritairement ≥ 4 RIR) montre encore une surestimation de l'e1RM de +4 à +7 % à 24 semaines (contre +5 à +14 % avant). Causes probables : progression a priori (ρ) et séries loin de l'échec. Non résolu.
- **Tenues.** La porte de la note ouverte ne s'applique pas aux tenues notées : une note ouverte de tenue est toujours versée.
- **Constat m1, second volet.** Dans la branche « mauvais jour », le test de la dichotomie compare la carte exacte à la prévision linéaire de cette branche (§ 5.4, étape 7).
- **Import partiel.** Après un import, les hypothèses de dose et leurs poids, la configuration de la BOCPD, `Planification.p`, `ControleDual.params` et l'essai en cours gardent leurs anciennes valeurs (§ 7.3). `mesure.porte_note_ouverte` est importable jusqu'à 100, ce qui rouvrirait la dérive B1.
- **Garde partielle (m5).** `Planification.evaluer` prend `ln(cible)` sans contrôler une cible ≤ 0.
- **Essai N-of-1.** `peut_demarrer` estime la durée par défaut d'un essai non planifié avec `DEFAUTS_DUAL['n_bras']` au lieu du paramètre ; toute liste `douleurs` non vide en fin de séance interrompt l'essai, même une gêne sous le seuil.

### A.3 Code mort, commentaires contraires, comportements à signaler

| # | Fichier, fonction | Constat |
| --- | --- | --- |
| 1 | `koach/modele.py`, `_apercu` | Jamais appelée ; sa variable `const` n'est pas utilisée. |
| 2 | `koach/modele.py`, `f_nerveux`, `f_musculaire` | `f_musculaire` renvoie le **tableau local lent** (17 valeurs), pas un nombre ; utilisées seulement par des outils de diagnostic. |
| 3 | `koach/modele.py`, `Piste` | `cran` jamais écrit ; `meilleur` et `premier_jour` écrits mais jamais lus par le moteur. |
| 4 | `koach/modele.py`, `piste` | `declare = False` puis passé au constructeur : variable inutile. |
| 5 | `koach/modele.py`, `f_tendon_aigu`, `f_tendon` | `f_tendon_aigu` tenu mais jamais lu ; `f_tendon` seulement exposé par `posterior`. |
| 6 | `koach/securite.py` | `SEMAINES_DE_CHARGE`, `Gardefous.dernier_jour_seance` et `avant_dernier_jour_seance` jamais utilisés. |
| 7 | `koach/seance.py`, `ouvrir` | `Seances.decalage` (décalage du bilan) calculé mais jamais utilisé (§ 8.5). |
| 8 | `koach/seance.py`, `Memoire` | Champs jamais lus : `cran_jour`, `haut_de_plage`, `facile`, `bas_manque`, `meilleur_sec`, `sec_total`, `total_seance`, `faciles_seance`, `flammes_seance`. |
| 9 | `koach/seance.py`, `_repere` | `plan.get('vrai_test')` : clé jamais posée (`prescrire` pose `apres_test`, jamais lue). La série repère peut suivre un vrai test du même jour, sauf via `dernier_test_jour`. |
| 10 | `koach/seance.py`, `cible` ; `koach/moteur.py`, `_plan` | Paramètre `faites` non lu. |
| 11 | `koach/numerique.py`, `dart_round` | Inutilisée. |
| 12 | `qualites/regles.py`, `SCHEMA` | Entrées `compression` et `transition_muscle_up` jamais lues (remplacées dans `parts_fixes`) ; leurs valeurs diffèrent de celles réellement utilisées. |
| 13 | `params/koach_params_v1.json` | 18 clés non lues par le moteur (§ 7.5), dont `rupture.fenetre` et `adherence.refus_silence_j`, présentes dans les dictionnaires de défauts. |
| 14 | `koach/modele.py`, docstring du module | Annonce une « réussite binaire (2PL en ogive normale) » : aucun modèle binaire n'existe. |
| 15 | `koach/modele.py`, `observer_serie` | La docstring cite `manual`, `parts`, `assistKg` : non lus. |
| 16 | `koach/moteur.py`, `observe` | La docstring cite le type `profil` (non traité) et omet `charge_manuelle`, `plan` et `parametres`. |
| 17 | `koach/modele.py`, `C_LIN` | Commentaire « Epley, Brzycki » : 0,0265 est plus plat que ces formules (≈ 0,028 à 0,032 ln/rép. entre 2 et 10 rép., calcul) ; l'écart est compensé par `courbe_echelle` = 0,10 (e^0,1·0,0265 = 0,0293). |
| 18 | `koach/rupture.py`, `koach/adherence.py`, `koach/dual.py` | Commentaires « Clés nouvelles (absentes de koach_params_v1.json) » périmés : elles y sont toutes. Renvois à « LIVRAISON » pour justifier des défauts : le document de livraison n'existe pas encore. |
| 19 | `koach/securite.py`, docstring du module | « Les valeurs viennent de `params['securite']` » : `palier_bilan` code en dur 0,015, 4, 6, 0,01, 3, 0,5, −0,08 ; `_arrets` l'épisode « réel » ≥ 4 ; `_semaines_de_charge` ≥ 4 jours. Valeurs égales à 0.3.1, mais hors fichier. |
| 20 | `koach/seance.py`, `_repere`, `_cible_charge` | Réserve des séries repères (1,5 ; 2 débutant) et fenêtre de 42 jours de la barre récente du repère en dur, alors que `barre_recente_j` existe. ±15 %/+5 % entre séries, 0,35, 0,2, 0,12, 2,5, 0,08 sont aussi codés en dur. |
| 21 | `koach/seance.py`, `_cible_charge` | Le commentaire « jamais plus lourd un jour verrouillé » (bornes dans la séance) ne correspond à aucune borne de ce bloc : en semaine verrouillée, seule la part écrite borne. |
| 22 | `koach/planification.py`, `__init__` | Le commentaire dit que `options['sans_validateur']` « refuse toute modulation au-delà des plafonds » : `_sur` accepte alors tout plan (déjà borné par `decoder`). |
| 23 | `koach/seance.py`, `_item` | `koach.douleur_retrait` (cause `reprise_dose`) porte `zone = cond['zone']` (souvent `None`) au lieu de la zone dont le budget est épuisé. |
| 24 | `koach/seance.py`, `cible` | Une raison est ré-émise à chaque appel : doublons dans `explain()`. |
| 25 | `koach/modele.py`, `avancer` | `q_delta_jour_inactif` est ajouté à **toutes** les pistes (le nom dit « inactif »), sur la branche principale seulement. |
| 26 | `koach/modele.py`, `_serie_force`, `_serie_tenue` | Le bruit de la note dépend de `R` = répétitions **possibles**, pas des répétitions faites ; pour une tenue, `R` = 6 en dur. |
| 27 | `koach/rupture.py`, `valider_parametres` | L'import admet un renommage des `qualites` et `classes_reponse` (contrôle de type seul), alors que la liste est « figée » (cahier, Méthodes § 2). `FIGEES` cite `controle_dual.plafond_volume` et `plafond_intensite`, absentes du fichier. |
| 28 | `koach/seance.py`, `_mesure_utile` | `jours_avant_echeance` n'est fourni par aucun appelant du banc (qui passe `jour_evenement`) : le blocage des mesures à l'approche de l'échéance (A6.5) est inactif sur le banc. |
| 29 | `banc/politique_koach.py` | Le facteur de cran (0,75) est fourni par le banc, pas par le fichier de paramètres. |
| 30 | `rejeu/journal_app.py`, `declares_initiaux` | La conversion de la charge de travail initiale d'un accessoire en 1RM utilise la courbe de population sans l'échelle `courbe_echelle` (e^0,1) que le moteur applique à g₀ : le 1RM déclaré est un peu plus bas que ce que le moteur déduirait de la même charge. |

### A.4 Points ouverts pour KM2

1. Faire acter ou corriger les écarts au cahier du § A.1, en particulier les n° 1 (séries sans note), 2 (BA figé, BP a priori non nul), 8 (compte des 256 plans) et 10 (demi-largeur).
2. M5 : décider de l'interprétation de l'intervalle (demi-largeur ou largeur totale), recalibrer le bruit de processus et `defaut_modele_sd` sur la campagne, ajouter le critère « demi-largeur sous 6 % après 8 semaines de journal régulier ».
3. M6 : appliquer dans `Koach._plan`, dans un ordre fixe, les modulations des extensions (allègement, planification, bras d'essai, forme), ou figer dans le contrat de KM3 l'API d'appelant que le banc utilise.
4. M7 : ajouter un événement `reference` (blocs ou empreinte, cibles, échéance, poids) traité par `observe`.
5. M8 : mesurer le résidu par l'innovation de la note convertie en ln capacité, ou diviser le déplacement par le gain.
6. Porter le retour gradué au volume et la durée bornée (§ 8.3) dans le moteur Dart, et les règles de volume de 0.3.1 encore portées par le validateur seul (`securite.plafond_hebdo_par_niveau`, `decharge_max_semaines`, `affutage_baisse`), ou fournir un validateur équivalent obligatoire.
7. Décider du sort des 18 clés non lues : supprimer ou brancher.
8. Adapter `fixtures/generer.py` et régénérer les fixtures de parité (§ 9.6) ; écrire en boucles ordonnées les produits de `tirer` et `evaluer` ; remplacer `round` dans `_surmenage`.
9. Import : réappliquer hypothèses, BOCPD, `Planification.p` et `ControleDual.params`, ou figer ces sections ; borner `porte_note_ouverte` (par exemple à 3 au plus).
10. Étendre la porte de la note ouverte aux tenues ; chercher l'origine de la dérive résiduelle sur un plateau.
11. Corriger ou acter m6, m10, m12, m14, et le second volet de m1.
12. Calibrer `lambda_transport` sur le banc (cahier § 6).
