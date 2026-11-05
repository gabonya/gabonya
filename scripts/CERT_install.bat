@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: ============================================================
::  Установка корневых/промежуточных сертификатов и CRL
::  Источник: c0000-app005 (каталоги /crt/, /cdp/, /crl/)
:: ============================================================

:: Проверка прав администратора
NET SESSION >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Требуются права администратора.
    echo Запустите скрипт от имени администратора.
    pause
    exit /b 1
)

set "BASE=http://10.200.0.100"
set "CERTDIR=C:\сертификаты"
set "LOG=C:\CRL_Install.log"
set "FAILED=0"

:: Очистка старых файлов, чтобы не ставить устаревшее
for %%D in (crt cdp crl) do (
    if exist "%CERTDIR%\%%D" rmdir /s /q "%CERTDIR%\%%D"
    mkdir "%CERTDIR%\%%D" 2>nul
)

echo Начало установки %date% %time% > "%LOG%"

:: ------------------------------------------------------------
:: Скачивание /crt/  (сертификаты УЦ)
:: ------------------------------------------------------------
echo Скачивание сертификатов (/crt/)...
for %%F in (
    00C3175170000000000BD7.cer
    1f50c55fa138aa27334ed1e89bff71ac21f4dc9d.crt
    2ad94cdb41d6285c317bbb36f81425b52221b0f5.crt
    2CEB332A000000000BD6.cer
    39038e7a889c8a04bdc3e425bb6eb2024d7fd744.crt
    4683BD9C000000000BD5.cer
    5859c0d54a0ba1cfdc1db340f8d4beba4a128243.cer
    5859c0d54a0ba1cfdc1db340f8d4beba4a128243.crt
    7AA38B02798153F66A339E108D83D9D3A5A2BD6A.cer
    9f9461fd76296240e1a70a0109336e2e92ec1bea.crt
    A495D499551DE7F995C27A60426D38688EC75E89.cer
    CA_FNS_KOE_1.crt
    CA_FNS_KOE_2.crt
    CA_FNS_KOE_3.crt
    CA_FNS_Russia_1.crt
    CA_FNS_Russia_2015.crt
    CA_FNS_Russia_2017.crt
    CA_FNS_Russia_2018.crt
    CA_FNS_Russia_2019_IP.crt
    CA_FNS_Russia_2019_UL.crt
    CA_FNS_Russia_2022.crt
    CA_FNS_Russia_2022_01.crt
    CA_FNS_Russia_2022_02.crt
    CA_FNS_Russia_2023_01.crt
    CA_FNS_Russia_2023_02.crt
    CA_FNS_Russia_2024_01.crt
    CA_FNS_Russia_2024_02.crt
    CA_FNS_Russia_2025_01.crt
    CA_FNS_Russia_2025_02.crt
    CA_FNS_Russia_2026_01.crt
    ca_rtk_2020.cer
    ca_rtk_gost2012.crt
    CA_Security_2026.crt
    caGS.crt
    CROSS_DUC.p7b
    crtFNS.p7b
    guc.crt
    guc2022.crt
    guc2026.crt
    GUC_2025.crt
    GUC_2026.crt
    guc_gost2012.crt
    GUC_MKS_2022.crt
    rootGS.crt
    vguc1_5.crt
) do call :dl crt %%F

:: Файлы с пробелами/кириллицей в имени: URL в percent-encoding (%%20 = пробел)
curl -f -s -S -o "%CERTDIR%\crt\FNS_Russia_RSA.crt" "%BASE%/crt/FNS%%20Russia%%20RSA.crt" || call :fail "crt/FNS Russia RSA.crt"
:: (%%D0%%A4%%D0%%9D%%D0%%A1 = ФНС, %%D0%%A0%%D0%%BE%%D1%%81%%D1%%81%%D0%%B8%%D0%%B8 = России, %%D0%%9A%%D0%%9E%%D0%%AD = КОЭ)
curl -f -s -S -o "%CERTDIR%\crt\FNS_Rossii_2.crt" "%BASE%/crt/%%D0%%A4%%D0%%9D%%D0%%A1%%20%%D0%%A0%%D0%%BE%%D1%%81%%D1%%81%%D0%%B8%%D0%%B8%%202.crt" || call :fail "crt/ФНС России 2.crt"
curl -f -s -S -o "%CERTDIR%\crt\FNS_Rossii_3.crt" "%BASE%/crt/%%D0%%A4%%D0%%9D%%D0%%A1%%20%%D0%%A0%%D0%%BE%%D1%%81%%D1%%81%%D0%%B8%%D0%%B8%%203.crt" || call :fail "crt/ФНС России 3.crt"
curl -f -s -S -o "%CERTDIR%\crt\FNS_Rossii_KOE_2026.cer" "%BASE%/crt/%%D0%%A4%%D0%%9D%%D0%%A1_%%D0%%A0%%D0%%BE%%D1%%81%%D1%%81%%D0%%B8%%D0%%B8_%%D0%%9A%%D0%%9E%%D0%%AD_2026.cer" || call :fail "crt/ФНС_России_КОЭ_2026.cer"

