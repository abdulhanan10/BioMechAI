import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { auth } from '../firebase';
import { sendPasswordResetEmail } from 'firebase/auth';
import { motion, AnimatePresence } from 'framer-motion';
import { Mail, ArrowRight, CheckCircle } from 'lucide-react';

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(''); setToastMessage(null); setLoading(true);

    try {
      if (!email) throw new Error('Please enter your email.');
      await sendPasswordResetEmail(auth, email);
      setToastMessage('Password reset link sent to your email.');
      setTimeout(() => setToastMessage(null), 3000);
    } catch (err: any) {
      setError(err.message || 'Failed to send reset link');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#090b10] flex items-center justify-center relative overflow-hidden p-4">
      {/* Toast Notification */}
      <AnimatePresence>
        {toastMessage && (
          <motion.div
            initial={{ opacity: 0, y: -20, scale: 0.9 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -20, scale: 0.9 }}
            className="fixed top-8 right-8 z-50 glass-panel border border-[#00f3ff]/30 shadow-[0_0_20px_rgba(0,243,255,0.2)] rounded-xl px-6 py-4 flex items-center gap-3"
          >
            <CheckCircle className="text-[#00f3ff]" size={24} />
            <span className="text-white font-medium">{toastMessage}</span>
          </motion.div>
        )}
      </AnimatePresence>

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
            <div className="w-28 h-28 rounded-full bg-[#090b10] flex items-center justify-center shadow-[0_0_30px_rgba(0,243,255,0.4)] mb-3 overflow-hidden border-2 border-[#00f3ff]/30">
              <img src="/logo.png" alt="BioMechAI Logo" className="w-full h-full object-cover scale-[1.05]" />
            </div>
            <h1 className="text-3xl font-bold tracking-wider text-white mb-6">
              BioMech<span className="text-[#00f3ff]">AI</span>
            </h1>
            <h2 className="text-xl font-medium text-gray-300">
              Reset Password
            </h2>
            <p className="text-gray-400 mt-2 text-sm text-center">
              Enter your email to receive a recovery link
            </p>
          </div>

          <AnimatePresence mode="wait">
            {error && (
              <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} exit={{ opacity: 0, height: 0 }} className="bg-red-500/10 border border-red-500/30 text-red-400 p-3 rounded-xl mb-6 text-sm text-center">
                {error}
              </motion.div>
            )}
          </AnimatePresence>

          <form onSubmit={handleSubmit} className="space-y-5">
            <div className="relative">
              <Mail className="absolute left-4 top-3.5 text-gray-400" size={20} />
              <input type="email" placeholder="Email Address" value={email} onChange={e => setEmail(e.target.value)} className="w-full bg-black/40 border border-white/10 rounded-xl py-3 pl-12 pr-4 text-white focus:border-[#00f3ff] focus:shadow-[0_0_15px_rgba(0,243,255,0.2)] outline-none transition-all placeholder:text-gray-500" required />
            </div>

            <button disabled={loading} type="submit" className="w-full btn-primary py-4 rounded-xl flex items-center justify-center gap-2 mt-4 text-lg disabled:opacity-50">
              {loading ? 'Processing...' : 'Send Link'}
              {!loading && <ArrowRight size={20} />}
            </button>
          </form>

          <div className="mt-8 text-center border-t border-white/5 pt-6">
            <Link to="/auth" className="text-sm text-gray-400 hover:text-white transition-colors">
              Back to Sign In
            </Link>
          </div>

        </div>
      </motion.div>
    </div>
  );
}
