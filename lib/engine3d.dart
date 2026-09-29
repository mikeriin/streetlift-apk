// M1 (mannequin 3D) : socle du moteur 3D et écran de diagnostic
// « Moteur 3D » (Réglages › À propos › Moteur 3D).
//
// Le moteur est flutter_scene (Flutter GPU sur Impeller), décision du
// propriétaire du 27/09/2026. Cet écran indique si le téléphone est
// compatible et mesure la fluidité sur 10 s. Depuis M2, le rendu mesuré est
// le mannequin anatomique (lib/mannequin_3d.dart) en rotation lente, muscles
// d'une traction allumés dans la rampe historique (halo en thème sombre).
// Sans Flutter GPU, l'écran le dit clairement et rien ne plante :
// l'application garde ses illustrations 2D.
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FramePhase;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:flutter_scene/scene.dart';

import 'animation_test_screen.dart';
import 'app_theme.dart';
import 'device.dart';
import 'mannequin_3d.dart';
import 'mannequin_preload.dart';
import 'ui.dart';

/// Résultat de la vérification du moteur 3D sur cet appareil.
class Engine3DSupport {
  /// Flutter GPU répond (contexte GPU créé).
  final bool gpuAvailable;

  /// Ressources du moteur chargées (shaders, tables) : le rendu peut démarrer.
  final bool engineReady;

  /// Raison lisible en cas d'échec (jamais affichée brute à l'utilisateur).
  final String? error;

  const Engine3DSupport({
    required this.gpuAvailable,
    required this.engineReady,
    this.error,
  });

  bool get compatible => gpuAvailable && engineReady;
}

Future<Engine3DSupport>? _support;
Engine3DSupport? _supportKnown;

/// Vérifie une seule fois par lancement que Flutter GPU et flutter_scene
/// fonctionnent. Ne lève jamais d'exception.
Future<Engine3DSupport> engine3DSupport() =>
    _support ??= _probe().then((s) => _supportKnown = s);

/// Résultat de [engine3DSupport] s'il est déjà connu (M2 : le mannequin
/// choisit son affichage dès sa construction, sans attente ni indicateur).
Engine3DSupport? get engine3DSupportKnown => _supportKnown;

Future<Engine3DSupport> _probe() async {
  try {
    // Lève une exception si Flutter GPU n'est pas activé ou pas pris en
    // charge (moteur de rendu Skia, pilote trop ancien, tests sur ordinateur).
    gpu.gpuContext;
  } catch (e) {
    return Engine3DSupport(
      gpuAvailable: false,
      engineReady: false,
      error: '$e',
    );
  }
  try {
    await Scene.initializeStaticResources();
  } catch (e) {
    return Engine3DSupport(gpuAvailable: true, engineReady: false, error: '$e');
  }
  return Engine3DSupport(
    gpuAvailable: true,
    engineReady: Scene.isReadyToRender,
    error: Scene.isReadyToRender ? null : 'Ressources du moteur non chargées',
  );
}

/// Mesure de fluidité : images par seconde et temps d'image (du début de la
/// construction à la fin du rendu GPU de chaque image).
class FrameStats {
  final int frames;
  final Duration window;
  final double meanMs, p99Ms;

  const FrameStats({
    required this.frames,
    required this.window,
    required this.meanMs,
    required this.p99Ms,
  });

  double get fps =>
      window.inMicroseconds == 0 ? 0 : frames * 1e6 / window.inMicroseconds;

  /// Images rendues pendant [window] à partir de la première reçue, comptées
  /// sur l'horloge du moteur (les temps d'image arrivent par lots, avec
  /// jusqu'à une seconde de retard : la fenêtre ne dépend pas de leur
  /// arrivée).
  static FrameStats fromTimings(List<FrameTiming> timings, Duration window) {
    if (timings.isEmpty) return of(const [], window);
    int vsync(FrameTiming t) =>
        t.timestampInMicroseconds(FramePhase.vsyncStart);
    final start = timings.map(vsync).reduce(math.min);
    final limit = start + window.inMicroseconds;
    return of([
      for (final t in timings)
        if (vsync(t) < limit) t.totalSpan,
    ], window);
  }

