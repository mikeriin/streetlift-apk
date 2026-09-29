// M7 (mannequin 3D) : lecteur d'animation du mannequin.
//
// Sous le mannequin animé : lecture / pause, curseur de temps (glisser =
// parcourir le mouvement), nom et tempo de la phase en cours (« Descente ·
// 3 s »), temps, et les boutons de vue du mannequin. Le halo de la zone
// travaillée suit la phase (`phaseHaloGain` : plus vif en concentrique,
// plus doux en excentrique, pulsation lente en isométrie).
//
// Animations réduites (réglage Android) : aucune lecture ; le curseur ne
// s'arrête que sur les images clés de début et de fin de chaque phase,
// sans pulsation. Économie : lecture en pause hors écran, en arrière-plan
// et après 60 s sans interaction ; ticker muet quand la page est cachée.
//
// Sans animation pour un exercice, rien de tout cela n'est affiché : la
// fiche garde son mannequin fixe (`ExerciseMannequin`). Sans Flutter GPU, le
// repli 2D s'affiche seul, sans lecteur vide.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'app_theme.dart';
import 'mannequin_3d.dart';
import 'mannequin_clip.dart';

/// Pause automatique après ce délai sans interaction.
const kPlayerIdlePause = Duration(seconds: 60);

/// Raisons d'une pause automatique (affichées sous le lecteur).
enum PlayerPause {
  offscreen('hors de l’écran'),
  background('application en arrière-plan'),
  idle('60 s sans interaction');

  final String label;
  const PlayerPause(this.label);
}

/// État de lecture d'un clip, sans rendu (testable sans GPU).
class ClipPlayback {
  final ClipEntry entry;

  /// Animations réduites : pas de lecture, images clés seulement.
  final bool reduceMotion;

  double _time = 0;
  bool _playing = false;
  PlayerPause? _autoPause;

  ClipPlayback(this.entry, {this.reduceMotion = false});

  double get duration => entry.duration;
  double get time => _time;
  bool get playing => _playing;

  /// Raison de la dernière pause automatique (null : pause voulue, ou
  /// lecture en cours).
  PlayerPause? get autoPause => _autoPause;

  ClipPhase get phase => entry.phaseAt(_time);

  /// Gain du halo à l'instant courant.
  double get haloGain =>
      phaseHaloGain(entry.phases, _time, reduceMotion: reduceMotion);

  /// Lance la lecture (sans effet quand les animations sont réduites).
  void play() {
    if (reduceMotion) return;
    _playing = true;
    _autoPause = null;
  }

  /// Met en pause ([reason] : pause automatique).
  void pause([PlayerPause? reason]) {
    if (!_playing) return;
    _playing = false;
    _autoPause = reason;
  }

  /// Reprend après une pause automatique de cette raison.
  bool resumeFrom(PlayerPause reason) {
    if (_playing || _autoPause != reason) return false;
    play();
    return true;
  }

  /// Avance de [dt] s (bornée à 0,1 s : après une page cachée ou une image
  /// perdue, pas de saut) ; le clip boucle.
  void advance(double dt) {
    if (!_playing || duration <= 0) return;
    _time = (_time + dt.clamp(0.0, .1)) % duration;
  }

  /// Place le temps (curseur). Animations réduites : image clé la plus
  /// proche.
  void seek(double t) {
    final v = t.clamp(0.0, duration);
    if (!reduceMotion) {
      _time = v;
      return;
    }
    _time = entry.keyTimes[nearestKey(v)];
  }

  /// Indice de l'image clé la plus proche de [t].
  int nearestKey(double t) {
    final keys = entry.keyTimes;
    var best = 0;
    for (var i = 1; i < keys.length; i++) {
      if ((keys[i] - t).abs() < (keys[best] - t).abs()) best = i;
    }
    return best;
  }

  /// Image clé courante (animations réduites).
  int get keyIndex => nearestKey(_time);

  void seekKey(int i) {
    final keys = entry.keyTimes;
    _time = keys[i.clamp(0, keys.length - 1)];
  }
}

/// Temps affiché : « 1,2 s ».
String playerSeconds(double t) =>
    '${t.toStringAsFixed(1).replaceAll('.', ',')} s';

/// Mannequin animé avec son lecteur.
class MannequinPlayer extends StatefulWidget {
  final ClipEntry clip;
  final Map<String, double> intensities;
  final Set<String> stretched;
  final MannequinView view;
  final double height;
  final Color? background;

  /// Images/s affichées (animation de test : fluidité).
  final bool showFps;

