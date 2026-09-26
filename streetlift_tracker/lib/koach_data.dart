// Koach (L7, KT-025, KT-029, KT-030, KT-032, KT-034, KT-036) — données
// persistées. L'état de Koach (estimations, biais, courbes) n'est jamais
// sauvegardé : il est recalculé depuis le journal (D31). Sont persistés
// uniquement les décisions et saisies de l'utilisateur : options, pesées,
// historique daté des valeurs de pilotage, acceptations et refus, verrous,
// réponses aux questionnaires, matériel, objectifs, adaptations, allègements.
// Format et bornes : docs/CONTRAT_L7.md §3.4.

import 'koach_engine.dart' show defaultEquipment, parseDt;

final RegExp _dayRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');

double _d(Object? v) => (v as num).toDouble();

bool _okNum(Object? v, double lo, double hi) =>
    v is num && v.isFinite && v >= lo && v <= hi;

/// Pesée (D12) : une par jour civil.
class WeighIn {
  final String date; // AAAA-MM-JJ
  final double kg;
  const WeighIn(this.date, this.kg);

  Map<String, dynamic> toJson() => {'date': date, 'kg': kg};
}

/// Valeur de pilotage datée (D30, D33) : `initial`, `manual`, `koach`, `test`.
class PilotageEvent {
  final String at; // horodatage local
  final String ref;
  final double value;
  final String source;
  const PilotageEvent(this.at, this.ref, this.value, this.source);

  Map<String, dynamic> toJson() => {
    'at': at,
    'ref': ref,
    'value': value,
    'source': source,
  };
}

/// Décision de l'utilisateur sur une proposition de Koach (D4, D7).
class KoachDecision {
  final String at;
  final String id;
  final String kind; // value | pain | painEnd | fatigue | inSession | structure
  final String status; // accepted | refused
  final Map<String, dynamic> detail;
  const KoachDecision(this.at, this.id, this.kind, this.status, this.detail);

  Map<String, dynamic> toJson() => {
    'at': at,
    'id': id,
    'kind': kind,
    'status': status,
    if (detail.isNotEmpty) 'detail': detail,
  };
}

/// Réponses facultatives d'une séance (D14) : données de santé potentielles.
class SessionAnswers {
  double? sleep; // heures
  int? form; // /10
  final Map<String, int> pain; // mouvement → 0-10
  SessionAnswers({this.sleep, this.form, Map<String, int>? pain})
    : pain = pain ?? {};

  bool get isEmpty => sleep == null && form == null && pain.isEmpty;

  Map<String, dynamic> toJson() => {
    if (sleep != null) 'sleep': sleep,
    if (form != null) 'form': form,
    if (pain.isNotEmpty) 'pain': pain,
  };
}

/// Adaptation de structure acceptée (D28) : couche datée et réversible.
class Adaptation {
  final String id;
  final String at;
  final int week;
  final String kind; // sets | deload
  final String movement;
  final String? exercise;
  final int delta;
  final double sets;
  final double load;
  String status; // active | reverted
  String? revertedAt;
  Adaptation({
    required this.id,
    required this.at,
    required this.week,
    required this.kind,
    required this.movement,
    this.exercise,
    this.delta = 0,
    this.sets = 1,
    this.load = 0,
    this.status = 'active',
    this.revertedAt,
  });

  bool get active => status == 'active';

  Map<String, dynamic> toJson() => {
    'id': id,
    'at': at,
    'week': week,
    'kind': kind,
    'movement': movement,
    if (exercise != null) 'exercise': exercise,
    if (delta != 0) 'delta': delta,
    if (kind == 'deload') 'sets': sets,
    if (kind == 'deload') 'load': load,
    'status': status,
    if (revertedAt != null) 'revertedAt': revertedAt,
  };
}

/// Objectif modifié par l'utilisateur (D27) ; absent = valeur par défaut.
class Objective {
  final double? target;
  final String? date; // AAAA-MM-JJ
  const Objective(this.target, this.date);

  Map<String, dynamic> toJson() => {
    if (target != null) 'target': target,
    if (date != null) 'date': date,
  };
}

