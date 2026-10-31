import requests
from flask import current_app

# Comprehensive built-in geocoding lookup for instant, reliable resolution
POPULAR_DESTINATIONS = {
    'hyderabad': {'name': 'Hyderabad', 'city': 'Hyderabad', 'country': 'India', 'latitude': 17.385044, 'longitude': 78.486671},
    'mumbai': {'name': 'Mumbai', 'city': 'Mumbai', 'country': 'India', 'latitude': 19.076090, 'longitude': 72.877426},
    'delhi': {'name': 'Delhi', 'city': 'Delhi', 'country': 'India', 'latitude': 28.613939, 'longitude': 77.209021},
    'new delhi': {'name': 'New Delhi', 'city': 'New Delhi', 'country': 'India', 'latitude': 28.613939, 'longitude': 77.209021},
    'dubai': {'name': 'Dubai', 'city': 'Dubai', 'country': 'United Arab Emirates', 'latitude': 25.204849, 'longitude': 55.270783},
    'bali': {'name': 'Bali', 'city': 'Denpasar', 'country': 'Indonesia', 'latitude': -8.409518, 'longitude': 115.188916},
    'paris': {'name': 'Paris', 'city': 'Paris', 'country': 'France', 'latitude': 48.856614, 'longitude': 2.352222},
    'singapore': {'name': 'Singapore', 'city': 'Singapore', 'country': 'Singapore', 'latitude': 1.352083, 'longitude': 103.819836},
    'tokyo': {'name': 'Tokyo', 'city': 'Tokyo', 'country': 'Japan', 'latitude': 35.676192, 'longitude': 139.650311},
    'london': {'name': 'London', 'city': 'London', 'country': 'United Kingdom', 'latitude': 51.507351, 'longitude': -0.127758},
    'new york': {'name': 'New York', 'city': 'New York', 'country': 'United States', 'latitude': 40.712776, 'longitude': -74.005974},
    'bangkok': {'name': 'Bangkok', 'city': 'Bangkok', 'country': 'Thailand', 'latitude': 13.756331, 'longitude': 100.501765},
    'rome': {'name': 'Rome', 'city': 'Rome', 'country': 'Italy', 'latitude': 41.902782, 'longitude': 12.496366},
    'sydney': {'name': 'Sydney', 'city': 'Sydney', 'country': 'Australia', 'latitude': -33.868820, 'longitude': 151.209296},
    'cairo': {'name': 'Cairo', 'city': 'Cairo', 'country': 'Egypt', 'latitude': 30.044420, 'longitude': 31.235712},
    'cape town': {'name': 'Cape Town', 'city': 'Cape Town', 'country': 'South Africa', 'latitude': -33.924870, 'longitude': 18.424055},
    'rio de janeiro': {'name': 'Rio de Janeiro', 'city': 'Rio de Janeiro', 'country': 'Brazil', 'latitude': -22.906847, 'longitude': -43.172896},
    'barcelona': {'name': 'Barcelona', 'city': 'Barcelona', 'country': 'Spain', 'latitude': 41.387917, 'longitude': 2.169919},
    'amsterdam': {'name': 'Amsterdam', 'city': 'Amsterdam', 'country': 'Netherlands', 'latitude': 52.367573, 'longitude': 4.904139},
    'santorini': {'name': 'Santorini', 'city': 'Fira', 'country': 'Greece', 'latitude': 36.393156, 'longitude': 25.461509}
}

class GeocodingService:
    @staticmethod
    def geocode(query: str):
        if not query or not query.strip():
            return None

        clean_query = query.strip().lower()

        # Check local instant lookup
        for key, dest in POPULAR_DESTINATIONS.items():
            if key in clean_query or clean_query in key:
                return dest

        # If Google Maps API key is configured, use Google Geocoding API
        api_key = current_app.config.get('GOOGLE_MAPS_API_KEY')
        if api_key:
            try:
                resp = requests.get(
                    "https://maps.googleapis.com/maps/api/geocode/json",
                    params={"address": query, "key": api_key},
                    timeout=5
                )
                if resp.status_code == 200:
                    data = resp.json()
                    if data.get('status') == 'OK' and data.get('results'):
                        result = data['results'][0]
                        loc = result['geometry']['location']
                        return {
                            'name': result.get('formatted_address', query),
                            'city': query.title(),
                            'country': '',
                            'latitude': loc['lat'],
                            'longitude': loc['lng']
                        }
            except Exception as e:
                current_app.logger.warning(f"Google geocoding error: {e}")

        # Nominatim OpenStreetMap fallback for unknown coordinates
        try:
            resp = requests.get(
                "https://nominatim.openstreetmap.org/search",
                params={"q": query, "format": "json", "limit": 1},
                headers={"User-Agent": "SmartTravelPlanner/1.0"},
                timeout=4
            )
            if resp.status_code == 200:
                results = resp.json()
                if results and len(results) > 0:
                    r = results[0]
                    return {
                        'name': r.get('display_name', query),
                        'city': query.title(),
                        'country': '',
                        'latitude': float(r['lat']),
                        'longitude': float(r['lon'])
                    }
        except Exception:
            pass

        return None
