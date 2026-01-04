#!/bin/bash

# CollabSphere User Testing Script
echo "CollabSphere User Testing Script"
echo "==================================="

BASE_URL="http://localhost:3000"
JWT_TOKEN=""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

test_pass() {
    echo -e "${GREEN}[PASS]:${NC} $1"
}

test_fail() {
    echo -e "${RED}[FAIL]:${NC} $1"
}

test_info() {
    echo -e "${BLUE}[INFO]:${NC} $1"
}

# Test 1: User Registration
echo ""
test_info "Testing user registration..."
REGISTER_RESPONSE=$(curl -s -X POST $BASE_URL/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "full_name": "Test User API",
      "email": "testuser@api.com",
      "password": "password123",
      "password_confirmation": "password123",
      "country": "USA",
      "bio": "API Testing User"
    }
  }')

if echo "$REGISTER_RESPONSE" | grep -q "token"; then
    test_pass "User registration successful"
    JWT_TOKEN=$(echo "$REGISTER_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['token'])")
else
    test_fail "User registration failed: $REGISTER_RESPONSE"
    # Try login instead
    echo ""
    test_info "Trying to login with existing user..."
    LOGIN_RESPONSE=$(curl -s -X POST $BASE_URL/auth/login \
      -H "Content-Type: application/json" \
      -d '{
        "email": "test@example.com",
        "password": "password123"
      }')
    
    if echo "$LOGIN_RESPONSE" | grep -q "token"; then
        test_pass "User login successful"
        JWT_TOKEN=$(echo "$LOGIN_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['token'])")
    else
        test_fail "Both registration and login failed"
        exit 1
    fi
fi

# Test 2: Create Project
echo ""
test_info "Testing project creation..."
PROJECT_RESPONSE=$(curl -s -X POST $BASE_URL/api/v1/projects \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "project": {
      "title": "API Test Project",
      "description": "Testing project creation via API script",
      "status": "Ideation",
      "visibility": "public"
    }
  }')

if echo "$PROJECT_RESPONSE" | grep -q "id"; then
    test_pass "Project creation successful"
    PROJECT_ID=$(echo "$PROJECT_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])")
else
    test_fail "Project creation failed: $PROJECT_RESPONSE"
    PROJECT_ID=1  # Use existing project
fi

# Test 3: List Projects
echo ""
test_info "Testing project listing..."
PROJECTS_RESPONSE=$(curl -s -X GET $BASE_URL/api/v1/projects \
  -H "Authorization: Bearer $JWT_TOKEN")

if echo "$PROJECTS_RESPONSE" | grep -q "title"; then
    test_pass "Project listing successful"
    PROJECT_COUNT=$(echo "$PROJECTS_RESPONSE" | python3 -c "import sys, json; print(len(json.load(sys.stdin)))")
    test_info "Found $PROJECT_COUNT projects"
else
    test_fail "Project listing failed"
fi

# Test 4: Add Comment
echo ""
test_info "Testing comment creation..."
COMMENT_RESPONSE=$(curl -s -X POST $BASE_URL/api/v1/projects/$PROJECT_ID/comments \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "comment": {
      "content": "This is an automated test comment!"
    }
  }')

if echo "$COMMENT_RESPONSE" | grep -q "content"; then
    test_pass "Comment creation successful"
else
    test_fail "Comment creation failed: $COMMENT_RESPONSE"
fi

# Test 5: Vote on Project
echo ""
test_info "Testing project voting..."
VOTE_RESPONSE=$(curl -s -X POST $BASE_URL/api/v1/projects/$PROJECT_ID/vote \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"vote_type": "up"}')

if echo "$VOTE_RESPONSE" | grep -q "message"; then
    test_pass "Project voting successful"
else
    test_fail "Project voting failed: $VOTE_RESPONSE"
fi

# Test 6: Get Project Details
echo ""
test_info "Testing project details retrieval..."
PROJECT_DETAIL_RESPONSE=$(curl -s -X GET $BASE_URL/api/v1/projects/$PROJECT_ID \
  -H "Authorization: Bearer $JWT_TOKEN")

if echo "$PROJECT_DETAIL_RESPONSE" | grep -q "title"; then
    test_pass "Project details retrieval successful"
else
    test_fail "Project details retrieval failed"
fi

# Test 7: Test Invalid Authentication
echo ""
test_info "Testing invalid authentication..."
INVALID_AUTH_RESPONSE=$(curl -s -X POST $BASE_URL/api/v1/projects \
  -H "Authorization: Bearer invalid_token" \
  -H "Content-Type: application/json" \
  -d '{"project": {"title": "Should Fail"}}')

if echo "$INVALID_AUTH_RESPONSE" | grep -q "error\|Unauthorized"; then
    test_pass "Invalid authentication properly rejected"
else
    test_fail "Invalid authentication should have been rejected"
fi

echo ""
echo "Testing Summary:"
echo "==================="
test_info "All core functionality has been tested"
test_info "Backend API: http://localhost:3000"
test_info "Frontend App: http://localhost:3001"
echo ""
test_info "Manual Frontend Testing Checklist:"
echo "   □ Open http://localhost:3001 in browser"
echo "   □ Test user registration form"
echo "   □ Test login functionality"
echo "   □ Test project creation interface"
echo "   □ Test project listing and filtering"
echo "   □ Test commenting system"
echo "   □ Test voting buttons"
echo "   □ Test user profile management"
echo ""
echo "Happy testing!"