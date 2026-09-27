from fastapi import APIRouter
from app.api.v1.health import router as health_router
from app.api.v1.auth import router as auth_router
from app.api.v1.companies import router as companies_router
from app.api.v1.customers import router as customers_router
from app.api.v1.orders import router as orders_router
from app.api.v1.approvals import router as approvals_router
from app.api.v1.capacity import router as capacity_router
from app.api.v1.tracking import router as tracking_router
from app.api.v1.tasks import router as tasks_router
from app.api.v1.audit import router as audit_router

api_router = APIRouter()

api_router.include_router(health_router)
api_router.include_router(auth_router)
api_router.include_router(companies_router)
api_router.include_router(customers_router)
api_router.include_router(orders_router)
api_router.include_router(approvals_router)
api_router.include_router(capacity_router)
api_router.include_router(tracking_router)
api_router.include_router(tasks_router)
api_router.include_router(audit_router)
