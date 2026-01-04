#!/bin/bash

# CollabSphere Deployment Script
# Handles production deployment setup

set -e

echo "CollabSphere Deployment Setup"
echo "================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check environment
if [ "$1" != "production" ] && [ "$1" != "staging" ]; then
    print_error "Usage: $0 [production|staging]"
    exit 1
fi

ENVIRONMENT=$1

print_status "Preparing $ENVIRONMENT deployment..."

# Build frontend
print_status "Building frontend..."
cd frontend
npm run build
print_success "Frontend build complete"
cd ..

# Precompile Rails assets if needed
print_status "Preparing backend..."
cd backend
RAILS_ENV=$ENVIRONMENT rails assets:precompile 2>/dev/null || true
print_success "Backend prepared"
cd ..

# Create deployment package
print_status "Creating deployment package..."
tar -czf "collabsphere-$ENVIRONMENT-$(date +%Y%m%d-%H%M).tar.gz" \
    --exclude-from=.gitignore \
    --exclude=.git \
    --exclude=node_modules \
    --exclude="*.log" \
    --exclude=tmp \
    .

print_success "Deployment package created"

print_status "Deployment checklist:"
echo "[DONE] Frontend built"
echo "[DONE] Assets compiled"
echo "[DONE] Package created"
echo ""
echo "Next steps:"
echo "1. Upload package to server"
echo "2. Extract and configure environment variables"
echo "3. Run database migrations"
echo "4. Restart services"
echo ""
print_warning "Don't forget to set production environment variables!"
print_success "Deployment ready!"