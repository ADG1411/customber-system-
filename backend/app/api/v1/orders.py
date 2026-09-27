from fastapi import APIRouter, Depends, Query
from typing import Optional, List
from app.core.security import get_current_user, CurrentUser, require_roles
from app.core.database import SupabaseManager
from app.models.schemas import ApiResponse, OrderCreate, OrderStatusUpdate
from app.core.errors import NotFoundError, CapacityConflictError
import uuid
from datetime import datetime, timezone, timedelta

router = APIRouter(prefix="/orders", tags=["Order Management & Workflow"])

@router.get("", response_model=ApiResponse)
async def list_orders(
    status: Optional[str] = None,
    priority: Optional[str] = None,
    current_user: CurrentUser = Depends(get_current_user)
):
    """Lists orders with status and priority filtering."""
    store = SupabaseManager.get_store()
    orders = [o for o in store.get("orders", []) if o.get("company_id") == current_user.company_id]
    
    if status:
        orders = [o for o in orders if o.get("status", "").upper() == status.upper()]
    if priority:
        orders = [o for o in orders if o.get("priority", "").upper() == priority.upper()]
        
    return ApiResponse(success=True, data=orders)

@router.get("/{order_id}", response_model=ApiResponse)
async def get_order_detail(order_id: str, current_user: CurrentUser = Depends(get_current_user)):
    """Retrieves single order with complete customer details, tasks, and history."""
    store = SupabaseManager.get_store()
    order = next(
        (o for o in store.get("orders", []) if (o["id"] == order_id or o.get("order_number") == order_id) and o.get("company_id") == current_user.company_id),
        None
    )
    if not order:
        raise NotFoundError(f"Order {order_id} not found")
        
    tasks = [t for t in store.get("workflow_tasks", []) if t.get("order_id") == order["id"]]
    approvals = [a for a in store.get("approvals", []) if a.get("order_id") == order["id"]]
    
    return ApiResponse(
        success=True,
        data={
            "order": order,
            "tasks": tasks,
            "approvals": approvals
        }
    )

@router.patch("/{order_id}/status", response_model=ApiResponse)
async def update_order_status(
    order_id: str,
    req: OrderStatusUpdate,
    current_user: CurrentUser = Depends(require_roles(["ADMIN", "MANAGER", "TEAM_LEAD", "SUPER_ADMIN"]))
):
    """Updates order workflow stage and checks capacity if advancing to PRODUCTION."""
    store = SupabaseManager.get_store()
    order = next(
        (o for o in store.get("orders", []) if (o["id"] == order_id or o.get("order_number") == order_id) and o.get("company_id") == current_user.company_id),
        None
    )
    if not order:
        raise NotFoundError(f"Order {order_id} not found")
        
    previous_status = order["status"]
    new_status = req.status.upper()
    
    # Capacity check if entering PRODUCTION
    if new_status == "PRODUCTION" and previous_status != "PRODUCTION":
        capacity_record = store.get("production_capacity", [{}])[0]
        avail = capacity_record.get("available_capacity_units", 0)
        needed = order.get("quantity", 1)
        if avail < needed:
            # Route to approval queue
            order["status"] = "APPROVAL_PENDING"
            # Add to approvals
            approval_entry = {
                "id": str(uuid.uuid4()),
                "company_id": current_user.company_id,
                "order_id": order["id"],
                "order_number": order["order_number"],
                "customer_name": order.get("customer_name", "Customer"),
                "quantity": needed,
                "value": order.get("total", 0.0),
                "type": "PRODUCTION_CAPACITY",
                "required_capacity_units": needed,
                "available_capacity_units": avail,
                "status": "PENDING",
                "decision_notes": f"Automatic hold: Required {needed} units, but bench capacity available is {avail} units."
            }
            store.setdefault("approvals", []).append(approval_entry)
            
            # Log audit
            store.setdefault("audit_logs", []).append({
                "id": str(uuid.uuid4()),
                "company_id": current_user.company_id,
                "user_email": current_user.email,
                "action": "CAPACITY_CONFLICT_ROUTED_TO_APPROVAL",
                "entity_type": "orders",
                "entity_id": order["order_number"],
                "details": f"Attempted move to PRODUCTION, routed to approval queue due to capacity shortage ({avail}/{needed}).",
                "created_at": datetime.now(timezone.utc).isoformat()
            })
            
            return ApiResponse(
                success=True,
                message=f"Insufficient capacity ({avail}/{needed} units). Order routed to Production Approval Queue.",
                data={"order": order, "approval_required": True, "approval": approval_entry}
            )
            
    order["status"] = new_status
    
    # Audit log
    store.setdefault("audit_logs", []).append({
        "id": str(uuid.uuid4()),
        "company_id": current_user.company_id,
        "user_email": current_user.email,
        "action": "CHANGE_STATUS",
        "entity_type": "orders",
        "entity_id": order["order_number"],
        "details": f"Status changed from {previous_status} to {new_status}. Reason: {req.reason or 'User action'}",
        "created_at": datetime.now(timezone.utc).isoformat()
    })
    
    return ApiResponse(
        success=True,
        message=f"Order status updated to {new_status}",
        data={"order": order}
    )
