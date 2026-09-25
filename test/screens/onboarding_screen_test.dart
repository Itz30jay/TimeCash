import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timecash/providers/settings_provider.dart';
import 'package:timecash/screens/onboarding_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OnboardingScreen Tests', () {
    testWidgets('renders intro page and navigates through pages', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
          child: const MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      // Verify page 1 title and Skip button
      expect(find.text('Plan your study time'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      // Swipe or tap next to go to page 2
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify page 2
      expect(find.text('Get reminders even in silent mode'), findsOneWidget);

      // Tap next to go to page 3
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify page 3
      expect(find.text('Track where your money goes'), findsOneWidget);

      // Tap next to open setup sheet
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify setup bottom sheet is displayed
      expect(find.text('Quick Setup'), findsOneWidget);
      expect(find.text('Currency'), findsOneWidget);
      expect(find.text('Monthly Budget (optional)'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('Skip button opens setup sheet immediately', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
          child: const MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      // Tap Skip
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Verify setup sheet opens
      expect(find.text('Quick Setup'), findsOneWidget);
      expect(find.text('Currency'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });
  });
}
