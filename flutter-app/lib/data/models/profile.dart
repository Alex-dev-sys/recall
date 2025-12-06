class Profile {
  final String id;
  final int? telegramUserId;
  final String? encryptedSession;
  final String? onesignalPlayerId;
  final String? phoneNumber;
  final String? firstName;
  final String? lastName;
  final String? username;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile({
    required this.id,
    this.telegramUserId,
    this.encryptedSession,
    this.onesignalPlayerId,
    this.phoneNumber,
    this.firstName,
    this.lastName,
    this.username,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      telegramUserId: json['telegram_user_id'] as int?,
      encryptedSession: json['encrypted_session'] as String?,
      onesignalPlayerId: json['onesignal_player_id'] as String?,
      phoneNumber: json['phone_number'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      username: json['username'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'telegram_user_id': telegramUserId,
      'encrypted_session': encryptedSession,
      'onesignal_player_id': onesignalPlayerId,
      'phone_number': phoneNumber,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Profile copyWith({
    String? id,
    int? telegramUserId,
    String? encryptedSession,
    String? onesignalPlayerId,
    String? phoneNumber,
    String? firstName,
    String? lastName,
    String? username,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      telegramUserId: telegramUserId ?? this.telegramUserId,
      encryptedSession: encryptedSession ?? this.encryptedSession,
      onesignalPlayerId: onesignalPlayerId ?? this.onesignalPlayerId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (username != null) {
      return '@$username';
    } else if (phoneNumber != null) {
      return phoneNumber!;
    } else {
      return 'User';
    }
  }

  String get initials {
    if (firstName != null) {
      final first = firstName![0].toUpperCase();
      final last = lastName != null ? lastName![0].toUpperCase() : '';
      return '$first$last';
    } else if (username != null) {
      return username![0].toUpperCase();
    } else {
      return 'U';
    }
  }
}
