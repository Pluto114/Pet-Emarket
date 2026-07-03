# Pet-Emarket

Pet-Emarket 是软件工程实训课程的宠物商店电商系统。系统目标不是做一个简单商品展示页，而是完成“用户端体验、后台管理、订单交易闭环、AI 推荐问答、工程化交付”五条主线，最终能支撑课程设计文档、代码演示、团队协作展示和答辩。

## 0. 当前可运行骨架

当前已经落地 Java 正式后端骨架、交易闭环，并进入智能模块阶段：

- 正式后端：`backend/pet-emarket-server`，Spring Boot Java API，支持登录、注册、JWT 鉴权、用户 CRUD、商品 CRUD。
- 正式后端交易：支持购物车、收货地址、创建订单、支付模拟、支付/退款流水、会员积分账本、管理员发货、用户收货、评价、取消、申请退单、审核退单。
- 正式后端智能模块：支持附近门店查询、RAG-lite 智能问答、用户行为日志、Item-CF + 马尔可夫链 + 热度 + LBS 的混合推荐。
- AI 联调：Java 后端 `/api/v1/ai/chat` 只作为网关转发到独立 FastAPI AI 服务；外部模型或 AI 服务不可达时直接返回错误，禁止本地假回答。
- 媒体上传：商家/管理员通过 Java 后端 `/api/v1/media/upload` 上传图片和视频，由后端读取环境变量并转存阿里云 OSS，前端不保存 OSS 密钥。
- 正式后端管理模块：支持门店管理、媒体管理、后台数据看板、活体宠物审核状态流转。
- 临时 mock：`backend/api-server` 是早期 Node.js mock，不再作为正式后端继续开发。
- 用户端：`frontend/pet-emarket-app`，Flutter 单项目（PawMart 橄榄绿主题），支持 Web/Android。
- 默认管理员账号：`admin / Admin@123456`。
- 默认用户账号：`demo / Demo@123456`。
- Web 默认 API：`http://localhost:8080`。
- AI 服务：`http://localhost:8001`。

---

## 数据库搭建（MySQL + Flyway）

Java 后端默认直接连接 MySQL，并使用 Flyway 自动执行 `backend/pet-emarket-server/src/main/resources/db/migration` 下的迁移脚本。商品、购物车、订单、地址、支付流水、积分和行为日志都必须落 MySQL。

默认连接配置在 `backend/pet-emarket-server/src/main/resources/application.yml`：

```text
DB_HOST=localhost
DB_PORT=3306
DB_NAME=pet_emarket
DB_USERNAME=root
DB_PASSWORD=Zhaojerry331!
```

不要再使用 H2 或旧 Node mock 作为正式联调路径，也不要手动导入旧 SQL 文件作为主流程。

### 1. 创建数据库和账号

如果使用默认 root 账号，请至少确保数据库存在：

```bash
CREATE DATABASE IF NOT EXISTS pet_emarket
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;
```

如需单独账号，也可以执行：

```bash
CREATE USER IF NOT EXISTS 'pet_emarket'@'localhost' IDENTIFIED BY 'change-me';
GRANT ALL PRIVILEGES ON pet_emarket.* TO 'pet_emarket'@'localhost';
FLUSH PRIVILEGES;
```

### 2. 启动后端

```bash
cd backend/pet-emarket-server
mvn spring-boot:run
```

启动 Java 后端后，Flyway 会自动建表；`DataInitializer` 只负责创建必要演示账号、门店和商品，不再写入假媒体 URL。

### 3. Docker MySQL 可选方案

```bash
docker run -d --name mysql-local -p 3307:3306 \
  -e MYSQL_ROOT_PASSWORD=123456 \
  -e MYSQL_DATABASE=pet_emarket \
  mysql:8.0 \
  --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
```

---

## OSS 上传配置

商家/管理员上传图片、视频时，前端调用 Java 后端 multipart API，后端再写入 OSS。部署时只在环境变量中配置 OSS，禁止写入代码：

```bash
OSS_ENABLED=true
ALIYUN_OSS_ENDPOINT=oss-cn-hangzhou.aliyuncs.com
ALIYUN_OSS_BUCKET=your-bucket
ALIYUN_OSS_ACCESS_KEY_ID=your-access-key-id
ALIYUN_OSS_ACCESS_KEY_SECRET=your-access-key-secret
ALIYUN_OSS_PUBLIC_BASE_URL=https://your-domain-or-bucket-url
ALIYUN_OSS_OBJECT_PREFIX=pet-emarket
```

支持格式：图片 `jpg/jpeg/png/gif/webp`，视频 `mp4/mov/avi/m4v/webm`。

