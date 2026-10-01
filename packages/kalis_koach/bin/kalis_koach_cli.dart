// Simulateur / inventaire de kalis_koach (lot GK).
//
// Usage : dart run bin/kalis_koach_cli.dart --rapport <dossier>
// Écrit dans <dossier> :
//   inventaire.json  poses, flammes, événements, raisons, messages
//   inventaire.txt   même contenu, lisible
//   cas_types.txt    répliques rendues pour des cas types
//   svg/             chaque pose et chaque flamme en SVG (depuis les
//                    commandes du paquet), pour contrôle visuel
import 'dart:convert';
import 'dart:io';

import 'package:kalis_koach/kalis_koach.dart';

/// Point d’entrée : `--rapport <dossier>`.
void main(List<String> args) {
  final i = args.indexOf('--rapport');
  if (i < 0 || i + 1 >= args.length) {
    stderr.writeln('Usage : kalis_koach_cli --rapport <dossier>');
    exitCode = 64;
    return;
  }
  final dir = Directory(args[i + 1])..createSync(recursive: true);
  final director = KoachDirector();
  const texts = KoachTexts();

  // Poses.
  final poses = <Map<String, Object?>>[];
  for (final p in KoachPose.values) {
    final a = p.art;
    final info = p.info;
    final ink = koachPathStats(a.ink);
    final paper = koachPathStats(a.paper);
    poses.add({
      'id': p.id,
      'sheet': info.sheet,
      'cell': [info.row + 1, info.col + 1],
      'emotion': info.emotion.name,
      'usages': [for (final u in info.usages) u.name],
      'eyes': info.eyesOpen ? 'open' : 'closed',
      'framing': info.framing.name,
      'gaze': info.gaze.name,
      'bubbleSide': info.bubbleSide.name,
      'bounds': [a.bounds.left, a.bounds.top, a.bounds.right, a.bounds.bottom],
      'ink': {
        'subpaths': ink.subpaths,
        'lines': ink.lines,
        'cubics': ink.cubics,
      },
      'paper': {
        'subpaths': paper.subpaths,
        'lines': paper.lines,
        'cubics': paper.cubics,
      },
      'eyeBoxes': [
        for (final e in a.eyeBoxes) [e.left, e.top, e.right, e.bottom],
      ],
      'ints': a.ink.length + a.paper.length + a.eyes.length,
    });
  }

  // Flammes.
  final flames = <Map<String, Object?>>[];
  for (var level = 1; level <= koachFlameLevels; level++) {
    final f = koachFlame(level);
    flames.add({
      'level': level,
      'label': koachFlameLabel(level),
      'tint': koachFlameTint(level),
      'bounds': [f.bounds.left, f.bounds.top, f.bounds.right, f.bounds.bottom],
      'ints': f.ink.length + f.outline.length + f.hollow.length,
    });
  }

  // Événements : nombre de variantes, poses, paramètres.
  final events = <Map<String, Object?>>[];
  for (final e in KoachEvent.values) {
    final r = director.ruleFor(e);
    if (r == null) {
      events.add({'event': e.name, 'rule': 'explication d’une réplique'});
      continue;
    }
    events.add({
      'event': e.name,
      'variants': r.messageKeys.length,
      'poses': [for (final p in r.poses) p.id],
      'params': r.params,
      'priority': r.priority,
      'actions': [for (final a in r.actions) a.kind.name],
      'why': r.whyKey,
    });
  }
  final reasons = [
    for (final r in director.reasons.entries)
      {
        'code': r.code,
        'proposals': r.proposalKeys.length,
        'applied': r.appliedKeys.length,
        'why': r.whyKey,
        'params': r.params,
        'poses': [for (final p in r.poses) p.id],
      },
  ];

  // Mesure du temps de choix d'une réplique (budget indicatif : 1 ms).
  final sw = Stopwatch()..start();
  var n = 0;
  for (var k = 0; k < 20000; k++) {
    final e = KoachEvent.values[k % KoachEvent.values.length];
    if (e == KoachEvent.why) continue;
    final line = director.lineFor(
      KoachCue(
        e,
        params: _sampleParams,
        reason: k.isEven ? 'deload' : null,
        occurrence: k,
      ),
    );
    texts.bubble(line);
    n++;
  }
  sw.stop();
  final perLineUs = sw.elapsedMicroseconds / n;

  final inventory = {
    'schema': kalisKoachSchema,
    'version': kalisKoachVersion,
    'commonFrame': [
      koachCommonFrame.left,
      koachCommonFrame.top,
      koachCommonFrame.right,
      koachCommonFrame.bottom,
    ],
    'poses': poses,
    'flames': flames,
    'events': events,
    'reasons': reasons,
    'messages': koachMessagesFr.length,
    'timing': {'linesRendered': n, 'microsecondsPerLine': perLineUs},
  };
  File('${dir.path}/inventaire.json').writeAsStringSync(
    '${const JsonEncoder.withIndent(' ').convert(inventory)}\n',
  );

  final txt = StringBuffer()
    ..writeln('kalis_koach $kalisKoachVersion — inventaire')
    ..writeln('Cadre commun : $koachCommonFrame')
    ..writeln()
    ..writeln('Poses (${poses.length}) :');
  for (final p in poses) {
    txt.writeln(
      '  ${p['id']}  ${p['sheet']}${(p['cell'] as List).join('.')}'
      '  ${p['emotion']}  yeux ${p['eyes']}  ${p['framing']}'
      '  regard ${p['gaze']}  bulle ${p['bubbleSide']}  ${p['ints']} entiers',
    );
  }
  txt
    ..writeln()
    ..writeln('Flammes : ${flames.length}');
  for (final f in flames) {
    txt.writeln(
      '  ${f['label']}  teinte ${(f['tint'] as double).toStringAsFixed(3)}'
      '  boîte ${f['bounds']}',
    );
  }
  txt
    ..writeln()
    ..writeln('Événements (${events.length}) :');
  for (final e in events) {
    txt.writeln(
      '  ${e['event']}: ${e['variants'] ?? '-'} variantes, '
      'poses ${e['poses'] ?? '-'}, paramètres ${e['params'] ?? '-'}',
    );
  }
  txt
    ..writeln()
    ..writeln('Raisons : ${director.reasons.codes.join(', ')}')
    ..writeln('Messages : ${koachMessagesFr.length}')
    ..writeln('Temps moyen par réplique : ${perLineUs.toStringAsFixed(2)} µs');
  File('${dir.path}/inventaire.txt').writeAsStringSync(txt.toString());

  File(
    '${dir.path}/cas_types.txt',
  ).writeAsStringSync(_casTypes(director, texts));

  final svg = Directory('${dir.path}/svg')..createSync(recursive: true);
  for (final p in KoachPose.values) {
    File('${svg.path}/${p.id}.svg').writeAsStringSync(_poseSvg(p));
  }
  for (var level = 1; level <= koachFlameLevels; level++) {
    final f = koachFlame(level);
    File('${svg.path}/flamme_$level.svg').writeAsStringSync(
      _svg(
        f.bounds.inflate(10),
        '<path fill="#141414" fill-rule="evenodd" d="${koachPathToSvg(f.ink)}"/>',
      ),
    );
  }
  stdout.writeln(
    'Rapport écrit dans ${dir.path} : ${poses.length} poses, '
    '${flames.length} flammes, ${events.length} événements, '
    '${perLineUs.toStringAsFixed(2)} µs par réplique.',
  );
}

