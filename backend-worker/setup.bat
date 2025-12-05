@echo off
echo ========================================
echo   Recall Bot - Установка зависимостей
echo ========================================
echo.

cd /d "%~dp0"

echo [1/4] Проверка Python...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python не найден!
    echo Установите Python с https://www.python.org/downloads/
    echo Не забудьте поставить галочку "Add Python to PATH"
    pause
    exit /b 1
)
python --version
echo ✅ Python найден
echo.

echo [2/4] Создание виртуального окружения...
if exist venv (
    echo Виртуальное окружение уже существует
) else (
    python -m venv venv
    echo ✅ Виртуальное окружение создано
)
echo.

echo [3/4] Активация виртуального окружения...
call venv\Scripts\activate.bat
echo ✅ Активировано
echo.

echo [4/4] Установка зависимостей...
pip install --upgrade pip
pip install -r requirements.txt
echo ✅ Зависимости установлены
echo.

echo ========================================
echo   Установка завершена!
echo ========================================
echo.
echo Теперь выполните:
echo   1. Получите Telegram API на https://my.telegram.org
echo   2. Обновите config\config.yaml (api_id и api_hash)
echo   3. Запустите: start_worker.bat
echo.
pause
