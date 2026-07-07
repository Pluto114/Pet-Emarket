import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // 需要先运行: flutter pub add geolocator

import '../../../core/api/api_client.dart';
import '../../../core/session/session_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/product.dart';
import '../../../models/recommendation.dart';
import '../../../shared/widgets/toast.dart';
import '../ai_assistant/ai_assistant_page.dart';
import '../product/product_detail_page.dart';
import '../../merchant/register/merchant_register_page.dart';

const _banners = [
  {
    'title': 'PawMart',
    'sub': '为你的爱宠精选每一份好物',
    'color1': Color(0xFF7A8B3C),
    'color2': Color(0xFF3A441E),
  },
  {
    'title': '萌宠领养节',
    'sub': '新品活体上线，限时领券',
    'color1': Color(0xFF4C5A26),
    'color2': Color(0xFF2A3018),
  },
  {
    'title': '口粮狂欢',
    'sub': '满199减30，会员折上折',
    'color1': Color(0xFF93AE4E),
    'color2': Color(0xFF647430),
  },
];

class HomePage extends StatefulWidget {
  const HomePage({
    required this.apiClient,
    required this.sessionStore,
    this.onGoToMerchant,
    this.onNavigateToProducts,
    super.key,
  });
  final ApiClient apiClient;
  final SessionStore sessionStore;
  final VoidCallback? onGoToMerchant;
  final VoidCallback? onNavigateToProducts;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _pageCtrl = PageController();
  final ScrollController _scrollController = ScrollController();
  late final Timer _bannerTimer;

  // Feed Flow State
  List<RecommendationItem> feedItems = [];
  bool isLoadingFeed = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  int currentPage = 1;
  String? feedError;

  // Context Sensors
  String selectedCategory = '推荐'; // 默认推荐 Tab
  List<String> dynamicCategories = [];
  String _lastViewedId = '';
  double? _userLat;
  double? _userLng;

  int _bi = 0;

  List<String> get categories {
    return ['推荐', '附近', ...dynamicCategories];
  }

  @override
  void initState() {
    super.initState();
    _initDataFlow();

    _scrollController.addListener(_onScroll);

    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_pageCtrl.hasClients && mounted) {
        _pageCtrl.animateToPage(
          (_bi + 1) % _banners.length,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchFeed(refresh: false);
    }
  }

  Future<void> _initDataFlow() async {
    await _initLocation();
    _fetchCategoriesSilently();
    _fetchFeed(refresh: true);
  }

