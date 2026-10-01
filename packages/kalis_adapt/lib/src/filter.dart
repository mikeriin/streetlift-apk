/// Filtre de Kalman d'un exercice : capacité, pente, forme de la courbe,
/// effet de jour. Équations et justifications : `CONTRAT.md`, § Modèle.
library;

import 'numeric.dart';
import 'params.dart';

/// Ce que mesure la capacité d'un exercice.
enum CapacityMode {
  /// Exercice chargé : la capacité est une charge (1RM de charge totale),
  /// reliée aux répétitions par la courbe répétitions ↔ charge.
  loaded,

  /// Exercice au poids du corps compté en répétitions : la capacité est le
  /// nombre maximal de répétitions.
  reps,

  /// Tenue : la capacité est la durée maximale, en secondes.
  hold,
}

/// Point de l'historique d'un filtre (après une séance).
final class TrackPoint {
  /// Niveau [level] (`ln`) d'écart-type [sd] au jour [day].
  const TrackPoint(this.day, this.level, this.sd);

  /// Numéro de jour civil.
  final int day;

  /// `ln` de la capacité (1RM de charge totale, ou maximum de répétitions
  /// ou de secondes) : indépendant du pivot de la courbe.
  final double level;

  /// Écart-type du niveau.
  final double sd;
}

/// Filtre d'un exercice. État `[c, v, κ, d]` :
///
/// - `c` : `ln` de la capacité opérationnelle — pour un exercice chargé, la
///   charge soulevable [nRef] fois ; sinon le maximum de répétitions ou de
///   secondes ;
/// - `v` : pente de `c` par semaine (tendance locale amortie) ;
/// - `κ` : `ln k`, forme de la courbe répétitions ↔ charge (exercices
///   chargés) ;
/// - `d` : effet de jour, remis à zéro à chaque séance.
///
/// Le 1RM d'un exercice chargé s'en déduit :
/// `ln 1RM = c + ln(1 + (nRef − 1) / k)`.
final class CapacityFilter {
  /// Filtre de mode [mode], d'a priori `c ~ N(c, cSd²)`, `v ~ N(v, vSd²)`,
  /// `ln k ~ N(ln k, kLogSd²)`, pivot [nRef], au jour [day].
  CapacityFilter({
    required this.mode,
    required double c,
    required double cSd,
    required double v,
    required double vSd,
    required double k,
    required double kLogSd,
    required this.nRef,
    required this.day,
  }) : m = <double>[c, v, ln(k), 0],
       cov = List<double>.filled(16, 0) {
    cov[0] = cSd * cSd;
    cov[5] = vSd * vSd;
    cov[10] = kLogSd * kLogSd;
  }

  CapacityFilter._copy(CapacityFilter o)
    : mode = o.mode,
      m = List<double>.of(o.m),
      cov = List<double>.of(o.cov),
      nRef = o.nRef,
      day = o.day {
    sessions = o.sessions;
    sets = o.sets;
    inSession = o.inSession;
    setFatigue = List<double>.of(o.setFatigue);
    history = List<TrackPoint>.of(o.history);
  }

  /// A priori exprimé sur le 1RM (niveau déclaré) : `c = x − g(nRef, k)` ;
  /// l'incertitude sur `k` se reporte sur `c` et les corrèle.
  factory CapacityFilter.fromOneRm({
    required double logOneRm,
    required double sd,
    required double v,
    required double vSd,
    required double k,
    required double kLogSd,
    required double nRef,
    required int day,
  }) {
    final u = (nRef - 1) / k;
    final a = u / (1 + u);
    final f = CapacityFilter(
      mode: CapacityMode.loaded,
      c: logOneRm - ln(1 + u),
      cSd: sqrt(sd * sd + a * a * kLogSd * kLogSd),
      v: v,
      vSd: vSd,
      k: k,
      kLogSd: kLogSd,
      nRef: nRef,
      day: day,
    );
    f.cov[2] = a * kLogSd * kLogSd;
    f.cov[8] = f.cov[2];
    return f;
  }

  /// Copie indépendante.
  CapacityFilter fork() => CapacityFilter._copy(this);

  /// Mode de capacité.
  final CapacityMode mode;

  /// Moyenne de l'état `[c, v, κ, d]`.
  final List<double> m;

  /// Covariance de l'état, 4 × 4, ligne par ligne.
  final List<double> cov;

  /// Répétitions jusqu'à l'échec du pivot de la courbe (exercices chargés).
  double nRef;

  /// Jour de la dernière prédiction.
  int day;

