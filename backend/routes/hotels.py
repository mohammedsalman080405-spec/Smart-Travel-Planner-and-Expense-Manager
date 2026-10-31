from flask import Blueprint, request, jsonify
from models.hotel import Hotel
from models.hotel_image import HotelImage
from models.hotel_facility import HotelFacility
from models.hotel_space import HotelSpace
from models.room import Room
from services.hotel_search_service import HotelSearchService
from services.geocoding_service import GeocodingService

hotels_bp = Blueprint('hotels', __name__, url_prefix='/api/hotels')

@hotels_bp.route('/search', methods=['GET'])
def search_hotels():
    lat_str = request.args.get('latitude')
    lng_str = request.args.get('longitude')
    dest_str = request.args.get('destination', '').strip()
    radius_km = float(request.args.get('radius_km', 25.0))
    min_price = request.args.get('min_price', type=float)
    max_price = request.args.get('max_price', type=float)
    rating = request.args.get('rating', type=float)
    sort_by = request.args.get('sort_by', 'distance')
    page = request.args.get('page', default=1, type=int)
    per_page = request.args.get('per_page', default=30, type=int)

    # If coordinates are missing but destination is provided, geocode destination
    lat = None
    lng = None
    if lat_str and lng_str:
        try:
            lat = float(lat_str)
            lng = float(lng_str)
        except ValueError:
            pass

    if (lat is None or lng is None) and dest_str:
        geo = GeocodingService.geocode(dest_str)
        if geo:
            lat = geo['latitude']
            lng = geo['longitude']

    if lat is None or lng is None:
        # Default to a global central reference if none given
        lat = 17.385044
        lng = 78.486671

    result = HotelSearchService.search_hotels(
        latitude=lat,
        longitude=lng,
        radius_km=radius_km,
        destination_name=dest_str,
        min_price=min_price,
        max_price=max_price,
        min_rating=rating,
        sort_by=sort_by,
        page=page,
        per_page=per_page
    )

    result['searched_coordinates'] = {'latitude': lat, 'longitude': lng}
    result['radius_km'] = radius_km
    return jsonify(result), 200

@hotels_bp.route('/<int:hotel_id>', methods=['GET'])
def get_hotel(hotel_id):
    hotel = Hotel.query.get(hotel_id)
    if not hotel:
        return jsonify({'error': 'Hotel not found'}), 404
    return jsonify(hotel.to_dict(include_details=True)), 200

@hotels_bp.route('/<int:hotel_id>/images', methods=['GET'])
def get_hotel_images(hotel_id):
    images = HotelImage.query.filter_by(hotel_id=hotel_id).order_by(HotelImage.display_order.asc()).all()
    return jsonify([img.to_dict() for img in images]), 200

@hotels_bp.route('/<int:hotel_id>/facilities', methods=['GET'])
def get_hotel_facilities(hotel_id):
    facilities = HotelFacility.query.filter_by(hotel_id=hotel_id).all()
    return jsonify([f.to_dict() for f in facilities]), 200

@hotels_bp.route('/<int:hotel_id>/spaces', methods=['GET'])
def get_hotel_spaces(hotel_id):
    category = request.args.get('category')
    query = HotelSpace.query.filter_by(hotel_id=hotel_id)
    if category:
        query = query.filter_by(category=category)
    spaces = query.all()
    return jsonify([s.to_dict() for s in spaces]), 200

@hotels_bp.route('/<int:hotel_id>/rooms', methods=['GET'])
def get_hotel_rooms(hotel_id):
    rooms = Room.query.filter_by(hotel_id=hotel_id).order_by(Room.price_per_night.asc()).all()
    return jsonify([r.to_dict() for r in rooms]), 200
