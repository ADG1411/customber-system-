import React, { useState } from 'react';
import { 
  ShoppingBag, 
  Users, 
  Gauge, 
  CheckCircle2, 
  AlertTriangle, 
  Clock, 
  ArrowUpRight, 
  Layers, 
  ShieldCheck,
  Split,
  Check,
  Pause,
  X
} from 'lucide-react';
import { Order, Approval, CapacityRecord, AuditLog } from '../types';

interface AdminDashboardProps {
  orders: Order[];
  approvals: Approval[];
  capacity: CapacityRecord | null;
  auditLogs: AuditLog[];
  onApprovalAction: (approvalId: string, action: 'APPROVE' | 'HOLD' | 'REJECT' | 'SCHEDULE' | 'SPLIT') => void;
  onAdvanceOrderStatus: (orderId: string, nextStatus: string) => void;
  onNavigateToTracking: (token: string) => void;
}

export const AdminDashboard: React.FC<AdminDashboardProps> = ({
  orders,
  approvals,
  capacity,
  auditLogs,
  onApprovalAction,
  onAdvanceOrderStatus,
  onNavigateToTracking,
}) => {
  const [selectedApproval, setSelectedApproval] = useState<Approval | null>(null);

  const pendingApprovalsCount = approvals.filter(a => a.status === 'PENDING').length;
  const totalRevenue = orders.reduce((sum, o) => sum + (o.paid_amount || 0), 0);
  const usedCap = capacity ? capacity.used_capacity_units : 50;
  const totalCap = capacity ? capacity.total_capacity_units : 100;
  const availCap = capacity ? capacity.available_capacity_units : 50;
  const capacityPercent = Math.round((usedCap / totalCap) * 100);

  return (
    <div className="space-y-6">
      {/* Page Title & Status Banner */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-white flex items-center space-x-2">
            <span>Executive Operations & Production Hub</span>
          </h1>
          <p className="text-xs text-slate-400 mt-1">
            Real-time jewelry atelier management, simultaneous capacity balancing, and customer order workflow.
          </p>
        </div>
        <div className="flex items-center space-x-2">
          <span className="px-3 py-1 bg-cyan-950/60 border border-cyan-500/30 rounded-lg text-cyan-400 text-xs font-semibold flex items-center space-x-1.5">
            <span className="w-2 h-2 rounded-full bg-cyan-400 animate-pulse"></span>
            <span>Production Engine Active</span>
          </span>
        </div>
      </div>

      {/* KPI Cards Row */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Card 1: Revenue & Orders */}
        <div className="glass-panel p-5 rounded-xl border border-slate-800 relative overflow-hidden">
          <div className="flex items-center justify-between text-slate-400 text-xs font-medium">
            <span>Total Collected Revenue</span>
            <div className="p-2 rounded-lg bg-emerald-500/10 text-emerald-400">
              <ShoppingBag className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3 text-2xl font-bold text-white font-mono">
            ₹{totalRevenue.toLocaleString('en-IN')}
          </div>
          <div className="mt-2 flex items-center justify-between text-xs text-slate-400">
            <span>{orders.length} Bespoke Orders</span>
            <span className="text-emerald-400 flex items-center font-medium">
              +14.2% <ArrowUpRight className="w-3 h-3 ml-0.5" />
            </span>
          </div>
        </div>

        {/* Card 2: Production Bench Capacity */}
        <div className="glass-panel p-5 rounded-xl border border-slate-800 relative overflow-hidden">
          <div className="flex items-center justify-between text-slate-400 text-xs font-medium">
            <span>Today's Bench Capacity</span>
            <div className="p-2 rounded-lg bg-cyan-500/10 text-cyan-400">
              <Gauge className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3 text-2xl font-bold text-white font-mono flex items-baseline space-x-2">
            <span>{usedCap}</span>
            <span className="text-sm font-normal text-slate-400">/ {totalCap} units ({capacityPercent}%)</span>
          </div>
          <div className="w-full bg-slate-800 h-1.5 rounded-full mt-3 overflow-hidden">
            <div 
              className={`h-full rounded-full transition-all duration-500 ${
                capacityPercent >= 80 ? 'bg-amber-400' : 'bg-cyan-400'
              }`}
              style={{ width: `${capacityPercent}%` }}
            ></div>
          </div>
          <div className="mt-2 flex justify-between text-[11px] text-slate-400">
            <span>Available: <strong className="text-cyan-400">{availCap} units</strong></span>
            <span>Allocated: <strong>{usedCap} units</strong></span>
          </div>
        </div>

        {/* Card 3: Pending Approvals Alert */}
        <div className="glass-panel p-5 rounded-xl border border-slate-800 relative overflow-hidden">
          <div className="flex items-center justify-between text-slate-400 text-xs font-medium">
            <span>Production Approval Queue</span>
            <div className="p-2 rounded-lg bg-amber-500/10 text-amber-400">
              <AlertTriangle className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3 text-2xl font-bold text-amber-400 font-mono">
            {pendingApprovalsCount} Conflict
          </div>
          <div className="mt-2 text-xs text-slate-400">
            Simultaneous order limit reached. Action required.
          </div>
        </div>

        {/* Card 4: Customers & VIPs */}
        <div className="glass-panel p-5 rounded-xl border border-slate-800 relative overflow-hidden">
          <div className="flex items-center justify-between text-slate-400 text-xs font-medium">
            <span>Active CRM Clients</span>
            <div className="p-2 rounded-lg bg-blue-500/10 text-blue-400">
              <Users className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3 text-2xl font-bold text-white font-mono">
            5 Clients
          </div>
          <div className="mt-2 flex items-center justify-between text-xs text-slate-400">
            <span className="text-cyan-400 font-semibold">2 VIP / Platinum</span>
            <span>1 WhatsApp lead</span>
          </div>
        </div>
      </div>

      {/* SECTION 24: Simultaneous Order Approval Queue */}
      <div className="glass-panel rounded-xl border border-slate-800 p-6">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between pb-4 border-b border-slate-800/80 gap-2">
          <div>
            <div className="flex items-center space-x-2">
              <span className="p-1 rounded bg-amber-500/20 text-amber-400">
                <CheckCircle2 className="w-4 h-4" />
              </span>
              <h2 className="text-base font-bold text-white">
                Simultaneous Order Approval & Capacity Balancing
              </h2>
            </div>
            <p className="text-xs text-slate-400 mt-1">
              Order A and Order B arrived simultaneously. Order A consumed 50 capacity units. Order B is waiting for admin resolution.
            </p>
          </div>
          <span className="text-xs font-semibold px-2.5 py-1 rounded bg-slate-800 text-slate-300 border border-slate-700">
            Simultaneous Conflict Demo (Prompt §24 & §25)
          </span>
        </div>

        <div className="overflow-x-auto mt-4">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="border-b border-slate-800 text-slate-400 uppercase tracking-wider text-[11px]">
                <th className="py-3 px-3">Order</th>
                <th className="py-3 px-3">Customer</th>
                <th className="py-3 px-3">Required Qty</th>
                <th className="py-3 px-3">Order Value</th>
                <th className="py-3 px-3">Available Bench</th>
                <th className="py-3 px-3">Status</th>
                <th className="py-3 px-3 text-right">Admin Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/60 font-sans">
              {approvals.map((appr) => {
                const isPending = appr.status === 'PENDING';
                return (
                  <tr key={appr.id} className="hover:bg-slate-800/30 transition-colors">
                    <td className="py-3.5 px-3 font-semibold text-cyan-400 font-mono">
                      {appr.order_number}
                    </td>
                    <td className="py-3.5 px-3 text-slate-200">
                      {appr.customer_name}
                    </td>
                    <td className="py-3.5 px-3 font-medium text-slate-200">
                      {appr.quantity} pieces
                    </td>
                    <td className="py-3.5 px-3 font-mono text-slate-300">
                      ₹{appr.value?.toLocaleString('en-IN')}
                    </td>
                    <td className="py-3.5 px-3">
                      <span className={`px-2 py-0.5 rounded text-[11px] font-bold ${
                        appr.available_capacity_units > 0 
                          ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20' 
                          : 'bg-red-500/10 text-red-400 border border-red-500/20'
                      }`}>
                        {appr.available_capacity_units} units available
                      </span>
                    </td>
                    <td className="py-3.5 px-3">
                      <span className={`px-2.5 py-1 rounded-full text-[11px] font-bold ${
                        appr.status === 'APPROVED' ? 'bg-emerald-500/20 text-emerald-300' :
                        appr.status === 'PENDING' ? 'bg-amber-500/20 text-amber-300 animate-pulse' :
                        appr.status === 'SPLIT' ? 'bg-blue-500/20 text-blue-300' :
                        appr.status === 'HOLD' ? 'bg-purple-500/20 text-purple-300' :
                        'bg-slate-800 text-slate-400'
                      }`}>
                        {appr.status}
                      </span>
                    </td>
                    <td className="py-3.5 px-3 text-right">
                      {isPending ? (
                        <div className="flex items-center justify-end space-x-1.5">
                          <button
                            onClick={() => onApprovalAction(appr.id, 'APPROVE')}
                            title="Force Approve"
                            className="px-2.5 py-1 rounded bg-emerald-600 hover:bg-emerald-500 text-white font-medium text-[11px] transition-all flex items-center space-x-1 shadow-sm"
                          >
                            <Check className="w-3 h-3" />
                            <span>Approve</span>
                          </button>
                          <button
                            onClick={() => onApprovalAction(appr.id, 'SPLIT')}
                            title="Split Order: 25 Now / 25 Later (§25)"
                            className="px-2.5 py-1 rounded bg-blue-600 hover:bg-blue-500 text-white font-medium text-[11px] transition-all flex items-center space-x-1"
                          >
                            <Split className="w-3 h-3" />
                            <span>Split Order</span>
                          </button>
                          <button
                            onClick={() => onApprovalAction(appr.id, 'HOLD')}
                            title="Place on Hold"
                            className="px-2 py-1 rounded bg-slate-700 hover:bg-slate-600 text-slate-300 font-medium text-[11px] transition-all"
                          >
                            Hold
                          </button>
                        </div>
                      ) : (
                        <span className="text-[11px] text-slate-500 italic">
                          Action completed ({appr.status})
                        </span>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Orders Workflow Pipeline & Timeline */}
      <div className="glass-panel rounded-xl border border-slate-800 p-6">
        <div className="flex items-center justify-between pb-4 border-b border-slate-800/80">
          <div>
            <h2 className="text-base font-bold text-white flex items-center space-x-2">
              <Layers className="w-4 h-4 text-cyan-400" />
              <span>Live Bespoke Orders Workflow Pipeline</span>
            </h2>
            <p className="text-xs text-slate-400 mt-0.5">
              Track manufacturing lifecycle across casting, CAD, and quality control.
            </p>
          </div>
          <span className="text-xs text-slate-400">
            Total {orders.length} Orders
          </span>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mt-5">
          {orders.map((order) => {
            const isDelivered = order.status === 'DELIVERED';
            const isPendingApproval = order.status === 'APPROVAL_PENDING';
            
            return (
              <div 
                key={order.id} 
                className="glass-card p-4 rounded-xl border border-slate-800/80 hover:border-cyan-500/40 transition-all flex flex-col justify-between"
              >
                <div>
                  <div className="flex items-center justify-between">
                    <span className="font-mono text-xs font-bold text-cyan-400">
                      {order.order_number}
                    </span>
                    <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                      order.priority === 'URGENT' ? 'bg-red-500/20 text-red-300' :
                      order.priority === 'HIGH' ? 'bg-amber-500/20 text-amber-300' :
                      'bg-slate-700/60 text-slate-300'
                    }`}>
                      {order.priority}
                    </span>
                  </div>

                  <h3 className="font-semibold text-slate-100 text-sm mt-2 leading-snug">
                    {order.product_name}
                  </h3>

                  <div className="mt-2 text-xs text-slate-400 space-y-1">
                    <div className="flex justify-between">
                      <span>Customer:</span>
                      <strong className="text-slate-200">{order.customer_name}</strong>
                    </div>
                    <div className="flex justify-between">
                      <span>Quantity:</span>
                      <strong className="text-slate-200">{order.quantity} units</strong>
                    </div>
                    <div className="flex justify-between">
                      <span>Value:</span>
                      <strong className="text-slate-200 font-mono">₹{order.total?.toLocaleString('en-IN')}</strong>
                    </div>
                  </div>

                  {/* Tracking Token Badge */}
                  {order.tracking_token && (
                    <div className="mt-3 p-2 rounded-lg bg-navy-900/90 border border-slate-800 flex items-center justify-between">
                      <span className="text-[10px] text-slate-400">Token:</span>
                      <button
                        onClick={() => onNavigateToTracking(order.tracking_token!)}
                        className="text-xs font-mono font-bold text-cyan-400 hover:underline flex items-center space-x-1"
                      >
                        <span>{order.tracking_token}</span>
                        <ArrowUpRight className="w-3 h-3" />
                      </button>
                    </div>
                  )}
                </div>

                {/* Workflow Progression Controls */}
                <div className="mt-4 pt-3 border-t border-slate-800/80">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-[10px] uppercase font-bold text-slate-400">
                      Stage:
                    </span>
                    <span className={`text-[11px] font-bold px-2 py-0.5 rounded ${
                      order.status === 'PRODUCTION' ? 'bg-cyan-500/20 text-cyan-300 border border-cyan-500/30' :
                      order.status === 'QUALITY_CHECK' ? 'bg-purple-500/20 text-purple-300' :
                      order.status === 'DELIVERED' ? 'bg-emerald-500/20 text-emerald-300' :
                      'bg-slate-800 text-slate-300'
                    }`}>
                      {order.status}
                    </span>
                  </div>

                  {!isDelivered && !isPendingApproval && (
                    <div className="flex space-x-1.5 mt-2">
                      {order.status === 'DESIGN' && (
                        <button
                          onClick={() => onAdvanceOrderStatus(order.id, 'PRODUCTION')}
                          className="w-full py-1.5 rounded bg-cyan-600 hover:bg-cyan-500 text-navy-900 font-bold text-xs transition-colors"
                        >
                          Advance to Production →
                        </button>
                      )}
                      {order.status === 'PRODUCTION' && (
                        <button
                          onClick={() => onAdvanceOrderStatus(order.id, 'QUALITY_CHECK')}
                          className="w-full py-1.5 rounded bg-cyan-600 hover:bg-cyan-500 text-navy-900 font-bold text-xs transition-colors"
                        >
                          Pass to Quality Check →
                        </button>
                      )}
                      {order.status === 'QUALITY_CHECK' && (
                        <button
                          onClick={() => onAdvanceOrderStatus(order.id, 'PACKAGING')}
                          className="w-full py-1.5 rounded bg-cyan-600 hover:bg-cyan-500 text-navy-900 font-bold text-xs transition-colors"
                        >
                          Send to Packaging →
                        </button>
                      )}
                      {order.status === 'PACKAGING' && (
                        <button
                          onClick={() => onAdvanceOrderStatus(order.id, 'DELIVERED')}
                          className="w-full py-1.5 rounded bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-xs transition-colors"
                        >
                          Mark as Delivered ✓
                        </button>
                      )}
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Audit Log Stream */}
      <div className="glass-panel rounded-xl border border-slate-800 p-6">
        <div className="flex items-center justify-between pb-3 border-b border-slate-800/80">
          <div className="flex items-center space-x-2">
            <ShieldCheck className="w-4 h-4 text-emerald-400" />
            <h2 className="text-sm font-bold text-white">
              Immutable Governance & System Audit Trail (§34)
            </h2>
          </div>
          <span className="text-[11px] text-slate-500">Live Timestamped</span>
        </div>

        <div className="divide-y divide-slate-800/50 mt-3 text-xs">
          {auditLogs.slice(0, 5).map((log) => (
            <div key={log.id} className="py-2.5 flex items-start justify-between">
              <div>
                <span className="font-mono text-cyan-400 font-semibold mr-2">
                  [{log.action}]
                </span>
                <span className="text-slate-300">
                  {log.details}
                </span>
              </div>
              <span className="text-[10px] text-slate-500 font-mono shrink-0 ml-4">
                {new Date(log.created_at).toLocaleTimeString()}
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
