import os
import uuid
import logging
from typing import List, Optional
from fastapi import FastAPI, Header, HTTPException, Body
from pydantic import BaseModel
from dotenv import load_dotenv

from .services.maps_service import MapsService
from .services.solver_service import SolverService

# Setup Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("route-engine")

# Load Env
load_dotenv()
GOOGLE_MAPS_API_KEY = os.getenv("GOOGLE_MAPS_API_KEY")

if not GOOGLE_MAPS_API_KEY:
    logger.warning("⚠️  GOOGLE_MAPS_API_KEY not found. Service will fail on real calls.")

app = FastAPI(
    title="B2B Route Calculation Engine",
    version="1.0.0"
)

# CORS (Cross-Origin Resource Sharing)
# Required for Flutter Web and local dev integration
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Allow all for dev; restrict in prod
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Services
maps_service = MapsService(api_key=GOOGLE_MAPS_API_KEY or "dummy")
solver_service = SolverService()

# --- Models ---
class Location(BaseModel):
    lat: float
    lng: float

class Waypoint(BaseModel):
    id: str
    location: Location
    duration_check: Optional[int] = 60

class Constraints(BaseModel):
    transport_mode: str = "DRIVING"
    avoid_tolls: bool = False

class RouteRequest(BaseModel):
    mode: str  # OPTIMIZED | MAZE
    start_time: Optional[str] = None
    constraints: Constraints = Constraints()
    waypoints: List[Waypoint]

# --- Endpoints ---

@app.get("/")
def health_check():
    return {"status": "ok", "service": "route-engine"}

@app.post("/v1/routes/calculate")
def calculate_route(
    request: RouteRequest,
    x_organization_id: str = Header(..., alias="X-Organization-ID")
):
    logger.info(f"📝 Org [{x_organization_id}] Request: [{request.mode}] with {len(request.waypoints)} spots")

    if len(request.waypoints) < 2:
        raise HTTPException(status_code=400, detail="At least 2 waypoints required.")

    # 1. Solve Order (Maze vs Optimized)
    # Convert Pydantic models to dicts for internal logic
    waypoints_data = [wp.dict() for wp in request.waypoints]
    
    if request.mode == "OPTIMIZED":
        ordered_waypoints = solver_service.solve_tsp(waypoints_data)
    else:
        ordered_waypoints = solver_service.solve_maze(waypoints_data)

    # 2. Calculate Route Segments
    segments = []
    total_duration = 0
    total_distance = 0
    warnings = []

    for i in range(len(ordered_waypoints) - 1):
        start_wp = ordered_waypoints[i]
        end_wp = ordered_waypoints[i+1]
        
        # Real Google Maps Call
        route_data = maps_service.get_route_data(
            origin=start_wp['location'],
            destination=end_wp['location'],
            mode=request.constraints.transport_mode
        )

        if route_data:
            segments.append({
                "from_id": start_wp['id'],
                "to_id": end_wp['id'],
                "duration_seconds": route_data['duration_seconds'],
                "distance_meters": route_data['distance_meters'],
                "transport_mode": route_data['transport_mode'],
                "polyline": route_data['polyline']
            })
            total_duration += route_data['duration_seconds']
            total_distance += route_data['distance_meters']
        else:
            # Fallback for error/no route
            warnings.append(f"Could not calculate route from {start_wp['id']} to {end_wp['id']}")
            # Add dummy segment to keep continuity? Or fail? 
            # For now, fail softly with a warning and straight line stub if possible, or just skip.
            # Let's add a dummy zero-segment to avoid breaking the chain visually?
            segments.append({
                "from_id": start_wp['id'],
                "to_id": end_wp['id'],
                "duration_seconds": 0,
                "distance_meters": 0,
                "transport_mode": "UNKNOWN",
                "polyline": ""
            })

    return {
        "route_id": str(uuid.uuid4()),
        "total_duration_seconds": total_duration,
        "total_distance_meters": total_distance,
        "segments": segments,
        "warnings": warnings 
    }
