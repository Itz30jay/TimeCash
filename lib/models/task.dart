/// Task model for study schedule items.
library;

import 'package:flowra/utils/constants.dart';

class Task {
  final int? id;
  final String title;
  final String? subject;
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final String date; // yyyy-MM-dd
  final String repeatType;
  final String? repeatDays; // Comma-separated day numbers (1=Mon, 7=Sun)
  final String priority;
  final String notificationType;
  final String? notes;
  final String status;
  final String createdAt;
  final String updatedAt;

  const Task({
    this.id,
    required this.title,
    this.subject,
    required this.startTime,
    required this.endTime,
    required this.date,
    this.repeatType = 'Once',
    this.repeatDays,
    this.priority = 'Normal',
    this.notificationType = 'Sound + vibration',
    this.notes,
    this.status = 'Upcoming',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'subject': subject,
      'start_time': startTime,
      'end_time': endTime,
      'date': date,
      'repeat_type': repeatType,
      'repeat_days': repeatDays,
      'priority': priority,
      'notification_type': notificationType,
      'notes': notes,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      subject: map['subject'] as String?,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      date: map['date'] as String,
      repeatType: map['repeat_type'] as String? ?? 'Once',
      repeatDays: map['repeat_days'] as String?,
      priority: map['priority'] as String? ?? 'Normal',
      notificationType:
          map['notification_type'] as String? ?? 'Sound + vibration',
      notes: map['notes'] as String?,
      status: map['status'] as String? ?? AppConstants.statusUpcoming,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Task copyWith({
    int? id,
    String? title,
    String? subject,
    String? startTime,
    String? endTime,
    String? date,
    String? repeatType,
    String? repeatDays,
    String? priority,
    String? notificationType,
    String? notes,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      date: date ?? this.date,
      repeatType: repeatType ?? this.repeatType,
      repeatDays: repeatDays ?? this.repeatDays,
      priority: priority ?? this.priority,
      notificationType: notificationType ?? this.notificationType,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get the start DateTime for this task
  DateTime get startDateTime {
    final dateParts = date.split('-');
    final timeParts = startTime.split(':');
    return DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  /// Get the end DateTime for this task
  DateTime get endDateTime {
    final dateParts = date.split('-');
    final timeParts = endTime.split(':');
    return DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  bool get isCompleted => status == AppConstants.statusCompleted;
  bool get isMissed => status == AppConstants.statusMissed;
  bool get isUpcoming => status == AppConstants.statusUpcoming;
  bool get isRunning => status == AppConstants.statusRunning;
  bool get isSkipped => status == AppConstants.statusSkipped;
  bool get isCritical => priority == 'Critical';
  bool get isImportant => priority == 'Important';

  /// Duration in minutes
  int get durationMinutes {
    final start = startDateTime;
    final end = endDateTime;
    final diff = end.difference(start).inMinutes;
    return diff > 0 ? diff : 0;
  }

  /// Check if this task overlaps with another task
  bool overlapsWith(Task other) {
    if (date != other.date) return false;
    final thisStart = startDateTime;
    final thisEnd = endDateTime;
    final otherStart = other.startDateTime;
    final otherEnd = other.endDateTime;
    return thisStart.isBefore(otherEnd) && otherStart.isBefore(thisEnd);
  }

  @override
  String toString() => 'Task(id: $id, title: $title, date: $date, status: $status)';
}
