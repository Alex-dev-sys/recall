import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/task.dart';
import 'priority_badge.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onMarkDone;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onMarkDone,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = task.isOverdue;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOverdue
            ? BorderSide(color: Colors.red.withValues(alpha: 0.5), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PriorityBadge(priority: task.priority),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.content,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (task.deadline != null) ...[
                          const SizedBox(height: 8),
                          _buildDeadlineInfo(context),
                        ],
                      ],
                    ),
                  ),
                  if (onMarkDone != null)
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      color: Colors.green,
                      onPressed: onMarkDone,
                      tooltip: 'Отметить как выполнено',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.format_quote,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.originalQuote,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTypeChip(context),
                  const Spacer(),
                  Text(
                    _formatCreatedAt(task.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeadlineInfo(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = task.isOverdue;
    final timeUntil = task.timeUntilDeadline;

    Color color;
    IconData icon;
    String text;

    if (isOverdue) {
      color = Colors.red;
      icon = Icons.alarm_off;
      text = 'Просрочено';
    } else if (timeUntil != null && timeUntil.inHours < 24) {
      color = Colors.orange;
      icon = Icons.alarm;
      text = 'До ${_formatDeadline(task.deadline!)}';
    } else {
      color = theme.colorScheme.primary;
      icon = Icons.access_time;
      text = _formatDeadline(task.deadline!);
    }

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip(BuildContext context) {
    final theme = Theme.of(context);
    final typeLabel = _getTaskTypeLabel(task.taskType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        typeLabel,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getTaskTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'request':
        return 'Просьба';
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

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);

    if (deadlineDate == today) {
      return 'Сегодня, ${DateFormat('HH:mm').format(deadline)}';
    } else if (deadlineDate == tomorrow) {
      return 'Завтра, ${DateFormat('HH:mm').format(deadline)}';
    } else if (deadline.year == now.year) {
      return DateFormat('d MMM, HH:mm', 'ru_RU').format(deadline);
    } else {
      return DateFormat('d MMM yyyy, HH:mm', 'ru_RU').format(deadline);
    }
  }

  String _formatCreatedAt(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Только что';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ч назад';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} д назад';
    } else {
      return DateFormat('d MMM', 'ru_RU').format(date);
    }
  }
}
