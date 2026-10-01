// G1 (D2.1, D2.2, D2.5) : gestes et écrans du mode dev.
//
// - Logo de l'en-tête ([HeaderLogo]) : 5 appuis d'affilée (2 s au plus
//   entre deux appuis) démarrent une session de test vierge ; pendant la
//   session de test le logo est rose vif, et un appui long de 3 s (anneau
//   de progression, relâcher annule) la supprime directement.
// - Étiquette « DEV » ([DevBadge]) au bord droit de tous les écrans pendant
//   la session de test ; appui long : outils de test.
// - Outils de test ([DevToolsSheet]) : voyage dans le temps, export JSON de
//   la session, suppression ; emplacements du simulateur et de
//   l'inspecteur (G10).
// Hors build de développement ([kDevBuild] faux), [HeaderLogo] est le logo
// d'origine, sans geste, et rien d'autre de ce fichier n'est atteint.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kalis_koach/kalis_koach.dart' show KoachPose;

import '../app_theme.dart';
import '../backup_files.dart' show backupFileName;
import '../brand.dart';
import '../kalis_clock.dart';
import '../koach/koach_view.dart';
import '../main.dart' show appNavigator;
import '../program_start.dart' show longCivilDate;
import '../session_host.dart';
import '../settings_screen.dart' show kAppVersion;
import '../program_screens.dart' show ProgramScreen;
import '../store.dart';
import 'dev_flags.dart';
import 'dev_session.dart';

/// Couleur du logo : rose vif pendant la session de test.
Color devLogoColor(Color normal) =>
    kDevBuild && DevSession.active.value ? kDevPink : normal;

/// Série d'appuis rapprochés : [target] appuis, au plus [window] entre deux.
class TapStreak {
  final int target;
  final Duration window;
  TapStreak({this.target = 5, this.window = const Duration(seconds: 2)});

  DateTime? _last;
  int _count = 0;

  /// Appuis comptés dans la série en cours.
  int get count => _count;

  /// Compte un appui à [at] ; vrai quand la série atteint [target] (elle
  /// repart alors de zéro).
  bool tap(DateTime at) {
    final last = _last;
    if (last == null || at.difference(last) > window || at.isBefore(last)) {
      _count = 0;
    }
    _count++;
    _last = at;
    if (_count >= target) {
      reset();
      return true;
    }
    return false;
  }

  void reset() {
    _count = 0;
    _last = null;
  }
}

/// Actions du mode dev (redémarrage logique de l'application).
class DevActions {
  DevActions._();

  /// Démarre une session de test vierge.
  static Future<void> start() => SessionHost.restart(
    DevSession.create,
    message: 'Session de test : installation neuve',
    detail: 'Rien de ce que tu fais ici ne touche ta session personnelle.',
    koach: KoachPose.settings,
  );

  /// Supprime la session de test et revient à la session personnelle.
  static Future<void> delete() => SessionHost.restart(
    () async {
      final remaining = await DevSession.destroy();
      if (remaining.isNotEmpty) {
        throw 'suppression incomplète (${remaining.length} clés)';
      }
    },
    message: 'Session de test supprimée',
    detail: 'Retour à ta session personnelle.',
    koach: KoachPose.wave,
  );

  /// Voyage dans le temps : date simulée = aujourd'hui + [days] jours.
  static Future<void> travel(int days) {
    final real = KalisClock.realNow();
    final target = DateTime(real.year, real.month, real.day + days);
    return SessionHost.restart(
      () => DevSession.setOffsetDays(days),
      message: days == 0
          ? 'Retour à aujourd’hui'
          : 'Date simulée : ${longCivilDate(target)}',
      koach: KoachPose.direction,
    );
  }
}

