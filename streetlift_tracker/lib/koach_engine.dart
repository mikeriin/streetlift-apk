// Koach (L7, KT-026 à KT-032) — moteur d'autorégulation, pur et déterministe.
//
// Transcription de la référence Python `tools/koach_reference.py` (même
// ordre des opérations) : mêmes sorties à 0,01 kg près sur les fixtures
// partagées `test/fixtures/koach/` (test `l7_koach_engine_test.dart`).
// Entrées : journal normalisé (Map JSON), programme annoté, décisions de
// l'utilisateur, horloge. Aucun accès au stockage, au réseau ni à Flutter.
// Contrat : docs/CONTRAT_L7.md.

import 'dart:convert';
import 'dart:math' as math;

/// Paramètres (contrat §4). Les valeurs « simulation » sont justifiées au
/// contrat §8 ; une entrée peut les surcharger (`params`, tests).
const Map<String, double> koachParams = {
  'q': 0.005,
  'sigma_day': 0.05,
  'atypical': 0.05,
  'r_base': 0.015,
  'r_rir': 0.01,
  'r_rir_target': 1.0,
  'r_reps': 0.003,
  'r_reps_from': 5,
  'r_rank': 0.005,
  'r_failed': 0.015,
  'failed_extra': 0.5,
  'r_test': 0.005,
  'test_half_step': 1.0,
  'r_manual': 0.01,
  'r_prior': 0.10,
  'uncertain': 0.05,
  'k_min': 15.0,
  'k_max': 45.0,
  'k_prior_sd': 4.0,
  'k_min_sets': 12,
  'k_min_spread': 3,
  'k_window': 60,
  'valid_rir_max': 4,
  'valid_n_max': 12,
  'rest_min_ratio': 0.8,
  'bias_min': -2.0,
  'bias_max': 2.0,
  'bias_prior_sd': 1.0,
  'bias_window_days': 21,
  'bias_min_sets': 3,
  'rir_noise_sd': 1.0,
  'cap_up': 0.025,
  'cap_down': 0.05,
  'cap_weeks_max': 4,
  'hysteresis': 0.75,
  'end_base': 0.05,
  'end_rir': 0.02,
  'end_test': 0.02,
  'end_rir_max': 3,
  'end_dip_double_above': 30,
  'end_bound_sd': 1.0,
  'end_uncertain': 0.10,
  'fatigue_1': -0.05,
  'fatigue_2': -0.075,
  'fatigue_3': -0.10,
  'fatigue_cut_1': 0.15,
  'fatigue_cut_2': 0.25,
  'fatigue_cut_3': 0.30,
  'sleep_min': 5.0,
  'form_max': 4.0,
  'pain_threshold': 3.0,
  'pain_cut': 0.20,
  'slope_weeks': 6,
  'late': 0.8,
  'ahead': 1.2,
  'struct_min_weeks': 6,
  'struct_total_cap': 0.15,
  'deload_sets': 0.6,
  'deload_load': 0.10,
  'up_big': 0.06,
  'up_big_cap': 5.0,
  'up_small': 0.03,
  'up_small_cap': 2.5,
  'down': 0.03,
  'down_big': 0.06,
};

const double koachEps = 1e-9;
const double lbKg = 0.45359237;
const double _day = 86400.0;

/// Incréments du matériel par défaut (D23, valeurs du propriétaire).
const Map<String, Map<String, Object>> defaultEquipment = {
  'dumbbell': {'small': 1.0, 'threshold': 10.0, 'large': 2.0},
  'plate': {'step': 1.25},
  'barbell': {'step': 2.5},
  'pulley': {'step': 2.5, 'unit': 'lb'},
  'machine': {'step': 2.5, 'unit': 'kg'},
};

// ---------------------------------------------------------------------------
// Outils numériques (identiques en Python)
// ---------------------------------------------------------------------------
double _sq(double x) => x * x;

/// Arrondi au plus proche, demi s'éloignant de zéro.
double kRound(double x) =>
    x >= 0 ? (x + 0.5).floorToDouble() : -((-x + 0.5).floorToDouble());

double floorGrid(double v, double step) =>
    (v / step + koachEps).floorToDouble() * step;

double ceilGrid(double v, double step) =>
    (v / step - koachEps).ceilToDouble() * step;

double nearGrid(double v, double step) => kRound(v / step) * step;

/// Arrondi au centième (sorties).
double r2(double v) => kRound(v * 100.0) / 100.0;

/// Numerical Recipes « erfcc » : erreur relative < 1,2e-7.
double kErfc(double x) {
  final z = x.abs();
  final t = 1.0 / (1.0 + 0.5 * z);
  final poly =
      -z * z -
      1.26551223 +
      t *
          (1.00002368 +
              t *
                  (0.37409196 +
                      t *
                          (0.09678418 +
                              t *
                                  (-0.18628806 +
                                      t *
                                          (0.27886807 +
                                              t *
                                                  (-1.13520398 +
                                                      t *
                                                          (1.48851587 +
                                                              t *
                                                                  (-0.82215223 +
                                                                      t * 0.17087277))))))));
  final ans = t * math.exp(poly);
  return x >= 0 ? ans : 2.0 - ans;
}

double normPdf(double a) => math.exp(-0.5 * a * a) / math.sqrt(2.0 * math.pi);

double normCdf(double a) => 0.5 * kErfc(-a / math.sqrt(2.0));

/// %1RM(n) = 1 / (1 + (n − 1) / k), n = répétitions jusqu'à l'échec.
double pctOf(double n, double k) => 1.0 / (1.0 + (n - 1.0) / k);

double oneRm(double mass, double n, double k) => mass * (1.0 + (n - 1.0) / k);

final RegExp _isoRe = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2})(?::(\d{2})(?:\.(\d{1,6}))?)?)?',
);

/// Horodatage local → secondes « murales » (sans fuseau ni heure d'été).
double? parseDt(String? s) {
  if (s == null) return null;
  final m = _isoRe.firstMatch(s.trim());
  if (m == null) return null;
  final y = int.parse(m.group(1)!), mo = int.parse(m.group(2)!);
  final d = int.parse(m.group(3)!);
  final h = int.parse(m.group(4) ?? '0'), mi = int.parse(m.group(5) ?? '0');
  final se = int.parse(m.group(6) ?? '0');
  final frac = m.group(7);
  final us = frac == null ? 0 : int.parse('${frac}000000'.substring(0, 6));
  final date = DateTime.utc(y, mo, d);
  if (date.year != y || date.month != mo || date.day != d) return null;
  final days = date.millisecondsSinceEpoch ~/ 86400000;
  return days * _day + h * 3600.0 + mi * 60.0 + se + us / 1e6;
}

int dayOf(double t) => (t / _day).floor();

String _two(int v) => v.toString().padLeft(2, '0');

/// Secondes murales → « AAAA-MM-JJTHH:MM:SS ».
String isoOf(double t) {
  final d = DateTime.fromMillisecondsSinceEpoch(
    (t * 1000).floor(),
    isUtc: true,
  );
  return '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}'
      'T${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}';
}

/// Horodatage local d'une date de l'application (toujours sans fuseau).
String wallIso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}'
    'T${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}';

String civilIso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

// ---------------------------------------------------------------------------
// Échelle de difficulté (D9) et valeurs RIR héritées
// ---------------------------------------------------------------------------
class EffortLevel {
  final int rir;
  final String label;
  final String more;
  const EffortLevel(this.rir, this.label, this.more);
}

/// Du plus dur au plus facile ; stockée en RIR (5 = « 5 ou plus »).
const List<EffortLevel> effortScale = [
  EffortLevel(0, 'Échec', 'plus aucune rep'),
  EffortLevel(1, 'Très dur', 'encore 1'),
  EffortLevel(2, 'Dur', 'encore 2'),
  EffortLevel(3, 'Soutenu', 'encore 3'),
  EffortLevel(4, 'Modéré', 'encore 4'),
  EffortLevel(5, 'Facile', 'encore 5 ou plus'),
];

/// Libellé court d'une difficulté (RIR arrondi à l'échelon inférieur).
String effortName(double rir) {
  final i = math.min(5, math.max(0, rir.floor()));
  return effortScale[i].label;
}

final RegExp _effortRe = RegExp(r'^\d{1,2}(?:[.,][05])?$');

/// Texte libre du champ RIR/RPE (avant 3.0.0) → RIR, ou null (contrat
/// §3.3) : entier ou demi ; RPE 1-10 → 10 − RPE ; > 5 → 5. Plages, texte,
/// « @8 » : non interprétables (borne inférieure, jamais une mesure).
double? parseLegacyEffort(String? text, String scale) {
  if (text == null) return null;
  final t = text.replaceAll(' ', '').replaceAll(' ', '').trim();
  if (t.isEmpty || !_effortRe.hasMatch(t)) return null;
  var v = double.parse(t.replaceAll(',', '.'));
  if (scale == 'rpe') {
    if (v < 1 || v > 10) return null;
    v = 10.0 - v;
  }
  return v > 5 ? 5.0 : v;
}

