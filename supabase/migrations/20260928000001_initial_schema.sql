-- ====================================================================
-- SUPABASE MIGRATION 001: INITIAL SCHEMA
-- Multi-tenant WhatsApp AI Automation + CRM + Order & Workflow System
-- Initial Domain: Luxury Jewelry & Custom Manufacturing
-- ====================================================================

-- 1. Enable Required Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. Utility Trigger Function to automatically update "updated_at"
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ====================================================================
-- 3. TENANT & RBAC CORE
-- ====================================================================

-- Companies (Tenants)
CREATE TABLE IF NOT EXISTS companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    industry VARCHAR(100) DEFAULT 'Jewelry & Luxury Goods',
    currency VARCHAR(10) DEFAULT 'INR',
    currency_symbol VARCHAR(5) DEFAULT '₹',
    logo_url TEXT,
    support_phone VARCHAR(50),
    support_email VARCHAR(255),
    website VARCHAR(255),
    settings JSONB DEFAULT '{
        "ai_confidence_auto_threshold": 0.90,
        "ai_confidence_safe_threshold": 0.60,
        "auto_approval_enabled": false,
        "business_hours": {
            "start": "09:00",
            "end": "19:00",
            "timezone": "Asia/Kolkata"
        }
    }'::jsonb,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Roles
CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE NOT NULL, -- SUPER_ADMIN, ADMIN, MANAGER, TEAM_LEAD, TEAM_MEMBER, SUPPORT_AGENT, CUSTOMER
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_system BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Permissions
CREATE TABLE IF NOT EXISTS permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(100) UNIQUE NOT NULL, -- e.g. 'orders:read', 'orders:write', 'approvals:manage'
    module VARCHAR(50) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Role Permissions Mapping
CREATE TABLE IF NOT EXISTS role_permissions (
    role_id UUID REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

-- Users (Profiles linked to Supabase Auth or internal management)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_user_id UUID UNIQUE, -- Foreign key to auth.users if Supabase Auth is active
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    avatar_url TEXT,
    department VARCHAR(100),
    status VARCHAR(50) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED')),
    workload_count INTEGER DEFAULT 0,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(company_id, email)
);

-- ====================================================================
-- 4. CRM & CUSTOMERS
-- ====================================================================

CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(50) NOT NULL,
    email VARCHAR(255),
    company VARCHAR(255),
    tier VARCHAR(50) DEFAULT 'STANDARD' CHECK (tier IN ('STANDARD', 'SILVER', 'GOLD', 'PLATINUM', 'VIP')),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(20),
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    notes TEXT,
    total_orders INTEGER DEFAULT 0,
    total_spent NUMERIC(15, 2) DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(company_id, phone)
);

-- Customer Tokens for secure external tracking portal (/track)
CREATE TABLE IF NOT EXISTS customer_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    order_id UUID, -- Optional direct link to an order or customer case
    token VARCHAR(64) UNIQUE NOT NULL, -- e.g. SARJAN-2026-8F42
    is_revoked BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMPTZ,
    last_accessed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ====================================================================
-- 5. PRODUCTS & CATALOG
-- ====================================================================

CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    sku VARCHAR(100) NOT NULL,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL, -- 'Rings', 'Necklaces', 'Bracelets', 'Earrings', 'Coins', 'Custom'
    description TEXT,
    metal_type VARCHAR(50) DEFAULT '18K Gold', -- '14K Gold', '18K Gold', '22K Gold', 'Platinum', '925 Silver'
    base_price NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    making_charges NUMERIC(15, 2) DEFAULT 0.00,
    purity VARCHAR(50) DEFAULT '18K / 750',
    gross_weight_grams NUMERIC(10, 3) DEFAULT 0.000,
    net_weight_grams NUMERIC(10, 3) DEFAULT 0.000,
    stone_details JSONB DEFAULT '[]'::jsonb, -- Diamonds, emeralds, rubies, etc.
    images TEXT[] DEFAULT ARRAY[]::TEXT[],
    is_customizable BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    stock_quantity INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(company_id, sku)
);

CREATE TABLE IF NOT EXISTS product_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    variant_name VARCHAR(100) NOT NULL, -- e.g. 'Size 14 / Rose Gold'
    sku_modifier VARCHAR(100),
    additional_price NUMERIC(15, 2) DEFAULT 0.00,
    stock_quantity INTEGER DEFAULT 0,
    attributes JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ====================================================================
-- 6. ORDERS & BATCHES
-- ====================================================================

CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    order_number VARCHAR(100) NOT NULL, -- e.g. ORD-1025
    customer_id UUID NOT NULL REFERENCES customers(id),
    tracking_token VARCHAR(64),
    status VARCHAR(50) DEFAULT 'ORDER_RECEIVED' CHECK (
        status IN (
            'ORDER_RECEIVED',
            'APPROVAL_PENDING',
            'PAYMENT_CONFIRMED',
            'DESIGN',
            'DESIGN_APPROVAL',
            'PRODUCTION',
            'QUALITY_CHECK',
            'PACKAGING',
            'SHIPPING',
            'DELIVERED',
            'CANCELLED',
            'ON_HOLD'
        )
    ),
    priority VARCHAR(20) DEFAULT 'NORMAL' CHECK (priority IN ('LOW', 'NORMAL', 'HIGH', 'URGENT')),
    subtotal NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    discount NUMERIC(15, 2) DEFAULT 0.00,
    tax NUMERIC(15, 2) DEFAULT 0.00,
    total NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    paid_amount NUMERIC(15, 2) DEFAULT 0.00,
    remaining_amount NUMERIC(15, 2) GENERATED ALWAYS AS (total - paid_amount) STORED,
    payment_status VARCHAR(50) DEFAULT 'UNPAID' CHECK (payment_status IN ('UNPAID', 'PARTIAL', 'PAID', 'REFUNDED')),
    expected_delivery TIMESTAMPTZ,
    assigned_team_id UUID,
    assigned_user_id UUID,
    custom_specifications JSONB DEFAULT '{}'::jsonb,
    internal_notes TEXT,
    customer_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(company_id, order_number)
);

CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id),
    product_variant_id UUID REFERENCES product_variants(id),
    item_title VARCHAR(255) NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(15, 2) NOT NULL,
    total_price NUMERIC(15, 2) NOT NULL,
    specifications JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Split order / production batches
CREATE TABLE IF NOT EXISTS order_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    batch_number VARCHAR(50) NOT NULL, -- e.g. BATCH-1, BATCH-2
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    status VARCHAR(50) DEFAULT 'QUEUED' CHECK (status IN ('QUEUED', 'IN_PRODUCTION', 'QUALITY_CHECK', 'COMPLETED', 'HOLD')),
    scheduled_start TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Payments
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    amount NUMERIC(15, 2) NOT NULL CHECK (amount > 0),
    payment_method VARCHAR(50) DEFAULT 'BANK_TRANSFER' CHECK (payment_method IN ('UPI', 'BANK_TRANSFER', 'CARD', 'CASH', 'CHEQUE', 'PAYMENT_GATEWAY')),
    transaction_reference VARCHAR(255),
    status VARCHAR(50) DEFAULT 'CONFIRMED' CHECK (status IN ('PENDING', 'CONFIRMED', 'FAILED', 'REFUNDED')),
    receipt_url TEXT,
    notes TEXT,
    recorded_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ====================================================================
-- 7. TEAMS & WORKFLOW TASKS
-- ====================================================================

CREATE TABLE IF NOT EXISTS teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL, -- Sales, Design, CAD, Production, Quality Control, Packaging, Shipping, Support, Finance
    department VARCHAR(100) NOT NULL,
    description TEXT,
    lead_user_id UUID,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS team_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_in_team VARCHAR(50) DEFAULT 'MEMBER',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(team_id, user_id)
);

