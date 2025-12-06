class Chat {
  final String id;
  final String userId;
  final int chatId;
  final String chatTitle;
  final String chatType;
  final bool isActive;
  final DateTime addedAt;
  final DateTime? lastMessageAt;
  final bool isMonitored;

  Chat({
    required this.id,
    required this.userId,
    required this.chatId,
    required this.chatTitle,
    required this.chatType,
    required this.isActive,
    required this.addedAt,
    this.lastMessageAt,
    this.isMonitored = false,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      chatId: json['chat_id'] as int,
      chatTitle: json['chat_title'] as String,
      chatType: json['chat_type'] as String,
      isActive: json['is_active'] as bool? ?? true,
      addedAt: DateTime.parse(json['added_at'] as String),
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      isMonitored: json['is_active'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'chat_id': chatId,
      'chat_title': chatTitle,
      'chat_type': chatType,
      'is_active': isActive,
      'added_at': addedAt.toIso8601String(),
      'last_message_at': lastMessageAt?.toIso8601String(),
    };
  }

  Chat copyWith({
    String? id,
    String? userId,
    int? chatId,
    String? chatTitle,
    String? chatType,
    bool? isActive,
    DateTime? addedAt,
    DateTime? lastMessageAt,
    bool? isMonitored,
  }) {
    return Chat(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      chatId: chatId ?? this.chatId,
      chatTitle: chatTitle ?? this.chatTitle,
      chatType: chatType ?? this.chatType,
      isActive: isActive ?? this.isActive,
      addedAt: addedAt ?? this.addedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isMonitored: isMonitored ?? this.isMonitored,
    );
  }

  String get chatTypeLabel {
    switch (chatType) {
      case 'private':
        return 'Личный чат';
      case 'group':
        return 'Группа';
      case 'supergroup':
        return 'Супергруппа';
      case 'channel':
        return 'Канал';
      default:
        return chatType;
    }
  }
}
