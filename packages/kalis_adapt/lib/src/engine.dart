/// `KalisAdapt` : réalisation de `AdaptEngine` (kalis_core).
library;

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart' show KalisPlan;

import 'advise.dart';
import 'event_day.dart';
import 'model.dart';
import 'params.dart';
import 'replay.dart';
import 'review.dart';
import 'session.dart';
import 'version.dart';

/// Moteur dynamique de Kalis Track : suivi et adaptation (D5).
///
/// Chaque méthode est une fonction pure de ses arguments : le journal est
/// rejoué, aucun état n'est gardé d'un appel à l'autre hors d'un cache qui
/// ne change aucun résultat (le dernier rejeu, repris tant que le
/// catalogue, le profil, le bloc et le début du journal sont les mêmes
/// objets).
final class KalisAdapt implements AdaptEngine, EventDayAdvisor {
  /// Moteur de paramètres [params] ; [plan] est le moteur statique appelé
  /// pour les restructurations (D5.1).
  ///
  /// [legacy] : les blocs qui portent les champs de `kalis_core` 0.4.0 sont
  /// servis comme par `kalis_adapt` 0.1 (comparaison des deux versions) ;
  /// par défaut, ils passent par le mode coach.
  ///
  /// [restructureImported] : un bloc importé (plus de six semaines, le
  /// programme de 40 semaines du propriétaire) reçoit aussi les
  /// propositions de restructuration de `kalis_plan` (DECISIONS_CP.md C11 :
  /// toutes les fonctionnalités s'y appliquent ; l'application l'active pour
  /// ce programme, avec la sauvegarde de l'original). Par défaut, comme
  /// avant : jamais de restructuration d'un bloc importé.
  KalisAdapt({
    this.params = AdaptParams.standard,
    PlanEngine? plan,
    this.legacy = false,
    this.restructureImported = false,
  }) : plan = plan ?? KalisPlan();

  /// Vrai : un bloc importé peut être restructuré (voir le constructeur).
  final bool restructureImported;

  /// Paramètres.
  final AdaptParams params;

  /// Moteur statique.
  final PlanEngine plan;

  /// Vrai : comportement de 0.1 pour tous les blocs.
  final bool legacy;

  Catalog? _catalog;
  AthleteProfile? _profile;
  ProgramBlock? _block;
  EngineContext? _context;
  BlockView? _view;
  List<SessionRecord> _sessions = const <SessionRecord>[];
  Replayed? _replayed;

  @override
  String get engineVersion => kalisAdaptVersion;

  /// Vide le cache du dernier rejeu (les résultats n'en dépendent pas).
  void clearCache() {
    _catalog = null;
    _profile = null;
    _block = null;
    _context = null;
    _view = null;
    _sessions = const <SessionRecord>[];
    _replayed = null;
  }

  /// Contexte, vue du bloc et état rejoué pour [input].
  (EngineContext, BlockView, Replayed) prepare(
    Catalog catalog,
    AdaptInput input,
  ) {
    final sessions = sessionsOf(input.log, input.today.dayNumber);
    final sameWorld =
        identical(catalog, _catalog) &&
        identical(input.profile, _profile) &&
        identical(input.block, _block);
    var context = _context;
    var view = _view;
    final cached = _replayed;
    if (sameWorld && context != null && view != null && cached != null) {
      final old = _sessions;
      var prefix = old.length <= sessions.length;
      for (var i = 0; prefix && i < old.length; i++) {
        if (!identical(old[i], sessions[i])) {
          prefix = false;
        }
      }
      if (prefix) {
        if (old.length == sessions.length) {
          return (context, view, cached);
        }
        _checkOrder(sessions, old.isEmpty ? 1 : old.length);
        final state = cached.state.fork();
        final digests = List<SessionDigest>.of(cached.digests);
        replaySessions(
          context,
          view,
          state,
          digests,
          sessions.skip(old.length),
        );
        final replayed = Replayed(state, digests);
        _sessions = sessions;
        _replayed = replayed;
        return (context, view, replayed);
      }
    }
    final violations = input.profile.validate();
    if (violations.isNotEmpty) {
      final v = violations.first;
      throw ArgumentError('profil invalide : ${v.path} ${v.code}');
    }
    _checkOrder(sessions, 1);
    context = EngineContext(
      catalog: catalog,
      profile: input.profile,
      params: params,
    );
    view = BlockView(
      input.block,
      params,
      profile: input.profile,
      legacy: legacy,
      restructureImported: restructureImported,
    );
    final state = ModelState(params);
    final digests = <SessionDigest>[];
    replaySessions(context, view, state, digests, sessions);
    final replayed = Replayed(state, digests);
    _catalog = catalog;
    _profile = input.profile;
    _block = input.block;
    _context = context;
    _view = view;
    _sessions = sessions;
    _replayed = replayed;
    return (context, view, replayed);
  }

  /// Refuse un journal dont les séances, à partir du rang [from], ne sont
  /// pas par date croissante (au sens large).
  static void _checkOrder(List<SessionRecord> sessions, int from) {
    for (var i = from < 1 ? 1 : from; i < sessions.length; i++) {
      if (sessions[i].date < sessions[i - 1].date) {
        throw ArgumentError('journal non chronologique : ${sessions[i].id}');
      }
    }
  }

  @override
  SessionPlan prescribeSession(Catalog catalog, SessionRequest request) {
    final (context, view, replayed) = prepare(catalog, request.input);
    return buildSessionPlan(context, view, replayed, request);
  }

  @override
  IntraSessionAdvice adviseNextSet(Catalog catalog, AdviceRequest request) {
    final (context, view, replayed) = prepare(catalog, request.input);
    return buildAdvice(context, view, replayed, request);
  }

  @override
  AdaptReview review(Catalog catalog, AdaptInput input) {
    final (context, view, replayed) = prepare(catalog, input);
    return buildReview(context, view, replayed, input, plan);
  }

  @override
  EventDayPlan planEventDay(Catalog catalog, EventDayRequest request) {
    final (context, view, replayed) = prepare(catalog, request.input);
    return buildEventDay(context, view, replayed, request);
  }

  /// Estimations de capacité pour [input] (inspecteur, simulateur).
  List<ExerciseEstimate> estimates(Catalog catalog, AdaptInput input) {
    final (_, _, replayed) = prepare(catalog, input);
    return estimatesOf(replayed.state);
  }
}
