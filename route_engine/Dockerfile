# 使用官方輕量級 Python 映像檔
FROM python:3.10-slim

# 設定工作目錄
WORKDIR /app

# 1. 先複製依賴檔並安裝 (利用 Docker Cache 加速)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 2. 複製程式碼
COPY . .

# 3. 注入 Cloud Run 預設 Port 環境變數
ENV PORT=8080

# 4. 啟動命令 (符合 Cloud Run 要求)
CMD exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT}
