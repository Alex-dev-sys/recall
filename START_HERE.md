# 👋 Добро пожаловать в Recall Project!

## Что это?

**Recall** - это AI-powered система, которая автоматически находит задачи в ваших Telegram-сообщениях и отправляет push-уведомления.

```
Сообщение в Telegram:
"Привет! Можешь завтра до обеда отправить мне отчет? Срочно!"
              ↓
          AI анализ
              ↓
    🔴 СРОЧНАЯ ЗАДАЧА
   Отправить отчет
  ⏰ Завтра до обеда
```

---

## ⚡ Быстрый старт

### 1️⃣ Выберите свой путь:

#### 🚀 Хочу быстро попробовать (15 минут)
→ Откройте [QUICKSTART.md](QUICKSTART.md)

#### 📚 Хочу понять всё детально
→ Откройте [README.md](README.md)

#### 🏗️ Хочу понять архитектуру
→ Откройте [docs/SYSTEM_DESIGN.md](docs/SYSTEM_DESIGN.md)

#### 🔌 Хочу интегрировать API
→ Откройте [docs/API_EXAMPLES.md](docs/API_EXAMPLES.md)

#### 📱 Разрабатываю Flutter приложение
→ Откройте [flutter-app/ARCHITECTURE.md](flutter-app/ARCHITECTURE.md)

---

## 📦 Что уже готово?

### ✅ Backend (Python)
- [x] **Worker процесс** - Слушает Telegram через Pyrogram
- [x] **AI Pipeline** - 4 этапа анализа (Extractor → Deduplicator → Deadline Parser → Prioritizer)
- [x] **REST API** - FastAPI сервер для Flutter
- [x] **Session Manager** - Шифрованное хранение сессий
- [x] **Database Manager** - Работа с Supabase

### ✅ База данных (Supabase)
- [x] **SQL схема** - 5 таблиц с Row Level Security
- [x] **Triggers** - Автоматические обновления
- [x] **Views** - Удобные запросы

### ✅ Edge Functions (TypeScript)
- [x] **Push-уведомления** - Через Firebase Cloud Messaging

### ⏳ Flutter App (архитектура готова)
- [x] Архитектурный дизайн
- [x] Примеры кода
- [ ] Полная реализация

### ✅ Документация
- [x] Полная документация
- [x] Быстрый старт
- [x] Примеры API
- [x] Системный дизайн

---

## 🛠️ Технологии

### Backend
- Python 3.10+ • Pyrogram • FastAPI • OpenAI/Anthropic

### Database
- Supabase (PostgreSQL) • Row Level Security • Real-time

### Mobile
- Flutter • Riverpod • Firebase Cloud Messaging

### Infrastructure
- Docker • docker-compose • Supabase Edge Functions (Deno)

---

## 📂 Структура проекта

```
recall-project/
├── 📁 backend-worker/       # Python Worker + API
│   ├── src/                 # Исходный код (6 файлов, ~2650 строк)
│   ├── config/              # Конфигурация
│   └── Dockerfile           # Docker deployment
│
├── 📁 supabase/             # База данных
│   ├── migrations/          # SQL схема
│   └── functions/           # Edge Functions (push)
│
├── 📁 flutter-app/          # Мобильное приложение
│   └── ARCHITECTURE.md      # Архитектура Flutter
│
├── 📁 docs/                 # Документация
│   ├── SYSTEM_DESIGN.md     # Архитектура системы
│   └── API_EXAMPLES.md      # Примеры API
│
├── 📄 README.md             # Полная документация
├── 📄 QUICKSTART.md         # Быстрый старт
└── 📄 START_HERE.md         # Этот файл
```

---

## 🎯 Что делать дальше?

### Шаг 1: Настройка окружения

```bash
# Установите зависимости
cd backend-worker
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Шаг 2: Получите API ключи

Вам понадобятся:
- ✅ Supabase аккаунт (бесплатно)
- ✅ Telegram API credentials (бесплатно)
- ✅ OpenAI API ключ ($5-10 на старт)
- ✅ Firebase проект (бесплатно)

**Где получить:**
- Supabase: [supabase.com](https://supabase.com)
- Telegram: [my.telegram.org](https://my.telegram.org)
- OpenAI: [platform.openai.com](https://platform.openai.com)
- Firebase: [console.firebase.google.com](https://console.firebase.google.com)

### Шаг 3: Настройте конфигурацию

```bash
# Скопируйте пример конфига
cp config/config.example.yaml config/config.yaml

# Отредактируйте config.yaml
nano config/config.yaml
```

### Шаг 4: Запустите!

```bash
# Примените SQL миграцию в Supabase Dashboard

# Запустите Worker
python src/worker.py