---

## RAG 向量知识库搭建（Docker + MongoDB）

AI 智能问答依赖 MongoDB 存储知识库文档（46 篇宠物百科）。

### 1. 创建 MongoDB 容器

```bash
docker run -d --name mongodb-local -p 27017:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=123456 \
  mongo:8
```

### 2. 导入知识库 + 商店数据

```bash
cd Pet-Emarket/ai-recommendation-service

# 一键创建数据库、集合、索引 + 导入 46 篇知识库 + 3 家测试商店
docker exec -i mongodb-local mongosh -u admin -p 123456 --authenticationDatabase admin < scripts/seed_knowledge_v2.js
```

### 3. 验证

```bash
docker exec -it mongodb-local mongosh -u admin -p 123456 --authenticationDatabase admin
> use pet_emarket
> show collections
# 预期: chat_history, knowledge_base, recommendation_cache, stores, user_behaviors
> db.knowledge_base.countDocuments()
# 预期: 46
```

### 集合说明

| 集合 | 用途 |
|------|------|
| `knowledge_base` | RAG 知识库（46 篇宠物百科） |
| `stores` | 商店信息（含 2dsphere 地理索引） |
| `user_behaviors` | 用户行为日志 |
| `chat_history` | 问答历史 |
| `recommendation_cache` | 推荐缓存（TTL 30 分钟） |

### 连接信息

```
mongodb://admin:123456@localhost:27017/pet_emarket?authSource=admin
```

---

## 完整启动流程

### 1. AI 推荐服务 (端口 8001)

```bash
cd ai-recommendation-service
pip install -r requirements.txt
cp .env.example .env          # 编辑 .env 填入百炼 API Key
python -m uvicorn app.main:app --port 8001
```

验证：`http://localhost:8001/health` → `{"mongodb":"ok"}`

### 2. Java 后端 (端口 8080)

```bash
cd backend/pet-emarket-server
mvn spring-boot:run
```

AI 网关配置 (`application.yml`)：`enabled: true, base-url: localhost:8001, timeout: 10s`

### 3. Flutter 前端

```bash
cd frontend/pet-emarket-app
flutter pub get && flutter run -d chrome
```

### AI 调用链路

```
前端/Postman → Java /api/v1/ai/chat → Python /api/v1/chat
                                          ├─ Prompt Guard
                                          ├─ 知识库检索 (46篇)
                                          └─ 百炼 qwen-plus
```

AI 模块必须调用外部模型 API；如果 Python AI 服务或百炼不可达，接口返回 `AI_GATEWAY_UNAVAILABLE` / `LLM_UNAVAILABLE`，不生成本地模板答案。

### 直接测 AI

```
POST http://localhost:8001/api/v1/chat
{"userId":"test","question":"狗狗打什么疫苗？"}
```

### 运行测试

```bash
cd ai-recommendation-service && python -m pytest tests/ -v   # 16 tests
cd backend/pet-emarket-server && mvn test                    # Java
```

---

## 1. 项目目标

本项目按高分课程设计标准搭建，核心验收目标如下：

- 完成游客、普通用户、会员、商家管理员、平台管理员的完整业务链路。
- 支持附近宠物商店搜索、宠物/周边商品浏览、行为埋点、购物车、收货地址、下单、支付模拟、支付流水、会员积分、发货、收货、评价、取消订单、申请退单、管理员审核退单。
- 区分活体宠物和普通周边商品，活体宠物必须具备唯一编号、检疫证明、疫苗记录、健康状态、溯源信息。
- 引入 RAG 智能问答、AI 文案生成、Item-CF 协同过滤、马尔可夫链行为预测、混合推荐策略。
- 保留工程化交付能力，包括接口规范、统一异常、日志追踪、自动化测试、安全扫描、部署脚本和演示材料。

## 2. 总体架构

实训阶段采用“多模块后端 + 独立 AI 推荐服务 + 用户端 + 管理端”的可落地架构。设计上保留微服务边界，实现上可以先按模块单体或轻量服务推进，避免早期拆分过度影响进度。

```text
User App / Web Client / Admin Web
                |
        Spring Cloud Gateway
                |
-------------------------------------------------
 user-service        store-service       product-service
 cart-service        order-service       payment-service
 media-service       admin-service       notification-service
-------------------------------------------------
                |
        AI Recommendation Service
 RAG Chat / Item-CF / Markov Chain / Hybrid Recommendation
                |
 MySQL / Redis / MongoDB / RabbitMQ / Vector Store
```

## 3. 仓库结构

