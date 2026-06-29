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
)
from app.rag.prompt_guard import guard
from app.rag.retriever import search_knowledge, format_context


# ==================== 应用生命周期 ====================

@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用启动/关闭时执行"""
    app.state.mongo_client = AsyncIOMotorClient(settings.mongodb_uri)
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
    except Exception:
        if has_knowledge:
            raw_answer = _get_fallback_answer(req.question, docs)
        else:
            raw_answer = "抱歉，AI 服务暂时不可用，请稍后重试。"

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


def _get_fallback_answer(question: str, docs: list) -> str:
    """LLM 不可用时的回退回答"""
    if not docs:
        return "抱歉，我目前没有找到与您问题相关的资料。请尝试换一种方式提问，或联系平台客服获取帮助。"

    parts = [f"根据资料库，关于「{question}」的相关信息如下：\n"]
    for doc in docs:
        parts.append(f"• {doc['title']}：{doc['content']}")
    return "\n".join(parts)


# ---- /recommend — 混合推荐 ----

@app.post("/api/v1/recommend")
async def recommend(req: RecommendRequest):
    """混合推荐接口（当前返回 mock 数据）"""
    # TODO 第三阶段: 接入 Item-CF + 马尔可夫链 + 混合推荐
    items = [
        RecommendItem(
            productId="prod_001",
            productName="英短蓝猫幼崽（3个月）",
            score=0.92,
            reasons=["根据你最近浏览的猫咪用品推荐", "距离你 1.2km"],
        ),
        RecommendItem(
            productId="prod_002",
            productName="皇家幼猫粮 2kg",
            score=0.87,
            reasons=["你曾购买过猫粮", "会员专享价"],
        ),
        RecommendItem(
            productId="prod_003",
            productName="猫抓板 大号",
            score=0.75,
            reasons=["养猫必备用品"],
        ),
        RecommendItem(
            productId="prod_004",
            productName="金毛幼犬（2个月）",
            score=0.68,
            reasons=["热门活体宠物 Top 10"],
        ),
        RecommendItem(
            productId="prod_005",
            productName="狗狗磨牙棒 套装",
            score=0.60,
            reasons=["热门推荐"],
        ),
    ]

    return success(RecommendResponse(
        recommendations=items[: req.limit],
    ).model_dump())


# ---- /stores/nearby — LBS 附近商店 ----

@app.get("/api/v1/stores/nearby")
async def stores_nearby(
    lat: float = 30.28,
    lng: float = 120.14,
    radius: int = 5000,
    limit: int = 20,
):
    """LBS 附近商店搜索（当前返回 mock 数据）"""
    # TODO 第二阶段: 接入 MongoDB 2dsphere 地理查询
    stores = [
        StoreItem(
            storeId="store_001",
            name="喵星球宠物生活馆",
            address="杭州市西湖区文三路 100 号",
            distance=350.0,
            rating=4.8,
            tags=["猫", "狗", "医疗"],
        ),
        StoreItem(
            storeId="store_002",
            name="汪星人宠物乐园",
            address="杭州市拱墅区湖墅南路 200 号",
            distance=1200.0,
            rating=4.5,
            tags=["狗", "训练", "美容"],
        ),
        StoreItem(
            storeId="store_003",
            name="爱宠小屋",
            address="杭州市滨江区江南大道 300 号",
            distance=5200.0,
            rating=4.6,
            tags=["猫", "狗", "小宠", "寄养"],
        ),
    ]

    nearby = [s for s in stores if s.distance <= radius]

    return success(StoresNearbyResponse(
        stores=nearby[:limit],
        total=len(nearby),
    ).model_dump())


# ==================== 启动入口 ====================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=settings.PORT,
        reload=settings.DEBUG,
    )
