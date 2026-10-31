from datetime import datetime
from extensions import db

class TripDestination(db.Model):
    __tablename__ = 'trip_destinations'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    trip_id = db.Column(db.Integer, db.ForeignKey('trips.trip_id', ondelete='CASCADE'), nullable=False)
    destination_id = db.Column(db.Integer, db.ForeignKey('destinations.destination_id', ondelete='CASCADE'), nullable=False)
    visit_order = db.Column(db.Integer, default=1)

    trip = db.relationship('Trip', back_populates='trip_destinations')
    destination = db.relationship('Destination', back_populates='trip_destinations')

    def to_dict(self):
        return {
            'id': self.id,
            'trip_id': self.trip_id,
            'destination_id': self.destination_id,
            'visit_order': self.visit_order,
            'destination': self.destination.to_dict() if self.destination else None
        }

class TripActivity(db.Model):
    __tablename__ = 'trip_activities'

    activity_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    trip_id = db.Column(db.Integer, db.ForeignKey('trips.trip_id', ondelete='CASCADE'), nullable=False)
    destination_id = db.Column(db.Integer, db.ForeignKey('destinations.destination_id', ondelete='SET NULL'))
    activity_name = db.Column(db.String(150), nullable=False)
    activity_date = db.Column(db.Date, nullable=False)
    start_time = db.Column(db.String(20))
    end_time = db.Column(db.String(20))
    location = db.Column(db.String(200))
    latitude = db.Column(db.Numeric(10, 7))
    longitude = db.Column(db.Numeric(10, 7))
    notes = db.Column(db.Text)

    trip = db.relationship('Trip', back_populates='activities')
    destination = db.relationship('Destination', back_populates='trip_activities')

    def to_dict(self):
        return {
            'activity_id': self.activity_id,
            'trip_id': self.trip_id,
            'destination_id': self.destination_id,
            'activity_name': self.activity_name,
            'activity_date': self.activity_date.isoformat() if self.activity_date else None,
            'start_time': self.start_time,
            'end_time': self.end_time,
            'location': self.location,
            'latitude': float(self.latitude) if self.latitude is not None else None,
            'longitude': float(self.longitude) if self.longitude is not None else None,
            'notes': self.notes
        }

class Trip(db.Model):
    __tablename__ = 'trips'

    trip_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.user_id', ondelete='CASCADE'), nullable=False)
    trip_name = db.Column(db.String(150), nullable=False)
    destination = db.Column(db.String(150), nullable=False)
    start_date = db.Column(db.Date, nullable=False)
    end_date = db.Column(db.Date, nullable=False)
    traveller_count = db.Column(db.Integer, default=1)
    total_trip_budget = db.Column(db.Numeric(12, 2), nullable=False, default=0.00)
    currency = db.Column(db.String(10), nullable=False, default='INR')
    status = db.Column(db.String(30), default='planned')  # planned, ongoing, completed, cancelled
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    user = db.relationship('User', back_populates='trips')
    trip_destinations = db.relationship('TripDestination', back_populates='trip', cascade='all, delete-orphan')
    activities = db.relationship('TripActivity', back_populates='trip', cascade='all, delete-orphan', order_by='TripActivity.activity_date, TripActivity.start_time')
    bookings = db.relationship('Booking', back_populates='trip')
    budget = db.relationship('Budget', back_populates='trip', uselist=False, cascade='all, delete-orphan')
    expenses = db.relationship('Expense', back_populates='trip', cascade='all, delete-orphan')

    def to_dict(self, include_details=True):
        data = {
            'trip_id': self.trip_id,
            'user_id': self.user_id,
            'trip_name': self.trip_name,
            'destination': self.destination,
            'start_date': self.start_date.isoformat() if self.start_date else None,
            'end_date': self.end_date.isoformat() if self.end_date else None,
            'traveller_count': self.traveller_count,
            'total_trip_budget': float(self.total_trip_budget or 0),
            'currency': self.currency or 'INR',
            'status': self.status,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }

        if include_details:
            data['activities'] = [a.to_dict() for a in self.activities]
            data['destinations'] = [td.to_dict() for td in self.trip_destinations]
            data['bookings'] = [b.to_dict() for b in self.bookings]
            data['budget'] = self.budget.to_dict() if self.budget else None
            data['expenses'] = [e.to_dict() for e in self.expenses]

        return data
