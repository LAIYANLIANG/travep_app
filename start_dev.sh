#!/bin/bash

# ============================================================================
# Trivep App - Smart Startup Script with Pre-flight Checks
# ============================================================================
# 啟動順序：
#   1. Route Engine Backend (Port 8080) - Maze 探索、機票、餐廳、住宿
#   2. Itinerary Backend   (Port 8000) - 行程計算與 AI 建議
#   3. Astro Frontend       (Port 4321) - 首頁入口
#   4. Flutter App          (Chrome)    - 主應用程式
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get absolute path of current directory
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "🚀 ${BLUE}Trivep App Development Environment${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============================================================================
# 1. PRE-FLIGHT CHECKS
# ============================================================================

echo "📋 ${YELLOW}Running Pre-flight Checks...${NC}"
echo ""

# --- Check & auto-release port if occupied by same project ---
check_port() {
    local port=$1
    local service=$2
    local expected_keyword=$3  # used to identify if same project is running

    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        # Get the command line of the process holding the port
        local pid
        pid=$(lsof -ti:$port -sTCP:LISTEN | head -1)
        local cmdline
        cmdline=$(ps -p "$pid" -o args= 2>/dev/null || echo "")

        if echo "$cmdline" | grep -q "$expected_keyword" ; then
            echo "   ${YELLOW}⚠️  Port $port ($service) occupied by same project — auto-restarting${NC}"
            lsof -ti:$port -sTCP:LISTEN | xargs kill 2>/dev/null || true
            sleep 1
            echo "   ${GREEN}✓ Port $port released${NC}"
        else
            echo "   ${YELLOW}⚠️  Port $port is in use by an unknown process (PID $pid)${NC}"
            echo "   ${YELLOW}   Command: $cmdline${NC}"
            read -p "   Kill it and continue? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                lsof -ti:$port -sTCP:LISTEN | xargs kill -9 2>/dev/null || true
                sleep 1
                echo "   ${GREEN}✓ Port $port is now available${NC}"
            else
                echo "   ${RED}✗ Cannot start $service — port $port is occupied${NC}"
                return 1
            fi
        fi
    else
        echo "   ${GREEN}✓ Port $port is available ($service)${NC}"
    fi
}

echo "🔍 Checking port availability..."
check_port 8080 "Route Engine Backend" "route_engine_backend" || exit 1
check_port 8000 "Itinerary Backend"    "backend"              || exit 1
check_port 4321 "Astro Frontend"       "astro"                || exit 1
check_port 53858 "Flutter Web"         "flutter"              || exit 1
echo ""

# --- Environment Files ---
echo "🔍 Checking environment files..."

check_env_file() {
    local dir=$1
    local service=$2

    if [ ! -f "$PROJECT_DIR/$dir/.env" ]; then
        if [ -f "$PROJECT_DIR/$dir/.env.example" ]; then
            echo "   ${BLUE}Creating .env from .env.example for $service...${NC}"
            cp "$PROJECT_DIR/$dir/.env.example" "$PROJECT_DIR/$dir/.env"
            echo "   ${YELLOW}⚠️  Please edit $dir/.env and add your API keys${NC}"
        else
            echo "   ${YELLOW}⚠️  $service: no .env or .env.example — skipping${NC}"
        fi
    else
        echo "   ${GREEN}✓ $service: .env exists${NC}"
    fi
}

check_env_file "route_engine_backend" "Route Engine Backend"
check_env_file "backend"              "Itinerary Backend"
echo ""

# --- Virtual Environments (Python backends) ---
echo "🔍 Checking virtual environments..."

check_venv() {
    local dir=$1
    local service=$2

    if [ ! -d "$PROJECT_DIR/$dir/venv" ]; then
        echo "   ${YELLOW}⚠️  $service: venv not found — creating...${NC}"
        cd "$PROJECT_DIR/$dir"
        python3 -m venv venv
        ./venv/bin/pip install --upgrade pip -q
        if [ -f "requirements.txt" ]; then
            ./venv/bin/pip install -r requirements.txt -q
        fi
        cd "$PROJECT_DIR"
        echo "   ${GREEN}✓ Created venv for $service${NC}"
    else
        echo "   ${GREEN}✓ $service: venv exists${NC}"
    fi
}

check_venv "route_engine_backend" "Route Engine Backend"
check_venv "backend"              "Itinerary Backend"
echo ""

# --- Node.js (Astro) ---
echo "🔍 Checking Astro frontend dependencies..."

if command -v node &> /dev/null; then
    echo "   ${GREEN}✓ Node.js is installed$(node -v 2>/dev/null && echo " ($(node -v))")${NC}"
