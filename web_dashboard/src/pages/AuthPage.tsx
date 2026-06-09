import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { auth, db } from '../firebase';
import { signInWithEmailAndPassword, createUserWithEmailAndPassword, sendPasswordResetEmail } from 'firebase/auth';
import { doc, setDoc, serverTimestamp } from 'firebase/firestore';
import { motion, AnimatePresence } from 'framer-motion';
import { Mail, Lock, User, ArrowRight } from 'lucide-react';

export default function AuthPage() {
  const [isLogin, setIsLogin] = useState(true);
  const [isForgotPassword, setIsForgotPassword] = useState(false);
  
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [msg, setMsg] = useState('');
  
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(''); setMsg(''); setLoading(true);

    try {
      if (isForgotPassword) {
        if (!email) throw new Error('Please enter your email.');
        await sendPasswordResetEmail(auth, email);
        setMsg('Password reset link sent to your email.');
      } else if (isLogin) {
        await signInWithEmailAndPassword(auth, email, password);
        navigate('/');
      } else {
        if (!name) throw new Error('Please enter your name.');
        const cred = await createUserWithEmailAndPassword(auth, email, password);
        await setDoc(doc(db, 'users', cred.user.uid), {
          email,
          name,
          role: 'user', // default new signups to user
          createdAt: serverTimestamp()
        });
        navigate('/');
      }
    } catch (err: any) {
      setError(err.message || 'Authentication failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#090b10] flex items-center justify-center relative overflow-hidden p-4">
      {/* Background Neon Orbs */}
      <div className="absolute top-1/4 left-1/4 w-[400px] h-[400px] bg-[#00f3ff] rounded-full blur-[120px] opacity-20 animate-pulse"></div>
      <div className="absolute bottom-1/4 right-1/4 w-[500px] h-[500px] bg-[#9d00ff] rounded-full blur-[150px] opacity-10"></div>

      <motion.div 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
        className="w-full max-w-md relative z-10"
      >
        <div className="glass-panel rounded-3xl p-8 shadow-2xl relative overflow-hidden">
          
          <div className="flex flex-col items-center mb-10">
            <div className="w-24 h-24 rounded-full bg-white flex items-center justify-center shadow-[0_0_30px_rgba(0,243,255,0.4)] mb-6 overflow-hidden p-1">
              <img src="/logo.png" alt="BioMechAI Logo" className="w-full h-full object-contain" />
            </div>
            <h2 className="text-3xl font-bold text-white tracking-wide">
              {isForgotPassword ? 'Reset Password' : isLogin ? 'Welcome Back' : 'Create Account'}
            </h2>
            <p className="text-gray-400 mt-2 text-sm text-center">
              {isForgotPassword ? 'Enter your email to receive a recovery link' : isLogin ? 'Enter your details to access your dashboard' : 'Join BioMechAI to track your fitness journey'}
            </p>
          </div>

          <AnimatePresence mode="wait">
            {error && (
              <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} exit={{ opacity: 0, height: 0 }} className="bg-red-500/10 border border-red-500/30 text-red-400 p-3 rounded-xl mb-6 text-sm text-center">
                {error}
              </motion.div>
            )}
            {msg && (
              <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} exit={{ opacity: 0, height: 0 }} className="bg-[#00f3ff]/10 border border-[#00f3ff]/30 text-[#00f3ff] p-3 rounded-xl mb-6 text-sm text-center">
                {msg}
              </motion.div>
            )}
          </AnimatePresence>

          <form onSubmit={handleSubmit} className="space-y-5">
            <AnimatePresence>
              {!isLogin && !isForgotPassword && (
                <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} exit={{ opacity: 0, height: 0 }} className="relative">
                  <User className="absolute left-4 top-3.5 text-gray-400" size={20} />
                  <input type="text" placeholder="Full Name" value={name} onChange={e => setName(e.target.value)} className="w-full bg-black/40 border border-white/10 rounded-xl py-3 pl-12 pr-4 text-white focus:border-[#00f3ff] focus:shadow-[0_0_15px_rgba(0,243,255,0.2)] outline-none transition-all placeholder:text-gray-500" required />
                </motion.div>
              )}
            </AnimatePresence>

            <div className="relative">
              <Mail className="absolute left-4 top-3.5 text-gray-400" size={20} />
              <input type="email" placeholder="Email Address" value={email} onChange={e => setEmail(e.target.value)} className="w-full bg-black/40 border border-white/10 rounded-xl py-3 pl-12 pr-4 text-white focus:border-[#00f3ff] focus:shadow-[0_0_15px_rgba(0,243,255,0.2)] outline-none transition-all placeholder:text-gray-500" required />
            </div>

            <AnimatePresence>
              {!isForgotPassword && (
                <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} exit={{ opacity: 0, height: 0 }} className="relative">
                  <Lock className="absolute left-4 top-3.5 text-gray-400" size={20} />
                  <input type="password" placeholder="Password" value={password} onChange={e => setPassword(e.target.value)} className="w-full bg-black/40 border border-white/10 rounded-xl py-3 pl-12 pr-4 text-white focus:border-[#00f3ff] focus:shadow-[0_0_15px_rgba(0,243,255,0.2)] outline-none transition-all placeholder:text-gray-500" required />
                </motion.div>
              )}
            </AnimatePresence>

            {isLogin && !isForgotPassword && (
              <div className="flex justify-end">
                <button type="button" onClick={() => setIsForgotPassword(true)} className="text-xs text-[#00f3ff] hover:text-white transition-colors">Forgot Password?</button>
              </div>
            )}

            <button disabled={loading} type="submit" className="w-full btn-primary py-4 rounded-xl flex items-center justify-center gap-2 mt-4 text-lg disabled:opacity-50">
              {loading ? 'Processing...' : (isForgotPassword ? 'Send Link' : isLogin ? 'Sign In' : 'Create Account')}
              {!loading && <ArrowRight size={20} />}
            </button>
          </form>

          <div className="mt-8 text-center border-t border-white/5 pt-6">
            {isForgotPassword ? (
              <button onClick={() => setIsForgotPassword(false)} className="text-sm text-gray-400 hover:text-white transition-colors">
                Back to Sign In
              </button>
            ) : (
              <p className="text-sm text-gray-400">
                {isLogin ? "Don't have an account? " : "Already have an account? "}
                <button onClick={() => setIsLogin(!isLogin)} className="text-[#00f3ff] font-semibold hover:text-white transition-colors ml-1">
                  {isLogin ? 'Sign Up' : 'Sign In'}
                </button>
              </p>
            )}
          </div>

        </div>
      </motion.div>
    </div>
  );
}
