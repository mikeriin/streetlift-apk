import 'package:flutter/material.dart';

import 'builder_screen.dart';
import 'exercise_screens.dart';
import 'app_theme.dart';
import 'ui.dart';
import 'levelup.dart';
import 'session_screen.dart';
import 'store.dart';
import 'store_widget.dart';
import 'wod_models.dart';
import 'wod_preview.dart';
import 'wod_catalog.dart';
import 'wod_screen.dart' show WodRunScreen;
import 'wod_store.dart';

/// Onglet Arsenal — séances à la carte et WODs à débloquer. Même grammaire que l'accueil.
class ArsenalScreen extends StatelessWidget {
  const ArsenalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // L6 : différé tant que l'onglet est masqué (voir store_widget.dart).
    return StoreBuilder(
      builder: (context) {
        final sessions = store.customSessions;
        final wods = store.wods;
        final unlockedWods = [
          for (final w in wods)
            if (store.unlocked(w)) w,
        ]..sort(
          (a, b) =>
              a.level != b.level
                  ? a.level.compareTo(b.level)
                  : a.name.compareTo(b.name),
        );
        return KScreen(
          appBar: const KTopBar(),
          body: KList(
            padding: KSpace.content,
            children: [
              const KPageIntro(
                'Arsenal',
                'Tes séances. Tes défis. Ton rythme.',
              ),
              const _Credits(),
              KActionRow(
                minButtonWidth: 160,
                children: [
                  FilledButton.icon(
                    onPressed: () => newCustomSession(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Nouvelle séance'),
                  ),
                ],
              ),
              KMenuTile(
                icon: Icons.menu_book_outlined,
                title: 'Exercices',
                subtitle: 'Fiches, démonstrations, muscles et progressions',
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ExerciseLibraryScreen(),
                      ),
                    ),
              ),
              KSection(
                'Mes séances',
                subtitle:
                    sessions.isEmpty
                        ? 'Aucune séance enregistrée'
                        : '${sessions.length} séance${sessions.length > 1 ? 's' : ''} personnelle${sessions.length > 1 ? 's' : ''}',
              ),
              if (sessions.isEmpty)
                _EmptyTile(
                  title: 'Ta première séance',
                  action: 'Créer une séance',
                  text:
                      'Choisis tes exercices, leur mode d’exécution et les temps de repos.',
                  onTap: () => newCustomSession(context),
                )
              else
                for (final s in sessions) _SessionTile(session: s),
              _SectionHeader(
                title: 'Mes WODs',
                actionLabel: 'Catalogue',
                actionIcon: Icons.grid_view_rounded,
                onAction:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WodCatalogScreen(),
                      ),
                    ),
              ),
              if (unlockedWods.isEmpty)
                _EmptyTile(
                  title: 'Ton premier WOD',
                  action: 'Ouvrir le catalogue',
                  text:
                      'Achète tes WODs avec les crédits gagnés en progressant. Chaque WOD reste ensuite disponible dans ton arsenal.',
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WodCatalogScreen(),
                        ),
                      ),
                )
              else
                for (final w in unlockedWods) WodTile(wod: w),
            ],
          ),
        );
      },
    );
  }
}

// ----------------------------- bannière ---------------------------------

/// Abonné au store : le solde suit un passage de niveau alors que la bannière
/// est instanciée en `const`.
class _Credits extends StoreWidget {
  const _Credits();

  /// Ce que le solde permet : prochain objectif de la liste d'envies, sinon
  /// l'essai du jour, sinon le rappel de la vitrine.
  static String _subtitle() {
    final target = store.wishTarget;
    if (target != null) {
      final missing = store.missingFor(target);
      return missing == 0
          ? '« ${target.name} » est à ta portée'
          : 'Plus que ${creditsLabel(missing)} pour « ${target.name} »';
    }
    if (store.credits < 0) {
      return 'Tes prochains gains comblent d’abord ce déficit';
    }
    final trial = store.trialWod;
    if (trial != null && !store.unlocked(trial)) {
      return 'Essai du jour offert : « ${trial.name} »';
    }
    return 'À utiliser dans le catalogue';
  }

  @override
  Widget build(BuildContext context) => KMenuTile(
    icon: Icons.toll_rounded,
    title:
        store.credits >= 0
            ? '${store.credits} crédit${store.credits > 1 ? 's' : ''} WOD'
            : 'WOD : ${creditDeficitLabel(store.credits)}',
    subtitle: _subtitle(),
    onTap:
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WodCatalogScreen()),
        ),
  );
}

