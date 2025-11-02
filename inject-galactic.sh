#!/bin/bash
# next.config.js for static export
cat > next.config.js << 'EOL'
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export',
  trailingSlash: true,
  images: { unoptimized: true },
  eslint: { ignoreDuringBuilds: true },
};
module.exports = nextConfig;
EOL

# Monad Chain
mkdir -p src/app
cat > src/app/chain.ts << 'EOL'
import { defineChain } from 'viem';

export const monadTestnet = defineChain({
  id: 10143,
  name: 'Monad Testnet',
  nativeCurrency: { name: 'MON', symbol: 'MON', decimals: 18 },
  rpcUrls: { default: { http: ['https://testnet-rpc.monad.xyz'] } },
  blockExplorers: { default: { name: 'Monad', url: 'https://explorer.testnet.monad.xyz' } },
});
EOL

# Providers (Client Wrapper)
cat > src/app/providers.tsx << 'EOL'
'use client';
import { PrivyProvider } from '@privy-io/react-auth';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { WagmiProvider, createConfig, http } from 'wagmi';
import { monadTestnet } from './chain';

const queryClient = new QueryClient();
const wagmiConfig = createConfig({
  chains: [monadTestnet],
  transports: { [monadTestnet.id]: http() },
});

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <PrivyProvider appId="cmaoduqox005ole0nmj1s4qck" config={{ loginMethods: ['email', 'wallet'] }}>
      <QueryClientProvider client={queryClient}>
        <WagmiProvider config={wagmiConfig}>
          {children}
        </WagmiProvider>
      </QueryClientProvider>
    </PrivyProvider>
  );
}
EOL

# Layout
cat > src/app/layout.tsx << 'EOL'
import './globals.css';
import { Providers } from './providers';
import Footer from './components/Footer';

export const metadata = {
  title: 'EmpowerTours Galactic',
  description: 'Intergalactic Web3 Pixel Game on Monad',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="bg-black text-white min-h-screen flex flex-col">
        <Providers>
          <main className="flex-1">{children}</main>
          <Footer />
        </Providers>
      </body>
    </html>
  );
}
EOL

# Home Splash
cat > src/app/page.tsx << 'EOL'
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
EOL

# Game Component (Full Production with Fixes)
mkdir -p src/app/components
cat > src/app/components/Game.tsx << 'EOL'
'use client';
import { useState, useEffect, useRef, useCallback, useMemo } from 'react';
import { Stage, Layer, Rect, Circle, Line, Star as KonvaStar } from 'react-konva';
import { motion } from 'framer-motion';
import { usePrivy } from '@privy-io/react-auth';
import { useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseEther } from 'viem';
import { monadTestnet } from '../chain';

const TOKEN_SWAP = '0xe004F2eaCd0AD74E14085929337875b20975F0AA' as const;

const tokenSwapABI = [
  { name: 'swap', inputs: [{ type: 'uint256' }], outputs: [], stateMutability: 'nonpayable', type: 'function' }
] as const;

interface UserData {
  username: string;
  created: string;
  points: number;
  tours: number;
  ships: number;
  lasers: { x: number; y: number }[];
  position: { x: number; y: number };
}

