// G1 (D2.1, D2.2) : racine de l'application et redémarrage logique.
//
// Passer de la session personnelle à la session de test (ou l'inverse), ou
// changer la date de la session de test, redémarre l'application sans
// quitter le processus : les écritures en attente sont terminées, l'arbre
// de l'application est démonté (écrans, routes, états), un magasin neuf
// est chargé depuis l'espace de la session active, puis l'ouverture est
// rejouée. Hors build de développement, la racine ne redémarre jamais.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kalis_koach/kalis_koach.dart' show KoachPose;

import 'app_theme.dart';
import 'dev/dev_flags.dart';
import 'dev/dev_widgets.dart';
import 'mannequin_3d.dart' show Display3DSettings;
import 'store.dart';

class SessionHost extends StatefulWidget {
  /// Démarrage : lecture de la session active puis chargement du magasin.
  final Future<void> Function() boot;

  /// Application pour une initialisation (écran d'ouverture compris).
  final Widget Function(Future<void> initialization) builder;
  const SessionHost({super.key, required this.boot, required this.builder});

  static _SessionHostState? _current;

  /// Redémarrage logique : [change] s'exécute une fois l'application
  /// démontée et les écritures de la session quittée terminées ; un
  /// magasin neuf est ensuite chargé. [message] est annoncé à l'arrivée,
  /// par Koach (G5) dans la pose [koach], avec [detail] en dessous.
  static Future<void> restart(
    Future<void> Function() change, {
    String? message,
    String? detail,
    KoachPose koach = KoachPose.settings,
  }) async {
    final host = _current;
    if (host == null || !host.mounted) {
      await change();
      return;
    }
    await host._restart(change, message, detail, koach);
  }

  /// Redémarrage en cours (tests).
  static bool get switching => _current?._switching ?? false;

  @override
  State<SessionHost> createState() => _SessionHostState();
}

class _SessionHostState extends State<SessionHost> {
  late Future<void> _init;
  int _generation = 0;
  bool _switching = false;
  String? _message, _detail;
  KoachPose _koach = KoachPose.settings;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    SessionHost._current = this;
    _init = widget.boot();
  }

  @override
  void dispose() {
    if (identical(SessionHost._current, this)) SessionHost._current = null;
    _messageTimer?.cancel();
    super.dispose();
  }

  Future<void> _restart(
    Future<void> Function() change,
    String? message,
    String? detail,
    KoachPose koach,
  ) async {
    if (_switching) return;
    // Écritures de la session quittée terminées avant tout changement.
    try {
      await store.flush();
    } catch (_) {}
    setState(() => _switching = true);
    // L'arbre de l'application est démonté (écrans, routes, écouteurs du
    // magasin) avant le changement de session.
    await WidgetsBinding.instance.endOfFrame;
    Object? failure;
    try {
      await change();
    } catch (error) {
      failure = error;
    }
    Display3DSettings.instance.reset();
    store = AppStore();
    if (!mounted) return;
    setState(() {
      _generation++;
      _switching = false;
      _init = store.init();
    });
    if (failure == null) {
      _say(message, detail, koach);
    } else {
      _say('Opération impossible : $failure', null, KoachPose.oops);
    }
  }

  void _say(String? message, String? detail, KoachPose koach) {
    _messageTimer?.cancel();
    setState(() {
      _message = message;
      _detail = detail;
      _koach = koach;
    });
    if (message == null) return;
    _messageTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _message = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_switching)
            ColoredBox(color: KPalette(dark).bg)
          else
            KeyedSubtree(
              key: ValueKey('session-$_generation'),
              child: widget.builder(_init),
            ),
          if (kDevBuild) const DevBadge(),
          if (_message != null)
            SessionToast(message: _message!, detail: _detail, pose: _koach),
        ],
      ),
    );
  }
}
