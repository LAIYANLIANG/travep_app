import googlemaps
from typing import List, Tuple
from .models_itinerary import Waypoint, Segment, ItineraryResponse

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
        self.gmaps = googlemaps.Client(key=google_maps_key) if google_maps_key and google_maps_key != "dummy" else None

    def calculate_route(self, waypoints: List[Waypoint]) -> ItineraryResponse:
        """
        Calculates the full itinerary by segmenting it into legs.
        
        Args:
            waypoints: List of Waypoint objects defined by the user.
            
        Returns:
            ItineraryResponse containing segments, totals, polyline, and warnings.
        """
        if len(waypoints) < 2:
            print(f"⚠️ [ENGINE] Not enough waypoints ({len(waypoints)}), returning empty response", flush=True)
            return ItineraryResponse(
                segments=[], 
                total_duration_seconds=0, 
                total_distance_meters=0, 
                combined_polyline="",
                route_polyline=[],
                warnings=[]
            )

        print(f"🟢 [ENGINE] Starting route calculation for {len(waypoints)} waypoints", flush=True)

        segments: List[Segment] = []
        total_time = 0
        total_dist = 0
        
        for i in range(len(waypoints)):
            # Auto-Geocoding if lat/lng are 0 or missing (Simple validation)
            current_wp = waypoints[i]
            if (current_wp.latitude == 0.0 and current_wp.longitude == 0.0) or (abs(current_wp.latitude) < 0.0001 and abs(current_wp.longitude) < 0.0001):
                 if self.gmaps and current_wp.name:
                     print(f"🌍 Auto-Geocoding: {current_wp.name}", flush=True)
                     try:
                         geocode_res = self.gmaps.geocode(current_wp.name)
                         if geocode_res:
                             loc = geocode_res[0]['geometry']['location']
                             current_wp.latitude = loc['lat']
                             current_wp.longitude = loc['lng']
                             print(f"   -> Found: {loc}", flush=True)
                     except Exception as e:
                         print(f"❌ Geocode Error: {e}", flush=True)
        
        visited_locations = []

        segments: List[Segment] = []
        total_time = 0
        total_dist = 0
        
        # 1. Segmentation
        for i in range(len(waypoints) - 1):
            start = waypoints[i]
            end = waypoints[i+1]
            
            # Skip if still invalid after geocoding attempt
            if (start.latitude == 0 and start.longitude == 0) or (end.latitude == 0 and end.longitude == 0):
                 print(f"⚠️ Skipping segment {start.name} -> {end.name} due to invalid coordinates.", flush=True)
                 continue

            print(f"🟢 [ENGINE] Calculating segment {i+1}: {start.name} -> {end.name}", flush=True)
            segment = self._get_segment_directions(start, end)
            
            segments.append(segment)
            total_time += segment.duration_seconds
            total_dist += segment.distance_meters
            
            # Backtracking Logic
            for visited in visited_locations:
                if abs(end.latitude - visited.latitude) < 0.002 and abs(end.longitude - visited.longitude) < 0.002:
                     pass
            
            visited_locations.append(start)
         
        # Ensure we add the last point
        visited_locations.append(waypoints[-1])
        
        print(f"🟢 [ENGINE] Calculated {len(segments)} segments, total time: {total_time}s", flush=True)

        # Combined polyline (Naive: just the first one for MVP, better to use segments in UI)
        combined_poly = segments[0].polyline if segments else "" 
        
        # Decode for frontend (Legacy support)
        # We use the library utility directly, no need for client instance if just decoding
        route_poly_decoded = []
        if combined_poly:
             try:
                 route_poly_decoded = googlemaps.convert.decode_polyline(combined_poly)
             except Exception as e:
                 print(f"⚠️ Polyline Decode Warning: {e}")
        
        # Stitch all segment polylines for the full visual path
        full_path_points = []
        if segments:
            for seg in segments:
                if seg.polyline:
                    try:
                        decoded = googlemaps.convert.decode_polyline(seg.polyline)
                        full_path_points.extend(decoded)
                    except:
                        pass
        
        # If full path is empty but we have a combined one (e.g. from Mock), use that
        if not full_path_points and route_poly_decoded:
            full_path_points = route_poly_decoded

        # Convert to list of dicts for Pydantic/Frontend
        # googlemaps returns [{'lat': ..., 'lng': ...}] which matches our need
        route_polyline_export = full_path_points

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
            route_polyline=route_polyline_export,
            warnings=warnings
        )

    def _get_segment_directions(self, start: Waypoint, end: Waypoint) -> Segment:
        """
        Fetches directions for a single leg (Start -> End).
        Uses Google Maps Directions API if available, otherwise falls back to mock data.
        """
        if not self.gmaps:
            # Fallback for mock/dummy mode (MVP Development)
            print("⚠️ Google Maps Client not initialized (Invalid Key?). Using Mock.")
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
