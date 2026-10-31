class Budget {
  final int budgetId;
  final int tripId;
  final double accommodationBudget;
  final double transportBudget;
  final double foodBudget;
  final double activitiesBudget;
  final double shoppingBudget;
  final double otherBudget;
  final double totalBudget;
  final String currency;

  Budget({
    required this.budgetId,
    required this.tripId,
    this.accommodationBudget = 0.0,
    this.transportBudget = 0.0,
    this.foodBudget = 0.0,
    this.activitiesBudget = 0.0,
    this.shoppingBudget = 0.0,
    this.otherBudget = 0.0,
    this.totalBudget = 0.0,
    this.currency = 'USD',
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      budgetId: json['budget_id'] ?? 0,
      tripId: json['trip_id'] ?? 0,
      accommodationBudget: (json['accommodation_budget'] as num?)?.toDouble() ?? 0.0,
      transportBudget: (json['transport_budget'] as num?)?.toDouble() ?? 0.0,
      foodBudget: (json['food_budget'] as num?)?.toDouble() ?? 0.0,
      activitiesBudget: (json['activities_budget'] as num?)?.toDouble() ?? 0.0,
      shoppingBudget: (json['shopping_budget'] as num?)?.toDouble() ?? 0.0,
      otherBudget: (json['other_budget'] as num?)?.toDouble() ?? 0.0,
      totalBudget: (json['total_budget'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'USD',
    );
  }
}

class BudgetSummary {
  final int tripId;
  final double totalBudget;
  final double totalSpent;
  final double remainingBalance;
  final double percentageUsed;
  final String currency;
  final Map<String, double> categoryBudgets;
  final Map<String, double> categorySpending;
  final Budget budget;

  BudgetSummary({
    required this.tripId,
    required this.totalBudget,
    required this.totalSpent,
    required this.remainingBalance,
    required this.percentageUsed,
    required this.currency,
    required this.categoryBudgets,
    required this.categorySpending,
    required this.budget,
  });

  factory BudgetSummary.fromJson(Map<String, dynamic> json) {
    Map<String, double> catB = {};
    if (json['category_budgets'] is Map) {
      json['category_budgets'].forEach((k, v) {
        catB[k.toString()] = (v as num).toDouble();
      });
    }

    Map<String, double> catS = {};
    if (json['category_spending'] is Map) {
      json['category_spending'].forEach((k, v) {
        catS[k.toString()] = (v as num).toDouble();
      });
    }

    return BudgetSummary(
      tripId: json['trip_id'] ?? 0,
      totalBudget: (json['total_budget'] as num?)?.toDouble() ?? 0.0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
      remainingBalance: (json['remaining_balance'] as num?)?.toDouble() ?? 0.0,
      percentageUsed: (json['percentage_used'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'USD',
      categoryBudgets: catB,
      categorySpending: catS,
      budget: Budget.fromJson(json['budget'] ?? {}),
    );
  }
}
