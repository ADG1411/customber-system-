import React, { useState, useEffect } from 'react';
import { Sidebar } from './components/Sidebar';
import { Header } from './components/Header';
import { AdminDashboard } from './pages/AdminDashboard';
import { CustomerTracking } from './pages/CustomerTracking';
import { SystemHealth } from './pages/SystemHealth';
import { CustomersPage } from './pages/CustomersPage';
import { Order, Approval, CapacityRecord, AuditLog, Customer, RoleCode, WorkflowTask } from './types';
import { api } from './lib/api';

export function App() {
  const [currentTab, setCurrentTab] = useState<string>('dashboard');
  const [currentRole, setCurrentRole] = useState<RoleCode>('ADMIN');
  const [trackingLookupToken, setTrackingLookupToken] = useState<string>('SARJAN-2026-8F42');
  
  // Data states
  const [orders, setOrders] = useState<Order[]>([]);
  const [approvals, setApprovals] = useState<Approval[]>([]);
  const [capacity, setCapacity] = useState<CapacityRecord | null>(null);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [tasks, setTasks] = useState<WorkflowTask[]>([]);
  const [auditLogs, setAuditLogs] = useState<AuditLog[]>([]);
  const [supabaseConnected, setSupabaseConnected] = useState<boolean>(true);
  const [loading, setLoading] = useState<boolean>(true);

  // Initial load
  const loadData = async () => {
    try {
      const [healthRes, ordersData, approvalsData, capacityData, customersData, logsData, tasksData] = await Promise.all([
        api.getHealth(),
        api.getOrders(),
        api.getApprovals(),
        api.getCapacity(),
        api.getCustomers(),
        api.getAuditLogs(),
        api.getTasks()
      ]);

      setSupabaseConnected(healthRes.supabase.is_live_connected || true);
      setOrders(ordersData);
      setApprovals(approvalsData);
      setCapacity(capacityData.current);
      setCustomers(customersData);
      setAuditLogs(logsData);
      setTasks(tasksData);
    } catch (err) {
      console.error('Failed to load initial dataset:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  // Action handlers
  const handleApprovalAction = async (
    approvalId: string,
    action: 'APPROVE' | 'HOLD' | 'REJECT' | 'SCHEDULE' | 'SPLIT'
  ) => {
    try {
      await api.executeApprovalAction(approvalId, action);
      // Reload updated states
      await loadData();
    } catch (err: any) {
      alert(err.message || 'Action failed');
    }
  };

  const handleAdvanceOrderStatus = async (orderId: string, nextStatus: string) => {
    try {
      const res = await api.updateOrderStatus(orderId, nextStatus);
      if (res.approval_required) {
        alert('Capacity conflict detected! Order has been placed in the Production Approval Queue.');
      }
      await loadData();
    } catch (err: any) {
      alert(err.message || 'Status update failed');
    }
  };

  const handleSwitchRole = async (role: RoleCode) => {
    try {
      setCurrentRole(role);
      await api.switchRole(role);
    } catch (err) {
      console.error(err);
    }
  };

  const handleQuickTrack = (token: string) => {
    setTrackingLookupToken(token);
    setCurrentTab('track');
  };

  return (
    <div className="min-h-screen bg-[#07111F] text-slate-100 flex flex-col font-sans">
      {/* Sidebar Navigation */}
      <Sidebar
        currentTab={currentTab}
        setCurrentTab={setCurrentTab}
        currentRole={currentRole}
        onSwitchRole={handleSwitchRole}
      />

      {/* Header */}
      <Header
        currentRole={currentRole}
        supabaseConnected={supabaseConnected}
        onQuickTrack={handleQuickTrack}
      />

      {/* Main Content Area */}
      <main className="ml-64 flex-1 p-6 overflow-y-auto">
        {loading ? (
          <div className="h-64 flex flex-col items-center justify-center space-y-3 text-cyan-400">
            <div className="w-8 h-8 border-2 border-cyan-400 border-t-transparent rounded-full animate-spin"></div>
            <span className="text-xs font-medium">Connecting to Sarjan Platform...</span>
          </div>
        ) : (
          <>
            {currentTab === 'dashboard' && (
              <AdminDashboard
                orders={orders}
                approvals={approvals}
                capacity={capacity}
                auditLogs={auditLogs}
                onApprovalAction={handleApprovalAction}
                onAdvanceOrderStatus={handleAdvanceOrderStatus}
                onNavigateToTracking={handleQuickTrack}
              />
            )}

            {currentTab === 'approvals' && (
              <AdminDashboard
                orders={orders}
                approvals={approvals}
                capacity={capacity}
                auditLogs={auditLogs}
                onApprovalAction={handleApprovalAction}
                onAdvanceOrderStatus={handleAdvanceOrderStatus}
                onNavigateToTracking={handleQuickTrack}
              />
            )}

            {currentTab === 'capacity' && (
              <AdminDashboard
                orders={orders}
                approvals={approvals}
                capacity={capacity}
                auditLogs={auditLogs}
                onApprovalAction={handleApprovalAction}
                onAdvanceOrderStatus={handleAdvanceOrderStatus}
                onNavigateToTracking={handleQuickTrack}
              />
            )}

            {currentTab === 'orders' && (
              <AdminDashboard
                orders={orders}
                approvals={approvals}
                capacity={capacity}
                auditLogs={auditLogs}
                onApprovalAction={handleApprovalAction}
                onAdvanceOrderStatus={handleAdvanceOrderStatus}
                onNavigateToTracking={handleQuickTrack}
              />
            )}

            {currentTab === 'customers' && (
              <CustomersPage customers={customers} />
            )}

            {currentTab === 'tasks' && (
              <div className="space-y-6">
                <div className="flex items-center justify-between">
                  <h1 className="text-2xl font-bold text-white">Team Tasks & Assignments</h1>
                  <span className="text-xs text-slate-400">{tasks.length} Active Tasks</span>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                  {tasks.map((task) => (
                    <div key={task.id} className="glass-panel p-5 rounded-xl border border-slate-800 space-y-3">
                      <div className="flex items-center justify-between">
                        <span className="text-xs font-mono font-bold text-cyan-400">{task.task_number}</span>
                        <span className="text-[10px] px-2 py-0.5 rounded font-bold bg-slate-800 text-slate-300">{task.priority}</span>
                      </div>
                      <h4 className="font-bold text-sm text-white">{task.title}</h4>
                      <p className="text-xs text-slate-400">{task.description}</p>
                      <div className="pt-2 border-t border-slate-800 text-xs flex justify-between text-slate-400">
                        <span>Assigned: <strong className="text-slate-200">{task.assigned_to}</strong></span>
                        <span className="text-cyan-400 font-semibold">{task.status}</span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {currentTab === 'track' && (
              <CustomerTracking initialToken={trackingLookupToken} />
            )}

            {currentTab === 'audit' && (
              <div className="glass-panel p-6 rounded-xl border border-slate-800 space-y-4">
                <h1 className="text-xl font-bold text-white">Platform Audit Log & Traceability</h1>
                <div className="divide-y divide-slate-800 text-xs">
                  {auditLogs.map((log) => (
                    <div key={log.id} className="py-3 flex justify-between items-start">
                      <div>
                        <span className="font-mono text-cyan-400 font-bold mr-2">[{log.action}]</span>
                        <span className="text-slate-200">{log.details}</span>
                        <span className="text-slate-500 block text-[11px] mt-0.5">By: {log.user_email}</span>
                      </div>
                      <span className="text-slate-500 font-mono text-[10px] shrink-0 ml-4">
                        {new Date(log.created_at).toLocaleString()}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {currentTab === 'health' && (
              <SystemHealth />
            )}
          </>
        )}
      </main>
    </div>
  );
}

export default App;
