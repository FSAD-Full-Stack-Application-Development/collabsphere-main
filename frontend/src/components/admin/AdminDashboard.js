import React, { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { adminService } from "../../apiService";

const AdminDashboard = () => {
  const [counts, setCounts] = useState({ users: 0, projects: 0, tags: 0 });
  const [analytics, setAnalytics] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      setLoading(true);
      const [stats, analyticsData] = await Promise.all([
        adminService.getStats(),
        adminService.getAnalytics(),
      ]);
      setCounts(stats);
      setAnalytics(analyticsData);
    } catch (e) {
      console.error("Failed to load admin data", e);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="container" style={{ paddingTop: "20px" }}>
      <div className="card">
        <h1>Admin Dashboard</h1>
        <p style={{ color: "#6b7280" }}>Moderation and site management</p>
      </div>

      {/* Quick Actions */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))",
          gap: "16px",
          marginTop: "16px",
        }}
      >
        <div className="card">
          <h3>Users</h3>
          <p style={{ fontSize: "24px", margin: "8px 0" }}>
            {loading ? "..." : counts.users}
          </p>
          <Link to="/admin/users" className="btn btn-sm btn-outline">
            Manage Users
          </Link>
        </div>

        <div className="card">
          <h3>Projects</h3>
          <p style={{ fontSize: "24px", margin: "8px 0" }}>
            {loading ? "..." : counts.projects}
          </p>
          <Link to="/admin/projects" className="btn btn-sm btn-outline">
            Manage Projects
          </Link>
        </div>

        <div className="card">
          <h3>Tags</h3>
          <p style={{ fontSize: "24px", margin: "8px 0" }}>
            {loading ? "..." : counts.tags}
          </p>
          <Link to="/admin/tags" className="btn btn-sm btn-outline">
            Manage Tags
          </Link>
        </div>

        <div className="card">
          <h3>Reports</h3>
          <p style={{ fontSize: "12px", color: "#6b7280", marginTop: "8px" }}>
            Manage user reports
          </p>
          <Link
            to="/admin/reports"
            className="btn btn-sm btn-outline"
            style={{ marginTop: "12px" }}
          >
            View Reports
          </Link>
        </div>

        <div className="card">
          <h3>🏆 Leaderboard</h3>
          <p style={{ fontSize: "12px", color: "#6b7280", marginTop: "8px" }}>
            Top projects and users
          </p>
          <Link
            to="/admin/leaderboard"
            className="btn btn-sm btn-outline"
            style={{ marginTop: "12px" }}
          >
            View Leaderboard
          </Link>
        </div>

        <div className="card">
          <h3> API Logs</h3>
          <p style={{ fontSize: "12px", color: "#6b7280", marginTop: "8px" }}>
            Monitor API requests & performance
          </p>
          <Link
            to="/admin/api-logs"
            className="btn btn-sm btn-outline"
            style={{ marginTop: "12px" }}
          >
            View API Logs
          </Link>
        </div>
      </div>

      {/* Analytics Section */}
      {!loading && analytics && (
        <>
          {/* User Metrics */}
          <div className="card" style={{ marginTop: "24px" }}>
            <h2 style={{ marginBottom: "16px" }}> User Analytics</h2>
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
                gap: "16px",
              }}
            >
              <div
                style={{
                  padding: "16px",
                  background: "#f9fafb",
                  borderRadius: "6px",
                }}
              >
                <div style={{ fontSize: "12px", color: "#6b7280" }}>
                  New Users Today
                </div>
                <div
                  style={{
                    fontSize: "24px",
                    fontWeight: "bold",
                    color: "#10b981",
                  }}
                >
                  {analytics.user_metrics.new_users_today}
                </div>
              </div>
              <div
                style={{
                  padding: "16px",
                  background: "#f9fafb",
                  borderRadius: "6px",
                }}
              >
                <div style={{ fontSize: "12px", color: "#6b7280" }}>
                  New Users This Week
                </div>
                <div
                  style={{
                    fontSize: "24px",
                    fontWeight: "bold",
                    color: "#3b82f6",
                  }}
                >
                  {analytics.user_metrics.new_users_this_week}
                </div>
              </div>
              <div
                style={{
                  padding: "16px",
                  background: "#f9fafb",
                  borderRadius: "6px",
                }}
              >
                <div style={{ fontSize: "12px", color: "#6b7280" }}>
                  New Users This Month
                </div>
                <div
                  style={{
                    fontSize: "24px",
                    fontWeight: "bold",
                    color: "#8b5cf6",
                  }}
                >
                  {analytics.user_metrics.new_users_this_month}
                </div>
              </div>
              <div
                style={{
                  padding: "16px",
                  background: "#f9fafb",
                  borderRadius: "6px",
                }}
              >
                <div style={{ fontSize: "12px", color: "#6b7280" }}>
                  Active This Week
                </div>
                <div
                  style={{
                    fontSize: "24px",
                    fontWeight: "bold",
                    color: "#f59e0b",
                  }}
                >
                  {analytics.user_metrics.active_users_this_week}
                </div>
              </div>
            </div>
          </div>

          {/* Project Metrics */}
          <div className="card" style={{ marginTop: "16px" }}>
            <h2 style={{ marginBottom: "16px" }}>📁 Project Analytics</h2>
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
                gap: "16px",
              }}
            >
              <div
                style={{
                  padding: "16px",
                  background: "#f9fafb",
                  borderRadius: "6px",
                }}
              >
                <div style={{ fontSize: "12px", color: "#6b7280" }}>
                  Created Today
                </div>
                <div
                  style={{
                    fontSize: "24px",
                    fontWeight: "bold",
                    color: "#10b981",
                  }}
                >
                  {analytics.project_metrics.projects_created_today}
                </div>
              </div>
              <div
                style={{
                  padding: "16px",
                  background: "#f9fafb",
                  borderRadius: "6px",
                }}
              >
                <div style={{ fontSize: "12px", color: "#6b7280" }}>
                  Created This Week
                </div>
                <div
                  style={{
                    fontSize: "24px",
                    fontWeight: "bold",
                    color: "#3b82f6",
                  }}
                >
                  {analytics.project_metrics.projects_created_this_week}
                </div>
              </div>
              <div
                style={{
                  padding: "16px",
                  background: "#f9fafb",
                  borderRadius: "6px",
                }}
              >
                <div style={{ fontSize: "12px", color: "#6b7280" }}>
                  Created This Month
                </div>
                <div
                  style={{
                    fontSize: "24px",
                    fontWeight: "bold",
                    color: "#8b5cf6",
                  }}
                >
                  {analytics.project_metrics.projects_created_this_month}
                </div>
              </div>
              <div
                style={{
                  padding: "16px",
                  background: "#f9fafb",
                  borderRadius: "6px",
                }}
              >
                <div style={{ fontSize: "12px", color: "#6b7280" }}>
                  Avg Collaborators
                </div>
                <div
                  style={{
                    fontSize: "24px",
                    fontWeight: "bold",
                    color: "#f59e0b",
                  }}
                >
                  {analytics.project_metrics.average_collaborators_per_project}
                </div>
              </div>
            </div>
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "repeat(3, 1fr)",
                gap: "12px",
                marginTop: "16px",
              }}
            >
              <div
                style={{
                  padding: "12px",
                  background: "#ecfdf5",
                  borderRadius: "6px",
                  border: "1px solid #d1fae5",
                }}
              >
                <div
                  style={{
                    fontSize: "12px",
                    color: "#065f46",
                    fontWeight: "500",
                  }}
                >
                  Ongoing
                </div>
                <div
                  style={{
                    fontSize: "20px",
                    fontWeight: "bold",
                    color: "#047857",
                  }}
                >
                  {analytics.project_metrics.projects_by_status.Ongoing || 0}
                </div>
              </div>
              <div
                style={{
                  padding: "12px",
                  background: "#eff6ff",
                  borderRadius: "6px",
                  border: "1px solid #dbeafe",
                }}
              >
                <div
                  style={{
                    fontSize: "12px",
                    color: "#1e40af",
                    fontWeight: "500",
                  }}
                >
                  Ideation
                </div>
                <div
                  style={{
                    fontSize: "20px",
                    fontWeight: "bold",
                    color: "#2563eb",
                  }}
                >
                  {analytics.project_metrics.projects_by_status.Ideation || 0}
                </div>
              </div>
              <div
                style={{
                  padding: "12px",
                  background: "#f5f3ff",
                  borderRadius: "6px",
                  border: "1px solid #e9d5ff",
                }}
              >
                <div
                  style={{
                    fontSize: "12px",
                    color: "#6b21a8",
                    fontWeight: "500",
                  }}
                >
                  Completed
                </div>
                <div
                  style={{
                    fontSize: "20px",
                    fontWeight: "bold",
                    color: "#7c3aed",
                  }}
                >
                  {analytics.project_metrics.projects_by_status.Completed || 0}
                </div>
              </div>
            </div>
          </div>

          {/* Engagement Metrics */}
          <div className="card" style={{ marginTop: "16px" }}>
            <h2 style={{ marginBottom: "16px" }}>💬 Engagement Analytics</h2>
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
                gap: "16px",
              }}
            >
              <div
                style={{
                  padding: "16px",
                  background: "#f9fafb",
                  borderRadius: "6px",
                }}
              >
                <div style={{ fontSize: "12px", color: "#6b7280" }}>
                  Total Comments
                </div>
                <div style={{ fontSize: "24px", fontWeight: "bold" }}>
                  {analytics.overview.total_comments}
                </div>
                <div
                  style={{
                    fontSize: "11px",
                    color: "#10b981",
                    marginTop: "4px",
                  }}
                >
                  +{analytics.engagement_metrics.comments_today} today
                </div>
              </div>
              <div
                style={{
                  padding: "16px",
                  background: "#f9fafb",
                  borderRadius: "6px",
                }}
              >
                <div style={{ fontSize: "12px", color: "#6b7280" }}>
                  Total Votes
                </div>
                <div style={{ fontSize: "24px", fontWeight: "bold" }}>
                  {analytics.overview.total_votes}
                </div>
                <div
                  style={{
                    fontSize: "11px",
                    color: "#10b981",
                    marginTop: "4px",
                  }}
                >
                  +{analytics.engagement_metrics.votes_today} today
                </div>
              </div>
              <div
                style={{
                  padding: "16px",
                  background: "#f9fafb",
                  borderRadius: "6px",
                }}
              >
                <div style={{ fontSize: "12px", color: "#6b7280" }}>
                  Avg Comments/Project
                </div>
                <div
                  style={{
                    fontSize: "24px",
                    fontWeight: "bold",
                    color: "#3b82f6",
                  }}
                >
                  {analytics.engagement_metrics.average_comments_per_project}
                </div>
              </div>
              <div
                style={{
                  padding: "16px",
                  background: "#f9fafb",
                  borderRadius: "6px",
                }}
              >
                <div style={{ fontSize: "12px", color: "#6b7280" }}>
                  Avg Votes/Project
                </div>
                <div
                  style={{
                    fontSize: "24px",
                    fontWeight: "bold",
                    color: "#8b5cf6",
                  }}
                >
                  {analytics.engagement_metrics.average_votes_per_project}
                </div>
              </div>
            </div>
          </div>

          {/* Top Performers */}
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "1fr 1fr",
              gap: "16px",
              marginTop: "16px",
            }}
          >
            <div className="card">
              <h3 style={{ marginBottom: "12px" }}>👥 Most Active Users</h3>
              <p
                style={{
                  fontSize: "12px",
                  color: "#6b7280",
                  marginBottom: "12px",
                }}
              >
                Based on owned projects + collaborations
              </p>
              {analytics.top_performers.most_active_users
                .slice(0, 5)
                .map((user, index) => (
                  <div
                    key={user.id}
                    style={{
                      padding: "8px",
                      background: index % 2 === 0 ? "#f9fafb" : "white",
                      borderRadius: "4px",
                      marginBottom: "4px",
                      display: "flex",
                      justifyContent: "space-between",
                      alignItems: "center",
                    }}
                  >
                    <div>
                      <div style={{ fontSize: "14px", fontWeight: "500" }}>
                        {user.full_name}
                      </div>
                      <div style={{ fontSize: "11px", color: "#6b7280" }}>
                        {user.owned_count} owned • {user.collab_count}{" "}
                        collaborations
                      </div>
                    </div>
                    <span
                      style={{
                        fontSize: "18px",
                        fontWeight: "bold",
                        color: "#8b5cf6",
                      }}
                    >
                      {user.project_count}
                    </span>
                  </div>
                ))}
            </div>

            <div className="card">
              <h3 style={{ marginBottom: "12px" }}>🔥 Most Viewed Projects</h3>
              {analytics.top_performers.most_viewed_projects
                .slice(0, 5)
                .map((project, index) => (
                  <div
                    key={project.id}
                    style={{
                      padding: "8px",
                      background: index % 2 === 0 ? "#f9fafb" : "white",
                      borderRadius: "4px",
                      marginBottom: "4px",
                      display: "flex",
                      justifyContent: "space-between",
                    }}
                  >
                    <span style={{ fontSize: "14px" }}>{project.title}</span>
                    <span
                      style={{
                        fontSize: "14px",
                        fontWeight: "bold",
                        color: "#3b82f6",
                      }}
                    >
                      {project.project_stat.total_views} views
                    </span>
                  </div>
                ))}
            </div>
          </div>

          {/* Distribution Charts */}
          <div className="card" style={{ marginTop: "16px" }}>
            <h2 style={{ marginBottom: "16px" }}>🌍 User Distribution</h2>

            {/* By Country */}
            <div style={{ marginBottom: "24px" }}>
              <h3 style={{ fontSize: "16px", marginBottom: "12px" }}>
                Top Countries
              </h3>
              <div
                style={{ display: "flex", flexDirection: "column", gap: "8px" }}
              >
                {Object.entries(
                  analytics.user_metrics.users_by_country || {}
                ).map(([country, count]) => (
                  <div
                    key={country}
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: "8px",
                    }}
                  >
                    <div style={{ minWidth: "120px", fontSize: "14px" }}>
                      {country}
                    </div>
                    <div
                      style={{
                        flex: 1,
                        background: "#e5e7eb",
                        borderRadius: "4px",
                        height: "24px",
                        position: "relative",
                        overflow: "hidden",
                      }}
                    >
                      <div
                        style={{
                          width: `${
                            (count /
                              Math.max(
                                ...Object.values(
                                  analytics.user_metrics.users_by_country
                                )
                              )) *
                            100
                          }%`,
                          background:
                            "linear-gradient(90deg, #3b82f6, #8b5cf6)",
                          height: "100%",
                          borderRadius: "4px",
                          transition: "width 0.3s ease",
                        }}
                      />
                    </div>
                    <div
                      style={{
                        minWidth: "40px",
                        textAlign: "right",
                        fontSize: "14px",
                        fontWeight: "bold",
                      }}
                    >
                      {count}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* By University */}
            <div style={{ marginBottom: "24px" }}>
              <h3 style={{ fontSize: "16px", marginBottom: "12px" }}>
                Top Universities
              </h3>
              <div
                style={{ display: "flex", flexDirection: "column", gap: "8px" }}
              >
                {Object.entries(
                  analytics.user_metrics.users_by_university || {}
                ).map(([university, count]) => (
                  <div
                    key={university}
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: "8px",
                    }}
                  >
                    <div
                      style={{
                        minWidth: "180px",
                        fontSize: "14px",
                        whiteSpace: "nowrap",
                        overflow: "hidden",
                        textOverflow: "ellipsis",
                      }}
                    >
                      {university}
                    </div>
                    <div
                      style={{
                        flex: 1,
                        background: "#e5e7eb",
                        borderRadius: "4px",
                        height: "24px",
                        position: "relative",
                        overflow: "hidden",
                      }}
                    >
                      <div
                        style={{
                          width: `${
                            (count /
                              Math.max(
                                ...Object.values(
                                  analytics.user_metrics.users_by_university
                                )
                              )) *
                            100
                          }%`,
                          background:
                            "linear-gradient(90deg, #10b981, #06b6d4)",
                          height: "100%",
                          borderRadius: "4px",
                          transition: "width 0.3s ease",
                        }}
                      />
                    </div>
                    <div
                      style={{
                        minWidth: "40px",
                        textAlign: "right",
                        fontSize: "14px",
                        fontWeight: "bold",
                      }}
                    >
                      {count}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* By Department */}
            <div>
              <h3 style={{ fontSize: "16px", marginBottom: "12px" }}>
                Top Departments
              </h3>
              <div
                style={{ display: "flex", flexDirection: "column", gap: "8px" }}
              >
                {Object.entries(
                  analytics.user_metrics.users_by_department || {}
                ).map(([department, count]) => (
                  <div
                    key={department}
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: "8px",
                    }}
                  >
                    <div
                      style={{
                        minWidth: "150px",
                        fontSize: "14px",
                        whiteSpace: "nowrap",
                        overflow: "hidden",
                        textOverflow: "ellipsis",
                      }}
                    >
                      {department}
                    </div>
                    <div
                      style={{
                        flex: 1,
                        background: "#e5e7eb",
                        borderRadius: "4px",
                        height: "24px",
                        position: "relative",
                        overflow: "hidden",
                      }}
                    >
                      <div
                        style={{
                          width: `${
                            (count /
                              Math.max(
                                ...Object.values(
                                  analytics.user_metrics.users_by_department
                                )
                              )) *
                            100
                          }%`,
                          background:
                            "linear-gradient(90deg, #f59e0b, #ef4444)",
                          height: "100%",
                          borderRadius: "4px",
                          transition: "width 0.3s ease",
                        }}
                      />
                    </div>
                    <div
                      style={{
                        minWidth: "40px",
                        textAlign: "right",
                        fontSize: "14px",
                        fontWeight: "bold",
                      }}
                    >
                      {count}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Most Used Tags */}
          {analytics.tag_metrics && analytics.tag_metrics.most_used_tags && (
            <div className="card" style={{ marginTop: "16px" }}>
              <h2 style={{ marginBottom: "16px" }}>🏷️ Most Used Tags</h2>
              <div
                style={{
                  display: "grid",
                  gridTemplateColumns: "repeat(auto-fill, minmax(200px, 1fr))",
                  gap: "12px",
                }}
              >
                {analytics.tag_metrics.most_used_tags.map((tag, index) => (
                  <div
                    key={tag.name}
                    style={{
                      padding: "12px",
                      background: `hsl(${index * 36}, 70%, 95%)`,
                      border: `2px solid hsl(${index * 36}, 70%, 60%)`,
                      borderRadius: "8px",
                      textAlign: "center",
                    }}
                  >
                    <div
                      style={{
                        fontSize: "16px",
                        fontWeight: "bold",
                        color: `hsl(${index * 36}, 70%, 30%)`,
                      }}
                    >
                      {tag.name}
                    </div>
                    <div
                      style={{
                        fontSize: "20px",
                        fontWeight: "bold",
                        color: `hsl(${index * 36}, 70%, 40%)`,
                        marginTop: "4px",
                      }}
                    >
                      {tag.count}
                    </div>
                    <div style={{ fontSize: "11px", color: "#6b7280" }}>
                      projects
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
};

export default AdminDashboard;
