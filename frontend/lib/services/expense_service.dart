import '../config/api_config.dart';
import '../models/expense.dart';
import 'api_service.dart';

class ExpenseService {
  static Future<List<Expense>> getTripExpenses(int tripId) async {
    final response = await ApiService.get(ApiConfig.tripExpenses(tripId), needsAuth: true);
    if (response is List) {
      return response.map((e) => Expense.fromJson(e)).toList();
    }
    return [];
  }

  static Future<Expense> addExpense({
    required int tripId,
    required String category,
    required double amount,
    required String expenseDate,
    String? description,
    String currency = 'USD',
  }) async {
    final response = await ApiService.post(
      ApiConfig.expenses,
      body: {
        'trip_id': tripId,
        'category': category,
        'amount': amount,
        'expense_date': expenseDate,
        'description': description ?? '',
        'currency': currency,
      },
      needsAuth: true,
    );
    return Expense.fromJson(response['expense']);
  }

  static Future<void> deleteExpense(int expenseId) async {
    await ApiService.delete(ApiConfig.expenseDetails(expenseId), needsAuth: true);
  }
}
