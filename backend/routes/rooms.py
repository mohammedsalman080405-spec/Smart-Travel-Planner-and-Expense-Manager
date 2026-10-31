from flask import Blueprint, jsonify
from models.room import Room

rooms_bp = Blueprint('rooms', __name__, url_prefix='/api/rooms')

@rooms_bp.route('/<int:room_id>', methods=['GET'])
def get_room(room_id):
    room = Room.query.get(room_id)
    if not room:
        return jsonify({'error': 'Room not found'}), 404
    return jsonify(room.to_dict(include_images=True)), 200
