/// AI 宠物医生 — 现代聊天 UI · 暖橘用户气泡 · 淡棕 AI 气泡
library;

import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_theme.dart' show voldogOrange;

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({required this.apiClient, super.key});
  final ApiClient apiClient;

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final _ctrl = TextEditingController();
  final _list = <_Msg>[];
  final _scrollCtrl = ScrollController();
  bool _loading = false;

  @override
  void dispose() { _ctrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() { _list.add(_Msg(true, text)); _loading = true; });
    _ctrl.clear();
    _scrollDown();
    try {
      final answer = await widget.apiClient.chat(text, scene: 'assistant');
      final buf = StringBuffer(answer.answer);
      if (answer.knowledgeTags.isNotEmpty) buf.write('\n\n🏷 ${answer.knowledgeTags.join(' · ')}');
      if (answer.recommendedActions.isNotEmpty) buf.write('\n\n💡 ${answer.recommendedActions.join(' | ')}');
      if (mounted) setState(() { _list.add(_Msg(false, buf.toString())); _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _list.add(_Msg(false, '抱歉，AI 服务暂时不可用')); _loading = false; });
    }
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.of(context).pop()),
        title: Row(children: [
          Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4CAF50))),
          const SizedBox(width: 10),
          Text('AI 宠物医生', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: scheme.onSurface)),
        ]),
        backgroundColor: scheme.surface, surfaceTintColor: Colors.transparent, elevation: 0,
      ),
      body: Column(children: [
        // 状态栏
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Icon(Icons.verified, size: 18, color: const Color(0xFF4CAF50)),
            const SizedBox(width: 8),
            Text('在线 · 基于 46 篇兽医知识库', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            const Spacer(),
            Icon(Icons.shield_outlined, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text('E2E', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
          ]),
        ),
        // 消息列表
        Expanded(
          child: _list.isEmpty && !_loading
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 80, height: 80, decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: scheme.primaryContainer),
                    child: Icon(Icons.smart_toy_rounded, size: 40, color: scheme.primary)),
                  const SizedBox(height: 16),
                  Text('AI 宠物医生', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: scheme.onSurface)),
                  const SizedBox(height: 4),
                  Text('可以问我宠物养护、疾病、喂养等问题', style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
                ]))
              : ListView.builder(
                  controller: _scrollCtrl, physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  itemCount: _list.length + (_loading ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (_loading && i == _list.length) return _typing(scheme);
                    return _bubble(_list[i], scheme);
                  },
                ),
        ),
        // 底部输入悬浮条
        Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: scheme.shadow.withAlpha(20), blurRadius: 16, offset: const Offset(0, 4))]),
          child: Row(children: [
            IconButton(icon: Icon(Icons.pets, color: scheme.primary.withAlpha(140), size: 22), onPressed: () {}),
            Expanded(child: TextField(controller: _ctrl, style: TextStyle(color: scheme.onSurface, fontSize: 15),
              decoration: InputDecoration(hintText: '输入问题…', hintStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12)),
              onSubmitted: (_) => _send())),
            Container(decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.primary),
              child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20), onPressed: _loading ? null : _send)),
          ]),
        ),
      ]),
    );
  }

  Widget _bubble(_Msg m, ColorScheme s) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: m.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!m.isUser) ...[CircleAvatar(radius: 16, backgroundColor: s.primaryContainer, child: Icon(Icons.smart_toy_rounded, size: 18, color: s.primary)), const SizedBox(width: 8)],
        Flexible(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: m.isUser ? s.primary : s.surfaceContainerHigh,
            borderRadius: BorderRadius.only(topLeft: const Radius.circular(20), topRight: const Radius.circular(20),
              bottomLeft: m.isUser ? const Radius.circular(20) : const Radius.circular(4),
              bottomRight: m.isUser ? const Radius.circular(4) : const Radius.circular(20)),
          ),
          child: Text(m.text, style: TextStyle(fontSize: 14, height: 1.5, color: m.isUser ? s.onPrimary : s.onSurface)),
        )),
        if (m.isUser) const SizedBox(width: 8),
      ],
    ));
  }

  Widget _typing(ColorScheme s) {
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      CircleAvatar(radius: 16, backgroundColor: s.primaryContainer, child: Icon(Icons.smart_toy_rounded, size: 18, color: s.primary)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: s.surfaceContainerHigh, borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomRight: Radius.circular(20), bottomLeft: Radius.circular(4))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _Dot(s.primary, 0), const SizedBox(width: 6), _Dot(s.primary, 300), const SizedBox(width: 6), _Dot(s.primary, 600),
        ]),
      ),
    ]);
  }

  Widget _Dot(Color c, int delay) {
    return TweenAnimationBuilder<double>(tween: Tween(begin: 0.3, end: 1.0), duration: const Duration(milliseconds: 900),
      builder: (_, v, __) => Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: c.withAlpha((v * 255).round()))));
  }
}

class _Msg { final bool isUser; final String text; const _Msg(this.isUser, this.text); }
