# Recall - System Design Document

## 1. Обзор системы

**Recall** - это интеллектуальная система отслеживания задач, которая автоматически анализирует сообщения в Telegram с помощью ИИ, извлекает задачи и отправляет push-уведомления пользователям.

### Ключевые возможности:
- ✅ Автоматическое извлечение задач из текста
- ✅ Определение приоритета и дедлайнов с помощью ИИ
- ✅ Обнаружение дубликатов
- ✅ Push-уведомления в реальном времени
- ✅ Кроссплатформенное мобильное приложение

---

## 2. Архитектура системы

```
                                    ┌──────────────────────┐
                                    │   Telegram Servers   │
                                    └──────────┬───────────┘
                                               │
                                               │ MTProto
                                               │
                         ┌─────────────────────▼────────────────────┐
                         │                                           │
                         │         PYTHON WORKER (Backend)           │
                         │                                           │
                         │  ┌────────────────────────────────────┐  │
                         │  │  Session Manager (Pyrogram)        │  │
                         │  │  - Multiple user sessions          │  │
                         │  │  - Encrypted session storage       │  │
                         │  └───────────────┬────────────────────┘  │
                         │                  │                        │
                         │  ┌───────────────▼────────────────────┐  │
                         │  │  Message Listener                  │  │
                         │  │  - Monitors selected chats         │  │
                         │  │  - Filters text messages           │  │
                         │  └───────────────┬────────────────────┘  │
                         │                  │                        │
                         │  ┌───────────────▼────────────────────┐  │
                         │  │  AI Pipeline                       │  │
                         │  │                                    │  │
                         │  │  1. Extractor    ─────────────┐   │  │
                         │  │     (Find tasks)              │   │  │
                         │  │                               │   │  │
                         │  │  2. Deduplicator  ◄───────────┤   │  │
                         │  │     (Check duplicates)        │   │  │
                         │  │                               │   │  │
                         │  │  3. Deadline Parser ◄─────────┤   │  │
                         │  │     (Parse dates)             │   │  │
                         │  │                               │   │  │
                         │  │  4. Prioritizer   ◄───────────┘   │  │
                         │  │     (Assign priority)             │  │
                         │  └───────────────┬────────────────────┘  │
                         │                  │                        │
                         └──────────────────┼────────────────────────┘
                                            │
                                            │ Save task
                                            │
                         ┌──────────────────▼────────────────────────┐
                         │                                           │
                         │         SUPABASE (Database)               │
                         │                                           │
                         │  ┌────────────────────────────────────┐  │
                         │  │  PostgreSQL Tables:                │  │
                         │  │  - profiles                        │  │
                         │  │  - monitored_chats                 │  │
                         │  │  - tasks ◄──── (INSERT trigger)    │  │
                         │  │  - task_notifications              │  │
                         │  │  - worker_sessions                 │  │
                         │  └────────────────┬───────────────────┘  │
                         │                   │                       │
                         │  ┌────────────────▼───────────────────┐  │
                         │  │  Database Webhook                  │  │
                         │  │  (on INSERT to tasks)              │  │
                         │  └────────────────┬───────────────────┘  │
                         │                   │                       │
                         └───────────────────┼───────────────────────┘
                                             │
                                             │ HTTP POST
                                             │
                         ┌───────────────────▼───────────────────────┐
                         │                                           │
                         │    EDGE FUNCTION (Supabase/Deno)          │
                         │                                           │
                         │  ┌────────────────────────────────────┐  │
                         │  │  send-task-notification            │  │
                         │  │                                    │  │
                         │  │  1. Get user's FCM token           │  │
                         │  │  2. Format notification            │  │
                         │  │  3. Send via FCM API               │  │
                         │  │  4. Log notification               │  │
                         │  └────────────────┬───────────────────┘  │
                         │                   │                       │
                         └───────────────────┼───────────────────────┘
                                             │
                                             │ FCM API
                                             │
                         ┌───────────────────▼───────────────────────┐
                         │  Firebase Cloud Messaging (FCM)           │
                         │  - Push notification delivery             │
                         │  - Android & iOS support                  │
                         └───────────────────┬───────────────────────┘
                                             │
                                             │ Push
                                             │
                         ┌───────────────────▼───────────────────────┐
                         │                                           │
                         │         FLUTTER APP (Mobile)              │
                         │                                           │
                         │  ┌────────────────────────────────────┐  │
                         │  │  Screens:                          │  │
                         │  │  - Login (phone + code)            │  │
                         │  │  - Home (task list)                │  │
                         │  │  - Chat Selection                  │  │
                         │  │  - Task Detail                     │  │
                         │  │  - Profile/Settings                │  │
                         │  └────────────────────────────────────┘  │
                         │                                           │
                         │  ┌────────────────────────────────────┐  │
                         │  │  State Management (Riverpod)       │  │
                         │  │  - Auth state                      │  │
                         │  │  - Task list (real-time updates)   │  │
                         │  │  - Chat list                       │  │
                         │  └────────────────────────────────────┘  │
                         │                                           │
                         │  ┌────────────────────────────────────┐  │
                         │  │  Services:                         │  │
                         │  │  - API Service (REST)              │  │
                         │  │  - Supabase Client (real-time)     │  │
                         │  │  - FCM Service (push handler)      │  │
                         │  └────────────────────────────────────┘  │
                         │                                           │
                         └───────────────────────────────────────────┘
```

