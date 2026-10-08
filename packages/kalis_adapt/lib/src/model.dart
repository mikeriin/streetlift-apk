/// État du modèle individuel et déroulement d'une séance : a priori,
/// observation des séries, prescription des séries, conseil intra-séance.
/// Équations et justifications : `CONTRAT.md`, § Modèle et § Décisions.
library;

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart' show planSimilarity;

import 'book.dart';
import 'coach.dart';
import 'fatigue.dart';
import 'filter.dart';
import 'numeric.dart';
import 'params.dart';
import 'rater.dart';

/// Douleur qui dure (CX, correction 1, sécurité) : intensité à partir de
/// laquelle une gêne compte (3 sur 10 : au-delà de la zone « continue » de
/// la règle de douleur, R5-P23 ; Silbernagel et al. 2007).
const int painPersistMin = 3;

/// Durée d'une gêne au même niveau qui demande l'arrêt et un avis : plus
/// de deux semaines (NHS, douleur du poignet : consulter si elle ne
/// s'améliore pas en deux semaines ou revient).
const int painPersistDays = 14;

/// Écart toléré entre deux signalements d'un même épisode (choix
/// raisonné : une séance manquée ou un jour sans bilan ne coupe pas un
/// épisode ; deux semaines, la durée même du seuil de persistance, pour
/// qu'une gêne signalée une fois par semaine ou moins reste un épisode).
const int painEpisodeGapDays = 14;

/// Jours à 2 sur 10 au plus avant de lever l'arrêt (relecture documentée
/// CX : reprise seulement après deux semaines à 2 sur 10 au plus).
const int painResumeDays = 14;

/// Gêne forte (5 sur 10 et plus) plus de sept jours : arrêt et renvoi vers
/// le kinésithérapeute (relecture documentée CX, `street_12`).
const int painStrongMin = 5;

/// Durée de la gêne forte qui déclenche l'arrêt.
const int painStrongDays = 7;

/// Fenêtre où un nouvel épisode compte comme un retour de la douleur
/// (douze semaines, choix raisonné).
const int painRecurDays = 84;

/// Arrêt d'une zone : douleur qui dure, qui revient après une reprise, ou
/// forte plus d'une semaine.
final class PainStop {
  /// Arrêt de la zone [zone].
  const PainStop({
    required this.zone,
    required this.sessions,
    required this.intensity,
    required this.recurrence,
  });

  /// Zone.
  final BodyZone zone;

  /// Séances de l'épisode en cours où la gêne a été signalée à 3 sur 10 ou
  /// plus.
  final int sessions;

  /// Plus forte intensité de l'épisode.
  final int intensity;

  /// Vrai quand la douleur est revenue après une accalmie.
  final bool recurrence;
}

/// Suivi d'une zone douloureuse.
final class PainState {
  /// Suivi de la zone [zone].
  PainState(this.zone, this.side);

  /// Zone.
  final BodyZone zone;

  /// Côté du dernier signalement.
  BodySide side;

  /// Séances où la zone a été signalée.
  int sessionsReported = 0;

  /// Dernière intensité signalée.
  int lastIntensity = 0;

  /// Séances de suite au-dessus du seuil.
  int consecutiveAbove = 0;

  /// Jour du dernier signalement.
  int lastDay = 0;

  /// Jour du dernier signalement au-dessus du seuil, ou `null`.
  int? lastAboveDay;

  /// Intensité du dernier signalement au-dessus du seuil.
  int lastAboveIntensity = 0;

  /// Signalements datés (jour, intensité), les plus récents à la fin ; une
  /// zone non citée quand la question est posée vaut 0.
  final List<(int, int)> history = <(int, int)>[];

  /// Note un signalement du jour [day] à [intensity].
  void record(int day, int intensity) {
    if (history.isNotEmpty && history.last.$1 == day) {
      final before = history.removeLast();
      history.add((day, intensity > before.$2 ? intensity : before.$2));
    } else {
      history.add((day, intensity));
    }
    if (history.length > 80) {
      history.removeAt(0);
    }
  }

  /// Arrêt en cours au jour [day] (douleur qui dure, qui revient, ou forte
  /// plus d'une semaine, sans deux semaines à 2 sur 10 au plus depuis), ou
  /// `null`.
  PainStop? stopAt(int day, {int? run}) {
    final highs = <(int, int)>[
      for (final h in history)
        if (h.$2 >= painPersistMin && h.$1 <= day) h,
    ];
    if (highs.isEmpty || day - highs.last.$1 >= painResumeDays) {
      return null;
    }
    final episodes = <List<(int, int)>>[];
    for (final h in highs) {
      if (episodes.isEmpty ||
          h.$1 - episodes.last.last.$1 > painEpisodeGapDays) {
        episodes.add(<(int, int)>[h]);
      } else {
        episodes.last.add(h);
      }
    }
    final current = episodes.last;
    final lasting = current.last.$1 - current.first.$1 >= painPersistDays;
    int? strongFirst;
    int? strongLast;
    var worst = 0;
    for (final h in current) {
      if (h.$2 > worst) {
        worst = h.$2;
      }
      if (h.$2 >= painStrongMin) {
        strongFirst ??= h.$1;
        strongLast = h.$1;
      }
    }
    final strong =
        strongFirst != null &&
        strongLast != null &&
        strongLast - strongFirst >= painStrongDays;
    // Retour après une accalmie : un épisode antérieur réel (deux
    // signalements au moins, ou 4 sur 10 et plus) dans les douze semaines.
    var recurrence = false;
    if (episodes.length >= 2) {
      final before = episodes[episodes.length - 2];
      var real = before.length >= 2;
      for (final h in before) {
        if (h.$2 >= painPersistMin + 1) {
          real = true;
        }
      }
      recurrence = real && current.first.$1 - before.last.$1 <= painRecurDays;
    }
    // Séances de suite au-dessus du seuil dans l'épisode en cours, recomptées
    // d'après l'historique jusqu'au jour [day] : un arrêt déclenché par
    // trois séances de suite ne tombe pas au premier signalement plus bas
    // (relecture indépendante du code, CA2 : le compteur courant était
    // remis à zéro).
    var streak = run;
    if (streak == null) {
      var n = 0;
      var best = 0;
      for (final h in history) {
        if (h.$1 > day) {
          break;
        }
        if (h.$1 < current.first.$1) {
          continue;
        }
        n = h.$2 > painPersistMin ? n + 1 : 0;
        if (n > best) {
          best = n;
        }
      }
      streak = best;
    }
    if (!lasting && !strong && !recurrence && streak <= 2) {
      return null;
    }
    return PainStop(
      zone: zone,
      sessions: current.length,
      intensity: worst,
      recurrence: recurrence,
    );
  }

  /// Intensité à montrer pour la zone au jour [day] : la dernière ; si elle
  /// a été levée depuis un signalement au-dessus du seuil encore récent, ce
  /// signalement (la douleur affichée est celle du journal).
  int shownIntensity(int day, int clearDays) {
    final above = lastAboveDay;
    if (lastIntensity > 0 || above == null || day - above > clearDays) {
      return lastIntensity;
    }
    return lastAboveIntensity;
  }

  /// Copie indépendante.
  PainState fork() {
    final c = PainState(zone, side);
    c.sessionsReported = sessionsReported;
    c.lastIntensity = lastIntensity;
    c.consecutiveAbove = consecutiveAbove;
    c.lastDay = lastDay;
    c.lastAboveDay = lastAboveDay;
    c.lastAboveIntensity = lastAboveIntensity;
    c.history.addAll(history);
    return c;
  }

  /// Jour où le dernier arrêt de la zone a été levé (deux semaines sans
  /// signalement à 3 sur 10 ou plus après un arrêt), au plus tard [day],
  /// ou `null` (CA2, partie 0 : reprise graduée conduite par le moteur).
  int? liftedOn(int day) {
    int? lastHigh;
    for (final h in history) {
      if (h.$2 >= painPersistMin && h.$1 <= day) {
        lastHigh = h.$1;
      }
    }
    if (lastHigh == null) {
      return null;
    }
    final lift = lastHigh + painResumeDays;
    if (lift > day) {
      return null;
    }
    // L'arrêt a-t-il eu lieu à l'un des jours de l'épisode ? Les séances de
    // suite au-dessus du seuil se recomptent d'après l'historique (le
    // compteur courant a pu être remis à zéro depuis).
    var run = 0;
    for (final h in history) {
      if (h.$1 > lastHigh) {
        break;
      }
      run = h.$2 > painPersistMin ? run + 1 : 0;
      if (h.$2 >= painPersistMin &&
          lastHigh - h.$1 < painEpisodeGapDays + painPersistDays &&
          stopAt(h.$1, run: run) != null) {
        return lift;
      }
    }
    return null;
  }

  /// Signalements des jours `[from ; to]` (intensités, dans l'ordre).
  List<int> reportsBetween(int from, int to) => <int>[
    for (final h in history)
      if (h.$1 >= from && h.$1 <= to) h.$2,
  ];
}

/// Meilleure série de [bests] (jour, valeur ; les plus récentes à la fin)
/// depuis la dernière coupure d'au moins [gapDays] jours, dans les
/// [windowDays] jours avant [day] ; 0 sans séance récente.
int recentBestOf(List<(int, int)> bests, int day, int gapDays, int windowDays) {
  var best = 0;
  var next = day;
  for (var i = bests.length - 1; i >= 0; i--) {
    final (d, amount) = bests[i];
    if (next - d >= gapDays || day - d > windowDays) {
      break;
    }
    if (amount > best) {
      best = amount;
    }
    next = d;
  }
  return best;
}

/// Ce que le moteur retient d'un exercice d'une séance à l'autre.
final class ExerciseTrack {
  /// Suivi de l'exercice [info] par le filtre [filter].
  ExerciseTrack(this.info, this.filter);

  /// Exercice.
  final ExerciseInfo info;

  /// Filtre de capacité.
  final CapacityFilter filter;

  /// Charge externe de la dernière séance (séries de travail), en kg.
  double? lastLoad;

  /// Vrai si la dernière séance a connu un échec non prévu : pas de hausse.
  bool noUp = false;

  /// Vrai si la dernière séance a été notée nettement plus facile que
  /// visé (au moins [AdaptParams.adviceGapFlames] flammes sous la cible,
  /// cibles atteintes) : la séance suivante monte d'un cran et se fait au
  /// ressenti dans la plage.
  bool easy = false;

  /// Séries de la dernière séance notées nettement plus faciles que visé.
  int easySets = 0;

  /// Plus grande série de la dernière séance (répétitions ou secondes).
  int lastTop = 0;

  /// Niveau habituel de la fatigue brute à l'heure de cet exercice.
  double? fatigueBaseline;

  /// Jour de la dernière série repère.
  int? benchmarkDay;

  /// Mode coach : jour de la dernière série qui mesure la capacité (note
  /// sous le seuil « loin de l'échec », échec) ; au-delà d'un délai, une
  /// série repère est proposée.
  int? exactDay;

  /// Jour de la première séance.
  int? firstDay;

  /// Jour de la dernière séance.
  int? lastDay;

  /// Jour de la dernière reprise après coupure déjà appliquée (transfert
  /// ou désentraînement) : elle n'est pas comptée deux fois quand une
  /// séance ouverte n'a laissé aucune série utilisable.
  int? resumedDay;

