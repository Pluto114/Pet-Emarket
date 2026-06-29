# AI 智能问答接口对接文档

> 服务: `ai-recommendation-service` | 版本: v1 | 最后更新: 2026-06-29

---

## 接口地址

| 环境 | 地址 |
|------|------|
| 本地开发 | `http://localhost:8001` |
| AI 服务端口 | `8001` |

---

## POST /api/v1/chat — RAG 智能问答

### 请求

```http
POST /api/v1/chat
Content-Type: application/json
```

```json
{
  "userId": "string (必填, 用户ID)",
  "question": "string (必填, 1~500字符)",
  "context": {
    "orderId": "string (可选, 关联订单ID)",
    "productId": "string (可选, 关联商品ID)"
  }
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `userId` | string | 是 | 当前登录用户 ID |
| `question` | string | 是 | 用户问题，1-500 字符 |
| `context` | object | 否 | 可选上下文 |
| `context.orderId` | string | 否 | 在订单详情页提问时传入 |
| `context.productId` | string | 否 | 在商品详情页提问时传入 |

### 响应 — 知识库回答

```json
{
  "success": true,
  "code": "000000",
  "message": "操作成功",
  "data": {
    "answer": "[此回答来自知识库]\n幼犬应从6-8周龄开始接种核心疫苗...",
    "sources": [
      { "title": "宠物疫苗全面指南", "url": "" },
      { "title": "狗狗日常健康护理指南", "url": "" }
    ],
    "disclaimer": "【免责声明】以上内容仅供参考...",
    "relatedProducts": [],
    "answerSource": "knowledge_base"
  },
  "traceId": "a1b2c3d4",
  "timestamp": 1783651200000
}
```

### 响应 — AI 模型回答（知识库无匹配）

```json
{
  "success": true,
  "code": "000000",
  "data": {
    "answer": "[此回答来自 AI 模型自身知识，仅供参考]\n金毛犬每天需要1-2小时运动...",
    "sources": [],
    "disclaimer": "",
    "relatedProducts": [],
    "answerSource": "ai_model"
  }
}
```

### 响应 — 业务型模板回答

```json
{
  "success": true,
  "code": "000000",
  "data": {
    "answer": "关于订单问题，建议您前往「我的订单」页面查看...",
    "sources": [],
    "disclaimer": "",
    "relatedProducts": [],
    "answerSource": "template"
  }
}
```

### 响应 — 安全拦截

```json
{
  "success": false,
  "code": "400004",
  "message": "问题包含不当内容，请重新输入",
  "data": {},
  "traceId": "a1b2c3d4",
  "timestamp": 1783651200000
}
```

### 响应字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| `data.answer` | string | AI 回答内容，含来源标签前缀 |
| `data.sources` | array | 引用的知识库文档列表 |
| `data.disclaimer` | string | 免责声明（仅健康类问题返回非空） |
| `data.answerSource` | string | 来源标识 |
| `data.relatedProducts` | array | 关联商品 ID 列表（预留字段） |

### answerSource 枚举

| 值 | 含义 | 前端展示建议 |
|----|------|-------------|
| `knowledge_base` | 来自 MSD 兽医知识库 | 绿色标签"知识库认证" |
| `ai_model` | 来自 AI 模型通用知识 | 灰色标签"AI 参考" |
| `template` | 业务模板回答 | 无需标签 |

### 错误码

| code | 含义 | 前端处理 |
|------|------|----------|
| `000000` | 成功 | 正常展示 |
| `400003` | 问答服务不可用 | 提示"AI 暂时不可用，请稍后" |
| `400004` | 内容被安全拦截 | 提示"请更换问题" |

---

## 前端集成示例

### Flutter (Dart)

```dart
Future<Map<String, dynamic>> askAI(String userId, String question) async {
  final uri = Uri.parse('http://localhost:8001/api/v1/chat');
  final resp = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'userId': userId, 'question': question}),
  );
  final data = jsonDecode(resp.body);
  if (data['success'] != true) {
    throw Exception(data['message'] ?? 'AI service error');
  }
  return data['data'];
}
```

### Java (Spring Boot RestTemplate)

```java
RestTemplate restTemplate = new RestTemplate();
HttpHeaders headers = new HttpHeaders();
headers.setContentType(MediaType.APPLICATION_JSON);