CREATE TABLE IF NOT EXISTS workflow_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(100) DEFAULT 'Jewelry Standard',
    stages JSONB NOT NULL DEFAULT '[
        {"key": "ORDER_RECEIVED", "name": "Order Received", "department": "Sales", "order": 1},
        {"key": "PAYMENT_CONFIRMED", "name": "Payment Confirmed", "department": "Finance", "order": 2},
        {"key": "DESIGN", "name": "CAD & Design", "department": "Design", "order": 3},
        {"key": "DESIGN_APPROVAL", "name": "Customer Design Approval", "department": "Sales", "order": 4},
        {"key": "PRODUCTION", "name": "Manufacturing & Casting", "department": "Production", "order": 5},
        {"key": "QUALITY_CHECK", "name": "Quality Audit & Testing", "department": "Quality Control", "order": 6},
        {"key": "PACKAGING", "name": "Secure Luxury Packaging", "department": "Packaging", "order": 7},
        {"key": "SHIPPING", "name": "Armored Logistics & Dispatch", "department": "Shipping", "order": 8},
        {"key": "DELIVERED", "name": "Delivered to Customer", "department": "Shipping", "order": 9}
    ]'::jsonb,
    is_default BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS workflow_stages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID NOT NULL REFERENCES workflow_templates(id) ON DELETE CASCADE,
    stage_key VARCHAR(50) NOT NULL,
    stage_name VARCHAR(100) NOT NULL,
    department VARCHAR(100) NOT NULL,
    sequence_order INTEGER NOT NULL,
    auto_assign_team_id UUID REFERENCES teams(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS workflow_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    task_number VARCHAR(100) NOT NULL, -- e.g. TSK-1025
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    stage_key VARCHAR(50) NOT NULL,
    department VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    priority VARCHAR(20) DEFAULT 'NORMAL' CHECK (priority IN ('LOW', 'NORMAL', 'HIGH', 'URGENT')),
    status VARCHAR(50) DEFAULT 'TODO' CHECK (status IN ('TODO', 'IN_PROGRESS', 'WAITING', 'COMPLETED', 'CANCELLED')),
    assigned_to UUID REFERENCES users(id),
    deadline TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ====================================================================
-- 8. PRODUCTION CAPACITY & APPROVALS
-- ====================================================================

CREATE TABLE IF NOT EXISTS production_capacity (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    department VARCHAR(100) DEFAULT 'Production',
    total_capacity_units INTEGER NOT NULL DEFAULT 100,
    used_capacity_units INTEGER NOT NULL DEFAULT 0,
    available_capacity_units INTEGER GENERATED ALWAYS AS (total_capacity_units - used_capacity_units) STORED,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(company_id, date, department)
);

CREATE TABLE IF NOT EXISTS approvals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    type VARCHAR(50) DEFAULT 'PRODUCTION_CAPACITY' CHECK (type IN ('PRODUCTION_CAPACITY', 'DESIGN_APPROVAL', 'DISCOUNT_OVERRIDE', 'REFUND')),
    required_capacity_units INTEGER NOT NULL DEFAULT 1,
    available_capacity_units INTEGER DEFAULT 0,
    status VARCHAR(50) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'HOLD', 'REJECTED', 'SCHEDULED', 'SPLIT')),
    requested_by UUID REFERENCES users(id),
    reviewed_by UUID REFERENCES users(id),
    reviewed_at TIMESTAMPTZ,
    scheduled_for_date DATE,
    decision_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ====================================================================
-- 9. WHATSAPP & CONVERSATIONS
-- ====================================================================

