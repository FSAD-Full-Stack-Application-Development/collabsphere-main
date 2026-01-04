#!/bin/bash

# Register a test user
RESP=$(curl -s -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"user": {"full_name": "Test User", "email": "test_collab_'$(date +%s)'@test.com", "password": "password123"}}')

TOKEN=$(echo "$RESP" | python3 -c "import sys, json; print(json.load(sys.stdin)['token'])" 2>/dev/null)
USER_ID=$(echo "$RESP" | python3 -c "import sys, json; print(json.load(sys.stdin)['user']['id'])" 2>/dev/null)

echo "Token: $TOKEN"
echo "User ID: $USER_ID"

# Create a project
PROJ=$(curl -s -X POST http://localhost:3000/api/v1/projects \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"project": {"title": "Test Project", "description": "Test", "status": "Ideation", "visibility": "public"}}')

PROJ_ID=$(echo "$PROJ" | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])" 2>/dev/null)
echo "Project ID: $PROJ_ID"

# Create collaborator user
COLLAB=$(curl -s -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"user": {"full_name": "Collaborator", "email": "collaborator_'$(date +%s)'@test.com", "password": "password123"}}')

COLLAB_ID=$(echo "$COLLAB" | python3 -c "import sys, json; print(json.load(sys.stdin)['user']['id'])" 2>/dev/null)
echo "Collaborator ID: $COLLAB_ID"

# Try to add collaborator
echo ""
echo "Adding collaborator with project_role=member..."
ADD_RESP=$(curl -s -X POST "http://localhost:3000/api/v1/projects/$PROJ_ID/collaborations" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"collaboration\": {\"user_id\": $COLLAB_ID, \"project_role\": \"member\"}}")

echo "Response:"
echo "$ADD_RESP" | python3 -m json.tool 2>/dev/null || echo "$ADD_RESP"
