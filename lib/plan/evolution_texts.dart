// G10 (D5.6, D5.7, D6.4) : ce que Koach dit des propositions du moteur
// dynamique. Les moteurs ne produisent aucun texte (PIPELINE_GP.md §3) :
// nature de la proposition, diff et codes de raison sont rendus ici, en
// phrases courtes, au tutoiement, sans promesse de résultat ni allégation
// médicale (règles L13). Un code inconnu donne un texte générique.
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_koach/kalis_koach.dart' show KoachPose;

import '../adapt/adapt_texts.dart';
import '../athlete_profile.dart' show kZoneLabels;
import 'plan_evolution.dart';
import 'plan_texts.dart';

/// Nature d'une proposition, en titre court.
String evolutionKindTitle(kc.ProposalKind k) => switch (k) {
  kc.ProposalKind.volume => 'Volume',
  kc.ProposalKind.exerciseSwap => 'Échange d’exercice',
  kc.ProposalKind.sessionRestructure => 'Séance réorganisée',
  kc.ProposalKind.blockRestructure => 'Bloc réorganisé',
  kc.ProposalKind.deload => 'Semaine allégée',
  kc.ProposalKind.painSparing => 'Zone épargnée',
  kc.ProposalKind.load => 'Charges',
  kc.ProposalKind.reps => 'Répétitions',
  kc.ProposalKind.schedule => 'Calendrier',
};

/// Pose de Koach pour une proposition.
KoachPose evolutionPose(kc.ProposalKind k, {required bool pending}) {
  if (pending) return KoachPose.idea;
  return switch (k) {
    kc.ProposalKind.volume ||
    kc.ProposalKind.load ||
    kc.ProposalKind.reps => KoachPose.analyze,
    kc.ProposalKind.deload => KoachPose.readTip,
    kc.ProposalKind.painSparing => KoachPose.anatomy,
    kc.ProposalKind.exerciseSwap => KoachPose.direction,
    kc.ProposalKind.sessionRestructure ||
    kc.ProposalKind.blockRestructure ||
    kc.ProposalKind.schedule => KoachPose.explainBoard,
  };
}

/// Niveaux de déblocage (D5.7) : ce que Koach peut faire, à l'infinitif.
const kUnlockCan = <kc.UnlockLevel, String>{
  kc.UnlockLevel.loadsReps: 'régler tes charges et tes répétitions',
  kc.UnlockLevel.volume: 'ajuster ton volume et alléger une semaine',
  kc.UnlockLevel.exerciseSwap: 'échanger un exercice qui stagne',
  kc.UnlockLevel.sessionRestructure: 'réorganiser une séance',
  kc.UnlockLevel.blockRestructure: 'réorganiser ton bloc',
};

/// Quand chaque niveau s'ouvre (règle standard, D5.7).
const kUnlockWhen = <kc.UnlockLevel, String>{
  kc.UnlockLevel.loadsReps: 'dès la première séance',
  kc.UnlockLevel.volume: 'après 2 semaines de séances',
  kc.UnlockLevel.exerciseSwap: 'après 4 semaines',
  kc.UnlockLevel.sessionRestructure: 'après un bloc terminé',
  kc.UnlockLevel.blockRestructure: 'après deux blocs terminés',
};

/// « Dans 2 semaines de séances, je pourrai ajuster ton volume… » ; null
/// si tout est débloqué.
String? unlockNextText({
  required kc.UnlockLevel? next,
  required int weeks,
  required int blocks,
}) {
  if (next == null) return null;
  final can = kUnlockCan[next]!;
  if (blocks > 0) {
    final b = blocks == 1 ? 'un bloc terminé' : '$blocks blocs terminés';
    final w = weeks > 0
        ? ' et $weeks semaine${weeks > 1 ? 's' : ''} de séances'
        : '';
    return 'Encore $b$w, et je pourrai $can.';
  }
  if (weeks > 0) {
    return 'Dans $weeks semaine${weeks > 1 ? 's' : ''} de séances, je '
        'pourrai $can.';
  }
  return 'Je pourrai bientôt $can, dès que je serai assez sûr de moi.';
}

/// Confiance en mots simples.
String confidenceWords(double c) {
  final pct = (c * 100).round();
  final w = c >= 0.85
      ? 'très sûr de moi'
      : c >= 0.7
      ? 'assez sûr de moi'
      : c >= 0.5
      ? 'plutôt sûr de moi'
      : 'encore peu sûr de moi';
  return 'Je suis $w ($pct %).';
}

