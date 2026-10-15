// Contrats de sauvegarde L2 : résultats d'achat et d'import, limites d'import
// et décompression bornée. Aucun stockage ici : le store garde sa clé unique.

import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:typed_data';

/// Résultat d'un achat de WOD, connu seulement après l'écriture (KT-002).
enum PurchaseStatus {
  /// Débit et droit enregistrés : l'écriture a été acceptée.
  success,

  /// Déjà possédé : aucun débit.
  alreadyOwned,

  /// Un achat du même WOD est déjà en cours : aucun second débit.
  pending,

  /// Solde insuffisant au moment de l'achat : aucun débit.
  insufficientCredits,

  /// Le prix a changé depuis l'offre affichée : aucun débit.
  priceChanged,

  /// Écriture refusée : aucun débit, droit non accordé.
  failed,
}

class PurchaseResult {
  final PurchaseStatus status;

  /// Prix de l'offre au moment de la décision (payé si [status] = success).
  final int? cost;
  const PurchaseResult(this.status, {this.cost});

  /// Le WOD est possédé à l'issue de l'opération.
  bool get owned =>
      status == PurchaseStatus.success || status == PurchaseStatus.alreadyOwned;
}

/// Validation d'un score de WOD (KT-003).
enum ResultSave {
  /// Résultat enregistré et écriture acceptée.
  saved,

  /// Résultat gardé en mémoire mais écriture refusée : à réessayer.
  unsaved,

  /// Ni WOD jouable, ni tentative autorisée ouverte : rien d'enregistré.
  denied,
}

/// Résultat d'un import (KT-013 / KT-015).
/// Départ du programme (KT-006) : `saved` seulement une fois écrit.
enum StartSave { saved, unsaved, outOfRange, invalid }

enum ImportStatus {
  success,

  /// Structure, types ou valeurs invalides : rien n'est modifié.
  invalid,

  /// Une limite d'import est dépassée : rien n'est modifié.
  tooLarge,

  /// La copie de récupération ou la nouvelle sauvegarde n'a pas été écrite :
  /// l'état courant est conservé.
  writeFailed,

  /// Les données locales ont changé depuis l'aperçu confirmé : rien n'est
  /// modifié, une nouvelle confirmation est nécessaire (L2b).
  conflict,
}

/// Résultat d'une suppression des données de l'application (L2b).
enum EraseStatus {
  /// Données remplacées par un état neuf et toutes les autres clés retirées.
  success,

  /// État neuf écrit, mais des clés n'ont pas pu être retirées : à relancer.
  partial,

  /// Rien n'a été supprimé : l'état neuf n'a pas pu être écrit.
  failed,
}

class EraseResult {
  final EraseStatus status;

  /// Clés de stockage encore présentes (hors état neuf), jamais leur contenu.
  final List<String> remaining;
  const EraseResult(this.status, {this.remaining = const []});
}

/// Limites d'import. Une sauvegarde représentative (40 semaines du
/// programme entièrement saisies, 60 séances perso, 300 résultats de WOD)
/// pèse 1 037 555 octets de JSON et 71 374 valeurs (mesure de
/// `test/l2_persistence_test.dart`) : chaque limite laisse au moins un
/// facteur 10 de marge, sans permettre une expansion démesurée.
class ImportLimits {
  /// Caractères du texte collé (JSON brut ou « gz: » + base64).
  final int maxInputChars;

  /// Octets produits par la décompression, vérifiés pendant le flux.
  final int maxJsonBytes;

  /// Valeurs JSON (objets, listes, textes, nombres…), comptées au décodage.
  final int maxNodes;

  /// Longueur d'un texte isolé (note, nom, ligne de WOD…).
  final int maxStringChars;

  /// Entrées du journal (séances du programme, perso et archives).
  final int maxLogs;

  /// Séries au total, toutes séances confondues.
  final int maxSets;

  /// Résultats de WOD au total.
  final int maxResults;

  /// Séances perso, exercices perso, WOD perso, droits, envies : chacun.
  final int maxEntries;

  const ImportLimits({
    this.maxInputChars = 8 * 1024 * 1024,
    this.maxJsonBytes = 32 * 1024 * 1024,
    this.maxNodes = 2000000,
    this.maxStringChars = 100000,
    this.maxLogs = 20000,
    this.maxSets = 500000,
    this.maxResults = 100000,
    this.maxEntries = 20000,
  });

  static const standard = ImportLimits();
}

/// Limite d'import dépassée ; le message reste compréhensible tel quel.
class ImportLimitException implements Exception {
  final String message;
  const ImportLimitException(this.message);
  @override
  String toString() => message;
}

/// Tampon d'octets qui refuse de dépasser [limit] pendant la décompression.
class _LimitedBytes implements Sink<List<int>> {
  _LimitedBytes(this.limit);
  final int limit;
  final BytesBuilder bytes = BytesBuilder();

  @override
  void add(List<int> chunk) {
    if (bytes.length + chunk.length > limit) {
      throw const ImportLimitException(
        'Sauvegarde trop volumineuse une fois décompressée.',
      );
    }
    bytes.add(chunk);
  }

  @override
  void close() {}
}

/// Texte JSON d'une sauvegarde collée, décompressée par morceaux : la taille
/// produite est contrôlée pendant le flux, pas après coup.
String boundedUnpack(String raw, ImportLimits limits) {
  final text = raw.trim();
  if (text.length > limits.maxInputChars) {
    throw const ImportLimitException('Texte de sauvegarde trop volumineux.');
  }
  if (!text.startsWith('gz:')) {
    if (text.length > limits.maxJsonBytes) {
      throw const ImportLimitException('Sauvegarde trop volumineuse.');
    }
    return text;
  }
  final compressed = base64Decode(text.substring(3));
  final output = _LimitedBytes(limits.maxJsonBytes);
  final input = gzip.decoder.startChunkedConversion(output);
  const step = 16 * 1024;
  try {
    for (var i = 0; i < compressed.length; i += step) {
      final end = i + step < compressed.length ? i + step : compressed.length;
      input.add(Uint8List.sublistView(compressed, i, end));
    }
    input.close();
  } on ImportLimitException {
    rethrow;
  } catch (_) {
    throw const FormatException('Données compressées illisibles.');
  }
  return utf8.decode(output.bytes.takeBytes());
}

/// Décodage JSON qui compte les valeurs et la longueur des textes pendant
/// l'analyse.
Object? boundedJsonDecode(String text, ImportLimits limits) {
  var nodes = 0;
  return jsonDecode(
    text,
    reviver: (key, value) {
      if (++nodes > limits.maxNodes) {
        throw const ImportLimitException('Sauvegarde trop détaillée.');
      }
      if (value is String && value.length > limits.maxStringChars) {
        throw const ImportLimitException('Texte trop long dans la sauvegarde.');
      }
      return value;
    },
  );
}
