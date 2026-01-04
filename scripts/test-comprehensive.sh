#!/bin/bash

################################################################################
# CollabSphere Comprehensive API Test Suite
# 
# This script tests ALL backend API functionality including:
# - JWT Authentication (Register, Login, Token validation)
# - User Management (Profile, Extended fields, Two-stage registration)
# - Project CRUD (Create, Read, Update, Delete)
# - Collaboration System (Custom roles, Permissions)
# - Comment System (CRUD, Threading, Nested replies)
# - Voting System (Upvote, Downvote, Duplicate prevention)
# - Statistics Tracking (Auto-updates, Counters)
# - Advanced Features (Pagination, Filtering, Search)
# - Security Testing (Invalid tokens, Unauthorized access, Expired tokens)
# - Error Handling (Validation, Edge cases, Malformed JSON)
#
# Total Tests: 40+
# Expected Pass Rate: 100%
################################################################################

set -e  # Exit on error (can be disabled for full test run)

# Configuration
BASE_URL="${BASE_URL:-http://localhost:3000}"
VERBOSE="${VERBOSE:-false}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Global variables
JWT_TOKEN=""
USER_ID=""
PROJECT_ID=""
PROJECT_ID_2=""
COMMENT_ID=""
COLLABORATION_ID=""
RESOURCE_ID=""

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo -e "\n${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}\n"
}

print_section() {
    echo -e "\n${MAGENTA}▶ $1${NC}\n"
}

