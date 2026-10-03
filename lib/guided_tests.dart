// CU (dev6.8.0, PIPELINE_CP) : tests guidés du profil v3 (`kalis_core`
// 0.4.0, PARCOURS_V3.md § 5).
//
// À la création du profil : uniquement des déclarations, aucun test
// physique. Un test n'est proposé que pour un mouvement du programme dont la
// capacité est inconnue (ni record, ni fourchette connue), quand le
// questionnaire le permet (`eligibleTests`) et que son prérequis par
// mouvement est tenu d'après les niveaux et les records déclarés (tri fait
// ici, comme le demande CQ) : tests sous-maximaux à la première séance,
// tests maximaux et de course après 3 séances. Le résultat devient un
// `Benchmark` (`source: guided_test`, `protocolId`) du profil ; la valeur
// estimée s'affiche toujours en fourchette.
import 'package:flutter/material.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_koach/kalis_koach.dart' show KoachPose;

import 'app_theme.dart';
import 'athlete_profile.dart';
import 'koach/koach_bubble.dart';
import 'koach/koach_view.dart';
import 'profile_v3.dart';
import 'store.dart';
import 'ui.dart';

/// Test proposé pour un mouvement.
class TestProposal {
  final GuidedTest test;
  final String exerciseId;
  const TestProposal(this.test, this.exerciseId);

  /// Clé stable (mouvement et protocole).
  String get key => '${test.id}|$exerciseId';
}

/// Séances faites à partir desquelles les tests maximaux et de course
/// (`later`) sont proposés (« après 3 à 4 séances de familiarisation »,
/// borne basse : choix du lot).
const kLaterTestsAfterSessions = 3;

/// Au plus autant de propositions à la fois (écran lisible).
const kMaxTestProposals = 4;

/// Gêne à partir de laquelle aucun test n'est proposé sur un mouvement qui
/// charge la zone (PARCOURS_V3.md : « pas de test maximal si gêne ≥ 4/10 » ;
/// appliqué ici à tous les tests, par prudence).
const kTestDiscomfortLimit = 4;

/// Mouvements dont la capacité compte (ceux qu'un test peut caler) :
/// mouvements de référence, mouvements de compétition, objectifs,
/// épreuves, figures.
List<String> _interesting(AthleteProfile p) {
  final out = <String>[];
  void add(String id) {
    if (!out.contains(id)) out.add(id);
  }

  for (final l in p.movementLevels) {
    add(l.exerciseId);
  }
  for (final d in [
    p.disciplines.primary,
    ...p.disciplines.secondaries.map((s) => s.discipline),
  ]) {
    for (final id in kDisciplineMainExercises[d] ?? const <String>[]) {
      add(id);
    }
  }
  for (final g in p.goals) {
    if (g.exerciseId != null) add(g.exerciseId!);
  }
  for (final e in p.events ?? const <SeasonEvent>[]) {
    for (final l in e.lifts ?? const <CompetitionLift>[]) {
      add(l.exerciseId);
    }
  }
  for (final s in p.skills ?? const <SkillState>[]) {
    add(s.currentExerciseId);
  }
  for (final m in kLevelMovements) {
    if (movementsFor([p.disciplines.primary]).contains(m)) add(m.exerciseId);
  }
  return out;
}

/// Plus grand nombre de répétitions strictes connu sur un schéma de
/// mouvement (fourchette basse ou record), pour les prérequis des tests.
double _bestRepsOnPattern(AthleteProfile p, Catalog c, MovementPattern pat) {
  var best = 0.0;
  for (final l in p.movementLevels) {
    final e = c.find(l.exerciseId);
    if (e == null || e.pattern != pat || !l.known) continue;
    if (l.measure == LevelMeasure.maxReps && (l.low ?? 0) > best) {
      best = l.low!;
    }
  }
  for (final b in p.benchmarks ?? const <Benchmark>[]) {
    final e = c.find(b.exerciseId);
    if (e == null || e.pattern != pat) continue;
    if (b.kind == BenchmarkKind.maxReps &&
        (b.externalLoadKg ?? 0) == 0 &&
        (b.reps ?? 0) > best) {
      best = b.reps!.toDouble();
    }
  }
  return best;
}

