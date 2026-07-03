import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/product.dart';
import '../../../shared/widgets/toast.dart';
import '../ai_assistant/ai_assistant_page.dart';
import '../product/product_detail_page.dart';
import '../recommendation/recommendation_page.dart';
import '../../merchant/register/merchant_register_page.dart';

const _banners = [
  {'title': '萌宠领养节', 'sub': '新品活体上线，限时领券', 'emoji': '🐶'},
  {'title': '医疗体检季', 'sub': '到店即享免费基础体检', 'emoji': '💊'},
  {'title': '口粮狂欢', 'sub': '满199减30，会员折上折', 'emoji': '🦴'},
];

class HomePage extends StatefulWidget {
  const HomePage({
    required this.apiClient,
    required this.sessionStore,
    this.onGoToMerchant,
    super.key,
  });
  final ApiClient apiClient;
  final SessionStore sessionStore;
  final VoidCallback? onGoToMerchant;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _pageCtrl = PageController();
  late final Timer _bannerTimer;
  bool loadingProducts = true;
  String? productError;
  String selectedCategory = '全部';
  List<Product> allProducts = [];
  List<Product> products = [];
  int _bi = 0;

  List<String> get categories {
    final values =
        allProducts
            .map((product) => product.category.trim())
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return ['全部', ...values];
  }

