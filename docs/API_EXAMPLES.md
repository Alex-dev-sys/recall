# Recall API - Examples

Примеры использования REST API для интеграции с Flutter или другими клиентами.

## Base URL

```
http://localhost:8000
```

В production замените на ваш домен.

---

## Authentication Flow

### 1. Request Verification Code

**Endpoint:** `POST /auth/request-code`

**Request:**
```json
{
  "phone_number": "+79991234567"
}
```

**Response:**
```json
{
  "success": true,
  "phone_code_hash": "1234567890abcdef",
  "message": "Verification code sent to +79991234567"
}
```

**cURL:**
```bash
curl -X POST http://localhost:8000/auth/request-code \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "+79991234567"}'
```

**Flutter:**
```dart
final response = await dio.post(
  '$baseUrl/auth/request-code',
  data: {'phone_number': phoneNumber},
);

final phoneCodeHash = response.data['phone_code_hash'];
```

---

### 2. Verify Code and Login

**Endpoint:** `POST /auth/verify-code`

**Request:**
```json
{
  "phone_number": "+79991234567",
  "code": "12345",
  "phone_code_hash": "1234567890abcdef",
  "password": "optional_2fa_password"
}
```

**Response:**
```json
{
  "success": true,
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "message": "Login successful"
}
```

**cURL:**
```bash
curl -X POST http://localhost:8000/auth/verify-code \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "+79991234567",
    "code": "12345",
    "phone_code_hash": "1234567890abcdef"
  }'
```

**Flutter:**
```dart
final response = await dio.post(
  '$baseUrl/auth/verify-code',
  data: {
    'phone_number': phoneNumber,
    'code': code,
    'phone_code_hash': phoneCodeHash,
  },
);

final userId = response.data['user_id'];
// Сохраните userId в SharedPreferences
await prefs.setString('user_id', userId);
```

---

## Chat Management

### 3. Get User's Chat List

**Endpoint:** `GET /chats/list/{user_id}`

**Response:**
```json
{
  "chats": [
    {
      "chat_id": 123456789,
      "title": "Рабочий чат",
      "type": "group",
      "username": null,
      "photo_exists": true,
      "unread_count": 5,
      "is_monitored": true
    },
    {
      "chat_id": 987654321,
      "title": "Иван Петров",
      "type": "private",
      "username": "ivan_petrov",
      "photo_exists": false,
      "unread_count": 0,
      "is_monitored": false
    }
  ]
}
```

**cURL:**
```bash
curl http://localhost:8000/chats/list/550e8400-e29b-41d4-a716-446655440000
```

**Flutter:**
```dart
final response = await dio.get('$baseUrl/chats/list/$userId');
final chats = (response.data['chats'] as List)
    .map((json) => Chat.fromJson(json))
    .toList();
```

---

### 4. Toggle Chat Monitoring

**Endpoint:** `POST /chats/toggle/{user_id}`

**Request:**
```json
{
  "chat_id": 123456789,
  "chat_title": "Рабочий чат",
  "chat_type": "group",
  "action": "add"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Chat 'Рабочий чат' added to monitoring"
}
```

**Action values:**
- `"add"` - Добавить чат в мониторинг
- `"remove"` - Убрать чат из мониторинга

**cURL:**
```bash
# Добавить чат
curl -X POST http://localhost:8000/chats/toggle/550e8400-e29b-41d4-a716-446655440000 \
  -H "Content-Type: application/json" \
  -d '{
    "chat_id": 123456789,
    "chat_title": "Рабочий чат",
    "chat_type": "group",
    "action": "add"
  }'

# Убрать чат
curl -X POST http://localhost:8000/chats/toggle/550e8400-e29b-41d4-a716-446655440000 \
  -H "Content-Type: application/json" \
  -d '{
    "chat_id": 123456789,
    "chat_title": "Рабочий чат",
    "chat_type": "group",
    "action": "remove"
  }'
```

**Flutter:**
```dart
Future<void> toggleChat(int chatId, String title, bool enable) async {
  await dio.post(
    '$baseUrl/chats/toggle/$userId',
    data: {
      'chat_id': chatId,
      'chat_title': title,
      'chat_type': 'group',
      'action': enable ? 'add' : 'remove',
    },
  );
}
```

---

## Task Management

### 5. Get Active Tasks

**Endpoint:** `GET /tasks/active/{user_id}?limit=50`

