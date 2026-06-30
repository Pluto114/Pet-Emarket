/// 首页 — Voldog 滚动联动动画 · 视差 · 弹跳 · 3D 倾斜
library;

import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/session/session_store.dart';
import '../../../../core/theme/app_theme.dart' show radiusCard;
import '../ai_assistant/ai_assistant_page.dart';
import '../recommendation/recommendation_page.dart';

// ── Mock ──
const _banners = [
  {'title':'萌宠领养节','sub':'新品活体上线，限时领券','emoji':'🐶'},
  {'title':'医疗体检季','sub':'到店即享免费基础体检','emoji':'💊'},
  {'title':'口粮狂欢','sub':'满199减30，会员折上折','emoji':'🦴'},
];
const _cats = [
  {'l':'猫咪','i':Icons.pets},
  {'l':'狗狗','i':Icons.cruelty_free_outlined},
  {'l':'小宠','i':Icons.grid_view_rounded},
  {'l':'用品','i':Icons.category_outlined},
  {'l':'医疗','i':Icons.local_hospital_outlined},
];
const _store = {'n':'汪星人宠物乐园','d':350,'r':4.9,'a':'拱墅区湖墅南路200号'};
final _prods = [
  _P('英短蓝猫 3月龄',3800,4.9,'🐱','浏览过猫咪用品','活体'),
  _P('皇家幼猫粮 2kg',168,4.7,'🥫','复购同品牌','口粮'),
  _P('自动猫砂盆',599,4.6,'🚽','热门Top5','用品'),
  _P('金毛幼犬',2500,4.8,'🐕','本周活体第3','活体'),
  _P('磨牙棒套装',49,4.5,'🦴','都在复购','零食'),
  _P('布偶猫宝宝',5200,5.0,'🐱','3人已收藏','活体'),
  _P('宠物益生菌',89,4.4,'💊','换季推荐','保健'),
  _P('实木猫爬架',799,4.8,'🏰','销量No.1','用品'),
  _P('飞盘玩具',35,4.3,'🥏','户外必备','玩具'),
];
class _P{final String n,t,e,r;final double p,s;const _P(this.n,this.p,this.s,this.e,this.r,this.t);}

// ═══════════════════════════════════════════ HomePage ═══════════════════════════════════════════
class HomePage extends StatefulWidget {
  const HomePage({required this.apiClient,required this.sessionStore,required this.onNavigate,super.key});
  final ApiClient apiClient;final SessionStore sessionStore;final ValueChanged<int> onNavigate;
  @override State<HomePage> createState()=>_HS();
}

class _HS extends State<HomePage> with TickerProviderStateMixin {
  // ── Breathing AI bubble ──
  late final AnimationController _breathCtrl;
  late final Animation<double> _breathAnim;

  // ── Banner auto-scroll ──
  final _pageCtrl = PageController(viewportFraction: 0.88);
  late final Timer _bannerTimer;
  int _bi = 0;

  // ── Scroll-driven animations ──
  final ScrollController _scrollCtrl = ScrollController();
  double _scrollOffset = 0;
  double _lastScrollOffset = 0;
  bool _scrollingDown = false;

  final _searchCtrl = TextEditingController();

  @override void initState() {
    super.initState();
    _breathCtrl = AnimationController(vsync:this, duration:const Duration(milliseconds:1800));
    _breathAnim = Tween(begin:1.0, end:1.14).animate(CurvedAnimation(parent:_breathCtrl, curve:Curves.easeInOut));
    _breathCtrl.repeat(reverse:true);

    _bannerTimer = Timer.periodic(const Duration(milliseconds:3500), (_) {
      if (_pageCtrl.hasClients && mounted) {
        final n = (_bi + 1) % _banners.length;
        _pageCtrl.animateToPage(n, duration:const Duration(milliseconds:600), curve:Curves.easeInOut);
      }
    });

    // 全局滚动监听
    _scrollCtrl.addListener(() {
      final o = _scrollCtrl.offset;
      setState(() {
        _scrollingDown = o > _lastScrollOffset;
        _scrollOffset = o;
        _lastScrollOffset = o;
      });
    });
  }

