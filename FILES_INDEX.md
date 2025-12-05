# Recall Project - Files Index

Полный список всех файлов проекта с описанием.

## Общая статистика

- **Всего файлов:** 19
- **Python файлов:** 6 (~2650 строк)
- **SQL файлов:** 1 (~400 строк)
- **TypeScript файлов:** 1 (~250 строк)
- **Markdown документации:** 7
- **Конфигурационных файлов:** 4

---

## Корень проекта

| Файл | Тип | Строк | Описание |
|------|-----|-------|----------|
| `README.md` | Markdown | ~800 | Главная документация проекта |
| `QUICKSTART.md` | Markdown | ~400 | Быстрый старт за 15 минут |
| `PROJECT_SUMMARY.md` | Markdown | ~600 | Полный обзор проекта |
| `FILES_INDEX.md` | Markdown | ~200 | Этот файл - индекс всех файлов |

---

## Backend Worker (Python)

### Исходный код (`backend-worker/src/`)

| Файл | Строк | Описание | Основные классы/функции |
|------|-------|----------|-------------------------|
| `worker.py` | ~400 | Главный Worker процесс | `RecallWorker`, `main()` |
| `api_server.py` | ~350 | FastAPI REST API | Endpoints для Flutter |
| `ai_pipeline.py` | ~450 | AI Pipeline (4 этапа) | `AIPipeline`, `AIProvider` |
| `session_manager.py` | ~350 | Pyrogram сессии | `SessionManager`, `SessionEncryption` |
| `database.py` | ~500 | Работа с Supabase | `DatabaseManager` |
| `prompts.py` | ~600 | AI промпты | Константы промптов |

**Итого:** ~2650 строк Python кода

### Конфигурация (`backend-worker/config/`)

| Файл | Тип | Описание |
|------|-----|----------|
| `config.example.yaml` | YAML | Пример конфигурации |

### Deployment (`backend-worker/`)

| Файл | Тип | Описание |
|------|-----|----------|
| `requirements.txt` | Text | Python зависимости |
| `Dockerfile` | Docker | Multi-stage build образ |
| `docker-compose.yml` | YAML | Orchestration (worker + api + redis + nginx) |
| `.env.example` | Text | Пример переменных окружения |

---

## База данных (Supabase)

### Migrations (`supabase/migrations/`)

| Файл | Строк | Описание |
|------|-------|----------|
| `001_initial_schema.sql` | ~400 | Полная схема БД (5 таблиц + RLS + triggers + views) |

**Таблицы:**
- `profiles` - Пользователи
- `monitored_chats` - Отслеживаемые чаты
- `tasks` - Извлеченные задачи
- `task_notifications` - Лог уведомлений
- `worker_sessions` - Активные сессии воркера

---

## Edge Functions (Supabase)

### Functions (`supabase/functions/`)

| Файл | Тип | Строк | Описание |
|------|-----|-------|----------|
| `send-task-notification/index.ts` | TypeScript | ~250 | Push-уведомления через FCM |
| `README.md` | Markdown | ~150 | Гайд по настройке функций |

---

## Flutter App

### Документация (`flutter-app/`)

| Файл | Тип | Строк | Описание |
|------|-----|-------|----------|
| `ARCHITECTURE.md` | Markdown | ~700 | Архитектура Flutter приложения |

**Описывает:**
- Структуру проекта
- Основные экраны (Login, Home, Chat Selection, Task Detail)
- State Management (Riverpod)
- Models (Task, Chat, Profile)
- Services (API, Supabase, FCM)

**Примечание:** Сам Flutter код не реализован, только архитектура и примеры кода.

---

## Документация (`docs/`)

| Файл | Тип | Строк | Описание |
|------|-----|-------|----------|
| `SYSTEM_DESIGN.md` | Markdown | ~900 | Системная архитектура с диаграммами |
| `API_EXAMPLES.md` | Markdown | ~700 | Примеры использования REST API |

---

## Структура директорий

