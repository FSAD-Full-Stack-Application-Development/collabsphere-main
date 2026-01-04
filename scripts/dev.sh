#!/bin/bash

# CollabSphere Development Server Script
# Starts both backend and frontend in development mode

set -e

echo "Starting CollabSphere Development Servers"
echo "==========================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "package.json" ] || [ ! -d "backend" ] || [ ! -d "frontend" ]; then
    echo "Please run this script from the CollabSphere root directory"
    exit 1
fi

# Function to cleanup on exit
cleanup() {
    echo ""
    print_status "Shutting down servers..."
    jobs -p | xargs -r kill
    exit 0
}

trap cleanup SIGINT SIGTERM

print_status "Starting backend server (Rails)..."
cd backend
rails server &
BACKEND_PID=$!
cd ..

print_status "Starting frontend server (React)..."
cd frontend
PORT=3001 npm start &
FRONTEND_PID=$!
cd ..

print_success "Development servers started!"
echo ""
echo " Frontend: http://localhost:3001"
echo "Backend API: http://localhost:3000"
echo ""
echo "Press Ctrl+C to stop both servers"

# Wait for background processes
wait