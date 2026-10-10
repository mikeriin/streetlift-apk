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
//
// UI2 (refonte UI, maquette « Bilan du jour ») : cartes du kit, plus de
// carte dans une carte (C7 : la question et les cinq tuiles du ressenti
// dans la même carte, Koach à côté du titre, « Pourquoi ? » déplié en
// place) ; un seul bouton plein (C2) ; choix en puces neutres ; temps et
// lieu en feuilles de liste ; « Douleur ou malaise ? » de la séance ouvre
// le détail sur la section Douleur ([reportSessionPain]).
import 'package:flutter/material.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_koach/kalis_koach.dart'
    show KoachPose, KoachSide, KoachUsage;

import '../athlete_profile.dart'
    show kRegionZones, kSideLabels, kZoneLabels, regionsOfZone, limitationOf;
import '../koach/koach_bubble.dart';
import '../koach/koach_view.dart';
import '../models.dart';
import '../muscle_map_2d.dart';
import '../plan/coach_texts.dart'
    show coachBlockHasPainStop, coachBlockPainNotes;
import '../plan/evolution_widgets.dart' show EvolutionSessionCard;
import '../store.dart';
import '../ui.dart';
import '../wellbeing_screens.dart' show SafetyScreen;
import 'adapt_texts.dart';
import 'clearance.dart';
import 'widgets/session_kit.dart';

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

/// Hauteur d'une tuile de ressenti (maquette « Bilan du jour »).
const double _feelTileHeight = 96;

/// Largeur minimale d'une tuile de ressenti pour les poser côte à côte.
const double _feelTileMinWidth = 52;

/// Éléments d'une colonne séparés de l'écart entre cartes.
List<Widget> _spaced(List<Widget> items, [double gap = KSpacing.cardGap]) => [
  for (var i = 0; i < items.length; i++) ...[
    if (i > 0) SizedBox(height: gap),
    items[i],
  ],
];

/// « Douleur ou malaise ? » (menu ⋮ de la séance, cahier §4.1) : détail du
/// bilan ouvert sur la section Douleur. Un bilan validé est appliqué à la
/// séance (S[week], J[base]) ; vrai dans ce cas, faux si la page est
/// quittée sans bilan ou par « Passer » (qui rend le bilan de départ tel
/// quel : rien n'est recalculé, la question du jour reste posée).
Future<bool> reportSessionPain(
  BuildContext context,
  WeekPlan week,
  DayPlan base,
) async {
  final initial =
      store.sessionAdapt(week.n, base.j)?.check ?? const kc.HealthCheck();
  final detail = await Navigator.of(context).push<kc.HealthCheck>(
    MaterialPageRoute(
      builder: (_) => HealthDetailScreen(initial: initial, focusPain: true),
    ),
  );
  if (detail == null || identical(detail, initial)) return false;
  store.adaptAnswer(week.n, base, detail);
  return true;
}

/// Koach et ce qu'il dit, sans bulle (C7 : une bulle posée dans une carte
/// serait une carte dans une carte) : le texte, « Pourquoi ? » qui déplie
/// l'explication en place (« Compris » la replie ; Koach prend alors la
/// pose de l'explication, comme dans la bulle), Koach du côté conseillé
/// par sa pose. Composant à promouvoir dans le kit (UI5).
class KoachWhyHeader extends StatefulWidget {
  final KoachPose pose;
  final String text;
  final String why;
  final KoachPose whyPose;
  final double koachHeight;

  /// Texte en titre de carte (« Comment tu te sens ? ») ; sinon texte
  /// courant.
  final bool title;
  const KoachWhyHeader({
    super.key,
    required this.pose,
    required this.text,
    required this.why,
    this.whyPose = KoachPose.think,
    this.koachHeight = 64,
    this.title = false,
  });

  @override
  State<KoachWhyHeader> createState() => _KoachWhyHeaderState();
}

