// RV4 (dev7.7.2, DECISIONS_CP.md C17.51.5) — changements du jour d'une
// séance : exercice remplacé pour cette séance seulement, ligne retirée pour
// aujourd'hui (raison au choix). Le programme écrit n'est jamais modifié.
//
// - Les changements sont gardés dans la séance (`SessionLog.changes`, par
//   identifiant de la ligne écrite) et posés sur la journée affichée
//   ([SessionDayChanges.withDayChanges]) : séance servie par Koach, par le
//   moteur d'avant ou telle qu'écrite.
// - Remplacement : l'exercice choisi garde l'emplacement (séries écrites,
//   groupe et format, chrono, repos) ; son journal porte son nom
//   (`<ligne>~<exercice>`) : Koach reçoit l'exercice réel (sans cible du
//   moteur sur la ligne remplacée). Un exercice personnel (hors de la base)
//   est noté comme tout exercice inconnu de Koach : rien ne lui est versé.
// - Retrait : la ligne disparaît de la séance du jour, son groupe au chrono
//   se recale sur les lignes restantes (règle de KB5) ; avant le début de
//   la séance, Koach la sert sans cette ligne. Annulable tant que la séance
//   n'est pas finie.
part of 'store.dart';

/// RV4 : raisons d'un retrait pour aujourd'hui, dans l'ordre de la feuille.
const kDayRemovalReasons = <String, String>{
  'materiel': 'Pas de matériel',
  'douleur': 'Douleur',
  'temps': 'Manque de temps',
  'autre': 'Autre raison',
};

/// RV4 : identifiant de la ligne écrite d'un exercice affiché (sans le
/// remplaçant `~…` ni le suffixe d'un test inséré par Koach). Pur.
String dayChangeKey(String id) {
  var base = id.split('~').first;
  if (base.endsWith(kKoachTestSuffix)) {
    base = base.substring(0, base.length - kKoachTestSuffix.length);
  }
  return base;
}

/// RV4 : identifiant d'un exercice personnel remplaçant (hors de la base).
String dayCustomId(String name) =>
    'perso-${normalizeText(name).replaceAll(RegExp(r'[^a-z0-9]+'), '-')}';

/// RV4 : séries d'un remplaçant d'une autre unité que la ligne écrite :
/// le nombre de séries et le format (« · E2MOM ») sont gardés, la cible de
/// chaque série passe dans l'unité du remplaçant ([seconds] : tenue en
/// secondes ; sinon répétitions), à [value] (historique de l'exercice) ou à
/// une valeur de départ (30 s, 8 répétitions : choix raisonné, la saisie
/// reste libre). Null : libellé non reconnu (gardé tel quel). Pur.
String? daySetsInUnit(String label, {required bool seconds, int? value}) {
  final m = RegExp(
    r'^(\s*\d+\s*[×x]\s*)(\d+(?:\s*-\s*\d+)?)(\s*s\b)?',
  ).firstMatch(label);
  if (m == null) return null;
  final v = value ?? (seconds ? 30 : 8);
  return '${m.group(1)}$v${seconds ? ' s' : ''}${label.substring(m.end)}';
}

extension SessionDayChanges on AppStore {
  /// Changements du jour de la séance S[week]·J[j].
  Map<String, Map<String, dynamic>> dayChanges(int week, int j) =>
      logs[sessionKey(week, j)]?.changes ?? const {};

  /// Changement du jour de l'exercice affiché [id] (null : aucun).
  Map<String, dynamic>? dayChangeOf(int week, int j, String id) =>
      dayChanges(week, j)[dayChangeKey(id)];

  /// Emplacements (programme créé ou importé) des lignes retirées pour
  /// aujourd'hui de S[week]·J[j].
  Set<String> dayRemovedSlots(int week, int j) => {
    for (final e in dayChanges(week, j).entries)
      if (e.value['type'] == 'retrait')
        if (SessionAdaptStore(this).adaptSlotOf(week, j, e.key) case final s?)
          s,
  };

  /// Journée [d] (semaine [week]) avec ses changements du jour : lignes
  /// retirées enlevées, exercices remplacés à leur place. Le test court
  /// inséré par Koach avant une ligne changée part avec elle.
  DayPlan withDayChanges(int week, DayPlan d) {
    final ch = dayChanges(week, d.j);
    if (ch.isEmpty) return d;
    final out = <Exercise>[];
    var changed = false;
    for (final e in d.exercises) {
      final c = ch[dayChangeKey(e.id)];
      if (c == null) {
        out.add(e);
        continue;
      }
      if (e.id.endsWith(kKoachTestSuffix) || c['type'] == 'retrait') {
        changed = true;
        continue;
      }
      if (c['type'] == 'remplace') {
        final x = _dayReplaced(e, c);
        changed = changed || !identical(x, e);
        out.add(x);
        continue;
      }
      out.add(e);
    }
    return changed ? DayPlan.adapted(d, out) : d;
  }

