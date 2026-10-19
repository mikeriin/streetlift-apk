# Conventions du portage Dart de Koach 1.0.1 (lot KM2)

Référence : `packages/kalis_adapt/reference/koach/*.py` (Python, numpy), contrat
`CONTRAT_1_0.md`. Cible : `packages/kalis_adapt/lib/src/koach/*.dart`, **une seule
bibliothèque** `koach.dart` dont chaque module est un `part` (`part of 'koach.dart';`).
Les membres privés (`_x`) sont donc partagés entre les fichiers. Parité visée :
1e-9 relatif sur les fixtures `reference/fixtures/*.json` (en pratique : bit pour bit,
mêmes opérations flottantes dans le même ordre).

Il n'y a **pas de SDK Dart dans la session** : le code est compilé et testé par la CI.
Écrire du Dart 3 strict (`strict-casts`, `strict-inference`, `strict-raw-types`,
`package:lints/recommended.yaml`, `dart format` largeur 80 par défaut — le format est
corrigé par la CI, ne pas s'en soucier) : aucun cast implicite depuis `dynamic`/`Object?`.

## Règle principale : port ligne pour ligne

- Même découpage en fonctions et méthodes, mêmes noms traduits, même ordre des
  opérations flottantes (associativité de gauche à droite comme Python : `a * b * c`
  = `(a * b) * c`). Ne jamais « simplifier » une expression.
- `x ** y` (flottants) → `pw(x, y)` (= `math.pow`, pow de la libc comme CPython),
  y compris `x ** 2`. `x * x` reste `x * x`.
- `math.exp/log/sqrt` → `math.exp/log/sqrt` (`dart:math` est importé `as math`).
- `math.floor(x)` → `x.floor()` (int) ; `math.ceil` → `.ceil()` ; `int(x)` →
  `.truncate()` ; `float(x)` → `dbl(x)` ; `round(x, n)` de Python → voir le contrat
  (§ 9.4 : `arrondi` de numerique) ; `a // b` sur des entiers → `divEnt(a, b)`.
- `min/max` de Python : `math.min/max` sur des nombres (attention : `max(a, b, c)` →
  `math.max(math.max(a, b), c)`).
- numpy : boucles explicites. Produits matrice-vecteur et réductions : **somme
  séquentielle dans l'ordre des indices** (sauf indication contraire de l'appelant).
  Les tableaux d'état du `Modele` sont des `Float64List` à la capacité `cap` :
  `m[i]`, covariance `pm[i * cap + j]` (lecture `modele.pget(i, j)`).
- Vérité Python (`if x:`, `x or y`) → `vrai(x)`, `ou(x, y)` (fichier `outils.dart`).
  `d.get(k) or {}` → `dictOuVide(d[k])` ; `d.get(k) or []` → `listeOuVide(d[k])`.
- `d.get(k, defaut)` → `d[k] ?? defaut` (la référence ne met jamais de `None`
  explicite là où un défaut est donné, sauf mention).
- Entrées JSON : `Json = Map<String, Object?>`. Lecture typée : `dbl(v)`, `dblOu(v)`,
  `ent(v)`, `jm(v)`, `jmOu(v)`, `jl(v)`, `jld(v)` (liste de doubles), `v as String`.
  Les nombres JSON peuvent être `int` ou `double` : toujours passer par `dbl`/`ent`.
- `copy.deepcopy` → `copieProfonde` / `copieJson`. `dict(x)` (copie superficielle) →
  `Map<String, Object?>.of(x)`. `list(x)` → `List.of(x)`.
- Dictionnaires : l'ordre d'insertion compte (Dart `Map` littéral / `LinkedHashMap`
  le garde). Clés tuples → records Dart (`(int, String)`), qui ont l'égalité de valeur.
- Ensembles Python → `Set` Dart ; l'ordre d'itération d'un ensemble n'entre dans aucun
  résultat (contrat § 9.2) ; quand le Python trie (`sorted`), trier (`..sort()` sur des
  `String` = ordre des points de code pour l'ASCII).
- Tuples renvoyés → records (`(double, double)`), déstructurés par `final (a, b) = …`.
- Classes : mêmes noms (`Gardefous`, `Seances`, `Grille`, `Memoire`, `Planification`,
  `Surveillance`, `Bocpd`, `Adherence`, `ControleDual`, `EssaiN1`, `Reponse`…).
- Noms : `snake_case` → `lowerCamelCase`, `_prive` → `_prive` ; constantes de module
  `MAJUSCULES` → `lowerCamelCase` (`SEMAINES_VERROUILLEES` → `semainesVerrouillees`).
  Les fonctions de module **privées** d'un fichier prennent un préfixe propre au fichier
  pour éviter les collisions entre parts : `_se` (seance), `_sec` (securite), `_pl`
  (planification), `_ru` (rupture), `_ad` (adherence), `_du` (dual) — par exemple
  `seance.arrondi` (entier) → `_seArrondi`. Les fonctions publiques de module gardent
  leur nom traduit s'il ne collisionne pas avec un nom déjà défini (voir les fichiers
  existants) ; sinon préfixe du module (`seanceArrondi`).
