/// Recherche déterministe du meilleur programme (D4.2, D4.3) :
/// construction gloutonne avec anticipation, recuit simulé à graine fixe,
/// descente finale, puis retour sur les changements qui ne paient pas leur
/// pénalité (diff minimal, D4.6).
library;

import 'dart:typed_data';

import 'context.dart';
import 'hash.dart';
import 'score.dart';
import 'sets.dart';
import 'state.dart';
import 'traits.dart';

/// Identité d'un emplacement créé par la recherche, pas encore nommé.
const int unnamedSlot = -1;

/// Recherche sur un [PlanContext].
final class Planner {
  /// Recherche pour [context], de suite pseudo-aléatoire [seed].
  Planner(this.context, int seed)
    : scorer = Scorer(context),
      _random = SeededRandom(fnvMix(0x4B504C4E, seed)),
      _selectable = <int>[
        for (final e in context.pool)
          if (e.selectable) e.index,
      ],
      _heuristic = Float64List(context.pool.length),
      _current = Int32List(context.pool.length),
      _touched = Int32List(context.pool.length),
      _saveA = _DaySave(context.params.maxSlotsPerDay),
      _saveB = _DaySave(context.params.maxSlotsPerDay);

  /// Contexte.
  final PlanContext context;

  /// Notateur.
  final Scorer scorer;

  final SeededRandom _random;
  final List<int> _selectable;
  final Float64List _heuristic;
  final Int32List _current;
  final Int32List _touched;
  final _DaySave _saveA;
  final _DaySave _saveB;

  /// Jours gelés (verrou `keep_day`, portée d'une restructuration).
  Set<int> frozenDays = const <int>{};

  // Référence de la pénalité de changement.
  Int32List _referenceExercise = Int32List(0);
  int _referencePresent = 0;
  bool _hasReference = false;

  // Propositions déjà montrées (« Autre proposition »).
  final List<Int32List> _previous = <Int32List>[];
  final List<int> _previousSizes = <int>[];

  /// Poids de la pénalité de ressemblance aux propositions déjà montrées.
  double diversityWeight = 0;

  /// Exercices bannis de la recherche pour ce passage (rotation).
  final Set<int> banned = <int>{};

  /// Exercice que l'utilisateur vient de retirer du jour [dayBanDay] : il
  /// n'y revient pas pendant cette recherche (rang dans le vivier, ou −1).
  int dayBanIndex = -1;

  /// Jour de [dayBanIndex].
  int dayBanDay = -1;

  /// Nombre de notes calculées (mesure d'effort).
  int evaluations = 0;

  /// Remet la suite pseudo-aléatoire à la graine [seed].
  void reseed(int seed) => _random.reset(fnvMix(0x4B504C4E, seed));

  /// Fixe la référence de la pénalité de changement : [state] tel qu'il
  /// est. Un emplacement de référence est reconnu par son identité.
  void setReference(PlanState state) {
    _referenceExercise = Int32List(state.slotIds.length)
      ..fillRange(0, state.slotIds.length, -1);
    var present = 0;
    for (var d = 0; d < state.dayCount; d++) {
      for (var i = 0; i < state.count[d]; i++) {
        final id = state.uid[d][i];
        if (id >= 0) {
          _referenceExercise[id] = state.exercise[d][i];
          present++;
        }
      }
    }
    _referencePresent = present;
    _hasReference = true;
  }

  /// Retire la référence de la pénalité de changement.
  void clearReference() {
    _hasReference = false;
  }

  /// Nombre d'emplacements de [state] qui diffèrent de la référence
  /// (remplacés, ajoutés ou retirés).
  int changesFromReference(PlanState state) {
    if (!_hasReference) {
      return 0;
    }
    var present = 0;
    var changed = 0;
    final reference = _referenceExercise;
    for (var d = 0; d < state.dayCount; d++) {
      final ids = state.uid[d];
      final ex = state.exercise[d];
      for (var i = 0; i < state.count[d]; i++) {
        final id = ids[i];
        if (id >= 0 && id < reference.length && reference[id] >= 0) {
          present++;
          if (reference[id] != ex[i]) {
            changed++;
          }
        } else {
          changed++;
        }
      }
    }
    return changed + (_referencePresent - present);
  }

