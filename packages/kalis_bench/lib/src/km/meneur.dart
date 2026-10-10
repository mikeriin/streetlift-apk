/// Meneur de saison du banc Koach (lot KM2) : portage ligne pour ligne de
/// `kalis_adapt/reference/banc/meneur.py`, lui-même portage de `simulate`
/// (`kalis_adapt/lib/src/sim/runner.dart`, 0.3.1) pour une politique qui
/// lit et écrit du JSON (séances au format du contrat de `kalis_core`).
///
/// Mêmes clés d'aléas que le meneur de `kalis_adapt` (calendrier, effets de
/// jour, séries) : à graine égale, l'athlète simulé, ses absences, sa
/// maladie et sa douleur sont ceux que le témoin 0.3.1 a rencontrés. La
/// saison servie est la saison de référence exportée par `kmReferenceSeason`.
/// L'athlète simulé est celui de `package:kalis_adapt/simulation.dart`
/// ([SimAthlete], [TruthExercise], [EnduranceTruth], [SimRandom]), dont
/// `banc/verite.py`, `banc/verite_endurance.py` et `banc/alea.py` sont les
/// portages Python.
///
/// Les lignes `KmTour.sets` et `KmTour.estimates` ont exactement les clés et
/// les valeurs de la référence Python (types JSON conservés : un entier reste
/// un entier).
///
/// Dart pur : aucun accès disque.
library;

import 'dart:math' as math;

import 'package:kalis_adapt/kalis_adapt.dart'
    show CapacityMode, ExerciseBook, ExerciseInfo, enduranceKindOf;
import 'package:kalis_adapt/koach.dart' as kc;
import 'package:kalis_adapt/simulation.dart'
    show
        AthleteSpec,
        EnduranceDone,
        EnduranceTruth,
        SetOutcome,
        SimAthlete,
        SimRandom,
        TruthExercise,
        TruthKind,
        athleteFromJson;
import 'package:kalis_core/kalis_core.dart'
    show
        AthleteProfile,
        BodyZone,
        Catalog,
        ExercisePrescription,
        HealthCheck,
        IntensityTarget,
        LoadBasis,
        Reason;

/// Objet JSON (dictionnaire Python).
typedef Json = Map<String, Object?>;

// ---------------------------------------------------------------------------
// Outils (sémantique Python)
// ---------------------------------------------------------------------------

/// `d.get(k, defaut)` : la valeur de la clé si elle est présente (même
/// nulle), sinon [defaut].
Object? _meGet(Json d, String k, Object? defaut) =>
    d.containsKey(k) ? d[k] : defaut;

/// `flames_to_rir` (`banc/alea.py`).
double _meFlammesVersRir(num flames) =>
    flames == 10 ? 0.0 : (11 - flames) / 2.0;

/// Entier JSON attendu par l'athlète simulé de `kalis_adapt` (types
/// entiers) : un nombre non entier n'y a pas d'équivalent (la référence
/// Python le garderait en flottant) et est refusé.
int _meEnt(Object? v, String quoi) {
  if (v is int) {
    return v;
  }
  if (v is double && v == v.truncateToDouble() && v.isFinite) {
    return v.toInt();
  }
  throw ArgumentError.value(v, quoi, 'entier attendu par la vérité simulée');
}

int? _meEntOu(Object? v, String quoi) => v == null ? null : _meEnt(v, quoi);

/// Prescription typée de `kalis_core` pour la vérité d'endurance (qui ne lit
/// que l'exercice, les durées, distances, répétitions, calories, les
/// flammes visées et la présence d'une intensité).
ExercisePrescription _mePrescription(Json item) {
  final intensite = item['intensity'];
  return ExercisePrescription(
    slotId: item['slotId']! as String,
    exerciseId: item['exerciseId']! as String,
    sets: _meEnt(_meGet(item, 'sets', 0), 'sets'),
    repsLow: _meEntOu(item['repsLow'], 'repsLow'),
    repsHigh: _meEntOu(item['repsHigh'], 'repsHigh'),
    secondsLow: _meEntOu(item['secondsLow'], 'secondsLow'),
    secondsHigh: _meEntOu(item['secondsHigh'], 'secondsHigh'),
    distanceMeters: kc.dblOu(item['distanceMeters']),
    calories: kc.dblOu(item['calories']),
    targetFlames: _meEntOu(item['targetFlames'], 'targetFlames'),
    toCalibrate: false,
    loadBasis: LoadBasis.external,
    reasons: const <Reason>[],
    intensity: intensite == null
        ? null
        : IntensityTarget.fromJson(kc.jm(intensite)),
  );
}

/// Ce que la vérité d'endurance a fait d'une ligne (`made` de la référence).
Json _meFait(EnduranceDone d) => <String, Object?>{
  'sets': d.sets,
  'seconds': d.seconds,
  'distanceMeters': d.distanceMeters,
  'reps': d.reps,
  'calories': d.calories,
  'flames': d.flames,
  'success': d.success,
};

// ---------------------------------------------------------------------------
// Contexte, tour, politique
// ---------------------------------------------------------------------------

