// UI4 (refonte UI) : contenu de la sous-page « Notifications » (cahier §4.1,
// §4.5) — groupes du kit, réglages en place. Posé par les Réglages dans une
// `KPage.sub` : ce widget ne porte pas de Scaffold. [highlight] met une
// ligne en évidence 1,5 s quand on arrive depuis la recherche des réglages.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'device.dart';
import 'notifications.dart';
import 'ui.dart';

class NotificationSettingsPanel extends StatefulWidget {
  final NotificationService? service;

  /// Ligne à mettre en évidence : `'reminder'` (« Rappels de séance ») ou
  /// `'reminder-time'` (« Heure du rappel »).
  final String? highlight;
  const NotificationSettingsPanel({super.key, this.service, this.highlight});
  @override
  State<NotificationSettingsPanel> createState() =>
      _NotificationSettingsPanelState();
}

class _NotificationSettingsPanelState extends State<NotificationSettingsPanel> {
  NotificationService get service => widget.service ?? Notif.service;
  bool working = false, attempted = false;
  @override
  void initState() {
    super.initState();
    unawaited(service.reschedule());
  }

  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> run(Future<void> Function() action) async {
    if (working) return;
    setState(() => working = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> open(String page) async {
    if (!await openDeviceSettings(page)) {
      message('Ouvre les réglages Android → Applications → Kalis Track.');
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ReminderStatus>(
    valueListenable: service.status,
    builder: (context, state, _) {
      final k = KTokens.of(context);
      final s = service.app.settings;
      final access = state.access;
      final busy = working || state.busy;
      final showProblem = s.notifOn || attempted;
      final blocked = showProblem && access != null && !access.usable;
      final error = showProblem ? state.error : null;
      // Bloqué : l'accès est connu ; le canal seul peut être coupé.
      final allowed = access?.allowed ?? false;
      final time = TimeOfDay(
        hour: s.notifHour,
        minute: s.notifMinute,
      ).format(context);
      final groups = <Widget>[
        KMenuGroup(
          dividerIndent: KSpacing.s16,
          children: [
            KSwitchRow(
              key: const ValueKey('notif-reminder'),
              title: 'Rappels de séance',
              subtitle: 'La séance du programme à l’heure choisie.',
              value: s.notifOn,
              highlight: widget.highlight == 'reminder',
              onChanged: busy
                  ? null
                  : (value) => run(() async {
                      attempted = value;
                      if (value && !await service.requestPermission()) return;
                      s.notifOn = value;
                      service.app.saveSettings();
                      await service.reschedule();
                    }),
            ),
            if (s.notifOn)
              KMenuRow(
                key: const ValueKey('notif-reminder-time'),
                title: 'Heure du rappel',
                // L12 (KT-070) : jamais de rappel un jour de repos ni
                // pendant une pause (réglage « Ignorer les jours de repos »
                // retiré).
                subtitle: 'Jours d’entraînement prévus uniquement',
                value: time,
                highlight: widget.highlight == 'reminder-time',
                enabled: !busy,
                onTap: () => run(() async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: s.notifHour,
                      minute: s.notifMinute,
                    ),
                    helpText: 'Heure du rappel',
                  );
                  if (picked == null) return;
                  s.notifHour = picked.hour;
                  s.notifMinute = picked.minute;
                  service.app.saveSettings();
                  await service.reschedule();
                }),
              ),
          ],
        ),
        if (s.notifOn && !blocked && error == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KSpacing.s4),
            child: Text(
              busy
                  ? 'Mise à jour du rappel…'
                  : state.next == null
                  ? 'Aucune séance à venir à rappeler.'
                  : 'Prochain rappel : '
                        '${MaterialLocalizations.of(context).formatMediumDate(state.next!)}'
                        ' à ${TimeOfDay.fromDateTime(state.next!).format(context)}.',
              style: KType.detail.copyWith(color: k.texte2),
            ),
          ),
        if (blocked || error != null)
          KMenuGroup(
            key: const ValueKey('notif-problem'),
            title: 'Problème',
            children: [
              KMenuRow(
                icon: Icons.error_outline_rounded,
                danger: true,
                chevron: false,
                title:
                    error ??
                    (allowed
                        ? 'Rappels désactivés dans les réglages Android'
                        : 'Notifications bloquées par Android'),
              ),
              if (blocked)
                KMenuRow(
                  title: 'Ouvrir les réglages Android',
                  enabled: !busy,
                  onTap: () => open(allowed ? 'channel' : 'notifications'),
                ),
              if (error != null)
                KMenuRow(
                  title: 'Réessayer',
                  chevron: false,
                  enabled: !busy,
                  onTap: () => run(() => service.reschedule(force: true)),
                ),
              if (error != null && state.technicalError != null)
                KMenuRow(
                  title: 'Copier le rapport technique',
                  chevron: false,
                  onTap: () async {
                    await Clipboard.setData(
                      ClipboardData(text: state.technicalError!),
                    );
                    message('Rapport technique copié.');
                  },
                ),
            ],
          ),
        if (s.notifOn && !blocked)
          KMenuGroup(
            key: const ValueKey('notif-android'),
            title: 'Options Android',
            dividerIndent: KSpacing.s16,
            children: [
              if (access?.exact == true)
                const KMenuRow(
                  title: 'Heure précise autorisée.',
                  chevron: false,
                )
              else
                KMenuRow(
                  title: 'Autoriser l’heure précise',
                  subtitle:
                      'Android peut retarder les rappels en veille. Tu peux '
                      'autoriser l’heure précise.',
                  enabled: !busy,
                  onTap: () => run(() async {
                    if (!await service.requestExactPermission()) {
                      message(
                        'Les rappels restent actifs à une heure approximative.',
                      );
                    }
                  }),
                ),
              KMenuRow(
                title: 'Notifications',
                subtitle: 'Réglages Android des rappels',
                onTap: () => open('channel'),
              ),
              KMenuRow(
                title: 'Batterie',
                subtitle: 'Réglages Android de la batterie',
                onTap: () => open('battery'),
              ),
            ],
          ),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < groups.length; i++) ...[
            if (i > 0) const SizedBox(height: KSpacing.s8),
            groups[i],
          ],
        ],
      );
    },
  );
}
