"""
AI Recommendation Service — FastAPI 应用入口
提供 /chat、/recommend、/stores/nearby 三个核心接口
"""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
from openai import AsyncOpenAI

from app.core.config import settings
from app.schemas.recommendation_schema import (
    success, error,
    ChatRequest, ChatResponse, ChatSource,
    RecommendRequest, RecommendItem, RecommendResponse,
    StoreItem, StoresNearbyResponse,
    CopywritingRequest, CopywritingResponse,
)
from app.rag.prompt_guard import guard
from app.rag.retriever import search_knowledge, format_context
from app.recommender.item_cf.item_cf import recommend as itemcf_recommend
from app.recommender.markov.markov_chain import predict as markov_predict
from app.content_generation.copywriting import generate as generate_copy


# ==================== 应用生命周期 ====================

@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用启动/关闭时执行"""
    app.state.mongo_client = AsyncIOMotorClient(
        settings.mongodb_uri,
        serverSelectionTimeoutMS=3000,
        connectTimeoutMS=3000,
        socketTimeoutMS=5000,
    )
    app.state.db = app.state.mongo_client[settings.MONGODB_DB]
    app.state.llm_client = AsyncOpenAI(
        api_key=settings.LLM_API_KEY,
        base_url=settings.LLM_BASE_URL,
    )
    print(f"[OK] MongoDB connected: {settings.MONGODB_DB}")
    print(f"[OK] LLM ready: {settings.LLM_MODEL}")
    yield
    app.state.mongo_client.close()
    print("[OK] MongoDB connection closed")


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    lifespan=lifespan,
)

# CORS — 允许 Flutter Web 和任意前端跨域
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ==================== 健康检查 ====================

@app.get("/health")
async def health_check():
    """MongoDB 连接健康检查"""
    try:
        await app.state.db.command("ping")
        mongo_status = "ok"
    except Exception as e:
        mongo_status = f"error: {e}"

    return success({
        "service": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "mongodb": mongo_status,
        "llm": "configured" if settings.LLM_API_KEY.strip() else "missing_api_key",
    })


# ==================== API v1 ====================

# ---- RAG 系统提示词 ----

RAG_SYSTEM_PROMPT = """你是 Pet-Emarket 宠物电商平台的 AI 助手。请根据以下知识库文档回答用户问题。

要求：
1. 只基于提供的文档内容回答，不要编造信息
2. 如果文档中没有相关信息，请诚实说「抱歉，我目前没有找到相关的资料」
3. 回答要简洁、准确、易理解
4. 如果涉及宠物健康问题，你的回答末尾必须包含免责声明

当前知识库文档：
{context}"""

GENERAL_SYSTEM_PROMPT = """你是 Pet-Emarket 宠物电商平台的 AI 助手。请根据你的知识回答用户的宠物相关问题。