/// Une gêne d'au moins [kTestDiscomfortLimit] sur une articulation que le
/// mouvement charge (contrainte moyenne ou forte du catalogue).
bool _painBlocks(AthleteProfile p, CatalogExercise e) {
  for (final l in p.limitations) {
    final level =
        l.effortDiscomfort != null && l.effortDiscomfort! > l.discomfort
        ? l.effortDiscomfort!
        : l.discomfort;
    if (level < kTestDiscomfortLimit) continue;
    final joint = l.zone.joint;
    if (joint == null) continue;
    final stress = e.jointStress[joint];
    if (stress == JointStress.moderate || stress == JointStress.high) {
      return true;
    }
  }
  return false;
}

/// Protocole adapté à un mouvement (null : aucun).
String? _protocolFor(AthleteProfile p, Catalog c, CatalogExercise e) {
  if (e.unit == MeasureUnit.distance) {
    final longRun = p.enduranceBase?.longRun;
    final regular =
        longRun == LongRunBand.min30To60 ||
        longRun == LongRunBand.min60To90 ||
        longRun == LongRunBand.over90Min;
    return regular ? 't7_course_chrono' : 't6_course_6min';
  }
  if (e.unit == MeasureUnit.seconds) return 't5_maintien_max';
  final name = Catalog.normalizeLabel(e.name);
  if (e.loadType == LoadType.addedWeight) {
    if (name.contains('muscle')) return 't3_max_direct';
    if (e.bodyweightFraction == null) return null;
    if (p.bodyWeightKg == null) return null;
    if (_bestRepsOnPattern(p, c, e.pattern) < 8) return null;
    if (!p.equipment.contains('ceinture de lest')) return null;
    return 't2_leste';
  }
  if (e.loadType == LoadType.bodyweight || e.loadType == LoadType.none) {
    return 't4_reps_max';
  }
  return 't1_serie_lourde';
}

/// Tests proposés pour le profil [p] : mouvements du programme
/// ([programIds], vide : ceux du profil) dont la capacité est inconnue.
List<TestProposal> proposeTests({
  required ProfileQuestionnaire parcours,
  required AthleteProfile profile,
  required Catalog catalog,
  required Iterable<String> programIds,
  required int year,
  required int sessionsDone,
}) {
  final eligible = {
    for (final t in parcours.eligibleTests(profile.toJson(), todayYear: year))
      t.id: t,
  };
  eligible.remove('t8_sans_test');
  if (eligible.isEmpty) return const [];
  final known = <String>{
    for (final b in profile.benchmarks ?? const <Benchmark>[]) b.exerciseId,
    for (final l in profile.movementLevels)
      if (l.known) l.exerciseId,
  };
  final program = programIds.toSet();
  final out = <TestProposal>[];
  for (final id in _interesting(profile)) {
    if (out.length >= kMaxTestProposals) break;
    if (known.contains(id)) continue;
    final e = catalog.find(id);
    if (e == null) continue;
    if (program.isNotEmpty &&
        !program.contains(id) &&
        !program.any(
          (x) => catalog.find(x) != null && catalog.rootOf(x).id == e.rootId,
        )) {
      continue;
    }
    if (!e.feasibleWith(profile.equipment.toSet())) continue;
    if (_painBlocks(profile, e)) continue;
    final pid = _protocolFor(profile, catalog, e);
    final t = pid == null ? null : eligible[pid];
    if (t == null) continue;
    if (t.stage == 'later' && sessionsDone < kLaterTestsAfterSessions) {
      continue;
    }
    out.add(TestProposal(t, id));
  }
  return out;
}

/// Saisie du résultat d'un test.
class TestEntry {
  double? loadKg;
  int? reps;
  double? rir;
  int? seconds;
  double? meters;
  double? bodyWeightKg;
}