  /// Ajoute [state] aux propositions déjà montrées.
  void addPrevious(PlanState state) {
    final counts = Int32List(context.pool.length);
    var size = 0;
    for (var d = 0; d < state.dayCount; d++) {
      for (var i = 0; i < state.count[d]; i++) {
        if (!_isLocked(state, d, i)) {
          counts[state.exercise[d][i]]++;
          size++;
        }
      }
    }
    _previous.add(counts);
    _previousSizes.add(size);
    final keep = context.params.alternativeHistory;
    while (_previous.length > keep) {
      _previous.removeAt(0);
      _previousSizes.removeAt(0);
    }
  }

  /// Plus petite distance de [state] aux propositions déjà montrées (1 s'il
  /// n'y en a pas) : part des exercices non verrouillés différents.
  double minDistanceToPrevious(PlanState state) {
    if (_previous.isEmpty) {
      return 1;
    }
    final size = _fillCurrent(state);
    var least = 1.0;
    for (var j = 0; j < _previous.length; j++) {
      final d = _distance(j, size);
      if (d < least) {
        least = d;
      }
    }
    _clearCurrent();
    return least;
  }

  int _touchedCount = 0;

  int _fillCurrent(PlanState state) {
    var size = 0;
    _touchedCount = 0;
    for (var d = 0; d < state.dayCount; d++) {
      for (var i = 0; i < state.count[d]; i++) {
        if (_isLocked(state, d, i)) {
          continue;
        }
        final e = state.exercise[d][i];
        if (_current[e] == 0) {
          _touched[_touchedCount++] = e;
        }
        _current[e]++;
        size++;
      }
    }
    return size;
  }

  void _clearCurrent() {
    for (var i = 0; i < _touchedCount; i++) {
      _current[_touched[i]] = 0;
    }
    _touchedCount = 0;
  }

  double _distance(int j, int size) {
    final previous = _previous[j];
    var overlap = 0;
    for (var i = 0; i < _touchedCount; i++) {
      final e = _touched[i];
      final a = _current[e];
      final b = previous[e];
      overlap += a < b ? a : b;
    }
    final larger = size > _previousSizes[j] ? size : _previousSizes[j];
    return larger == 0 ? 0 : 1 - overlap / larger;
  }

  bool _isLocked(PlanState state, int day, int at) {
    final id = state.uid[day][at];
    return id >= 0 && state.locked[id];
  }

  /// Objectif de la recherche : note, moins la pénalité de changement,
  /// moins la pénalité de ressemblance.
  double objective(PlanState state) {
    evaluations++;
    var value = scorer.evaluate(state);
    if (_hasReference) {
      value -= context.params.changePenalty * changesFromReference(state);
    }
    if (diversityWeight > 0 && _previous.isNotEmpty) {
      final size = _fillCurrent(state);
      final wanted = context.params.alternativeMinDistance + 0.05;
      for (var j = 0; j < _previous.length; j++) {
        final gap = wanted - _distance(j, size);
        if (gap > 0) {
          value -= diversityWeight * gap;
        }
      }
      _clearCurrent();
    }
    return value;
  }

  // ------------------------------------------------------ contraintes dures

  int _workSlots(PlanState state, int day) {
    var n = 0;
    final ex = state.exercise[day];
    for (var i = 0; i < state.count[day]; i++) {
      if (context.pool[ex[i]].kind != SlotKind.mobility) {
        n++;
      }
    }
    return n;
  }

  /// Vrai si [entry] peut être ajouté au jour [day] de [state] (hors
  /// contrainte de durée, vérifiée après l'ajout).
  bool canPlace(PlanState state, int day, PoolEntry entry) {
    if (!entry.selectable ||
        !entry.feasibleOn(day) ||
        banned.contains(entry.index) ||
        (day == dayBanDay && entry.index == dayBanIndex) ||
        frozenDays.contains(day)) {
      return false;
    }
    if (state.count[day] >= state.capacity || state.dayHas(day, entry.index)) {
      return false;
    }
    if (entry.kind != SlotKind.mobility &&
        _workSlots(state, day) >= context.days[day].maxWorkSlots) {
      return false;
    }
    return true;
  }

  bool _isLastRequired(PlanState state, int poolIndex) {
    final id = context.pool[poolIndex].id;
    return context.requiredIds.contains(id) &&
        state.occurrences(poolIndex) <= 1;
  }

  // ------------------------------------------------------------- glouton

