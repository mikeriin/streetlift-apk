// UI1 (refonte UI) : composants de la zone Programme qui manquent au kit,
// à promouvoir dans `lib/kit/` par UI5 (cahier §7.2) :
// - [showProgramSheet] : feuille de contenu (poignée, titre, résumé,
//   contenu libre qui défile) pour ce qui n'est ni une feuille d'actions ni
//   une feuille de liste (détail d'une semaine, résumé d'un jour de repos,
//   explication du programme, changement de Koach, feuilles de la création) ;
// - [ProgramDayRow] : ligne de jour de l'accueil et de la feuille de la
//   semaine. `KDayRow` (kit) ne porte ni « en cours » ni « reprise » (écrits
//   et lus par TalkBack, L5), ni le bouton ⓘ à côté de l'état (R7).
import 'package:flutter/material.dart';

import '../../koach/koach_view.dart' show KoachSurface;
import '../../ui.dart';

AnimationStyle _sheetMotion(BuildContext context) => AnimationStyle(
  duration: KMotion.standard.durationIn(context),
  reverseDuration: KMotion.fast.durationIn(context),
  curve: KMotion.standard.curve,
);

/// En-tête des feuilles de la zone : poignée, titre (`titreSeance`, comme
/// les feuilles du kit), résumé.
class ProgramSheetHeader extends StatelessWidget {
  final String? title, subtitle;
  const ProgramSheetHeader({super.key, this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: KSpacing.s12),
        Center(
          child: Container(
            width: KSize.handleWidth,
            height: KSize.handleHeight,
            decoration: ShapeDecoration(color: k.texte3, shape: KRadius.pill),
          ),
        ),
        const SizedBox(height: KSpacing.s12),
        if (title != null)
          Semantics(
            header: true,
            child: Text(
              title!,
              style: KType.titreSeance.copyWith(color: k.texte),
            ),
          ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: KSpacing.s4),
            child: Text(
              subtitle!,
              style: KType.detail.copyWith(color: k.texte2),
            ),
          ),
        if (title != null || subtitle != null)
          const SizedBox(height: KSpacing.s12),
      ],
    );
  }
}

/// Feuille de contenu : poignée, titre et résumé facultatifs, contenu qui
/// défile (marges de page, écart [gap] entre les éléments). [draggable] :
/// feuille haute qu'on agrandit en la tirant (contenu long). Fond
/// `surface`, rayon des cartes en haut (thème) ; Koach posé dessus prend sa
/// couleur pour papier.
Future<T?> showProgramSheet<T>(
  BuildContext context, {
  String? title,
  String? subtitle,
  required List<Widget> Function(BuildContext context) children,
  bool draggable = false,
  double gap = KSpacing.s12,
  Key? listKey,
}) {
  final k = KTokens.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: k.surface,
    sheetAnimationStyle: _sheetMotion(context),
    constraints: draggable
        ? null
        : BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .9),
    builder: (ctx) {
      Widget list(ScrollController? controller) {
        final items = children(ctx);
        return ListView(
          key: listKey,
          controller: controller,
          shrinkWrap: !draggable,
          padding: EdgeInsets.only(
            left: KSpacing.page,
            right: KSpacing.page,
            bottom: KSpacing.s24 + MediaQuery.paddingOf(ctx).bottom,
          ),
          children: [
            ProgramSheetHeader(title: title, subtitle: subtitle),
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) SizedBox(height: gap),
              items[i],
            ],
          ],
        );
      }

      return KoachSurface(
        color: KTokens.of(ctx).surface,
        child: draggable
            ? DraggableScrollableSheet(
                expand: false,
                initialChildSize: .7,
                maxChildSize: .94,
                builder: (_, controller) => list(controller),
              )
            : list(null),
      );
    },
  );
}

/// État d'une journée du programme.
enum ProgramDayStatus { todo, done, inProgress, resume }

/// Ligne de jour : numéro, titre (capitales selon U3, jamais coupé), détail
/// facultatif, état écrit (« En cours », « Reprise ») et icône ; appui :
/// ouvrir ; appui long : résumé ; [onInfo] : bouton ⓘ, équivalent visible
/// de l'appui long (R7). Rayon des menus (20), fond `surface`.
class ProgramDayRow extends StatelessWidget {
  final int day;
  final String title;
  final String? detail;
  final ProgramDayStatus status;
  final VoidCallback? onTap, onLongPress, onInfo;

  /// Fond de la ligne (`surface` sur la page, `haute` dans une feuille).
  final Color? color;
  const ProgramDayRow({
    super.key,
    required this.day,
    required this.title,
    this.detail,
    this.status = ProgramDayStatus.todo,
    this.onTap,
    this.onLongPress,
    this.onInfo,
    this.color,
  });