Map<String, Object> body = new HashMap<>();
body.put("userId", userId);
body.put("question", question);

HttpEntity<Map<String, Object>> request = new HttpEntity<>(body, headers);
String aiUrl = "http://localhost:8001/api/v1/chat";
ResponseEntity<Map> response = restTemplate.postForEntity(aiUrl, request, Map.class);

Map<String, Object> result = response.getBody();
boolean success = (boolean) result.get("success");
if (success) {
    Map<String, Object> data = (Map<String, Object>) result.get("data");
    String answer = (String) data.get("answer");
    String source = (String) data.get("answerSource");
    // 返回给前端
}
```

---

## 问答流程

```
前端 → POST /api/v1/chat
         ├─ 安全检测 (Prompt Guard)
         │   ├─ 敏感词/注入 → 400004
         │   └─ 健康类 → 加免责声明
         ├─ 问题分类
         │   ├─ 业务型 (订单/退款/物流) → 模板 answerSource=template
         │   └─ 知识型 → 继续
         └─ 知识库检索
             ├─ 有结果 → 百炼 qwen-plus + 宠物知识库 → answerSource=knowledge_base
             └─ 无结果 → 百炼 qwen-plus 通用回答 → answerSource=ai_model
```

## 注意事项

1. **超时**: LLM 调用约 2-5 秒，建议设 30 秒超时
2. **防抖**: 用户快速连点会消耗百炼额度，建议前端 500ms 防抖
3. **免责声明**: `disclaimer` 非空时前端必须展示在回答下方
4. **来源标签**: `answer` 字段已包含 `[此回答来自知识库]` 前缀，可直接展示
5. **空结果**: 知识库无匹配自动降级 AI 模型回答，不会返回空内容

---

## 本地开发环境搭建（团队成员必读）

AI 服务依赖 MongoDB 存储知识库和用户行为数据。以下为每位团队成员在本机搭建开发环境的步骤。

### 1. 安装 Docker 并拉取 MongoDB

```bash
# 拉取 MongoDB 镜像
docker pull mongo:8

# 启动 MongoDB 容器（带认证）
docker run -d --name mongodb-local -p 27017:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=123456 \
  mongo:8
```

### 2. 导入知识库数据

```bash
# 进入项目目录
cd Pet-Emarket/ai-recommendation-service

# 运行知识库种子脚本
docker exec -i mongodb-local mongosh -u admin -p 123456 --authenticationDatabase admin < scripts/seed_knowledge_v2.js
```

### 3. 安装 Python 依赖并启动服务

```bash
pip install -r requirements.txt
python -m uvicorn app.main:app --port 8001
```

### 4. 验证服务

```bash
curl http://localhost:8001/health
# 预期返回: {"success":true, "data":{"mongodb":"ok", ...}}
```

### 5. 配置 LLM API Key

`app/core/config.py` 中已内置团队共享百炼 API Key。如需使用个人 Key，修改该文件中的 `LLM_API_KEY` 即可。

### MongoDB 连接信息

| 配置项 | 值 |
|--------|-----|
| 地址 | `localhost:27017` |
| 用户名 | `admin` |
| 密码 | `123456` |
| 认证数据库 | `admin` |
| 业务数据库 | `pet_emarket` |
| 连接字符串 | `mongodb://admin:123456@localhost:27017/pet_emarket?authSource=admin` |

### 知识库结构

`pet_emarket.knowledge_base` 集合，46 篇文档，15 个分类：

`selecting_pet`(5) `feeding`(5) `daily_care`(4) `dog_health`(4) `cat_health`(3)
`parasites`(3) `vaccination`(2) `behavior`(3) `breed_dog`(3) `breed_cat`(3)
`environment`(3) `emergency`(3) `senior_care`(2) `spay_neuter`(1) `small_pets`(2)
