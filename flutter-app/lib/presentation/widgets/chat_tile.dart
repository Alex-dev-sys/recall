import 'package:flutter/material.dart';
import '../../data/models/chat.dart';

class ChatTile extends StatelessWidget {
  final Chat chat;
  final bool isMonitored;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onTap;

  const ChatTile({
    super.key,
    required this.chat,
    required this.isMonitored,
    this.onToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getChatColor(chat.chatType),
        child: Icon(
          _getChatIcon(chat.chatType),
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(
        chat.chatTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        chat.chatTypeLabel,
        style: theme.textTheme.bodySmall,
      ),
      trailing: Switch(
        value: isMonitored,
        onChanged: onToggle,
        activeTrackColor: theme.colorScheme.primaryContainer,
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return theme.colorScheme.primary;
          }
          return theme.colorScheme.outline;
        }),
      ),
      onTap: onTap,
    );
  }

  Color _getChatColor(String type) {
    switch (type.toLowerCase()) {
      case 'private':
        return Colors.blue;
      case 'group':
        return Colors.green;
      case 'supergroup':
        return Colors.purple;
      case 'channel':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getChatIcon(String type) {
    switch (type.toLowerCase()) {
      case 'private':
        return Icons.person;
      case 'group':
        return Icons.group;
      case 'supergroup':
        return Icons.groups;
      case 'channel':
        return Icons.campaign;
      default:
        return Icons.chat;
    }
  }
}
