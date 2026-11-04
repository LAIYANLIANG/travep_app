#!/bin/bash

# ============================================================================
# Trivep App - Dedicated Flutter Web Runner (Fixed Port 53858)
# ============================================================================
# 永久將 Flutter Web 綁定在 http://localhost:53858/
# ============================================================================

set -e

PORT=53858
HOSTNAME="localhost"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "🚀 ${BLUE}啟動 Trivep Flutter Web (鎖定連接埠: ${PORT})${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 檢查連接埠是否被佔用
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    OLD_PID=$(lsof -ti:$PORT -sTCP:LISTEN | head -1)
    echo "⚠️  ${YELLOW}連接埠 $PORT 目前被程序 (PID: $OLD_PID) 佔用，正在釋放...${NC}"
    lsof -ti:$PORT -sTCP:LISTEN | xargs kill -9 2>/dev/null || true
    sleep 1
    echo "✓  ${GREEN}連接埠 $PORT 已成功釋放！${NC}"
fi

# 檢查是否有舊的動態埠 Flutter Chrome 程序殘留
OLD_FLUTTER_PID=$(ps aux | grep "[f]lutter_tools.snapshot run -d chrome" | awk '{print $2}' || true)
if [ -n "$OLD_FLUTTER_PID" ]; then
    echo "ℹ️  ${BLUE}發現殘留的舊 Flutter 執行程序 (PID: $OLD_FLUTTER_PID)，正在關閉...${NC}"
    kill -9 $OLD_FLUTTER_PID 2>/dev/null || true
fi

echo ""
echo "🌐 即將在 ${GREEN}http://${HOSTNAME}:${PORT}/${NC} 開啟 Flutter 應用程式..."
echo "💡 提示："
echo "   - AI 智慧行程規劃直達網址: ${GREEN}http://${HOSTNAME}:${PORT}/?page=11${NC}"
echo "   - 路線優化器直達網址:     ${GREEN}http://${HOSTNAME}:${PORT}/?page=9${NC}"
echo "   - 在終端機按 'r' 進行 Hot Reload，按 'R' 進行 Hot Restart"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

exec flutter run -d chrome --web-port=$PORT --web-hostname=$HOSTNAME "$@"

