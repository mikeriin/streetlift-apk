// M56 (mannequin 3D) : préchargement du mannequin au lancement.
//
// Décision du propriétaire (28/09/2026) : plus de saccade à chaque
// affichage du mannequin. Juste après que l'application est prête (première
// image affichée, initialisation faite), le modèle, sa carte, son squelette,
// sa peau sont chargés en tâche de fond dans les caches partagés par tous
// les écrans (`MannequinScene`, `MannequinRig`, `MannequinMap`), puis les
// pipelines de rendu sont
// préchauffés par une image hors écran (`Scene.warmUp`) : le premier
// mannequin visible ne compile plus les shaders. Un écran 3D ouvert avant la
// fin du préchargement attend les mêmes futurs (pas de double chargement)
// derrière son indicateur discret.
//
// Mesures (Réglages › À propos › Moteur 3D) : durée du préchargement
// (chargement, préchauffage), mémoire résidente ajoutée, et pour le dernier
// mannequin ouvert : temps jusqu'à sa première image et images perdues
// pendant l'ouverture.
import 'dart:async';
import 'dart:io' show ProcessInfo;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_scene/scene.dart';

import 'engine3d.dart';
import 'mannequin_3d.dart';

/// Résultat du préchargement.
class PreloadReport {
  /// Chargement des ressources (modèle, carte, rig, peau), ms.
  final int loadMs;

  /// Préchauffage des pipelines (image hors écran), ms ; -1 si impossible.
  final int warmUpMs;

  /// Mémoire résidente avant et après, octets (0 si indisponible).
  final int rssBefore, rssAfter;

  /// Téléphone compatible (sinon rien n'est préchargé).
  final bool compatible;
  const PreloadReport({
    required this.loadMs,
    required this.warmUpMs,
    required this.rssBefore,
    required this.rssAfter,
    required this.compatible,
  });

  int get totalMs => loadMs + (warmUpMs > 0 ? warmUpMs : 0);
  double get addedMb => (rssAfter - rssBefore) / (1024 * 1024);
}

/// Ouverture d'un écran avec mannequin : temps jusqu'à la première image du
/// mannequin et images perdues (plus de deux intervalles d'affichage)
/// pendant l'ouverture.
class OpenReport {
  final int firstImageMs;
  final int lostFrames, frames;

  /// Préchargement terminé avant cette ouverture.
  final bool preloaded;
  const OpenReport(
    this.firstImageMs,
    this.lostFrames,
    this.frames,
    this.preloaded,
  );
}

class MannequinPreload {
  MannequinPreload._();

  /// Désactivé par les tests de mesure « avant » (CI 3D).
  static bool enabled = true;

  static Future<void>? _pending;
  static PreloadReport? _report;
  static bool _done = false;

  /// Rapport du préchargement (null tant qu'il n'est pas terminé).
  static PreloadReport? get report => _report;
  static bool get done => _done;

  /// Ouverture du dernier mannequin (écran fiche, Anatomie, STATS…).
  static final lastOpen = ValueNotifier<OpenReport?>(null);

  /// Lance le préchargement (une seule fois) ; sans effet si désactivé.
  static Future<void> start() {
    if (!enabled) return Future.value();
    return _pending ??= _run();
  }

  /// Tests : état initial.
  @visibleForTesting
  static void reset() {
    _pending = null;
    _report = null;
    _done = false;
    lastOpen.value = null;
  }

  static int _rss() {
    try {
      return ProcessInfo.currentRss;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> _run() async {
    final rss0 = _rss();
    final sw = Stopwatch()..start();
    var compatible = false;
    var warm = -1;
    try {
      final support = await engine3DSupport();
      compatible = support.compatible;
      if (compatible) {
        // Ressources : modèle (converti par le hook de build), carte, rig,
        // peau.
        final scene = await MannequinScene.create();
        final load = sw.elapsedMilliseconds;
        // Préchauffage : matériaux mis en évidence (rampe, halo) et peau,
        // une image hors écran, jetée.
        final sw2 = Stopwatch()..start();
        try {
          scene.configure(
            dark: true,
            intensities: scene.map.fromGroups(const {'dos': 1.0}),
            bones: true,
            halo: true,
          );
          final camera = scene.camera(0, .06, scene.fitDistance(.75));
          await scene.scene.warmUp([RenderView(camera: camera)]);
          warm = sw2.elapsedMilliseconds;
        } catch (_) {
          warm = -1;
        }
        _report = PreloadReport(
          loadMs: load,
          warmUpMs: warm,
          rssBefore: rss0,
          rssAfter: _rss(),
          compatible: true,
        );
      } else {
        _report = PreloadReport(
          loadMs: sw.elapsedMilliseconds,
          warmUpMs: -1,
          rssBefore: rss0,
          rssAfter: _rss(),
          compatible: false,
        );
      }
    } catch (_) {
      // Modèle illisible : les écrans réessaieront ; rien à signaler ici.
    } finally {
      _done = true;
    }
  }
}

/// Mesure de l'ouverture d'un mannequin (démarrée par [Mannequin3D] à sa
/// création, arrêtée peu après sa première image).
class OpenTimer {
  final Stopwatch _sw = Stopwatch()..start();
  final bool _preloaded = MannequinPreload.done;
  final List<FrameTiming> _timings = [];
  bool _listening = true;
  Timer? _stop;

  OpenTimer() {
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  void _onTimings(List<FrameTiming> t) => _timings.addAll(t);

  /// Première image du mannequin affichée : encore 400 ms de collecte, puis
  /// bilan dans [MannequinPreload.lastOpen].
  void firstImage() {
    if (!_listening || _stop != null) return;
    final ms = _sw.elapsedMilliseconds;
    _stop = Timer(const Duration(milliseconds: 400), () => _finish(ms));
  }

  void _finish(int firstMs) {
    if (!_listening) return;
    _listening = false;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    var lost = 0;
    for (final t in _timings) {
      // Perdue : plus de deux intervalles d'affichage (33 ms à 60 Hz).
      if (t.totalSpan.inMicroseconds > 33334) lost++;
    }
    MannequinPreload.lastOpen.value = OpenReport(
      firstMs,
      lost,
      _timings.length,
      _preloaded,
    );
  }

  void cancel() {
    if (!_listening) return;
    _listening = false;
    _stop?.cancel();
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
  }
}
