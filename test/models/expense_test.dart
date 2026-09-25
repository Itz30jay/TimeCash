import 'package:flutter_test/flutter_test.dart';
import 'package:timecash/models/expense.dart';

void main() {
  group('Expense Model Tests', () {
    final now = DateTime.now().toIso8601String();

    test('should correctly serialize to and from Map', () {
      final expense = Expense(
        id: 10,
        amount: 250.75,
        category: 'Food',
        note: 'College Canteen Lunch',
        paymentMethod: 'UPI',
        date: '2026-09-25',
        createdAt: now,
        updatedAt: now,
      );

      final map = expense.toMap();
      expect(map['id'], 10);
      expect(map['amount'], 250.75);
      expect(map['category'], 'Food');
      expect(map['note'], 'College Canteen Lunch');
      expect(map['payment_method'], 'UPI');
      expect(map['date'], '2026-09-25');

      final deserialized = Expense.fromMap(map);
      expect(deserialized.id, 10);
      expect(deserialized.amount, 250.75);
      expect(deserialized.category, 'Food');
      expect(deserialized.note, 'College Canteen Lunch');
      expect(deserialized.paymentMethod, 'UPI');
      expect(deserialized.date, '2026-09-25');
    });

    test('copyWith should update specified fields only', () {
      final original = Expense(
        id: 1,
        amount: 100.0,
        category: 'Travel',
        date: '2026-09-25',
        createdAt: now,
        updatedAt: now,
      );

      final updated = original.copyWith(amount: 150.0, note: 'Metro card reload');
      expect(updated.id, original.id);
      expect(updated.amount, 150.0);
      expect(updated.category, 'Travel');
      expect(updated.note, 'Metro card reload');
      expect(updated.date, '2026-09-25');
    });
  });
}
