import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/chat_message.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../data/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final client = ref.watch(apiClientProvider).requireValue;
  return ChatRepository(client);
});

class ChatState {
  const ChatState({required this.messages, required this.status});

  final List<ChatMessageModel> messages;
  final String status;

  static const initial = ChatState(messages: [], status: 'open');
}

class ChatNotifier extends AutoDisposeAsyncNotifier<ChatState> {
  @override
  Future<ChatState> build() async {
    final repo = ref.read(chatRepositoryProvider);
    final result = await repo.getMessages();
    return ChatState(messages: result['messages'], status: result['status']);
  }

  Future<void> poll() async {
    final current = state.value;
    if (current == null || current.messages.isEmpty) return;
    final repo = ref.read(chatRepositoryProvider);
    try {
      final result = await repo.getMessages(type: 'after', afterId: current.messages.last.id);
      final newMsgs = result['messages'] as List<ChatMessageModel>;
      if (newMsgs.isNotEmpty || result['status'] != current.status) {
        state = AsyncData(ChatState(messages: [...current.messages, ...newMsgs], status: result['status']));
      }
    } catch (_) {
      // best-effort poll
    }
  }

  Future<void> send(String text) async {
    final repo = ref.read(chatRepositoryProvider);
    await repo.sendMessage(text);
    await refresh();
  }

  Future<void> reopen() async {
    final repo = ref.read(chatRepositoryProvider);
    await repo.reopen();
    await refresh();
  }

  Future<void> refresh() async {
    final repo = ref.read(chatRepositoryProvider);
    final result = await repo.getMessages();
    state = AsyncData(ChatState(messages: result['messages'], status: result['status']));
  }
}

final chatProvider = AutoDisposeAsyncNotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
