import React, { useState, useEffect } from "react";
import { adminService } from "../../apiService";
import "./ManageReports.css";

const ManageReports = () => {
  const [reports, setReports] = useState([]);
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalCount, setTotalCount] = useState(0);
  const itemsPerPage = 25;
  const [filters, setFilters] = useState({
    status: "",
    type: "",
  });
  const [selectedReport, setSelectedReport] = useState(null);
  const [actionModal, setActionModal] = useState({
    show: false,
    reportId: null,
    report: null,
  });
  const [detailModal, setDetailModal] = useState({
    show: false,
    type: "",
    id: null,
    data: null,
  });
  const [loadingDetail, setLoadingDetail] = useState(false);

  useEffect(() => {
    fetchReports();
    fetchStats();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filters, currentPage]);

  const fetchReports = async () => {
    try {
      setLoading(true);
      const response = await adminService.getReports({
        ...filters,
        page: currentPage,
        per_page: itemsPerPage,
      });

      // Handle response: {data: [...], meta: {...}}
      const reportsData = response.data || response;
      const metadata = response.meta || {};

      setReports(reportsData);
      setTotalCount(metadata.total_count || reportsData.length);
      setTotalPages(
        metadata.total_pages ||
          Math.ceil((metadata.total_count || reportsData.length) / itemsPerPage)
      );
      setError("");
    } catch (err) {
      setError(
        "Failed to fetch reports: " + (err.response?.data?.error || err.message)
      );
    } finally {
      setLoading(false);
    }
  };

  const fetchStats = async () => {
    try {
      const data = await adminService.getReportStats();
      setStats(data);
    } catch (err) {
      console.error("Failed to fetch stats:", err);
    }
  };

  const handleFilterChange = (e) => {
    const { name, value } = e.target;
    setCurrentPage(1);
    setFilters((prev) => ({ ...prev, [name]: value }));
  };

  const handleBanUser = async (userId, reportId) => {
    if (
      !window.confirm(
        "Ban this user? They will not be able to access the platform."
      )
    )
      return;
    try {
      await adminService.updateUser(userId, { banned: true });
      await adminService.resolveReport(
        reportId,
        "User banned for policy violations"
      );
      alert("User has been banned successfully");
      setActionModal({ show: false, type: "", reportId: null, report: null });
      fetchReports();
      fetchStats();
    } catch (err) {
      alert(
        "Failed to ban user: " + (err.response?.data?.error || err.message)
      );
    }
  };

  const handleDeleteUser = async (userId, reportId) => {
    if (
      !window.confirm(
        "Permanently delete this user? This action CANNOT be undone!"
      )
    )
      return;
    try {
      await adminService.deleteUser(userId);
      await adminService.resolveReport(reportId, "User permanently deleted");
      alert("User has been deleted successfully");
      setActionModal({ show: false, type: "", reportId: null, report: null });
      fetchReports();
      fetchStats();
    } catch (err) {
      alert(
        "Failed to delete user: " + (err.response?.data?.error || err.message)
      );
    }
  };

  const handleDeleteProject = async (projectId, reportId) => {
    if (
      !window.confirm(
        "Permanently delete this project? This action CANNOT be undone!"
      )
    )
      return;
    try {
      await adminService.deleteProject(projectId);
      await adminService.resolveReport(reportId, "Project permanently deleted");
      alert("Project has been deleted successfully");
      setActionModal({ show: false, type: "", reportId: null, report: null });
      fetchReports();
      fetchStats();
    } catch (err) {
      alert(
        "Failed to delete project: " +
          (err.response?.data?.error || err.message)
      );
    }
  };

  const handleHideProject = async (projectId, reportId) => {
    if (
      !window.confirm(
        "Hide this project? It will be set to private and marked as inactive."
      )
    )
      return;
    try {
      await adminService.updateProject(projectId, {
        visibility: "private",
        status: "inactive",
      });
      await adminService.resolveReport(
        reportId,
        "Project hidden (set to private/inactive)"
      );
      alert("Project has been hidden successfully");
      setActionModal({ show: false, type: "", reportId: null, report: null });
      fetchReports();
      fetchStats();
    } catch (err) {
      alert(
        "Failed to hide project: " + (err.response?.data?.error || err.message)
      );
    }
  };

  const handleDismissReport = async (reportId, reason) => {
    try {
      await adminService.dismissReport(
        reportId,
        reason || "No policy violation found"
      );
      alert("Report dismissed - no action taken");
      setActionModal({ show: false, type: "", reportId: null, report: null });
      fetchReports();
      fetchStats();
    } catch (err) {
      alert(
        "Failed to dismiss report: " +
          (err.response?.data?.error || err.message)
      );
    }
  };

  const openActionModal = (reportId, report) => {
    setActionModal({ show: true, reportId, report });
  };

  const fetchUserDetails = async (userId) => {
    setLoadingDetail(true);
    try {
      const response = await adminService.getUsers({ q: "", id: userId });
      const user = Array.isArray(response)
        ? response.find((u) => u.id === userId)
        : response;
      setDetailModal({
        show: true,
        type: "user",
        id: userId,
        data: user || {},
      });
    } catch (err) {
      alert("Failed to load user details");
    } finally {
      setLoadingDetail(false);
    }
  };

  const fetchProjectDetails = async (projectId) => {
    setLoadingDetail(true);
    try {
      const response = await adminService.getProjects({ q: "", id: projectId });
      const project = Array.isArray(response)
        ? response.find((p) => p.id === projectId)
        : response;
      setDetailModal({
        show: true,
        type: "project",
        id: projectId,
        data: project || {},
      });
    } catch (err) {
      alert("Failed to load project details");
    } finally {
      setLoadingDetail(false);
    }
  };

  const openDetailModal = (type, id) => {
    if (type === "User") {
      fetchUserDetails(id);
    } else if (type === "Project") {
      fetchProjectDetails(id);
    }
  };

  const getStatusBadge = (status) => {
    const badges = {
      pending: "🟡 Pending Review",
      reviewing: "🔵 Under Review",
      resolved: "🟢 Valid (Resolved)",
      dismissed: "⚪ Invalid (Dismissed)",
    };
    return badges[status] || status;
  };

  const getTypeBadge = (type) => {
    const badges = {
      User: "👤 User",
      Project: "📁 Project",
      Comment: "💬 Comment",
      Tag: "🏷️ Tag",
    };
    return badges[type] || type;
  };

  if (loading && !reports.length) {
    return <div className="loading">Loading reports...</div>;
  }

  return (
    <div className="manage-reports">
      <div className="reports-header">
        <h2>Manage Reports</h2>
        {stats && (
          <div className="stats-summary">
            <div className="stat-card">
              <span className="stat-value">{stats.total}</span>
              <span className="stat-label">Total Reports</span>
            </div>
            <div className="stat-card pending">
              <span className="stat-value">
                {stats.by_status?.pending || 0}
              </span>
              <span className="stat-label">Pending Review</span>
            </div>
            <div className="stat-card resolved">
              <span className="stat-value">
                {stats.by_status?.resolved || 0}
              </span>
              <span className="stat-label">Valid Reports</span>
            </div>
            <div className="stat-card dismissed">
              <span className="stat-value">
                {stats.by_status?.dismissed || 0}
              </span>
              <span className="stat-label">Invalid Reports</span>
            </div>
          </div>
        )}
      </div>

      {error && <div className="error-message">{error}</div>}

      <div className="filters">
        <div className="filter-group">
          <label>Status:</label>
          <select
            name="status"
            value={filters.status}
            onChange={handleFilterChange}
          >
            <option value="">All Statuses</option>
            <option value="pending">Pending Review</option>
            <option value="reviewing">Under Review</option>
            <option value="resolved">Valid (Resolved)</option>
            <option value="dismissed">Invalid (Dismissed)</option>
          </select>
        </div>

        <div className="filter-group">
          <label>Type:</label>
          <select
            name="type"
            value={filters.type}
            onChange={handleFilterChange}
          >
            <option value="">All Types</option>
            <option value="User">User</option>
            <option value="Project">Project</option>
            <option value="Comment">Comment</option>
            <option value="Tag">Tag</option>
          </select>
        </div>

        <button
          onClick={() => setFilters({ status: "", type: "" })}
          className="btn-reset"
        >
          Reset Filters
        </button>
      </div>

      <div className="reports-list">
        {reports.length === 0 ? (
          <div className="no-reports">No reports found</div>
        ) : (
          <table>
            <thead>
              <tr>
                <th>ID</th>
                <th>Type</th>
                <th>Reported Item</th>
                <th>Reporter</th>
                <th>Reason</th>
                <th>Status</th>
                <th>Date</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {reports.map((report) => (
                <tr key={report.id}>
                  <td>#{report.id}</td>
                  <td>
                    <span className="badge type-badge">
                      {getTypeBadge(report.reportable_type)}
                    </span>
                  </td>
                  <td>
                    <div className="reportable-info">
                      {report.reportable_type === "User" ||
                      report.reportable_type === "Project" ? (
                        <button
                          className="link-button"
                          onClick={() =>
                            openDetailModal(
                              report.reportable_type,
                              report.reportable_details?.id
                            )
                          }
                          title={`View ${report.reportable_type} details`}
                        >
                          <strong>
                            {report.reportable_details?.name ||
                              report.reportable_details?.title ||
                              "N/A"}
                          </strong>
                        </button>
                      ) : (
                        <strong>
                          {report.reportable_details?.name ||
                            report.reportable_details?.title ||
                            report.reportable_details?.content?.substring(
                              0,
                              30
                            ) ||
                            "N/A"}
                        </strong>
                      )}
                      <small>
                        {report.reportable_details?.email ||
                          report.reportable_details?.owner}
                      </small>
                    </div>
                  </td>
                  <td>
                    <div className="reporter-info">
                      <strong>{report.reporter?.full_name}</strong>
                      <small>{report.reporter?.email}</small>
                    </div>
                  </td>
                  <td>
                    <div className="reason-cell">
                      <strong>{report.reason}</strong>
                      {report.description && (
                        <small title={report.description}>
                          {report.description.substring(0, 50)}...
                        </small>
                      )}
                    </div>
                  </td>
                  <td>
                    <span
                      className={`badge status-badge status-${report.status}`}
                    >
                      {getStatusBadge(report.status)}
                    </span>
                  </td>
                  <td>{new Date(report.created_at).toLocaleDateString()}</td>
                  <td>
                    <div className="action-buttons">
                      {(report.status === "pending" ||
                        report.status === "reviewing") && (
                        <button
                          onClick={() => openActionModal(report.id, report)}
                          className="btn-action"
                          title="Take action on this report"
                        >
                          ⚡ Take Action
                        </button>
                      )}
                      <button
                        onClick={() => setSelectedReport(report)}
                        className="btn-view"
                        title="View full report details"
                      >
                        👁️ View
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}

        {/* Pagination Controls */}
        {!loading && reports.length > 0 && (
          <div
            style={{
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
              marginTop: "20px",
              padding: "16px",
              background: "#f9fafb",
              borderRadius: "8px",
            }}
          >
            <div style={{ fontSize: "14px", color: "#6b7280" }}>
              Showing {(currentPage - 1) * itemsPerPage + 1} to{" "}
              {Math.min(currentPage * itemsPerPage, totalCount)} of {totalCount}{" "}
              reports
            </div>
            <div style={{ display: "flex", gap: "8px", alignItems: "center" }}>
              <button
                className="btn btn-sm"
                onClick={() => setCurrentPage(1)}
                disabled={currentPage === 1}
                style={{ opacity: currentPage === 1 ? 0.5 : 1 }}
              >
                First
              </button>
              <button
                className="btn btn-sm"
                onClick={() => setCurrentPage(currentPage - 1)}
                disabled={currentPage === 1}
                style={{ opacity: currentPage === 1 ? 0.5 : 1 }}
              >
                Previous
              </button>
              <span style={{ padding: "0 12px", fontSize: "14px" }}>
                Page {currentPage} of {totalPages}
              </span>
              <button
                className="btn btn-sm"
                onClick={() => setCurrentPage(currentPage + 1)}
                disabled={currentPage === totalPages}
                style={{ opacity: currentPage === totalPages ? 0.5 : 1 }}
              >
                Next
              </button>
              <button
                className="btn btn-sm"
                onClick={() => setCurrentPage(totalPages)}
                disabled={currentPage === totalPages}
                style={{ opacity: currentPage === totalPages ? 0.5 : 1 }}
              >
                Last
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Action Modal */}
      {actionModal.show && (
        <div
          className="modal-overlay"
          onClick={() =>
            setActionModal({ show: false, reportId: null, report: null })
          }
        >
          <div
            className="modal-content"
            onClick={(e) => e.stopPropagation()}
            style={{ maxWidth: "600px" }}
          >
            <h3>⚡ Take Action on Report</h3>

            {actionModal.report && (
              <div
                style={{
                  background: "#f3f4f6",
                  padding: "12px",
                  borderRadius: "6px",
                  marginBottom: "16px",
                }}
              >
                <div style={{ marginBottom: "8px" }}>
                  <strong>
                    Reported {actionModal.report.reportable_type}:
                  </strong>{" "}
                  {actionModal.report.reportable_details?.name ||
                    actionModal.report.reportable_details?.title ||
                    "N/A"}
                </div>
                <div style={{ marginBottom: "8px" }}>
                  <strong>Reason:</strong> {actionModal.report.reason}
                </div>
                {actionModal.report.description && (
                  <div style={{ fontSize: "14px", color: "#6b7280" }}>
                    <strong>Details:</strong> {actionModal.report.description}
                  </div>
                )}
              </div>
            )}

            <p
              style={{
                fontSize: "14px",
                color: "#374151",
                marginBottom: "16px",
              }}
            >
              Choose an action to take on the reported{" "}
              {actionModal.report?.reportable_type?.toLowerCase() || "item"}:
            </p>

            {/* User Actions */}
            {actionModal.report?.reportable_type === "User" && (
              <div
                className="action-buttons-grid"
                style={{ display: "grid", gap: "12px", marginBottom: "16px" }}
              >
                <button
                  onClick={() =>
                    handleBanUser(
                      actionModal.report.reportable_details.id,
                      actionModal.reportId
                    )
                  }
                  className="btn-action-danger"
                  style={{
                    padding: "12px",
                    background: "#dc2626",
                    color: "white",
                    border: "none",
                    borderRadius: "6px",
                    cursor: "pointer",
                    fontSize: "14px",
                    fontWeight: "500",
                  }}
                >
                  🚫 Ban User - User cannot access the platform
                </button>
                <button
                  onClick={() =>
                    handleDeleteUser(
                      actionModal.report.reportable_details.id,
                      actionModal.reportId
                    )
                  }
                  className="btn-action-danger"
                  style={{
                    padding: "12px",
                    background: "#991b1b",
                    color: "white",
                    border: "none",
                    borderRadius: "6px",
                    cursor: "pointer",
                    fontSize: "14px",
                    fontWeight: "500",
                  }}
                >
                  🗑️ Delete User - Permanently remove user and all data
                </button>
              </div>
            )}

            {/* Project Actions */}
            {actionModal.report?.reportable_type === "Project" && (
              <div
                className="action-buttons-grid"
                style={{ display: "grid", gap: "12px", marginBottom: "16px" }}
              >
                <button
                  onClick={() =>
                    handleHideProject(
                      actionModal.report.reportable_details.id,
                      actionModal.reportId
                    )
                  }
                  className="btn-action-warning"
                  style={{
                    padding: "12px",
                    background: "#ea580c",
                    color: "white",
                    border: "none",
                    borderRadius: "6px",
                    cursor: "pointer",
                    fontSize: "14px",
                    fontWeight: "500",
                  }}
                >
                  👁️‍🗨️ Hide Project - Set to private and inactive
                </button>
                <button
                  onClick={() =>
                    handleDeleteProject(
                      actionModal.report.reportable_details.id,
                      actionModal.reportId
                    )
                  }
                  className="btn-action-danger"
                  style={{
                    padding: "12px",
                    background: "#991b1b",
                    color: "white",
                    border: "none",
                    borderRadius: "6px",
                    cursor: "pointer",
                    fontSize: "14px",
                    fontWeight: "500",
                  }}
                >
                  🗑️ Delete Project - Permanently remove project
                </button>
              </div>
            )}

            {/* Dismiss Option */}
            <div
              style={{
                borderTop: "1px solid #e5e7eb",
                paddingTop: "16px",
                marginTop: "16px",
              }}
            >
              <p
                style={{
                  fontSize: "14px",
                  color: "#6b7280",
                  marginBottom: "12px",
                }}
              >
                Or dismiss this report if no action is needed:
              </p>
              <button
                onClick={() =>
                  handleDismissReport(
                    actionModal.reportId,
                    "No policy violation found"
                  )
                }
                className="btn-dismiss"
                style={{
                  padding: "10px 16px",
                  background: "#f3f4f6",
                  color: "#374151",
                  border: "1px solid #d1d5db",
                  borderRadius: "6px",
                  cursor: "pointer",
                  fontSize: "14px",
                  width: "100%",
                }}
              >
                ✗ Dismiss Report - No policy violation
              </button>
            </div>

            <div
              style={{
                marginTop: "16px",
                display: "flex",
                justifyContent: "flex-end",
              }}
            >
              <button
                onClick={() =>
                  setActionModal({ show: false, reportId: null, report: null })
                }
                className="btn-cancel"
                style={{
                  padding: "8px 16px",
                  background: "white",
                  border: "1px solid #d1d5db",
                  borderRadius: "6px",
                  cursor: "pointer",
                }}
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Report Details Modal */}
      {selectedReport && (
        <div className="modal-overlay" onClick={() => setSelectedReport(null)}>
          <div
            className="modal-content report-details"
            onClick={(e) => e.stopPropagation()}
          >
            <h3>Report Details</h3>
            <div className="detail-section">
              <label>Report ID:</label>
              <span>#{selectedReport.id}</span>
            </div>
            <div className="detail-section">
              <label>Type:</label>
              <span>{getTypeBadge(selectedReport.reportable_type)}</span>
            </div>
            <div className="detail-section">
              <label>Reported Item:</label>
              <div>
                <strong>
                  {selectedReport.reportable_details?.name ||
                    selectedReport.reportable_details?.title ||
                    "N/A"}
                </strong>
                <br />
                <small>
                  {selectedReport.reportable_details?.email ||
                    selectedReport.reportable_details?.owner}
                </small>
              </div>
            </div>
            <div className="detail-section">
              <label>Reporter:</label>
              <div>
                <strong>{selectedReport.reporter?.full_name}</strong>
                <br />
                <small>{selectedReport.reporter?.email}</small>
              </div>
            </div>
            <div className="detail-section">
              <label>Reason:</label>
              <span>{selectedReport.reason}</span>
            </div>
            {selectedReport.description && (
              <div className="detail-section">
                <label>Description:</label>
                <p>{selectedReport.description}</p>
              </div>
            )}
            <div className="detail-section">
              <label>Status:</label>
              <span>{getStatusBadge(selectedReport.status)}</span>
            </div>
            <div className="detail-section">
              <label>Reported At:</label>
              <span>
                {new Date(selectedReport.created_at).toLocaleString()}
              </span>
            </div>
            {selectedReport.resolved_at && (
              <>
                <div className="detail-section">
                  <label>Resolved At:</label>
                  <span>
                    {new Date(selectedReport.resolved_at).toLocaleString()}
                  </span>
                </div>
                <div className="detail-section">
                  <label>Resolved By:</label>
                  <span>{selectedReport.resolved_by?.full_name}</span>
                </div>
              </>
            )}
            <button
              onClick={() => setSelectedReport(null)}
              className="btn-close"
            >
              Close
            </button>
          </div>
        </div>
      )}

      {/* User/Project Detail Modal */}
      {detailModal.show && (
        <div
          className="modal-overlay"
          onClick={() =>
            setDetailModal({ show: false, type: "", id: null, data: null })
          }
        >
          <div
            className="modal-content detail-modal"
            onClick={(e) => e.stopPropagation()}
          >
            {loadingDetail ? (
              <div className="loading">Loading details...</div>
            ) : detailModal.type === "user" ? (
              <>
                <h3>User Details</h3>
                <div className="detail-section">
                  <label>Name:</label>
                  <span>{detailModal.data?.full_name || "N/A"}</span>
                </div>
                <div className="detail-section">
                  <label>Email:</label>
                  <span>{detailModal.data?.email || "N/A"}</span>
                </div>
                <div className="detail-section">
                  <label>Role:</label>
                  <span>{detailModal.data?.system_role || "user"}</span>
                </div>
                <div className="detail-section">
                  <label>Country:</label>
                  <span>{detailModal.data?.country || "N/A"}</span>
                </div>
                <div className="detail-section">
                  <label>University:</label>
                  <span>{detailModal.data?.university || "N/A"}</span>
                </div>
                <div className="detail-section">
                  <label>Department:</label>
                  <span>{detailModal.data?.department || "N/A"}</span>
                </div>
                <div className="detail-section">
                  <label>Status:</label>
                  <span>
                    {detailModal.data?.banned ? "🚫 Banned" : " Active"}
                  </span>
                </div>
                <div className="detail-section">
                  <label>Reports:</label>
                  <span>{detailModal.data?.reports_count || 0} report(s)</span>
                </div>
                <div className="detail-section">
                  <label>Joined:</label>
                  <span>
                    {detailModal.data?.created_at
                      ? new Date(
                          detailModal.data.created_at
                        ).toLocaleDateString()
                      : "N/A"}
                  </span>
                </div>
              </>
            ) : (
              <>
                <h3>Project Details</h3>
                <div className="detail-section">
                  <label>Title:</label>
                  <span>{detailModal.data?.title || "N/A"}</span>
                </div>
                <div className="detail-section">
                  <label>Description:</label>
                  <p>{detailModal.data?.description || "N/A"}</p>
                </div>
                <div className="detail-section">
                  <label>Owner:</label>
                  <div>
                    <strong>
                      {detailModal.data?.owner?.full_name || "N/A"}
                    </strong>
                    <br />
                    <small>{detailModal.data?.owner?.email}</small>
                  </div>
                </div>
                <div className="detail-section">
                  <label>Status:</label>
                  <span>{detailModal.data?.status || "N/A"}</span>
                </div>
                <div className="detail-section">
                  <label>Visibility:</label>
                  <span>{detailModal.data?.visibility || "N/A"}</span>
                </div>
                <div className="detail-section">
                  <label>Reports:</label>
                  <span>{detailModal.data?.reports_count || 0} report(s)</span>
                </div>
                {detailModal.data?.project_stat && (
                  <>
                    <div className="detail-section">
                      <label>Views:</label>
                      <span>
                        {detailModal.data.project_stat.total_views || 0}
                      </span>
                    </div>
                    <div className="detail-section">
                      <label>Votes:</label>
                      <span>
                        {detailModal.data.project_stat.total_votes || 0}
                      </span>
                    </div>
                    <div className="detail-section">
                      <label>Comments:</label>
                      <span>
                        {detailModal.data.project_stat.total_comments || 0}
                      </span>
                    </div>
                  </>
                )}
                <div className="detail-section">
                  <label>Created:</label>
                  <span>
                    {detailModal.data?.created_at
                      ? new Date(
                          detailModal.data.created_at
                        ).toLocaleDateString()
                      : "N/A"}
                  </span>
                </div>
              </>
            )}
            <button
              onClick={() =>
                setDetailModal({ show: false, type: "", id: null, data: null })
              }
              className="btn-close"
            >
              Close
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default ManageReports;
