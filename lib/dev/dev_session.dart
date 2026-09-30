// G1 (D2.1 à D2.3, D2.5) : session de test du mode dev.
//
// Une seule session de test à la fois, décrite par la clé de contrôle
// [SessionSpace.controlKey] (marqueur, date de création réelle, décalage
// d'horloge en jours). Elle survit à la fermeture de l'application jusqu'à
// sa suppression. Ses données vivent sous [SessionSpace.devPrefix]
// (session_prefs.dart) ; la supprimer retire toutes ces clés, la clé de
// contrôle et le fichier d'export partagé. Rien de tout cela n'existe hors
// build de développement (kDevBuild).

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../kalis_clock.dart';
import '../session_prefs.dart';
import 'dev_flags.dart';

/// Couleur du logo pendant la session de test (D2.1), et nulle part
/// ailleurs.
const kDevPink = Color(0xFFFF1493);

/// Marqueur de la clé de contrôle (présent seulement dans le code du mode
/// dev : sert aussi à prouver son absence de l'AAB).
const kDevMarker = 'KALIS-DEV-SESSION-7F3A';

class DevSession {
  DevSession._();

  /// Session de test active (logo rose, étiquette DEV).
  static final active = ValueNotifier<bool>(false);

  static DateTime? _createdAt;

  /// Date réelle de création de la session de test.
  static DateTime? get createdAt => _createdAt;

  /// Lit la clé de contrôle au démarrage : session de test active ou non.
  static Future<void> load() async {
    if (!kDevBuild) return;
    _apply(_read(await SharedPreferences.getInstance()));
  }

  static Map<String, Object?>? _read(SharedPreferences raw) {
    final text = raw.getString(SessionSpace.controlKey);
    if (text == null) return null;
    try {
      final map = Map<String, Object?>.from(jsonDecode(text) as Map);
      return map['marker'] == kDevMarker ? map : null;
    } catch (_) {
      return null;
    }
  }

  static void _apply(Map<String, Object?>? control) {
    final on = kDevBuild && control != null;
    SessionSpace.devActive = on;
    final days = control?['offsetDays'];
    KalisClock.setOffsetDays(on && days is int ? days : 0);
    _createdAt = on
        ? DateTime.tryParse('${control?['createdAt'] ?? ''}')
        : null;
    active.value = on;
  }

  static Future<bool> _write(
    SharedPreferences raw,
    Map<String, Object?> control,
  ) => raw.setString(SessionSpace.controlKey, jsonEncode(control));

  /// Crée une session de test vierge (installation neuve) et l'active.
  /// Sans effet si une session de test existe déjà.
  static Future<void> create() async {
    if (!kDevBuild) return;
    final raw = await SharedPreferences.getInstance();
    if (_read(raw) != null) {
      _apply(_read(raw));
      return;
    }
    // Restes d'une suppression interrompue : la nouvelle session est vierge.
    for (final key in raw.getKeys().toList()) {
      if (key.startsWith(SessionSpace.devPrefix)) await raw.remove(key);
    }
    final control = <String, Object?>{
      'marker': kDevMarker,
      'createdAt': KalisClock.realNow().toIso8601String(),
      'offsetDays': 0,
    };
    if (!await _write(raw, control)) {
      throw StateError('Session de test : écriture refusée');
    }
    _apply(control);
  }

  /// Supprime la session de test : toutes ses clés, la clé de contrôle et
  /// le fichier d'export partagé. Renvoie les clés qui n'ont pas pu être
  /// retirées (vide en cas de succès).
  static Future<List<String>> destroy() async {
    if (!kDevBuild) return const [];
    final raw = await SharedPreferences.getInstance();
    final remaining = <String>[];
    for (final key in raw.getKeys().toList()) {
      if (!SessionSpace.reserved(key)) continue;
      try {
        await raw.remove(key);
      } catch (_) {}
      if (raw.containsKey(key)) remaining.add(key);
    }
    await DevShare.clear();
    _apply(null);
    return remaining;
  }

  /// Voyage dans le temps : décalage de l'horloge de la session de test,
  /// en jours civils (0 = aujourd'hui).
  static Future<void> setOffsetDays(int days) async {
    if (!kDevBuild) return;
    final raw = await SharedPreferences.getInstance();
    final control = _read(raw);
    if (control == null) return;
    control['offsetDays'] = days;
    await _write(raw, control);
    _apply(control);
  }
}

/// Export JSON de la session de test par le menu de partage Android
/// (fichier temporaire unique du cache, servi en lecture seule).
class DevShare {
  DevShare._();
  static const _channel = MethodChannel('kalis_track/share');

  /// Tests : remplace l'appel natif (nom, texte ; null = suppression).
  @visibleForTesting
  static Future<String> Function(String? name, String? text)? debugHook;

  static Future<String> shareJson(String name, String text) async {
    final hook = debugHook;
    if (hook != null) return hook(name, text);
    try {
      final r = await _channel.invokeMethod<String>('shareJson', {
        'name': name,
        'bytes': Uint8List.fromList(utf8.encode(text)),
      });
      return r ?? 'error';
    } on MissingPluginException {
      return 'unsupported';
    } on PlatformException {
      return 'error';
    }
  }

  /// Supprime le fichier d'export partagé (suppression de la session).
  static Future<void> clear() async {
    final hook = debugHook;
    if (hook != null) {
      await hook(null, null);
      return;
    }
    try {
      await _channel.invokeMethod<String>('clearJson');
    } catch (_) {}
  }
}
