@echo off
echo ========================================
echo   Recall Bot - Запуск API Server
echo ========================================
echo.

cd /d "%~dp0"

echo Активация виртуального окружения...
if not exist venv (
    echo ❌ Виртуальное окружение не найдено!
    echo Сначала запустите: setup.bat
    pause
    exit /b 1
)

call venv\Scripts\activate.bat
echo ✅ Окружение активировано
echo.

echo Запуск API Server на http://localhost:8000
echo Документация: http://localhost:8000/docs
echo (Для остановки нажмите Ctrl+C)
echo.
python src\api_server.py

pause
