// Générateur déterministe de WODs : aucune donnée stockée, le catalogue se
// recalcule à l'identique à chaque lancement (Random à graine fixe par index).
// Les WODs générés s'inspirent des formats et mouvements présents dans l'app.
import 'dart:math';

import 'wod_models.dart';

class _Mv {
  final String n; // libellé
  final int tier; // difficulté d'accès 1-10
  final int base; // reps de base au tier 5
  final Set<String> eq; // pdc · barre · lest · erg · kb · box · corde
  const _Mv(this.n, this.tier, this.base, this.eq);
}

const _pull = [
  _Mv('rows barre basse', 1, 12, {'barre'}),
  _Mv('pull-ups', 2, 8, {'barre'}),
  _Mv('chin-ups', 2, 8, {'barre'}),
  _Mv('toes-to-bar', 3, 10, {'barre'}),
  _Mv('tractions lestées 10 kg', 6, 5, {'barre', 'lest'}),
  _Mv('muscle-ups', 7, 3, {'barre'}),
  _Mv('tractions lestées 20 kg', 8, 4, {'barre', 'lest'}),
];
const _push = [
  _Mv('push-ups', 1, 15, {'pdc'}),
  _Mv('diamond push-ups', 3, 12, {'pdc'}),
  _Mv('dips', 3, 10, {'barre'}),
  _Mv('pike push-ups', 3, 10, {'pdc'}),
  _Mv('archer push-ups', 5, 8, {'pdc'}),
  _Mv('dips lestés 10 kg', 6, 6, {'barre', 'lest'}),
  _Mv('HSPU', 7, 5, {'pdc'}),
  _Mv('dips lestés 20 kg', 8, 5, {'barre', 'lest'}),
];
const _legs = [
  _Mv('air squats', 1, 20, {'pdc'}),
  _Mv('walking lunges', 1, 16, {'pdc'}),
  _Mv('squat jumps', 2, 12, {'pdc'}),
  _Mv('box jumps', 2, 12, {'box'}),
  _Mv('jumping lunges', 3, 14, {'pdc'}),
  _Mv('goblet squats 24 kg', 4, 12, {'kb'}),
  _Mv('sandbag lunges 20 kg', 5, 12, {'kb'}),
  _Mv('pistol squats', 6, 6, {'pdc'}),
];
const _core = [
  _Mv('sit-ups', 1, 20, {'pdc'}),
  _Mv('plank shoulder taps', 1, 20, {'pdc'}),
  _Mv('hollow rocks', 2, 15, {'pdc'}),
  _Mv('V-ups', 3, 12, {'pdc'}),
  _Mv('leg raises', 3, 12, {'barre'}),
  _Mv('dragon flags', 7, 5, {'pdc'}),
];
const _meta = [
  _Mv('mountain climbers', 1, 30, {'pdc'}),
  _Mv('burpees', 2, 10, {'pdc'}),
  _Mv('kettlebell swings 24 kg', 3, 15, {'kb'}),
  _Mv('wall balls 6 kg', 3, 15, {'kb'}),
  _Mv('double-unders', 3, 30, {'corde'}),
  _Mv('burpees over the box', 4, 8, {'box'}),
  _Mv('devil press 2×15 kg', 6, 8, {'kb'}),
];
const _dist = [
  _Mv('200 m run', 1, 200, {'run'}),
  _Mv('250 m row', 2, 250, {'erg'}),
  _Mv('400 m run', 2, 400, {'run'}),
  _Mv('500 m row', 3, 500, {'erg'}),
  _Mv('500 m skierg', 3, 500, {'erg'}),
  _Mv('15 cal bike', 3, 15, {'erg'}),
  _Mv('50 m farmer carry 2×24 kg', 4, 50, {'kb'}),
];

const _names = [
  'Sentinelle',
  'Bastion',
  'Vigie',
  'Rafale',
  'Garde',
  'Éclaireur',
  'Rempart',
  'Assaut',
  'Colonne',
  'Bivouac',
  'Tarmac',
  'Corvée',
  'Réveil',
  'Hydra',
  'Atlas',
  'Titan',
  'Cobra',
  'Viper',
  'Enclume',
  'Forge',
  'Sierra',
  'Tango',
  'Kilo',
  'Delta',
  'Bravo',
  'Écho',
  'Foxtrot',
  'Lima',
  'Oscar',
  'Romeo',
  'Zulu',
  'Alpha',
  'Charlie',
  'Golf',
  'Hotel',
  'India',
  'Juliett',
  'Mike',
  'Papa',
  'Quebec',
  'Uniform',
  'Victor',
  'Whiskey',
  'Yankee',
  'Meute',
  'Bunker',
  'Casemate',
  'Guérite',
  'Merlon',
  'Barbacane',
];

/// Nombre de WODs générés pour compléter le catalogue à 500.
int generatedCount(int curated) => (500 - curated).clamp(0, 500);

/// Génère `count` WODs distincts (déduplication sur format + mouvements).
List<Wod> generateWods(int count) {
  final out = <Wod>[];
  final seen = <String>{};
  var i = 0;
  while (out.length < count && i < count * 4) {
    final w = generateWod(i++);
    if (seen.add('${w.type}|${w.scheme}|${w.lines.join('|')}')) out.add(w);
  }
  return out;
}

Wod generateWod(int i) {
  final r = Random(7919 * i + 104729);
  final tier = 1 + (i % 10); // 1..10 répartis uniformément
  final family = i % 6; // format
  int pick(List<_Mv> pool, Set<String> used) {
    final ok = [
      for (var k = 0; k < pool.length; k++)
        if (pool[k].tier <= tier + 1 &&
            pool[k].tier >= (tier - 5).clamp(1, 10) &&
            !used.contains(pool[k].n))
          k,
    ];
    final cands =
        ok.isEmpty
            ? [
              for (var k = 0; k < pool.length; k++)
                if (pool[k].tier <= tier + 1) k,
            ]
            : ok;
    return cands[r.nextInt(cands.length)];
  }

  // volume : tier 1 ≈ 60 % de la base, tier 10 ≈ 170 %
  int reps(_Mv m, [double mult = 1]) {
    final f = 0.6 + (tier - 1) * 0.12;
    return max(1, (m.base * f * mult).round());
  }

  String line(_Mv m, [double mult = 1]) {
    if (m.eq.contains('run') || m.eq.contains('erg')) {
      return m.n; // distance fixe
    }
    return '${reps(m, mult)} ${m.n}';
  }

  final used = <String>{};
  _Mv take(List<_Mv> pool) {
    final m = pool[pick(pool, used)];
    used.add(m.n);
    return m;
  }

  final name =
      '${_names[i % _names.length]} ${(i ~/ _names.length + 1).toString().padLeft(2, '0')}';
  final id = 'gen$i';
  switch (family) {
    case 0: // rounds for time
      final n = 3 + r.nextInt(3) + (tier >= 7 ? 1 : 0);
      final pool = [
        take(_pull),
        take(_push),
        take(_legs),
        if (r.nextBool()) take(_core) else take(_meta),
      ];
      return Wod(
        id: id,
        name: name,
        type: 'rounds',
        rounds: n,
        restSec: tier <= 3 ? 60 : 0,
        source: 'kalis',
        lines: [for (final m in pool) line(m)],
        notes: 'Rounds réguliers : garde de la marge sur le premier.',
      );
    case 1: // chipper for time
      final pool = [
        take(_meta),
        take(_pull),
        take(_push),
        take(_legs),
        take(_core),
        take(_meta),
      ];
      return Wod(
        id: id,
        name: name,
        type: 'fortime',
        source: 'kalis',
        lines: [for (final m in pool) line(m, 2.0)],
        minutes: 12 + tier * 2,
        notes: 'Chipper : chaque mouvement une seule fois, dans l\u2019ordre.',
      );
    case 2: // ladder
      final schemes = [
        '21-15-9',
        '15-12-9',
        '10-8-6-4-2',
        '12-9-6',
        '20-16-12-8-4',
      ];
      final scheme = schemes[r.nextInt(schemes.length)];
      final pool = [
        take(_pull),
        take(_push),
        if (tier >= 4) take(_meta) else take(_legs),
      ];
      return Wod(
        id: id,
        name: name,
        type: 'fortime',
        scheme: scheme,
        source: 'kalis',
        lines: [for (final m in pool) m.n],
        notes: 'Schéma $scheme de chaque mouvement, enchaîné.',
      );
    case 3: // amrap
      final min = 8 + 2 * r.nextInt(5) + (tier >= 6 ? 4 : 0);
      final pool = [
        take(_meta),
        take(_push),
        take(_legs),
        if (tier >= 3) take(_pull),
      ];
      return Wod(
        id: id,
        name: name,
        type: 'amrap',
        minutes: min,
        source: 'kalis',
        lines: [for (final m in pool) line(m, 0.6)],
        notes: 'Rythme tenable dès le premier round ; score = rounds + reps.',
      );
    case 4: // emom
      final rounds = 10 + 2 * r.nextInt(4) + (tier >= 7 ? 4 : 0);
      final pool = [take(_pull), take(_push), take(_legs)];
      return Wod(
        id: id,
        name: name,
        type: 'emom',
        rounds: rounds,
        interval: 60,
        source: 'kalis',
        lines: [
          for (var k = 0; k < pool.length; k++)
            'min ${k + 1}, ${k + 4}, ${k + 7}… : ${line(pool[k], 0.5)}',
        ],
        notes:
            'Un mouvement par minute, en rotation. Si une minute déborde, réduis de 2 reps.',
      );
    default: // routine : blocs enchaînés avec repos
      final a = take(_pull), b = take(_push), c = take(_legs), d = take(_dist);
      final sets = 3 + (tier >= 5 ? 1 : 0);
      return Wod(
        id: id,
        name: name,
        type: 'routine',
        restSec: 90,
        source: 'kalis',
        lines: [
          '$sets × (${line(a, 0.7)} + ${line(b, 0.7)}) · repos 90 s',
          '$sets × (${line(c, 0.9)} + ${d.n}) · repos 90 s',
          'Finisher : ${line(_meta[1], 1.0)}',
        ],
        notes: 'Routine en blocs : qualité d\u2019exécution avant la vitesse.',
      );
  }
}

