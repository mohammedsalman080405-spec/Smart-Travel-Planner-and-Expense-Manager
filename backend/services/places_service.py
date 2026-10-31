import requests
from flask import current_app

class PlacesService:
    @staticmethod
    def search_nearby_hotels(latitude: float, longitude: float, radius_meters: int = 10000):
        api_key = current_app.config.get('GOOGLE_PLACES_API_KEY')
        if not api_key:
            return []

        try:
            url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
            params = {
                "location": f"{latitude},{longitude}",
                "radius": radius_meters,
                "type": "lodging",
                "key": api_key
            }
            resp = requests.get(url, params=params, timeout=6)
            if resp.status_code == 200:
                data = resp.json()
                results = []
                for p in data.get('results', []):
                    results.append({
                        'place_id': p.get('place_id'),
                        'hotel_name': p.get('name'),
                        'address': p.get('vicinity', ''),
                        'latitude': p.get('geometry', {}).get('location', {}).get('lat'),
                        'longitude': p.get('geometry', {}).get('location', {}).get('lng'),
                        'star_rating': p.get('rating', 4.0),
                        'review_rating': p.get('rating', 4.0),
                        'review_count': p.get('user_ratings_total', 0),
                        'data_source': 'google_places',
                        'is_demo': False
                    })
                return results
        except Exception as e:
            current_app.logger.warning(f"Google Places API error: {e}")
            return []

        return []