  /// Classe les exercices choisissables par besoin décroissant (après un
  /// [objective] sur [state]) et rend les premiers de chaque classe de
  /// discipline en manque, puis les premiers toutes classes confondues.
  List<int> _shortlist(PlanState state, {bool wide = false}) {
    final ctx = context;
    final slotTime = scorer.slotSeconds;
    final classNeed = List<double>.filled(DisciplineClass.values.length, 0);
    for (var k = 0; k < classNeed.length; k++) {
      final share = slotTime == 0 ? 0.0 : scorer.classSecondsAt(k) / slotTime;
      classNeed[k] = ctx.targets[k] - share;
    }
    final groupNeed = List<double>.filled(MuscleGroup.values.length, 0);
    for (var g = 0; g < groupNeed.length; g++) {
      final low = ctx.bandLow[g];
      if (low > 0) {
        final gap = (low - scorer.volumeHalfSets(g)) / low;
        groupNeed[g] = gap > 0 ? gap * ctx.groupWeight[g] : 0;
      }
    }
    final goalNeed = List<double>.filled(ctx.goals.length, 0);
    for (var j = 0; j < goalNeed.length; j++) {
      final need = ctx.goalExposureTarget * ctx.goalBestSupport[j];
      final gap = need <= 0 ? 0.0 : 1 - scorer.goalSupportSum(j) / need;
      goalNeed[j] = gap > 0 ? gap * ctx.goalWeights[j] : 0;
    }
    final missing = ctx.coverableBits & ~scorer.coveredBits;
    final order = <int>[];
    for (final index in _selectable) {
      if (banned.contains(index)) {
        continue;
      }
      final e = ctx.pool[index];
      var h = 0.0;
      final deficit = classNeed[e.cls.index];
      h += 2 * (deficit > 0 ? deficit : deficit * 0.5) * e.affinity / 100;
      for (var k = 0; k < e.creditGroups.length; k++) {
        h += 0.25 * e.creditValues[k] * groupNeed[e.creditGroups[k]];
      }
      if (e.coverBits & missing != 0) {
        h += 0.5;
      }
      for (var j = 0; j < goalNeed.length; j++) {
        h += goalNeed[j] * e.goalSupport[j] / 100;
      }
      if ((e.liked || e.known) && state.occurrences(index) == 0) {
        h += 0.5;
      }
      h += 0.2 * e.fit;
      final sfr = e.traits.stimulusFatigue;
      if (sfr > 0) {
        h += 0.1 * sfr;
      }
      _heuristic[index] = h + 1e-4 * e.tieBreak;
      order.add(index);
    }
    order.sort((a, b) {
      final by = _heuristic[b].compareTo(_heuristic[a]);
      return by != 0 ? by : ctx.pool[a].id.compareTo(ctx.pool[b].id);
    });
    // Passe large (finition) : six fois plus de candidats.
    final per = ctx.params.shortlistPerClass * (wide ? 6 : 1);
    final taken = List<int>.filled(DisciplineClass.values.length, 0);
    final out = <int>[];
    var overall = 0;
    for (final index in order) {
      final k = ctx.pool[index].cls.index;
      final wantClass = classNeed[k] > 0.01 && taken[k] < per;
      final wantOverall = overall < per;
      if (wantClass || wantOverall) {
        out.add(index);
        taken[k]++;
        if (wantOverall) {
          overall++;
        }
      }
    }
    return out;
  }

  /// Meilleurs ajouts d'un exercice de [shortlist] à un jour de [state] :
  /// jusqu'à [width] triplets (valeur, jour, exercice), du meilleur au
  /// moins bon. [onlyDays] restreint les jours (bits) ; 0 = tous.
  List<(double, int, int)> _bestAdditions(
    PlanState state,
    List<int> shortlist,
    int width,
    int onlyDays,
  ) {
    final ctx = context;
    final best = <(double, int, int)>[];
    for (final index in shortlist) {
      final e = ctx.pool[index];
      for (var d = 0; d < ctx.dayCount; d++) {
        if (onlyDays != 0 && (onlyDays >> d) & 1 == 0) {
          continue;
        }
        if (!canPlace(state, d, e)) {
          continue;
        }
        final at = state.add(d, index, ctx.defaultSets(e, d), unnamedSlot);
        if (normalizeDay(ctx, state, d)) {
          final value = objective(state) + 1e-7 * e.tieBreak;
          var pos = best.length;
          while (pos > 0 && best[pos - 1].$1 < value) {
            pos--;
          }
          if (pos < width) {
            best.insert(pos, (value, d, index));
            if (best.length > width) {
              best.removeLast();
            }
          }
        }
        state.removeAt(d, at);
        normalizeDay(ctx, state, d);
      }
    }
    return best;
  }

