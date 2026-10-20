// L6 (KT-023) — Pilote de `flutter drive` : écrit les mesures renvoyées par
// l'application (tools/perf_device/integration_test/l6_device_test.dart)
// dans KALIS_DEVICE_OUT (par défaut build/), sous le nom KALIS_DEVICE_NAME.
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null) return;
    await writeResponseData(
      data,
      testOutputFilename: Platform.environment['KALIS_DEVICE_NAME'] ?? 'l6_device',
      destinationDirectory: Platform.environment['KALIS_DEVICE_OUT'] ?? 'build',
    );
  },
);
