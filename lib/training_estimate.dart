// Planned volume and elapsed time. Cadences are explicit modelling assumptions,
// never a measurement of physiological load. Unknown prescriptions stay visible.
import 'dart:math' as math;

import 'models.dart';

class Span {
  final double low, high;
  const Span(this.low, this.high);
  const Span.exact(double value) : low = value, high = value;
  static const zero = Span.exact(0);
  double get midpoint => (low + high) / 2;
  Span operator +(Span b) => Span(low + b.low, high + b.high);
  Span times(double n) => Span(low * n, high * n);
  Span multiply(Span b) => Span(low * b.low, high * b.high);
  String get label => low.round() == high.round()
      ? '${low.round()}'
      : '${low.floor()}–${high.ceil()}';
}

class MovementVolume {
  final String name, unit;
  final Span amount;
  final double? kg;
  const MovementVolume(this.name, this.unit, this.amount, {this.kg});
  MovementVolume scaled(Span factor) =>
      MovementVolume(name, unit, amount.multiply(factor), kg: kg);
}

class TrainingEstimate {
  Span work = Span.zero, rest = Span.zero, transitions = Span.zero;
  Span? clock;
  double sets = 0;
  bool partial = false, projected = false;
  final List<String> notes = [];
  final List<MovementVolume> movements = [];
  final List<({String title, TrainingEstimate estimate})> details = [];
  Span get elapsed => clock ?? work + rest + transitions;
  Span volume(String unit) => movements
      .where((m) => m.unit == unit)
      .fold(Span.zero, (s, m) => s + m.amount);
  Span get tonnage => movements
      .where((m) => m.unit == 'rep' && m.kg != null)
      .fold(Span.zero, (s, m) => s + m.amount.times(m.kg!));
  bool get hasTonnage =>
      movements.any((m) => m.unit == 'rep' && (m.kg ?? 0) > 0);
  String get durationLabel {
    if (elapsed.high <= 0) return partial ? 'À préciser' : '—';
    if (partial && clock == null) {
      if (elapsed.low < 60) return '≥ ${elapsed.low.floor()} s';
      return '≥ ${math.max(1, (elapsed.low / 60).floor())} min';
    }
    if (elapsed.high < 60) {
      final lo = elapsed.low.floor(), hi = elapsed.high.ceil();
      return lo == hi ? '${clock == null ? '≈ ' : ''}$lo s' : '$lo–$hi s';
    }
    final lo = math.max(1, (elapsed.low / 60).floor());
    final hi = math.max(1, (elapsed.high / 60).ceil());
    if (clock != null && elapsed.low == elapsed.high) {
      return formatSeconds(elapsed.low);
    }
    return lo == hi ? '≈ $lo min' : '$lo–$hi min';
  }

  String get volumeLabel {
    final parts = <String>[];
    for (final u in [
      ('rep', 'rép.'),
      ('s', 's d’effort'),
      ('m', 'm'),
      ('cal', 'cal'),
    ]) {
      final amount = volume(u.$1);
      if (amount.high > 0) parts.add('${amount.label} ${u.$2}');
    }
    if (parts.isEmpty) return partial ? 'Volume à préciser' : 'Récupération';
    return '${projected ? '≈ ' : ''}${parts.join(' · ')}${partial ? ' + non chiffré' : ''}';
  }

  void add(TrainingEstimate e, {double factor = 1}) {
    // Fixed-duration sub-blocks already distribute their clock into components.
    work = work + e.work.times(factor);
    rest = rest + e.rest.times(factor);
    transitions = transitions + e.transitions.times(factor);
    sets += e.sets * factor;
    partial |= e.partial;
    projected |= e.projected;
    movements.addAll(e.movements.map((m) => m.scaled(Span.exact(factor))));
    notes.addAll(e.notes);
  }

  static String formatSeconds(double value) {
    final s = value.round();
    if (s < 60) return '$s s';
    return '${s ~/ 60} min${s % 60 == 0 ? '' : ' ${s % 60} s'}';
  }
}

class TrainingEstimator {
  static String normalize(String s) => s
      .toLowerCase()
      .replaceAll('–', '-')
      .replaceAll('−', '-')
      .replaceAll('’', "'")
      .replaceAll('″', '"')
      .replaceAll('′', "'")
      .trim();
  static double number(String s) => double.parse(s.replaceAll(',', '.'));