const Map<String, String> _sampleParams = {
  'remaining': '3',
  'field': 'ton matériel',
  'weeks': '12',
  'exercise': 'Tractions australiennes',
  'replacement': 'Rowing à l’élastique',
  'minutes': '25',
  'done': '9',
  'planned': '14',
  'value': '12 répétitions',
  'feature': 'les objectifs',
};

String _casTypes(KoachDirector d, KoachTexts t) {
  final b = StringBuffer(
    'Cas types (relus) — kalis_koach $kalisKoachVersion\n\n',
  );
  void show(String title, KoachCue cue) {
    final line = d.lineFor(cue);
    b
      ..writeln('# $title')
      ..writeln(
        '  pose : ${line.pose.id} (bulle à ${line.pose.info.bubbleSide.name})',
      )
      ..writeln('  bulle : ${t.bubble(line)}')
      ..writeln(
        '  actions : ${[for (final a in line.actions) t.action(a)].join(' | ')}',
      );
    final why = d.explain(line);
    if (why != null) {
      b.writeln('  pourquoi (${why.pose.id}) : ${t.bubble(why)}');
    }
    b.writeln();
  }

  show('Premier lancement', const KoachCue(KoachEvent.welcome));
  show(
    'Profil, étape',
    const KoachCue(
      KoachEvent.profileStep,
      params: {'remaining': '4'},
      occurrence: 1,
    ),
  );
  show(
    'Profil à mettre à jour',
    const KoachCue(
      KoachEvent.profileUpdateNeeded,
      params: {'field': 'ton matériel'},
    ),
  );
  show(
    'Première passe du programme',
    const KoachCue(KoachEvent.programDraftReady, params: {'weeks': '12'}),
  );
  show(
    'Proposition : charge augmentée',
    const KoachCue(
      KoachEvent.proposalNew,
      reason: 'load_increased',
      params: {'exercise': 'Pompes'},
    ),
  );
  show(
    'Proposition : code inconnu (générique)',
    const KoachCue(KoachEvent.proposalNew, reason: 'code_futur'),
  );
  show(
    'Changement appliqué : séance raccourcie',
    const KoachCue(
      KoachEvent.changeApplied,
      reason: 'session_shortened',
      params: {'minutes': '20'},
    ),
  );
  show('Bilan santé : douleur', const KoachCue(KoachEvent.healthCheckPain));
  show(
    'Fin de séance écourtée',
    const KoachCue(
      KoachEvent.sessionEndPartial,
      params: {'done': '6', 'planned': '12'},
    ),
  );
  show(
    'Record',
    const KoachCue(
      KoachEvent.personalRecord,
      params: {'exercise': 'Dips', 'value': '15 répétitions'},
    ),
  );
  show('Erreur', const KoachCue(KoachEvent.error));
  show('Session de test', const KoachCue(KoachEvent.devSessionEnter));
  show(
    'Nouveauté',
    const KoachCue(
      KoachEvent.featureIntro,
      params: {'feature': 'les objectifs'},
    ),
  );
  b.writeln('# Variantes successives (fin de séance, occurrences 0 à 3)');
  for (var o = 0; o < 4; o++) {
    final line = d.lineFor(KoachCue(KoachEvent.sessionEndGood, occurrence: o));
    b.writeln('  $o : ${line.pose.id} — ${t.bubble(line)}');
  }
  return b.toString();
}

String _poseSvg(KoachPose p) {
  final a = p.art;
  final body = StringBuffer()
    ..write(
      '<path fill="#141414" fill-rule="evenodd" d="${koachPathToSvg(a.ink)}"/>',
    );
  if (a.paper.isNotEmpty) {
    body.write(
      '<path fill="#ffffff" fill-rule="evenodd" d="${koachPathToSvg(a.paper)}"/>',
    );
  }
  if (a.eyes.isNotEmpty) {
    body.write(
      '<path fill="#ffffff" fill-rule="evenodd" d="${koachPathToSvg(a.eyes)}"/>',
    );
  }
  return _svg(koachCommonFrame, body.toString());
}

String _svg(KoachBox box, String body) =>
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="${box.left} ${box.top} '
    '${box.width} ${box.height}" width="${box.width ~/ 4}" '
    'height="${box.height ~/ 4}"><rect x="${box.left}" y="${box.top}" '
    'width="${box.width}" height="${box.height}" fill="#ffffff"/>$body</svg>\n';
