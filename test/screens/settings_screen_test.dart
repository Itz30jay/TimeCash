import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timecash/providers/expense_provider.dart';
import 'package:timecash/providers/settings_provider.dart';
import 'package:timecash/providers/task_provider.dart';
import 'package:timecash/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsScreen Tests', () {
    testWidgets('renders all major settings tiles and options', (tester) async {
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
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      // Verify AppBar title
      expect(find.text('Settings'), findsWidgets);

      // Verify sections
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Budget & Currency'), findsOneWidget);
      expect(find.text('Data'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);

      // Verify specific tiles
      expect(find.text('Notification Permission'), findsOneWidget);
      expect(find.text('Exact Alarm Permission'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Role'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Currency'), findsOneWidget);
      expect(find.text('Monthly Budget'), findsOneWidget);
      expect(find.text('Load Sample Data'), findsOneWidget);
      expect(find.text('Export Expenses as CSV'), findsOneWidget);
      expect(find.text('Clear All Data'), findsOneWidget);
      expect(find.text('About the Developer'), findsOneWidget);
      expect(find.text('View Source Code'), findsNothing);
      expect(find.text('About Flowra'), findsOneWidget);
    });

    testWidgets('tapping About Flowra opens dialog with version and GitHub link', (tester) async {
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
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      // Tap About Flowra
      await tester.tap(find.text('About Flowra'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Flowra'), findsWidgets);
      expect(find.textContaining('100% offline'), findsOneWidget);
      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Close'), findsNothing);
    });
  });
}
