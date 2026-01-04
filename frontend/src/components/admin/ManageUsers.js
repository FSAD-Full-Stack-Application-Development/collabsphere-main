import React, { useEffect, useState } from "react";
import { adminService } from "../../apiService";

const ManageUsers = () => {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalCount, setTotalCount] = useState(0);
  const itemsPerPage = 25;
  const [filters, setFilters] = useState({
    role: "",
    country: "",
    university: "",
    department: "",
    banned: "",
    reported: "",
    q: "",
  });

  // Detail modal state
  const [detailModal, setDetailModal] = useState({ show: false, user: null });

  // Edit modal state
  const [editModal, setEditModal] = useState({
    show: false,
    user: null,
    formData: {},
  });

  // Available filter options
  const [availableFilters, setAvailableFilters] = useState({
    countries: [],
    universities: [],
    departments: [],
  });
  const [countryUniversities, setCountryUniversities] = useState([]);
  const [universityDepartments, setUniversityDepartments] = useState([]);

  useEffect(() => {
    loadUsers();
    loadFilterOptions();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filters, currentPage]);

  useEffect(() => {
    if (filters.country) {
      loadUniversitiesByCountry(filters.country);
    } else {
      setCountryUniversities([]);
    }
  }, [filters.country]);

  useEffect(() => {
    if (filters.university) {
      loadDepartmentsByUniversity(filters.university);
    } else {
      setUniversityDepartments([]);
    }
  }, [filters.university]);

  // Create user form state
  const [newUser, setNewUser] = useState({
    full_name: "",
    email: "",
    password: "",
    system_role: "user",
  });

  const handleCreateUser = async (e) => {
    e.preventDefault();
    try {
      await adminService.createUser(newUser);
      setNewUser({
        full_name: "",
        email: "",
        password: "",
        system_role: "user",
      });
      loadUsers();
    } catch (err) {
      alert("Failed to create user");
    }
  };

  const loadUsers = async () => {
    try {
      setLoading(true);
      const response = await adminService.getUsers({
        ...filters,
        page: currentPage,
        per_page: itemsPerPage,
      });

      // Handle response: {data: [...], meta: {...}}
      const usersData = response.data || response;
      const metadata = response.meta || {};

      setUsers(usersData);
      setTotalCount(metadata.total_count || usersData.length);
      setTotalPages(
        metadata.total_pages ||
          Math.ceil((metadata.total_count || usersData.length) / itemsPerPage)
      );
    } catch (e) {
      console.error(e);
      setError("Failed to load users");
    } finally {
      setLoading(false);
    }
  };

  const loadFilterOptions = async () => {
    try {
      const data = await adminService.getUserFilterOptions();
      setAvailableFilters(data);
    } catch (e) {
      console.error("Failed to load filter options:", e);
    }
  };

  const loadUniversitiesByCountry = async (country) => {
    try {
      const data = await adminService.getUserUniversitiesByCountry(country);
      setCountryUniversities(data.universities || []);
    } catch (e) {
      console.error("Failed to load universities:", e);
    }
  };

  const loadDepartmentsByUniversity = async (university) => {
    try {
      const data = await adminService.getUserDepartmentsByUniversity(
        university
      );
      setUniversityDepartments(data.departments || []);
    } catch (e) {
      console.error("Failed to load departments:", e);
    }
  };

  const handleFilterChange = (e) => {
    const { name, value } = e.target;
    setCurrentPage(1); // Reset to first page when filter changes
    setFilters((prev) => {
      const newFilters = { ...prev, [name]: value };
      if (name === "country") {
        newFilters.university = "";
        newFilters.department = "";
      }
      if (name === "university") {
        newFilters.department = "";
      }
      return newFilters;
    });
  };

  const handleDelete = async (userId) => {
    if (!window.confirm("Delete this user? This action cannot be undone."))
      return;
    try {
      await adminService.deleteUser(userId);
      loadUsers();
    } catch (e) {
      alert("Failed to delete user");
    }
  };

  const handleRoleChange = async (userId, newRole) => {
    try {
      await adminService.updateUserRole(userId, newRole);
      loadUsers();
    } catch (e) {
      alert("Failed to update role");
    }
  };

  const handleEditUser = async (user) => {
    setEditModal({
      show: true,
      user,
      formData: {
        full_name: user.full_name || "",
        email: user.email || "",
        system_role: user.system_role || "user",
        country: user.country || "",
        university: user.university || "",
        department: user.department || "",
      },
    });
  };

  const handleSaveEdit = async () => {
    try {
      await adminService.updateUser(editModal.user.id, editModal.formData);
      setEditModal({ show: false, user: null, formData: {} });
      loadUsers();
    } catch (e) {
      alert("Failed to update user");
    }
  };

  const openDetailModal = (user) => {
    setDetailModal({ show: true, user });
    // Fetch full user details
    fetchUserDetails(user.id);
  };

  const fetchUserDetails = async (userId) => {
    try {
      const fullUserData = await adminService.getUser(userId);
      setDetailModal((prev) => ({ ...prev, user: fullUserData }));
    } catch (e) {
      console.error("Failed to fetch user details:", e);
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
        <h1>Manage Users</h1>
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
              placeholder="Name or email"
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
              Role:
            </label>
            <select
              className="form-input"
              name="role"
              value={filters.role}
              onChange={handleFilterChange}
            >
              <option value="">All Roles</option>
              <option value="user">User</option>
              <option value="admin">Admin</option>
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
              Country:
            </label>
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
            <label
              style={{
                fontSize: "12px",
                fontWeight: "500",
                display: "block",
                marginBottom: "4px",
              }}
            >
              University:
            </label>
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
            <label
              style={{
                fontSize: "12px",
                fontWeight: "500",
                display: "block",
                marginBottom: "4px",
              }}
            >
              Department:
            </label>
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
          <div>
            <label
              style={{
                fontSize: "12px",
                fontWeight: "500",
                display: "block",
                marginBottom: "4px",
              }}
            >
              Banned:
            </label>
            <select
              className="form-input"
              name="banned"
              value={filters.banned}
              onChange={handleFilterChange}
            >
              <option value="">All</option>
              <option value="true">Banned Only</option>
              <option value="false">Active Only</option>
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
          <div style={{ display: "flex", alignItems: "flex-end" }}>
            <button
              className="btn btn-sm"
              onClick={() =>
                setFilters({
                  role: "",
                  country: "",
                  university: "",
                  department: "",
                  banned: "",
                  reported: "",
                  q: "",
                })
              }
              style={{ width: "100%" }}
            >
              Reset
            </button>
          </div>
        </div>

        <div style={{ marginTop: "12px" }}>
          {/* Create user form */}
          <form
            onSubmit={handleCreateUser}
            style={{
              display: "grid",
              gridTemplateColumns: "1fr 1fr 1fr auto",
              gap: "8px",
              marginBottom: "12px",
            }}
          >
            <input
              className="form-input"
              placeholder="Full name"
              value={newUser.full_name}
              onChange={(e) =>
                setNewUser({ ...newUser, full_name: e.target.value })
              }
              required
            />
            <input
              className="form-input"
              placeholder="Email"
              value={newUser.email}
              onChange={(e) =>
                setNewUser({ ...newUser, email: e.target.value })
              }
              required
            />
            <input
              className="form-input"
              placeholder="Password"
              value={newUser.password}
              onChange={(e) =>
                setNewUser({ ...newUser, password: e.target.value })
              }
              required
            />
            <button className="btn btn-primary" type="submit">
              Create User
            </button>
          </form>
          {users.length === 0 ? (
            <p>No users found.</p>
          ) : (
            <div style={{ display: "grid", gap: "8px" }}>
              {users.map((user) => (
                <div
                  key={user.id}
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
                      onClick={() => openDetailModal(user)}
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
                      {user.full_name}
                    </button>
                    <div style={{ color: "#6b7280", fontSize: "13px" }}>
                      {user.email}
                    </div>
                    <div style={{ color: "#6b7280", fontSize: "12px" }}>
                      {user.system_role || "user"}{" "}
                      {user.banned ? " • BANNED" : ""}
                      {user.reports_count > 0 && (
                        <span style={{ color: "#dc2626", marginLeft: "8px" }}>
                           {user.reports_count} report
                          {user.reports_count > 1 ? "s" : ""}
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
                    <select
                      value={user.system_role || "user"}
                      onChange={(e) =>
                        handleRoleChange(user.id, e.target.value)
                      }
                    >
                      <option value="user">user</option>
                      <option value="admin">admin</option>
                    </select>
                    <button
                      className="btn btn-sm"
                      onClick={() => handleEditUser(user)}
                    >
                      Edit
                    </button>
                    <button
                      className="btn btn-sm btn-danger"
                      onClick={() => handleDelete(user.id)}
                    >
                      Delete
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* Pagination Controls */}
          {!loading && users.length > 0 && (
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
                {totalCount} users
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
              maxWidth: "800px",
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
              <h2>User Details</h2>
              <button
                onClick={() => setDetailModal({ show: false, user: null })}
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
                <div
                  style={{
                    display: "grid",
                    gridTemplateColumns: "1fr 1fr",
                    gap: "8px",
                  }}
                >
                  <div>
                    <strong>Name:</strong> {detailModal.user.full_name}
                  </div>
                  <div>
                    <strong>Email:</strong> {detailModal.user.email}
                  </div>
                  <div>
                    <strong>Role:</strong>{" "}
                    <span
                      style={{
                        background:
                          detailModal.user.system_role === "admin"
                            ? "#fbbf24"
                            : "#3b82f6",
                        color: "white",
                        padding: "2px 8px",
                        borderRadius: "4px",
                        fontSize: "12px",
                      }}
                    >
                      {detailModal.user.system_role || "user"}
                    </span>
                  </div>
                  <div>
                    <strong>Status:</strong>{" "}
                    <span
                      style={{
                        color: detailModal.user.banned ? "#dc2626" : "#10b981",
                        fontWeight: "bold",
                      }}
                    >
                      {detailModal.user.banned ? "BANNED" : "Active"}
                    </span>
                  </div>
                  <div>
                    <strong>Country:</strong>{" "}
                    {detailModal.user.country || "Not set"}
                  </div>
                  <div>
                    <strong>University:</strong>{" "}
                    {detailModal.user.university || "Not set"}
                  </div>
                  <div>
                    <strong>Department:</strong>{" "}
                    {detailModal.user.department || "Not set"}
                  </div>
                  <div>
                    <strong>Joined:</strong>{" "}
                    {new Date(detailModal.user.created_at).toLocaleDateString()}
                  </div>
                </div>
              </div>

              {/* Activity Stats */}
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
                      {detailModal.user.owned_projects?.length || 0}
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
                      {detailModal.user.collaborations?.length || 0}
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
                      {detailModal.user.comments?.length || 0}
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
                      {detailModal.user.reports_count || 0}
                    </div>
                    <div style={{ fontSize: "12px", color: "#6b7280" }}>
                      Reports
                    </div>
                  </div>
                </div>
              </div>

              {/* Owned Projects */}
              {detailModal.user.owned_projects &&
                detailModal.user.owned_projects.length > 0 && (
                  <div
                    style={{
                      borderBottom: "2px solid #e5e7eb",
                      paddingBottom: "12px",
                    }}
                  >
                    <h3 style={{ marginBottom: "12px", color: "#1f2937" }}>
                      Owned Projects ({detailModal.user.owned_projects.length})
                    </h3>
                    <div style={{ display: "grid", gap: "8px" }}>
                      {detailModal.user.owned_projects.map((project) => (
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

              {/* Collaborations */}
              {detailModal.user.collaborations &&
                detailModal.user.collaborations.length > 0 && (
                  <div
                    style={{
                      borderBottom: "2px solid #e5e7eb",
                      paddingBottom: "12px",
                    }}
                  >
                    <h3 style={{ marginBottom: "12px", color: "#1f2937" }}>
                      Collaborating On ({detailModal.user.collaborations.length}
                      )
                    </h3>
                    <div style={{ display: "grid", gap: "8px" }}>
                      {detailModal.user.collaborations.map((collab) => (
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

              {/* Funding Activity */}
              {detailModal.user.funds && detailModal.user.funds.length > 0 && (
                <div
                  style={{
                    borderBottom: "2px solid #e5e7eb",
                    paddingBottom: "12px",
                  }}
                >
                  <h3 style={{ marginBottom: "12px", color: "#1f2937" }}>
                    Funding Activity ({detailModal.user.funds.length})
                  </h3>
                  <div style={{ display: "grid", gap: "8px" }}>
                    {detailModal.user.funds.map((fund) => (
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
                          <strong>{fund.project?.title || "Project"}</strong>
                          <div style={{ fontSize: "11px", color: "#9ca3af" }}>
                            {fund.funded_at
                              ? new Date(fund.funded_at).toLocaleDateString()
                              : new Date(fund.created_at).toLocaleDateString()}
                          </div>
                        </div>
                        <div style={{ fontWeight: "bold", color: "#10b981" }}>
                          ${Number(fund.amount).toFixed(2)}
                        </div>
                      </div>
                    ))}
                  </div>
                  <div
                    style={{
                      marginTop: "8px",
                      fontWeight: "bold",
                      color: "#10b981",
                    }}
                  >
                    Total Funded: $
                    {detailModal.user.funds
                      .reduce((sum, f) => sum + Number(f.amount || 0), 0)
                      .toFixed(2)}
                  </div>
                </div>
              )}

              {/* Tags */}
              {detailModal.user.tags && detailModal.user.tags.length > 0 && (
                <div
                  style={{
                    borderBottom: "2px solid #e5e7eb",
                    paddingBottom: "12px",
                  }}
                >
                  <h3 style={{ marginBottom: "12px", color: "#1f2937" }}>
                    Tags/Interests
                  </h3>
                  <div
                    style={{ display: "flex", flexWrap: "wrap", gap: "6px" }}
                  >
                    {detailModal.user.tags.map((tag) => (
                      <span
                        key={tag.id}
                        style={{
                          background: "#3b82f6",
                          color: "white",
                          padding: "4px 12px",
                          borderRadius: "12px",
                          fontSize: "12px",
                        }}
                      >
                        {tag.tag_name}
                      </span>
                    ))}
                  </div>
                </div>
              )}

              {/* Recent Comments */}
              {detailModal.user.comments &&
                detailModal.user.comments.length > 0 && (
                  <div>
                    <h3 style={{ marginBottom: "12px", color: "#1f2937" }}>
                      Recent Comments ({detailModal.user.comments.length})
                    </h3>
                    <div
                      style={{
                        display: "grid",
                        gap: "8px",
                        maxHeight: "200px",
                        overflow: "auto",
                      }}
                    >
                      {detailModal.user.comments.slice(0, 5).map((comment) => (
                        <div
                          key={comment.id}
                          style={{
                            padding: "8px",
                            background: "#f9fafb",
                            borderRadius: "6px",
                            fontSize: "13px",
                          }}
                        >
                          <div
                            style={{ color: "#6b7280", marginBottom: "4px" }}
                          >
                            Project #{comment.project_id} •{" "}
                            {new Date(comment.created_at).toLocaleDateString()}
                          </div>
                          <div>{comment.content}</div>
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
              <h2>Edit User</h2>
              <button
                onClick={() =>
                  setEditModal({ show: false, user: null, formData: {} })
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
                  Full Name
                </label>
                <input
                  className="form-input"
                  value={editModal.formData.full_name}
                  onChange={(e) =>
                    setEditModal({
                      ...editModal,
                      formData: {
                        ...editModal.formData,
                        full_name: e.target.value,
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
                  Email
                </label>
                <input
                  className="form-input"
                  type="email"
                  value={editModal.formData.email}
                  onChange={(e) =>
                    setEditModal({
                      ...editModal,
                      formData: {
                        ...editModal.formData,
                        email: e.target.value,
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
                  System Role
                </label>
                <select
                  className="form-input"
                  value={editModal.formData.system_role}
                  onChange={(e) =>
                    setEditModal({
                      ...editModal,
                      formData: {
                        ...editModal.formData,
                        system_role: e.target.value,
                      },
                    })
                  }
                >
                  <option value="user">User</option>
                  <option value="admin">Admin</option>
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
                  Country
                </label>
                <input
                  className="form-input"
                  value={editModal.formData.country}
                  onChange={(e) =>
                    setEditModal({
                      ...editModal,
                      formData: {
                        ...editModal.formData,
                        country: e.target.value,
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
                  University
                </label>
                <input
                  className="form-input"
                  value={editModal.formData.university}
                  onChange={(e) =>
                    setEditModal({
                      ...editModal,
                      formData: {
                        ...editModal.formData,
                        university: e.target.value,
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
                  Department
                </label>
                <input
                  className="form-input"
                  value={editModal.formData.department}
                  onChange={(e) =>
                    setEditModal({
                      ...editModal,
                      formData: {
                        ...editModal.formData,
                        department: e.target.value,
                      },
                    })
                  }
                />
              </div>
              <div style={{ display: "flex", gap: "8px", marginTop: "8px" }}>
                <button className="btn btn-primary" onClick={handleSaveEdit}>
                  Save Changes
                </button>
                <button
                  className="btn"
                  onClick={() =>
                    setEditModal({ show: false, user: null, formData: {} })
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

export default ManageUsers;
