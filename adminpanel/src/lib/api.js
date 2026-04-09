const BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

async function apiFetch(path, options = {}) {
  const token = localStorage.getItem('access_token');
  const res = await fetch(`${BASE_URL}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
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
  listUsers: (params = {}) => apiFetch(`/admin/users?${new URLSearchParams(params)}`),
  listIndustries: () => apiFetch('/admin/industries'),
  listReferrals: () => apiFetch('/referrals/my/given'),
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

  // Users
  updateUser: (id, body) => apiFetch(`/admin/users/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(body),
  }),
};