/// Étiquettes de matériel d'un WOD, déduites des mouvements.
final _eqErg = RegExp(r'\brow\b|skierg|bike|erg\b|cal ');
final _eqRun = RegExp(r'\bm run\b|m course|sprint|footing');
final _eqBar = RegExp(
  r'pull|chin|muscle|dip|toes|leg raise|rows barre|traction|\bmu\b|bench',
);
final _eqLest = RegExp(r'\d\s*kg|lest|gilet');
final _eqKb = RegExp(
  r'kettlebell|kb|wall ball|goblet|sandbag|farmer|devil|snatch|halt[eè]re|dumb',
);
final _eqBox = RegExp(r'\bbox\b|step-over|plate');
final _eqRope = RegExp(r'double-under|corde');
final Map<String, Set<String>> _eqCache = {};

Set<String> equipmentOf(Wod w) {
  final key = w.lines.join('\n').toLowerCase();
  final cached = _eqCache[key];
  if (cached != null) return cached;
  final t = w.lines.join(' ').toLowerCase();
  final eq = <String>{};
  if (_eqErg.hasMatch(t)) eq.add('erg');
  if (_eqRun.hasMatch(t)) eq.add('run');
  if (_eqBar.hasMatch(t)) eq.add('barre');
  if (_eqLest.hasMatch(t)) eq.add('lest');
  if (_eqKb.hasMatch(t)) eq.add('kb');
  if (_eqBox.hasMatch(t)) eq.add('box');
  if (_eqRope.hasMatch(t)) eq.add('corde');
  if (eq.isEmpty) eq.add('pdc');
  if (_eqCache.length > 1000) _eqCache.clear();
  _eqCache[key] = Set.unmodifiable(eq);
  return Set.unmodifiable(eq);
}

// =====================================================================
// Deuxième série générée : 500 WODs supplémentaires (ids « genx… »).
// Douze familles, vocabulaire élargi, noms descriptifs (format + mouvements)
// et notes de mise à l'échelle. Déterministe comme la première série ; les
// ids et le contenu des 449 premiers WODs générés ne bougent pas.
// =====================================================================

/// Nombre de WODs de la deuxième série (catalogue total : 1 000).
const generatedCountV2 = 500;

