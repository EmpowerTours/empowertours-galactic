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
