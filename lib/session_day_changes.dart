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
// - KB6 (dev7.8.0, Koach 1.0.9, C17.54-55) : propositions de Koach
//   (`Koach.remplacants`), groupées et étiquetées (« Équivalent », « Plus
//   facile », « Sans ce matériel », « Autre »), avec leur raison courte et
//   leur cible de départ ; « Pourquoi ? » facultatif (pas de matériel →
//   « Il me manque : », douleur, trop dur, autre) recalcule les
//   propositions. Remplaçant de la base suivi par Koach : demandé à
//   `plan(seance)` avec `remplace` (cibles de Koach à l'emplacement) ; la
//   séance commencée sans série validée repart de son début pour cela ;
//   sinon la ligne prend la cible de départ (jamais plus de ligne sans
//   cible quand Koach en donne une).
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

/// KB6 : réponses de « Pourquoi ? » (codes de raison de Koach 1.0.9), dans
/// l'ordre de la feuille.
const kDayReplaceReasons = <String, String>{
  'pas_de_materiel': 'Pas de matériel',
  'douleur': 'Douleur',
  'trop_dur': 'Trop dur',
  'autre': 'Autre',
};

/// KB6 : étiquettes des propositions de Koach 1.0.9, libellés affichés.
const kDayReplaceLabels = <String, String>{
  'equivalent': 'Équivalent',
  'plus_facile': 'Plus facile',
  'sans_materiel': 'Sans ce matériel',
  'autre': 'Autre',
};

/// KB6 : proposition de remplacement : exercice de la base [id], nom,
/// étiquette (`kDayReplaceLabels`), raison courte, cible de départ
/// ([depart] : `source`, `loadKg`, plages ; vide : à choisir).
typedef DayReplaceProposal = ({
  String id,
  String name,
  String label,
  String text,
  Map<String, Object?> depart,
});

/// KB6 : propositions de remplacement d'une ligne : raison retenue (code),
/// propositions dans l'ordre de Koach.
typedef DayReplaceOptions = ({
  String reason,
  List<DayReplaceProposal> proposals,
});

/// KB6 : cible de départ [d] de Koach (`depart` d'un remplaçant) lisible :
/// « 6-8 reps à 20 kg », « 30-40 s » ; null : rien à dire (à choisir).
/// [kg] : libellé d'une charge. Pur.
String? dayDepartText(Map d, String Function(double kg) kg) {
  String? plage(String lo, String hi, String u) {
    final a = d[lo], z = d[hi];
    if (a is! num && z is! num) return null;
    if (a is num && z is num && a.round() != z.round()) {
      return '${a.round()}-${z.round()} $u';
    }
    return '${((z ?? a) as num).round()} $u';
  }

  final amount =
      plage('repsLow', 'repsHigh', 'reps') ??
      plage('secondsLow', 'secondsHigh', 's');
  final l = d['loadKg'];
  final load = l is num && l > 0 ? kg(l.toDouble()) : null;
  if (amount == null && load == null) return null;
  if (amount == null) return load;
  return load == null ? amount : '$amount à $load';
}

/// KB6 : cible de départ [d] utilisable (charge ou plage). Pur.
bool dayHasDepart(Map? d) =>
    d != null &&
    const [
      'loadKg',
      'repsLow',
      'repsHigh',
      'secondsLow',
      'secondsHigh',
    ].any((k) => d[k] is num);