  /// Text has priority: the original dataset contains e.g. restSec=120 for 2 min 30.
  static Span? duration(String text) {
    final t = normalize(text);
    final m = RegExp(
      r'''(\d+(?:[.,]\d+)?)(?:\s*-\s*(\d+(?:[.,]\d+)?))?\s*(min(?:utes?)?|s(?:ec(?:ondes?)?)?|["'])''',
    ).firstMatch(t);
    if (m == null) return null;
    final f = m[3]!.startsWith('min') || m[3] == "'" ? 60.0 : 1.0;
    var lo = number(m[1]!) * f, hi = number(m[2] ?? m[1]!) * f;
    if (f == 60 && m[2] == null) {
      final seconds = RegExp(
        r'^\s*(\d{1,2})(?:\s*s|\s*"|\s*$)',
      ).firstMatch(t.substring(m.end));
      if (seconds != null) {
        lo += number(seconds[1]!);
        hi = lo;
      }
    }
    return Span(math.min(lo, hi), math.max(lo, hi));
  }

  /// Seconds / repetition, including a plausible cadence range if no tempo is given.
  static Span cadence(String name, [String tempo = '']) {
    final n = normalize(name), t = normalize(tempo);
    final four = RegExp(
      r'^(\d+)[- /](\d+)[- /](\d+|x)[- /](\d+)$',
    ).firstMatch(t);
    if (four != null) {
      final total = List.generate(
        4,
        (i) => four[i + 1] == 'x' ? 1.0 : number(four[i + 1]!),
      ).reduce((a, b) => a + b);
      return Span.exact(total);
    }
    final explicit = duration(t);
    if (explicit != null) {
      if (RegExp(r'pause|tenue|poitrine|descente|exc\.').hasMatch(t)) {
        return explicit + const Span(1, 2);
      }
      return explicit;
    }
    if (t.contains('lent')) return const Span(3, 5);
    if (RegExp(
      r'muscle.?up|\bmu\b|burpee|wall walk|dragon|négatif|excentrique',
    ).hasMatch(n)) {
      return const Span(4, 6);
    }
    if (RegExp(r'double.?under|corde').hasMatch(n)) return const Span(.5, .8);
    if (RegExp(
      r'traction|pull.?up|chin.?up|pistol|hspu|toes|squat.*70|soulevé|deadlift',
    ).hasMatch(n)) {
      return const Span(2.5, 4);
    }
    return const Span(2, 3);
  }

  static Span pace(String name) {
    final n = normalize(name);
    if (RegExp(r'burpee|fente|lunge').hasMatch(n)) return const Span(2, 4);
    if (RegExp(r'carry|farmer').hasMatch(n)) return const Span(.8, 1.3);
    if (RegExp(r'bike|vélo').hasMatch(n)) return const Span(.10, .18);
    if (RegExp(r'row|rameur|ski').hasMatch(n)) return const Span(.22, .32);
    if (n.contains('erg')) return const Span(.10, .32);
    if (RegExp(r'marche|walk').hasMatch(n)) return const Span(.55, .85);
    if (n.contains('très rapide') || n.contains('sprint')) {
      return const Span(.14, .22);
    }
    if (n.contains('rapide') && !n.contains('lent')) {
      return const Span(.20, .30);
    }
    if (RegExp(r'lent|footing|récupération').hasMatch(n)) {
      return const Span(.35, .48);
    }
    return const Span(.27, .39);
  }

  static Span workOf(MovementVolume m, [String tempo = '']) =>
      m.amount.multiply(switch (m.unit) {
        's' => const Span.exact(1),
        'm' => pace(m.name),
        'cal' => const Span(3, 5),
        _ => cadence(m.name, tempo),
      });
  static double? externalKg(String text) {
    final t = normalize(text);
    // Alternative weights do not identify the athlete's chosen weight.
    if (RegExp(r'\d\s*/\s*\d').hasMatch(t)) return null;
    final m = RegExp(
      r'(?:(\d+)\s*[×x]\s*)?(\d+(?:[.,]\d+)?)\s*kg',
    ).firstMatch(t);
    return m == null ? null : number(m[2]!) * number(m[1] ?? '1');
  }

