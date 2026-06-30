/// 用户端首页 — Voldog 重设计
/// CustomScrollView + 呼吸动画 AI 悬浮球 + 瀑布商品流
library;

import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/session/session_store.dart';
import '../ai_assistant/ai_assistant_page.dart';
import '../product/product_detail_page.dart';
import '../recommendation/recommendation_page.dart';
import '../store/nearby_store_page.dart';

// ═══════════════════════════════════════════
//  品牌色 & 设计常量
// ═══════════════════════════════════════════
const Color voldogOrange = Color(0xFFFF8C42);
const Color voldogCream = Color(0xFFFFF8F3);
const double cardRadius = 24.0;

// ═══════════════════════════════════════════
//  Mock 数据
// ═══════════════════════════════════════════
const List<Map<String, dynamic>> _mockBanners = [
  {'title': '萌宠领养节', 'subtitle': '新品活体上线，限时领券', 'color': 0xFFFFE0D0, 'emoji': '🐶'},
  {'title': '医疗体检季', 'subtitle': '到店即享免费基础体检', 'color': 0xFFD0EAFF, 'emoji': '💊'},
  {'title': '口粮狂欢', 'subtitle': '满199减30 会员折上折', 'color': 0xFFFFF0D0, 'emoji': '🦴'},
];

const List<Map<String, dynamic>> _mockCategories = [
  {'label': '猫咪', 'icon': Icons.pets, 'colors': [Color(0xFFFF9A76), Color(0xFFFFB89B)]},
  {'label': '狗狗', 'icon': Icons.cruelty_free_outlined, 'colors': [Color(0xFFFFA940), Color(0xFFFFC069)]},
  {'label': '小宠', 'icon': Icons.grid_view_rounded, 'colors': [Color(0xFF7EC8A0), Color(0xFF9ED5B5)]},
  {'label': '用品', 'icon': Icons.category_outlined, 'colors': [Color(0xFF6EB5FF), Color(0xFFA0D0FF)]},
  {'label': '医疗服务', 'icon': Icons.local_hospital_outlined, 'colors': [Color(0xFFFF7777), Color(0xFFFFA0A0)]},
];

const Map<String, dynamic> _mockNearbyStore = {
  'name': '汪星人宠物乐园', 'distance': 35, 'rating': 4.9, 'address': '拱墅区湖墅南路 200 号',
  'tags': ['狗', '医疗', '美容'],
};

final List<_MockProduct> _mockProducts = [
  _MockProduct('英短蓝猫幼崽 3月龄', 3800, '🐱', '根据你最近浏览的猫咪用品推荐', 4.9, '活体', true),
  _MockProduct('皇家幼猫粮 2kg', 168, '🥫', '你曾购买过同品牌猫粮', 4.7, '口粮', false),
  _MockProduct('全自动猫砂盆', 599, '🚽', '养猫热门单品 Top 5', 4.6, '用品', false),
  _MockProduct('金毛幼犬 2月龄', 2500, '🐕', '热门活体宠物 本周第3名', 4.8, '活体', true),
  _MockProduct('狗狗磨牙棒 套装', 49, '🦴', '铲屎官都在复购', 4.5, '零食', false),
  _MockProduct('布偶猫宝宝 4月龄', 5200, '🐱', '附近3位用户已收藏', 5.0, '活体', true),
  _MockProduct('宠物益生菌', 89, '💊', '换季肠胃护理推荐', 4.4, '保健品', false),
  _MockProduct('猫爬架实木豪华款', 799, '🏰', '猫咪最爱 销量No.1', 4.8, '用品', false),
];

class _MockProduct {
  final String name;
  final double price;
  final String emoji;
  final String reason;
  final double rating;
  final String tag;
  final bool isPet;
  const _MockProduct(this.name, this.price, this.emoji, this.reason, this.rating, this.tag, this.isPet);
}

// ═══════════════════════════════════════════
//  HomePage
// ═══════════════════════════════════════════
class HomePage extends StatefulWidget {
  const HomePage({required this.apiClient, required this.sessionStore, required this.onNavigate, super.key});
  final ApiClient apiClient;
  final SessionStore sessionStore;
  final ValueChanged<int> onNavigate;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final AnimationController _breathCtrl;
  late final Animation<double> _breathAnim;