/// Ce que la politique reçoit pour une séance (`meneur.Contexte`,
/// `SessionContext` de `kalis_adapt`).
final class KmContexte {
  /// Contexte de la séance [jourIndex] de la semaine [semaine].
  KmContexte({
    required this.saison,
    required this.profil,
    required this.livre,
    required this.blocIndex,
    required this.bloc,
    required this.semaine,
    required this.semaineBloc,
    required this.jourIndex,
    required this.simDay,
    required this.bilan,
    required this.lieu,
    required this.athlete,
    required this.ecrit,
    required this.genreSemaine,
    required this.intention,
    required this.jourEvenement,
    required this.budget,
  });

  /// Saison (export `kmReferenceSeason`).
  final Json saison;

  /// Profil des moteurs en vigueur (JSON).
  final Json profil;

  /// Fiches des exercices (grilles du profil de départ).
  final ExerciseBook livre;

  /// Rang du bloc.
  final int blocIndex;

  /// Bloc (JSON de `ProgramBlock`).
  final Json bloc;

  /// Semaine de la saison (0 = première).
  final int semaine;

  /// Semaine dans le bloc.
  final int semaineBloc;

  /// Indice du jour dans la semaine (`dayIndex`).
  final int jourIndex;

  /// Jour de la simulation (0 = premier lundi).
  final int simDay;

  /// Bilan santé du jour (JSON du contrat), ou `null`.
  final Json? bilan;

  /// Autre lieu d'entraînement (code), ou `null`.
  final String? lieu;

  /// Athlète simulé : réservé aux mesures et à l'utilisateur simulé du
  /// banc (la politique ne le lit pas pour prescrire).
  final SimAthlete athlete;

  /// Prescription écrite du jour (bloc de référence), clé `items`.
  final Json ecrit;

  /// Nature de la semaine (`kind`).
  final Object? genreSemaine;

  /// Intention de la semaine (`intent`).
  final Object? intention;

  /// Séance du jour d'une échéance.
  final bool jourEvenement;

  /// Durée prévue de la séance, en minutes.
  final int? budget;

  /// Rôle de l'emplacement [slotId] dans le bloc (`role_de`), ou `null`.
  String? roleDe(String slotId) {
    for (final d in kc.jl(kc.jm(bloc['pass1'])['days'])) {
      for (final s in kc.jl(kc.jm(d)['slots'])) {
        final sm = kc.jm(s);
        if (sm['slotId'] == slotId) {
          return sm['role'] as String?;
        }
      }
    }
    return null;
  }
}

/// Résultat d'une saison simulée (`meneur.Tour`, `SimRun` réduit à ce que
/// les mesures lisent) : lignes en dictionnaires, mêmes clés que la
/// référence Python.
final class KmTour {
  /// Tour de la saison [cle] sous [scenario], vérité [kind], graine [seed].
  KmTour(this.cle, this.scenario, this.kind, this.seed, this.politique);

  /// Clé du profil.
  final String cle;

  /// Scénario.
  final String scenario;

  /// Modèle de vérité (`a`, `b`, `c`).
  final String kind;

  /// Graine.
  final int seed;

  /// Nom de la politique.
  final String politique;

  /// Séries (clés de `tour.sets` de `meneur.py`).
  final List<Json> sets = <Json>[];

  /// Estimations (clés de `tour.estimates`).
  final List<Json> estimates = <Json>[];

  /// Séances prévues.
  int sessionsPlanned = 0;

  /// Séances faites.
  int sessionsDone = 0;

  /// Hausses de charge sur la zone douloureuse après signalement.
  int painAggravations = 0;

  /// Poussées de douleur d'une zone réactive.
  int painFlares = 0;

  /// Blessures de surcharge d'endurance.
  int enduranceOveruse = 0;

  /// Plus forte hausse d'une sortie de course.
  double worstRunSpike = 0.0;

  /// Gain de capacité vraie par semaine (`ln`), par exercice suivi trois
  /// semaines au moins.
  final Map<String, double> gain = <String, double>{};

  /// Capacité vraie au départ, par exercice entraîné.
  final Map<String, double> cap0 = <String, double>{};

  /// Capacité vraie en fin de saison, par exercice rencontré.
  final Map<String, double> capFin = <String, double>{};

  /// Séances (record JSON), si `garderJournal`.
  final List<Json> journal = <Json>[];

  /// Prédictions de P(réussite) faites par la politique.
  final List<Json> predictions = <Json>[];

  /// (semaine, bloc, semaine du bloc, jour, items servis).
  final List<(int, int, int, int, List<Json>)> servi =
      <(int, int, int, int, List<Json>)>[];

  /// Divers (`endurance` : [durée facile de départ, durée facile, WOD de
  /// départ, WOD]).
  final Json extra = <String, Object?>{};
}

/// Interface d'une politique du banc (`meneur.Politique`, `SimPolicy`).
abstract class KmPolitique {
  /// Nom.
  String get nom;

  /// Début de la saison [saison], profil [profil], fiches [livre].
  void debut(Json saison, Json profil, ExerciseBook livre) {}

  /// Profil changé au début de la semaine [semaine].
  void changementProfil(int semaine, Json profil) {}

  /// Début de la semaine [semaine].
  void debutSemaine(int semaine) {}

  /// Séance du jour [simDay] manquée.
  void seanceManquee(int semaine, int simDay) {}

