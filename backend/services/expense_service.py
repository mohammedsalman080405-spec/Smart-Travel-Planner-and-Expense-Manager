from datetime import datetime
from models.expense import Expense
from extensions import db

class ExpenseService:
    @staticmethod
    def get_trip_expenses(trip_id: int):
        expenses = Expense.query.filter_by(trip_id=trip_id).order_by(Expense.expense_date.desc(), Expense.created_at.desc()).all()
        return [e.to_dict() for e in expenses]

    @staticmethod
    def add_expense(user_id: int, trip_id: int, category: str, amount: float, expense_date_str: str, description: str = '', currency: str = 'USD'):
        try:
            exp_date = datetime.strptime(expense_date_str, '%Y-%m-%d').date()
        except ValueError:
            exp_date = datetime.utcnow().date()

        expense = Expense(
            trip_id=trip_id,
            user_id=user_id,
            category=category,
            amount=amount,
            currency=currency,
            expense_date=exp_date,
            description=description
        )
        db.session.add(expense)
        db.session.commit()
        return expense