  // 1. 静默获取定位信息（用于附近推荐 LBS）
  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      _userLat = position.latitude;
      _userLng = position.longitude;
    } catch (e) {
      debugPrint('获取定位失败，降级为普通推荐: $e');
    }
  }

  // 2. 静默拉取分类列表
  Future<void> _fetchCategoriesSilently() async {
    try {
      final allProducts = await widget.apiClient.listProducts();
      final cats =
          allProducts
              .map((product) => product.category.trim())
              .where((cat) => cat.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      if (mounted) {
        setState(() => dynamicCategories = cats);
      }
    } catch (_) {}
  }

  // 3. 核心：加载智能推荐信息流
  Future<void> _fetchFeed({bool refresh = false}) async {
    if (refresh) {
      currentPage = 1;
      hasMore = true;
      if (mounted)
        setState(() {
          isLoadingFeed = true;
          feedError = null;
        });
    } else {
      if (!hasMore || isLoadingMore) return;
      if (mounted) setState(() => isLoadingMore = true);
      currentPage++;
    }

    String scene = 'HOME';
    String queryCat = '';

    if (selectedCategory == '附近') {
      scene = 'NEARBY';
    } else if (selectedCategory != '推荐') {
      queryCat = selectedCategory;
    }

    try {
      final items = await widget.apiClient.recommendations(
        scene: scene,
        category: queryCat,
        page: currentPage,
        limit: 10,
        longitude: _userLng,
        latitude: _userLat,
        lastProductId: _lastViewedId, // 激活马尔可夫链上下文
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            feedItems = items;
          } else {
            feedItems.addAll(items);
          }
          hasMore = items.length >= 10;
          isLoadingFeed = false;
          isLoadingMore = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          feedError = error.toString();
          isLoadingFeed = false;
          isLoadingMore = false;
        });
      }
    }
  }

  void _onCategorySelected(String category) {
    if (selectedCategory == category) return;
    setState(() {
      selectedCategory = category;
    });
    // 切换 Tab 时重置列表并刷新请求
    _fetchFeed(refresh: true);
  }

  void _showCategorySearch(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (ctx) {
        final controller = TextEditingController();
        String filterText = '';
        return StatefulBuilder(
          builder:
              (ctx, setDialogState) => AlertDialog(
                title: const Text('搜索分类'),
                content: SizedBox(
                  width: 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: '输入分类名称…',
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: PawmartColors.neutral400,
                          ),
                        ),
                        onChanged: (v) => setDialogState(() => filterText = v),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: ListView(
                          children:
                              categories
                                  .where(
                                    (c) =>
                                        filterText.isEmpty ||
                                        c.contains(filterText),
                                  )
                                  .map(
                                    (c) => ListTile(
                                      dense: true,
                                      title: Text(c),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        _onCategorySelected(c);
                                      },
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('取消'),
                  ),
                ],
              ),
        );
      },
    );
  }

  String get _sectionTitle {
    if (selectedCategory == '推荐') return '猜你喜欢';
    if (selectedCategory == '附近') return '附近精选';
    if (selectedCategory.length > 6)
      return '${selectedCategory.substring(0, 6)}… · 精选';
    return '$selectedCategory · 精选';
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _bannerTimer.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final w = MediaQuery.of(ctx).size.width;
    final wide = w > 800;

    return Scaffold(
      backgroundColor: PawmartColors.surfaceBg,
      body: RefreshIndicator(
        onRefresh: () => _fetchFeed(refresh: true),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // ════════ Hero Banner (Full Width) ════════
            SliverToBoxAdapter(
              child: SizedBox(
                height: wide ? 300 : 220,
                child: Stack(
                  children: [
                    PageView.builder(
                      physics: const BouncingScrollPhysics(),
                      controller: _pageCtrl,
                      onPageChanged: (i) => setState(() => _bi = i),
                      itemCount: _banners.length,
                      itemBuilder: (_, i) {
                        final b = _banners[i];
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                b['color1'] as Color,
                                b['color2'] as Color,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -40,
                                top: -40,
                                child: Opacity(
                                  opacity: 0.12,
                                  child: Icon(
                                    Icons.pets,
                                    size: 240,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  wide ? 40 : 20,
                                  20,
                                  wide ? 40 : 20,
                                  20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      b['title'] as String,
                                      style: TextStyle(
                                        fontSize: wide ? 36 : 28,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        height: 1.15,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      b['sub'] as String,
                                      style: TextStyle(
                                        fontSize: wide ? 17 : 15,
                                        color: Colors.white.withAlpha(230),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      height: 42,
                                      child: FilledButton(
                                        onPressed: () {
                                          widget.onNavigateToProducts?.call();
                                        },
                                        style: FilledButton.styleFrom(
                                          backgroundColor:
                                              PawmartColors.accent400,
                                          foregroundColor:
                                              PawmartColors.textOnAccent,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 28,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              pawmartRadiusFull,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          '立即选购',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Positioned(
                      right: 20,
                      bottom: 20,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(_banners.length, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _bi == i ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color:
                                  _bi == i
                                      ? Colors.white
                                      : Colors.white.withAlpha(90),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ════════ Category Chips + Search ════════
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                decoration: BoxDecoration(
                  color: PawmartColors.neutral50,
                  border: Border(
                    bottom: BorderSide(color: PawmartColors.neutral200),
                  ),
                ),
                child: Row(
                  children: [
                    // Category chips (scrollable with visible scrollbar)
                    Expanded(
                      child: Scrollbar(
                        thumbVisibility: true,
                        thickness: 4,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.only(left: wide ? 40 : 16),
                          child: Row(
                            children: [
                              for (final label in categories)
                                _categoryChip(label, selectedCategory == label),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Compact search
                    Container(
                      width: 36,
                      height: 36,
                      margin: EdgeInsets.only(right: wide ? 40 : 12, left: 8),
                      decoration: BoxDecoration(
                        color: PawmartColors.surfaceCard,
                        borderRadius: BorderRadius.circular(pawmartRadiusFull),
                        border: Border.all(color: PawmartColors.neutral200),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.search_rounded, size: 18),
                        color: PawmartColors.textSecondary,
                        padding: EdgeInsets.zero,
                        onPressed: () => _showCategorySearch(ctx),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ════════ Merchant Center Entry ════════
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  wide ? 40 : 16,
                  18,
                  wide ? 40 : 16,
                  0,
                ),
                child: _buildMerchantCenterCard(ctx),
              ),
            ),

            // ════════ Feed Section Header ════════
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  wide ? 40 : 16,
                  24,
                  wide ? 40 : 16,
                  8,
                ),
                child: pawmartSectionHeader(
                  _sectionTitle,
                  actionLabel: '查看全部',
                  onAction: () => widget.onNavigateToProducts?.call(),
                ),
              ),
            ),

            // ════════ Feed Content (Infinite Scroll Grid) ════════
            if (isLoadingFeed)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (feedError != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 16),
                  child: Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.error_outline,
                        color: PawmartColors.error,
                      ),
                      title: Text(feedError!),
                      trailing: TextButton(
                        onPressed: () => _fetchFeed(refresh: true),
                        child: const Text('重试'),
                      ),
                    ),
                  ),
                ),
              )
            else if (feedItems.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 16),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: PawmartColors.surfaceCard,
                      borderRadius: BorderRadius.circular(pawmartRadiusMd),
                      boxShadow: pawmartShadow1,
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: PawmartColors.neutral300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '暂无推荐商品，请稍后再来',
                            style: TextStyle(
                              fontSize: 15,
                              color: PawmartColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: wide ? 150 : 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    childAspectRatio: 1.1, // 可根据商品标签高度适当微调
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _recommendationCard(feedItems[i]),
                    childCount: feedItems.length,
                  ),
                ),
              ),

            // ════════ Load More Indicator ════════
            if (isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),

            // ════════ Brand Promise Section ════════
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  wide ? 40 : 16,
                  36,
                  wide ? 40 : 16,
                  36,
                ),
                child: LayoutBuilder(
                  builder: (_, constraints) {
                    final isCompact = constraints.maxWidth < 500;
                    if (isCompact) {
                      return Wrap(
                        spacing: 16,
                        runSpacing: 20,
                        alignment: WrapAlignment.spaceAround,
                        children: [
                          _brandPromise(
                            Icons.verified_user_outlined,
                            '正品保障',
                            '全球品牌授权，假一赔十',
                          ),
                          _brandPromise(
                            Icons.local_shipping_outlined,
                            '极速配送',
                            '全国主要城市次日达',
                          ),
                          _brandPromise(
                            Icons.replay_outlined,
                            '7天无理由',
                            '不满意随时退换货',
                          ),
                          _brandPromise(
                            Icons.headset_mic_outlined,
                            '专属客服',
                            '7x24小时在线咨询',
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        _brandPromise(
                          Icons.verified_user_outlined,
                          '正品保障',
                          '全球品牌授权，假一赔十',
                        ),
                        const SizedBox(width: 12),
                        _brandPromise(
                          Icons.local_shipping_outlined,
                          '极速配送',
                          '全国主要城市次日达',
                        ),
                        const SizedBox(width: 12),
                        _brandPromise(
                          Icons.replay_outlined,
                          '7天无理由',
                          '不满意随时退换货',
                        ),
                        const SizedBox(width: 12),
                        _brandPromise(
                          Icons.headset_mic_outlined,
                          '专属客服',
                          '7x24小时在线咨询',
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // ════════ Footer ════════
            SliverToBoxAdapter(
              child: Container(
                color: PawmartColors.neutral900,
                padding: EdgeInsets.fromLTRB(
                  wide ? 40 : 24,
                  40,
                  wide ? 40 : 24,
                  24,
                ),
                child: LayoutBuilder(
                  builder: (_, constraints) {
                    final isNarrow = constraints.maxWidth < 500;
                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _footerColumn('关于PawMart', ['品牌故事', '加入我们', '联系客服']),
                          const SizedBox(height: 24),
                          _footerColumn('购物指南', ['新手指南', '支付方式', '配送说明']),
                          const SizedBox(height: 24),
                          _footerColumn('客户服务', ['退换政策', '售后保障', '常见问题']),
                          const SizedBox(height: 24),
                          _footerColumn('关注我们', ['微信公众号', '微博', '小红书']),
                          const SizedBox(height: 28),
                          _footerBottom(),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _footerColumn('关于PawMart', [
                                '品牌故事',
                                '加入我们',
                                '联系客服',
                              ]),
                            ),
                            Expanded(
                              child: _footerColumn('购物指南', [
                                '新手指南',
                                '支付方式',
                                '配送说明',
                              ]),
                            ),
                            Expanded(
                              child: _footerColumn('客户服务', [
                                '退换政策',
                                '售后保障',
                                '常见问题',
                              ]),
                            ),
                            Expanded(
                              child: _footerColumn('关注我们', [
                                '微信公众号',
                                '微博',
                                '小红书',
                              ]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        _footerBottom(),
                      ],
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => AiAssistantPage(apiClient: widget.apiClient),
              ),
            ),
        child: const Icon(Icons.smart_toy_rounded),
      ),
    );
  }

  // ——— Merchant Center Card ———
  Widget _buildMerchantCenterCard(BuildContext ctx) {
    final isMerchant = widget.sessionStore.isMerchant;
    return GestureDetector(
      onTap: () {
        if (isMerchant) {
          widget.onGoToMerchant?.call();
        } else {
          Navigator.push(
            ctx,
            MaterialPageRoute(
              builder:
                  (_) => MerchantRegisterPage(
                    apiClient: widget.apiClient,
                    sessionStore: widget.sessionStore,
                  ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                isMerchant
                    ? [PawmartColors.primary400, PawmartColors.primary600]
                    : [PawmartColors.neutral100, PawmartColors.neutral200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(pawmartRadiusLg),
          boxShadow: pawmartShadow1,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    isMerchant
                        ? Colors.white.withAlpha(40)
                        : PawmartColors.primary50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.storefront_rounded,
                size: 26,
                color: isMerchant ? Colors.white : PawmartColors.primary500,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMerchant ? '商家中心' : '成为商家',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color:
                          isMerchant ? Colors.white : PawmartColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isMerchant ? '管理你的店铺和商品' : '开启你的宠物事业',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isMerchant
                              ? Colors.white.withAlpha(200)
                              : PawmartColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color:
                  isMerchant
                      ? Colors.white.withAlpha(200)
                      : PawmartColors.primary500,
            ),
          ],
        ),
      ),
    );
  }

  // ——— Category Chip ———
  Widget _categoryChip(String label, bool active) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(pawmartRadiusFull),
        onTap: () => _onCategorySelected(label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: active ? PawmartColors.accent400 : PawmartColors.neutral100,
            borderRadius: BorderRadius.circular(pawmartRadiusFull),
            boxShadow: active ? pawmartShadow1 : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color:
                  active
                      ? PawmartColors.textOnAccent
                      : PawmartColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  // ——— Recommendation Card (Upgraded from Product Card) ———
  Widget _recommendationCard(RecommendationItem item) {
    final product = item.product;
    final colors = [
      PawmartColors.primary100,
      PawmartColors.accent50,
      PawmartColors.neutral100,
      PawmartColors.primary50,
    ];
    final isOos = product.stock <= 0;

    return InkWell(
      borderRadius: BorderRadius.circular(pawmartRadiusMd),
      onTap: () {
        // 记录用户最新点击的商品ID，用于触发马尔可夫链上下文推荐
        _lastViewedId = product.id.toString();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => ProductDetailPage(
                  product: product,
                  apiClient: widget.apiClient,
                ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: PawmartColors.surfaceCard,
          borderRadius: BorderRadius.circular(pawmartRadiusMd),
          boxShadow: pawmartShadow1,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image area
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color:
                      colors[product.category.hashCode.abs() % colors.length],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (product.coverUrl.isNotEmpty)
                      Image.network(
                        product.coverUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _productIcon(product),
                      )
                    else
                      _productIcon(product),
                    if (isOos)
                      Container(
                        color: Colors.black.withAlpha(80),
                        alignment: Alignment.center,
                        child: const Text(
                          '售罄',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Product info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: PawmartColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '¥${product.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: PawmartColors.primary500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // 高级推荐引擎返回的理由标签 (Tag)
                      if (item.reasons.isNotEmpty)
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 1),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: PawmartColors.primary50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.reasons.first,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                color: PawmartColors.primary600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                      GestureDetector(
                        onTap: isOos ? null : () => _addProductToCart(product),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color:
                                isOos
                                    ? PawmartColors.neutral300
                                    : PawmartColors.accent400,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            isOos ? Icons.block : Icons.add,
                            size: 16,
                            color:
                                isOos
                                    ? PawmartColors.neutral400
                                    : PawmartColors.textOnAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productIcon(Product product) {
    return Center(
      child: Icon(
        product.isLivePet ? Icons.pets : Icons.shopping_bag_outlined,
        size: 40,
        color: PawmartColors.primary400,
      ),
    );
  }

  Future<void> _addProductToCart(Product product) async {
    try {
      await widget.apiClient.addCartItem(productId: product.id, quantity: 1);
      if (mounted) showSuccess(context, '${product.name} 已加入购物车');
    } catch (error) {
      if (mounted) showError(context, error.toString());
    }
  }

  // ——— Brand Promise Item ———
  Widget _brandPromise(IconData icon, String title, String sub) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: PawmartColors.primary50,
              borderRadius: BorderRadius.circular(pawmartRadiusFull),
            ),
            child: Icon(icon, size: 24, color: PawmartColors.primary500),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: PawmartColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: TextStyle(fontSize: 12, color: PawmartColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _footerColumn(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              item,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withAlpha(180),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _footerBottom() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 1,
          color: Colors.white.withAlpha(25),
        ),
        const SizedBox(height: 16),
        Text(
          '© 2026 PawMart 宠物商城',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(130)),
        ),
      ],
    );
  }
}
