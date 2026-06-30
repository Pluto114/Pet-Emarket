# 前端架构分析与完成情况

> 项目: Pet-Emarket Flutter 前端 | 分析日期: 2026-06-29 | 框架: Flutter 3.44 + Dart 3.12

---

## 一、文件架构总览

```
frontend/pet-emarket-app/lib/
│
├── main.dart                          # 应用入口，路由分发
│
├── core/                              # 基础设施层
│   ├── api/
│   │   ├── api_client.dart            # API 客户端（20+ 接口全覆盖）
│   │   ├── api_transport.dart         # 传输层平台分发
│   │   ├── api_transport_io.dart      # dart:io 原生传输
│   │   ├── api_transport_web.dart     # Web HttpRequest 传输
│   │   ├── api_transport_stub.dart    # 不支持的平台抛异常
│   │   └── api_transport_types.dart   # TransportResponse 类型
│   ├── session/
│   │   └── session_store.dart         # 会话状态 (ChangeNotifier)
│   └── theme/
│       └── app_theme.dart             # Material 3 主题 (Voldog 设计)
│
├── models/                            # 数据模型层 (10 个)
│   ├── ai_chat.dart                   # AI 问答回答
│   ├── admin_dashboard.dart           # 管理后台数据看板
│   ├── app_user.dart                  # 用户模型
│   ├── cart_item.dart                 # 购物车条目
│   ├── media_asset.dart               # 媒体资源
│   ├── order.dart                     # 订单 + 状态日志
│   ├── product.dart                   # 商品 (含活体宠物子结构)
│   ├── recommendation.dart            # 推荐结果
│   ├── shipping_address.dart          # 收货地址
│   └── store.dart                     # 宠物商店
│
├── features/                          # 功能页面层
│   ├── auth/
│   │   └── auth_page.dart             # 登录/注册页
│   │
│   ├── user/                          # 用户端 (8 文件)
│   │   ├── user_shell.dart            # 底部导航壳 + HomeTab + ProfileTab
│   │   ├── ai_assistant/              # AI 问答页面
│   │   ├── cart/                      # 购物车 + 收货地址管理
│   │   ├── order/                     # 订单页 (完整状态机操作)
│   │   ├── product/                   # 商品列表 + 详情
│   │   ├── profile/                   # 用户管理 CRUD
│   │   ├── recommendation/           # 推荐展示 (评分芯片 + 理由)
│   │   └── store/                     # 附近商店 LBS 搜索
│   │
│   └── admin/                         # 管理端 (9 文件)
│       ├── admin_shell.dart           # 响应式导航壳
│       ├── dashboard/                 # 数据看板 (统计 + 饼图)
│       ├── media/                     # 媒体审核管理
│       ├── member/                    # 会员管理 CRUD
│       ├── order/                     # 订单管理 (发货/取消/直退)
│       ├── pet_audit/                 # 活体宠物审核
│       ├── product/                   # 商品管理 CRUD
│       ├── refund/                    # 退单审核 (同意/拒绝)
│       └── store/                     # 门店管理 CRUD
│
└── shared/                            # 共享组件层
    └── widgets/
        ├── confirm_dialog.dart        # 确认对话框 (支持 destructive)
        ├── empty_state.dart           # 空状态占位
        ├── skeleton_loader.dart       # Shimmer 骨架屏
        └── toast.dart                 # Success/Error/Info SnackBar
```

---

## 二、完成情况

### 整体：40 个文件，全部 DONE

| 层级 | 文件数 | 状态 |
|------|--------|------|
| `core/api` | 6 | ✅ 全部完成 |
| `core/session` | 1 | ✅ Token 持久化 + devBypass |
| `core/theme` | 1 | ✅ Material 3 + Voldog 亮暗双主题 |
| `models` | 10 | ✅ fromJson/toJson + null-safety |
| `features/auth` | 1 | ✅ 登录/注册/表单校验 |
| `features/user` | 8 | ✅ loading/error/empty 三状态全覆盖 |
| `features/admin` | 9 | ✅ 8 页面 + 响应式导航 |
| `shared/widgets` | 4 | ✅ 骨架屏/空状态/Toast/对话框 |

### 各页面功能清单

