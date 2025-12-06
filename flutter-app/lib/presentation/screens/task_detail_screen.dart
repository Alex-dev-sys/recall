import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/priority_badge.dart';

class TaskDetailScreen extends ConsumerWidget {
  final Task task;

  const TaskDetailScreen({
    super.key,
    required this.task,
  });

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('d MMMM y, HH:mm', 'ru_RU').format(dateTime);
  }

  String _formatTaskType(String type) {
    switch (type) {
      case 'request':
        return 'Запрос';
      case 'promise':
        return 'Обещание';
      case 'agreement':
        return 'Договоренность';
      case 'reminder':
        return 'Напоминание';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали задачи'),
        actions: [
          if (task.status != 'done' && task.status != 'cancelled')
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'done') {
                  await ref.read(taskListProvider.notifier).markAsDone(task.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } else if (value == 'cancel') {
                  await ref.read(taskListProvider.notifier).updateTaskStatus(
                        task.id,
                        'cancelled',
                      );
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'done',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 12),
                      Text('Выполнено'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Отменить'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.secondaryContainer,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Priority Badge
                  Row(
                    children: [
                      PriorityBadge(priority: task.priority),
                      const SizedBox(width: 12),
                      Chip(
                        label: Text(_formatTaskType(task.taskType)),
                        backgroundColor: theme.colorScheme.surface,
                      ),
                      const Spacer(),
                      if (task.isOverdue)
                        const Icon(Icons.warning_rounded, color: Colors.red),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Task Content
                  Text(
                    task.content,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Original Quote
                  if (task.originalQuote.isNotEmpty) ...[
                    _buildSectionTitle(theme, 'Оригинальное сообщение'),
                    const SizedBox(height: 8),
                    Card(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.format_quote,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                task.originalQuote,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Deadline
                  if (task.deadline != null) ...[
                    _buildSectionTitle(theme, 'Дедлайн'),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: task.isOverdue
                            ? Colors.red.withValues(alpha: 0.2)
                            : theme.colorScheme.primaryContainer,
                        child: Icon(
                          task.isOverdue ? Icons.alarm_off : Icons.alarm_on,
                          color: task.isOverdue
                              ? Colors.red
                              : theme.colorScheme.primary,
                        ),
                      ),
                      title: Text(_formatDateTime(task.deadline!)),
                      subtitle: task.isOverdue
                          ? const Text(
                              'Просрочено',
                              style: TextStyle(color: Colors.red),
                            )
                          : Text(_getTimeUntilDeadline()),
                      trailing: task.deadlineIsPrecise
                          ? const Chip(
                              label: Text('Точное время'),
                              avatar: Icon(Icons.check, size: 16),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Source Link
                  if (task.sourceLink != null) ...[
                    _buildSectionTitle(theme, 'Источник'),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.telegram,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      title: const Text('Открыть в Telegram'),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () async {
                        if (task.sourceLink != null && task.sourceLink!.isNotEmpty) {
                          try {
                            final uri = Uri.parse(task.sourceLink!);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Не удалось открыть ссылку'),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Ошибка: ${e.toString()}'),
                                ),
                              );
                            }
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ссылка на сообщение недоступна'),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // AI Analysis
                  if (task.aiReasoning != null && task.aiReasoning!.isNotEmpty) ...[
                    _buildSectionTitle(theme, 'AI анализ'),
                    const SizedBox(height: 8),
                    Card(
                      color: theme.colorScheme.tertiaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.psychology,
                                  color: theme.colorScheme.onTertiaryContainer,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Уверенность: ${(task.confidence * 100).toStringAsFixed(0)}%',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.onTertiaryContainer,
                                  ),
                                ),
                              ],
                            ),
                            if (task.aiReasoning!.containsKey('reasoning')) ...[
                              const SizedBox(height: 12),
                              Text(
                                task.aiReasoning!['reasoning'].toString(),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onTertiaryContainer,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Metadata
                  _buildSectionTitle(theme, 'Информация'),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            theme,
                            'Статус',
                            _formatStatus(task.status),
                            Icons.info_outline,
                          ),
                          const Divider(),
                          _buildInfoRow(
                            theme,
                            'Создано',
                            _formatDateTime(task.createdAt),
                            Icons.calendar_today,
                          ),
                          if (task.completedAt != null) ...[
                            const Divider(),
                            _buildInfoRow(
                              theme,
                              'Выполнено',
                              _formatDateTime(task.completedAt!),
                              Icons.check_circle_outline,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: task.status != 'done' && task.status != 'cancelled'
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () async {
                    await ref.read(taskListProvider.notifier).markAsDone(task.id);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Отметить как выполненную'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'new':
        return 'Новая';
      case 'acknowledged':
        return 'Принято к сведению';
      case 'in_progress':
        return 'В работе';
      case 'done':
        return 'Выполнено';
      case 'cancelled':
        return 'Отменено';
      default:
        return status;
    }
  }

  String _getTimeUntilDeadline() {
    if (task.deadline == null) return '';

    final duration = task.timeUntilDeadline;
    if (duration == null || duration.isNegative) return 'Просрочено';

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) {
      return 'Осталось: $days д. $hours ч.';
    } else if (hours > 0) {
      return 'Осталось: $hours ч. $minutes мин.';
    } else {
      return 'Осталось: $minutes мин.';
    }
  }
}
