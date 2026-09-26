import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowra/providers/expense_provider.dart';
import 'package:flowra/providers/settings_provider.dart';
import 'package:flowra/providers/task_provider.dart';
import 'package:flowra/screens/home_screen.dart';
import 'package:flowra/screens/study_focus_screen.dart';
import 'package:flowra/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService().initialize();
  });

  group('HomeScreen Tests', () {
    testWidgets('renders streak banner, quick actions, stats, and empty tasks state', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool addTaskTriggered = false;
      bool addExpenseTriggered = false;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => TaskProvider()),
            ChangeNotifierProvider(create: (_) => ExpenseProvider()),
          ],
          child: MaterialApp(
            home: HomeScreen(
              onAddTask: () => addTaskTriggered = true,
              onAddExpense: () => addExpenseTriggered = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify streak banner & next task card
      expect(find.text('Ignite Your Study Streak'), findsOneWidget);
      expect(find.text('All caught up!'), findsOneWidget);
      expect(find.text('No upcoming tasks for now'), findsOneWidget);

      // Verify quick action buttons
      expect(find.text('Add Task'), findsWidgets);
      expect(find.text('Focus Timer'), findsOneWidget);
      expect(find.text('Add Expense'), findsOneWidget);

      // Verify today stats
      expect(find.text('Tasks Done'), findsOneWidget);
      expect(find.text("Today's Spend"), findsOneWidget);

      // Verify Today's Schedule section
      expect(find.text("Today's Schedule"), findsOneWidget);
      expect(find.text('No tasks today'), findsOneWidget);
      expect(find.text('Tap + to add your first study session'), findsOneWidget);

      // Test tapping Add Expense quick action
      await tester.tap(find.text('Add Expense'));
      await tester.pumpAndSettle();
      expect(addExpenseTriggered, isTrue);

      // Test tapping Add Task button in empty state
      await tester.tap(find.text('Add Task').first);
      await tester.pumpAndSettle();
      expect(addTaskTriggered, isTrue);
    });

    testWidgets('tapping Focus Timer opens StudyFocusScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => TaskProvider()),
            ChangeNotifierProvider(create: (_) => ExpenseProvider()),
          ],
          child: MaterialApp(
            home: HomeScreen(
              onAddTask: () {},
              onAddExpense: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Focus Timer
      await tester.tap(find.text('Focus Timer'));
      await tester.pumpAndSettle();

      // Verify StudyFocusScreen opened
      expect(find.byType(StudyFocusScreen), findsOneWidget);
      expect(find.text('Focus Mode'), findsOneWidget);
    });
  });
}