  /// Séance du jour : `{'items': [...]}`.
  Json planifier(KmContexte ctx) => <String, Object?>{
    'items': ctx.ecrit['items'],
  };

  /// Cible de la série [index] de [item], ou `null` pour s'arrêter.
  Json? prochaineSerie(KmContexte ctx, Json item, int index, List<Json> done) =>
      kmCibleDe(item, index);

  /// L'athlète a changé de cran d'élastique sur [exId].
  void cranChange(String exId, int change) {}

  /// Fin de la séance (record JSON).
  void terminer(KmContexte ctx, Json record) {}

  /// (capacité, écart-type relatif, opérationnelle, bas, haut) de [exId]
  /// pour [n] répétitions à la réserve visée, ou `null`.
  List<double>? estimer(String exId, double n) => null;

  /// Fin de la semaine [semaine].
  void finSemaine(int semaine, KmTour tour) {}

  /// Fin de la saison.
  void fin(KmTour tour) {}
}

/// Mesure d'une prescription (`mesure_de`) : 1 secondes, 0 répétitions,
/// 2 autre.
int kmMesureDe(Json item) {
  if (item['secondsHigh'] != null || item['secondsLow'] != null) {
    return 1;
  }
  if (item['repsHigh'] != null || item['repsLow'] != null) {
    return 0;
  }
  return 2;
}

/// Cible de la série [index] d'une prescription (`cible_de`,
/// `targetOfItem`).
Json kmCibleDe(Json item, int index) {
  final targets = item['setTargets'];
  if (kc.vrai(targets)) {
    final tl = kc.jl(targets);
    final t = kc.jm(tl[index < tl.length ? index : tl.length - 1]);
    Object? pick(String k, [String? k2]) {
      final v = t[k];
      return v == null ? item[k2 ?? k] : v;
    }

    return <String, Object?>{
      'repsLow': pick('repsLow'),
      'repsHigh': pick('repsHigh'),
      'secondsLow': pick('secondsLow'),
      'secondsHigh': pick('secondsHigh'),
      'loadKg': t['loadKg'] ?? item['startLoadKg'],
      'flames': pick('flames', 'targetFlames'),
      'role': t['role'],
    };
  }
  return <String, Object?>{
    'repsLow': item['repsLow'],
    'repsHigh': item['repsHigh'],
    'secondsLow': item['secondsLow'],
    'secondsHigh': item['secondsHigh'],
    'loadKg': item['startLoadKg'],
    'flames': item['targetFlames'],
    'role': null,
  };
}

// ---------------------------------------------------------------------------
// Saison
// ---------------------------------------------------------------------------

