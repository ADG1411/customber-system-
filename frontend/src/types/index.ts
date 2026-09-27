export interface Company {
  id: string;
  name: string;
  slug: string;
  industry: string;
  currency: string;
  currency_symbol: string;
  support_phone?: string;
  support_email?: string;
  website?: string;
  settings?: Record<string, any>;
}

export type RoleCode = 
  | 'SUPER_ADMIN'
  | 'ADMIN'
  | 'MANAGER'
  | 'TEAM_LEAD'
  | 'TEAM_MEMBER'
  | 'SUPPORT_AGENT'
  | 'CUSTOMER';

export interface User {
  id: string;
  name: string;
  email: string;
  role: RoleCode;
  company_id: string;
  department?: string;
}

export interface Customer {
  id: string;
  company_id: string;
  name: string;
  phone: string;
  email?: string;
  company?: string;
  tier: 'STANDARD' | 'SILVER' | 'GOLD' | 'PLATINUM' | 'VIP';
  city?: string;
  state?: string;
  tags: string[];
  notes?: string;
  total_orders: number;
  total_spent: number;
  created_at: string;
}

export type OrderStatus =
  | 'ORDER_RECEIVED'
  | 'APPROVAL_PENDING'
  | 'PAYMENT_CONFIRMED'
  | 'DESIGN'
  | 'DESIGN_APPROVAL'
  | 'PRODUCTION'
  | 'QUALITY_CHECK'
  | 'PACKAGING'
  | 'SHIPPING'
  | 'DELIVERED'
  | 'CANCELLED'
  | 'ON_HOLD';

export type Priority = 'LOW' | 'NORMAL' | 'HIGH' | 'URGENT';

export interface Order {
  id: string;
  company_id: string;
  order_number: string;
  customer_id: string;
  customer_name?: string;
  product_name?: string;
  quantity: number;
  tracking_token?: string;
  status: OrderStatus;
  priority: Priority;
  total: number;
  paid_amount: number;
  remaining_amount: number;
  payment_status: 'UNPAID' | 'PARTIAL' | 'PAID' | 'REFUNDED';
  expected_delivery?: string;
  assigned_user_name?: string;
  created_at: string;
}

export interface Approval {
  id: string;
  company_id: string;
  order_id: string;
  order_number: string;
  customer_name: string;
  quantity: number;
  value: number;
  type: string;
  required_capacity_units: number;
  available_capacity_units: number;
  status: 'PENDING' | 'APPROVED' | 'HOLD' | 'REJECTED' | 'SCHEDULED' | 'SPLIT';
  decision_notes?: string;
}

export interface CapacityRecord {
  date: string;
  department: string;
  total_capacity_units: number;
  used_capacity_units: number;
  available_capacity_units: number;
  notes?: string;
}

export interface WorkflowTask {
  id: string;
  company_id: string;
  task_number: string;
  order_id: string;
  order_number: string;
  stage_key: string;
  department: string;
  title: string;
  description?: string;
  priority: Priority;
  status: 'TODO' | 'IN_PROGRESS' | 'WAITING' | 'COMPLETED' | 'CANCELLED';
  assigned_to?: string;
  deadline?: string;
}

export interface AuditLog {
  id: string;
  user_email: string;
  action: string;
  entity_type: string;
  entity_id: string;
  details: string;
  created_at: string;
}

export interface NotificationItem {
  id: string;
  title: string;
  message: string;
  type: string;
  is_read: boolean;
  created_at: string;
}

export interface TrackingStage {
  key: string;
  label: string;
  desc: string;
  state: 'COMPLETED' | 'CURRENT' | 'UPCOMING';
}

export interface TrackingData {
  order_number: string;
  tracking_token: string;
  customer_name: string;
  product_name: string;
  quantity: number;
  total: number;
  paid_amount: number;
  remaining_amount: number;
  payment_status: string;
  status: OrderStatus;
  expected_delivery?: string;
  stages: TrackingStage[];
}