/// KB6 : séries d'un libellé écrit [label] (« 6×3 · E2MOM ») à la cible de
/// départ [d] : nombre de séries et format gardés, répétitions ou
/// secondes de la plage. Null : libellé non reconnu ou cible sans plage.
/// Pur.
String? daySetsAtDepart(String label, Map d) {
  final m = RegExp(
    r'^(\s*\d+\s*[×x]\s*)(\d+(?:\s*-\s*\d+)?)(\s*s\b)?',
  ).firstMatch(label);
  if (m == null) return null;
  String? plage(String lo, String hi) {
    final a = d[lo], z = d[hi];
    if (a is! num && z is! num) return null;
    if (a is num && z is num && a.round() != z.round()) {
      return '${a.round()}-${z.round()}';
    }
    return '${((z ?? a) as num).round()}';
  }

  final s = plage('secondsLow', 'secondsHigh');
  final r = s == null ? plage('repsLow', 'repsHigh') : null;
  if (s == null && r == null) return null;
  return '${m.group(1)}${s ?? r}${s != null ? ' s' : ''}'
      '${label.substring(m.end)}';
}

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

  /// KB6 : emplacements (programme créé ou importé) des lignes de
  /// S[week]·J[j] remplacées pour aujourd'hui, avec leur changement.
  Map<String, Map<String, dynamic>> dayReplacedSlots(int week, int j) => {
    for (final e in dayChanges(week, j).entries)
      if (e.value['type'] == 'remplace')
        if (SessionAdaptStore(this).adaptSlotOf(week, j, e.key) case final s?)
          s: e.value,
  };

  /// KB6 : identifiant de la base de l'exercice écrit de la ligne affichée
  /// [e] (même remplacée) ; null : inconnu.
  String? dayWrittenId(int week, int j, Exercise e) {
    final key = dayChangeKey(e.id);
    final written = SessionAdaptStore(
      this,
    ).programExerciseOf(week, j, Exercise.adapted(e, id: key));
    final w = written ?? (e.id == key ? e : null);
    return w == null ? null : w.catalogId ?? content.idFor(w.name);
  }

  /// KB6 : fiches de remplacement de Koach 1.0.9 (catalogue, grilles du
  /// profil), construites une fois.
  List<Map<String, Object?>>? _dayReplaceInfos() {
    final cat = content.catalog;
    if (cat == null) return null;
    final profile = adaptProfile;
    return SessionAdaptStore(this)._g9Memo(
      'kb6infos|${identityHashCode(cat)}|${identityHashCode(athlete)}',
      () => ka.koachInfosRemplacement(cat, profile),
    );
  }

  /// KB6 : matériel de l'exercice écrit de [e] proposé sous « Il me
  /// manque : » (sans le sol, le mur, le tapis, la magnésie, toujours
  /// disponibles pour Koach).
  List<String> dayMissingChoices(int week, int j, Exercise e) {
    final from = dayWrittenId(week, j, e);
    final x = from == null ? null : content.catalog?.find(from);
    if (x == null) return const [];
    return [
      for (final m in x.equipment)
        if (!ko.koachMaterielToujours.contains(m)) m,
    ];
  }

  /// KB6 : propositions de Koach 1.0.9 pour remplacer la ligne affichée
  /// [e] de S[week]·J[day.j] (`Koach.remplacants`, lecture seule : rien
  /// n'est versé au journal), selon la raison [reason]
  /// (`kDayReplaceReasons`, sans réponse : `autre`), le matériel qui manque
  /// [missing] et la zone douloureuse [zone] (douleur : celle du bilan du
  /// jour sinon). Un jour de douleur active, aucune proposition ne
  /// sollicite la zone, quelle que soit la raison. Moteur absent (Koach
  /// pas prêt ou arrêté) : mêmes règles, sans cible apprise. Null :
  /// exercice écrit inconnu de la base.
  DayReplaceOptions? dayReplaceOptions(
    int week,
    DayPlan day,
    Exercise e, {
    String? reason,
    List<String> missing = const [],
    String? zone,
  }) {
    final cat = content.catalog;
    final from = dayWrittenId(week, day.j, e);
    final infos = _dayReplaceInfos();
    if (cat == null || from == null || !cat.contains(from) || infos == null) {
      return null;
    }
    final key = dayChangeKey(e.id);
    final (:slot, :item, :role) = _dayReplaceItem(week, day.j, e, from);
    final a = sessionAdapt(week, day.j);
    final pains = <String>{
      for (final p in a?.check?.pains ?? const <kc.PainReport>[]) p.zone.code,
    };
    final code = kDayReplaceReasons.containsKey(reason) ? reason! : 'autre';
    final z = code == 'douleur' ? zone ?? pains.firstOrNull : null;
    final shown = withDayChanges(week, day).exercises;
    final profile = athlete?.profile;
    final demande = <String, Object?>{
      'exerciseId': from,
      'item': item,
      'role': ?role,
      'raison': {
        'code': code,
        if (code == 'pas_de_materiel') 'materiel': [...missing],
        if (z != null) 'zone': z,
      },
      if (a?.place?.code case final l?) 'lieu': l,
      'exclus': <String>{
        ...?profile?.dislikedExerciseIds,
        ...?profile?.cannotDoExerciseIds,
        for (final x in shown)
          if (dayChangeKey(x.id) != key)
            if (x.catalogId ?? content.idFor(x.name) case final id?) id,
      }.toList(),
    };
    Map<String, Object?> r;
    try {
      final k = _koachRt.live;
      r = k != null
          ? k.remplacants(infos, demande)
          : ko.koachRemplacants(infos, demande);
    } catch (_) {
      try {
        r = ko.koachRemplacants(infos, demande);
      } catch (_) {
        return null;
      }
    }
    final byId = {for (final i in infos) '${i['id']}': i};
    bool sollicite(Map? c) {
      if (c == null) return false;
      for (final z in pains) {
        final n = (c['zoneLevels'] as Map?)?[z];
        if ((n is num && n > 0) ||
            ((c['painStopHits'] as List?)?.contains(z) ?? false)) {
          return true;
        }
      }
      return false;
    }

    final out = <DayReplaceProposal>[];
    for (final x in (r['remplacants'] as List? ?? const [])) {
      if (x is! Map) continue;
      final id = '${x['exerciseId']}';
      // Douleur active : la zone n'est filtrée par Koach que pour la
      // raison « douleur » ; l'application l'écarte pour toute raison.
      if (code != 'douleur' && sollicite(byId[id])) continue;
      out.add((
        id: id,
        name: content.byId[id]?.nom ?? '${x['nom'] ?? id}',
        label: kDayReplaceLabels.containsKey(x['etiquette'])
            ? '${x['etiquette']}'
            : 'autre',
        text: '${x['texte'] ?? ''}',
        depart: (x['depart'] as Map?)?.cast<String, Object?>() ?? const {},
      ));
    }
    return (reason: code, proposals: out);
  }

  /// KB6 : ligne de [e] demandée aux remplaçants de Koach : la ligne
  /// servie par Koach si c'est encore l'exercice écrit [from], sinon la
  /// ligne écrite du jour ; emplacement et rôle.
  ({String? slot, Map<String, Object?> item, Object? role}) _dayReplaceItem(
    int week,
    int j,
    Exercise e,
    String from,
  ) {
    final slot = SessionAdaptStore(
      this,
    ).adaptSlotOf(week, j, dayChangeKey(e.id));
    if (slot == null) return (slot: null, item: const {}, role: null);
    final a = sessionAdapt(week, j);
    final info = koachJourInfo(week, j);
    final served = a == null ? null : _koachServed(a, slot);
    return (
      slot: slot,
      item:
          (served != null && served['exerciseId'] == from ? served : null) ??
          info?.items.where((x) => x['slotId'] == slot).firstOrNull ??
          const {},
      role: info?.roles[slot],
    );
  }

  /// KB6 : cible de départ de Koach pour [to] (exercice choisi dans la
  /// recherche) à la place de la ligne affichée [e] : même règle que les
  /// propositions (historique, transfert prudent, a priori). Null : moteur
  /// absent, exercice que Koach ne suit pas, rien à proposer.
  Map<String, Object?>? dayDepartFor(
    int week,
    DayPlan day,
    Exercise e,
    String to,
  ) {
    final k = _koachRt.live;
    final infos = _dayReplaceInfos();
    final from = dayWrittenId(week, day.j, e);
    if (k == null || infos == null || from == null) return null;
    Map<String, Object?>? fo, fc;
    for (final i in infos) {
      if (i['id'] == from) fo = i;
      if (i['id'] == to) fc = i;
    }
    if (fo == null || fc == null) return null;
    final item = _dayReplaceItem(week, day.j, e, from).item;
    final step = fc['gridStep'];
    final etat = k.modele.instantane();
    try {
      final d = ko.koachDepart(
        k,
        from,
        ko.koachUniteRemplacant(fo),
        to,
        ko.koachUniteRemplacant(fc),
        item,
        step is num
            ? ko.Grille(
                step.toDouble(),
                (fc['gridMinimum'] as num?)?.toDouble() ?? 0,
                fc['gridDumbbell'] == true,
              )
            : null,
      );
      return dayHasDepart(d) ? d : null;
    } catch (_) {
      return null;
    } finally {
      k.modele.restaurer(etat);
    }
  }

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
    // KB6 : cible de départ de Koach (remplaçant pas servi par Koach à
    // l'emplacement : séance commencée avec des séries validées, Koach
    // arrêté, moteur d'avant) : plage et charge de départ.
    final depart = c['cible'] is Map ? c['cible'] as Map : null;
    final atDepart = depart == null ? null : daySetsAtDepart(label, depart);
    final converted =
        atDepart ??
        (seconds == null || seconds == wasSeconds
            ? null
            : daySetsInUnit(
                label,
                seconds: seconds,
                value: (c['valeur'] as num?)?.toInt(),
              ));
    final kg =
        (depart?['loadKg'] as num?)?.toDouble() ??
        (c['kg'] as num?)?.toDouble();
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
      why: switch (depart == null
          ? null
          : dayDepartText(depart, (x) => massLabel(x, engine: true))) {
        final t? =>
          'Remplace « $from » aujourd’hui. Cible de départ de '
              'Koach : $t.',
        _ => 'Remplace « $from » aujourd’hui.',
      },
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
  ///
  /// KB6 : [reason] (`kDayReplaceReasons`) et [missing] (« Il me manque :
  /// ») gardés avec le changement ; [depart] : cible de départ de Koach
  /// (servie quand Koach ne sert pas le remplaçant à l'emplacement) ;
  /// [label] : étiquette de la proposition choisie.
  void dayReplace(
    int week,
    DayPlan day,
    Exercise e, {
    String? to,
    required String name,
    String? reason,
    List<String> missing = const [],
    Map<String, Object?>? depart,
    String? label,
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
      if (kDayReplaceReasons.containsKey(reason)) 'raison': reason,
      if (reason == 'pas_de_materiel' && missing.isNotEmpty)
        'manque': [...missing],
      if (dayHasDepart(depart)) 'cible': {...depart!},
      if (kDayReplaceLabels.containsKey(label)) 'etiquette': label,
    };
    // Colonne de charge ouverte d'emblée pour un exercice chargé sans
    // historique (la charge se saisit).
    final departKg = depart?['loadKg'];
    if (entry != null &&
        loaded.contains(entry.ex.loadType) &&
        (kg == null || kg <= 0) &&
        !(departKg is num && departKg > 0)) {
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

  /// KB6 : la séance S[week]·J[base.j] commencée par Koach sans série
  /// validée repart de son début pour servir ses changements du jour
  /// (remplacement servi avec les cibles de Koach, ou ligne revenue) ;
  /// [base] : journée du programme (pas la journée affichée). Vrai : la
  /// séance a été recommencée.
  Future<bool> dayServeChanges(int week, DayPlan base) async {
    if (!koachRecommencable(week, base.j)) return false;
    return koachRecommencerPourChangement(week, base);
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

  /// KB6 : le remplacement du jour de la ligne écrite [key] peut être
  /// annulé : Koach ne sert pas le remplaçant à l'emplacement, ou la séance
  /// peut repartir de son début (aucune série validée). Sinon la ligne
  /// servie par Koach reste celle du remplaçant jusqu'à la fin.
  bool dayCanUndo(int week, int j, String key) {
    final c = dayChanges(week, j)[key];
    if (c == null) return false;
    if (c['type'] != 'remplace') return true;
    final slot = SessionAdaptStore(this).adaptSlotOf(week, j, key);
    final a = sessionAdapt(week, j);
    final served = slot == null || a == null ? null : _koachServed(a, slot);
    if (served == null || served['remplace'] == null) return true;
    // Ligne au départ chronométré servie telle qu'écrite (PR8) : la ligne
    // affichée est celle du programme, le retour est sûr.
    if (SessionAdaptStore(this).adaptAsWritten(week, slot)) return true;
    return koachRecommencable(week, j);
  }

  /// Annule le changement du jour de la ligne écrite [key] (séance pas
  /// finie) : la ligne revient telle que la séance la sert.
  void dayUndo(int week, DayPlan day, String key) {
    final log = logs[sessionKey(week, day.j)];
    if (log == null || log.done) return;
    final c = log.changes[key];
    if (c == null || !dayCanUndo(week, day.j, key)) return;
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
