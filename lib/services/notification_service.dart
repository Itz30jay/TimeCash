/// Notification service for scheduling study reminders.
/// Handles Android notification channels, permissions, exact alarms,
/// and boot-completed rescheduling.
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timecash/models/task.dart';
import 'package:timecash/utils/constants.dart';

/// Background notification response handler (must be top-level)
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse details) {
  // Handled by the app when it opens
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _hasNotificationPermission = false;
  bool _hasExactAlarmPermission = false;

  bool get hasNotificationPermission => _hasNotificationPermission;
  bool get hasExactAlarmPermission => _hasExactAlarmPermission;

  // Callback for when a notification action is tapped
  Function(String? payload)? onNotificationTap;
  Function(String actionId, String? payload)? onNotificationAction;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (e) {
      debugPrint('Timezone error: $e');
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    }

    // Android settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS/macOS settings (for future support)
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      await _createStudyAlertChannel();
    }

    _initialized = true;
    await checkPermissions();
  }

  Future<void> _createStudyAlertChannel() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      const channel = AndroidNotificationChannel(
        AppConstants.studyAlertChannelId,
        AppConstants.studyAlertChannelName,
        description: AppConstants.studyAlertChannelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      );
      await androidPlugin.createNotificationChannel(channel);
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    if (response.actionId != null && response.actionId!.isNotEmpty) {
      onNotificationAction?.call(response.actionId!, response.payload);
    } else {
      onNotificationTap?.call(response.payload);
    }
  }

  // ─── Permission Management ────────────────────────────────────────────

  Future<void> checkPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        _hasNotificationPermission =
            await androidPlugin.areNotificationsEnabled() ?? false;

        // Check exact alarm permission (Android 12+)
        try {
          _hasExactAlarmPermission =
              await androidPlugin.canScheduleExactNotifications() ?? false;
        } catch (_) {
          _hasExactAlarmPermission = true; // Assume true on older Android
        }
      }
    } else {
      _hasNotificationPermission = true;
      _hasExactAlarmPermission = true;
    }
  }

  Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        _hasNotificationPermission = granted ?? false;
        return _hasNotificationPermission;
      }
    }
    return false;
  }

  Future<bool> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final granted =
            await androidPlugin.requestExactAlarmsPermission();
        _hasExactAlarmPermission = granted ?? false;
        return _hasExactAlarmPermission;
      }
    }
    return false;
  }

  // ─── Schedule Notifications ───────────────────────────────────────────

  /// Schedule a notification for a task
  Future<void> scheduleTaskNotification(Task task) async {
    if (!_initialized || !_hasNotificationPermission) return;
    if (task.id == null) return;

    final scheduledDate = task.startDateTime;
    if (scheduledDate.isBefore(DateTime.now())) return;

    final tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);

    // Build notification details based on notification type
    final androidDetails = _buildAndroidDetails(task);

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    // Use unique notification ID based on task ID
    final notifId = task.id!;

    try {
      if (_hasExactAlarmPermission) {
        await _plugin.zonedSchedule(
          notifId,
          '📚 Study Time',
          '${task.title}\n${task.startTime} – ${task.endTime}',
          tzScheduled,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'task:${task.id}',
        );
      } else {
        // Fallback to inexact scheduling
        await _plugin.zonedSchedule(
          notifId,
          '📚 Study Time',
          '${task.title}\n${task.startTime} – ${task.endTime}',
          tzScheduled,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'task:${task.id}',
        );
      }
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
    }
  }

  /// Schedule a pre-alert notification (X minutes before task)
  Future<void> schedulePreAlert(Task task, int minutesBefore) async {
    if (!_initialized || !_hasNotificationPermission) return;
    if (task.id == null) return;

    final preAlertTime =
        task.startDateTime.subtract(Duration(minutes: minutesBefore));
    if (preAlertTime.isBefore(DateTime.now())) return;

    final tzPreAlert = tz.TZDateTime.from(preAlertTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      AppConstants.studyAlertChannelId,
      AppConstants.studyAlertChannelName,
      channelDescription: AppConstants.studyAlertChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
    );

    // Use offset ID for pre-alert (task.id + 100000)
    final preAlertId = task.id! + 100000;

    try {
      final scheduleMode = _hasExactAlarmPermission
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      await _plugin.zonedSchedule(
        preAlertId,
        '⏰ Coming Up',
        '${task.title} starts in $minutesBefore minutes',
        tzPreAlert,
        notificationDetails,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'prealert:${task.id}',
      );
    } catch (e) {
      debugPrint('Failed to schedule pre-alert: $e');
    }
  }

  /// Build Android notification details based on task priority/type
  AndroidNotificationDetails _buildAndroidDetails(Task task) {
    final isAlarmStyle = task.notificationType == 'Alarm-style reminder';
    final isSilent = task.notificationType == 'Silent popup';

    return AndroidNotificationDetails(
      AppConstants.studyAlertChannelId,
      AppConstants.studyAlertChannelName,
      channelDescription: AppConstants.studyAlertChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      playSound: !isSilent,
      enableVibration: !isSilent,
      fullScreenIntent: isAlarmStyle || task.isCritical,
      category: isAlarmStyle
          ? AndroidNotificationCategory.alarm
          : AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      autoCancel: false,
      ongoing: false,
      actions: const [
        AndroidNotificationAction(
          'start_now',
          '▶ Start Now',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'snooze_10',
          '⏰ Snooze 10m',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          'done',
          '✓ Done',
          showsUserInterface: true,
        ),
      ],
    );
  }

  /// Snooze a task notification by rescheduling it
  Future<void> snoozeNotification(Task task, int minutes) async {
    if (!_initialized || task.id == null) return;

    // Cancel existing notification
    await cancelTaskNotification(task.id!);

    final snoozeTime = DateTime.now().add(Duration(minutes: minutes));
    final tzSnooze = tz.TZDateTime.from(snoozeTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      AppConstants.studyAlertChannelId,
      AppConstants.studyAlertChannelName,
      channelDescription: AppConstants.studyAlertChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    try {
      final scheduleMode = _hasExactAlarmPermission
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      await _plugin.zonedSchedule(
        task.id!,
        '📚 Snoozed Reminder',
        '${task.title}\nTime to study!',
        tzSnooze,
        notificationDetails,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'task:${task.id}',
      );
    } catch (e) {
      debugPrint('Failed to snooze notification: $e');
    }
  }

  /// Send a budget warning notification
  Future<void> showBudgetWarning(
      String category, double spent, double limit, String symbol) async {
    if (!_initialized || !_hasNotificationPermission) return;

    final percentage = ((spent / limit) * 100).round();
    final isOver = spent >= limit;

    await _plugin.show(
      category.hashCode + 200000,
      isOver ? '🚨 Budget Exceeded!' : '⚠️ Budget Warning',
      isOver
          ? '$category: $symbol${spent.toStringAsFixed(0)} / $symbol${limit.toStringAsFixed(0)} ($percentage%)'
          : '$category budget at $percentage% — $symbol${(limit - spent).toStringAsFixed(0)} remaining',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.studyAlertChannelId,
          AppConstants.studyAlertChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  // ─── Cancel Notifications ─────────────────────────────────────────────

  Future<void> cancelTaskNotification(int taskId) async {
    await _plugin.cancel(taskId);
    await _plugin.cancel(taskId + 100000); // Pre-alert
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  // ─── Reschedule All Notifications ─────────────────────────────────────

  /// Reschedule all future task notifications.
  /// Called after boot, timezone change, app update, or database change.
  Future<void> rescheduleAllNotifications(List<Task> futureTasks,
      {bool preAlertEnabled = false, int preAlertMinutes = 5}) async {
    if (!_initialized) return;

    await cancelAllNotifications();
    await checkPermissions();

    for (final task in futureTasks) {
      if (task.isUpcoming || task.isRunning) {
        await scheduleTaskNotification(task);
        if (preAlertEnabled) {
          await schedulePreAlert(task, preAlertMinutes);
        }
      }
    }
  }
}