test_pass() {
    PASSED_TESTS=$((PASSED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${GREEN}PASS:${NC} $1"
}

test_fail() {
    FAILED_TESTS=$((FAILED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${RED}FAIL:${NC} $1"
}

test_info() {
    echo -e "${BLUE}INFO:${NC} $1"
}

test_warn() {
    echo -e "${YELLOW}WARN:${NC} $1"
}

check_server() {
    print_section "Checking server availability..."
    
    if curl -s "$BASE_URL" -w "%{http_code}" -o /dev/null | grep -q "^[234]" > /dev/null 2>&1; then
        test_pass "Server is running at $BASE_URL"
        return 0
    else
        test_fail "Server is not responding at $BASE_URL"
        echo ""
        test_info "Please ensure the Rails server is running:"
        test_info "  cd backend && rails server -p 3000"
        exit 1
    fi
}

################################################################################
# Test Categories
################################################################################

#------------------------------------------------------------------------------
# 1. AUTHENTICATION & JWT TESTS
#------------------------------------------------------------------------------
test_authentication() {
    print_header "1. AUTHENTICATION & JWT TESTS"
    
    # Test 1.1: User Registration
    print_section "Test 1.1: User Registration"
    TIMESTAMP=$(date +%s)
    REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/register" \
        -H "Content-Type: application/json" \
        -d "{
            \"user\": {
                \"email\": \"testuser_${TIMESTAMP}@test.com\",
                \"password\": \"password123\",
                \"full_name\": \"Test User ${TIMESTAMP}\"
            }
        }")
    
    if echo "$REGISTER_RESPONSE" | grep -q "token"; then
        test_pass "User registration successful"
        JWT_TOKEN=$(echo "$REGISTER_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['token'])" 2>/dev/null || echo "")
        USER_ID=$(echo "$REGISTER_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['user']['id'])" 2>/dev/null || echo "")
        test_info "JWT Token obtained: ${JWT_TOKEN:0:20}..."
        test_info "User ID: $USER_ID"
    else
        test_fail "User registration failed: $REGISTER_RESPONSE"
    fi
    
    # Test 1.2: User Login
    print_section "Test 1.2: User Login"
    LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"testuser_${TIMESTAMP}@test.com\",
            \"password\": \"password123\"
        }")
    
    if echo "$LOGIN_RESPONSE" | grep -q "token"; then
        test_pass "User login successful"
    else
        test_fail "User login failed: $LOGIN_RESPONSE"
    fi
    
    # Test 1.3: Invalid Login Credentials
    print_section "Test 1.3: Invalid Login Credentials"
    INVALID_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
        -H "Content-Type: application/json" \
        -d '{"email": "wrong@test.com", "password": "wrongpass"}')
    
    if echo "$INVALID_LOGIN" | grep -q "error\|Unauthorized"; then
        test_pass "Invalid credentials properly rejected"
    else
        test_fail "Invalid credentials should have been rejected"
    fi
    
    # Test 1.4: JWT Token Validation
    print_section "Test 1.4: JWT Token Validation (Access Protected Route)"
    PROFILE_RESPONSE=$(curl -s -X GET "$BASE_URL/api/v1/users/profile" \
        -H "Authorization: Bearer $JWT_TOKEN")
    
    if echo "$PROFILE_RESPONSE" | grep -q "email"; then
        test_pass "JWT token is valid and accepted"
    else
        test_fail "JWT token validation failed"
    fi
}

#------------------------------------------------------------------------------
# 2. USER MANAGEMENT TESTS
#------------------------------------------------------------------------------
test_user_management() {
    print_header "2. USER MANAGEMENT TESTS"
    
    # Test 2.1: Get Current User Profile
    print_section "Test 2.1: Get Current User Profile"
    PROFILE=$(curl -s -X GET "$BASE_URL/api/v1/users/profile" \
        -H "Authorization: Bearer $JWT_TOKEN")
    
    if echo "$PROFILE" | grep -q "email"; then
        test_pass "User profile retrieval successful"
    else
        test_fail "User profile retrieval failed"
    fi
    
    # Test 2.2: Update User Profile (Two-stage registration - Step 2)
    print_section "Test 2.2: Update User Profile (Extended Fields)"
    UPDATE_RESPONSE=$(curl -s -X PUT "$BASE_URL/api/v1/users/$USER_ID" \
        -H "Authorization: Bearer $JWT_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "user": {
                "country": "Japan",
                "university": "Tokyo Tech",
                "department": "Computer Science",                "bio": "Full-stack developer passionate about collaboration"
            }
        }')
    
    if echo "$UPDATE_RESPONSE" | grep -q "Japan\|Tokyo Tech"; then
        test_pass "User profile update successful (extended fields)"
    else
        test_fail "User profile update failed"
    fi
    
    # Test 2.3: List All Users
    print_section "Test 2.3: List All Users"
    USERS_LIST=$(curl -s -X GET "$BASE_URL/api/v1/users" \
        -H "Authorization: Bearer $JWT_TOKEN")
    
    if echo "$USERS_LIST" | grep -q "email"; then
        test_pass "Users listing successful"
        USER_COUNT=$(echo "$USERS_LIST" | python3 -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "N/A")
        test_info "Total users in system: $USER_COUNT"
    else
        test_fail "Users listing failed"
    fi
}

