# Deploy tkogl2.dll from cmake build output to GUImorphDevelopment inst/libs/x64/
# Run from repo root: powershell -ExecutionPolicy Bypass -File scripts/deploy-dll.ps1

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$Src = Join-Path $RepoRoot "integrated-guimorph-development_EOC/Project/tkogl2/build/tkogl2.dll"
$DestDir = Join-Path $RepoRoot "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/inst/libs/x64"
$Dest = Join-Path $DestDir "tkogl2.dll"
$Backup = Join-Path $DestDir "tkogl2.dll.bak"

if (-not (Test-Path $Src)) {
    throw "Build output not found: $Src — run Native Build in BUILD.md first."
}

if (-not (Test-Path $DestDir)) {
    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
}

$BackupPath = "none"
if (Test-Path $Dest) {
    Copy-Item -Path $Dest -Destination $Backup -Force
    $BackupPath = $Backup
}

Copy-Item -Path $Src -Destination $Dest -Force

Write-Host "Deployed tkogl2.dll"
Write-Host "  Source:  $Src"
Write-Host "  Dest:    $Dest"
Write-Host "  Backup:  $BackupPath"
