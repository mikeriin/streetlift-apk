# Contrat de Koach 1.0 (`kalis_adapt` 1.0.0)

Rédigé le 09/10/2026 d'après le code de la référence Python (`packages/kalis_adapt/reference/`, branche `moteurs`, arbre de travail du lot KM1).
Fichier de paramètres lu : `params/koach_params_v1.json`, SHA-256 `111bdf818349fe5bc6b9cc2d64f147ffa230da3290c08e42400bfefa74b3f734`, 263 clés.

Ce contrat décrit le code tel qu'il est. Quand le code, un commentaire ou le cahier divergent, le contrat suit le code et signale l'écart dans l'annexe A. Le lot KM2 porte ce contrat en Dart ; la parité visée est de 1e-9 (cahier, « Contraintes »).

Conventions : `ln` = logarithme népérien ; « capacité » = capacité à frais d'un exercice, dans son unité (1RM de charge totale en kg, répétitions maximales, secondes de maintien maximal, ou capacité d'endurance) ; `clamp(x, a, b)` borne x ; les références `fichier:ligne` renvoient à `reference/`.

---

## 1. Objet, périmètre, vocabulaire

### 1.1 Objet

Koach 1.0 est un moteur hors ligne en quatre parties :

1. **Estimation** : un filtre gaussien sur un état latent. L'état regroupe 10 qualités, la réponse à l'entraînement, des sensibilités à la fatigue, la mesure de la note et la courbe répétitions-charge, plus 3 composantes par exercice suivi.
2. **Prescription** : la séance et la série suivante (charges, plages, séries, tests, tentatives).
3. **Garde-fous** : les règles de sécurité de `kalis_adapt` 0.3.1, en contraintes dures.
4. **Extensions** : planification hebdomadaire, surveillance hors modèle, adhérence, contrôle dual.

L'état se recalcule en rejouant le journal (`moteur.rejouer`). Le § 9.5 précise les limites de cette propriété.

### 1.2 Modules

| Module | Rôle |
| --- | --- |
| `koach/numerique.py` | fonctions numériques portables (erfc, loi normale, appariement de moments, mulberry32, fnv1a32) |
| `koach/modele.py` | état, a priori, dynamique, modèles de mesure, mises à jour |
| `koach/securite.py` | état de la douleur par zone, paliers du bilan, conduite sous douleur |
| `koach/seance.py` | prescription de séance, cible de série, vrai test, tentatives, mémoire par exercice |
| `koach/moteur.py` | façade `Koach` (`observe`, `posterior`, `plan`, `explain`), classe `Extension`, `rejouer` |
| `koach/planification.py` | extension `Planification` (replanification hebdomadaire) |
| `koach/rupture.py` | extension `Surveillance` (BOCPD, secours, diagnostic, dossier), `importer_parametres` |
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