  /// Dernier effet de jour observé (hors bilan santé et fatigue prévue).
  double lastResidual = 0;

  /// Séries de travail de la dernière séance.
  int lastSets = 0;

  /// Plus grande valeur d'une série (répétitions ou secondes), record.
  double bestAmount = 0;

  /// Plus grande série menée à bien de chaque séance (jour, répétitions ou
  /// secondes), douze au plus, les plus récentes à la fin.
  List<(int, int)> sessionBests = const <(int, int)>[];

  /// Meilleure série menée à bien depuis la dernière coupure d'au moins
  /// [gapDays] jours (arrêt pour douleur, pause), dans les [windowDays]
  /// jours avant [day] ; 0 sans séance récente (CA2, partie 0 : la tenue
  /// servie part d'un maintien récent, jamais d'un record d'avant un
  /// arrêt).
  int recentBest(int day, int gapDays, int windowDays) =>
      recentBestOf(sessionBests, day, gapDays, windowDays);

  /// Mode coach : dernière séance de chaque emplacement (charge et schéma),
  /// pour borner les hausses à schéma égal.
  Map<String, SlotMark> slotMarks = const <String, SlotMark>{};

  /// Mode coach : barres réussies récemment (jour, charge externe), les
  /// plus lourdes d'abord — une ouverture est une barre déjà faite.
  List<(int, double)> heavy = const <(int, double)>[];

  /// Mode coach : ce que la dernière série repère a montré de la capacité
  /// (répétitions faites plus la réserve dite, au plus celle demandée),
  /// ou `null`.
  double? probeCapacity;

  /// Mode coach, exercice assisté : assistance de la dernière série
  /// (charge externe négative du journal), ou `null`.
  double? assist;

  /// Mode coach, exercice assisté : jour du dernier changement de cran
  /// d'assistance, ou `null`.
  int? assistDay;

  /// Mode coach : performance (logarithme de la capacité du jour) des
  /// dernières séances qui ont mesuré la capacité, trois au plus (jour,
  /// valeur).
  List<(int, double)> form = const <(int, double)>[];

  /// Mode coach : jour où l'alerte de surmenage s'est déclenchée (deux
  /// séances mesurées de suite nettement sous la précédente), ou `null`.
  int? easeDay;

  /// Mode coach : performance des deux séances de l'alerte, en part de la
  /// séance de référence.
  double easeRatio = 1;

  /// Jour d'une série repère qui a montré nettement moins que l'estimation
  /// (lue alors comme une borne basse), ou `null` : une baisse ne se lit
  /// qu'à la deuxième mesure concordante, un autre jour (CX, correction 1).
  int? lowProbeDay;

  /// Copie indépendante.
  ExerciseTrack fork() {
    final c = ExerciseTrack(info, filter.fork());
    c.lowProbeDay = lowProbeDay;
    c.assist = assist;
    c.assistDay = assistDay;
    c.form = form;
    c.easeDay = easeDay;
    c.easeRatio = easeRatio;
    c.probeCapacity = probeCapacity;
    c.lastLoad = lastLoad;
    c.noUp = noUp;
    c.easy = easy;
    c.easySets = easySets;
    c.lastTop = lastTop;
    c.fatigueBaseline = fatigueBaseline;
    c.benchmarkDay = benchmarkDay;
    c.exactDay = exactDay;
    c.firstDay = firstDay;
    c.lastDay = lastDay;
    c.resumedDay = resumedDay;
    c.lastResidual = lastResidual;
    c.lastSets = lastSets;
    c.bestAmount = bestAmount;
    c.sessionBests = sessionBests;
    c.slotMarks = slotMarks;
    c.heavy = heavy;
    return c;
  }
}

/// Alerte de surmenage (mode coach) : suite [form] des performances
/// mesurées (jour, logarithme de la capacité du jour ; trois au plus) après
/// la séance du jour [day] de performance [value], et part de la séance de
/// référence tenue par les deux dernières quand l'alerte se déclenche —
/// deux séances mesurées de suite nettement sous celle d'avant
/// (`coachOverreachDrop`), les trois dans `coachOverreachSpanDays` jours —
/// sinon `null`. La séance d'alerte devient la nouvelle référence.
(List<(int, double)>, double?) formAfter(
  List<(int, double)> form,
  int day,
  double value,
  AdaptParams p,
) {
  final next = <(int, double)>[
    for (final e in form)
      if (e.$1 != day) e,
    (day, value),
  ];
  while (next.length > 3) {
    next.removeAt(0);
  }
  if (next.length == 3 && day - next[0].$1 <= p.coachOverreachSpanDays) {
    final limit = next[0].$2 + ln(1 - p.coachOverreachDrop);
    if (next[1].$2 <= limit && next[2].$2 <= limit) {
      final best = next[1].$2 > next[2].$2 ? next[1].$2 : next[2].$2;
      return (<(int, double)>[next[2]], exp(best - next[0].$2));
    }
  }
  return (next, null);
}

/// Retient dans [track] la performance mesurée [value] de la séance du jour
/// [day] et ouvre, à l'alerte de surmenage, une semaine à volume réduit
/// (`ExerciseTrack.easeDay`) ; voir [formAfter].
void noteForm(ExerciseTrack track, int day, double value, AdaptParams p) {
  final (form, ratio) = formAfter(track.form, day, value, p);
  track.form = form;
  if (ratio != null) {
    track.easeDay = day;
    track.easeRatio = ratio;
  }
}

/// État du modèle individuel après le rejeu du journal.
final class ModelState {
  /// État neuf.
  ModelState(AdaptParams p) : rater = RatingModel(), fatigue = FatigueModel(p);

  ModelState._(this.rater, this.fatigue);

  /// Suivis par exercice, dans l'ordre de première apparition.
  final Map<String, ExerciseTrack> tracks = <String, ExerciseTrack>{};

  /// Modèle de note.
  final RatingModel rater;

  /// Modèle forme / fatigue.
  final FatigueModel fatigue;

  /// Zones douloureuses suivies.
  final Map<BodyZone, PainState> pains = <BodyZone, PainState>{};

  /// Copie indépendante (les séances jouées dessus ne touchent pas
  /// l'original).
  ModelState fork() {
    final c = ModelState._(rater.fork(), fatigue.fork());
    for (final e in tracks.entries) {
      c.tracks[e.key] = e.value.fork();
    }
    for (final e in pains.entries) {
      c.pains[e.key] = e.value.fork();
    }
    return c;
  }

  /// Note la douleur de la zone [zone] pour la séance du jour [day] :
  /// [intensity] est la plus forte intensité signalée ce jour-là.
  void notePain(
    BodyZone zone,
    BodySide side,
    int intensity,
    int day,
    AdaptParams p,
  ) {
    final s = pains.putIfAbsent(zone, () => PainState(zone, side));
    s.side = side;
    s.sessionsReported++;
    s.consecutiveAbove = intensity > p.painThreshold
        ? s.consecutiveAbove + 1
        : 0;
    s.lastIntensity = intensity;
    s.lastDay = day;
    if (intensity > p.painThreshold) {
      s.lastAboveDay = day;
      s.lastAboveIntensity = intensity;
    }
    s.record(day, intensity);
  }

  /// Arrêts en cours au jour [day] (douleur qui dure ou qui revient),
  /// zone par zone dans l'ordre de `BodyZone.values`.
  List<PainStop> painStops(int day) => <PainStop>[
    for (final zone in BodyZone.values)
      if (pains[zone]?.stopAt(day) case final stop?) stop,
  ];

  /// La question des douleurs a été posée au jour [day] et la zone [zone]
  /// n'a pas été citée : elle n'est plus douloureuse.
  void clearPain(BodyZone zone, int day) {
    final s = pains[zone];
    if (s == null) {
      return;
    }
    s.lastIntensity = 0;
    s.consecutiveAbove = 0;
    s.lastDay = day;
    s.record(day, 0);
  }

  /// Vrai si la zone [zone] est encore au-dessus du seuil au jour [day] :
  /// dernier signalement au-dessus du seuil et pas trop ancien.
  bool painActive(BodyZone zone, int day, AdaptParams p) {
    final s = pains[zone];
    if (s == null) {
      return false;
    }
    return s.lastIntensity > p.painThreshold &&
        day - s.lastDay <= p.painClearDays;
  }

  /// Zones qui interdisent une hausse de charge de l'exercice [track] au
  /// jour [day] : douleur encore active, ou signalée au-dessus du seuil
  /// depuis la dernière séance de l'exercice (elle n'est « jamais suivie
  /// d'une charge accrue sur la zone »).
  List<BodyZone> painBlocks(
    ExerciseInfo info,
    int? lastDay,
    int day,
    AdaptParams p,
  ) {
    final out = <BodyZone>[];
    for (final s in pains.values) {
      final above = s.lastAboveDay;
      final since = above != null && (lastDay == null || above >= lastDay);
      if ((painActive(s.zone, day, p) || since) &&
          info.zoneLevel(s.zone) >= 0.5) {
        out.add(s.zone);
      }
    }
    return out;
  }
}

/// Cible d'une série.
final class SetPlan {
  /// Série à la charge externe [loadKg], de [low] à [high] répétitions (ou
  /// secondes), à [flames] flammes.
  const SetPlan({
    required this.loadKg,
    required this.low,
    required this.high,
    required this.flames,
    this.open = false,
    this.benchmark = false,
    this.role,
  });

  /// Charge externe en kg (exercices chargés), sinon `null`.
  final double? loadKg;

  /// Bas de la cible (répétitions ou secondes).
  final int low;

  /// Haut de la cible.
  final int high;

  /// Flammes visées.
  final int flames;

  /// Série ouverte (série repère, ou plage laissée au ressenti).
  final bool open;

  /// Série repère : ouverte, plus près de l'échec que les autres.
  final bool benchmark;

  /// Rôle de la série dans sa technique (mode coach), ou `null`.
  final SetRole? role;

  /// La même cible à une autre charge.
  SetPlan withLoad(double? kg) => SetPlan(
    loadKg: kg,
    low: low,
    high: high,
    flames: flames,
    open: open,
    benchmark: benchmark,
    role: role,
  );
}

/// Place d'un exercice dans une séance : ce que la prescription du bloc
/// en dit.
final class SlotSpec {
  /// Emplacement.
  const SlotSpec({
    required this.low,
    required this.high,
    required this.rir,
    required this.sets,
    required this.restSeconds,
    required this.main,
    required this.benchmarkOk,
    required this.hasTarget,
    this.test = false,
    this.coach,
    this.coachRead = false,
  });

  /// Séance d'un bloc au contrat 0.4.0 dont la prescription n'est plus
  /// connue (bloc précédent) : le journal se lit comme en mode coach.
  final bool coachRead;

  /// Vrai si le journal de cet emplacement se lit comme en mode coach
  /// (bornes « charnière », notes isolées lues comme bornes).
  bool get reads => coach != null || coachRead;

  /// Bas de la plage (répétitions ou secondes).
  final int low;

  /// Haut de la plage.
  final int high;

  /// RIR visé.
  final double rir;

  /// Nombre de séries.
  final int sets;

  /// Repos entre les séries, en secondes.
  final int restSeconds;