  @override void dispose() {
    _breathCtrl.dispose();
    _bannerTimer.cancel();
    _pageCtrl.dispose();
    _scrollCtrl.removeListener((){});
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── 动画计算 ──
  double _clamp(double v, double min, double max) => v < min ? min : v > max ? max : v;
  double _parallax(double start, double end, double from, double to) {
    final t = _clamp((_scrollOffset - start) / (end - start), 0.0, 1.0);
    return from + (to - from) * t;
  }

  @override Widget build(BuildContext ctx) {
    final t = Theme.of(ctx);
    final s = t.colorScheme;
    final u = widget.sessionStore.user;

    // Banner parallax: offset 0→200 → scale 1.0→0.85, opacity 1.0→0.0
    final bannerScale = _parallax(0, 200, 1.0, 0.85);
    final bannerOpacity = _parallax(0, 200, 1.0, 0.0);

    // Category icons stagger trigger: become visible when scroll > 80
    final catVisible = _scrollOffset > 80;

    // Grid cards appear threshold
    final gridVisible = _scrollOffset > 250;

    // AI bubble: slide right on scroll-down, back on scroll-up
    final bubbleDx = _scrollingDown && _scrollOffset > 100 ? 100.0 : 0.0;

    return Scaffold(
      backgroundColor: s.surface,
      body: Stack(children: [
        CustomScrollView(controller: _scrollCtrl, physics: const BouncingScrollPhysics(), slivers: [
          //── 搜索栏 ──
          SliverAppBar(floating:true, pinned:false, snap:true, backgroundColor:s.surface, surfaceTintColor:Colors.transparent, elevation:0, toolbarHeight:72, titleSpacing:16,
            flexibleSpace:SafeArea(child:Padding(padding:const EdgeInsets.symmetric(horizontal:16,vertical:8), child:Row(children:[
              Expanded(child:Container(height:48, decoration:BoxDecoration(color:s.surfaceContainerLow, borderRadius:BorderRadius.circular(24),
                boxShadow:[BoxShadow(color:s.primary.withAlpha(12), blurRadius:10, offset:const Offset(0,3))]),
                child:TextField(controller:_searchCtrl, decoration:InputDecoration(hintText:'搜索宠物、口粮…', hintStyle:TextStyle(color:s.onSurface.withAlpha(80),fontSize:14),
                  prefixIcon:Icon(Icons.search_rounded, color:s.onSurface.withAlpha(100)), border:InputBorder.none, contentPadding:const EdgeInsets.symmetric(vertical:13))))),
              const SizedBox(width:10),
              _IB(icon:Icons.qr_code_scanner_outlined, s:s, onTap:(){}),
              const SizedBox(width:8),
              _IB(icon:Icons.notifications_outlined, s:s, badge:3, onTap:(){}),
            ])))),
          //── 欢迎语 ──
          SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.fromLTRB(20,4,20,12), child:Row(children:[
            CircleAvatar(radius:22, backgroundColor:s.primaryContainer, child:Text(u!=null&&u.displayName.isNotEmpty?u.displayName[0].toUpperCase():'🐾', style:const TextStyle(fontSize:18))),
            const SizedBox(width:10),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
              Text(u!=null?'Hi, ${u.displayName} ～':'Hi, 铲屎官 ～', style:TextStyle(fontWeight:FontWeight.w700, fontSize:16, color:s.onSurface)),
              Text(u!=null?'${u.memberLevel} · 今天想为毛孩子添点什么？':'今天想为毛孩子添点什么？', style:TextStyle(fontSize:12, color:s.onSurfaceVariant)),
            ])),
          ]))),

          //── Banner 视差：scale + opacity ──
          SliverToBoxAdapter(child:Transform.scale(
            scale: bannerScale,
            child: Opacity(
              opacity: bannerOpacity,
              child: SizedBox(height:155, child:PageView.builder(
                physics:const BouncingScrollPhysics(), controller:_pageCtrl, onPageChanged:(i)=>setState(()=>_bi=i), itemCount:_banners.length,
                itemBuilder:(_,i){final b=_banners[i];
                  return Padding(padding:const EdgeInsets.symmetric(horizontal:6), child:ClipRRect(borderRadius:BorderRadius.circular(radiusCard), child:Container(
                    decoration:BoxDecoration(gradient:LinearGradient(colors:[s.primaryContainer, s.secondaryContainer], begin:Alignment.topLeft, end:Alignment.bottomRight)),
                    child:Stack(children:[
                      Positioned(right:-10, bottom:-10, child:Text(b['emoji']as String, style:const TextStyle(fontSize:80))),
                      Padding(padding:const EdgeInsets.all(24), child:Column(crossAxisAlignment:CrossAxisAlignment.start, mainAxisAlignment:MainAxisAlignment.center, children:[
                        Text(b['title']as String, style:TextStyle(fontSize:22, fontWeight:FontWeight.w800, color:s.onSurface)),
                        const SizedBox(height:6),
                        Text(b['sub']as String, style:TextStyle(fontSize:14, color:s.onSurfaceVariant)),
                      ])),
                    ]))),
                  );
                },
              )),
            ),
          )),

          // 胶囊指示器
          SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.only(top:12, bottom:6), child:Row(mainAxisAlignment:MainAxisAlignment.center, children:List.generate(_banners.length, (i){
            final active = _bi == i;
            return AnimatedContainer(duration:const Duration(milliseconds:300), margin:const EdgeInsets.symmetric(horizontal:4),
              width:active?24:8, height:8, decoration:BoxDecoration(borderRadius:BorderRadius.circular(4), color:active?s.primary:s.primary.withAlpha(60)));
          })))),

