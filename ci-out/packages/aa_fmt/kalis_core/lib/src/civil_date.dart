/// Jour civil du calendrier grégorien, sans heure ni fuseau.
///
/// Les moteurs ne lisent jamais l'horloge : « aujourd'hui » leur est passé
/// sous cette forme. Sérialisé « AAAA-MM-JJ ».
final class CivilDate implements Comparable<CivilDate> {
  /// Jour civil ; [ArgumentError] si la date n'existe pas (30 février…) ou
  /// sort de l'intervalle 0001-9999.
  factory CivilDate(int year, int month, int day) {
    final d = DateTime.utc(year, month, day);
    if (year < 1 ||
        year > 9999 ||
        d.year != year ||
        d.month != month ||
        d.day != day) {
      throw ArgumentError('Jour civil invalide : $year-$month-$day');
    }
    return CivilDate._(year, month, day);
  }

  /// Lit « AAAA-MM-JJ » ; [FormatException] sinon.
  factory CivilDate.parse(String iso) {
    final m = _pattern.firstMatch(iso);
    if (m == null) {
      throw FormatException('Jour civil attendu au format AAAA-MM-JJ', iso);
    }
    try {
      return CivilDate(
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
        int.parse(m.group(3)!),
      );
    } on ArgumentError {
      throw FormatException('Jour civil inexistant', iso);
    }
  }

  /// Jour civil d'un numéro de jour (voir [dayNumber]).
  factory CivilDate.fromDayNumber(int dayNumber) {
    final d = DateTime.fromMillisecondsSinceEpoch(
      dayNumber * _millisecondsPerDay,
      isUtc: true,
    );
    return CivilDate(d.year, d.month, d.day);
  }

  const CivilDate._(this.year, this.month, this.day);

  static final RegExp _pattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
  static const int _millisecondsPerDay = 86400000;

  /// Année (1 à 9999).
  final int year;

  /// Mois (1 à 12).
  final int month;

  /// Jour du mois (1 à 31).
  final int day;

  /// Nombre de jours depuis le 1970-01-01 (négatif avant).
  int get dayNumber =>
      DateTime.utc(year, month, day).millisecondsSinceEpoch ~/
      _millisecondsPerDay;

  /// Jour ISO de la semaine : 1 = lundi … 7 = dimanche.
  int get weekday => DateTime.utc(year, month, day).weekday;

  /// Forme « AAAA-MM-JJ ».
  String get iso {
    final y = year.toString().padLeft(4, '0');
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Ce jour décalé de [days] jours (négatif : vers le passé).
  CivilDate addDays(int days) => CivilDate.fromDayNumber(dayNumber + days);

  /// Nombre de jours de ce jour jusqu'à [other] (négatif si [other] précède).
  int daysUntil(CivilDate other) => other.dayNumber - dayNumber;

  /// Vrai si ce jour précède strictement [other].
  bool operator <(CivilDate other) => compareTo(other) < 0;

  /// Vrai si ce jour précède ou égale [other].
  bool operator <=(CivilDate other) => compareTo(other) <= 0;

  /// Vrai si ce jour suit strictement [other].
  bool operator >(CivilDate other) => compareTo(other) > 0;

  /// Vrai si ce jour suit ou égale [other].
  bool operator >=(CivilDate other) => compareTo(other) >= 0;

  @override
  int compareTo(CivilDate other) {
    if (year != other.year) {
      return year.compareTo(other.year);
    }
    if (month != other.month) {
      return month.compareTo(other.month);
    }
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) {
    return other is CivilDate &&
        year == other.year &&
        month == other.month &&
        day == other.day;
  }

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => iso;
}