  /// Mouvement principal de la séance.
  final bool main;

  /// Une série repère est permise (semaine de montée, effort assez haut).
  final bool benchmarkOk;

  /// La prescription porte une cible de difficulté.
  final bool hasTarget;

  /// Séries de test.
  final bool test;

  /// Lecture « coach » de la prescription (bloc qui porte les champs de
  /// `kalis_core` 0.4.0), ou `null` : règle générale de 0.1.
  final CoachSpec? coach;

  /// Haut de plage étendu quand la charge suivante n'est pas atteignable.
  int get highExtended => high + (high + 2) ~/ 3;

  /// Plafond de répétitions quand aucune charge plus lourde n'est possible :
  /// le double du haut de plage, 30 au plus.
  int get wideTop {
    final wide = 2 * high > 30 ? 30 : 2 * high;
    return wide > highExtended ? wide : highExtended;
  }
}

/// Série observée pendant la séance en cours (ce que le conseil et les
/// apprentissages de fin d'exercice relisent).
final class ObservedSet {
  /// Série.
  const ObservedSet({
    required this.loadKg,
    required this.amount,
    required this.flames,
    required this.failed,
    required this.unplannedFail,
    required this.open,
    required this.target,
    this.rir = 0,
    this.quality,
    this.role,
  });

  /// Charge externe, en kg.
  final double? loadKg;

  /// Répétitions ou secondes faites.
  final int amount;

  /// Flammes notées.
  final int? flames;

  /// Série menée à l'échec ou manquée.
  final bool failed;

  /// Échec qui n'était pas prévu par la cible.
  final bool unplannedFail;

  /// Série ouverte.
  final bool open;

  /// Cible affichée.
  final SetPlan? target;

  /// Réserve estimée par le modèle après la série, en répétitions.
  final double rir;

  /// Propreté déclarée (1 à 5), ou `null`.
  final int? quality;

  /// Rôle de la ligne dans sa technique, ou `null`.
  final SetRole? role;
}

/// Un exercice en cours dans une séance.
final class ExerciseRun {
  /// Exercice [info] à l'emplacement [spec].
  ExerciseRun(this.info, this.spec);

  /// Exercice.
  final ExerciseInfo info;

  /// Emplacement.
  final SlotSpec spec;

  /// Suivi (absent tant qu'aucun a priori ni série n'existe).
  ExerciseTrack? track;

  /// L'estimation est encore incertaine : RIR visé relevé.
  bool uncertain = true;

  /// Calibrage : plafonds de hausse élargis.
  bool calibrating = true;

  /// RIR visé de la séance (cible + bonus de calibrage, de santé, de
  /// douleur).
  double rirEff = 0;

  /// Répétitions jusqu'à l'échec de référence de la séance.
  double nPlan = 1;

  /// Décalage prévu de l'effet de jour (fatigue, bilan santé).
  double baseShift = 0;

  /// Écart de la fatigue brute à son niveau habituel.
  double rawDeviation = 0;

  /// Fatigue brute à l'ouverture.
  double raw = 0;

  /// Échecs non prévus de la séance.
  int fails = 0;

  /// Mode coach : une série de la séance a mesuré la capacité (série
  /// ouverte ou test près de l'échec, répétitions manquantes).
  bool measured = false;

  /// Mode coach : la séance du jour est servie en séries fractionnées
  /// (plus de lignes que le bloc n'en écrit, plus courtes).
  bool split = false;

  /// Mode coach : lignes retenues pour la séance (gel sur une zone
  /// douloureuse, alerte de surmenage), ou `null`.
  int? lines;

  /// Séries notées face à une cible.
  int ratedSets = 0;

  /// Séries notées nettement plus faciles que visé, cible atteinte.
  int easySets = 0;

  /// La dernière série notée était nettement plus facile que visé.
  bool lastRatedEasy = false;

  /// La séance précédente était nettement plus facile que visé : séries au
  /// ressenti dans la plage.
  bool easyMode = false;

  /// Séries observées.
  final List<ObservedSet> observed = <ObservedSet>[];

  /// Cibles des séries (prescription ou conseil), par rang.
  List<SetPlan?> plan = <SetPlan?>[];

  /// Zones douloureuses qui interdisent une hausse.
  List<BodyZone> painZones = const <BodyZone>[];

  /// Raison pour laquelle la charge n'a pas monté, ou `null`.
  String? heldCause;

  /// Le plus petit pas de la grille dépasse le plafond : la plage s'étend.
  bool coarse = false;

  /// Clé de l'exercice dans la séance (emplacement, exercice, rang), ou
  /// `null` : des séries enchaînées avec un autre exercice (superset,
  /// tours) retrouvent le même déroulement.
  String? key;

  /// Rang de l'effet de jour de cet exercice parmi ceux de la séance.
  int? dayIndex;

  /// Vrai une fois les apprentissages de fin d'exercice faits.
  bool closed = false;

  /// Mode coach : raisons des décisions prises pour cet exercice.
  final List<Reason> notes = <Reason>[];

  /// Mode coach : la technique du bloc n'est pas servie aujourd'hui.
  bool techniqueWithheld = false;

  /// Mode coach : la semaine interdit toute hausse de charge (allègement,
  /// affûtage, test, compétition).
  bool lockUp = false;

  /// Mode coach : plafond de hausse d'une séance à l'autre, ou `null` :
  /// ceux de 0.1.
  double? riseCap;

  /// Mode coach : mouvement en reprise graduée après une douleur qui dure
  /// (écrite par le bloc ou conduite par le moteur) — jamais au-dessus de
  /// la dose écrite, loin de l'échec, sans série repère (CA2, partie 0).
  bool inReturn = false;

  /// Mode coach : dose écrite jamais dépassée ce jour (reprise graduée,
  /// appui du poignet sensible) — ni séries ajoutées, ni plage étendue,
  /// ni tenue allongée au-delà de l'écrit.
  bool doseCapped = false;

  /// Mode coach : mouvement qui charge une zone à l'arrêt ou sortie d'un
  /// arrêt depuis moins de douze semaines — la quantité par série monte de
  /// 10 % au plus (une répétition ou une seconde au moins) d'une séance à
  /// la suivante, même quand le bloc écrit davantage (CA2, partie 0 ;
  /// Soligard et al. 2016).
  bool recentZone = false;

  /// Mode coach : part du 1RM la plus haute permise pendant une reprise
  /// graduée conduite par le moteur, ou `null`.
  double? returnPct;

  /// Mode coach : le jour suit un affûtage — le maximum du jour des
  /// tentatives compte le gain d'affûtage (`coachTaperGain`).
  bool tapered = false;

  /// Vrai si l'exercice a un filtre ouvert.
  bool get modelled => track != null;
}

/// Ce dont une séance a besoin pour se dérouler.
final class EngineContext {
  /// Contexte.
  EngineContext({
    required this.catalog,
    required this.profile,
    required this.params,
  }) : book = ExerciseBook(catalog, profile);

  /// Catalogue.
  final Catalog catalog;

  /// Profil.
  final AthleteProfile profile;

  /// Paramètres.
  final AdaptParams params;

  /// Informations par exercice.
  final ExerciseBook book;

  /// Niveau d'expérience (0 débutant … 3 élite) pour les a priori.
  int get level {
    final e = profile.experience;
    return e == null ? 1 : e.index;
  }
}

/// Déroulement d'une séance sur un état du modèle : observation des
/// séries, prescription, conseil.
final class SessionRun {
  /// Ouvre une séance au jour [day].
  SessionRun(
    this.ctx,
    this.state, {
    required this.day,
    required this.health,
    required this.bodyWeightKg,
    this.extraRir = 0,
    this.noIncrease = false,
  }) {
    state.fatigue.advance(day, ctx.params);
  }

  /// Contexte.
  final EngineContext ctx;

  /// État du modèle (modifié par la séance).
  final ModelState state;

  /// Jour de la séance.
  final int day;

  /// Lecture du bilan santé.
  final HealthReading health;

  /// Poids de corps du jour, en kg.
  final double bodyWeightKg;

  /// RIR ajouté à toutes les cibles (bilan santé bas).
  final double extraRir;

  /// Aucune hausse de charge aujourd'hui (bilan santé bas).
  final bool noIncrease;

  /// Exercice en cours.
  ExerciseRun? current;

  final List<double> _dayResiduals = <double>[];
  final List<double> _dayWeights = <double>[];

  /// Exercices de la séance qui ont des séries et attendent leur clôture,
  /// dans l'ordre d'ouverture.
  final List<ExerciseRun> _pending = <ExerciseRun>[];

  /// Exercices clos de la séance, dans l'ordre de clôture.
  final List<ExerciseRun> closed = <ExerciseRun>[];

  AdaptParams get _p => ctx.params;

  // ---------------------------------------------------------------- a priori

  /// A priori de l'exercice [info] tiré du profil (niveau déclaré) ou d'un
  /// exercice proche déjà suivi ; `null` si rien n'est connu.
  ExerciseTrack? _priorFor(ExerciseInfo info, SlotSpec spec) {
    final mode = info.mode;
    if (mode == null) {
      return null;
    }
    final p = _p;
    final level = ctx.level;
    final v = p.trendPrior[level];
    final vSd = p.trendPriorSd[level];
    final k0 = info.lowerBody ? p.kLowerBody : p.kGeneral;
    final nRef = (spec.low + spec.high) / 2 + spec.rir;
    for (final declared in ctx.profile.movementLevels) {
      final low = declared.low;
      final high = declared.high;
      if (declared.exerciseId != info.id ||
          !declared.known ||
          low == null ||
          high == null ||
          low <= 0 ||
          high < low) {
        continue;
      }
      final spread = ln(high / low) / 3.4641016151377544; // √12 : loi uniforme
      final sd = sqrt(spread * spread + sq(p.priorSdDeclared));
      switch (declared.measure) {
        case LevelMeasure.oneRmKg:
          if (mode != CapacityMode.loaded) {
            continue;
          }
          final lowTotal = info.totalLoad(low, bodyWeightKg);
          final highTotal = info.totalLoad(high, bodyWeightKg);
          if (lowTotal <= 0) {
            continue;
          }
          return ExerciseTrack(
            info,
            CapacityFilter.fromOneRm(
              logOneRm: 0.5 * (ln(lowTotal) + ln(highTotal)),
              sd: sqrt(
                sq(ln(highTotal / lowTotal) / 3.4641016151377544) +
                    sq(p.priorSdDeclared),
              ),
              v: v,
              vSd: vSd,
              k: k0,
              kLogSd: p.kLogSd,
              nRef: nRef,
              day: day,
            ),
          );
        case LevelMeasure.maxReps:
          if (mode != CapacityMode.reps) {
            continue;
          }
          return ExerciseTrack(
            info,
            _directFilter(mode, 0.5 * (ln(low) + ln(high)), sd, v, vSd),
          );
        case LevelMeasure.maxHoldSeconds:
          if (mode != CapacityMode.hold) {
            continue;
          }
          return ExerciseTrack(
            info,
            _directFilter(mode, 0.5 * (ln(low) + ln(high)), sd, v, vSd),
          );
        case LevelMeasure.timeSeconds:
          continue;
      }
    }
    if (mode != CapacityMode.loaded) {
      return null;
    }
    // Exercice chargé de la même chaîne de variantes et du même matériel,
    // déjà suivi : son 1RM sert d'a priori large.
    ExerciseTrack? best;
    var bestSimilarity = p.transferMinSimilarity;
    for (final t in state.tracks.values) {
      if (t.info.mode != CapacityMode.loaded ||
          t.info.exercise.rootId != info.exercise.rootId ||
          t.info.exercise.loadType != info.exercise.loadType ||
          t.filter.sessions < 1) {
        continue;
      }
      final s = planSimilarity(t.info.exercise, info.exercise);
      if (s > bestSimilarity ||
          (s == bestSimilarity &&
              best != null &&
              t.info.id.compareTo(best.info.id) < 0)) {
        best = t;
        bestSimilarity = s;
      }
    }
    if (best == null) {
      return null;
    }
    return ExerciseTrack(
      info,
      CapacityFilter.fromOneRm(
        logOneRm: ln(best.filter.capacity),
        sd: sqrt(sq(p.priorSdNeighbour) + sq(best.filter.capacityRelSd)),
        v: v,
        vSd: vSd,
        k: k0,
        kLogSd: p.kLogSd,
        nRef: nRef,
        day: day,
      ),
    );
  }

