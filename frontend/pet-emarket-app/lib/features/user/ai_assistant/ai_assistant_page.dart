/// AI 宠物医生 — Voldog 聊天 UI · 半透明 AppBar
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({required this.apiClient, super.key});
  final ApiClient apiClient;
  @override State<AiAssistantPage> createState() => _AS();
}

class _AS extends State<AiAssistantPage> {
  final _c = TextEditingController();
  final _list = <_M>[];
  final _sc = ScrollController();
  bool _b = false;

  @override void dispose() { _c.dispose(); _sc.dispose(); super.dispose(); }

  Future<void> _send() async {
    final t = _c.text.trim(); if (t.isEmpty) return;
    setState(() { _list.add(_M(true, t)); _b = true; }); _c.clear(); _sd();
    try {
      final a = await widget.apiClient.chat(t, scene: 'assistant');
      final buf = StringBuffer(a.answer);
      if (a.knowledgeTags.isNotEmpty) buf.write('\n\n🏷 ${a.knowledgeTags.join(' · ')}');
      if (a.recommendedActions.isNotEmpty) buf.write('\n\n💡 ${a.recommendedActions.join(' | ')}');
      if (mounted) setState(() { _list.add(_M(false, buf.toString())); _b = false; });
    } catch (e) { if (mounted) setState(() { _list.add(_M(false, '抱歉，AI 暂时不可用')); _b = false; }); }
    _sd();
  }

  void _sd() { WidgetsBinding.instance.addPostFrameCallback((_) { if (_sc.hasClients) _sc.animateTo(_sc.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); }); }

  @override Widget build(BuildContext ctx) {
    final t = Theme.of(ctx); final s = t.colorScheme;
    return Scaffold(
      backgroundColor: s.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.of(ctx).pop()),
        title: Row(children: [
          Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4CAF50))),
          const SizedBox(width: 10),
          Text('Voldog 智能AI宠医 🐾', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: s.onSurface)),
        ]),
        backgroundColor: s.surface.withAlpha(210),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
      ),
      body: Column(children: [
        const SizedBox(height: kToolbarHeight + 20),
        // 状态栏
        Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: s.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Icon(Icons.verified, size: 16, color: const Color(0xFF4CAF50)), const SizedBox(width: 8),
            Text('在线中 · 46 篇兽医知识', style: TextStyle(fontSize: 12, color: s.onSurfaceVariant)),
            const Spacer(), Icon(Icons.shield_outlined, size: 14, color: s.onSurfaceVariant), const SizedBox(width: 4), Text('端到端加密', style: TextStyle(fontSize: 11, color: s.onSurfaceVariant)),
          ])),
        // 消息列表
        Expanded(child: _list.isEmpty && !_b
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 80, height: 80, decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: s.primaryContainer), child: Icon(Icons.smart_toy_rounded, size: 40, color: s.primary)),
              const SizedBox(height: 16), Text('Voldog 智能AI宠医', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: s.onSurface)),
              const SizedBox(height: 4), Text('可以问我宠物养护、疾病、喂养等问题', style: TextStyle(fontSize: 13, color: s.onSurfaceVariant)),
            ]))
          : ListView.builder(controller: _sc, physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), itemCount: _list.length + (_b ? 1 : 0), itemBuilder: (_, i) {
              if (_b && i == _list.length) return _typing(s);
              return _bubble(_list[i], s);
            })),
        // 底部输入胶囊
        Container(margin: const EdgeInsets.fromLTRB(12, 0, 12, 12), padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(color: s.surfaceContainerLow, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: s.shadow.withAlpha(20), blurRadius: 16, offset: const Offset(0, 4))]),
          child: Row(children: [
            IconButton(icon: Icon(Icons.pets, color: s.primary.withAlpha(140), size: 22), onPressed: () {}),
            Expanded(child: TextField(controller: _c, style: TextStyle(color: s.onSurface, fontSize: 15),
              decoration: InputDecoration(hintText: '输入问题…', hintStyle: TextStyle(color: s.onSurfaceVariant, fontSize: 14), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12)),
              onSubmitted: (_) => _send())),
            Container(decoration: BoxDecoration(shape: BoxShape.circle, color: s.primary),
              child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20), onPressed: _b ? null : _send)),
          ])),
      ]));
  }

  Widget _bubble(_M m, ColorScheme s) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: m.isUser ? MainAxisAlignment.end : MainAxisAlignment.start, children: [
    if (!m.isUser) ...[CircleAvatar(radius: 16, backgroundColor: s.primaryContainer, child: Icon(Icons.smart_toy_rounded, size: 18, color: s.primary)), const SizedBox(width: 8)],
    Flexible(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: m.isUser ? s.primary : s.surfaceContainerHigh,
        borderRadius: BorderRadius.only(topLeft: const Radius.circular(20), topRight: const Radius.circular(20),
          bottomLeft: m.isUser ? const Radius.circular(20) : const Radius.circular(4),
          bottomRight: m.isUser ? const Radius.circular(4) : const Radius.circular(20))),
      child: Text(m.text, style: TextStyle(fontSize: 14, height: 1.5, color: m.isUser ? s.onPrimary : s.onSurface)))),
    if (m.isUser) const SizedBox(width: 8),
  ]));

  Widget _typing(ColorScheme s) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
    CircleAvatar(radius: 16, backgroundColor: s.primaryContainer, child: Icon(Icons.smart_toy_rounded, size: 18, color: s.primary)), const SizedBox(width: 8),
    Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: s.surfaceContainerHigh, borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomRight: Radius.circular(20), bottomLeft: Radius.circular(4))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [_Dot(s.primary), const SizedBox(width: 6), _Dot(s.primary), const SizedBox(width: 6), _Dot(s.primary)])),
  ]);

  Widget _Dot(Color c) => TweenAnimationBuilder<double>(tween: Tween(begin: 0.3, end: 1.0), duration: const Duration(milliseconds: 900), builder: (_, v, __) => Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: c.withAlpha((v * 255).round()))));
}

class _M { final bool isUser; final String text; const _M(this.isUser, this.text); }
