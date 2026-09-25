/// Expenses screen with expense list, category breakdown, and charts.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:timecash/models/expense.dart';
import 'package:timecash/providers/expense_provider.dart';
import 'package:timecash/providers/settings_provider.dart';
import 'package:timecash/screens/add_edit_expense_screen.dart';
import 'package:timecash/utils/constants.dart';
import 'package:timecash/utils/helpers.dart';
import 'package:timecash/utils/theme.dart';
import 'package:timecash/widgets/common_widgets.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final settings = context.watch<SettingsProvider>();
    final symbol = settings.currencySymbol;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
      ),
      body: RefreshIndicator(
        onRefresh: () => expenseProvider.loadAll(),
        child: CustomScrollView(
          slivers: [
            // Summary cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Today',
                        value: CurrencyHelper.format(
                            expenseProvider.todayTotal, symbol),
                        icon: Icons.today_rounded,
                        color: AppTheme.warningOrange,
                      ),
                    ),
                    Expanded(
                      child: StatCard(
                        title: 'This Month',
                        value: CurrencyHelper.formatCompact(
                            expenseProvider.monthTotal, symbol),
                        icon: Icons.calendar_month_rounded,
                        color: AppTheme.dangerRed,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Budget progress
            if (settings.monthlyBudget > 0)
              SliverToBoxAdapter(
                child: BudgetProgressBar(
                  label: 'Monthly Budget',
                  spent: expenseProvider.monthTotal,
                  limit: settings.monthlyBudget,
                  currencySymbol: symbol,
                ),
              ),

            // Category pie chart
            if (expenseProvider.categoryTotals.isNotEmpty)
              SliverToBoxAdapter(
                child: ChartCard(
                  title: 'By Category',
                  height: 220,
                  chart: _buildPieChart(
                      expenseProvider.categoryTotals, expenseProvider.monthTotal),
                ),
              ),

            // Spending trend
            if (expenseProvider.dailyTrend.isNotEmpty)
              SliverToBoxAdapter(
                child: ChartCard(
                  title: 'Last 30 Days Trend',
                  height: 180,
                  chart: _buildTrendChart(
                      expenseProvider.dailyTrend, isDark, symbol),
                ),
              ),

            // Top stats
            if (expenseProvider.categoryTotals.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                          label: 'Top Category',
                          value: expenseProvider.topCategory,
                          icon: Icons.category_rounded,
                          color: AppTheme.primaryIndigo,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoTile(
                          label: 'Most Expensive Day',
                          value: expenseProvider.getMostExpensiveDay(),
                          icon: Icons.trending_up_rounded,
                          color: AppTheme.dangerRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Header with search & category filter
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Recent Expenses'),
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search expenses...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    ),
                  ),
                  // Category chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: ['All', ...AppConstants.expenseCategories].map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (_) =>
                                setState(() => _selectedCategory = cat),
                            selectedColor:
                                AppTheme.primaryIndigo.withValues(alpha: 0.2),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppTheme.primaryIndigo : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Expense list
            () {
              final allExpenses = expenseProvider.monthExpenses;
              final filtered = allExpenses.where((e) {
                final matchesCategory =
                    _selectedCategory == 'All' || e.category == _selectedCategory;
                final matchesQuery = _searchQuery.isEmpty ||
                    e.category
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()) ||
                    (e.note != null &&
                        e.note!
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()));
                return matchesCategory && matchesQuery;
              }).toList();

              if (allExpenses.isEmpty) {
                return const SliverToBoxAdapter(
                  child: EmptyState(
                    title: 'No expenses yet',
                    subtitle: 'Tap + to log your first expense',
                    icon: Icons.receipt_long_rounded,
                  ),
                );
              }

              if (filtered.isEmpty) {
                return SliverToBoxAdapter(
                  child: EmptyState(
                    title: 'No matching expenses',
                    subtitle: 'Try adjusting your search or category filter',
                    icon: Icons.search_off_rounded,
                    buttonLabel: 'Clear Filter',
                    onAction: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _selectedCategory = 'All';
                      });
                    },
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= filtered.length) return null;
                    final expense = filtered[index];
                    return ExpenseCard(
                      expense: expense,
                      currencySymbol: symbol,
                      onTap: () => _editExpense(expense),
                      onDelete: () => _deleteExpense(expense),
                    );
                  },
                  childCount: filtered.length,
                ),
              );
            }(),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExpense,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildPieChart(
      Map<String, double> categories, double total) {
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

    final sections = <PieChartSectionData>[];
    int i = 0;
    for (final entry in categories.entries) {
      final percent = total > 0 ? (entry.value / total * 100) : 0;
      sections.add(PieChartSectionData(
        color: colors[i % colors.length],
        value: entry.value,
        title: '${percent.toStringAsFixed(0)}%',
        titleStyle: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
        radius: 55,
        titlePositionPercentageOffset: 0.55,
      ));
      i++;
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 32,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int j = 0; j < categories.length && j < 6; j++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors[j % colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          categories.keys.elementAt(j),
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendChart(
      List<Map<String, dynamic>> trend, bool isDark, String symbol) {
    if (trend.isEmpty) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    for (int i = 0; i < trend.length; i++) {
      spots.add(FlSpot(i.toDouble(), (trend[i]['total'] as num).toDouble()));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.primaryIndigo,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primaryIndigo.withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '$symbol${spot.y.toStringAsFixed(0)}',
                  const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Future<void> _addExpense() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditExpenseScreen()),
    );
    if (result == true && mounted) {
      context.read<ExpenseProvider>().loadAll();
    }
  }

  Future<void> _editExpense(Expense expense) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => AddEditExpenseScreen(expense: expense)),
    );
    if (result == true && mounted) {
      context.read<ExpenseProvider>().loadAll();
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Delete this ${expense.category} expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<ExpenseProvider>().deleteExpense(expense.id!);
    }
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 2),
            Text(value,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
