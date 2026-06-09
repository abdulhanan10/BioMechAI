
import { NavLink, useNavigate } from 'react-router-dom';
import { auth } from '../firebase';
import { signOut } from 'firebase/auth';
import { LayoutDashboard, Trophy, Utensils, Settings, LogOut, Activity } from 'lucide-react';

export default function Sidebar() {
  const navigate = useNavigate();

  const handleSignOut = async () => {
    await signOut(auth);
    navigate('/auth');
  };

  return (
    <div className="w-full md:w-64 glass-panel border-r border-white/5 flex flex-col min-h-screen">
      <div className="p-6 border-b border-white/5 flex items-center gap-3">
        <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-[#00f3ff] to-[#0088ff] flex items-center justify-center shadow-[0_0_15px_rgba(0,243,255,0.3)]">
          <Activity size={24} color="#000" strokeWidth={2.5} />
        </div>
        <h1 className="text-xl font-bold tracking-wider text-white">
          BioMech<span className="text-[#00f3ff]">AI</span>
        </h1>
      </div>
      
      <div className="flex-1 p-4 flex flex-col gap-2 mt-4">
        <div className="text-xs font-semibold text-gray-500 uppercase tracking-widest px-4 mb-2">Menu</div>
        
        <NavLink to="/" className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
          <LayoutDashboard size={20} />
          <span>Dashboard</span>
        </NavLink>
        
        <NavLink to="/leaderboard" className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
          <Trophy size={20} />
          <span>Leaderboard</span>
        </NavLink>
        
        <NavLink to="/diet" className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
          <Utensils size={20} />
          <span>Nutrition Plans</span>
        </NavLink>
        
        <NavLink to="/profile" className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
          <Settings size={20} />
          <span>Settings</span>
        </NavLink>
      </div>

      <div className="p-4 border-t border-white/5">
        <button 
          onClick={handleSignOut}
          className="w-full flex items-center justify-center gap-2 py-3 px-4 rounded-xl text-gray-400 hover:text-white hover:bg-white/5 transition-all"
        >
          <LogOut size={18} />
          <span>Sign Out</span>
        </button>
      </div>
    </div>
  );
}
