// L11 (KT-058 à KT-064) — écrans de l'adaptation au jour le jour :
// « J'ai seulement N minutes » (aperçu des différences), échange d'un
// exercice et changement de lieu, bandeau de séance (reprise, maladie,
// allègement), carte de l'accueil (pause, plan qui glisse, assiduité,
// plateau, prudence), écran « Adaptation au jour le jour » (mode
// d'autonomie, vacances, maladie, historique) et difficulté globale de fin
// de séance. Contrat : docs/CONTRAT_L11.md.
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'koach_adapt.dart';
import 'models.dart';
import 'program_generator.dart' show GenCatalog, GenExercise;
import 'store.dart';
import 'ui.dart';

String _min(double seconds) => '≈ ${(seconds / 60).round()} min';

void _snack(BuildContext context, String text, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: Duration(seconds: action == null ? 3 : 6),
        content: Text(text),
        action: action,
      ),
    );
}

Future<GenCatalog?> _catalog(BuildContext context) async {
  try {
    return await store.adaptCatalog();
  } catch (_) {
    if (context.mounted) {
      _snack(context, 'Base d’exercices illisible : échange impossible.');
    }
    return null;
  }
}

// ============================================ « J'ai seulement N minutes »

/// Choix de la durée disponible puis aperçu des différences (KT-058).
/// Renvoie vrai si la séance a changé.
Future<bool> showCompressSheet(
  BuildContext context,
  int week,
  DayPlan base,
) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _CompressSheet(week: week, base: base),
  );
  return changed ?? false;
}

class _CompressSheet extends StatefulWidget {
  final int week;
  final DayPlan base;
  const _CompressSheet({required this.week, required this.base});

  @override
  State<_CompressSheet> createState() => _CompressSheetState();
}

class _CompressSheetState extends State<_CompressSheet> {
  static const _choices = [15, 20, 30, 45, 60, 75, 90];
  int? _minutes;

