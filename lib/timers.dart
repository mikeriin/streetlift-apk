import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'alerts.dart';
import 'store.dart';
import 'wod_formats.dart';

/// Horloge monotone du processus (µs) : ne recule jamais, ne suit pas les
/// changements d'heure ; sur Android elle s'arrête pendant la veille
/// profonde (CLOCK_MONOTONIC) et ne survit pas au processus.
final Stopwatch _processWatch = Stopwatch()..start();
int processMonotonicMicros() => _processWatch.elapsedMicroseconds;

/// Repère de mesure : heure murale et, si disponible, horloge monotone.
class TimeMark {
  final DateTime wall;
  final int? mono;
  const TimeMark(this.wall, this.mono);
}

/// Durées des chronos (L4b, KT-018). L'heure murale compte la veille de
/// l'appareil (écran verrouillé) ; l'horloge monotone du même processus la
/// borne par en dessous : un recul de l'heure système ne fait ni reculer ni
/// geler un chrono. Un saut en avant de l'heure ne se distingue pas d'une
/// veille : il est compté (limite documentée). Les repères ne sont jamais
/// persistés comme origine : après un nouveau processus, un redémarrage ou
/// un import, seule une durée déjà comptée est reprise.
class ElapsedClock {
  final DateTime Function() wall;
  final int Function()? mono;
  const ElapsedClock(this.wall, [this.mono]);

  /// Heure murale et horloge monotone réelles.
  static const system = ElapsedClock(DateTime.now, processMonotonicMicros);

  TimeMark mark() => TimeMark(wall(), mono?.call());

  /// Millisecondes écoulées depuis [m], jamais négatives.
  int msSince(TimeMark m) {
    final w = wall().difference(m.wall).inMilliseconds;
    final source = mono;
    final start = m.mono;
    if (source == null || start == null) return math.max(0, w);
    final monotonic = (source() - start) ~/ 1000;
    // Heure reculée (w < monotone) : la mesure monotone fait foi.
    return math.max(w, monotonic);
  }
}

/// Une alerte n'est jouée que si sa transition vient d'avoir lieu : pas de
/// rafale de bips anciens au retour dans l'application.
const staleAlertMs = 1500;

/// Chrono de séance : repos entre séries, tenues, EMOM / AMRAP / intervalles
/// d'une ligne de programme. Vit avec l'écran de séance : non restauré
/// après destruction du processus (décision du 26/09/2026), les séries et
/// saisies l'étant par le journal.
class TimerCtl extends ChangeNotifier {
  final ElapsedClock clock;
  TimerCtl({DateTime Function()? now, int Function()? mono})
    : clock = now == null && mono == null
          ? ElapsedClock.system
          : ElapsedClock(now ?? DateTime.now, mono);
  Timer? _t;
  bool running = false;
  bool up = false; // chronomètre (max temps)
  String label = 'REPOS';
  int total = 0;
  int remaining = 0;
  int elapsed = 0;
  List<(String, int)> _phases = [];
  int _pi = 0;

  /// Origine du déroulement et fin de la phase en cours (ms depuis
  /// l'origine) : les phases se déduisent du temps écoulé, jamais du
  /// nombre de rafraîchissements.
  TimeMark? _origin;
  int _endMs = 0;
  bool _preSignaled = false;

  /// Alertes jouées (tests) : transitions et fins récentes seulement.
  int alerts = 0;

  bool get visible => running || label == 'TERMINÉ';

  void startRest(int seconds) {
    if (seconds <= 0) {
      stop();
      return;
    }
    _phases = [];
    _beginPhase('REPOS', seconds);
  }

  void single(String lbl, int seconds, {bool prepare = true}) =>
      _startPhases([(lbl, seconds)], prepare: prepare);

  void emom(int rounds, int interval) => _startPhases([
    for (var i = 1; i <= rounds; i++) ('MINUTE $i/$rounds', interval),
  ]);

  void startInterval(int rounds, int work, int rest) => _startPhases([
    for (var i = 1; i <= rounds; i++) ...[
      ('EFFORT $i/$rounds', work),
      if (i < rounds) ('REPOS $i/$rounds', rest),
    ],
  ]);

