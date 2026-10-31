from models.budget import Budget
from models.expense import Expense
from models.trip import Trip
from extensions import db
from sqlalchemy import func
from currency import amount_in_inr

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
                currency='INR'
            )
            db.session.add(budget)
            db.session.commit()
        return budget

    @staticmethod
    def get_trip_financial_summary(trip_id: int):
        budget = BudgetService.get_or_create_budget(trip_id)
        expenses = Expense.query.filter_by(trip_id=trip_id).all()

        total_spent = sum(float(amount_in_inr(e.amount, e.currency)) for e in expenses)
        trip = Trip.query.get(trip_id)
        configured_budget = (
            trip.total_trip_budget
            if trip and trip.total_trip_budget and float(trip.total_trip_budget) > 0
            else budget.total_budget
        )
        total_budget = float(amount_in_inr(configured_budget, budget.currency))

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
                category_spending[cat] += float(amount_in_inr(e.amount, e.currency))
            else:
                category_spending['Other'] += float(amount_in_inr(e.amount, e.currency))

        category_budgets = {
            'Accommodation': float(amount_in_inr(budget.accommodation_budget, budget.currency)),
            'Transportation': float(amount_in_inr(budget.transport_budget, budget.currency)),
            'Food': float(amount_in_inr(budget.food_budget, budget.currency)),
            'Activities': float(amount_in_inr(budget.activities_budget, budget.currency)),
            'Shopping': float(amount_in_inr(budget.shopping_budget, budget.currency)),
            'Other': float(amount_in_inr(budget.other_budget, budget.currency))
        }

        remaining_balance = round(total_budget - total_spent, 2)
        percentage_used = round((total_spent / total_budget * 100), 1) if total_budget > 0 else 0.0

        return {
            'trip_id': trip_id,
            'total_budget': round(total_budget, 2),
            'total_spent': round(total_spent, 2),
            'remaining_balance': remaining_balance,
            'percentage_used': percentage_used,
            'currency': 'INR',
            'category_budgets': category_budgets,
            'category_spending': {k: round(v, 2) for k, v in category_spending.items()},
            'budget': budget.to_dict()
        }
