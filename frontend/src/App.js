import React from "react";
import {
  BrowserRouter as Router,
  Routes,
  Route,
  Navigate,
} from "react-router-dom";
import { authService } from "./apiService";

// Import components
import Header from "./components/Header";
import Login from "./components/Login";
import AdminLogin from "./components/AdminLogin";
import Dashboard from "./components/Dashboard";
import ProfileCompletion from "./components/ProfileCompletion";
import ProjectList from "./components/ProjectList";
import ProjectDetails from "./components/ProjectDetails";
import CreateProject from "./components/CreateProject";
import EditProject from "./components/EditProject";
import EditProfile from "./components/EditProfile";
// Admin components
import AdminDashboard from "./components/admin/AdminDashboard";
import ManageUsers from "./components/admin/ManageUsers";
import ManageProjects from "./components/admin/ManageProjects";
import ManageTags from "./components/admin/ManageTags";
import ManageReports from "./components/admin/ManageReports";
import Leaderboard from "./components/admin/Leaderboard";
import ApiLogs from "./components/admin/ApiLogs";
import HomePage from "./components/HomePage";

// Protected Route component
const ProtectedRoute = ({ children }) => {
  if (!authService.isAuthenticated()) {
    window.location.href = "https://web06.cs.ait.ac.th/app/";
    return null;
  }
  return children;
};

const AdminRoute = ({ children }) => {
  const user = authService.getCurrentUser();
  if (!authService.isAuthenticated()) {
    window.location.href = "https://web06.cs.ait.ac.th/app/";
    return null;
  }
  // backend uses `system_role` (string 'admin'|'user') per docs; fall back to legacy fields
  const isAdmin =
    user?.system_role === "admin" || user?.role === "admin" || user?.is_admin;
  return isAdmin ? children : <Navigate to="/dashboard" />;
};

function App() {
  return (
    <Router basename="/project">
      <div className="App">
        <Header />
        <main
          style={{
            paddingTop: "105px",
            minHeight: "100vh",
            background: "var(--bg-light)",
          }}
        >
          <Routes>
            <Route path="/login" element={<Login />} />
            <Route path="/admin-login" element={<AdminLogin />} />
            <Route
              path="/profile-completion"
              element={
                <ProtectedRoute>
                  <ProfileCompletion />
                </ProtectedRoute>
              }
            />
            <Route
              path="/dashboard"
              element={
                <ProtectedRoute>
                  <Dashboard />
                </ProtectedRoute>
              }
            />
            <Route
              path="/profile/edit"
              element={
                <ProtectedRoute>
                  <EditProfile />
                </ProtectedRoute>
              }
            />
            <Route
              path="/projects"
              element={
                <ProtectedRoute>
                  <ProjectList />
                </ProtectedRoute>
              }
            />
            <Route
              path="/projects/new"
              element={
                <ProtectedRoute>
                  <CreateProject />
                </ProtectedRoute>
              }
            />
            <Route
              path="/projects/:id"
              element={
                <ProtectedRoute>
                  <ProjectDetails />
                </ProtectedRoute>
              }
            />
            <Route
              path="/projects/:id/edit"
              element={
                <ProtectedRoute>
                  <EditProject />
                </ProtectedRoute>
              }
            />
            {/* Admin routes for moderation */}
            <Route
              path="/admin"
              element={
                <ProtectedRoute>
                  <AdminRoute>
                    <AdminDashboard />
                  </AdminRoute>
                </ProtectedRoute>
              }
            />
            <Route
              path="/admin/users"
              element={
                <ProtectedRoute>
                  <AdminRoute>
                    <ManageUsers />
                  </AdminRoute>
                </ProtectedRoute>
              }
            />
            <Route
              path="/admin/projects"
              element={
                <ProtectedRoute>
                  <AdminRoute>
                    <ManageProjects />
                  </AdminRoute>
                </ProtectedRoute>
              }
            />
            <Route
              path="/admin/tags"
              element={
                <ProtectedRoute>
                  <AdminRoute>
                    <ManageTags />
                  </AdminRoute>
                </ProtectedRoute>
              }
            />
            <Route
              path="/admin/reports"
              element={
                <ProtectedRoute>
                  <AdminRoute>
                    <ManageReports />
                  </AdminRoute>
                </ProtectedRoute>
              }
            />
            <Route
              path="/admin/leaderboard"
              element={
                <ProtectedRoute>
                  <AdminRoute>
                    <Leaderboard />
                  </AdminRoute>
                </ProtectedRoute>
              }
            />
            <Route
              path="/admin/api-logs"
              element={
                <ProtectedRoute>
                  <AdminRoute>
                    <ApiLogs />
                  </AdminRoute>
                </ProtectedRoute>
              }
            />
            <Route path="/" element={<HomePage />} />
          </Routes>
        </main>
      </div>
    </Router>
  );
}

export default App;
