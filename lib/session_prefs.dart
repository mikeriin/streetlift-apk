// G1 (D2.3) : isolation des données de la session de test.
//
// Toutes les données persistées de l'application passent par [KalisPrefs],
// vue de SharedPreferences liée à l'espace de la session active au moment
// de sa création :
// - session personnelle : clés d'origine, inchangées (aucune migration,
//   aucune donnée déplacée) ; les clés de la session de test sont
//   invisibles (ni lues, ni exportées, ni effacées) ;
// - session de test : clés préfixées par [SessionSpace.devPrefix] ; les
//   clés personnelles sont invisibles.
// Une vue ne change jamais d'espace : un magasin créé pour une session
// n'écrit que dans la sienne, même si une écriture tardive arrive après le
// changement de session. L'application ne crée aucun autre fichier interne
// (sauvegardes par le sélecteur système, copies de récupération dans les
// préférences) ; le seul fichier du mode dev (export partagé, cache) est
// supprimé avec la session de test.

import 'package:shared_preferences/shared_preferences.dart';

import 'dev/dev_flags.dart';

class SessionSpace {
  SessionSpace._();

  /// Préfixe des clés de la session de test.
  static const devPrefix = 'kt_session_test::';

  /// Clé de contrôle (session de test active, décalage d'horloge) : hors
  /// des deux espaces.
  static const controlKey = 'kt_session_test_control_v1';

  static bool _dev = false;

  /// Session de test active (toujours faux hors build de développement).
  static bool get isDev => kDevBuild && _dev;

  /// Réservé à dev_session.dart.
  static set devActive(bool value) => _dev = kDevBuild && value;

  /// Clé qui n'appartient pas à la session personnelle.
  static bool reserved(String key) =>
      key.startsWith(devPrefix) || key == controlKey;
}

/// Vue de SharedPreferences limitée à un espace (personnel ou test).
class KalisPrefs {
  final SharedPreferences raw;

  /// Espace de la session de test.
  final bool dev;
  KalisPrefs(this.raw, {required this.dev});

  /// Vue de la session active.
  static Future<KalisPrefs> active() async => KalisPrefs(
    await SharedPreferences.getInstance(),
    dev: SessionSpace.isDev,
  );

  String _k(String key) {
    if (SessionSpace.reserved(key)) {
      throw ArgumentError.value(key, 'key', 'clé réservée au mode dev');
    }
    return dev ? '${SessionSpace.devPrefix}$key' : key;
  }

  /// Clés de l'espace (sans préfixe).
  Set<String> getKeys() {
    const p = SessionSpace.devPrefix;
    return {
      for (final k in raw.getKeys())
        if (dev && k.startsWith(p))
          k.substring(p.length)
        else if (!dev && !SessionSpace.reserved(k))
          k,
    };
  }

  bool containsKey(String key) => raw.containsKey(_k(key));
  Object? get(String key) => raw.get(_k(key));
  String? getString(String key) => raw.getString(_k(key));
  int? getInt(String key) => raw.getInt(_k(key));
  bool? getBool(String key) => raw.getBool(_k(key));
  double? getDouble(String key) => raw.getDouble(_k(key));
  List<String>? getStringList(String key) => raw.getStringList(_k(key));
  Future<bool> setString(String key, String value) =>
      raw.setString(_k(key), value);
  Future<bool> setInt(String key, int value) => raw.setInt(_k(key), value);
  Future<bool> setBool(String key, bool value) => raw.setBool(_k(key), value);
  Future<bool> setDouble(String key, double value) =>
      raw.setDouble(_k(key), value);
  Future<bool> setStringList(String key, List<String> value) =>
      raw.setStringList(_k(key), value);
  Future<bool> remove(String key) => raw.remove(_k(key));

  /// Copie de l'espace (clés sans préfixe → valeurs), pour la récupération
  /// après un échec de démarrage et les contrôles.
  Map<String, Object?> snapshot() => {
    for (final k in getKeys()) k: raw.get(_k(k)),
  };
}
