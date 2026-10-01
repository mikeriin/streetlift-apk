// G2 (dev6.1.0, D1.1 et D1.2) : annonce de la suppression des WOD, des
// séances perso et de « Mes progrès », et accès à la copie complète faite
// avant (stockée dans l'application, partageable par le menu Android ou
// enregistrable dans un fichier). Écran sobre, montré une fois au premier
// lancement, puis retrouvable dans Réglages › Sauvegardes.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'backup_files.dart';
import 'retired_data.dart';
import 'session_prefs.dart';
import 'store.dart';
import 'ui.dart';

/// Partage de la copie par le menu Android (fichier temporaire unique du
/// cache, servi en lecture seule par `ShareProvider`).
class RetiredCopyShare {
  RetiredCopyShare._();
  static const _channel = MethodChannel('kalis_track/share');

  /// Tests : remplace l'appel natif (nom, texte).
  @visibleForTesting
  static Future<String> Function(String name, String text)? debugHook;

  /// `shared`, `unavailable`, `unsupported` ou `error`.
  static Future<String> share(String name, String text) async {
    final hook = debugHook;
    if (hook != null) return hook(name, text);
    try {
      final r = await _channel.invokeMethod<String>('shareJson', {
        'name': name,
        'file': 'copie',
        'bytes': Uint8List.fromList(utf8.encode(text)),
      });
      return r ?? 'error';
    } on MissingPluginException {
      return 'unsupported';
    } on PlatformException {
      return 'error';
    }
  }
}

/// Ouvre l'annonce si la copie existe et que l'annonce n'a pas été lue.
Future<void> showRetiredNoticeIfNeeded(NavigatorState navigator) async {
  final notice = store.retiredNotice;
  if (notice == null || notice.seen) return;
  await navigator.push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const RetiredNoticeScreen(),
    ),
  );
}

class RetiredNoticeScreen extends StatelessWidget {
  /// Ouvert depuis Réglages › Sauvegardes : annonce déjà lue, bouton
  /// « Fermer » au lieu de « Compris ».
  final bool fromSettings;
  const RetiredNoticeScreen({super.key, this.fromSettings = false});

  static String _date(DateTime at) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(at.day)}/${two(at.month)}/${at.year} à ${two(at.hour)}:${two(at.minute)}';
  }

  static String _size(int bytes) => bytes < 1024 * 1024
      ? '${(bytes / 1024).ceil()} Ko'
      : '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} Mo';

  Future<void> _share(BuildContext context, RetiredNotice notice) async {
    final messenger = ScaffoldMessenger.of(context);
    final text = store.retiredCopy;
    if (text == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Copie illisible : rien n’a été partagé.')),
      );
      return;
    }
    final result = await RetiredCopyShare.share(
      notice.fileName(devSession: SessionSpace.isDev),
      text,
    );
    if (result == 'shared') return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result == 'unavailable'
              ? 'Aucune application ne peut recevoir la copie. Essaie « Enregistrer dans un fichier ».'
              : 'Partage impossible. Essaie « Enregistrer dans un fichier ».',
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context, RetiredNotice notice) async {
    final messenger = ScaffoldMessenger.of(context);
    final text = store.retiredCopy;
    if (text == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Copie illisible : aucun fichier enregistré.'),
        ),
      );
      return;
    }
    final result = await backupFiles.save(
      notice.fileName(devSession: SessionSpace.isDev),
      Uint8List.fromList(utf8.encode(text)),
    );
    final message = switch (result.status) {
      FileSaveStatus.saved => 'Copie enregistrée : ${result.name ?? 'fichier'}.',
      FileSaveStatus.unverified =>
        'Copie écrite, mais sa relecture n’a pas été possible. Vérifie le fichier.',
      FileSaveStatus.cancelled => 'Enregistrement annulé.',
      FileSaveStatus.failed => 'Enregistrement impossible. Réessaie.',
    };
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final notice = store.retiredNotice;
    final text = Theme.of(context).textTheme;
    void close() {
      if (!fromSettings) store.markRetiredNoticeSeen();
      Navigator.of(context).maybePop();
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !fromSettings) store.markRetiredNoticeSeen();
      },
      child: KScreen(
        appBar: AppBar(
          title: Text(fromSettings ? 'Copie de sécurité' : 'Mise à jour'),
        ),
        body: KList(
          key: const ValueKey('retired-notice'),
          children: [
            Text(
              'WOD et séances perso retirés',
              style: text.headlineSmall,
            ),
            const Text(
              'Kalis Track se recentre sur ton programme. L’onglet WOD, le '
              'créateur de séances et « Mes progrès » ont été retirés.',
            ),
            if (notice == null)
              const KCard(
                child: Text(
                  'Aucune copie dans cette session : il n’y avait ni WOD, ni '
                  'séance perso, ni crédit à supprimer.',
                ),
              )
            else ...[
              const KSection('Supprimé de l’application', topPadding: 4),
              KCard(
                key: const ValueKey('retired-notice-deleted'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final line in notice.summary.lines)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('•  '),
                            Expanded(child: Text(line)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Text(
                'Ne change pas : ton programme, l’historique de ses séances, '
                'tes records, tes références, tes réglages et ton profil. Ton '
                'niveau peut baisser : les WOD et les séances perso ne '
                'rapportent plus d’XP.',
              ),
              const KSection('Ta copie de sécurité', topPadding: 4),
              KCard(
                key: const ValueKey('retired-notice-copy'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified_rounded, color: SL.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Copie complète vérifiée',
                            style: text.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Faite le ${_date(notice.at)} (${_size(notice.bytes)}), '
                      'avant toute suppression. Elle est gardée dans '
                      'l’application et se retrouve dans Réglages › '
                      'Sauvegardes. Elle contient toutes tes données d’avant '
                      'la mise à jour et s’importe dans la version '
                      'précédente.',
                    ),
                  ],
                ),
              ),
              KActionRow(
                children: [
                  FilledButton.icon(
                    key: const ValueKey('retired-notice-share'),
                    onPressed: () => _share(context, notice),
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('Partager la copie'),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey('retired-notice-save'),
                    onPressed: () => _save(context, notice),
                    icon: const Icon(Icons.save_alt_rounded),
                    label: const Text('Enregistrer dans un fichier'),
                  ),
                ],
              ),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const ValueKey('retired-notice-close'),
                onPressed: close,
                child: Text(fromSettings ? 'Fermer' : 'Compris'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
