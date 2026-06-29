"""
API 数据模型定义
统一返回格式遵循 README 规范：
{ success, code, message, data, traceId, timestamp }
"""

import uuid
import time
from typing import Any, Optional
from pydantic import BaseModel, Field


# ==================== 统一返回体 ====================

class ApiResponse(BaseModel):
    """统一 API 返回格式"""
    success: bool = True
    code: str = "000000"
    message: str = "操作成功"
    data: Any = None
    traceId: str = Field(default_factory=lambda: uuid.uuid4().hex[:16])
    timestamp: int = Field(default_factory=lambda: int(time.time() * 1000))


def success(data: Any = None, message: str = "操作成功") -> ApiResponse:
    return ApiResponse(success=True, code="000000", message=message, data=data)


def error(code: str, message: str, data: Any = None) -> ApiResponse:
    return ApiResponse(success=False, code=code, message=message, data=data if data is not None else {})


# ==================== Chat 问答 ====================

class ChatRequest(BaseModel):
    userId: str = Field(..., description="用户 ID")
    question: str = Field(..., min_length=1, max_length=500, description="用户问题")
    context: Optional[dict] = Field(default=None, description="可选上下文 (orderId, productId)")


class ChatSource(BaseModel):
    title: str
    url: str = ""


class ChatResponse(BaseModel):
    answer: str
    sources: list[ChatSource] = []
    disclaimer: str = ""
    relatedProducts: list[str] = []
    answerSource: str = "ai_model"  # knowledge_base | ai_model


# ==================== Recommend 推荐 ====================

class RecommendRequest(BaseModel):
    userId: str = Field(..., description="用户 ID")
    lat: Optional[float] = Field(default=None, description="纬度")
    lng: Optional[float] = Field(default=None, description="经度")
    limit: int = Field(default=10, ge=1, le=50, description="返回数量")


class RecommendItem(BaseModel):
    productId: str
    productName: str = ""
    score: float
    reasons: list[str] = []


class RecommendResponse(BaseModel):
    recommendations: list[RecommendItem]


# ==================== Stores Nearby LBS ====================

class StoreItem(BaseModel):
    storeId: str
    name: str
    address: str
    distance: float
    rating: float = 0.0
    tags: list[str] = []


class StoresNearbyResponse(BaseModel):
    stores: list[StoreItem]
    total: int


# ==================== Copywriting 文案生成 ====================

class CopywritingRequest(BaseModel):
    productId: str = Field(..., description="商品 ID")
    productType: str = Field(..., description="商品类型: pet_living | pet_supply")
    attributes: dict = Field(default={}, description="商品属性")


class CopywritingResponse(BaseModel):
    description: str = ""
    videoScript: str = ""
    marketingCopy: str = ""
