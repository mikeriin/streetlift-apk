import 'dart:io';

Future<void> main(List<String> args) async {
  final i = args.indexOf('--rapport');
  final rapport = i >= 0 ? args[i + 1] : 'rapport';
  Directory(rapport).createSync(recursive: true);
  final p = await Process.start('bash', ['run.sh', rapport]);
  await stdout.addStream(p.stdout);
  await stderr.addStream(p.stderr);
  final code = await p.exitCode;
  stdout.writeln('run.sh : $code');
}
