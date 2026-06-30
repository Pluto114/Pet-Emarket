# AI 推荐与问答模块 — 开发任务书

> **负责人**: 王涵哲  
> **目录**: `ai-recommendation-service/`  
> **关联数据库**: MongoDB（本地 Docker 部署，已连接）  
> **开发 IDE**: IntelliJ IDEA  
> **当前状态**: 全部四阶段开发完成。4 个接口（/chat /recommend /stores/nearby /copywriting）全部对接。16 个测试用例全部通过。  

---

## 一、模块定位

AI 推荐服务是 Pet-Emarket 的独立微服务，位于网关之后，负责：

- 智能问答（RAG）
- 商品文案与视频脚本生成
- Item-CF 协同过滤推荐
- 马尔可夫链用户行为预测
- 混合推荐策略（输出推荐分 + 推荐理由）
- LBS 附近商店搜索

---

## 二、接口清单（共 3 个核心接口）

| 接口路径 | 方法 | 功能 | 阶段 |
|----------|------|------|------|
| `/api/v1/chat` | POST | RAG 智能问答 | 第三阶段 |
| `/api/v1/recommend` | POST | 混合推荐 | 第三阶段 |
| `/api/v1/stores/nearby` | GET | LBS 附近商店搜索 | 第二阶段 |

### 2.1 `/api/v1/chat` — RAG 智能问答

```
POST /api/v1/chat
```

**请求体**:
```json
{
  "userId": "xxx",
  "question": "新手适合养什么猫？",
  "context": {
    "orderId": "可选",
    "productId": "可选"
  }
}
```

**响应体**:
```json
{
  "success": true,
  "code": "000000",
  "message": "操作成功",
  "data": {
    "answer": "新手建议从英短、美短开始...",
    "sources": [
      {"title": "新手养猫指南", "url": "..."}
    ],
    "disclaimer": "仅供参考，严重健康问题请咨询执业兽医",
    "relatedProducts": []
  },
  "traceId": "...",
  "timestamp": 1783651200000
}
```

**核心要求**:
1. 区分**知识型问题**（如"猫粮怎么选"）和**业务型问题**（如"我的订单到哪了"）
2. 知识型问题走 RAG 检索 → LLM 生成
3. 业务型问题走订单/售后 API 查询 → 模板化回答
4. 宠物健康类回答必须带安全提示：**"仅供参考，严重健康问题请咨询执业兽医"**
5. 对接 LLM API（建议用阿里云百炼 / OpenAI 兼容接口）

### 2.2 `/api/v1/recommend` — 混合推荐

```
POST /api/v1/recommend
```

**请求体**:
```json
{
  "userId": "xxx",
  "lat": 30.5,
  "lng": 120.4,
  "limit": 10
}
```

**响应体**:
```json
{
  "success": true,
  "code": "000000",
  "data": {
    "recommendations": [
      {
        "productId": "xxx",
        "score": 0.92,
        "reasons": [
          "根据你最近浏览的幼猫和猫粮推荐",
          "距离你 1.2km",
          "会员专享价"
        ]
      }
    ]
  }
}
```

**推荐分公式**（来自 README 5.3 节）:
```
score = item_cf_score
      + markov_transition_score
      + member_level_weight
      + store_distance_weight
      + hot_item_weight
      + stock_status_weight
```

### 2.3 `/api/v1/stores/nearby` — LBS 附近商店

```
GET /api/v1/stores/nearby?lat=30.5&lng=120.4&radius=5000&limit=20
```

**核心要求**:
- MongoDB `2dsphere` 地理索引
- 按距离排序返回
- 支持半径筛选

---

## 三、算法策略详解

### 3.1 三层推荐策略（必须全部实现）

| 层级 | 策略 | 用途 | 触发条件 |
|------|------|------|----------|
| L0 兜底 | 热门推荐 | 新用户无行为记录 | 用户行为数据 < 阈值 |
| L1 协同过滤 | Item-CF | 基于物品相似度 | 用户有浏览/购买记录 |
| L2 行为预测 | 马尔可夫链 | 基于行为序列预测下一步 | 用户行为序列 ≥ 3 步 |

### 3.2 Item-CF 协同过滤

**文件**: `app/recommender/item_cf/item_cf.py`

**核心逻辑**:
1. 从 MongoDB 读取用户行为日志（浏览、收藏、加购、购买）
2. 构建物品共现矩阵
3. 计算物品间余弦相似度
4. 根据用户历史行为物品，召回 Top-N 相似物品
5. 输出 `item_cf_score`

