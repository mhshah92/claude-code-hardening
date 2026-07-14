#Requires -RunAsAdministrator
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$ManagedDir  = "C:\Program Files\ClaudeCode"
$ManagedFile = Join-Path $ManagedDir "managed-settings.json"
$Timestamp   = Get-Date -Format "yyyyMMddHHmmss"
$BackupFile  = Join-Path $ManagedDir "managed-settings.json.bak.$Timestamp"

Write-Host "== Claude Code managed settings installer (Windows) =="

# Confirm elevation explicitly (in addition to #Requires -RunAsAdministrator,
# in case this script is dot-sourced or the requires check is bypassed)
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script must be run from an elevated (Administrator) PowerShell session."
    exit 1
}

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "Claude Code not found on PATH. Install it first: npm install -g @anthropic-ai/claude-code"
    exit 1
}

Write-Host ""
Write-Host "NOTE: Claude Code's Bash sandbox is not supported on native Windows (Seatbelt"
Write-Host "and bubblewrap have no Windows equivalent, and WSL1 is not supported either)."
Write-Host "This policy applies permission deny rules only. For real sandbox enforcement,"
Write-Host "run Claude Code inside WSL2 and use install-linux.sh there instead."
Write-Host ""

Write-Host "Creating managed settings directory..."
New-Item -ItemType Directory -Path $ManagedDir -Force | Out-Null

if (Test-Path $ManagedFile) {
    Write-Host "Existing managed-settings.json found — backing it up to:"
    Write-Host "  $BackupFile"
    Copy-Item -Path $ManagedFile -Destination $BackupFile -Force
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SourceFile = Join-Path $ScriptDir "managed-settings.json"

Write-Host "Copying managed-settings.json from repository..."
Copy-Item $SourceFile $ManagedFile -Force

Write-Host "Validating JSON..."
try {
    Get-Content -Raw -Path $ManagedFile | ConvertFrom-Json -ErrorAction Stop | Out-Null
}
catch {
    Write-Host "ERROR: written file is not valid JSON. Restoring previous state if a backup exists."
    if (Test-Path $BackupFile) {
        Copy-Item -Path $BackupFile -Destination $ManagedFile -Force
    }
    else {
        Remove-Item -Path $ManagedFile -Force -ErrorAction SilentlyContinue
    }
    exit 1
}

Write-Host "Locking down file permissions (Administrators: full control, Users: read-only)..."
$acl = Get-Acl $ManagedFile
$acl.SetAccessRuleProtection($true, $false)
$adminsRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "BUILTIN\Administrators", "FullControl", "Allow")
$systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "NT AUTHORITY\SYSTEM", "FullControl", "Allow")
$usersRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "BUILTIN\Users", "ReadAndExecute", "Allow")
$acl.AddAccessRule($adminsRule)
$acl.AddAccessRule($systemRule)
$acl.AddAccessRule($usersRule)
Set-Acl -Path $ManagedFile -AclObject $acl

Write-Host ""
Write-Host "Done. Managed settings installed at:"
Write-Host "  $ManagedFile"
Write-Host ""
Write-Host "Next: open a Claude Code session (claude) in any project and run /permissions"
Write-Host "to confirm the managed deny rules are listed."
