import 'package:flutter_test/flutter_test.dart';
import 'package:timecash/utils/helpers.dart';

void main() {
  group('DateTimeHelper Tests', () {
    test('formatDate and parseDateFromDb roundtrip', () {
      final date = DateTime(2026, 9, 25);
      final dbStr = DateTimeHelper.formatDateForDb(date);
      expect(dbStr, '2026-09-25');

      final parsed = DateTimeHelper.parseDateFromDb(dbStr);
      expect(parsed.year, 2026);
      expect(parsed.month, 9);
      expect(parsed.day, 25);
    });

    test('parseTimeFromDb with date', () {
      final date = DateTime(2026, 9, 25);
      final dt = DateTimeHelper.parseTimeFromDb('14:30', date);
      expect(dt.year, 2026);
      expect(dt.month, 9);
      expect(dt.day, 25);
      expect(dt.hour, 14);
      expect(dt.minute, 30);
    });

    test('startOfDay and endOfDay', () {
      final date = DateTime(2026, 9, 25, 15, 30, 45);
      final start = DateTimeHelper.startOfDay(date);
      expect(start.hour, 0);
      expect(start.minute, 0);
      expect(start.second, 0);

      final end = DateTimeHelper.endOfDay(date);
      expect(end.hour, 23);
      expect(end.minute, 59);
      expect(end.second, 59);
    });

    test('getDaysInWeek returns 7 days', () {
      final date = DateTime(2026, 9, 25); // Friday
      final days = DateTimeHelper.getDaysInWeek(date);
      expect(days.length, 7);
      expect(days.first.weekday, DateTime.monday);
      expect(days.last.weekday, DateTime.sunday);
    });
  });

  group('CurrencyHelper Tests', () {
    test('format formats numbers with 2 decimals and currency symbol', () {
      expect(CurrencyHelper.format(1250.50, '₹'), '₹1,250.50');
      expect(CurrencyHelper.format(0, r'$'), r'$0.00');
    });

    test('formatCompact formats large numbers concisely', () {
      expect(CurrencyHelper.formatCompact(150000, '₹'), '₹1.5L');
      expect(CurrencyHelper.formatCompact(2500, '₹'), '₹2.5K');
      expect(CurrencyHelper.formatCompact(500, '₹'), '₹500');
    });
  });

  group('ValidationHelper Tests', () {
    test('validateRequired', () {
      expect(ValidationHelper.validateRequired(null, 'Title'), 'Title is required');
      expect(ValidationHelper.validateRequired('', 'Title'), 'Title is required');
      expect(ValidationHelper.validateRequired('   ', 'Title'), 'Title is required');
      expect(ValidationHelper.validateRequired('Valid Title', 'Title'), isNull);
    });

    test('validateAmount', () {
      expect(ValidationHelper.validateAmount(null), 'Amount is required');
      expect(ValidationHelper.validateAmount(''), 'Amount is required');
      expect(ValidationHelper.validateAmount('abc'), 'Enter a valid amount');
      expect(ValidationHelper.validateAmount('-10'), 'Enter a valid amount');
      expect(ValidationHelper.validateAmount('0'), 'Enter a valid amount');
      expect(ValidationHelper.validateAmount('150.50'), isNull);
    });
  });
}
