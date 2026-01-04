import React, { useState, useEffect } from "react";
import { apiLogService } from "../../apiService";

const ApiLogs = () => {
  const [logs, setLogs] = useState([]);
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [period, setPeriod] = useState("today");
  const [filters, setFilters] = useState({
    page: 1,
    per_page: 50,
  });
  const [meta, setMeta] = useState({});

  useEffect(() => {
    loadLogs();
    loadStats();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filters, period]);

  const loadLogs = async () => {
    try {
      setLoading(true);
      const data = await apiLogService.getLogs(filters);
      setLogs(data.logs);
      setMeta(data.meta);
    } catch (error) {
      console.error("Failed to load logs:", error);
    } finally {
      setLoading(false);
    }
  };

  const loadStats = async () => {
    try {
      const data = await apiLogService.getStats(period);
      setStats(data.stats);
    } catch (error) {
      console.error("Failed to load stats:", error);
    }
  };

  const handleCleanup = async () => {
    if (
      window.confirm("Are you sure you want to delete logs older than 30 days?")
    ) {
      try {
        const result = await apiLogService.cleanup(30);
        alert(result.message);
        loadLogs();
        loadStats();
      } catch (error) {
        alert("Failed to cleanup logs");
      }
    }
  };

  const getStatusColor = (status) => {
    if (status >= 200 && status < 300) return "#10b981"; // green
    if (status >= 400 && status < 500) return "#f59e0b"; // yellow
    if (status >= 500) return "#ef4444"; // red
    return "#6b7280"; // gray
  };

  const getMethodColor = (method) => {
    const colors = {
      GET: "#3b82f6",
      POST: "#10b981",
      PUT: "#f59e0b",
      PATCH: "#8b5cf6",
      DELETE: "#ef4444",
    };
    return colors[method] || "#6b7280";
  };

  if (loading && logs.length === 0) {
    return <div className="text-center p-4">Loading logs...</div>;
  }

  return (
    <div style={{ padding: "24px" }}>
      <div style={{ marginBottom: "24px" }}>
        <h1 style={{ marginBottom: "8px" }}>API Request Logs</h1>
        <p style={{ color: "#6b7280" }}>
          Monitor all API requests, track success rates, and analyze usage
          patterns
        </p>
      </div>

      {/* Statistics Cards */}
      {stats && (
        <div style={{ marginBottom: "24px" }}>
          <div style={{ display: "flex", gap: "12px", marginBottom: "16px" }}>
            <button
              onClick={() => setPeriod("today")}
              className={
                period === "today" ? "btn btn-primary" : "btn btn-secondary"
              }
            >
              Today
            </button>
            <button
              onClick={() => setPeriod("week")}
              className={
                period === "week" ? "btn btn-primary" : "btn btn-secondary"
              }
            >
              This Week
            </button>
            <button
              onClick={() => setPeriod("month")}
              className={
                period === "month" ? "btn btn-primary" : "btn btn-secondary"
              }
            >
              This Month
            </button>
            <button
              onClick={handleCleanup}
              className="btn btn-danger"
              style={{ marginLeft: "auto" }}
            >
              Cleanup Old Logs
            </button>
          </div>

          <div
            style={{
              display: "grid",
              gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
              gap: "16px",
              marginBottom: "24px",
            }}
          >
            <div className="card" style={{ padding: "16px" }}>
              <div
                style={{
                  fontSize: "24px",
                  fontWeight: "bold",
                  color: "#3b82f6",
                }}
              >
                {stats.total_requests}
              </div>
              <div style={{ color: "#6b7280", fontSize: "14px" }}>
                Total Requests
              </div>
            </div>

            <div className="card" style={{ padding: "16px" }}>
              <div
                style={{
                  fontSize: "24px",
                  fontWeight: "bold",
                  color: "#10b981",
                }}
              >
                {stats.successful_requests}
              </div>
              <div style={{ color: "#6b7280", fontSize: "14px" }}>
                Successful
              </div>
            </div>

            <div className="card" style={{ padding: "16px" }}>
              <div
                style={{
                  fontSize: "24px",
                  fontWeight: "bold",
                  color: "#ef4444",
                }}
              >
                {stats.failed_requests}
              </div>
              <div style={{ color: "#6b7280", fontSize: "14px" }}>Failed</div>
            </div>

            <div className="card" style={{ padding: "16px" }}>
              <div
                style={{
                  fontSize: "24px",
                  fontWeight: "bold",
                  color: "#8b5cf6",
                }}
              >
                {stats.success_rate}%
              </div>
              <div style={{ color: "#6b7280", fontSize: "14px" }}>
                Success Rate
              </div>
            </div>

            <div className="card" style={{ padding: "16px" }}>
              <div
                style={{
                  fontSize: "24px",
                  fontWeight: "bold",
                  color: "#f59e0b",
                }}
              >
                {stats.avg_duration}ms
              </div>
              <div style={{ color: "#6b7280", fontSize: "14px" }}>
                Avg Duration
              </div>
            </div>
          </div>

          {/* Top Endpoints */}
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "1fr 1fr",
              gap: "16px",
            }}
          >
            <div className="card" style={{ padding: "16px" }}>
              <h3 style={{ marginBottom: "12px" }}>Top Endpoints</h3>
              <div style={{ maxHeight: "200px", overflow: "auto" }}>
                {Object.entries(stats.top_endpoints).map(([path, count]) => (
                  <div
                    key={path}
                    style={{
                      display: "flex",
                      justifyContent: "space-between",
                      padding: "8px 0",
                      borderBottom: "1px solid #e5e7eb",
                    }}
                  >
                    <span style={{ fontSize: "12px", color: "#374151" }}>
                      {path}
                    </span>
                    <span style={{ fontWeight: "bold" }}>{count}</span>
                  </div>
                ))}
              </div>
            </div>

            <div className="card" style={{ padding: "16px" }}>
              <h3 style={{ marginBottom: "12px" }}>Requests by Method</h3>
              <div>
                {Object.entries(stats.requests_by_method).map(
                  ([method, count]) => (
                    <div
                      key={method}
                      style={{
                        display: "flex",
                        justifyContent: "space-between",
                        padding: "8px 0",
                        borderBottom: "1px solid #e5e7eb",
                      }}
                    >
                      <span
                        style={{
                          fontWeight: "bold",
                          color: getMethodColor(method),
                        }}
                      >
                        {method}
                      </span>
                      <span>{count}</span>
                    </div>
                  )
                )}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Logs Table */}
      <div className="card">
        <div style={{ overflowX: "auto" }}>
          <table className="table">
            <thead>
              <tr>
                <th>Timestamp</th>
                <th>Method</th>
                <th>Path</th>
                <th>Status</th>
                <th>Duration</th>
                <th>IP Address</th>
                <th>User</th>
              </tr>
            </thead>
            <tbody>
              {logs.map((log) => (
                <tr key={log.id}>
                  <td style={{ fontSize: "12px" }}>
                    {new Date(log.created_at).toLocaleString()}
                  </td>
                  <td>
                    <span
                      style={{
                        padding: "4px 8px",
                        borderRadius: "4px",
                        fontSize: "12px",
                        fontWeight: "bold",
                        color: "white",
                        backgroundColor: getMethodColor(log.request_method),
                      }}
                    >
                      {log.request_method}
                    </span>
                  </td>
                  <td
                    style={{
                      fontSize: "12px",
                      maxWidth: "300px",
                      overflow: "hidden",
                      textOverflow: "ellipsis",
                    }}
                  >
                    {log.request_path}
                  </td>
                  <td>
                    <span
                      style={{
                        padding: "4px 8px",
                        borderRadius: "4px",
                        fontSize: "12px",
                        fontWeight: "bold",
                        color: "white",
                        backgroundColor: getStatusColor(log.response_status),
                      }}
                    >
                      {log.response_status}
                    </span>
                  </td>
                  <td style={{ fontSize: "12px" }}>
                    {log.duration ? `${log.duration.toFixed(2)}ms` : "N/A"}
                  </td>
                  <td style={{ fontSize: "12px" }}>{log.ip_address}</td>
                  <td style={{ fontSize: "12px" }}>
                    {log.user ? log.user.full_name : "Anonymous"}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        {meta.total_pages > 1 && (
          <div
            style={{
              display: "flex",
              justifyContent: "center",
              gap: "8px",
              padding: "16px",
            }}
          >
            <button
              onClick={() => setFilters({ ...filters, page: filters.page - 1 })}
              disabled={filters.page === 1}
              className="btn btn-secondary"
            >
              Previous
            </button>
            <span style={{ padding: "8px 16px" }}>
              Page {meta.current_page} of {meta.total_pages}
            </span>
            <button
              onClick={() => setFilters({ ...filters, page: filters.page + 1 })}
              disabled={filters.page >= meta.total_pages}
              className="btn btn-secondary"
            >
              Next
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export default ApiLogs;
