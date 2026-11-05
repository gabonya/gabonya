@echo off
chcp 65001 >nul
setlocal EnableExtensions

rem ============================================================
rem  Настройка ведомственного УЦ ФНС России
rem  на АРМ Администратора Центра регистрации
rem
rem  Запускать: правой кнопкой -> "Запуск от имени администратора".
rem  Если файлы .crt лежат рядом с этим .bat, они берутся оттуда,
rem  иначе скачиваются с http://c0000-app005/crt/
rem ============================================================

net session >nul 2>&1
if errorlevel 1 (
    echo Нужны права администратора.
    echo Нажмите на файл правой кнопкой и выберите "Запуск от имени администратора".
    echo.
    pause
    exit /b 1
)

set "BASE_URL=http://c0000-app005/crt"
set "SRC=%~dp0"
set "ERRORS=0"

echo.
echo [1/3] Корневой сертификат Минцифры -^> Доверенные корневые центры сертификации
call :install "GUC_2026.crt" Root

echo.
echo [2/3] Сертификат ведомственного УЦ ФНС России -^> Промежуточные центры сертификации
call :install "CA_FNS_Russia_2026_01.crt" CA

echo.
echo [3/3] Сертификат УЦ безопасности ФНС России -^> Доверенные корневые центры сертификации
call :install "CA_Security_2026.crt" Root

echo.
if %ERRORS% equ 0 (
    echo Все сертификаты успешно установлены.
) else (
    echo Завершено с ошибками: %ERRORS%. Проверьте сообщения выше.
)
echo.
pause
exit /b %ERRORS%

:install
set "FILE=%~1"
set "STORE=%~2"
set "CRT=%SRC%%FILE%"

if exist "%CRT%" (
    echo   Найден файл рядом со скриптом: %FILE%
) else (
    set "CRT=%TEMP%\%FILE%"
    echo   Скачивание %BASE_URL%/%FILE% ...
    powershell -NoProfile -Command "Invoke-WebRequest -UseBasicParsing -Uri '%BASE_URL%/%FILE%' -OutFile '%TEMP%\%FILE%'"
)
if not exist "%CRT%" (
    echo   ОШИБКА: файл %FILE% не найден и не скачан
    set /a ERRORS+=1
    exit /b 1
)

certutil -f -addstore %STORE% "%CRT%"
if errorlevel 1 (
    echo   ОШИБКА: не удалось установить %FILE%
    set /a ERRORS+=1
    exit /b 1
)
echo   OK
exit /b 0
