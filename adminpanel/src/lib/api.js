const BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';
export const STATIC_BASE_URL = BASE_URL.split('/api')[0];

async function apiFetch(path, options = {}) {
  const token = localStorage.getItem('access_token');
  const headers = {
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...options.headers,
  };

  // Only set application/json if body is present and not FormData
  if (options.body && !(options.body instanceof FormData) && !headers['Content-Type']) {
    headers['Content-Type'] = 'application/json';
  }

  const res = await fetch(`${BASE_URL}${path}`, {
    ...options,
    headers,
  });
  if (!res.ok) {
    if (res.status === 401) {
      localStorage.removeItem('access_token');
      localStorage.removeItem('refresh_token');
      window.location.href = '/';
      return Promise.reject(new Error('Session expired'));
    }
    const errorJson = await res.json().catch(() => ({}));
    throw new Error(`API ${res.status}: ${path} - ${errorJson.message || 'Unknown Error'} (${errorJson.code || 'NO_CODE'})`);
  }
  const json = await res.json();
  return json.data;
}

export const api = {
  getAdminOverview: () => apiFetch('/admin/analytics/overview'),
  getCurrentUser: () => apiFetch('/auth/me'),
  listUsers: (params = {}) => apiFetch(`/admin/users?${new URLSearchParams(params)}`),
  listIndustryCategories: () => apiFetch('/industry-categories'),
  listIndustries: () => apiFetch('/admin/industries'),
  listReferrals: () => apiFetch('/referrals/my/given'),
  listAllReferrals: (params = {}) => {
    const qs = new URLSearchParams();
    if (params.page) qs.append('page', params.page);
    if (params.limit) qs.append('page_size', params.limit);
    if (params.search) qs.append('search', params.search);
    if (params.status) qs.append('status', params.status);
    return apiFetch(`/admin/referrals?${qs.toString()}`).catch(() => apiFetch('/referrals/my/given'));
  },
  listPayments: (params = {}) => apiFetch(`/admin/payments?${new URLSearchParams(params)}`),
  recordPayment: (body) => apiFetch('/admin/payments', {
    method: 'POST',
    body: JSON.stringify(body),
  }),
  updatePayment: (id, body) => apiFetch(`/admin/payments/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(body),
  }),
  exportData: () => apiFetch('/admin/export'),

  // Applications
  listApplications: (params = {}) => apiFetch(`/applications?${new URLSearchParams(params)}`),
  getApplication: (id) => apiFetch(`/applications/${id}`),
  updateApplicationStatus: (id, body) =>
    apiFetch(`/applications/${id}/status`, {
      method: 'PATCH',
      body: JSON.stringify(body),
    }),
  createApplication: (body) =>
    apiFetch('/applications', {
      method: 'POST',
      body: JSON.stringify(body),
    }),
  deleteApplication: (id) => apiFetch(`/applications/${id}`, {
    method: 'DELETE',
  }),

  // Admin Auth
  adminLogin: async (username, password) => {
    const res = await fetch(`${BASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ identifier: username, password }),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || `Login failed (${res.status})`);
    }
    const json = await res.json();
    return json.data;
  },

  // Chapters
  listChapters: () => apiFetch('/chapters'),
  getOccupiedIndustries: (chapterId) => apiFetch(`/chapters/${chapterId}/occupied-industries`),

  // Users
  updateUser: (id, body) => apiFetch(`/admin/users/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(body),
  }),
  removeUserFromChapter: (id) => apiFetch(`/admin/users/${id}/chapter`, {
    method: 'DELETE',
  }),


  changePassword: (body) => apiFetch('/auth/change-password', {
    method: 'PUT',
    body: JSON.stringify(body),
  }),

  // Rewards & Partners
  listPartners: (activeOnly = false) => apiFetch(`/rewards/partners?active_only=${activeOnly}`),
  createPartner: (body) => apiFetch('/rewards/partners', {
    method: 'POST',
    body: JSON.stringify(body),
  }),
  updatePartner: (id, body) => apiFetch(`/rewards/partners/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(body),
  }),
  uploadPartnerLogo: (file) => {
    const formData = new FormData();
    formData.append('file', file);
    return apiFetch('/rewards/partners/upload-logo', {
      method: 'POST',
      body: formData,
      headers: {}, // Remove default JSON Content-Type
    }, true); // Use raw body for FormData
  },
  createOffer: (partnerId, body) => apiFetch(`/rewards/partners/${partnerId}/offers`, {
    method: 'POST',
    body: JSON.stringify(body),
  }),
  // Notifications
  listNotifications: () => apiFetch('/notifications'),
  getUnreadCount: () => apiFetch('/notifications/unread-count'),
  markNotificationRead: (id) => apiFetch(`/notifications/${id}/read`, { method: 'PATCH' }),
  markAllNotificationsRead: () => apiFetch('/notifications/read-all', { method: 'PATCH' }),
  deleteNotification: (id) => apiFetch(`/notifications/${id}`, { method: 'DELETE' }),

  // Events
  listEvents: (params = {}) => apiFetch(`/events?${new URLSearchParams(params)}`),
  createEvent: (body) => apiFetch('/events', {
    method: 'POST',
    body: JSON.stringify(body),
  }),
  updateEvent: (id, body) => apiFetch(`/events/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(body),
  }),
  uploadEventImage: (file) => {
    const formData = new FormData();
    formData.append('file', file);
    return apiFetch('/events/upload-image', {
      method: 'POST',
      body: formData,
      headers: {},
    }, true);
  },
  approveRsvp: (eventId, body) => apiFetch(`/events/${eventId}/approve`, {
    method: 'POST',
    body: JSON.stringify(body),
  }),

  // Horizontal Clubs
  listClubs: () => apiFetch('/horizontal-clubs'),
  createClub: (body) => apiFetch('/admin/clubs', {
    method: 'POST',
    body: JSON.stringify(body),
  }),
  updateClub: (id, body) => apiFetch(`/admin/clubs/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(body),
  }),
  deleteClub: (id) => apiFetch(`/admin/clubs/${id}`, {
    method: 'DELETE',
  }),
  listFees: () => apiFetch('/admin/fees'),
  updateFee: (mType, body) => apiFetch(`/admin/fees/${mType}`, {
    method: 'PATCH',
    body: JSON.stringify(body),
  }),

  // Marketplace
  listMarketplaceListings: (params = {}) => apiFetch(`/marketplace?${new URLSearchParams(params)}`),
  updateMarketplaceListing: (id, body) => apiFetch(`/marketplace/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(body),
  }),
  deleteMarketplaceListing: (id) => apiFetch(`/marketplace/${id}`, {
    method: 'DELETE',
  }),
  featureMarketplaceListing: (id, isFeatured) => apiFetch(`/marketplace/${id}`, {
    method: 'PATCH',
    body: JSON.stringify({ is_featured: isFeatured }),
  }),
  listMarketplaceInterests: (listingId) => apiFetch(`/marketplace/${listingId}/interests`),
};
