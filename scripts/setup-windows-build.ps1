# Instala dependencias de build Windows (NuGet para flutter_tts).
# Executar uma vez por maquina ou quando o build falhar com "nuget.exe not found".
#
# Uso (na pasta luditeca_app):
#   powershell -ExecutionPolicy Bypass -File .\scripts\setup-windows-build.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$toolsDir = Join-Path $root "tools"
$nugetPath = Join-Path $toolsDir "nuget.exe"

if (-not (Test-Path $toolsDir)) {
    New-Item -ItemType Directory -Path $toolsDir | Out-Null
}

if (Test-Path $nugetPath) {
    Write-Host "NuGet ja existe: $nugetPath"
} else {
    Write-Host "A transferir nuget.exe..."
    $url = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
    Invoke-WebRequest -Uri $url -OutFile $nugetPath -UseBasicParsing
    Write-Host "NuGet instalado em: $nugetPath"
}

$globalNuget = Get-Command nuget -ErrorAction SilentlyContinue
if ($globalNuget) {
    Write-Host "nuget global: $($globalNuget.Source)"
} else {
    Write-Host "nuget global: nao encontrado (OK - o CMake usa tools\nuget.exe)"
}

Write-Host ""
Write-Host "Proximo passo: flutter run -d windows"
