import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timecash/providers/expense_provider.dart';
import 'package:timecash/providers/settings_provider.dart';
import 'package:timecash/screens/expenses_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ExpensesScreen Tests', () {
    testWidgets('renders title, stat cards, search field, category chips, and empty state', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => ExpenseProvider()),
          ],
          child: const MaterialApp(
            home: ExpensesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify AppBar title
      expect(find.text('Expenses'), findsOneWidget);

      // Verify StatCards
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);

      // Verify SectionHeader
      expect(find.text('Recent Expenses'), findsOneWidget);

      // Verify Search TextField
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search expenses...'), findsOneWidget);

      // Verify Category filter chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Travel'), findsOneWidget);

      // Verify empty state when no expenses exist
      expect(find.text('No expenses yet'), findsOneWidget);
      expect(find.text('Tap + to log your first expense'), findsOneWidget);
    });

    testWidgets('allows selecting category filter chip and typing in search', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => ExpenseProvider()),
          ],
          child: const MaterialApp(
            home: ExpensesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Food' filter chip
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(find.byType(TextField), 'Lunch');
      await tester.pumpAndSettle();

      expect(find.text('Lunch'), findsOneWidget);
    });
  });
}