  CapacityFilter _directFilter(
    CapacityMode mode,
    double c,
    double sd,
    double v,
    double vSd,
  ) {
    return CapacityFilter(
      mode: mode,
      c: c,
      cSd: sd,
      v: v,
      vSd: vSd,
      k: _p.kGeneral,
      kLogSd: 0,
      nRef: 1,
      day: day,
    );
  }

  // ------------------------------------------------------ ouverture, clôture

  /// Ouvre l'exercice [info] à l'emplacement [spec]. L'exercice précédent
  /// est mis en attente : s'il revient sous la même clé [key] (séries
  /// enchaînées), son déroulement reprend là où il en était — même effet
  /// de jour, même fatigue de séries, même compte d'échecs. Les
  /// apprentissages de fin d'exercice se font à [closeAll].
  ExerciseRun begin(ExerciseInfo info, SlotSpec spec, {String? key}) {
    _suspend();
    if (key != null) {
      for (final known in _pending) {
        if (known.key == key && identical(known.info, info)) {
          current = known;
          return known;
        }
      }
    }
    final run = ExerciseRun(info, spec)..key = key;
    current = run;
    run.rirEff = spec.rir;
    run.nPlan = (spec.low + spec.high) / 2 + spec.rir;
    var track = state.tracks[info.id];
    if (track != null && track.filter.inSession) {
      // Le même exercice à un autre emplacement de la séance : le premier
      // déroulement est clos avant d'ouvrir le second.
      for (final other in List<ExerciseRun>.of(_pending)) {
        if (identical(other.track, track)) {
          _finalize(other);
        }
      }
    }
    if (track == null) {
      track = _priorFor(info, spec);
      if (track != null) {
        state.tracks[info.id] = track;
      }
    }
    if (track != null) {
      _open(run, track);
    }
    return run;
  }

  /// Met l'exercice en cours en attente : son effet de jour, tel qu'il est
  /// estimé à ce moment, informe la part commune des exercices suivants.
  void _suspend() {
    final run = current;
    current = null;
    if (run == null) {
      return;
    }
    final track = run.track;
    if (track == null || run.observed.isEmpty) {
      if (track != null && track.filter.inSession && run.observed.isEmpty) {
        // Ouvert pour une prescription, sans série : rien n'est retenu.
        track.filter.inSession = false;
        track.filter.m[3] = 0;
        for (var i = 0; i < 4; i++) {
          track.filter.cov[12 + i] = 0;
          track.filter.cov[4 * i + 3] = 0;
        }
      }
      return;
    }
    if (!_pending.contains(run)) {
      _pending.add(run);
    }
    _noteDayEffect(run);
  }

  void _noteDayEffect(ExerciseRun run) {
    final p = _p;
    final f = run.track!.filter;
    final residual = f.m[3] - run.baseShift;
    final varOwn = (1 - p.dayCommonShare) * sq(p.daySd);
    final weight = 1 / (f.cov[15] + varOwn);
    final index = run.dayIndex;
    if (index == null) {
      run.dayIndex = _dayResiduals.length;
      _dayResiduals.add(residual);
      _dayWeights.add(weight);
    } else {
      _dayResiduals[index] = residual;
      _dayWeights[index] = weight;
    }
  }

  void _open(ExerciseRun run, ExerciseTrack track) {
    final p = _p;
    run.track = track;
    track.filter.hinge = run.spec.reads;
    final info = run.info;
    _resume(track);
    // La courbe pivote sur la plage travaillée quand elle s'est nettement
    // éloignée du pivot : c'est là que le niveau s'apprend sans dépendre
    // de la forme de la courbe. Un petit écart (RIR visé d'une semaine à
    // l'autre) ne déplace rien : chaque déplacement reporte un peu de
    // l'incertitude de la courbe sur le niveau.
    final pivot = track.filter.nRef;
    final away = (run.nPlan - pivot).abs();
    if (away > p.pivotShiftReps && away > p.pivotShiftShare * pivot) {
      track.filter.repivot(run.nPlan);
    }
    final raw = state.fatigue.rawShift(info, p);
    final baseline = track.fatigueBaseline;
    final deviation = baseline == null ? 0.0 : raw - baseline;
    run.raw = raw;
    run.rawDeviation = deviation;
    final base = state.fatigue.gain * deviation + health.shift;
    run.baseShift = base;
    final varCommon = p.dayCommonShare * sq(p.daySd);
    final varOwn = (1 - p.dayCommonShare) * sq(p.daySd);
    var common = 0.0;
    var varCommonNow = varCommon;
    if (_dayWeights.isNotEmpty) {
      var sw = 0.0;
      var swd = 0.0;
      for (var i = 0; i < _dayWeights.length; i++) {
        sw += _dayWeights[i];
        swd += _dayWeights[i] * _dayResiduals[i];
      }
      common = swd / (sw + 1 / varCommon);
      varCommonNow = 1 / (sw + 1 / varCommon);
    }
    track.filter.beginSession(
      day,
      base + common,
      sqrt(varCommonNow + varOwn),
      p,
    );
    run.painZones = state.painBlocks(info, track.lastDay, day, p);
    _settle(run);
  }

  /// Après une coupure : la pente propre n'est plus extrapolée ; le niveau
  /// suit, pour une part, les exercices proches qui ont continué, sinon il
  /// décroît lentement (désentraînement).
  void _resume(ExerciseTrack track) {
    final p = _p;
    final lastSession = track.lastDay;
    if (lastSession == null) {
      return;
    }
    final resumed = track.resumedDay;
    final last = resumed != null && resumed > lastSession
        ? resumed
        : lastSession;
    if (day - last <= 14 || track.filter.inSession) {
      return;
    }
    track.resumedDay = day;
    track.filter.m[1] = 0;
    var weight = 0.0;
    var change = 0.0;
    final neighbours = <(double, ExerciseTrack)>[];
    for (final t in state.tracks.values) {
      final tLast = t.lastDay;
      if (identical(t, track) ||
          t.info.mode != track.info.mode ||
          tLast == null ||
          tLast <= last ||
          t.filter.history.isEmpty) {
        continue;
      }
      final s = planSimilarity(t.info.exercise, track.info.exercise);
      if (s >= p.transferMinSimilarity) {
        neighbours.add((s, t));
      }
    }
    neighbours.sort((a, b) {
      final bySimilarity = b.$1.compareTo(a.$1);
      return bySimilarity != 0
          ? bySimilarity
          : a.$2.info.id.compareTo(b.$2.info.id);
    });
    for (var i = 0; i < neighbours.length && i < p.transferNeighbours; i++) {
      final (s, t) = neighbours[i];
      var before = t.filter.history.first.level;
      for (final point in t.filter.history) {
        if (point.day <= last) {
          before = point.level;
        }
      }
      weight += s;
      change += s * (t.filter.history.last.level - before);
    }
    if (weight > 0) {
      final delta = p.transferShare * change / weight;
      track.filter.shiftLevel(delta, sq(0.5 * delta) + sq(0.01));
    } else if (day - last > p.detrainFromDays) {
      final delta = -p.detrainPerWeek * (day - last - p.detrainFromDays) / 7;
      track.filter.shiftLevel(delta, sq(0.5 * delta) + sq(0.01));
    }
  }

  /// Fixe l'incertitude et le RIR visé de la séance pour l'exercice.
  void _settle(ExerciseRun run) {
    final p = _p;
    final track = run.track!;
    final sd = track.filter.loadSd(run.nPlan, withDay: false);
    run.uncertain = sd > p.calibrationSd;
    run.calibrating =
        run.uncertain && track.filter.sessions < p.calibrationSessions;
    run.easyMode =
        track.easy &&
        !track.noUp &&
        !noIncrease &&
        run.painZones.isEmpty &&
        !run.spec.test;
    var rir = run.spec.rir + extraRir;
    if (run.uncertain && !run.spec.test && run.spec.coach == null) {
      // Un test se fait à l'effort demandé : c'est lui qui lève
      // l'incertitude. (Mode coach : la dose du bloc et les garde-fous
      // valent ; l'effort affiché reste celui qui est attendu.)
      rir += p.calibrationRirBonus;
    }
    if (run.painZones.isNotEmpty) {
      rir += p.painRirBonus;
    }
    run.rirEff = rir > 5 ? 5 : rir;
  }

  /// Ferme tous les exercices de la séance, dans l'ordre d'ouverture :
  /// apprentissages de fin d'exercice.
  void closeAll() {
    _suspend();
    for (final run in List<ExerciseRun>.of(_pending)) {
      _finalize(run);
    }
  }

