import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:timecash/providers/task_provider.dart';
import 'package:timecash/screens/study_focus_screen.dart';

void main() {
  group('StudyFocusScreen Tests', () {
    testWidgets('renders focus timer, presets, and controls', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => TaskProvider()),
          ],
          child: const MaterialApp(
            home: StudyFocusScreen(),
          ),
        ),
      );

      // Verify timer displays 25:00 default
      expect(find.text('25:00'), findsOneWidget);
      expect(find.text('READY'), findsOneWidget);
      expect(find.text('Start Focus'), findsOneWidget);

      // Verify preset chips are present
      expect(find.text('25m Study'), findsOneWidget);
      expect(find.text('45m Study'), findsOneWidget);
      expect(find.text('5m Break'), findsOneWidget);

      // Tap on 5m Break preset
      await tester.tap(find.text('5m Break'));
      await tester.pump();

      // Verify timer updated to 05:00
      expect(find.text('05:00'), findsOneWidget);

      // Tap on Start Focus button
      await tester.tap(find.text('Start Focus'));
      await tester.pump();

      // Verify state changes to FOCUSING and Pause button
      expect(find.text('FOCUSING'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);
    });
  });
}
