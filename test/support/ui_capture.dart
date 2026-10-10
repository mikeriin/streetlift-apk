// UI0 (refonte UI) : rendus de test avec les polices réelles — Barlow
// embarquée (assets/fonts) et icônes Material du SDK. Rendu dans le moteur
// de test, pas une capture de l'APK (le tour sur émulateur en fait).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

const uiCaptureEnabled = bool.fromEnvironment('KALIS_CAPTURE');
const uiCaptureDir = 'validation/UI';

Future<void> _load(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await loader.load();
}

/// Barlow (trois largeurs) et icônes Material.
Future<void> loadUiFonts() async {
  await _load('Barlow', [
    'assets/fonts/Barlow-Regular.ttf',
    'assets/fonts/Barlow-Medium.ttf',
    'assets/fonts/Barlow-SemiBold.ttf',
  ]);
  await _load('BarlowSemiCondensed', ['assets/fonts/BarlowSemiCondensed-SemiBold.ttf']);
  await _load('BarlowCondensed', [
    'assets/fonts/BarlowCondensed-Medium.ttf',
    'assets/fonts/BarlowCondensed-SemiBold.ttf',
  ]);
  var sdk = Platform.environment['FLUTTER_ROOT'];
  final exe = Platform.resolvedExecutable;
  if (sdk == null && exe.contains('/bin/cache/')) {
    sdk = exe.substring(0, exe.indexOf('/bin/cache/'));
  }
  if (sdk == null) return;
  final dir = '$sdk/bin/cache/artifacts/material_fonts';
  await _load('MaterialIcons', ['$dir/MaterialIcons-Regular.otf']);
  final roboto = Directory(dir)
      .listSync()
      .whereType<File>()
      .where((f) => f.path.contains('Roboto-') && f.path.endsWith('.ttf'))
      .map((f) => f.path)
      .toList();
  await _load('Roboto', roboto);
}

/// Écrit le contenu de [boundary] en PNG.
Future<void> saveUiPng(
  WidgetTester tester,
  GlobalKey boundary,
  String name, {
  double pixelRatio = 2,
}) async {
  final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await render.toImage(pixelRatio: pixelRatio);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$uiCaptureDir/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(png!.buffer.asUint8List());
    image.dispose();
  });
}
