# ✅ Setup Checklist - Recall Project

## Статус: Supabase подключен ✓

**Project URL:** `https://pavrkvgztgksaovujeld.supabase.co`

Ключи уже настроены в `config/config.yaml` и `.mcp-config.json`

---

## 📋 Что делать дальше

### ☑️ Шаг 1: Применить SQL миграцию (ОБЯЗАТЕЛЬНО!)

Открой [SQL Editor](https://supabase.com/dashboard/project/pavrkvgztgksaovujeld/sql/new) и выполни содержимое файла:

```
supabase/migrations/001_initial_schema.sql
```

**Как проверить:**
```bash
cd backend-worker
python test_supabase_connection.py
```

Должно вывести: `✅ SUPABASE CONNECTION TEST PASSED`

---

### ☑️ Шаг 2: Получить Telegram API credentials

1. Зайди на [my.telegram.org](https://my.telegram.org)
2. Войди со своим номером
3. **API development tools**
4. Создай приложение
5. Скопируй `api_id` и `api_hash`

**Обнови config/config.yaml:**
```yaml
telegram:
  api_id: 12345678  # ← Вставь сюда
  api_hash: "abc123..."  # ← Вставь сюда
```

---

### ☑️ Шаг 3: Сгенерировать ключ шифрования

```bash
cd backend-worker
python generate_encryption_key.py
```

Скопируй ключ в `config/config.yaml`:
```yaml
telegram:
  session_encryption_key: "GENERATED_KEY_HERE"
```

---

### ☑️ Шаг 4: Получить OpenAI API ключ

1. Зайди на [platform.openai.com](https://platform.openai.com)
2. **API Keys** → Create new key
3. Скопируй ключ

**Обнови config/config.yaml:**
```yaml
ai:
  api_key: "sk-..."  # ← Вставь сюда
```

---

### ☑️ Шаг 5: Установить зависимости

```bash
cd backend-worker
python -m venv venv
venv\Scripts\activate  # Windows
# source venv/bin/activate  # Linux/Mac

pip install -r requirements.txt
```

---

### ☑️ Шаг 6: Запустить Worker

```bash
cd backend-worker
venv\Scripts\activate
python src/worker.py
```

Должно вывести:
```
2024-12-02 14:00:00 | INFO | RecallWorker started successfully
```

---

### ☑️ Шаг 7: Запустить API Server (в другом терминале)

```bash
cd backend-worker
venv\Scripts\activate
python src/api_server.py
```

Должно вывести:
```
INFO:     Uvicorn running on http://0.0.0.0:8000
```

Проверь: http://localhost:8000/health

---

### ☑️ Шаг 8: Настроить OneSignal (для push-уведомлений)

1. Зайди на [onesignal.com](https://onesignal.com)
2. Создай новое приложение
3. Выбери **Mobile App** → Android/iOS
4. Получи **App ID** и **REST API Key**

**Установи секреты:**
```bash
supabase secrets set ONESIGNAL_APP_ID=your-app-id
supabase secrets set ONESIGNAL_API_KEY=your-api-key
```

**Deploy Edge Function:**
```bash
cd supabase/functions
supabase functions deploy send-task-notification
```

---

### ☑️ Шаг 9: Создать Database Webhook

1. Открой [Database > Webhooks](https://supabase.com/dashboard/project/pavrkvgztgksaovujeld/database/hooks)
2. **Create webhook**
3. Настрой:
   - Name: `task-notification-trigger`
   - Table: `tasks`
   - Events: `INSERT`
   - URL: `https://pavrkvgztgksaovujeld.supabase.co/functions/v1/send-task-notification`
   - Headers:
     ```
     Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBhdnJrdmd6dGdrc2FvdnVqZWxkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ2ODI5MjAsImV4cCI6MjA4MDI1ODkyMH0.XdqIGRJB1RWcouteyhMpkip5jE_L58x04no4xMbXwvU
     ```

---

### ☑️ Шаг 10: Разработать Flutter приложение

См. документацию:
- [flutter-app/ARCHITECTURE.md](flutter-app/ARCHITECTURE.md)
- [ONESIGNAL_SETUP.md](ONESIGNAL_SETUP.md)

---

## 🔍 Проверка работы

### Тест 1: Backend подключен к Supabase

```bash
cd backend-worker
python test_supabase_connection.py
```

Ожидаемый результат: `✅ SUPABASE CONNECTION TEST PASSED`

### Тест 2: API работает

```bash
curl http://localhost:8000/health
```

Ожидаемый результат:
```json
{
  "status": "healthy",
  "worker_running": true,
  "active_sessions": 0
}
```

### Тест 3: База данных доступна

Открой [Table Editor](https://supabase.com/dashboard/project/pavrkvgztgksaovujeld/editor) и проверь таблицы.

---

## 📊 Прогресс

| Шаг | Статус | Описание |
|-----|--------|----------|
| ✅ | Done | Supabase project создан |
| ✅ | Done | Ключи сохранены в config |
| ⏳ | Todo | SQL миграция применена |
| ⏳ | Todo | Telegram API получен |
| ⏳ | Todo | OpenAI API получен |
| ⏳ | Todo | Dependencies установлены |
| ⏳ | Todo | Worker запущен |
| ⏳ | Todo | API Server запущен |
| ⏳ | Todo | OneSignal настроен |
| ⏳ | Todo | Edge Function deployed |
| ⏳ | Todo | Webhook создан |
| ⏳ | Todo | Flutter app разработан |

---

## 🆘 Помощь

### Проблема: SQL миграция не применяется

**Решение:** Скопируй SQL вручную через SQL Editor.

### Проблема: Worker не запускается

**Решение:** Проверь config.yaml, все ли ключи заполнены.

### Проблема: API не отвечает

**Решение:**
```bash
# Проверь порт
netstat -ano | findstr :8000

# Перезапусти
python src/api_server.py
```

---

## 📚 Документация

- [README.md](README.md) - Полная документация
- [QUICKSTART.md](QUICKSTART.md) - Быстрый старт
- [SUPABASE_SETUP_INSTRUCTIONS.md](SUPABASE_SETUP_INSTRUCTIONS.md) - Настройка Supabase
- [ONESIGNAL_SETUP.md](ONESIGNAL_SETUP.md) - Настройка push-уведомлений
- [TECH_STACK_UPDATE.md](TECH_STACK_UPDATE.md) - Изменения в стеке

---

**Текущий прогресс:** 2/12 шагов ✅

Следующее действие: **Применить SQL миграцию** 👆
