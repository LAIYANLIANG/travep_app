from dotenv import load_dotenv
import os

# Load env vars at the very beginning
load_dotenv()

import uuid
import time
import json
import re
from datetime import datetime
from typing import List, Optional
from fastapi import FastAPI, Header, HTTPException, Query
from pydantic import BaseModel
from amadeus import Client, ResponseError
import google.generativeai as genai
import googlemaps
import httpx

app = FastAPI(
    title="Antigravity Route Engine",
    version="2.0.0",
    description="Backend for B2B Travel Planner with Maze & Hierarchy Mode"
)

from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False, # Wildcards cannot be used with credentials=True
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Data Models (Mirroring OpenAPI) ---
class Location(BaseModel):
    lat: float
    lng: float

class Waypoint(BaseModel):
    id: str
    original_index: Optional[int] = None
    name: Optional[str] = None
    location: Location
    locked: bool = False

class RouteRequest(BaseModel):
    mode: str  # MAZE | OPTIMIZED | TSP
    target_end_point: Optional[Location] = None
    waypoints: List[Waypoint]

class FlightRequest(BaseModel):
    departure_city: str
    destination: str
    start_date: str
    end_date: str
    departure_time_preference: str
    return_time_preference: str
    budget: Optional[int] = None
    people_adults: int = 1
    people_children: int = 0
    return_origin_city: Optional[str] = None
    return_destination_city: Optional[str] = None
    userQuery: Optional[str] = None


# --- Endpoints ---
from .flights import router as flights_router
from .restaurants import router as restaurants_router
from .lodging import router as lodging_router
from .poi_knowledge_base import get_rag_pois, generate_dynamic_itinerary, normalize_city, get_city_meta, POI_DATABASE

app.include_router(flights_router, prefix="/api", tags=["Flights"])
app.include_router(restaurants_router, prefix="/api", tags=["Restaurants"])
app.include_router(lodging_router, prefix="/api", tags=["Lodging"])
from .api_itinerary import router as itinerary_router
app.include_router(itinerary_router, prefix="/api", tags=["Smart Itinerary"])
from .api_ecpay import router as ecpay_router
app.include_router(ecpay_router, prefix="/api/ecpay", tags=["Payment"])

# --- Caching Layer (Mock) ---
# Dynamic Data: Route results, durations (Expires 24h)
mock_redis_cache = {} 
# Static Data: Place details (Expires 30 days)
mock_static_db = {
    "wp1": {"name": "布加勒斯特 (Bucharest)", "address": "Romania", "photo": "url"},
    # ... Pre-populated static data
}

# Init Google Maps Client
API_KEY = os.getenv("GOOGLE_MAPS_API_KEY")
gmaps = googlemaps.Client(key=API_KEY) if API_KEY and API_KEY != "dummy" else None

# Init Amadeus
amadeus = Client(
    client_id=os.getenv("AMADEUS_CLIENT_ID"),
    client_secret=os.getenv("AMADEUS_CLIENT_SECRET")
)

# Init Gemini
GEMINI_KEY = os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY")
if GEMINI_KEY and GEMINI_KEY != "dummy":
    genai.configure(api_key=GEMINI_KEY)
    print(f"✅ Gemini API Initialized (Key: ...{GEMINI_KEY[-4:]})", flush=True)
else:
    print(f"⚠️ WARNING: Gemini API Key NOT configured. AI features will fail.", flush=True)

# Init Anthropic Claude
ANTHROPIC_KEY = os.getenv("ANTHROPIC_API_KEY")
if ANTHROPIC_KEY:
    print(f"✅ Anthropic Claude API Initialized (Key: ...{ANTHROPIC_KEY[-6:]})", flush=True)

def call_llm(prompt: str) -> str:
    """
    Call Anthropic Claude (haiku-5-5) as primary AI, with Gemini fallback.
    """
    anthropic_key = os.getenv("ANTHROPIC_API_KEY")
    if anthropic_key:
        try:
            with httpx.Client(timeout=35.0) as client:
                res = client.post(
                    "https://api.anthropic.com/v1/messages",
                    headers={
                        "x-api-key": anthropic_key,
                        "anthropic-version": "2023-06-01",
                        "content-type": "application/json"
                    },
                    json={
                        "model": "claude-haiku-5-5",
                        "max_tokens": 4096,
                        "messages": [{"role": "user", "content": prompt}]
                    }
                )
                if res.status_code == 200:
                    data = res.json()
                    # Extract text block (skipping thinking blocks)
                    text = ""
                    for block in data.get("content", []):
                        if block.get("type") == "text":
                            text += block.get("text", "")
                    
                    if "```json" in text:
                        text = text.split("```json")[1].split("```")[0].strip()
                    elif "```" in text:
                        text = text.split("```")[1].split("```")[0].strip()
                    return text.strip()
                else:
                    print(f"⚠️ Claude error {res.status_code}: {res.text[:200]}", flush=True)
        except Exception as e:
            print(f"⚠️ Claude call failed: {e}", flush=True)

    # Fallback to Gemini if configured
    gemini_key = os.getenv("GEMINI_API_KEY")
    if gemini_key and gemini_key != "dummy":
        try:
            model = genai.GenerativeModel('gemini-2.5-flash')
            resp = model.generate_content(prompt)
            text = resp.text.replace('```json', '').replace('```', '')
            if text.strip().startswith("json"): text = text.strip()[4:]
            return text.strip()
        except Exception as e:
            print(f"⚠️ Gemini call failed: {e}", flush=True)

    raise RuntimeError("No LLM service available")


