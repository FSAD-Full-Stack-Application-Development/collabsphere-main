#!/bin/bash

echo "=========================================="
echo "TESTING PROFILE API ENDPOINTS"
echo "=========================================="

BASE_URL="http://localhost:3000/api/v1"
AUTH_URL="http://localhost:3000/auth"

# Step 1: Login to get JWT token
echo -e "\n1. Logging in as Araya (student)..."
LOGIN_RESPONSE=$(curl -s -X POST $AUTH_URL/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "araya.student@collabsphere.com",
    "password": "password123"
  }')

TOKEN=$(echo $LOGIN_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin).get('token', ''))")

if [ -z "$TOKEN" ]; then
  echo "✗ Login failed"
  echo $LOGIN_RESPONSE | python3 -m json.tool
  exit 1
fi

echo "✓ Login successful, token received"

# Step 2: Get Araya's profile
echo -e "\n2. Getting Araya's profile..."
ARAYA_ID="4cb4cc14-f65b-4246-bc2a-588dde052331"
curl -s $BASE_URL/profiles/$ARAYA_ID \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

# Step 3: Get Somchai's profile
echo -e "\n3. Getting Somchai's profile (mentor)..."
SOMCHAI_ID="13ac340f-1148-4975-b671-4212e9252fdd"
curl -s $BASE_URL/profiles/$SOMCHAI_ID \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

# Step 4: Update Araya's profile
echo -e "\n4. Testing profile update..."
UPDATE_RESPONSE=$(curl -s -X PATCH $BASE_URL/users/$ARAYA_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "age": 23,
      "short_term_goals": "Complete IoT smart farming project and win Bangkok Tech Hackathon!"
    }
  }')

echo $UPDATE_RESPONSE | python3 -m json.tool

# Step 5: List all profiles
echo -e "\n5. Listing all user profiles..."
curl -s "$BASE_URL/users?per_page=10" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

echo -e "\n=========================================="
echo "PROFILE API TESTS COMPLETE ✓"
echo "=========================================="