  /// Ajoute [index] au jour [day] et recalcule les séries du jour. Rend le
  /// rang de l'emplacement, ou −1 (état inchangé) si la séance ne tient
  /// plus dans son temps.
  int place(PlanState state, int day, int index, int identity) {
    final e = context.pool[index];
    final at = state.add(day, index, context.defaultSets(e, day), identity);
    if (!normalizeDay(context, state, day)) {
      state.removeAt(day, at);
      normalizeDay(context, state, day);
      return -1;
    }
    return at;
  }

  /// Amorce : place d'abord un exercice pour chaque schéma de base que le
  /// vivier permet et que le programme ne couvre pas encore (genou, tirage,
  /// poussée, hanche, tronc), au jour où il sert le mieux la note — même
  /// s'il la fait d'abord baisser : l'équilibre des schémas ne se juge
  /// qu'une fois les deux côtés présents. Un exercice par tranche de dix
  /// minutes de renforcement au plus ; la suite de la recherche peut le
  /// retirer.
  void _seedPatterns(PlanState state) {
    final ctx = context;
    if (ctx.resistanceShare <= 0) {
      return;
    }
    var minutes = 0;
    for (final d in ctx.days) {
      minutes += d.minutes;
    }
    var seeds = (minutes * ctx.resistanceShare / 10).floor();
    const order = <int>[16, 8, 1, 32, 4, 2, 64];
    for (final bit in order) {
      if (seeds <= 0) {
        break;
      }
      if (ctx.coverableBits & bit == 0) {
        continue;
      }
      objective(state);
      if (scorer.coveredBits & bit != 0) {
        continue;
      }
      final candidates = <int>[
        for (final index in _selectable)
          if (ctx.pool[index].coverBits & bit != 0 && !banned.contains(index))
            index,
      ];
      candidates.sort((a, b) {
        final by = _merit(ctx.pool[b]).compareTo(_merit(ctx.pool[a]));
        return by != 0 ? by : ctx.pool[a].id.compareTo(ctx.pool[b].id);
      });
      final best = _bestAdditions(
        state,
        candidates.length > 8 ? candidates.sublist(0, 8) : candidates,
        1,
        0,
      );
      if (best.isNotEmpty) {
        final (_, d, index) = best.first;
        if (place(state, d, index, unnamedSlot) >= 0) {
          seeds--;
        }
      }
    }
  }

  double _merit(PoolEntry e) {
    var support = 0;
    for (final s in e.goalSupport) {
      if (s > support) {
        support = s;
      }
    }
    return (e.liked ? 1.0 : 0.0) +
        support / 100 +
        e.fit +
        e.affinity / 200 +
        1e-3 * e.tieBreak;
  }

  /// Construction gloutonne avec anticipation : ajoute l'exercice qui
  /// améliore le plus la note, en regardant un ajout plus loin pour les
  /// meilleurs candidats ; s'arrête quand plus aucun ajout n'améliore.
  /// Une séance vide est remplie d'abord (aucune séance vide).
  ///
  /// [seed] amorce d'abord les schémas de base (construction initiale) ;
  /// [wide] élargit la liste des candidats (finition).
  void construct(PlanState state, {bool seed = false, bool wide = false}) {
    final ctx = context;
    final width = ctx.params.lookaheadWidth;
    if (seed) {
      _seedPatterns(state);
    }
    for (var step = 0; step < 160; step++) {
      var empty = 0;
      for (var d = 0; d < ctx.dayCount; d++) {
        if (state.count[d] == 0 && !frozenDays.contains(d)) {
          empty |= 1 << d;
        }
      }
      final base = objective(state);
      final shortlist = _shortlist(state, wide: wide);
      final first = _bestAdditions(state, shortlist, width, empty);
      if (first.isEmpty) {
        if (empty != 0) {
          // Aucun candidat du haut du classement ne tient dans un jour
          // vide : on essaie tout le vivier.
          final all = _bestAdditions(state, _selectable, 1, empty);
          if (all.isEmpty) {
            break;
          }
          final (_, d, index) = all.first;
          place(state, d, index, unnamedSlot);
          continue;
        }
        break;
      }
      var chosen = first.first;
      var chosenAhead = first.first.$1;
      if (first.length > 1 && empty == 0) {
        var bestValue = double.negativeInfinity;
        for (final candidate in first) {
          final (value, d, index) = candidate;
          final at = place(state, d, index, unnamedSlot);
          if (at < 0) {
            continue;
          }
          final next = _bestAdditions(state, shortlist, 1, 0);
          state.removeAt(d, at);
          normalizeDay(ctx, state, d);
          final ahead = next.isEmpty || next.first.$1 < value
              ? value
              : next.first.$1;
          if (ahead > bestValue + 1e-12) {
            bestValue = ahead;
            chosen = candidate;
            chosenAhead = ahead;
          }
        }
      }
      final (_, d, index) = chosen;
      if (empty == 0 && chosenAhead <= base + 1e-9) {
        break;
      }
      if (place(state, d, index, unnamedSlot) < 0) {
        break;
      }
    }
  }