export default function Game() {
  const { user, ready } = usePrivy();
  const [username, setUsername] = useState('');
  const [userData, setUserData] = useState<UserData | null>(null);
  const [menuOpen, setMenuOpen] = useState(false);
  const [holding, setHolding] = useState(false);
  const [holdStartTime, setHoldStartTime] = useState(0);
  const [monAmount, setMonAmount] = useState(0.1);
  const [dimensions, setDimensions] = useState({ width: 800, height: 600 });
  const [txHash, setTxHash] = useState<`0x${string}` | undefined>();
  const { data: txReceipt } = useWaitForTransactionReceipt({ hash: txHash });
  const { writeContract, isPending } = useWriteContract();

  useEffect(() => {
    const update = () => setDimensions({ width: window.innerWidth, height: window.innerHeight - 100 });
    update();
    window.addEventListener('resize', update);
    return () => window.removeEventListener('resize', update);
  }, []);

  const saveUser = useCallback((data: UserData) => {
    localStorage.setItem(`empowertours_${data.username}`, JSON.stringify(data));
    setUserData(data);
  }, []);

  const loadUser = useCallback((name: string) => {
    const data = localStorage.getItem(`empowertours_${name}`);
    if (data) {
      setUserData(JSON.parse(data));
    } else {
      const newData: UserData = {
        username: name,
        created: new Date().toISOString().split('T')[0],
        points: 0,
        tours: 100,
        ships: 1,
        lasers: [],
        position: { x: 200, y: 400 },
      };
      saveUser(newData);
    }
  }, [saveUser]);

  const progress = holding ? Math.min(((Date.now() - holdStartTime) / 2000) * 100, 100) : 0;

  const performSwap = async () => {
    try {
      const hash = await writeContract({
        address: TOKEN_SWAP,
        abi: tokenSwapABI,
        functionName: 'swap',
        args: [parseEther(monAmount.toString())],
        chainId: monadTestnet.id,
      });
      setTxHash(hash);
      if (txReceipt?.status === 'success') {
        saveUser({ ...userData!, tours: userData!.tours + (monAmount * 100), points: userData!.points + 50 });
      }
    } catch (err) {
      alert('Swap Failed - Check Wallet/MON Balance');
    }
  };

  useEffect(() => {
    if (progress >= 100) {
      performSwap();
      setHolding(false);
    }
  }, [progress]);

  const handleHoldStart = () => {
    setHolding(true);
    setHoldStartTime(Date.now());
  };

  const handleHoldEnd = () => setHolding(false);

  const stars = useMemo(() => Array.from({ length: 100 }, () => ({
    x: Math.random() * dimensions.width,
    y: Math.random() * dimensions.height,
    color: `hsl(${Math.random() * 360}, 70%, 70%)`,
  })), [dimensions]);

  const drawAstronaut = (x: number, y: number, color = '#00ff00') => (
    <>
      <Circle x={x} y={y} radius={15} fill="#87ceeb" />
      <Circle x={x} y={y + 5} radius={8} fill="#ffd700" />
      <Rect x={x - 12} y={y + 15} width={24} height={30} fill={color} cornerRadius={10} />
    </>
  );

  if (!ready) return <div className="h-screen flex-center bg-black text-white">Loading...</div>;
  if (!userData) {
    return (
      <div className="h-screen flex-center bg-black">
        <div className="p-8 bg-gray-900 rounded-2xl">
          <input value={username} onChange={(e) => setUsername(e.target.value)} placeholder="Galactic Username" className="w-64 p-4 bg-gray-800 rounded mb-4" onKeyPress={(e) => e.key === 'Enter' && loadUser(username)} />
          <button onClick={() => loadUser(username)} className="w-64 p-4 bg-purple-600 rounded">Join Universe</button>
        </div>
      </div>
    );
  }

  return (
    <div className="h-screen flex flex-col bg-black">
      <div className="p-4 bg-gray-900/80 flex justify-between">
        <div>👨‍🚀 {userData.username} | Points: {userData.points} | TOURS: {userData.tours}</div>
        <div className="flex items-center gap-2">
          <input type="number" value={monAmount} onChange={(e) => setMonAmount(Number(e.target.value))} className="w-20 p-2 bg-gray-800 rounded" />
          <motion.div onPointerDown={handleHoldStart} onPointerUp={handleHoldEnd} onPointerLeave={handleHoldEnd} onTouchStart={handleHoldStart} onTouchEnd={handleHoldEnd}>
            <div className="w-16 h-16 bg-green-500 rounded-full flex-center relative overflow-hidden">
              <svg className="w-16 h-16 absolute" viewBox="0 0 36 36">
                <motion.path d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831" fill="none" stroke="#10b981" strokeWidth="3" strokeDasharray={`${progress}, 100`} />
              </svg>
              <span className="z-10 text-xl">💎</span>
            </div>
            <p className="text-xs">Hold 2s Swap</p>
          </motion.div>
        </div>
      </div>
      <Stage width={dimensions.width} height={dimensions.height}>
        <Layer>
          {stars.map((s, i) => <KonvaStar key={i} x={s.x} y={s.y} numPoints={5} innerRadius={2} outerRadius={4} fill={s.color} opacity={0.8} />)}
          <Rect x={100} y={350} width={400} height={100} fill="#8B4513" />
          {drawAstronaut(userData.position.x, userData.position.y)}
          {userData.lasers.map((l, i) => <Line key={i} points={[l.x, l.y, l.x, l.y - 50]} stroke="#ff0000" strokeWidth={3} />)}
        </Layer>
      </Stage>
      {menuOpen && (
        <div className="absolute bottom-20 left-1/2 -translate-x-1/2 bg-gray-900 p-6 rounded-2xl">
          <button onClick={() => { saveUser({ ...userData!, lasers: [...userData!.lasers, { x: 300, y: 380 }], points: userData!.points + 100 }); setMenuOpen(false); }} className="p-4 bg-red-600 rounded">Laser (+100)</button>
          <button onClick={() => { saveUser({ ...userData!, ships: userData!.ships + 1, points: userData!.points + 200 }); setMenuOpen(false); }} className="p-4 bg-blue-600 rounded">Ship (+200)</button>
        </div>
      )}
      {!menuOpen && <button onClick={() => setMenuOpen(true)} className="absolute bottom-8 left-1/2 -translate-x-1/2 p-6 bg-teal-600 rounded-full">Explore & Build</button>}
    </div>
  );
}
EOL

# Footer
cat > src/app/components/Footer.tsx << 'EOL'
'use client';
import Link from 'next/link';
import { ExternalLink } from 'lucide-react';

export default function Footer() {
  return (
    <footer className="bg-gray-900/80 py-6">
      <div className="max-w-7xl mx-auto px-4 text-center">
        <p>© 2025 EmpowerTours.xyz</p>
        <a href="https://earvingallardo.com" target="_blank" className="text-blue-400">Earvin Gallardo <ExternalLink className="w-4 h-4 inline" /></a>
      </div>
    </footer>
  );
}
EOL

# About + Dedication
mkdir -p src/app/about
cat > src/app/about/page.tsx << 'EOL'
'use client';
import Link from 'next/link';
import { Heart, Star } from 'lucide-react';

export default function About() {
  return (
    <div className="min-h-screen bg-gray-950 py-12 px-4 text-center">
      <h1 className="text-4xl font-bold mb-6">About</h1>
      <section className="bg-gray-800 rounded-xl p-8 max-w-4xl mx-auto">
        <div className="flex justify-center mb-6">
          <Heart className="w-12 h-12 text-red-500 animate-pulse" />
          <Star className="w-12 h-12 text-yellow-400 ml-4" />
        </div>
        <h2 className="text-3xl mb-4 text-green-400">Dedication</h2>
        <blockquote className="text-2xl italic">
          To my children...<br /><br />
          Never stop creating,<br />
          never stop building,<br />
          never stop believing.
        </blockquote>
        <p className="mt-6">— Dad (Earvin Gallardo)</p>
      </section>
      <Link href="/" className="text-blue-400">← Game</Link>
    </div>
  );
}
EOL

echo "Galactic Code Injected!"
