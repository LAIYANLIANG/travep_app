import googlemaps
from typing import List, Tuple
from .models import Waypoint, Segment, ItineraryResponse

class ItineraryEngine:
    """
    Core Logic Engine for the Smart Itinerary.
    Responsible for:
    1.  Segmentation: Breaking down a full itinerary into individual A->B legs.
    2.  Route Calculation: Calling Google Directions API (or mock) for each leg.
    3.  Aggregation: summing up total time and distance.
    4.  Backtracking Detection: Identifying if the user is returning to a previous location.
    """
    def __init__(self, google_maps_key: str):
        self.gmaps = googlemaps.Client(key=google_maps_key) if google_maps_key != "dummy" else None

    def calculate_route(self, waypoints: List[Waypoint]) -> ItineraryResponse:
        """
        Calculates the full itinerary by segmenting it into legs.
        
        Args:
            waypoints: List of Waypoint objects defined by the user.
            
        Returns:
            ItineraryResponse containing segments, totals, polyline, and warnings.
        """
        if len(waypoints) < 2:
            return ItineraryResponse(
                segments=[], 
                total_duration_seconds=0, 
                total_distance_meters=0, 
                combined_polyline=""
            )

        segments: List[Segment] = []
        total_time = 0
        total_dist = 0
        
        # 1. Segmentation
        visited_locations = []
        
        for i in range(len(waypoints) - 1):
            start = waypoints[i]
            end = waypoints[i+1]
            
            segment = self._get_segment_directions(start, end)
            
            segments.append(segment)
            total_time += segment.duration_seconds
            total_dist += segment.distance_meters
            
            # Backtracking Logic (Simple MVP: Check if end node is close to any previous node)
            # Threshold: e.g., 200 meters (approx 0.002 degrees roughly)
            for visited in visited_locations:
                if abs(end.latitude - visited.latitude) < 0.002 and abs(end.longitude - visited.longitude) < 0.002:
                     # This is a warning, not an error. 
                     # Ideally we add this to 'warnings' list in response
                     pass
            
            visited_locations.append(start)
         
        # Ensure we add the last point
        visited_locations.append(waypoints[-1])

        # Combined polyline (Naive: just the first one for MVP, better to use segments in UI)
        combined_poly = segments[0].polyline if segments else "" 

        # Generate warnings
        warnings = []
        # Re-check specifically for A->B->A patterns
        for i in range(len(waypoints) - 2):
            if waypoints[i].id == waypoints[i+2].id:
                warnings.append(f"Backtracking detected at stop {i+3} ({waypoints[i+2].name}): You returned to the previous location.")

        return ItineraryResponse(
            segments=segments,
            total_duration_seconds=total_time,
            total_distance_meters=total_dist,
            combined_polyline=combined_poly,
            warnings=warnings
        )

    def _get_segment_directions(self, start: Waypoint, end: Waypoint) -> Segment:
        """
        Fetches directions for a single leg (Start -> End).
        Uses Google Maps Directions API if available, otherwise falls back to mock data.
        """
        if not self.gmaps:
            # Fallback for mock/dummy mode (MVP Development)
            return Segment(
                start_id=start.id,
                end_id=end.id,
                mode=start.mode,
                duration_seconds=600,
                distance_meters=1000,
                polyline="_p~iF~ps|U_ulLnnqC_mqNvxq`@" 
            )

        try:
            # Phase 2: Real API Call
            directions_result = self.gmaps.directions(
                origin=(start.latitude, start.longitude),
                destination=(end.latitude, end.longitude),
                mode=start.mode,
                departure_time="now" 
            )

            if not directions_result:
                raise Exception("No directions found")

            leg = directions_result[0]['legs'][0]
            
            return Segment(
                start_id=start.id,
                end_id=end.id,
                mode=start.mode,
                duration_seconds=leg['duration']['value'],
                distance_meters=leg['distance']['value'],
                polyline=directions_result[0]['overview_polyline']['points']
            )
        except Exception as e:
            print(f"Error fetching directions: {e}")
            # Fallback on error to avoid crashing the whole chain
            return Segment(
                start_id=start.id,
                end_id=end.id,
                mode=start.mode,
                duration_seconds=0,
                distance_meters=0,
                polyline=""
            )
