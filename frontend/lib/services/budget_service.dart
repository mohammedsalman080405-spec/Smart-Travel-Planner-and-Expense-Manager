import '../config/api_config.dart';
import '../models/budget.dart';
import 'api_service.dart';

class BudgetService {
  static Future<BudgetSummary> getTripFinancialSummary(int tripId) async {
    final response = await ApiService.get(ApiConfig.budget(tripId), needsAuth: true);
    return BudgetSummary.fromJson(response);
  }

  static Future<BudgetSummary> updateBudget({
    required int tripId,
    double? accommodationBudget,
    double? transportBudget,
    double? foodBudget,
    double? activitiesBudget,
    double? shoppingBudget,
    double? otherBudget,
    String? currency,
  }) async {
    final body = <String, dynamic>{};
    if (accommodationBudget != null) body['accommodation_budget'] = accommodationBudget;
    if (transportBudget != null) body['transport_budget'] = transportBudget;
    if (foodBudget != null) body['food_budget'] = foodBudget;
    if (activitiesBudget != null) body['activities_budget'] = activitiesBudget;
    if (shoppingBudget != null) body['shopping_budget'] = shoppingBudget;
    if (otherBudget != null) body['other_budget'] = otherBudget;
    if (currency != null) body['currency'] = currency;

    final response = await ApiService.put(
      ApiConfig.budget(tripId),
      body: body,
      needsAuth: true,
    );
    return BudgetSummary.fromJson(response['summary']);
  }
}
