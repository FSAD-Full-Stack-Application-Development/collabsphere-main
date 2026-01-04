#!/bin/bash

echo "=========================================="
echo "COMPREHENSIVE BACKEND API TEST"
echo "=========================================="

BASE_URL="http://localhost:3000/api/v1"
AUTH_URL="http://localhost:3000/auth"

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Helper function to test endpoint
test_endpoint() {
  local test_name=$1
  local method=$2
  local url=$3
  local headers=$4
  local data=$5
  local expected_status=$6
  
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  
  echo -e "\n${BLUE}Test ${TOTAL_TESTS}: ${test_name}${NC}"
  
  if [ -z "$data" ]; then
    response=$(curl -s -w "\n%{http_code}" -X $method "$url" $headers)
  else
    response=$(curl -s -w "\n%{http_code}" -X $method "$url" $headers -d "$data")
  fi
  
  http_code=$(echo "$response" | tail -n 1)
  body=$(echo "$response" | head -n -1)
  
  if [ "$http_code" == "$expected_status" ]; then
    echo -e "${GREEN}✓ PASSED${NC} - Status: $http_code"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    echo -e "${RED}✗ FAILED${NC} - Expected: $expected_status, Got: $http_code"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo "Response: $body" | python3 -m json.tool 2>/dev/null || echo "$body"
  fi
}

# ==========================================
# 1. AUTHENTICATION TESTS
# ==========================================
echo -e "\n${BLUE}========== 1. AUTHENTICATION TESTS ==========${NC}"

# Test 1.1: Register new user
test_endpoint \
  "Register new user" \
  "POST" \
  "$AUTH_URL/register" \
  "-H 'Content-Type: application/json'" \
  '{
    "user": {
      "email": "testuser@backend.test",
      "password": "password123",
      "full_name": "Test User Backend",
      "country": "Thailand",
      "university": "Asian Institute of Technology"
    }
  }' \
  "201"

# Test 1.2: Login with valid credentials
echo -e "\n${BLUE}Logging in to get JWT token...${NC}"
LOGIN_RESPONSE=$(curl -s -X POST $AUTH_URL/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "araya.student@collabsphere.com",
    "password": "password123"
  }')

TOKEN=$(echo $LOGIN_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin).get('token', ''))")

if [ -z "$TOKEN" ]; then
  echo -e "${RED}✗ Login failed - Cannot continue with authenticated tests${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Login successful${NC}"
AUTH_HEADER="-H 'Authorization: Bearer $TOKEN'"

# Test 1.3: Login with invalid credentials
test_endpoint \
  "Login with invalid password" \
  "POST" \
  "$AUTH_URL/login" \
  "-H 'Content-Type: application/json'" \
  '{
    "email": "araya.student@collabsphere.com",
    "password": "wrongpassword"
  }' \
  "401"

# ==========================================
# 2. USER/PROFILE TESTS
# ==========================================
echo -e "\n${BLUE}========== 2. USER & PROFILE TESTS ==========${NC}"

# Test 2.1: Get user profile
test_endpoint \
  "Get user profile by ID" \
  "GET" \
  "$BASE_URL/profiles/4cb4cc14-f65b-4246-bc2a-588dde052331" \
  "$AUTH_HEADER" \
  "" \
  "200"

# Test 2.2: Get current user profile
test_endpoint \
  "Get current user profile (/users/me)" \
  "GET" \
  "$BASE_URL/users/me" \
  "$AUTH_HEADER" \
  "" \
  "200"

# Test 2.3: Update user profile
test_endpoint \
  "Update user profile" \
  "PATCH" \
  "$BASE_URL/users/4cb4cc14-f65b-4246-bc2a-588dde052331" \
  "$AUTH_HEADER -H 'Content-Type: application/json'" \
  '{
    "user": {
      "bio": "Updated bio for testing"
    }
  }' \
  "200"

# Test 2.4: List all users
test_endpoint \
  "List all users" \
  "GET" \
  "$BASE_URL/users?per_page=5" \
  "$AUTH_HEADER" \
  "" \
  "200"