  void stopwatch(String lbl) {
    _t?.cancel();
    _phases = [];
    up = true;
    label = lbl;
    total = 0;
    remaining = 0;
    elapsed = 0;
    _origin = clock.mark();
    running = true;
    notifyListeners();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _startPhases(List<(String, int)> phases, {bool prepare = true}) {
    phases = phases.where((p) => p.$2 > 0).toList();
    if (phases.isEmpty) {
      stop();
      return;
    }
    final prep = prepare ? store.settings.prepSec : 0;
    _phases = [if (prep > 0) ('PRÊT', prep), ...phases];
    _pi = 0;
    _beginPhase(_phases[0].$1, _phases[0].$2);
  }

  void _beginPhase(String lbl, int seconds) {
    _t?.cancel();
    up = false;
    label = lbl;
    total = seconds;
    remaining = seconds;
    _preSignaled = false;
    _origin = clock.mark();
    _endMs = seconds * 1000;
    running = true;
    notifyListeners();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!running) return;
    final ms = clock.msSince(_origin!);
    if (up) {
      elapsed = ms ~/ 1000;
      notifyListeners();
      return;
    }
    remaining = ((_endMs - ms) / 1000).ceil();
    if (remaining == 3 && !_preSignaled && total > 10) {
      _preSignaled = true;
      if (store.settings.vibration) HapticFeedback.lightImpact();
    }
    if (remaining <= 0) {
      // Retour tardif (veille, arrière-plan) : les phases sautées sont
      // rattrapées d'après le temps écoulé ; seule une transition récente
      // sonne, une seule fois.
      final late = ms - _endMs;
      if (late < staleAlertMs) {
        alerts++;
        alertBeep();
      }
      while (remaining <= 0) {
        if (_phases.isNotEmpty && _pi < _phases.length - 1) {
          _pi++;
          final p = _phases[_pi];
          label = p.$1;
          total = p.$2;
          _preSignaled = false;
          _endMs += p.$2 * 1000;
          remaining = ((_endMs - ms) / 1000).ceil();
        } else {
          _t?.cancel();
          running = false;
          remaining = 0;
          label = 'TERMINÉ';
          break;
        }
      }
    }
    notifyListeners();
  }

  void add(int s) {
    if (!running || up) return;
    final ms = clock.msSince(_origin!);
    _endMs = math.max(_endMs + s * 1000, ms + 1000);
    remaining = ((_endMs - ms) / 1000).ceil();
    total = math.max(total, remaining);
    notifyListeners();
  }

  /// Chrono montant : 1er appui = figer (lecture du temps), 2e = fermer.
  void stop() {
    if (up && running) {
      elapsed = clock.msSince(_origin!) ~/ 1000;
      _t?.cancel();
      running = false;
      label = 'TERMINÉ';
      notifyListeners();
      return;
    }
    _t?.cancel();
    running = false;
    up = false;
    remaining = 0;
    elapsed = 0;
    label = 'REPOS';
    notifyListeners();
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }
}

/// Horloge à précision milliseconde : les pauses ne perdent pas de fractions
/// de seconde, et un retour d'arrière-plan ne rejoue pas tous les bips ratés.
class WodClock extends ChangeNotifier {
  final ValueNotifier<bool> active = ValueNotifier(false);
  final ElapsedClock clock;
  WodClock({DateTime Function()? now, int Function()? mono})
    : clock = now == null && mono == null
          ? ElapsedClock.system
          : ElapsedClock(now ?? DateTime.now, mono);
  Timer? _t;
  bool running = false, started = false, finished = false, countdown = false;
  int elapsed = 0, remaining = 0, restLeft = 0, round = 0;
  int emomRound = 0, emomRounds = 0, emomInterval = 0, capSec = 0;
  bool capHit = false;
  final List<int> laps = [];
  TimeMark? _startAt;
  int _accMs = 0, _duration = 0;
  int? _restEndMs;

  /// Déroulement par phases (Tabata, AMRAP en blocs) : la phase en cours
  /// se déduit du temps actif cumulé. Un rafraîchissement tardif ne
  /// prolonge donc aucune phase et ne rejoue aucune transition.
  List<WodPhase> _phases = const [];
  List<int> _ends = const [];
  int phaseIndex = -1, phaseRemaining = 0, prepSeconds = 0;

