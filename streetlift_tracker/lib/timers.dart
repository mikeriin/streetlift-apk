import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'alerts.dart';
import 'store.dart';

class TimerCtl extends ChangeNotifier {
  final DateTime Function() now;
  TimerCtl({DateTime Function()? now}) : now = now ?? DateTime.now;
  Timer? _t;
  bool running = false;
  bool up = false; // chronomètre (max temps)
  String label = 'REPOS';
  int total = 0;
  int remaining = 0;
  int elapsed = 0;
  List<(String, int)> _phases = [];
  int _pi = 0;
  DateTime? _deadline;
  DateTime? _startAt;
  bool _preSignaled = false;

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
    _startAt = now();
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
    _deadline = now().add(Duration(seconds: seconds));
    running = true;
    notifyListeners();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!running) return;
    if (up) {
      elapsed = now().difference(_startAt!).inSeconds;
      notifyListeners();
      return;
    }
    remaining = (_deadline!.difference(now()).inMilliseconds / 1000).ceil();
    if (remaining == 3 && !_preSignaled && total > 10) {
      _preSignaled = true;
      if (store.settings.vibration) HapticFeedback.lightImpact();
    }
    var alerted = false;
    while (remaining <= 0) {
      if (!alerted) {
        alertBeep();
        alerted = true;
      }
      if (_phases.isNotEmpty && _pi < _phases.length - 1) {
        _pi++;
        final p = _phases[_pi];
        label = p.$1;
        total = p.$2;
        _preSignaled = false;
        _deadline = _deadline!.add(Duration(seconds: p.$2));
        remaining = (_deadline!.difference(now()).inMilliseconds / 1000).ceil();
      } else {
        _t?.cancel();
        running = false;
        remaining = 0;
        label = 'TERMINÉ';
        break;
      }
    }
    notifyListeners();
  }

  void add(int s) {
    if (!running || up) return;
    final current = now();
    var d = _deadline!.add(Duration(seconds: s));
    if (d.isBefore(current.add(const Duration(seconds: 1)))) {
      d = current.add(const Duration(seconds: 1));
    }
    _deadline = d;
    remaining = (d.difference(current).inMilliseconds / 1000).ceil();
    total = math.max(total, remaining);
    notifyListeners();
  }

  /// Chrono montant : 1er appui = figer (lecture du temps), 2e = fermer.
  void stop() {
    if (up && running) {
      elapsed = now().difference(_startAt!).inSeconds;
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
  final DateTime Function() now;
  WodClock({DateTime Function()? now}) : now = now ?? DateTime.now;
  Timer? _t;
  bool running = false, started = false, finished = false, countdown = false;
  int elapsed = 0, remaining = 0, restLeft = 0, round = 0;
  int emomRound = 0, emomRounds = 0, emomInterval = 0, capSec = 0;
  bool capHit = false;
  final List<int> laps = [];
  DateTime? _startAt;
  int _accMs = 0, _duration = 0;
  int? _restEndMs;

  int get _activeMs =>
      _accMs +
      (running ? math.max(0, now().difference(_startAt!).inMilliseconds) : 0);

  void _run() {
    _startAt = now();
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
    _accMs = _duration = 0;
    _startAt = null;
    _restEndMs = null;
    laps.clear();
    notifyListeners();
  }

  void _tick() {
    if (!running) return;
    final ms = _activeMs;
    final old = (elapsed, remaining, restLeft, emomRound, capHit);
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
        running = false;
        finished = true;
        _t?.cancel();
        alertAlarm();
        notifyListeners();
        return;
      }
      if (emomRounds > 0) {
        final next = ms ~/ (emomInterval * 1000) + 1;
        beep = beep || next > emomRound;
        emomRound = next;
        remaining = ((next * emomInterval * 1000 - ms) / 1000).ceil();
      } else {
        remaining = ((_duration * 1000 - ms) / 1000).ceil();
      }
    } else if (capSec > 0 && !capHit && elapsed >= capSec) {
      capHit = true;
      alertAlarm();
      beep = false;
    }
    if (beep) alertBeep();
    if (old != (elapsed, remaining, restLeft, emomRound, capHit)) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    active.dispose();
    super.dispose();
  }
}
