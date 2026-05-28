# Liga o emulador Android à API local (porta 3020) e inicia o Flutter.
# Uso: .\scripts\dev-android.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

$adb = "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe"
if (-not (Test-Path $adb)) {
    $adb = "$env:ANDROID_HOME\platform-tools\adb.exe"
}

$defines = @(
    "--dart-define=APP_ENV=local",
    "--dart-define=DATA_SOURCE=vps_api",
    "--dart-define=API_BASE_URL=http://localhost:3020",
    "--dart-define=MEDIA_BASE_URL=http://localhost:3020/media"
)

if (Test-Path $adb) {
    & powershell -ExecutionPolicy Bypass -File "$root\scripts\adb-reverse-all.ps1"
    $defines += "--dart-define=ANDROID_DEV_HOST=127.0.0.1"
} else {
    $lan = Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object { $_.InterfaceAlias -notmatch 'Loopback' -and $_.IPAddress -notmatch '^169\.' } |
        Select-Object -First 1 -ExpandProperty IPAddress
    if (-not $lan) {
        throw "Sem adb e sem IP LAN. Instale Android SDK platform-tools ou ligue Wi-Fi."
    }
    Write-Host "adb ausente — usando IP LAN: $lan"
    $defines += "--dart-define=ANDROID_DEV_HOST=$lan"
}

flutter run @defines
