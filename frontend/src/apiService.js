// API Service for CollabSphere Backend
import axios from "axios";

const API_BASE_URL = process.env.REACT_APP_API_URL || "https://web06.cs.ait.ac.th/be";

// Create axios instance with default config
const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    "Content-Type": "application/json",
  },
});

// Public API client (no auth interceptors / no 401 redirect). Use this for anonymous reads
export const publicApi = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    "Content-Type": "application/json",
  },
});

// Add request interceptor to include auth token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem("collabsphere_token");
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Add response interceptor to handle auth errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem("collabsphere_token");
      localStorage.removeItem("collabsphere_user");
      window.location.href = "/login";
    }
    return Promise.reject(error);
  }
);

// Authentication Services
export const authService = {
  // Stage 1 Registration - Basic info
  register: async (userData) => {
    const response = await axios.post(`${API_BASE_URL}/auth/register`, {
      user: userData,
    });
    if (response.data.token) {
      localStorage.setItem("collabsphere_token", response.data.token);
      localStorage.setItem(
        "collabsphere_user",
        JSON.stringify(response.data.user)
      );
    }
    return response.data;
  },

  // Login
  login: async (email, password) => {
    const response = await axios.post(`${API_BASE_URL}/auth/login`, {
      email,
      password,
    });
    if (response.data.token) {
      localStorage.setItem("collabsphere_token", response.data.token);
      localStorage.setItem(
        "collabsphere_user",
        JSON.stringify(response.data.user)
      );
    }
    return response.data;
  },

  // Logout
  logout: () => {
    localStorage.removeItem("collabsphere_token");
    localStorage.removeItem("collabsphere_user");
  },

  // Get current user from storage
  getCurrentUser: () => {
    const userStr = localStorage.getItem("collabsphere_user");
    return userStr ? JSON.parse(userStr) : null;
  },

  // Check if user is authenticated
  isAuthenticated: () => {
    return !!localStorage.getItem("collabsphere_token");
  },
};

// User Services
export const userService = {
  // Get current user profile
  getProfile: async () => {
    const response = await api.get("/api/v1/users/profile");
    return response.data;
  },

  // Stage 2 - Complete user profile
  updateProfile: async (userId, profileData) => {
    const response = await api.patch(`/api/v1/users/${userId}`, {
      user: profileData,
    });
    // Update stored user data
    localStorage.setItem("collabsphere_user", JSON.stringify(response.data));
    return response.data;
  },

  // Get all users
  getUsers: async () => {
    const response = await api.get("/api/v1/users");
    return response.data;
  },

  // Get user by ID
  getUserById: async (userId) => {
    const response = await api.get(`/api/v1/users/${userId}`);
    return response.data;
  },

  // Create user (admin)
  // Admin helper to create a user without replacing current session. Uses the public register endpoint.
  adminCreateUser: async (userData) => {
    const response = await api.post(`/auth/register`, { user: userData });
    // Do not touch localStorage here; caller will handle UI update
    return response.data;
  },

  // Delete user (admin)
  deleteUser: async (userId) => {
    const response = await api.delete(`/api/v1/users/${userId}`);
    return response.data;
  },

  // Update user (admin) - generic patch
  patchUser: async (userId, data) => {
    const response = await api.patch(`/api/v1/users/${userId}`, { user: data });
    return response.data;
  },
};

// Project Services
export const projectService = {
  // Get all projects
  getProjects: async (params = {}) => {
    const response = await api.get("/api/v1/projects", { params });
    // Return full response with data and meta for pagination
    return response.data;
  },

  // Get project by ID
  getProject: async (projectId) => {
    const response = await api.get(`/api/v1/projects/${projectId}`);
    return response.data;
  },

  // Create new project
  createProject: async (projectData) => {
    const response = await api.post("/api/v1/projects", {
      project: projectData,
    });
    return response.data;
  },

  // Update project
  updateProject: async (projectId, projectData) => {
    const response = await api.patch(
      `/api/v1/projects/${projectId}`,
      projectData
    );
    return response.data;
  },

  // Delete project
  deleteProject: async (projectId) => {
    const response = await api.delete(`/api/v1/projects/${projectId}`);
    return response.data;
  },

  // Vote on project
  voteProject: async (projectId, voteType = "up") => {
    const response = await api.post(`/api/v1/projects/${projectId}/vote`, {
      vote_type: voteType,
    });
    return response.data;
  },

  // Remove vote
  unvoteProject: async (projectId) => {
    const response = await api.delete(`/api/v1/projects/${projectId}/vote`);
    return response.data;
  },
};

