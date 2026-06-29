"""
Retriever — 知识库检索
从 MongoDB knowledge_base 集合中检索相关文档
支持：MongoDB 全文搜索 + 关键词回退检索
"""

import re
from typing import Any
from motor.motor_asyncio import AsyncIOMotorDatabase


async def search_knowledge(
    db: AsyncIOMotorDatabase,
    query: str,
    top_k: int = 3,
) -> list[dict[str, Any]]:
    """从知识库检索与 query 最相关的文档（中文 regex，不用 $text）"""
    collection = db["knowledge_base"]
    results: list[dict[str, Any]] = []
    seen_titles: set[str] = set()

    keywords = _extract_keywords(query)
    if not keywords:
        return results

    # 多轮检索：title 精确匹配 > content 匹配，按匹配数计分
    scored: list[tuple[int, dict[str, Any]]] = []

    for kw in keywords:
        regex = {"$regex": kw, "$options": "i"}

        # title 匹配（权重更高）
        async for doc in collection.find({"title": regex}):
            tid = doc.get("title", "")
            if tid in seen_titles:
                continue
            seen_titles.add(tid)
            score = 2  # title match = 2 points per keyword
            # 累加已有分数
            for i, (s, d) in enumerate(scored):
                if d.get("title") == tid:
                    scored[i] = (s + score, d)
                    break
            else:
                scored.append((score, {
                    "title": tid,
                    "content": doc.get("content", ""),
                    "category": doc.get("category", ""),
                    "source": doc.get("source", ""),
                }))

        # content 匹配
        async for doc in collection.find({"content": regex}):
            tid = doc.get("title", "")
            if tid in seen_titles:
                continue
            seen_titles.add(tid)
            score = 1  # content match = 1 point per keyword
            for i, (s, d) in enumerate(scored):
                if d.get("title") == tid:
                    scored[i] = (s + score, d)
                    break
            else:
                scored.append((score, {
                    "title": tid,
                    "content": doc.get("content", ""),
                    "category": doc.get("category", ""),
                    "source": doc.get("source", ""),
                }))

    # 按分数降序取 top_k
    scored.sort(key=lambda x: x[0], reverse=True)
    for s, doc in scored[:top_k]:
        results.append({
            **doc,
            "score": round(s / max(len(keywords), 1), 2),
        })

    return results


def format_context(docs: list[dict[str, Any]]) -> str:
    """将检索结果拼接为 LLM 上下文"""
    if not docs:
        return "未找到相关知识文档。"

    parts = []
    for i, doc in enumerate(docs, 1):
        parts.append(
            f"[文档{i}] {doc['title']}\n"
            f"来源: {doc['source']}\n"
            f"内容: {doc['content']}"
        )
    return "\n\n".join(parts)


def _extract_keywords(query: str) -> list[str]:
    """从问题中提取关键词（支持中文 bigram）"""
    stopwords = {
        "的", "了", "是", "在", "我", "有", "和", "就", "不", "人",
        "都", "一", "一个", "上", "也", "很", "到", "说", "要", "去",
        "你", "会", "着", "没有", "看", "好", "自己", "这", "什么",
        "怎么", "为什么", "可以", "吗", "呢", "吧", "啊", "哦",
    }

    words = []
    # 策略 1: 按标点切词
    for chunk in re.split(r"[，。！？\s,\.!\?、；;：:（）()]+", query):
        chunk = chunk.strip()
        if len(chunk) >= 2 and chunk not in stopwords:
            words.append(chunk)

    # 策略 2: 中文 bigram/trigram 滑动窗口
    if not words or len(words) == 1:
        clean = query
        for sw in stopwords:
            clean = clean.replace(sw, "")
        for win in [2, 3]:
            for i in range(len(clean) - win + 1):
                gram = clean[i:i + win]
                if gram not in stopwords:
                    words.append(gram)

    # 去重，取前 8 个
    seen = set()
    unique = []
    for w in words:
        if w not in seen:
            seen.add(w)
            unique.append(w)
    return unique[:8]
