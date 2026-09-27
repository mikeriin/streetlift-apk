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
