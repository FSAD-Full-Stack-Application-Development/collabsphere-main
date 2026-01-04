import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { projectService, resourceService } from '../apiService';

const CreateProject = () => {
  const [projectData, setProjectData] = useState({
    title: '',
    description: '',
    status: 'Ideation',
    visibility: 'public',
  });
  const [resourceData, setResourceData] = useState({
    file_name: '',
    file_url: '',
    resource_type: 'document',
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [showResourceForm, setShowResourceForm] = useState(false);
  const navigate = useNavigate();

  const handleProjectChange = (e) => {
    setProjectData({
      ...projectData,
      [e.target.name]: e.target.value,
    });
  };

  const handleResourceChange = (e) => {
    setResourceData({
      ...resourceData,
      [e.target.name]: e.target.value,
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      // Create the project first
      const project = await projectService.createProject(projectData);
      
      // If resource data is provided, add it to the project
      if (showResourceForm && resourceData.file_name && resourceData.file_url) {
        await resourceService.addResource(project.id, resourceData);
      }
      
      // Navigate to the new project
      navigate(`/projects/${project.id}`);
    } catch (error) {
      const errorMessage = error.response?.data?.errors 
        ? error.response.data.errors.join(', ')
        : error.response?.data?.error || 'Failed to create project';
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="container">
      <div style={{ maxWidth: '700px', margin: '0 auto', paddingTop: '20px', paddingBottom: '40px' }}>
        <div className="card">
          <div style={{ marginBottom: '32px' }}>
            <h2 style={{ marginBottom: '8px' }}>Create New Project</h2>
            <p style={{ color: 'var(--text-light)', fontSize: '15px', margin: 0 }}>
              Share your idea and collaborate with the community
            </p>
          </div>

          {error && (
            <div className="alert alert-error">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit}>
            {/* Project Details */}
            <div className="form-group">
              <label className="form-label">Project Title</label>
              <input
                type="text"
                name="title"
                value={projectData.title}
                onChange={handleProjectChange}
                className="form-input"
                required
                placeholder="e.g., AI-Powered Education Platform"
              />
            </div>

            <div className="form-group">
              <label className="form-label">Description</label>
              <textarea
                name="description"
                value={projectData.description}
                onChange={handleProjectChange}
                className="form-textarea"
                required
                placeholder="Describe your project, its goals, and what you're looking for..."
                style={{ minHeight: '120px' }}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Project Status</label>
              <select
                name="status"
                value={projectData.status}
                onChange={handleProjectChange}
                className="form-select"
                required
              >
                <option value="Ideation">Ideation - Project in idea phase</option>
                <option value="Ongoing">Ongoing - Project actively in progress</option>
                <option value="Completed">Completed - Project finished</option>
              </select>
            </div>

            <div className="form-group">
              <label className="form-label">Visibility</label>
              <select
                name="visibility"
                value={projectData.visibility}
                onChange={handleProjectChange}
                className="form-select"
                required
              >
                <option value="public">Public - Visible to everyone</option>
                <option value="private">Private - Only you can see</option>
                <option value="restricted">Restricted - Only collaborators can see</option>
              </select>
            </div>

            {/* Resource Section */}
            <div style={{ marginTop: '28px', paddingTop: '28px', borderTop: '2px solid var(--border-color)' }}>
              <div className="flex justify-between items-center" style={{ marginBottom: '20px' }}>
                <div>
                  <h4 style={{ margin: '0 0 4px 0', fontSize: '16px' }}>Add New Resource</h4>
                  <p style={{ margin: 0, fontSize: '13px', color: 'var(--text-light)' }}>
                    Attach documents, links, or files to your project
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() => setShowResourceForm(!showResourceForm)}
                  className="btn btn-sm btn-outline"
                  style={{ minWidth: '100px' }}
                >
                  {showResourceForm ? '✕ Hide' : '+ Add'}
                </button>
              </div>

              {showResourceForm && (
                <>
                  <div className="form-group">
                    <label className="form-label">Resource Name</label>
                    <input
                      type="text"
                      name="file_name"
                      value={resourceData.file_name}
                      onChange={handleResourceChange}
                      className="form-input"
                      placeholder="e.g., Project Proposal, Design Mockups"
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Resource URL</label>
                    <input
                      type="url"
                      name="file_url"
                      value={resourceData.file_url}
                      onChange={handleResourceChange}
                      className="form-input"
                      placeholder="https://example.com/document.pdf"
                    />
                  </div>

                  <div className="form-group">
                    <label className="form-label">Resource Type</label>
                    <select
                      name="resource_type"
                      value={resourceData.resource_type}
                      onChange={handleResourceChange}
                      className="form-select"
                    >
                      <option value="document">Document</option>
                      <option value="image">Image</option>
                      <option value="video">Video</option>
                      <option value="link">Link</option>
                      <option value="other">Other</option>
                    </select>
                  </div>
                </>
              )}
            </div>

            {/* Submit Button */}
            <div style={{ marginTop: '32px', display: 'flex', gap: '12px' }}>
              <button
                type="submit"
                className="btn btn-primary"
                disabled={loading}
                style={{ flex: 1 }}
              >
                {loading ? 'Creating Project...' : 'Create Project'}
              </button>
              
              <button
                type="button"
                onClick={() => navigate('/projects')}
                className="btn btn-outline"
                disabled={loading}
              >
                Cancel
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default CreateProject;