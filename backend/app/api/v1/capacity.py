from fastapi import APIRouter, Depends
from app.core.security import get_current_user, CurrentUser
from app.core.database import SupabaseManager
from app.models.schemas import ApiResponse

router = APIRouter(prefix="/capacity", tags=["Production Capacity Planning"])

@router.get("", response_model=ApiResponse)
async def get_capacity_overview(current_user: CurrentUser = Depends(get_current_user)):
    """Returns today's workbench production capacity, used units, and available capacity."""
    store = SupabaseManager.get_store()
    capacity_records = [c for c in store.get("production_capacity", []) if c.get("company_id") == current_user.company_id]
    
    current_cap = capacity_records[0] if capacity_records else {
        "date": "Today",
        "department": "Production",
        "total_capacity_units": 100,
        "used_capacity_units": 50,
        "available_capacity_units": 50,
        "notes": "Bench casting capacity"
    }
    
    return ApiResponse(
        success=True,
        data={
            "current": current_cap,
            "all_records": capacity_records
        }
    )
