from unittest.mock import MagicMock, patch
from .ai_advisor import AIAdvisor
from .models import Waypoint, Segment

def test_ai_advisor_mock():
    # Mock waypoints and segments
    waypoints = [
        Waypoint(id="1", name="A", latitude=0, longitude=0, mode="walking"),
        Waypoint(id="2", name="B", latitude=0, longitude=0, mode="walking")
    ]
    segments = [
        Segment(start_id="1", end_id="2", mode="walking", duration_seconds=7200, distance_meters=10000, polyline="")
    ]
    
    # Instantiate Advisor
    advisor = AIAdvisor()
    
    # Mock the internal GenerativeModel if api key exists (or force mock if not)
    # Here we mock the behavior regardless of key presence for stable testing
    advisor.model = MagicMock()
    mock_response = MagicMock()
    mock_response.text = "- Suggestion 1\n- Suggestion 2"
    advisor.model.generate_content.return_value = mock_response
    
    suggestions = advisor.analyze_itinerary(waypoints, segments, 7200)
    
    assert len(suggestions) == 2
    assert "Suggestion 1" in suggestions[0]