| 页面 | 核心功能 | 状态 |
|------|----------|------|
| **AuthPage** | 登录、注册、表单校验、devBypass 跳过登录 | ✅ |
| **HomeTab** | 欢迎卡片、热门商品、活体推荐、快捷入口 | ✅ |
| **ProductsPage** | 商品列表、搜索、CRUD 对话框、角色权限 | ✅ |
| **ProductDetailPage** | 商品详情、活体档案、加购物车、行为埋点 | ✅ |
| **NearbyStorePage** | 附近商店列表、距离显示、商店详情 | ✅ |
| **RecommendationPage** | 推荐列表、评分芯片、策略推荐理由展示 | ✅ |
| **AiAssistantPage** | 聊天 UI、消息气泡、知识标签、推荐操作 | ✅ |
| **CartPage** | 购物车列表、地址管理 CRUD、创建订单 | ✅ |
| **OrderPage** | 订单状态机（支付/发货/收货/评价/取消/退单） | ✅ |
| **DashboardPage** | 6 统计卡片、饼图(fl_chart)、销量排行 | ✅ |
| **ProductManagePage** | 商品 CRUD + 活体字段条件展示 | ✅ |
| **PetAuditPage** | 活体宠物审核列表 + 通过 | ✅ |
| **OrderManagePage** | 订单列表 + 发货/取消/直退操作 | ✅ |
| **RefundAuditPage** | 退单审核（同意/拒绝 + 备注） | ✅ |
| **MediaManagePage** | 媒体审核 + CRUD | ✅ |
| **StoreManagePage** | 门店 CRUD + 经纬度 | ✅ |

---

## 三、架构特点

### 优势

1. **三层状态全覆盖**：所有页面 loading/empty/error 三种状态均处理
2. **角色权限**：`SessionStore.isAdmin` 控制页面路由和按钮显隐
3. **平台适配**：IO/Web 双传输层，Chrome + Android
4. **Material 3 设计系统**：Voldog 品牌色 + 亮/暗双主题
5. **模型完整**：10 个 model 全部 fromJson/toJson

### 待优化的代码结构问题

| 问题 | 位置 | 影响 |
|------|------|------|
| `user_shell.dart` 过大 (721行) | 内嵌 HomeTab/ProfileTab/ProductsPage 等 | 难维护 |
| 产品 CRUD 重复 | `user/product/` 和 `admin/product/` 两份 | 代码冗余 |
| 活体审核缺拒绝 | `pet_audit_page.dart` 只有「通过」按钮 | 功能不完整 |
| `profile_page.dart` 未接入导航 | 独立 UsersPage 未被任何路由引用 | 死代码 |

---

## 四、演示路线对照

README 12 步演示 vs 前端实现：

| # | 演示步骤 | 前端页面 | 状态 |
|----|----------|----------|------|
| 1 | 游客浏览附近商店 | `NearbyStorePage` | ✅ |
| 2 | 用户登录成为会员 | `AuthPage` | ✅ |
| 3 | 活体宠物详情 (检疫证/疫苗) | `ProductDetailPage` | ⚠️ 档案展开待完善 |
| 4 | AI 问答 | `AiAssistantPage` | ✅ |
| 5 | 推荐商品 + 理由 | `RecommendationPage` | ✅ |
| 6 | 加购物车创建订单 | `CartPage` | ✅ |
| 7 | 支付模拟 | `OrderPage` | ✅ |
| 8 | 管理员发货 | `OrderManagePage` | ✅ |
| 9 | 确认收货评价 | `OrderPage` | ✅ |
| 10 | 申请退单 | `OrderPage` | ✅ |
| 11 | 审核退单 | `RefundAuditPage` | ✅ |
| 12 | 数据看板 | `DashboardPage` | ✅ |

11/12 已覆盖。

---

## 五、待开发内容

### UI/UX 大改方向

| 优先级 | 内容 | 当前状态 |
|--------|------|----------|
| **高** | 首页重设计（独立布局，非内嵌 Tab） | `HomeTab` 嵌在 `user_shell.dart` |
| **高** | 活体档案详情展开（检疫证/疫苗/溯源） | 模型支持，UI 待扩展 |
| **高** | 活体审核拒绝流程 | 缺拒绝按钮 |
| **中** | 商品搜索 + 分类筛选 | 仅标题搜索 |
| **中** | 购物车结算步骤引导 | 当前为单页表单 |
| **中** | 会员积分/支付流水展示 | 后端已有 API |
| **低** | AI 文案生成页面 | 未开发 |
| **低** | 响应式平板适配 | 仅手机竖屏 |

### 用户端首页重新设计方案

当前首页是 `user_shell.dart` 中的 `HomeTab` 内联组件，结构简单：

```
当前: [欢迎卡片] → [热门商品横向滚动] → [活体推荐] → [快捷操作按钮]
```

建议改为独立 `features/user/home/home_page.dart`：

```
新设计:
  [搜索栏]
  [Banner 轮播]
  [分类图标行 (猫/狗/小宠/用品/医疗)]
  [附近商店快捷卡片]
  [AI 助手快捷入口 - 气泡]
  [推荐商品流 (瀑布/网格)]
  [底部: 为你推荐 + 推荐理由]
```

### 文件拆分建议

```
features/user/
  ├── user_shell.dart         → 仅导航壳 (<100行)
  ├── home/
  │   └── home_page.dart      ← 从 user_shell 拆出 HomeTab
  ├── products/
  │   ├── products_page.dart  ← 从 user_shell 拆出
  │   └── product_detail_page.dart
  ├── profile/
  │   └── profile_page.dart   ← 从 user_shell 拆出 ProfileTab
  ├── recommendation/
  ├── ai_assistant/
  ├── cart/
  ├── order/
  └── store/
```
