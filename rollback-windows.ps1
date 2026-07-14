#Requires -RunAsAdministrator
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$ManagedDir  = "C:\Program Files\ClaudeCode"
$ManagedFile = Join-Path $ManagedDir "managed-settings.json"

Write-Host "== Claude Code managed settings rollback (Windows) =="

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script must be run from an elevated (Administrator) PowerShell session."
    exit 1
}

if (-not (Test-Path $ManagedDir)) {
    Write-Host "No managed settings directory found. Nothing to roll back."
    exit 0
}

$LatestBackup = Get-ChildItem -Path $ManagedDir -Filter "managed-settings.json.bak.*" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if ($LatestBackup) {
    Write-Host "Found a prior backup:"
    Write-Host "  $($LatestBackup.FullName)"
    $ans = Read-Host "Restore this backup instead of just removing the hardened settings? [y/N]"
    if ($ans -match '^[Yy]$') {
        Copy-Item -Path $LatestBackup.FullName -Destination $ManagedFile -Force
        Write-Host "Restored previous managed-settings.json."
        exit 0
    }
}

if (Test-Path $ManagedFile) {
    Write-Host "Removing managed-settings.json..."
    Remove-Item -Path $ManagedFile -Force
    Write-Host "Removed. Claude Code will no longer apply the hardened org policy on this machine."
}
else {
    Write-Host "No managed-settings.json found. Nothing to remove."
}

Write-Host ""
Write-Host "Note: backup files (if any) were left in place at:"
Write-Host "  $ManagedDir"
Write-Host "Delete them manually if you no longer need them."