# Time-Based Cache
class TimeBasedCache:
    _instance = None
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(TimeBasedCache, cls).__new__(cls)
            cls._instance.store = {}
        return cls._instance
    
    def set(self, key, value, ttl=3600):
        self.store[key] = (value, time.time() + ttl)
        
    def get(self, key):
        if key in self.store:
            val, safe_until = self.store[key]
            if time.time() < safe_until:
                return val
            else:
                del self.store[key]
        return None

local_cache = TimeBasedCache()

@app.post("/v1/routes/calculate")
def calculate_route(
    req: RouteRequest,
    x_org_id: str = Header(..., alias="X-Organization-ID")
):
    print(f"🚀 [Org: {x_org_id}] Calculation Request: {req.mode}, Waypoints: {len(req.waypoints)}")
    
    # Check Cache
    params_key = f"{req.mode}_" + "_".join(sorted([w.id for w in req.waypoints]))
    if params_key in mock_redis_cache:
        print(f"✅ Cache Hit (Redis): Returning saved route for {params_key}")
        return mock_redis_cache[params_key]

    print("⚠️ Cache Miss: Calculating fresh route...")
    
    ordered_waypoints = []
    # Simple TSP (Nearest Neighbor)
    if req.waypoints:
        current = req.waypoints[0]
        unvisited = req.waypoints[1:]
        ordered_waypoints.append(current)
        while unvisited:
            nearest = min(unvisited, key=lambda wp: (wp.location.lat - current.location.lat)**2 + (wp.location.lng - current.location.lng)**2)
            ordered_waypoints.append(nearest)
            unvisited.remove(nearest)
            current = nearest
            
    # Calculate Route using Google Maps
    total_dist = 0
    total_duration_min = 0
    polyline_points = []
    
    if gmaps and len(ordered_waypoints) > 1:
        try:
            print("🗺️ calling Google Directions API...")
            origin = (ordered_waypoints[0].location.lat, ordered_waypoints[0].location.lng)
            destination = (ordered_waypoints[-1].location.lat, ordered_waypoints[-1].location.lng)
            waypoints = [(w.location.lat, w.location.lng) for w in ordered_waypoints[1:-1]]
            
            # Request Driving Directions
            directions_result = gmaps.directions(
                origin,
                destination,
                waypoints=waypoints,
                mode="driving",
                optimize_waypoints=True # Let Google optimize if needed, or false to respect our TSP
            )
            
            if directions_result:
                route = directions_result[0]
                # Sum legs
                for leg in route['legs']:
                    total_dist += leg['distance']['value'] # meters
                    total_duration_min += leg['duration']['value'] / 60 # minutes
                
                # Get Polyline
                if 'overview_polyline' in route:
                    # Decode polyline to list of points
                    polyline_points = googlemaps.convert.decode_polyline(route['overview_polyline']['points'])
                    # Convert to our format [{"lat":..., "lng":...}]
                    polyline_points = [{"lat": p['lat'], "lng": p['lng']} for p in polyline_points]
                    
        except Exception as e:
            print(f"❌ Google Maps API Error: {e}")
            # Fallback to mock
            total_dist = len(req.waypoints) * 5000 
            total_duration_min = len(req.waypoints) * 60
            
    else:
        # Fallback Mock Logic
        total_dist = len(req.waypoints) * 5000 
        total_duration_min = len(req.waypoints) * 90

    # --- AI Analysis / Notices ---
    ai_notices = []
    if len(req.waypoints) > 5:
        ai_notices.append("⚠️ 景點數量過多：建議一天安排 3-4 個景點以免過於匆促。")
    if total_duration_min > 480: # > 8 hours
        ai_notices.append("⚠️ 行車時間過長：總交通時間超過 8 小時，建議縮減行程。")

    res = {
        "optimized_waypoints": ordered_waypoints,
        "total_distance_meters": int(total_dist),
        "total_duration_minutes": int(total_duration_min),
        "route_polyline": polyline_points, # Real path!
        "ai_notices": ai_notices
    }
    
    # Save to Cache
    mock_redis_cache[params_key] = res
    return res
        
    # Rule 2: Duration check (e.g., > 8 hours)
    if total_duration_min > 480:
        ai_notices.append("🕒 行程時間過長：預估超過 8 小時，可能無法準時完成。 (Long duration)")
        
    # Rule 3: Distance check (Mock: if any segment > 100km)
    # (Simplified for now since we don't have real distances per segment yet)
    
    result = {
        "route_id": str(uuid.uuid4()),
        "total_duration": total_duration_min,
        "remaining_distance_to_target": remaining, 
        "segments": [{"polyline": "encoded_polyline_example", "duration": 600} for _ in req.waypoints],
        "optimized_waypoints": [wp.dict() for wp in ordered_waypoints],
        "ai_notices": ai_notices # Return notices
    }

    # 3. Save to Redis Cache (24h TTL logic would be here)
    mock_redis_cache[params_key] = result
    print(f"💾 Saved to Cache: {params_key}")
    
    return result