          //── 金刚区：Staggered bounce-in ──
          SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.symmetric(vertical:10, horizontal:4), child:Row(
            mainAxisAlignment:MainAxisAlignment.spaceEvenly,
            children:List.generate(_cats.length, (i) {
              final c = _cats[i];
              return _CatBounce(
                index: i,
                visible: catVisible,
                child: InkWell(onTap:(){}, borderRadius:BorderRadius.circular(20), child:SizedBox(width:60, child:Column(children:[
                  Container(width:48, height:48, decoration:BoxDecoration(shape:BoxShape.circle, color:s.primaryContainer,
                    boxShadow:[BoxShadow(color:s.primary.withAlpha(30), blurRadius:8, offset:const Offset(0,2))]),
                    child:Icon(c['i']as IconData, color:s.primary, size:24)),
                  const SizedBox(height:6),
                  Text(c['l']as String, style:TextStyle(fontSize:11, fontWeight:FontWeight.w500, color:s.onSurface)),
                ]))),
              );
            }),
          ))),

          //── 附近商店 ──
          SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.fromLTRB(20,8,20,4), child:GestureDetector(
            onTap:()=>widget.onNavigate(1),
            child:Container(height:100, decoration:BoxDecoration(borderRadius:BorderRadius.circular(radiusCard),
              boxShadow:[BoxShadow(color:s.primary.withAlpha(12), blurRadius:16, offset:const Offset(0,4))]),
              child:ClipRRect(borderRadius:BorderRadius.circular(radiusCard), child:Container(color:s.surfaceContainerLow, padding:const EdgeInsets.all(18), child:Row(children:[
                Container(width:50, height:50, decoration:BoxDecoration(borderRadius:BorderRadius.circular(16), color:s.primaryContainer),
                  child:Icon(Icons.store, color:s.primary, size:28)),
                const SizedBox(width:14),
                Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, mainAxisAlignment:MainAxisAlignment.center, children:[
                  Row(children:[Text(_store['n']as String, style:TextStyle(fontWeight:FontWeight.w700, fontSize:16, color:s.onSurface)),
                    const Spacer(), _SC(rating:_store['r']as double, s:s)]),
                  const SizedBox(height:4),
                  Text(_store['a']as String, style:TextStyle(fontSize:12, color:s.onSurfaceVariant)),
                ])),
                const SizedBox(width:10),
                Container(padding:const EdgeInsets.symmetric(horizontal:10, vertical:4), decoration:BoxDecoration(color:s.primaryContainer, borderRadius:BorderRadius.circular(12)),
                  child:Text('${_store['d']}m', style:TextStyle(color:s.primary, fontWeight:FontWeight.w700, fontSize:12))),
              ]))))))),

          //── AI 推荐标题 ──
          SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.fromLTRB(20,22,20,6), child:Row(children:[
            Container(width:4, height:20, decoration:BoxDecoration(color:s.primary, borderRadius:BorderRadius.circular(2))),
            const SizedBox(width:10),
            Icon(Icons.auto_awesome, size:20, color:s.primary), const SizedBox(width:6),
            Expanded(child:Text('AI 为你推荐', style:TextStyle(fontSize:18, fontWeight:FontWeight.w800, color:s.onSurface))),
            TextButton(onPressed:()=>Navigator.push(ctx, MaterialPageRoute(builder:(_)=>RecommendationPage(apiClient:widget.apiClient))), child:const Text('更多 >')),
          ]))),

          //── 商品瀑布流 3/4 列 + 淡入浮现 + 3D 微倾 ──
          SliverPadding(padding:const EdgeInsets.symmetric(horizontal:14), sliver:SliverLayoutBuilder(builder:(_, cstr) {
            final w = cstr.crossAxisExtent; final cols = w >= 600 ? 4 : 3; final r = cols == 4 ? 0.82 : 0.88;
            return SliverGrid(
              gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:cols, childAspectRatio:r, mainAxisSpacing:10, crossAxisSpacing:10),
              delegate:SliverChildBuilderDelegate((_, i) => _CardAppear(idx:i, visible:gridVisible, child:_card(_prods[i], s)), childCount:_prods.length),
            );
          })),
          const SliverToBoxAdapter(child:SizedBox(height:100)),
        ]),

        //── AI 悬浮球：滚动收起 ──
        Positioned(right:18, bottom:24, child:AnimatedSlide(
          duration:const Duration(milliseconds:400),
          curve:Curves.easeOutBack,
          offset:Offset(bubbleDx > 0 ? 1.6 : 0, 0),
          child:AnimatedBuilder(animation:_breathCtrl, builder:(_, c) => Transform.scale(scale:_breathAnim.value, child:c), child:GestureDetector(
            onTap:()=>Navigator.push(ctx, MaterialPageRoute(builder:(_)=>AiAssistantPage(apiClient:widget.apiClient))),
            child:Container(width:56, height:56, decoration:BoxDecoration(shape:BoxShape.circle, color:s.primary,
              boxShadow:[BoxShadow(color:s.primary.withAlpha(80), blurRadius:18, offset:const Offset(0,6))]),
              child:const Icon(Icons.smart_toy_rounded, color:Colors.white, size:28)),
          )),
        )),
      ]),
    );
  }

  // ── 商品卡片（含 3D 微倾） ──
  Widget _card(_P p, ColorScheme s) {
    return GestureDetector(onTap:(){}, child:Container(
      decoration:BoxDecoration(color:s.surfaceContainerLow, borderRadius:BorderRadius.circular(radiusCard),
        boxShadow:[BoxShadow(color:s.shadow.withAlpha(12), blurRadius:10, offset:const Offset(0,3))]),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        Expanded(flex:3, child:ClipRRect(borderRadius:const BorderRadius.vertical(top:Radius.circular(radiusCard)), child:Stack(children:[
          Container(decoration:BoxDecoration(gradient:LinearGradient(colors:[s.primaryContainer, s.secondaryContainer]))),
          Center(child:Text(p.e, style:const TextStyle(fontSize:36))),
          // 左上玻璃拟态推荐理由
          Positioned(left:8, top:8, child:ClipRRect(borderRadius:BorderRadius.circular(10), child:BackdropFilter(filter:ImageFilter.blur(sigmaX:6, sigmaY:6), child:Container(
            padding:const EdgeInsets.symmetric(horizontal:8, vertical:4),
            decoration:BoxDecoration(color:s.primary.withAlpha(100), borderRadius:BorderRadius.circular(10)),
            child:Row(mainAxisSize:MainAxisSize.min, children:[const Text('🐾', style:TextStyle(fontSize:10)), const SizedBox(width:3),
              Text(p.r, style:const TextStyle(fontSize:9, color:Colors.white, fontWeight:FontWeight.w500))])))),
          Positioned(right:6, bottom:6, child:_SC(rating:p.s, s:s, compact:true)),
        ]))),
        Expanded(flex:3, child:Padding(padding:const EdgeInsets.all(10), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
          Text(p.n, maxLines:2, overflow:TextOverflow.ellipsis, style:TextStyle(fontWeight:FontWeight.w600, fontSize:12, color:s.onSurface, height:1.2)),
          const Spacer(),
          Row(children:[
            Text('¥${p.p.toStringAsFixed(p.p==p.p.roundToDouble()?0:0)}', style:TextStyle(color:s.primary, fontWeight:FontWeight.w800, fontSize:14)),
            const Spacer(),
            Container(width:24, height:24, decoration:BoxDecoration(shape:BoxShape.circle, color:s.primaryContainer),
              child:Icon(Icons.add_shopping_cart_rounded, color:s.primary, size:14)),
          ]),
        ]))),
      ])));
  }
}