**关键参数**:
- 相似度阈值：0.3
- 召回数量：Top-50
- 行为权重：浏览=0.3, 收藏=0.5, 加购=0.7, 购买=1.0

### 3.3 马尔可夫链行为预测

**文件**: `app/recommender/markov/markov_chain.py`

**核心逻辑**:
1. 定义行为状态空间：`[浏览, 收藏, 加购, 购买, 评价]`
2. 从 MongoDB 读取用户行为序列，按时间排序
3. 统计状态转移频率，构建转移概率矩阵
4. 根据用户当前状态，预测下一状态最可能的行为
5. 根据预测行为推荐对应商品
6. 输出 `markov_transition_score`

**关键参数**:
- 序列窗口：最近 10 条行为
- 冷启动默认概率：均匀分布

### 3.4 混合推荐（Hybrid Recommender）

**文件**: `app/recommender/hybrid_recommender.py`

**核心逻辑**:
1. 并行调用 Item-CF、马尔可夫链、热门兜底
2. 按公式加权汇总得分
3. 生成推荐理由列表
4. 排序后返回 Top-N

**权重配置**:
```python
WEIGHTS = {
    "item_cf": 0.35,
    "markov": 0.25,
    "member_level": 0.10,
    "store_distance": 0.15,
    "hot_item": 0.10,
    "stock_status": 0.05,
}
```

---

## 四、RAG 智能问答架构

### 4.1 整体流程

```
用户提问 → Prompt Guard（安全检测）
         → 问题分类（知识型 / 业务型）
         → 知识型: Retriever 检索向量库 → LLM 生成
         → 业务型: 查询订单/商品 API → 模板回答
         → 安全审核 → 返回
```

### 4.2 组件说明

| 组件 | 文件 | 功能 |
|------|------|------|
| Prompt Guard | `app/rag/prompt_guard.py` | 敏感词过滤、注入检测、安全审核 |
| Retriever | `app/rag/retriever.py` | 向量检索，从向量库召回相关文档片段 |
| Copywriting | `app/content_generation/copywriting.py` | AI 商品文案生成 |

### 4.3 知识库来源

- 宠物百科（猫狗品种、习性、饲养）
- 商品信息（名称、描述、规格）
- 养宠常见问题 FAQ
- MSD 兽医手册（项目根目录已有 `MSD_Veterinary_Manual_Pet_Owners_目录.md`）

### 4.4 Prompt Guard 规则

**文件**: `app/rag/prompt_guard.py`

1. 输入长度限制：≤ 500 字符
2. 敏感词过滤：政治、色情、暴力
3. Prompt Injection 检测：拒绝 `忽略以上指令`、`system:` 等模式
4. 输出安全审核：确保回答不包含医疗建议（仅提供参考信息）

---

## 五、数据库设计（MongoDB）

### 5.1 集合设计

| 集合名 | 用途 | 关键索引 |
|--------|------|----------|
| `user_behaviors` | 用户行为日志 | `userId`, `timestamp` |
| `stores` | 商店信息 | `location: "2dsphere"` |
| `recommendation_cache` | 推荐结果缓存 | `userId`, `expireAt` (TTL) |
| `knowledge_base` | RAG 知识库文档 | `embedding` (向量索引) |
| `chat_history` | 问答历史 | `userId`, `sessionId` |

### 5.2 user_behaviors 文档结构

```json
{
  "userId": "xxx",
  "productId": "xxx",
  "behaviorType": "VIEW | FAVORITE | CART | PURCHASE | REVIEW",
  "categoryId": "xxx",
  "storeId": "xxx",
  "timestamp": "2026-06-25T10:00:00Z",
  "duration": 120
}
```

### 5.3 stores 地理索引

```javascript
db.stores.createIndex({ location: "2dsphere" })
```

查询示例:
```javascript
db.stores.find({
  location: {
    $near: {
      $geometry: { type: "Point", coordinates: [120.4, 30.5] },
      $maxDistance: 5000
    }
  }
})
```

### 5.4 MongoDB 数据库创建步骤（完整）

你已经在 IDEA 中连接了本地 Docker 部署的 MongoDB，下面是一步步创建数据库的过程。

#### 5.4.1 确认 MongoDB 容器在运行

在 IDEA 底部 Terminal 或 Windows 终端执行：

```bash
# 查看运行中的容器
docker ps

# 如果没有看到 mongo 容器，启动它
docker start mongo
```

