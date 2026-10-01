/// Registres d'XP et de Krédits en ajout seul (D7.3, D7.7) et état opaque
/// du moteur (`QuestState.data`).
library;

import 'package:kalis_core/kalis_core.dart';

import 'numeric.dart';

/// Ce que le registre dit d'une séance déjà réglée.
enum SessionStatus {
  /// Séance pas encore réglée.
  unsettled,

  /// Séance récompensée.
  paid,

  /// Séance faite malgré une douleur : aucune récompense.
  pain,

  /// Séance au-delà du nombre de séances prévues de la semaine.
  extra,

  /// Séance de récupération hors programme (mobilité, marche) : pas d'XP
  /// d'effort, mais elle compte pour les quêtes de récupération.
  recovery,
}

/// Portées du code `quest.xp_capped`.
abstract final class CapScope {
  /// Séances au-delà du programme de la semaine.
  static const String week = 'week';

  /// Séance de récupération hors programme.
  static const String recovery = 'recovery';

  /// Plafond d'XP de records de la séance.
  static const String records = 'records';

  /// Plafond hebdomadaire d'XP de jalons.
  static const String milestones = 'milestones';
}

/// Registres en ajout seul : les écritures reçues sont reprises telles
/// quelles, les nouvelles sont ajoutées à la suite. Chaque gain a une clé
/// stable ; une clé déjà présente n'est jamais écrite deux fois.
final class Ledger {
  /// Registres de [state].
  Ledger(QuestState state)
    : xp = List<XpEntry>.of(state.xp),
      kredits = List<KreditEntry>.of(state.kredits) {
    for (final e in xp) {
      _index(e);
    }
    for (final e in kredits) {
      _kreditKeys.add(kreditKey(e.source, e.refId));
      balance += e.amount;
    }
    receivedXp = xp.length;
    receivedKredits = kredits.length;
  }

  /// Registre d'XP.
  final List<XpEntry> xp;

  /// Registre de Krédits.
  final List<KreditEntry> kredits;

  /// Nombre d'écritures d'XP reçues (les suivantes sont nouvelles).
  late final int receivedXp;

  /// Nombre d'écritures de Krédits reçues.
  late final int receivedKredits;

  /// XP total.
  int totalXp = 0;

  /// Solde de Krédits.
  int balance = 0;

  final Set<String> _xpKeys = <String>{};
  final Set<String> _kreditKeys = <String>{};
  final Map<String, SessionStatus> _status = <String, SessionStatus>{};
  final Map<String, int> _paidInWeek = <String, int>{};
  final Map<String, int> _milestoneXpInWeek = <String, int>{};

  /// Clé d'une écriture d'XP.
  static String xpKey(XpSource source, String? sessionId, String? refId) =>
      source == XpSource.effort ? 'effort|$sessionId' : '${source.code}|$refId';

  /// Clé d'une écriture de Krédits.
  static String kreditKey(KreditSource source, String? refId) =>
      '${source.code}|$refId';

  /// Référence de semaine d'une écriture d'effort : `week|<lundi ISO>`.
  static String weekRef(int monday) =>
      'week|${CivilDate.fromDayNumber(monday).iso}';

  void _index(XpEntry e) {
    _xpKeys.add(xpKey(e.source, e.sessionId, e.refId));
    totalXp += e.amount;
    if (e.source == XpSource.effort) {
      final id = e.sessionId;
      if (id == null) {
        return;
      }
      var status = SessionStatus.paid;
      for (final r in e.reasons) {
        if (r.code == ReasonCodes.questNoRewardPain) {
          status = SessionStatus.pain;
        } else if (r.code == ReasonCodes.questXpCapped) {
          final scope = r.params['scope'];
          if (scope == CapScope.week) {
            status = SessionStatus.extra;
          } else if (scope == CapScope.recovery) {
            status = SessionStatus.recovery;
          }
        }
      }
      _status[id] = status;
      final ref = e.refId;
      if (status == SessionStatus.paid && ref != null) {
        _paidInWeek.update(ref, (n) => n + 1, ifAbsent: () => 1);
      }
    } else if (e.source == XpSource.milestone) {
      final ref = weekRef(mondayOf(e.date.dayNumber));
      _milestoneXpInWeek.update(
        ref,
        (n) => n + e.amount,
        ifAbsent: () => e.amount,
      );
    }
  }

  /// Vrai si le gain de clé [key] est déjà au registre d'XP.
  bool hasXp(String key) => _xpKeys.contains(key);

  /// Vrai si le gain de clé [key] est déjà au registre de Krédits.
  bool hasKredits(String key) => _kreditKeys.contains(key);

  /// Ce que le registre dit de la séance [sessionId].
  SessionStatus statusOf(String sessionId) =>
      _status[sessionId] ?? SessionStatus.unsettled;

  /// Séances récompensées de la semaine de référence [weekRef].
  int paidSessionsIn(String weekRef) => _paidInWeek[weekRef] ?? 0;

  /// XP de jalons déjà écrit dans la semaine du lundi [monday].
  int milestoneXpIn(int monday) => _milestoneXpInWeek[weekRef(monday)] ?? 0;

  /// Ajoute un gain d'XP (jamais négatif) s'il n'y est pas déjà ; rend
  /// vrai s'il a été écrit. La date de l'écriture n'est jamais antérieure
  /// à la dernière écriture.
  bool addXp({
    required int day,
    required XpSource source,
    required int amount,
    String? sessionId,
    String? refId,
    required List<Reason> reasons,
  }) {
    final key = xpKey(source, sessionId, refId);
    if (_xpKeys.contains(key)) {
      return false;
    }
    var date = CivilDate.fromDayNumber(day);
    if (xp.isNotEmpty && date < xp.last.date) {
      date = xp.last.date;
    }
    final entry = XpEntry(
      sequence: xp.length,
      date: date,
      source: source,
      amount: amount < 0 ? 0 : amount,
      sessionId: sessionId,
      refId: refId,
      reasons: reasons,
    );
    xp.add(entry);
    _index(entry);
    return true;
  }

  /// Ajoute un gain de Krédits s'il n'y est pas déjà ; rend vrai s'il a
  /// été écrit.
  bool addKredits({
    required int day,
    required KreditSource source,
    required int amount,
    required String refId,
  }) {
    final key = kreditKey(source, refId);
    if (amount <= 0 || _kreditKeys.contains(key)) {
      return false;
    }
    var date = CivilDate.fromDayNumber(day);
    if (kredits.isNotEmpty && date < kredits.last.date) {
      date = kredits.last.date;
    }
    kredits.add(
      KreditEntry(
        sequence: kredits.length,
        date: date,
        source: source,
        amount: amount,
        refId: refId,
      ),
    );
    _kreditKeys.add(key);
    balance += amount;
    return true;
  }

  /// Coffres déjà ouverts dans la semaine du lundi [monday].
  int chestsIn(int monday) {
    final prefix = 'chest|${CivilDate.fromDayNumber(monday).iso}|';
    var n = 0;
    for (var i = kredits.length - 1; i >= 0; i--) {
      final e = kredits[i];
      if (e.source == KreditSource.chest &&
          (e.refId ?? '').startsWith(prefix)) {
        n++;
      }
      if (e.date.dayNumber < monday - 7) {
        break;
      }
    }
    return n;
  }
}

/// Semaine close.
final class WeekSummary {
  /// Résumé de la semaine du lundi [monday].
  const WeekSummary({
    required this.monday,
    required this.planned,
    required this.done,
    required this.restPlanned,
    required this.restKept,
    required this.status,
  });

  /// Semaine réussie.
  static const int success = 1;

  /// Semaine manquée.
  static const int failed = 0;

  /// Semaine en pause.
  static const int paused = 2;

  /// Numéro de jour du lundi.
  final int monday;

  /// Séances prévues (hors pauses, hors séances neutralisées).
  final int planned;

  /// Séances faites, au plus [planned].
  final int done;

  /// Jours de repos prévus.
  final int restPlanned;

  /// Jours sans séance d'entraînement, au plus [restPlanned].
  final int restKept;

  /// [success], [failed] ou [paused].
  final int status;

  /// Forme compacte de l'état opaque.
  List<int> toJson() => <int>[
    monday,
    planned,
    done,
    restPlanned,
    restKept,
    status,
  ];
}

int _asInt(Object? v, int fallback) =>
    v is int ? v : (v is num ? v.round() : fallback);

/// État opaque de `kalis_quest`, lu depuis `QuestState.data` et réécrit à
/// chaque appel.
final class MachineState {
  MachineState._();

  /// Version du format.
  static const int version = 1;

  /// Lit l'état de [state] ; un état vide (ou d'une autre version) démarre
  /// le registre « aujourd'hui » ([today]) : rien de ce qui précède ne
  /// donne d'XP (D1.3).
  factory MachineState.read(QuestState state, int today) {
    final m = MachineState._();
    final data = state.data;
    if (data['v'] == version) {
      final started = data['startedOn'];
      final settled = data['settledThrough'];
      if (started is String && settled is String) {
        m.startedOn = CivilDate.parse(started).dayNumber;
        m.settledThrough = CivilDate.parse(settled).dayNumber;
        m.fresh = false;
        m.chestGap = _asInt(data['chestGap'], 0);
        m.streak = _asInt(data['streak'], 0);
        m.bestStreak = _asInt(data['bestStreak'], 0);
        m.sessions = _asInt(data['sessions'], 0);
        m.chests = _asInt(data['chests'], 0);
        final weeks = data['weeks'];
        if (weeks is List<Object?>) {
          for (final w in weeks) {
            if (w is List<Object?> && w.length >= 6) {
              m.weeks.add(
                WeekSummary(
                  monday: _asInt(w[0], 0),
                  planned: _asInt(w[1], 0),
                  done: _asInt(w[2], 0),
                  restPlanned: _asInt(w[3], 0),
                  restKept: _asInt(w[4], 0),
                  status: _asInt(w[5], 0),
                ),
              );
            }
          }
        }
        final best = data['attrBest'];
        if (best is Map<String, Object?>) {
          for (final e in best.entries) {
            final v = e.value;
            if (v is num) {
              m.attrBest[e.key] = v.toDouble();
            }
          }
        }
        final ranks = data['rankBest'];
        if (ranks is Map<String, Object?>) {
          for (final e in ranks.entries) {
            m.rankBest[e.key] = _asInt(e.value, 0);
          }
        }
        final done = data['questsDone'];
        if (done is Map<String, Object?>) {
          for (final e in done.entries) {
            m.questsDone[e.key] = _asInt(e.value, 0);
          }
        }
        return m;
      }
    }
    // État absent : le registre démarre aujourd'hui. Si des écritures
    // existent déjà (état opaque perdu), on repart de la première.
    m.startedOn = state.xp.isEmpty ? today : state.xp.first.date.dayNumber;
    if (m.startedOn > today) {
      m.startedOn = today;
    }
    final last = state.lastEvaluatedOn;
    m.settledThrough = last == null || state.xp.isEmpty
        ? today - 1
        : last.dayNumber - 1;
    if (m.settledThrough > today - 1) {
      m.settledThrough = today - 1;
    }
    return m;
  }

  /// Vrai au premier appel (état vide).
  bool fresh = true;

  /// Jour de démarrage du registre.
  int startedOn = 0;

  /// Dernier jour clos : tous les jours jusqu'à lui sont réglés.
  int settledThrough = 0;

  /// Séances récompensées depuis le dernier coffre.
  int chestGap = 0;

  /// Série de semaines en cours.
  int streak = 0;

  /// Meilleure série de semaines.
  int bestStreak = 0;

  /// Séances récompensées depuis le démarrage.
  int sessions = 0;

  /// Coffres ouverts depuis le démarrage.
  int chests = 0;

  /// Semaines closes, par date croissante.
  final List<WeekSummary> weeks = <WeekSummary>[];

  /// Meilleure valeur atteinte par attribut (code de l'attribut).
  final Map<String, double> attrBest = <String, double>{};

  /// Meilleur rang atteint par mouvement de référence (0 à 6).
  final Map<String, int> rankBest = <String, int>{};

  /// Quêtes terminées par famille.
  final Map<String, int> questsDone = <String, int>{};

  /// Objet JSON de l'état (clés triées, valeurs stables).
  Map<String, Object?> toJson() {
    final attrs = attrBest.keys.toList()..sort();
    final ranks = rankBest.keys.toList()..sort();
    final kinds = questsDone.keys.toList()..sort();
    return <String, Object?>{
      'attrBest': <String, Object?>{for (final k in attrs) k: attrBest[k]},
      'bestStreak': bestStreak,
      'chestGap': chestGap,
      'chests': chests,
      'questsDone': <String, Object?>{for (final k in kinds) k: questsDone[k]},
      'rankBest': <String, Object?>{for (final k in ranks) k: rankBest[k]},
      'sessions': sessions,
      'settledThrough': CivilDate.fromDayNumber(settledThrough).iso,
      'startedOn': CivilDate.fromDayNumber(startedOn).iso,
      'streak': streak,
      'v': version,
      'weeks': <Object?>[for (final w in weeks) w.toJson()],
    };
  }
}
