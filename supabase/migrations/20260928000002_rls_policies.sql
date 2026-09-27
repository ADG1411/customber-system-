-- ====================================================================
-- SUPABASE MIGRATION 002: ROW LEVEL SECURITY (RLS) POLICIES
-- Enterprise Multi-Tenant & Role-Based Access Control
-- ====================================================================

-- 1. Helper function to extract user's company_id from JWT claims or user record
CREATE OR REPLACE FUNCTION get_auth_company_id()
RETURNS UUID AS $$
BEGIN
    -- Check if company_id is provided in JWT user metadata
    IF (auth.jwt() -> 'app_metadata' ->> 'company_id') IS NOT NULL THEN
        RETURN (auth.jwt() -> 'app_metadata' ->> 'company_id')::UUID;
    END IF;

    IF (auth.jwt() -> 'user_metadata' ->> 'company_id') IS NOT NULL THEN
        RETURN (auth.jwt() -> 'user_metadata' ->> 'company_id')::UUID;
    END IF;

    -- Fallback: check users table linked by auth_user_id
    RETURN (SELECT company_id FROM users WHERE auth_user_id = auth.uid() LIMIT 1);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 2. Helper function to check if the current user has a specific role code
CREATE OR REPLACE FUNCTION auth_user_has_role(role_code_check TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM users u
        JOIN roles r ON u.role_id = r.id
        WHERE u.auth_user_id = auth.uid()
        AND r.code = role_code_check
    );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ====================================================================
-- 3. ENABLE RLS ON ALL SENSITIVE TABLES
-- ====================================================================

ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE workflow_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE workflow_stages ENABLE ROW LEVEL SECURITY;
ALTER TABLE workflow_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE production_capacity ENABLE ROW LEVEL SECURITY;
ALTER TABLE approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE knowledge_base ENABLE ROW LEVEL SECURITY;
ALTER TABLE automation_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- ====================================================================
-- 4. TENANT POLICIES (COMPANIES)
-- ====================================================================

-- Users can only view their own company record
CREATE POLICY "Users can view own company"
    ON companies FOR SELECT
    USING (id = get_auth_company_id() OR auth_user_has_role('SUPER_ADMIN'));

CREATE POLICY "Super Admins can manage companies"
    ON companies FOR ALL
    USING (auth_user_has_role('SUPER_ADMIN'));

-- ====================================================================
-- 5. USERS POLICIES
-- ====================================================================

CREATE POLICY "Users can view colleagues in their company"
    ON users FOR SELECT
    USING (company_id = get_auth_company_id());

CREATE POLICY "Admins can manage company users"
    ON users FOR ALL
    USING (company_id = get_auth_company_id() AND (auth_user_has_role('ADMIN') OR auth_user_has_role('SUPER_ADMIN')));

-- ====================================================================
-- 6. CUSTOMER & ORDER POLICIES
-- ====================================================================

-- Internal team can view and manage their company's customers
CREATE POLICY "Company members can view customers"
    ON customers FOR SELECT
    USING (company_id = get_auth_company_id());

CREATE POLICY "Company members can manage customers"
    ON customers FOR ALL
    USING (company_id = get_auth_company_id());

-- Orders: Company team access
CREATE POLICY "Company members can view orders"
    ON orders FOR SELECT
    USING (company_id = get_auth_company_id());

CREATE POLICY "Company members can manage orders"
    ON orders FOR ALL
    USING (company_id = get_auth_company_id());

CREATE POLICY "Company members can view order items"
    ON order_items FOR SELECT
    USING (company_id = get_auth_company_id());

CREATE POLICY "Company members can manage order items"
    ON order_items FOR ALL
    USING (company_id = get_auth_company_id());

-- Customer Token lookup (Public or Anonymous with valid non-expired token for /track)
CREATE POLICY "Token holders can view tracking order"
    ON orders FOR SELECT
    USING (
        tracking_token IS NOT NULL AND
        EXISTS (
            SELECT 1 FROM customer_tokens ct
            WHERE ct.order_id = orders.id
            AND ct.is_revoked = FALSE
            AND (ct.expires_at IS NULL OR ct.expires_at > NOW())
        )
    );

-- ====================================================================
-- 7. PRODUCTION, WORKFLOW & CAPACITY POLICIES
-- ====================================================================

CREATE POLICY "Company members view production capacity"
    ON production_capacity FOR SELECT
    USING (company_id = get_auth_company_id());

CREATE POLICY "Managers and Admins manage capacity"
    ON production_capacity FOR ALL
    USING (
        company_id = get_auth_company_id() AND
        (auth_user_has_role('ADMIN') OR auth_user_has_role('MANAGER') OR auth_user_has_role('SUPER_ADMIN'))
    );

CREATE POLICY "Company members view approvals"
    ON approvals FOR SELECT
    USING (company_id = get_auth_company_id());

CREATE POLICY "Authorized personnel manage approvals"
    ON approvals FOR ALL
    USING (
        company_id = get_auth_company_id() AND
        (auth_user_has_role('ADMIN') OR auth_user_has_role('MANAGER') OR auth_user_has_role('SUPER_ADMIN'))
    );

CREATE POLICY "Company members view tasks"
    ON workflow_tasks FOR SELECT
    USING (company_id = get_auth_company_id());

CREATE POLICY "Company members update assigned tasks"
    ON workflow_tasks FOR ALL
    USING (company_id = get_auth_company_id());

-- ====================================================================
-- 8. COMMUNICATIONS & KNOWLEDGE BASE
-- ====================================================================

CREATE POLICY "Company members view conversations"
    ON conversations FOR SELECT
    USING (company_id = get_auth_company_id());

CREATE POLICY "Company members manage conversations"
    ON conversations FOR ALL
    USING (company_id = get_auth_company_id());

CREATE POLICY "Company members view messages"
    ON messages FOR SELECT
    USING (company_id = get_auth_company_id());

CREATE POLICY "Company members insert messages"
    ON messages FOR INSERT
    WITH CHECK (company_id = get_auth_company_id());

CREATE POLICY "Company members view knowledge base"
    ON knowledge_base FOR SELECT
    USING (company_id = get_auth_company_id());

CREATE POLICY "Admins manage knowledge base"
    ON knowledge_base FOR ALL
    USING (
        company_id = get_auth_company_id() AND
        (auth_user_has_role('ADMIN') OR auth_user_has_role('SUPER_ADMIN'))
    );

-- ====================================================================
-- 9. AUDIT LOGS & NOTIFICATIONS
-- ====================================================================

CREATE POLICY "Users view own notifications"
    ON notifications FOR SELECT
    USING (company_id = get_auth_company_id() AND (user_id IS NULL OR user_id = auth.uid()));

CREATE POLICY "Users update own notifications"
    ON notifications FOR UPDATE
    USING (company_id = get_auth_company_id() AND (user_id IS NULL OR user_id = auth.uid()));

CREATE POLICY "Admins view audit logs"
    ON audit_logs FOR SELECT
    USING (
        company_id = get_auth_company_id() AND
        (auth_user_has_role('ADMIN') OR auth_user_has_role('SUPER_ADMIN') OR auth_user_has_role('MANAGER'))
    );

CREATE POLICY "System inserts audit logs"
    ON audit_logs FOR INSERT
    WITH CHECK (company_id = get_auth_company_id());