String _zone(Object? code) {
  for (final z in kc.BodyZone.values) {
    if (z.code == code) return (kZoneLabels[z] ?? z.code).toLowerCase();
  }
  return 'une zone';
}

/// Raison d'une proposition, en français (null : rien à dire).
String? evolutionReasonText(
  kc.Reason r, {
  required String Function(String id) exerciseName,
}) {
  final p = r.params;
  num? n(String k) => p[k] is num ? p[k] as num : null;
  switch (r.code) {
    case 'adapt.deload':
      return 'Ta forme est basse plusieurs séances de suite : une semaine '
          'plus légère pour récupérer.';
    case 'adapt.fatigue_high':
      return 'Ta fatigue s’accumule.';
    case 'adapt.plateau':
      final w = n('weeks')?.toInt();
      return '${exerciseName('${p['exerciseId']}')} ne progresse plus'
          '${w == null ? '' : ' depuis $w semaines'}.';
    case 'adapt.exercise_skipped':
      final t = n('times')?.toInt();
      return 'Tu as sauté ${exerciseName('${p['exerciseId']}')}'
          '${t == null ? ' plusieurs fois' : ' $t fois'}.';
    case 'adapt.load_floor':
      return 'La plus petite charge disponible est encore trop lourde pour '
          'cet exercice.';
    case 'adapt.volume_up':
      final s = n('sets')?.toInt() ?? 1;
      return '$s série${s > 1 ? 's' : ''} de plus.';
    case 'adapt.volume_down':
      final s = n('sets')?.toInt() ?? 1;
      return '$s série${s > 1 ? 's' : ''} de moins.';
    case 'adapt.volume_response':
      final m = '${p['muscle']}';
      final sets = n('weeklySets');
      final label = kMuscleGroupLabels[m] ?? m;
      return sets == null
          ? 'Volume des $label ajusté d’après tes séances.'
          : 'Tes $label font ${sets.round()} séries par semaine : je règle '
                'd’après ce que tes séances montrent.';
    case 'adapt.missed_sessions':
      final missed = n('missed')?.toInt();
      final planned = n('planned')?.toInt();
      return missed == null || planned == null
          ? 'Plusieurs séances n’ont pas été faites.'
          : '$missed séance${missed > 1 ? 's' : ''} sur $planned non '
                'faite${missed > 1 ? 's' : ''} ces dernières semaines : un '
                'programme qui tient dans ta semaine vaut mieux.';
    case 'adapt.time_short':
      return 'Le temps t’a souvent manqué ce jour-là.';
    case 'adapt.pain_reported':
      final i = n('intensity')?.toInt();
      return 'Douleur signalée (${_zone(p['zone'])}'
          '${i == null ? '' : ', $i/10'}) deux séances de suite : je '
          'l’épargne.';
    case 'adapt.unlock_level':
      return null;
  }
  return adaptReasonText(r, exerciseName: exerciseName);
}

/// Raisons lisibles d'une proposition (sans doublon).
List<String> evolutionReasons(
  kc.Proposal p, {
  required String Function(String id) exerciseName,
}) {
  final out = <String>[];
  for (final r in p.reasons) {
    final t = evolutionReasonText(r, exerciseName: exerciseName);
    if (t != null && !out.contains(t)) out.add(t);
  }
  return out;
}

/// Ce qui change, en une phrase (sans le « pourquoi »).
String evolutionAction(
  EvolutionEntry e, {
  required String Function(String id) exerciseName,
  required String Function(int dayIndex) dayName,
}) {
  final p = e.proposal;
  final changes = p.diff?.changes ?? const <kc.PlanChange>[];
  kc.PlanChange? first(kc.ChangeKind k) {
    for (final c in changes) {
      if (c.kind == k) return c;
    }
    return null;
  }

  switch (p.kind) {
    case kc.ProposalKind.volume:
      final c = first(kc.ChangeKind.prescriptionChanged);
      final from = c?.fromPrescription, to = c?.toPrescription;
      if (from != null && to != null) {
        final name = exerciseName(to.exerciseId);
        final d = to.sets - from.sets;
        if (d > 0) {
          return 'ajouter $d série${d > 1 ? 's' : ''} à $name';
        }
        if (d < 0) {
          return 'retirer ${-d} série${d < -1 ? 's' : ''} à $name';
        }
      }
      return 'ajuster ton volume';
    case kc.ProposalKind.deload:
      return 'alléger une semaine (moins de séries, plus de marge)';
    case kc.ProposalKind.exerciseSwap || kc.ProposalKind.painSparing:
      final c = first(kc.ChangeKind.exerciseReplaced);
      if (c?.fromExerciseId != null && c?.toExerciseId != null) {
        return 'remplacer ${exerciseName(c!.fromExerciseId!)} par '
            '${exerciseName(c.toExerciseId!)}';
      }
      final r = first(kc.ChangeKind.exerciseRemoved);
      if (r?.fromExerciseId != null) {
        return 'retirer ${exerciseName(r!.fromExerciseId!)}';
      }
      return p.kind == kc.ProposalKind.painSparing
          ? 'épargner une zone douloureuse'
          : 'échanger un exercice';
    case kc.ProposalKind.sessionRestructure:
      final day = changes.isEmpty || changes.first.dayIndex == null
          ? null
          : dayName(changes.first.dayIndex!);
      return day == null
          ? 'réorganiser une séance'
          : 'réorganiser ta séance du ${day.toLowerCase()}';
    case kc.ProposalKind.blockRestructure:
      return 'réorganiser la suite de ton bloc';
    case kc.ProposalKind.load:
      return 'ajuster tes charges';
    case kc.ProposalKind.reps:
      return 'ajuster tes répétitions';
    case kc.ProposalKind.schedule:
      return 'ajuster ton calendrier';
  }
}

