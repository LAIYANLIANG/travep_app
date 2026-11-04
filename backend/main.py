import os
from dotenv import load_dotenv
load_dotenv()

from fastapi import FastAPI, HTTPException
from .models import ItineraryRequest, ItineraryResponse
from .engine import ItineraryEngine
from .ai_advisor import AIAdvisor
from .flights import router as flights_router
from .restaurants import router as restaurants_router
from .lodging import router as lodging_router

app = FastAPI(title="Smart Itinerary Backend")

# --- CORS Configuration ---
from fastapi.middleware.cors import CORSMiddleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Request Logger Middleware (Diagnostics) ---
@app.middleware("http")
async def log_requests(request, call_next):
    print(f"📡 Incoming Request: {request.method} {request.url.path}")
    response = await call_next(request)
    print(f"🛑 Response Status: {response.status_code}")
    return response

# Include Routers with explicit slash handling
app.include_router(flights_router, prefix="/api", tags=["Flights"])
app.include_router(restaurants_router, prefix="/api", tags=["Restaurants"])
app.include_router(lodging_router, prefix="/api", tags=["Lodging"])

# --- Health Check (Verify API prefix) ---
@app.get("/api/health")
def api_health():
    return {"status": "ok", "message": "API prefix is working"}

# Initialize Engine and Advisor
GOOGLE_MAPS_KEY = os.getenv("GOOGLE_MAPS_API_KEY", "dummy")
engine = ItineraryEngine(google_maps_key=GOOGLE_MAPS_KEY)
advisor = AIAdvisor()

@app.get("/")
def read_root():
    """
    Health check endpoint.
    """
    return {"status": "ok", "service": "Smart Itinerary Backend"}

@app.post("/api/calculate_itinerary", response_model=ItineraryResponse)
def calculate_itinerary(request: ItineraryRequest):
    """
    Core API: Calculates the optimized itinerary with AI suggestions.
    
    Process:
    1.  Engine: Segments coordinates and fetches travel data (Maps API).
    2.  Advisor: Analyzes the results for logical/pacing issues (Gemini AI).
    3.  Returns: Combined response with polyline, stats, and warnings.
    """
    try:
        # 1. Calculate Route (Segments, Time, Distance)
        response = engine.calculate_route(request.waypoints)
        
        # 2. AI Analysis (Smart Suggestions)
        # Only run if we actually have segments
        if response.segments:
            suggestions = advisor.analyze_itinerary(
                waypoints=request.waypoints,
                segments=response.segments,
                total_time=response.total_duration_seconds
            )
            # Merge logic: Append suggestions to warnings
            response.warnings.extend(suggestions)
            
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    import os
    
    port = int(os.getenv("PORT", 8000))
    host = os.getenv("HOST", "127.0.0.1")
    
    print(f"🚀 Starting Itinerary Backend on {host}:{port}")
    uvicorn.run(app, host=host, port=port, reload=True)
