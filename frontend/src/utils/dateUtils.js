// Date utility functions for displaying relative time

export const getRelativeTime = (dateString) => {
  if (!dateString) return '';
  
  const date = new Date(dateString);
  const now = new Date();
  const seconds = Math.floor((now - date) / 1000);
  
  // Handle future dates
  if (seconds < 0) return 'just now';
  
  // Less than a minute
  if (seconds < 60) return 'just now';
  
  // Minutes
  if (seconds < 3600) {
    const minutes = Math.floor(seconds / 60);
    return `${minutes} ${minutes === 1 ? 'minute' : 'minutes'} ago`;
  }
  
  // Hours
  if (seconds < 86400) {
    const hours = Math.floor(seconds / 3600);
    return `${hours} ${hours === 1 ? 'hour' : 'hours'} ago`;
  }
  
  // Days
  if (seconds < 604800) {
    const days = Math.floor(seconds / 86400);
    return `${days} ${days === 1 ? 'day' : 'days'} ago`;
  }
  
  // Weeks
  if (seconds < 2592000) {
    const weeks = Math.floor(seconds / 604800);
    return `${weeks} ${weeks === 1 ? 'week' : 'weeks'} ago`;
  }
  
  // Months
  if (seconds < 31536000) {
    const months = Math.floor(seconds / 2592000);
    return `${months} ${months === 1 ? 'month' : 'months'} ago`;
  }
  
  // Years
  const years = Math.floor(seconds / 31536000);
  return `${years} ${years === 1 ? 'year' : 'years'} ago`;
};

export const formatDate = (dateString) => {
  if (!dateString) return '';
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  });
};
