import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/chat_message.dart';
import '../../../../core/widgets/common.dart';
import '../../presentation/widgets/aff_user_avatar.dart';
import '../../presentation/sample_data.dart';
import '../../presentation/widgets/affiliate_design.dart';
import 'chat_providers.dart';

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

  void _toast(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

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
      _toast('Reconnect to the server to send messages');
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
          AffHeaderIcon(icon: Icons.notifications_outlined, onTap: () {}),
          const AffUserAvatar(),
        ],
      ),
      body: AffAmbient(
        child: chatAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: 'Failed to load chat.\n$e', onRetry: () => ref.invalidate(chatProvider)),
        data: (chatState) {
          final closed = chatState.status == 'closed';
          return Column(
            children: [
              if (sample)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: SampleDataBanner(onRetry: () => ref.invalidate(chatProvider)),
                ),
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
              else
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_attachmentBytes != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10, left: 4),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.memory(_attachmentBytes!, width: 84, height: 84, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: -8,
                                    right: -8,
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _attachment = null;
                                        _attachmentBytes = null;
                                      }),
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), border: Border.all(color: AffColors.hairline), boxShadow: AffColors.cardShadow),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      tooltip: 'Attach a picture',
                                      icon: const Icon(Icons.attach_file_rounded, color: AffColors.purpleEnd),
                                      onPressed: _sending ? null : _showAttachSheet,
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _controller,
                                        minLines: 1,
                                        maxLines: 4,
                                        textInputAction: TextInputAction.send,
                                        onSubmitted: (_) => _send(sample: sample),
                                        decoration: const InputDecoration(
                                          filled: false,
                                          hintText: 'Type your message...',
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(vertical: 13),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
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
                                padding: const EdgeInsets.all(14),
                                icon: _sending
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.send_rounded, color: Colors.white, size: 21),
                                onPressed: _sending ? null : () => _send(sample: sample),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
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
        accent: AffColors.cyan,
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
