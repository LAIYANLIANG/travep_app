from typing import List, Optional
from pydantic import BaseModel

class Waypoint(BaseModel):
    """
    Represents a single stop in the itinerary.
    """
    id: str
    name: str = ""
    latitude: float
    longitude: float
    mode: str = "driving"  # driving, walking, transit


class ItineraryRequest(BaseModel):
    session_id: str
    waypoints: List[Waypoint]
    optimize_for: str = "time"  # time, distance

class Segment(BaseModel):
    """
    Represents a computed route between two consecutive waypoints.
    """
    start_id: str
    end_id: str
    mode: str
    duration_seconds: int
    distance_meters: int
    polyline: str  # Encoded polyline for this segment

class ItineraryResponse(BaseModel):
    """
    The full calculation result returned to the client.
    Includes aggregated stats, merged polyline, and AI warnings.
    """
    segments: List[Segment]
    total_duration_seconds: int
    total_distance_meters: int
    combined_polyline: str # Merged polyline for the whole route
    route_polyline: List[dict] = [] # Legacy support: List of {"lat":..., "lng":...} for frontend visualization
    warnings: List[str] = []
