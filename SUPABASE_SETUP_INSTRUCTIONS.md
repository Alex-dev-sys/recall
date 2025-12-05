# 🚀 Настройка Supabase для Recall Project

## Твои учетные данные

**Project URL:** `https://pavrkvgztgksaovujeld.supabase.co`
**Project Ref:** `pavrkvgztgksaovujeld`

✅ Ключи сохранены в файле `.mcp-config.json`

---

## Шаг 1: Применение SQL миграции

### Вариант А: Через SQL Editor (рекомендуется)

1. Открой [Supabase Dashboard](https://supabase.com/dashboard/project/pavrkvgztgksaovujeld)
2. Перейди в **SQL Editor** (слева в меню)
3. Нажми **New Query**
4. Скопируй весь SQL из файла `supabase/migrations/001_initial_schema.sql`
5. Вставь в редактор
6. Нажми **Run** или `Ctrl+Enter`

### Вариант Б: Через Supabase CLI (если установлен)

```bash
cd recall-project

# Логин
supabase login

# Линк к проекту
supabase link --project-ref pavrkvgztgksaovujeld

# Применить миграцию
supabase db push
```

---

## Шаг 2: Проверка таблиц

После выполнения миграции проверь, что созданы таблицы:

1. Перейди в **Table Editor**
2. Должны быть видны таблицы:
   - ✅ `profiles`
   - ✅ `monitored_chats`
   - ✅ `tasks`
   - ✅ `task_notifications`
   - ✅ `worker_sessions`

3. Проверь представление:
   - ✅ `active_tasks_view`

---

## Шаг 3: Настройка Database Webhook

1. Перейди в **Database > Webhooks**
2. Нажми **Create a new hook**
3. Заполни:
   - **Name:** `task-notification-trigger`
   - **Table:** `tasks`
   - **Events:** Выбери `INSERT`
   - **Type:** `HTTP Request`
   - **Method:** `POST`
   - **URL:** `https://pavrkvgztgksaovujeld.supabase.co/functions/v1/send-task-notification`
   - **HTTP Headers:**
     ```
     Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBhdnJrdmd6dGdrc2FvdnVqZWxkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ2ODI5MjAsImV4cCI6MjA4MDI1ODkyMH0.XdqIGRJB1RWcouteyhMpkip5jE_L58x04no4xMbXwvU
     Content-Type: application/json
     ```

4. Нажми **Create webhook**

---

## Шаг 4: Deploy Edge Function

### Установка Supabase CLI (если еще не установлен)

```bash
npm install -g supabase
```

### Deploy функции

```bash
cd recall-project

# Логин (если еще не залогинен)
supabase login

# Линк к проекту
supabase link --project-ref pavrkvgztgksaovujeld

# Deploy Edge Function
cd supabase/functions
supabase functions deploy send-task-notification
```

### Установка секретов для OneSignal

После того как получишь ключи от OneSignal:

```bash
supabase secrets set ONESIGNAL_APP_ID=your-app-id-here
supabase secrets set ONESIGNAL_API_KEY=your-rest-api-key-here
```

---

## Шаг 5: Настройка Backend Worker

Обнови конфигурацию в `backend-worker/config/config.yaml`:

```yaml
supabase:
  url: "https://pavrkvgztgksaovujeld.supabase.co"
  service_role_key: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBhdnJrdmd6dGdrc2FvdnVqZWxkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDY4MjkyMCwiZXhwIjoyMDgwMjU4OTIwfQ.sQrchRCQpDClMJieC9hCqW7b9r4kAEJKYvadsiKSthc"
  anon_key: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBhdnJrdmd6dGdrc2FvdnVqZWxkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ2ODI5MjAsImV4cCI6MjA4MDI1ODkyMH0.XdqIGRJB1RWcouteyhMpkip5jE_L58x04no4xMbXwvU"
```

---

## Шаг 6: Настройка Flutter App

Создай файл `lib/core/constants/api_constants.dart`:

```dart
class ApiConstants {
  // Backend API
  static const String baseUrl = 'http://localhost:8000'; // Поменяй на свой IP

  // Supabase
  static const String supabaseUrl = 'https://pavrkvgztgksaovujeld.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBhdnJrdmd6dGdrc2FvdnVqZWxkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ2ODI5MjAsImV4cCI6MjA4MDI1ODkyMH0.XdqIGRJB1RWcouteyhMpkip5jE_L58x04no4xMbXwvU';

  // OneSignal (получи после создания приложения)
  static const String oneSignalAppId = 'YOUR_ONESIGNAL_APP_ID';
}
```

---

## Проверка настройки

### 1. Проверь таблицы

```sql
-- В SQL Editor
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public';
```

Должны вернуться:
- profiles
- monitored_chats
- tasks
- task_notifications
- worker_sessions

### 2. Проверь RLS политики

```sql
SELECT schemaname, tablename, policyname
FROM pg_policies
WHERE schemaname = 'public';
```

Должны быть политики для каждой таблицы.

### 3. Проверь Edge Function

```bash
# Проверь, что функция задеплоена
supabase functions list

# Проверь логи
supabase functions logs send-task-notification
```

### 4. Проверь Database Webhook

В **Database > Webhooks** должен быть активный webhook `task-notification-trigger`.

---

## Следующие шаги

После настройки Supabase:

1. ✅ Получи Telegram API credentials ([my.telegram.org](https://my.telegram.org))
2. ✅ Получи OpenAI API ключ ([platform.openai.com](https://platform.openai.com))
3. ✅ Создай OneSignal приложение ([onesignal.com](https://onesignal.com))
4. ✅ Запусти Python Worker: `python src/worker.py`
5. ✅ Запусти API Server: `python src/api_server.py`
6. ✅ Разработай Flutter приложение

---

## Troubleshooting

### Ошибка: "relation does not exist"

**Решение:** Миграция не применена. Повторите Шаг 1.

### Ошибка: "permission denied"

**Решение:** Проверьте, что используете `service_role_key` в Backend Worker.

### Edge Function не триггерится

**Решение:**
1. Проверьте, что Webhook создан и активен
2. Проверьте URL в webhook (должен быть правильный project ref)
3. Проверьте логи: `supabase functions logs send-task-notification`

---

## Полезные ссылки

- [Supabase Dashboard](https://supabase.com/dashboard/project/pavrkvgztgksaovujeld)
- [SQL Editor](https://supabase.com/dashboard/project/pavrkvgztgksaovujeld/sql/new)
- [Table Editor](https://supabase.com/dashboard/project/pavrkvgztgksaovujeld/editor)
- [Database Webhooks](https://supabase.com/dashboard/project/pavrkvgztgksaovujeld/database/hooks)
- [Edge Functions](https://supabase.com/dashboard/project/pavrkvgztgksaovujeld/functions)

---

**Готово!** После выполнения всех шагов Supabase полностью настроен для Recall Project 🎉
