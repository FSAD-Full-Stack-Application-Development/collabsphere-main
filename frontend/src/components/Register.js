import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { authService } from '../apiService';

const Register = () => {
  const [formData, setFormData] = useState({
    full_name: '',
    email: '',
    password: '',
    country: '',
    bio: '',
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const navigate = useNavigate();

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      await authService.register(formData);
      // Redirect to profile completion page
      navigate('/profile-completion');
    } catch (error) {
      const errorMessage = error.response?.data?.errors 
        ? error.response.data.errors.join(', ')
        : error.response?.data?.error || 'Registration failed';
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="container" style={{ paddingTop: '40px', paddingBottom: '60px' }}>
      <div style={{ maxWidth: '580px', margin: '0 auto' }}>
        <div className="card" style={{ padding: '40px' }}>
          <div style={{ textAlign: 'center', marginBottom: '32px' }}>
            <div style={{ 
              width: '64px', 
              height: '64px', 
              margin: '0 auto 20px',
              background: 'var(--gradient-main)',
              borderRadius: '16px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: '32px',
              color: 'white',
              fontWeight: 'bold',
              boxShadow: 'var(--shadow-md)'
            }}>
              C
            </div>
            <h2 style={{ marginBottom: '8px' }}>
              Create Your Account
            </h2>
            <p style={{ color: 'var(--text-light)', fontSize: '15px', margin: 0 }}>
              <span className="badge badge-primary" style={{ marginRight: '8px' }}>Step 1 of 2</span>
              Basic Information
            </p>
          </div>

          {error && (
            <div className="alert alert-error" style={{ marginBottom: '24px' }}>
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label className="form-label">Full Name *</label>
              <input
                type="text"
                name="full_name"
                value={formData.full_name}
                onChange={handleChange}
                className="form-input"
                placeholder="John Doe"
                required
                autoFocus
              />
            </div>

            <div className="form-group">
              <label className="form-label">Email Address *</label>
              <input
                type="email"
                name="email"
                value={formData.email}
                onChange={handleChange}
                className="form-input"
                placeholder="you@example.com"
                required
                autoComplete="email"
              />
            </div>

            <div className="form-group">
              <label className="form-label">Password *</label>
              <input
                type="password"
                name="password"
                value={formData.password}
                onChange={handleChange}
                className="form-input"
                placeholder="Minimum 6 characters"
                minLength={6}
                required
                autoComplete="new-password"
              />
              <small style={{ color: 'var(--text-light)', fontSize: '13px', display: 'block', marginTop: '4px' }}>
                Use at least 6 characters with a mix of letters and numbers
              </small>
            </div>

            <div className="form-group">
              <label className="form-label">Country (Optional)</label>
              <input
                type="text"
                name="country"
                value={formData.country}
                onChange={handleChange}
                className="form-input"
                placeholder="e.g., Malaysia, Singapore"
              />
            </div>

            <div className="form-group">
              <label className="form-label">Short Bio (Optional)</label>
              <textarea
                name="bio"
                value={formData.bio}
                onChange={handleChange}
                className="form-textarea"
                placeholder="Tell us a bit about yourself and your interests..."
                rows="4"
              />
            </div>

            <button
              type="submit"
              className="btn btn-primary"
              style={{ width: '100%', marginTop: '8px' }}
              disabled={loading}
            >
              {loading ? (
                <span style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}>
                  <div className="spinner" style={{ width: '16px', height: '16px', border: '2px solid white', borderTopColor: 'transparent' }}></div>
                  Creating Account...
                </span>
              ) : 'Continue to Profile Setup →'}
            </button>
          </form>

          <div className="divider"></div>

          <div style={{ textAlign: 'center' }}>
            <p style={{ color: 'var(--text-medium)', fontSize: '15px', margin: 0 }}>
              Already have an account?{' '}
              <Link to="/login" style={{ 
                color: 'var(--accent-gold)', 
                fontWeight: '600',
                textDecoration: 'none',
                transition: 'var(--transition-smooth)'
              }}>
                Sign in instead
              </Link>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Register;