// G9 (D5.8, D5.9) : bilan santé en début de séance.
//
// - Page « Bilan du jour », première page de la séance servie par
//   `kalis_adapt` : Koach demande « Comment tu te sens ? » (5 niveaux, Koach
//   en 5 poses avec leur libellé, l'information ne passe pas par l'image
//   seule). Réponse moyenne ou haute → séance ; réponse basse → détail
//   facultatif sur un seul écran. « Passer » partout ; une question sans
//   réponse n'est pas prise en compte (aucune valeur par défaut).
// - L'ajustement qui en sort est appliqué en mode assisté (Koach dit ce
//   qu'il a changé, « Annuler ») ou proposé en mode libre (« Accepter » /
//   « Garder ma séance »).
// - Douleur : zones épargnées par le moteur ; règle L13 de renvoi vers un
//   professionnel conservée (douleur > 3/10 plus de 2 séances de suite).
import 'package:flutter/material.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_koach/kalis_koach.dart' show KoachPose, KoachUsage;

import '../app_theme.dart';
import '../athlete_profile.dart'
    show kRegionZones, kSideLabels, kZoneLabels, regionsOfZone, limitationOf;
import '../koach/koach_bubble.dart';
import '../koach/koach_view.dart';
import '../models.dart';
import '../muscle_map_2d.dart';
import '../store.dart';
import '../ui.dart';
import 'adapt_texts.dart';

/// Pose de Koach pour chaque réponse à « Comment tu te sens ? ».
const kFeelPoses = <int, KoachPose>{
  1: KoachPose.oops,
  2: KoachPose.shrug,
  3: KoachPose.ponder,
  4: KoachPose.thumbsUp,
  5: KoachPose.cheer,
};

/// Explication de l'ajustement du bilan (« Pourquoi ? »).
const kHealthWhy =
    'Ton bilan me dit comment tu arrives aujourd’hui. S’il est bas, je ne '
    'monte pas les charges, je garde un peu plus de marge sur chaque série, '
    'et parfois une série de moins. Une douleur : j’épargne la zone. Ce que '
    'tu n’as pas répondu ne compte pas.';

/// Page « Bilan du jour » de la séance.
class HealthCheckPage extends StatefulWidget {
  final WeekPlan week;
  final DayPlan base;

  /// Séance du moteur changée (bilan, choix) : les pages sont recalculées.
  final VoidCallback onChanged;

  /// Aller au premier exercice.
  final VoidCallback onStart;
  const HealthCheckPage({
    super.key,
    required this.week,
    required this.base,
    required this.onChanged,
    required this.onStart,
  });

  @override
  State<HealthCheckPage> createState() => _HealthCheckPageState();
}

class _HealthCheckPageState extends State<HealthCheckPage> {
  bool _redo = false;
  bool _busy = false;

  int get _w => widget.week.n;

  Future<void> _answer(int overall) async {
    if (_busy) return;
    var check = kc.HealthCheck(overall: overall);
    if (feelIsLow(overall)) {
      final detail = await Navigator.of(context).push<kc.HealthCheck>(
        MaterialPageRoute(builder: (_) => HealthDetailScreen(initial: check)),
      );
      if (!mounted) return;
      if (detail != null) check = detail;
    }
    _apply(check);
  }

  void _apply(kc.HealthCheck? check, {bool skipped = false}) {
    setState(() => _busy = true);
    final a = store.adaptAnswer(_w, widget.base, check, skipped: skipped);
    setState(() {
      _busy = false;
      _redo = false;
    });
    widget.onChanged();
    if (a != null && a.base == null) widget.onStart();
  }

  Future<void> _detail(kc.HealthCheck? current) async {
    final detail = await Navigator.of(context).push<kc.HealthCheck>(
      MaterialPageRoute(
        builder: (_) =>
            HealthDetailScreen(initial: current ?? const kc.HealthCheck()),
      ),
    );
    if (!mounted || detail == null) return;
    _apply(detail);
  }

