/// Settings provider for theme and app settings state management.
library;

import 'package:flutter/material.dart';
import 'package:timecash/services/settings_service.dart';
import 'package:timecash/services/notification_service.dart';
import 'package:timecash/utils/constants.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _settings = SettingsService();
  final NotificationService _notifService = NotificationService();

  ThemeMode _themeMode = ThemeMode.system;
  String _currencySymbol = '₹';
  String _currencyCode = 'INR';
  double _monthlyBudget = 0;
  bool _preAlertEnabled = false;
  int _preAlertMinutes = 5;
  bool _showNextTaskNotification = false;
  bool _hasNotificationPermission = false;
  bool _hasExactAlarmPermission = false;
  String _userName = '';
  String _userRole = AppConstants.roleStudent;

  ThemeMode get themeMode => _themeMode;
  String get currencySymbol => _currencySymbol;
  String get currencyCode => _currencyCode;
  double get monthlyBudget => _monthlyBudget;
  bool get preAlertEnabled => _preAlertEnabled;
  int get preAlertMinutes => _preAlertMinutes;
  bool get showNextTaskNotification => _showNextTaskNotification;
  bool get hasNotificationPermission => _hasNotificationPermission;
  bool get hasExactAlarmPermission => _hasExactAlarmPermission;
  String get userName => _userName;
  String get userRole => _userRole;

  Future<void> loadSettings() async {
    _themeMode = _settings.themeMode;
    _currencySymbol = _settings.currencySymbol;
    _currencyCode = _settings.currencyCode;
    _monthlyBudget = _settings.monthlyBudget;
    _preAlertEnabled = _settings.preAlertEnabled;
    _preAlertMinutes = _settings.preAlertMinutes;
    _showNextTaskNotification = _settings.showNextTaskNotification;
    _userName = _settings.userName;
    _userRole = _settings.userRole;

    await refreshPermissions();
    notifyListeners();
  }

  Future<void> refreshPermissions() async {
    await _notifService.checkPermissions();
    _hasNotificationPermission = _notifService.hasNotificationPermission;
    _hasExactAlarmPermission = _notifService.hasExactAlarmPermission;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _settings.setThemeMode(mode);
    notifyListeners();
  }

  Future<void> setCurrency(String code, String symbol) async {
    _currencyCode = code;
    _currencySymbol = symbol;
    await _settings.setCurrency(code, symbol);
    notifyListeners();
  }

  Future<void> setMonthlyBudget(double amount) async {
    _monthlyBudget = amount;
    await _settings.setMonthlyBudget(amount);
    notifyListeners();
  }

  Future<void> setPreAlertEnabled(bool enabled) async {
    _preAlertEnabled = enabled;
    await _settings.setPreAlertEnabled(enabled);
    notifyListeners();
  }

  Future<void> setPreAlertMinutes(int minutes) async {
    _preAlertMinutes = minutes;
    await _settings.setPreAlertMinutes(minutes);
    notifyListeners();
  }

  Future<void> setShowNextTaskNotification(bool show) async {
    _showNextTaskNotification = show;
    await _settings.setShowNextTaskNotification(show);
    notifyListeners();
  }

  Future<void> setUserName(String name) async {
    _userName = name;
    await _settings.setUserName(name);
    notifyListeners();
  }

  Future<void> setUserRole(String role) async {
    _userRole = role;
    await _settings.setUserRole(role);
    notifyListeners();
  }

  Future<bool> requestNotificationPermission() async {
    final granted = await _notifService.requestNotificationPermission();
    _hasNotificationPermission = granted;
    notifyListeners();
    return granted;
  }

  Future<bool> requestExactAlarmPermission() async {
    final granted = await _notifService.requestExactAlarmPermission();
    _hasExactAlarmPermission = granted;
    notifyListeners();
    return granted;
  }
}
