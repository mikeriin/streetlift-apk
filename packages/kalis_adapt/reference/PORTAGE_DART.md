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
