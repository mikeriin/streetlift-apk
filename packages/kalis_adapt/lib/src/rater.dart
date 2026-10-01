/// Modèle de la note en flammes : bruit de l'estimation du RIR, biais de
/// report, détection des notes peu informatives.
library;

import 'params.dart';

/// Ce que le moteur sait de la façon dont l'utilisateur note ses séries.
final class RatingModel {
  /// Modèle neuf.
  RatingModel();

  RatingModel._copy(RatingModel o) {
    window.addAll(o.window);
  }

  /// Copie indépendante.
  RatingModel fork() => RatingModel._copy(this);

  /// Fenêtre glissante des séries notées : `true` si la série confirme
  /// exactement la cible pré-remplie (mêmes flammes, mêmes répétitions).
  final List<bool> window = <bool>[];

  /// Note une série : [confirmed] si elle confirme la cible telle quelle.
  void note(bool confirmed, AdaptParams p) {
    window.add(confirmed);
    if (window.length > p.lazyWindow) {
      window.removeAt(0);
    }
  }

  /// Part des séries de la fenêtre qui confirment la cible telle quelle.
  double get confirmRate {
    if (window.isEmpty) {
      return 0;
    }
    var confirmed = 0;
    for (final c in window) {
      if (c) {
        confirmed++;
      }
    }
    return confirmed / window.length;
  }

  /// Poids d'une note confirmée, de [AdaptParams.lazyMinWeight] à 1 : 1
  /// tant que la part de confirmations reste ordinaire, puis décroissant.
  double weight(AdaptParams p) {
    if (window.length < p.lazyMinSets) {
      return 1;
    }
    final c = confirmRate;
    if (c <= p.lazyConfirmRate) {
      return 1;
    }
    final w = (1 - c) / (1 - p.lazyConfirmRate);
    return w < p.lazyMinWeight ? p.lazyMinWeight : w;
  }

  /// Écart-type, en répétitions, de l'estimation des répétitions restantes
  /// pour un RIR [rir] et [reps] répétitions faites : croît avec la
  /// distance à l'échec et avec la longueur de la série.
  double rirSd(double rir, int reps, AdaptParams p) {
    var sd = p.rirSdBase + p.rirSdPerRir * rir;
    final n = reps + rir;
    if (n > p.rirSdRepsFrom) {
      sd *= 1 + p.rirSdRepsGain * (n - p.rirSdRepsFrom);
    }
    return sd;
  }

  /// RIR réel attendu pour un RIR dit [rir] (sous-estimation moyenne).
  double trueRir(double rir, AdaptParams p) => rir * (1 + p.rirBias);
}