  static int sides(String text) =>
      RegExp(
        r'/(?:bras|jambe|côté)|par (?:bras|jambe|côté)|each (?:side|arm|leg)|unilatéral',
      ).hasMatch(normalize(text))
      ? 2
      : 1;

  static List<int> scheme(String text) {
    final t = normalize(text);
    if (t.contains('/')) return [];
    final ns = RegExp(
      r'\d+',
    ).allMatches(t).map((m) => int.parse(m[0]!)).toList();
    if (ns.length < 2) return ns;
    if (!RegExp(r'…|\.\.\.|→').hasMatch(t)) return ns;
    final step = ns.length > 2 ? ns[1] - ns[0] : (ns.last >= ns.first ? 1 : -1);
    if (step == 0 || (ns.last - ns.first) * step < 0) return [];
    final count = math.min(1000, (ns.last - ns.first).abs() ~/ step.abs() + 1);
    return List.generate(count, (i) => ns.first + i * step);
  }

  static TrainingEstimate exercise(
    Exercise e, {
    required String prescription,
    double? kg,
    int defaultRest = 90,
    double? repMax,
  }) {
    final out = TrainingEstimate();
    final text = normalize(prescription), name = normalize(e.name);
    final timer = e.timer;
    final interval = e.interval;
    if (interval != null || timer?['type'] == 'hiit') {
      final rounds = interval?.rounds ?? timer!['rounds'] as int;
      final work = interval?.work ?? timer!['work'] as int;
      final rest = interval?.rest ?? timer!['rest'] as int;
      out.sets = rounds.toDouble();
      out.work = Span.exact((rounds * work).toDouble());
      // Matches the runner: no recovery after the last work interval.
      out.rest = Span.exact((math.max(0, rounds - 1) * rest).toDouble());
      out.clock = out.work + out.rest;
      out.movements.add(MovementVolume(e.name, 's', out.work));
      return out;
    }
    if (text.startsWith('emom')) {
      final min = RegExp(r'emom\s*(\d+)\s*min').firstMatch(text);
      final custom = RegExp(
        r'emom\s*(\d+)\s*[×x]\s*(\d+)\s*s',
      ).firstMatch(text);
      final rounds =
          timer?['rounds'] as int? ??
          int.tryParse(min?[1] ?? custom?[1] ?? '') ??
          1;
      final seconds =
          timer?['interval'] as int? ?? int.tryParse(custom?[2] ?? '') ?? 60;
      final reps = RegExp(r'(\d+)\s*reps').firstMatch(text);
      return emom(
        ['${reps?[1] ?? ''} ${e.name}${kg == null ? '' : ' $kg kg'}'],
        rounds: rounds,
        interval: seconds,
      );
    }
    if (text.startsWith('amrap') || timer?['type'] == 'amrap') {
      out.clock = Span.exact(
        ((timer?['sec'] as int?) ?? duration(text)?.midpoint ?? 0).toDouble(),
      );
      out.work = out.clock!;
      out.movements.add(MovementVolume(e.name, 's', out.work));
      out.notes.add('Durée imposée ; nombre de répétitions libre.');
      return out;
    }
    if (RegExp(r'^\d+(?:-\d+)?\s*min$').hasMatch(text)) {
      out.work = duration(text)!;
      out.clock = out.work;
      out.movements.add(MovementVolume(e.name, 's', out.work));
      return out;
    }
    if (text == '—' || text.isEmpty) {
      if (!name.contains('bilan')) {
        out.partial = true;
        out.notes.add('Prescription manquante : ${e.name}.');
      }
      return out;
    }
    var n =
        e.forcedSets ??
        int.tryParse(
          RegExp(r'^(\d+)\s*(?:[×x]|rounds?|échelles?)').firstMatch(text)?[1] ??
              '',
        ) ??
        1;
    final side = sides('$text $name');
    var reps = Span.zero, hold = Span.zero;
    final myo = RegExp(
      r'^1\s*[×x]\s*(\d+)(?:-(\d+))?\s*puis\s*(\d+)\s*[×x]\s*\(?(\d+)',
    ).firstMatch(text);
    final cluster = RegExp(
      r'^(\d+)\s*[×x]\s*\((\d+)\s*[×x]\s*(\d+)\)',
    ).firstMatch(text);
    final standard = RegExp(r'^\d+\s*[×x]\s*(\d+)(?:-(\d+))?').firstMatch(text);
    final ladder = RegExp(
      r'échelles?.*de\s*(\d+)\s*à\s*(\d+)',
    ).firstMatch(text);
    var microRest = Span.zero;
    if (myo != null) {
      n = 1 + int.parse(myo[3]!);
      reps =
          Span(number(myo[1]!), number(myo[2] ?? myo[1]!)) +
          Span.exact(number(myo[3]!) * number(myo[4]!));
      microRest =
          (duration(e.rest) ??
                  duration(text.substring(myo.end)) ??
                  const Span.exact(15))
              .times((n - 1).toDouble());
    } else if (cluster != null) {
      reps = Span.exact(
        number(cluster[1]!) * number(cluster[2]!) * number(cluster[3]!),
      );
      microRest =
          (duration(text.substring(cluster.end)) ?? const Span.exact(20)).times(
            n * (number(cluster[2]!) - 1),
          );
    } else if (ladder != null) {
      final a = int.parse(ladder[1]!), b = int.parse(ladder[2]!);
      reps = Span.exact(n * (a + b) * ((a - b).abs() + 1) / 2);
      microRest = const Span(5, 15).times(n * (a - b).abs().toDouble());
      out.notes.add('Échelles : 5–15 s estimées entre paliers.');
    } else if (text.contains('round') && text.contains(':')) {
      final circuit = parseLine(text);
      out.add(circuit);
      out.sets = n.toDouble();
    } else if (text.contains('montée')) {
      n = 6;
      reps = const Span.exact(6);
      out.projected = true;
      out.notes.add('Test 1RM : hypothèse de 3 montées et 3 tentatives.');
    } else if (RegExp(r'^\d+(?:-\d+){2,}$').hasMatch(text)) {
      final ns = scheme(text);
      n = ns.length;
      reps = Span.exact(ns.fold(0.0, (a, b) => a + b));
    } else if (text.contains('max')) {
      out.projected = true;
      if (RegExp(r'isom|hang|hold|tenue').hasMatch('$name ${e.tempo}')) {
        out.partial = true;
        out.notes.add('Tenue maximale non connue : durée à préciser.');
      } else if (repMax != null && repMax > 0) {
        reps = Span(repMax * .7, repMax).times(n.toDouble());
        out.notes.add(
          'Répétitions maximales estimées à partir de tes références (70–100 %).',
        );
      } else {
        out.partial = true;
        out.notes.add('Maximum non renseigné : volume et effort non chiffrés.');
      }
    } else if (standard != null) {
      final amount = Span(
        number(standard[1]!),
        number(standard[2] ?? standard[1]!),
      ).times(n.toDouble());
      if (RegExp(r'^\s*s\b').hasMatch(text.substring(standard.end))) {
        final angles = text.contains('par angle')
            ? int.tryParse(
                    RegExp(r'(\d+) angles').firstMatch(name)?[1] ?? '',
                  ) ??
                  1
            : 1;
        hold = amount.times(angles.toDouble());
        if (angles > 1) {
          out.notes.add('$angles angles comptés pour chaque série.');
        }
        out.work =
            out.work +
            (duration(e.tempo)?.times((n * angles).toDouble()) ?? Span.zero);
      } else {
        reps = amount;
      }
      if (text.contains('cluster')) {
        // In the source programme, these clusters are singles with an intra pause.
        final intra =
            duration(text.substring(standard.end)) ?? const Span.exact(30);
        microRest = Span(
          math.max(0, reps.low - n),
          math.max(0, reps.high - n),
        ).multiply(intra);
        out.notes.add(
          'Clusters : pause intra entre les répétitions (singles).',
        );
      }
    } else {
      out.partial = true;
      out.notes.add('Prescription à préciser : $prescription.');
    }
    reps = reps.times(side.toDouble());
    hold = hold.times(side.toDouble());
    if (side == 2) out.notes.add('Les deux côtés sont comptés.');
    if (text.contains('flex.') && text.contains('ext.')) {
      reps = reps.times(2);
      out.notes.add('Flexion et extension comptées séparément.');
    }
    var mass = kg;
    if (mass != null &&
        name.contains('par haltère') &&
        !name.contains('unilatéral') &&
        !text.contains('/bras')) {
      mass *= 2;
      out.notes.add('Tonnage calculé avec deux haltères.');
    }
    if (reps.high > 0) {
      final m = MovementVolume(e.name, 'rep', reps, kg: mass);
      out.movements.add(m);
      out.work = out.work + workOf(m, e.tempo);
    }
    if (hold.high > 0) {
      out.movements.add(MovementVolume(e.name, 's', hold));
      out.work = out.work + hold;
    }
    out.sets = n.toDouble();
    var rest =
        duration(e.rest) ??
        (e.restSec == null ? null : Span.exact(e.restSec!.toDouble()));
    if (rest == null && n > 1 && e.rest.trim() != '—') {
      rest = Span.exact(defaultRest.toDouble());
      out.notes.add('Repos par défaut : $defaultRest s.');
    }
    if (myo != null) rest = Span.zero;
    out.rest =
        out.rest +
        (rest ?? Span.zero).times(math.max(0, n - 1).toDouble()) +
        microRest;
    if (normalize(e.rest).contains('après')) {
      out.rest = rest ?? Span.zero;
      out.notes.add('Délai minimal avant cet exercice : ${e.rest}.');
    }
    return out;
  }

