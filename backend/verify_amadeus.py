import asyncio
import sys
import json
from unittest.mock import MagicMock, patch

# Add parent dir to path to import backend modules
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from backend.flights import search_flight_offers, FlightSearchRequest
from backend.restaurants import search_restaurants
from backend.lodging import get_hotels_by_geocode, get_hotel_offers

async def run_verification():
    print("🚀 Starting Amadeus Backend Logic Verification...")
    
    # --- 1. Verify Flights ---
    print("\n✈️  Verifying Flights API...")
    with patch("httpx.AsyncClient") as mock_client:
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "data": [{"type": "flight-offer", "id": "1", "price": {"total": "15000"}}],
            "dictionaries": {"currencies": {"TWD": "New Taiwan Dollar"}}
        }
        
        # Setup context manager mock
        mock_instance = mock_client.return_value
        mock_instance.__aenter__.return_value.post.return_value = mock_response
        
        # Perform Call
        req = FlightSearchRequest(payload={
            "currencyCode": "TWD", 
            "originDestinations": [], 
            "travelers": []
        })
        
        # Must patch get_amadeus_token as well
        with patch("backend.flights.get_amadeus_token", return_value="mock_token"):
             result = await search_flight_offers(req)
        
        if "data" in result and result["data"][0]["price"]["total"] == "15000":
            print("✅ Flights API Logic: PASSED (Parsed Response Correctly)")
        else:
            print(f"❌ Flights API Logic: FAILED - Result: {result}")

    # --- 2. Verify Restaurants ---
    print("\n🍽️  Verifying Restaurants API...")
    with patch("httpx.AsyncClient") as mock_client:
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "data": [{"name": "Tasty Place", "tags": ["restaurant", "korean"]}]
        }
        
        mock_instance = mock_client.return_value
        mock_instance.__aenter__.return_value.get.return_value = mock_response
        
        with patch("backend.flights.get_amadeus_token", return_value="mock_token"):
            result = await search_restaurants(latitude=25.03, longitude=121.56, keyword="korean")
            
        if len(result["data"]) == 1 and result["data"][0]["name"] == "Tasty Place":
             print("✅ Restaurants API Logic: PASSED (Filtered Correctly)")
        else:
            print(f"❌ Restaurants API Logic: FAILED - Result: {result}")

    # --- 3. Verify Lodging ---
    print("\n🏨 Verifying Lodging API (Step 1 & 2)...")
    with patch("httpx.AsyncClient") as mock_client:
        # We need to simulate distinct calls for Step 1 (Geo) and Step 2 (Offers)
        # This is harder with a single mock_instance, but let's test Step 1 mainly.
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "data": [{"hotelId": "H123", "name": "Grand Hotel"}]
        }
        
        mock_instance = mock_client.return_value
        mock_instance.__aenter__.return_value.get.return_value = mock_response
        
        with patch("backend.flights.get_amadeus_token", return_value="mock_token"):
             result = await get_hotels_by_geocode(37.5, 127.0)
        
        if result["data"][0]["hotelId"] == "H123":
             print("✅ Lodging API Logic: PASSED (Step 1 Found Hotels)")
        else:
             print(f"❌ Lodging API Logic: FAILED - Result: {result}")

if __name__ == "__main__":
    asyncio.run(run_verification())