  /// Séances observées.
  int sessions = 0;

  /// Séries observées.
  int sets = 0;

  /// Vrai entre [beginSession] et [endSession].
  bool inSession = false;

  /// Pertes relatives de répétitions laissées par les séries de la séance.
  List<double> setFatigue = <double>[];

  /// Niveau après chaque séance.
  List<TrackPoint> history = <TrackPoint>[];

  // ------------------------------------------------------------------ temps

  /// Avance l'état jusqu'au jour [toDay] : tendance amortie, bruit de
  /// processus proportionnel au temps écoulé.
  void predict(int toDay, AdaptParams p) {
    final dt = (toDay - day) / 7;
    if (dt <= 0) {
      return;
    }
    final lnPhi = ln(p.trendDamping);
    final phi = exp(dt * lnPhi);
    final g = (1 - phi) / (-lnPhi);
    // F = [[1, g, 0, 0], [0, phi, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]].
    m[0] += g * m[1];
    m[1] *= phi;
    final f = <double>[1, g, 0, 0, 0, phi, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
    final fc = _mul(f, cov);
    final out = _mulT(fc, f);
    for (var i = 0; i < 16; i++) {
      cov[i] = out[i];
    }
    final ql = p.levelNoise * p.levelNoise;
    final qt = p.trendNoise * p.trendNoise;
    cov[0] += ql * dt + qt * dt * dt * dt / 3;
    cov[1] += qt * dt * dt / 2;
    cov[4] += qt * dt * dt / 2;
    cov[5] += qt * dt;
    day = toDay;
  }

  /// Décale le niveau de [delta] (transfert d'un exercice proche,
  /// désentraînement) en ajoutant la variance [variance].
  void shiftLevel(double delta, double variance) {
    m[0] += delta;
    cov[0] += variance;
  }

  /// Déplace le pivot de la courbe à [n] répétitions jusqu'à l'échec
  /// (exercices chargés, hors séance). Le 1RM et l'incertitude de toute
  /// charge prévue sont conservés : `c' = c + g(nRef, k) − g(n, k)`, avec
  /// `g(n, k) = ln(1 + (n − 1) / k)` ; la covariance suit par la
  /// transformation linéaire `c' = c + t·κ`,
  /// `t = u'/(1 + u') − u/(1 + u)`.
  void repivot(double n) {
    if (mode != CapacityMode.loaded || inSession) {
      return;
    }
    final to = n < 1 ? 1.0 : n;
    if ((to - nRef).abs() < 1e-9) {
      return;
    }
    final kk = k;
    final u0 = (nRef - 1) / kk;
    final u1 = (to - 1) / kk;
    final t = u1 / (1 + u1) - u0 / (1 + u0);
    m[0] += ln(1 + u0) - ln(1 + u1);
    for (var j = 0; j < 4; j++) {
      cov[j] += t * cov[8 + j];
    }
    for (var i = 0; i < 4; i++) {
      cov[4 * i] += t * cov[4 * i + 2];
    }
    nRef = to;
    _symmetrize();
  }

  /// Ouvre une séance au jour [toDay] : l'effet de jour repart de
  /// `N(shift, daySd²)`, sans corrélation avec le reste.
  void beginSession(int toDay, double shift, double daySd, AdaptParams p) {
    predict(toDay, p);
    for (var i = 0; i < 4; i++) {
      cov[12 + i] = 0;
      cov[4 * i + 3] = 0;
    }
    cov[15] = daySd * daySd;
    m[3] = shift;
    inSession = true;
    setFatigue = <double>[];
  }

  /// Ferme la séance : l'effet de jour est oublié.
  void endSession() {
    if (!inSession) {
      return;
    }
    inSession = false;
    sessions++;
    for (var i = 0; i < 4; i++) {
      cov[12 + i] = 0;
      cov[4 * i + 3] = 0;
    }
    m[3] = 0;
    history.add(TrackPoint(day, m[0] + gRef, sqrt(cov[0] < 0 ? 0.0 : cov[0])));
  }

  // --------------------------------------------------- fatigue intra-séance

  /// Perte relative de capacité de la série à venir (séries déjà faites).
  double fatigueNow(AdaptParams p) {
    var total = 0.0;
    final n = setFatigue.length;
    for (var i = 0; i < n; i++) {
      total += setFatigue[i] * _recovery(n - 1 - i, p);
    }
    return total > 0.8 ? 0.8 : total;
  }

  /// Note la fatigue laissée par une série finie à [rir] répétitions de
  /// l'échec, suivie de [restSeconds] de repos.
  void noteSetFatigue(double rir, int restSeconds, AdaptParams p) {
    setFatigue.add(setFatigueOf(rir, restSeconds, p));
  }

  // ----------------------------------------------------------------- courbe

  /// Paramètre `k` de la courbe.
  double get k => exp(m[2]);

  /// `ln(1 + (nRef − 1) / k)` : écart entre la capacité opérationnelle et
  /// le 1RM.
  double get gRef => mode == CapacityMode.loaded ? ln(1 + (nRef - 1) / k) : 0;

  /// Répétitions possibles, frais, à la charge de logarithme [logLoad],
  /// pour une capacité du jour décalée de [shift] (exercices chargés).
  double repsPossible(double logLoad, {double shift = 0}) {
    return 1 + k * (exp(m[0] + m[3] + shift + gRef - logLoad) - 1);
  }

  /// `ln` de la charge soulevable [n] fois aujourd'hui, capacité décalée
  /// de [shift] (exercices chargés).
  double logLoadFor(double n, {double shift = 0}) {
    final r = n < 1 ? 1.0 : n;
    return m[0] + m[3] + shift + gRef - ln(1 + (r - 1) / k);
  }

  /// Capacité du jour (répétitions ou secondes maximales), décalée de
  /// [shift] (modes [CapacityMode.reps] et [CapacityMode.hold]).
  double capacityToday({double shift = 0}) => exp(m[0] + m[3] + shift);

  // ------------------------------------------------------------ observation

  /// Série d'un exercice chargé : charge de logarithme [logLoad], [n]
  /// répétitions jusqu'à l'échec estimées avec l'écart-type [nSd], après la
  /// perte relative [fatigue].
  ///
  /// [bound] : la série dit seulement « au moins [n] » — ou, avec [upper],
  /// « au plus [n] » (une série ratée sans une seule répétition). [learnK] : la série
  /// met à jour `k` (elle est fraîche et [n] est connu précisément) ;
  /// sinon `k` est tenu pour fixe : il ne bouge pas, et son incertitude
  /// s'ajoute au bruit de la série. [clip] : au-delà de ce nombre
  /// d'écarts-types de l'innovation, la série est tenue pour douteuse —
  /// son bruit est gonflé pour ramener l'écart au seuil et elle n'apprend
  /// pas `k`.
  void observeLoad({
    required double logLoad,
    required double n,
    required double nSd,
    required double fatigue,
    required AdaptParams p,
    bool bound = false,
    bool upper = false,
    bool learnK = false,
    double? clip,
  }) {
    final kk = k;
    final scale = 1 / (1 - fatigue < 1e-6 ? 1e-6 : 1 - fatigue);
    final nEff = (n < 1 ? 1.0 : n) * scale;
    final u = (nEff - 1) / kk;
    final ur = (nRef - 1) / kk;
    final h = m[0] + m[3] - ln(1 + u) + ln(1 + ur);
    final hk = u / (1 + u) - ur / (1 + ur);
    final slope = scale / (kk * (1 + u));
    var r = sq(nSd * slope) + sq(p.observationFloor);
    final jac = <double>[1, 0, hk, 1];
    var learn = learnK;
    if (clip != null) {
      final nu = logLoad - h;
      final contradicts = bound ? (upper ? nu < 0 : nu > 0) : true;
      if (contradicts && nu * nu > clip * clip * _innovationVar(jac, r, learn)) {
        learn = false;
        final inflated =
            r + nu * nu / (clip * clip) - _innovationVar(jac, r, false);
        if (inflated > r) {
          r = inflated;
        }
      }
    }
    if (bound && upper) {
      // « Au plus [n] » : la même contrainte, de l'autre côté.
      _lowerBound(<double>[-1, 0, -hk, -1], logLoad - h, r, learn);
    } else if (bound) {
      _lowerBound(jac, h - logLoad, r, learn);
    } else {
      _update(jac, logLoad - h, r, learn);
    }
    m[2] = clampDouble(m[2], ln(p.kMin), ln(p.kMax));
    sets++;
  }

  /// Capacité observée directement (modes [CapacityMode.reps] et
  /// [CapacityMode.hold]) : [logCapacity] est le `ln` de la capacité
  /// fraîche impliquée par la série, d'écart-type relatif [sd] ; [clip]
  /// comme pour [observeLoad].
  void observeDirect({
    required double logCapacity,
    required double sd,
    required AdaptParams p,
    bool bound = false,
    double? clip,
  }) {
    final h = m[0] + m[3];
    var r = sq(sd) + sq(p.observationFloor);
    const jac = <double>[1, 0, 0, 1];
    if (clip != null) {
      final nu = logCapacity - h;
      final s = _innovationVar(jac, r, false);
      if ((!bound || nu > 0) && nu * nu > clip * clip * s) {
        r += nu * nu / (clip * clip) - s;
      }
    }
    if (bound) {
      _lowerBound(jac, h - logCapacity, r, false);
    } else {
      _update(jac, logCapacity - h, r, false);
    }
    sets++;
  }

  /// Variance de l'innovation d'une observation de jacobien [jac] et de
  /// bruit [r].
  double _innovationVar(List<double> jac, double r, bool learnK) {
    final (h, noise) = _effective(jac, r, learnK);
    var s = noise;
    for (var i = 0; i < 4; i++) {
      for (var j = 0; j < 4; j++) {
        s += h[i] * cov[4 * i + j] * h[j];
      }
    }
    return s;
  }

  List<double> _gain(List<double> jac, double r, bool learnK) {
    final ch = List<double>.filled(4, 0);
    for (var i = 0; i < 4; i++) {
      var sum = 0.0;
      for (var j = 0; j < 4; j++) {
        sum += cov[4 * i + j] * jac[j];
      }
      ch[i] = sum;
    }
    var s = r;
    for (var i = 0; i < 4; i++) {
      s += jac[i] * ch[i];
    }
    final gain = <double>[ch[0] / s, ch[1] / s, ch[2] / s, ch[3] / s, s];
    if (!learnK) {
      gain[2] = 0;
    }
    return gain;
  }

  /// Forme de Joseph, valable pour tout gain :
  /// `C ← (I − KH) C (I − KH)ᵀ + K R Kᵀ`.
  void _joseph(List<double> gain, List<double> jac, double r) {
    final a = List<double>.filled(16, 0);
    for (var i = 0; i < 4; i++) {
      for (var j = 0; j < 4; j++) {
        a[4 * i + j] = (i == j ? 1.0 : 0.0) - gain[i] * jac[j];
      }
    }
    final ac = _mul(a, cov);
    final out = _mulT(ac, a);
    for (var i = 0; i < 4; i++) {
      for (var j = 0; j < 4; j++) {
        cov[4 * i + j] = out[4 * i + j] + gain[i] * r * gain[j];
      }
    }
    _symmetrize();
  }

  /// Jacobien et bruit effectifs d'une observation. Quand elle n'apprend
  /// pas `k`, `k` est tenu pour fixe : sa composante quitte le jacobien et
  /// son incertitude s'ajoute au bruit (`hk² · Var(κ)`). Le niveau ne peut
  /// alors bouger que dans le sens de l'innovation — avec un gain calculé
  /// sur la covariance complète, une corrélation entre `c` et `κ` pouvait
  /// l'envoyer à l'opposé de ce que la série montrait.
  (List<double>, double) _effective(List<double> jac, double r, bool learnK) {
    if (learnK) {
      return (jac, r);
    }
    return (<double>[jac[0], jac[1], 0, jac[3]], r + jac[2] * jac[2] * cov[10]);
  }

  void _update(List<double> jac, double innovation, double r, bool learnK) {
    final (h, noise) = _effective(jac, r, learnK);
    final gain = _gain(h, noise, learnK);
    for (var i = 0; i < 4; i++) {
      m[i] += gain[i] * innovation;
    }
    _joseph(gain, h, noise);
  }

  /// Contrainte `H·m + ε ≥ y`, `ε ~ N(0, R)` ; [margin] = `H·m − y`.
  /// Moments de la loi normale tronquée (Tallis 1961) : la moyenne se
  /// déplace de `K·√S·λ`, la covariance fait la part `λ(a + λ)` d'une mise
  /// à jour complète.
  void _lowerBound(List<double> jac, double margin, double r, bool learnK) {
    final (h, noise) = _effective(jac, r, learnK);
    final gain = _gain(h, noise, learnK);
    final s = sqrt(gain[4]);
    final a = margin / s;
    final cdf = normCdf(a);
    final lambda = cdf < 1e-300 ? -a : normPdf(a) / cdf;
    for (var i = 0; i < 4; i++) {
      m[i] += gain[i] * s * lambda;
    }
    final w = clampDouble(lambda * (a + lambda), 0, 1);
    if (w > 0) {
      final old = List<double>.of(cov);
      _joseph(gain, h, noise);
      for (var i = 0; i < 16; i++) {
        cov[i] = (1 - w) * old[i] + w * cov[i];
      }
      _symmetrize();
    }
  }

  void _symmetrize() {
    for (var i = 0; i < 4; i++) {
      for (var j = i + 1; j < 4; j++) {
        final v = 0.5 * (cov[4 * i + j] + cov[4 * j + i]);
        cov[4 * i + j] = v;
        cov[4 * j + i] = v;
      }
      if (cov[5 * i] < 1e-12) {
        cov[5 * i] = 1e-12;
      }
    }
  }

  // ---------------------------------------------------------------- lecture

  /// Écart-type du `ln` de la charge soulevable [n] fois (niveau, `k` et,
  /// si [withDay], effet de jour). Pour les modes sans courbe, [n] est
  /// ignoré.
  double loadSd(double n, {bool withDay = true}) {
    var hk = 0.0;
    if (mode == CapacityMode.loaded) {
      final kk = k;
      final u = ((n < 1 ? 1.0 : n) - 1) / kk;
      final ur = (nRef - 1) / kk;
      hk = u / (1 + u) - ur / (1 + ur);
    }
    final jac = <double>[1, 0, hk, withDay ? 1.0 : 0.0];
    var variance = 0.0;
    for (var i = 0; i < 4; i++) {
      for (var j = 0; j < 4; j++) {
        variance += jac[i] * cov[4 * i + j] * jac[j];
      }
    }
    return sqrt(variance < 0 ? 0.0 : variance);
  }

  /// Capacité hors effet de jour : 1RM de charge totale (mode chargé),
  /// répétitions ou secondes maximales.
  double get capacity => exp(m[0] + gRef);

  /// Écart-type relatif de [capacity].
  double get capacityRelSd => loadSd(1, withDay: false);

  /// Pente de la capacité, en part par semaine.
  double get trend => m[1];

  /// Écart-type de la pente.
  double get trendSd => sqrt(cov[5] < 0 ? 0.0 : cov[5]);

  /// État sérialisable (inspecteur, export du mode dev).
  Map<String, Object?> toJson() => <String, Object?>{
    'mode': mode.name,
    'mean': <Object?>[for (final x in m) roundTo(x, 6)],
    'sd': <Object?>[
      for (var i = 0; i < 4; i++)
        roundTo(sqrt(cov[5 * i] < 0 ? 0.0 : cov[5 * i]), 6),
    ],
    'nRef': roundTo(nRef, 3),
    'day': day,
    'sessions': sessions,
    'sets': sets,
  };

  static double _recovery(int age, AdaptParams p) {
    // p.setFatigueRecovery ^ (age / 2)
    return exp(age / 2 * ln(p.setFatigueRecovery));
  }
}

/// Perte relative de capacité laissée par une série finie à [rir]
/// répétitions de l'échec, après [restSeconds] de repos.
double setFatigueOf(double rir, int restSeconds, AdaptParams p) {
  final rest = restSeconds < 30 ? 30.0 : restSeconds.toDouble();
  final base = p.setFatigueAtFailure * exp(-rest / p.setFatigueRestTau);
  return base * exp(-(rir < 0 ? 0.0 : rir) / p.setFatigueRirScale);
}

/// Fatigue prévue avant la série de rang [setIndex] quand les précédentes
/// finissent à [rir] répétitions de l'échec avec [restSeconds] de repos.
double plannedFatigue(
  int setIndex,
  double rir,
  int restSeconds,
  AdaptParams p,
) {
  final f = setFatigueOf(rir, restSeconds, p);
  var total = 0.0;
  for (var i = 0; i < setIndex; i++) {
    total += f * exp((setIndex - 1 - i) / 2 * ln(p.setFatigueRecovery));
  }
  return total > 0.8 ? 0.8 : total;
}

List<double> _mul(List<double> a, List<double> b) {
  final out = List<double>.filled(16, 0);
  for (var i = 0; i < 4; i++) {
    for (var j = 0; j < 4; j++) {
      var sum = 0.0;
      for (var k = 0; k < 4; k++) {
        sum += a[4 * i + k] * b[4 * k + j];
      }
      out[4 * i + j] = sum;
    }
  }
  return out;
}

/// `a × bᵀ`.
List<double> _mulT(List<double> a, List<double> b) {
  final out = List<double>.filled(16, 0);
  for (var i = 0; i < 4; i++) {
    for (var j = 0; j < 4; j++) {
      var sum = 0.0;
      for (var k = 0; k < 4; k++) {
        sum += a[4 * i + k] * b[4 * j + k];
      }
      out[4 * i + j] = sum;
    }
  }
  return out;
}