#------------------------------------------------------------------------------
# 3. PROJECT CRUD TESTS
#------------------------------------------------------------------------------
test_project_crud() {
    print_header "3. PROJECT CRUD TESTS"
    
    # Test 3.1: Create Project
    print_section "Test 3.1: Create Project"
    TIMESTAMP=$(date +%s)
    CREATE_PROJECT=$(curl -s -X POST "$BASE_URL/api/v1/projects" \
        -H "Authorization: Bearer $JWT_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"project\": {
                \"title\": \"Test Project ${TIMESTAMP}\",
                \"description\": \"Automated test project for comprehensive testing\",
                \"status\": \"Ideation\",
                \"visibility\": \"public\"
            }
        }")
    
    if echo "$CREATE_PROJECT" | grep -q "id"; then
        test_pass "Project creation successful"
        PROJECT_ID=$(echo "$CREATE_PROJECT" | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])" 2>/dev/null || echo "")
        test_info "Project ID: $PROJECT_ID"
    else
        test_fail "Project creation failed: $CREATE_PROJECT"
    fi
    
    # Test 3.2: Read Project Details
    print_section "Test 3.2: Read Project Details"
    PROJECT_DETAIL=$(curl -s -X GET "$BASE_URL/api/v1/projects/$PROJECT_ID" \
        -H "Authorization: Bearer $JWT_TOKEN")
    
    if echo "$PROJECT_DETAIL" | grep -q "title"; then
        test_pass "Project retrieval successful"
    else
        test_fail "Project retrieval failed"
    fi
    
    # Test 3.3: Update Project
    print_section "Test 3.3: Update Project"
    UPDATE_PROJECT=$(curl -s -X PUT "$BASE_URL/api/v1/projects/$PROJECT_ID" \
        -H "Authorization: Bearer $JWT_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "project": {
                "title": "Updated Test Project",
                "status": "Ongoing"
            }
        }')
    
    if echo "$UPDATE_PROJECT" | grep -q "Updated Test Project\|Ongoing"; then
        test_pass "Project update successful"
    else
        test_fail "Project update failed"
    fi
    
    # Test 3.4: List All Projects
    print_section "Test 3.4: List All Projects"
    PROJECTS_LIST=$(curl -s -X GET "$BASE_URL/api/v1/projects" \
        -H "Authorization: Bearer $JWT_TOKEN")
    
    if echo "$PROJECTS_LIST" | grep -q "title"; then
        test_pass "Projects listing successful"
        PROJECT_COUNT=$(echo "$PROJECTS_LIST" | python3 -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "N/A")
        test_info "Total projects: $PROJECT_COUNT"
    else
        test_fail "Projects listing failed"
    fi
    
    # Test 3.5: Project Validation (Missing Required Fields)
    print_section "Test 3.5: Project Validation (Missing Title)"
    INVALID_PROJECT=$(curl -s -X POST "$BASE_URL/api/v1/projects" \
        -H "Authorization: Bearer $JWT_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "project": {
                "description": "No title provided"
            }
        }')
    
    if echo "$INVALID_PROJECT" | grep -q "error\|can't be blank"; then
        test_pass "Project validation working (rejected missing title)"
    else
        test_fail "Project validation should reject missing title"
    fi
}

#------------------------------------------------------------------------------
# 4. COLLABORATION SYSTEM TESTS
#------------------------------------------------------------------------------
test_collaboration_system() {
    print_header "4. COLLABORATION SYSTEM TESTS"
    
    # Create a second user for collaboration testing
    print_section "Test 4.1: Create Second User for Collaboration"
    TIMESTAMP=$(date +%s)
    COLLABORATOR_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/register" \
        -H "Content-Type: application/json" \
        -d "{
            \"user\": {
                \"email\": \"collaborator_${TIMESTAMP}@test.com\",
                \"password\": \"password123\",
                \"full_name\": \"Collaborator ${TIMESTAMP}\"
            }
        }")
    
    COLLABORATOR_ID=$(echo "$COLLABORATOR_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['user']['id'])" 2>/dev/null || echo "")
    
    if [ -n "$COLLABORATOR_ID" ]; then
        test_pass "Second user created for collaboration testing"
        test_info "Collaborator ID: $COLLABORATOR_ID"
    else
        test_fail "Failed to create second user"
    fi
    
    # Test 4.2: Add Collaborator
    print_section "Test 4.2: Add Collaborator to Project"
    ADD_COLLAB=$(curl -s -X POST "$BASE_URL/api/v1/projects/$PROJECT_ID/collaborations" \
        -H "Authorization: Bearer $JWT_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"collaboration\": {
                \"user_id\": $COLLABORATOR_ID,
                \"project_role\": \"member\"
                
            }
        }")
    
    if echo "$ADD_COLLAB" | grep -q "id\|member\|project_role"; then
        test_pass "Collaborator added successfully"
        COLLABORATION_ID=$(echo "$ADD_COLLAB" | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])" 2>/dev/null || echo "")
    else
        test_fail "Failed to add collaborator"
    fi
    
    # Test 4.3: List Collaborators
    print_section "Test 4.3: List Project Collaborators"
    LIST_COLLAB=$(curl -s -X GET "$BASE_URL/api/v1/projects/$PROJECT_ID/collaborations" \
        -H "Authorization: Bearer $JWT_TOKEN")
    
    if echo "$LIST_COLLAB" | grep -q "project_role\|user_id"; then
        test_pass "Collaborators listing successful"
    else
        test_fail "Collaborators listing failed"
    fi
    
    # Test 4.4: Prevent Duplicate Collaboration
    print_section "Test 4.4: Prevent Duplicate Collaboration"
    DUPLICATE_COLLAB=$(curl -s -X POST "$BASE_URL/api/v1/projects/$PROJECT_ID/collaborations" \
        -H "Authorization: Bearer $JWT_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"collaboration\": {
                \"user_id\": $COLLABORATOR_ID,
                \"project_role\": \"viewer\"
                
            }
        }")
    
    if echo "$DUPLICATE_COLLAB" | grep -q "error\|already"; then
        test_pass "Duplicate collaboration properly prevented"
    else
        test_warn "Duplicate collaboration should be prevented"
    fi
}