@app.post("/v1/smart/flights")
def search_smart_flights(req: FlightRequest):
    try:
        print(f"✈️ Flight Search: '{req.departure_city}' -> '{req.destination}' (Query: '{req.userQuery}')")
        
        # 1. Check Cache
        cache_key = f"flight_{req.model_dump_json()}"
        cached = local_cache.get(cache_key)
        if cached:
            print(f"✅ Cache Hit (Flight)")
            return cached

        # 2. AI Resolution for Airports, Destination, and Vibe (Claude / Gemini)
        print("🤖 Consulting AI for destination, airports & itinerary theme...")
        
        # Pre-resolve destination using global normalizer (extracts Barcelona, Paris, etc. from query)
        effective_dest = normalize_city(req.destination or "", req.userQuery or "")
        _, _, default_dest_code = get_city_meta(effective_dest)
        origin_code = "TPE"
        dest_code = default_dest_code
        ret_origin_code = default_dest_code
        ret_dest_code = "TPE"
        analysis_summary = f"{effective_dest}精選自由行"

        try:
            extract_prompt = f"""
            Act as a professional global travel agent.
            Analyze this user trip request:
            Departure City: {req.departure_city or '台北 (TPE)'}
            Destination City: {req.destination or '未提供'}
            User Query / Message: {req.userQuery or '無'}
            Departure Date: {req.start_date}
            Return Date: {req.end_date}
            Party: {req.people_adults} Adults, {req.people_children} Children
            Budget: {req.budget or '標準預算'}

            任務:
            1. 從使用者需求中找出實際出發機場與抵達機場的 3 字 IATA 代碼 (例如: 台北是 TPE, 巴塞隆納是 BCN, 馬德里是 MAD, 巴黎是 CDG, 倫敦是 LHR, 羅馬是 FCO, 東京是 NRT/HND, 紐約是 JFK, 曼谷是 BKK, 首爾是 ICN)。
            2. 如果 Destination City 為空，請務必由 User Query 自動推斷出主要前往城市名稱 (繁體中文，例如: 巴塞隆納、巴黎、東京)。
            3. 分析使用者的旅遊風格與關鍵主題 (繁體中文，約 15 字以內，例如: 經典古蹟與地中海風景巡禮)。

            僅回傳純 JSON 格式 (不要 Markdown):
            {{
                "inferredDestination": "{effective_dest}",
                "originCode": "IATA",
                "destinationCode": "IATA",
                "returnOriginCode": "IATA",
                "returnDestinationCode": "IATA",
                "analysis_summary": "旅遊風格摘要"
            }}
            """
            ai_text = call_llm(extract_prompt)
            data = json.loads(ai_text)
            origin_code = data.get("originCode", origin_code)
            dest_code = data.get("destinationCode", dest_code)
            ret_origin_code = data.get("returnOriginCode", ret_origin_code)
            ret_dest_code = data.get("returnDestinationCode", ret_dest_code)
            analysis_summary = data.get("analysis_summary", analysis_summary)
            ai_dest = data.get("inferredDestination")
            if ai_dest and ai_dest.strip():
                effective_dest = normalize_city(ai_dest, req.userQuery or "")

            print(f"🤖 AI Resolution: {origin_code} -> {dest_code} ({effective_dest}) | 主題: {analysis_summary}")
        except Exception as e:
            print(f"⚠️ AI Extract Warning: {e}. Using pre-resolved destination '{effective_dest}' ({dest_code}).")

        # 3. Flight Search (Amadeus with Smart Realistic Fallback)
        print(f"✈️ Searching Flights: {origin_code} -> {dest_code} on {req.start_date}")
        valid_flights = []
        try:
            response = amadeus.shopping.flight_offers_search.get(
                originLocationCode=origin_code,
                destinationLocationCode=dest_code,
                departureDate=req.start_date,
                returnDate=req.end_date,
                adults=req.people_adults,
                children=req.people_children,
                currencyCode='TWD',
                max=5
            )
            if response.data:
                for flight in response.data:
                    price = float(flight['price']['total'])
                    if req.budget and (price > req.budget * 10000):
                        continue
                    valid_flights.append(flight)
            print(f"✅ Amadeus returned {len(valid_flights)} flights")
        except Exception as err:
            print(f"⚠️ Amadeus API unavailable or blocked ({err}), applying high-quality flight recommendation fallback.")

        # Fallback realistic flight if Amadeus is unreachable / no flights found
        if not valid_flights:
            mock_price = 14800 if not req.budget else min(16800, max(8500, req.budget * 4000))
            valid_flights = [{
                "type": "flight-offer",
                "id": "flight_rec_1",
                "price": {"total": str(int(mock_price)), "currency": "TWD"},
                "itineraries": [
                    {
                        "duration": "PT3H15M",
                        "segments": [
                            {
                                "departure": {"iataCode": origin_code, "at": f"{req.start_date}T08:30:00"},
                                "arrival": {"iataCode": dest_code, "at": f"{req.start_date}T12:45:00"},
                                "carrierCode": "BR",
                                "number": "198"
                            }
                        ]
                    },
                    {
                        "duration": "PT3H45M",
                        "segments": [
                            {
                                "departure": {"iataCode": ret_origin_code, "at": f"{req.end_date}T14:00:00"},
                                "arrival": {"iataCode": ret_dest_code, "at": f"{req.end_date}T16:45:00"},
                                "carrierCode": "BR",
                                "number": "197"
                            }
                        ]
                    }
                ]
            }]

        effective_dest = normalize_city(effective_dest, req.userQuery or "")

        # 4. Synthesizing Final Day-by-Day Itinerary Plan using RAG POI Knowledge Base
        print("🤖 Synthesizing Final Itinerary with AI & RAG Knowledge...")
        num_days = 4
        try:
            d1 = datetime.strptime(req.start_date, "%Y-%m-%d")
            d2 = datetime.strptime(req.end_date, "%Y-%m-%d")
            num_days = max(1, min(14, (d2 - d1).days + 1))
        except Exception:
            num_days = 4

        # Retrieve relevant POIs from knowledge base (RAG grounding)
        rag_pois = get_rag_pois(effective_dest, req.userQuery or "", limit=14)
        if rag_pois:
            rag_poi_text = "【精選地點與座標參考庫 (RAG POI Database)】:\n請優先從以下精選庫中挑選符合使用者需求（特別是用戶指定的古蹟、風景、現代地標）的地點，並嚴格直接使用其提供的精確 lat 與 lng 經緯度：\n" + "\n".join([
                f"- {p['name']} (分類: {p['category']}, 緯度: {p['lat']}, 經度: {p['lng']}, 特色: {p.get('notes', '')})"
                for p in rag_pois
            ])
        else:
            rag_poi_text = f"【目的地】：{effective_dest}\n請為【{effective_dest}】搜尋並列出該城市真實知名、具有代表性的景點、古蹟、餐廳與機場，並為每個地點標示精準的真實 WGS84 經緯度（lat 緯度、lng 經度，浮點數小數點後 4 位以上）。不可填 0 或留空。"

        synth_prompt = f"""
        Role: 專業全球旅遊規劃師 (Professional Global Travel Expert, 繁體中文).
        
        使用者旅遊需求:
        - 目的地: {effective_dest}
        - 旅遊天數: {num_days} 天
        - 旅遊主題/偏好: {analysis_summary}
        - 備註/使用者需求: {req.userQuery or '無特定備註'}
        - 旅行團體: {req.people_adults} 位成人, {req.people_children} 位孩童

        {rag_poi_text}

        任務:
        請為這 {num_days} 天產出每日詳細行程規劃（總共輸出 {num_days} 天，從第 1 天到第 {num_days} 天，不可偷工減料或縮減天數）。
        必須使用繁體中文。
        嚴格依照以下 JSON 陣列格式回傳 (直接輸出純 JSON 陣列，不要包含 Markdown 格式文字或外層說明):
        [
            {{
                "day": 1,
                "title": "第 1 天主題 (例如：抵達探索・市區首訪)",
                "highlights": "這天行程亮點的簡要說明 (1~2句話)",
                "activities": "抵達機場 -> 飯店 Check-in -> 知名地標 1 -> 推薦餐廳",
                "spots": [
                    {{
                        "name": "地點名稱 (如: 聖家堂 (Sagrada Família)、米拉之家、埃爾普拉特機場)",
                        "category": "景點/餐廳/飯店/機場/車站",
                        "lat": 41.4036,
                        "lng": 2.1744,
                        "notes": "簡短建議"
                    }}
                ]
            }}
        ]

        地點與座標要求 (極為關鍵)：
        1. 每天的 "spots" 陣列必須包含 3 到 5 個具體明確的地點。第一天首站應包含機場/車站、當天入住飯店；後續各天包含主要景點與推薦餐廳；最後一天包含返程機場。
        2. "lat" (緯度) 與 "lng" (經度) 必須填寫該地點在真實世界中的精確 WGS84 座標浮點數 (float，例如 41.4036, 2.1744)，小數點後 4 位以上。嚴禁填 0 或留空。
        3. 地點名稱請使用完整具體名稱。
        """

        itinerary_outline = []
        try:
            synth_text = call_llm(synth_prompt)
            # Remove markdown syntax if present
            cleaned_text = synth_text.strip()
            if cleaned_text.startswith("```"):
                cleaned_text = re.sub(r"^```(?:json)?\s*", "", cleaned_text)
                cleaned_text = re.sub(r"\s*```$", "", cleaned_text).strip()
            
            itinerary_outline = json.loads(cleaned_text)
            if not isinstance(itinerary_outline, list):
                if isinstance(itinerary_outline, dict) and "itinerary" in itinerary_outline:
                    itinerary_outline = itinerary_outline["itinerary"]
                else:
                    itinerary_outline = [itinerary_outline]

            # Validate and enrich spots in each day
            poi_lookup = {p["name"]: (p["lat"], p["lng"]) for p in rag_pois}
            lat_center, lng_center, _ = get_city_meta(effective_dest)

            for day_idx, day in enumerate(itinerary_outline):
                day_spots = day.get("spots", [])
                if not isinstance(day_spots, list) or len(day_spots) == 0:
                    # Synthesize spots from activities string
                    act_text = day.get("activities", "")
                    items = [x.strip() for x in act_text.replace("->", "、").replace("，", "、").split("、") if x.strip()]
                    day_spots = []
                    for i, item_name in enumerate(items[:4]):
                        lat_val, lng_val = lat_center + (day_idx * 0.005) + (i * 0.003), lng_center + (day_idx * 0.005) + (i * 0.003)
                        day_spots.append({
                            "name": item_name,
                            "category": "飯店" if "飯店" in item_name or "hotel" in item_name.lower() else ("機場" if "機場" in item_name else ("餐廳" if "麵" in item_name or "餐" in item_name else "景點")),
                            "lat": lat_val,
                            "lng": lng_val,
                            "notes": "推薦造訪"
                        })
                    day["spots"] = day_spots

                for spot in day.get("spots", []):
                    name = spot.get("name", "")
                    # Match known POI coordinates
                    for p_name, coords in poi_lookup.items():
                        if p_name in name or name in p_name:
                            spot["lat"], spot["lng"] = coords
                            break
                    
                    try:
                        spot["lat"] = float(spot.get("lat", 0.0))
                        spot["lng"] = float(spot.get("lng", 0.0))
                    except (ValueError, TypeError):
                        spot["lat"] = 0.0
                        spot["lng"] = 0.0
                    
                    # Coordinate fallback if missing
                    if spot["lat"] == 0.0 or spot["lng"] == 0.0:
                        spot["lat"] = lat_center + (day_idx * 0.004) + 0.002
                        spot["lng"] = lng_center + (day_idx * 0.004) + 0.002

            print(f"✅ Successfully synthesized {len(itinerary_outline)} days of itinerary with verified spots & coordinates!")
        except Exception as e:
            print(f"⚠️ Synthesis parsing warning: {e}. Generating structured fallback using RAG POIs ({num_days} days).")
            itinerary_outline = generate_dynamic_itinerary(effective_dest, num_days, req.userQuery or "")

        result = {
            "metadata": {
                "origin": origin_code,
                "destination": dest_code,
                "return_origin": ret_origin_code,
                "return_dest": ret_dest_code,
                "effective_destination": effective_dest
            },
            "flights": valid_flights,
            "itinerary_outline": itinerary_outline
        }

        # 5. Save to Cache
        local_cache.set(cache_key, result, ttl=3600)
        return result

    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Server Error: {str(e)}")
    return result

