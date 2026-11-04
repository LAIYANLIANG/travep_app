import os
import sys
import time
from unittest.mock import MagicMock

# Add current directory to path
sys.path.append(os.getcwd())

from backend.engine import ItineraryEngine
from backend.ai_advisor import AIAdvisor
from backend.models import Waypoint

# Force dummy keys
os.environ["GOOGLE_MAPS_API_KEY"] = "dummy"
os.environ["GEMINI_API_KEY_FREE"] = "dummy_free"

def run_eastern_europe_demo():
    print("\n🌍 \033[1mStarting Smart Itinerary: Eastern Europe Grand Tour (10 Days)\033[0m")
    print("=============================================================")
    
    # 1. Setup Eastern Europe Data (10 Stops)
    # A classic loop: Prague -> South -> East -> North -> West -> Prague
    print("\n📍 \033[1mUser defines 10 Waypoints:\033[0m")
    waypoints = [
        Waypoint(id="1", name="Prague Old Town (CZ)", latitude=50.0878, longitude=14.4205, mode="driving"),
        Waypoint(id="2", name="Cesky Krumlov (CZ)", latitude=48.8109, longitude=14.3162, mode="driving"),
        Waypoint(id="3", name="Vienna (AT)", latitude=48.2082, longitude=16.3738, mode="driving"),
        Waypoint(id="4", name="Bratislava (SK)", latitude=48.1486, longitude=17.1077, mode="driving"),
        Waypoint(id="5", name="Budapest (HU)", latitude=47.4979, longitude=19.0402, mode="driving"),
        Waypoint(id="6", name="Krakow (PL)", latitude=50.0647, longitude=19.9450, mode="driving"),
        Waypoint(id="7", name="Auschwitz-Birkenau (PL)", latitude=50.0345, longitude=19.1804, mode="driving"),
        Waypoint(id="8", name="Warsaw (PL)", latitude=52.2297, longitude=21.0122, mode="driving"),
        Waypoint(id="9", name="Wroclaw (PL)", latitude=51.1079, longitude=17.0385, mode="driving"),
        Waypoint(id="10", name="Prague (CZ) - Return", latitude=50.0755, longitude=14.4378, mode="driving")
    ]
    
    for i, wp in enumerate(waypoints):
        print(f"   {i+1:2d}. [{wp.mode.upper()}] {wp.name}")

    # 2. Initialize Engine
    print("\n⚙️  \033[1mInitializing Logic Engine...\033[0m")
    engine = ItineraryEngine(google_maps_key="dummy")
    advisor = AIAdvisor()
    
    # Mock AI response for Eastern Europe
    if not advisor.model:
        advisor.model = MagicMock()
    
    mock_response = MagicMock()
    # Simulated advice for a 10-day trip covering this distance
    mock_response.text = "- 🏎️ Total driving distance is over 2,500km. For 10 days, that's ~4 hours driving daily. Doable but tight.\n- 🛂 Remember vignettes (toll stickers) are required for CZ, AT, SK, and HU highways.\n- ⚠️ Krakow to Warsaw is a long stretch. Consider taking the high-speed train (EIP) if not committed to driving."
    advisor.model.generate_content.return_value = mock_response

    # 3. Calculate Route (Simulated)
    print("\n🚀 \033[1mCalculating Route & Generating Segments...\033[0m")
    time.sleep(1.0) # Simulating heavy calculation
    
    # Manually inject stats for this long trip
    response = engine.calculate_route(waypoints)
    response.total_duration_seconds = 28 * 3600 # Approx 28 hours total driving
    response.total_distance_meters = 2200000 # 2200 km

    print(f"   Analyzed {len(response.segments)} segments across 5 countries.")
    print(f"   Total Estimated Driving Time: {response.total_duration_seconds // 3600} hours")
    print(f"   Total Distance: {response.total_distance_meters / 1000} km")

    # 4. Internal Logic Check
    print("\n🔍 \033[1mChecking for Logic Issues...\033[0m")
    time.sleep(0.5)
    # Loop check
    if abs(waypoints[0].latitude - waypoints[-1].latitude) < 0.1:
         print(f"   ℹ️  \033[32mCircular Route Detected: Standard 'Grand Loop' configuration.\033[0m")

    # 5. Call AI Advisor
    print("\n🧠 \033[1mConsulting AI Advisor (Gemini) for 10-Day Pace...\033[0m")
    time.sleep(1.2)
    suggestions = advisor.analyze_itinerary(waypoints, response.segments, response.total_duration_seconds)
    
    for s in suggestions:
        print(f"   💡 \033[36mAI Suggestion: {s}\033[0m")

    print("\n=============================================================")
    print("🎉 \033[1mEastern Europe Demo Complete\033[0m\n")

if __name__ == "__main__":
    run_eastern_europe_demo()
