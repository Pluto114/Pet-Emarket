# Pet-Emarket Database Design

> **Overview**: Pet-Emarket uses a multi-database architecture — **MySQL** (relational data), **MongoDB** (geo-spatial, vector embeddings), and **Redis** (cache, rate limiting, distributed locks).

---

## 1. Database Overview

| Database | Engine | Purpose | Deployment |
|---|---|---|---|
| MySQL / H2 | InnoDB (MySQL) / H2 (dev) | User, product, order, cart, payment, loyalty, media, behavior | Docker / embedded H2 |
| MongoDB | Replica Set | Store geo-location, user embeddings, knowledge base (RAG) | Docker |
| Redis | Standalone | Cache, session, rate limiting, distributed locks | Docker |

---

## 2. MySQL Schema

### 2.1 Entity Relationship Summary

```
user_account (1) ──── (N) shipping_address
user_account (1) ──── (N) cart_item
user_account (1) ──── (N) pet_order
user_account (1) ──── (N) point_ledger
user_account (1) ──── (N) user_behavior
user_account (1) ──── (N) media_asset (as created_by)

pet_store (1) ──── (N) product (as store_id)

product (1) ──── (N) cart_item
product (1) ──── (N) order_item
product (1) ──── (N) user_behavior
product (1) ──── (N) media_asset (as product_id)

pet_order (1) ──── (N) order_item
pet_order (1) ──── (N) order_status_log
pet_order (1) ──── (N) payment_record
pet_order (1) ──── (N) point_ledger
```

### 2.2 Tables

| Table | Description | Key Columns |
|---|---|---|
| `user_account` | Users (admin, merchant, customer) | username (unique), passwordHash, role, memberLevel, pointsBalance |
| `pet_store` | Pet stores with location | longitude, latitude, rating, status |
| `product` | Products (live pets & goods) | storeId, type (PET_LIVE/GOODS), category, price, stock, auditStatus |
| `cart_item` | Shopping cart items | userId, productId, quantity |
| `pet_order` | Orders | orderNo (unique), userId, status, payAmount, rewardPoints |
| `order_item` | Order line items | orderId, productId, unitPrice, quantity, subtotal |
| `order_status_log` | Order state machine audit log | orderId, fromStatus, toStatus, operatorRole, reason |
| `payment_record` | Payment transactions | paymentNo (unique), orderId, type (PAY/REFUND), amount, channel |
| `point_ledger` | Points ledger (earn/reverse) | userId, orderId, type, points, balanceAfter |
| `user_behavior` | Behavior tracking for recommendations | userId, productId, behaviorType (VIEW/FAVORITE/CART/PURCHASE/REVIEW), weight |
| `shipping_address` | User shipping addresses | userId, receiver, phone, province, city, district, detail |
| `media_asset` | Image/video media assets | title, mediaType, url, productId, status |

Full DDL: See `database/mysql/migrations/001_init_schema.sql`

---

## 3. MongoDB Collections

| Collection | Purpose | Key Fields |
|---|---|---|
| `stores` | Geo-location based store search | location (2dsphere), name, city, status, rating |
| `knowledge_chunks` | RAG knowledge base embedding | chunkId, source, content, embedding[], metadata |
| `user_behaviors` (optional) | Behavior log for AI | Alternative to MySQL `user_behavior` table |

Indexes: See `database/mongodb/store_geo_indexes.js`  
Vector indices: See `database/vector-store/knowledge-base-design.md`

---

## 4. Redis Key Spaces

See: `database/redis/redis-key-design.md`

| Key Space | Example | TTL |
|---|---|---|
| Auth tokens | `pet:auth:token:{token}` | 8h |
| Product cache | `pet:product:info:{productId}` | 1h |
| Store cache | `pet:store:info:{storeId}` | 1h |
| Cart count | `pet:cart:count:{userId}` | 5min |
| Rate limiting | `pet:ratelimit:api:{userId}:{endpoint}` | 1min |
| Distributed locks | `pet:lock:order:create:{userId}` | 10s |
| Recommendation cache | `pet:recommend:user:{userId}` | 30min |

---

## 5. Order State Machine

```
WAIT_PAY (0) ──(pay)──> WAIT_SHIP (1) ──(ship)──> WAIT_RECEIVE (2)
                                                          │
                                              (receive)  │
                                                          ▼
WAIT_REVIEW (3) ──(review)──> FINISHED (4)

Cancel / Refund paths:
WAIT_PAY ──────────> CANCELED (-1)
WAIT_SHIP ─────────> REFUND_APPLIED (-2) ──> REFUND_SUCCESS (-3)
ADMIN forced refund ──────────────────────> ADMIN_REFUND (-4)
```

Status logged in `order_status_log` for audit trail.

---

## 6. Seed Data

Pre-loaded demo data includes:

- **2 users**: admin + demo customer
- **3 stores**: PetJoy, PawCare, MeowLife (Hangzhou locations)
- **6 products**: 3 live pets + 3 pet supplies
- **2 media assets**: demo video + banner image
- **2 shipping addresses**: for demo user
- **12 behavior records**: for recommendation algorithm training
- **3 orders**: finished / wait-ship / wait-pay (full lifecycle)

See: `database/mysql/seeds/seed_demo_data.sql`