```text
Pet-Emarket/
  frontend/user-app          用户端，负责登录、首页、附近商店、商品、购物车、订单、AI 问答
  frontend/admin-app         管理后台，负责商品审核、商店管理、订单管理、退单审核、数据看板
  backend/                   后端核心服务，负责用户、商品、购物车、订单、支付、媒体、通知
  ai-recommendation-service/ AI 与推荐服务，负责 RAG、Item-CF、马尔可夫链、混合推荐
  database/                  数据库脚本、索引、Redis key、向量库设计
  devops/                    Docker、Nginx、启动脚本、部署脚本、CI 配置
  tests/                     API 测试、端到端测试、安全检查清单
  reports/                   SAST、APPScan、截图、演示报告归档
  docs/                      需求、架构、接口、数据库、分工、测试、安全、答辩材料
```

## 4. 四人分工

默认分工如下。可以根据个人技术熟悉度调整姓名，但职责边界和目录归属不要随意变化，避免后期合并混乱。

| 成员 | 角色 | 主要目录 | 核心职责 | 必须交付 |
|---|---|---|---|---|
| 赵杰瑞 | 用户端与演示体验负责人 | `frontend/user-app`、`docs/07-presentation` | 用户登录、首页、附近商店、商品详情、购物车、订单页面、AI 问答入口、推荐展示、最终演示路线 | 可运行用户端、完整演示流程、页面截图、答辩演示脚本 |
| 翁晨昊 | 后端核心交易负责人 | `backend/user-service`、`backend/product-service`、`backend/cart-service`、`backend/order-service`、`backend/payment-service` | 用户、商品、购物车、订单状态机、支付模拟、支付/退款流水、会员积分账本、退款审核、评价、统一返回体、核心接口 | 后端核心接口、订单状态机、数据库表映射、接口联调说明 |
| 王涵哲 | AI、LBS 与推荐负责人 | `ai-recommendation-service`、`database/mongodb`、`database/vector-store` | 附近商店搜索、MongoDB 地理索引、RAG 问答、Item-CF、马尔可夫链、混合推荐、推荐理由 | 推荐接口、问答接口、LBS 查询接口、算法说明、测试样例 |
| 陈鹏翔 | 后台、DevOps 与测试负责人 | `frontend/admin-app`、`backend/admin-service`、`backend/media-service`、`devops`、`tests`、`reports` | 管理后台、商品审核、视频管理、发货、退单审核、数据看板、部署脚本、测试与安全扫描报告 | 后台页面、部署脚本、测试用例、安全扫描记录、验收材料 |

## 5. 核心职责标准

### 5.1 用户端标准

- 页面必须能支撑完整演示链路：登录 -> 附近商店 -> 商品详情 -> 加购物车 -> 下单 -> 查看订单 -> 收货评价 -> AI 问答 -> 推荐商品。
- 所有接口调用统一经过 `core/api`，禁止在页面里散落硬编码请求。
- 所有页面必须处理 loading、empty、error 三种状态。
- 订单状态、会员等级、商品类型等枚举必须和后端保持一致。
- 推荐商品要展示推荐理由，例如“根据你最近浏览的幼猫和猫粮推荐”。

### 5.2 后端核心标准

- 所有接口统一使用 `/api/v1` 前缀。
- 所有响应统一使用 `ResponseResult` 格式。
- 所有写操作必须做参数校验、权限校验和审计日志预留。
- 订单状态只能通过 `OrderStateMachine` 流转，禁止在业务代码中随意改状态。
- 支付回调、取消订单、退款审核必须考虑幂等。
- 订单明细必须保存商品名称、价格、会员折扣、地址等快照，避免后续商品变更影响历史订单。

订单状态统一如下：

```text
0  已下单/待支付
1  已支付/待发货
2  已发货/待收货
3  已收货/待评价
4  已评价/完成
-1 取消订单
-2 申请退单
-3 退单成功
-4 管理员直接退单
```

### 5.3 AI、LBS 与推荐标准

- LBS 搜索必须使用经纬度、半径、距离排序的接口语义，MongoDB 侧预留 `2dsphere` 索引。
- RAG 问答必须区分知识型问题和订单/售后类业务问题。
- 宠物健康相关回答必须带“仅供参考，严重健康问题请咨询执业兽医”的安全提示。
- 推荐服务至少实现三层策略：热门兜底、Item-CF 协同过滤、马尔可夫链行为预测。
- 混合推荐必须输出推荐分和推荐理由，便于前端展示和答辩解释。

推荐分建议：

```text
score = item_cf_score
      + markov_transition_score
      + member_level_weight
      + store_distance_weight
      + hot_item_weight
      + stock_status_weight
```

### 5.4 后台、测试与部署标准

