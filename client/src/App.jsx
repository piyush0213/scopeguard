import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth, homeFor } from './context/AuthContext.jsx';
import { Protected, FullSpinner } from './components/Layout.jsx';
import { Login, Register } from './pages/Auth.jsx';
import NewProject from './pages/client/NewProject.jsx';
import Orders from './pages/client/Orders.jsx';
import ClientOrderWorkspace from './pages/client/OrderWorkspace.jsx';
import DevDashboard from './pages/dev/Dashboard.jsx';
import DevWorkspace from './pages/dev/DevWorkspace.jsx';

function Home() {
  const { user, loading } = useAuth();
  if (loading) return <FullSpinner />;
  return <Navigate to={user ? homeFor(user) : '/login'} replace />;
}

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          <Route path="/client" element={<Protected role="client" />}>
            <Route index element={<Navigate to="new" replace />} />
            <Route path="new" element={<NewProject />} />
            <Route path="menu" element={<Navigate to="/client/new" replace />} />
            <Route path="scope" element={<Navigate to="/client/new" replace />} />
            <Route path="orders" element={<Orders />} />
            <Route path="orders/:id" element={<ClientOrderWorkspace />} />
          </Route>
          <Route path="/dev" element={<Protected role="dev" />}>
            <Route index element={<Navigate to="dashboard" replace />} />
            <Route path="dashboard" element={<DevDashboard />} />
            <Route path="orders/:id" element={<DevWorkspace />} />
          </Route>
          <Route path="*" element={<Home />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}