// ---------------------------------------------------------------------------
// Matériel et incréments (D23)
// ---------------------------------------------------------------------------
Map<String, dynamic> _eq(Map<String, dynamic>? equipment, String kind) {
  final e = equipment?[kind];
  if (e is Map && e.isNotEmpty) return Map<String, dynamic>.from(e);
  return Map<String, dynamic>.from(defaultEquipment[kind]!);
}

double _num(Object? v) => (v as num).toDouble();

double toNative(double kg, String kind, Map<String, dynamic>? equipment) =>
    _eq(equipment, kind)['unit'] == 'lb' ? kg / lbKg : kg;

double fromNative(double v, String kind, Map<String, dynamic>? equipment) =>
    _eq(equipment, kind)['unit'] == 'lb' ? v * lbKg : v;

/// Charge suivante (up) ou précédente sur la grille du matériel (kg).
double gridNext(
  double kg,
  String kind,
  Map<String, dynamic>? equipment,
  bool up,
) {
  final e = _eq(equipment, kind);
  if (kind == 'dumbbell') {
    final small = _num(e['small']), thr = _num(e['threshold']);
    final large = _num(e['large']);
    if (up) {
      if (kg < thr - koachEps) {
        return math.min(floorGrid(kg, small) + small, thr);
      }
      return thr + floorGrid(kg - thr, large) + large;
    }
    if (kg > thr + koachEps) {
      return math.max(thr + ceilGrid(kg - thr, large) - large, thr);
    }
    return math.max(ceilGrid(kg, small) - small, 0.0);
  }
  final step = _num(e['step']);
  final native = toNative(kg, kind, equipment);
  final nxt =
      up
          ? floorGrid(native, step) + step
          : math.max(ceilGrid(native, step) - step, 0.0);
  return fromNative(nxt, kind, equipment);
}

/// Charge la plus proche sur la grille du matériel (kg → kg).
double gridRound(double kg, String kind, Map<String, dynamic>? equipment) {
  final e = _eq(equipment, kind);
  if (kind == 'dumbbell') {
    final small = _num(e['small']), thr = _num(e['threshold']);
    final large = _num(e['large']);
    if (kg <= thr + koachEps) {
      final v = nearGrid(kg, small);
      if (v <= thr + koachEps) return v;
    }
    return thr + nearGrid(kg - thr, large);
  }
  return fromNative(
    nearGrid(toNative(kg, kind, equipment), _num(e['step'])),
    kind,
    equipment,
  );
}

// ---------------------------------------------------------------------------
// Poids de corps (D12)
// ---------------------------------------------------------------------------
/// Pesée applicable au jour `day` : la dernière ≤ ce jour ; avant la
/// première pesée, la première ; sans pesée, la valeur de pilotage.
double? bodyweightAt(List<dynamic> weighIns, int day, double? fallback) {
  int? bestDay, firstDay;
  double? best, first;
  for (final raw in weighIns) {
    final w = raw as Map;
    final t = parseDt(w['date'] as String?);
    if (t == null) continue;
    final d = dayOf(t);
    final kg = _num(w['kg']);
    if (firstDay == null || d < firstDay) {
      firstDay = d;
      first = kg;
    }
    if (d <= day && (bestDay == null || d >= bestDay)) {
      bestDay = d;
      best = kg;
    }
  }
  return best ?? first ?? fallback;
}

// ---------------------------------------------------------------------------
// Filtre de Kalman 1D
// ---------------------------------------------------------------------------
class KPending {
  final double z, r, gap;
  final double? bound;
  final String session;
  const KPending(this.z, this.r, this.gap, this.bound, this.session);
}

class KSeriesPoint {
  final String at;
  final double x, sd;
  final String kind;
  final String? session;

  /// Mesure du jour (moyenne pondérée des séries), null sans mesure.
  final double? z;
  const KSeriesPoint(
    this.at,
    this.x,
    this.sd,
    this.kind,
    this.session, [
    this.z,
  ]);
}

/// État d'une grandeur : x (1RM système en kg, ou maximum de reps), P.
class KTrack {
  double x;
  double p;
  double t;
  double k;
  final double kPrior;
  bool kPersonal = false;
  final List<(double, double)> kObs = [];
  double? nMin, nMax;
  int validSets = 0;
  final List<int> validWeeks = [];
  final List<KSeriesPoint> series = [];
  double? lastMeasure;
  KPending? pending;

  KTrack(this.x, double sd, this.t, this.k) : p = sd * sd, kPrior = k;

  KTrack._copy(KTrack o)
    : x = o.x,
      p = o.p,
      t = o.t,
      k = o.k,
      kPrior = o.kPrior {
    kPersonal = o.kPersonal;
    kObs.addAll(o.kObs);
    nMin = o.nMin;
    nMax = o.nMax;
    validSets = o.validSets;
    validWeeks.addAll(o.validWeeks);
    series.addAll(o.series);
    lastMeasure = o.lastMeasure;
    pending = o.pending;
  }

  KTrack copy() => KTrack._copy(this);

  double get sd => math.sqrt(p);

  void predict(double at, double q) {
    final dt = (at - t) / _day;
    if (dt > 0) {
      p += _sq(q * x) * (dt / 7.0);
      t = at;
    }
  }

  void update(double z, double variance) {
    if (variance <= 0) return;
    final g = p / (p + variance);
    x += g * (z - x);
    p *= (1.0 - g);
  }

  /// Contrainte x + ε ≥ L (ε ~ N(0, s²)) : ne peut que relever
  /// l'estimation, nettement seulement si elle est contredite.
  void lowerBound(double bound, double s) {
    final scale = math.sqrt(p + s * s);
    if (scale <= 0) return;
    final a = (x - bound) / scale;
    final cdf = normCdf(a);
    final lam = cdf < 1e-300 ? -a : normPdf(a) / cdf;
    x += p * lam / scale;
    p -= (p * p) / (scale * scale) * lam * (a + lam);
    if (p < 1e-9) p = 1e-9;
  }

  void addWeek(int? week) {
    if (week != null && !validWeeks.contains(week)) validWeeks.add(week);
  }
}

class KBias {
  double b = 0.0;
  double? p;
  int updates = 0;
}

/// État complet d'un rejeu (cache incrémental : [copy]).
class KoachState {
  final KBias bias = KBias();
  final Map<String, KTrack> tracks = {};
  final Map<String, KTrack> rtracks = {};
  final Map<String, Map<String, double>> fatigue = {};
  final List<String> signatures = [];
  double? bwNow;

  KoachState();

  KoachState copy() {
    final out = KoachState();
    out.bias
      ..b = bias.b
      ..p = bias.p
      ..updates = bias.updates;
    tracks.forEach((k, v) => out.tracks[k] = v.copy());
    rtracks.forEach((k, v) => out.rtracks[k] = v.copy());
    fatigue.forEach((k, v) => out.fatigue[k] = Map<String, double>.of(v));
    out.signatures.addAll(signatures);
    out.bwNow = bwNow;
    return out;
  }
}

// ---------------------------------------------------------------------------
// Entrées normalisées
// ---------------------------------------------------------------------------
Map<String, double> paramsOf(Map<String, dynamic> inp) {
  final out = Map<String, double>.of(koachParams);
  final over = inp['params'];
  if (over is Map) {
    over.forEach((k, v) => out[k as String] = (v as num).toDouble());
  }
  return out;
}

List<Map<String, dynamic>> _list(Object? v) => [
  for (final e in (v as List?) ?? const []) (e as Map).cast<String, dynamic>(),
];

bool _truthy(Object? v) {
  if (v == null || v == false) return false;
  if (v is num) return v != 0;
  if (v is String) return v.isNotEmpty;
  return true;
}

double? _dn(Object? v) => v == null ? null : (v as num).toDouble();

int? _in(Object? v) => v == null ? null : (v as num).toInt();

double? sessionTime(Map<String, dynamic> s) {
  double? best;
  for (final ex in _list(s['exercises'])) {
    for (final st in _list(ex['sets'])) {
      if (_truthy(st['done']) && _truthy(st['at'])) {
        final t = parseDt(st['at'] as String);
        if (t != null && (best == null || t < best)) best = t;
      }
    }
  }
  if (best != null) return best;
  return parseDt(s['finishedAt'] as String?);
}

class KSession {
  final double t;
  final String key;
  final Map<String, dynamic> s;
  const KSession(this.t, this.key, this.s);
}

int _cmpStr(String a, String b) => a.compareTo(b);

