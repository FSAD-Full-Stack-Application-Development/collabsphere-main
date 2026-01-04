import React, { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { authService } from "../apiService";

const Login = () => {
  const [formData, setFormData] = useState({
    email: "",
    password: "",
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const navigate = useNavigate();

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError("");

    try {
      await authService.login(formData.email, formData.password);
      const user = authService.getCurrentUser();
      // If the logged in user is an admin (backend uses system_role), redirect to admin dashboard
      const isAdmin =
        user?.system_role === "admin" ||
        user?.role === "admin" ||
        user?.is_admin;
      if (isAdmin) {
        navigate("/admin");
      } else {
        navigate("/dashboard");
      }
    } catch (error) {
      setError(error.response?.data?.error || "Login failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div
      className="container"
      style={{ paddingTop: "40px", paddingBottom: "60px" }}
    >
      <div style={{ maxWidth: "480px", margin: "0 auto" }}>
        <div className="card" style={{ padding: "40px" }}>
          <div style={{ textAlign: "center", marginBottom: "32px" }}>
            <div
              style={{
                width: "64px",
                height: "64px",
                margin: "0 auto 20px",
                background: "var(--gradient-main)",
                borderRadius: "16px",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                fontSize: "32px",
                color: "white",
                fontWeight: "bold",
                boxShadow: "var(--shadow-md)",
              }}
            >
              C
            </div>
            <h2 style={{ marginBottom: "8px" }}>Welcome Back</h2>
            <p
              style={{
                color: "var(--text-light)",
                fontSize: "15px",
                margin: 0,
              }}
            >
              Sign in to continue to CollabSphere
            </p>
          </div>

          {error && (
            <div className="alert alert-error" style={{ marginBottom: "24px" }}>
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label className="form-label">Email Address</label>
              <input
                type="email"
                name="email"
                value={formData.email}
                onChange={handleChange}
                className="form-input"
                placeholder="you@example.com"
                required
                autoComplete="email"
                autoFocus
              />
            </div>

            <div className="form-group">
              <label className="form-label">Password</label>
              <input
                type="password"
                name="password"
                value={formData.password}
                onChange={handleChange}
                className="form-input"
                placeholder="Enter your password"
                required
                autoComplete="current-password"
              />
            </div>

            <button
              type="submit"
              className="btn btn-primary"
              style={{ width: "100%", marginTop: "8px" }}
              disabled={loading}
            >
              {loading ? (
                <span
                  style={{
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    gap: "8px",
                  }}
                >
                  <div
                    className="spinner"
                    style={{
                      width: "16px",
                      height: "16px",
                      border: "2px solid white",
                      borderTopColor: "transparent",
                    }}
                  ></div>
                  Signing in...
                </span>
              ) : (
                "Sign In"
              )}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};

export default Login;
