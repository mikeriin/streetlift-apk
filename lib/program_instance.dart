// Instance de programme (L10, KT-050) : le programme n'est plus un fichier
// embarqué fixe mais une instance générée et stockée pour chaque
// utilisateur. Fonctions pures (aucune horloge : les dates sont passées en
// paramètre) ; branchement sur le store : `lib/program_store.dart`.
//
// Deux sortes d'instance :
// - `template` : modèle « Expert streetlifting », le programme de 40 semaines
//   embarqué (`assets/programme_v33.json.gz`, LC1 compris), repris à
//   l'identique. C'est l'instance implicite de toute installation antérieure
//   à 4.0.0 (migration du propriétaire) : rien n'est écrit tant qu'elle
//   n'est pas remplacée, et le programme reste exactement celui de 3.2.0.
// - `generated` : programme produit par le générateur, semaines stockées
//   telles quelles (figées), entrées et graine conservées pour le rejouer.
import 'dart:convert';

import 'legacy_pack.dart';

const kProgramInstanceVersion = 1;

/// Version du générateur L10 (retiré par G7) écrite dans ses instances.
const kGeneratorVersion = '1.0.0';

/// Délai d'annulation d'une régénération (KT-057).
const Duration kRegenerationUndo = Duration(days: 7);

class ProgramInstance {
  final int version;

  /// `template` ou `generated`.
  final String kind;

  /// `onboarding` (nouvel utilisateur), `user` (demandé), `profile`
  /// (profil modifié), `cycle` (cycle suivant), `migration`.
  final String origin;
  final String createdAt;
  final String updatedAt;
  final String generator;
  final String models;
  final int seed;

  /// Entrées de la dernière génération (instantané).
  final Map<String, dynamic> inputs;

  /// Semaines du programme (schéma `programme_v33`), vides pour `template`.
  final List<Map<String, dynamic>> weeks;

  /// Annotations Koach générées (`exercises`, `weeks`).
  final Map<String, dynamic> koach;

  /// Résumé de la dernière génération (modèle, explication, niveaux…).
  final Map<String, dynamic> summary;

  /// Historique des générations : `{at, fromWeek, toWeek, cycle, seed,
  /// reason, generator}` (au plus 100 entrées).
  final List<Map<String, dynamic>> history;

  /// Rang du dernier cycle généré.
  final int cycle;

  /// Choix de l'utilisateur : `split` (auto, fullbody, upper_lower, ppl),
  /// `focus` (endurance).
  final Map<String, String> options;

  /// État précédent (annulation pendant 7 jours) : `{at, fromWeek,
  /// instance}` ; null sinon.
  final Map<String, dynamic>? undo;

  /// Empreinte du profil au moment de la génération (proposition de
  /// régénération quand elle change).
  final String profileKey;

  /// Empreinte SHA-256 du programme embarqué (`template`).
  final String? sourceSha;

  const ProgramInstance({
    this.version = kProgramInstanceVersion,
    required this.kind,
    required this.origin,
    required this.createdAt,
    required this.updatedAt,
    this.generator = kGeneratorVersion,
    this.models = '',
    this.seed = 0,
    this.inputs = const {},
    this.weeks = const [],
    this.koach = const {},
    this.summary = const {},
    this.history = const [],
    this.cycle = 0,
    this.options = const {},
    this.undo,
    this.profileKey = '',
    this.sourceSha,
  });

  bool get generated => kind == 'generated';

  /// Instance implicite d'une installation antérieure (modèle Expert
  /// streetlifting, programme embarqué inchangé).
  factory ProgramInstance.template({
    required String at,
    String origin = 'migration',
    String? sourceSha,
  }) => ProgramInstance(
    kind: 'template',
    origin: origin,
    createdAt: at,
    updatedAt: at,
    sourceSha: sourceSha,
    summary: const {'model': 'expert_streetlifting'},
  );

