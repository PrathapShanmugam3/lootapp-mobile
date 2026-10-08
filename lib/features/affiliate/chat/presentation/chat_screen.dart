import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/chat_message.dart';
import '../../../../core/widgets/common.dart';
import '../../presentation/widgets/aff_user_avatar.dart';
import '../../presentation/widgets/affiliate_design.dart';
import 'chat_providers.dart';

const _quickReplies = ['Payout delayed', 'Tracking issue', 'KYC help'];

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  Timer? _pollTimer;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      ref.read(chatProvider.notifier).poll();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? text]) async {
    final value = (text ?? _controller.text).trim();
    if (value.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(chatProvider.notifier).send(value);
      _controller.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatProvider);

    return Scaffold(
      backgroundColor: AffColors.pageBg,
      appBar: AffHeader(
        title: 'Chat',
        subtitle: 'LootHat Affiliate',
        actions: [
          AffHeaderIcon(icon: Icons.notifications_outlined, onTap: () {}),
          const AffUserAvatar(),
        ],
      ),
      body: chatAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: 'Failed to load chat.\n$e', onRetry: () => ref.invalidate(chatProvider)),
        data: (chatState) {
          final closed = chatState.status == 'closed';
          return Column(
            children: [
              _SupportBanner(),
              Expanded(
                child: chatState.messages.isEmpty
                    ? const EmptyState(message: 'No messages yet — say hello!', icon: Icons.forum_rounded)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: chatState.messages.length,
                        itemBuilder: (context, i) {
                          final m = chatState.messages[i];
                          return _Bubble(message: m, mine: m.from == 'user');
                        },
                      ),
              ),
              if (closed)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: AffColors.warning.withValues(alpha: 0.12),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, size: 16, color: AffColors.warning),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('This conversation was closed.')),
                      TextButton(onPressed: () => ref.read(chatProvider.notifier).reopen(), child: const Text('Start new chat')),
                    ],
                  ),
                )
              else ...[
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _quickReplies.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => _QuickReplyChip(label: _quickReplies[i], onTap: () => _send(_quickReplies[i])),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: AffColors.hairline), boxShadow: AffColors.cardShadow),
                            child: TextField(
                              controller: _controller,
                              minLines: 1,
                              maxLines: 4,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _send(),
                              decoration: const InputDecoration(
                                hintText: 'Type your message...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            gradient: AffColors.gradient,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: AffColors.purpleEnd.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 6))],
                          ),
                          child: IconButton(
                            icon: _sending
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            onPressed: _sending ? null : () => _send(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SupportBanner extends StatelessWidget {
  const _SupportBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: AffCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(gradient: AffColors.gradient, shape: BoxShape.circle),
                  child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 21),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: AffColors.success, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LootHat Support', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AffColors.ink)),
                  Text('Ask about offers, payouts or your account', style: TextStyle(fontSize: 11, color: AffColors.inkMuted, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickReplyChip extends StatelessWidget {
  const _QuickReplyChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: AffColors.hairline)),
          child: Text(label, style: const TextStyle(color: AffColors.ink, fontWeight: FontWeight.w600, fontSize: 12.5)),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});

  final ChatMessageModel message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
      padding: const EdgeInsets.fromLTRB(15, 11, 15, 9),
      decoration: BoxDecoration(
        gradient: mine ? AffColors.gradient : null,
        color: mine ? null : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(mine ? 20 : 5),
          bottomRight: Radius.circular(mine ? 5 : 20),
        ),
        border: mine ? null : Border.all(color: AffColors.hairline),
        boxShadow: mine ? [BoxShadow(color: AffColors.purpleEnd.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 6))] : AffColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.imagePath != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  '${ApiConfig.baseUrl}${message.imagePath}',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 80, width: 120, child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            ),
          if (message.text.isNotEmpty)
            Text(message.text, style: TextStyle(color: mine ? Colors.white : AffColors.ink, fontSize: 13.5, height: 1.35)),
          const SizedBox(height: 3),
          Text(
            message.time ?? '',
            style: TextStyle(fontSize: 10, color: mine ? Colors.white.withValues(alpha: 0.75) : AffColors.inkFaint),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [bubble],
      ),
    );
  }
}