class _KoachWhyHeaderState extends State<KoachWhyHeader> {
  bool _why = false;

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final koach = KoachView(
      key: const ValueKey('koach-ask-view'),
      pose: _why ? widget.whyPose : widget.pose,
      height: widget.koachHeight,
      // Largeur fixe : le texte ne bouge pas quand Koach change de pose.
      width: widget.koachHeight * .9,
    );
    final koachLeft = widget.pose.info.bubbleSide == KoachSide.right;
    final style = widget.title ? KType.titreSeance : KType.corps;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: widget.title,
          child: Text(
            widget.text,
            key: const ValueKey('koach-bubble-text'),
            style: style.copyWith(color: k.texte),
          ),
        ),
        KTextButton(
          key: const ValueKey('koach-why'),
          label: _why ? 'Compris' : 'Pourquoi ?',
          onPressed: () => setState(() => _why = !_why),
          dense: true,
          alignStart: true,
        ),
      ],
    );
    final motion = KMotion.standard;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: koachLeft
              ? [
                  koach,
                  const SizedBox(width: KSpacing.s12),
                  Expanded(child: text),
                ]
              : [
                  Expanded(child: text),
                  const SizedBox(width: KSpacing.s12),
                  koach,
                ],
        ),
        AnimatedSize(
          duration: motion.durationIn(context),
          curve: motion.curve,
          alignment: Alignment.topCenter,
          child: _why
              ? Padding(
                  padding: const EdgeInsets.only(top: KSpacing.s4),
                  child: Text(
                    widget.why,
                    key: const ValueKey('koach-why-text'),
                    style: KType.corps.copyWith(color: k.texte2),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Titre d'une carte d'état (arrêt pour douleur, avis médical) : bouclier
/// en `avertissement`, titre en `corpsFort`.
class _StateTitle extends StatelessWidget {
  final String text;
  const _StateTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.shield_outlined,
          size: KSize.iconSmall,
          color: k.avertissement,
        ),
        const SizedBox(width: KSpacing.s8),
        Expanded(
          child: Text(text, style: KType.corpsFort.copyWith(color: k.texte)),
        ),
      ],
    );
  }
}

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
    // Réponse donnée ; le temps disponible et les douleurs déjà dits
    // restent (faits) ; une réponse basse rouvre le détail avec les
    // réponses précédentes.
    final before = store.sessionAdapt(_w, widget.base.j)?.check;
    final low = feelIsLow(overall);
    final j = <String, Object?>{
      if (before != null)
        ...(low
            ? before.toJson()
            : (SessionAdaptStore.factsOf(before)?.toJson() ?? const {})),
      'overall': overall,
    };
    var check = kc.HealthCheck.fromJson(j);
    if (low) {
      final initial = check;
      final detail = await Navigator.of(context).push<kc.HealthCheck>(
        MaterialPageRoute(builder: (_) => HealthDetailScreen(initial: initial)),
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
        padding: const EdgeInsets.fromLTRB(
          KSpacing.page,
          KSpacing.s4,
          KSpacing.page,
          KSpacing.s16,
        ),
        children: _spaced([
          // G10 : ce qui change dans cette séance (propositions de Koach
          // appliquées ou acceptées), au début de la séance concernée.
          if (store.evolutionForSession(_w, widget.base.j).isNotEmpty)
            EvolutionSessionCard(week: _w, j: widget.base.j),
          // CI1g : avis médical demandé par le bloc, pas encore confirmé.
          ...clearanceCard(_w, widget.base.j),
          ..._painStopCard(a),
          ...(!a.asked || _redo ? _question(a) : _answered(a)),
        ]),
      );
    },
  );

  /// CI1b (`kalis_plan` / `kalis_adapt` 0.2.2) : douleur qui dure —
  /// arrêt des mouvements qui chargent la zone (retirés de la séance),
  /// consigne de consulter, reprise graduée écrite dans le bloc. Toujours
  /// en tête de la séance tant qu'elle vaut.
  List<Widget> _painStopCard(SessionAdapt a) {
    final stops = painStopsOf(a.active, store.adaptExerciseName);
    final block = store.adaptPlaceOf(_w, widget.base.j)?.block;
    // Notes du bloc : l'arrêt d'une zone déjà dit par la séance n'est pas
    // répété.
    // CI1d : zones à l'arrêt lues aussi dans les ajustements (le renvoi
    // n'est dans les raisons de la séance qu'une fois par semaine).
    final codes = painStopZoneCodes(a.active);
    final stopped = <int>{
      for (final z in kc.BodyZone.values)
        if (codes.contains(z.code)) z.index,
    };
    final notes = block == null
        ? const <String>[]
        : coachBlockPainNotes(block, store.content.catalog, stopped: stopped);
    if (stops.isEmpty && notes.isEmpty) return const [];
    // CI1d : la consigne de consulter suit le moteur (première séance de
    // l'arrêt, puis une fois par semaine).
    final notice = painStopNoticeZones(a.active);
    final held = painStopHeldZones(a.active);
    final lines = <String>[
      for (final s in stops)
        painStopText(
          s,
          notice: notice.contains(s.zone),
          held: held.contains(s.zone),
        ),
      ...notes,
    ];
    final stopTitle =
        stops.isNotEmpty || (block != null && coachBlockHasPainStop(block));
    final k = KTokens.of(context);
    return [
      KCard(
        key: const ValueKey('health-pain-stop'),
        accent: k.avertissement,
        child: KoachSays(
          pose: koachPose(KoachUsage.care),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StateTitle(stopTitle ? 'Arrêt pour douleur' : 'Reprise graduée'),
              for (final l in lines)
                Padding(
                  padding: const EdgeInsets.only(top: KSpacing.s8),
                  child: Text(l, style: KType.corps.copyWith(color: k.texte)),
                ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _question(SessionAdapt a) => [
    KCard(
      key: const ValueKey('health-question'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KoachWhyHeader(
            pose: koachPose(KoachUsage.healthCheck),
            text: 'Comment tu te sens ?',
            why:
                'Ta réponse règle la séance d’aujourd’hui. Si ça ne va pas, '
                'je te poserai quelques questions, toutes facultatives.',
            title: true,
          ),
          const SizedBox(height: KSpacing.s12),
          LayoutBuilder(
            builder: (context, c) {
              // Cinq tuiles côte à côte ; écran étroit ou grand texte : une
              // tuile par ligne, Koach à gauche du libellé.
              final wide =
                  (c.maxWidth - 4 * KSpacing.s4) / 5 >= _feelTileMinWidth &&
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
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _spaced(tiles, KSpacing.s8),
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    if (i > 0) const SizedBox(width: KSpacing.s4),
                    Expanded(child: tiles[i]),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    ),
    Align(
      child: KTextButton(
        key: const ValueKey('feel-skip'),
        label: 'Passer',
        onPressed: _busy ? null : () => _apply(null, skipped: true),
      ),
    ),
  ];

  List<Widget> _answered(SessionAdapt a) {
    final k = KTokens.of(context);
    final lines = a.check == null
        ? const <String>[]
        : healthCheckLines(a.check!);
    final zones = store.adaptPainReferralZones;
    return [
      // Ce qui change d'abord : la carte de Koach, puis le bilan.
      if (a.base != null) _adjustmentCard(a),
      if (zones.isNotEmpty)
        KCard(
          key: const ValueKey('health-referral'),
          accent: k.avertissement,
          child: KoachSays(
            pose: koachPose(KoachUsage.care),
            child: Text(
              '${zones.join(', ')} : $kPainReferral',
              style: KType.corpsFort.copyWith(color: k.texte),
            ),
          ),
        ),
      KCard(
        key: const ValueKey('health-summary'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                KoachView(
                  key: const ValueKey('koach-header-view'),
                  pose: koachPose(KoachUsage.healthCheck),
                  height: 40,
                  width: 36,
                ),
                const SizedBox(width: KSpacing.s12),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Bilan du jour',
                      style: KType.titreCarte.copyWith(color: k.texte),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: KSpacing.s8),
            if (lines.isEmpty)
              Text(
                'Bilan passé : séance prévue.',
                style: KType.corps.copyWith(color: k.texte2),
              )
            else
              for (final l in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: KSpacing.s4),
                  child: Text(l, style: KType.corps.copyWith(color: k.texte)),
                ),
            const SizedBox(height: KSpacing.s12),
            Wrap(
              spacing: KSpacing.s8,
              runSpacing: KSpacing.s8,
              children: [
                KTonalButton(
                  key: const ValueKey('bilan-redo'),
                  onPressed: () => setState(() => _redo = true),
                  icon: Icons.refresh_rounded,
                  label: 'Refaire le bilan',
                ),
                KTonalButton(
                  key: const ValueKey('bilan-detail'),
                  onPressed: () => _detail(a.check),
                  icon: Icons.edit_note_rounded,
                  label: 'Préciser (douleur, temps…)',
                ),
              ],
            ),
          ],
        ),
      ),
      if (a.base == null)
        KPrimaryButton(
          key: const ValueKey('bilan-start'),
          onPressed: widget.onStart,
          icon: Icons.play_arrow_rounded,
          label: 'Premier exercice',
        ),
    ];
  }

  /// Carte de Koach : ce que l'ajustement du bilan change (6 lignes au
  /// plus), et les choix du mode (assisté : appliqué, « Annuler » ; libre :
  /// « Accepter » / « Garder ma séance »).
  Widget _adjustmentCard(SessionAdapt a) {
    final k = KTokens.of(context);
    final all = sessionDiffLines(a.base!, a.plan, store.adaptExerciseName);
    final shown = all.isEmpty
        ? const ['Charges et cibles un peu plus prudentes.']
        : all.take(6).toList();
    final more = all.length - shown.length;
    final (
      KoachPose pose,
      String head,
      List<(String, String, VoidCallback)> actions,
      bool list,
    ) = switch (a.choice) {
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
          ('adjust-accept', 'Accepter l’ajustement', () => _choose('accepted')),
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
            Text(head, style: KType.corpsFort.copyWith(color: k.texte)),
            if (list) ...[
              const SizedBox(height: KSpacing.s4),
              for (final l in shown)
                Padding(
                  padding: const EdgeInsets.only(top: KSpacing.s4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•', style: KType.corps.copyWith(color: k.texte2)),
                      const SizedBox(width: KSpacing.s8),
                      Expanded(
                        child: Text(
                          l,
                          style: KType.corps.copyWith(color: k.texte),
                        ),
                      ),
                    ],
                  ),
                ),
              if (more > 0)
                Padding(
                  padding: const EdgeInsets.only(top: KSpacing.s4),
                  child: Text(
                    '… et $more autre${more > 1 ? 's' : ''} '
                    'changement${more > 1 ? 's' : ''}.',
                    style: KType.detail.copyWith(color: k.texte2),
                  ),
                ),
            ],
            const SizedBox(height: KSpacing.s12),
            Wrap(
              spacing: KSpacing.s8,
              runSpacing: KSpacing.s8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (var i = 0; i < actions.length; i++)
                  i == 0
                      ? KPrimaryButton(
                          key: ValueKey(actions[i].$1),
                          onPressed: actions[i].$3,
                          label: actions[i].$2,
                          expand: false,
                        )
                      : KTonalButton(
                          key: ValueKey(actions[i].$1),
                          onPressed: actions[i].$3,
                          label: actions[i].$2,
                        ),
                KTextButton(
                  key: const ValueKey('adjust-why'),
                  onPressed: () => showKoachSheet<void>(
                    context,
                    pose: KoachPose.explainBoard,
                    title: 'Pourquoi ?',
                    text: kHealthWhy,
                  ),
                  label: 'Pourquoi ?',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tuile de ressenti : Koach dans la pose du niveau et son libellé, sur
/// `haute`, rayon des cartes (maquette « Bilan du jour »).
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
    final k = KTokens.of(context);
    final label = kFeelLabels[level]!;
    final shape = RoundedRectangleBorder(
      borderRadius: KRadius.cardRadius,
      side: k.controlSide,
    );
    return Semantics(
      button: true,
      label: 'Je me sens : $label',
      excludeSemantics: true,
      child: Material(
        color: k.haute,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          // Koach posé sur la tuile prend sa couleur pour papier.
          child: KoachSurface(
            color: k.haute,
            child: horizontal
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KSpacing.s12,
                      vertical: KSpacing.s8,
                    ),
                    child: Row(
                      children: [
                        KoachView(
                          pose: kFeelPoses[level]!,
                          height: 44,
                          width: 40,
                        ),
                        const SizedBox(width: KSpacing.s12),
                        Expanded(
                          child: Text(
                            label,
                            style: KType.libelle.copyWith(color: k.texte),
                          ),
                        ),
                      ],
                    ),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: _feelTileHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: KSpacing.s4,
                        vertical: KSpacing.s8,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          KoachView(
                            pose: kFeelPoses[level]!,
                            height: 48,
                            width: 44,
                          ),
                          const SizedBox(height: KSpacing.s4),
                          // Même taille pour les cinq libellés ; un libellé
                          // trop large se réduit, il n'est jamais coupé.
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label,
                              maxLines: 1,
                              style: KType.micro.copyWith(color: k.texte),
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

  /// Ouvert depuis « Douleur ou malaise ? » (séance) : la page défile
  /// jusqu'à la section Douleur à l'ouverture.
  final bool focusPain;
  const HealthDetailScreen({
    super.key,
    required this.initial,
    this.focusPain = false,
  });

  @override
  State<HealthDetailScreen> createState() => _HealthDetailScreenState();
}

class _HealthDetailScreenState extends State<HealthDetailScreen> {
  late final Map<String, int?> _v;
  List<kc.PainReport>? _pains;
  int? _minutes;
  final GlobalKey _painKey = GlobalKey();

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
    if (widget.focusPain) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showPain());
    }
  }

  /// Fait défiler la page jusqu'à la section Douleur.
  void _showPain() {
    final target = _painKey.currentContext;
    if (!mounted || target == null) return;
    final motion = KMotion.slow;
    Scrollable.ensureVisible(
      target,
      duration: motion.durationIn(context),
      curve: motion.curve,
    );
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
    final ok = await showKContentSheet<bool>(
      context,
      title: kZoneLabels[zone]!,
      subtitle: 'Douleur',
      closeLabel: null,
      contentKey: const ValueKey('pain-sheet'),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) {
          final k = KTokens.of(ctx);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: KSpacing.s8,
                children: [
                  for (final b in kc.BodySide.values)
                    KChip(
                      kSideLabels[b]!,
                      key: ValueKey('pain-side-${b.code}'),
                      selected: side == b,
                      onTap: () => set(() => side = b),
                    ),
                ],
              ),
              const SizedBox(height: KSpacing.s12),
              Text(
                'Douleur aujourd’hui : ${level.round()}/10',
                style: KType.corpsFort.copyWith(color: k.texte),
              ),
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
                style: KType.detail.copyWith(color: k.texte2),
              ),
              const SizedBox(height: KSpacing.s16),
              KPrimaryButton(
                key: const ValueKey('pain-save'),
                onPressed: () => Navigator.pop(ctx, true),
                label: 'Enregistrer',
              ),
            ],
          );
        },
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

  /// « Aucune douleur » choisi.
  bool get _noPain => _pains != null && _pains!.isEmpty;

  void _removePain(kc.PainReport p) => setState(() {
    final next = [...?_pains]..removeWhere((x) => x.zone == p.zone);
    // Douleur déjà dite puis retirée : « aucune ».
    _pains = next.isEmpty && widget.initial.pains == null ? null : next;
  });

  Widget _title(KTokens k, String t) => Semantics(
    header: true,
    child: Text(t, style: KType.titreCarte.copyWith(color: k.texte)),
  );

  /// Douleurs déclarées : une ligne par zone (zone · côté, n/10), qui
  /// rouvre la feuille de la zone, et « Retirer ».
  Widget _painRows(KTokens k, List<kc.PainReport> pains) => Material(
    color: k.haute,
    shape: KRadius.menuShape,
    clipBehavior: Clip.antiAlias,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < pains.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              thickness: 1,
              indent: KSpacing.s16,
              endIndent: KSpacing.s16,
              color: k.filet,
            ),
          InkWell(
            key: ValueKey('pain-${pains[i].zone.code}'),
            onTap: () => _editPain(pains[i].zone),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: KSize.primary),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: KSpacing.s16,
                  end: KSpacing.s4,
                  top: KSpacing.s8,
                  bottom: KSpacing.s8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${kZoneLabels[pains[i].zone]} · '
                            '${kSideLabels[pains[i].side]!.toLowerCase()}',
                            style: KType.corpsMoyen.copyWith(color: k.texte),
                          ),
                          Text(
                            '${pains[i].intensity}/10',
                            style: KType.detail.copyWith(color: k.texte2),
                          ),
                        ],
                      ),
                    ),
                    KIconButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Retirer',
                      onPressed: () => _removePain(pains[i]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final inset = KNavigationInset.of(context);
    final pains = _pains ?? const <kc.PainReport>[];
    final lit = <String, double>{
      for (final p in pains)
        for (final r in regionsOfZone(p.zone)) r: .35 + .065 * p.intensity,
    };
    final children = <Widget>[
      KCard(
        child: KoachSays(
          pose: koachPose(KoachUsage.care),
          koachHeight: 64,
          child: Text(
            'Dis-moi ce qui ne va pas. Tout est facultatif : ce que tu '
            'laisses vide ne compte pas.',
            style: KType.corps.copyWith(color: k.texte),
          ),
        ),
      ),
      for (final q in _questions)
        KCard(
          key: ValueKey('detail-${q.$1}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title(k, q.$2),
              const SizedBox(height: KSpacing.s4),
              Wrap(
                spacing: KSpacing.s8,
                children: [
                  for (var i = 1; i <= 5; i++)
                    KChip(
                      q.$3[i - 1],
                      key: ValueKey('detail-${q.$1}-$i'),
                      selected: _v[q.$1] == i,
                      // Un appui sur le choix déjà fait le retire.
                      onTap: () =>
                          setState(() => _v[q.$1] = _v[q.$1] == i ? null : i),
                    ),
                ],
              ),
            ],
          ),
        ),
      KeyedSubtree(
        key: _painKey,
        child: KCard(
          key: const ValueKey('detail-pains'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title(k, 'Douleur'),
              const SizedBox(height: KSpacing.s4),
              Text(
                'Touche la zone sur la carte, ou choisis-la dans la liste.',
                style: KType.detail.copyWith(color: k.texte2),
              ),
              const SizedBox(height: KSpacing.s4),
              KChip(
                'Aucune douleur',
                key: const ValueKey('detail-no-pain'),
                selected: _noPain,
                onTap: () => setState(() => _pains = _noPain ? null : []),
              ),
              const SizedBox(height: KSpacing.s8),
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
              const SizedBox(height: KSpacing.s8),
              Wrap(
                spacing: KSpacing.s8,
                children: [
                  for (final z in kc.BodyZone.values)
                    KChip(
                      kZoneLabels[z]!,
                      key: ValueKey('pain-zone-${z.code}'),
                      onTap: () => _editPain(z),
                    ),
                ],
              ),
              if (pains.isNotEmpty) ...[
                const SizedBox(height: KSpacing.s8),
                _painRows(k, pains),
              ],
              const SizedBox(height: KSpacing.s4),
              KTextButton(
                key: const ValueKey('detail-safety'),
                label: 'Conseils de sécurité',
                icon: Icons.health_and_safety_outlined,
                alignStart: true,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SafetyScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
      KCard(
        key: const ValueKey('detail-minutes'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title(k, 'Temps disponible aujourd’hui'),
            const SizedBox(height: KSpacing.s4),
            Wrap(
              spacing: KSpacing.s8,
              children: [
                for (final m in _minuteChoices)
                  KChip(
                    '$m min',
                    key: ValueKey('detail-minutes-$m'),
                    selected: _minutes == m,
                    onTap: () =>
                        setState(() => _minutes = _minutes == m ? null : m),
                  ),
              ],
            ),
          ],
        ),
      ),
      KPrimaryButton(
        key: const ValueKey('detail-save'),
        onPressed: () => Navigator.pop(context, _result()),
        label: 'Valider mon bilan',
      ),
      Align(
        child: KTextButton(
          key: const ValueKey('detail-skip'),
          onPressed: () => Navigator.pop(context, widget.initial),
          label: 'Passer',
        ),
      ),
    ];
    return Scaffold(
      backgroundColor: k.fond,
      appBar: const KTopBar.sub(title: 'Bilan du jour'),
      body: SafeArea(
        top: false,
        bottom: inset == 0,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: KSpacing.maxWidth),
            child: SingleChildScrollView(
              key: const ValueKey('health-detail'),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                KSpacing.page,
                KSpacing.s8,
                KSpacing.page,
                KSpacing.s24 + inset,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _spaced(children),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// « J'ai seulement… minutes » (séance servie par le moteur) : temps
/// disponible ajouté au bilan ; null : annulé ; 0 : temps prévu.
Future<int?> showMinutesSheet(BuildContext context, int? current) async {
  const choices = [20, 30, 45, 60, 75, 90];
  final i = await showKListSheet(
    context,
    title: 'Combien de temps as-tu ?',
    summary: 'Koach raccourcit la séance en gardant l’essentiel.',
    items: [
      for (final m in choices)
        KListItem(
          '$m min',
          icon: Icons.schedule_rounded,
          state: current == m ? KListState.current : KListState.todo,
        ),
      KListItem(
        'Le temps prévu',
        icon: Icons.event_available_rounded,
        state: current == null ? KListState.current : KListState.todo,
      ),
    ],
  );
  if (i == null) return null;
  return i < choices.length ? choices[i] : 0;
}

/// « Je m'entraîne ailleurs » (séance servie par le moteur) : lieu du
/// jour ; null : annulé ; `''` : lieu prévu.
Future<String?> showPlaceChoiceSheet(
  BuildContext context,
  kc.Place? current,
) async {
  const places = kc.Place.values;
  final i = await showKListSheet(
    context,
    title: 'Où t’entraînes-tu aujourd’hui ?',
    summary:
        'Koach remplace ce qui n’est pas faisable sur place par un '
        'équivalent.',
    items: [
      for (final p in places)
        KListItem(
          switch (p) {
            kc.Place.gym => 'En salle',
            kc.Place.home => 'À la maison',
            kc.Place.outdoor => 'Dehors',
          },
          icon: switch (p) {
            kc.Place.gym => Icons.fitness_center_rounded,
            kc.Place.home => Icons.home_rounded,
            kc.Place.outdoor => Icons.park_rounded,
          },
          state: current == p ? KListState.current : KListState.todo,
        ),
      KListItem(
        'Le lieu prévu',
        icon: Icons.event_available_rounded,
        state: current == null ? KListState.current : KListState.todo,
      ),
    ],
  );
  if (i == null) return null;
  return i < places.length ? places[i].code : '';
}
