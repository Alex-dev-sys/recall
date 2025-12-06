import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/task.dart';
import 'priority_badge.dart';

class TaskCardGlass extends StatefulWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onMarkDone;

  const TaskCardGlass({
    super.key,
    required this.task,
    this.onTap,
    this.onMarkDone,
  });

  @override
  State<TaskCardGlass> createState() => _TaskCardGlassState();
}

class _TaskCardGlassState extends State<TaskCardGlass>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = widget.task.isOverdue;

    // Priority gradient colors
    List<Color> gradientColors = _getPriorityGradient(widget.task.priority);

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.8),
                          Colors.white.withValues(alpha: 0.4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isOverdue
                            ? Colors.red.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors[0].withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Gradient accent on left
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 6,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: gradientColors,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(24),
                                bottomLeft: Radius.circular(24),
                              ),
                            ),
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  PriorityBadge(priority: widget.task.priority),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.task.content,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            letterSpacing: -0.3,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (widget.task.deadline != null) ...[
                                          const SizedBox(height: 8),
                                          _buildDeadlineChip(context),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (widget.onMarkDone != null)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.check_circle_rounded),
                                        color: Colors.green,
                                        iconSize: 28,
                                        onPressed: widget.onMarkDone,
                                        tooltip: 'Выполнено',
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Quote section
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary.withValues(alpha: 0.05),
                                      theme.colorScheme.secondary.withValues(alpha: 0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.format_quote_rounded,
                                      size: 18,
                                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        widget.task.originalQuote,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontStyle: FontStyle.italic,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                          height: 1.4,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Footer row
                              Row(
                                children: [
                                  _buildTypeChip(context),
                                  const Spacer(),
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 14,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatCreatedAt(widget.task.createdAt),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Color> _getPriorityGradient(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return [const Color(0xFFEF4444), const Color(0xFFFB923C)];
      case 'high':
        return [const Color(0xFFF97316), const Color(0xFFFBBF24)];
      case 'medium':
        return [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)];
      case 'low':
        return [const Color(0xFF10B981), const Color(0xFF06B6D4)];
      default:
        return [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
    }
  }

  Widget _buildDeadlineChip(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = widget.task.isOverdue;
    final timeUntil = widget.task.timeUntilDeadline;

    Color bgColor;
    Color textColor;
    IconData icon;
    String text;

    if (isOverdue) {
      bgColor = Colors.red.withValues(alpha: 0.15);
      textColor = Colors.red;
      icon = Icons.alarm_off_rounded;
      text = 'Просрочено';
    } else if (timeUntil != null && timeUntil.inHours < 24) {
      bgColor = Colors.orange.withValues(alpha: 0.15);
      textColor = Colors.orange;
      icon = Icons.alarm_on_rounded;
      text = _formatDeadline(widget.task.deadline!);
    } else {
      bgColor = theme.colorScheme.primary.withValues(alpha: 0.15);
      textColor = theme.colorScheme.primary;
      icon = Icons.schedule_rounded;
      text = _formatDeadline(widget.task.deadline!);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(BuildContext context) {
    final theme = Theme.of(context);
    final typeLabel = _getTaskTypeLabel(widget.task.taskType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.6),
            theme.colorScheme.tertiaryContainer.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        typeLabel,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  String _getTaskTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'request':
        return '📋 Просьба';
      case 'promise':
        return '🤝 Обещание';
      case 'agreement':
        return '📅 Встреча';
      case 'reminder':
        return '⏰ Напоминание';
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
      return 'Сегодня ${DateFormat('HH:mm').format(deadline)}';
    } else if (deadlineDate == tomorrow) {
      return 'Завтра ${DateFormat('HH:mm').format(deadline)}';
    } else if (deadline.year == now.year) {
      return DateFormat('d MMM HH:mm', 'ru_RU').format(deadline);
    } else {
      return DateFormat('d MMM yyyy', 'ru_RU').format(deadline);
    }
  }

  String _formatCreatedAt(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'только что';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}м назад';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}ч назад';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}д назад';
    } else {
      return DateFormat('d MMM', 'ru_RU').format(date);
    }
  }
}