  ProgramInstance copyWith({
    String? origin,
    String? updatedAt,
    int? seed,
    Map<String, dynamic>? inputs,
    List<Map<String, dynamic>>? weeks,
    Map<String, dynamic>? koach,
    Map<String, dynamic>? summary,
    List<Map<String, dynamic>>? history,
    int? cycle,
    Map<String, String>? options,
    Map<String, dynamic>? undo,
    bool clearUndo = false,
    String? profileKey,
    String? kind,
    String? models,
    String? generator,
  }) => ProgramInstance(
    version: version,
    kind: kind ?? this.kind,
    origin: origin ?? this.origin,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    generator: generator ?? this.generator,
    models: models ?? this.models,
    seed: seed ?? this.seed,
    inputs: inputs ?? this.inputs,
    weeks: weeks ?? this.weeks,
    koach: koach ?? this.koach,
    summary: summary ?? this.summary,
    history: history ?? this.history,
    cycle: cycle ?? this.cycle,
    options: options ?? this.options,
    undo: clearUndo ? null : (undo ?? this.undo),
    profileKey: profileKey ?? this.profileKey,
    sourceSha: sourceSha,
  );

  Map<String, dynamic> toJson({bool withUndo = true}) => {
    'v': version,
    'kind': kind,
    'origin': origin,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'generator': generator,
    if (models.isNotEmpty) 'models': models,
    'seed': seed,
    if (inputs.isNotEmpty) 'inputs': inputs,
    if (weeks.isNotEmpty) 'weeks': weeks,
    if (koach.isNotEmpty) 'koach': koach,
    if (summary.isNotEmpty) 'summary': summary,
    if (history.isNotEmpty) 'history': history,
    'cycle': cycle,
    if (options.isNotEmpty) 'options': options,
    if (withUndo && undo != null) 'undo': undo,
    if (profileKey.isNotEmpty) 'profileKey': profileKey,
    if (sourceSha != null) 'sourceSha': sourceSha,
  };

  /// Lecture. [strict] (import d'un fichier) : toute valeur hors contrat
  /// lève [FormatException] ; sinon (démarrage) : null et [issues] + 1.
  static ProgramInstance? fromJson(
    Object? raw, {
    bool strict = false,
    List<String>? issues,
  }) {
    if (raw == null) return null;
    try {
      return _parse(raw);
    } on FormatException catch (e) {
      if (strict) rethrow;
      issues?.add(e.message);
      return null;
    } catch (_) {
      if (strict) {
        throw const FormatException('Programme personnalisé invalide.');
      }
      issues?.add('programInstance');
      return null;
    }
  }

