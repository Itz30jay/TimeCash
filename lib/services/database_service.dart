/// Local SQLite database service for all app data.
/// Handles tasks, expenses, budgets, and settings storage.
library;

import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flowra/models/task.dart';
import 'package:flowra/models/expense.dart';
import 'package:flowra/models/budget.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'flowra.db');
    final oldPath = join(dbPath, 'timecash.db');

    try {
      if (!await databaseExists(path) && await databaseExists(oldPath)) {
        final oldFile = File(oldPath);
        if (await oldFile.exists()) {
          await oldFile.copy(path);
        }
      }
    } catch (_) {}

    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        subject TEXT,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        date TEXT NOT NULL,
        repeat_type TEXT NOT NULL DEFAULT 'Once',
        repeat_days TEXT,
        priority TEXT NOT NULL DEFAULT 'Normal',
        notification_type TEXT NOT NULL DEFAULT 'Sound + vibration',
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'Upcoming',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        payment_method TEXT,
        date TEXT NOT NULL,
        time TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        monthly_limit REAL NOT NULL,
        month TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_tasks_date ON tasks(date)');
    await db.execute('CREATE INDEX idx_tasks_status ON tasks(status)');
    await db.execute('CREATE INDEX idx_expenses_date ON expenses(date)');
    await db.execute('CREATE INDEX idx_expenses_category ON expenses(category)');
    await db.execute('CREATE INDEX idx_budgets_month ON budgets(month)');
    await db.execute(
        'CREATE UNIQUE INDEX idx_budgets_cat_month ON budgets(category, month)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE expenses ADD COLUMN time TEXT');
    }
  }

  // ─── Task Operations ──────────────────────────────────────────────────

  Future<int> insertTask(Task task) async {
    final db = await database;
    return db.insert('tasks', task.toMap());
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<Task?> getTaskById(int id) async {
    final db = await database;
    final maps = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Task.fromMap(maps.first);
  }

  Future<List<Task>> getTasksByDate(String date) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'start_time ASC',
    );
    return maps.map((m) => Task.fromMap(m)).toList();
  }

  Future<List<Task>> getTasksByDateRange(String startDate, String endDate) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC, start_time ASC',
    );
    return maps.map((m) => Task.fromMap(m)).toList();
  }

  Future<List<Task>> getUpcomingTasks() async {
    final db = await database;
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final maps = await db.query(
      'tasks',
      where: "date >= ? AND status IN ('Upcoming', 'Running')",
      whereArgs: [today],
      orderBy: 'date ASC, start_time ASC',
      limit: 20,
    );
    return maps.map((m) => Task.fromMap(m)).toList();
  }

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final maps = await db.query('tasks', orderBy: 'date DESC, start_time ASC');
    return maps.map((m) => Task.fromMap(m)).toList();
  }

  Future<int> updateTaskStatus(int id, String status) async {
    final db = await database;
    return db.update(
      'tasks',
      {'status': status, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, int>> getTaskStatsForDate(String date) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM tasks
      WHERE date = ?
      GROUP BY status
    ''', [date]);

    final stats = <String, int>{};
    for (final row in maps) {
      stats[row['status'] as String] = row['count'] as int;
    }
    return stats;
  }

  Future<Map<String, int>> getTaskStatsForMonth(String month) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM tasks
      WHERE date LIKE ?
      GROUP BY status
    ''', ['$month%']);

    final stats = <String, int>{};
    for (final row in maps) {
      stats[row['status'] as String] = row['count'] as int;
    }
    return stats;
  }

  // Mark overdue tasks as Missed
  Future<int> markOverdueTasks() async {
    final db = await database;
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return db.update(
      'tasks',
      {'status': 'Missed', 'updated_at': now.toIso8601String()},
      where:
          "(date < ? OR (date = ? AND end_time <= ?)) AND status IN ('Upcoming', 'Running')",
      whereArgs: [today, today, currentTime],
    );
  }

  /// Calculate study streak and habit statistics
  Future<Map<String, dynamic>> getStudyStreakStats() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT DISTINCT date
      FROM tasks
      WHERE status = 'Completed'
      ORDER BY date DESC
    ''');

    if (maps.isEmpty) {
      return {
        'currentStreak': 0,
        'bestStreak': 0,
        'totalCompleted': 0,
        'totalStudyMinutes': 0,
      };
    }

    final dates = maps
        .map((m) => DateTime.tryParse(m['date'] as String))
        .where((d) => d != null)
        .cast<DateTime>()
        .toList();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    int currentStreak = 0;
    if (dates.isNotEmpty) {
      final mostRecent =
          DateTime(dates.first.year, dates.first.month, dates.first.day);
      if (mostRecent.isAtSameMomentAs(today) ||
          mostRecent.isAtSameMomentAs(yesterday)) {
        currentStreak = 1;
        DateTime checkDate = mostRecent;
        for (int i = 1; i < dates.length; i++) {
          final prevDate =
              DateTime(dates[i].year, dates[i].month, dates[i].day);
          final diff = checkDate.difference(prevDate).inDays;
          if (diff == 1) {
            currentStreak++;
            checkDate = prevDate;
          } else if (diff == 0) {
            continue;
          } else {
            break;
          }
        }
      }
    }

    int bestStreak = currentStreak;
    int tempStreak = 1;
    for (int i = 0; i < dates.length - 1; i++) {
      final d1 = DateTime(dates[i].year, dates[i].month, dates[i].day);
      final d2 =
          DateTime(dates[i + 1].year, dates[i + 1].month, dates[i + 1].day);
      final diff = d1.difference(d2).inDays;
      if (diff == 1) {
        tempStreak++;
        if (tempStreak > bestStreak) bestStreak = tempStreak;
      } else if (diff > 1) {
        tempStreak = 1;
      }
    }
    if (tempStreak > bestStreak) bestStreak = tempStreak;

    final completedTasks = await db.query(
      'tasks',
      where: "status = 'Completed'",
    );
    int totalMinutes = 0;
    for (final row in completedTasks) {
      final task = Task.fromMap(row);
      totalMinutes += task.durationMinutes;
    }

    return {
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'totalCompleted': completedTasks.length,
      'totalStudyMinutes': totalMinutes,
    };
  }

  // ─── Expense Operations ───────────────────────────────────────────────

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return db.insert('expenses', expense.toMap());
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Expense>> getExpensesByDate(String date) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'time DESC, created_at DESC',
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<List<Expense>> getExpensesByDateRange(
      String startDate, String endDate) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC, time DESC, created_at DESC',
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<List<Expense>> getExpensesByMonth(String month) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'date LIKE ?',
      whereArgs: ['$month%'],
      orderBy: 'date DESC, time DESC, created_at DESC',
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<double> getTotalExpenseForDate(String date) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE date = ?',
      [date],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<double> getTotalExpenseForMonth(String month) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE date LIKE ?',
      ['$month%'],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<Map<String, double>> getExpensesByCategory(String month) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM expenses
      WHERE date LIKE ?
      GROUP BY category
      ORDER BY total DESC
    ''', ['$month%']);

    final result = <String, double>{};
    for (final row in maps) {
      result[row['category'] as String] = (row['total'] as num).toDouble();
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getDailyExpenseTrend(int days) async {
    final db = await database;
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    final start =
        '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final end =
        '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

    return db.rawQuery('''
      SELECT date, SUM(amount) as total
      FROM expenses
      WHERE date >= ? AND date <= ?
      GROUP BY date
      ORDER BY date ASC
    ''', [start, end]);
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final maps =
        await db.query('expenses', orderBy: 'date DESC, time DESC, created_at DESC');
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  // ─── Budget Operations ────────────────────────────────────────────────

  Future<int> insertOrUpdateBudget(Budget budget) async {
    final db = await database;
    final existing = await db.query(
      'budgets',
      where: 'category = ? AND month = ?',
      whereArgs: [budget.category, budget.month],
    );

    if (existing.isEmpty) {
      return db.insert('budgets', budget.toMap());
    } else {
      return db.update(
        'budgets',
        budget.toMap(),
        where: 'category = ? AND month = ?',
        whereArgs: [budget.category, budget.month],
      );
    }
  }

  Future<List<Budget>> getBudgetsForMonth(String month) async {
    final db = await database;
    final maps = await db.query(
      'budgets',
      where: 'month = ?',
      whereArgs: [month],
    );
    return maps.map((m) => Budget.fromMap(m)).toList();
  }

  Future<Budget?> getBudgetForCategory(String category, String month) async {
    final db = await database;
    final maps = await db.query(
      'budgets',
      where: 'category = ? AND month = ?',
      whereArgs: [category, month],
    );
    if (maps.isEmpty) return null;
    return Budget.fromMap(maps.first);
  }

  // ─── Settings Operations ──────────────────────────────────────────────

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }

  /// Seed realistic student data for quick demonstration
  Future<void> seedSampleData() async {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final nowIso = now.toIso8601String();

    final sampleTasks = [
      Task(
        title: 'Calculus & Linear Algebra',
        subject: 'Study',
        startTime: '09:00',
        endTime: '10:30',
        date: today,
        priority: 'Important',
        notificationType: 'Sound + vibration',
        notes: 'Chapter 5: Eigenvalues and Vector Spaces',
        status: 'Completed',
        createdAt: nowIso,
        updatedAt: nowIso,
      ),
      Task(
        title: 'Data Structures Lecture',
        subject: 'Class',
        startTime: '11:00',
        endTime: '12:30',
        date: today,
        priority: 'Normal',
        notificationType: 'Sound + vibration',
        notes: 'Binary search trees and AVL trees balance',
        status: 'Completed',
        createdAt: nowIso,
        updatedAt: nowIso,
      ),
      Task(
        title: 'Mobile App Project Lab',
        subject: 'Assignment',
        startTime: '14:00',
        endTime: '16:00',
        date: today,
        priority: 'Critical',
        notificationType: 'Alarm-style reminder',
        notes: 'Finalize local SQLite integration and unit test suite',
        status: 'Upcoming',
        createdAt: nowIso,
        updatedAt: nowIso,
      ),
      Task(
        title: 'Machine Learning Revision',
        subject: 'Revision',
        startTime: '17:00',
        endTime: '18:30',
        date: today,
        priority: 'Normal',
        notificationType: 'Sound + vibration',
        notes: 'Review Gradient Descent formulas',
        status: 'Upcoming',
        createdAt: nowIso,
        updatedAt: nowIso,
      ),
      Task(
        title: 'Evening Workout & Cardio',
        subject: 'Exercise',
        startTime: '19:00',
        endTime: '20:00',
        date: today,
        priority: 'Normal',
        notificationType: 'Sound + vibration',
        notes: 'Campus gym session',
        status: 'Upcoming',
        createdAt: nowIso,
        updatedAt: nowIso,
      ),
    ];

    for (final task in sampleTasks) {
      await insertTask(task);
    }

    final sampleExpenses = [
      Expense(
        amount: 120.0,
        category: 'Food',
        note: 'Cafeteria Lunch',
        paymentMethod: 'UPI',
        date: today,
        time: '12:45',
        createdAt: nowIso,
        updatedAt: nowIso,
      ),
      Expense(
        amount: 500.0,
        category: 'Travel',
        note: 'Monthly Metro Card Reload',
        paymentMethod: 'UPI',
        date: today,
        time: '08:30',
        createdAt: nowIso,
        updatedAt: nowIso,
      ),
      Expense(
        amount: 450.0,
        category: 'Books / Supplies',
        note: 'Reference Textbook & Stationery',
        paymentMethod: 'Card',
        date: today,
        time: '15:10',
        createdAt: nowIso,
        updatedAt: nowIso,
      ),
      Expense(
        amount: 299.0,
        category: 'Recharge / Internet',
        note: 'Monthly 5G Data Pack',
        paymentMethod: 'UPI',
        date: today,
        time: '10:15',
        createdAt: nowIso,
        updatedAt: nowIso,
      ),
      Expense(
        amount: 85.0,
        category: 'Food',
        note: 'Coffee & Snacks',
        paymentMethod: 'Cash',
        date: today,
        time: '17:20',
        createdAt: nowIso,
        updatedAt: nowIso,
      ),
      Expense(
        amount: 160.0,
        category: 'Books / Supplies',
        note: 'Notebooks & Pen Set',
        paymentMethod: 'Cash',
        date: today,
        time: '14:05',
        createdAt: nowIso,
        updatedAt: nowIso,
      ),
      Expense(
        amount: 220.0,
        category: 'Entertainment',
        note: 'Weekend Movie Ticket',
        paymentMethod: 'UPI',
        date: today,
        time: '19:40',
        createdAt: nowIso,
        updatedAt: nowIso,
      ),
    ];

    for (final expense in sampleExpenses) {
      await insertExpense(expense);
    }
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('tasks');
    await db.delete('expenses');
    await db.delete('budgets');
    await db.delete('settings');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
