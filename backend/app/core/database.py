from typing import Optional, Dict, Any, List
from supabase import create_client, Client
from app.core.config import settings
from app.core.logging import logger
import copy
import uuid
from datetime import datetime, timezone, timedelta

class SupabaseManager:
    _service_client: Optional[Client] = None
    _anon_client: Optional[Client] = None
    _is_live_connected: bool = False
    _connection_error: Optional[str] = None
    
    # In-memory high-fidelity datastore for local development, instant testing, and offline resilience
    _store: Dict[str, List[Dict[str, Any]]] = {}

    @classmethod
    def initialize(cls):
        """Initializes Supabase clients and checks connection status."""
        cls._init_mock_store()
        
        # Check if valid live Supabase URL and key are provided
        if (
            settings.SUPABASE_URL 
            and "supabase.co" in settings.SUPABASE_URL
            and settings.SUPABASE_SERVICE_ROLE_KEY 
            and not settings.SUPABASE_SERVICE_ROLE_KEY.startswith("mock_")
        ):
            try:
                cls._service_client = create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_ROLE_KEY)
                cls._anon_client = create_client(settings.SUPABASE_URL, settings.SUPABASE_ANON_KEY)
                # Verify lightweight connectivity
                test_res = cls._service_client.table("companies").select("id").limit(1).execute()
                cls._is_live_connected = True
                cls._connection_error = None
                logger.info("Successfully connected to live Supabase project at %s", settings.SUPABASE_URL)
            except Exception as e:
                cls._is_live_connected = False
                cls._connection_error = str(e)
                logger.warning("Supabase live connection check failed (%s). Falling back to active local store.", str(e))
        else:
            cls._is_live_connected = False
            cls._connection_error = "Running in Development / Sandbox Mode. Provide live SUPABASE_SERVICE_ROLE_KEY to sync."
            logger.info("Supabase configured in Development Sandbox mode with pre-seeded jewelry enterprise dataset.")

    @classmethod
    def get_service_client(cls) -> Optional[Client]:
        return cls._service_client

    @classmethod
    def get_anon_client(cls) -> Optional[Client]:
        return cls._anon_client

    @classmethod
    def is_connected(cls) -> bool:
        return cls._is_live_connected

    @classmethod
    def get_status(cls) -> Dict[str, Any]:
        return {
            "supabase_url": settings.SUPABASE_URL,
            "is_live_connected": cls._is_live_connected,
            "mode": "Live Supabase Cloud" if cls._is_live_connected else "Development Sandbox (Pre-seeded DB)",
            "connection_error": cls._connection_error,
            "tables_in_store": list(cls._store.keys()),
            "total_records": sum(len(records) for records in cls._store.values())
        }

    @classmethod
    def get_store(cls) -> Dict[str, List[Dict[str, Any]]]:
        return cls._store

    @classmethod
    def _init_mock_store(cls):
        """Pre-seeds rich jewelry enterprise dataset matching 20260928000003_seed_data.sql"""
        now = datetime.now(timezone.utc).isoformat()
        future_2d = (datetime.now(timezone.utc) + timedelta(days=2)).isoformat()
        future_7d = (datetime.now(timezone.utc) + timedelta(days=7)).isoformat()
        future_10d = (datetime.now(timezone.utc) + timedelta(days=10)).isoformat()
        today_date = datetime.now(timezone.utc).strftime("%Y-%m-%d")

        company_id = "11111111-1111-1111-1111-111111111111"

        cls._store = {
            "companies": [
                {
                    "id": company_id,
                    "name": "Sarjan Fine Jewels",
                    "slug": "sarjan-jewels",
                    "industry": "Fine Jewelry & Bespoke Manufacturing",
                    "currency": "INR",
                    "currency_symbol": "₹",
                    "support_phone": "+91 98250 00000",
                    "support_email": "admin@sarjan.tech",
                    "website": "https://sarjanfinejewels.com",
                    "settings": {
                        "ai_confidence_auto_threshold": 0.90,
                        "ai_confidence_safe_threshold": 0.60,
                        "auto_approval_enabled": False,
                        "business_hours": {"start": "09:00", "end": "19:00", "timezone": "Asia/Kolkata"}
                    },
                    "is_active": True,
                    "created_at": now,
                    "updated_at": now
                }
            ],
            "roles": [
                {"id": "22222222-2222-2222-2222-222222222221", "code": "SUPER_ADMIN", "name": "Super Administrator"},
                {"id": "22222222-2222-2222-2222-222222222222", "code": "ADMIN", "name": "Administrator"},
                {"id": "22222222-2222-2222-2222-222222222223", "code": "MANAGER", "name": "Operations Manager"},
                {"id": "22222222-2222-2222-2222-222222222224", "code": "TEAM_LEAD", "name": "Department Lead"},
                {"id": "22222222-2222-2222-2222-222222222225", "code": "TEAM_MEMBER", "name": "Artisan / CAD Specialist"},
                {"id": "22222222-2222-2222-2222-222222222226", "code": "SUPPORT_AGENT", "name": "Customer Support"},
                {"id": "22222222-2222-2222-2222-222222222227", "code": "CUSTOMER", "name": "Customer"}
            ],
            "users": [
                {
                    "id": "33333333-3333-3333-3333-333333333331",
                    "company_id": company_id,
                    "role_code": "ADMIN",
                    "name": "Abhishek Administrator",
                    "email": "admin@sarjan.tech",
                    "phone": "+91 98250 99999",
                    "department": "Executive Management",
                    "status": "ACTIVE",
                    "workload_count": 3
                },
                {
                    "id": "33333333-3333-3333-3333-333333333332",
                    "company_id": company_id,
                    "role_code": "TEAM_MEMBER",
                    "name": "Amit Patel (CAD Lead)",
                    "email": "amit.cad@sarjan.tech",
                    "phone": "+91 98250 88888",
                    "department": "Design & CAD",
                    "status": "ACTIVE",
                    "workload_count": 5
                },
                {
                    "id": "33333333-3333-3333-3333-333333333333",
                    "company_id": company_id,
                    "role_code": "TEAM_MEMBER",
                    "name": "Rajesh Varma (Master Goldsmith)",
                    "email": "rajesh.prod@sarjan.tech",
                    "phone": "+91 98250 77777",
                    "department": "Production & Casting",
                    "status": "ACTIVE",
                    "workload_count": 7
                },
                {
                    "id": "33333333-3333-3333-3333-333333333334",
                    "company_id": company_id,
                    "role_code": "TEAM_MEMBER",
                    "name": "Pooja Iyer (Hallmarking & QC)",
                    "email": "pooja.qc@sarjan.tech",
                    "phone": "+91 98250 66666",
                    "department": "Quality Control",
                    "status": "ACTIVE",
                    "workload_count": 2
                },
                {
                    "id": "33333333-3333-3333-3333-333333333335",
                    "company_id": company_id,
                    "role_code": "SUPPORT_AGENT",
                    "name": "Sneha Shah (VIP Concierge)",
                    "email": "support@sarjan.tech",
                    "phone": "+91 98250 55555",
                    "department": "Customer Support",
                    "status": "ACTIVE",
                    "workload_count": 4
                }
            ],
            "customers": [
                {
                    "id": "44444444-4444-4444-4444-444444444441",
                    "company_id": company_id,
                    "name": "Rahul Patel",
                    "phone": "+919825012345",
                    "email": "rahul.patel@gmail.com",
                    "company": "Patel Diamond Exports",
                    "tier": "VIP",
                    "city": "Ahmedabad",
                    "state": "Gujarat",
                    "tags": ["VIP", "Wholesale", "Custom CAD"],
                    "notes": "Preferred 18K White Gold with VVS diamonds",
                    "total_orders": 4,
                    "total_spent": 380000.00,
                    "created_at": now
                },
                {
                    "id": "44444444-4444-4444-4444-444444444442",
                    "company_id": company_id,
                    "name": "Amit Shah",
                    "phone": "+919825123456",
                    "email": "amit.shah@relstar.com",
                    "company": "Shah Heritage",
                    "tier": "PLATINUM",
                    "city": "Mumbai",
                    "state": "Maharashtra",
                    "tags": ["Bridal", "Kundan"],
                    "notes": "Prefers hallmark certification on delivery",
                    "total_orders": 2,
                    "total_spent": 215000.00,
                    "created_at": now
                },
                {
                    "id": "44444444-4444-4444-4444-444444444443",
                    "company_id": company_id,
                    "name": "Priya Sharma",
                    "phone": "+919825234567",
                    "email": "priya.sharma@yahoo.com",
                    "company": "Self",
                    "tier": "GOLD",
                    "city": "Surat",
                    "state": "Gujarat",
                    "tags": ["Solitaire", "Modern"],
                    "notes": "Custom anniversary ring order",
                    "total_orders": 1,
                    "total_spent": 85000.00,
                    "created_at": now
                },
                {
                    "id": "44444444-4444-4444-4444-444444444444",
                    "company_id": company_id,
                    "name": "Vikram Mehta",
                    "phone": "+919825345678",
                    "email": "vikram.mehta@outlook.com",
                    "company": "Mehta Gems",
                    "tier": "STANDARD",
                    "city": "Delhi",
                    "state": "Delhi",
                    "tags": ["Inquiry", "WhatsApp"],
                    "notes": "First time inquiry via WhatsApp Cloud API",
                    "total_orders": 0,
                    "total_spent": 0.00,
                    "created_at": now
                },
                {
                    "id": "44444444-4444-4444-4444-444444444445",
                    "company_id": company_id,
                    "name": "Ananya Desai",
                    "phone": "+919825456789",
                    "email": "ananya.desai@gmail.com",
                    "company": "Studio Desai",
                    "tier": "GOLD",
                    "city": "Bengaluru",
                    "state": "Karnataka",
                    "tags": ["Polki", "Platinum"],
                    "notes": "Interested in platinum bands",
                    "total_orders": 1,
                    "total_spent": 65000.00,
                    "created_at": now
                }
            ],
            "products": [
                {
                    "id": "55555555-5555-5555-5555-555555555551",
                    "company_id": company_id,
                    "sku": "RNG-SOL-001",
                    "name": "Royal Solitaire Diamond Ring",
                    "category": "Rings",
                    "metal_type": "18K White Gold",
                    "base_price": 85000.00,
                    "making_charges": 6500.00,
                    "purity": "18K / 750",
                    "gross_weight_grams": 4.250,
                    "net_weight_grams": 4.010,
                    "stock_quantity": 12,
                    "is_customizable": True
                },
                {
                    "id": "55555555-5555-5555-5555-555555555552",
                    "company_id": company_id,
                    "sku": "NCK-KND-002",
                    "name": "Heritage Kundan Choker Necklace",
                    "category": "Necklaces",
                    "metal_type": "22K Yellow Gold",
                    "base_price": 320000.00,
                    "making_charges": 24000.00,
                    "purity": "22K / 916",
                    "gross_weight_grams": 48.500,
                    "net_weight_grams": 42.100,
                    "stock_quantity": 3,
                    "is_customizable": True
                },
                {
                    "id": "55555555-5555-5555-5555-555555555556",
                    "company_id": company_id,
                    "sku": "BND-PLT-006",
                    "name": "Men's Platinum Diamond Band",
                    "category": "Rings",
                    "metal_type": "Platinum 950",
                    "base_price": 68000.00,
                    "making_charges": 5800.00,
                    "purity": "Pt 950",
                    "gross_weight_grams": 8.200,
                    "net_weight_grams": 8.160,
                    "stock_quantity": 18,
                    "is_customizable": True
                }
            ],
            "production_capacity": [
                {
                    "id": "77777777-7777-7777-7777-777777777771",
                    "company_id": company_id,
                    "date": today_date,
                    "department": "Production",
                    "total_capacity_units": 100,
                    "used_capacity_units": 50,
                    "available_capacity_units": 50,
                    "notes": "Bench casting capacity for today"
                }
            ],
            "orders": [
                {
                    "id": "66666666-6666-6666-6666-666666666625",
                    "company_id": company_id,
                    "order_number": "ORD-1025",
                    "customer_id": "44444444-4444-4444-4444-444444444441",
                    "customer_name": "Rahul Patel",
                    "product_name": "Custom Solitaire Diamond Ring (Size 14)",
                    "quantity": 50,
                    "tracking_token": "SARJAN-2026-8F42",
                    "status": "PRODUCTION",
                    "priority": "HIGH",
                    "total": 82400.00,
                    "paid_amount": 40000.00,
                    "remaining_amount": 42400.00,
                    "payment_status": "PARTIAL",
                    "expected_delivery": future_7d,
                    "assigned_user_id": "33333333-3333-3333-3333-333333333333",
                    "assigned_user_name": "Rajesh Varma (Master Goldsmith)",
                    "created_at": now
                },
                {
                    "id": "66666666-6666-6666-6666-666666666626",
                    "company_id": company_id,
                    "order_number": "ORD-1026",
                    "customer_id": "44444444-4444-4444-4444-444444444442",
                    "customer_name": "Amit Shah",
                    "product_name": "Men's Platinum Diamond Band (Size 20)",
                    "quantity": 50,
                    "tracking_token": "SARJAN-2026-9A11",
                    "status": "APPROVAL_PENDING",
                    "priority": "HIGH",
                    "total": 77250.00,
                    "paid_amount": 77250.00,
                    "remaining_amount": 0.00,
                    "payment_status": "PAID",
                    "expected_delivery": future_7d,
                    "assigned_user_id": None,
                    "assigned_user_name": "Unassigned",
                    "created_at": now
                },
                {
                    "id": "66666666-6666-6666-6666-666666666627",
                    "company_id": company_id,
                    "order_number": "ORD-1027",
                    "customer_id": "44444444-4444-4444-4444-444444444443",
                    "customer_name": "Priya Sharma",
                    "product_name": "Royal Solitaire Diamond Ring (Custom Engraving)",
                    "quantity": 1,
                    "tracking_token": "SARJAN-2026-3C77",
                    "status": "DESIGN",
                    "priority": "NORMAL",
                    "total": 82400.00,
                    "paid_amount": 82400.00,
                    "remaining_amount": 0.00,
                    "payment_status": "PAID",
                    "expected_delivery": future_10d,
                    "assigned_user_id": "33333333-3333-3333-3333-333333333332",
                    "assigned_user_name": "Amit Patel (CAD Lead)",
                    "created_at": now
                },
                {
                    "id": "66666666-6666-6666-6666-666666666628",
                    "company_id": company_id,
                    "order_number": "ORD-1028",
                    "customer_id": "44444444-4444-4444-4444-444444444445",
                    "customer_name": "Ananya Desai",
                    "product_name": "Men's Platinum Diamond Band",
                    "quantity": 1,
                    "tracking_token": "SARJAN-2026-4D88",
                    "status": "QUALITY_CHECK",
                    "priority": "URGENT",
                    "total": 66950.00,
                    "paid_amount": 66950.00,
                    "remaining_amount": 0.00,
                    "payment_status": "PAID",
                    "expected_delivery": future_2d,
                    "assigned_user_id": "33333333-3333-3333-3333-333333333334",
                    "assigned_user_name": "Pooja Iyer (Hallmarking & QC)",
                    "created_at": now
                }
            ],
            "approvals": [
                {
                    "id": "88888888-8888-8888-8888-888888888881",
                    "company_id": company_id,
                    "order_id": "66666666-6666-6666-6666-666666666625",
                    "order_number": "ORD-1025",
                    "customer_name": "Rahul Patel",
                    "quantity": 50,
                    "value": 82400.00,
                    "type": "PRODUCTION_CAPACITY",
                    "required_capacity_units": 50,
                    "available_capacity_units": 50,
                    "status": "APPROVED",
                    "decision_notes": "Batch 1 capacity verified and locked for production."
                },
                {
                    "id": "88888888-8888-8888-8888-888888888882",
                    "company_id": company_id,
                    "order_id": "66666666-6666-6666-6666-666666666626",
                    "order_number": "ORD-1026",
                    "customer_name": "Amit Shah",
                    "quantity": 50,
                    "value": 77250.00,
                    "type": "PRODUCTION_CAPACITY",
                    "required_capacity_units": 50,
                    "available_capacity_units": 0,
                    "status": "PENDING",
                    "decision_notes": "Waiting for bench slot or admin schedule decision (Order B conflict example)."
                }
            ],
            "workflow_tasks": [
                {
                    "id": "99999999-9999-9999-9999-999999999991",
                    "company_id": company_id,
                    "task_number": "TSK-1025",
                    "order_id": "66666666-6666-6666-6666-666666666625",
                    "order_number": "ORD-1025",
                    "stage_key": "PRODUCTION",
                    "department": "Production",
                    "title": "Cast 50 units in 18K White Gold",
                    "description": "Cast and assemble ring mountings, set center stones",
                    "priority": "HIGH",
                    "status": "IN_PROGRESS",
                    "assigned_to": "Rajesh Varma (Master Goldsmith)",
                    "deadline": future_2d
                },
                {
                    "id": "99999999-9999-9999-9999-999999999992",
                    "company_id": company_id,
                    "task_number": "TSK-1027",
                    "order_id": "66666666-6666-6666-6666-666666666627",
                    "order_number": "ORD-1027",
                    "stage_key": "DESIGN",
                    "department": "Design",
                    "title": "Create 3D CAD matrix rendering for customer review",
                    "description": "Render with 1.2ct cushion cut stone and send proof to customer",
                    "priority": "HIGH",
                    "status": "IN_PROGRESS",
                    "assigned_to": "Amit Patel (CAD Lead)",
                    "deadline": future_2d
                },
                {
                    "id": "99999999-9999-9999-9999-999999999993",
                    "company_id": company_id,
                    "task_number": "TSK-1028",
                    "order_id": "66666666-6666-6666-6666-666666666628",
                    "order_number": "ORD-1028",
                    "stage_key": "QUALITY_CHECK",
                    "department": "Quality Control",
                    "title": "BIS Hallmarking & Diamond Clarity Certification",
                    "description": "Perform XRF purity test and issue guarantee card",
                    "priority": "URGENT",
                    "status": "TODO",
                    "assigned_to": "Pooja Iyer (Hallmarking & QC)",
                    "deadline": future_2d
                }
            ],
            "audit_logs": [
                {
                    "id": str(uuid.uuid4()),
                    "company_id": company_id,
                    "user_email": "admin@sarjan.tech",
                    "action": "APPROVE_ORDER",
                    "entity_type": "orders",
                    "entity_id": "ORD-1025",
                    "details": "Order #ORD-1025 approved for Production (Batch 1: 50 units). Token SARJAN-2026-8F42 active.",
                    "created_at": now
                },
                {
                    "id": str(uuid.uuid4()),
                    "company_id": company_id,
                    "user_email": "admin@sarjan.tech",
                    "action": "CREATE_ORDER",
                    "entity_type": "orders",
                    "entity_id": "ORD-1026",
                    "details": "Simultaneous order queued: ORD-1026 (50 units) routed to Approval Queue due to zero remaining capacity.",
                    "created_at": now
                }
            ],
            "notifications": [
                {
                    "id": str(uuid.uuid4()),
                    "company_id": company_id,
                    "title": "Approval Required: Capacity Conflict",
                    "message": "Order #ORD-1026 (Amit Shah - 50 units) is waiting for bench capacity. Total today: 100, Used: 50, Remaining: 50 (allocated to ORD-1025).",
                    "type": "APPROVAL_REQUIRED",
                    "is_read": False,
                    "created_at": now
                }
            ]
        }

# Auto-initialize on module load
SupabaseManager.initialize()
