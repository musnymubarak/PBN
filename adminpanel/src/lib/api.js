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
  if (!res.ok) throw new Error(`API ${res.status}: ${path}`);
  const json = await res.json();
  return json.data;
}

export const api = {
  getAdminOverview: () => apiFetch('/admin/analytics/overview'),
  listUsers: (params = {}) => apiFetch(`/admin/users?${new URLSearchParams(params)}`),
  listReferrals: () => apiFetch('/referrals/my/given'),
  listPayments: () => apiFetch('/admin/payments'),
  exportData: () => apiFetch('/admin/export'),
};
