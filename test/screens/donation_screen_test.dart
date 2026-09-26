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
      expect(find.text('About the Developer'), findsOneWidget);
      expect(find.text('Support Flowra'), findsOneWidget);
      expect(
        find.textContaining('Flowra is free'),
        findsOneWidget,
      );

      // Verify preset amounts
      expect(find.text('₹10'), findsOneWidget);
      expect(find.text('₹20'), findsOneWidget);
      expect(find.text('₹50'), findsOneWidget);
      expect(find.text('₹100'), findsOneWidget);

      // Verify Copy UPI ID button exists
      expect(find.textContaining('Copy UPI ID'), findsOneWidget);

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

    testWidgets('renders footer with social links and copyright', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: DonationScreen(),
        ),
      );

      // Developer social links
      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('Instagram'), findsOneWidget);

      // Scroll to the footer
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -800));
      await tester.pumpAndSettle();

      // Copyright text (year is dynamic)
      expect(find.textContaining('©'), findsOneWidget);
      expect(find.textContaining('All rights reserved.'), findsOneWidget);

      // Made with love text
      expect(find.textContaining('Made with'), findsOneWidget);

      // Open-source text should NOT exist
      expect(find.textContaining('open-source'), findsNothing);

      // Support encouragement text
      expect(find.text('If Flowra helps you, consider supporting its development ❤️'), findsOneWidget);
    });
  });
}
