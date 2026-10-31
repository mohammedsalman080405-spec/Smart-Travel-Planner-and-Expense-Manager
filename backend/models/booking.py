from datetime import datetime
from extensions import db
from currency import amount_in_inr

class Booking(db.Model):
    __tablename__ = 'bookings'

    booking_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.user_id', ondelete='CASCADE'), nullable=False)
    hotel_id = db.Column(db.Integer, db.ForeignKey('hotels.hotel_id', ondelete='CASCADE'), nullable=False)
    room_id = db.Column(db.Integer, db.ForeignKey('rooms.room_id', ondelete='CASCADE'), nullable=False)
    trip_id = db.Column(db.Integer, db.ForeignKey('trips.trip_id', ondelete='SET NULL'))
    check_in = db.Column(db.Date, nullable=False)
    check_out = db.Column(db.Date, nullable=False)
    guest_count = db.Column(db.Integer, default=1)
    number_of_nights = db.Column(db.Integer, nullable=False)
    price_per_night = db.Column(db.Numeric(10, 2), nullable=False)
    total_amount = db.Column(db.Numeric(10, 2), nullable=False)
    currency = db.Column(db.String(10), default='INR')
    booking_status = db.Column(db.String(30), default='confirmed')  # confirmed, cancelled, completed
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Relationships
    user = db.relationship('User', back_populates='bookings')
    hotel = db.relationship('Hotel', back_populates='bookings')
    room = db.relationship('Room', back_populates='bookings')
    trip = db.relationship('Trip', back_populates='bookings')

    def to_dict(self):
        return {
            'booking_id': self.booking_id,
            'user_id': self.user_id,
            'hotel_id': self.hotel_id,
            'room_id': self.room_id,
            'trip_id': self.trip_id,
            'hotel_name': self.hotel.hotel_name if self.hotel else None,
            'hotel_image': self.hotel.exterior_image_url if self.hotel else None,
            'hotel_address': self.hotel.address if self.hotel else None,
            'room_name': self.room.room_name if self.room else None,
            'room_type': self.room.room_type if self.room else None,
            'room_image': self.room.image_url if self.room else None,
            'check_in': self.check_in.isoformat() if self.check_in else None,
            'check_out': self.check_out.isoformat() if self.check_out else None,
            'guest_count': self.guest_count,
            'number_of_nights': self.number_of_nights,
            'price_per_night': float(amount_in_inr(self.price_per_night, self.currency)),
            'total_amount': float(amount_in_inr(self.total_amount, self.currency)),
            'currency': 'INR',
            'booking_status': self.booking_status,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }
