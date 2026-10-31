from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime
from models.trip import Trip, TripActivity, TripDestination
from services.budget_service import BudgetService
from extensions import db

trips_bp = Blueprint('trips', __name__, url_prefix='/api/trips')

@trips_bp.route('', methods=['POST'])
@jwt_required()
def create_trip():
    user_id = int(get_jwt_identity())
    data = request.get_json() or {}

    trip_name = data.get('trip_name', '').strip()
    destination = data.get('destination', '').strip()
    start_date_str = data.get('start_date')
    end_date_str = data.get('end_date')
    traveller_count = data.get('traveller_count', 1)

    if not trip_name or not destination or not start_date_str or not end_date_str:
        return jsonify({'error': 'trip_name, destination, start_date, and end_date are required'}), 400

    try:
        start_date = datetime.strptime(start_date_str, '%Y-%m-%d').date()
        end_date = datetime.strptime(end_date_str, '%Y-%m-%d').date()
    except ValueError:
        return jsonify({'error': 'Dates must be in YYYY-MM-DD format'}), 400

    if end_date < start_date:
        return jsonify({'error': 'end_date cannot be earlier than start_date'}), 400

    trip = Trip(
        user_id=user_id,
        trip_name=trip_name,
        destination=destination,
        start_date=start_date,
        end_date=end_date,
        traveller_count=traveller_count,
        status='planned'
    )
    db.session.add(trip)
    db.session.commit()

    # Automatically initialize a budget for the trip
    BudgetService.get_or_create_budget(trip.trip_id)

    return jsonify({
        'message': 'Trip created successfully',
        'trip': trip.to_dict()
    }), 201

@trips_bp.route('', methods=['GET'])
@jwt_required()
def get_trips():
    user_id = int(get_jwt_identity())
    trips = Trip.query.filter_by(user_id=user_id).order_by(Trip.start_date.desc()).all()
    return jsonify([t.to_dict(include_details=True) for t in trips]), 200

@trips_bp.route('/<int:trip_id>', methods=['GET'])
@jwt_required()
def get_trip(trip_id):
    user_id = int(get_jwt_identity())
    trip = Trip.query.filter_by(trip_id=trip_id, user_id=user_id).first()
    if not trip:
        return jsonify({'error': 'Trip not found'}), 404
    return jsonify(trip.to_dict(include_details=True)), 200

@trips_bp.route('/<int:trip_id>', methods=['PUT'])
@jwt_required()
def update_trip(trip_id):
    user_id = int(get_jwt_identity())
    trip = Trip.query.filter_by(trip_id=trip_id, user_id=user_id).first()
    if not trip:
        return jsonify({'error': 'Trip not found'}), 404

    data = request.get_json() or {}
    if 'trip_name' in data and data['trip_name'].strip():
        trip.trip_name = data['trip_name'].strip()
    if 'destination' in data and data['destination'].strip():
        trip.destination = data['destination'].strip()
    if 'start_date' in data:
        trip.start_date = datetime.strptime(data['start_date'], '%Y-%m-%d').date()
    if 'end_date' in data:
        trip.end_date = datetime.strptime(data['end_date'], '%Y-%m-%d').date()
    if 'traveller_count' in data:
        trip.traveller_count = int(data['traveller_count'])
    if 'status' in data:
        trip.status = data['status']

    db.session.commit()
    return jsonify({'message': 'Trip updated successfully', 'trip': trip.to_dict()}), 200

@trips_bp.route('/<int:trip_id>', methods=['DELETE'])
@jwt_required()
def delete_trip(trip_id):
    user_id = int(get_jwt_identity())
    trip = Trip.query.filter_by(trip_id=trip_id, user_id=user_id).first()
    if not trip:
        return jsonify({'error': 'Trip not found'}), 404

    db.session.delete(trip)
    db.session.commit()
    return jsonify({'message': 'Trip deleted successfully'}), 200

# Trip Activities
@trips_bp.route('/<int:trip_id>/activities', methods=['POST'])
@jwt_required()
def add_activity(trip_id):
    user_id = int(get_jwt_identity())
    trip = Trip.query.filter_by(trip_id=trip_id, user_id=user_id).first()
    if not trip:
        return jsonify({'error': 'Trip not found'}), 404

    data = request.get_json() or {}
    activity_name = data.get('activity_name', '').strip()
    activity_date_str = data.get('activity_date')

    if not activity_name or not activity_date_str:
        return jsonify({'error': 'activity_name and activity_date are required'}), 400

    try:
        activity_date = datetime.strptime(activity_date_str, '%Y-%m-%d').date()
    except ValueError:
        return jsonify({'error': 'activity_date must be in YYYY-MM-DD format'}), 400

    activity = TripActivity(
        trip_id=trip_id,
        activity_name=activity_name,
        activity_date=activity_date,
        start_time=data.get('start_time', '09:00'),
        end_time=data.get('end_time', '12:00'),
        location=data.get('location', ''),
        latitude=data.get('latitude'),
        longitude=data.get('longitude'),
        notes=data.get('notes', '')
    )
    db.session.add(activity)
    db.session.commit()

    return jsonify({'message': 'Activity added successfully', 'activity': activity.to_dict()}), 201

@trips_bp.route('/activities/<int:activity_id>', methods=['DELETE'])
@jwt_required()
def delete_activity(activity_id):
    activity = TripActivity.query.get(activity_id)
    if not activity:
        return jsonify({'error': 'Activity not found'}), 404

    user_id = int(get_jwt_identity())
    if activity.trip.user_id != user_id:
        return jsonify({'error': 'Unauthorized'}), 403

    db.session.delete(activity)
    db.session.commit()
    return jsonify({'message': 'Activity deleted successfully'}), 200
