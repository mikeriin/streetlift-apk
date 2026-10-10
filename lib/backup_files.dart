// Fichiers de sauvegarde (L2b) : sélecteur système Android, sans permission
// de stockage. Un succès n'est annoncé qu'après écriture ET relecture
// identique côté natif. Le contenu n'est jamais journalisé.

import 'package:flutter/services.dart';

enum FileSaveStatus {
  /// Écrit puis relu à l'identique.
  saved,

  /// Écrit, mais la relecture n'a pas été possible : non confirmé.
  unverified,

  /// Sélecteur fermé sans choix : aucun fichier créé.
  cancelled,

  /// Échec (voir [FileSaveResult.error]).
  failed,
}

class FileSaveResult {
  final FileSaveStatus status;
  final String? name;
  final int? bytes;

  /// `denied`, `unavailable`, `io`, `partial`, `interrupted`, `busy`,
  /// `noPicker`, `unsupported`.
  final String? error;

  /// Fichier incomplet supprimé après un échec.
  final bool deleted;
  const FileSaveResult(
    this.status, {
    this.name,
    this.bytes,
    this.error,
    this.deleted = false,
  });
}

enum FileOpenStatus { opened, cancelled, tooLarge, failed }

class FileOpenResult {
  final FileOpenStatus status;
  final Uint8List? bytes;
  final String? name;

  /// Taille annoncée par le fournisseur : indicative, jamais utilisée seule.
  final int? declaredSize;
  final String? error;
  const FileOpenResult(
    this.status, {
    this.bytes,
    this.name,
    this.declaredSize,
    this.error,
  });
}

abstract class BackupFiles {
  /// Propose [name] dans le sélecteur système puis écrit [bytes].
  Future<FileSaveResult> save(String name, Uint8List bytes);

  /// Ouvre un fichier choisi ; au-delà de [maxBytes], lecture interrompue.
  Future<FileOpenResult> open(int maxBytes);
}

class PlatformBackupFiles implements BackupFiles {
  static const _channel = MethodChannel('kalis_track/backup_files');

  @override
  Future<FileSaveResult> save(String name, Uint8List bytes) async {
    try {
      final r = await _channel.invokeMapMethod<String, Object?>(
        'createDocument',
        {'name': name, 'bytes': bytes},
      );
      final status = r?['status'];
      final saved = r?['bytes'] as int?;
      final shown = r?['name'] as String?;
      return switch (status) {
        'saved' => FileSaveResult(
          FileSaveStatus.saved,
          name: shown ?? name,
          bytes: saved,
        ),
        'unverified' => FileSaveResult(
          FileSaveStatus.unverified,
          name: shown ?? name,
          bytes: saved,
        ),
        'cancelled' => const FileSaveResult(FileSaveStatus.cancelled),
        _ => FileSaveResult(
          FileSaveStatus.failed,
          name: shown,
          error: r?['code'] as String? ?? 'io',
          deleted: r?['deleted'] == true,
        ),
      };
    } on MissingPluginException {
      return const FileSaveResult(FileSaveStatus.failed, error: 'unsupported');
    } on PlatformException {
      return const FileSaveResult(FileSaveStatus.failed, error: 'io');
    }
  }

  @override
  Future<FileOpenResult> open(int maxBytes) async {
    try {
      final r = await _channel.invokeMapMethod<String, Object?>(
        'openDocument',
        {'maxBytes': maxBytes},
      );
      final name = r?['name'] as String?;
      final size = r?['declaredSize'] as int?;
      return switch (r?['status']) {
        'opened' => FileOpenResult(
          FileOpenStatus.opened,
          bytes: r?['bytes'] as Uint8List?,
          name: name,
          declaredSize: size,
        ),
        'cancelled' => const FileOpenResult(FileOpenStatus.cancelled),
        'tooLarge' => FileOpenResult(
          FileOpenStatus.tooLarge,
          name: name,
          declaredSize: size,
        ),
        _ => FileOpenResult(
          FileOpenStatus.failed,
          name: name,
          error: r?['code'] as String? ?? 'io',
        ),
      };
    } on MissingPluginException {
      return const FileOpenResult(FileOpenStatus.failed, error: 'unsupported');
    } on PlatformException {
      return const FileOpenResult(FileOpenStatus.failed, error: 'io');
    }
  }
}

/// Remplaçable par les tests (sélecteur simulé).
BackupFiles backupFiles = PlatformBackupFiles();

/// Nom proposé : daté, identifiable, sans nom ni donnée sportive. G1 :
/// [test] = export d'une session de test (mode dev), nommé comme tel.
String backupFileName(DateTime at, {bool test = false}) {
  String two(int v) => v.toString().padLeft(2, '0');
  final kind = test ? 'session-de-test' : 'sauvegarde';
  return 'kalis-track-$kind-${at.year}-${two(at.month)}-${two(at.day)}'
      '-${two(at.hour)}${two(at.minute)}.json';
}