**Query Parameters:**
- `limit` (optional, default: 50) - Максимальное количество задач

**Response:**
```json
{
  "tasks": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "user_id": "550e8400-e29b-41d4-a716-446655440000",
      "chat_id": 123456789,
      "message_id": 42,
      "content": "Отправить отчет клиенту",
      "original_quote": "можешь отправить мне тот отчет",
      "task_type": "request",
      "priority": "urgent",
      "deadline": "2024-12-02T16:00:00Z",
      "deadline_is_precise": false,
      "status": "new",
      "source_link": "https://t.me/c/123456789/42",
      "confidence": 0.95,
      "is_duplicate": false,
      "created_at": "2024-12-02T14:00:00Z",
      "updated_at": "2024-12-02T14:00:00Z"
    }
  ]
}
```

**cURL:**
```bash
curl http://localhost:8000/tasks/active/550e8400-e29b-41d4-a716-446655440000?limit=20
```

**Flutter:**
```dart
final response = await dio.get(
  '$baseUrl/tasks/active/$userId',
  queryParameters: {'limit': 50},
);

final tasks = (response.data['tasks'] as List)
    .map((json) => Task.fromJson(json))
    .toList();
```

---

### 6. Update Task Status

**Endpoint:** `PUT /tasks/{task_id}/status?status=done`

**Headers:**
- `X-User-Id` (optional) - User ID для дополнительной проверки

**Query Parameters:**
- `status` (required) - Новый статус задачи

**Status values:**
- `new` - Новая задача
- `acknowledged` - Пользователь увидел
- `in_progress` - В работе
- `done` - Выполнена
- `cancelled` - Отменена

**Response:**
```json
{
  "success": true,
  "message": "Task status updated to done"
}
```

**cURL:**
```bash
curl -X PUT "http://localhost:8000/tasks/550e8400-e29b-41d4-a716-446655440001/status?status=done" \
  -H "X-User-Id: 550e8400-e29b-41d4-a716-446655440000"
```

**Flutter:**
```dart
Future<void> markTaskAsDone(String taskId) async {
  await dio.put(
    '$baseUrl/tasks/$taskId/status',
    queryParameters: {'status': 'done'},
    options: Options(headers: {'X-User-Id': userId}),
  );
}
```

---

## Profile Management

### 7. Get User Profile

**Endpoint:** `GET /profile/{user_id}`

**Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "telegram_user_id": 123456789,
  "phone_number": "+79991234567",
  "first_name": "Иван",
  "last_name": "Петров",
  "username": "ivan_petrov",
  "fcm_token": "fcm_token_here",
  "is_active": true,
  "created_at": "2024-12-01T10:00:00Z",
  "updated_at": "2024-12-02T14:00:00Z"
}
```

**cURL:**
```bash
curl http://localhost:8000/profile/550e8400-e29b-41d4-a716-446655440000
```

**Flutter:**
```dart
final response = await dio.get('$baseUrl/profile/$userId');
final profile = Profile.fromJson(response.data);
```

---

### 8. Update FCM Token

**Endpoint:** `POST /profile/fcm-token/{user_id}`

**Request:**
```json
{
  "fcm_token": "firebase_cloud_messaging_token_here"
}
```

**Response:**
```json
{
  "success": true,
  "message": "FCM token updated"
}
```

**cURL:**
```bash
curl -X POST http://localhost:8000/profile/fcm-token/550e8400-e29b-41d4-a716-446655440000 \
  -H "Content-Type: application/json" \
  -d '{"fcm_token": "fcm_token_here"}'
```

**Flutter:**
```dart
// Получите FCM token
final fcmToken = await FirebaseMessaging.instance.getToken();