const _pull2 = [
  _Mv('rows barre basse', 1, 12, {'barre'}),
  _Mv('pull-ups', 2, 8, {'barre'}),
  _Mv('chin-ups', 2, 8, {'barre'}),
  _Mv('toes-to-bar', 3, 10, {'barre'}),
  _Mv('chest-to-bar pull-ups', 5, 6, {'barre'}),
  _Mv('tractions lestées 10 kg', 6, 5, {'barre', 'lest'}),
  _Mv('muscle-ups', 7, 3, {'barre'}),
  _Mv('tractions lestées 20 kg', 8, 4, {'barre', 'lest'}),
  _Mv('muscle-ups lestés 5 kg', 9, 2, {'barre', 'lest'}),
];
const _push2 = [
  _Mv('push-ups', 1, 15, {'pdc'}),
  _Mv('pompes déclinées', 2, 12, {'pdc'}),
  _Mv('diamond push-ups', 3, 12, {'pdc'}),
  _Mv('dips', 3, 10, {'barre'}),
  _Mv('pike push-ups', 3, 10, {'pdc'}),
  _Mv('archer push-ups', 5, 8, {'pdc'}),
  _Mv('dips lestés 10 kg', 6, 6, {'barre', 'lest'}),
  _Mv('HSPU', 7, 5, {'pdc'}),
  _Mv('dips lestés 20 kg', 8, 5, {'barre', 'lest'}),
  _Mv('HSPU en déficit', 9, 4, {'pdc'}),
];
const _legs2 = [
  _Mv('air squats', 1, 20, {'pdc'}),
  _Mv('walking lunges', 1, 16, {'pdc'}),
  _Mv('squat jumps', 2, 12, {'pdc'}),
  _Mv('box jumps', 2, 12, {'box'}),
  _Mv('jumping lunges', 3, 14, {'pdc'}),
  _Mv('goblet squats 24 kg', 4, 12, {'kb'}),
  _Mv('sandbag lunges 20 kg', 5, 12, {'kb'}),
  _Mv('pistol squats', 6, 6, {'pdc'}),
  _Mv('pistol squats lestés 10 kg', 8, 4, {'pdc', 'lest'}),
];
const _core2 = [
  _Mv('sit-ups', 1, 20, {'pdc'}),
  _Mv('plank shoulder taps', 1, 20, {'pdc'}),
  _Mv('hollow rocks', 2, 15, {'pdc'}),
  _Mv('V-ups', 3, 12, {'pdc'}),
  _Mv('leg raises', 3, 12, {'barre'}),
  _Mv('toes-to-bar', 4, 10, {'barre'}),
  _Mv('dragon flags', 7, 5, {'pdc'}),
];
const _meta2 = [
  _Mv('mountain climbers', 1, 30, {'pdc'}),
  _Mv('burpees', 2, 10, {'pdc'}),
  _Mv('kettlebell swings 24 kg', 3, 15, {'kb'}),
  _Mv('wall balls 6 kg', 3, 15, {'kb'}),
  _Mv('double-unders', 3, 30, {'corde'}),
  _Mv('burpees over the box', 4, 8, {'box'}),
  _Mv('thrusters 2×15 kg', 5, 10, {'kb'}),
  _Mv('devil press 2×15 kg', 6, 8, {'kb'}),
  _Mv('burpees pull-ups', 6, 6, {'barre'}),
];
const _dist2 = [
  _Mv('200 m run', 1, 200, {'run'}),
  _Mv('250 m row', 2, 250, {'erg'}),
  _Mv('400 m run', 2, 400, {'run'}),
  _Mv('500 m row', 3, 500, {'erg'}),
  _Mv('500 m skierg', 3, 500, {'erg'}),
  _Mv('15 cal bike', 3, 15, {'erg'}),
  _Mv('50 m farmer carry 2×24 kg', 4, 50, {'kb'}),
  _Mv('800 m run', 4, 800, {'run'}),
];
const _skill2 = [
  _Mv('wall walks', 4, 3, {'pdc'}),
  _Mv('pistol squats', 6, 6, {'pdc'}),
  _Mv('muscle-ups', 7, 3, {'barre'}),
  _Mv('HSPU', 7, 5, {'pdc'}),
  _Mv('front lever raises', 8, 3, {'barre'}),
  _Mv('muscle-ups stricts', 9, 2, {'barre'}),
];

