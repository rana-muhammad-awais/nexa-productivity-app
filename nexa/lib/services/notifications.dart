import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/constants.dart';
import '../data/models.dart';
import '../core/utils.dart';

/// Full-featured local notification engine.
/// Handles scheduled reminders for: tasks, budget alerts, renewal warnings,
/// khata payment reminders, habit reminders, and daily morning briefs.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ─── Channel IDs ────────────────────────────────────────────────────
  static const _chTask = 'nexa.tasks';
  static const _chBudget = 'nexa.budgets';
  static const _chRenewal = 'nexa.renewals';
  static const _chKhata = 'nexa.khata';
  static const _chHabit = 'nexa.habits';
  static const _chGeneral = 'nexa.general';

  // ID ranges to avoid collisions: tasks 10000+, renewals 20000+, budgets 30000+, habits 40000+, khata 50000+
  static const _taskBase = 10000;
  static const _renewalBase = 20000;
  static const _budgetBase = 30000;
  static const _habitBase = 40000;
  static const _khataBase = 50000;
  static const _dailyBriefId = 1;

  // ─── Initialization ─────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const init = InitializationSettings(android: androidInit, iOS: iosInit);
      await _plugin.initialize(init);
      await _createChannels();
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService.init failed: $e');
    }
  }

  Future<void> _createChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    final channels = [
      const AndroidNotificationChannel(
        _chTask, 'Task Reminders',
        description: 'Reminders for tasks due today or at specific times',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        _chBudget, 'Budget Alerts',
        description: 'Alerts when spending approaches or exceeds budget limits',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        _chRenewal, 'Renewal Reminders',
        description: 'Alerts before subscriptions and documents expire',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        _chKhata, 'Khata Reminders',
        description: 'Payment collection reminders for outstanding balances',
        importance: Importance.defaultImportance,
      ),
      const AndroidNotificationChannel(
        _chHabit, 'Habit Reminders',
        description: 'Daily habit check-in reminders',
        importance: Importance.defaultImportance,
      ),
      const AndroidNotificationChannel(
        _chGeneral, 'General',
        description: 'General notifications and daily briefs',
        importance: Importance.defaultImportance,
      ),
    ];

    for (final ch in channels) {
      try {
        await android.createNotificationChannel(ch);
      } catch (_) {}
    }
  }

  // ─── Request Permission (Android 13+) ───────────────────────────────
  Future<bool> requestPermission() async {
    if (!_initialized) await init();
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? true;
    } catch (_) {
      return false;
    }
  }

  // ─── Task Reminders ─────────────────────────────────────────────────
  /// Schedule a notification for a task at its due date/time.
  /// Uses the hashCode of taskId to generate a stable notification ID.
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    String? dueDate,
    String? dueTime,
  }) async {
    if (!_initialized) await init();
    if (dueDate == null) return;

    try {
      final parts = dueDate.split('-');
      if (parts.length != 3) return;
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      int hour = 9, minute = 0; // Default to 9 AM
      if (dueTime != null && dueTime.contains(':')) {
        final tp = dueTime.split(':');
        hour = int.parse(tp[0]);
        minute = int.parse(tp[1]);
      }

      final scheduled = tz.TZDateTime(tz.local, year, month, day, hour, minute);

      // Don't schedule if in the past
      if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

      final id = _taskBase + (taskId.hashCode.abs() % 9999);

      await _plugin.zonedSchedule(
        id,
        '📋 Task Reminder',
        title,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _chTask, 'Task Reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('scheduleTaskReminder failed: $e');
    }
  }

  /// Cancel a task reminder.
  Future<void> cancelTaskReminder(String taskId) async {
    if (!_initialized) return;
    try {
      final id = _taskBase + (taskId.hashCode.abs() % 9999);
      await _plugin.cancel(id);
    } catch (_) {}
  }

  // ─── Renewal / Expiry Reminders ─────────────────────────────────────
  /// Schedule reminders for resource renewals/expiries.
  /// Fires 3 days before and 1 day before.
  Future<void> scheduleRenewalReminder({
    required String resourceId,
    required String name,
    required String? renewalDate,
    bool isExpiry = false,
  }) async {
    if (!_initialized) await init();
    if (renewalDate == null) return;

    try {
      final days = daysUntil(renewalDate);
      if (days == null || days < 0) return;

      final baseId = _renewalBase + (resourceId.hashCode.abs() % 9999);
      final label = isExpiry ? 'expires' : 'renews';
      final emoji = isExpiry ? '📄' : '🔄';

      // 3 days before
      if (days >= 3) {
        final parts = renewalDate.split('-');
        final dt = DateTime(
            int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        final threeBefore = dt.subtract(const Duration(days: 3));
        final scheduled =
            tz.TZDateTime(tz.local, threeBefore.year, threeBefore.month, threeBefore.day, 9, 0);

        if (scheduled.isAfter(tz.TZDateTime.now(tz.local))) {
          await _plugin.zonedSchedule(
            baseId,
            '$emoji $name $label soon',
            '$name $label in 3 days',
            scheduled,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                _chRenewal, 'Renewal Reminders',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }

      // 1 day before
      if (days >= 1) {
        final parts = renewalDate.split('-');
        final dt = DateTime(
            int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        final oneBefore = dt.subtract(const Duration(days: 1));
        final scheduled =
            tz.TZDateTime(tz.local, oneBefore.year, oneBefore.month, oneBefore.day, 9, 0);

        if (scheduled.isAfter(tz.TZDateTime.now(tz.local))) {
          await _plugin.zonedSchedule(
            baseId + 1,
            '$emoji $name $label tomorrow!',
            '$name $label tomorrow. Take action now.',
            scheduled,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                _chRenewal, 'Renewal Reminders',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }
    } catch (e) {
      debugPrint('scheduleRenewalReminder failed: $e');
    }
  }

  Future<void> cancelRenewalReminder(String resourceId) async {
    if (!_initialized) return;
    try {
      final baseId = _renewalBase + (resourceId.hashCode.abs() % 9999);
      await _plugin.cancel(baseId);
      await _plugin.cancel(baseId + 1);
    } catch (_) {}
  }

  // ─── Budget Alerts ──────────────────────────────────────────────────
  /// Show immediate budget alert (triggered when spending crosses threshold).
  Future<void> showBudgetAlert({
    required String category,
    required double spent,
    required double limit,
    required String currency,
    required int percent,
  }) async {
    if (!_initialized) await init();
    try {
      final id = _budgetBase + (category.hashCode.abs() % 9999);
      final emoji = percent >= 100 ? '🚨' : '⚠️';
      final status = percent >= 100 ? 'exceeded' : 'approaching limit';

      await _plugin.show(
        id,
        '$emoji Budget $status: $category',
        'Spent ${formatCurrency(spent, currency)} of ${formatCurrency(limit, currency)} ($percent%)',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _chBudget, 'Budget Alerts',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (e) {
      debugPrint('showBudgetAlert failed: $e');
    }
  }

  // ─── Khata Payment Reminder ─────────────────────────────────────────
  /// Show immediate reminder for outstanding khata balance.
  Future<void> showKhataReminder({
    required String personName,
    required double balance,
    required String currency,
  }) async {
    if (!_initialized) await init();
    try {
      final id = _khataBase + (personName.hashCode.abs() % 9999);
      await _plugin.show(
        id,
        '💰 Payment Reminder: $personName',
        '$personName owes you ${formatCurrency(balance, currency)}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _chKhata, 'Khata Reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (e) {
      debugPrint('showKhataReminder failed: $e');
    }
  }

  // ─── Habit Reminder ─────────────────────────────────────────────────
  /// Schedule daily repeating habit reminder at a specific time.
  Future<void> scheduleHabitReminder({
    required String habitId,
    required String habitName,
    required String time, // HH:mm
  }) async {
    if (!_initialized) await init();
    try {
      final parts = time.split(':');
      if (parts.length != 2) return;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      final id = _habitBase + (habitId.hashCode.abs() % 9999);

      await _plugin.zonedSchedule(
        id,
        '✅ Habit Reminder',
        "Don't forget: $habitName",
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _chHabit, 'Habit Reminders',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      );
    } catch (e) {
      debugPrint('scheduleHabitReminder failed: $e');
    }
  }

  Future<void> cancelHabitReminder(String habitId) async {
    if (!_initialized) return;
    try {
      final id = _habitBase + (habitId.hashCode.abs() % 9999);
      await _plugin.cancel(id);
    } catch (_) {}
  }

  // ─── Daily Brief ────────────────────────────────────────────────────
  /// Show immediate daily brief with summary info.
  Future<void> showDailyBrief({
    required List<Task> tasks,
    required List<Resource> renewals,
    required double monthSpend,
    required String currency,
  }) async {
    if (!_initialized) await init();
    try {
      final due = tasks
          .where((t) => !t.isCompleted && t.dueDate == todayIsoDate())
          .length;
      final upcomingRenewal = renewals.isEmpty
          ? null
          : renewals.reduce((a, b) =>
              (daysUntil(a.renewalDate) ?? 99) <=
                      (daysUntil(b.renewalDate) ?? 99)
                  ? a
                  : b);
      final days = daysUntil(upcomingRenewal?.renewalDate);

      final lines = <String>[
        if (due > 0)
          '$due task${due > 1 ? 's' : ''} due today'
        else
          'No tasks due today ✨',
        'Spent ${formatCurrency(monthSpend, currency)} this month',
        if (upcomingRenewal != null && days != null)
          '${upcomingRenewal.name} renews ${days == 0 ? 'today' : 'in $days day${days == 1 ? '' : 's'}'}',
      ];

      await _plugin.show(
        _dailyBriefId,
        '☀️ Your daily brief',
        lines.join('  ·  '),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _chGeneral, 'General',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (e) {
      debugPrint('showDailyBrief failed: $e');
    }
  }

  // ─── Inventory Low Stock Alert ──────────────────────────────────────
  Future<void> showLowStockAlert({
    required String name,
    required int quantity,
    required int threshold,
  }) async {
    if (!_initialized) await init();
    try {
      await _plugin.show(
        _renewalBase + 5000 + (name.hashCode.abs() % 4999),
        '📦 Low Stock: $name',
        'Only $quantity left (threshold: $threshold)',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _chRenewal, 'Renewal Reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (e) {
      debugPrint('showLowStockAlert failed: $e');
    }
  }

  // ─── Bulk Reschedule ────────────────────────────────────────────────
  /// Reschedule all notifications based on current app data.
  /// Call this on app startup and after data import.
  Future<void> rescheduleAll(AppData data) async {
    if (!_initialized) await init();
    try {
      await _plugin.cancelAll();

      // Reschedule task reminders
      for (final task in data.tasks) {
        if (!task.isCompleted && task.dueDate != null) {
          await scheduleTaskReminder(
            taskId: task.id,
            title: task.title,
            dueDate: task.dueDate,
            dueTime: task.dueTime,
          );
        }
      }

      // Reschedule renewal reminders
      for (final resource in data.resources) {
        if (resource.renewalDate != null) {
          await scheduleRenewalReminder(
            resourceId: resource.id,
            name: resource.name,
            renewalDate: resource.renewalDate,
            isExpiry: resource.type == ResourceType.document,
          );
        }
      }
    } catch (e) {
      debugPrint('rescheduleAll failed: $e');
    }
  }

  // ─── Cancel All ─────────────────────────────────────────────────────
  Future<void> cancelAll() async {
    if (!_initialized) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
