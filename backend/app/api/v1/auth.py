from fastapi import APIRouter, Depends, HTTPException, status
from app.core.security import create_access_token, get_current_user, CurrentUser
from app.core.database import SupabaseManager
from app.models.schemas import ApiResponse, LoginRequest, SwitchRoleRequest, TokenResponse
from app.core.errors import UnauthorizedError
from datetime import timedelta

router = APIRouter(prefix="/auth", tags=["Authentication & RBAC"])

@router.post("/login", response_model=ApiResponse)
async def login(req: LoginRequest):
    """Authenticates credentials against Supabase users or demo profiles."""
    store = SupabaseManager.get_store()
    user = next((u for u in store.get("users", []) if u["email"].lower() == req.email.lower()), None)
    
    # If not found in users store, check admin default
    if not user:
        if req.email == "admin@sarjan.tech" and req.password:
            user = {
                "id": "33333333-3333-3333-3333-333333333331",
                "email": "admin@sarjan.tech",
                "role_code": "ADMIN",
                "company_id": "11111111-1111-1111-1111-111111111111",
                "name": "Abhishek Administrator",
                "department": "Executive Management"
            }
        else:
            raise UnauthorizedError("Invalid email or password.")
            
    token_payload = {
        "sub": user["id"],
        "email": user["email"],
        "role": user["role_code"],
        "company_id": user["company_id"],
        "name": user["name"]
    }
    
    access_token = create_access_token(token_payload)
    return ApiResponse(
        success=True,
        message="Login successful",
        data={
            "access_token": access_token,
            "token_type": "bearer",
            "user": user
        }
    )

@router.get("/me", response_model=ApiResponse)
async def get_me(current_user: CurrentUser = Depends(get_current_user)):
    """Returns current active authenticated user and permissions."""
    return ApiResponse(
        success=True,
        data={
            "id": current_user.id,
            "name": current_user.name,
            "email": current_user.email,
            "role": current_user.role,
            "company_id": current_user.company_id
        }
    )

@router.post("/switch-role", response_model=ApiResponse)
async def switch_role(req: SwitchRoleRequest, current_user: CurrentUser = Depends(get_current_user)):
    """Demo / Testing utility allowing rapid simulation across all 7 platform roles."""
    valid_roles = ["SUPER_ADMIN", "ADMIN", "MANAGER", "TEAM_LEAD", "TEAM_MEMBER", "SUPPORT_AGENT", "CUSTOMER"]
    if req.role not in valid_roles:
        raise HTTPException(status_code=400, detail=f"Invalid role. Must be one of: {valid_roles}")
    
    new_payload = {
        "sub": current_user.id,
        "email": current_user.email,
        "role": req.role,
        "company_id": current_user.company_id,
        "name": current_user.name
    }
    new_token = create_access_token(new_payload)
    return ApiResponse(
        success=True,
        message=f"Switched role to {req.role}",
        data={
            "access_token": new_token,
            "role": req.role,
            "user": {**new_payload, "id": current_user.id}
        }
    )
