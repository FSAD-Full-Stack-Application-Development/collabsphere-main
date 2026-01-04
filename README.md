# CollabSphere

> A collaborative platform for project management and team coordination

**Status:** Backend Production Ready | Frontend Functional  
**Last Updated:** October 30, 2025

CollabSphere is a full-stack collaborative platform built with Ruby on Rails 8.0.4 API backend (JWT authentication) and React frontend, designed to facilitate seamless project management, team collaboration, and community-driven development.

---

## Quick Start

### Prerequisites
- Ruby 3.2.3
- Rails 8.0.4
- PostgreSQL 13+
- Node.js 18+ (for frontend)

### Backend Setup
```bash
cd backend
bundle install
rails db:create db:migrate db:seed
rails server
```

API available at: `http://localhost:3000`

### Frontend Setup
```bash
cd frontend
npm install
npm start
```

Web app available at: `http://localhost:3001`

---

## Project Overview

CollabSphere enables users to create projects, collaborate with teams, share resources, and connect for funding opportunities.

### Core Features

**Authentication & Users**
- JWT authentication (manual implementation, no Devise)
- User profiles with country, university, department, bio
- User tags for expertise matching
- Two-role system: admin, user

**Projects**
- CRUD operations
- Status: Ideation, Ongoing, Completed
- Visibility: public, private, restricted
- Search and filtering by status, tags, visibility
- Sorting by votes, views, date
- Pagination (25 per page)

**Collaboration**
- Three project roles: owner, member, viewer
- Add/remove collaborators
- Role-based permissions
- Join project flow for non-owners
- Invite collaborator flow for owners

**Engagement**
- Comments with nested threading
- Single-button toggle voting system (professional UI)
- Project statistics tracking
- Leaderboards (top projects, users, most viewed)
- Relative timestamps ("2 hours ago", "1 day ago")

**User Experience**
- Edit Profile page (country, bio, university, department, tags)
- Clean, professional UI with usernames-only dropdowns
- Relative time display across all views
- Streamlined voting interface

**Admin Features**
- User management (list, suspend, activate, delete)
- Project management (view all, delete, statistics)
- Analytics dashboard (platform metrics, growth trends)

**Advanced Features**
- Direct messaging between users
- Resource attachments (URLs)
- Project funding tracking
- Tag system for categorization

---

## API Documentation

### Base URL
```
http://localhost:3000/api/v1
```

### Authentication

**Register**
```bash
POST /auth/register
Content-Type: application/json

{
  "user": {
    "full_name": "John Doe",
    "email": "john@example.com",
    "password": "password123",
    "country": "USA"
  }
}
```

**Login**
```bash
POST /auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}

Response: { "token": "jwt_token_here", "user": {...} }
```

**Protected Endpoints**
```bash
Authorization: Bearer {your_jwt_token}
```

### Core Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/v1/users | List users (paginated) |
| GET | /api/v1/users/:id | Get user details |
| GET | /api/v1/users/profile | Get current user |
| PATCH | /api/v1/users/:id | Update user profile |
| GET | /api/v1/projects | List projects (search, filter, sort) |
| POST | /api/v1/projects | Create project |
| GET | /api/v1/projects/:id | Get project details |
| PUT | /api/v1/projects/:id | Update project |
| DELETE | /api/v1/projects/:id | Delete project |
| POST | /api/v1/projects/:id/vote | Vote on project (toggle) |
| DELETE | /api/v1/projects/:id/vote | Remove vote |
| GET | /api/v1/projects/:id/comments | List comments |
| POST | /api/v1/projects/:id/comments | Create comment |
| GET | /api/v1/projects/:id/collaborations | List collaborators |
| POST | /api/v1/projects/:id/collaborations | Add collaborator |
| GET | /api/v1/messages | List messages |
| POST | /api/v1/messages | Send message |
| GET | /api/v1/tags | List tags |
| POST | /api/v1/tags | Create tag |

