from extensions import db

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
    currency = db.Column(db.String(10), default='USD')

    trip = db.relationship('Trip', back_populates='budget')

    def calculate_total(self):
        self.total_budget = (
            (self.accommodation_budget or 0) +
            (self.transport_budget or 0) +
            (self.food_budget or 0) +
            (self.activities_budget or 0) +
            (self.shopping_budget or 0) +
            (self.other_budget or 0)
        )
        return self.total_budget

    def to_dict(self):
        return {
            'budget_id': self.budget_id,
            'trip_id': self.trip_id,
            'accommodation_budget': float(self.accommodation_budget) if self.accommodation_budget is not None else 0.0,
            'transport_budget': float(self.transport_budget) if self.transport_budget is not None else 0.0,
            'food_budget': float(self.food_budget) if self.food_budget is not None else 0.0,
            'activities_budget': float(self.activities_budget) if self.activities_budget is not None else 0.0,
            'shopping_budget': float(self.shopping_budget) if self.shopping_budget is not None else 0.0,
            'other_budget': float(self.other_budget) if self.other_budget is not None else 0.0,
            'total_budget': float(self.total_budget) if self.total_budget is not None else 0.0,
            'currency': self.currency
        }
