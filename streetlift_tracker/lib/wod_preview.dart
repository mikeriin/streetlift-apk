// Fiche d'un WOD, façon page produit : couverture, accroche, mouvements,
// « pourquoi ça compte », volume et durée, muscles, ton record ; puis le prix,
// l'essai du jour ou le lancement. Le déblocage joue une révélation en place
// (reflet sur la couverture), sans écran modal.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'ui.dart';
import 'estimate_view.dart';
import 'muscle_body.dart';
import 'store.dart';
import 'wod_models.dart';
import 'wod_screen.dart';
import 'wod_store.dart';

class WodPreviewScreen extends StatefulWidget {
  final String wodId;
  final bool fromRunner;
  const WodPreviewScreen({
    super.key,
    required this.wodId,
    this.fromRunner = false,
  });

  @override
  State<WodPreviewScreen> createState() => _WodPreviewScreenState();
}

class _WodPreviewScreenState extends State<WodPreviewScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _celebrated = false;

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  /// Achat : une seule facturation, une seule révélation.
  void _buy(Wod w) {
    final owned = store.unlocked(w);
    if (!store.unlockWod(w) || owned || _celebrated) return;
    _celebrated = true;
    if (store.settings.vibration) HapticFeedback.mediumImpact();
    if (MediaQuery.disableAnimationsOf(context)) {
      _reveal.value = 1;
    } else {
      _reveal.forward(from: 0);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '« ${w.name} » débloqué : gagné à la sueur. Rejoue-le à volonté.',
        ),
      ),
    );
  }

  void _run(Wod w) {
    if (widget.fromRunner) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => WodRunScreen(wodId: w.id)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final matches = store.wods.where((x) => x.id == widget.wodId);
        if (matches.isEmpty) {
          return KScreen(
            appBar: AppBar(),
            body: const Center(child: Text('Ce WOD a été supprimé.')),
          );
        }
        final w = matches.first;
        final estimate = store.wodEstimate(w);
        final muscles = store.wodMuscles(w);
        final unlocked = store.unlocked(w);
        final trial = !unlocked && store.isTrial(w);
        final cost = store.wodCost(w);
        final base = store.basePrice(w);
        final missing = store.missingFor(w);
        final lp = store.levelProgress;
        final best = w.best();
        final attempts = w.results.where((r) => r.completed).length;
        final catalog = store.isCatalog(w);
        return KScreen(
          appBar: AppBar(
            title: Text(w.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              if (catalog && !unlocked)
                IconButton(
                  tooltip: 'Liste d\u2019envies',
                  icon: Icon(
                    store.wished(w)
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: store.wished(w) ? SL.accent : SL.text,
                  ),
                  onPressed: () => store.toggleWish(w),
                ),
            ],
          ),
          body: KList(
            children: [
              // ----- couverture, nom, état -----
              KCard(
                padding: EdgeInsets.zero,
                radius: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: UnlockReveal(
                        progress: _reveal,
                        child: WodCover(
                          wod: w,
                          radius: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        w.typeLabel.toUpperCase(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: KPalette.light,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: .8,
                                        ),
                                      ),
                                    ),
                                    TierChevrons(
                                      w.level,
                                      size: 16,
                                      color: KPalette.light,
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                if (trial || (!unlocked && base > cost))
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: KPalette.light,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      trial
                                          ? 'ESSAI DU JOUR · OFFERT'
                                          : 'VITRINE · −${base - cost}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: KPalette.burgundy,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: .6,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            w.name,
                            style: TextStyle(
                              color: SL.text,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          if (w.header().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              w.header(),
                              style: TextStyle(
                                color: SL.dim,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              KBadge(w.typeLabel, color: SL.accent),
                              KBadge(
                                'Niv. ${w.level}/10 · ${tierLabel(w.level)}',
                              ),
                              KBadge(estimate.durationLabel),
                              if (catalog) WodPriceTag(wod: w),
                              if (w.source.isNotEmpty)
                                Text(
                                  '@${w.source}',
                                  style: TextStyle(
                                    color: SL.dim,
                                    fontSize: 11.5,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // ----- mouvements -----
              _card(
                'Mouvements',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final l in w.lines)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          l,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ),
                    if (w.notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        w.notes,
                        style: TextStyle(
                          color: SL.dim,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // ----- pourquoi ça compte, ton record -----
              _card(
                'Pourquoi ça compte',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeTagline(w),
                      style: TextStyle(
                        color: SL.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      storeWhy(w, estimate, muscles),
                      style: TextStyle(
                        color: SL.dim,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    if (best != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            size: 18,
                            color: SL.accent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ton record : ${best.score} · $attempts tentative${attempts > 1 ? 's' : ''}. La barre est posée.',
                              style: TextStyle(
                                color: SL.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (unlocked || trial) ...[
                      const SizedBox(height: 10),
                      Text(
                        trial
                            ? 'Termine l\u2019essai : ton score reste, et le WOD coûte 1 crédit de moins.'
                            : 'Aucune marque encore. Pose la première.',
                        style: TextStyle(
                          color: SL.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _card(
                'Volume et durée',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EstimateView(estimate: estimate),
                    TextButton.icon(
                      onPressed:
                          () => showEstimate(
                            context,
                            'Détail des mouvements · par passage',
                            estimate,
                          ),
                      icon: const Icon(Icons.list_alt_outlined, size: 17),
                      label: const Text('Détail des mouvements'),
                    ),
                  ],
                ),
              ),
              // ----- muscles -----
              _card(
                'Muscles sollicités',
                Column(
                  children: [
                    MuscleHeatmap(data: muscles, height: 200),
                    const SizedBox(height: 6),
                    MuscleLegend(data: muscles),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: KBottomActions(
            child: _actions(
              w,
              unlocked: unlocked,
              trial: trial,
              cost: cost,
              missing: missing,
              nextLevel: store.level + 1,
              xpLeft: lp.need - lp.inLevel,
            ),
          ),
        );
      },
    );
  }

  Widget _actions(
    Wod w, {
    required bool unlocked,
    required bool trial,
    required int cost,
    required int missing,
    required int nextLevel,
    required int xpLeft,
  }) {
    if (unlocked) {
      return FilledButton.icon(
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(widget.fromRunner ? 'Revenir au chrono' : 'Lancer le WOD'),
        onPressed: () => _run(w),
      );
    }
    final tryButton =
        trial
            ? OutlinedButton.icon(
              icon: const Icon(Icons.bolt_rounded),
              label: const Text('Essayer · offert jusqu\u2019à minuit'),
              onPressed: () => _run(w),
            )
            : null;
    final Widget main =
        missing == 0
            ? FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: SL.action,
                foregroundColor: KPalette.light,
              ),
              icon: const Icon(Icons.lock_open),
              label: Text('Acheter · ${creditsLabel(cost)}'),
              onPressed: () => _buy(w),
            )
            : Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SL.faint,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                'Il te manque ${creditsLabel(missing)} · niveau $nextLevel dans $xpLeft XP',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SL.dim,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            );
    if (tryButton == null) return main;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [tryButton, const SizedBox(height: 8), main],
    );
  }

  Widget _card(String title, Widget child) => KCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KSection(title, topPadding: 0),
        const SizedBox(height: 6),
        child,
      ],
    ),
  );
}
