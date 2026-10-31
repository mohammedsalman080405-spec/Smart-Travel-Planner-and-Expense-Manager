from extensions import db
from currency import amount_in_inr

class Budget(db.Model):
    __tablename__ = 'budgets'

    budget_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    trip_id = db.Column(db.Integer, db.ForeignKey('trips.trip_id', ondelete='CASCADE'), nullable=False, unique=True)
    accommodation_budget = db.Column(db.Numeric(10, 2), default=0.00)
    transport_budget = db.Column(db.Numeric(10, 2), default=0.00)
    food_budget = db.Column(db.Numeric(10, 2), default=0.00)
    activities_budget = db.Column(db.Numeric(10, 2), default=0.00)
    shopping_budget = db.Column(db.Numeric(10, 2), default=0.00)
    other_budget = db.Column(db.Numeric(10, 2), default=0.00)
    total_budget = db.Column(db.Numeric(10, 2), default=0.00)
    currency = db.Column(db.String(10), default='INR')

    trip = db.relationship('Trip', back_populates='budget')

    def calculate_total(self):
        category_total = (
            (self.accommodation_budget or 0) +
            (self.transport_budget or 0) +
            (self.food_budget or 0) +
            (self.activities_budget or 0) +
            (self.shopping_budget or 0) +
            (self.other_budget or 0)
        )
        if category_total > 0:
            self.total_budget = category_total
        return self.total_budget

    def to_dict(self):
        currency = self.currency or 'INR'
        return {
            'budget_id': self.budget_id,
            'trip_id': self.trip_id,
            'accommodation_budget': float(amount_in_inr(self.accommodation_budget, currency)),
            'transport_budget': float(amount_in_inr(self.transport_budget, currency)),
            'food_budget': float(amount_in_inr(self.food_budget, currency)),
            'activities_budget': float(amount_in_inr(self.activities_budget, currency)),
            'shopping_budget': float(amount_in_inr(self.shopping_budget, currency)),
            'other_budget': float(amount_in_inr(self.other_budget, currency)),
            'total_budget': float(amount_in_inr(self.total_budget, currency)),
            'currency': 'INR'
        }
