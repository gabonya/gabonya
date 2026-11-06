@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

rem ============ НАСТРОЙКИ ============
rem Сервер с папками
set "SERVER=c0000-app005"
rem Сетевой путь к серверу (UNC)
set "BASE=\\%SERVER%"
rem Префикс веб-ссылок (http или https)
set "URLBASE=http://%SERVER%"
rem Тип ссылок в блокноте: http - веб-ссылки, unc - сетевые пути
set "LINK_TYPE=http"
rem Папки для обхода
set "FOLDERS=crt cdp crl"
rem Куда сохранять блокноты (рядом с bat-файлом)
set "OUT=%~dp0links"
rem ===================================

if not exist "%OUT%" mkdir "%OUT%"

for %%F in (%FOLDERS%) do (
    set "SRC=%BASE%\%%F"
    set "TXT=%OUT%\%%F.txt"
    set /a COUNT=0

    if exist "!SRC!\" (
        echo Обработка !SRC! ...
        > "!TXT!" echo Папка: !SRC!
        >> "!TXT!" echo Дата: %DATE% %TIME%
        >> "!TXT!" echo.

        for /f "delims=" %%L in ('dir /s /b /a-d "!SRC!" 2^>nul') do (
            set "P=%%L"
            if /i "%LINK_TYPE%"=="http" (
                set "P=!P:%BASE%=%URLBASE%!"
                set "P=!P:\=/!"
                set "P=!P: =%%20!"
            )
            >> "!TXT!" echo !P!
            set /a COUNT+=1
        )

        >> "!TXT!" echo.
        >> "!TXT!" echo Всего ссылок: !COUNT!
        echo   найдено: !COUNT! -^> !TXT!
    ) else (
        echo [ОШИБКА] Папка недоступна: !SRC!
        > "!TXT!" echo Папка недоступна: !SRC!
    )
)

echo.
echo Готово. Файлы сохранены в: %OUT%
start "" "%OUT%"
pause
