import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/chat_message.dart';
import '../../../../core/widgets/common.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../presentation/widgets/aff_user_avatar.dart';
import '../../presentation/sample_data.dart';
import '../../presentation/widgets/affiliate_design.dart';
import 'chat_providers.dart';
import '../../../../core/widgets/app_toast.dart';

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
  XFile? _attachment;
  Uint8List? _attachmentBytes;
  final _picker = ImagePicker();
  static const _maxBytes = 5 * 1024 * 1024;

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

  void _toast(String message, [ToastType type = ToastType.error]) => showToast(context, message, type: type);

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, maxWidth: 2048, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > _maxBytes) {
        if (mounted) _toast('That picture is too large (max 5 MB)');
        return;
      }
      if (!mounted) return;
      setState(() {
        _attachment = file;
        _attachmentBytes = bytes;
      });
    } catch (e, st) {
      debugPrint('Image pick failed: $e\n$st');
      if (mounted) _toast('Could not open that picture');
    }
  }

  void _showAttachSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Attach a picture', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AffColors.ink)),
              ),
              ListTile(
                leading: const AffIconChip(icon: Icons.photo_library_rounded, color: AffColors.purpleEnd, size: 42),
                title: const Text('Choose from gallery', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pick(ImageSource.gallery);
                },
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const AffIconChip(icon: Icons.photo_camera_rounded, color: AffColors.pink, size: 42),
                  title: const Text('Take a photo', style: TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pick(ImageSource.camera);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send({bool sample = false}) async {
    final value = _controller.text.trim();
    if ((value.isEmpty && _attachment == null) || _sending) return;
    if (sample) {
      _toast('Reconnect to the server to send messages', ToastType.warning);
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(chatProvider.notifier).send(value, image: _attachment);
      _controller.clear();
      if (!mounted) return;
      setState(() {
        _attachment = null;
        _attachmentBytes = null;
      });
    } catch (e) {
      if (mounted) _toast(e is ApiException ? e.message : 'Could not send. Please try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawAsync = ref.watch(chatProvider);
    final sample = isSample(rawAsync);
    final chatAsync = withSample(rawAsync, SampleData.chat);

    return Scaffold(
      backgroundColor: AffColors.pageBg,
      appBar: AffHeader(
        title: 'Chat',
        subtitle: 'LootHat Affiliate',
        actions: [
          AffHeaderIcon(
            icon: Icons.notifications_none_rounded,
            showDot: true,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
          const AffUserAvatar(),
        ],
      ),
      body: chatAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: 'Failed to load chat.\n$e', onRetry: () => ref.invalidate(chatProvider)),
        data: (chatState) {
          final closed = chatState.status == 'closed';
          final messages = chatState.messages;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                if (sample) SampleDataBanner(onRetry: () => ref.invalidate(chatProvider)),
                Expanded(
                  child: FadeSlideIn(
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: AffColors.cardShadow),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          const _SupportHeader(),
                          Expanded(
                            child: Container(
                              color: AffColors.fieldBg,
                              child: messages.isEmpty
                                  ? const EmptyState(message: 'No messages yet — say hello!', icon: Icons.forum_rounded)
                                  : ListView.builder(
                                      controller: _scrollController,
                                      padding: const EdgeInsets.all(14),
                                      itemCount: messages.length,
                                      itemBuilder: (context, i) {
                                        final m = messages[i];
                                        final showDate = m.date != null && m.date!.isNotEmpty && (i == 0 || messages[i - 1].date != m.date);
                                        return Column(
                                          children: [
                                            if (showDate) _DatePill(m.date!),
                                            _Bubble(message: m, mine: m.from == 'user'),
                                          ],
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (closed)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline, size: 16, color: AffColors.warning),
                        const SizedBox(width: 8),
                        Expanded(child: Text('This conversation was closed.', style: AffText.jakarta(12.5, FontWeight.w600, color: AffColors.warning))),
                        TextButton(onPressed: () => ref.read(chatProvider.notifier).reopen(), child: const Text('Start new chat')),
                      ],
                    ),
                  )
                else
                  _Composer(
                    controller: _controller,
                    sending: _sending,
                    attachmentBytes: _attachmentBytes,
                    onAttach: _showAttachSheet,
                    onRemoveAttachment: () => setState(() {
                      _attachment = null;
                      _attachmentBytes = null;
                    }),
                    onSend: () => _send(sample: sample),
                  ),
                // Space for the floating tab bar.
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Support card header: gradient bar with the agent avatar and presence dot.
class _SupportHeader extends StatelessWidget {
  const _SupportHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [AffColors.violetDeep, AffColors.purple]),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.22)),
                child: Text('S', style: AffText.number(15, FontWeight.w800, color: Colors.white)),
              ),
              Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: const Color(0xFF4ADE80), shape: BoxShape.circle, border: Border.all(color: AffColors.purpleEnd, width: 2)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LootHat Support', style: AffText.jakarta(14, FontWeight.w800, color: Colors.white)),
                Text('Ask about offers, payouts or your account', maxLines: 1, overflow: TextOverflow.ellipsis, style: AffText.jakarta(10.5, FontWeight.w500, color: Colors.white.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: AffColors.chipLilac, borderRadius: BorderRadius.circular(99)),
        child: Text(text.toUpperCase(), style: AffText.jakarta(10, FontWeight.w700, color: AffColors.violetDeep)),
      ),
    );
  }
}

/// Message composer: white pill with attach, text field and the gradient
/// send button — plus a removable preview of a picked picture.
class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.attachmentBytes,
    required this.onAttach,
    required this.onRemoveAttachment,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final Uint8List? attachmentBytes;
  final VoidCallback onAttach;
  final VoidCallback onRemoveAttachment;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (attachmentBytes != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 4),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.memory(attachmentBytes!, width: 84, height: 84, fit: BoxFit.cover)),
                  Positioned(
                    top: -8,
                    right: -8,
                    child: GestureDetector(
                      onTap: onRemoveAttachment,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(color: AffColors.ink, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(99),
            boxShadow: [BoxShadow(color: const Color(0xFF3C1478).withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: sending ? null : onAttach,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Icon(Icons.attach_file_rounded, color: AffColors.purpleEnd, size: 21),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  style: AffText.jakarta(13, FontWeight.w500),
                  decoration: InputDecoration(
                    filled: false,
                    isDense: true,
                    hintText: 'Type your message…',
                    hintStyle: AffText.jakarta(13, FontWeight.w500, color: AffColors.inkHint),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: sending ? null : onSend,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(begin: Alignment(-1, -0.6), end: Alignment(1, 0.6), colors: [AffColors.purpleEnd, AffColors.magenta]),
                    boxShadow: [BoxShadow(color: AffColors.purpleEnd.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))],
                  ),
                  child: sending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 17),
                ),
              ),
            ],
          ),
        ),
      ],
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
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 9),
      decoration: BoxDecoration(
        gradient: mine ? AffColors.gradient : null,
        color: mine ? null : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(mine ? 18 : 6),
          bottomRight: Radius.circular(mine ? 6 : 18),
        ),
        boxShadow: mine
            ? [BoxShadow(color: AffColors.purpleEnd.withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 6))]
            : [BoxShadow(color: const Color(0xFF3C1478).withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.imagePath != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => Dialog.fullscreen(
                    backgroundColor: Colors.black,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: InteractiveViewer(child: Center(child: Image.network('${ApiConfig.baseUrl}${message.imagePath}'))),
                        ),
                        SafeArea(
                          child: IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    '${ApiConfig.baseUrl}${message.imagePath}',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(height: 80, width: 120, child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
              ),
            ),
          if (message.text.isNotEmpty)
            Text(message.text, style: AffText.jakarta(13, FontWeight.w500, color: mine ? Colors.white : AffColors.ink, height: 1.45)),
          const SizedBox(height: 4),
          Text(
            mine ? '${message.time ?? ''} · Sent' : (message.time ?? ''),
            style: AffText.number(9.5, FontWeight.w600, color: mine ? Colors.white.withValues(alpha: 0.75) : AffColors.inkHint),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [bubble],
      ),
    );
  }
}