// ----------------------------- sections ---------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    this.actionIcon = Icons.add,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) => KSection(
    title,
    actionLabel: actionLabel,
    actionIcon: actionIcon,
    onAction: onAction,
  );
}

class _EmptyTile extends StatelessWidget {
  final String text, title, action;
  final VoidCallback onTap;
  const _EmptyTile({
    required this.text,
    required this.onTap,
    required this.title,
    required this.action,
  });
  @override
  Widget build(BuildContext context) => KEmpty(
    icon: Icons.add_circle_outline,
    title: title,
    message: text,
    action: action,
    onAction: onTap,
  );
}

// ----------------------------- tuiles -----------------------------------
// Tap = ouvrir · appui long = actions (même convention que l'accueil).

class _Tile extends StatelessWidget {
  final Widget badge;
  final String title;
  final String subtitle;
  final String? tag;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _Tile({
    required this.badge,
    required this.title,
    required this.subtitle,
    this.tag,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) => KCard(
    onTap: onTap,
    onLongPress: onLongPress,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 36, height: 36, child: badge),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (tag != null) ...[
                const SizedBox(height: 4),
                // Séance faite : validation en vert ; prix et record : accent.
                KBadge(
                  tag!.toLowerCase(),
                  color: tag!.contains('FAIT') ? SL.success : SL.accent,
                ),
              ],
            ],
          ),
        ),
        IconButton(
          tooltip: 'Actions pour $title',
          onPressed: onLongPress,
          icon: const Icon(Icons.more_vert),
        ),
      ],
    ),
  );
}

Widget _badge(Color c, Widget child) => Container(
  alignment: Alignment.center,
  decoration: BoxDecoration(
    color: c.withValues(alpha: 0.18),
    borderRadius: BorderRadius.circular(22),
  ),
  child: child,
);