CREATE TABLE IF NOT EXISTS whatsapp_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    phone_number_id VARCHAR(100) NOT NULL,
    waba_id VARCHAR(100) NOT NULL,
    display_phone_number VARCHAR(50) NOT NULL,
    webhook_verify_token VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    channel VARCHAR(50) DEFAULT 'WHATSAPP' CHECK (channel IN ('WHATSAPP', 'WEB', 'PORTAL')),
    status VARCHAR(50) DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'PENDING_TEAM', 'RESOLVED', 'CLOSED')),
    assigned_to UUID REFERENCES users(id),
    assigned_team_id UUID REFERENCES teams(id),
    priority VARCHAR(20) DEFAULT 'NORMAL' CHECK (priority IN ('LOW', 'NORMAL', 'HIGH', 'URGENT')),
    last_message_at TIMESTAMPTZ DEFAULT NOW(),
    unread_count INTEGER DEFAULT 0,
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    external_message_id VARCHAR(255) UNIQUE, -- Idempotency key for WhatsApp WAMID
    sender_type VARCHAR(50) NOT NULL CHECK (sender_type IN ('CUSTOMER', 'AI', 'TEAM', 'SYSTEM')),
    sender_user_id UUID REFERENCES users(id),
    content TEXT NOT NULL,
    message_type VARCHAR(50) DEFAULT 'TEXT' CHECK (message_type IN ('TEXT', 'IMAGE', 'DOCUMENT', 'AUDIO', 'LOCATION', 'TEMPLATE')),
    media_url TEXT,
    ai_processed BOOLEAN DEFAULT FALSE,
    ai_intent VARCHAR(50),
    ai_confidence NUMERIC(4, 3),
    status VARCHAR(50) DEFAULT 'DELIVERED' CHECK (status IN ('PENDING', 'SENT', 'DELIVERED', 'READ', 'FAILED')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS support_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    ticket_number VARCHAR(100) NOT NULL, -- e.g. SUP-1025
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    conversation_id UUID REFERENCES conversations(id),
    order_id UUID REFERENCES orders(id),
    subject VARCHAR(255) NOT NULL,
    description TEXT,
    intent VARCHAR(50),
    priority VARCHAR(20) DEFAULT 'NORMAL' CHECK (priority IN ('LOW', 'NORMAL', 'HIGH', 'URGENT')),
    status VARCHAR(50) DEFAULT 'WAITING_FOR_TEAM' CHECK (status IN ('OPEN', 'WAITING_FOR_TEAM', 'IN_PROGRESS', 'RESOLVED', 'CLOSED')),
    assigned_to UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ====================================================================
-- 10. AI KNOWLEDGE BASE & AUTOMATION
-- ====================================================================

CREATE TABLE IF NOT EXISTS knowledge_base (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    category VARCHAR(100) NOT NULL, -- 'FAQ', 'PRICING', 'MAKING_CHARGES', 'PURITY_STANDARDS', 'CUSTOMIZATION_POLICY', 'SHIPPING_TIMELINE', 'RETURN_POLICY'
    question_or_title VARCHAR(255) NOT NULL,
    answer_or_content TEXT NOT NULL,
    keywords TEXT[] DEFAULT ARRAY[]::TEXT[],
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS automation_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    event_trigger VARCHAR(100) NOT NULL, -- 'ORDER_STATUS_CHANGED', 'CAPACITY_EXCEEDED', 'TASK_COMPLETED', 'PAYMENT_RECEIVED'
    conditions JSONB NOT NULL DEFAULT '{}'::jsonb,
    actions JSONB NOT NULL DEFAULT '[]'::jsonb,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(100) NOT NULL, -- 'NEW_ORDER', 'APPROVAL_REQUIRED', 'TASK_ASSIGNED', 'CAPACITY_ALERT'
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    document_type VARCHAR(50) NOT NULL CHECK (document_type IN ('INVOICE', 'QUOTATION', 'RECEIPT', 'DESIGN_CAD', 'CERTIFICATE', 'SHIPPING_LABEL')),
    file_path TEXT NOT NULL,
    file_size_bytes BIGINT,
    mime_type VARCHAR(100),
    is_customer_visible BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    user_email VARCHAR(255),
    action VARCHAR(100) NOT NULL, -- 'APPROVE_ORDER', 'CHANGE_STATUS', 'CREATE_ORDER', 'ASSIGN_TASK'
    entity_type VARCHAR(50) NOT NULL, -- 'orders', 'approvals', 'workflow_tasks'
    entity_id VARCHAR(100) NOT NULL,
    previous_state JSONB,
    new_state JSONB,
    ip_address VARCHAR(50),
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ====================================================================
-- 11. INDEXES FOR HIGH-PERFORMANCE QUERYING
-- ====================================================================

CREATE INDEX IF NOT EXISTS idx_customers_company_phone ON customers(company_id, phone);
CREATE INDEX IF NOT EXISTS idx_orders_company_status ON orders(company_id, status);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_tokens_token ON customer_tokens(token);
CREATE INDEX IF NOT EXISTS idx_workflow_tasks_company_status ON workflow_tasks(company_id, status);
CREATE INDEX IF NOT EXISTS idx_workflow_tasks_assigned_to ON workflow_tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_approvals_company_status ON approvals(company_id, status);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_external_id ON messages(external_message_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_company ON audit_logs(company_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON notifications(user_id, is_read);

-- ====================================================================
-- 12. TRIGGERS FOR UPDATED_AT
-- ====================================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_companies_updated_at') THEN
        CREATE TRIGGER trg_companies_updated_at BEFORE UPDATE ON companies FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_users_updated_at') THEN
        CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_customers_updated_at') THEN
        CREATE TRIGGER trg_customers_updated_at BEFORE UPDATE ON customers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_products_updated_at') THEN
        CREATE TRIGGER trg_products_updated_at BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_orders_updated_at') THEN
        CREATE TRIGGER trg_orders_updated_at BEFORE UPDATE ON orders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_workflow_tasks_updated_at') THEN
        CREATE TRIGGER trg_workflow_tasks_updated_at BEFORE UPDATE ON workflow_tasks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_approvals_updated_at') THEN
        CREATE TRIGGER trg_approvals_updated_at BEFORE UPDATE ON approvals FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_conversations_updated_at') THEN
        CREATE TRIGGER trg_conversations_updated_at BEFORE UPDATE ON conversations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;