// Отправьте на сервер
await dio.post(
  '$baseUrl/profile/fcm-token/$userId',
  data: {'fcm_token': fcmToken},
);
```

---

## Health Check

### 9. System Health

**Endpoint:** `GET /health`

**Response:**
```json
{
  "status": "healthy",
  "worker_running": true,
  "active_sessions": 5
}
```

**cURL:**
```bash
curl http://localhost:8000/health
```

---

## Error Handling

### Error Response Format

Все ошибки возвращают следующий формат:

```json
{
  "detail": "Error message description"
}
```

### HTTP Status Codes

- `200 OK` - Успешный запрос
- `400 Bad Request` - Некорректные данные
- `401 Unauthorized` - Неавторизованный доступ
- `404 Not Found` - Ресурс не найден
- `500 Internal Server Error` - Ошибка сервера

### Примеры ошибок

**Invalid phone number:**
```json
{
  "detail": "Invalid phone number format"
}
```

**Invalid verification code:**
```json
{
  "detail": "PhoneCodeInvalid: The verification code is incorrect"
}
```

**User session not found:**
```json
{
  "detail": "User session not found"
}
```

---

## Complete Flutter Integration Example

### API Service Class

```dart
import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio;
  final String baseUrl;
  final String userId;

  ApiService({
    required this.baseUrl,
    required this.userId,
  }) : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: Duration(seconds: 30),
          receiveTimeout: Duration(seconds: 30),
        )) {
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  // Authentication
  Future<String> requestCode(String phoneNumber) async {
    final response = await _dio.post('/auth/request-code', data: {
      'phone_number': phoneNumber,
    });
    return response.data['phone_code_hash'];
  }

  Future<String> verifyCode({
    required String phoneNumber,
    required String code,
    required String phoneCodeHash,
    String? password,
  }) async {
    final response = await _dio.post('/auth/verify-code', data: {
      'phone_number': phoneNumber,
      'code': code,
      'phone_code_hash': phoneCodeHash,
      if (password != null) 'password': password,
    });
    return response.data['user_id'];
  }

  // Chats
  Future<List<Chat>> getChatList() async {
    final response = await _dio.get('/chats/list/$userId');
    return (response.data['chats'] as List)
        .map((json) => Chat.fromJson(json))
        .toList();
  }

  Future<void> toggleChat({
    required int chatId,
    required String chatTitle,
    required String chatType,
    required bool enable,
  }) async {
    await _dio.post('/chats/toggle/$userId', data: {
      'chat_id': chatId,
      'chat_title': chatTitle,
      'chat_type': chatType,
      'action': enable ? 'add' : 'remove',
    });
  }

  // Tasks
  Future<List<Task>> getActiveTasks({int limit = 50}) async {
    final response = await _dio.get(
      '/tasks/active/$userId',
      queryParameters: {'limit': limit},
    );
    return (response.data['tasks'] as List)
        .map((json) => Task.fromJson(json))
        .toList();
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    await _dio.put(
      '/tasks/$taskId/status',
      queryParameters: {'status': status},
      options: Options(headers: {'X-User-Id': userId}),
    );
  }

  // Profile
  Future<Profile> getProfile() async {
    final response = await _dio.get('/profile/$userId');
    return Profile.fromJson(response.data);
  }

  Future<void> updateFcmToken(String fcmToken) async {
    await _dio.post('/profile/fcm-token/$userId', data: {
      'fcm_token': fcmToken,
    });
  }

  // Health
  Future<Map<String, dynamic>> healthCheck() async {
    final response = await _dio.get('/health');
    return response.data;
  }
}
```

### Usage Example

```dart
// Initialize
final apiService = ApiService(
  baseUrl: 'http://10.0.2.2:8000',  // Android emulator
  userId: savedUserId,
);

// Login flow
try {
  // Step 1: Request code
  final phoneCodeHash = await apiService.requestCode('+79991234567');

  // Step 2: User enters code
  final code = '12345'; // from user input

  // Step 3: Verify
  final userId = await apiService.verifyCode(
    phoneNumber: '+79991234567',
    code: code,
    phoneCodeHash: phoneCodeHash,
  );

  // Save userId
  await prefs.setString('user_id', userId);

} on DioException catch (e) {
  if (e.response?.statusCode == 400) {
    print('Invalid code: ${e.response?.data['detail']}');
  }
}

// Get tasks
final tasks = await apiService.getActiveTasks();

// Mark task as done
await apiService.updateTaskStatus(taskId, 'done');
```

---

## Testing with Postman

### Import Collection

Создайте Postman collection с этими endpoints:

```json
{
  "info": {
    "name": "Recall API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "variable": [
    {
      "key": "base_url",
      "value": "http://localhost:8000"
    },
    {
      "key": "user_id",
      "value": "550e8400-e29b-41d4-a716-446655440000"
    }
  ]
}
```

---

## Rate Limiting (To Be Implemented)

В production добавьте rate limiting:

```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@app.post("/auth/request-code")
@limiter.limit("5/minute")  # 5 requests per minute
async def request_code(request: Request, ...):
    ...
```

---

**API Version:** 1.0.0
**Last Updated:** 2024-12-02