List<KSession> sortedSessions(Map<String, dynamic> inp) {
  final out = <(KSession, int)>[];
  for (final s in _list(inp['sessions'])) {
    final t = sessionTime(s);
    if (t != null) out.add((KSession(t, s['key'] as String, s), out.length));
  }
  out.sort((a, b) {
    final c = a.$1.t.compareTo(b.$1.t);
    if (c != 0) return c;
    final d = _cmpStr(a.$1.key, b.$1.key);
    return d != 0 ? d : a.$2.compareTo(b.$2);
  });
  return [for (final e in out) e.$1];
}

/// D13 : repos réel depuis la série validée précédente du même exercice.
bool restOk(Map<String, dynamic> ex, int i, double ratio) {
  final rest = _dn(ex['restSec']);
  if (rest == null || rest == 0) return true;
  final sets = _list(ex['sets']);
  final t = parseDt(sets[i]['at'] as String?);
  if (t == null) return true;
  for (var j = i - 1; j >= 0; j--) {
    final prev = sets[j];
    if (_truthy(prev['done']) && _truthy(prev['at'])) {
      final tp = parseDt(prev['at'] as String);
      if (tp == null) return true;
      return (t - tp) >= ratio * rest - koachEps;
    }
  }
  return true;
}

bool isFailed(Map<String, dynamic> ex, Map<String, dynamic> st) {
  final planned = _in(ex['plannedReps']);
  final reps = _in(st['reps']);
  return planned != null && reps != null && reps < planned;
}

/// Masse système : poids de corps + lest (tractions, dips, muscle-up),
/// charge de la barre (squat).
double? liftMass(
  Map<String, dynamic> lift,
  Map<String, dynamic> st,
  double? bw,
) {
  final kg = _dn(st['kg']);
  if (lift['bodyweight'] == true) {
    if (bw == null) return null;
    return bw + (kg ?? 0.0);
  }
  if (kg == null || kg <= 0) return null;
  return kg;
}

class KEvent {
  final double t;
  final int kind; // 0 : modification manuelle ; 1 : séance
  final String key;
  final Map<String, dynamic> obj;
  const KEvent(this.t, this.kind, this.key, this.obj);
}

List<KEvent> eventList(Map<String, dynamic> inp) {
  final events = <(KEvent, int)>[];
  for (final s in sortedSessions(inp)) {
    events.add((KEvent(s.t, 1, s.key, s.s), events.length));
  }
  for (final h in _list(inp['history'])) {
    if (h['source'] != 'manual') continue;
    final th = parseDt(h['at'] as String?);
    if (th != null) {
      events.add((KEvent(th, 0, '${h['ref']}@${h['at']}', h), events.length));
    }
  }
  events.sort((a, b) {
    var c = a.$1.t.compareTo(b.$1.t);
    if (c != 0) return c;
    c = a.$1.kind.compareTo(b.$1.kind);
    if (c != 0) return c;
    c = _cmpStr(a.$1.key, b.$1.key);
    return c != 0 ? c : a.$2.compareTo(b.$2);
  });
  return [for (final e in events) e.$1];
}

String eventSignature(KEvent ev) => jsonEncode([ev.t, ev.kind, ev.key, ev.obj]);

// ---------------------------------------------------------------------------
// Rejeu (KT-026, KT-027) et cache incrémental (KT-034)
// ---------------------------------------------------------------------------
class KContext {
  final Map<String, dynamic> inp;
  final Map<String, double> p;
  final Map<String, dynamic> refs;
  final List<dynamic> weigh;
  final List<Map<String, dynamic>> lifts;
  final Map<String, Map<String, dynamic>> liftByRef;
  final List<Map<String, dynamic>> repmax;
  final Map<String, Map<String, dynamic>> repByRef;
  final List<KSession> sessions;
  final Map<String, double> initial = {};

  KContext(this.inp)
    : p = paramsOf(inp),
      refs = ((inp['references'] as Map?) ?? const {}).cast<String, dynamic>(),
      weigh = (inp['weighIns'] as List?) ?? const [],
      lifts = _list(inp['lifts']),
      liftByRef = {for (final l in _list(inp['lifts'])) l['ref'] as String: l},
      repmax = _list(inp['repmax']),
      repByRef = {for (final r in _list(inp['repmax'])) r['ref'] as String: r},
      sessions = sortedSessions(inp) {
    final raw = _list(inp['history']);
    final order = List<int>.generate(raw.length, (i) => i);
    order.sort((i, j) {
      final a = parseDt(raw[i]['at'] as String?) ?? 0.0;
      final b = parseDt(raw[j]['at'] as String?) ?? 0.0;
      var c = a.compareTo(b);
      if (c != 0) return c;
      c = _cmpStr(raw[i]['ref'] as String, raw[j]['ref'] as String);
      return c != 0 ? c : i.compareTo(j);
    });
    for (final i in order) {
      final h = raw[i];
      final ref = h['ref'] as String;
      if (h['source'] == 'initial' && !initial.containsKey(ref)) {
        initial[ref] = _num(h['value']);
      }
    }
  }

  double? bw(int day) => bodyweightAt(weigh, day, _dn(refs['B4']));

  double? prior(String ref) => initial[ref] ?? _dn(refs[ref]);
}

KTrack? _trackFor(
  KContext ctx,
  KoachState state,
  Map<String, dynamic> lift,
  double t,
) {
  final key = lift['key'] as String;
  final existing = state.tracks[key];
  if (existing != null) return existing;
  final v0 = ctx.prior(lift['ref'] as String);
  if (v0 == null) return null;
  double x0;
  if (lift['bodyweight'] == true) {
    final bw0 = ctx.bw(dayOf(t));
    if (bw0 == null) return null;
    x0 = v0 + bw0;
  } else {
    x0 = v0;
  }
  if (x0 <= 0) return null;
  final tr = KTrack(x0, ctx.p['r_prior']! * x0, t, _num(lift['k']));
  state.tracks[key] = tr;
  return tr;
}

KTrack? _rtrackFor(KContext ctx, KoachState state, String ref, double t) {
  final existing = state.rtracks[ref];
  if (existing != null) return existing;
  final v0 = ctx.prior(ref);
  if (v0 == null || v0 <= 0) return null;
  final tr = KTrack(v0, ctx.p['r_prior']! * v0, t, 1.0);
  state.rtracks[ref] = tr;
  return tr;
}

void _applyEvent(KContext ctx, KoachState state, KEvent ev) {
  final p = ctx.p;
  state.bias.p ??= _sq(p['bias_prior_sd']!);
  final t = ev.t;
  if (ev.kind == 0) {
    final ref = ev.obj['ref'] as String;
    final lift = ctx.liftByRef[ref];
    if (lift != null) {
      final tr = _trackFor(ctx, state, lift, t);
      if (tr != null) {
        tr.predict(t, p['q']!);
        final bw = lift['bodyweight'] == true ? ctx.bw(dayOf(t)) : 0.0;
        final z = _num(ev.obj['value']) + (bw ?? 0.0);
        tr.update(z, _sq(p['r_manual']! * z));
        tr.pending = null;
        tr.series.add(KSeriesPoint(isoOf(t), tr.x, tr.sd, 'manual', null));
      }
    } else if (ctx.repByRef.containsKey(ref)) {
      final tr = _rtrackFor(ctx, state, ref, t);
      if (tr != null) {
        tr.predict(t, p['q']!);
        final z = _num(ev.obj['value']);
        tr.update(z, _sq(p['r_manual']! * z));
        tr.series.add(KSeriesPoint(isoOf(t), tr.x, tr.sd, 'manual', null));
      }
    }
  } else {
    _processSession(ctx, state, ev.obj, t);
  }
  state.signatures.add(eventSignature(ev));
}

KoachState replay(Map<String, dynamic> inp) {
  final ctx = KContext(inp);
  final state = KoachState();
  for (final ev in eventList(inp)) {
    _applyEvent(ctx, state, ev);
  }
  return _finish(ctx, state);
}

/// Reprend un état calculé sur un préfixe identique d'événements ; sinon
/// rejeu complet. Résultat identique au rejeu complet (test obligatoire).
KoachState replayIncremental(Map<String, dynamic> inp, KoachState? cached) {
  final ctx = KContext(inp);
  final events = eventList(inp);
  final sigs = [for (final e in events) eventSignature(e)];
  if (cached != null) {
    final old = cached.signatures;
    var prefix = old.length <= sigs.length;
    for (var i = 0; prefix && i < old.length; i++) {
      if (old[i] != sigs[i]) prefix = false;
    }
    if (prefix) {
      final state = cached.copy();
      for (var i = old.length; i < events.length; i++) {
        _applyEvent(ctx, state, events[i]);
      }
      return _finish(ctx, state);
    }
  }
  final state = KoachState();
  for (final ev in events) {
    _applyEvent(ctx, state, ev);
  }
  return _finish(ctx, state);
}

KoachState _finish(KContext ctx, KoachState state) {
  final now = parseDt(ctx.inp['now'] as String?)!;
  state.bwNow = ctx.bw(dayOf(now));
  state.bias.p ??= _sq(ctx.p['bias_prior_sd']!);
  return state;
}

class _Anchor {
  final String type, key;
  final double z, sigRel;
  const _Anchor(this.type, this.key, this.z, this.sigRel);
}

bool _anyDone(List<Map<String, dynamic>> exs) {
  for (final ex in exs) {
    for (final st in _list(ex['sets'])) {
      if (_truthy(st['done'])) return true;
    }
  }
  return false;
}

void _processSession(
  KContext ctx,
  KoachState state,
  Map<String, dynamic> s,
  double t,
) {
  final p = ctx.p;
  final bias = state.bias;
  final bw = ctx.bw(dayOf(t));
  final week = _in(s['week']);
  final anchors = <_Anchor>[];
  final allEx = _list(s['exercises']);
  for (final lift in ctx.lifts) {
    final key = lift['key'] as String;
    final exs = [
      for (final ex in allEx)
        if (ex['ref'] == lift['ref'] &&
            (ex['cat'] == 'strength' || ex['cat'] == 'test1rm'))
          ex,
    ];
    if (!_anyDone(exs)) continue;
    final tr = _trackFor(ctx, state, lift, t);
    if (tr == null) continue;
    tr.predict(t, p['q']!);
    final xBefore = tr.x;
    final k = tr.k;
    // Test 1RM : meilleure série, + ½ incrément ; jamais mis en attente.
    double? testZ;
    for (final ex in exs) {
      if (ex['cat'] != 'test1rm') continue;
      for (final st in _list(ex['sets'])) {
        final reps = _in(st['reps']);
        if (!_truthy(st['done']) ||
            _truthy(st['excluded']) ||
            reps == null ||
            reps == 0 ||
            reps < 1) {
          continue;
        }
        final m = liftMass(lift, st, bw);
        if (m == null) continue;
        final z = oneRm(m, reps.toDouble(), k);
        if (testZ == null || z > testZ) testZ = z;
      }
    }
    if (testZ != null) {
      testZ += 0.5 * _num(lift['grid']) * p['test_half_step']!;
      tr.update(testZ, _sq(p['r_test']! * testZ));
      tr.pending = null;
      tr.lastMeasure = t;
      tr.addWeek(week);
      anchors.add(_Anchor('test', key, testZ, p['r_test']!));
    }
    // Séries de travail.
    final meas = <(double, double)>[];
    double? bound;
    (Map<String, dynamic>, Map<String, dynamic>, double)? firstSet;
    var failedAnchors = <_Anchor>[];
    for (final ex in exs) {
      if (ex['cat'] != 'strength') continue;
      final sets = _list(ex['sets']);
      for (var i = 0; i < sets.length; i++) {
        final st = sets[i];
        if (!_truthy(st['done'])) continue;
        final rank = i + 1;
        final reps = _in(st['reps']);
        if (_truthy(st['excluded']) || reps == null || reps == 0 || reps < 1) {
          continue;
        }
        final m = liftMass(lift, st, bw);
        if (m == null) continue;
        firstSet ??= (ex, st, m);
        if (!restOk(ex, i, p['rest_min_ratio']!)) continue;
        final r = reps.toDouble();
        if (_truthy(ex['cluster'])) {
          // Clusters : chaque rep est au moins un single.
          if (bound == null || m > bound) bound = m;
          continue;
        }
        final rir = _dn(st['rir']);
        if (isFailed(ex, st)) {
          final z = oneRm(m, r + p['failed_extra']!, k);
          meas.add((z, p['r_failed']! + p['r_rank']! * (rank - 1)));
          if (rank == 1) {
            // Ancre de biais : la série ratée reflète la forme du jour.
            failedAnchors.add(
              _Anchor(
                'failed',
                key,
                z,
                math.sqrt(_sq(p['r_failed']!) + _sq(p['sigma_day']!)),
              ),
            );
          }
          tr.validSets += 1;
          tr.addWeek(week);
        } else if (rir != null &&
            rir <= p['valid_rir_max']! &&
            r + rir <= p['valid_n_max']!) {
          final n = r + math.max(0.0, rir + bias.b);
          final z = oneRm(m, n, k);
          var rs = _dn(ex['rirTarget']);
          if (rs == null || p['r_rir_target']! < 0.5) rs = rir;
          final ns = r + rs;
          final sig =
              (p['r_base']! +
                  p['r_rir']! * rs +
                  p['r_reps']! * math.max(0.0, ns - p['r_reps_from']!) +
                  p['r_rank']! * (rank - 1));
          meas.add((z, sig));
          tr.validSets += 1;
          tr.addWeek(week);
        } else if (rir != null &&
            rir > p['valid_rir_max']! &&
            r <= p['valid_n_max']!) {
          // « Facile » : au moins RIR − 1 en réserve (bruit ±1).
          final lb = oneRm(m, r + math.max(0.0, rir - 1.0 + bias.b), k);
          if (bound == null || lb > bound) bound = lb;
        } else if (r <= p['valid_n_max']!) {
          final lb = oneRm(m, r, k);
          if (bound == null || lb > bound) bound = lb;
        }
      }
    }
    double? dayZ;
    if (meas.isNotEmpty) {
      var wsum = 0.0;
      var zsum = 0.0;
      for (final (z, sig) in meas) {
        final variance = _sq(sig * xBefore);
        wsum += 1.0 / variance;
        zsum += z / variance;
      }
      final zbar = zsum / wsum;
      dayZ = zbar;
      final r = 1.0 / wsum + _sq(p['sigma_day']! * xBefore);
      final gap = zbar / xBefore - 1.0;
      final pend = tr.pending;
      tr.pending = null;
      if (pend != null &&
          gap * pend.gap > 0 &&
          gap.abs() >= 0.5 * p['atypical']!) {
        // Séance atypique confirmée : incertitude rouverte, les deux comptent.
        final jump = 0.5 * (pend.gap + gap) * xBefore;
        tr.p += jump * jump;
        tr.update(pend.z, pend.r);
        if (pend.bound != null) {
          tr.lowerBound(pend.bound!, p['sigma_day']! * tr.x);
        }
        tr.update(zbar, r);
        tr.lastMeasure = t;
      } else if (gap.abs() >= p['atypical']! && testZ == null) {
        // Séance atypique isolée : en attente de confirmation (ni
        // estimation ni biais n'en tiennent compte d'ici là).
        tr.pending = KPending(zbar, r, gap, bound, s['key'] as String);
        bound = null;
        failedAnchors = [];
      } else {
        tr.update(zbar, r);
        tr.lastMeasure = t;
      }
    }
    if (bound != null) tr.lowerBound(bound, p['sigma_day']! * tr.x);
    anchors.addAll(failedAnchors);
    if (firstSet != null) {
      final (ex, st, m) = firstSet;
      final lvl = fatigueLevel(
        p,
        xBefore,
        m,
        _in(st['reps']),
        _dn(st['rir']),
        bias.b,
        k,
        failed: isFailed(ex, st),
      );
      if (lvl > 0) {
        state.fatigue.putIfAbsent(s['key'] as String, () => {})[key] = lvl;
      }
    }
    tr.series.add(
      KSeriesPoint(isoOf(t), tr.x, tr.sd, 'session', s['key'] as String, dayZ),
    );
  }

  // Endurance (D21).
  for (final spec in ctx.repmax) {
    final ref = spec['ref'] as String;
    final exs = [
      for (final ex in allEx)
        if (ex['ref'] == ref &&
            (ex['cat'] == 'endurance' || ex['cat'] == 'enduranceTest'))
          ex,
    ];
    if (!_anyDone(exs)) continue;
    final tr = _rtrackFor(ctx, state, ref, t);
    if (tr == null) continue;
    tr.predict(t, p['q']!);
    int? testMax;
    for (final ex in exs) {
      if (ex['cat'] != 'enduranceTest') continue;
      for (final st in _list(ex['sets'])) {
        final reps = _in(st['reps']);
        if (_truthy(st['done']) && !_truthy(st['excluded']) && reps != null) {
          if (testMax == null || reps > testMax) testMax = reps;
        }
      }
    }
    if (testMax != null && testMax > 0) {
      // « Un test mesuré remplace l'estimation » (D21).
      tr.x = testMax.toDouble();
      tr.p = _sq(p['end_test']! * testMax);
      tr.lastMeasure = t;
      tr.addWeek(week);
      anchors.add(_Anchor('endtest', ref, testMax.toDouble(), p['end_test']!));
    } else {
      Map<String, dynamic>? first;
      int? best;
      for (final ex in exs) {
        if (ex['cat'] != 'endurance' || _truthy(ex['emom'])) continue;
        for (final st in _list(ex['sets'])) {
          final reps = _in(st['reps']);
          if (!_truthy(st['done']) ||
              _truthy(st['excluded']) ||
              reps == null ||
              reps == 0) {
            continue;
          }
          first ??= st;
          if (best == null || reps > best) best = reps;
        }
      }
      if (first != null) {
        final rir = _dn(first['rir']);
        final reps = _in(first['reps'])!;
        if (rir != null && rir <= p['end_rir_max']!) {
          final z = reps + math.max(0.0, rir + bias.b);
          var sig = p['end_base']! + p['end_rir']! * rir;
          if (spec['dips'] == true && reps > p['end_dip_double_above']!) {
            sig *= 2.0;
          }
          tr.update(z, _sq(sig * z));
          tr.lastMeasure = t;
          tr.addWeek(week);
        }
      }
      if (best != null) tr.lowerBound(best.toDouble(), p['end_bound_sd']!);
    }
    tr.series.add(
      KSeriesPoint(isoOf(t), tr.x, tr.sd, 'session', s['key'] as String),
    );
  }

  for (final a in anchors) {
    _biasUpdate(ctx, state, a, t, s);
  }
}

/// D17, ancrée sur les tests : n − 1 = k·u + c, moindres carrés rétrécis
/// vers l'a priori du programme, bornés à [15 ; 45] (contrat §4.3).
void _kRefit(KTrack tr, Map<String, double> p) {
  final window = p['k_window']!.toInt();
  final obs =
      tr.kObs.length > window
          ? tr.kObs.sublist(tr.kObs.length - window)
          : tr.kObs;
  if (obs.length < p['k_min_sets']! ||
      tr.nMin == null ||
      tr.nMax! - tr.nMin! < p['k_min_spread']!) {
    return;
  }
  var su = 0.0, sn = 0.0;
  for (final (u, n) in obs) {
    su += u;
    sn += n;
  }
  final mu = su / obs.length;
  final mn = sn / obs.length;
  var suu = 0.0, sun = 0.0;
  for (final (u, _) in obs) {
    suu += _sq(u - mu);
  }
  for (final (u, n) in obs) {
    sun += (u - mu) * (n - mn);
  }
  if (suu <= 1e-12) return;
  final kLs = sun / suu;
  final sigN2 =
      _sq(p['rir_noise_sd']!) + _sq(tr.kPrior * p['sigma_day']! * (1.0 + mu));
  final vLs = sigN2 / suu;
  final w0 = 1.0 / _sq(p['k_prior_sd']!);
  final k = (tr.kPrior * w0 + kLs / vLs) / (w0 + 1.0 / vLs);
  tr.k = math.min(p['k_max']!, math.max(p['k_min']!, k));
  tr.kPersonal = true;
}

/// D19 : écart entre RIR déclaré et RIR impliqué par une ancre, sur les
/// séances des 21 jours précédents.
void _biasUpdate(
  KContext ctx,
  KoachState state,
  _Anchor anchor,
  double t,
  Map<String, dynamic> s,
) {
  final p = ctx.p;
  final bias = state.bias;
  final z = anchor.z;
  final lo = t - p['bias_window_days']! * _day;
  final diffs = <double>[];
  double sigN;
  if (anchor.type == 'test' || anchor.type == 'failed') {
    Map<String, dynamic>? found;
    for (final l in ctx.lifts) {
      if (l['key'] == anchor.key) found = l;
    }
    final lift = found!;
    final tr = state.tracks[anchor.key]!;
    final k = tr.k;
    final pcts = <double>[];
    final kNew = <(double, double)>[];
    for (final ses in ctx.sessions) {
      if (ses.t < lo || ses.t >= t || ses.key == s['key']) continue;
      final bw = ctx.bw(dayOf(ses.t));
      for (final ex in _list(ses.s['exercises'])) {
        if (ex['ref'] != lift['ref'] ||
            ex['cat'] != 'strength' ||
            _truthy(ex['cluster'])) {
          continue;
        }
        for (final st in _list(ex['sets'])) {
          final reps = _in(st['reps']);
          if (!_truthy(st['done']) ||
              _truthy(st['excluded']) ||
              reps == null ||
              reps == 0) {
            continue;
          }
          final rir = _dn(st['rir']);
          if (rir == null ||
              rir > p['valid_rir_max']! ||
              reps + rir > p['valid_n_max']!) {
            continue;
          }
          if (isFailed(ex, st)) continue;
          final m = liftMass(lift, st, bw);
          if (m == null || m <= 0) continue;
          final nImp = 1.0 + k * (z / m - 1.0);
          diffs.add((nImp - reps) - rir);
          pcts.add(m / z);
          if (anchor.type == 'test') kNew.add((z / m - 1.0, reps + rir));
        }
      }
    }
    for (final (u, n) in kNew) {
      if (tr.nMin == null || n < tr.nMin!) tr.nMin = n;
      if (tr.nMax == null || n > tr.nMax!) tr.nMax = n;
      tr.kObs.add((u, n));
    }
    if (kNew.isNotEmpty) _kRefit(tr, p);
    if (diffs.length < p['bias_min_sets']!) return;
    var sp = 0.0;
    for (final v in pcts) {
      sp += v;
    }
    final pAvg = sp / pcts.length;
    sigN = k * anchor.sigRel / pAvg;
  } else {
    for (final ses in ctx.sessions) {
      if (ses.t < lo || ses.t >= t || ses.key == s['key']) continue;
      Map<String, dynamic>? first;
      for (final ex in _list(ses.s['exercises'])) {
        if (ex['ref'] != anchor.key ||
            ex['cat'] != 'endurance' ||
            _truthy(ex['emom'])) {
          continue;
        }
        for (final st in _list(ex['sets'])) {
          final reps = _in(st['reps']);
          if (_truthy(st['done']) &&
              !_truthy(st['excluded']) &&
              reps != null &&
              reps != 0) {
            first = st;
            break;
          }
        }
        if (first != null) break;
      }
      if (first != null) {
        final rir = _dn(first['rir']);
        if (rir != null && rir <= p['end_rir_max']!) {
          diffs.add((z - _in(first['reps'])!) - rir);
        }
      }
    }
    if (diffs.length < p['bias_min_sets']!) return;
    sigN = anchor.sigRel * z;
  }
  var sd = 0.0;
  for (final v in diffs) {
    sd += v;
  }
  final bObs = sd / diffs.length;
  final r = _sq(p['rir_noise_sd']!) / diffs.length + sigN * sigN;
  final g = bias.p! / (bias.p! + r);
  bias.b += g * (bObs - bias.b);
  bias.p = bias.p! * (1.0 - g);
  bias.b = math.min(p['bias_max']!, math.max(p['bias_min']!, bias.b));
  bias.updates += 1;
}

// ---------------------------------------------------------------------------
// D25 — jour de fatigue
// ---------------------------------------------------------------------------
/// Réduction de volume proposée : 0 (rien), 0.15, 0.25 ou 0.30.
double fatigueLevel(
  Map<String, double> p,
  double? xCurrent,
  double? mass,
  int? reps,
  double? rir,
  double b,
  double k, {
  bool failed = false,
  double? sleep,
  double? form,
}) {
  var level = 0.0;
  if (sleep != null && sleep < p['sleep_min']! - koachEps) {
    level = p['fatigue_cut_3']!;
  }
  if (form != null && form <= p['form_max']! + koachEps) {
    level = p['fatigue_cut_3']!;
  }
  if (mass != null &&
      reps != null &&
      reps != 0 &&
      xCurrent != null &&
      xCurrent != 0) {
    double? n;
    if (failed) {
      n = reps + p['failed_extra']!;
    } else if (rir != null) {
      n = reps + math.max(0.0, rir + b);
    }
    if (n != null) {
      final gap = oneRm(mass, n, k) / xCurrent - 1.0;
      if (gap <= p['fatigue_3']! + koachEps) {
        level = math.max(level, p['fatigue_cut_3']!);
      } else if (gap <= p['fatigue_2']! + koachEps) {
        level = math.max(level, p['fatigue_cut_2']!);
      } else if (gap <= p['fatigue_1']! + koachEps) {
        level = math.max(level, p['fatigue_cut_1']!);
      }
    }
  }
  return level;
}

// ---------------------------------------------------------------------------
// D24 — prescription pendant la séance
// ---------------------------------------------------------------------------
/// Suggestion de charge pour les séries restantes.
class KSuggestion {
  final double kg, from, delta;
  final String direction; // up | down
  final String reason; // easy1 | easy2 | twoHard | missed | missed2
  const KSuggestion(
    this.kg,
    this.from,
    this.delta,
    this.direction,
    this.reason,
  );

  Map<String, dynamic> toJson() => {
    'kg': kg,
    'from': from,
    'delta': delta,
    'direction': direction,
    'reason': reason,
  };
}

