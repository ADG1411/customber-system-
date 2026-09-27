import React, { useState, useEffect } from 'react';
import { 
  Search, 
  CheckCircle2, 
  Clock, 
  Circle, 
  ShieldCheck, 
  Package, 
  Calendar, 
  DollarSign, 
  Sparkles,
  ArrowRight,
  Gem
} from 'lucide-react';
import { TrackingData } from '../types';
import { api } from '../lib/api';

interface CustomerTrackingProps {
  initialToken?: string;
}

export const CustomerTracking: React.FC<CustomerTrackingProps> = ({ initialToken = 'SARJAN-2026-8F42' }) => {
  const [tokenInput, setTokenInput] = useState(initialToken);
  const [trackingData, setTrackingData] = useState<TrackingData | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchTracking = async (tokenToLookup: string) => {
    if (!tokenToLookup.trim()) return;
    setLoading(true);
    setError(null);
    try {
      const data = await api.trackOrder(tokenToLookup.trim());
      setTrackingData(data);
    } catch (err: any) {
      setError(err.message || 'Failed to retrieve order. Please verify your tracking token.');
      setTrackingData(null);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (initialToken) {
      setTokenInput(initialToken);
      fetchTracking(initialToken);
    }
  }, [initialToken]);

  const sampleTokens = [
    { token: 'SARJAN-2026-8F42', label: 'Production (50 units)' },
    { token: 'SARJAN-2026-9A11', label: 'Approval Conflict (50 units)' },
    { token: 'SARJAN-2026-3C77', label: 'CAD Design (1 unit)' },
  ];

  return (
    <div className="max-w-4xl mx-auto space-y-8 py-4">
      {/* Hero Tracking Search Box */}
      <div className="glass-panel p-8 rounded-2xl border border-slate-800 text-center relative overflow-hidden shadow-glass">
        <div className="inline-flex p-3 rounded-2xl bg-cyan-500/10 border border-cyan-500/30 text-cyan-400 mb-4 shadow-cyan-glow">
          <Gem className="w-8 h-8" />
        </div>
        <h1 className="font-luxury text-3xl font-bold text-white tracking-wide">
          Bespoke Jewelry Tracking Portal
        </h1>
        <p className="text-xs text-slate-400 mt-2 max-w-md mx-auto">
          Enter your unique non-sequential tracking token to monitor CAD design, bench casting, and hallmarking in real-time.
        </p>

        <form 
          onSubmit={(e) => { e.preventDefault(); fetchTracking(tokenInput); }}
          className="mt-6 flex flex-col sm:flex-row items-center justify-center gap-2 max-w-lg mx-auto"
        >
          <div className="relative w-full">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 transform -translate-y-1/2" />
            <input
              type="text"
              value={tokenInput}
              onChange={(e) => setTokenInput(e.target.value)}
              placeholder="e.g. SARJAN-2026-8F42"
              className="w-full bg-slate-900 border border-slate-700 rounded-xl pl-9 pr-4 py-3 text-sm font-mono text-cyan-400 placeholder-slate-500 focus:outline-none focus:border-cyan-400 focus:ring-1 focus:ring-cyan-400"
            />
          </div>
          <button
            type="submit"
            disabled={loading}
            className="w-full sm:w-auto px-6 py-3 rounded-xl bg-gradient-to-r from-cyan-500 to-blue-600 hover:from-cyan-400 hover:to-blue-500 text-navy-900 font-bold text-xs uppercase tracking-wider transition-all shadow-md disabled:opacity-50 shrink-0"
          >
            {loading ? 'Verifying...' : 'Track Order'}
          </button>
        </form>

        {/* Quick Sample Tokens */}
        <div className="mt-4 flex flex-wrap items-center justify-center gap-2 text-xs">
          <span className="text-slate-500">Try sample tokens:</span>
          {sampleTokens.map((s) => (
            <button
              key={s.token}
              onClick={() => {
                setTokenInput(s.token);
                fetchTracking(s.token);
              }}
              className="px-2.5 py-1 rounded-md bg-slate-800/80 hover:bg-slate-700 text-cyan-300 font-mono text-[11px] border border-slate-700"
            >
              {s.token} <span className="text-slate-400 font-sans">({s.label})</span>
            </button>
          ))}
        </div>
      </div>

      {/* Error Message */}
      {error && (
        <div className="p-4 rounded-xl bg-red-500/10 border border-red-500/30 text-red-300 text-xs text-center font-medium">
          {error}
        </div>
      )}

      {/* Tracking Results Card */}
      {trackingData && (
        <div className="glass-panel rounded-2xl border border-slate-800 overflow-hidden space-y-6">
          {/* Order Header Summary Banner */}
          <div className="bg-gradient-to-r from-navy-800 to-slate-900 p-6 border-b border-slate-800 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
            <div>
              <div className="flex items-center space-x-2">
                <span className="text-xs font-mono font-bold px-2 py-0.5 rounded bg-cyan-500/20 text-cyan-400 border border-cyan-500/40">
                  {trackingData.order_number}
                </span>
                <span className="text-xs text-slate-400 font-mono">
                  Token: {trackingData.tracking_token}
                </span>
              </div>
              <h2 className="text-xl font-bold text-white mt-1">
                {trackingData.product_name}
              </h2>
              <p className="text-xs text-slate-400">
                Customer: <strong className="text-slate-200">{trackingData.customer_name}</strong> • Quantity: <strong className="text-slate-200">{trackingData.quantity} pieces</strong>
              </p>
            </div>

            <div className="text-left md:text-right">
              <span className="text-xs text-slate-400 block">Total Order Value</span>
              <span className="text-2xl font-bold text-white font-mono">
                ₹{trackingData.total.toLocaleString('en-IN')}
              </span>
              <div className="text-[11px] text-slate-400 mt-0.5 space-x-2">
                <span>Paid: <strong className="text-emerald-400">₹{trackingData.paid_amount.toLocaleString('en-IN')}</strong></span>
                <span>Balance: <strong className="text-amber-400">₹{trackingData.remaining_amount.toLocaleString('en-IN')}</strong></span>
              </div>
            </div>
          </div>

          {/* Section 16: Visual 9-Stage Luxury Timeline */}
          <div className="p-6">
            <h3 className="text-sm font-bold uppercase tracking-wider text-slate-300 mb-6 flex items-center space-x-2">
              <Sparkles className="w-4 h-4 text-cyan-400" />
              <span>Real-Time Production & Delivery Progression</span>
            </h3>

            <div className="relative pl-6 space-y-8 before:absolute before:left-3 before:top-2 before:bottom-2 before:w-0.5 before:bg-slate-800">
              {trackingData.stages.map((stage, idx) => {
                const isCompleted = stage.state === 'COMPLETED';
                const isCurrent = stage.state === 'CURRENT';
                const isUpcoming = stage.state === 'UPCOMING';

                return (
                  <div key={stage.key} className="relative flex items-start space-x-4">
                    {/* Node Dot / Icon */}
                    <div className="absolute -left-6 top-0.5">
                      {isCompleted ? (
                        <div className="w-6 h-6 rounded-full bg-emerald-500/20 text-emerald-400 flex items-center justify-center border border-emerald-500/50 shadow-sm">
                          <CheckCircle2 className="w-4 h-4" />
                        </div>
                      ) : isCurrent ? (
                        <div className="w-6 h-6 rounded-full bg-cyan-500/20 text-cyan-400 flex items-center justify-center border border-cyan-400 shadow-cyan-glow">
                          <span className="w-2.5 h-2.5 rounded-full bg-cyan-400 animate-ping"></span>
                        </div>
                      ) : (
                        <div className="w-6 h-6 rounded-full bg-slate-900 text-slate-600 flex items-center justify-center border border-slate-800">
                          <Circle className="w-3 h-3" />
                        </div>
                      )}
                    </div>

                    {/* Stage Details */}
                    <div className="pl-4">
                      <div className="flex items-center space-x-2">
                        <span className={`text-sm font-bold ${
                          isCompleted ? 'text-emerald-400' :
                          isCurrent ? 'text-cyan-400' :
                          'text-slate-500'
                        }`}>
                          {stage.label}
                        </span>
                        {isCurrent && (
                          <span className="text-[10px] font-semibold px-2 py-0.5 rounded-full bg-cyan-500/20 text-cyan-300 border border-cyan-500/40 uppercase">
                            Currently In Progress
                          </span>
                        )}
                        {isCompleted && (
                          <span className="text-[10px] font-semibold text-emerald-400/80">
                            Completed ✓
                          </span>
                        )}
                      </div>
                      <p className="text-xs text-slate-400 mt-1">
                        {stage.desc}
                      </p>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Customer Privacy Guarantee Badge */}
          <div className="bg-navy-900/60 p-4 border-t border-slate-800 flex items-center justify-between text-[11px] text-slate-400">
            <div className="flex items-center space-x-2">
              <ShieldCheck className="w-4 h-4 text-emerald-400" />
              <span>
                Authorized Customer Privacy Guard (§53) • Confidential client token verification.
              </span>
            </div>
            <span>Sarjan Atelier Certified</span>
          </div>
        </div>
      )}
    </div>
  );
};
