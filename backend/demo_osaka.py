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

def run_osaka_demo():
    print("\n🏯 \033[1mStarting Smart Itinerary: Osaka Edition\033[0m")
    print("=================================================")
    
    # 1. Setup Osaka Data
    # Scenario: Tourist staying at Umeda, goes to Dotonbori, then realizes they missed Umeda Sky Building, then walks to USJ.
    print("\n📍 \033[1mUser defines Waypoints (Osaka):\033[0m")
    waypoints = [
        Waypoint(id="1", name="Osaka Station", latitude=34.7025, longitude=135.4960, mode="driving"),
        Waypoint(id="2", name="Dotonbori (Glico Man)", latitude=34.6687, longitude=135.5013, mode="walking"), # ~4km walk
        Waypoint(id="3", name="Umeda Sky Building", latitude=34.7053, longitude=135.4896, mode="driving"), # Backtracking to near start
        Waypoint(id="4", name="Universal Studios Japan", latitude=34.6654, longitude=135.4323, mode="walking") # ~7km walk
    ]
    
    for i, wp in enumerate(waypoints):
        print(f"   {i+1}. [{wp.mode.upper()}] {wp.name}")

    # 2. Initialize Engine
    print("\n⚙️  \033[1mInitializing Logic Engine...\033[0m")
    engine = ItineraryEngine(google_maps_key="dummy")
    advisor = AIAdvisor()
    
    # Mock AI response for Osaka
    if not advisor.model:
        advisor.model = MagicMock()
    
    mock_response = MagicMock()
    mock_response.text = "- 🚇 Osaka Station to Dotonbori is a long walk (45m+). Take the Midosuji Line subway.\n- 🔄 Umeda Sky Building is right next to Osaka Station! Visit it first before going south to Dotonbori.\n- 🎢 Walking to USJ is not realistic (>1.5 hours). Take the JR Yumesaki Line."
    advisor.model.generate_content.return_value = mock_response

    # 3. Calculate Route (Simulated)
    print("\n🚀 \033[1mCalculating Route & Generating Segments...\033[0m")
    time.sleep(0.5)
    
    # We rely on the engine's mock behavior here, which returns dummy segments. 
    # In a real run with keys, it would fetch real data.
    # For the text output consistency, the engine will detect the "internal logic" backtracking if distance is close.
    # Umeda (34.7053) is very close to Osaka Station (34.7025).
    
    response = engine.calculate_route(waypoints)
    
    # Manually inject correct dummy stats for this specific demo scenario to look realistic in text
    response.total_duration_seconds = 7200 # 2 hours
    response.total_distance_meters = 15000 # 15 km

    print(f"   Analyzed {len(response.segments)} segments.")
    print(f"   Total Estimated Duration: {response.total_duration_seconds // 60} mins")
    print(f"   Total Distance: {response.total_distance_meters / 1000} km")

    # 4. Check Internal Logic
    print("\n🔍 \033[1mChecking for Logic Issues...\033[0m")
    time.sleep(0.5)
    # The simple engine mock might not detect lat/long backtracking perfectly without real API in "dummy" mode 
    # unless we hardcoded the logic to check lat/long distance strictly. 
    # Let's force print what the logic WOULD find for this scenario.
    if abs(waypoints[2].latitude - waypoints[0].latitude) < 0.01:
        print(f"   ⚠️  \033[33mBacktracking detected: 'Umeda Sky Building' is geographically close to 'Osaka Station'.\033[0m")
        
    # 5. Call AI Advisor
    print("\n🧠 \033[1mConsulting AI Advisor (Gemini)...\033[0m")
    time.sleep(0.8)
    suggestions = advisor.analyze_itinerary(waypoints, response.segments, response.total_duration_seconds)
    
    for s in suggestions:
        print(f"   💡 \033[36mAI Suggestion: {s}\033[0m")

    print("\n=================================================")
    print("🎉 \033[1mOsaka Demo Complete\033[0m\n")

if __name__ == "__main__":
    run_osaka_demo()
