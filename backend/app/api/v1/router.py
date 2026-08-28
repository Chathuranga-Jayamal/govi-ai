from fastapi import APIRouter

from app.api.v1.endpoints import advisory, auth, disease, health

api_router = APIRouter()
api_router.include_router(health.router, prefix="/health", tags=["health"])
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(disease.router, prefix="/disease", tags=["disease"])
api_router.include_router(advisory.router, prefix="/advisory", tags=["advisory"])
