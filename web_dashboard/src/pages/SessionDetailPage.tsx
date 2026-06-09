import { useState, useEffect, useRef } from 'react';
import { useParams, useSearchParams, useNavigate } from 'react-router-dom';
import { collection, doc, getDoc, getDocs, addDoc, query, orderBy, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase';
import { ArrowLeft, Play, Pause, Send } from 'lucide-react';

export default function SessionDetailPage() {
  const { sessionId } = useParams();
  const [searchParams] = useSearchParams();
  const uid = searchParams.get('uid');
  const navigate = useNavigate();

  const [session, setSession] = useState<any>(null);
  const [reps, setReps] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  
  const videoRef = useRef<HTMLVideoElement>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [feedbackText, setFeedbackText] = useState('');
  const [feedbacks, setFeedbacks] = useState<any[]>([]);

  useEffect(() => {
    const fetchData = async () => {
      if (!uid || !sessionId) return;
      try {
        const docRef = doc(db, 'users', uid, 'workout_sessions', sessionId);
        const docSnap = await getDoc(docRef);
        if (docSnap.exists()) setSession(docSnap.data());

        const repsRef = collection(db, 'users', uid, 'workout_sessions', sessionId, 'reps');
        const repsSnap = await getDocs(repsRef);
        const fetchedReps = repsSnap.docs.map(d => ({ id: d.id, ...d.data() } as any)).sort((a: any, b: any) => a.repNumber - b.repNumber);
        setReps(fetchedReps);
        
        // Fetch feedbacks
        const feedbackRef = collection(db, 'trainer_feedback');
        const q = query(feedbackRef, orderBy('createdAt', 'desc'));
        const fbSnap = await getDocs(q);
        const allFb = fbSnap.docs.map(d => ({ id: d.id, ...d.data() }));
        setFeedbacks(allFb.filter((f: any) => f.sessionId === sessionId));
      } catch (error) {
        console.error("Error:", error);
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, [uid, sessionId]);

  const togglePlay = () => {
    if (videoRef.current) {
      if (isPlaying) videoRef.current.pause();
      else videoRef.current.play();
      setIsPlaying(!isPlaying);
    }
  };

  const handleAddFeedback = async () => {
    if (!feedbackText.trim() || !uid || !sessionId) return;
    const timestamp = videoRef.current ? Math.floor(videoRef.current.currentTime) : 0;
    
    try {
      await addDoc(collection(db, 'trainer_feedback'), {
        clientId: uid,
        sessionId: sessionId,
        feedbackText,
        videoTimestamp: timestamp,
        createdAt: serverTimestamp()
      });
      setFeedbackText('');
      // Optimistic UI update
      setFeedbacks([{ clientId: uid, sessionId, feedbackText, videoTimestamp: timestamp, createdAt: new Date() }, ...feedbacks]);
    } catch (e) {
      console.error(e);
    }
  };

  if (loading) return <div className="p-8 text-white">Loading...</div>;
  if (!session) return <div className="p-8 text-white">Session not found</div>;

  return (
    <div className="p-8">
      <button onClick={() => navigate(`/client/${uid}`)} className="flex items-center gap-2 text-gray-400 hover:text-white mb-6 transition-colors">
        <ArrowLeft size={20} /> Back to Client
      </button>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Video Player */}
        <div className="space-y-6">
          <div className="glass-panel border border-white/5 rounded-2xl overflow-hidden relative group">
            {session.videoUrl ? (
              <>
                <video 
                  ref={videoRef}
                  src={session.videoUrl} 
                  className="w-full h-auto aspect-video object-cover"
                  controls={false}
                />
                <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                  <button onClick={togglePlay} className="w-16 h-16 bg-[#00f3ff] rounded-full flex items-center justify-center text-black hover:scale-110 transition-transform">
                    {isPlaying ? <Pause size={30} fill="currentColor" /> : <Play size={30} fill="currentColor" className="ml-1" />}
                  </button>
                </div>
              </>
            ) : (
              <div className="w-full aspect-video flex items-center justify-center bg-[#161b22] text-gray-500">
                No video recorded for this session
              </div>
            )}
          </div>

          {/* Feedback input */}
          <div className="glass-panel border border-white/5 rounded-2xl p-6">
            <h3 className="text-white font-bold mb-4">Add Trainer Feedback</h3>
            <div className="flex gap-3">
              <input 
                type="text" 
                value={feedbackText}
                onChange={e => setFeedbackText(e.target.value)}
                placeholder="E.g., Keep your back straighter..."
                className="flex-1 bg-[#161b22] border border-white/10 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-[#00f3ff]"
                onKeyDown={e => e.key === 'Enter' && handleAddFeedback()}
              />
              <button 
                onClick={handleAddFeedback}
                className="bg-[#00f3ff] text-black px-6 rounded-xl font-bold flex items-center gap-2 hover:bg-[#00d0fa] transition-colors"
              >
                Send <Send size={16} />
              </button>
            </div>
            
            <div className="mt-6 space-y-3">
              {feedbacks.map((f, i) => (
                <div key={i} className="bg-[#161b22] p-4 rounded-xl border border-white/5 flex gap-4">
                  <div className="bg-white/10 px-2 py-1 rounded text-xs text-[#00f3ff] font-mono h-fit">
                    {Math.floor(f.videoTimestamp / 60)}:{(f.videoTimestamp % 60).toString().padStart(2, '0')}
                  </div>
                  <div className="text-gray-300 text-sm">{f.feedbackText}</div>
                </div>
              ))}
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
