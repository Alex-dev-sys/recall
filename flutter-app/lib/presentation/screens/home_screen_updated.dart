import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/chat_tile.dart';

class HomeScreenUpdated extends ConsumerStatefulWidget {
  const HomeScreenUpdated({super.key});

  @override
  ConsumerState<HomeScreenUpdated> createState() => _HomeScreenUpdatedState();
}

class _HomeScreenUpdatedState extends ConsumerState<HomeScreenUpdated> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recall'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_selectedIndex == 0) {
                ref.read(taskListProvider.notifier).loadTasks();
              } else if (_selectedIndex == 1) {
                ref.read(chatListProvider.notifier).loadChats();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: 'Задачи',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Чаты',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
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
            icon: Icons.task_alt,
            title: 'Нет активных задач',
            subtitle: 'Задачи будут появляться автоматически\nиз ваших Telegram-сообщений',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(taskListProvider.notifier).loadTasks();
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskCard(
                task: task,
                onTap: () {
                  context.push('/task/${task.id}', extra: task);
                },
                onMarkDone: () async {
                  await ref.read(taskListProvider.notifier).markAsDone(task.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Задача выполнена!')),
                    );
                  }
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

  Widget _buildChatsTab() {
    final chatsAsync = ref.watch(chatListProvider);

    return chatsAsync.when(
      data: (chats) {
        if (chats.isEmpty) {
          return _buildEmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'Нет отслеживаемых чатов',
            subtitle: 'Добавьте чаты для мониторинга задач',
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
        icon: Icons.person_outline,
        title: 'Не авторизован',
        subtitle: 'Войдите в аккаунт для доступа ко всем функциям',
      );
    }

    return ListView(
      children: [
        const SizedBox(height: 32),
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              profile.initials,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          profile.displayName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (profile.phoneNumber != null) ...[
          const SizedBox(height: 4),
          Text(
            profile.phoneNumber!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
        const SizedBox(height: 32),
        _buildStatCard(),
        const Divider(height: 32),
        ListTile(
          leading: const Icon(Icons.notifications),
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
        const Divider(),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('О приложении'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'Recall',
              applicationVersion: '1.0.0',
              applicationIcon: const Icon(Icons.notifications_active_rounded, size: 48),
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
    );
  }

  Widget _buildStatCard() {
    final taskNotifier = ref.read(taskListProvider.notifier);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Активных',
                  taskNotifier.totalActiveTasks.toString(),
                  Icons.task_alt,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Срочных',
                  taskNotifier.urgentTasksCount.toString(),
                  Icons.warning_rounded,
                  Colors.red,
                ),
                _buildStatItem(
                  'Просрочено',
                  taskNotifier.overdueTasksCount.toString(),
                  Icons.alarm_off,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
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
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
