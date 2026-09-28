import 'dart:async';
import 'package:flutter/services.dart';
import 'package:streetlift_tracker/notifications.dart';

class FakeNotifications implements NotificationBackend {
  bool allowed = true, channelAllowed = true, exact = true;
  bool failInit = false, failSchedule = false, revokeExact = false;
  int initialized = 0, requests = 0, shown = 0;
  String? launchPayload;
  void Function(String?)? open;
  Completer<void>? scheduleGate;
  final pending = <int>{};
  final cancelled = <int>[];
  final scheduled = <({PlannedReminder reminder, bool exact})>[];
  @override
  Future<String?> initialize(void Function(String?) onOpen) async {
    initialized++;
    if (failInit) throw StateError('init_native_error');
    open = onOpen;
    return launchPayload;
  }

  @override
  Future<NotificationAccess> access() async => NotificationAccess(
    allowed: allowed,
    channelAllowed: channelAllowed,
    exact: exact,
  );
  @override
  Future<bool> requestPermission() async {
    requests++;
    return allowed;
  }

  @override
  Future<bool> requestExactPermission() async => exact;
  @override
  Future<String?> timeZoneName() async => 'Europe/Paris';
  @override
  Future<Set<int>> pendingIds() async => Set.of(pending);
  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    pending.remove(id);
  }

  @override
  Future<void> schedule(PlannedReminder reminder, {required bool exact}) async {
    if (scheduleGate != null) await scheduleGate!.future;
    if (failSchedule) throw StateError('schedule_native_error');
    if (exact && revokeExact) {
      throw PlatformException(code: 'exact_alarms_not_permitted');
    }
    pending.add(reminder.id);
    scheduled.add((reminder: reminder, exact: exact));
  }

  @override
  Future<void> showTest() async {
    shown++;
  }
}
