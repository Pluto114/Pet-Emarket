import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({required this.apiClient, super.key});
  final ApiClient apiClient;

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(isUser: true, text: text));
      _loading = true;
    });
    _controller.clear();

    try {
      final answer = await widget.apiClient.chat(text, scene: 'assistant');
      final buffer = StringBuffer(answer.answer);
      if (answer.knowledgeTags.isNotEmpty) {
        buffer.write('\n\n知识标签：${answer.knowledgeTags.join('、')}');
      }
      if (answer.recommendedActions.isNotEmpty) {
        buffer.write('\n\n建议操作：\n- ${answer.recommendedActions.join('\n- ')}');
      }
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(isUser: false, text: buffer.toString()));
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(isUser: false, text: '请求失败：$e'));
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('AI 智能问答')),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.smart_toy_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text('AI 宠物助手', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text('问我关于宠物养护的任何问题', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == _messages.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              CircleAvatar(child: Icon(Icons.smart_toy)),
                              SizedBox(width: 12),
                              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                            ],
                          ),
                        );
                      }
                      final msg = _messages[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: msg.isUser ? theme.colorScheme.primaryContainer : theme.colorScheme.secondaryContainer,
                              child: Icon(msg.isUser ? Icons.person : Icons.smart_toy, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Card(
                                color: msg.isUser ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(msg.text),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: '输入你的问题...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _loading ? null : _send,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final bool isUser;
  final String text;
  const ChatMessage({required this.isUser, required this.text});
}

