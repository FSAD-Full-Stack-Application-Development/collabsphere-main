import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { userService, authService } from '../apiService';

const EditProfile = () => {
  const [formData, setFormData] = useState({
    full_name: '',
    email: '',
    country: '',
    bio: '',
    university: '',
    department: '',
    tags: '',
  });
  const [tagInput, setTagInput] = useState('');
  const [tagList, setTagList] = useState([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const navigate = useNavigate();
  const currentUser = authService.getCurrentUser();

  useEffect(() => {
    const load = async () => {
      try {
        const profile = await userService.getProfile();
        const tagsArray = Array.isArray(profile.tags) ? profile.tags : (profile.tags ? String(profile.tags).split(',').map(t=>t.trim()).filter(Boolean) : []);
        setFormData({
          full_name: profile.full_name || '',
          email: profile.email || '',
          country: profile.country || '',
          bio: profile.bio || '',
          university: profile.university || '',
          department: profile.department || '',
          tags: tagsArray.join(', '),
        });
        setTagList(tagsArray);
      } catch (e) {
        setError('Failed to load profile');
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSaving(true);
    setError('');
    try {
      const payload = {
        ...formData,
        tags: tagList.length ? tagList : (formData.tags ? formData.tags.split(',').map(t => t.trim()).filter(Boolean) : []),
      };
      await userService.updateProfile(currentUser.id, payload);
      navigate('/dashboard');
    } catch (e) {
      setError(e.response?.data?.error || 'Failed to update profile');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (<div className="loading"><div className="spinner"></div></div>);
  }

  return (
    <div className="container">
      <div style={{ maxWidth: '600px', margin: '0 auto', paddingTop: '20px' }}>
        <div className="card">
          <div className="flex justify-between items-center mb-6">
            <h2>Edit Profile</h2>
            <button onClick={() => navigate('/dashboard')} className="btn btn-sm btn-outline">Cancel</button>
          </div>

          {error && <div className="alert alert-error">{error}</div>}

          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label className="form-label">Full Name</label>
              <input type="text" name="full_name" value={formData.full_name} onChange={handleChange} className="form-input" required />
            </div>

            <div className="form-group">
              <label className="form-label">Email</label>
              <input type="email" name="email" value={formData.email} onChange={handleChange} className="form-input" required />
            </div>

            <div className="form-group">
              <label className="form-label">Country</label>
              <input type="text" name="country" value={formData.country} onChange={handleChange} className="form-input" placeholder="e.g., Malaysia" />
            </div>

            <div className="form-group">
              <label className="form-label">Short Bio</label>
              <textarea name="bio" value={formData.bio} onChange={handleChange} className="form-textarea" placeholder="Tell us about yourself..." />
            </div>

            <div className="form-group">
              <label className="form-label">University</label>
              <input type="text" name="university" value={formData.university} onChange={handleChange} className="form-input" />
            </div>

            <div className="form-group">
              <label className="form-label">Department</label>
              <input type="text" name="department" value={formData.department} onChange={handleChange} className="form-input" />
            </div>

            <div className="form-group">
              <label className="form-label">Skills/Interest Tags</label>
              <div
                style={{ display: 'flex', flexWrap: 'wrap', gap: '8px', padding: '8px', border: '1px solid #e5e7eb', borderRadius: '6px' }}
                onClick={() => { const el = document.getElementById('edit-tag-input'); if (el) el.focus(); }}
              >
                {tagList.map((tag, idx) => (
                  <span key={idx} style={{ background: '#e5e7eb', borderRadius: '999px', padding: '4px 8px', display: 'inline-flex', alignItems: 'center', gap: '6px' }}>
                    {tag}
                    <button type="button" onClick={() => setTagList(tagList.filter((_, i) => i !== idx))} style={{ border: 'none', background: 'transparent', cursor: 'pointer', color: '#6b7280' }}>×</button>
                  </span>
                ))}
                <input
                  id="edit-tag-input"
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

            <div className="flex gap-3">
              <button type="submit" className="btn btn-primary" disabled={saving}>{saving ? 'Saving...' : 'Save Changes'}</button>
              <button type="button" className="btn btn-outline" onClick={() => navigate('/dashboard')}>Cancel</button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default EditProfile;