  /// Calcule la moyenne et le 99e centile (rang supérieur) des durées.
  static FrameStats of(List<Duration> spans, Duration window) {
    if (spans.isEmpty) {
      return FrameStats(frames: 0, window: window, meanMs: 0, p99Ms: 0);
    }
    final ms = [for (final s in spans) s.inMicroseconds / 1000]..sort();
    final mean = ms.reduce((a, b) => a + b) / ms.length;
    final rank = (ms.length * .99).ceil().clamp(1, ms.length) - 1;
    return FrameStats(
      frames: ms.length,
      window: window,
      meanMs: mean,
      p99Ms: ms[rank],
    );
  }
}

/// Seuil de fluidité retenu pour la suite du pipeline (images par seconde).
const kEngine3DFluidFps = 45.0;

/// Durée de la mesure de fluidité.
const kEngine3DMeasure = Duration(seconds: 10);

/// Gris mat de la musculature (page de référence validée : #8F8B8A).
const kMuscleGray = Color(0xFF8F8B8A);

/// Fond de la scène 3D (page de référence validée).
Color sceneBackground(bool dark) =>
    dark ? const Color(0xFF161414) : const Color(0xFFEDEBEA);

/// Écran « Moteur 3D » : mannequin en rotation, compatibilité et fluidité.
class Engine3DScreen extends StatefulWidget {
  /// Mesure de fluidité lancée automatiquement une fois le rendu prêt.
  final bool autoMeasure;
  const Engine3DScreen({super.key, this.autoMeasure = true});

  @override
  State<Engine3DScreen> createState() => Engine3DScreenState();
}

class Engine3DScreenState extends State<Engine3DScreen> {
  Engine3DSupport? _support;
  Map<String, Object?> _info = const {};

  /// Muscles d'une traction (principal, secondaire, stabilisateur) : rampe
  /// et halo dans le rendu mesuré.
  Map<String, double> _demo = const {};
  bool _ready = false;

  // Mesure de fluidité.
  final List<FrameTiming> _timings = [];
  bool _firstBatch = true;
  Timer? _measureTimer;
  FrameStats? _stats;
  bool _measuring = false;

  /// Dernière mesure terminée (tests d'intégration et captures CI).
  FrameStats? get stats => _stats;
  Engine3DSupport? get support => _support;
  Map<String, Object?> get info => _info;