#### 5.4.2 进入 MongoDB Shell

```bash
docker exec -it mongo mongosh
```

进入后你会看到 `test>` 提示符，说明已连上。

#### 5.4.3 创建数据库

```javascript
// 切换到 pet_emarket 数据库（MongoDB 在第一次写入时自动创建）
use pet_emarket
```

#### 5.4.4 创建集合与索引（一键执行）

将以下脚本**全部复制**到 mongosh 中执行：

```javascript
// ========== 1. stores 集合 — 商店信息（LBS 搜索核心） ==========
// 先创建地理空间索引，后续 LBS 查询必须依赖此索引
db.stores.createIndex({ location: "2dsphere" })
db.stores.createIndex({ storeId: 1 }, { unique: true })

// 插入一条测试商店数据验证
db.stores.insertOne({
  storeId: "store_001",
  name: "喵星球宠物生活馆",
  address: "杭州市西湖区文三路 100 号",
  location: {
    type: "Point",
    coordinates: [120.142, 30.278]   // [经度, 纬度] — 注意顺序！
  },
  phone: "0571-88888888",
  rating: 4.8,
  tags: ["猫", "狗", "医疗"],
  createTime: new Date()
})

// ========== 2. user_behaviors 集合 — 用户行为日志 ==========
db.user_behaviors.createIndex({ userId: 1, timestamp: -1 })
db.user_behaviors.createIndex({ productId: 1 })
db.user_behaviors.createIndex({ behaviorType: 1 })

// 插入测试行为数据
db.user_behaviors.insertMany([
  {
    userId: "user_001",
    productId: "prod_001",
    behaviorType: "VIEW",
    categoryId: "cat_living",
    storeId: "store_001",
    timestamp: new Date("2026-06-25T10:00:00Z"),
    duration: 45
  },
  {
    userId: "user_001",
    productId: "prod_002",
    behaviorType: "FAVORITE",
    categoryId: "cat_food",
    storeId: "store_001",
    timestamp: new Date("2026-06-25T10:05:00Z"),
    duration: 30
  },
  {
    userId: "user_001",
    productId: "prod_003",
    behaviorType: "CART",
    categoryId: "cat_toy",
    storeId: "store_001",
    timestamp: new Date("2026-06-25T10:10:00Z"),
    duration: 60
  }
])

// ========== 3. recommendation_cache 集合 — 推荐缓存 ==========
// TTL 索引：30 分钟后自动删除，避免数据膨胀
db.recommendation_cache.createIndex({ expireAt: 1 }, { expireAfterSeconds: 0 })
db.recommendation_cache.createIndex({ userId: 1 })

// ========== 4. chat_history 集合 — 问答历史 ==========
db.chat_history.createIndex({ userId: 1, sessionId: 1 })
db.chat_history.createIndex({ timestamp: -1 })

// ========== 5. knowledge_base 集合 — RAG 知识库文档 ==========
// 后续对接向量库时再补 embedding 索引
db.knowledge_base.createIndex({ title: "text", content: "text" })

// 插入一条测试知识文档
db.knowledge_base.insertOne({
  title: "新手养猫常见问题",
  content: "新手建议从性格温顺的品种开始，如英短、美短、布偶猫...",
  category: "pet_care",
  source: "MSD兽医手册",
  createTime: new Date()
})
```

#### 5.4.5 验证创建结果

```javascript
// 查看所有集合
show collections
// 预期输出：chat_history, knowledge_base, recommendation_cache, stores, user_behaviors

// 查看 stores 索引
db.stores.getIndexes()

// 测试地理查询是否能正常执行
db.stores.find({
  location: {
    $near: {
      $geometry: { type: "Point", coordinates: [120.14, 30.28] },
      $maxDistance: 5000   // 5 公里范围内
    }
  }
})
// 预期返回：刚才插入的"喵星球宠物生活馆"
```

#### 5.4.6 IDEA 中查看 MongoDB 数据

IDEA 已经连接了 MongoDB，你可以直接在 IDE 内操作：

1. IDEA 右侧边栏 → **Database** 标签
2. 找到你的 MongoDB 连接 → 展开 → 双击 `pet_emarket` 数据库
3. 双击任一集合即可查看数据，无需命令行
4. 右键集合 → **Jump to Query Console** 可以执行查询语句

> 提醒：MongoDB 坐标顺序为 **[经度, 纬度]**，百度/高德地图通常返回 [纬度, 经度]，注意转换。