  void _finalize(ExerciseRun run) {
    _pending.remove(run);
    if (identical(current, run)) {
      current = null;
    }
    final track = run.track!;
    final p = _p;
    final f = track.filter;
    _noteDayEffect(run);
    final residual = f.m[3] - run.baseShift;
    final variance = f.cov[15];
    final varOwn = (1 - p.dayCommonShare) * sq(p.daySd);
    if (track.fatigueBaseline != null) {
      state.fatigue.learn(
        run.rawDeviation,
        residual + state.fatigue.gain * run.rawDeviation,
        variance + varOwn,
      );
    }
    final baseline = track.fatigueBaseline;
    track.fatigueBaseline = baseline == null
        ? run.raw
        : baseline + p.fatigueBaselineAlpha * (run.raw - baseline);
    track.lastResidual = residual;
    // Charge de référence de la séance suivante : la plus lourde des
    // séries menées à bien, sans échec (un échauffement non marqué ou une
    // pyramide ne la tirent pas vers le bas ; une série arrêtée un peu
    // sous sa cible ne la fait pas baisser, c'est le modèle qui en juge) ;
    // après un échec non prévu, la plus légère des charges échouées (la
    // séance suivante ne la dépasse pas ; le modèle dit s'il faut
    // descendre).
    double? held;
    double? lowestFailed;
    double? lowest;
    var openSet = false;
    var top = 0;
    var made = 0;
    for (final o in run.observed) {
      if (o.amount > top) {
        top = o.amount;
      }
      final said = o.flames;
      if (o.failed ||
          (run.spec.reads
              ? run.measured
              : (said != null && rirOfFlames(said) < state.rater.ceiling(p)))) {
        track.exactDay = day;
      }
      final kg = o.loadKg;
      if (kg != null) {
        if (lowest == null || kg < lowest) {
          lowest = kg;
        }
        if (!o.failed && o.amount >= 1 && (held == null || kg > held)) {
          held = kg;
        }
        if (o.unplannedFail && (lowestFailed == null || kg < lowestFailed)) {
          lowestFailed = kg;
        }
      }
      // Série repère. (Mode coach : les séries d'une plage sont toutes
      // « au ressenti » ; seule une série ouverte au-delà du haut de la
      // plage du bloc est une série repère.)
      if (o.open &&
          (!run.spec.reads || (o.target?.high ?? 0) > run.spec.high)) {
        openSet = true;
        final said = o.flames;
        if (run.spec.reads && !o.failed && said != null) {
          final asked = rirOfFlames(o.target!.flames);
          final rir = rirOfFlames(said);
          track.probeCapacity = o.amount + (rir < asked ? rir : asked);
        }
      }
      if (o.amount > track.bestAmount) {
        track.bestAmount = o.amount.toDouble();
      }
      if (!o.failed && o.amount > made) {
        made = o.amount;
      }
    }
    if (made > 0) {
      final bests = <(int, int)>[
        for (final b in track.sessionBests)
          if (b.$1 != day) b,
      ];
      var best = made;
      for (final b in track.sessionBests) {
        if (b.$1 == day && b.$2 > best) {
          best = b.$2;
        }
      }
      bests.add((day, best));
      track.sessionBests = bests.length > 12
          ? bests.sublist(bests.length - 12)
          : bests;
    }
    final easy =
        run.fails == 0 &&
        run.lastRatedEasy &&
        2 * run.easySets >= run.ratedSets;
    if (lowest != null) {
      var reference = held ?? lowest;
      if (lowestFailed != null) {
        reference = lowestFailed;
      }
      // Même exercice déjà fait aujourd'hui avec un échec non prévu : la
      // référence ne remonte pas.
      final earlier = track.lastLoad;
      if (track.lastDay == day &&
          track.noUp &&
          earlier != null &&
          earlier < reference) {
        reference = earlier;
      }
      track.lastLoad = reference;
    }
    track.easy = easy;
    track.easySets = run.easySets;
    // Un échec non prévu plus tôt dans la même séance (même exercice à un
    // autre emplacement) compte aussi ; la plus grande série retenue est
    // alors la plus petite des deux passages.
    final sameDay = track.lastDay == day;
    track.lastTop = sameDay && track.lastTop < top && track.noUp
        ? track.lastTop
        : top;
    track.noUp = run.fails > 0 || (sameDay && track.noUp);
    if (openSet) {
      track.benchmarkDay = day;
    }
    track.firstDay ??= day;
    track.lastDay = day;
    track.lastSets = run.observed.length;
    noteHeavy(track, run, day, p);
    final coach = run.spec.coach;
    if (coach != null) {
      noteCoachSession(track, run, coach, day, p, bodyWeightKg);
      if (run.measured || run.fails > 0) {
        noteForm(track, day, f.m[0] + f.m[3], p);
      }
    }
    f.endSession();
    run.closed = true;
    closed.add(run);
  }

  // ------------------------------------------------------------ observation

  /// Observe une série de l'exercice en cours : [loadKg] charge externe,
  /// [amount] répétitions ou secondes, [flames] note, [missed] cible
  /// manquée sans note, [target] cible affichée, [test] série de test.
  void observe({
    required double? loadKg,
    required int amount,
    required int? flames,
    required bool missed,
    required SetPlan? target,
    bool test = false,
    bool boundOnly = false,
    int? quality,
    SetRole? role,
    int? lineAmount,
  }) {
    final run = current!;
    final info = run.info;
    final mode = info.mode;
    if (mode == null) {
      return;
    }
    final failed = flames == Flames.failure || (flames == null && missed);
    if (mode == CapacityMode.loaded) {
      final total = info.totalLoad(loadKg ?? 0, bodyWeightKg);
      if (total <= 0) {
        return;
      }
      final logLoad = ln(total);
      if (run.track == null) {
        _firstLoaded(run, logLoad, amount, flames, failed);
      }
      _observeLoaded(
        run,
        logLoad,
        loadKg ?? 0,
        amount,
        flames,
        failed,
        target,
        test,
        boundOnly,
        quality,
        role,
        lineAmount ?? amount,
      );
    } else {
      if (run.track == null) {
        _firstDirect(run, mode, amount, flames, failed);
      }
      final track = run.track;
      if (track != null && run.spec.reads && info.exercise.assisted) {
        // Assistance changée depuis la dernière série (cran d'élastique) :
        // la capacité attendue se décale d'un cran, l'incertitude grandit.
        final now = loadKg ?? 0;
        final before = track.assist;
        if (before != null && (now - before).abs() > 1e-9) {
          track.assistDay = day;
          track.probeCapacity = null;
          final step = ln(_p.coachAssistStepShare);
          track.filter.shiftLevel(
            now > before ? step : -step,
            sq(_p.coachAssistStepSd),
          );
        }
        track.assist = now;
      }
      _observeDirect(
        run,
        mode,
        amount,
        flames,
        failed,
        target,
        boundOnly,
        quality,
        role,
        test,
        lineAmount ?? amount,
      );
    }
  }

  /// Première série d'un exercice chargé sans a priori : a priori diffus
  /// centré sur ce qu'elle implique.
  void _firstLoaded(
    ExerciseRun run,
    double logLoad,
    int reps,
    int? flames,
    bool failed,
  ) {
    final p = _p;
    final info = run.info;
    final k0 = info.lowerBody ? p.kLowerBody : p.kGeneral;
    double n;
    if (failed) {
      n = reps + p.failExtraReps;
    } else if (flames == null) {
      n = reps + run.spec.rir;
    } else {
      n = reps + state.rater.trueRir(rirOfFlames(flames), p);
    }
    final nRef = run.nPlan;
    final track = ExerciseTrack(
      info,
      CapacityFilter(
        mode: CapacityMode.loaded,
        c: logLoad - logShare(n, k0) + logShare(nRef, k0),
        cSd: p.priorSdFirstSet,
        v: p.trendPrior[ctx.level],
        vSd: p.trendPriorSd[ctx.level],
        k: k0,
        kLogSd: p.kLogSd,
        nRef: nRef,
        day: day,
      ),
    );
    state.tracks[info.id] = track;
    _open(run, track);
  }

  void _firstDirect(
    ExerciseRun run,
    CapacityMode mode,
    int amount,
    int? flames,
    bool failed,
  ) {
    final p = _p;
    final rir = failed
        ? 0.0
        : (flames == null
              ? run.spec.rir
              : state.rater.trueRir(rirOfFlames(flames), p));
    final implied = _impliedCapacity(mode, amount < 1 ? 1 : amount, rir);
    final track = ExerciseTrack(
      run.info,
      _directFilter(
        mode,
        ln(implied),
        p.priorSdFirstSet,
        p.trendPrior[ctx.level],
        p.trendPriorSd[ctx.level],
      ),
    );
    state.tracks[run.info.id] = track;
    _open(run, track);
  }

  /// Capacité (répétitions ou secondes maximales) impliquée par une série
  /// de [amount] finie à [rir] répétitions de l'échec.
  double _impliedCapacity(CapacityMode mode, int amount, double rir) {
    if (mode == CapacityMode.hold) {
      final reserve = _p.holdReserveShare * (rir > 6 ? 6.0 : rir);
      return amount / (1 - reserve);
    }
    return amount + rir;
  }

  /// Quantité (répétitions ou secondes) à faire pour garder [rir] en
  /// réserve avec la capacité [capacity].
  double _amountFor(CapacityMode mode, double capacity, double rir) {
    if (mode == CapacityMode.hold) {
      final reserve = _p.holdReserveShare * (rir > 6 ? 6.0 : rir);
      return capacity * (1 - reserve);
    }
    return capacity - rir;
  }

  void _observeLoaded(
    ExerciseRun run,
    double logLoad,
    double loadKg,
    int reps,
    int? flames,
    bool failed,
    SetPlan? target,
    bool test,
    bool boundOnly,
    int? quality,
    SetRole? role,
    int shown,
  ) {
    final p = _p;
    final track = run.track!;
    final f = track.filter;
    final fatigue = f.fatigueNow(p);
    final kk = f.k;
    final nPred = f.repsPossible(logLoad) * (1 - fatigue);
    final uPred = (nPred - 1) / kk;
    final slope = 1 / (kk * (1 + (uPred < 0 ? 0.0 : uPred)));
    final loadSd = f.loadSd(nPred < 1 ? 1.0 : nPred);
    final fresh = fatigue < p.kLearnMaxFatigue;
    final open = target != null && target.open;
    var rirEstimate = 0.0;
    if (reps < 1) {
      // Pas une répétition : la charge dépasse ce qui se soulève une fois
      // aujourd'hui (borne haute). Comme pour un échec, une série très loin
      // de ce qui était prévu (zéro répétition à une charge légère) est
      // une saisie douteuse : son poids est réduit (`clip`).
      f.observeLoad(
        logLoad: logLoad,
        n: 1,
        nSd: p.failSd,
        fatigue: fatigue,
        p: p,
        bound: true,
        upper: true,
        clip: p.failOutlier,
      );
    } else if (failed) {
      f.observeLoad(
        logLoad: logLoad,
        n: reps + p.failExtraReps,
        nSd: p.failSd,
        fatigue: fatigue,
        p: p,
        learnK: fresh,
        clip: p.failOutlier,
      );
    } else if (flames == null || boundOnly) {
      f.observeLoad(
        logLoad: logLoad,
        n: reps.toDouble(),
        nSd: p.completedSd,
        fatigue: fatigue,
        p: p,
        bound: true,
      );
    } else if (flames == Flames.min) {
      f.observeLoad(
        logLoad: logLoad,
        n: reps + state.rater.trueRir(p.openRir, p),
        nSd: state.rater.rirSd(p.openRir, reps, p),
        fatigue: fatigue,
        p: p,
        bound: true,
      );
    } else if (run.spec.reads &&
        _asBound(
          run,
          flames,
          open,
          test,
          reps,
          target,
          implied: reps + rirOfFlames(flames),
          predicted: nPred,
        )) {
      // Mode coach : loin de l'échec, la note ne se lit que comme « au
      // moins tant en réserve » (la prédiction des répétitions restantes
      // se dégrade loin de l'échec et plafonne, R2-P3). Sur une série
      // lourde et courte (8 répétitions possibles au plus), la réserve dite
      // se corrige du biais de note appris, comme une mesure (Halperin et
      // al. 2022 : sous-estimation moyenne d'environ une répétition, plus
      // juste près de l'échec et sur les charges lourdes ; CA2, partie 0 :
      // estimation moins prudente, jamais abaissée par une série facile).
      final rir = rirOfFlames(flames);
      final heavy = reps + rir <= p.coachHeavyBoundReps;
      f.observeLoad(
        logLoad: logLoad,
        n: reps + (heavy ? state.rater.trueRir(rir, p) : rir),
        nSd: state.rater.rirSd(rir, reps, p),
        fatigue: fatigue,
        p: p,
        bound: true,
      );
    } else {
      final rir = rirOfFlames(flames);
      if (test && run.spec.coach != null && role != SetRole.attempt) {
        // Test mené près de l'échec : l'écart à la prévision corrige le
        // biais de note appris (limite 4 de 0.1).
        if (rir <= 1) {
          state.rater.learn(reps + rir - nPred, p);
        }
      }
      final confirmed =
          target != null &&
          !target.open &&
          flames == target.flames &&
          reps == target.high;
      final w = confirmed ? state.rater.weight(p) : 1.0;
      if (target != null && !target.open) {
        state.rater.note(confirmed, p);
      }
      final predicted = nPred - reps;
      final rirForNoise = predicted > rir
          ? (predicted > 6 ? 6.0 : predicted)
          : rir;
      var sd = state.rater.rirSd(rirForNoise, reps, p);
      if (w < 0.999) {
        sd = sd / sqrt(w < 1e-3 ? 1e-3 : w);
      }
      final nObserved = reps + state.rater.trueRir(rir, p);
      // Atténuation des écarts aberrants (Huber) : au-delà du seuil, le
      // bruit est gonflé pour ramener l'innovation au seuil.
      final e = nPred - nObserved;
      final s = sq(sd) + sq(loadSd / slope);
      if (e * e > sq(p.huber) * s) {
        sd = sqrt(sq(sd) + e * e / sq(p.huber) - s);
      }
      if (w > 0.02) {
        f.observeLoad(
          logLoad: logLoad,
          n: nObserved,
          nSd: sd,
          fatigue: fatigue,
          p: p,
          // Mode coach : toute série notée près de l'échec, fraîche,
          // renseigne la forme de la courbe (séries de tête lourdes et
          // séries longues se recoupent).
          learnK:
              fresh &&
              ((test || open) && rir <= 2 ||
                  (run.spec.reads && rir <= p.coachCurveRir)),
        );
      }
      f.observeLoad(
        logLoad: logLoad,
        n: reps.toDouble(),
        nSd: p.completedSd,
        fatigue: fatigue,
        p: p,
        bound: true,
      );
    }
    if (!(failed || reps < 1)) {
      // RIR a posteriori de la série (la note seule est trop bruitée).
      rirEstimate = clampDouble(
        f.repsPossible(logLoad) * (1 - fatigue) - reps,
        0,
        8,
      );
    }
    f.noteSetFatigue(rirEstimate, run.spec.restSeconds, p);
    state.fatigue.add(run.info, effortWeight(rirEstimate, failed: failed));
    final unplanned =
        failed && (target == null || target.flames < Flames.failure);
    if (unplanned) {
      run.fails++;
    }
    _noteEase(run, shown, flames, failed, target);
    run.observed.add(
      ObservedSet(
        loadKg: loadKg,
        amount: shown,
        flames: flames,
        failed: failed,
        unplannedFail: unplanned,
        open: open,
        target: target,
        rir: rirEstimate,
        quality: quality,
        role: role,
      ),
    );
  }