  // --------------------------------------------------------------- recuit

  bool _dayOpen(int day) => !frozenDays.contains(day);

  /// Tente un coup aléatoire sur [state] ; rend faux si le coup n'est pas
  /// admissible (l'état est alors inchangé). Les jours touchés sont
  /// sauvegardés dans [_saveA] et [_saveB].
  bool _randomMove(PlanState state) {
    final ctx = context;
    final days = ctx.dayCount;
    final roll = _random.nextInt(100);
    _saveA.day = -1;
    _saveB.day = -1;
    final d = _random.nextInt(days);
    if (!_dayOpen(d)) {
      return false;
    }
    if (roll < 55) {
      // Remplacer un exercice.
      final n = state.count[d];
      if (n == 0) {
        return false;
      }
      final at = _random.nextInt(n);
      if (_isLocked(state, d, at)) {
        return false;
      }
      final old = state.exercise[d][at];
      if (_isLastRequired(state, old)) {
        return false;
      }
      int candidate;
      if (_random.nextInt(100) < 60) {
        final near = ctx.neighbours(old);
        if (near.isEmpty) {
          return false;
        }
        candidate = near[_random.nextInt(near.length)];
      } else {
        if (_selectable.isEmpty) {
          return false;
        }
        candidate = _selectable[_random.nextInt(_selectable.length)];
      }
      final e = ctx.pool[candidate];
      if (candidate == old ||
          !e.selectable ||
          !e.feasibleOn(d) ||
          banned.contains(candidate) ||
          (d == dayBanDay && candidate == dayBanIndex) ||
          state.dayHas(d, candidate)) {
        return false;
      }
      final wasWork = ctx.pool[old].kind != SlotKind.mobility;
      final isWork = e.kind != SlotKind.mobility;
      if (isWork &&
          !wasWork &&
          _workSlots(state, d) >= ctx.days[d].maxWorkSlots) {
        return false;
      }
      _saveA.save(state, d);
      state.exercise[d][at] = candidate;
      state.sets[d][at] = ctx.defaultSets(e, d);
      if (!normalizeDay(ctx, state, d)) {
        _saveA.restore(state);
        return false;
      }
      return true;
    }
    if (roll < 70) {
      // Ajouter un exercice.
      if (_selectable.isEmpty) {
        return false;
      }
      final candidate = _selectable[_random.nextInt(_selectable.length)];
      final e = ctx.pool[candidate];
      if (!canPlace(state, d, e)) {
        return false;
      }
      _saveA.save(state, d);
      var evictions = 0;
      while (place(state, d, candidate, unnamedSlot) < 0) {
        // La séance est pleine : on fait de la place (deux retraits au
        // plus), le recuit juge l'échange.
        final n = state.count[d];
        if (evictions >= 2 || n == 0) {
          _saveA.restore(state);
          return false;
        }
        final at = _random.nextInt(n);
        if (_isLocked(state, d, at) ||
            _isLastRequired(state, state.exercise[d][at])) {
          _saveA.restore(state);
          return false;
        }
        state.removeAt(d, at);
        normalizeDay(ctx, state, d);
        evictions++;
      }
      return true;
    }
    final n = state.count[d];
    if (n <= 1) {
      return false;
    }
    final at = _random.nextInt(n);
    if (_isLocked(state, d, at) ||
        _isLastRequired(state, state.exercise[d][at])) {
      return false;
    }
    if (roll < 85) {
      // Retirer un exercice.
      _saveA.save(state, d);
      state.removeAt(d, at);
      normalizeDay(ctx, state, d);
      return true;
    }
    // Déplacer un exercice vers un autre jour.
    if (days < 2) {
      return false;
    }
    final to = _random.nextInt(days);
    final moved = state.exercise[d][at];
    final e = ctx.pool[moved];
    if (to == d || !_dayOpen(to) || !canPlace(state, to, e)) {
      return false;
    }
    _saveA.save(state, d);
    _saveB.save(state, to);
    state.removeAt(d, at);
    normalizeDay(ctx, state, d);
    if (place(state, to, moved, unnamedSlot) < 0) {
      _saveA.restore(state);
      _saveB.restore(state);
      return false;
    }
    return true;
  }