  String get statusLabel => switch (status) {
    ProgramDayStatus.done => 'Séance effectuée',
    ProgramDayStatus.inProgress => 'Séance en cours',
    ProgramDayStatus.resume => 'Reprise : séance neutre',
    ProgramDayStatus.todo => 'Séance à faire',
  };

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final done = status == ProgramDayStatus.done;
    final (IconData icon, Color ink) = switch (status) {
      ProgramDayStatus.done => (Icons.check_circle_rounded, k.validation),
      ProgramDayStatus.inProgress => (Icons.timelapse_rounded, k.encre),
      ProgramDayStatus.resume => (Icons.fast_forward_rounded, k.texte2),
      ProgramDayStatus.todo => (Icons.radio_button_unchecked_rounded, k.texte3),
    };
    final written = switch (status) {
      ProgramDayStatus.inProgress => 'En cours',
      ProgramDayStatus.resume => 'Reprise',
      _ => null,
    };
    final statusIcon = Icon(
      icon,
      key: ValueKey('day-status-$day'),
      semanticLabel: statusLabel,
      size: KSize.icon,
      color: ink,
    );
    final main = Semantics(
      button: true,
      label: 'Jour $day · $title. $statusLabel',
      value: detail,
      onTap: onTap,
      onLongPress: onLongPress,
      onTapHint: done
          ? 'Afficher l’historique'
          : status == ProgramDayStatus.inProgress
          ? 'Reprendre la séance'
          : 'Ouvrir la séance',
      onLongPressHint: onLongPress == null ? null : 'Afficher le résumé',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: KSize.search),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              KSpacing.s14,
              KSpacing.s8,
              onInfo == null ? KSpacing.s14 : KSpacing.s4,
              KSpacing.s8,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: KSpacing.s32,
                  child: Text(
                    'J$day',
                    style: KType.chiffrePetit.copyWith(color: k.texte2),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        k.title(title),
                        style: k.titleStyle(
                          KType.ligneJour.copyWith(
                            color: done ? k.texte2 : k.texte,
                          ),
                        ),
                      ),
                      if (detail != null)
                        Text(
                          detail!,
                          style: KType.detail.copyWith(color: k.texte2),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: KSpacing.s8),
                if (written != null) ...[
                  Text(
                    written,
                    key: ValueKey(
                      status == ProgramDayStatus.inProgress
                          ? 'day-in-progress-$day'
                          : 'day-resume-$day',
                    ),
                    style: KType.micro.copyWith(color: ink),
                  ),
                  const SizedBox(width: KSpacing.s4),
                ],
                statusIcon,
              ],
            ),
          ),
        ),
      ),
    );
    return Material(
      color: color ?? k.surface,
      shape: KRadius.menuShape,
      clipBehavior: Clip.antiAlias,
      child: onInfo == null
          ? main
          : Row(
              children: [
                Expanded(child: main),
                IconButton(
                  key: ValueKey('day-info-$day'),
                  tooltip: 'Résumé du jour $day',
                  onPressed: onInfo,
                  icon: Icon(
                    Icons.info_outline_rounded,
                    size: KSize.iconSmall,
                    color: k.texte2,
                  ),
                ),
                const SizedBox(width: KSpacing.s4),
              ],
            ),
    );
  }
}

/// Ligne d'un changement avec son « Pourquoi ? » dépliable (feuilles de
/// Koach : ce qui change, ce qui a bougé). Cible de 48 dp, état lu par
/// TalkBack ; se range dans un `KMenuGroup`.
class WhyTile extends StatefulWidget {
  final String title;
  final List<String> reasons;
  const WhyTile({super.key, required this.title, required this.reasons});

  @override
  State<WhyTile> createState() => _WhyTileState();
}

class _WhyTileState extends State<WhyTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final can = widget.reasons.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: can,
          expanded: can ? _open : null,
          child: InkWell(
            onTap: can ? () => setState(() => _open = !_open) : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: KSize.target),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KSpacing.s16,
                  vertical: KSpacing.s8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: KType.corps.copyWith(color: k.texte),
                          ),
                          if (can)
                            Text(
                              'Pourquoi ?',
                              style: KType.detail.copyWith(color: k.texte2),
                            ),
                        ],
                      ),
                    ),
                    if (can)
                      AnimatedRotation(
                        turns: _open ? .5 : 0,
                        duration: KMotion.fast.durationIn(context),
                        curve: KMotion.fast.curve,
                        child: Icon(
                          Icons.expand_more_rounded,
                          size: KSize.icon,
                          color: k.texte2,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.only(
              left: KSpacing.s16,
              right: KSpacing.s16,
              bottom: KSpacing.s12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final r in widget.reasons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: KSpacing.s4),
                    child: Text(
                      r,
                      style: KType.corps.copyWith(color: k.texte2),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Feuille de liste du kit (`KListSheet`) ouverte sur l'élément [initial]
/// (choix parmi 40 semaines : la semaine affichée est visible d'emblée ;
/// `showKListSheet` s'ouvre toujours en haut de la liste). Rend l'index
/// choisi, null sans choix.
Future<int?> showProgramListSheet(
  BuildContext context, {
  required String title,
  String? summary,
  required List<KListItem> items,
  int initial = 0,
}) {
  // Hauteur d'une ligne d'une ligne de détail : 56 dp et 4 d'écart ; on
  // ouvre deux lignes au-dessus de l'élément pour le montrer avec son
  // voisinage.
  final controller = ScrollController(
    initialScrollOffset:
        (KSize.primary + KSpacing.s4) * (initial > 2 ? initial - 2 : 0),
  );
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    sheetAnimationStyle: _sheetMotion(context),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * .85,
    ),
    builder: (ctx) => KListSheet(
      title: title,
      summary: summary,
      items: items,
      controller: controller,
      onSelected: (i) => Navigator.pop(ctx, i),
    ),
  ).whenComplete(controller.dispose);
}
