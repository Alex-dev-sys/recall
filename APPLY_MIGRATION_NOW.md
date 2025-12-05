# 🚀 Применение SQL Миграции

## Способ 1: Через Supabase Dashboard (РЕКОМЕНДУЕТСЯ)

### Шаг 1: Открыть SQL Editor
Перейдите по ссылке:
```
https://supabase.com/dashboard/project/pavrkvgztgksaovujeld/sql/new
```

### Шаг 2: Скопировать миграцию
Откройте файл:
```
supabase/migrations/001_initial_schema.sql
```

Скопируйте весь содержимое (Ctrl+A → Ctrl+C)

### Шаг 3: Вставить и выполнить
1. Вставьте код в SQL Editor (Ctrl+V)
2. Нажмите **Run** или Ctrl+Enter
3. Дождитесь сообщения "Success"

### Шаг 4: Проверить
После выполнения проверьте, что созданы таблицы:
- ✅ profiles
- ✅ monitored_chats
- ✅ tasks
- ✅ task_notifications
- ✅ worker_sessions

---

## Способ 2: Через Python скрипт

```bash
cd C:\Users\user\OneDrive\Desktop\Scribe\recall-project\backend-worker
python -m venv venv
venv\Scripts\activate
pip install supabase
cd ..
python apply_migration.py
```

---

## ✅ После применения миграции

База данных готова! Теперь можно:

1. **Запустить Backend Worker**
   ```bash
   cd backend-worker
   python src/worker.py
   ```

2. **Запустить API сервер**
   ```bash
   cd backend-worker
   python src/api_server.py
   ```

3. **Протестировать подключение**
   ```bash
   python test_supabase_connection.py
   ```

---

## 📝 Что делает миграция?

### Таблицы:
- **profiles** - профили пользователей + Telegram сессии
- **monitored_chats** - отслеживаемые чаты
- **tasks** - извлеченные задачи с AI анализом
- **task_notifications** - лог отправленных уведомлений
- **worker_sessions** - активные worker сессии

### Безопасность:
- ✅ Row Level Security (RLS) включен
- ✅ Пользователи видят только свои данные
- ✅ Service Role имеет полный доступ

### Дополнительно:
- ✅ Indexes для быстрых запросов
- ✅ Triggers для auto-update timestamp
- ✅ Views для удобных выборок
- ✅ Foreign keys для целостности данных

---

## 🆘 Проблемы?

Если миграция не применилась:
1. Проверьте что вы залогинены в Supabase
2. Убедитесь что открыт правильный проект (pavrkvgztgksaovujeld)
3. Попробуйте выполнить по частям (по одной таблице за раз)

---

**Следующий шаг:** Получить Telegram API credentials на https://my.telegram.org
