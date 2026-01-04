# CollabSphere Frontend

A React frontend application for the CollabSphere collaboration platform.

## Quick Start

1. **Install dependencies:**
   ```bash
   cd /root/collabsphere/frontend
   npm install
   ```

2. **Make sure your Rails API is running:**
   ```bash
   cd /root/collabsphere/backend
   rails server
   ```

3. **Start the React app:**
   ```bash
   cd /root/collabsphere/frontend
   npm start
   ```

4. **Open your browser:**
   Visit `http://localhost:3001`

## Features Implemented

### Authentication
- **User registration** with nested Rails parameters
- **JWT login/logout** with Bearer token management
- **Protected routes** with automatic redirect
- **Token storage** in localStorage
- **Profile completion** after registration

### User Management
- **Dashboard** with user profile display
- **Edit Profile** page at `/profile/edit`
  - Update country, bio, university, department
  - Manage user tags (comma-separated input)
- **Profile display** with relative timestamps
- **Username-only dropdowns** (no email display for privacy)

### Project Management
- **Create projects** with status indicators (Ideation/Ongoing/Completed)
- **List all projects** with relative creation times
- **Project details** view with full information
- **Edit project** functionality with error handling
- **Project statistics** (views, votes, comments count)
- **Single-button toggle voting** system (professional UI)
- **Relative timestamps** throughout ("2 hours ago", "1 day ago")

### Team Collaboration
- **Join project flow** for non-owners ("Join this project" button)
- **Invite collaborator** interface for project owners
- **Project role selection** with enum values:
  - Owner (full control)
  - Member (edit access)
  - Viewer (read-only)
- **Team member display** with role badges
- **Username-only user selection** in dropdowns

### Comments & Discussions
- **Add comments** to projects
- **Threaded replies** (nested comments)
- **Relative timestamps** on all comments
- **Real-time updates** after posting

### Resources
- **Add project resources** (documents, links, etc.)
- **Resource type categorization**
- **Resource display** in project details

## API Endpoints Used

| Endpoint | Method | Feature | Status |
|----------|--------|---------|--------|
| `/auth/register` | POST | User registration |  WORKING |
| `/auth/login` | POST | User login |  WORKING |
| `/api/v1/users/profile` | GET | Get user profile |  WORKING |
| `/api/v1/users/:id` | PATCH | Update user profile |  WORKING |
| `/api/v1/projects` | GET | List projects |  WORKING |
| `/api/v1/projects` | POST | Create project |  WORKING |
| `/api/v1/projects/:id` | GET | Project details |  WORKING |
| `/api/v1/projects/:id` | PUT | Update project |  WORKING |
| `/api/v1/projects/:id/vote` | POST | Vote on project |  WORKING |
| `/api/v1/projects/:id/vote` | DELETE | Remove vote |  WORKING |
| `/api/v1/projects/:id/comments` | GET | Get comments |  WORKING |
| `/api/v1/projects/:id/comments` | POST | Add comment |  WORKING |
| `/api/v1/projects/:id/collaborations` | GET | Get collaborators |  WORKING |
| `/api/v1/projects/:id/collaborations` | POST | Add collaborator |  WORKING |
| `/api/v1/projects/:id/resources` | GET | Get resources |  WORKING |
| `/api/v1/projects/:id/resources` | POST | Add resource |  WORKING |

## Key Implementation Details

### Rails Strong Parameters
All API requests use proper Rails parameter wrapping:

```javascript
// Registration
{ user: { full_name, email, password, country } }

// Create Project
{ project: { title, description, status } }

// Update Profile
{ user: { country, bio, university, department, tags } }

// Add Collaborator
{ collaboration: { user_id, project_role } }
```

### Relative Time Display
Custom `dateUtils.js` provides human-readable timestamps:
- "Just now" (< 1 minute)
- "5 minutes ago"
- "2 hours ago"
- "1 day ago"
- "3 weeks ago"
- Falls back to formatted date for older content

### Team Collaboration Flow
- **Non-owners** see "Join this project" button
- **Owners** see "Invite Collaborator" form with:
  - Username-only user dropdown
  - Project role selector (Owner/Member/Viewer)
  - No legacy fields (permission_level, custom role_name removed)

### Voting System
- Single toggle button instead of separate upvote/downvote
- Shows current vote state
- Professional, clean UI
- Handles vote/unvote/revote gracefully

