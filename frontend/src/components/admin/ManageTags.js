import React, { useEffect, useState } from "react";
import { adminService } from "../../apiService";

const ManageTags = () => {
  const [tags, setTags] = useState([]);
  const [loading, setLoading] = useState(true);
  const [newTag, setNewTag] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalCount, setTotalCount] = useState(0);
  const itemsPerPage = 50;

  useEffect(() => {
    loadTags();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentPage]);

  const loadTags = async () => {
    try {
      setLoading(true);
      const response = await adminService.getTags({
        page: currentPage,
        per_page: itemsPerPage,
      });

      // Handle response: {data: [...], meta: {...}}
      const tagsData = response.data || response;
      const metadata = response.meta || {};

      setTags(tagsData);
      setTotalCount(metadata.total_count || tagsData.length);
      setTotalPages(
        metadata.total_pages ||
          Math.ceil((metadata.total_count || tagsData.length) / itemsPerPage)
      );
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const handleCreate = async (e) => {
    e.preventDefault();
    if (!newTag.trim()) return;
    try {
      await adminService.createTag({ tag_name: newTag });
      setNewTag("");
      loadTags();
    } catch (e) {
      alert("Failed to create tag");
    }
  };

  const handleDelete = async (tagId) => {
    if (!window.confirm("Delete this tag?")) return;
    try {
      await adminService.deleteTag(tagId);
      loadTags();
    } catch (e) {
      alert("Failed to delete tag");
    }
  };

  const handleEdit = async (tag) => {
    const newName = window.prompt("New tag name", tag.tag_name);
    if (newName === null || !newName.trim()) return;
    try {
      await adminService.updateTag(tag.id, { tag_name: newName });
      loadTags();
    } catch (e) {
      alert("Failed to update tag");
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
        <h1>Manage Tags</h1>

        <form
          onSubmit={handleCreate}
          style={{ display: "flex", gap: "8px", marginTop: "12px" }}
        >
          <input
            value={newTag}
            onChange={(e) => setNewTag(e.target.value)}
            placeholder="New tag name"
            className="form-input"
          />
          <button className="btn btn-primary" type="submit">
            Create
          </button>
        </form>

        <div style={{ marginTop: "16px", display: "grid", gap: "8px" }}>
          {tags.length === 0 ? (
            <p>No tags found.</p>
          ) : (
            tags.map((tag) => (
              <div
                key={tag.id}
                style={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  padding: "8px",
                  border: "1px solid #e5e7eb",
                  borderRadius: "6px",
                }}
              >
                <div>{tag.tag_name}</div>
                <div style={{ display: "flex", gap: "8px" }}>
                  <button
                    className="btn btn-sm"
                    onClick={() => handleEdit(tag)}
                  >
                    Edit
                  </button>
                  <button
                    className="btn btn-sm btn-danger"
                    onClick={() => handleDelete(tag.id)}
                  >
                    Delete
                  </button>
                </div>
              </div>
            ))
          )}

          {/* Pagination Controls */}
          {!loading && tags.length > 0 && (
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
                {totalCount} tags
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
    </div>
  );
};

export default ManageTags;
