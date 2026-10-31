from extensions import db

class HotelFacility(db.Model):
    __tablename__ = 'hotel_facilities'

    facility_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    hotel_id = db.Column(db.Integer, db.ForeignKey('hotels.hotel_id', ondelete='CASCADE'), nullable=False)
    facility_name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.String(255))

    hotel = db.relationship('Hotel', back_populates='facilities')

    def to_dict(self):
        return {
            'facility_id': self.facility_id,
            'hotel_id': self.hotel_id,
            'facility_name': self.facility_name,
            'description': self.description
        }
