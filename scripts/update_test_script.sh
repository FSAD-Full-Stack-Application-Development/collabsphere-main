#!/bin/bash
# Update test script for new simplified role structure

# Restore backup
cp test-comprehensive.sh.backup test-comprehensive.sh

# Remove professional_role line from user update test
sed -i '/professional_role.*Software Developer/d' test-comprehensive.sh

# Update collaboration tests to use project_role instead of role + permission
# Find and replace the collaboration creation payload
sed -i 's/"role": "collaborator",/"project_role": "member"/' test-comprehensive.sh
sed -i 's/"permission": "write"/"project_role": "member"/' test-comprehensive.sh
sed -i 's/"permission": "read"/"project_role": "viewer"/' test-comprehensive.sh

echo "Test script updated successfully!"
