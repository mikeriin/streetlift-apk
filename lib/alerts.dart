// Alertes sonores et haptiques partagées (fin de repos, fin de WOD, time cap).
// SystemSound.alert est muet sur Android : on joue nos propres sons embarqués.
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'store.dart';

final AudioPlayer _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

Future<void> _play(String asset) async {
  try {
    await _player.stop();
    await _player.play(AssetSource(asset), volume: 1.0);
  } catch (_) {}
}

void _vibrate() {
  HapticFeedback.heavyImpact();
  Future.delayed(const Duration(milliseconds: 250), HapticFeedback.heavyImpact);
  Future.delayed(const Duration(milliseconds: 500), HapticFeedback.heavyImpact);
}

/// Triple bip : fin de repos, transition d'intervalle, fin de tenue.
void alertBeep() {
  if (store.settings.sound) _play('sounds/beep.wav');
  if (store.settings.vibration) _vibrate();
}

/// Alarme longue : fin d'AMRAP / EMOM / WOD, time cap.
void alertAlarm() {
  if (store.settings.sound) _play('sounds/alarm.wav');
  if (store.settings.vibration) _vibrate();
}