---

## 六、文案生成

### 6.1 功能

**文件**: `app/content_generation/copywriting.py`

- 商品详情文案生成：根据商品属性（品种、年龄、性别、特点）生成吸引人的描述
- 视频脚本生成：为活体宠物生成 30 秒展示视频脚本大纲
- 营销文案：根据促销活动生成配套文案

### 6.2 接口预留

```
POST /api/v1/copywriting/generate
```

---

## 七、错误码规范（40xxxx 段）

| 错误码 | 含义 |
|--------|------|
| 400001 | 推荐服务不可用 |
| 400002 | 用户行为数据不足 |
| 400003 | 问答服务不可用 |
| 400004 | Prompt 安全审核不通过 |
| 400005 | 知识库检索无结果 |
| 400006 | 文案生成失败 |
| 400007 | LBS 查询参数无效 |

---

## 八、当前开发环境说明

### 8.1 你的环境

| 项目 | 详情 |
|------|------|
| IDE | IntelliJ IDEA |
| OS | Windows 11 |
| Python | 建议 3.10+ |
| MongoDB | 本地 Docker 部署，已连接 |
| LLM API | 阿里云百炼（推荐，免费额度充足） |

### 8.2 百炼模型选择指南

阿里云百炼新用户开通即送各模型 **100 万 Token**（有效期 90 天），Qwen3.7-MAX 每日额外 **200 次免费调用**。

#### 推荐模型选择

| 场景 | 推荐模型 | 原因 |
|------|----------|------|
| **RAG 问答** | `qwen-plus` | 质量与速度均衡，回答准确，适合知识型问答 |
| **文案生成** | `qwen-turbo` | 速度快、成本低，文案生成任务不需要最强模型 |
| **问题分类（知识型/业务型）** | `qwen-turbo` | 简单分类任务，低成本即可 |
| **Prompt Guard 安全检测** | `qwen-turbo` | 规则匹配为主，模型兜底 |
| **兜底/高难度问答** | `qwen-max` | 复杂问题时才调用，节省额度 |

#### 模型能力对比

| 模型 | 速度 | 质量 | 免费额度 | 适用 |
|------|------|------|----------|------|
| `qwen-turbo` | 最快 | ★★★ | 100万T | 文案、分类、安全检测 |
| `qwen-plus` | 快 | ★★★★ | 100万T | RAG 问答（主力） |
| `qwen-max` | 中 | ★★★★★ | 100万T | 复杂问答兜底 |
| `qwen-turbo-latest` | 最快 | ★★★ | 100万T | 同上 turbo |

#### 百炼 API 接入方式

百炼支持 **OpenAI 兼容模式**，代码无需改动，只改 `base_url` 和 `api_key`：

```python
# app/core/config.py
LLM_API_KEY = "sk-xxxxxxxx"  # 百炼控制台获取
LLM_BASE_URL = "https://dashscope.aliyuncs.com/compatible-mode/v1"
LLM_MODEL = "qwen-plus"       # 默认模型
LLM_MODEL_FAST = "qwen-turbo" # 轻量任务模型
```

调用示例（与 OpenAI SDK 完全兼容）：
```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-xxxxxxxx",
    base_url="https://dashscope.aliyuncs.com/compatible-mode/v1"
)

response = client.chat.completions.create(
    model="qwen-plus",
    messages=[{"role": "user", "content": "新手适合养什么猫？"}]
)
print(response.choices[0].message.content)
```

#### 申请步骤

