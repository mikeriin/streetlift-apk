// G9 : textes français de la séance servie par `kalis_adapt` — codes de
// raison `adapt.*`, ajustements du bilan, conseils pendant la séance,
// résumé de fin. Le moteur ne produit aucun texte (PIPELINE_GP.md §3) :
// tout ce que Koach dit de la séance vient d'ici. Tutoiement, phrases
// courtes, aucune allégation médicale, aucune promesse de résultat (L13).
import 'package:kalis_core/kalis_core.dart' as kc;

import '../athlete_profile.dart' show kZoneLabels;
import '../plan/reason_texts_0_4.dart' show reasonText04;

/// « 62,5 kg », « 60 kg », « 7,25 kg ».
String adaptKg(double kg) {
  final t = kg == kg.roundToDouble()
      ? kg.toInt().toString()
      : kg
            .toStringAsFixed(2)
            .replaceAll(RegExp(r'0+$'), '')
            .replaceAll('.', ',');
  return '$t kg';
}

/// Texte de la colonne kg (point décimal, comme la saisie).
String adaptKgField(double kg) => kg == kg.roundToDouble()
    ? kg.toInt().toString()
    : kg.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '');

String _range(int? a, int? b) {
  if (a == null && b == null) return '';
  final lo = a ?? b!, hi = b ?? a!;
  return lo == hi ? '$lo' : '$lo-$hi';
}

/// « 8 reps », « 6-8 reps », « 30 s ».
String adaptAmount(int? low, int? high, {required bool seconds}) {
  final r = _range(low, high);
  if (r.isEmpty) return '';
  return seconds ? '$r s' : '$r reps';
}

/// CI1f : durée en minutes entières, d'au moins 2 min (mobilité, marche,
/// vélo léger) : la séance la note en minutes (« 1 × 10 min »).
bool prescriptionInMinutes(kc.ExercisePrescription p) {
  final lo = p.secondsLow, hi = p.secondsHigh;
  if (lo == null && hi == null) return false;
  if (p.repsLow != null || p.repsHigh != null) return false;
  if (p.kind == kc.SetKind.test) return false;
  for (final t in p.setTargets ?? const <kc.SetTarget>[]) {
    for (final v in [t.secondsLow, t.secondsHigh]) {
      if (v != null && v % 60 != 0) return false;
    }
  }
  return (lo ?? hi!) >= 120 && (lo ?? 0) % 60 == 0 && (hi ?? 0) % 60 == 0;
}

/// Libellé de la séance prescrite pour un exercice (« 3 × 8-10 »,
/// « 3 × 30 s », « 1 × max », « 1 × 10 min ») ; l'application le relit
/// (LogSpec).
String adaptSetsText(kc.ExercisePrescription p) {
  final seconds = p.secondsLow != null || p.secondsHigh != null;
  final n = p.sets;
  if (prescriptionInMinutes(p)) {
    final lo = (p.secondsLow ?? p.secondsHigh!) ~/ 60;
    final hi = (p.secondsHigh ?? p.secondsLow!) ~/ 60;
    return lo == hi ? '$n × $lo min' : '$n × $lo-$hi min';
  }
  if (p.kind == kc.SetKind.test &&
      ((p.repsHigh ?? 0) >= 100 || (p.secondsHigh ?? 0) >= 300)) {
    return seconds ? '$n × max s' : '$n × max';
  }
  var lo = seconds ? p.secondsLow : p.repsLow;
  var hi = seconds ? p.secondsHigh : p.repsHigh;
  for (final t in p.setTargets ?? const <kc.SetTarget>[]) {
    final a = seconds ? t.secondsLow : t.repsLow;
    final b = seconds ? t.secondsHigh : t.repsHigh;
    if (a != null && (lo == null || a < lo)) lo = a;
    if (b != null && (hi == null || b > hi)) hi = b;
  }
  final r = _range(lo, hi);
  if (r.isEmpty) return '$n série${n > 1 ? 's' : ''}';
  return seconds ? '$n × $r s' : '$n × $r';
}

/// Intensité affichée d'une prescription (flammes visées).
String adaptIntensity(kc.ExercisePrescription p) {
  final f = p.targetFlames;
  if (f == null) return '';
  return 'Difficulté visée $f/10 · RIR ${flamesRir(f)}';
}

