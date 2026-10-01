// G5 (D6.4) : carte du jour de l'accueil — Koach annonce la séance du jour
// (ou le repos, ou la séance commencée, ou la séance faite). Affichée
// seulement sur la semaine actuelle, quand aujourd'hui est un jour du
// programme. Variante de pose : une par jour (graine = jour civil, sans
// stockage).
import 'package:flutter/material.dart';
import 'package:kalis_koach/kalis_koach.dart';

import '../models.dart';
import '../store.dart';
import 'koach_bubble.dart';

/// Ce que Koach dit de la journée.
enum KoachDayState { rest, todo, started, done }

class KoachHomeCard extends StatelessWidget {
  final DayPlan day;
  final bool done, inProgress;
  final DateTime today;
  final VoidCallback onOpen;
  const KoachHomeCard({
    super.key,
    required this.day,
    required this.done,
    required this.inProgress,
    required this.today,
    required this.onOpen,
  });

  KoachDayState get state => day.exercises.isEmpty
      ? KoachDayState.rest
      : done
      ? KoachDayState.done
      : inProgress
      ? KoachDayState.started
      : KoachDayState.todo;

  /// Texte de la bulle (aussi pour les tests).
  String text() => switch (state) {
    KoachDayState.rest =>
      'Aujourd’hui, c’est récupération. Elle fait partie du programme : '
          'profites-en !',
    KoachDayState.done =>
      'Séance du jour faite : bien joué ! Pense à bien récupérer.',
    KoachDayState.started => 'Ta séance du jour est commencée : on la termine ?',
    KoachDayState.todo => _todo(),
  };

  String _todo() {
    final n = day.exercises.length;
    final d = store.dayEstimate(day).durationLabel;
    final time = RegExp(r'\d').hasMatch(d) ? ', $d' : '';
    return 'Aujourd’hui : ${day.title}. $n exercice${n > 1 ? 's' : ''}'
        '$time. On s’y met ?';
  }

  KoachPose pose() {
    final n = koachDaySeed(today);
    return switch (state) {
      KoachDayState.rest => koachPose(KoachUsage.rest, n),
      KoachDayState.done => koachPose(KoachUsage.sessionEnd, n),
      KoachDayState.started => KoachPose.you,
      KoachDayState.todo => koachPose(KoachUsage.sessionStart, n),
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = state;
    return KeyedSubtree(
      key: const ValueKey('koach-home-card'),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: KoachBubble(
          pose: pose(),
          text: text(),
          koachHeight: 76,
          seed: koachDaySeed(today),
          actions: [
            if (s == KoachDayState.todo)
              KoachBubbleAction(
                'C’est parti',
                onOpen,
                primary: true,
                key: const ValueKey('koach-home-open'),
              ),
            if (s == KoachDayState.started)
              KoachBubbleAction(
                'Reprendre',
                onOpen,
                primary: true,
                key: const ValueKey('koach-home-open'),
              ),
          ],
        ),
      ),
    );
  }
}
