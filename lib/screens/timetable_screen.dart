/// Timetable screen with daily timeline and weekly calendar view.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flowra/models/task.dart';
import 'package:flowra/providers/task_provider.dart';
import 'package:flowra/providers/settings_provider.dart';
import 'package:flowra/screens/add_edit_task_screen.dart';
import 'package:flowra/screens/study_focus_screen.dart';
import 'package:flowra/utils/constants.dart';
import 'package:flowra/utils/helpers.dart';
import 'package:flowra/utils/theme.dart';
import 'package:flowra/widgets/common_widgets.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Task> _selectedDayTasks = [];
  bool _isLoading = false;
  String _selectedSubject = 'All';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final taskProvider = context.read<TaskProvider>();
    _selectedDayTasks = await taskProvider.getTasksForDate(_selectedDate);
    setState(() => _isLoading = false);
  }

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = date);
    _loadTasks();
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      _selectDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredTasks = _selectedSubject == 'All'
        ? _selectedDayTasks
        : _selectedDayTasks
            .where((t) => t.subject == _selectedSubject)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: _pickCustomDate,
            tooltip: 'Pick Date',
          ),
          IconButton(
            icon: const Icon(Icons.today_rounded),
            onPressed: () => _selectDate(DateTime.now()),
            tooltip: 'Go to Today',
          ),
        ],
      ),
      body: Column(
        children: [
          // Permission banner
          PermissionBanner(
            showNotificationWarning: !settings.hasNotificationPermission,
            showExactAlarmWarning: !settings.hasExactAlarmPermission,
            onFixNotification: () =>
                settings.requestNotificationPermission(),
            onFixAlarm: () => settings.requestExactAlarmPermission(),
          ),

          // Week day selector
          _buildWeekSelector(isDark),

          // Date header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateTimeHelper.isToday(_selectedDate)
                      ? 'Today'
                      : DateTimeHelper.formatDate(_selectedDate),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                if (_selectedDayTasks.isNotEmpty)
                  _buildCompletionChip(),
              ],
            ),
          ),

          // Subject filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: ['All', ...AppConstants.taskSubjects].map((subj) {
                final isSelected = _selectedSubject == subj;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(subj),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedSubject = subj),
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

          // Tasks list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedDayTasks.isEmpty
                    ? EmptyState(
                        title: 'No tasks',
                        subtitle: 'No study sessions scheduled for this day',
                        icon: Icons.event_note_rounded,
                        buttonLabel: 'Add Task',
                        onAction: _addTask,
                      )
                    : filteredTasks.isEmpty
                        ? EmptyState(
                            title: 'No $_selectedSubject tasks',
                            subtitle:
                                'No study sessions found under this subject filter',
                            icon: Icons.filter_alt_off_rounded,
                            buttonLabel: 'Show All',
                            onAction: () =>
                                setState(() => _selectedSubject = 'All'),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadTasks,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 100),
                              itemCount: filteredTasks.length,
                              itemBuilder: (context, index) {
                                final task = filteredTasks[index];
                            return Dismissible(
                              key: Key('task_${task.id}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                color: AppTheme.dangerRed,
                                child: const Icon(Icons.delete_rounded,
                                    color: Colors.white),
                              ),
                              confirmDismiss: (_) => _confirmDelete(task),
                              onDismissed: (_) async {
                                await context
                                    .read<TaskProvider>()
                                    .deleteTask(task.id!);
                                _loadTasks();
                              },
                              child: TaskCard(
                                task: task,
                                onTap: () => _editTask(task),
                                onFocus: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          StudyFocusScreen(initialTask: task),
                                    ),
                                  ).then((_) => _loadTasks());
                                },
                                onStart: task.isUpcoming
                                    ? () async {
                                        await context
                                            .read<TaskProvider>()
                                            .startTask(task.id!);
                                        _loadTasks();
                                      }
                                    : null,
                                onComplete: task.isRunning
                                    ? () async {
                                        await context
                                            .read<TaskProvider>()
                                            .completeTask(task.id!);
                                        _loadTasks();
                                      }
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildWeekSelector(bool isDark) {
    final weekDays = DateTimeHelper.getDaysInWeek(_selectedDate);

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: weekDays.length,
        itemBuilder: (context, index) {
          final day = weekDays[index];
          final isSelected = day.day == _selectedDate.day &&
              day.month == _selectedDate.month &&
              day.year == _selectedDate.year;
          final isToday = DateTimeHelper.isToday(day);

          return GestureDetector(
            onTap: () => _selectDate(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryIndigo
                    : isToday
                        ? AppTheme.primaryIndigo.withValues(alpha: 0.1)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: isToday && !isSelected
                    ? Border.all(color: AppTheme.primaryIndigo, width: 1.5)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateTimeHelper.formatDayOfWeekShort(day),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : isDark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : isDark
                              ? Colors.white
                              : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompletionChip() {
    final completed =
        _selectedDayTasks.where((t) => t.isCompleted).length;
    final total = _selectedDayTasks.length;
    final percent = total > 0 ? (completed / total * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.successGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$completed/$total done ($percent%)',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.successGreen,
        ),
      ),
    );
  }

  Future<void> _addTask() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditTaskScreen(
          task: Task(
            title: '',
            startTime: DateTimeHelper.formatTimeForDb(DateTime.now()),
            endTime: DateTimeHelper.formatTimeForDb(
                DateTime.now().add(const Duration(hours: 1))),
            date: DateTimeHelper.formatDateForDb(_selectedDate),
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
          ),
        ),
      ),
    );
    if (result == true) _loadTasks();
  }

  Future<void> _editTask(Task task) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddEditTaskScreen(task: task)),
    );
    if (result == true) _loadTasks();
  }

  Future<bool?> _confirmDelete(Task task) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Delete "${task.title}"?'),
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
  }
}
