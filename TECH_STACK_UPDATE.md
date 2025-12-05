# Обновление технологического стека

## Изменения: Firebase → OneSignal

### ❌ Удалено

- Firebase Cloud Messaging (FCM)
- Firebase Core SDK
- `google-services.json` / `GoogleService-Info.plist`
- Зависимость от Google Services

### ✅ Добавлено

- **OneSignal** для push-уведомлений
- Более простая интеграция
- Единый SDK для Android + iOS
- Бесплатно до 10,000 пользователей

---

## Обновленный стек

### Backend
- **Python 3.10+** - Основной язык
- **Pyrogram** - Telegram UserBot клиент
- **FastAPI** - REST API для Flutter
- **Supabase** - База данных + Auth + Edge Functions
- **OpenAI / Anthropic** - AI для анализа сообщений

### Mobile App
- **Flutter** - Cross-platform UI
- **Riverpod** - State management
- **Supabase Flutter** - Real-time database
- **OneSignal** - Push-уведомления ✨ (НОВОЕ)

### Infrastructure
- **Supabase PostgreSQL** - База данных
- **Supabase Edge Functions (Deno)** - Serverless
- **OneSignal API** - Доставка push ✨ (НОВОЕ)
- **Docker + docker-compose** - Deployment

---

## Что изменилось в файлах

### 1. База данных

**Было:**
```sql
fcm_token TEXT
```

**Стало:**
```sql
onesignal_player_id TEXT
```

### 2. Edge Function

**Было:**
```typescript
const fcmUrl = "https://fcm.googleapis.com/v1/projects/...";
await fetch(fcmUrl, {
  headers: { "Authorization": `Bearer ${FCM_SERVER_KEY}` }
});
```

**Стало:**
```typescript
const oneSignalUrl = "https://onesignal.com/api/v1/notifications";
await fetch(oneSignalUrl, {
  headers: { "Authorization": `Basic ${ONESIGNAL_API_KEY}` }
});
```

### 3. Flutter Dependencies

**Было:**
```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9
```

**Стало:**
```yaml
dependencies:
  onesignal_flutter: ^5.0.0
```

### 4. Flutter Initialization

**Было:**
```dart
await Firebase.initializeApp();
final fcmToken = await FirebaseMessaging.instance.getToken();
```

**Стало:**
```dart
OneSignal.shared.setAppId("YOUR_APP_ID");
final state = await OneSignal.shared.getDeviceState();
final playerId = state?.userId;
```

---

## Преимущества OneSignal

| Аспект | Firebase | OneSignal |
|--------|----------|-----------|
| Настройка | Сложнее | Проще |
| Google Services | Обязательно | Не требуется |
| SDK размер | ~3 MB | ~2 MB |
| Бесплатный план | Безлимит | До 10k users |
| Аналитика | Базовая | Продвинутая |
| A/B тесты | Нет | Есть |
| Segmentation | Ограниченная | Продвинутая |
| In-App Messages | Нет | Есть |

---

## Миграционный путь

Если у вас уже настроен Firebase:

### 1. Обновите базу данных
```sql
ALTER TABLE public.profiles ADD COLUMN onesignal_player_id TEXT;
```

### 2. Обновите Edge Function
```bash
supabase functions deploy send-task-notification
```

### 3. Обновите Flutter App
```bash
flutter pub remove firebase_core firebase_messaging
flutter pub add onesignal_flutter
```

### 4. Переинициализируйте push
```dart
await OneSignalService.initialize();
```

---

## Новые файлы

- [ONESIGNAL_SETUP.md](ONESIGNAL_SETUP.md) - Полный гайд по настройке OneSignal
- `supabase/functions/send-task-notification/index.ts` - Обновлен для OneSignal
- `supabase/migrations/001_initial_schema.sql` - Обновлена таблица profiles

---

## Следующие шаги

1. Создайте аккаунт на [OneSignal.com](https://onesignal.com)
2. Получите App ID и REST API Key
3. Обновите Edge Function секреты:
   ```bash
   supabase secrets set ONESIGNAL_APP_ID=xxx
   supabase secrets set ONESIGNAL_API_KEY=xxx
   ```
4. Интегрируйте в Flutter app (см. [ONESIGNAL_SETUP.md](ONESIGNAL_SETUP.md))

---

**Версия:** 2.0.0 (без Firebase)
**Дата:** 2024-12-02
