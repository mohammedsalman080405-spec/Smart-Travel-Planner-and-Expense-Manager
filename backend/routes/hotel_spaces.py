from flask import Blueprint, jsonify
from models.hotel_space import HotelSpace

hotel_spaces_bp = Blueprint('hotel_spaces', __name__, url_prefix='/api/hotel-spaces')

@hotel_spaces_bp.route('/<int:space_id>', methods=['GET'])
def get_hotel_space(space_id):
    space = HotelSpace.query.get(space_id)
    if not space:
        return jsonify({'error': 'Hotel space not found'}), 404
    return jsonify(space.to_dict()), 200