/// `sets` : séries validées et non écartées du jour, dans l'ordre
/// ({kg, reps, rir}). `flags` : locked (D6), deload / pain / fatigue
/// (aucune hausse), refused = directions refusées (D7).
KSuggestion? inSession(
  Map<String, double> p,
  Map<String, dynamic> lift,
  List<Map<String, dynamic>> sets,
  double? rirTarget,
  int? planned,
  double? bw,
  double grid,
  Map<String, dynamic> flags,
) {
  if (_truthy(flags['locked']) || sets.isEmpty || rirTarget == null) {
    return null;
  }
  final body = lift['bodyweight'] == true;
  if (body && bw == null) return null;
  final cur = sets.last;
  final kg = _dn(cur['kg']) ?? 0.0;
  final mass = body ? bw! + kg : kg;
  if (mass <= 0) return null;
  final refused = [
    for (final e in (flags['refused'] as List?) ?? const []) e as String,
  ];
  final noUp =
      _truthy(flags['deload']) ||
      _truthy(flags['pain']) ||
      _truthy(flags['fatigue']);

  KSuggestion? change(double delta, double? cap, bool up, String reason) {
    if (up && (noUp || refused.contains('up'))) return null;
    if (!up && refused.contains('down')) return null;
    final raw = mass * (1.0 + delta);
    final target = body ? raw - bw! : raw;
    double next;
    if (up) {
      final limit = cap == null ? target : math.min(target, kg + cap);
      next = floorGrid(limit, grid);
      if (next <= kg + koachEps) return null;
    } else {
      next = ceilGrid(target, grid);
      if (body && next < 0) next = 0.0;
      if (next >= kg - koachEps) return null;
    }
    return KSuggestion(r2(next), r2(kg), delta, up ? 'up' : 'down', reason);
  }

  final reps = _in(cur['reps']);
  if (planned != null && reps != null && reps < planned) {
    final big = planned - reps >= 2;
    return change(
      -(big ? p['down_big']! : p['down']!),
      null,
      false,
      big ? 'missed2' : 'missed',
    );
  }
  if (sets.length >= 2 && rirTarget >= 2) {
    final a = sets[sets.length - 2];
    final ra = _dn(a['rir']), rb = _dn(cur['rir']);
    if (ra != null && rb != null && ra <= 1 && rb <= 1) {
      return change(-p['down']!, null, false, 'twoHard');
    }
  }
  if (sets.length == 1) {
    final rir = _dn(cur['rir']);
    if (rir == null) return null;
    if (rir >= rirTarget + 2 - koachEps) {
      return change(p['up_big']!, p['up_big_cap']!, true, 'easy2');
    }
    if (rir >= rirTarget + 1 - koachEps) {
      return change(p['up_small']!, p['up_small_cap']!, true, 'easy1');
    }
  }
  return null;
}

// ---------------------------------------------------------------------------
// Propositions de fin de séance (D5 b, D20, D21, D22, D26, D33)
// ---------------------------------------------------------------------------
int weeksSinceChange(
  Map<String, dynamic> inp,
  String ref,
  double t,
  Map<String, double> p,
) {
  double? last;
  for (final h in _list(inp['history'])) {
    if (h['ref'] != ref) continue;
    final th = parseDt(h['at'] as String?);
    if (th != null && th <= t && (last == null || th > last)) last = th;
  }
  if (last == null) return 1;
  final w = ((t - last) / (7 * _day) - koachEps).ceil();
  return math.max(1, math.min(p['cap_weeks_max']!.toInt(), w));
}

List<Map<String, dynamic>> proposals(
  Map<String, dynamic> inp,
  KoachState state,
  String sessionKey,
) {
  final p = paramsOf(inp);
  final refs =
      ((inp['references'] as Map?) ?? const {}).cast<String, dynamic>();
  final equipment =
      (inp['equipment'] as Map?)?.cast<String, dynamic>() ??
      Map<String, dynamic>.from(defaultEquipment);
  final locks = {
    for (final l in (inp['locks'] as List?) ?? const []) l as String,
  };
  final pains = (inp['pain'] as Map?)?.cast<String, dynamic>() ?? const {};
  Map<String, dynamic>? sess;
  for (final s in _list(inp['sessions'])) {
    if (s['key'] == sessionKey) sess = s;
  }
  if (sess == null) return [];
  final t = sessionTime(sess);
  if (t == null) return [];
  final now = parseDt(inp['now'] as String?)!;
  final bwNow = state.bwNow;
  final dayBw = bodyweightAt(
    (inp['weighIns'] as List?) ?? const [],
    dayOf(t),
    _dn(refs['B4']),
  );
  final here = (pains[sessionKey] as Map?)?.cast<String, dynamic>() ?? const {};
  final out = <Map<String, dynamic>>[];
  final allEx = _list(sess['exercises']);
  for (final lift in _list(inp['lifts'])) {
    final key = lift['key'] as String, ref = lift['ref'] as String;
    final exs = [
      for (final ex in allEx)
        if (ex['ref'] == ref &&
            (ex['cat'] == 'strength' || ex['cat'] == 'test1rm'))
          ex,
    ];
    if (!_anyDone(exs)) continue;
    final tr = state.tracks[key];
    final cur = _dn(refs[ref]);
    if (tr == null || cur == null || locks.contains(ref)) continue;
    final body = lift['bodyweight'] == true;
    if (body && bwNow == null) continue;
    final grid = _num(lift['grid']);
    final bw = body ? bwNow! : 0.0;
    final painful = (_dn(here[key]) ?? 0) > p['pain_threshold']!;
    double? testBest;
    for (final ex in exs) {
      if (ex['cat'] != 'test1rm') continue;
      for (final st in _list(ex['sets'])) {
        final reps = _in(st['reps']);
        if (_truthy(st['done']) &&
            !_truthy(st['excluded']) &&
            reps != null &&
            reps != 0) {
          final m = liftMass(lift, st, dayBw);
          if (m == null) continue;
          final z = oneRm(m, reps.toDouble(), tr.k);
          if (testBest == null || z > testBest) testBest = z;
        }
      }
    }
    if (testBest != null) {
      // Test mesuré : proposé tel quel (source « test »), sans plafond.
      var val = nearGrid(testBest - (body ? dayBw! : 0.0), grid);
      if (body && val < 0) val = 0.0;
      if ((val - cur).abs() > koachEps && !(painful && val > cur)) {
        out.add({
          'id': '$sessionKey|$ref',
          'ref': ref,
          'kind': 'value',
          'from': r2(cur),
          'to': r2(val),
          'source': 'test',
          'reason': 'test',
        });
      }
      continue;
    }
    if (tr.sd > p['uncertain']! * tr.x || tr.lastMeasure == null) continue;
    final target = tr.x - bw;
    if ((target - cur).abs() < p['hysteresis']! * grid) continue;
    final w = weeksSinceChange(inp, ref, now, p);
    final curSys = cur + bw;
    final hi = curSys * (1.0 + p['cap_up']! * w) - bw;
    final lo = curSys * (1.0 - p['cap_down']! * w) - bw;
    var val = nearGrid(target, grid);
    if (val > hi + koachEps) val = floorGrid(hi, grid);
    if (val < lo - koachEps) val = ceilGrid(lo, grid);
    if (body && val < 0) val = 0.0;
    if (painful && val > cur) continue;
    if ((val - cur).abs() > koachEps) {
      out.add({
        'id': '$sessionKey|$ref',
        'ref': ref,
        'kind': 'value',
        'from': r2(cur),
        'to': r2(val),
        'source': 'koach',
        'reason': val > cur ? 'up' : 'down',
      });
    }
  }
  for (final spec in _list(inp['repmax'])) {
    final ref = spec['ref'] as String;
    final exs = [
      for (final ex in allEx)
        if (ex['ref'] == ref &&
            (ex['cat'] == 'endurance' || ex['cat'] == 'enduranceTest'))
          ex,
    ];
    if (!_anyDone(exs)) continue;
    final tr = state.rtracks[ref];
    final cur = _dn(refs[ref]);
    if (tr == null || cur == null || locks.contains(ref)) continue;
    int? testMax;
    for (final ex in exs) {
      if (ex['cat'] != 'enduranceTest') continue;
      for (final st in _list(ex['sets'])) {
        final reps = _in(st['reps']);
        if (_truthy(st['done']) && !_truthy(st['excluded']) && reps != null) {
          if (testMax == null || reps > testMax) testMax = reps;
        }
      }
    }
    if (testMax != null && testMax > 0) {
      if ((testMax - cur).abs() > koachEps) {
        out.add({
          'id': '$sessionKey|$ref',
          'ref': ref,
          'kind': 'value',
          'from': r2(cur),
          'to': testMax.toDouble(),
          'source': 'test',
          'reason': 'test',
        });
      }
      continue;
    }
    if (tr.lastMeasure == null || tr.sd > p['end_uncertain']! * tr.x) continue;
    if ((tr.x - cur).abs() < 1.0) continue;
    final w = weeksSinceChange(inp, ref, now, p);
    final hi = cur * (1.0 + p['cap_up']! * w);
    final lo = cur * (1.0 - p['cap_down']! * w);
    var val = kRound(tr.x);
    if (val > hi + koachEps) val = (hi + koachEps).floorToDouble();
    if (val < lo - koachEps) val = (lo - koachEps).ceilToDouble();
    if ((val - cur).abs() > koachEps) {
      out.add({
        'id': '$sessionKey|$ref',
        'ref': ref,
        'kind': 'value',
        'from': r2(cur),
        'to': val,
        'source': 'koach',
        'reason': val > cur ? 'up' : 'down',
      });
    }
  }
  out.addAll(_accessoryProposals(inp, p, sess, sessionKey, equipment, locks));
  out.addAll(_painProposals(inp, p, sessionKey));
  return out;
}

