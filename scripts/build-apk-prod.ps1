# Garante APP_ENV=production no .env antes do build.
Set-Location (Split-Path $PSScriptRoot -Parent)

$envFile = Join-Path $PWD '.env'
if (-not (Test-Path $envFile)) {
  Copy-Item '.env.example' '.env'
  (Get-Content '.env') -replace 'APP_ENV=local', 'APP_ENV=production' | Set-Content '.env'
}

(Get-Content $envFile) | ForEach-Object {
  if ($_ -match '^\s*APP_ENV\s*=') { 'APP_ENV=production'; return }
  $_
} | Set-Content $envFile.tmp
Move-Item -Force $envFile.tmp $envFile

flutter build apk --release
Write-Host ""
Write-Host "APK: build\app\outputs\flutter-apk\app-release.apk"
Write-Host "Confirme no .env: APP_ENV=production e URLs da VPS."
