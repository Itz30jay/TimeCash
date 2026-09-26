/// Home screen showing greeting, next task, today's summary,
/// quick actions, and task/expense stats.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flowra/providers/task_provider.dart';
import 'package:flowra/providers/expense_provider.dart';
import 'package:flowra/providers/settings_provider.dart';
import 'package:flowra/utils/helpers.dart';
import 'package:flowra/utils/theme.dart';
import 'package:flowra/widgets/common_widgets.dart';
import 'package:flowra/screens/study_focus_screen.dart';
import 'package:flowra/screens/add_edit_task_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onAddTask;
  final VoidCallback onAddExpense;

  const HomeScreen({
    super.key,
    required this.onAddTask,
    required this.onAddExpense,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    // Refresh every 30 seconds to update task status and countdown
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final taskProvider = context.read<TaskProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    await taskProvider.loadTodayTasks();
    await expenseProvider.loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // App bar with greeting
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: false,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateTimeHelper.getGreeting(name: settings.userName),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                colors: [
                                  AppTheme.primaryIndigo,
                                  AppTheme.studyBlue,
                                ],
                              ).createShader(
                                  const Rect.fromLTWH(0, 0, 250, 40)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateTimeHelper.formatDate(DateTime.now()),
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Permission warning banner
                  PermissionBanner(
                    showNotificationWarning:
                        !settings.hasNotificationPermission,
                    showExactAlarmWarning: !settings.hasExactAlarmPermission,
                    onFixNotification: () =>
                        settings.requestNotificationPermission(),
                    onFixAlarm: () => settings.requestExactAlarmPermission(),
                  ),

                  // Study streak banner
                  _buildStreakBanner(context),

                  // Next task card
                  _buildNextTaskCard(context),

                  // Quick actions
                  _buildQuickActions(context),

                  // Today's stats row
                  _buildTodayStats(context),

                  // Today's tasks
                  const SectionHeader(title: "Today's Schedule"),
                  _buildTodayTasks(context),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakBanner(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final streak = taskProvider.currentStreak;
    final best = taskProvider.bestStreak;
    final hours = taskProvider.totalStudyHours;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: streak > 0
                ? [
                    Colors.orange.withValues(alpha: 0.15),
                    Colors.deepOrange.withValues(alpha: 0.04),
                  ]
                : [
                    AppTheme.primaryIndigo.withValues(alpha: 0.08),
                    AppTheme.primaryIndigo.withValues(alpha: 0.02),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (streak > 0 ? Colors.orange : AppTheme.primaryIndigo)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                streak > 0
                    ? Icons.local_fire_department_rounded
                    : Icons.bolt_rounded,
                color: streak > 0 ? Colors.orange : AppTheme.primaryIndigo,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    streak > 0
                        ? '$streak Day Study Streak! 🔥'
                        : 'Ignite Your Study Streak',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    streak > 0
                        ? 'Best: $best days • ${hours.toStringAsFixed(1)}h studied'
                        : 'Complete your scheduled tasks to build consistency',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextTaskCard(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final nextTask = taskProvider.nextTask;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (nextTask == null) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppTheme.successGreen, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'All caught up!',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'No upcoming tasks for now',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final countdown = DateTimeHelper.getCountdown(nextTask.startDateTime);
    final isRunning = nextTask.isRunning;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isRunning
                ? [
                    AppTheme.studyBlue.withValues(alpha: 0.15),
                    AppTheme.primaryIndigo.withValues(alpha: 0.05),
                  ]
                : [
                    AppTheme.primaryIndigo.withValues(alpha: 0.1),
                    AppTheme.primaryIndigo.withValues(alpha: 0.03),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isRunning
                          ? AppTheme.studyBlue.withValues(alpha: 0.2)
                          : AppTheme.primaryIndigo.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isRunning ? '🔴 NOW' : '📚 NEXT UP',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isRunning
                            ? AppTheme.studyBlue
                            : AppTheme.primaryIndigo,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    countdown,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isRunning
                          ? AppTheme.studyBlue
                          : AppTheme.primaryIndigo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                nextTask.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${nextTask.startTime} – ${nextTask.endTime}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              if (nextTask.subject != null) ...[
                const SizedBox(height: 4),
                Text(
                  nextTask.subject!,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFFA5B4FC)
                        : AppTheme.primaryIndigo,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (nextTask.isUpcoming) ...[
                    Expanded(
                      child: PrimaryButton(
                        label: 'Start Now',
                        icon: Icons.play_arrow_rounded,
                        onPressed: () {
                          context
                              .read<TaskProvider>()
                              .startTask(nextTask.id!);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.timer_rounded),
                      tooltip: 'Focus Mode',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                StudyFocusScreen(initialTask: nextTask),
                          ),
                        );
                      },
                    ),
                  ],
                  if (nextTask.isRunning) ...[
                    Expanded(
                      child: PrimaryButton(
                        label: 'Mark Complete',
                        icon: Icons.check_rounded,
                        color: AppTheme.successGreen,
                        onPressed: () {
                          context
                              .read<TaskProvider>()
                              .completeTask(nextTask.id!);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.timer_rounded),
                      tooltip: 'Focus Mode',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                StudyFocusScreen(initialTask: nextTask),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionButton(
              icon: Icons.add_task_rounded,
              label: 'Add Task',
              color: AppTheme.primaryIndigo,
              onTap: widget.onAddTask,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.timer_rounded,
              label: 'Focus Timer',
              color: AppTheme.studyBlue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudyFocusScreen()),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.add_card_rounded,
              label: 'Add Expense',
              color: AppTheme.dangerRed,
              onTap: widget.onAddExpense,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayStats(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final settings = context.watch<SettingsProvider>();
    final symbol = settings.currencySymbol;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              title: 'Tasks Done',
              value:
                  '${taskProvider.todayCompleted}/${taskProvider.todayTotal}',
              icon: Icons.task_alt_rounded,
              color: AppTheme.successGreen,
              subtitle: taskProvider.todayTotal > 0
                  ? '${(taskProvider.todayCompletionRate * 100).toStringAsFixed(0)}% complete'
                  : null,
            ),
          ),
          Expanded(
            child: StatCard(
              title: "Today's Spend",
              value: CurrencyHelper.formatCompact(
                  expenseProvider.todayTotal, symbol),
              icon: Icons.payments_rounded,
              color: AppTheme.warningOrange,
              subtitle:
                  'Month: ${CurrencyHelper.formatCompact(expenseProvider.monthTotal, symbol)}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTasks(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    if (taskProvider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (taskProvider.todayTasks.isEmpty) {
      return EmptyState(
        title: 'No tasks today',
        subtitle: 'Tap + to add your first study session',
        icon: Icons.event_note_rounded,
        buttonLabel: 'Add Task',
        onAction: widget.onAddTask,
      );
    }

    final taskProv = context.read<TaskProvider>();

    return Column(
      children: taskProvider.todayTasks
          .map(
            (task) => TaskCard(
              task: task,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditTaskScreen(task: task),
                  ),
                ).then((_) {
                  if (!mounted) return;
                  taskProv.loadTodayTasks();
                });
              },
              onFocus: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudyFocusScreen(initialTask: task),
                  ),
                ).then((_) {
                  if (!mounted) return;
                  taskProv.loadTodayTasks();
                });
              },
              onStart: task.isUpcoming
                  ? () => taskProv.startTask(task.id!)
                  : null,
              onComplete: task.isRunning
                  ? () => taskProv.completeTask(task.id!)
                  : null,
            ),
          )
          .toList(),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
