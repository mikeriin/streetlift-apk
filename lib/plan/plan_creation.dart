// G7 (D4.3 à D4.7) : déroulé de la création du programme avec `kalis_plan`.
//
// État de l'écran, sans règle d'entraînement : propositions successives
// (graines 0, 1, 2… : « Autre proposition »), actions de revue transmises
// au moteur avec tous les verrous, profil mis à jour par ce que la revue
// apprend (`applyProfileDelta`), annulation d'un changement, passe 2 et
// ajustements de l'utilisateur. Le moteur est appelé de façon synchrone
// (quelques dizaines de millisecondes, kalis_plan docs/MESURES.md) ; chaque
// appel est mesuré et, en session de test, noté dans le journal du moteur.
import 'package:flutter/foundation.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_plan/kalis_plan.dart' show KalisPlan, applyProfileDelta;

import 'plan_program.dart';

/// Un changement de la revue (annulable).
class PlanStep {
  final String label;
  final kc.Pass1Plan before, after;
  final kc.AthleteProfile profileBefore;
  final List<kc.PlanLock> locksBefore;
  final List<kc.PlanChange> changes;

  /// Emplacement visé par l'utilisateur (null : ajout).
  final String? slotId;
  const PlanStep({
    required this.label,
    required this.before,
    required this.after,
    required this.profileBefore,
    required this.locksBefore,
    required this.changes,
    this.slotId,
  });

  /// Changements autres que celui demandé (ce que Koach doit expliquer).
  List<kc.PlanChange> get sideEffects => [
    for (final c in changes)
      if (!c.reasons.any((r) => r.code.startsWith('plan.user_'))) c,
  ];
}

class PlanCreation extends ChangeNotifier {
  PlanCreation({
    required this.catalog,
    required kc.AthleteProfile profile,
    required this.startDate,
    this.journalOn = false,
    KalisPlan? engine,
  }) : _profile = profile,
       engine = engine ?? KalisPlan();

  final kc.Catalog catalog;
  final KalisPlan engine;
  final kc.CivilDate startDate;

  /// Journal du moteur (session de test).
  final bool journalOn;
  final List<Map<String, Object?>> journal = [];

  kc.AthleteProfile _profile;
  kc.AthleteProfile get profile => _profile;

  /// Propositions montrées (graine = rang).
  final List<kc.Pass1Plan> proposals = [];
  int index = 0;

  kc.Pass1Plan? _reviewed;
  List<kc.PlanLock> locks = const [];
  final List<PlanStep> steps = [];

  /// Emplacements déjà passés en revue (une décision prise).
  final Set<String> decided = {};

  kc.Pass2Plan? pass2;
  final Map<String, PlanAdjust> adjust = {};

  /// Temps du dernier appel au moteur (ms).
  int lastMs = 0;

  int get seed => index;
  bool get started => proposals.isNotEmpty;
  kc.Pass1Plan get plan => _reviewed ?? proposals[index];
  bool get reviewed => steps.isNotEmpty || decided.isNotEmpty;

  kc.PlanRequest request() => kc.PlanRequest(
    profile: _profile,
    seed: seed,
    startDate: startDate,
    locks: locks,
  );

  T _timed<T>(
    String op,
    Map<String, Object?> Function() request,
    T Function() run,
    Object? Function(T) out,
  ) {
    final sw = Stopwatch()..start();
    final r = run();
    sw.stop();
    lastMs = sw.elapsedMilliseconds;
    if (journalOn) {
      journal.add({
        'op': op,
        'ms': lastMs,
        'request': request(),
        'response': out(r),
      });
    }
    return r;
  }

  /// Première proposition (graine 0).
  void start() {
    if (started) return;
    final req = request();
    proposals.add(
      _timed('createPass1', req.toJson, () => engine.createPass1(catalog, req), (p) => p.toJson()),
    );
    index = 0;
    notifyListeners();
  }

  /// « Autre proposition » (D4.3) : graine suivante ; les propositions déjà
  /// vues restent accessibles. Seulement avant tout changement de revue.
  void otherProposal() {
    if (reviewed) return;
    if (index + 1 < proposals.length) {
      index++;
    } else {
      final req = kc.PlanRequest(
        profile: _profile,
        seed: proposals.length,
        startDate: startDate,
        locks: locks,
      );
      proposals.add(
        _timed('createPass1', req.toJson, () => engine.createPass1(catalog, req), (p) => p.toJson()),
      );
      index = proposals.length - 1;
    }
    notifyListeners();
  }

  void previousProposal() {
    if (reviewed || index == 0) return;
    index--;
    notifyListeners();
  }

  /// Variantes d'un emplacement (3 ciblées + toutes).
  kc.VariantSet variants(String slotId) {
    final req = kc.VariantsRequest(request: request(), current: plan, slotId: slotId);
    return _timed('variants', req.toJson, () => engine.variants(catalog, req), (v) => v.toJson());
  }

  kc.ReviewResult _review(kc.ReviewAction action) {
    final req = kc.ReviewRequest(request: request(), current: plan, action: action);
    final res = _timed('review', req.toJson, () => engine.review(catalog, req), (r) => r.toJson());
    _profile = applyProfileDelta(_profile, res.profileDelta);
    locks = res.locks;
    _reviewed = res.plan;
    return res;
  }

