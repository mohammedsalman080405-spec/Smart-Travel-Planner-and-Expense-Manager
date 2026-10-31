import requests
from flask import current_app

class PlacesService:
    @staticmethod
    def search_nearby_hotels(latitude: float, longitude: float, radius_meters: int = 15000):
        """
        Uses Google Places API (New) Nearby Search:
        POST https://places.googleapis.com/v1/places:searchNearby
        """
        api_key = current_app.config.get('GOOGLE_PLACES_API_KEY')
        if not api_key:
            current_app.logger.info(
                "[Google Places API (New)] GOOGLE_PLACES_API_KEY not configured in .env. "
                "Using verified database / demonstration properties fallback mode."
            )
            return []

        try:
            url = "https://places.googleapis.com/v1/places:searchNearby"
            headers = {
                "Content-Type": "application/json",
                "X-Goog-Api-Key": api_key,
                "X-Goog-FieldMask": (
                    "places.id,places.displayName,places.location,"
                    "places.formattedAddress,places.rating,places.userRatingCount,"
                    "places.photos,places.types,places.googleMapsUri"
                )
            }
            payload = {
                "includedPrimaryTypes": ["hotel"],
                "maxResultCount": 20,
                "rankPreference": "DISTANCE",
                "locationRestriction": {
                    "circle": {
                        "center": {
                            "latitude": float(latitude),
                            "longitude": float(longitude)
                        },
                        "radius": float(radius_meters)
                    }
                }
            }

            resp = requests.post(url, json=payload, headers=headers, timeout=6)
            if resp.status_code == 200:
                data = resp.json()
                places = data.get("places", [])
                results = []
                for p in places:
                    loc = p.get("location", {})
                    disp_name = p.get("displayName", {}).get("text", "Luxury Hotel")
                    photos = p.get("photos", [])
                    photo_url = None
                    if photos and len(photos) > 0:
                        photo_ref = photos[0].get("name")
                        if photo_ref:
                            photo_url = f"https://places.googleapis.com/v1/{photo_ref}/media?key={api_key}&maxHeightPx=800"

                    results.append({
                        "place_id": p.get("id"),
                        "hotel_name": disp_name,
                        "address": p.get("formattedAddress", ""),
                        "latitude": loc.get("latitude"),
                        "longitude": loc.get("longitude"),
                        "star_rating": float(p.get("rating", 4.5)),
                        "review_rating": float(p.get("rating", 4.5)),
                        "review_count": int(p.get("userRatingCount", 120)),
                        "exterior_image_url": photo_url or "https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1200&q=80",
                        "google_maps_uri": p.get("googleMapsUri"),
                        "data_source": "google_places_new",
                        "is_demo": False
                    })
                return results
            else:
                current_app.logger.warning(
                    f"[Google Places API (New)] Request failed status={resp.status_code}: {resp.text}"
                )
                return []
        except Exception as e:
            current_app.logger.warning(f"[Google Places API (New)] Exception occurred: {e}")
            return []