/// RIR d'un nombre de flammes (« 2 », « 1,5 », « 5 et plus »).
String flamesRir(int flames) {
  final r = kc.Flames.toRir(flames);
  final t = r == r.roundToDouble()
      ? r.toInt().toString()
      : '$r'.replaceAll('.', ',');
  return kc.Flames.isOpenEnded(flames) ? '$t et plus' : t;
}

String _zone(Object? code) {
  for (final z in kc.BodyZone.values) {
    if (z.code == code) return (kZoneLabels[z] ?? '$code').toLowerCase();
  }
  return 'la zone signalée';
}

/// « le poignet », « l’épaule » : zone de `kalis_core` avec son article.
String _zoneArticle(Object? code) {
  for (final z in kc.BodyZone.values) {
    if (z.code == code) return _zoneArticles[z] ?? 'la zone signalée';
  }
  return 'la zone signalée';
}

const _zoneArticles = <kc.BodyZone, String>{
  kc.BodyZone.neck: 'le cou',
  kc.BodyZone.shoulder: 'l’épaule',
  kc.BodyZone.elbow: 'le coude',
  kc.BodyZone.wristHand: 'le poignet',
  kc.BodyZone.upperBack: 'le haut du dos',
  kc.BodyZone.lowerBack: 'le bas du dos',
  kc.BodyZone.chest: 'la poitrine',
  kc.BodyZone.abdomen: 'le ventre',
  kc.BodyZone.hip: 'la hanche',
  kc.BodyZone.thigh: 'la cuisse',
  kc.BodyZone.knee: 'le genou',
  kc.BodyZone.lowerLeg: 'la jambe',
  kc.BodyZone.ankleFoot: 'la cheville',
};

/// CI1b : arrêt pour une douleur qui dure (`kalis_adapt` 0.2.2, mode
/// coach) dans la séance servie [plan] : zones à l'arrêt et exercices
/// retirés aujourd'hui (vide : aucun arrêt).
///
/// CI1d (`kalis_adapt` 0.2.3) : le moteur ne met plus la raison
/// `adapt.pain_persistent` dans la séance qu'à la première séance de
/// l'arrêt puis une fois par semaine (renvoi vers un professionnel) ; les
/// autres jours, l'arrêt se lit dans les ajustements (exercice retiré ou
/// remplacé pour la zone). La carte reste donc affichée tant que l'arrêt
/// retire ou remplace quelque chose ([painStopNoticeZones] : jours du
/// renvoi).
List<({String zone, List<String> removed})> painStopsOf(
  kc.SessionPlan plan,
  String Function(String exerciseId) exerciseName,
) {
  final zones = <String>[];
  void addZone(kc.Reason r) {
    final z = r.params['zone'];
    if (r.code == 'adapt.pain_persistent' &&
        z is String &&
        !zones.contains(z)) {
      zones.add(z);
    }
  }

  for (final r in plan.reasons) {
    addZone(r);
  }
  for (final a in plan.adjustments) {
    if (a.kind != kc.AdjustmentKind.exerciseRemoved &&
        a.kind != kc.AdjustmentKind.exerciseSwapped) {
      continue;
    }
    a.reasons.forEach(addZone);
  }
  return [
    for (final z in zones)
      (
        zone: _zone(z),
        removed: <String>{
          for (final a in plan.adjustments)
            if (a.kind == kc.AdjustmentKind.exerciseRemoved &&
                a.exerciseId != null &&
                a.reasons.any(
                  (r) =>
                      r.code == 'adapt.pain_persistent' &&
                      r.params['zone'] == z,
                ))
              exerciseName(a.exerciseId!),
        }.toList(),
      ),
  ];
}

/// CI1d : codes des zones à l'arrêt dans la séance [plan] (raisons de la
/// séance et ajustements retirés ou remplacés), comme [painStopsOf].
Set<String> painStopZoneCodes(kc.SessionPlan plan) => <String>{
  for (final r in [
    ...plan.reasons,
    for (final a in plan.adjustments)
      if (a.kind == kc.AdjustmentKind.exerciseRemoved ||
          a.kind == kc.AdjustmentKind.exerciseSwapped)
        ...a.reasons,
  ])
    if (r.code == 'adapt.pain_persistent' && r.params['zone'] is String)
      r.params['zone']! as String,
};

/// CI1d : zones (libellés de [painStopsOf]) dont l'arrêt est « gardé »
/// (`sessions` = 0 : les deux semaines à 2/10 au plus sont acquises, mais
/// l'arrêt ne se lève que sur une semaine de charge).
Set<String> painStopHeldZones(kc.SessionPlan plan) => <String>{
  for (final r in [
    ...plan.reasons,
    for (final a in plan.adjustments) ...a.reasons,
  ])
    if (r.code == 'adapt.pain_persistent' && r.params['sessions'] == 0)
      _zone(r.params['zone']),
};