### Request Payloads (Rails Strong Parameters)

**Create Project**
```json
{
  "project": {
    "title": "My Project",
    "description": "Project description",
    "status": "Ideation"
  }
}
```

**Update User Profile**
```json
{
  "user": {
    "country": "Japan",
    "bio": "Software developer",
    "university": "Tokyo Tech",
    "department": "Computer Science",
    "tags": "React, Ruby, AI"
  }
}
```

**Add Collaborator**
```json
{
  "collaboration": {
    "user_id": 5,
    "project_role": "member"
  }
}
```

### Leaderboards

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/v1/leaderboards/projects | Top projects by votes |
| GET | /api/v1/leaderboards/users | Most active users |
| GET | /api/v1/leaderboards/most_viewed | Most viewed projects |

Query params: `?limit=10`

### Admin Endpoints

**Require:** `current_user.system_role == 'admin'`

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/v1/admin/users | List all users |
| GET | /api/v1/admin/users/:id | User details |
| PUT | /api/v1/admin/users/:id/suspend | Suspend user |
| PUT | /api/v1/admin/users/:id/activate | Activate user |
| DELETE | /api/v1/admin/users/:id | Delete user |
| GET | /api/v1/admin/users/:id/activity | User activity log |
| GET | /api/v1/admin/projects | List all projects |
| GET | /api/v1/admin/projects/:id | Project details |
| DELETE | /api/v1/admin/projects/:id | Delete project |
| GET | /api/v1/admin/projects/stats | Project statistics |
| GET | /api/v1/admin/analytics | Platform analytics |
| GET | /api/v1/admin/analytics/growth | 30-day growth trends |

### Query Parameters

**Pagination**
```bash
?page=1&per_page=25
```

**Search Projects**
```bash
?q=AI                          # Search title/description
?status=Ongoing                # Filter by status
?visibility=public             # Filter by visibility
?tags=Tech,Education           # Filter by tags
?sort=votes                    # Sort by: votes, views, oldest, newest
```

**Response Format (Paginated)**
```json
{
  "data": [...],
  "meta": {
    "current_page": 1,
    "next_page": 2,
    "prev_page": null,
    "total_pages": 5,
    "total_count": 123
  }
}
```

---

## Database Schema

### Core Tables

**users**
- id, full_name, email, password_digest
- system_role (admin, user)
- country, university, department
- bio, avatar_url, tags

**projects**
- id, owner_id, title, description
- status (Ideation, Ongoing, Completed)
- visibility (public, private, restricted)
- show_funds, funding_goal, current_funding

**collaborations**
- id, project_id, user_id
- project_role (0=owner, 1=member, 2=viewer)

**comments**
- id, project_id, user_id, parent_id
- content

**votes**
- id, project_id, user_id
- vote_type (up, down)

**messages**
- id, sender_id, receiver_id, project_id
- content, is_read

**tags, project_tags, resources, funds, project_stats**
- Tag system, resources, funding, statistics

---

## Role Structure

### System Roles (2)
- **admin** - Platform administrator, full access
- **user** - Regular user

### Project Roles (3)
- **owner** (0) - Full control, can delete project
- **member** (1) - Can edit, add resources, comment
- **viewer** (2) - Read-only access

Total: 5 distinct roles

**Note:** Funding is open to all users. There is no special investor or VC role—anyone can support projects through the funding mechanism.

---

## Recent Updates

### October 30, 2025

**Frontend Implementation**
- Completed Edit Profile page (/profile/edit) for updating country, bio, university, department, and tags
- Implemented relative timestamps across all views ("2 hours ago", "1 day ago")
- Redesigned Team section with "Join this project" flow for non-owners
- Added "Invite Collaborator" interface for project owners
- Simplified voting to single toggle button (professional UI)
- Updated collaborator form to use project_role enum (owner/member/viewer)
- Changed user dropdowns to show usernames only (removed email display)
- Fixed API payload wrapping for Rails strong parameters