/// Logo de l'en-tête (accueil et autres écrans à en-tête).
class HeaderLogo extends StatelessWidget {
  const HeaderLogo({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDevBuild) return KalisLogo(color: SL.logo);
    return ValueListenableBuilder<bool>(
      valueListenable: DevSession.active,
      builder: (context, active, _) => DevLogoGesture(
        key: const ValueKey('header-logo'),
        active: active,
        onFiveTaps: DevActions.start,
        onHoldComplete: DevActions.delete,
      ),
    );
  }
}

/// Logo avec les gestes du mode dev.
class DevLogoGesture extends StatefulWidget {
  /// Session de test active : logo rose, appui long de 3 s.
  final bool active;
  final VoidCallback onFiveTaps, onHoldComplete;

  /// Horloge des appuis (tests).
  final DateTime Function() clock;
  const DevLogoGesture({
    super.key,
    required this.active,
    required this.onFiveTaps,
    required this.onHoldComplete,
    this.clock = KalisClock.realNow,
  });

  /// Durée de l'appui long de suppression.
  static const hold = Duration(seconds: 3);

  /// Au-delà, un appui n'est plus un appui court.
  static const tapMax = Duration(milliseconds: 500);

  @override
  State<DevLogoGesture> createState() => _DevLogoGestureState();
}

class _DevLogoGestureState extends State<DevLogoGesture>
    with SingleTickerProviderStateMixin {
  final _streak = TapStreak();
  // Durée réelle même avec « Réduire les animations » (sinon Flutter
  // raccourcit l'animation à 5 % : l'appui de 3 s durerait 0,15 s).
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: DevLogoGesture.hold,
    animationBehavior: AnimationBehavior.preserve,
  )..addStatusListener(_onHold);
  DateTime? _downAt;
  Offset? _downPos;
  bool _fired = false;

  @override
  void didUpdateWidget(DevLogoGesture old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) {
      _hold.value = 0;
      _streak.reset();
    }
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  void _onHold(AnimationStatus status) {
    if (status != AnimationStatus.completed || _fired || !widget.active) {
      return;
    }
    _fired = true;
    HapticFeedback.heavyImpact();
    widget.onHoldComplete();
  }

  void _down(PointerDownEvent e) {
    _downAt = widget.clock();
    _downPos = e.position;
    _fired = false;
    if (widget.active) _hold.forward(from: 0);
  }

  void _move(PointerMoveEvent e) {
    final start = _downPos;
    if (start != null && (e.position - start).distance > 24) _cancel();
  }

  void _cancel([PointerEvent? _]) {
    _downAt = null;
    _downPos = null;
    if (!_fired && _hold.value > 0) {
      _hold.stop();
      _hold.value = 0;
    }
  }

  void _up(PointerUpEvent e) {
    final downAt = _downAt;
    _cancel();
    if (downAt == null || _fired) return;
    final now = widget.clock();
    if (now.difference(downAt) > DevLogoGesture.tapMax) return;
    _tap(now);
  }

  /// Appui court : compte seulement hors session de test (5 appuis pendant
  /// une session de test ne font rien, DECISIONS_GP.md G1).
  void _tap(DateTime at) {
    if (widget.active) return;
    if (_streak.tap(at)) {
      HapticFeedback.mediumImpact();
      widget.onFiveTaps();
    } else if (_streak.count >= 3) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    return Semantics(
      container: true,
      excludeSemantics: true,
      image: true,
      label: active
          ? 'Kalis Track, logo rose : session de test active'
          : 'Kalis Track',
      hint: active
          ? 'Appui long de 3 secondes : supprimer la session de test'
          : null,
      onTap: active ? null : () => _tap(widget.clock()),
      onLongPress: active ? widget.onHoldComplete : null,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _down,
        onPointerMove: _move,
        onPointerUp: _up,
        onPointerCancel: _cancel,
        child: AnimatedBuilder(
          animation: _hold,
          builder: (context, child) => Stack(
            alignment: Alignment.center,
            children: [
              child!,
              if (active && _hold.value > 0)
                SizedBox(
                  key: const ValueKey('dev-hold-ring'),
                  width: KalisLogo.headerSize - 2,
                  height: KalisLogo.headerSize - 2,
                  child: CircularProgressIndicator(
                    value: _hold.value,
                    strokeWidth: 3,
                    color: SL.text,
                    backgroundColor: SL.line,
                  ),
                ),
            ],
          ),
          child: KalisLogo(color: active ? kDevPink : SL.logo),
        ),
      ),
    );
  }
}

