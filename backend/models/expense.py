from datetime import datetime
from extensions import db
from currency import amount_in_inr

class Expense(db.Model):
    __tablename__ = 'expenses'

    expense_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    trip_id = db.Column(db.Integer, db.ForeignKey('trips.trip_id', ondelete='CASCADE'), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('users.user_id', ondelete='CASCADE'), nullable=False)
    category = db.Column(db.String(50), nullable=False)  # Accommodation, Food, Transportation, Shopping, Entertainment, Activities, Other
    amount = db.Column(db.Numeric(10, 2), nullable=False)
    currency = db.Column(db.String(10), default='INR')
    expense_date = db.Column(db.Date, nullable=False)
    description = db.Column(db.String(255))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    trip = db.relationship('Trip', back_populates='expenses')
    user = db.relationship('User', back_populates='expenses')

    def to_dict(self):
        return {
            'expense_id': self.expense_id,
            'trip_id': self.trip_id,
            'user_id': self.user_id,
            'category': self.category,
            'amount': float(amount_in_inr(self.amount, self.currency)),
            'currency': 'INR',
            'expense_date': self.expense_date.isoformat() if self.expense_date else None,
            'description': self.description,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }
