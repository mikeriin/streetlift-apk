import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

const _device = MethodChannel('kalis_track/device');

Future<String?> deviceTimeZoneName() =>
    _device.invokeMethod<String>('timeZoneName');

Future<bool> openDeviceSettings(String page) async {
  try {
    return await _device.invokeMethod<bool>('openSettings', {'page': page}) ??
        false;
  } catch (_) {
    return false;
  }
}

Future<void> enableHighRefreshRate() async {
  try {
    await _device.invokeMethod<void>('highRefreshRate');
  } catch (_) {
    // Appareil non Android ou mode non disponible : cadence système conservée.
  }
}

Future<void> keepAwake(bool enabled) async {
  try {
    await WakelockPlus.toggle(enable: enabled);
  } catch (_) {}
}

/// M1 (moteur 3D) : capacités graphiques de l'appareil, lues par l'écran
/// Moteur 3D. Vide hors Android ou si la lecture échoue.
Future<Map<String, Object?>> graphicsInfo() async {
  try {
    final raw = await _device.invokeMethod<Map<Object?, Object?>>(
      'graphicsInfo',
    );
    return {for (final e in (raw ?? const {}).entries) '${e.key}': e.value};
  } catch (_) {
    return const {};
  }
}