```
recall-project/
│
├── 📄 README.md                       # Главная документация
├── 📄 QUICKSTART.md                   # Быстрый старт
├── 📄 PROJECT_SUMMARY.md              # Обзор проекта
├── 📄 FILES_INDEX.md                  # Этот файл
│
├── 📁 backend-worker/                 # Python Backend
│   ├── 📁 src/                        # Исходный код
│   │   ├── 🐍 worker.py               # Worker процесс
│   │   ├── 🐍 api_server.py           # REST API
│   │   ├── 🐍 ai_pipeline.py          # AI Pipeline
│   │   ├── 🐍 session_manager.py      # Pyrogram сессии
│   │   ├── 🐍 database.py             # Supabase клиент
│   │   └── 🐍 prompts.py              # AI промпты
│   │
│   ├── 📁 config/                     # Конфигурация
│   │   └── ⚙️ config.example.yaml     # Пример конфига
│   │
│   ├── 📁 logs/                       # Логи (создается автоматически)
│   ├── 📁 sessions/                   # Pyrogram сессии (создается автоматически)
│   │
│   ├── 📄 requirements.txt            # Python зависимости
│   ├── 🐳 Dockerfile                  # Docker образ
│   ├── 🐳 docker-compose.yml          # Orchestration
│   └── 📄 .env.example                # Переменные окружения
│
├── 📁 supabase/                       # База данных
│   ├── 📁 migrations/                 # SQL миграции
│   │   └── 🗄️ 001_initial_schema.sql  # Схема БД
│   │
│   └── 📁 functions/                  # Edge Functions
│       ├── 📄 README.md               # Гайд по функциям
│       └── 📁 send-task-notification/
│           └── 📜 index.ts            # Push-уведомления
│
├── 📁 flutter-app/                    # Мобильное приложение
│   ├── 📄 ARCHITECTURE.md             # Архитектура Flutter
│   ├── 📁 lib/                        # Dart код (не реализован)
│   │   ├── 📁 data/
│   │   ├── 📁 presentation/
│   │   └── 📁 core/
│   └── 📄 pubspec.yaml                # Flutter зависимости (пример)
│
└── 📁 docs/                           # Документация
    ├── 📄 SYSTEM_DESIGN.md            # Системный дизайн
    └── 📄 API_EXAMPLES.md             # Примеры API
```

---

## Ключевые технологии по файлам

### Python Backend

**Dependencies (requirements.txt):**
```
pyrogram==2.0.106         # Telegram client
tgcrypto==1.2.5          # Fast encryption
supabase==2.3.4          # Database client
openai==1.12.0           # AI provider
anthropic==0.18.1        # AI provider
fastapi + uvicorn        # REST API
cryptography==42.0.2     # Session encryption
loguru==0.7.2            # Logging
pydantic==2.6.1          # Data validation
```

### TypeScript Edge Function

**Dependencies:**
```typescript
@supabase/supabase-js@2.38.0  // Database client
Deno std library              // HTTP server
```

### Flutter App (Planned)

**Dependencies (pubspec.yaml):**
```yaml
flutter_riverpod: ^2.4.9     # State management
supabase_flutter: ^2.0.0     # Database + Auth
firebase_core: ^2.24.2       # Firebase SDK
firebase_messaging: ^14.7.9  # Push notifications
dio: ^5.4.0                  # HTTP client
freezed: ^2.4.6              # Code generation
```

---

## Размер кода

### По типам файлов:

| Тип | Файлов | Строк |
|-----|--------|-------|
| Python (`.py`) | 6 | ~2650 |
| SQL (`.sql`) | 1 | ~400 |
| TypeScript (`.ts`) | 1 | ~250 |
| Markdown (`.md`) | 7 | ~4000 |
| YAML (`.yaml`/`.yml`) | 2 | ~100 |
| **Итого** | **17** | **~7400** |

### По компонентам:

| Компонент | Строк кода | Строк документации |
|-----------|------------|-------------------|
| Python Backend | 2650 | - |
| Database (SQL) | 400 | - |
| Edge Functions | 250 | 150 |
| Flutter (планируется) | ~2400 | 700 |
| Документация | - | 4000 |
| **Итого** | **~5700** | **~4850** |

---

## Файлы для первого запуска

Минимальный набор файлов для запуска MVP:

