import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import Calendar from 'react-calendar';
import 'react-calendar/dist/Calendar.css';
import { collection, getDocs, doc, getDoc } from 'firebase/firestore';
import { db } from '../firebase';
import { ArrowLeft, Activity } from 'lucide-react';

export default function ClientDetailPage() {
  const { uid } = useParams();
  const navigate = useNavigate();
  const [client, setClient] = useState<any>(null);
  const [sessions, setSessions] = useState<any[]>([]);
  const [selectedDate, setSelectedDate] = useState<Date>(new Date());
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchClientAndSessions = async () => {
      if (!uid) return;
      try {
        const docRef = doc(db, 'users', uid);
        const docSnap = await getDoc(docRef);
        if (docSnap.exists()) setClient(docSnap.data());

        const sessionsRef = collection(db, 'users', uid, 'workout_sessions');
        const querySnapshot = await getDocs(sessionsRef);
        const fetchedSessions = querySnapshot.docs.map(doc => {
          const data = doc.data();
          // handle Firestore Timestamp
          const sessionDate = data.sessionDate?.toDate ? data.sessionDate.toDate() : new Date(data.sessionDate);
          return { id: doc.id, ...data, sessionDate };
        });
        setSessions(fetchedSessions);
      } catch (error) {
        console.error("Error fetching data:", error);
      } finally {
        setLoading(false);
      }
    };
    fetchClientAndSessions();
  }, [uid]);

  const tileClassName = ({ date, view }: { date: Date, view: string }) => {
    if (view === 'month') {
      const hasSession = sessions.some(s => 
        s.sessionDate.getDate() === date.getDate() &&
        s.sessionDate.getMonth() === date.getMonth() &&
        s.sessionDate.getFullYear() === date.getFullYear()
      );
      return hasSession ? 'has-session' : null;
    }
    return null;
  };

  const selectedDateSessions = sessions.filter(s => 
    s.sessionDate.getDate() === selectedDate.getDate() &&
    s.sessionDate.getMonth() === selectedDate.getMonth() &&
    s.sessionDate.getFullYear() === selectedDate.getFullYear()
  );

  if (loading) return <div className="p-8 text-white">Loading...</div>;
  if (!client) return <div className="p-8 text-white">Client not found</div>;

  return (
    <div className="p-8">
      <button onClick={() => navigate('/clients')} className="flex items-center gap-2 text-gray-400 hover:text-white mb-6 transition-colors">
        <ArrowLeft size={20} /> Back to Clients
      </button>

      <div className="flex justify-between items-start mb-8">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2">{client.name}</h1>
          <p className="text-gray-400">{client.email} • Goal: {client.fitnessGoal}</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Calendar Section */}
        <div className="lg:col-span-1">
          <div className="glass-panel border border-white/5 rounded-2xl p-6 mb-6">
            <h2 className="text-xl font-bold text-white mb-4">Workout Calendar</h2>
            <style>{`
              .react-calendar { background: transparent; border: none; font-family: inherit; width: 100%; color: white; }
              .react-calendar__navigation button { color: white; min-width: 44px; background: none; font-size: 16px; margin-top: 8px; }
              .react-calendar__navigation button:enabled:hover, .react-calendar__navigation button:enabled:focus { background-color: rgba(255,255,255,0.1); }
              .react-calendar__tile { color: white; padding: 10px 6.6667%; }
              .react-calendar__tile:enabled:hover, .react-calendar__tile:enabled:focus { background-color: rgba(255,255,255,0.1); border-radius: 8px; }
              .react-calendar__tile--now { background: rgba(0, 243, 255, 0.2); border-radius: 8px; }
              .react-calendar__tile--active { background: #00f3ff !important; color: black; border-radius: 8px; }
              .has-session { position: relative; }
              .has-session::after { content: ''; position: absolute; bottom: 2px; left: 50%; transform: translateX(-50%); width: 6px; height: 6px; background-color: #3FB950; border-radius: 50%; }
              .react-calendar__month-view__days__day--weekend { color: #8B949E; }
              .react-calendar__month-view__days__day--neighboringMonth { color: #4b5563; }
            `}</style>
            <Calendar 
              onChange={(val) => setSelectedDate(val as Date)} 
              value={selectedDate} 
              tileClassName={tileClassName}
            />
          </div>
        </div>

        {/* Sessions Section */}
        <div className="lg:col-span-2">
          <div className="glass-panel border border-white/5 rounded-2xl p-6 h-full">
            <h2 className="text-xl font-bold text-white mb-4">Sessions on {selectedDate.toDateString()}</h2>
            
            {selectedDateSessions.length === 0 ? (
              <div className="text-center text-gray-500 py-12">No workouts recorded on this date.</div>
            ) : (
              <div className="space-y-4">
                {selectedDateSessions.map(session => (
                  <div key={session.id} className="bg-[#161b22] border border-white/5 rounded-xl p-5 hover:border-[#00f3ff]/30 transition-all">
                    <div className="flex justify-between items-center mb-4">
                      <div>
                        <div className="text-lg font-bold text-white">{session.sessionDate.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</div>
                        <div className="text-sm text-gray-400">{session.totalDuration} seconds • {session.exerciseCount} exercises</div>
                      </div>
                      <div className="text-right">
                        <div className="text-sm text-gray-400">Avg Form Score</div>
                        <div className={`text-xl font-bold ${session.avgFormScore >= 80 ? 'text-green-400' : session.avgFormScore >= 60 ? 'text-yellow-400' : 'text-red-400'}`}>
                          {Math.round(session.avgFormScore)}
                        </div>
                      </div>
                    </div>
                    
                    <div className="flex gap-3 mt-4 pt-4 border-t border-white/5">
                      <button 
                        onClick={() => navigate(`/session/${session.id}?uid=${uid}`)}
                        className="w-full bg-white/5 hover:bg-white/10 text-white py-2 rounded-lg flex items-center justify-center gap-2 transition-colors text-sm"
                      >
                        <Activity size={16} /> View Analysis
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
