"""
Retriever — 知识库检索
从 MongoDB knowledge_base 集合中检索相关文档
支持：MongoDB 全文搜索 + 关键词回退检索
"""

import re
from pathlib import Path
from typing import Any
from motor.motor_asyncio import AsyncIOMotorDatabase
from pymongo.errors import PyMongoError


async def search_knowledge(
    db: AsyncIOMotorDatabase,
    query: str,
    top_k: int = 3,
) -> list[dict[str, Any]]:
    """从知识库检索与 query 最相关的文档（中文 regex，不用 $text）"""
    collection = db["knowledge_base"]
    keywords = _extract_keywords(query)
    if not keywords:
        return []

    try:
        docs: list[dict[str, Any]] = []
        seen_titles: set[str] = set()

        for kw in keywords:
            regex = {"$regex": kw, "$options": "i"}

            async for doc in collection.find({"title": regex}):
                tid = doc.get("title", "")
                if tid in seen_titles:
                    continue
                seen_titles.add(tid)
                docs.append({
                    "title": tid,
                    "content": doc.get("content", ""),
                    "category": doc.get("category", ""),
                    "source": doc.get("source", ""),
                    "_match_weight": 2,
                })

            async for doc in collection.find({"content": regex}):
                tid = doc.get("title", "")
                if tid in seen_titles:
                    continue
                seen_titles.add(tid)
                docs.append({
                    "title": tid,
                    "content": doc.get("content", ""),
                    "category": doc.get("category", ""),
                    "source": doc.get("source", ""),
                    "_match_weight": 1,
                })
        return _rank_docs(docs, keywords, top_k)
    except PyMongoError:
        return _search_local_seed(keywords, top_k)


def _rank_docs(
    docs: list[dict[str, Any]],
    keywords: list[str],
    top_k: int,
) -> list[dict[str, Any]]:
    """按关键词命中数对文档排序。"""
    scored: list[tuple[int, dict[str, Any]]] = []
    is_cat_query = any("猫" in kw for kw in keywords)
    is_dog_query = any("狗" in kw or "犬" in kw for kw in keywords)
    for doc in docs:
        title = str(doc.get("title", ""))
        content = str(doc.get("content", ""))
        category = str(doc.get("category", ""))
        score = int(doc.pop("_match_weight", 0))
        for kw in keywords:
            if kw and kw in title:
                score += 2
            if kw and kw in content:
                score += 1
        if is_cat_query:
            if "猫" in title or category.startswith("cat"):
                score += 5
            if "犬" in title or "狗" in title or category.startswith("dog"):
                score -= 3
        if is_dog_query:
            if "犬" in title or "狗" in title or category.startswith("dog"):
                score += 5
            if "猫" in title or category.startswith("cat"):
                score -= 3
        if score > 0:
            scored.append((score, doc))

    scored.sort(key=lambda x: x[0], reverse=True)
    return [
        {
            **doc,
            "score": round(s / max(len(keywords), 1), 2),
        }
        for s, doc in scored[:top_k]
    ]


def _search_local_seed(keywords: list[str], top_k: int) -> list[dict[str, Any]]:
    """MongoDB 不可用时，从种子脚本读取本地知识库文档。"""
    seed_path = Path(__file__).resolve().parents[2] / "scripts" / "seed_knowledge_v2.js"
    if not seed_path.exists():
        return []

    text = seed_path.read_text(encoding="utf-8")
    docs: list[dict[str, Any]] = []
    pattern = re.compile(
        r'title:\s*"(?P<title>.*?)".*?'
        r'category:\s*"(?P<category>.*?)".*?'
        r'source:\s*"(?P<source>.*?)".*?'
        r'content:\s*"(?P<content>.*?)"',
        re.DOTALL,
    )
    for match in pattern.finditer(text):
        docs.append({
            "title": match.group("title"),
            "content": match.group("content"),
            "category": match.group("category"),
            "source": f"{match.group('source')}（本地知识库）",
        })
    return _rank_docs(docs, keywords, top_k)


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
