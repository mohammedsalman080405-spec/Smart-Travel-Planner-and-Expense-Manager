import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../services/budget_service.dart';

class BudgetProvider extends ChangeNotifier {
  BudgetSummary? _summary;
  bool _isLoading = false;
  String? _errorMessage;

  BudgetSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchBudget(int tripId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _summary = await BudgetService.getTripFinancialSummary(tripId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> updateBudget({
    required int tripId,
    double? accommodationBudget,
    double? transportBudget,
    double? foodBudget,
    double? activitiesBudget,
    double? shoppingBudget,
    double? otherBudget,
    String? currency,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _summary = await BudgetService.updateBudget(
        tripId: tripId,
        accommodationBudget: accommodationBudget,
        transportBudget: transportBudget,
        foodBudget: foodBudget,
        activitiesBudget: activitiesBudget,
        shoppingBudget: shoppingBudget,
        otherBudget: otherBudget,
        currency: currency,
      );
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
}
