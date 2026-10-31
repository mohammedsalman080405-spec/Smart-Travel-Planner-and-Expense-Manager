from extensions import db

class HotelImage(db.Model):
    __tablename__ = 'hotel_images'

    image_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    hotel_id = db.Column(db.Integer, db.ForeignKey('hotels.hotel_id', ondelete='CASCADE'), nullable=False)
    image_url = db.Column(db.Text, nullable=False)
    image_category = db.Column(db.String(50), default='exterior')  # exterior, interior, lobby, dining, amenity
    caption = db.Column(db.String(200))
    display_order = db.Column(db.Integer, default=0)

    hotel = db.relationship('Hotel', back_populates='images')

    def to_dict(self):
        return {
            'image_id': self.image_id,
            'hotel_id': self.hotel_id,
            'image_url': self.image_url,
            'image_category': self.image_category,
            'caption': self.caption,
            'display_order': self.display_order
        }
