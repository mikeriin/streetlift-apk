// G9 (D5.3-D5.10) : séance servie par le moteur dynamique `kalis_adapt`,
// telle que l'application la garde dans le journal (champ `adapt` d'une
// séance, version 1, facultatif).
//
// - le bilan santé du début de séance (seules les réponses données) ;
// - la séance prescrite, figée à la prescription (rien ne bouge si
//   l'application est fermée puis rouverte), et la séance sans l'effet du
//   bilan quand il change quelque chose ([SessionAdapt.base]) ;
// - la suite donnée à l'ajustement du bilan (mode assisté : appliqué ou
//   annulé ; mode libre : en attente, accepté ou gardé) ;
// - les conseils pendant la séance, série par série ([AdviceStep]).
//
// Fonctions pures : aucune horloge, aucun stockage.
import 'package:kalis_core/kalis_core.dart' as kc;

const kSessionAdaptVersion = 1;

/// Suites possibles d'un ajustement (bilan, conseil).
const kAdaptChoices = {'applied', 'undone', 'pending', 'accepted', 'kept'};

/// Conseil pendant la séance pour un exercice : à partir de la série
/// [from] (rang dans le journal de l'exercice), nouvelles cibles.
class AdviceStep {
  final int from;
  final String action;
  final double? kg;
  final int? low;
  final int? high;
  final String status;
  final List<kc.Reason> reasons;

  /// Repos conseillé après la série (secondes).
  final int? rest;
  const AdviceStep({
    required this.from,
    required this.action,
    this.kg,
    this.low,
    this.high,
    required this.status,
    this.reasons = const [],
    this.rest,
  });

  /// Le conseil vaut pour les séries (appliqué ou accepté).
  bool get active => status == 'applied' || status == 'accepted';

  AdviceStep withStatus(String s) => AdviceStep(
    from: from,
    action: action,
    kg: kg,
    low: low,
    high: high,
    status: s,
    reasons: reasons,
    rest: rest,
  );

  Map<String, Object?> toJson() => {
    'from': from,
    'action': action,
    if (kg != null) 'kg': kg,
    if (low != null) 'low': low,
    if (high != null) 'high': high,
    'status': status,
    if (reasons.isNotEmpty) 'reasons': [for (final r in reasons) r.toJson()],
    if (rest != null) 'rest': rest,
  };

  static AdviceStep fromJson(Object? raw) {
    if (raw is! Map) throw const FormatException('Conseil invalide.');
    final from = raw['from'];
    final action = raw['action'];
    final status = raw['status'];
    if (from is! int ||
        from < 0 ||
        from > 1000 ||
        action is! String ||
        action.length > 40 ||
        status is! String ||
        !kAdaptChoices.contains(status)) {
      throw const FormatException('Conseil invalide.');
    }
    final kg = raw['kg'];
    if (kg != null && (kg is! num || !kg.isFinite || kg.abs() > 1000)) {
      throw const FormatException('Conseil invalide.');
    }
    int? small(String k, int max) {
      final v = raw[k];
      if (v == null) return null;
      if (v is! int || v < 0 || v > max) {
        throw const FormatException('Conseil invalide.');
      }
      return v;
    }

    final reasons = <kc.Reason>[];
    final r = raw['reasons'];
    if (r != null) {
      if (r is! List || r.length > 20) {
        throw const FormatException('Conseil invalide.');
      }
      for (final x in r) {
        if (x is! Map) throw const FormatException('Conseil invalide.');
        reasons.add(kc.Reason.fromJson(x.cast<String, Object?>()));
      }
    }
    return AdviceStep(
      from: from,
      action: action,
      kg: (kg as num?)?.toDouble(),
      low: small('low', 86400),
      high: small('high', 86400),
      status: status,
      reasons: reasons,
      rest: small('rest', 900),
    );
  }
}

/// Séance servie par le moteur dynamique.
class SessionAdapt {
  /// Place dans le bloc (`ProgramRef`).
  final String blockId;
  final int weekIndex;
  final int dayIndex;

  /// Jour civil de la prescription.
  final String date;

  /// Mode du profil à la prescription (`assisted`, `free`).
  final String mode;

  /// Question « Comment tu te sens ? » réglée (répondue ou passée).
  final bool asked;

  /// Bilan du jour : seules les réponses données (null : aucun bilan).
  final kc.HealthCheck? check;

  /// Lieu du jour, s'il diffère du lieu prévu.
  final kc.Place? place;

  /// Séance prescrite avec le bilan et le lieu du jour.
  final kc.SessionPlan plan;

  /// Séance prescrite sans l'effet du bilan (même lieu), quand elle
  /// diffère de [plan].
  final kc.SessionPlan? base;

  /// Suite donnée à l'ajustement du bilan (null : rien à décider).
  final String? choice;

