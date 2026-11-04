import os
import httpx
import json
from fastapi import APIRouter, HTTPException, Body
from pydantic import BaseModel
from typing import List, Optional, Dict, Any

router = APIRouter()

# --- Configuration ---
AMADEUS_CLIENT_ID = os.getenv("AMADEUS_CLIENT_ID")
AMADEUS_CLIENT_SECRET = os.getenv("AMADEUS_CLIENT_SECRET")
AMADEUS_BASE_URL = "https://test.api.amadeus.com"  # Switch to production for live

# --- Token Management (Simple In-Memory for Demo) ---
_access_token = None
# _token_expiry = 0 # Not implemented for simplicity

async def get_amadeus_token():
    global _access_token
    
    # Check environment variables here to ensure they were loaded
    id = os.getenv("AMADEUS_CLIENT_ID")
    secret = os.getenv("AMADEUS_CLIENT_SECRET")
    
    if not id or not secret:
        raise HTTPException(status_code=500, detail="Amadeus API Keys missing in .env")

    # In a real app, check expiry properly. For now, we fetch new if None.
    if _access_token:
        # Check validity logic would go here
        return _access_token

    async with httpx.AsyncClient(timeout=10.0) as client:
        try:
            response = await client.post(
                f"{AMADEUS_BASE_URL}/v1/security/oauth2/token",
                data={
                    "grant_type": "client_credentials",
                    "client_id": id,
                    "client_secret": secret
                },
                headers={"Content-Type": "application/x-www-form-urlencoded"}
            )
            if response.status_code != 200:
                print(f"Amadeus Auth Error Details: {response.text}")
                raise HTTPException(status_code=500, detail="Failed to authenticate with Amadeus")
            
            data = response.json()
            _access_token = data["access_token"]
            return _access_token
        except httpx.HTTPStatusError as e:
            print(f"Amadeus Auth HTTP Error: {e.response.text}")
            raise HTTPException(status_code=500, detail="Failed to authenticate with Amadeus")

# --- Models ---
# We use flexible Dict[str, Any] for the input payload to allow maximum flexibility 
# as per the complexity of the Amadeus API, but define a wrapper for documentation.
class FlightSearchRequest(BaseModel):
    # This matches the structure:
    # { "currencyCode": "TWD", "originDestinations": [...], "travelers": [...], ... }
    payload: Dict[str, Any] 

# --- Endpoints ---

@router.post("/shopping/flight-offers")
async def search_flight_offers(request: FlightSearchRequest):
    """
    Proxy endpoint for Amadeus Flight Offers Search v2 (POST).
    """
    token = await get_amadeus_token()
    
    url = f"{AMADEUS_BASE_URL}/v2/shopping/flight-offers"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    # Ensure maxFlightOffers is set if not present to maximize retrieval
    payload = request.payload
    if "searchCriteria" not in payload:
        payload["searchCriteria"] = {}
    if "maxFlightOffers" not in payload["searchCriteria"]:
         payload["searchCriteria"]["maxFlightOffers"] = 50 # Default max
 
    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            # Note: We are sending the payload exactly as received/modified
            response = await client.post(url, json=payload, headers=headers)
            
            # Simple error handling
            if response.status_code != 200:
                print(f"Amadeus API Error: {response.text}")
                return {
                    "error": True, 
                    "status_code": response.status_code,
                    "details": response.json()
                }

            data = response.json()
            return data

        except Exception as e:
            import traceback
            print(f"❌ Flight API Exception: {e}")
            traceback.print_exc()
            return {"error": True, "message": str(e) or "Unknown error occurred during Flight Search"}