L'ordre est celui de `qualites/regles.py:25` et de `params.qualites`. Chaque fiche porte un `vecteur` de 10 charges ≥ 0 de somme 1, arrondies à 4 décimales ; l'arrondi est reporté sur la plus forte charge (`regles.py:401-405`).

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
  - `f ≥ 10` : `(−∞ ; 0,25]` (lu par l'appelant, `modele.py:822-823`) ;
  - `f = 9` : `[0,25 ; 1,25]`, ou `[0,25 ; 1,5]` pour un noteur entier ;
  - sinon `r = (11 − f)/2` et demi-largeur `d = 0,25` (`0,5` pour un noteur entier) ; si `r ≥ ouvert`, l'intervalle est `[r − d ; +∞)` (catégorie ouverte « 4 ou plus »), sinon `[r − d ; r + d]`.
- **Noteur entier** (`noteur_entier`) : au moins `noteur_entier_notes_min` notes non ratées et inférieures à 10, dont au plus `noteur_entier_part_max` × n à la demi-répétition. Une note à la demi-répétition est une flamme paire (2, 4, 6 ou 8).

---

## 2. Schéma du journal

Le journal est une liste ordonnée d'événements (dictionnaires JSON). `Koach.observe(e)` les ajoute à `koach.journal` dans l'ordre reçu. Le champ `type` est obligatoire. Un type inconnu est journalisé puis ignoré.

### 2.1 Événements lus par le moteur

| `type` | Champs (type, unité) | Effet |
| --- | --- | --- |
| `seance_debut` | `jour` (entier, jours depuis le début) ; `bilan` (objet ou absent) ; `poids_kg` (nombre ou absent) ; `contexte` (objet ou absent) | `garde.avancer(jour)` ; si `bilan.pains` n'est pas `None`, `garde.noter_seance(jour, pains, posee=True)` ; `modele.debut_seance` ; `seances.ouvrir` |
| `serie` | `serie` (objet, § 2.2) | `modele.observer_serie`, puis `seances.serie_faite` |
| `seance_fin` | `douleurs` (liste `{zone, intensity}` ou absent) ; `seance` (objet `{sets: [serie…]}`) | `garde.noter_seance(jour, douleurs, posee=False)` si la liste n'est pas vide ; `seances.fermer(seance)` ; `modele.fin_seance()` ; crochets `fin_seance(koach, resume, e)` |
| `seance_manquee` | `jour`, `semaine` (lus par les extensions) | crochets `seance_manquee` seulement |
| `semaine_fin` | `jour` (entier) ; `semaine` (entier, indice de la semaine qui finit) ; facultatifs lus par le contrôle dual : `alerte_hors_modele`, `alerte`, `douleur`, `douleurs` | `modele.avancer(jour)`, `modele.fin_semaine()`, crochets `fin_semaine(koach, ligne, e)` |
| `cran` | `exerciseId` ; `facteur` (> 0) | `modele.changer_cran` |
| `poids` | `poids_kg` | `modele.poids_kg` |
| `charge_manuelle` | `exerciseId` ; `loadKg` (charge externe, kg) ; `reps` ; `rir` | `modele.observer_charge_manuelle` |
| `decision` | voir § 2.4 | crochets `decision(koach, e)` seulement |

Le `jour` de `seance_fin` n'est pas lu : la séance garde le jour de `seance_debut` (`koach.jour`).

**`bilan`** (bilan de santé du jour). Les clés suivantes sont lues ; une clé absente ou `None` vaut « non répondu ».

| Clé | Valeurs |
| --- | --- |
| `overall` | 0 à 5 (neutre 4) |
| `sleepHours` | heures de sommeil |
| `sleepQuality`, `energy`, `mood`, `soreness`, `stress`, `motivation`, `nutrition`, `hydration` | 1 à 5 ; une réponse ≤ 2 compte |
| `pains` | liste `{zone, intensity}` ; liste vide = question posée, aucune douleur ; absente = question non posée |

Codes de zone : `neck`, `shoulder`, `elbow`, `wrist_hand`, `upper_back`, `lower_back`, `chest`, `abdomen`, `hip`, `thigh`, `knee`, `lower_leg`, `ankle_foot`.

**`contexte`**. Les clés lues :

| Clé | Lue par | Usage |
| --- | --- | --- |
| `semaine` | `seances.ouvrir` | indice global ; sans elle, la semaine n'est pas notée |
| `genre` | `seances.ouvrir` | `kind` de la semaine du plan |
| `intention` | `seances.ouvrir` | `intent` de la semaine du plan |
| `jour_evenement` | `seances._item` | booléen ; jour d'épreuve |
| `jours_avant_echeance` | `seances._mesure_utile` | entier |

`budget` et `lieu` sont transmis par le banc mais ne sont pas lus.

### 2.2 Objet `serie`

Lu par `Modele.observer_serie`, `Seances.serie_faite` et `Seances.fermer`.

| Champ | Type, unité | Lu par | Sens |
| --- | --- | --- | --- |
| `exerciseId` | texte | tous | identifiant de la base (clé des fiches) |
| `slotId` | texte | seance | emplacement ; relie la série au plan servi (`slotId + '.t'` pour un vrai test) |
| `kind` | `work`, `warmup`, `test` | seance.fermer | les échauffements ne comptent pas dans la mémoire (maximums, échec, barres réussies) |
| `reps` | entier ≥ 0 | modele, seance | répétitions faites |
| `seconds` | nombre ≥ 0 | modele, seance | durée tenue (tenues) |
| `externalLoadKg` | nombre ≥ 0 ou `None` | modele, seance | charge externe (sans le poids du corps) |
| `flames` | 1 à 10 ou `None` | modele, seance | note ; `None` = série sans note |
| `failed` | booléen | modele, seance | série ratée |
| `target` | objet `{repsLow, repsHigh, secondsLow, secondsHigh, flames, role}` | modele (`flames`), seance (`repsHigh`, `flames`, `role`) | cible servie ; `target.flames` = note préremplie ; `target.role` ∈ `None`, `test`, `attempt` |
| `restSeconds` | s | modele | repos avant la série (défaut 90) |
| `role` | texte | modele | `test` ou `attempt` marque une mesure (`dernier_test_jour`) |
| `repere` | booléen | modele | série repère (marque une mesure) |
| `demand` | nombre > 0 | modele (cardio, wod) | demande relative écrite (cardio : durée écrite × poids de qualité, en minutes) ; sans elle, la série d'endurance est ignorée |
| `doneShare` | 0 à 1 (défaut 1) | modele (cardio, wod) | part faite ; < 0,999 = séance écourtée |
| `dose` | nombre (défaut 1) | modele (cardio, wod) | stimulus ajouté aux trois compteurs de la semaine |
| `fatigueSets` | nombre (défaut 1) | modele (cardio, wod) | équivalent en séries pour les compartiments |

Le banc transmet aussi `setIndex` et `technique`, que le moteur ne lit pas. La docstring de `observer_serie` cite `manual`, `parts` et `assistKg` : ces champs ne sont pas lus (annexe A).

### 2.3 Masse et unité de capacité

Pour un exercice `charge`, la masse vaut `masse = externalLoadKg + fraction × poids_kg`. `fraction` est la part du poids du corps donnée par la fiche ; `poids_kg` vient du profil (défaut 72), d'un `seance_debut.poids_kg` ou d'un événement `poids`. La capacité est l'e1RM de cette masse totale, comme le demande le cahier (Méthodes § 2). Pour les autres types, la masse vaut 1.

### 2.4 Événements `decision`

Le moteur ne les lit pas ; chaque extension filtre ce qui la concerne.

| Charge utile | Extension | Champs |
| --- | --- | --- |
| `proposition` | Adhérence | `jour` ; `proposition` `{id, type ∈ TYPES, exerciseId, ampleur, charge_kg, reps, rir, contexte {bilan_bas, semaine_allegement, moment, refus_recents}}` ; `accepte` (booléen) ; `raison` ∈ `too_heavy`, `too_light`, `equipment`, `time`, autre ou `None` |
| `diagnostic` | Surveillance | `{cause ∈ douleur, moins_de_temps, fatigue, rien ; zone ; intensite ; seances_par_semaine ; duree_max_min}` |
| `essai` | Contrôle dual | `{semaine, cible {qualite | exerciseId}, traites, temoins, contexte, graine, n_bras}` |
| `alerte_hors_modele` | Contrôle dual | booléen ; interrompt l'essai en cours |

Types de proposition (`adherence.TYPES`) : `charge_plus`, `charge_moins`, `volume_plus`, `volume_moins`, `reps_plus`, `reps_moins`, `echange`, `test`, `allegement`. Moments : `debut_de_seance`, `entre_series`, `prochaine_seance`.

### 2.5 Entrées hors journal

Ces entrées sont nécessaires au calcul mais ne sont pas des événements :

- `params` : le fichier de paramètres (§ 7).
- `fiches` : `vecteurs_qualites_v1.json`, champ `exercices`. Champs lus par le moteur : `type`, `vecteur`, `ratio`, `fraction`, `difficulte`, `bas`, `tendon`, `zone_tendon`, `systemique`, `locale`, `groupes`, `schema`, `type_charge`.
- `profil` : `niveau` 0–3 (borné ; défaut 1), `sexe` (`female` réduit l'a priori de charge), `poids_kg`, `declares` `{exerciseId: (mesure, valeur)}`, `zones_fragiles`. Les mesures déclarées sont `one_rm_kg`, `max_reps` ou `max_hold_seconds`. `zones_fragiles` est lu mais n'a aucun effet (annexe A).
- Les **contraintes** de `plan` (§ 3.3).
- La **référence** de la planification (`charger_reference`).
- Les poids d'hypothèses écrits par le contrôle dual.

### 2.6 Ce qui est recalculé depuis le journal

Toutes ces données sont recalculées : l'état gaussien (deux branches pendant une séance), les compartiments de fatigue, le multiplicateur de bruit, les compteurs de notes et de paresse, l'état de douleur, la mémoire de prescription par exercice, les doses par zone et les états des extensions. Le § 9.5 liste les conditions sans lesquelles un rejeu ne redonne pas le même état.

---

## 3. API

### 3.1 `Koach(params, fiches, profil)`

Le constructeur crée `modele`, `garde` (`Gardefous(params, niveau, zones_fragiles)`), `seances`, `journal = []`, `raisons = []`, `jour = 0` et `extensions = []`. Les extensions sont ajoutées par l'appelant, et leur ordre compte : c'est l'ordre des crochets.

### 3.2 `observe(evenement)` → `None`

Voir § 2.1.

### 3.3 `plan(contraintes)`

Le champ `horizon` choisit le traitement. Une autre valeur lève `ValueError`.

**`horizon = 'seance'`.** Entrées :

| Clé | Contenu |
| --- | --- |
| `items` | items écrits du jour (format `kalis_core`), déjà modulés par la planification et l'allègement (§ 3.7) |
| `grilles` | `{exerciseId: Grille(pas, minimum, halteres)}` |
| `zones` | `{exerciseId: (niveaux {zone: 0, 0,5 ou 1}, zones provoquées : ensemble)}` |
| `roles` | `{slotId: main, secondary, …}` |

Sortie : `{'items': [...], 'raisons': [...]}`.

Chaque item servi est une copie de l'écrit ; seuls `sets` et `setTargets` changent. `setTargets` vaut `None` pour un item de travail `charge`, `reps` ou `tenue`. Les items retirés disparaissent.

Les champs `koach*` peuvent être posés sur un item écrit, par l'appelant ou par la planification. Ils sont lus ainsi :

| Champ | Posé par | Lu par | Effet |
| --- | --- | --- | --- |
| `koachIntensite` | `Planification.appliquer` | `_cible_charge` | écart relatif de charge totale, borné à ±`plafond_intensite`, ignoré en semaine verrouillée |
| `koachVolume` | `Planification.appliquer` | — | information : séries servies − séries écrites |
| `koachCible` | l'appelant | `_tentative` | charge externe visée, tentée à la dernière barre si P ≥ 0,35 |
| `koachFragile` | l'appelant | `_bornes_hausse` | divise la hausse permise par 2 |

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

L'intervalle à 90 % vaut `exp(μ ± 1,6448536269514722·σ)`. Toutes ces valeurs sont « à frais » : sans effet de jour ni fatigue.

### 3.5 `explain()` → liste

`explain()` renvoie une copie de `seances.raisons` : les raisons émises depuis l'ouverture de la séance, prescription et séries comprises. Chaque raison a la forme `{code, params}`. Une raison émise par `cible` est ré-émise à chaque appel ; les doublons sont donc possibles.

**Liste complète des codes `koach.*`.** L'application écrit un texte par code.

| Code | Paramètres | Émis quand |
| --- | --- | --- |
| `koach.douleur_retrait` | `exercice`, `zone` (ou `None`), `cause` ∈ `douleur`, `douleur_arret`, `douleur_reprise`, `reprise_dose` | exercice retiré par la conduite sous douleur ou budget de reprise épuisé (`seance.py:377`, `:415`) |
| `koach.test_reporte` | `exercice`, `cause` = `bilan_bas` | test écrit retiré un jour de bilan ≥ 1, hors jour d'épreuve (`:380`) |
| `koach.reprise_coupure` | `exercice`, `jours` (entier) | séries × `coupure_series` après ≥ `coupure_j` jours sans séance (`:402`) |
| `koach.reprise_dose` | `exercice`, `zone` | séries ramenées au budget hebdomadaire de la zone en reprise (`:413`) |
| `koach.vrai_test` | `exercice` | vrai test inséré (`:355`) ; le même code figure dans `reasons` de l'item de test, avec `params` vide |
| `koach.arret_exercice` | `exercice`, `cause` = `echecs` | `echecs_arret` échecs dans l'exercice (`:450`) |
| `koach.serie_repere` | `exercice` | série repère (charge, répétitions, tenue) (`:651`, `:760`, `:815`) |
| `koach.tendon` | `exercice` | durée d'une tenue en bras tendus bornée par la hausse des tendons (`:800`) |

Les raisons « pas de hausse sur douleur », « bilan bas », « borne de hausse », « part écrite » et « séries ×0,6 sur douleur » n'ont pas de code : elles n'apparaissent que dans `trace`. Les extensions ont leurs propres codes, hors `koach.*` :

- Surveillance : causes `rupture`, `residu`, `assiduite`, `douleur` ; actions `conduite_douleur` (avec `renvoi_professionnel: True`), `replanifier`, `semaine_allegee`, `elargir` ; codes des questions et des choix (§ 3.7.2).
- Contrôle dual : raisons texte `essai_demarre:<semaine>:`, `essai_refuse:<semaine>:<raisons>`, `essai_interrompu:<raison>`, `synthetique_impossible:<message>`. Raisons de refus : `non_calibre`, `affutage`, `alerte_hors_modele`, `douleur`, `echeance_proche`, `deja_<statut>`, `essai_en_cours`, `semaines_insuffisantes:n<m`, `aucun_lift_principal`, `lift_inconnu:<id>`, `intervalle_large:<id>:<demi>`.

### 3.6 Extensions : crochets

`Extension` (`moteur.py:137-153`) définit cinq crochets, tous facultatifs :

| Crochet | Appelé |
| --- | --- |
| `fin_seance(koach, resume, e)` | après `modele.fin_seance` |
| `seance_manquee(koach, e)` | sur `seance_manquee` |
| `fin_semaine(koach, ligne, e)` | après `modele.fin_semaine` |
| `decision(koach, e)` | sur `decision` |
| `plan_semaine(koach, c)` | sur `plan` à l'horizon `semaine` |

Les crochets sont appelés dans l'ordre de `koach.extensions`. Deux crochets sont appelés par d'autres modules :

- `sur_alerte_hors_modele(koach, causes)` : appelé par `Surveillance.verifier`.
- `appliquer_parametres(params)` : appelé par `importer_parametres`.

`rejouer(params, fiches, profil, journal, extensions)` instancie les extensions (fabriques sans argument) et rejoue le journal.

### 3.7 Extensions : algorithmes

#### 3.7.1 `Planification(params, fiches, validateur=None, options=None)`

`options` surcharge `params.planification` (copie gardée à la construction).

`charger_reference(blocs, block_weeks, horizon, cibles, echeance_jour, principaux, poids_corps)` prend les paramètres suivants :

- `cibles` : `{exerciseId: valeur visée}`, en charge **totale** pour un exercice chargé.
- `principaux` : exercices suivis en plus des cibles.

Les exercices suivis, `suivis`, sont les cibles triées puis les principaux, gardés s'ils ont une fiche.

**Semaines de référence.** Pour la semaine globale w :

- bloc `k` = dernier indice `j` tel que `block_weeks[j] ≤ w` ;
- semaine de bloc `w − block_weeks[k]` ;
- semaine écrite = **dernière** entrée de `pass2.weeks` portant ce `weekIndex`.

Une semaine est **verrouillée** si `intention or genre` ∈ {intro, deload, taper, test, competition, transition} ou si `genre` ∈ {deload, test, intro}.

**Lignes d'un item** (`lignes_item(item, e)`). Elles sont vides pour un échauffement, une fiche absente ou `sets ≤ 0`.

- `rir` = réserve des `targetFlames` (2,5 sans flammes) ; pour un test, `test.targetRir` (1 par défaut).
- `reps` = moyenne de `repsLow` et `repsHigh` ; `quantité` = `reps`, sinon secondes/10, sinon 1.
- Pour une fiche `charge` : `part` = `percentOfOneRm`, sinon `exp(−g₀(reps ou 8 + rir))` ; `pente` = `g₀'(reps + rir)` ; g₀ est la courbe de population (§ 5.1). Sinon `part = None` et `pente = 0,03`.
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
2. Construit `H` : une ligne par exercice suivi (fonctionnelle de capacité à frais, moyenne `base + h·m`), puis une ligne pour ρ et une par EPS_c.
3. `S = H P Hᵀ`, puis `S = ½(S + Sᵀ) + 1e-12·I`.
4. Décomposition propre (`numpy.linalg.eigh`), valeurs propres négatives mises à 0, `L = V·√Λ`.
5. Générateur mulberry32 de graine `fnv1a32('koach-plan:<graine>:<semaine>')`. Ordre des tirages : `z[a, b]` gaussien pour a < n, b < k (ligne par ligne) ; puis n uniformes pour l'hypothèse de chaque trajectoire (inversion de la fonction de répartition des `poids_hyp`, dernier indice par défaut) ; puis, pour chaque a et chaque b < max(E, 1), `bruit_jour[a, b]` et `bruit_proc[a, b]` en alternance.
6. `x = moyennes + z·Lᵀ`.

**Évaluation** (`evaluer(X, tirage, depuis, blocs, qualites)`) :

- **Décodage.** Pour le bloc j, la variable de volume i (qualité q active) donne `A[:, j, q] = 1 + clip(X, ±plafond_volume)` ; l'intensité donne `I[:, j] = clip(X, ±plafond_intensite)`.
- **Dernière semaine.** `fin = horizon − 1`. Avec une échéance, `fin = min(fin, jour_ech // 7)`. Sans échéance ni cible, `fin = min(fin, depuis + horizon_sans_echeance_sem − 1)`.
- **Boucle sur w.** Une semaine non écrite ne contribue qu'à la fatigue : `F ×= e^(−1)`. Une semaine écrite :
  1. En semaine verrouillée : `a = min(a, 1)` et `i = min(i, 0)`.
  2. Interpolation linéaire de `stim` et `syst` sur la grille ; le stimulus est multiplié par `fe = a·Vᵀ`.
  3. `charge_jour[c, d] = Σ_q syst[c, d, q]·a[c, q]`.
  4. Fatigue lente (τ = `tau_musculaire_j`) : `F = F·e^(−7/τ) + Σ_d charge_jour[d]·e^(−(7 − d)/τ)` ; au matin de l'échéance, `f_ech = F·e^(−de/τ) + Σ_{d<de} charge_jour[d]·e^(−(de − d)/τ)`.
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
2. Dimensions : `d = blocs × (qualités actives + 1)`, avec les blocs dans l'ordre de première apparition à partir de `semaine`. `pop = max(4, plans_max // iterations)`. `elite_n = max(2, round(pop·elite))`. Graine CEM : `fnv1a32('koach-cem:<graine>:<semaine>')`.
3. Moyenne de départ : le plan en cours, à la première semaine du bloc qui en a un. Écart de départ : ½ plafond.
4. Pour chaque itération : `X[0] = 0` (référence), `X[1] = moy`, `X[2…]` = `moy + écart·gauss`, tirés ligne par ligne puis bornés. Les candidats sont triés par `(−valeur, indice)`. Mise à jour : `moy = lissage·moy_élite + (1 − lissage)·moy` et `écart = max(lissage·sd_élite + (1 − lissage)·écart ; 1e-4)`, où `sd_élite` est l'écart-type de population (numpy `std`, ddof 0). Les 4 meilleurs candidats de l'itération sont ajoutés en tête de `candidats_finaux`, qui garde aussi les 4 premiers de la liste précédente.
5. Choix. Les essais sont le meilleur candidat, puis `candidats_finaux`. Un essai est écarté si sa valeur ≤ valeur de référence + `gain_min`. Sinon il est soumis au validateur (`_sur`) jusqu'à 3 fois ; s'il échoue, il est divisé par 2 et resoumis. Le premier essai validé dont la valeur dépasse celle du plan choisi (au départ, la référence) + `gain_min` est retenu.
6. Le plan retenu est écrit pour toutes les semaines écrites ≥ `semaine`, avec le verrou appliqué : `plan[w] = {volume: [10], intensite}`.

**Application.** `items_modules(w)` calcule, pour chaque item écrit de la semaine (jours puis items, dans l'ordre écrit), le nombre de séries servies :

- Échauffements, tests et items sans séries : séries inchangées, écart 0.
- Autres items : `voulu = n·Σ_q v_q·volume_q + reste[ex]`, `servi = max(1, floor(voulu + 0,5))`, `reste[ex] = voulu − servi`.
- Plafond dur sur les séries entières : tant qu'une qualité dépasse `ref·(1 + plafond_volume)`, les ajouts sont retirés un par un, dans l'ordre inverse. Puis, tant qu'une qualité de référence non nulle passe sous `ref·(1 − plafond_volume)`, les retraits sont rendus un par un, dans l'ordre inverse.

`appliquer(semaine, jour, items)` copie les items modifiés et pose `sets`, `koachIntensite` (si l'écart ≠ 0) et `koachVolume`.

`blocs_modules(plan)` produit la copie des blocs que lit le validateur. Il y écrit les séries et `setTargets = None`. Si l'écart d'intensité est non nul, il multiplie aussi `percentOfOneRm` et `intensity.value` (base `percent_one_rm`) par `1 + e` (arrondis à 4 décimales), et `startLoadKg` devient `(startLoadKg + bw)·(1 + e) − bw` (arrondi à 3 décimales).

`_sur(x)` est vrai si le validateur ne trouve, sur les blocs modulés, aucun constat `(code, week, dayIndex, exerciseId)` absent des constats de la référence (multiensemble). Sans validateur, il est toujours vrai.

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
| `residu` | sur les `residu_secours_semaines` dernières semaines, chaque \|moyenne des résidus d'e1RM de la semaine\| > `residu_secours` ; le résidu d'e1RM d'une séance est `resume[5]`, écart ln entre capacité du jour vue après la séance et prévue avant, mouvements chargés suivis depuis 3 séances |
| `assiduite` | séances faites < `assiduite_secours` × prévues, cumulées sur `assiduite_secours_semaines` semaines |
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

`appliquer_allegement(items, jour)` est appelé par l'appelant, pas par le moteur. Sur les items de travail ayant au moins une série : `sets = max(1, floor(sets·f + 0,5))`, et les flammes (y compris celles de `setTargets`) baissent de `floor(2·rir + 0,5)`, au moins 1, sauf à 10.

`dossier(koach)` exporte un dossier hors modèle anonymisé :

- les `journal_dossier` derniers événements, hors événements `profil` ;
- les clés de `CLES_INTERDITES` sont retirées ;
- un texte est gardé seulement s'il est un code (au plus 64 caractères `[A-Za-z0-9_.-]`, pas une date ISO).

`importer_parametres` : voir § 7.3.

#### 3.7.3 `Adherence(params)`

Le modèle est un probit bayésien : `P(accepte) = Φ(w·x)`, avec `w ~ N(m, P)` de dimension 16.

- A priori : `m₀ = (biais_initial, 0, …)`, `P₀ = a_priori_poids_sd²·I`.
- Caractéristiques `x` : biais 1 ; indicatrice du type (9) ; `min(|ampleur|/ampleur_echelle, ampleur_borne)` ; bilan bas ; semaine d'allègement ; moment `entre_series` ; moment `prochaine_seance` ; `min(refus récents/refus_recents_echelle, 1)`.
- Prédiction : `Φ(m·x/√(1 + xᵀPx))`.
- Mise à jour : `interval_moments(s, v, 1, 0, +∞)` si la proposition est acceptée, `(−∞, 0]` sinon, reportée en rang 1. La variance `v` est bornée à 1e-12.

Un refus avec `too_heavy` ou `too_light` (et charge, reps, rir fournis) devient aussi une mesure faible de capacité (§ 5.10). `equipment` et `time` sont rangés comme contraintes de planification.

`forme(cible, depart, pas_min, type, contexte)` découpe le trajet en paliers :

- n va de 1 à `min(paliers_max, floor(d/pas))` ;
- paliers intermédiaires `depart ± pas·floor(k·d/(n·pas) + 0,5)`, dernier palier = cible exactement ;
- chaque pas doit valoir au moins `pas_min` quand n > 1 ;
- pour chaque n, on retient le moment de plus forte probabilité minimale (ordre `MOMENTS`) ;
- on s'arrête au premier n dont la probabilité minimale atteint `proba_cible`.

La forme ne change jamais la cible.

#### 3.7.4 `ControleDual(params, lifts_principaux)`

**Poids des hypothèses.** `Reponse` tient un a posteriori discret sur les 9 hypothèses (§ 4.4). Ses poids sont recopiés dans `modele.poids_hyp` à chaque fin de semaine.

**Innovation hebdomadaire.** Pour chaque exercice suivi d'une classe :

- `ν = μ_pré(b) − μ_post(b − 1)` ;
- `g_h = (ρ + EPS)·facteur·dose_h(stim)` et `g_u = Σ w_h g_h` ;
- `V_prior = V_post(b − 1) + 7·q_delta_jour_inactif` ;
- gain `K = clamp(1 − V_pré/V_prior ; 0 ; 1)` ;
- observation `(K·δ_h, ν, max(V_prior − V_pré, 0) + sigma_innovation²)`, puis `δ_h ← (1 − K)·δ_h + g_h − g_u`.

La vraisemblance est gaussienne. Les poids sont normalisés en espace logarithmique, mis au plancher `plancher_poids`, puis renormalisés.

**Calibrage** (`calibre`) : au moins `semaines_min` semaines de journal, et `1,6448536269514722·σ < intervalle_max` pour chaque lift principal.

**Essai N-of-1** (`EssaiN1`) :

- Bras A : volume × (1 + `amplitude_volume`). Bras B : intensité × (1 + `amplitude_intensite`).
- Séquence ABBA ou BAAB : tirage `rng.next() < 0,5` avec la graine `fnv1a32('koach-dual-essai:<graine>:<semaine>')`.
- Mesure hebdomadaire : progrès de la cible − progrès de son témoin synthétique. Le témoin est un contrôle synthétique démoyenné, poids sur le simplexe, FISTA à pas 1/L avec L = 2 × majorant de λmax(A) (trace de A^16, puissance 1/16) ; projection exacte sur le simplexe par tri par insertion stable.
- Analyse : différences appariées par paire de bras ; variance intra-bras groupée ; a priori `N(0, a_priori_effet_sd²)`. Décision `B` si `P(B > A) ≥ seuil_decision`, `A` si P ≤ 1 − seuil, indéterminée sinon.

**Tirage de Thompson.** `hypothese_pour_la_semaine` tire un indice avec la graine `fnv1a32('koach-dual:<graine>:<semaine>')`. La planification ne l'appelle pas (annexe A).

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
- KN, KM, KL, KG, BA, BP, λ, KU, FI, HH : moyenne et variance tirées de la paire `[moyenne, sd]` du fichier (`k_nerveux`, `k_musculaire`, `k_nerveux_local`, `k_musculaire_systemique`, `biais_rir_additif`, `biais_rir_proportionnel`, `courbe_forme`, `courbe_echelle`, `fatigue_intra`, `part_tenue`). Une `sd` nulle fige la composante.

**Constante de population d'un exercice** (`base_de`, ln de capacité) :

- `charge` : `ln max(ratio·poids·niveau_echelle_charge[niveau]·(facteur_femme si female) ; fraction·poids·1,1 ; 1)`.
- `reps`, `tenue` : `ln clamp(base·e^(pente_difficulte·marge) ; bornes)`, où `marge = marge_niveau[0] + marge_niveau[1]·niveau − difficulte` (difficulté 3 par défaut), `base` vaut `reps_base` ou `tenue_base_s`, et les bornes `reps_bornes` ou `tenue_bornes_s`.
- `cardio` : `ln cardio_minutes_par_niveau[niveau]`.
- `wod` : 0.

**Création d'une piste**, sur les deux branches si une séance est ouverte :

- `δ_e` : moyenne 0, variance `max(sd² − Σ_q v_q²·P[θ_q, θ_q] ; (0,5·sd)²)`. `sd` vaut `delta_sd` (charge), `reps_sd` (reps et tenue), `cardio_sd` ou `wod_sd`. `P[θ_q, θ_q]` est la variance **courante** (a posteriori) au moment de la création.
- `κ_e` : moyenne `courbe_bas_du_corps` si `bas`, sinon 0 ; variance `courbe_echelle_exercice_sd²`. Pour une tenue : moyenne 0, variance `part_tenue_exercice_sd²`.
- `φ_e` : moyenne 0, variance `fatigue_intra_exercice_sd²`.
- **Capacité déclarée.** Si `declares[id] = (mesure, valeur)`, que la mesure correspond au type et que la valeur est > 0, on verse une observation ponctuelle hors séance : `base + Σ v_q θ_q + δ_e = cible`, de variance `delta_sd_declare²`. La cible vaut `ln(valeur + fraction·poids)` pour une charge, `ln valeur` sinon.

### 4.3 Fonctionnelles de capacité

`h_frais(e)·x` : coefficient `v_q` sur θ_q (seulement pour `v_q ≠ 0`, dans l'ordre q), puis 1 sur δ_e. La capacité à frais vaut `base + h_frais·x`.

`h_jour(e)` = `h_frais` + `[DS : 1, DE : 1, KN : −gn, KL : −ln, KG : −gm, KM : −lm]`, avec les régresseurs de fatigue `(gn, ln, gm, lm) = (f_g[0], loc[0], f_g[1], loc[1])` et `loc[c] = Σ_g w_g·f_l[c][g]/Σ_g w_g` sur les groupes de la fiche (0 sans groupe).

`capacite(id)` renvoie `(base + h_frais·m, √(h_frais P h_frais))`. `capacite_du_jour(id)` fait le même calcul avec `h_jour` ; pendant une séance, c'est le mélange des deux branches, de poids `w` = poids du mauvais jour : moyenne `(1 − w)μ₀ + wμ₁`, variance par appariement des moments.

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
  - `g = dose_moyenne(stim)·facteur` ;
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

**Changement d'exercice.** Quand une série porte un exercice différent de la série précédente, DE est remis à zéro sur les deux branches. Si c'est le premier passage de la piste ce jour-là :

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

**Mise à jour** (`_observer`), pour chaque branche, dans l'ordre principale puis alternative :

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
6. **Grande surprise** (`|μ₂ − μ| > 1` et carte exacte fournie) :
   - `pas = ph·(μ₂ − μ)/v` ;
   - si `|f(m + pas) − μ| > |μ₂ − μ|`, **12** dichotomies sur α ∈ [0 ; 1] : on garde la borne basse, avec le même test à `m + α·pas` ;
   - `m += α·pas` ; `P −= ph·phᵀ·(v − v₂)/v²`.
   - `f` recalcule la prévision exacte (`_lin_force` ou `_lin_tenue`) en un état donné.
7. Sinon, report de rang 1 : `m += ph·(μ₂ − μ)/v` ; `P −= ph·phᵀ·(v − v₂)/v²`.
8. Log-poids de la branche : `+= logZ`.

**Observations hors séance** (`_observer_hors` : déclaration, refus motivé, charge manuelle). La branche alternative est suspendue pendant l'observation ; seule la branche principale est mise à jour et son log-poids est restauré.

### 5.5 Catégories de flammes, catégorie ouverte, noteur entier

Les intervalles sont ceux du § 1.5. La catégorie ouverte vaut `[r − d ; +∞)` pour r ≥ `rir_ouvert`.

**Porte de la note ouverte.** Si `b = +∞`, que la note est perçue et que `prévision ≥ a + porte_note_ouverte·√s²`, la série ne met pas l'état à jour (résidu `None`). Avec la valeur 99 du fichier, cette porte ne se déclenche presque jamais.

### 5.6 Quadrature `category_moments` et queue lourde

```
sd = √v ; si sd ≤ 0 → (0, m, v)
h = span/steps (steps = 52, span = 6,5) ; z_i = i·h pour i = −52 … 52 (105 points)
u_i = m + sd·z_i ; w_i = e^(−z_i²/2) ; σ_i² = noise_var(u_i)
L_i = mass(a, b, u_i, σ_i) ; avec queue lourde : L_i = (1 − g)·L_i + g·mass(a, b, u_i, √(σ_i² + gs²))
sw = Σ w_i ; s0 = Σ w_i L_i ; s1 = Σ w_i L_i z_i ; s2 = Σ w_i L_i z_i²     (sommes dans l'ordre de i)
si s0 < 1e-280·sw → interval_moments(m, v, noise_var(m), a, b)
mz = s1/s0 ; vz = max(1e-12 ; s2/s0 − mz²)
retour (ln(s0/sw), m + sd·mz, v·vz)
```

`(g, gs) = note_erreur_grossiere`.

**`mass(a, b, u, t)`** = P(a ≤ u + e ≤ b), avec e ~ N(0, t²) :

- `a = −∞` : 1 si `b = +∞`, sinon `½·erfc(−(b − u)/t/√2)` ;
- `b = +∞` : `½·erfc((a − u)/t/√2)` ;
- sinon `lo = (a − u)/t` et `hi = (b − u)/t` ; si `lo > 0`, `½·(erfc(lo/√2) − erfc(hi/√2))`, sinon `½·(erfc(−hi/√2) − erfc(−lo/√2))` ; résultat borné à ≥ 0.

Le code appelle ici `math.erfc` de la bibliothèque C, pas `numerique.erfc` (annexe A, § 9).

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
3. **Série sans note** : réserve vraie dans `[0 ; +∞)`, avec `s² = 0,35² + extra`.
4. **Note 10** : réserve perçue dans `(−∞ ; 0,25]`.
5. **Autre note** : intervalle du § 1.5 sur la réserve perçue.

Pour une note perçue, `s² = bruit_rir_de(clamp(v ; 0 ; 8), R)² + extra` ; ce `s²` sert au résidu et à la porte. Les séries d'une charge ≤ 0 sont ignorées.

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
| Réussie sans note | censure à droite : `u ∈ [0 ; +∞)`, `s² = bt² + extra_t` |
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

Ces observations portent sur la capacité à frais (`h_frais`), hors séance, et sur les exercices `charge` seulement.

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
2. Calcule le palier et le décalage du bilan (§ 8.1).
3. `coupure` = jours depuis la dernière séance fermée.
4. Vide les raisons et les plans.
5. Calcule les budgets de reprise par zone (§ 8.2).
6. Remet à zéro la mémoire de séance de chaque exercice.

### 6.2 `prescrire(items, grilles, zones, roles)`

Pour chaque item, dans l'ordre :

1. `zones_ex[id]` est mémorisé (sert aux doses par zone en fin de séance).
2. **`_item`**, dans cet ordre :
   1. **Conduite sous douleur** (`garde.conduite`, § 8.1), avec `depuis_jour` = jour de la dernière séance de l'exercice. Exercice retiré : `koach.douleur_retrait` et item supprimé.
   2. **Test un jour de bilan ≥ 1**, hors jour d'épreuve : `koach.test_reporte` et item supprimé.
   3. **Plan de l'emplacement** :
      - `sans_hausse` = conduite sans hausse, ou palier ≥ 1 ;
      - `rir_bonus` = conduite, + `bilan_rir_bonus` au palier 1, + 2 × `bilan_rir_bonus` au palier 2 ;
      - `rir_min` = conduite ; au palier 2, au moins `bilan_bas_rir_min` ;
      - `part_max` = conduite ;
      - `verrou` = semaine verrouillée (`intention or genre` ∈ SEMAINES_VERROUILLEES, ou `genre` ∈ {deload, test, intro}).
   4. **Séries**, pour un item de travail `charge`, `reps` ou `tenue` hors test :
      - facteur de la conduite : `max(1, floor(séries·f + 1e-9))` ;
      - si `coupure ≥ coupure_j` : `n = floor(séries·coupure_series + 0,5)`, appliqué si `1 ≤ n < séries`, avec `koach.reprise_coupure` ;
      - au palier 2, si l'item a des flammes : une série de moins, sans descendre sous 3 (rôle `main`) ou 2.
   5. **Budget de reprise** (hors échauffement) : pour chaque zone provoquée qui a un budget, les séries sont bornées par le reste (`koach.reprise_dose`). Zéro série : `koach.douleur_retrait` (cause `reprise_dose`) et item supprimé. Sinon le budget est débité.
   6. `sets` est posé ; `setTargets = None` pour un item de travail `charge`, `reps` ou `tenue`.
3. **Vrai test** (§ 6.4), si l'item est de travail et que l'exercice n'a pas encore été testé dans cette prescription.

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

1. **Calibrage.** Si `mesures = 0` et `σ(capacité) > 0,12` : plage, `loadKg = None`, flammes.
2. **Charge du modèle.**
   - `reps` = `repsHigh` si la plage est un point, sinon le milieu de la plage ;
   - prudence = `prudence_charge[1]` après plus de 3 séances, `prudence_charge[0]` sinon ;
   - `voulu = charge_pour(reps, rir, prudence) = exp(μ_jour − prudence·σ_jour − g(λ, k, (reps + rir)/garde)) − bw`, avec `bw = fraction·poids` et `garde` la garde courante.
3. **Séries allégées** (série de tête, index ≥ 1, tête connue) : `voulu = min(voulu, (tête + bw)·(1 − drop) − bw)`.
4. **Écart de planification.** Si `koachIntensite` est non nul hors verrou : `voulu = (voulu + bw)·(1 + clamp(écart, ±plafond_intensite)) − bw`.
5. **Part écrite** (`percentOfOneRm`, sauf séries allégées) :
   - `charge_de_part(part)` lit la part comme un **niveau d'effort**. Si part ≥ 1, la charge vaut `e^μ·part`. Sinon : `R` = inverse de g₀ en `−ln part` (Newton, 12 pas, R ∈ [1 ; 200]), puis la charge vaut `exp(μ − g(λ, k, R))`. μ est la capacité à frais (du jour si demandé) ;
   - le plafond vaut `charge_de_part(part) − bw` en semaine verrouillée, pour un débutant, ou si part ≥ `couloir_part_lourde` ; sinon `charge_de_part(part·(1 + couloir_haut_max)) − bw`.
6. **Plafond de la conduite** : `charge_de_part(part_max) − bw`.
7. **Simple d'entraînement** (`repsLow = repsHigh = 1`, hors test) : au plus `charge_de_part(simple_part_max ou simple_part_max_bilan_bas si palier ≥ 1, du jour) − bw`.
8. **Grille** : `charge = grille.proche(max(voulu, minimum))`.
9. **Test adaptatif** (index 0, ni `sans_hausse` ni verrou, au moins 1 séance). Parmi le cran du dessous et celui du dessus :
   - un candidat est admissible si `|reps_prevues(cand, 0) − reps − rir| ≤ ecart_rir_tolere` et `cand ≤ voulu + pas` ;
   - il remplace la charge si son information dépasse de plus de 2 % celle de la meilleure charge, dans l'ordre précédent puis suivant ;
   - l'information vaut `cov²/(var + s²)`, avec `cov = h_frais·P·c`, `var = cᵀPc` (c = jacobien perçu de la série) et `s² = bruit_rir_de(clamp(v ; 0 ; 8), R)²`.
10. **Bornes de hausse** (`_bornes_hausse`, index 0 seulement). La clé est `(slotId, repsHigh)` ; `fragile` = zone de conduite ou `koachFragile`.
    - **Schéma connu** `(charge, verrou)` :
      - si `sans_hausse` ou verrou (dernière séance ratée ou répétitions non atteintes) : au plus la charge de la dernière séance ;
      - sinon `h = hausse_par_niveau[niveau]` (× `hausse_fragile_facteur` si fragile ; × 2 hors rôles `main` et `secondary`) ; si `charge > (avant + bw)(1 + h) − bw`, `charge = max(plancher(haut), min(charge, suivant(avant)))`, ce qui laisse toujours un cran.
    - **Schéma nouveau** : borne = maximum, sur les barres réussies des `barre_recente_j` derniers jours, de :
      - `c` si `sans_hausse` ou fragile ;
      - sinon `max(plancher((c + bw)(1 + premiere_hausse)(1 + schema_change_part·clamp(r − repsHigh ; 0 ; schema_change_reps_max)) − bw) ; suivant(c))`.
11. **Après un échec dans la séance** (`baisse < 1`) : la charge ne dépasse pas `plancher((charge_item + bw)·baisse − bw)`.
12. **Index ≥ 1 avec `sans_hausse` ou un échec** : pas plus que la charge de la série précédente.
13. **D'une série à l'autre** (index ≥ 1, hors série de tête) :
    - au plus `(charge_item + bw)·1,05 − bw`, avec un cran permis : `max(plancher(haut), min(charge, suivant(charge_item)))` ;
    - au moins `proche((charge_item + bw)·0,85 − bw)`.
14. **Zone douloureuse ou en reprise, ou bilan bas** (`sans_hausse` ou raison de conduite) : au plus `charge_derniere`, la plus lourde charge du dernier passage de l'exercice.
15. Au moins le minimum de la grille. À l'index 0, la charge devient la tête.
16. **Série repère** (§ 6.4) :
    - `charge_r = plancher(max(min(charge_pour(repsHigh, rep, 0,5) ; (récente + bw)(1 + repere_hausse) − bw) ; minimum))`, au moins la charge de travail ;
    - « récente » = la plus lourde barre réussie de moins de 42 j, sinon la tête ;
    - retour `{repsLow, repsHigh + reps_ouvertes, loadKg: charge_r, flames: flammes_de_rir(rep), repere: True}`.

#### `_cible_reps`

1. Si `mesures = 0` : la plage écrite.
2. **Prévision.** `sûr = floor(prévu·e^(−σ/2) + 0,3)`, avec `prévu = e^μ_jour·garde − rir`.
3. **Plage étendue.** Si l'item est libre (ni verrou, ni `sans_hausse`, ni raison de conduite, ni échec), sans technique et sans élastique, et que `sûr > haut` : `haut = min(sûr, 2·haut, 30)`.
4. **Bas de plage.** Si `sûr < bas` : `bas = max(1, sûr)`.
5. **Verrous.**
   - Après `sans_hausse` ou un échec à la dernière séance : `haut ≤ max(reps_max, 1)`.
   - Zone récente : `haut ≤ max(floor(reps_max·(1 + h)), reps_max + 1)`.
   - Après un échec dans la séance : `haut ≤ reps de la série précédente`.
6. Si le bas dépasse le haut, `bas = haut`.
7. **Série repère** : `{bas, min(max(2·haut écrit, haut), 60), flammes du repère, repere}`.

#### `_cible_tenue`

1. Si `mesures = 0` : la plage écrite.
2. **Prévision.** `prévu = e^μ_jour·garde·max(0,15 ; 1 − hh·rir)` ; `sûr = floor(prévu·e^(−σ/2))`.
3. **Plafond.** `haut ≤ floor(tenue_part_max·e^(μ + σ))` si cette valeur est ≥ 1.
4. **Tendons.** Pour un schéma `figure_statique*` : `h = tenue_hausse_par_niveau[niveau]` ; si la conduite donne une hausse maximale, `h = min(h, hausse_quantite)`. Si un maximum est connu, `haut ≤ max(floor(sec_max·(1 + h)), sec_max + 1)` (`koach.tendon`).
5. **Verrous.** Après `sans_hausse` ou un échec : `haut ≤ sec_max`. Après un échec dans la séance : `haut ≤ sec` de la série précédente.
6. `haut` vaut au moins 1 ; `bas = min(lo, haut)`, puis `max(1, sûr)` si `sûr < bas`.
7. **Tenue repère**, sauf en bras tendus sans maximum connu : `secondsHigh` = haut si une borne de tendon s'applique, sinon `max(haut, min(2·hi, 180))`.

### 6.4 Séries repères et vrai test

**`_mesure_utile`** est vrai si toutes ces conditions tiennent :

- l'item a au moins une série ; ce n'est ni un test ni un échauffement ;
- ni verrou, ni `sans_hausse`, ni échec dans la séance, ni raison de conduite ;
- pas de `jours_avant_echeance ≤ 14` ; pas de `dayStress = light` ;
- la technique est absente, `standard`, `top_set_backoff` ou `isometric_hold` ;
- `1,6448536269514722·σ > intervalle_declenchement` ;
- dernière mesure il y a au moins `jours_min_entre_tests` jours ;
- pas un débutant avec moins de 3 séances.

**Série repère** : la dernière série de l'item (`index = sets − 1`) quand `_mesure_utile` est vrai. Réserve 2 pour un débutant, 1,5 sinon (constantes du code).

**Vrai test** (`_vrai_test`), si toutes ces conditions tiennent :

- rôle `main` ou `secondary`, type `charge`, au moins 2 séries ;
- piste vue au moins une fois ; `_mesure_utile` ;
- grille et `charge_max` connus ;
- `suivant(ref) + bw ≤ (ref + bw)·(1 + rampe_pas)` : la grille n'est pas trop grossière.

Il renvoie `(n, rir)` : `(test_reps_debutant, test_rir_debutant)` au niveau 0, `(test_reps_avance, test_rir_avance)` au niveau ≥ 2, `(test_reps, test_rir)` sinon.

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

1. **Index 0** : `charge_pour(n, rir + 2, 0,5)`, plafonné à `(récente + bw)(1 + repere_hausse) − bw` (barres de moins de `barre_recente_j` jours).
2. **Index ≥ 1, fin du test** : le test s'arrête (`None`) sans charge précédente, après un échec, sans note, avec moins de n répétitions, ou sur une note 10.
3. **Confirmation** : si la réserve dite ≤ rir + 0,75, la même barre est refaite pour confirmation ; arrêt après `rampe_confirmations` notes basses.
4. **Pas de montée** : premier pas de `rampe_pas_par_rir` dont `réserve ≥ seuil − rir + 1 − 1e-9`, sinon le dernier pas. `voulu = (dernière + bw)(1 + pas) − bw`, au plus `exp(μ + 2,5·max(σ, rampe_sd_min) − g(λ, k, n)) − bw`.
5. **Grille** : `charge = plancher(voulu)`.
6. **Probabilité** : si `P(réussir) < rampe_proba_min`, essai du plus petit pas ; arrêt s'il n'est pas faisable.
7. **Hausse minimale** : si la charge ne monte pas, `suivant(dernière)` à condition que ce cran soit ≤ `rampe_pas`, sinon arrêt.
8. Effort affiché : 2 en réserve. `repere: True`.

**Test xRM chargé** :

- charge = `proche(charge_pour(repsHigh, targetRir ou 1, 0,25))`, ou `startLoadKg` si `mesures = 0` ou s'il n'y a pas de grille ;
- avec `sans_hausse` : au plus `charge_derniere` ;
- à l'index ≥ 1 : au moins la charge précédente, ou la même après un échec.

**Test sans charge** (répétitions ou tenue maximale) : la plage écrite, flammes = max(8, flammes de `targetRir` ou de 0).

### 6.6 Retour de série et fin de séance

**`serie_faite`** met à jour :

- la mémoire de séance : charge, répétitions, secondes, échec, flammes ;
- le plan de l'emplacement : charge, flammes, répétitions et échec de la série ; sur un échec, `échecs += 1`, et hors test `baisse = 1 − echec_baisse`.

**`fermer(record)`** :

1. **Doses par zone.** Les séries faites (reps > 0 ou secondes > 0) sont regroupées par `(exerciseId, slotId)`. Chacune ajoute 1 à la dose de la semaine pour chaque zone provoquée (`zones_ex`).
2. **Mémoire par exercice.** Au premier groupe d'un exercice, la mémoire est remise à zéro. Puis :
   - `charge_derniere` = la plus lourde charge du groupe (échauffements compris) ;
   - maximums de charge, de répétitions et de secondes (hors échauffement) ;
   - `echec` = un échec hors cible 10 et hors rôles `attempt` et `test` ;
   - barres réussies `(jour, charge, reps)` ;
   - `schemas[(slot, repsHigh de la première série de travail sans rôle)] = (charge, raté ou repsHigh non atteint)`.
3. `derniere_seance = jour`.

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

Il y a ensuite onze sections d'objets plats : `a_priori`, `mesure`, `jour`, `fatigue`, `dynamique`, `test_adaptatif`, `planification`, `securite`, `adherence`, `rupture`, `controle_dual`.

- Les valeurs sont des nombres, des listes de nombres, des listes de couples ou des textes (`hypotheses_stimulus`).
- Une paire `[moyenne, sd]` décrit une composante d'état ; `sd = 0` la fige.
- `rupture`, `adherence` et `controle_dual` sont lues par `.get(clé, défaut)`. Les défauts (`DEFAUTS_RUPTURE`, `DEFAUTS_ADHERENCE`, `DEFAUTS_DUAL`, `DEFAUTS_PLAFONDS`) sont aujourd'hui **tous égaux** aux valeurs du fichier. Toutes les autres sections sont lues par indexation directe : une clé absente lève une erreur.

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
| bornes | celles de `rupture.BORNES` |
| positivité | toute clé numérique qui finit par `_sd` ou commence par `sigma`, `tau` ou `bruit` doit être > 0 |

**Application.** Fusion superficielle par section, dans l'ordre trié des clés. Le dictionnaire fusionné est ensuite assigné à :

- `koach.params`, `modele.p`, `seances.p` ;
- `garde.s` et `seances.s` (section `securite`) ;
- `appliquer_parametres(fusion)` de chaque extension qui l'expose : Surveillance (seuils), Adhérence.

**Ce qui n'est pas relu après un import :**

| Élément | Où il est figé |
| --- | --- |
| τ des compartiments | `modele.tau`, figé à la construction |
| hypothèses de dose et leurs poids | `modele.hypotheses`, `poids_hyp` |
| a priori déjà appliqués à l'état | état courant |
| configuration de la BOCPD | `Surveillance.bocpd` |
| copie `Planification.p` | pas de `appliquer_parametres` |
| paramètres de l'essai N-of-1 en cours | `EssaiN1` |
| `qualites` et `classes_reponse` | contrôle de type seul : elles peuvent être renommées |

Ces écarts sont détaillés dans l'annexe A.

### 7.4 Tableau de toutes les clés

Le tableau est généré depuis le JSON au moment de la rédaction. « Lu par » donne le module lecteur ; une clé « Non lue » n'est lue par aucun module du moteur.

| Section | Clé | Valeur | Unité | Rôle | Lu par |
| --- | --- | --- | --- | --- | --- |
| — | `schema` | 1 | — | Version du schéma ; un import doit porter la même valeur | rupture.valider_parametres |
| — | `version` | "1.0.0-ref.1" | — | Version des paramètres ; un import doit garder la même majeure | rupture.valider_parametres, dossier |
| — | `date` | "2026-10-09" | — | Date du fichier (texte) | validation (type seul) |
| — | `note` | (texte) | — | Commentaire libre (texte) | validation (type seul) |
| — | `qualites` | ["pousser", "tirer", "jambes", "tronc", "figures", "endurance_force", "explosivite", "aerobie", "anaerobie", "mobilite"] | — | Noms des 10 qualités latentes, dans l'ordre des indices 0 à 9 | aucun module (liste informative) |
| — | `classes_reponse` | ["charge", "reps", "tenue", "cardio", "wod"] | — | Noms des 5 classes de réponse (ordre des écarts EPS) | aucun module (liste informative ; `modele.CLASSES` fait foi) |
| a_priori | `theta_sd` | 0.2 | ln | Écart-type a priori de chaque qualité θ_q | modele |
| a_priori | `delta_sd` | 0.3 | ln | Écart-type a priori total de ln capacité d'un exercice chargé | modele.piste |
| a_priori | `delta_sd_declare` | 0.07 | ln | Bruit d'une capacité déclarée au profil (observation ponctuelle) | modele.piste |
| a_priori | `rho_moyenne_par_niveau` | [0.0095, 0.003, 0.0012, 0.0006] | ln/sem. | Réponse à l'entraînement ρ à dose de référence, par niveau 0 à 3 | modele |
| a_priori | `rho_sd_rel` | 0.6 | part | Écart-type de ρ rapporté à sa moyenne | modele |
| a_priori | `eps_classe_moyenne` | [0.0, 0.0029, 0.0029, 0.002, 0.001] | ln/sem. | Écart de réponse par classe (charge, reps, tenue, cardio, wod) au niveau intermédiaire, mis à l'échelle ρ_niveau/ρ_1 | modele |
| a_priori | `eps_classe_sd` | 0.003 | ln/sem. | Écart-type des écarts de classe (même mise à l'échelle) | modele |
| a_priori | `k_nerveux` | [0.0, 0.0] | [moy., sd] | Sensibilité KN au compartiment rapide, part systémique | modele |
| a_priori | `k_musculaire` | [0.0, 0.0] | [moy., sd] | Sensibilité KM au compartiment lent, part locale | modele |
| a_priori | `biais_rir_additif` | [0.0, 0.0] | [rép., rép.] | Biais personnel BA de la note (perçu = (vrai − BA)/(1 + BP)) | modele |
| a_priori | `courbe_echelle_exercice_sd` | 0.22 | ln | Écart-type de l'échelle de courbe propre à l'exercice (κ_e) | modele.piste |
| a_priori | `courbe_bas_du_corps` | -0.2 | ln | Moyenne a priori de κ_e pour un exercice du bas du corps (`bas`) | modele, seance, planification |
| a_priori | `fatigue_intra` | [0.85, 0.0] | [moy., sd] | Fatigue intra-séance FI (part des répétitions perdue par unité de régresseur) | modele |
| a_priori | `part_tenue` | [0.1, 0.0] | [moy., sd] | HH : part du maintien maximal par répétition en réserve | modele |
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
| a_priori | `courbe_echelle` | [0.1, 0.0] | [moy., sd] | KU : échelle ln de la courbe de l'utilisateur | modele, seance, planification |
| a_priori | `biais_rir_proportionnel` | [0.25, 0.15] | [moy., sd] | BP : biais proportionnel de la note | modele |
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
| mesure | `cardio_poids_qualite` | 1.25 | × | Poids de la demande d'une course de qualité (lu par le banc seulement) | banc/politique_koach |
| mesure | `wod_pente_rir` | 4.0 | rép./unité | Pente réserve perçue ↔ demande relative (wod) | modele._serie_endurance |
| mesure | `bruit_rir_endurance` | 0.8 | rép. | Bruit de la note d'endurance | modele._serie_endurance |
| mesure | `bruit_rir_reference` | 5.0 | rép. | Réserve à laquelle vaut le bruit du cahier | modele.bruit_rir_de |
| mesure | `dispersion_fatigue_intra` | 0.3 | — | Bruit ajouté ∝ régresseur de fatigue de séance | modele |
| mesure | `note_aberrante` | 0.05 | proba | Probabilité qu'une note ne dise rien (répartie sur 10 flammes) | modele |
| mesure | `porte_note_ouverte` | 99 | écarts-types | Note ouverte ignorée si la prévision dépasse la borne de ce nombre d'écarts-types | modele._serie_force |
| mesure | `note_erreur_grossiere` | [0.08, 2.0] | [proba, rép.] | Queue lourde : probabilité et écart-type ajouté | modele._observer |
| mesure | `noteur_entier_notes_min` | 20 | notes | Notes vues avant de conclure « noteur entier » | modele.noteur_entier |
| mesure | `noteur_entier_part_max` | 0.05 | part | Part maximale de demi-notes d'un noteur entier | modele.noteur_entier |
| jour | `sigma_seance` | 0.022 | ln | Écart-type de l'effet de jour de séance DS (sans bilan) | modele, planification |
| jour | `sigma_exercice` | 0.018 | ln | Écart-type de l'effet de jour d'exercice DE | modele, planification |
| jour | `bilan_par_point` | 0.012 | ln/point | Moyenne de DS par point de bilan général | modele.debut_seance |
| jour | `bilan_neutre` | 4 | point | Bilan général neutre | modele.debut_seance |
| jour | `sigma_seance_avec_bilan` | 0.018 | ln | Écart-type de DS quand le bilan général est donné | modele.debut_seance |
| jour | `mauvais_jour_proba` | 0.05 | proba | Poids a priori de la branche « mauvais jour » | modele.debut_seance |
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
| dynamique | `q_delta_jour_inactif` | 2e-05 | ln²/j | Bruit de processus quotidien de δ_e (tous les exercices) | modele.avancer, dual |
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
| securite | `hausse_par_niveau` | [0.1, 0.05, 0.05, 0.05] | part | Hausse de charge maximale à schéma égal, par niveau | securite.hausse_max |
| securite | `hausse_fragile_facteur` | 0.5 | × | Facteur de la hausse sur zone fragile | securite.hausse_max |
| securite | `douleur_seuil` | 3 | /10 | Seuil de douleur (zone active au-dessus) | securite |
| securite | `douleur_jours_actifs` | 14 | j | Durée d'activité d'un signalement | securite |
| securite | `douleur_forte_contrainte` | 4 | /10 | Retrait si sollicitation 1 et douleur ≥ | securite.conduite |
| securite | `douleur_moyenne_contrainte` | 5 | /10 | Retrait si sollicitation ≥ 0,5 et douleur ≥ | securite.conduite |
| securite | `douleur_allegement` | 4 | /10 | Séries réduites si douleur ≥ | securite.conduite |
| securite | `douleur_allegement_series` | 0.6 | × | Facteur des séries | securite.conduite |
| securite | `douleur_rir_bonus` | 1.0 | rép. | Réserve ajoutée sur zone douloureuse | securite.conduite |
| securite | `douleur_remplacant_part` | 0.7 | part 1RM | Non lue (pas de remplaçant dans Koach) | — |
| securite | `arret_persistance_min` | 3 | /10 | Signalement compté dans un épisode | securite |
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
| securite | `coupure_j` | 14 | j | Coupure qui réduit les séries | seance |
| securite | `coupure_series` | 0.8 | × | Facteur des séries après coupure | seance |
| securite | `tenue_hausse_par_niveau` | [0.2, 0.15, 0.1, 0.1] | part | Hausse maximale par tenue en bras tendus | seance._cible_tenue |
| securite | `tenue_part_max` | 0.75 | part | Plafond d'une tenue en part du maximum (prudent) | seance._cible_tenue |
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
| securite | `endurance_pic` | 0.1 | part | Non lue | — |
| securite | `endurance_pic_jours` | 30 | j | Non lue | — |
| securite | `endurance_pic_courses_min` | 3 | courses | Non lue | — |
| securite | `endurance_reprise` | [[7, 0.7], [14, 0.5]] | [[j, part]] | Non lue | — |
| securite | `endurance_mauvais_jour` | 0.7 | × | Non lue | — |
| securite | `wod_jours_durs` | 2 | j | Non lue | — |
| securite | `wod_echelle` | 0.75 | × | Non lue | — |
| securite | `plafond_hebdo_par_niveau` | [12, 20, 25, 30] | séries | Non lue (porté par le validateur injecté) | — |
| securite | `volume_hausse` | 0.2 | part | Non lue (validateur) | — |
| securite | `volume_hausse_series` | 2 | séries | Non lue (validateur) | — |
| securite | `volume_hausse_2sem` | 0.3 | part | Non lue (validateur) | — |
| securite | `volume_hausse_2sem_series` | 4 | séries | Non lue (validateur) | — |
| securite | `decharge_part` | 0.7 | part | Non lue (validateur) | — |
| securite | `decharge_max_semaines` | [12, 7, 6, 6] | sem. | Non lue (validateur) | — |
| securite | `affutage_baisse` | [0.3, 0.3, 0.4, 0.4] | part | Non lue (validateur) | — |
| securite | `seance_tolerance` | 1.15 | × | Non lue (validateur) | — |
| securite | `seance_tolerance_min` | 3.0 | min | Non lue (validateur) | — |
| securite | `couloir_haut_max` | 0.15 | part | Couloir au-dessus de la part écrite (< 85 %, hors débutant et verrou) | seance._cible_charge |
| securite | `couloir_part_lourde` | 0.85 | part | Part écrite au-dessus de laquelle la charge écrite plafonne | seance._cible_charge |
| securite | `schema_change_part` | 0.025 | part/rép. | Hausse permise par répétition de moins (schéma nouveau) | seance |
| securite | `schema_change_reps_max` | 4 | rép. | Répétitions comptées au plus | seance |
| securite | `barre_recente_j` | 42 | j | Fenêtre des barres réussies récentes | seance |
| securite | `premiere_hausse` | 0.1 | part | Hausse maximale sur la barre récente (schéma nouveau, ouverture) | seance |
| securite | `reprise_dose_depart` | 0.6 | × | Budget hebdo de séries par zone en reprise : part de l'habitude | seance._budget_reprise |
| securite | `reprise_dose_hausse` | 0.25 | part | Hausse du budget d'une semaine de charge à l'autre | seance._budget_reprise |
| securite | `tentative_recente_part` | 0.85 | part | Barre récente prise pour ouverture si ≥ cette part du max | seance._tentative |
| adherence | `a_priori_poids_sd` | 1.5 | — | Écart-type a priori des 16 poids probit | adherence |
| adherence | `biais_initial` | 1.0 | — | Moyenne a priori du poids de biais | adherence |
| adherence | `pas_min` | 0.5 | unité de la cible | Pas minimal entre paliers (défaut si non donné) | adherence.forme |
| adherence | `proba_cible` | 0.7 | proba | P(acceptation) visée par palier | adherence.forme |
| adherence | `refus_silence_j` | 0 | j | Non lue | — |
| adherence | `paliers_max` | 4 | — | Paliers maximaux vers une cible | adherence.forme |
| adherence | `ampleur_echelle` | 4.0 | pas | Ampleur divisée par ce nombre | adherence |
| adherence | `ampleur_borne` | 3.0 | — | Borne de la caractéristique d'ampleur | adherence |
| adherence | `refus_recents_j` | 14 | j | Fenêtre des refus récents | adherence |
| adherence | `refus_recents_echelle` | 5.0 | refus | Refus récents pour une caractéristique 1 | adherence |
| rupture | `hasard` | 0.02 | /séance | Hasard H de la BOCPD | rupture |
| rupture | `alerte` | 0.6 | proba | Seuil d'alerte de P(rupture) | rupture |
| rupture | `fenetre` | 3 | séances | Non lue (remplacée par fenetre_seances) | — |
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
| rupture | `residu_reps_reference` | 8.0 | rép. | R de conversion réserve → e1RM (g'(R)) | rupture._residu_e1rm (chemin de secours) |
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

### 7.5 Clés non lues, défauts absents du fichier

**Clés du JSON lues par aucun module de `koach/`** (recherche de la chaîne de clé dans le code) :

- `qualites`, `classes_reponse` ;
- `mesure.bruit_serie`, `mesure.bruit_echec`, `mesure.bruit_continu` ;
- `mesure.cardio_poids_qualite` (lu par le banc seulement) ;
- `fatigue.grille_tau_nerveux`, `fatigue.grille_tau_musculaire`, `fatigue.grille_tau_tendineux` ;
- `test_adaptatif.poids_information`, `test_adaptatif.test_reps_ouvertes` ;
- `planification.gain_affutage` ;
- `securite.douleur_remplacant_part`, `securite.endurance_pic`, `securite.endurance_pic_jours`, `securite.endurance_pic_courses_min`, `securite.endurance_reprise`, `securite.endurance_mauvais_jour`, `securite.wod_jours_durs`, `securite.wod_echelle`, `securite.plafond_hebdo_par_niveau`, `securite.volume_hausse`, `securite.volume_hausse_series`, `securite.volume_hausse_2sem`, `securite.volume_hausse_2sem_series`, `securite.decharge_part`, `securite.decharge_max_semaines`, `securite.affutage_baisse`, `securite.seance_tolerance`, `securite.seance_tolerance_min` ;
- `adherence.refus_silence_j` (présent dans `DEFAUTS_ADHERENCE` mais jamais lu) ;
- `rupture.fenetre` (présent dans `DEFAUTS_RUPTURE`, « lu pour mémoire », jamais lu).

**Clés lues par `.get` avec un défaut, absentes du JSON** : aucune. Toutes les clés des dictionnaires de défauts sont présentes dans le fichier, avec la même valeur. `dual._innovations` lit `dynamique.q_delta_jour_inactif` avec le défaut 0 ; la clé existe.

---

## 8. Garde-fous (contraintes dures)

`securite.py` ne propose rien : il borne. Les numéros A… renvoient à l'inventaire `km1-outils/notes/SECURITE_0_3_1.md` (règles de `kalis_adapt` 0.3.1) ; les numéros B… aux critères du banc.

### 8.1 Règles de 0.3.1 reprises

| Règle 0.3.1 | Dans Koach | Où |
| --- | --- | --- |
| A1.1 seuil 3/10, zone active 14 j, zone bloquante depuis la dernière séance de l'exercice | `active(z)` = dernière intensité si > `douleur_seuil` et ≤ `douleur_jours_actifs` jours ; bloquante si une intensité > seuil a été signalée entre `depuis_jour` et aujourd'hui (niveau ≥ 0,5) : sans hausse, +`douleur_rir_bonus` | `securite.active`, `conduite` |
| A1.2 pas de hausse, +1 RIR | `sans_hausse`, `rir` ; plafond « dernier passage » (`charge_derniere`) ; reps et tenues plafonnées par le maximum de la dernière séance | `conduite`, `seance` |
| A1.3 retrait (niveau 1 et ≥ 4, niveau ≥ 0,5 et ≥ 5) | `retire`, cause `douleur` | `conduite` |
| A1.4 allègement ≥ 4/10 : séries × 0,6 | `series = douleur_allegement_series` | `conduite` |
| A1.6 test retiré (zone du jour, ou > 2/10 dans les 7 jours) | `retire` si `est_test` | `conduite`, `signalee_semaine` |
| A2.1 arrêt : (a) ≥ 14 j, (b) ≥ 5 sur ≥ 7 j, (c) retour ≤ 84 j après un épisode réel, (d) ≥ 3 séances de suite > 3 | `_arrets` ; épisodes = signalements ≥ `arret_persistance_min` séparés de ≤ `arret_levee_j` ; épisode « réel » = ≥ 2 signalements ou un ≥ 4 ; levée quand le dernier signalement ≥ 3 date de ≥ 14 j (`arret_leve = dernier + 14`) | `securite._arrets` |
| A2.2 pendant l'arrêt : mouvements qui provoquent retirés ; ceux qui chargent la zone au premier palier (séries × 0,5, ≥ 3 RIR, sans hausse, ≤ 67,5 % du 1RM, pas de test) ; escalade après 14 j si gêne ≥ 3 dans les 7 j | idem (`part_max = reprise_charge_base`, lu comme niveau d'effort, § 6.3) | `conduite` |
| A3.1 et A3.2 reprise et arrêt gardé jusqu'à une semaine de charge | `arret(z)` vrai tant qu'aucune semaine de charge n'a commencé depuis la levée (une semaine compte si la levée lui laisse ≥ 4 jours) | `arret`, `_semaines_de_charge` |
| A3.3 paliers 0,5 + 0,1 par semaine de charge, plancher 0,4, recul si > 2/10 dans les 7 j ; charge ≤ 0,675 + 0,25·(part − 0,5) ; ≥ 3 RIR ; hausse de quantité ≤ 10 % ou +1 sur zone récente ; tests retirés | `reprise(z)`, `conduite`, `recente(z)` | `securite` |
| A5.1 lecture du bilan, paliers | `palier_bilan` : constantes 0,015, 4, 6 h, 0,01 par heure (≤ 3 h), 0,01 par réponse ≤ 2, part 0,5, plancher −0,08 **écrites dans le code** ; seuils `bilan_palier1/2` ; overall ≤ 1 → palier 2, ≤ 2 → palier 1 | `securite.palier_bilan` |
| A5.2 palier 1 : +0,5 RIR, pas de hausse, tests retirés ; palier 2 : +1 RIR, une série de moins (plancher 3 ou 2), ≥ 3 RIR, simple ≤ 85 % | `_item`, `_cible_charge` ; tentatives −2 % par palier | `seance` |
| A6.1 coupure ≥ 14 j : séries × 0,8 | `_item` | `seance` |
| A6.5 semaines verrouillées : pas de hausse au-delà de l'écrit, pas de série repère | `verrou` (charge écrite, pas de test adaptatif, pas de repère, pas d'écart de planification) | `seance`, `planification` |
| A7.2 bornes 10/5/5/5 %, ×0,5 si fragile, un cran toujours permis, couloir +15 % sous 85 %, schéma changé +2,5 %/rép. (4 au plus), premier passage +10 % sur la barre de 42 j, simple ≤ 92 % | `_bornes_hausse`, `_cible_charge` | `seance` |
| A7.4 conseil : −15 %/+5 % d'une série à l'autre, −7,5 % gardé après un échec, arrêt après 2 échecs | `_cible_charge`, `cible` | `seance` |
| A8.2 tentatives : ouverture ≤ 91 %·max et P ≥ 0,95, barre récente ≥ 85 % ; 2e P ≥ 0,8, 3e ≥ 0,5 ; sauts +5 %/+3 %, +5 kg ; jamais décroissantes ; −2 % par palier et sur douleur | `_tentative` (sans la bonification d'affûtage `coachTaperGain`) | `seance` |
| A8.3 séries repères : 14 j, 1,5 RIR (2 débutant), +6 rép. ouvertes, jamais en verrou, bilan bas, douleur ou échec | `_mesure_utile`, `_repere` | `seance` |
| A9.1 tendons : hausse par tenue 20/15/10/10 % ou +1 s ; tenues ≤ 75 % du maximum | `_cible_tenue` (par tenue seulement ; pas de borne sur le total de l'emplacement) | `seance` |
| A9.3 changement de cran : capacité × 0,75, +0,25 d'incertitude | événement `cran` (le facteur est fourni par l'appelant) | `modele` |

### 8.2 Règles propres à Koach, plus prudentes

- **Budget hebdomadaire de reprise par zone** (`_budget_reprise`), pour une zone levée depuis ≤ `reprise_surveillance_j` jours et qui n'est plus à l'arrêt :
  - habitude = moyenne des doses des semaines de charge parmi les 4 semaines qui précèdent le premier signalement ≥ 3 ;
  - première semaine de charge depuis la levée : `max(1, floor(reprise_dose_depart·habitude + 1e-9))` ;
  - ensuite : `max(précédente + 1 ; floor(précédente·(1 + reprise_dose_hausse) + 1e-9))` ;
  - moins les séries déjà faites cette semaine.
  Le budget s'applique à tous les mouvements qui provoquent la zone, quel que soit le volume écrit.
- **Jamais plus lourd que le dernier passage** de l'exercice (et non que la dernière séance de l'emplacement) sur zone douloureuse ou en reprise, ou un jour de bilan bas.
- **Ouverture des tentatives** bornée par les barres réussies des 42 derniers jours (+10 %, +2,5 % par répétition au-delà de la première, 4 au plus).
- **Montée du vrai test** : 1re barre ≤ +10 % sur la barre récente ; barre suivante seulement si P(réussite) ≥ 0,75 ; borne haute à μ + 2,5σ.
- **Série repère chargée** ≤ +10 % sur la barre récente.

### 8.3 Règles de 0.3.1 non reprises par Koach 1.0

Ces règles ne sont **pas** dans le code Python ; KM2 doit trancher (annexe B) :

| Règle | Contenu |
| --- | --- |
| A1.5 | remplaçant sous douleur ; Koach retire seulement, `douleur_remplacant_part` n'est pas lu |
| A1.7 | proposition « épargner la zone » |
| A2.3 | course retirée pendant un arrêt du bas du corps |
| A4.1 à A4.3 | poignet : appui neutre, arrêt du poignet, dose plafonnée |
| A6.2 | alerte de surmenage |
| A6.3 | décharge anticipée de la revue |
| A6.4 | récupération réduite |
| A6.5 | échéance ≤ 14 j : seule la série repère est bloquée, par `jours_avant_echeance` |
| A7.3 | règles sans charge au complet : couloir, `coachDirectGuardRir` |
| A7.2 | double progression « 2 pour 2 », simple ≤ 92 % du 1RM **du jour** (Koach : part lue comme niveau d'effort), exercice nouveau à 60 % |
| A8.1 | report d'un test à 48 h |
| A8.2 | bonification d'affûtage |
| A9.1 | borne du temps total de l'emplacement |
| A9.2 | techniques réservées au niveau |
| A9.4 | séries fractionnées |
| A9.5 | étapes de figures |
| A10.1 à A10.5 | endurance : reprise 70/50 %, jour sans, +10 % sur 30 j, wod 75 %, fatigue croisée ; les clés `endurance_*` et `wod_*` existent mais ne sont pas lues |
| A11 | propositions de volume de la revue |
| A13 | règles de génération de `kalis_plan` (mode prudent, impact, IMC, première semaine, feu vert médical) ; elles restent dans le plan de référence, que Koach ne restructure pas |

### 8.4 Plafonds de la planification

- **Volume par qualité.** Facteur ∈ [1 − 0,15 ; 1 + 0,15] par bloc. Il est vérifié sur les séries entières de chaque semaine par rapport à la référence (`items_modules`) ; l'arrondi par diffusion d'erreur est corrigé jusqu'à respecter le plafond.
- **Intensité.** Écart ∈ [−0,05 ; 0,05] par bloc, appliqué à la charge totale du modèle (`koachIntensite`), et de nouveau borné dans la séance.
- **Semaines verrouillées.** Volume ≤ 1 et intensité ≤ 0.
- **Tendons.** Pénalité 1 par semaine où le rapport charge tendineuse / moyenne des 4 semaines dépasse `max(1,3 ; rapport de la référence)`, si la référence est ≥ 4.
- **Validateur injecté.** `validateur(blocs) → [constats {code, week, dayIndex, exerciseId}]`. Un plan qui ajoute un constat est divisé par 2, au plus 3 fois, puis abandonné. Sur le banc, le validateur est `securite_banc.constats_saison`, portage des critères B1 à B14 de `kalis_bench` vérifié contre le Dart. **Dans l'application, KM2 devra fournir un validateur équivalent ; sans validateur, `_sur` est toujours vrai.**
- **Contrôle dual.** `facteur_borne` garde le produit plan × essai dans les plafonds, mais n'est appelé nulle part (annexe A).

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
| `'koach-plan:%d:%d' % (planification.graine, semaine)` | jumeau numérique |
| `'koach-cem:%d:%d' % (planification.graine, semaine)` | entropie croisée |
| `'koach-dual-essai:%d:%d' % (graine, semaine)` | séquence ABBA/BAAB |
| `'koach-dual:%d:%d' % (graine, semaine)` | tirage de Thompson |
| `'koach-adherence-poids:' + clé` et `'koach-adherence-decisions:' + clé` | banc seulement, utilisateur simulé (clé = `saison:scenario:graine`) |

### 9.2 Ordres qui comptent

- **Pistes** : ordre de création (`ordre`). Il fixe les indices d'état, l'ordre des mises à jour en fin de semaine et l'ordre de `posterior`.
- **Fonctionnelles** : qualités dans l'ordre 0 à 9 (seulement `v_q ≠ 0`), puis δ_e, puis DS, DE, KN, KL, KG, KM ; ensuite λ, KU, κ_e, φ_e, BA, BP.
- **Sommes** : `_stats`, `_intra`, quadrature, moyennes de résidus.
- **Dictionnaires** : l'ordre d'insertion compte (`zones` de la conduite, `zones` de `garde`, `memoire`). Dart `LinkedHashMap` garde le même ordre si les insertions sont identiques.
- **Ensembles Python** (`hits`, zones provoquées) : l'itération dépend du hachage (`PYTHONHASHSEED`). L'ordre des raisons `koach.reprise_dose` peut varier d'une exécution à l'autre ; le résultat numérique ne change pas (annexe A).
- **Tris** :
  - CEM : clé `(−valeur, indice)` ;
  - constats : tri de tuples `(code, week, dayIndex, exerciseId)` ;
  - extensions : clés triées (`sorted`) ;
  - projection sur le simplexe : tri par insertion stable.
- **Extensions** : ordre de la liste ; sur le banc, `surveillance`, `dual`, `adherence`.

### 9.3 Fonctions à porter ligne pour ligne

- **`erfc`.** Si `|x| < 2` : série de 80 termes, `term ← term·2z²/(2n + 1)`, puis `erf = 2/√π·e^(−z²)·Σ` et `erfc = 1 − erf`. Sinon : fraction continue de Laplace sur 200 étages, évaluée à rebours, `f = (k/2)/(z + f)`, puis `e^(−z²)/√π/(z + f)`. Symétrie : `2 − erfc(|x|)` pour `x < 0`.
- **`norm_cdf(a)`** = `½·erfc(−a/√2)` ; **`norm_sf(a)`** = `½·erfc(a/√2)`.
- **`norm_ppf`** : Acklam (coefficients du code, seuil 0,02425), puis un pas de Halley avec `norm_cdf`.
- **`interval_moments`**, **`category_moments`** (52 pas, 6,5 écarts-types), **`point_moments`** : § 5.6 et 5.12.
- **`dart_round`** (arrondi demi vers le haut, symétrique) existe dans `numerique`, mais le moteur ne l'utilise pas.
- **Arrondis** : le moteur emploie `math.floor(x + 0,5)` (arrondis de séries) et `math.ceil`. Les arrondis de Python (`round`, arrondi bancaire) n'apparaissent que dans `elite_n = round(pop·elite)` et dans les sorties `blocs_modules` et `historique`.
- **`lgamma`** (Lanczos), **`projection_simplexe`**, **`borne_lambda_max`**, **FISTA** : boucles fixes.

### 9.4 numpy : ce que le Dart doit reproduire, et les risques pour 1e-9

| Point | Code | Risque | Proposition |
| --- | --- | --- | --- |
| **Décomposition propre** | `Planification.tirer` (`planification.py:294`, `numpy.linalg.eigh`, LAPACK) | **Élevé.** Signes des vecteurs propres, ordre et base dans un sous-espace dégénéré non uniques. `L` change, donc les trajectoires changent pour les mêmes `z`. Une parité à 1e-9 est irréaliste sans réécriture. | Remplacer par une factorisation déterministe portable (Cholesky avec pivot ou jitter, ou Jacobi à balayages fixes) écrite en boucles dans les deux langages. Décision KM1/KM2. |
| Produits matriciels BLAS | `H @ P @ H.T`, `z @ L.T`, `a @ V.T`, `charge_jour @ decro`, `a @ tq`, `h @ m` (`tirer`, `evaluer`) | Moyen : ordre d'accumulation et FMA propres à BLAS. Écarts de l'ordre de 1e-16 relatif, amplifiés par les seuils (`jour ≥ seuil`, tri CEM). | Boucles explicites dans un ordre fixé, des deux côtés. |
| `np.einsum('cdq,cq->cd')` | `evaluer` | Moyen : ordre interne. | Idem. |
| Réductions `.sum()`, `.mean()` sur le dernier axe (≥ 8 éléments) | `evaluer` (transport par qualité, `syst[2].sum()`, `mr.sum()`, `prog.mean(axis=(1,2))`, `ok.mean`) | Faible à moyen : numpy fait une sommation par paires (8 accumulateurs, blocs de 128). Les moyennes de booléens sont exactes. | Reproduire la sommation par paires de numpy ou passer à des boucles dans les deux. |
| `elite.mean(axis=0)`, `elite.std(axis=0)` | `replanifier` | Faible : réduction sur l'axe 0, séquentielle. `std` = racine de la moyenne des carrés des écarts (ddof 0). | Porter tel quel. |
| Seuils et comparaisons | `jour ≥ seuil`, `cw/moy_c > limite + 1e-9`, tri `(−v, a)`, `vx ≤ v_ref + gain_min` | Tout écart en amont peut faire basculer une comparaison : le plan retenu change et l'écart dépasse alors 1e-9. | Fixtures de parité sur `evaluer` (valeurs) **avant** la parité sur le choix. |
| Mises à jour de rang 1 | `np.outer`, `P -= …`, fusion des branches, croissance ligne puis colonne | Faible : opérations élément par élément. | Porter tel quel (ligne puis colonne pour la croissance). |
| `math.erfc` de libm | `numerique._category_mass` | Moyen : Dart n'a pas d'erfc ; une implémentation différente donne ≈ 1e-16 relatif, mais la quadrature et les seuils (`s0 < 1e-280·sw`) l'exposent. | Faire appeler `numerique.erfc` par la référence Python (changement de code KM1) puis régénérer les fixtures. |
| `exp`, `log`, `sqrt`, `sin`, `pow` | partout | Faible : `sqrt` est correctement arrondi ; `exp`, `log`, `pow` dépendent de la libm (Dart VM et CPython utilisent en général la libm de la plateforme). `intra_report ** k` est un `pow` à exposant entier : en Dart, utiliser `math.pow` (et non une boucle de multiplications) pour garder la même valeur. | Fixtures exécutées sur la même plateforme (CI Linux). |
| Format des traces | `'%.1f' % x` dans `trace` | Sans effet : hors contrat. | — |

### 9.5 Rejeu depuis le journal : conditions

`rejouer` redonne le même état **seulement si** les appels hors journal sont rejoués à l'identique, aux mêmes moments :

1. **`plan(...)` change l'état.** `plan(seance)` et `plan(serie)` créent des pistes : l'observation déclarée est appliquée à la création, et l'ordre de création fixe les indices. Elles remplissent aussi `zones_ex` (doses par zone en fin de séance, donc budgets de reprise), les plans d'emplacement (lus par `serie_faite`) et les débits de budget.
2. **La planification** n'est pas journalisée : `charger_reference`, les cibles, l'échéance, `replanifier(0)` à la construction et les changements de profil sur le banc.
3. **`importer_parametres`** n'est pas journalisé.
4. **L'allègement et la modulation des items** sont appliqués par l'appelant (`appliquer_allegement`, `Planification.appliquer`).

Le banc vérifie le rejeu des **extensions** (`banc/extensions_koach.rejouer_etats`). Le contrat recommande à KM2 de journaliser les entrées de `plan` (contraintes) et les imports, ou de rendre la création de pistes indépendante de `plan` (annexe B).

### 9.6 Fixtures

Le répertoire `reference/fixtures/` est **vide** à la date de ce contrat. Les fixtures à produire au lot KM1 (livrable « fixtures JSON de parité ») :

| Domaine | Contenu |
| --- | --- |
| Fonctions numériques | grilles d'entrées et sorties de `erfc`, `norm_ppf`, `interval_moments`, `category_moments`, `point_moments`, `lgamma`, mulberry32 (10⁴ tirages), fnv1a32 (chaînes du § 9.1) |
| Journal complet | un journal par profil type, avec `posterior()` après chaque événement et la sortie de chaque `plan` |
| Planification | `evaluer` sur une matrice X fixée ; tirage du jumeau (après la décision sur `eigh`) |
| Extensions | états de la BOCPD, de l'adhérence et du contrôle dual après rejeu |

---

## 10. Limites connues et hors périmètre de 1.0

1. **Structure.** La structure du plan n'est jamais modifiée : exercices, jours, schémas, ordre. Le cahier (Méthodes § 5) prévoit des changements de structure aux frontières de bloc ; rien n'est écrit pour cela.
2. **Planification.** Elle ne module que le volume, par qualité et par bloc, et l'intensité, par bloc, à l'intérieur des plafonds. Il n'y a ni récapitulatif de fin de bloc, ni replanification sur « moins de temps » (seule l'action codée existe), ni arrêt d'urgence.
3. **Objectif sous contrainte de risque.** Le risque n'est représenté que par la pénalité tendineuse et le validateur ; aucune probabilité de blessure n'est estimée.
4. **Thompson sampling.** Il n'est pas branché dans la planification. Le jumeau tire une hypothèse par trajectoire selon les poids a posteriori, ce qui intègre l'incertitude mais n'est pas un tirage de Thompson. `hypothese_pour_la_semaine`, `ControleDual.modulation` et `facteur_borne` ne sont pas appelés par le moteur ; les bras N-of-1 sont appliqués par le banc (`ControleDualBanc`).
5. **Mobilité.** Pas de modèle 2PL ; les exercices `mobilite` et `autre` (distance, calories, portés) ne sont pas suivis.
6. **Wod.** Pas de modèle continu log-normal : effort perçu et demande relative seulement (cahier, Méthodes § 2).
7. **Compartiment tendineux.** Calculé mais sans effet sur les décisions de séance.
8. **Fatigue nerveuse systémique et musculaire locale.** Figées à 0 (régression du banc) : seules les parts locale rapide et systémique lente agissent.
9. **Garde-fous non repris** (§ 8.3), en particulier l'endurance (A10), le poignet (A4) et les remplaçants (A1.5).
10. **Paramètres.** Ils ne sont pas réestimés par utilisateur dans un fichier : seul l'état du filtre l'est. Le cahier dit « réestimé pour chaque utilisateur et stocké dans le fichier de paramètres ».
11. **Rejeu.** Voir § 9.5.
12. **Hors périmètre, reporté par le cahier** : VBT, a priori collectif.

---

## Annexe A. Écarts relevés (code, commentaires, cahier)

Chaque entrée donne le fichier et la ligne, puis le constat.

### A.1 Code mort, clés et champs inutilisés

| # | Fichier:ligne | Constat |
| --- | --- | --- |
| 1 | `koach/modele.py:916-925` | `_apercu` n'est appelé nulle part ; sa variable `const` n'est pas utilisée. |
| 2 | `koach/modele.py:366-372` | `f_nerveux` renvoie le compartiment systémique rapide ; `f_musculaire` renvoie le **tableau local lent** (17 valeurs) et non un nombre : nom trompeur. Utilisés seulement par les outils de diagnostic. |
| 3 | `koach/modele.py:84-85, 899-902` | `Piste.cran` jamais écrit ; `Piste.meilleur`, `Piste.premier_jour` écrits mais jamais lus par le moteur. |
| 4 | `koach/modele.py:221` | `declare = False` puis passé au constructeur : variable inutile. |
| 5 | `koach/modele.py:136, 353, 1200` | `f_tendon_aigu` tenu mais jamais lu ; `f_tendon` seulement exposé (`moteur.py:101`). Le compartiment tendineux du cahier (Méthodes § 4) n'agit sur rien. |
| 6 | `koach/securite.py:12, 14` | `ZONES_BAS` et `SEMAINES_DE_CHARGE` jamais utilisés. |
| 7 | `koach/securite.py:49, 51-52` | `fragiles`, `dernier_jour_seance`, `avant_dernier_jour_seance` jamais lus : `profil.zones_fragiles` n'a aucun effet. La hausse « fragile » de 0.3.1 (A7.2, zone fragile du **profil**) n'est appliquée que via `koachFragile` ou une zone de conduite (`seance.py:680`). |
| 8 | `koach/seance.py:256` | `Seances.decalage` (décalage du bilan) est calculé (`seance.py:256`) mais jamais utilisé : la capacité prévue n'est pas baissée du décalage comme en 0.3.1 (A5.2) ; le bilan agit via l'a priori de DS. |
| 9 | `koach/seance.py:84-87, 98-110` | Champs de `Memoire` jamais lus : `cran_jour`, `haut_de_plage`, `facile`, `bas_manque`, `meilleur_sec`, `sec_total`, `total_seance`, `faciles_seance`, `flammes_seance`, `jours`. |
| 10 | `koach/seance.py:127-128` | `courses` et `jours_durs` jamais remplis ni lus (règles d'endurance A10 absentes). |
| 11 | `koach/seance.py:510` | `plan.get('vrai_test')` : clé jamais posée (le code pose `apres_test`, `seance.py:359`, jamais lue). Le test est donc sans effet ; la série repère peut suivre un vrai test du même jour, sauf via `dernier_test_jour`. |
| 12 | `koach/seance.py:439` ; `moteur.py:121` | Paramètre `faites` de `cible` non lu. |
| 13 | `koach/dual.py:72-79` | `facteur_borne` n'est appelé nulle part. |
| 14 | `koach/dual.py:935-955` | `hypothese_pour_la_semaine` et `modulation` ne sont pas appelés par le moteur ni par la planification. |
| 15 | `koach/numerique.py:225-226` | `dart_round` inutilisé. |
| 16 | `qualites/regles.py:85, 92` | Entrées `compression` et `transition_muscle_up` de `SCHEMA` jamais lues (remplacées par `parts_fixes`, `regles.py:124-133`) ; leurs valeurs diffèrent de celles réellement utilisées. |
| 17 | `params/koach_params_v1.json` | 32 clés non lues (§ 7.5). |
| 18 | `koach/rupture.py:31` | `fenetre` 3 « lu pour mémoire » : jamais lu. |
| 19 | `koach/adherence.py:33` | `refus_silence_j` jamais lu. |

### A.2 Commentaires et docstrings qui contredisent le code

| # | Fichier:ligne | Constat |
| --- | --- | --- |
| 20 | `koach/modele.py:8-11` | La docstring annonce une « réussite binaire (2PL en ogive normale) » : aucun modèle binaire n'existe ; la mobilité n'est pas suivie. |
| 21 | `koach/modele.py:685-688` | La docstring de `observer_serie` cite les champs `manual`, `parts`, `assistKg` : non lus. |
| 22 | `koach/moteur.py:35-37` | La docstring d'`observe` cite le type `profil` (non traité) et omet `charge_manuelle` (traité, `moteur.py:75-76`). |
| 23 | `koach/modele.py:45-46` | « C_LIN : Epley, Brzycki » : Brzycki donne ≈ 0,028 à 0,032 ln/rép. entre 2 et 10 rép. et Epley ≈ 0,028 (calcul) ; 0,0265 est plus plat. L'écart est compensé par `courbe_echelle` = 0,10 (e^0,1·0,0265 = 0,0293). C_LOG·e^0,1 = 0,0986 ≈ Lombardi (0,10). |
| 24 | `koach/rupture.py:33-34` ; `koach/adherence.py:34` ; `koach/dual.py:50` | « Clés nouvelles (absentes de koach_params_v1.json) » : elles y sont toutes à présent. |
| 25 | `koach/rupture.py:34, 144` | Renvoi à « LIVRAISON » pour justifier des défauts : `LIVRAISON_KM1.md` n'existe pas encore. |
| 26 | `koach/securite.py:8-9` | « Les valeurs viennent de `params['securite']`, égales à celles de `AdaptParams.standard` » : `palier_bilan` (`securite.py:227-239`) code en dur 0,015, 4, 6, 0,01, 3, 0,5, −0,08 ; `_arrets` code en dur l'épisode « réel » ≥ 4 (`:143`) ; `_semaines_de_charge` code en dur ≥ 4 jours (`:68`). Les valeurs sont égales à 0.3.1, mais ne viennent pas du fichier. |
| 27 | `koach/seance.py:514` | Série repère à 1,5 RIR (2 débutant) en dur, alors que la section `test_adaptatif` a des clés de réserve (de sens différent) ; aucune clé `benchmarkRir`. |
| 28 | SAUVEGARDE 09/10 ~19:00 point 4 (« BP 0,25 figé ») | Le fichier donne `biais_rir_proportionnel` = [0,25 ; 0,15] : BP est **appris**, pas figé. |

### A.3 Comportements à signaler

| # | Fichier:ligne | Constat |
| --- | --- | --- |
| 29 | `koach/seance.py:415` | `koach.douleur_retrait` (cause `reprise_dose`) porte `zone = cond['zone']` (souvent `None`) au lieu de la zone dont le budget est épuisé. |
| 30 | `koach/seance.py:408-419` | `for z in hits` itère sur un **ensemble** : l'ordre des raisons `koach.reprise_dose` dépend du hachage (non déterministe d'une exécution Python à l'autre). |
| 31 | `koach/seance.py:651, 760, 800, 815` | `cible` ré-émet la même raison à chaque appel : doublons dans `explain()`. |
| 32 | `koach/modele.py:1118-1124` | `_observer_hors` pendant une séance ouverte (refus motivé, charge manuelle) ne met à jour que la branche principale ; la fusion de fin de séance mélange ensuite une branche qui n'a pas vu l'observation. |
| 33 | `koach/modele.py:331-333` | `avancer` ajoute `q_delta_jour_inactif` à **toutes** les pistes (le nom dit « inactif »), et seulement sur la branche principale. |
| 34 | `koach/modele.py:854` | `porte_note_ouverte = 99` : la porte ne se déclenche pratiquement jamais ; le commentaire (`:855-858`) décrit un garde-fou contre l'aplatissement de la courbe qui est donc inactif. |
| 35 | `koach/modele.py:873, 1020` | Le bruit de la note dépend de `R` = répétitions **possibles** et non des répétitions faites (seuil « longue série » de 12) ; pour une tenue, `R` = 6 en dur. |
| 36 | `koach/numerique.py:129-137` | `_category_mass` appelle `math.erfc` (libm) au lieu de `numerique.erfc`, alors que le module annonce des fonctions portées ligne pour ligne (`:2-4`). |
| 37 | `koach/planification.py:294` | `numpy.linalg.eigh` : non portable à 1e-9 (§ 9.4). |
| 38 | `koach/planification.py:601` | Comptage `plans = evalues + 2 + len(essais)` ; les appels réels à `evaluer` sont pop × itérations (256) + 1 (échelle, sans échéance) + 1 (référence) + 1 par essai (jusqu'à 9) + 1 par essai validé + 1 (détail final), sans compter les appels au validateur. Le cahier dit « 256 plans évalués au plus » (Méthodes § 5) : le budget est dépassé de quelques évaluations. |
| 39 | `koach/planification.py:397-399` | Une semaine non écrite fait décroître la fatigue lente de `e^(−1)`, soit 1 jour au lieu de 7 (`e^(−7/τ)`). |
| 40 | `koach/planification.py:91` ; `koach/rupture.py:750-758` | Après `importer_parametres`, `Planification.p` (copie), `modele.tau`, les hypothèses, la BOCPD et l'essai en cours gardent les anciennes valeurs. |
| 41 | `koach/rupture.py:833-856` | L'import admet un renommage des `qualites` et `classes_reponse` (contrôle de type seul), alors que la liste est « figée » (cahier, Méthodes § 2). |
| 42 | `koach/dual.py:354` | `peut_demarrer` estime la durée par défaut avec `DEFAUTS_DUAL['n_bras']` et non le paramètre `n_bras`. |
| 43 | `koach/seance.py:492` | `jours_avant_echeance` n'est fourni par aucun appelant (le banc passe `jour_evenement`) : le blocage des séries repères à l'approche de l'échéance (A6.5) est inactif sur le banc. |
| 44 | `koach/seance.py:658` | Fenêtre de 42 jours en dur pour la série repère, alors que `barre_recente_j` (42) existe et sert ailleurs. |
| 45 | `koach/seance.py:631-637` | ±15 %/+5 % entre séries, `0,35` (P cible), `0,2`, `0,12` (calibrage), `2,5` (borne de montée), `0,08` (drop par défaut) sont codés en dur, hors fichier de paramètres. |
| 46 | `banc/politique_koach.py:171` | Le facteur de cran (0,75) est fourni par le banc, pas par le fichier de paramètres. |

### A.4 Écarts par rapport au cahier

| # | Cahier | Code |
| --- | --- | --- |
| 47 | Méthodes § 3 : « Biais initial 0 » | Biais additif 0, mais biais proportionnel de population 0,25 ± 0,15 (`a_priori.biais_rir_proportionnel`). |
| 48 | Méthodes § 3 : bruit 2,0 / 1,5 / 1,0 | Interprété comme le bruit **à 5 RIR** ; il vaut ≈ 29 % de cette valeur à l'échec et croît au-delà de 12 répétitions possibles. |
| 49 | Méthodes § 2 : WOD continu log-normal, mobilité 2PL | Absents (§ 10). |
| 50 | Méthodes § 4 : trois compartiments | Le compartiment tendineux n'agit pas ; la part systémique du rapide et la part locale du lent sont figées à 0. |
| 51 | Méthodes § 5 : structure modifiable aux frontières de bloc | Jamais modifiée. |
| 52 | Méthodes § 6 : « λ calibré sur le banc » | λ = 0,5, aucun calage documenté. |
| 53 | Méthodes § 7 : Thompson sampling | Non branché dans la planification (n° 14). |
| 54 | Méthodes § 9 : « Moins de temps → replanification avec les nouvelles disponibilités » | Action codée seulement. |
| 55 | Méthodes § 9 : secours « résidu d'e1RM > 5 % deux semaines » | Implémenté ; SAUVEGARDE note qu'il était actif 39 % des semaines (version antérieure du résidu) ; `banc/validation_koach.py` mesure une variante à 20 % (`RESIDU_PROPOSE`) : décision à écrire. |
| 56 | Contraintes : règles de sécurité de 0.3.1 « conduite sous douleur, poignet, tendons, plafond de volume de la 1re semaine, feu vert médical » | Poignet, endurance, remplaçants et règles de génération non repris (§ 8.3) ; le plafond de 1re semaine et le feu vert médical restent dans le plan de référence (`kalis_plan`), que Koach ne restructure pas. |
| 57 | Méthodes, en-tête : « Chaque valeur … réestimé pour chaque utilisateur et stocké dans le fichier de paramètres » | Non fait (§ 10). |
| 58 | Contraintes : « L'état se recalcule depuis le journal » | Sous conditions (§ 9.5). |

## Annexe B. Points à décider avant KM2

1. Remplacer `eigh` par une factorisation portable dans `Planification.tirer` (§ 9.4), et faire appeler `numerique.erfc` par `_category_mass`.
2. Journaliser les entrées de `plan` et les imports, ou rendre la création de pistes indépendante de `plan` (§ 9.5).
3. Reprendre ou écarter explicitement les règles de 0.3.1 non reprises (§ 8.3), en particulier A10 (endurance) et A4 (poignet), dont les clés existent déjà.
4. Décider du sort des 32 clés non lues : supprimer, ou brancher.
5. Appliquer `profil.zones_fragiles` (hausse ×0,5 de A7.2) ou retirer le champ.
6. Fixer `porte_note_ouverte` à une valeur active (par exemple 2 ou 3) ou retirer la porte.
7. Calibrer λ du transport sur le banc (cahier § 6).
8. Seuil de secours « résidu d'e1RM » (5 % du cahier ou 20 % mesuré).
9. Compter le budget de 256 plans de façon stricte, ou corriger le cahier.
10. Produire les fixtures de parité (§ 9.6).