  /// Lecture au démarrage (jamais quand les animations sont réduites).
  final bool autoplay;
  final String semanticLabel;
  final Widget? fallback;
  final ValueChanged<bool>? onReady;

  const MannequinPlayer({
    super.key,
    required this.clip,
    this.intensities = const {},
    this.stretched = const {},
    this.view = MannequinView.troisQuarts,
    this.height = 420,
    this.background,
    this.showFps = false,
    this.autoplay = true,
    this.semanticLabel = 'Mannequin anatomique animé en 3D',
    this.fallback,
    this.onReady,
  });

  @override
  State<MannequinPlayer> createState() => MannequinPlayerState();
}

class MannequinPlayerState extends State<MannequinPlayer>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey<Mannequin3DState> _mannequin = GlobalKey();
  late final Ticker _ticker = createTicker(_onTick);
  ClipPlayback? _playback;
  MannequinClip? _clip;
  MannequinFraming? _framing;
  bool? _ready;
  String? _error;
  Duration _last = Duration.zero;
  Timer? _idle, _visibility;

  // Images/s : ticks de la dernière seconde.
  int _frames = 0;
  Duration _fpsStart = Duration.zero;
  double? _fps;

  /// État de lecture (tests).
  ClipPlayback? get playback => _playback;
  MannequinClip? get clip => _clip;
  MannequinFraming? get framing => _framing;
  double? get fps => _fps;
  bool? get ready => _ready;
  Mannequin3DState? get mannequin => _mannequin.currentState;

  bool get _reduceMotion => MediaQuery.of(context).disableAnimations;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idle?.cancel();
    _visibility?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final p = _playback;
    if (p == null) return;
    if (state == AppLifecycleState.resumed) {
      if (p.resumeFrom(PlayerPause.background)) _start();
    } else if (p.playing) {
      _stop(PlayerPause.background);
    }
  }

  Future<void> _onMannequinReady(bool ok) async {
    widget.onReady?.call(ok);
    if (!ok) {
      if (mounted) setState(() => _ready = false);
      return;
    }
    final state = _mannequin.currentState;
    final scene = state?.scene;
    final rig = scene?.rig;
    if (scene == null || rig == null) {
      if (mounted) setState(() => _ready = false);
      return;
    }
    try {
      final clip = await MannequinClip.load(widget.clip, rig);
      if (!mounted) return;
      // Cadrage commun à tout le clip : la caméra ne bouge pas.
      final times = <double>{
        ...widget.clip.keyTimes,
        for (var t = 0.0; t < clip.duration; t += .5) t,
      };
      final framing = scene.framingOver([for (final t in times) clip.sample(t)]);
      final playback = ClipPlayback(widget.clip, reduceMotion: _reduceMotion);
      setState(() {
        _clip = clip;
        _framing = framing;
        _playback = playback;
        _ready = true;
      });
      _apply();
      if (widget.autoplay && !playback.reduceMotion) {
        playback.play();
        _start();
      }
      _touch();
    } catch (_) {
      if (mounted) setState(() => _error = 'Animation illisible.');
    }
  }

  void _start() {
    if (!mounted) return;
    _last = Duration.zero;
    _frames = 0;
    _fpsStart = Duration.zero;
    if (!_ticker.isActive) _ticker.start();
    setState(() {});
  }

  void _stop([PlayerPause? reason]) {
    _playback?.pause(reason);
    if (_ticker.isActive) _ticker.stop();
    if (reason == PlayerPause.offscreen) {
      // Reprise dès que le lecteur revient à l'écran.
      _visibility?.cancel();
      _visibility = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (!mounted) return;
        if (_onScreen()) {
          _visibility?.cancel();
          if (_playback?.resumeFrom(PlayerPause.offscreen) ?? false) _start();
        }
      });
    }
    if (mounted) setState(() {});
  }

  void _onTick(Duration elapsed) {
    final p = _playback;
    if (p == null || !p.playing) return;
    final dt = _last == Duration.zero
        ? 0.0
        : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    p.advance(dt);
    _frames++;
    final window = elapsed - _fpsStart;
    if (window >= const Duration(seconds: 1)) {
      if (_fpsStart != Duration.zero) {
        _fps = (_frames - 1) * 1e6 / window.inMicroseconds;
      }
      _fpsStart = elapsed;
      _frames = 1;
      // Hors de l'écran (défilement) : pause.
      if (!_onScreen()) {
        _stop(PlayerPause.offscreen);
        return;
      }
    }
    _apply();
  }

  /// Le lecteur est-il (au moins en partie) à l'écran ?
  bool _onScreen() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return false;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    return rect.overlaps(Offset.zero & MediaQuery.sizeOf(context));
  }

  void _apply() {
    final p = _playback, clip = _clip;
    if (p == null || clip == null) return;
    _mannequin.currentState?.showPose(
      clip.sample(p.time),
      framing: _framing,
      haloGain: p.haloGain,
    );
    if (mounted) setState(() {});
  }

  /// Interaction : relance le délai d'inactivité.
  void _touch() {
    if (_playback == null) return;
    _idle?.cancel();
    _idle = Timer(kPlayerIdlePause, () {
      if (mounted && (_playback?.playing ?? false)) _stop(PlayerPause.idle);
    });
  }

  /// Lecture / pause (bouton).
  void toggle() {
    final p = _playback;
    if (p == null) return;
    _touch();
    if (p.playing) {
      _stop();
    } else {
      p.play();
      _start();
    }
  }

  /// Place le temps (curseur, tests).
  void seek(double t) {
    final p = _playback;
    if (p == null) return;
    _touch();
    p.seek(t);
    _apply();
  }

  bool _wasPlaying = false;

  @override
  Widget build(BuildContext context) {
    final view = Mannequin3D(
      key: _mannequin,
      animated: true,
      intensities: widget.intensities,
      stretched: widget.stretched,
      view: widget.view,
      height: widget.height,
      background: widget.background,
      semanticLabel: widget.semanticLabel,
      fallback: widget.fallback,
      onReady: _onMannequinReady,
    );
    return Listener(
      onPointerDown: (_) => _touch(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          view,
          if (_ready == true && _playback != null) _controls(context),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: TextStyle(color: SL.dim)),
            ),
        ],
      ),
    );
  }

  Widget _controls(BuildContext context) {
    final p = _playback!;
    final tt = Theme.of(context).textTheme;
    final phase = p.phase;
    final keys = widget.clip.keyTimes;
    final Widget slider;
    if (p.reduceMotion) {
      // Images clés seulement : début et fin de chaque phase.
      final i = p.keyIndex;
      slider = Slider(
        key: const ValueKey('player-slider'),
        value: i.toDouble(),
        max: (keys.length - 1).toDouble(),
        divisions: keys.length - 1,
        semanticFormatterCallback: (v) {
          final k = v.round().clamp(0, keys.length - 1);
          return 'Image clé ${k + 1} sur ${keys.length}, '
              '${playerSeconds(keys[k])}, ${widget.clip.phaseAt(keys[k]).name}';
        },
        onChanged: (v) {
          _touch();
          p.seekKey(v.round());
          _apply();
        },
      );
    } else {
      slider = Slider(
        key: const ValueKey('player-slider'),
        value: p.time.clamp(0.0, p.duration),
        max: p.duration,
        semanticFormatterCallback: (v) =>
            '${playerSeconds(v)} sur ${playerSeconds(p.duration)}, '
            '${widget.clip.phaseAt(v).name}',
        onChangeStart: (_) {
          _wasPlaying = p.playing;
          if (p.playing) _stop();
        },
        onChanged: seek,
        onChangeEnd: (_) {
          if (_wasPlaying) {
            p.play();
            _start();
          }
        },
      );
    }
    final auto = p.autoPause;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (!p.reduceMotion)
                IconButton.filledTonal(
                  key: const ValueKey('player-play'),
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  tooltip: p.playing ? 'Pause' : 'Lecture',
                  onPressed: toggle,
                  icon: Icon(p.playing ? Icons.pause : Icons.play_arrow),
                ),
              Expanded(child: slider),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: !p.playing,
                  child: Text(
                    phase.label,
                    key: const ValueKey('player-phase'),
                    style: tt.titleSmall,
                  ),
                ),
              ),
              Text(
                '${playerSeconds(p.time)} / ${playerSeconds(p.duration)}',
                key: const ValueKey('player-time'),
                style: tt.bodySmall,
              ),
            ],
          ),
          if (widget.showFps || auto != null || p.reduceMotion)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                [
                  if (widget.showFps)
                    _fps == null || !p.playing
                        ? 'Images/s : mesure pendant la lecture'
                        : 'Images/s : ${_fps!.round()}',
                  if (auto != null) 'En pause : ${auto.label}',
                  if (p.reduceMotion)
                    'Animations réduites : images clés de début et de fin '
                        'de chaque phase',
                ].join(' · '),
                key: const ValueKey('player-status'),
                style: tt.bodySmall?.copyWith(color: SL.dim),
              ),
            ),
        ],
      ),
    );
  }
}