  void _observeDirect(
    ExerciseRun run,
    CapacityMode mode,
    int amount,
    int? flames,
    bool failed,
    SetPlan? target,
    bool boundOnly,
    int? quality,
    SetRole? role,
    bool test,
    int shown,
  ) {
    final p = _p;
    final track = run.track!;
    final f = track.filter;
    final fatigue = f.fatigueNow(p);
    final keep = 1 - fatigue;
    if (test &&
        run.spec.coach != null &&
        mode == CapacityMode.reps &&
        amount >= 1 &&
        (failed || (flames != null && rirOfFlames(flames) <= 1))) {
      // Test de répétitions mené près de l'échec : l'écart à la prévision
      // corrige le biais de note appris (limite 4 de 0.1).
      final shown = amount + (failed ? p.failExtraReps : rirOfFlames(flames!));
      state.rater.learn(shown - f.capacityToday() * keep, p);
    }
    final done = amount < 1 ? 1 : amount;
    final open = target != null && target.open;
    var rirEstimate = 0.0;
    double relSd(double rir) {
      if (mode == CapacityMode.hold) {
        return p.holdSdBase + p.holdSdPerRir * rir;
      }
      return state.rater.rirSd(rir, done, p) / (done + rir);
    }

    if (failed) {
      final implied = mode == CapacityMode.hold
          ? done.toDouble()
          : done + p.failExtraReps;
      f.observeDirect(
        logCapacity: ln(implied / keep),
        sd: mode == CapacityMode.hold ? p.holdSdBase / 2 : p.failSd / implied,
        p: p,
        clip: p.failOutlier,
      );
    } else if (flames == null || boundOnly) {
      f.observeDirect(
        logCapacity: ln(done / keep),
        sd: 0.05,
        p: p,
        bound: true,
      );
    } else if (flames == Flames.min) {
      final rir = state.rater.trueRir(p.openRir, p);
      f.observeDirect(
        logCapacity: ln(_impliedCapacity(mode, done, rir) / keep),
        sd: relSd(p.openRir),
        p: p,
        bound: true,
      );
    } else if (run.spec.reads &&
        _asBound(
          run,
          flames,
          open,
          test,
          amount,
          target,
          implied: _impliedCapacity(mode, done, rirOfFlames(flames)),
          predicted: f.capacityToday() * keep,
        )) {
      final said = rirOfFlames(flames);
      f.observeDirect(
        logCapacity: ln(_impliedCapacity(mode, done, said) / keep),
        sd: relSd(said),
        p: p,
        bound: true,
      );
    } else {
      final rir = rirOfFlames(flames);
      final confirmed =
          target != null &&
          !target.open &&
          flames == target.flames &&
          amount == target.high;
      final w = confirmed ? state.rater.weight(p) : 1.0;
      if (target != null && !target.open) {
        state.rater.note(confirmed, p);
      }
      var sd = relSd(rir);
      if (w < 0.999) {
        sd = sd / sqrt(w < 1e-3 ? 1e-3 : w);
      }
      final implied = _impliedCapacity(mode, done, state.rater.trueRir(rir, p));
      final e = ln(implied / keep) - (f.m[0] + f.m[3]);
      final s = sq(sd) + sq(f.loadSd(1));
      if (e * e > sq(p.huber) * s) {
        sd = sqrt(sq(sd) + e * e / sq(p.huber) - s);
      }
      if (w > 0.02) {
        f.observeDirect(logCapacity: ln(implied / keep), sd: sd, p: p);
      }
      f.observeDirect(
        logCapacity: ln(done / keep),
        sd: 0.05,
        p: p,
        bound: true,
      );
    }
    if (!failed) {
      final after = f.capacityToday() * keep;
      if (mode == CapacityMode.hold) {
        final share = after <= 0 ? 0.0 : 1 - done / after;
        rirEstimate = clampDouble(share / p.holdReserveShare, 0, 8);
      } else {
        rirEstimate = clampDouble(after - done, 0, 8);
      }
    }
    f.noteSetFatigue(rirEstimate, run.spec.restSeconds, p);
    state.fatigue.add(run.info, effortWeight(rirEstimate, failed: failed));
    final unplanned =
        failed && (target == null || target.flames < Flames.failure);
    if (unplanned) {
      run.fails++;
    }
    _noteEase(run, shown, flames, failed, target);
    run.observed.add(
      ObservedSet(
        loadKg: null,
        amount: shown,
        flames: flames,
        failed: failed,
        unplannedFail: unplanned,
        open: open,
        target: target,
        rir: rirEstimate,
        quality: quality,
        role: role,
      ),
    );
  }

  /// Compte la série dans le bilan « nettement plus facile que visé » de
  /// l'exercice : cible atteinte et note d'une flamme (« 5 répétitions en
  /// réserve et plus », qui ne borne la capacité que par le bas), au moins
  /// [AdaptParams.adviceGapFlames] flammes sous la cible (D5).
  /// Mode coach : vrai si la note [flames] se lit comme une borne basse
  /// (loin de l'échec).
  /// Une série ouverte (au ressenti, série repère) arrêtée à la réserve
  /// demandée mesure la capacité jusqu'à 2 répétitions en réserve dites.
  bool _censored(int flames, [bool open = false]) {
    final rir = rirOfFlames(flames);
    if (open && rir <= 2) {
      return false;
    }
    return rir >= state.rater.ceiling(_p);
  }

  /// Mode coach : vrai si la série se lit comme une borne basse. Une série
  /// à cible fixe menée à bien ne mesure pas la capacité, quelle que soit
  /// sa note : une note isolée est trop peu sûre (erreur de 2,6 à 3,4
  /// répétitions, Steele et al. 2017 ; sous-estimation, Halperin et al.
  /// 2022) — elle sert au conseil de la série suivante, pas à l'estimation.
  /// Ce que l'athlète fait mesure : un échec, des répétitions qui manquent
  /// à la cible avec une note dure, une série ouverte arrêtée à la réserve
  /// demandée, un test.
  bool _asBound(
    ExerciseRun run,
    int flames,
    bool open,
    bool test,
    int amount,
    SetPlan? target, {
    required double implied,
    required double predicted,
  }) {
    // Série ouverte menée jusqu'au haut de sa plage : elle n'a pas été
    // arrêtée au ressenti, elle ne mesure pas.
    final byFeel = open && (target == null || amount < target.high);
    if (_censored(flames, byFeel)) {
      return true;
    }
    // Série au ressenti qui montre nettement moins que l'estimation (10 %
    // et plus) : une seule mesure ne fait pas baisser l'estimation — elle se
    // lit comme une borne basse, et la baisse attend une deuxième mesure
    // concordante dans les quatre semaines (CX, correction 1 : jamais
    // d'estimation abaissée sur une seule série d'un mauvais jour ; la note
    // sous-estime la réserve loin de l'échec, Zourdos et al. 2021).
    // (De même pour une série arrêtée sous le bas de sa cible : CA2,
    // partie 0 — une seule série arrêtée tôt ne fait plus baisser
    // l'estimation ; relecture documentée, manche 4 et partie 0.)
    final short = target != null && amount < target.low;
    if ((byFeel || short) && !test && run.spec.coach != null && predicted > 0) {
      final track = run.track!;
      if (implied < predicted * 0.9) {
        final last = track.lowProbeDay;
        // Le même mauvais jour ne confirme pas : la deuxième mesure vient
        // d'une autre séance.
        if (last == day) {
          return true;
        }
        if (last == null || day - last > 28) {
          track.lowProbeDay = day;
          return true;
        }
        track.lowProbeDay = null;
      } else {
        // Une mesure conforme efface la borne basse en attente.
        track.lowProbeDay = null;
      }
    }
    if (byFeel || test || short) {
      run.measured = true;
      return false;
    }
    return true;
  }

