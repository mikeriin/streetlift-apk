// M56 (brouillon M6) : carte « Koach · séance du jour », en tête de la séance.
//
// Avant 5.5.0, les indications de Koach pour la séance du jour s'affichaient
// au-dessus du premier exercice, dans la page de l'exercice (questionnaire
// d'avant séance D14, jour de fatigue D25), et le bandeau d'adaptation de la
// séance (L11 : reprise, maladie, semaine allégée, décharge, séance
// recomposée ou raccourcie) sous le compteur d'exercices. Ils sont réunis ici,
// dans une carte distincte des cartes d'exercice, placée en tête de la
// séance (première page, avant la liste des exercices) : résumé d'une
// ligne une fois repliée. Aucune logique de Koach
// ne change : mêmes conditions d'affichage, mêmes textes, mêmes actions
// (accepter, ignorer, détails), selon le mode Assisté ou Automatique.
// Les indications propres à un exercice (suggestion de charge, série de
// calibrage) restent sur l'exercice.
//
// Sans rien à dire (Koach désactivé, aucun ajustement, questionnaire passé
// ou non demandé), la carte n'apparaît pas : une ligne neutre répétée à
// chaque séance serait du bruit, et l'en-tête de séance reste compact.
import 'package:flutter/material.dart';
import 'package:kalis_koach/kalis_koach.dart' show KoachPose;

import 'adapt_screens.dart' show AdaptSessionBanner;
import 'app_theme.dart';
import 'koach/koach_view.dart';
import 'koach_widgets.dart';
import 'models.dart';
import 'store.dart';
import 'ui.dart';

class KoachDayCard extends StatefulWidget {
  final int week;

  /// Séance du programme (adaptation, L11) et séance affichée (fatigue).
  final DayPlan base, day;

  /// Après une action qui change les séries (fatigue acceptée, adaptation).
  final VoidCallback? onChanged;

  const KoachDayCard({
    super.key,
    required this.week,
    required this.base,
    required this.day,
    this.onChanged,
  });

  /// Repli choisi pendant la session, par séance.
  static final Map<String, bool> _folded = {};

  @visibleForTesting
  static void debugReset() => _folded.clear();

  @override
  State<KoachDayCard> createState() => KoachDayCardState();
}

/// Contenu de la carte à un instant donné (aussi pour les tests).
class KoachDayContent {
  final bool questions;
  final double fatigueLevel;
  final int fatigueSets;
  final String adaptSummary;
  final List<String> adaptLines;
  const KoachDayContent({
    required this.questions,
    required this.fatigueLevel,
    required this.fatigueSets,
    required this.adaptSummary,
    required this.adaptLines,
  });

  bool get fatigue => fatigueSets > 0 && store.autonomyMode != 'guided';
  bool get isEmpty => !questions && !fatigue && adaptSummary.isEmpty;

  factory KoachDayContent.of(int week, DayPlan base, DayPlan day) {
    final j = day.j;
    final koach = store.koachOn && week >= 1;
    final level = koach ? store.koachFatigueLevel(week, j, day.exercises) : 0.0;
    final cut = level > 0
        ? store
              .koachFatigueCut(week, j, day.exercises, level)
              .values
              .fold<int>(0, (a, b) => a + b)
        : 0;
    var summary = '';
    var lines = const <String>[];
    if (week >= 1) {
      final info = store.adaptInfo(week, base.j);
      final compressed = store.adaptCompressed(week, base.j);
      summary = AdaptSessionBanner.summary(info, compressed);
      lines = AdaptSessionBanner.lines(info, compressed);
    }
    return KoachDayContent(
      questions: koach && store.koachAskBefore(week, j),
      fatigueLevel: level,
      fatigueSets: cut,
      adaptSummary: summary,
      adaptLines: lines,
    );
  }

