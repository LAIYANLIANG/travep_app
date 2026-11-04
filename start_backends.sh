#!/bin/bash

# Start Backend Services Only (for testing)

echo "🔧 Starting Backend Services Only..."

PROJECT_DIR=$(pwd)

# 1. Start Route Engine Backend (Port 8080)
echo "   Starting Route Engine Backend on port 8080..."
osascript -e "tell application \"Terminal\" to do script \"cd '$PROJECT_DIR/route_engine_backend' && ./venv/bin/uvicorn app.main:app --reload --port 8080\""

# 2. Start Itinerary Backend (Port 8000)
echo ""
echo "✅ Backend services started in separate Terminal windows"
echo "   - Route Engine API: http://127.0.0.1:8080/docs"
