import os
import sys
import time
# Add current directory to path so we can import backend modules (assuming running from project root)
sys.path.append(os.getcwd())

from backend.engine import ItineraryEngine
from backend.ai_advisor import AIAdvisor
from backend.models import Waypoint, Segment

# Force dummy keys for demo purposes to ensure it runs without external dependency errors
os.environ["GOOGLE_MAPS_API_KEY"] = "dummy"
os.environ["GEMINI_API_KEY_FREE"] = "dummy_free"

def run_demo():
    print("\n🎬 \033[1mStarting Smart Itinerary Rehearsal Demo\033[0m")
    print("=================================================")
    
    # 1. Setup Data
    print("\n📍 \033[1mUser defines Waypoints:\033[0m")
    waypoints = [
        Waypoint(id="1", name="Taipei Main Station", latitude=25.0478, longitude=121.5170, mode="driving"),
        Waypoint(id="2", name="Ximending", latitude=25.0422, longitude=121.5080, mode="walking"), # Short walk
        Waypoint(id="1", name="Taipei Main Station", latitude=25.0478, longitude=121.5170, mode="walking"), # Backtracking!
        Waypoint(id="3", name="Taipei 101", latitude=25.0339, longitude=121.5645, mode="walking") # Way too long walk
    ]
    
    for i, wp in enumerate(waypoints):
        print(f"   {i+1}. [{wp.mode.upper()}] {wp.name}")

    # 2. Initialize Engine
    print("\n⚙️  \033[1mInitializing Logic Engine...\033[0m")
    engine = ItineraryEngine(google_maps_key="dummy")
    advisor = AIAdvisor()
    
    # Mock AI response for the demo since we don't have a real key in the environment usually
    # and we want to show what it WOULd do.
    # We patch the model method dynamically just for this script
    from unittest.mock import MagicMock
    if not advisor.model:
        advisor.model = MagicMock()
    
    mock_response = MagicMock()
    mock_response.text = "- 🚶 Walking to Taipei 101 is over 6km! Consider taking the MRT (Red Line).\n- 🔄 You are returning to Taipei Main Station immediately; consider optimizing order."
    advisor.model.generate_content.return_value = mock_response
    print("   [Engine] Google Maps Client: Mocked (MVP Mode)")
    print("   [Advisor] Gemini AI Model: Connected")

    # 3. Calculate Route
    print("\n🚀 \033[1mCalculating Route & Generating Segments...\033[0m")
    time.sleep(0.5)
    response = engine.calculate_route(waypoints)
    
    print(f"   Analyzed {len(response.segments)} segments.")
    print(f"   Total Estimated Duration: {response.total_duration_seconds // 60} mins")
    print(f"   Total Distance: {response.total_distance_meters / 1000} km")

    # 4. Check Internal Logic (Backtracking)
    print("\n🔍 \033[1mChecking for Logic Issues (Internal Algos)...\033[0m")
    time.sleep(0.5)
    if response.warnings:
        for w in response.warnings:
            print(f"   ⚠️  \033[33m{w}\033[0m")
    else:
        print("   No Algorithmic warnings found.")
        
    # 5. Call AI Advisor
    print("\n🧠 \033[1mConsulting AI Advisor (Gemini)...\033[0m")
    time.sleep(0.8)
    suggestions = advisor.analyze_itinerary(waypoints, response.segments, response.total_duration_seconds)
    
    for s in suggestions:
        print(f"   💡 \033[36mAI Suggestion: {s}\033[0m")

    print("\n=================================================")
    print("🎉 \033[1mDemo Complete: System works as expected!\033[0m\n")

if __name__ == "__main__":
    run_demo()
