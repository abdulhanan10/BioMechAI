import React, { useState, useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate, useLocation } from 'react-router-dom';
import { auth } from './firebase';
import { onAuthStateChanged } from 'firebase/auth';
import { AnimatePresence, motion } from 'framer-motion';

import Sidebar from './components/Sidebar';
import AuthPage from './pages/AuthPage';
import DashboardHome from './pages/DashboardHome';
import ClientListPage from './pages/ClientListPage';
import ClientDetailPage from './pages/ClientDetailPage';
import SessionDetailPage from './pages/SessionDetailPage';
import ProfilePage from './pages/ProfilePage';

// Layout wrapper for authenticated pages
function Layout({ children }: { children: React.ReactNode }) {
  const location = useLocation();
  
  return (
    <div className="flex flex-col md:flex-row min-h-screen bg-[#090b10] overflow-hidden">
      <Sidebar />
      <div className="flex-1 overflow-y-auto relative">
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