// Comment Services
export const commentService = {
  // Get comments for project
  getComments: async (projectId) => {
    const response = await api.get(`/api/v1/projects/${projectId}/comments`);
    return response.data;
  },

  // Add comment
  addComment: async (projectId, commentData) => {
    const response = await api.post(
      `/api/v1/projects/${projectId}/comments`,
      commentData
    );
    return response.data;
  },

  // Update comment
  updateComment: async (projectId, commentId, commentData) => {
    const response = await api.patch(
      `/api/v1/projects/${projectId}/comments/${commentId}`,
      commentData
    );
    return response.data;
  },

  // Delete comment
  deleteComment: async (projectId, commentId) => {
    const response = await api.delete(
      `/api/v1/projects/${projectId}/comments/${commentId}`
    );
    return response.data;
  },
};

// Collaboration Services
export const collaborationService = {
  // Get collaborators for project
  getCollaborators: async (projectId) => {
    const response = await api.get(
      `/api/v1/projects/${projectId}/collaborations`
    );
    return response.data;
  },

  // Add collaborator with custom role
  addCollaborator: async (projectId, collaboratorData) => {
    const response = await api.post(
      `/api/v1/projects/${projectId}/collaborations`,
      { collaboration: collaboratorData }
    );
    return response.data;
  },

  // Update collaboration
  updateCollaboration: async (
    projectId,
    collaborationId,
    collaborationData
  ) => {
    const response = await api.patch(
      `/api/v1/projects/${projectId}/collaborations/${collaborationId}`,
      collaborationData
    );
    return response.data;
  },

  // Remove collaborator
  removeCollaborator: async (projectId, collaborationId) => {
    const response = await api.delete(
      `/api/v1/projects/${projectId}/collaborations/${collaborationId}`
    );
    return response.data;
  },
};

// Fund Services
export const fundService = {
  // Get funds for project
  getFunds: async (projectId) => {
    const response = await api.get(`/api/v1/projects/${projectId}/funds`);
    return response.data;
  },

  // Add fund to project
  addFund: async (projectId, fundData) => {
    const response = await api.post(
      `/api/v1/projects/${projectId}/funds`,
      fundData
    );
    return response.data;
  },
};

// Report Services
export const reportService = {
  // Submit a report
  submitReport: async (reportData) => {
    const response = await api.post("/api/v1/reports", { report: reportData });
    return response.data;
  },
};

// Resource Services
export const resourceService = {
  // Get resources for project
  getResources: async (projectId) => {
    const response = await api.get(`/api/v1/projects/${projectId}/resources`);
    return response.data;
  },

  // Add resource
  addResource: async (projectId, resourceData) => {
    const response = await api.post(
      `/api/v1/projects/${projectId}/resources`,
      resourceData
    );
    return response.data;
  },

  // Update resource
  updateResource: async (projectId, resourceId, resourceData) => {
    const response = await api.patch(
      `/api/v1/projects/${projectId}/resources/${resourceId}`,
      resourceData
    );
    return response.data;
  },

  // Delete resource
  deleteResource: async (projectId, resourceId) => {
    const response = await api.delete(
      `/api/v1/projects/${projectId}/resources/${resourceId}`
    );
    return response.data;
  },
};

