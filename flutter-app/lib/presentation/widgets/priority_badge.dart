import 'package:flutter/material.dart';

class PriorityBadge extends StatelessWidget {
  final String priority;
  final bool showLabel;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getPriorityConfig(priority);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: config.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: 14,
            color: config.color,
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              config.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: config.color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  _PriorityConfig _getPriorityConfig(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return _PriorityConfig(
          color: Colors.red,
          icon: Icons.warning_rounded,
          label: 'Срочно',
        );
      case 'high':
        return _PriorityConfig(
          color: Colors.orange,
          icon: Icons.flag_rounded,
          label: 'Высокий',
        );
      case 'medium':
        return _PriorityConfig(
          color: Colors.blue,
          icon: Icons.info_rounded,
          label: 'Средний',
        );
      case 'low':
        return _PriorityConfig(
          color: Colors.grey,
          icon: Icons.circle_outlined,
          label: 'Низкий',
        );
      default:
        return _PriorityConfig(
          color: Colors.grey,
          icon: Icons.circle_outlined,
          label: priority,
        );
    }
  }
}

class _PriorityConfig {
  final Color color;
  final IconData icon;
  final String label;

  _PriorityConfig({
    required this.color,
    required this.icon,
    required this.label,
  });
}
