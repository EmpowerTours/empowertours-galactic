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