:: ------------------------------------------------------------
:: Скачивание /cdp/
:: ------------------------------------------------------------
echo Скачивание сертификатов и CRL (/cdp/)...
for %%F in (
    06ff0ba33c2ea7bf0223fb9c31697f1334ede5e2.crl
    0da4be6542fec3fa3988caabbab7b38ce19cf0b0.crl
    13b64f4d7c2023ed600120a4029d00af3f8ff7e4.crl
    163D4290BF0A9C881766B9264F928470A3D705DB.crl
    1B5F67C6A9D0F2893A9F130775B7576596551701.crl
    1f50c55fa138aa27334ed1e89bff71ac21f4dc9d.crl
    23f0da4a5de30c96e91f976a3e641689a1f8553c.crl
    2ad94cdb41d6285c317bbb36f81425b52221b0f5.crl
    2ec19ae0672330515ee0d0a4b4174c18a6d2d00f.crl
    2fb731cee8b0c1f4b4d8ba324f53fb0e3158cabf.crl
    3460b09c616fc3d01b160a78df55506d097f2154.crl
    39038e7a889c8a04bdc3e425bb6eb2024d7fd744.crl
    47176fec1d829cfd5dbc288bfcf01f1ac905e605.crl
    4e5c543b70fefd74c7597304f2cacad7967078e4.crl
    5859c0d54a0ba1cfdc1db340f8d4beba4a128243.crl
    5cf20720044c2197800678f72c79b143747939e9.crl
    5ed7a78b451f46fae96b8959023f640f146ef1d7.crl
    6bd5fc58602420a87f965ff9fd4419d0be922288.crl
    864395c3ca5224ea882d7dd2675533f3c1c19c48.crl
    8b983b891851e8ef9c0278b8eac8d420b255c95d.crl
    9f9461fd76296240e1a70a0109336e2e92ec1bea.crl
    9fc27358a874816a606d33f447a468a67639679b.crl
    ac53bead76ac54d0880675d705c58b01b5abbe94.crl
    aeec619ebfcd5254b7ebb5c5b2842e161bb21f4c.crl
    bd1c4b912fc654e5f4e2e44992255f40ae42ea6a.crl
    c1836f3194b61e57ba10a847870a51e399cb07d0.crl
    c2364dcc24260a439625305b67579b2ac9439cd5.crl
    c254f1b46bd44cb7e06d36b42390f1fec33c9b06.crl
    c91358b14ca7623a7ed23f3ca6e7147c9d70a386.crl
    c987263a676296a707343f9895a81aceada6ef2d.crl
    ca_rtk_2020.crl
    ca_rtk_gost2012.crl
    d156fb382c4c55ad7eb3ae0ac66749577f87e116.crl
    d195f49eae9a03d78278e7d91f560a55e0c09fa7.crl
    da02413b5df67e675f8817ecd8555ddca27ee352.crl
    e0aca23183615a27ac05b888102fd46009b6fae4.crl
    e7a4b88fc93bc1e746bf24f8e2fcd7f40a7c67d0.crl
    e91f07442c45b2cf599ee949e5d83e8382b94a50.crl
    f4d870f66acb1f6cd5a6bd9d5f00ee159ddcbc54.crl
    fcb21945f2bb7670b371b03cee94381d4f975cd5.crl
    guc.crl
    guc.crt
    guc2021.crl
    guc2022.crl
    guc2025.crl
    guc2026.crl
    guc2026.crt
    guc_gost12.crl
    guc_gost12.crt
    vguc1_5.crl
    vguc1_5.crt
) do call :dl cdp %%F

:: ------------------------------------------------------------
:: Скачивание /crl/
:: ------------------------------------------------------------
echo Скачивание сертификатов и CRL (/crl/)...
for %%F in (
    13b64f4d7c2023ed600120a4029d00af3f8ff7e4.crl
    1B5F67C6A9D0F2893A9F130775B7576596551701.crl
    23f0da4a5de30c96e91f976a3e641689a1f8553c.crl
    3460b09c616fc3d01b160a78df55506d097f2154.crl
    4e5c543b70fefd74c7597304f2cacad7967078e4.crl
    5cf20720044c2197800678f72c79b143747939e9.crl
    6C580D6F11265CD6C8A06B83B7268AAD797FA065.crl
    9178E3ADD6808B712AD63C905729AA6EE80E661D.crl
    aeec619ebfcd5254b7ebb5c5b2842e161bb21f4c.crl
    C987263A676296A707343F9895A81ACEADA6EF2D.crl
    d156fb382c4c55ad7eb3ae0ac66749577f87e116.crl
    DA02413B5DF67E675F8817ECD8555DDCA27EE352.crl
    e91f07442c45b2cf599ee949e5d83e8382b94a50.crl
    e91f07442c45b2cf599ee949e5d83e8382b94a50_.crl
    F4D870F66ACB1F6CD5A6BD9D5F00EE159DDCBC54.crl
    fcb21945f2bb7670b371b03cee94381d4f975cd5.crl
    gsgccr3dvtlsca2020.crl
    Kaznacheystvo-Rossii.crt
    lk.budget.gov.ru.CRT
    ucfk.crl
    ucfk_2020.crl
    ucfk_2020.crt
    ucfk_2021.crl
    ucfk_2021.crt
    ucfk_2022.crl
    ucfk_2023.crl
    ucfk_2023.crt
    ucfk_2024.crl
    ucfk_2024.crt
    ucfk_2025.crl
    ucfk_2025.crt
    ucfk_2025_1.crl
    ucfk_2025_1.crt
    ucfk_2026.crl
    ucfk_2026.crt
    ucfk_2026_1.crl
    ucfk_2026_1.crt
    ucfk_gost12.crl
    ucfk_gost12.crt
) do call :dl crl %%F