// Tag Services
export const tagService = {
  // Get all tags
  getTags: async () => {
    const response = await api.get("/api/v1/tags");
    return response.data;
  },

  // Create tag
  createTag: async (tagData) => {
    const response = await api.post("/api/v1/tags", tagData);
    return response.data;
  },

  // Get tag by ID
  getTag: async (tagId) => {
    const response = await api.get(`/api/v1/tags/${tagId}`);
    return response.data;
  },
  // Update tag
  updateTag: async (tagId, tagData) => {
    const response = await api.patch(`/api/v1/tags/${tagId}`, tagData);
    return response.data;
  },

  // Delete tag
  deleteTag: async (tagId) => {
    const response = await api.delete(`/api/v1/tags/${tagId}`);
    return response.data;
  },
};

// Admin helper services (dedicated admin API)
export const adminService = {
  // Get dashboard stats
  getStats: async () => {
    const response = await api.get("/api/v1/admin/stats");
    return response.data;
  },

  // Analytics
  getAnalytics: async () => {
    const response = await api.get("/api/v1/admin/analytics");
    return response.data;
  },

  getAnalyticsGrowth: async () => {
    const response = await api.get("/api/v1/admin/analytics/growth");
    return response.data;
  },

  // Audit Logs
  getAuditLogs: async (filters = {}) => {
    const response = await api.get("/api/v1/admin/audit_logs", {
      params: filters,
    });
    return response.data;
  },

  getAuditLogStats: async () => {
    const response = await api.get("/api/v1/admin/audit_logs/stats");
    return response.data;
  },

  // Users
  getUsers: async (filters = {}) => {
    const response = await api.get("/api/v1/admin/users", { params: filters });
    return response.data;
  },

  getUser: async (userId) => {
    const response = await api.get(`/api/v1/admin/users/${userId}`);
    return response.data;
  },

  getUserFilterOptions: async () => {
    const response = await api.get("/api/v1/admin/users/filter_options");
    return response.data;
  },

  getUserUniversitiesByCountry: async (country) => {
    const response = await api.get(
      "/api/v1/admin/users/universities_by_country",
      { params: { country } }
    );
    return response.data;
  },

  getUserDepartmentsByUniversity: async (university) => {
    const response = await api.get(
      "/api/v1/admin/users/departments_by_university",
      { params: { university } }
    );
    return response.data;
  },

  createUser: async (userData) => {
    const response = await api.post("/api/v1/admin/users", { user: userData });
    return response.data;
  },

  updateUser: async (userId, userData) => {
    const response = await api.patch(`/api/v1/admin/users/${userId}`, {
      user: userData,
    });
    return response.data;
  },

  deleteUser: async (userId) => {
    const response = await api.delete(`/api/v1/admin/users/${userId}`);
    return response.data;
  },

  // Convenience methods for user moderation
  banUser: async (userId) => {
    const response = await api.patch(`/api/v1/admin/users/${userId}`, {
      user: { banned: true },
    });
    return response.data;
  },

  unbanUser: async (userId) => {
    const response = await api.patch(`/api/v1/admin/users/${userId}`, {
      user: { banned: false },
    });
    return response.data;
  },

  updateUserRole: async (userId, role) => {
    const response = await api.patch(`/api/v1/admin/users/${userId}`, {
      user: { system_role: role },
    });
    return response.data;
  },

  // Projects
  getProjects: async (filters = {}) => {
    const response = await api.get("/api/v1/admin/projects", {
      params: filters,
    });
    return response.data;
  },

  getProject: async (projectId) => {
    const response = await api.get(`/api/v1/admin/projects/${projectId}`);
    return response.data;
  },

  getProjectFilterOptions: async () => {
    const response = await api.get("/api/v1/admin/projects/filter_options");
    return response.data;
  },

  getProjectUniversitiesByCountry: async (country) => {
    const response = await api.get(
      "/api/v1/admin/projects/universities_by_country",
      { params: { country } }
    );
    return response.data;
  },

  getProjectDepartmentsByUniversity: async (university) => {
    const response = await api.get(
      "/api/v1/admin/projects/departments_by_university",
      { params: { university } }
    );
    return response.data;
  },

  updateProject: async (projectId, projectData) => {
    const response = await api.patch(`/api/v1/admin/projects/${projectId}`, {
      project: projectData,
    });
    return response.data;
  },

  deleteProject: async (projectId) => {
    const response = await api.delete(`/api/v1/admin/projects/${projectId}`);
    return response.data;
  },

  // Tags
  getTags: async (params = {}) => {
    const response = await api.get("/api/v1/admin/tags", { params });
    return response.data;
  },

  createTag: async (tagData) => {
    const response = await api.post("/api/v1/admin/tags", { tag: tagData });
    return response.data;
  },

  updateTag: async (tagId, tagData) => {
    const response = await api.patch(`/api/v1/admin/tags/${tagId}`, {
      tag: tagData,
    });
    return response.data;
  },

  deleteTag: async (tagId) => {
    const response = await api.delete(`/api/v1/admin/tags/${tagId}`);
    return response.data;
  },

  // Reports
  getReports: async (filters = {}) => {
    const response = await api.get("/api/v1/admin/reports", {
      params: filters,
    });
    return response.data;
  },

  getReportStats: async () => {
    const response = await api.get("/api/v1/admin/reports/stats");
    return response.data;
  },

  resolveReport: async (reportId, resolution = "") => {
    const response = await api.patch(
      `/api/v1/admin/reports/${reportId}/resolve`,
      { resolution }
    );
    return response.data;
  },

  dismissReport: async (reportId, reason = "") => {
    const response = await api.patch(
      `/api/v1/admin/reports/${reportId}/dismiss`,
      { reason }
    );
    return response.data;
  },

  // Leaderboard
  getLeaderboardFilters: async () => {
    const response = await api.get("/api/v1/admin/leaderboard/filter_options");
    return response.data;
  },

  getUniversitiesByCountry: async (country) => {
    const response = await api.get(
      "/api/v1/admin/leaderboard/universities_by_country",
      { params: { country } }
    );
    return response.data;
  },

  getDepartmentsByUniversity: async (university) => {
    const response = await api.get(
      "/api/v1/admin/leaderboard/departments_by_university",
      { params: { university } }
    );
    return response.data;
  },

  getMostViewedProjects: async (filters = {}) => {
    const response = await api.get(
      "/api/v1/admin/leaderboard/most_viewed_projects",
      { params: filters }
    );
    return response.data;
  },

  getMostVotedProjects: async (filters = {}) => {
    const response = await api.get(
      "/api/v1/admin/leaderboard/most_voted_projects",
      { params: filters }
    );
    return response.data;
  },

  getMostCommentedProjects: async (filters = {}) => {
    const response = await api.get(
      "/api/v1/admin/leaderboard/most_commented_projects",
      { params: filters }
    );
    return response.data;
  },

  getMostActiveCollaborators: async (filters = {}) => {
    const response = await api.get(
      "/api/v1/admin/leaderboard/most_active_collaborators",
      { params: filters }
    );
    return response.data;
  },

  getMostFundedProjects: async (filters = {}) => {
    const response = await api.get(
      "/api/v1/admin/leaderboard/most_funded_projects",
      { params: filters }
    );
    return response.data;
  },

  getTopFunders: async (filters = {}) => {
    const response = await api.get("/api/v1/admin/leaderboard/top_funders", {
      params: filters,
    });
    return response.data;
  },
};

// API Logs Services
export const apiLogService = {
  // Get all API logs with filters
  getLogs: async (filters = {}) => {
    const response = await api.get("/api/v1/admin/api_logs", {
      params: filters,
    });
    return response.data;
  },

  // Get API log statistics
  getStats: async (period = "today", customRange = {}) => {
    const response = await api.get("/api/v1/admin/api_logs/stats", {
      params: { period, ...customRange },
    });
    return response.data;
  },

  // Get single log details
  getLog: async (id) => {
    const response = await api.get(`/api/v1/admin/api_logs/${id}`);
    return response.data;
  },

  // Cleanup old logs
  cleanup: async (days = 30) => {
    const response = await api.delete("/api/v1/admin/api_logs/cleanup", {
      params: { days },
    });
    return response.data;
  },
};

export default api;