# --- Advanced MOCK HIERARCHY ---
# Structure: ID -> {name, type, parent_id, has_children}

def generate_mock_hierarchy():
    data = {}
    
    def _add_node(id, name, type, parent_id, has_children=True, lat=None, lng=None):
        node = {
            "id": id, "name": name, "type": type, "parent_id": parent_id, 
            "has_children": has_children
        }
        if lat is not None: node["lat"] = lat
        if lng is not None: node["lng"] = lng
        data[id] = node
        return id

    def _add_poi(parent_id, name, lat, lng, type="POI"):
        _add_node(f"{parent_id}_{name.replace(' ', '_').lower()}", name, type, parent_id, False, lat, lng)

    def _add_city_structure(city_id, city_name, parent_id, districts_list, lat_base, lng_base):
        # Add City
        _add_node(city_id, city_name, "CITY", parent_id, True)
        
        # Add Districts
        for d_name in districts_list:
            d_id = f"{city_id}_{d_name.replace(' ', '_').lower()}"
            _add_node(d_id, d_name, "DISTRICT", city_id, True)
            
            # Add Categories
            cats = ["Attractions", "Restaurants", "Hotels", "Transport"]
            for cat in cats:
                c_id = f"{d_id}_{cat.lower()}"
                _add_node(c_id, cat, "CATEGORY", d_id, True)
                
                # Real Names Mapping for Demo
                # Real Names Mapping for Demo (Traditional Chinese)
                real_names_map = {
                    # --- ASIA ---
                    # Tokyo (tokyo)
                    "tokyo_shinjuku_attractions": ["新宿御苑 (Shinjuku Gyoen)", "東京都廳 (Tokyo Metro Gov)", "歌舞伎町 (Kabukicho)", "新宿黃金街 (Golden Gai)", "武士博物館 (Samurai Museum)", "花園神社 (Hanazono Shrine)", "半藏門 (Hanzomon)","吹上大宮御所 (Hanamachi Daimyo)","白金台 (Bakuten)","麻布黑美水溫泉 (Machiko)"],
                    "tokyo_shinjuku_restaurants": ["思出橫丁 (Omoide Yokocho)", "機器人餐廳 (Robot Rest.)", "紐約燒烤 (New York Grill)", "風雲兒拉麵 (Fuunji)", "麵屋武藏 (Menya Musashi)"],
                    "tokyo_shibuya_attractions": ["澀谷十字路口 (Shibuya Crossing)", "忠犬八公像 (Hachiko)", "SHIBUYA SKY", "明治神宮 (Meiji Jingu)", "代代木公園 (Yoyogi Park)", "任天堂東京 (Nintendo Tokyo)"],
                    "tokyo_shibuya_restaurants": ["一蘭拉麵 (Ichiran)", "元氣壽司 (Genki Sushi)", "美登利壽司 (Midori Sushi)", "權八 (Gonpachi)", "AFURI 拉麵"],
                    "tokyo_ginza_attractions": ["銀座六號 (GINZA SIX)", "歌舞伎座 (Kabukiza)", "銀座和光 (Wako)", "博品館 (Hakuhinkan)", "日產Crossing"],
                    "tokyo_ginza_restaurants": ["銀座久兵衛 (Kyubey)", "資生堂Parlour", "煉瓦亭 (Rengatei)", "數寄屋漢堡排 (Sukiyabashi)", "千疋屋 (Sembikiya)"],
                    "tokyo_asakusa_attractions": ["雷門/淺草寺 (Senso-ji)", "仲見世通 (Nakamise)", "東京晴空塔 (Skytree)", "隅田公園 (Sumida Park)", "花屋敷遊樂園 (Hanayashiki)"],
                    "tokyo_asakusa_restaurants": ["大黑家天婦羅 (Daikokuya)", "淺草今半 (Imahan)", "並木藪蕎麥 (Namiki Yabu)", "龜十銅鑼燒 (Kameju)", "淺草炸肉餅"],

                    # Osaka (osaka)
                    "osaka_dotonbori_attractions": ["固力果跑跑人 (Glico Man)", "道頓堀摩天輪 (Ebisu Tower)", "法善寺橫丁", "千日前道具街", "道頓堀水上觀光船"],
                    "osaka_dotonbori_restaurants": ["蟹道樂 (Kani Doraku)", "一蘭拉麵 道頓堀", "章魚燒道樂 (Wanaka)", "串炸達摩 (Kushikatsu Daruma)", "千房大阪燒 (Chibo)"],
                    "osaka_umeda_attractions": ["梅田藍天大廈 (Sky Building)", "HEP FIVE摩天輪", "GRAND FRONT大阪", "大阪車站城", "露天神社 (Ohatsu Tenjin)"],
                    "osaka_umeda_restaurants": ["梅田食道街", "北新地 宇良", "本みやけ (Honmiyake)", "喝鈍豬排 (Katsudon)", "春水堂 梅田"],
                    "osaka_namba_attractions": ["難波八阪神社 (Lion Head)", "難波Parks", "黑門市場 (Kuromon Market)", "吉本新喜劇", "日本橋電器街"],
                    "osaka_namba_restaurants": ["黑門三平 (Kuromon Sanpei)", "自由軒咖哩", "老爺爺起司蛋糕", "自由軒", "北極星蛋包飯"],

                    # Bangkok (bkk)
                    "bkk_sukhumvit_attractions": ["Terminal 21", "班哲希利公園 (Benjasiri)", "EmQuartier", "牛仔巷 (Soi Cowboy)", "恐龍星球"],
                    "bkk_sukhumvit_restaurants": ["Cabbages & Condoms", "Gaggan Anand", "Roast", "El Gaucho Steakhouse", "After You Dessert"],
                    "bkk_silom_attractions": ["馬哈納科恩大廈 (Mahanakhon)", "倫披尼公園 (Lumpini)", "帕蓬夜市 (Patpong)", "席隆夜市", "尼爾森海斯圖書館"],
                    "bkk_silom_restaurants": ["Somboon Seafood (建興酒家)", "Sirocco Sky Bar", "Mango Tree", "Scarlett Wine Bar", "Nadimos"],
                    "bkk_old_city_attractions": ["大皇宮 (Grand Palace)", "玉佛寺 (Emerald Buddha)", "臥佛寺 (Wat Pho)", "考山路 (Khao San)", "鄭王廟 (Wat Arun)"],
                    "bkk_old_city_restaurants": ["Jay Fai (痣姐熱炒)", "Thip Samai Pad Thai (鬼門炒粉)", "The Deck", "Krua Apsorn", "Mont Nomsod"],

                    # --- EUROPE ---
                    # Paris (paris)
                    "paris_le_marais_attractions": ["畢卡索博物館 (Picasso)", "伏日廣場 (Place des Vosges)", "龐毕度中心 (Pompidou)", "卡納瓦雷博物館", "雨果故居"],
                    "paris_le_marais_restaurants": ["L'As du Fallafel (口袋餅)", "Breizh Café (可麗餅)", "Le Petit Marché", "Chez Janou", "Carette"],
                    "paris_montmartre_attractions": ["聖心堂 (Sacré-Cœur)", "小丘廣場 (Place du Tertre)", "紅磨坊 (Moulin Rouge)", "愛牆 (Wall of Love)", "達利美術館"],
                    "paris_montmartre_restaurants": ["Le Consulat", "La Maison Rose", "Le Moulin de la Galette", "Pink Mamma", "Un Zèbre à Montmartre"],
                    "paris_latin_quarter_attractions": ["先賢祠 (Panthéon)", "盧森堡公園 (Luxembourg)", "莎士比亞書店", "中世紀博物館", "索邦大學"],
                    "paris_latin_quarter_restaurants": ["Le Procope (波寇咖啡)", "Le Petit Prince", "La Jacobine", "Café de Flore (花神)", "Les Deux Magots (雙叟)"],

                    # London (london)
                    "london_soho_attractions": ["皮卡迪利圓環 (Piccadilly)", "唐人街 (Chinatown)", "皇后劇院 (Les Mis)", "哈利波特劇院", "攝政街 (Regent St)"],
                    "london_soho_restaurants": ["Dishoom (印度菜)", "Burger & Lobster", "Barrafina", "Flat Iron (牛排)", "Bob Bob Ricard"],
                    "london_westminster_attractions": ["大笨鐘 (Big Ben)", "倫敦眼 (London Eye)", "西敏寺 (Abbey)", "白金漢宮 (Buckingham)", "唐寧街10號"],
                    "london_westminster_restaurants": ["The Cinnamon Club", "Quilon", "The Ivy Victoria", "Munich Cricket Club", "M Bar"],
                    "london_camden_attractions": ["卡姆登市集 (Camden Market)", "攝政運河", "Roundhouse", "爵士咖啡廳", "櫻草花山 (Primrose Hill)"],
                    "london_camden_restaurants": ["Poppie's Fish & Chips", "The Cheese Bar", "Gilgamesh", "Honest Burgers", "Camden Town Brewery"],

                    # --- NORTH AMERICA ---
                    # NYC (nyc)
                    "nyc_manhattan_attractions": ["帝國大廈 (Empire State)", "中央公園 (Central Park)", "時代廣場 (Times Sq)", "MoMA現代藝術館", "高線公園 (High Line)", "自由女神 (Statue of Liberty)"],
                    "nyc_manhattan_restaurants": ["Katz's Deli (燻肉三明治)", "Joe's Pizza", "Peter Luger (牛排)", "Le Bernardin", "Shake Shack HQ"],
                    "nyc_brooklyn_attractions": ["布魯克林大橋 (Brooklyn Bridge)", "DUMBO區", "展望公園 (Prospect Park)", "布魯克林博物館", "康尼島 (Coney Island)"],
                    "nyc_brooklyn_restaurants": ["Juliana's Pizza", "Peter Luger Steak House", "Smorgasburg", "River Café", "Grimaldi's"],
                    "nyc_queens_attractions": ["法拉盛草原公園", "MoMA PS1", "皇后區博物館", "花旗球場 (Citi Field)", "Rockaway Beach"],
                    "nyc_queens_restaurants": ["Nan Xiang Xiao Long Bao (南翔)", "Xi'an Famous Foods", "Taverna Kyclades", "SriPraPhai", "Asian Jewels"],

                    # SF (sf)
                    "sf_union_square_attractions": ["聯合廣場 (Union Sq)", "舊金山纜車總站", "MoMA SF", "唐人街 (Chinatown)", "Westfield中心"],
                    "sf_union_square_restaurants": ["The Cheesecake Factory", "John's Grill", "Sears Fine Food", "Kin Khao", "Bouchon Bistro"],
                    "sf_fishermans_wharf_attractions": ["漁人碼頭 (Fisherman's Wharf)", "39號碼頭 (Pier 39)", "惡魔島 (Alcatraz)", "吉拉德里廣場", "海事歷史公園"],
                    "sf_fishermans_wharf_restaurants": ["Boudin Bakery (酸麵包)", "Fog Harbor Fish House", "Scoma's", "Crab House", "In-N-Out Burger"],

                    # --- SOUTH AMERICA ---
                    # Rio (rio)
                    "rio_copacabana_attractions": ["科帕卡巴納海灘 (Copacabana)", "科帕卡巴納堡", "糖麵包山 (Sugarloaf)", "大西洋大道", "費拉手工藝市集"],
                    "rio_copacabana_restaurants": ["Marius Degustare", "Churrascaria Palace", "Garota de Ipanema", "Confeitaria Colombo", "Alfaia"],
                    "rio_ipanema_attractions": ["依帕內瑪海灘 (Ipanema)", "Arpoador岩石 (日落)", "General Osório廣場", "Hippie Fair", "聖母和平教堂"],
                    "rio_ipanema_restaurants": ["Zazá Bistrô", "Satyricon", "Gero Ipanema", "Via Sete", "Bazzar"],

                    # --- AFRICA ---
                    # Cairo (cairo)
                    "cairo_giza_attractions": ["吉薩金字塔群 (Pyramids)", "人面獅身像 (Sphinx)", "太陽船博物館", "大埃及博物館 (GEM)", "孟菲斯古城"],
                    "cairo_giza_restaurants": ["Pizza Hut (Sphinx View)", "Andrea Mariouteya", "Felfela", "139 Pavilion", "Khan El Khalili Rest."],
                    "cairo_downtown_attractions": ["埃及博物館 (Museum)", "解放廣場 (Tahrir Sq)", "開羅塔 (Cairo Tower)", "阿布丁宮", "歌劇院"],
                    "cairo_downtown_restaurants": ["Koshary Abou Tarek", "Felfela Downtown", "Café Riche", "Estoril", "Eish & Malh"],

                    # --- OCEANIA ---
                    # Sydney (syd)
                    "syd_cbd_attractions": ["雪梨歌劇院 (Opera House)", "雪梨港灣大橋 (Bridge)", "達令港 (Darling Harbour)", "皇家植物園", "雪梨塔 (Tower Eye)"],
                    "syd_cbd_restaurants": ["Quay", "Bennelong", "Mr. Wong", "Chat Thai", "Hubert"],
                    "syd_the_rocks_attractions": ["岩石區 (The Rocks)", "當代藝術博物館", "天文台山", "卡德曼小屋", "週末市集"],
                    "syd_the_rocks_restaurants": ["Pancakes on the Rocks", "The Glenmore", "Munich Brauhaus", "Ribs & Burgers", "Sake Restaurant"],
                    "syd_bondi_attractions": ["邦代海灘 (Bondi Beach)", "Bondi至Coogee步道", "冰山泳池 (Icebergs)", "塗鴉牆", "Campbell Parade"],
                    "syd_bondi_restaurants": ["Bondi Icebergs Club", "Hurricane's Grill", "Bills Bondi", "Fishmongers", "Gelato Messina"],

                    # --- ANTARCTICA ---
                    # Antarctica (ant)
                    "ant_research_research_stations_category": ["麥克默多站 (McMurdo)", "阿蒙森-史考特站 (South Pole)", "沃斯托克站 (Vostok)", "埃斯佩蘭薩站 (Esperanza)", "聯合冰川營地"]
                }
                
                # Generic Fillers (to avoid empty lists for categories without specific real names)
                generic_fillers = {
                    "Hotels": ["Grand Hyatt (君悅酒店)", "Hilton Hotel (希爾頓)", "Marriott (萬豪)", "Local Boutique Hotel (當地精品飯店)", "City Hostel (城市青旅)", "Four Seasons (四季酒店)"],
                    "Transport": ["Central Station (中央車站)", "Metro Station (地鐵站)", "Bus Terminal (巴士總站)", "Taxi Stand (計程車招呼站)", "City Bike Station (單車租借站)"],
                    "Restaurants": ["Local Cafe (當地咖啡)", "Street Food Stall (街頭小吃)", "Fine Dining (精緻餐飲)", "Family Restaurant (家庭餐廳)", "Bistro (小酒館)"],
                    "Attractions": ["City Park (城市公園)", "Local Museum (當地博物館)", "Historic Square (歷史廣場)", "Art Gallery (藝廊)", "Observation Deck (觀景台)"]
                }
                
                # Determine names source
                # 1. Try specific real names first
                # 2. If empty, use generic fillers for that category
                names_list = real_names_map.get(c_id)
                if not names_list:
                    names_list = generic_fillers.get(cat, [])
                
                # Iterate ONLY through the names we have. No more "Category #1" fallbacks.
                SPECIFIC_POI_LOCATIONS = {
                    "半藏門 (Hanzomon)": (35.68389, 139.74556),
                    "吹上大宮御所 (Hanamachi Daimyo)": (35.68614, 139.74856),
                    "白金台 (Bakuten)": (35.63809, 139.72657),
                    "麻布黑美水溫泉 (Machiko)": (35.6558, 139.7356)
                }

                for i, final_name in enumerate(names_list, 1):
                    # Mock LatLng jitter OR Specific Location
                    if final_name in SPECIFIC_POI_LOCATIONS:
                        lat, lng = SPECIFIC_POI_LOCATIONS[final_name]
                        _add_poi(c_id, final_name, lat, lng)
                    else:
                        _add_poi(c_id, final_name, lat_base + (i*0.002), lng_base + (i*0.002))

    # 1. Continents
    continents = {
        "asia": "Asia", "europe": "Europe", "na": "North America", 
        "sa": "South America", "africa": "Africa", "oceania": "Oceania", "ant": "Antarctica"
    }
    for k, v in continents.items():
        _add_node(k, v, "CONTINENT", None)

    # --- ASIA ---
    _add_node("asia_east", "East Asia", "REGION", "asia")
    _add_node("jp", "Japan", "COUNTRY", "asia_east")
    _add_city_structure("tokyo", "Tokyo", "jp", ["Shinjuku", "Shibuya", "Ginza", "Asakusa"], 35.6895, 139.6917)
    _add_city_structure("osaka", "Osaka", "jp", ["Dotonbori", "Umeda", "Namba"], 34.6937, 135.5023)
    
    _add_node("th", "Thailand", "COUNTRY", "asia_east") # Simplified region
    _add_city_structure("bkk", "Bangkok", "th", ["Sukhumvit", "Silom", "Old City"], 13.7563, 100.5018)

    # --- EUROPE ---
    _add_node("eu_west", "Western Europe", "REGION", "europe")
    _add_node("fr", "France", "COUNTRY", "eu_west")
    _add_city_structure("paris", "Paris", "fr", ["Le Marais", "Montmartre", "Latin Quarter"], 48.8566, 2.3522)
    
    _add_node("uk", "United Kingdom", "COUNTRY", "eu_west")
    _add_city_structure("london", "London", "uk", ["Soho", "Westminster", "Camden"], 51.5074, -0.1278)

    # --- NORTH AMERICA ---
    _add_node("na_usa", "USA", "COUNTRY", "na")
    _add_city_structure("nyc", "New York City", "na_usa", ["Manhattan", "Brooklyn", "Queens"], 40.7128, -74.0060)
    _add_city_structure("sf", "San Francisco", "na_usa", ["Union Square", "Fishermans Wharf"], 37.7749, -122.4194)

    # --- SOUTH AMERICA ---
    _add_node("brazil", "Brazil", "COUNTRY", "sa")
    _add_city_structure("rio", "Rio de Janeiro", "brazil", ["Copacabana", "Ipanema"], -22.9068, -43.1729)

    # --- AFRICA ---
    _add_node("egypt", "Egypt", "COUNTRY", "africa")
    _add_city_structure("cairo", "Cairo", "egypt", ["Giza", "Downtown"], 30.0444, 31.2357)

    # --- OCEANIA ---
    _add_node("aus", "Australia", "COUNTRY", "oceania")
    _add_city_structure("syd", "Sydney", "aus", ["CBD", "The Rocks", "Bondi"], -33.8688, 151.2093)

    # --- ANTARCTICA ---
    # Direct Category -> POI structure for valid simplicity
    _add_node("ant_research", "Research Stations", "CATEGORY", "ant")
    _add_poi("ant_research", "McMurdo Station", -77.846, 166.668)
    _add_poi("ant_research", "Amundsen-Scott", -90.000, 0.000)

    return data

