import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowra/models/task.dart';
import 'package:flowra/widgets/common_widgets.dart';

void main() {
  group('Common Widgets Tests', () {
    testWidgets('StatCard renders title, value, and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Total Spent',
              value: '₹1,500',
              icon: Icons.account_balance_wallet_rounded,
              color: Colors.indigo,
            ),
          ),
        ),
      );

      expect(find.text('Total Spent'), findsOneWidget);
      expect(find.text('₹1,500'), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_wallet_rounded), findsOneWidget);
    });

    testWidgets('SectionHeader displays title and action', (tester) async {
      bool actionTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Today Schedule',
              actionLabel: 'See All',
              onAction: () => actionTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Today Schedule'), findsOneWidget);
      expect(find.text('See All'), findsOneWidget);

      await tester.tap(find.text('See All'));
      expect(actionTapped, isTrue);
    });

    testWidgets('EmptyState displays title, subtitle and action button',
        (tester) async {
      bool actionPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'No Tasks',
              subtitle: 'Create a task to get started',
              icon: Icons.assignment_rounded,
              buttonLabel: 'Add Task',
              onAction: () => actionPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('No Tasks'), findsOneWidget);
      expect(find.text('Create a task to get started'), findsOneWidget);
      expect(find.text('Add Task'), findsOneWidget);

      await tester.tap(find.text('Add Task'));
      expect(actionPressed, isTrue);
    });

    testWidgets('PrimaryButton renders and triggers callback', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Save Task',
              icon: Icons.check_rounded,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Save Task'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      await tester.tap(find.text('Save Task'));
      expect(pressed, isTrue);
    });

    testWidgets('TaskCard renders task info and triggers onFocus',
        (tester) async {
      bool focusTapped = false;
      const task = Task(
        id: 1,
        title: 'Physics Lab Session',
        subject: 'Study',
        startTime: '10:00',
        endTime: '11:30',
        date: '2026-09-25',
        priority: 'Important',
        createdAt: '2026-09-25T08:00:00',
        updatedAt: '2026-09-25T08:00:00',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(
              task: task,
              onFocus: () => focusTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Physics Lab Session'), findsOneWidget);
      expect(find.text('10:00 – 11:30'), findsOneWidget);
      expect(find.text('Important'), findsOneWidget);
      expect(find.byIcon(Icons.timer_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.timer_rounded));
      expect(focusTapped, isTrue);
    });
  });
}
