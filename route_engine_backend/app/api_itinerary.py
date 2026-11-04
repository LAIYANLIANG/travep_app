import os
from fastapi import APIRouter, HTTPException
from .models_itinerary import ItineraryRequest, ItineraryResponse, Waypoint
from .engine import ItineraryEngine
from .ai_advisor import AIAdvisor

router = APIRouter()

# Initialize Engine and Advisor
GOOGLE_MAPS_KEY = os.getenv("GOOGLE_MAPS_API_KEY", "dummy")
engine = ItineraryEngine(google_maps_key=GOOGLE_MAPS_KEY)
advisor = AIAdvisor()

@router.post("/calculate_itinerary", response_model=ItineraryResponse)
def calculate_itinerary(request: dict):
    """
    Core API: Calculates the optimized itinerary with AI suggestions.
    
    Process:
    1.  Engine: Segments coordinates and fetches travel data (Maps API).
    2.  Advisor: Analyzes the results for logical/pacing issues (Gemini AI).
    3.  Returns: Combined response with polyline, stats, and warnings.
    
    Note: Accepts dict to handle frontend's nested location structure
    """
    try:
        print(f"🔵 [API] Received request: {request}", flush=True)
        
        # Transform frontend format to backend format
        # Frontend sends: {location: {lat, lng}}
        # Backend expects: {latitude, longitude}
        transformed_waypoints = []
        for wp_data in request.get("waypoints", []):
            if "location" in wp_data:
                # Nested format from frontend
                loc = wp_data["location"]
                transformed_wp = {
                    "id": wp_data.get("id", ""),
                    "name": wp_data.get("name", ""),
                    "latitude": loc.get("lat", 0.0),
                    "longitude": loc.get("lng", 0.0),
                    "mode": wp_data.get("mode", "driving")
                }
            else:
                # Already flat format (backward compatibility)
                transformed_wp = wp_data
            
            transformed_waypoints.append(Waypoint(**transformed_wp))
        
        print(f"🔵 [API] Transformed {len(transformed_waypoints)} waypoints", flush=True)
        for i, wp in enumerate(transformed_waypoints):
            print(f"  WP{i+1}: {wp.name} @ ({wp.latitude}, {wp.longitude})", flush=True)
        
        # Create proper request object
        itinerary_request = ItineraryRequest(
            session_id=request.get("session_id", "default"),
            waypoints=transformed_waypoints,
            optimize_for=request.get("optimize_for", "time")
        )
        
        # 1. Calculate Route (Segments, Time, Distance)
        print(f"🔵 [API] Calling engine.calculate_route...", flush=True)
        response = engine.calculate_route(itinerary_request.waypoints)
        print(f"🔵 [API] Engine returned {len(response.segments)} segments", flush=True)
        print(f"🔵 [API] Route polyline points: {len(response.route_polyline)}", flush=True)
        
        # 2. AI Analysis (Smart Suggestions)
        # Only run if we actually have segments
        if response.segments:
            suggestions = advisor.analyze_itinerary(
                waypoints=itinerary_request.waypoints,
                segments=response.segments,
                total_time=response.total_duration_seconds
            )
            # Merge logic: Append suggestions to warnings
            response.warnings.extend(suggestions)
        
        print(f"🔵 [API] Returning response with {len(response.route_polyline)} polyline points", flush=True)
        return response
    except Exception as e:
        import traceback
        print(f"❌ Error in calculate_itinerary: {e}", flush=True)
        print(traceback.format_exc(), flush=True)
        raise HTTPException(status_code=500, detail=str(e))


