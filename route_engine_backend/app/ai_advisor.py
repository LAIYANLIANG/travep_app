import os
import google.generativeai as genai
from typing import List
from .models_itinerary import Waypoint, Segment

class AIAdvisor:
    """
    AI Advisory Module using Google Gemini.
    Analyzes the calculated itinerary (waypoints + segments) to provide actionable suggestions
    regarding pacing, logic, and travel modes.
    """
    def __init__(self):
        # Access GEMINI_API_KEY from environment (Standardized in route_engine_backend)
        self.api_key = os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY") 
        if self.api_key:
            genai.configure(api_key=self.api_key)
            self.model = genai.GenerativeModel('gemini-pro')
        else:
            self.model = None

    def analyze_itinerary(self, waypoints: List[Waypoint], segments: List[Segment], total_time: int) -> List[str]:
        """
        Generates smart suggestions based on the itinerary data.
        
        Args:
            waypoints: List of stops.
            segments: Calculated route segments.
            total_time: Total duration in seconds.
            
        Returns:
            List of suggestion strings (max 3).
        """
        if not self.model:
            return ["AI suggestions unavailable (Missing or Invalid API Key)"]

        # Construct Prompt
        prompt = f"""
        Act as a travel expert. Analyze this itinerary and provide 3 short, actionable suggestions (max 1 sentence each).
        Focus on logic, pacing, and mode of transport.
        
        Total Duration: {total_time // 60} minutes.
        Stops:
        """
        for i, w in enumerate(waypoints):
            prompt += f"{i+1}. {w.name} ({w.mode})\n"
        
        prompt += "\nSegments:\n"
        for s in segments:
            prompt += f"- {s.mode.upper()}: {s.duration_seconds // 60} mins\n"

        prompt += "\nProvide suggestions:"

        try:
            response = self.model.generate_content(prompt)
            # Simple parsing: expect suggestions on new lines
            suggestions = [line.strip("- *") for line in response.text.split('\n') if line.strip()]
            return suggestions[:3]
        except Exception as e:
            print(f"Gemini Error: {e}")
            return ["Error generating AI suggestions"]