:: ------------------------------------------------------------
:: Установка сертификатов
::   самоподписанные   = Доверенные корневые центры (ROOT)
::   остальные УЦ      = Промежуточные центры (CA)
::   конечные (не УЦ)  = пропускаются
:: Скрипт PowerShell находится в конце этого файла.
:: ------------------------------------------------------------
echo Установка сертификатов...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=(Get-Content -LiteralPath '%~f0' -Encoding UTF8 -Raw) -split '(?m)^::PS_BEGIN::\r?$'; Invoke-Expression $s[1]" >> "%LOG%" 2>&1
if errorlevel 1 (
    echo   Есть ошибки при установке сертификатов, см. %LOG%
    set "FAILED=1"
)

:: ------------------------------------------------------------
:: Установка CRL
:: ------------------------------------------------------------
echo Установка CRL...
for %%D in (cdp crl) do (
    for %%F in ("%CERTDIR%\%%D\*.crl") do (
        certutil -addstore -f "CA" "%%~fF" >nul 2>&1
        if errorlevel 1 (
            echo   ОШИБКА установки CRL: %%D\%%~nxF
            echo ОШИБКА установки CRL: %%D\%%~nxF >> "%LOG%"
            set "FAILED=1"
        )
    )
)

:: Обновление кэша цепочек
certutil -setreg chain\ChainCacheResyncFiletime @now >nul

:: Очистка кэша URL (CRL/AIA)
certutil -urlcache * delete >nul

echo Установка завершена %date% %time% >> "%LOG%"

:: Перезапуск службы криптографии
net stop cryptsvc /y
net start cryptsvc

echo.
if "%FAILED%"=="1" (
    echo Установка завершена С ОШИБКАМИ. Подробности: %LOG%
) else (
    echo Установка завершена успешно.
)
pause
exit /b 0


:: ============================================================
:: Подпрограммы
:: ============================================================

:: :dl <папка на сервере> <имя файла>
:dl
echo   %~1/%~2
curl -f -s -S -o "%CERTDIR%\%~1\%~2" "%BASE%/%~1/%~2"
if errorlevel 1 call :fail "%~1/%~2"
exit /b 0

:fail
echo   ОШИБКА скачивания: %~1
echo ОШИБКА скачивания: %~1 >> "%LOG%"
set "FAILED=1"
exit /b 0


:: ============================================================
:: Ниже - PowerShell-часть (cmd сюда не доходит из-за exit /b)
:: ============================================================
::PS_BEGIN::
$ErrorActionPreference = 'Stop'
$X = 'System.Security.Cryptography.X509Certificates'
$root = New-Object "$X.X509Store" 'Root', 'LocalMachine'
$ca   = New-Object "$X.X509Store" 'CA',   'LocalMachine'
$root.Open('ReadWrite'); $ca.Open('ReadWrite')
$errors = 0
$files = Get-ChildItem -Path (Join-Path $env:CERTDIR '*\*') -Include *.cer, *.crt, *.p7b -File
foreach ($f in $files) {
    $rel = $f.Directory.Name + '\' + $f.Name
    try {
        $col = New-Object "$X.X509Certificate2Collection"
        $col.Import($f.FullName)
        foreach ($c in $col) {
            $bc = $c.Extensions | Where-Object { $_ -is [System.Security.Cryptography.X509Certificates.X509BasicConstraintsExtension] }
            if ($bc -and -not $bc.CertificateAuthority) {
                Write-Output ("SKIP  {0} | {1}" -f $rel, $c.Subject)
                continue
            }
            if ($c.Subject -eq $c.Issuer) { $root.Add($c); $t = 'ROOT' } else { $ca.Add($c); $t = 'CA  ' }
            Write-Output ("{0}  {1} | {2}" -f $t, $rel, $c.Subject)
        }
    } catch {
        Write-Output ("ERROR {0} | {1}" -f $rel, $_.Exception.Message)
        $errors++
    }
}
$root.Close(); $ca.Close()
Write-Output ("Processed files: {0}, errors: {1}" -f $files.Count, $errors)
if ($errors -gt 0) { exit 1 }
