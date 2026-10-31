import math
from models.hotel import Hotel
from extensions import db

def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate the great circle distance between two points 
    on the earth (specified in decimal degrees), returning km.
    """
    # Convert decimal degrees to radians
    lat1_rad, lon1_rad = math.radians(lat1), math.radians(lon1)
    lat2_rad, lon2_rad = math.radians(lat2), math.radians(lon2)

    # Haversine formula
    dlat = lat2_rad - lat1_rad
    dlon = lon2_rad - lon1_rad
    a = math.sin(dlat / 2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    radius_km = 6371.0 # Radius of Earth in kilometers
    return round(radius_km * c, 2)

class HotelSearchService:
    @staticmethod
    def search_hotels(
        latitude: float,
        longitude: float,
        radius_km: float = 20.0,
        destination_name: str = None,
        min_price: float = None,
        max_price: float = None,
        min_rating: float = None,
        sort_by: str = 'distance', # distance, price_asc, price_desc, rating
        page: int = 1,
        per_page: int = 20
    ):
        query = Hotel.query

        # If a destination query or city is provided, filter or boost
        if destination_name:
            query = query.filter(
                (Hotel.city.ilike(f"%{destination_name}%")) | 
                (Hotel.country.ilike(f"%{destination_name}%")) |
                (Hotel.hotel_name.ilike(f"%{destination_name}%"))
            )

        if min_price is not None:
            query = query.filter(Hotel.starting_price >= min_price)
        if max_price is not None:
            query = query.filter(Hotel.starting_price <= max_price)
        if min_rating is not None:
            query = query.filter(Hotel.star_rating >= min_rating)

        all_candidates = query.all()

        results = []
        for hotel in all_candidates:
            h_lat = float(hotel.latitude)
            h_lng = float(hotel.longitude)
            dist = haversine_distance(latitude, longitude, h_lat, h_lng)

            # Check if within radius, or if destination was explicitly matched allow up to 100km
            if dist <= radius_km or (destination_name and dist <= 120.0):
                hotel_dict = hotel.to_dict()
                hotel_dict['distance_km'] = dist
                hotel_dict['formatted_distance'] = f"{dist:.1f} km from center"
                results.append(hotel_dict)

        # Sort results
        if sort_by == 'price_asc':
            results.sort(key=lambda x: x['starting_price'])
        elif sort_by == 'price_desc':
            results.sort(key=lambda x: x['starting_price'], reverse=True)
        elif sort_by == 'rating':
            results.sort(key=lambda x: x['star_rating'], reverse=True)
        else: # default distance
            results.sort(key=lambda x: x['distance_km'])

        total = len(results)
        start_idx = (page - 1) * per_page
        end_idx = start_idx + per_page
        paginated_items = results[start_idx:end_idx]

        return {
            'total': total,
            'page': page,
            'per_page': per_page,
            'hotels': paginated_items
        }
