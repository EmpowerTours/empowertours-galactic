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