---

## 3. Последовательность работы

### 3.1 Поток данных при извлечении задачи

```
User sends message in Telegram
         │
         ▼
Telegram Server
         │
         ▼
Python Worker (Pyrogram listener)
         │
         ▼
Check if chat is monitored
         │
         ▼ (YES)
AI Pipeline
         │
         ├──▶ Extractor: Extract tasks from text
         │              ↓
         │         [Task 1, Task 2, ...]
         │              ↓
         ├──▶ Deduplicator: Check existing tasks
         │              ↓
         │         [Filtered tasks]
         │              ↓
         ├──▶ Deadline Parser: Parse "завтра в 5" → "2024-12-03T17:00"
         │              ↓
         │         [Tasks with deadlines]
         │              ↓
         └──▶ Prioritizer: Determine priority (urgent/high/medium/low)
                        ↓
                  [Final tasks]
                        ↓
Save to Supabase (tasks table)
         │
         ▼
Database Webhook triggers
         │
         ▼
Edge Function (send-task-notification)
         │
         ├──▶ Get user's FCM token from profiles table
         │
         ├──▶ Format notification based on priority
         │
         ├──▶ Send push via FCM API
         │
         └──▶ Log to task_notifications table
                        ↓
Firebase Cloud Messaging
         │
         ▼
User's mobile device receives push notification
         │
         ▼
User opens app → Task detail screen
```

### 3.2 Поток авторизации

```
User opens Flutter app
         │
         ▼
Enter phone number
         │
         ▼
API: POST /auth/request-code
         │
         ▼
Python Worker: Pyrogram.send_code()
         │
         ▼
Telegram sends code to user
         │
         ▼
User enters code in app
         │
         ▼
API: POST /auth/verify-code
         │
         ▼
Python Worker: Pyrogram.sign_in()
         │
         ▼
Export & encrypt session string
         │
         ▼
Save to Supabase (profiles table)
         │
         ▼
Start worker session for user
         │
         ▼
User logged in → Navigate to Home screen
```

---

## 4. Компоненты системы

### 4.1 Python Worker

**Файлы:**
- `worker.py` - Главный процесс
- `session_manager.py` - Управление Pyrogram сессиями
- `ai_pipeline.py` - AI-анализ сообщений
- `database.py` - Работа с Supabase
- `prompts.py` - AI промпты
- `api_server.py` - FastAPI сервер для Flutter

**Ответственность:**
- Подключение к Telegram через Pyrogram (для каждого пользователя)
- Прослушивание сообщений в отслеживаемых чатах
- Обработка через AI Pipeline
- Сохранение задач в БД
- Предоставление REST API для Flutter

### 4.2 AI Pipeline

**Этапы обработки:**

1. **Extractor** (Извлечение)
   - Модель: GPT-4o-mini / Claude 3.5 Sonnet
   - Вход: Текст сообщения + контекст (чат, отправитель)
   - Выход: Массив задач с confidence score
   - Промпт: Системный промпт с примерами + user message

2. **Deduplicator** (Дедупликация)
   - Вход: Новая задача + список активных задач из БД
   - Выход: `is_duplicate: true/false`
   - Метод: AI-сравнение семантического смысла

3. **Deadline Parser** (Парсинг дедлайна)
   - Вход: "завтра вечером", "через 2 часа", "к пятнице"
   - Выход: ISO datetime + флаг `is_precise`
   - Логика: Относительные даты + NLP парсинг

4. **Prioritizer** (Приоритизация)
   - Вход: Задача + дедлайн + ключевые слова
   - Выход: `urgent` / `high` / `medium` / `low`
   - Критерии: Время до дедлайна, ключевые слова, контекст

### 4.3 База данных (Supabase PostgreSQL)

**Таблицы:**