- Mots réservés ou types Dart comme noms de variables (`in`, `is`, `num`, `int`,
  `default`, `new`, `var`…) : suffixe `_` → `num_`… (lint : préférer `nombre`, `valeur`).
- Exceptions Python (`ValueError`) → `ArgumentError(message)` ; `KeyError` implicite →
  laisser échouer (cast nul).
- Texte des traces (`trace`, hors contrat) : reproduire au mieux, sans exigence de
  parité (`'%.1f' % x` → `x.toStringAsFixed(1)`).

## Ce qui existe déjà (à lire avant d'écrire)

- `outils.dart` : `Json`, `inf`, `dbl`, `dblOu`, `ent`, `jm`, `jmOu`, `jl`, `jld`,
  `vrai`, `ou`, `dictOuVide`, `listeOuVide`, `copieProfonde`, `copieJson`, `plancher`,
  `plafond`, `divEnt`, `egalJson`, `somme`, `dans`.
- `numerique.dart` : `erfcK`, `normPdfK`, `normCdfK`, `normSfK`, `normPpfK`,
  `intervalMoments`, `categoryMoments`, `pointMoments` (records `(logZ, m, v)`),
  `Mulberry32` (`next`, `gauss`), `fnv1a32`, `dartRound`, `clampD`, `choleskySemi`,
  `arrondi(x, [n])`, constantes `sqrt2`, `sqrtPi`, `sqrt2Pi`, `m32`.