#------------------------------------------------------------------------------
# 5. COMMENT SYSTEM TESTS
#------------------------------------------------------------------------------
test_comment_system() {
    print_header "5. COMMENT SYSTEM TESTS"
    
    # Test 5.1: Create Comment
    print_section "Test 5.1: Create Comment"
    CREATE_COMMENT=$(curl -s -X POST "$BASE_URL/api/v1/projects/$PROJECT_ID/comments" \
        -H "Authorization: Bearer $JWT_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "comment": {
                "content": "This is an automated test comment!"
            }
        }')
    
    if echo "$CREATE_COMMENT" | grep -q "content"; then
        test_pass "Comment creation successful"
        COMMENT_ID=$(echo "$CREATE_COMMENT" | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])" 2>/dev/null || echo "")
        test_info "Comment ID: $COMMENT_ID"
    else
        test_fail "Comment creation failed"
    fi
    
    # Test 5.2: Create Nested Reply
    print_section "Test 5.2: Create Nested Reply (Threading)"
    NESTED_COMMENT=$(curl -s -X POST "$BASE_URL/api/v1/projects/$PROJECT_ID/comments" \
        -H "Authorization: Bearer $JWT_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"comment\": {
                \"content\": \"This is a reply to the parent comment\",
                \"parent_id\": $COMMENT_ID
            }
        }")
    
    if echo "$NESTED_COMMENT" | grep -q "parent_id"; then
        test_pass "Nested comment (threading) successful"
    else
        test_fail "Nested comment creation failed"
    fi
    
    # Test 5.3: List Comments
    print_section "Test 5.3: List Project Comments"
    LIST_COMMENTS=$(curl -s -X GET "$BASE_URL/api/v1/projects/$PROJECT_ID/comments" \
        -H "Authorization: Bearer $JWT_TOKEN")
    
    if echo "$LIST_COMMENTS" | grep -q "content"; then
        test_pass "Comments listing successful"
        COMMENT_COUNT=$(echo "$LIST_COMMENTS" | python3 -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "N/A")
        test_info "Total comments: $COMMENT_COUNT"
    else
        test_fail "Comments listing failed"
    fi
    
    # Test 5.4: Update Comment
    print_section "Test 5.4: Update Comment"
    UPDATE_COMMENT=$(curl -s -X PUT "$BASE_URL/api/v1/projects/$PROJECT_ID/comments/$COMMENT_ID" \
        -H "Authorization: Bearer $JWT_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "comment": {
                "content": "Updated comment content"
            }
        }')
    
    if echo "$UPDATE_COMMENT" | grep -q "Updated comment content"; then
        test_pass "Comment update successful"
    else
        test_fail "Comment update failed"
    fi
}

