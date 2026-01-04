import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { userService, authService } from '../apiService';

const ProfileCompletion = () => {
  const [formData, setFormData] = useState({
    country: '',
    university: '',
    department: '',
    tags: '',
    bio: '',
  });
  const [tagInput, setTagInput] = useState('');
  const [tagList, setTagList] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const navigate = useNavigate();
  const currentUser = authService.getCurrentUser();

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
    setSuccess('');

    try {
      // Prefer chip list if present, else split by commas
      const tagsArray = tagList.length
        ? tagList
        : (formData.tags ? formData.tags.split(',').map(tag => tag.trim()).filter(Boolean) : []);

      const profileData = {
        ...formData,
        tags: tagsArray,
      };

      await userService.updateProfile(currentUser.id, profileData);
      setSuccess('Profile completed successfully!');
      
      // Redirect to dashboard after a short delay
      setTimeout(() => {
        navigate('/dashboard');
      }, 2000);
    } catch (error) {
      const errorMessage = error.response?.data?.errors 
        ? error.response.data.errors.join(', ')
        : error.response?.data?.error || 'Profile update failed';
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const handleSkip = () => {
    navigate('/dashboard');
  };

  return (
    <div className="container">
      <div style={{ maxWidth: '500px', margin: '0 auto', paddingTop: '40px' }}>
        <div className="card">
          <h2 style={{ textAlign: 'center', marginBottom: '8px' }}>
            Complete Your Profile
          </h2>
          <p style={{ textAlign: 'center', color: '#6b7280', marginBottom: '24px' }}>
            Stage 2: Optional profile details (you can skip this)
          </p>

          {error && (
            <div className="alert alert-error">
              {error}
            </div>
          )}

          {success && (
            <div className="alert alert-success">
              {success}
            </div>
          )}

          <form onSubmit={handleSubmit}>
            {/* Country */}
            <div className="form-group">
              <label className="form-label">Country</label>
              <input
                type="text"
                name="country"
                value={formData.country}
                onChange={handleChange}
                className="form-input"
                placeholder="e.g., Malaysia"
              />
            </div>

            {/* University */}
            <div className="form-group">
              <label className="form-label">University</label>
              <input
                type="text"
                name="university"
                value={formData.university}
                onChange={handleChange}
                className="form-input"
                placeholder="e.g., Sunway University"
              />
            </div>

            {/* Department */}
            <div className="form-group">
              <label className="form-label">Department</label>
              <input
                type="text"
                name="department"
                value={formData.department}
                onChange={handleChange}
                className="form-input"
                placeholder="e.g., Computer Science"
              />
            </div>

            {/* Bio */}
            <div className="form-group">
              <label className="form-label">Bio</label>
              <textarea
                name="bio"
                value={formData.bio}
                onChange={handleChange}
                className="form-input"
                placeholder="Tell us a bit about yourself"
                rows={4}
              />
            </div>

            {/* Skills/Interest Tags (Chip Input) */}
            <div className="form-group">
              <label className="form-label">Skills/Interest Tags</label>
              <div
                style={{
                  display: 'flex',
                  flexWrap: 'wrap',
                  gap: '8px',
                  padding: '8px',
                  border: '1px solid #e5e7eb',
                  borderRadius: '6px',
                }}
                onClick={() => {
                  const el = document.getElementById('tag-input');
                  if (el) el.focus();
                }}
              >
                {tagList.map((tag, idx) => (
                  <span key={idx} style={{ background: '#e5e7eb', borderRadius: '999px', padding: '4px 8px', display: 'inline-flex', alignItems: 'center', gap: '6px' }}>
                    {tag}
                    <button type="button" onClick={() => setTagList(tagList.filter((_, i) => i !== idx))} style={{ border: 'none', background: 'transparent', cursor: 'pointer', color: '#6b7280' }}>×</button>
                  </span>
                ))}
                <input
                  id="tag-input"
                  type="text"
                  value={tagInput}
                  onChange={(e) => setTagInput(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' || e.key === ',') {
                      e.preventDefault();
                      const val = tagInput.trim().replace(/,$/, '');
                      if (val && !tagList.includes(val)) setTagList([...tagList, val]);
                      setTagInput('');
                    }
                    if (e.key === 'Backspace' && !tagInput && tagList.length) {
                      setTagList(tagList.slice(0, -1));
                    }
                  }}
                  placeholder="Type a tag and press Enter"
                  style={{ border: 'none', outline: 'none', flex: 1, minWidth: '160px' }}
                />
              </div>
            </div>

            <div className="flex gap-4">
              <button
                type="submit"
                className="btn btn-primary"
                style={{ flex: 1 }}
                disabled={loading}
              >
                {loading ? 'Saving...' : 'Complete Profile'}
              </button>
              
              <button
                type="button"
                onClick={handleSkip}
                className="btn btn-outline"
                style={{ flex: 1 }}
                disabled={loading}
              >
                Skip for Now
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default ProfileCompletion;