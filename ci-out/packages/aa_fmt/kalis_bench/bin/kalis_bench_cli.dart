// Entrée du rapport sur la branche de contrôle (mise au point du lot KM1,
// jamais sur moteurs) : n'écrit que les exports KM1.
import 'common.dart';
import 'km_common.dart';

Future<void> main(List<String> args) async {
  final outPath = option(args, '--rapport');
  if (outPath == null) {
    return;
  }
  await runKm1(outPath: '$outPath/km1');
}
