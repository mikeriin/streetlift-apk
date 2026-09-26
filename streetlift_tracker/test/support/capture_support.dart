// Outils des rendus Flutter de test (L5-C) : polices réelles du SDK et
// écriture PNG. Rendu d'un widget dans le moteur de test : ce n'est ni une
// capture de l'APK ni un essai sur téléphone (barres système, clavier natif
// et permissions ne sont pas représentés).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const captureEnabled = bool.fromEnvironment('KALIS_CAPTURE');
const captureDir = String.fromEnvironment(
  'KALIS_CAPTURE_DIR',
  defaultValue: 'validation/L5-C',
);

/// Charge Roboto et les icônes Material depuis le SDK Flutter.
Future<void> loadCaptureFonts() async {
  final sdk = Platform.environment['FLUTTER_ROOT'];
  if (sdk == null) return;
  final dir = Directory('$sdk/bin/cache/artifacts/material_fonts');
  final fonts = dir.listSync().whereType<File>().where(
    (f) => f.path.contains('Roboto-') && f.path.endsWith('.ttf'),
  );
  for (final family in ['Roboto', 'Ahem']) {
    final loader = FontLoader(family);
    for (final file in fonts) {
      loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    }
    await loader.load();
  }
  final icons = FontLoader('MaterialIcons')..addFont(
    Future.value(
      ByteData.sublistView(
        File('${dir.path}/MaterialIcons-Regular.otf').readAsBytesSync(),
      ),
    ),
  );
  await icons.load();
}

/// Précharge les images d'assets affichées (logo, muscles).
Future<void> precacheCaptureImages(WidgetTester tester) async {
  await tester.runAsync(() async {
    final context = tester.element(find.byType(MaterialApp).first);
    await Future.wait([
      precacheImage(const AssetImage('assets/icon/logo_mark.png'), context),
      for (final file in Directory('assets/muscles').listSync().whereType<File>())
        if (file.path.endsWith('.png'))
          precacheImage(AssetImage(file.path), context),
    ]);
  });
  await tester.pumpAndSettle();
}

/// Écrit le contenu de [boundary] en PNG (densité 2).
Future<void> savePng(WidgetTester tester, GlobalKey boundary, String name) async {
  final render =
      boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await render.toImage(pixelRatio: 2);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$captureDir/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(png!.buffer.asUint8List());
    image.dispose();
  });
}