  @override
  void initState() {
    super.initState();
    loadProducts();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_pageCtrl.hasClients && mounted) {
        _pageCtrl.animateToPage(
          (_bi + 1) % _banners.length,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> loadProducts() async {
    setState(() {
      loadingProducts = true;
      productError = null;
    });
    try {
      allProducts = await widget.apiClient.listProducts();
      if (selectedCategory != '全部' &&
          !allProducts.any((product) => product.category == selectedCategory)) {
        selectedCategory = '全部';
      }
      _applyCategoryFilter();
    } catch (error) {
      productError = error.toString();
    } finally {
      if (mounted) setState(() => loadingProducts = false);
    }
  }

  void _applyCategoryFilter() {
    products =
        selectedCategory == '全部'
            ? List<Product>.from(allProducts)
            : allProducts
                .where((product) => product.category == selectedCategory)
                .toList();
  }

  @override
  void dispose() {
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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ——— Category Chips ———
          SliverToBoxAdapter(
            child: Container(
              color: PawmartColors.neutral50,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 16),
                child: Row(
                  children: [
                    for (final label in categories)
                      _categoryChip(label, selectedCategory == label),
                  ],
                ),
              ),
            ),
          ),

          // ——— Banner Carousel ———
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                wide ? 40 : 16,
                16,
                wide ? 40 : 16,
                8,
              ),
              child: SizedBox(
                height: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(pawmartRadiusLg),
                  child: Stack(
                    children: [
                      PageView.builder(
                        physics: const BouncingScrollPhysics(),
                        controller: _pageCtrl,
                        onPageChanged: (i) => setState(() => _bi = i),
                        itemCount: _banners.length,
                        itemBuilder: (_, i) {
                          final b = _banners[i];
                          final colors = [
                            [
                              PawmartColors.primary400,
                              PawmartColors.primary600,
                            ],
                            [PawmartColors.accent300, PawmartColors.accent500],
                            [
                              PawmartColors.primary300,
                              PawmartColors.primary700,
                            ],
                          ];
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: colors[i],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  right: 20,
                                  top: -10,
                                  child: Text(
                                    b['emoji'] as String,
                                    style: const TextStyle(fontSize: 80),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        b['title'] as String,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        b['sub'] as String,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white.withAlpha(200),
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
                        right: 12,
                        bottom: 12,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(_banners.length, (i) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              width: _bi == i ? 16 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                color:
                                    _bi == i
                                        ? Colors.white
                                        : Colors.white.withAlpha(100),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ——— Merchant Center Entry ———
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                wide ? 40 : 16,
                12,
                wide ? 40 : 16,
                4,
              ),
              child: _buildMerchantCenterCard(ctx),
            ),
          ),

          // ——— New Arrivals Section ———
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                wide ? 40 : 16,
                16,
                wide ? 40 : 16,
                4,
              ),
              child: pawmartSectionHeader('新品上市', actionLabel: '查看全部'),
            ),
          ),

          if (loadingProducts)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (productError != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 16),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.error_outline),
                    title: Text(productError!),
                    trailing: TextButton(
                      onPressed: loadProducts,
                      child: const Text('重试'),
                    ),
                  ),
                ),
              ),
            )
          else if (products.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 16),
                child: const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('暂无商品，请稍后再来。'),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: wide ? 36 : 12),
              sliver: SliverLayoutBuilder(
                builder: (_, cstr) {
                  final cw = cstr.crossAxisExtent;
                  final cols = cw >= 600 ? 4 : (cw >= 400 ? 3 : 2);
                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      childAspectRatio: 0.62,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _productCard(products[i]),
                      childCount: products.length,
                    ),
                  );
                },
              ),
            ),

          // ——— AI Recommendation Section ———
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.only(top: 24),
              padding: EdgeInsets.fromLTRB(
                wide ? 40 : 16,
                28,
                wide ? 40 : 16,
                24,
              ),
              color: PawmartColors.neutral50,
              child: Column(
                children: [
                  pawmartSectionHeader('AI 为你推荐'),
                  const SizedBox(height: 16),
                  Text(
                    '根据宠物品种和年龄，为你精选最适合的商品',
                    style: TextStyle(
                      fontSize: 14,
                      color: PawmartColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 3 feature cards
                  Row(
                    children: [
                      _featureCard(Icons.pets, '按品种推荐', '金毛、柯基、布偶…不同品种有不同营养需求'),
                      const SizedBox(width: 12),
                      _featureCard(
                        Icons.schedule,
                        '按年龄推荐',
                        '幼犬、成犬、老年犬，智能匹配生长周期',
                      ),
                      const SizedBox(width: 12),
                      _featureCard(
                        Icons.favorite_outline,
                        '按健康需求',
                        '肠胃敏感、关节养护、毛发亮泽专属方案',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 46,
                    child: FilledButton(
                      onPressed:
                          () => Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder:
                                  (_) => RecommendationPage(
                                    apiClient: widget.apiClient,
                                  ),
                            ),
                          ),
                      style: FilledButton.styleFrom(
                        backgroundColor: PawmartColors.accent400,
                        foregroundColor: PawmartColors.textOnAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                      ),
                      child: Text(
                        '开始智能推荐',
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
          ),

          // ——— Brand Promise Section ———
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                wide ? 40 : 16,
                32,
                wide ? 40 : 16,
                32,
              ),
              child: Row(
                children: [
                  _brandPromise(Icons.shield_outlined, '正品保障', '假一赔十'),
                  const SizedBox(width: 12),
                  _brandPromise(
                    Icons.local_shipping_outlined,
                    '极速配送',
                    '主要城市次日达',
                  ),
                  const SizedBox(width: 12),
                  _brandPromise(Icons.replay_outlined, '7天无理由', '不满意随时退换'),
                  const SizedBox(width: 12),
                  _brandPromise(
                    Icons.support_agent_outlined,
                    '专属客服',
                    '7x24小时在线',
                  ),
                ],
              ),
            ),
          ),

          // ——— Footer ———
          SliverToBoxAdapter(
            child: Container(
              color: PawmartColors.neutral900,
              padding: EdgeInsets.fromLTRB(
                wide ? 40 : 24,
                32,
                wide ? 40 : 24,
                24,
              ),
              child: Column(
                children: [
                  Text(
                    'PawMart 宠物商城',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 20,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _footerLink('关于我们'),
                      _footerLink('联系客服'),
                      _footerLink('隐私政策'),
                      _footerLink('用户协议'),
                      _footerLink('帮助中心'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '© 2026 PawMart. 保留所有权利。',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withAlpha(130),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
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
        padding: const EdgeInsets.all(20),
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
                color: (isMerchant ? Colors.white : PawmartColors.primary500)
                    .withAlpha(40),
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
        onTap: () {
          if (selectedCategory == label) return;
          setState(() {
            selectedCategory = label;
            _applyCategoryFilter();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: active ? PawmartColors.accent400 : PawmartColors.neutral100,
            borderRadius: BorderRadius.circular(pawmartRadiusFull),
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

  // ——— Product Card ———
  Widget _productCard(Product product) {
    final colors = [
      PawmartColors.primary100,
      PawmartColors.accent50,
      PawmartColors.neutral100,
      PawmartColors.primary50,
    ];
    return InkWell(
      borderRadius: BorderRadius.circular(pawmartRadiusMd),
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => ProductDetailPage(
                    product: product,
                    apiClient: widget.apiClient,
                  ),
            ),
          ),
      child: Container(
        decoration: BoxDecoration(
          color: PawmartColors.surfaceCard,
          borderRadius: BorderRadius.circular(pawmartRadiusMd),
          boxShadow: pawmartShadow1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: colors[product.category.hashCode.abs() % colors.length],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(pawmartRadiusMd),
                ),
              ),
              child:
                  product.coverUrl.isNotEmpty
                      ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(pawmartRadiusMd),
                        ),
                        child: Image.network(
                          product.coverUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => _productIcon(product),
                        ),
                      )
                      : _productIcon(product),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: PawmartColors.primary50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: PawmartColors.primary600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      height: 1.2,
                      color: PawmartColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description.isEmpty
                        ? '商家暂未填写简介'
                        : product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.25,
                      color: PawmartColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '库存 ${product.stock}',
                    style: TextStyle(
                      fontSize: 11,
                      color: PawmartColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '¥${product.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: PawmartColors.primary500,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        borderRadius: BorderRadius.circular(pawmartRadiusFull),
                        onTap:
                            product.stock > 0
                                ? () => _addProductToCart(product)
                                : null,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color:
                                product.stock > 0
                                    ? PawmartColors.accent400
                                    : PawmartColors.neutral200,
                            borderRadius: BorderRadius.circular(
                              pawmartRadiusFull,
                            ),
                          ),
                          child: const Icon(
                            Icons.add_shopping_cart_rounded,
                            size: 14,
                            color: PawmartColors.textOnAccent,
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
        size: 36,
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

  // ——— Feature Card ———
  Widget _featureCard(IconData icon, String title, String desc) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PawmartColors.surfaceCard,
          borderRadius: BorderRadius.circular(pawmartRadiusMd),
          border: Border.all(color: PawmartColors.neutral200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: PawmartColors.primary50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: PawmartColors.primary500),
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
              desc,
              style: TextStyle(
                fontSize: 12,
                color: PawmartColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ——— Brand Promise Item ———
  Widget _brandPromise(IconData icon, String title, String sub) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: PawmartColors.primary50,
              borderRadius: BorderRadius.circular(pawmartRadiusFull),
            ),
            child: Icon(icon, size: 20, color: PawmartColors.primary500),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: PawmartColors.textPrimary,
            ),
          ),
          Text(
            sub,
            style: TextStyle(fontSize: 11, color: PawmartColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(180)),
    );
  }
}
