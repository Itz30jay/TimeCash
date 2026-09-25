/// Settings service using SharedPreferences for user preferences.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timecash/utils/constants.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    if (_prefs == null) throw StateError('SettingsService not initialized');
    return _prefs!;
  }

  // Onboarding
  bool get isOnboardingComplete =>
      _p.getBool(AppConstants.keyOnboardingComplete) ?? false;
  Future<void> setOnboardingComplete(bool value) =>
      _p.setBool(AppConstants.keyOnboardingComplete, value);

  // Currency
  String get currencySymbol =>
      _p.getString(AppConstants.keyCurrencySymbol) ?? AppConstants.defaultCurrency;
  String get currencyCode =>
      _p.getString(AppConstants.keyCurrencyCode) ?? AppConstants.defaultCurrencyCode;
  Future<void> setCurrency(String code, String symbol) async {
    await _p.setString(AppConstants.keyCurrencyCode, code);
    await _p.setString(AppConstants.keyCurrencySymbol, symbol);
  }

  // Monthly budget
  double get monthlyBudget =>
      _p.getDouble(AppConstants.keyMonthlyBudget) ??
      AppConstants.defaultMonthlyBudget;
  Future<void> setMonthlyBudget(double amount) =>
      _p.setDouble(AppConstants.keyMonthlyBudget, amount);

  // Theme
  ThemeMode get themeMode {
    final value = _p.getString(AppConstants.keyThemeMode) ?? 'system';
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    return _p.setString(AppConstants.keyThemeMode, value);
  }

  // Pre-alert
  bool get preAlertEnabled =>
      _p.getBool(AppConstants.keyPreAlertEnabled) ?? false;
  Future<void> setPreAlertEnabled(bool value) =>
      _p.setBool(AppConstants.keyPreAlertEnabled, value);

  int get preAlertMinutes =>
      _p.getInt(AppConstants.keyPreAlertMinutes) ??
      AppConstants.defaultPreAlertMinutes;
  Future<void> setPreAlertMinutes(int minutes) =>
      _p.setInt(AppConstants.keyPreAlertMinutes, minutes);

  // Next task notification
  bool get showNextTaskNotification =>
      _p.getBool(AppConstants.keyShowNextTaskNotification) ?? false;
  Future<void> setShowNextTaskNotification(bool value) =>
      _p.setBool(AppConstants.keyShowNextTaskNotification, value);
}
