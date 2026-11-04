import googlemaps
from datetime import datetime
from typing import List, Dict, Any, Optional

class MapsService:
    def __init__(self, api_key: str):
        try:
            self.client = googlemaps.Client(key=api_key)
        except ValueError:
            print(f"⚠️ Invalid API Key: {api_key}. MapsService will not function correctly.")
            self.client = None

    def get_route_data(
        self, 
        origin: Dict[str, float], 
        destination: Dict[str, float], 
        mode: str = "driving",
        departure_time: Optional[datetime] = None
    ) -> Dict[str, Any]:
        """
        Fetch route between two points using Google Directions API.
        Returns duration, distance, and polyline.
        """
        if not self.client:
            print("❌ MapsClient not initialized (Invalid Key).")
            return None

        try:
            # Convert lat/lng dict to tuple for the client
            org_tuple = (origin['lat'], origin['lng'])
            dest_tuple = (destination['lat'], destination['lng'])

            directions_result = self.client.directions(
                origin=org_tuple,
                destination=dest_tuple,
                mode=mode.lower(),
                departure_time=departure_time or datetime.now()
            )

            if not directions_result:
                print(f"⚠️ No route found between {org_tuple} and {dest_tuple}")
                return None

            route = directions_result[0]
            leg = route['legs'][0]
            
            return {
                "duration_seconds": leg['duration']['value'],
                "distance_meters": leg['distance']['value'],
                "polyline": route['overview_polyline']['points'],
                "transport_mode": mode.upper()
            }
        except Exception as e:
            print(f"❌ Google Maps API Error: {e}")
            return None

    def get_distance_matrix(
        self, 
        origins: List[Dict[str, float]], 
        destinations: List[Dict[str, float]], 
        mode: str = "driving"
    ):
        """
        Fetch distance matrix for TSP optimization.
        """
        if not self.client:
            return None

        org_tuples = [(o['lat'], o['lng']) for o in origins]
        dest_tuples = [(d['lat'], d['lng']) for d in destinations]
        
        return self.client.distance_matrix(
            origins=org_tuples,
            destinations=dest_tuples,
            mode=mode.lower()
        )