  /// Résumé d'une ligne (carte repliée).
  String summary(String sessionKey) {
    final parts = <String>[];
    if (questions) {
      final a = store.koach.answers[sessionKey];
      parts.add(
        a == null || (a.sleep == null && a.form == null)
            ? 'Sommeil et forme à noter'
            : _capitalize(
                [
                  if (a.sleep != null) 'sommeil ${_sleepLabel(a.sleep!)}',
                  if (a.form != null) 'forme ${a.form}/10',
                ].join(', '),
              ),
      );
    }
    if (fatigue) {
      parts.add(
        'Fatigue probable : −${(fatigueLevel * 100).round()} % proposé',
      );
    }
    if (adaptSummary.isNotEmpty) parts.add(adaptSummary);
    return parts.join(' · ');
  }

  static String _capitalize(String t) =>
      t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);

  static String _sleepLabel(double v) {
    for (final (label, value) in koachSleepOptions) {
      if (value == v) return label;
    }
    return '${v.toStringAsFixed(1)} h';
  }
}

class KoachDayCardState extends State<KoachDayCard> {
  String get _key => store.sessionKey(widget.week, widget.day.j);

  bool get folded => KoachDayCard._folded[_key] ?? false;

  void toggle() => setState(() => KoachDayCard._folded[_key] = !folded);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final c = KoachDayContent.of(widget.week, widget.base, widget.day);
      if (c.isEmpty) return const SizedBox.shrink();
      return _card(context, c);
    },
  );

  Widget _card(BuildContext context, KoachDayContent c) {
    final w = widget.week, j = widget.day.j;
    final summary = c.summary(_key);
    final header = Semantics(
      button: true,
      expanded: !folded,
      label:
          'Koach, séance du jour : $summary. '
          '${folded ? 'Déplier' : 'Replier'}',
      excludeSemantics: true,
      child: InkWell(
        key: const ValueKey('koach-day-toggle'),
        borderRadius: BorderRadius.circular(12),
        onTap: toggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              // G5 (D6.4) : Koach en personne (pose selon le sujet).
              KoachView(
                key: const ValueKey('koach-day-view'),
                pose: c.questions
                    ? KoachPose.checklist
                    : c.fatigue
                    ? KoachPose.please
                    : KoachPose.settings,
                height: 44,
                width: 40,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KOACH · SÉANCE DU JOUR',
                      style: TextStyle(
                        fontSize: 11.5,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w800,
                        color: SL.accent,
                      ),
                    ),
                    if (folded)
                      Text(
                        summary,
                        key: const ValueKey('koach-day-summary'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: SL.text),
                      ),
                  ],
                ),
              ),
              Icon(
                folded ? Icons.expand_more : Icons.expand_less,
                color: SL.dim,
              ),
            ],
          ),
        ),
      ),
    );
    final sections = <Widget>[
      if (c.questions) KoachQuestionsCard(sessionKey: _key, bare: true),
      if (c.fatigue)
        KoachFatigueCard(
          bare: true,
          level: c.fatigueLevel,
          sets: c.fatigueSets,
          onAccept: () {
            store.acceptKoachFatigue(
              w,
              j,
              widget.day.exercises,
              c.fatigueLevel,
            );
            widget.onChanged?.call();
          },
          onRefuse: () {
            store.refuseKoachFatigue(w, j, c.fatigueLevel);
            widget.onChanged?.call();
          },
        ),
      if (c.adaptSummary.isNotEmpty) _adaptation(context, c),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: KCard(
        key: const ValueKey('koach-day-card'),
        accent: SL.bordeaux,
        radius: 16,
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            if (!folded)
              Padding(
                key: const ValueKey('koach-day-content'),
                padding: const EdgeInsets.only(top: 8, right: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < sections.length; i++) ...[
                      if (i > 0) Divider(height: 20, color: SL.line),
                      sections[i],
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Adaptation de la séance (L11) : une phrase par ajustement, avec sa
  /// raison ; détails et choix dans la même fiche qu'avant.
  Widget _adaptation(BuildContext context, KoachDayContent c) => Column(
    key: const ValueKey('adapt-session-banner'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          const Icon(Icons.tune_rounded, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Séance adaptée',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      for (final t in c.adaptLines)
        Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $t')),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          key: const ValueKey('koach-day-adapt-details'),
          onPressed: () => AdaptSessionBanner.showDetails(
            context,
            widget.week,
            widget.base,
            widget.onChanged,
          ),
          child: const Text('Détails'),
        ),
      ),
    ],
  );
}