  static ProgramInstance _parse(Object raw) {
    if (raw is! Map) {
      throw const FormatException('Programme : section invalide.');
    }
    final m = raw.cast<String, dynamic>();
    final v = m['v'];
    if (v is! int || v < 1 || v > kProgramInstanceVersion) {
      throw const FormatException('Programme : version non prise en charge.');
    }
    final kind = m['kind'];
    if (kind != 'template' && kind != 'generated') {
      throw const FormatException('Programme : sorte invalide.');
    }
    String str(String k, {int max = 200}) {
      final x = m[k];
      if (x is! String || x.length > max) {
        throw FormatException('Programme : $k invalide.');
      }
      return x;
    }

    final weeks = <Map<String, dynamic>>[];
    final rawWeeks = m['weeks'];
    if (rawWeeks != null) {
      if (rawWeeks is! List || rawWeeks.length > 520) {
        throw const FormatException('Programme : semaines invalides.');
      }
      for (var k = 0; k < rawWeeks.length; k++) {
        final w = rawWeeks[k];
        if (w is! Map || w['n'] != k + 1) {
          throw const FormatException('Programme : semaine invalide.');
        }
        final days = w['days'];
        if (days is! List || days.length != 7) {
          throw const FormatException('Programme : journées invalides.');
        }
        for (var j = 0; j < 7; j++) {
          final d = days[j];
          if (d is! Map ||
              d['j'] != j + 1 ||
              d['title'] is! String ||
              d['exercises'] is! List ||
              (d['exercises'] as List).length > 60) {
            throw const FormatException('Programme : journée invalide.');
          }
          for (final e in d['exercises'] as List) {
            if (e is! Map ||
                e['id'] is! String ||
                e['name'] is! String ||
                (e['name'] as String).length > 300 ||
                e['sets'] is! Map ||
                e['load'] is! Map) {
              throw const FormatException('Programme : exercice invalide.');
            }
          }
        }
        weeks.add(w.cast<String, dynamic>());
      }
    }
    if (kind == 'generated' && weeks.isEmpty) {
      throw const FormatException('Programme : semaines absentes.');
    }
    Map<String, dynamic> obj(String k) {
      final x = m[k];
      if (x == null) return {};
      if (x is! Map) throw FormatException('Programme : $k invalide.');
      return x.cast<String, dynamic>();
    }

    final history = <Map<String, dynamic>>[];
    for (final h in (m['history'] as List? ?? const [])) {
      if (h is! Map) throw const FormatException('Programme : historique.');
      history.add(h.cast<String, dynamic>());
    }
    if (history.length > 100) {
      throw const FormatException('Programme : historique trop long.');
    }
    final seed = m['seed'];
    final cycle = m['cycle'];
    if (seed is! int || cycle is! int || cycle < 0 || cycle > 1000) {
      throw const FormatException('Programme : graine ou cycle invalide.');
    }
    final options = <String, String>{};
    for (final e in obj('options').entries) {
      if (e.value is! String) {
        throw const FormatException('Programme : option invalide.');
      }
      options[e.key] = e.value as String;
    }
    final undo = m['undo'];
    if (undo != null && (undo is! Map || undo['instance'] is! Map)) {
      throw const FormatException('Programme : annulation invalide.');
    }
    final inputs = obj('inputs');
    if (inputs.isNotEmpty) GenInputs.fromJson(inputs); // contrôle strict
    return ProgramInstance(
      version: v,
      kind: kind as String,
      origin: str('origin'),
      createdAt: str('createdAt'),
      updatedAt: str('updatedAt'),
      generator: str('generator'),
      models: m['models'] as String? ?? '',
      seed: seed,
      inputs: inputs,
      weeks: weeks,
      koach: obj('koach'),
      summary: obj('summary'),
      history: history,
      cycle: cycle,
      options: options,
      undo: undo == null ? null : (undo as Map).cast<String, dynamic>(),
      profileKey: m['profileKey'] as String? ?? '',
      sourceSha: m['sourceSha'] as String?,
    );
  }

  /// Programme complet (schéma `programme_v33`) à partir du programme
  /// embarqué : même méta et même Pilotage, semaines de l'instance.
  Map<String, dynamic> programJson(Map<String, dynamic> base) {
    if (!generated) return base;
    return {
      'meta': {
        ...(base['meta'] as Map<String, dynamic>),
        'weeks': weeks.length,
        'generator': generator,
      },
      'pilotage': base['pilotage'],
      'weeks': weeks,
    };
  }

  /// Annotations Koach complètes (courbe et accessoires du programme
  /// embarqué, exercices et semaines de l'instance).
  Map<String, dynamic> koachJson(Map<String, dynamic> baseKoach) {
    if (!generated) return baseKoach;
    return {
      'version': 1,
      'source': {'generator': generator, 'seed': seed},
      'exercises': koach['exercises'] ?? const {},
      'accessories': baseKoach['accessories'] ?? const {},
      'weeks': koach['weeks'] ?? const {},
      'curve': baseKoach['curve'] ?? const {},
    };
  }

  /// Annulation encore possible à [now] (7 jours).
  bool canUndo(DateTime now) {
    final u = undo;
    if (u == null) return false;
    final at = DateTime.tryParse('${u['at']}');
    return at != null && now.difference(at) <= kRegenerationUndo;
  }
}

// ------------------------------------------------------------ fusion