  /// Recuit simulé de [iterations] coups ; [state] finit sur le meilleur
  /// état rencontré.
  void anneal(PlanState state, int iterations) {
    if (iterations <= 0) {
      return;
    }
    final params = context.params;
    var current = objective(state);
    var bestValue = current;
    final best = state.copy();
    final t0 = params.annealStartTemperature;
    final lnRatio = stableLn(params.annealEndTemperature / t0);
    for (var it = 0; it < iterations; it++) {
      if (!_randomMove(state)) {
        continue;
      }
      final value = objective(state);
      final delta = value - current;
      var accept = delta >= 0;
      if (!accept && delta > -0.5) {
        final temperature = t0 * stableExp(lnRatio * it / iterations);
        accept = _random.nextDouble() < stableExp(delta / temperature);
      }
      if (accept) {
        current = value;
        if (value > bestValue + 1e-12) {
          bestValue = value;
          best.restore(state);
        }
      } else {
        _saveA.restore(state);
        _saveB.restore(state);
      }
    }
    state.restore(best);
  }

  // -------------------------------------------------------------- descente

  /// Descente : pour chaque emplacement libre, le meilleur remplacement
  /// parmi ses voisins, puis le retrait s'il améliore ; répète tant qu'un
  /// passage améliore (trois passages au plus).
  void polish(PlanState state) {
    final ctx = context;
    var current = objective(state);
    for (var pass = 0; pass < 3; pass++) {
      var improved = false;
      for (var d = 0; d < ctx.dayCount; d++) {
        if (!_dayOpen(d)) {
          continue;
        }
        for (var at = 0; at < state.count[d]; at++) {
          if (_isLocked(state, d, at)) {
            continue;
          }
          final old = state.exercise[d][at];
          if (_isLastRequired(state, old)) {
            continue;
          }
          final wasWork = ctx.pool[old].kind != SlotKind.mobility;
          var bestIndex = -1;
          var bestValue = current;
          _saveA.save(state, d);
          for (final candidate in ctx.neighbours(old)) {
            final e = ctx.pool[candidate];
            if (!e.feasibleOn(d) ||
                banned.contains(candidate) ||
                (d == dayBanDay && candidate == dayBanIndex) ||
                state.dayHas(d, candidate)) {
              continue;
            }
            if (e.kind != SlotKind.mobility &&
                !wasWork &&
                _workSlots(state, d) >= ctx.days[d].maxWorkSlots) {
              continue;
            }
            state.exercise[d][at] = candidate;
            if (normalizeDay(ctx, state, d)) {
              final value = objective(state);
              if (value > bestValue + 1e-9) {
                bestValue = value;
                bestIndex = candidate;
              }
            }
            _saveA.restore(state);
          }
          if (bestIndex >= 0) {
            state.exercise[d][at] = bestIndex;
            normalizeDay(ctx, state, d);
            current = bestValue;
            improved = true;
          }
        }
      }
      // Retraits qui améliorent (exercice de trop).
      for (var d = 0; d < ctx.dayCount; d++) {
        if (!_dayOpen(d)) {
          continue;
        }
        var at = 0;
        while (at < state.count[d]) {
          if (state.count[d] <= 1 ||
              _isLocked(state, d, at) ||
              _isLastRequired(state, state.exercise[d][at])) {
            at++;
            continue;
          }
          _saveA.save(state, d);
          state.removeAt(d, at);
          normalizeDay(ctx, state, d);
          final value = objective(state);
          if (value > current + 1e-9) {
            current = value;
            improved = true;
          } else {
            _saveA.restore(state);
            at++;
          }
        }
      }
      if (_coverMissing(state)) {
        improved = true;
      }
      final before = state.slotCount;
      construct(state, wide: true);
      if (state.slotCount != before) {
        improved = true;
        current = objective(state);
      }
      if (!improved) {
        break;
      }
    }
  }

