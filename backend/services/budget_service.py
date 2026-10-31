from models.budget import Budget
from models.expense import Expense
from extensions import db
from sqlalchemy import func

class BudgetService:
    @staticmethod
    def get_or_create_budget(trip_id: int):
        budget = Budget.query.filter_by(trip_id=trip_id).first()
        if not budget:
            budget = Budget(
                trip_id=trip_id,
                accommodation_budget=0.0,
                transport_budget=0.0,
                food_budget=0.0,
                activities_budget=0.0,
                shopping_budget=0.0,
                other_budget=0.0,
                total_budget=0.0,
                currency='USD'
            )
            db.session.add(budget)
            db.session.commit()
        return budget

    @staticmethod
    def get_trip_financial_summary(trip_id: int):
        budget = BudgetService.get_or_create_budget(trip_id)
        expenses = Expense.query.filter_by(trip_id=trip_id).all()

        total_spent = sum(float(e.amount) for e in expenses)
        total_budget = float(budget.total_budget) if budget.total_budget else 0.0

        # Category-wise spent
        category_spending = {
            'Accommodation': 0.0,
            'Transportation': 0.0,
            'Food': 0.0,
            'Activities': 0.0,
            'Shopping': 0.0,
            'Other': 0.0
        }

        for e in expenses:
            cat = e.category
            if cat in category_spending:
                category_spending[cat] += float(e.amount)
            else:
                category_spending['Other'] += float(e.amount)

        category_budgets = {
            'Accommodation': float(budget.accommodation_budget or 0),
            'Transportation': float(budget.transport_budget or 0),
            'Food': float(budget.food_budget or 0),
            'Activities': float(budget.activities_budget or 0),
            'Shopping': float(budget.shopping_budget or 0),
            'Other': float(budget.other_budget or 0)
        }

        remaining_balance = round(total_budget - total_spent, 2)
        percentage_used = round((total_spent / total_budget * 100), 1) if total_budget > 0 else 0.0

        return {
            'trip_id': trip_id,
            'total_budget': round(total_budget, 2),
            'total_spent': round(total_spent, 2),
            'remaining_balance': remaining_balance,
            'percentage_used': percentage_used,
            'currency': budget.currency,
            'category_budgets': category_budgets,
            'category_spending': {k: round(v, 2) for k, v in category_spending.items()},
            'budget': budget.to_dict()
        }