  /// Split only at the top level, preserving decimals and nested combinations.
  static List<String> _split(String text) {
    var depth = 0, start = 0;
    final out = <String>[];
    for (var i = 0; i < text.length; i++) {
      if (text[i] == '(') depth++;
      if (text[i] == ')') depth--;
      final comma =
          text[i] == ',' &&
          !(i > 0 &&
              i + 1 < text.length &&
              RegExp(r'\d').hasMatch(text[i - 1]) &&
              RegExp(r'\d').hasMatch(text[i + 1]));
      if (depth == 0 && ('+·;'.contains(text[i]) || comma)) {
        out.add(text.substring(start, i));
        start = i + 1;
      }
    }
    out.add(text.substring(start));
    return out.where((s) => s.trim().isNotEmpty).toList();
  }

  static TrainingEstimate parseLine(
    String source, {
    String repScheme = '',
    int depth = 0,
  }) {
    final out = TrainingEstimate();
    var t = normalize(source);
    if (t.isEmpty) return out;
    if (depth > 12) {
      out.partial = true;
      return out;
    }
    t = t.replaceFirst(
      RegExp(r'^(?:min\b[^:]*|cash in|cash out|finisher)\s*:\s*'),
      '',
    );
    final amrap = RegExp(r'^amrap\s*(\d+)\s*min\s*:\s*(.*)$').firstMatch(t);
    if (amrap != null) {
      return _amrap(
        parseLine(amrap[2]!, depth: depth + 1),
        number(amrap[1]!) * 60,
      );
    }
    final rounds = RegExp(r'^(\d+)\s+rounds?[^:]*:\s*(.*)$').firstMatch(t);
    if (rounds != null) {
      out.add(
        parseLine(rounds[2]!, depth: depth + 1),
        factor: number(rounds[1]!),
      );
      return out;
    }
    // Repeated blocks with recovery between repetitions, including track intervals.
    final repeated = RegExp(
      r'^(\d+)\s*[×x]\s*(.+?)(?:\s*[·;]\s*(?:repos|rest)\s*(.+))?$',
    ).firstMatch(t);
    if (repeated != null && !t.contains('+') && !t.contains('(')) {
      final n = number(repeated[1]!);
      out.add(
        parseLine(repeated[2]!, repScheme: repScheme, depth: depth + 1),
        factor: n,
      );
      if (repeated[3] != null) {
        out.rest =
            out.rest +
            (duration(repeated[3]!) ?? Span.zero).times(math.max(0, n - 1));
      }
      return out;
    }
    final blockRest = RegExp(
      r'^(\d+)\s*[×x]\s*\((.*)\)\s*[·;]\s*(?:repos|rest)\s*(.+)$',
    ).firstMatch(t);
    if (blockRest != null) {
      final n = number(blockRest[1]!);
      out.add(
        parseLine(blockRest[2]!, repScheme: repScheme, depth: depth + 1),
        factor: n,
      );
      out.rest =
          out.rest +
          (duration(blockRest[3]!) ?? Span.zero).times(math.max(0, n - 1));
      return out;
    }
    final chunks = _split(t);
    if (chunks.length > 1) {
      for (final s in chunks) {
        out.add(parseLine(s, repScheme: repScheme, depth: depth + 1));
      }
      out.transitions =
          out.transitions +
          const Span(
            3,
            8,
          ).times(math.max(0, out.movements.length - 1).toDouble());
      return out;
    }
    final prefix = RegExp(r'^(\d+)\s*[×x]\s*\((.*)\)$').firstMatch(t);
    final suffix = RegExp(r'^\((.*)\)\s*[×x]\s*(\d+)$').firstMatch(t);
    if (prefix != null || suffix != null) {
      final inner = prefix?[2] ?? suffix![1]!;
      final n = number(prefix?[1] ?? suffix![2]!);
      out.add(
        parseLine(inner, repScheme: repScheme, depth: depth + 1),
        factor: n,
      );
      out.transitions =
          out.transitions + const Span(3, 8).times(math.max(0, n - 1));
      return out;
    }
    if (RegExp(
      r'''^(?:rest|repos)\b|^\d+(?:[.,]\d+)?\s*(?:min|s|["'])\s*(?:de\s+)?(?:rest|repos)\b''',
    ).hasMatch(t)) {
      final sec = duration(t);
      if (sec != null) {
        out.rest = sec;
      } else if (t != 'repos' && t != 'rest') {
        out.partial = true;
        out.notes.add('Repos non chiffré : $source.');
      }
      return out;
    }
    if (RegExp(r'\d\s*(?:…|\.\.\.)').hasMatch(t)) {
      out.partial = true;
      out.notes.add(
        'Échelle ouverte : répétitions à adapter au nombre de tours atteint.',
      );
      return out;
    }
    Span? amount;
    var unit = 'rep';
    final ladder = RegExp(
      r'^(\d+(?:\s*[-→]\s*(?:\d+|…|\.\.\.)){2,})\s+(.*)$',
    ).firstMatch(t);
    if (ladder != null) {
      amount = Span.exact(scheme(ladder[1]!).fold(0.0, (a, b) => a + b));
      t = ladder[2]!;
    } else {
      final leading = RegExp(
        r'^(\d+(?:[.,]\d+)?)(?:\s*-\s*(\d+(?:[.,]\d+)?))?\s*',
      ).firstMatch(t);
      if (leading != null) {
        amount = Span(number(leading[1]!), number(leading[2] ?? leading[1]!));
        t = t.substring(leading.end);
        final u = RegExp(
          r'''^(km|min|m|s|cal(?:ories)?|["'])(?![a-zà-ÿ])\s*''',
        ).firstMatch(t);
        if (u != null) {
          final raw = u[1]!;
          unit = switch (raw) {
            'km' || 'm' => 'm',
            'min' || 's' || '"' || "'" => 's',
            _ => 'cal',
          };
          if (raw == 'km') amount = amount.times(1000);
          if (raw == 'min' || raw == "'") amount = amount.times(60);
          t = t.substring(u.end);
          if (unit == 'm' && repScheme.isNotEmpty) {
            amount = amount.times(
              math.max(1, scheme(repScheme).length).toDouble(),
            );
          }
        }
      } else {
        final ns = scheme(repScheme);
        if (ns.isNotEmpty) amount = Span.exact(ns.fold(0.0, (a, b) => a + b));
      }
    }
    if (amount == null || (t.isEmpty && unit == 'rep')) {
      out.partial = true;
      out.notes.add('Volume non chiffré : $source.');
      return out;
    }
    amount = amount.times(sides(t).toDouble());
    final movement = MovementVolume(
      t.isEmpty ? 'Effort' : t,
      unit,
      amount,
      kg: externalKg(t),
    );
    out.movements.add(movement);
    out.work = workOf(movement);
    out.sets = 1;
    return out;
  }

