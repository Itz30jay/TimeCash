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

enum ExpenseGroupBy { day, week, month }

class ExpenseGroup {
  final String title;
  final double total;
  final List<Expense> expenses;

  const ExpenseGroup({
    required this.title,
    required this.total,
    required this.expenses,
  });
}

class ExpenseProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notifService = NotificationService();
  final SettingsService _settings = SettingsService();

  List<Expense> _todayExpenses = [];
  List<Expense> _monthExpenses = [];
  List<Expense> _allExpenses = [];
  double _todayTotal = 0;
  double _monthTotal = 0;
  Map<String, double> _categoryTotals = {};
  List<Budget> _budgets = [];
  List<Map<String, dynamic>> _dailyTrend = [];
  bool _isLoading = false;

  List<Expense> get todayExpenses => _todayExpenses;
  List<Expense> get monthExpenses => _monthExpenses;
  List<Expense> get allExpenses => _allExpenses;
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
    try {
      _allExpenses = await _db.getAllExpenses();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading all expenses: $e');
    }
  }

  List<ExpenseGroup> groupExpenses(
      List<Expense> expenses, ExpenseGroupBy groupBy) {
    if (expenses.isEmpty) return [];

    final Map<String, List<Expense>> grouped = {};
    final Map<String, String> titles = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final currentWeekStart =
        today.subtract(Duration(days: today.weekday - 1));
    final lastWeekStart = currentWeekStart.subtract(const Duration(days: 7));

    for (final expense in expenses) {
      try {
        final dt = DateTimeHelper.parseDateFromDb(expense.date);
        final expenseDate = DateTime(dt.year, dt.month, dt.day);

        String key;
        String title;

        switch (groupBy) {
          case ExpenseGroupBy.day:
            key = expense.date;
            if (expenseDate == today) {
              title = 'Today • ${DateTimeHelper.formatDateShort(dt)}';
            } else if (expenseDate == yesterday) {
              title = 'Yesterday • ${DateTimeHelper.formatDateShort(dt)}';
            } else {
              title = DateTimeHelper.formatDate(dt);
            }
            break;

          case ExpenseGroupBy.week:
            final weekStart = expenseDate
                .subtract(Duration(days: expenseDate.weekday - 1));
            final weekEnd = weekStart.add(const Duration(days: 6));
            key = DateTimeHelper.formatDateForDb(weekStart);
            if (weekStart == currentWeekStart) {
              title =
                  'This Week • ${DateTimeHelper.formatDateShort(weekStart)} – ${DateTimeHelper.formatDateShort(weekEnd)}';
            } else if (weekStart == lastWeekStart) {
              title =
                  'Last Week • ${DateTimeHelper.formatDateShort(weekStart)} – ${DateTimeHelper.formatDateShort(weekEnd)}';
            } else {
              title =
                  '${DateTimeHelper.formatDateShort(weekStart)} – ${DateTimeHelper.formatDateShort(weekEnd)}';
            }
            break;

          case ExpenseGroupBy.month:
            key = DateTimeHelper.formatMonthForDb(dt);
            title = DateTimeHelper.formatMonth(dt);
            break;
        }

        grouped.putIfAbsent(key, () => []).add(expense);
        titles[key] = title;
      } catch (_) {
        grouped.putIfAbsent(expense.date, () => []).add(expense);
        titles[expense.date] = expense.date;
      }
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return sortedKeys.map((k) {
      final list = grouped[k]!;
      final total = list.fold<double>(0.0, (sum, e) => sum + e.amount);
      return ExpenseGroup(
        title: titles[k] ?? k,
        total: total,
        expenses: list,
      );
    }).toList();
  }

  List<ExpenseGroup> groupedByDay([List<Expense>? expenses]) =>
      groupExpenses(expenses ?? (allExpenses.isNotEmpty ? allExpenses : monthExpenses), ExpenseGroupBy.day);

  List<ExpenseGroup> groupedByWeek([List<Expense>? expenses]) =>
      groupExpenses(expenses ?? (allExpenses.isNotEmpty ? allExpenses : monthExpenses), ExpenseGroupBy.week);

  List<ExpenseGroup> groupedByMonth([List<Expense>? expenses]) =>
      groupExpenses(expenses ?? (allExpenses.isNotEmpty ? allExpenses : monthExpenses), ExpenseGroupBy.month);

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
    try {
      final now = DateTime.now();
      final prevMonth = DateTime(now.year, now.month - 1, 1);
      final month = DateTimeHelper.formatMonthForDb(prevMonth);
      return await _db.getTotalExpenseForMonth(month);
    } catch (e) {
      debugPrint('Error getting previous month total: $e');
      return 0.0;
    }
  }
}