  void _noteEase(
    ExerciseRun run,
    int amount,
    int? flames,
    bool failed,
    SetPlan? target,
  ) {
    if (flames == null || target == null) {
      return;
    }
    run.ratedSets++;
    // Mode coach : une note au plafond de ce qu'une personne sait dire
    // (« 3 en réserve ou plus »), au-dessus de la réserve visée, compte
    // comme « plus facile que visé » — elle ouvre une série au ressenti
    // qui dira ce que la charge (ou la plage) vaut vraiment.
    final said = rirOfFlames(flames);
    final coachEasy =
        run.spec.coach != null &&
        said >= state.rater.ceiling(_p) &&
        said - rirOfFlames(target.flames) >= 0.5;
    final easy =
        !failed &&
        amount >= target.high &&
        ((flames == Flames.min &&
                target.flames - flames >= _p.adviceGapFlames) ||
            coachEasy);
    if (easy) {
      run.easySets++;
    }
    run.lastRatedEasy = easy;
  }

  // ----------------------------------------------------------- prescription

  /// Quantile prudent pour un RIR visé [rir].
  double quantileZ(double rir) {
    final p = _p;
    return clampDouble(
      p.quantileBase - p.quantilePerRir * rir,
      p.quantileMin,
      p.quantileMax,
    );
  }

  /// Répétitions prévues à la charge externe [loadKg] en gardant [rir] en
  /// réserve, après la perte relative [fatigue] : quantile prudent de la
  /// capacité du jour, la fatigue étant elle-même incertaine.
  double predictedReps(
    ExerciseRun run,
    double loadKg,
    double rir,
    double fatigue,
  ) {
    final p = _p;
    final f = run.track!.filter;
    final total = run.info.totalLoad(loadKg, bodyWeightKg);
    if (total <= 0) {
      // Charge totale nulle (assistance égale au poids porté) : la série
      // n'est pas limitée par la charge.
      return 1000;
    }
    final logLoad = ln(total);
    final n = f.repsPossible(logLoad);
    final kk = f.k;
    final u = (n - 1) / kk;
    final slope = 1 / (kk * (1 + (u < 0 ? 0.0 : u)));
    final sdCapacity = f.loadSd(run.nPlan) / slope;
    final sdFatigue = p.fatigueRelSd * fatigue * n;
    final sd = sqrt(sq(sdCapacity * (1 - fatigue)) + sq(sdFatigue));
    return n * (1 - fatigue) - quantileZ(rir) * sd - rir;
  }

  /// Quantité prévue (répétitions ou secondes) d'un exercice sans charge.
  double predictedAmount(ExerciseRun run, double rir, double fatigue) {
    final p = _p;
    final f = run.track!.filter;
    final mode = run.info.mode!;
    final sdLog = f.loadSd(1);
    final sdFatigue = p.fatigueRelSd * fatigue;
    final sd = sqrt(sq(sdLog) + sq(sdFatigue));
    final capacity =
        f.capacityToday(shift: -quantileZ(rir) * sd) * (1 - fatigue);
    return _amountFor(mode, capacity, rir);
  }

  /// Charge externe de la séance pour un exercice chargé (règle à
  /// hystérésis : la charge ne bouge que quand la plage ne tient plus).
  double chooseLoad(ExerciseRun run) {
    final p = _p;
    final track = run.track!;
    final spec = run.spec;
    final info = run.info;
    final grid = info.grid;
    final rir = run.rirEff;
    final bw = info.fraction * bodyWeightKg;
    final lo = spec.low;
    final hi = spec.high;
    double reps(double kg) => predictedReps(run, kg, rir, 0);
    double possible(double kg) {
      final total = info.totalLoad(kg, bodyWeightKg);
      return total <= 0 ? 1000 : track.filter.repsPossible(ln(total));
    }

    final mid = (lo + hi + 1) ~/ 2;
    final last = track.lastLoad;
    run.heldCause = null;
    run.coarse = false;
    if (last == null) {
      final f = track.filter;
      final shift = -quantileZ(rir) * f.loadSd(run.nPlan);
      final ideal = exp(f.logLoadFor(mid + rir, shift: shift)) - bw;
      return grid.floor(ideal < grid.minimum ? grid.minimum : ideal);
    }
    // La dernière charge du journal peut être hors grille (autre matériel,
    // saisie libre) : la séance repart de la charge de la grille juste
    // en dessous (une charge sous la plus petite de la grille est gardée).
    final floored = grid.floor(last);
    final start = floored > last ? last : floored;
    var kg = start;
    final floorReps = lo - 2 > 3 ? lo - 2 : 3;
    if (reps(kg) < lo - p.downMargin) {
      // Sur une grille à gros crans, la charge du dessous peut être bien
      // trop légère : la charge est alors gardée, avec moins de
      // répétitions, tant qu'elle en permet assez.
      final below = grid.next(kg, up: false);
      final keep =
          below < kg - 1e-9 &&
          reps(kg) >= floorReps - p.downMargin &&
          reps(below) >= spec.highExtended + p.upMargin;
      if (!keep) {
        for (var i = 0; i < 60; i++) {
          final next = grid.next(kg, up: false);
          if (next >= kg - 1e-9) {
            break;
          }
          kg = next;
          if (reps(kg) >= lo) {
            break;
          }
        }
        return kg;
      }
      run.coarse = true;
    }
    if (track.noUp) {
      run.heldCause = 'failure';
      return kg;
    }
    if (run.painZones.isNotEmpty) {
      run.heldCause = 'pain';
      return kg;
    }
    if (noIncrease) {
      run.heldCause = 'health';
      return kg;
    }
    if (run.lockUp) {
      run.heldCause = 'phase';
      return kg;
    }
    final rise = run.calibrating
        ? p.maxUpCalibration
        : (run.riseCap ?? (spec.main ? p.maxUpMain : p.maxUpOther));
    final capTotal = (last + bw) * (1 + rise);
    for (var i = 0; i < 60; i++) {
      final next = grid.next(kg, up: true);
      final over = next + bw > capTotal + 1e-9;
      if (over && kg != start) {
        break;
      }
      // Un seul incrément reste permis quand le plus petit pas de la
      // grille dépasse le plafond (haltères, machines à gros crans).
      final now = reps(kg);
      bool ok;
      if (run.easyMode && kg == start) {
        // La dernière séance a été notée « 5 en réserve et plus » : un cran
        // de plus, même si le modèle — qui n'a alors que des bornes basses
        // — ne le prévoit pas encore, pourvu que la charge suivante laisse
        // au moins trois répétitions d'après ces bornes, ou que le plafond
        // de répétitions soit atteint (cette charge n'apprend plus rien).
        ok = possible(next) >= 3 || track.lastTop >= spec.wideTop;
      } else if (run.calibrating) {
        ok = reps(next) >= mid;
      } else if (over) {
        ok =
            now >= spec.highExtended - 1 + p.upMargin &&
            reps(next) >= (lo - 2 > 3 ? lo - 2 : 3);
        if (!ok && now >= hi + p.upMargin) {
          run.coarse = true;
        }
      } else {
        ok =
            (now >= hi + p.upMargin && reps(next) >= lo) ||
            (now >= spec.highExtended + p.upMargin &&
                reps(next) >= (lo - 2 > 3 ? lo - 2 : 3));
      }
      if (!ok) {
        if (!over &&
            now >= hi + p.upMargin &&
            kg == start &&
            !run.calibrating) {
          // La plage est dépassée mais la charge suivante ne tient pas
          // encore : c'est le pas de la grille qui retient.
          run.coarse = true;
        }
        break;
      }
      kg = next;
      if (over) {
        break;
      }
    }
    if (kg == start && !run.calibrating) {
      final next = grid.next(kg, up: true);
      if (next + bw > capTotal + 1e-9 &&
          reps(kg) >= hi + p.upMargin &&
          reps(next) >= lo &&
          !run.coarse) {
        run.heldCause = 'cap';
      }
    }
    return kg;
  }

  /// Répétitions visées à la charge [loadKg] pour la série de fatigue
  /// prévue [fatigue] : (cible entière, valeur prévue).
  (int, double) targetReps(ExerciseRun run, double loadKg, double fatigue) {
    final spec = run.spec;
    final r = predictedReps(run, loadKg, run.rirEff, fatigue);
    var top = spec.high;
    if (r >= spec.high + 1) {
      // La charge suivante n'est pas atteignable : la plage s'étend.
      top = spec.highExtended;
      if (r >= top + 1) {
        final next = run.info.grid.next(loadKg, up: true);
        final floor = spec.low - 2 > 3 ? spec.low - 2 : 3;
        if (predictedReps(run, next, run.rirEff, fatigue) < floor) {
          top = 2 * spec.high > 30 ? 30 : 2 * spec.high;
          if (top < spec.highExtended) {
            top = spec.highExtended;
          }
        }
      }
    }
    var target = (r + 0.5).floor();
    if (target > top) {
      target = top;
    }
    if (target < 1) {
      target = 1;
    }
    return (target, r);
  }

  /// Cible entière d'un exercice sans charge pour la fatigue [fatigue].
  int targetAmount(ExerciseRun run, double fatigue) {
    final spec = run.spec;
    final r = predictedAmount(run, run.rirEff, fatigue);
    var top = spec.high;
    if (r >= spec.high + 1) {
      top = run.info.mode == CapacityMode.hold
          ? spec.high + spec.high ~/ 2
          : spec.highExtended;
      if (run.info.mode == CapacityMode.reps && r >= top + 1) {
        // Sans charge, les répétitions sont le seul réglage : la plage
        // s'étend comme pour une charge qui ne peut pas monter.
        final wide = 2 * spec.high > 30 ? 30 : 2 * spec.high;
        if (wide > top) {
          top = wide;
        }
      }
    }
    var target = (r + 0.5).floor();
    if (run.info.mode == CapacityMode.hold && target > 20) {
      target = target ~/ 5 * 5;
    }
    if (target > top) {
      target = top;
    }
    // Sans charge, les répétitions (ou les secondes) sont la charge : après
    // un échec non prévu, une douleur sur la zone ou un bilan bas, jamais
    // plus que la plus grande série de la dernière séance (I2, I3) ; après
    // un échec dans la séance, jamais plus que la dernière série faite.
    final track = run.track!;
    if (!spec.test &&
        track.lastDay != null &&
        (track.noUp || run.painZones.isNotEmpty || noIncrease)) {
      final cap = track.lastTop < 1 ? 1 : track.lastTop;
      if (target > cap) {
        target = cap;
      }
    }
    if (run.fails > 0 && run.observed.isNotEmpty) {
      final done = run.observed.last.amount;
      final cap = done < 1 ? 1 : done;
      if (target > cap) {
        target = cap;
      }
    }
    if (target < 1) {
      target = 1;
    }
    return target;
  }

