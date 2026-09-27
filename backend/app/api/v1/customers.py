from fastapi import APIRouter, Depends, Query
from typing import Optional, List
from app.core.security import get_current_user, CurrentUser, require_roles
from app.core.database import SupabaseManager
from app.models.schemas import ApiResponse, CustomerCreate
from app.core.errors import NotFoundError
import uuid
from datetime import datetime, timezone

router = APIRouter(prefix="/customers", tags=["Customers (CRM)"])

@router.get("", response_model=ApiResponse)
async def list_customers(
    search: Optional[str] = None,
    tier: Optional[str] = None,
    current_user: CurrentUser = Depends(get_current_user)
):
    """Lists customers for the tenant with optional search and tier filtering."""
    store = SupabaseManager.get_store()
    customers = [c for c in store.get("customers", []) if c.get("company_id") == current_user.company_id]
    
    if search:
        s = search.lower()
        customers = [
            c for c in customers
            if s in c["name"].lower() or s in c["phone"].lower() or (c.get("email") and s in c["email"].lower())
        ]
        
    if tier:
        customers = [c for c in customers if c.get("tier", "").upper() == tier.upper()]
        
    return ApiResponse(success=True, data=customers)

@router.get("/{customer_id}", response_model=ApiResponse)
async def get_customer(customer_id: str, current_user: CurrentUser = Depends(get_current_user)):
    """Fetches customer profile, order history, and notes."""
    store = SupabaseManager.get_store()
    customer = next(
        (c for c in store.get("customers", []) if c["id"] == customer_id and c.get("company_id") == current_user.company_id),
        None
    )
    if not customer:
        raise NotFoundError(f"Customer {customer_id} not found")
        
    # Attached orders
    orders = [o for o in store.get("orders", []) if o.get("customer_id") == customer_id]
    
    return ApiResponse(
        success=True,
        data={
            "customer": customer,
            "orders": orders
        }
    )

@router.post("", response_model=ApiResponse)
async def create_customer(
    req: CustomerCreate,
    current_user: CurrentUser = Depends(require_roles(["ADMIN", "MANAGER", "SUPPORT_AGENT", "SUPER_ADMIN"]))
):
    """Creates a new customer record."""
    store = SupabaseManager.get_store()
    new_cust = {
        "id": str(uuid.uuid4()),
        "company_id": current_user.company_id,
        "name": req.name,
        "phone": req.phone,
        "email": req.email,
        "company": req.company,
        "tier": req.tier,
        "city": req.city,
        "state": req.state,
        "tags": req.tags,
        "notes": req.notes,
        "total_orders": 0,
        "total_spent": 0.0,
        "created_at": datetime.now(timezone.utc).isoformat()
    }
    store.setdefault("customers", []).append(new_cust)
    return ApiResponse(success=True, message="Customer created successfully", data=new_cust)