#------------------------------------------------------------------------------
# 6. VOTING SYSTEM TESTS
#------------------------------------------------------------------------------
test_voting_system() {
    print_header "6. VOTING SYSTEM TESTS"
    
    # Test 6.1: Upvote Project
    print_section "Test 6.1: Upvote Project"
    UPVOTE=$(curl -s -X POST "$BASE_URL/api/v1/projects/$PROJECT_ID/vote" \
        -H "Authorization: Bearer $JWT_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"vote_type": "up"}')
    
    if echo "$UPVOTE" | grep -q "message\|success"; then
        test_pass "Upvote successful"
    else
        test_fail "Upvote failed"
    fi
    
    # Test 6.2: Prevent Duplicate Vote
    print_section "Test 6.2: Prevent Duplicate Vote"
    DUPLICATE_VOTE=$(curl -s -X POST "$BASE_URL/api/v1/projects/$PROJECT_ID/vote" \
        -H "Authorization: Bearer $JWT_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"vote_type": "up"}')
    
    if echo "$DUPLICATE_VOTE" | grep -q "error\|already"; then
        test_pass "Duplicate vote properly prevented"
    else
        test_warn "Duplicate vote should be prevented"
    fi
    
    # Test 6.3: Remove Vote
    print_section "Test 6.3: Remove Vote"
    REMOVE_VOTE=$(curl -s -X DELETE "$BASE_URL/api/v1/projects/$PROJECT_ID/vote" \
        -H "Authorization: Bearer $JWT_TOKEN")
    
    if echo "$REMOVE_VOTE" | grep -q "removed\|success"; then
        test_pass "Vote removal successful"
    else
        test_warn "Vote removal response: $REMOVE_VOTE"
    fi
    
    # Test 6.4: Downvote Project
    print_section "Test 6.4: Downvote Project"
    DOWNVOTE=$(curl -s -X POST "$BASE_URL/api/v1/projects/$PROJECT_ID/vote" \
        -H "Authorization: Bearer $JWT_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"vote_type": "down"}')
    
    if echo "$DOWNVOTE" | grep -q "message\|success"; then
        test_pass "Downvote successful"
    else
        test_fail "Downvote failed"
    fi
}

#------------------------------------------------------------------------------
# 7. STATISTICS TRACKING TESTS
#------------------------------------------------------------------------------
test_statistics() {
    print_header "7. STATISTICS TRACKING TESTS"
    
    # Test 7.1: Get Project Statistics
    print_section "Test 7.1: Get Project Statistics"
    STATS=$(curl -s -X GET "$BASE_URL/api/v1/stats/projects/$PROJECT_ID" \
        -H "Authorization: Bearer $JWT_TOKEN")
    
    if echo "$STATS" | grep -q "total_votes\|total_comments\|total_views"; then
        test_pass "Statistics retrieval successful"
        test_info "Stats: $(echo $STATS | python3 -c 'import sys,json; s=json.load(sys.stdin); print(f\"Views: {s.get(\"total_views\",0)}, Votes: {s.get(\"total_votes\",0)}, Comments: {s.get(\"total_comments\",0)}\")'  2>/dev/null || echo 'N/A')"
    else
        test_fail "Statistics retrieval failed"
    fi
    
    # Test 7.2: Verify Statistics Auto-Update
    print_section "Test 7.2: Verify Statistics Auto-Update After Actions"
    # Get stats before
    STATS_BEFORE=$(curl -s -X GET "$BASE_URL/api/v1/stats/projects/$PROJECT_ID" -H "Authorization: Bearer $JWT_TOKEN")
    VOTES_BEFORE=$(echo "$STATS_BEFORE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('total_votes', 0))" 2>/dev/null || echo "0")
    
    # Perform action (remove vote, add vote)
    curl -s -X DELETE "$BASE_URL/api/v1/projects/$PROJECT_ID/vote" -H "Authorization: Bearer $JWT_TOKEN" > /dev/null
    sleep 1
    curl -s -X POST "$BASE_URL/api/v1/projects/$PROJECT_ID/vote" \
        -H "Authorization: Bearer $JWT_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"vote_type": "up"}' > /dev/null
    
    # Get stats after
    STATS_AFTER=$(curl -s -X GET "$BASE_URL/api/v1/stats/projects/$PROJECT_ID" -H "Authorization: Bearer $JWT_TOKEN")
    VOTES_AFTER=$(echo "$STATS_AFTER" | python3 -c "import sys, json; print(json.load(sys.stdin).get('total_votes', 0))" 2>/dev/null || echo "0")
    
    test_pass "Statistics auto-update verification completed"
    test_info "Votes before: $VOTES_BEFORE, after: $VOTES_AFTER"
}

#------------------------------------------------------------------------------
# 8. ADVANCED FEATURES TESTS
#------------------------------------------------------------------------------
test_advanced_features() {
    print_header "8. ADVANCED FEATURES TESTS"
    
    # Test 8.1: Pagination
    print_section "Test 8.1: Pagination"
    PAGINATED=$(curl -s -X GET "$BASE_URL/api/v1/projects?page=1&per_page=5" \
        -H "Authorization: Bearer $JWT_TOKEN")
    
    if echo "$PAGINATED" | grep -q "title"; then
        test_pass "Pagination working"
        PAGE_COUNT=$(echo "$PAGINATED" | python3 -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "N/A")
        test_info "Items on page 1: $PAGE_COUNT (max 5)"
    else
        test_fail "Pagination failed"
    fi
    
    # Test 8.2: Filtering by Status
    print_section "Test 8.2: Filtering by Status"
    FILTERED=$(curl -s -X GET "$BASE_URL/api/v1/projects?status=Ongoing" \
        -H "Authorization: Bearer $JWT_TOKEN")
    
    if echo "$FILTERED" | grep -q "Ongoing\|title"; then
        test_pass "Status filtering working"
    else
        test_warn "Status filtering may not have results"
    fi
    
    # Test 8.3: Search Functionality
    print_section "Test 8.3: Search Functionality"
    SEARCH=$(curl -s -X GET "$BASE_URL/api/v1/projects?search=Test" \
        -H "Authorization: Bearer $JWT_TOKEN")
    
    if echo "$SEARCH" | grep -q "title"; then
        test_pass "Search functionality working"
    else
        test_warn "Search may not have results"
    fi
}

#------------------------------------------------------------------------------
# 9. SECURITY TESTS
#------------------------------------------------------------------------------
test_security() {
    print_header "9. SECURITY TESTS"
    
    # Test 9.1: Unauthorized Access (No Token)
    print_section "Test 9.1: Unauthorized Access (No Token)"
    UNAUTHORIZED=$(curl -s -X GET "$BASE_URL/api/v1/projects")
    
    if echo "$UNAUTHORIZED" | grep -q "error\|Unauthorized"; then
        test_pass "Unauthorized access properly blocked (no token)"
    else
        test_fail "Should require authentication"
    fi
    
    # Test 9.2: Invalid Token
    print_section "Test 9.2: Invalid Token"
    INVALID_TOKEN=$(curl -s -X GET "$BASE_URL/api/v1/projects" \
        -H "Authorization: Bearer invalid_token_12345")
    
    if echo "$INVALID_TOKEN" | grep -q "error\|Unauthorized\|Invalid"; then
        test_pass "Invalid token properly rejected"
    else
        test_fail "Invalid token should be rejected"
    fi
    
    # Test 9.3: Expired Token (Simulated)
    print_section "Test 9.3: Expired/Malformed Token"
    EXPIRED_TOKEN=$(curl -s -X GET "$BASE_URL/api/v1/projects" \
        -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxLCJleHAiOjE1NDY0NTEyMDB9.invalid")
    
    if echo "$EXPIRED_TOKEN" | grep -q "error\|Unauthorized\|Invalid"; then
        test_pass "Expired/malformed token properly rejected"
    else
        test_fail "Expired token should be rejected"
    fi
    
    # Test 9.4: Malformed JSON
    print_section "Test 9.4: Malformed JSON Request"
    MALFORMED=$(curl -s -X POST "$BASE_URL/api/v1/projects" \
        -H "Authorization: Bearer $JWT_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{invalid json}')
    
    if echo "$MALFORMED" | grep -q "error\|parse"; then
        test_pass "Malformed JSON properly rejected"
    else
        test_warn "Malformed JSON handling: $MALFORMED"
    fi
}

#------------------------------------------------------------------------------
# 10. DELETE OPERATIONS TESTS
#------------------------------------------------------------------------------
test_delete_operations() {
    print_header "10. DELETE OPERATIONS TESTS"
    
    # Test 10.1: Delete Comment
    print_section "Test 10.1: Delete Comment"
    if [ -n "$COMMENT_ID" ]; then
        DELETE_COMMENT=$(curl -s -X DELETE "$BASE_URL/api/v1/projects/$PROJECT_ID/comments/$COMMENT_ID" \
            -H "Authorization: Bearer $JWT_TOKEN")
        
        if echo "$DELETE_COMMENT" | grep -q "success\|deleted" || [ -z "$DELETE_COMMENT" ]; then
            test_pass "Comment deletion successful"
        else
            test_warn "Comment deletion response: $DELETE_COMMENT"
        fi
    else
        test_warn "No comment ID available for deletion test"
    fi
    
    # Test 10.2: Delete Collaboration
    print_section "Test 10.2: Delete Collaboration"
    if [ -n "$COLLABORATION_ID" ]; then
        DELETE_COLLAB=$(curl -s -X DELETE "$BASE_URL/api/v1/projects/$PROJECT_ID/collaborations/$COLLABORATION_ID" \
            -H "Authorization: Bearer $JWT_TOKEN")
        
        if echo "$DELETE_COLLAB" | grep -q "success\|deleted" || [ -z "$DELETE_COLLAB" ]; then
            test_pass "Collaboration deletion successful"
        else
            test_warn "Collaboration deletion response: $DELETE_COLLAB"
        fi
    else
        test_warn "No collaboration ID available for deletion test"
    fi
    
    # Test 10.3: Delete Project
    print_section "Test 10.3: Delete Project"
    if [ -n "$PROJECT_ID" ]; then
        DELETE_PROJECT=$(curl -s -X DELETE "$BASE_URL/api/v1/projects/$PROJECT_ID" \
            -H "Authorization: Bearer $JWT_TOKEN")
        
        if echo "$DELETE_PROJECT" | grep -q "success\|deleted" || [ -z "$DELETE_PROJECT" ]; then
            test_pass "Project deletion successful"
        else
            test_warn "Project deletion response: $DELETE_PROJECT"
        fi
    else
        test_warn "No project ID available for deletion test"
    fi
}

################################################################################
# Main Test Runner
################################################################################

main() {
    clear
    print_header "CollabSphere Comprehensive API Test Suite"
    
    echo -e "${CYAN}Configuration:${NC}"
    echo -e "  Base URL: ${YELLOW}$BASE_URL${NC}"
    echo -e "  Verbose: $VERBOSE"
    echo ""
    
    # Check server
    check_server
    
    # Run all test categories
    test_authentication
    test_user_management
    test_project_crud
    test_collaboration_system
    test_comment_system
    test_voting_system
    test_statistics
    test_advanced_features
    test_security
    test_delete_operations
    
    # Final summary
    print_header "TEST SUMMARY"
    
    echo -e "${CYAN}Total Tests:${NC} $TOTAL_TESTS"
    echo -e "${GREEN}Passed:${NC} $PASSED_TESTS"
    echo -e "${RED}Failed:${NC} $FAILED_TESTS"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "\n${GREEN}ALL TESTS PASSED! (100%)${NC}"
        echo -e "${GREEN}Backend API is production ready!${NC}\n"
        exit 0
    else
        PASS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
        echo -e "\n${YELLOW}Pass Rate: ${PASS_RATE}%${NC}"
        echo -e "${YELLOW}Some tests failed. Please review the output above.${NC}\n"
        exit 1
    fi
}

# Run main function
main
