@echo off
chcp 65001 >nul
color 0E
cls

echo.
echo ╔══════════════════════════════════════════════════════════╗
echo ║                                                          ║
echo ║           🔍 ПРОВЕРКА ВСЕГО ПРОЕКТА 🔍                  ║
echo ║                                                          ║
echo ╚══════════════════════════════════════════════════════════╝
echo.
echo.

cd /d "%~dp0"

echo [1/3] Проверка config.yaml...
echo ════════════════════════════════════════════════════════════
python check_config.py
if %errorlevel% neq 0 (
    echo.
    echo ⚠️  Config has issues - see above
    echo.
)
echo.
timeout /t 2 /nobreak >nul

echo [2/3] Проверка Python синтаксиса...
echo ════════════════════════════════════════════════════════════
python check_syntax.py
if %errorlevel% neq 0 (
    echo.
    echo ❌ Syntax errors found!
    echo.
)
echo.
timeout /t 2 /nobreak >nul

echo [3/3] Проверка зависимостей...
echo ════════════════════════════════════════════════════════════
if exist venv (
    call venv\Scripts\activate.bat
    python -c "import pyrogram, supabase, openai, yaml, loguru; print('✅ All main dependencies installed')" 2>nul
    if %errorlevel% neq 0 (
        echo ⚠️  Some dependencies missing
        echo Run: setup.bat
    )
) else (
    echo ⚠️  Virtual environment not found
    echo Run: setup.bat
)
echo.

echo ╔══════════════════════════════════════════════════════════╗
echo ║                                                          ║
echo ║                 ✅ ПРОВЕРКА ЗАВЕРШЕНА                   ║
echo ║                                                          ║
echo ╚══════════════════════════════════════════════════════════╝
echo.
pause
