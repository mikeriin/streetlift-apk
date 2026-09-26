// Contrôle des données par l'utilisateur (L2b) : export par fichier, import
// avec aperçu et confirmation, suppression locale explicite. Réutilise la
// validation, les limites, la file d'écritures et la transaction d'import
// de L2 : aucun second chemin d'import.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'backup_files.dart';
import 'notifications.dart';
import 'store.dart';

/// Replanification des rappels après import ou suppression (remplaçable
/// par les tests).
Future<void> Function() rescheduleReminders = Notif.reschedule;

enum ImportChoice { backupThenReplace, replaceWithoutBackup }

enum EraseChoice { exportThenErase, erase }

String _size(int bytes) =>
    bytes < 1024 ? '$bytes octets' : '${(bytes / 1024).round()} Ko';

String _reason(String? code) => switch (code) {
  'denied' => 'accès refusé par l’emplacement choisi',
  'unavailable' => 'emplacement ou fichier indisponible',
  'partial' => 'le fichier relu ne correspond pas à la sauvegarde',
  'interrupted' => 'opération interrompue',
  'busy' => 'une autre opération de fichier est en cours',
  'noPicker' => 'aucun sélecteur de fichiers sur ce téléphone',
  'unsupported' => 'fonction indisponible sur cet appareil',
  _ => 'erreur de lecture ou d’écriture',
};

/// Message affiché après un export : un succès seulement si l'écriture a
/// été confirmée par relecture.
String exportMessage(FileSaveResult r, {bool unsaved = false}) => switch (r
    .status) {
  FileSaveStatus.saved =>
    'Sauvegarde enregistrée : ${r.name ?? 'fichier'}'
        '${r.bytes == null ? '' : ' (${_size(r.bytes!)})'}. '
        'Fichier non chiffré : garde-le en lieu sûr.'
        '${unsaved ? ' Il contient des modifications pas encore enregistrées sur le téléphone.' : ''}',
  FileSaveStatus.unverified =>
    'Fichier écrit mais non relu : ouvre-le pour vérifier ou refais l’export.',
  FileSaveStatus.cancelled => 'Export annulé : aucun fichier créé.',
  FileSaveStatus.failed =>
    'Export impossible : ${_reason(r.error)}.'
        '${r.deleted ? ' Le fichier incomplet a été supprimé.' : ''}',
};

/// Un message remplace le précédent : les étapes d'un même parcours
/// (préparation, export, import, suppression) ne s'empilent pas en file.
void _say(ScaffoldMessengerState messenger, String text) {
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 6)),
    );
}

