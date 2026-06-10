import React, { useState, useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate, useLocation } from 'react-router-dom';
import { auth } from './firebase';
import { onAuthStateChanged } from 'firebase/auth';
import { AnimatePresence, motion } from 'framer-motion';
import { Menu } from 'lucide-react';

import Sidebar from './components/Sidebar';
import AuthPage from './pages/AuthPage';
import ForgotPasswordPage from './pages/ForgotPasswordPage';
import DashboardHome from './pages/DashboardHome';
import ClientListPage from './pages/ClientListPage';
import ClientDetailPage from './pages/ClientDetailPage';
import SessionDetailPage from './pages/SessionDetailPage';
import ProfilePage from './pages/ProfilePage';

// Layout wrapper for authenticated pages
function Layout({ children }: { children: React.ReactNode }) {
  const location = useLocation();
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);

  // Close sidebar on navigation on mobile
  useEffect(() => {
    setIsSidebarOpen(false);
  }, [location]);
  
  return (
    <div className="flex flex-col md:flex-row min-h-screen bg-[#090b10] overflow-hidden">
      {/* Mobile Top Bar */}
      <div className="md:hidden flex items-center justify-between p-4 glass-panel border-b border-white/5 relative z-30">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-full bg-[#090b10] flex items-center justify-center shadow-[0_0_10px_rgba(0,243,255,0.3)] overflow-hidden border border-[#00f3ff]/30">
            <img src="/logo.png" alt="Logo" className="w-full h-full object-cover scale-[1.05]" />
          </div>
          <h1 className="text-lg font-bold tracking-wider text-white">
            BioMech<span className="text-[#00f3ff]">AI</span>
          </h1>
        </div>
        <button onClick={() => setIsSidebarOpen(true)} className="text-gray-300 hover:text-white p-2">
          <Menu size={26} />
        </button>
      </div>

      {/* Overlay for mobile */}
      {isSidebarOpen && (
        <div 
          className="fixed inset-0 bg-black/60 backdrop-blur-sm z-40 md:hidden" 
          onClick={() => setIsSidebarOpen(false)}
        />
      )}

      {/* Sidebar Container */}
      <div className={`fixed inset-y-0 left-0 z-50 transform ${isSidebarOpen ? 'translate-x-0' : '-translate-x-full'} md:relative md:translate-x-0 transition-transform duration-300 ease-in-out`}>
        <Sidebar onClose={() => setIsSidebarOpen(false)} />
      </div>

      <div className="flex-1 overflow-y-auto relative h-[calc(100vh-73px)] md:h-screen">
        <AnimatePresence mode="wait">
          <motion.div
            key={location.pathname}
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            transition={{ duration: 0.3 }}
            className="w-full h-full"
          >
            {children}
          </motion.div>
        </AnimatePresence>
      </div>
    </div>
  );
}

// Protected Route wrapper
function ProtectedRoute({ children, user, loading }: { children: React.ReactNode, user: any, loading: boolean }) {
  if (loading) return <div className="min-h-screen bg-[#090b10] flex items-center justify-center"><div className="w-12 h-12 border-4 border-[#00f3ff] border-t-transparent rounded-full animate-spin"></div></div>;
  if (!user) return <Navigate to="/auth" />;
  return <Layout>{children}</Layout>;
}

export default function App() {
  const [currentUser, setCurrentUser] = useState<any | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (user) => {
      setCurrentUser(user);
      setLoading(false);
    });
    return () => unsubscribe();
  }, []);

  return (
    <BrowserRouter>
      <Routes>
        <Route path="/auth" element={currentUser && !loading ? <Navigate to="/" /> : <AuthPage />} />
        <Route path="/forgot-password" element={currentUser && !loading ? <Navigate to="/" /> : <ForgotPasswordPage />} />
        
        <Route path="/" element={
          <ProtectedRoute user={currentUser} loading={loading}>
            <DashboardHome />
          </ProtectedRoute>
        } />
        
        <Route path="/clients" element={
          <ProtectedRoute user={currentUser} loading={loading}>
            <ClientListPage />
          </ProtectedRoute>
        } />
        
        <Route path="/client/:uid" element={
          <ProtectedRoute user={currentUser} loading={loading}>
            <ClientDetailPage />
          </ProtectedRoute>
        } />

        <Route path="/session/:sessionId" element={
          <ProtectedRoute user={currentUser} loading={loading}>
            <SessionDetailPage />
          </ProtectedRoute>
        } />
        
        <Route path="/profile" element={
          <ProtectedRoute user={currentUser} loading={loading}>
            <ProfilePage />
          </ProtectedRoute>
        } />

        <Route path="*" element={<Navigate to="/" />} />
      </Routes>
    </BrowserRouter>
  );
}
