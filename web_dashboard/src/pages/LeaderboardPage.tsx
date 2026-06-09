import { useEffect, useState } from 'react';
import { db } from '../firebase';
import { collection, query, where, getDocs } from 'firebase/firestore';
import { motion } from 'framer-motion';
import { Trophy, Medal, Star } from 'lucide-react';

export default function LeaderboardPage() {
  const [leaders, setLeaders] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchLeaders() {
      try {
        const usersQ = query(collection(db, 'users'), where('role', '==', 'user'));
        const usersSnap = await getDocs(usersQ);
        
        const sessionsSnap = await getDocs(collection(db, 'sessions'));
        const sessions = sessionsSnap.docs.map(d => d.data());
        
        const leaderData = usersSnap.docs.map(doc => {
          const u = doc.data();
          const userSessions = sessions.filter(s => s.userId === doc.id);
          const totalReps = userSessions.reduce((acc, s) => acc + (s.validReps || 0), 0);
          const avgScore = userSessions.length ? userSessions.reduce((acc, s) => acc + (s.avgFormScore || 0), 0) / userSessions.length : 0;
          
          return { id: doc.id, name: u.name, totalReps, avgScore, avatar: `https://api.dicebear.com/7.x/avataaars/svg?seed=${u.name}` };
        }).sort((a, b) => b.totalReps - a.totalReps);
        
        setLeaders(leaderData);
      } catch (e) {
        console.error(e);
      } finally {
        setLoading(false);
      }
    }
    fetchLeaders();
  }, []);

  const containerVariants = { hidden: { opacity: 0 }, show: { opacity: 1, transition: { staggerChildren: 0.1 } } };
  const itemVariants = { hidden: { opacity: 0, x: -20 }, show: { opacity: 1, x: 0 } };

  if (loading) return <div className="flex-1 flex items-center justify-center"><div className="w-10 h-10 border-4 border-[#00f3ff] border-t-transparent rounded-full animate-spin"></div></div>;

  return (
    <div className="p-8 max-w-5xl mx-auto space-y-8">
      <div className="flex items-center gap-4">
        <div className="p-4 bg-[#f1c40f]/10 rounded-2xl text-[#f1c40f]">
          <Trophy size={32} />
        </div>
        <div>
          <h1 className="text-3xl font-bold text-white">Global Leaderboard</h1>
          <p className="text-gray-400">See how you stack up against the BioMechAI community.</p>
        </div>
      </div>

      <motion.div variants={containerVariants} initial="hidden" animate="show" className="glass-panel rounded-2xl overflow-hidden">
        <div className="grid grid-cols-12 gap-4 p-4 border-b border-white/5 text-xs font-semibold text-gray-500 uppercase tracking-widest bg-black/20">
          <div className="col-span-1 text-center">Rank</div>
          <div className="col-span-6">Athlete</div>
          <div className="col-span-3 text-right">Valid Reps</div>
          <div className="col-span-2 text-right">Avg Form</div>
        </div>
        
        {leaders.map((leader, index) => (
          <motion.div key={leader.id} variants={itemVariants} className="grid grid-cols-12 gap-4 p-4 items-center border-b border-white/5 hover:bg-white/5 transition-colors group">
            <div className="col-span-1 flex justify-center">
              {index === 0 ? <Medal className="text-[#f1c40f]" size={24} /> : 
               index === 1 ? <Medal className="text-[#95a5a6]" size={24} /> : 
               index === 2 ? <Medal className="text-[#d35400]" size={24} /> : 
               <span className="text-gray-500 font-bold">{index + 1}</span>}
            </div>
            <div className="col-span-6 flex items-center gap-4">
              <img src={leader.avatar} alt="avatar" className="w-10 h-10 rounded-full bg-white/10" />
              <span className="font-semibold text-white group-hover:text-[#00f3ff] transition-colors">{leader.name}</span>
            </div>
            <div className="col-span-3 text-right font-mono text-lg text-white">
              {leader.totalReps}
            </div>
            <div className="col-span-2 flex justify-end items-center gap-1 text-[#2ea043] font-mono">
              <Star size={14} />
              {leader.avgScore.toFixed(1)}
            </div>
          </motion.div>
        ))}
        {leaders.length === 0 && (
          <div className="p-8 text-center text-gray-500">No leaderboard data available yet.</div>
        )}
      </motion.div>
    </div>
  );
}
