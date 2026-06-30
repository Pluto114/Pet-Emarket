"""
马尔可夫链行为预测
基于用户行为序列构建转移概率，预测下一步行为并推荐商品
"""
from typing import Any
from collections import defaultdict
from motor.motor_asyncio import AsyncIOMotorDatabase

STATES = ["VIEW", "FAVORITE", "CART", "PURCHASE", "REVIEW"]


async def predict(
    db: AsyncIOMotorDatabase, user_id: str, window: int = 10,
) -> list[dict[str, Any]]:
    coll = db["user_behaviors"]
    docs = await coll.find({"userId": user_id}).sort("timestamp", -1).limit(window).to_list(length=window)
    if len(docs) < 3:
        return []

    # 转移矩阵
    tr: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    sc: dict[str, int] = defaultdict(int)
    for i in range(len(docs) - 1):
        prev = docs[i + 1].get("behaviorType", "")
        curr = docs[i].get("behaviorType", "")
        if prev in STATES and curr in STATES:
            tr[prev][curr] += 1
            sc[prev] += 1

    curr = docs[0].get("behaviorType", "")
    if curr not in sc:
        return []

    probs = {nxt: cnt / sc[curr] for nxt, cnt in tr[curr].items()}
    if not probs:
        return []
    predicted = max(probs, key=probs.get)

    similar = await coll.distinct("userId", {"userId": {"$ne": user_id}, "behaviorType": predicted})
    if not similar:
        return []

    results = []
    pipeline = [
        {"$match": {"userId": {"$in": similar[:50]}, "behaviorType": predicted}},
        {"$group": {"_id": "$productId", "count": {"$sum": 1}}},
        {"$sort": {"count": -1}}, {"$limit": 10},
    ]
    async for doc in coll.aggregate(pipeline):
        results.append({
            "productId": doc["_id"],
            "score": round(min(doc["count"] / 20, 1.0), 3),
            "reason": f"预测你可能想{_name(predicted)}",
        })
    return results


def _name(b: str) -> str:
    return {"VIEW":"浏览","FAVORITE":"收藏","CART":"加入购物车","PURCHASE":"购买","REVIEW":"评价"}.get(b, "浏览")
