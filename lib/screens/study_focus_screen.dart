/// Study Focus / Pomodoro Timer screen for distraction-free study sessions.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timecash/models/task.dart';
import 'package:timecash/providers/task_provider.dart';
import 'package:timecash/utils/theme.dart';
import 'package:timecash/widgets/common_widgets.dart';

class StudyFocusScreen extends StatefulWidget {
  final Task? initialTask;

  const StudyFocusScreen({super.key, this.initialTask});

  @override
  State<StudyFocusScreen> createState() => _StudyFocusScreenState();
}

class _StudyFocusScreenState extends State<StudyFocusScreen> {
  static const List<int> _presetMinutes = [25, 45, 60, 5, 15];

  late int _selectedMinutes;
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;
  Task? _selectedTask;

  final List<String> _motivationalQuotes = [
    'Deep focus produces outstanding results.',
    'Small consistent efforts lead to massive success.',
    'Put your phone on silent and own this study hour.',
    'Discipline is choosing between what you want now and what you want most.',
    'One focused hour is worth three distracted hours.',
  ];
  int _quoteIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedTask = widget.initialTask;
    _selectedMinutes = 25;
    _remainingSeconds = _selectedMinutes * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _selectPreset(int minutes) {
    if (_isRunning) return;
    setState(() {
      _selectedMinutes = minutes;
      _remainingSeconds = minutes * 60;
      _quoteIndex = (_quoteIndex + 1) % _motivationalQuotes.length;
    });
  }

  void _toggleTimer() {
    if (_isRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    HapticFeedback.lightImpact();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        _onSessionComplete();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
    HapticFeedback.lightImpact();
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _selectedMinutes * 60;
    });
    HapticFeedback.mediumImpact();
  }

  Future<void> _onSessionComplete() async {
    setState(() => _isRunning = false);
    HapticFeedback.heavyImpact();

    if (_selectedTask != null && _selectedTask!.id != null) {
      await context.read<TaskProvider>().completeTask(_selectedTask!.id!);
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration_rounded, color: AppTheme.successGreen),
            SizedBox(width: 8),
            Text('Session Completed! 🎉'),
          ],
        ),
        content: Text(
          _selectedTask != null
              ? 'Great job! You finished your study session for "${_selectedTask!.title}".'
              : 'Great job! You finished your $_selectedMinutes minute study session.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  String _formatTime() {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final taskProvider = context.watch<TaskProvider>();
    final availableTasks = taskProvider.todayTasks
        .where((t) => !t.isCompleted && !t.isSkipped)
        .toList();

    final totalSeconds = _selectedMinutes * 60;
    final progress = totalSeconds > 0
        ? (1.0 - (_remainingSeconds / totalSeconds)).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Focus Mode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _resetTimer,
            tooltip: 'Reset Timer',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            // Task selector dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: DropdownButtonFormField<Task?>(
                initialValue: _selectedTask,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Focusing on task (optional)',
                  prefixIcon: Icon(Icons.task_alt_rounded),
                ),
                items: [
                  const DropdownMenuItem<Task?>(
                    value: null,
                    child: Text('General Focus Session'),
                  ),
                  ...availableTasks.map(
                    (t) => DropdownMenuItem<Task?>(
                      value: t,
                      child: Text(
                        '${t.title} (${t.startTime})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: _isRunning
                    ? null
                    : (task) => setState(() => _selectedTask = task),
              ),
            ),

            const Spacer(),

            // Circular progress timer
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 240,
                  height: 240,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: isDark
                        ? AppTheme.darkSurfaceHigh
                        : AppTheme.lightSurfaceHigh,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.primaryIndigo),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isRunning ? 'FOCUSING' : 'READY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: _isRunning
                            ? AppTheme.primaryIndigo
                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Motivational quote card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                '“${_motivationalQuotes[_quoteIndex]}”',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const Spacer(),

            // Preset duration chips
            Wrap(
              spacing: 8,
              children: _presetMinutes.map((m) {
                final isSelected = _selectedMinutes == m;
                final isBreak = m <= 15;
                return ChoiceChip(
                  label: Text(isBreak ? '${m}m Break' : '${m}m Study'),
                  selected: isSelected,
                  onSelected: _isRunning ? null : (_) => _selectPreset(m),
                  selectedColor:
                      AppTheme.primaryIndigo.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppTheme.primaryIndigo : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: _isRunning ? 'Pause' : 'Start Focus',
                      icon: _isRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: _isRunning ? AppTheme.warningOrange : AppTheme.primaryIndigo,
                      onPressed: _toggleTimer,
                    ),
                  ),
                  if (_isRunning || _remainingSeconds < totalSeconds) ...[
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.check_rounded),
                      tooltip: 'Mark Done Early',
                      onPressed: _onSessionComplete,
                      style: IconButton.styleFrom(
                        backgroundColor:
                            AppTheme.successGreen.withValues(alpha: 0.15),
                        foregroundColor: AppTheme.successGreen,
                        padding: const EdgeInsets.all(14),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