# Test 2.5: Autocomplete universities
test_endpoint \
  "Autocomplete universities" \
  "GET" \
  "$BASE_URL/users/autocomplete/universities?term=Asian" \
  "$AUTH_HEADER" \
  "" \
  "200"

# Test 2.6: Autocomplete countries
test_endpoint \
  "Autocomplete countries" \
  "GET" \
  "$BASE_URL/users/autocomplete/countries?term=Thai" \
  "$AUTH_HEADER" \
  "" \
  "200"

# ==========================================
# 3. PROJECT TESTS
# ==========================================
echo -e "\n${BLUE}========== 3. PROJECT TESTS ==========${NC}"

# Test 3.1: Create project
echo -e "\n${BLUE}Creating test project...${NC}"
PROJECT_RESPONSE=$(curl -s -X POST "$BASE_URL/projects" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "project": {
      "title": "Backend Test Project",
      "description": "Testing project creation",
      "category": "Web Development",
      "status": "active"
    }
  }')

PROJECT_ID=$(echo $PROJECT_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin).get('id', ''))" 2>/dev/null)

if [ -z "$PROJECT_ID" ]; then
  echo -e "${RED}✗ Failed to create project${NC}"
else
  echo -e "${GREEN}✓ Project created: $PROJECT_ID${NC}"
  PASSED_TESTS=$((PASSED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Test 3.2: List projects
test_endpoint \
  "List all projects" \
  "GET" \
  "$BASE_URL/projects?per_page=10" \
  "$AUTH_HEADER" \
  "" \
  "200"

# Test 3.3: Get project by ID
if [ ! -z "$PROJECT_ID" ]; then
  test_endpoint \
    "Get project by ID" \
    "GET" \
    "$BASE_URL/projects/$PROJECT_ID" \
    "$AUTH_HEADER" \
    "" \
    "200"
fi

# Test 3.4: Update project
if [ ! -z "$PROJECT_ID" ]; then
  test_endpoint \
    "Update project" \
    "PATCH" \
    "$BASE_URL/projects/$PROJECT_ID" \
    "$AUTH_HEADER -H 'Content-Type: application/json'" \
    '{
      "project": {
        "description": "Updated description for testing"
      }
    }' \
    "200"
fi

# Test 3.5: Vote on project
if [ ! -z "$PROJECT_ID" ]; then
  test_endpoint \
    "Vote on project" \
    "POST" \
    "$BASE_URL/projects/$PROJECT_ID/vote" \
    "$AUTH_HEADER -H 'Content-Type: application/json'" \
    '{"vote": {"vote_type": "upvote"}}' \
    "201"
fi

# ==========================================
# 4. TAG & SUGGESTION TESTS
# ==========================================
echo -e "\n${BLUE}========== 4. TAG & SUGGESTION TESTS ==========${NC}"

# Test 4.1: Get tag suggestions
test_endpoint \
  "Get tag suggestions" \
  "GET" \
  "$BASE_URL/suggestions/tags?q=web" \
  "$AUTH_HEADER" \
  "" \
  "200"

# Test 4.2: Get country suggestions
test_endpoint \
  "Get country suggestions" \
  "GET" \
  "$BASE_URL/suggestions/countries?q=thai" \
  "$AUTH_HEADER" \
  "" \
  "200"

# Test 4.3: Get university suggestions
test_endpoint \
  "Get university suggestions" \
  "GET" \
  "$BASE_URL/suggestions/universities?q=technology" \
  "$AUTH_HEADER" \
  "" \
  "200"

# ==========================================
# 5. SEARCH TESTS
# ==========================================
echo -e "\n${BLUE}========== 5. SEARCH TESTS ==========${NC}"

# Test 5.1: Search projects
test_endpoint \
  "Search projects" \
  "GET" \
  "$BASE_URL/search/projects?q=test" \
  "$AUTH_HEADER" \
  "" \
  "200"

# Test 5.2: Search users
test_endpoint \
  "Search users" \
  "GET" \
  "$BASE_URL/search/users?q=araya" \
  "$AUTH_HEADER" \
  "" \
  "200"

# ==========================================
# 6. NOTIFICATION TESTS
# ==========================================
echo -e "\n${BLUE}========== 6. NOTIFICATION TESTS ==========${NC}"

# Test 6.1: Get notifications
test_endpoint \
  "Get user notifications" \
  "GET" \
  "$BASE_URL/notifications" \
  "$AUTH_HEADER" \
  "" \
  "200"

# Test 6.2: Get unread notifications count
test_endpoint \
  "Get unread notifications count" \
  "GET" \
  "$BASE_URL/notifications/unread_count" \
  "$AUTH_HEADER" \
  "" \
  "200"

# ==========================================
# 7. COMMENT TESTS
# ==========================================
echo -e "\n${BLUE}========== 7. COMMENT TESTS ==========${NC}"

if [ ! -z "$PROJECT_ID" ]; then
  # Test 7.1: Create comment
  echo -e "\n${BLUE}Creating test comment...${NC}"
  COMMENT_RESPONSE=$(curl -s -X POST "$BASE_URL/projects/$PROJECT_ID/comments" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "comment": {
        "content": "This is a test comment for backend testing"
      }
    }')
  
  COMMENT_ID=$(echo $COMMENT_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin).get('id', ''))" 2>/dev/null)
  
  if [ -z "$COMMENT_ID" ]; then
    echo -e "${RED}✗ Failed to create comment${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  else
    echo -e "${GREEN}✓ Comment created: $COMMENT_ID${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  fi
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  
  # Test 7.2: List comments
  test_endpoint \
    "List project comments" \
    "GET" \
    "$BASE_URL/projects/$PROJECT_ID/comments" \
    "$AUTH_HEADER" \
    "" \
    "200"