### 1. Backend Worker
```
backend-worker/
├── src/worker.py
├── src/ai_pipeline.py
├── src/session_manager.py
├── src/database.py
├── src/prompts.py
├── config/config.yaml (создать из example)
└── requirements.txt
```

### 2. База данных
```
supabase/migrations/001_initial_schema.sql
```

### 3. API (опционально для Flutter)
```
backend-worker/src/api_server.py
```

### 4. Edge Function (для push)
```
supabase/functions/send-task-notification/index.ts
```

---

## Генерация файлов

### Автоматически создаваемые при запуске:

```
backend-worker/logs/                # Логи
├── recall_worker.log

backend-worker/sessions/            # Pyrogram сессии
├── user_*.session
```

### Создаваемые пользователем:

```
backend-worker/config/config.yaml   # Из config.example.yaml
backend-worker/.env                 # Из .env.example
```

---

## Навигация по проекту

### Хотите настроить проект?
→ Начните с [QUICKSTART.md](QUICKSTART.md)

### Хотите понять архитектуру?
→ Прочитайте [docs/SYSTEM_DESIGN.md](docs/SYSTEM_DESIGN.md)

### Хотите интегрировать API?
→ Смотрите [docs/API_EXAMPLES.md](docs/API_EXAMPLES.md)

### Хотите разработать Flutter приложение?
→ Следуйте [flutter-app/ARCHITECTURE.md](flutter-app/ARCHITECTURE.md)

### Хотите настроить push-уведомления?
→ Читайте [supabase/functions/README.md](supabase/functions/README.md)

---

## Зависимости между файлами

```
worker.py
  ├── imports: ai_pipeline.py
  ├── imports: session_manager.py
  ├── imports: database.py
  └── uses: config/config.yaml

api_server.py
  ├── imports: session_manager.py
  ├── imports: database.py
  ├── imports: worker.py
  └── uses: config/config.yaml

ai_pipeline.py
  ├── imports: prompts.py
  └── calls: OpenAI/Anthropic API

database.py
  └── connects to: Supabase (001_initial_schema.sql)

session_manager.py
  └── connects to: Telegram API

index.ts (Edge Function)
  ├── triggered by: Database Webhook (tasks INSERT)
  └── calls: Firebase Cloud Messaging API
```

---

## Чеклист для разработчика

### ✅ Backend готов
- [x] Worker процесс (Pyrogram)
- [x] AI Pipeline (4 этапа)
- [x] Session Manager (шифрование)
- [x] Database Manager (Supabase CRUD)
- [x] REST API (FastAPI)
- [x] AI промпты (русский язык)

### ✅ База данных готова
- [x] SQL схема (5 таблиц)
- [x] Row Level Security
- [x] Triggers и Functions
- [x] Views для удобных запросов

### ✅ Edge Functions готовы
- [x] Push-уведомления (TypeScript)
- [x] FCM интеграция
- [x] Database Webhook обработка

### ⏳ Flutter App (архитектура готова)
- [x] Архитектурный дизайн
- [x] Примеры кода
- [ ] Полная реализация UI
- [ ] Firebase интеграция
- [ ] Supabase Real-time

### ✅ Документация готова
- [x] README.md
- [x] QUICKSTART.md
- [x] SYSTEM_DESIGN.md
- [x] API_EXAMPLES.md
- [x] PROJECT_SUMMARY.md
- [x] FILES_INDEX.md

### 🐳 Deployment готов
- [x] Dockerfile
- [x] docker-compose.yml
- [x] .env.example
- [ ] CI/CD pipeline

---

## Git Repository Structure (рекомендуется)

```bash
# .gitignore
backend-worker/config/config.yaml
backend-worker/.env
backend-worker/logs/
backend-worker/sessions/
flutter-app/ios/
flutter-app/android/
flutter-app/.flutter-plugins
flutter-app/build/
.vscode/
.idea/
__pycache__/
*.pyc
*.session
*.session-journal
.DS_Store
```

---

**Последнее обновление:** 2024-12-02
**Версия проекта:** 1.0.0 MVP
**Статус:** ✅ Ready for Development
