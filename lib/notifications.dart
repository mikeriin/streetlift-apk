import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'device.dart';
import 'store.dart';

const reminderChannel = 'kalis_daily'; // Conserve les choix Android existants.
const reminderTestId = 900;
const reminderDelayedTestId = 901;

class PlannedReminder {
  final int id;
  final String title, body, payload;
  final tz.TZDateTime at;
  const PlannedReminder(this.id, this.title, this.body, this.payload, this.at);
  String get signature => '$title|$body|$payload|${at.millisecondsSinceEpoch}';
}

/// Règle des rappels (L12, KT-070), gardée par G2 : un rappel seulement un
/// jour d'entraînement prévu, jamais un jour de repos ni pendant une pause.
bool reminderAllowed({required bool trainingDay, bool paused = false}) =>
    trainingDay && !paused;

/// Dates civiles dans le fuseau du téléphone. Au plus 280 alarmes, même sans
/// rouvrir l'app chaque semaine. Le repli DateTime utilise le fuseau système.
List<PlannedReminder> planReminders(
  AppStore app,
  DateTime now, {
  tz.Location? location,
}) {
  // Pas de rappel sans départ confirmé (KT-006) : aucune date inventée.
  if (!app.settings.notifOn || !app.program.scheduled) return [];
  // G10 : la pause vacances / maladie de L11 est retirée (une pause en
  // cours avant la mise à jour ne suspend plus les rappels : elle ne
  // pourrait plus être levée).
  final result = <PlannedReminder>[];
  for (final week in app.program.weeks) {
    for (final day in week.days) {
      // KT-070 : uniquement les jours d'entraînement prévus, jamais un
      // jour de repos (l'ancien réglage « Ignorer les jours de repos » n'a
      // plus d'effet).
      if (app.isDone(week.n, day.j) ||
          !reminderAllowed(trainingDay: day.exercises.isNotEmpty)) {
        continue;
      }
      final date = app.program.dateFor(week.n, day.j);
      final at = location == null
          ? tz.TZDateTime.from(
              DateTime(
                date.year,
                date.month,
                date.day,
                app.settings.notifHour,
                app.settings.notifMinute,
              ),
              tz.UTC,
            )
          : tz.TZDateTime(
              location,
              date.year,
              date.month,
              date.day,
              app.settings.notifHour,
              app.settings.notifMinute,
            );
      if (!at.isAfter(now)) continue;
      result.add(
        PlannedReminder(
          1000 + (week.n - 1) * 7 + day.j,
          'S${week.n} · J${day.j} — ${day.title}',
          '${day.exercises.length} exercices · ${week.block}',
          'S${week.n}-J${day.j}',
          at,
        ),
      );
    }
  }
  result.sort((a, b) => a.at.compareTo(b.at));
  return result;
}

class NotificationAccess {
  final bool allowed, channelAllowed, exact;
  const NotificationAccess({
    required this.allowed,
    required this.channelAllowed,
    required this.exact,
  });
  bool get usable => allowed && channelAllowed;
}

/// Frontière native remplaçable pour tester erreurs, permissions et reprises.
abstract class NotificationBackend {
  Future<String?> initialize(void Function(String?) onOpen);
  Future<NotificationAccess> access();
  Future<bool> requestPermission();
  Future<bool> requestExactPermission();
  Future<String?> timeZoneName();
  Future<Set<int>> pendingIds();
  Future<void> cancel(int id);
  Future<void> schedule(PlannedReminder reminder, {required bool exact});
  Future<void> showTest();
}

class AndroidNotificationBackend implements NotificationBackend {
  final FlutterLocalNotificationsPlugin plugin;
  AndroidNotificationBackend({FlutterLocalNotificationsPlugin? plugin})
    : plugin = plugin ?? FlutterLocalNotificationsPlugin();
  AndroidFlutterLocalNotificationsPlugin get android =>
      plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >() ??
      (throw UnsupportedError('Les rappels nécessitent Android.'));

  static const details = NotificationDetails(
    android: AndroidNotificationDetails(
      reminderChannel,
      'Rappel quotidien',
      channelDescription: 'La séance du jour',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_kalis',
      category: AndroidNotificationCategory.reminder,
    ),
  );

