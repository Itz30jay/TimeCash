import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowra/models/expense.dart';
import 'package:flowra/models/task.dart';

void main() {
  group('Export CSV Formatting Tests', () {
    test('converts expense list to CSV table correctly', () {
      final expenses = [
        const Expense(
          id: 1,
          amount: 150.0,
          category: 'Food',
          note: 'Canteen Lunch',
          paymentMethod: 'UPI',
          date: '2026-09-25',
          createdAt: '2026-09-25T12:00:00',
          updatedAt: '2026-09-25T12:00:00',
        ),
      ];

      final rows = <List<dynamic>>[
        ['Date', 'Amount', 'Category', 'Note', 'Payment Method'],
        ...expenses.map((e) => [
              e.date,
              e.amount,
              e.category,
              e.note ?? '',
              e.paymentMethod ?? '',
            ]),
      ];

      final csv = const ListToCsvConverter().convert(rows);
      expect(csv, contains('Date,Amount,Category,Note,Payment Method'));
      expect(csv, contains('2026-09-25,150.0,Food,Canteen Lunch,UPI'));
    });

    test('converts task list to CSV table correctly', () {
      final tasks = [
        const Task(
          id: 1,
          title: 'Mathematics Study',
          subject: 'Study',
          startTime: '09:00',
          endTime: '10:30',
          date: '2026-09-25',
          priority: 'Critical',
          status: 'Upcoming',
          repeatType: 'Daily',
          notes: 'Integration by parts',
          createdAt: '2026-09-25T08:00:00',
          updatedAt: '2026-09-25T08:00:00',
        ),
      ];

      final rows = <List<dynamic>>[
        [
          'Date',
          'Title',
          'Subject',
          'Start Time',
          'End Time',
          'Priority',
          'Status',
          'Repeat',
          'Notes',
        ],
        ...tasks.map((t) => [
              t.date,
              t.title,
              t.subject ?? '',
              t.startTime,
              t.endTime,
              t.priority,
              t.status,
              t.repeatType,
              t.notes ?? '',
            ]),
      ];

      final csv = const ListToCsvConverter().convert(rows);
      expect(csv, contains('Date,Title,Subject,Start Time,End Time,Priority,Status,Repeat,Notes'));
      expect(csv, contains('2026-09-25,Mathematics Study,Study,09:00,10:30,Critical,Upcoming,Daily,Integration by parts'));
    });
  });
}