class KoachData {
  bool enabled = false;
  bool structure = false;
  bool advanced = false;
  String questionnaires = 'unset'; // unset | on | off
  String? legacyScale; // rir | rpe (figé à la première activation)
  bool introSeen = false;
  final List<WeighIn> weighIns = [];
  final List<PilotageEvent> history = [];
  final List<KoachDecision> decisions = [];
  final Set<String> locks = {};
  final Map<String, SessionAnswers> answers = {};
  final Map<String, Map<String, dynamic>> equipment = {};
  final Map<String, Map<String, Objective>> objectives = {};
  final List<Adaptation> adaptations = [];
  final Map<String, String> painRelief = {};

  KoachData();

  /// Aucune donnée ni option : rien n'est écrit dans la sauvegarde (export
  /// identique à 2.5.9 tant que Koach n'a jamais servi).
  bool get pristine =>
      !enabled &&
      !structure &&
      !advanced &&
      questionnaires == 'unset' &&
      legacyScale == null &&
      !introSeen &&
      weighIns.isEmpty &&
      history.isEmpty &&
      decisions.isEmpty &&
      locks.isEmpty &&
      answers.isEmpty &&
      equipment.isEmpty &&
      objectives.isEmpty &&
      adaptations.isEmpty &&
      painRelief.isEmpty;

  /// Incréments du matériel : réglages de l'utilisateur, sinon défauts D23.
  Map<String, dynamic> get equipmentSettings => {
    for (final e in defaultEquipment.entries)
      e.key: {...e.value, ...?equipment[e.key]},
  };

  Map<String, dynamic> toJson() => {
    'v': 1,
    'enabled': enabled,
    if (structure) 'structure': true,
    if (advanced) 'advanced': true,
    'questionnaires': questionnaires,
    if (legacyScale != null) 'legacyScale': legacyScale,
    if (introSeen) 'introSeen': true,
    if (weighIns.isNotEmpty) 'weighIns': [for (final w in weighIns) w.toJson()],
    if (history.isNotEmpty) 'history': [for (final h in history) h.toJson()],
    if (decisions.isNotEmpty)
      'decisions': [for (final d in decisions) d.toJson()],
    if (locks.isNotEmpty) 'locks': (locks.toList()..sort()),
    if (answers.isNotEmpty)
      'answers': {
        for (final e in answers.entries)
          if (!e.value.isEmpty) e.key: e.value.toJson(),
      },
    if (equipment.isNotEmpty) 'equipment': equipment,
    if (objectives.isNotEmpty)
      'objectives': {
        for (final e in objectives.entries)
          e.key: {for (final o in e.value.entries) o.key: o.value.toJson()},
      },
    if (adaptations.isNotEmpty)
      'adaptations': [for (final a in adaptations) a.toJson()],
    if (painRelief.isNotEmpty) 'painRelief': painRelief,
  };

