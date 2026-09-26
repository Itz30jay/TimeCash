/// Flowra — Offline Planner & Expense Tracker
/// Entry point with Provider setup, routing, and bottom navigation.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flowra/providers/task_provider.dart';
import 'package:flowra/providers/expense_provider.dart';
import 'package:flowra/providers/settings_provider.dart';
import 'package:flowra/services/notification_service.dart';
import 'package:flowra/services/settings_service.dart';
import 'package:flowra/screens/onboarding_screen.dart';
import 'package:flowra/screens/home_screen.dart';
import 'package:flowra/screens/timetable_screen.dart';
import 'package:flowra/screens/expenses_screen.dart';
import 'package:flowra/screens/reports_screen.dart';
import 'package:flowra/screens/settings_screen.dart';
import 'package:flowra/screens/add_edit_task_screen.dart';
import 'package:flowra/screens/add_edit_expense_screen.dart';
import 'package:flowra/screens/study_focus_screen.dart';
import 'package:flowra/utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for mobile
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize services
  final settingsService = SettingsService();
  await settingsService.initialize();

  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const FlowraApp(),
    ),
  );
}

class FlowraApp extends StatefulWidget {
  const FlowraApp({super.key});

  @override
  State<FlowraApp> createState() => _FlowraAppState();
}

class _FlowraAppState extends State<FlowraApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Load settings and reschedule notifications after app launch
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final settingsProvider = context.read<SettingsProvider>();
      await settingsProvider.loadSettings();

      // Reschedule all notifications (handles boot, timezone change, etc.)
      if (!mounted) return;
      final taskProvider = context.read<TaskProvider>();
      await taskProvider.rescheduleAllNotifications();

      // Handle notification tap actions
      final notifService = NotificationService();
      notifService.onNotificationAction = (actionId, payload) {
        _handleNotificationAction(actionId, payload);
      };
      notifService.onNotificationTap = (payload) {
        _handleNotificationTap(payload);
      };
    });
  }

  void _handleNotificationAction(String actionId, String? payload) {
    if (payload == null) return;
    final parts = payload.split(':');
    if (parts.length < 2) return;
    final taskId = int.tryParse(parts[1]);
    if (taskId == null) return;

    final taskProvider = context.read<TaskProvider>();

    switch (actionId) {
      case 'start_now':
        taskProvider.startTask(taskId);
        break;
      case 'snooze_10':
        // Snooze needs the task object
        taskProvider.loadTodayTasks().then((_) {
          final task = taskProvider.todayTasks
              .where((t) => t.id == taskId)
              .firstOrNull;
          if (task != null) {
            taskProvider.snoozeTask(task, 10);
          }
        });
        break;
      case 'done':
        taskProvider.completeTask(taskId);
        break;
    }
  }

  void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    final parts = payload.split(':');
    if (parts.length < 2) return;
    final taskId = int.tryParse(parts[1]);
    if (taskId == null) return;

    final taskProvider = context.read<TaskProvider>();
    taskProvider.loadTodayTasks().then((_) {
      final task = taskProvider.todayTasks
          .where((t) => t.id == taskId)
          .firstOrNull;
      if (task != null && _navigatorKey.currentState != null) {
        _navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => StudyFocusScreen(initialTask: task),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final settingsService = SettingsService();

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Flowra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: settings.themeMode,
      home: settingsService.isOnboardingComplete
          ? const MainShell()
          : const OnboardingScreen(),
      routes: {
        '/main': (_) => const MainShell(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/add-task': (_) => const AddEditTaskScreen(),
        '/add-expense': (_) => const AddEditExpenseScreen(),
        '/focus': (_) => const StudyFocusScreen(),
      },
    );
  }
}

/// Main app shell with bottom navigation bar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _onTabChanged(int index) {
    setState(() => _currentIndex = index);
  }

  void _navigateToAddTask() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditTaskScreen()),
    ).then((_) {
      if (!mounted) return;
      context.read<TaskProvider>().loadTodayTasks();
    });
  }

  void _navigateToAddExpense() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditExpenseScreen()),
    ).then((_) {
      if (!mounted) return;
      context.read<ExpenseProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        onAddTask: _navigateToAddTask,
        onAddExpense: _navigateToAddExpense,
      ),
      const TimetableScreen(),
      const ExpensesScreen(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month_rounded),
            label: 'Timetable',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart_rounded),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
