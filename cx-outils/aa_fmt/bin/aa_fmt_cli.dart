// Outil de mise au point du lot CX (branche de contrôle seulement, jamais
// sur moteurs) : copie les paquets voisins dans le dossier du rapport et
// les formate là, sans toucher aux paquets contrôlés ensuite par la CI
// (leur contrôle de formatage reste celui de la CI). La session récupère
// les sources formatées dans ci-out.
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
  final copies = <String>[];
  for (final p in packages) {
    final name = p.split('/').last;
    for (final f in Directory(p).listSync(recursive: true)) {
      if (f is! File ||
          !f.path.endsWith('.dart') ||
          f.path.contains('/.dart_tool/')) {
        continue;
      }
      final rel = f.path.substring(p.length + 1);
      File('$out/$name/$rel')
        ..createSync(recursive: true)
        ..writeAsBytesSync(f.readAsBytesSync());
    }
    copies.add('$out/$name');
  }
  final result = Process.runSync('dart', <String>[
    'format',
    '--language-version=3.10',
    ...copies,
  ]);
  File('$out/format.txt')
    ..createSync(recursive: true)
    ..writeAsStringSync('${result.stdout}\n${result.stderr}');
}