  /// Identifiant du remplaçant de la ligne [key] par [to] (base) ou
  /// l'exercice personnel [name].
  String _dayReplacedId(String key, String? to, String name) =>
      '$key~${to ?? dayCustomId(name)}';

  /// Exercice [e] (ligne affichée) remplacé selon [c] : même emplacement,
  /// mêmes séries, même format et chrono ; nom, fiche et charge du
  /// remplaçant ; plus de cible du moteur sur la ligne.
  Exercise _dayReplaced(Exercise e, Map<String, dynamic> c) {
    final to = c['to'] as String?;
    final name = '${c['name']}';
    final id = _dayReplacedId(dayChangeKey(e.id), to, name);
    if (e.id == id) return e;
    final entry = to == null ? null : content.byId[to];
    // « enchaîné » reste dans le nom : la ligne garde sa page d'enchaînement
    // (règle des protocoles).
    final chained = e.name.toLowerCase().contains('enchaîn');
    final label = setsLabel(e);
    final spec = logSpec(e);
    final wasSeconds = spec.kind == 'hold' || spec.kind == 'holdMax';
    final seconds = c['secondes'] as bool?;
    final converted = seconds == null || seconds == wasSeconds
        ? null
        : daySetsInUnit(
            label,
            seconds: seconds,
            value: (c['valeur'] as num?)?.toInt(),
          );
    final kg = (c['kg'] as num?)?.toDouble();
    // Une consigne de charge de la ligne écrite (« +15 kg », « 80 % »)
    // ne vaut pas pour le remplaçant.
    final intensity = RegExp(r'kg|lest|%').hasMatch(e.intensity.toLowerCase())
        ? ''
        : e.intensity;
    final from = splitName('${c['from'] ?? e.name}').$1;
    return Exercise.adapted(
      e,
      id: id,
      name: chained ? '$name — enchaîné' : name,
      sets: converted != null
          ? SetsSpec.text(converted)
          : e.sets.type == 'volume'
          ? SetsSpec.text(label)
          : null,
      load: LoadSpec.fixed(kg),
      cue: entry?.ex.keyPoints.firstOrNull ?? '',
      why: 'Remplace « $from » aujourd’hui.',
      catalogId: to,
      clearCatalog: to == null,
      intensity: intensity,
      engine: false,
    );
  }

  /// La ligne affichée [e] de S[week]·J[j] peut être remplacée ou retirée
  /// pour aujourd'hui : séance pas finie, aucune série validée sur la
  /// ligne, pas un test court inséré par Koach.
  bool dayCanChange(int week, int j, Exercise e) {
    final log = logs[sessionKey(week, j)];
    if (log?.done ?? false) return false;
    if (e.id.endsWith(kKoachTestSuffix) || e.isGtg) return false;
    return !(log?.ex[e.id]?.sets.any((s) => s.done) ?? false);
  }