  /// Plan des séries de l'exercice ouvert (il doit avoir un suivi).
  List<SetPlan> planSets(ExerciseRun run) {
    final p = _p;
    final track = run.track!;
    final spec = run.spec;
    final rir = run.rirEff;
    final flames = flamesOfRir(rir);
    final out = <SetPlan>[];
    if (run.info.mode == CapacityMode.loaded) {
      final kg = chooseLoad(run);
      for (var i = 0; i < spec.sets; i++) {
        final fatigue = plannedFatigue(i, rir, spec.restSeconds, p);
        final (reps, _) = targetReps(run, kg, fatigue);
        out.add(_felt(run, kg, reps, flames));
      }
    } else {
      for (var i = 0; i < spec.sets; i++) {
        final fatigue = plannedFatigue(i, rir, spec.restSeconds, p);
        final amount = targetAmount(run, fatigue);
        out.add(_felt(run, null, amount, flames));
      }
    }
    // Série repère : quand les notes n'informent plus, la dernière série
    // devient ouverte (autant de répétitions que possible en gardant la
    // réserve dite), comme dans l'APRE (Mann et al. 2010).
    final lastBenchmark = track.benchmarkDay;
    // Mode coach : aussi quand aucune série n'a mesuré la capacité depuis
    // `coachProbeDays` (notes au plafond de ce qu'une personne sait dire).
    final exact = track.exactDay;
    final blind =
        spec.coach != null &&
        track.lastDay != null &&
        (exact == null || day - exact >= p.coachProbeDays);
    final every = state.rater.weight(p) < p.benchmarkWeight
        ? p.benchmarkEveryDays
        : (blind ? p.coachProbeDays : p.benchmarkEveryDaysRated);
    if (wantsBenchmark(run) &&
        every > 0 &&
        (lastBenchmark == null || day - lastBenchmark >= every)) {
      final last = out.removeLast();
      out.add(
        SetPlan(
          loadKg: last.loadKg,
          low: last.low,
          high: last.low + p.benchmarkExtraReps,
          flames: flamesOfRir(p.benchmarkRir),
          open: true,
          benchmark: true,
        ),
      );
    }
    if (spec.test && spec.high > spec.low) {
      // Test sans cible série par série (« maximum ») : séries ouvertes,
      // la prévision prudente sert de repère bas.
      for (var i = 0; i < out.length; i++) {
        final planned = out[i];
        var high = planned.low + (planned.low + 1) ~/ 2 + 2;
        if (high > spec.high) {
          high = spec.high;
        }
        if (high > planned.low) {
          out[i] = SetPlan(
            loadKg: planned.loadKg,
            low: planned.low,
            high: high,
            flames: planned.flames,
            open: true,
          );
        }
      }
    }
    run.plan = List<SetPlan?>.of(out);
    return out;
  }

  /// Cible d'une série de [amount] répétitions (ou secondes) prévues. En
  /// mode « plus facile que visé », la série se fait au ressenti dans la
  /// plage du bloc (élargie à la prévision) : c'est elle qui dira la
  /// capacité, que les notes très basses ne bornent que par le bas.
  SetPlan _felt(ExerciseRun run, double? kg, int amount, int flames) {
    if (!run.easyMode) {
      return SetPlan(loadKg: kg, low: amount, high: amount, flames: flames);
    }
    final spec = run.spec;
    final low = amount < spec.low ? amount : spec.low;
    var high = amount > spec.high ? amount : spec.high;
    // Jusqu'au haut de plage étendu : la série s'arrête au ressenti, et
    // c'est le nombre atteint qui dira si la charge suivante est possible.
    final wide = run.info.mode == CapacityMode.hold
        ? spec.high + spec.high ~/ 2
        : (2 * spec.high > 30 ? 30 : 2 * spec.high);
    if (wide > high) {
      high = wide;
    }
    return SetPlan(
      loadKg: kg,
      low: low,
      high: high,
      flames: flames,
      open: high > low,
    );
  }

  /// Vrai si l'exercice ouvert relève d'une série repère aujourd'hui (hors
  /// délai depuis la précédente).
  bool wantsBenchmark(ExerciseRun run) {
    return !run.uncertain &&
        !run.easyMode &&
        !run.track!.noUp &&
        run.spec.benchmarkOk &&
        run.spec.sets >= 2 &&
        run.info.mode != CapacityMode.hold &&
        run.painZones.isEmpty &&
        !noIncrease;
  }

  // ----------------------------------------------------------------- conseil

  /// Cible de la série de rang [index] après les séries déjà observées de
  /// l'exercice en cours, et nature du changement.
  (SetPlan, IntraSessionAction) advise(ExerciseRun run, int index) {
    final p = _p;
    final spec = run.spec;
    final track = run.track!;
    final previous = run.observed.last;
    final rir = run.rirEff;
    final flamesTarget = flamesOfRir(rir);
    final planned = index < run.plan.length ? run.plan[index] : null;
    final previousTarget = previous.target;
    final previousFlames = previousTarget?.flames ?? flamesTarget;
    final rated = previous.flames;
    final gap =
        (previous.unplannedFail ? Flames.failure : (rated ?? previousFlames)) -
        previousFlames;
    final load = previous.loadKg;
    // Série nettement plus facile que visé, cible atteinte.
    final easy =
        rated == Flames.min &&
        previousTarget != null &&
        !previous.failed &&
        previous.amount >= previousTarget.high &&
        previousFlames - Flames.min >= p.adviceGapFlames;
    final free = run.fails == 0 && run.painZones.isEmpty && !noIncrease;
    if (planned != null && gap.abs() < p.adviceGapFlames && run.fails == 0) {
      final same = load != null && planned.loadKg != load
          ? planned.withLoad(load)
          : planned;
      return (same, IntraSessionAction.keep);
    }
    final fatigue = track.filter.fatigueNow(p);
    if (run.info.mode != CapacityMode.loaded || load == null) {
      var amount = targetAmount(run, fatigue);
      if (easy && free) {
        // Le modèle n'a qu'une borne basse : la série suivante monte d'un
        // cinquième (au moins une répétition), dans la plage étendue.
        final step = (previous.amount + 2) ~/ 5;
        var bumped = previous.amount + (step < 1 ? 1 : step);
        final wide = run.info.mode == CapacityMode.hold
            ? 2 * spec.high
            : (2 * spec.high > 30 ? 30 : 2 * spec.high);
        final top = wide > spec.highExtended ? wide : spec.highExtended;
        if (bumped > top) {
          bumped = top;
        }
        if (bumped > amount) {
          amount = bumped;
        }
      }
      var next = SetPlan(
        loadKg: null,
        low: amount,
        high: amount,
        flames: flamesTarget,
      );
      if (planned != null && planned.open && run.fails == 0) {
        next = SetPlan(
          loadKg: null,
          low: amount,
          high: amount + p.benchmarkExtraReps,
          flames: planned.flames,
          open: true,
          benchmark: planned.benchmark,
        );
      }
      final before = planned?.high ?? previous.amount;
      final action = previous.unplannedFail && run.fails >= 2
          ? IntraSessionAction.stopExercise
          : (amount > before
                ? IntraSessionAction.repsUp
                : (amount < before
                      ? IntraSessionAction.repsDown
                      : IntraSessionAction.keep));
      return (next, action);
    }
    final grid = run.info.grid;
    final bw = run.info.fraction * bodyWeightKg;
    final lo = spec.low;
    final hi = spec.high;
    final mid = (lo + hi + 1) ~/ 2;
    double reps(double kg) => predictedReps(run, kg, rir, fatigue);
    double stepDown(double from) {
      final floorTotal = (from + bw) * (1 - p.maxDownSet);
      var kg = from;
      for (var i = 0; i < 60; i++) {
        final next = grid.next(kg, up: false);
        // Un cran reste toujours permis, même quand il dépasse la baisse
        // maximale (grille à gros crans).
        if (next >= kg - 1e-9 ||
            (next + bw < floorTotal - 1e-9 && kg != from)) {
          break;
        }
        kg = next;
        if (reps(kg) >= lo) {
          break;
        }
      }
      return kg;
    }

    final floored = grid.floor(load);
    var kg = floored > load ? load : floored;
    final canRise = free && !track.noUp;
    var raisedByRating = false;
    if (planned == null && !previous.unplannedFail) {
      // Calibrage après une première série au jugé : vers le milieu de plage.
      if (canRise) {
        final cap = (load + bw) * (1 + p.maxUpSetCalibration);
        for (var i = 0; i < 60; i++) {
          final next = grid.next(kg, up: true);
          if (next + bw > cap + 1e-9 || reps(next) < mid) {
            break;
          }
          kg = next;
        }
      }
      if (reps(kg) < lo - p.downMargin) {
        kg = stepDown(kg);
      }
    } else if (gap >= p.adviceGapFlames || previous.unplannedFail) {
      if (reps(kg) < lo - p.downMargin) {
        // Grille à gros crans : la charge est gardée avec moins de
        // répétitions quand celle du dessous serait bien trop légère
        // (jamais après un échec).
        final below = grid.next(kg, up: false);
        final floorReps = lo - 2 > 3 ? lo - 2 : 3;
        final keep =
            !previous.unplannedFail &&
            below < kg - 1e-9 &&
            reps(kg) >= floorReps - p.downMargin &&
            reps(below) >= spec.highExtended + p.upMargin;
        if (!keep) {
          kg = stepDown(kg);
        }
      }
    } else if (canRise) {
      final cap =
          (load + bw) *
          (1 + (run.calibrating ? p.maxUpSetCalibration : p.maxUpSet));
      if (easy) {
        // D5 : un écart d'au moins deux flammes ajuste la série suivante.
        // Un cran de la grille, que le modèle le prévoie ou non (il n'a
        // alors que des bornes basses) ; au-delà, le modèle décide.
        final next = grid.next(kg, up: true);
        final total = run.info.totalLoad(next, bodyWeightKg);
        final possible = total <= 0
            ? 1000.0
            : track.filter.repsPossible(ln(total)) * (1 - fatigue);
        if (next > kg && (possible >= 3 || previous.amount >= spec.wideTop)) {
          kg = next;
          raisedByRating = true;
        }
      }
      for (var i = 0; i < 60; i++) {
        final next = grid.next(kg, up: true);
        if (next + bw > cap + 1e-9) {
          break;
        }
        final ok = run.calibrating
            ? reps(next) >= mid
            : (reps(kg) >= hi + p.upMargin && reps(next) >= lo);
        if (!ok) {
          break;
        }
        kg = next;
        if (!run.calibrating) {
          break;
        }
      }
    }
    final (target, _) = targetReps(run, kg, fatigue);
    var next = SetPlan(
      loadKg: kg,
      low: target,
      high: target,
      flames: flamesTarget,
    );
    if (raisedByRating || (run.easyMode && !previous.unplannedFail)) {
      // Série au ressenti dans la plage : elle dira ce que la charge vaut.
      final low = target < spec.low ? target : spec.low;
      final high = target > spec.high ? target : spec.high;
      next = SetPlan(
        loadKg: kg,
        low: low,
        high: high,
        flames: flamesTarget,
        open: high > low,
      );
    } else if (planned != null && planned.open && !previous.unplannedFail) {
      next = SetPlan(
        loadKg: kg,
        low: target,
        high: target + p.benchmarkExtraReps,
        flames: planned.flames,
        open: true,
        benchmark: planned.benchmark,
      );
    }
    final before = planned?.high ?? previous.amount;
    IntraSessionAction action;
    if (previous.unplannedFail && run.fails >= 2) {
      action = IntraSessionAction.stopExercise;
    } else if (kg > load + 1e-9) {
      action = IntraSessionAction.loadUp;
    } else if (kg < load - 1e-9) {
      action = IntraSessionAction.loadDown;
    } else if (target > before) {
      action = IntraSessionAction.repsUp;
    } else if (target < before) {
      action = IntraSessionAction.repsDown;
    } else {
      action = IntraSessionAction.keep;
    }
    while (run.plan.length <= index) {
      run.plan.add(null);
    }
    run.plan[index] = next;
    return (next, action);
  }
}
