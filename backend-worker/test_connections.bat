@echo off
echo ========================================
echo   Recall Bot - Тест подключений
echo ========================================
echo.

cd /d "%~dp0"

if not exist venv (
    echo ❌ Виртуальное окружение не найдено!
    echo Сначала запустите: setup.bat
    pause
    exit /b 1
)

call venv\Scripts\activate.bat
echo ✅ Окружение активировано
echo.

echo [1/2] Тестирование Supabase...
python test_supabase_connection.py
echo.

echo [2/2] Тестирование GPT Lama API...
python test_gptlama_api.py
echo.

echo ========================================
echo   Тестирование завершено
echo ========================================
pause
