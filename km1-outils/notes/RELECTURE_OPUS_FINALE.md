# Relecture finale de Koach 1.0 (référence Python), avant livraison

10/10/2026 · relecteur indépendant (Opus 5.5) · `moteurs/packages/kalis_adapt/reference/`, en lecture seule. Je n'ai lancé ni simulation ni pytest. Scripts de lecture : `/tmp/relecture2/cles.py`, `cles2.py`, `valeurs.py`, `agregats.py`.
Les chemins sont relatifs à `packages/kalis_adapt/reference/`. Chaque statut ci-dessous a été vérifié dans le code actuel, sans m'appuyer sur le journal des corrections.

Bilan des constats nouveaux : **0 bloquant, 3 majeurs, 9 mineurs**.

---

## 1. Constats de la première relecture : statut dans le code actuel

| N° | Statut | Preuve (fichier, fonction) |
| --- | --- | --- |
| B1 | **Corrigé**, avec un reste déclaré | `params/koach_params_v1.json` : `mesure.porte_note_ouverte` = 1.0 ; `koach/modele.py` `_serie_force` (l. 889) : `pred >= a + porte·√s²` → la série n'est pas versée. Reste déclaré à l'annexe A.2 : dérive de +4 à +7 % sur un plateau, porte importable jusqu'à 100. |
| B2 | **Corrigé** pour le vrai test et la série repère | `koach/seance.py` `_mesure_utile` : `if self.coupure > 0: return False`, puis `retour_seances_avant_mesure` ; `_vrai_test` et `_rampe` (index 0) renvoient `None` sans barre réussie depuis `barre_recente_j`. Une voie reste ouverte par l'échelle des tentatives (voir N1). |
| B3 | **Corrigé en partie**, reste déclaré | JSON : `biais_rir_proportionnel` = [0.25, 0.15], donc BP est appris ; `biais_rir_additif` = [0, 0], donc BA reste figé. Écart déclaré à l'annexe A.1, n° 2. |
| B4 | **Corrigé**, avec un reste mineur | `koach/securite.py` `_zones_fragiles`, `fragile`, `conduite` (`'fragile'`), poignet (l. 290) ; `seance._bornes_hausse` (`profil = plan['fragile']`, hausse × 0,5) ; `_cible_charge` (`surcharge_fragile_max`). Reste : le plancher « RIR ≥ 1 sur zone fragile » (critère `contre_indication`) n'est pas repris (m6). |
| M1 | **Corrigé en partie**, reste déclaré | `koach/planification.py` `__init__` : `ValueError` si `validateur is None` sans `options['sans_validateur']`. `volume_hausse*`, `decharge_part` et `seance_tolerance*` sont maintenant lus dans `seance.py` (`_limite_volume`, `_budgets_retour`, `_duree_bornee`). `plafond_hebdo_par_niveau`, `decharge_max_semaines` et `affutage_baisse` ne sont lus nulle part (validateur seul ; déclaré A.1 n° 17 et A.4 n° 6). Avec `sans_validateur`, `_sur` accepte tout plan (déclaré A.3 n° 22). |
| M2 | **Corrigé** côté banc | `banc/extensions_koach.py` : `items_du_jour` borne le produit par `facteur_borne` rapporté à la **référence** ; `cible_serie` passe par `Seances.borne_externe`, qui renvoie `None` sur `sans_hausse`, `verrou`, `part_max`, `dose_plafonnee`, zone, fragile, échec ou test. L'application reste à la charge de l'appelant (M6). |
| M3 | **Corrigé en partie**, reste déclaré | `koach/rupture.py` : `FIGEES`, `BORNES`, `valider_parametres`, événement `parametres` versé par `importer_parametres` et rejoué par `moteur.observe`. N'atteint toujours pas `Planification.p`, `ControleDual`, la BOCPD ni les hypothèses (aucun `cle_params` ni `appliquer_parametres` dans ces classes). Déclaré A.2, « Import partiel ». |
| M4 | **Corrigé** | `koach/numerique.py` `category_moments` : pas choisi sur la vraisemblance (`besoin = ceil((zhi − zlo)·sd/(0,5·large))`, 1 200 points au plus), fenêtre `[a − 8T ; b + 8T]`. |
| M5 | **Ouvert**, déclaré | Aucun changement du bruit de processus ; annexe A.2. |
| M6 | **Ouvert**, déclaré | `koach/moteur.py` `_plan` : `prescrire` sans crochet d'extension ; annexe A.2. |
| M7 | **Ouvert**, déclaré | Aucun événement `reference` dans `moteur.observe` ; annexe A.2. |
| M8 | **Ouvert**, déclaré | `rupture.Surveillance.fin_seance` prend `resume[5]` = moyenne de `jour_vu − jour_prevu` (`modele.fin_seance`, l. 477-478) ; annexe A.2. |