- 后台必须覆盖商品审核、宠物活体审核、视频管理、订单发货、退单审核、会员管理、数据看板。
- 测试至少覆盖登录、商品查询、下单、支付模拟、发货、收货、评价、退单、推荐、问答。
- `reports/sast` 和 `reports/appscan` 用于保存安全扫描截图或报告。
- `devops/docker/docker-compose.yml` 用于本地一键启动基础服务。
- 每次阶段合并后必须更新测试记录和问题清单。

## 6. 接口协作规范

统一返回格式：

```json
{
  "success": true,
  "code": "000000",
  "message": "操作成功",
  "data": {},
  "traceId": "trace-id",
  "timestamp": 1783651200000
}
```

统一错误码方向：

```text
000000 成功
10xxxx 用户与权限错误
20xxxx 商品与商店错误
30xxxx 订单与支付错误
40xxxx AI 与推荐错误
50xxxx 系统异常
```

接口变更规则：

- 任何接口路径、字段、枚举、状态码变更，必须先改 `docs/03-api/api-list.md`。
- 前后端联调前必须提供请求样例和响应样例。
- 不允许口头约定字段名，所有字段必须落到文档或代码 schema。

## 7. Git 工作流

分支规则：

```text
main              稳定演示版本
develop           日常集成版本
feature/frontend-* 用户端功能
feature/backend-*  后端功能
feature/ai-*       AI、LBS、推荐功能
feature/admin-*    后台、测试、部署功能
hotfix/*           紧急修复
```

提交信息格式：

```text
feat(order): add order state machine
fix(recommend): handle empty behavior history
docs(api): update order api contract
test(order): add refund transition test
chore(devops): add docker compose skeleton
```

合并要求：

- 每个人只在自己的 feature 分支开发。
- 合并到 `develop` 前必须自测通过。
- 合并必须说明影响范围、接口变化、数据库变化。
- 冲突由相关模块负责人共同处理，不能直接覆盖别人的文件。

## 8. 分阶段推进计划

### 第一阶段：项目骨架与接口契约

目标：所有模块能启动或具备空接口，前后端知道对方字段。

- 用户端完成页面壳子和路由。
- 后端完成统一返回体、基础 Controller、订单状态枚举。
- AI 服务完成 `/recommend`、`/chat`、`/stores/nearby` 空接口。
- 后台完成菜单和页面壳子。
- 文档完成接口列表和数据库核心表。

合并点：合并到 `develop`，完成第一次全员联调。

### 第二阶段：核心业务闭环

目标：能演示完整交易流程。

- 登录注册。
- 附近商店与商品列表。
- 商品详情与活体宠物档案。
- 购物车。
- 创建订单。
- 支付模拟。
- 管理员发货。
- 用户收货和评价。
- 用户申请退单。
- 管理员审核退单。

合并点：形成可演示版本，打 `v0.1-demo` 标签。

### 第三阶段：高分功能

目标：形成答辩亮点。

- RAG 智能问答。
- AI 商品文案或视频脚本生成。
- Item-CF 推荐。
- 马尔可夫链行为预测。
- 混合推荐和推荐理由。
- 会员等级价格。
- 数据可视化看板。
- 安全扫描和测试报告。

合并点：形成高分功能版本，打 `v0.2-smart` 标签。

### 第四阶段：联调、修复与答辩包装

目标：系统稳定、演示顺畅、材料完整。

- 修复接口字段不一致。
- 准备演示账号和演示数据。
- 准备 PPT、截图、视频、扫描报告。
- 复查订单状态机、推荐算法、后台审核三条重点演示路线。
- 准备老师提问回答稿。

合并点：合并到 `main`，打 `v1.0-final` 标签。

## 9. 最终演示路线

推荐按以下顺序演示：

1. 游客浏览附近宠物商店。
2. 用户登录并成为会员。
3. 查看活体宠物详情，展示检疫证、疫苗记录、健康状态。
4. AI 问答，例如“新手适合养什么猫？”。
5. 展示推荐商品和推荐理由，解释 Item-CF + 马尔可夫链。
6. 加入购物车并创建订单。
7. 支付模拟，订单进入待发货。
8. 后台管理员发货。
9. 用户确认收货并评价。
10. 用户申请退单。
11. 管理员审核退单。
12. 展示订单状态日志、数据看板、安全扫描报告。

## 10. 开工原则

- 先跑通闭环，再追求细节。
- 先统一接口，再分头开发。
- 先做可演示功能，再做内部优化。
- 所有核心状态、枚举、字段以文档和代码常量为准。
- 不做无法演示的炫技，所有高级技术都要能在答辩里讲清楚、点出来、跑出来。
