import { createContext, useContext, useState, useEffect } from 'react';
import api from '../lib/api';

const AuthContext = createContext();

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  // Check if user is logged in on mount
  useEffect(() => {
    const initAuth = async () => {
      const token = localStorage.getItem('accessToken');
      if (token) {
        try {
          const res = await api.get('/auth/me');
          setUser(res.data.data);
        } catch (err) {
          console.error('Auth verification failed', err);
          localStorage.removeItem('accessToken');
          localStorage.removeItem('refreshToken');
        }
      }
      setLoading(false);
    };
    initAuth();
  }, []);

  const login = async (identifier, password) => {
    try {
      const res = await api.post('/auth/login', { identifier, password });
      const data = res.data.data;
      
      if (data.requires_2fa) {
        return { success: true, requires2FA: true, tfaToken: data.tfa_token };
      }
      
      const { access_token, refresh_token } = data;
      localStorage.setItem('accessToken', access_token);
      localStorage.setItem('refreshToken', refresh_token);
      
      // Fetch user profile immediately after login
      const userRes = await api.get('/auth/me', {
        headers: { Authorization: `Bearer ${access_token}` }
      });
      setUser(userRes.data.data);
      return { success: true };
    } catch (err) {
      return { 
        success: false, 
        error: err.response?.data?.error?.message || 'Login failed' 
      };
    }
  };

  const verify2FA = async (tfaToken, otp) => {
    try {
      const res = await api.post('/auth/verify-2fa', { tfa_token: tfaToken, otp });
      const { access_token, refresh_token } = res.data.data;
      
      localStorage.setItem('accessToken', access_token);
      localStorage.setItem('refreshToken', refresh_token);
      
      // Fetch user profile immediately after 2FA login verification
      const userRes = await api.get('/auth/me', {
        headers: { Authorization: `Bearer ${access_token}` }
      });
      setUser(userRes.data.data);
      return { success: true };
    } catch (err) {
      return {
        success: false,
        error: err.response?.data?.error?.message || 'Verification failed'
      };
    }
  };

  const logout = () => {
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ user, loading, login, logout, verify2FA }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
