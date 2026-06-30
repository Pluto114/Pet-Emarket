/// 首页 — 纯内容 · Banner + Bento · 商品流 · 无顶栏
library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/session/session_store.dart';
import '../../../../core/theme/app_theme.dart' show radiusCard;
import '../ai_assistant/ai_assistant_page.dart';
import '../recommendation/recommendation_page.dart';

const _banners=[
  {'title':'萌宠领养节','sub':'新品活体上线，限时领券','emoji':'🐶','img':'https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=600&h=340&fit=crop'},
  {'title':'医疗体检季','sub':'到店即享免费基础体检','emoji':'💊','img':'https://images.unsplash.com/photo-1530041539825-403b3b39c5b1?w=600&h=340&fit=crop'},
  {'title':'口粮狂欢','sub':'满199减30，会员折上折','emoji':'🦴','img':'https://images.unsplash.com/photo-1583511655783-fb0ee6510a9d?w=600&h=340&fit=crop'},
];
final _bentoProds=[
  _P('英短蓝猫','3月龄',3800,4.9,'https://images.unsplash.com/photo-1592194996308-7b43878e84a6?w=200&h=200&fit=crop','活体'),
  _P('皇家幼猫粮','2kg',168,4.7,'https://images.unsplash.com/photo-1589924691995-5d0e6f1aaa3a?w=200&h=200&fit=crop','口粮'),
  _P('全自动猫砂盆','爆款',599,4.6,'https://images.unsplash.com/photo-1589241541754-3f03413de6f7?w=200&h=200&fit=crop','用品'),
  _P('金毛幼犬','2月龄',2500,4.8,'https://images.unsplash.com/photo-1552053831-71594a27632d?w=200&h=200&fit=crop','活体'),
];
final _prods=[
  _P('英短蓝猫','3月龄',3800,4.9,'https://images.unsplash.com/photo-1592194996308-7b43878e84a6?w=400&h=400&fit=crop','活体'),
  _P('皇家幼猫粮','2kg',168,4.7,'https://images.unsplash.com/photo-1589924691995-5d0e6f1aaa3a?w=400&h=400&fit=crop','口粮'),
  _P('全自动猫砂盆','爆款',599,4.6,'https://images.unsplash.com/photo-1589241541754-3f03413de6f7?w=400&h=400&fit=crop','用品'),
  _P('金毛幼犬','2月龄',2500,4.8,'https://images.unsplash.com/photo-1552053831-71594a27632d?w=400&h=400&fit=crop','活体'),
  _P('磨牙棒套装','50g',49,4.5,'https://images.unsplash.com/photo-1601758228041-9643e6cbaeb0?w=400&h=400&fit=crop','零食'),
  _P('布偶猫宝宝','4月龄',5200,5.0,'https://images.unsplash.com/photo-1513360371669-4adf3dd7dff8?w=400&h=400&fit=crop','活体'),
  _P('宠物益生菌','30粒',89,4.4,'https://images.unsplash.com/photo-1583947215259-38e31be8751f?w=400&h=400&fit=crop','保健'),
  _P('实木猫爬架','豪华款',799,4.8,'https://images.unsplash.com/photo-1583511655783-fb0ee6510a9d?w=400&h=400&fit=crop','用品'),
  _P('狗狗飞盘','标准',35,4.3,'https://images.unsplash.com/photo-1576201836106-db1758fd1c97?w=400&h=400&fit=crop','玩具'),
];
class _P{final String n,sub,img,t;final double p,s;const _P(this.n,this.sub,this.p,this.s,this.img,this.t);}

class HomePage extends StatefulWidget {
  const HomePage({required this.apiClient,required this.sessionStore,super.key});
  final ApiClient apiClient;final SessionStore sessionStore;
  @override State<HomePage> createState()=>_HS();
}

class _HS extends State<HomePage> {
  final _pageCtrl=PageController();
  late final Timer _bannerTimer;
  int _bi=0;

  @override void initState(){
    super.initState();
    _bannerTimer=Timer.periodic(const Duration(seconds:4),(_){
      if(_pageCtrl.hasClients&&mounted) _pageCtrl.animateToPage((_bi+1)%_banners.length,duration:const Duration(milliseconds:500),curve:Curves.easeInOut);
    });
  }
  @override void dispose(){_bannerTimer.cancel();_pageCtrl.dispose();super.dispose();}

