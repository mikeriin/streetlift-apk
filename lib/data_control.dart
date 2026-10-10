// Contrôle des données par l'utilisateur (L2b) : export par fichier, import
// avec aperçu et confirmation, suppression locale explicite. Réutilise la
// validation, les limites, la file d'écritures et la transaction d'import
// de L2 : aucun second chemin d'import.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'backup_files.dart';
import 'kalis_clock.dart';
import 'notifications.dart';
import 'session_prefs.dart';
import 'store.dart';
import 'ui.dart';

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
String exportMessage(
  FileSaveResult r, {
  bool unsaved = false,
}) => switch (r.status) {
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
  final now = KalisClock.now();
  final json = store.exportForFile(appVersion: appVersion, at: now);
  final result = await backupFiles.save(
    backupFileName(now, test: SessionSpace.isDev),
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
  // G1 (D2.3) : une sauvegarde de la session de test n'entre dans la
  // session personnelle qu'après un avertissement explicite.
  if (!SessionSpace.isDev && isTestSessionBackup(raw)) {
    final go = await showKConfirm(
      context,
      title: 'Importer une sauvegarde de test ?',
      message:
          'Ce fichier vient d’une session de test (mode dev), avec des '
          'données fictives et parfois une date simulée. L’importer '
          'remplacerait tes données personnelles par ces données de test.',
      confirmLabel: 'Continuer quand même',
      destructive: true,
    );
    if (!context.mounted) return null;
    if (!go) {
      _say(messenger, 'Import annulé : rien n’a changé.');
      return null;
    }
  }
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
    final choice = await Navigator.of(context).push<ImportChoice>(
      MaterialPageRoute(
        builder: (_) => ImportPreviewDialog(preview: preview, source: source),
      ),
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
      final again = await showKConfirm(
        context,
        title: 'Tes données ont changé',
        message:
            'Des données ont été modifiées depuis l’aperçu. Rien n’a été '
            'importé. Revois l’aperçu et confirme de nouveau : une sauvegarde '
            'faite avant ce changement ne le contient pas.',
        confirmLabel: 'Revoir l’aperçu',
      );
      if (again && context.mounted) continue;
      _say(messenger, 'Import annulé : rien n’a changé.');
      return status;
    }
    if (status == ImportStatus.success) await rescheduleReminders();
    _say(messenger, switch (status) {
      ImportStatus.success =>
        'Import réussi : ${preview.sessionsDone} séances${preview.ignored.hasUserData ? ' ; WOD, séances perso et crédits du fichier ignorés' : ''}. Tes données précédentes restent en copie de secours interne.',
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
  final choice = await Navigator.of(context).push<EraseChoice>(
    MaterialPageRoute(builder: (_) => const EraseDataDialog()),
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

/// Bas de page des sous-pages de confirmation, dans l'ordre de `KConfirm` :
/// « Annuler » (même effet que le retour) à gauche, l'action principale à
/// droite, même hauteur (56) ; grand texte ou écran étroit : l'un sous
/// l'autre, l'action en haut. Au-dessus du clavier.
class _PageActions extends StatelessWidget {
  final Widget primary;
  const _PageActions({required this.primary});

  @override
  Widget build(BuildContext context) {
    final cancel = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: KSize.primary),
      child: KTonalButton(
        label: 'Annuler',
        expand: true,
        onPressed: () => Navigator.maybePop(context),
      ),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            KSpacing.page,
            KSpacing.s8,
            KSpacing.page,
            KSpacing.s16,
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              final stacked =
                  c.maxWidth <
                  6 * KSize.target * MediaQuery.textScalerOf(context).scale(1);
              if (stacked) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    primary,
                    const SizedBox(height: KSpacing.s8),
                    cancel,
                  ],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: cancel),
                    const SizedBox(width: KSpacing.s8),
                    Expanded(child: primary),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Ligne d'information d'un aperçu : libellé, puis valeur.
class _Line extends StatelessWidget {
  final String label, value;
  const _Line(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: KSpacing.s16,
      vertical: KSpacing.s8,
    ),
    child: KRowLabel(label, subtitle: value),
  );
}

/// Liste à puces sous un titre de section (une carte, sans séparateurs).
class _Bullets extends StatelessWidget {
  final String title;
  final List<String> items;
  const _Bullets(this.title, this.items);
  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final style = KType.corps.copyWith(color: k.texte);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        KSectionTitle(title),
        KCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final t in items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: KSpacing.s4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•  ', style: style),
                      Expanded(child: Text(t, style: style)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Aperçu d'une sauvegarde avant import (sous-page, §4.5) : contenu du
/// fichier, état du téléphone, conséquence, sauvegarde préalable proposée.
/// Rend le choix ([ImportChoice]) par `Navigator.pop`, null si annulé.
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
    final k = KTokens.of(context);
    final p = widget.preview;
    final done = store.logs.values.where((l) => l.done).length;
    return KPage.sub(
      title: 'Importer une sauvegarde',
      lead:
          'Vérifie le contenu du fichier avant de remplacer tes données. '
          'Rien ne change avant ta confirmation.',
      bottom: _PageActions(
        primary: KPrimaryButton(
          key: const ValueKey('import-confirm'),
          label: _backupFirst
              ? 'Sauvegarder puis remplacer'
              : 'Remplacer sans sauvegarde',
          onPressed: () => Navigator.pop(
            context,
            _backupFirst
                ? ImportChoice.backupThenReplace
                : ImportChoice.replaceWithoutBackup,
          ),
        ),
      ),
      children: [
        KMenuGroup(
          title: 'Contenu du fichier',
          dividerIndent: KSpacing.s16,
          children: [
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
              '${p.sessionsDone}${p.archivedSessions == 0 ? '' : ' (dont ${p.archivedSessions} répétées)'}',
            ),
            _Line('Niveau calculé', 'niveau ${p.level} · ${p.xp} XP'),
            _Line('Exercices ajoutés', '${p.userExercises}'),
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
          ],
        ),
        // G2 (D1.1) : un fichier d'avant dev6.1.0 peut contenir des WOD,
        // des séances perso, des crédits ou des données « Motivation » :
        // ils ne sont plus importés, et c'est dit avant de confirmer.
        if (p.ignored.hasUserData)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KSpacing.s4),
            child: Text(
              'Non importé (fonctions retirées) : '
              '${p.ignored.lines.join(', ')}. Ces données restent dans le '
              'fichier.',
              key: const ValueKey('import-ignored'),
              style: KType.detail.copyWith(color: k.texte2),
            ),
          ),
        KMenuGroup(
          title: 'Sur ce téléphone',
          dividerIndent: KSpacing.s16,
          children: [
            _Line('Séances terminées', '$done'),
            _Line(
              'Départ du programme',
              store.program.start == null
                  ? 'non démarré'
                  : 'S1 · J1 le ${civilDateLabel(store.program.start!)}',
            ),
          ],
        ),
        const KNotice(
          icon: Icons.warning_amber_rounded,
          tone: KTone.danger,
          message:
              'L’import remplace toutes tes données actuelles : journal, '
              'références, réglages, profil et données Koach. Aucune fusion.',
        ),
        KMenuGroup(
          dividerIndent: KSpacing.s16,
          children: [
            KSwitchRow(
              key: const ValueKey('import-backup-first'),
              title:
                  'Sauvegarder d’abord mes données actuelles dans un fichier '
                  '(recommandé)',
              value: _backupFirst,
              onChanged: (v) => setState(() => _backupFirst = v),
            ),
          ],
        ),
      ],
    );
  }
}