  /// Schémas de base manquants : essaie d'y placer un exercice, en
  /// retirant au besoin un ou deux exercices libres du jour pour lui faire
  /// de la place ; garde l'échange s'il améliore l'objectif. Rend vrai si
  /// [state] a changé.
  bool _coverMissing(PlanState state) {
    final ctx = context;
    var changed = false;
    const order = <int>[16, 8, 1, 32, 4, 2, 64];
    for (final bit in order) {
      var current = objective(state);
      if (ctx.coverableBits & bit == 0 || scorer.coveredBits & bit != 0) {
        continue;
      }
      final candidates = <int>[
        for (final index in _selectable)
          if (ctx.pool[index].coverBits & bit != 0 && !banned.contains(index))
            index,
      ];
      candidates.sort((a, b) {
        final by = _merit(ctx.pool[b]).compareTo(_merit(ctx.pool[a]));
        return by != 0 ? by : ctx.pool[a].id.compareTo(ctx.pool[b].id);
      });
      final best = state.copy();
      var bestValue = current;
      final work = state.copy();
      final top = candidates.length > 4 ? 4 : candidates.length;
      for (var c = 0; c < top; c++) {
        final index = candidates[c];
        final e = ctx.pool[index];
        for (var d = 0; d < ctx.dayCount; d++) {
          if (!_dayOpen(d) || !e.feasibleOn(d) || state.dayHas(d, index)) {
            continue;
          }
          final n = state.count[d];
          // Retraits essayés : aucun, un, puis deux exercices libres.
          for (var i = -1; i < n; i++) {
            for (var j = -1; j < (i < 0 ? 0 : i); j++) {
              work.restore(state);
              var ok = true;
              for (final at in <int>[i, j]) {
                if (at < 0) {
                  continue;
                }
                if (_isLocked(work, d, at) ||
                    _isLastRequired(work, work.exercise[d][at])) {
                  ok = false;
                }
              }
              if (!ok) {
                continue;
              }
              // Le rang le plus haut d'abord : l'autre ne bouge pas.
              if (i >= 0) {
                work.removeAt(d, i);
              }
              if (j >= 0) {
                work.removeAt(d, j);
              }
              if (!canPlace(work, d, e)) {
                continue;
              }
              if (place(work, d, index, unnamedSlot) < 0) {
                continue;
              }
              final value = objective(work);
              if (value > bestValue + 1e-9) {
                bestValue = value;
                best.restore(work);
              }
            }
          }
        }
      }
      if (bestValue > current + 1e-9) {
        state.restore(best);
        current = bestValue;
        changed = true;
      }
    }
    return changed;
  }

  // ------------------------------------------------------ réparation, retour

  /// Rend [state] admissible : retire d'abord les exercices libres qui ne
  /// sont plus admissibles ce jour-là, puis, tant qu'une séance dépasse
  /// son temps ou son nombre d'exercices, l'exercice libre dont le retrait
  /// coûte le moins. Ce qui est verrouillé ne bouge pas.
  void repair(PlanState state) {
    final ctx = context;
    for (var d = 0; d < ctx.dayCount; d++) {
      if (!_dayOpen(d)) {
        continue;
      }
      var at = 0;
      while (at < state.count[d]) {
        final e = ctx.pool[state.exercise[d][at]];
        final bad =
            !e.selectable || !e.feasibleOn(d) || banned.contains(e.index);
        if (bad && !_isLocked(state, d, at)) {
          state.removeAt(d, at);
        } else {
          at++;
        }
      }
      while (true) {
        final over =
            !normalizeDay(ctx, state, d) ||
            _workSlots(state, d) > ctx.days[d].maxWorkSlots;
        if (!over) {
          break;
        }
        var bestAt = -1;
        var bestValue = double.negativeInfinity;
        for (var i = 0; i < state.count[d]; i++) {
          if (_isLocked(state, d, i) ||
              _isLastRequired(state, state.exercise[d][i])) {
            continue;
          }
          _saveA.save(state, d);
          state.removeAt(d, i);
          normalizeDay(ctx, state, d);
          final value = objective(state);
          _saveA.restore(state);
          if (value > bestValue) {
            bestValue = value;
            bestAt = i;
          }
        }
        if (bestAt < 0) {
          break;
        }
        state.removeAt(d, bestAt);
      }
    }
  }

