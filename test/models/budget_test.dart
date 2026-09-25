import 'package:flutter_test/flutter_test.dart';
import 'package:timecash/models/budget.dart';

void main() {
  group('Budget Model Tests', () {
    test('should correctly serialize to and from Map', () {
      const budget = Budget(
        id: 5,
        category: 'Food',
        monthlyLimit: 3000.0,
        month: '2026-09',
      );

      final map = budget.toMap();
      expect(map['id'], 5);
      expect(map['category'], 'Food');
      expect(map['monthly_limit'], 3000.0);
      expect(map['month'], '2026-09');

      final deserialized = Budget.fromMap(map);
      expect(deserialized.id, 5);
      expect(deserialized.category, 'Food');
      expect(deserialized.monthlyLimit, 3000.0);
      expect(deserialized.month, '2026-09');
    });

    test('copyWith should allow overriding properties', () {
      const budget = Budget(
        id: 1,
        category: 'Overall',
        monthlyLimit: 5000.0,
        month: '2026-09',
      );

      final updated = budget.copyWith(monthlyLimit: 6000.0);
      expect(updated.id, 1);
      expect(updated.category, 'Overall');
      expect(updated.monthlyLimit, 6000.0);
      expect(updated.month, '2026-09');
    });
  });
}
