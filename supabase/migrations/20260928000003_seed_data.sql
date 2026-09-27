-- ====================================================================
-- SUPABASE MIGRATION 003: SEED DEMO DATA
-- Luxury Jewelry Enterprise: Sarjan Fine Jewels
-- ====================================================================

-- Fixed deterministic UUIDs for relational consistency
DO $$
DECLARE
    v_company_id UUID := '11111111-1111-1111-1111-111111111111';
    
    -- Role IDs
    v_role_super_admin UUID := '22222222-2222-2222-2222-222222222221';
    v_role_admin UUID := '22222222-2222-2222-2222-222222222222';
    v_role_manager UUID := '22222222-2222-2222-2222-222222222223';
    v_role_lead UUID := '22222222-2222-2222-2222-222222222224';
    v_role_member UUID := '22222222-2222-2222-2222-222222222225';
    v_role_support UUID := '22222222-2222-2222-2222-222222222226';
    v_role_customer UUID := '22222222-2222-2222-2222-222222222227';

    -- User IDs
    v_user_admin UUID := '33333333-3333-3333-3333-333333333331';
    v_user_cad UUID := '33333333-3333-3333-3333-333333333332';
    v_user_prod UUID := '33333333-3333-3333-3333-333333333333';
    v_user_qc UUID := '33333333-3333-3333-3333-333333333334';
    v_user_support UUID := '33333333-3333-3333-3333-333333333335';

    -- Customer IDs
    v_cust_rahul UUID := '44444444-4444-4444-4444-444444444441';
    v_cust_amit UUID := '44444444-4444-4444-4444-444444444442';
    v_cust_priya UUID := '44444444-4444-4444-4444-444444444443';
    v_cust_vikram UUID := '44444444-4444-4444-4444-444444444444';
    v_cust_ananya UUID := '44444444-4444-4444-4444-444444444445';

    -- Product IDs
    v_prod_ring1 UUID := '55555555-5555-5555-5555-555555555551';
    v_prod_choker UUID := '55555555-5555-5555-5555-555555555552';
    v_prod_pendant UUID := '55555555-5555-5555-5555-555555555553';
    v_prod_bracelet UUID := '55555555-5555-5555-5555-555555555554';
    v_prod_jhumka UUID := '55555555-5555-5555-5555-555555555555';
    v_prod_band UUID := '55555555-5555-5555-5555-555555555556';
    v_prod_studs UUID := '55555555-5555-5555-5555-555555555557';
    v_prod_kada UUID := '55555555-5555-5555-5555-555555555558';
    v_prod_cocktail UUID := '55555555-5555-5555-5555-555555555559';
    v_prod_bespoke UUID := '55555555-5555-5555-5555-555555555560';

    -- Order IDs
    v_ord_1025 UUID := '66666666-6666-6666-6666-666666666625';
    v_ord_1026 UUID := '66666666-6666-6666-6666-666666666626';
    v_ord_1027 UUID := '66666666-6666-6666-6666-666666666627';
    v_ord_1028 UUID := '66666666-6666-6666-6666-666666666628';
    v_ord_1029 UUID := '66666666-6666-6666-6666-666666666629';
    v_ord_1030 UUID := '66666666-6666-6666-6666-666666666630';

