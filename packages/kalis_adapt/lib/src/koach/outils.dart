part of 'koach.dart';

// Outils de portage : lecture typée du JSON (les entrées du moteur sont du
// JSON pur, comme dans la référence Python) et sémantique Python des
// opérations qui en ont une (vérité, division entière, copie profonde).

/// Objet JSON (dictionnaire Python).
typedef Json = Map<String, Object?>;

const double inf = double.infinity;

/// Nombre JSON en double (`float(x)`).
double dbl(Object? v) => (v as num).toDouble();

/// Nombre JSON en double, ou null.
double? dblOu(Object? v) => v == null ? null : (v as num).toDouble();

/// Entier JSON (`int(x)` : troncature vers zéro).
int ent(Object? v) => v is int ? v : (v as num).truncate();

/// Dictionnaire JSON.
Json jm(Object? v) => v as Map<String, Object?>;

/// Dictionnaire JSON ou null.
Json? jmOu(Object? v) => v == null ? null : v as Map<String, Object?>;

/// Liste JSON.
List<Object?> jl(Object? v) => v as List<Object?>;

/// Liste JSON de nombres en doubles.
List<double> jld(Object? v) => [for (final x in v as List<Object?>) dbl(x)];

/// Vérité Python : None, False, 0, 0.0, '' et les conteneurs vides sont
/// faux.
bool vrai(Object? v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v.isNotEmpty;
  if (v is Iterable<Object?>) return v.isNotEmpty;
  if (v is Map<Object?, Object?>) return v.isNotEmpty;
  return true;
}

/// `a or b` de Python.
Object? ou(Object? a, Object? b) => vrai(a) ? a : b;

/// `d.get(k) or {}` : dictionnaire, vide si absent ou faux.
Json dictOuVide(Object? v) =>
    vrai(v) ? v as Map<String, Object?> : <String, Object?>{};

/// `d.get(k) or []` : liste, vide si absente ou fausse.
List<Object?> listeOuVide(Object? v) =>
    vrai(v) ? v as List<Object?> : <Object?>[];

/// Copie profonde d'une valeur JSON (dictionnaires dans l'ordre d'insertion).
Object? copieProfonde(Object? v) {
  if (v is Map<String, Object?>) {
    return <String, Object?>{
      for (final e in v.entries) e.key: copieProfonde(e.value),
    };
  }
  if (v is List<Object?>) {
    return <Object?>[for (final x in v) copieProfonde(x)];
  }
  return v;
}

/// Copie profonde d'un dictionnaire JSON.
Json copieJson(Json v) => copieProfonde(v) as Json;

/// `math.floor` de Python (entier).
int plancher(double x) => x.floor();

/// `math.ceil` de Python (entier).
int plafond(double x) => x.ceil();

/// `a // b` de Python sur des entiers (division euclidienne vers -∞).
int divEnt(int a, int b) {
  final q = a ~/ b;
  return (a % b != 0 && ((a < 0) != (b < 0))) ? q - 1 : q;
}

/// Égalité Python de deux valeurs JSON (1 == 1.0, dictionnaires sans ordre).
bool egalJson(Object? a, Object? b) {
  if (a is num && b is num) return a == b;
  if (a is Map<String, Object?> && b is Map<String, Object?>) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (!b.containsKey(e.key) || !egalJson(e.value, b[e.key])) return false;
    }
    return true;
  }
  if (a is List<Object?> && b is List<Object?>) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!egalJson(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

/// Somme Python d'une liste de doubles (ordre des indices, départ 0).
double somme(Iterable<double> xs) {
  var s = 0.0;
  for (final x in xs) {
    s += x;
  }
  return s;
}

/// `x in liste` de Python (égalité JSON).
bool dans(Object? x, Iterable<Object?> liste) {
  for (final y in liste) {
    if (egalJson(x, y)) return true;
  }
  return false;
}

/// `'%.nf' % x` de Python : arrondi correct de la valeur binaire exacte,
/// au pair sur une égalité exacte (`toStringAsFixed` arrondit l'égalité
/// vers le haut).
String fixe(num x0, int n) {
  final x = x0.toDouble();
  if (x.isNaN) return 'nan';
  if (x.isInfinite) return x > 0 ? 'inf' : '-inf';
  final s = x.toStringAsFixed(n);
  if (n >= 20 || x.abs() >= 1e21) return s;
  final l = x.abs().toStringAsFixed(20);
  final p = l.indexOf('.');
  final reste = l.substring(p + 1 + n);
  if (reste[0] != '5' || reste.substring(1).replaceAll('0', '').isNotEmpty) {
    return s;
  }
  // Égalité exacte : garder la troncature si son dernier chiffre est pair.
  final tronque = l.substring(0, p + 1 + n);
  final chiffres = tronque.replaceAll('.', '');
  final dernier = int.parse(chiffres[chiffres.length - 1]);
  var v = BigInt.parse(chiffres);
  if (dernier.isOdd) v += BigInt.one;
  var t = v.toString().padLeft(n + 1, '0');
  if (n > 0) t = '${t.substring(0, t.length - n)}.${t.substring(t.length - n)}';
  final neg = x < 0 || (x == 0 && x.isNegative);
  return neg ? '-$t' : t;
}
