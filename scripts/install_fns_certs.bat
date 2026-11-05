@echo off
chcp 65001 >nul
setlocal EnableExtensions

rem ============================================================
rem  Настройка ведомственного УЦ ФНС России
rem  на АРМ Администратора Центра регистрации
rem ============================================================

rem --- Проверка прав администратора ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Запрашиваю права администратора...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "BASE_URL=http://c0000-app005/crt"
set "TMPDIR=%TEMP%\fns_certs"
set "ERRORS=0"

if not exist "%TMPDIR%" mkdir "%TMPDIR%"

echo.
echo [1/3] Корневой сертификат Минцифры -^> Доверенные корневые центры сертификации
call :install "GUC_2026.crt" Root

echo.
echo [2/3] Сертификат ведомственного УЦ ФНС России -^> Промежуточные центры сертификации
call :install "CA_FNS_Russia_2026_01.crt" CA

echo.
echo [3/3] Сертификат УЦ безопасности ФНС России -^> Доверенные корневые центры сертификации
call :install "CA_Security_2026.crt" Root

rmdir /s /q "%TMPDIR%" >nul 2>&1

echo.
if %ERRORS% equ 0 (
    echo Все сертификаты успешно установлены.
) else (
    echo Завершено с ошибками: %ERRORS%. Проверьте сообщения выше.
)
echo.
pause
exit /b %ERRORS%

rem ------------------------------------------------------------
rem  :install <имя_файла> <хранилище>
rem ------------------------------------------------------------
:install
set "FILE=%~1"
set "STORE=%~2"
set "DEST=%TMPDIR%\%FILE%"

echo   Скачивание %BASE_URL%/%FILE% ...
certutil -urlcache -split -f "%BASE_URL%/%FILE%" "%DEST%" >nul 2>&1
if not exist "%DEST%" (
    powershell -NoProfile -Command "try { Invoke-WebRequest -UseBasicParsing -Uri '%BASE_URL%/%FILE%' -OutFile '%DEST%' } catch { exit 1 }" >nul 2>&1
)
if not exist "%DEST%" (
    echo   ОШИБКА: не удалось скачать %FILE%
    set /a ERRORS+=1
    exit /b 1
)

echo   Установка в хранилище %STORE% ...
certutil -f -addstore %STORE% "%DEST%" >nul
if %errorlevel% neq 0 (
    echo   ОШИБКА: не удалось установить %FILE%
    set /a ERRORS+=1
    exit /b 1
)
echo   OK
exit /b 0
