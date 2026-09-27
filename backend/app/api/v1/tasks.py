from fastapi import APIRouter, Depends
from typing import Optional
from app.core.security import get_current_user, CurrentUser
from app.core.database import SupabaseManager
from app.models.schemas import ApiResponse
from app.core.errors import NotFoundError
from pydantic import BaseModel

class TaskStatusUpdate(BaseModel):
    status: str

router = APIRouter(prefix="/tasks", tags=["Team Tasks & Workflows"])

@router.get("", response_model=ApiResponse)
async def list_tasks(status: Optional[str] = None, current_user: CurrentUser = Depends(get_current_user)):
    """Lists department tasks across workflow stages."""
    store = SupabaseManager.get_store()
    tasks = [t for t in store.get("workflow_tasks", []) if t.get("company_id") == current_user.company_id]
    if status:
        tasks = [t for t in tasks if t.get("status", "").upper() == status.upper()]
    return ApiResponse(success=True, data=tasks)

@router.patch("/{task_id}/status", response_model=ApiResponse)
async def update_task_status(task_id: str, req: TaskStatusUpdate, current_user: CurrentUser = Depends(get_current_user)):
    """Updates team task execution status."""
    store = SupabaseManager.get_store()
    task = next((t for t in store.get("workflow_tasks", []) if t["id"] == task_id or t.get("task_number") == task_id), None)
    if not task:
        raise NotFoundError(f"Task {task_id} not found")
        
    task["status"] = req.status.upper()
    return ApiResponse(success=True, message=f"Task updated to {req.status}", data=task)