# В другом терминале: API Server
python src/api_server.py
```

---

## 📖 Полная документация

| Документ | Описание | Время чтения |
|----------|----------|--------------|
| [README.md](README.md) | Полная документация | 20 мин |
| [QUICKSTART.md](QUICKSTART.md) | Быстрый старт | 5 мин |
| [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) | Обзор проекта | 10 мин |
| [docs/SYSTEM_DESIGN.md](docs/SYSTEM_DESIGN.md) | Архитектура | 15 мин |
| [docs/API_EXAMPLES.md](docs/API_EXAMPLES.md) | Примеры API | 10 мин |
| [flutter-app/ARCHITECTURE.md](flutter-app/ARCHITECTURE.md) | Flutter архитектура | 10 мин |
| [FILES_INDEX.md](FILES_INDEX.md) | Индекс файлов | 5 мин |

---

## 💡 Примеры использования

### Пример 1: Срочная задача

**Входящее сообщение:**
> "Привет! Можешь срочно отправить мне тот отчет? Клиент ждет!"

**AI анализ:**
- **Задача:** Отправить отчет
- **Приоритет:** 🔴 Urgent (слово "срочно" + упоминание клиента)
- **Дедлайн:** +2 часа (ASAP)

**Результат:** Push-уведомление на телефон через 3-5 секунд

---

### Пример 2: Обещание с дедлайном

**Входящее сообщение:**
> "Окей, я сделаю презентацию к пятнице вечером"

**AI анализ:**
- **Задача:** Сделать презентацию
- **Тип:** Promise (обещание)
- **Приоритет:** 🔵 Medium (дедлайн через 4 дня)
- **Дедлайн:** Пятница, 18:00

**Результат:** Задача в приложении + напоминание за 24 часа

---

## 🎓 Обучающие материалы

### Видео-туториалы (планируются)
- [ ] Установка и настройка (10 мин)
- [ ] Первый запуск (5 мин)
- [ ] Разработка Flutter приложения (30 мин)
- [ ] Деплой в production (15 мин)

### Статьи
- [x] [Как работает AI Pipeline](docs/SYSTEM_DESIGN.md#4-компоненты-системы)
- [x] [Безопасность и шифрование](docs/SYSTEM_DESIGN.md#5-безопасность)
- [x] [Масштабирование](docs/SYSTEM_DESIGN.md#6-масштабируемость)

---

## 🤝 Поддержка

### Возникла проблема?

1. **Проверьте Troubleshooting** в [QUICKSTART.md](QUICKSTART.md#troubleshooting)
2. **Проверьте логи:**
   ```bash
   tail -f logs/recall_worker.log
   ```
3. **Откройте Issue на GitHub**
4. **Напишите в Telegram:** @your_username

### Хотите внести вклад?

Pull requests приветствуются! См. [README.md](README.md) для guidelines.

---

## 📊 Roadmap

### Phase 1: MVP ✅ (Done)
- [x] Python Worker с AI Pipeline
- [x] Supabase база данных
- [x] Edge Functions для push
- [x] REST API для Flutter
- [x] Полная документация

### Phase 2: Production Ready 🚧 (In Progress)
- [ ] Flutter приложение (полная реализация)
- [ ] Docker deployment
- [ ] Comprehensive testing
- [ ] CI/CD pipeline

### Phase 3: Advanced Features 📋 (Planned)
- [ ] Голосовые сообщения (Speech-to-Text)
- [ ] OCR для изображений
- [ ] Интеграция с календарем
- [ ] Web-версия
- [ ] Team collaboration

---

## 🎯 Цели проекта

### Главная цель
Помочь людям не забывать о важных обязательствах, автоматически извлекая их из повседневного общения.

### Почему это важно?
- 📱 **Средний человек пишет 100+ сообщений в день**
- 💼 **20-30% содержат какие-то обязательства**
- ❌ **Многие забываются, потому что не записаны**
- ✅ **Recall автоматизирует этот процесс**

---

## 📈 Метрики успеха

| Метрика | Целевое значение | Текущее |
|---------|-----------------|---------|
| Точность извлечения задач | >90% | TBD |
| Латентность (сообщение → push) | <5 сек | ~3-5 сек ✅ |
| False positives (ложные задачи) | <10% | TBD |
| User satisfaction | >4.5/5 | TBD |

---

## 🌟 Особенности

### Что делает Recall уникальным?

1. **AI-First подход** - Не регулярные выражения, а настоящий AI анализ
2. **Контекстное понимание** - Учитывает отправителя, чат, историю
3. **Умная дедупликация** - Не создает дубликаты задач
4. **Real-time** - 3-5 секунд от сообщения до уведомления
5. **Privacy-focused** - Все данные шифруются, RLS защита

---

## 🔥 Быстрые команды

```bash
# Backend
python src/worker.py              # Запустить Worker
python src/api_server.py          # Запустить API
tail -f logs/recall_worker.log    # Логи

# Supabase
supabase db push                  # Применить миграции
supabase functions deploy         # Deploy функции
supabase functions logs           # Логи функции

# Flutter
flutter run                       # Запуск приложения
flutter clean && flutter pub get  # Очистка

# Docker
docker-compose up -d              # Запуск
docker-compose logs -f worker     # Логи
docker-compose down               # Остановка

# Health check
curl http://localhost:8000/health
```

---

## 📞 Контакты

**Автор:** [Your Name]
**Email:** your@email.com
**Telegram:** @your_username
**GitHub:** github.com/yourusername/recall-project

---

## ⚖️ Лицензия

MIT License - используйте свободно!

---

## 🙏 Благодарности

Спасибо open-source сообществу за отличные инструменты:
- **Pyrogram** - Telegram client
- **Supabase** - Backend as a Service
- **OpenAI** - AI models
- **Flutter** - Beautiful UI framework

---

# 🚀 Начнем?

### Я готов начать работу с проектом!

→ **Новичок?** Начните с [QUICKSTART.md](QUICKSTART.md)
→ **Опытный разработчик?** Читайте [README.md](README.md)
→ **Хочу понять архитектуру?** Открывайте [docs/SYSTEM_DESIGN.md](docs/SYSTEM_DESIGN.md)

---

**Версия:** 1.0.0 MVP
**Дата:** 2024-12-02
**Статус:** ✅ Ready to Launch

**Happy coding! 🎉**