/// `meneur.simuler` : simule la saison [saison] (export `kmReferenceSeason`,
/// décodé du JSON) pour la politique [politique] sous le modèle de vérité
/// [kind] (`a`, `b` ou `c`) et la graine [seed].
///
/// [specJson] remplace la fiche de l'athlète (banc adversarial) ;
/// [surcharges] : identifiant d'exercice (ou `*`) → multiplicateurs
/// appliqués à la vérité d'un exercice à sa création (`capacity`,
/// `curveB`, `slope`, `power`, `fatigueScale`, `holdShare`).
KmTour kmSimuler(
  Catalog catalog,
  Json saison,
  KmPolitique politique,
  String kind,
  int seed, {
  Json? specJson,
  bool garderJournal = false,
  Map<String, Map<String, double>>? surcharges,
}) {
  final AthleteSpec spec = athleteFromJson(
    specJson ?? kc.jm(saison['specJson']),
  );
  final profils = kc.jl(saison['profiles']);
  final profil = kc.jm(kc.jm(profils[0])['profile']);
  final livre = ExerciseBook(catalog, AthleteProfile.fromJson(profil));
  final truthKind = TruthKind.values.byName(kind);
  final athlete = SimAthlete(
    spec,
    AthleteProfile.fromJson(profil),
    livre,
    seed,
    kind: truthKind,
  );
  // `_surcharger` de la référence : la vérité d'un exercice est surchargée
  // la première fois que le meneur la demande (le meneur est seul à
  // appeler `truthOf` : les identifiants déjà demandés sont ceux que
  // l'athlète connaît).
  final connus = <String>{};
  TruthExercise? truthOf(String exId) {
    final connu = connus.contains(exId);
    connus.add(exId);
    final t = athlete.truthOf(exId);
    final sur = surcharges;
    if (sur != null && sur.isNotEmpty && t != null && !connu) {
      final exact = sur[exId];
      final m = (exact == null || exact.isEmpty) ? sur['*'] : exact;
      if (m != null && m.isNotEmpty) {
        t.capacity *= m['capacity'] ?? 1.0;
        t.startCapacity = t.capacity;
        t.curveB *= m['curveB'] ?? 1.0;
        t.slope *= m['slope'] ?? 1.0;
        t.power *= m['power'] ?? 1.0;
        t.fatigueScale *= m['fatigueScale'] ?? 1.0;
        t.holdShare *= m['holdShare'] ?? 1.0;
      }
    }
    return t;
  }

  final endurance = EnduranceTruth(truthKind, spec.level, seed);
  final tour = KmTour(
    saison['key']! as String,
    saison['scenario']! as String,
    kind,
    seed,
    politique.nom,
  );
  final blocs = kc.jl(saison['blocks']);
  final exerciseSessions = <String, int>{};
  final bandNotch = <String, int>{};
  final lastMaxLoad = <String, num>{};
  final schemeLoad = <String, num>{};
  final weeks = kc.ent(saison['weeks']);
  final parSemaine = <int, List<(int, int, int, int)>>{};
  for (final s0 in kc.jl(saison['sessions'])) {
    final s = kc.jl(s0);
    parSemaine
        .putIfAbsent(kc.ent(s[0]), () => <(int, int, int, int)>[])
        .add((kc.ent(s[1]), kc.ent(s[2]), kc.ent(s[3]), kc.ent(s[4])));
  }
  politique.debut(saison, profil, livre);
  var courant = profil;
  final eventDaysByWeek = kc.jl(saison['eventDaysByWeek']);
  for (var g = 0; g < weeks; g++) {
    for (final ch0 in profils.skip(1)) {
      final ch = kc.jm(ch0);
      if (kc.ent(ch['week']) == g) {
        courant = kc.jm(ch['profile']);
        politique.changementProfil(g, courant);
      }
    }
    final eventDays = <int>{
      for (final d in kc.jl(eventDaysByWeek[g])) kc.ent(d),
    };
    politique.debutSemaine(g);
    for (final (bi, wb, di, simDay)
        in parSemaine[g] ?? const <(int, int, int, int)>[]) {
      final bloc = kc.jm(blocs[bi]);
      Json? semaine0;
      for (final w in kc.jl(kc.jm(bloc['pass2'])['weeks'])) {
        if (kc.jm(w)['weekIndex'] == wb) {
          semaine0 = kc.jm(w);
        }
      }
      final semaine = semaine0!;
      Json? ecrit0;
      for (final d in kc.jl(semaine['days'])) {
        if (kc.jm(d)['dayIndex'] == di) {
          ecrit0 = kc.jm(d);
        }
      }
      final ecrit = ecrit0!;
      tour.sessionsPlanned += 1;
      final calendar = SimRandom.of(seed, 'calendar|$simDay');
      final bf = spec.breakFromDay;
      if (bf != null && simDay >= bf && simDay < bf + spec.breakDays) {
        politique.seanceManquee(g, simDay);
        continue;
      }
      if (calendar.next() < spec.missRate) {
        politique.seanceManquee(g, simDay);
        continue;
      }
      athlete.advance(simDay);
      final budget = kc.ent(
        kc.jm(kc.jl(kc.jm(bloc['pass1'])['days'])[di])['minutesBudget'],
      );
      final HealthCheck? sante = athlete.healthCheck(budget);
      final Json? bilan = sante?.toJson();
      final autre = spec.otherPlaceFromDay;
      final String? lieu =
          (autre != null &&
              simDay >= autre &&
              simDay < autre + spec.otherPlaceDays)
          ? spec.otherPlace?.code
          : null;
      final ctx = KmContexte(
        saison: saison,
        profil: courant,
        livre: livre,
        blocIndex: bi,
        bloc: bloc,
        semaine: g,
        semaineBloc: wb,
        jourIndex: di,
        simDay: simDay,
        bilan: bilan,
        lieu: lieu,
        athlete: athlete,
        ecrit: ecrit,
        genreSemaine: semaine['kind'],
        intention: semaine['intent'],
        jourEvenement: eventDays.contains(simDay),
        budget: budget,
      );
      final seance = politique.planifier(ctx);
      final done = <Json>[];
      final trained = <(TruthExercise, Json)>[];
      var order = 0;
      final ecrits = <Json>[for (final it in kc.jl(ecrit['items'])) kc.jm(it)];
      final servis = <Json>[for (final it in kc.jl(seance['items'])) kc.jm(it)];
      for (final item in servis) {
        final exId = item['exerciseId']! as String;
        final truth = truthOf(exId);
        final measure = kmMesureDe(item);
        final ExerciseInfo? info = livre.find(exId);
        final String? eKind = (truth != null || info == null)
            ? null
            : enduranceKindOf(info)?.name;
        final setsN = _meEnt(_meGet(item, 'sets', 0), 'sets');
        if (truth == null &&
            (eKind == 'run' || eKind == 'conditioning') &&
            item['kind'] != 'warmup' &&
            setsN > 0) {
          final rates =
              SimRandom.of(seed, 'rate|$simDay|$exId').next() >= spec.lazy;
          final (EnduranceDone, BodyZone?) resultat;
          if (eKind == 'run') {
            resultat = endurance.run(
              _mePrescription(item),
              setsN,
              simDay,
              0,
              ill: athlete.ill,
              rates: rates,
            );
          } else {
            var written = item;
            for (final it in ecrits) {
              if (it['slotId'] == item['slotId']) {
                written = it;
              }
            }
            final wr = (written['repsHigh'] ?? written['secondsHigh']) as num?;
            final sr = (item['repsHigh'] ?? item['secondsHigh']) as num?;
            final wSets = kc.dbl(_meGet(written, 'sets', 0));
            final num ws = wSets <= 0 ? 1 : written['sets']! as num;
            final double share = (wr == null || sr == null || wr <= 0)
                ? 1.0
                : (sr / wr) * (setsN / ws);
            resultat = endurance.wodPiece(
              _mePrescription(item),
              setsN,
              simDay,
              0,
              ill: athlete.ill,
              rates: rates,
              hardDaysBefore: endurance.hardStreakBefore(simDay),
              writtenShare: share > 1 ? 1.0 : share,
            );
          }
          final (fait, injured) = resultat;
          final made = _meFait(fait);
          if (injured != null) {
            athlete.overuse(injured, 4, 14);
          }
          for (var i = 0; i < fait.sets; i++) {
            done.add(<String, Object?>{
              'exerciseId': exId,
              'exerciseOrder': order,
              'setIndex': i,
              'kind': kc.ou(item['kind'], 'work'),
              'reps': made['reps'],
              'seconds': made['seconds'],
              'distanceMeters': made['distanceMeters'],
              'calories': made['calories'],
              'flames': made['flames'],
              'success': made['success'],
              'slotId': item['slotId'],
              'enduranceKind': eKind,
              'item': item,
            });
          }
          order += 1;
          continue;
        }
        if (truth == null || measure == 2) {
          final reps = item['repsHigh'] ?? item['repsLow'];
          final seconds = item['secondsHigh'] ?? item['secondsLow'];
          if (reps != null ||
              seconds != null ||
              item['distanceMeters'] != null ||
              item['calories'] != null) {
            for (var i = 0; i < setsN; i++) {
              done.add(<String, Object?>{
                'exerciseId': exId,
                'exerciseOrder': order,
                'setIndex': i,
                'kind': kc.ou(item['kind'], 'work'),
                'reps': reps,
                'seconds': reps == null ? seconds : null,
                'flames': item['targetFlames'],
                'success': true,
                'slotId': item['slotId'],
                'nonModelise': true,
              });
            }
          }
          order += 1;
          continue;
        }
        final hold = truth.mode == CapacityMode.hold;
        final loaded = truth.mode == CapacityMode.loaded;
        if (hold != (measure == 1)) {
          order += 1;
          continue;
        }
        final slotId = item['slotId']! as String;
        athlete.beginExercise(truth, slotId);
        double? assistKg;
        if (truth.mode == CapacityMode.reps && info!.exercise.assisted) {
          var notch = bandNotch[exId] ?? 3;
          final change = kc.ent(_meGet(item, 'assistChange', 0));
          if ((change < 0 && notch > 0) || (change > 0 && notch < 6)) {
            final step =
                0.75 *
                math.exp(
                  0.12 *
                      SimRandom.of(
                        seed,
                        'band|$exId|${change < 0 ? notch : notch + 1}',
                      ).gauss(),
                );
            final factor = change < 0 ? step : 1 / step;
            truth.capacity *= factor;
            truth.startCapacity *= factor;
            truth.firstCapacity *= factor;
            notch += change;
            politique.cranChange(exId, change);
          }
          bandNotch[exId] = notch;
          assistKg = -10.0 * notch;
        }
        var basis = item;
        for (final it in ecrits) {
          if (it['slotId'] == slotId && it['exerciseId'] == exId) {
            basis = it;
          }
        }
        final basisLow = (hold ? basis['secondsLow'] : basis['repsLow']) as num?;
        final basisHigh =
            (hold ? basis['secondsHigh'] : basis['repsHigh']) as num?;
        final count = exerciseSessions[exId] ?? 0;
        final role = ctx.roleDe(slotId);
        final num rest = kc.ou(item['restSeconds'], 90)! as num;
        final technique = kc.jmOu(item['technique']);
        final isTest = item['kind'] == 'test' || basis['kind'] == 'test';
        final Object? testKind = isTest
            ? kc.dictOuVide(kc.ou(item['test'], basis['test']))['kind']
            : null;
        final isAttempt =
            testKind == 'one_rm' || testKind == 'attempt_simulation';
        var performed = 0;
        num? sessionMax;
        for (var i = 0; i < setsN; i++) {
          final target = politique.prochaineSerie(ctx, item, i, done);
          if (target == null) {
            break;
          }
          var flamesTarget0 = target['flames'];
          flamesTarget0 ??= item['targetFlames'];
          flamesTarget0 ??= 6;
          final num flamesTarget = flamesTarget0 as num;
          final flamesInt = _meEnt(flamesTarget, 'flames');
          var low = (hold ? target['secondsLow'] : target['repsLow']) as num?;
          var high = (hold ? target['secondsHigh'] : target['repsHigh']) as num?;
          low ??= high;
          high ??= low;
          if (low == null || high == null) {
            break;
          }
          num? load;
          var selfSelected = false;
          if (loaded) {
            load = target['loadKg'] as num?;
            if (load == null) {
              load = athlete.selfSelect(
                truth,
                _meEnt(high, 'high'),
                _meFlammesVersRir(flamesTarget),
              );
              selfSelected = true;
            }
          }
          final double? loadD = load?.toDouble();
          final restI = _meEnt(rest, 'restSeconds');
          final key = '$simDay|$slotId|$i';
          final lineRole = target['role'];
          final Object? tk = technique?['kind'];
          final applies =
              technique != null &&
              (technique['lastSetOnly'] != true || i == setsN - 1);
          final Object? served = applies ? tk : null;
          final dayMax = truth.capacity * math.exp(truth.day);
          var plannedFailure = flamesTarget >= 10;
          List<Json>? parts;
          int? elapsed;
          SetOutcome outcome;
          if (lineRole == 'attempt') {
            outcome = athlete.perform(
              truth,
              loadKg: loadD,
              low: 1,
              high: 1,
              flamesTarget: flamesInt,
              restSeconds: restI,
              noiseKey: key,
            );
            plannedFailure = true;
          } else if (lineRole == 'test' &&
              ((!loaded) || high > low) &&
              flamesTarget >= 8) {
            outcome = athlete.perform(
              truth,
              loadKg: loadD,
              low: _meEnt(low, 'low'),
              high: _meEnt(high + (hold ? 600 : 200), 'high'),
              flamesTarget: flamesInt,
              restSeconds: restI,
              noiseKey: key,
            );
            plannedFailure = true;
          } else if (served == 'cluster' && !hold) {
            final t = technique!;
            final mini = _meEnt(kc.ou(t['miniSets'], 1), 'miniSets');
            final each = _meEnt(kc.ou(t['miniSetReps'], high), 'miniSetReps');
            final intra = _meEnt(
              kc.ou(t['intraRestSeconds'], 30),
              'intraRestSeconds',
            );
            parts = <Json>[];
            var total = 0;
            SetOutcome? last;
            for (var k = 0; k < mini; k++) {
              final o = athlete.perform(
                truth,
                loadKg: loadD,
                low: each,
                high: each,
                flamesTarget: flamesInt,
                restSeconds: k < mini - 1 ? intra : restI,
                noiseKey: '$key|$k',
              );
              last = o;
              if (o.amount >= 1) {
                parts.add(<String, Object?>{'reps': o.amount});
                total += o.amount;
              }
              if (o.failed || o.amount < each) {
                break;
              }
            }
            outcome = SetOutcome(
              amount: total,
              flames: last?.flames,
              trueRir: last == null ? 0.0 : last.trueRir,
              failed: last == null ? false : last.failed,
            );
            low = mini * each;
            high = mini * each;
          } else if ((served == 'rest_pause' || served == 'myo_reps') &&
              !hold) {
            final t = technique!;
            final myo = served == 'myo_reps';
            final intra = _meEnt(
              kc.ou(t['intraRestSeconds'], myo ? 15 : 20),
              'intraRestSeconds',
            );
            final cap = _meEnt(kc.ou(t['miniSets'], myo ? 5 : 2), 'miniSets');
            final each = _meEnt(kc.ou(t['miniSetReps'], 3), 'miniSetReps');
            final goal = t['totalRepsTarget'] as num?;
            final first = athlete.perform(
              truth,
              loadKg: loadD,
              low: _meEnt(low, 'low'),
              high: _meEnt(high, 'high'),
              flamesTarget: flamesInt,
              restSeconds: intra,
              noiseKey: key,
            );
            parts = first.amount >= 1
                ? <Json>[
                    <String, Object?>{'reps': first.amount},
                  ]
                : <Json>[];
            var total = first.amount;
            if (!first.failed) {
              for (var k = 1; k < cap + 1; k++) {
                if (goal != null && total >= goal) {
                  break;
                }
                final o = athlete.perform(
                  truth,
                  loadKg: loadD,
                  low: myo ? each : 1,
                  high: myo ? each : _meEnt(high, 'high'),
                  flamesTarget: 9,
                  restSeconds: k < cap ? intra : restI,
                  noiseKey: '$key|$k',
                );
                if (o.amount < 1) {
                  break;
                }
                parts.add(<String, Object?>{'reps': o.amount});
                total += o.amount;
                if (o.failed || (myo && o.amount < each)) {
                  break;
                }
              }
            }
            outcome = SetOutcome(
              amount: total,
              flames: first.flames,
              trueRir: first.trueRir,
              failed: first.failed,
            );
            if (parts.isEmpty) {
              parts = null;
            }
          } else if (served == 'drop_set' && loaded && load != null) {
            final t = technique!;
            final drops = _meEnt(kc.ou(t['drops'], 1), 'drops');
            final num pct = kc.ou(t['dropPct'], 0.2)! as num;
            final first = athlete.perform(
              truth,
              loadKg: loadD,
              low: _meEnt(low, 'low'),
              high: _meEnt(high, 'high'),
              flamesTarget: flamesInt,
              restSeconds: 10,
              noiseKey: key,
            );
            parts = first.amount >= 1
                ? <Json>[
                    <String, Object?>{
                      'reps': first.amount,
                      'externalLoadKg': load,
                    },
                  ]
                : <Json>[];
            var total = first.amount;
            final bw = truth.info.fraction * athlete.bodyWeightKg;
            num kg = load;
            if (!first.failed) {
              for (var k = 1; k < drops + 1; k++) {
                var nxt = truth.info.grid.floor(
                  ((kg + bw) * (1 - pct) - bw).toDouble(),
                );
                if (nxt < truth.info.grid.minimum) {
                  nxt = truth.info.grid.minimum;
                }
                if (nxt >= kg) {
                  break;
                }
                kg = nxt;
                final o = athlete.perform(
                  truth,
                  loadKg: nxt,
                  low: 1,
                  high: _meEnt(high + 10, 'high'),
                  flamesTarget: 9,
                  restSeconds: k < drops ? 10 : restI,
                  noiseKey: '$key|$k',
                );
                if (o.amount < 1) {
                  break;
                }
                parts.add(<String, Object?>{
                  'reps': o.amount,
                  'externalLoadKg': kg,
                });
                total += o.amount;
              }
            }
            outcome = SetOutcome(
              amount: total,
              flames: first.flames,
              trueRir: first.trueRir,
              failed: first.failed,
            );
            if (parts.isEmpty) {
              parts = null;
            }
          } else if (served == 'accentuated_eccentric') {
            outcome = athlete.performEccentric(
              truth,
              loadKg: loadD,
              low: _meEnt(low, 'low'),
              high: _meEnt(high, 'high'),
              flamesTarget: flamesInt,
              restSeconds: restI,
              noiseKey: key,
            );
          } else if ((served == 'density' || served == 'for_time') && !hold) {
            final t = technique!;
            final goal = _meEnt(kc.ou(t['totalRepsTarget'], high), 'goal');
            final limit = t['durationSeconds'] as num?;
            parts = <Json>[];
            var total = 0;
            var seconds = 0;
            SetOutcome? last;
            var k = 0;
            while (k < 120 && total < goal) {
              var chunk = (athlete.capacityNow(truth, loadD) / 3).round();
              if (chunk < 1) {
                chunk = 1;
              }
              if (chunk > goal - total) {
                chunk = goal - total;
              }
              final o = athlete.perform(
                truth,
                loadKg: loadD,
                low: chunk,
                high: chunk,
                flamesTarget: 6,
                restSeconds: 20,
                noiseKey: '$key|$k',
              );
              last = o;
              if (o.amount < 1) {
                break;
              }
              parts.add(<String, Object?>{'reps': o.amount});
              total += o.amount;
              seconds += o.amount * 3 + 20;
              if (limit != null && seconds >= limit) {
                break;
              }
              k += 1;
            }
            elapsed = seconds > 20 ? seconds - 20 : seconds;
            outcome = SetOutcome(
              amount: total,
              flames: last?.flames,
              trueRir: last == null ? 0.0 : last.trueRir,
              failed: false,
            );
            if (parts.isEmpty) {
              parts = null;
            }
            low = total < low ? total : low;
          } else {
            outcome = athlete.perform(
              truth,
              loadKg: loadD,
              low: _meEnt(low, 'low'),
              high:
                  (served == 'amrap' && technique!['durationSeconds'] == null)
                  ? _meEnt(high + 200, 'high')
                  : _meEnt(high, 'high'),
              flamesTarget: flamesInt,
              restSeconds: restI,
              noiseKey: key,
            );
          }
          final int? quality =
              (served == 'isometric_hold' || served == 'skill_practice')
              ? athlete.qualityOf(outcome)
              : null;
          final rec = <String, Object?>{
            'exerciseId': exId,
            'exerciseOrder': order,
            'setIndex': i,
            'kind': kc.ou(item['kind'], 'work'),
            'externalLoadKg': load ?? assistKg,
            'reps': hold ? null : outcome.amount,
            'seconds': hold ? outcome.amount : null,
            'flames': outcome.flames,
            'success': (!outcome.failed) && outcome.amount >= low,
            'failed': outcome.failed,
            'slotId': slotId,
            'target': <String, Object?>{
              'repsLow': hold ? null : low,
              'repsHigh': hold ? null : high,
              'secondsLow': hold ? low : null,
              'secondsHigh': hold ? high : null,
              'loadKg': selfSelected ? null : load,
              'flames': flamesTarget,
              'role': lineRole,
            },
            'technique': served == 'standard' ? null : served,
            'role': lineRole,
            'parts': parts,
            'elapsedSeconds': elapsed,
            'quality': quality,
            'restSeconds': rest,
            'selfSelected': selfSelected,
            'repere': kc.vrai(target['repere']),
          };
          done.add(rec);
          double? rise;
          var steps = 0;
          if (i == 0 && load != null) {
            final before = lastMaxLoad[exId];
            if (before != null) {
              final bw = truth.info.fraction * athlete.bodyWeightKg;
              rise = (load + bw) / (before + bw) - 1;
              var kg = before.toDouble();
              while (kg < load - 1e-9 && steps < 50) {
                kg = truth.info.grid.next(kg, up: true);
                steps += 1;
              }
            }
          }
          double? schemeRise;
          var schemeSteps = 0;
          if (i == 0 && load != null && !isTest) {
            final sk = '$slotId|$exId|$high';
            final before = schemeLoad[sk];
            if (before != null) {
              final bw = truth.info.fraction * athlete.bodyWeightKg;
              schemeRise = (load + bw) / (before + bw) - 1;
              var kg = before.toDouble();
              while (kg < load - 1e-9 && schemeSteps < 50) {
                kg = truth.info.grid.next(kg, up: true);
                schemeSteps += 1;
              }
            }
            schemeLoad[sk] = load;
          }
          if (load != null && (sessionMax == null || load > sessionMax)) {
            sessionMax = load;
          }
          final double? totalKg = (loaded && loadD != null)
              ? truth.info.totalLoad(loadD, athlete.bodyWeightKg)
              : null;
          final num reachLow = basisLow ?? (basisHigh ?? low);
          final num reachHigh = basisHigh ?? (basisLow ?? high);
          tour.sets.add(<String, Object?>{
            'week': g,
            'weekKind': semaine['kind'],
            'exerciseId': exId,
            'mode': truth.mode.name,
            'exerciseSession': count,
            'setIndex': i,
            'loadKg': load,
            'amount': outcome.amount,
            'flames': outcome.flames,
            'trueRir': outcome.trueRir,
            'wantRir': _meFlammesVersRir(flamesTarget),
            'failed': outcome.failed,
            'plannedFailure': plannedFailure,
            'main': role == 'main',
            'open': high > low,
            'rise': rise,
            'targetLow': low,
            'targetHigh': high,
            'steps': steps,
            'reachable': athlete.reachable(
              truth,
              _meEnt(reachLow, 'low'),
              _meEnt(reachHigh, 'high'),
              _meFlammesVersRir(flamesTarget),
            ),
            'simDay': simDay,
            'slotId': slotId,
            'role': lineRole,
            'technique': served,
            'schemeRise': schemeRise,
            'schemeSteps': schemeSteps,
            'attempt': isAttempt,
            'eventDay': eventDays.contains(simDay),
            'truePct': totalKg == null ? null : totalKg / truth.capacity,
            'totalKg': totalKg,
            'dayMax': dayMax,
            'quality': quality,
            'test': isTest,
            'openTarget': flamesTarget == 1,
            'capacity': truth.capacity,
            'trace': target['trace'],
            'repere': _meGet(target, 'repere', false),
          });
          performed += 1;
        }
        athlete.endExercise(truth);
        if (sessionMax != null) {
          lastMaxLoad[exId] = sessionMax;
        }
        if (performed > 0) {
          exerciseSessions[exId] = count + 1;
          trained.add((truth, item));
          tour.cap0.putIfAbsent(exId, () => truth.startCapacity);
        }
        order += 1;
      }
      final record = <String, Object?>{
        'id': 'sim-$simDay',
        'simDay': simDay,
        'week': g,
        'blockIndex': bi,
        'weekIndex': wb,
        'dayIndex': di,
        'place': lieu,
        'healthCheck': bilan,
        'sets': done,
        'pains': <Object?>[for (final p in athlete.sessionPains()) p.toJson()],
        'bodyWeightKg': athlete.bodyWeightKg,
        'eventDay': eventDays.contains(simDay),
      };
      endurance.endDay(simDay);
      politique.terminer(ctx, record);
      if (garderJournal) {
        tour.journal.add(record);
      }
      tour.servi.add((g, bi, wb, di, servis));
      tour.sessionsDone += 1;
      for (final (truth, item) in trained) {
        final exId = item['exerciseId']! as String;
        var basis = item;
        for (final it in ecrits) {
          if (it['slotId'] == item['slotId'] && it['exerciseId'] == exId) {
            basis = it;
          }
        }
        final flames = basis['targetFlames'] as num?;
        final hold = truth.mode == CapacityMode.hold;
        final low = (hold ? basis['secondsLow'] : basis['repsLow']) as num?;
        final high = (hold ? basis['secondsHigh'] : basis['repsHigh']) as num?;
        final num lo = low ?? (high ?? 8);
        final num hi = high ?? (low ?? 8);
        final n =
            (lo + hi) / 2 +
            (flames == null ? 3.0 : _meFlammesVersRir(flames));
        final est = politique.estimer(exId, n);
        if (est == null) {
          continue;
        }
        final loaded = truth.mode == CapacityMode.loaded;
        tour.estimates.add(<String, Object?>{
          'week': g,
          'simDay': simDay,
          'exerciseId': exId,
          'mode': truth.mode.name,
          'exerciseSession': exerciseSessions[exId] ?? 0,
          'capacity': est[0],
          'truth': truth.capacity,
          'relSd': est[1],
          'operational': est[2],
          'truthOperational': loaded
              ? truth.capacity * truth.share(n)
              : truth.capacity,
          'main': ctx.roleDe(item['slotId']! as String) == 'main',
          'low': est.length > 3 ? est[3] : null,
          'high': est.length > 4 ? est[4] : null,
        });
      }
    }
    athlete.endWeek();
    politique.finSemaine(g, tour);
  }
  for (final t in athlete.truths) {
    final first = t.firstDay;
    final last = t.lastDay;
    tour.capFin[t.info.id] = t.capacity;
    if (first == null || last == null || last - first < 21) {
      continue;
    }
    tour.gain[t.info.id] =
        math.log(t.lastCapacity / t.firstCapacity) / ((last - first) / 7);
  }
  tour.painAggravations = athlete.painAggravations;
  tour.painFlares = athlete.painFlares;
  tour.enduranceOveruse = endurance.overuse;
  tour.worstRunSpike = endurance.worstSpike;
  tour.extra['endurance'] = <double>[
    endurance.startEasyMinutes,
    endurance.easyMinutes,
    endurance.startWod,
    endurance.wod,
  ];
  politique.fin(tour);
  return tour;
}
