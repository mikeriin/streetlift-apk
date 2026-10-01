// G5 (D6.4, D6.5) : Koach parle — bulle, feuille du bas, message court,
// en-tête et rangée « Koach + contenu » des cartes existantes.
//
// Les répliques viennent de `kalis_koach` ([KoachDirector], [KoachTexts]) ;
// les écrans qui parlaient déjà gardent leurs textes (règles L13 déjà
// vérifiées) et les confient à Koach : pose choisie selon l'usage, bulle
// placée du côté du regard de la pose.
import 'package:flutter/material.dart';
import 'package:kalis_koach/kalis_koach.dart';

import '../app_theme.dart';
import 'koach_view.dart';

/// Directeur et textes partagés de l'application.
final KoachDirector koachDirector = KoachDirector();
const KoachTexts koachTexts = KoachTexts();

/// Graine stable des répliques : jour civil (une variante par jour, sans
/// stockage ni hasard).
int koachDaySeed(DateTime day) =>
    DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

/// Pose d'un usage, variée selon [occurrence] (kalis_koach).
KoachPose koachPose(KoachUsage usage, [int occurrence = 0]) =>
    koachPoseFor(usage, occurrence: occurrence);

/// Action d'une bulle.
class KoachBubbleAction {
  final String label;
  final VoidCallback onPressed;

  /// Action principale (bouton plein).
  final bool primary;
  final Key? key;
  const KoachBubbleAction(
    this.label,
    this.onPressed, {
    this.primary = false,
    this.key,
  });
}

/// Couleur de la bulle sur le support courant.
Color koachBubbleColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF2B2B2B)
    : Colors.white;

/// Koach et sa bulle : texte, actions, « Pourquoi ? » dépliable.
class KoachBubble extends StatefulWidget {
  final KoachPose pose;
  final String text;

  /// Explication dépliée par « Pourquoi ? » (Koach change alors de pose).
  final String? why;
  final KoachPose whyPose;
  final List<KoachBubbleAction> actions;
  final double koachHeight;
  final KoachFrame frame;

  /// Côté de la bulle ; par défaut celui conseillé par la pose.
  final KoachSide? side;

  /// Graine du clignement.
  final int seed;
  const KoachBubble({
    super.key,
    required this.pose,
    required this.text,
    this.why,
    this.whyPose = KoachPose.think,
    this.actions = const [],
    this.koachHeight = 72,
    this.frame = KoachFrame.pose,
    this.side,
    this.seed = 0,
  });

  /// Bulle d'une réplique de `kalis_koach` ; [onAction] relie chaque nature
  /// d'action à son effet (une action sans effet n'est pas montrée ;
  /// « Pourquoi ? » est géré par la bulle).
  factory KoachBubble.line(
    KoachLine line, {
    Key? key,
    Map<KoachActionKind, VoidCallback> onAction = const {},
    double koachHeight = 72,
    int seed = 0,
  }) {
    final why = koachDirector.explain(line);
    final actions = <KoachBubbleAction>[];
    for (final a in line.actions) {
      final run = onAction[a.kind];
      if (a.kind == KoachActionKind.why || run == null) continue;
      actions.add(
        KoachBubbleAction(
          koachTexts.action(a),
          run,
          primary: actions.isEmpty,
          key: ValueKey('koach-action-${a.kind.name}'),
        ),
      );
    }
    return KoachBubble(
      key: key,
      pose: line.pose,
      text: koachTexts.bubble(line),
      why: why == null ? null : koachTexts.render(why.messageKey, why.params),
      whyPose: why?.pose ?? KoachPose.think,
      koachHeight: koachHeight,
      seed: seed,
      actions: actions,
    );
  }

  @override
  State<KoachBubble> createState() => KoachBubbleState();
}

class KoachBubbleState extends State<KoachBubble> {
  bool _why = false;

  /// Explication dépliée (tests).
  bool get whyOpen => _why;

  void toggleWhy() => setState(() => _why = !_why);