/// D22 : double progression ; `prevention` : jamais de hausse.
List<Map<String, dynamic>> _accessoryProposals(
  Map<String, dynamic> inp,
  Map<String, double> p,
  Map<String, dynamic> sess,
  String sessionKey,
  Map<String, dynamic> equipment,
  Set<String> locks,
) {
  final out = <Map<String, dynamic>>[];
  final refs =
      ((inp['references'] as Map?) ?? const {}).cast<String, dynamic>();
  final order = sortedSessions(inp);
  final t = sessionTime(sess)!;
  for (final a in _list(inp['accessories'])) {
    final ref = a['ref'] as String;
    final done = <(Map<String, dynamic>, Map<String, dynamic>)>[];
    for (final ex in _list(sess['exercises'])) {
      if (ex['ref'] == ref && ex['cat'] == 'accessory') {
        for (final st in _list(ex['sets'])) {
          if (_truthy(st['done']) && !_truthy(st['excluded'])) {
            done.add((ex, st));
          }
        }
      }
    }
    if (done.isEmpty || locks.contains(ref) || refs[ref] == null) continue;
    final cur = _num(refs[ref]);
    var success = true;
    var failed = false;
    for (final (ex, st) in done) {
      final planned = _in(ex['plannedReps']);
      final target = _dn(ex['rirTarget']);
      final reps = _in(st['reps']);
      final rir = _dn(st['rir']);
      if (planned == null || reps == null) {
        success = false;
      } else if (reps < planned) {
        failed = true;
        success = false;
      } else if (target == null || rir == null || rir < target + 1 - koachEps) {
        success = false;
      }
    }
    final kind = a['equipment'] as String;
    if (success && a['prevention'] != true) {
      final val = gridNext(cur, kind, equipment, true);
      out.add({
        'id': '$sessionKey|$ref',
        'ref': ref,
        'kind': 'value',
        'from': r2(cur),
        'to': r2(val),
        'source': 'koach',
        'reason': 'accUp',
      });
    } else if (failed) {
      var prevFailed = false;
      for (var i = order.length - 1; i >= 0; i--) {
        final o = order[i];
        if (o.t >= t || o.key == sessionKey) continue;
        final prev = <(Map<String, dynamic>, Map<String, dynamic>)>[];
        for (final ex in _list(o.s['exercises'])) {
          if (ex['ref'] == ref && ex['cat'] == 'accessory') {
            for (final st in _list(ex['sets'])) {
              if (_truthy(st['done']) && !_truthy(st['excluded'])) {
                prev.add((ex, st));
              }
            }
          }
        }
        if (prev.isEmpty) continue;
        for (final (ex, st) in prev) {
          if (isFailed(ex, st)) prevFailed = true;
        }
        break;
      }
      if (prevFailed) {
        final val = gridNext(cur, kind, equipment, false);
        if (val < cur - koachEps) {
          out.add({
            'id': '$sessionKey|$ref',
            'ref': ref,
            'kind': 'value',
            'from': r2(cur),
            'to': r2(val),
            'source': 'koach',
            'reason': 'accDown',
          });
        }
      }
    }
  }
  return out;
}

/// D26 : douleur > 3/10 deux séances de suite → allègement −20 %.
List<Map<String, dynamic>> _painProposals(
  Map<String, dynamic> inp,
  Map<String, double> p,
  String sessionKey,
) {
  final pains = (inp['pain'] as Map?)?.cast<String, dynamic>() ?? const {};
  final here = (pains[sessionKey] as Map?)?.cast<String, dynamic>() ?? const {};
  final order = [for (final s in sortedSessions(inp)) s.key];
  final idx = order.indexOf(sessionKey);
  if (idx < 0) return [];
  final active = {
    for (final m in (inp['painRelief'] as List?) ?? const []) m as String,
  };
  final out = <Map<String, dynamic>>[];
  for (final lift in _list(inp['lifts'])) {
    final key = lift['key'] as String;
    if ((_dn(here[key]) ?? 0) <= p['pain_threshold']! || active.contains(key)) {
      continue;
    }
    double? prev;
    for (var j = idx - 1; j >= 0; j--) {
      final q = (pains[order[j]] as Map?)?.cast<String, dynamic>() ?? const {};
      if (q.containsKey(key)) {
        prev = _dn(q[key]);
        break;
      }
    }
    if (prev != null && prev > p['pain_threshold']!) {
      out.add({
        'id': '$sessionKey|pain|$key',
        'ref': lift['ref'],
        'kind': 'pain',
        'movement': key,
        'cut': p['pain_cut']!,
        'source': 'koach',
        'reason': 'pain',
      });
    }
  }
  return out;
}

/// D26 : douleur > 3/10 à la dernière séance notée de ce mouvement.
bool painBlocks(Map<String, dynamic> inp, String key) {
  final p = paramsOf(inp);
  final pains = (inp['pain'] as Map?)?.cast<String, dynamic>() ?? const {};
  final order = sortedSessions(inp);
  for (var i = order.length - 1; i >= 0; i--) {
    final q =
        (pains[order[i].key] as Map?)?.cast<String, dynamic>() ?? const {};
    if (q.containsKey(key)) return (_dn(q[key]) ?? 0) > p['pain_threshold']!;
  }
  return false;
}

// ---------------------------------------------------------------------------
// D27 — objectifs, pentes, statut
// ---------------------------------------------------------------------------
KSeriesPoint? estimateAt(List<KSeriesPoint> series, double t) {
  KSeriesPoint? last;
  for (final pt in series) {
    final tp = parseDt(pt.at);
    if (tp != null && tp <= t + koachEps) last = pt;
  }
  return last;
}

/// Pente (unités / semaine) des estimations des `weeks` dernières semaines.
double? slopePerWeek(
  List<KSeriesPoint> series,
  double now,
  int weeks, [
  double offset = 0.0,
]) {
  final pts = <(double, double)>[];
  for (var i = 0; i < weeks; i++) {
    final pt = estimateAt(series, now - i * 7 * _day);
    if (pt != null) pts.add((-i.toDouble(), pt.x - offset));
  }
  if (pts.length < 3) return null;
  final n = pts.length.toDouble();
  var sx = 0.0, sy = 0.0;
  for (final (x, y) in pts) {
    sx += x;
    sy += y;
  }
  final mx = sx / n, my = sy / n;
  var sxx = 0.0, sxy = 0.0;
  for (final (x, _) in pts) {
    sxx += _sq(x - mx);
  }
  if (sxx <= 0) return null;
  for (final (x, y) in pts) {
    sxy += (x - mx) * (y - my);
  }
  return sxy / sxx;
}

Map<String, dynamic> objectiveStatus(
  Map<String, double> p,
  double? current,
  double? slope,
  double? target,
  int? targetDay,
  int nowDay,
) {
  if (target == null || targetDay == null || current == null) {
    return {'status': 'none'};
  }
  if (current >= target - koachEps) return {'status': 'reached'};
  final weeksLeft = (targetDay - nowDay) / 7.0;
  if (weeksLeft <= 0) return {'status': 'past'};
  final required = (target - current) / weeksLeft;
  if (slope == null)
    return {'status': 'insufficient', 'required': r2(required)};
  final ratio = slope / required;
  final status =
      ratio < p['late']!
          ? 'late'
          : ratio > p['ahead']!
          ? 'ahead'
          : 'onTrack';
  return {
    'status': status,
    'required': r2(required),
    'observed': r2(slope),
    'ratio': r2(ratio),
  };
}