  static TrainingEstimate _amrap(
    TrainingEstimate round,
    double seconds, {
    int restSec = 0,
  }) {
    final out = TrainingEstimate();
    final cycle = round.elapsed + Span.exact(restSec.toDouble());
    if (cycle.low > 0) {
      final factor = Span(seconds / cycle.high, seconds / cycle.low);
      out.movements.addAll(round.movements.map((m) => m.scaled(factor)));
      out.sets = round.sets * factor.midpoint;
      // Use component proportions; the clock, not rounding of estimated rounds, is authoritative.
      final k = seconds / cycle.midpoint;
      out.work = Span.exact(round.work.midpoint * k);
      out.rest = Span.exact((round.rest.midpoint + restSec) * k);
      out.transitions = Span.exact(round.transitions.midpoint * k);
    } else {
      out.work = Span.exact(seconds);
    }
    out.clock = Span.exact(seconds);
    out.projected = true;
    out.partial = round.partial;
    out.notes.addAll(round.notes);
    out.notes.add('AMRAP : volume projeté selon la cadence, durée fixe.');
    return out;
  }

  /// EMOM d'un exercice du programme : [lines] à refaire au début de chaque
  /// intervalle de [interval] secondes, [rounds] fois (même calcul qu'avant
  /// G2, qui l'a sorti de l'estimation des WOD).
  static TrainingEstimate emom(
    List<String> lines, {
    required int rounds,
    required int interval,
  }) {
    final out = TrainingEstimate();
    final parsed = [for (final line in lines) parseLine(line)];
    final outside = <int>{
      for (var i = 0; i < lines.length; i++)
        if (RegExp(
          r'^(?:cash[ -]in|cash[ -]out|finisher)\s*:',
          caseSensitive: false,
        ).hasMatch(lines[i].trim()))
          i,
    };
    final labelled = lines.any(
      (l) => RegExp(r'^min\s*\d', caseSensitive: false).hasMatch(l),
    );
    for (var slot = 1; slot <= rounds; slot++) {
      final visit = TrainingEstimate();
      for (var i = 0; i < parsed.length; i++) {
        if (!outside.contains(i) &&
            (!labelled || _visits(lines[i], slot, interval))) {
          visit.add(parsed[i]);
        }
      }
      final k = math.max(0, visit.movements.length - 1);
      visit.transitions =
          visit.transitions + const Span(3, 8).times(k.toDouble());
      final required = visit.elapsed;
      if (required.high > interval) {
        out.notes.add(
          'Le travail prévu peut dépasser un intervalle de $interval s.',
        );
      }
      out.movements.addAll(visit.movements);
      out.sets += visit.sets;
      out.partial |= visit.partial;
      out.notes.addAll(visit.notes);
      // Effort bounded by the interval, with the remaining time as recovery.
      final effort = math.min(interval.toDouble(), visit.work.midpoint);
      final transition = math.min(
        math.max(0.0, interval - effort),
        visit.transitions.midpoint,
      );
      out.work = out.work + Span.exact(effort);
      out.transitions = out.transitions + Span.exact(transition);
      out.rest = out.rest + Span.exact(interval - effort - transition);
    }
    out.clock = Span.exact((rounds * interval).toDouble());
    out.notes.add(
      'EMOM : volume prescrit ; récupération incluse dans les intervalles.',
    );
    if (outside.isNotEmpty) {
      final extra = TrainingEstimate();
      for (final i in outside) {
        extra.add(parsed[i]);
      }
      extra.transitions =
          extra.transitions + const Span(3, 8).times(outside.length.toDouble());
      out.add(extra);
      out.clock = out.clock! + extra.elapsed;
      out.notes.add(
        'Cash in / cash out : comptés une seule fois, en dehors des intervalles.',
      );
    }
    if (RegExp(
      r'pénalité|à partager|binôme|au choix',
      caseSensitive: false,
    ).hasMatch(lines.join(' '))) {
      out.notes.add(
        'Options, pénalités ou partage en équipe : estimation du volume écrit, à adapter.',
      );
    }
    for (var i = 0; i < parsed.length && i < lines.length; i++) {
      out.details.add((title: lines[i], estimate: parsed[i]));
    }
    return out;
  }

  static bool _visits(String line, int slot, int interval) {
    final m = RegExp(r'^min\s*([^:]+):').firstMatch(normalize(line));
    if (m == null) return true;
    final t = m[1]!;
    final minute = 1 + (slot - 1) * interval ~/ 60;
    final nums = RegExp(
      r'\d+',
    ).allMatches(t).map((m) => int.parse(m[0]!)).toList();
    if (nums.isEmpty) return false;
    if (t.contains('-') && nums.length == 2) {
      return minute >= nums[0] && minute <= nums[1];
    }
    if (RegExp(r'…|\.\.\.').hasMatch(t) && nums.length > 1) {
      final step = nums[1] - nums[0];
      return step > 0 && minute >= nums[0] && (minute - nums[0]) % step == 0;
    }
    return nums.contains(minute);
  }
}
