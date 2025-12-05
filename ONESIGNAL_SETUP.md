# Push-уведомления через OneSignal (без Firebase)

## Почему OneSignal вместо Firebase?

- ✅ Бесплатно до 10,000 пользователей
- ✅ Нет зависимости от Google Services
- ✅ Единый SDK для Android + iOS
- ✅ Простая интеграция с Flutter
- ✅ Работает напрямую из Supabase Edge Functions

---

## Изменения в проекте

### 1. База данных (profiles)

```sql
-- Вместо fcm_token используем onesignal_player_id
CREATE TABLE public.profiles (
    ...
    onesignal_player_id TEXT,  -- ← Изменено
    ...
);
```

### 2. Edge Function

Теперь использует OneSignal API вместо FCM:

```typescript
// Вместо Firebase Cloud Messaging
const response = await fetch("https://onesignal.com/api/v1/notifications", {
  method: "POST",
  headers: {
    "Authorization": `Basic ${ONESIGNAL_API_KEY}`,
  },
  body: JSON.stringify({
    app_id: ONESIGNAL_APP_ID,
    include_player_ids: [playerId],
    headings: { ru: title },
    contents: { ru: body },
  }),
});
```

### 3. Flutter App

#### pubspec.yaml

```yaml
dependencies:
  # Вместо firebase_messaging используем onesignal_flutter
  onesignal_flutter: ^5.0.0

  # Supabase остается
  supabase_flutter: ^2.0.0
```

#### Инициализация OneSignal

```dart
// main.dart
import 'package:onesignal_flutter/onesignal_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация OneSignal
  OneSignal.shared.setAppId("YOUR_ONESIGNAL_APP_ID");

  // Запрос разрешений
  await OneSignal.shared.promptUserForPushNotificationPermission();

  // Получить Player ID
  final status = await OneSignal.shared.getDeviceState();
  final playerId = status?.userId;

  // Отправить на backend
  if (playerId != null) {
    await updateOneSignalPlayerId(playerId);
  }

  // Обработчик нажатий на уведомления
  OneSignal.shared.setNotificationOpenedHandler((OSNotificationOpenedResult result) {
    final taskId = result.notification.additionalData?['task_id'];
    if (taskId != null) {
      // Открыть экран задачи
      navigateToTask(taskId);
    }
  });

  runApp(MyApp());
}
```

---

## Настройка OneSignal

### Шаг 1: Создание приложения

1. Зайдите на [onesignal.com](https://onesignal.com)
2. Создайте аккаунт (бесплатно)
3. **New App/Website**
4. Название: "Recall"
5. Выберите платформы: **Mobile App**

### Шаг 2: Настройка Android

1. **Select Platforms > Android**
2. **Firebase Server Key** - не нужен! OneSignal сам создаст
3. **Configure SDK**:
   ```gradle
   // android/app/build.gradle
   // OneSignal автоматически добавится через Flutter plugin
   ```

### Шаг 3: Настройка iOS

1. **Select Platforms > Apple iOS**
2. Загрузите `.p12` сертификат (или .p8 AuthKey)
3. Следуйте инструкциям OneSignal

### Шаг 4: Получение ключей

1. **Settings > Keys & IDs**
2. Скопируйте:
   - **OneSignal App ID** - для Flutter
   - **REST API Key** - для Edge Function

---

## Настройка Edge Function

### Установка секретов

```bash
supabase secrets set ONESIGNAL_APP_ID=your-app-id
supabase secrets set ONESIGNAL_API_KEY=your-rest-api-key
```

### Deploy

```bash
supabase functions deploy send-task-notification
```

---

## Обновление Backend API

### database.py

```python
async def update_onesignal_player_id(self, user_id: str, player_id: str):
    """Update OneSignal Player ID for push notifications"""
    try:
        self.client.table("profiles").update(
            {"onesignal_player_id": player_id}
        ).eq("id", user_id).execute()

        logger.info(f"OneSignal Player ID updated for user {user_id}")
    except Exception as e:
        logger.error(f"Failed to update OneSignal Player ID: {e}")
        raise
```

### api_server.py

```python
class UpdatePlayerIdRequest(BaseModel):
    player_id: str

@app.post("/profile/onesignal-player-id/{user_id}")
async def update_player_id(user_id: str, request: UpdatePlayerIdRequest):
    """Update OneSignal Player ID"""
    try:
        await db.update_onesignal_player_id(
            user_id=user_id,
            player_id=request.player_id
        )
        return {"success": True, "message": "Player ID updated"}
    except Exception as e:
        logger.error(f"Failed to update Player ID: {e}")
        raise HTTPException(status_code=500, detail=str(e))
```

---

## Flutter Integration Example

### OneSignal Service

```dart
// lib/data/services/onesignal_service.dart
import 'package:onesignal_flutter/onesignal_flutter.dart';

class OneSignalService {
  static Future<void> initialize() async {
    // Установка App ID
    OneSignal.shared.setAppId(ApiConstants.oneSignalAppId);

    // Запрос разрешений
    await OneSignal.shared.promptUserForPushNotificationPermission();

    // Получение Player ID
    final state = await OneSignal.shared.getDeviceState();
    final playerId = state?.userId;

    if (playerId != null) {
      print('OneSignal Player ID: $playerId');
      // Отправить на backend
      await _sendPlayerIdToBackend(playerId);
    }

    // Обработчик уведомлений
    OneSignal.shared.setNotificationOpenedHandler(_handleNotificationOpened);

    // Обработчик получения уведомлений в foreground
    OneSignal.shared.setNotificationWillShowInForegroundHandler(
      _handleNotificationReceived
    );
  }

  static Future<void> _sendPlayerIdToBackend(String playerId) async {
    final dio = Dio();
    final userId = await getUserId(); // Из SharedPreferences

    await dio.post(
      '${ApiConstants.baseUrl}/profile/onesignal-player-id/$userId',
      data: {'player_id': playerId},
    );
  }

  static void _handleNotificationOpened(OSNotificationOpenedResult result) {
    final taskId = result.notification.additionalData?['task_id'];
    if (taskId != null) {
      // Navigate to task detail
      Get.to(() => TaskDetailScreen(taskId: taskId));
    }
  }

  static void _handleNotificationReceived(OSNotificationReceivedEvent event) {
    // Show notification even when app is in foreground
    event.complete(event.notification);
  }
}
```

### Использование

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Supabase
  await Supabase.initialize(
    url: ApiConstants.supabaseUrl,
    anonKey: ApiConstants.supabaseAnonKey,
  );

  // Инициализация OneSignal
  await OneSignalService.initialize();

  runApp(MyApp());
}
```

---

## Тестирование

### 1. Отправка тестового уведомления через OneSignal Dashboard

1. Зайдите в **Messages > New Push**
2. **Send to Test Device**
3. Введите Player ID
4. Отправьте

### 2. Отправка через Edge Function

```bash
# Создайте тестовую задачу в БД
curl -X POST https://your-project.supabase.co/functions/v1/send-task-notification \
  -H "Content-Type: application/json" \
  -d '{
    "type": "INSERT",
    "table": "tasks",
    "record": {
      "id": "test-uuid",
      "user_id": "user-uuid",
      "content": "Тестовая задача",
      "priority": "urgent",
      "deadline": null,
      "source_link": "https://t.me/c/123/456",
      "created_at": "2024-12-02T14:00:00Z"
    }
  }'
