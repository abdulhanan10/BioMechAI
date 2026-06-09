import { useState, useEffect } from 'react';
import { db } from '../firebase';
import { useNavigate } from 'react-router-dom';
import { Search, ChevronRight } from 'lucide-react';
import { collection as firestoreCollection, query as firestoreQuery, where as firestoreWhere, getDocs as firestoreGetDocs } from 'firebase/firestore';

export default function ClientListPage() {
  const [clients, setClients] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchClients = async () => {
      try {
        const q = firestoreQuery(firestoreCollection(db, 'users'), firestoreWhere('role', '==', 'user'));
        const querySnapshot = await firestoreGetDocs(q);
        const fetchedClients = querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        setClients(fetchedClients);
      } catch (error) {
        console.error("Error fetching clients:", error);
      } finally {
        setLoading(false);
      }
    };
    fetchClients();
  }, []);

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2">My Clients</h1>
          <p className="text-gray-400">Manage and monitor all your assigned clients</p>
        </div>
        
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={20} />
          <input 
            type="text" 
            placeholder="Search clients..." 
            className="bg-[#161b22] border border-white/10 rounded-xl py-2.5 pl-10 pr-4 text-white placeholder-gray-500 focus:outline-none focus:border-[#00f3ff] transition-colors w-64"
          />
        </div>
      </div>

      <div className="glass-panel border border-white/5 rounded-2xl overflow-hidden">
        {loading ? (
          <div className="p-8 text-center text-gray-400">Loading clients...</div>
        ) : clients.length === 0 ? (
          <div className="p-8 text-center text-gray-400">No clients found.</div>
        ) : (
          <table className="w-full text-left">
            <thead className="bg-white/5 border-b border-white/5">
              <tr>
                <th className="px-6 py-4 text-sm font-semibold text-gray-400">Client Name</th>
                <th className="px-6 py-4 text-sm font-semibold text-gray-400">Fitness Goal</th>
                <th className="px-6 py-4 text-sm font-semibold text-gray-400">Streak</th>
                <th className="px-6 py-4 text-sm font-semibold text-gray-400 text-right">Action</th>
              </tr>
            </thead>
            <tbody>
              {clients.map((client) => (
                <tr 
                  key={client.id} 
                  onClick={() => navigate(`/client/${client.id}`)}
                  className="border-b border-white/5 hover:bg-white/5 cursor-pointer transition-colors group"
                >
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#00f3ff] to-[#0088ff] flex items-center justify-center text-black font-bold">
                        {client.name ? client.name.charAt(0).toUpperCase() : 'U'}
                      </div>
                      <div>
                        <div className="text-white font-medium">{client.name}</div>
                        <div className="text-xs text-gray-500">{client.email}</div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 text-gray-300">{client.fitnessGoal || 'N/A'}</td>
                  <td className="px-6 py-4 text-gray-300">🔥 {client.streakCount || 0} days</td>
                  <td className="px-6 py-4 text-right">
                    <ChevronRight className="inline-block text-gray-500 group-hover:text-[#00f3ff] transition-colors" size={20} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
