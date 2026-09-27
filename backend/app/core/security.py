from typing import Optional, List, Dict, Any
from datetime import datetime, timezone, timedelta
import jwt
from fastapi import Depends, HTTPException, Security, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.core.config import settings
from app.core.errors import UnauthorizedError, ForbiddenError
from app.core.logging import logger

security_scheme = HTTPBearer(auto_error=False)

# Roles hierarchy & permissions
ROLE_PERMISSIONS: Dict[str, List[str]] = {
    "SUPER_ADMIN": ["*"],
    "ADMIN": [
        "orders:*", "approvals:*", "capacity:*", "customers:*", "teams:*", 
        "tasks:*", "products:*", "payments:*", "knowledge:*", "reports:*", 
        "audit:*", "settings:*"
    ],
    "MANAGER": [
        "orders:read", "orders:write", "approvals:manage", "capacity:manage",
        "teams:read", "teams:write", "tasks:manage", "customers:read"
    ],
    "TEAM_LEAD": [
        "orders:read", "tasks:read", "tasks:write", "teams:read"
    ],
    "TEAM_MEMBER": [
        "tasks:read", "tasks:update_status", "orders:read"
    ],
    "SUPPORT_AGENT": [
        "customers:read", "customers:write", "messages:read", "messages:write", "tickets:manage"
    ],
    "CUSTOMER": [
        "portal:track", "orders:view_own"
    ]
}

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)
    return encoded_jwt

def decode_token(token: str) -> dict:
    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        raise UnauthorizedError("Session has expired. Please log in again.")
    except jwt.InvalidTokenError:
        raise UnauthorizedError("Invalid authentication credentials.")

class CurrentUser:
    def __init__(self, id: str, email: str, role: str, company_id: str, name: str):
        self.id = id
        self.email = email
        self.role = role
        self.company_id = company_id
        self.name = name

async def get_current_user(credentials: Optional[HTTPAuthorizationCredentials] = Security(security_scheme)) -> CurrentUser:
    """Authenticates user via Bearer token, or provides demo admin profile for rapid inspection if header is omitted."""
    if not credentials:
        # Development convenience default for local testing
        return CurrentUser(
            id="33333333-3333-3333-3333-333333333331",
            email="admin@sarjan.tech",
            role="ADMIN",
            company_id="11111111-1111-1111-1111-111111111111",
            name="Abhishek Administrator"
        )
    
    payload = decode_token(credentials.credentials)
    user_id = payload.get("sub") or payload.get("user_id")
    email = payload.get("email")
    role = payload.get("role", "ADMIN")
    company_id = payload.get("company_id", "11111111-1111-1111-1111-111111111111")
    name = payload.get("name", "User")
    
    if not user_id:
        raise UnauthorizedError("Could not validate credentials.")
        
    return CurrentUser(id=user_id, email=email, role=role, company_id=company_id, name=name)

def require_roles(allowed_roles: List[str]):
    def role_dependency(current_user: CurrentUser = Depends(get_current_user)):
        if current_user.role == "SUPER_ADMIN":
            return current_user
        if current_user.role not in allowed_roles:
            raise ForbiddenError(f"Access denied. Requires one of roles: {', '.join(allowed_roles)}")
        return current_user
    return role_dependency