  @override
  Future<String?> initialize(void Function(String?) onOpen) async {
    final initialized = await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_kalis'),
      ),
      onDidReceiveNotificationResponse: (r) => onOpen(r.payload),
    );
    if (initialized != true) {
      throw StateError('Android n’a pas initialisé les notifications.');
    }
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        reminderChannel,
        'Rappel quotidien',
        description: 'La séance du jour',
        importance: Importance.high,
      ),
    );
    final launch = await plugin.getNotificationAppLaunchDetails();
    return launch?.didNotificationLaunchApp == true
        ? launch?.notificationResponse?.payload
        : null;
  }

  @override
  Future<NotificationAccess> access() async {
    final allowed = await android.areNotificationsEnabled() ?? false;
    final channels = await android.getNotificationChannels() ?? [];
    final matching = channels.where((c) => c.id == reminderChannel);
    return NotificationAccess(
      allowed: allowed,
      channelAllowed:
          matching.isEmpty || matching.first.importance != Importance.none,
      exact: await android.canScheduleExactNotifications() ?? false,
    );
  }

  @override
  Future<bool> requestPermission() async =>
      await android.requestNotificationsPermission() ?? false;
  @override
  Future<bool> requestExactPermission() async =>
      await android.requestExactAlarmsPermission() ?? false;
  @override
  Future<String?> timeZoneName() => deviceTimeZoneName();
  @override
  Future<Set<int>> pendingIds() async =>
      (await plugin.pendingNotificationRequests()).map((r) => r.id).toSet();
  @override
  Future<void> cancel(int id) => plugin.cancel(id);
  @override
  Future<void> schedule(PlannedReminder r, {required bool exact}) =>
      plugin.zonedSchedule(
        r.id,
        r.title,
        r.body,
        r.at,
        details,
        payload: r.payload,
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
  @override
  Future<void> showTest() => plugin.show(
    reminderTestId,
    'Kalis Track · test',
    'Les notifications sont prêtes. Bon entraînement !',
    details,
  );
}

class ReminderStatus {
  final NotificationAccess? access;
  final int count;
  final DateTime? next;
  final String? error, technicalError;
  final bool busy;
  const ReminderStatus({
    this.access,
    this.count = 0,
    this.next,
    this.error,
    this.technicalError,
    this.busy = false,
  });
}

class NotificationService {
  /// Magasin suivi (G1 : remplacé au changement de session, [attach]).
  AppStore app;
  final NotificationBackend backend;
  final DateTime Function() now;
  final status = ValueNotifier<ReminderStatus>(const ReminderStatus());
  void Function(int week, int day)? onOpen;
  bool _ready = false, _bound = false;
  Future<void>? _initializing;
  Future<void> _queue = Future<void>.value();
  int _revision = 0;
  String? _source;
  final Map<int, String> _scheduled = {};
  NotificationService(this.app, this.backend, {DateTime Function()? now})
    : now = now ?? DateTime.now;

  void _open(String? payload) {
    final match = RegExp(r'^S(\d+)-J([1-7])$').firstMatch(payload ?? '');
    if (match == null) return;
    final week = int.parse(match[1]!);
    if (week > 0 && week <= app.program.weeks.length) {
      onOpen?.call(week, int.parse(match[2]!));
    }
  }

