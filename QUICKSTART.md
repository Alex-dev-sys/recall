# Recall - Quick Start Guide

Быстрая инструкция для запуска проекта за 15 минут.

## Предварительные требования

```bash
# Проверьте версии
python --version    # >= 3.10
flutter --version   # >= 3.0
node --version      # >= 18
```

---

## 1. Клонирование и установка (5 мин)

```bash
# Клонируйте репозиторий
git clone https://github.com/yourusername/recall-project.git
cd recall-project

# Backend
cd backend-worker
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt

# Flutter (в новом терминале)
cd flutter-app
flutter pub get
```

---

## 2. Настройка Supabase (5 мин)

### 2.1 Создайте проект
1. Зайдите на [supabase.com](https://supabase.com)
2. Создайте новый проект
3. Дождитесь инициализации (~2 мин)

### 2.2 Примените SQL миграцию
1. Откройте **SQL Editor** в dashboard
2. Скопируйте содержимое `supabase/migrations/001_initial_schema.sql`
3. Выполните SQL
4. Проверьте создание таблиц в **Table Editor**

### 2.3 Скопируйте ключи
1. **Settings > API**
2. Скопируйте:
   - `Project URL`
   - `anon public key`
   - `service_role key` (скрытый, нажмите "Reveal")

---

## 3. Получение API ключей (3 мин)

### 3.1 Telegram API
1. Зайдите на [my.telegram.org](https://my.telegram.org)
2. **API development tools**
3. Создайте приложение
4. Скопируйте `api_id` и `api_hash`

### 3.2 OpenAI API
1. Зайдите на [platform.openai.com](https://platform.openai.com)
2. **API Keys**
3. Создайте новый ключ
4. Скопируйте (показывается только один раз!)

### 3.3 Firebase (для push-уведомлений)
1. Создайте проект на [console.firebase.google.com](https://console.firebase.google.com)
2. Добавьте Android/iOS приложение
3. Скачайте `google-services.json` / `GoogleService-Info.plist`
4. **Project Settings > Cloud Messaging > Server key**

---

## 4. Конфигурация (2 мин)

### 4.1 Backend Worker

```bash
cd backend-worker

# Скопируйте пример конфига
cp config/config.example.yaml config/config.yaml

# Сгенерируйте ключ шифрования
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
# Скопируйте вывод
```

Отредактируйте `config/config.yaml`:

```yaml
supabase:
  url: "https://your-project.supabase.co"
  service_role_key: "your-service-role-key"

telegram:
  api_id: 12345678
  api_hash: "your-api-hash"
  session_encryption_key: "YOUR_GENERATED_KEY_HERE"

ai:
  provider: "openai"
  model: "gpt-4o-mini"
  api_key: "sk-..."
```

### 4.2 Flutter App

Создайте `lib/core/constants/api_constants.dart`:

```dart
class ApiConstants {
  static const String baseUrl = 'http://localhost:8000';
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
}
```

---

## 5. Запуск! (2 мин)

### 5.1 Запустите Backend

```bash
cd backend-worker
source venv/bin/activate

# В одном терминале: Worker
python src/worker.py

# В другом терминале: API Server
python src/api_server.py
```

Вы должны увидеть:
```
2024-12-02 14:00:00 | INFO | RecallWorker started successfully
INFO:     Uvicorn running on http://0.0.0.0:8000
```

### 5.2 Запустите Flutter App

```bash
cd flutter-app

# Подключите устройство или запустите эмулятор
flutter devices

# Запустите приложение
flutter run
```

---

## 6. Первый запуск (3 мин)

### 6.1 Авторизация
1. Откройте приложение
2. Введите свой номер телефона (формат: +7XXXXXXXXXX)
3. Получите код из Telegram
4. Введите код → Готово!

### 6.2 Выберите чаты для мониторинга
1. Нажмите **"+"** в приложении
2. Увидите список всех ваших чатов
3. Включите галочки для нужных чатов
4. Готово!

### 6.3 Проверьте работу
1. Попросите кого-нибудь написать в отслеживаемый чат:
   > "Привет! Можешь завтра отправить мне файл?"
2. Через 5-10 секунд получите push-уведомление
3. Откройте приложение → Увидите новую задачу

---

## 7. Настройка Edge Function (опционально, 5 мин)

Для полноценных push-уведомлений настройте Edge Function:

```bash
cd supabase/functions

# Установите Supabase CLI
npm install -g supabase

# Логин
supabase login

# Линк к проекту
supabase link --project-ref your-project-ref

# Deploy функции
supabase functions deploy send-task-notification

# Установите FCM key
supabase secrets set FCM_SERVER_KEY=your-firebase-server-key
```

### Настройте Database Webhook:
1. **Supabase Dashboard > Database > Webhooks**
2. **Create webhook**:
   - Table: `tasks`
   - Events: `INSERT`
   - URL: `https://your-project.supabase.co/functions/v1/send-task-notification`
   - Header: `Authorization: Bearer your-anon-key`

---

## 8. Проверка работы системы

### Проверьте логи Worker:
```bash
tail -f logs/recall_worker.log
```

### Проверьте API:
```bash
curl http://localhost:8000/health
```

Ожидаемый ответ:
```json
{
  "status": "healthy",
  "worker_running": true,
  "active_sessions": 1
}
```

### Проверьте базу данных:
```sql
-- В Supabase SQL Editor
SELECT * FROM profiles;
SELECT * FROM monitored_chats;
SELECT * FROM tasks ORDER BY created_at DESC LIMIT 5;
```

---

## Troubleshooting

### Проблема: Worker не запускается

**Ошибка:** `ImportError: No module named 'pyrogram'`

**Решение:**
```bash
source venv/bin/activate  # Активируйте venv!
pip install -r requirements.txt
```

---

### Проблема: AI не извлекает задачи

**Ошибка:** `openai.error.AuthenticationError`

**Решение:**
1. Проверьте API ключ в `config/config.yaml`
2. Проверьте баланс на [platform.openai.com](https://platform.openai.com/account/usage)

---

### Проблема: Flutter app не подключается к API

**Ошибка:** `SocketException: Connection refused`

**Решение:**
1. Убедитесь, что API server запущен (`python src/api_server.py`)
2. Проверьте `baseUrl` в `api_constants.dart`:
   - Эмулятор Android: `http://10.0.2.2:8000`
   - Реальное устройство: `http://YOUR_LOCAL_IP:8000`

Найдите ваш IP:
```bash
# Windows
ipconfig

# macOS/Linux
ifconfig | grep inet
```

---

### Проблема: Push-уведомления не приходят

**Решение:**
1. Проверьте FCM token в таблице `profiles`
2. Проверьте Database Webhook включен
3. Проверьте логи Edge Function:
   ```bash
   supabase functions logs send-task-notification
   ```

---

## Полезные команды

```bash
# Backend Worker
python src/worker.py                    # Запустить Worker
python src/api_server.py                # Запустить API
python src/ai_pipeline.py               # Тест AI Pipeline

# Flutter
flutter run                             # Запуск
flutter clean && flutter pub get        # Очистка и переустановка
flutter pub run build_runner build      # Генерация кода

# Supabase
supabase db push                        # Применить миграции
supabase functions deploy <name>        # Deploy функции
supabase functions logs <name>          # Просмотр логов

# Docker (production)
docker-compose up -d                    # Запуск всех сервисов
docker-compose logs -f worker           # Логи Worker
docker-compose down                     # Остановка
```

---

## Следующие шаги

1. **Прочитайте полный README.md** для деталей архитектуры
2. **Настройте production deployment** с Docker
3. **Добавьте мониторинг** (Prometheus + Grafana)
4. **Кастомизируйте AI промпты** в `src/prompts.py`
5. **Настройте CI/CD** для автоматического деплоя

---

## Дополнительные ресурсы

- 📚 [Полная документация](README.md)
- 🏗️ [System Design](docs/SYSTEM_DESIGN.md)
- 📱 [Flutter Architecture](flutter-app/ARCHITECTURE.md)
- 🔧 [Edge Functions Guide](supabase/functions/README.md)

---

## Поддержка

Если что-то не работает:
1. Проверьте логи: `tail -f logs/recall_worker.log`
2. Проверьте API: `curl http://localhost:8000/health`
3. Откройте Issue на GitHub
4. Напишите в Telegram: @your_username

---

**Happy coding! 🚀**