  /// Conseils pendant la séance, par exercice (clé du journal).
  final Map<String, List<AdviceStep>> advice;

  const SessionAdapt({
    required this.blockId,
    required this.weekIndex,
    required this.dayIndex,
    required this.date,
    required this.mode,
    this.asked = false,
    this.check,
    this.place,
    required this.plan,
    this.base,
    this.choice,
    this.advice = const {},
  });

  bool get assisted => mode == 'assisted';

  /// L'ajustement du bilan vaut pour la séance.
  bool get adjusted =>
      base != null && (choice == 'applied' || choice == 'accepted');

  /// Séance faite : avec l'ajustement du bilan, ou sans.
  kc.SessionPlan get active => base == null || adjusted ? plan : base!;

  /// L'ajustement attend la décision de l'utilisateur (mode libre).
  bool get pending => base != null && choice == 'pending';

  /// Bilan donné au moteur pour la séance faite.
  kc.HealthCheck? get activeCheck => base == null || adjusted ? check : null;

  SessionAdapt copyWith({
    bool? asked,
    kc.HealthCheck? check,
    bool clearCheck = false,
    kc.Place? place,
    bool clearPlace = false,
    kc.SessionPlan? plan,
    kc.SessionPlan? base,
    bool clearBase = false,
    String? choice,
    bool clearChoice = false,
    Map<String, List<AdviceStep>>? advice,
    String? date,
    String? mode,
  }) => SessionAdapt(
    blockId: blockId,
    weekIndex: weekIndex,
    dayIndex: dayIndex,
    date: date ?? this.date,
    mode: mode ?? this.mode,
    asked: asked ?? this.asked,
    check: clearCheck ? null : (check ?? this.check),
    place: clearPlace ? null : (place ?? this.place),
    plan: plan ?? this.plan,
    base: clearBase ? null : (base ?? this.base),
    choice: clearChoice ? null : (choice ?? this.choice),
    advice: advice ?? this.advice,
  );

  /// Conseils d'un exercice, avec [step] ajouté.
  SessionAdapt withAdvice(String exerciseKey, AdviceStep step) {
    final next = {
      for (final e in advice.entries) e.key: [...e.value],
    };
    (next[exerciseKey] ??= []).add(step);
    return copyWith(advice: next);
  }

  /// Retire le dernier conseil de [exerciseKey] (G9 correction 1 : la note
  /// de la série qui l'a produit a changé, il est recalculé).
  SessionAdapt withoutLastAdvice(String exerciseKey) {
    final list = advice[exerciseKey];
    if (list == null || list.isEmpty) return this;
    final next = {
      for (final e in advice.entries) e.key: [...e.value],
    };
    final l = next[exerciseKey]!..removeLast();
    if (l.isEmpty) next.remove(exerciseKey);
    return copyWith(advice: next);
  }

  /// Change la suite du dernier conseil de [exerciseKey].
  SessionAdapt withLastAdviceStatus(String exerciseKey, String status) {
    final list = advice[exerciseKey];
    if (list == null || list.isEmpty) return this;
    final next = {
      for (final e in advice.entries) e.key: [...e.value],
    };
    final l = next[exerciseKey]!;
    l[l.length - 1] = l.last.withStatus(status);
    return copyWith(advice: next);
  }

  Map<String, Object?> toJson() => {
    'v': kSessionAdaptVersion,
    'blockId': blockId,
    'week': weekIndex,
    'day': dayIndex,
    'date': date,
    'mode': mode,
    if (asked) 'asked': true,
    if (check != null) 'check': check!.toJson(),
    if (place != null) 'place': place!.code,
    'plan': plan.toJson(),
    if (base != null) 'base': base!.toJson(),
    if (choice != null) 'choice': choice,
    if (advice.isNotEmpty)
      'advice': {
        for (final e in advice.entries)
          e.key: [for (final s in e.value) s.toJson()],
      },
  };

  /// Lecture ; [FormatException] hors contrat (toute autre erreur de
  /// lecture devient une [FormatException]).
  static SessionAdapt fromJson(Map<String, dynamic> m) {
    try {
      return _read(m);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Séance du moteur illisible.');
    }
  }

  static SessionAdapt _read(Map<String, dynamic> m) {
    final v = m['v'];
    if (v is! int || v < 1 || v > kSessionAdaptVersion) {
      throw const FormatException('Séance du moteur : version.');
    }
    String str(String k, int max) {
      final x = m[k];
      if (x is! String || x.isEmpty || x.length > max) {
        throw FormatException('Séance du moteur : $k.');
      }
      return x;
    }

    int nat(String k) {
      final x = m[k];
      if (x is! int || x < 0 || x > 10000) {
        throw FormatException('Séance du moteur : $k.');
      }
      return x;
    }

    final date = str('date', 10);
    kc.CivilDate.parse(date);
    final mode = str('mode', 10);
    if (mode != 'assisted' && mode != 'free') {
      throw const FormatException('Séance du moteur : mode.');
    }
    kc.SessionPlan plan(Object? raw) {
      if (raw is! Map) throw const FormatException('Séance du moteur : plan.');
      final p = kc.SessionPlan.fromJson(raw.cast<String, Object?>());
      if (p.validate().isNotEmpty) {
        throw const FormatException('Séance du moteur : plan hors contrat.');
      }
      return p;
    }

    kc.HealthCheck? check;
    final c = m['check'];
    if (c != null) {
      if (c is! Map) throw const FormatException('Séance du moteur : bilan.');
      check = kc.HealthCheck.fromJson(c.cast<String, Object?>());
      if (check.validate().isNotEmpty) {
        throw const FormatException('Séance du moteur : bilan hors contrat.');
      }
    }
    final p = m['place'];
    final choice = m['choice'];
    if (choice != null &&
        (choice is! String || !kAdaptChoices.contains(choice))) {
      throw const FormatException('Séance du moteur : suite.');
    }
    final advice = <String, List<AdviceStep>>{};
    final a = m['advice'];
    if (a != null) {
      if (a is! Map || a.length > 200) {
        throw const FormatException('Séance du moteur : conseils.');
      }
      for (final e in a.entries) {
        final list = e.value;
        if (e.key is! String || list is! List || list.length > 200) {
          throw const FormatException('Séance du moteur : conseils.');
        }
        advice[e.key as String] = [
          for (final x in list) AdviceStep.fromJson(x),
        ];
      }
    }
    return SessionAdapt(
      blockId: str('blockId', 200),
      weekIndex: nat('week'),
      dayIndex: nat('day'),
      date: date,
      mode: mode,
      asked: m['asked'] == true,
      check: check,
      place: p == null ? null : kc.Place.fromCode(p as String),
      plan: plan(m['plan']),
      base: m['base'] == null ? null : plan(m['base']),
      choice: choice as String?,
      advice: advice,
    );
  }
}

/// Cible d'une série : charge externe, plage de répétitions ou de secondes,
/// flammes visées.
class SetGoal {
  final double? kg;
  final int? low;
  final int? high;
  final int? flames;
  final bool seconds;
  const SetGoal({
    this.kg,
    this.low,
    this.high,
    this.flames,
    this.seconds = false,
  });

  /// Valeur pré-remplie de la colonne « valeur » (bas de la plage).
  int? get prefill => low ?? high;

  kc.SetTarget toTarget() => kc.SetTarget(
    repsLow: seconds ? null : low,
    repsHigh: seconds ? null : high,
    secondsLow: seconds ? low : null,
    secondsHigh: seconds ? high : null,
    loadKg: kg,
    flames: flames,
  );
}

/// L'exercice se mesure en secondes (tenue).
bool prescriptionInSeconds(kc.ExercisePrescription p) =>
    p.secondsLow != null || p.secondsHigh != null;

/// Cible de la série [index] d'une prescription, avant tout conseil.
SetGoal planGoal(kc.ExercisePrescription p, int index) {
  final seconds = prescriptionInSeconds(p);
  final targets = p.setTargets;
  if (targets != null && targets.isNotEmpty) {
    final t = targets[index < targets.length ? index : targets.length - 1];
    return SetGoal(
      kg: t.loadKg,
      low: seconds ? t.secondsLow : t.repsLow,
      high: seconds ? t.secondsHigh : t.repsHigh,
      flames: t.flames ?? p.targetFlames,
      seconds: seconds,
    );
  }
  return SetGoal(
    kg: p.startLoadKg,
    low: seconds ? p.secondsLow : p.repsLow,
    high: seconds ? p.secondsHigh : p.repsHigh,
    flames: p.kind == kc.SetKind.test ? kc.Flames.failure : p.targetFlames,
    seconds: seconds,
  );
}

/// Cible de la série [index] après les conseils actifs [steps] (le plus
/// récent qui la couvre l'emporte ; ses valeurs absentes restent celles
/// du plan).
SetGoal adviceGoal(
  kc.ExercisePrescription p,
  int index,
  List<AdviceStep> steps,
) {
  final g = planGoal(p, index);
  AdviceStep? last;
  for (final s in steps) {
    if (s.active && s.from <= index) last = s;
  }
  if (last == null) return g;
  return SetGoal(
    kg: last.kg ?? g.kg,
    low: last.low ?? g.low,
    high: last.high ?? last.low ?? g.high,
    flames: g.flames,
    seconds: g.seconds,
  );
}

/// Séries de travail prescrites d'une séance (`plannedWorkSets`).
int plannedWorkSetsOf(kc.SessionPlan plan) {
  var n = 0;
  for (final it in plan.items) {
    if (it.kind == kc.SetKind.warmup) continue;
    n += it.sets;
  }
  return n;
}