---

## 2. Constats nouveaux

### Bloquants

Aucun.

### Majeurs

**N1. Après une coupure, les tentatives ignorent la règle « pas de hausse » du retour, et le nouveau plancher remonte l'ouverture vers la barre d'avant la coupure.**
- Fichier : `koach/seance.py`, `_tentative` (bloc « Incertitude élargie… », environ l. 2203), avec `_item` (`if self.coupure > 0 … plan['sans_hausse'] = True`).
- Preuve :
  - Pendant la semaine du retour, `_item` pose `sans_hausse`, avec ce commentaire : « aucune hausse au-dessus du dernier passage ».
  - Un test écrit `one_rm` ou `attempt_simulation` n'est pourtant pas reporté. Seul `palier >= 1` le reporte, et `conduite` ne retire un test que sous douleur.
  - `_tentative` ne lit ni `plan['sans_hausse']`, ni `self.coupure`, ni `mem.echec`. Le plancher n'est désactivé que par `baisse >= 1.0`, c'est-à-dire par un bilan bas ou une zone de conduite.
  - Avec `barre_recente_j` = 42 et `coupure_j` = 14, une coupure de 14 à 41 jours laisse une barre « récente » qui date d'avant la coupure. Quand l'incertitude élargie fait tomber le quantile prudent sous cette barre, l'ouverture remonte jusqu'à `min(récente, 0,91·e^μ)`. Les 2e et 3e tentatives montent ensuite, sans aucune borne de retour.
  - Comparaison : la branche « test xRM » de `_cible_test` borne bien à `charge_derniere` sous `sans_hausse` et après un échec.