/// Export par fichier. Les modifications en attente sont d'abord
/// enregistrées ; si elles ne peuvent pas l'être, le fichier contient l'état
/// affiché et le message le signale.
Future<FileSaveStatus> exportBackupFile(
  BuildContext context, {
  required String appVersion,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  _say(messenger, 'Préparation de l’export…');
  await store.flush();
  final unsaved = store.hasUnsavedChanges;
  final now = DateTime.now();
  final json = store.exportForFile(appVersion: appVersion, at: now);
  final result = await backupFiles.save(
    backupFileName(now),
    Uint8List.fromList(utf8.encode(json)),
  );
  _say(messenger, exportMessage(result, unsaved: unsaved));
  return result.status;
}

/// Import depuis un fichier choisi : lecture bornée, validation, aperçu,
/// confirmation, puis transaction d'import L2.
Future<ImportStatus?> importBackupFile(
  BuildContext context, {
  required String appVersion,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final opened = await backupFiles.open(ImportLimits.standard.maxInputChars);
  switch (opened.status) {
    case FileOpenStatus.cancelled:
      _say(messenger, 'Import annulé : rien n’a changé.');
      return null;
    case FileOpenStatus.tooLarge:
      _say(messenger, 'Fichier trop volumineux : rien n’a changé.');
      return ImportStatus.tooLarge;
    case FileOpenStatus.failed:
      _say(
        messenger,
        'Lecture impossible : ${_reason(opened.error)}. Rien n’a changé.',
      );
      return null;
    case FileOpenStatus.opened:
      break;
  }
  String text;
  try {
    text = utf8.decode(opened.bytes ?? Uint8List(0));
  } on FormatException {
    _say(messenger, _invalidMessage);
    return ImportStatus.invalid;
  }
  if (!context.mounted) return null;
  return confirmAndImport(
    context,
    text,
    appVersion: appVersion,
    source: opened.name,
  );
}

const _invalidMessage =
    'Ce fichier n’est pas une sauvegarde Kalis Track valide, ou son format n’est pas pris en charge. Rien n’a changé.';

/// Aperçu puis confirmation d'un texte de sauvegarde (fichier ou
/// presse-papiers). Rien n'est modifié avant la confirmation ; en cas de
/// changement local pendant l'aperçu, une nouvelle confirmation est exigée.
Future<ImportStatus?> confirmAndImport(
  BuildContext context,
  String raw, {
  required String appVersion,
  String? source,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  while (true) {
    if (!context.mounted) return null;
    final checked = store.previewImport(raw);
    final preview = checked.preview;
    if (preview == null) {
      _say(
        messenger,
        checked.status == ImportStatus.tooLarge
            ? 'Sauvegarde trop volumineuse : rien n’a changé.'
            : _invalidMessage,
      );
      return checked.status;
    }
    final choice = await showDialog<ImportChoice>(
      context: context,
      builder: (_) => ImportPreviewDialog(preview: preview, source: source),
    );
    if (!context.mounted) return null;
    if (choice == null) {
      _say(messenger, 'Import annulé : rien n’a changé.');
      return null;
    }
    if (choice == ImportChoice.backupThenReplace) {
      final saved = await exportBackupFile(context, appVersion: appVersion);
      if (!context.mounted) return null;
      if (saved != FileSaveStatus.saved) {
        _say(
          messenger,
          'Import non effectué : la sauvegarde de tes données actuelles n’a pas été confirmée. Rien n’a changé.',
        );
        return null;
      }
    }
    final status = await store.applyImport(preview);
    if (status == ImportStatus.conflict) {
      if (!context.mounted) return status;
      final again = await showDialog<bool>(
        context: context,
        builder: (_) => const _ConflictDialog(),
      );
      if (again == true && context.mounted) continue;
      _say(messenger, 'Import annulé : rien n’a changé.');
      return status;
    }
    if (status == ImportStatus.success) await rescheduleReminders();
    _say(messenger, switch (status) {
      ImportStatus.success =>
        'Import réussi : ${preview.sessionsDone} séances, ${preview.wodResults} résultats de WOD, ${preview.wodsUnlocked} WODs débloqués. Tes données précédentes restent en copie de secours interne.',
      ImportStatus.writeFailed =>
        'Import impossible : écriture refusée par le téléphone. Les données actuelles sont conservées.',
      ImportStatus.tooLarge => 'Sauvegarde trop volumineuse : rien n’a changé.',
      _ => _invalidMessage,
    });
    return status;
  }
}

/// Suppression des données locales : aperçu du périmètre, confirmation
/// tapée, export préalable proposé.
Future<EraseStatus?> eraseAppData(
  BuildContext context, {
  required String appVersion,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final choice = await showDialog<EraseChoice>(
    context: context,
    builder: (_) => const EraseDataDialog(),
  );
  if (!context.mounted) return null;
  if (choice == null) {
    _say(messenger, 'Suppression annulée : rien n’a été supprimé.');
    return null;
  }
  if (choice == EraseChoice.exportThenErase) {
    final saved = await exportBackupFile(context, appVersion: appVersion);
    if (!context.mounted) return null;
    if (saved != FileSaveStatus.saved) {
      _say(
        messenger,
        'Suppression non effectuée : l’export préalable n’a pas été confirmé. Rien n’a été supprimé.',
      );
      return null;
    }
  }
  final result = await store.eraseAllData();
  if (result.status != EraseStatus.failed) await rescheduleReminders();
  _say(messenger, switch (result.status) {
    EraseStatus.success =>
      'Données de l’application supprimées : elle est revenue à son état d’installation. Les fichiers exportés et les sauvegardes Android existantes ne sont pas touchés.',
    EraseStatus.partial =>
      'Suppression incomplète : ${result.remaining.length} élément(s) n’ont pas pu être effacés. Relance « Supprimer les données de l’application ».',
    EraseStatus.failed =>
      'Suppression impossible : écriture refusée. Tes données sont intactes.',
  });
  return result.status;
}

class _Line extends StatelessWidget {
  final String label, value;
  const _Line(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label : ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: value),
        ],
      ),
    ),
  );
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [const Text('•  '), Expanded(child: Text(text))],
    ),
  );
}

class ImportPreviewDialog extends StatefulWidget {
  final ImportPreview preview;
  final String? source;
  const ImportPreviewDialog({super.key, required this.preview, this.source});

  @override
  State<ImportPreviewDialog> createState() => _ImportPreviewDialogState();
}

class _ImportPreviewDialogState extends State<ImportPreviewDialog> {
  bool _backupFirst = true;

  String _date(BuildContext context, DateTime at) {
    final l = MaterialLocalizations.of(context);
    final time = l.formatTimeOfDay(
      TimeOfDay.fromDateTime(at),
      alwaysUse24HourFormat: true,
    );
    return '${l.formatFullDate(at)} à $time';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.preview;
    final heading = Theme.of(context).textTheme.titleSmall;
    final done = store.logs.values.where((l) => l.done).length;
    return AlertDialog(
      scrollable: true,
      title: const Text('Importer cette sauvegarde ?'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Contenu du fichier', style: heading),
          const SizedBox(height: 8),
          if (widget.source != null) _Line('Fichier', widget.source!),
          _Line(
            'Format',
            '${p.format}${p.appVersion == null ? '' : ' · Kalis Track ${p.appVersion}'}',
          ),
          _Line(
            'Exportée le',
            p.exportedAt == null
                ? 'date non enregistrée dans ce fichier'
                : _date(context, p.exportedAt!),
          ),
          _Line(
            'Séances terminées',
            '${p.sessionsDone} (programme ${p.programSessions}, perso ${p.customSessionsDone}, dont ${p.archivedSessions} répétées)',
          ),
          _Line('Résultats de WOD', '${p.wodResults}'),
          _Line(
            'WODs débloqués',
            '${p.wodsUnlocked} (${p.creditsPaid} crédits payés)'
                '${p.legacyGrants == 0 ? '' : ' · ${p.legacyGrants} droits anciens archivés'}',
          ),
          _Line('Niveau calculé', 'niveau ${p.level} · ${p.xp} XP'),
          _Line(
            'Crédits gagnés',
            p.creditsGranted == null
                ? 'non enregistrés dans ce fichier : recalculés depuis son journal'
                : '${p.creditsGranted} (registre du fichier)',
          ),
          _Line(
            'Séances perso',
            '${p.customTemplates} modèles · ${p.userExercises} exercices ajoutés',
          ),
          _Line('Liste d’envies', '${p.wishlist}'),
          _Line('Départ du programme', switch ((
            p.programStart,
            p.startOrigin,
          )) {
            (null, _) => 'non démarré',
            (final d?, 'migration') =>
              'S1 · J1 le ${civilDateLabel(d)} (calendrier d’origine)',
            (final d?, _) => 'S1 · J1 le ${civilDateLabel(d)}',
          }),
          _Line(
            'Références',
            '${p.referencesSet} renseignées'
                '${p.referencesHistoric == 0 ? '' : ' · ${p.referencesHistoric} à vérifier'}',
          ),
          // L7 : les réponses aux questionnaires (données de santé
          // potentielles) sont nommées avant l'import.
          if (p.koachPresent)
            _Line(
              'Koach',
              '${p.koachEnabled ? 'activé' : 'désactivé'} · '
                  '${p.koachWeighIns} pesée(s) · '
                  '${p.koachAnswers} séance(s) avec questionnaire',
            ),
          const SizedBox(height: 12),
          Text('Sur ce téléphone', style: heading),
          const SizedBox(height: 8),
          _Line('Séances terminées', '$done'),
          _Line('WODs débloqués', '${store.unlockedWods.length}'),
          _Line(
            'Départ du programme',
            store.program.start == null
                ? 'non démarré'
                : 'S1 · J1 le ${civilDateLabel(store.program.start!)}',
          ),
          const SizedBox(height: 12),
          Text(
            'L’import remplace toutes tes données actuelles : journal, séances perso, références, résultats, crédits, WODs débloqués, liste d’envies, réglages et données Koach. Aucune fusion.',
            style: TextStyle(color: SL.action, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _backupFirst,
            onChanged: (v) => setState(() => _backupFirst = v ?? false),
            title: const Text(
              'Sauvegarder d’abord mes données actuelles dans un fichier (recommandé)',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed:
              () => Navigator.pop(
                context,
                _backupFirst
                    ? ImportChoice.backupThenReplace
                    : ImportChoice.replaceWithoutBackup,
              ),
          child: Text(
            _backupFirst
                ? 'Sauvegarder puis remplacer'
                : 'Remplacer sans sauvegarde',
          ),
        ),
      ],
    );
  }
}

class _ConflictDialog extends StatelessWidget {
  const _ConflictDialog();
  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Tes données ont changé'),
    content: const Text(
      'Des données ont été modifiées depuis l’aperçu. Rien n’a été importé. Revois l’aperçu et confirme de nouveau : une sauvegarde faite avant ce changement ne le contient pas.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Annuler'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Revoir l’aperçu'),
      ),
    ],
  );
}

