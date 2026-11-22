import { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { api, getToken, setToken } from '../lib/api.js';
import { closeSocket } from '../lib/socket.js';

const AuthCtx = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(!!getToken());

  useEffect(() => {
    if (!getToken()) return;
    // Only a real 401 logs you out; a server restart or network blip retries instead.
    let cancelled = false;
    const load = (attempt = 0) =>
      api('/api/auth/me')
        .then((d) => !cancelled && setUser(d.user))
        .catch((e) => {
          if (cancelled) return;
          if (e.status === 401) return setToken(null);
          if (attempt < 20) return new Promise((r) => setTimeout(r, 1500)).then(() => load(attempt + 1));
        })
        .finally(() => !cancelled && setLoading(false));
    load();
    return () => {
      cancelled = true;
    };
  }, []);

  const finish = useCallback(({ token, user }) => {
    closeSocket();
    setToken(token);
    setUser(user);
    return user;
  }, []);

  const login = (email, password) => api('/api/auth/login', { method: 'POST', body: { email, password } }).then(finish);
  const register = (form) => api('/api/auth/register', { method: 'POST', body: form }).then(finish);
  const logout = () => {
    closeSocket();
    setToken(null);
    setUser(null);
  };

  return <AuthCtx.Provider value={{ user, loading, login, register, logout }}>{children}</AuthCtx.Provider>;
}

export const useAuth = () => useContext(AuthCtx);
export const homeFor = (user) => (user?.role === 'dev' ? '/dev/dashboard' : '/client/new');
