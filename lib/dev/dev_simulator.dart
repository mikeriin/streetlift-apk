// G10 (D2.5) : simulateur de séances de la session de test (mode dev).
//
// Un athlète simulé de `kalis_adapt` (physiologie et comportement à vérité
// connue : capacités, forme du jour, notes plus ou moins justes, séances
// manquées, douleur, autre lieu) suit le programme de la session de test
// pendant N semaines. L'horloge de la session de test avance séance par
// séance ; chaque séance passe par le même chemin qu'une vraie : bilan du
// jour, prescription du moteur, séries notées en flammes, fin de séance,
// revue du moteur et propositions de Koach (appliquées en mode assisté ;
// en mode libre, laissées en attente ou toutes acceptées). Fin de bloc :
// le bloc suivant est validé tel que le moteur le propose.
//
// Déterministe : même session de départ, même athlète, même graine, même
// nombre de semaines → même session de test, octet pour octet. Une séance
// suit la prescription du jour, sans conseil série par série (choix du
// lot, pour tenir le temps de calcul sur téléphone).
//
// Code du mode dev seulement (build de développement, session de test).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kalis_adapt/kalis_adapt.dart' as ka;
import 'package:kalis_adapt/simulation.dart' as sim;
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_koach/kalis_koach.dart' show KoachPose;

import '../adapt/adapt_texts.dart' show adaptKgField;
import '../app_theme.dart';
import '../kalis_clock.dart';
import '../koach/koach_bubble.dart';
import '../models.dart';
import '../program_start.dart' show longCivilDate;
import '../session_host.dart';
import '../session_prefs.dart' show SessionSpace;
import '../store.dart';
import '../ui.dart';
import 'dev_flags.dart';
import 'dev_session.dart';

/// Athlètes simulés de `kalis_adapt`, avec leur description.
const kSimAthleteLabels = <String, String>{
  'debutant_salle': 'Débutant en salle (progresse vite, notes approximatives)',
  'intermediaire_salle': 'Intermédiaire en salle',
  'avance_street': 'Avancé street (progresse lentement, notes précises)',
  'notes_paresseuses': 'Notes paresseuses (confirme presque toujours)',
  'irregulier': 'Irrégulier (séances manquées, coupure, maladie)',
  'maison_halteres': 'Débutant à la maison, haltères',
  'calisthenie_parc': 'Calisthénie au parc (oublie parfois de noter)',
  'douleur_et_lieu': 'Douleur à l’épaule puis entraînement ailleurs',
};

/// Bilan d'une simulation.
class DevSimResult {
  final int days, sessionsDone, sessionsMissed, sets;
  final int proposals, accepted, blocksAdded;
  final DateTime end;
  final String? error;
  const DevSimResult({
    this.days = 0,
    this.sessionsDone = 0,
    this.sessionsMissed = 0,
    this.sets = 0,
    this.proposals = 0,
    this.accepted = 0,
    this.blocksAdded = 0,
    required this.end,
    this.error,
  });
}