/// CI1d : texte court d'une raison `adapt.pain_persistent` un jour sans
/// renvoi (sous un exercice) : l'arrêt, sans la consigne de consulter.
String painStopShortText(kc.Reason r) =>
    'Arrêt en cours (${_zone(r.params['zone'])}) : douleur qui dure.';

/// CI1d : zones (libellés de [painStopsOf]) dont la séance porte le renvoi
/// vers un professionnel (`adapt.pain_persistent` dans les raisons de la
/// séance : première séance de l'arrêt, puis une fois par semaine).
Set<String> painStopNoticeZones(kc.SessionPlan plan) => <String>{
  for (final r in plan.reasons)
    if (r.code == 'adapt.pain_persistent' && r.params['zone'] is String)
      _zone(r.params['zone']),
};

/// CI1b : texte de l'arrêt d'une zone dans la séance (douleur qui dure).
/// CI1d : [held] — arrêt gardé (deux semaines basses acquises, levée à la
/// prochaine semaine de charge). [notice] faux — jour sans renvoi (le moteur ne le répète qu'une
/// fois par semaine) : l'arrêt et les retraits sont dits, sans la
/// consigne de consulter.
String painStopText(
  ({String zone, List<String> removed}) s, {
  bool notice = true,
  bool held = false,
}) {
  final head = notice
      ? 'Douleur qui dure (${s.zone}) : 3 sur 10 ou plus depuis plus de deux '
            'semaines, ou revenue après une reprise.'
      : 'Arrêt en cours (${s.zone}) : douleur qui dure.';
  final removed = s.removed.isEmpty
      ? ' Les mouvements qui la chargent restent de côté.'
      : ' Retiré${s.removed.length > 1 ? 's' : ''} aujourd’hui : '
            '${s.removed.join(', ')}.';
  final consult = notice ? ' Consulte un médecin ou un kinésithérapeute.' : '';
  final back = held
      ? ' La gêne est restée basse : les mouvements retirés reviennent à la '
            'prochaine semaine de charge, par paliers.'
      : ' Les mouvements retirés reviendront après deux semaines à 2 sur 10 '
            'au plus, par paliers.';
  return '$head$removed$consult$back';
}

num? _num(Object? v) => v is num ? v : null;

