import hashlib
import urllib.parse
from datetime import datetime

class ECPayService:
    def __init__(self, merchant_id: str, hash_key: str, hash_iv: str, return_url: str):
        self.merchant_id = merchant_id
        self.hash_key = hash_key
        self.hash_iv = hash_iv
        self.return_url = return_url

    def generate_check_mac_value(self, params: dict) -> str:
        """
        為 ECPay 金流產生驗證用的 CheckMacValue
        """
        # 1. 參數按字母 A-Z 排序並串接為 QueryString
        sorted_keys = sorted(params.keys())
        query_string = "&".join(f"{k}={params[k]}" for k in sorted_keys if params[k] != "")

        # 2. 前後加上 HashKey 與 HashIV
        raw_str = f"HashKey={self.hash_key}&{query_string}&HashIV={self.hash_iv}"

        # 3. 進行 URL Encode，再轉小寫
        encoded_str = urllib.parse.quote_plus(raw_str).lower()

        # 4. 因應 ECPay 特殊規則，替換掉特定字串
        encoded_str = encoded_str.replace('%2d', '-').replace('%5f', '_').replace('%2e', '.').replace('%21', '!')
        encoded_str = encoded_str.replace('%2a', '*').replace('%28', '(').replace('%29', ')')

        # 5. SHA256 雜湊，轉大寫
        mac_value = hashlib.sha256(encoded_str.encode("utf-8")).hexdigest().upper()
        return mac_value

    def create_order_form_data(self, order_id: str, amount: int, item_name: str, client_back_url: str) -> dict:
        """
        產生用於建立綠界 Form Http Post 的參數字典
        """
        params = {
            "MerchantID": self.merchant_id,
            "MerchantTradeNo": order_id,
            "MerchantTradeDate": datetime.now().strftime("%Y/%m/%d %H:%M:%S"),
            "PaymentType": "aio",
            "TotalAmount": str(amount),
            "TradeDesc": "J87 Points Top Up",
            "ItemName": item_name,
            "ReturnURL": self.return_url,
            "ChoosePayment": "Credit",
            "EncryptType": "1",
            "ClientBackURL": client_back_url, # 供消費者點擊返回 APP 的按鈕
        }

        # 計算檢查碼
        params["CheckMacValue"] = self.generate_check_mac_value(params)
        return params

    def verify_callback(self, request_form: dict) -> bool:
        """
        驗證綠界回傳的 CheckMacValue 是否正確
        """
        if "CheckMacValue" not in request_form:
            return False
            
        received_mac = request_form.pop("CheckMacValue")
        calculated_mac = self.generate_check_mac_value(request_form)
        return received_mac == calculated_mac
