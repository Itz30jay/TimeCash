/// Settings screen with notification, theme, budget, export, and about options.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timecash/providers/settings_provider.dart';
import 'package:timecash/providers/task_provider.dart';
import 'package:timecash/providers/expense_provider.dart';
import 'package:timecash/services/database_service.dart';
import 'package:timecash/services/export_service.dart';
import 'package:timecash/screens/donation_screen.dart';
import 'package:timecash/utils/constants.dart';
import 'package:timecash/utils/helpers.dart';
import 'package:timecash/utils/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // ─── Notifications ──────────────────────────────────────
          _SectionTitle('Notifications'),
          _SettingsTile(
            icon: Icons.notifications_rounded,
            title: 'Notification Permission',
            subtitle: settings.hasNotificationPermission
                ? 'Enabled ✓'
                : 'Disabled — tap to enable',
            trailing: Icon(
              settings.hasNotificationPermission
                  ? Icons.check_circle_rounded
                  : Icons.warning_rounded,
              color: settings.hasNotificationPermission
                  ? AppTheme.successGreen
                  : AppTheme.warningOrange,
            ),
            onTap: () async {
              if (!settings.hasNotificationPermission) {
                await settings.requestNotificationPermission();
              }
            },
          ),
          _SettingsTile(
            icon: Icons.alarm_rounded,
            title: 'Exact Alarm Permission',
            subtitle: settings.hasExactAlarmPermission
                ? 'Allowed ✓'
                : 'Not allowed — reminders may be delayed',
            trailing: Icon(
              settings.hasExactAlarmPermission
                  ? Icons.check_circle_rounded
                  : Icons.warning_rounded,
              color: settings.hasExactAlarmPermission
                  ? AppTheme.successGreen
                  : AppTheme.warningOrange,
            ),
            onTap: () async {
              if (!settings.hasExactAlarmPermission) {
                await settings.requestExactAlarmPermission();
              }
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.alarm_add_rounded),
            title: const Text('Pre-alert before tasks'),
            subtitle:
                Text('${settings.preAlertMinutes} minutes before start time'),
            value: settings.preAlertEnabled,
            onChanged: (v) => settings.setPreAlertEnabled(v),
          ),
          if (settings.preAlertEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<int>(
                initialValue: settings.preAlertMinutes,
                decoration: const InputDecoration(
                  labelText: 'Pre-alert time',
                  prefixIcon: Icon(Icons.timer_rounded),
                ),
                items: [5, 10, 15]
                    .map((m) => DropdownMenuItem(
                        value: m, child: Text('$m minutes before')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) settings.setPreAlertMinutes(v);
                },
              ),
            ),
          const SizedBox(height: 8),
          // DND guidance
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.do_not_disturb_on_rounded,
                      color: AppTheme.warningOrange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'To receive sound during silent mode, allow TimeCash under Do Not Disturb exceptions or allow Alarms & reminders in Settings → Apps → TimeCash → Notifications.',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey[500], height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Appearance ─────────────────────────────────────────
          _SectionTitle('Appearance'),
          _SettingsTile(
            icon: isDark
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            title: 'Theme',
            subtitle: switch (settings.themeMode) {
              ThemeMode.light => 'Light mode',
              ThemeMode.dark => 'Dark mode',
              _ => 'System default',
            },
            onTap: () => _showThemeDialog(context, settings),
          ),

          // ─── Budget & Currency ──────────────────────────────────
          _SectionTitle('Budget & Currency'),
          _SettingsTile(
            icon: Icons.currency_exchange_rounded,
            title: 'Currency',
            subtitle:
                '${settings.currencySymbol} (${settings.currencyCode})',
            onTap: () => _showCurrencyDialog(context, settings),
          ),
          _SettingsTile(
            icon: Icons.savings_rounded,
            title: 'Monthly Budget',
            subtitle: settings.monthlyBudget > 0
                ? CurrencyHelper.format(
                    settings.monthlyBudget, settings.currencySymbol)
                : 'Not set',
            onTap: () => _showBudgetDialog(context, settings),
          ),

          // ─── Data Management ────────────────────────────────────
          _SectionTitle('Data'),
          _SettingsTile(
            icon: Icons.auto_awesome_rounded,
            title: 'Load Demo Student Data',
            subtitle: 'Populate sample timetable and expenses',
            onTap: () => _loadSampleData(context),
          ),
          _SettingsTile(
            icon: Icons.download_rounded,
            title: 'Export Expenses as CSV',
            subtitle: 'Save to phone storage',
            onTap: () => _exportData(context),
          ),
          _SettingsTile(
            icon: Icons.delete_forever_rounded,
            title: 'Clear All Data',
            subtitle: 'Delete all tasks, expenses, and budgets',
            titleColor: AppTheme.dangerRed,
            onTap: () => _clearData(context),
          ),

          // ─── About ─────────────────────────────────────────────
          _SectionTitle('About'),
          _SettingsTile(
            icon: Icons.favorite_rounded,
            title: 'Support the Developer',
            subtitle: 'Make a donation',
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DonationScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.code_rounded,
            title: 'View Source Code',
            subtitle: 'Open on GitHub',
            trailing: const Icon(Icons.open_in_new_rounded, size: 16),
            onTap: () => launchUrl(
              Uri.parse(AppConstants.githubRepoUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
          _SettingsTile(
            icon: Icons.info_rounded,
            title: 'About TimeCash',
            subtitle: 'v${AppConstants.appVersion}',
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Choose Theme'),
        children: [
          _themeOption(ctx, settings, ThemeMode.system, 'System Default',
              Icons.brightness_auto_rounded),
          _themeOption(ctx, settings, ThemeMode.light, 'Light Mode',
              Icons.light_mode_rounded),
          _themeOption(ctx, settings, ThemeMode.dark, 'Dark Mode',
              Icons.dark_mode_rounded),
        ],
      ),
    );
  }

  Widget _themeOption(BuildContext ctx, SettingsProvider settings,
      ThemeMode mode, String label, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: settings.themeMode == mode
          ? const Icon(Icons.check_rounded, color: AppTheme.primaryIndigo)
          : null,
      onTap: () {
        settings.setThemeMode(mode);
        Navigator.pop(ctx);
      },
    );
  }

  void _showCurrencyDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Currency'),
        children: AppConstants.currencies.entries
            .map(
              (e) => ListTile(
                title: Text('${e.value} ${e.key}'),
                trailing: settings.currencyCode == e.key
                    ? const Icon(Icons.check_rounded,
                        color: AppTheme.primaryIndigo)
                    : null,
                onTap: () {
                  settings.setCurrency(e.key, e.value);
                  Navigator.pop(ctx);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  void _showBudgetDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(
      text: settings.monthlyBudget > 0
          ? settings.monthlyBudget.toStringAsFixed(0)
          : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Monthly Budget'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter amount',
            prefixText: '${settings.currencySymbol} ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              settings.setMonthlyBudget(0);
              Navigator.pop(ctx);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text.trim());
              if (amount != null && amount > 0) {
                settings.setMonthlyBudget(amount);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final expenseProvider = context.read<ExpenseProvider>();
    try {
      final expenses = await expenseProvider.getAllExpenses();
      if (expenses.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No expenses to export')),
          );
        }
        return;
      }

      final month = DateTimeHelper.formatMonth(DateTime.now());
      final path = await ExportService.exportExpensesToCsv(expenses, month);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to: $path'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _loadSampleData(BuildContext context) async {
    final taskProvider = context.read<TaskProvider>();
    final expenseProvider = context.read<ExpenseProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Load Demo Data'),
        content: const Text(
          'This will populate your app with sample timetable study sessions and student expense records.\n\nGreat for instantly testing all app features!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryIndigo),
            child: const Text('Load Data'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await DatabaseService().seedSampleData();
      await taskProvider.loadTodayTasks();
      await expenseProvider.loadAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample study sessions and expenses loaded! 🎉'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _clearData(BuildContext context) async {
    final taskProvider = context.read<TaskProvider>();
    final expenseProvider = context.read<ExpenseProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all tasks, expenses, budgets, and settings.\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await DatabaseService().clearAllData();
      await taskProvider.loadTodayTasks();
      await expenseProvider.loadAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared')),
        );
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryIndigo.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.access_time_filled_rounded,
                  color: AppTheme.primaryIndigo),
            ),
            const SizedBox(width: 12),
            const Text('TimeCash'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Version ${AppConstants.appVersion}'),
            const SizedBox(height: 12),
            Text(
              AppConstants.appDescription,
              style: TextStyle(color: Colors.grey[600], height: 1.4),
            ),
            const SizedBox(height: 12),
            Text(
              '• 100% offline\n• No ads, no tracking\n• No account required\n• Your data stays on your phone',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => launchUrl(
              Uri.parse(AppConstants.githubRepoUrl),
              mode: LaunchMode.externalApplication,
            ),
            child: const Text('GitHub'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryIndigo,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: titleColor,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
