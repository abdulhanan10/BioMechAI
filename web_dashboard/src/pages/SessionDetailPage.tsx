import { useState, useEffect } from 'react';
import { useParams, useSearchParams, useNavigate } from 'react-router-dom';
import { collection, doc, getDoc, getDocs, updateDoc } from 'firebase/firestore';
import { db } from '../firebase';
import { ArrowLeft, Send, CheckCircle } from 'lucide-react';

export default function SessionDetailPage() {
  const { sessionId } = useParams();
  const [searchParams] = useSearchParams();
  const uid = searchParams.get('uid');
  const navigate = useNavigate();

  const [session, setSession] = useState<any>(null);
  const [reps, setReps] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [feedbackText, setFeedbackText] = useState('');
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  useEffect(() => {
    const fetchData = async () => {
      if (!uid || !sessionId) return;
      try {
        const docRef = doc(db, 'users', uid, 'workout_sessions', sessionId);
        const docSnap = await getDoc(docRef);
        if (docSnap.exists()) {
          const data = docSnap.data();
          setSession(data);
        }

        const repsRef = collection(db, 'users', uid, 'workout_sessions', sessionId, 'reps');
        const repsSnap = await getDocs(repsRef);
        const fetchedReps = repsSnap.docs.map(d => ({ id: d.id, ...d.data() } as any)).sort((a: any, b: any) => a.repNumber - b.repNumber);
        setReps(fetchedReps);
        
      } catch (error) {
        console.error("Error:", error);
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, [uid, sessionId]);
  const handleSaveSessionFeedback = async () => {
    if (!feedbackText.trim() || !uid || !sessionId) return;
    try {
      const docRef = doc(db, 'users', uid, 'workout_sessions', sessionId);
      await updateDoc(docRef, {
        trainerFeedback: feedbackText
      });
      setSession((prev: any) => ({...prev, trainerFeedback: feedbackText}));
      setFeedbackText('');
      setToastMessage('Feedback sent to client!');
      setTimeout(() => setToastMessage(null), 3000);
    } catch (e) {
      console.error(e);
      setToastMessage('Failed to send feedback');
      setTimeout(() => setToastMessage(null), 3000);
    }
  };

  if (loading) return <div className="p-8 text-white">Loading...</div>;
  if (!session) return <div className="p-8 text-white">Session not found</div>;

  return (
    <div className="p-8">
      {toastMessage && (
        <div className="fixed top-6 right-6 z-50 bg-[#090b10]/90 border border-[#00f3ff]/50 text-white px-6 py-4 rounded-xl shadow-[0_0_20px_rgba(0,243,255,0.2)] flex items-center gap-3 backdrop-blur-md transition-all duration-300">
          <CheckCircle className="text-[#00f3ff]" size={24} />
          <span className="font-bold">{toastMessage}</span>
        </div>
      )}

      <button onClick={() => navigate(`/client/${uid}`)} className="flex items-center gap-2 text-gray-400 hover:text-white mb-6 transition-colors">
        <ArrowLeft size={20} /> Back to Client
      </button>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <div className="space-y-6">
          {/* Session Feedback */}
          <div className="glass-panel border border-white/5 rounded-2xl p-6">
            <h3 className="text-white font-bold mb-4">Session Feedback (Sent to App)</h3>
            
            {session.trainerFeedback && (
              <div className="mb-6 p-4 bg-[#00f3ff]/10 border border-[#00f3ff]/30 rounded-xl">
                <p className="text-[#00f3ff] text-sm font-bold mb-1">Previously Sent Feedback:</p>
                <p className="text-white whitespace-pre-wrap">{session.trainerFeedback}</p>
              </div>
            )}

            <textarea 
              value={feedbackText}
              onChange={e => setFeedbackText(e.target.value)}
              placeholder="Write new feedback for this entire session. The client will see this in their app..."
              className="w-full bg-[#161b22] border border-white/10 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-[#00f3ff] min-h-[100px] resize-y mb-4"
            />
            <div className="flex justify-end">
              <button 
                onClick={handleSaveSessionFeedback}
                className="bg-[#00f3ff] text-black px-6 py-3 rounded-xl font-bold flex items-center gap-2 hover:bg-[#00d0fa] transition-colors"
              >
                Send Feedback <Send size={16} />
              </button>
            </div>
          </div>
        </div>

        {/* Rep Analysis Table */}
        <div className="glass-panel border border-white/5 rounded-2xl p-6 h-fit max-h-[80vh] overflow-y-auto">
          <h2 className="text-xl font-bold text-white mb-6">Rep-by-Rep Analysis</h2>
          
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-white/10">
                <th className="py-3 text-gray-400 font-medium text-sm">Rep</th>
                <th className="py-3 text-gray-400 font-medium text-sm">Valid</th>
                <th className="py-3 text-gray-400 font-medium text-sm">Score</th>
                <th className="py-3 text-gray-400 font-medium text-sm">Issues</th>
              </tr>
            </thead>
            <tbody>
              {reps.map(rep => (
                <tr key={rep.id} className="border-b border-white/5">
                  <td className="py-4 text-white font-medium">{rep.repNumber}</td>
                  <td className="py-4">
                    {rep.isValid ? <span className="text-green-500">✅</span> : <span className="text-red-500">❌</span>}
                  </td>
                  <td className="py-4 text-white">
                    <span className={`px-2 py-1 rounded-full text-xs font-bold ${rep.formScore >= 80 ? 'bg-green-500/20 text-green-400' : rep.formScore >= 60 ? 'bg-yellow-500/20 text-yellow-400' : 'bg-red-500/20 text-red-400'}`}>
                      {Math.round(rep.formScore)}
                    </span>
                  </td>
                  <td className="py-4 text-gray-400 text-sm">
                    {rep.errorsDetected?.length > 0 ? rep.errorsDetected.join(', ') : 'None'}
                  </td>
                </tr>
              ))}
              {reps.length === 0 && (
                <tr><td colSpan={4} className="py-8 text-center text-gray-500">No reps recorded</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
