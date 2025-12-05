@echo off
echo ========================================
echo   Recall Bot - Запуск Worker
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

echo Запуск Worker...
echo (Для остановки нажмите Ctrl+C)
echo.
python src\worker.py

pause
