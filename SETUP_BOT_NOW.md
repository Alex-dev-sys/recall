# 🤖 Настройка Telegram Бота - Пошаговая Инструкция

## ✅ Что уже готово:

- ✅ **Backend Worker** - код готов (100%)
- ✅ **AI Pipeline** - GPT-4o-mini через GPT Lama API настроен
- ✅ **Supabase** - credentials настроены
- ✅ **Flutter App** - APK собран: `C:\Users\user\recall_app_final\build\app\outputs\flutter-apk\app-release.apk`

---

## 📋 Осталось сделать:

### 1️⃣ Применить SQL Миграцию (5 минут)

**Перейдите по ссылке:**
```
https://supabase.com/dashboard/project/pavrkvgztgksaovujeld/sql/new
```

**Откройте файл:**
```
C:\Users\user\OneDrive\Desktop\Scribe\recall-project\supabase\migrations\001_initial_schema.sql
```

**Скопируйте всё содержимое (Ctrl+A → Ctrl+C)**

**Вставьте в SQL Editor и нажмите RUN (Ctrl+Enter)**

✅ **Готово!** База данных создана.

---

### 2️⃣ Получить Telegram API Credentials (5 минут)

**Перейдите:** https://my.telegram.org

1. Войдите через свой номер телефона
2. Перейдите в **API Development Tools**
3. Создайте новое приложение:
   - **App title:** Recall Bot
   - **Short name:** recall
   - **Platform:** Other
4. Скопируйте:
   - `api_id` (число)
   - `api_hash` (строка)

---

### 3️⃣ Сгенерировать Encryption Key (1 минута)

**Установите Python** (если еще не установлен):
```
https://www.python.org/downloads/
```
Галочка "Add Python to PATH" ✅

**Откройте PowerShell** и выполните:
```powershell
python -m pip install cryptography
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

Скопируйте полученный ключ (выглядит как: `xGH7kP9mQ...`)

---

### 4️⃣ Обновить конфигурацию (2 минуты)

**Откройте файл:**
```
C:\Users\user\OneDrive\Desktop\Scribe\recall-project\backend-worker\config\config.yaml
```

**Замените строки 12-14:**
```yaml
telegram:
  api_id: ВАШ_API_ID  # Вставьте число из my.telegram.org
  api_hash: "ВАШ_API_HASH"  # Вставьте hash из my.telegram.org
  session_encryption_key: "ВАШ_ENCRYPTION_KEY"  # Ключ из шага 3
```

**Сохраните файл (Ctrl+S)**

---

### 5️⃣ Установить зависимости (5 минут)

**Откройте PowerShell:**
```powershell
cd C:\Users\user\OneDrive\Desktop\Scribe\recall-project\backend-worker

# Создать виртуальное окружение
python -m venv venv

# Активировать
.\venv\Scripts\Activate.ps1

# Установить зависимости
pip install -r requirements.txt
```

---

### 6️⃣ Протестировать подключения (2 минуты)

**Проверить Supabase:**
```powershell
python test_supabase_connection.py
```
Должно показать: `✅ Supabase connection successful!`

**Проверить AI API:**
```powershell
python test_gptlama_api.py
```
Должно показать: `✅ AI API works!`

---

### 7️⃣ Запустить Worker! 🚀

```powershell
python src\worker.py
```

**При первом запуске:**
- Введите ваш номер телефона (+7...)
- Введите код из Telegram
- Если нужно - введите 2FA пароль

✅ **Worker запущен!** Теперь он слушает ваши Telegram чаты и извлекает задачи.

---

## 🎯 Как использовать:

### В Telegram:
1. Отправьте боту команду `/start`
2. Добавьте чаты для мониторинга командой `/monitor`
3. Пишите сообщения с задачами:
   - "Нужно отправить отчет до пятницы"
   - "Напомни позвонить маме завтра"
   - "Встреча с клиентом 15:00"

### В Flutter приложении:
1. Установите APK: `C:\Users\user\recall_app_final\build\app\outputs\flutter-apk\app-release.apk`
2. Войдите через Supabase Auth
3. Смотрите свои задачи в 3 вкладках:
   - **Tasks** - все задачи
   - **Chats** - отслеживаемые чаты
   - **Profile** - ваш профиль

---

## 🔍 Как работает AI Pipeline:

### 4 этапа анализа:

1. **Extractor** 🔍
   - Находит задачи в тексте
   - Определяет тип (request/promise/agreement/reminder)
   - Извлекает контекст

2. **Deduplicator** 🔁
   - Проверяет дубликаты за последние 72 часа
   - Использует семантический поиск
   - Объединяет похожие задачи

3. **Deadline Parser** 📅
   - Понимает "завтра", "в пятницу", "через неделю"
   - Извлекает точное время
   - Определяет срочность

4. **Prioritizer** ⚡
   - Расставляет приоритеты (urgent/high/medium/low)
   - Учитывает дедлайн, контекст, слова-триггеры
   - Сортирует по важности

---

## 📊 Структура данных:

### Таблицы Supabase:
- `profiles` - пользователи и Telegram сессии
- `monitored_chats` - отслеживаемые чаты
- `tasks` - извлеченные задачи
- `task_notifications` - отправленные уведомления
- `worker_sessions` - активные worker процессы

---

## 🆘 Проблемы?

### Worker не запускается:
```powershell
# Проверьте Python
python --version

# Проверьте зависимости
pip list | findstr pyrogram
pip list | findstr openai
pip list | findstr supabase
```

### Ошибка Telegram API:
- Проверьте `api_id` и `api_hash` в config.yaml
- Убедитесь что создали приложение на my.telegram.org

### Ошибка Supabase:
- Проверьте что применили миграцию (шаг 1)
- Проверьте credentials в config.yaml

### Ошибка AI API:
```powershell
python test_gptlama_api.py
```

---

## 📂 Полезные файлы:

- **Конфиг:** `backend-worker/config/config.yaml`
- **Логи:** `backend-worker/logs/recall_worker.log`
- **Сессии:** `backend-worker/sessions/` (создается автоматически)
- **APK:** `C:\Users\user\recall_app_final\build\app\outputs\flutter-apk\app-release.apk`

---

## 🎉 Готово!

Теперь у вас есть:
- ✅ Telegram бот который извлекает задачи
- ✅ AI Pipeline с GPT-4o-mini
- ✅ База данных в Supabase
- ✅ Flutter приложение для просмотра задач

**Время на полную настройку:** ~20 минут

**Стоимость:** $0/месяц (всё на free tier)

---

**Следующий шаг:** Применить SQL миграцию → https://supabase.com/dashboard/project/pavrkvgztgksaovujeld/sql/new
