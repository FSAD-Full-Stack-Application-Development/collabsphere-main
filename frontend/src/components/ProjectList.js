import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { projectService } from "../apiService";
import { getRelativeTime } from "../utils/dateUtils";

const ProjectList = () => {
  const [projects, setProjects] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalCount, setTotalCount] = useState(0);
  const itemsPerPage = 12;

  useEffect(() => {
    loadProjects();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentPage]);

  const loadProjects = async () => {
    try {
      setLoading(true);
      const response = await projectService.getProjects({
        page: currentPage,
        per_page: itemsPerPage,
      });

      // Handle response: {data: [...], meta: {...}}
      const projectsData = response.data || response;
      const metadata = response.meta || {};

      setProjects(projectsData);
      setTotalCount(metadata.total_count || projectsData.length);
      setTotalPages(
        metadata.total_pages ||
          Math.ceil(
            (metadata.total_count || projectsData.length) / itemsPerPage
          )
      );
    } catch (error) {
      setError("Failed to load projects");
      console.error("Projects error:", error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="loading">
        <div className="spinner"></div>
      </div>
    );
  }

  return (
    <div className="container">
      <div style={{ paddingTop: "20px" }}>
        {/* Header */}
        <div className="flex justify-between items-center mb-4">
          <h1>All Projects</h1>
          <Link to="/projects/new" className="btn btn-primary">
            Create New Project
          </Link>
        </div>

        {error && <div className="alert alert-error">{error}</div>}

        {/* Projects Grid */}
        {projects.length > 0 ? (
          <div className="project-grid">
            {projects.map((project) => (
              <div key={project.id} className="project-card">
                <h3 className="project-title">
                  <Link
                    to={`/projects/${project.id}`}
                    style={{ textDecoration: "none", color: "inherit" }}
                  >
                    {project.title}
                  </Link>
                </h3>

                <p className="project-description">
                  {project.description?.substring(0, 150)}
                  {project.description?.length > 150 ? "..." : ""}
                </p>

                {/* Project Stats */}
                {project.project_stat && (
                  <div
                    style={{
                      display: "flex",
                      gap: "16px",
                      margin: "12px 0",
                      fontSize: "14px",
                      color: "#6b7280",
                    }}
                  >
                    <span>{project.project_stat.total_views} views</span>
                    <span> {project.project_stat.total_votes} votes</span>
                    <span>{project.project_stat.total_comments} comments</span>
                  </div>
                )}

                {/* Tags */}
                {project.tags && project.tags.length > 0 && (
                  <div style={{ marginBottom: "12px" }}>
                    {project.tags.slice(0, 3).map((tag) => (
                      <span
                        key={tag.id}
                        style={{
                          background: "#e5e7eb",
                          padding: "2px 6px",
                          borderRadius: "3px",
                          fontSize: "11px",
                          marginRight: "6px",
                          color: "#374151",
                        }}
                      >
                        {tag.tag_name}
                      </span>
                    ))}
                    {project.tags.length > 3 && (
                      <span style={{ fontSize: "11px", color: "#6b7280" }}>
                        +{project.tags.length - 3} more
                      </span>
                    )}
                  </div>
                )}

                {/* Actions */}
                <div className="flex justify-between items-center">
                  <div style={{ fontSize: "13px", color: "#6b7280" }}>
                    <span>Vote count: {project.vote_count || 0}</span>
                  </div>

                  <Link
                    to={`/projects/${project.id}`}
                    className="btn btn-sm btn-primary"
                  >
                    View Details & Vote
                  </Link>
                </div>

                {/* Project Meta */}
                <div className="project-meta">
                  <span
                    className={`project-status status-${project.status?.toLowerCase()}`}
                  >
                    {project.status}
                  </span>
                  <div>
                    <span>by {project.owner?.full_name}</span>
                    <br />
                    <span style={{ fontSize: "11px", color: "#9ca3af" }}>
                      {project.visibility} •{" "}
                      {getRelativeTime(project.created_at)}
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div
            className="card"
            style={{ textAlign: "center", padding: "60px" }}
          >
            <h3 style={{ color: "#6b7280", marginBottom: "16px" }}>
              No projects found
            </h3>
            <p style={{ color: "#6b7280", marginBottom: "24px" }}>
              Be the first to create a project and start collaborating!
            </p>
            <Link to="/projects/new" className="btn btn-primary">
              Create First Project
            </Link>
          </div>
        )}

        {/* Pagination Controls */}
        {!loading && projects.length > 0 && totalPages > 1 && (
          <div
            style={{
              display: "flex",
              justifyContent: "center",
              alignItems: "center",
              marginTop: "32px",
              marginBottom: "32px",
              padding: "16px",
              background: "#f9fafb",
              borderRadius: "8px",
            }}
          >
            <div style={{ display: "flex", gap: "8px", alignItems: "center" }}>
              <button
                className="btn btn-sm"
                onClick={() => setCurrentPage(1)}
                disabled={currentPage === 1}
                style={{
                  opacity: currentPage === 1 ? 0.5 : 1,
                  cursor: currentPage === 1 ? "not-allowed" : "pointer",
                }}
              >
                First
              </button>
              <button
                className="btn btn-sm"
                onClick={() => setCurrentPage(currentPage - 1)}
                disabled={currentPage === 1}
                style={{
                  opacity: currentPage === 1 ? 0.5 : 1,
                  cursor: currentPage === 1 ? "not-allowed" : "pointer",
                }}
              >
                Previous
              </button>
              <span
                style={{
                  padding: "0 16px",
                  fontSize: "14px",
                  fontWeight: "500",
                }}
              >
                Page {currentPage} of {totalPages}
              </span>
              <button
                className="btn btn-sm"
                onClick={() => setCurrentPage(currentPage + 1)}
                disabled={currentPage === totalPages}
                style={{
                  opacity: currentPage === totalPages ? 0.5 : 1,
                  cursor:
                    currentPage === totalPages ? "not-allowed" : "pointer",
                }}
              >
                Next
              </button>
              <button
                className="btn btn-sm"
                onClick={() => setCurrentPage(totalPages)}
                disabled={currentPage === totalPages}
                style={{
                  opacity: currentPage === totalPages ? 0.5 : 1,
                  cursor:
                    currentPage === totalPages ? "not-allowed" : "pointer",
                }}
              >
                Last
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default ProjectList;
