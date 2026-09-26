/// Onboarding screen shown on first launch.
/// 3 intro pages + permission requests + name/role + currency/budget setup.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flowra/providers/settings_provider.dart';
import 'package:flowra/services/settings_service.dart';
import 'package:flowra/utils/constants.dart';
import 'package:flowra/utils/theme.dart';
import 'package:flowra/widgets/common_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _selectedCurrency = 'INR';
  String _selectedSymbol = '₹';
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String _selectedRole = AppConstants.roleStudent;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.calendar_month_rounded,
      title: 'Plan your day',
      subtitle:
          'Create a daily and weekly timetable.\nStay organized and never miss an important task.',
      color: AppTheme.primaryIndigo,
    ),
    _OnboardingPage(
      icon: Icons.notifications_active_rounded,
      title: 'Get reminders even in silent mode',
      subtitle:
          'Strong notifications that work on silent.\nNever forget an important task or meeting.',
      color: AppTheme.studyBlue,
    ),
    _OnboardingPage(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Track where your money goes',
      subtitle:
          'Log daily expenses and understand spending.\nSet budgets and save smarter.',
      color: AppTheme.successGreen,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _budgetController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _showSetupDialog();
    }
  }

  Future<void> _showSetupDialog() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _SetupSheet(
        selectedCurrency: _selectedCurrency,
        selectedSymbol: _selectedSymbol,
        budgetController: _budgetController,
        nameController: _nameController,
        selectedRole: _selectedRole,
        onCurrencyChanged: (code, symbol) {
          setState(() {
            _selectedCurrency = code;
            _selectedSymbol = symbol;
          });
        },
        onRoleChanged: (role) {
          setState(() => _selectedRole = role);
        },
        onComplete: _completeOnboarding,
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    final settings = context.read<SettingsProvider>();

    // Request permissions
    await settings.requestNotificationPermission();
    await settings.requestExactAlarmPermission();

    // Save currency
    await settings.setCurrency(_selectedCurrency, _selectedSymbol);

    // Save budget if provided
    final budgetText = _budgetController.text.trim();
    if (budgetText.isNotEmpty) {
      final budget = double.tryParse(budgetText);
      if (budget != null && budget > 0) {
        await settings.setMonthlyBudget(budget);
      }
    }

    // Save user name and role
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      await settings.setUserName(name);
    }
    await settings.setUserRole(_selectedRole);

    // Mark onboarding complete
    await SettingsService().setOnboardingComplete(true);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _showSetupDialog,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: page.color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(page.icon, size: 56, color: page.color),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          page.title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.subtitle,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[500],
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Dots + next button
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dots
                  Row(
                    children: List.generate(_pages.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppTheme.primaryIndigo
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  // Next / Get Started
                  FloatingActionButton(
                    onPressed: _nextPage,
                    backgroundColor: AppTheme.primaryIndigo,
                    child: Icon(
                      _currentPage == _pages.length - 1
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 28,
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
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

class _SetupSheet extends StatefulWidget {
  final String selectedCurrency;
  final String selectedSymbol;
  final TextEditingController budgetController;
  final TextEditingController nameController;
  final String selectedRole;
  final Function(String code, String symbol) onCurrencyChanged;
  final Function(String role) onRoleChanged;
  final VoidCallback onComplete;

  const _SetupSheet({
    required this.selectedCurrency,
    required this.selectedSymbol,
    required this.budgetController,
    required this.nameController,
    required this.selectedRole,
    required this.onCurrencyChanged,
    required this.onRoleChanged,
    required this.onComplete,
  });

  @override
  State<_SetupSheet> createState() => _SetupSheetState();
}

class _SetupSheetState extends State<_SetupSheet> {
  late String _currency;
  late String _role;

  @override
  void initState() {
    super.initState();
    _currency = widget.selectedCurrency;
    _role = widget.selectedRole;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Quick Setup',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Set your preferences. You can change these later in Settings.',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),

            // Your Name
            const Text('Your Name (optional)',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: widget.nameController,
              decoration: const InputDecoration(
                hintText: 'e.g. Jay',
                prefixIcon: Icon(Icons.person_rounded),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),

            // Role selector
            const Text('I am a...',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.userRoles.map((role) {
                final isSelected = _role == role;
                return ChoiceChip(
                  label: Text(role),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _role = role);
                    widget.onRoleChanged(role);
                  },
                  selectedColor:
                      AppTheme.primaryIndigo.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppTheme.primaryIndigo : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Currency selector
            const Text('Currency',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.currency_exchange_rounded),
              ),
              items: AppConstants.currencies.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text('${e.value} ${e.key}'),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _currency = value);
                  widget.onCurrencyChanged(
                      value, AppConstants.currencies[value]!);
                }
              },
            ),
            const SizedBox(height: 20),
            // Monthly budget
            const Text('Monthly Budget (optional)',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: widget.budgetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g. 5000',
                prefixIcon: const Icon(Icons.account_balance_wallet_rounded),
                prefixText: '${AppConstants.currencies[_currency] ?? "₹"} ',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Get Started',
                icon: Icons.rocket_launch_rounded,
                onPressed: () {
                  Navigator.pop(context);
                  widget.onComplete();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
