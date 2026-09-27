from typing import Optional, List, Dict, Any
from datetime import datetime
from pydantic import BaseModel, Field, EmailStr

# Standard API Envelope
class ApiResponse(BaseModel):
    success: bool = True
    message: Optional[str] = None
    data: Optional[Any] = None

# Auth Schemas
class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class SwitchRoleRequest(BaseModel):
    role: str = Field(..., description="SUPER_ADMIN, ADMIN, MANAGER, TEAM_MEMBER, SUPPORT_AGENT, CUSTOMER")

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: Dict[str, Any]

# Company Schemas
class CompanyResponse(BaseModel):
    id: str
    name: str
    slug: str
    industry: str
    currency: str
    currency_symbol: str
    support_phone: Optional[str] = None
    support_email: Optional[str] = None
    website: Optional[str] = None
    settings: Dict[str, Any]

# Customer Schemas
class CustomerCreate(BaseModel):
    name: str
    phone: str
    email: Optional[EmailStr] = None
    company: Optional[str] = None
    tier: str = "STANDARD"
    city: Optional[str] = None
    state: Optional[str] = None
    tags: List[str] = []
    notes: Optional[str] = None

class CustomerResponse(BaseModel):
    id: str
    company_id: str
    name: str
    phone: str
    email: Optional[str] = None
    company: Optional[str] = None
    tier: str
    city: Optional[str] = None
    state: Optional[str] = None
    tags: List[str]
    notes: Optional[str] = None
    total_orders: int
    total_spent: float
    created_at: str

# Order Schemas
class OrderCreate(BaseModel):
    customer_id: str
    product_name: str
    quantity: int = Field(gt=0)
    unit_price: float = Field(gt=0)
    priority: str = "NORMAL"
    notes: Optional[str] = None

class OrderStatusUpdate(BaseModel):
    status: str
    reason: Optional[str] = None

class OrderResponse(BaseModel):
    id: str
    company_id: str
    order_number: str
    customer_id: str
    customer_name: Optional[str] = None
    product_name: Optional[str] = None
    quantity: Optional[int] = 1
    tracking_token: Optional[str] = None
    status: str
    priority: str
    total: float
    paid_amount: float
    remaining_amount: float
    payment_status: str
    expected_delivery: Optional[str] = None
    assigned_user_name: Optional[str] = None
    created_at: str

# Approval Schemas
class ApprovalActionRequest(BaseModel):
    action: str = Field(..., description="APPROVE, HOLD, REJECT, SCHEDULE, SPLIT")
    decision_notes: Optional[str] = None
    scheduled_for_date: Optional[str] = None
    split_quantity_now: Optional[int] = None

# Tracking Portal Token Verification
class TokenVerifyRequest(BaseModel):
    token: str

class TrackingOrderResponse(BaseModel):
    order_number: str
    tracking_token: str
    customer_name: str
    product_name: str
    quantity: int
    order_value: float
    paid_amount: float
    remaining_amount: float
    status: str
    expected_delivery: Optional[str]
    stages: List[Dict[str, Any]]
