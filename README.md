# Recall - AI-Powered Task Reminder System

![Recall Logo](docs/logo.png)

**Recall** - это умная система напоминаний, которая автоматически находит задачи в ваших Telegram-сообщениях с помощью ИИ и отправляет push-уведомления.

## Архитектура

```
┌─────────────────┐      ┌──────────────────┐      ┌─────────────────┐
│  Flutter App    │ ───▶ │  Python Worker   │ ───▶ │   Supabase DB   │
│  (Mobile UI)    │      │  (AI Pipeline)   │      │  (PostgreSQL)   │
└─────────────────┘      └──────────────────┘      └─────────────────┘
         │                        │                          │
         │                        ▼                          │
         │               ┌──────────────┐                   │
         └──────────────▶│  Telegram    │                   │
                         │  (Pyrogram)  │                   │
                         └──────────────┘                   │
                                                             │
         ┌───────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────┐
│  Edge Functions  │
│  (Notifications) │
└──────────────────┘
         │
         ▼
┌──────────────────┐
│  Firebase FCM    │
│  (Push Notify)   │
└──────────────────┘
```

## Стек технологий

### Backend
- **Python 3.10+** - Основной язык
- **Pyrogram** - Telegram UserBot клиент
- **FastAPI** - REST API для Flutter
- **Supabase** - База данных (PostgreSQL) + Authentication
- **OpenAI / Anthropic** - AI для анализа сообщений

### Mobile App
- **Flutter** - Cross-platform мобильное приложение
- **Riverpod** - State management
- **Supabase Flutter** - Real-time database
- **Firebase Messaging** - Push-уведомления

### Notifications
- **Supabase Edge Functions** (Deno) - Serverless функции
- **Firebase Cloud Messaging** - Доставка push-уведомлений

---

## Установка и запуск

### Требования

- Python 3.10+
- Flutter 3.0+
- Node.js 18+ (для Supabase CLI)
- Supabase аккаунт
- Firebase аккаунт
- Telegram API credentials

---

## Шаг 1: Настройка Supabase

### 1.1 Создание проекта

