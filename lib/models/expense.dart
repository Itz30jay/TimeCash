/// Expense model for tracking daily spending.
library;

class Expense {
  final int? id;
  final double amount;
  final String category;
  final String? note;
  final String? paymentMethod;
  final String date; // yyyy-MM-dd
  final String createdAt;
  final String updatedAt;

  const Expense({
    this.id,
    required this.amount,
    required this.category,
    this.note,
    this.paymentMethod,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'category': category,
      'note': note,
      'payment_method': paymentMethod,
      'date': date,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      note: map['note'] as String?,
      paymentMethod: map['payment_method'] as String?,
      date: map['date'] as String,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Expense copyWith({
    int? id,
    double? amount,
    String? category,
    String? note,
    String? paymentMethod,
    String? date,
    String? createdAt,
    String? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Expense(id: $id, amount: $amount, category: $category, date: $date)';
}
