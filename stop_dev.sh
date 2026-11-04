#!/bin/bash

# ============================================================================
# Trivep App - Quick Stop Script
# Stops all running services (backends, Astro, Flutter)
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "🛑 ${RED}Stopping all Trivep services...${NC}"
echo ""

stop_port() {
    local port=$1
    local service=$2

    if lsof -ti:$port -sTCP:LISTEN >/dev/null 2>&1 ; then
        lsof -ti:$port -sTCP:LISTEN | xargs kill 2>/dev/null || true
        echo "   ${GREEN}✓${NC} $service (port $port) stopped"
    else
        echo "   ${YELLOW}-${NC} $service (port $port) was not running"
    fi
}

# Stop each service by port
stop_port 8080 "Route Engine Backend"
stop_port 8000 "Itinerary Backend"
stop_port 4321 "Astro Frontend"
stop_port 53858 "Flutter Web"

# Kill any remaining uvicorn processes from this project
pkill -f "uvicorn.*route_engine_backend" 2>/dev/null || true
pkill -f "uvicorn.*backend/main"         2>/dev/null || true
pkill -f "flutter.*53858"                2>/dev/null || true

echo ""
echo "${GREEN}✅ All Trivep services stopped${NC}"
echo "💡 Restart with: ${YELLOW}./start_dev.sh${NC}"
echo ""
