<# : ===== часть для cmd (PowerShell считает это комментарием) =====
@echo off
chcp 65001 >nul
set "BAT_DIR=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content -LiteralPath '%~f0' -Encoding UTF8) -join [Environment]::NewLine)"
pause
exit /b
#>
# ===== часть на PowerShell =====

# ------------ НАСТРОЙКИ ------------
$Server  = 'http://c0000-app005'      # адрес сервера
$Folders = 'crt', 'cdp', 'crl'         # папки для обхода
$Recurse = $true                       # заходить во вложенные папки
$OutDir  = Join-Path $env:BAT_DIR 'links'
# -----------------------------------

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

function Get-Links([string]$Url, [hashtable]$Seen) {
    if ($Seen.ContainsKey($Url)) { return }
    $Seen[$Url] = $true

    $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing -UseDefaultCredentials -TimeoutSec 120
    $base = New-Object System.Uri($Url)

    foreach ($m in [regex]::Matches($resp.Content, 'href\s*=\s*"([^"]+)"', 'IgnoreCase')) {
        $href = [System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value)
        $abs  = (New-Object System.Uri($base, $href)).AbsoluteUri

        # пропускаем [To Parent Directory], саму папку и чужие ссылки
        if (-not $abs.StartsWith($Url, [StringComparison]::OrdinalIgnoreCase)) { continue }
        if ($abs.Length -eq $Url.Length) { continue }

        if ($abs.EndsWith('/')) {
            if ($Recurse) { Get-Links $abs $Seen }
        } else {
            $abs
        }
    }
}

foreach ($f in $Folders) {
    $url = $Server.TrimEnd('/') + '/' + $f.Trim('/') + '/'
    $txt = Join-Path $OutDir ($f + '.txt')
    Write-Host "Обработка $url ..."
    try {
        $links = @(Get-Links $url @{} | Sort-Object -Unique)
        $lines = @("Папка: $url", "Дата: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')", '') +
                 $links + @('', "Всего ссылок: $($links.Count)")
        Set-Content -LiteralPath $txt -Value $lines -Encoding UTF8
        Write-Host "  найдено: $($links.Count) -> $txt"
    } catch {
        Write-Host "  [ОШИБКА] $url : $($_.Exception.Message)" -ForegroundColor Red
        Set-Content -LiteralPath $txt -Value "Ошибка доступа к $url : $($_.Exception.Message)" -Encoding UTF8
    }
}

Write-Host ''
Write-Host "Готово. Файлы сохранены в: $OutDir"
Start-Process explorer.exe $OutDir