  /// Propositions de remplacement de [e] (en tête de la liste) : les
  /// exercices de la base les plus proches (muscles, schéma, famille,
  /// difficulté : proximité de base de `kalis_core`).
  List<String> dayReplaceProposals(Exercise e, {int count = 6}) {
    final cat = content.catalog;
    final from = e.catalogId ?? content.idFor(e.name);
    if (cat == null || from == null || !cat.contains(from)) return const [];
    final scored = <(String, double)>[
      for (final x in cat.exercises)
        if (x.id != from && !x.assisted) (x.id, cat.similarity(from, x.id)),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final x in scored.take(count)) x.$1];
  }

  /// Dernière série faite de l'exercice [to] (base) ou de l'exercice
  /// personnel [name] dans le journal : charge et répétitions (ou
  /// secondes). Null : jamais fait.
  ({double? kg, int? value})? dayLastPerformance(String? to, String name) {
    final title = normalizeText(splitName(name).$1);
    String? best;
    ({double? kg, int? value})? out;
    for (final sl in logs.values) {
      for (final x in sl.ex.entries) {
        final nm = sl.exerciseNames[x.key];
        final match = to != null
            ? x.key.endsWith('~$to') || (nm != null && content.idFor(nm) == to)
            : nm != null && normalizeText(splitName(nm).$1) == title;
        if (!match) continue;
        for (final s in x.value.sets) {
          if (!s.done) continue;
          final at = s.completedAt ?? sl.finishedAt ?? '';
          if (best != null && at.compareTo(best) < 0) continue;
          best = at;
          out = (
            kg: double.tryParse(s.kg.replaceAll(',', '.')),
            value: parseWholeNumber(s.reps),
          );
        }
      }
    }
    return out;
  }

  /// Remplace la ligne affichée [e] de la séance S[week]·J[day.j] par
  /// l'exercice [to] de la base (ou l'exercice personnel [name] si [to]
  /// est null) pour cette séance seulement. Charge proposée : celle de la
  /// dernière fois (rien sinon, à saisir). Choisir l'exercice écrit lui-même
  /// annule le remplacement.
  void dayReplace(
    int week,
    DayPlan day,
    Exercise e, {
    String? to,
    required String name,
  }) {
    if (!dayCanChange(week, day.j, e)) return;
    final key = dayChangeKey(e.id);
    final log = sessionLog(week, day.j);
    final before = log.changes[key];
    final written = SessionAdaptStore(
      this,
    ).programExerciseOf(week, day.j, Exercise.adapted(e, id: key));
    final writtenId = written == null
        ? null
        : written.catalogId ?? content.idFor(written.name);
    _dayDropLog(log, e.id);
    if (to != null && before != null && to == writtenId) {
      log.changes.remove(key);
      saveLogs();
      notifyListeners();
      return;
    }
    final entry = to == null ? null : content.byId[to];
    final perf = dayLastPerformance(to, name);
    const loaded = {
      kc.LoadType.addedWeight,
      kc.LoadType.barbell,
      kc.LoadType.dumbbells,
      kc.LoadType.kettlebell,
      kc.LoadType.machine,
      kc.LoadType.cable,
    };
    final kg = perf?.kg;
    log.changes[key] = {
      'type': 'remplace',
      'to': to,
      'name': entry?.nom ?? name,
      'from': before?['from'] ?? e.name,
      if (entry != null) 'secondes': entry.ex.unit == kc.MeasureUnit.seconds,
      if (perf?.value case final v? when v > 0) 'valeur': v,
      if (kg != null && kg > 0) 'kg': kg,
    };
    // Colonne de charge ouverte d'emblée pour un exercice chargé sans
    // historique (la charge se saisit).
    if (entry != null &&
        loaded.contains(entry.ex.loadType) &&
        (kg == null || kg <= 0)) {
      final id = _dayReplacedId(key, to, name);
      final x = log.ex[id];
      if (x == null || !x.sets.any((s) => s.done)) {
        log.ex.remove(id);
        final shown = withDayChanges(week, day);
        for (final y in shown.exercises) {
          if (y.id == id) exLog(week, day.j, y).showKg = true;
        }
      }
    }
    saveLogs();
    notifyListeners();
  }

  /// Retire la ligne affichée [e] de la séance S[week]·J[day.j] pour
  /// aujourd'hui, raison [reason] (`kDayRemovalReasons`).
  void dayRemove(int week, DayPlan day, Exercise e, String reason) {
    if (!dayCanChange(week, day.j, e)) return;
    final key = dayChangeKey(e.id);
    final log = sessionLog(week, day.j);
    final before = log.changes[key];
    _dayDropLog(log, e.id);
    log.changes[key] = {
      'type': 'retrait',
      'reason': kDayRemovalReasons.containsKey(reason) ? reason : 'autre',
      'from': before?['from'] ?? e.name,
    };
    saveLogs();
    notifyListeners();
  }

  /// Annule le changement du jour de la ligne écrite [key] (séance pas
  /// finie) : la ligne revient telle que la séance la sert.
  void dayUndo(int week, DayPlan day, String key) {
    final log = logs[sessionKey(week, day.j)];
    if (log == null || log.done) return;
    final c = log.changes[key];
    if (c == null) return;
    if (c['type'] == 'remplace') {
      final id = _dayReplacedId(key, c['to'] as String?, '${c['name']}');
      if (log.ex[id]?.sets.any((s) => s.done) ?? false) return;
      _dayDropLog(log, id);
    }
    log.changes.remove(key);
    // Ligne retirée avant le début de la séance de Koach : absente de la
    // séance servie, elle revient telle qu'écrite.
    if (c['type'] == 'retrait') {
      final slot = SessionAdaptStore(this).adaptSlotOf(week, day.j, key);
      if (slot != null) koachRemettreLigne(week, day, slot);
    }
    saveLogs();
    notifyListeners();
  }

  /// Lignes retirées pour aujourd'hui de S[week]·J[j] : (clé, nom, raison).
  List<({String key, String name, String reason})> dayRemovedLines(
    int week,
    int j,
  ) => [
    for (final e in dayChanges(week, j).entries)
      if (e.value['type'] == 'retrait')
        (
          key: e.key,
          name: splitName('${e.value['from'] ?? e.key}').$1,
          reason: kDayRemovalReasons[e.value['reason']] ?? 'Autre raison',
        ),
  ];

  /// Journal de la ligne [id] sans série validée : retiré de la séance (la
  /// ligne change) ; une ligne qui a des séries validées n'est jamais
  /// touchée.
  void _dayDropLog(SessionLog log, String id) {
    for (final k in [id, '$id$kKoachTestSuffix']) {
      final x = log.ex[k];
      if (x != null && x.sets.any((s) => s.done)) continue;
      log.ex.remove(k);
      log.exerciseNames.remove(k);
    }
  }
}
