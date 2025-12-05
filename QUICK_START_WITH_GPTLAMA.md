# 🚀 Быстрый старт Recall Project

## ✅ Что уже настроено:

### 1. Supabase ✓
- Project URL: `https://pavrkvgztgksaovujeld.supabase.co`
- Ключи сохранены в `config/config.yaml`

### 2. AI API (GPT Lama) ✓
- Base URL: `https://api.gptlama.ru/v1`
- Model: `gpt-4o-mini`
- API Key настроен

---

## 📋 Что нужно сделать:

### Шаг 1: Применить SQL миграцию (ОБЯЗАТЕЛЬНО!)

1. Открой [Supabase SQL Editor](https://supabase.com/dashboard/project/pavrkvgztgksaovujeld/sql/new)
2. Скопируй весь SQL из файла: `supabase/migrations/001_initial_schema.sql`
3. Вставь в редактор и нажми **Run** (Ctrl+Enter)

**Проверка:**
```bash
cd backend-worker
python test_supabase_connection.py
```

Должно вывести: `✅ SUPABASE CONNECTION TEST PASSED`

---

### Шаг 2: Получить Telegram API credentials

1. Зайди на [my.telegram.org](https://my.telegram.org)
2. Войди со своим номером
3. **API development tools** → Create application
4. Скопируй `api_id` и `api_hash`

**Обнови `config/config.yaml`:**
```yaml
telegram:
  api_id: 12345678  # ← Твой api_id
  api_hash: "abc123def456"  # ← Твой api_hash
```

---

### Шаг 3: Сгенерировать ключ шифрования

```bash
cd backend-worker
python generate_encryption_key.py
```

Скопируй ключ в `config/config.yaml`:
```yaml
telegram:
  session_encryption_key: "GENERATED_KEY"
```

---

### Шаг 4: Установить зависимости

```bash
cd backend-worker
python -m venv venv
venv\Scripts\activate

pip install -r requirements.txt
```

---

### Шаг 5: Проверить AI API

```bash
python test_gptlama_api.py
```

Должно вывести:
```
✅ GPT LAMA API TEST PASSED
🎉 AI API работает корректно!
```

---

### Шаг 6: Запустить Worker

```bash
python src/worker.py
```

Должно вывести:
```
2024-12-02 14:00:00 | INFO | RecallWorker started successfully
```

---

### Шаг 7: Запустить API Server (в другом терминале)

```bash
cd backend-worker
venv\Scripts\activate
python src/api_server.py
```

Проверь: http://localhost:8000/health

---

## 🧪 Тестирование

### Тест 1: Supabase подключение
```bash
python test_supabase_connection.py
```

### Тест 2: GPT Lama API
```bash
python test_gptlama_api.py
```

### Тест 3: API Health
```bash
curl http://localhost:8000/health
```

---

## 📊 Прогресс

| Компонент | Статус |
|-----------|--------|
| Supabase | ✅ Настроен |
| GPT Lama API | ✅ Настроен |
| SQL Migration | ⏳ Нужно применить |
| Telegram API | ⏳ Нужно получить |
| Dependencies | ⏳ Нужно установить |
| Worker | ⏳ Готов к запуску |

---

## 🔥 После запуска

### Использование через API:

**1. Запросить код от Telegram:**
```bash
curl -X POST http://localhost:8000/auth/request-code \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "+79991234567"}'
```

**2. Войти с кодом:**
```bash
curl -X POST http://localhost:8000/auth/verify-code \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "+79991234567",
    "code": "12345",
    "phone_code_hash": "hash_from_step1"
  }'
```

**3. Получить список чатов:**
```bash
curl http://localhost:8000/chats/list/{user_id}
```

---

## 📚 Полезные ссылки

- [Supabase Dashboard](https://supabase.com/dashboard/project/pavrkvgztgksaovujeld)
- [SQL Editor](https://supabase.com/dashboard/project/pavrkvgztgksaovujeld/sql/new)
- [Table Editor](https://supabase.com/dashboard/project/pavrkvgztgksaovujeld/editor)
- [GPT Lama](https://api.gptlama.ru/)

---

## ❓ Troubleshooting

### Ошибка: "relation does not exist"
→ Применить SQL миграцию (Шаг 1)

### Ошибка: "Failed to create Supabase client"
→ Проверить ключи в config.yaml

### Ошибка: "OpenAI API error"
→ Проверить GPT Lama API ключ

### Worker не запускается
→ Заполнить все поля в config.yaml

---

**Следующий шаг:** Применить SQL миграцию → [Supabase SQL Editor](https://supabase.com/dashboard/project/pavrkvgztgksaovujeld/sql/new)
