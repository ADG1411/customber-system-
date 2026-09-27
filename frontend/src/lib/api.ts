import { Company, Customer, Order, Approval, CapacityRecord, WorkflowTask, AuditLog, TrackingData, RoleCode } from '../types';

const API_BASE = '/api/v1';

async function handleResponse<T>(res: Response): Promise<T> {
  const json = await res.json();
  if (!res.ok || json.success === false) {
    const errorMsg = json.error?.message || json.message || `Request failed with status ${res.status}`;
    throw new Error(errorMsg);
  }
  return json.data as T;
}

export const api = {
  async getHealth() {
    const res = await fetch(`${API_BASE}/health`);
    return handleResponse<{
      service: string;
      version: string;
      environment: string;
      supabase: {
        is_live_connected: boolean;
        mode: string;
        total_records: number;
        connection_error?: string;
      };
    }>(res);
  },

  async getCurrentCompany() {
    const res = await fetch(`${API_BASE}/companies/current`);
    return handleResponse<Company>(res);
  },

  async getCustomers(search?: string, tier?: string) {
    const params = new URLSearchParams();
    if (search) params.append('search', search);
    if (tier) params.append('tier', tier);
    const res = await fetch(`${API_BASE}/customers?${params.toString()}`);
    return handleResponse<Customer[]>(res);
  },

  async getOrders(status?: string, priority?: string) {
    const params = new URLSearchParams();
    if (status) params.append('status', status);
    if (priority) params.append('priority', priority);
    const res = await fetch(`${API_BASE}/orders?${params.toString()}`);
    return handleResponse<Order[]>(res);
  },

  async updateOrderStatus(orderId: string, status: string, reason?: string) {
    const res = await fetch(`${API_BASE}/orders/${orderId}/status`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ status, reason }),
    });
    return handleResponse<{ order: Order; approval_required?: boolean }>(res);
  },

  async getApprovals(status?: string) {
    const params = new URLSearchParams();
    if (status) params.append('status', status);
    const res = await fetch(`${API_BASE}/approvals?${params.toString()}`);
    return handleResponse<Approval[]>(res);
  },

  async executeApprovalAction(
    approvalId: string,
    action: 'APPROVE' | 'HOLD' | 'REJECT' | 'SCHEDULE' | 'SPLIT',
    decisionNotes?: string,
    splitQuantityNow?: number
  ) {
    const res = await fetch(`${API_BASE}/approvals/${approvalId}/action`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        action,
        decision_notes: decisionNotes,
        split_quantity_now: splitQuantityNow,
      }),
    });
    return handleResponse<{ approval: Approval; order?: Order }>(res);
  },

  async getCapacity() {
    const res = await fetch(`${API_BASE}/capacity`);
    return handleResponse<{ current: CapacityRecord; all_records: CapacityRecord[] }>(res);
  },

  async getTasks(status?: string) {
    const params = new URLSearchParams();
    if (status) params.append('status', status);
    const res = await fetch(`${API_BASE}/tasks?${params.toString()}`);
    return handleResponse<WorkflowTask[]>(res);
  },

  async updateTaskStatus(taskId: string, status: string) {
    const res = await fetch(`${API_BASE}/tasks/${taskId}/status`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ status }),
    });
    return handleResponse<WorkflowTask>(res);
  },

  async getAuditLogs() {
    const res = await fetch(`${API_BASE}/audit-logs`);
    return handleResponse<AuditLog[]>(res);
  },

  async trackOrder(token: string) {
    const res = await fetch(`${API_BASE}/track/${encodeURIComponent(token)}`);
    return handleResponse<TrackingData>(res);
  },

  async switchRole(role: RoleCode) {
    const res = await fetch(`${API_BASE}/auth/switch-role`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ role }),
    });
    return handleResponse<{ access_token: string; role: RoleCode; user: any }>(res);
  }
};
