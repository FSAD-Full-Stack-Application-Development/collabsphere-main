#!/bin/bash
# Get a real token and test collaboration
RESP=$(curl -s -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"user": {"full_name": "Debug User", "email": "debug_'$(date +%s)'@test.com", "password": "password123"}}')

TOKEN=$(echo "$RESP" | python3 -c "import sys, json; print(json.load(sys.stdin)['token'])" 2>/dev/null)
USER_ID=$(echo "$RESP" | python3 -c "import sys, json; print(json.load(sys.stdin)['user']['id'])" 2>/dev/null)

# Create project
PROJ=$(curl -s -X POST http://localhost:3000/api/v1/projects \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"project": {"title": "Debug Project", "description": "Test", "status": "Ideation", "visibility": "public"}}')

PROJ_ID=$(echo "$PROJ" | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])" 2>/dev/null)

# Create collaborator
COLLAB=$(curl -s -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"user": {"full_name": "Collab User", "email": "collab_'$(date +%s)'@test.com", "password": "password123"}}')

COLLAB_ID=$(echo "$COLLAB" | python3 -c "import sys, json; print(json.load(sys.stdin)['user']['id'])" 2>/dev/null)

echo "Token: ${TOKEN:0:20}..."
echo "User ID: $USER_ID"
echo "Project ID: $PROJ_ID"
echo "Collaborator ID: $COLLAB_ID"
echo ""

# Test adding collaborator
echo "Testing: POST /api/v1/projects/$PROJ_ID/collaborations"
echo "Payload: {\"collaboration\": {\"user_id\": $COLLAB_ID, \"project_role\": \"member\"}}"
ADD_RESP=$(curl -s -X POST "http://localhost:3000/api/v1/projects/$PROJ_ID/collaborations" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"collaboration\": {\"user_id\": $COLLAB_ID, \"project_role\": \"member\"}}")

echo "Response:"
echo "$ADD_RESP" | python3 -m json.tool 2>/dev/null || echo "$ADD_RESP"

# Test update user profile
echo ""
echo "Testing: PATCH /api/v1/users/$USER_ID"
echo "Payload: {\"user\": {\"country\": \"Japan\", \"university\": \"Tokyo Tech\"}}"
UPDATE=$(curl -s -X PATCH "http://localhost:3000/api/v1/users/$USER_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"user": {"country": "Japan", "university": "Tokyo Tech", "department": "CS", "bio": "Test"}}')

echo "Response:"
echo "$UPDATE" | python3 -m json.tool 2>/dev/null || echo "$UPDATE"