/// Simule [weeks] semaines de l'athlète [athleteKey] (graine [seed]) dans
/// le magasin [app], à partir d'aujourd'hui (horloge du magasin) ;
/// [acceptAll] : en mode libre, accepter toutes les propositions.
/// [onProgress] : jours simulés / jours prévus.
Future<DevSimResult> runDevSimulation(
  AppStore app, {
  required String athleteKey,
  required int weeks,
  required int seed,
  bool acceptAll = false,
  void Function(int done, int total)? onProgress,
}) async {
  final clock = app.storeClock;
  final now0 = clock();
  final start = DateTime(now0.year, now0.month, now0.day);
  final catalog = app.content.catalog;
  final profile = app.adaptProfile;
  if (catalog == null || profile == null) {
    return DevSimResult(
      end: start,
      error:
          'Il faut un profil (et la base d’exercices) dans la session de '
          'test.',
    );
  }
  if (app.program.start == null || app.program.beforeStart(start)) {
    return DevSimResult(
      end: start,
      error: 'Il faut un programme commencé dans la session de test.',
    );
  }
  final spec = sim.athleteOf(athleteKey);
  final book = ka.ExerciseBook(catalog, profile);
  final athlete = sim.SimAthlete(spec, profile, book, seed);
  final total = weeks * 7;
  var t = start;
  app.storeClock = () => t;
  var done = 0, missed = 0, sets = 0, proposals = 0, accepted = 0;
  var blocks = 0;
  final before = app.planEvolution.entries.length;
  try {
    for (var d = 0; d < total; d++) {
      if (d > 0 && d % 7 == 0) athlete.endWeek();
      final date = DateTime(start.year, start.month, start.day + d);
      t = DateTime(date.year, date.month, date.day, 18);
      // Fin du programme créé : bloc suivant tel que proposé.
      for (var k = 0; k < 2 && !app.program.containsDate(date); k++) {
        if (app.planProgram == null) break;
        final c = PlanStore(app).newNextBlockCreation(journal: false);
        if (c == null) break;
        c.createPass2();
        PlanStore(app).applyNextBlockCreation(c);
        blocks++;
      }
      onProgress?.call(d, total);
      if (!app.program.containsDate(date)) break;
      final week = app.program.weekFor(date);
      final j = app.program.dayFor(date);
      final base = app.program.week(week).day(j);
      if (base == null || base.exercises.isEmpty) continue;
      final key = app.sessionKey(week, j);
      final log = app.logs[key];
      if (log != null &&
          (log.done || log.ex.values.any((x) => x.sets.any((s) => s.done)))) {
        continue;
      }
      // Séance manquée : coupure, puis au hasard (taux de l'athlète).
      final breakFrom = spec.breakFromDay;
      if (breakFrom != null &&
          d >= breakFrom &&
          d < breakFrom + spec.breakDays) {
        missed++;
        continue;
      }
      if (sim.SimRandom.of(seed, 'calendar|$d').next() < spec.missRate) {
        missed++;
        continue;
      }
      athlete.advance(d);
      if (!_session(app, athlete, spec, week, j, base, d, () {
        t = t.add(const Duration(seconds: 45));
      }, (n) => sets += n)) {
        missed++;
        continue;
      }
      done++;
      app.consumeReward();
      // Revue du moteur et propositions, comme à l'ouverture de l'accueil.
      app.evolutionRefresh();
      if (acceptAll) {
        for (final e in app.evolutionPending) {
          app.evolutionAccept(e);
          accepted++;
        }
      }
      // Laisse respirer l'interface (barre de progression).
      await Future<void>.delayed(Duration.zero);
    }
  } finally {
    app.storeClock = clock;
  }
  proposals = app.planEvolution.entries.length - before;
  await app.flush();
  onProgress?.call(total, total);
  return DevSimResult(
    days: total,
    sessionsDone: done,
    sessionsMissed: missed,
    sets: sets,
    proposals: proposals < 0 ? 0 : proposals,
    accepted: accepted,
    blocksAdded: blocks,
    end: DateTime(start.year, start.month, start.day + total),
  );
}

