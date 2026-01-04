import React, { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import {
  projectService,
  commentService,
  collaborationService,
  resourceService,
  fundService,
  userService,
  authService,
} from "../apiService";
import { getRelativeTime } from "../utils/dateUtils";

const ProjectDetails = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const currentUser = authService.getCurrentUser();

  const [project, setProject] = useState(null);
  const [comments, setComments] = useState([]);
  const [collaborators, setCollaborators] = useState([]);
  const [resources, setResources] = useState([]);
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  // Form states
  const [newComment, setNewComment] = useState("");
  const [newCollaborator, setNewCollaborator] = useState({
    user_id: "",
    project_role: "member",
  });
  const [replyTo, setReplyTo] = useState(null);
  const [replyContent, setReplyContent] = useState("");
  const [fundAmount, setFundAmount] = useState("");
  const [hasVoted, setHasVoted] = useState(false);

  useEffect(() => {
    loadProjectData();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  const loadProjectData = async () => {
    try {
      setLoading(true);

      // Load project details
      const projectData = await projectService.getProject(id);
      setProject(projectData);

      // Check if current user has voted
      if (currentUser && projectData.votes) {
        const userVote = projectData.votes.find(
          (v) => v.user_id === currentUser.id
        );
        setHasVoted(!!userVote);
      }

      // Load related data
      const [commentsData, collaboratorsData, resourcesData, usersData] =
        await Promise.all([
          commentService.getComments(id),
          collaborationService.getCollaborators(id),
          resourceService.getResources(id),
          userService.getUsers(),
        ]);

      setComments(commentsData);
      setCollaborators(collaboratorsData);
      setResources(resourcesData);
      setUsers(usersData);
    } catch (error) {
      setError("Failed to load project details");
      console.error("Project details error:", error);
    } finally {
      setLoading(false);
    }
  };

  // Vote toggle handled inline by single button

  const handleDelete = async () => {
    if (
      window.confirm(
        "Are you sure you want to delete this project? This action cannot be undone."
      )
    ) {
      try {
        await projectService.deleteProject(id);
        navigate("/projects");
      } catch (error) {
        alert("Failed to delete project");
      }
    }
  };

  const handleAddComment = async (e) => {
    e.preventDefault();
    if (!newComment.trim()) return;

    try {
      await commentService.addComment(id, { content: newComment });
      setNewComment("");
      loadProjectData(); // Reload to show new comment
    } catch (error) {
      alert("Failed to add comment");
    }
  };

  const handleReply = async (e) => {
    e.preventDefault();
    if (!replyContent.trim()) return;

    try {
      await commentService.addComment(id, {
        content: replyContent,
        parent_id: replyTo,
      });
      setReplyContent("");
      setReplyTo(null);
      loadProjectData(); // Reload to show new reply
    } catch (error) {
      alert("Failed to add reply");
    }
  };

  const handleAddCollaborator = async (e) => {
    e.preventDefault();
    // Determine who we are adding: owner invites someone, others join themselves
    const isOwner = project.owner_id === currentUser?.id;

    const payload = isOwner
      ? {
          user_id: newCollaborator.user_id,
          project_role: newCollaborator.project_role,
        }
      : {
          user_id: currentUser?.id,
          project_role: newCollaborator.project_role,
        };

    if (!payload.user_id || !payload.project_role) return;

    try {
      await collaborationService.addCollaborator(id, payload);
      setNewCollaborator({ user_id: "", project_role: "member" });
      loadProjectData(); // Reload to show new collaborator
    } catch (error) {
      const msg =
        error.response?.data?.errors?.join?.(", ") ||
        error.response?.data?.error ||
        "Failed to join/invite collaborator";
      alert(msg);
    }
  };

  const handleAddFund = async (e) => {
    e.preventDefault();
    const amount = parseFloat(fundAmount);
    if (!amount || amount <= 0) {
      alert("Please enter a valid amount");
      return;
    }

    try {
      await fundService.addFund(id, { amount });
      setFundAmount("");
      loadProjectData(); // Reload to show new fund
      alert("Thank you for your contribution!");
    } catch (error) {
      alert("Failed to add fund");
    }
  };

  if (loading) {
    return (
      <div className="loading">
        <div className="spinner"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="container">
        <div className="alert alert-error">{error}</div>
      </div>
    );
  }

  if (!project) {
    return (
      <div className="container">
        <div className="alert alert-error">Project not found</div>
      </div>
    );
  }

  const isOwner = project.owner_id === currentUser?.id;
  const isAlreadyCollaborator = collaborators?.some(
    (c) => c.user?.id === currentUser?.id
  );

  return (
    <div className="container">
      <div style={{ paddingTop: "20px" }}>
        {/* Project Header */}
        <div className="card">
          <div className="flex justify-between items-start mb-4">
            <div style={{ flex: 1 }}>
              <h1 style={{ marginBottom: "8px" }}>{project.title}</h1>
              <div className="flex items-center gap-4 mb-2">
                <span
                  className={`project-status status-${project.status?.toLowerCase()}`}
                >
                  {project.status}
                </span>
                <span style={{ color: "#6b7280" }}>
                  by {project.owner?.full_name}
                </span>
                <span style={{ color: "#6b7280", fontSize: "14px" }}>
                  {project.visibility} • Created{" "}
                  {getRelativeTime(project.created_at)}
                </span>
              </div>
            </div>

            <div style={{ display: "flex", gap: "10px", flexWrap: "wrap" }}>
              {/* Single toggle button for vote */}
              <button
                type="button"
                onClick={async (e) => {
                  e.preventDefault();
                  e.stopPropagation();
                  try {
                    if (hasVoted) {
                      // Unvote if already voted
                      await projectService.unvoteProject(id);
                      setHasVoted(false);
                      alert("Vote removed!");
                    } else {
                      // Vote if not voted yet
                      await projectService.voteProject(id);
                      setHasVoted(true);
                      alert("Vote recorded!");
                    }
                    loadProjectData(); // Reload to get updated count
                  } catch (err) {
                    console.error("Vote error:", err);
                    alert(
                      "Failed to vote: " +
                        (err.response?.data?.error || err.message)
                    );
                  }
                }}
                className={hasVoted ? "btn btn-success" : "btn btn-primary"}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "8px",
                  minWidth: "140px",
                }}
              >
                <span style={{ fontSize: "18px" }}>
                  {hasVoted ? "✓" : "⬆️"}
                </span>
                <span>
                  {hasVoted ? "Unvote" : "Vote"} •{" "}
                  {project.project_stat?.total_votes || 0}
                </span>
              </button>
              {isOwner && (
                <>
                  <button
                    type="button"
                    onClick={() => navigate(`/projects/${id}/edit`)}
                    className="btn btn-success"
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: "8px",
                      minWidth: "100px",
                    }}
                  >
                    <span style={{ fontSize: "16px" }}>✏️</span>
                    <span>Edit</span>
                  </button>
                  <button
                    type="button"
                    onClick={handleDelete}
                    className="btn btn-danger"
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: "8px",
                      minWidth: "100px",
                    }}
                  >
                    <span style={{ fontSize: "16px" }}>🗑️</span>
                    <span>Delete</span>
                  </button>
                </>
              )}
            </div>
          </div>

          <p style={{ lineHeight: "1.6", marginBottom: "16px" }}>
            {project.description}
          </p>

          {/* Project Stats */}
          {project.project_stat && (
            <div
              style={{
                display: "flex",
                gap: "24px",
                padding: "16px",
                background: "#f9fafb",
                borderRadius: "6px",
              }}
            >
              <span>{project.project_stat.total_views} views</span>
              <span> {project.project_stat.total_votes} votes</span>
              <span>{project.project_stat.total_comments} comments</span>
            </div>
          )}
        </div>

        {/* Project Resources */}
        {resources.length > 0 && (
          <div className="card">
            <h3 style={{ marginBottom: "16px" }}>Project Resources</h3>
            <div style={{ display: "grid", gap: "12px" }}>
              {resources.map((resource) => (
                <div
                  key={resource.id}
                  style={{
                    padding: "12px",
                    border: "1px solid #e5e7eb",
                    borderRadius: "6px",
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                  }}
                >
                  <div>
                    <strong>{resource.file_name}</strong>
                    <span
                      style={{
                        marginLeft: "8px",
                        fontSize: "12px",
                        color: "#6b7280",
                        textTransform: "uppercase",
                      }}
                    >
                      {resource.resource_type}
                    </span>
                  </div>
                  <a
                    href={resource.file_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="btn btn-sm btn-outline"
                  >
                    Open
                  </a>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Team / Join Section */}
        <div className="card">
          <h3 style={{ marginBottom: "16px" }}>Team</h3>

          {collaborators.length > 0 ? (
            <div style={{ marginBottom: "24px" }}>
              {collaborators.map((collab) => (
                <div
                  key={collab.id}
                  style={{
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                    padding: "12px",
                    border: "1px solid #e5e7eb",
                    borderRadius: "6px",
                    marginBottom: "8px",
                  }}
                >
                  <div
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: "8px",
                      flexWrap: "wrap",
                    }}
                  >
                    <strong>{collab.user?.full_name}</strong>
                    {/* Role badge only */}
                    <span
                      style={{
                        background: "#e5e7eb",
                        color: "#374151",
                        borderRadius: "999px",
                        padding: "2px 8px",
                        fontSize: "12px",
                      }}
                    >
                      {collab.project_role}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <p style={{ color: "#6b7280", marginBottom: "24px" }}>
              No collaborators yet. Be the first to join!
            </p>
          )}

          {/* Join or Invite */}
          <form onSubmit={handleAddCollaborator}>
            {isOwner ? (
              <>
                <h4 style={{ marginBottom: "12px" }}>Invite Collaborator</h4>
                <div
                  style={{
                    display: "grid",
                    gridTemplateColumns: "2fr 2fr auto",
                    gap: "12px",
                    alignItems: "end",
                  }}
                >
                  <div className="form-group" style={{ marginBottom: "0" }}>
                    <label className="form-label">User</label>
                    <select
                      value={newCollaborator.user_id}
                      onChange={(e) =>
                        setNewCollaborator({
                          ...newCollaborator,
                          user_id: e.target.value,
                        })
                      }
                      className="form-select"
                      required
                    >
                      <option value="">Select a user</option>
                      {users.map((user) => (
                        <option key={user.id} value={user.id}>
                          {user.full_name}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="form-group" style={{ marginBottom: "0" }}>
                    <label className="form-label">Role</label>
                    <select
                      value={newCollaborator.project_role}
                      onChange={(e) =>
                        setNewCollaborator({
                          ...newCollaborator,
                          project_role: e.target.value,
                        })
                      }
                      className="form-select"
                    >
                      <option value="member">Member - Can edit project</option>
                      <option value="viewer">Viewer - Can view only</option>
                    </select>
                  </div>

                  <button type="submit" className="btn btn-primary">
                    Invite
                  </button>
                </div>
              </>
            ) : (
              <>
                <h4 style={{ marginBottom: "12px" }}>Join this project</h4>
                {isAlreadyCollaborator ? (
                  <p style={{ color: "#6b7280" }}>
                    You are already part of this project.
                  </p>
                ) : (
                  <div
                    style={{
                      display: "grid",
                      gridTemplateColumns: "2fr auto",
                      gap: "12px",
                      alignItems: "end",
                    }}
                  >
                    <div className="form-group" style={{ marginBottom: "0" }}>
                      <label className="form-label">Join as</label>
                      <select
                        value={newCollaborator.project_role}
                        onChange={(e) =>
                          setNewCollaborator({
                            ...newCollaborator,
                            project_role: e.target.value,
                          })
                        }
                        className="form-select"
                      >
                        <option value="member">
                          Member - Can edit project
                        </option>
                        <option value="viewer">Viewer - Can view only</option>
                      </select>
                    </div>

                    <button type="submit" className="btn btn-primary">
                      Join Project
                    </button>
                  </div>
                )}
              </>
            )}
          </form>
        </div>

        {/* Funding Section */}
        <div className="card">
          <h3 style={{ marginBottom: "16px" }}>Funding</h3>

          {/* Total Funding */}
          {project.funds && project.funds.length > 0 && (
            <div
              style={{
                padding: "16px",
                backgroundColor: "#f0fdf4",
                borderRadius: "8px",
                marginBottom: "24px",
                border: "1px solid #86efac",
              }}
            >
              <div
                style={{
                  fontSize: "14px",
                  color: "#6b7280",
                  marginBottom: "4px",
                }}
              >
                Total Funding
              </div>
              <div
                style={{
                  fontSize: "28px",
                  fontWeight: "bold",
                  color: "#16a34a",
                }}
              >
                $
                {project.funds
                  .reduce((sum, fund) => sum + Number(fund.amount), 0)
                  .toFixed(2)}
              </div>
            </div>
          )}

          {/* Funding List */}
          {project.funds && project.funds.length > 0 ? (
            <div style={{ marginBottom: "24px" }}>
              <h4 style={{ marginBottom: "12px", fontSize: "16px" }}>
                Contributors
              </h4>
              <div
                style={{ display: "flex", flexDirection: "column", gap: "8px" }}
              >
                {project.funds.map((fund) => (
                  <div
                    key={fund.id}
                    style={{
                      padding: "12px",
                      backgroundColor: "#f9fafb",
                      borderRadius: "6px",
                      display: "flex",
                      justifyContent: "space-between",
                      alignItems: "center",
                    }}
                  >
                    <div>
                      <div style={{ fontWeight: "500" }}>
                        {fund.funder ? fund.funder.full_name : "Anonymous"}
                      </div>
                      <div style={{ fontSize: "12px", color: "#6b7280" }}>
                        {new Date(fund.funded_at).toLocaleDateString()}
                      </div>
                    </div>
                    <div
                      style={{
                        fontSize: "18px",
                        fontWeight: "bold",
                        color: "#16a34a",
                      }}
                    >
                      ${Number(fund.amount).toFixed(2)}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ) : (
            <p style={{ color: "#6b7280", marginBottom: "24px" }}>
              No contributions yet. Be the first to support this project!
            </p>
          )}

          {/* Add Funding Form */}
          <form onSubmit={handleAddFund}>
            <h4 style={{ marginBottom: "12px", fontSize: "16px" }}>
              Support This Project
            </h4>
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "1fr auto",
                gap: "12px",
                alignItems: "end",
              }}
            >
              <div className="form-group" style={{ marginBottom: "0" }}>
                <label className="form-label">Amount ($)</label>
                <input
                  type="number"
                  step="0.01"
                  min="0.01"
                  value={fundAmount}
                  onChange={(e) => setFundAmount(e.target.value)}
                  className="form-input"
                  placeholder="Enter amount"
                  required
                />
              </div>
              <button type="submit" className="btn btn-primary">
                Contribute
              </button>
            </div>
          </form>
        </div>

        {/* Comments Section */}
        <div className="card">
          <h3 style={{ marginBottom: "16px" }}>Comments</h3>

          {/* Add Comment Form */}
          <form onSubmit={handleAddComment} style={{ marginBottom: "24px" }}>
            <div className="form-group">
              <textarea
                value={newComment}
                onChange={(e) => setNewComment(e.target.value)}
                className="form-textarea"
                placeholder="Add a comment..."
                required
              />
            </div>
            <button type="submit" className="btn btn-primary">
              Add Comment
            </button>
          </form>

          {/* Comments List */}
          {comments.length > 0 ? (
            <div className="comment-section">
              {comments.map((comment) => (
                <div key={comment.id} className="comment">
                  <div className="comment-author">
                    {comment.user?.full_name}
                  </div>
                  <div className="comment-content">{comment.content}</div>
                  <div className="comment-meta">
                    <span style={{ color: "#6b7280", fontSize: "13px" }}>
                      {getRelativeTime(comment.created_at)}
                    </span>
                    <button
                      onClick={() =>
                        setReplyTo(replyTo === comment.id ? null : comment.id)
                      }
                      style={{
                        marginLeft: "12px",
                        background: "none",
                        border: "none",
                        color: "#3b82f6",
                        cursor: "pointer",
                        fontSize: "12px",
                      }}
                    >
                      {replyTo === comment.id ? "Cancel" : "Reply"}
                    </button>
                  </div>

                  {/* Reply Form */}
                  {replyTo === comment.id && (
                    <form onSubmit={handleReply} style={{ marginTop: "12px" }}>
                      <div className="form-group">
                        <textarea
                          value={replyContent}
                          onChange={(e) => setReplyContent(e.target.value)}
                          className="form-textarea"
                          placeholder="Write a reply..."
                          style={{ minHeight: "80px" }}
                          required
                        />
                      </div>
                      <div className="flex gap-2">
                        <button
                          type="submit"
                          className="btn btn-sm btn-primary"
                        >
                          Reply
                        </button>
                        <button
                          type="button"
                          onClick={() => {
                            setReplyTo(null);
                            setReplyContent("");
                          }}
                          className="btn btn-sm btn-outline"
                        >
                          Cancel
                        </button>
                      </div>
                    </form>
                  )}
                </div>
              ))}
            </div>
          ) : (
            <p style={{ color: "#6b7280" }}>
              No comments yet. Be the first to comment!
            </p>
          )}
        </div>
      </div>
    </div>
  );
};

export default ProjectDetails;
