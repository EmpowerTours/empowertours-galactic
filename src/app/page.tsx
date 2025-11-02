'use client';
import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Globe, Rocket } from 'lucide-react';
import Game from './components/Game';

export default function Home() {
  const [showSplash, setShowSplash] = useState(true);

  useEffect(() => {
    const timer = setTimeout(() => setShowSplash(false), 5000);
    return () => clearTimeout(timer);
  }, []);

  return (
    <div className="relative h-screen bg-gradient-to-br from-purple-900 via-black to-blue-900 overflow-hidden">
      <AnimatePresence mode="wait">
        {showSplash ? (
          <motion.div key="splash" className="absolute inset-0 flex flex-col items-center justify-center text-center p-8">
            <motion.div animate={{ rotateY: 360 }} transition={{ duration: 20, repeat: Infinity, ease: 'linear' }} className="mb-8">
              <Globe className="w-32 h-32 text-cyan-400 drop-shadow-2xl" />
            </motion.div>
            <motion.h1 className="text-6xl md:text-8xl font-black bg-gradient-to-r from-yellow-400 to-orange-500 bg-clip-text text-transparent mb-4 drop-shadow-2xl">
              EMPOWERTours
            </motion.h1>
            <motion.div initial={{ x: -200 }} animate={{ x: [-200, 200, -200] }} transition={{ duration: 10, repeat: Infinity }} className="absolute top-20 left-10">
              <Rocket className="w-12 h-12 text-red-500" />
            </motion.div>
            <motion.div initial={{ x: 200 }} animate={{ x: [200, -200, 200] }} transition={{ duration: 15, repeat: Infinity, delay: 2 }} className="absolute bottom-20 right-10">
              <Rocket className="w-16 h-16 text-emerald-400" />
            </motion.div>
            <motion.button whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }} onClick={() => setShowSplash(false)} className="bg-gradient-to-r from-purple-600 to-blue-600 px-12 py-6 rounded-full text-2xl font-bold shadow-2xl">
              🚀 Launch Game
            </motion.button>
          </motion.div>
        ) : (
          <motion.div key="game" initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
            <Game />
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