Map<String, dynamic> objectives(Map<String, dynamic> inp, KoachState state) {
  final p = paramsOf(inp);
  final now = parseDt(inp['now'] as String?)!;
  final nowDay = dayOf(now);
  final bw = state.bwNow ?? 0.0;
  final goals =
      (inp['objectives'] as Map?)?.cast<String, dynamic>() ?? const {};
  final out = <String, dynamic>{};

  void one(String ref, KTrack tr, double off) {
    final cur = tr.x - off;
    final slope = slopePerWeek(tr.series, now, p['slope_weeks']!.toInt(), off);
    final res = <String, dynamic>{};
    final g = (goals[ref] as Map?)?.cast<String, dynamic>() ?? const {};
    for (final level in const ['stage', 'final']) {
      final o = (g[level] as Map?)?.cast<String, dynamic>();
      if (o == null) continue;
      final d = o['date'] == null ? null : parseDt(o['date'] as String);
      res[level] = objectiveStatus(
        p,
        cur,
        slope,
        _dn(o['target']),
        d == null ? null : dayOf(d),
        nowDay,
      );
    }
    out[ref] = {
      'current': r2(cur),
      'slope': slope == null ? null : r2(slope),
      'objectives': res,
    };
  }

  for (final lift in _list(inp['lifts'])) {
    final tr = state.tracks[lift['key']];
    if (tr != null) {
      one(lift['ref'] as String, tr, lift['bodyweight'] == true ? bw : 0.0);
    }
  }
  for (final spec in _list(inp['repmax'])) {
    final tr = state.rtracks[spec['ref']];
    if (tr != null) one(spec['ref'] as String, tr, 0.0);
  }
  return out;
}

// ---------------------------------------------------------------------------
// D28 — option « Koach adapte la structure »
// ---------------------------------------------------------------------------
List<Map<String, dynamic>> structure(
  Map<String, dynamic> inp,
  KoachState state,
  int week,
) {
  final p = paramsOf(inp);
  Map<String, dynamic>? info;
  for (final w in _list(inp['weeks'])) {
    if (_in(w['n']) == week) info = w;
  }
  if (info == null || info['type'] == 'deload' || info['type'] == 'test') {
    return [];
  }
  final total = _dn(info['totalSets']) ?? 0.0;
  final cap = (p['struct_total_cap']! * total + koachEps).floor();
  final objs = objectives(inp, state);
  final out = <Map<String, dynamic>>[];
  var used = 0;
  final mains = (info['main'] as Map?)?.cast<String, dynamic>() ?? const {};
  for (final lift in _list(inp['lifts'])) {
    final key = lift['key'] as String, ref = lift['ref'] as String;
    final tr = state.tracks[key];
    final main = mains[key] as String?;
    if (tr == null ||
        main == null ||
        main.isEmpty ||
        tr.validWeeks.length < p['struct_min_weeks']!) {
      continue;
    }
    final o =
        ((objs[ref] as Map?)?['objectives'] as Map?)?.cast<String, dynamic>() ??
        const {};
    var st = (o['stage'] as Map?)?.cast<String, dynamic>();
    if (st == null ||
        st['status'] == 'none' ||
        st['status'] == 'reached' ||
        st['status'] == 'past') {
      st = (o['final'] as Map?)?.cast<String, dynamic>();
    }
    if (st == null) continue;
    final status = st['status'] as String;
    final delta =
        status == 'late'
            ? 1
            : status == 'ahead'
            ? -1
            : 0;
    if (delta == 0 || used + 1 > cap) continue;
    used += 1;
    out.add({
      'id': 'W$week|sets|$key',
      'week': week,
      'kind': 'sets',
      'movement': key,
      'exercise': main,
      'delta': delta,
      'reason': status,
    });
  }
  final now = parseDt(inp['now'] as String?)!;
  final quest =
      (inp['questionnaires'] as Map?)?.cast<String, dynamic>() ?? const {};
  for (final lift in _list(inp['lifts'])) {
    final key = lift['key'] as String;
    final tr = state.tracks[key];
    if (tr == null) continue;
    final measured = [
      for (final pt in tr.series)
        if (pt.z != null) pt,
    ];
    final p0 = estimateAt(measured, now);
    final p1 = estimateAt(measured, now - 7 * _day);
    final p2 = estimateAt(measured, now - 14 * _day);
    if (p0 == null || p1 == null || p2 == null) continue;
    if (p0.session == p1.session || p1.session == p2.session) continue;
    if (!(p2.z! > p1.z! + koachEps && p1.z! > p0.z! + koachEps)) continue;
    final lo = now - 14 * _day;
    var signal = false;
    for (final pt in tr.series) {
      final tp = parseDt(pt.at);
      if (tp == null || tp < lo || pt.kind != 'session') continue;
      final sk = pt.session;
      if (state.fatigue[sk]?.containsKey(key) ?? false) signal = true;
      final q = (quest[sk] as Map?)?.cast<String, dynamic>() ?? const {};
      final sleep = _dn(q['sleep']), form = _dn(q['form']);
      if (sleep != null && sleep < p['sleep_min']! - koachEps) signal = true;
      if (form != null && form <= p['form_max']! + koachEps) signal = true;
    }
    if (signal) {
      out.add({
        'id': 'W$week|deload',
        'week': week,
        'kind': 'deload',
        'movement': key,
        'sets': p['deload_sets']!,
        'load': p['deload_load']!,
        'reason': 'decline',
      });
      break;
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// Sorties résumées (fixtures)
// ---------------------------------------------------------------------------
Map<String, dynamic> summarize(KoachState state) {
  final lifts = <String, dynamic>{};
  for (final key in state.tracks.keys.toList()..sort()) {
    final tr = state.tracks[key]!;
    lifts[key] = {
      'x': r2(tr.x),
      'sd': r2(tr.sd),
      'k': r2(tr.k),
      'kPersonal': tr.kPersonal,
      'validSets': tr.validSets,
      'validWeeks': tr.validWeeks.length,
      'pending': tr.pending != null,
      'series': [for (final pt in tr.series) r2(pt.x)],
    };
  }
  final repmax = <String, dynamic>{};
  for (final ref in state.rtracks.keys.toList()..sort()) {
    final tr = state.rtracks[ref]!;
    repmax[ref] = {
      'x': r2(tr.x),
      'sd': r2(tr.sd),
      'validWeeks': tr.validWeeks.length,
      'series': [for (final pt in tr.series) r2(pt.x)],
    };
  }
  return {
    'bias': r2(state.bias.b),
    'biasUpdates': state.bias.updates,
    'lifts': lifts,
    'repmax': repmax,
    'bwNow': state.bwNow == null ? null : r2(state.bwNow!),
  };
}

/// Exécute un cas de fixture (mêmes clés que `run_case` en Python).
Map<String, dynamic> runCase(Map<String, dynamic> kase) {
  final out = <String, dynamic>{};
  final inp = (kase['input'] as Map?)?.cast<String, dynamic>();
  if (inp != null) {
    final state = replay(inp);
    out['state'] = summarize(state);
    if (kase['proposalsFor'] != null) {
      out['proposals'] = proposals(inp, state, kase['proposalsFor'] as String);
    }
    if (kase['objectives'] == true) out['objectives'] = objectives(inp, state);
    if (kase['structureWeek'] != null) {
      out['structure'] = structure(inp, state, _in(kase['structureWeek'])!);
    }
    final pb = kase['painBlocks'] as List?;
    if (pb != null && pb.isNotEmpty) {
      out['painBlocks'] = {for (final k in pb) k as String: painBlocks(inp, k)};
    }
  }
  final p = Map<String, double>.of(koachParams);
  final ins = kase['inSession'] as List?;
  if (ins != null) {
    out['inSession'] = [
      for (final raw in ins)
        () {
          final c = (raw as Map).cast<String, dynamic>();
          return inSession(
            p,
            (c['lift'] as Map).cast<String, dynamic>(),
            _list(c['sets']),
            _dn(c['rirTarget']),
            _in(c['planned']),
            _dn(c['bw']),
            _num(c['grid']),
            (c['flags'] as Map?)?.cast<String, dynamic>() ?? const {},
          )?.toJson();
        }(),
    ];
  }
  final fat = kase['fatigue'] as List?;
  if (fat != null) {
    out['fatigue'] = [
      for (final raw in fat)
        () {
          final c = (raw as Map).cast<String, dynamic>();
          return fatigueLevel(
            p,
            _dn(c['x']),
            _dn(c['mass']),
            _in(c['reps']),
            _dn(c['rir']),
            _dn(c['b']) ?? 0.0,
            _num(c['k']),
            failed: c['failed'] == true,
            sleep: _dn(c['sleep']),
            form: _dn(c['form']),
          );
        }(),
    ];
  }
  final legacy = kase['legacyEffort'] as List?;
  if (legacy != null) {
    out['legacyEffort'] = [
      for (final raw in legacy)
        parseLegacyEffort(
          (raw as Map)['text'] as String?,
          raw['scale'] as String,
        ),
    ];
  }
  final grid = kase['grid'] as List?;
  if (grid != null) {
    final eq =
        (kase['equipment'] as Map?)?.cast<String, dynamic>() ??
        Map<String, dynamic>.from(defaultEquipment);
    out['grid'] = [
      for (final raw in grid)
        () {
          final c = (raw as Map).cast<String, dynamic>();
          return c.containsKey('up')
              ? r2(
                gridNext(
                  _num(c['kg']),
                  c['kind'] as String,
                  eq,
                  c['up'] == true,
                ),
              )
              : r2(gridRound(_num(c['kg']), c['kind'] as String, eq));
        }(),
    ];
  }
  return out;
}
