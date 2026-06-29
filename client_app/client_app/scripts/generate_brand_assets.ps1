Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$appRoot = Split-Path -Parent $PSScriptRoot
Set-Location $appRoot

$logoPath = Join-Path $appRoot "assets\images\logo.png"
if (-not (Test-Path -LiteralPath $logoPath)) {
    throw "Logo image not found at $logoPath"
}

$dart = "dart"
$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
if ($flutterCommand) {
    $flutterBin = Split-Path -Parent $flutterCommand.Source
    $flutterRoot = Split-Path -Parent $flutterBin
    $flutterDart = Join-Path $flutterRoot "bin\cache\dart-sdk\bin\dart.exe"
    if (Test-Path -LiteralPath $flutterDart) {
        $dart = $flutterDart
    }
}

& $dart run flutter_launcher_icons
& $dart run flutter_native_splash:create
