import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/chat.dart';
import '../../data/services/supabase_service.dart';
import '../../data/services/api_service.dart';
import 'auth_provider.dart';

final chatListProvider = StateNotifierProvider<ChatListNotifier, AsyncValue<List<Chat>>>((ref) {
  final auth = ref.watch(authProvider);
  return ChatListNotifier(auth.profile?.id);
});

class ChatListNotifier extends StateNotifier<AsyncValue<List<Chat>>> {
  ChatListNotifier(this.userId) : super(const AsyncValue.loading()) {
    if (userId != null) {
      loadChats();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  final String? userId;
  final _supabase = SupabaseService.instance;
  final _api = ApiService.instance;

  Future<void> loadChats() async {
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      // DEMO MODE: Return mock chats
      await Future.delayed(const Duration(milliseconds: 500));

      final mockChats = _createMockChats();
      state = AsyncValue.data(mockChats);

      // Original backend call (commented out):
      // final chats = await _supabase.getMonitoredChats(userId!);
      // state = AsyncValue.data(chats);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  List<Chat> _createMockChats() {
    final now = DateTime.now();
    return [
      Chat(
        id: 'chat_1',
        userId: userId!,
        chatId: 123456,
        chatTitle: 'Рабочая группа',
        chatType: 'group',
        isActive: true,
        isMonitored: true,
        addedAt: now.subtract(const Duration(days: 5)),
        lastMessageAt: now,
      ),
      Chat(
        id: 'chat_2',
        userId: userId!,
        chatId: 789012,
        chatTitle: 'Личный чат с Иваном',
        chatType: 'private',
        isActive: true,
        isMonitored: true,
        addedAt: now.subtract(const Duration(days: 10)),
        lastMessageAt: now.subtract(const Duration(hours: 3)),
      ),
      Chat(
        id: 'chat_3',
        userId: userId!,
        chatId: 345678,
        chatTitle: 'Проектный канал',
        chatType: 'channel',
        isActive: true,
        isMonitored: false,
        addedAt: now.subtract(const Duration(days: 15)),
        lastMessageAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

  Future<List<dynamic>> getAvailableChats() async {
    if (userId == null) return [];

    try {
      return await _api.getAvailableChats(userId!);
    } catch (e) {
      return [];
    }
  }

  Future<void> toggleChat({
    required int chatId,
    required String chatTitle,
    required String chatType,
    required bool enable,
  }) async {
    if (userId == null) return;

    try {
      // DEMO MODE: Update local state
      await Future.delayed(const Duration(milliseconds: 300));

      final currentChats = state.value ?? [];
      final updatedChats = currentChats.map((chat) {
        if (chat.chatId == chatId) {
          return Chat(
            id: chat.id,
            userId: chat.userId,
            chatId: chat.chatId,
            chatTitle: chat.chatTitle,
            chatType: chat.chatType,
            isActive: chat.isActive,
            isMonitored: enable,
            addedAt: chat.addedAt,
            lastMessageAt: DateTime.now(),
          );
        }
        return chat;
      }).toList();

      state = AsyncValue.data(updatedChats);

      // Original backend call (commented out):
      // await _supabase.toggleChatMonitoring(
      //   userId!,
      //   chatId,
      //   chatTitle,
      //   chatType,
      //   enable,
      // );
      // await loadChats();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> removeChat(int chatId) async {
    if (userId == null) return;

    try {
      final currentChats = state.value ?? [];
      final chat = currentChats.firstWhere(
        (c) => c.chatId == chatId,
        orElse: () => throw Exception('Chat not found'),
      );

      await _supabase.toggleChatMonitoring(
        userId!,
        chatId,
        chat.chatTitle,
        chat.chatType,
        false,
      );
      await loadChats();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  int get monitoredChatsCount => state.value?.length ?? 0;

  List<Chat> getChatsByType(String type) {
    return state.value?.where((chat) => chat.chatType == type).toList() ?? [];
  }
}