/// Mot à taper pour confirmer la suppression.
const eraseConfirmationWord = 'SUPPRIMER';

class EraseDataDialog extends StatefulWidget {
  const EraseDataDialog({super.key});
  @override
  State<EraseDataDialog> createState() => _EraseDataDialogState();
}

class _EraseDataDialogState extends State<EraseDataDialog> {
  final _typed = TextEditingController();
  bool _exportFirst = true;

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heading = Theme.of(context).textTheme.titleSmall;
    final confirmed = _typed.text.trim().toUpperCase() == eraseConfirmationWord;
    return AlertDialog(
      scrollable: true,
      title: const Text('Supprimer les données de l’application ?'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Supprimé de ce téléphone', style: heading),
          const SizedBox(height: 6),
          const _Bullet(
            'le journal : séances du programme et perso, séries, notes, dates',
          ),
          const _Bullet(
            'les modèles de séances perso et les exercices ajoutés',
          ),
          const _Bullet(
            'les références Pilotage (poids de corps, 1RM, max) : retour aux valeurs du programme',
          ),
          const _Bullet('les résultats de WOD et les WODs modifiés ou créés'),
          const _Bullet(
            'les crédits gagnés, les WODs débloqués et les droits anciens archivés',
          ),
          const _Bullet(
            'la liste d’envies et les réglages (thème, sons, rappels)',
          ),
          const _Bullet(
            'les copies de secours internes et les anciennes données de migration',
          ),
          const _Bullet('les rappels programmés par l’application'),
          const SizedBox(height: 10),
          Text('Non supprimé', style: heading),
          const SizedBox(height: 6),
          const _Bullet('les fichiers exportés et les textes copiés ailleurs'),
          const _Bullet(
            'les sauvegardes Android ou Google déjà faites : elles peuvent restaurer ces données si l’application est réinstallée',
          ),
          const _Bullet(
            'les autorisations système (notifications, alarmes) : elles se gèrent dans les réglages Android',
          ),
          const _Bullet('le programme et le catalogue de WODs intégrés'),
          const SizedBox(height: 10),
          const Text(
            'L’application demande à Android d’effacer ses données : un effacement physique irrécupérable n’est pas garanti.',
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _exportFirst,
            onChanged: (v) => setState(() => _exportFirst = v ?? false),
            title: const Text('Exporter d’abord une sauvegarde (recommandé)'),
          ),
          TextField(
            controller: _typed,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Tape $eraseConfirmationWord pour confirmer',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed:
              confirmed
                  ? () => Navigator.pop(
                    context,
                    _exportFirst
                        ? EraseChoice.exportThenErase
                        : EraseChoice.erase,
                  )
                  : null,
          child: const Text('Supprimer'),
        ),
      ],
    );
  }
}