  final TextEditingController _searchCtrl = TextEditingController();
  int _bannerIdx = 0;

  @override
  void initState() {
    super.initState();
    // 呼吸动画
    _breathCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _breathAnim = Tween<double>(begin: 1.0, end: 1.14).animate(
      CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut),
    );
    _breathCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.sessionStore.user;

    return Scaffold(
      backgroundColor: voldogCream,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── 搜索栏 ──
              SliverAppBar(
                floating: true,
                pinned: false,
                snap: true,
                backgroundColor: voldogCream,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                toolbarHeight: 72,
                titleSpacing: 16,
                flexibleSpace: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: voldogOrange.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 3))],
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: InputDecoration(
                              hintText: '搜索宠物、口粮、用品…',
                              hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.35), fontSize: 14),
                              prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _IconBubble(icon: Icons.qr_code_scanner_outlined, onTap: () {}),
                      const SizedBox(width: 8),
                      _IconBubble(icon: Icons.notifications_outlined, badge: 3, onTap: () {}),
                    ]),
                  ),
                ),
              ),

              // ── 欢迎语 ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: voldogOrange.withValues(alpha: 0.15),
                      child: Text(
                        user != null && user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '🐾',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(user != null ? 'Hi, ${user.displayName} ～' : 'Hi, 铲屎官 ～',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        Text(user != null ? '${user.memberLevel} · 今天想为毛孩子添点什么？' : '今天想为毛孩子添点什么？',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                      ]),
                    ),
                  ]),
                ),
              ),

              // ── Banner 轮播 ──
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 150,
                  child: PageView.builder(
                    onPageChanged: (i) => setState(() => _bannerIdx = i),
                    controller: PageController(viewportFraction: 0.9),
                    itemCount: _mockBanners.length,
                    itemBuilder: (ctx, i) {
                      final b = _mockBanners[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(cardRadius),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(b['color'] as int), Color(b['color'] as int).withValues(alpha: 0.6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Stack(children: [
                              Positioned(right: -10, bottom: -10, child: Text(b['emoji'] as String, style: const TextStyle(fontSize: 80))),
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Text(b['title'] as String, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF3D2C1E))),
                                  const SizedBox(height: 6),
                                  Text(b['subtitle'] as String, style: const TextStyle(fontSize: 14, color: Color(0xFF7A5C4A))),
                                ]),
                              ),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Banner 指示器
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 6),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_mockBanners.length, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _bannerIdx == i ? 20 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _bannerIdx == i ? voldogOrange : voldogOrange.withValues(alpha: 0.25),
                      ),
                    );
                  })),
                ),
              ),

              // ── 金刚区（分类图标行） ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: SizedBox(
                    height: 82,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _mockCategories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (ctx, i) {
                        final cat = _mockCategories[i];
                        return InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 72,
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(children: [
                              Container(
                                width: 50, height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(colors: (cat['colors'] as List<Color>), begin: Alignment.topLeft, end: Alignment.bottomRight),
                                  boxShadow: [BoxShadow(color: (cat['colors'] as List<Color>)[0].withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 3))],
                                ),
                                child: Icon(cat['icon'] as IconData, color: Colors.white, size: 26),
                              ),
                              const SizedBox(height: 6),
                              Text(cat['label'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // ── 附近商店卡片 ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: GestureDetector(
                    onTap: () => widget.onNavigate(1),
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(cardRadius),
                        boxShadow: [BoxShadow(color: voldogOrange.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(cardRadius),
                        child: Stack(children: [
                          // 模糊背景
                          Positioned.fill(
                            child: Image.asset('', errorBuilder: (_, __, ___) => Container(
                              decoration: BoxDecoration(gradient: LinearGradient(colors: [voldogOrange.withValues(alpha: 0.08), voldogOrange.withValues(alpha: 0.02)])),
                            )),
                          ),
                          BackdropFilter(
                            filter: const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                            child: Container(color: theme.colorScheme.surface.withValues(alpha: 0.92)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(children: [
                              Container(
                                width: 50, height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(colors: [voldogOrange, Color(0xFFFFB088)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                ),
                                child: const Icon(Icons.store, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Row(children: [
                                    Text(_mockNearbyStore['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                    const Spacer(),
                                    _ScoreChip(rating: _mockNearbyStore['rating'] as double),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(_mockNearbyStore['address'] as String, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                                ]),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: voldogOrange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                                child: Text('${_mockNearbyStore['distance']}m', style: const TextStyle(color: voldogOrange, fontWeight: FontWeight.w700, fontSize: 12)),
                              ),
                            ]),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),

              // ── 智能推荐标题 ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 6),
                  child: Row(children: [
                    Container(
                      width: 4, height: 20,
                      decoration: BoxDecoration(color: voldogOrange, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.auto_awesome, size: 20, color: voldogOrange),
                    const SizedBox(width: 6),
                    const Expanded(child: Text('AI 为你推荐', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                    TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => RecommendationPage(apiClient: widget.apiClient))), child: const Text('更多 >')),
                  ]),
                ),
              ),

              // ── 瀑布商品流 ──
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.72, mainAxisSpacing: 12, crossAxisSpacing: 12),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildProductCard(_mockProducts[i], i, theme),
                    childCount: _mockProducts.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // ── AI 呼吸悬浮球 ──
          Positioned(
            right: 18, bottom: 24,
            child: AnimatedBuilder(
              animation: _breathAnim,
              builder: (ctx, child) => Transform.scale(
                scale: _breathAnim.value,
                child: child,
              ),
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => AiAssistantPage(apiClient: widget.apiClient))),
                child: Container(
                  width: 58, height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [voldogOrange, Color(0xFFFF6B35)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    boxShadow: [BoxShadow(color: voldogOrange.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 6))],
                  ),
                  child: Stack(children: [
                    const Center(child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 28)),
                    Positioned(right: 8, top: 8, child: Container(width: 10, height: 10,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white))),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 商品卡片 ──
  Widget _buildProductCard(_MockProduct p, int index, ThemeData theme) {
    final height = index.isEven ? 280.0 : 250.0 + Random(index).nextDouble() * 20;
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(cardRadius),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 图片区
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(cardRadius)),
              child: Container(
                decoration: BoxDecoration(gradient: LinearGradient(colors: [
                  p.isPet ? const Color(0xFFFFF0E8) : const Color(0xFFF0F8FF),
                  p.isPet ? const Color(0xFFFDE8D5) : const Color(0xFFE3F0FF),
                ])),
                child: Stack(children: [
                  Center(child: Text(p.emoji, style: const TextStyle(fontSize: 46))),
                  if (p.isPet)
                    Positioned(left: 10, top: 10, child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: voldogOrange.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(8)),
                      child: const Text('活体', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    )),
                  Positioned(right: 8, bottom: 8, child: _ScoreChip(rating: p.rating, compact: true)),
                ]),
              ),
            ),
          ),
          // 信息区
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, height: 1.25)),
                const SizedBox(height: 6),
                // AI 推荐理由
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: voldogOrange.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Text('🐾', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 4),
                    Expanded(child: Text(p.reason, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.55)))),
                  ]),
                ),
                const Spacer(),
                Row(children: [
                  Text('¥${p.price.toStringAsFixed(p.price == p.price.roundToDouble() ? 0 : 0)}',
                      style: const TextStyle(color: voldogOrange, fontWeight: FontWeight.w800, fontSize: 17)),
                  const Spacer(),
                  Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: voldogOrange.withValues(alpha: 0.12)),
                    child: const Icon(Icons.add_shopping_cart_rounded, color: voldogOrange, size: 16)),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════
//  共享小组件
// ═══════════════════════════════════════════

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon, this.badge = 0, this.onTap});
  final IconData icon;
  final int badge;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: voldogOrange.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Stack(children: [
          Center(child: Icon(icon, size: 22, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55))),
          if (badge > 0)
            Positioned(right: 6, top: 6, child: Container(
              width: 16, height: 16,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFF4444)),
              child: Center(child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))),
            )),
        ]),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.rating, this.compact = false});
  final double rating;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 2 : 3),
      decoration: BoxDecoration(color: voldogOrange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(compact ? 6 : 10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.star_rounded, size: compact ? 10 : 12, color: voldogOrange),
        const SizedBox(width: 2),
        Text('$rating', style: TextStyle(fontSize: compact ? 10 : 12, fontWeight: FontWeight.w700, color: voldogOrange)),
      ]),
    );
  }
}
