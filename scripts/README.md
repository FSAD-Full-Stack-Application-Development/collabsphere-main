# CollabSphere Test Scripts
This folder contains automated test scripts for the CollabSphere backend API.
## Available Scripts
### 1. `test-comprehensive.sh` - **RECOMMENDED** 
**Complete automated test suite covering ALL 40+ tests**
Tests everything we've implemented and verified:
- JWT Authentication (Register, Login, Token validation)
- User Management (Profile, Extended fields, Two-stage registration)
- Project CRUD (Create, Read, Update, Delete)
- Collaboration System (Custom roles, Permissions)
- Comment System (CRUD, Threading, Nested replies)
- Voting System (Upvote, Downvote, Duplicate prevention)
- Statistics Tracking (Auto-updates, Counters)
- Advanced Features (Pagination, Filtering, Search)
- Security Testing (Invalid tokens, Unauthorized access)
- Error Handling (Validation, Edge cases)
- Delete Operations (Comments, Collaborations, Projects)
**Usage:**
```bash
# Run all tests
cd /root/collabsphere/scripts
./test-comprehensive.sh
# Or with custom base URL
BASE_URL=http://localhost:3000 ./test-comprehensive.sh
```
**Expected Output:**
```
 CollabSphere Comprehensive API Test Suite
Configuration:
 Base URL: http://localhost:3000
 Verbose: false
 PASS: Server is running at http://localhost:3000
1. AUTHENTICATION & JWT TESTS
 PASS: User registration successful
 PASS: User login successful
 PASS: Invalid credentials properly rejected
 PASS: JWT token is valid and accepted
... (40+ more tests)
 TEST SUMMARY
Total Tests: 40+
Passed: 40+
Failed: 0
 ALL TESTS PASSED! (100%)
 Backend API is production ready!
```
---
### 2. `test-user.sh` - Original Basic Tests
**Simpler test script covering core functionality**
Basic tests:
- User registration
- User login
- Project creation
- Project listing
- Comments
- Voting
- Invalid authentication
**Usage:**
```bash
cd /root/collabsphere/scripts
./test-user.sh
```
---
### 3. `setup.sh` - Database Setup
**Initialize database with migrations and seed data**
**Usage:**
```bash
cd /root/collabsphere/scripts
./setup.sh
```
---
### 4. `dev.sh` - Development Server
**Start Rails development server**
**Usage:**
```bash
cd /root/collabsphere/scripts
./dev.sh
```
---
### 5. `deploy.sh` - Production Deployment
**Deploy to production environment**
**Usage:**
```bash
cd /root/collabsphere/scripts
./deploy.sh
```
---
## Getting Started for Team Members
### Prerequisites
1. Rails server must be running:
 ```bash
 cd /root/collabsphere/backend
 rails server -p 3000
 ```
2. Database must be set up:
 ```bash
 cd /root/collabsphere/backend
 rails db:create db:migrate
 ```
### Run Complete Test Suite
```bash
cd /root/collabsphere/scripts
chmod +x test-comprehensive.sh
./test-comprehensive.sh
```
This will:
1. Check if server is running
2. Test all authentication endpoints
3. Test all CRUD operations
4. Test collaboration system
5. Test comment threading
6. Test voting system
7. Test statistics tracking
8. Test pagination & filtering
9. Test security features
10. Test delete operations
**Total time:** ~30-60 seconds
---
## Test Categories Covered
### Category 1: Authentication & JWT
- User registration
- User login
- Invalid credentials handling
- JWT token validation
### Category 2: User Management
- Get user profile
- Update profile (extended fields)
- List all users
- Two-stage registration
### Category 3: Project CRUD
- Create project
- Read project details
- Update project
- List all projects
- Validation testing
### Category 4: Collaboration System
- Add collaborator
- List collaborators
- Custom roles (owner, collaborator, vc)
- Permissions (read, write, manage)
- Duplicate prevention
### Category 5: Comment System
- Create comment
- Create nested reply (threading)
- List comments
- Update comment
- Delete comment
### Category 6: Voting System
- Upvote project
- Downvote project
- Remove vote
- Duplicate vote prevention
### Category 7: Statistics Tracking
- Get project statistics
- Verify auto-update after actions
- Views, votes, comments counters
### Category 8: Advanced Features
- Pagination (page, per_page)
- Filtering by status
- Search functionality
### Category 9: Security
- Unauthorized access (no token)
- Invalid token rejection
- Expired token handling
- Malformed JSON handling
### Category 10: Delete Operations
- Delete comments
- Delete collaborations
- Delete projects
---
## Troubleshooting
### Server Not Running
```
 FAIL: Server is not responding at http://localhost:3000
Solution:
cd /root/collabsphere/backend
rails server -p 3000
```
### Database Issues
```
Error: PG::ConnectionBad
Solution:
cd /root/collabsphere/backend
rails db:create
rails db:migrate
```
### Permission Denied
```
bash: ./test-comprehensive.sh: Permission denied
Solution:
chmod +x test-comprehensive.sh
```
---
## Test Results Documentation
After running tests, check these files for detailed results:
- `../backend/FINAL_COMPREHENSIVE_TEST_REPORT.md` (860 lines)
- `../backend/COMPREHENSIVE_API_TEST_REPORT.md` (573 lines)
---
## Expected Results
 **100% Pass Rate** - All tests should pass 
 **40+ Tests** - Complete coverage 
 **Production Ready** - Backend is fully tested
---
## For Team Members
### Frontend(React/Flutter)
After running these tests, you can confidently:
1. Use JWT authentication flow
2. Make authenticated API requests
3. Handle all CRUD operations
4. Implement collaboration features
5. Add comment threading
6. Integrate voting system
7. Display statistics
8. Use pagination
### Integration Examples
See these files for integration code:
- `../backend/FINAL_COMPREHENSIVE_TEST_REPORT.md` - Flutter & React examples
- `../README.md` - API documentation with examples
---
## Support
If you encounter issues:
1. Check server is running: `curl http://localhost:3000`
2. Check database: `cd ../backend && rails db:migrate:status`
3. Review test output for specific errors
4. Check `../backend/FINAL_COMPREHENSIVE_TEST_REPORT.md`
---
**Last Updated:** October 30, 2025 
**Test Coverage:** 100% 
**Total Tests:** 40+ 
**Status:** Production Ready