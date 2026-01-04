import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { projectService, userService, authService } from '../apiService';

const Dashboard = () => {
  const [userProfile, setUserProfile] = useState(null);
  const [recentProjects, setRecentProjects] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const currentUser = authService.getCurrentUser();

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      setLoading(true);
      
      // Load user profile
      const profile = await userService.getProfile();
      setUserProfile(profile);
      
      // Load recent projects
      const projects = await projectService.getProjects();
      setRecentProjects(projects.slice(0, 6)); // Show first 6 projects
      
    } catch (error) {
      setError('Failed to load dashboard data');
      console.error('Dashboard error:', error);
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
      <div style={{ paddingTop: '20px' }}>
        
        {/* Welcome Section */}
        <div className="card">
          <h1 style={{ marginBottom: '8px' }}>
            Welcome back, {currentUser?.full_name}! 
          </h1>
          <p style={{ color: '#6b7280', marginBottom: '0' }}>
            Manage your projects and collaborate with the community
          </p>
        </div>

        {error && (
          <div className="alert alert-error">
            {error}
          </div>
        )}

        {/* Profile Section */}
        {userProfile && (
          <div className="card">
            <div className="flex justify-between items-center mb-4">
              <h2 style={{ margin: '0' }}>Your Profile</h2>
              <Link to="/profile/edit" className="btn btn-sm btn-outline">
                Edit Profile
              </Link>
            </div>
            
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '16px' }}>
              <div>
                <strong>Email:</strong> {userProfile.email}
              </div>
              {userProfile.country && (
                <div>
                  <strong>Country:</strong> {userProfile.country}
                </div>
              )}
              {userProfile.university && (
                <div>
                  <strong>University:</strong> {userProfile.university}
                </div>
              )}
              {userProfile.department && (
                <div>
                  <strong>Department:</strong> {userProfile.department}
                </div>
              )}
              {/* professional_role removed in backend */}
            </div>
            
            {userProfile.bio && (
              <div style={{ marginTop: '16px' }}>
                <strong>Bio:</strong>
                <p style={{ margin: '4px 0 0 0', color: '#6b7280' }}>
                  {userProfile.bio}
                </p>
              </div>
            )}
            
            {userProfile.tags && userProfile.tags.length > 0 && (
              <div style={{ marginTop: '16px' }}>
                <strong>Skills/Interests:</strong>
                <div style={{ marginTop: '8px', display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
                  {userProfile.tags.map((tag, index) => (
                    <span
                      key={index}
                      style={{
                        background: '#e5e7eb',
                        padding: '4px 8px',
                        borderRadius: '4px',
                        fontSize: '12px',
                        color: '#374151'
                      }}
                    >
                      {tag}
                    </span>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}

        {/* Quick Actions */}
        <div className="card">
          <h2 style={{ marginBottom: '16px' }}>Quick Actions</h2>
          <div className="flex gap-4">
            <Link to="/projects/new" className="btn btn-primary">
              Create New Project
            </Link>
            <Link to="/projects" className="btn btn-outline">
              Browse All Projects
            </Link>
          </div>
        </div>

        {/* Recent Projects */}
        <div className="card">
          <div className="flex justify-between items-center mb-4">
            <h2 style={{ margin: '0' }}>Recent Projects</h2>
            <Link to="/projects" className="btn btn-sm btn-outline">
              View All
            </Link>
          </div>
          
          {recentProjects.length > 0 ? (
            <div className="project-grid">
              {recentProjects.map((project) => (
                <div key={project.id} className="project-card">
                  <h3 className="project-title">
                    <Link 
                      to={`/projects/${project.id}`}
                      style={{ textDecoration: 'none', color: 'inherit' }}
                    >
                      {project.title}
                    </Link>
                  </h3>
                  <p className="project-description">
                    {project.description?.substring(0, 100)}
                    {project.description?.length > 100 ? '...' : ''}
                  </p>
                  <div className="project-meta">
                    <span className={`project-status status-${project.status?.toLowerCase()}`}>
                      {project.status}
                    </span>
                    <span>by {project.owner?.full_name}</span>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div style={{ textAlign: 'center', padding: '40px', color: '#6b7280' }}>
              <p>No projects available yet.</p>
              <Link to="/projects/new" className="btn btn-primary mt-4">
                Create the First Project
              </Link>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Dashboard;