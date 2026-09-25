/// Task provider for state management using ChangeNotifier.
/// Manages task CRUD, status updates, and notification scheduling.
library;

import 'package:flutter/material.dart';
import 'package:timecash/models/task.dart';
import 'package:timecash/services/database_service.dart';
import 'package:timecash/services/notification_service.dart';
import 'package:timecash/services/settings_service.dart';
import 'package:timecash/utils/helpers.dart';

class TaskProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notifService = NotificationService();
  final SettingsService _settings = SettingsService();

  List<Task> _todayTasks = [];
  List<Task> _weekTasks = [];
  List<Task> _allTasks = [];
  Task? _nextTask;
  bool _isLoading = false;
  Map<String, int> _todayStats = {};
  Map<String, int> _monthStats = {};

  int _currentStreak = 0;
  int _bestStreak = 0;
  int _totalStudyMinutes = 0;

  List<Task> get todayTasks => _todayTasks;
  List<Task> get weekTasks => _weekTasks;
  List<Task> get allTasks => _allTasks;
  Task? get nextTask => _nextTask;
  bool get isLoading => _isLoading;
  Map<String, int> get todayStats => _todayStats;
  Map<String, int> get monthStats => _monthStats;

  int get currentStreak => _currentStreak;
  int get bestStreak => _bestStreak;
  int get totalStudyMinutes => _totalStudyMinutes;
  double get totalStudyHours => _totalStudyMinutes / 60.0;

  int get todayTotal =>
      _todayStats.values.fold(0, (sum, count) => sum + count);
  int get todayCompleted => _todayStats['Completed'] ?? 0;
  int get todayMissed => _todayStats['Missed'] ?? 0;
  double get todayCompletionRate =>
      todayTotal > 0 ? todayCompleted / todayTotal : 0;

  int get monthTotal =>
      _monthStats.values.fold(0, (sum, count) => sum + count);
  int get monthCompleted => _monthStats['Completed'] ?? 0;

  Future<void> loadTodayTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Mark overdue tasks
      await _db.markOverdueTasks();

      final today = DateTimeHelper.formatDateForDb(DateTime.now());
      _todayTasks = await _db.getTasksByDate(today);
      _todayStats = await _db.getTaskStatsForDate(today);

      // Update running status for current time
      await _updateRunningStatus();

      // Find next upcoming task
      _findNextTask();

      // Load month stats
      final month = DateTimeHelper.formatMonthForDb(DateTime.now());
      _monthStats = await _db.getTaskStatsForMonth(month);

      // Load study streak stats
      final streakStats = await _db.getStudyStreakStats();
      _currentStreak = streakStats['currentStreak'] as int? ?? 0;
      _bestStreak = streakStats['bestStreak'] as int? ?? 0;
      _totalStudyMinutes = streakStats['totalStudyMinutes'] as int? ?? 0;
    } catch (e) {
      debugPrint('Error loading today tasks: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadWeekTasks(DateTime weekStart) async {
    try {
      final start = DateTimeHelper.formatDateForDb(weekStart);
      final end = DateTimeHelper.formatDateForDb(
          weekStart.add(const Duration(days: 6)));
      _weekTasks = await _db.getTasksByDateRange(start, end);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading week tasks: $e');
    }
  }

  Future<void> loadAllTasks() async {
    try {
      _allTasks = await _db.getAllTasks();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading all tasks: $e');
    }
  }

  Future<List<Task>> getTasksForDate(DateTime date) async {
    return _db.getTasksByDate(DateTimeHelper.formatDateForDb(date));
  }

  Future<Task?> addTask(Task task) async {
    try {
      final id = await _db.insertTask(task);
      final newTask = task.copyWith(id: id);

      // Schedule notification
      await _notifService.scheduleTaskNotification(newTask);
      if (_settings.preAlertEnabled) {
        await _notifService.schedulePreAlert(
            newTask, _settings.preAlertMinutes);
      }

      await loadTodayTasks();
      return newTask;
    } catch (e) {
      debugPrint('Error adding task: $e');
      return null;
    }
  }

  Future<bool> updateTask(Task task) async {
    try {
      await _db.updateTask(task);

      // Reschedule notification
      if (task.id != null) {
        await _notifService.cancelTaskNotification(task.id!);
        if (task.isUpcoming) {
          await _notifService.scheduleTaskNotification(task);
          if (_settings.preAlertEnabled) {
            await _notifService.schedulePreAlert(
                task, _settings.preAlertMinutes);
          }
        }
      }

      await loadTodayTasks();
      return true;
    } catch (e) {
      debugPrint('Error updating task: $e');
      return false;
    }
  }

  Future<bool> deleteTask(int id) async {
    try {
      await _notifService.cancelTaskNotification(id);
      await _db.deleteTask(id);
      await loadTodayTasks();
      return true;
    } catch (e) {
      debugPrint('Error deleting task: $e');
      return false;
    }
  }

  Future<bool> completeTask(int id) async {
    try {
      await _db.updateTaskStatus(id, 'Completed');
      await _notifService.cancelTaskNotification(id);
      await loadTodayTasks();
      return true;
    } catch (e) {
      debugPrint('Error completing task: $e');
      return false;
    }
  }

  Future<bool> skipTask(int id) async {
    try {
      await _db.updateTaskStatus(id, 'Skipped');
      await _notifService.cancelTaskNotification(id);
      await loadTodayTasks();
      return true;
    } catch (e) {
      debugPrint('Error skipping task: $e');
      return false;
    }
  }

  Future<bool> startTask(int id) async {
    try {
      await _db.updateTaskStatus(id, 'Running');
      await loadTodayTasks();
      return true;
    } catch (e) {
      debugPrint('Error starting task: $e');
      return false;
    }
  }

  Future<Task?> duplicateTask(Task task) async {
    final duplicate = task.copyWith(
      id: null,
      status: 'Upcoming',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    return addTask(duplicate);
  }

  Future<void> snoozeTask(Task task, int minutes) async {
    try {
      await _notifService.snoozeNotification(task, minutes);
    } catch (e) {
      debugPrint('Error snoozing task: $e');
    }
  }

  /// Check for overlapping tasks
  Future<List<Task>> checkOverlaps(Task newTask) async {
    final dayTasks =
        await _db.getTasksByDate(newTask.date);
    return dayTasks
        .where((t) => t.id != newTask.id && t.overlapsWith(newTask))
        .toList();
  }

  /// Generate recurring task instances for future dates
  Future<void> generateRecurringInstances(Task baseTask, int daysAhead) async {
    if (baseTask.repeatType == 'Once') return;

    final startDate = DateTimeHelper.parseDateFromDb(baseTask.date);
    final now = DateTime.now().toIso8601String();

    for (int i = 1; i <= daysAhead; i++) {
      final futureDate = startDate.add(Duration(days: i));
      final shouldCreate = _shouldCreateForDate(baseTask, futureDate);

      if (shouldCreate) {
        final instance = baseTask.copyWith(
          id: null,
          date: DateTimeHelper.formatDateForDb(futureDate),
          status: 'Upcoming',
          repeatType: 'Once', // Instances are individual
          createdAt: now,
          updatedAt: now,
        );
        await addTask(instance);
      }
    }
  }

  bool _shouldCreateForDate(Task task, DateTime date) {
    switch (task.repeatType) {
      case 'Daily':
        return true;
      case 'Weekdays':
        return date.weekday >= 1 && date.weekday <= 5;
      case 'Weekly':
        return date.weekday ==
            DateTimeHelper.parseDateFromDb(task.date).weekday;
      case 'Custom':
        if (task.repeatDays == null) return false;
        final days =
            task.repeatDays!.split(',').map((d) => int.tryParse(d.trim()));
        return days.contains(date.weekday);
      default:
        return false;
    }
  }

  void _findNextTask() {
    final now = DateTime.now();
    _nextTask = null;

    for (final task in _todayTasks) {
      if (task.isUpcoming && task.startDateTime.isAfter(now)) {
        _nextTask = task;
        break;
      }
    }

    // If no upcoming task today, also check running
    if (_nextTask == null) {
      for (final task in _todayTasks) {
        if (task.isRunning) {
          _nextTask = task;
          break;
        }
      }
    }
  }

  Future<void> _updateRunningStatus() async {
    final now = DateTime.now();
    for (final task in _todayTasks) {
      if (task.isUpcoming &&
          task.startDateTime.isBefore(now) &&
          task.endDateTime.isAfter(now)) {
        await _db.updateTaskStatus(task.id!, 'Running');
      }
    }
    // Reload after status updates
    final today = DateTimeHelper.formatDateForDb(DateTime.now());
    _todayTasks = await _db.getTasksByDate(today);
    _todayStats = await _db.getTaskStatsForDate(today);
  }

  /// Reschedule all future notifications (after boot, timezone change, etc.)
  Future<void> rescheduleAllNotifications() async {
    final upcoming = await _db.getUpcomingTasks();
    await _notifService.rescheduleAllNotifications(
      upcoming,
      preAlertEnabled: _settings.preAlertEnabled,
      preAlertMinutes: _settings.preAlertMinutes,
    );
  }
}
