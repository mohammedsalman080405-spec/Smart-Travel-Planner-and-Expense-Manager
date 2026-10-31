from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.booking import Booking
from services.booking_service import BookingService
from extensions import db

bookings_bp = Blueprint('bookings', __name__, url_prefix='/api/bookings')

@bookings_bp.route('', methods=['POST'])
@jwt_required()
def create_booking():
    user_id = int(get_jwt_identity())
    data = request.get_json() or {}

    hotel_id = data.get('hotel_id')
    room_id = data.get('room_id')
    check_in = data.get('check_in')
    check_out = data.get('check_out')
    guest_count = data.get('guest_count', 1)
    trip_id = data.get('trip_id')

    if not hotel_id or not room_id or not check_in or not check_out:
        return jsonify({'error': 'hotel_id, room_id, check_in, and check_out are required'}), 400

    try:
        booking = BookingService.create_booking(
            user_id=user_id,
            hotel_id=hotel_id,
            room_id=room_id,
            check_in_str=check_in,
            check_out_str=check_out,
            guest_count=guest_count,
            trip_id=trip_id
        )
        return jsonify({
            'message': 'Booking confirmed successfully',
            'booking': booking.to_dict()
        }), 201
    except ValueError as e:
        return jsonify({'error': str(e)}), 400
    except Exception as e:
        return jsonify({'error': f'Failed to process booking: {str(e)}'}), 500

@bookings_bp.route('', methods=['GET'])
@jwt_required()
def list_bookings():
    user_id = int(get_jwt_identity())
    bookings = Booking.query.filter_by(user_id=user_id).order_by(Booking.created_at.desc()).all()
    return jsonify([b.to_dict() for b in bookings]), 200

@bookings_bp.route('/<int:booking_id>', methods=['GET'])
@jwt_required()
def get_booking(booking_id):
    user_id = int(get_jwt_identity())
    booking = Booking.query.filter_by(booking_id=booking_id, user_id=user_id).first()
    if not booking:
        return jsonify({'error': 'Booking not found'}), 404
    return jsonify(booking.to_dict()), 200

@bookings_bp.route('/<int:booking_id>/cancel', methods=['PATCH'])
@jwt_required()
def cancel_booking(booking_id):
    user_id = int(get_jwt_identity())
    booking = Booking.query.filter_by(booking_id=booking_id, user_id=user_id).first()
    if not booking:
        return jsonify({'error': 'Booking not found'}), 404

    if booking.booking_status == 'cancelled':
        return jsonify({'message': 'Booking is already cancelled', 'booking': booking.to_dict()}), 200

    booking.booking_status = 'cancelled'
    db.session.commit()
    return jsonify({'message': 'Booking cancelled successfully', 'booking': booking.to_dict()}), 200
