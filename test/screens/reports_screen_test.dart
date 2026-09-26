import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timecash/providers/expense_provider.dart';
import 'package:timecash/providers/settings_provider.dart';
import 'package:timecash/providers/task_provider.dart';
import 'package:timecash/screens/reports_screen.dart';
import 'package:timecash/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService().initialize();
  });

  group('ReportsScreen Tests', () {
    testWidgets('renders Study report tab by default with stat cards', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => TaskProvider()),
            ChangeNotifierProvider(create: (_) => ExpenseProvider()),
          ],
          child: const MaterialApp(
            home: ReportsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify AppBar and tabs
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Money'), findsOneWidget);

      // Verify Study tab stat cards
      expect(find.text('Planned'), findsOneWidget);
      expect(find.text('Completed'), findsWidgets);
      expect(find.text('Missed'), findsWidgets);
      expect(find.text('Completion Rate'), findsOneWidget);
      expect(find.text('Current Streak'), findsOneWidget);
    });

    testWidgets('switches to Money report tab and renders spending cards', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => TaskProvider()),
            ChangeNotifierProvider(create: (_) => ExpenseProvider()),
          ],
          child: const MaterialApp(
            home: ReportsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Money' tab
      await tester.tap(find.text('Money'));
      await tester.pumpAndSettle();

      // Verify Money tab stat cards
      expect(find.text('Monthly Total'), findsOneWidget);
      expect(find.text('Daily Average'), findsOneWidget);
      expect(find.text('Top Category'), findsOneWidget);
    });
  });
}
