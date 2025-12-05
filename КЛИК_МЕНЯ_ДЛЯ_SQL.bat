@echo off
chcp 65001 >nul
color 0A
cls

echo.
echo ╔══════════════════════════════════════════════════════════╗
echo ║                                                          ║
echo ║      🚀 ПРИМЕНЕНИЕ SQL МИГРАЦИИ ЗА 3 КЛИКА 🚀          ║
echo ║                                                          ║
echo ╚══════════════════════════════════════════════════════════╝
echo.
echo.
echo [Шаг 1/3] Открываю SQL Editor в браузере...
timeout /t 2 /nobreak >nul

start "" "https://supabase.com/dashboard/project/pavrkvgztgksaovujeld/sql/new"

echo ✅ Браузер открыт!
echo.
timeout /t 2 /nobreak >nul

echo [Шаг 2/3] Открываю SQL файл в Notepad...
timeout /t 1 /nobreak >nul

cd /d "%~dp0"
start notepad "supabase\migrations\001_initial_schema.sql"

echo ✅ SQL файл открыт!
echo.
timeout /t 2 /nobreak >nul

echo [Шаг 3/3] ТЕПЕРЬ ТЫ:
echo.
echo ┌─────────────────────────────────────────────┐
echo │                                             │
echo │  1️⃣  В Notepad нажми: Ctrl+A (выделить)   │
echo │                                             │
echo │  2️⃣  Нажми: Ctrl+C (скопировать)          │
echo │                                             │
echo │  3️⃣  В браузере нажми: Ctrl+V (вставить)  │
echo │                                             │
echo │  4️⃣  Нажми кнопку: RUN                     │
echo │                                             │
echo │  5️⃣  Дождись: "Success" ✅                │
echo │                                             │
echo └─────────────────────────────────────────────┘
echo.
echo.
echo ✨ ГОТОВО! База данных будет создана!
echo.
pause