  WodPhase? get phase => phaseIndex >= 0 && phaseIndex < _phases.length
      ? _phases[phaseIndex]
      : null;
  bool get phased => _phases.isNotEmpty;
  int get phaseCount => _phases.length;

  /// Temps écoulé hors préparation.
  int get workElapsed => math.max(0, elapsed - prepSeconds);

  /// Une alerte n'est jouée que si sa transition vient d'avoir lieu : pas
  /// de rafale de bips anciens au retour dans l'application.
  static const staleMs = staleAlertMs;

  /// Alertes déclenchées (bips de transition, alarmes de fin) : le son et
  /// la vibration suivent ensuite les réglages. Compteurs lus par les tests.
  int beeps = 0, alarms = 0;

  int get _activeMs => _accMs + (running ? clock.msSince(_startAt!) : 0);

  /// Temps actif compté, en millisecondes (pauses exclues).
  int get activeMs => _activeMs;

  void _run() {
    _startAt = clock.mark();
    running = true;
    started = true;
    active.value = true;
    _t?.cancel();
    _t = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
    notifyListeners();
  }

  void startStopwatch({int cap = 0}) {
    reset();
    capSec = math.max(0, cap);
    _run();
  }

  void startCountdown(int seconds) {
    if (seconds <= 0) return;
    reset();
    countdown = true;
    _duration = remaining = seconds;
    _run();
  }

  void startEmom(int rounds, int interval) {
    if (rounds <= 0 || interval <= 0) return;
    reset();
    countdown = true;
    emomRounds = rounds;
    emomInterval = interval;
    emomRound = 1;
    _duration = rounds * interval;
    remaining = interval;
    _run();
  }

  /// Démarre un déroulement par phases, précédé d'une préparation de
  /// [prep] secondes (réglage « Préparation »), hors durée du WOD.
  void startPhases(List<WodPhase> phases, {int prep = 0}) {
    final list = [
      if (prep > 0) WodPhase(PhaseKind.prep, prep),
      for (final p in phases)
        if (p.seconds > 0) p,
    ];
    if (list.isEmpty) return;
    reset();
    countdown = true;
    prepSeconds = math.max(0, prep);
    _phases = List.unmodifiable(list);
    var end = 0;
    _ends = List.unmodifiable([for (final p in list) end += p.seconds * 1000]);
    _duration = end ~/ 1000;
    remaining = _duration;
    phaseIndex = 0;
    phaseRemaining = list.first.seconds;
    _run();
  }

  void toggle() {
    if (!started || finished) return;
    if (running) {
      stop();
    } else {
      _run();
    }
  }

  void lap({int rest = 0}) {
    if (!running || restLeft > 0) return;
    _tick();
    if (!running) return;
    round++;
    laps.add(elapsed);
    if (rest > 0) {
      _restEndMs = _activeMs + rest * 1000;
      restLeft = rest;
    }
    notifyListeners();
  }

  void stop() {
    if (!running) return;
    _tick();
    if (running) _accMs = _activeMs;
    running = false;
    _t?.cancel();
    notifyListeners();
  }

  void reset() {
    _t?.cancel();
    running = started = finished = countdown = capHit = false;
    active.value = false;
    elapsed = remaining = restLeft = round = 0;
    emomRound = emomRounds = emomInterval = capSec = 0;
    _phases = const [];
    _ends = const [];
    phaseIndex = -1;
    phaseRemaining = prepSeconds = 0;
    _accMs = _duration = 0;
    _startAt = null;
    _restEndMs = null;
    laps.clear();
    notifyListeners();
  }

