@echo off
chcp 65001 >nul
color 0B
cls

echo.
echo ╔══════════════════════════════════════════════════════════╗
echo ║                                                          ║
echo ║      📱 ПОЛУЧЕНИЕ TELEGRAM API CREDENTIALS 📱           ║
echo ║                                                          ║
echo ╚══════════════════════════════════════════════════════════╝
echo.
echo.
echo [Шаг 1/3] Открываю my.telegram.org...
timeout /t 2 /nobreak >nul

start "" "https://my.telegram.org"

echo ✅ Сайт открыт!
echo.
timeout /t 2 /nobreak >nul

echo [Шаг 2/3] Открываю config.yaml для редактирования...
timeout /t 1 /nobreak >nul

cd /d "%~dp0"
start notepad "backend-worker\config\config.yaml"

echo ✅ Config открыт!
echo.
timeout /t 2 /nobreak >nul

echo [Шаг 3/3] ИНСТРУКЦИЯ:
echo.
echo ┌─────────────────────────────────────────────┐
echo │  В БРАУЗЕРЕ:                                │
echo │                                             │
echo │  1️⃣  Войди через свой номер телефона      │
echo │                                             │
echo │  2️⃣  Введи код из Telegram                │
echo │                                             │
echo │  3️⃣  Нажми: API development tools          │
echo │                                             │
echo │  4️⃣  Заполни форму:                        │
echo │     App title: Recall Bot                  │
echo │     Short name: recall                     │
echo │     Platform: Other                        │
echo │                                             │
echo │  5️⃣  Нажми: Create application             │
echo │                                             │
echo │  6️⃣  Скопируй:                             │
echo │     api_id (число)                         │
echo │     api_hash (строка)                      │
echo │                                             │
echo └─────────────────────────────────────────────┘
echo.
echo ┌─────────────────────────────────────────────┐
echo │  В NOTEPAD (config.yaml):                  │
echo │                                             │
echo │  Найди раздел telegram: (строки 11-14)    │
echo │                                             │
echo │  Замени:                                    │
echo │    api_id: 12345678  ← твой api_id         │
echo │    api_hash: "abc..."  ← твой api_hash     │
echo │                                             │
echo │  Сохрани: Ctrl+S                           │
echo │                                             │
echo └─────────────────────────────────────────────┘
echo.
echo.
echo ✨ После этого запусти: backend-worker\start_worker.bat
echo.
pause
