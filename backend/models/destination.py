from datetime import datetime
from extensions import db

class Destination(db.Model):
    __tablename__ = 'destinations'

    destination_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    name = db.Column(db.String(150), nullable=False)
    city = db.Column(db.String(100), nullable=False, index=True)
    country = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text)
    latitude = db.Column(db.Numeric(10, 7), nullable=False)
    longitude = db.Column(db.Numeric(10, 7), nullable=False)
    image_url = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Relationships
    hotels = db.relationship('Hotel', back_populates='destination')
    trip_destinations = db.relationship('TripDestination', back_populates='destination')
    trip_activities = db.relationship('TripActivity', back_populates='destination')

    def to_dict(self):
        return {
            'destination_id': self.destination_id,
            'name': self.name,
            'city': self.city,
            'country': self.country,
            'description': self.description,
            'latitude': float(self.latitude) if self.latitude is not None else None,
            'longitude': float(self.longitude) if self.longitude is not None else None,
            'image_url': self.image_url,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }
