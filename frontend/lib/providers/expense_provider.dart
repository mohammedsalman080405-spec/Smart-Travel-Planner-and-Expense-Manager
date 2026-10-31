import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchExpenses(int tripId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _expenses = await ExpenseService.getTripExpenses(tripId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> addExpense({
    required int tripId,
    required String category,
    required double amount,
    required String expenseDate,
    String? description,
    String currency = 'USD',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final exp = await ExpenseService.addExpense(
        tripId: tripId,
        category: category,
        amount: amount,
        expenseDate: expenseDate,
        description: description,
        currency: currency,
      );
      _expenses.insert(0, exp);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteExpense(int expenseId) async {
    try {
      await ExpenseService.deleteExpense(expenseId);
      _expenses.removeWhere((e) => e.expenseId == expenseId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }
}
