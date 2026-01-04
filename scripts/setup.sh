#!/bin/bash

# CollabSphere Development Environment Setup Script
# This script sets up the entire development environment

set -e  # Exit on any error

echo "CollabSphere Development Setup"
echo "================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
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

# Check if we're in the right directory
if [ ! -f "package.json" ] || [ ! -d "backend" ] || [ ! -d "frontend" ]; then
    print_error "Please run this script from the CollabSphere root directory"
    exit 1
fi

print_status "Starting CollabSphere setup..."

# Check system requirements
print_status "Checking system requirements..."

# Check Ruby
if ! command -v ruby &> /dev/null; then
    print_error "Ruby is not installed. Please install Ruby 3.1+ first."
    exit 1
fi

ruby_version=$(ruby -v | grep -o '[0-9]\+\.[0-9]\+' | head -1)
print_success "Ruby $ruby_version found"

# Check Rails
if ! command -v rails &> /dev/null; then
    print_warning "Rails not found. Installing Rails..."
    gem install rails
fi

rails_version=$(rails -v | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
print_success "Rails $rails_version found"

# Check Node.js
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed. Please install Node.js 16+ first."
    exit 1
fi

node_version=$(node -v)
print_success "Node.js $node_version found"

# Check npm
if ! command -v npm &> /dev/null; then
    print_error "npm is not installed. Please install npm first."
    exit 1
fi

npm_version=$(npm -v)
print_success "npm $npm_version found"

# Check PostgreSQL
if ! command -v psql &> /dev/null; then
    print_warning "PostgreSQL client not found. Please ensure PostgreSQL is installed."
fi

print_status "Installing backend dependencies..."
cd backend
if [ -f "Gemfile" ]; then
    bundle install
    print_success "Backend dependencies installed"
else
    print_error "Gemfile not found in backend directory"
    exit 1
fi

print_status "Setting up database..."
if rails db:create db:migrate db:seed; then
    print_success "Database setup complete"
else
    print_warning "Database setup had issues. You may need to configure PostgreSQL manually."
fi

cd ..

print_status "Installing frontend dependencies..."
cd frontend
if [ -f "package.json" ]; then
    npm install
    print_success "Frontend dependencies installed"
else
    print_error "package.json not found in frontend directory"
    exit 1
fi

cd ..

print_status "Installing root-level dependencies..."
npm install

# Create development environment file if it doesn't exist
if [ ! -f "backend/.env.development" ]; then
    print_status "Creating development environment file..."
    cat > backend/.env.development << EOF
DATABASE_URL=postgresql://localhost:5432/collabsphere_development
REDIS_URL=redis://localhost:6379/0
JWT_SECRET_KEY=your_jwt_secret_key_here_change_in_production
RAILS_ENV=development
EOF
    print_success "Development environment file created"
fi

# Create scripts executable
chmod +x scripts/*.sh

print_success "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Start the development servers:"
echo "   npm run dev"
echo ""
echo "2. Open your browser:"
echo "   Backend API: http://localhost:3000"
echo "   Frontend: http://localhost:3001"
echo ""
echo "3. For Docker setup:"
echo "   docker-compose up"
echo ""
echo "Happy coding!"