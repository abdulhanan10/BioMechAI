import { useEffect, useState } from 'react';
import { db } from '../firebase';
import { collection, query, where, getDocs } from 'firebase/firestore';
import { XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, AreaChart, Area } from 'recharts';
import { motion } from 'framer-motion';
import { Target, Activity, Flame, Award, Users } from 'lucide-react';

export default function DashboardHome() {
  const [clients, setClients] = useState<any[]>([]);
  const [selectedClient, setSelectedClient] = useState<any | null>(null);
  const [sessions, setSessions] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchClients() {
      try {
        // Fetch only clients (users with role 'user')
        const q = query(collection(db, 'users'), where('role', '==', 'user'));
        const snap = await getDocs(q);
        const fetched = snap.docs.map(d => ({ uid: d.id, ...d.data() }));
        setClients(fetched);
        
        // Auto-select the first user if available
        if (fetched.length > 0) {
          handleSelectClient(fetched[0]);
        } else {
          setLoading(false);
        }
      } catch (err) {
        console.error(err);
        setLoading(false);
      }
    }
    fetchClients();
  }, []);

  const handleSelectClient = async (client: any) => {
    setSelectedClient(client);
    try {
      const q = collection(db, 'users', client.uid, 'workout_sessions');
      const snap = await getDocs(q);
      const fetchedSessions = snap.docs.map(d => ({ id: d.id, ...d.data() }))
        .sort((a:any, b:any) => new Date(a.sessionDate).getTime() - new Date(b.sessionDate).getTime());
      setSessions(fetchedSessions);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const totalValidReps = sessions.reduce((acc, s) => acc + (s.totalValidReps || 0), 0);
  const avgScore = sessions.length > 0 ? Math.floor(sessions.reduce((acc, s) => acc + (s.avgFormScore || 0), 0) / sessions.length).toFixed(1) : "0.0";
  const streak = Math.min(sessions.length, 7); // Mock streak

  const chartData = sessions.slice(-10).map((s, i) => ({
    name: `S${i+1}`,
    score: s.avgFormScore || 0,
    reps: s.totalValidReps || 0
  }));

  const containerVariants = {
    hidden: { opacity: 0 },
    show: {
      opacity: 1,
      transition: { staggerChildren: 0.1 }
    }
  };

  const itemVariants = {
    hidden: { opacity: 0, y: 20 },
    show: { opacity: 1, y: 0, transition: { type: "spring" as const, stiffness: 300, damping: 24 } }
  };

  if (loading) return <div className="flex-1 flex items-center justify-center"><div className="w-10 h-10 border-4 border-[#00f3ff] border-t-transparent rounded-full animate-spin"></div></div>;

  return (
    <motion.div 
      variants={containerVariants} initial="hidden" animate="show"
      className="p-8 max-w-7xl mx-auto space-y-8"
    >
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2">Trainer Overview</h1>
          <p className="text-gray-400">Viewing bio-mechanical data for your selected client.</p>
        </div>
        
        {/* Client Selector Dropdown */}
        <div className="flex items-center gap-3 bg-black/40 border border-white/10 p-2 rounded-xl">
          <Users size={20} className="text-[#00f3ff] ml-2" />
          <select 
            className="bg-transparent text-white outline-none pr-4 cursor-pointer"
            value={selectedClient?.uid || ''}
            onChange={(e) => {
              const client = clients.find(c => c.uid === e.target.value);
              if (client) handleSelectClient(client);
            }}
          >
            {clients.map(c => (
              <option key={c.uid} value={c.uid} className="bg-[#090b10] text-white">
                {c.name || c.email}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <motion.div variants={itemVariants} className="glass-panel glass-panel-hover p-6 rounded-2xl relative overflow-hidden">
          <div className="absolute -right-4 -top-4 text-white/5"><Activity size={100} /></div>
          <div className="flex items-center gap-4 mb-4">
            <div className="p-3 bg-[#00f3ff]/10 rounded-xl text-[#00f3ff]"><Activity size={24} /></div>
            <h3 className="text-gray-400 font-medium">Total Workouts</h3>
          </div>
          <p className="text-4xl font-bold text-white">{sessions.length}</p>
        </motion.div>

        <motion.div variants={itemVariants} className="glass-panel glass-panel-hover p-6 rounded-2xl relative overflow-hidden">
          <div className="absolute -right-4 -top-4 text-white/5"><Target size={100} /></div>
          <div className="flex items-center gap-4 mb-4">
            <div className="p-3 bg-green-500/10 rounded-xl text-green-400"><Target size={24} /></div>
            <h3 className="text-gray-400 font-medium">Avg Form Score</h3>
          </div>
          <p className="text-4xl font-bold text-white">{avgScore}<span className="text-xl text-gray-500">/100</span></p>
        </motion.div>

        <motion.div variants={itemVariants} className="glass-panel glass-panel-hover p-6 rounded-2xl relative overflow-hidden">
          <div className="absolute -right-4 -top-4 text-white/5"><Flame size={100} /></div>
          <div className="flex items-center gap-4 mb-4">
            <div className="p-3 bg-orange-500/10 rounded-xl text-orange-400"><Flame size={24} /></div>
            <h3 className="text-gray-400 font-medium">Total Valid Reps</h3>
          </div>
          <p className="text-4xl font-bold text-white">{totalValidReps}</p>
        </motion.div>

        <motion.div variants={itemVariants} className="glass-panel glass-panel-hover p-6 rounded-2xl relative overflow-hidden">
          <div className="absolute -right-4 -top-4 text-white/5"><Award size={100} /></div>
          <div className="flex items-center gap-4 mb-4">
            <div className="p-3 bg-purple-500/10 rounded-xl text-purple-400"><Award size={24} /></div>
            <h3 className="text-gray-400 font-medium">Current Streak</h3>
          </div>
          <p className="text-4xl font-bold text-white">{streak} <span className="text-xl text-gray-500">Days</span></p>
        </motion.div>
      </div>

      {/* Charts */}
      {/* Charts */}
      <div className="grid grid-cols-1 gap-8">
        <motion.div variants={itemVariants} className="glass-panel p-6 rounded-2xl">
          <h3 className="text-xl font-bold text-white mb-6 flex items-center gap-2">
            <div className="w-2 h-6 bg-[#00f3ff] rounded-full"></div>
            Form Progression
          </h3>
          <div className="h-72">
            {chartData.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={chartData}>
                  <defs>
                    <linearGradient id="colorScore" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#00f3ff" stopOpacity={0.3}/>
                      <stop offset="95%" stopColor="#00f3ff" stopOpacity={0}/>
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" vertical={false} />
                  <XAxis dataKey="name" stroke="#8b949e" tickLine={false} axisLine={false} />
                  <YAxis stroke="#8b949e" domain={[0, 100]} tickLine={false} axisLine={false} />
                  <Tooltip contentStyle={{ backgroundColor: 'rgba(18,22,33,0.9)', borderColor: 'rgba(255,255,255,0.1)', borderRadius: '12px' }} />
                  <Area type="monotone" dataKey="score" stroke="#00f3ff" strokeWidth={3} fillOpacity={1} fill="url(#colorScore)" />
                </AreaChart>
              </ResponsiveContainer>
            ) : <div className="h-full flex items-center justify-center text-gray-500">No session data yet for this user.</div>}
          </div>
        </motion.div>
      </div>
    </motion.div>
  );
}
