from fastapi.testclient import TestClient
from backend.main import app

client = TestClient(app)

def test_read_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "service": "Smart Itinerary Backend"}

def test_calculate_itinerary_mock():
    payload = {
        "session_id": "test_123",
        "waypoints": [
            {"id": "A", "latitude": 25.0, "longitude": 121.0},
            {"id": "B", "latitude": 25.1, "longitude": 121.1}
        ]
    }
    response = client.post("/calculate_itinerary", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert len(data["segments"]) == 1
    assert data["total_duration_seconds"] == 600
