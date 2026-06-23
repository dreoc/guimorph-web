# Deploy tkogl2.dll from cmake build output to GUImorphDevelopment inst/libs/x64/
# Run from repo root: powershell -ExecutionPolicy Bypass -File scripts/deploy-dll.ps1
#
# Optional: -Source <path-to-tkogl2.dll>
# Default: MSVC Release build-msvc/Release/tkogl2.dll, then MinGW build/tkogl2.dll fallback

param(
    [string]$Source = ""
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$TkoglRoot = Join-Path $RepoRoot "integrated-guimorph-development_EOC/Project/tkogl2"
$DestDir = Join-Path $RepoRoot "integrated-guimorph-development_EOC/Project/GUImorphDevelopment/inst/libs/x64"
$Dest = Join-Path $DestDir "tkogl2.dll"
$Backup = Join-Path $DestDir "tkogl2.dll.bak"

$DefaultCandidates = @(
    (Join-Path $TkoglRoot "build-msvc/Release/tkogl2.dll"),
    (Join-Path $TkoglRoot "build/tkogl2.dll")
)

if ($Source) {
    $Src = $Source
} else {
    $Src = $null
    foreach ($candidate in $DefaultCandidates) {
        if (Test-Path $candidate) {
            $Src = $candidate
            break
        }
    }
}

if (-not $Src -or -not (Test-Path $Src)) {
    $searched = ($DefaultCandidates -join "; ")
    throw "Build output not found. Run Native Build in BUILD.md first, or pass -Source. Searched: $searched"
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