/// Une séance : bilan, séries notées en flammes, fin. Faux si le moteur
/// ne sert pas cette séance.
bool _session(
  AppStore app,
  sim.SimAthlete athlete,
  sim.AthleteSpec spec,
  int week,
  int j,
  DayPlan base,
  int day,
  void Function() tick,
  void Function(int) countSets,
) {
  final opened = app.adaptOpen(week, base);
  if (opened == null) return false;
  final place = app.adaptPlaceOf(week, j);
  final budget = place == null
      ? 60
      : place.block.pass1.days
            .firstWhere(
              (x) => x.dayIndex == place.dayIndex,
              orElse: () => place.block.pass1.days.first,
            )
            .minutesBudget;
  final check = athlete.healthCheck(budget);
  if (check == null) {
    app.adaptAnswer(week, base, null, skipped: true);
  } else {
    app.adaptAnswer(week, base, check);
  }
  final otherFrom = spec.otherPlaceFromDay;
  if (otherFrom != null &&
      day >= otherFrom &&
      day < otherFrom + spec.otherPlaceDays &&
      spec.otherPlace != null) {
    app.adaptSetPlace(week, base, spec.otherPlace);
  }
  var a = app.sessionAdapt(week, j);
  if (a == null) return false;
  // Mode libre : l'ajustement du bilan est accepté (comme « tout accepter »
  // pour une séance du jour).
  if (a.choice == 'pending') {
    app.adaptChoose(week, base, 'accepted');
    a = app.sessionAdapt(week, j)!;
  }
  final served = app.adaptDay(week, base, a);
  var n = 0;
  for (final e in served.exercises) {
    final log = app.exLog(week, j, e);
    final spec2 = app.logSpec(e);
    final it = app.adaptItemFor(week, j, e);
    final truth = it == null ? null : athlete.truthOf(it.exerciseId);
    final hold = it != null && prescriptionInSeconds(it);
    final modeled =
        truth != null &&
        it != null &&
        (truth.mode == ka.CapacityMode.hold) == hold;
    if (it != null) app.adaptPrefill(week, j, e, log);
    if (modeled) athlete.beginExercise(truth, it.slotId);
    for (var i = 0; i < log.sets.length; i++) {
      final s = log.sets[i];
      if (s.done) continue;
      final g = it == null ? null : app.adaptGoal(week, j, e, i);
      if (modeled && g != null) {
        final flames = g.flames ?? it.targetFlames ?? 6;
        var low = g.low ?? g.high;
        var high = g.high ?? g.low;
        if (low == null || high == null) break;
        final loaded =
            truth.mode == ka.CapacityMode.loaded &&
            it.loadBasis != kc.LoadBasis.bodyweight &&
            it.loadBasis != kc.LoadBasis.unloaded;
        double? load;
        if (loaded) {
          load =
              g.kg ?? athlete.selfSelect(truth, high, kc.Flames.toRir(flames));
        }
        // Test « au maximum » : plage ouverte, l'athlète va au bout.
        if (high > 300 && !hold) high = 300;
        final out = athlete.perform(
          truth,
          loadKg: loaded ? load : null,
          low: low,
          high: high,
          flamesTarget: flames,
          restSeconds: it.restSeconds ?? 90,
          noiseKey: '$day|${it.slotId}|$i',
        );
        if (loaded && load != null) s.kg = adaptKgField(load);
        s.reps = '${out.amount}';
        s.flames = out.flames;
        s.flamesUnknown = out.flames == null;
        s.effort = out.flames == null ? null : kc.Flames.toRir(out.flames!);
      } else {
        // Exercice que le moteur ne modélise pas (mobilité, cardio…) :
        // fait comme prescrit.
        if (s.reps.isEmpty) {
          final planned =
              g?.prefill ??
              app.plannedReps(e, spec2, log.sets.length)[i] ??
              spec2.seconds ??
              1;
          s.reps = '$planned';
        }
        if (g?.flames != null) {
          s.flames = g!.flames;
          s.effort = kc.Flames.toRir(g.flames!);
        }
      }
      tick();
      s.done = true;
      s.completedAt = app.storeClock().toIso8601String();
      n++;
    }
    if (modeled) athlete.endExercise(truth);
  }
  countSets(n);
  app.saveLogs(affectsProgression: false);
  app.markSessionDone(week, j, true);
  return true;
}

// ------------------------------------------------------------------ écran

Future<void> openDevSimulator(BuildContext context) {
  if (!kDevBuild || !SessionSpace.isDev) return Future.value();
  return Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const DevSimulatorScreen()));
}

/// Outils de test › Simulateur de séances.
class DevSimulatorScreen extends StatefulWidget {
  const DevSimulatorScreen({super.key});

  @override
  State<DevSimulatorScreen> createState() => _DevSimulatorScreenState();
}

class _DevSimulatorScreenState extends State<DevSimulatorScreen> {
  String _athlete = 'intermediaire_salle';
  int _weeks = 8;
  int _seed = 1;
  bool _acceptAll = false;
  bool _running = false;
  double _progress = 0;
  DevSimResult? _result;