```sql
profiles
├── id (UUID, PK)
├── telegram_user_id (BIGINT, unique)
├── encrypted_session (TEXT)
├── fcm_token (TEXT)
└── ...

monitored_chats
├── id (UUID, PK)
├── user_id (UUID, FK → profiles)
├── chat_id (BIGINT)
├── chat_title (TEXT)
└── is_active (BOOLEAN)

tasks
├── id (UUID, PK)
├── user_id (UUID, FK → profiles)
├── chat_id (BIGINT)
├── content (TEXT)
├── priority (enum: urgent/high/medium/low)
├── deadline (TIMESTAMPTZ)
├── status (enum: new/acknowledged/in_progress/done/cancelled)
└── ...

task_notifications
├── id (UUID, PK)
├── task_id (UUID, FK → tasks)
├── notification_type (enum: creation/reminder/deadline_approaching)
├── sent_at (TIMESTAMPTZ)
└── success (BOOLEAN)
```

**Row Level Security (RLS):**
- Каждый пользователь видит только свои данные
- Service role (backend worker) имеет полный доступ

### 4.4 Edge Functions (Supabase/Deno)

**send-task-notification**

```typescript
Handler flow:
1. Receive webhook payload (new task inserted)
2. Extract user_id from task
3. Query profiles table for fcm_token
4. Format notification:
   - Title: "🔴 СРОЧНАЯ ЗАДАЧА" (based on priority)
   - Body: task.content + deadline info
5. Send POST to FCM API
6. Log result to task_notifications table
```

**FCM Message Format:**
```json
{
  "message": {
    "token": "user_fcm_token",
    "notification": {
      "title": "🔴 СРОЧНАЯ ЗАДАЧА",
      "body": "Отправить отчет ⏰ Через 30 минут"
    },
    "data": {
      "task_id": "uuid",
      "priority": "urgent",
      "source_link": "https://t.me/c/123/456"
    },
    "android": {
      "priority": "high",
      "notification": {
        "sound": "urgent",
        "channel_id": "task_notifications"
      }
    }
  }
}
```

### 4.5 Flutter App

**Структура:**

```dart
lib/
├── data/                    # Data layer
│   ├── models/              # Data classes (Task, Chat, Profile)
│   ├── repositories/        # Business logic (API calls)
│   └── services/            # External services (API, Supabase, FCM)
│
├── presentation/            # UI layer
│   ├── screens/             # App screens
│   ├── widgets/             # Reusable widgets
│   └── providers/           # Riverpod state providers
│
└── core/                    # Shared code
    ├── constants/           # API endpoints, colors
    ├── theme/               # App theme
    └── utils/               # Helpers
```

**Ключевые экраны:**
1. **LoginScreen** - Ввод телефона
2. **VerifyCodeScreen** - Ввод кода из Telegram
3. **HomeScreen** - Список задач (StreamBuilder для real-time updates)
4. **ChatSelectionScreen** - Выбор чатов для мониторинга
5. **TaskDetailScreen** - Детали задачи + действия (отметить выполненной)

---

## 5. Безопасность

### 5.1 Шифрование

**Session Encryption:**
- Pyrogram session strings хранятся зашифрованными с помощью Fernet (симметричное шифрование)
- Ключ шифрования хранится в переменных окружения
- Расшифровка происходит только в памяти Worker