```

---

## Сравнение: Firebase vs OneSignal

| Функция | Firebase FCM | OneSignal |
|---------|-------------|-----------|
| Цена | Бесплатно (безлимит) | Бесплатно до 10k users |
| Настройка | Сложнее (нужен Firebase проект) | Проще (без Google Services) |
| SDK размер | ~3 MB | ~2 MB |
| Аналитика | Базовая | Продвинутая |
| A/B тесты | Нет | Есть |
| Segmentation | Ограниченная | Продвинутая |
| In-App Messages | Нет | Есть |

---

## Миграция с Firebase

Если у вас уже был Firebase:

### 1. Обновите таблицу profiles

```sql
-- Добавить новое поле
ALTER TABLE public.profiles ADD COLUMN onesignal_player_id TEXT;

-- Индекс
CREATE INDEX idx_profiles_onesignal_player_id
ON public.profiles(onesignal_player_id)
WHERE onesignal_player_id IS NOT NULL;

-- Опционально: удалить старое поле
-- ALTER TABLE public.profiles DROP COLUMN fcm_token;
```

### 2. Обновите Flutter App

```yaml
# pubspec.yaml
dependencies:
  # Удалите
  # firebase_core: ^2.24.2
  # firebase_messaging: ^14.7.9

  # Добавьте
  onesignal_flutter: ^5.0.0
```

### 3. Переделайте Edge Function

Используйте новый код из `send-task-notification/index.ts`

---

## Troubleshooting

### Проблема: Player ID = null

**Решение:**
1. Проверьте правильность OneSignal App ID
2. Убедитесь, что разрешения на уведомления даны
3. Проверьте:
   ```dart
   final state = await OneSignal.shared.getDeviceState();
   print('Player ID: ${state?.userId}');
   print('Subscribed: ${state?.isSubscribed}');
   ```

### Проблема: Уведомления не приходят

**Решение:**
1. Проверьте Player ID сохранен в БД
2. Проверьте логи Edge Function
3. Отправьте тестовое через OneSignal Dashboard

### Проблема: iOS уведомления не работают

**Решение:**
1. Убедитесь, что загружен правильный `.p12` / `.p8`
2. Проверьте Bundle ID совпадает
3. Включите Push Notifications в Xcode Capabilities

---

## Полезные ссылки

- [OneSignal Docs](https://documentation.onesignal.com/)
- [OneSignal Flutter SDK](https://documentation.onesignal.com/docs/flutter-sdk-setup)
- [OneSignal REST API](https://documentation.onesignal.com/reference/create-notification)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)

---

**Готово!** Теперь у вас push-уведомления работают через OneSignal без Firebase 🎉
