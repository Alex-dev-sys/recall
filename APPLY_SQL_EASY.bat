@echo off
echo ========================================
echo   Открываем SQL Editor в браузере...
echo ========================================
echo.

REM Открыть SQL Editor в браузере
start "" "https://supabase.com/dashboard/project/pavrkvgztgksaovujeld/sql/new"

echo ✅ Браузер открыт!
echo.
echo Теперь:
echo   1. В Проводнике откройте:
echo      supabase\migrations\001_initial_schema.sql
echo.
echo   2. Скопируйте весь текст (Ctrl+A, Ctrl+C)
echo.
echo   3. Вставьте в браузер (Ctrl+V)
echo.
echo   4. Нажмите кнопку RUN
echo.
echo Готово!
echo.
pause

REM Открыть файл миграции в Notepad
start notepad "supabase\migrations\001_initial_schema.sql"

echo.
echo SQL файл открыт в Notepad
echo Скопируйте его и вставьте в браузер
echo.
pause
