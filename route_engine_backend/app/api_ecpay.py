from fastapi import APIRouter, Request, Form, HTTPException
from pydantic import BaseModel
from typing import Dict, Any
from .ecpay_service import ECPayService
import os

router = APIRouter()

# Mock settings. For production, these should be from env vars.
# These are ECPay's stage testing credentials
MERCHANT_ID = os.getenv("ECPAY_MERCHANT_ID", "2000132")
HASH_KEY = os.getenv("ECPAY_HASH_KEY", "5294y06JbISpM5x9")
HASH_IV = os.getenv("ECPAY_HASH_IV", "v77hoKGq4kWxNNIS")
RETURN_URL = os.getenv("ECPAY_RETURN_URL", "https://your-ngrok-url/api/ecpay/callback")

ecpay_service = ECPayService(
    merchant_id=MERCHANT_ID,
    hash_key=HASH_KEY,
    hash_iv=HASH_IV,
    return_url=RETURN_URL
)

class OrderRequest(BaseModel):
    user_id: str
    amount: int
    points: int

@router.post("/create-order")
def create_order(req: OrderRequest):
    """
    提供給 Flutter 前端:
    建立訂單參數，包含 CheckMacValue，讓前端可以用這些 Form Data 建立 WebView 導向綠界。
    """
    import uuid
    # 產生唯一的訂單編號 (綠界規定限 20 碼以內)
    order_id = f"J87{uuid.uuid4().hex[:16]}".upper()
    
    # 建立 Form 表單資料
    form_data = ecpay_service.create_order_form_data(
        order_id=order_id,
        amount=req.amount,
        item_name=f"J87 Points - {req.points} Pts",
        client_back_url="https://j87.org/payment/success" # 前端跳回的自訂網址
    )
    
    # 在真實環境中，此時應該把 order_id 與 user_id 寫進 Firestore "pending_orders" collection
    # ...
    
    return {
        "status": "success",
        "order_id": order_id,
        "ecpay_url": "https://payment-stage.ecpay.com.tw/Cashier/AioCheckOut/V5",
        "form_data": form_data
    }

@router.post("/callback")
async def ecpay_callback(request: Request):
    """
    綠界在使用者付款成功後，會在背景呼叫此 API (Server-to-Server)
    """
    # 綠界的 callback 是 application/x-www-form-urlencoded
    form_data = await request.form()
    data_dict = dict(form_data)
    
    # 1. 驗證 CheckMacValue
    is_valid = ecpay_service.verify_callback(data_dict.copy())
    
    if not is_valid:
        print(f"❌ ECPay Callback Signature Verification Failed! TradeNo: {data_dict.get('MerchantTradeNo')}")
        # 若失敗，依舊回傳 0|Error 給綠界
        from fastapi.responses import PlainTextResponse
        return PlainTextResponse("0|ErrorMessage")

    # 2. 判斷付款狀態 (RtnCode == 1 代表成功)
    rtn_code = data_dict.get("RtnCode")
    if str(rtn_code) == "1":
        # 成功付款，根據 MerchantTradeNo 去 Firestore "pending_orders" 撈出對應的 user_id
        # 然後將 points 加入 user_id 下方的 points 欄位
        print(f"✅ Payment Success! TradeNo: {data_dict.get('MerchantTradeNo')}, Amount: {data_dict.get('TradeAmt')}")
        # update_firebase_user_points(...)
        
        # 必須回傳 1|OK 給綠界，否則他們會一直重試
        from fastapi.responses import PlainTextResponse
        return PlainTextResponse("1|OK")
    else:
        print(f"⚠️ Payment Failed/Other Status: {rtn_code}")
        from fastapi.responses import PlainTextResponse
        return PlainTextResponse("1|OK")
