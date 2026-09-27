from fastapi import APIRouter, Depends
from app.core.security import get_current_user, CurrentUser, require_roles
from app.core.database import SupabaseManager
from app.models.schemas import ApiResponse

router = APIRouter(prefix="/audit-logs", tags=["Audit Trail"])

@router.get("", response_model=ApiResponse)
async def list_audit_logs(
    current_user: CurrentUser = Depends(require_roles(["ADMIN", "SUPER_ADMIN", "MANAGER"]))
):
    """Retrieves immutable audit trail of actions taken in the platform."""
    store = SupabaseManager.get_store()
    logs = [l for l in store.get("audit_logs", []) if l.get("company_id") == current_user.company_id]
    # Return sorted with latest first
    logs.reverse()
    return ApiResponse(success=True, data=logs)