/// Benchmark du résultat (null : saisie incomplète ou hors limites).
Benchmark? benchmarkOfTest(
  GuidedTest t,
  String exerciseId,
  TestEntry v,
  CivilDate today,
) {
  final kind = t.benchmarkKind == null
      ? null
      : BenchmarkKind.fromCode(t.benchmarkKind!);
  if (kind == null) return null;
  final Benchmark b;
  switch (t.id) {
    case 't1_serie_lourde':
    case 't2_leste':
      if (v.loadKg == null || v.reps == null) return null;
      b = Benchmark(
        exerciseId: exerciseId,
        kind: kind,
        source: BenchmarkSource.guidedTest,
        protocolId: t.id,
        date: today,
        externalLoadKg: v.loadKg,
        reps: v.reps,
        rir: v.rir,
        bodyWeightKg: t.id == 't2_leste' ? v.bodyWeightKg : null,
      );
    case 't3_max_direct':
      if (v.loadKg == null) return null;
      b = Benchmark(
        exerciseId: exerciseId,
        kind: kind,
        source: BenchmarkSource.guidedTest,
        protocolId: t.id,
        date: today,
        externalLoadKg: v.loadKg,
        reps: 1,
        rir: 0,
        bodyWeightKg: v.bodyWeightKg,
      );
    case 't5_maintien_max':
      if (v.seconds == null) return null;
      b = Benchmark(
        exerciseId: exerciseId,
        kind: kind,
        source: BenchmarkSource.guidedTest,
        protocolId: t.id,
        date: today,
        seconds: v.seconds,
      );
    case 't6_course_6min':
      if (v.meters == null) return null;
      b = Benchmark(
        exerciseId: exerciseId,
        kind: kind,
        source: BenchmarkSource.guidedTest,
        protocolId: t.id,
        date: today,
        distanceMeters: v.meters,
        seconds: 360,
      );
    case 't7_course_chrono':
      if (v.meters == null || v.seconds == null) return null;
      b = Benchmark(
        exerciseId: exerciseId,
        kind: kind,
        source: BenchmarkSource.guidedTest,
        protocolId: t.id,
        date: today,
        distanceMeters: v.meters,
        seconds: v.seconds,
      );
    case 't9_reps_temps':
      if (v.reps == null) return null;
      b = Benchmark(
        exerciseId: exerciseId,
        kind: kind,
        source: BenchmarkSource.guidedTest,
        protocolId: t.id,
        date: today,
        reps: v.reps,
        seconds: v.seconds ?? 120,
      );
    default:
      if (v.reps == null) return null;
      b = Benchmark(
        exerciseId: exerciseId,
        kind: kind,
        source: BenchmarkSource.guidedTest,
        protocolId: t.id,
        date: today,
        reps: v.reps,
      );
  }
  return b.validate().isEmpty ? b : null;
}

/// Estimation affichée (toujours une fourchette) ; null si aucune.
String? estimateText(
  GuidedTest t,
  CatalogExercise e,
  TestEntry v, {
  bool novice = false,
}) {
  String kg(double x) => '${numText((x * 2).round() / 2)} kg';
  switch (t.id) {
    case 't1_serie_lourde':
      final est = v.loadKg == null || v.reps == null
          ? null
          : estimateOneRm(
              loadKg: v.loadKg!,
              reps: v.reps!,
              rir: v.rir ?? 0,
              novice: novice,
            );
      if (est == null) return null;
      return 'Maximum estimé sur 1 répétition : ${kg(est.lowKg)} à '
          '${kg(est.highKg)}.';
    case 't2_leste':
      final f = e.bodyweightFraction?.value;
      final bw = v.bodyWeightKg;
      if (f == null || bw == null || v.loadKg == null || v.reps == null) {
        return null;
      }
      final est = estimateOneRm(
        loadKg: v.loadKg! + f * bw,
        reps: v.reps!,
        rir: v.rir ?? 0,
        novice: novice,
      );
      if (est == null) return null;
      double lest(double total) => externalFromTotal(
        totalKg: total,
        bodyWeightKg: bw,
        bodyweightFraction: f,
      );
      return 'Lest maximal estimé : ${kg(lest(est.lowKg))} à '
          '${kg(lest(est.highKg))} (estimation, ne sert pas au choix des '
          'tentatives).';
    case 't6_course_6min':
      final speed = v.meters == null
          ? null
          : trialSpeed(meters: v.meters!, seconds: 360);
      if (speed == null) return null;
      final pace = 1000 / speed;
      return 'Vitesse moyenne : ${numText((speed * 3.6 * 10).round() / 10)} '
          'km/h (${durationText(pace)} au km), à ±5 à 8 % près.';
    case 't7_course_chrono':
      if (v.meters == null || v.seconds == null) return null;
      final tenK = riegelSeconds(
        seconds: v.seconds!.toDouble(),
        meters: v.meters!,
        targetMeters: 10000,
      );
      if (tenK == null || v.meters! >= 10000) return null;
      return 'Temps prédit sur 10 km : environ ${durationText(tenK)} '
          '(provisoire, au moins ±4 %).';
  }
  return null;
}

