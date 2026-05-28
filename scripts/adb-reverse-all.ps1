# Redireciona a porta 3020 do host para TODOS os emuladores/dispositivos ligados.
$adb = "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe"
if (-not (Test-Path $adb)) {
    $adb = "$env:ANDROID_HOME\platform-tools\adb.exe"
}
if (-not (Test-Path $adb)) {
    Write-Warning "adb nao encontrado. Instale Android SDK platform-tools."
    exit 1
}

$lines = & $adb devices 2>&1
$serials = $lines | Where-Object { $_ -match '\tdevice$' } | ForEach-Object { ($_ -split '\t')[0] }

if (-not $serials) {
    Write-Warning "Nenhum dispositivo Android ligado."
    exit 0
}

foreach ($serial in $serials) {
    & $adb -s $serial reverse tcp:3020 tcp:3020
    Write-Host "[$serial] adb reverse tcp:3020 -> host:3020"
    & $adb -s $serial reverse --list
}