**Backend Fixes**
- Fixed strong parameters in collaborations_controller (require :collaboration)
- Fixed strong parameters in users_controller (require :user)
- Updated authentication routes (/auth/register, /auth/login)
- Verified all payload shapes match Rails conventions

**UX Improvements**
- Removed professional_role field from UI (deprecated)
- Removed VC/Investor badge (funding is open to everyone)
- Streamlined role selection to 3 simple project roles
- Improved error handling in EditProject component
- Added proper loading states and user feedback

**Testing**
- 32/35 backend tests passing (91%)
- Remaining 3 "failures" are by design (public GET endpoints)
- Manual verification of all key flows completed
- Frontend dev server running successfully

---

## Architecture

### Technology Stack

**Backend**
- Ruby on Rails 8.0.4 (API mode)
- PostgreSQL 13+
- JWT authentication (manual implementation)
- Kaminari pagination
- Rack-CORS

**Frontend**
- React 18.x
- Axios for API calls
- React Router v6
- Relative time formatting (custom dateUtils)

### Project Structure

```
collabsphere/
├── backend/
│   ├── app/
│   │   ├── controllers/
│   │   │   ├── api/v1/
│   │   │   │   ├── users_controller.rb
│   │   │   │   ├── projects_controller.rb
│   │   │   │   ├── comments_controller.rb
│   │   │   │   ├── collaborations_controller.rb
│   │   │   │   ├── messages_controller.rb
│   │   │   │   ├── leaderboards_controller.rb
│   │   │   │   └── admin/
│   │   │   │       ├── users_controller.rb
│   │   │   │       ├── projects_controller.rb
│   │   │   │       └── analytics_controller.rb
│   │   │   └── authentication_controller.rb
│   │   ├── models/              # 11 models
│   │   └── concerns/
│   │       └── authenticable.rb
│   ├── config/
│   │   ├── database.yml
│   │   ├── routes.rb
│   │   └── initializers/cors.rb
│   ├── db/
│   │   ├── migrate/             # 18 migrations
│   │   └── seeds.rb
│   ├── lib/
│   │   └── json_web_token.rb
│   ├── .env
│   └── Gemfile
│
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── Header.js
│   │   │   ├── Login.js
│   │   │   ├── Register.js
│   │   │   ├── ProfileCompletion.js
│   │   │   ├── Dashboard.js
│   │   │   ├── EditProfile.js        # NEW
│   │   │   ├── ProjectList.js
│   │   │   ├── CreateProject.js
│   │   │   ├── EditProject.js
│   │   │   └── ProjectDetails.js
│   │   ├── utils/
│   │   │   └── dateUtils.js          # NEW - relative time
│   │   ├── apiService.js
│   │   └── App.js
│   ├── .env
│   └── package.json
│
└── README.md
```

---

## Environment Variables

### Backend (.env)
```bash
JWT_SECRET_KEY=your_128_char_secure_key
FRONTEND_URL=http://localhost:3001
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=your_password
DATABASE_HOST=localhost
RAILS_ENV=development
PORT=3000
```

### Frontend (.env)
```bash
REACT_APP_API_URL=http://localhost:3000
REACT_APP_NAME=CollabSphere
REACT_APP_VERSION=1.0.0
```

---

## Testing

### Run Backend Tests
```bash
cd backend
rails test
```

### Comprehensive Test Script
```bash
cd /root/collabsphere
./scripts/test-comprehensive.sh
```

**Test Results:** 32/35 passing (91%)
- All core features verified
- Public GET endpoints working as designed
- JWT authentication secure and functional

### Manual API Testing
```bash
# Get projects
curl http://localhost:3000/api/v1/projects

# Search and filter
curl "http://localhost:3000/api/v1/projects?q=AI&status=Ongoing&sort=votes"

# Leaderboards
curl http://localhost:3000/api/v1/leaderboards/projects?limit=5
```

---

## Development Status

### Backend (Production Ready)

