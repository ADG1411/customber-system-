from fastapi import APIRouter
from app.core.config import settings
from app.core.database import SupabaseManager
from app.models.schemas import ApiResponse

router = APIRouter(tags=["Health & Status"])

@router.get("/health", response_model=ApiResponse)
async def check_health():
    """Returns platform health, version, and Supabase integration status."""
    supabase_status = SupabaseManager.get_status()
    return ApiResponse(
        success=True,
        message="Sarjan Enterprise Platform operational",
        data={
            "service": settings.PROJECT_NAME,
            "version": settings.PROJECT_VERSION,
            "environment": settings.ENVIRONMENT,
            "supabase": supabase_status
        }
    )
