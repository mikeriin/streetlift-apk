import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'device.dart';
import 'notifications.dart';
import 'ui.dart';

class NotificationSettingsPanel extends StatefulWidget {
  final NotificationService? service;
  const NotificationSettingsPanel({super.key, this.service});
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
      final s = service.app.settings;
      final access = state.access;
      final busy = working || state.busy;
      final showProblem = s.notifOn || attempted;
      final blocked = showProblem && access != null && !access.usable;
      final error = showProblem ? state.error : null;
      final c = Theme.of(context).colorScheme;
      return KCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile.adaptive(
              title: const Text('Rappels de séance'),
              subtitle: const Text('La séance du programme à l’heure choisie.'),
              value: s.notifOn,
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
            if (s.notifOn) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Heure du rappel'),
                // L12 (KT-070) : jamais de rappel un jour de repos ni
                // pendant une pause (réglage « Ignorer les jours de repos »
                // retiré).
                subtitle: const Text('Jours d’entraînement prévus uniquement'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      TimeOfDay(
                        hour: s.notifHour,
                        minute: s.notifMinute,
                      ).format(context),
                      style: TextStyle(
                        color: c.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: busy
                    ? null
                    : () => run(() async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: s.notifHour,
                            minute: s.notifMinute,
                          ),
                          helpText: 'Heure du rappel',
                        );
                        if (time == null) return;
                        s.notifHour = time.hour;
                        s.notifMinute = time.minute;
                        service.app.saveSettings();
                        await service.reschedule();
                      }),
              ),
              if (!blocked && error == null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Text(
                    busy
                        ? 'Mise à jour du rappel…'
                        : state.next == null
                        ? 'Aucune séance à venir à rappeler.'
                        : 'Prochain rappel : ${MaterialLocalizations.of(context).formatMediumDate(state.next!)} à ${TimeOfDay.fromDateTime(state.next!).format(context)}.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
            if (blocked || error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.error.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        error ??
                            (access!.allowed
                                ? 'Canal « Rappel quotidien » désactivé'
                                : 'Notifications bloquées par Android'),
                        style: TextStyle(
                          color: c.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (blocked)
                        OutlinedButton.icon(
                          onPressed: busy
                              ? null
                              : () => open(
                                  access.allowed ? 'channel' : 'notifications',
                                ),
                          icon: const Icon(Icons.settings_outlined),
                          label: const Text('Ouvrir les réglages Android'),
                        ),
                      if (error != null)
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton(
                              onPressed: busy
                                  ? null
                                  : () => run(
                                      () => service.reschedule(force: true),
                                    ),
                              child: const Text('Réessayer'),
                            ),
                            if (state.technicalError != null)
                              TextButton(
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: state.technicalError!),
                                  );
                                  message('Rapport technique copié.');
                                },
                                child: const Text(
                                  'Copier le rapport technique',
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            if (s.notifOn && !blocked)
              ExpansionTile(
                title: const Text('Options Android'),
                shape: const Border(),
                collapsedShape: const Border(),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Text(
                    access?.exact == true
                        ? 'Heure précise autorisée.'
                        : 'Android peut retarder les rappels en veille. Tu peux autoriser l’heure précise.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (access?.exact != true)
                        TextButton.icon(
                          onPressed: busy
                              ? null
                              : () => run(() async {
                                  if (!await service.requestExactPermission()) {
                                    message(
                                      'Les rappels restent actifs à une heure approximative.',
                                    );
                                  }
                                }),
                          icon: const Icon(Icons.alarm),
                          label: const Text('Autoriser l’heure précise'),
                        ),
                      TextButton(
                        onPressed: () => open('channel'),
                        child: const Text('Notifications'),
                      ),
                      TextButton(
                        onPressed: () => open('battery'),
                        child: const Text('Batterie'),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      );
    },
  );
}