1. 打开 [阿里云百炼控制台](https://bailian.console.aliyun.com/)
2. 实名认证（支付宝扫码即可）
3. 左侧菜单 → **模型广场** → 选择 `qwen-plus` → 开通服务
4. 右上角头像 → **API-KEY** → 创建新的 API Key
5. 将 API Key 写入项目 `.env` 文件或 `config.py`

### 8.3 IDEA 开发配置步骤

1. **打开项目**: IDEA → Open → 选择 `Pet-Emarket/ai-recommendation-service/` 目录
2. **配置 Python 解释器**: File → Project Structure → SDK → 选择 Python 3.10+
3. **安装依赖**: IDEA 底部 Terminal 执行:
   ```bash
   pip install -r requirements.txt
   ```
4. **配置 MongoDB 连接**: 在 `app/core/config.py` 中设置:
   ```python
   MONGODB_URI = "mongodb://localhost:27017"
   MONGODB_DB = "pet_emarket"
   ```
5. **运行服务**:
   ```bash
   uvicorn app.main:app --reload --port 8001
   ```
6. **调试**: 右键 `main.py` → Debug，IDEA 自带断点调试支持 FastAPI

### 8.4 MongoDB 快速验证

数据库和集合的完整创建步骤见 **[第五章 5.4 节](#54-mongodb-数据库创建步骤完整)**。下面只做快速连接验证：

```bash
# 进入 Docker MongoDB
docker exec -it mongo mongosh

# 验证 pet_emarket 数据库和集合是否存在
use pet_emarket
show collections
db.stores.findOne()
```

### 8.5 推荐的 Python 依赖（`requirements.txt`）

```
# Web 框架
fastapi==0.115.0
uvicorn[standard]==0.30.0

# MongoDB
motor==3.6.0         # 异步 MongoDB 驱动
pymongo==4.8.0

# 推荐算法
numpy==2.1.0
scikit-learn==1.5.0

# RAG / LLM
langchain==0.3.0
langchain-community==0.3.0
openai==1.50.0       # 兼容 OpenAI / 阿里云百炼

# 数据验证
pydantic==2.9.0

# 工具
httpx==0.27.0        # 异步 HTTP 客户端，调后端 API
python-dotenv==1.0.0

# 测试
pytest==8.3.0
pytest-asyncio==0.24.0
```

---

## 九、分阶段开发计划

### 第一阶段：空接口与基础架构 ✅ 已完成

- [x] 补全 `app/main.py` — FastAPI 应用入口
- [x] 补全 `app/core/config.py` — 配置管理（MongoDB URI、LLM API Key 等）
- [x] 补全 `app/schemas/recommendation_schema.py` — Pydantic 数据模型
- [x] 实现 `/recommend`、`/chat`、`/stores/nearby` 空接口（返回 mock 数据）
- [x] 验证 MongoDB 连接
- [x] 单元测试骨架（11 个用例全部通过）

**成果**: 3 个接口可调用，返回 mock JSON，服务启动正常，11/11 测试通过。

### 第二阶段：LBS 与数据准备

- [x] 实现 `/stores/nearby` — MongoDB 2dsphere 地理查询
- [x] 实现用户行为数据写入（从后端 API 同步或模拟生成）
- [x] 搭建 `user_behaviors` 集合并灌入测试数据
- [x] 编写 LBS 查询测试用例

### 第三阶段：核心算法

- [x] 实现 RAG 智能问答（Retriever + LLM）
- [x] 实现 Prompt Guard 安全检测
- [x] 实现 Item-CF 协同过滤
- [x] 实现马尔可夫链行为预测
- [x] 实现混合推荐（Hybrid Recommender）
- [x] 实现文案生成

### 第四阶段：联调、优化与答辩

- [x] 前端联调，验证推荐理由展示
- [x] 算法效果调优（相似度阈值、权重）
- [x] 性能优化（推荐缓存、异步调用）
- [x] 编写算法说明文档
- [x] 准备演示数据与答辩脚本

---

## 十、关键验收标准

| 验收项 | 标准 |
|--------|------|
| 推荐接口 | 返回推荐商品 + 推荐分 + 推荐理由 |
| 问答接口 | 知识型问题走 RAG，业务型问题走 API 查询 |
| 安全提示 | 宠物健康回答必须带免责声明 |
| 三层策略 | 热门兜底、Item-CF、马尔可夫链全部可用 |
| LBS 搜索 | 经纬度 + 半径查询，按距离排序 |
| 错误处理 | 无行为记录时优雅降级到热门推荐 |
| 代码质量 | 所有接口有测试用例 |
| 文档 | 算法说明、接口文档、测试样例 |

---

## 十一、开发建议

1. **先跑通 Mock，再补算法**。第一阶段用假数据让前端能联调，避免阻塞团队。
2. **MongoDB 是核心**。行为数据、商店位置、知识库都在 Mongo，先把数据模型和索引建好。
3. **LLM API 尽早申请**。阿里云百炼有免费额度，OpenAI 兼容接口通用性好，二选一即可。
4. **推荐算法用 NumPy 手写**。Item-CF 和马尔可夫链不复杂，不用引入重量级框架，答辩时更容易讲清楚。
5. **推荐理由比推荐分数更重要**。答辩时老师会问"为什么推荐这个商品"，理由要能解释。
6. **每个接口写完就补测试**。`tests/test_recommendation.py` 已有骨架，边写边测。