  @override
  Widget build(BuildContext context) {
    final pose = _why ? widget.whyPose : widget.pose;
    final side = widget.side ?? widget.pose.info.bubbleSide;
    final koach = KoachView(
      key: const ValueKey('koach-bubble-view'),
      pose: pose,
      height: widget.koachHeight,
      frame: widget.frame,
      seed: widget.seed,
      // Largeur fixe : la bulle ne bouge pas quand Koach change de pose.
      width: widget.frame == KoachFrame.pose ? widget.koachHeight * .9 : null,
    );
    final koachLeft = side == KoachSide.right;
    final bubble = _bubble(context, koachLeft);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: koachLeft
          ? [koach, const SizedBox(width: 8), Expanded(child: bubble)]
          : [Expanded(child: bubble), const SizedBox(width: 8), koach],
    );
  }

  Widget _bubble(BuildContext context, bool koachLeft) {
    final tt = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    const r = Radius.circular(16), tip = Radius.circular(4);
    final why = widget.why;
    return Semantics(
      container: true,
      label: 'Koach',
      child: Container(
        key: const ValueKey('koach-bubble'),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: koachBubbleColor(context),
          // Coin pointu vers Koach : la bulle « sort » de sa bouche.
          borderRadius: BorderRadius.only(
            topLeft: r,
            topRight: r,
            bottomLeft: koachLeft ? tip : r,
            bottomRight: koachLeft ? r : tip,
          ),
          border: dark ? null : Border.all(color: SL.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.text,
              key: const ValueKey('koach-bubble-text'),
              style: tt.bodyMedium?.copyWith(color: SL.text, height: 1.3),
            ),
            if (why != null)
              AnimatedSize(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                alignment: Alignment.topCenter,
                child: _why
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          why,
                          key: const ValueKey('koach-why-text'),
                          style: tt.bodySmall?.copyWith(
                            color: SL.dim,
                            height: 1.35,
                          ),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            if (why != null || widget.actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.end,
                  children: [
                    if (why != null)
                      TextButton(
                        key: const ValueKey('koach-why'),
                        onPressed: toggleWhy,
                        child: Text(_why ? 'Compris' : 'Pourquoi ?'),
                      ),
                    for (final a in widget.actions)
                      a.primary
                          ? FilledButton(
                              key: a.key,
                              onPressed: a.onPressed,
                              child: Text(a.label),
                            )
                          : OutlinedButton(
                              key: a.key,
                              onPressed: a.onPressed,
                              child: Text(a.label),
                            ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Koach à côté d'un contenu existant (cartes qui parlaient déjà : le
/// contenu devient ce que dit Koach).
class KoachSays extends StatelessWidget {
  final KoachPose pose;
  final Widget child;
  final double koachHeight;
  const KoachSays({
    super.key,
    required this.pose,
    required this.child,
    this.koachHeight = 56,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: KoachView(
          key: const ValueKey('koach-says-view'),
          pose: pose,
          height: koachHeight,
          width: koachHeight * .9,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(child: child),
    ],
  );
}

/// En-tête « KOACH · … » d'une carte, avec Koach en petit.
class KoachHeader extends StatelessWidget {
  final String text;
  final KoachPose pose;
  final Color? color;
  const KoachHeader(this.text, {super.key, required this.pose, this.color});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      KoachView(
        key: const ValueKey('koach-header-view'),
        pose: pose,
        height: 40,
        width: 36,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            color: color ?? SL.dim,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ),
    ],
  );
}

/// Feuille du bas où Koach parle (explication, demande).
Future<T?> showKoachSheet<T>(
  BuildContext context, {
  required KoachPose pose,
  required String text,
  String? title,
  String? why,
  List<KoachBubbleAction> actions = const [],
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) => KoachSurface(
    color:
        Theme.of(context).bottomSheetTheme.backgroundColor ??
        Theme.of(context).colorScheme.surfaceContainerLow,
    child: SingleChildScrollView(
    key: const ValueKey('koach-sheet'),
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
        KoachBubble(
          pose: pose,
          text: text,
          why: why,
          koachHeight: 120,
          actions: actions.isEmpty
              ? [
                  KoachBubbleAction(
                    'OK',
                    () => Navigator.of(context).pop(),
                    primary: true,
                    key: const ValueKey('koach-sheet-ok'),
                  ),
                ]
              : actions,
        ),
      ],
    ),
  ),
  ),
);

/// Couleurs d'un message court (lues avant une attente asynchrone).
@immutable
class KoachToastColors {
  final Color background, text;
  const KoachToastColors(this.background, this.text);

  factory KoachToastColors.of(BuildContext context) {
    final theme = Theme.of(context);
    return KoachToastColors(
      theme.snackBarTheme.backgroundColor ?? theme.colorScheme.inverseSurface,
      theme.snackBarTheme.contentTextStyle?.color ??
          theme.colorScheme.onInverseSurface,
    );
  }
}

/// Message court de Koach (SnackBar avec Koach en petit). Avec un grand
/// texte ([large]), le texte garde toute la largeur : Koach s'efface.
SnackBar koachSnackBar(
  KoachToastColors colors,
  String text, {
  KoachPose pose = KoachPose.thumbsUp,
  bool large = false,
}) => SnackBar(
  key: const ValueKey('koach-toast'),
  content: Row(
    children: [
      if (!large) ...[
        KoachView(
          pose: pose,
          height: 34,
          width: 30,
          colors: KoachColors.onColor(colors.background),
        ),
        const SizedBox(width: 10),
      ],
      Expanded(
        child: Text(text, style: TextStyle(color: colors.text)),
      ),
    ],
  ),
);

/// Grand texte : au-delà de 130 %, les messages courts n'ont pas Koach.
bool koachLargeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(10) > 13;

/// Message court de Koach (remplace un SnackBar).
void showKoachToast(
  BuildContext context,
  String text, {
  KoachPose pose = KoachPose.thumbsUp,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.showSnackBar(
    koachSnackBar(
      KoachToastColors.of(context),
      text,
      pose: pose,
      large: koachLargeText(context),
    ),
  );
}
