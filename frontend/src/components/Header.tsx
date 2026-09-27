import React from 'react';
import { Search, Bell, Shield, Sparkles, CheckCircle } from 'lucide-react';
import { RoleCode } from '../types';

interface HeaderProps {
  currentRole: RoleCode;
  supabaseConnected: boolean;
  onQuickTrack: (token: string) => void;
}

export const Header: React.FC<HeaderProps> = ({
  currentRole,
  supabaseConnected,
  onQuickTrack,
}) => {
  return (
    <header className="h-16 bg-navy-900/80 backdrop-blur-md border-b border-slate-800/80 px-6 flex items-center justify-between sticky top-0 z-30 ml-64">
      {/* Search Bar */}
      <div className="flex items-center space-x-4 flex-1 max-w-lg">
        <div className="relative w-full">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 transform -translate-y-1/2" />
          <input
            type="text"
            placeholder="Search orders, customer phone, token (e.g. SARJAN-2026-8F42)..."
            onKeyDown={(e) => {
              if (e.key === 'Enter' && e.currentTarget.value.trim()) {
                onQuickTrack(e.currentTarget.value.trim());
              }
            }}
            className="w-full bg-slate-900/90 border border-slate-800 rounded-lg pl-9 pr-12 py-1.5 text-xs text-slate-200 placeholder-slate-500 focus:outline-none focus:border-cyan-500 focus:ring-1 focus:ring-cyan-500 transition-all"
          />
          <span className="absolute right-2.5 top-1/2 transform -translate-y-1/2 text-[10px] bg-slate-800 text-slate-400 px-1.5 py-0.5 rounded font-mono border border-slate-700">
            ↵ Enter
          </span>
        </div>
      </div>

      {/* Right Controls */}
      <div className="flex items-center space-x-4">
        {/* Backend / Supabase Status Indicator */}
        <div className="hidden sm:flex items-center space-x-2 px-2.5 py-1 rounded-full bg-slate-900 border border-slate-800 text-xs">
          <span className="relative flex h-2 w-2">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-cyan-400 opacity-75"></span>
            <span className="relative inline-flex rounded-full h-2 w-2 bg-cyan-500"></span>
          </span>
          <span className="text-slate-300 text-[11px] font-medium">
            FastAPI :8000
          </span>
          <span className="text-slate-600">|</span>
          <span className={`text-[11px] font-medium ${supabaseConnected ? 'text-emerald-400' : 'text-cyan-400'}`}>
            Supabase DB
          </span>
        </div>

        {/* Notifications Icon with active badge */}
        <div className="relative cursor-pointer p-2 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800/60 transition-colors">
          <Bell className="w-4 h-4" />
          <span className="absolute top-1 right-1 w-2 h-2 bg-cyan-400 rounded-full"></span>
        </div>

        {/* Current User Profile Chip */}
        <div className="flex items-center space-x-2.5 pl-2 border-l border-slate-800">
          <div className="w-8 h-8 rounded-full bg-gradient-to-tr from-cyan-600 to-blue-700 flex items-center justify-center text-xs font-bold text-white shadow-sm">
            AA
          </div>
          <div className="hidden md:block text-left">
            <div className="text-xs font-semibold text-slate-200 leading-tight">
              Abhishek Admin
            </div>
            <div className="text-[10px] text-cyan-400 flex items-center space-x-1">
              <Shield className="w-2.5 h-2.5" />
              <span>{currentRole}</span>
            </div>
          </div>
        </div>
      </div>
    </header>
  );
};
