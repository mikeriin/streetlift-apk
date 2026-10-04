// Accès aux données de kalis_core depuis les tests (`dart test` s'exécute à
// la racine du paquet ; kalis_core est le dossier voisin) et petits
// constructeurs de journaux.
import 'dart:convert';
import 'dart:io';

import 'package:kalis_adapt/kalis_adapt.dart' show KalisAdapt;
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_core/testing.dart';
import 'package:kalis_quest/kalis_quest.dart';
import 'package:kalis_quest/simulation.dart';

/// Racine du paquet kalis_core.
const String corePath = '../kalis_core';

Catalog? _catalog;

/// Catalogue chargé (une fois par fichier de test).
Catalog loadCatalog() => _catalog ??= Catalog.fromJsonBytes(
  gzip.decode(File('$corePath/data/catalog_v1.json.gz').readAsBytesSync()),
);

/// Objet JSON d'un fichier (décompressé si son nom finit par `.gz`).
Map<String, Object?> readJsonObject(String path) {
  final bytes = File(path).readAsBytesSync();
  final text = utf8.decode(path.endsWith('.gz') ? gzip.decode(bytes) : bytes);
  return jsonDecode(text) as Map<String, Object?>;
}

List<ProfileFixture>? _profiles;

/// Les profils types de kalis_core.
List<ProfileFixture> loadProfiles() => _profiles ??= readProfileFixtures(
  readJsonObject('$corePath/test/fixtures/profiles.json'),
);

/// Profil type de clé [key].
AthleteProfile profileOf(String key) =>
    loadProfiles().firstWhere((p) => p.key == key).profile;

List<JournalFixture>? _journals;

/// Les journaux types de kalis_core.
List<JournalFixture> loadJournals() => _journals ??= readJournalFixtures(
  readJsonObject('$corePath/test/fixtures/journals.json.gz'),
);

final Map<String, SimStage> _stages = <String, SimStage>{};

/// Programme de l'archétype [a] sur [weeks] semaines (créé une fois).
SimStage stageOf(Archetype a, int weeks) => _stages.putIfAbsent(
  '${a.profileKey}|$weeks',
  () => SimStage(
    loadCatalog(),
    KalisAdapt().plan,
    profileOf(a.profileKey),
    weeks,
  ),
);

/// Profil de travail des scénarios : homme de 70 kg, lundi, mercredi et
/// vendredi.
const String scenarioProfile = 'homme_25_musculation_debutant_3x60';

/// Lundi de départ des scénarios.
final CivilDate monday = CivilDate(2026, 10, 5);

/// État vide.
const QuestState emptyState = QuestState(
  xp: <XpEntry>[],
  kredits: <KreditEntry>[],
  quests: <Quest>[],
  data: <String, Object?>{},
);

/// Développé couché à la barre.
const String bench = 'mu-developpe-couche-barre';

/// Back squat barre haute.
const String squat = 'mu-back-squat-barre-haute';

/// Série de travail.
SetRecord setOf(
  String exerciseId,
  int index, {
  int order = 0,
  double? load,
  int? reps,
  int? seconds,
  int? flames,
  int? target,
  bool success = true,
  SetKind kind = SetKind.work,
}) {
  return SetRecord(
    exerciseId: exerciseId,
    exerciseOrder: order,
    setIndex: index,
    kind: kind,
    externalLoadKg: load,
    reps: reps,
    seconds: seconds,
    flames: flames,
    success: success,
    excluded: false,
    target: target == null ? null : SetTarget(flames: target),
  );
}

/// [count] séries identiques de développé couché, notées à la cible.
List<SetRecord> benchSets(
  int count, {
  double load = 60,
  int reps = 8,
  int flames = 7,
  int? target = 7,
}) => <SetRecord>[
  for (var i = 0; i < count; i++)
    setOf(bench, i, load: load, reps: reps, flames: flames, target: target),
];

/// Séance terminée du jour [date].
SessionRecord sessionOf(
  String id,
  CivilDate date,
  List<SetRecord> sets, {
  bool completed = true,
  bool resume = false,
  HealthCheck? health,
  int? planned,
  ProgramRef? ref,
}) {
  return SessionRecord(
    id: id,
    date: date,
    origin: SessionOrigin.program,
    programRef: ref,
    resume: resume,
    completed: completed,
    healthCheck: health,
    sets: sets,
    pains: const <PainReport>[],
    plannedWorkSets: planned,
  );
}

/// Appel du moteur.
QuestOutcome run(
  KalisQuest engine,
  AthleteProfile profile,
  List<SessionRecord> sessions,
  QuestState state,
  CivilDate today, {
  List<TrainingBreak>? breaks,
  List<QuestClaim>? claims,
  ProgramBlock? block,
  AdaptationSummary? adaptation,
  int seed = 7,
}) {
  return engine.evaluate(
    loadCatalog(),
    QuestInput(
      profile: profile,
      log: TrainingLog(sessions: sessions, breaks: breaks),
      block: block,
      adaptation: adaptation,
      state: state,
      today: today,
      seed: seed,
      claims: claims,
    ),
  );
}

/// Texte JSON canonique d'un résultat.
String outcomeText(QuestOutcome o) => jsonEncode(o.toJson());

/// Texte JSON canonique d'un état.
String stateText(QuestState s) => jsonEncode(s.toJson());

/// État relu depuis son JSON (export puis import).
QuestState reimport(QuestState s) =>
    QuestState.fromJson(jsonDecode(stateText(s)) as Map<String, Object?>);

/// Écriture d'effort de la séance [sessionId].
XpEntry effortOf(QuestState state, String sessionId) => state.xp.firstWhere(
  (e) => e.source == XpSource.effort && e.sessionId == sessionId,
);

/// XP d'une origine.
int xpOf(QuestState state, XpSource source) {
  var sum = 0;
  for (final e in state.xp) {
    if (e.source == source) {
      sum += e.amount;
    }
  }
  return sum;
}

/// Codes de raison présents dans un résultat.
Set<String> reasonCodesOf(QuestOutcome o) {
  final codes = <String>{};
  void add(Iterable<Reason> reasons) {
    for (final r in reasons) {
      codes.add(r.code);
    }
  }

  for (final e in o.state.xp) {
    add(e.reasons);
  }
  for (final q in o.state.quests) {
    add(q.reasons);
  }
  for (final e in o.events) {
    add(e.reasons);
  }
  for (final g in o.goals) {
    add(g.reasons ?? const <Reason>[]);
  }
  return codes;
}
