"""
AI 文案生成 — qwen-turbo
支持：商品详情 / 视频脚本 / 营销文案
"""
from openai import AsyncOpenAI
from app.core.config import settings

PROMPTS = {
    "detail": (
        "你是宠物商城文案专家。根据以下商品信息，写一段80-120字的商品详情文案，"
        "突出特点卖点，语言温暖治愈，适合养宠人群。\n商品信息：{info}"
    ),
    "video_script": (
        "你是宠物短视频策划。为以下活体宠物写一个30秒展示视频脚本大纲（5-7个镜头），"
        "每个镜头一行描述画面和配乐。\n宠物信息：{info}"
    ),
    "marketing": (
        "你是宠物商城营销编辑。根据活动信息写一段50字以内的促销文案，"
        "朗朗上口有记忆点，可用Emoji。\n活动信息：{info}"
    ),
}


async def generate(client: AsyncOpenAI, copy_type: str, info: str) -> str:
    prompt = PROMPTS.get(copy_type, PROMPTS["detail"]).format(info=info)
    try:
        resp = await client.chat.completions.create(
            model=settings.LLM_MODEL_FAST,
            messages=[{"role": "user", "content": prompt}],
            temperature=0.8, max_tokens=300,
        )
        return resp.choices[0].message.content.strip()
    except Exception as e:
        return f"文案生成失败：{e}"
