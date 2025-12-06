class Task {
  final String id;
  final String userId;
  final int chatId;
  final int messageId;
  final String content;
  final String originalQuote;
  final String taskType;
  final String priority;
  final DateTime? deadline;
  final bool deadlineIsPrecise;
  final String status;
  final String? sourceLink;
  final double confidence;
  final bool isDuplicate;
  final String? duplicateOf;
  final Map<String, dynamic>? aiReasoning;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  Task({
    required this.id,
    required this.userId,
    required this.chatId,
    required this.messageId,
    required this.content,
    required this.originalQuote,
    required this.taskType,
    required this.priority,
    this.deadline,
    required this.deadlineIsPrecise,
    required this.status,
    this.sourceLink,
    required this.confidence,
    required this.isDuplicate,
    this.duplicateOf,
    this.aiReasoning,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      chatId: json['chat_id'] as int,
      messageId: json['message_id'] as int,
      content: json['content'] as String,
      originalQuote: json['original_quote'] as String,
      taskType: json['task_type'] as String,
      priority: json['priority'] as String,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      deadlineIsPrecise: json['deadline_is_precise'] as bool? ?? false,
      status: json['status'] as String,
      sourceLink: json['source_link'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      isDuplicate: json['is_duplicate'] as bool? ?? false,
      duplicateOf: json['duplicate_of'] as String?,
      aiReasoning: json['ai_reasoning'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'chat_id': chatId,
      'message_id': messageId,
      'content': content,
      'original_quote': originalQuote,
      'task_type': taskType,
      'priority': priority,
      'deadline': deadline?.toIso8601String(),
      'deadline_is_precise': deadlineIsPrecise,
      'status': status,
      'source_link': sourceLink,
      'confidence': confidence,
      'is_duplicate': isDuplicate,
      'duplicate_of': duplicateOf,
      'ai_reasoning': aiReasoning,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  Task copyWith({
    String? id,
    String? userId,
    int? chatId,
    int? messageId,
    String? content,
    String? originalQuote,
    String? taskType,
    String? priority,
    DateTime? deadline,
    bool? deadlineIsPrecise,
    String? status,
    String? sourceLink,
    double? confidence,
    bool? isDuplicate,
    String? duplicateOf,
    Map<String, dynamic>? aiReasoning,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      chatId: chatId ?? this.chatId,
      messageId: messageId ?? this.messageId,
      content: content ?? this.content,
      originalQuote: originalQuote ?? this.originalQuote,
      taskType: taskType ?? this.taskType,
      priority: priority ?? this.priority,
      deadline: deadline ?? this.deadline,
      deadlineIsPrecise: deadlineIsPrecise ?? this.deadlineIsPrecise,
      status: status ?? this.status,
      sourceLink: sourceLink ?? this.sourceLink,
      confidence: confidence ?? this.confidence,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      duplicateOf: duplicateOf ?? this.duplicateOf,
      aiReasoning: aiReasoning ?? this.aiReasoning,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  bool get isOverdue {
    if (deadline == null) return false;
    return deadline!.isBefore(DateTime.now()) &&
           status != 'done' &&
           status != 'cancelled';
  }

  Duration? get timeUntilDeadline {
    if (deadline == null) return null;
    return deadline!.difference(DateTime.now());
  }
}
