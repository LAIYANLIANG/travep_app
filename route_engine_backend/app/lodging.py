import os
import httpx
from fastapi import APIRouter, HTTPException, Query, Body
from typing import List, Optional, Dict, Any
from pydantic import BaseModel

router = APIRouter()

AMADEUS_BASE_URL = "https://test.api.amadeus.com"

# --- Token Helper ---
async def get_amadeus_token():
    from .flights import get_amadeus_token as fetch_token
    return await fetch_token()

# --- Models ---
class HotelSearchRequest(BaseModel):
    cityCode: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    checkInDate: str
    checkOutDate: str
    adults: int = 1
    roomQuantity: int = 1

# --- Endpoints ---

@router.get("/lodging/hotels-by-geocode")
async def get_hotels_by_geocode(
    latitude: float, 
    longitude: float, 
    radius: int = 5
):
    """
    Step 1: Find hotels (IDs) near a location.
    """
    token = await get_amadeus_token()
    url = f"{AMADEUS_BASE_URL}/v1/reference-data/locations/hotels/by-geocode"
    headers = {"Authorization": f"Bearer {token}"}
    params = {
        "latitude": latitude,
        "longitude": longitude,
        "radius": radius,
        "radiusUnit": "KM",
        "hotelSource": "ALL"
    }
    
    async with httpx.AsyncClient(timeout=20.0) as client:
        response = await client.get(url, params=params, headers=headers)
        if response.status_code != 200:
            if response.status_code == 404: return {"data": []}
            return {"error": True, "details": response.json()}
        return response.json()

@router.get("/lodging/hotel-offers")
async def get_hotel_offers(
    hotelIds: str, # Comma separated
    checkInDate: str,
    checkOutDate: str,
    adults: int = 1,
    currency: str = "TWD"
):
    """
    Step 2: Get specific offers for a list of hotel IDs.
    """
    token = await get_amadeus_token()
    url = f"{AMADEUS_BASE_URL}/v3/shopping/hotel-offers"
    headers = {"Authorization": f"Bearer {token}"}
    params = {
        "hotelIds": hotelIds,
        "checkInDate": checkInDate,
        "checkOutDate": checkOutDate,
        "adults": adults,
        "currency": currency,
        "bestRateOnly": "false" # Get all offers as requested for max info
    }
    
    async with httpx.AsyncClient(timeout=20.0) as client:
        response = await client.get(url, params=params, headers=headers)
        if response.status_code != 200:
             # Sometime v3 returns 404 if no offers found for those specific hotels
            if response.status_code == 404: return {"data": []}
            return {"error": True, "details": response.json()}
        return response.json()
