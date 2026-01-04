#!/bin/bash

echo "Test 1: Unauthorized Access (No Token)"
UNAUTH=$(curl -s -X GET http://localhost:3000/api/v1/projects)
echo "$UNAUTH" | python3 -m json.tool 2>/dev/null || echo "$UNAUTH"

echo ""
echo "Test 2: Invalid Token"
INVALID=$(curl -s -X GET http://localhost:3000/api/v1/projects \
  -H "Authorization: Bearer INVALID_TOKEN_12345")
echo "$INVALID" | python3 -m json.tool 2>/dev/null || echo "$INVALID"

echo ""
echo "Test 3: Malformed Token"
MALFORMED=$(curl -s -X GET http://localhost:3000/api/v1/projects \
  -H "Authorization: Bearer eyJhbGciOiJub25lIn0.eyJpZCI6MX0.")
echo "$MALFORMED" | python3 -m json.tool 2>/dev/null || echo "$MALFORMED"
