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
    bias = o.bias;
    biasNotes = o.biasNotes;
    topSaid = o.topSaid;
  }

  /// Mode coach : plus grande réserve dite jusqu'ici par une note fermée
  /// (de 2 à 9 flammes), ou `null`. Une personne ne sait pas dire plus
  /// qu'un certain nombre de répétitions en réserve : sa note la plus
  /// haute se lit comme « au moins tant ».
  double? topSaid;

  /// Note une réserve dite [rir] par une note fermée.
  void noteSaid(double rir) {
    final top = topSaid;
    if (top == null || rir > top) {
      topSaid = rir;
    }
  }

  /// Réserve dite à partir de laquelle une note ne se lit que comme une
  /// borne basse : la plus haute réserve que la personne ait jamais dite,
  /// au moins [AdaptParams.coachCensorRir].
  double ceiling(AdaptParams p) {
    final top = topSaid;
    return top == null || top < p.coachCensorRir ? p.coachCensorRir : top;
  }

  /// Biais de report appris (mode coach), ou `null` : celui des
  /// paramètres.
  double? bias;

  /// Nombre de tests qui ont corrigé [bias].
  int biasNotes = 0;

  /// Corrige le biais d'après un test mené près de l'échec : [innovation]
  /// est l'écart, en répétitions, entre ce que le test montre et ce que
  /// les séries notées laissaient prévoir. Un test qui montre plus que
  /// prévu dit que les notes sous-estiment la réserve davantage que
  /// supposé.
  void learn(double innovation, AdaptParams p) {
    final current = bias ?? p.rirBias;
    var step = p.biasLearnRate * innovation / p.biasLearnRir;
    if (step > p.biasLearnMaxStep) {
      step = p.biasLearnMaxStep;
    }
    if (step < -p.biasLearnMaxStep) {
      step = -p.biasLearnMaxStep;
    }
    final next = current + step;
    bias = next < p.biasMin ? p.biasMin : (next > p.biasMax ? p.biasMax : next);
    biasNotes++;
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
  double trueRir(double rir, AdaptParams p) => rir * (1 + (bias ?? p.rirBias));
}
