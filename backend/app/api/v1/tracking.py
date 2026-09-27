from fastapi import APIRouter
from app.core.database import SupabaseManager
from app.models.schemas import ApiResponse
from app.core.errors import NotFoundError

router = APIRouter(prefix="/track", tags=["Customer Tracking Portal (Public)"])

WORKFLOW_STAGES = [
    {"key": "ORDER_RECEIVED", "label": "Order Received", "desc": "Bespoke jewelry order registered in Sarjan atelier system"},
    {"key": "PAYMENT_CONFIRMED", "label": "Payment Confirmed", "desc": "Deposit / full payment verified"},
    {"key": "DESIGN", "label": "CAD & Design", "desc": "3D matrix model designed by master jewelry artisan"},
    {"key": "DESIGN_APPROVAL", "label": "Design Approved", "desc": "3D proof approved by customer"},
    {"key": "PRODUCTION", "label": "Production & Casting", "desc": "Precious metal casting, mounting and gemstone setting"},
    {"key": "QUALITY_CHECK", "label": "Quality Audit & Hallmarking", "desc": "BIS hallmark inspection and diamond clarity test"},
    {"key": "PACKAGING", "label": "Luxury Packaging", "desc": "Protective luxury presentation box and authenticity certificate"},
    {"key": "SHIPPING", "label": "Armored Logistics & Dispatch", "desc": "Insured secured courier dispatched"},
    {"key": "DELIVERED", "label": "Delivered", "desc": "Successfully delivered into recipient hands"}
]

@router.get("/{token}", response_model=ApiResponse)
async def track_order_by_token(token: str):
    """Public customer tracking lookup by secure token (e.g., SARJAN-2026-8F42). Exposes ONLY authorized customer details."""
    store = SupabaseManager.get_store()
    clean_token = token.strip().upper()
    
    order = next((o for o in store.get("orders", []) if o.get("tracking_token", "").upper() == clean_token), None)
    
    if not order:
        raise NotFoundError(f"No order found matching tracking token '{clean_token}'. Please verify your token.")
        
    current_status = order["status"]
    
    # Calculate stage progression
    current_stage_idx = 0
    stage_keys = [s["key"] for s in WORKFLOW_STAGES]
    if current_status in stage_keys:
        current_stage_idx = stage_keys.index(current_status)
    elif current_status == "APPROVAL_PENDING":
        current_stage_idx = 1  # Waiting after payment
        
    stages_with_status = []
    for idx, s in enumerate(WORKFLOW_STAGES):
        if idx < current_stage_idx:
            status_flag = "COMPLETED"
        elif idx == current_stage_idx:
            status_flag = "CURRENT"
        else:
            status_flag = "UPCOMING"
            
        stages_with_status.append({
            "key": s["key"],
            "label": s["label"],
            "desc": s["desc"],
            "state": status_flag
        })
        
    customer_safe_data = {
        "order_number": order["order_number"],
        "tracking_token": order["tracking_token"],
        "customer_name": order.get("customer_name"),
        "product_name": order.get("product_name"),
        "quantity": order.get("quantity", 1),
        "total": order["total"],
        "paid_amount": order["paid_amount"],
        "remaining_amount": order["remaining_amount"],
        "payment_status": order["payment_status"],
        "status": order["status"],
        "expected_delivery": order.get("expected_delivery"),
        "stages": stages_with_status
    }
    
    return ApiResponse(
        success=True,
        message="Order tracking details retrieved",
        data=customer_safe_data
    )
