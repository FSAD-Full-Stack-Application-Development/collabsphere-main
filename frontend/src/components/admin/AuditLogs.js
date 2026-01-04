import React, { useState, useEffect } from "react";
import { adminService } from "../../apiService";
import "./AuditLogs.css";

const AuditLogs = () => {
  const [logs, setLogs] = useState([]);
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState({
    action: "",
    user_id: "",
    resource_type: "",
    page: 1,
  });

  useEffect(() => {
    loadLogs();
    loadStats();
  }, [filters]);

  const loadLogs = async () => {
    try {
      setLoading(true);
      const response = await adminService.getAuditLogs(filters);
      setLogs(response.data || response);
    } catch (e) {
      console.error("Failed to load audit logs:", e);
    } finally {
      setLoading(false);
    }
  };

  const loadStats = async () => {
    try {
      const statsData = await adminService.getAuditLogStats();
      setStats(statsData);
    } catch (e) {
      console.error("Failed to load audit stats:", e);
    }
  };

  const handleFilterChange = (e) => {
    const { name, value } = e.target;
    setFilters((prev) => ({ ...prev, [name]: value, page: 1 }));
  };

  const getActionBadge = (action) => {
    const badges = {
      user_deleted: { emoji: "🗑️", color: "#dc2626", label: "User Deleted" },
      user_banned: { emoji: "🚫", color: "#ea580c", label: "User Banned" },
      user_unbanned: { emoji: "", color: "#10b981", label: "User Unbanned" },
      project_deleted: {
        emoji: "🗑️",
        color: "#dc2626",
        label: "Project Deleted",
      },
      project_hidden: {
        emoji: "👁️‍🗨️",
        color: "#f59e0b",
        label: "Project Hidden",
      },
      report_resolved: {
        emoji: "✓",
        color: "#10b981",
        label: "Report Resolved",
      },
      report_dismissed: {
        emoji: "✗",
        color: "#6b7280",
        label: "Report Dismissed",
      },
    };

    const badge = badges[action] || {
      emoji: "📝",
      color: "#3b82f6",
      label: action,
    };
    return badge;
  };

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleString();
  };

  return (
    <div className="container" style={{ paddingTop: "20px" }}>
      <div className="card">
        <h1>📜 Audit Logs</h1>
        <p style={{ color: "#6b7280" }}>
          Track all admin actions and moderation activities
        </p>
      </div>

      {/* Stats */}
      {stats && (
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
            gap: "16px",
            marginTop: "16px",
          }}
        >
          <div
            className="card"
            style={{ background: "#f0fdf4", border: "1px solid #bbf7d0" }}
          >
            <div
              style={{ fontSize: "12px", color: "#065f46", fontWeight: "500" }}
            >
              Total Actions
            </div>
            <div
              style={{ fontSize: "28px", fontWeight: "bold", color: "#047857" }}
            >
              {stats.total_actions}
            </div>
          </div>
          <div
            className="card"
            style={{ background: "#eff6ff", border: "1px solid #bfdbfe" }}
          >
            <div
              style={{ fontSize: "12px", color: "#1e3a8a", fontWeight: "500" }}
            >
              Actions Today
            </div>
            <div
              style={{ fontSize: "28px", fontWeight: "bold", color: "#1d4ed8" }}
            >
              {stats.actions_today}
            </div>
          </div>
          <div
            className="card"
            style={{ background: "#fefce8", border: "1px solid #fde047" }}
          >
            <div
              style={{ fontSize: "12px", color: "#713f12", fontWeight: "500" }}
            >
              Actions This Week
            </div>
            <div
              style={{ fontSize: "28px", fontWeight: "bold", color: "#a16207" }}
            >
              {stats.actions_this_week}
            </div>
          </div>
        </div>
      )}

      {/* Filters */}
      <div className="card" style={{ marginTop: "16px" }}>
        <h3 style={{ marginBottom: "12px" }}>Filters</h3>
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
            gap: "12px",
          }}
        >
          <div>
            <label
              style={{
                fontSize: "12px",
                fontWeight: "500",
                display: "block",
                marginBottom: "4px",
              }}
            >
              Action Type:
            </label>
            <select
              className="form-input"
              name="action"
              value={filters.action}
              onChange={handleFilterChange}
            >
              <option value="">All Actions</option>
              <option value="user_deleted">User Deleted</option>
              <option value="user_banned">User Banned</option>
              <option value="user_unbanned">User Unbanned</option>
              <option value="project_deleted">Project Deleted</option>
              <option value="project_hidden">Project Hidden</option>
              <option value="report_resolved">Report Resolved</option>
              <option value="report_dismissed">Report Dismissed</option>
            </select>
          </div>
          <div>
            <label
              style={{
                fontSize: "12px",
                fontWeight: "500",
                display: "block",
                marginBottom: "4px",
              }}
            >
              Resource Type:
            </label>
            <select
              className="form-input"
              name="resource_type"
              value={filters.resource_type}
              onChange={handleFilterChange}
            >
              <option value="">All Resources</option>
              <option value="User">User</option>
              <option value="Project">Project</option>
              <option value="Report">Report</option>
            </select>
          </div>
          <div style={{ display: "flex", alignItems: "flex-end" }}>
            <button
              className="btn btn-sm"
              onClick={() =>
                setFilters({
                  action: "",
                  user_id: "",
                  resource_type: "",
                  page: 1,
                })
              }
              style={{ width: "100%" }}
            >
              Reset Filters
            </button>
          </div>
        </div>
      </div>

      {/* Logs Table */}
      <div className="card" style={{ marginTop: "16px" }}>
        <h3 style={{ marginBottom: "12px" }}>Recent Actions</h3>
        {loading ? (
          <div
            style={{ textAlign: "center", padding: "40px", color: "#6b7280" }}
          >
            Loading logs...
          </div>
        ) : logs.length === 0 ? (
          <div
            style={{ textAlign: "center", padding: "40px", color: "#6b7280" }}
          >
            No audit logs found
          </div>
        ) : (
          <div style={{ overflowX: "auto" }}>
            <table style={{ width: "100%", borderCollapse: "collapse" }}>
              <thead>
                <tr style={{ borderBottom: "2px solid #e5e7eb" }}>
                  <th
                    style={{
                      padding: "12px",
                      textAlign: "left",
                      fontSize: "12px",
                      fontWeight: "600",
                      color: "#6b7280",
                    }}
                  >
                    Action
                  </th>
                  <th
                    style={{
                      padding: "12px",
                      textAlign: "left",
                      fontSize: "12px",
                      fontWeight: "600",
                      color: "#6b7280",
                    }}
                  >
                    Admin
                  </th>
                  <th
                    style={{
                      padding: "12px",
                      textAlign: "left",
                      fontSize: "12px",
                      fontWeight: "600",
                      color: "#6b7280",
                    }}
                  >
                    Resource
                  </th>
                  <th
                    style={{
                      padding: "12px",
                      textAlign: "left",
                      fontSize: "12px",
                      fontWeight: "600",
                      color: "#6b7280",
                    }}
                  >
                    Details
                  </th>
                  <th
                    style={{
                      padding: "12px",
                      textAlign: "left",
                      fontSize: "12px",
                      fontWeight: "600",
                      color: "#6b7280",
                    }}
                  >
                    IP Address
                  </th>
                  <th
                    style={{
                      padding: "12px",
                      textAlign: "left",
                      fontSize: "12px",
                      fontWeight: "600",
                      color: "#6b7280",
                    }}
                  >
                    Date
                  </th>
                </tr>
              </thead>
              <tbody>
                {logs.map((log) => {
                  const badge = getActionBadge(log.action);
                  return (
                    <tr
                      key={log.id}
                      style={{ borderBottom: "1px solid #f3f4f6" }}
                    >
                      <td style={{ padding: "12px" }}>
                        <span
                          style={{
                            display: "inline-block",
                            padding: "4px 8px",
                            borderRadius: "4px",
                            fontSize: "12px",
                            fontWeight: "500",
                            background: `${badge.color}20`,
                            color: badge.color,
                          }}
                        >
                          {badge.emoji} {badge.label}
                        </span>
                      </td>
                      <td style={{ padding: "12px" }}>
                        <div style={{ fontSize: "14px", fontWeight: "500" }}>
                          {log.user?.full_name || "Unknown"}
                        </div>
                        <div style={{ fontSize: "12px", color: "#6b7280" }}>
                          {log.user?.email || ""}
                        </div>
                      </td>
                      <td style={{ padding: "12px" }}>
                        {log.resource_type && (
                          <div style={{ fontSize: "13px" }}>
                            <span style={{ color: "#6b7280" }}>
                              {log.resource_type}
                            </span>
                            {log.resource_id && (
                              <span style={{ color: "#3b82f6" }}>
                                {" "}
                                #{log.resource_id}
                              </span>
                            )}
                          </div>
                        )}
                      </td>
                      <td style={{ padding: "12px", maxWidth: "300px" }}>
                        <div
                          style={{
                            fontSize: "13px",
                            color: "#374151",
                            wordBreak: "break-word",
                          }}
                        >
                          {log.details || "-"}
                        </div>
                      </td>
                      <td style={{ padding: "12px" }}>
                        <div
                          style={{
                            fontSize: "12px",
                            color: "#6b7280",
                            fontFamily: "monospace",
                          }}
                        >
                          {log.ip_address || "-"}
                        </div>
                      </td>
                      <td style={{ padding: "12px" }}>
                        <div
                          style={{
                            fontSize: "12px",
                            color: "#6b7280",
                            whiteSpace: "nowrap",
                          }}
                        >
                          {formatDate(log.created_at)}
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Action Stats by Type */}
      {stats && stats.by_action && Object.keys(stats.by_action).length > 0 && (
        <div className="card" style={{ marginTop: "16px" }}>
          <h3 style={{ marginBottom: "12px" }}>Actions Breakdown</h3>
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
              gap: "12px",
            }}
          >
            {Object.entries(stats.by_action).map(([action, count]) => {
              const badge = getActionBadge(action);
              return (
                <div
                  key={action}
                  style={{
                    padding: "12px",
                    background: "#f9fafb",
                    borderRadius: "6px",
                    border: "1px solid #e5e7eb",
                  }}
                >
                  <div
                    style={{
                      fontSize: "12px",
                      color: "#6b7280",
                      marginBottom: "4px",
                    }}
                  >
                    {badge.emoji} {badge.label}
                  </div>
                  <div
                    style={{
                      fontSize: "24px",
                      fontWeight: "bold",
                      color: badge.color,
                    }}
                  >
                    {count}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
};

export default AuditLogs;