  @override
  Widget build(BuildContext context) {
    final week = widget.week, base = widget.base;
    final current = store.adaptCompressed(week, base.j);
    final plan =
        _minutes == null
            ? null
            : store.adaptCompressPreview(week, base, _minutes!);
    final names = {
      for (final e in base.exercises) e.id: store.splitName(e.name).$1,
    };
    final lines = <String>[];
    if (plan != null && !plan.unchanged) {
      if (plan.warmup) lines.add('Échauffement ramené à 3 minutes.');
      for (final e in base.exercises) {
        final n = plan.sets[e.id];
        if (n != null) {
          lines.add(
            '${names[e.id]} : ${store.setCount(e)} → $n série${n > 1 ? 's' : ''}'
            '${e.prevention ? ' (prévention gardée)' : ''}.',
          );
        }
      }
      for (final p in plan.pairs) {
        lines.add('${names[p.$1]} + ${names[p.$2]} : enchaînés.');
      }
      for (final id in plan.removed) {
        lines.add('${names[id]} : retiré.');
      }
    }
    return SingleChildScrollView(
      key: const ValueKey('adapt-compress-sheet'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'J’ai seulement…',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Koach garde les mouvements principaux (au moins 2/3 de leurs '
            'séries) et la prévention (1 série), enchaîne les accessoires et '
            'retire les moins prioritaires.',
            style: TextStyle(color: SL.dim),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in _choices)
                ChoiceChip(
                  key: ValueKey('adapt-minutes-$m'),
                  label: Text('$m min'),
                  selected: _minutes == m,
                  onSelected: (_) => setState(() => _minutes = m),
                ),
            ],
          ),
          if (plan != null) ...[
            const SizedBox(height: 16),
            if (plan.unchanged)
              Text(
                'La séance tient déjà en $_minutes minutes '
                '(${_min(plan.before)}) : rien à changer.',
              )
            else ...[
              Text(
                'Durée estimée : ${_min(plan.before)} → ${_min(plan.after)}',
                key: const ValueKey('adapt-compress-duration'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (!plan.feasible)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Au plus court, en gardant 2/3 des séries principales : '
                    '${_min(plan.after)}.',
                  ),
                ),
              const SizedBox(height: 8),
              for (final l in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $l'),
                ),
            ],
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              if (current != null)
                OutlinedButton(
                  key: const ValueKey('adapt-compress-clear'),
                  onPressed: () {
                    store.clearCompression(week, base);
                    Navigator.pop(context, true);
                  },
                  child: const Text('Séance complète'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Fermer'),
              ),
              if (plan != null && !plan.unchanged)
                FilledButton(
                  key: const ValueKey('adapt-compress-apply'),
                  onPressed: () {
                    store.applyCompression(week, base, plan);
                    Navigator.pop(context, true);
                  },
                  child: const Text('Appliquer'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ================================================= échange d'exercice

/// Échange d'un exercice de la séance (KT-059). Renvoie vrai si la séance
/// a changé.
Future<bool> showSwapSheet(
  BuildContext context,
  int week,
  DayPlan base,
  Exercise exercise,
) async {
  final catalog = await _catalog(context);
  if (catalog == null || !context.mounted) return false;
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder:
        (_) => _SwapSheet(
          week: week,
          base: base,
          exercise: exercise,
          catalog: catalog,
        ),
  );
  return changed ?? false;
}

class _SwapSheet extends StatefulWidget {
  final int week;
  final DayPlan base;
  final Exercise exercise;
  final GenCatalog catalog;
  const _SwapSheet({
    required this.week,
    required this.base,
    required this.exercise,
    required this.catalog,
  });

  @override
  State<_SwapSheet> createState() => _SwapSheetState();
}

class _SwapSheetState extends State<_SwapSheet> {
  String _motive = 'busy';

  @override
  Widget build(BuildContext context) {
    final e = widget.exercise;
    final original =
        widget.base.exercises
            .where((x) => x.id == e.id.split('~').first)
            .firstOrNull ??
        e;
    final candidates = store.adaptSwapCandidates(
      widget.catalog,
      original,
      motive: _motive,
    );
    final known = store.adaptPackOf(original, widget.catalog) != null;
    return SingleChildScrollView(
      key: const ValueKey('adapt-swap-sheet'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Échanger · ${store.splitName(original.name).$1}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in kSwapMotives)
                ChoiceChip(
                  key: ValueKey('adapt-motive-${m.$1}'),
                  label: Text(m.$2),
                  selected: _motive == m.$1,
                  onSelected: (_) => setState(() => _motive = m.$1),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!known)
            const Text(
              'Exercice absent de la base : aucune proposition automatique.',
            )
          else if (candidates.isEmpty)
            const Text(
              'Aucun exercice équivalent avec ton matériel (même type de '
              'mouvement, difficulté proche).',
            )
          else ...[
            Text(
              'Même type de mouvement, difficulté proche, matériel disponible'
              '${_motive == 'pain' ? ', contrainte articulaire égale ou moindre' : ''}. '
              'La première série sert de calibrage.',
              style: TextStyle(color: SL.dim),
            ),
            for (final (i, c) in candidates.indexed)
              ListTile(
                key: ValueKey('adapt-swap-${c.id}'),
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(c.name),
                subtitle: Text(
                  'Difficulté ${c.difficulty}/10'
                  '${c.materiel.isEmpty || c.materiel.every((m) => m == 'aucun') ? ' · sans matériel' : ''}',
                ),
                onTap: () {
                  store.applySwap(
                    widget.week,
                    widget.base,
                    original,
                    c,
                    _motive,
                    widget.catalog,
                  );
                  Navigator.pop(context, true);
                },
              ),
          ],
          if (_motive == 'pain')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Une douleur qui persiste relève d’un professionnel de santé.',
                style: TextStyle(color: SL.dim),
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            children: [
              if (e.id.contains('~'))
                OutlinedButton(
                  key: const ValueKey('adapt-swap-revert'),
                  onPressed: () {
                    store.revertSwap(
                      widget.week,
                      widget.base,
                      e.id.split('~').first,
                    );
                    Navigator.pop(context, true);
                  },
                  child: const Text('Exercice d’origine'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Fermer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Choix d'un exercice de la séance à échanger.
Future<bool> pickAndSwap(BuildContext context, int week, DayPlan base) async {
  final day = store.sessionDay(week, base);
  final key = store.sessionKey(week, base.j);
  final candidates = [
    for (final e in day.exercises)
      if (!(store.logs[key]?.ex[e.id]?.sets.any((s) => s.done) ?? false)) e,
  ];
  final picked = await showModalBottomSheet<Exercise>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder:
        (context) => ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Quel exercice échanger ?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
            if (candidates.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Tous les exercices sont commencés : un échange se fait '
                  'avant la première série.',
                ),
              ),
            for (final e in candidates)
              ListTile(
                title: Text(store.splitName(e.name).$1),
                subtitle: e.id.contains('~') ? const Text('Échangé') : null,
                onTap: () => Navigator.pop(context, e),
              ),
          ],
        ),
  );
  if (picked == null || !context.mounted) return false;
  return showSwapSheet(context, week, base, picked);
}

/// Changement de lieu ponctuel : variante de toute la séance (KT-059).
Future<bool> showPlaceSheet(
  BuildContext context,
  int week,
  DayPlan base,
) async {
  final catalog = await _catalog(context);
  if (catalog == null || !context.mounted) return false;
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PlaceSheet(week: week, base: base, catalog: catalog),
  );
  return changed ?? false;
}

class _PlaceSheet extends StatefulWidget {
  final int week;
  final DayPlan base;
  final GenCatalog catalog;
  const _PlaceSheet({
    required this.week,
    required this.base,
    required this.catalog,
  });

  @override
  State<_PlaceSheet> createState() => _PlaceSheetState();
}

class _PlaceSheetState extends State<_PlaceSheet> {
  String? _place;

  @override
  Widget build(BuildContext context) {
    final preview =
        _place == null
            ? const <String, GenExercise?>{}
            : store.adaptPlacePreview(
              widget.week,
              widget.base,
              _place!,
              widget.catalog,
            );
    return SingleChildScrollView(
      key: const ValueKey('adapt-place-sheet'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Je m’entraîne ailleurs',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in kPlaces)
                ChoiceChip(
                  key: ValueKey('adapt-place-${p.$1}'),
                  label: Text(p.$2),
                  selected: _place == p.$1,
                  onSelected: (_) => setState(() => _place = p.$1),
                ),
            ],
          ),
          if (_place != null) ...[
            const SizedBox(height: 12),
            if (preview.isEmpty)
              Text(
                'Tout se fait avec le matériel de ${placeLabel(_place!).toLowerCase()} : '
                'rien à changer.',
              ),
            for (final e in widget.base.exercises)
              if (preview.containsKey(e.id))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    preview[e.id] == null
                        ? '• ${store.splitName(e.name).$1} : pas d’équivalent '
                            'ici, à passer ou à remplacer toi-même.'
                        : '• ${store.splitName(e.name).$1} → ${preview[e.id]!.name}',
                  ),
                ),
          ],
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Fermer'),
              ),
              if (_place != null && preview.values.any((v) => v != null))
                FilledButton(
                  key: const ValueKey('adapt-place-apply'),
                  onPressed: () {
                    store.applyPlace(
                      widget.week,
                      widget.base,
                      _place!,
                      preview,
                      widget.catalog,
                    );
                    Navigator.pop(context, true);
                  },
                  child: const Text('Adapter la séance'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================================================== bandeau de séance

/// Adaptations de la séance (reprise, maladie, allègement, compression) :
/// texte court, toujours écrit (jamais la couleur seule).
class AdaptSessionBanner extends StatelessWidget {
  final int week;
  final DayPlan base;
  final VoidCallback? onChanged;
  const AdaptSessionBanner({
    super.key,
    required this.week,
    required this.base,
    this.onChanged,
  });

  static List<String> lines(AdaptSessionInfo info, int? compressed) {
    final out = <String>[];
    final r = info.rule;
    if (info.safety && r != null) {
      out.add(
        'Reprise après ${r.gap} jours : charges −${(r.loadCut * 100).round()} %'
        '${r.setCut > 0 ? ', une série de moins' : ''} sur '
        '${info.movements.length > 1 ? 'les mouvements principaux' : 'le mouvement principal'}'
        '${r.calibrationWeek ? ' ; semaine de calibrage (tests légers)' : ''}'
        '${r.calibrationSet ? ' ; série 1 = calibrage, arrête-toi à 2-3 répétitions en réserve' : ''}.',
      );
    }
    if (info.illness) {
      out.add(
        'Retour après une maladie : volume −30 % et une répétition en réserve '
        'de plus cette semaine. Si les symptômes persistent, parles-en à un '
        'professionnel de santé.',
      );
    }
    if (info.lighten) out.add('Fin de semaine allégée : séries × 0,8.');
    if (info.deload) {
      out.add('Semaine de décharge : séries × 0,6, charges −10 %.');
    }
    if (compressed != null) out.add('Séance recomposée pour $compressed min.');
    if (info.shorter) out.add('Séances 20 % plus courtes.');
    return out;
  }

  /// Résumé d'une ligne (l'en-tête de séance reste compact à 200 %).
  static String summary(AdaptSessionInfo info, int? compressed) {
    final parts = <String>[];
    final r = info.rule;
    if (info.safety && r != null) {
      parts.add(
        info.applied
            ? 'Reprise : charges −${(r.loadCut * 100).round()} %'
            : 'Reprise après ${r.gap} jours : allègement proposé',
      );
    }
    if (info.illness) {
      parts.add(
        info.applied ? 'Retour de maladie : allégé' : 'Retour de maladie',
      );
    }
    if (info.lighten) parts.add('Semaine allégée');
    if (info.deload) parts.add('Décharge');
    if (compressed != null) parts.add('$compressed min');
    if (info.shorter) parts.add('Séance raccourcie');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final info = store.adaptInfo(week, base.j);
    final compressed = store.adaptCompressed(week, base.j);
    final text = summary(info, compressed);
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Semantics(
        button: true,
        label: 'Adaptation de la séance : $text. Détails',
        excludeSemantics: true,
        child: KCard(
          key: const ValueKey('adapt-session-banner'),
          accent: SL.accent,
          radius: 14,
          padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
          onTap: () => _details(context),
          child: Row(
            children: [
              const Icon(Icons.tune_rounded, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _details(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (context) => ListenableBuilder(
            listenable: store,
            builder: (context, _) {
              final info = store.adaptInfo(week, base.j);
              final mode = info.mode;
              final pending =
                  info.safety && info.choice == null && mode != 'guided';
              void choose(String c) {
                store.setAdaptSafety(week, base, c);
                onChanged?.call();
                Navigator.pop(context);
              }

              return SingleChildScrollView(
                key: const ValueKey('adapt-session-details'),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Séance adaptée',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    for (final t in lines(
                      info,
                      store.adaptCompressed(week, base.j),
                    ))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('• $t'),
                      ),
                    if (info.safety && !info.applied)
                      Text(
                        mode == 'expert'
                            ? 'Mode Expert : à toi de décider.'
                            : 'Mode Assisté : rien ne change sans ton accord.',
                        style: TextStyle(color: SL.dim),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        if (info.safety && info.applied)
                          OutlinedButton(
                            key: const ValueKey('adapt-safety-undo'),
                            onPressed: () => choose('refused'),
                            child: Text(
                              mode == 'guided' ? 'Annuler' : 'Revenir au prévu',
                            ),
                          ),
                        if (info.safety && !info.applied) ...[
                          if (pending)
                            OutlinedButton(
                              key: const ValueKey('adapt-safety-keep'),
                              onPressed: () => choose('refused'),
                              child: const Text('Garder le prévu'),
                            ),
                          FilledButton(
                            key: const ValueKey('adapt-safety-apply'),
                            onPressed: () => choose('applied'),
                            child: Text(
                              pending ? 'Appliquer' : 'Appliquer quand même',
                            ),
                          ),
                        ],
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Fermer'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}

// ======================================================= carte d'accueil

class AdaptHomeCard extends StatelessWidget {
  final bool pauseOnly, proposalsOnly;
  const AdaptHomeCard({
    super.key,
    this.pauseOnly = false,
    this.proposalsOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final pause = proposalsOnly ? null : store.adapt.pause;
    final proposals =
        pauseOnly ? const <AdaptProposal>[] : store.adaptProposals;
    return Column(
      key: const ValueKey('adapt-home-card'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pause != null) _PauseCard(pause: pause),
        for (final p in proposals)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: KCard(
              key: ValueKey('adapt-proposal-${p.kind}'),
              accent: SL.accent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(p.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(p.text),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (i, a) in p.actions.indexed)
                        i == 0 && a.$1 != 'dismiss'
                            ? FilledButton(
                              key: ValueKey('adapt-action-${a.$1}'),
                              onPressed: () => _run(context, p, a.$1),
                              child: Text(a.$2),
                            )
                            : OutlinedButton(
                              key: ValueKey('adapt-action-${a.$1}'),
                              onPressed: () => _run(context, p, a.$1),
                              child: Text(a.$2),
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _run(BuildContext context, AdaptProposal p, String a) async {
    final messenger = ScaffoldMessenger.of(context);
    final text = await store.runAdaptAction(p, a);
    if (text != null) {
      messenger.showSnackBar(SnackBar(content: Text(text)));
    }
  }
}

class _PauseCard extends StatelessWidget {
  final AdaptPause pause;
  const _PauseCard({required this.pause});

  @override
  Widget build(BuildContext context) {
    final vacation = pause.kind == 'vacation';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: KCard(
        key: const ValueKey('adapt-pause-card'),
        accent: SL.accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              vacation ? 'Vacances : programme en pause' : 'Pause maladie',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              vacation
                  ? 'Ton calendrier est en pause depuis le '
                      '${_date(pause.from)}. Si tu en as envie : 2 séances '
                      'd’entretien de 20 minutes sans matériel par semaine, '
                      'facultatives.'
                  : 'Repose-toi. Au retour, la première semaine sera plus '
                      'légère (volume −30 %). Si les symptômes persistent, '
                      'parles-en à un professionnel de santé.',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  key: const ValueKey('adapt-pause-end'),
                  onPressed: () {
                    store.endPause();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Bon retour ! Le programme reprend aujourd’hui.',
                        ),
                      ),
                    );
                  },
                  child: const Text('Je reprends'),
                ),
                if (vacation)
                  OutlinedButton(
                    key: const ValueKey('adapt-maintenance'),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final c = await _catalog(context);
                      if (c == null) return;
                      final name = store.addMaintenanceSession(c);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            '« $name » est dans tes séances perso.',
                          ),
                        ),
                      );
                    },
                    child: const Text('Séance d’entretien'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _date(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

// ========================================= écran « Adaptation au quotidien »

class AdaptScreen extends StatelessWidget {
  const AdaptScreen({super.key});

  static const _eventLabels = {
    'mode': 'Mode changé',
    'compress': 'Séance recomposée',
    'uncompress': 'Séance complète rétablie',
    'swap': 'Exercice échangé',
    'unswap': 'Exercice d’origine rétabli',
    'place': 'Séance adaptée à un autre lieu',
    'slide': 'Programme décalé',
    'pause': 'Pause',
    'resume': 'Reprise',
    'safety': 'Adaptation de reprise',
    'lighten': 'Fin de semaine allégée',
    'unlighten': 'Allègement levé',
    'shorter': 'Séances plus courtes',
    'unshorter': 'Séances de durée normale',
    'plateau': 'Palier',
    'days': 'Jours de séance modifiés',
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final mode = store.autonomyMode;
      final pause = store.adapt.pause;
      final events = store.adapt.events.reversed.take(30).toList();
      return KScreen(
        appBar: AppBar(title: const Text('Adaptation au quotidien')),
        body: KList(
          key: const ValueKey('adapt-screen'),
          children: [
            const KSection('Mode de Koach'),
            for (final m in kAutonomyModes)
              KCard(
                key: ValueKey('adapt-mode-$m'),
                accent: mode == m ? SL.accent : null,
                onTap: () => store.setAutonomyMode(m),
                child: Semantics(
                  selected: mode == m,
                  button: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            mode == m
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${const {'guided': 'Guidé', 'assisted': 'Assisté', 'expert': 'Expert'}[m]}'
                              '${mode == m ? ' (actuel)' : ''}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(kAutonomyExplanations[m]!),
                    ],
                  ),
                ),
              ),
            const KSection(
              'Pause',
              subtitle:
                  'Le calendrier s’arrête ; à la reprise, le programme repart '
                  'là où tu en étais, sans séance doublée.',
            ),
            if (pause == null)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const ValueKey('adapt-vacation'),
                    onPressed: () => store.startPause('vacation'),
                    icon: const Icon(Icons.beach_access_outlined),
                    label: const Text('Je pars en vacances'),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey('adapt-illness'),
                    onPressed: () => store.startPause('illness'),
                    icon: const Icon(Icons.healing_outlined),
                    label: const Text('Je suis malade'),
                  ),
                ],
              )
            else
              _PauseCard(pause: pause),
            const KSection('Durée et charge'),
            SwitchListTile(
              key: const ValueKey('adapt-shorter'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Séances 20 % plus courtes'),
              subtitle: const Text(
                'Koach recompose chaque séance à venir (principaux gardés).',
              ),
              value: store.adapt.shorter != null,
              onChanged: store.setShorter,
            ),
            if (store.adapt.lightenFrom != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Allègement jusqu’au ${_date(store.adapt.lightenTo!)}',
                ),
                trailing: TextButton(
                  key: const ValueKey('adapt-unlighten'),
                  onPressed: store.clearLighten,
                  child: const Text('Lever'),
                ),
              ),
            const KSection('Historique'),
            if (events.isEmpty)
              const KEmpty(
                icon: Icons.history,
                title: 'Aucune adaptation',
                message: 'Les adaptations de Koach apparaîtront ici.',
              ),
            for (final e in events)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${_eventLabels[e.kind] ?? e.kind}'
                  '${e.status == 'undone' ? ' (annulé)' : ''}',
                ),
                subtitle: Text(_eventDetail(e)),
                trailing:
                    e.kind == 'slide' && e.status == 'applied'
                        ? TextButton(
                          onPressed: () {
                            final ok = store.undoSlide(e);
                            _snack(
                              context,
                              ok
                                  ? 'Départ rétabli.'
                                  : 'Le départ a changé depuis : annulation '
                                      'impossible.',
                            );
                          },
                          child: const Text('Annuler'),
                        )
                        : null,
              ),
          ],
        ),
      );
    },
  );

  static String _eventDetail(AdaptEvent e) {
    final d = e.detail;
    final when = '${_date(e.at.substring(0, 10))} ${e.at.substring(11, 16)}';
    final extra = switch (e.kind) {
      'slide' => '${d['days']} jour(s)',
      'compress' => '${d['minutes']} min',
      'mode' => '${d['from']} → ${d['to']}',
      'plateau' => '${d['movement']}',
      'pause' || 'resume' => d['kind'] == 'illness' ? 'maladie' : 'vacances',
      _ => '${d['session'] ?? ''}',
    };
    return extra.isEmpty ? when : '$when · $extra';
  }
}

// ======================================= difficulté globale (KT-064)

/// Une seule question après la séance, pour les débutants et novices en
/// mode Guidé ou Assisté ; « Passer » toujours possible.
Future<void> showSessionDifficulty(BuildContext context, String key) async {
  final value = await showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder:
        (context) => SingleChildScrollView(
          key: const ValueKey('adapt-difficulty-sheet'),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cette séance était…',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Difficulté globale sur 10. Un simple repère pour doser la '
                'semaine.',
                style: TextStyle(color: SL.dim),
              ),
              const SizedBox(height: 8),
              for (final e in kDifficultyLabels.entries)
                if (e.key > 0)
                  ListTile(
                    key: ValueKey('adapt-difficulty-${e.key}'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(radius: 16, child: Text('${e.key}')),
                    title: Text(e.value),
                    onTap: () => Navigator.pop(context, e.key),
                  ),
              TextButton(
                key: const ValueKey('adapt-difficulty-skip'),
                onPressed: () => Navigator.pop(context),
                child: const Text('Passer'),
              ),
            ],
          ),
        ),
  );
  if (value != null) store.setSessionDifficulty(key, value);
}