/// Mot à taper pour confirmer la suppression.
const eraseConfirmationWord = 'SUPPRIMER';

/// Le mot tapé confirme la suppression : espaces ignorés, casse ignorée
/// (« supprimer » est accepté comme « SUPPRIMER »).
bool eraseWordMatches(String typed) =>
    typed.trim().toLowerCase() == eraseConfirmationWord.toLowerCase();

/// Suppression des données (sous-page, §4.5) : périmètre, export préalable
/// proposé, mot à taper. Rend le choix ([EraseChoice]) par `Navigator.pop`,
/// null si annulé.
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
    final k = KTokens.of(context);
    final confirmed = eraseWordMatches(_typed.text);
    return KPage.sub(
      title: 'Supprimer les données de l’application',
      lead:
          'L’application demande à Android d’effacer ses données : un '
          'effacement physique irrécupérable n’est pas garanti.',
      bottom: _PageActions(
        primary: KPrimaryButton(
          key: const ValueKey('erase-confirm'),
          label: 'Supprimer',
          danger: true,
          onPressed: confirmed
              ? () => Navigator.pop(
                  context,
                  _exportFirst
                      ? EraseChoice.exportThenErase
                      : EraseChoice.erase,
                )
              : null,
        ),
      ),
      children: [
        const _Bullets('Supprimé de ce téléphone', [
          'le journal : séances du programme, séries, notes, dates',
          'les exercices ajoutés',
          'les références (poids de corps, 1RM, max) : retour aux valeurs '
              'du programme',
          'les réglages (thème, sons, rappels)',
          'les copies de secours internes (dont la copie d’avant la '
              'suppression des WOD) et les anciennes données de migration',
          'les rappels programmés par l’application',
        ]),
        const _Bullets('Non supprimé', [
          'les fichiers exportés et les textes copiés ailleurs',
          'les sauvegardes Android ou Google déjà faites : elles peuvent '
              'restaurer ces données si l’application est réinstallée',
          'les autorisations système (notifications, alarmes) : elles se '
              'gèrent dans les réglages Android',
          'le programme intégré',
        ]),
        KMenuGroup(
          title: 'Confirmation',
          dividerIndent: KSpacing.s16,
          children: [
            KSwitchRow(
              key: const ValueKey('erase-export-first'),
              title: 'Exporter d’abord une sauvegarde (recommandé)',
              value: _exportFirst,
              onChanged: (v) => setState(() => _exportFirst = v),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                KSpacing.s16,
                KSpacing.s8,
                KSpacing.s16,
                KSpacing.s16,
              ),
              child: TextField(
                key: const ValueKey('erase-word'),
                controller: _typed,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                style: KType.corps.copyWith(color: k.texte),
                decoration: const InputDecoration(
                  labelText: 'Tape $eraseConfirmationWord pour confirmer',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// G1 : sauvegarde exportée depuis une session de test (mode dev).
bool isTestSessionBackup(String raw) {
  try {
    final data = jsonDecode(raw);
    return data is Map && data['sessionDeTest'] == true;
  } catch (_) {
    return false;
  }
}