/// Feuille d'actions commune (Lancer / Modifier / Dupliquer / Supprimer).
Future<void> _actions(
  BuildContext context,
  String name, {
  VoidCallback? preview,
  required VoidCallback run,
  required VoidCallback edit,
  required VoidCallback dup,
  required VoidCallback del,
}) {
  return showModalBottomSheet(
    context: context,
    builder:
        (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              if (preview != null)
                ListTile(
                  leading: Icon(Icons.insights, color: SL.dim),
                  title: const Text('Aperçu (volume, muscles)'),
                  onTap: () {
                    Navigator.pop(ctx);
                    preview();
                  },
                ),
              ListTile(
                leading: Icon(Icons.play_arrow_rounded, color: SL.accent),
                title: const Text('Lancer'),
                onTap: () {
                  Navigator.pop(ctx);
                  run();
                },
              ),
              ListTile(
                leading: Icon(Icons.edit_outlined, color: SL.dim),
                title: const Text('Modifier'),
                onTap: () {
                  Navigator.pop(ctx);
                  edit();
                },
              ),
              ListTile(
                leading: Icon(Icons.copy_outlined, color: SL.dim),
                title: const Text('Dupliquer'),
                onTap: () {
                  Navigator.pop(ctx);
                  dup();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: SL.danger),
                title: Text('Supprimer', style: TextStyle(color: SL.danger)),
                onTap: () {
                  Navigator.pop(ctx);
                  del();
                },
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
  );
}

Future<void> _confirmDelete(
  BuildContext context,
  String what,
  VoidCallback onConfirm,
) => showDialog(
  context: context,
  builder:
      (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('$what Action irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: SL.alert,
              foregroundColor: KPalette.light,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
);

class _SessionTile extends StatelessWidget {
  final CustomSession session;
  const _SessionTile({required this.session});

  Future<void> _run(BuildContext context) async {
    if (session.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cette séance est vide : ajoute des exercices.'),
        ),
      );
      return;
    }
    if (store.isDone(0, int.parse(session.id))) {
      final repeat = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Séance déjà terminée'),
              content: const Text(
                'Recommencer conserve le résultat précédent dans STATS → Historique et prépare de nouvelles séries.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Consulter'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Nouvelle séance'),
                ),
              ],
            ),
      );
      if (repeat == null || !context.mounted) return;
      if (repeat) store.restartCustomSession(session);
    }
    if (!context.mounted) return;
    final wp = session.toWeekPlan();
    // Le bilan s'affiche depuis la page de fin de séance ; au retour, le
    // navigateur (et non la tuile, reconstruite entre-temps) vérifie un
    // éventuel niveau restant.
    final nav = Navigator.of(context);
    final root = nav.context;
    await nav.push(
      MaterialPageRoute(
        builder: (_) => SessionScreen(week: wp, day: wp.days.first),
      ),
    );
    if (root.mounted) checkLevelUp(root);
  }

  void _edit(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(
      builder:
          (_) =>
              SessionEditor(session: CustomSession.fromJson(session.toJson())),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final s = session;
    final modes = s.items
        .map((e) => modeById(e.mode).label)
        .toSet()
        .join(' · ');
    final done = store.isDone(0, int.tryParse(s.id) ?? -1);
    return _Tile(
      badge: _badge(
        SL.accent,
        Text(
          '${s.items.length}',
          style: TextStyle(
            color: SL.accent,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      title: s.name,
      subtitle:
          '${s.items.length} exercice${s.items.length > 1 ? 's' : ''}${modes.isEmpty ? '' : ' · $modes'}',
      tag:
          done
              ? 'FAIT ✓'
              : store.inProgress('S0-J${s.id}')
              ? 'EN COURS'
              : null,
      onTap: () => _run(context),
      onLongPress:
          () => _actions(
            context,
            s.name,
            run: () => _run(context),
            edit: () => _edit(context),
            dup: () => store.duplicateSession(s),
            del:
                () => _confirmDelete(
                  context,
                  '« ${s.name} » et son historique seront effacés.',
                  () => store.deleteSession(s),
                ),
          ),
    );
  }
}

class WodTile extends StatelessWidget {
  final Wod wod;
  const WodTile({super.key, required this.wod});

  void _run(BuildContext context) {
    if (!store.canRun(wod)) {
      _preview(context);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WodRunScreen(wodId: wod.id)),
    );
  }

  void _preview(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => WodPreviewScreen(wodId: wod.id)),
  );

  void _actions(BuildContext context) => showModalBottomSheet(
    context: context,
    builder:
        (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    wod.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.insights, color: SL.dim),
                title: const Text('Aperçu : volume, durée et muscles'),
                onTap: () {
                  Navigator.pop(ctx);
                  _preview(context);
                },
              ),
              if (store.canRun(wod))
                ListTile(
                  leading: Icon(Icons.play_arrow_rounded, color: SL.accent),
                  title: Text(
                    store.unlocked(wod) ? 'Lancer' : 'Essayer · offert',
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _run(context);
                  },
                ),
              if (store.isCatalog(wod) && !store.unlocked(wod))
                ListTile(
                  leading: Icon(
                    store.wished(wod)
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: SL.accent,
                  ),
                  title: Text(
                    store.wished(wod)
                        ? 'Retirer de ma liste d\u2019envies'
                        : 'Ajouter à ma liste d\u2019envies',
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    store.toggleWish(wod);
                  },
                ),
              const SizedBox(height: 4),
            ],
          ),
        ),
  );

  @override
  Widget build(BuildContext context) {
    final w = wod;
    final state = storeStateOf(w);
    final owned = state == StoreState.owned;
    final estimate = store.wodEstimate(w);
    final sub =
        '${w.typeLabel} · ${estimate.durationLabel}${owned && w.lines.isNotEmpty ? ' · ${w.lines.take(2).join(' · ')}' : ''}';
    return KCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      radius: 20,
      onTap: () => _run(context),
      onLongPress: () => _actions(context),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 70,
            child: WodCover(
              wod: w,
              radius: 12,
              dim: state == StoreState.locked,
              child:
                  owned
                      ? null
                      : Center(
                        child: Icon(
                          state == StoreState.trial
                              ? Icons.bolt_rounded
                              : Icons.lock_outline_rounded,
                          color: KPalette.light,
                          size: 18,
                        ),
                      ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        w.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: SL.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: TierChevrons(w.level),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: SL.dim, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(child: WodPriceTag(wod: w)),
                    if (store.wished(w)) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.favorite_rounded, size: 14, color: SL.accent),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Actions pour ${w.name}',
            icon: Icon(Icons.more_vert, color: SL.dim),
            onPressed: () => _actions(context),
          ),
        ],
      ),
    );
  }
}
