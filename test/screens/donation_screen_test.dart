import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timecash/screens/donation_screen.dart';

void main() {
  group('DonationScreen Tests', () {
    testWidgets('renders preset donation amounts and custom input', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DonationScreen(),
        ),
      );

      // Verify header and title
      expect(find.text('Support the Developer'), findsOneWidget);
      expect(find.text('Support TimeCash'), findsOneWidget);
      expect(
        find.textContaining('TimeCash is free and offline.'),
        findsOneWidget,
      );

      // Verify preset amounts
      expect(find.text('₹10'), findsOneWidget);
      expect(find.text('₹20'), findsOneWidget);
      expect(find.text('₹50'), findsOneWidget);
      expect(find.text('₹100'), findsOneWidget);

      // Initially button says 'Select an Amount'
      expect(find.text('Select an Amount'), findsOneWidget);

      // Select preset ₹100
      await tester.tap(find.text('₹100'));
      await tester.pump();

      // Button now updates to 'Donate ₹100'
      expect(find.text('Donate ₹100'), findsOneWidget);

      // Enter custom amount
      await tester.enterText(find.byType(TextField), '300');
      await tester.pump();

      // Button now updates to 'Donate ₹300'
      expect(find.text('Donate ₹300'), findsOneWidget);
    });
  });
}
