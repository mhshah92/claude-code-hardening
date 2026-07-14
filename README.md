# Claude Code — org-level hardening

Managed settings that lock down Claude Code across **macOS, Linux/WSL2, and Windows**: blocks
reading secrets/credentials, blocks curl/wget/rm -rf/force-push, disables permission-bypass
mode, restricts to managed permission rules and hooks only, and (on macOS and Linux/WSL2) turns
on bash sandboxing with a network domain allowlist.

## Platform support

| Platform | Managed settings path | Sandbox enforcement |
|---|---|---|
| macOS | `/Library/Application Support/ClaudeCode/managed-settings.json` | Yes (Seatbelt, built in) |
| Linux / WSL2 | `/etc/claude-code/managed-settings.json` | Yes (bubblewrap — install it separately) |
| Windows (native) | `C:\Program Files\ClaudeCode\managed-settings.json` | **Not supported by Claude Code.** Permission deny rules still apply, but Bash is not OS-sandboxed. |

Claude Code's sandbox is built on OS primitives (Seatbelt on macOS, bubblewrap on Linux/WSL2)
and does not have a native Windows equivalent — WSL1 isn't supported either. If your Windows
developers need real sandbox enforcement rather than permission-layer deny rules alone, run
Claude Code inside WSL2 and apply the Linux installer there instead of (or in addition to) the
native Windows one.

## Files

- `managed-settings.json` — the single source of truth used by all installers.
- `install-macos.sh` / `rollback-macos.sh` — deploy/remove the policy at
  `/Library/Application Support/ClaudeCode/`.
- `install-linux.sh` / `rollback-linux.sh` — deploy/remove the policy at `/etc/claude-code/`.
  Warns if `bubblewrap` isn't installed, since the sandbox block depends on it.
- `install-windows.ps1` / `rollback-windows.ps1` — deploy/remove the policy at
  `C:\Program Files\ClaudeCode\`. Must be run from an elevated (Administrator) PowerShell
  session.

Each installer backs up any existing `managed-settings.json` first (timestamped) and validates
the JSON before locking down file permissions.

## Usage

**macOS**
```
chmod +x install-macos.sh rollback-macos.sh
./install-macos.sh
./rollback-macos.sh   # to undo
```

**Linux / WSL2**
```
chmod +x install-linux.sh rollback-linux.sh
./install-linux.sh
./rollback-linux.sh   # to undo
```

**Windows** (run in an Administrator PowerShell session)
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
.\install-windows.ps1
.\rollback-windows.ps1   # to undo
```

## Important limitation

This is enforcement by convention, not tamper-proofing: anyone with local admin/root/sudo on
the machine can edit or delete the managed settings file directly. This only holds as a real
control if end users do NOT have local admin rights, or if the policy is delivered via MDM /
Group Policy / server-managed settings rather than trusted from a local file that an admin user
could edit.

On native Windows there's a second gap even with admin rights locked down: the sandbox itself
doesn't exist as an enforcement layer, so the deny rules in `permissions` are the only backstop
for Bash. Treat native-Windows installs as a lighter guarantee than macOS/Linux, and prefer
WSL2 wherever the threat model requires it.

## Verify after installing

Open a Claude Code session in any project and run `/permissions` to confirm the managed deny
rules are listed. Then test that a local `.claude/settings.local.json` trying to re-allow a
denied command (e.g. `curl`) has no effect — that's the proof the floor actually holds.

On macOS and Linux/WSL2, also run `/sandbox` to confirm the sandbox panel shows it as active
rather than missing a dependency.