// ═══════════════════════════════════════════ 动画组件 ═══════════════════════════════════════════

/// 金刚区图标：Staggered easeOutBack 弹跳
class _CatBounce extends StatelessWidget {
  const _CatBounce({required this.index, required this.visible, required this.child});
  final int index; final bool visible; final Widget child;

  @override Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween:Tween(begin:0.0, end:visible?1.0:0.0),
      duration:Duration(milliseconds:500 + index * 80),
      curve:Curves.easeOutBack,
      builder:(_, v, c) => Transform.translate(offset:Offset(0, (1-v)*40), child:Opacity(opacity:v, child:c)),
    );
  }
}

/// 商品卡片：淡入 + 上滑 + 3D 微倾
class _CardAppear extends StatefulWidget {
  const _CardAppear({required this.idx, required this.visible, required this.child});
  final int idx; final bool visible; final Widget child;
  @override State<_CardAppear> createState() => _CardAppearState();
}

class _CardAppearState extends State<_CardAppear> with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slide;
  bool _shown = false;

  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync:this, duration:Duration(milliseconds:550 + widget.idx * 60));
    _slide = CurvedAnimation(parent:_ctrl, curve:Curves.easeOutCubic);
  }

  @override void didUpdateWidget(_CardAppear old) {
    super.didUpdateWidget(old);
    if (widget.visible && !_shown) { _ctrl.forward(); _shown = true; }
    else if (!widget.visible && _shown) { _ctrl.reverse(); _shown = false; }
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final val = _slide.value;
    final tilt = (1 - val) * 0.08; // 卡片从倾斜到扶正
    return AnimatedBuilder(
      animation:_slide,
      builder:(_, child) => Transform(
        alignment:Alignment.center,
        transform:Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(tilt),
        child: Transform.translate(offset:Offset(0, (1-val)*60), child:Opacity(opacity:val, child:widget.child)),
      ),
    );
  }
}

