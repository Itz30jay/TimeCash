/// Add/Edit Task screen with full form for creating or editing study tasks.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flowra/models/task.dart';
import 'package:flowra/providers/settings_provider.dart';
import 'package:flowra/providers/task_provider.dart';
import 'package:flowra/utils/constants.dart';
import 'package:flowra/utils/helpers.dart';
import 'package:flowra/utils/theme.dart';
import 'package:flowra/widgets/common_widgets.dart';

class AddEditTaskScreen extends StatefulWidget {
  final Task? task; // null = add mode, non-null = edit mode

  const AddEditTaskScreen({super.key, this.task});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  String _subject = AppConstants.taskSubjects.first;
  bool _subjectInitialized = false;
  DateTime _date = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime =
      TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: TimeOfDay.now().minute);
  String _repeatType = 'Once';
  List<int> _customDays = [];
  String _priority = 'Normal';
  String _notificationType = 'Sound + vibration';
  bool _isSaving = false;

  bool get isEditing => widget.task != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_subjectInitialized && !isEditing) {
      final role = context.read<SettingsProvider>().userRole;
      final roleSubjects = AppConstants.getTaskSubjectsForRole(role);
      if (roleSubjects.isNotEmpty) {
        _subject = roleSubjects.first;
      }
      _subjectInitialized = true;
    }
  }

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final t = widget.task!;
      _titleController.text = t.title;
      _notesController.text = t.notes ?? '';
      _subject = t.subject ?? AppConstants.taskSubjects.first;
      _date = DateTimeHelper.parseDateFromDb(t.date);
      final startParts = t.startTime.split(':');
      _startTime = TimeOfDay(
          hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
      final endParts = t.endTime.split(':');
      _endTime = TimeOfDay(
          hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
      _repeatType = t.repeatType;
      _priority = t.priority;
      _notificationType = t.notificationType;
      if (t.repeatDays != null) {
        _customDays = t.repeatDays!
            .split(',')
            .map((d) => int.tryParse(d.trim()) ?? 0)
            .where((d) => d > 0)
            .toList();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate time range
    final startDt = DateTime(_date.year, _date.month, _date.day,
        _startTime.hour, _startTime.minute);
    final endDt = DateTime(
        _date.year, _date.month, _date.day, _endTime.hour, _endTime.minute);

    if (endDt.isBefore(startDt) || endDt.isAtSameMomentAs(startDt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final now = DateTime.now().toIso8601String();
    final task = Task(
      id: widget.task?.id,
      title: _titleController.text.trim(),
      subject: _subject,
      startTime: _formatTimeOfDay(_startTime),
      endTime: _formatTimeOfDay(_endTime),
      date: DateTimeHelper.formatDateForDb(_date),
      repeatType: _repeatType,
      repeatDays:
          _repeatType == 'Custom' ? _customDays.join(',') : null,
      priority: _priority,
      notificationType: _notificationType,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      status: widget.task?.status ?? 'Upcoming',
      createdAt: widget.task?.createdAt ?? now,
      updatedAt: now,
    );

    // Check for overlaps
    final taskProvider = context.read<TaskProvider>();
    final overlaps = await taskProvider.checkOverlaps(task);

    if (overlaps.isNotEmpty && mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Time Overlap'),
          content: Text(
            'This task overlaps with:\n${overlaps.map((t) => '• ${t.title} (${t.startTime}–${t.endTime})').join('\n')}\n\nSave anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save Anyway'),
            ),
          ],
        ),
      );
      if (proceed != true) {
        setState(() => _isSaving = false);
        return;
      }
    }

    bool success;
    if (isEditing) {
      success = await taskProvider.updateTask(task);
    } else {
      final result = await taskProvider.addTask(task);
      success = result != null;

      // Generate recurring instances if needed
      if (success && _repeatType != 'Once') {
        await taskProvider.generateRecurringInstances(result, 30);
      }
    }

    setState(() => _isSaving = false);

    if (success && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Task updated' : 'Task added'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'Add Task'),
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
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                hintText: 'e.g. Project review / Math revision',
                prefixIcon: Icon(Icons.edit_rounded),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  ValidationHelper.validateRequired(v, 'Task title'),
            ),
            const SizedBox(height: 16),

            // Subject/Category
            Builder(
              builder: (ctx) {
                final role = ctx.watch<SettingsProvider>().userRole;
                final roleSubjects = AppConstants.getTaskSubjectsForRole(role);
                final subjects = roleSubjects.contains(_subject)
                    ? roleSubjects
                    : [_subject, ...roleSubjects];
                return DropdownButtonFormField<String>(
                  initialValue: _subject,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_rounded),
                  ),
                  items: subjects
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _subject = v);
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Date picker
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today_rounded),
                ),
                child: Text(DateTimeHelper.formatDate(_date)),
              ),
            ),
            const SizedBox(height: 16),

            // Time pickers row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickStartTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Time',
                        prefixIcon: Icon(Icons.access_time_rounded),
                      ),
                      child: Text(_startTime.format(context)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickEndTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Time',
                        prefixIcon: Icon(Icons.access_time_filled_rounded),
                      ),
                      child: Text(_endTime.format(context)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Repeat type
            DropdownButtonFormField<String>(
              initialValue: _repeatType,
              decoration: const InputDecoration(
                labelText: 'Repeat',
                prefixIcon: Icon(Icons.repeat_rounded),
              ),
              items: AppConstants.repeatTypes
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _repeatType = v!),
            ),

            // Custom days selector
            if (_repeatType == 'Custom') ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final entry in {
                    1: 'Mon',
                    2: 'Tue',
                    3: 'Wed',
                    4: 'Thu',
                    5: 'Fri',
                    6: 'Sat',
                    7: 'Sun'
                  }.entries)
                    FilterChip(
                      label: Text(entry.value),
                      selected: _customDays.contains(entry.key),
                      onSelected: (sel) {
                        setState(() {
                          if (sel) {
                            _customDays.add(entry.key);
                          } else {
                            _customDays.remove(entry.key);
                          }
                        });
                      },
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Priority
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                prefixIcon: Icon(Icons.flag_rounded),
              ),
              items: AppConstants.taskPriorities
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _priority = v!),
            ),
            const SizedBox(height: 16),

            // Notification type
            DropdownButtonFormField<String>(
              initialValue: _notificationType,
              decoration: const InputDecoration(
                labelText: 'Notification Type',
                prefixIcon: Icon(Icons.notifications_rounded),
              ),
              items: AppConstants.notificationTypes
                  .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                  .toList(),
              onChanged: (v) => setState(() => _notificationType = v!),
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Any additional details...',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: isEditing ? 'Update Task' : 'Save Task',
                icon: Icons.check_rounded,
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    if (widget.task?.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
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
      await context.read<TaskProvider>().deleteTask(widget.task!.id!);
      if (mounted) Navigator.pop(context, true);
    }
  }
}
