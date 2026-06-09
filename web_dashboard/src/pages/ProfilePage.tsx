import React, { useState, useEffect } from 'react';
import { db, auth } from '../firebase';
import { doc, getDoc, updateDoc } from 'firebase/firestore';
import { motion } from 'framer-motion';
import { User, Mail, Shield, Save } from 'lucide-react';

export default function ProfilePage() {
  const [profile, setProfile] = useState<any>({ name: '', email: '', fitnessGoal: 'Weight Loss' });
  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState('');

  useEffect(() => {
    async function loadProfile() {
      if (!auth.currentUser) return;
      const docRef = doc(db, 'users', auth.currentUser.uid);
      const snap = await getDoc(docRef);
      if (snap.exists()) {
        setProfile({ ...snap.data(), email: auth.currentUser.email });
      }
    }
    loadProfile();
  }, []);

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser) return;
    setSaving(true);
    setMsg('');
    try {
      await updateDoc(doc(db, 'users', auth.currentUser.uid), {
        name: profile.name,
        fitnessGoal: profile.fitnessGoal
      });
      setMsg('Profile updated successfully!');
      setTimeout(() => setMsg(''), 3000);
    } catch (err) {
      console.error(err);
      alert('Error updating profile');
    } finally {
      setSaving(false);
    }
  };

  const containerVariants = { hidden: { opacity: 0, scale: 0.95 }, show: { opacity: 1, scale: 1, transition: { type: "spring" as const, bounce: 0.4 } } };

  return (
    <div className="p-8 max-w-4xl mx-auto space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-white mb-2">Account Settings</h1>
        <p className="text-gray-400">Manage your profile and BioMechAI preferences.</p>
      </div>

      <motion.div variants={containerVariants} initial="hidden" animate="show" className="glass-panel rounded-3xl p-8">
        
        <div className="flex items-center gap-6 mb-10 pb-8 border-b border-white/5">
          <div className="w-24 h-24 rounded-full bg-gradient-to-tr from-[#00f3ff] to-[#9d00ff] p-1">
            <div className="w-full h-full bg-[#090b10] rounded-full flex items-center justify-center overflow-hidden">
              {profile.name ? <img src={`https://api.dicebear.com/7.x/avataaars/svg?seed=${profile.name}`} alt="avatar" /> : <User size={40} className="text-gray-500" />}
            </div>
          </div>
          <div>
            <h2 className="text-2xl font-bold text-white">{profile.name || 'User'}</h2>
            <div className="flex items-center gap-2 text-gray-400 mt-1">
              <Shield size={16} className="text-[#00f3ff]" />
              <span>BioMechAI Athlete</span>
            </div>
          </div>
        </div>

        {msg && <div className="bg-green-500/10 text-green-400 p-4 rounded-xl mb-6 border border-green-500/20">{msg}</div>}

        <form onSubmit={handleSave} className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label className="block text-sm font-medium text-gray-400 mb-2">Full Name</label>
              <div className="relative">
                <User className="absolute left-4 top-3.5 text-gray-500" size={20} />
                <input 
                  type="text" 
                  value={profile.name} 
                  onChange={e => setProfile({...profile, name: e.target.value})} 
                  className="w-full bg-black/30 border border-white/10 rounded-xl py-3 pl-12 pr-4 text-white focus:border-[#00f3ff] outline-none transition-all" 
                />
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-400 mb-2">Email Address</label>
              <div className="relative">
                <Mail className="absolute left-4 top-3.5 text-gray-500" size={20} />
                <input 
                  type="email" 
                  value={profile.email} 
                  disabled
                  className="w-full bg-black/50 border border-white/5 rounded-xl py-3 pl-12 pr-4 text-gray-500 cursor-not-allowed" 
                />
              </div>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-400 mb-2">Primary Fitness Goal</label>
            <select 
              value={profile.fitnessGoal}
              onChange={e => setProfile({...profile, fitnessGoal: e.target.value})}
              className="w-full bg-black/30 border border-white/10 rounded-xl py-3 px-4 text-white focus:border-[#00f3ff] outline-none transition-all appearance-none"
            >
              <option value="Weight Loss">Weight Loss & Toning</option>
              <option value="Muscle Gain">Muscle Gain & Hypertrophy</option>
              <option value="Endurance">Endurance & Stamina</option>
              <option value="Flexibility">Flexibility & Mobility</option>
            </select>
          </div>

          <div className="pt-6 border-t border-white/5 flex justify-end">
            <button 
              type="submit" 
              disabled={saving}
              className="btn-primary py-3 px-8 rounded-xl flex items-center gap-2"
            >
              <Save size={20} />
              {saving ? 'Saving...' : 'Save Changes'}
            </button>
          </div>
        </form>

      </motion.div>
    </div>
  );
}
