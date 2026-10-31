class Expense {
  final int expenseId;
  final int tripId;
  final int userId;
  final String category;
  final double amount;
  final String currency;
  final String expenseDate;
  final String? description;
  final String? createdAt;

  Expense({
    required this.expenseId,
    required this.tripId,
    required this.userId,
    required this.category,
    required this.amount,
    this.currency = 'INR',
    required this.expenseDate,
    this.description,
    this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      expenseId: json['expense_id'] ?? 0,
      tripId: json['trip_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      category: json['category'] ?? 'Other',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'INR',
      expenseDate: json['expense_date'] ?? '',
      description: json['description'],
      createdAt: json['created_at'],
    );
  }
}
