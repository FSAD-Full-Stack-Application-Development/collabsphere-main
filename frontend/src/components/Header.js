import React from "react";
import { Link, useNavigate } from "react-router-dom";
import { authService } from "../apiService";

const Header = () => {
  const navigate = useNavigate();
  const isAuthenticated = authService.isAuthenticated();
  const currentUser = authService.getCurrentUser();
  // backend uses `system_role` (string). Support legacy `role` or boolean `is_admin` too.
  const isAdmin =
    currentUser?.system_role === "admin" ||
    currentUser?.role === "admin" ||
    currentUser?.is_admin;

  const handleLogout = () => {
    authService.logout();
    window.location.href = "https://web06.cs.ait.ac.th/app/";
  };

  return (
    <header className="header">
      <div className="header-content">
        <Link to="/" className="logo">
          CollabSphere
        </Link>

        <nav className="nav">
          {isAuthenticated ? (
            <>
              {!isAdmin ? (
                <>
                  <Link to="/dashboard" className="nav-link">
                    Dashboard
                  </Link>
                  <Link to="/projects" className="nav-link">
                    Projects
                  </Link>
                  <Link to="/projects/new" className="nav-link">
                    New Project
                  </Link>
                </>
              ) : (
                <Link to="/admin" className="nav-link">
                  Admin
                </Link>
              )}
              <span className="nav-link">
                Hello, {currentUser?.full_name || "User"}
              </span>
              <button onClick={handleLogout} className="btn btn-sm btn-outline">
                Logout
              </button>
            </>
          ) : (
            <>
              <a href="https://web06.cs.ait.ac.th/app/" className="nav-link">
                Login
              </a>
            </>
          )}
        </nav>
      </div>
    </header>
  );
};

export default Header;