  /// Mannequin affiché et prêt (rendu mesurable).
  bool get ready => _ready;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    final results = await Future.wait<Object>([
      engine3DSupport(),
      graphicsInfo(),
    ]);
    if (!mounted) return;
    final support = results[0] as Engine3DSupport;
    var demo = const <String, double>{};
    if (support.compatible) {
      try {
        demo = (await MannequinMap.load()).fromGroups(const {
          'dos': kIntensityPrimary,
          'biceps': kIntensitySecondary,
          'avant-bras': kIntensityStabilizer,
        });
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _support = support;
      _info = results[1] as Map<String, Object?>;
      _demo = demo;
    });
  }

  void _onReady(bool ok) {
    if (!mounted || _ready == ok) return;
    setState(() => _ready = ok);
    if (ok && widget.autoMeasure) {
      // Laisse le premier rendu se stabiliser avant de mesurer.
      _measureTimer = Timer(const Duration(milliseconds: 800), startMeasure);
    }
  }

  @override
  void dispose() {
    _stopMeasure(record: false);
    super.dispose();
  }

  void startMeasure() {
    if (!mounted || !_ready || _measuring) return;
    _timings.clear();
    _firstBatch = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    setState(() => _measuring = true);
    _measureTimer?.cancel();
    // Délai de collecte après la fenêtre : les derniers temps d'image
    // arrivent par lot.
    _measureTimer = Timer(
      kEngine3DMeasure + const Duration(milliseconds: 2500),
      () => _stopMeasure(record: true),
    );
  }

  void _onTimings(List<FrameTiming> timings) {
    // Le premier lot peut contenir des images antérieures au début de la
    // mesure : il est écarté, la fenêtre commence à l'image suivante.
    if (_firstBatch) {
      _firstBatch = false;
      return;
    }
    _timings.addAll(timings);
  }

  void _stopMeasure({required bool record}) {
    _measureTimer?.cancel();
    _measureTimer = null;
    if (!_measuring) return;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _measuring = false;
    if (record && mounted) {
      setState(
        () => _stats = FrameStats.fromTimings(_timings, kEngine3DMeasure),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return KScreen(
      appBar: AppBar(title: const Text('MOTEUR 3D')),
      body: KList(
        key: const ValueKey('engine3d-list'),
        children: [
          _view(dark),
          _animationTest(context),
          _compatibility(context),
          _performance(context),
          _preload(context),
          Text(
            'Le mannequin anatomique 3D tourne lentement, muscles d’une '
            'traction allumés : la mesure porte sur ce rendu. Sans moteur 3D, '
            'l’application garde ses illustrations 2D.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _view(bool dark) {
    final support = _support;
    if (support != null && support.compatible) {
      return KeyedSubtree(
        key: const ValueKey('engine3d-view'),
        child: Mannequin3D(
          intensities: _demo,
          view: MannequinView.troisQuarts,
          viewButtons: false,
          spin: true,
          // M6b : fond de la page (décision du 29/09/2026 : fond de chaque
          // vue 3D = couleur de son support, sans démarcation).
          background: Theme.of(context).scaffoldBackgroundColor,
          height: 380,
          onReady: _onReady,
          semanticLabel:
              'Mannequin anatomique en rotation, muscles d’une traction '
              'allumés',
        ),
      );
    }
    final Widget child;
    if (support == null) {
      child = const AspectRatio(
        aspectRatio: 1,
        child: Center(child: CircularProgressIndicator()),
      );
    } else {
      child = Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.view_in_ar_outlined, size: 40, color: SL.dim),
              const SizedBox(height: 12),
              Text(
                'La 3D n’est pas disponible sur ce téléphone.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Les fiches et les statistiques continuent d’utiliser les '
                'illustrations 2D.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(KSpace.radius),
      child: ColoredBox(color: sceneBackground(dark), child: child),
    );
  }

  Widget _compatibility(BuildContext context) {
    final support = _support;
    final ok = support?.compatible ?? false;
    final tt = Theme.of(context).textTheme;
    final backend = _backendLabel();
    final device = [
      _info['manufacturer'],
      _info['model'],
    ].whereType<String>().where((s) => s.isNotEmpty).join(' ');
    final android = _info['release'] == null
        ? 'inconnue'
        : 'Android ${_info['release']} (API ${_info['sdk']})';
    return KCard(
      key: const ValueKey('engine3d-compat'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                support == null
                    ? Icons.hourglass_empty
                    : ok
                    ? Icons.check_circle
                    : Icons.cancel,
                color: support == null
                    ? SL.dim
                    : ok
                    ? SL.success
                    : SL.danger,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  support == null
                      ? 'Vérification…'
                      : ok
                      ? 'Compatible'
                      : 'Non compatible',
                  style: tt.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _row(
            'Flutter GPU',
            support == null
                ? '…'
                : support.gpuAvailable
                ? 'disponible'
                : 'absent',
          ),
          _row('API graphique', backend),
          _row('Appareil', device.isEmpty ? 'inconnu' : device),
          _row('Version', android),
          if (support != null && !ok) ...[
            const SizedBox(height: 8),
            Text(
              support.gpuAvailable
                  ? 'Le moteur 3D n’a pas pu démarrer sur ce téléphone.'
                  : 'Ce téléphone n’active pas Flutter GPU, nécessaire au '
                        'moteur 3D.',
              style: tt.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  String _backendLabel() {
    final used = _info['impellerBackend'];
    if (used is String && used.isNotEmpty) {
      final name = used == 'OpenGLES' ? 'OpenGL ES' : used;
      return '$name (Impeller)';
    }
    final vulkan = _info['vulkanVersion'];
    final major = _info['glesMajor'], minor = _info['glesMinor'];
    final caps = <String>[
      if (vulkan is int && vulkan > 0)
        'Vulkan ${vulkan >> 22}.${(vulkan >> 12) & 0x3ff}',
      if (major is int && major > 0) 'OpenGL ES $major.$minor',
    ];
    return caps.isEmpty ? 'inconnue' : caps.join(' · ');
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: TextStyle(color: SL.dim)),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );

  /// M7 : accès à l'animation de test (lecteur, intensité par phase).
  Widget _animationTest(BuildContext context) => KCard(
    key: const ValueKey('engine3d-animation-test'),
    onTap: () {
      // La mesure de fluidité de cette page s'arrête : le lecteur mesure la
      // sienne.
      _stopMeasure(record: false);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AnimationTestScreen()),
      );
    },
    child: Row(
      children: [
        Icon(Icons.directions_run, color: SL.dim),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Animation de test',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Squat lent au poids du corps, réservé aux tests du lecteur '
                '3D (phases, intensité, fluidité).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: SL.dim),
      ],
    ),
  );

  /// M56 : préchargement au lancement et ouverture du dernier mannequin.
  Widget _preload(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    String ms(int v) => '$v ms';
    return KCard(
      key: const ValueKey('engine3d-preload'),
      child: ValueListenableBuilder<OpenReport?>(
        valueListenable: MannequinPreload.lastOpen,
        builder: (context, open, _) {
          final r = MannequinPreload.report;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Préchargement', style: tt.titleMedium),
              const SizedBox(height: 8),
              if (!MannequinPreload.enabled)
                Text('Désactivé (mesure de référence).', style: tt.bodySmall)
              else if (r == null)
                Text(
                  MannequinPreload.done
                      ? 'Préchargement impossible (modèle illisible).'
                      : 'Préchargement en cours…',
                  style: tt.bodySmall,
                )
              else if (!r.compatible)
                Text('Rien à précharger sans moteur 3D.', style: tt.bodySmall)
              else ...[
                _row('Au lancement', '${ms(r.totalMs)} après l’accueil'),
                _row('Chargement', ms(r.loadMs)),
                _row(
                  'Préchauffage',
                  r.warmUpMs >= 0 ? ms(r.warmUpMs) : 'indisponible',
                ),
                if (r.rssBefore > 0)
                  _row(
                    'Mémoire ajoutée',
                    '${r.addedMb.toStringAsFixed(1).replaceAll('.', ',')} Mo',
                  ),
              ],
              if (open != null) ...[
                const SizedBox(height: 6),
                _row(
                  'Dernier mannequin',
                  'première image en ${ms(open.firstImageMs)}, '
                      '${open.lostFrames} image${open.lostFrames > 1 ? 's' : ''} '
                      'perdue${open.lostFrames > 1 ? 's' : ''} sur ${open.frames}'
                      '${open.preloaded ? '' : ' (avant la fin du préchargement)'}',
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _performance(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final stats = _stats;
    final canMeasure = _ready;
    String fmt(double v) => v.toStringAsFixed(1).replaceAll('.', ',');
    return KCard(
      key: const ValueKey('engine3d-perf'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fluidité', style: tt.titleMedium),
          const SizedBox(height: 8),
          if (!canMeasure)
            Text(
              (_support?.compatible ?? false)
                  ? 'Chargement du mannequin…'
                  : 'Mesure impossible sans moteur 3D.',
              style: tt.bodySmall,
            )
          else if (_measuring) ...[
            Text(
              'Mesure en cours sur ${kEngine3DMeasure.inSeconds} s…',
              style: tt.bodyMedium,
            ),
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ] else if (stats == null)
            Text('Mesure en attente.', style: tt.bodySmall)
          else if (stats.frames == 0)
            Text(
              'Aucun temps d’image reçu pendant la mesure : relance-la.',
              style: tt.bodySmall,
            )
          else ...[
            _row('Images/s', fmt(stats.fps)),
            _row('Temps moyen', '${fmt(stats.meanMs)} ms'),
            _row('99e centile', '${fmt(stats.p99Ms)} ms'),
            const SizedBox(height: 6),
            Text(
              stats.fps >= kEngine3DFluidFps
                  ? 'Fluide : le mannequin animé pourra s’afficher.'
                  : 'Moins de ${kEngine3DFluidFps.round()} images/s : '
                        'l’animation 3D risque d’être saccadée.',
              style: tt.bodySmall,
            ),
          ],
          if (canMeasure && !_measuring) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                key: const ValueKey('engine3d-measure'),
                onPressed: startMeasure,
                icon: const Icon(Icons.speed),
                label: Text(
                  stats == null ? 'Mesurer (10 s)' : 'Mesurer à nouveau',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