// ================================================================== écrans

Object? _programKey;
Set<String> _programIds = const {};

/// Programme actuel : identifiants du catalogue de ses exercices (gardés
/// tant que le programme ne change pas).
Set<String> programExerciseIds() {
  final key = (store.program, store.program.weeks.length, store.content);
  if (key == _programKey) return _programIds;
  final out = <String>{};
  for (final w in store.program.weeks) {
    for (final d in w.days) {
      for (final e in d.exercises) {
        final id = e.exId != null && store.content.byId.containsKey(e.exId)
            ? e.exId
            : store.content.idFor(e.name);
        if (id != null) out.add(id);
      }
    }
  }
  _programKey = key;
  return _programIds = out;
}

/// Tests proposés au profil actuel.
List<TestProposal> currentTestProposals() {
  final p = store.athleteProfileForEngines;
  final parcours = store.content.questionnaire;
  final catalog = store.content.catalog;
  if (p == null || parcours == null || catalog == null) return const [];
  return proposeTests(
    parcours: parcours,
    profile: p,
    catalog: catalog,
    programIds: programExerciseIds(),
    year: store.storeClock().year,
    sessionsDone: store.logs.values.where((l) => l.done).length,
  );
}

/// Tests guidés : propositions, ou tous les tests permis.
class GuidedTestsScreen extends StatelessWidget {
  const GuidedTestsScreen({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final proposals = currentTestProposals();
      final p = store.athleteProfileForEngines;
      final parcours = store.content.questionnaire;
      final allowed = p == null || parcours == null
          ? const <GuidedTest>[]
          : parcours.eligibleTests(
              p.toJson(),
              todayYear: store.storeClock().year,
            );
      final onlyNoTest = allowed.every((t) => t.id == 't8_sans_test');
      return KScreen(
        appBar: AppBar(title: const Text('TESTS GUIDÉS')),
        body: KList(
          key: const ValueKey('guided-tests'),
          children: [
            KoachSurface(
              color: SL.bg,
              child: KoachBubble(
                key: const ValueKey('guided-tests-koach'),
                pose: onlyNoTest ? KoachPose.thumbsUp : KoachPose.checklist,
                koachHeight: 90,
                text: onlyNoTest
                    ? 'Pas de test pour toi : je cale tes charges au fil de '
                          'tes 2 ou 3 premières séances, sans effort maximal.'
                    : proposals.isEmpty
                    ? 'Rien à tester pour l’instant : je connais ce qu’il me '
                          'faut, ou ton programme n’a pas encore commencé.'
                    : 'Un test court pour caler tes charges sur ce que tu '
                          'fais vraiment. Échauffe-toi, et arrête-toi dès que '
                          'la technique se dégrade.',
                why:
                    'Les valeurs des 2 ou 3 premières séances restent '
                    'provisoires : le geste s’apprend, et le maximum mesuré '
                    'monte un peu sans que la force change.',
              ),
            ),
            for (final pr in proposals)
              KCard(
                key: ValueKey('guided-test-${pr.key}'),
                onTap: () => openGuidedTest(context, pr),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.content.byId[pr.exerciseId]?.nom ??
                                pr.exerciseId,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pr.test.title,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );
}

Future<void> openGuidedTest(BuildContext context, TestProposal p) =>
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => GuidedTestPage(proposal: p)),
    );

/// Un test : pour qui, sécurité, déroulé, arrêt, saisie du résultat.
class GuidedTestPage extends StatefulWidget {
  final TestProposal proposal;
  const GuidedTestPage({super.key, required this.proposal});

  @override
  State<GuidedTestPage> createState() => _GuidedTestPageState();
}

class _GuidedTestPageState extends State<GuidedTestPage> {
  final _load = TextEditingController();
  final _reps = TextEditingController();
  final _seconds = TextEditingController();
  final _meters = TextEditingController();
  final _bw = TextEditingController();
  double? _rir;
  String? _error;

  GuidedTest get _t => widget.proposal.test;

  @override
  void initState() {
    super.initState();
    final w = store.athleteProfile?.bodyWeightKg ?? store.currentBodyweight;
    if (w != null) _bw.text = numText(w);
  }

  @override
  void dispose() {
    for (final c in [_load, _reps, _seconds, _meters, _bw]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) {
    final s = c.text.trim().replaceAll(',', '.');
    return s.isEmpty ? null : double.tryParse(s);
  }

  int? _duration(TextEditingController c) {
    final s = c.text.trim();
    if (s.isEmpty) return null;
    var total = 0;
    for (final p in s.split(':')) {
      final v = int.tryParse(p.trim());
      if (v == null || v < 0) return null;
      total = total * 60 + v;
    }
    return total;
  }

  TestEntry get _entry => TestEntry()
    ..loadKg = _num(_load)
    ..reps = int.tryParse(_reps.text.trim())
    ..rir = _rir
    ..seconds = _duration(_seconds)
    ..meters = _t.id == 't7_course_chrono' && _num(_meters) != null
        ? _num(_meters)! * 1000
        : _num(_meters)
    ..bodyWeightKg = _num(_bw);

  void _save() {
    final today = civilOf(store.storeClock());
    final b = benchmarkOfTest(_t, widget.proposal.exerciseId, _entry, today);
    if (b == null) {
      setState(() => _error = 'Remplis chaque valeur demandée.');
      return;
    }
    if (!store.addGuidedTestResult(b)) {
      setState(() => _error = 'Résultat hors limites.');
      return;
    }
    Navigator.of(context).pop();
    showKoachToast(
      context,
      'Résultat enregistré dans ton profil.',
      pose: KoachPose.thumbsUp,
    );
  }

  List<String> _lines(String key) => [
    for (final x in (_t.json[key] as List? ?? const [])) '$x',
  ];

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final e = store.content.byId[widget.proposal.exerciseId]?.ex;
    final dim = Theme.of(context).textTheme.bodySmall;
    final title = Theme.of(context).textTheme.titleMedium;
    final loadTest =
        t.id == 't1_serie_lourde' ||
        t.id == 't2_leste' ||
        t.id == 't3_max_direct';
    final repsTest =
        t.id == 't1_serie_lourde' ||
        t.id == 't2_leste' ||
        t.id == 't4_reps_max' ||
        t.id == 't9_reps_temps' ||
        t.id == 't10_series_repetees';
    final estimate = e == null
        ? null
        : estimateText(
            t,
            e,
            _entry,
            novice:
                store.athleteProfile?.trainingAge == TrainingAge.under6Months,
          );
    Widget field(
      String key,
      TextEditingController c,
      String label, {
      String? hint,
    }) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        key: ValueKey(key),
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, helperText: hint),
        onChanged: (_) => setState(() {}),
      ),
    );
    return KScreen(
      appBar: AppBar(title: const Text('TEST GUIDÉ')),
      body: KList(
        key: ValueKey('guided-test-page-${t.id}'),
        children: [
          KCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e?.name ?? widget.proposal.exerciseId, style: title),
                const SizedBox(height: 2),
                Text(t.title, style: dim),
                const SizedBox(height: 8),
                if (t.json['forWhom'] is String)
                  Text(t.json['forWhom']! as String),
              ],
            ),
          ),
          KCard(
            key: const ValueKey('guided-test-safety'),
            accent: SL.action,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.health_and_safety_outlined, color: SL.accent),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Sécurité', style: title)),
                  ],
                ),
                const SizedBox(height: 6),
                for (final l in _lines('safety')) Text('• $l'),
                const SizedBox(height: 6),
                Text(
                  'Une douleur, un vertige ou une gêne inhabituelle : arrête '
                  'le test. Si ça persiste, demande l’avis d’un professionnel '
                  'de santé.',
                  style: dim,
                ),
              ],
            ),
          ),
          KCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Déroulé', style: title),
                const SizedBox(height: 6),
                for (final (i, l) in _lines('steps').indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('${i + 1}. $l'),
                  ),
                const SizedBox(height: 6),
                Text('Quand t’arrêter', style: title),
                const SizedBox(height: 4),
                for (final l in _lines('stop')) Text('• $l'),
              ],
            ),
          ),
          KCard(
            key: const ValueKey('guided-test-result'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Ton résultat', style: title),
                if (loadTest)
                  field(
                    'test-load',
                    _load,
                    t.id == 't2_leste'
                        ? 'Lest (kg)'
                        : t.id == 't3_max_direct'
                        ? 'Meilleure charge réussie (kg)'
                        : 'Charge (kg)',
                  ),
                if (repsTest) field('test-reps', _reps, 'Répétitions'),
                if (t.id == 't1_serie_lourde' || t.id == 't2_leste') ...[
                  const SizedBox(height: 8),
                  Text('Il t’en restait combien sous le pied ?', style: dim),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in const [0.0, 1.0, 2.0, 3.0])
                        ChoiceChip(
                          key: ValueKey('test-rir-${r.round()}'),
                          label: Text(r == 0 ? 'Aucune' : '${r.round()}'),
                          selected: _rir == r,
                          onSelected: (_) =>
                              setState(() => _rir = _rir == r ? null : r),
                        ),
                    ],
                  ),
                ],
                if (t.id == 't2_leste' || t.id == 't3_max_direct')
                  field(
                    'test-bw',
                    _bw,
                    'Ton poids du jour (kg)',
                    hint: 'Pesée du jour',
                  ),
                if (t.id == 't5_maintien_max' || t.id == 't7_course_chrono')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextField(
                      key: const ValueKey('test-seconds'),
                      controller: _seconds,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(
                        labelText: 'Temps',
                        helperText: 'En secondes, ou min:s',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                if (t.id == 't6_course_6min')
                  field('test-meters', _meters, 'Distance parcourue (m)'),
                if (t.id == 't7_course_chrono')
                  field('test-meters', _meters, 'Distance (km)'),
                if (estimate != null) ...[
                  const SizedBox(height: 10),
                  Text(estimate, key: const ValueKey('test-estimate')),
                ],
                if (t.json['uncertainty'] is String) ...[
                  const SizedBox(height: 6),
                  Text('Précision : ${t.json['uncertainty']}', style: dim),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: TextStyle(color: SL.danger)),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  key: const ValueKey('test-save'),
                  onPressed: _save,
                  child: const Text('Enregistrer le résultat'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte de Koach sur l'accueil : un test guidé est proposé (première
/// séance, ou après 3 séances pour les tests maximaux et de course), une
/// seule fois pour chaque ensemble de propositions.
class GuidedTestHomeCard extends StatelessWidget {
  const GuidedTestHomeCard({super.key});

  static bool get visible {
    if (store.athlete == null) return false;
    final start = store.program.start;
    if (start == null || store.storeClock().isBefore(start)) return false;
    final props = currentTestProposals();
    if (props.isEmpty) return false;
    final seen = store.seenTestProposals;
    return props.any((p) => !seen.contains(p.key));
  }

  @override
  Widget build(BuildContext context) {
    final props = currentTestProposals();
    final first = props.isEmpty ? null : props.first;
    return KoachSurface(
      key: const ValueKey('guided-test-card'),
      color: SL.bg,
      child: KoachBubble(
        pose: KoachPose.checklist,
        koachHeight: 76,
        text: first == null
            ? 'Rien à tester pour l’instant.'
            : 'Pour caler tes charges : un test guidé sur '
                  '${store.content.byId[first.exerciseId]?.nom ?? first.exerciseId}'
                  '${props.length > 1 ? ' (et ${props.length - 1} autre${props.length > 2 ? 's' : ''})' : ''}'
                  ' ? Court, avec les consignes de sécurité.',
        actions: [
          KoachBubbleAction(
            'Voir les tests',
            () {
              store.markTestProposalsSeen([for (final p in props) p.key]);
              Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const GuidedTestsScreen()),
              );
            },
            primary: true,
            key: const ValueKey('guided-test-open'),
          ),
          KoachBubbleAction(
            'Plus tard',
            () => store.markTestProposalsSeen([for (final p in props) p.key]),
            key: const ValueKey('guided-test-later'),
          ),
        ],
      ),
    );
  }
}
