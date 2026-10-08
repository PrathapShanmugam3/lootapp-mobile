import 'package:flutter/material.dart';

import '../network/api_client.dart';
import '../theme/app_theme.dart';
import 'chat_message.dart';

/// Shared chat bubble list + composer, reused by the affiliate support chat,
/// manager inbox chat, and admin support chat. The host screen owns data
/// fetching/polling and passes in the current message list; this widget is
/// purely presentational plus the text/image input callback.
class ChatView extends StatefulWidget {
  const ChatView({
    super.key,
    required this.messages,
    required this.selfFrom,
    required this.onSend,
    this.closed = false,
    this.onReopen,
    this.quickReplies,
  });

  /// Which `from` value represents "me" in this context — 'user' for the
  /// affiliate screen, 'admin' for manager/admin screens.
  final String selfFrom;
  final List<ChatMessageModel> messages;
  final Future<void> Function(String text, String? imagePath) onSend;
  final bool closed;
  final VoidCallback? onReopen;
  final List<String>? quickReplies;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.onSend(text, null);
      _controller.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.closed)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: AppColors.warning.withValues(alpha: 0.12),
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 16, color: AppColors.warning),
                const SizedBox(width: 8),
                const Expanded(child: Text('This conversation was closed.')),
                if (widget.onReopen != null)
                  TextButton(onPressed: widget.onReopen, child: const Text('Start new chat')),
              ],
            ),
          ),
        Expanded(
          child: widget.messages.isEmpty
              ? const Center(child: Text('No messages yet — say hello!'))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.messages.length,
                  itemBuilder: (context, index) {
                    final m = widget.messages[index];
                    final mine = m.from == widget.selfFrom;
                    return _Bubble(message: m, mine: mine);
                  },
                ),
        ),
        if (!widget.closed)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  if (widget.quickReplies != null && widget.quickReplies!.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.bolt_outlined),
                      tooltip: 'Quick replies',
                      onPressed: () => _showQuickReplies(context),
                    ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceTint,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.hairlineStrong),
                      ),
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Type a message…',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.ink,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sending ? null : _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showQuickReplies(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final reply in widget.quickReplies!)
              ListTile(
                title: Text(reply),
                onTap: () {
                  _controller.text = reply;
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Chat message rendered as a small card (rounded-20, soft purple shadow,
/// sender avatar chip + label) matching the bento-card language used across
/// the rest of the app, instead of a classic speech-bubble tail.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});

  final ChatMessageModel message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: mine ? AppColors.ink : AppColors.surfaceTint,
        shape: BoxShape.circle,
      ),
      child: Icon(
        mine ? Icons.person : Icons.support_agent,
        size: 15,
        color: mine ? Colors.white : AppColors.inkMuted,
      ),
    );

    final card = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: mine ? AppColors.ink : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: mine ? null : Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            mine ? 'You' : 'Support',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: mine ? Colors.white.withValues(alpha: 0.75) : AppColors.inkFaint,
            ),
          ),
          const SizedBox(height: 4),
          if (message.imagePath != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  '${ApiConfig.baseUrl}${message.imagePath}',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 80,
                    width: 120,
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
          if (message.text.isNotEmpty)
            Text(
              message.text,
              style: TextStyle(
                color: mine ? Colors.white : AppColors.ink,
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            message.time ?? '',
            style: TextStyle(
              fontSize: 10,
              color: mine ? Colors.white.withValues(alpha: 0.7) : AppColors.inkFaint,
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: mine
            ? [card, const SizedBox(width: 8), avatar]
            : [avatar, const SizedBox(width: 8), card],
      ),
    );
  }
}