/// Position (semaine, jour) d'une date pour un départ.
({int week, int day}) positionOf(DateTime start, DateTime date) {
  final o = civilDayIndex(date) - civilDayIndex(start);
  return (week: o < 0 ? 1 : o ~/ 7 + 1, day: o < 0 ? 1 : o % 7 + 1);
}

/// Semaines après une régénération à partir du jour [from] (semaine, jour) :
/// les journées antérieures, et toute journée qui a déjà un journal
/// ([hasLog]), restent celles de [oldWeeks] ; la suite vient de [newWeeks]
/// (numérotées à partir de `from.week`). L'historique n'est jamais modifié.
List<Map<String, dynamic>> mergeWeeks({
  required List<Map<String, dynamic>> oldWeeks,
  required List<Map<String, dynamic>> newWeeks,
  required ({int week, int day}) from,
  required bool Function(int week, int day) hasLog,
}) {
  final out = <Map<String, dynamic>>[];
  for (final w in oldWeeks) {
    final n = w['n'] as int;
    if (n < from.week) out.add(w);
  }
  // Semaines manquantes avant la reprise (programme plus court que la
  // date) : journées de repos, pour garder une numérotation continue.
  for (var n = out.length + 1; n < from.week; n++) {
    out.add(restWeek(n));
  }
  for (final w in newWeeks) {
    final n = w['n'] as int;
    if (n != from.week) {
      out.add(w);
      continue;
    }
    final old = oldWeeks.where((x) => x['n'] == n).toList();
    if (old.isEmpty) {
      out.add(w);
      continue;
    }
    final days = <Map<String, dynamic>>[];
    for (var j = 1; j <= 7; j++) {
      final keepOld = j < from.day || hasLog(n, j);
      final src = keepOld ? old.first : w;
      days.add(((src['days'] as List)[j - 1] as Map).cast<String, dynamic>());
    }
    out.add({...w, 'days': days});
  }
  // Journées futures ayant déjà un journal (séance commencée à l'avance) :
  // conservées aussi.
  for (var k = 0; k < out.length; k++) {
    final n = out[k]['n'] as int;
    if (n <= from.week) continue;
    final old = oldWeeks.where((x) => x['n'] == n).toList();
    if (old.isEmpty) continue;
    final days = [
      for (final d in out[k]['days'] as List)
        (d as Map).cast<String, dynamic>(),
    ];
    var changed = false;
    for (var j = 1; j <= 7; j++) {
      if (hasLog(n, j)) {
        days[j - 1] = ((old.first['days'] as List)[j - 1] as Map)
            .cast<String, dynamic>();
        changed = true;
      }
    }
    if (changed) out[k] = {...out[k], 'days': days};
  }
  return out;
}

Map<String, dynamic> restWeek(int n) => {
  'n': n,
  'dates': '',
  'block': 'Pause',
  'blockKey': 'P',
  'color': '808080',
  'kind': 'rest',
  'days': [
    for (var j = 1; j <= 7; j++)
      {
        'j': j,
        'title': 'REPOS',
        'cycle': '',
        'conduite': '',
        'exercises': <Map<String, dynamic>>[],
      },
  ],
};

/// Semaines du programme embarqué (copie profonde) : point de départ d'une
/// instance générée qui remplace le modèle Expert streetlifting en cours de
/// route (semaines passées conservées à l'identique).
List<Map<String, dynamic>> copyWeeks(List<dynamic> weeks) => [
  for (final w in weeks)
    (jsonDecode(jsonEncode(w)) as Map).cast<String, dynamic>(),
];

// ------------------------------------------------------------ « ce qui change »

class WeekChange {
  final int week;
  final List<String> lines;
  const WeekChange(this.week, this.lines);
}

class ProgramDiff {
  final List<WeekChange> weeks;
  final String modelBefore, modelAfter;
  final int sessionsBefore, sessionsAfter; // séances par semaine (1re semaine)
  final int minutesBefore, minutesAfter; // durée moyenne estimée
  final Map<String, (int, int)>
  volume; // groupe → (avant, après), 1re semaine complète
  const ProgramDiff({
    required this.weeks,
    required this.modelBefore,
    required this.modelAfter,
    required this.sessionsBefore,
    required this.sessionsAfter,
    required this.minutesBefore,
    required this.minutesAfter,
    required this.volume,
  });

