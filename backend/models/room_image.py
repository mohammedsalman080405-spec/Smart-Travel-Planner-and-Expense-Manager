from extensions import db

class RoomImage(db.Model):
    __tablename__ = 'room_images'

    image_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    room_id = db.Column(db.Integer, db.ForeignKey('rooms.room_id', ondelete='CASCADE'), nullable=False)
    image_url = db.Column(db.Text, nullable=False)
    caption = db.Column(db.String(200))
    display_order = db.Column(db.Integer, default=0)

    room = db.relationship('Room', back_populates='images')

    def to_dict(self):
        return {
            'image_id': self.image_id,
            'room_id': self.room_id,
            'image_url': self.image_url,
            'caption': self.caption,
            'display_order': self.display_order
        }
