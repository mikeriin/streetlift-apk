import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/notifications.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'support/fake_notifications.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppStore app;
  late FakeNotifications backend;
  late NotificationService service;
  final now = DateTime.utc(2026, 9, 13, 12);
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    app = AppStore();
    await app.init();
    app.settings.notifOn = true;
    // L4 : une installation neuve n'a pas de rappel avant son départ ; ces
    // scénarios portent sur une installation existante (calendrier du
    // 13/07/2026). Cas « non démarré » : test/l4_depart_test.dart.
    app.program.start = DateTime(2026, 7, 13);
    backend = FakeNotifications();
    service = NotificationService(app, backend, now: () => now);
    tzdata.initializeTimeZones();
  });
  tearDown(() async {
    await app.flush();
    service.dispose();
    app.dispose();
  });

  test(
    'couvre tout le programme restant, avec des IDs stables et un seul rappel par jour',
    () {
      final plan = planReminders(
        app,
        now,
        location: tz.getLocation('Europe/Paris'),
      );
      expect(plan.length, greaterThan(7));
      expect(plan.length, lessThanOrEqualTo(280));
      expect(plan.last.at.isAfter(now.add(const Duration(days: 100))), true);
      expect(plan.map((r) => r.id).toSet().length, plan.length);
      expect(plan.every((r) => r.at.isAfter(now)), true);
      final again = planReminders(
        app,
        now.add(const Duration(hours: 1)),
        location: tz.getLocation('Europe/Paris'),
      );
      expect(again.map((r) => r.id), plan.map((r) => r.id));
    },
  );
  test(
    'le changement d’heure conserve 7h30 et change correctement l’instant UTC',
    () {
      app.settings.notifSkipRest = false;
      final plan = planReminders(
        app,
        now,
        location: tz.getLocation('Europe/Paris'),
      );
      final before = plan.singleWhere(
        (r) => r.at.month == 10 && r.at.day == 24,
      );
      // L12 (KT-070) : plus de rappel les jours de repos ; le dimanche 25/10
      // (S16 · J7) en est un. Même contrôle du changement d'heure avec le
      // lundi 26/10 (S17 · J1) : 2 jours + 1 h.
      expect(plan.where((r) => r.at.month == 10 && r.at.day == 25), isEmpty);
      final after = plan.singleWhere((r) => r.at.month == 10 && r.at.day == 26);
      expect(before.at.hour, 7);
      expect(after.at.hour, 7);
      expect(before.at.minute, 30);
      expect(after.at.toUtc().difference(before.at.toUtc()).inHours, 49);
    },
  );
  test(
    'supprime les anciennes alarmes et celles des séances terminées, sans toucher aux autres',
    () async {
      app.settings.notifSkipRest = false;
      final all = planReminders(app, now);
      final first = all.first;
      final match = RegExp(r'S(\d+)-J(\d+)').firstMatch(first.payload)!;
      app.markSessionDone(int.parse(match[1]!), int.parse(match[2]!), true);
      backend.pending.addAll({100, 106, first.id, 901, 42});
      await service.reschedule();
      expect(backend.cancelled, containsAll([100, 106, first.id]));
      expect(backend.pending, containsAll([901, 42]));
      expect(service.status.value.error, null);
    },
  );
  test(
    'notification désactivée ou programme terminé ne crée aucune alarme',
    () async {
      app.settings.notifOn = false;
      backend.pending.add(1100);
      await service.reschedule();
      expect(backend.pending, isEmpty);
      expect(backend.scheduled, isEmpty);
      app.settings.notifOn = true;
      expect(planReminders(app, DateTime(2040)), isEmpty);
    },
  );
  test('les blocages globaux et du canal sont diagnostiqués', () async {
    backend.allowed = false;
    await service.reschedule();
    expect(service.status.value.access!.allowed, false);
    expect(backend.scheduled, isEmpty);
    backend.allowed = true;
    backend.channelAllowed = false;
    expect(await service.requestPermission(), false);
    await service.reschedule();
    expect(service.status.value.access!.channelAllowed, false);
    expect(backend.scheduled, isEmpty);
  });
  test('un refus de l’heure précise garde des rappels approximatifs', () async {
    backend.exact = false;
    await service.reschedule();
    expect(service.status.value.count, greaterThan(7));
    expect(backend.scheduled.every((r) => !r.exact), true);
    expect(service.status.value.next!.hour, app.settings.notifHour);
  });
  test(
    'révocation entre vérification et planification : repli sans abandon des rappels',
    () async {
      backend.revokeExact = true;
      await service.reschedule();
      expect(service.status.value.error, null);
      expect(service.status.value.access!.exact, false);
      expect(service.status.value.count, greaterThan(7));
      expect(backend.scheduled.every((r) => !r.exact), true);
    },
  );
  test(
    'les erreurs restent lisibles et une nouvelle tentative répare le service',
    () async {
      backend.failInit = true;
      await service.reschedule();
      expect(
        service.status.value.technicalError,
        contains('init_native_error'),
      );
      backend.failInit = false;
      backend.failSchedule = true;
      await service.reschedule();
      expect(
        service.status.value.technicalError,
        contains('schedule_native_error'),
      );
      backend.failSchedule = false;
      await service.reschedule();
      expect(service.status.value.error, null);
      expect(service.status.value.count, greaterThan(7));
      expect(backend.initialized, 2);
    },
  );
  test(
    'désactiver pendant une planification ne laisse aucun rappel quotidien',
    () async {
      backend.scheduleGate = Completer<void>();
      final first = service.reschedule();
      await Future<void>.delayed(Duration.zero);
      app.settings.notifOn = false;
      final second = service.reschedule();
      backend.scheduleGate!.complete();
      await Future.wait([first, second]);
      expect(backend.pending, isEmpty);
      expect(service.status.value.count, 0);
    },
  );
  test(
    'ne recrée pas les mêmes alarmes inutilement mais une réparation forcée les restaure',
    () async {
      await service.reschedule();
      final n = backend.scheduled.length;
      await service.reschedule();
      expect(backend.scheduled.length, n);
      await service.reschedule(force: true);
      expect(backend.scheduled.length, 2 * n);
      expect(backend.cancelled, isEmpty);
    },
  );
  test(
    'les tests immédiat et différé ne dépendent pas de la période du programme',
    () async {
      app.settings.notifOn = false;
      expect(await service.test(), true);
      expect(backend.shown, 1);
      expect(await service.test(delayed: true), true);
      expect(backend.scheduled.single.reminder.id, reminderDelayedTestId);
      expect(
        backend.scheduled.single.reminder.at.difference(now).inSeconds,
        15,
      );
    },
  );
  test(
    'tap après démarrage à froid : bonne séance, payload invalide ignoré',
    () async {
      backend.launchPayload = 'S8-J2';
      final opened = <String>[];
      service.onOpen = (w, d) => opened.add('$w/$d');
      await service.reschedule();
      await service.reschedule();
      expect(opened, ['8/2']);
      backend.open!('S99-J1');
      backend.open!('invalid');
      backend.open!('S8-J3');
      expect(opened, ['8/2', '8/3']);
    },
  );
  test(
    'une séance terminée en cours d’utilisation annule automatiquement son rappel',
    () async {
      service.bind();
      await service.reschedule();
      final r = backend.scheduled.first.reminder;
      final match = RegExp(r'S(\d+)-J(\d+)').firstMatch(r.payload)!;
      app.markSessionDone(int.parse(match[1]!), int.parse(match[2]!), true);
      // Laisse la file du listener finir sans appeler manuellement reschedule.
      await Future<void>.delayed(Duration.zero);
      expect(backend.pending.contains(r.id), false);
    },
  );
}
