import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/chat_message.dart';
import '../../../../core/widgets/chat_view.dart';
import '../../../../core/widgets/common.dart';
import '../../presentation/admin_providers.dart';

class AdminSupportScreen extends ConsumerStatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  ConsumerState<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends ConsumerState<AdminSupportScreen> {
  final _searchCtrl = TextEditingController();
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(adminRepositoryProvider).getConversations();
  }

  void _search() => setState(() => _future = ref.read(adminRepositoryProvider).getConversations(search: _searchCtrl.text));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PortalHeader(title: 'Support inbox'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search conversations…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _search),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) return const LoadingState();
                if (snap.hasError) return ErrorState(message: '${snap.error}', onRetry: _search);
                final conversations = (snap.data?['conversations'] as List?) ?? [];
                if (conversations.isEmpty) return const EmptyState(message: 'No conversations yet', icon: Icons.inbox_outlined);
                return RefreshIndicator(
                  onRefresh: () async => _search(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: conversations.length,
                    itemBuilder: (context, i) {
                      final c = (conversations[i] as Map).cast<String, dynamic>();
                      final unread = c['unread'] == true;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: unread ? AppColors.primary.withValues(alpha: 0.06) : null,
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white, size: 18)),
                          title: Text(c['name']?.toString() ?? 'Unknown User', style: TextStyle(fontWeight: unread ? FontWeight.w700 : FontWeight.normal)),
                          subtitle: Text(c['lastMessage']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: unread
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                                  child: Text('${c['unreadCount'] ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                                )
                              : null,
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => AdminChatScreen(userId: c['userId'].toString(), name: c['name']?.toString() ?? '')))
                              .then((_) => _search()),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AdminChatScreen extends ConsumerStatefulWidget {
  const AdminChatScreen({super.key, required this.userId, required this.name});

  final String userId;
  final String name;

  @override
  ConsumerState<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends ConsumerState<AdminChatScreen> {
  List<ChatMessageModel> _messages = [];
  String _status = 'open';
  List<String> _templates = [];
  bool _loading = true;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    ref.read(adminRepositoryProvider).getMessageTemplates().then((t) {
      if (mounted) setState(() => _templates = t);
    }).catchError((_) {});
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(adminRepositoryProvider).getChat(widget.userId);
      setState(() {
        _messages = result['messages'];
        _status = result['status'];
      });
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _poll() async {
    if (_messages.isEmpty) return;
    try {
      final result = await ref.read(adminRepositoryProvider).getChat(widget.userId, type: 'after', afterId: _messages.last.id);
      final newMsgs = result['messages'] as List<ChatMessageModel>;
      if (newMsgs.isNotEmpty && mounted) {
        setState(() => _messages = [..._messages, ...newMsgs]);
      }
    } catch (_) {}
  }

  Future<void> _closeConversation() async {
    try {
      await ref.read(adminRepositoryProvider).closeChat(widget.userId);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PortalHeader(
        title: widget.name,
        actions: [
          if (_status == 'open')
            TextButton(onPressed: _closeConversation, child: const Text('Close', style: TextStyle(color: Colors.white))),
        ],
      ),
      body: _loading
          ? const LoadingState()
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : ChatView(
                  messages: _messages,
                  selfFrom: 'admin',
                  closed: _status == 'closed',
                  quickReplies: _templates,
                  onSend: (text, imagePath) async {
                    await ref.read(adminRepositoryProvider).sendChatMessage(widget.userId, text);
                    await _load();
                  },
                ),
    );
  }
}