**В пути:**
- HTTPS для всех API-запросов
- TLS для подключения к Supabase
- MTProto (Telegram's encryption) для сообщений

### 5.2 Аутентификация и авторизация

**Row Level Security (RLS):**
```sql
-- Пример политики: пользователь видит только свои задачи
CREATE POLICY "Users can view own tasks"
ON tasks FOR SELECT
USING (auth.uid() = user_id);
```

**Service Role:**
- Backend Worker использует `service_role_key` для обхода RLS
- Ключ доступен только на сервере, никогда не отправляется клиенту

### 5.3 Рекомендации для Production

1. **Переменные окружения:**
   - Используйте `.env` файлы (не коммитить в Git)
   - Или секрет-менеджеры (AWS Secrets Manager, HashiCorp Vault)

2. **Rate Limiting:**
   - Ограничьте количество запросов на пользователя
   - Используйте Redis для хранения счетчиков

3. **Webhook Signature Verification:**
   - Проверяйте подпись Database Webhook перед обработкой

4. **CORS:**
   - Ограничьте `allowed_origins` только вашими доменами

5. **2FA:**
   - Рекомендуйте пользователям включить 2FA в Telegram

---

## 6. Масштабируемость

### 6.1 Текущие ограничения

- **1 Worker процесс** - Обрабатывает всех пользователей
- **Sequential AI calls** - Каждая задача проходит через 4 AI-запроса последовательно
- **Single database** - PostgreSQL (Supabase)

### 6.2 Варианты масштабирования

**Горизонтальное масштабирование:**

1. **Multiple Worker Instances:**
   - Используйте Redis для координации (distributed locks)
   - Каждый Worker обрабатывает подмножество пользователей
   - Load balancing через Consul / Kubernetes

2. **Message Queue:**
   - Используйте RabbitMQ / Kafka для обработки сообщений
   - Worker слушает очередь и обрабатывает асинхронно
   - Retry logic для failed messages

3. **AI Request Batching:**
   - Группируйте несколько задач в один AI-запрос
   - Используйте параллельные запросы (`asyncio.gather`)

4. **Database:**
   - Supabase автоматически масштабируется (managed service)
   - Для self-hosted: Read replicas + Connection pooling (PgBouncer)

**Вертикальное масштабирование:**
- Увеличьте ресурсы Worker сервера (CPU, RAM)
- Используйте более мощные AI модели (GPT-4 вместо GPT-4o-mini)

---

## 7. Мониторинг и логирование

### 7.1 Логи

**Python Worker:**
```python
# Loguru с ротацией файлов
logger.add(
    "logs/recall_worker.log",
    rotation="100 MB",
    retention="7 days",
    level="INFO"
)
```

**Edge Functions:**
```bash
supabase functions logs send-task-notification --follow
```

### 7.2 Метрики

**Key Performance Indicators (KPI):**
- Количество обработанных сообщений/сек
- Среднее время обработки AI Pipeline
- Процент успешных push-уведомлений
- Количество активных сессий Pyrogram

**Инструменты:**
- **Prometheus** - Сбор метрик
- **Grafana** - Визуализация
- **Sentry** - Error tracking

### 7.3 Health Checks

**Worker:**
```python
GET /health
Response: {
    "status": "healthy",
    "worker_running": true,
    "active_sessions": 42
}
```

**Database:**
```sql
-- Проверка количества активных задач
SELECT COUNT(*) FROM tasks WHERE status NOT IN ('done', 'cancelled');
```

---

## 8. Стоимость и оптимизация

### 8.1 Оценка затрат

**AI API (OpenAI GPT-4o-mini):**
- ~$0.15 за 1M input tokens
- ~$0.60 за 1M output tokens
- Среднее сообщение: ~500 tokens (4 AI calls)
- **~$0.002 за сообщение**

**Supabase (Pro Plan):**
- Database: $25/месяц
- Edge Functions: $10/месяц (1M requests)
- **~$35/месяц**

**Firebase (Blaze Plan):**
- FCM: Бесплатно
- Hosting: ~$5/месяц

**Сервер (VPS):**
- 2 vCPU, 4GB RAM: ~$20/месяц

**Итого на 1000 пользователей:**
- ~$80-100/месяц (без учета AI calls)
- + $2 за 1000 сообщений с задачами

### 8.2 Оптимизация затрат

1. **Cache AI responses** - Похожие сообщения → один AI call
2. **Use local models** - Ollama (Llama 3) для Extractor
3. **Batch processing** - Группировка AI-запросов
4. **Tiered plans** - Free tier с лимитами, Premium без лимитов

---

## 9. Roadmap

### Phase 1: MVP (Done) ✅
- [x] Python Worker с Pyrogram
- [x] AI Pipeline (4 этапа)
- [x] Supabase database
- [x] Edge Functions для push
- [x] Flutter app архитектура

### Phase 2: Production Ready 🚧
- [ ] Docker deployment
- [ ] Comprehensive testing
- [ ] Error recovery и retry logic
- [ ] User onboarding в приложении

### Phase 3: Advanced Features 📋
- [ ] Голосовые сообщения (Speech-to-Text)
- [ ] Поддержка изображений (OCR для скриншотов)
- [ ] Интеграция с календарем
- [ ] Web-версия на Next.js

### Phase 4: Scale 🚀
- [ ] Multiple Worker instances
- [ ] Message queue (RabbitMQ)
- [ ] Advanced analytics
- [ ] Team collaboration

---

## 10. Заключение

Система **Recall** использует современный стек технологий для создания интеллектуальной системы управления задачами:

✅ **Scalable** - Может масштабироваться горизонтально
✅ **Secure** - Шифрование, RLS, безопасные API
✅ **Real-time** - Push-уведомления и Supabase Realtime
✅ **AI-Powered** - Точное извлечение и приоритизация задач

**Технологический стек:**
- Backend: Python + Pyrogram + FastAPI
- AI: OpenAI GPT-4o-mini / Anthropic Claude
- Database: Supabase (PostgreSQL)
- Functions: Supabase Edge Functions (Deno)
- Mobile: Flutter + Riverpod
- Notifications: Firebase Cloud Messaging

---

**Документ обновлен:** 2024-12-02
**Версия:** 1.0.0