/// Schémas décroissants et croissants, par difficulté croissante.
const _descSchemes = [
  '15-12-9',
  '21-15-9',
  '12-9-6-3',
  '20-16-12-8-4',
  '10-8-6-4-2',
];
const _ascSchemes = ['1-2-3-…-8', '1-2-3-…-10', '2-4-6-…-12', '1-2-3-…-12'];

const _scaling = [
  'Débutant : divise les reps par deux · Intermédiaire : tel quel · Confirmé : ajoute un gilet 5 kg.',
  'Garde des séries courtes et propres : mieux vaut fractionner que dégrader la technique.',
  'Objectif : rounds réguliers ; note ton temps par round pour la prochaine tentative.',
  'Respire au sol, jamais en suspension : les transitions coûtent moins que les échecs.',
  'Version longue : +1 round · Version courte : −1 round. Score comparable à mouvements égaux.',
];

String _romanSuffix(int n) {
  const r = [
    '',
    ' II',
    ' III',
    ' IV',
    ' V',
    ' VI',
    ' VII',
    ' VIII',
    ' IX',
    ' X',
  ];
  return n < r.length ? r[n] : ' ×$n';
}

/// Génère `count` WODs distincts de la deuxième série, noms uniques.
List<Wod> generateWodsV2(int count) {
  final out = <Wod>[];
  final seen = <String>{};
  final names = <String, int>{};
  var i = 0;
  while (out.length < count && i < count * 8) {
    final w = generateWodV2(i++);
    if (!seen.add('${w.type}|${w.scheme}|${w.rounds}|${w.lines.join('|')}')) {
      continue;
    }
    final n = names.update(w.name, (v) => v + 1, ifAbsent: () => 0);
    if (n > 0) w.name = '${w.name}${_romanSuffix(n)}';
    out.add(w);
  }
  return out;
}

