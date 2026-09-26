import 'package:flutter_test/flutter_test.dart';
import 'package:timecash/models/task.dart';
import 'package:timecash/models/expense.dart';
import 'package:timecash/models/budget.dart';
import 'package:timecash/utils/constants.dart';

void main() {
  group('Standalone Core Logic Tests', () {
    final now = DateTime.now().toIso8601String();

    test('Task model serialization and properties', () {
      final task = Task(
        id: 1,
        title: 'Operating Systems Revision',
        subject: 'Study',
        startTime: '10:00',
        endTime: '11:30',
        date: '2026-09-25',
        repeatType: 'Daily',
        repeatDays: '1,2,3,4,5',
        priority: 'Critical',
        notificationType: 'Alarm-style reminder',
        notes: 'Memory management',
        status: 'Upcoming',
        createdAt: now,
        updatedAt: now,
      );

      final map = task.toMap();
      expect(map['id'], 1);
      expect(map['title'], 'Operating Systems Revision');
      expect(map['start_time'], '10:00');
      expect(map['end_time'], '11:30');
      expect(map['repeat_days'], '1,2,3,4,5');

      final deserialized = Task.fromMap(map);
      expect(deserialized.title, task.title);
      expect(deserialized.priority, 'Critical');
      expect(deserialized.notificationType, 'Alarm-style reminder');

      expect(task.durationMinutes, 90);
      expect(task.startDateTime.hour, 10);
      expect(task.endDateTime.hour, 11);
      expect(task.endDateTime.minute, 30);
      expect(task.isUpcoming, isTrue);
      expect(task.isCompleted, isFalse);
      expect(task.isCritical, isTrue);
    });

    test('Task collision detection', () {
      final task = Task(
        id: 1,
        title: 'Operating Systems Revision',
        startTime: '10:00',
        endTime: '11:30',
        date: '2026-09-25',
        createdAt: now,
        updatedAt: now,
      );

      final overlapping = Task(
        id: 2,
        title: 'Algorithms',
        startTime: '11:00',
        endTime: '12:00',
        date: '2026-09-25',
        createdAt: now,
        updatedAt: now,
      );
      expect(task.overlapsWith(overlapping), isTrue);

      final nonOverlapping = Task(
        id: 3,
        title: 'Gym',
        startTime: '12:00',
        endTime: '13:00',
        date: '2026-09-25',
        createdAt: now,
        updatedAt: now,
      );
      expect(task.overlapsWith(nonOverlapping), isFalse);

      final diffDate = Task(
        id: 4,
        title: 'Algorithms',
        startTime: '10:30',
        endTime: '11:30',
        date: '2026-09-26',
        createdAt: now,
        updatedAt: now,
      );
      expect(task.overlapsWith(diffDate), isFalse);
    });

    test('Expense model serialization', () {
      final expense = Expense(
        id: 10,
        amount: 150.50,
        category: 'Food',
        note: 'College Canteen Lunch',
        paymentMethod: 'UPI',
        date: '2026-09-25',
        createdAt: now,
        updatedAt: now,
      );

      final expMap = expense.toMap();
      expect(expMap['amount'], 150.50);
      expect(expMap['category'], 'Food');
      expect(expMap['payment_method'], 'UPI');

      final expDeser = Expense.fromMap(expMap);
      expect(expDeser.amount, 150.50);
      expect(expDeser.note, 'College Canteen Lunch');
      expect(expDeser.paymentMethod, 'UPI');
    });

    test('Budget model and AppConstants', () {
      const budget = Budget(
        id: 5,
        category: 'Overall',
        monthlyLimit: 5000.0,
        month: '2026-09',
      );

      final bMap = budget.toMap();
      expect(bMap['monthly_limit'], 5000.0);
      expect(bMap['month'], '2026-09');

      final bDeser = Budget.fromMap(bMap);
      expect(bDeser.category, 'Overall');
      expect(bDeser.monthlyLimit, 5000.0);

      expect(AppConstants.appName, 'Flowra');
      expect(AppConstants.defaultCurrency, '₹');
      expect(AppConstants.defaultCurrencyCode, 'INR');
      expect(AppConstants.studyAlertChannelId, 'study_alerts');
      expect(AppConstants.expenseCategories.length, 8);
      expect(AppConstants.paymentMethods.length, 4);
    });
  });
}