- `modele.dart` : constantes d'indices `nq ngr th rho eps kn km ba bp lam ku fi hh ds de kl
  kg ng`, `cLin`, `g8`, `ln8`, `lamMin`, `lamMax`, `pw`, `phiK` (= `_phi`), `phi1K`,
  `classesK` (= `CLASSES`), `zonesTendon`, typedefs `Residu`, `ResumeSeance`
  (`(int jour, double z, double rel, int n, double poidsMauvaisJour, double? e1rm)`),
  classes `Piste` et `Modele` (méthodes : `piste`, `baseDe`, `courbeMoyenne`, statiques
  `Modele.gK` (= `_g`), `Modele.dgK`, `Modele.dgFormeK`, `Modele.repsDe`, `courbe`,
  `repsA`, `avancer`, `effort`, `effortIntra`, `fatigueDe`, `fatigueIntraDe`, `gardeDe`,
  `intra` (= `_intra`), `debutSeance`, `debutExercice`, `poidsMauvaisJour`, `finSeance`,
  `hCapacite(t, jour:)` (= `_h_capacite`), statique `Modele.stats(m, pm, cap, idx, co)`
  (= `_stats`), `bruitRirDe`, `noteurEntier`, `bornesFlammes`, `rirVrai`, `observerSerie`,
  `masse`, `mu` (= `_mu`), `observerRaison`, `observerChargeManuelle`, `changerCran`,
  `dose`, `doseMoyenne`, `recuperation`, `accoutumance`, `finSemaine`, `elargir`,
  `capacite`, `capaciteDuJour`, `intervalle`, `valeur` ; champs `p`, `vecteurs`, `profil`,
  `niveau`, `cap`, `m`, `pm`, `n`, `pistes`, `ordre`, `jour`, `poidsKg`, `tau`, `fG`, `fL`,
  `fTendon`, `bruitRir`, `paresse`, `logw`, `enSeance`, `bilan`, `histoireResidus`,
  `hypotheses` (liste de `(double s0, int k)`), `poidsHyp`, `semaines`,
  `journalSemaines`, `elargi`, `altOuverte`, `altM`, `altP`).
- `moteur.dart` : `Extension` (crochets `finSeance(koach, resume, e)`,
  `seanceManquee(koach, e)`, `finSemaine(koach, ligne, e)`, `decision(koach, e)`,
  `planSemaine(koach, c)`), interfaces `AvecAlerteHorsModele`
  (`surAlerteHorsModele(koach, List<String> causes)`), `AvecParametres`
  (`appliquerParametres(Json params)`), `AvecHypothese`
  (`int? hypothesePourLaSemaine(koach, semaine, graine)`) — un `getattr(x, 'f')` de la
  référence devient `if (x is AvecX)`. Classe `Koach` (champs `params`, `fiches`
  (`Map<String, Json>`), `profil`, `modele`, `garde`, `seances`, `journal`, `raisons`,
  `jour`, `extensions` ; méthodes `observe`, `posterior`, `plan`, `explain`), fonction
  `rejouer`.

## Interfaces attendues entre modules

- `securite.dart` : `Gardefous(Json params, int niveau, Object? zonesFragiles)` ; champ
  `Json s` (section `securite`, réaffecté par l'import de paramètres) ; méthodes
  `avancer(int jour)`, `noterSeance(int jour, List<Object?> douleurs, {bool posee = true})`,
  et les autres traduites. Constantes `zonesBas`, `poignet`, `semainesVerrouillees`.
- `seance.dart` : `Grille(double pas, double minimum, [bool halteres = false])` (champs
  `pas`, `minimum`, `halteres`) ; `Seances(Json params, Modele modele, Gardefous garde,
  Map<String, Json> fiches)` ; champs `Json p`, `Json s` (réaffectés par l'import),
  `List<Json> raisons` ; méthodes `ouvrir(int jour, Json? bilan, Json contexte)`,
  `serieFaite(Json s)`, `fermer(Json record)`,
  `List<Json> prescrire(List<Json> items, Map<String, Grille> grilles,
  Map<String, (Json, Set<String>)> zones, Json roles)`,
  `Json? cible(Json item, int index, List<Object?> faites)`,
  `Json? borneExterne(Json item, int index, double charge)` (renvoie ce que renvoie la
  référence), et le reste traduit. Fonctions de module `rirDeFlammes`, `flammesDeRir`,
  `equivalentStandard`, `secondesPrescrites`, `reduire`.
- `planification.dart` : `typedef Validateur = List<Json> Function(List<Json> blocs);`
  `Planification(Json params, Map<String, Json> fiches, Validateur? validateur,
  [Json? options])` (extension) ; `chargerReference(...)`, `tirer`, `evaluer`,
  `replanifier`, `itemsModules`, `appliquer`, `blocsModules`, champs `plan`,
  `historique`, `suivis`, `p`… (traduits).
- `rupture.dart` : `Surveillance(Json params)`, `Bocpd`, `importerParametres(Koach k,
  Json fichier)` (renvoie `{ok, erreurs, …}` comme la référence),
  `appliquerParametres(Koach k, Json nouveau)` (fonction de module appelée par
  `Koach.observe`), `figees` (= `FIGEES`), `bornes` (= `BORNES`).
- `adherence.dart` : `Adherence([Json? params])`, constantes `types`/`moments`… traduites
  (préfixer si collision : `adherenceTypes`, `adherenceMoments`), `defautsAdherence`.
- `dual.dart` : `ControleDual(Json params, List<String> liftsPrincipaux)`, `Reponse`,
  `EssaiN1`, fonctions `calibre`, `facteurBorne`, constante `z90`, `defautsDual`.

## Delta 1.0.1 → 1.0.2 (lot KM2c1)

**Porté le 15/10/2026 (`kalis_adapt` 1.0.1, `kalis_bench` 0.4.2)** : les points ci-dessous sont faits ; les tests lisent `fixtures/` et `params/koach_params_v1.json`, les copies figées de 1.0.1 sont supprimées. Livraison : `pipeline/cp/livraisons/LIVRAISON_KM2c1.md`.

Liste exacte : `CHANGEMENTS_1_0_2.md`. Points d'attention pour la parité :

- `seance.dart` : `Memoire.barres` (jour, charge, répétitions, flammes ou nul) et `barres_ratees` (jour, charge), remplies par `fermer` dans l'ordre des séries du groupe ; `plan['reprise']`, `plan['reprise_plafond']` (calculé une seule fois par ligne, à la première série demandée, avec le `repsHigh` de la série d'index 0 et `gel = faux` ; les raisons émises par ce calcul sont retirées), `plan['palier_franchi']` ; `_bornes_hausse` reçoit `gel` (nul = `sans_hausse ou reprise`) ; `_palier_barres` : mêmes parcours de listes, mêmes comparaisons à 1e-9 (`dit >= seuil - 1e-9`, bande `total >= plus_haute*(1 - bande) - 1e-9`, barre ratée `> plus_haute + 1e-9`).
- `planification.dart` : la contraction se fait exercice par exercice, dans l'ordre de `suivis`, sur les seules cibles de type `charge` ; `centre` = moyenne numpy de la tranche `(candidats, trajectoires)` le long des trajectoires (sommation par paires, comme `prevu_jour`) ; `kd` est calculé une fois par appel d'`evaluer` ; `frais` est modifié avant `prevu_jour`, `jour` et l'échelle des tentatives.
- `modele.dart` : `capacite(id, brut)` ; `dual.dart` passe `brut = vrai` aux deux lectures de variance (mise à jour des hypothèses, `cap_seance`) et pas à `calibre`.
- `rupture.dart` : quatre bornes d'import de plus.
- Paramètres : cinq clés nouvelles placées à la fin de leur section (`mesure.intervalle_echelle` après `defaut_modele_sd`), SHA-256 dans l'en-tête du contrat ; les clés `securite` nouvelles sont des listes de listes et un flottant.
- Banc : `critere_apparie` (`banc/adversaire.py`) est à porter dans `kalis_bench` (`kmComparerAdversaires`, clé `critere_7_bis`) ; `--partie` existe déjà côté Dart.

- Tests Dart : depuis KM1c2 ils lisent les copies figées de 1.0.1 (`reference/fix_dart/`, `reference/params/koach_params_d1.json` ; chemins de même longueur que les originaux). KM2c1 les repointe vers `reference/fixtures/` et `reference/params/koach_params_v1.json` (kalis_adapt : `koach_facade_test`, `koach_parite_test`, `koach_proprietes_test`, `koach_textes_test`, `validateur_test`, `koach_parametres_test` ; kalis_bench : `km2_banc_test`, `km2_validateur_test`, `km2_adversaire_test`, `bin/km2.dart`, `bin/km2_adversaire.dart`), met à jour les attentes de `koach_parametres_test` (version, SHA-256, 322 clés : 6 + 316), régénère `kalis_bench/test/fixtures/km2/` (`fixtures/generer_banc_km2.py`) et supprime les copies.

## Delta 1.0.2 → 1.0.3 (lot KM2c2)

Liste exacte : `CHANGEMENTS_1_0_3.md` (section H : fichiers Dart concernés). Points d'attention pour la parité :

- `modele.dart` : classe `Fiabilite` (contrat § 5.13) : grille `lphi` de `fiabilite_phi_points` valeurs (`lo + (hi − lo)·k/(n − 1)`), `phi = exp(lphi)`, a priori normalisé par `_normaliser` (soustraction de `max + ln Σ exp(x − max)`, boucles explicites), `phi0 = Σ exp(lp0_k)·phi_k` ; `_masse(mu, sd, a, b)` : plancher de sd 1e-9, `Φ_b = 1` si `b` est infini et `Φ_a = 0` si `a` l'est, ramené à 0 si négatif ; `noter` : pour chaque k, `var = v + phi_k·s0_2 + extra`, `L = _masse(mu, sqrt(var), a, b)`, puis si g > 0 : `L = (1 − g)·L + g·_masse(mu, sqrt(var + gsd²), a, b)` avec `(g, gsd) = note_erreur_grossiere`, puis `L = w_main·L + w_nul`, 1e-300 avant `log` ; `_ajouter` : `lp0_k + λ·(lp_k − lp0_k) + logl_k` puis normalisation ; `serie` : comptes Beta avec le même oubli ; `proba_phi_sup` compare `lphi_k >= ln(seuil) − 1e-9`. Les deux grilles par schéma suivent les mêmes appels. `elargissement` : `κ² = 1 + a·max(E[φ] − phi0, 0) + c·max(ρ − ρ0, 0)²`, 1 si κ² ≤ 1, sinon `min(sqrt(κ²), fiabilite_elargissement_max)`. `oubli` est lu dans `p` à chaque appel.
- `_serie_force` : appels placés APRÈS la sonde et AVANT la porte des séries sans note, pour toute série de `reps > 0` non ratée et dont `kind` n'est pas `warmup` : `fiabilite.serie(percu, lourd)` puis, si `percu`, `fiabilite.noter(pred, max(var_p, 0), a, b, (s2 − extra)/bruit_rir², extra, melange[0], melange[1], lourd)`, avec `var_p = cᵀPc` (`_stats` sur la branche principale), `extra = (dispersion_fatigue_intra·sj·R)²`, `lourd = (repsHigh ?? reps) ≤ fiabilite_schema_reps`. L'état `m`, `P` n'est pas touché par ces appels.
- `capacite(id, brut)` : `k = intervalle_echelle × κ` hors `brut` ; `capacite_du_jour(id, brut)` : écart-type × κ hors `brut`. `elargissement()` est lu à chaque appel (pas de cache).
- `planification.dart`, `tirer` : après la symétrisation de S et avant Cholesky, si κ ≠ 1 : pour i < E, ligne i × κ puis colonne i × κ (dans cet ordre, sur la même matrice).
- `seance.dart` : `proba_reussite(ex, externe, reps, brut)` ; `_tentative` et `_rampe` lisent `capacite_du_jour(ex, brut: true)` ; `_tentative` passe `brut: true` aux deux `proba_reussite` ; après un échec dans la séance, hors semaine de compétition (`genres[semaine] == 'competition'` lu comme en Python) et si `tentative_echec_baisse_part > 0` : `bas = max((derniere + bw)(1 − part) − bw, minimum)`, `plancher_ = grille.plancher(bas)`, `plancher_ = grille.suivant(plancher_)` si `plancher_ < bas − 1e-9`, `c = plus_lourde(proba)` bornée à `[plancher_, derniere]`. `_palier_barres` : `kappa`, `g_pas`, `marge` calculés une fois en tête ; `pas *= g_pas` après le choix de la ligne de `tentative_palier_par_rir` ; `total *= 1 − marge` si `marge > 0` ; le reste inchangé. `_cible_charge` : `prudence += prudence_charge_fiabilite·(κ − 1)` si κ > 1 et `hi ≤ fiabilite_schema_reps`, après le choix `prudence_charge[0/1]`. `_bornes_hausse` : règle `echec_sans_hausse_tout_schema` appliquée juste après le calcul de `gel`, avant le schéma connu.
- `rupture.dart` : `bornes` : `defaut_modele_sd` (0,001 ; 0,1) et six bornes nouvelles ; `figees` : les cinq clés de grille et d'a priori de la fiabilité ; `appliquerParametres` : `modele.fiabilite.p = fusion['mesure']`. `moteur.dart` : `posterior()['fiabilite'] = fiabilite.resume()`. Défauts du code quand une clé manque (fichiers 1.0.2) : les valeurs du fichier 1.0.3, sauf `echec_sans_hausse_tout_schema` (défaut 0 dans le code, 1 dans le fichier) et les coefficients d'élargissement (0 dans le code).
- Paramètres : 16 clés nouvelles à la fin de leur section (`mesure`, `securite`, `planification`), aucune valeur existante changée ; asset `koach_params_1_0_3.json`, SHA-256 et 338 clés (6 + 332) dans `koach_parametres_test.dart`.
- Tests Dart : depuis KM1c3 ils lisent les copies figées de 1.0.2 (`reference/fix_dart/`, `reference/params/koach_params_d2.json`). KM2c2 les repointe vers `reference/fixtures/` et `reference/params/koach_params_v1.json`, régénère `kalis_bench/test/fixtures/km2/` si le banc Dart change et supprime les copies. `kalis_bench` n'a pas été touché par KM1c3.
- **Fait en KM2c2** (`kalis_adapt` 1.0.2, 16/10/2026) : delta porté, tests repointés, copies supprimées, asset
  `koach_params_1_0_3.json`. Branches du delta que les 15 fixtures n'exécutent pas (tentative ratée hors compétition,
  tirages du jumeau avec κ > 1) : fixtures complémentaires `kalis_adapt/test/fixtures/km2c2/` produites par la
  référence sans la modifier (`generer_km2c2.py`). Note : `fixtures/generer.py`, `tirage_intermediaire` (aide au
  portage, non lue par les tests Dart) n'applique pas κ ; le générateur de KM2c2 en a une variante qui l'applique.
  Le banc Dart comparait alors la référence sur les saisons figées (`--saisons-figees`) : la saison vivante de
  `kalis_plan` 0.4.x n'était plus celle que lisait Python (régénérée au lot KR1, ci-dessous).

## Delta 1.0.3 → 1.0.4 (lot KR1, `kalis_adapt` 1.0.3, 16/10/2026)

- `modele.dart` : `elargir(facteur)` lit d'abord, pour chaque composante de `variancesAPriori()` (qualités `th + q`,
  puis `pistes[e].idx` dans l'ordre de `ordre`), `ri = !(v > 0) ? √facteur : min(√facteur ; max(1 ; √(v0 / v)))` sur
  la diagonale d'avant, puis multiplie ligne puis colonne, composante par composante (même ordre que Python) ;
  `variancesAPriori()` : `theta_sd²` (via `pw(x, 2)`), puis pour chaque piste `max(sd·sd − Σ v_q²·theta_sd² ;
  pw(0,5·sd, 2))`, `sd` lu comme dans `piste` (`tenue` sur `reps_sd`). La branche `alt` n'est pas touchée.
- Paramètres : aucune valeur changée ; version `1.0.4-ref.1`, asset `koach_params_1_0_4.json`.
- Données de référence régénérées sur `kalis_plan` 0.4.1 (34 profils) : la saison vivante du banc est de nouveau celle
  que lit Python (`km2_banc_test.dart`, égalité stricte) ; `--saisons-figees` relit `kalis_bench/docs/data/kr1/saisons_figees_0_3_1/reference/`.

## Delta 1.0.4 → 1.0.5 (lot KM1c4, 17/10/2026 ; portage = lot KM2c3, `kalis_adapt` 1.0.4)

Liste exacte : `CHANGEMENTS_1_0_5.md` (section G : fichiers Dart concernés). Points d'attention pour la parité :

- `securite.dart` : `episode(z)` renvoie `(premier, dernier)` des signalements ≥ `arret_persistance_min` de
  l'épisode en cours, par le même découpage que `_episode` (déjà porté pour les arrêts) ; `sensible(z)` =
  `0 ≤ jour − dernier ≤ sensible_j` ; `sensibles()` trié ; `geneRecente(z)` = `pireEntre(jour − douleur_hausse_j + 1,
  jour)`. Dans `conduite`, après le bloc « zone bloquante depuis la dernière séance » et avant le bloc `recente` :
  `if (act <= 0 && niveau >= 0.5 && geneRecente(z) > douleur_seuil) { sans_hausse ; rir = max(rir,
  douleur_rir_bonus) ; note(z, 'douleur') }` (ordre des `note` : la première raison l'emporte, comme en Python).
- `seance.dart` : état `ecritZone` (zone → semaine → séries écrites), `budgetSemaine` (zone → permis), `rampeZone`
  (ensemble, parcouru trié quand il est écrit), `reserveEchauffement` (zone → séries que l'échauffement peut prendre
  aujourd'hui) ; `_semaineConnue(w)` = `garde.semaines.containsKey(w) || allegees.containsKey(w)` ;
  `_semaineDeCharge(w)` = `garde.semaines[w]` si connue là, sinon `!allegees[w]` si connue là, sinon faux (jamais sur
  `joursSeances`, tronqué à 20) ; `_compterEcritZone(semaine, items)` (sur `zonesEx` connues seulement, `sets` entier
  > 0) ; `_ecritZone` ; `_budgetZoneSemaine(z)` → `(int? permis, bool sortie)`, fonction pure, ligne pour ligne :
  `debut = ep.premier ~/ 7` ; `apres = debut + 1`, ou, si `arretLeve != null && arretLeve >= ep.premier`,
  `max(apres, premiere)` avec `premiere = 7 − leve % 7 >= 4 ? leve ~/ 7 : leve ~/ 7 + 1` ; branche `semaine == debut`
  (recherche de la dernière semaine de charge parmi les `rampe_zone_semaines_max` précédentes, `tenir`), sinon boucle
  `w` décroissante de `semaine − 1` à `debut` qui s'arrête à la première semaine de charge (si `w < apres` : pas de
  référence), recherche arrière de `w − 1` à `max(apres, w − rampe_zone_semaines_max)` ; puis, sans référence, si
  `apres == debut + 1` et que `debut` est de charge : référence `debut`, `tenir` ; `floor(x + 1e-9)` ; `habitude =
  somme / 4.0` ; sortie quand `total >= max(ecrit(semaine), ecrit(dernière semaine de charge))` ; `ouvrir` : zones
  triées, `(b, sortie) = _budgetZoneSemaine(z)`, `sortie` retire de `rampeZone`, `b != null` l'y ajoute et pose
  `budgetSemaine[z]` ; `_budgetsZoneJour(items)` : `part = floor(reste · e_jour / (e_jour + e_reste) + 0,5)` en double,
  `reste` entier ; `prescrire` : `_compterEcritZone(sem, items)`, `budgetZone = _budgetsZoneJour(items)`,
  `reserveEchauffement[z] = max(0, budgetZone[z] − travail écrit sur z)` avant la boucle, et le vrai test n'est pas
  tenté quand une zone provoquée par l'exercice est dans `budgetZone` ; `_item` : le bloc du budget s'applique à **tout**
  item (échauffement et test compris), un échauffement est borné par `min(reste, reserveEchauffement[z])` et débite les
  deux, le retrait n'a lieu que si une zone est épuisée (`epuisee`), la raison `douleur_retrait` porte cette zone.
  `_budgetReprise` disparaît.
  Règle 3 bis (rampe de retour après une coupure) : état `retourZone` (zone → `(int semaine, int depart)`, parcouru
  trié), `manqueZone` (zone → semaine → séries écrites des séances manquées, `_compterManqueZone` appelé dans
  `ouvrir` juste après `_compterEcritZone` pour chaque séance manquée versée), `expoJour` (zone → dernier jour
  d'exposition réalisée, posé dans `fermer` dans la boucle qui incrémente `doseZone`) ; `_manqueRecent(z)` = une
  entrée > 0 dans `manqueZone[z]` pour `k ∈ [semaine − charge_chronique_semaines ; semaine[` ; `_habitudeAvant(z,
  fin)` = somme de `doseZone[z][k]` pour `k ∈ [fin − charge_chronique_semaines + 1 ; fin]` et `k ≥ min(garde.semaines
  ∪ allegees)` divisée par le nombre de ces `k` (null sans semaine connue ou sans `k`) ; `_departRetour(z)` =
  `floor(reprise_dose_depart · habitude + 1e-9)` avec `fin = expoJour[z] ~/ 7`, `reprise_dose_sans_habitude` si
  l'habitude est null ou ≤ 0, au moins `reprise_dose_min` ; `_budgetRetour(z, {depart, debut})` → `(int? permis, bool
  sortie)`, fonction pure : `(debut, depart)` lus dans `retourZone[z]` s'ils ne sont pas donnés (null sinon) ; boucle
  `w` décroissante de `semaine − 1` à `debut` qui s'arrête à la première semaine de charge, recherche arrière de
  `w − 1` à `max(debut, w − rampe_zone_semaines_max)` si la dose est ≤ 0 ; avec référence > 0 : `max(ref + 1,
  floor(ref · (1 + reprise_dose_hausse) + 1e-9))`, sinon `depart` ; au moins `reprise_dose_min` ; sortie quand `total
  >= max(ecrit(semaine), ecrit(dernière semaine de charge))` ; `_entrerRetour(items)` appelé dans `prescrire` juste
  après `_compterEcritZone(sem, items)` (donc seulement si `sem != null`) et avant `_budgetsZoneJour` : zones = clés
  de `doseZone` ∪ zones provoquées des items du jour et de `contexte['reste_semaine']` (`zonesEx` connues), triées ;
  on saute une zone déjà dans `budgetSemaine`, `retourZone`, `rampeZone` ou sensible, une zone dont aucune valeur de
  `doseZone` n'est > 0, une zone sans `expoJour` ou avec `jour − expoJour[z] < coupure_j`, une zone sans
  `_manqueRecent` ; `ecrit = ecritZone(z, semaine) + séries des séances restantes sur z` ; si `ecrit > 0`,
  `depart = _departRetour(z)`, `(permis, _) = _budgetRetour(z, depart: depart, debut: semaine)`, et si `permis !=
  null && permis < ecrit` : `retourZone[z] = (semaine, depart)`, `budgetSemaine[z] = permis`. `_entrerRetour` rend la main
  aussitôt si `verrouillee()`. Dans `ouvrir`, après la boucle des zones sensibles : pour chaque zone de `retourZone`
  (triée), si elle est dans `budgetSemaine` ou sensible → retirée de `retourZone` ; sinon, si `verrouillee()` →
  rien (suspendue) ; sinon `(b, sortie) = _budgetRetour(z)` ; `sortie || b == null` → retirée, sinon
  `budgetSemaine[z] = b` (sans toucher `rampeZone`). Le permis du jour et `_item` s'appliquent aux zones en retour comme aux zones
  sensibles (même `budgetZone`) ; l'interdiction du vrai test ne vaut que pour une zone de `budgetZone` qui n'est
  pas dans `retourZone`.
- `modele.dart` : `elargir(part)` : `lam = clamp(part, 0, 1)` ; `idx` = indices de `variancesAPriori()` ; pour chaque
  branche (`P` principale, puis `alt.P` si la branche « mauvais jour » existe, dans l'ordre de `_branches`) : lignes
  puis colonnes de chaque `i` multipliées par `(1 − lam)` ; puis, si `lam < 1`, le bloc `idx × idx` divisé par
  `(1 − lam)` (division, pas multiplication par l'inverse : même arrondi que Python), sinon mis à 0 ; puis
  `P[i][i] += lam · v0`. Même ordre d'opérations que `modele.py`.
- `rupture.dart` : cause « rien » : `part = elargissement_vers_a_priori` (défaut 0,25), `modele.elargir(part)`, action
  `{'action': 'elargir', 'part': part}` ; `bornes` : `('rupture', 'elargissement_vers_a_priori') : (0, 1)` ;
  `elargissement_rien_de_special` n'est plus lu : KM2c3 la retire du fichier `koach_params_v1.json`, de l'asset et des
  bornes (le validateur Dart ne doit ni l'exiger ni la refuser).
- Paramètres : 7 clés nouvelles insérées dans leur section (`securite` : `reprise_dose_sans_habitude`,
  `reprise_dose_min`, `rampe_zone_semaines_max`, `sensible_j`, `douleur_hausse_j`, `charge_chronique_semaines` juste
  après `reprise_dose_hausse` ;
  `rupture` : `elargissement_vers_a_priori` juste après `elargissement_rien_de_special`), `securite.reprise_dose_depart`
  0,5 ; version `1.0.5-ref.1`, asset
  `koach_params_1_0_5.json`, SHA-256 et 345 clés (6 + 339 ; 346 écrit par erreur au départ) dans `koach_parametres_test.dart`.
- Modèle de vérité du banc (`lib/src/sim/truth.dart`) : `PORTAGE_BANC.md`, « Delta KM1c4 » (`_painKnown = false` au
  début d'un épisode de la fiche et d'un épisode tendineux).
- Tests Dart : depuis KM1c4 ils lisent les copies figées de 1.0.4 (`reference/fix_dart/`,
  `reference/params/koach_params_d4.json`) ; `kalis_bench` (`km2_banc_test`, `km2_validateur_test`,
  `km2_adversaire_test`, `bin/km2.dart`, `bin/km2_adversaire.dart`) lit `koach_params_d4.json`. KM2c3 repointe tout
  vers `reference/fixtures/` et `reference/params/koach_params_v1.json`, supprime `fix_dart/` et
  `koach_params_d4.json`, régénère `kalis_bench/test/fixtures/km2/` (`generer_banc_km2.py`, moteur 1.0.5, vérité
  corrigée) et met `_planReference` à la version courante de `kalis_plan` si elle change.
- **Fait en KM2c3** (`kalis_adapt` 1.0.4, `kalis_bench` 0.5.6, 17-18/10/2026) : delta porté ligne pour ligne, tests
  repointés, `fix_dart/` et `koach_params_d4.json` supprimés, asset `koach_params_1_0_5.json` (345 clés, SHA-256
  `d8a492b7…f26d`, identique au fichier de la référence), `truth.dart` corrigé, fixtures du banc régénérées (et trois
  saisons ajoutées : `autres_08` référence b 47, `ks_01` douleur à l'épaule b 38, `street_03` séances manquées b 57),
  fixtures complémentaires `test/fixtures/km2c2/` régénérées, tests de `test_km1c4_douleur.py` portés
  (`test/koach_km1c4_douleur_test.dart`). Écart à la liste ci-dessus : `rupture.elargissement_rien_de_special` est
  GARDÉE dans le fichier, l'asset, les défauts et les bornes, comme dans la référence (le fichier porte le SHA-256 que
  les fixtures vérifient ; la retirer change la référence) ; le code Dart ne la lit plus et son validateur l'admet sans
  l'exiger. `Seances._semaine_connue` (appelée nulle part dans la référence) n'est pas portée.

## Delta 1.0.5 → 1.0.6 (lot KM4, 19/10/2026 ; portage dans le même lot, `kalis_adapt` 1.0.5)

- `seance.dart` : `prescrire` en deux passes (`_item` sur toutes les lignes, puis `_planRetour`, puis `_retourGradue` et le vrai test) ; `BudgetsRetour` réécrit (`limites`, `fait`, `limiteDures`, `faitDures`, `reste`, `plan`, `cause`, `repartie`, `depasse`, tenues inchangées) ; `_UniteRetour` ; `rangRole` ; `_douleurUnite` ; `semainesManquees` (rempli par `ouvrir` depuis `contexte['manquees']`) ; raison `koach.retour_gradue` avec `ecrites` et `douleur`. Ligne pour ligne : arrondi du plancher `(écrit × part − 1e-9).ceil()`, comparaison `m / n` en double, égalités départagées par la séance puis la ligne la plus tardive, excès comparés à `1e-9`.
- `parametres.dart` : `koachVersion` et `koachParametresVersion` `1.0.6-ref.1`, asset `koach_params_1_0_6.json` (copie à l'octet de `params/koach_params_v1.json`), SHA-256, 346 clés.
- `rupture.dart` : `elargissement_rien_de_special` retirée des défauts et des bornes.
- `koach_textes.dart` : « N séries au lieu de M » quand `ecrites` > `series` (sens des autres textes inchangé).
- Banc : `_pkItemsVolume(items, roles)`, `kmMesureRampe`, `rampe` dans le résultat de saison (`kmMesureDeSaison`), `tool/kr1_securite.py` (`rampe_principaux`).
- Tests : `test/koach_km4_retour_test.dart` (port des 11 tests de `tests/test_km4_retour.py`), `koach_parametres_test.dart`, `koach_textes_test.dart` ; fixtures régénérées.
