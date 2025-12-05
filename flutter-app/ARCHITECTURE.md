# Recall Flutter App - Architecture

## Project Structure

```
lib/
├── main.dart                      # App entry point
├── app.dart                       # MaterialApp setup
│
├── core/                          # Core utilities and constants
│   ├── constants/
│   │   ├── api_constants.dart     # API endpoints
│   │   └── app_constants.dart     # App-wide constants
│   ├── theme/
│   │   ├── app_theme.dart         # Theme configuration
│   │   └── colors.dart            # Color palette
│   └── utils/
│       ├── date_formatter.dart    # Date formatting utilities
│       └── validators.dart        # Input validators
│
├── data/                          # Data layer
│   ├── models/
│   │   ├── task.dart              # Task model
│   │   ├── chat.dart              # Chat model
│   │   └── profile.dart           # Profile model
│   ├── repositories/
│   │   ├── auth_repository.dart   # Authentication operations
│   │   ├── task_repository.dart   # Task CRUD operations
│   │   └── chat_repository.dart   # Chat operations
│   └── services/
│       ├── api_service.dart       # HTTP client wrapper
│       ├── supabase_service.dart  # Supabase client
│       └── fcm_service.dart       # Firebase Cloud Messaging
│
├── presentation/                  # UI layer
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart           # Phone number input
│   │   │   └── verify_code_screen.dart     # Code verification
│   │   ├── home/
│   │   │   ├── home_screen.dart            # Main task list
│   │   │   └── task_detail_screen.dart     # Task details
│   │   ├── chats/
│   │   │   └── chat_selection_screen.dart  # Select chats to monitor
│   │   └── profile/
│   │       └── profile_screen.dart         # User profile & settings
│   │
│   ├── widgets/
│   │   ├── task_card.dart         # Task card widget
│   │   ├── priority_badge.dart    # Priority indicator
│   │   ├── chat_tile.dart         # Chat list item
│   │   └── loading_indicator.dart # Loading spinner
│   │
│   └── providers/                 # State management (Riverpod)
│       ├── auth_provider.dart     # Auth state
│       ├── task_provider.dart     # Task state
│       └── chat_provider.dart     # Chat state
│
└── firebase_options.dart          # Firebase configuration

```

## Dependencies (pubspec.yaml)

```yaml
name: recall_app
description: Task reminder app with Telegram integration
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3

  # Supabase
  supabase_flutter: ^2.0.0

  # Firebase
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9

  # UI
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  lottie: ^2.7.0

  # Utilities
  intl: ^0.18.1
  timeago: ^3.6.0
  url_launcher: ^6.2.2
  share_plus: ^7.2.1

  # HTTP & Data
  dio: ^5.4.0
  json_annotation: ^4.8.1
  freezed_annotation: ^2.4.1

  # Local Storage
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0

  # Notifications
  flutter_local_notifications: ^16.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Code Generation
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
  freezed: ^2.4.6
  riverpod_generator: ^2.3.9

  # Linting
  flutter_lints: ^3.0.1

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/animations/
```

## Key Components

### 1. Authentication Flow

#### login_screen.dart
```dart
// Phone number input screen
// User enters phone number → Call /auth/request-code API
// Navigate to verify_code_screen with phone_code_hash
```

#### verify_code_screen.dart
```dart
// Verification code input
// User enters code → Call /auth/verify-code API
// On success: Save user_id, navigate to home_screen
```

#### auth_provider.dart
```dart
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AsyncValue<User?> build() {
    // Check if user is already logged in
    return AsyncValue.loading();
  }

  Future<void> requestCode(String phoneNumber) async {
    // Call API to request code
  }

  Future<void> verifyCode(String code, String phoneCodeHash) async {
    // Call API to verify code
    // Save user_id to local storage
    // Update state
  }

  Future<void> logout() async {
    // Clear local storage
    // Update state
  }
}
```

### 2. Home Screen (Task List)

#### home_screen.dart
```dart
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Recall'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.push(...),
          ),
        ],
      ),
      body: tasksAsync.when(
        data: (tasks) => TaskListView(tasks: tasks),
        loading: () => ShimmerLoading(),
        error: (error, stack) => ErrorWidget(error),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatSelectionScreen()),
        ),
        child: Icon(Icons.add),
      ),
    );
  }
}
```

