# Atalho: garante production no .env e corre no Windows.
Set-Location (Split-Path $PSScriptRoot -Parent)
$path = '.env'
if (Test-Path $path) {
  (Get-Content $path) | ForEach-Object {
    if ($_ -match '^\s*APP_ENV\s*=') { 'APP_ENV=production'; return }
    $_
  } | Set-Content "$path.tmp"
  Move-Item -Force "$path.tmp" $path
}
flutter run -d windows