BEGIN

    -- 1. Insert Company
    INSERT INTO companies (id, name, slug, industry, currency, currency_symbol, support_phone, support_email, website)
    VALUES (
        v_company_id,
        'Sarjan Fine Jewels',
        'sarjan-jewels',
        'Fine Jewelry & Bespoke Manufacturing',
        'INR',
        '₹',
        '+91 98250 00000',
        'admin@sarjan.tech',
        'https://sarjanfinejewels.com'
    ) ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name;

    -- 2. Insert Roles
    INSERT INTO roles (id, code, name, description)
    VALUES 
        (v_role_super_admin, 'SUPER_ADMIN', 'Super Administrator', 'Full global platform control'),
        (v_role_admin, 'ADMIN', 'Administrator', 'Business unit management and approvals'),
        (v_role_manager, 'MANAGER', 'Operations Manager', 'Order queue, capacity balancing and team management'),
        (v_role_lead, 'TEAM_LEAD', 'Department Lead', 'Supervises department tasks and quality signoff'),
        (v_role_member, 'TEAM_MEMBER', 'Artisan / CAD Specialist', 'Executes assigned production tasks'),
        (v_role_support, 'SUPPORT_AGENT', 'Customer Support', 'Handles inquiries and WhatsApp conversations'),
        (v_role_customer, 'CUSTOMER', 'Customer', 'Accesses tracking portal and personal orders')
    ON CONFLICT (code) DO NOTHING;

    -- 3. Insert Users
    INSERT INTO users (id, company_id, role_id, name, email, phone, department, status, workload_count)
    VALUES 
        (v_user_admin, v_company_id, v_role_admin, 'Abhishek Administrator', 'admin@sarjan.tech', '+91 98250 99999', 'Executive Management', 'ACTIVE', 3),
        (v_user_cad, v_company_id, v_role_member, 'Amit Patel (CAD Lead)', 'amit.cad@sarjan.tech', '+91 98250 88888', 'Design & CAD', 'ACTIVE', 5),
        (v_user_prod, v_company_id, v_role_member, 'Rajesh Varma (Master Goldsmith)', 'rajesh.prod@sarjan.tech', '+91 98250 77777', 'Production & Casting', 'ACTIVE', 7),
        (v_user_qc, v_company_id, v_role_member, 'Pooja Iyer (Hallmarking & QC)', 'pooja.qc@sarjan.tech', '+91 98250 66666', 'Quality Control', 'ACTIVE', 2),
        (v_user_support, v_company_id, v_role_support, 'Sneha Shah (VIP Concierge)', 'support@sarjan.tech', '+91 98250 55555', 'Customer Support', 'ACTIVE', 4)
    ON CONFLICT (company_id, email) DO NOTHING;

    -- 4. Insert Customers
    INSERT INTO customers (id, company_id, name, phone, email, company, tier, city, state, tags, notes, total_orders, total_spent)
    VALUES 
        (v_cust_rahul, v_company_id, 'Rahul Patel', '+919825012345', 'rahul.patel@gmail.com', 'Patel Diamond Exports', 'VIP', 'Ahmedabad', 'Gujarat', ARRAY['VIP', 'Wholesale', 'Custom CAD'], 'Preferred 18K Yellow Gold with VVS diamonds', 4, 380000.00),
        (v_cust_amit, v_company_id, 'Amit Shah', '+919825123456', 'amit.shah@relstar.com', 'Shah Heritage', 'PLATINUM', 'Mumbai', 'Maharashtra', ARRAY['Bridal', 'Kundan'], 'Prefers hallmark certification certificate on delivery', 2, 215000.00),
        (v_cust_priya, v_company_id, 'Priya Sharma', '+919825234567', 'priya.sharma@yahoo.com', 'Self', 'GOLD', 'Surat', 'Gujarat', ARRAY['Solitaire', 'Modern'], 'Looking for custom anniversary ring', 1, 85000.00),
        (v_cust_vikram, v_company_id, 'Vikram Mehta', '+919825345678', 'vikram.mehta@outlook.com', 'Mehta Gems', 'STANDARD', 'Delhi', 'Delhi', ARRAY['Inquiry', 'WhatsApp'], 'First time inquiry via WhatsApp Cloud API', 0, 0.00),
        (v_cust_ananya, v_company_id, 'Ananya Desai', '+919825456789', 'ananya.desai@gmail.com', 'Studio Desai', 'GOLD', 'Bengaluru', 'Karnataka', ARRAY['Polki', 'Platinum'], 'Interested in platinum bands', 1, 65000.00)
    ON CONFLICT (company_id, phone) DO NOTHING;

    -- 5. Insert Products
    INSERT INTO products (id, company_id, sku, name, category, metal_type, base_price, making_charges, purity, gross_weight_grams, net_weight_grams, is_customizable, stock_quantity)
    VALUES 
        (v_prod_ring1, v_company_id, 'RNG-SOL-001', 'Royal Solitaire Diamond Ring', 'Rings', '18K White Gold', 85000.00, 6500.00, '18K / 750', 4.250, 4.010, TRUE, 12),
        (v_prod_choker, v_company_id, 'NCK-KND-002', 'Heritage Kundan Choker Necklace', 'Necklaces', '22K Yellow Gold', 320000.00, 24000.00, '22K / 916', 48.500, 42.100, TRUE, 3),
        (v_prod_pendant, v_company_id, 'PND-EMR-003', 'Emerald Cut Solitaire Pendant', 'Necklaces', '18K Yellow Gold', 48000.00, 4200.00, '18K / 750', 3.100, 2.940, TRUE, 15),
        (v_prod_bracelet, v_company_id, 'BRC-TNS-004', 'Eternal Diamond Tennis Bracelet', 'Bracelets', '18K Rose Gold', 175000.00, 12500.00, '18K / 750', 14.800, 14.100, TRUE, 6),
        (v_prod_jhumka, v_company_id, 'ERR-JHM-005', 'Regal Peacock Polki Jhumkas', 'Earrings', '22K Yellow Gold', 142000.00, 11000.00, '22K / 916', 26.400, 22.800, TRUE, 5),
        (v_prod_band, v_company_id, 'BND-PLT-006', 'Men''s Platinum Diamond Band', 'Rings', 'Platinum 950', 68000.00, 5800.00, 'Pt 950', 8.200, 8.160, TRUE, 18),
        (v_prod_studs, v_company_id, 'ERR-STD-007', 'Classic Floral Diamond Studs', 'Earrings', '18K White Gold', 38000.00, 3200.00, '18K / 750', 2.800, 2.700, TRUE, 25),
        (v_prod_kada, v_company_id, 'BRC-KDA-008', 'Temple Nakshi Bridal Kada', 'Bracelets', '22K Yellow Gold', 365000.00, 28000.00, '22K / 916', 54.200, 53.800, TRUE, 2),
        (v_prod_cocktail, v_company_id, 'RNG-TNZ-009', 'Tanzanite & Diamond Cocktail Ring', 'Rings', '18K White Gold', 95000.00, 7500.00, '18K / 750', 5.600, 4.850, TRUE, 8),
        (v_prod_bespoke, v_company_id, 'RNG-BSP-010', 'Custom Bespoke Wedding Band Set', 'Rings', '18K Rose Gold', 115000.00, 9500.00, '18K / 750', 12.400, 12.100, TRUE, 10)
    ON CONFLICT (company_id, sku) DO NOTHING;

    -- 6. Insert Production Capacity (Current Date)
    INSERT INTO production_capacity (company_id, date, department, total_capacity_units, used_capacity_units, notes)
    VALUES 
        (v_company_id, CURRENT_DATE, 'Production', 100, 50, 'Regular jewelry bench casting capacity'),
        (v_company_id, CURRENT_DATE + INTERVAL '1 day', 'Production', 100, 30, 'Scheduled capacity for tomorrow'),
        (v_company_id, CURRENT_DATE + INTERVAL '2 day', 'Production', 100, 0, 'Available slots')
    ON CONFLICT (company_id, date, department) DO UPDATE SET used_capacity_units = EXCLUDED.used_capacity_units;

    -- 7. Insert Orders
    INSERT INTO orders (id, company_id, order_number, customer_id, tracking_token, status, priority, subtotal, discount, tax, total, paid_amount, payment_status, expected_delivery, assigned_user_id)
    VALUES 
        (v_ord_1025, v_company_id, 'ORD-1025', v_cust_rahul, 'SARJAN-2026-8F42', 'PRODUCTION', 'HIGH', 80000.00, 0.00, 2400.00, 82400.00, 40000.00, 'PARTIAL', NOW() + INTERVAL '7 days', v_user_prod),
        (v_ord_1026, v_company_id, 'ORD-1026', v_cust_amit, 'SARJAN-2026-9A11', 'APPROVAL_PENDING', 'HIGH', 75000.00, 0.00, 2250.00, 77250.00, 77250.00, 'PAID', NOW() + INTERVAL '8 days', NULL),
        (v_ord_1027, v_company_id, 'ORD-1027', v_cust_priya, 'SARJAN-2026-3C77', 'DESIGN', 'NORMAL', 85000.00, 5000.00, 2400.00, 82400.00, 82400.00, 'PAID', NOW() + INTERVAL '10 days', v_user_cad),
        (v_ord_1028, v_company_id, 'ORD-1028', v_cust_ananya, 'SARJAN-2026-4D88', 'QUALITY_CHECK', 'URGENT', 65000.00, 0.00, 1950.00, 66950.00, 66950.00, 'PAID', NOW() + INTERVAL '2 days', v_user_qc),
        (v_ord_1029, v_company_id, 'ORD-1029', v_cust_rahul, 'SARJAN-2026-5E99', 'PACKAGING', 'NORMAL', 142000.00, 2000.00, 4200.00, 144200.00, 144200.00, 'PAID', NOW() + INTERVAL '3 days', v_user_admin),
        (v_ord_1030, v_company_id, 'ORD-1030', v_cust_amit, 'SARJAN-2026-6F00', 'DELIVERED', 'NORMAL', 320000.00, 10000.00, 9300.00, 319300.00, 319300.00, 'PAID', NOW() - INTERVAL '2 days', v_user_admin)
    ON CONFLICT (company_id, order_number) DO NOTHING;

    -- 8. Insert Order Items
    INSERT INTO order_items (company_id, order_id, product_id, item_title, quantity, unit_price, total_price, specifications)
    VALUES 
        (v_company_id, v_ord_1025, v_prod_ring1, 'Custom Solitaire Diamond Ring (Size 14)', 50, 1600.00, 80000.00, '{"size": 14, "gold_color": "18K White Gold", "diamond_clarity": "VVS1"}'::jsonb),
        (v_company_id, v_ord_1026, v_prod_band, 'Men''s Platinum Diamond Band (Size 20)', 50, 1500.00, 75000.00, '{"size": 20, "metal": "Platinum 950"}'::jsonb),
        (v_company_id, v_ord_1027, v_prod_ring1, 'Royal Solitaire Diamond Ring (Custom Engraving)', 1, 85000.00, 85000.00, '{"engraving": "Forever Priya & Rahul"}'::jsonb)
    ON CONFLICT DO NOTHING;

    -- 9. Insert Customer Tokens
    INSERT INTO customer_tokens (company_id, customer_id, order_id, token, expires_at)
    VALUES 
        (v_company_id, v_cust_rahul, v_ord_1025, 'SARJAN-2026-8F42', NOW() + INTERVAL '90 days'),
        (v_company_id, v_cust_amit, v_ord_1026, 'SARJAN-2026-9A11', NOW() + INTERVAL '90 days'),
        (v_company_id, v_cust_priya, v_ord_1027, 'SARJAN-2026-3C77', NOW() + INTERVAL '90 days')
    ON CONFLICT (token) DO NOTHING;

    -- 10. Insert Production Approvals (demonstrating simultaneous capacity constraint)
    INSERT INTO approvals (company_id, order_id, type, required_capacity_units, available_capacity_units, status, requested_by, decision_notes)
    VALUES 
        (v_company_id, v_ord_1025, 'PRODUCTION_CAPACITY', 50, 50, 'APPROVED', v_user_admin, 'Capacity verified and allocated for batch 1'),
        (v_company_id, v_ord_1026, 'PRODUCTION_CAPACITY', 50, 0, 'PENDING', v_user_admin, 'Waiting for capacity slot or admin schedule decision')
    ON CONFLICT DO NOTHING;

    -- 11. Insert Workflow Tasks
    INSERT INTO workflow_tasks (company_id, task_number, order_id, stage_key, department, title, description, priority, status, assigned_to, deadline)
    VALUES 
        (v_company_id, 'TSK-1025', v_ord_1025, 'PRODUCTION', 'Production', 'Cast 50 units in 18K White Gold', 'Cast and assemble ring mountings, set center stones', 'HIGH', 'IN_PROGRESS', v_user_prod, NOW() + INTERVAL '3 days'),
        (v_company_id, 'TSK-1027', v_ord_1027, 'DESIGN', 'Design', 'Create 3D CAD matrix rendering for customer review', 'Render with 1.2ct cushion cut stone and send proof to customer', 'HIGH', 'IN_PROGRESS', v_user_cad, NOW() + INTERVAL '1 day'),
        (v_company_id, 'TSK-1028', v_ord_1028, 'QUALITY_CHECK', 'Quality Control', 'BIS Hallmarking and Diamond Clarity Verification', 'Perform XRF purity test and issue guarantee card', 'URGENT', 'TODO', v_user_qc, NOW() + INTERVAL '1 day')
    ON CONFLICT DO NOTHING;

    -- 12. Insert Knowledge Base for AI
    INSERT INTO knowledge_base (company_id, category, question_or_title, answer_or_content, keywords)
    VALUES 
        (v_company_id, 'FAQ', 'What purity gold does Sarjan Fine Jewels provide?', 'We offer certified 18 Karat (750 hallmark) and 22 Karat (916 hallmark) gold jewellery with official government-recognized BIS hallmarking.', ARRAY['purity', 'gold', 'hallmark', '18k', '22k', 'bis']),
        (v_company_id, 'MAKING_CHARGES', 'What are your making charges structure?', 'Making charges start from ₹450 per gram for plain gold and 8% to 14% on diamond jewelry depending on intricate craftsmanship and setting complexity.', ARRAY['making charges', 'rate', 'cost', 'percentage']),
        (v_company_id, 'CUSTOMIZATION', 'Can I customize a ring or provide my own CAD design?', 'Yes! We specialize in bespoke jewelry. You can share reference photos or 3D CAD files. Our CAD design team prepares a 3D digital proof in 24 to 48 hours for your approval prior to casting.', ARRAY['custom', 'bespoke', 'cad', 'customization', 'design'])
    ON CONFLICT DO NOTHING;

    -- 13. Insert Audit Log Entry
    INSERT INTO audit_logs (company_id, user_id, user_email, action, entity_type, entity_id, previous_state, new_state)
    VALUES 
        (v_company_id, v_user_admin, 'admin@sarjan.tech', 'APPROVE_ORDER', 'orders', 'ORD-1025', '{"status": "APPROVAL_PENDING"}'::jsonb, '{"status": "PRODUCTION", "capacity_units": 50}'::jsonb),
        (v_company_id, v_user_admin, 'admin@sarjan.tech', 'CREATE_ORDER', 'orders', 'ORD-1026', NULL, '{"status": "APPROVAL_PENDING", "requested_units": 50}'::jsonb)
    ON CONFLICT DO NOTHING;

    -- 14. Insert Notification
    INSERT INTO notifications (company_id, user_id, type, title, message, is_read)
    VALUES 
        (v_company_id, v_user_admin, 'APPROVAL_REQUIRED', 'Simultaneous Order Capacity Alert', 'Order #ORD-1026 requires 50 units. Available capacity on bench is currently 0. Please review approval queue.', FALSE),
        (v_company_id, v_user_cad, 'TASK_ASSIGNED', 'New CAD Task Assigned', 'Task #TSK-1027: 3D CAD matrix rendering for customer proof has been assigned to you.', FALSE)
    ON CONFLICT DO NOTHING;

END $$;
