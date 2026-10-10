// G10 (D1.4) : lecture seule de la section `adapt` de la sauvegarde
// (adaptations au jour le jour de L11, retirées en G10). Les décisions
// passées restent dans la sauvegarde telles quelles : elles sont relues
// (import strict, démarrage tolérant) et réécrites à l'identique, jamais
// modifiées ni utilisées pour décider. Contrat d'origine :
// docs/CONTRAT_L11.md, § 9.

/// Version du format de la section `adapt`.
const int kAdaptVersion = 1;

final RegExp _dayRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');
final RegExp _atRe = RegExp(
  r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(?::\d{2}(?:\.\d{1,6})?)?$',
);
final RegExp _keyRe = RegExp(r'^S([1-9]\d*)-J([1-7])$');

bool _okDay(Object? v) =>
    v is String && _dayRe.hasMatch(v) && DateTime.tryParse(v) != null;
bool _okAt(Object? v) =>
    v is String && _atRe.hasMatch(v) && DateTime.tryParse(v) != null;

/// Modes d'autonomie de L11 (valeurs lues dans les anciennes sauvegardes).
const kAutonomyModes = ['guided', 'assisted', 'expert'];

// ======================================================== données

/// Pause en cours (vacances ou maladie).
class AdaptPause {
  final String kind; // vacation | illness
  final String from; // AAAA-MM-JJ
  final String? to; // premier jour de retour (pauses terminées)
  const AdaptPause(this.kind, this.from, [this.to]);
  Map<String, dynamic> toJson() => {
    'kind': kind,
    'from': from,
    if (to != null) 'to': to,
  };
}

/// Événement daté (historique des adaptations, annulables).
class AdaptEvent {
  final String at, kind;
  final Map<String, dynamic> detail;
  String status; // applied | undone
  AdaptEvent(this.at, this.kind, this.detail, [this.status = 'applied']);
  Map<String, dynamic> toJson() => {
    'at': at,
    'kind': kind,
    'status': status,
    if (detail.isNotEmpty) 'detail': detail,
  };
}

/// Section `adapt` de la sauvegarde (écrite seulement si utilisée).
class AdaptData {
  int version = kAdaptVersion;

  /// Mode choisi sans profil (installation sans profil L8).
  String? autonomy;

  /// Adaptations par séance (`S·J`) : compression, échanges, lieu, choix
  /// de reprise.
  final Map<String, Map<String, dynamic>> sessions = {};
  AdaptPause? pause;
  final List<AdaptPause> pauses = [];

  /// Séances 20 % plus courtes (assiduité), depuis cet horodatage.
  String? shorter;

  /// Allègement × 0,8 : jours civils inclus [from, to].
  String? lightenFrom, lightenTo;

  /// Difficulté globale par séance : {rpe 0-10, minutes}.
  final Map<String, Map<String, int>> difficulty = {};
  final List<AdaptEvent> events = [];

  /// Propositions écartées (« Plus tard ») : identifiant → horodatage.
  final Map<String, String> dismissed = {};

  static const maxSessions = 400,
      maxDifficulty = 2000,
      maxEvents = 500,
      maxDismissed = 500;

  bool get pristine =>
      autonomy == null &&
      sessions.isEmpty &&
      pause == null &&
      pauses.isEmpty &&
      shorter == null &&
      lightenFrom == null &&
      difficulty.isEmpty &&
      events.isEmpty &&
      dismissed.isEmpty;

  Map<String, dynamic> toJson() => {
    'v': version,
    if (autonomy != null) 'autonomy': autonomy,
    if (sessions.isNotEmpty) 'sessions': sessions,
    if (pause != null) 'pause': pause!.toJson(),
    if (pauses.isNotEmpty) 'pauses': [for (final p in pauses) p.toJson()],
    if (shorter != null) 'shorter': shorter,
    if (lightenFrom != null) 'lighten': {'from': lightenFrom, 'to': lightenTo},
    if (difficulty.isNotEmpty) 'difficulty': difficulty,
    if (events.isNotEmpty) 'events': [for (final e in events) e.toJson()],
    if (dismissed.isNotEmpty) 'dismissed': dismissed,
  };

  static bool _simple(Object? v) =>
      v == null ||
      v is bool ||
      (v is num && v.isFinite) ||
      (v is String && v.length <= 200);

  static bool _okSession(Object? v) {
    if (v is! Map) return false;
    for (final e in v.entries) {
      final k = e.key, x = e.value;
      final ok = switch (k) {
        'minutes' => x is int && x >= 5 && x <= 600,
        'at' => _okAt(x),
        'warmup' => x is bool,
        'place' => x is String && x.length <= 40,
        'resume' => x == 'applied' || x == 'refused',
        'sets' =>
          x is Map &&
              x.length <= 60 &&
              x.entries.every(
                (s) =>
                    s.key is String &&
                    (s.key as String).length <= 80 &&
                    s.value is int &&
                    (s.value as int) >= 1 &&
                    (s.value as int) <= 100,
              ),
        'removed' =>
          x is List &&
              x.length <= 60 &&
              x.every((i) => i is String && i.length <= 80),
        'pairs' =>
          x is List &&
              x.length <= 30 &&
              x.every(
                (p) =>
                    p is List &&
                    p.length == 2 &&
                    p.every((i) => i is String && i.length <= 80),
              ),
        'swaps' =>
          x is Map &&
              x.length <= 60 &&
              x.entries.every(
                (s) =>
                    s.key is String &&
                    (s.key as String).length <= 80 &&
                    s.value is Map &&
                    (s.value as Map)['to'] is String &&
                    (s.value as Map)['name'] is String &&
                    ((s.value as Map)['name'] as String).length <= 200 &&
                    (s.value as Map).length <= 6 &&
                    (s.value as Map).values.every(_simple) &&
                    ((s.value as Map)['kg'] == null ||
                        ((s.value as Map)['kg'] is num &&
                            ((s.value as Map)['kg'] as num) >= 0 &&
                            ((s.value as Map)['kg'] as num) <= 1000)),
              ),
        _ => false,
      };
      if (!ok) return false;
    }
    return true;
  }