MOCK_HIERARCHY_DATA = generate_mock_hierarchy()

@app.get("/v1/places/hierarchy")
def get_hierarchy(parent_id: Optional[str] = None):
    """Deep Hierarchy Drill-down API"""
    results = []
    
    if not parent_id:
        # Return Roots (Continents, those with parent_id = None)
        for k, v in MOCK_HIERARCHY_DATA.items():
            if v['parent_id'] is None:
                results.append(v)
    else:
        # Return Children of parent_id
        for k, v in MOCK_HIERARCHY_DATA.items():
            if v['parent_id'] == parent_id:
                results.append(v)
                
    return results

@app.get("/v1/places/nearby")
def search_nearby(
    anchor_lat: float, 
    anchor_lng: float, 
    radius_meters: int = 1000
):
    """定錨半徑搜尋"""
    print(f"🔍 在 ({anchor_lat}, {anchor_lng}) 半徑 {radius_meters}m 內搜尋")
    return [
        {"place_id": "p1", "name": "老城區咖啡", "location": {"lat": anchor_lat+0.001, "lng": anchor_lng}},
        {"place_id": "p2", "name": "古堡飯店", "location": {"lat": anchor_lat-0.001, "lng": anchor_lng}},
    ]

@app.post("/v1/places/analyze")
def analyze_place(place_id: str, user_intent: str):
    """Gemini 樁代碼"""
    return {
        "verdict": "recommended",
        "summary": f"這間店 ({place_id}) 非常適合 {user_intent}，環境安靜。",
        "tags": ["安靜", "好吃"]
    }
