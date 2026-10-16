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