要求：
1. 回答要简洁、准确、易理解
2. 如果涉及宠物健康问题，你的回答末尾必须包含免责声明
3. 如果不确定，请诚实说明"""

BUSINESS_RESPONSES = {
    "订单": "关于订单问题，建议您前往「我的订单」页面查看订单详情和物流信息。如有退换货需求，可在订单详情中申请。",
    "退款": "关于退款问题，退款将在审核通过后 3-5 个工作日内原路返回。您可以在「我的订单」中查看退款进度。",
    "发货": "订单支付成功后，商家会在 24-48 小时内发货。发货后您将收到物流单号通知。",
    "物流": "您可以在订单详情中查看实时物流信息。如物流长时间未更新，请联系商家客服。",
    "支付": "本平台支持支付宝和微信支付。如遇到支付问题，请检查网络连接后重试。",
    "会员": "会员等级分为普通会员、银卡会员、金卡会员、钻石会员。消费越多等级越高，享受的折扣也越大。",
    "default": "关于这个问题，建议您联系平台客服获取更详细的帮助。",
}

HEALTH_DISCLAIMER = "【免责声明】以上内容仅供参考，不能替代专业兽医诊断。如宠物出现严重健康问题，请立即咨询执业兽医。"

KNOWLEDGE_BASE_TAG = "[此回答来自知识库]"
AI_MODEL_TAG = "[此回答来自 AI 模型自身知识，仅供参考]"


# ---- /chat — RAG 智能问答 ----

@app.post("/api/v1/chat")
async def chat(req: ChatRequest):
    """RAG 智能问答接口"""
    # Step 1: Prompt Guard 安全检测
    guard_result = guard(req.question)
    if not guard_result.passed:
        return error("400004", guard_result.reason)

    # Step 2: 业务型问题 → 模板回答
    if guard_result.question_type == "business":
        answer = _get_business_answer(req.question)
        return success(ChatResponse(
            answer=answer,
            sources=[],
            disclaimer="",
            relatedProducts=[],
            answerSource="template",
        ).model_dump())

    # Step 3: 知识型问题 → RAG 检索
    docs = await search_knowledge(app.state.db, req.question)
    has_knowledge = len(docs) > 0

    # Step 4: 构建上下文 → 调用 LLM
    if has_knowledge:
        context = format_context(docs)
        system_prompt = RAG_SYSTEM_PROMPT.format(context=context)
        answer_source = "knowledge_base"
    else:
        system_prompt = GENERAL_SYSTEM_PROMPT
        answer_source = "ai_model"

    if not settings.LLM_API_KEY.strip():
        return error(
            "LLM_API_KEY_MISSING",
            "AI 模型 API Key 未配置，请在 ai-recommendation-service/.env 或项目根 .env 中设置 LLM_API_KEY",
        )

    try:
        llm_response = await app.state.llm_client.chat.completions.create(
            model=settings.LLM_MODEL,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": req.question},
            ],
            temperature=0.7,
            max_tokens=500,
        )
        raw_answer = llm_response.choices[0].message.content.strip()
    except Exception as exc:
        return error("LLM_UNAVAILABLE", f"AI 模型服务暂时不可用：{exc}")

    # Step 5: 给回答加上来源标识
    if answer_source == "knowledge_base":
        answer = f"{KNOWLEDGE_BASE_TAG}\n{raw_answer}"
    else:
        if AI_MODEL_TAG not in raw_answer:
            answer = f"{AI_MODEL_TAG}\n{raw_answer}"
        else:
            answer = raw_answer

    # Step 6: 健康类问题加免责声明
    disclaimer = HEALTH_DISCLAIMER if guard_result.needs_disclaimer else ""

    # Step 7: 构建 sources
    sources = [
        ChatSource(title=doc["title"], url="")
        for doc in docs
    ]

    return success(ChatResponse(
        answer=answer,
        sources=sources,
        disclaimer=disclaimer,
        relatedProducts=[],
        answerSource=answer_source,
    ).model_dump())


def _get_business_answer(question: str) -> str:
    """根据关键词匹配业务型回答"""
    for keyword, response in BUSINESS_RESPONSES.items():
        if keyword in question:
            return response
    return BUSINESS_RESPONSES["default"]


# ---- /recommend — 混合推荐 ----

@app.post("/api/v1/recommend")
async def recommend(req: RecommendRequest):
    """混合推荐接口 — Item-CF + 马尔可夫链 + 真实商品冷启动"""
    items = []

    # Step 1: Item-CF 协同过滤
    try:
        cf_results = await itemcf_recommend(app.state.db, req.userId)
        for r in cf_results:
            items.append(RecommendItem(
                productId=r["productId"], score=r["score"], reasons=[r["reason"]],
            ))
    except Exception:
        pass

    # Step 2: 马尔可夫链行为预测
    try:
        mk_results = await markov_predict(app.state.db, req.userId)
        for r in mk_results:
            items.append(RecommendItem(
                productId=r["productId"], score=r["score"], reasons=[r["reason"]],
            ))
    except Exception:
        pass

    # Step 3: 用真实商品补全名称；无算法结果时从 MongoDB 商品集合冷启动
    items = await _hydrate_recommendation_products(app.state.db, items)
    if not items:
        items = await _popular_products_from_db(app.state.db, req.limit)

    items.sort(key=lambda x: x.score, reverse=True)
    return success(RecommendResponse(recommendations=items[:req.limit]).model_dump())


async def _hydrate_recommendation_products(db, items: list[RecommendItem]) -> list[RecommendItem]:
    if not items:
        return []
    ids = [item.productId for item in items if item.productId]
    if not ids:
        return items
    try:
        docs = await db["products"].find({
            "$or": [
                {"_id": {"$in": ids}},
                {"id": {"$in": ids}},
                {"productId": {"$in": ids}},
            ]
        }).to_list(length=len(ids))
    except Exception:
        return items

    products = {}
    for doc in docs:
        pid = _product_id(doc)
        if pid:
            products[pid] = doc
    for item in items:
        doc = products.get(item.productId)
        if doc and not item.productName:
            item.productName = _product_name(doc)
    return items


async def _popular_products_from_db(db, limit: int) -> list[RecommendItem]:
    try:
        docs = await db["products"].aggregate([
            {"$match": {
                "$or": [
                    {"status": {"$exists": False}},
                    {"status": {"$in": ["ON_SALE", "APPROVED", "ACTIVE"]}},
                ]
            }},
            {"$addFields": {
                "rankScore": {
                    "$add": [
                        {"$ifNull": ["$sales", 0]},
                        {"$ifNull": ["$viewCount", 0]},
                        {"$ifNull": ["$stock", 0]},
                    ]
                }
            }},
            {"$sort": {"rankScore": -1, "createdAt": -1}},
            {"$limit": limit},
        ]).to_list(length=limit)
    except Exception:
        return []

    recommendations = []
    for index, doc in enumerate(docs):
        pid = _product_id(doc)
        if not pid:
            continue
        recommendations.append(RecommendItem(
            productId=pid,
            productName=_product_name(doc),
            score=round(max(0.1, 0.8 - index * 0.04), 3),
            reasons=["真实商品冷启动：按销量、浏览量和库存排序"],
        ))
    return recommendations


def _product_id(doc: dict) -> str:
    return str(doc.get("productId") or doc.get("id") or doc.get("_id") or "")


def _product_name(doc: dict) -> str:
    return str(doc.get("productName") or doc.get("name") or doc.get("title") or "")


# ---- /stores/nearby — LBS 附近商店 ----

@app.get("/api/v1/stores/nearby")
async def stores_nearby(
    lat: float = 30.28,
    lng: float = 120.14,
    radius: int = 5000,
    limit: int = 20,
):
    """LBS 附近商店搜索 — MongoDB 2dsphere 地理查询"""
    if radius <= 0 or radius > 50000:
        return error("400007", "radius must be 1-50000 meters")
    if lat < -90 or lat > 90 or lng < -180 or lng > 180:
        return error("400007", "invalid lat/lng")

    collection = app.state.db["stores"]
    cursor = collection.aggregate([
        {"$geoNear": {
            "near": {"type": "Point", "coordinates": [lng, lat]},
            "distanceField": "dist",
            "spherical": True,
            "maxDistance": radius,
        }},
        {"$limit": limit},
    ])

    stores = []
    async for doc in cursor:
        stores.append(StoreItem(
            storeId=doc.get("storeId", ""),
            name=doc.get("name", ""),
            address=doc.get("address", ""),
            distance=round(doc.get("dist", 0), 1),
            rating=round(doc.get("rating", 0), 1),
            tags=[str(t) for t in doc.get("tags", [])],
        ))

    return success(StoresNearbyResponse(stores=stores, total=len(stores)).model_dump())


# ---- /copywriting/generate — AI 文案生成 ----

@app.post("/api/v1/copywriting/generate")
async def copywriting(req: CopywritingRequest):
    """AI 文案生成"""
    info = f"名称:{req.productId}"
    for k, v in req.attributes.items():
        info += f" {k}:{v}"
    try:
        text = await generate_copy(app.state.llm_client, req.productType, info)
        return success(CopywritingResponse(description=text).model_dump())
    except Exception:
        return error("400006", "文案生成失败")


# ==================== 启动入口 ====================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=settings.PORT,
        reload=settings.DEBUG,
    )
