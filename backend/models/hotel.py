from datetime import datetime
from extensions import db
from currency import amount_in_inr

class Hotel(db.Model):
    __tablename__ = 'hotels'

    hotel_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    destination_id = db.Column(db.Integer, db.ForeignKey('destinations.destination_id', ondelete='SET NULL'))
    hotel_name = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text)
    address = db.Column(db.String(300), nullable=False)
    city = db.Column(db.String(100), nullable=False, index=True)
    country = db.Column(db.String(100), nullable=False)
    latitude = db.Column(db.Numeric(10, 7), nullable=False)
    longitude = db.Column(db.Numeric(10, 7), nullable=False)
    star_rating = db.Column(db.Numeric(2, 1), default=4.5)
    review_rating = db.Column(db.Numeric(2, 1), default=4.5)
    review_count = db.Column(db.Integer, default=0)
    starting_price = db.Column(db.Numeric(10, 2), nullable=False)
    currency = db.Column(db.String(10), default='INR')
    exterior_image_url = db.Column(db.Text)
    exterior_model_url = db.Column(db.Text)
    place_id = db.Column(db.String(100))
    data_source = db.Column(db.String(50), default='database')
    is_demo = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    destination = db.relationship('Destination', back_populates='hotels')
    images = db.relationship('HotelImage', back_populates='hotel', cascade='all, delete-orphan')
    facilities = db.relationship('HotelFacility', back_populates='hotel', cascade='all, delete-orphan')
    rooms = db.relationship('Room', back_populates='hotel', cascade='all, delete-orphan')
    spaces = db.relationship('HotelSpace', back_populates='hotel', cascade='all, delete-orphan')
    bookings = db.relationship('Booking', back_populates='hotel', cascade='all, delete-orphan')

    def to_dict(self, include_details=False):
        data = {
            'hotel_id': self.hotel_id,
            'destination_id': self.destination_id,
            'hotel_name': self.hotel_name,
            'description': self.description,
            'address': self.address,
            'city': self.city,
            'country': self.country,
            'latitude': float(self.latitude) if self.latitude is not None else None,
            'longitude': float(self.longitude) if self.longitude is not None else None,
            'star_rating': float(self.star_rating) if self.star_rating is not None else 4.5,
            'review_rating': float(self.review_rating) if self.review_rating is not None else 4.5,
            'review_count': self.review_count,
            'starting_price': float(amount_in_inr(self.starting_price, self.currency)),
            'currency': 'INR',
            'exterior_image_url': self.exterior_image_url,
            'exterior_model_url': self.exterior_model_url,
            'place_id': self.place_id,
            'data_source': self.data_source,
            'is_demo': self.is_demo,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }

        if include_details:
            data['facilities'] = [f.to_dict() for f in self.facilities]
            data['images'] = [img.to_dict() for img in self.images]
            data['rooms'] = [r.to_dict() for r in self.rooms]
            data['spaces'] = [s.to_dict() for s in self.spaces]
        else:
            data['facilities'] = [f.facility_name for f in self.facilities]

        return data