  static AdaptPause? _pause(Object? v, {bool closed = false}) {
    if (v is! Map) return null;
    final kind = v['kind'], from = v['from'], to = v['to'];
    if (kind != 'vacation' && kind != 'illness') return null;
    if (!_okDay(from)) return null;
    if (closed ? !_okDay(to) : to != null) return null;
    if (closed && (to as String).compareTo(from as String) < 0) return null;
    return AdaptPause(kind as String, from as String, to as String?);
  }

  /// Lecture de la section. [strict] (import d'un fichier) : toute valeur
  /// hors contrat lève [FormatException] ; sinon (démarrage) l'entrée est
  /// ignorée et comptée dans [issues].
  static AdaptData fromJson(
    Object? raw, {
    bool strict = false,
    List<String>? issues,
  }) {
    final out = AdaptData();
    if (raw == null) return out;
    void bad(String what) {
      if (strict) throw FormatException('Adaptations invalides : $what.');
      issues?.add(what);
    }

    if (raw is! Map) {
      bad('section');
      return out;
    }
    final v = raw['v'];
    if (v != null && (v is! int || v < 1 || v > kAdaptVersion)) {
      bad('version');
      return out;
    }
    final a = raw['autonomy'];
    if (a != null) {
      if (a is String && kAutonomyModes.contains(a)) {
        out.autonomy = a;
      } else {
        bad('mode');
      }
    }
    final sessions = raw['sessions'];
    if (sessions != null) {
      if (sessions is! Map || (strict && sessions.length > maxSessions)) {
        bad('séances');
      } else {
        for (final e in sessions.entries) {
          if (e.key is String &&
              _keyRe.hasMatch(e.key as String) &&
              _okSession(e.value)) {
            out.sessions[e.key as String] = Map<String, dynamic>.from(
              e.value as Map,
            );
          } else {
            bad('séance ${e.key}');
          }
        }
      }
    }
    final p = raw['pause'];
    if (p != null) {
      final x = _pause(p);
      if (x == null) {
        bad('pause');
      } else {
        out.pause = x;
      }
    }
    final ps = raw['pauses'];
    if (ps != null) {
      if (ps is! List || (strict && ps.length > maxEvents)) {
        bad('pauses');
      } else {
        for (final i in ps) {
          final x = _pause(i, closed: true);
          if (x == null) {
            bad('pause terminée');
          } else {
            out.pauses.add(x);
          }
        }
      }
    }
    final s = raw['shorter'];
    if (s != null) {
      if (_okAt(s)) {
        out.shorter = s as String;
      } else {
        bad('séances plus courtes');
      }
    }
    final l = raw['lighten'];
    if (l != null) {
      if (l is Map &&
          _okDay(l['from']) &&
          _okDay(l['to']) &&
          (l['to'] as String).compareTo(l['from'] as String) >= 0) {
        out
          ..lightenFrom = l['from'] as String
          ..lightenTo = l['to'] as String;
      } else {
        bad('allègement');
      }
    }
    final d = raw['difficulty'];
    if (d != null) {
      if (d is! Map || (strict && d.length > maxDifficulty)) {
        bad('difficultés');
      } else {
        for (final e in d.entries) {
          final x = e.value;
          if (e.key is String &&
              (e.key as String).length <= 60 &&
              x is Map &&
              x['rpe'] is int &&
              (x['rpe'] as int) >= 0 &&
              (x['rpe'] as int) <= 10 &&
              x['minutes'] is int &&
              (x['minutes'] as int) >= 1 &&
              (x['minutes'] as int) <= 600 &&
              x.length == 2) {
            out.difficulty[e.key as String] = {
              'rpe': x['rpe'] as int,
              'minutes': x['minutes'] as int,
            };
          } else {
            bad('difficulté ${e.key}');
          }
        }
      }
    }
    final ev = raw['events'];
    if (ev != null) {
      if (ev is! List || (strict && ev.length > maxEvents)) {
        bad('historique');
      } else {
        for (final x in ev) {
          if (x is Map &&
              _okAt(x['at']) &&
              x['kind'] is String &&
              (x['kind'] as String).length <= 40 &&
              (x['status'] == 'applied' || x['status'] == 'undone') &&
              (x['detail'] == null ||
                  (x['detail'] is Map &&
                      (x['detail'] as Map).length <= 20 &&
                      (x['detail'] as Map).keys.every((k) => k is String) &&
                      (x['detail'] as Map).values.every(_simple)))) {
            out.events.add(
              AdaptEvent(
                x['at'] as String,
                x['kind'] as String,
                Map<String, dynamic>.from((x['detail'] as Map?) ?? const {}),
                x['status'] as String,
              ),
            );
          } else {
            bad('événement');
          }
        }
      }
    }
    final dm = raw['dismissed'];
    if (dm != null) {
      if (dm is! Map || (strict && dm.length > maxDismissed)) {
        bad('propositions écartées');
      } else {
        for (final e in dm.entries) {
          if (e.key is String &&
              (e.key as String).length <= 200 &&
              _okAt(e.value)) {
            out.dismissed[e.key as String] = e.value as String;
          } else {
            bad('proposition écartée');
          }
        }
      }
    }
    // Démarrage : listes trop longues bornées aux entrées les plus récentes.
    if (out.events.length > maxEvents) {
      out.events.removeRange(0, out.events.length - maxEvents);
    }
    return out;
  }
}