1. Зайдите на [supabase.com](https://supabase.com)
2. Создайте новый проект
3. Скопируйте `Project URL` и `anon/service_role keys`

### 1.2 Применение миграций

```bash
cd supabase
supabase login
supabase link --project-ref your-project-ref
supabase db push
```

Или вручную выполните SQL из `supabase/migrations/001_initial_schema.sql` в SQL Editor.

### 1.3 Настройка Row Level Security (RLS)

RLS уже настроен в миграциях. Проверьте, что политики применились:

```sql
SELECT * FROM pg_policies WHERE tablename IN ('profiles', 'tasks', 'monitored_chats');
```

---

## Шаг 2: Настройка Python Worker

### 2.1 Установка зависимостей

```bash
cd backend-worker
python -m venv venv
source venv/bin/activate  # На Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2.2 Получение Telegram API credentials

1. Зайдите на [my.telegram.org](https://my.telegram.org)
2. Войдите со своим номером телефона
3. Перейдите в **API development tools**
4. Создайте приложение и получите `api_id` и `api_hash`

### 2.3 Получение AI API ключа

#### Для OpenAI:
1. Зайдите на [platform.openai.com](https://platform.openai.com)
2. Создайте API ключ

#### Для Anthropic:
1. Зайдите на [console.anthropic.com](https://console.anthropic.com)
2. Создайте API ключ

### 2.4 Настройка конфигурации

Скопируйте пример конфига:

```bash
cp config/config.example.yaml config/config.yaml
```

Отредактируйте `config/config.yaml`:

```yaml
supabase:
  url: "https://your-project.supabase.co"
  service_role_key: "your-service-role-key"

telegram:
  api_id: 12345678
  api_hash: "your-api-hash"
  session_encryption_key: "your-32-byte-key"  # Сгенерируйте: python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"

ai:
  provider: "openai"
  model: "gpt-4o-mini"
  api_key: "your-openai-api-key"
```

### 2.5 Запуск Worker

```bash
python src/worker.py
```

### 2.6 Запуск API Server (для Flutter)

В отдельном терминале:

```bash
python src/api_server.py
```

API будет доступен на `http://localhost:8000`

Документация: `http://localhost:8000/docs`

---

## Шаг 3: Настройка Edge Functions

### 3.1 Установка Supabase CLI

```bash
npm install -g supabase
```

### 3.2 Deploy Edge Function

```bash
cd supabase/functions
supabase functions deploy send-task-notification
```

### 3.3 Настройка переменных окружения

```bash
supabase secrets set FCM_SERVER_KEY=your-fcm-server-key
```

### 3.4 Создание Database Webhook

1. Зайдите в Supabase Dashboard
2. **Database > Webhooks**
3. **Create a new hook**:
   - Table: `tasks`
   - Events: `INSERT`
   - URL: `https://your-project.supabase.co/functions/v1/send-task-notification`
   - Headers: `Authorization: Bearer YOUR_ANON_KEY`

---

## Шаг 4: Настройка Flutter App

### 4.1 Установка Flutter

Следуйте инструкциям на [flutter.dev](https://flutter.dev/docs/get-started/install)

### 4.2 Настройка Firebase

1. Создайте проект на [Firebase Console](https://console.firebase.google.com)
2. Добавьте Android/iOS приложения
3. Скачайте `google-services.json` (Android) и `GoogleService-Info.plist` (iOS)
4. Поместите файлы в соответствующие папки

### 4.3 Настройка Firebase Cloud Messaging

1. В Firebase Console: **Project Settings > Cloud Messaging**
2. Включите **Cloud Messaging API**
3. Скопируйте **Server Key** для Edge Functions

### 4.4 Установка зависимостей

```bash
cd flutter-app
flutter pub get
```

### 4.5 Генерация кода

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4.6 Настройка API endpoint

Создайте файл `lib/core/constants/api_constants.dart`:

```dart
class ApiConstants {
  static const String baseUrl = 'http://YOUR_SERVER_IP:8000';
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
}
```

### 4.7 Запуск приложения

```bash
flutter run
```

---

## Workflow использования

### 1. Первый запуск (пользователь)

1. Пользователь открывает Flutter app
2. Вводит номер телефона
3. Получает код от Telegram
4. Вводит код → Завершает авторизацию
5. Python Worker создает сессию Pyrogram для пользователя

### 2. Выбор чатов для мониторинга

1. Пользователь нажимает "+" в приложении
2. Видит список всех своих Telegram-чатов
3. Выбирает чаты галочками (add/remove)
4. Сохраняется в таблице `monitored_chats`

### 3. Автоматическое извлечение задач

1. Пользователь получает сообщение в Telegram (в отслеживаемом чате)
2. Python Worker перехватывает сообщение через Pyrogram
3. AI Pipeline анализирует текст:
   - **Extractor**: Находит задачи
   - **Deduplicator**: Проверяет дубликаты
   - **Deadline Parser**: Определяет сроки
   - **Prioritizer**: Назначает приоритет
4. Задача сохраняется в таблицу `tasks`

### 4. Push-уведомления

1. Database Webhook триггерит Edge Function
2. Edge Function отправляет push через FCM
3. Пользователь получает уведомление на телефон
4. Клик на уведомление → Открывается детальная страница задачи

### 5. Управление задачами

1. Пользователь видит список задач в Flutter app
2. Цветовая индикация по приоритету
3. Может отметить задачу как выполненную (swipe или кнопка)
4. Real-time обновления через Supabase Realtime

---

## Примеры AI-анализа

### Пример 1: Срочная задача

**Входное сообщение:**
> "Привет! Можешь срочно отправить мне тот отчет? Клиент ждет!"

**AI Pipeline:**

1. **Extractor:**
   ```json
   {
     "task_text": "Отправить отчет",
     "original_quote": "отправить мне тот отчет",
     "task_type": "request",
     "deadline_hint": "срочно",
     "confidence": 0.95
   }
   ```

2. **Deadline Parser:**
   ```json
   {
     "parsed_datetime": "2024-12-02T16:00:00",
     "is_precise": false,
     "reasoning": "Срочно = +2 часа"
   }
   ```

3. **Prioritizer:**
   ```json
   {
     "priority": "urgent",
     "reasoning": "Ключевое слово 'срочно' + упоминание клиента"
   }
   ```

**Результат:** Задача с приоритетом 🔴 URGENT, дедлайн через 2 часа

---

### Пример 2: Обещание с дедлайном

**Входное сообщение:**
> "Окей, я сделаю презентацию к пятнице вечером"

**AI Pipeline:**

1. **Extractor:**
   ```json
   {
     "task_text": "Сделать презентацию",
     "task_type": "promise",
     "deadline_hint": "к пятнице вечером",
     "confidence": 1.0
   }
   ```

2. **Deadline Parser:**
   ```json
   {
     "parsed_datetime": "2024-12-06T18:00:00",
     "is_precise": false
   }
   ```

3. **Prioritizer:**
   ```json
   {
     "priority": "medium",
     "reasoning": "Дедлайн через 4 дня, обычная рабочая задача"
   }
   ```

**Результат:** Задача с приоритетом 🔵 MEDIUM, дедлайн в пятницу 18:00

---

## Мониторинг и логи

### Python Worker логи

```bash
tail -f logs/recall_worker.log
```

### Edge Function логи

```bash
supabase functions logs send-task-notification --follow
```

### База данных

Проверка активных задач:

```sql
SELECT * FROM active_tasks_view;
```

Проверка отправленных уведомлений:

```sql
SELECT * FROM task_notifications ORDER BY sent_at DESC LIMIT 10;
```

---

## Production Deployment

### Backend (Python Worker + API)

Рекомендуется использовать:
- **Docker** + **docker-compose**
- **Systemd** для автозапуска
- **Nginx** для reverse proxy API

Пример `docker-compose.yml` можно найти в `backend-worker/docker-compose.example.yml`

### Flutter App

```bash
# Android
flutter build apk --release

# iOS
flutter build ipa --release
```

### Мониторинг

- Логи в файл + **Logstash** / **Loki**
- Метрики через **Prometheus**
- Алерты через **Grafana**

---

## Безопасность

### ✅ Что уже реализовано:

1. **Шифрование сессий** - Pyrogram session strings хранятся зашифрованными (Fernet)
2. **Row Level Security** - Пользователи видят только свои данные
3. **Service Role для Worker** - Backend использует service_role_key с полными правами
4. **Валидация на уровне БД** - CHECK constraints для enum-полей

### ⚠️ Рекомендации для production:

1. Используйте **HTTPS** для API
2. Храните ключи в **переменных окружения** или **секрет-менеджере** (HashiCorp Vault, AWS Secrets Manager)
3. Настройте **rate limiting** в FastAPI
4. Включите **Database Webhook signature verification**
5. Ограничьте CORS только вашими доменами
6. Включите **2FA** для Supabase Dashboard

---

## Тестирование

### Юнит-тесты Python

```bash
cd backend-worker
pytest tests/
```

### Тестирование AI Pipeline

```bash
python src/ai_pipeline.py
```

### Тестирование Edge Function локально

```bash
supabase functions serve send-task-notification
```

---

## Troubleshooting

### Проблема: Worker не получает сообщения

**Решение:**
1. Проверьте, что чат добавлен в `monitored_chats`
2. Проверьте логи: `tail -f logs/recall_worker.log`
3. Убедитесь, что Pyrogram сессия активна

### Проблема: Push-уведомления не приходят

**Решение:**
1. Проверьте FCM token в таблице `profiles`
2. Проверьте логи Edge Function
3. Проверьте, что Database Webhook активен
4. Тестируйте FCM через Firebase Console

### Проблема: AI возвращает неправильные результаты

**Решение:**
1. Проверьте используемую модель (например, `gpt-4o-mini` может быть точнее)
2. Настройте `min_confidence_threshold` в конфиге
3. Проверьте промпты в `src/prompts.py`
4. Включите дебаг-логи: `log_level: DEBUG`

---

## Roadmap

- [ ] Web-версия на Next.js
- [ ] Поддержка WhatsApp через Baileys
- [ ] Голосовые сообщения (Speech-to-Text)
- [ ] Интеграция с календарем (Google Calendar, Outlook)
- [ ] Командная работа (shared tasks)
- [ ] Аналитика продуктивности

---

## Лицензия

MIT License

---

## Контакты

- **Telegram**: @your_username
- **Email**: your@email.com
- **GitHub**: https://github.com/yourusername/recall-project

---

## Благодарности

- [Pyrogram](https://docs.pyrogram.org) - Telegram MTProto клиент
- [Supabase](https://supabase.com) - Open source Firebase alternative
- [OpenAI](https://openai.com) - GPT models for AI analysis
- [Flutter](https://flutter.dev) - Beautiful cross-platform UI

---

**Made with ❤️ by [Your Name]**