  /// Lecture d'une section `koach`. [strict] (import d'un fichier) : toute
  /// valeur hors contrat refuse la section entière (FormatException, rien
  /// n'est modifié). Sinon (document de l'application relu au démarrage) :
  /// une entrée illisible est ignorée, les autres sont gardées ; [issues]
  /// compte les entrées ignorées.
  static KoachData fromJson(
    Object? raw, {
    required Set<String> knownRefs,
    required Set<String> movements,
    bool strict = false,
    List<String>? issues,
  }) {
    final out = KoachData();
    if (raw == null) return out;
    if (raw is! Map) {
      if (strict) throw const FormatException('Section Koach invalide.');
      issues?.add('koach');
      return out;
    }
    void bad(String what) {
      if (strict) throw FormatException('Koach : $what invalide.');
      issues?.add(what);
    }

    bool flag(String k) {
      final v = raw[k];
      if (v == null) return false;
      if (v is bool) return v;
      bad(k);
      return false;
    }

    out.enabled = flag('enabled');
    out.structure = flag('structure');
    out.advanced = flag('advanced');
    out.introSeen = flag('introSeen');
    final q = raw['questionnaires'];
    if (q != null) {
      if (q is String && const ['unset', 'on', 'off'].contains(q)) {
        out.questionnaires = q;
      } else {
        bad('questionnaires');
      }
    }
    final ls = raw['legacyScale'];
    if (ls != null) {
      if (ls == 'rir' || ls == 'rpe') {
        out.legacyScale = ls as String;
      } else {
        bad('legacyScale');
      }
    }
    List<Object?> list(String k, int limit) {
      final v = raw[k];
      if (v == null) return const [];
      if (v is! List || v.length > limit) {
        bad(k);
        return const [];
      }
      return v;
    }

    final days = <String>{};
    for (final e in list('weighIns', 2000)) {
      if (e is Map &&
          e['date'] is String &&
          _dayRe.hasMatch(e['date'] as String) &&
          parseDt(e['date'] as String) != null &&
          _okNum(e['kg'], 20, 400) &&
          days.add(e['date'] as String)) {
        out.weighIns.add(WeighIn(e['date'] as String, _d(e['kg'])));
      } else {
        bad('pesée');
      }
    }
    out.weighIns.sort((a, b) => a.date.compareTo(b.date));
    for (final e in list('history', 5000)) {
      if (e is Map &&
          e['at'] is String &&
          parseDt(e['at'] as String) != null &&
          e['ref'] is String &&
          knownRefs.contains(e['ref']) &&
          _okNum(e['value'], 0, 10000) &&
          const ['initial', 'manual', 'koach', 'test'].contains(e['source'])) {
        out.history.add(
          PilotageEvent(
            e['at'] as String,
            e['ref'] as String,
            _d(e['value']),
            e['source'] as String,
          ),
        );
      } else {
        bad('historique');
      }
    }
    for (final e in list('decisions', 10000)) {
      if (e is Map &&
          e['at'] is String &&
          parseDt(e['at'] as String) != null &&
          e['id'] is String &&
          (e['id'] as String).isNotEmpty &&
          (e['id'] as String).length <= 200 &&
          const [
            'value',
            'pain',
            'painEnd',
            'fatigue',
            'inSession',
            'structure',
          ].contains(e['kind']) &&
          (e['status'] == 'accepted' || e['status'] == 'refused') &&
          (e['detail'] == null || e['detail'] is Map)) {
        out.decisions.add(
          KoachDecision(
            e['at'] as String,
            e['id'] as String,
            e['kind'] as String,
            e['status'] as String,
            e['detail'] == null
                ? const {}
                : Map<String, dynamic>.from(e['detail'] as Map),
          ),
        );
      } else {
        bad('décision');
      }
    }
    for (final e in list('locks', 200)) {
      if (e is String && knownRefs.contains(e)) {
        out.locks.add(e);
      } else {
        bad('verrou');
      }
    }
    final answers = raw['answers'];
    if (answers != null) {
      if (answers is! Map || answers.length > 400) {
        bad('questionnaires');
      } else {
        answers.forEach((k, v) {
          if (k is! String ||
              !RegExp(r'^S\d+-J\d+$').hasMatch(k) ||
              v is! Map) {
            bad('questionnaire');
            return;
          }
          final a = SessionAnswers();
          final sleep = v['sleep'], form = v['form'], pain = v['pain'];
          if (sleep != null) {
            if (_okNum(sleep, 0, 24)) {
              a.sleep = _d(sleep);
            } else {
              bad('sommeil');
            }
          }
          if (form != null) {
            if (form is int && form >= 0 && form <= 10) {
              a.form = form;
            } else {
              bad('forme');
            }
          }
          if (pain != null) {
            if (pain is Map) {
              pain.forEach((m, n) {
                if (m is String &&
                    movements.contains(m) &&
                    n is int &&
                    n >= 0 &&
                    n <= 10) {
                  a.pain[m] = n;
                } else {
                  bad('douleur');
                }
              });
            } else {
              bad('douleur');
            }
          }
          if (!a.isEmpty) out.answers[k] = a;
        });
      }
    }
    final eq = raw['equipment'];
    if (eq != null) {
      if (eq is! Map) {
        bad('matériel');
      } else {
        eq.forEach((k, v) {
          if (k is! String || !defaultEquipment.containsKey(k) || v is! Map) {
            bad('matériel');
            return;
          }
          final m = <String, dynamic>{};
          var ok = true;
          v.forEach((kk, vv) {
            if (kk == 'unit') {
              if (vv == 'kg' || vv == 'lb') {
                m['unit'] = vv;
              } else {
                ok = false;
              }
            } else if (const [
                  'small',
                  'threshold',
                  'large',
                  'step',
                ].contains(kk) &&
                _okNum(vv, 0.01, 50)) {
              m[kk as String] = _d(vv);
            } else {
              ok = false;
            }
          });
          if (ok && m.isNotEmpty) {
            out.equipment[k] = m;
          } else {
            bad('matériel');
          }
        });
      }
    }
    final objs = raw['objectives'];
    if (objs != null) {
      if (objs is! Map) {
        bad('objectifs');
      } else {
        objs.forEach((ref, levels) {
          if (ref is! String || !knownRefs.contains(ref) || levels is! Map) {
            bad('objectif');
            return;
          }
          final m = <String, Objective>{};
          levels.forEach((level, o) {
            if ((level == 'stage' || level == 'final') &&
                o is Map &&
                (o['target'] == null || _okNum(o['target'], 0, 10000)) &&
                (o['date'] == null ||
                    (o['date'] is String &&
                        _dayRe.hasMatch(o['date'] as String) &&
                        parseDt(o['date'] as String) != null))) {
              m[level as String] = Objective(
                o['target'] == null ? null : _d(o['target']),
                o['date'] as String?,
              );
            } else {
              bad('objectif');
            }
          });
          if (m.isNotEmpty) out.objectives[ref] = m;
        });
      }
    }
    final ids = <String>{};
    for (final e in list('adaptations', 1000)) {
      if (e is Map &&
          e['id'] is String &&
          ids.add(e['id'] as String) &&
          e['at'] is String &&
          parseDt(e['at'] as String) != null &&
          e['week'] is int &&
          (e['week'] as int) >= 1 &&
          (e['week'] as int) <= 40 &&
          (e['kind'] == 'sets' || e['kind'] == 'deload') &&
          e['movement'] is String &&
          movements.contains(e['movement']) &&
          (e['exercise'] == null || e['exercise'] is String) &&
          (e['delta'] == null || e['delta'] == 1 || e['delta'] == -1) &&
          (e['sets'] == null || _okNum(e['sets'], 0.1, 1)) &&
          (e['load'] == null || _okNum(e['load'], 0, 0.5)) &&
          (e['status'] == 'active' || e['status'] == 'reverted') &&
          (e['revertedAt'] == null || e['revertedAt'] is String)) {
        out.adaptations.add(
          Adaptation(
            id: e['id'] as String,
            at: e['at'] as String,
            week: e['week'] as int,
            kind: e['kind'] as String,
            movement: e['movement'] as String,
            exercise: e['exercise'] as String?,
            delta: (e['delta'] as int?) ?? 0,
            sets: e['sets'] == null ? 1 : _d(e['sets']),
            load: e['load'] == null ? 0 : _d(e['load']),
            status: e['status'] as String,
            revertedAt: e['revertedAt'] as String?,
          ),
        );
      } else {
        bad('adaptation');
      }
    }
    final relief = raw['painRelief'];
    if (relief != null) {
      if (relief is! Map) {
        bad('allègement');
      } else {
        relief.forEach((k, v) {
          if (k is String &&
              movements.contains(k) &&
              v is String &&
              parseDt(v) != null) {
            out.painRelief[k] = v;
          } else {
            bad('allègement');
          }
        });
      }
    }
    return out;
  }

  /// Copie indépendante (aperçu d'import, effacement).
  KoachData copy({
    required Set<String> knownRefs,
    required Set<String> movements,
  }) =>
      KoachData.fromJson(toJson(), knownRefs: knownRefs, movements: movements);
}