String _dec(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : '$v'.replaceAll('.', ',');

/// Raison `adapt.*` d'une décision du moteur, en français (null : raison
/// interne, rien à dire à l'utilisateur).
String? adaptReasonText(
  kc.Reason r, {
  String Function(String exerciseId)? exerciseName,
}) {
  final p = r.params;
  String name(Object? id) =>
      id is String ? (exerciseName?.call(id) ?? id) : 'cet exercice';
  switch (r.code) {
    case 'adapt.calibration':
      final n = _num(p['session'])?.toInt();
      return n == null
          ? 'Calibrage : je cale la charge sur tes premières séances.'
          : 'Calibrage, séance $n sur 3 au plus : je cale la charge sur ce '
                'que tu fais.';
    case 'adapt.low_confidence':
      return 'Je te connais encore peu sur cet exercice : charge prudente.';
    case 'adapt.load_up':
      final d = _num(p['deltaKg'])?.toDouble();
      return d == null
          ? 'Charge en hausse.'
          : '+${adaptKg(d)} par rapport à la dernière fois.';
    case 'adapt.load_down':
      final d = _num(p['deltaKg'])?.toDouble();
      return d == null
          ? 'Charge en baisse.'
          : '−${adaptKg(d)} par rapport à la dernière fois.';
    case 'adapt.load_held':
      return switch (p['cause']) {
        'health' || 'health_strong' => 'Charge gardée : ton bilan est bas.',
        'pain' => 'Charge gardée : une douleur est signalée.',
        'failure' => 'Charge gardée : la dernière fois, une série a manqué.',
        // CI1d (`kalis_adapt` 0.2.3) : zone à l'arrêt ou en reprise
        // graduée, ou remplaçant d'une douleur du jour : dose prudente.
        'pain_return' =>
          'Zone douloureuse ou en reprise : dose prudente, 3 répétitions en '
              'réserve, pas de hausse aujourd’hui.',
        _ => 'Charge gardée cette fois.',
      };
    case 'adapt.increment_coarse':
      final s = _num(p['stepKg'])?.toDouble();
      return s == null
          ? 'Le plus petit cran est gros : tu progresses par les répétitions.'
          : 'Le plus petit cran (${adaptKg(s)}) est gros : tu progresses '
                'par les répétitions.';
    case 'adapt.flames_below_target':
      return 'Tes séries étaient plus faciles que prévu : un cran de plus, '
          'au ressenti.';
    case 'adapt.flames_above_target':
      return 'La série était plus dure que prévu.';
    case 'adapt.set_failed':
      return 'Série manquée : on ne monte pas.';
    case 'adapt.reps_up':
      return 'Une répétition de plus.';
    case 'adapt.reps_down':
      return 'Une répétition de moins.';
    case 'adapt.pain_reported':
      final i = _num(p['intensity'])?.toInt();
      return 'Douleur signalée (${_zone(p['zone'])}${i == null ? '' : ', $i/10'}) : '
          'je l’épargne aujourd’hui.';
    case 'adapt.pain_persistent':
      return 'Douleur qui dure (${_zone(p['zone'])}) : demande l’avis d’un '
          'médecin ou d’un kinésithérapeute.';
    case 'adapt.health_low':
      return 'Ton bilan est bas : séance allégée.';
    case 'adapt.sleep_low':
      return 'Nuit difficile : je reste prudent.';
    case 'adapt.time_short':
      final a = _num(p['minutesAvailable'])?.toInt();
      return a == null
          ? 'Moins de temps aujourd’hui : séance raccourcie.'
          : 'Tu as $a min : séance raccourcie.';
    case 'adapt.place_changed':
      return 'Autre lieu aujourd’hui : exercice remplacé par un équivalent '
          'faisable sur place.';
    case 'adapt.load_floor':
      return 'La plus petite charge disponible est encore trop lourde : '
          'exercice remplacé.';
    case 'adapt.benchmark_set':
      final rir = _num(p['rir'])?.toDouble();
      final margin = rir == null ? 'une marge' : '${_dec(rir)} en réserve';
      return 'Dernière série ouverte : autant de répétitions que possible en '
          'gardant $margin.';
    case 'adapt.fatigue_high':
      return 'Fatigue accumulée : je reste prudent.';
    case 'adapt.resume_after_break':
      return 'Reprise après une coupure : on repart doucement.';
    case 'adapt.no_rating':
      return 'Séries sans note : je ne les compte pas pour régler la charge.';
    case 'adapt.ratings_uninformative':
      return 'Tes notes confirment presque toujours la cible : je regarde '
          'surtout ce que tu soulèves.';
    case 'adapt.estimate_updated':
      return 'Estimation de ${name(p['exerciseId'])} mise à jour.';
  }
  // CI1 : codes ajoutés par kalis_core 0.4.0, émis par kalis_adapt 0.2.
  return reasonText04(r.code, p, (id) => name(id));
}

/// Ajustement d'une séance (bilan, douleur, temps, lieu), en français.
String adjustmentText(
  kc.SessionAdjustment a,
  String Function(String exerciseId) exerciseName, {
  bool test = false,
}) {
  final x = a.exerciseId == null ? 'un exercice' : exerciseName(a.exerciseId!);
  switch (a.kind) {
    case kc.AdjustmentKind.loadReduced:
      return 'Charge plus légère sur $x.';
    case kc.AdjustmentKind.loadIncreased:
      return 'Charge plus lourde sur $x.';
    case kc.AdjustmentKind.setsReduced:
      final n = -(a.setsDelta ?? -1);
      return '$x : $n série${n > 1 ? 's' : ''} de moins.';
    case kc.AdjustmentKind.exerciseSwapped:
      final to = a.replacementExerciseId == null
          ? 'un équivalent'
          : exerciseName(a.replacementExerciseId!);
      // CI1d (`kalis_adapt` 0.2.3) : pendant l'arrêt du poignet, une
      // poussée en extension devient un appui neutre (parallettes,
      // poignées), au premier palier de la reprise.
      for (final r in a.reasons) {
        if (r.code == 'adapt.pain_persistent' &&
            r.params['zone'] == kc.BodyZone.wristHand.code) {
          return 'Remplacement : $x → $to (appui neutre : '
              '${_zoneArticle(r.params['zone'])} est à l’arrêt, douleur qui '
              'dure).';
        }
      }
      return '$x remplacé par $to.';
    case kc.AdjustmentKind.exerciseRemoved:
      // CI1b (`kalis_adapt` 0.2.2) : retrait pour une douleur qui dure, ou
      // test reporté un jour de bilan bas.
      for (final r in a.reasons) {
        if (r.code == 'adapt.pain_persistent') {
          return '$x retiré : il charge ${_zoneArticle(r.params['zone'])}, '
              'douleur qui dure.';
        }
      }
      if (test &&
          a.reasons.any(
            (r) =>
                r.code == 'adapt.health_low' ||
                r.code == 'adapt.sleep_low' ||
                r.code == 'adapt.fatigue_high',
          )) {
        return 'Test de $x reporté : il se refera à une prochaine séance, '
            'un jour en forme.';
      }
      // CI1d (`kalis_adapt` 0.2.3) : un test ne se fait jamais sur une
      // zone douloureuse ni pendant une reprise : reporté, pas remplacé.
      for (final r in a.reasons) {
        final painToday = r.code == 'adapt.pain_reported';
        final comeback =
            r.code == 'adapt.load_held' && r.params['cause'] == 'pain_return';
        final zone = _zoneArticle(r.params['zone']);
        if (test && painToday) {
          return 'Test de $x reporté : pas de test tant que $zone a été '
              'signalé au-dessus de 2 sur 10 dans la semaine.';
        }
        if (test && comeback) {
          return 'Test de $x reporté : pas de test pendant la reprise après '
              'une douleur.';
        }
        if (painToday) {
          return 'Retiré aujourd’hui : $x (douleur signalée : $zone).';
        }
      }
      return '$x retiré aujourd’hui.';
    case kc.AdjustmentKind.restIncreased:
      return 'Plus de repos sur $x.';
  }
}

/// Ce que l'ajustement du bilan change, ligne par ligne : ajustements du
/// moteur, puis exercices dont la charge ou les séries changent.
List<String> sessionDiffLines(
  kc.SessionPlan base,
  kc.SessionPlan plan,
  String Function(String exerciseId) exerciseName,
) {
  final out = <String>[];
  final done = <String>{};
  for (final a in plan.adjustments) {
    final t = adjustmentText(
      a,
      exerciseName,
      test: base.items.any(
        (b) => b.exerciseId == a.exerciseId && b.kind == kc.SetKind.test,
      ),
    );
    if (done.add(t)) out.add(t);
  }
  final before = {for (final it in base.items) it.slotId: it};
  for (final it in plan.items) {
    final b = before[it.slotId];
    if (b == null || b.exerciseId != it.exerciseId) continue;
    final name = exerciseName(it.exerciseId);
    final kgA = b.setTargets?.first.loadKg ?? b.startLoadKg;
    final kgB = it.setTargets?.first.loadKg ?? it.startLoadKg;
    String? line;
    if (kgA != null && kgB != null && (kgA - kgB).abs() > 1e-6) {
      line = '$name : ${adaptKg(kgB)} au lieu de ${adaptKg(kgA)}.';
    } else if (b.sets != it.sets &&
        // (CI1d : déjà dit par l'ajustement « séries de moins ».)
        !plan.adjustments.any(
          (a) =>
              a.kind == kc.AdjustmentKind.setsReduced &&
              a.exerciseId == it.exerciseId,
        )) {
      line = '$name : ${it.sets} séries au lieu de ${b.sets}.';
    } else if (b.targetFlames != null &&
        it.targetFlames != null &&
        b.targetFlames != it.targetFlames) {
      line =
          '$name : ${it.targetFlames} flammes visées au lieu de '
          '${b.targetFlames}.';
    }
    if (line != null && done.add(line)) out.add(line);
  }
  for (final b in base.items) {
    if (plan.items.any((it) => it.slotId == b.slotId)) continue;
    // CI1b : retrait déjà dit par son ajustement (douleur, test reporté).
    if (plan.adjustments.any(
      (a) =>
          a.kind == kc.AdjustmentKind.exerciseRemoved &&
          a.exerciseId == b.exerciseId,
    )) {
      continue;
    }
    final line = '${exerciseName(b.exerciseId)} retiré aujourd’hui.';
    if (done.add(line)) out.add(line);
  }
  return out;
}

/// Conseil pour la série suivante, en une phrase (null : rien à dire).
String? adviceText(
  kc.IntraSessionAdvice a, {
  required bool seconds,
  double? previousKg,
}) {
  final kg = a.nextLoadKg;
  final amount = seconds
      ? adaptAmount(a.nextSeconds, a.nextSeconds, seconds: true)
      : adaptAmount(a.nextRepsLow, a.nextRepsHigh, seconds: false);
  final target = [
    if (kg != null && kg > 0) adaptKg(kg),
    if (amount.isNotEmpty) amount,
  ].join(' × ');
  final why = a.reasons.any((r) => r.code == 'adapt.set_failed')
      ? 'la série a manqué'
      : a.reasons.any((r) => r.code == 'adapt.flames_above_target')
      ? 'la série était plus dure que prévu'
      : a.reasons.any((r) => r.code == 'adapt.flames_below_target')
      ? 'la série était plus facile que prévu'
      : null;
  final tail = why == null ? '' : ' ($why)';
  switch (a.action) {
    case kc.IntraSessionAction.keep:
      return null;
    case kc.IntraSessionAction.stopExercise:
      return 'Deux séries manquées : on s’arrête là pour cet exercice '
          'aujourd’hui.';
    case kc.IntraSessionAction.restMore:
      return 'Prends une minute de repos en plus avant la série suivante.';
    case kc.IntraSessionAction.loadUp:
    case kc.IntraSessionAction.repsUp:
      return target.isEmpty
          ? 'Un cran de plus pour la série suivante$tail.'
          : 'Série suivante : $target$tail.';
    case kc.IntraSessionAction.loadDown:
    case kc.IntraSessionAction.repsDown:
      return target.isEmpty
          ? 'Un cran de moins pour la série suivante$tail.'
          : 'Série suivante : $target$tail.';
  }
}

/// Réponses à « Comment tu te sens ? » (1 = le plus bas, 5 = le plus haut).
const kFeelLabels = <int, String>{
  1: 'Pas bien',
  2: 'Bof',
  3: 'Correct',
  4: 'Bien',
  5: 'En forme',
};

/// Réponse basse : le détail du bilan est proposé (D5.8).
bool feelIsLow(int overall) => overall <= 2;

/// Une ligne du bilan en mots (seules les réponses données).
List<String> healthCheckLines(kc.HealthCheck c) {
  String five(int v, List<String> l) => l[(v - 1).clamp(0, 4)];
  const scale = ['très bas', 'bas', 'moyen', 'bon', 'très bon'];
  return [
    if (c.overall != null) 'Forme : ${kFeelLabels[c.overall]!.toLowerCase()}',
    if (c.sleepQuality != null) 'Sommeil : ${five(c.sleepQuality!, scale)}',
    if (c.energy != null) 'Énergie : ${five(c.energy!, scale)}',
    if (c.mood != null) 'Humeur : ${five(c.mood!, scale)}',
    if (c.soreness != null)
      'Courbatures : ${five(c.soreness!, const ['très fortes', 'fortes', 'moyennes', 'légères', 'aucune'])}',
    if (c.stress != null)
      'Stress : ${five(c.stress!, const ['très fort', 'fort', 'moyen', 'faible', 'aucun'])}',
    if (c.motivation != null) 'Motivation : ${five(c.motivation!, scale)}',
    if (c.nutrition != null) 'Alimentation : ${five(c.nutrition!, scale)}',
    if (c.hydration != null) 'Hydratation : ${five(c.hydration!, scale)}',
    if (c.minutesAvailable != null)
      'Temps disponible : ${c.minutesAvailable} min',
    if (c.pains != null)
      c.pains!.isEmpty
          ? 'Douleur : aucune'
          : 'Douleur : ${[for (final p in c.pains!) '${_zone(p.zone.code)} ${p.intensity}/10'].join(', ')}',
  ];
}

/// Capacité estimée lisible (« 1RM estimé 117,5 kg », « 12 reps max »).
String capacityText(kc.ExerciseEstimate e) {
  String n(double v) {
    final r = (v * 2).round() / 2;
    return r == r.roundToDouble()
        ? r.toInt().toString()
        : '$r'.replaceAll('.', ',');
  }

  return switch (e.unit) {
    kc.CapacityUnit.oneRmKg => '1RM estimé ${n(e.capacity)} kg',
    kc.CapacityUnit.maxReps => '${e.capacity.round()} reps max estimées',
    kc.CapacityUnit.maxHoldSeconds =>
      '${e.capacity.round()} s de tenue max estimées',
    _ => 'capacité ${n(e.capacity)}',
  };
}
