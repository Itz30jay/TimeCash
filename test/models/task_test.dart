import 'package:flutter_test/flutter_test.dart';
import 'package:flowra/models/task.dart';

void main() {
  group('Task Model Tests', () {
    final now = DateTime.now().toIso8601String();

    test('should correctly serialize to and from Map', () {
      final task = Task(
        id: 1,
        title: 'Math Study',
        subject: 'Study',
        startTime: '09:00',
        endTime: '10:30',
        date: '2026-09-25',
        repeatType: 'Daily',
        repeatDays: '1,2,3,4,5',
        priority: 'Critical',
        notificationType: 'Alarm-style reminder',
        notes: 'Chapter 4 calculus',
        status: 'Upcoming',
        createdAt: now,
        updatedAt: now,
      );

      final map = task.toMap();
      expect(map['id'], 1);
      expect(map['title'], 'Math Study');
      expect(map['start_time'], '09:00');
      expect(map['end_time'], '10:30');
      expect(map['date'], '2026-09-25');
      expect(map['priority'], 'Critical');

      final deserialized = Task.fromMap(map);
      expect(deserialized.id, task.id);
      expect(deserialized.title, task.title);
      expect(deserialized.subject, task.subject);
      expect(deserialized.startTime, task.startTime);
      expect(deserialized.endTime, task.endTime);
      expect(deserialized.date, task.date);
      expect(deserialized.repeatType, task.repeatType);
      expect(deserialized.repeatDays, task.repeatDays);
      expect(deserialized.priority, task.priority);
      expect(deserialized.notificationType, task.notificationType);
      expect(deserialized.notes, task.notes);
      expect(deserialized.status, task.status);
    });

    test('should calculate startDateTime and endDateTime accurately', () {
      final task = Task(
        id: 2,
        title: 'Physics Lab',
        startTime: '14:15',
        endTime: '16:45',
        date: '2026-09-25',
        createdAt: now,
        updatedAt: now,
      );

      final start = task.startDateTime;
      expect(start.year, 2026);
      expect(start.month, 9);
      expect(start.day, 25);
      expect(start.hour, 14);
      expect(start.minute, 15);

      final end = task.endDateTime;
      expect(end.year, 2026);
      expect(end.month, 9);
      expect(end.day, 25);
      expect(end.hour, 16);
      expect(end.minute, 45);
    });

    test('should calculate durationMinutes accurately', () {
      final task = Task(
        id: 3,
        title: 'Calculus Session',
        startTime: '09:00',
        endTime: '10:30',
        date: '2026-09-25',
        createdAt: now,
        updatedAt: now,
      );
      expect(task.durationMinutes, 90);

      final task2 = task.copyWith(startTime: '14:15', endTime: '16:45');
      expect(task2.durationMinutes, 150);
    });

    test('should detect status helpers correctly', () {
      final upcoming = Task(
        title: 'Task A',
        startTime: '10:00',
        endTime: '11:00',
        date: '2026-09-25',
        status: 'Upcoming',
        priority: 'Critical',
        createdAt: now,
        updatedAt: now,
      );
      expect(upcoming.isUpcoming, isTrue);
      expect(upcoming.isCompleted, isFalse);
      expect(upcoming.isCritical, isTrue);

      final completed = upcoming.copyWith(status: 'Completed');
      expect(completed.isCompleted, isTrue);
      expect(completed.isUpcoming, isFalse);

      final running = upcoming.copyWith(status: 'Running');
      expect(running.isRunning, isTrue);

      final missed = upcoming.copyWith(status: 'Missed');
      expect(missed.isMissed, isTrue);
    });

    test('should detect task overlaps on the same day', () {
      final task1 = Task(
        id: 1,
        title: 'Task 1',
        startTime: '10:00',
        endTime: '12:00',
        date: '2026-09-25',
        createdAt: now,
        updatedAt: now,
      );

      final overlapping = Task(
        id: 2,
        title: 'Task 2',
        startTime: '11:30',
        endTime: '13:00',
        date: '2026-09-25',
        createdAt: now,
        updatedAt: now,
      );

      final nonOverlapping = Task(
        id: 3,
        title: 'Task 3',
        startTime: '12:00',
        endTime: '13:00',
        date: '2026-09-25',
        createdAt: now,
        updatedAt: now,
      );

      final differentDay = Task(
        id: 4,
        title: 'Task 4',
        startTime: '10:30',
        endTime: '11:30',
        date: '2026-09-26',
        createdAt: now,
        updatedAt: now,
      );

      expect(task1.overlapsWith(overlapping), isTrue);
      expect(task1.overlapsWith(nonOverlapping), isFalse);
      expect(task1.overlapsWith(differentDay), isFalse);
    });
  });
}
