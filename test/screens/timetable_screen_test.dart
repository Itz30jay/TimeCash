import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowra/providers/settings_provider.dart';
import 'package:flowra/providers/task_provider.dart';
import 'package:flowra/screens/timetable_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TimetableScreen Tests', () {
    testWidgets('renders app bar, date header, filter chips, and empty state', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => TaskProvider()),
          ],
          child: const MaterialApp(
            home: TimetableScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify AppBar title and actions
      expect(find.text('Timetable'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);
      expect(find.byIcon(Icons.today_rounded), findsOneWidget);

      // Verify Today date header
      expect(find.text('Today'), findsOneWidget);

      // Verify subject filter chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Study'), findsOneWidget);
      expect(find.text('Revision'), findsOneWidget);

      // Verify empty state when no tasks exist
      expect(find.text('No tasks'), findsOneWidget);
      expect(find.text('No study sessions scheduled for this day'), findsOneWidget);
      expect(find.text('Add Task'), findsOneWidget);
    });

    testWidgets('tapping subject chip selects it and tapping today icon resets view', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => TaskProvider()),
          ],
          child: const MaterialApp(
            home: TimetableScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Study' subject filter chip
      await tester.tap(find.text('Study'));
      await tester.pumpAndSettle();

      // Tap 'Go to Today' action icon
      await tester.tap(find.byIcon(Icons.today_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('No tasks'), findsOneWidget);
    });
  });
}
