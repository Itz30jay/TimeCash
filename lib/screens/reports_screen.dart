/// Reports screen with study and spending analytics.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:timecash/providers/task_provider.dart';
import 'package:timecash/providers/expense_provider.dart';
import 'package:timecash/providers/settings_provider.dart';
import 'package:timecash/utils/helpers.dart';
import 'package:timecash/utils/theme.dart';
import 'package:timecash/widgets/common_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _prevMonthTotal = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final taskProvider = context.read<TaskProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    await taskProvider.loadTodayTasks();
    await expenseProvider.loadAll();
    _prevMonthTotal = await expenseProvider.getPreviousMonthTotal();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Study', icon: Icon(Icons.school_rounded, size: 20)),
            Tab(text: 'Money', icon: Icon(Icons.payments_rounded, size: 20)),
          ],
          indicatorColor: AppTheme.primaryIndigo,
          labelColor: AppTheme.primaryIndigo,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStudyReport(),
          _buildMoneyReport(),
        ],
      ),
    );
  }

  Widget _buildStudyReport() {
    final taskProvider = context.watch<TaskProvider>();

    final planned = taskProvider.monthTotal;
    final completed = taskProvider.monthCompleted;
    final missed = taskProvider.monthStats['Missed'] ?? 0;
    final rate = planned > 0 ? (completed / planned * 100) : 0;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const SizedBox(height: 8),
          // Stats grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Planned',
                        value: '$planned',
                        icon: Icons.event_note_rounded,
                        color: AppTheme.primaryIndigo,
                      ),
                    ),
                    Expanded(
                      child: StatCard(
                        title: 'Completed',
                        value: '$completed',
                        icon: Icons.task_alt_rounded,
                        color: AppTheme.successGreen,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Missed',
                        value: '$missed',
                        icon: Icons.cancel_rounded,
                        color: AppTheme.dangerRed,
                      ),
                    ),
                    Expanded(
                      child: StatCard(
                        title: 'Completion Rate',
                        value: '${rate.toStringAsFixed(0)}%',
                        icon: Icons.trending_up_rounded,
                        color: rate >= 70
                            ? AppTheme.successGreen
                            : AppTheme.warningOrange,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Current Streak',
                        value: '${taskProvider.currentStreak} Days',
                        icon: Icons.local_fire_department_rounded,
                        color: Colors.orange,
                        subtitle: 'Best: ${taskProvider.bestStreak} days',
                      ),
                    ),
                    Expanded(
                      child: StatCard(
                        title: 'Study Hours',
                        value: '${taskProvider.totalStudyHours.toStringAsFixed(1)} hrs',
                        icon: Icons.timelapse_rounded,
                        color: AppTheme.studyBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Weekly bar chart
          ChartCard(
            title: 'This Week',
            height: 200,
            chart: _buildWeeklyStudyChart(taskProvider),
          ),

          // Today stats card
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Today's Summary",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _buildStatRow('Tasks planned',
                      '${taskProvider.todayTotal}', AppTheme.primaryIndigo),
                  _buildStatRow('Completed',
                      '${taskProvider.todayCompleted}', AppTheme.successGreen),
                  _buildStatRow('Missed', '${taskProvider.todayMissed}',
                      AppTheme.dangerRed),
                  const Divider(height: 20),
                  _buildStatRow(
                      'Completion rate',
                      '${(taskProvider.todayCompletionRate * 100).toStringAsFixed(0)}%',
                      taskProvider.todayCompletionRate >= 0.7
                          ? AppTheme.successGreen
                          : AppTheme.warningOrange),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoneyReport() {
    final expenseProvider = context.watch<ExpenseProvider>();
    final settings = context.watch<SettingsProvider>();
    final symbol = settings.currencySymbol;

    final monthTotal = expenseProvider.monthTotal;
    final categories = expenseProvider.categoryTotals;
    final topCat = expenseProvider.topCategory;
    final dailyAvg = expenseProvider.dailyAverage;
    final budgetRem = expenseProvider.budgetRemaining;
    final hasBudget = settings.monthlyBudget > 0;

    // Generate insight
    String insight = '';
    if (categories.isNotEmpty && monthTotal > 0) {
      final topAmount = categories[topCat] ?? 0;
      final topPercent = (topAmount / monthTotal * 100).toStringAsFixed(0);
      insight =
          'You spent ${CurrencyHelper.format(topAmount, symbol)} on $topCat this month, which is $topPercent% of your total expenses.';
    }

    // Comparison with previous month
    final diff = monthTotal - _prevMonthTotal;
    final diffPercent = _prevMonthTotal > 0
        ? ((diff / _prevMonthTotal) * 100).toStringAsFixed(0)
        : '0';

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Monthly Total',
                        value: CurrencyHelper.formatCompact(
                            monthTotal, symbol),
                        icon: Icons.account_balance_wallet_rounded,
                        color: AppTheme.dangerRed,
                      ),
                    ),
                    Expanded(
                      child: StatCard(
                        title: 'Daily Average',
                        value: CurrencyHelper.format(dailyAvg, symbol),
                        icon: Icons.show_chart_rounded,
                        color: AppTheme.warningOrange,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Top Category',
                        value: topCat,
                        icon: Icons.category_rounded,
                        color: AppTheme.primaryIndigo,
                      ),
                    ),
                    if (hasBudget)
                      Expanded(
                        child: StatCard(
                          title: 'Budget Left',
                          value: CurrencyHelper.format(
                              budgetRem.clamp(0, double.infinity), symbol),
                          icon: Icons.savings_rounded,
                          color: budgetRem >= 0
                              ? AppTheme.successGreen
                              : AppTheme.dangerRed,
                          subtitle: budgetRem < 0 ? 'Over budget!' : null,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Category chart
          if (categories.isNotEmpty)
            ChartCard(
              title: 'Category Breakdown',
              height: 220,
              chart: _buildCategoryBarChart(categories, symbol),
            ),

          // Month comparison
          if (_prevMonthTotal > 0)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      diff > 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color:
                          diff > 0 ? AppTheme.dangerRed : AppTheme.successGreen,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        diff > 0
                            ? 'Spending is up $diffPercent% vs last month'
                            : 'Spending is down ${diffPercent.replaceFirst('-', '')}% vs last month',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: diff > 0
                              ? AppTheme.dangerRed
                              : AppTheme.successGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Insight
          if (insight.isNotEmpty)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_rounded,
                        color: AppTheme.warningOrange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        insight,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStudyChart(TaskProvider taskProvider) {
    final weekDays = DateTimeHelper.getDaysInWeek(DateTime.now());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<int>>(
      future: Future.wait(weekDays.map((d) async {
        final stats = await taskProvider
            .getTasksForDate(d);
        return stats.where((t) => t.isCompleted).length;
      })),
      builder: (context, snapshot) {
        final data = snapshot.data ?? List.filled(7, 0);

        return BarChart(
          BarChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                    if (value.toInt() >= 0 && value.toInt() < 7) {
                      return Text(
                        labels[value.toInt()],
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(
              7,
              (i) => BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[i].toDouble(),
                    color: i == DateTime.now().weekday - 1
                        ? AppTheme.primaryIndigo
                        : AppTheme.primaryIndigo.withValues(alpha: 0.4),
                    width: 24,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryBarChart(
      Map<String, double> categories, String symbol) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entries = categories.entries.toList();
    final colors = [
      Colors.orange,
      Colors.blue,
      AppTheme.primaryIndigo,
      Colors.teal,
      Colors.pink,
      Colors.purple,
      AppTheme.dangerRed,
      Colors.grey,
    ];

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                if (value.toInt() >= 0 && value.toInt() < entries.length) {
                  final label = entries[value.toInt()].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      label.length > 6
                          ? '${label.substring(0, 6)}..'
                          : label,
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          entries.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: entries[i].value,
                color: colors[i % colors.length],
                width: 20,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '$symbol${rod.toY.toStringAsFixed(0)}',
                const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          Text(
            value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
