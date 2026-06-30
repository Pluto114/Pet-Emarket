/// 用户端首页 — Voldog Material 3 · 无硬编码颜色
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/session/session_store.dart';
import '../../../../core/theme/app_theme.dart' show voldogOrange, radiusCard;
import '../ai_assistant/ai_assistant_page.dart';
import '../recommendation/recommendation_page.dart';

// ── Mock ──
const _banners = [
  {'title': '萌宠领养节', 'subtitle': '新品上线，限时领券', 'emoji': '🐶'},
  {'title': '医疗体检季', 'subtitle': '到店免费基础体检', 'emoji': '💊'},
  {'title': '口粮狂欢', 'subtitle': '满199减30 折上折', 'emoji': '🦴'},
];
const _cats = [
  {'label': '猫咪', 'icon': Icons.pets},
  {'label': '狗狗', 'icon': Icons.cruelty_free_outlined},
  {'label': '小宠', 'icon': Icons.grid_view_rounded},
  {'label': '用品', 'icon': Icons.category_outlined},
  {'label': '医疗', 'icon': Icons.local_hospital_outlined},
];
const _store = {'name': '汪星人宠物乐园', 'dist': 350, 'rating': 4.9, 'addr': '拱墅区湖墅南路200号'};

final _products = [
  _Prod('英短蓝猫 3月龄', 3800, 4.9, '🐱', '根据你浏览的猫咪用品推荐', '活体'),
  _Prod('皇家幼猫粮 2kg', 168, 4.7, '🥫', '曾购买同品牌猫粮', '口粮'),
  _Prod('全自动猫砂盆', 599, 4.6, '🚽', '热门单品 Top5', '用品'),
  _Prod('金毛幼犬 2月龄', 2500, 4.8, '🐕', '本周活体第3名', '活体'),
  _Prod('磨牙棒套装', 49, 4.5, '🦴', '铲屎官都在复购', '零食'),
  _Prod('布偶猫宝宝', 5200, 5.0, '🐱', '附近3位用户已收藏', '活体'),
  _Prod('宠物益生菌', 89, 4.4, '💊', '换季肠胃护理推荐', '保健'),
  _Prod('实木猫爬架', 799, 4.8, '🏰', '销量No.1', '用品'),
  _Prod('狗狗飞盘玩具', 35, 4.3, '🥏', '户外互动必备', '玩具'),
];

class _Prod { final String n, t, e, r; final double p, s; const _Prod(this.n, this.p, this.s, this.e, this.r, this.t); }

