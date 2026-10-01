/// État d'un programme candidat pendant la recherche : pour chaque jour,
/// la liste de ses exercices (rang dans le vivier), de leurs séries et de
/// l'identité de leur emplacement.
library;

import 'dart:typed_data';

/// Programme candidat, modifiable.
final class PlanState {
  /// État vide de [dayCount] jours, [capacity] emplacements par jour.
  PlanState(this.dayCount, this.capacity)
    : exercise = List<Int32List>.generate(
        dayCount,
        (_) => Int32List(capacity),
        growable: false,
      ),
      sets = List<Int32List>.generate(
        dayCount,
        (_) => Int32List(capacity),
        growable: false,
      ),
      uid = List<Int32List>.generate(
        dayCount,
        (_) => Int32List(capacity),
        growable: false,
      ),
      count = Int32List(dayCount),
      slotIds = <String>[],
      locked = <bool>[];

  PlanState._shared(PlanState other)
    : dayCount = other.dayCount,
      capacity = other.capacity,
      exercise = List<Int32List>.generate(
        other.dayCount,
        (d) => Int32List.fromList(other.exercise[d]),
        growable: false,
      ),
      sets = List<Int32List>.generate(
        other.dayCount,
        (d) => Int32List.fromList(other.sets[d]),
        growable: false,
      ),
      uid = List<Int32List>.generate(
        other.dayCount,
        (d) => Int32List.fromList(other.uid[d]),
        growable: false,
      ),
      count = Int32List.fromList(other.count),
      slotIds = other.slotIds,
      locked = other.locked;

  /// Nombre de jours.
  final int dayCount;

  /// Emplacements par jour.
  final int capacity;

  /// Rang dans le vivier de l'exercice de chaque emplacement, par jour.
  final List<Int32List> exercise;

  /// Séries de chaque emplacement, par jour.
  final List<Int32List> sets;

  /// Identité de chaque emplacement (rang dans [slotIds]), par jour.
  final List<Int32List> uid;

  /// Nombre d'emplacements par jour.
  final Int32List count;

  /// Identifiant de chaque emplacement connu (registre en ajout seul,
  /// partagé entre les copies d'un même état).
  final List<String> slotIds;

  /// Verrou de chaque emplacement connu.
  final List<bool> locked;

  /// Copie indépendante (le registre des emplacements reste partagé).
  PlanState copy() => PlanState._shared(this);

  /// Recopie les jours de [other] (même forme, même registre).
  void restore(PlanState other) {
    for (var d = 0; d < dayCount; d++) {
      exercise[d].setAll(0, other.exercise[d]);
      sets[d].setAll(0, other.sets[d]);
      uid[d].setAll(0, other.uid[d]);
      count[d] = other.count[d];
    }
  }

  /// Enregistre un emplacement et rend son identité.
  int register(String slotId, {required bool isLocked}) {
    slotIds.add(slotId);
    locked.add(isLocked);
    return slotIds.length - 1;
  }

  /// Nombre total d'emplacements.
  int get slotCount {
    var n = 0;
    for (var d = 0; d < dayCount; d++) {
      n += count[d];
    }
    return n;
  }

  /// Ajoute un emplacement à la fin du jour [day] ; rend son rang.
  int add(int day, int poolIndex, int setCount, int identity) {
    final at = count[day];
    exercise[day][at] = poolIndex;
    sets[day][at] = setCount;
    uid[day][at] = identity;
    count[day] = at + 1;
    return at;
  }

  /// Retire l'emplacement de rang [at] du jour [day] (le dernier prend sa
  /// place : l'ordre dans l'état n'a pas de sens, l'ordre de la séance est
  /// calculé à la sortie).
  void removeAt(int day, int at) {
    final last = count[day] - 1;
    if (at != last) {
      exercise[day][at] = exercise[day][last];
      sets[day][at] = sets[day][last];
      uid[day][at] = uid[day][last];
    }
    count[day] = last;
  }

  /// Rang dans le jour [day] de l'emplacement d'identité [identity], ou −1.
  int positionOf(int day, int identity) {
    final ids = uid[day];
    for (var i = 0; i < count[day]; i++) {
      if (ids[i] == identity) {
        return i;
      }
    }
    return -1;
  }

  /// Vrai si le jour [day] contient l'exercice [poolIndex].
  bool dayHas(int day, int poolIndex) {
    final ex = exercise[day];
    for (var i = 0; i < count[day]; i++) {
      if (ex[i] == poolIndex) {
        return true;
      }
    }
    return false;
  }

  /// Nombre d'emplacements portant l'exercice [poolIndex].
  int occurrences(int poolIndex) {
    var n = 0;
    for (var d = 0; d < dayCount; d++) {
      final ex = exercise[d];
      for (var i = 0; i < count[d]; i++) {
        if (ex[i] == poolIndex) {
          n++;
        }
      }
    }
    return n;
  }
}
