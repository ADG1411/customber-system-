from fastapi import APIRouter, Depends
from app.core.security import get_current_user, CurrentUser
from app.core.database import SupabaseManager
from app.models.schemas import ApiResponse
from app.core.errors import NotFoundError

router = APIRouter(prefix="/companies", tags=["Companies (Tenants)"])

@router.get("/current", response_model=ApiResponse)
async def get_current_company(current_user: CurrentUser = Depends(get_current_user)):
    """Returns the tenant company information for the current authenticated context."""
    store = SupabaseManager.get_store()
    company = next((c for c in store.get("companies", []) if c["id"] == current_user.company_id), None)
    if not company:
        raise NotFoundError("Company not found for current session")
    return ApiResponse(success=True, data=company)
