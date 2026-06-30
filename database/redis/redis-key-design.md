# Pet-Emarket Redis Key Design

> **Role**: Caching layer for hot data, session tokens, and rate limiting.

---

## Key Naming Convention

```
pet:{module}:{entity}:{id}[:{sub}]
```

- `pet` — project prefix (namespace)
- `module` — business module name (auth, product, store, order, etc.)
- `entity` — resource type (token, info, stock, geo, etc.)
- `id` — unique identifier (userId, productId, storeId)
- `sub` — optional sub-resource qualifier

All keys use **colon (`:`)** as delimiter.  
**TTL** is mandatory for all cache entries — no permanent keys.

---

## 1. Auth / Session

| Key Pattern | Type | TTL | Description |
|---|---|---|---|
| `pet:auth:token:{token}` | String (JSON) | 28800s (8h) | JWT token → `{userId, role, username}` mapping for server-side validation |
| `pet:auth:refresh:{userId}` | String | 604800s (7d) | Refresh token, allows token renewal without re-login |

---

## 2. Product Cache

| Key Pattern | Type | TTL | Description |
|---|---|---|---|
| `pet:product:info:{productId}` | Hash | 3600s (1h) | Product detail cache: `{name, price, stock, coverUrl, category, type}` |
| `pet:product:hot:{category}` | Sorted Set | 600s (10min) | Hot products by category, score = view_count + purchase_weight |
| `pet:product:stock:{productId}` | String (Int) | 300s (5min) | Real-time stock for flash checkout validation |
| `pet:product:list:{category}:page:{page}` | String (JSON) | 600s (10min) | Paginated product list cache |

---

## 3. Store Cache

| Key Pattern | Type | TTL | Description |
|---|---|---|---|
| `pet:store:info:{storeId}` | Hash | 3600s (1h) | Store detail: `{name, rating, phone, businessHours}` |
| `pet:store:geo:{city}:{status}` | Sorted Set | 1800s (30min) | Store IDs by city, score = rating; used for LBS fallback |

---

## 4. Recommendation Cache

| Key Pattern | Type | TTL | Description |
|---|---|---|---|
| `pet:recommend:user:{userId}` | String (JSON) | 1800s (30min) | Hybrid recommendation result for user (top-N products with reason) |
| `pet:recommend:hot` | String (JSON) | 600s (10min) | Global hot products as fallback when user has no behavior data |

---

## 5. Rate Limiting

| Key Pattern | Type | TTL | Description |
|---|---|---|---|
| `pet:ratelimit:api:{userId}:{endpoint}` | String (Counter) | 60s (1min sliding) | Rate counter for API throttling (max 30 req/min per endpoint) |
| `pet:ratelimit:ai:{userId}` | String (Counter) | 3600s (1h) | AI service rate limit (max 10 requests/hour per user) |
| `pet:ratelimit:login:{ip}` | String (Counter) | 300s (5min) | Login attempt throttle (max 5 attempts/5min per IP) |

---

## 6. Session / Distributed Lock

| Key Pattern | Type | TTL | Description |
|---|---|---|---|
| `pet:lock:order:create:{userId}` | String | 10s | Distributed lock for preventing duplicate order submission |
| `pet:lock:payment:{orderNo}` | String | 30s | Payment processing lock, prevents double-payment |
| `pet:session:user:{userId}` | Hash | 1800s (30min) | Active user session: `{lastActiveAt, currentCartId}` |

---

## 7. Cart (Read optimization)

| Key Pattern | Type | TTL | Description |
|---|---|---|---|
| `pet:cart:count:{userId}` | String (Int) | 300s (5min) | Cart item count badge for UI; invalidated on add/remove |
| `pet:cart:checked:{userId}` | Sorted Set | 600s (10min) | Checked product IDs for order summary, score = addedAt timestamp |

---

## Deletion / Invalidation Strategy

- **Cache-aside (lazy loading)**: Data is loaded into cache on read miss; invalidated on write.
- **Write-through for critical paths**: Stock and order locks invalidate immediately on update.
- **Eventual consistency** for recommendation cache: recomputed every 30 min.
- **Bulk invalidation pattern**:
  - Product updated: `DEL pet:product:info:{id}`, touch `pet:product:list:*`
  - Order placed: `DEL pet:cart:count:{userId}`
  - Recommendation refreshed: `DEL pet:recommend:user:{userId}`