fi

# ==========================================
# 8. MODERATION TESTS
# ==========================================
echo -e "\n${BLUE}========== 8. MODERATION TESTS ==========${NC}"

# Test 8.1: Create report
if [ ! -z "$PROJECT_ID" ]; then
  test_endpoint \
    "Report a project" \
    "POST" \
    "$BASE_URL/reports" \
    "$AUTH_HEADER -H 'Content-Type: application/json'" \
    '{
      "report": {
        "reportable_type": "Project",
        "reportable_id": "'$PROJECT_ID'",
        "reason": "spam",
        "description": "Testing report system"
      }
    }' \
    "201"
fi

# Test 8.2: Get my reports
test_endpoint \
  "Get my reports" \
  "GET" \
  "$BASE_URL/reports/my_reports" \
  "$AUTH_HEADER" \
  "" \
  "200"

# ==========================================
# 9. STATISTICS TESTS
# ==========================================
echo -e "\n${BLUE}========== 9. STATISTICS TESTS ==========${NC}"

if [ ! -z "$PROJECT_ID" ]; then
  # Test 9.1: Get project stats
  test_endpoint \
    "Get project statistics" \
    "GET" \
    "$BASE_URL/projects/$PROJECT_ID/stats" \
    "$AUTH_HEADER" \
    "" \
    "200"
fi

# ==========================================
# 10. HEALTH CHECK
# ==========================================
echo -e "\n${BLUE}========== 10. HEALTH CHECK ==========${NC}"

test_endpoint \
  "Rails health check" \
  "GET" \
  "http://localhost:3000/up" \
  "" \
  "" \
  "200"

# ==========================================
# FINAL SUMMARY
# ==========================================
echo -e "\n=========================================="
echo -e "TEST SUMMARY"
echo -e "=========================================="
echo -e "Total Tests:  $TOTAL_TESTS"
echo -e "${GREEN}Passed:       $PASSED_TESTS${NC}"
echo -e "${RED}Failed:       $FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
  echo -e "\n${GREEN}✓ ALL TESTS PASSED!${NC}"
  echo -e "=========================================="
  exit 0
else
  echo -e "\n${RED}✗ SOME TESTS FAILED${NC}"
  echo -e "=========================================="
  exit 1
fi
