import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_tile.dart';

class ChatSelectionScreen extends ConsumerStatefulWidget {
  const ChatSelectionScreen({super.key});

  @override
  ConsumerState<ChatSelectionScreen> createState() => _ChatSelectionScreenState();
}

class _ChatSelectionScreenState extends ConsumerState<ChatSelectionScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, private, group, channel

  @override
  void initState() {
    super.initState();
    // Load chats when screen opens
    Future.microtask(() {
      ref.read(chatListProvider.notifier).loadChats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatsAsync = ref.watch(chatListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор чатов'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Поиск чатов...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Все'),
                      selected: _selectedFilter == 'all',
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = 'all';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Личные'),
                      selected: _selectedFilter == 'private',
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = 'private';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Группы'),
                      selected: _selectedFilter == 'group',
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = 'group';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Каналы'),
                      selected: _selectedFilter == 'channel',
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = 'channel';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: chatsAsync.when(
        data: (chats) {
          // Filter chats
          final filteredChats = chats.where((chat) {
            // Search filter
            final matchesSearch = _searchQuery.isEmpty ||
                chat.chatTitle.toLowerCase().contains(_searchQuery);

            // Type filter
            final matchesType = _selectedFilter == 'all' ||
                (_selectedFilter == 'group' &&
                    (chat.chatType == 'group' || chat.chatType == 'supergroup')) ||
                chat.chatType == _selectedFilter;

            return matchesSearch && matchesType;
          }).toList();

          if (filteredChats.isEmpty) {
            return _buildEmptyState(theme);
          }

          // Group by monitored status
          final monitoredChats = filteredChats.where((c) => c.isMonitored).toList();
          final otherChats = filteredChats.where((c) => !c.isMonitored).toList();

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(chatListProvider.notifier).loadChats();
            },
            child: ListView(
              children: [
                if (monitoredChats.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_active,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Отслеживаемые (${monitoredChats.length})',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...monitoredChats.map((chat) => ChatTile(
                        chat: chat,
                        isMonitored: chat.isMonitored,
                        onToggle: (value) async {
                          await ref.read(chatListProvider.notifier).toggleChat(
                                chatId: chat.chatId,
                                chatTitle: chat.chatTitle,
                                chatType: chat.chatType,
                                enable: value,
                              );
                        },
                      )),
                  const Divider(height: 32),
                ],
                if (otherChats.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Доступные чаты (${otherChats.length})',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...otherChats.map((chat) => ChatTile(
                        chat: chat,
                        isMonitored: chat.isMonitored,
                        onToggle: (value) async {
                          await ref.read(chatListProvider.notifier).toggleChat(
                                chatId: chat.chatId,
                                chatTitle: chat.chatTitle,
                                chatType: chat.chatType,
                                enable: value,
                              );
                        },
                      )),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(theme, error.toString()),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Чаты не найдены',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Попробуйте изменить параметры поиска',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(chatListProvider.notifier).loadChats();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
