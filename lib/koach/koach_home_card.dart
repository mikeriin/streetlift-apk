// G5 (D6.4) : Koach sur la carte du jour de l'accueil (séance du jour sur
// fond de la couleur dominante). Sa pose dit la journée : séance à faire
// (poses d'élan), commencée (« à toi »), faite (victoire), repos (repos).
// Une variante par jour (graine = jour civil, sans stockage). La carte garde
// sa taille : la semaine entière tient toujours à l'écran (L5).
import 'package:kalis_koach/kalis_koach.dart';

import '../models.dart';
import 'koach_bubble.dart';

/// Ce que Koach dit de la journée.
enum KoachDayState { rest, todo, started, done }

/// Koach et la journée du programme.
class KoachToday {
  final DayPlan day;
  final bool done, inProgress;
  final DateTime today;
  const KoachToday({
    required this.day,
    required this.done,
    required this.inProgress,
    required this.today,
  });

  KoachDayState get state => day.exercises.isEmpty
      ? KoachDayState.rest
      : done
      ? KoachDayState.done
      : inProgress
      ? KoachDayState.started
      : KoachDayState.todo;

  /// Pose de Koach.
  KoachPose pose() {
    final n = koachDaySeed(today);
    return switch (state) {
      KoachDayState.rest => koachPose(KoachUsage.rest, n),
      KoachDayState.done => koachPose(KoachUsage.sessionEnd, n),
      KoachDayState.started => KoachPose.you,
      KoachDayState.todo => koachPose(KoachUsage.sessionStart, n),
    };
  }
}
