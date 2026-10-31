from flask import Blueprint, request, jsonify
from models.destination import Destination
from services.geocoding_service import GeocodingService
from extensions import db

destinations_bp = Blueprint('destinations', __name__, url_prefix='/api/destinations')

@destinations_bp.route('', methods=['GET'])
def get_destinations():
    destinations = Destination.query.order_by(Destination.name.asc()).all()
    return jsonify([d.to_dict() for d in destinations]), 200

@destinations_bp.route('/search', methods=['GET'])
def search_destinations():
    q = (request.args.get('q') or request.args.get('query') or '').strip()
    if not q:
        destinations = Destination.query.limit(10).all()
        return jsonify([d.to_dict() for d in destinations]), 200

    destinations = Destination.query.filter(
        (Destination.name.ilike(f"%{q}%")) |
        (Destination.city.ilike(f"%{q}%")) |
        (Destination.country.ilike(f"%{q}%"))
    ).all()

    return jsonify([d.to_dict() for d in destinations]), 200

@destinations_bp.route('/geocode', methods=['GET'])
def geocode_destination():
    q = (request.args.get('q') or request.args.get('query') or '').strip()
    if not q:
        return jsonify({'error': 'Query string "q" or "query" is required'}), 400

    # 1. First check if exists in DB destinations
    match = Destination.query.filter(
        (Destination.name.ilike(f"%{q}%")) |
        (Destination.city.ilike(f"%{q}%"))
    ).first()

    if match:
        return jsonify({
            'name': match.name,
            'city': match.city,
            'country': match.country,
            'latitude': float(match.latitude),
            'longitude': float(match.longitude),
            'destination_id': match.destination_id
        }), 200

    # 2. Geocode using service
    geo = GeocodingService.geocode(q)
    if geo:
        return jsonify(geo), 200

    return jsonify({'error': f'Could not resolve coordinates for "{q}"'}), 404

@destinations_bp.route('/<int:destination_id>', methods=['GET'])
def get_destination(destination_id):
    destination = Destination.query.get(destination_id)
    if not destination:
        return jsonify({'error': 'Destination not found'}), 404
    return jsonify(destination.to_dict()), 200
