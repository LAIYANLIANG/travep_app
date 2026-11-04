import os
import httpx
from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional, Dict, Any

router = APIRouter()

#Re-use config from flights or centralized config (duplication for now to keep modular as requested)
AMADEUS_CLIENT_ID = os.getenv("AMADEUS_CLIENT_ID")
AMADEUS_CLIENT_SECRET = os.getenv("AMADEUS_CLIENT_SECRET")
AMADEUS_BASE_URL = "https://test.api.amadeus.com"

# --- Token Helper (Ideally shared) ---
async def get_amadeus_token():
    # TODO: Refactor to shared utility
    from .flights import get_amadeus_token as fetch_token
    return await fetch_token()

# --- Endpoints ---

@router.get("/restaurants/search")
async def search_restaurants(
    latitude: float, 
    longitude: float, 
    radius: int = 2, 
    keyword: Optional[str] = None
):
    """
    Search for restaurants using Amadeus POI API.
    Auto-pagination (loop) to fetch max results if needed, 
    but for speed we start with basic page limit.
    """
    token = await get_amadeus_token()
    
    # Switch to Activities API as POI is decommissioned
    url = f"{AMADEUS_BASE_URL}/v1/shopping/activities"
    headers = {
        "Authorization": f"Bearer {token}",
    }
    
    params = {
        "latitude": latitude,
        "longitude": longitude,
        "radius": radius, # km
    }

    all_pois = []
    
    async with httpx.AsyncClient(timeout=20.0) as client:
        try:
            response = await client.get(url, params=params, headers=headers)
            if response.status_code != 200:
                 return {"error": True, "details": response.json()}
            
            data = response.json()
            if "data" in data:
                all_pois.extend(data["data"])
            
            # Simple "Next Page" logic (Limit to 1 extra page for speed in demo)
            if "meta" in data and "links" in data["meta"] and "next" in data["meta"]["links"]:
                pass 

            # Filter by keyword if provided (Client-side filtering is also an option, 
            # but backend filtering reduces payload)
            if keyword:
                keyword_lower = keyword.lower()
                all_pois = [
                    p for p in all_pois 
                    if keyword_lower in p.get("name", "").lower() or 
                       any(keyword_lower in tag.lower() for tag in p.get("tags", []))
                ]

            return {"data": all_pois}

        except Exception as e:
            return {"error": True, "message": str(e)}
