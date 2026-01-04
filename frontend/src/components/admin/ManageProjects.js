import React, { useEffect, useState } from "react";
import { adminService } from "../../apiService";

const ManageProjects = () => {
  const [projects, setProjects] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalCount, setTotalCount] = useState(0);
  const itemsPerPage = 25;
  const [filters, setFilters] = useState({
    status: "",
    visibility: "",
    owner_country: "",
    owner_university: "",
    owner_department: "",
    reported: "",
    q: "",
    sort: "",
  });

  // Detail modal state
  const [detailModal, setDetailModal] = useState({
    show: false,
    project: null,
  });

  // Edit modal state
  const [editModal, setEditModal] = useState({
    show: false,
    project: null,
    formData: {},
  });

  // Cascading filter states
  const [availableFilters, setAvailableFilters] = useState({
    countries: [],
    universities: [],
    departments: [],
  });
  const [countryUniversities, setCountryUniversities] = useState([]);
  const [universityDepartments, setUniversityDepartments] = useState([]);

  useEffect(() => {
    loadProjects();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filters, currentPage]);

  useEffect(() => {
    loadFilterOptions();
  }, []);

  const loadProjects = async () => {
    try {
      setLoading(true);
      const response = await adminService.getProjects({
        ...filters,
        page: currentPage,
        per_page: itemsPerPage,
      });

      // Handle response: {data: [...], meta: {...}}
      const projectsData = response.data || response.projects || response;
      const metadata = response.meta || {};

      setProjects(projectsData);
      setTotalCount(metadata.total_count || projectsData.length);
      setTotalPages(
        metadata.total_pages ||
          Math.ceil(
            (metadata.total_count || projectsData.length) / itemsPerPage
          )
      );
    } catch (e) {
      console.error(e);
      setError("Failed to load projects");
    } finally {
      setLoading(false);
    }
  };
  const loadFilterOptions = async () => {
    try {
      const data = await adminService.getProjectFilterOptions();
      setAvailableFilters(data);
    } catch (e) {
      console.error("Failed to load filter options:", e);
    }
  };

  const loadUniversitiesByCountry = async (country) => {
    if (!country) {
      setCountryUniversities([]);
      return;
    }
    try {
      const data = await adminService.getProjectUniversitiesByCountry(country);
      setCountryUniversities(data.universities || []);
    } catch (e) {
      console.error("Failed to load universities:", e);
      setCountryUniversities([]);
    }
  };

  const loadDepartmentsByUniversity = async (university) => {
    if (!university) {
      setUniversityDepartments([]);
      return;
    }
    try {
      const data = await adminService.getProjectDepartmentsByUniversity(
        university
      );
      setUniversityDepartments(data.departments || []);
    } catch (e) {
      console.error("Failed to load departments:", e);
      setUniversityDepartments([]);
    }
  };

  const handleFilterChange = (e) => {
    const { name, value } = e.target;
    setCurrentPage(1); // Reset to first page when filter changes

    // Reset dependent filters when parent filter changes
    if (name === "owner_country") {
      setFilters((prev) => ({
        ...prev,
        [name]: value,
        owner_university: "",
        owner_department: "",
      }));
      setUniversityDepartments([]);
      if (value) {
        loadUniversitiesByCountry(value);
      } else {
        setCountryUniversities([]);
      }
    } else if (name === "owner_university") {
      setFilters((prev) => ({ ...prev, [name]: value, owner_department: "" }));
      if (value) {
        loadDepartmentsByUniversity(value);
      } else {
        setUniversityDepartments([]);
      }
    } else {
      setFilters((prev) => ({ ...prev, [name]: value }));
    }
  };

  const handleDelete = async (projectId) => {
    if (!window.confirm("Delete this project? This action cannot be undone."))
      return;
    try {
      await adminService.deleteProject(projectId);
      loadProjects();
    } catch (e) {
      alert("Failed to delete project");
    }
  };

  const handleStatusChange = async (project, newStatus) => {
    try {
      await adminService.updateProject(project.id, { status: newStatus });
      loadProjects();
    } catch (e) {
      alert("Failed to update project status");
    }
  };

  const openDetailModal = (project) => {
    setDetailModal({ show: true, project });
    // Fetch full project details
    fetchProjectDetails(project.id);
  };

  const fetchProjectDetails = async (projectId) => {
    try {
      const fullProjectData = await adminService.getProject(projectId);
      setDetailModal((prev) => ({ ...prev, project: fullProjectData }));
    } catch (e) {
      console.error("Failed to fetch project details:", e);
    }
  };

  const handleEditProject = (project) => {
    setEditModal({
      show: true,
      project,
      formData: {
        title: project.title,
        description: project.description,
        status: project.status,
        visibility: project.visibility,
      },
    });
  };

  const handleSaveEdit = async () => {
    try {
      await adminService.updateProject(
        editModal.project.id,
        editModal.formData
      );
      setEditModal({ show: false, project: null, formData: {} });
      loadProjects();
    } catch (e) {
      alert("Failed to update project");
    }
  };

  if (loading)
    return (
      <div className="container" style={{ paddingTop: "20px" }}>
        <div className="loading">
          <div className="spinner"></div>
        </div>
      </div>
    );

  return (
    <div className="container" style={{ paddingTop: "20px" }}>
      <div className="card">
        <h1>Manage Projects</h1>
        {error && <div className="alert alert-error">{error}</div>}

        {/* Filters */}
        <div
          style={{
            marginTop: "12px",
            marginBottom: "20px",
            padding: "15px",
            background: "#f9fafb",
            borderRadius: "8px",
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(150px, 1fr))",
            gap: "10px",
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
              Search:
            </label>
            <input
              className="form-input"
              name="q"
              placeholder="Title or description"
              value={filters.q}
              onChange={handleFilterChange}
            />
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
              Status:
            </label>
            <select
              className="form-input"
              name="status"
              value={filters.status}
              onChange={handleFilterChange}
            >
              <option value="">All Statuses</option>
              <option value="Ideation">Ideation</option>
              <option value="Ongoing">Ongoing</option>
              <option value="Completed">Completed</option>
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
              Visibility:
            </label>
            <select
              className="form-input"
              name="visibility"
              value={filters.visibility}
              onChange={handleFilterChange}
            >
              <option value="">All</option>
              <option value="public">Public</option>
              <option value="private">Private</option>
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
              Owner Country:
            </label>
            <select
              className="form-input"
              name="owner_country"
              value={filters.owner_country}
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
            <label
              style={{
                fontSize: "12px",
                fontWeight: "500",
                display: "block",
                marginBottom: "4px",
              }}
            >
              Owner University:
            </label>
            <select
              className="form-input"
              name="owner_university"
              value={filters.owner_university}
              onChange={handleFilterChange}
              disabled={
                !filters.owner_country && countryUniversities.length === 0
              }
            >
              <option value="">All Universities</option>
              {(filters.owner_country
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
            <label
              style={{
                fontSize: "12px",
                fontWeight: "500",
                display: "block",
                marginBottom: "4px",
              }}
            >
              Owner Department:
            </label>
            <select
              className="form-input"
              name="owner_department"
              value={filters.owner_department}
              onChange={handleFilterChange}
              disabled={
                !filters.owner_university && universityDepartments.length === 0
              }
            >
              <option value="">All Departments</option>
              {(filters.owner_university
                ? universityDepartments
                : availableFilters.departments
              ).map((dept) => (
                <option key={dept} value={dept}>
                  {dept}
                </option>
              ))}
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
              Reported:
            </label>
            <select
              className="form-input"
              name="reported"
              value={filters.reported}
              onChange={handleFilterChange}
            >
              <option value="">All</option>
              <option value="true">Reported Only</option>
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
              Sort By:
            </label>
            <select
              className="form-input"
              name="sort"
              value={filters.sort}
              onChange={handleFilterChange}
            >
              <option value="">Recent</option>
              <option value="reports">Most Reported</option>
              <option value="views">Most Views</option>
              <option value="likes">Most Liked</option>
              <option value="funded">Most Funded</option>
            </select>
          </div>
          <div style={{ display: "flex", alignItems: "flex-end" }}>
            <button
              className="btn btn-sm"
              onClick={() => {
                setFilters({
                  status: "",
                  visibility: "",
                  owner_country: "",
                  owner_university: "",
                  owner_department: "",
                  reported: "",
                  q: "",
                  sort: "",
                });
                setCountryUniversities([]);
                setUniversityDepartments([]);
              }}
              style={{ width: "100%" }}
            >
              Reset
            </button>
          </div>
        </div>

        <div style={{ marginTop: "12px" }}>
          {projects.length === 0 ? (
            <p>No projects found.</p>
          ) : (
            <div style={{ display: "grid", gap: "8px" }}>
              {projects.map((project) => (
                <div
                  key={project.id}
                  style={{
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                    padding: "12px",
                    border: "1px solid #e5e7eb",
                    borderRadius: "6px",
                  }}
                >
                  <div>
                    <button
                      onClick={() => openDetailModal(project)}
                      style={{
                        background: "none",
                        border: "none",
                        padding: 0,
                        color: "#3b82f6",
                        textDecoration: "underline",
                        cursor: "pointer",
                        fontSize: "16px",
                        fontWeight: "bold",
                      }}
                    >
                      {project.title}
                    </button>
                    <div style={{ color: "#6b7280", fontSize: "13px" }}>
                      {project.owner?.full_name}
                    </div>
                    <div style={{ color: "#6b7280", fontSize: "12px" }}>
                      {project.visibility} • {project.status}
                      {project.reports_count > 0 && (
                        <span style={{ color: "#dc2626", marginLeft: "8px" }}>
                          {project.reports_count} report
                          {project.reports_count > 1 ? "s" : ""}
                        </span>
                      )}
                    </div>
                  </div>

                  <div
                    style={{
                      display: "flex",
                      gap: "8px",
                      alignItems: "center",
                    }}
                  >
                    <button
                      className="btn btn-sm"
                      onClick={() => handleEditProject(project)}
                    >
                      Edit
                    </button>
                    <select
                      value={project.status || "Ideation"}
                      onChange={(e) =>
                        handleStatusChange(project, e.target.value)
                      }
                    >
                      <option value="Ideation">Ideation</option>
                      <option value="Ongoing">Ongoing</option>
                      <option value="Completed">Completed</option>
                    </select>
                    <button
                      className="btn btn-sm btn-danger"
                      onClick={() => handleDelete(project.id)}
                    >
                      Delete
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* Pagination Controls */}
          {!loading && projects.length > 0 && (
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
                {Math.min(currentPage * itemsPerPage, totalCount)} of{" "}
                {totalCount} projects
              </div>
              <div
                style={{ display: "flex", gap: "8px", alignItems: "center" }}
              >
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
      </div>

      {/* Detail Modal */}
      {detailModal.show && (
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
        >
          <div
            className="card"
            style={{
              maxWidth: "900px",
              width: "90%",
              maxHeight: "85vh",
              overflow: "auto",
            }}
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
                onClick={() => setDetailModal({ show: false, project: null })}
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
              {/* Basic Info */}
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
                  <strong>Title:</strong> {detailModal.project.title}
                </div>
                <div style={{ marginTop: "8px" }}>
                  <strong>Description:</strong>{" "}
                  {detailModal.project.description || "No description"}
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
                      {detailModal.project.status}
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
                      {detailModal.project.visibility}
                    </span>
                  </div>
                  <div>
                    <strong>Created:</strong>{" "}
                    {new Date(
                      detailModal.project.created_at
                    ).toLocaleDateString()}
                  </div>
                  <div>
                    <strong>Reports:</strong>{" "}
                    <span style={{ color: "#dc2626", fontWeight: "bold" }}>
                      {detailModal.project.reports_count || 0}
                    </span>
                  </div>
                </div>
              </div>

              {/* Owner Info */}
              {detailModal.project.owner && (
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
                      {detailModal.project.owner.full_name}
                    </div>
                    <div>
                      <strong>Email:</strong> {detailModal.project.owner.email}
                    </div>
                    <div>
                      <strong>Country:</strong>{" "}
                      {detailModal.project.owner.country || "Not set"}
                    </div>
                    <div>
                      <strong>University:</strong>{" "}
                      {detailModal.project.owner.university || "Not set"}
                    </div>
                    <div>
                      <strong>Department:</strong>{" "}
                      {detailModal.project.owner.department || "Not set"}
                    </div>
                  </div>
                </div>
              )}

              {/* Statistics */}
              {detailModal.project.project_stat && (
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
                        👁️ {detailModal.project.project_stat.total_views || 0}
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
                        👍 {detailModal.project.project_stat.total_votes || 0}
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
                        {detailModal.project.project_stat.total_comments || 0}
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

              {/* Tags */}
              {detailModal.project.tags &&
                detailModal.project.tags.length > 0 && (
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
                      {detailModal.project.tags.map((tag) => (
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

              {/* Collaborators */}
              {detailModal.project.collaborations &&
                detailModal.project.collaborations.length > 0 && (
                  <div
                    style={{
                      borderBottom: "2px solid #e5e7eb",
                      paddingBottom: "12px",
                    }}
                  >
                    <h3 style={{ marginBottom: "12px", color: "#1f2937" }}>
                      Collaborators ({detailModal.project.collaborations.length}
                      )
                    </h3>
                    <div
                      style={{
                        display: "grid",
                        gridTemplateColumns: "repeat(2, 1fr)",
                        gap: "8px",
                      }}
                    >
                      {detailModal.project.collaborations.map((collab) => (
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
                            <strong>{collab.user?.full_name || "User"}</strong>
                            <div style={{ fontSize: "11px", color: "#6b7280" }}>
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
                      ))}
                    </div>
                  </div>
                )}

              {/* Funding */}
              {detailModal.project.funds &&
                detailModal.project.funds.length > 0 && (
                  <div
                    style={{
                      borderBottom: "2px solid #e5e7eb",
                      paddingBottom: "12px",
                    }}
                  >
                    <h3 style={{ marginBottom: "12px", color: "#1f2937" }}>
                      Funding ({detailModal.project.funds.length} contributions)
                    </h3>
                    <div style={{ display: "grid", gap: "8px" }}>
                      {detailModal.project.funds.map((fund) => (
                        <div
                          key={fund.id}
                          style={{
                            padding: "8px",
                            background: "#f9fafb",
                            borderRadius: "6px",
                            display: "flex",
                            justifyContent: "space-between",
                          }}
                        >
                          <div>
                            <strong>
                              {fund.funder?.full_name || "Anonymous"}
                            </strong>
                            <div style={{ fontSize: "11px", color: "#9ca3af" }}>
                              {fund.funded_at
                                ? new Date(fund.funded_at).toLocaleDateString()
                                : new Date(
                                    fund.created_at
                                  ).toLocaleDateString()}
                            </div>
                          </div>
                          <div
                            style={{
                              fontWeight: "bold",
                              fontSize: "18px",
                              color: "#10b981",
                            }}
                          >
                            ${Number(fund.amount).toFixed(2)}
                          </div>
                        </div>
                      ))}
                    </div>
                    <div
                      style={{
                        marginTop: "12px",
                        padding: "12px",
                        background: "#d1fae5",
                        borderRadius: "8px",
                        textAlign: "center",
                      }}
                    >
                      <div
                        style={{
                          fontSize: "24px",
                          fontWeight: "bold",
                          color: "#10b981",
                        }}
                      >
                        Total Funding: $
                        {detailModal.project.funds
                          .reduce((sum, f) => sum + Number(f.amount || 0), 0)
                          .toFixed(2)}
                      </div>
                    </div>
                  </div>
                )}

              {/* Votes Breakdown */}
              {detailModal.project.votes &&
                detailModal.project.votes.length > 0 && (
                  <div
                    style={{
                      borderBottom: "2px solid #e5e7eb",
                      paddingBottom: "12px",
                    }}
                  >
                    <h3 style={{ marginBottom: "12px", color: "#1f2937" }}>
                      Votes Breakdown
                    </h3>
                    <div
                      style={{
                        display: "grid",
                        gridTemplateColumns: "1fr 1fr",
                        gap: "12px",
                      }}
                    >
                      <div
                        style={{
                          padding: "12px",
                          background: "#d1fae5",
                          borderRadius: "8px",
                          textAlign: "center",
                        }}
                      >
                        <div
                          style={{
                            fontSize: "28px",
                            fontWeight: "bold",
                            color: "#10b981",
                          }}
                        >
                          👍{" "}
                          {
                            detailModal.project.votes.filter(
                              (v) => v.vote_type === "up"
                            ).length
                          }
                        </div>
                        <div style={{ fontSize: "14px", color: "#065f46" }}>
                          Upvotes
                        </div>
                      </div>
                      <div
                        style={{
                          padding: "12px",
                          background: "#fee2e2",
                          borderRadius: "8px",
                          textAlign: "center",
                        }}
                      >
                        <div
                          style={{
                            fontSize: "28px",
                            fontWeight: "bold",
                            color: "#dc2626",
                          }}
                        >
                          👎{" "}
                          {
                            detailModal.project.votes.filter(
                              (v) => v.vote_type === "down"
                            ).length
                          }
                        </div>
                        <div style={{ fontSize: "14px", color: "#991b1b" }}>
                          Downvotes
                        </div>
                      </div>
                    </div>
                  </div>
                )}

              {/* Comments */}
              {detailModal.project.comments &&
                detailModal.project.comments.length > 0 && (
                  <div>
                    <h3 style={{ marginBottom: "12px", color: "#1f2937" }}>
                      Comments ({detailModal.project.comments.length})
                    </h3>
                    <div
                      style={{
                        display: "grid",
                        gap: "8px",
                        maxHeight: "250px",
                        overflow: "auto",
                      }}
                    >
                      {detailModal.project.comments.map((comment) => (
                        <div
                          key={comment.id}
                          style={{
                            padding: "10px",
                            background: "#f9fafb",
                            borderRadius: "6px",
                            fontSize: "13px",
                            borderLeft: "3px solid #3b82f6",
                          }}
                        >
                          <div
                            style={{
                              display: "flex",
                              justifyContent: "space-between",
                              marginBottom: "6px",
                            }}
                          >
                            <strong style={{ color: "#1f2937" }}>
                              {comment.user?.full_name || "User"}
                            </strong>
                            <span
                              style={{ fontSize: "11px", color: "#9ca3af" }}
                            >
                              {new Date(
                                comment.created_at
                              ).toLocaleDateString()}
                            </span>
                          </div>
                          <div style={{ color: "#4b5563" }}>
                            {comment.content}
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

      {/* Edit Modal */}
      {editModal.show && (
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
        >
          <div
            className="card"
            style={{
              maxWidth: "600px",
              width: "90%",
              maxHeight: "80vh",
              overflow: "auto",
            }}
          >
            <div
              style={{
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
                marginBottom: "20px",
              }}
            >
              <h2>Edit Project</h2>
              <button
                onClick={() =>
                  setEditModal({ show: false, project: null, formData: {} })
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
            <div style={{ display: "grid", gap: "12px" }}>
              <div>
                <label
                  style={{
                    fontWeight: "500",
                    display: "block",
                    marginBottom: "4px",
                  }}
                >
                  Title
                </label>
                <input
                  className="form-input"
                  value={editModal.formData.title}
                  onChange={(e) =>
                    setEditModal({
                      ...editModal,
                      formData: {
                        ...editModal.formData,
                        title: e.target.value,
                      },
                    })
                  }
                />
              </div>
              <div>
                <label
                  style={{
                    fontWeight: "500",
                    display: "block",
                    marginBottom: "4px",
                  }}
                >
                  Description
                </label>
                <textarea
                  className="form-input"
                  rows="4"
                  value={editModal.formData.description}
                  onChange={(e) =>
                    setEditModal({
                      ...editModal,
                      formData: {
                        ...editModal.formData,
                        description: e.target.value,
                      },
                    })
                  }
                />
              </div>
              <div>
                <label
                  style={{
                    fontWeight: "500",
                    display: "block",
                    marginBottom: "4px",
                  }}
                >
                  Status
                </label>
                <select
                  className="form-input"
                  value={editModal.formData.status}
                  onChange={(e) =>
                    setEditModal({
                      ...editModal,
                      formData: {
                        ...editModal.formData,
                        status: e.target.value,
                      },
                    })
                  }
                >
                  <option value="Ideation">Ideation</option>
                  <option value="Ongoing">Ongoing</option>
                  <option value="Completed">Completed</option>
                </select>
              </div>
              <div>
                <label
                  style={{
                    fontWeight: "500",
                    display: "block",
                    marginBottom: "4px",
                  }}
                >
                  Visibility
                </label>
                <select
                  className="form-input"
                  value={editModal.formData.visibility}
                  onChange={(e) =>
                    setEditModal({
                      ...editModal,
                      formData: {
                        ...editModal.formData,
                        visibility: e.target.value,
                      },
                    })
                  }
                >
                  <option value="public">Public</option>
                  <option value="private">Private</option>
                </select>
              </div>
              <div style={{ display: "flex", gap: "8px", marginTop: "8px" }}>
                <button className="btn btn-primary" onClick={handleSaveEdit}>
                  Save Changes
                </button>
                <button
                  className="btn"
                  onClick={() =>
                    setEditModal({ show: false, project: null, formData: {} })
                  }
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ManageProjects;