- Réponse aux questions du point 2a :
  - après une douleur : non (le test est retiré sous arrêt ou reprise ; `cond['zone']` donne `baisse < 1`) ;
  - après un bilan bas : non (test reporté, ou `baisse < 1` un jour d'épreuve) ;
  - après une coupure : **oui**.
- Correction proposée :
```python
# _item, après le bloc coupure :
if est_test and self.coupure > 0 and not evenement and typ == 'charge' \
        and (item.get('test') or {}).get('kind') in ('one_rm', 'attempt_simulation'):
    self._raison('koach.test_reporte', exercice=ex_id, cause='coupure')
    return None
# _tentative, condition du plancher :
if recente is not None and recente > charge and baisse >= 1.0 \
        and not plan['sans_hausse'] and self.coupure == 0 and not mem.echec:
    ...
# _tentative, un jour d'épreuve en retour de coupure (test gardé) :
if plan['sans_hausse'] and mem.charge_derniere is not None:
    charge = min(charge, mem.charge_derniere)   # à l'ouverture
```
Ajouter un test : 6 semaines de séances, 21 jours sans séance, puis un jour de test `one_rm`. Vérifier qu'aucune tentative n'est servie (ou que l'ouverture reste ≤ `charge_derniere` un jour d'épreuve).

**N2. Le contrat ne décrit pas le plancher d'ouverture des tentatives.**
- Fichier : `CONTRAT_1_0.md` § 6.5 (« Ouverture », étapes 1 à 3) et § 8.2 (A8.2), comparés à `seance._tentative`.
- Preuve : le contrat donne trois étapes (quantile plafonné, barre récente plus légère, plafond « justifié »). Le code en exécute quatre : entre les étapes 2 et 3, si `récente > charge` et `baisse ≥ 1`, alors `charge = plancher(max(min(récente, 0,91·e^μ − bw), charge))`. KM2 porte le contrat en Dart à 1e-9 près : le port servirait une ouverture différente, et la règle de sécurité ajoutée n'est relue par personne.
- Correction proposée : ajouter au § 6.5 l'étape « 2 bis. Plancher : si une barre réussie de moins de `barre_recente_j` jours est plus lourde que la charge, que `baisse ≥ 1` (et, après N1, sans `sans_hausse`, sans coupure et sans échec à la dernière séance) : `charge = plancher(max(min(récente ; tentative_ouverture_part·e^μ − bw) ; charge))` », et la citer au § 8.3 comme règle propre à Koach.

**N3. Le contrat et SOURCES ne suivent pas les ajouts du planificateur (P(cible), repli), et la valeur de `marge_cible` est fausse dans les deux documents.**
- Fichiers : `CONTRAT_1_0.md` § 3.7.1 (« Trajectoires » ; « Recherche », étapes 5 et 6) et § 7.4 ; `SOURCES.md`, section `planification` ; `koach/planification.py`, `evaluer` et `replanifier`.
- Preuve :
  1. Code : `sd_jour = √(sigma_seance² + sigma_exercice² + rendement_test_sd²)`. Contrat : `√(sigma_seance² + sigma_exercice²)`.
  2. `marge_cible` vaut **0.065** dans le JSON et **0.0** dans le tableau § 7.4 et dans SOURCES (« choix raisonné, aucune source »). Script `valeurs.py` : c'est la seule valeur des 305 qui diffère. L'empreinte SHA-256 de l'en-tête est pourtant celle du fichier actuel. Les tableaux n'ont donc pas été régénérés après le changement, et le contrôle « par script » annoncé au § 7.4 ne porte que sur la présence des clés.
  3. Le repli « aucun plan meilleur et sûr » (`garde` : plan en cours gardé, sinon la référence si elle est validée, sinon la dernière modulation prolongée sans validation ; `ligne['plan_garde']`) n'est décrit nulle part. L'étape 6 du contrat dit seulement que « le plan retenu est écrit ».
  4. `rendement_test_sd` est classé « mesure sur le banc » sans mesure citée, et `marge_cible` (0,065) n'a aucune ligne de source à sa vraie valeur.
- Conséquence : un port Dart conforme au contrat calcule un autre P(cible), et donc un autre plan, à chaque replanification avec échéance. Le repli diverge aussi.
- Correction proposée : régénérer les tableaux § 7.4 et SOURCES depuis le JSON, en comparant aussi les **valeurs** (étendre le contrôle, par exemple `valeurs.py`). Corriger la formule du § 3.7.1. Ajouter l'étape « 5 bis. Repli » (trois branches, dans l'ordre du code, verrou appliqué à la prolongation, `plan_garde` dans l'historique). Citer la mesure du banc qui donne 0,065 et 0,07, ou les classer « choix raisonné ».

### Mineurs

| N° | Fichier, fonction | Constat et preuve | Correction proposée |
| --- | --- | --- | --- |
| m1 | `seance.prescrire` | `ecrit_semaines[sem] += …` à chaque appel de `plan(seance)`. Deux appels pour une même séance (aperçu, puis séance), ou une séance prescrite puis déclarée dans `manquees`, comptent l'écrit deux fois. Le rejeu reste exact, puisque les appels sont journalisés, mais l'état dépend du nombre d'appels. La détection d'allègement (`ecrit ≤ decharge_part·ref_e`) est faussée. Le volume servi ne dépasse jamais l'écrit. | Garder l'écrit par séance : `self.ecrit_jour[(sem, self.jour)] = somme` (écrasé), et `ecrit_semaines[sem] = Σ` sur les jours de la semaine. |
| m2 | `seance._compter`, `_historique`, `_budgets_retour` ; `securite.noter_semaine` ; `dose_zone` | Toutes ces mémoires sont indexées par le numéro de semaine **du programme** (`contexte['semaine']`). Si un nouveau programme repart à 0, les semaines 0, 1, 2… s'additionnent à celles de l'ancien programme, et les limites deviennent trop larges. Les semaines sans rien (trou de numérotation) comptent « de charge à 0 » : la limite tombe alors à `volume_hausse_series` = 2 séries par groupe, ce qui est trop strict mais sans danger. | Indexer par semaine absolue (`jour // 7`), ou remettre à zéro sur un événement `reference` (voir M7). |
| m3 | `planification.replanifier`, repli | La troisième branche (la dernière modulation prolongée) n'est pas validée par `_sur`. En cas de repli, la ligne d'historique décrit la **référence** (`choisi = zeros` → `valeur`, `p_cibles`, `volume`) et non le plan gardé. | Valider la prolongation (`_sur` sur `self.plan`), sinon revenir à la référence. En cas de repli, calculer la ligne sur le plan effectivement gardé. |
| m4 | `seance._duree_permet_test` contre `_duree_bornee` | Deux modèles de durée différents : `_duree_item_s` ne compte ni les côtés, ni l'endurance, ni la vitesse ; `_duree_item` les compte. Un vrai test admis peut ensuite faire retirer des séries à la dernière ligne de renforcement (le test est toujours épargné). | Utiliser `_duree_seance(items + [rampe estimée], vitesse)` dans `_duree_permet_test`. |
| m5 | `CONTRAT_1_0.md`, A.1 n° 17 | La phrase « Les règles de volume … ne vivent que dans le validateur injecté » est périmée : `volume_hausse*`, `decharge_part` et `seance_tolerance*` sont dans le moteur (§ 8.3). Seuls `plafond_hebdo_par_niveau` (dont le plafond de la 1re semaine), `decharge_max_semaines` et `affutage_baisse` restent hors moteur (c'est ce que dit A.4 n° 6). | Aligner A.1 n° 17 sur A.4 n° 6. |
| m6 | `seance.rir_cible` ; `CONTRAT_1_0.md` § 8.1 | Le critère `contre_indication` (RIR < 1 sur une zone fragile du profil, hors test ; inventaire 0.3.1, l. 635) n'est pas repris comme plancher. Koach ne crée pas de RIR 0, mais sert des flammes 10 si elles sont écrites. L'écart n'est pas déclaré au § 8.1. | `if plan['fragile'] and not plan['test'] and rir < 1: rir = 1.0`, ou déclarer l'écart au § 8.1. |
| m7 | `rupture.BORNES` | `mesure.porte_note_ouverte` est importable jusqu'à 100, ce qui rouvre B1 (déclaré A.2, mais non corrigé alors que la correction tient en une ligne). | `('mesure', 'porte_note_ouverte'): (0.0, 3.0)`. |
| m8 | `banc/campagne.py` l. 64-66 ; `SOURCES.md` l. 24 | Chemins absolus de l'environnement de travail (`/tmp/km1-campagne`, `/home/claude/km1-outils/SET9`, `/home/claude/km1-outils/`) dans des fichiers publics. Aucune donnée privée, mais un détail d'environnement. | Variable d'environnement ou option en ligne de commande ; dans SOURCES, « dépôt d'outils du lot (non publié) ». |
| m9 | `donnees/rejeu_journal_agregats.json`, `conversion` | `profil_niveau_lu` = 1 est un attribut individuel de l'athlète du journal. Les autres comptes (73 séances lues, 12 pesées…) décrivent un seul journal. C'est acceptable en agrégat, mais à acter. | Retirer `profil_niveau_lu`, ou acter qu'il est publiable. |

Points vérifiés sans constat :
- `_retour_gradue` ne fait que **réduire** (séries, puis secondes des tenues). Le signe des budgets est juste (`limite − fait − réserve − jour`), et les crédits sont strictement positifs, donc aucune division par zéro.
- Un groupe sans historique reçoit une limite égale à la tolérance (prudent).
- Une séance manquée compte à son écrit, comme le validateur du banc.
- `_fermer_volume` compte les séries dures de la montée.
- `cible` (arrêt `volume_test`) garantit montée + travail ≤ séries de la ligne, et `durs_max = max(1, lignes − 1)`.
- `_duree_bornee` ne retire jamais une montée de test ; `_vitesse` est protégée contre une distance nulle.
- Déterminisme : aucune itération sur un ensemble non trié dans les ajouts (`sorted(r_t)`, `FAMILLES_BRAS_TENDUS`, `sorted(hits)`), aucune clé flottante. Les mémoires nouvelles (`vol_semaines`, `tenue_semaines`, `dures_semaines`, `ecrit_semaines`, `allegees`, `zones_ex`, `jours_durs`, `jours_seances`) dérivent toutes de `seance_debut.contexte`, des événements `plan` et de `seance_fin`.
- Le rendement de test entre dans P(cible) avec le bon signe : `ln(cible) + 0,065` rend l'objectif plus exigeant, donc plus prudent.

---

## 3. Paramètres (scripts `cles.py`, `cles2.py`, `valeurs.py`)

- SHA-256 de `params/koach_params_v1.json` : `e9e315289def5ea0c5c0f5207005002e6b3d317d4786dc3d595e25359d72c47e`. **Identique** à l'empreinte citée dans les en-têtes de `CONTRAT_1_0.md` et de `SOURCES.md`.
- Clés : 305 (6 à la racine, 299 dans 11 sections). Tableau § 7.4 du contrat : 305 lignes, mêmes clés, **même ordre**, aucun doublon. `SOURCES.md` § 1 : 305 lignes, mêmes clés, aucun doublon.
- Valeurs : une seule diffère. `planification.marge_cible` vaut 0.0 dans les deux documents et 0.065 dans le fichier (N3).
- Clés jamais lues dans `koach/`, `banc/` ni `rejeu/` (recherche de la chaîne) : 14. Ce sont `classes_reponse`, `mesure.bruit_serie`, `bruit_echec`, `bruit_continu`, `fatigue.grille_tau_nerveux`, `grille_tau_musculaire`, `grille_tau_tendineux`, `test_adaptatif.poids_information`, `test_reps_ouvertes`, `planification.gain_affutage`, `securite.douleur_remplacant_part`, `plafond_hebdo_par_niveau`, `decharge_max_semaines` et `affutage_baisse`. `qualites` n'est lue que par le banc. Avec `mesure.cardio_poids_qualite` (lue par le banc seulement) et `rupture.fenetre` et `adherence.refus_silence_j` (présentes dans les dictionnaires de défauts seulement), on retrouve les **18 clés non lues par le moteur** annoncées au § 7.5 et en A.3 n° 13. C'est cohérent. Toutes sont marquées « Non lue » dans le tableau.

## 4. Confidentialité

Recherche dans `packages/kalis_adapt/reference/` et `packages/kalis_bench/` (fichiers suivis ou non, hors `__pycache__`, fichiers `.gz` décompressés compris) :
- `km1-journal` : **aucune occurrence**.
- Nom ou adresse de l'utilisateur, adresse électronique, lieux personnels : **aucun**.
- Noms des auteurs des programmes de référence privés (les deux entraîneurs de calisthénie connus du profil) et nom du classeur de programme personnel : **aucune occurrence**.
- Valeurs individuelles d'un journal réel : **aucune**. `tests/test_rejeu.py` utilise un export synthétique (dates de 2030), et `rejeu/walk_forward.py` prend l'export en argument. Les seuls chemins de travail trouvés sont ceux du mineur m8.
- `donnees/rejeu_journal_agregats.json` :
  - aucune cellule avec n < 3 ne porte de statistique (les cellules n = 1 ou 2 n'ont que `n` ; `B_tests_reels/test1rm` a n = 0 et le seul compte 0) ;
  - aucune date, aucun identifiant d'exercice (motif `xx-…`), aucune clé de séance ;
  - les chaînes se limitent à la description et au schéma ;
  - reste à acter : `profil_niveau_lu` (m9).
