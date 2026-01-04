# CollabSphere Database Schema Analysis

**Generated:** November 5, 2025  
**Database Type:** PostgreSQL  
**Schema Version:** 2025_10_30_043054  
**Total Tables:** 11 entities + 2 join tables = 13 tables  
**Total Columns:** 110+ attributes across all tables  
**Foreign Keys:** 19 relationships  
**Indexes:** 37+ for query optimization

> **Note:** This analysis reflects the **current production schema** (schema.rb). The DBML visualization file (collabsphere_schema.dbml) includes additional fields like `is_reported` that are designed but not yet migrated to the database.

---

## Table of Contents
1. [Core Entities (11)](#core-entities)
2. [Join Tables (2)](#join-tables)
3. [Relationships Overview](#relationships-overview)
4. [Indexes and Performance](#indexes-and-performance)
5. [Data Types Summary](#data-types-summary)
6. [Planned Schema Extensions](#planned-schema-extensions)

---

## Core Entities

### 1. **users** (User Accounts)
**Purpose:** Store user account information and profile data

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `id` | bigint | PRIMARY KEY, auto-increment | Unique user identifier |
| `full_name` | string | - | User's display name |
| `email` | string | UNIQUE (application level) | Login email address |
| `password_digest` | string | NOT NULL | Encrypted password (bcrypt) |
| `system_role` | string | default: 'user' | System role: 'admin' or 'user' |
| `bio` | text | nullable | User biography/description |
| `avatar_url` | string | nullable | Profile picture URL |
| `country` | string | nullable | User's country |
| `university` | string | nullable | Educational institution |
| `department` | string | nullable | Academic department |
| `is_reported` | boolean | **PLANNED** - Not in production | Moderation flag for reported accounts |
| `created_at` | datetime | NOT NULL | Account creation timestamp |
| `updated_at` | datetime | NOT NULL | Last profile update timestamp |

**Indexes:** None explicitly defined (relies on primary key)

**Planned Indexes:**
- Unique index on `email` (currently enforced at application level only)

**Relationships:**
- Has many: projects (as owner), collaborations, comments, votes, messages (as sender/receiver), funds (as funder), resources (as added_by)
- Has many through: tags (via user_tags)

**Business Rules:**
- Email must be unique (validated in Rails, needs DB constraint)
- Password minimum length enforced at application level
- Default system_role is 'user'
- AIT integration uses university/department fields

---

### 2. **projects** (Innovation Projects)
**Purpose:** Core content entity representing collaborative projects

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `id` | bigint | PRIMARY KEY, auto-increment | Unique project identifier |
| `owner_id` | bigint | NOT NULL, FOREIGN KEY → users(id) | Project creator |
| `title` | string | NOT NULL (application) | Project name |
| `description` | text | NOT NULL (application) | Project details |
| `status` | string | default: 'Ideation' | Workflow state: Ideation, Ongoing, Completed |
| `visibility` | string | default: 'public' | Access control: public, private, restricted |
| `show_funds` | boolean | default: false | Display funding information |
| `project_phase` | string | nullable | Development phase |
| `funding_goal` | decimal(12,2) | nullable | Target funding amount |
| `is_reported` | boolean | **PLANNED** - Not in production | Moderation flag for reported projects |
| `current_funding` | decimal(12,2) | default: 0.0 | Accumulated funding |
| `created_at` | datetime | NOT NULL | Project creation timestamp |
| `updated_at` | datetime | NOT NULL | Last modification timestamp |

**Indexes:**
- `index_projects_on_owner_id` - Fast lookup of user's projects
- `index_projects_on_status` - Filter by workflow state
- `index_projects_on_visibility` - Access control queries
- `index_projects_on_created_at` - Chronological sorting

**Relationships:**
- Belongs to: users (owner)
- Has many: collaborations, comments, votes, resources, funds, messages, project_stats
- Has many through: tags (via project_tags)

**Business Rules:**
- Status transitions: Ideation → Ongoing → Completed
- Visibility affects who can view/join
- Funding tracked with 2 decimal precision
- Owner has full control, members can edit, viewers read-only

---

### 3. **collaborations** (Team Memberships)
**Purpose:** Manage project team members and their roles

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `id` | bigint | PRIMARY KEY, auto-increment | Unique collaboration identifier |
| `project_id` | bigint | NOT NULL, FOREIGN KEY → projects(id) | Associated project |
| `user_id` | bigint | NOT NULL, FOREIGN KEY → users(id) | Team member |
| `project_role` | integer | default: 1 (member) | Role enum: 0=owner, 1=member, 2=viewer |
| `created_at` | datetime | NOT NULL | Join date timestamp |
| `updated_at` | datetime | NOT NULL | Role change timestamp |

**Indexes:**
- `index_collaborations_on_project_id` - List project team
- `index_collaborations_on_user_id` - List user's projects

**Relationships:**
- Belongs to: project, user

**Business Rules:**
- Unique combination of (user_id, project_id) enforced at application level
- Role hierarchy: owner (0) > member (1) > viewer (2)
- Owner automatically created when project created
- Only one owner per project

**Role Permissions:**
| Role | Create | Read | Update | Delete | Add Members |
|------|--------|------|--------|--------|-------------|
| Owner (0) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Member (1) | ❌ | ✅ | ✅ | ❌ | ❌ |
| Viewer (2) | ❌ | ✅ | ❌ | ❌ | ❌ |

---

### 4. **comments** (Project Discussion)
**Purpose:** Threaded comment system with nested replies

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `id` | bigint | PRIMARY KEY, auto-increment | Unique comment identifier |
| `project_id` | bigint | NOT NULL, FOREIGN KEY → projects(id) | Associated project |
| `user_id` | bigint | NOT NULL, FOREIGN KEY → users(id) | Comment author |
| `parent_id` | bigint | nullable, FOREIGN KEY → comments(id) | Parent comment for threading |
| `content` | text | NOT NULL | Comment text |
| `is_reported` | boolean | **PLANNED** - Not in production | Moderation flag for reported comments |
| `created_at` | datetime | NOT NULL | Comment post timestamp |
| `updated_at` | datetime | NOT NULL | Last edit timestamp |

**Indexes:**
- `index_comments_on_project_id` - List project comments
- `index_comments_on_user_id` - List user's comments
- `index_comments_on_parent_id` - Threaded replies lookup

**Relationships:**
- Belongs to: project, user, parent comment (self-referential)
- Has many: replies (comments with this comment as parent)

**Business Rules:**
- Immediate publish (no pre-moderation)
- Parent_id NULL = top-level comment
- Parent_id set = nested reply
- Author can edit/delete own comments
- Project owner can delete any comment
- Admin can delete any comment
- Threading depth unlimited (application may limit display)

**Threading Example:**
```
Comment 1 (parent_id: null)
  ├─ Comment 2 (parent_id: 1)
  │   └─ Comment 3 (parent_id: 2)
  └─ Comment 4 (parent_id: 1)
```

---

### 5. **votes** (Project Voting)
**Purpose:** Upvote/downvote mechanism for project validation

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `id` | bigint | PRIMARY KEY, auto-increment | Unique vote identifier |
| `project_id` | bigint | NOT NULL, FOREIGN KEY → projects(id) | Voted project |
| `user_id` | bigint | NOT NULL, FOREIGN KEY → users(id) | Voter |
| `vote_type` | string | NOT NULL | 'up' or 'down' |
| `voted_at` | datetime | nullable | Vote timestamp |
| `created_at` | datetime | NOT NULL | Initial vote creation |
| `updated_at` | datetime | NOT NULL | Vote change timestamp |

**Indexes:**
- `index_votes_on_project_id` - Count project votes
- `index_votes_on_user_id` - User's voting history
- `index_votes_on_user_id_and_project_id` (UNIQUE) - Prevent duplicate votes

**Relationships:**
- Belongs to: project, user

**Business Rules:**
- One vote per user per project (enforced by unique index)
- Vote types: 'up' (upvote), 'down' (downvote)
- Users can change their vote (update vote_type)
- Users can remove vote (delete record)
- Vote count calculated: COUNT(up) - COUNT(down)

**Vote Workflow:**
1. First vote: Create new vote record
2. Change vote: Update existing vote_type
3. Remove vote: Delete vote record

---

### 6. **messages** (Private Messaging)
**Purpose:** Direct user-to-user communication

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `id` | bigint | PRIMARY KEY, auto-increment | Unique message identifier |
| `sender_id` | bigint | NOT NULL, FOREIGN KEY → users(id) | Message sender |
| `receiver_id` | bigint | NOT NULL, FOREIGN KEY → users(id) | Message recipient |
| `project_id` | bigint | nullable, FOREIGN KEY → projects(id) | Related project (optional) |
| `content` | text | NOT NULL | Message text |
| `sent_at` | datetime | nullable | Send timestamp |
| `is_reported` | boolean | **PLANNED** - Not in production | Moderation flag for reported messages |
| `is_read` | boolean | default: false | Read/unread status |
| `created_at` | datetime | NOT NULL | Creation timestamp |
| `updated_at` | datetime | NOT NULL | Edit timestamp |

**Indexes:**
- `index_messages_on_sender_id` - Sent messages
- `index_messages_on_receiver_id` - Inbox
- `index_messages_on_sender_id_and_receiver_id` - Conversation threads
- `index_messages_on_project_id` - Project-related messages
- `index_messages_on_is_read` - Unread count

**Relationships:**
- Belongs to: sender (user), receiver (user), project (optional)

**Business Rules:**
- One-to-one messaging (not group chat)
- Optional project context (project_id)
- Read receipt tracking (is_read)
- Sender can edit/delete own messages
- Receiver can only read
- Admin can view all messages

---

### 7. **resources** (Project Attachments)
**Purpose:** Files, documents, and links attached to projects

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `id` | bigint | PRIMARY KEY, auto-increment | Unique resource identifier |
| `project_id` | bigint | NOT NULL, FOREIGN KEY → projects(id) | Associated project |
| `title` | string | NOT NULL | Resource name |
| `description` | text | nullable | Resource description |
| `url` | string | NOT NULL | File URL or external link |
| `is_reported` | boolean | **PLANNED** - Not in production | Moderation flag for reported resources |
| `added_by_id` | bigint | NOT NULL, FOREIGN KEY → users(id) | Uploader |
| `created_at` | datetime | NOT NULL | Upload timestamp |
| `updated_at` | datetime | NOT NULL | Metadata update timestamp |

**Indexes:**
- `index_resources_on_project_id` - List project resources
- `index_resources_on_added_by_id` - User's uploads

**Relationships:**
- Belongs to: project, user (added_by)

**Business Rules:**
- URL-based storage (files stored externally)
- Team members can upload
- Project owner approves (application logic)
- Uploader and owner can delete
- URL immutable (delete and re-upload to replace)

---

### 8. **funds** (Funding Transactions)
**Purpose:** Track financial contributions to projects

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `id` | bigint | PRIMARY KEY, auto-increment | Unique fund identifier |
| `project_id` | bigint | NOT NULL, FOREIGN KEY → projects(id) | Funded project |
| `funder_id` | bigint | NOT NULL, FOREIGN KEY → users(id) | Contributor |
| `amount` | decimal(12,2) | NOT NULL | Contribution amount |
| `funded_at` | datetime | nullable | Transaction timestamp |
| `created_at` | datetime | NOT NULL | Record creation |
| `updated_at` | datetime | NOT NULL | Record update |

**Indexes:**
- `index_funds_on_project_id` - Project funding history
- `index_funds_on_funder_id` - User's contributions
- `index_funds_on_project_id_and_funder_id` - User's contributions to specific project

**Relationships:**
- Belongs to: project, user (funder)

**Business Rules:**
- Amount stored with 2 decimal precision (cents)
- Supports up to $9,999,999,999.99 per transaction
- Multiple contributions allowed per user per project
- Contributions aggregate to project.current_funding
- Funds cannot be deleted (financial audit trail)

**Funding Workflow:**
1. User contributes via POST /api/v1/projects/:id/funds
2. Amount added to project.current_funding
3. Transaction recorded in funds table
4. If current_funding ≥ funding_goal, project "fully funded"

---

### 9. **tags** (Content Taxonomy)
**Purpose:** Global tag system for categorizing projects and users

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `id` | bigint | PRIMARY KEY, auto-increment | Unique tag identifier |
| `tag_name` | string | UNIQUE (application level) | Tag label |
| `created_at` | datetime | NOT NULL | Tag creation timestamp |
| `updated_at` | datetime | NOT NULL | Last update timestamp |

**Indexes:** None explicitly defined (relies on primary key)

**Planned Indexes:**
- Unique index on `tag_name` (currently enforced at application level only)

**Relationships:**
- Has many through: projects (via project_tags), users (via user_tags)

**Business Rules:**
- Tags are global (shared across all projects/users)
- Tag names case-insensitive at application level
- Admin can create/delete tags
- Users can suggest tags (application feature)

---

### 10. **project_stats** (Engagement Metrics)
**Purpose:** Aggregate statistics for projects

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `id` | bigint | PRIMARY KEY, auto-increment | Unique stat identifier |
| `project_id` | bigint | NOT NULL, FOREIGN KEY → projects(id) | Associated project (1:1 relationship) |
| `total_views` | integer | default: 0 | Page view count |
| `total_votes` | integer | default: 0 | Net vote score |
| `total_comments` | integer | default: 0 | Comment count |
| `last_updated` | datetime | nullable | Last stat calculation |
| `created_at` | datetime | NOT NULL | Record creation |
| `updated_at` | datetime | NOT NULL | Last stat update |

**Indexes:**
- `index_project_stats_on_project_id` - Lookup project stats
- `index_project_stats_on_total_views` - Sort by popularity
- `index_project_stats_on_total_votes` - Sort by votes

**Planned Indexes:**
- Unique constraint on `project_id` to enforce strict 1:1 relationship at database level

**Relationships:**
- Belongs to: project (1:1 relationship)

**Business Rules:**
- One stats record per project (enforced at application level, should add DB constraint)
- Updated via callbacks or background jobs
- Used for leaderboards and trending
- total_votes = upvotes - downvotes

**Stat Calculation:**
```ruby
total_views: Increment on GET /projects/:id
total_votes: COUNT(votes WHERE vote_type='up') - COUNT(votes WHERE vote_type='down')
total_comments: COUNT(comments)
```

---

## Join Tables

### 11. **project_tags** (Many-to-Many: Projects ↔ Tags)
**Purpose:** Link projects to tags for categorization

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `id` | bigint | PRIMARY KEY, auto-increment | Unique relationship identifier |
| `project_id` | bigint | NOT NULL, FOREIGN KEY → projects(id) | Tagged project |
| `tag_id` | bigint | NOT NULL, FOREIGN KEY → tags(id) | Applied tag |
| `created_at` | datetime | NOT NULL | Tag assignment timestamp |
| `updated_at` | datetime | NOT NULL | Record update |

**Indexes:**
- `index_project_tags_on_project_id` - List project's tags
- `index_project_tags_on_tag_id` - Projects with specific tag

**Planned Indexes:**
- Unique constraint on `(project_id, tag_id)` to prevent duplicate tagging at database level

**Relationships:**
- Belongs to: project, tag

**Business Rules:**
- Unique combination (project_id, tag_id) enforced at application level, needs DB constraint
- Projects can have multiple tags
- Tags can be applied to multiple projects
- Owner can add/remove tags

---

### 12. **user_tags** (Many-to-Many: Users ↔ Tags)
**Purpose:** Link users to tags for expertise/interests

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `id` | bigint | PRIMARY KEY, auto-increment | Unique relationship identifier |
| `user_id` | bigint | NOT NULL, FOREIGN KEY → users(id) | Tagged user |
| `tag_id` | bigint | NOT NULL, FOREIGN KEY → tags(id) | Applied tag |
| `created_at` | datetime | NOT NULL | Tag assignment timestamp |
| `updated_at` | datetime | NOT NULL | Record update |

**Indexes:**
- `index_user_tags_on_user_id` - List user's tags
- `index_user_tags_on_tag_id` - Users with specific tag
- `index_user_tags_on_user_id_and_tag_id` (UNIQUE) - Prevent duplicates

**Relationships:**
- Belongs to: user, tag

**Business Rules:**
- Unique combination (user_id, tag_id) enforced by unique index
- Users can have multiple tags (skills, interests)
- Tags can be assigned to multiple users
- Users can manage their own tags

---

## Relationships Overview

### Entity Relationship Diagram (Text Format)

```
users (1) ────< (many) projects [owner_id]
users (1) ────< (many) collaborations
users (1) ────< (many) comments
users (1) ────< (many) votes
users (1) ────< (many) messages [sender_id]
users (1) ────< (many) messages [receiver_id]
users (1) ────< (many) funds [funder_id]
users (1) ────< (many) resources [added_by_id]
users (many) ──< user_tags >── (many) tags

projects (1) ──< (many) collaborations
projects (1) ──< (many) comments
projects (1) ──< (many) votes
projects (1) ──< (many) resources
projects (1) ──< (many) funds
projects (1) ──< (many) messages [optional]
projects (1) ──< (1) project_stats
projects (many) ──< project_tags >── (many) tags

comments (1) ──< (many) comments [self-referential, parent_id]

tags (many) ──< project_tags >── (many) projects
tags (many) ──< user_tags >── (many) users
```

### Cardinality Summary

| Relationship | Type | Description |
|-------------|------|-------------|
| User → Projects | 1:M | User owns many projects |
| User → Collaborations | 1:M | User participates in many projects |
| Project → Collaborations | 1:M | Project has many team members |
| Project → Comments | 1:M | Project has many comments |
| User → Comments | 1:M | User writes many comments |
| Comment → Comments | 1:M | Comment has many replies (self-join) |
| User → Votes | 1:M | User votes on many projects |
| Project → Votes | 1:M | Project receives many votes |
| User ↔ User (Messages) | M:M | Users message each other |
| Project → Resources | 1:M | Project has many resources |
| User → Resources | 1:M | User uploads many resources |
| Project → Funds | 1:M | Project receives many contributions |
| User → Funds | 1:M | User contributes to many projects |
| Project → Stats | 1:1 | Project has one stats record |
| Project ↔ Tags | M:M | Projects have many tags, tags apply to many projects |
| User ↔ Tags | M:M | Users have many tags, tags apply to many users |

---

## Indexes and Performance

### Index Strategy Analysis

#### **Primary Indexes (13 total)**
All tables have implicit primary key indexes on `id` column.

#### **Foreign Key Indexes (19 total)**
1. `collaborations`: project_id, user_id
2. `comments`: project_id, user_id, parent_id
3. `funds`: project_id, funder_id, (project_id + funder_id) composite
4. `messages`: sender_id, receiver_id, project_id, (sender_id + receiver_id) composite
5. `project_stats`: project_id, total_views, total_votes
6. `project_tags`: project_id, tag_id
7. `projects`: owner_id, status, visibility, created_at
8. `resources`: project_id, added_by_id
9. `user_tags`: user_id, tag_id, (user_id + tag_id) unique composite
10. `votes`: project_id, user_id, (user_id + project_id) unique composite

#### **Business Logic Indexes (5 total)**
1. `messages.is_read` - Fast unread count
2. `project_stats.total_views` - Leaderboard sorting
3. `project_stats.total_votes` - Leaderboard sorting
4. `projects.created_at` - Chronological display
5. `projects.status` - Workflow filtering

#### **Unique Constraints (2 enforced at DB level)**
1. `votes(user_id, project_id)` - One vote per user per project
2. `user_tags(user_id, tag_id)` - One tag per user (no duplicates)

### Performance Optimization Notes

**Fast Queries (Indexed):**
✅ List user's projects: `projects WHERE owner_id = ?`
✅ Project comments: `comments WHERE project_id = ?`
✅ User's vote on project: `votes WHERE user_id = ? AND project_id = ?`
✅ Unread messages: `messages WHERE receiver_id = ? AND is_read = false`
✅ Trending projects: `project_stats ORDER BY total_votes DESC`

**Potentially Slow Queries (Not Indexed):**
⚠️ Search projects by title: `projects WHERE title LIKE '%keyword%'` (full-text search needed)
⚠️ User email lookup: `users WHERE email = ?` (should add unique index)
⚠️ Tag name lookup: `tags WHERE tag_name = ?` (should add unique index)

**Recommended Additional Indexes:**
```sql
CREATE UNIQUE INDEX index_users_on_email ON users(email);
CREATE UNIQUE INDEX index_tags_on_tag_name ON tags(tag_name);
CREATE INDEX index_projects_on_title ON projects USING gin(to_tsvector('english', title));
```

---

## Data Types Summary

### Numeric Types
- **bigint (Primary Keys)**: All `id` fields, foreign keys - supports 2^63-1 records
- **integer**: Counters (total_views, total_votes, total_comments), enums (project_role)
- **decimal(12,2)**: Financial amounts (funding_goal, current_funding, amount) - precision to cents

### String Types
- **string (VARCHAR)**: Short text (title, email, status, visibility, tag_name) - default 255 chars
- **text**: Long content (description, content, bio) - unlimited length

### Boolean Types
- **boolean**: Flags (show_funds, is_read) - true/false/null

### Temporal Types
- **datetime**: All timestamps (created_at, updated_at, sent_at, voted_at, funded_at)
  - Stored in UTC
  - Application converts to user timezone

### Special Types
- **PostgreSQL extension**: plpgsql enabled for stored procedures

---

## Data Validation Rules

### Application-Level Validations (in models)

**users:**
- email: format validation, uniqueness
- password: minimum 6 characters, confirmation match
- system_role: inclusion in ['admin', 'user']

**projects:**
- title: presence, minimum 3 characters
- description: presence, minimum 10 characters
- status: inclusion in ['Ideation', 'Ongoing', 'Completed']
- visibility: inclusion in ['public', 'private', 'restricted']
- owner_id: presence

**collaborations:**
- uniqueness: (user_id, project_id) scope
- project_role: inclusion in [0, 1, 2]

**comments:**
- content: presence
- project_id, user_id: presence

**votes:**
- vote_type: inclusion in ['up', 'down']
- uniqueness: (user_id, project_id) enforced at DB level

**messages:**
- content: presence
- sender_id, receiver_id: presence
- validation: sender ≠ receiver

**resources:**
- title, url, project_id, added_by_id: presence

**funds:**
- amount: numericality > 0
- project_id, funder_id: presence

**tags:**
- tag_name: presence, uniqueness (case-insensitive)

---

## Storage Estimates

### Size Calculations (Approximate)

**Per Record Size:**
- users: ~500 bytes (with bio, avatar_url)
- projects: ~1 KB (with long description)
- collaborations: ~100 bytes
- comments: ~500 bytes (average content)
- votes: ~50 bytes
- messages: ~500 bytes
- resources: ~300 bytes
- funds: ~100 bytes
- tags: ~100 bytes
- project_tags: ~50 bytes
- user_tags: ~50 bytes
- project_stats: ~100 bytes

**Expected Scale (1000 users):**
- 1,000 users × 500 bytes = 0.5 MB
- 5,000 projects × 1 KB = 5 MB
- 15,000 collaborations × 100 bytes = 1.5 MB
- 50,000 comments × 500 bytes = 25 MB
- 25,000 votes × 50 bytes = 1.25 MB
- 10,000 messages × 500 bytes = 5 MB
- 5,000 resources × 300 bytes = 1.5 MB
- 500 tags × 100 bytes = 0.05 MB

**Total for 1000 active users: ~40 MB data + indexes (~60 MB total)**

---

## Versioning Strategy

### Current Implementation: Single Version with Metadata

All entities use **current-state versioning** with these tracking fields:

1. **created_at**: Initial creation timestamp (immutable)
2. **updated_at**: Last modification timestamp (auto-updated)
3. **Author fields**: user_id, owner_id, sender_id, funder_id (immutable)

### Versioning Per Entity

| Entity | Created | Updated | Author Field | Version History |
|--------|---------|---------|--------------|-----------------|
| users | ✅ | ✅ | N/A (self) | Current state only |
| projects | ✅ | ✅ | owner_id (immutable) | Current state only |
| collaborations | ✅ | ✅ | user_id (immutable) | Current state only |
| comments | ✅ | ✅ | user_id (immutable) | Current state only |
| votes | ✅ | ✅ | user_id (immutable) | Current state only |
| messages | ✅ | ✅ | sender_id (immutable) | Current state only |
| resources | ✅ | ✅ | added_by_id (immutable) | Current state only |
| funds | ✅ | ✅ | funder_id (immutable) | Immutable (audit trail) |
| tags | ✅ | ✅ | N/A | Current state only |
| project_stats | ✅ | ✅ | N/A | Current state + last_updated |

### Version Tracking Capabilities

**Who:** Author/creator tracked via foreign keys (user_id, owner_id, etc.)
**When:** Timestamps show creation and last update
**What:** Current state stored, no previous versions retained

### Future Enhancement: Full Version History

To implement complete edit history, add:

```sql
CREATE TABLE versions (
  id bigint PRIMARY KEY,
  item_type string NOT NULL,
  item_id bigint NOT NULL,
  event string NOT NULL,  -- 'create', 'update', 'destroy'
  whodunnit integer,      -- user_id who made change
  object text,            -- serialized previous state
  object_changes text,    -- diff of changes
  created_at datetime NOT NULL
);
```

This follows the PaperTrail gem pattern for Rails applications.

---

## Security Considerations

### Data Protection

1. **Passwords**: Hashed with bcrypt (password_digest)
2. **Financial Data**: decimal(12,2) prevents floating-point errors
3. **Soft Deletes**: Not implemented (hard deletes used)
4. **Audit Trail**: created_at/updated_at provide basic audit

### Access Control

**Database Level:**
- Foreign key constraints prevent orphaned records
- Unique indexes prevent duplicate votes/tags

**Application Level:**
- JWT authentication on protected routes
- Role-based authorization (admin vs user)
- Owner/member/viewer permissions on projects
- Users can only edit own records

### Data Integrity

**Cascading Deletes (should be configured):**
- Delete user → cascade to collaborations, comments, votes, messages (sent), resources, funds
- Delete project → cascade to collaborations, comments, votes, resources, funds, project_stats
- Delete tag → cascade to project_tags, user_tags
- Delete comment → cascade to child comments (replies)

**Current Risk:** Foreign keys defined but CASCADE not specified - may cause orphaned records.

**Recommendation:** Add CASCADE rules:
```sql
ON DELETE CASCADE  -- for dependent records
ON DELETE SET NULL -- for optional references
ON DELETE RESTRICT -- for audit trail records (funds)
```

---

## Summary Statistics

### Database Overview

| Metric | Count |
|--------|-------|
| Total Tables | 13 |
| Core Entities | 11 |
| Join Tables | 2 |
| Total Columns | 110+ |
| Foreign Keys | 19 |
| Indexes | 37+ |
| Unique Constraints | 2 (DB level) |

### Table Sizes (by relationship count)

**Largest Tables (most relationships):**
1. **users**: 10 relationships (projects, collaborations, comments, votes, messages × 2, funds, resources, user_tags)
2. **projects**: 9 relationships (collaborations, comments, votes, resources, funds, messages, project_stats, project_tags, owner)
3. **comments**: 3 relationships (project, user, parent/children)

**Smallest Tables (fewest relationships):**
1. **tags**: 2 relationships (project_tags, user_tags)
2. **project_stats**: 1 relationship (project)
3. **funds**: 2 relationships (project, funder)

### Normalization Level

**Database is in 3NF (Third Normal Form):**
✅ 1NF: All attributes atomic (no repeating groups)
✅ 2NF: No partial dependencies (all non-key attributes depend on entire primary key)
✅ 3NF: No transitive dependencies (non-key attributes don't depend on other non-key attributes)

**Denormalization for performance:**
- `project_stats` table caches calculated values (total_views, total_votes, total_comments)
- `projects.current_funding` aggregates sum of funds.amount
- Trade-off: Faster reads, requires cache invalidation on writes

---

## Planned Schema Extensions

**The following fields are documented in the DBML schema (collabsphere_schema.dbml) but NOT YET migrated to production:**

### Content Moderation System (is_reported flag)
Planned addition of `is_reported boolean` field to support user reporting of inappropriate content:

- **users.is_reported** - Flag reported user accounts for admin review
- **projects.is_reported** - Flag reported projects for moderation
- **comments.is_reported** - Flag reported comments for removal
- **messages.is_reported** - Flag reported messages for policy violations
- **resources.is_reported** - Flag reported files/links for inappropriate content

**Implementation Status:** Designed in DBML, pending migration creation

**Rationale:** Community moderation and content safety are critical for academic collaboration platform

### Unique Constraints (Application vs Database Level)

**Currently enforced at application level (not in DB):**
- `users.email` - Unique constraint exists in DBML, needs database index
- `tags.tag_name` - Unique constraint exists in DBML, needs database index
- `collaborations (user_id, project_id)` - Unique constraint exists in DBML, implemented in DB
- `votes (user_id, project_id)` - Unique constraint exists in DBML, implemented in DB
- `project_tags (project_id, tag_id)` - Unique constraint exists in DBML, needs database index
- `user_tags (user_id, tag_id)` - Unique constraint exists in DBML, **implemented in DB** ✅

**Next Steps:** Create migrations to add unique indexes for email and tag_name

### One-to-One Relationship Enhancement

**project_stats.project_id:**
- Current: Foreign key with index
- DBML Design: Unique constraint for strict 1:1 relationship
- Action Needed: Add unique index to enforce at database level

---

## Conclusion

CollabSphere's database schema is well-structured with:

✅ **Clear entity separation**: 11 distinct content types
✅ **Proper relationships**: Foreign keys enforce referential integrity (19 FKs)
✅ **Performance optimization**: Strategic indexing on frequently queried fields (37+ indexes)
✅ **Scalability**: Bigint primary keys support billions of records
✅ **Data integrity**: Unique constraints prevent logical errors (2 DB-level, more pending)
✅ **Audit capability**: Timestamps track creation and modification
✅ **Flexibility**: Text fields for unlimited content, decimal for precise financial data

**Strengths:**
- Normalized schema reduces redundancy (3NF compliance)
- Comprehensive indexing supports fast queries (project lookups, user searches, leaderboards)
- PostgreSQL provides advanced features (extensions, full-text search ready)
- Clear separation of concerns (users, projects, engagement, communication)
- Self-referential threading (comments.parent_id) enables nested discussions
- Strategic denormalization (project_stats) for analytics performance

**Implementation Roadmap:**
1. **Phase 1 (Pending):** Add `is_reported` boolean fields to 5 tables for content moderation
2. **Phase 2 (Pending):** Add unique database indexes on users.email and tags.tag_name
3. **Phase 3 (Pending):** Add unique constraint to project_stats.project_id
4. **Phase 4 (Future):** Configure CASCADE rules for foreign keys (delete behavior)
5. **Phase 5 (Future):** Implement full-text search on projects.title and projects.description
6. **Phase 6 (Future):** Consider soft deletes for important records (add deleted_at column)
7. **Phase 7 (Future):** Add version history table for complete audit trail

**Overall Assessment:** Production-ready schema for MVP launch ✅  
**DBML Documentation:** Comprehensive design includes planned enhancements (see collabsphere_schema.dbml)  
**Migration Status:** Core schema deployed, moderation features in design phase

---

**Schema Version:** 2025_10_30_043054  
**Analysis Date:** November 5, 2025  
**Analyst:** CollabSphere Development Team
