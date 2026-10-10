// G2 (dev6.1.0, D1.1 et D1.2) : annonce de la suppression des WOD, des
// séances perso et de « Mes progrès », et accès à la copie complète faite
// avant (stockée dans l'application, partageable par le menu Android ou
// enregistrable dans un fichier). Écran sobre, montré une fois au premier
// lancement, puis retrouvable dans Réglages › Sauvegardes.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        const SnackBar(
          content: Text('Copie illisible : rien n’a été partagé.'),
        ),
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
      FileSaveStatus.saved =>
        'Copie enregistrée : ${result.name ?? 'fichier'}.',
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
    final k = KTokens.of(context);
    final body = KType.corps.copyWith(color: k.texte);
    void close() {
      if (!fromSettings) store.markRetiredNoticeSeen();
      Navigator.of(context).maybePop();
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !fromSettings) store.markRetiredNoticeSeen();
      },
      // UI4 (R3) : depuis les Réglages, le titre reprend le libellé de
      // l'entrée ; au premier lancement, l'annonce garde son titre.
      child: KPage.sub(
        key: const ValueKey('retired-notice'),
        title: fromSettings
            ? 'Copie d’avant la suppression des WOD'
            : 'Mise à jour',
        children: [
          Text(
            'WOD et séances perso retirés',
            style: KType.titreCarte.copyWith(color: k.texte),
          ),
          Text(
            'Kalis Track se recentre sur ton programme. L’onglet WOD, le '
            'créateur de séances et « Mes progrès » ont été retirés.',
            style: body,
          ),
          if (notice == null)
            KCard(
              child: Text(
                'Aucune copie dans cette session : il n’y avait ni WOD, ni '
                'séance perso, ni crédit à supprimer.',
                style: body,
              ),
            )
          else ...[
            const KSectionTitle('Supprimé de l’application', top: KSpacing.s4),
            KCard(
              key: const ValueKey('retired-notice-deleted'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in notice.summary.lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: KSpacing.s4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('•  ', style: body),
                          Expanded(child: Text(line, style: body)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Text(
              'Ne change pas : ton programme, l’historique de ses séances, '
              'tes records, tes références, tes réglages et ton profil. Ton '
              'niveau peut baisser : les WOD et les séances perso ne '
              'rapportent plus d’XP.',
              style: body,
            ),
            const KSectionTitle('Ta copie de sécurité', top: KSpacing.s4),
            KCard(
              key: const ValueKey('retired-notice-copy'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified_rounded, color: k.validation),
                      const SizedBox(width: KSpacing.s8),
                      Expanded(
                        child: Text(
                          'Copie complète vérifiée',
                          style: KType.titreCarte.copyWith(color: k.texte),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: KSpacing.s8),
                  // UI4 (R5) : plus de chemin « Réglages › Sauvegardes ».
                  Text(
                    'Faite le ${_date(notice.at)} (${_size(notice.bytes)}), '
                    'avant toute suppression. Elle est gardée dans '
                    'l’application et reste accessible depuis les Réglages, '
                    'rubrique « Données et confidentialité ». Elle contient '
                    'toutes tes données d’avant la mise à jour et s’importe '
                    'dans la version précédente.',
                    style: body,
                  ),
                ],
              ),
            ),
            KPrimaryButton(
              key: const ValueKey('retired-notice-share'),
              onPressed: () => _share(context, notice),
              icon: Icons.ios_share_rounded,
              label: 'Partager la copie',
            ),
            KTonalButton(
              key: const ValueKey('retired-notice-save'),
              onPressed: () => _save(context, notice),
              icon: Icons.save_alt_rounded,
              label: 'Enregistrer dans un fichier',
              expand: true,
            ),
          ],
          KTonalButton(
            key: const ValueKey('retired-notice-close'),
            onPressed: close,
            label: fromSettings ? 'Fermer' : 'Compris',
            expand: true,
          ),
        ],
      ),
    );
  }
}