  /// Diff minimal : annule un à un les changements par rapport à
  /// [reference] dont l'annulation, admissible, ne fait pas baisser
  /// l'objectif (pénalité de changement comprise). Répète jusqu'à
  /// stabilité.
  void revertUnpaidChanges(PlanState state, PlanState reference) {
    final ctx = context;
    var current = objective(state);
    for (var round = 0; round < 8; round++) {
      var reverted = false;
      for (var d = 0; d < ctx.dayCount; d++) {
        if (!_dayOpen(d)) {
          continue;
        }
        // Emplacements remplacés ou ajoutés.
        var at = 0;
        while (at < state.count[d]) {
          if (_isLocked(state, d, at)) {
            at++;
            continue;
          }
          final id = state.uid[d][at];
          final refAt = id >= 0 ? reference.positionOf(d, id) : -1;
          _saveA.save(state, d);
          var tried = false;
          if (refAt < 0) {
            if (state.count[d] > 1 &&
                !_isLastRequired(state, state.exercise[d][at])) {
              state.removeAt(d, at);
              tried = true;
            }
          } else if (reference.exercise[d][refAt] != state.exercise[d][at]) {
            final back = reference.exercise[d][refAt];
            final e = ctx.pool[back];
            if (e.selectable &&
                e.feasibleOn(d) &&
                !banned.contains(back) &&
                !state.dayHas(d, back)) {
              state.exercise[d][at] = back;
              tried = true;
            }
          }
          if (!tried) {
            at++;
            continue;
          }
          final ok =
              normalizeDay(ctx, state, d) &&
              _workSlots(state, d) <= ctx.days[d].maxWorkSlots;
          final value = ok ? objective(state) : double.negativeInfinity;
          if (value >= current - 1e-12) {
            current = value;
            reverted = true;
            if (refAt >= 0) {
              at++;
            }
          } else {
            _saveA.restore(state);
            at++;
          }
        }
        // Emplacements retirés.
        for (var i = 0; i < reference.count[d]; i++) {
          final id = reference.uid[d][i];
          if (id < 0 || state.positionOf(d, id) >= 0) {
            continue;
          }
          final back = reference.exercise[d][i];
          final e = ctx.pool[back];
          if (!e.selectable ||
              !e.feasibleOn(d) ||
              banned.contains(back) ||
              state.count[d] >= state.capacity ||
              state.dayHas(d, back)) {
            continue;
          }
          _saveA.save(state, d);
          state.add(d, back, reference.sets[d][i], id);
          final ok =
              normalizeDay(ctx, state, d) &&
              _workSlots(state, d) <= ctx.days[d].maxWorkSlots;
          final value = ok ? objective(state) : double.negativeInfinity;
          if (value >= current - 1e-12) {
            current = value;
            reverted = true;
          } else {
            _saveA.restore(state);
          }
        }
      }
      if (!reverted) {
        break;
      }
    }
  }
}

final class _DaySave {
  _DaySave(int capacity)
    : exercise = Int32List(capacity),
      sets = Int32List(capacity),
      uid = Int32List(capacity);

  Int32List exercise;
  Int32List sets;
  Int32List uid;
  int count = 0;
  int day = -1;

  void save(PlanState state, int d) {
    if (exercise.length != state.capacity) {
      exercise = Int32List(state.capacity);
      sets = Int32List(state.capacity);
      uid = Int32List(state.capacity);
    }
    day = d;
    count = state.count[d];
    exercise.setAll(0, state.exercise[d]);
    sets.setAll(0, state.sets[d]);
    uid.setAll(0, state.uid[d]);
  }

  void restore(PlanState state) {
    if (day < 0) {
      return;
    }
    state.exercise[day].setAll(0, exercise);
    state.sets[day].setAll(0, sets);
    state.uid[day].setAll(0, uid);
    state.count[day] = count;
  }
}