/// Un WOD de la deuxième série : `i ~/ 10 % 12` choisit la famille, `i % 10`
/// le palier de difficulté 1-10 (volume et mouvements accessibles).
Wod generateWodV2(int i) {
  final r = Random(6007 * i + 15485863);
  final tier = 1 + (i % 10);
  final family = (i ~/ 10) % 12;
  final id = 'genx$i';

  int pick(List<_Mv> pool, Set<String> used) {
    final ok = [
      for (var k = 0; k < pool.length; k++)
        if (pool[k].tier <= tier + 1 &&
            pool[k].tier >= (tier - 5).clamp(1, 10) &&
            !used.contains(pool[k].n))
          k,
    ];
    final cands =
        ok.isEmpty
            ? [
              for (var k = 0; k < pool.length; k++)
                if (pool[k].tier <= tier + 1) k,
            ]
            : ok;
    return cands[r.nextInt(cands.length)];
  }

  // Volume : palier 1 ≈ 60 % de la base, palier 10 ≈ 170 %.
  int reps(_Mv m, [double mult = 1]) {
    final f = 0.6 + (tier - 1) * 0.12;
    return max(1, (m.base * f * mult).round());
  }

  String line(_Mv m, [double mult = 1]) {
    if (m.eq.contains('run') || m.eq.contains('erg')) return m.n;
    return '${reps(m, mult)} ${m.n}';
  }

  final used = <String>{};
  _Mv take(List<_Mv> pool) {
    final m = pool[pick(pool, used)];
    used.add(m.n);
    return m;
  }

  String short(_Mv m) => m.n.replaceAll(
    RegExp(r'\s\d+(?:[.,]\d+)?(?:×\d+)?\s*(kg|m|cal)\b.*$'),
    '',
  );
  String join(List<_Mv> ms) {
    final names = [for (final m in ms) short(m)];
    if (names.length == 1) return names.first;
    return '${names.sublist(0, names.length - 1).join(', ')} & ${names.last}';
  }

  final note = _scaling[r.nextInt(_scaling.length)];
  switch (family) {
    case 0: // couplet + distance, rounds for time
      final a = take(_pull2), b = take(_push2), d = take(_dist2);
      final n = 3 + r.nextInt(3) + (tier >= 6 ? 1 : 0);
      return Wod(
        id: id,
        name: '$n rounds · ${join([a, b])} + ${d.n}',
        type: 'rounds',
        rounds: n,
        restSec: tier <= 3 ? 60 : 0,
        source: 'kalis',
        lines: [line(a), line(b), d.n],
        notes: 'Couplet suivi d\u2019une distance à chaque round. $note',
      );
    case 1: // triplet, rounds for time
      final a = take(_push2), b = take(_legs2), c = take(_core2);
      final n = 4 + r.nextInt(3);
      return Wod(
        id: id,
        name: '$n rounds · ${join([a, b, c])}',
        type: 'rounds',
        rounds: n,
        restSec: tier <= 4 ? 45 : 0,
        source: 'kalis',
        lines: [line(a), line(b), line(c)],
        notes: 'Triplet poussée / jambes / gainage. $note',
      );
    case 2: // chipper décroissant
      final pool = [
        take(_meta2),
        take(_legs2),
        take(_push2),
        take(_pull2),
        take(_core2),
        take(_meta2),
      ];
      final mults = [3.0, 2.5, 2.0, 1.6, 1.4, 1.0];
      final lines = [
        for (var k = 0; k < pool.length; k++) line(pool[k], mults[k]),
      ];
      var total = 0;
      for (var k = 0; k < pool.length; k++) {
        total += reps(pool[k], mults[k]);
      }
      return Wod(
        id: id,
        name:
            'Chipper $total reps · ${short(pool.first)} → ${short(pool.last)}',
        type: 'fortime',
        minutes: 15 + tier * 2,
        source: 'kalis',
        lines: lines,
        notes:
            'Chaque mouvement une seule fois, dans l\u2019ordre, reps décroissantes. $note',
      );
    case 3: // échelle décroissante
      final scheme =
          _descSchemes[min(_descSchemes.length - 1, (tier - 1) ~/ 2)];
      final pool = [
        take(_pull2),
        take(_push2),
        if (tier >= 4) take(_meta2) else take(_legs2),
      ];
      return Wod(
        id: id,
        name: '$scheme · ${join(pool)}',
        type: 'fortime',
        scheme: scheme,
        source: 'kalis',
        lines: [for (final m in pool) m.n],
        notes:
            'Schéma $scheme de chaque mouvement, enchaîné sans repos imposé. $note',
      );
    case 4: // échelle croissante
      final scheme = _ascSchemes[min(_ascSchemes.length - 1, (tier - 1) ~/ 3)];
      final a = take(tier >= 6 ? _skill2 : _pull2), b = take(_push2);
      return Wod(
        id: id,
        name: 'Échelle ${scheme.replaceAll('-…-', ' → ')} · ${join([a, b])}',
        type: 'fortime',
        scheme: scheme,
        source: 'kalis',
        lines: [a.n, b.n],
        notes:
            'Échelle montante : chaque barreau ajoute des reps aux deux mouvements. $note',
      );
    case 5: // AMRAP
      final minutes = 8 + 2 * r.nextInt(5) + (tier >= 6 ? 4 : 0);
      final pool = [
        take(_meta2),
        take(_push2),
        take(_legs2),
        if (tier >= 3) take(_pull2),
      ];
      return Wod(
        id: id,
        name: 'AMRAP $minutes · ${join(pool)}',
        type: 'amrap',
        minutes: minutes,
        source: 'kalis',
        lines: [for (final m in pool) line(m, 0.6)],
        notes:
            'Score = rounds + reps. Rythme tenable dès le premier round. $note',
      );
    case 6: // blocs d'AMRAP avec repos
      const blocks = 3;
      final base = 3 + r.nextInt(2);
      final pool = [take(_meta2), take(_legs2), take(_push2)];
      final lines = <String>[];
      for (var k = 0; k < blocks; k++) {
        final mins = base + k;
        lines.add(
          'AMRAP $mins min : ${[for (final m in pool) line(m, 0.35 + 0.1 * k)].join(' · ')}',
        );
        if (k < blocks - 1) lines.add('Repos 2 min');
      }
      return Wod(
        id: id,
        name: '$blocks × AMRAP $base-${base + 1}-${base + 2} · ${join(pool)}',
        type: 'routine',
        restSec: 120,
        source: 'kalis',
        lines: lines,
        notes:
            'Reprends chaque bloc où tu t\u2019es arrêté ; score = total des rounds. $note',
      );
    case 7: // EMOM en rotation
      final rounds = 12 + 3 * r.nextInt(3) + (tier >= 7 ? 3 : 0);
      final pool = [take(_pull2), take(_push2), take(_legs2)];
      return Wod(
        id: id,
        name: 'EMOM $rounds · ${join(pool)}',
        type: 'emom',
        rounds: rounds,
        interval: 60,
        source: 'kalis',
        lines: [
          for (var k = 0; k < pool.length; k++)
            'min ${k + 1}, ${k + 4}, ${k + 7}… : ${line(pool[k], 0.5)}',
        ],
        notes:
            'Un mouvement par minute, en rotation. Si une minute déborde, réduis de 2 reps. $note',
      );
    case 8: // EMOM par blocs de 5 minutes
      final pool = [take(_meta2), take(_push2), take(_pull2)];
      return Wod(
        id: id,
        name: 'EMOM 15 par blocs · ${join(pool)}',
        type: 'emom',
        rounds: 15,
        interval: 60,
        source: 'kalis',
        lines: [
          for (var k = 0; k < pool.length; k++)
            'min ${5 * k + 1}-${5 * k + 5} : ${line(pool[k], 0.45)}',
        ],
        notes: 'Trois blocs de cinq minutes, un mouvement par bloc. $note',
      );
    case 9: // force lestée puis metcon
      final heavy = take(
        tier >= 5
            ? [_pull2[5], _push2[6], _pull2[7], _push2[8]]
            : [_pull2[1], _push2[3], _pull2[2]],
      );
      final pool = [take(_meta2), take(_push2), take(_legs2)];
      final sets = 4 + (tier >= 6 ? 2 : 1);
      final amrap = 6 + 2 * r.nextInt(3);
      return Wod(
        id: id,
        name: 'Force + metcon · ${short(heavy)} puis AMRAP $amrap',
        type: 'routine',
        restSec: 120,
        source: 'kalis',
        lines: [
          '$sets × (${line(heavy, 0.6)}) · départ toutes les 2 min',
          'Repos 2 min',
          'AMRAP $amrap min : ${[for (final m in pool) line(m, 0.5)].join(' · ')}',
        ],
        notes:
            'Bloc de force lourd et propre, puis metcon léger et rapide. $note',
      );
    case 10: // Tabata
      final pool = [
        take(_push2),
        take(_legs2),
        take(_core2),
        if (tier >= 5) take(_meta2),
      ];
      return Wod(
        id: id,
        name: 'Tabata × ${pool.length} · ${join(pool)}',
        type: 'routine',
        restSec: 60,
        source: 'kalis',
        lines: [
          for (final m in pool) '8 × (max ${m.n} en 20 s) · 10 s de repos',
        ],
        notes:
            'Un Tabata par mouvement, 1 min de repos entre deux. Score = reps du plus faible intervalle, par mouvement. $note',
      );
    default: // Death by
      final m = take(
        tier >= 6
            ? [_meta2[1], _pull2[1], _push2[3], _meta2[5]]
            : [_meta2[1], _push2[0], _legs2[0], _meta2[2]],
      );
      final step = tier >= 7 ? 2 : 1;
      final rounds = 12 + 3 * r.nextInt(3);
      String block(int from, int to) =>
          'min $from-$to : ${((from + to) ~/ 2) * step} ${m.n}';
      final third = rounds ~/ 3;
      return Wod(
        id: id,
        name: 'Death by · ${short(m)}${step > 1 ? ' (+2 / min)' : ''}',
        type: 'emom',
        rounds: rounds,
        interval: 60,
        source: 'kalis',
        lines: [
          block(1, third),
          block(third + 1, 2 * third),
          block(2 * third + 1, rounds),
        ],
        notes:
            'Minute 1 : $step rep${step > 1 ? 's' : ''}, puis +$step par minute jusqu\u2019à ne plus tenir l\u2019intervalle. Score = dernière minute réussie. $note',
      );
  }
}
