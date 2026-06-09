
import { motion } from 'framer-motion';
import { Utensils, Droplets, Leaf, Flame } from 'lucide-react';

export default function DietPage() {
  const containerVariants = { hidden: { opacity: 0 }, show: { opacity: 1, transition: { staggerChildren: 0.1 } } };
  const itemVariants = { hidden: { opacity: 0, y: 20 }, show: { opacity: 1, y: 0 } };

  return (
    <div className="p-8 max-w-6xl mx-auto space-y-8">
      <div className="flex items-center gap-4">
        <div className="p-4 bg-green-500/10 rounded-2xl text-green-400">
          <Utensils size={32} />
        </div>
        <div>
          <h1 className="text-3xl font-bold text-white">Nutrition Plans</h1>
          <p className="text-gray-400">Fuel your body for optimal bio-mechanical performance.</p>
        </div>
      </div>

      <motion.div variants={containerVariants} initial="hidden" animate="show" className="grid grid-cols-1 md:grid-cols-2 gap-8">
        
        {/* Keto Plan */}
        <motion.div variants={itemVariants} className="glass-panel glass-panel-hover rounded-3xl overflow-hidden group">
          <div className="relative h-64 overflow-hidden">
            <img 
              src="/keto_meal.png" 
              alt="Keto Meal" 
              className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-[#090b10] to-transparent"></div>
            <div className="absolute bottom-4 left-6 flex gap-2">
              <span className="px-3 py-1 bg-white/10 backdrop-blur rounded-full text-xs font-semibold text-white border border-white/20">High Fat</span>
              <span className="px-3 py-1 bg-[#00f3ff]/20 backdrop-blur rounded-full text-xs font-semibold text-[#00f3ff] border border-[#00f3ff]/30">Low Carb</span>
            </div>
          </div>
          <div className="p-6">
            <h2 className="text-2xl font-bold text-white mb-2">The Keto Shred</h2>
            <p className="text-gray-400 mb-6 line-clamp-2">A high-fat, low-carbohydrate diet designed to force your body into a metabolic state called ketosis, perfect for rapid fat loss.</p>
            
            <div className="grid grid-cols-3 gap-4 mb-6">
              <div className="bg-black/20 p-3 rounded-xl text-center border border-white/5">
                <Flame className="mx-auto text-orange-400 mb-1" size={18} />
                <div className="text-sm font-bold text-white">75%</div>
                <div className="text-[10px] text-gray-500 uppercase">Fat</div>
              </div>
              <div className="bg-black/20 p-3 rounded-xl text-center border border-white/5">
                <Droplets className="mx-auto text-[#00f3ff] mb-1" size={18} />
                <div className="text-sm font-bold text-white">20%</div>
                <div className="text-[10px] text-gray-500 uppercase">Protein</div>
              </div>
              <div className="bg-black/20 p-3 rounded-xl text-center border border-white/5">
                <Leaf className="mx-auto text-green-400 mb-1" size={18} />
                <div className="text-sm font-bold text-white">5%</div>
                <div className="text-[10px] text-gray-500 uppercase">Carbs</div>
              </div>
            </div>
            
            <button className="w-full btn-primary py-3 rounded-xl">Select Plan</button>
          </div>
        </motion.div>

        {/* High Protein Plan */}
        <motion.div variants={itemVariants} className="glass-panel glass-panel-hover rounded-3xl overflow-hidden group">
          <div className="relative h-64 overflow-hidden">
            <img 
              src="/high_protein_meal.png" 
              alt="High Protein Meal" 
              className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-[#090b10] to-transparent"></div>
            <div className="absolute bottom-4 left-6 flex gap-2">
              <span className="px-3 py-1 bg-white/10 backdrop-blur rounded-full text-xs font-semibold text-white border border-white/20">High Protein</span>
              <span className="px-3 py-1 bg-purple-500/20 backdrop-blur rounded-full text-xs font-semibold text-purple-400 border border-purple-500/30">Muscle Gain</span>
            </div>
          </div>
          <div className="p-6">
            <h2 className="text-2xl font-bold text-white mb-2">Lean Muscle Builder</h2>
            <p className="text-gray-400 mb-6 line-clamp-2">Optimized for muscle protein synthesis and recovery after heavy BioMechAI tracking sessions.</p>
            
            <div className="grid grid-cols-3 gap-4 mb-6">
              <div className="bg-black/20 p-3 rounded-xl text-center border border-white/5">
                <Droplets className="mx-auto text-[#00f3ff] mb-1" size={18} />
                <div className="text-sm font-bold text-white">40%</div>
                <div className="text-[10px] text-gray-500 uppercase">Protein</div>
              </div>
              <div className="bg-black/20 p-3 rounded-xl text-center border border-white/5">
                <Leaf className="mx-auto text-green-400 mb-1" size={18} />
                <div className="text-sm font-bold text-white">40%</div>
                <div className="text-[10px] text-gray-500 uppercase">Carbs</div>
              </div>
              <div className="bg-black/20 p-3 rounded-xl text-center border border-white/5">
                <Flame className="mx-auto text-orange-400 mb-1" size={18} />
                <div className="text-sm font-bold text-white">20%</div>
                <div className="text-[10px] text-gray-500 uppercase">Fat</div>
              </div>
            </div>
            
            <button className="w-full bg-white/5 hover:bg-white/10 border border-white/10 text-white font-semibold py-3 rounded-xl transition-colors">Select Plan</button>
          </div>
        </motion.div>

      </motion.div>
    </div>
  );
}
