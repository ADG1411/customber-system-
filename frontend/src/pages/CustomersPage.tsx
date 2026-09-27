import React, { useState } from 'react';
import { Users, Search, Phone, Mail, MapPin, Tag, ArrowUpRight } from 'lucide-react';
import { Customer } from '../types';

interface CustomersPageProps {
  customers: Customer[];
  onSelectCustomer?: (customer: Customer) => void;
}

export const CustomersPage: React.FC<CustomersPageProps> = ({ customers }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [tierFilter, setTierFilter] = useState('ALL');

  const filteredCustomers = customers.filter((c) => {
    const matchesSearch = 
      c.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      c.phone.includes(searchTerm) ||
      (c.email && c.email.toLowerCase().includes(searchTerm.toLowerCase()));
    const matchesTier = tierFilter === 'ALL' || c.tier === tierFilter;
    return matchesSearch && matchesTier;
  });

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white flex items-center space-x-2">
            <Users className="w-6 h-6 text-cyan-400" />
            <span>Customer Relationship Management (CRM)</span>
          </h1>
          <p className="text-xs text-slate-400 mt-1">
            Manage high-net-worth jewelry clients, order history, VIP tiers, and WhatsApp contact channels.
          </p>
        </div>

        <div className="flex items-center space-x-3">
          <div className="relative">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 transform -translate-y-1/2" />
            <input
              type="text"
              placeholder="Search clients..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="bg-slate-900 border border-slate-700 rounded-lg pl-9 pr-3 py-1.5 text-xs text-slate-200 placeholder-slate-500 focus:outline-none focus:border-cyan-400"
            />
          </div>

          <select
            value={tierFilter}
            onChange={(e) => setTierFilter(e.target.value)}
            className="bg-slate-900 border border-slate-700 text-xs text-slate-200 rounded-lg px-2.5 py-1.5 focus:outline-none focus:border-cyan-400"
          >
            <option value="ALL">All Tiers</option>
            <option value="VIP">VIP</option>
            <option value="PLATINUM">Platinum</option>
            <option value="GOLD">Gold</option>
            <option value="STANDARD">Standard</option>
          </select>
        </div>
      </div>

      {/* Customers Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filteredCustomers.map((cust) => (
          <div key={cust.id} className="glass-card p-5 rounded-xl border border-slate-800 space-y-4">
            <div className="flex items-start justify-between">
              <div>
                <h3 className="font-bold text-white text-base leading-tight">
                  {cust.name}
                </h3>
                {cust.company && (
                  <span className="text-xs text-cyan-400 font-medium block mt-0.5">
                    {cust.company}
                  </span>
                )}
              </div>
              <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                cust.tier === 'VIP' ? 'bg-amber-500/20 text-amber-300 border border-amber-500/40' :
                cust.tier === 'PLATINUM' ? 'bg-cyan-500/20 text-cyan-300 border border-cyan-500/40' :
                cust.tier === 'GOLD' ? 'bg-yellow-500/20 text-yellow-300' :
                'bg-slate-800 text-slate-400'
              }`}>
                {cust.tier}
              </span>
            </div>

            <div className="space-y-1.5 text-xs text-slate-300">
              <div className="flex items-center space-x-2">
                <Phone className="w-3.5 h-3.5 text-slate-500" />
                <span className="font-mono text-slate-200">{cust.phone}</span>
              </div>
              {cust.email && (
                <div className="flex items-center space-x-2">
                  <Mail className="w-3.5 h-3.5 text-slate-500" />
                  <span className="text-slate-300 truncate">{cust.email}</span>
                </div>
              )}
              {cust.city && (
                <div className="flex items-center space-x-2">
                  <MapPin className="w-3.5 h-3.5 text-slate-500" />
                  <span>{cust.city}, {cust.state}</span>
                </div>
              )}
            </div>

            {/* Tags */}
            {cust.tags && cust.tags.length > 0 && (
              <div className="flex flex-wrap gap-1 pt-1">
                {cust.tags.map((tag) => (
                  <span key={tag} className="text-[10px] px-2 py-0.5 rounded bg-slate-800/80 text-slate-300 border border-slate-700/60 flex items-center space-x-1">
                    <Tag className="w-2.5 h-2.5 text-cyan-400" />
                    <span>{tag}</span>
                  </span>
                ))}
              </div>
            )}

            {/* Metrics */}
            <div className="pt-3 border-t border-slate-800/80 flex items-center justify-between text-xs">
              <span className="text-slate-400">Total Spent:</span>
              <strong className="text-white font-mono">₹{cust.total_spent?.toLocaleString('en-IN')}</strong>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};
