// Outil de mise au point (branche de contrôle seulement) : formate les
// paquets voisins sur place, puis recopie leurs sources Dart dans le
// dossier du rapport pour que la session les récupère formatées.
import 'dart:io';

void main(List<String> args) {
  final at = args.indexOf('--rapport');
  if (at < 0 || at + 1 >= args.length) {
    exitCode = 64;
    return;
  }
  final out = args[at + 1];
  final packages = <String>[
    for (final d in Directory('..').listSync())
      if (d is Directory &&
          !d.path.endsWith('aa_fmt') &&
          File('${d.path}/pubspec.yaml').existsSync())
        d.path,
  ]..sort();
  final result = Process.runSync('dart', <String>['format', ...packages]);
  File('$out/format.txt')
    ..createSync(recursive: true)
    ..writeAsStringSync('${result.stdout}\n${result.stderr}');
  for (final p in packages) {
    final name = p.split('/').last;
    for (final f in Directory(p).listSync(recursive: true)) {
      if (f is! File ||
          !f.path.endsWith('.dart') ||
          f.path.contains('/.dart_tool/') ||
          f.path.endsWith('.g.dart')) {
        continue;
      }
      final rel = f.path.substring(p.length + 1);
      final target = File('$out/$name/$rel')..createSync(recursive: true);
      target.writeAsStringSync(f.readAsStringSync());
    }
  }
}
