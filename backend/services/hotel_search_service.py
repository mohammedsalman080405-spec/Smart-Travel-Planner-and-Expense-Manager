import math
from models.hotel import Hotel
from services.places_service import PlacesService
from extensions import db
from flask import current_app

def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate the great circle distance between two points 
    on the earth (specified in decimal degrees), returning km.
    """
    lat1_rad, lon1_rad = math.radians(lat1), math.radians(lon1)
    lat2_rad, lon2_rad = math.radians(lat2), math.radians(lon2)

    dlat = lat2_rad - lat1_rad
    dlon = lon2_rad - lon1_rad
    a = math.sin(dlat / 2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    radius_km = 6371.0
    return round(radius_km * c, 2)

class HotelSearchService:
    @staticmethod
    def search_hotels(
        latitude: float,
        longitude: float,
        radius_km: float = 30.0,
        destination_name: str = None,
        min_price: float = None,
        max_price: float = None,
        min_rating: float = None,
        sort_by: str = 'distance',
        page: int = 1,
        per_page: int = 30
    ):
        current_app.logger.info(
            f"[HotelSearch] Searching hotels at lat={latitude}, lng={longitude}, "
            f"radius_km={radius_km}, destination='{destination_name}'"
        )

        results = []

        # 1. Try Google Places (New) Nearby Search if configured
        places_results = PlacesService.search_nearby_hotels(
            latitude=latitude,
            longitude=longitude,
            radius_meters=int(radius_km * 1000)
        )
        if places_results:
            current_app.logger.info(f"[HotelSearch] Google Places API returned {len(places_results)} live hotels")
            for p in places_results:
                dist = haversine_distance(latitude, longitude, p['latitude'], p['longitude'])
                p['distance_km'] = dist
                p['formatted_distance'] = f"{dist:.1f} km from center"
                p['starting_price'] = p.get('starting_price')
                results.append(p)

        # 2. Database query (verified seeded properties / fallback mode)
        query = Hotel.query

        if min_price is not None:
            query = query.filter(Hotel.starting_price >= min_price)
        if max_price is not None:
            query = query.filter(Hotel.starting_price <= max_price)
        if min_rating is not None:
            query = query.filter(Hotel.star_rating >= min_rating)

        db_candidates = query.all()

        for hotel in db_candidates:
            h_lat = float(hotel.latitude)
            h_lng = float(hotel.longitude)
            dist = haversine_distance(latitude, longitude, h_lat, h_lng)

            # Match within search radius OR match destination city within 150 km
            matches_city = False
            if destination_name:
                clean_dest = destination_name.strip().lower()
                clean_city = (hotel.city or '').strip().lower()
                clean_country = (hotel.country or '').strip().lower()
                if clean_dest in clean_city or clean_city in clean_dest or clean_dest in clean_country:
                    matches_city = True

            if dist <= radius_km or (matches_city and dist <= 150.0):
                hotel_dict = hotel.to_dict()
                hotel_dict['distance_km'] = dist
                hotel_dict['formatted_distance'] = f"{dist:.1f} km from center"
                # Check for duplicates if already found
                if not any(r.get('hotel_id') == hotel.hotel_id for r in results):
                    results.append(hotel_dict)

        # Sort results
        if sort_by == 'price_asc':
            results.sort(key=lambda x: x.get('starting_price', 0))
        elif sort_by == 'price_desc':
            results.sort(key=lambda x: x.get('starting_price', 0), reverse=True)
        elif sort_by == 'rating':
            results.sort(key=lambda x: x.get('star_rating', 0), reverse=True)
        else: # default distance
            results.sort(key=lambda x: x.get('distance_km', 9999))

        current_app.logger.info(f"[HotelSearch] Found total {len(results)} hotels matching criteria.")

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