## Configuration

The app is configured to:
- Connect to Rails API at `http://localhost:3000` (via REACT_APP_API_URL)
- Store JWT tokens in localStorage
- Auto-redirect on authentication errors
- Handle CORS properly with backend

## Project Structure

```
src/
├── components/              # React components
│   ├── Header.js           # Navigation header with auth state
│   ├── Login.js            # Login form
│   ├── Register.js         # Registration form (Stage 1)
│   ├── ProfileCompletion.js # Profile completion (Stage 2)
│   ├── Dashboard.js        # User dashboard
│   ├── EditProfile.js      # Edit user profile (NEW)
│   ├── ProjectList.js      # Projects listing with relative time
│   ├── CreateProject.js    # Project creation form
│   ├── EditProject.js      # Project editing with error handling
│   └── ProjectDetails.js   # Project detail view with team section
├── utils/
│   └── dateUtils.js        # Relative time utilities (NEW)
├── apiService.js           # API service layer with proper payload wrapping
├── App.js                  # Main app component with routing
├── index.js                # App entry point
└── index.css               # Global styles
```

## Recent Updates

### October 30, 2025

**New Features**
- Edit Profile page at `/profile/edit`
- Relative timestamps across all views
- Join/Invite team collaboration flow
- Single-button toggle voting

**UX Improvements**
- Removed email addresses from user dropdowns
- Simplified role selection to 3 project roles
- Professional voting interface
- Better error handling in forms
- Loading states throughout

**Bug Fixes**
- Fixed payload wrapping for Rails strong parameters
- Fixed collaborator form to use project_role enum
- Fixed registration payload structure
- Fixed project creation payload structure
- Removed unused handlers to eliminate warnings

**Removed**
- professional_role field (deprecated)
- VC/Investor badge (funding open to all)
- permission_level selector (simplified)
- Custom role_name field (using enum only)

## Styling

- Clean, modern design with card-based layouts
- Responsive layout (mobile-friendly)
- Color-coded status indicators for projects
- Interactive elements with hover states
- Loading states for async operations
- Professional badge system for roles
- Error messages with helpful context

## Troubleshooting

### CORS Issues
If you see CORS errors:
1. Verify Rails server is running on port 3000
2. Check `config/initializers/cors.rb` allows `http://localhost:3001`
3. Restart Rails server after CORS changes

### API Connection Issues
1. Verify Rails server is running: `curl http://localhost:3000/api/v1/projects`
2. Check API base URL in `.env`: `REACT_APP_API_URL=http://localhost:3000`
3. Verify authentication endpoints return JWT tokens

### Token Issues
If authentication isn't working:
1. Check browser localStorage for `token` key
2. Verify JWT secret is consistent in backend `.env`
3. Check token expiration (default 24 hours)
4. Clear localStorage and re-login: `localStorage.clear()`

### Compilation Warnings
If you see warnings about unused variables:
- These have been cleaned up in recent updates
- Ensure you're on the latest version
- Run `npm start` to verify compilation succeeds

## Development Workflow

### Testing New Features
1. Start backend: `cd backend && rails server`
2. Start frontend: `cd frontend && npm start`
3. Register a test user or login with existing credentials
4. Test the feature in browser
5. Check browser console for errors
6. Check Network tab for API calls

### Adding New Components
1. Create component in `src/components/`
2. Import in `App.js` if it needs a route
3. Add proper error handling and loading states
4. Use `apiService.js` for all API calls
5. Apply proper Rails parameter wrapping

### Updating API Integration
1. Check backend controller for expected parameters
2. Update `apiService.js` with correct payload shape
3. Ensure nested parameters match Rails strong parameters
4. Test with browser Network tab to verify request body

## Next Steps

### Planned Features
- Admin dashboard UI
- Direct messaging interface
- Advanced search filters
- Real-time notifications with WebSocket
- File upload for avatars and resources
- Email notifications

### Performance Optimizations
- Implement React.memo for list items
- Add virtualization for long lists
- Optimize re-renders with proper key props
- Add service worker for caching

### Testing
- Add unit tests for components
- Add integration tests for user flows
- Add E2E tests with Cypress
- Test error scenarios and edge cases

---

**Status:** Functional  
**Last Updated:** October 30, 2025  
**Next Phase:** Admin UI, messaging interface, deployment