  void _choose(String choice) {
    store.adaptChoose(_w, widget.base, choice);
    widget.onChanged();
    setState(() {});
    if (choice == 'accepted' || choice == 'kept') widget.onStart();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final a = store.sessionAdapt(_w, widget.base.j);
      if (a == null) return const SizedBox.shrink();
      return ListView(
        key: const ValueKey('health-page'),
        padding: const EdgeInsets.fromLTRB(KSpace.page, 2, KSpace.page, 16),
        children: !a.asked || _redo ? _question(a) : _answered(a),
      );
    },
  );

  List<Widget> _question(SessionAdapt a) => [
    KCard(
      key: const ValueKey('health-question'),
      child: KoachBubble(
        pose: koachPose(KoachUsage.healthCheck),
        text: 'Comment tu te sens ?',
        why:
            'Ta réponse règle la séance d’aujourd’hui. Si ça ne va pas, je '
            'te poserai quelques questions, toutes facultatives.',
        koachHeight: 88,
      ),
    ),
    const SizedBox(height: 12),
    LayoutBuilder(
      builder: (context, c) {
        // Cinq tuiles côte à côte ; écran étroit ou grand texte : une
        // tuile par ligne, Koach à gauche du libellé.
        final wide =
            c.maxWidth / 5 >= 58 &&
            MediaQuery.textScalerOf(context).scale(10) <= 13;
        final tiles = [
          for (var n = 1; n <= 5; n++)
            _FeelTile(
              key: ValueKey('feel-$n'),
              level: n,
              horizontal: !wide,
              onTap: _busy ? null : () => _answer(n),
            ),
        ];
        return wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final t in tiles) Expanded(child: t)],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: tiles,
              );
      },
    ),
    const SizedBox(height: 8),
    Align(
      child: TextButton(
        key: const ValueKey('feel-skip'),
        onPressed: _busy ? null : () => _apply(null, skipped: true),
        child: const Text('Passer'),
      ),
    ),
  ];

  List<Widget> _answered(SessionAdapt a) {
    final lines = a.check == null
        ? const <String>[]
        : healthCheckLines(a.check!);
    final zones = store.adaptPainReferralZones;
    return [
      // Ce qui change d'abord : la carte de Koach, puis le bilan.
      if (a.base != null) ...[_adjustmentCard(a), const SizedBox(height: 12)],
      if (zones.isNotEmpty) ...[
        KCard(
          key: const ValueKey('health-referral'),
          accent: SL.accent,
          child: KoachSays(
            pose: koachPose(KoachUsage.care),
            child: Text(
              '${zones.join(', ')} : $kPainReferral',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
      KCard(
        key: const ValueKey('health-summary'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KoachHeader(
              'Bilan du jour',
              pose: koachPose(KoachUsage.healthCheck),
            ),
            const SizedBox(height: 8),
            if (lines.isEmpty)
              Text(
                'Bilan passé : séance prévue.',
                style: TextStyle(color: SL.dim),
              )
            else
              for (final l in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(l),
                ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  key: const ValueKey('bilan-redo'),
                  onPressed: () => setState(() => _redo = true),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refaire le bilan'),
                ),
                TextButton.icon(
                  key: const ValueKey('bilan-detail'),
                  onPressed: () => _detail(a.check),
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: const Text('Préciser (douleur, temps…)'),
                ),
              ],
            ),
          ],
        ),
      ),
      if (a.base == null) ...[
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const ValueKey('bilan-start'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(KControl.buttonHeight),
          ),
          onPressed: widget.onStart,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Premier exercice'),
        ),
      ],
    ];
  }

  /// Carte de Koach : ce que l'ajustement du bilan change (6 lignes au
  /// plus), et les choix du mode (assisté : appliqué, « Annuler » ; libre :
  /// « Accepter » / « Garder ma séance »).
  Widget _adjustmentCard(SessionAdapt a) {
    final all = sessionDiffLines(a.base!, a.plan, store.adaptExerciseName);
    final shown = all.isEmpty
        ? const ['Charges et cibles un peu plus prudentes.']
        : all.take(6).toList();
    final more = all.length - shown.length;
    final (KoachPose pose, String head, List<(String, String, VoidCallback)> actions, bool list) =
        switch (a.choice) {
          'applied' => (
            koachPose(KoachUsage.adjustment),
            'J’ai adapté ta séance à ton bilan :',
            <(String, String, VoidCallback)>[
              ('adjust-go', 'C’est parti', widget.onStart),
              ('adjust-undo', 'Annuler', () => _choose('undone')),
            ],
            true,
          ),
          'undone' => (
            koachPose(KoachUsage.cancel),
            'D’accord, tu gardes ta séance prévue.',
            <(String, String, VoidCallback)>[
              ('adjust-go', 'C’est parti', widget.onStart),
              ('adjust-redo', 'Rétablir l’ajustement', () => _choose('applied')),
            ],
            false,
          ),
          'pending' => (
            koachPose(KoachUsage.proposal),
            'Vu ton bilan, je te propose :',
            <(String, String, VoidCallback)>[
              ('adjust-accept', 'Accepter', () => _choose('accepted')),
              ('adjust-keep', 'Garder ma séance', () => _choose('kept')),
            ],
            true,
          ),
          'accepted' => (
            koachPose(KoachUsage.confirmation),
            'C’est noté, séance adaptée :',
            <(String, String, VoidCallback)>[
              ('adjust-go', 'C’est parti', widget.onStart),
              ('adjust-keep', 'Garder ma séance', () => _choose('kept')),
            ],
            true,
          ),
          _ => (
            koachPose(KoachUsage.confirmation),
            'Tu gardes ta séance prévue.',
            <(String, String, VoidCallback)>[
              ('adjust-go', 'C’est parti', widget.onStart),
              (
                'adjust-accept',
                'Accepter l’ajustement',
                () => _choose('accepted'),
              ),
            ],
            false,
          ),
        };
    return KCard(
      key: ValueKey('health-adjust-${a.choice}'),
      child: KoachSays(
        pose: pose,
        koachHeight: 64,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(head, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (list) ...[
              const SizedBox(height: 4),
              for (final l in shown)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('• $l'),
                ),
              if (more > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '… et $more autre${more > 1 ? 's' : ''} '
                    'changement${more > 1 ? 's' : ''}.',
                    style: TextStyle(color: SL.dim),
                  ),
                ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (var i = 0; i < actions.length; i++)
                  i == 0
                      ? FilledButton(
                          key: ValueKey(actions[i].$1),
                          onPressed: actions[i].$3,
                          child: Text(actions[i].$2),
                        )
                      : TextButton(
                          key: ValueKey(actions[i].$1),
                          onPressed: actions[i].$3,
                          child: Text(actions[i].$2),
                        ),
                TextButton(
                  key: const ValueKey('adjust-why'),
                  onPressed: () => showKoachSheet<void>(
                    context,
                    pose: KoachPose.explainBoard,
                    title: 'Pourquoi ?',
                    text: kHealthWhy,
                  ),
                  child: const Text('Pourquoi ?'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeelTile extends StatelessWidget {
  final int level;
  final VoidCallback? onTap;

  /// Koach à gauche du libellé (une tuile par ligne).
  final bool horizontal;
  const _FeelTile({
    super.key,
    required this.level,
    required this.onTap,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = kFeelLabels[level]!;
    return Semantics(
      button: true,
      label: 'Je me sens : $label',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Material(
          color: SL.card,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: KoachSurface(
              color: SL.card,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 6,
                ),
                child: horizontal
                    ? Row(
                        children: [
                          KoachView(
                            pose: kFeelPoses[level]!,
                            height: 44,
                            width: 40,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          KoachView(
                            pose: kFeelPoses[level]!,
                            height: 48,
                            width: 44,
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label,
                              maxLines: 1,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- détail

/// Détail du bilan, sur un seul écran : tout est facultatif ; une question
/// laissée vide n'est pas prise en compte.
class HealthDetailScreen extends StatefulWidget {
  final kc.HealthCheck initial;
  const HealthDetailScreen({super.key, required this.initial});

  @override
  State<HealthDetailScreen> createState() => _HealthDetailScreenState();
}

class _HealthDetailScreenState extends State<HealthDetailScreen> {
  late final Map<String, int?> _v;
  List<kc.PainReport>? _pains;
  int? _minutes;

  static const _scale = ['Très bas', 'Bas', 'Moyen', 'Bon', 'Très bon'];
  static const _questions = <(String, String, List<String>)>[
    ('sleepQuality', 'Sommeil', _scale),
    ('energy', 'Énergie', _scale),
    ('mood', 'Humeur', _scale),
    (
      'soreness',
      'Courbatures',
      ['Très fortes', 'Fortes', 'Moyennes', 'Légères', 'Aucune'],
    ),
    ('stress', 'Stress', ['Très fort', 'Fort', 'Moyen', 'Faible', 'Aucun']),
    ('motivation', 'Motivation', _scale),
    ('nutrition', 'Alimentation', _scale),
    ('hydration', 'Hydratation', _scale),
  ];
  static const _minuteChoices = [20, 30, 45, 60, 75, 90];

  @override
  void initState() {
    super.initState();
    final j = widget.initial.toJson();
    _v = {for (final q in _questions) q.$1: j[q.$1] as int?};
    _pains = widget.initial.pains == null ? null : [...widget.initial.pains!];
    _minutes = widget.initial.minutesAvailable;
  }

  kc.HealthCheck _result() {
    final j = <String, Object?>{...widget.initial.toJson()};
    j.remove('pains');
    j.remove('minutesAvailable');
    for (final q in _questions) {
      final x = _v[q.$1];
      if (x == null) {
        j.remove(q.$1);
      } else {
        j[q.$1] = x;
      }
    }
    if (_minutes != null) j['minutesAvailable'] = _minutes;
    if (_pains != null) j['pains'] = [for (final p in _pains!) p.toJson()];
    return kc.HealthCheck.fromJson(j);
  }

  Future<void> _editPain(kc.BodyZone zone) async {
    kc.PainReport? existing;
    for (final p in _pains ?? const <kc.PainReport>[]) {
      if (p.zone == zone) existing = p;
    }
    var side = existing?.side ?? kc.BodySide.both;
    var level = (existing?.intensity ?? 4).toDouble();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => SingleChildScrollView(
          key: const ValueKey('pain-sheet'),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                kZoneLabels[zone]!,
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final b in kc.BodySide.values)
                    ChoiceChip(
                      key: ValueKey('pain-side-${b.code}'),
                      label: Text(kSideLabels[b]!),
                      selected: side == b,
                      onSelected: (_) => set(() => side = b),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Douleur aujourd’hui : ${level.round()}/10'),
              Slider(
                key: const ValueKey('pain-level'),
                value: level,
                max: 10,
                divisions: 10,
                label: '${level.round()}/10',
                onChanged: (v) => set(() => level = v),
              ),
              Text(
                '0 : aucune · 10 : la pire imaginable. Au-dessus de 3/10, '
                'j’épargne la zone. Une douleur forte ou qui dure mérite '
                'l’avis d’un professionnel de santé.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              FilledButton(
                key: const ValueKey('pain-save'),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    final l = limitationOf(zone, side, level.round());
    setState(() {
      final next = [...?_pains]..removeWhere((p) => p.zone == zone);
      next.add(
        kc.PainReport(
          zone: zone,
          side: side,
          joint: l.joint,
          intensity: level.round(),
          phase: kc.PainPhase.before,
        ),
      );
      _pains = next;
    });
  }

  Widget _title(String t) =>
      Text(t, style: Theme.of(context).textTheme.titleMedium);

  @override
  Widget build(BuildContext context) {
    final lit = <String, double>{
      for (final p in _pains ?? const <kc.PainReport>[])
        for (final r in regionsOfZone(p.zone)) r: .35 + .065 * p.intensity,
    };
    return KScreen(
      appBar: AppBar(title: const Text('Bilan du jour')),
      body: KList(
        key: const ValueKey('health-detail'),
        children: [
          KCard(
            child: KoachSays(
              pose: koachPose(KoachUsage.care),
              koachHeight: 64,
              child: const Text(
                'Dis-moi ce qui ne va pas. Tout est facultatif : ce que tu '
                'laisses vide ne compte pas.',
              ),
            ),
          ),
          for (final q in _questions)
            KCard(
              key: ValueKey('detail-${q.$1}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title(q.$2),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var i = 1; i <= 5; i++)
                        ChoiceChip(
                          key: ValueKey('detail-${q.$1}-$i'),
                          label: Text(q.$3[i - 1]),
                          selected: _v[q.$1] == i,
                          onSelected: (on) =>
                              setState(() => _v[q.$1] = on ? i : null),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          KCard(
            key: const ValueKey('detail-pains'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title('Douleur'),
                const SizedBox(height: 4),
                Text(
                  'Touche la zone sur la carte, ou choisis-la dans la liste.',
                  style: TextStyle(color: SL.dim, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ChoiceChip(
                  key: const ValueKey('detail-no-pain'),
                  label: const Text('Aucune douleur'),
                  selected: _pains != null && _pains!.isEmpty,
                  onSelected: (on) => setState(() => _pains = on ? [] : null),
                ),
                const SizedBox(height: 8),
                MuscleMap2D(
                  key: const ValueKey('detail-body-map'),
                  views: const [MapView.face, MapView.dos],
                  height: 220,
                  intensities: lit,
                  semanticLabel: 'Carte du corps',
                  onRegionTap: (r) {
                    final z = r == null ? null : kRegionZones[r];
                    if (z != null) _editPain(z);
                  },
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final z in kc.BodyZone.values)
                      ActionChip(
                        key: ValueKey('pain-zone-${z.code}'),
                        label: Text(kZoneLabels[z]!),
                        onPressed: () => _editPain(z),
                      ),
                  ],
                ),
                for (final p in _pains ?? const <kc.PainReport>[])
                  ListTile(
                    key: ValueKey('pain-${p.zone.code}'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${kZoneLabels[p.zone]} · ${kSideLabels[p.side]!.toLowerCase()}',
                    ),
                    subtitle: Text('${p.intensity}/10'),
                    onTap: () => _editPain(p.zone),
                    trailing: IconButton(
                      tooltip: 'Retirer',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                        final next = [...?_pains]
                          ..removeWhere((x) => x.zone == p.zone);
                        _pains = next.isEmpty ? null : next;
                      }),
                    ),
                  ),
              ],
            ),
          ),
          KCard(
            key: const ValueKey('detail-minutes'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title('Temps disponible aujourd’hui'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final m in _minuteChoices)
                      ChoiceChip(
                        key: ValueKey('detail-minutes-$m'),
                        label: Text('$m min'),
                        selected: _minutes == m,
                        onSelected: (on) =>
                            setState(() => _minutes = on ? m : null),
                      ),
                  ],
                ),
              ],
            ),
          ),
          FilledButton(
            key: const ValueKey('detail-save'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(KControl.buttonHeight),
            ),
            onPressed: () => Navigator.pop(context, _result()),
            child: const Text('Valider mon bilan'),
          ),
          Align(
            child: TextButton(
              key: const ValueKey('detail-skip'),
              onPressed: () => Navigator.pop(context, widget.initial),
              child: const Text('Passer'),
            ),
          ),
        ],
      ),
    );
  }
}

/// « J'ai seulement… minutes » (séance servie par le moteur) : temps
/// disponible ajouté au bilan ; null : annulé ; 0 : temps prévu.
Future<int?> showMinutesSheet(BuildContext context, int? current) =>
    showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => SingleChildScrollView(
        key: const ValueKey('minutes-sheet'),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Combien de temps as-tu ?',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            const Text('Koach raccourcit la séance en gardant l’essentiel.'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in const [20, 30, 45, 60, 75, 90])
                  ChoiceChip(
                    key: ValueKey('minutes-$m'),
                    label: Text('$m min'),
                    selected: current == m,
                    onSelected: (_) => Navigator.pop(ctx, m),
                  ),
                ChoiceChip(
                  key: const ValueKey('minutes-planned'),
                  label: const Text('Le temps prévu'),
                  selected: current == null,
                  onSelected: (_) => Navigator.pop(ctx, 0),
                ),
              ],
            ),
          ],
        ),
      ),
    );

/// « Je m'entraîne ailleurs » (séance servie par le moteur) : lieu du
/// jour ; null : annulé ; `''` : lieu prévu.
Future<String?> showPlaceChoiceSheet(BuildContext context, kc.Place? current) =>
    showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => SingleChildScrollView(
        key: const ValueKey('place-sheet'),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Où t’entraînes-tu aujourd’hui ?',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            const Text(
              'Koach remplace ce qui n’est pas faisable sur place par un '
              'équivalent.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in kc.Place.values)
                  ChoiceChip(
                    key: ValueKey('place-${p.code}'),
                    label: Text(switch (p) {
                      kc.Place.gym => 'En salle',
                      kc.Place.home => 'À la maison',
                      kc.Place.outdoor => 'Dehors',
                    }),
                    selected: current == p,
                    onSelected: (_) => Navigator.pop(ctx, p.code),
                  ),
                ChoiceChip(
                  key: const ValueKey('place-planned'),
                  label: const Text('Le lieu prévu'),
                  selected: current == null,
                  onSelected: (_) => Navigator.pop(ctx, ''),
                ),
              ],
            ),
          ],
        ),
      ),
    );
