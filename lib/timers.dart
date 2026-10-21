import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'alerts.dart';
import 'store.dart';

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
          : ElapsedClock(now ?? DateTime.now, mono),
      _isSide = false;

  /// RV1c1 : chrono secondaire (tenue, mini-repos, durée) lancé pendant le
  /// chrono d'un groupe : même horloge, sans chrono secondaire à son tour.
  TimerCtl._side(this.clock) : _isSide = true;
  final bool _isSide;
  TimerCtl? _side;
  Timer? _t;
  bool running = false;

  /// RV1c1 (C17.45) : le chrono en cours est celui d'un groupe au chrono
  /// (EMOM, E2MOM, E3MOM, E90s, intervalles, AMRAP, pour le temps) : tant
  /// qu'il tourne, aucun autre chrono ne le remplace (repos, tenue,
  /// mini-repos) ; seul l'athlète l'arrête ou relance un groupe.
  bool groupClock = false;
  bool get groupRunning => running && groupClock;

  /// RV1c1 : chrono secondaire, affiché au-dessus de la barre du groupe.
  TimerCtl get side {
    assert(!_isSide, 'pas de chrono secondaire d’un chrono secondaire');
    return _side ??= TimerCtl._side(clock);
  }

  /// Barre du bas affichée : chrono principal ou secondaire.
  bool get shown => visible || (_side?.visible ?? false);
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
    // RV1c1 : le repos ne remplace jamais le chrono d'un groupe.
    if (groupRunning) return;
    if (seconds <= 0) {
      stop();
      return;
    }
    _phases = [];
    groupClock = false;
    _beginPhase('REPOS', seconds);
  }

  /// Décompte lancé par un bouton « Lancer » ([group] : chrono d'un groupe,
  /// AMRAP).
  void single(
    String lbl,
    int seconds, {
    bool prepare = true,
    bool group = false,
  }) => _startPhases([(lbl, seconds)], prepare: prepare, group: group);

  /// RV1c1 : chrono d'une ligne (tenue, durée, mini-repos) : le chrono
  /// principal comme avant, ou, pendant le chrono d'un groupe, le chrono
  /// secondaire (sans préparation : l'athlète est déjà dans le tour). Un
  /// second appui sur le même chrono secondaire en cours l'arrête.
  void solo(String lbl, int seconds, {bool prepare = true}) {
    if (!groupRunning) {
      single(lbl, seconds, prepare: prepare);
      return;
    }
    final s = side;
    if (s.running && !s.up && s.label == lbl) {
      s.stop();
      return;
    }
    s.single(lbl, seconds, prepare: false);
  }

  /// RV1c1 : chrono montant d'une ligne (tenue au maximum) : principal, ou
  /// secondaire pendant le chrono d'un groupe.
  void soloStopwatch(String lbl) {
    if (!groupRunning) {
      stopwatch(lbl);
      return;
    }
    final s = side;
    if (s.running && s.up) {
      s.stop();
      return;
    }
    s.stopwatch(lbl);
  }

  /// PR1 : départ toutes les [interval] s (EMOM, E2MOM, E90s).
  void emom(int rounds, int interval) {
    final unit = interval == 60 ? 'MINUTE' : 'TOUR';
    _startPhases([
      for (var i = 1; i <= rounds; i++) ('$unit $i/$rounds', interval),
    ], group: true);
  }

  void startInterval(int rounds, int work, int rest) => _startPhases([
    for (var i = 1; i <= rounds; i++) ...[
      ('EFFORT $i/$rounds', work),
      if (i < rounds) ('REPOS $i/$rounds', rest),
    ],
  ], group: true);

  void stopwatch(String lbl, {bool group = false}) {
    _t?.cancel();
    _phases = [];
    groupClock = group && !_isSide;
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

  void _startPhases(
    List<(String, int)> phases, {
    bool prepare = true,
    bool group = false,
  }) {
    phases = phases.where((p) => p.$2 > 0).toList();
    if (phases.isEmpty) {
      stop();
      return;
    }
    final prep = prepare ? store.settings.prepSec : 0;
    _phases = [if (prep > 0) ('PRÊT', prep), ...phases];
    _pi = 0;
    groupClock = group && !_isSide;
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
    // RV1c1 : le chrono d'un groupe ne se décale pas (−15 s / +15 s).
    if (!running || up || groupClock) return;
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
    groupClock = false;
    remaining = 0;
    elapsed = 0;
    label = 'REPOS';
    notifyListeners();
  }

  @override
  void dispose() {
    _t?.cancel();
    _side?.dispose();
    super.dispose();
  }
}