/// Étiquette « DEV » au bord droit de l'écran pendant la session de test.
/// Appui long : outils de test.
class DevBadge extends StatelessWidget {
  const DevBadge({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: DevSession.active,
    builder: (context, active, _) {
      if (!active) return const SizedBox.shrink();
      return Align(
        alignment: const Alignment(1, .3),
        child: Semantics(
          key: const ValueKey('dev-badge'),
          button: true,
          label: 'Session de test active',
          hint: 'Appui long : outils de test',
          onLongPress: openDevTools,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: openDevTools,
            child: Container(
              width: 24,
              height: 56,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xE6000000),
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(10),
                ),
                border: Border(
                  left: BorderSide(color: Color(0x80FFFFFF)),
                  top: BorderSide(color: Color(0x80FFFFFF)),
                  bottom: BorderSide(color: Color(0x80FFFFFF)),
                ),
              ),
              child: const RotatedBox(
                quarterTurns: 3,
                child: Text(
                  'DEV',
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    decoration: TextDecoration.none,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Message de la racine (changement de session), au-dessus de tout écran.
class SessionToast extends StatelessWidget {
  final String message;

  /// G5 : seconde ligne, plus discrète.
  final String? detail;

  /// G5 (D6.4) : Koach annonce le changement de session.
  final KoachPose pose;
  const SessionToast({
    super.key,
    required this.message,
    this.detail,
    this.pose = KoachPose.settings,
  });

  static const _background = Color(0xF0202020);

  /// Papier de Koach : le fond du message, opaque.
  static const _opaque = Color(0xFF202020);

  @override
  Widget build(BuildContext context) => MediaQuery.fromView(
    view: View.of(context),
    child: Builder(
      builder: (context) {
        final media = MediaQuery.of(context);
        const style = TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 14,
          height: 1.3,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.none,
          fontFamily: 'Roboto',
        );
        return Positioned(
          left: 24,
          right: 24,
          bottom: media.padding.bottom + 104,
          child: IgnorePointer(
            child: Semantics(
              liveRegion: true,
              child: Center(
                child: Container(
                  key: const ValueKey('session-toast'),
                  padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
                  decoration: BoxDecoration(
                    color: _background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Hors du thème de l'application : support sombre
                      // fixe, Koach blanc.
                      KoachView(
                        key: const ValueKey('session-toast-koach'),
                        pose: pose,
                        height: 48,
                        width: 44,
                        colors: KoachColors.onDark(_opaque),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(message, style: style),
                            if (detail != null)
                              Text(
                                detail!,
                                style: style.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFFCCCCCC),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// Ouvre les outils de test (session de test seulement).
void openDevTools() {
  if (!kDevBuild || !DevSession.active.value) return;
  final context = appNavigator.currentContext;
  if (context == null) return;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const DevToolsSheet(),
  );
}

/// Nom du fichier d'export de la session de test.
String devExportFileName(DateTime at) => backupFileName(at, test: true);

/// Outils de test : voyage dans le temps, export, suppression.
class DevToolsSheet extends StatelessWidget {
  const DevToolsSheet({super.key});

  Future<void> _go(BuildContext context, int days) async {
    Navigator.of(context).pop();
    await DevActions.travel(days);
  }

  Future<void> _pick(BuildContext context) async {
    final real = KalisClock.realNow();
    final today = DateTime(real.year, real.month, real.day);
    final now = KalisClock.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year, now.month, now.day),
      firstDate: today,
      lastDate: DateTime(today.year + 5, today.month, today.day),
      helpText: 'Date simulée',
    );
    if (picked == null || !context.mounted) return;
    final days = DateTime.utc(
      picked.year,
      picked.month,
      picked.day,
    ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
    await _go(context, days);
  }

  Future<void> _export(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    await store.flush();
    final at = KalisClock.now();
    final text = store.exportForFile(appVersion: kAppVersion, at: at);
    final result = await DevShare.shareJson(devExportFileName(at), text);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          result == 'shared'
              ? 'Export de la session de test prêt : choisis où l’envoyer.'
              : 'Export impossible ($result).',
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la session de test ?'),
        content: const Text(
          'Toutes les données de la session de test sont effacées. '
          'Ta session personnelle reste telle qu’elle était.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            key: const ValueKey('dev-delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    Navigator.of(context).pop();
    HapticFeedback.heavyImpact();
    await DevActions.delete();
  }

  @override
  Widget build(BuildContext context) {
    final offset = KalisClock.offsetDays;
    final created = DevSession.createdAt;
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        key: const ValueKey('dev-tools'),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Outils de test', style: text.titleLarge),
            const SizedBox(height: 6),
            Text(
              created == null
                  ? 'Session de test active. Ta session personnelle n’est pas touchée.'
                  : 'Session de test créée le ${longCivilDate(created)}. '
                        'Ta session personnelle n’est pas touchée.',
              style: TextStyle(color: SL.dim, height: 1.4),
            ),
            const SizedBox(height: 16),
            Semantics(
              container: true,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: SL.line),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date simulée',
                      style: TextStyle(color: SL.dim, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      longCivilDate(KalisClock.now()),
                      key: const ValueKey('dev-date'),
                      style: text.titleMedium,
                    ),
                    Text(
                      offset == 0
                          ? 'Aujourd’hui (heure réelle)'
                          : 'Aujourd’hui + $offset jour${offset > 1 ? 's' : ''}',
                      style: TextStyle(color: SL.dim, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('dev-plus-day'),
                  onPressed: () => _go(context, offset + 1),
                  icon: const Icon(Icons.today_outlined),
                  label: const Text('Avancer d’un jour'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('dev-plus-week'),
                  onPressed: () => _go(context, offset + 7),
                  icon: const Icon(Icons.date_range_outlined),
                  label: const Text('Avancer d’une semaine'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('dev-pick-date'),
                  onPressed: () => _pick(context),
                  icon: const Icon(Icons.edit_calendar_outlined),
                  label: const Text('Choisir une date'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('dev-today'),
                  onPressed: offset == 0 ? null : () => _go(context, 0),
                  icon: const Icon(Icons.restore),
                  label: const Text('Revenir à aujourd’hui'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              key: const ValueKey('dev-export'),
              onPressed: () => _export(context),
              icon: const Icon(Icons.ios_share),
              label: const Text('Exporter la session de test (JSON)'),
            ),
            const SizedBox(height: 8),
            const ListTile(
              enabled: false,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.fast_forward_outlined),
              title: Text('Simulateur de séances'),
              subtitle: Text('Arrive avec le lot G10'),
            ),
            ListTile(
              key: const ValueKey('dev-inspector'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.manage_search),
              title: const Text('Inspecteur du moteur'),
              subtitle: const Text(
                'Création du programme : Mon programme › Outils de test '
                '(et l’icône loupe pendant la création)',
              ),
              onTap: () {
                final nav = Navigator.of(context);
                nav.pop();
                nav.push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ProgramScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              key: const ValueKey('dev-delete'),
              style: TextButton.styleFrom(foregroundColor: SL.danger),
              onPressed: () => _delete(context),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Supprimer la session de test'),
            ),
            Text(
              'Raccourci : appui long de 3 secondes sur le logo rose.',
              style: TextStyle(color: SL.dim, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
