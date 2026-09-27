import React from 'react';
import { 
  LayoutDashboard, 
  Users, 
  ShoppingBag, 
  CheckCircle2, 
  Gauge, 
  Layers, 
  Compass, 
  ShieldCheck, 
  Activity,
  Gem,
  UserCheck
} from 'lucide-react';
import { RoleCode } from '../types';

interface NavItem {
  id: string;
  label: string;
  icon: any;
  badge?: string;
  highlight?: boolean;
}

interface NavSection {
  title: string;
  items: NavItem[];
}

interface SidebarProps {
  currentTab: string;
  setCurrentTab: (tab: string) => void;
  currentRole: RoleCode;
  onSwitchRole: (role: RoleCode) => void;
}

export const Sidebar: React.FC<SidebarProps> = ({
  currentTab,
  setCurrentTab,
  currentRole,
  onSwitchRole
}) => {
  const navSections: NavSection[] = [
    {
      title: 'MANAGEMENT',
      items: [
        { id: 'dashboard', label: 'Admin Dashboard', icon: LayoutDashboard },
        { id: 'approvals', label: 'Approval Queue', icon: CheckCircle2, badge: '1 Conflict' },
        { id: 'capacity', label: 'Production Capacity', icon: Gauge },
      ]
    },
    {
      title: 'OPERATIONS & CRM',
      items: [
        { id: 'orders', label: 'Bespoke Orders', icon: ShoppingBag },
        { id: 'customers', label: 'Customers CRM', icon: Users },
        { id: 'tasks', label: 'Team Tasks', icon: Layers },
      ]
    },
    {
      title: 'CUSTOMER INTERFACE',
      items: [
        { id: 'track', label: 'Tracking Portal (/track)', icon: Compass, highlight: true },
      ]
    },
    {
      title: 'PLATFORM GOVERNANCE',
      items: [
        { id: 'audit', label: 'Audit Trail', icon: ShieldCheck },
        { id: 'health', label: 'Supabase & API Health', icon: Activity },
      ]
    }
  ];

  const rolesList: RoleCode[] = ['ADMIN', 'MANAGER', 'TEAM_MEMBER', 'SUPPORT_AGENT', 'CUSTOMER'];

  return (
    <aside className="w-64 bg-navy-900 border-r border-slate-800 flex flex-col h-screen fixed left-0 top-0 z-40 select-none">
      {/* Brand Header */}
      <div className="p-5 border-b border-slate-800/80 flex items-center justify-between">
        <div className="flex items-center space-x-3">
          <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-cyan-500 to-blue-600 flex items-center justify-center shadow-cyan-glow">
            <Gem className="w-5 h-5 text-navy-900" />
          </div>
          <div>
            <span className="font-luxury text-lg font-bold text-white tracking-wide block leading-tight">
              SARJAN
            </span>
            <span className="text-[10px] text-cyan-400 font-semibold tracking-widest uppercase">
              Fine Jewels SaaS
            </span>
          </div>
        </div>
      </div>

      {/* Tenant Pill */}
      <div className="px-4 py-2 bg-navy-800/50 border-b border-slate-800/60 flex items-center justify-between text-xs">
        <span className="text-slate-400 truncate font-medium">Sarjan Fine Jewels</span>
        <span className="px-1.5 py-0.5 rounded text-[10px] font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
          Multi-Tenant Active
        </span>
      </div>

      {/* Navigation Links */}
      <div className="flex-1 overflow-y-auto px-3 py-4 space-y-6">
        {navSections.map((section) => (
          <div key={section.title} className="space-y-1">
            <h4 className="px-3 text-[10px] font-bold tracking-wider text-slate-500 uppercase">
              {section.title}
            </h4>
            {section.items.map((item) => {
              const Icon = item.icon;
              const isActive = currentTab === item.id;
              return (
                <button
                  key={item.id}
                  onClick={() => setCurrentTab(item.id)}
                  className={`w-full flex items-center justify-between px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-150 ${
                    isActive
                      ? 'bg-cyan-500/10 text-cyan-400 border border-cyan-500/30 shadow-sm'
                      : item.highlight
                      ? 'text-cyan-300 hover:bg-slate-800/60'
                      : 'text-slate-300 hover:bg-slate-800/50 hover:text-white'
                  }`}
                >
                  <div className="flex items-center space-x-3">
                    <Icon className={`w-4 h-4 ${isActive ? 'text-cyan-400' : 'text-slate-400'}`} />
                    <span>{item.label}</span>
                  </div>
                  {item.badge && (
                    <span className="text-[10px] px-1.5 py-0.5 rounded-full font-semibold bg-amber-500/20 text-amber-300 border border-amber-500/30">
                      {item.badge}
                    </span>
                  )}
                </button>
              );
            })}
          </div>
        ))}
      </div>

      {/* Role Switcher Sandbox Footer */}
      <div className="p-3 bg-navy-800/90 border-t border-slate-800">
        <div className="flex items-center justify-between mb-2">
          <div className="flex items-center space-x-1.5 text-xs text-slate-400">
            <UserCheck className="w-3.5 h-3.5 text-cyan-400" />
            <span className="font-semibold text-slate-300">RBAC Simulator:</span>
          </div>
          <span className="text-[11px] font-bold text-cyan-400 bg-cyan-950/80 px-2 py-0.5 rounded border border-cyan-800/50">
            {currentRole}
          </span>
        </div>
        <select
          value={currentRole}
          onChange={(e) => onSwitchRole(e.target.value as RoleCode)}
          className="w-full bg-navy-900 border border-slate-700 text-slate-200 text-xs rounded-md px-2.5 py-1.5 focus:outline-none focus:border-cyan-500"
        >
          {rolesList.map((r) => (
            <option key={r} value={r}>
              Simulate: {r}
            </option>
          ))}
        </select>
      </div>
    </aside>
  );
};