  @override Widget build(BuildContext ctx){
    final t=Theme.of(ctx);final s=t.colorScheme;final u=widget.sessionStore.user;
    final w=MediaQuery.of(ctx).size.width;final wide=w>800;

    return Scaffold(
      backgroundColor:s.surface,
      body:CustomScrollView(physics:const BouncingScrollPhysics(),slivers:[
        // Welcome
        SliverToBoxAdapter(child:Padding(padding:EdgeInsets.fromLTRB(wide?40:20,20,wide?40:20,16),child:Row(children:[
          CircleAvatar(radius:22,backgroundColor:s.primaryContainer,child:Text(u!=null&&u.displayName.isNotEmpty?u.displayName[0].toUpperCase():'🐾',style:const TextStyle(fontSize:18))),
          const SizedBox(width:10),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(u!=null?'Hi, ${u.displayName}～':'Hi, 铲屎官～',style:TextStyle(fontWeight:FontWeight.w700,fontSize:16,color:s.onSurface)),
            Text(u!=null?'${u.memberLevel} · 今天想为毛孩子添点什么？':'今天想为毛孩子添点什么？',style:TextStyle(fontSize:12,color:s.onSurfaceVariant)),
          ])),
        ]))),

        // Bento: 左轮播 + 右 2x2
        SliverToBoxAdapter(child:Padding(padding:EdgeInsets.symmetric(horizontal:wide?40:14),child:ConstrainedBox(
          constraints:const BoxConstraints(maxHeight:324),
          child:Row(children:[
            Expanded(flex:2,child:ClipRRect(borderRadius:BorderRadius.circular(radiusCard),child:Stack(children:[
              PageView.builder(
                physics:const BouncingScrollPhysics(),controller:_pageCtrl,onPageChanged:(i)=>setState(()=>_bi=i),itemCount:_banners.length,
                itemBuilder:(_,i){final b=_banners[i];
                  return Stack(children:[
                    Positioned.fill(child:Image.network(b['img']as String,fit:BoxFit.cover,errorBuilder:(_,__,___)=>Container(decoration:BoxDecoration(gradient:LinearGradient(colors:[s.primaryContainer,s.secondaryContainer],begin:Alignment.topLeft,end:Alignment.bottomRight))))),
                    Positioned.fill(child:Container(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Colors.black.withAlpha(60),Colors.transparent])))),
                    Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[
                      Text(b['title']as String,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800,color:Colors.white,shadows:[Shadow(color:Colors.black26,blurRadius:4)])),
                      const SizedBox(height:4),
                      Text(b['sub']as String,style:const TextStyle(fontSize:12,color:Colors.white70,shadows:[Shadow(color:Colors.black26,blurRadius:4)])),
                    ])),
                  ]);
                },
              ),
              Positioned(right:10,bottom:10,child:Row(mainAxisSize:MainAxisSize.min,children:List.generate(_banners.length,(i)=>AnimatedContainer(
                duration:const Duration(milliseconds:200),margin:const EdgeInsets.symmetric(horizontal:2),width:_bi==i?12:5,height:5,
                decoration:BoxDecoration(borderRadius:BorderRadius.circular(3),color:_bi==i?s.primary:s.primary.withAlpha(80)))))),
            ]))),
            const SizedBox(width:10),
            Expanded(flex:3,child:GridView.builder(
              physics:const NeverScrollableScrollPhysics(),
              gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,childAspectRatio:1.5,mainAxisSpacing:8,crossAxisSpacing:8),
              itemCount:4,itemBuilder:(_,i)=>_bentoCard(_bentoProds[i],s),
            )),
          ]),
        ))),

        // AI推荐
        SliverToBoxAdapter(child:Padding(padding:EdgeInsets.fromLTRB(wide?40:20,24,wide?40:20,8),child:Row(children:[
          Container(width:4,height:20,decoration:BoxDecoration(color:s.primary,borderRadius:BorderRadius.circular(2))),
          const SizedBox(width:10),
          Icon(Icons.auto_awesome,size:20,color:s.primary),const SizedBox(width:6),
          Expanded(child:Text('AI 为你推荐',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800,color:s.onSurface))),
          TextButton(onPressed:()=>Navigator.push(ctx,MaterialPageRoute(builder:(_)=>RecommendationPage(apiClient:widget.apiClient))),child:const Text('更多 >')),
        ]))),

        // 商品网格
        SliverPadding(padding:EdgeInsets.symmetric(horizontal:wide?36:10),sliver:SliverLayoutBuilder(builder:(_,cstr){
          final cw=cstr.crossAxisExtent;final cols=cw>=600?4:3;
          return SliverGrid(
            gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:cols,childAspectRatio:0.72,mainAxisSpacing:12,crossAxisSpacing:12),
            delegate:SliverChildBuilderDelegate((_,i)=>AspectRatio(aspectRatio:0.72,child:_card(_prods[i%_prods.length],s)),childCount:9),
          );
        })),
        const SliverToBoxAdapter(child:SizedBox(height:100)),
      ]),
      floatingActionButton:FloatingActionButton(
        onPressed:()=>Navigator.push(ctx,MaterialPageRoute(builder:(_)=>AiAssistantPage(apiClient:widget.apiClient))),
        backgroundColor:s.primary,shape:const CircleBorder(),child:const Icon(Icons.smart_toy_rounded,color:Colors.white),
      ),
    );
  }

  Widget _bentoCard(_P p,ColorScheme s)=>Card(
    elevation:0,color:s.surfaceContainerHighest.withAlpha(80),
    shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)),
    margin:EdgeInsets.zero,
    child:Padding(padding:const EdgeInsets.all(12),child:Row(children:[
      ClipRRect(borderRadius:BorderRadius.circular(12),child:SizedBox(width:85,height:85,child:_productImage(p.img))),
      const SizedBox(width:12),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
        Container(padding:const EdgeInsets.symmetric(horizontal:6,vertical:2),decoration:BoxDecoration(color:s.primary.withAlpha(25),borderRadius:BorderRadius.circular(6)),
          child:Text('${p.t} · ${p.sub}',style:TextStyle(fontSize:10,fontWeight:FontWeight.w500,color:s.primary))),
        Text(p.n,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:13,fontWeight:FontWeight.bold,color:s.onSurface)),
        Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
          Text('¥${p.p.toStringAsFixed(0)}',style:TextStyle(fontSize:14,fontWeight:FontWeight.bold,color:s.primary)),
          Container(padding:const EdgeInsets.all(4),decoration:BoxDecoration(color:s.primary.withAlpha(25),shape:BoxShape.circle),child:Icon(Icons.add_shopping_cart,size:16,color:s.primary)),
        ]),
      ])),
    ])));

  // ── 商品图片（Network + fallback） ──
  Widget _productImage(String url)=>Image.network(url,fit:BoxFit.cover,
    errorBuilder:(_,__,___)=>Container(decoration:const BoxDecoration(gradient:LinearGradient(colors:[Color(0xFFFFF0E8),Color(0xFFFDE8D5)])),child:const Center(child:Icon(Icons.pets,color:Color(0xFFFF6F22),size:24))),
    loadingBuilder:(_,child,progress)=>progress==null?child:Container(decoration:const BoxDecoration(gradient:LinearGradient(colors:[Color(0xFFFFF0E8),Color(0xFFFDE8D5)])),child:Center(child:CircularProgressIndicator(strokeWidth:2,value:progress.expectedTotalBytes!=null?progress.cumulativeBytesLoaded/progress.expectedTotalBytes!:null))));

  Widget _card(_P p,ColorScheme s)=>GestureDetector(onTap:(){},child:Container(
    decoration:BoxDecoration(color:s.surfaceContainerLow,borderRadius:BorderRadius.circular(radiusCard),
      boxShadow:[BoxShadow(color:s.shadow.withAlpha(12),blurRadius:10,offset:const Offset(0,3))]),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Expanded(child:ClipRRect(borderRadius:const BorderRadius.vertical(top:Radius.circular(radiusCard)),child:Stack(children:[
        Positioned.fill(child:_productImage(p.img)),
        Positioned(right:6,top:6,child:Container(padding:const EdgeInsets.symmetric(horizontal:5,vertical:2),decoration:BoxDecoration(color:s.primary.withAlpha(180),borderRadius:BorderRadius.circular(4)),child:Text(p.t,style:const TextStyle(fontSize:9,color:Colors.white)))),
        Positioned(right:6,bottom:6,child:_SC(rating:p.s,s:s)),
      ]))),
      Padding(padding:const EdgeInsets.all(10),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Container(padding:const EdgeInsets.symmetric(horizontal:6,vertical:3),decoration:BoxDecoration(color:s.primaryContainer,borderRadius:BorderRadius.circular(6)),
          child:Text(p.sub,style:TextStyle(fontSize:10,color:s.onSurfaceVariant))),
        const SizedBox(height:4),
        Text(p.n,maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(fontWeight:FontWeight.w600,fontSize:12,color:s.onSurface,height:1.2)),
        const SizedBox(height:4),
        Row(children:[
          Text('¥${p.p.toStringAsFixed(0)}',style:TextStyle(color:s.primary,fontWeight:FontWeight.w800,fontSize:14)),
          const Spacer(),
          Container(width:24,height:24,decoration:BoxDecoration(shape:BoxShape.circle,color:s.primaryContainer),child:Icon(Icons.add_shopping_cart_rounded,color:s.primary,size:14)),
        ]),
      ])),
    ])));
}

class _SC extends StatelessWidget{
  const _SC({required this.rating,required this.s});
  final double rating;final ColorScheme s;
  @override Widget build(BuildContext c)=>Container(padding:const EdgeInsets.symmetric(horizontal:6,vertical:2),
    decoration:BoxDecoration(color:s.primary.withAlpha(180),borderRadius:BorderRadius.circular(6)),
    child:Row(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.star_rounded,size:10,color:Colors.white),const SizedBox(width:1),
      Text('$rating',style:const TextStyle(fontSize:10,fontWeight:FontWeight.w700,color:Colors.white))]));
}