  /// Applique une action (puis [then], même changement pour l'utilisateur :
  /// « je ne sais pas faire » puis la variante choisie). Renvoie le
  /// changement, annulable.
  PlanStep act(
    kc.ReviewAction action, {
    kc.ReviewAction? then,
    required String label,
  }) {
    final before = plan;
    final p0 = _profile;
    final l0 = locks;
    final first = _review(action);
    var changes = first.diff.changes;
    if (then != null) {
      final second = _review(then);
      changes = combineChanges(before, plan, [changes, second.diff.changes]);
    }
    final target = action.slotId;
    if (target != null) decided.add(target);
    if (then?.slotId != null) decided.add(then!.slotId!);
    final step = PlanStep(
      label: label,
      before: before,
      after: plan,
      profileBefore: p0,
      locksBefore: l0,
      changes: changes,
      slotId: target,
    );
    steps.add(step);
    pass2 = null;
    adjust.clear();
    notifyListeners();
    return step;
  }

  /// « Je sais faire » : verrouille l'emplacement, rien ne bouge.
  void canDo(String slotId) {
    act(
      kc.ReviewAction(kind: kc.ReviewKind.canDo, slotId: slotId),
      label: 'Je sais faire',
    );
  }

  /// Marque un emplacement comme vu, sans changement.
  void keep(String slotId) {
    decided.add(slotId);
    notifyListeners();
  }

  /// Annule le dernier changement (D4.6).
  PlanStep? undo() {
    if (steps.isEmpty) return null;
    final s = steps.removeLast();
    _reviewed = steps.isEmpty && identical(s.before, proposals[index])
        ? null
        : s.before;
    _profile = s.profileBefore;
    locks = s.locksBefore;
    if (s.slotId != null &&
        !steps.any((x) => x.slotId == s.slotId)) {
      decided.remove(s.slotId);
    }
    pass2 = null;
    adjust.clear();
    notifyListeners();
    return s;
  }

  /// Passe 2 (D4.7) sur la passe 1 validée.
  kc.Pass2Plan createPass2() {
    final req = kc.Pass2Request(request: request(), pass1: plan);
    pass2 = _timed('createPass2', req.toJson, () => engine.createPass2(catalog, req), (p) => p.toJson());
    adjust.clear();
    notifyListeners();
    return pass2!;
  }

  /// Bloc validé, prêt à stocker.
  PlanBlockEntry entry(String at) => PlanBlockEntry(
    block: kc.ProgramBlock(pass1: plan, pass2: pass2!),
    seed: seed,
    locks: locks,
    adjust: Map.of(adjust),
    validatedAt: at,
  );

  /// Ajustement d'un emplacement ; null s'il est accepté, sinon la raison.
  String? setAdjust(String slotId, PlanAdjust next, {required bool cautious}) {
    final p = pass2;
    if (p == null) return 'La passe 2 n’est pas encore prête.';
    final check = checkAdjust(
      PlanBlockEntry(
        block: kc.ProgramBlock(pass1: plan, pass2: p),
        seed: seed,
        locks: locks,
        validatedAt: '',
      ),
      slotId,
      next,
      cautious: cautious,
    );
    if (!check.ok) return check.message;
    if (next.isEmpty) {
      adjust.remove(slotId);
    } else {
      adjust[slotId] = next;
    }
    notifyListeners();
    return null;
  }

  /// Journal exportable (session de test).
  Map<String, Object?> journalJson({required String engineVersion}) => {
    'kind': 'kalis_plan_journal',
    'v': 1,
    'engineVersion': engineVersion,
    'catalogVersion': catalog.sourceVersion,
    'entries': journal,
  };
}

/// Changements de plusieurs actions successives, réduits à ce qui diffère
/// entre [before] et [after] : le dernier changement d'un emplacement
/// l'emporte, avec l'exercice d'origine de [before].
List<kc.PlanChange> combineChanges(
  kc.Pass1Plan before,
  kc.Pass1Plan after,
  List<List<kc.PlanChange>> diffs,
) {
  Map<String, String> index(kc.Pass1Plan p) => {
    for (final d in p.days)
      for (final s in d.slots) s.slotId: s.exerciseId,
  };
  final a = index(before), b = index(after);
  final last = <String, kc.PlanChange>{};
  final other = <kc.PlanChange>[];
  for (final diff in diffs) {
    for (final c in diff) {
      final id = c.slotId;
      if (id == null) {
        other.add(c);
      } else {
        last[id] = c;
      }
    }
  }
  final out = <kc.PlanChange>[];
  for (final e in last.entries) {
    final from = a[e.key], to = b[e.key];
    if (from == to) continue;
    final c = e.value;
    switch (c.kind) {
      case kc.ChangeKind.exerciseReplaced:
        if (from == null || to == null) continue;
        out.add(c.copyWith(fromExerciseId: from, toExerciseId: to));
      case kc.ChangeKind.exerciseAdded || kc.ChangeKind.exerciseMoved:
        if (to == null || from != null) continue;
        out.add(c.copyWith(toExerciseId: to));
      case kc.ChangeKind.exerciseRemoved:
        if (to != null) continue;
        out.add(c);
      default:
        out.add(c);
    }
  }
  return [...out, ...other];
}