else
    echo "   ${RED}✗ Node.js is not installed${NC}"
    exit 1
fi

if [ ! -d "$PROJECT_DIR/j87-astro/node_modules" ]; then
    echo "   ${BLUE}Installing Astro dependencies...${NC}"
    cd "$PROJECT_DIR/j87-astro" && npm install
    cd "$PROJECT_DIR"
fi
echo "   ${GREEN}✓ Astro: node_modules exists${NC}"
echo ""

# --- Python3 ---
echo "🔍 Checking system tools..."

if command -v python3 &> /dev/null; then
    echo "   ${GREEN}✓ Python3 is installed${NC}"
else
    echo "   ${RED}✗ Python3 is not installed${NC}"
    exit 1
fi

# --- Flutter ---
if command -v flutter &> /dev/null; then
    echo "   ${GREEN}✓ Flutter is installed${NC}"
    if [ -f "$PROJECT_DIR/pubspec.yaml" ]; then
        echo "   ${BLUE}Running flutter pub get...${NC}"
        cd "$PROJECT_DIR" && flutter pub get > /dev/null 2>&1
        echo "   ${GREEN}✓ Flutter dependencies updated${NC}"
    fi
else
    echo "   ${RED}✗ Flutter is not installed${NC}"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "${GREEN}✅ All pre-flight checks passed!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============================================================================
# 2. START SERVICES (with health checks)
# ============================================================================

echo "🎬 ${BLUE}Starting Services...${NC}"
echo ""

FAIL=0

# Helper: wait for a port to become available
wait_for_port() {
    local port=$1
    local service=$2
    local max_wait=$3  # seconds

    local waited=0
    while [ $waited -lt $max_wait ]; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 ; then
            echo "   ${GREEN}✓ $service is running on port $port${NC}"
            return 0
        fi
        sleep 1
        waited=$((waited + 1))
    done
    echo "   ${RED}✗ $service failed to start on port $port (waited ${max_wait}s)${NC}"
    return 1
}

# --- 1. Route Engine Backend (Port 8080) ---
echo "   ${BLUE}[1/4]${NC} Starting Route Engine Backend (Port 8080)..."
osascript -e "tell application \"Terminal\" to do script \"cd '$PROJECT_DIR/route_engine_backend' && ./venv/bin/uvicorn app.main:app --reload --port 8080\"" > /dev/null 2>&1
wait_for_port 8080 "Route Engine Backend" 15 || FAIL=1

# --- 2. Itinerary Backend (Port 8000) ---
echo "   ${BLUE}[2/4]${NC} Starting Itinerary Backend (Port 8000)..."
osascript -e "tell application \"Terminal\" to do script \"cd '$PROJECT_DIR' && ./backend/venv/bin/uvicorn backend.main:app --reload --port 8000\"" > /dev/null 2>&1
wait_for_port 8000 "Itinerary Backend" 15 || FAIL=1

# --- 3. Astro Frontend (Port 4321) ---
echo "   ${BLUE}[3/4]${NC} Starting Astro Frontend (Port 4321)..."
osascript -e "tell application \"Terminal\" to do script \"cd '$PROJECT_DIR/j87-astro' && npm run dev\"" > /dev/null 2>&1
wait_for_port 4321 "Astro Frontend" 15 || FAIL=1

# --- 4. Flutter App (Port 53858) ---
echo "   ${BLUE}[4/4]${NC} Starting Flutter App (Chrome Port 53858)..."
osascript -e "tell application \"Terminal\" to do script \"cd '$PROJECT_DIR' && flutter run -d chrome --web-port=53858 --web-hostname=localhost\"" > /dev/null 2>&1

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $FAIL -eq 0 ]; then
    echo "${GREEN}✅ All services started successfully!${NC}"
else
    echo "${YELLOW}⚠️  Some services may have failed — check Terminal windows${NC}"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📍 ${BLUE}Service URLs:${NC}"
echo "   • Astro 首頁:         ${GREEN}http://localhost:4321/${NC}"
echo "   • Route Engine API:   ${GREEN}http://127.0.0.1:8080/docs${NC}"
echo "   • Itinerary API:      ${GREEN}http://127.0.0.1:8000/docs${NC}"
echo "   • Flutter App:        ${GREEN}http://localhost:53858/${NC}"
echo "   • AI 行程規劃直達:     ${GREEN}http://localhost:53858/?page=11${NC}"
echo ""
echo "💡 ${YELLOW}Tips:${NC}"
echo "   • Press 'r' in Flutter terminal for Hot Reload"
echo "   • Press 'R' in Flutter terminal for Hot Restart"
echo "   • To stop all services: ./stop_dev.sh"
echo ""