  Future<void> init() async {
    if (_ready) return;
    if (_initializing != null) return _initializing;
    _initializing = _initialize();
    try {
      await _initializing;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _initialize() async {
    tzdata.initializeTimeZones();
    final launch = await backend.initialize(_open);
    _ready = true;
    _open(launch);
  }

  /// Réagit aussi à une séance terminée/effacée et à un import.
  void bind() {
    if (_bound) return;
    _bound = true;
    app.addListener(_onStoreChange);
    _onStoreChange();
  }

  /// G1 : suit un autre magasin (redémarrage logique vers ou depuis la
  /// session de test). Tous les rappels sont recalculés depuis ce magasin :
  /// ceux de la session quittée sont annulés (session personnelle suspendue
  /// pendant la session de test, session de test annulée à sa suppression),
  /// ceux de la session rejointe sont programmés.
  void attach(AppStore next) {
    if (identical(next, app)) return;
    if (_bound) app.removeListener(_onStoreChange);
    app = next;
    _source = null;
    if (_bound) {
      next.addListener(_onStoreChange);
      unawaited(reschedule(force: true));
    }
  }

  void _onStoreChange() {
    final s = app.settings;
    final done =
        app.logs.entries.where((e) => e.value.done).map((e) => e.key).toList()
          ..sort();
    // Le départ fait partie de la signature : le changer replanifie les
    // mêmes identifiants S·J (pas de doublon), sans attendre un autre signal.
    final start = app.program.start;
    final signature =
        '${s.notifOn}|${s.notifHour}|${s.notifMinute}|${s.notifSkipRest}|'
        '${start == null ? '-' : civilDateString(start)}|$done';
    if (signature == _source) return;
    _source = signature;
    unawaited(reschedule());
  }

  void _fail(
    Object error, {
    int count = 0,
    DateTime? next,
    NotificationAccess? access,
  }) {
    debugPrint('Kalis notifications: $error');
    status.value = ReminderStatus(
      access: access ?? status.value.access,
      count: count,
      next: next,
      error:
          'Les rappels n’ont pas pu être entièrement programmés. Réessaie ci-dessous.',
      technicalError: error.toString(),
    );
  }

  Future<bool> requestPermission() async {
    try {
      await init();
      await backend.requestPermission();
      final access = await backend.access();
      status.value = ReminderStatus(access: access);
      return access.usable;
    } catch (e) {
      _fail(e);
      return false;
    }
  }

  Future<bool> requestExactPermission() async {
    try {
      await init();
      final granted = await backend.requestExactPermission();
      await reschedule(force: true);
      return granted;
    } catch (e) {
      _fail(e);
      return false;
    }
  }

  Future<void> reschedule({bool force = false}) {
    final revision = ++_revision;
    _queue = _queue.then((_) async {
      if (revision != _revision) return;
      if (force) _scheduled.clear();
      try {
        await _reschedule(revision);
      } catch (e) {
        _fail(e);
      }
    });
    return _queue;
  }

  static bool _ours(int id) =>
      (id >= 100 && id <= 106) || (id >= 1001 && id <= 1280);
  Future<void> _reschedule(int revision) async {
    status.value = ReminderStatus(access: status.value.access, busy: true);
    await init(); // Retente après un échec initial.
    final access = await backend.access();
    tz.Location? location;
    try {
      final name = await backend.timeZoneName();
      if (name != null) location = tz.getLocation(name);
    } catch (_) {} // Le repli DateTime local garde le bon instant.
    final planned = planReminders(app, now(), location: location);
    final desired = app.settings.notifOn && access.usable
        ? planned
        : <PlannedReminder>[];
    final ids = desired.map((r) => r.id).toSet();
    final pending = await backend.pendingIds();
    if (revision != _revision) return;
    // Ne détruit pas d'abord tous les rappels encore valides.
    for (final id in pending.where((id) => _ours(id) && !ids.contains(id))) {
      if (revision != _revision) return;
      await backend.cancel(id);
      _scheduled.remove(id);
    }
    var exact = access.exact;
    var count = 0;
    DateTime? next;
    Object? failure;
    for (final reminder in desired) {
      if (revision != _revision) return;
      try {
        final signature = '${reminder.signature}|$exact';
        if (_scheduled[reminder.id] != signature ||
            !pending.contains(reminder.id)) {
          try {
            await backend.schedule(reminder, exact: exact);
          } on PlatformException catch (e) {
            if (!exact || e.code != 'exact_alarms_not_permitted') rethrow;
            exact = false;
            await backend.schedule(reminder, exact: false);
          }
          _scheduled[reminder.id] = '${reminder.signature}|$exact';
        }
        count++;
        next ??= location == null ? reminder.at.toLocal() : reminder.at;
      } catch (e) {
        failure ??= e;
      }
    }
    if (revision != _revision) return;
    final effective = NotificationAccess(
      allowed: access.allowed,
      channelAllowed: access.channelAllowed,
      exact: exact,
    );
    if (failure != null) {
      _fail(failure, access: effective, count: count, next: next);
    } else {
      status.value = ReminderStatus(
        access: effective,
        count: count,
        next: next,
      );
    }
  }

  Future<bool> test({bool delayed = false}) async {
    try {
      await init();
      final access = await backend.access();
      if (!access.usable) {
        status.value = ReminderStatus(access: access);
        return false;
      }
      var exact = access.exact;
      if (delayed) {
        final at = tz.TZDateTime.from(
          now().add(const Duration(seconds: 15)),
          tz.UTC,
        );
        final reminder = PlannedReminder(
          reminderDelayedTestId,
          'Kalis Track · test différé',
          'Le rappel fonctionne aussi écran verrouillé.',
          '',
          at,
        );
        try {
          await backend.schedule(reminder, exact: exact);
        } on PlatformException catch (e) {
          if (!access.exact || e.code != 'exact_alarms_not_permitted') rethrow;
          exact = false;
          await backend.schedule(reminder, exact: false);
        }
      } else {
        await backend.showTest();
      }
      final previous = status.value;
      status.value = ReminderStatus(
        access: NotificationAccess(
          allowed: access.allowed,
          channelAllowed: access.channelAllowed,
          exact: exact,
        ),
        count: previous.count,
        next: previous.next,
        error: previous.error,
        technicalError: previous.technicalError,
      );
      return true;
    } catch (e) {
      _fail(e);
      return false;
    }
  }

  void dispose() {
    if (_bound) app.removeListener(_onStoreChange);
    status.dispose();
  }
}

class Notif {
  static final service = NotificationService(
    store,
    AndroidNotificationBackend(),
  );
  static ValueNotifier<ReminderStatus> get status => service.status;
  static set onOpen(void Function(int week, int day)? callback) =>
      service.onOpen = callback;
  static void bind() => service.bind();

  /// G1 : magasin de la session active (voir [NotificationService.attach]).
  static void attach(AppStore app) => service.attach(app);
  static Future<void> reschedule() => service.reschedule(force: true);
  static Future<bool> requestPermission() => service.requestPermission();
}
