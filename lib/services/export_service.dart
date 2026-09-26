/// Export service for generating CSV files from tasks and expenses.
library;

import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timecash/models/task.dart';
import 'package:timecash/models/expense.dart';

class ExportService {
  ExportService._();

  static Future<String> exportExpensesToCsv(
      List<Expense> expenses, String monthLabel) async {
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
    final dir = await _getExportDir();
    final safeName = monthLabel.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
    final file = File('${dir.path}/flowra_expenses_$safeName.csv');
    await file.writeAsString(csv);
    return file.path;
  }

  static Future<String> exportTasksToCsv(
      List<Task> tasks, String label) async {
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
    final dir = await _getExportDir();
    final safeName = label.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
    final file = File('${dir.path}/flowra_tasks_$safeName.csv');
    await file.writeAsString(csv);
    return file.path;
  }

  static Future<List<Expense>> importExpensesFromCsv(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return [];

    final content = await file.readAsString();
    final rows = const CsvToListConverter().convert(content);

    if (rows.length <= 1) return []; // Only header or empty

    final expenses = <Expense>[];
    final now = DateTime.now().toIso8601String();

    for (int i = 1; i < rows.length; i++) {
      try {
        final row = rows[i];
        expenses.add(Expense(
          date: row[0].toString(),
          amount: double.parse(row[1].toString()),
          category: row[2].toString(),
          note: row.length > 3 ? row[3].toString() : null,
          paymentMethod: row.length > 4 ? row[4].toString() : null,
          createdAt: now,
          updatedAt: now,
        ));
      } catch (_) {
        continue; // Skip malformed rows
      }
    }

    return expenses;
  }

  static Future<Directory> _getExportDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${dir.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }
}
