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
    const friendlyMessage = errorJson.message || errorJson.error || 'Unknown Error';
    const err = new Error(friendlyMessage);
    err.status = res.status;
    err.code = errorJson.code || 'NO_CODE';
    err.path = path;
    err.details = `API ${res.status}: ${path} - ${friendlyMessage} (${err.code})`;
    throw err;
  }
  const contentType = res.headers.get('Content-Type');
  if (contentType && (contentType.includes('text/csv') || contentType.includes('application/octet-stream'))) {
    return await res.blob();
  }
  
  const json = await res.json();
  return json.data;
}

export const api = {
  getAdminOverview: () => apiFetch('/admin/analytics/overview'),
  getAdminTimeseries: (params = {}) => apiFetch(`/admin/analytics/timeseries?${new URLSearchParams(params)}`),
  getCurrentUser: () => apiFetch('/auth/me'),
  listUsers: (params = {}) => apiFetch(`/admin/users?${new URLSearchParams(params)}`),
  listStaff: (params = {}) => apiFetch(`/admin/staff?${new URLSearchParams(params)}`),
  createStaff: (body) => apiFetch('/admin/staff', { method: 'POST', body: JSON.stringify(body) }),
  deleteStaff: (id) => apiFetch(`/admin/staff/${id}`, { method: 'DELETE' }),
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
  patchApplication: (id, body) => apiFetch(`/applications/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(body),
  }),
  updateApplicationStatus: (id, body) =>
    apiFetch(`/applications/${id}/status`, {
      method: 'PATCH',
      body: JSON.stringify(body),
    }),
  updatePaymentStatus: (appId, status) =>
    apiFetch(`/admin/applications/${appId}/payment-status`, { method: 'PATCH', body: JSON.stringify({ payment_status: status }) }),

  // ── Rewards / Privilege Cards Admin API ──
  listPrivilegeCards: (filters = {}) => {
    const q = new URLSearchParams();
    if (filters.status) q.append('status', filters.status);
    if (filters.chapter_id) q.append('chapter_id', filters.chapter_id);
    return apiFetch(`/admin/cards?${q.toString()}`);
  },
  issuePrivilegeCard: (data) =>
    apiFetch('/admin/cards/issue', { method: 'POST', body: JSON.stringify(data) }),
  updatePrivilegeCard: (cardId, data) =>
    apiFetch(`/admin/cards/${cardId}`, { method: 'PATCH', body: JSON.stringify(data) }),
  suspendPrivilegeCard: (cardId) =>
    apiFetch(`/admin/cards/${cardId}/suspend`, { method: 'POST' }),
  replacePrivilegeCard: (cardId) =>
    apiFetch(`/admin/cards/${cardId}/replace`, { method: 'POST' }),
  exportPrivilegeCards: () =>
    apiFetch('/admin/cards/export'),

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
  listChapters: (params = { active_only: false }) => apiFetch(`/chapters?${new URLSearchParams(params)}`),
  createChapter: (body) => apiFetch('/chapters', {
    method: 'POST',
    body: JSON.stringify(body),
  }),
  updateChapter: (id, body) => apiFetch(`/chapters/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(body),
  }),
  deleteChapter: (id) => apiFetch(`/chapters/${id}`, {
    method: 'DELETE',
  }),
  getOccupiedIndustries: (chapterId) => apiFetch(`/chapters/${chapterId}/occupied-industries`),
  uploadChapterPoster: (chapterId, file) => {
    const formData = new FormData();
    formData.append('file', file);
    return apiFetch(`/chapters/${chapterId}/upload-poster`, {
      method: 'POST',
      body: formData,
      headers: {},
    }, true);
  },

  // Users
  getMemberProfile: (id) => apiFetch(`/admin/users/${id}/profile`),
  updateUser: (id, body) => apiFetch(`/admin/users/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(body),
  }),
  removeUserFromChapter: (id) => apiFetch(`/admin/users/${id}/chapter`, {
    method: 'DELETE',
  }),
  deleteUser: (id) => apiFetch(`/admin/users/${id}`, {
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

  // Home Slides (dynamic home carousel)
  listHomeSlides: () => apiFetch('/admin/home/slides'),
  createHomeSlide: (body) => apiFetch('/admin/home/slides', {
    method: 'POST',
    body: JSON.stringify(body),
  }),
  updateHomeSlide: (id, body) => apiFetch(`/admin/home/slides/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(body),
  }),
  deleteHomeSlide: (id) => apiFetch(`/admin/home/slides/${id}`, {
    method: 'DELETE',
  }),
  reorderHomeSlides: (orderedIds) => apiFetch('/admin/home/slides/reorder', {
    method: 'POST',
    body: JSON.stringify({ ordered_ids: orderedIds }),
  }),
  uploadHomeSlideImage: (file) => {
    const formData = new FormData();
    formData.append('file', file);
    return apiFetch('/admin/home/slides/upload-image', {
      method: 'POST',
      body: formData,
      headers: {},
    }, true);
  },

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
  adminListMarketplaceListings: (params = {}) => apiFetch(`/admin/marketplace/listings?${new URLSearchParams(params)}`),
  approveMarketplaceListing: (id) => apiFetch(`/admin/marketplace/listings/${id}/approve`, { method: 'PATCH' }),
  rejectMarketplaceListing: (id, reason) => apiFetch(`/admin/marketplace/listings/${id}/reject`, {
    method: 'PATCH',
    body: JSON.stringify({ reason }),
  }),
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

  listPrivilegeCardHistory: (cardId) => apiFetch(`/admin/cards/${cardId}/history`),

  // Complements (admin)
  listComplements: (params = {}) => {
    const qs = new URLSearchParams();
    Object.entries(params).forEach(([k, v]) => {
      if (v !== undefined && v !== null && v !== '') qs.append(k, v);
    });
    return apiFetch(`/admin/complements?${qs.toString()}`);
  },
  updateComplementStatus: (id, body) => apiFetch(`/admin/complements/${id}/status`, {
    method: 'PATCH',
    body: JSON.stringify(body),
  }),
  listComplementTypes: (activeOnly = true) =>
    apiFetch(`/admin/complement-types?active_only=${activeOnly}`),
  createComplementType: (body) => apiFetch('/admin/complement-types', {
    method: 'POST',
    body: JSON.stringify(body),
  }),

  // Onboarding (public; token-authenticated)
  getOnboardingStatus: (token) => apiFetch(`/applications/onboard/${encodeURIComponent(token)}`),
  patchOnboardingDetails: (token, body) => apiFetch(`/applications/onboard/${encodeURIComponent(token)}/details`, {
    method: 'PATCH',
    body: JSON.stringify(body),
  }),
  submitOnboardingTshirt: (token, size) => apiFetch(`/applications/onboard/${encodeURIComponent(token)}/tshirt`, {
    method: 'POST',
    body: JSON.stringify({ size }),
  }),

  // Audit Logs (SUPER_ADMIN only)
  listAuditLogs: (params = {}) => {
    const qs = new URLSearchParams();
    Object.entries(params).forEach(([k, v]) => {
      if (v !== undefined && v !== null && v !== '') qs.append(k, v);
    });
    return apiFetch(`/admin/audit-logs?${qs.toString()}`);
  },
  getAuditLogFacets: () => apiFetch('/admin/audit-logs/facets'),

  // Mailbox Viewer
  listMailbox: (folder = 'INBOX') => apiFetch(`/admin/mailbox?folder=${encodeURIComponent(folder)}`),
  getMailboxEmail: (uid, folder = 'INBOX') => apiFetch(`/admin/mailbox/${uid}?folder=${encodeURIComponent(folder)}`),
  sendMailboxEmail: (body) => apiFetch('/admin/mailbox/send', { method: 'POST', body: JSON.stringify(body) }),

  // Mailbox Settings (SUPER_ADMIN only)
  getMailboxSettings: () => apiFetch('/admin/mailbox-settings'),
  updateMailboxSettings: (body) => apiFetch('/admin/mailbox-settings', { method: 'PATCH', body: JSON.stringify(body) }),

  // Community & Leads (admin)
  getCommunityStats: (days = 30) => apiFetch(`/admin/community/stats?days=${days}`),
  listCommunityLeads: (params = {}) => {
    const qs = new URLSearchParams();
    Object.entries(params).forEach(([k, v]) => {
      if (v !== undefined && v !== null && v !== '') qs.append(k, v);
    });
    return apiFetch(`/admin/community/leads?${qs.toString()}`);
  },
  listCommunityPosts: (params = {}) => {
    const qs = new URLSearchParams();
    Object.entries(params).forEach(([k, v]) => {
      if (v !== undefined && v !== null && v !== '') qs.append(k, v);
    });
    return apiFetch(`/admin/community/posts?${qs.toString()}`);
  },
  getCommunityPost: (id) => apiFetch(`/admin/community/posts/${id}`),
  updateCommunityLeadStatus: (id, status) =>
    apiFetch(`/admin/community/posts/${id}/status`, { method: 'PATCH', body: JSON.stringify({ status }) }),
  recordCommunityTyfb: (id, business_value) =>
    apiFetch(`/admin/community/posts/${id}/tyfb`, { method: 'PATCH', body: JSON.stringify({ business_value }) }),
  deleteCommunityPost: (id) => apiFetch(`/admin/community/posts/${id}`, { method: 'DELETE' }),
  deleteCommunityComment: (id) => apiFetch(`/admin/community/comments/${id}`, { method: 'DELETE' }),

  // Payment Proofs
  listPaymentProofs: (status = '') => {
    const qs = status ? `?status=${status}` : '';
    return apiFetch(`/admin/payment-proofs${qs}`);
  },
  approvePaymentProof: (id, notes) => apiFetch(`/admin/payment-proofs/${id}/approve`, {
    method: 'POST',
    body: JSON.stringify({ notes }),
  }),
  rejectPaymentProof: (id, notes) => apiFetch(`/admin/payment-proofs/${id}/reject`, {
    method: 'POST',
    body: JSON.stringify({ notes }),
  }),
};
