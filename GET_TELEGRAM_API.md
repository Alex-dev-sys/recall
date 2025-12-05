# 📱 Получение Telegram API Credentials

## Шаг 1: Открыть my.telegram.org

Перейдите по ссылке: **https://my.telegram.org**

## Шаг 2: Войти в аккаунт

1. Введите ваш номер телефона в международном формате
   - Пример для России: `+7 900 123 45 67`
   - Пример для Украины: `+380 50 123 45 67`

2. Нажмите **Next**

3. Введите код подтверждения из Telegram

4. Если включена 2FA - введите пароль

## Шаг 3: Создать приложение

1. После входа нажмите **API development tools**

2. Заполните форму:
   ```
   App title:        Recall Bot
   Short name:       recall
   Platform:         Other
   Description:      Personal task extraction bot
   ```

3. Нажмите **Create application**

## Шаг 4: Скопировать credentials

После создания вы увидите:

```
App api_id:      12345678
App api_hash:    a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
```

**Важно:** Не делитесь этими данными!

## Шаг 5: Обновить config.yaml

Откройте файл:
```
C:\Users\user\OneDrive\Desktop\Scribe\recall-project\backend-worker\config\config.yaml
```

Найдите раздел `telegram:` и замените:

```yaml
telegram:
  api_id: 12345678  # 👈 Вставьте ваш api_id (только число, без кавычек)
  api_hash: "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6"  # 👈 Вставьте ваш api_hash (в кавычках)
  session_encryption_key: "xK9mQ7nP5wR2tY8uI3oL6aS1dF4gH7jK0zA9mB5vN2cX8qW1eR4tY7uI0oP3aS6dF9gH2jK5zL8xC1vB4nM7=="  # ✅ Уже настроен
```

**Сохраните файл (Ctrl+S)**

## Шаг 6: Готово! 🎉

Теперь можно запускать Worker:

```powershell
cd C:\Users\user\OneDrive\Desktop\Scribe\recall-project\backend-worker
.\start_worker.bat
```

---

## ❓ FAQ

### Q: Можно ли использовать один api_id для нескольких ботов?
A: Да, один api_id можно использовать для нескольких приложений.

### Q: Что делать если потерял api_hash?
A: Зайдите снова на my.telegram.org → API development tools → Ваше приложение

### Q: Можно ли удалить приложение?
A: Да, но тогда нужно будет создать новое и обновить конфиг.

### Q: Это безопасно?
A: Да, эти credentials используются только для подключения к Telegram API. Worker работает от вашего имени и не имеет доступа к вашим паролям.

---

**Следующий шаг:** Запустите `setup.bat` для установки зависимостей