  bool get empty =>
      weeks.every((w) => w.lines.isEmpty) && modelBefore == modelAfter;
}

String _dayLabel(Map<String, dynamic> d) {
  final ex = (d['exercises'] as List).length;
  return ex == 0 ? 'repos' : '${d['title']} ($ex exercices)';
}

/// Aperçu « ce qui change » entre deux versions de la suite du programme,
/// à partir de (semaine, jour) [from], sur [horizon] semaines.
ProgramDiff diffWeeks({
  required List<Map<String, dynamic>> before,
  required List<Map<String, dynamic>> after,
  required ({int week, int day}) from,
  required String modelBefore,
  required String modelAfter,
  int horizon = 2,
}) {
  final changes = <WeekChange>[];
  Map<String, dynamic>? weekOf(List<Map<String, dynamic>> l, int n) {
    for (final w in l) {
      if (w['n'] == n) return w;
    }
    return null;
  }

  for (var n = from.week; n < from.week + horizon; n++) {
    final a = weekOf(before, n), b = weekOf(after, n);
    final lines = <String>[];
    for (var j = 1; j <= 7; j++) {
      if (n == from.week && j < from.day) continue;
      final da = a == null
          ? null
          : ((a['days'] as List)[j - 1] as Map).cast<String, dynamic>();
      final db = b == null
          ? null
          : ((b['days'] as List)[j - 1] as Map).cast<String, dynamic>();
      final la = da == null ? 'rien' : _dayLabel(da);
      final lb = db == null ? 'rien' : _dayLabel(db);
      final namesA = {
        for (final e in (da?['exercises'] as List? ?? const []))
          '${(e as Map)['name']}'.split(' — ').first,
      };
      final namesB = {
        for (final e in (db?['exercises'] as List? ?? const []))
          '${(e as Map)['name']}'.split(' — ').first,
      };
      if (la != lb) lines.add('J$j : $la → $lb');
      final added = namesB.difference(namesA).toList()..sort();
      final removed = namesA.difference(namesB).toList()..sort();
      if (added.isNotEmpty) lines.add('J$j : + ${added.join(', ')}');
      if (removed.isNotEmpty) lines.add('J$j : − ${removed.join(', ')}');
    }
    changes.add(WeekChange(n, lines));
  }
  (int, int, Map<String, int>) stats(Map<String, dynamic>? w) {
    if (w == null) return (0, 0, {});
    var sessions = 0, seconds = 0;
    final vol = <String, int>{};
    for (final d in w['days'] as List) {
      final dm = d as Map;
      final ex = dm['exercises'] as List;
      if (ex.isEmpty) continue;
      sessions++;
      seconds += (dm['estimate'] as int?) ?? 0;
      for (final e in ex) {
        final em = e as Map;
        final hard = em['hard'];
        if (hard is! int) continue;
        for (final g in (em['groups'] as List? ?? const [])) {
          vol['$g'] = (vol['$g'] ?? 0) + hard;
        }
      }
    }
    return (
      sessions,
      sessions == 0 ? 0 : (seconds / sessions / 60).round(),
      vol,
    );
  }

  final next = from.day == 1 ? from.week : from.week + 1;
  final sa = stats(weekOf(before, next)), sb = stats(weekOf(after, next));
  final groups = {...sa.$3.keys, ...sb.$3.keys}.toList()..sort();
  return ProgramDiff(
    weeks: changes,
    modelBefore: modelBefore,
    modelAfter: modelAfter,
    sessionsBefore: sa.$1,
    sessionsAfter: sb.$1,
    minutesBefore: sa.$2,
    minutesAfter: sb.$2,
    volume: {for (final g in groups) g: (sa.$3[g] ?? 0, sb.$3[g] ?? 0)},
  );
}
