import json
from datetime import datetime
from extensions import db

class Room(db.Model):
    __tablename__ = 'rooms'

    room_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    hotel_id = db.Column(db.Integer, db.ForeignKey('hotels.hotel_id', ondelete='CASCADE'), nullable=False)
    room_name = db.Column(db.String(150), nullable=False)
    room_type = db.Column(db.String(80), nullable=False)  # Standard, Deluxe, Premium, Executive Suite, Presidential Suite
    description = db.Column(db.Text)
    price_per_night = db.Column(db.Numeric(10, 2), nullable=False)
    currency = db.Column(db.String(10), default='USD')
    bed_type = db.Column(db.String(50), default='King Bed')
    room_size = db.Column(db.String(50), default='45 sq.m')
    maximum_occupancy = db.Column(db.Integer, default=2)
    amenities = db.Column(db.Text)  # JSON or comma-separated
    availability_status = db.Column(db.String(30), default='available')
    image_url = db.Column(db.Text)
    model_url = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    hotel = db.relationship('Hotel', back_populates='rooms')
    images = db.relationship('RoomImage', back_populates='room', cascade='all, delete-orphan')
    bookings = db.relationship('Booking', back_populates='room', cascade='all, delete-orphan')

    def to_dict(self, include_images=True):
        amenities_list = []
        if self.amenities:
            try:
                amenities_list = json.loads(self.amenities)
            except Exception:
                amenities_list = [a.strip() for a in self.amenities.split(',') if a.strip()]

        data = {
            'room_id': self.room_id,
            'hotel_id': self.hotel_id,
            'room_name': self.room_name,
            'room_type': self.room_type,
            'description': self.description,
            'price_per_night': float(self.price_per_night) if self.price_per_night is not None else 0.0,
            'currency': self.currency,
            'bed_type': self.bed_type,
            'room_size': self.room_size,
            'maximum_occupancy': self.maximum_occupancy,
            'amenities': amenities_list,
            'availability_status': self.availability_status,
            'image_url': self.image_url,
            'model_url': self.model_url,
            'has_3d_model': bool(self.model_url and self.model_url.strip()),
            'created_at': self.created_at.isoformat() if self.created_at else None
        }

        if include_images:
            data['images'] = [img.to_dict() for img in self.images]

        return data