  void _tick() {
    if (!running) return;
    final ms = _activeMs;
    final old = (
      elapsed,
      remaining,
      restLeft,
      emomRound,
      capHit,
      phaseIndex,
      phaseRemaining,
    );
    elapsed = ms ~/ 1000;
    var beep = false;
    if (_restEndMs != null) {
      restLeft = math.max(0, ((_restEndMs! - ms) / 1000).ceil());
      if (restLeft == 0) {
        _restEndMs = null;
        beep = true;
      }
    }
    if (countdown) {
      if (ms >= _duration * 1000) {
        _accMs = _duration * 1000;
        elapsed = _duration;
        remaining = restLeft = 0;
        if (emomRounds > 0) emomRound = emomRounds;
        final late = ms - _duration * 1000;
        if (phased) {
          phaseIndex = _phases.length - 1;
          phaseRemaining = 0;
        }
        running = false;
        finished = true;
        _t?.cancel();
        if (!phased || late < staleMs) {
          alarms++;
          alertAlarm();
        }
        notifyListeners();
        return;
      }
      if (phased) {
        var i = 0;
        while (i < _ends.length - 1 && ms >= _ends[i]) {
          i++;
        }
        if (i != phaseIndex) {
          final start = i == 0 ? 0 : _ends[i - 1];
          beep = beep || ms - start < staleMs;
          phaseIndex = i;
        }
        phaseRemaining = ((_ends[i] - ms) / 1000).ceil();
        remaining = ((_duration * 1000 - ms) / 1000).ceil();
      } else if (emomRounds > 0) {
        final next = ms ~/ (emomInterval * 1000) + 1;
        beep = beep || next > emomRound;
        emomRound = next;
        remaining = ((next * emomInterval * 1000 - ms) / 1000).ceil();
      } else {
        remaining = ((_duration * 1000 - ms) / 1000).ceil();
      }
    } else if (capSec > 0 && !capHit && elapsed >= capSec) {
      capHit = true;
      alarms++;
      alertAlarm();
      beep = false;
    }
    if (beep) {
      beeps++;
      alertBeep();
    }
    if (old !=
        (
          elapsed,
          remaining,
          restLeft,
          emomRound,
          capHit,
          phaseIndex,
          phaseRemaining,
        )) {
      notifyListeners();
    }
  }

  // ---------- Reprise après interruption (KT-018) ----------
  /// Point sûr : temps actif compté et état des rounds, sans aucun repère
  /// d'horloge (inutilisable dans un autre processus ou après redémarrage).
  Map<String, dynamic> checkpoint() => {
    'ms': _activeMs,
    'laps': List<int>.of(laps),
    'round': round,
    if (_restEndMs != null) 'restEndMs': _restEndMs,
    'capHit': capHit,
    'finished': finished,
  };

  /// Après un démarrage configuré sur la même prescription (`start…`),
  /// remet le chrono **en pause** au temps d'un point sûr : le temps passé
  /// hors de l'application n'est pas compté, aucune alerte n'est rejouée.
  void resumePaused({
    required int ms,
    List<int> laps = const [],
    int round = 0,
    int? restEndMs,
    bool capHit = false,
  }) {
    _t?.cancel();
    running = false;
    final limit = countdown ? _duration * 1000 : 86400 * 1000;
    _accMs = ms.clamp(0, limit);
    this.laps
      ..clear()
      ..addAll(laps);
    this.round = round;
    _restEndMs = restEndMs != null && restEndMs > _accMs ? restEndMs : null;
    this.capHit = capHit || (capSec > 0 && _accMs >= capSec * 1000);
    _recompute(_accMs);
    if (countdown && _accMs >= _duration * 1000) finished = true;
    active.value = true;
    notifyListeners();
  }

  /// Affichage déduit du temps actif, sans alerte.
  void _recompute(int ms) {
    elapsed = ms ~/ 1000;
    restLeft = _restEndMs == null
        ? 0
        : math.max(0, ((_restEndMs! - ms) / 1000).ceil());
    if (!countdown) return;
    if (phased) {
      var i = 0;
      while (i < _ends.length - 1 && ms >= _ends[i]) {
        i++;
      }
      phaseIndex = i;
      phaseRemaining = math.max(0, ((_ends[i] - ms) / 1000).ceil());
      remaining = math.max(0, ((_duration * 1000 - ms) / 1000).ceil());
    } else if (emomRounds > 0) {
      final next = math.min(emomRounds, ms ~/ (emomInterval * 1000) + 1);
      emomRound = next;
      remaining = math.max(
        0,
        ((next * emomInterval * 1000 - ms) / 1000).ceil(),
      );
    } else {
      remaining = math.max(0, ((_duration * 1000 - ms) / 1000).ceil());
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    active.dispose();
    super.dispose();
  }
}
