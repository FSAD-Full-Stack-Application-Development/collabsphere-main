# CollabSphere Backend API Reference

This document provides a comprehensive reference for all backend API endpoints, parameters, request/response formats, authentication, error handling, and special features for CollabSphere.

---

## Table of Contents

- [Authentication](#authentication)
- [User Management](#user-management)
- [Projects](#projects)
- [Collaboration Requests](#collaboration-requests)
- [Collaborations](#collaborations)
- [Messaging](#messaging)
- [Funding](#funding)
- [Notifications](#notifications)
- [Audit Logs](#audit-logs)
- [Other Endpoints](#other-endpoints)
- [Error Handling](#error-handling)
- [WebSocket Messaging](#websocket-messaging)

---

## Authentication

All endpoints (except registration/login) require a JWT token in the `Authorization` header:

```
Authorization: Bearer <token>
```

### Endpoints

#### Register

`POST /auth/register`

**Body:**
Root key: `user` (object)

| Field                 | Type   | Required | Description                 |
| --------------------- | ------ | -------- | --------------------------- |
| full_name             | string | Yes      | User's full name            |
| email                 | string | Yes      | User email address (unique) |
| password              | string | Yes      | User password (min 6 chars) |
| password_confirmation | string | No       | Confirmation for password   |
| bio                   | string | No       | User biography              |
| avatar_url            | string | No       | URL to profile picture      |
| system_role           | string | No       | 'user' (default) or 'admin' |
| country               | string | No       | Country                     |

**Response:**

```
201 Created
{
  "token": "<jwt-token>",
  "user": {
    "id": 1,
    "full_name": "Alice Smith",
    "email": "alice@example.com",
    ...
  }
}
```

#### Login

`POST /api/auth/login`

**Body:**
| Field | Type | Required |
|----------|--------|----------|
| email | string | Yes |
| password | string | Yes |

**Response:**

```
200 OK
{
  "token": "<jwt-token>"
}
```

---

## User Management

### Get Current User

`GET /api/users/me`

**Response:**

```
200 OK
{
  "id": 1,
  "full_name": "Alice Smith",
  ...
}
```

### List/Search Users

`GET /api/v1/users`

**Query Parameters:**
| Name | Type | Required | Description |
|----------|--------|----------|-----------------------------------|
| name | string | No | Search by full or partial name |
| email | string | No | Search by full or partial email |
| page | int | No | Pagination page |
| per_page | int | No | Results per page |

**Response:**

```
200 OK
{
  "data": [ ...user objects... ],
  "meta": { ...pagination... }
}
```

### Get User by ID

`GET /api/users/:id`

**Response:** Same as above.

### Update User

`PUT /api/users/:id`

**Body:**
Root key: `user` (object)

| Field               | Type    | Required | Description |
| ------------------- | ------- | -------- | ----------- |
| full_name           | string  | No       |             |
| email               | string  | No       |             |
| password            | string  | No       |             |
| bio                 | string  | No       |             |
| avatar_url          | string  | No       |             |
| system_role         | string  | No       |             |
| country             | string  | No       |             |
| university          | string  | No       |             |
| department          | string  | No       |             |
| age                 | integer | No       |             |
| occupation          | string  | No       |             |
| short_term_goals    | string  | No       |             |
| long_term_goals     | string  | No       |             |
| immediate_questions | string  | No       |             |
| computer_equipment  | string  | No       |             |
| connection_type     | string  | No       |             |

### Delete User

`DELETE /api/users/:id`

**Response:**

```
204 No Content
```

---

## Projects

### List Projects

`GET /api/v1/projects`

**Query Parameters:**
| Name | Type | Required | Default | Description |
|-----------|---------|----------|---------|-----------------------------------|
| q | string | No | | Search by title/description |
| status | string | No | | Filter by status |
| visibility| string | No | | Filter by visibility |
| tags | string | No | | Comma-separated tag names |
| sort | string | No | | 'votes', 'views', 'oldest', etc. |
| page | integer | No | 1 | Pagination page |
| per_page | integer | No | 25 | Results per page |

**Response:**

```
200 OK
{
  "data": [ ...project objects... ],
  "meta": { ...pagination... }
}
```

### Get Project

`GET /api/v1/projects/:id`

**Response:**

```
200 OK
{
  "id": 1,
  "title": "Project X",
  ...
}
```

### Create Project

`POST /api/v1/projects`

**Body:**
Root key: `project` (object)

| Field       | Type    | Required | Description |
| ----------- | ------- | -------- | ----------- |
| title       | string  | Yes      |             |
| description | string  | Yes      |             |
| status      | string  | No       |             |
| visibility  | string  | No       |             |
| show_funds  | boolean | No       |             |

### Update Project

`PUT /api/v1/projects/:id`
Same as create, all fields optional.

### Delete Project

`DELETE /api/v1/projects/:id`

**Response:**

```
204 No Content
```

---

## Collaboration Requests

### List Collaboration Requests

`GET /api/v1/projects/:id/collab`

**Query Parameters:**
| Name | Type | Required | Default | Description |
|-------|---------|----------|---------|---------------------|
| page | integer | No | 1 | Pagination page |
| limit | integer | No | 20 | Results per page |

### Create Collaboration Request

`POST /api/v1/projects/:id/collab/request`

**Body:**
| Field | Type | Required | Description |
|---------|--------|----------|----------------------------|
| message | string | No | Message to project owner |

### Approve Collaboration Request

`POST /api/v1/projects/:id/collab/approve`

**Body or Query:**
| Field | Type | Required | Description |
|---------|---------|----------|----------------------------|
| user_id | integer | Yes | User whose request to approve |

### Reject Collaboration Request

`POST /api/v1/projects/:id/collab/reject`

**Body or Query:**
| Field | Type | Required | Description |
|---------|---------|----------|----------------------------|
| user_id | integer | Yes | User whose request to reject |

---

## Collaborations

### List Collaborations

`GET /api/v1/projects/:project_id/collaborations`

**Query Parameters:**
| Name | Type | Required | Default | Description |
|-------|---------|----------|---------|---------------------|
| page | integer | No | 1 | Pagination page |
| per_page | integer | No | 20 | Results per page |

### Add Collaborator

`POST /api/v1/projects/:project_id/collaborations`

**Body:**
Root key: `collaboration` (object)
| Field | Type | Required | Description |
|------------|---------|----------|---------------------|
| user_id | integer | Yes | User to add |
| project_role | string | No | Role for user |

### Update Collaboration

`PUT /api/v1/projects/:project_id/collaborations/:id`
Same as add, all fields optional.

### Remove Collaborator

`DELETE /api/v1/projects/:project_id/collaborations/:id`

**Response:**

```
204 No Content
```

---

## Messaging

### List Messages

`GET /api/v1/messages`

**Query Parameters:**
| Name | Type | Required | Default | Description |
|------------|---------|----------|---------|---------------------|
| project_id | integer | No | | Filter by project |
| user_id | integer | No | | Filter by sender |
| unread | boolean | No | | Only unread |
| page | integer | No | 1 | Pagination page |
| limit/per_page | integer | No | 20 | Results per page |

### Get Message

`GET /api/v1/messages/:id`

**Response:**

```
200 OK
{
  "id": 1,
  "content": "Hello!",
  ...
}
```

### Send Message

`POST /api/v1/messages`

**Body:**
Root key: `message` (object)
| Field | Type | Required | Description |
|-------------|---------|----------|---------------------|
| receiver_id | integer | Yes | Recipient user |
| content | string | Yes | Message text |
| project_id | integer | No | Project context |

### Mark Message as Read

`PATCH /api/v1/messages/:id/read`

**Response:**

```
200 OK
{
  "message": "Message marked as read",
  ...
}
```

---

## Funding

### List Funding Requests

`GET /api/projects/:project_id/fund`

**Query Parameters:**
| Name | Type | Required | Default | Description |
|----------|---------|----------|---------|---------------------|
| page | integer | No | 1 | Pagination page |
| per_page | integer | No | 20 | Results per page |

### Create Funding Request

`POST /api/projects/:project_id/fund/request`

**Body:**
Root key: `funding_request` (object)
| Field | Type | Required | Description |
|---------|---------|----------|---------------------|
| amount | decimal | Yes | Amount requested |
| note | string | No | Optional note |

### Approve Funding Request

`POST /api/projects/:project_id/fund/verify`

**Body or Query:**
| Field | Type | Required | Description |
|---------|---------|----------|---------------------|
| id | integer | Yes | Funding request id |

### Reject Funding Request

`POST /api/projects/:project_id/fund/reject`

**Body or Query:**
| Field | Type | Required | Description |
|---------|---------|----------|---------------------|
| id | integer | Yes | Funding request id |

### Fund a Project

`POST /api/v1/funds`

**Body:**
| Field | Type | Required | Description |
|---------|---------|----------|---------------------|
| amount | decimal | Yes | Amount to fund |

---

## Notifications

### List Notifications

`GET /api/v1/notifications`

**Query Parameters:**
| Name | Type | Required | Default | Description |
|----------|---------|----------|---------|---------------------|
| unread | boolean | No | | Only unread |
| read | boolean | No | | Only read |
| type | string | No | | Filter by type |
| page | integer | No | 1 | Pagination page |
| per_page | integer | No | 20 | Results per page |

### Mark Notification as Read

`POST /api/v1/notifications/:id/read`

**URL Param:**
| Name | Type | Required |
|------|---------|----------|
| id | integer | Yes |

### Mark Notification as Unread

`POST /api/v1/notifications/:id/unread`

**URL Param:**
| Name | Type | Required |
|------|---------|----------|
| id | integer | Yes |

### Mark All as Read

`POST /api/v1/notifications/read_all`
No params.

### Delete Notification

`DELETE /api/v1/notifications/:id`

**URL Param:**
| Name | Type | Required |
|------|---------|----------|
| id | integer | Yes |

---

## Audit Logs

### List Audit Logs

`GET /api/audit_logs`

**Access:** Admin only. No parameters.

---

## Other Endpoints

### Suggestions & Autocomplete

#### University Autocomplete

- `GET /api/v1/suggestions/universities?query=abc` — Returns a static list of university suggestions, filtered by `query` (not user data).
- `GET /api/v1/users/autocomplete/universities?term=abc` — Returns a dynamic list of universities from user data, filtered by `term`.

#### Department Autocomplete

- `GET /api/v1/suggestions/departments?query=xyz` — Returns a static list of department suggestions, filtered by `query`.
- **There is currently NO endpoint for `/api/v1/users/autocomplete/departments` (dynamic from user data).**

#### Country Autocomplete

- `GET /api/v1/suggestions/countries?query=xyz` — Returns a static list of country suggestions, filtered by `query`.
- `GET /api/v1/users/autocomplete/countries?term=xyz` — Returns a dynamic list of countries from user data, filtered by `term`.

#### Tag Suggestions

- `GET /api/v1/suggestions/tags?query=xyz` — Returns a static list of tag suggestions, filtered by `query`.

#### User Autocomplete/Search

- **There is currently NO endpoint for user autocomplete or search.** Users can only be listed via `/api/users` (with pagination) or fetched by ID. If you need user search/autocomplete, you must add a new API.

##### Project Leaderboard

`GET /api/v1/leaderboards/projects`

**Query Parameters:**
| Name | Type | Required | Description |
|------------ |--------|----------|-----------------------------------|
| q | string | No | Search by project title/desc |
| university | string | No | Filter by university |
| department | string | No | Filter by department |
| limit | int | No | Max results (default 10) |

##### User Leaderboard

`GET /api/v1/leaderboards/users`

**Query Parameters:**
| Name | Type | Required | Description |
|------------ |--------|----------|-----------------------------------|
| q | string | No | Search by user name |
| university | string | No | Filter by university |
| department | string | No | Filter by department |
| limit | int | No | Max results (default 10) |

##### Most Viewed Projects

`GET /api/v1/leaderboards/most_viewed`

**Query Parameters:**
| Name | Type | Required | Description |
|------------ |--------|----------|-----------------------------------|
| q | string | No | Search by project title/desc |
| university | string | No | Filter by university |
| department | string | No | Filter by department |
| limit | int | No | Max results (default 10) |
| page | int | No | Pagination page |
| per_page | int | No | Results per page |

---

**API Planning Note:**

- If you need dynamic department autocomplete (from user data), or user search/autocomplete, you must implement new endpoints. The current API only supports static suggestions for departments and tags, and dynamic autocomplete for universities/countries (from user data only).

---

---

## Other Endpoints

### Suggestions & Autocomplete

#### University Autocomplete

- `GET /api/v1/suggestions/universities?query=abc` — Static list (not user data)
- `GET /api/v1/users/autocomplete/universities?term=abc` — Dynamic from user data

#### Department Autocomplete

- `GET /api/v1/suggestions/departments?query=xyz` — Static list
- **No dynamic department autocomplete endpoint.**

#### Country Autocomplete

- `GET /api/v1/suggestions/countries?query=xyz` — Static list
- `GET /api/v1/users/autocomplete/countries?term=xyz` — Dynamic from user data

#### Tag Suggestions

- `GET /api/v1/suggestions/tags?query=xyz` — Static list

#### User Autocomplete/Search

- **No endpoint for user autocomplete or search.**

### Comments

- `GET /api/v1/projects/:project_id/comments` — List comments for a project
- `POST /api/v1/projects/:project_id/comments` — Create comment
- `PUT /api/v1/projects/:project_id/comments/:id` — Update comment
- `DELETE /api/v1/projects/:project_id/comments/:id` — Delete comment

### Resources

- `GET /api/v1/projects/:project_id/resources` — List resources
- `POST /api/v1/projects/:project_id/resources` — Create resource
- `PUT /api/v1/projects/:project_id/resources/:id` — Update resource
- `DELETE /api/v1/projects/:project_id/resources/:id` — Delete resource

### Funds

- `GET /api/v1/projects/:project_id/funds` — List funds
- `POST /api/v1/projects/:project_id/funds` — Create fund

### Tags

- `GET /api/v1/tags` — List tags
- `POST /api/v1/tags` — Create tag

### Dashboard & Stats

- `GET /api/v1/dashboard/statistics` — Platform statistics
- `GET /api/v1/stats/projects/:id` — Project stats

### Voting

- `POST /api/v1/projects/:id/vote` — Upvote project
- `DELETE /api/v1/projects/:id/vote` — Remove upvote

### Messages (Extra)

- `GET /api/v1/messages/unread_count` — Count of unread messages
- `GET /api/v1/messages/:project_id` — Project chat history

### User Profile

- `GET /api/v1/users/profile` — Current user's profile

### Reports

- `POST /api/v1/reports` — Create report
- `GET /api/v1/reports/my_reports` — List my reports

### Admin APIs (Detailed)

#### Users

##### List Users

`GET /api/v1/admin/users`

**Query Parameters:**
| Name | Type | Required | Description |
|-----------|---------|----------|----------------------------|
| page | integer | No | Pagination page |
| per_page | integer | No | Results per page |
| filter | string | No | Filter by role/status/etc. |

**Response:**

```
200 OK
{
  "data": [ ...user objects... ],
  "meta": { ...pagination... }
}
```

##### Show User

`GET /api/v1/admin/users/:id`

**URL Param:**
| Name | Type | Required |
|------|---------|----------|
| id | integer | Yes |

**Response:** User object.

##### Update User

`PUT /api/v1/admin/users/:id`

**URL Param:**
| Name | Type | Required |
|------|---------|----------|
| id | integer | Yes |

**Body:**
Root key: `user` (object)

| Field     | Type   | Required | Description     |
| --------- | ------ | -------- | --------------- |
| full_name | string | No       |                 |
| email     | string | No       |                 |
| ...       | ...    | ...      | All user fields |

##### Delete User

`DELETE /api/v1/admin/users/:id`

**URL Param:**
| Name | Type | Required |
|------|---------|----------|
| id | integer | Yes |

**Response:**

```
204 No Content
```

##### Suspend/Unsuspend User

`POST /api/v1/admin/users/:id/suspend`
`POST /api/v1/admin/users/:id/unsuspend`

**URL Param:**
| Name | Type | Required |
|------|---------|----------|
| id | integer | Yes |

**Response:**

```
200 OK
{
  "message": "User suspended/unsuspended"
}
```

##### User Filter Options

`GET /api/v1/admin/users/filters`
`GET /api/v1/admin/users/filter_options`

**Response:**

```
200 OK
{
  "roles": [...],
  "statuses": [...],
  ...
}
```

##### Universities/Departments by Country/University

`GET /api/v1/admin/users/universities_by_country?country=xyz`
`GET /api/v1/admin/users/departments_by_university?university=abc`

**Query Parameters:**
| Name | Type | Required | Description |
|-----------|--------|----------|-------------|
| country | string | Yes | For universities_by_country |
| university| string | Yes | For departments_by_university |

**Response:**

```
200 OK
{
  "universities": [...],
  "departments": [...]
}
```

#### Projects

##### List Projects

`GET /api/v1/admin/projects`

**Query Parameters:**
| Name | Type | Required | Description |
|-----------|---------|----------|----------------------------|
| page | integer | No | Pagination page |
| per_page | integer | No | Results per page |
| filter | string | No | Filter by status/etc. |

**Response:**

```
200 OK
{
  "data": [ ...project objects... ],
  "meta": { ...pagination... }
}
```

### List/Search Projects

`GET /api/v1/projects`

**Query Parameters:**
| Name | Type | Required | Default | Description |
|-----------|---------|----------|---------|-----------------------------------|
| q | string | No | | Search by title/description |
| status | string | No | | Filter by status |
| visibility| string | No | | Filter by visibility |
| tags | string | No | | Comma-separated tag names |
| university| string | No | | Filter by university |
| department| string | No | | Filter by department |
| sort | string | No | | 'votes', 'views', 'oldest', etc. |
| page | integer | No | 1 | Pagination page |
| per_page | integer | No | 25 | Results per page |

**Response:**

```
200 OK
{
  "data": [ ...project objects... ],
  "meta": { ...pagination... }
}
```

| Field | Type   | Required | Description        |
| ----- | ------ | -------- | ------------------ |
| title | string | No       |                    |
| ...   | ...    | ...      | All project fields |

##### Delete Project

`DELETE /api/v1/admin/projects/:id`

**URL Param:**
| Name | Type | Required |
|------|---------|----------|
| id | integer | Yes |

**Response:**

```
204 No Content
```

##### Feature/Unfeature Project

`POST /api/v1/admin/projects/:id/feature`
`POST /api/v1/admin/projects/:id/unfeature`

**URL Param:**
| Name | Type | Required |
|------|---------|----------|
| id | integer | Yes |

**Response:**

```
200 OK
{
  "message": "Project featured/unfeatured"
}
```

##### Project Filter Options

`GET /api/v1/admin/projects/filters`
`GET /api/v1/admin/projects/filter_options`

**Response:**

```
200 OK
{
  "statuses": [...],
  ...
}
```

##### Universities/Departments by Country/University

`GET /api/v1/admin/projects/universities_by_country?country=xyz`
`GET /api/v1/admin/projects/departments_by_university?university=abc`

**Query Parameters:**
| Name | Type | Required | Description |
|-----------|--------|----------|-------------|
| country | string | Yes | For universities_by_country |
| university| string | Yes | For departments_by_university |

**Response:**

```
200 OK
{
  "universities": [...],
  "departments": [...]
}
```

#### Reports

##### List Reports

`GET /api/v1/admin/reports`

**Query Parameters:**
| Name | Type | Required | Description |
|-----------|---------|----------|----------------------------|
| page | integer | No | Pagination page |
| per_page | integer | No | Results per page |

**Response:**

```
200 OK
{
  "data": [ ...report objects... ],
  "meta": { ...pagination... }
}
```

##### Show Report

`GET /api/v1/admin/reports/:id`

**URL Param:**
| Name | Type | Required |
|------|---------|----------|
| id | integer | Yes |

**Response:** Report object.

##### Resolve/Dismiss Report

`PATCH /api/v1/admin/reports/:id/resolve`
`PATCH /api/v1/admin/reports/:id/dismiss`

**URL Param:**
| Name | Type | Required |
|------|---------|----------|
| id | integer | Yes |

**Response:**

```
200 OK
{
  "message": "Report resolved/dismissed"
}
```

##### Report Stats

`GET /api/v1/admin/reports/stats`

**Response:**

```
200 OK
{
  "open": 5,
  "resolved": 10,
  ...
}
```

#### Moderation

##### List Moderation Reports

`GET /api/v1/admin/moderation/reports`

**Query Parameters:**
| Name | Type | Required | Description |
|-----------|---------|----------|----------------------------|
| page | integer | No | Pagination page |
| per_page | integer | No | Results per page |

**Response:**

```
200 OK
{
  "data": [ ...moderation report objects... ],
  "meta": { ...pagination... }
}
```

##### Update Moderation Report

`PATCH /api/v1/admin/moderation/reports/:id`

**URL Param:**
| Name | Type | Required |
|------|---------|----------|
| id | integer | Yes |

**Body:**
| Field | Type | Required | Description |
|------------|---------|----------|---------------------|
| status | string | No | New status |
| note | string | No | Moderator note |

##### Resolve Moderation Report

`POST /api/v1/admin/moderation/reports/:id/resolve`

**URL Param:**
| Name | Type | Required |
|------|---------|----------|
| id | integer | Yes |

**Response:**

```
200 OK
{
  "message": "Moderation report resolved"
}
```

##### Suspend/Unsuspend User (Moderation)

`POST /api/v1/admin/moderation/users/:id/suspend`
`POST /api/v1/admin/moderation/users/:id/unsuspend`

**URL Param:**
| Name | Type | Required |
|------|---------|----------|
| id | integer | Yes |

**Response:**

```
200 OK
{
  "message": "User suspended/unsuspended"
}
```

##### Hide/Unhide Project

`POST /api/v1/admin/moderation/projects/:id/hide`
`POST /api/v1/admin/moderation/projects/:id/unhide`

**URL Param:**
| Name | Type | Required |
|------|---------|----------|
| id | integer | Yes |

**Response:**

```
200 OK
{
  "message": "Project hidden/unhidden"
}
```

##### Hide/Unhide Comment

`POST /api/v1/admin/moderation/comments/:id/hide`
`POST /api/v1/admin/moderation/comments/:id/unhide`

**URL Param:**
| Name | Type | Required |
|------|---------|----------|
| id | integer | Yes |

**Response:**

```
200 OK
{
  "message": "Comment hidden/unhidden"
}
```

##### Moderation Stats

`GET /api/v1/admin/moderation/stats`

**Response:**

```
200 OK
{
  "open": 3,
  "resolved": 7,
  ...
}
```

#### Analytics & Dashboard

##### Platform Stats

`GET /api/v1/admin/stats`

**Response:**

```
200 OK
{
  "users": 100,
  "projects": 50,
  ...
}
```

##### Analytics Overview

`GET /api/v1/admin/analytics`

**Response:**

```
200 OK
{
  "growth": {...},
  ...
}
```

##### Growth Analytics

`GET /api/v1/admin/analytics/growth`

**Response:**

```
200 OK
{
  "users": [...],
  "projects": [...],
  ...
}
```

#### Audit Logs

##### List Audit Logs

`GET /api/v1/admin/audit_logs`

**Query Parameters:**
| Name | Type | Required | Description |
|-----------|---------|----------|----------------------------|
| page | integer | No | Pagination page |
| per_page | integer | No | Results per page |

**Response:**

```
200 OK
{
  "data": [ ...audit log objects... ],
  "meta": { ...pagination... }
}
```

##### Audit Log Stats

`GET /api/v1/admin/audit_logs/stats`

**Response:**

```
200 OK
{
  "total": 100,
  ...
}
```

#### API Logs

##### List API Logs

`GET /api/v1/admin/api_logs`

**Query Parameters:**
| Name | Type | Required | Description |
|-----------|---------|----------|----------------------------|
| page | integer | No | Pagination page |
| per_page | integer | No | Results per page |

**Response:**

```
200 OK
{
  "data": [ ...api log objects... ],
  "meta": { ...pagination... }
}
```

##### Show API Log

`GET /api/v1/admin/api_logs/:id`

**URL Param:**
| Name | Type | Required |
|------|---------|----------|
| id | integer | Yes |

**Response:** API log object.

##### API Log Stats

`GET /api/v1/admin/api_logs/stats`

**Response:**

```
200 OK
{
  "total": 1000,
  ...
}
```

##### Cleanup API Logs

`DELETE /api/v1/admin/api_logs/cleanup`

**Response:**

```
200 OK
{
  "message": "API logs cleaned up"
}
```

#### Database Management

##### Run DB Seeds

`POST /api/v1/admin/database/run_seeds`

**Response:**

```
200 OK
{
  "message": "Seeds run"
}
```

##### Reset Database

`POST /api/v1/admin/database/reset`

**Response:**

```
200 OK
{
  "message": "Database reset"
}
```

#### Leaderboards (Admin)

##### Leaderboard Filter Options

`GET /api/v1/admin/leaderboard/filter_options`

**Response:**

```
200 OK
{
  "filters": {...}
}
```

##### Universities/Departments by Country/University

`GET /api/v1/admin/leaderboard/universities_by_country?country=xyz`
`GET /api/v1/admin/leaderboard/departments_by_university?university=abc`

**Query Parameters:**
| Name | Type | Required | Description |
|-----------|--------|----------|-------------|
| country | string | Yes | For universities_by_country |
| university| string | Yes | For departments_by_university |

**Response:**

```
200 OK
{
  "universities": [...],
  "departments": [...]
}
```

##### Most Viewed/Voted/Commented Projects, Most Active Collaborators, Most Funded Projects, Top Funders

`GET /api/v1/admin/leaderboard/most_viewed_projects`
`GET /api/v1/admin/leaderboard/most_voted_projects`
`GET /api/v1/admin/leaderboard/most_commented_projects`
`GET /api/v1/admin/leaderboard/most_active_collaborators`
`GET /api/v1/admin/leaderboard/most_funded_projects`
`GET /api/v1/admin/leaderboard/top_funders`

**Response:**

```
200 OK
{
  "data": [...],
  "meta": { ...pagination... }
}
```

---

**API Planning Note:**

- Filtering and search are now available for users (`name`, `email`), projects (`q`, `status`, `visibility`, `tags`, `university`, `department`), and leaderboards (`q`, `university`, `department`).
- Leaderboard endpoints use `limit` for result count (default 10).
- If you need dynamic department autocomplete (from user data), you must implement a new endpoint. The current API only supports static suggestions for departments and tags, and dynamic autocomplete for universities/countries (from user data only).
- All endpoints are prefixed with `/api/`.
- Most endpoints require authentication (see above).
- Pagination is supported on all list endpoints via `page` and `per_page`/`limit`.
- For more details, see controller files in `app/controllers/api/` and models in `app/models/`.

---

For further details, refer to the codebase or contact the backend team.