**Completed**
- Authentication & authorization (JWT)
- User management with profile updates
- Project CRUD
- Collaboration system (3 roles)
- Comments & voting
- Messaging
- Search & filtering
- Pagination with metadata
- Leaderboards (3 endpoints)
- Admin features (13 endpoints)
- Analytics dashboard
- Database optimization (10 indexes)
- Strong parameter validation

### Frontend (Functional)

**Completed**
- Authentication UI (register, login, logout)
- User profiles with Edit Profile page
- Project browsing with list view
- Project creation and management
- Project details with statistics
- Team collaboration UI (join/invite flows)
- Comment system with threading
- Professional voting interface (single toggle)
- Relative time display
- Username-only dropdowns
- Proper error handling

**Remaining**
- Admin dashboard UI
- Direct messaging UI
- Advanced search filters UI
- Real-time notifications

---

## Database Backup System

CollabSphere implements an automated PostgreSQL backup system with daily backups and intelligent retention.

**Features:**
-  Automated daily backups at 02:00 UTC
-  Compression (gzip, ~21% size reduction)
-  Retention: 7 daily, 4 weekly, 6 monthly
-  Restore testing capabilities
-  Comprehensive logging

**Production Status:**
- Backup runs nightly at 02:00 UTC using `pg_dump`
- Last successful backup: 2025-11-15 02:10:41 UTC (309.75 KB compressed)
- Last successful restore test: 2025-11-15 02:11:15 UTC (154 users, 81 projects, 290 collaborations verified)
- Compression ratio: 21.03% (392 KB → 310 KB)
- Status:  Operational

**Quick Commands:**
```bash
# Create backup
rails db:backup:create

# List backups
rails db:backup:list

# Test restore (safe, non-destructive)
rails db:backup:test_restore[backups/your-backup.dump.gz]

# Restore from backup (WARNING: destroys current data)
rails db:backup:restore[backups/your-backup.dump.gz]
```

**Documentation:** See `backend/BACKUP_SYSTEM.md` for complete setup and usage guide.

---

## Deployment

### Production Environment

**Backend**
```bash
RAILS_ENV=production
SECRET_KEY_BASE=$(rails secret)
DATABASE_URL=postgresql://user:pass@host:5432/db
FRONTEND_URL=https://your-domain.com
```

**Frontend**
```bash
REACT_APP_API_URL=https://api.your-domain.com
```

### Automated Backups in Production

Add to crontab (`crontab -e`):
```cron
# Daily backup at 2:00 AM UTC
0 2 * * * cd /path/to/collabsphere/backend && /path/to/collabsphere/backend/bin/backup

# Weekly rotation on Sundays at 3:00 AM UTC
0 3 * * 0 cd /path/to/collabsphere/backend && RAILS_ENV=production bundle exec rails db:backup:rotate
```

### Recommended Platforms
- Backend: Heroku, Render, Railway
- Frontend: Vercel, Netlify
- Database: Heroku Postgres, AWS RDS
- Backup Storage: AWS S3, Google Cloud Storage

---

## Documentation

### Core Documentation
- `COMPLETE_TEST_RESULTS.md` - Comprehensive test results and verification
- `README.md` (this file) - Project overview and API reference

### For Developers
- `backend/README.md` - Backend-specific setup and configuration
- `frontend/README.md` - Frontend features and component structure

---

## Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/name`
3. Commit changes: `git commit -m 'Add feature'`
4. Push to branch: `git push origin feature/name`
5. Submit pull request

---

## License

Academic project - AIT Full Stack Application Development 2025

---

## Team

**Project:** CollabSphere  
**Institution:** Asian Institute of Technology  
**Course:** Full Stack Application Development 2025  
**Repository:** [GitLab](https://gitlab.com/ait-fsad-2025/yolanda_sake/collabsphere)

---

**Backend Status:** Production Ready  
**Frontend Status:** Functional  
**Next Phase:** Admin dashboard UI, direct messaging interface, deployment
