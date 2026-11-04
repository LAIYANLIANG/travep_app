import os
import httpx
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
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
                next_url = data["meta"]["links"]["next"]
                # response_next = await client.get(next_url, headers=headers) # Using full URL provided by API
                # Amadeus sometimes gives full URL, sometimes relative. 
                # Be safe and just use current params logic if needed, but for now stick to one large page.
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

# ==========================================
# 接收前端選定餐廳並新增的 POST 接口
# ==========================================

# 1. 定義前端 POST 傳過來的 JSON 欄位格式
class AddRestaurantRequest(BaseModel):
    trip_id: str               # 要加入哪一個行程 ID
    name: str                  # 餐廳名稱
    latitude: float            # 緯度
    longitude: float           # 經度
    category: Optional[str] = "餐廳"  # 類別 (如：拉麵、燒肉、咖啡廳)
    note: Optional[str] = None        # 使用者自訂備註 (如：必點炸雞)

# 2. 建立 POST 端點
@router.post("/restaurants/add")
async def add_restaurant_to_trip(request: AddRestaurantRequest):
    """
    接收前端選定的餐廳，處理加入行程邏輯
    完整路徑: POST http://127.0.0.1:8000/api/restaurants/add
    """
    try:
        print(f"📥 收到新增餐廳: {request.name} (座標: {request.latitude}, {request.longitude}) -> 行程: {request.trip_id}")
        
        # 這裡之後可以寫入 Firebase Firestore 或呼叫行程演算法
        # 目前先回傳成功的 Mock 狀態
        result = {
            "success": True,
            "message": f"成功將「{request.name}」加入行程 {request.trip_id}！",
            "restaurant_data": request.model_dump()
        }
        return result

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))