/// « de ajouter » → « d’ajouter » (élision devant une voyelle ou un h).
String de(String s) =>
    RegExp(r'^[aeiouyhàâéèêëîïôûü]', caseSensitive: false).hasMatch(s)
    ? 'd’$s'
    : 'de $s';

/// Quand le changement s'applique, d'après la semaine du bloc où il
/// commence ([fromWeek]) et celle d'aujourd'hui ([currentWeek], null :
/// inconnue ou autre bloc).
String evolutionWhen(int fromWeek, int? currentWeek) {
  if (currentWeek == null) return ' (semaine ${fromWeek + 1} du bloc)';
  if (fromWeek == currentWeek + 1) return ' à partir de la semaine prochaine';
  if (fromWeek == currentWeek) return ' dès cette semaine';
  if (fromWeek > currentWeek) {
    return ' à partir de la semaine ${fromWeek + 1} du bloc';
  }
  return '';
}

/// Phrase avec une majuscule initiale (« Ajouter 1 série à… »).
String capitalized(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// Ce que Koach dit d'une proposition : en place (« J'ai prévu de… ») ou
/// proposée (« Je te propose de… »), avec la première raison.
String evolutionHeadline(
  EvolutionEntry e, {
  required String Function(String id) exerciseName,
  required String Function(int dayIndex) dayName,
  int? currentWeek,
}) {
  final action = evolutionAction(
    e,
    exerciseName: exerciseName,
    dayName: dayName,
  );
  final reasons = evolutionReasons(e.proposal, exerciseName: exerciseName);
  final why = reasons.isEmpty ? '' : ' ${reasons.first}';
  final when = evolutionWhen(e.fromWeek, currentWeek);
  return switch (e.status) {
    EvoStatus.pending => 'Je te propose ${de(action)}$when.$why',
    EvoStatus.applied => 'J’ai prévu ${de(action)}$when.$why',
    EvoStatus.accepted => 'C’est noté : je vais $action$when.',
    EvoStatus.refused => 'Refusé : je ne vais pas $action.',
    EvoStatus.undone => 'Annulé : je ne vais plus $action.',
    _ => capitalized(action),
  };
}

/// Suite donnée, en mots (historique).
String evolutionStatusLabel(String status) => switch (status) {
  EvoStatus.pending => 'En attente',
  EvoStatus.applied => 'Appliqué (mode assisté)',
  EvoStatus.accepted => 'Accepté',
  EvoStatus.refused => 'Refusé',
  EvoStatus.undone => 'Annulé',
  _ => status,
};

/// Ligne d'un changement de prescription : « Lundi · Tractions : 3 × 8-10
/// → 4 × 8-10 ».
String prescriptionChangeLine(kc.PlanChange c, String day, String name) {
  final from = c.fromPrescription, to = c.toPrescription;
  if (from == null || to == null) return '$day · $name';
  final a = prescriptionLabel(from), b = prescriptionLabel(to);
  final fa = from.targetFlames, fb = to.targetFlames;
  final flames = fa != null && fb != null && fa != fb
      ? ', flammes visées $fa → $fb'
      : '';
  return '$day · $name : $a → $b$flames';
}

/// Texte d'une flamme visée pour l'inspecteur.
String inspectorFlames(int? f) => f == null ? '—' : '$f · RIR ${flamesRir(f)}';