// ═══════════════════════════════════ HomePage ═══════════════════════════════════
class HomePage extends StatefulWidget {
  const HomePage({required this.apiClient, required this.sessionStore, required this.onNavigate, super.key});
  final ApiClient apiClient;
  final SessionStore sessionStore;
  final ValueChanged<int> onNavigate;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final AnimationController _breathCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
    ..repeat(reverse: true);
  final _breathAnim = Tween<double>(begin: 1.0, end: 1.14).animate(CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut));

  // Banner
  final _pageCtrl = PageController(viewportFraction: 0.9);
  late final Timer _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
    if (_pageCtrl.hasClients && mounted) {
      final next = (_bannerIdx + 1) % _banners.length;
      _pageCtrl.animateToPage(next, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
  });
  int _bannerIdx = 0;

  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _breathCtrl.repeat(reverse: true); }
  @override
  void dispose() { _breathCtrl.dispose(); _bannerTimer.cancel(); _pageCtrl.dispose(); _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = widget.sessionStore.user;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(children: [
        CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
          // ── AppBar：搜索栏 ──
          SliverAppBar(
            floating: true, pinned: false, snap: true,
            backgroundColor: scheme.surface, surfaceTintColor: Colors.transparent, elevation: 0, toolbarHeight: 72, titleSpacing: 16,
            flexibleSpace: SafeArea(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                Expanded(child: Container(
                  height: 48,
                  decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: scheme.primary.withAlpha(15), blurRadius: 10, offset: const Offset(0, 3))]),
                  child: TextField(controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: '搜索宠物、口粮、用品…', hintStyle: TextStyle(color: scheme.onSurface.withAlpha(80), fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: scheme.onSurface.withAlpha(100)), border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 13)),
                  ),
                )),
                const SizedBox(width: 10),
                _IconBtn(icon: Icons.qr_code_scanner_outlined, scheme: scheme, onTap: () {}),
                const SizedBox(width: 8),
                _IconBtn(icon: Icons.notifications_outlined, scheme: scheme, badge: 3, onTap: () {}),
              ]),
            )),
          ),
          // ── 欢迎语 ──
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(children: [
              CircleAvatar(radius: 22, backgroundColor: scheme.primaryContainer, child: Text(user != null && user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '🐾', style: const TextStyle(fontSize: 18))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user != null ? 'Hi, ${user.displayName} ～' : 'Hi, 铲屎官 ～', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: scheme.onSurface)),
                Text(user != null ? '${user.memberLevel} · 今天想为毛孩子添点什么？' : '今天想为毛孩子添点什么？', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              ])),
            ]),
          )),
          // ── Banner 轮播（PageView + Timer 自动播放） ──
          SliverToBoxAdapter(child: SizedBox(
            height: 150,
            child: PageView.builder(
              physics: const BouncingScrollPhysics(),
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _bannerIdx = i),
              itemCount: _banners.length,
              itemBuilder: (ctx, i) {
                final b = _banners[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ClipRRect(borderRadius: BorderRadius.circular(radiusCard), child: Container(
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [scheme.primaryContainer, scheme.secondaryContainer], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                    child: Stack(children: [
                      Positioned(right: -10, bottom: -10, child: Text(b['emoji'] as String, style: const TextStyle(fontSize: 80))),
                      Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(b['title'] as String, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: scheme.onSurface)),
                        const SizedBox(height: 6),
                        Text(b['subtitle'] as String, style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant)),
                      ])),
                    ]),
                  )),
                );
              },
            ),
          )),
          // 指示器
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_banners.length, (i) {
              return AnimatedContainer(duration: const Duration(milliseconds: 250), margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _bannerIdx == i ? 20 : 7, height: 7,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: _bannerIdx == i ? scheme.primary : scheme.primary.withAlpha(60)));
            })),
          )),
          // ── 金刚区（spaceEvenly 居中） ──
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: _cats.map((c) {
              return InkWell(onTap: () {}, borderRadius: BorderRadius.circular(20), child: SizedBox(width: 60, child: Column(children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.primaryContainer,
                  boxShadow: [BoxShadow(color: scheme.primary.withAlpha(30), blurRadius: 8, offset: const Offset(0, 2))]),
                  child: Icon(c['icon'] as IconData, color: scheme.primary, size: 24)),
                const SizedBox(height: 6),
                Text(c['label'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: scheme.onSurface)),
              ]));
            }).toList()),
          )),
          // ── 附近商店 ──
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: GestureDetector(
              onTap: () => widget.onNavigate(1),
              child: Container(height: 100, decoration: BoxDecoration(borderRadius: BorderRadius.circular(radiusCard), boxShadow: [BoxShadow(color: scheme.primary.withAlpha(12), blurRadius: 16, offset: const Offset(0, 4))]),
                child: ClipRRect(borderRadius: BorderRadius.circular(radiusCard), child: Container(
                  color: scheme.surfaceContainerLow,
                  padding: const EdgeInsets.all(18),
                  child: Row(children: [
                    Container(width: 50, height: 50, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: scheme.primaryContainer), child: Icon(Icons.store, color: scheme.primary, size: 28)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Row(children: [
                        Text(_store['name'] as String, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: scheme.onSurface)),
                        const Spacer(),
                        _ScoreChip(rating: _store['rating'] as double, scheme: scheme),
                      ]),
                      const SizedBox(height: 4),
                      Text(_store['addr'] as String, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    ])),
                    const SizedBox(width: 10),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
                      child: Text('${_store['dist']}m', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700, fontSize: 12))),
                  ]),
                )),
              ),
            ),
          )),
          // ── 智能推荐 ──
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 6),
            child: Row(children: [
              Container(width: 4, height: 20, decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Icon(Icons.auto_awesome, size: 20, color: scheme.primary),
              const SizedBox(width: 6),
              Expanded(child: Text('AI 为你推荐', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: scheme.onSurface))),
              TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecommendationPage(apiClient: widget.apiClient))), child: const Text('更多 >')),
            ]),
          )),
          // ── 瀑布商品流 3列（宽屏4列） ──
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverLayoutBuilder(builder: (ctx, constraints) {
              final w = constraints.crossAxisExtent;
              final cols = w >= 600 ? 4 : 3;
              final ratio = cols == 4 ? 0.85 : 0.90;
              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, childAspectRatio: ratio, mainAxisSpacing: 10, crossAxisSpacing: 10),
                delegate: SliverChildBuilderDelegate((ctx, i) => _card(_products[i], i, scheme), childCount: _products.length),
              );
            }),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ]),

        // ── AI 呼吸悬浮球 ──
        Positioned(right: 18, bottom: 24,
          child: AnimatedBuilder(animation: _breathCtrl, builder: (ctx, c) => Transform.scale(scale: _breathAnim.value, child: c),
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AiAssistantPage(apiClient: widget.apiClient))),
              child: Container(width: 56, height: 56,
                decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.primary, boxShadow: [BoxShadow(color: scheme.primary.withAlpha(80), blurRadius: 18, offset: const Offset(0, 6))]),
                child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 28)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _card(_Prod p, int i, ColorScheme s) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(color: s.surfaceContainerLow, borderRadius: BorderRadius.circular(radiusCard),
          boxShadow: [BoxShadow(color: s.shadow.withAlpha(10), blurRadius: 10, offset: const Offset(0, 3))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 3, child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(radiusCard)), child: Container(
            decoration: BoxDecoration(gradient: LinearGradient(colors: [s.primaryContainer, s.secondaryContainer])),
            child: Stack(children: [
              Center(child: Text(p.e, style: const TextStyle(fontSize: 36))),
              Positioned(right: 6, bottom: 6, child: _ScoreChip(rating: p.s, scheme: s, compact: true)),
            ]),
          ))),
          Expanded(flex: 3, child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.n, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: s.onSurface, height: 1.2)),
              const SizedBox(height: 4),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: s.primaryContainer.withAlpha(80), borderRadius: BorderRadius.circular(6)),
                child: Row(children: [
                  const Text('🐾 ', style: TextStyle(fontSize: 9)),
                  Expanded(child: Text(p.r, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9, color: s.onSurfaceVariant))),
                ])),
              const Spacer(),
              Row(children: [
                Text('¥${p.p.toStringAsFixed(p.p == p.p.roundToDouble() ? 0 : 0)}', style: TextStyle(color: s.primary, fontWeight: FontWeight.w800, fontSize: 14)),
                const Spacer(),
                Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, color: s.primaryContainer), child: Icon(Icons.add_shopping_cart_rounded, color: s.primary, size: 14)),
              ]),
            ]),
          )),
        ]),
      ),
    );
  }
}

// ── 小组件 ──
class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.scheme, this.badge = 0, this.onTap});
  final IconData icon; final ColorScheme scheme; final int badge; final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(width: 42, height: 42,
    decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
    child: Stack(children: [
      Center(child: Icon(icon, size: 22, color: scheme.onSurface.withAlpha(140))),
      if (badge > 0) Positioned(right: 6, top: 6, child: Container(width: 16, height: 16, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red), child: Center(child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))))),
    ]),
  ));
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.rating, required this.scheme, this.compact = false});
  final double rating; final ColorScheme scheme; final bool compact;
  @override
  Widget build(BuildContext context) => Container(padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 7, vertical: compact ? 1 : 2),
    decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(compact ? 5 : 8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.star_rounded, size: compact ? 9 : 11, color: scheme.primary),
      const SizedBox(width: 1),
      Text('$rating', style: TextStyle(fontSize: compact ? 9 : 11, fontWeight: FontWeight.w700, color: scheme.primary)),
    ]));
}
