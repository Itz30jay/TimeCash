/// Date, time, and currency formatting helpers.
library;

import 'package:intl/intl.dart';

class DateTimeHelper {
  DateTimeHelper._();

  static String formatDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('d MMM').format(date);
  }

  static String formatDateForDb(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static DateTime parseDateFromDb(String date) {
    return DateFormat('yyyy-MM-dd').parse(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat.jm().format(time);
  }

  static String formatTime24(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  static String formatTimeForDb(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  static DateTime parseTimeFromDb(String time, DateTime date) {
    final parts = time.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  static String formatMonth(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  static String formatMonthShort(DateTime date) {
    return DateFormat('MMM yyyy').format(date);
  }

  static String formatMonthForDb(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  static String formatDayOfWeek(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  static String formatDayOfWeekShort(DateTime date) {
    return DateFormat('EEE').format(date);
  }

  static String formatDateTime(DateTime date, [String? time]) {
    if (time != null && time.isNotEmpty) {
      try {
        final parsed = parseTimeFromDb(time, date);
        return DateFormat('d MMM yyyy · h:mm a').format(parsed);
      } catch (_) {}
    }
    return DateFormat('d MMM yyyy · h:mm a').format(date);
  }

  static String formatFullDateTime(DateTime date) {
    return DateFormat('d MMM yyyy, h:mm a').format(date);
  }

  static String getGreeting({String? name}) {
    final hour = DateTime.now().hour;
    String base;
    if (hour < 12) {
      base = 'Good morning';
    } else if (hour < 17) {
      base = 'Good afternoon';
    } else {
      base = 'Good evening';
    }
    if (name != null && name.isNotEmpty) {
      return '$base, $name 👋';
    }
    return base;
  }

  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = dateTime.difference(now);

    if (diff.isNegative) {
      if (diff.inMinutes.abs() < 1) return 'Just now';
      if (diff.inMinutes.abs() < 60) return '${diff.inMinutes.abs()}m ago';
      if (diff.inHours.abs() < 24) return '${diff.inHours.abs()}h ago';
      return '${diff.inDays.abs()}d ago';
    }

    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return 'In ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'In ${diff.inHours}h';
    return 'In ${diff.inDays}d';
  }

  static String getCountdown(DateTime target) {
    final now = DateTime.now();
    final diff = target.difference(now);
    if (diff.isNegative) return 'Past due';

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  }

  static List<DateTime> getDaysInWeek(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
  }
}

class CurrencyHelper {
  CurrencyHelper._();

  static String format(double amount, String symbol) {
    final formatter = NumberFormat('#,##0.00');
    return '$symbol${formatter.format(amount)}';
  }

  static String formatCompact(double amount, String symbol) {
    if (amount >= 100000) {
      return '$symbol${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '$symbol${amount.toStringAsFixed(0)}';
  }
}

class ValidationHelper {
  ValidationHelper._();

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Enter a valid amount';
    }
    return null;
  }

  static String? validateTimeRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 'Select start and end time';
    if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
      return 'End time must be after start time';
    }
    return null;
  }
}