/// 图标按钮
class _IB extends StatelessWidget {
  const _IB({required this.icon, required this.s, this.badge=0, this.onTap});
  final IconData icon; final ColorScheme s; final int badge; final VoidCallback? onTap;
  @override Widget build(BuildContext c) => GestureDetector(onTap:onTap, child:Container(width:42, height:42,
    decoration:BoxDecoration(color:s.surfaceContainerLow, borderRadius:BorderRadius.circular(16)), child:Stack(children:[
    Center(child:Icon(icon, size:22, color:s.onSurface.withAlpha(140))),
    if(badge>0) Positioned(right:6, top:6, child:Container(width:16, height:16, decoration:const BoxDecoration(shape:BoxShape.circle, color:Colors.red),
      child:Center(child:Text('$badge', style:const TextStyle(color:Colors.white, fontSize:9, fontWeight:FontWeight.w700))))),
  ])));
}

/// 评分芯片
class _SC extends StatelessWidget {
  const _SC({required this.rating, required this.s, this.compact=false});
  final double rating; final ColorScheme s; final bool compact;
  @override Widget build(BuildContext c) => Container(padding:EdgeInsets.symmetric(horizontal:compact?5:7, vertical:compact?1:2),
    decoration:BoxDecoration(color:s.primaryContainer, borderRadius:BorderRadius.circular(compact?5:8)),
    child:Row(mainAxisSize:MainAxisSize.min, children:[Icon(Icons.star_rounded, size:compact?9:11, color:s.primary), const SizedBox(width:1),
      Text('$rating', style:TextStyle(fontSize:compact?9:11, fontWeight:FontWeight.w700, color:s.primary))]));
}
