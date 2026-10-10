# Portage Dart du banc Koach (lot KM2) — interfaces partagées

Les modules Python du banc (`packages/kalis_adapt/reference/banc/*.py`) sont portés dans
`packages/kalis_bench/lib/src/km/` (bibliothèque `kalis_bench`, Dart pur : **aucun
`dart:io` dans `lib/`** — la lecture et l'écriture de fichiers se font dans `bin/`).
Conventions de portage : celles de `reference/PORTAGE_DART.md` (port ligne pour ligne,
mêmes opérations flottantes, `vrai`/`ou`/`dbl`/`ent`/`jm`/`jl`…, records, `pw`), sauf
que chaque fichier est une **bibliothèque ordinaire** (pas un `part`) : importer le
moteur avec un préfixe, `import 'package:kalis_adapt/koach.dart' as kc;`, et les
outils JSON par `kc.dbl`, `kc.vrai`, etc. (ou les redéfinir localement en privé).

Le moteur Dart (`package:kalis_adapt/koach.dart`) est le portage validé de `koach/`
(parité 1e-9 sur les 13 fixtures). Différence voulue avec la référence (contrat,
constats M6 et M7) : **la façade applique elle-même les crochets d'extension**, dans
l'ordre de `koach.extensions` :

- `observe({'type': 'reference', 'blocs', 'block_weeks', 'horizon', 'cibles',
  'echeance_jour', 'echeances_par_semaine', 'principaux', 'poids_corps',
  'cibles_tentatives', 'semaine'})` : pour chaque extension `Planification`,
  `chargerReference(...)`, puis `replanifier(koach, semaine)` et note de la prévision
  (`Planification.previsions`, mêmes clés que `PlanificationCampagne.previsions` :
  `semaine`, `echeance`, `p`, `p_tout`, `cibles`). `echeances_par_semaine` =
  `saison['eventDaysByWeek']` : chaque lundi, l'échéance est relue comme
  `planification_banc.echeance_de(saison, w, 7 * w)`. `cibles` = `cibles_du_profil(profil,
  fiches)` (charge TOTALE), `cibles_tentatives` = `{exerciseId: targetValue}` des buts
  `one_rm_kg` (ce que `PolitiqueKoach.cibles` met en `koachCible`).
- `observe({'type': 'cibles', 'semaine', 'cibles', 'cibles_tentatives'})` :
  `PlanificationBanc.changement_profil` + `PolitiqueKoach.changement_profil`.
- `seance_debut.contexte` porte en plus `jour_index` (= `ctx.jour_index`, indice du
  jour dans la semaine) : la façade s'en sert pour `Planification.appliquer(semaine,
  jour_index, items)`.
- `plan({'horizon': 'seance', items: <items ÉCRITS du jour>, ...})` : la façade applique
  `Planification.appliquer` (modulation), `Surveillance.appliquerAllegement` (semaine
  allégée), `ControleDual.itemsDuJour` (bras A, = `ControleDualBanc.items_du_jour`, le
  journal de l'extension est `ControleDual.journal`), puis pose `koachCible` sur les
  items de test des exercices de `cibles_tentatives`. **L'appelant passe donc les items
  écrits bruts** (`ctx.ecrit['items']`), sans `items_du_jour` ni `koachCible`.
- `plan({'horizon': 'serie', ...})` : la façade applique `ControleDual.cibleSerie`
  (bras B, = `ControleDualBanc.cible_serie`). La sortie peut porter en plus une clé
  `proposition` (forme d'adhérence, informative : ne change rien d'autre).
- Restent au banc (simulateur de l'utilisateur, à porter dans `kalis_bench`) : la réponse
  au diagnostic (`VeriteScenario.reponse`, puis `koach.observe({'type': 'decision',
  'jour', 'diagnostic': rep})` à la séance qui suit une alerte, AVANT `plan`, comme
  `SurveillanceBanc.items_du_jour`), l'utilisateur simulé de l'adhérence
  (`UtilisateurSimule`, `AdherenceBanc.apres_semaine` / `_proposer`), la proposition
  d'essai (`ControleDualBanc.apres_semaine`, `_contexte`), les journaux du banc
  (`SurveillanceBanc.journal`, `AdherenceBanc.journal`).

Classes du moteur à utiliser : `kc.Koach`, `kc.Planification(params, fiches,
validateur, options)` (`validateur` : `List<Json> Function(List<Json> blocs)`),
`kc.Surveillance(params)`, `kc.ControleDual(params, lifts)`, `kc.Adherence(params)`,
`kc.Grille(pas, minimum, halteres)`, `kc.Mulberry32`, `kc.fnv1a32`, `kc.normCdfK`,
`kc.calibre`, `kc.z90`, `kc.adherenceDim`, `kc.adherenceMoments`… (lire les fichiers
`packages/kalis_adapt/lib/src/koach/*.dart` pour les noms exacts).

## Fichiers et interfaces (à respecter exactement)

### `lib/src/km/meneur.dart` (port de `banc/meneur.py`)

```dart
typedef Json = Map<String, Object?>;

/// Ce que la politique reçoit pour une séance (`meneur.Contexte`).
final class KmContexte { /* champs traduits : saison, profil (Json), livre
  (ExerciseBook), blocIndex, bloc (Json), semaine, semaineBloc, jourIndex, simDay,
  bilan (Json?), lieu (String?), athlete (SimAthlete), ecrit (Json : jour écrit, clé
  'items'), genreSemaine, intention, jourEvenement (bool), budget (int?) */
  String? roleDe(String slotId); }

