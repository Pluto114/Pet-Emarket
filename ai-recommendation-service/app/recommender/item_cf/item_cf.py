"""
Item-CF 协同过滤推荐
基于用户行为共现矩阵 + 余弦相似度
"""
import math
from typing import Any
from motor.motor_asyncio import AsyncIOMotorDatabase

BW = {"VIEW": 0.3, "FAVORITE": 0.5, "CART": 0.7, "PURCHASE": 1.0}


async def recommend(
    db: AsyncIOMotorDatabase, user_id: str,
    top_k: int = 30, min_sim: float = 0.1,
) -> list[dict[str, Any]]:
    coll = db["user_behaviors"]
    docs = await coll.find({"userId": user_id}).to_list(length=200)
    if not docs:
        return []

    user_items: dict[str, float] = {}
    for d in docs:
        pid = d.get("productId", "")
        w = BW.get(d.get("behaviorType", ""), 0.2)
        user_items[pid] = max(user_items.get(pid, 0), w)

    interacted = set(user_items.keys())
    cand: dict[str, float] = {}

    for pid in list(interacted)[:10]:
        same = await coll.distinct("userId", {"productId": pid, "userId": {"$ne": user_id}})
        if not same: continue
        other = await coll.find({"userId": {"$in": same[:50]}, "productId": {"$nin": list(interacted)}}).to_list(length=500)
        for d in other:
            op = d.get("productId", "")
            w = BW.get(d.get("behaviorType", ""), 0.2)
            cand[op] = cand.get(op, 0) + w

    scored = sorted(cand.items(), key=lambda x: x[1], reverse=True)
    res = []
    for pid, score in scored[:top_k]:
        cnt = max(await coll.count_documents({"productId": pid}), 1)
        sim = min(score / math.sqrt(cnt), 1.0)
        if sim >= min_sim:
            res.append({"productId": pid, "score": round(sim, 3), "reason": "与你浏览过的商品相似"})
    return res
