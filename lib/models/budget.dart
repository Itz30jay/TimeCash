/// Budget model for monthly category and overall budgets.
library;

class Budget {
  final int? id;
  final String category; // 'Overall' for monthly total budget
  final double monthlyLimit;
  final String month; // yyyy-MM

  const Budget({
    this.id,
    required this.category,
    required this.monthlyLimit,
    required this.month,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category': category,
      'monthly_limit': monthlyLimit,
      'month': month,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      category: map['category'] as String,
      monthlyLimit: (map['monthly_limit'] as num).toDouble(),
      month: map['month'] as String,
    );
  }

  Budget copyWith({
    int? id,
    String? category,
    double? monthlyLimit,
    String? month,
  }) {
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      month: month ?? this.month,
    );
  }
}