/// Résultat d'une saison (`meneur.Tour`) : lignes en dictionnaires, mêmes clés que la
/// référence Python.
final class KmTour {
  KmTour(this.cle, this.scenario, this.kind, this.seed, this.politique);
  final String cle; final String scenario; final String kind; final int seed;
  final String politique;
  final List<Json> sets = [];        // clés de `tour.sets` de meneur.py
  final List<Json> estimates = [];   // clés de `tour.estimates`
  int sessionsPlanned = 0; int sessionsDone = 0;
  int painAggravations = 0; int painFlares = 0; int enduranceOveruse = 0;
  double worstRunSpike = 0.0;
  final Map<String, double> gain = {}; final Map<String, double> cap0 = {};
  final Map<String, double> capFin = {};
  final List<Json> journal = [];     // séances (record), si garderJournal
  final List<Json> predictions = [];
  final List<(int, int, int, int, List<Json>)> servi = [];
  final Json extra = {};
}

/// Interface d'une politique du banc (`meneur.Politique`), mêmes méthodes.
abstract class KmPolitique {
  String get nom;
  void debut(Json saison, Json profil, ExerciseBook livre) {}
  void changementProfil(int semaine, Json profil) {}
  void debutSemaine(int semaine) {}
  void seanceManquee(int semaine, int simDay) {}
  Json planifier(KmContexte ctx);            // {'items': [...]}
  Json? prochaineSerie(KmContexte ctx, Json item, int index, List<Json> done);
  void cranChange(String exId, int change) {}
  void terminer(KmContexte ctx, Json record) {}
  List<double>? estimer(String exId, double n) => null;   // (cap, sd, op, bas, haut)
  void finSemaine(int semaine, KmTour tour) {}
  void fin(KmTour tour) {}
}

/// `meneur.simuler` : [saison] = export `kmReferenceSeason` (Dart, même JSON que
/// `donnees/reference/*.json.gz`), vérité [kind] ∈ {'a','b','c'}, graine [seed].
KmTour kmSimuler(Catalog catalog, Json saison, KmPolitique politique, String kind,
    int seed, {Json? specJson, bool garderJournal = false,
    Map<String, Map<String, double>>? surcharges});
```

Le meneur Python est lui-même un portage de `simulate` (`kalis_adapt/lib/src/sim/runner.dart`)
pour une saison JSON ; ses appels à l'athlète simulé (`verite.py`, `verite_endurance.py`,
`alea.py`) sont des portages des classes Dart `SimAthlete`, `TruthExercise`,
`EnduranceTruth`, `SimRandom` (`package:kalis_adapt/simulation.dart`) : **utiliser ces
classes Dart** (et `ExerciseBook(catalog, AthleteProfile.fromJson(profil))` pour
`make_book`). Si un membre lu par le meneur Python n'est pas public côté Dart, l'ajouter
dans `kalis_adapt/lib/src/sim/` comme accesseur public **purement additif** (aucun
changement de comportement de 0.3.1) et le dire dans le rapport.

### `lib/src/km/politique_koach.dart` (port de `politique_koach.py`, `extensions_koach.py`, `planification_banc.py`)

`PolitiqueKoach implements KmPolitique` (nom `koach_1_0`), avec les extensions du moteur
montées dans l'ordre de la campagne : `Planification` (validateur = constats de sécurité
des blocs, voir `kmSafetyOfBlocks` / `securite_banc.constats_saison` : le validateur du
banc Dart), `Surveillance`, `ControleDual`, `Adherence` ; les parties « utilisateur
simulé » de `extensions_koach.py` sont des membres de la politique.

```dart
final class PolitiqueKoach implements KmPolitique {
  PolitiqueKoach({required Catalog catalog, required Json parametres,
    required Map<String, Json> fiches, int graine = 0,
    List<String> briques = const ['planification', 'surveillance', 'dual', 'adherence'],
    int trajectoires = 1000, bool raisons = false, Json? optionsDual});
  late kc.Koach koach;
  kc.Planification? get planification;    // null sans planificateur
  List<Json> get previsions;               // Planification.previsions ([] sinon)
  Map<String, Object?> journaux();         // journaux du banc (SurveillanceBanc, ControleDual, AdherenceBanc)
  Map<String, Object?> etats();            // etat_complet / etat des extensions
  Map<String, kc.Grille> get grilles;
  ...
}
```
(`parametres` : fichier de paramètres Koach décodé ; `fiches` : `vecteurs_qualites_v1.json`
champ `exercices`.)

### `lib/src/km/campagne.dart` (port de `campagne.py`, `criteres_moteur.py`, `mesures.py`)

Critères du cahier mesurés sur des `KmTour` (Koach) et sur le témoin `kalis_adapt` 0.3.1
(`kmWitnessSeason` de `km_export.dart`, déjà en Dart : même JSON que
`donnees/temoin/*.json.gz`). Fonctions pures ; l'exécution (boucle sur la matrice,
isolates, fichiers, temps) est dans `bin/km2.dart`.

### `lib/src/km/adversaire.dart` (port de `adversaire.py`)

Espace adversarial, recherche (μ+λ), évaluation contre le témoin (`kmAdversaryRun`).
