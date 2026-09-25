/// Expense provider for state management.
/// Manages expense CRUD, budget tracking, and category analysis.
library;

import 'package:flutter/material.dart';
import 'package:timecash/models/expense.dart';
import 'package:timecash/models/budget.dart';
import 'package:timecash/services/database_service.dart';
import 'package:timecash/services/notification_service.dart';
import 'package:timecash/services/settings_service.dart';
import 'package:timecash/utils/helpers.dart';

class ExpenseProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notifService = NotificationService();
  final SettingsService _settings = SettingsService();

  List<Expense> _todayExpenses = [];
  List<Expense> _monthExpenses = [];
  double _todayTotal = 0;
  double _monthTotal = 0;
  Map<String, double> _categoryTotals = {};
  List<Budget> _budgets = [];
  List<Map<String, dynamic>> _dailyTrend = [];
  bool _isLoading = false;

  List<Expense> get todayExpenses => _todayExpenses;
  List<Expense> get monthExpenses => _monthExpenses;
  double get todayTotal => _todayTotal;
  double get monthTotal => _monthTotal;
  Map<String, double> get categoryTotals => _categoryTotals;
  List<Budget> get budgets => _budgets;
  List<Map<String, dynamic>> get dailyTrend => _dailyTrend;
  bool get isLoading => _isLoading;

  String get topCategory {
    if (_categoryTotals.isEmpty) return 'None';
    return _categoryTotals.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  double get dailyAverage {
    if (_monthExpenses.isEmpty) return 0;
    final now = DateTime.now();
    final daysInMonth = now.day;
    return _monthTotal / daysInMonth;
  }

  double get monthlyBudget => _settings.monthlyBudget;

  double get budgetRemaining {
    final budget = _settings.monthlyBudget;
    if (budget <= 0) return 0;
    return budget - _monthTotal;
  }

  double get budgetPercentage {
    final budget = _settings.monthlyBudget;
    if (budget <= 0) return 0;
    return (_monthTotal / budget).clamp(0, 2);
  }

  Future<void> loadTodayExpenses() async {
    _isLoading = true;
    notifyListeners();

    try {
      final today = DateTimeHelper.formatDateForDb(DateTime.now());
      _todayExpenses = await _db.getExpensesByDate(today);
      _todayTotal = await _db.getTotalExpenseForDate(today);
    } catch (e) {
      debugPrint('Error loading today expenses: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMonthExpenses() async {
    try {
      final month = DateTimeHelper.formatMonthForDb(DateTime.now());
      _monthExpenses = await _db.getExpensesByMonth(month);
      _monthTotal = await _db.getTotalExpenseForMonth(month);
      _categoryTotals = await _db.getExpensesByCategory(month);
      _budgets = await _db.getBudgetsForMonth(month);
      _dailyTrend = await _db.getDailyExpenseTrend(30);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading month expenses: $e');
    }
  }

  Future<void> loadAll() async {
    await loadTodayExpenses();
    await loadMonthExpenses();
  }

  Future<bool> addExpense(Expense expense) async {
    try {
      await _db.insertExpense(expense);
      await loadAll();

      // Check budget warnings
      await _checkBudgetWarnings(expense.category);

      return true;
    } catch (e) {
      debugPrint('Error adding expense: $e');
      return false;
    }
  }

  Future<bool> updateExpense(Expense expense) async {
    try {
      await _db.updateExpense(expense);
      await loadAll();
      return true;
    } catch (e) {
      debugPrint('Error updating expense: $e');
      return false;
    }
  }

  Future<bool> deleteExpense(int id) async {
    try {
      await _db.deleteExpense(id);
      await loadAll();
      return true;
    } catch (e) {
      debugPrint('Error deleting expense: $e');
      return false;
    }
  }

  Future<List<Expense>> getExpensesForDateRange(
      DateTime start, DateTime end) async {
    return _db.getExpensesByDateRange(
      DateTimeHelper.formatDateForDb(start),
      DateTimeHelper.formatDateForDb(end),
    );
  }

  Future<List<Expense>> getAllExpenses() async {
    return _db.getAllExpenses();
  }

  // Budget management
  Future<void> setBudget(
      String category, double limit, String month) async {
    final budget = Budget(
      category: category,
      monthlyLimit: limit,
      month: month,
    );
    await _db.insertOrUpdateBudget(budget);
    await loadMonthExpenses();
  }

  Budget? getBudgetForCategory(String category) {
    try {
      return _budgets.firstWhere((b) => b.category == category);
    } catch (_) {
      return null;
    }
  }

  Future<void> _checkBudgetWarnings(String category) async {
    final symbol = _settings.currencySymbol;
    final month = DateTimeHelper.formatMonthForDb(DateTime.now());

    // Check category budget
    final catBudget = await _db.getBudgetForCategory(category, month);
    if (catBudget != null) {
      final catSpent = _categoryTotals[category] ?? 0;
      final catPercent = catSpent / catBudget.monthlyLimit;
      if (catPercent >= 1.0) {
        await _notifService.showBudgetWarning(
            category, catSpent, catBudget.monthlyLimit, symbol);
      } else if (catPercent >= 0.8) {
        await _notifService.showBudgetWarning(
            category, catSpent, catBudget.monthlyLimit, symbol);
      }
    }

    // Check overall budget
    final overall = _settings.monthlyBudget;
    if (overall > 0) {
      final overallPercent = _monthTotal / overall;
      if (overallPercent >= 1.0) {
        await _notifService.showBudgetWarning(
            'Overall', _monthTotal, overall, symbol);
      } else if (overallPercent >= 0.8) {
        await _notifService.showBudgetWarning(
            'Overall', _monthTotal, overall, symbol);
      }
    }
  }

  /// Get "most expensive day" in current month
  String getMostExpensiveDay() {
    if (_dailyTrend.isEmpty) return 'N/A';
    Map<String, dynamic>? maxDay;
    double maxAmount = 0;
    for (final day in _dailyTrend) {
      final amount = (day['total'] as num).toDouble();
      if (amount > maxAmount) {
        maxAmount = amount;
        maxDay = day;
      }
    }
    if (maxDay == null) return 'N/A';
    try {
      final date = DateTimeHelper.parseDateFromDb(maxDay['date'] as String);
      return DateTimeHelper.formatDateShort(date);
    } catch (_) {
      return maxDay['date']?.toString() ?? 'N/A';
    }
  }

  /// Previous month comparison
  Future<double> getPreviousMonthTotal() async {
    final now = DateTime.now();
    final prevMonth = DateTime(now.year, now.month - 1, 1);
    final month = DateTimeHelper.formatMonthForDb(prevMonth);
    return _db.getTotalExpenseForMonth(month);
  }
}
