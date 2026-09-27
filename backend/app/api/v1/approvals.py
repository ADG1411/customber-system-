from fastapi import APIRouter, Depends, HTTPException
from typing import Optional, List
from app.core.security import get_current_user, CurrentUser, require_roles
from app.core.database import SupabaseManager
from app.models.schemas import ApiResponse, ApprovalActionRequest
from app.core.errors import NotFoundError
import uuid
from datetime import datetime, timezone

router = APIRouter(prefix="/approvals", tags=["Production Approvals & Capacity Queue"])

@router.get("", response_model=ApiResponse)
async def list_approvals(
    status: Optional[str] = None,
    current_user: CurrentUser = Depends(get_current_user)
):
    """Lists approval queue items with capacity and order details."""
    store = SupabaseManager.get_store()
    approvals = [a for a in store.get("approvals", []) if a.get("company_id") == current_user.company_id]
    
    if status:
        approvals = [a for a in approvals if a.get("status", "").upper() == status.upper()]
        
    return ApiResponse(success=True, data=approvals)

@router.post("/{approval_id}/action", response_model=ApiResponse)
async def handle_approval_action(
    approval_id: str,
    req: ApprovalActionRequest,
    current_user: CurrentUser = Depends(require_roles(["ADMIN", "MANAGER", "SUPER_ADMIN"]))
):
    """Executes approval decisions: APPROVE, HOLD, REJECT, SCHEDULE, SPLIT."""
    store = SupabaseManager.get_store()
    approval = next(
        (a for a in store.get("approvals", []) if a["id"] == approval_id and a.get("company_id") == current_user.company_id),
        None
    )
    if not approval:
        raise NotFoundError(f"Approval request {approval_id} not found")
        
    action = req.action.upper()
    order = next((o for o in store.get("orders", []) if o["id"] == approval.get("order_id")), None)
    
    if action == "APPROVE":
        approval["status"] = "APPROVED"
        approval["decision_notes"] = req.decision_notes or "Approved by admin for production dispatch."
        if order:
            order["status"] = "PRODUCTION"
            # Update capacity metrics
            capacity_list = store.get("production_capacity", [])
            if capacity_list:
                cap = capacity_list[0]
                cap["used_capacity_units"] = min(cap["total_capacity_units"], cap["used_capacity_units"] + approval["required_capacity_units"])
                cap["available_capacity_units"] = max(0, cap["total_capacity_units"] - cap["used_capacity_units"])
                
    elif action == "HOLD":
        approval["status"] = "HOLD"
        approval["decision_notes"] = req.decision_notes or "Placed on hold pending bench opening."
        if order:
            order["status"] = "ON_HOLD"
            
    elif action == "REJECT":
        approval["status"] = "REJECTED"
        approval["decision_notes"] = req.decision_notes or "Rejected by production manager."
        if order:
            order["status"] = "CANCELLED"
            
    elif action == "SCHEDULE":
        approval["status"] = "SCHEDULED"
        approval["scheduled_for_date"] = req.scheduled_for_date or "Tomorrow"
        approval["decision_notes"] = req.decision_notes or f"Scheduled for bench run on {req.scheduled_for_date}"
        
    elif action == "SPLIT":
        # Section 25 Split order: 50 -> Production Now, remaining -> Later
        split_qty = req.split_quantity_now or (approval["required_capacity_units"] // 2)
        remaining_qty = approval["required_capacity_units"] - split_qty
        approval["status"] = "SPLIT"
        approval["decision_notes"] = f"Split order: {split_qty} units approved into Production Now, {remaining_qty} units scheduled in Batch 2."
        if order:
            order["status"] = "PRODUCTION"
            order["quantity"] = split_qty
            
    # Audit log
    store.setdefault("audit_logs", []).append({
        "id": str(uuid.uuid4()),
        "company_id": current_user.company_id,
        "user_email": current_user.email,
        "action": f"APPROVAL_{action}",
        "entity_type": "approvals",
        "entity_id": approval.get("order_number", approval_id),
        "details": f"Decision: {action}. Notes: {approval['decision_notes']}",
        "created_at": datetime.now(timezone.utc).isoformat()
    })
    
    return ApiResponse(
        success=True,
        message=f"Approval action {action} processed successfully",
        data={"approval": approval, "order": order}
    )