#### task_card.dart
```dart
class TaskCard extends StatelessWidget {
  final Task task;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaskDetailScreen(task: task),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PriorityBadge(priority: task.priority),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.content,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (task.deadline != null) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16),
                    SizedBox(width: 4),
                    Text(
                      _formatDeadline(task.deadline!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              SizedBox(height: 8),
              Text(
                task.originalQuote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 3. Chat Selection Screen

#### chat_selection_screen.dart
```dart
class ChatSelectionScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(chatListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Select Chats to Monitor'),
      ),
      body: chatsAsync.when(
        data: (chats) => ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            return ChatTile(
              chat: chat,
              onToggle: (value) {
                ref.read(chatListProvider.notifier).toggleChat(
                  chat.chatId,
                  chat.title,
                  value,
                );
              },
            );
          },
        ),
        loading: () => ShimmerLoading(),
        error: (error, stack) => ErrorWidget(error),
      ),
    );
  }
}
```

#### chat_tile.dart
```dart
class ChatTile extends StatelessWidget {
  final Chat chat;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(chat.title[0].toUpperCase()),
      ),
      title: Text(chat.title),
      subtitle: Text(_getChatTypeLabel(chat.type)),
      trailing: Switch(
        value: chat.isMonitored,
        onChanged: onToggle,
      ),
    );
  }
}
```

### 4. State Management (Riverpod)

#### task_provider.dart
```dart
@riverpod
class TaskList extends _$TaskList {
  @override
  Future<List<Task>> build() async {
    // Load tasks from Supabase
    final userId = ref.watch(authProvider).value?.id;
    if (userId == null) return [];

    final supabase = ref.watch(supabaseServiceProvider);
    final response = await supabase.client
        .from('tasks')
        .select()
        .eq('user_id', userId)
        .not('status', 'in', ['done', 'cancelled'])
        .order('created_at', ascending: false);

    return (response as List).map((json) => Task.fromJson(json)).toList();
  }

  Future<void> markAsDone(String taskId) async {
    final supabase = ref.watch(supabaseServiceProvider);
    await supabase.client
        .from('tasks')
        .update({'status': 'done'})
        .eq('id', taskId);

    // Refresh list
    ref.invalidateSelf();
  }
}
```

#### chat_provider.dart
```dart
@riverpod
class ChatList extends _$ChatList {
  @override
  Future<List<Chat>> build() async {
    // Fetch chat list from API
    final userId = ref.watch(authProvider).value?.id;
    if (userId == null) return [];

    final api = ref.watch(apiServiceProvider);
    final response = await api.get('/chats/list/$userId');

    return (response.data['chats'] as List)
        .map((json) => Chat.fromJson(json))
        .toList();
  }

  Future<void> toggleChat(int chatId, String title, bool enable) async {
    final userId = ref.watch(authProvider).value?.id;
    final api = ref.watch(apiServiceProvider);

    await api.post('/chats/toggle/$userId', data: {
      'chat_id': chatId,
      'chat_title': title,
      'action': enable ? 'add' : 'remove',
    });

    // Refresh list
    ref.invalidateSelf();
  }
}
```

### 5. Firebase Cloud Messaging Setup

#### fcm_service.dart
```dart
class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    final token = await _messaging.getToken();
    print('FCM Token: $token');

    // Send token to backend
    if (token != null) {
      await _sendTokenToBackend(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_sendTokenToBackend);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  Future<void> _sendTokenToBackend(String token) async {
    // Call API to update FCM token
    final dio = Dio();
    final userId = await _getUserId();

    await dio.post(
      'http://your-api/profile/fcm-token/$userId',
      data: {'fcm_token': token},
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification when app is in foreground
    final notification = message.notification;
    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? '',
        body: notification.body ?? '',
        payload: message.data,
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Navigate to task detail screen
    final taskId = message.data['task_id'];
    if (taskId != null) {
      // Navigate to TaskDetailScreen(taskId)
    }
  }
}

// Top-level function for background messages
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  print('Background message: ${message.messageId}');
}
```

### 6. Models

#### task.dart
```dart
@freezed
class Task with _$Task {
  const factory Task({
    required String id,
    required String userId,
    required int chatId,
    required int messageId,
    required String content,
    required String originalQuote,
    required String taskType,
    required String priority,
    String? deadline,
    required bool deadlineIsPrecise,
    required String status,
    required String sourceLink,
    required double confidence,
    required bool isDuplicate,
    String? duplicateOf,
    Map<String, dynamic>? aiReasoning,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? completedAt,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}
```

## Color Coding by Priority

```dart
class PriorityColors {
  static Color getColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  static IconData getIcon(String priority) {
    switch (priority) {
      case 'urgent':
        return Icons.warning_rounded;
      case 'high':
        return Icons.flag_rounded;
      case 'medium':
        return Icons.info_rounded;
      case 'low':
        return Icons.circle_outlined;
      default:
        return Icons.circle_outlined;
    }
  }
}
```

## Real-time Updates with Supabase

```dart
class TaskRealtimeService {
  final SupabaseClient client;
  final String userId;

  late final RealtimeChannel _channel;

  void initialize(Function(Task) onTaskAdded) {
    _channel = client.channel('tasks:$userId')
      ..on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'INSERT',
          schema: 'public',
          table: 'tasks',
          filter: 'user_id=eq.$userId',
        ),
        (payload, [ref]) {
          final task = Task.fromJson(payload['record']);
          onTaskAdded(task);
        },
      )
      ..subscribe();
  }

  void dispose() {
    _channel.unsubscribe();
  }
}
```

## Summary

Архитектура следует принципам Clean Architecture:

1. **Data Layer**: Модели, репозитории, сервисы для API
2. **Presentation Layer**: UI screens, widgets, state providers
3. **Core**: Утилиты, константы, темы

**State Management**: Riverpod для реактивного управления состоянием

**Real-time**: Supabase Realtime для мгновенных обновлений задач

**Push Notifications**: Firebase Cloud Messaging для уведомлений
