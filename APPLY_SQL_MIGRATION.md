# 🗃️ Применение SQL Миграции - Пошаговая инструкция

## Способ 1: Через Web UI (РЕКОМЕНДУЕТСЯ) ⭐

### Шаг 1: Открыть SQL Editor

Нажмите на эту ссылку (откроется в браузере):

**https://supabase.com/dashboard/project/pavrkvgztgksaovujeld/sql/new**

### Шаг 2: Скопировать SQL

1. Откройте файл в Проводнике:
   ```
   C:\Users\user\OneDrive\Desktop\Scribe\recall-project\supabase\migrations\001_initial_schema.sql
   ```

2. Откройте его в любом текстовом редакторе (Notepad, VSCode, и т.д.)

3. Выделите весь текст: **Ctrl+A**

4. Скопируйте: **Ctrl+C**

### Шаг 3: Вставить и выполнить

1. Вернитесь в браузер с SQL Editor

2. Вставьте скопированный SQL: **Ctrl+V**

3. Нажмите кнопку **RUN** (или **Ctrl+Enter**)

4. Дождитесь сообщения **"Success"** (обычно 2-5 секунд)

### Шаг 4: Проверить результат

После выполнения должны появиться таблицы:

1. Перейдите в **Table Editor**:
   https://supabase.com/dashboard/project/pavrkvgztgksaovujeld/editor

2. Проверьте что созданы таблицы:
   - ✅ `profiles`
   - ✅ `monitored_chats`
   - ✅ `tasks`
   - ✅ `task_notifications`
   - ✅ `worker_sessions`

### ✅ Готово!

База данных настроена и готова к работе!

---

## Способ 2: Через командную строку (Альтернатива)

Если у вас установлен Supabase CLI:

```bash
cd C:\Users\user\OneDrive\Desktop\Scribe\recall-project
supabase db push
```

---

## Что делает эта миграция?

### 📦 Создает таблицы:

1. **profiles** - Профили пользователей
   - Telegram user_id
   - Зашифрованная сессия
   - OneSignal player_id
   - Данные профиля

2. **monitored_chats** - Отслеживаемые чаты
   - ID чата
   - Название чата
   - Тип (private/group/supergroup/channel)
   - Статус активности

3. **tasks** - Извлеченные задачи
   - Содержание задачи
   - Оригинальная цитата
   - Тип задачи (request/promise/agreement/reminder)
   - Приоритет (urgent/high/medium/low)
   - Дедлайн
   - Статус (new/in_progress/done/cancelled)
   - AI reasoning (почему AI выбрал эти параметры)

4. **task_notifications** - Отправленные уведомления
   - Лог всех push-уведомлений
   - Тип уведомления
   - Статус доставки

5. **worker_sessions** - Активные worker процессы
   - Мониторинг работающих worker'ов
   - Последний heartbeat
   - Статусы и ошибки

### 🔐 Настраивает безопасность:

- **Row Level Security (RLS)** - включен на всех таблицах
- **Политики доступа** - пользователи видят только свои данные
- **Service Role доступ** - backend worker имеет полный доступ

### ⚡ Создает дополнительные объекты:

- **Indexes** - для быстрых запросов
- **Triggers** - для автообновления timestamp'ов
- **Functions** - для бизнес-логики
- **Views** - для удобных выборок

---

## 🆘 Проблемы?

### Ошибка: "permission denied"
- Убедитесь что вы залогинены в Supabase
- Проверьте что открыт правильный проект

### Ошибка: "relation already exists"
- Таблицы уже созданы! Всё в порядке
- Можно пропустить этот шаг

### Ошибка: "syntax error"
- Убедитесь что скопировали весь файл целиком
- Попробуйте скопировать заново

### SQL Editor не открывается
1. Зайдите на https://supabase.com/dashboard
2. Выберите проект "recall"
3. В левом меню найдите "SQL Editor"
4. Нажмите "New query"

---

## ✨ Что дальше?

После применения миграции:

1. ✅ База данных готова
2. ✅ Можно запускать Worker
3. ✅ Можно использовать Flutter приложение

**Следующий шаг:** Получите Telegram API → [GET_TELEGRAM_API.md](GET_TELEGRAM_API.md)

---

## 📊 Визуализация структуры БД

```
┌─────────────────┐
│   auth.users    │
│  (Supabase)     │
└────────┬────────┘
         │
         │ references
         ▼
┌─────────────────┐
│   profiles      │◄────┐
│                 │     │
│ - telegram_id   │     │
│ - session       │     │
│ - onesignal_id  │     │
└────────┬────────┘     │
         │              │
         │ user_id      │
         ▼              │
┌─────────────────┐     │
│ monitored_chats │     │
│                 │     │
│ - chat_id       │     │
│ - chat_title    │     │
└────────┬────────┘     │
         │              │
         │ (user_id,    │
         │  chat_id)    │
         ▼              │
┌─────────────────┐     │
│     tasks       │     │
│                 │     │
│ - content       │     │
│ - priority      │     │
│ - deadline      │     │
│ - status        │     │
└────────┬────────┘     │
         │              │
         │ task_id      │
         ▼              │
┌─────────────────┐     │
│task_notifications│     │
└─────────────────┘     │
                        │
         │ user_id      │
         ▼              │
┌─────────────────┐     │
│worker_sessions  │─────┘
└─────────────────┘
```

---

**Время выполнения:** ~30 секунд
**Сложность:** ⭐☆☆☆☆ (очень легко)
