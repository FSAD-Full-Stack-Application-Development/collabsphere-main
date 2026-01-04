import React, { useEffect, useState } from "react";
import { adminService } from "../../apiService";
import "./Leaderboard.css";

const Leaderboard = () => {
  const [activeTab, setActiveTab] = useState("most_viewed");
  const [mostViewedProjects, setMostViewedProjects] = useState([]);
  const [mostVotedProjects, setMostVotedProjects] = useState([]);
  const [mostCommentedProjects, setMostCommentedProjects] = useState([]);
  const [mostActiveCollaborators, setMostActiveCollaborators] = useState([]);
  const [mostFundedProjects, setMostFundedProjects] = useState([]);
  const [topFunders, setTopFunders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  // Filter options
  const [availableFilters, setAvailableFilters] = useState({
    countries: [],
    universities: [],
    departments: [],
  });

  const [filters, setFilters] = useState({
    country: "",
    university: "",
    department: "",
  });

  const [countryUniversities, setCountryUniversities] = useState([]);
  const [universityDepartments, setUniversityDepartments] = useState([]);

  // Detail modals
  const [projectDetailModal, setProjectDetailModal] = useState({
    show: false,
    project: null,
  });
  const [userDetailModal, setUserDetailModal] = useState({
    show: false,
    user: null,
  });

  useEffect(() => {
    loadFilterOptions();
  }, []);

  useEffect(() => {
    loadLeaderboards();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filters]);

  useEffect(() => {
    if (filters.university) {
      loadDepartmentsByUniversity(filters.university);
    } else {
      setUniversityDepartments([]);
    }
  }, [filters.university]);

  useEffect(() => {
    if (filters.country) {
      loadUniversitiesByCountry(filters.country);
    } else {
      setCountryUniversities([]);
    }
  }, [filters.country]);

  const loadFilterOptions = async () => {
    try {
      const data = await adminService.getLeaderboardFilters();
      setAvailableFilters(data);
    } catch (e) {
      console.error("Failed to load filter options:", e);
    }
  };

  const loadDepartmentsByUniversity = async (university) => {
    try {
      const data = await adminService.getDepartmentsByUniversity(university);
      setUniversityDepartments(data.departments || []);
    } catch (e) {
      console.error("Failed to load departments:", e);
    }
  };

  const loadUniversitiesByCountry = async (country) => {
    try {
      const data = await adminService.getUniversitiesByCountry(country);
      setCountryUniversities(data.universities || []);
    } catch (e) {
      console.error("Failed to load universities:", e);
    }
  };

  const loadLeaderboards = async () => {
    try {
      setLoading(true);
      setError("");

      const [viewed, voted, commented, collaborators, funded, funders] =
        await Promise.all([
          adminService.getMostViewedProjects(filters),
          adminService.getMostVotedProjects(filters),
          adminService.getMostCommentedProjects(filters),
          adminService.getMostActiveCollaborators(filters),
          adminService.getMostFundedProjects(filters),
          adminService.getTopFunders(filters),
        ]);

      setMostViewedProjects(viewed);
      setMostVotedProjects(voted);
      setMostCommentedProjects(commented);
      setMostActiveCollaborators(collaborators);
      setMostFundedProjects(funded);
      setTopFunders(funders);
    } catch (e) {
      console.error("Failed to load leaderboards:", e);
      setError("Failed to load leaderboard data");
    } finally {
      setLoading(false);
    }
  };

  const handleFilterChange = (e) => {
    const { name, value } = e.target;
    setFilters((prev) => {
      const newFilters = { ...prev, [name]: value };
      // Reset university and department if country changes
      if (name === "country") {
        newFilters.university = "";
        newFilters.department = "";
      }
      // Reset department if university changes
      if (name === "university") {
        newFilters.department = "";
      }
      return newFilters;
    });
  };

  const resetFilters = () => {
    setFilters({ country: "", university: "", department: "" });
    setCountryUniversities([]);
    setUniversityDepartments([]);
  };

  const openProjectDetail = async (project) => {
    setProjectDetailModal({ show: true, project });
    try {
      const fullProjectData = await adminService.getProject(project.id);
      setProjectDetailModal({ show: true, project: fullProjectData });
    } catch (e) {
      console.error("Failed to fetch project details:", e);
    }
  };

  const openUserDetail = async (user) => {
    setUserDetailModal({ show: true, user });
    try {
      const fullUserData = await adminService.getUser(user.id);
      setUserDetailModal({ show: true, user: fullUserData });
    } catch (e) {
      console.error("Failed to fetch user details:", e);
    }
  };

  const renderProjectRow = (project, index, metric, metricLabel) => (
    <div
      key={project.id}
      className="leaderboard-row"
      onClick={() => openProjectDetail(project)}
      style={{ cursor: "pointer" }}
    >
      <div className="rank">#{index + 1}</div>
      <div className="project-info">
        <div className="project-title">{project.title}</div>
        <div className="project-meta">
          <span>Owner: {project.owner?.full_name}</span>
          {project.owner?.university && (
            <span> • {project.owner.university}</span>
          )}
          {project.owner?.country && <span> • {project.owner.country}</span>}
        </div>
        {project.tags && project.tags.length > 0 && (
          <div className="project-tags">
            {project.tags.map((tag) => (
              <span key={tag.id} className="tag-badge">
                {tag.tag_name}
              </span>
            ))}
          </div>
        )}
      </div>
      <div className="metric-value">
        <div className="metric-number">{metric}</div>
        <div className="metric-label">{metricLabel}</div>
      </div>
      <div className="stats-mini">
        <span title="Views">👁️ {project.project_stat?.total_views || 0}</span>
        <span title="Votes">👍 {project.project_stat?.total_votes || 0}</span>
        <span title="Comments">
          💬 {project.project_stat?.total_comments || 0}
        </span>
      </div>
    </div>
  );

  const renderUserRow = (user, index) => (
    <div
      key={user.id}
      className="leaderboard-row"
      onClick={() => openUserDetail(user)}
      style={{ cursor: "pointer" }}
    >
      <div className="rank">#{index + 1}</div>
      <div className="project-info">
        <div className="project-title">{user.full_name}</div>
        <div className="project-meta">
          <span>{user.email}</span>
          {user.university && <span> • {user.university}</span>}
          {user.department && <span> • {user.department}</span>}
          {user.country && <span> • {user.country}</span>}
        </div>
        {user.collaborations && user.collaborations.length > 0 && (
          <div className="collaborations-list">
            {user.collaborations.slice(0, 3).map((collab) => (
              <span key={collab.id} className="collab-badge">
                {collab.project?.title || `Project #${collab.project_id}`} (
                {collab.project_role})
              </span>
            ))}
            {user.collaborations.length > 3 && (
              <span className="collab-badge">
                +{user.collaborations.length - 3} more
              </span>
            )}
          </div>
        )}
      </div>
      <div className="metric-value">
        <div className="metric-number">{user.collaborations_count || 0}</div>
        <div className="metric-label">Projects</div>
      </div>
    </div>
  );

  if (loading && mostViewedProjects.length === 0) {
    return (
      <div className="container" style={{ paddingTop: "20px" }}>
        <div className="loading">
          <div className="spinner"></div>
        </div>
      </div>
    );
  }

  return (
    <div className="container" style={{ paddingTop: "20px" }}>
      <div className="card">
        <h1>🏆 Leaderboards</h1>
        {error && <div className="alert alert-error">{error}</div>}

        {/* Filters */}
        <div className="filters-section">
          <h3>Filter By Location</h3>
          <div className="filters-grid">
            <div>
              <label>Country</label>
              <select
                className="form-input"
                name="country"
                value={filters.country}
                onChange={handleFilterChange}
              >
                <option value="">All Countries</option>
                {availableFilters.countries.map((country) => (
                  <option key={country} value={country}>
                    {country}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label>University</label>
              <select
                className="form-input"
                name="university"
                value={filters.university}
                onChange={handleFilterChange}
                disabled={!filters.country && countryUniversities.length === 0}
              >
                <option value="">All Universities</option>
                {(filters.country
                  ? countryUniversities
                  : availableFilters.universities
                ).map((university) => (
                  <option key={university} value={university}>
                    {university}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label>Department</label>
              <select
                className="form-input"
                name="department"
                value={filters.department}
                onChange={handleFilterChange}
                disabled={
                  !filters.university && universityDepartments.length === 0
                }
              >
                <option value="">All Departments</option>
                {(filters.university
                  ? universityDepartments
                  : availableFilters.departments
                ).map((dept) => (
                  <option key={dept} value={dept}>
                    {dept}
                  </option>
                ))}
              </select>
            </div>

            <div style={{ display: "flex", alignItems: "flex-end" }}>
              <button
                className="btn btn-sm"
                onClick={resetFilters}
                style={{ width: "100%" }}
              >
                Reset Filters
              </button>
            </div>
          </div>
        </div>

        {/* Tabs */}
        <div className="tabs">
          <button
            className={`tab ${activeTab === "most_viewed" ? "active" : ""}`}
            onClick={() => setActiveTab("most_viewed")}
          >
            👁️ Most Viewed Projects
          </button>
          <button
            className={`tab ${activeTab === "most_voted" ? "active" : ""}`}
            onClick={() => setActiveTab("most_voted")}
          >
            👍 Most Voted Projects
          </button>
          <button
            className={`tab ${activeTab === "most_commented" ? "active" : ""}`}
            onClick={() => setActiveTab("most_commented")}
          >
            💬 Most Commented Projects
          </button>
          <button
            className={`tab ${activeTab === "most_active" ? "active" : ""}`}
            onClick={() => setActiveTab("most_active")}
          >
            👥 Most Active Collaborators
          </button>
          <button
            className={`tab ${activeTab === "most_funded" ? "active" : ""}`}
            onClick={() => setActiveTab("most_funded")}
          >
            💰 Most Funded Projects
          </button>
          <button
            className={`tab ${activeTab === "top_funders" ? "active" : ""}`}
            onClick={() => setActiveTab("top_funders")}
          >
            🌟 Top Funders
          </button>
        </div>

        {/* Content */}
        <div className="leaderboard-content">
          {activeTab === "most_viewed" && (
            <div className="leaderboard-list">
              {mostViewedProjects.length === 0 ? (
                <p>No projects found.</p>
              ) : (
                mostViewedProjects.map((project, index) =>
                  renderProjectRow(
                    project,
                    index,
                    project.project_stat?.total_views || 0,
                    "Views"
                  )
                )
              )}
            </div>
          )}

          {activeTab === "most_voted" && (
            <div className="leaderboard-list">
              {mostVotedProjects.length === 0 ? (
                <p>No projects found.</p>
              ) : (
                mostVotedProjects.map((project, index) =>
                  renderProjectRow(
                    project,
                    index,
                    project.project_stat?.total_votes || 0,
                    "Votes"
                  )
                )
              )}
            </div>
          )}

          {activeTab === "most_commented" && (
            <div className="leaderboard-list">
              {mostCommentedProjects.length === 0 ? (
                <p>No projects found.</p>
              ) : (
                mostCommentedProjects.map((project, index) =>
                  renderProjectRow(
                    project,
                    index,
                    project.project_stat?.total_comments || 0,
                    "Comments"
                  )
                )
              )}
            </div>
          )}

          {activeTab === "most_active" && (
            <div className="leaderboard-list">
              {mostActiveCollaborators.length === 0 ? (
                <p>No users found.</p>
              ) : (
                mostActiveCollaborators.map((user, index) =>
                  renderUserRow(user, index)
                )
              )}
            </div>
          )}

          {activeTab === "most_funded" && (
            <div className="leaderboard-list">
              {mostFundedProjects.length === 0 ? (
                <p>No funded projects found.</p>
              ) : (
                mostFundedProjects.map((project, index) => (
                  <div
                    key={project.id}
                    className="leaderboard-row"
                    onClick={() => openProjectDetail(project)}
                    style={{ cursor: "pointer" }}
                  >
                    <div className="rank">#{index + 1}</div>
                    <div className="project-info">
                      <div className="project-title">{project.title}</div>
                      <div className="project-meta">
                        <span>Owner: {project.owner?.full_name}</span>
                        {project.owner?.university && (
                          <span> • {project.owner.university}</span>
                        )}
                        {project.owner?.country && (
                          <span> • {project.owner.country}</span>
                        )}
                      </div>
                      {project.tags && project.tags.length > 0 && (
                        <div className="project-tags">
                          {project.tags.map((tag) => (
                            <span key={tag.id} className="tag-badge">
                              {tag.tag_name}
                            </span>
                          ))}
                        </div>
                      )}
                      <div
                        style={{
                          marginTop: "8px",
                          fontSize: "14px",
                          color: "#6b7280",
                        }}
                      >
                        💸 {project.funders_count || 0} contributors
                      </div>
                    </div>
                    <div className="metric-value">
                      <div
                        className="metric-number"
                        style={{ color: "#16a34a" }}
                      >
                        ${Number(project.total_funding || 0).toFixed(2)}
                      </div>
                      <div className="metric-label">Total Funding</div>
                    </div>
                    <div className="stats-mini">
                      <span title="Views">
                        👁️ {project.project_stat?.total_views || 0}
                      </span>
                      <span title="Votes">
                        👍 {project.project_stat?.total_votes || 0}
                      </span>
                      <span title="Comments">
                        💬 {project.project_stat?.total_comments || 0}
                      </span>
                    </div>
                  </div>
                ))
              )}
            </div>
          )}

          {activeTab === "top_funders" && (
            <div className="leaderboard-list">
              {topFunders.length === 0 ? (
                <p>No funders found.</p>
              ) : (
                topFunders.map((user, index) => (
                  <div
                    key={user.id}
                    className="leaderboard-row"
                    onClick={() => openUserDetail(user)}
                    style={{ cursor: "pointer" }}
                  >
                    <div className="rank">#{index + 1}</div>
                    <div className="project-info">
                      <div className="project-title">{user.full_name}</div>
                      <div className="project-meta">
                        <span>{user.email}</span>
                        {user.university && <span> • {user.university}</span>}
                        {user.department && <span> • {user.department}</span>}
                        {user.country && <span> • {user.country}</span>}
                      </div>
                      <div
                        style={{
                          marginTop: "8px",
                          fontSize: "14px",
                          color: "#6b7280",
                        }}
                      >
                        🎯 Funded {user.projects_funded_count || 0} projects
                      </div>
                    </div>
                    <div className="metric-value">
                      <div
                        className="metric-number"
                        style={{ color: "#16a34a" }}
                      >
                        ${Number(user.total_funded || 0).toFixed(2)}
                      </div>
                      <div className="metric-label">Total Contributed</div>
                    </div>
                  </div>
                ))
              )}
            </div>
          )}
        </div>
      </div>

      {/* Project Detail Modal */}
      {projectDetailModal.show && projectDetailModal.project && (
        <div
          style={{
            position: "fixed",
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            background: "rgba(0,0,0,0.5)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            zIndex: 1000,
          }}
          onClick={() => setProjectDetailModal({ show: false, project: null })}
        >
          <div
            className="card"
            style={{
              maxWidth: "900px",
              width: "90%",
              maxHeight: "85vh",
              overflow: "auto",
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div
              style={{
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
                marginBottom: "20px",
              }}
            >
              <h2>Project Details</h2>
              <button
                onClick={() =>
                  setProjectDetailModal({ show: false, project: null })
                }
                style={{
                  background: "none",
                  border: "none",
                  fontSize: "24px",
                  cursor: "pointer",
                }}
              >
                ×
              </button>
            </div>
            <div style={{ display: "grid", gap: "16px" }}>
              <div
                style={{
                  borderBottom: "2px solid #e5e7eb",
                  paddingBottom: "12px",
                }}
              >
                <h3 style={{ marginBottom: "12px", color: "#1f2937" }}>
                  Basic Information
                </h3>
                <div>
                  <strong>Title:</strong> {projectDetailModal.project.title}
                </div>
                <div style={{ marginTop: "8px" }}>
                  <strong>Description:</strong>{" "}
                  {projectDetailModal.project.description || "No description"}
                </div>
                <div
                  style={{
                    display: "grid",
                    gridTemplateColumns: "1fr 1fr",
                    gap: "8px",
                    marginTop: "12px",
                  }}
                >
                  <div>
                    <strong>Status:</strong>{" "}
                    <span
                      style={{
                        background: "#3b82f6",
                        color: "white",
                        padding: "2px 8px",
                        borderRadius: "4px",
                        fontSize: "12px",
                      }}
                    >
                      {projectDetailModal.project.status}
                    </span>
                  </div>
                  <div>
                    <strong>Visibility:</strong>{" "}
                    <span
                      style={{
                        background: "#10b981",
                        color: "white",
                        padding: "2px 8px",
                        borderRadius: "4px",
                        fontSize: "12px",
                      }}
                    >
                      {projectDetailModal.project.visibility}
                    </span>
                  </div>
                  <div>
                    <strong>Created:</strong>{" "}
                    {new Date(
                      projectDetailModal.project.created_at
                    ).toLocaleDateString()}
                  </div>
                  <div>
                    <strong>Reports:</strong>{" "}
                    <span style={{ color: "#dc2626", fontWeight: "bold" }}>
                      {projectDetailModal.project.reports_count || 0}
                    </span>
                  </div>
                </div>
              </div>
              {projectDetailModal.project.owner && (
                <div
                  style={{
                    borderBottom: "2px solid #e5e7eb",
                    paddingBottom: "12px",
                  }}
                >
                  <h3 style={{ marginBottom: "12px", color: "#1f2937" }}>
                    Owner Information
                  </h3>
                  <div
                    style={{
                      display: "grid",
                      gridTemplateColumns: "1fr 1fr",
                      gap: "8px",
                    }}
                  >
                    <div>
                      <strong>Name:</strong>{" "}
                      {projectDetailModal.project.owner.full_name}
                    </div>
                    <div>
                      <strong>Email:</strong>{" "}
                      {projectDetailModal.project.owner.email}
                    </div>
                    <div>
                      <strong>Country:</strong>{" "}
                      {projectDetailModal.project.owner.country || "Not set"}
                    </div>
                    <div>
                      <strong>University:</strong>{" "}
                      {projectDetailModal.project.owner.university || "Not set"}
                    </div>
                    <div>
                      <strong>Department:</strong>{" "}
                      {projectDetailModal.project.owner.department || "Not set"}
                    </div>
                  </div>
                </div>
              )}
              {projectDetailModal.project.project_stat && (
                <div
                  style={{
                    borderBottom: "2px solid #e5e7eb",
                    paddingBottom: "12px",
                  }}
                >
                  <h3 style={{ marginBottom: "12px", color: "#1f2937" }}>
                    Project Statistics
                  </h3>
                  <div
                    style={{
                      display: "grid",
                      gridTemplateColumns: "repeat(3, 1fr)",
                      gap: "12px",
                    }}
                  >
                    <div
                      style={{
                        textAlign: "center",
                        background: "#f3f4f6",
                        padding: "12px",
                        borderRadius: "8px",
                      }}
                    >
                      <div
                        style={{
                          fontSize: "32px",
                          fontWeight: "bold",
                          color: "#3b82f6",
                        }}
                      >
                        👁️{" "}
                        {projectDetailModal.project.project_stat.total_views ||
                          0}
                      </div>
                      <div
                        style={{
                          fontSize: "14px",
                          color: "#6b7280",
                          marginTop: "4px",
                        }}
                      >
                        Total Views
                      </div>
                    </div>
                    <div
                      style={{
                        textAlign: "center",
                        background: "#f3f4f6",
                        padding: "12px",
                        borderRadius: "8px",
                      }}
                    >
                      <div
                        style={{
                          fontSize: "32px",
                          fontWeight: "bold",
                          color: "#10b981",
                        }}
                      >
                        👍{" "}
                        {projectDetailModal.project.project_stat.total_votes ||
                          0}
                      </div>
                      <div
                        style={{
                          fontSize: "14px",
                          color: "#6b7280",
                          marginTop: "4px",
                        }}
                      >
                        Total Votes
                      </div>
                    </div>
                    <div
                      style={{
                        textAlign: "center",
                        background: "#f3f4f6",
                        padding: "12px",
                        borderRadius: "8px",
                      }}
                    >
                      <div
                        style={{
                          fontSize: "32px",
                          fontWeight: "bold",
                          color: "#f59e0b",
                        }}
                      >
                        💬{" "}
                        {projectDetailModal.project.project_stat
                          .total_comments || 0}
                      </div>
                      <div
                        style={{
                          fontSize: "14px",
                          color: "#6b7280",
                          marginTop: "4px",
                        }}
                      >
                        Total Comments
                      </div>
                    </div>
                  </div>
                </div>
              )}
              {projectDetailModal.project.tags &&
                projectDetailModal.project.tags.length > 0 && (
                  <div
                    style={{
                      borderBottom: "2px solid #e5e7eb",
                      paddingBottom: "12px",
                    }}
                  >
                    <h3 style={{ marginBottom: "12px", color: "#1f2937" }}>
                      Tags
                    </h3>
                    <div
                      style={{ display: "flex", flexWrap: "wrap", gap: "6px" }}
                    >
                      {projectDetailModal.project.tags.map((tag) => (
                        <span
                          key={tag.id}
                          style={{
                            background: "#3b82f6",
                            color: "white",
                            padding: "4px 12px",
                            borderRadius: "12px",
                            fontSize: "13px",
                          }}
                        >
                          {tag.tag_name}
                        </span>
                      ))}
                    </div>
                  </div>
                )}
              {projectDetailModal.project.collaborations &&
                projectDetailModal.project.collaborations.length > 0 && (
                  <div
                    style={{
                      borderBottom: "2px solid #e5e7eb",
                      paddingBottom: "12px",
                    }}
                  >
                    <h3 style={{ marginBottom: "12px", color: "#1f2937" }}>
                      Collaborators (
                      {projectDetailModal.project.collaborations.length})
                    </h3>
                    <div
                      style={{
                        display: "grid",
                        gridTemplateColumns: "repeat(2, 1fr)",
                        gap: "8px",
                      }}
                    >
                      {projectDetailModal.project.collaborations.map(
                        (collab) => (
                          <div
                            key={collab.id}
                            style={{
                              padding: "8px",
                              background: "#f9fafb",
                              borderRadius: "6px",
                              display: "flex",
                              justifyContent: "space-between",
                              alignItems: "center",
                            }}
                          >
                            <div>
                              <strong>
                                {collab.user?.full_name || "User"}
                              </strong>
                              <div
                                style={{ fontSize: "11px", color: "#6b7280" }}
                              >
                                {collab.user?.email}
                              </div>
                            </div>
                            <span
                              style={{
                                fontSize: "11px",
                                background: "#e5e7eb",
                                padding: "2px 6px",
                                borderRadius: "4px",
                              }}
                            >
                              {collab.project_role || "member"}
                            </span>
                          </div>
                        )
                      )}
                    </div>
                  </div>
                )}
            </div>
          </div>
        </div>
      )}

      {/* User Detail Modal */}
      {userDetailModal.show && userDetailModal.user && (
        <div
          style={{
            position: "fixed",
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            background: "rgba(0,0,0,0.5)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            zIndex: 1000,
          }}
          onClick={() => setUserDetailModal({ show: false, user: null })}
        >
          <div
            className="card"
            style={{
              maxWidth: "800px",
              width: "90%",
              maxHeight: "80vh",
              overflow: "auto",
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div
              style={{
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
                marginBottom: "20px",
              }}
            >
              <h2>User Details</h2>
              <button
                onClick={() => setUserDetailModal({ show: false, user: null })}
                style={{
                  background: "none",
                  border: "none",
                  fontSize: "24px",
                  cursor: "pointer",
                }}
              >
                ×
              </button>
            </div>
            <div style={{ display: "grid", gap: "16px" }}>
              <div
                style={{
                  borderBottom: "2px solid #e5e7eb",
                  paddingBottom: "12px",
                }}
              >
                <h3 style={{ marginBottom: "12px", color: "#1f2937" }}>
                  Basic Information
                </h3>
                <div
                  style={{
                    display: "grid",
                    gridTemplateColumns: "1fr 1fr",
                    gap: "8px",
                  }}
                >
                  <div>
                    <strong>Name:</strong> {userDetailModal.user.full_name}
                  </div>
                  <div>
                    <strong>Email:</strong> {userDetailModal.user.email}
                  </div>
                  <div>
                    <strong>Role:</strong>{" "}
                    <span
                      style={{
                        background:
                          userDetailModal.user.system_role === "admin"
                            ? "#fbbf24"
                            : "#3b82f6",
                        color: "white",
                        padding: "2px 8px",
                        borderRadius: "4px",
                        fontSize: "12px",
                      }}
                    >
                      {userDetailModal.user.system_role || "user"}
                    </span>
                  </div>
                  <div>
                    <strong>Status:</strong>{" "}
                    <span
                      style={{
                        color: userDetailModal.user.banned
                          ? "#dc2626"
                          : "#10b981",
                        fontWeight: "bold",
                      }}
                    >
                      {userDetailModal.user.banned ? "BANNED" : "Active"}
                    </span>
                  </div>
                  <div>
                    <strong>Country:</strong>{" "}
                    {userDetailModal.user.country || "Not set"}
                  </div>
                  <div>
                    <strong>University:</strong>{" "}
                    {userDetailModal.user.university || "Not set"}
                  </div>
                  <div>
                    <strong>Department:</strong>{" "}
                    {userDetailModal.user.department || "Not set"}
                  </div>
                  <div>
                    <strong>Joined:</strong>{" "}
                    {new Date(
                      userDetailModal.user.created_at
                    ).toLocaleDateString()}
                  </div>
                </div>
              </div>
              <div
                style={{
                  borderBottom: "2px solid #e5e7eb",
                  paddingBottom: "12px",
                }}
              >
                <h3 style={{ marginBottom: "12px", color: "#1f2937" }}>
                  Activity Statistics
                </h3>
                <div
                  style={{
                    display: "grid",
                    gridTemplateColumns: "repeat(4, 1fr)",
                    gap: "8px",
                  }}
                >
                  <div
                    style={{
                      textAlign: "center",
                      background: "#f3f4f6",
                      padding: "8px",
                      borderRadius: "6px",
                    }}
                  >
                    <div
                      style={{
                        fontSize: "24px",
                        fontWeight: "bold",
                        color: "#3b82f6",
                      }}
                    >
                      {userDetailModal.user.owned_projects?.length || 0}
                    </div>
                    <div style={{ fontSize: "12px", color: "#6b7280" }}>
                      Projects Owned
                    </div>
                  </div>
                  <div
                    style={{
                      textAlign: "center",
                      background: "#f3f4f6",
                      padding: "8px",
                      borderRadius: "6px",
                    }}
                  >
                    <div
                      style={{
                        fontSize: "24px",
                        fontWeight: "bold",
                        color: "#10b981",
                      }}
                    >
                      {userDetailModal.user.collaborations?.length || 0}
                    </div>
                    <div style={{ fontSize: "12px", color: "#6b7280" }}>
                      Collaborations
                    </div>
                  </div>
                  <div
                    style={{
                      textAlign: "center",
                      background: "#f3f4f6",
                      padding: "8px",
                      borderRadius: "6px",
                    }}
                  >
                    <div
                      style={{
                        fontSize: "24px",
                        fontWeight: "bold",
                        color: "#f59e0b",
                      }}
                    >
                      {userDetailModal.user.comments?.length || 0}
                    </div>
                    <div style={{ fontSize: "12px", color: "#6b7280" }}>
                      Comments
                    </div>
                  </div>
                  <div
                    style={{
                      textAlign: "center",
                      background: "#f3f4f6",
                      padding: "8px",
                      borderRadius: "6px",
                    }}
                  >
                    <div
                      style={{
                        fontSize: "24px",
                        fontWeight: "bold",
                        color: "#dc2626",
                      }}
                    >
                      {userDetailModal.user.reports_count || 0}
                    </div>
                    <div style={{ fontSize: "12px", color: "#6b7280" }}>
                      Reports
                    </div>
                  </div>
                </div>
              </div>
              {userDetailModal.user.owned_projects &&
                userDetailModal.user.owned_projects.length > 0 && (
                  <div
                    style={{
                      borderBottom: "2px solid #e5e7eb",
                      paddingBottom: "12px",
                    }}
                  >
                    <h3 style={{ marginBottom: "12px", color: "#1f2937" }}>
                      Owned Projects (
                      {userDetailModal.user.owned_projects.length})
                    </h3>
                    <div style={{ display: "grid", gap: "8px" }}>
                      {userDetailModal.user.owned_projects.map((project) => (
                        <div
                          key={project.id}
                          style={{
                            padding: "8px",
                            background: "#f9fafb",
                            borderRadius: "6px",
                            display: "flex",
                            justifyContent: "space-between",
                          }}
                        >
                          <div>
                            <strong>{project.title}</strong>
                            <div style={{ fontSize: "12px", color: "#6b7280" }}>
                              {project.status} • {project.visibility}
                            </div>
                          </div>
                          {project.project_stat && (
                            <div style={{ fontSize: "12px", color: "#6b7280" }}>
                              👁️ {project.project_stat.total_views} • 👍{" "}
                              {project.project_stat.total_votes} • 💬{" "}
                              {project.project_stat.total_comments}
                            </div>
                          )}
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              {userDetailModal.user.collaborations &&
                userDetailModal.user.collaborations.length > 0 && (
                  <div>
                    <h3 style={{ marginBottom: "12px", color: "#1f2937" }}>
                      Collaborating On (
                      {userDetailModal.user.collaborations.length})
                    </h3>
                    <div style={{ display: "grid", gap: "8px" }}>
                      {userDetailModal.user.collaborations.map((collab) => (
                        <div
                          key={collab.id}
                          style={{
                            padding: "8px",
                            background: "#f9fafb",
                            borderRadius: "6px",
                          }}
                        >
                          <strong>
                            {collab.project?.title ||
                              `Project #${collab.project_id}`}
                          </strong>
                          <div style={{ fontSize: "12px", color: "#6b7280" }}>
                            Role: {collab.project_role || "member"}
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Leaderboard;
