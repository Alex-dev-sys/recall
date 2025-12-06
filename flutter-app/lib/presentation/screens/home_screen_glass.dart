import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/task_card_glass.dart';
import '../widgets/glass_card.dart';
import '../widgets/chat_tile.dart';

class HomeScreenGlass extends ConsumerStatefulWidget {
  const HomeScreenGlass({super.key});

  @override
  ConsumerState<HomeScreenGlass> createState() => _HomeScreenGlassState();
}

class _HomeScreenGlassState extends ConsumerState<HomeScreenGlass>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: _buildGlassAppBar(),
      body: Stack(
        children: [
          // Animated gradient background
          _buildGradientBackground(),
          // Content
          SafeArea(
            child: _buildBody(),
          ),
        ],
      ),
      bottomNavigationBar: _buildGlassNavigationBar(),
    );
  }

  Widget _buildGradientBackground() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _selectedIndex == 0
              ? [
                  const Color(0xFF6366F1).withOpacity(0.1),
                  const Color(0xFF8B5CF6).withOpacity(0.05),
                  const Color(0xFF3B82F6).withOpacity(0.08),
                ]
              : _selectedIndex == 1
                  ? [
                      const Color(0xFF3B82F6).withOpacity(0.1),
                      const Color(0xFF06B6D4).withOpacity(0.05),
                      const Color(0xFF10B981).withOpacity(0.08),
                    ]
                  : [
                      const Color(0xFF8B5CF6).withOpacity(0.1),
                      const Color(0xFFEC4899).withOpacity(0.05),
                      const Color(0xFF6366F1).withOpacity(0.08),
                    ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildGlassAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AppBar(
            backgroundColor: Colors.white.withOpacity(0.3),
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Recall',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.refresh_rounded, size: 20),
                ),
                onPressed: () {
                  if (_selectedIndex == 0) {
                    ref.read(taskListProvider.notifier).loadTasks();
                  } else if (_selectedIndex == 1) {
                    ref.read(chatListProvider.notifier).loadChats();
                  }
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.logout_rounded, size: 20, color: Colors.red),
                ),
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassNavigationBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            indicatorColor: const Color(0xFF6366F1).withOpacity(0.2),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.task_alt_outlined),
                selectedIcon: Icon(Icons.task_alt_rounded),
                label: 'Задачи',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline_rounded),
                selectedIcon: Icon(Icons.chat_bubble_rounded),
                label: 'Чаты',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Профиль',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildTasksTab();
      case 1:
        return _buildChatsTab();
      case 2:
        return _buildProfileTab();
      default:
        return _buildTasksTab();
    }
  }

  Widget _buildTasksTab() {
    final tasksAsync = ref.watch(taskListProvider);

    return tasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return _buildEmptyState(
            icon: Icons.task_alt_rounded,
            title: 'Нет активных задач',
            subtitle: 'Задачи будут появляться автоматически\nиз ваших Telegram-сообщений',
            gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          );
        }

        return Column(
          children: [
            // Stats cards
            _buildStatsSection(tasks),
            const SizedBox(height: 16),
            // Tasks list
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref.read(taskListProvider.notifier).loadTasks();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return TaskCardGlass(
                      task: task,
                      onTap: () {
                        context.push('/task/${task.id}', extra: task);
                      },
                      onMarkDone: () async {
                        await ref.read(taskListProvider.notifier).markAsDone(task.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('✅ Задача выполнена!'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildStatsSection(List tasks) {
    final taskNotifier = ref.read(taskListProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStatCard(
            'Активных',
            taskNotifier.totalActiveTasks.toString(),
            Icons.task_alt_rounded,
            const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Срочных',
            taskNotifier.urgentTasksCount.toString(),
            Icons.warning_rounded,
            const [Color(0xFFEF4444), Color(0xFFF97316)],
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Просрочено',
            taskNotifier.overdueTasksCount.toString(),
            Icons.alarm_off_rounded,
            const [Color(0xFFF97316), Color(0xFFFB923C)],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, List<Color> gradient) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      gradientColors: [
        Colors.white.withOpacity(0.8),
        Colors.white.withOpacity(0.5),
      ],
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatsTab() {
    final chatsAsync = ref.watch(chatListProvider);

    return chatsAsync.when(
      data: (chats) {
        if (chats.isEmpty) {
          return _buildEmptyState(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Нет отслеживаемых чатов',
            subtitle: 'Добавьте чаты для мониторинга задач',
            gradient: const [Color(0xFF3B82F6), Color(0xFF06B6D4)],
            actionLabel: 'Добавить чаты',
            onAction: () {
              context.push('/chats');
            },
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(chatListProvider.notifier).loadChats();
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return ChatTile(
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
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildProfileTab() {
    final auth = ref.watch(authProvider);
    final profile = auth.profile;

    if (profile == null) {
      return _buildEmptyState(
        icon: Icons.person_outline_rounded,
        title: 'Не авторизован',
        subtitle: 'Войдите в аккаунт для доступа ко всем функциям',
        gradient: const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),
        // Profile card
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    profile.initials,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                profile.displayName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              if (profile.phoneNumber != null) ...[
                const SizedBox(height: 8),
                Text(
                  profile.phoneNumber!,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Settings
        GlassCard(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_rounded, color: Colors.white),
                ),
                title: const Text('Уведомления'),
                subtitle: const Text('Push-уведомления о новых задачах'),
                trailing: Switch(
                  value: true,
                  onChanged: (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(value
                            ? 'Уведомления включены'
                            : 'Уведомления отключены'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.info_rounded, color: Colors.white),
                ),
                title: const Text('О приложении'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Recall',
                    applicationVersion: '1.0.0',
                    applicationIcon: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    children: const [
                      Text(
                        'AI-Powered Task Reminder System\n\n'
                        'Автоматически извлекает задачи из ваших '
                        'Telegram-сообщений с помощью искусственного интеллекта.',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black.withOpacity(0.6),
                height: 1.5,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              GlassCard(
                onTap: onAction,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: gradient[0]),
                    const SizedBox(width: 8),
                    Text(
                      actionLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: gradient[0],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ошибка загрузки',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  if (_selectedIndex == 0) {
                    ref.read(taskListProvider.notifier).loadTasks();
                  } else if (_selectedIndex == 1) {
                    ref.read(chatListProvider.notifier).loadChats();
                  }
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Повторить'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
