/// Add/Edit Expense screen with form for logging expenses.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flowra/models/expense.dart';
import 'package:flowra/providers/expense_provider.dart';
import 'package:flowra/providers/settings_provider.dart';
import 'package:flowra/utils/constants.dart';
import 'package:flowra/utils/helpers.dart';
import 'package:flowra/utils/theme.dart';
import 'package:flowra/widgets/common_widgets.dart';

class AddEditExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const AddEditExpenseScreen({super.key, this.expense});

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _category = AppConstants.expenseCategories.first;
  String _paymentMethod = AppConstants.paymentMethods.first;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  bool _isSaving = false;

  bool get isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final e = widget.expense!;
      _amountController.text = e.amount.toStringAsFixed(2);
      _noteController.text = e.note ?? '';
      _category = e.category;
      _paymentMethod = e.paymentMethod ?? AppConstants.paymentMethods.first;
      _date = DateTimeHelper.parseDateFromDb(e.date);
      if (e.time != null && e.time!.isNotEmpty) {
        final parts = e.time!.split(':');
        if (parts.length == 2) {
          _time = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? TimeOfDay.now().hour,
            minute: int.tryParse(parts[1]) ?? TimeOfDay.now().minute,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final now = DateTime.now().toIso8601String();
    final formattedTime =
        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';
    final expense = Expense(
      id: widget.expense?.id,
      amount: double.parse(_amountController.text.trim()),
      category: _category,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      paymentMethod: _paymentMethod,
      date: DateTimeHelper.formatDateForDb(_date),
      time: formattedTime,
      createdAt: widget.expense?.createdAt ?? now,
      updatedAt: now,
    );

    final provider = context.read<ExpenseProvider>();
    bool success;
    if (isEditing) {
      success = await provider.updateExpense(expense);
    } else {
      success = await provider.addExpense(expense);
    }

    setState(() => _isSaving = false);

    if (success && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Expense updated' : 'Expense added'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final symbol =
        context.watch<SettingsProvider>().currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Expense' : 'Add Expense'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _confirmDelete,
              color: AppTheme.dangerRed,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Amount
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '$symbol ',
                prefixIcon: const Icon(Icons.payments_rounded),
              ),
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700),
              validator: ValidationHelper.validateAmount,
              autofocus: !isEditing,
            ),
            const SizedBox(height: 20),

            // Category chips
            const Text('Category',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.expenseCategories.map((cat) {
                final isSelected = _category == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _category = cat),
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

            // Payment method
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                prefixIcon: Icon(Icons.payment_rounded),
              ),
              items: AppConstants.paymentMethods
                  .map(
                      (m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _paymentMethod = v!),
            ),
            const SizedBox(height: 16),

            // Date & Time
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                      child: Text(
                        DateTimeHelper.formatDate(_date),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: _pickTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Time',
                        prefixIcon: Icon(Icons.access_time_rounded),
                      ),
                      child: Text(
                        _time.format(context),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Note
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'What was this expense for?',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: isEditing ? 'Update Expense' : 'Save Expense',
                icon: Icons.check_rounded,
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    if (widget.expense?.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context
          .read<ExpenseProvider>()
          .deleteExpense(widget.expense!.id!);
      if (mounted) Navigator.pop(context, true);
    }
  }
}