  Future<void> _run() async {
    setState(() {
      _running = true;
      _progress = 0;
      _result = null;
    });
    final r = await runDevSimulation(
      store,
      athleteKey: _athlete,
      weeks: _weeks,
      seed: _seed,
      acceptAll: _acceptAll,
      onProgress: (d, total) {
        if (mounted) setState(() => _progress = total == 0 ? 1 : d / total);
      },
    );
    if (!mounted) return;
    setState(() {
      _running = false;
      _result = r;
    });
    if (r.error != null) return;
    // L'horloge de la session de test va au dernier jour simulé : l'accueil
    // montre la semaine en cours et les propositions de Koach.
    final real = KalisClock.realNow();
    final days = DateTime.utc(
      r.end.year,
      r.end.month,
      r.end.day,
    ).difference(DateTime.utc(real.year, real.month, real.day)).inDays;
    await SessionHost.restart(
      () => DevSession.setOffsetDays(days < 0 ? 0 : days),
      message:
          'Simulation terminée : ${r.sessionsDone} séances, '
          '${r.proposals} proposition${r.proposals > 1 ? 's' : ''} de Koach',
      detail: 'Date simulée : ${longCivilDate(r.end)}.',
      koach: KoachPose.progressChart,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mode = store.adaptMode;
    final r = _result;
    return KScreen(
      appBar: AppBar(title: const Text('SIMULATEUR DE SÉANCES')),
      body: KList(
        key: const ValueKey('sim-list'),
        children: [
          KCard(
            child: KoachSays(
              pose: KoachPose.analyze,
              child: Text(
                'Je remplis ta session de test séance par séance, en avançant '
                'son horloge : un athlète simulé fait ses séries et les note '
                'en flammes. Mes propositions arrivent comme pour un vrai '
                'utilisateur (mode ${mode == 'free' ? 'libre' : 'assisté'}). '
                'Ta session personnelle n’est pas touchée.',
              ),
            ),
          ),
          const KSection('Athlète simulé'),
          RadioGroup<String>(
            groupValue: _athlete,
            onChanged: (v) {
              if (_running || v == null) return;
              setState(() => _athlete = v);
            },
            child: Column(
              children: [
                for (final e in kSimAthleteLabels.entries)
                  RadioListTile<String>(
                    key: ValueKey('sim-athlete-${e.key}'),
                    value: e.key,
                    enabled: !_running,
                    contentPadding: EdgeInsets.zero,
                    title: Text(e.value),
                  ),
              ],
            ),
          ),
          const KSection('Durée'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final w in const [1, 2, 4, 8, 12])
                ChoiceChip(
                  key: ValueKey('sim-weeks-$w'),
                  label: Text('$w semaine${w > 1 ? 's' : ''}'),
                  selected: _weeks == w,
                  onSelected: _running
                      ? null
                      : (_) => setState(() => _weeks = w),
                ),
            ],
          ),
          Row(
            children: [
              const Expanded(
                child: Text('Graine (même graine = même session)'),
              ),
              IconButton(
                tooltip: 'Graine précédente',
                onPressed: _running || _seed <= 1
                    ? null
                    : () => setState(() => _seed--),
                icon: const Icon(Icons.remove),
              ),
              Text('$_seed', key: const ValueKey('sim-seed')),
              IconButton(
                tooltip: 'Graine suivante',
                onPressed: _running ? null : () => setState(() => _seed++),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          if (mode == 'free')
            SwitchListTile(
              key: const ValueKey('sim-accept-all'),
              title: const Text('Accepter toutes les propositions'),
              subtitle: const Text(
                'Mode libre : sinon elles restent en attente sur l’accueil.',
              ),
              value: _acceptAll,
              onChanged: _running
                  ? null
                  : (v) => setState(() => _acceptAll = v),
            ),
          if (_running) ...[
            LinearProgressIndicator(
              key: const ValueKey('sim-progress'),
              value: _progress,
              color: SL.accent,
            ),
            Text('Simulation : ${(_progress * 100).round()} %'),
          ],
          if (r?.error != null)
            KCard(
              key: const ValueKey('sim-error'),
              child: KoachSays(pose: KoachPose.oops, child: Text(r!.error!)),
            ),
          FilledButton.icon(
            key: const ValueKey('sim-run'),
            onPressed: _running ? null : _run,
            icon: const Icon(Icons.fast_forward),
            label: Text('Simuler $_weeks semaine${_weeks > 1 ? 's' : ''}'),
          ),
        ],
      ),
    );
  }
}
