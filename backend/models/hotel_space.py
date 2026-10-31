import json
from extensions import db
from currency import amount_in_inr

class HotelSpace(db.Model):
    __tablename__ = 'hotel_spaces'

    space_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    hotel_id = db.Column(db.Integer, db.ForeignKey('hotels.hotel_id', ondelete='CASCADE'), nullable=False)
    space_name = db.Column(db.String(150), nullable=False)
    category = db.Column(db.String(60), nullable=False)  # banquet_hall, conference_hall, restaurant, pool, spa, gym, lounge, garden, reception
    description = db.Column(db.Text)
    capacity = db.Column(db.Integer, default=50)
    size = db.Column(db.String(50), default='120 sq.m')
    price = db.Column(db.Numeric(10, 2), default=0.00)
    currency = db.Column(db.String(10), default='INR')
    opening_hours = db.Column(db.String(100), default='06:00 - 23:00')
    amenities = db.Column(db.Text)
    image_url = db.Column(db.Text)
    model_url = db.Column(db.Text)
    availability_status = db.Column(db.String(30), default='available')

    hotel = db.relationship('Hotel', back_populates='spaces')

    def to_dict(self):
        amenities_list = []
        if self.amenities:
            try:
                amenities_list = json.loads(self.amenities)
            except Exception:
                amenities_list = [a.strip() for a in self.amenities.split(',') if a.strip()]

        return {
            'space_id': self.space_id,
            'hotel_id': self.hotel_id,
            'space_name': self.space_name,
            'category': self.category,
            'description': self.description,
            'capacity': self.capacity,
            'size': self.size,
            'price': float(amount_in_inr(self.price, self.currency)),
            'currency': 'INR',
            'opening_hours': self.opening_hours,
            'amenities': amenities_list,
            'image_url': self.image_url,
            'model_url': self.model_url,
            'has_3d_model': bool(self.model_url and self.model_url.strip()),
            'availability_status': self.availability_status
        }
