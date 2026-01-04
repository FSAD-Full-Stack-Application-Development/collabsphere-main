import React, { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { projectService } from '../apiService';

const EditProject = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [projectData, setProjectData] = useState({
    title: '',
    description: '',
    status: 'Ideation',
    visibility: 'public',
  });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    loadProject();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  const loadProject = async () => {
    try {
      setLoading(true);
      const data = await projectService.getProject(id);
      setProjectData({
        title: data.title || '',
        description: data.description || '',
        status: data.status || 'Ideation',
        visibility: data.visibility || 'public',
      });
    } catch (error) {
      setError('Failed to load project');
      console.error('Load error:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e) => {
    setProjectData({
      ...projectData,
      [e.target.name]: e.target.value,
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSaving(true);
    setError('');

    try {
      await projectService.updateProject(id, { project: projectData });
      navigate(`/projects/${id}`);
    } catch (error) {
      const errorMessage = error.response?.data?.errors 
        ? error.response.data.errors.join(', ')
        : error.response?.data?.error || 'Failed to update project';
      setError(errorMessage);
    } finally {
      setSaving(false);
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
      <div style={{ maxWidth: '600px', margin: '0 auto', paddingTop: '20px' }}>
        <div className="card">
          <div className="flex justify-between items-center mb-6">
            <h2>Edit Project</h2>
            <button
              onClick={() => navigate(`/projects/${id}`)}
              className="btn btn-sm btn-outline"
            >
              Cancel
            </button>
          </div>

          {error && (
            <div className="alert alert-error">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit}>
            {/* Project Title */}
            <div className="form-group">
              <label className="form-label">Project Title *</label>
              <input
                type="text"
                name="title"
                value={projectData.title}
                onChange={handleChange}
                className="form-input"
                required
                placeholder="e.g., AI-Powered Education Platform"
              />
            </div>

            {/* Description */}
            <div className="form-group">
              <label className="form-label">Description *</label>
              <textarea
                name="description"
                value={projectData.description}
                onChange={handleChange}
                className="form-textarea"
                required
                placeholder="Describe your project..."
                style={{ minHeight: '120px' }}
              />
            </div>

            {/* Project Status */}
            <div className="form-group">
              <label className="form-label">Project Status *</label>
              <select
                name="status"
                value={projectData.status}
                onChange={handleChange}
                className="form-select"
                required
              >
                <option value="Ideation">Ideation - Project in idea phase</option>
                <option value="Ongoing">Ongoing - Project actively in progress</option>
                <option value="Completed">Completed - Project finished</option>
              </select>
            </div>

            {/* Visibility */}
            <div className="form-group">
              <label className="form-label">Visibility *</label>
              <select
                name="visibility"
                value={projectData.visibility}
                onChange={handleChange}
                className="form-select"
                required
              >
                <option value="public">Public - Visible to everyone</option>
                <option value="private">Private - Only you can see</option>
                <option value="restricted">Restricted - Only collaborators can see</option>
              </select>
            </div>

            {/* Submit Button */}
            <div className="flex gap-3">
              <button
                type="submit"
                className="btn btn-primary"
                disabled={saving}
              >
                {saving ? 'Saving...' : 'Save Changes'}
              </button>
              <button
                type="button"
                onClick={() => navigate(`/projects/${id}`)}
                className="btn btn-outline"
              >
                Cancel
              </button>
            </div>
          </form>
        </div>

        {/* Help Info */}
        <div className="card" style={{ marginTop: '24px', border: '2px dashed #3b82f6', backgroundColor: '#eff6ff' }}>
          <h3 style={{ color: '#1e40af', marginBottom: '8px', fontSize: '14px' }}>
            Editing Project
          </h3>
          <p style={{ color: '#1e40af', fontSize: '13px', margin: 0 }}>
            Update your project details. Changes will be saved immediately and visible to collaborators.
          </p>
        </div>
      </div>
    </div>
  );
};

export default EditProject;
